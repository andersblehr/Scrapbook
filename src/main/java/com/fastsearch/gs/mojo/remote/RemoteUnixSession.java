package com.fastsearch.gs.mojo.remote;

import java.io.File;
import java.io.IOException;
import java.util.HashMap;

import org.apache.maven.plugin.logging.Log;

import com.fastsearch.gs.mojo.artifact.ESPArtifact;
import com.fastsearch.gs.mojo.artifact.ESPPatchArtifact;
import com.fastsearch.gs.mojo.esp.ESPComponent;
import com.fastsearch.gs.mojo.esp.ESPHost;
import com.fastsearch.gs.mojo.esp.enums.ESPFile;
import com.fastsearch.gs.mojo.esp.enums.ESPDir;
import com.fastsearch.gs.mojo.exceptions.ESPMojoException;
import com.fastsearch.gs.mojo.exceptions.RemoteSessionException;
import com.fastsearch.gs.mojo.util.PathUtil;
import com.fastsearch.gs.mojo.util.ProjectSettings;
import com.fastsearch.gs.mojo.util.SynchronisedLog;

import com.sshtools.j2ssh.SftpClient;
import com.sshtools.j2ssh.SshClient;
import com.sshtools.j2ssh.authentication.AuthenticationProtocolState;
import com.sshtools.j2ssh.authentication.PublicKeyAuthenticationClient;
import com.sshtools.j2ssh.session.SessionChannelClient;
import com.sshtools.j2ssh.transport.IgnoreHostKeyVerification;
import com.sshtools.j2ssh.transport.publickey.SshPrivateKey;
import com.sshtools.j2ssh.transport.publickey.SshPrivateKeyFile;


public class RemoteUnixSession implements RemoteSession
{
   private Log log = SynchronisedLog.getLog(  );

   private ESPHost host;
   private String shellPrompt;
   private SshClient sshClient;
   private SessionChannelClient session;
   private SftpClient sftpClient;
   private byte[] byteBuffer = new byte[ 512 ];
   private StringBuffer inputBuffer;


   public RemoteUnixSession( ESPHost host ) throws RemoteSessionException
   {
      if( !( "SSH2".equals( host.getRemoteCommand(  ) ) ) )
         throw new RemoteSessionException( "The remote command '" + host.getRemoteCommand(  ) + "' is not recognised for the '" + host.getPlatform(  ) + "' platform." );

      try
      {
         this.host = host;

         sshClient = new SshClient(  );
         sshClient.connect( host.getHostname(  ), new IgnoreHostKeyVerification(  ) );

         PublicKeyAuthenticationClient pk = new PublicKeyAuthenticationClient(  );
         pk.setUsername( host.getUsername(  ) );

         String keyFileName = PathUtil.joinPaths( ProjectSettings.getLocalPlatform(  ), System.getProperty( "user.home" ), ".ssh", "id_dsa" );
         SshPrivateKeyFile keyFile = SshPrivateKeyFile.parse( new File( keyFileName ) );
         SshPrivateKey privateKey = keyFile.toPrivateKey( "" );
         pk.setKey( privateKey );

         if( sshClient.authenticate( pk ) == AuthenticationProtocolState.COMPLETE )
         {
            session = sshClient.openSessionChannel(  );
            sftpClient = sshClient.openSftpClient(  );

            if( session.requestPseudoTerminal( "ansi", 80, 24, 0, 0, "" ) )
            {
               if( session.startShell(  ) )
               {
                  byte buffer[] = new byte[ 512 ];
                  int bytesRead = session.getInputStream(  ).read( buffer );
                  String bytes = new String( buffer, 0, bytesRead );

                  if( bytes.startsWith( "Last login" ) )
                     bytesRead = session.getInputStream(  ).read( buffer );

                  String fullPrompt = new String( buffer, 0, bytesRead );

                  if( fullPrompt.contains( "@" ) )
                     shellPrompt = fullPrompt.substring( 0, fullPrompt.indexOf( "@" ) );
                  else
                     shellPrompt = fullPrompt.substring( 0, 4 );

                  if( existsFile( ESPFile.setupenv_sh.getTargetPath(  ) ) )
                  {
                     execute( "cd " + ESPDir.ESP_BIN.getTargetPath(  ) );
                     execute( "source " + ESPFile.setupenv_sh.getName(  ) );
                     execute( "export PATH=$FASTSEARCH/bin:$PATH" );
                     execute( "cd -" );
                  }
               }
               else
               {
                  close(  );
                  throw new RemoteSessionException( "Could not open remote SSH shell on " + host.getHostname(  ) );
               }
            }
            else
            {
               close(  );
               throw new RemoteSessionException( "Could not obtain pseudo terminal (pty) on " + host.getHostname(  ) );
            }
         }
         else
            throw new RemoteSessionException( "Passwordless authentication failed for user " + host.getUsername(  ) + " on " + host.getHostId(  ) );
      }
      catch( IOException e )
      {
         throw new RemoteSessionException( "Caught exception during creation of remote SSH session on " + host.getHostname(  ), e );
      }
   }

   
   public synchronized String execute( String command ) throws RemoteSessionException
   {
      return execute( command, false );
   }

   
   public synchronized String execute( String command, boolean ignoreErrors ) throws RemoteSessionException
   {
      log.debug( "[" + host.getHostname(  ) + "Executing command '" + command + "'" );

      try
      {
         String fullCommand;

         if( ignoreErrors )
            fullCommand = command + " 1>/tmp/result.tmp 2>&1; echo \"RESULT: `cat /tmp/result.tmp`\"\n";
         else
            fullCommand = command + " 1>/tmp/result.tmp 2>/tmp/error.tmp; if [ $? -eq 0 ]; then echo \"RESULT: `cat /tmp/result.tmp`\"; else echo \"ERROR $?: `cat /tmp/error.tmp`\"; fi\n";

         session.getOutputStream(  ).write( fullCommand.getBytes(  ) );

         int bytesRead;
         String bytes;
         inputBuffer = new StringBuffer(  );
         int iterations = 0;
         boolean dataFound = false;
         boolean exitLoop = false;

         while( !exitLoop )
         {
            iterations++;
            bytesRead = session.getInputStream(  ).read( byteBuffer );
            bytes = new String( byteBuffer, 0, bytesRead );

            if( bytes.startsWith( shellPrompt ) )
               exitLoop = true;
            else if( !ignoreErrors && bytes.startsWith( "ERROR" ) )
            {
               String errorCode;
               String errorMessage;

               if( bytes.contains( ":" ) )
               {
                  errorCode    = bytes.substring( 0, bytes.indexOf( ":") ).split( " " )[ 1 ];
                  errorMessage = bytes.substring( bytes.indexOf( ":" ) + 2 ); // TODO: Need to handle the case where there's nothing after the colon..
               }
               else
               {
                  errorCode    = "(none)";
                  errorMessage = bytes;
               }

               throw new RemoteSessionException( "[" + host.getHostname(  ) + "] Command '" + command +
                                                 "' returned with error code " + errorCode + " and message '" +
                                                 errorMessage + "'." );
            }
            else if( bytes.startsWith( "RESULT" ) || ( ignoreErrors && bytes.startsWith( "ERROR" ) ) )
            {
               inputBuffer.append( bytes.substring( bytes.indexOf( ":" ) + 2 ) );
               dataFound = true;
            }
            else if( dataFound == true )
               inputBuffer.append( bytes );
         }
      }
      catch( IndexOutOfBoundsException e ) // TODO: This is potentially only a workaround for the task item above. 
      {
         log.error( "[" + host.getHostname(  ) + "] Caught IndexOutOfBoundsException when running command '" + command + "', proceed with care!"  );
      }
      catch( IOException e )
      {
         throw new RemoteSessionException( "Caught exception during execution of command '" + command + "' on " + host.getHostname(  ), e );
      }

      log.debug( "  -> Command output: " + inputBuffer.toString(  ) );

      return inputBuffer.toString(  );
   }

   
   public boolean existsFile( String remoteFile ) throws RemoteSessionException
   {
      String result = execute( "if [ -f " + remoteFile + " -o -L " + remoteFile + " ]; then echo exists; else echo notfound; fi" );

      if( result.startsWith( "exists" ) )
         return true;
      else
         return false;
   }

   
   public void touchFile( String remoteFile ) throws RemoteSessionException
   {
      execute( "touch " + remoteFile );
   }

   
   public void deleteFile( String remoteFile ) throws RemoteSessionException
   {
      execute( "rm " + remoteFile );
   }

   
   public boolean fileIsCurrent( ESPFile file ) throws RemoteSessionException, ESPMojoException
   {
      return file.getLocalMD5(  ).equals( getMD5( file.getTargetPath(  ) ) );
   }

   
   public boolean fileIsCurrent( ESPDir dir, String file ) throws RemoteSessionException, ESPMojoException
   {
      String localFile  = PathUtil.joinPaths( ProjectSettings.getLocalPlatform(  ),
                                              dir.getLocalPath(  ), 
                                              PathUtil.convertPath( ProjectSettings.getLocalPlatform(  ), file ) );
      String remoteFile = PathUtil.joinPaths( dir.getTargetPath(  ), PathUtil.convertPath( file ) );

      return ESPFile.getLocalMD5( localFile ).equals( getMD5( remoteFile ) );
   }

   
   public String getMD5( String remoteFile ) throws RemoteSessionException
   {
      if( existsFile( remoteFile ) )
         return execute( "md5sum " + remoteFile ).split( " " )[0].trim(  );
      else
         return "void";
   }

   
   public void createMD5Map( ESPArtifact artifact ) throws RemoteSessionException
   {
      String md5File = artifact.getMD5File(  ); 

      String fileDir = PathUtil.dirName( md5File );
      String fileName = PathUtil.baseName( md5File );

      execute( "cd " + fileDir + "; for f in `find . -type f -printf '%P\n' | grep -v " + fileName + " | sort`; do md5sum $f; done >" + md5File + "; cd -" );
   }

   
   public HashMap<String, String> getMD5Map( ESPArtifact artifact ) throws RemoteSessionException
   {
      if( existsFile( artifact.getMD5File(  ) ) )
      {
         HashMap<String, String> md5Map = new HashMap<String, String>(  );

         String[] md5Lines = getFileContents( artifact.getMD5File(  ) ).split( "\n" );

         for( String md5Line : md5Lines )
         {
            String[] parts = md5Line.split( "\\s+" );
            md5Map.put( parts[ 1 ].trim(  ), parts[ 0 ].trim(  ) );
         }

         return md5Map;
      }
      else
         return null;
   }

   
   public boolean existsDir( String remoteDir ) throws RemoteSessionException
   {
      String result = execute( "if [ -d " + remoteDir + " -o -L " + remoteDir + " ]; then echo exists; else echo notfound; fi" );

      if( result.startsWith( "exists" ) )
         return true;
      else
         return false;
   }

   
   public void createDir( String remoteDir ) throws RemoteSessionException
   {
      execute( "mkdir -p " + remoteDir );
   }


   public void removeDir( String remoteDir ) throws RemoteSessionException
   {
      execute( "rm -rf " + remoteDir );
   }


   public String[] getDirContents( String remoteDir ) throws RemoteSessionException
   {
      String[] files = execute( "find " + remoteDir + " -type f -printf '%P\n'" ).split( "\n" );

      for( int i = 0; i < files.length; i++ )
         files[ i ] = files[ i ].trim(  );

      return files;
   }

   
   public String[] getInstalledPatches(  ) throws RemoteSessionException
   {
      String[] patches;

      if( existsDir( ESPPatchArtifact.getPatchReadmeDir(  ) ) )
      {
         String dirFilter = PathUtil.joinPaths( ESPPatchArtifact.getPatchReadmeDir(  ), "*.txt" );
         patches = execute( "ls -1 " + dirFilter ).split( "\n" );

         for( int i = 0; i < patches.length; i++ )
         {
            patches[ i ] = patches[ i ].substring( patches[ i ].indexOf( "Hotfix_" ) + 7, patches[ i ].indexOf( "_Readme.txt" ) );
            String[] parts = patches[ i ].split( "\\." );
            patches[ i ] = parts[ 0 ] + "." + parts[ 1 ] + "." + parts[ 2 ] + "." + parts[ 3 ] + "." + parts[ 4 ];
         }

         return patches;
      }
      else
         return new String[ 0 ];
   }

   
   public String getFileContents( String remoteFile ) throws RemoteSessionException
   {
      return execute( "cat " + remoteFile );
   }


   public void copyFileFromHost( ESPHost host, String remoteFile ) throws RemoteSessionException
   {
      String noPromptOptions = " -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no ";
      String targetDir = PathUtil.dirName( remoteFile );

      if( !existsDir( targetDir ) )
         createDir( targetDir );

      execute( "scp" + noPromptOptions + host.getHostname(  ) + ":" + remoteFile + " " + targetDir );
   }

   
   public void copyDirFromHost( ESPHost host, String remoteDir ) throws RemoteSessionException
   {
      String noPromptOptions = " -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no ";

      if( existsDir( remoteDir ) )
         removeDir( remoteDir );

      execute( "scp -r" + noPromptOptions + host.getHostname(  ) + ":" + remoteDir + " " + PathUtil.dirName( remoteDir ) );
   }


   public void copyFile( String file, String targetDir ) throws RemoteSessionException
   {
      execute( "cp " + file + " " + targetDir );
   }

   
   public void putFile( String localFile, String remoteDir ) throws RemoteSessionException
   {
      try
      {
         log.debug( "SFTP'ing local file '" + localFile + "' to directory '" + remoteDir + "' on " + host.getHostname(  ) );

         if( !existsDir( remoteDir ) )
            createDir( remoteDir );

         sftpClient.put( localFile, remoteDir );
      }
      catch( IOException e )
      {
         throw new RemoteSessionException( "Caught IOException while using SFTP to transfer local file '" +
                                           localFile + "' to directory '" + remoteDir + "' on " + host.getHostname(  ), e );
      }
   }

   
   public synchronized void runInstaller(  ) throws RemoteSessionException
   {
      String installerOptions =
         "-silent " +
         "-is:tempdir " + host.getTempDir(  ) + " " +
         "-W platform.exitOnError=true " +
         "-W platform.exitOnWarning=true " +
         "-W legal.selection=1 " +
         "-W license.file=" + ESPFile.fastsearch_lic.getTargetPath(  ) + " " +
         "-W setup.selectedSetupTypeId=advanced " +
         "-W descriptor.filename=" + ESPFile.InstallProfile_xml.getTargetPath(  ) + " " +
         "-W descriptor.partial=true " +
         "-W descriptor.runTests=localTests " +  
         "-W advstartds.YES_NO=no";

      execute( ProjectSettings.getReleaseArtifact(  ).getInstallerTargetPath(  ) + " " + installerOptions );
   }


   public boolean existsRunningProcess(  ) throws RemoteSessionException
   {
      String userProcesses = execute( "ps -u " + host.getUsername(  ) );

      boolean existsRunningProcess = false;

      for( ESPComponent component : ESPComponent.values(  ) )
         existsRunningProcess = existsRunningProcess || ( userProcesses.contains( component.getProcessName(  ) ) );

      return existsRunningProcess;
   }

   
   public void close(  ) throws RemoteSessionException
   {
      try
      {
         session.close(  );
      }
      catch( IOException e )
      {
         throw new RemoteSessionException( "Caught exception when trying to close remote SSH session on " + host.getHostname(  ), e );
      }
   }
}

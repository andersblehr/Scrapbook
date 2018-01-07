package com.fastsearch.gs.mojo.esp;

import java.io.ByteArrayInputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;

import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import org.apache.maven.plugin.logging.Log;
import org.w3c.dom.Node;
import org.xml.sax.InputSource;

import com.fastsearch.gs.mojo.artifact.ESPArtifact;
import com.fastsearch.gs.mojo.artifact.ESPOverlayArtifact;
import com.fastsearch.gs.mojo.artifact.ESPPatchArtifact;
import com.fastsearch.gs.mojo.esp.enums.ESPDir;
import com.fastsearch.gs.mojo.esp.enums.ESPFile;
import com.fastsearch.gs.mojo.esp.enums.ESPStatus;
import com.fastsearch.gs.mojo.esp.enums.NctrlCommand;
import com.fastsearch.gs.mojo.exceptions.ESPMojoException;
import com.fastsearch.gs.mojo.exceptions.InconsistentVersionsException;
import com.fastsearch.gs.mojo.exceptions.MissingBackupException;
import com.fastsearch.gs.mojo.exceptions.RemoteSessionException;
import com.fastsearch.gs.mojo.exceptions.UnsupportedPlatformException;
import com.fastsearch.gs.mojo.remote.RemoteSession;
import com.fastsearch.gs.mojo.remote.RemoteSessionFactory;
import com.fastsearch.gs.mojo.util.ProjectSettings;
import com.fastsearch.gs.mojo.util.PathUtil;
import com.fastsearch.gs.mojo.util.Platform;
import com.fastsearch.gs.mojo.util.SynchronisedLog;
import com.fastsearch.gs.mojo.util.XPathUtil;


public class ESPHost
{
   private Log log = SynchronisedLog.getLog(  );
   private ArrayList<ESPComponent> hostedComponents;
   private ESPStatus  status;
   
   private String   hostId;
   private String   basePort;
   private String   fixmlDir;
   private String   hostname;
   private String   indexDir;
   private String   installDir;
   private Platform platform;
   private String   remoteCmd;
   private String   tempDir;
   private String   username;

   private RemoteSession remoteSession;
   private NctrlCommand nctrlCommand = null;

   ArrayList<String> changedOverlayFiles = new ArrayList<String>(  );   // TODO: Start using these for incrementally updating overlays
   ArrayList<String> missingOverlayFiles = new ArrayList<String>(  );
   ArrayList<String> redundantOverlayFiles = new ArrayList<String>(  );
   

   public ESPHost( Node hostNode, XPathUtil xPathUtil ) throws XPathExpressionException,
                                                               UnsupportedPlatformException, 
                                                               RemoteSessionException,
                                                               InconsistentVersionsException
   {
      hostedComponents = new ArrayList<ESPComponent>(  );
      
      hostId     = xPathUtil.getNode( XPathUtil.HOSTID,     hostNode ).getNodeValue(  );
      basePort   = xPathUtil.getNode( XPathUtil.BASEPORT,   hostNode ).getNodeValue(  );
      fixmlDir   = xPathUtil.getNode( XPathUtil.FIXMLDIR,   hostNode ).getNodeValue(  );
      hostname   = xPathUtil.getNode( XPathUtil.HOSTNAME,   hostNode ).getNodeValue(  );
      indexDir   = xPathUtil.getNode( XPathUtil.INDEXDIR,   hostNode ).getNodeValue(  );
      installDir = xPathUtil.getNode( XPathUtil.INSTALLDIR, hostNode ).getNodeValue(  );
      platform   = Platform.getPlatform( xPathUtil.getNode( XPathUtil.PLATFORM, hostNode ).getNodeValue(  ) );
      remoteCmd  = xPathUtil.getNode( XPathUtil.REMOTECMD,  hostNode ).getNodeValue(  );
      tempDir    = xPathUtil.getNode( XPathUtil.TEMPDIR,    hostNode ).getNodeValue(  );
      username   = xPathUtil.getNode( XPathUtil.USERNAME,   hostNode ).getNodeValue(  );

      if( ( Platform.LINUX != platform ) && ( Platform.WINDOWS != platform ) )
         throw new UnsupportedPlatformException( platform );
      
      remoteSession = RemoteSessionFactory.createRemoteSession( this );
      
      inspect(  );
   }
   
   
   public boolean isInstalled(  )
   {
      return ( ESPStatus.MISSING != status );
   }
   
   
   public void install(  ) throws RemoteSessionException
   {
      remoteSession.runInstaller(  );
      
      status = ESPStatus.DOWN;
   }
   
   
   public void uninstall(  ) throws RemoteSessionException
   {
      remoteSession.removeDir( installDir );
      remoteSession.removeDir( ESPDir.BACKUP.getTargetPath(  ) );
      remoteSession.removeDir( ESPDir.OVERLAY.getTargetPath(  ) );
   }
   

   public boolean isPatched(  ) throws RemoteSessionException
   {
      return remoteSession.existsDir( ESPPatchArtifact.getPatchReadmeDir(  ) );
   }
   
   
   public boolean hasAppliedArtifact( ESPArtifact artifact ) throws RemoteSessionException
   {
      return remoteSession.existsFile( artifact.getInstalledFile(  ) );
   }
   
   
   public boolean hasPackagedArtifact( ESPArtifact artifact ) throws RemoteSessionException
   {
      return remoteSession.existsFile( artifact.getPackagedArtifact(  ) );
   }
   
   
   public boolean hasBackup( ESPArtifact artifact ) throws RemoteSessionException
   {
      return remoteSession.existsDir( artifact.getBackupDir(  ) );
   }
   
   
   public String[] getInstalledPatches(  ) throws RemoteSessionException
   {
      return remoteSession.getInstalledPatches(  );
   }
   
   
   public void applyArtifact( ESPArtifact artifact ) throws RemoteSessionException, MissingBackupException
   {
      if( remoteSession.existsDir( artifact.getBackupDir(  ) ) )
         remoteSession.removeDir( artifact.getBackupDir(  ) );
      
      String[] files = remoteSession.getDirContents( artifact.getArtifactFilesDir(  ) );
      
      for( int i = 0; i < files.length; i++ )
      {
         String artifactFile = PathUtil.joinPaths( artifact.getArtifactFilesDir(  ), files[ i ] );
         String installedFile = PathUtil.joinPaths( installDir, files[ i ] );
         String targetDir = PathUtil.dirName( installedFile );
         
         if( remoteSession.existsFile( installedFile ) )
         {
            String backupDir = PathUtil.joinPaths( artifact.getBackupDir(  ), PathUtil.dirName( files[ i ] ) );
            remoteSession.createDir( backupDir );
            remoteSession.copyFile( installedFile, backupDir );
         }
         
         if( !remoteSession.existsDir( targetDir ) )
            remoteSession.createDir( targetDir );
         
         remoteSession.copyFile( artifactFile, targetDir );
      }
      
      if( artifact.isOverlay(  ) )
         remoteSession.createMD5Map( artifact );
   }

   
   public void rollbackArtifact( ESPArtifact artifact, boolean toBeReapplied ) throws RemoteSessionException, MissingBackupException
   {
      if( hasAppliedArtifact( artifact ) )
      {
         if( artifact.rollbackRequiresRestoreOfBackup(  ) )
         {
            if( remoteSession.existsDir( artifact.getBackupDir(  ) ) )
            {
               if( artifact.hasArtifactFiles( this ) )
               {
                  String[] artifactFiles = remoteSession.getDirContents( artifact.getArtifactFilesDir(  ) );
                  
                  for( int i = 0; i < artifactFiles.length; i++ )
                  {
                     String installedFile = PathUtil.joinPaths( installDir, artifactFiles[ i ] );
                     
                     if( artifact.rollbackFile( installedFile ) )
                        remoteSession.deleteFile( installedFile );
                  }
               }
               else
               {
                  String description = artifact.getDescription(  );
                  
                  log.warn( "Compressed archive for " + description + " '" + artifact.getArtifactId(  ) + "' not available, not enough information" );
                  log.warn( "to exhaustively roll back " + description + "." );
                  log.warn( "Restoring pre-" + description + " files from backup, some " + description + " files may persist.");
               }
               
               String[] backupFiles = remoteSession.getDirContents( artifact.getBackupDir(  ) );
               
               for( int i = 0; i < backupFiles.length; i++ )
               {
                  String backedUpFile = PathUtil.joinPaths( artifact.getBackupDir(  ), backupFiles[ i ] );
                  String targetDir = PathUtil.dirName( PathUtil.joinPaths( installDir, backupFiles[ i ] ) );
                  
                  remoteSession.copyFile( backedUpFile, targetDir );
               }
               
               remoteSession.removeDir( artifact.getBackupDir(  ) );
            }
            else
               throw new MissingBackupException( artifact );
         }
         
         if( artifact.isPatch(  ) )
         {
            if( !toBeReapplied )
               remoteSession.removeDir( PathUtil.dirName( artifact.getPackagedArtifactDir(  ) ) );
            
            if( ( 2 == remoteSession.getDirContents( ESPPatchArtifact.getPatchReadmeDir(  ) ).length )
                  && existsFile( ESPFile.banner_gif ) && existsFile( ESPFile.FAST_logo_gif ) )
               remoteSession.removeDir( ESPPatchArtifact.getPatchReadmeDir(  ) );
         }
         else if( artifact.isOverlay(  ) )
         {
            remoteSession.removeDir( ESPDir.OVERLAY.getTargetPath(  ) );
         }
      }
   }
   
   
   public boolean hasOverlay(  ) throws RemoteSessionException
   {
      return remoteSession.existsFile( ESPFile.overlay_md5.getTargetPath(  ) );
   }
   
   
   public boolean overlayIsCurrent(  ) throws RemoteSessionException
   {
      changedOverlayFiles.clear(  );
      missingOverlayFiles.clear(  );
      redundantOverlayFiles.clear(  );
      
      if( hasOverlay(  ) )
      {
         ESPOverlayArtifact localOverlay = ProjectSettings.getOverlayArtifact(  );
         HashMap<String, String> remoteMD5Map = remoteSession.getMD5Map( localOverlay );
         
         for( String localOverlayFile : localOverlay.getOverlayFiles(  ) )
         {
            if( !remoteMD5Map.containsKey( localOverlayFile ) )
               missingOverlayFiles.add( localOverlayFile );
            else if( !remoteMD5Map.get( localOverlayFile ).equals( localOverlay.getLocalMD5( localOverlayFile ) ) )
               changedOverlayFiles.add( localOverlayFile );
         }
         
         List localOverlayFiles = Arrays.asList( localOverlay.getOverlayFiles(  ) );
         
         for( String remoteOverlayFile : remoteMD5Map.keySet(  ) )
            if( !localOverlayFiles.contains( remoteOverlayFile ) )
               redundantOverlayFiles.add( remoteOverlayFile );
      }
      
      return ( 0 == changedOverlayFiles.size(  ) ) && ( 0 == missingOverlayFiles.size(  ) ) && ( 0 == redundantOverlayFiles.size(  ) );
   }
   
   
   public ESPStatus inspect(  ) throws RemoteSessionException
   {
      try
      {
         if( checkInstalled(  ) )
         {
            String sysstatusOutput = remoteSession.execute( NctrlCommand.SYSSTATUS.asString(  ) );
            
            boolean someRunning = sysstatusOutput.contains( "Running" );
            boolean someDead    = sysstatusOutput.contains( "Dead"    );
            
            if( someRunning && someDead )
               status = ESPStatus.STRUGGLING;
            else if( someRunning )
               status = ESPStatus.RUNNING;
            else if( someDead )
               status = ESPStatus.DOWN;
            else
               status = ESPStatus.UNKNOWN;
         }
         else
            status = ESPStatus.MISSING;
         
         if( ( ESPStatus.DOWN == status ) && ( remoteSession.existsRunningProcess(  ) ) )
            status = ESPStatus.HANGING;
      }
      catch( InconsistentVersionsException e )
      {
         status = ESPStatus.VERSION;
      }
         
      return status;
   }
   
   
   public boolean isRunning(  )
   {
      return ( ( ESPStatus.DOWN != status ) && ( ESPStatus.HANGING != status ) && ( ESPStatus.MISSING != status ) );
   }
   
   
   public boolean isDown(  )
   {
      return ( ESPStatus.DOWN == status );
   }
   
   
   public boolean isHanging(  )
   {
      return ( ESPStatus.HANGING == status );
   }
   
   
   public void runNctrlCommand( NctrlCommand command ) throws RemoteSessionException
   {
      remoteSession.execute( command.asString(  ) );
      
      status = inspect(  );
   }
   
   
   public boolean existsFile( ESPFile file ) throws RemoteSessionException
   {
      return remoteSession.existsFile( file.getTargetPath(  ) );
   }

   
   public boolean fileIsCurrent( ESPFile file ) throws RemoteSessionException, ESPMojoException
   {
      return remoteSession.fileIsCurrent( file );
   }
   
   
   public void touchFile( ESPFile file ) throws RemoteSessionException
   {
      remoteSession.touchFile( file.getTargetPath(  ) );
   }
   
   
   public boolean unpackingRequired( ESPArtifact artifact ) throws RemoteSessionException
   {
      return hasPackagedArtifact( artifact ) && !remoteSession.existsDir( artifact.getArtifactFilesDir(  ) );
   }

   
   public void putFile( String localFile, String targetDir ) throws RemoteSessionException
   {
      remoteSession.putFile( localFile, targetDir );
   }
   

   public void putFile( ESPFile file ) throws RemoteSessionException
   {
      remoteSession.putFile( file.getLocalPath(  ), file.getTargetDir(  ) );
   }
   
   
   public void putFile( ESPArtifact artifact ) throws RemoteSessionException
   {
      remoteSession.putFile( artifact.getRepositoryPath(  ), artifact.getPackagedArtifactDir(  ) );
   }
   
   
   public void copyFileFromHost( ESPHost host, String file ) throws RemoteSessionException
   {
      remoteSession.copyFileFromHost( host, file );
   }
   
   
   public void copyFileFromHost( ESPHost host, ESPFile file ) throws RemoteSessionException
   {
      remoteSession.copyFileFromHost( host, file.getTargetPath(  ) );
   }

   
   public void copyFileFromHost( ESPHost host, ESPArtifact artifact ) throws RemoteSessionException
   {
      remoteSession.copyFileFromHost( host, artifact.getPackagedArtifact(  ) );
   }
   
   
   public void copyDirFromHost( ESPHost host, ESPDir dir ) throws RemoteSessionException
   {
      remoteSession.copyDirFromHost( host, dir.getTargetPath(  ) );
   }

   
   public void unpackArtifact( ESPArtifact artifact ) throws RemoteSessionException
   {
      if( !remoteSession.existsDir( artifact.getArtifactFilesDir(  ) ) )
      {
         remoteSession.createDir( artifact.getArtifactFilesDir(  ) );
         remoteSession.execute( artifact.getUnpackCommand(  ) );
      }
   }
 
 
   public ArrayList<ESPComponent> getComponents(  )
   {
      return hostedComponents;
   }
   
   
   public void addComponent( ESPComponent component )
   {
      hostedComponents.add( component );
   }
   
   
   public boolean hasComponent( ESPComponent component )
   {
      return hostedComponents.contains( component );
   }
   
   
   public boolean isAdminHost(  )
   {
      return hostedComponents.contains( ESPComponent.CONFIGSERVER );
   }
   

   public ESPStatus getStatus(  )
   {
      return status;
   }
   
   
   public String getHostId(  )
   {
      return hostId;
   }


   public String getBasePort(  )
   {
      return basePort;
   }


   public String getFiXMLDir(  )
   {
      return fixmlDir;
   }


   public String getHostname(  )
   {
      return hostname;
   }


   public String getIndexDir(  )
   {
      return indexDir;
   }


   public String getInstallDir(  )
   {
      return installDir;
   }


   public Platform getPlatform(  )
   {
      return platform;
   }


   public String getRemoteCommand(  ) 
   {
      return remoteCmd;
   }


   public String getTempDir(  )
   {
      return tempDir;
   }


   public String getUsername(  )
   {
      return username;
   }
   
   
   public void setNctrlCommand( NctrlCommand nctrlCommand )
   {
      this.nctrlCommand = nctrlCommand;
   }


   public NctrlCommand getNctrlCommand(  )
   {
      return nctrlCommand;
   }
   
   
   public RemoteSession getRemoteSession(  )
   {
      return remoteSession;
   }
   
   
   private boolean checkInstalled(  ) throws RemoteSessionException, InconsistentVersionsException
   {
      try
      {
         if( remoteSession.existsFile( ESPFile.VERSION_xml.getTargetPath(  ) ) )
         {
            XPath xPath = XPathFactory.newInstance(  ).newXPath(  );
            
            String versionXML = remoteSession.getFileContents( ESPFile.VERSION_xml.getTargetPath(  ) );
            InputSource xmlInputSource = new InputSource( new ByteArrayInputStream( versionXML.getBytes(  ) ) );
            String installedVersion = ( ( Node )xPath.evaluate( "/version/@product-version", xmlInputSource, XPathConstants.NODE ) ).getNodeValue(  );

            if( installedVersion.equals( ProjectSettings.getPointRelease(  ) ) )
               return true;
            else
               throw new InconsistentVersionsException( hostname, ProjectSettings.getPointRelease(  ), installedVersion );
         }
         else
            return false;
      }
      catch( XPathExpressionException e )
      {
         throw new RemoteSessionException( "An xpath exception occurred during parsing of " + ESPFile.VERSION_xml.getTargetPath(  ) + " on " + hostname + ".", e );
      }
   }
}

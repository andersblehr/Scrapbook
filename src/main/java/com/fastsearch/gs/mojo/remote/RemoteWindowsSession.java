package com.fastsearch.gs.mojo.remote;

import java.util.HashMap;

import com.fastsearch.gs.mojo.artifact.ESPArtifact;
import com.fastsearch.gs.mojo.esp.ESPHost;
import com.fastsearch.gs.mojo.esp.enums.ESPDir;
import com.fastsearch.gs.mojo.esp.enums.ESPFile;
import com.fastsearch.gs.mojo.exceptions.ESPMojoException;
import com.fastsearch.gs.mojo.exceptions.RemoteSessionException;
import com.fastsearch.gs.mojo.util.ProjectSettings;


public class RemoteWindowsSession implements RemoteSession
{
   private ESPHost host;
   
   
   public RemoteWindowsSession( ESPHost host )
   {
      this.host = host;
   }
   
   public synchronized String execute( String command, boolean ignoreErrors ) throws RemoteSessionException {
      return null;
   }

   public synchronized String execute( String command ) throws RemoteSessionException {
      return null;
   }

   public boolean existsFile(String remoteFile) throws RemoteSessionException {
      return false;
   }

   public void touchFile(String remoteFile) throws RemoteSessionException {
      
   }

   public void deleteFile(String remoteFile) throws RemoteSessionException {
      
   }

   public boolean fileIsCurrent( ESPFile file ) throws RemoteSessionException, ESPMojoException {
      return false;
   }

   public boolean fileIsCurrent( ESPDir dir, String file ) throws RemoteSessionException, ESPMojoException {
      return false;
   }
   
   public String getMD5( String remoteFile ) throws RemoteSessionException {
      return null;
   }

   public void createMD5Map( ESPArtifact artifact ) throws RemoteSessionException {
      
   }

   public HashMap<String, String> getMD5Map( ESPArtifact artifact ) throws RemoteSessionException {
      return null;
   }
   
   public boolean existsDir(String remoteDir) throws RemoteSessionException {
      return false;
   }

   public void createDir(String remoteDir) throws RemoteSessionException {
      
   }

   public void removeDir(String remoteDir) throws RemoteSessionException {
      
   }
   
   public String[] getDirContents( String remoteDir ) throws RemoteSessionException {
      return null;
   }

   public String[] getInstalledPatches(  ) throws RemoteSessionException {
      return null;
   }
   
   public String getFileContents(String remoteFile) throws RemoteSessionException {
      return null;
   }

   public void copyFileFromHost(ESPHost host, String remoteDirectory) throws RemoteSessionException {
      
   }
   
   public void copyDirFromHost( ESPHost host, String remoteDir ) throws RemoteSessionException {
      
   }
   
   public void copyFile( String file, String targetDir ) throws RemoteSessionException {
      
   }

   public void putFile(String localFile, String remoteDir) throws RemoteSessionException {

   }

   public synchronized void runInstaller() throws RemoteSessionException
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
         "-W advstartds.YES_NO=no" +
         "-W password.username=" + host.getUsername(  ) + " " +
         "-W password.password=" + "TODO" + " " +
         "-W password.password2=" + "TODO";

      execute( ProjectSettings.getReleaseArtifact(  ).getInstallerTargetPath(  ) + " " + installerOptions );
   }

   public boolean existsRunningProcess() throws RemoteSessionException {
      return false;
   }

   public void close() throws RemoteSessionException {
      
   }
}

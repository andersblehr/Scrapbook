package com.fastsearch.gs.mojo.remote;

import java.util.HashMap;

import com.fastsearch.gs.mojo.artifact.ESPArtifact;
import com.fastsearch.gs.mojo.esp.ESPHost;
import com.fastsearch.gs.mojo.esp.enums.ESPDir;
import com.fastsearch.gs.mojo.esp.enums.ESPFile;
import com.fastsearch.gs.mojo.exceptions.ESPMojoException;
import com.fastsearch.gs.mojo.exceptions.RemoteSessionException;


public interface RemoteSession
{
   public String   execute( String command ) throws RemoteSessionException;
   public String   execute( String command, boolean ignoreErrors ) throws RemoteSessionException;
   public boolean  existsFile( String remoteFile ) throws RemoteSessionException;
   public void     touchFile( String remoteFile ) throws RemoteSessionException;
   public void     deleteFile( String remoteFile ) throws RemoteSessionException;
   public boolean  fileIsCurrent( ESPFile file ) throws RemoteSessionException, ESPMojoException;
   public boolean  fileIsCurrent( ESPDir dir, String file ) throws RemoteSessionException, ESPMojoException;
   public String   getMD5( String remoteFile ) throws RemoteSessionException;
   public void     createMD5Map( ESPArtifact artifact ) throws RemoteSessionException;
   public HashMap<String, String> getMD5Map( ESPArtifact artifact ) throws RemoteSessionException;
   public boolean  existsDir( String remoteDir ) throws RemoteSessionException;
   public void     createDir( String remoteDir ) throws RemoteSessionException;
   public void     removeDir( String remoteDir ) throws RemoteSessionException;
   public String[] getDirContents( String remoteDir ) throws RemoteSessionException;
   public String[] getInstalledPatches(  ) throws RemoteSessionException;
   public String   getFileContents( String remoteFile ) throws RemoteSessionException;
   public void     copyFileFromHost( ESPHost host, String remoteFile ) throws RemoteSessionException;
   public void     copyDirFromHost( ESPHost host, String remoteDir ) throws RemoteSessionException;
   public void     copyFile( String file, String targetDir ) throws RemoteSessionException;
   public void     putFile( String localFile, String remoteDir ) throws RemoteSessionException;
   public void     runInstaller(  ) throws RemoteSessionException;
   public boolean  existsRunningProcess(  ) throws RemoteSessionException;
   public void     close(  ) throws RemoteSessionException;
}

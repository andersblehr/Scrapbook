package com.fastsearch.gs.mojo.artifact;

import java.util.HashMap;

import com.fastsearch.gs.mojo.esp.ESPHost;
import com.fastsearch.gs.mojo.esp.enums.ESPArtifactGroupId;
import com.fastsearch.gs.mojo.esp.enums.ESPDir;
import com.fastsearch.gs.mojo.esp.enums.ESPFile;
import com.fastsearch.gs.mojo.exceptions.RemoteSessionException;
import com.fastsearch.gs.mojo.util.PathUtil;
import com.fastsearch.gs.mojo.util.Platform;
import com.fastsearch.gs.mojo.util.ProjectSettings;


public class ESPOverlayArtifact extends ESPArtifact
{
   private String[] overlayFiles;
   private HashMap<String, String> md5Map = new HashMap<String, String>(  );
   
   
   public ESPOverlayArtifact( String artifactId )
   {
      super( ESPArtifactGroupId.OVERLAY, artifactId, null, null );
      
      overlayFiles = ESPDir.OVERLAY.listLocalDirContents(  );
      for( String file : overlayFiles )
      {
         String filePath = PathUtil.joinPaths( ProjectSettings.getLocalPlatform(  ), ESPDir.OVERLAY.getLocalPath(  ), file );
         md5Map.put( PathUtil.convertPath( Platform.UNIX, file ), ESPFile.getLocalMD5( filePath ) );
      }
   }
   
   
   public String getArtifactFilesDir(  )
   {
      return getPackagedArtifactDir(  );
   }
   
   
   public String getBackupDir(  )
   {
      return PathUtil.joinPaths( ESPDir.BACKUP.getTargetPath(  ),
                                 getDescription(  ) );
   }
   
   
   public String[] getOverlayFiles(  )
   {
      return overlayFiles;
   }
   
   
   public String getLocalMD5( String overlayFile )
   {
      return md5Map.get( overlayFile );
   }

   
   public String getCapitalisedDescription(  )
   {
      return "Overlay";
   }
   
   
   public String getPackagedArtifactDir(  )
   {
      return ESPDir.OVERLAY.getTargetPath(  );
   }

   
   public String getPackagedArtifact(  )
   {
      return getPackagedArtifactDir(  );
   }
   
   
   public String getInstalledFile(  )
   {
      return ESPFile.overlay_md5.getTargetPath(  );
   }
   
   
   public String getMD5File(  )
   {
      return ESPFile.overlay_md5.getTargetPath(  );
   }
   
   
   public boolean hasArtifactFiles( ESPHost host ) throws RemoteSessionException
   {
      return host.hasOverlay(  );
   }
   
   
   public boolean rollbackFile( String installedFile )
   {
      return !installedFile.contains( ESPFile.overlay_md5.getName(  ) );
   }
   
   
   public boolean isOverlay(  )
   {
      return true;
   }
}

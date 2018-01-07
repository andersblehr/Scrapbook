package com.fastsearch.gs.mojo.artifact;

import org.apache.maven.model.Dependency;

import com.fastsearch.gs.mojo.esp.enums.ESPFile;
import com.fastsearch.gs.mojo.esp.enums.ESPDir;
import com.fastsearch.gs.mojo.util.PathUtil;
import com.fastsearch.gs.mojo.util.ProjectSettings;
import com.fastsearch.gs.mojo.util.SynchronisedLog;


public class ESPReleaseArtifact extends ESPArtifact
{
   public ESPReleaseArtifact( Dependency dependency )
   {
      super( dependency );
   }

   
   public String getCapitalisedDescription(  )
   {
      return "Installation bundle";
   }
   
   
   public String getPackagedArtifactDir(  )
   {
      return PathUtil.joinPaths( ProjectSettings.getRemoteLifecycleHome(  ),
                                 ESPDir.RELEASE_ESP.getRelativePath(  ),
                                 getArtifactId(  ),
                                 getVersion(  ) );
   }
   
   
   public String getPackagedArtifact(  )
   {
      return PathUtil.joinPaths( getPackagedArtifactDir(  ), getFileName(  ) );
   }
   
   
   public String getInstalledFile(  )
   {
      return ESPFile.VERSION_xml.getTargetPath(  );
   }
   
   
   public String getInstallerTargetPath(  )
   {
      return PathUtil.joinPaths( getArtifactFilesDir(  ),
                                 ESPFile.INSTALLER.getName( ProjectSettings.getTargetPlatform(  ) ) );
   }
   
   
   public String getMD5File(  )
   {
      SynchronisedLog.getLog(  ).warn( "ESPReleaseArtifact.getMD5File() called, should not happen; returning null." );
      return null;
   }
   
   
   public boolean rollbackRequiresRestoreOfBackup(  )
   {
      return false;
   }
}
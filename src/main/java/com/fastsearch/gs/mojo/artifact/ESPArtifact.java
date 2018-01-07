package com.fastsearch.gs.mojo.artifact;

import org.apache.maven.model.Dependency;

import com.fastsearch.gs.mojo.esp.ESPHost;
import com.fastsearch.gs.mojo.esp.enums.ESPArtifactGroupId;
import com.fastsearch.gs.mojo.esp.enums.ESPDir;
import com.fastsearch.gs.mojo.exceptions.RemoteSessionException;
import com.fastsearch.gs.mojo.util.PathUtil;
import com.fastsearch.gs.mojo.util.Platform;
import com.fastsearch.gs.mojo.util.ProjectSettings;


public abstract class ESPArtifact
{
   protected ESPArtifactGroupId groupId;
   protected String artifactId;
   protected String version;
   protected String type;

   
   protected ESPArtifact( Dependency dependency )
   {
      groupId = ESPArtifactGroupId.getGroupId( dependency.getGroupId(  ) );
      artifactId = dependency.getArtifactId(  );
      version = dependency.getVersion(  );
      type = dependency.getType(  );
   }
   
   
   protected ESPArtifact( ESPArtifactGroupId groupId, String artifactId, String version, String type )
   {
      this.groupId = groupId;
      this.artifactId = artifactId;
      this.version = version;
      this.type = type;
   }
   
   
   public String getFileName(  )
   {
      return artifactId + "-" + version + "." + type;
   }
   
   
   public String getRepositoryPath(  )
   {
      return PathUtil.joinPaths( ProjectSettings.getLocalPlatform(  ),
                                 ProjectSettings.getLocalRepository(  ),
                                 PathUtil.joinPaths( ProjectSettings.getLocalPlatform(  ), groupId.asString(  ).split( "\\." ) ),
                                 artifactId,
                                 version,
                                 getFileName(  ) );
   }


   public String getDescription(  )
   {
      return getCapitalisedDescription(  ).toLowerCase(  );
   }
   
   
   public String getBackupDir(  )
   {
      return getPackagedArtifactDir(  );
   }
   
   
   public String getArtifactFilesDir(  )
   {
      return PathUtil.joinPaths( getPackagedArtifactDir(  ), ESPDir.UNPACK.getRelativePath(  ) );
   }
   
   
   public String getUnpackCommand(  )
   {
      if( "tar.gz".equals( type ) )
         return "tar xvf " + getPackagedArtifact(  ) + " -C " + getArtifactFilesDir(  );
      else if( "zip".equals( type ) && ( Platform.LINUX == ProjectSettings.getTargetPlatform(  ) ) )
         return "unzip -nd " + getArtifactFilesDir(  ) + " " + getPackagedArtifact(  );
      else
         return null;
   }
   
   
   public String getGroupId(  )
   {
      return groupId.asString(  );
   }
   
   
   public String getArtifactId(  )
   {
      return artifactId;
   }
   
   
   public String getVersion(  )
   {
      return version;
   }
   
   
   public String getType(  )
   {
      return type;
   }
   

   public abstract String getCapitalisedDescription(  );
   public abstract String getPackagedArtifactDir(  );
   public abstract String getPackagedArtifact(  );
   public abstract String getInstalledFile(  );
   public abstract String getMD5File(  );
   
   
   public boolean hasArtifactFiles( ESPHost host ) throws RemoteSessionException
   {
      return true;
   }
   
   
   public boolean rollbackRequiresRestoreOfBackup(  )
   {
      return true;
   }
   
   
   public boolean rollbackFile( String file )
   {
      return true;
   }
   
   
   public boolean isPatch(  )
   {
      return false;
   }
   
   
   public boolean isOverlay(  )
   {
      return false;
   }
}

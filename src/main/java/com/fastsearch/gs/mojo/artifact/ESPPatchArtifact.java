package com.fastsearch.gs.mojo.artifact;

import org.apache.maven.model.Dependency;

import com.fastsearch.gs.mojo.esp.ESPHost;
import com.fastsearch.gs.mojo.esp.enums.ESPArtifactGroupId;
import com.fastsearch.gs.mojo.esp.enums.ESPDir;
import com.fastsearch.gs.mojo.esp.enums.ESPFile;
import com.fastsearch.gs.mojo.exceptions.RemoteSessionException;
import com.fastsearch.gs.mojo.remote.RemoteSession;
import com.fastsearch.gs.mojo.util.PathUtil;
import com.fastsearch.gs.mojo.util.ProjectSettings;


public class ESPPatchArtifact extends ESPArtifact
{
   public ESPPatchArtifact( Dependency dependency )
   {
      super( dependency );
   }
   
   
   protected ESPPatchArtifact( ESPArtifactGroupId groupId, String artifactId, String version, String type )
   {
      super( groupId, artifactId, version, type );
   }
   
   
   public static String getPatchReadmeDir(  )
   {
      return PathUtil.joinPaths( ProjectSettings.getInstallDir(  ), ESPDir.ESP_HOTFIX.getRelativePath(  ) );
   }
   
   
   public static ESPPatchArtifact resolvePatch( String artifactId, ESPHost host ) throws RemoteSessionException
   {
      RemoteSession remoteSession = host.getRemoteSession(  );
      
      String readmePrefix = "Hotfix_" + artifactId;
      String[] readmeFiles = remoteSession.getDirContents( getPatchReadmeDir(  ) );

      for( String readmeFileName : readmeFiles )
      {
         if( readmeFileName.contains( readmePrefix ) )
         {
            String version = readmeFileName.substring( 7 + artifactId.length(  ) + 1, readmeFileName.indexOf( "_Readme" ) );
            String type = ( "ALL".equals( version ) ? "zip" : "tar.gz" );
            
            return new ESPPatchArtifact( ESPArtifactGroupId.HOTFIX, artifactId, version, type );
         }
      }
      
      return null;
   }
   
   
   public String getReadme_txt(  )
   {
      return PathUtil.joinPaths( getPatchReadmeDir(  ),
                                 "Hotfix_" + getArtifactId(  ) + "." + getVersion(  ) + "_Readme.txt" );
   }
   
   
   public String getReadme_html(  )
   {
      return PathUtil.joinPaths( getPatchReadmeDir(  ),
                                 "Hotfix_" + getArtifactId(  ) + "." + getVersion(  ) + "_Readme.html" );
   }
   
   
   public String getBackupDir(  )
   {
      return PathUtil.joinPaths( ESPDir.BACKUP.getTargetPath(  ),
                                 artifactId );
   }
   

   public String getCapitalisedDescription(  )
   {
      return "Hotfix";
   }
   
   
   public String getPackagedArtifactDir(  )
   {
      return PathUtil.joinPaths( ProjectSettings.getRemoteLifecycleHome(  ),
                                 ESPDir.RELEASE_HOTFIX.getRelativePath(  ),
                                 artifactId,
                                 version );
   }

   
   public String getPackagedArtifact(  )
   {
      return PathUtil.joinPaths( getPackagedArtifactDir(  ), getFileName(  ) );
   }
   
   
   public String getInstalledFile(  )
   {
      return getReadme_txt(  );
   }
   
   
   public String getMD5File(  )
   {
      return ESPFile.patch_md5.getTargetPath( this );
   }
   
   
   public boolean hasArtifactFiles( ESPHost host ) throws RemoteSessionException
   {
      if( host.hasPackagedArtifact( this ) )
      {
         host.unpackArtifact( this );
         return true;
      }
      else
         return false;
   }
   
   
   public boolean rollbackFile( String file )
   {
      return ( !ESPFile.banner_gif.getTargetPath(  ).equals( file ) && !ESPFile.FAST_logo_gif.getTargetPath(  ).equals( file ) );
   }
   
   
   public boolean isPatch(  )
   {
      return true;
   }
}

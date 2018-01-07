package com.fastsearch.gs.mojo.esp.enums;

import java.io.File;
import java.util.ArrayList;

import com.fastsearch.gs.mojo.exceptions.RemoteSessionException;
import com.fastsearch.gs.mojo.remote.RemoteSession;
import com.fastsearch.gs.mojo.util.PathUtil;
import com.fastsearch.gs.mojo.util.Platform;
import com.fastsearch.gs.mojo.util.ProjectSettings;

public enum ESPDir
{
   LIFECYCLE_HOME       ( "lifecycle",                           false, false, false ),
   RELEASE_ESP          ( "esp|release",                         false, false, false ),
   RELEASE_HOTFIX       ( "esp|hotfixes",                        false, false, false ),
   BACKUP               ( "_backups",                            false, true,  false ),
   UNPACK               ( "_unpack",                             false, false, true  ),
   OVERLAY              ( "overlay",                             false, true,  false ),
   RESOURCE             ( "resources",                           false, true,  false ),
   
   ESP_BIN              ( "bin",                                 true,  false, false ),
   ESP_ETC              ( "etc",                                 true,  false, false ),
   ESP_SYSLOG           ( "var|log", "var|log|syslog",           true,  false, false ),
   ESP_HOTFIX           ( "etc|hotfixes",                        true,  false, false ),
   ESP_IPROFILE         ( "index-profiles",                      true,  false, false ),
   ESP_IPROFILE_BLISSED ( "etc|config_data|RTSearch|webcluster", true,  false, false );

   private String genericPath50;
   private String genericPath51;
   private boolean isInstalled;
   private boolean isProjectSpecific;
   private boolean requiresArtifact;
   
   
   private ESPDir( String genericPath, boolean isInstalled, boolean isProjectSpecific, boolean requiresArtifact )
   {
      this( genericPath, genericPath, isInstalled, isProjectSpecific, requiresArtifact );
   }
   
   
   private ESPDir( String genericPath50, String genericPath51, boolean isInstalled, boolean isProjectSpecific, boolean requiresArtifact )
   {
      this.genericPath50 = genericPath50;
      this.genericPath51 = genericPath51;
      this.isInstalled = isInstalled;
      this.isProjectSpecific = isProjectSpecific;
      this.requiresArtifact = requiresArtifact;
   }
   

   public String getRelativePath(  )
   {
      return getRelativePath( ProjectSettings.getTargetPlatform(  ) );
   }
   
   
   public String getRelativePath( Platform platform )
   {
      String genericPath = ( "5.0".equals( ProjectSettings.getMinorRelease(  ) ) ? genericPath50 : genericPath51 );
      
      if( ( Platform.LINUX == platform ) || ( Platform.UNIX == platform ) )
         return genericPath.replace( "|", "/" );
      else if( Platform.WINDOWS == platform )
         return genericPath.replace( "|", "\\" );
      else
         return null;
   }
   
   
   public String getTargetPath(  )
   {
      if( requiresArtifact )
         return null;
      else if( isInstalled )
         return PathUtil.joinPaths( ProjectSettings.getInstallDir(  ), getRelativePath(  ) );
      else if( isProjectSpecific )
         return PathUtil.joinPaths( ProjectSettings.getRemoteLifecycleHome(  ), ProjectSettings.getEngagementPrefix(  ), getRelativePath(  ) );
      else
         return PathUtil.joinPaths( ProjectSettings.getRemoteLifecycleHome(  ), getRelativePath(  ) );
   }
   
   
   public String getLocalPath(  )
   {
      if( requiresArtifact || isInstalled )
         return null;
      else
         return PathUtil.joinPaths( ProjectSettings.getLocalPlatform(  ),
                                    ProjectSettings.getLocalLifecycleHome(  ),
                                    getRelativePath( ProjectSettings.getLocalPlatform(  ) ) );
   }
   
   
   public String[] listLocalDirContents(  )
   {
      return listLocalDirContents( getLocalPath(  ) );
   }
   
   
   public static String[] listLocalDirContents( String dir )
   {
      return traverseDir( new File( dir ), null ).toArray( new String[ 1 ] );
   }
   
   
   public String[] listRemoteDirContents( RemoteSession remoteSession ) throws RemoteSessionException
   {
      return remoteSession.getDirContents( getTargetPath(  ) );
   }
   
   
   private static ArrayList<String> traverseDir( File dir, ArrayList<String> files )
   {
      if( null == files )
         files = new ArrayList<String>(  );
      
      if( dir.isDirectory(  ) )
      {
         String[] children = dir.list(  );
         
         for( int i = 0; i < children.length; i++ )
         {
            String child = PathUtil.joinPaths( ProjectSettings.getLocalPlatform(  ),
                                               dir.getAbsolutePath(  ),
                                               children[ i ] );
            files = traverseDir( new File( child ), files );
         }
      }
      else
      {
         String absolutePath = dir.getAbsolutePath(  );
         
         if( !absolutePath.contains( "CVS" ) && !absolutePath.contains( ".svn" ) )
         {
            String file = dir.getAbsolutePath(  ).substring( ESPDir.OVERLAY.getLocalPath(  ).length(  ) + 1 );
            files.add( PathUtil.convertPath( Platform.UNIX, file ) );
         }
      }
      
      return files;
   }
}

package com.fastsearch.gs.mojo.esp.enums;

import java.io.File;
import java.io.RandomAccessFile;
import java.math.BigInteger;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.security.MessageDigest;
import java.util.Date;
import java.util.Formatter;

import com.fastsearch.gs.mojo.artifact.ESPArtifact;
import com.fastsearch.gs.mojo.exceptions.ESPMojoException;
import com.fastsearch.gs.mojo.util.ProjectSettings;
import com.fastsearch.gs.mojo.util.PathUtil;
import com.fastsearch.gs.mojo.util.Platform;
import com.fastsearch.gs.mojo.util.SynchronisedLog;


public enum ESPFile
{
   INSTALLER            ( ESPDir.RELEASE_ESP,          "setup_Linux.bin", "setup.exe", false, false ),
   InstallProfile_xml   ( ESPDir.RESOURCE,             "InstallProfile.xml",           true,  true  ),
   index_profile_xml    ( ESPDir.RESOURCE,             "index-profile.xml",            true,  false ),
   IPROFILE_BLISSED     ( ESPDir.ESP_IPROFILE_BLISSED, "index-profile",                false, false ),
   IPROFILE_INSTALLED   ( ESPDir.ESP_IPROFILE,         "index-profile.xml",            false, false ),
   IPROFILE_BLISSMIRROR ( ESPDir.ESP_IPROFILE,         "index-profile",                false, false ),
   fastsearch_lic       ( ESPDir.RESOURCE,             "fastsearch.lic",               true,  true  ),
   setupenv_sh          ( ESPDir.ESP_BIN,              "setupenv.sh", "setupenv.bat",  false, false ),
   VERSION_xml          ( ESPDir.ESP_ETC,              "VERSION.xml",                  false, false ),
   all_log              ( ESPDir.ESP_SYSLOG,           "all.log",                      false, false ),
   banner_gif           ( ESPDir.ESP_HOTFIX,           "banner.gif",                   false, false ),
   FAST_logo_gif        ( ESPDir.ESP_HOTFIX,           "FAST_logo.gif",                false, false ),
   patch_md5            ( ESPDir.RELEASE_HOTFIX,       "patch.md5",                    false, false ),
   overlay_md5          ( ESPDir.OVERLAY,              "overlay.md5",                  false, false );

   private ESPDir relativePath;
   private String linuxName;
   private String windowsName;
   private boolean isPrerequisite;
   private boolean isTargetSpecific;
   
   
   private ESPFile( ESPDir path, String linuxName, String windowsName, boolean isPrerequisite, boolean isTargetSpecific )
   {
      this.relativePath     = path;
      this.linuxName        = linuxName;
      this.windowsName      = windowsName;
      this.isPrerequisite   = isPrerequisite;
      this.isTargetSpecific = isTargetSpecific;
   }
   
   
   private ESPFile( ESPDir path, String agnosticName, boolean isPrerequisite, boolean isTargetSpecific )
   {
      this( path, agnosticName, agnosticName, isPrerequisite, isTargetSpecific );
   }
   
   
   public String getName(  )
   {
      return getName( ProjectSettings.getTargetPlatform(  ) );
   }
   
   
   public String getName( Platform platform )
   {
      return ( Platform.WINDOWS == platform ) ? windowsName : linuxName;
   }

   
   public boolean isPrerequisite(  )
   {
      return isPrerequisite;
   }
   
   
   public String getLocalPath(  )
   {
      return getPath( ProjectSettings.getLocalPlatform(  ), ProjectSettings.getLocalLifecycleHome(  ) );
   }
   
   
   public String getLocalRelativePath(  )
   {
      return getPath( ProjectSettings.getLocalPlatform(  ), null );
   }
   
   
   public String getTargetDir(  )
   {
      return relativePath.getTargetPath(  );
//      if( isInstalled )
//         return getDir( ProjectSettings.getTargetPlatform(  ), ProjectSettings.getInstallDir(  ) );
//      else
//         return getDir( ProjectSettings.getTargetPlatform(  ), ProjectSettings.getRemoteLifecycleHome(  ) );
   }

   
   public String getTargetPath(  )
   {
      return PathUtil.joinPaths( getTargetDir(  ), getName(  ) );
   }
   
   
   public String getTargetPath( ESPArtifact artifact )
   {
      return PathUtil.joinPaths( getTargetDir(  ), artifact.getArtifactId(  ), artifact.getVersion(  ), getName(  ) );
   }
   
   
   public Date getLocalTimestamp(  )
   {
      return new Date( ( new File( getLocalPath(  ) ) ).lastModified(  ) );
   }
   
   
   public String getLocalMD5(  ) throws ESPMojoException
   {
      return getLocalMD5( getLocalPath(  ) );
   }
   
   
   public static String getLocalMD5( String localFile )
   {
      try
      {
         FileChannel channel = new RandomAccessFile( localFile, "r" ).getChannel(  );
         ByteBuffer buffer = channel.map( FileChannel.MapMode.READ_ONLY, 0, ( int )channel.size(  ) );
         MessageDigest digester = MessageDigest.getInstance( "md5" );

         digester.update( buffer.duplicate(  ) );
         byte[] digested = digester.digest(  );

         return new Formatter(  ).format( "%0" + ( digested.length * 2 ) + "x%n",
                                          new BigInteger( 1, digested ) ).out(  ).toString(  ).trim(  );
      }
      catch( Exception e )
      {
         SynchronisedLog.getLog(  ). error( "Exception occurred during computation of message digest (MD5) for file " + localFile + "." );
         return null;
      }
   }
   
   
   private String getDir( Platform platform, String baseDir )
   {
      return PathUtil.joinPaths( platform,
                                 ( null != baseDir ) ? baseDir : "",
                                 relativePath.getRelativePath( platform ),
                                 isTargetSpecific ? ProjectSettings.getTargetEnvironment(  ) : "" );
   }
   
   
   private String getPath( Platform platform, String baseDir )
   {
      return PathUtil.joinPaths( platform,
                                 getDir( platform, baseDir ),
                                 getName( ProjectSettings.getTargetPlatform(  ) ) ); 
   }
}

package com.fastsearch.gs.mojo.util;

import java.util.ArrayList;
import java.util.TreeMap;

import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import org.apache.maven.model.Dependency;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

import com.fastsearch.gs.mojo.artifact.ESPArtifact;
import com.fastsearch.gs.mojo.artifact.ESPOverlayArtifact;
import com.fastsearch.gs.mojo.artifact.ESPPatchArtifact;
import com.fastsearch.gs.mojo.artifact.ESPReleaseArtifact;
import com.fastsearch.gs.mojo.esp.enums.ESPFile;
import com.fastsearch.gs.mojo.esp.enums.ESPArtifactGroupId;
import com.fastsearch.gs.mojo.esp.enums.ESPDir;
import com.fastsearch.gs.mojo.esp.enums.ESPProperty;
import com.fastsearch.gs.mojo.exceptions.InvalidInstallProfileException;


public class ProjectSettings
{
   private static ProjectSettings instance = null;

   private static String customer;
   private static String engagement;
   private static String engagementPrefix;
   private static String targetEnvironment;
   private static boolean interactive;
   private static String localRepository;
   private static String localLifecycleHome;
   private static String remoteLifecycleHome;
   private static String installDir;
   private static String majorVersion;
   private static String minorVersion;
   private static String pointVersion;
   private static Platform localPlatform;
   private static Platform targetPlatform;
   private static ESPReleaseArtifact releaseArtifact;
   private static TreeMap<String, ESPArtifact> patchArtifacts = new TreeMap<String, ESPArtifact>(  );
   private static ESPOverlayArtifact overlayArtifact;
   

   private ProjectSettings(
         String _customer,
         String _engagement,
         String _prefix,
         String _projectDir,
         String _targetEnv,
         boolean _interactive,
         String _localRepository,
         ArrayList<Dependency> dependencies
      )
      throws InvalidInstallProfileException
   {
      customer           = _customer;
      engagement         = _engagement;
      engagementPrefix   = _prefix;
      targetEnvironment  = _targetEnv;
      interactive        = ( null != System.getProperty( ESPProperty.INTERACTIVE.getProperty(  ) ) )
                                 ? Boolean.parseBoolean( System.getProperty( ESPProperty.INTERACTIVE.getProperty(  ) ) )
                                 : _interactive;
      localRepository    = _localRepository;
      localLifecycleHome = _projectDir;
      
      try
      {
         XPath xPath = XPathFactory.newInstance(  ).newXPath(  );

         Node root = ( Node )xPath.evaluate( XPathUtil.ROOT, new InputSource( ESPFile.InstallProfile_xml.getLocalPath(  ) ), XPathConstants.NODE );
         
         String version = ( ( Node )xPath.evaluate( XPathUtil.VERSION, root, XPathConstants.NODE ) ).getNodeValue(  );
         majorVersion = version.substring( 0, 1 );
         minorVersion = version.substring( 2, 3 );
         pointVersion = version.substring( 4 );
         
         Node aHostNode = ( ( NodeList )xPath.evaluate( "host-set/host", root, XPathConstants.NODESET ) ).item( 0 );
         String platform = ( ( Node )xPath.evaluate( "property[@name='platform']/@value", aHostNode, XPathConstants.NODE ) ).getNodeValue(  );
         targetPlatform = Platform.getPlatform( platform );
         installDir = ( ( Node )xPath.evaluate( "property[@name='install-dir']/@value", aHostNode, XPathConstants.NODE ) ).getNodeValue(  );
         remoteLifecycleHome = PathUtil.joinPaths( PathUtil.dirName( installDir ), ESPDir.LIFECYCLE_HOME.getRelativePath(  ) );
         overlayArtifact = new ESPOverlayArtifact( customer.toLowerCase(  ).replace( " ", "" ) + "-" + engagementPrefix.toLowerCase(  ) );
         
         if( ( null != dependencies ) && ( !dependencies.isEmpty(  ) ) )
         {
            for( Dependency dependency : dependencies )
            {
               if( ESPArtifactGroupId.RELEASE.equals( ESPArtifactGroupId.getGroupId( dependency.getGroupId(  ) ) ) )
                  releaseArtifact = new ESPReleaseArtifact( dependency );
               else if( ESPArtifactGroupId.HOTFIX.equals( ESPArtifactGroupId.getGroupId( dependency.getGroupId(  ) ) ) )
                  patchArtifacts.put( dependency.getArtifactId(), new ESPPatchArtifact( dependency ) );
            }
         }
      }
      catch( XPathExpressionException e )
      {
         throw new InvalidInstallProfileException( e );
      }
   }
   
   
   public static void createInstance(
         String customer,
         String engagement,
         String prefix,
         String projectDir,
         String targetEnv,
         boolean interactive,
         String localRepository,
         ArrayList<Dependency> dependencies
      )
      throws InvalidInstallProfileException
   {
      if( null == instance )
         instance = new ProjectSettings( customer,
                                         engagement,
                                         prefix,
                                         projectDir,
                                         targetEnv,
                                         interactive,
                                         localRepository,
                                         dependencies );
   }
   
   
   public static boolean isInstantiated(  )
   {
      return ( null != instance );
   }


   public static String getCustomer(  )
   {
      return customer;
   }
   
   
   public static String getEngagement(  )
   {
      return engagement;
   }
   
   
   public static String getEngagementPrefix(  )
   {
      return engagementPrefix;
   }
   
   
   public static String getTargetEnvironment(  )
   {
      return targetEnvironment;
   }
   
   
   public static boolean inInteractiveMode(  )
   {
      return interactive;
   }
   
   
   public static String getLocalRepository(  )
   {
      return localRepository;
   }
   
   
   public static String getLocalLifecycleHome(  )
   {
      return localLifecycleHome;
   }
   
   
   public static String getRemoteLifecycleHome(  )
   {
      return remoteLifecycleHome;
   }
   
   
   public static String getInstallDir(  )
   {
      return installDir;
   }
   
   
   public static String getPointRelease(  )
   {
      return majorVersion + "." + minorVersion + "." + pointVersion;
   }
   
   
   public static String getMinorRelease(  )
   {
      return majorVersion + "." + minorVersion;
   }
   
   
   public static String getMajorRelease(  )
   {
      return majorVersion;
   }
   
   
   public static Platform getLocalPlatform(  )
   {
      return localPlatform;
   }
   
   
   public static Platform getTargetPlatform(  )
   {
      return targetPlatform;
   }


   public static ESPReleaseArtifact getReleaseArtifact(  )
   {
      return releaseArtifact;
   }


   public static TreeMap<String, ESPArtifact> getPatchArtifacts(  )
   {
      return patchArtifacts;
   }
   
   
   public static ESPOverlayArtifact getOverlayArtifact(  )
   {
      return overlayArtifact;
   }
   
   
   static
   {
      String osNameParts[] = System.getProperty( "os.name" ).split( " " );
      
      if( "Windows".equals( osNameParts[ 0 ] ) )
         localPlatform = Platform.WINDOWS;
      else
         localPlatform = Platform.LINUX;  // TODO: Need to handle other platforms as well...
   }
}

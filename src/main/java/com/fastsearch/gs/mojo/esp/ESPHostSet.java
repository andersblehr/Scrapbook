package com.fastsearch.gs.mojo.esp;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Stack;
import java.util.TreeMap;

import javax.xml.xpath.XPathExpressionException;

import org.apache.maven.plugin.logging.Log;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import com.fastsearch.gs.mojo.artifact.ESPArtifact;
import com.fastsearch.gs.mojo.esp.enums.ESPDir;
import com.fastsearch.gs.mojo.esp.enums.ESPFile;
import com.fastsearch.gs.mojo.esp.enums.ESPProperty;
import com.fastsearch.gs.mojo.esp.enums.NctrlCommand;
import com.fastsearch.gs.mojo.exceptions.BlissException;
import com.fastsearch.gs.mojo.exceptions.ESPMojoException;
import com.fastsearch.gs.mojo.exceptions.InconsistentVersionsException;
import com.fastsearch.gs.mojo.exceptions.InvalidInstallProfileException;
import com.fastsearch.gs.mojo.exceptions.InvalidProjectException;
import com.fastsearch.gs.mojo.exceptions.MissingBackupException;
import com.fastsearch.gs.mojo.exceptions.MissingInstallationException;
import com.fastsearch.gs.mojo.exceptions.RemoteSessionException;
import com.fastsearch.gs.mojo.exceptions.UnsupportedESPVersionException;
import com.fastsearch.gs.mojo.exceptions.UnsupportedPlatformException;
import com.fastsearch.gs.mojo.exceptions.UserTerminationException;
import com.fastsearch.gs.mojo.remote.RemoteSession;
import com.fastsearch.gs.mojo.util.PathUtil;
import com.fastsearch.gs.mojo.util.ProjectSettings;
import com.fastsearch.gs.mojo.util.Platform;
import com.fastsearch.gs.mojo.util.SynchronisedLog;
import com.fastsearch.gs.mojo.util.XPathUtil;


public class ESPHostSet
{
   private static ESPHostSet instance = null;
   
   private static Log log = SynchronisedLog.getLog(  );
   private HashMap<ESPComponent, ArrayList<ESPHost>> componentToHostsMap = new HashMap<ESPComponent, ArrayList<ESPHost>>(  );
   private HashMap<String, ESPHost> hostIdToHostMap = new HashMap<String, ESPHost>(  ); 
   
   private boolean hasErrors;
   private boolean hasWarnings;

   
   private ESPHostSet(  )
      throws InvalidInstallProfileException, 
             UnsupportedESPVersionException, 
             UnsupportedPlatformException, 
             RemoteSessionException,
             InconsistentVersionsException
   {
      componentToHostsMap.put( ESPComponent.ALL,                new ArrayList<ESPHost>(  ) );
      componentToHostsMap.put( ESPComponent.ADMINGUI,           new ArrayList<ESPHost>(  ) );
      componentToHostsMap.put( ESPComponent.ADMINSERVER,        new ArrayList<ESPHost>(  ) );
      componentToHostsMap.put( ESPComponent.ANCHORSERVER,       new ArrayList<ESPHost>(  ) );
      componentToHostsMap.put( ESPComponent.CLARITY,            new ArrayList<ESPHost>(  ) );
      componentToHostsMap.put( ESPComponent.CONFIGSERVER,       new ArrayList<ESPHost>(  ) );
      componentToHostsMap.put( ESPComponent.CONTENTDISTRIBUTOR, new ArrayList<ESPHost>(  ) );
      componentToHostsMap.put( ESPComponent.CRAWLER,            new ArrayList<ESPHost>(  ) );
      componentToHostsMap.put( ESPComponent.DUPSERVER,          new ArrayList<ESPHost>(  ) );
      componentToHostsMap.put( ESPComponent.INDEXER,            new ArrayList<ESPHost>(  ) );
      componentToHostsMap.put( ESPComponent.INDEXINGDISPATCHER, new ArrayList<ESPHost>(  ) );
      componentToHostsMap.put( ESPComponent.LICENSEMANAGER,     new ArrayList<ESPHost>(  ) );
      componentToHostsMap.put( ESPComponent.NAMESERVICE,        new ArrayList<ESPHost>(  ) );
      componentToHostsMap.put( ESPComponent.PROCSERVER,         new ArrayList<ESPHost>(  ) );
      componentToHostsMap.put( ESPComponent.QRSERVER,           new ArrayList<ESPHost>(  ) );
      componentToHostsMap.put( ESPComponent.RELBENCH,           new ArrayList<ESPHost>(  ) );
      componentToHostsMap.put( ESPComponent.RESOURCESERVICE,    new ArrayList<ESPHost>(  ) );
      componentToHostsMap.put( ESPComponent.SEARCH,             new ArrayList<ESPHost>(  ) );
      componentToHostsMap.put( ESPComponent.STORAGESERVICE,     new ArrayList<ESPHost>(  ) );
      componentToHostsMap.put( ESPComponent.UBERMASTER,         new ArrayList<ESPHost>(  ) );

      try
      {
         XPathUtil xPathUtil = new XPathUtil( ESPFile.InstallProfile_xml.getLocalPath(  ) );
         
         if( ( "4".equals( ProjectSettings.getMajorRelease(  ) ) ) || ( "3".equals( ProjectSettings.getMajorRelease(  ) ) ) || ( "2".equals( ProjectSettings.getMajorRelease(  ) ) ) )
            throw new UnsupportedESPVersionException( ProjectSettings.getPointRelease(  ) );
         
         NodeList hostList = xPathUtil.getNodeList( XPathUtil.HOSTSET );
         ArrayList<Thread> hostInstantiators = new ArrayList<Thread>(  );
         
         for( int i = 0; i < hostList.getLength(  ); i++ )
            hostInstantiators.add( new Thread( new ESPHostInstatiator( hostList.item( i ), xPathUtil ) ) ); 
         
         runThreads( hostInstantiators );
         
         for( ESPComponent component : ESPComponent.values(  ) )
         {
            if( component.inInstallProfile(  ) && component.inVersion(  ) )
            {
               NodeList nodes = xPathUtil.getNodeList( component );
            
               for( int i = 0; ( ( null != nodes ) && ( i < nodes.getLength(  ) ) ); i++ )
               {
                  String hostId = xPathUtil.getNode( XPathUtil.HOSTREF, nodes.item( i ) ).getNodeValue(  );

                  boolean componentIncluded = true;

                  if( ESPComponent.INDEXER == component )
                     componentIncluded = "true".equals( xPathUtil.getNode( XPathUtil.IS_INDEXER, nodes.item( i ) ).getNodeValue(  ) );
                  if( ESPComponent.SEARCH  == component )
                     componentIncluded = "true".equals( xPathUtil.getNode( XPathUtil.IS_SEARCH,  nodes.item( i ) ).getNodeValue(  ) );
                  
                  if ( componentIncluded )
                  {
                     ESPHost host = hostIdToHostMap.get( hostId );
                     host.addComponent( component );
                     componentToHostsMap.get( component ).add( host );
                  }
               }
            }
         }
         
         inspect( false );
      }
      catch( InterruptedException e )
      {
         log.error( "ESPHostInstantiator thread was interrupted, this should not happen." );
      }
      catch( XPathExpressionException e )
      {
         throw new InvalidInstallProfileException( e );
      }
   }

   
   public static boolean isInstantiated(  )
   {
      return ( null != instance );
   }
   
   
   public static ESPHostSet getInstance(  )
      throws InvalidInstallProfileException,
             UnsupportedESPVersionException,
             UnsupportedPlatformException,
             RemoteSessionException,
             InconsistentVersionsException,
             InvalidProjectException
   {
      if( null == instance )
      {
         try
         {
            log.info( "----------------------------------------------------------------------------" );
            log.info( "Project details:" );
            log.info( "  Customer:         " + ProjectSettings.getCustomer(  ) );
            log.info( "  Project:          " + ProjectSettings.getEngagement(  ) + " (" + ProjectSettings.getEngagementPrefix(  ) + ")" );
            log.info( "  Target env:       " + ProjectSettings.getTargetEnvironment(  ) );
            log.info( "  Local host:       " + InetAddress.getLocalHost(  ).getCanonicalHostName(  ) );
            log.info( "  Local repository: " + ProjectSettings.getLocalRepository(  ) );
            log.info( "  Project dir (pd): " + ProjectSettings.getLocalLifecycleHome(  ) );
            
            for( ESPFile file : ESPFile.values(  ) )
            {
               if( file.isPrerequisite(  ) && !( ( new File( file.getLocalPath(  ) ) ).exists(  ) ) )
                  throw new InvalidProjectException( "Local prerequisite file " + file.getLocalPath(  ) + " is missing, aborting." );
            }
            
            log.info( "  License:          " + PathUtil.joinPaths( ProjectSettings.getLocalPlatform(  ), "(pd)", ESPFile.fastsearch_lic.getLocalRelativePath(  ) ) );
            log.info( "  Install profile:  " + PathUtil.joinPaths( ProjectSettings.getLocalPlatform(  ), "(pd)", ESPFile.InstallProfile_xml.getLocalRelativePath(  ) ) );
            log.info( "  Index profile:    " + PathUtil.joinPaths( ProjectSettings.getLocalPlatform(  ), "(pd)", ESPFile.index_profile_xml.getLocalRelativePath(  ) ) );
            log.info( "Connecting to hosts:" );
            
            instance = new ESPHostSet(  );
            
            log.info( "Installation details:" );
            log.info( "  ESP version:      " + ProjectSettings.getPointRelease(  ) );
            log.info( "  Platform:         " + instance.getPlatform(  ).asString(  ) );
            log.info( "  Installation dir: " + instance.getInstallDir(  ) );
            log.info( "  User name:        " + instance.getUsername(  ) );
            log.info( "  Base port:        " + instance.getBasePort(  ) );
            log.info( "  Remote command:   " + instance.getRemoteCommand(  ) );
            
            log.info( "----------------------------------------------------------------------------" );
         }
         catch( UnknownHostException e )
         {
            log.warn( "Unable to look up local host, may or may not be a problem...", e );
         }
      }
      
      return instance;
   }
   
   
   public boolean confirmAction( String message ) throws UserTerminationException
   {
      if( ProjectSettings.inInteractiveMode(  ) )
      {
         BufferedReader inputReader = new BufferedReader( new InputStreamReader( System.in ) );
         
         try
         {
            log.warn( message );
            log.warn( "Press any key to continue, or <Ctrl-C> to abort." );
   
            if( -1 == inputReader.read(  ) )
               throw new UserTerminationException(  );
            else
               return true;
         }
         catch( IOException e )
         {
            throw new UserTerminationException( "Caught IOException when attempting to read user input", e );
         }
      }
      else
      {
         log.info( "..not in interactive mode, continuing without user interaction." );
         return true;
      }
   }
   
   
   public boolean isInstalled(  ) throws RemoteSessionException 
   {
      boolean installedOnAll  = true;
      
      for( ESPHost host : getHosts(  ) )
         installedOnAll  = installedOnAll && host.isInstalled(  );
      
      return installedOnAll;
   }
   
   
   public boolean installationIsCurrent(  ) throws RemoteSessionException, ESPMojoException
   {
      boolean forceInstall = false;
      
      if( null != System.getProperty( ESPProperty.REINSTALL.getProperty(  ) ) )
         forceInstall = Boolean.parseBoolean( System.getProperty( ESPProperty.REINSTALL.getProperty(  ) ) );
      
      return ( !forceInstall && isInstalled(  ) && getAdminHost(  ).fileIsCurrent( ESPFile.InstallProfile_xml ) );
   }
   
   
   public void install(  ) throws RemoteSessionException, ESPMojoException
   {
      ESPHost adminHost = getAdminHost(  );

      boolean installationBundleOK    = adminHost.hasPackagedArtifact( ProjectSettings.getReleaseArtifact(  ) );
      boolean licenseFileIsCurrent    = adminHost.fileIsCurrent( ESPFile.fastsearch_lic );
      boolean installProfileIsCurrent = adminHost.fileIsCurrent( ESPFile.InstallProfile_xml );
      boolean indexProfileIsCurrent   = adminHost.fileIsCurrent( ESPFile.index_profile_xml );
      
      log.info( "Distributing files as required:" );
      
      if( installationBundleOK )
         log.info( "  + [" + adminHost.getHostname(  ) + "] Available: Installation bundle." );
      else
      {
         log.info( "  + [" + adminHost.getHostname(  ) + "] Receiving from local repository: Installation bundle..." );
         adminHost.putFile( ProjectSettings.getReleaseArtifact(  ) );
      }
      
      if( licenseFileIsCurrent )
         log.info( "  + [" + adminHost.getHostname(  ) + "] Up to date: License file." );
      else
      {
         log.info( "  + [" + adminHost.getHostname(  ) + "] Receiving from local host: License file..." );
         adminHost.putFile( ESPFile.fastsearch_lic );
      }
 
      if( installProfileIsCurrent )
         log.info( "  + [" + adminHost.getHostname(  ) + "] Up to date: Install profile." );
      else
      {
         log.info( "  + [" + adminHost.getHostname(  ) + "] Receiving from local host: Install profile..." );
         adminHost.putFile( ESPFile.InstallProfile_xml );
      }
 
      if( indexProfileIsCurrent )
         log.info( "  + [" + adminHost.getHostname(  ) + "] Up to date: Index profile." );
      else
      {
         log.info( "  + [" + adminHost.getHostname(  ) + "] Receiving from local host: Index profile..." );
         adminHost.putFile( ESPFile.index_profile_xml );
      }

      for( ESPHost host : getHosts(  ) )
      {
         if( !host.isAdminHost(  ) )
         {
            if( host.hasPackagedArtifact( ProjectSettings.getReleaseArtifact(  ) ) )
               log.info( "  + [" + host.getHostname(  ) + "] Available: Installation bundle." );
            else
            {
               log.info( "  + [" + host.getHostname(  ) + "] Receiving from " + adminHost.getHostname(  ) + ": Installation bundle..." );
               host.copyFileFromHost( adminHost, ProjectSettings.getReleaseArtifact(  ) );
            }
   
            if( host.getRemoteSession(  ).getMD5( ESPFile.fastsearch_lic.getTargetPath(  ) ).equals( ESPFile.fastsearch_lic.getLocalMD5(  ) ) )
               log.info( "  + [" + host.getHostname(  ) + "] Up to date: License file." );
            else
            {
               log.info( "  + [" + host.getHostname(  ) + "] Receiving from " + adminHost.getHostname(  ) + ": License file..." );
               host.copyFileFromHost( adminHost, ESPFile.fastsearch_lic );
            }
       
            if( host.getRemoteSession(  ).getMD5( ESPFile.InstallProfile_xml.getTargetPath(  ) ).equals( ESPFile.InstallProfile_xml.getLocalMD5(  ) ) )
               log.info( "  + [" + host.getHostname(  ) + "] Up to date: Install profile." );
            else
            {
               log.info( "  + [" + host.getHostname(  ) + "] Receiving from " + adminHost.getHostname(  ) + ": Install profile..." );
               host.copyFileFromHost( adminHost, ESPFile.InstallProfile_xml );
            }
       
            if( host.getRemoteSession(  ).getMD5( ESPFile.index_profile_xml.getTargetPath(  ) ).equals( ESPFile.index_profile_xml.getLocalMD5(  ) ) )
               log.info( "  + [" + host.getHostname(  ) + "] Up to date: Index profile." );
            else
            {
               log.info( "  + [" + host.getHostname(  ) + "] Receiving from " + adminHost.getHostname(  ) + ": Index profile..." );
               host.copyFileFromHost( adminHost, ESPFile.index_profile_xml );
            }
         }
      }

      unpackArtifact( ProjectSettings.getReleaseArtifact(  ) );
      
      log.info( "Installing ESP " + ProjectSettings.getPointRelease(  ) + " on all hosts (may take a few minutes):" );
      doInstallAction( true );
   }
   
   
   public void uninstall(  ) throws RemoteSessionException, UserTerminationException
   {
      log.info( "Uninstalling ESP " + ProjectSettings.getPointRelease(  ) + " on all hosts:" );
      doInstallAction( false );
   }
   
   
   public boolean isPatched(  ) throws RemoteSessionException, MissingInstallationException
   {
      if( isInstalled(  ) )
      {
         boolean isPatched = false;
         
         for( ESPHost host : getHosts(  ) )
            isPatched = isPatched || host.isPatched(  );
         
         return isPatched;
      }
      else
         throw new MissingInstallationException(  );
   }

   
   public boolean hasPackagedArtifact( ESPArtifact artifact ) throws RemoteSessionException, MissingInstallationException
   {
      if( isInstalled(  ) )
      {
         boolean hasPackagedArtifact = true;
         
         for( ESPHost host : getHosts(  ) )
            hasPackagedArtifact = hasPackagedArtifact && host.hasPackagedArtifact( artifact );
         
         return hasPackagedArtifact;
      }
      else
         throw new MissingInstallationException(  );
   }
   
   
   public boolean hasAppliedArtifact( ESPArtifact artifact ) throws RemoteSessionException, MissingInstallationException
   {
      if( isInstalled(  ) )
      {
         boolean hasAppliedArtifact = true;
         
         for( ESPHost host : getHosts(  ) )
            hasAppliedArtifact = hasAppliedArtifact && host.hasAppliedArtifact( artifact );
         
         return hasAppliedArtifact;
      }
      else
         throw new MissingInstallationException(  );
   }
   
   
   public boolean hasAllPatches(  ) throws RemoteSessionException, MissingInstallationException
   {
      if( isInstalled(  ) )
      {
         boolean hasPatches = true;
         
         for( ESPHost host : getHosts(  ) )
            for( ESPArtifact patch : ProjectSettings.getPatchArtifacts(  ).values(  ) )
               hasPatches = hasPatches && host.hasAppliedArtifact( patch );
         
         return hasPatches;
      }
      else
         throw new MissingInstallationException(  );
   }
   
   
   public void patch( TreeMap<String, ESPArtifact> patchArtifacts ) throws RemoteSessionException, MissingInstallationException
   {
      ESPHost adminHost = getAdminHost(  );
      ArrayList<ESPArtifact> patchesToApply = new ArrayList<ESPArtifact>(  );
      TreeMap<String, ESPArtifact> patchesToRollback = new TreeMap<String, ESPArtifact>(  );
      
      boolean missingPatchesFound = false;
      
      for( ESPArtifact patch : patchArtifacts.values(  ) )
      {
         boolean hasPatch = hasAppliedArtifact( patch );
         
         if( missingPatchesFound && hasPatch )
         {
            patchesToRollback.put( patch.getArtifactId(  ), patch );
            patchesToApply.add( patch );
         }
         
         if( !hasPatch )
         {
            patchesToApply.add( patch );
            missingPatchesFound = true;
         }
      }
      
      if( 0 < patchesToRollback.size(  ) )
      {
         log.info( "Need to temporarily roll back hotfixes prior to applying new hotfix(es):" );
         
         for( ESPArtifact patch : patchesToRollback.values(  ) )
            log.info( "  + " + patch.getArtifactId(  ) );
         
         performRippledRollback( patchesToRollback, null );
      }

      for( ESPArtifact patch : patchesToApply )
      {
         if( !hasPackagedArtifact( patch ) )
         {
            log.info( "Distributing: Hotfix '" + patch.getArtifactId(  ) + "':" );
            
            if( !adminHost.hasPackagedArtifact( patch ) )
            {
               log.info( "  + [" + adminHost.getHostname(  ) + "] Receiving from local repository: Hotfix '" + patch.getArtifactId(  ) + "'..." ); 
               adminHost.putFile( patch );
            }
            else
               log.info( "  + [" + adminHost.getHostname(  ) + "] Available: Hotfix '" + patch.getArtifactId(  ) + "'." );
   
            for( ESPHost host : getHosts(  ) )
            {
               if( !host.hasAppliedArtifact( patch ) && !host.hasPackagedArtifact( patch ) )
               {
                  log.info( "  + [" + host.getHostname(  ) + "] Receiving from " + adminHost.getHostname(  ) + ": Hotfix '" + patch.getArtifactId(  ) + "'..." ); 
                  host.copyFileFromHost( adminHost, patch );
               }
               else if( !host.isAdminHost(  ) )
                  log.info( "  + [" + host.getHostname(  ) + "] Available: Hotfix '" + patch.getArtifactId(  ) + "'." );
            }
            
            unpackArtifact( patch );
         }

         applyArtifact( patch );
      }
   }
   
   
   public void rollback( ESPArtifact artifact ) throws RemoteSessionException
   {
      TreeMap<String, ESPArtifact> artifactMap = new TreeMap<String, ESPArtifact>(  );

      artifactMap.put( artifact.getArtifactId(  ), artifact );
      rollback( artifactMap, false );
   }
   
   
   public void rollback( TreeMap<String, ESPArtifact> irrevocableRollbackArtifacts, boolean reapplyTemporaryRollbacks )
      throws RemoteSessionException
   {
      TreeMap<String, ESPArtifact> installedOrConfiguredPatches = new TreeMap<String, ESPArtifact>( ProjectSettings.getPatchArtifacts(  ) );
      TreeMap<String, ESPArtifact> allRollbackArtifacts = new TreeMap<String, ESPArtifact>( irrevocableRollbackArtifacts );

      for( ESPArtifact artifact : irrevocableRollbackArtifacts.values(  ) )
         if( !installedOrConfiguredPatches.containsKey( artifact.getArtifactId(  ) ) )
            installedOrConfiguredPatches.put( artifact.getArtifactId(  ), artifact );
      
      for( ESPArtifact artifact : irrevocableRollbackArtifacts.values(  ) )
      {
         if( artifact.isPatch(  ) )
         {
            boolean artifactFound = false;
            
            for( ESPArtifact patch : installedOrConfiguredPatches.values(  ) )
            {
               if( artifactFound && !allRollbackArtifacts.containsKey( patch.getArtifactId(  ) ) )
                  allRollbackArtifacts.put( patch.getArtifactId(  ), patch );
               
               if( !artifactFound )
                  artifactFound = ( patch == artifact );
            }
         }
      }
      
      performRippledRollback( allRollbackArtifacts, irrevocableRollbackArtifacts );
      
      if( reapplyTemporaryRollbacks )
      {
         TreeMap<String, ESPArtifact> artifactsToReapply = new TreeMap<String, ESPArtifact>( allRollbackArtifacts );
         
         for( ESPArtifact artifact : irrevocableRollbackArtifacts.values(  ) )
            artifactsToReapply.remove( artifact.getArtifactId(  ) );
         
         for( ESPArtifact artifact : artifactsToReapply.values(  ) )
         {
            unpackArtifact( artifact );
            applyArtifact( artifact );
         }
      }
   }
   
   
   public boolean overlayIsCurrent(  ) throws RemoteSessionException, ESPMojoException
   {
      boolean isCurrent = true;
      
      for( ESPHost host : getHosts(  ) )
         isCurrent = isCurrent && host.overlayIsCurrent(  );
      
      return isCurrent;
   }
   
   
   public void deployOverlay(  ) throws RemoteSessionException
   {
      ESPHost adminHost = getAdminHost(  );
      String overlayArtifactId = ProjectSettings.getOverlayArtifact(  ).getArtifactId(  );
      
      log.info( "Distributing overlay '" + overlayArtifactId + "' as required:" );
      log.info( "  + [" + adminHost.getHostname(  ) + "] Receiving from local host: Overlay '" + overlayArtifactId + "'..." );
      
      // TODO: Somehow use missingOverlayFiles, changedOverlayFiles and redundantOverlayFiles in ESPHost to apply only those that have changed and/or been added/removed.
      
      for( String file : ProjectSettings.getOverlayArtifact(  ).getOverlayFiles(  ) )
      {
         String localFile =
            PathUtil.joinPaths( ProjectSettings.getLocalPlatform(  ),
                                ESPDir.OVERLAY.getLocalPath(  ), file );
         String remoteDir =
            PathUtil.joinPaths( ESPDir.OVERLAY.getTargetPath(  ),
                                PathUtil.dirName( PathUtil.convertPath( file ) ) );

         adminHost.putFile( localFile, remoteDir );
      }

      for( ESPHost host : getHosts(  ) )
      {
         if( !host.isAdminHost(  ) )
         {
            log.info( "  + [" + host.getHostname(  ) + "] Receiving from " + adminHost.getHostname(  ) + ": Overlay '" + overlayArtifactId + "'..." );
            host.copyDirFromHost( adminHost, ESPDir.OVERLAY );
         }
      }

      applyArtifact( ProjectSettings.getOverlayArtifact(  ) );
   }

   
   public boolean indexProfileIsCurrent(  ) throws RemoteSessionException
   {
      RemoteSession remoteSession = getAdminHost(  ).getRemoteSession(  );
      
      String md5LifecycleIndexProfile = remoteSession.getMD5( ESPFile.index_profile_xml.getTargetPath(  ) );
      String md5DeployedIndexProfile = remoteSession.getMD5( ESPFile.IPROFILE_BLISSED.getTargetPath(  ) );

      return md5LifecycleIndexProfile.equals( md5DeployedIndexProfile );
   }
   
   
   public void uploadIndexProfile(  ) throws RemoteSessionException, UserTerminationException, BlissException
   {
      RemoteSession remoteSession = getAdminHost(  ).getRemoteSession(  );
      
      remoteSession.copyFile( ESPFile.index_profile_xml.getTargetPath(  ), ESPDir.ESP_IPROFILE.getTargetPath(  ) );
      remoteSession.copyFile( ESPFile.IPROFILE_BLISSED.getTargetPath(  ), ESPDir.ESP_IPROFILE.getTargetPath(  ) );
      
      log.info( "Checking validity of index profile..." );
      String result = remoteSession.execute( "bliss -V " + ESPFile.IPROFILE_INSTALLED.getTargetPath(  ), true );
      
      if( !result.contains( "ERROR" ) )
      {
         log.info( "  + Index profile is valid." );
         
         log.info( "Checking if cold update is required..." );
         result = remoteSession.execute( "bliss -x -c " + ESPFile.IPROFILE_INSTALLED.getTargetPath(  ) + " " + ESPFile.IPROFILE_BLISSMIRROR.getTargetPath(  ), true );
         
         boolean coldUpdateRequired = result.contains( "Compatibility check: Index-profiles are incompatible" );
         
         if( coldUpdateRequired )
         {
            log.info( "  + Cold update is required." );
            confirmAction( "Cold update required, all data will be lost. Continue?" );
            log.info( "Performing cold update of index profile..." );
         }
         else
         {
            log.info( "  + Cold update is not required." );
            log.info( "Performing hot update of index profile..." );
         }
         
         result = remoteSession.execute( "bliss -i -C " + ESPFile.IPROFILE_INSTALLED.getTargetPath(  ), true );
         
         if( result.contains( "ERROR" ) )
         {
            String[] lines = result.split( "\n" );
            
            for( String line : lines )
               log.error( line );
            
            throw new BlissException( result );
         }
         else
         {
            log.info( "  + " + ( coldUpdateRequired ? "Cold" : "Hot" ) + " update of index profile complete." );
         }
      }
      
      remoteSession.deleteFile( ESPFile.IPROFILE_BLISSMIRROR.getTargetPath(  ) );
   }
   
   
   public void start( boolean showErrors ) throws RemoteSessionException
   {
      log.info( "  + [" + getAdminHost(  ).getHostname(  ) + "] " + NctrlCommand.START.getStartupMsg(  ) );
      getAdminHost(  ).runNctrlCommand( NctrlCommand.START );
      log.info( "  + [" + getAdminHost(  ).getHostname(  ) + "] " + NctrlCommand.START.getCompletionMsg(  ) );
      
      ArrayList<Thread> hostManagers = new ArrayList<Thread>(  );
      
      for( ESPHost host : getHosts(  ) )
      {
         if( !host.isAdminHost(  ) )
         {
            host.setNctrlCommand( NctrlCommand.START );
            hostManagers.add( new Thread( new NctrlManager( host ) ) );
         }
      }

      try
      {
         runThreads( hostManagers );
         
         synchronized( this )
         {
            wait( 10000 );
         }

         inspect( showErrors );
      }
      catch( InterruptedException e )
      {
         throw new RemoteSessionException( "Exception occurred while waiting for installation of ESP on hosts to complete", e );
      }
   }


   public void stop(  ) throws RemoteSessionException, UserTerminationException
   {
      ArrayList<Thread> hostManagers = new ArrayList<Thread>(  );
      
      for( ESPHost host : getHosts(  ) )
      {
         if( !host.isAdminHost(  ) )
         {
            host.setNctrlCommand( NctrlCommand.STOP );
            hostManagers.add( new Thread( new NctrlManager( host ) ) );
         }
      }

      try
      {
         runThreads( hostManagers );
      }
      catch( InterruptedException e )
      {
         throw new RemoteSessionException( "Exception occurred while waiting for installation of ESP on hosts to complete", e );
      }

      log.info( "  + [" + getAdminHost(  ).getHostname(  ) + "] " + NctrlCommand.STOP.getStartupMsg(  ) );
      getAdminHost(  ).runNctrlCommand( NctrlCommand.STOP );
      log.info( "  + [" + getAdminHost(  ).getHostname(  ) + "] " + NctrlCommand.STOP.getCompletionMsg(  ) );
   }


   public void inspect( boolean showErrors ) throws RemoteSessionException
   {
      String logContents;
      RemoteSession remoteSession = getAdminHost(  ).getRemoteSession(  );
      
      if( remoteSession.existsFile( ESPFile.all_log.getTargetPath(  ) ) )
         logContents = remoteSession.getFileContents( ESPFile.all_log.getTargetPath(  ) );
      else
         logContents = "(none)";
      
      hasErrors = logContents.contains( "ERROR" ) || logContents.contains( "CRITICAL" );
      hasWarnings = logContents.contains( "WARNING" );
      
      if( hasErrors && showErrors )
      {
         String[] logLines = logContents.split( "\n" );
         ArrayList<String> errorLines = new ArrayList<String>(  );
         
         for( String logLine : logLines )
         {
            if( logLine.contains( "ERROR" ) )
               errorLines.add( "ERROR: " + logLine.substring( logLine.indexOf( " : " ) + 3 ) );
            else if( logLine.contains( "CRITICAL" ) )
               errorLines.add( "CRITICAL: " + logLine.substring( logLine.indexOf( " : " ) + 3 ) );
         }
         
         int totalErrors = errorLines.size(  );
         
         while( 10 < errorLines.size(  ) )
            errorLines.remove( 0 );
         
         log.error( "System log has errors:" );
         log.info( "" );
         
         if( 10 < totalErrors )
         {
            log.info( "! (..not displaying " + ( totalErrors - 10 ) + " earlier errors..)" );
            log.info( "!" );
         }
         
         for( String errorLine : errorLines )
            log.info( "! " + errorLine );
         
         log.info( "" );
         log.info( "System log has errors, manual inspection required." );
      }
   }
   
   
   public boolean isRunning(  ) throws RemoteSessionException
   {
      boolean isRunning = true;
      
      for( ESPHost host : getHosts(  ) )
         isRunning = isRunning && host.isRunning(  );
      
      return isRunning;
   }
   
   
   public boolean someRunning(  ) throws RemoteSessionException
   {
      boolean someRunning = false;
      
      for( ESPHost host : getHosts(  ) )
         someRunning = someRunning || host.isRunning(  );
      
      return someRunning;
   }


   public boolean isDown(  ) throws RemoteSessionException
   {
      boolean isDown = true;
      
      for( ESPHost host : getHosts(  ) )
         isDown = isDown && host.isDown(  );
      
      return isDown;
   }
   
   
   public boolean hasErrors(  )
   {
      return hasErrors;
   }
   
   
   public boolean hasWarnings(  )
   {
      return hasWarnings;
   }
   
   
   public ESPHost getAdminHost(  )
   {
      return componentToHostsMap.get( ESPComponent.CONFIGSERVER ).get( 0 );
   }
   
   
   public ArrayList<ESPHost> getHosts(  )
   {
      return componentToHostsMap.get( ESPComponent.ALL );
   }
   
   
   public ArrayList<ESPHost> getHostsForComponent( ESPComponent component )
   {
      return componentToHostsMap.get( component );
   }
   
   
   public String getBasePort(  )
   {
      return componentToHostsMap.get( ESPComponent.ALL ).get( 0 ).getBasePort(  );
   }


   public String getInstallDir(  )
   {
      return componentToHostsMap.get( ESPComponent.ALL ).get( 0 ).getInstallDir(  );
   }


   public Platform getPlatform(  )
   {
      return componentToHostsMap.get( ESPComponent.ALL ).get( 0 ).getPlatform(  );
   }


   public String getRemoteCommand(  ) 
   {
      return componentToHostsMap.get( ESPComponent.ALL ).get( 0 ).getRemoteCommand(  );
   }


   public String getUsername(  )
   {
      return componentToHostsMap.get( ESPComponent.ALL ).get( 0 ).getUsername(  );
   }
   
   
   private void unpackArtifact( ESPArtifact artifact ) throws RemoteSessionException
   {
      try
      {
         ArrayList<Thread> unpackers = new ArrayList<Thread>(  );
         
         for( ESPHost host : getHosts(  ) )
            if( host.unpackingRequired( artifact ) )
               unpackers.add( new Thread( new ArtifactUnpacker( host, artifact ) ) );
         
         if( 0 < unpackers.size(  ) )
         {
            log.info( "Unpacking: " + artifact.getCapitalisedDescription(  ) + " '" + artifact.getArtifactId(  ) + "':" );
            runThreads( unpackers );
         }
      }
      catch( InterruptedException e )
      {
         throw new RemoteSessionException( "Unpack threads were interrupted before unpacking was complete.", e );
      }
   }
   
   
   private void doInstallAction( boolean install ) throws RemoteSessionException
   {
      try
      {
         ArrayList<Thread> hostInstallers = new ArrayList<Thread>(  );
         
         for( ESPHost host : getHosts(  ) )
            hostInstallers.add( new Thread( new InstallManager( host, install ) ) );
         
         runThreads( hostInstallers );
      }
      catch( InterruptedException e )
      {
         throw new RemoteSessionException( "Installation threads were interrupted before installation was complete.", e );
      }
   }

   
   private void applyArtifact( ESPArtifact artifact ) throws RemoteSessionException
   {
      try
      {
         ArrayList<Thread> artifactApplicators = new ArrayList<Thread>(  );
         
         for( ESPHost host : getHosts(  ) )
            if( !host.hasAppliedArtifact( artifact ) )
               artifactApplicators.add( new Thread( new ArtifactApplicator( host, artifact ) ) );
         
         if( 0 < artifactApplicators.size(  ) )
         {
            log.info( "Applying: " + artifact.getCapitalisedDescription(  ) + " '" + artifact.getArtifactId(  ) + "' on all hosts:" );
            runThreads( artifactApplicators );
         }
      }
      catch( InterruptedException e )
      {
         throw new RemoteSessionException( artifact.getCapitalisedDescription(  ) + " application threads were interrupted before application of " + artifact.getDescription(  ) + " '" + artifact.getArtifactId(  ) + "' was complete.", e );
      }
   }
   
   
   private void performRippledRollback(
         TreeMap<String, ESPArtifact> allRollbackArtifacts,
         TreeMap<String, ESPArtifact> irrevocableRollbackArtifacts ) throws RemoteSessionException   
   {
      Stack<ESPArtifact> rollbackStack = new Stack<ESPArtifact>(  );
      
      for( ESPArtifact artifact : allRollbackArtifacts.values(  ) )
         rollbackStack.push( artifact );
      
      while( !rollbackStack.empty(  ) )
      {
         try
         {
            ESPArtifact rollbackArtifact = rollbackStack.pop(  );
            
            boolean toBeReapplied = ( null == irrevocableRollbackArtifacts) || !irrevocableRollbackArtifacts.containsKey( rollbackArtifact.getArtifactId(  ) );
            
            if( toBeReapplied )
               log.info( "Temporarily rolling back " + rollbackArtifact.getDescription(  ) + " '" + rollbackArtifact.getArtifactId(  ) + "' on all hosts:" );
            else
               log.info( "Permanently rolling back " + rollbackArtifact.getDescription(  ) + " '" + rollbackArtifact.getArtifactId(  ) + "' on all hosts:" );
   
            ArrayList<Thread> rollbackManagers = new ArrayList<Thread>(  );

            for( ESPHost host : getHosts(  ) )
            {
               if( host.hasBackup( rollbackArtifact ) )
                  rollbackManagers.add( new Thread( new RollbackManager( host, rollbackArtifact, toBeReapplied ) ) );
               else
                  log.warn( "  + [" + host.getHostname(  ) + "] No backup available for " + rollbackArtifact.getDescription(  ) + " '" + rollbackArtifact.getArtifactId(  ) + "', manual rollback required." );
            }
            
            if( 0 < rollbackManagers.size(  ) )
               runThreads( rollbackManagers );
         }
         catch( InterruptedException e )
         {
            throw new RemoteSessionException( "Exception occurred while waiting for rollback threads to finish", e );
         }
      }
   }
   
   
   private void runThreads( ArrayList<Thread> threads ) throws InterruptedException
   {
      for( Thread thread : threads )
         thread.start(  );
      
      boolean operationInProgress = true;
      
      while( operationInProgress )
      {
         operationInProgress = false;
         
         for( Thread thread : threads )
            operationInProgress = ( operationInProgress || thread.isAlive(  ) );
         
         synchronized( this )
         {
            wait( 1000 );
         }
      }
   }
   
   
   private class ESPHostInstatiator implements Runnable
   {
      private Log log = SynchronisedLog.getLog(  );
      private Node hostNode;
      private XPathUtil xPathUtil;
      
      public ESPHostInstatiator( Node hostNode, XPathUtil xPathUtil )
      {
         this.hostNode = hostNode;
         this.xPathUtil = xPathUtil;
      }
      
      public synchronized void run(  )
      {
         try
         {
            ESPHost host = new ESPHost( hostNode, xPathUtil );
         
            log.info( "  + [" + host.getHostname(  ) + "] Status: " + host.getStatus(  ).asString(  ) );
            
            hostIdToHostMap.put( host.getHostId(  ), host );
            componentToHostsMap.get( ESPComponent.ALL ).add( host );
         }
         catch( Exception e )
         {
            log.error( "Caught exception in ESPHostInstantiator thread, proceed with care...", e );
         }
      }
   }
   
   
   private class ArtifactUnpacker implements Runnable
   {
      private Log log = SynchronisedLog.getLog(  );
      private ESPHost host;
      private ESPArtifact artifact;
      
      public ArtifactUnpacker( ESPHost host, ESPArtifact artifact ) throws RemoteSessionException
      {
         this.host = host;
         this.artifact = artifact;
      }
      
      public void run(  )
      {
         log.info( "  + [" + host.getHostname(  ) + "] Unpacking: " + artifact.getCapitalisedDescription(  ) + " '" + artifact.getArtifactId(  ) + "'..." );
         
         try
         {
            host.unpackArtifact( artifact );
            log.info( "  + [" + host.getHostname(  ) + "] Unpacking complete." );
         }
         catch( RemoteSessionException e )
         {
            log.error( "Caught exception during unpacking of artifact '" + artifact.getArtifactId(  ) + "' on host " + host.getHostname(  ) + ".", e );
         }
      }
   }


   private class InstallManager implements Runnable
   {
      private Log log = SynchronisedLog.getLog(  );
      private ESPHost host;
      private boolean install;
      
      public InstallManager( ESPHost host ) throws RemoteSessionException
      {
         this( host, true );
      }
      
      public InstallManager( ESPHost host, boolean install ) throws RemoteSessionException
      {
         this.host = host;
         this.install = install;
      }
      
      public void run(  )
      {
         String action = ( install ? "Installation" : "Uninstallation" );
         
         log.info( "  + [" + host.getHostname(  ) + "] " + action + " in progress..." );
         
         try
         {
            if( install )
               host.install(  );
            else
               host.uninstall(  );
            
            log.info( "  + [" + host.getHostname(  ) + "] " + action + " complete." );
         }
         catch( RemoteSessionException e )
         {
            log.error( "Caught exception during " + action.toLowerCase(  ) + " on host " + host.getHostname(  ) + ".", e );
         }
      }
   }


   private class ArtifactApplicator implements Runnable
   {
      private Log log = SynchronisedLog.getLog(  );
      private ESPHost host;
      private ESPArtifact artifact;
      
      public ArtifactApplicator( ESPHost host, ESPArtifact artifact ) throws RemoteSessionException
      {
         this.host = host;
         this.artifact = artifact;
      }
      
      public void run(  )
      {
         log.info( "  + [" + host.getHostname(  ) + "] Applying: " + artifact.getCapitalisedDescription(  ) + " '" + artifact.getArtifactId(  ) + "'..." );
         
         try
         {
            host.applyArtifact( artifact );
            log.info( "  + [" + host.getHostname(  ) + "] " + artifact.getCapitalisedDescription(  ) + " applied." );
         }
         catch( RemoteSessionException e )
         {
            log.error( "Caught exception while applying " + artifact.getDescription(  ) + " '" + artifact.getArtifactId(  ) + "' to host " + host.getHostname(  ) + ".", e );
         }
         catch( MissingBackupException e )
         {
            log.error( e.getMessage(  ), e );
         }
      }
   }
   
   
   private class RollbackManager implements Runnable
   {
      private Log log = SynchronisedLog.getLog(  );
      private ESPHost host;
      private ESPArtifact artifact;
      private boolean toBeReapplied;
      
      public RollbackManager( ESPHost host, ESPArtifact artifact, boolean toBeReapplied ) throws RemoteSessionException
      {
         this.host = host;
         this.artifact = artifact;
         this.toBeReapplied = toBeReapplied;
      }
      
      public void run(  )
      {
         log.info( "  + [" + host.getHostname(  ) + "] Rolling back " + artifact.getDescription(  ) + " '" + artifact.getArtifactId(  ) + "'..." );
         
         try
         {
            host.rollbackArtifact( artifact, toBeReapplied );
            log.info( "  + [" + host.getHostname(  ) + "] Rollback complete." );
         }
         catch( RemoteSessionException e )
         {
            log.error( "[" + host.getHostname(  ) + "] Caught exception while rolling back " + artifact.getDescription(  ) + " '" + artifact.getArtifactId(  ) + "': " + e.getMessage(  ), e );
         }
         catch( MissingBackupException e )
         {
            log.error( e.getMessage(  ), e );
         }
      }
   }


   private class NctrlManager implements Runnable
   {
      private Log log = SynchronisedLog.getLog(  );
      private ESPHost host;
      
      public NctrlManager( ESPHost host ) throws RemoteSessionException
      {
         this.host = host;
      }
      
      public void run(  )
      {
         log.info( "  + [" + host.getHostname(  ) + "] " + host.getNctrlCommand(  ).getStartupMsg(  ) );
         
         try
         {
            host.runNctrlCommand( host.getNctrlCommand(  ) );
            log.info( "  + [" + host.getHostname(  ) + "] " + host.getNctrlCommand(  ).getCompletionMsg(  ) );
         }
         catch( RemoteSessionException e )
         {
            log.error( "Caught exception during execution of '" + host.getNctrlCommand(  ).asString(  ) + "' on host " + host.getHostname(  ), e );
         }
      }
   }
}
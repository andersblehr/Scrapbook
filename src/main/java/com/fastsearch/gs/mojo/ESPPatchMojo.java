package com.fastsearch.gs.mojo;

/*
 * Copyright 2001-2005 The Apache Software Foundation.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.TreeMap;

import org.apache.maven.model.Dependency;
import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;

import com.fastsearch.gs.mojo.artifact.ESPArtifact;
import com.fastsearch.gs.mojo.artifact.ESPPatchArtifact;
import com.fastsearch.gs.mojo.esp.ESPHostSet;
import com.fastsearch.gs.mojo.esp.ESPHost;
import com.fastsearch.gs.mojo.exceptions.ESPMojoException;
import com.fastsearch.gs.mojo.exceptions.MissingInstallationException;
import com.fastsearch.gs.mojo.util.ProjectSettings;
import com.fastsearch.gs.mojo.util.SynchronisedLog;


/**
 * Goal which ...
 *
 * @goal patch
 * @phase process-sources
 * @requiresDependencyResolution compile
 */
public class ESPPatchMojo extends AbstractMojo
{
   /**
    * Customer name.
    * 
    * @parameter
    * @required
    */
   private String customer;
   
   /**
    * Engagement (project) name.
    * 
    * @parameter
    * @required
    */
   private String engagement;
   
   /**
    * Identifier for the project. Should ideally not be longer than 3-4 characters.
    * 
    * @parameter
    * @required
    */
   private String engagementPrefix;
   
   /**
    * Base directory for the project. Defaults to location of pom.xml file.
    * 
    * @parameter default-value="${basedir}"
    * @required
    */
   private String projectDir;
   
   /**
    * Environment to install to. Can be either of dev, test, stage and prod. Default is test.
    *
    * @parameter default-value="test"
    * @required
    */
   private String targetEnvironment;

   /**
    * Specifies whether the session should be interactive or not. If interactive, mvn will ask
    * for confirmation from user before continuing with disruptive actions such as taking down
    * ESP or uploading a new index profile.
    *
    * @parameter expression="${interactive}" default-value="${defaultInteractive}
    * @required
    */
   private boolean interactive;
   
   /**
    * Path to local Maven repository 
    * 
    * @parameter default-value="${settings.localRepository}"
    * @required
    * @readonly
    */
   private String localRepository;

   /**
   * The set of dependencies required by the project
   * 
   * @parameter default-value="${project.dependencies}"
   * @required
   * @readonly
   */
   private ArrayList<Dependency> dependencies;


   public void execute(  ) throws MojoExecutionException
   {
      setLog( SynchronisedLog.createInstance( getLog(  ) ) );

      try
      {
         if( !ProjectSettings.isInstantiated(  ) )
            ProjectSettings.createInstance( customer,
                                            engagement,
                                            engagementPrefix,
                                            projectDir,
                                            targetEnvironment,
                                            interactive,
                                            localRepository,
                                            dependencies );
         
         if( !ESPHostSet.isInstantiated(  ) )
         {
            getLog(  ).info( "----------------------------------------------------------------------------" );
            getLog(  ).info( "FAST ESP Project Lifecycle Manager: 'patch' phase starting up..." );
         }
         
         ESPHostSet hostSet = ESPHostSet.getInstance(  );

         if( !hostSet.isInstalled(  ) )
            throw new MissingInstallationException(  );
            
         TreeMap<String, ESPArtifact> configuredPatches = ProjectSettings.getPatchArtifacts(  );
         TreeMap<String, ESPArtifact> redundantPatches = new TreeMap<String, ESPArtifact>(  );
         ArrayList<ESPArtifact> appliedPatches = new ArrayList<ESPArtifact>(  );
         
         getLog(  ).info( "Hotfixes specified in configuration (pom.xml):" );
         
         if( 0 < configuredPatches.size(  ) )
            for( ESPArtifact patch : configuredPatches.values(  ) )
               getLog(  ).info( "  + " + patch.getArtifactId(  ) );
         else
            getLog(  ).info( "  + (none)" );
         
         getLog(  ).info( "Hotfix status per host:" );
         
         TreeMap<String, ESPArtifact> installedOrConfiguredPatches = new TreeMap<String, ESPArtifact>( ProjectSettings.getPatchArtifacts(  ) );

         boolean patchingRequired = false;
         
         for( ESPHost host : hostSet.getHosts(  ) )
         {
            List<String> installedPatches = Arrays.asList( host.getInstalledPatches(  ) );
            
            for( String patchId : installedPatches )
            {
               if( !installedOrConfiguredPatches.containsKey( patchId ) )
               {
                  ESPArtifact installedPatch = ESPPatchArtifact.resolvePatch( patchId, host );
                  
                  if( ( null != installedPatch) && !installedOrConfiguredPatches.containsKey( patchId ) )
                     installedOrConfiguredPatches.put( patchId, installedPatch );
               }
            }
            
            getLog(  ).info( "  + [" + host.getHostname(  ) + "]" );

            for( ESPArtifact patch : installedOrConfiguredPatches.values(  ) )
            {
               if( installedPatches.contains( patch.getArtifactId(  ) ) && configuredPatches.containsKey( patch.getArtifactId(  ) ) )
                  getLog(  ).info( "    + " + patch.getArtifactId(  ) + ": Applied." );
               else if( configuredPatches.containsKey( patch.getArtifactId(  ) ) )
               {
                  getLog(  ).info( "    + " + patch.getArtifactId(  ) + ": (missing)" );
                  
                  if( !appliedPatches.contains( patch ) )
                     appliedPatches.add( patch );
                  
                  patchingRequired = true;
               }
               else
               {
                  getLog(  ).info( "    + " + patch.getArtifactId(  ) + ": Applied, but not configured; rollback will be attempted." );
                  
                  if( !redundantPatches.containsKey( patch.getArtifactId(  ) ) )
                     redundantPatches.put( patch.getArtifactId(  ), patch );
               }
            }
         }
         
         boolean rollbackRequired = ( 0 < redundantPatches.size(  ) );
         boolean hostSetWasRunning = false;
         
         if( patchingRequired || rollbackRequired )
         {
            if( hostSet.isRunning(  ) )
            {
               String action;
               
               if( patchingRequired && rollbackRequired )
                  action = "rolling back & applying";
               else if( patchingRequired )
                  action = "applying";
               else
                  action = "rolling back";
               
               hostSet.confirmAction( "ESP must be stopped on all hosts prior to " + action + " hotfix(es). Continue?" );

               getLog(  ).info( "Stopping ESP prior to " + action + " hotfix(es):" );
               hostSet.stop(  );
               
               hostSetWasRunning = true;
            }
         }

         if( rollbackRequired )
            hostSet.rollback( redundantPatches, false );
         if( patchingRequired || rollbackRequired )
            hostSet.patch( ProjectSettings.getPatchArtifacts(  ) );

         if( hostSetWasRunning )
         {
            getLog(  ).info( "Restarting ESP:" );
            hostSet.start( false );
         }
         
         getLog(  ).info( "----------------------------------------------------------------------------" );
         
         boolean pastRollbackPoint = false;
         
         if( 0 < installedOrConfiguredPatches.size(  ) )
         {
            for( ESPArtifact patch : installedOrConfiguredPatches.values(  ) )
            {
               if( appliedPatches.contains( patch ) )
               {
                  getLog(  ).info( ">> Hotfix " + patch.getArtifactId(  ) + " has been successfully applied." );
                  pastRollbackPoint = true;
               }
               else if( configuredPatches.containsKey( patch.getArtifactId(  ) ) )
               {
                  if( pastRollbackPoint )
                     getLog(  ).info( ">> Hotfix " + patch.getArtifactId(  ) + " has been successfully reapplied." );
                  else
                     getLog(  ).info( ">> Hotfix " + patch.getArtifactId(  ) + " was already applied, did nothing." );
               }
               else if( redundantPatches.containsKey( patch.getArtifactId(  ) ) )
               {
                  getLog(  ).info( ">> Hotfix " + patch.getArtifactId(  ) + " has been successfully rolled back." );
                  pastRollbackPoint = true;
               }
            }
         } else
            getLog(  ).info( ">> No hotfixes configured and no rollbacks required, nothing to do." );

         getLog(  ).info( "----------------------------------------------------------------------------" );
      }
      catch( ESPMojoException e )
      {
         throw new MojoExecutionException( e.getMessage(  ), e );
      }
   }
}

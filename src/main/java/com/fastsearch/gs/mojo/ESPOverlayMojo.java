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

import org.apache.maven.model.Dependency;
import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;

import com.fastsearch.gs.mojo.esp.ESPHostSet;
import com.fastsearch.gs.mojo.exceptions.ESPMojoException;
import com.fastsearch.gs.mojo.exceptions.MissingInstallationException;
import com.fastsearch.gs.mojo.util.ProjectSettings;
import com.fastsearch.gs.mojo.util.SynchronisedLog;


/**
 * Goal which ...
 *
 * @goal overlay
 * @phase generate-resources
 */
public class ESPOverlayMojo extends AbstractMojo
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
    * Environment to install to. Can be either of dev, test, staging and prod. Default is test.
    *
    * @parameter default-value="test"
    * @required
    */
   private String targetEnvironment;

   /**
    * Environment to install to. Can be either of dev, test, stage and prod. Default is test.
    *
    * @parameter default-value="true"
    * @required
    */
   private boolean interactive;
   
   /**
    * Whether to roll back..
    *
    * @parameter expression="${rollback}" default-value="false"
    * @required
    */
   private boolean rollback;
   
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
            getLog(  ).info( "FAST ESP Project Lifecycle Manager: 'overlay' phase starting up..." );
         }
         
         ESPHostSet hostSet = ESPHostSet.getInstance(  );
         
         if( !hostSet.isInstalled(  ) )
            throw new MissingInstallationException(  );
         
         boolean hostSetWasRunning = false;
         boolean overlayIsCurrent = false;
         boolean hasOverlay = hostSet.hasAppliedArtifact( ProjectSettings.getOverlayArtifact(  ) );

         if( !rollback && hasOverlay )
            overlayIsCurrent = hostSet.overlayIsCurrent(  );
         
         if( ( rollback && hasOverlay ) || !overlayIsCurrent )
         {
            if( hostSet.isRunning(  ) )
            {
               String action;
               
               if( rollback )
                  action = "rolling back";
               else
                  action = "applying";
               
               hostSet.confirmAction( "ESP must be stopped prior to " + action + " overlay. Continue?" );
               
               getLog(  ).info( "Stopping ESP prior to " + action + " overlay:" );
               hostSet.stop(  );
               hostSetWasRunning = true;
            }
               
            if( rollback && hasOverlay )
               hostSet.rollback( ProjectSettings.getOverlayArtifact(  ) );
            else
               hostSet.deployOverlay(  );
         
            if( hostSetWasRunning )
            {
               getLog(  ).info( "Restarting ESP:" );
               hostSet.start( false );
            }
         }
         
         getLog(  ).info( "----------------------------------------------------------------------------" );
         
         if( rollback && !hasOverlay )
            getLog(  ).info( ">> Overlay '" + ProjectSettings.getOverlayArtifact(  ).getArtifactId(  ) + "' has not been applied, could not roll back." );
         else if( rollback )
            getLog(  ).info( ">> Overlay '" + ProjectSettings.getOverlayArtifact(  ).getArtifactId(  ) + "' has been successfully rolled back on all hosts." );
         else if( hasOverlay && overlayIsCurrent )
            getLog(  ).info( ">> Overlay '" + ProjectSettings.getOverlayArtifact(  ).getArtifactId(  ) + "' is current on all hosts, nothing to do." );
         else
            getLog(  ).info( ">> Overlay '" + ProjectSettings.getOverlayArtifact(  ).getArtifactId(  ) + "' has been successfully applied." );
         
         getLog(  ).info( "----------------------------------------------------------------------------" );
      }
      catch( ESPMojoException e )
      {
         throw new MojoExecutionException( e.getMessage(  ), e );
      }
   }
}
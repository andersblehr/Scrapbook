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
import com.fastsearch.gs.mojo.util.ProjectSettings;
import com.fastsearch.gs.mojo.util.SynchronisedLog;


/**
 * Goal which installs ESP to specified environment.
 *
 * @goal validate
 * @phase validate
 * @requiresDependencyResolution compile
 */
public class ESPValidatelMojo extends AbstractMojo
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
    * Environment to install to. Can be either of dev, test, staging and prod. Default is test.
    *
    * @parameter expression="false"
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
         ProjectSettings.createInstance( customer,
                                         engagement,
                                         engagementPrefix,
                                         projectDir,
                                         targetEnvironment,
                                         interactive,
                                         localRepository,
                                         dependencies );
         
         getLog(  ).info( "----------------------------------------------------------------------------" );
         getLog(  ).info( "FAST ESP Project Lifecycle Manager starting up..." );
         
         ESPHostSet hostSet = ESPHostSet.getInstance(  );
         
         boolean isInstalled = hostSet.isInstalled(  );
         boolean isRunning = hostSet.isRunning(  );
         
         if( isRunning )
         {
            getLog(  ).info( "Investigating system logs" );
            
            if( hostSet.hasErrors(  ) )
               hostSet.inspect( true );
         }
         
         getLog(  ).info( "----------------------------------------------------------------------------" );
         getLog(  ).info( ">> Project '" + engagement + "' is valid." );
         
         if( isRunning && hostSet.hasErrors(  ) )
            getLog(  ).info( ">> ESP is running, but system log has errors." );
         else if( isRunning && hostSet.hasWarnings(  ) )
            getLog(  ).info( ">> ESP is running, but system log has warnings." );
         else if( isRunning )
            getLog(  ).info( ">> ESP is running with no errors and no warnings." );
         else if( isInstalled )
            getLog(  ).info( ">> ESP is installed, but not running." );
         else
            getLog(  ).info( ">> ESP is not installed." );
         
         getLog(  ).info( "----------------------------------------------------------------------------" );
      }
      catch( ESPMojoException e )
      {
         throw new MojoExecutionException( e.getMessage(  ), e );
      }
   }
}

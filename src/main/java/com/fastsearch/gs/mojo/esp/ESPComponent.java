package com.fastsearch.gs.mojo.esp;

import com.fastsearch.gs.mojo.util.ProjectSettings;



public enum ESPComponent
{
   ALL                ( "espmeta",              false ), // Meta-item..
   
   ADMINGUI           ( "httpd",                true  ),
   ADMINSERVER        ( "adminserver",          true  ),
   ANCHORSERVER       ( "anchorserver-storage", true  ),
   CLARITY            ( "clarity_webcluster",   true  ),
   CONFIGSERVER       ( "configserver",         true  ),
   CONTENTDISTRIBUTOR ( "contentdistributor",   true  ),
   CRAWLER            ( "crawler",              true  ),
   DUPSERVER          ( "dupserver",            false ), // Cannot be configured by installer
   INDEXER            ( "indexer",              true ),
   INDEXINGDISPATCHER ( "indexingdispatcher",   true  ),
   LICENSEMANAGER     ( "lmgrd",                true  ),
   NAMESERVICE        ( "nameservice",          true  ),
   PROCSERVER         ( "procserver",           false ), // Need to parse NodeState.xml to obtain procservers
   QRSERVER           ( "qrserver",             true  ),
   RELBENCH           ( "relbench",             true  ),
   RESOURCESERVICE    ( "resourceservice",      true  ),
   SEARCH             ( "search-1",             true  ),
   STORAGESERVICE     ( "storageservice",       true  ),
   UBERMASTER         ( "ubermaster",           false ); // Cannot be configured by installer
   
   
   private final String  processName;
   private final boolean inInstallProfile;
   

   private ESPComponent( String processName, boolean inInstallProfile )
   {
      this.processName      = processName;
      this.inInstallProfile = inInstallProfile;
   }
   
   
   public String getProcessName(  )
   {
      return processName;
   }
   
   
   public boolean inInstallProfile(  )
   {
      return inInstallProfile;
   }
   
   
   public boolean inVersion(  )
   {
      if( this.equals( RELBENCH ) )
         return ( "5.0".equals( ProjectSettings.getMinorRelease(  ) ) ) ? true : false;
      else if( "5".equals( ProjectSettings.getMajorRelease(  ) ) )
         return true;
      else
         return false;
   }
}

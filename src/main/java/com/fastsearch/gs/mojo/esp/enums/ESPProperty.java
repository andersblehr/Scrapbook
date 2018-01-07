package com.fastsearch.gs.mojo.esp.enums;


public enum ESPProperty
{
   INTERACTIVE ( "interactive" ),
   REINSTALL   ( "reinstall"   ),
   ROLLBACK    ( "rollback"    );
   
   private String property;
   
   
   private ESPProperty( String property )
   {
      this.property = property;
   }
   
   
   public String getProperty(  )
   {
      return property;
   }
}

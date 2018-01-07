package com.fastsearch.gs.mojo.util;


public enum Platform
{
   LINUX   ( "Linux" ),
   WINDOWS ( "Windows" ),
   UNIX    ( "UNIX" );
   
   
   private String platform;
   
   
   private Platform( String platform )
   {
      this.platform = platform;
   }
   
   
   public static Platform getPlatform( String platform )
   {
      if( "Linux".equals( platform ) )
         return LINUX;
      else if( "Windows".equals( platform ) )
         return WINDOWS;
      else
         return UNIX;
   }
   
   
   public String asString(  )
   {
      return platform;
   }
}

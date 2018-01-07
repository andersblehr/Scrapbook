package com.fastsearch.gs.mojo.exceptions;


public class UnsupportedESPVersionException extends ESPMojoException
{
   private static final long serialVersionUID = 8846680555912887544L;

   
   public UnsupportedESPVersionException( String version )
   {
      super( "FDS version " + version + " is not supported by FAST's Delivery Framework. Only ESP 5 and higher are supported." );
   }
}

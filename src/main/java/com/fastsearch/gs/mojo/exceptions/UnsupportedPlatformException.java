package com.fastsearch.gs.mojo.exceptions;

import com.fastsearch.gs.mojo.util.Platform;


public class UnsupportedPlatformException extends ESPMojoException
{
   private static final long serialVersionUID = -7785658166534954085L;

   
   public UnsupportedPlatformException( Platform platform )
   {
      super( "The target platform '" + platform.asString(  ) + "' is not supported by FAST's Delivery Framework." );
   }
}

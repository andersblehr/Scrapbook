package com.fastsearch.gs.mojo.exceptions;

public class MissingInstallationException extends ESPMojoException
{
   private static final long serialVersionUID = 5657502297666799770L;

   
   public MissingInstallationException(  )
   {
      super( "ESP has not been installed, cannot continue." );
   }
}

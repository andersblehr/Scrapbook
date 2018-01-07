package com.fastsearch.gs.mojo.exceptions;

public class BlissException extends ESPMojoException
{
   private static final long serialVersionUID = 4874012166164944670L;

   
   public BlissException( String errorString )
   {
      super( "Errors during upload of index profile: " + errorString );
   }
}

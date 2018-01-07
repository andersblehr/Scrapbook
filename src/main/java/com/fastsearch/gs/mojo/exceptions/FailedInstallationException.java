package com.fastsearch.gs.mojo.exceptions;


public class FailedInstallationException extends ESPMojoException {

   private static final long serialVersionUID = -2496574012912732061L;

   
   public FailedInstallationException( String status )
   {
      super( "The state of this ESP installation is reported as '" + status + "', manual inspection required." );
   }
}

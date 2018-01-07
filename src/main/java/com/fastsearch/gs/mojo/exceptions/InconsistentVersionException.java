package com.fastsearch.gs.mojo.exceptions;


public class InconsistentVersionsException extends ESPMojoException
{
   private static final long serialVersionUID = -1003866904720843883L;

   
   public InconsistentVersionsException( String hostname, String expectedVersion, String installedVersion )
   {
      super( "The ESP version currently installed on " + hostname + " (" + installedVersion +
             ") is not consistent with the version specified in the install profile (" + expectedVersion +
             "). Manual cleanup required. Aborting." );
   }
}

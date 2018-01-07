package com.fastsearch.gs.mojo.exceptions;


public class UserTerminationException extends ESPMojoException
{
   private static final long serialVersionUID = 8966311923742506036L;


   public UserTerminationException(  )
   {
      super( "Caught user interrupt, aborting." );
   }

   
   public UserTerminationException( String message, Throwable e )
   {
      super( message, e );
   }
}

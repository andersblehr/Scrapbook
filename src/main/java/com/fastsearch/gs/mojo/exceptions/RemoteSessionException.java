package com.fastsearch.gs.mojo.exceptions;


public class RemoteSessionException extends ESPMojoException
{
   private static final long serialVersionUID = 5719669943496564945L;

   
   public RemoteSessionException( String message )
   {
      super( message );
   }

   
   public RemoteSessionException( String message, Exception e )
   {
      super( message, e );
   }
}

package com.fastsearch.gs.mojo.exceptions;

public class ESPMojoException extends Exception
{
   private static final long serialVersionUID = 6811485871482556756L;


   public ESPMojoException( String message )
   {
      super( message );
   }


   public ESPMojoException( String message, Throwable e )
   {
      super( message, e );
   }


   public ESPMojoException( Exception e )
   {
      super( e );
   }
}

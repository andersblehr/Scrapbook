package com.fastsearch.gs.mojo.exceptions;


public class InconsistentStateException extends ESPMojoException
{
   private static final long serialVersionUID = -708068894792355263L;


   public InconsistentStateException(  )
   {
      super( "The hosts in the configuration are in an inconsistent state, manual inspection required, aborting." );
   }
}

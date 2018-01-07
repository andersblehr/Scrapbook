package com.fastsearch.gs.mojo.exceptions;

import com.fastsearch.gs.mojo.artifact.ESPArtifact;


public class MissingBackupException extends ESPMojoException
{
   private static final long serialVersionUID = -8230513806938412655L;

   
   public MissingBackupException( ESPArtifact artifact )
   {
      super( "No backup available for " + artifact.getDescription() + "'" + artifact.getArtifactId(  ) + ", rollback not possible." );
   }
}

package com.fastsearch.gs.mojo.exceptions;

import com.fastsearch.gs.mojo.esp.enums.ESPFile;


public class InvalidInstallProfileException extends ESPMojoException
{
   private static final long serialVersionUID = -470120024082311520L;

   
   public InvalidInstallProfileException( Exception e )
   {
      super( "An error occured during reading or parsing of install profile '" + ESPFile.InstallProfile_xml.getLocalPath(  ) + "'.", e );
   }
}

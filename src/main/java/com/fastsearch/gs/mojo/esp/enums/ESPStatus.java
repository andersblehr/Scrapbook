package com.fastsearch.gs.mojo.esp.enums;


public enum ESPStatus
{
   RUNNING      ( "ESP is running."                                                                  ),
   STRUGGLING   ( "ESP is running, but some components are down."                                    ),
   HANGING      ( "ESP is stopped, but hanging processes exist."                                     ),
   DOWN         ( "ESP is installed but not running."                                                ),
   MISSING      ( "ESP is not installed."                                                            ),
   VERSION      ( "ESP is installed, but the installed version differs from the configured version." ),
   INCONSISTENT ( "The ESP state is not consistent across hosts."                                    ),
   UNKNOWN      ( "Unknown status."                                                                  );
   
   
   private String status;
   
   
   private ESPStatus( String status )
   {
      this.status = status;
   }
   
   
   public String asString(  )
   {
      return status;
   }
}

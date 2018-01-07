package com.fastsearch.gs.mojo.esp.enums;

public enum NctrlCommand
{
   START     ( "nctrl start", "Startup in progress...",  "Startup complete." ),
   STOP      ( "nctrl stop",  "Shutdown in progress...", "Shutdown complete." ),
   SYSSTATUS ( "nctrl sysstatus" );
   
   private String command;
   private String startupMsg;
   private String completionMsg;
   
   
   private NctrlCommand( String command, String startupMsg, String completionMsg )
   {
      this.command = command;
      this.startupMsg = startupMsg;
      this.completionMsg = completionMsg;
   }
   
   
   private NctrlCommand( String command )
   {
      this( command, null, null );
   }
   
   
   public String asString(  )
   {
      return command;
   }
   
   
   public String getStartupMsg(  )
   {
      return startupMsg;
   }


   public String getCompletionMsg(  )
   {
      return completionMsg;
   }
}

package com.fastsearch.gs.mojo.remote;

import com.fastsearch.gs.mojo.esp.ESPHost;
import com.fastsearch.gs.mojo.exceptions.RemoteSessionException;
import com.fastsearch.gs.mojo.util.Platform;


public class RemoteSessionFactory
{
   public static synchronized RemoteSession createRemoteSession( ESPHost host ) throws RemoteSessionException
   {
      if( Platform.WINDOWS == host.getPlatform(  ) )
         return new RemoteWindowsSession( host );
      else
         return new RemoteUnixSession( host );
   }
}

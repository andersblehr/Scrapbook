package com.fastsearch.gs.mojo.util;

import org.apache.maven.plugin.logging.Log;


public class SynchronisedLog implements Log
{
   private static Log instance = null;
   private static Log log = null;


   private SynchronisedLog( Log mojoLog )
   {
      instance = this;
      log = mojoLog;
   }
   
   
   public static Log createInstance( Log mojoLog )
   {
      if( null == instance )
         instance = new SynchronisedLog( mojoLog );
      
      return instance;
   }
   
   
   public static Log getLog(  )
   {
      return instance;
   }
   
   
   public synchronized void debug( CharSequence message )
   {
      log.debug( message );
   }
   
   
   public synchronized void debug( Throwable t )
   {
      log.debug( t );
   }
   
   
   public synchronized void debug( CharSequence message, Throwable t )
   {
      log.debug( message, t );
   }
   
   
   public synchronized void info( CharSequence message )
   {
      log.info( message );
   }
   
   
   public synchronized void info( Throwable t )
   {
      log.info( t );
   }
   
   
   public synchronized void info( CharSequence message, Throwable t )
   {
      log.info( message, t );
   }
   
   
   public synchronized void warn( CharSequence message )
   {
      log.warn( message );
   }
   
   
   public synchronized void warn( Throwable t )
   {
      log.warn( t );
   }
   
   
   public synchronized void warn( CharSequence message, Throwable t )
   {
      log.warn( message, t );
   }
   
   
   public synchronized void error( CharSequence message )
   {
      log.error( message );
   }
   
   
   public synchronized void error( Throwable t )
   {
      log.error( t );
   }
   
   
   public synchronized void error( CharSequence message, Throwable t )
   {
      log.error( message, t );
   }

   
   public boolean isDebugEnabled(  )
   {
      return true;
   }

   
   public boolean isErrorEnabled(  )
   {
      return true;
   }

   
   public boolean isInfoEnabled(  )
   {
      return true;
   }


   public boolean isWarnEnabled(  )
   {
      return true;
   }
}

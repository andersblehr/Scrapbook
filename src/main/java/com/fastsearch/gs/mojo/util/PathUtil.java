package com.fastsearch.gs.mojo.util;


public class PathUtil
{
   public static String joinPaths( String ... paths )
   {
      return joinPaths( ProjectSettings.getTargetPlatform(  ), paths );
   }

   
   public static String joinPaths( Platform platform, String ... paths )
   {
      int startIndex = ( "".equals( paths[ 0 ] ) ? 1 : 0 );
      
      StringBuffer path = new StringBuffer( removeTrailingPathSeparators( platform, paths[ startIndex ] ) );
      
      for( int i = startIndex + 1; i < paths.length; i++ )
         if( !( "".equals( paths[ i ] ) ) )
            path.append( getPathSeparator( platform ) + removeLeadingAndTrailingPathSeparators( platform, paths[ i ] ) );
      
      return path.toString(  );
   }
   
   
   public static String dirName( String path )
   {
      String pathSeparator = getPathSeparator( ProjectSettings.getTargetPlatform(  ) );
      String escapedPathSeparator = ( ( Platform.WINDOWS == ProjectSettings.getTargetPlatform(  ) ) ? "\\\\" : pathSeparator );
      
      StringBuffer dirName = new StringBuffer(  );
      String[] pathElements = path.split( escapedPathSeparator );

      for( int i = 0; i < pathElements.length - 1; i++ )
      {
         dirName.append( pathElements[ i ] );
         dirName.append( pathSeparator );
      }
      
      return dirName.toString(  );
   }
   
   
   public static String baseName( String path )
   {
      return baseName( ProjectSettings.getTargetPlatform(  ), path );
   }

   
   public static String baseName( Platform platform, String path )
   {
      String pathSeparator = ( ( Platform.WINDOWS == platform ) ? "\\\\" : getPathSeparator( platform ) );
      String[] pathElements = path.split( pathSeparator );

      return pathElements[ pathElements.length - 1 ];
   }
   
   
   public static String convertPath( String path )
   {
      return convertPath( ProjectSettings.getTargetPlatform(  ), path );
   }
   
   
   public static String convertPath( Platform platform, String path )
   {
      if( path.contains( "/" ) )
      {
         return path.replace( "/", getPathSeparator( platform ) );
      }
      else if( path.contains( "\\" ) )
      {
         return path.replace( "\\", getPathSeparator( platform ) );
      }
      else
         return path;
   }

   
   private static String removeLeadingAndTrailingPathSeparators( Platform platform, String pathElement )
   {
      if( pathElement.startsWith( getPathSeparator( platform ) ) )
         pathElement = pathElement.substring( 1 );
      
      return removeTrailingPathSeparators( platform, pathElement );
   }
   
   
   private static String removeTrailingPathSeparators( Platform platform, String pathElement )
   {
      if( pathElement.endsWith( getPathSeparator( platform ) ) )
         pathElement = pathElement.substring( 0, pathElement.length(  ) - 1 );
      
      return pathElement;
   }
   
   
   private static String getPathSeparator( Platform platform )
   {
      if( ( Platform.LINUX == platform ) || ( Platform.UNIX == platform ) )
         return "/";
      else
         return "\\";
   }
}
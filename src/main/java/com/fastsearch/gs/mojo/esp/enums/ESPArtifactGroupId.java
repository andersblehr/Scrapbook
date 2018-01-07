package com.fastsearch.gs.mojo.esp.enums;

public enum ESPArtifactGroupId
{
   RELEASE ( "com.fastsearch.esp.release" ),
   HOTFIX  ( "com.fastsearch.esp.hotfix"  ),
   OVERLAY ( "com.fastsearch.gs.overlay"  );
   
   private String groupId;
   
   
   private ESPArtifactGroupId( String groupId )
   {
      this.groupId = groupId;
   }
   
   
   public static ESPArtifactGroupId getGroupId( String groupIdAsString )
   {
      if( RELEASE.asString(  ).equals( groupIdAsString ) )
         return RELEASE;
      else if( HOTFIX.asString(  ).equals( groupIdAsString ) )
         return HOTFIX;
      else if( OVERLAY.asString(  ).equals( groupIdAsString ) )
         return HOTFIX;
      else
         return null;
   }
   
   
   public String asString(  )
   {
      return groupId;
   }
}

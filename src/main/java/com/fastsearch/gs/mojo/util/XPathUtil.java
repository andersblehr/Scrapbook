package com.fastsearch.gs.mojo.util;

import java.util.HashMap;

import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

import com.fastsearch.gs.mojo.esp.ESPComponent;


public class XPathUtil
{
   public final static String ROOT       = "/system-configuration";
   public final static String VERSION    = "@version";

   public final static String HOSTSET    = "00";
   public final static String HOSTID     = "01";
   public final static String HOSTREF    = "02";
   
   public final static String BASEPORT   = "10";
   public final static String FIXMLDIR   = "11";
   public final static String HOSTNAME   = "12";
   public final static String INDEXDIR   = "13";
   public final static String INSTALLDIR = "14";
   public final static String PLATFORM   = "15";
   public final static String REMOTECMD  = "16";
   public final static String TEMPDIR    = "17";
   public final static String USERNAME   = "18";
   
   public final static String IS_INDEXER = "20";
   public final static String IS_SEARCH  = "21";

   private HashMap<String, HashMap<ESPComponent, String>> metaComponentVault   = new HashMap<String, HashMap<ESPComponent, String>>(  );
   private HashMap<String, HashMap<String, String>>       metaEnvironmentVault = new HashMap<String, HashMap<String,       String>>(  );
   private XPath                                          xPath                = XPathFactory.newInstance(  ).newXPath(  );
   private Node                                           root;

   
   public XPathUtil( String installProfileFileName ) throws XPathExpressionException
   {
      root = ( Node )xPath.evaluate( ROOT, new InputSource( installProfileFileName ), XPathConstants.NODE );
      
      HashMap<ESPComponent, String> componentVaultESP5  = new HashMap<ESPComponent, String>(  );
      HashMap<ESPComponent, String> componentVaultESP50 = new HashMap<ESPComponent, String>(  );
      HashMap<ESPComponent, String> componentVaultESP51 = new HashMap<ESPComponent, String>(  );
      
      componentVaultESP5.put( ESPComponent.ADMINGUI,           "administration-set/administration-gui" );
      componentVaultESP5.put( ESPComponent.ADMINSERVER,        "administration-set/admin-service" );
      componentVaultESP5.put( ESPComponent.ANCHORSERVER,       "anchor-service/anchor-server" );
      componentVaultESP5.put( ESPComponent.CLARITY,            "administration-set/clarity" );
      componentVaultESP5.put( ESPComponent.CONFIGSERVER,       "administration-set/configuration-service" );
      componentVaultESP5.put( ESPComponent.CONTENTDISTRIBUTOR, "content-distributor-set/content-distributor" );
      componentVaultESP5.put( ESPComponent.CRAWLER,            "data-source-set/crawler" );
      componentVaultESP5.put( ESPComponent.INDEXER,            "search-engine-set/search-engine" );
      componentVaultESP5.put( ESPComponent.INDEXINGDISPATCHER, "indexing-dispatchers/indexing-dispatcher" );
      componentVaultESP5.put( ESPComponent.LICENSEMANAGER,     "license-service/license-server" );
      componentVaultESP5.put( ESPComponent.NAMESERVICE,        "name-service/name-server" );
      componentVaultESP5.put( ESPComponent.PROCSERVER,         "document-processor-set/document-processor" );
      componentVaultESP5.put( ESPComponent.QRSERVER,           "query-result-processor-set/query-result-processor" );
      componentVaultESP5.put( ESPComponent.RESOURCESERVICE,    "administration-set/resource-service" );
      componentVaultESP5.put( ESPComponent.SEARCH,             "search-engine-set/search-engine" );
      componentVaultESP5.put( ESPComponent.STORAGESERVICE,     "administration-set/storage-service" );

      componentVaultESP50.put( ESPComponent.RELBENCH,          "administration-set/relbench" );
      
      metaComponentVault.put( "5",   componentVaultESP5  );
      metaComponentVault.put( "5.0", componentVaultESP50 );
      metaComponentVault.put( "5.1", componentVaultESP51 );
      
      HashMap<String, String> environmentVaultESP5  = new HashMap<String, String>(  );
      HashMap<String, String> environmentVaultESP50 = new HashMap<String, String>(  );
      HashMap<String, String> environmentVaultESP51 = new HashMap<String, String>(  );
      
      environmentVaultESP5.put( HOSTSET,    "host-set/host" );
      environmentVaultESP5.put( HOSTID,     "@id" );
      environmentVaultESP5.put( HOSTREF,    "@host-ref" );

      environmentVaultESP5.put( BASEPORT,   "property[@name='baseport']/@value" );
      environmentVaultESP5.put( FIXMLDIR,   "property[@name='fixml-dir']/@value" );
      environmentVaultESP5.put( HOSTNAME,   "property[@name='hostname']/@value" );
      environmentVaultESP5.put( INDEXDIR,   "property[@name='index-dir']/@value" );
      environmentVaultESP5.put( INSTALLDIR, "property[@name='install-dir']/@value" );
      environmentVaultESP5.put( PLATFORM,   "property[@name='platform']/@value" );
      environmentVaultESP5.put( REMOTECMD,  "property[@name='remote-cmd']/@value" );
      environmentVaultESP5.put( TEMPDIR,    "property[@name='temp-dir']/@value" );
      environmentVaultESP5.put( USERNAME,   "property[@name='username']/@value" );

      environmentVaultESP5.put( IS_INDEXER, "property[@name='index']/@value" );
      environmentVaultESP5.put( IS_SEARCH,  "property[@name='search']/@value" );
      
      metaEnvironmentVault.put( "5",   environmentVaultESP5  );
      metaEnvironmentVault.put( "5.0", environmentVaultESP50 );
      metaEnvironmentVault.put( "5.1", environmentVaultESP51 );
   }
   
   
   public Node getRootNode(  ) throws XPathExpressionException
   {
      return root;
   }
   
   
   public NodeList getNodeList( ESPComponent component ) throws XPathExpressionException
   {
      return ( NodeList )xPath.evaluate( getXPath( component ), root, XPathConstants.NODESET );
   }
   
   
   public NodeList getNodeList( String key ) throws XPathExpressionException
   {
      return ( NodeList )xPath.evaluate( getXPath( key ), root, XPathConstants.NODESET );
   }
   
   
   public Node getNode( String key, Node node ) throws XPathExpressionException
   {
      return ( Node )xPath.evaluate( getXPath( key ), node, XPathConstants.NODE );
   }
   
   
   private String getXPath( ESPComponent component )
   {
      if( metaComponentVault.get( ProjectSettings.getMajorRelease(  ) ).containsKey( component ) )
      {
         return metaComponentVault.get( ProjectSettings.getMajorRelease(  ) ).get( component );
      }
      else if( metaComponentVault.get( ProjectSettings.getMinorRelease(  ) ).containsKey( component ) )
      {
         return metaComponentVault.get( ProjectSettings.getMinorRelease(  ) ).get( component );
      }
      else
      {
         return null;
      }
   }

   
   private String getXPath( String key )
   {
      if( metaEnvironmentVault.get( ProjectSettings.getMajorRelease(  ) ).containsKey( key ) )
      {
         return metaEnvironmentVault.get( ProjectSettings.getMajorRelease(  ) ).get( key );
      }
      else if ( metaEnvironmentVault.get( ProjectSettings.getMinorRelease(  ) ).containsKey( key ) )
      {
         return metaEnvironmentVault.get( ProjectSettings.getMinorRelease(  ) ).get( key );
      }
      else
      {
         return null;
      }
   }
}

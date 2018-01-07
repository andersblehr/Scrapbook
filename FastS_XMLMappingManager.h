#ifndef _FASTS_XMLMAPPINGMANAGER_H
#define _FASTS_XMLMAPPINGMANAGER_H
/*****************************************************************************
 * FastS_XMLMappingManager.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastS_XMLMappingManager.h,v 1.2 2001/02/15 14:10:54 ablehr Exp $
 * $Log: FastS_XMLMappingManager.h,v $
 * Revision 1.2  2001/02/15 14:10:54  ablehr
 * - Bugfix
 *
 *****************************************************************************/

#include <fastlib/util/hashtable.h>
#include <fastlib/util/string.h>
#include <fast/fixapi/fixapiconfiguration.h>
#include <ftutil/Fast_LogHandler.h>
#include <fastsax/FastSAX.h>

#include "FastS_XMLMappingList.h"


#define _C_MAX_MAPPINGS      512

#define _C_XMLMAP_ROOT       "xmlMapping"
#define _C_XMLMAP_LIST       "mappingList"
#define _C_XMLMAP_DOCDELIM   "documentDelimiter"
#define _C_XMLMAP_MAPPING    "mapping"
#define _C_XMLMAP_FROM       "fromElement"
#define _C_XMLMAP_ATTR       "attribute"
#define _C_XMLMAP_IFVALUE    "ifValue"
#define _C_XMLMAP_TO_CONTEXT "toContext"
#define _C_XMLMAP_TO_SFIELD  "toSummaryField"
#define _C_XMLMAP_TO_RFIELD  "toRankField"
#define _C_XMLMAP_CATALOG    "catalog"
#define _C_XMLMAP_CNAME      "name"
#define _C_XMLMAP_SCLASS     "summaryClass"
#define _C_XMLMAP_SNAME      "name"
#define _C_XMLMAP_RCLASS     "rankClass"
#define _C_XMLMAP_RNAME      "name"


/**//*************************************************************************
 * Maintain lists of mappings for XML elements.
 *
 * A mapping maps data associated with an XML element in a data file to one or
 * more contexts, summary fields, and/or rank fields.
 *
 * The mappings are defined in a mapping file which is loaded by during
 * construction.  Cf. xmlmap.dtd for the layout of mapping files.
 *
 * The loading of mapping files, which are XML, is facilitated by having the
 * class implement the FastSAX_IDocumentHandler interface.  Specifically, the
 * class ovverrides the default implementation in the FastSAX_HandlerBase class
 * of the FastSAX_IDocumentHandler interface, as well as the
 * FastSAX_IErrorHandler interface.
 *
 * For each element that is defined in the mapping file as having one or more
 * mappings, an mapping list is created and inserted into a hash table (@ref
 * _mappingHash), using the element name as key.  Whenever new mappings for
 * a given element is encountered in the mapping file, the mapping list for
 * that element is retrieved from the hash table and the new mapping is
 * appended to the end of the list.
 *
 * This class is instantiated once by @ref FastS_XMLIndexer.
 *
 * @see FastS_XMLMapping
 * @see FastS_XMLMappingList
 * @see FastS_FIXAPI_Configuration
 * @see FastSAX_IParser
 * @see FastSAX_HandlerBase
 *
 * @author  Anders Blehr
 * @version $Id: FastS_XMLMappingManager.h,v 1.2 2001/02/15 14:10:54 ablehr Exp $
 *///*************************************************************************
class FastS_XMLMappingManager : public FastSAX_HandlerBase
{
protected:
  /**
   * Enumaration used to identify the parse state when parsing the mapping
   * file.
   *
   * The values in the enumeration are: IDLE: No document events have yet
   * occurred; ROOT: We're at the root element for the mapping file; DELIM:
   * We're at the document delimiter element; LIST: We're at the mapping list
   * level, and MAPPING: We're at a specific mapping.
   */
  typedef enum { IDLE = 0, ROOT, DELIM, LIST, MAPPING } _MappingState;

  /**
   * A Fast_LogHandler instance for this class.
   */
  Fast_LogHandler * _logHandler;

  /**
   * A pointer to the current mapping (i.e., the @ref FastS_XMLMapping instance
   * corresponding to the mapping in the mapping file currently being parsed).
   * When notification is received of the @ref endElement() event that closes
   * the current element, the current mapping is appended to the end of the
   * mapping list for the element.
   */
  FastS_XMLMapping * _mapping;

  /**
   * A hash table of mapping lists (@ref FastS_XMLMappingList).  A mapping list
   * is created and inserted into the hash table for each XML element that has
   * one or more mappings in the mapping file.  The element name is used as
   * key.
   */
  Fast_HashTable<FastS_XMLMappingList *> * _mappingHash;

  /**
   * A string containing the document delimiter as specified in the mapping
   * file.
   *
   * The document delimiter delimits what from an indexing point of view
   * constitutes a document.  In practice, this means that a single XML file
   * can contain several documents, where the documents are separated by the
   * document delimiter.
   *
   * If specified, the document delimiter is always an XML element.
   *
   * If no document delimiter is specified in the mapping file, each XML file
   * will be treated as one and only one document.
   */
  Fast_String _documentDelimiter;

  /**
   * An instance of the FastS_FIXAPI_Configuration class.  This class maintains
   * the index layout as a hierarchy of classes corresponding to the contexts,
   * summary fields, and rank fields that make up the index.  It is not used in
   * this class, but is passed on to the constructor of the @ref
   * FastS_XMLMapping class whenever a mapping is identified in the mapping
   * file.
   *
   * The instance is instantiated by the @ref FastS_XMLIndexer class and
   * supplied to the constructor of this class as a parameter.
   */
  FastS_FIXAPI_Configuration * _configuration;

  /**
   * An instance of a class that implements the FastSAX_IParser interface.  It
   * is obtained through the use of the FastSAX_ParserFactory class, which is
   * instantiated in the main() program of the application.  The parser is
   * responsible for parsing the mapping file, and for notifying the mapping
   * manager (this FastS_XMLMappingManager instance) of document events.
   */
  FastSAX_IParser * _parser;

  /**
   * The current parse state (see @ref _MappingState).
   */
  _MappingState _state;

public:
  /**//************************************************************************
   * Constructor.
   *
   * Instantiates the @ref _mappingHash and the @ref _parser, and loads the
   * mapping file.
   *
   * @param mappingFile   The full path to and name of the mapping file.
   * @param configuration A valid FIXAPI configuration.
   *///************************************************************************  
  FastS_XMLMappingManager(const char *                 mappingFile,
                          FastS_FIXAPI_Configuration * configuration);

  /**//************************************************************************
   * Destructor.
   *///************************************************************************  
  virtual ~FastS_XMLMappingManager();

  /**//************************************************************************
   * Receive notification of a startElement event from the @ref _parser.
   *
   * Set the current state according to the current element.  If the state
   * indicates that the parser is currently parsing a mapping, construct this
   * mapping from the document data as it is received.
   *
   * @see FastS_XMLMapping
   * @see endElement()
   * @see FastSAX_IDocumentHandler
   * @see FastSAX_HandlerBase
   *
   * @param name          The element type name.
   * @param attributeList The attributes of the element, if any.
   *///************************************************************************  
  virtual void startElement(const char *             name,
                            FastSAX_IAttributeList * attributeList);

  /**//************************************************************************
   * Receive notification of an endElement event from the @ref _parser.
   *
   * Set the current state according to the element that ends.  If the state
   * indicates that a mapping has been constructed, add this mapping to the
   * mapping list for the element, creating the mapping list if it does not
   * already exist.
   *
   * @see FastS_XMLMapping
   * @see startElement()
   * @see FastSAX_IDocumentHandler
   * @see FastSAX_HandlerBase
   *
   * @param name The element type name.
   *///************************************************************************  
  virtual void endElement(const char * name);

  /**//************************************************************************
   * Receive notification of a warning from the @ref _parser.
   *
   * Give a warning using the SetWarning() method of the _logHandler with the
   * warning information embedded in the exception parameter.
   *
   * @see FastSAX_ParseException
   * @see FastSAX_IErrorHandler
   * @see FastSAX_HandlerBase
   *
   * @param parseException The warning information encapsulated in a SAX parse
   *                       exception.
   *///************************************************************************
  virtual void warning(FastSAX_ParseException& exception);

  /**//************************************************************************
   * Receive notification of a recoverable error from the @ref _parser.
   *
   * Set an error using the SetError() method of the _logHandler with the error
   * information embedded in the exception parameter.
   *
   * @see FastSAX_ParseException
   * @see FastSAX_IErrorHandler
   * @see FastSAX_HandlerBase
   *
   * @param parseException The error information encapsulated in a SAX parse
   *                       exception.
   *///************************************************************************
  virtual void error(FastSAX_ParseException& exception);

  /**//************************************************************************
   * Receive notification of an irrecoverable error from the @ref _parser.
   *
   * Set a fatal error using the SetError() method of the _logHandler with the
   * error information embedded in the exception parameter.
   *
   * @see FastSAX_ParseException
   * @see FastSAX_IErrorHandler
   * @see FastSAX_HandlerBase
   *
   * @param parseException The error information encapsulated in a SAX parse
   *                       exception.
   *///************************************************************************
  virtual void fatalError(FastSAX_ParseException& exception);

  /**//************************************************************************
   * Return the document delimiter as specified in the mapping file.
   *
   * @return The document delimiter as a string, or NULL if none was specified.
   *///************************************************************************
  const char * getDocumentDelimiter();

  /**//************************************************************************
   * Look up the mapping list for the specified element in the mapping hash and
   * return it to the caller.
   *
   * @return The mapping list for the specified element.
   *
   * @param element The element name for which to look up the mapping list.
   *///************************************************************************
  FastS_XMLMappingList * getMappings(const char * element);
};


#endif


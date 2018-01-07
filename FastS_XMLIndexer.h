#ifndef _FASTS_XMLINDEXER_H
#define _FASTS_XMLINDEXER_H
/*****************************************************************************
 * FastS_XMLIndexer.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastS_XMLIndexer.h,v 1.3 2001/02/15 14:10:54 ablehr Exp $
 * $Log: FastS_XMLIndexer.h,v $
 * Revision 1.3  2001/02/15 14:10:54  ablehr
 * - Bugfix
 *
 * Revision 1.2  2001/02/08 12:18:54  ablehr
 * - A little closer to 1.0...
 *
 * Revision 1.1.1.1  2001/02/06 11:52:52  ablehr
 * - Initial import into CVS.  No documentation at this stage.
 *
 *****************************************************************************/

#include <fastlib/util/string.h>
#include <fastlib/monitor/variablemonitor.h>
#include <fast/fixapi/fixapiconfiguration.h>
#include <fastsax/FastSAX.h>
#include <tokenizer/Fast_GenericTokenizer.h>

#include "FastS_XMLStateManager.h"
#include "FastS_XMLMappingManager.h"


/**//*************************************************************************
 * Index XML files, mapping XML elements and attributes to contexts, summary
 * fields, and rank fields as specified in the supplied mapping file.
 *
 * The class implements the Fast_TokenListener interface (cf. the FAST
 * Tokenizer documentation; CVS module `tokenizer') and extends the
 * FastSAX_HandlerBase class (cf. the FastSAX documentation; CVS module
 * `fastsax').
 *
 * In particular, it overrides the default implementation in
 * FastSAX_HandlerBase of the FastSAX_IDocumentHandler and
 * FastSAX_IErrorHandler interfaces.
 *
 * The class is instantiated once by the `xmlindex' application.  It in turn
 * instantiates a number of classes that are responsible for various indexing
 * subtasks, such as parsing, tokenizing, and indexing the XML data.
 *
 * During its lifetime, the class keeps track of the number of XML files
 * processed, the number of documents indexed (one XML file may contain several
 * documents), and the number of documents that were aborted due to XML parse
 * errors.
 *
 * @see FastS_FIXAPI_Configuration
 * @see FastSAX_HandlerBase
 * @see FastSAX_ParserFactory
 * @see FastSAX_IParser
 * @see Fast_GenericTokenizer
 * @see Fast_TokenListener
 * @see FastS_XMLMappingManager
 * @see FastS_XMLStateManager
 *
 * @author  Anders Blehr
 * @version $Id: FastS_XMLIndexer.h,v 1.3 2001/02/15 14:10:54 ablehr Exp $
 *///*************************************************************************
class FastS_XMLIndexer : public FastSAX_HandlerBase,
                         public Fast_TokenListener
{
protected:
  /**
   * A Fast_LogHandler instance for this class.
   */
  Fast_LogHandler * _logHandler;

  /**
   * An instance of the @ref FastS_XMLMappingManager class.  It is responsible
   * for reading and handling XML-to-FIXAPI mappings for the application.
   */
  FastS_XMLMappingManager * _mappingManager;

  /**
   * An instance of the @ref FastS_XMLStateManager class.  It is responsible
   * for keeping track of the XML parse state throughout the indexing process,
   * and for committing individial documents when they have been fully indexed.
   */
  FastS_XMLStateManager * _stateManager;

  /**
   * An instance of a class that implements the FastSAX_IParser interface.  It
   * is obtained through the use of the FastSAX_ParserFactory class, which is
   * instantiated in the main() program of the application.  The parser is
   * responsible for parsing the XML files that are to be indexed, and for
   * notifying the indexer (this FastS_XMLIndexer instance) of document events.
   */
  FastSAX_IParser * _parser;

  /**
   * An instance of the Fast_Tokenizer class or one of its derived classes.  It
   * is responsible for breaking the data obtained from the @ref _parser into
   * indexable chunks, i.e., words, and for notifying the indexer (this
   * FastS_XMLInexer instance) whenever a new word is available.
   *
   * However, the tokenizer is also responsible for notifying the indexer of
   * non-indexable data, which may be needed to construct document summaries
   * and/or static rank data.  It is in other words up to the indexer, not the
   * tokenizer, to decide what to do with the data obtained from the parser,
   * and consequently the tokenizer notifies the indexer whenever it has data,
   * be it indexable or not.
   */
  Fast_Tokenizer * _tokenizer;

  /**
   * An instance of the FastS_FIXAPI_Configuration class.  It is responsible
   * for reading the FIXAPI configuration file, and for maintaining a hierarchy
   * of classes corresponding to the layout of the FIXAPI configuration.
   */
  FastS_FIXAPI_Configuration * _configuration;

  /**
   * Flag indicating whether the FIXAPI @ref _configuration has been
   * initialized for indexing or not.
   */
  bool _initialized;

  /**
   * Flag indicating whether the FIXAPI @ref _configuration has finalized the
   * index.
   */
  bool _finalized;

public:
  /**//************************************************************************
   * Constructor.
   *
   * Creates the @ref _mappingManager, @ref _parser, @ref _tokenizer, @ref
   * _stateManger, and FIXAPI @ref _configuration instances needed by the
   * indexer; loads the FIXAPI configuration and mapping files, and sets the
   * @ref _parser's document and error handlers to point to this instance.
   * 
   * @see FastS_XMLMappingManager
   * @see FastS_XMLStateManager
   * @see FastSAX_IParser
   * @see Fast_Tokenizer
   * @see FastS_FIXAPI_Configuration
   *
   * @param configFile  The full path to and name of the FIXAPI configuration
   *                    file to use.
   * @param indexDir    The directory where the index will be created.
   * @param mappingFile The full path to and name of the mapping file to use.
   * @param partition   The data partition number (defaults to 0).
   *///************************************************************************  
  FastS_XMLIndexer(const char * configFile,
                   const char * indexDir,
                   const char * mappingFile,
                   unsigned int partition = 0);

  /**//************************************************************************
   * Destructor.
   *
   * Finalizes the index if it has not already been finalized, before deleting
   * all instances of classes instantiated by this instance.
   *///************************************************************************  
  virtual ~FastS_XMLIndexer();

  /**//************************************************************************
   * Receive notification of a startDocument event from the @ref _parser.
   *
   * Create a new parse state by calling the @ref newState() method of the @ref
   * _stateManager.
   *
   * @see FastS_XMLStateManager
   * @see endDocument()
   * @see FastSAX_IDocumentHandler
   * @see FastSAX_HandlerBase
   *///************************************************************************  
  virtual void startDocument();

  /**//************************************************************************
   * Receive notification of an endDocument event from the @ref _parser.
   *
   * Reset the state stack by calling the @ref reset() method of the @ref
   * _stateManager.
   *
   * @see FastS_XMLStateManager
   * @see startDocument()
   * @see FastSAX_IDocumentHandler
   * @see FastSAX_HandlerBase
   *///************************************************************************  
  virtual void endDocument();

  /**//************************************************************************
   * Receive notification of a startElement event from the @ref _parser.
   *
   * Create a new parse state by calling the @ref newState() method of the @ref
   * _stateManager.  Obtain the mapping list (cf. @ref FastS_XMLMappingList)
   * for this element from the @ref _mappingManager and iterate through the
   * list, adding each mapping (cf. @ref FastS_XMLMapping) that applies to this
   * element and/or attribute to the mapping list maintained by the current
   * state (cf. @ref FastS_XMLState) through the use of the @ref addMapping()
   * method of the @ref _stateMananger.
   *
   * For all attributes in the attribute list that have individual mappings,
   * tokenize and index these separately.
   *
   * @see FastS_XMLStateManager
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
   * Tokenize and index the data accumulated for this state, given that we can
   * tokenize as deemed by the @ref canTokenize() method of the @ref
   * _stateManager.
   *
   * Upon completion of tokenizing/indexing, make the previous state current by
   * popping it from the state stack through the use of the @ref popState()
   * method of the @ref _stateManager.
   *
   * @see FastS_XMLStateManager
   * @see startElement()
   * @see FastSAX_IDocumentHandler
   * @see FastSAX_HandlerBase
   *
   * @param name The element type name.
   *///************************************************************************  
  virtual void endElement(const char * name);

  /**//************************************************************************
   * Receive notification of a characters event from the @ref _parser.
   *
   * Append the character data to the tokenizer buffer if we can tokenize as
   * deemed by the @ref canTokenize() method of the @ref _stateManager.
   *
   * @see FastS_XMLStateManager
   * @see FastSAX_IDocumentHandler
   * @see FastSAX_HandlerBase
   *
   * @param data   The characters from the XML document.
   * @param start  The start position int the array.
   * @param length The number of characters to read from the array.
   *///************************************************************************  
  virtual void characters(const char * data, int start, int length);

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
  virtual void warning(FastSAX_ParseException& parseException);

  /**//************************************************************************
   * Receive notification of a recoverable error from the @ref _parser.
   *
   * Set an error using the SetError() method of the _logHandler with the error
   * information embedded in the exception parameter.  Upon catching the
   * exception thrown by the SetError() method, abort the document by calling
   * the @ref abortDocument() method of the @ref _stateManager, and perform the
   * exception's default action by calling the DefaultAction() method of the
   * caught exception.
   *
   * @see FastSAX_ParseException
   * @see FastSAX_IErrorHandler
   * @see FastSAX_HandlerBase
   *
   * @param parseException The error information encapsulated in a SAX parse
   *                       exception.
   *///************************************************************************
  virtual void error(FastSAX_ParseException& parseException);

  /**//************************************************************************
   * Receive notification of an irrecoverable error from the @ref _parser.
   *
   * Set a fatal error using the SetFatal() method of the _logHandler with the
   * error information embedded in the exception parameter.  Upon catching the
   * exception thrown by the SetError() method, give a warning that the
   * application will terminate, and then terminate the application by calling
   * the DefaultAction() method of the caught exception.
   *
   * @see FastSAX_ParseException
   * @see FastSAX_IErrorHandler
   * @see FastSAX_HandlerBase
   *
   * @param parseException The error information encapsulated in a SAX parse
   *                       exception.
   *///************************************************************************
  virtual void fatalError(FastSAX_ParseException& parseException);

  /**//************************************************************************
   * Receive notification of a new token from the @ref _tokenizer.
   *
   * Obtain the list of mappings for the current state from the @ref
   * _stateManager and iterate through these mappings.
   *
   * For each mapping that has contexts associated with it, add the token to
   * each of the contexts if the token is a word.  For each mapping that has
   * summary fields associated with it, append the token to each of the summary
   * fields.  For each mapping that has rank fields associated with it, set the
   * value of each rank field to the token's numeric value (if the token is not
   * numeric, an error will be set).
   *
   * @see FastS_XMLMapping
   * @see Fast_Tokenizer
   * @see FastS_FIXAPI_Context
   * @see FastS_FIXAPI_SummaryField
   * @see FastS_FIXAPI_RankField
   *///************************************************************************
  virtual void OnToken();

  /**//************************************************************************
   * Set the input encoding.
   *
   * The default encoding that the indexer expects, is UTF-8.  Use this method
   * to tell the indexer to expect a different input encoding.
   *
   * Note: The encoding string must be recognized by the `iconv' conversion
   * library.
   *
   * @param encoding The input encoding.
   *///************************************************************************
  void setInputEncoding(const char * encoding);

  /**//************************************************************************
   * Initiate the FIXAPI @ref _configuration for indexing.
   *
   * If this method is not invoked explicitly by the application, it will be
   * invoked upon the first invocation of the @ref index() method.
   *
   * @see index()
   * @see finalize()
   *///************************************************************************
  void initialize();

  /**//************************************************************************
   * Index an XML file.
   *
   * If the FIXAPI @ref _configuration has not been initiated for indexing, it
   * is initiated, whereupon the @ref _parser is told to parse the file.  The
   * parser will notify this instance of document events so that appropriate
   * actions are taken and character data indexed throughout the parse.
   *
   * @see FastSAX_IParser
   * @see initialize()
   *
   * @param fileName The name of the file to index.
   *///************************************************************************
  void index(const char * fileName);

  /**//************************************************************************
   * Finalize the index.
   *
   * If this method is not invoked explicitly by the application, it will be
   * invoked upon destruction by the destructor.
   *
   * @see initialize()
   *///************************************************************************
  void finalize();

  /**//************************************************************************
   * Return the number of documents that have been indexed successfully so far.
   *
   * This number is maintained by the @ref _stateManager.
   *
   * @see getNumDocumentsAborted()
   *
   * @return The number of documents that have been indexed successfully.
   *///************************************************************************
  int getNumDocumentsOK();

  /**//************************************************************************
   * Return the number of documents that have aborted so far.
   *
   * This number is maintained by the @ref _stateManager.
   *
   * @see getNumDocumentsOK()
   *
   * @return The number of documents that have aborted.
   *///************************************************************************
  int getNumDocumentsAborted();
};


#endif

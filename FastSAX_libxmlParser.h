#ifndef _FASTSAX_LIBXMLPARSER_H
#define _FASTSAX_LIBXMLPARSER_H
/******************************************************************************
 * FastSAX_libxmlParser.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 *
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_libxmlParser.h,v 1.4 2001/02/13 11:45:13 ablehr Exp $
 * $Log: FastSAX_libxmlParser.h,v $
 * Revision 1.4  2001/02/13 11:45:13  ablehr
 * - kdoc documentation complete (run `make doc').
 * - Consolidation complete.
 *
 ******************************************************************************/

extern "C" {
#include <gnome-xml/parser.h>
#include <gnome-xml/parserInternals.h>
#include <gnome-xml/xmlmemory.h>
}

#include "FastSAX_IParser.h"
#include "FastSAX_HandlerBase.h"
#include "FastSAX_libxmlLocator.h"
#include "FastSAX_libxmlAttributeList.h"


/**//**************************************************************************
 * Wrap libxml's (cf. http://www.xmlsoft.org/) SAX emulator in a @ref
 * FastSAX_IParser implementation.
 *
 * This class will be used by applications that need XML parsing, but do not
 * care nor want to know about the specifics of the parser implementation.
 * Applications should relate solely to the @ref FastSAX_IParser interface and
 * not to this specifc implementation of the interface.
 *
 * It is recommended to use the @ref FastSAX_ParserFactory class for obtaining
 * instances of this and other @ref FastSAX_IParser derived classes, rather
 * than instantiate the classes directly in the application code.  This will
 * ensure a loose coupling between the application and the SAX parser, enabling
 * easy replacement of one SAX parser with another.
 *
 * @see FastSAX_IParser
 * @see FastSAX_libxmlLocator
 * @see FastSAX_libxmlAttributeList
 *
 * @author  Anders Blehr
 * @version $Id: FastSAX_libxmlParser.h,v 1.4 2001/02/13 11:45:13 ablehr Exp $
 *///**************************************************************************
class FastSAX_libxmlParser : public FastSAX_IParser
{
/**
 * Befriend the function that the libxml parser will call when receiving
 * resolveEntity events, thus enabling the invocation of the @ref
 * resolveEntity() method of the parser's @ref _entityResolver.
 *
 * The current implementation only supports resolving system IDs that are file
 * names.  I.e., non-file entities are not supported.
 */
friend xmlParserInputPtr libxmlResolveEntity(void *, 
                                             const xmlChar *,
                                             const xmlChar * );
/**
 * Befriend the function that the libxml parser will call when receiving
 * notationDecl events, thus enabling the invocation of the @ref notationDecl()
 * method of the parser's @ref _DTDHandler.
 */
friend void libxmlNotationDecl(void *,
                               const xmlChar *,
                               const xmlChar *,
                               const xmlChar * );

/**
 * Befriend the function that the libxml parser will call when receiving
 * unparsedEntityDecl events, thus enabling the invocation of the @ref
 * unparsedEntityDecl() method of the parser's @ref _DTDHandler.
 */
friend void libxmlUnparsedEntityDecl(void *,
                                     const xmlChar *,
                                     const xmlChar *,
                                     const xmlChar *,
                                     const xmlChar * );

/**
 * Befriend the function that the libxml parser will call when receiving
 * setDocumentLocator events, thus enabling the invocation of the @ref
 * setDocumentLocator() method of the parser's @ref _documentHandler.
 */
friend void libxmlSetDocumentLocator(void *, xmlSAXLocatorPtr);

/**
 * Befriend the function that the libxml parser will call when receiving
 * startDocument events, thus enabling the invocation of the @ref
 * startDocument() method of the parser's @ref _documentHandler.
 */
friend void libxmlStartDocument(void *);

/**
 * Befriend the function that the libxml parser will call when receiving
 * endDocument events, thus enabling the invocation of the @ref endDocument()
 * method of the parser's @ref _documentHandler.
 */
friend void libxmlEndDocument(void *);

/**
 * Befriend the function that the libxml parser will call when receiving
 * startElement events, thus enabling the invocation of the @ref
 * startElement() method of the parser's @ref _documentHandler.
 */
friend void libxmlStartElement(void *, const xmlChar *, const xmlChar **);

/**
 * Befriend the function that the libxml parser will call when receiving
 * endElement events, thus enabling the invocation of the @ref endElement()
 * method of the parser's @ref _documentHandler.
 */
friend void libxmlEndElement(void *, const xmlChar *);

/**
 * Befriend the function that the libxml parser will call when receiving
 * characters events, thus enabling the invocation of the @ref characters()
 * method of the parser's @ref _documentHandler.
 */
friend void libxmlCharacters(void *, const xmlChar *, int);

/**
 * Befriend the function that the libxml parser will call when receiving
 * ignorableWhitespace events, thus enabling the invocation of the @ref
 * ignorableWhitespace() method of the parser's @ref _documentHandler.
 */
friend void libxmlIgnorableWhitespace(void *, const xmlChar *, int);

/**
 * Befriend the function that the libxml parser will call when receiving
 * processingInstruction events, thus enabling the invocation of the @ref
 * processingInstruction() method of the parser's @ref _documentHandler.
 */
friend void libxmlProcessingInstruction(void *,
                                        const xmlChar *,
                                        const xmlChar * );

/**
 * Befriend the function that the libxml parser will call when encountering
 * parse warnings, thus enabling the invocation of the @ref @warning() method
 * of the parser's @ref _errorHandler.
 */
friend void libxmlWarning(void *, const char *, ...);

/**
 * Befriend the function that the libxml parser will call when encountering
 * parse errors, thus enabling the invocation of the @ref error() method of
 * the parser's @ref _errorHandler.
 */
friend void libxmlError(void *, const char *, ...);

/**
 * Befriend the function that the libxml parser will call when encountering
 * fatal parse errors, thus enabling the invocation of the @ref fatalError()
 * method of the parser's @ref _errorHandler.
 */
friend void libxmlFatalError(void *, const char *, ...);

private:
  /**
   * A pointer to an instance of @ref FastSAX_HandlerBase.  Unless different
   * handlers are specified through the use of the @ref setDocumentHandler(),
   * @ref setDTDHandler(), @ref setEntityResolver(), and/or @ref
   * setErrorHandler(), all parse events will be handled by this instance.
   *
   * The default behaviour for practically all parse events is to do nothing,
   * so unless this is the desired behaviour, handlers that implement the
   * desired behaviour should be specified.
   */
  FastSAX_HandlerBase * _defaultHandler;

protected:
  /**
   * A pointer to the @ref FastSAX_IDocumentHandler implementation that handles
   * document events for this instance.  @ref _defaultHandler is used unless a
   * different document handler is specified using the @ref setDocumentHandler()
   * method.
   */
  FastSAX_IDocumentHandler * _documentHandler;

  /**
   * A pointer to the @ref FastSAX_IDTDHandler implementation that handles DTD
   * events for this instance.  @ref _defaultHandler is used unless a different
   * DTD handler is specified using the @ref setDTDHandler() method.
   */
  FastSAX_IDTDHandler * _DTDHandler;

  /**
   * A pointer to the @ref FastSAX_IEntityResolver implementation that resolves
   * entities for this instance.  @ref _defaultHandler is used unless a
   * different entity resolver is specified using the @ref setEntityResolver()
   * method.
   */
  FastSAX_IEntityResolver * _entityResolver;

  /**
   * A pointer to the @ref FastSAX_IErrorHandler implementation that handles
   * errors for this instance.  @ref _defaultHandler is used unless a different
   * error handler is specified using the @ref setErrorHandler() method.
   */
  FastSAX_IErrorHandler * _errorHandler;

  /**
   * A pointer to the @ref FastSAX_libxmlLocator (derived from @ref
   * FastSAX_ILocator) instance that associates document events with locations
   * for this instance.
   */
  FastSAX_libxmlLocator * _locator;

  /**
   * A persistent instance of @ref FastSAX_libxmlAttributeList (derived from
   * @ref FastSAX_AttributeListImpl) that is reset and populated with the
   * current element's attributes whenever a startElement event is received.
   * The instance is then passed to the @ref _documentHandler's @ref
   * startElement() method, to that the application can process the attributes.
   */
  FastSAX_libxmlAttributeList * _attributeList;

  /**
   * The Fast_LogHandler instance for this class.
   */
  Fast_LogHandler * _logHandler;

  /**
   * A pointer to libxml's parser context.  It is created for each call to @ref
   * parse() and destroyed upon completion of the parse.
   */
  xmlParserCtxtPtr _context;

public:
  /**//************************************************************************
   * Constructor.
   *
   * Instantiates the @ref _attributeList and @ref _defaultHandler member
   * variables, and sets the @ref _documentHandler, @ref _DTDHandler, @ref
   * _entityResolver, and @ref _errorHandler to point to the default handler.
   *///************************************************************************  
  FastSAX_libxmlParser();

  /**//************************************************************************
   * Destructor.
   *
   * Deletes the @ref _attributeList and @ref _defaultHandler instances.  Other
   * handlers were supplied by the application and should be deleted by the
   * application.
   *///************************************************************************  
  virtual ~FastSAX_libxmlParser();

  /**//************************************************************************
   * Allow an application to register a document event handler.
   *
   * If the application does not register a document handler, all document
   * events reported byt the SAX parser will be silently ignored (this is the
   * default behaviour implemented by @ref FastSAX_HandlerBase).
   *
   * Applications may register a new or different handler in the middle of a
   * parse, and the SAX parser must begin using the new handler immediately.
   *
   * @see FastSAX_IDocumentHandler
   * @see FastSAX_HandlerBase
   *
   * @param documentHandler The document handler.
   *///************************************************************************
  virtual void setDocumentHandler(FastSAX_IDocumentHandler * documentHandler);

  /**//************************************************************************
   * Allow an application to register a DTD event handler.
   *
   * If the application does not register a DTD handler, all DTD events
   * reported by the SAX parser will silently be ignored (this is the default
   * behaviour implemented by @ref FastSAX_HandlerBase).
   *
   * Applications may register a new or different handler in the middle of a
   * parse, and the SAX parser must begin using the new handler immediately.
   *
   * @see FastSAX_IDTDHandler
   * @see FastSAX_HandlerBase
   *
   * @param DTDHandler The DTD handler.
   *///************************************************************************
  virtual void setDTDHandler(FastSAX_IDTDHandler * DTDHandler);

  /**//************************************************************************
   * Allow an application to register a custom entity resolver.
   *
   * If the application does not register an entity resolver, the SAX parser
   * will resolve system identifiers and open connections to entities itself
   * (this is the default behavious implemented by @ref FastSAX_HandlerBase).
   *
   * Applications may register a new or different entity resolver in the
   * middle of a parse, and the SAX parser must begin using the new resolver
   * immediately.
   *
   * @see FastSAX_IEntityResolver
   * @see FastSAX_HandlerBase
   *
   * @param entityResolver The object for resolving entities.
   *///************************************************************************
  virtual void setEntityResolver(FastSAX_IEntityResolver * entityResolver);

  /**//************************************************************************
   * Allow an application to register an error event handler.
   *
   * If the application does not register an error event handler, all error
   * events reported by the SAX parser will be silently ignored, except for
   * @ref fatalError(), which will throw a @ref FastSAX_SAXException (this is
   * the default behaviour implemented by @ref FastSAX_HandlerBase).
   *
   * Applications may register a new or different handler in the middle of a
   * parse, and the SAX parser must begin using the new handler immediately.
   *
   * @see FastSAX_IDocumentHandler
   * @see FastSAX_HandlerBase
   *
   * @param documentHandler The document handler.
   *///************************************************************************
  virtual void setErrorHandler(FastSAX_IErrorHandler * errorHandler);

  /**//************************************************************************
   * Parse an XML document.
   *
   * The application can use this method to instruct the SAX parser to begin
   * parsing an XML document from any valid input source (a character stream,
   * a byte stream, or a URI).
   *
   * Applications may not invoke this method while a parse is in progress (they
   * should create a new parser instead for each additional XML document).
   * Once a parse is complete, an application may reuse the same parser object,
   * possibly with a different input source.
   *
   * Note: Currently, invoking this method is the exact equivalent of the
   * following:
   *
   * <pre>
   *   parse(inputSource->getSystemId());
   * </pre>
   *
   * Furthermore, if the system ID does not identify a local file, the parse
   * will fail.  I.e., the only input source currently supported, is local
   * files.
   *
   * @see FastSAX_IParser
   * @see FastSAX_InputSource
   * @see parse(const char *)
   *
   * @param inputSource The input source for the top-level of the XML document.
   *///************************************************************************
  virtual void parse(FastSAX_InputSource * inputSource);

  /**//************************************************************************
   * Parse an XML document from a system identifier (URI).
   *
   * This method is a shortcut for the common case of reading a document from a
   * system identifier.  It is the exact equivalent of the following:
   *
   * <pre>
   *   parse(new FastSAX_InputSource(systemId));
   * </pre>
   *
   * If the system identifier is a URL, it must be fully resolved before it is
   * passed to the parser.
   *
   * @see FastSAX_IParser
   * @see parse(FastSAX_InputSource *)
   *
   * @param systemId The system identifier (URI).
   *///************************************************************************
  virtual void parse(const char * systemId);
};


#endif

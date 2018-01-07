#ifndef _FASTSAX_IPARSER_H
#define _FASTSAX_IPARSER_H
/******************************************************************************
 * FastSAX_IParser.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 *
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_IParser.h,v 1.3 2001/02/09 12:07:47 ablehr Exp $
 * $Log: FastSAX_IParser.h,v $
 * Revision 1.3  2001/02/09 12:07:47  ablehr
 * - Consolidated.
 *
 * Revision 1.2  2001/02/08 12:17:45  ablehr
 * - Added a few comments and made minor modifications.  A little closer to 1.0...
 *
 ******************************************************************************/

#include "FastSAX_IDocumentHandler.h"
#include "FastSAX_IDTDHandler.h"
#include "FastSAX_IEntityResolver.h"
#include "FastSAX_IErrorHandler.h"


/**//**************************************************************************
 * [Most or all of this documentation is copied from David Megginson's official
 * SAX1 for Java release; cf. http://www.megginson.com/SAX/.]
 * 
 * Basic interface for SAX (Simple API for XML) parsers.
 *
 * All SAX parsers must implement this basic interface: it allows applications
 * to register handlers for different types of events and to initiate a parse
 * from a URI, or a character stream.
 *
 * All SAX parsers must also implement a zero-argument constructor (though
 * other constructors are also allowed).
 *
 * SAX parsers are reusable but not re-entrant: the application may reuse a
 * parser object (possibly with a different input source) once the first parse
 * has completed successfully, but it may not invoke the @ref parse() method
 * recursively within a parse.
 *
 * @see FastSAX_IEntityResolver
 * @see FastSAX_IDTDHandler
 * @see FastSAX_IDocumentHandler
 * @see FastSAX_IErrorHandler
 * @see FastSAX_HandlerBase
 * @see FastSAX_InputSource
 *///**************************************************************************
class FastSAX_IParser
{
public:
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
  virtual void setDocumentHandler(FastSAX_IDocumentHandler * documentHandler) = 0;

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
  virtual void setDTDHandler(FastSAX_IDTDHandler * DTDHandler) = 0;

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
  virtual void setEntityResolver(FastSAX_IEntityResolver * entityResolver) = 0;

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
  virtual void setErrorHandler(FastSAX_IErrorHandler * errorHandler) = 0;

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
   * @see FastSAX_InputSource
   * @see parse(const char *)
   * @see setEntityResolver()
   * @see setDTDHandler()
   * @see setDocumentHandler()
   * @see setErrorHandler()
   *
   * @param inputSource The input source for the top-level of the XML document.
   *///************************************************************************
  virtual void parse(FastSAX_InputSource * inputSource) = 0;

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
   * @see parse(FastSAX_InputSource *)
   *
   * @param systemId The system identifier (URI).
   *///************************************************************************
  virtual void parse(const char * systemId) = 0;
};


#endif

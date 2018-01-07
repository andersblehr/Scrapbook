#ifndef _FASTSAX_HANDLERBASE_H
#define _FASTSAX_HANDLERBASE_H
/******************************************************************************
 * FastSAX_HandlerBase.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 *
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_HandlerBase.h,v 1.4 2001/02/13 11:45:13 ablehr Exp $
 * $Log: FastSAX_HandlerBase.h,v $
 * Revision 1.4  2001/02/13 11:45:13  ablehr
 * - kdoc documentation complete (run `make doc').
 * - Consolidation complete.
 *
 * Revision 1.3  2001/02/09 12:07:47  ablehr
 * - Consolidated.
 *
 ******************************************************************************/

#include "FastSAX_IEntityResolver.h"
#include "FastSAX_IDTDHandler.h"
#include "FastSAX_IDocumentHandler.h"
#include "FastSAX_IErrorHandler.h"


/**//**************************************************************************
 * [Most or all of this documentation is copied from David Megginson's official
 * SAX1 for Java release; cf. http://www.megginson.com/SAX/.]
 *
 * Default base class for handlers.
 *
 * This class implements the default behaviour for four SAX interfaces: @ref
 * FastSAX_IEntityResolver, @ref FastSAX_IDTDHandler, @ref
 * FastSAX_IDocumentHandler, and @ref FastSAX_IErrorHandler.
 *
 * Application writers can extend this class when they need to implement only
 * part of an interface; parser writers can instantiate this class to provide
 * default handlers when the application has not supplied its own.
 *
 * Note that the use of this class is optional.
 *
 * @see FastSAX_IEntityResolver
 * @see FastSAX_IDTDHandler
 * @see FastSAX_IDocumentHandler
 * @see FastSAX_IErrorHandler
 *
 * @author  Anders Blehr
 * @version $Id: FastSAX_HandlerBase.h,v 1.4 2001/02/13 11:45:13 ablehr Exp $
 *///**************************************************************************
class FastSAX_HandlerBase : public FastSAX_IEntityResolver,
                            public FastSAX_IDTDHandler,
                            public FastSAX_IDocumentHandler,
                            public FastSAX_IErrorHandler
{
protected:
  /**
   * Locator object for document events.
   */
  FastSAX_ILocator * _locator;

public:
  /**//************************************************************************
   * Zero-parameter default constructor.
   *
   * The @ref _locator member variable is initialized to NULL.
   *///************************************************************************
  FastSAX_HandlerBase();

  /**//************************************************************************
   * Destructor.
   *///************************************************************************
  virtual ~FastSAX_HandlerBase();

  /**//************************************************************************
   * Resolve an external entity.
   *
   * Always return NULL, so that the parser will use the system identifier
   * provided int the XML document.  This method implements the SAX default
   * behaviour: application writers can override it in a subclass to do special
   * translations such as catalog lookups or URI redirection.
   *
   * @return The new input source, or NULL to require the default behaviour.
   *
   * @param publicId The public identifier, or NULL if none is available.
   * @param systemId The system identifier provided in the XML document.
   *///************************************************************************
  virtual FastSAX_InputSource * resolveEntity(const char * publicId,
                                              const char * systemId );

  /**//************************************************************************
   * Receive notification of an unparsed entity declaration.
   *
   * By default, do nothing.  Application writers may override this method in a
   * subclass if they wish to keep track of the notations declared in a
   * document.
   *
   * @param name     The notation name.
   * @param publicId The notation public identifier, or NULL if none is
   *                 available.
   * @param systemId The notation system identifier.
   *///************************************************************************
  virtual void notationDecl(const char * name,
                            const char * publicId,
                            const char * systemId );

  /**//************************************************************************
   * Receive notification of an unparsed entity declaration.
   *
   * By default, do nothing.  Application writers may override this method in a
   * subclass to keep track of the unparsed entities declared in a document.
   *
   * @param name         The entity name.
   * @param publicId     The entity public identifier, or NULL if none is
   *                     available.
   * @param systemId     The entity system identifier.
   * @param notationName The name of the associated notation
   *///************************************************************************
  virtual void unparsedEntityDecl(const char * name,
                                  const char * publicId,
                                  const char * systemId, 
                                  const char * notationName);

  /**//************************************************************************
   * Receive a @ref FastSAX_ILocator object for document events. 
   *
   * Store the locator.
   *
   * This is not the default SAX behaviour.  The default behaviour would do
   * nothing and leave it up to application writers to override this method in
   * a subclass if they wished to store the locator for use with other document
   * events.
   *
   * @see FastSAX_ILocator
   *
   * @param locator A locator for all SAX document events.
   *///************************************************************************
  virtual void setDocumentLocator(FastSAX_ILocator * locator);

  /**//************************************************************************
   * Receive notification of the beginning of the document.
   *
   * By default, do nothing.  Application writers may override this method in a
   * subclass to take specific actions at the beginning of a document (such as
   * allocating the root node of a tree or creating an output file).
   *///************************************************************************
  virtual void startDocument();

  /**//************************************************************************
   * Receive notification of the end of the document.
   *
   * By default, do nothing.  Application writers may override this method in a
   * subclass to do specific actions at the end of a document (such as
   * finalizing a tree or closing an output file).
   *///************************************************************************
  virtual void endDocument();

  /**//************************************************************************
   * Receive notification of the start of an element.
   *
   * By default, do nothing.  Application writers may override this method in a
   * subclass to take specific actions at the start of each element (such as
   * allocating a new tree node or writing output to a file).
   *
   * @param name          The element type name.
   * @param attributeList The specified or defaulted attributes.
   *///************************************************************************
  virtual void startElement(const char *             name,
                            FastSAX_IAttributeList * attributeList);

  /**//************************************************************************
   * Receive notification of the end of an element.
   *
   * By default, do nothing.  Application writers may override this method in a
   * subclass to take specific actions at the end of each element (such as
   * finalizing a tree node or writing output to a file).
   *
   * @param name The element type name.
   *///************************************************************************
  virtual void endElement(const char * name);

  /**//************************************************************************
   * Receive notification of character data inside an element.
   *
   * By default, do nothing.  Application writers may override this method to
   * take specific actions for each chunk of character data (such as adding the
   * data to a node or buffer, or printing it to a file).
   *
   * @param data   The characters.
   * @param start  The start position in the character array.
   * @param length The number of characters to use from the character array.
   *///************************************************************************
  virtual void characters(const char * data, int start, int length);

  /**//************************************************************************
   * Receive notification of ignorable whitespace in element content.
   *
   * By default, do nothing.  Application writers may override this method to
   * take specific actions for each chunk of ignorable whitespace (such as
   * adding data to a node or buffer, or printing it to a file).
   *
   * @param data   The whitespace characters.
   * @param start  The start position in the character array.
   * @param length The number of characters to use from the character array.
   *///************************************************************************
  virtual void ignorableWhitespace(const char * data, int start, int length);

  /**//************************************************************************
   * Receive notification of a processing instruction.
   *
   * By default, do nothing.  Application writers may override this method in a
   * subclass to take specific actions for each processing instruction, such as
   * setting status variables or invoking other methods.
   *
   * @param target The processing instruction target.
   * @param data   The processing instruction data, or NULL if none is
   *               supplied.
   *///************************************************************************
  virtual void processingInstruction(const char * target, const char * data);
  
  /**//************************************************************************
   * Receive notification of a parser warning.
   *
   * The default implementation does nothing.  Application writers may override
   * this method in a subclass to take specific actions for each warning, such
   * as inserting the message in a log file or printing it to the console.
   *
   * @see FastSAX_ParseException
   * 
   * @param exception The warning information encoded as an exception.
   *///************************************************************************
  virtual void warning(FastSAX_ParseException& exception);

  /**//************************************************************************
   * Receive notification of a recoverable parser error.
   * 
   * The default implementation does nothing.  Application writers may override
   * this method in a subclass to take specific actions for each error, such as
   * inserting the message in a log file or printing it to the console.
   *
   * @see FastSAX_ParseException
   * 
   * @param exception The error information encoded as an exception.
   *///************************************************************************
  virtual void error(FastSAX_ParseException& exception);

  /**//************************************************************************
   * Report a fatal XML parsing error.
   *
   * The default implementation throws a @ref FastSAX_ParseException.
   * Application writers may override this method in a subclass if they need to
   * take specific actions for each fatal error (such as collecting all of the
   * errors into a single report): in any case, the application must stop all
   * regular processing when this method is invoked, since the document is no
   * longer reliable, and the parser may no longer report parsing events.
   * 
   * @see FastSAX_ParseException
   * 
   * @param exception The error information encoded as an exception.
   *///************************************************************************
  virtual void fatalError(FastSAX_ParseException& exception);
};


#endif

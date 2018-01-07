#ifndef _FASTSAX_PARSEEXCEPTION_H
#define _FASTSAX_PARSEEXCEPTION_H
/******************************************************************************
 * FastSAX_ParseException.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 *
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_ParseException.h,v 1.4 2001/02/13 11:45:13 ablehr Exp $
 * $Log: FastSAX_ParseException.h,v $
 * Revision 1.4  2001/02/13 11:45:13  ablehr
 * - kdoc documentation complete (run `make doc').
 * - Consolidation complete.
 *
 * Revision 1.3  2001/02/09 12:07:48  ablehr
 * - Consolidated.
 *
 * Revision 1.2  2001/02/08 12:17:45  ablehr
 * - Added a few comments and made minor modifications.  A little closer to 1.0...
 *
 ******************************************************************************/

#include "FastSAX_Exception.h"
#include "FastSAX_ILocator.h"


/**//**************************************************************************
 * [Most or all of this documentation is copied from David Megginson's official
 * SAX1 for Java release; cf. http://www.megginson.com/SAX/.]
 *
 * Encapsulate an XML parse error or warning.
 *
 * This exception will include information for locating the error in the
 * original XML document.  Note that although the application will receive a
 * FastSAX_ParseException as the argument to the handlers in the @ref
 * FaatSAX_IErrorHandler interface, the application is not actually required to
 * throw the exception; instead, it can simply read the information in it and
 * take a different action.
 *
 * Since this exception is a subclass of @ref FastSAX_Exception, it inherits
 * its ability to wrap another exception.
 *
 * @see FastSAX_Exception
 * @see FastSAX_ILocator
 * @see FastSAX_IErrorHandler
 *
 * @author  Anders Blehr
 * @version $Id: FastSAX_ParseException.h,v 1.4 2001/02/13 11:45:13 ablehr Exp $
 *///**************************************************************************
class FastSAX_ParseException : public FastSAX_Exception
{
protected:
  /**
   * The public identifier of the entity where the exception ocurred.
   */
  Fast_String _publicId;

  /**
   * The system identifier of the entity where the exception ocurred.
   */
  Fast_String _systemId;

  /**
   * The line number of the end of the text where the exception ocurred.
   */
  int         _lineNumber;

  /**
   * The column number of the end of the text where the exception ocurred.
   */
  int         _columnNumber;

public:
  /**//************************************************************************
   * Create a new FastSAX_ParseException from a message and a locator.
   *
   * This constructor is especially useful when an application is creating its
   * own exception from within a @ref FastSAX_IDocumentHandler callback.
   *
   * @see FastSAX_ILocator
   *
   * @param message The error or warning message.
   * @param locator The locator object for the error or warning.
   *///************************************************************************
  FastSAX_ParseException(const char *       message,
                         FastSAX_ILocator * locator );

  /**//************************************************************************
   * Wrap an existing exception in a FastSAX_ParseException
   *
   * This constructor is especially useful when an application is creating its
   * own exception from within a @ref FastSAX_IDocumentHandler callback, and
   * needs to wrap an existing exception that is not a subclass of @ref
   * FastSAX_Exception.
   *
   * @see FastSAX_ILocator
   *
   * @param message   The error or warning message.
   * @param locator   The locator object for the error or warning.
   * @param exception Any exception.
   *///************************************************************************
  FastSAX_ParseException(const char *       message,
                         FastSAX_ILocator * locator,
                         Fast_Exception *   exception);

  /**//************************************************************************
   * Create a new FastSAX_ParseException.
   *
   * This constructor is most useful for parser writers.
   *
   * If the system identifier is a URL, the parser must resolve it fully before
   * creating the exception.
   *
   * @param message      The error or warning message.
   * @param publicId     The public identifier of the entity that generated the
   *                     error or warning.
   * @param systemId     The system identifier of the entity that generated the
   *                     error or warning.
   * @param lineNumber   The line number of the end of the text that caused the
   *                     error or warning.
   * @param columnNumber The column number of the end of the text that caused
   *                     the error or warning.
   *///************************************************************************
  FastSAX_ParseException(const char * message,
                         const char * publicId,
                         const char * systemId,
                         int          lineNumber,
                         int          columnNumber);

  /**//************************************************************************
   * Create a new FastSAX_ParseException with an embedded exception.
   *
   * This constructor is most useful for parser writers who need to wrap an
   * exception that is not a subclass of FastSAX_Exception.
   *
   * If the system identifier is a URL, the parser must resolve it fully before
   * creating the exception.
   *
   * @param message      The error or warning message, or NULL to use the
   *                     message from the embedded exception.
   * @param publicId     The public identifier of the entity that generated the
   *                     error or warning.
   * @param systemId     The system identifier of the entity that generated the
   *                     error or warning.
   * @param lineNumber   The line number of the end of the text that caused the
   *                     error or warning.
   * @param columnNumber The column number of the end of the text that caused
   *                     the error or warning.
   * @param exception    Another exception to embed in this one.
   *///************************************************************************
  FastSAX_ParseException(const char *     message,
                         const char *     publicId,
                         const char *     systemId,
                         int              lineNumber,
                         int              columnNumber,
                         Fast_Exception * exception    );

  /**//************************************************************************
   * Destructor.
   *///************************************************************************
  virtual ~FastSAX_ParseException();

  /**//************************************************************************
   * Get the public identifier of the entity where the exception occurred.
   *
   * @see getSystemId()
   *
   * @return A string containing the public identifier, or NULL if none is
   *         available.
   *///************************************************************************
  const char * getPublicId();

  /**//************************************************************************
   * Get the system identifier of the entity where the exception occurred.
   *
   * If the system identifier is a URL, it will be resolved fully.
   *
   * @see getPublicId()
   *
   * @return A string containing the system identifier, or NULL if none is
   *         available.
   *///************************************************************************
  const char * getSystemId();

  /**//************************************************************************
   * The line number of the end of the text where the exception occurred.
   *
   * @see getColumnNumber()
   *
   * @return An integer representing the line number, or -1 if none is
   *         available.
   *///************************************************************************
  int          getLineNumber();

  /**//************************************************************************
   * The column number of the end of the text where the exception occurred.
   *
   * The first column in a line is position 1.
   *
   * @see getLineNumber()
   *
   * @return An integer representing the column number, or -1 if none is
   *         available.
   *///************************************************************************
  int          getColumnNumber();
};


#endif

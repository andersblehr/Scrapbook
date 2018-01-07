#ifndef _FASTSAX_IERRORHANDLER_H
#define _FASTSAX_IERRORHANDLER_H
/******************************************************************************
 * FastSAX_IErrorHandler.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 *
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_IErrorHandler.h,v 1.4 2001/02/13 11:45:13 ablehr Exp $
 * $Log: FastSAX_IErrorHandler.h,v $
 * Revision 1.4  2001/02/13 11:45:13  ablehr
 * - kdoc documentation complete (run `make doc').
 * - Consolidation complete.
 *
 * Revision 1.3  2001/02/09 12:07:47  ablehr
 * - Consolidated.
 *
 * Revision 1.2  2001/02/08 12:17:45  ablehr
 * - Added a few comments and made minor modifications.  A little closer to 1.0...
 *
 ******************************************************************************/

#include "FastSAX_ParseException.h"


/**//**************************************************************************
 * [Most or all of this documentation is copied from David Megginson's official
 * SAX1 for Java release; cf. http://www.megginson.com/SAX/.]
 * 
 * Basic interface for SAX error handlers.
 *
 * If a SAX application needs to implement customized error handling, it must
 * implement this interface and then register an instance with the SAX parser
 * using the parser's @ref setErrorHandler() method.  The parser will then
 * report all errors and warnings through this interface.
 *
 * The parser shall use this interface instead of throwing an exception: it is
 * up to the application whether to throw an exception for different types of
 * errors and warnings.  Note, however, that there is no requirement that the
 * parser continue to provide useful information after a call to @ref
 * fatalError() (in other words, a SAX driver class could catch an exception
 * and report a fatal error).
 *
 * The @ref FastSAX_HandlerBase class provides a default implementation of this
 * interface, ignoring warnings and recoverable errors and throwing a @ref
 * FastSAX_ParseException for fatal errors.  An application may extend that
 * class rather than implementing the complete interface itself.
 *
 * @see setErrorHandler()
 * @see FastSAX_ParseException
 * @see FastSAX_HandlerBase
 *
 * @author  Anders Blehr
 * @version $Id: FastSAX_IErrorHandler.h,v 1.4 2001/02/13 11:45:13 ablehr Exp $
 *///**************************************************************************
class FastSAX_IErrorHandler
{
public:
  /**//************************************************************************
   * Receive notification of a warning.
   *
   * SAX parsers will use this method to report conditions that are not errors
   * or fatal errors as defined by the XML 1.0 recommendation.  The default
   * behaviour is to take no action.
   *
   * The SAX parser must continue to provide normal parsing events after
   * invoking this method: it should still be possible for the application to
   * process the document through to the end.
   *
   * @see FastSAX_ParseException
   *
   * @param exception The warning information encapsulated in a SAX parse
   *                  exception.
   *///************************************************************************
  virtual void warning(FastSAX_ParseException& exception) = 0;

  /**//************************************************************************
   * Receive notification of a recoverable error.
   *
   * This corresponds to the definition of "error" in section 1.2 of the W3C
   * XML 1.0 Recommendation.  For example, a validating parser would use this
   * callback to report the violation of a validity constraint.  The default
   * behaviour is to take no action.
   *
   * The SAX parser must continue to provide normal parsing events after
   * invoking this method: it should still be possible for the application to
   * process the document through to the end.  If the application cannot do so,
   * then the parser should report a fatal error even if the XML 1.0
   * recommendation does not require it to do so.
   *
   * @see FastSAX_ParseException
   *
   * @param exception The error information encapsulated in a SAX parse
   *                  exception.
   *///************************************************************************
  virtual void error(FastSAX_ParseException& exception) = 0;

  /**//************************************************************************
   * Receive notification of a non-recoverable error.
   *
   * This corresponds to the definition of "fatal error" in section 1.2 of the
   * W3C XML 1.0 Recommendation.  For example, a parser would use this callback
   * to report the violation of a well-formedness constraint.
   *
   * The application must assume that the document is unusable after the parser
   * has invoked this method, and should continue (if at all) only for the sake
   * of collection additional error messages: in fact, SAX parsers are free to
   * stop reporting any other events once this method has been invoked.
   *
   * @see FastSAX_ParseException
   *
   * @param exception The error information encapsulated in a SAX parse
   *                  exception.
   *///************************************************************************
  virtual void fatalError(FastSAX_ParseException& exception) = 0;
};


#endif

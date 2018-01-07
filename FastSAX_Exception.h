#ifndef _FASTSAX_EXCEPTION_H
#define _FASTSAX_EXCEPTION_H
/******************************************************************************
 * FastSAX_Exception.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 *
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_Exception.h,v 1.4 2001/02/13 11:45:13 ablehr Exp $
 * $Log: FastSAX_Exception.h,v $
 * Revision 1.4  2001/02/13 11:45:13  ablehr
 * - kdoc documentation complete (run `make doc').
 * - Consolidation complete.
 *
 * Revision 1.3  2001/02/09 12:07:47  ablehr
 * - Consolidated.
 *
 * Revision 1.2  2001/02/08 12:17:44  ablehr
 * - Added a few comments and made minor modifications.  A little closer to 1.0...
 *
 ******************************************************************************/

#include <ftutil/Fast_Exception.h>


/**//**************************************************************************
 * [Most or all of this documentation is copied from David Megginson's official
 * SAX1 for Java release; cf. http://www.megginson.com/SAX/.]
 *
 * Encapsulate a general SAX error or warning.
 *
 * This class can contain basic error or warning information from either the
 * XML parser or the application: a parser writer or application writer can
 * subclass it to provide additional functionality.  SAX handlers may throw
 * this exception or any exception subclassed from it.
 *
 * If the application needs to pass through other types of exceptions, it must
 * wrap those eceptions in a FastSAX_Exception or an exception derived from
 * FastSAX_Exception.
 *
 * If the parser or application needs to include information about a specific
 * location in an XML document, it should use the @ref FastSAX_ParseException
 * subclass.
 *
 * Note: The toString() method of the SAX1 for Java release is not implemented.
 *
 * @see FastSAX_ParseException
 *
 * @author  Anders Blehr
 * @version $Id: FastSAX_Exception.h,v 1.4 2001/02/13 11:45:13 ablehr Exp $
 *///**************************************************************************
class FastSAX_Exception : public Fast_Exception
{
protected:
  /**
   * The embedded exception.
   */
  Fast_Exception * _exception;

public:
  /**//************************************************************************
   * Create a new FastSAX_Exception.
   *
   * @param message The error or warning message.
   *///************************************************************************
  FastSAX_Exception(const char * message);

  /**//************************************************************************
   * Create a new FastSAX_Exception wrapping an existing exception.
   *
   * The existing exception will be embedded in the new one, and its message
   * will become the default message for the FastSAX_Exception.
   *
   * @param exception The exception to be wrapped in a FastSAX_Exception.
   *///************************************************************************
  FastSAX_Exception(Fast_Exception * exception);

  /**//************************************************************************
   * Create a new FastSAX_Exception from an existin exception.
   *
   * The existing exception will be embedded in the new one, but the new
   * exception will have its own message.
   *
   * @param message   The detail message.
   * @param exception The exception to be wrapped in a FastSAX_Exception.
   *///************************************************************************
  FastSAX_Exception(const char * message, Fast_Exception * exception);

  /**//************************************************************************
   * Destroy the FastSAX_Exception instance.
   *///************************************************************************
  virtual ~FastSAX_Exception();

  /**//************************************************************************
   * Return a detail message for this exception.
   *
   * If there is an embedded exception, and if thte FastSAX_Exception has no
   * detail message of its own, this method will return the detail message from
   * the embedded exception.
   *
   * @return The error or warning message.
   *///************************************************************************
  virtual const char * getMessage();

  /**//************************************************************************
   * Return the embedded exception, if any.
   *
   * @return The embedded exception, or NULL if there is none.
   *///************************************************************************
  Fast_Exception * getException();
};


#endif

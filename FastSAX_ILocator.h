#ifndef _FASTSAX_ILOCATOR_H
#define _FASTSAX_ILOCATOR_H
/******************************************************************************
 * FastSAX_ILocator.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 *
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_ILocator.h,v 1.4 2001/02/13 11:45:13 ablehr Exp $
 * $Log: FastSAX_ILocator.h,v $
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


/**//**************************************************************************
 * [Most or all of this documentation is copied from David Megginson's official
 * SAX1 for Java release; cf. http://www.megginson.com/SAX/.]
 * 
 * Interface for associating a SAX event with a document location.
 *
 * If a SAX parser provides location information to the SAX application, it
 * does so by implementing this interface and then passing an instance to the
 * application using the document handler's @ref setDocumentLocator() method.
 * The application can use the object to obtain the location of any other
 * document handler event in the XML source document.
 *
 * Note that the result returned by the object will be valid only during the
 * scope of each document handler method: the application will receive
 * unpredictable results if it attempts to use the locator at any other time.
 *
 * SAX parsers are not required to supply a locator, but they are very strongly
 * encouraged to do so.  If the parser supplies a locator, it must do so before
 * reporting any other document events.  If no locator has been set by the time
 * the application receives the @ref startDocument() event, the application
 * should assume that a locator is not available.
 *
 * @see setDocumentLocator()
 *
 * @author  Anders Blehr
 * @version $Id: FastSAX_ILocator.h,v 1.4 2001/02/13 11:45:13 ablehr Exp $
 *///**************************************************************************
class FastSAX_ILocator
{
public:
  /**//************************************************************************
   * Return the public identifier for the current document event.
   *
   * This will be the public identifier.
   *
   * @see getSystemId()
   *
   * @return A string containing the public identifier, or NULL if none is
   *         available.
   *///************************************************************************
  virtual const char * getPublicId() const = 0;

  /**//************************************************************************
   * Return the system identifier for the current document event.
   *
   * If the system identifier is a URL, the parser must resolve it fully before
   * passing it to the application.
   *
   * @see getPublicId()
   *
   * @return A string containing the system identifier, or NULL if none is
   *         available.
   *///************************************************************************
  virtual const char * getSystemId() const = 0;

  /**//************************************************************************
   * Return the line number where the current document event ends.  Note that
   * this is the line position of the first character after the text associated
   * with the document event.
   *
   * @see getColumnNumber()
   *
   * @return The line number, or -1 if none is available.
   *///************************************************************************
  virtual int getLineNumber() const = 0;

  /**//************************************************************************
   * Return the column numver where the current document event ends.  Note that
   * this is the column number of the first character after the text associated
   * with the document event.  The first column in a line is position 1.
   *
   * @see getLineNumber()
   *
   * @return The column number, or -1 if none is available.
   *///************************************************************************
  virtual int getColumnNumber() const = 0;
};


#endif

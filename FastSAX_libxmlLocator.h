#ifndef _FASTSAX_LIBXMLLOCATOR_H
#define _FASTSAX_LIBXMLLOCATOR_H
/******************************************************************************
 * FastSAX_libxmlLocator.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 *
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_libxmlLocator.h,v 1.2 2001/02/13 11:45:13 ablehr Exp $
 * $Log: FastSAX_libxmlLocator.h,v $
 * Revision 1.2  2001/02/13 11:45:13  ablehr
 * - kdoc documentation complete (run `make doc').
 * - Consolidation complete.
 *
 ******************************************************************************/

extern "C" {
#include <gnome-xml/parser.h>
}

#include "FastSAX_ILocator.h"


/**//**************************************************************************
 * Provide a @ref FastSAX_ILocator implementation that encapsulates libxml's
 * SAX emulation and its mechanisms for asslocating SAX events with document
 * locations.
 *
 * This class will only be instantiated by @ref FastSAX_libxmlParser instances;
 * SAX application writers should never have to and are not able to instantiate
 * this class.
 *
 * @see FastSAX_ILocator
 * @see FastSAX_libxmlParser
 *
 * @author  Anders Blehr
 * @version $Id: FastSAX_libxmlLocator.h,v 1.2 2001/02/13 11:45:13 ablehr Exp $
 *///**************************************************************************
class FastSAX_libxmlLocator : public FastSAX_ILocator
{
/**
 * Befriend the FastSAX_libxmlParser class to allow it to instantiate this class.
 */
friend class FastSAX_libxmlParser;

/**
 * Befriend the @ref libxmlSetDocumentLocator() function to allow it to supply
 * this instance with a libxml locator structure (xmlSAXLocatorPtr).
 */
friend void libxmlSetDocumentLocator(void *, xmlSAXLocatorPtr);

protected:
  /**
   * A pointer to a structure containing function pointers to the functions to
   * use for retrieving document location information when handling a libxml
   * SAX event.
   */
  xmlSAXLocatorPtr _locator;

  /**
   * A pointer to libxml's parser context, needed by libxml's locator functions.
   */
  xmlParserCtxtPtr _context;

  /**//************************************************************************
   * Constructor.
   *
   * By default, the libxml locator is set to xmlDefaultSAXLocator.  This can
   * be overridden in @ref FastSAX_libxmlParser instances by accessing and
   * setting the @ref _locator member directly.
   *///************************************************************************  
  FastSAX_libxmlLocator();

  /**//************************************************************************
   * Empty destructor.
   *///************************************************************************  
  virtual ~FastSAX_libxmlLocator();

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
  virtual const char * getPublicId() const;

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
  virtual const char * getSystemId() const;

  /**//************************************************************************
   * Return the line number where the current document event ends.  Note that
   * this is the line position of the first character after the text associated
   * with the document event.
   *
   * @see getColumnNumber()
   *
   * @return The line number, or -1 if none is available.
   *///************************************************************************
  virtual int getLineNumber() const;

  /**//************************************************************************
   * Return the column numver where the current document event ends.  Note that
   * this is the column number of the first character after the text associated
   * with the document event.  The first column in a line is position 1.
   *
   * @see getLineNumber()
   *
   * @return The column number, or -1 if none is available.
   *///************************************************************************
  virtual int getColumnNumber() const;
};


#endif

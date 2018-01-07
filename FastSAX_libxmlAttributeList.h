#ifndef _FASTSAX_LIBXMLATTRIBUTELIST_H
#define _FASTSAX_LIBXMLATTRIBUTELIST_H
/******************************************************************************
 * FastSAX_libxmlAttributeList.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 *
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_libxmlAttributeList.h,v 1.2 2001/02/13 11:45:13 ablehr Exp $
 * $Log: FastSAX_libxmlAttributeList.h,v $
 * Revision 1.2  2001/02/13 11:45:13  ablehr
 * - kdoc documentation complete (run `make doc').
 * - Consolidation complete.
 *
 ******************************************************************************/

extern "C" {
#include <gnome-xml/parser.h>
}

#include "FastSAX_AttributeListImpl.h"


/**//**************************************************************************
 * Provide a @ref FastSAX_IAttributeList implementation that handles attributes
 * as provided by the SAX emulation in libxml.
 *
 * This class will only be instantiated by @ref FastSAX_libxmlParser instances;
 * SAX application writers should never have to and are not able to instantiate
 * this class.
 *
 * This class extends the @ref FastSAX_AttributeListImpl helper class.
 *
 * @see FastSAX_IAttributeList
 * @see FastSAX_AttributeListImpl
 * @see FastSAX_libxmlParser
 *
 * @author  Anders Blehr
 * @version $Id: FastSAX_libxmlAttributeList.h,v 1.2 2001/02/13 11:45:13 ablehr Exp $
 *///**************************************************************************
class FastSAX_libxmlAttributeList : public FastSAX_AttributeListImpl
{
/**
 * Befriend the FastSAX_libxmlParser class to allow it to instantiate this class.
 */
friend class FastSAX_libxmlParser;

/**
 * Befriend the @ref libxmlStartElement() function to allow the attribute list
 * to be set whenever libxml reports a @ref startElement() event.
 */
friend void libxmlStartElement(void *, const xmlChar *, const xmlChar **);

protected:
  /**//************************************************************************
   * Default constructor.  Does nothing but invoke the constructor of the @ref
   * FastSAX_AttributeListImpl base class.
   *///************************************************************************
  FastSAX_libxmlAttributeList();

  /**//************************************************************************
   * Empty destructor.
   *///************************************************************************
  virtual ~FastSAX_libxmlAttributeList();

  /**//************************************************************************
   * Set the attribute list, discarding previous content.
   *
   * This method creates a @ref FastSAX_AttributeListImpl attribute list from a
   * libxml attributeList.  
   *
   * @see setAttributeList(FastSAX_IAttributeList *)
   *
   * @param attributeList The attribute list as an array of pointers.
   *///************************************************************************
  void setAttributeList(const xmlChar ** attributeList);
};

#endif

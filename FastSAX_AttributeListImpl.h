#ifndef _FASTSAX_ATTRIBUTELISTIMPL_H
#define _FASTSAX_ATTRIBUTELISTIMPL_H
/******************************************************************************
 * FastSAX_AttributeListImpl.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 *
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_AttributeListImpl.h,v 1.1 2001/02/13 11:45:13 ablehr Exp $
 * $Log: FastSAX_AttributeListImpl.h,v $
 * Revision 1.1  2001/02/13 11:45:13  ablehr
 * - kdoc documentation complete (run `make doc').
 * - Consolidation complete.
 *
 ******************************************************************************/

#include <fastlib/util/string.h>
#include <fastlib/util/dlist.h>

#include "FastSAX_IAttributeList.h"


/**//**************************************************************************
 * Trivial class representing an XML attribute.  All members are public (i.e.,
 * no access methods).
 *///**************************************************************************
class FastSAX_Attribute
{
public:
  /**
   * The name of the attribute.
   */
  Fast_String _name;

  /**
   * The type of the attribute.
   */
  Fast_String _type;

  /**
   * The value of the attribute.
   */
  Fast_String _value;

  /**//************************************************************************
   * Empty default constructor.
   *///************************************************************************
  FastSAX_Attribute() {}

  /**//************************************************************************
   * Empty destructor.
   *///************************************************************************
  ~FastSAX_Attribute() {}
};


/**//**************************************************************************
 * [Most or all of this documentation is copied from David Megginson's official
 * SAX1 for Java release; cf. http://www.megginson.com/SAX/.]
 *
 * Convenience implementation for @ref FastSAX_IAttributeList.
 *
 * This class provides a convenience implementation of the @ref
 * FastSAX_IAttributeList interface.  The implementation is useful both for
 * SAX parser writers, who can use it to provide attributes to the application,
 * and for SAX application writers, who can use it to create a persistent copy
 * of an element's attribute specifications:
 *
 * <pre>
 * void
 * Fast_SAXApplication::startElement(const char *             name,
 *                                   FastSAX_IAttributeList * attributeList)
 * {
 *   // Create persistent copy of attribute list for use outside this method
 *   _attributeList = new FastSAX_AttributeListImpl(attributeList);
 *
 *   [...]
 * }
 * </pre>
 *
 * Please note that SAX parsers are not required to use this class to provide
 * an implementation of @ref FastSAX_IAttributeList; it is supplied only as an
 * optional convenience.  In particular, parser writers are encouraged to
 * invent more efficient implementations.
 *
 * @author  Anders Blehr
 * @version $Id: FastSAX_AttributeListImpl.h,v 1.1 2001/02/13 11:45:13 ablehr Exp $
 *///**************************************************************************
class FastSAX_AttributeListImpl : public FastSAX_IAttributeList
{
protected:
  /**
   * The attribute list implemented as a doubly linked list.
   */
  Fast_DList * _attributeList;

  /**
   * The last accessed element (attribute) in the attribute list.
   */
  Fast_DListElement * _element;

  /**//************************************************************************
   * [This method is internal and not in the official SAX1 for Java release.]
   *
   * Retrieve an attribute by position.
   *
   * @see FastSAX_Attribute
   * @see getAttribute(const char *)
   *
   * @return The attribute, or NULL if there is not attribute at that position.
   *
   * @param position The position of the attribute in the list.
   *///************************************************************************
  FastSAX_Attribute * getAttribute(int position);

  /**//************************************************************************
   * [This method is internal and not in the official SAX1 for Java release.]
   *
   * Retrieve an attribute by name.
   *
   * @see FastSAX_Attribute
   * @see getAttribute(int)
   *
   * @return The attribute, or NULL if there is not attribute by that name.
   *
   * @param name The attribute name.
   *///************************************************************************
  FastSAX_Attribute * getAttribute(const char * name);

public:
  /**//************************************************************************
   * Create an empty attribute list.
   *
   * This constructor is most useful for parser writers, who will use it to
   * create a single, reusable attribute list that can be reset with the @ref
   * clear() method between elements.
   *
   * @see addAttribute()
   * @see clear()
   *///************************************************************************
  FastSAX_AttributeListImpl();

  /**//************************************************************************
   * Construct a persistent copy of an existing attribute list.
   *
   * This constructor is most useful for application writers, who will use it
   * to create a persistent copy of an existing attribute list.
   *
   * @see startElement()
   *
   * @param attributeList The attribute list to copy.
   *///************************************************************************
  FastSAX_AttributeListImpl(FastSAX_IAttributeList * attributeList);

  /**//************************************************************************
   * Destructor.  Deletes the @ref _attributeList member variable.
   *///************************************************************************
  virtual ~FastSAX_AttributeListImpl();

  /**//************************************************************************
   * Return the number of attributes in the list.
   *
   * @return The number of attributes in the list.
   *///************************************************************************
  virtual int getLength() const;

  /**//************************************************************************
   * Get the name of an attribute (by position).
   *
   * @return The attribute name as a string, or NULL if there is no attribute
   *         at that position.
   *
   * @see getName(const char *)
   *
   * @param position The position of the attribute in the list.
   *///************************************************************************
  virtual const char * getName(int position);

  /**//************************************************************************
   * Get the type of an attribute (by position).
   *
   * @see getType(const char *)
   *
   * @return The attribute type as a string ("NMTOKEN" for an enumeration, and
   *         "CDATA" if no declaration was read), or NULL of there is no
   *         attribute at that position.
   *
   * @param position The position of the attribute in the list.
   *///************************************************************************
  virtual const char * getType(int position);

  /**//************************************************************************
   * Get the value of an attribute (by position).
   *
   * @see getValue(const char *)
   *
   * @return The attribute value as a string, or NULL if there is no attribute
   *         at that position.
   *
   * @param position The position of the attribute in the list.
   *///************************************************************************
  virtual const char * getValue(int position);

  /**//************************************************************************
   * Get the type of an attribute (by name).
   *
   * @see getType(int)
   *
   * @return The attribute type as a string ("NMTOKEN" for enumeration, and
   *         "CDATA" if no declaration was read).
   *
   * @param name The attribute name.
   *///************************************************************************
  virtual const char * getType(const char * name);

  /**//************************************************************************
   * Get the value of an attribute (by name).
   *
   * @see getValue(int)
   *
   * @return The attribute value as a string.
   *
   * @param name The attribute name.
   *///************************************************************************
  virtual const char * getValue(const char * name);

  /**//************************************************************************
   * Set the attribute list, discarding previous content.
   *
   * This method allows an application writer to reuse an attribute list
   * easily.
   *
   * @param attributeList The attribute list to copy.
   *///************************************************************************
   void setAttributeList(FastSAX_IAttributeList * attributeList);

  /**//************************************************************************
   * Add an attribute to an attribute list.
   *
   * This method is provided for SAX parser writers, to allow them to build up
   * an attribute list incrementally before delivering it to the application.
   *
   * @see removeAttribute()
   * @see startElement()
   *
   * @param name  The attribute name.
   * @param type  The attribute type ("NMTOKEN" for an enumeration).
   * @param value The attribute value (must not be NULL).
   *///************************************************************************
  void addAttribute(const char * name,
                    const char * type,
                    const char * value);

  /**//************************************************************************
   * Remove an attribute from the list.
   *
   * SAX application writers can use this method to filter attributes out of an
   * attribute list.  Note that invoking thos method will change the length of
   * the attribute list and some of the attribute's indices.
   *
   * If the requested attribute is not in the list, this is a no-op.
   *
   * @param name The attribute name.
   *///************************************************************************
  void removeAttribute(const char * name);

  /**//************************************************************************
   * Clear the attribute list.
   *
   * SAX parser writers can use this method to reset the attribute list between
   * @ref startElement() events.  Normally, it will make sense to reuse the
   * same FastSAX_AttributeListImpl object rather than allocation a new one
   * each time.
   *
   * @see startElement()
   *///************************************************************************
  void clear();
};


#endif

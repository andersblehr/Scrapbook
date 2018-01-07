#ifndef _FASTSAX_IATTRIBUTELIST_H
#define _FASTSAX_IATTRIBUTELIST_H
/******************************************************************************
 * FastSAX_IAttributeList.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 *
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_IAttributeList.h,v 1.4 2001/02/13 11:45:13 ablehr Exp $
 * $Log: FastSAX_IAttributeList.h,v $
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

/**//**************************************************************************
 * [Most or all of this documentation is copied from David Megginson's official
 * SAX1 for Java release; cf. http://www.megginson.com/SAX/.]
 * 
 * Interface for an element's atribute specifications.
 *
 * When an attribute list is supplied as part of a @ref startElement event,
 * the list will return valid results only during the scope of the event;
 * once the event handler returns control to the parser, the attribute list is
 * invalid.  To save a persistent copy of the attribute list, use the SAX1
 * @ref FastSAX_AttributeListImpl helper class.
 *
 * An attribute list includes only attributes that have been specified or
 * defaulted: #IMPLIED attributes will not be included.
 *
 * There are two ways for the SAX application to obtain information from the
 * FastSAX_IAttributeList.  First, it can iterate through the entire list:
 *
 * <pre>
 * void
 * Fast_SAXApplication::startElement(const char *             name,
 *                                   FastSAX_IAttributeList * attributeList)
 * {
 *   int         i;
 *   Fast_String name;
 *   Fast_String type;
 *   Fast_String value;
 *
 *   for (i = 0; i < attributeList->getLength(); i++)
 *   {
 *     name = attributeList->getName(i);
 *     type = attributeList->getType(i);
 *     value = attributeList->getValue(i);
 *     [...]
 *   }
 * )
 * </pre>
 *
 * (Note that the result of getLenght() will be zero if there are no
 * attributes.)
 *
 * As an alternative, the application can request the value or type of
 * specific attributes:
 *
 * <pre>
 * void
 * Fast_SAXApplication::startElement(const char *             name,
 *                                   FastSAX_IAttributeList * attributeList)
 * {
 *   Fast_String id;
 *   Fast_String label;
 *
 *   id = attributeList->getValue("id");
 *   label = attributeList->getValue("label");
 *   [...]
 * }
 * </pre>
 *
 * @see startElement()
 * @see FastSAX_AttributeListImpl
 *
 * @author  Anders Blehr
 * @version $Id: FastSAX_IAttributeList.h,v 1.4 2001/02/13 11:45:13 ablehr Exp $
 *///**************************************************************************
class FastSAX_IAttributeList
{
public:
  /**//************************************************************************
   * Return the number of attributes in this list.
   *
   * The SAX parser may provide attributes in any arbitrary order, regardless
   * of the order in which they were declared or specified.  The number of
   * attributes may be zero.
   *
   * @return The number of attributes in the list.
   *///************************************************************************
  virtual int getLength() const = 0;

  /**//************************************************************************
   * Return the name of an attribute in this list (by position).
   *
   * The names must be unique: the SAX parser shall not include the same
   * attribute twice.  Attributes without values (those declared #IMPLIED
   * without a value specified in the start tag) will be omitted from the list.
   *
   * If the attribute name has a namespace prefix, the prefix will still be
   * attached.
   *
   * @see getLength()
   *
   * @return The name of the indexed attribute, or NULL if the index is out of
   *         range.
   *
   * @param position The index of the attribute in the list (start at 0).
   *///************************************************************************
  virtual const char * getName(int position) = 0;

  /**//************************************************************************
   * Return the type of an attribute in the list (by position).
   *
   * The attribute type is one of the strings "CDATA", "ID", "IDREF", "IDREFS",
   * "NMTOKEN", "NMTOKENS", "ENTITY", "ENTITIES", or "NOTATION" (always in
   * upper case).
   *
   * If the parser has not read a declaration for the attribute, or if the
   * parser does not report attribute types, then it must return the value
   * "CDATA" as stated in the XML 1.0 Recommendation (clause 3.3.3,
   * "Attribute-Value Normalization").
   *
   * For an enumerated attribute that is not a notation, the parser will report
   * the type as "NMTOKEN".
   *
   * @see getLength()
   * @see getType(const char *)
   *
   * @return The attribute type as a string, or NULL of the index is out of
   *         range.
   *
   * @param position The index of the attribute in the list (start at 0).
   *///************************************************************************
  virtual const char * getType(int position) = 0;

  /**//************************************************************************
   * Return the value of an attribute in the list (by position).
   *
   * If the attribute value is a list of tokens (IDREFS, ENTITIES, or NMTOKENS),
   * the tokens will be concatenated into a single string separated by
   * whitespace.
   *
   * @see getLength()
   * @see getValue(const char *)
   *
   * @return The attribute value as a string, or NULL of the index is out of
   *         range.
   *
   * @param position The index of the attribute in the list (start at 0).
   *///************************************************************************
  virtual const char * getValue(int position) = 0;

  /**//************************************************************************
   * Return the type of an attribute in the list (by name).
   *
   * The return value is the same as the return value for getType(int).
   *
   * If the attribute has a namespace prefix in the document, the application
   * must include the prefix here.
   *
   * @see getType(int)
   *
   * @return The attribute type as a string, or NULL if no such attribute
   *         exists.
   *
   * @param name The name of the attribute.
   *///************************************************************************
  virtual const char * getType(const char * name) = 0;

  /**//************************************************************************
   * Return the value of an attribute in the list (by name).
   *
   * The return value is the same as the return value for getValue(int).
   *
   * If the attribute has a namespace prefix in the document, the application
   * must include the prefix here.
   *
   * @see getType(int)
   *
   * @return The attribute value as a string, or NULL if no such attribute
   *         exists.
   *
   * @param name The name of the attribute.
   *///************************************************************************
  virtual const char * getValue(const char * name) = 0;
};


#endif

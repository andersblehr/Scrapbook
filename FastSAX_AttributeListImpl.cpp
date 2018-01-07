/*****************************************************************************
 * FastSAX_InputSource.cpp
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_AttributeListImpl.cpp,v 1.1 2001/02/13 11:45:13 ablehr Exp $
 * $Log: FastSAX_AttributeListImpl.cpp,v $
 * Revision 1.1  2001/02/13 11:45:13  ablehr
 * - kdoc documentation complete (run `make doc').
 * - Consolidation complete.
 *
 *****************************************************************************/

#include "FastSAX_AttributeListImpl.h"


/*****************************************************************************
 ******* > >  P R O T E C T E D   M E M B E R   F U N C T I O N S  < < *******
 *****************************************************************************/

/*****************************************************************************
 * getAttributeList -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_Attribute *
FastSAX_AttributeListImpl::getAttribute(int position)
{
  int                 length = getLength();
  int                 i;
  FastSAX_Attribute * attribute = NULL;

  /* Only look up attribute if position is within bounds */
  if (position <= length - 1)
  {
    /* Get the last element if position is last in list */
    if (position == length - 1)
      _element = _attributeList->GetTail();
    else
    {
      /* Get the first element in the list ... */
      _element = _attributeList->GetHead();

      /* ... and move forward to the indicated position */
      for (i = 0; i < position; i++)
        _element = _element->GetNext();
    }

    /* Retrieve the attribute from the Fast_DListElement's _data member */
    attribute = (FastSAX_Attribute *)_element->_data;
  }

  /* Return the attribute, or NULL if position was out of bounds */
  return attribute;
}


/*****************************************************************************
 * getAttributeList -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_Attribute *
FastSAX_AttributeListImpl::getAttribute(const char * name)
{
  int                 length = getLength();
  FastSAX_Attribute * attribute = NULL;
  bool                nameFound = false;
  int                 elementsChecked = 0;

  /* Only do something if there are elements in the list */
  if (length > 0)
  {
    /* Start with the first element in the list */
    _element = _attributeList->GetHead();
    nameFound = (((FastSAX_Attribute *)_element->_data)->_name == name);

    /* Iterate while attribute not found and more elements in list */
    while ((!nameFound) && (++elementsChecked < length))
    {
      _element = _element->GetNext();
      nameFound = (((FastSAX_Attribute *)_element->_data)->_name == name);
    }
  }

  /* Retrieve the attribute from the list element if the attribute was found */
  if (nameFound)
    attribute = (FastSAX_Attribute *)_element->_data;

  /* Return the attribute, or NULL if none was found */
  return attribute;
}


/*****************************************************************************
 ********** > >  P U B L I C   M E M B E R   F U N C T I O N S  < < **********
 *****************************************************************************/

/*****************************************************************************
 * FastSAX_AttributeListImpl -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_AttributeListImpl::FastSAX_AttributeListImpl()
{
  /* Create the doubly linked attribute list and set the current element to 0 */
  _attributeList = new Fast_DList();
  _element = NULL;
}


/*****************************************************************************
 * FastSAX_AttributeListImpl -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_AttributeListImpl::FastSAX_AttributeListImpl(FastSAX_IAttributeList *
                                                       attributeList)
{
  /* Create the doubly linked attribute list and set the current element to 0 */
  _attributeList = new Fast_DList();
  _element = NULL;

  /* Make this list be a copy of the supplied attribute list */
  setAttributeList(attributeList);
}


/*****************************************************************************
 * ~FastSAX_AttributeListImpl -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_AttributeListImpl::~FastSAX_AttributeListImpl()
{
  /* Delete the attribute list */
  delete _attributeList;
}


/*****************************************************************************
 * getLength -- Cf. header file for function description.
 *****************************************************************************/
int
FastSAX_AttributeListImpl::getLength() const
{
  /* Use the Fast_DList::GetListLength() method */
  return _attributeList->GetListLength();
}


/*****************************************************************************
 * getName -- Cf. header file for function description.
 *****************************************************************************/
const char *
FastSAX_AttributeListImpl::getName(int position)
{
  const char *        name = NULL;
  FastSAX_Attribute * attribute = getAttribute(position);

  /* Retrieve attribute name from looked up list element if not NULL */
  if (attribute != NULL)
    name = attribute->_name.CString();

  /* Return the attribute name, or NULL if position was out of bounds */
  return name;
}


/*****************************************************************************
 * getType -- Cf. header file for function description.
 *****************************************************************************/
const char *
FastSAX_AttributeListImpl::getType(int position)
{
  const char *        type = NULL;
  FastSAX_Attribute * attribute = getAttribute(position);

  /* Retrieve attribute type from looked up list element if not NULL */
  if (attribute != NULL)
    type = attribute->_type.CString();

  /* Return the attribute type, or NULL if position was out of bounds */
  return type;
}


/*****************************************************************************
 * getValue -- Cf. header file for function description.
 *****************************************************************************/
const char *
FastSAX_AttributeListImpl::getValue(int position)
{
  const char *        value = NULL;
  FastSAX_Attribute * attribute = getAttribute(position);

  /* Retrieve attribute value from looked up list element if not NULL */
  if (attribute != NULL)
    value = attribute->_value.CString();

  /* Return the attribute value, or NULL if position was out of bounds */
  return value;
}


/*****************************************************************************
 * getType -- Cf. header file for function description.
 *****************************************************************************/
const char *
FastSAX_AttributeListImpl::getType(const char * name)
{
  const char *        type = NULL;
  FastSAX_Attribute * attribute = getAttribute(name);

  /* Retrieve attribute type from looked up list element if not NULL */
  if (attribute != NULL)
    type = attribute->_type.CString();

  /* Return the attribute type, or NULL if position was out of bounds */
  return type;
}


/*****************************************************************************
 * getValue -- Cf. header file for function description.
 *****************************************************************************/
const char *
FastSAX_AttributeListImpl::getValue(const char * name)
{
  const char *        value = NULL;
  FastSAX_Attribute * attribute = getAttribute(name);

  /* Retrieve attribute value from looked up list element if not NULL */
  if (attribute != NULL)
    value = attribute->_value.CString();

  /* Return the attribute value, or NULL if position was out of bounds */
  return value;
}


/*****************************************************************************
 * setAttributeList -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_AttributeListImpl::setAttributeList(FastSAX_IAttributeList *
                                              attributeList)
{
  int i;

  /* Clear the old contents of the attribute list before doing anything else */
  clear();

  /* For each element in the list, add it to this list */
  for (i = 0; i < attributeList->getLength(); i++)
    addAttribute(attributeList->getName(i),
                 attributeList->getType(i),
                 attributeList->getValue(i));
}


/*****************************************************************************
 * addAttribute -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_AttributeListImpl::addAttribute(const char * name,
                                        const char * type,
                                        const char * value)
{
  /* Only add the attribute if it's not already in the list */
  if (getValue(name) == NULL)
  {
    /* Create new list element and attribute instances */
    Fast_DListElement * element = new Fast_DListElement();
    FastSAX_Attribute * attribute = new FastSAX_Attribute();
    
    /* Set the attribute member variables */
    attribute->_name = name;
    attribute->_type = type;
    attribute->_value = value;
    
    /* Have the list element's _data member point to the attribute instance */
    element->_data = attribute;
    
    /* Add the new attribute to the end of the attribute list */
    _attributeList->AddTail(element);
  }
}


/*****************************************************************************
 * removeAttribute -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_AttributeListImpl::removeAttribute(const char * name)
{
  /* Only do something if the attribute can be found in the list */
  if (getValue(name) != NULL)
  {
    /* If the attribute was found, _element points to the element in question */
    _attributeList->RemoveElement(_element);

    /* Delete the element and set the _element pointer to NULL */
    delete _element;
    _element = NULL;
  }
}


/*****************************************************************************
 * clear -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_AttributeListImpl::clear()
{
  /* Free up the memory occupied by the attribute list */
  _attributeList->FreeList();
}

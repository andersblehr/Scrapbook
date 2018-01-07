/******************************************************************************
 * FastS_XMLMapping.cpp
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastS_XMLMappingList.cpp,v 1.2 2001/02/19 14:04:56 ablehr Exp $
 * $Log: FastS_XMLMappingList.cpp,v $
 * Revision 1.2  2001/02/19 14:04:56  ablehr
 * - kdoc documentation complete.  Run `make doc'.
 * - Released as 1.0.
 *
 ******************************************************************************/

#include "FastS_XMLMappingList.h"


/*****************************************************************************
 ********** > >  P U B L I C   M E M B E R   F U N C T I O N S  < < **********
 *****************************************************************************/

/*****************************************************************************
 * FastS_XMLMappingList -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLMappingList::FastS_XMLMappingList() :
    Fast_DList()
{
  /* Create a list enumerator that enumerates this list */
  _mappingEnumerator = new Fast_DListEnumerator(*this);
}


/*****************************************************************************
 * ~FastS_XMLMappingList -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLMappingList::~FastS_XMLMappingList()
{
  Fast_DListElement * element;

  /* Reset the list enumerator */
  _mappingEnumerator->Reset();

  /* Set mapping pointers to NULL to avoid deleting them when deleting list */
  element = (Fast_DListElement *)_mappingEnumerator->GetNext();

  while (element != NULL)
  {
    element->_data = NULL;
    element = (Fast_DListElement *)_mappingEnumerator->GetNext();
  }

  /* Delete the enumerator and free the memory occupied by the list */
  delete _mappingEnumerator;

  FreeList();
}


/*****************************************************************************
 * add -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLMappingList::add(FastS_XMLMapping * mapping)
{
  Fast_DListElement * element = new Fast_DListElement();

  /* Add the mapping to the list */
  element->_data = (void *)mapping;

  AddTail(element);
}


/*****************************************************************************
 * getFirst -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLMapping *
FastS_XMLMappingList::getFirst()
{
  /* Reset enumerator before returning next mapping */
  _mappingEnumerator->Reset();

  return getNext();
}


/*****************************************************************************
 * getNext -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLMapping *
FastS_XMLMappingList::getNext()
{
  /* Return mapping pointer from next list element, or NULL if none */
  Fast_DListElement * element =
    (Fast_DListElement *)_mappingEnumerator->GetNext();

  return element ? (FastS_XMLMapping *)element->_data : NULL;
}


/*****************************************************************************
 * getLength -- Cf. header file for function description.
 *****************************************************************************/
int
FastS_XMLMappingList::getLength()
{
  return GetListLength();
}

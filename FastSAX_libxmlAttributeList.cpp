/*****************************************************************************
 * FastSAX_libxmlAttributeList.cpp
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_libxmlAttributeList.cpp,v 1.2 2001/02/13 11:45:13 ablehr Exp $
 * $Log: FastSAX_libxmlAttributeList.cpp,v $
 * Revision 1.2  2001/02/13 11:45:13  ablehr
 * - kdoc documentation complete (run `make doc').
 * - Consolidation complete.
 *
 *****************************************************************************/

#include "FastSAX_libxmlAttributeList.h"


/*****************************************************************************
 ******* > >  P R O T E C T E D   M E M B E R   F U N C T I O N S  < < *******
 *****************************************************************************/

/*****************************************************************************
 * FastSAX_libxmlAttributeList -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_libxmlAttributeList::FastSAX_libxmlAttributeList() :
    FastSAX_AttributeListImpl()
{
}


/*****************************************************************************
 * ~FastSAX_libxmlAttributeList -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_libxmlAttributeList::~FastSAX_libxmlAttributeList()
{
}


/*****************************************************************************
 * setAttributeList -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_libxmlAttributeList::setAttributeList(const xmlChar ** attributeList)
{
  /* Clear the old contents of the attribute list before doing anything else */
  clear();

  /* Only do something if there is data in the attribute list (i.e., array) */
  if (attributeList != NULL)
  {
    /* Add each attribute in the array to this list */
    while (attributeList[0] != NULL)
    {
      /* Attribute type is not supplied by libxml, default to "CDATA" */
      addAttribute((const char *)attributeList[0], "CDATA",
                   (const char *)attributeList[1]          );

      /* Jump to next attribute in array */
      attributeList += 2;
    }
  }
}

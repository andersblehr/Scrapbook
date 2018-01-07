#ifndef _FASTS_XMLMAPPINGLIST_H
#define _FASTS_XMLMAPPINGLIST_H
/*****************************************************************************
 * FastS_XMLMappingList.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastS_XMLMappingList.h,v 1.3 2001/02/19 14:04:56 ablehr Exp $
 * $Log: FastS_XMLMappingList.h,v $
 * Revision 1.3  2001/02/19 14:04:56  ablehr
 * - kdoc documentation complete.  Run `make doc'.
 * - Released as 1.0.
 *
 * Revision 1.2  2001/02/15 14:10:54  ablehr
 * - Bugfix
 *
 *****************************************************************************/

#include <fastlib/util/dlist.h>

#include "FastS_XMLMapping.h"


/**//*************************************************************************
 * Provide a list of mappings.
 *
 * This class is a specialization of the Fast_DList class tailored to
 * maintaining a list of @ref FastS_XMLMapping instances, and providing
 * methods for traversing the list without the use of extra enumerator classes.
 *
 * The class is used both by the @ref FastS_XMLMappingManager and the @ref
 * FastS_XMLState classes.  The former builds a list of all mappings in the
 * mapping file that may apply to an element in the data file, whereas the
 * latter builds a list of the subset of these mappings that actually do apply
 * to a given occurrence of the element.
 *
 * @see FastS_XMLMapping
 * @see FastS_XMLMappingManager
 * @see FastS_XMLState
 * @see Fast_DList
 * @see Fast_DListEnumerator
 *
 * @author  Anders Blehr
 * @version $Id: FastS_XMLMappingList.h,v 1.3 2001/02/19 14:04:56 ablehr Exp $
 *///*************************************************************************
class FastS_XMLMappingList : protected Fast_DList
{
protected:
  /**
   * Enumerator used for traversing the list of mappings.
   */
  Fast_DListEnumerator * _mappingEnumerator;

public:
  /**//************************************************************************
   * Constructor.  Initialize the list and the list enumerator.
   *///************************************************************************  
  FastS_XMLMappingList();

  /**//************************************************************************
   * Destructor.
   *///************************************************************************  
  virtual ~FastS_XMLMappingList();

  /**//************************************************************************
   * Add a mapping to the list.
   *
   * @param mapping The mapping to be added to the list.
   *///************************************************************************  
  void add(FastS_XMLMapping * mapping);

  /**//************************************************************************
   * Obtain a pointer to the first mapping in the list.
   *
   * @return A pointer to the first mapping in the list, or NULL if the list is
   *         empty.
   *///************************************************************************  
  FastS_XMLMapping * getFirst();

  /**//************************************************************************
   * Obtain a pointer to the next mapping in the list.
   *
   * @return A pointer to the next mapping in the list, or NULL if there are no
   *         more mappings.
   *///************************************************************************  
  FastS_XMLMapping * getNext();

  /**//************************************************************************
   * Return the number of mappings in the list.
   *
   * @return The number of mappings in the list.
   *///************************************************************************  
  int getLength();
};


#endif

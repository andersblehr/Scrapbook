#ifndef _FASTS_XMLSTATE_H
#define _FASTS_XMLSTATE_H
/*****************************************************************************
 * FastS_XMLState.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastS_XMLState.h,v 1.2 2001/02/19 14:04:56 ablehr Exp $
 * $Log: FastS_XMLState.h,v $
 * Revision 1.2  2001/02/19 14:04:56  ablehr
 * - kdoc documentation complete.  Run `make doc'.
 * - Released as 1.0.
 *
 *****************************************************************************/

#include <fastlib/util/string.h>
#include <fastlib/util/dlist.h>

#include "FastS_XMLMappingList.h"


#define _C_XMLSTATE_ROOT       0
#define _C_XMLSTATE_DELIM      1
#define _C_XMLSTATE_ELEMENT    2
#define _C_XMLSTATE_ATTRIBUTE  3


/**//*************************************************************************
 * Manage the mappings associated with a state, and keep track of whether the
 * state is associated with the document delimiter, and/or is tokenizable.
 *
 * A state is created for each new element encountered in the data file, and
 * for each attribute of the element that is mapped individually.  Once the
 * element (or the attribute) has been indexed, the state is deleted by the
 * @ref FastS_XMLStateManager.
 *
 * The state maintains a list of mappings that actually apply to this specific
 * occurrence of the element, as opposed to the mapping list maintained by @ref
 * FastS_XMLMapping, which contains all mappings that may apply to the element.
 *
 * The class inherits the Fast_DListElement; the reason for this, is that the
 * stack functionality in @ref FastS_XMLStateStack is implemented as a 
 * Fast_DList.
 *
 * @see FastS_XMLStateManager
 * @see FastS_XMLStateStack
 * @see FastS_XMLMappingList
 * @see FastS_XMLMapping
 *
 * @author  Anders Blehr
 * @version $Id: FastS_XMLState.h,v 1.2 2001/02/19 14:04:56 ablehr Exp $
 *///*************************************************************************
class FastS_XMLState : public Fast_DListElement
{
protected:
  /**
   * The name of the element associated with the state.
   */
  Fast_String _element;

  /**
   * The list of mappings that apply to this occurrence of the element.
   */
  FastS_XMLMappingList * _mappingList;

  /**
   * Integer representing the state type.
   */
  int _stateType;

public:
  /**//************************************************************************
   * Constructor.  Create a state with no associated element.
   *///************************************************************************  
  FastS_XMLState();

  /**//************************************************************************
   * Constructor.  Create a state with an associated element.
   *///************************************************************************  
  FastS_XMLState(const char * element);

  /**//************************************************************************
   * Constructor.  Create a state one and only one associated mapping.
   *///************************************************************************  
  FastS_XMLState(FastS_XMLMapping * mapping);

  /**//************************************************************************
   * Destructor.
   *///************************************************************************  
  virtual ~FastS_XMLState();

  /**//************************************************************************
   * Add a mapping to the list of mappings associated with the state.
   *
   * @param mapping The mapping to be added to the list.
   *///************************************************************************  
  void addMapping(FastS_XMLMapping * mapping);

  /**//************************************************************************
   * Return the name of the element associated with the state.
   *
   * @return The name of the element.
   *///************************************************************************  
  const char * getElement();

  /**//************************************************************************
   * Return the list of mappings associated with the state.
   *
   * @return The list of mappings associated with the state.
   *///************************************************************************  
  FastS_XMLMappingList * getMappings();

  /**//************************************************************************
   * Inform the state that the element associated with the state is the
   * document delimiter.
   *///************************************************************************  
  void makeDelimiter();

  /**//************************************************************************
   * Query whether the state has an associated element.
   *
   * @return true if the state has an associated element; false otherwise.
   *///************************************************************************  
  bool isElement();

  /**//************************************************************************
   * Query whether the element associated with the state is the document
   * delimiter.
   *
   * @return true if the element is the document delimiter; false otherwise.
   *///************************************************************************  
  bool isDelimiter();

  /**//************************************************************************
   * Query whether the state is tokenizable.  The state is tokenizable if the
   * list of mappings associated with the state contains one or more mappings.
   *
   * @return true if the state is tokenixable; false otherwise.
   *///************************************************************************  
  bool isTokenizable();
};


#endif

#ifndef _FASTS_XMLSTATESTACK_H
#define _FASTS_XMLSTATESTACK_H
/*****************************************************************************
 * FastS_XMLStateStack.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastS_XMLStateStack.h,v 1.2 2001/02/19 14:04:56 ablehr Exp $
 * $Log: FastS_XMLStateStack.h,v $
 * Revision 1.2  2001/02/19 14:04:56  ablehr
 * - kdoc documentation complete.  Run `make doc'.
 * - Released as 1.0.
 *
 *****************************************************************************/

#include <fastlib/util/dlist.h>

#include "FastS_XMLState.h"


/**//*************************************************************************
 * Maintain the state history as a stack.
 *
 * All states associated with elements enclosing the element associated with
 * the current state are kept in this stack.  When the current element ends,
 * the state associated with the enclosing state is popped from the stack and
 * made current by the @ref FastS_XMLStateManager.
 *
 * The stack is implemented using the Fast_DList class, which is why the @ref
 * FastS_XMLState class inherits from Fast_DListElement.
 *
 * @author  Anders Blehr
 * @version $Id: FastS_XMLStateStack.h,v 1.2 2001/02/19 14:04:56 ablehr Exp $
 *///*************************************************************************
class FastS_XMLStateStack
{
protected:
  /**
   * The list that implements the stack.
   */
  Fast_DList * _stackList;

public:
  /**//************************************************************************
   * Constructor.  Create the stack list.
   *///************************************************************************  
  FastS_XMLStateStack();

  /**//************************************************************************
   * Destructor.
   *///************************************************************************  
  virtual ~FastS_XMLStateStack();

  /**//************************************************************************
   * Push a state onto the stack.
   *
   * @param state The state to be pushed onto the stack.
   *///************************************************************************  
  void push(FastS_XMLState * state);

  /**//************************************************************************
   * Pop a state from the stack.
   *
   * @return The state popped from the stack.
   *///************************************************************************  
  FastS_XMLState * pop();

  /**//************************************************************************
   * Query if the stack is empty.
   *
   * @return true if the stack is empty; false otherwise.
   *///************************************************************************  
  bool isEmpty();

  /**//************************************************************************
   * Make the stack empty.
   *///************************************************************************  
  void makeEmpty();
};


#endif

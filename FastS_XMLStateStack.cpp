/******************************************************************************
 * FastS_XMLStateStack.cpp
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastS_XMLStateStack.cpp,v 1.2 2001/02/19 14:04:56 ablehr Exp $
 * $Log: FastS_XMLStateStack.cpp,v $
 * Revision 1.2  2001/02/19 14:04:56  ablehr
 * - kdoc documentation complete.  Run `make doc'.
 * - Released as 1.0.
 *
 ******************************************************************************/

#include "FastS_XMLStateStack.h"


/*****************************************************************************
 ********** > >  P U B L I C   M E M B E R   F U N C T I O N S  < < **********
 *****************************************************************************/

/*****************************************************************************
 * FastS_XMLStateStack -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLStateStack::FastS_XMLStateStack()
{
  /* Create the stack list */
  _stackList = new Fast_DList();
}


/*****************************************************************************
 * ~FastS_XMLStateStack -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLStateStack::~FastS_XMLStateStack()
{
  /* Free the stack list before deleting it */
  _stackList->FreeList();

  delete _stackList;
}


/*****************************************************************************
 * push -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLStateStack::push(FastS_XMLState * state)
{
  /* Only push non-NULL states onto the stack */
  if (state != NULL)
    _stackList->AddHead(state);
}


/*****************************************************************************
 * pop -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLState *
FastS_XMLStateStack::pop()
{
  return (FastS_XMLState *)_stackList->RemoveHead();
}


/*****************************************************************************
 * isEmpty -- Cf. header file for function description.
 *****************************************************************************/
bool
FastS_XMLStateStack::isEmpty()
{
  /* The stack is empty if the stack list has no elements */
  return (_stackList->GetListLength() == 0);
}


/*****************************************************************************
 * makeEmpty -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLStateStack::makeEmpty()
{
  _stackList->FreeList();
}

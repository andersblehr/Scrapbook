/******************************************************************************
 * FastS_XMLState.cpp
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastS_XMLState.cpp,v 1.2 2001/02/19 14:04:56 ablehr Exp $
 * $Log: FastS_XMLState.cpp,v $
 * Revision 1.2  2001/02/19 14:04:56  ablehr
 * - kdoc documentation complete.  Run `make doc'.
 * - Released as 1.0.
 *
 ******************************************************************************/

#include "FastS_XMLState.h"


/*****************************************************************************
 ********** > >  P U B L I C   M E M B E R   F U N C T I O N S  < < **********
 *****************************************************************************/

/*****************************************************************************
 * FastS_XMLState -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLState::FastS_XMLState()
{
  _mappingList = new FastS_XMLMappingList();
  _stateType = _C_XMLSTATE_ROOT;
}


/*****************************************************************************
 * FastS_XMLState -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLState::FastS_XMLState(const char * element)
{
  _element = element;
  _mappingList = new FastS_XMLMappingList();
  _stateType = _C_XMLSTATE_ELEMENT;
}


/*****************************************************************************
 * FastS_XMLState -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLState::FastS_XMLState(FastS_XMLMapping * mapping)
{
  _mappingList = new FastS_XMLMappingList();
  _mappingList->add(mapping);
  _stateType = _C_XMLSTATE_ATTRIBUTE;
}


/*****************************************************************************
 * ~FastS_XMLState -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLState::~FastS_XMLState()
{
  delete _mappingList;
}


/*****************************************************************************
 * addMapping -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLState::addMapping(FastS_XMLMapping * mapping)
{
  _mappingList->add(mapping);
}


/*****************************************************************************
 * getMappings -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLMappingList *
FastS_XMLState::getMappings()
{
  return _mappingList;
}


/*****************************************************************************
 * getElement -- Cf. header file for function description.
 *****************************************************************************/
const char *
FastS_XMLState::getElement()
{
  return (_element != "") ? _element.CString() : NULL;
}


/*****************************************************************************
 * makeDelimiter -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLState::makeDelimiter()
{
  _stateType = _C_XMLSTATE_DELIM;
}


/*****************************************************************************
 * isDelimiter -- Cf. header file for function description.
 *****************************************************************************/
bool
FastS_XMLState::isElement()
{
  return ((_stateType == _C_XMLSTATE_ELEMENT) ||
          (_stateType == _C_XMLSTATE_DELIM  )    );
}


/*****************************************************************************
 * isDelimiter -- Cf. header file for function description.
 *****************************************************************************/
bool
FastS_XMLState::isDelimiter()
{
  return (_stateType == _C_XMLSTATE_DELIM);
}


/*****************************************************************************
 * isTokenizable -- Cf. header file for function description.
 *****************************************************************************/
bool
FastS_XMLState::isTokenizable()
{
  return (isElement() && (_mappingList->getLength() > 0));
}

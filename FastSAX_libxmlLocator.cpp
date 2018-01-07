/*****************************************************************************
 * FastSAX_libxmlLocator.cpp
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_libxmlLocator.cpp,v 1.2 2001/02/13 11:45:13 ablehr Exp $
 * $Log: FastSAX_libxmlLocator.cpp,v $
 * Revision 1.2  2001/02/13 11:45:13  ablehr
 * - kdoc documentation complete (run `make doc').
 * - Consolidation complete.
 *
 *****************************************************************************/

#include "FastSAX_libxmlLocator.h"


/*****************************************************************************
 ******* > >  P R O T E C T E D   M E M B E R   F U N C T I O N S  < < *******
 *****************************************************************************/

/*****************************************************************************
 * FastSAX_libxmlLocator -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_libxmlLocator::FastSAX_libxmlLocator() :
    _locator(&xmlDefaultSAXLocator),
    _context(NULL)
{
}


/*****************************************************************************
 * ~FastSAX_libxmlLocator -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_libxmlLocator::~FastSAX_libxmlLocator()
{
}


/*****************************************************************************
 ********** > >  P U B L I C   M E M B E R   F U N C T I O N S  < < **********
 *****************************************************************************/

/*****************************************************************************
 * getPublicId -- Cf. header file for function description.
 *****************************************************************************/
const char *
FastSAX_libxmlLocator::getPublicId() const
{
  return (const char *)((_locator->getPublicId)(_context));
}


/*****************************************************************************
 * getSystemId -- Cf. header file for function description.
 *****************************************************************************/
const char *
FastSAX_libxmlLocator::getSystemId() const
{
  return (const char *)((_locator->getSystemId)(_context));
}


/*****************************************************************************
 * getLineNumber -- Cf. header file for function description.
 *****************************************************************************/
int
FastSAX_libxmlLocator::getLineNumber() const
{
  return (_locator->getLineNumber)(_context);
}


/*****************************************************************************
 * getColumnNumber -- Cf. header file for function description.
 *****************************************************************************/
int
FastSAX_libxmlLocator::getColumnNumber() const
{
  return (_locator->getColumnNumber)(_context);
}

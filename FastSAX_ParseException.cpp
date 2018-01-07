/*****************************************************************************
 * FastSAX_ParseException.cpp
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_ParseException.cpp,v 1.3 2001/02/09 12:07:48 ablehr Exp $
 * $Log: FastSAX_ParseException.cpp,v $
 * Revision 1.3  2001/02/09 12:07:48  ablehr
 * - Consolidated.
 *
 * Revision 1.2  2001/02/08 12:17:45  ablehr
 * - Added a few comments and made minor modifications.  A little closer to 1.0...
 *
 *****************************************************************************/

#include "FastSAX_ParseException.h"


/*****************************************************************************
 ********** > >  P U B L I C   M E M B E R   F U N C T I O N S  < < **********
 *****************************************************************************/

/*****************************************************************************
 * FastSAX_ParseException -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_ParseException::FastSAX_ParseException(const char *       message,
                                               FastSAX_ILocator * locator ) :
    FastSAX_Exception(message),
    _publicId(locator->getPublicId()),
    _systemId(locator->getSystemId()),
    _lineNumber(locator->getLineNumber()),
    _columnNumber(locator->getColumnNumber())
{
}


/*****************************************************************************
 * FastSAX_ParseException -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_ParseException::FastSAX_ParseException(const char *       message,
                                               FastSAX_ILocator * locator,
                                               Fast_Exception *   exception) :
    FastSAX_Exception(message, exception),
    _publicId(locator->getPublicId()),
    _systemId(locator->getSystemId()),
    _lineNumber(locator->getLineNumber()),
    _columnNumber(locator->getColumnNumber())
{
}


/*****************************************************************************
 * FastSAX_ParseException -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_ParseException::FastSAX_ParseException(const char * message,
                                               const char * publicId,
                                               const char * systemId,
                                               int          lineNumber,
                                               int          columnNumber) :
    FastSAX_Exception(message),
    _publicId(publicId),
    _systemId(systemId),
    _lineNumber(lineNumber),
    _columnNumber(columnNumber)
{
}


/*****************************************************************************
 * FastSAX_ParseException -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_ParseException::FastSAX_ParseException(const char *     message,
                                               const char *     publicId,
                                               const char *     systemId,
                                               int              lineNumber,
                                               int              columnNumber,
                                               Fast_Exception * exception) :
    FastSAX_Exception(message, exception),
    _publicId(publicId),
    _systemId(systemId),
    _lineNumber(lineNumber),
    _columnNumber(columnNumber)
{
}


/*****************************************************************************
 * ~FastSAX_ParseException -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_ParseException::~FastSAX_ParseException()
{
}


/*****************************************************************************
 * getPublicId -- Cf. header file for function description.
 *****************************************************************************/
const char *
FastSAX_ParseException::getPublicId()
{
  return _publicId.CString();
}


/*****************************************************************************
 * getSystemId -- Cf. header file for function description.
 *****************************************************************************/
const char *
FastSAX_ParseException::getSystemId()
{
  return _systemId.CString();
}


/*****************************************************************************
 * getLineNumber -- Cf. header file for function description.
 *****************************************************************************/
int
FastSAX_ParseException::getLineNumber()
{
  return _lineNumber;
}


/*****************************************************************************
 * getColumnNumber -- Cf. header file for function description.
 *****************************************************************************/
int
FastSAX_ParseException::getColumnNumber()
{
  return _columnNumber;
}

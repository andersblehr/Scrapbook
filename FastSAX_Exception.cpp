/*****************************************************************************
 * FastSAX_Exception.cpp
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_Exception.cpp,v 1.3 2001/02/09 12:07:47 ablehr Exp $
 * $Log: FastSAX_Exception.cpp,v $
 * Revision 1.3  2001/02/09 12:07:47  ablehr
 * - Consolidated.
 *
 * Revision 1.2  2001/02/08 12:17:44  ablehr
 * - Added a few comments and made minor modifications.  A little closer to 1.0...
 *
 *****************************************************************************/

#include "FastSAX_Exception.h"


/*****************************************************************************
 ********** > >  P U B L I C   M E M B E R   F U N C T I O N S  < < **********
 *****************************************************************************/

/*****************************************************************************
 * FastSAX_Exception -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_Exception::FastSAX_Exception(const char * message) :
    Fast_Exception(FLOG_ERROR, message),
    _exception(NULL)
{
}


/*****************************************************************************
 * FastSAX_Exception -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_Exception::FastSAX_Exception(Fast_Exception * exception) :
    Fast_Exception(FLOG_ERROR, exception->GetMessage()),
    _exception(exception)
{
}


/*****************************************************************************
 * FastSAX_Exception -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_Exception::FastSAX_Exception(const char *     message,
                                     Fast_Exception * exception) :
    Fast_Exception(FLOG_ERROR, message),
    _exception(exception)
{
}


/*****************************************************************************
 * ~FastSAX_Exception -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_Exception::~FastSAX_Exception()
{
}


/*****************************************************************************
 * getMessage -- Cf. header file for function description.
 *****************************************************************************/
const char *
FastSAX_Exception::getMessage()
{
  const char * message = GetMessage();

  if ((message == NULL) && (_exception != NULL))
    message = _exception->GetMessage();

  return message;
}


/*****************************************************************************
 * getException -- Cf. header file for function description.
 *****************************************************************************/
Fast_Exception *
FastSAX_Exception::getException()
{
  return _exception;
}

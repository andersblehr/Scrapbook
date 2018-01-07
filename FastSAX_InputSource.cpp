/*****************************************************************************
 * FastSAX_InputSource.cpp
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_InputSource.cpp,v 1.2 2001/02/09 12:07:47 ablehr Exp $
 * $Log: FastSAX_InputSource.cpp,v $
 * Revision 1.2  2001/02/09 12:07:47  ablehr
 * - Consolidated.
 *
 *****************************************************************************/

#include "FastSAX_InputSource.h"


/*****************************************************************************
 ********** > >  P U B L I C   M E M B E R   F U N C T I O N S  < < **********
 *****************************************************************************/

/*****************************************************************************
 * FastSAX_InputSource -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_InputSource::FastSAX_InputSource() :
    _byteStream(NULL)
{
}


/*****************************************************************************
 * FastSAX_InputSource -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_InputSource::FastSAX_InputSource(const char * systemId) :
    _byteStream(NULL),
    _systemId(systemId)
{
}


/*****************************************************************************
 * FastSAX_InputSource -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_InputSource::FastSAX_InputSource(std::istream * byteStream) :
    _byteStream(byteStream)
{
}


/*****************************************************************************
 * ~FastSAX_InputSource -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_InputSource::~FastSAX_InputSource()
{
}


/*****************************************************************************
 * setPublicId -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_InputSource::setPublicId(const char * publicId)
{
  _publicId = publicId;
}


/*****************************************************************************
 * getPublicId -- Cf. header file for function description.
 *****************************************************************************/
const char *
FastSAX_InputSource::getPublicId()
{
  /* Return NULL if the public identifier has not been set */
  return (_publicId != "") ? _publicId.CString() : NULL;
}


/*****************************************************************************
 * setSystemId -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_InputSource::setSystemId(const char * systemId)
{
  _systemId = systemId;
}


/*****************************************************************************
 * getSystemId -- Cf. header file for function description.
 *****************************************************************************/
const char *
FastSAX_InputSource::getSystemId()
{
  /* Return NULL if the system identifier has not been set */
  return (_systemId != "") ? _systemId.CString() : NULL;
}


/*****************************************************************************
 * setByteStream -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_InputSource::setByteStream(std::istream * byteStream)
{
  _byteStream = byteStream;
}


/*****************************************************************************
 * getByteStream -- Cf. header file for function description.
 *****************************************************************************/
std::istream *
FastSAX_InputSource::getByteStream()
{
  return _byteStream;
}


/*****************************************************************************
 * setEncoding -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_InputSource::setEncoding(const char * encoding)
{
  _encoding = encoding;
}


/*****************************************************************************
 * getEncoding -- Cf. header file for function description.
 *****************************************************************************/
const char *
FastSAX_InputSource::getEncoding()
{
  /* Return NULL if the encoding has not been set */
  return (_encoding != NULL) ? _encoding.CString() : NULL;
}

/*****************************************************************************
 * FastSAX_Exception.cpp
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_HandlerBase.cpp,v 1.3 2001/02/09 12:07:47 ablehr Exp $
 * $Log: FastSAX_HandlerBase.cpp,v $
 * Revision 1.3  2001/02/09 12:07:47  ablehr
 * - Consolidated.
 *
 * Revision 1.2  2001/02/08 12:17:44  ablehr
 * - Added a few comments and made minor modifications.  A little closer to 1.0...
 *
 *****************************************************************************/

#include "FastSAX_HandlerBase.h"


/*****************************************************************************
 ********** > >  P U B L I C   M E M B E R   F U N C T I O N S  < < **********
 *****************************************************************************/

/*****************************************************************************
 * FastSAX_HandlerBase -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_HandlerBase::FastSAX_HandlerBase()
{
  /* Initialize member veraibles */
  _locator = NULL;
}


/*****************************************************************************
 * ~FastSAX_HandlerBase -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_HandlerBase::~FastSAX_HandlerBase()
{
}


/*****************************************************************************
 * resolveEntity -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_InputSource *
FastSAX_HandlerBase::resolveEntity(const char *, const char *)
{
  /* Returning NULL is the default behaviour according to the SAX definition */
  return NULL;
}


/*****************************************************************************
 * notationDecl -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_HandlerBase::notationDecl(const char *, const char *, const char *)
{
}


/*****************************************************************************
 * unparsedEntityDecl -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_HandlerBase::unparsedEntityDecl(const char *, const char *,
                                        const char *, const char * )
{
}


/*****************************************************************************
 * setDocumentLocator -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_HandlerBase::setDocumentLocator(FastSAX_ILocator * locator)
{
  /* Store the supplied locator in a member variable */
  _locator = locator;
}


/*****************************************************************************
 * startDocument -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_HandlerBase::startDocument()
{
}


/*****************************************************************************
 * endDocument -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_HandlerBase::endDocument()
{
}


/*****************************************************************************
 * startElement -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_HandlerBase::startElement(const char *, FastSAX_IAttributeList *)
{
}


/*****************************************************************************
 * endElement -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_HandlerBase::endElement(const char *)
{
}


/*****************************************************************************
 * characters -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_HandlerBase::characters(const char *, int, int)
{
}


/*****************************************************************************
 * ignorableCharacters -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_HandlerBase::ignorableWhitespace(const char *, int, int)
{
}


/*****************************************************************************
 * processingInstructions -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_HandlerBase::processingInstruction(const char *, const char *)
{
}


/*****************************************************************************
 * warning -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_HandlerBase::warning(FastSAX_ParseException&)
{
}


/*****************************************************************************
 * error -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_HandlerBase::error(FastSAX_ParseException&)
{
}


/*****************************************************************************
 * fatalError -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_HandlerBase::fatalError(FastSAX_ParseException& exception)
{
  throw exception;
}

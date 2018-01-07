/*****************************************************************************
 * FastSAX_ParserFactory.cpp
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_ParserFactory.cpp,v 1.3 2001/02/13 11:45:13 ablehr Exp $
 * $Log: FastSAX_ParserFactory.cpp,v $
 * Revision 1.3  2001/02/13 11:45:13  ablehr
 * - kdoc documentation complete (run `make doc').
 * - Consolidation complete.
 *
 *****************************************************************************/

#include "FastSAX_ParserFactory.h"
#include "FastSAX_libxmlParser.h"


/* Initialize the static instance pointer to NULL */
FastSAX_ParserFactory * FastSAX_ParserFactory::_factory = NULL;


/*****************************************************************************
 ******* > >  P R O T E C T E D   M E M B E R   F U N C T I O N S  < < *******
 *****************************************************************************/

/*****************************************************************************
 * FastSAX_ParserFactory -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_ParserFactory::FastSAX_ParserFactory(const char * type)
{
  /* Obtain a log handler instance for this class */
  _logHandler = Fast_LogManager::GetLogHandler("FastSAX_ParserFactory");

  if (strcmp(type, _C_SAXTYPE_XERCES) == 0)
    /* Xerces support is not yet (Feb 2001) implemented... */
    _logHandler->
      SetFatal("Support for \"%s\" parser not yet implemented.", type);
  else if (strcmp(type, _C_SAXTYPE_LIBXML) != 0)
    /* libxml is currently (Feb 2001) the only FastSAX implementation... */
    _logHandler->
      SetFatal("Unknown parser type \"%s\", cannot instantiate.", type);

  /* Set the type specification */
  _type = type;
}


/*****************************************************************************
 * ~FastSAX_ParserFactory -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_ParserFactory::~FastSAX_ParserFactory()
{
}


/*****************************************************************************
 ********** > >  P U B L I C   M E M B E R   F U N C T I O N S  < < **********
 *****************************************************************************/

/*****************************************************************************
 * createFactory -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_ParserFactory *
FastSAX_ParserFactory::createFactory()
{
  /* Create a parser factory with the default parser type specification */
  return createFactory(_C_SAXTYPE_DEFAULT);
}


/*****************************************************************************
 * createFactory -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_ParserFactory *
FastSAX_ParserFactory::createFactory(const char * type)
{
  /* Instantiate factory if not already instantiated; set error otherwise */
  if (_factory == NULL)
    _factory = new FastSAX_ParserFactory(type);
  else
    _factory->_logHandler->
      SetError("Factory already exists (type is \"%s\"), use "
               "destroyFactory() to destroy.", _factory->_type.CString());

  /* Return a pointer to the singleton parser factory instance */
  return _factory;
}


/*****************************************************************************
 * destroyFactory -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_ParserFactory::destroyFactory()
{
  /* Create dummy factory and give warning if factory is uninstantiated */
  if (_factory == NULL)
  {
    createFactory(_C_SAXTYPE_DEFAULT);

    _factory->_logHandler->
      SetWarning("Attempt to destroy uninstantiated parser factory.  "
                 "Creating and destroying dummy instance."            );
  }

  /* Delete the singleton parser factory instance */
  delete _factory;
}


/*****************************************************************************
 * getFactory -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_ParserFactory *
FastSAX_ParserFactory::getFactory()
{
  /* Create factory and give warning if factory is uninstantiated */
  if (_factory == NULL)
  {
    createFactory(_C_SAXTYPE_DEFAULT);

    _factory->_logHandler->
      SetWarning("Request for uninstantiated factory, creating default "
                 "factory (type is \"%s\").", _factory->_type.CString() );
  }

  /* Return a pointer to the singleton parser factory instance */
  return _factory;
}


/*****************************************************************************
 * createFactory -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_IParser *
FastSAX_ParserFactory::createParser()
{
  FastSAX_IParser * parser = NULL;

  if (_type == _C_SAXTYPE_LIBXML)
    /* Create a libxml-based FastSAX parser */
    parser = new FastSAX_libxmlParser();
  else
    /* Set fatal error if the specified parser type is not supported */
    _logHandler->
      SetFatal("Don't know how to create \"%s\" XNML parser.", _type.CString());

  /* Return a pointer to the newly created parser instance */
  return parser;
}

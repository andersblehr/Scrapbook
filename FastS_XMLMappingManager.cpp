/******************************************************************************
 * FastS_XMLMappingManager.cpp
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastS_XMLMappingManager.cpp,v 1.3 2001/02/15 14:10:54 ablehr Exp $
 * $Log: FastS_XMLMappingManager.cpp,v $
 * Revision 1.3  2001/02/15 14:10:54  ablehr
 * - Bugfix
 *
 ******************************************************************************/

#include "FastS_XMLMappingManager.h"


/*****************************************************************************
 ********** > >  P U B L I C   M E M B E R   F U N C T I O N S  < < **********
 *****************************************************************************/

/*****************************************************************************
 * FastS_XMLMappingManager -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLMappingManager::FastS_XMLMappingManager(const char * mappingFile,
                                                 FastS_FIXAPI_Configuration *
                                                   configuration) try :
    FastSAX_HandlerBase()
{
  /* Obtain a Fast_LogHandler instance for this class */
  _logHandler = Fast_LogManager::GetLogHandler("FastS_XMLMappingManager");

  /* Set an error if the configuration is NULL */
  if (configuration == NULL)
    _logHandler->SetError("FIXAPI configuration is NULL, "
                          "cannot instantiate mapping manager.");

  /* Initialize member variables */
  _configuration = configuration;
  _mapping = NULL;
  _state = IDLE;

  /* Create the hash table of mapping lists */
  _mappingHash = new Fast_HashTable<FastS_XMLMappingList *>(_C_MAX_MAPPINGS);

  /* Obtain a parser from the parser factory instantiated by the application */
  _parser = FastSAX_ParserFactory::getFactory()->createParser();

  /* Set the parser's document and error handlers to point to this instance */
  _parser->setDocumentHandler(this);
  _parser->setErrorHandler(this);

  /* Parse (i.e., load) the mapping file */
  _parser->parse(mappingFile);
}
catch (Fast_Exception& anException)
{
  anException.DefaultAction();
}


/*****************************************************************************
 * ~FastS_XMLMappingManager -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLMappingManager::~FastS_XMLMappingManager()
{
  /* Delete objects created here */
  delete _mappingHash;
  delete _parser;
}


/*****************************************************************************
 * startElement -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLMappingManager::startElement(const char *             name,
                                      FastSAX_IAttributeList * attributeList) try
{
  switch (_state)
  {
    /* State = IDLE: Element must be root element */
    case IDLE:
    {
      /* Set error of the element is not the root element */
      if (strcmp(name, _C_XMLMAP_ROOT) != 0)
        _logHandler->SetError("Unexpected element \"%s\", "
                              "mapping file probably invalid.", name);

      /* Update state */
      _state = ROOT;

      break;
    }

    /* State = ROOT: Element must be document delimiter or mapping list */
    case ROOT:
    {
      /* Set error if element is neither document delimiter nor mapping list */
      if (strcmp(name, _C_XMLMAP_DOCDELIM) && strcmp(name, _C_XMLMAP_LIST))
        _logHandler->SetError("Unexpected element \"%s\", (excpected \"%s\" "
                              "or \"%s\"), mapping file probably invalid.", 
                              name, _C_XMLMAP_DOCDELIM, _C_XMLMAP_LIST       );

      if (strcmp(name, _C_XMLMAP_DOCDELIM) == 0)
      {
        /* Element is document delimiter; keep delimiter and update state */
        _documentDelimiter = attributeList->getValue("element");
        _state = DELIM;
      }
      else if (strcmp(name, _C_XMLMAP_LIST) == 0)
        /* Element is mapping list; update state */
        _state = LIST;

      break;
    }

    /* State = LIST: Element must be mapping */
    case LIST:
    {
      /* Set error if element is not mapping */
      if (strcmp(name, _C_XMLMAP_MAPPING) != 0)
        _logHandler->SetError("Unexpected element \"%s\" (expected \"%s\"), "
                              "mapping file probably invalid.",
                              name, _C_XMLMAP_MAPPING                        );

      /* Create a new mapping using the current element and its attributes */
      _mapping = new FastS_XMLMapping(_configuration,
                                      attributeList->getValue(_C_XMLMAP_FROM),
                                      attributeList->getValue(_C_XMLMAP_ATTR),
                                      attributeList->getValue(_C_XMLMAP_IFVALUE));

      /* Update state */
      _state = MAPPING;

      break;
    }

    /* State = MAPPING: Element must map to context, sField, or rField */
    case MAPPING:
    {
      /* Add context, sField, or rField to mapping depending on the element */
      if (strcmp(name, _C_XMLMAP_TO_CONTEXT) == 0)
        _mapping->addContext(attributeList->getValue(_C_XMLMAP_CATALOG),
                             attributeList->getValue(_C_XMLMAP_CNAME)   );
      else if (strcmp(name, _C_XMLMAP_TO_SFIELD) == 0)
        _mapping->addSummaryField(attributeList->getValue(_C_XMLMAP_SCLASS),
                                  attributeList->getValue(_C_XMLMAP_SNAME)  );
      else if (strcmp(name, _C_XMLMAP_TO_RFIELD) == 0)
        _mapping->addRankField(attributeList->getValue(_C_XMLMAP_RCLASS),
                               attributeList->getValue(_C_XMLMAP_RNAME)  );
      else
        /* Set error if element is neither of the above */
        _logHandler->SetError("Unexpected element \"%s\" (excpected \"%s\", "
                              "\"%s\", or \"%s\"), mapping file probably "
                              "invalid.", name, _C_XMLMAP_TO_CONTEXT,
                              _C_XMLMAP_TO_SFIELD, _C_XMLMAP_TO_RFIELD       );

      break;
    }

    /* State = DELIM: We should never get here... */
    case DELIM:
      break;
  }
}
catch (Fast_Exception& anException)
{
  anException.DefaultAction();
}


/*****************************************************************************
 * endElement -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLMappingManager::endElement(const char * name) try
{
  FastS_XMLMappingList * mappingList;

  switch (_state)
  {
    /* State = MAPPING: Element does not have to be mapping... */
    case MAPPING:
    {
      if (strcmp(name, _C_XMLMAP_MAPPING) == 0)
      {
        /* OK, it _is_ mapping; see if a mapping list exists for the element */
        mappingList = _mappingHash->Find(_mapping->getElement());

        /* If a mapping list does not exist, create one and insert into hash */
        if (mappingList == NULL)
        {
          mappingList = new FastS_XMLMappingList();
          _mappingHash->Insert(_mapping->getElement(), mappingList);
        }

        /* Add current mapping, which is now complete, to mapping list */
        mappingList->add(_mapping);

        /* Update state */
        _state = LIST;
      }

      break;
    }

    /* State = LIST: Element must be mapping list */
    case LIST:
    {
      /* Set error if the element is not mapping list */
      if (strcmp(name, _C_XMLMAP_LIST) != 0)
        _logHandler->
          SetError("Unexpected element \"%s\" (expected \"%s\").  Mapping "
                   "file probably invalid.", name, _C_XMLMAP_LIST          );

      /* Update state */
      _state = ROOT;

      break;
    }

    /* State = DELIM: Element must be document delimiter */
    case DELIM:
    {
      /* Set error if the element is not document delimiter */
      if (strcmp(name, _C_XMLMAP_DOCDELIM) != 0)
        _logHandler->
          SetError("Unexpected element \"%s\" (expected \"%s\").  Mapping "
                   "file probably invalid.", name, _C_XMLMAP_DOCDELIM      );

      /* Update state */
      _state = ROOT;

      break;
    }

    /* State = ROOT: Element must be the root element */
    case ROOT:
    {
      /* Set error if the element is not the root element */
      if (strcmp(name, _C_XMLMAP_ROOT) != 0)
        _logHandler->
          SetError("Unexpected element \"%s\" (expected \"%s\").  Mapping "
                   "file probably invalid.", name, _C_XMLMAP_ROOT          );

      /* Update state (we should be done now...) */
      _state = IDLE;

      break;
    }

    /* State = IDLE: We should never get here... */
    case IDLE:
      break;
  }
}
catch (Fast_Exception& anException)
{
  anException.DefaultAction();
}


/*****************************************************************************
 * warning -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLMappingManager::warning(FastSAX_ParseException& parseException)
{
  /* Set warning using the warning information embedded in the exception */
  _logHandler->SetWarning("SAX parse error (line %u, column %u): %s",
                          parseException.getLineNumber(),
                          parseException.getColumnNumber(),
                          parseException.getMessage()                );
}


/*****************************************************************************
 * error -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLMappingManager::error(FastSAX_ParseException& parseException)
{
  /* Set error using the error information embedded in the exception */
  _logHandler->SetError("SAX parse error (line %u, column %u): %s",
                        parseException.getLineNumber(),
                        parseException.getColumnNumber(),
                        parseException.getMessage()                );
}


/*****************************************************************************
 * fatalError -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLMappingManager::fatalError(FastSAX_ParseException& parseException)
{
  /* Set fatal error using the error information embedded in the exception */
  _logHandler->SetFatal("SAX parse error (line %u, column %u): %s",
                        parseException.getLineNumber(),
                        parseException.getColumnNumber(),
                        parseException.getMessage()                );
}


/*****************************************************************************
 * getDocumentDelimiter -- Cf. header file for function description.
 *****************************************************************************/
const char *
FastS_XMLMappingManager::getDocumentDelimiter()
{
  /* Return the document delimiter, or NULL if none has been specified */
  return (_documentDelimiter != "") ? _documentDelimiter.CString() : NULL;
}


/*****************************************************************************
 * getMappings -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLMappingList *
FastS_XMLMappingManager::getMappings(const char * element)
{
  /* Look up element in the hash table and return the resulting mapping list */
  return _mappingHash->Find(element);
}

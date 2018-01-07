/******************************************************************************
 * FastS_XMLIndexer.cpp
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastS_XMLIndexer.cpp,v 1.3 2001/02/15 14:10:54 ablehr Exp $
 * $Log: FastS_XMLIndexer.cpp,v $
 * Revision 1.3  2001/02/15 14:10:54  ablehr
 * - Bugfix
 *
 ******************************************************************************/

#include <fastlib/log/logreporter.h>

#include "FastS_XMLIndexer.h"


/*****************************************************************************
 ********** > >  P U B L I C   M E M B E R   F U N C T I O N S  < < **********
 *****************************************************************************/

/*****************************************************************************
 * FastS_XMLIndexer -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLIndexer::FastS_XMLIndexer(const char * configFile,
                                   const char * indexDir,
                                   const char * mappingFile,
                                   unsigned int partition   ) try :
    FastSAX_HandlerBase(),
    Fast_TokenListener()
{
  /* Create a Fast_LogHandler instance for this class */
  _logHandler = Fast_LogManager::GetLogHandler("FastS_XMLIndexer");

  /* Create the index configuration instance */
  _configuration =
    new FastS_FIXAPI_Configuration(indexDir,
                                   partition,
                                   new Fast_LogReporter(_logHandler->
                                                          GetLogReporter(),
                                                        "FIXAPI"           ),
                                   _logHandler->GetVerbosity() > 0,
                                   false                                     );

  /* Read the index configuration file and abort if error(s) in file */
  if (_configuration->ReadConfigFile(configFile) != 0)
    _logHandler->SetFatal("Error in index configuration file, aborting.");

  /* Instantiate the mapping manager and load the mapping file */
  _mappingManager = new FastS_XMLMappingManager(mappingFile, _configuration);

  /* Obtain a parser from the parser factory instantiated by the application */
  _parser = FastSAX_ParserFactory::getFactory()->createParser();

  /* Set the parser's document and error handlers to point to this instance */
  _parser->setDocumentHandler(this);
  _parser->setErrorHandler(this);

  /* Instantiate the tokenizer (hardcoded to Fast_GenericTokenizer for now) */
  _tokenizer = new Fast_GenericTokenizer(this);

  /* Instantiate the state manager */
  _stateManager =
    new FastS_XMLStateManager(_configuration,
                              _mappingManager->getDocumentDelimiter());

  /* Initialize flags to false */
  _initialized = false;
  _finalized = false;
}
catch (Fast_Exception& theException)
{
  theException.DefaultAction();
}


/*****************************************************************************
 * ~FastS_XMLIndexer -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLIndexer::~FastS_XMLIndexer(void)
{
  /* Finalize the index if it has not already been done */
  if (!_finalized)
    finalize();

  /* Delete instances created by this instance */
  delete _parser;
  delete _tokenizer;
  delete _configuration;
  delete _mappingManager;
  delete _stateManager;
}


/*****************************************************************************
 * startDocument -- Cf. header file for function description.
 *****************************************************************************/
void 
FastS_XMLIndexer::startDocument()
{
  /* Create a new, document (file) level state */
  _stateManager->newState();
}


/*****************************************************************************
 * endDocument -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLIndexer::endDocument()
{
  /* Reset the state stack */
  _stateManager->reset();
}


/*****************************************************************************
 * startElement -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLIndexer::startElement(const char *             name,
                               FastSAX_IAttributeList * attributeList) try
{
  FastS_XMLMappingList * mappingList = _mappingManager->getMappings(name);
  FastS_XMLMapping *     mapping;
  const char *           attributeValue;

  /* Create a new state for this element */
  _stateManager->newState(name);

  /* Only do something if we got a mapping list from the mapping manager */
  if (mappingList != NULL)
  {
    /* Retrieve the first mapping from the mapping list */
    mapping = mappingList->getFirst();

    /* Iterate while the current mapping is non-NULL */
    while (mapping != NULL)
    {
      switch (mapping->getType())
      {
        /* Type = ELEMENT: Add the mapping to the current state */
        case _C_MAPPINGTYPE_ELEMENT:
        {
          _stateManager->addMapping(mapping);

          break;
        }

        /* Type = IFVALUE: Add the mapping to the current state only if ... */
        case _C_MAPPINGTYPE_IFVALUE:
        {
          /* ... the attribute specified in the mapping is in the attribute
             list and has the value ("ifValue") specified in the mapping */
          if (strcmp(mapping->getIfValue(),
                     attributeList->getValue(mapping->getAttribute())) == 0)
            _stateManager->addMapping(mapping);

          break;
        }

        /* Type = ATTRIBUTE: Index the value of the specified attribute, if set */
        case _C_MAPPINGTYPE_ATTRIBUTE:
        {
          /* Attempt to look up the value of the specified attribute */
          attributeValue = attributeList->getValue(mapping->getAttribute());

          /* If a value was returned, the attribute is set for this element */
          if (attributeValue != NULL)
          {
            /* Create a new state that has only one mapping: the current */
            _stateManager->newState(mapping);

            /* Add attribute value to tokenizer and tokenize immediately */
            _tokenizer->Put((const utf8_t *)attributeValue);
            _tokenizer->Tokenize();

            /* Revert to previous (or "actual current") state */
            _stateManager->popState();
          }

          break;
        }
      }

      /* Retrieve the next mapping from the mapping list */
      mapping = mappingList->getNext();
    }
  }
}
catch (Fast_Exception& theException)
{
  theException.DefaultAction();
}


/*****************************************************************************
 * endElement -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLIndexer::endElement(const char *) try
{
  /* Tokenize if the state is tokenizable */
  if (_stateManager->canTokenize())
    _tokenizer->Tokenize();

  /* Revert to previous state (i.e., the state for the enclosing element) */
  _stateManager->popState();
}
catch (Fast_Exception& theException)
{
  theException.DefaultAction();
}


/*****************************************************************************
 * characters -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLIndexer::characters(const char * data, int start, int length) try
{
  /* Append the data to the tokenizer buffer if the state is tokenizable */
  if (_stateManager->canTokenize())
    _tokenizer->Put((const utf8_t *)(data + start), length);
}
catch (Fast_Exception& theException)
{
  theException.DefaultAction();
}


/*****************************************************************************
 * warning -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLIndexer::warning(FastSAX_ParseException& parseException) try
{
  /* Set warning using the warning information embedded in the exception */
  _logHandler->SetWarning("SAX parse error (line %u, column %u): %s",
                          parseException.getLineNumber(),
                          parseException.getColumnNumber(),
                          parseException.getMessage()                );
}
catch (Fast_Exception& theException)
{
  theException.DefaultAction();
}


/*****************************************************************************
 * error -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLIndexer::error(FastSAX_ParseException& parseException) try
{
  /* Set error using the error information embedded in the exception */
  _logHandler->SetError("SAX parse error (line %u, column %u): %s",
                        parseException.getLineNumber(),
                        parseException.getColumnNumber(),
                        parseException.getMessage()                );
}
catch (Fast_Exception& theException)
{
  /* SetError throws an exception; abort the document upon catching it */
  _stateManager->abortDocument();

  /* Do the default action */
  theException.DefaultAction();
}


/*****************************************************************************
 * fatalError -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLIndexer::fatalError(FastSAX_ParseException& parseException) try
{
  /* Set fatal error using the error information embedded in the exception */
  _logHandler->SetFatal("SAX parse error (line %u, column %u): %s",
                        parseException.getLineNumber(),
                        parseException.getColumnNumber(),
                        parseException.getMessage()                );
}
catch (Fast_Exception& theException)
{
  /* SetError throws a fatal exception; give warning that we'll terminate */
  _logHandler->SetWarning("Fatal error, terminating...");

  /* The default action terminates the application for fatal exceptions */
  theException.DefaultAction();
}


/*****************************************************************************
 * OnToken -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLIndexer::OnToken() try
{
  FastS_XMLMappingList *      mappingList = _stateManager->getMappings();
  FastS_XMLMapping *          mapping = mappingList->getFirst();
  FastS_FIXAPI_Context *      context;
  FastS_FIXAPI_SummaryField * summaryField;
  FastS_FIXAPI_RankField *    rankField;

  /* Iterate while the mapping retrieved from the mapping list is non-NULL */
  while (mapping != NULL)
  {
    /* If token is word, add token to all contexts in the mapping */
    if (mapping->hasContexts() && _token->IsWord())
    {
      context = mapping->getFirstContext();

      while (context != NULL)
      {
        context->AddWord(_token->AsLowerCaseUTF8(),
                         _token->GetByteLengthAsUTF8());
        context = mapping->getNextContext();
      }
    }

    /* Append token to all summary field that exists for this mapping */
    if (mapping->hasSummaryFields())
    {
      summaryField = mapping->getFirstSummaryField();

      while (summaryField != NULL)
      {
        summaryField->AppendValue(_token->AsUTF8(),
                                  _token->GetByteLengthAsUTF8());
        summaryField = mapping->getNextSummaryField();
      }
    }

    /* Set all rank fields that exists for this mapping to the token value */
    if (mapping->hasRankFields())
    {
      rankField = mapping->getFirstRankField();

      while (rankField != NULL)
      {
        rankField->SetValue(_token->AsNumber());
        rankField = mapping->getNextRankField();
      }
    }

    /* Get the next mapping for the current state */
    mapping = mappingList->getNext();
  }
}
catch (Fast_Exception& anException)
{
  anException.DefaultAction();
}


/*****************************************************************************
 * setInputEncoding -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLIndexer::setInputEncoding(const char * encoding)
{
  /* Tell the tokenizer to expect an encoding different from UCS-4 and UTF-8 */
  _tokenizer->SetAlternateEncoding(encoding);
}


/*****************************************************************************
 * initialize -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLIndexer::initialize()
{
  /* Initialize if not initialized; set warning if already initialized */
  if (!_initialized)
  {
    _configuration->InitiateIndexing();
    _initialized = true;
  }
  else
    _logHandler->
      SetWarning("Indexer already initialized, no need to reinitialize.");
}


/*****************************************************************************
 * index -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLIndexer::index(const char * fileName) try
{
  /* Initialize if uninitialized */
  if (!_initialized)
    initialize();

  /* Parse the file */
  _parser->parse(fileName);
}
catch (Fast_Exception& anException)
{
  _logHandler->SetWarning("Parse error occured for file %s.", fileName);
}


/*****************************************************************************
 * finalize -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLIndexer::finalize()
{
  /* Finalize if not finalized; set warning if already finalized */
  if (!_finalized)
  {
    _configuration->EndIndexing();
    _finalized = true;
  }
  else
    _logHandler->SetWarning("Index already finalized, no need to refinalize.");
}


/*****************************************************************************
 * getNumDocumentsOK -- Cf. header file for function description.
 *****************************************************************************/
int
FastS_XMLIndexer::getNumDocumentsOK()
{
  /* Retrieve and return the number of successfully indexed documents */
  return _stateManager->getNumDocumentsOK();
}


/*****************************************************************************
 * getNumDocumentsAborted -- Cf. header file for function description.
 *****************************************************************************/
int
FastS_XMLIndexer::getNumDocumentsAborted()
{
  /* Retrieve and return the number of aborted documents */
  return _stateManager->getNumDocumentsAborted();
}

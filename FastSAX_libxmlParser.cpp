/******************************************************************************
 * FastSAX_libxmlParser.cpp
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_libxmlParser.cpp,v 1.5 2001/02/13 11:45:13 ablehr Exp $
 * $Log: FastSAX_libxmlParser.cpp,v $
 * Revision 1.5  2001/02/13 11:45:13  ablehr
 * - kdoc documentation complete (run `make doc').
 * - Consolidation complete.
 *
 ******************************************************************************/

#include "FastSAX_libxmlParser.h"


/******************************************************************************
 * This structure is passed to libxml upon initiation of a parse and specifies
 * which functions libxml should invoke when receiving specific XML events.
 * Functions are specified only for those events that are handled in the SAX1
 * specification.
 *
 * The individual functions in turn invoke the corresponding methods of the
 * parser's document handler, DTD handler, entity resolver, and error handler.
 ******************************************************************************/
xmlSAXHandler libxmlSAXHandler = {
  NULL, /* internalSubset */
  NULL, /* isStandalone */
  NULL, /* hasInternalSubset */
  NULL, /* hasExternalSubset */
  libxmlResolveEntity, /* resolveEntity */
  NULL, /* getEntity */
  NULL, /* entityDecl */
  libxmlNotationDecl, /* notationDecl */
  NULL, /* attributeDecl */
  NULL, /* elementDecl */
  libxmlUnparsedEntityDecl, /* unparsedEntityDecl */
  libxmlSetDocumentLocator, /* setDocumentLocator */
  libxmlStartDocument, /* startDocument */
  libxmlEndDocument, /* endDocument */
  libxmlStartElement, /* startElement */
  libxmlEndElement, /* endElement */
  NULL, /* reference */
  libxmlCharacters, /* characters */
  libxmlIgnorableWhitespace, /* ignorableWhitespace */
  libxmlProcessingInstruction, /* processingInstruction */
  NULL, /* comment */
  libxmlWarning, /* xmlParserWarning */
  libxmlError, /* xmlParserError */
  libxmlFatalError, /* xmlFatalError */
  NULL, /* getParameterEntity */
  libxmlCharacters  /* cdataBlock */
};


/*****************************************************************************
 ********** > >  P U B L I C   M E M B E R   F U N C T I O N S  < < **********
 *****************************************************************************/

/*****************************************************************************
 * FastSAX_libxmlParser -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_libxmlParser::FastSAX_libxmlParser()
{
  _locator = new FastSAX_libxmlLocator();
  _attributeList = new FastSAX_libxmlAttributeList();

  _defaultHandler = new FastSAX_HandlerBase();

  setDocumentHandler(_defaultHandler);
  setDTDHandler(_defaultHandler);
  setEntityResolver(_defaultHandler);
  setErrorHandler(_defaultHandler);

  _context = NULL;

  _logHandler = Fast_LogManager::GetLogHandler("FastSAX_libxmlParser");
}


/*****************************************************************************
 * ~FastSAX_libxmlParser -- Cf. header file for function description.
 *****************************************************************************/
FastSAX_libxmlParser::~FastSAX_libxmlParser()
{
  delete _locator;
  delete _attributeList;
  delete _defaultHandler;
}


/*****************************************************************************
 * setDocumentHandler -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_libxmlParser::setDocumentHandler(FastSAX_IDocumentHandler *
                                         documentHandler           )
{
  _documentHandler = documentHandler;
}


/*****************************************************************************
 * setDTDHandler -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_libxmlParser::setDTDHandler(FastSAX_IDTDHandler * DTDHandler)
{
  _DTDHandler = DTDHandler;
}


/*****************************************************************************
 * setEntityResolver -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_libxmlParser::setEntityResolver(FastSAX_IEntityResolver * entityResolver)
{
  _entityResolver = entityResolver;
}


/*****************************************************************************
 * setErrorHandler -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_libxmlParser::setErrorHandler(FastSAX_IErrorHandler * errorHandler)
{
  _errorHandler = errorHandler;
}


/*****************************************************************************
 * parse -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_libxmlParser::parse(FastSAX_InputSource * inputSource)
{
  /* Currently, only system IDs that identify local files are supported... */
  parse(inputSource->getSystemId());
}


/*****************************************************************************
 * parse -- Cf. header file for function description.
 *****************************************************************************/
void
FastSAX_libxmlParser::parse(const char * systemId)
{
  /* Parse if the system ID is not NULL; set error otherwise */
  if (systemId != NULL)
  {
    /* Create a new file parser context from the system ID (file name) */
    _context = xmlCreateFileParserCtxt(systemId);

    /* Set an error if the parser context could not be created */
    if (_context == NULL)
      _logHandler->SetError("Unable to open input source %s.", systemId);

    /* Set the context of the document locator */
    _locator->_context = _context;

    /* Delete the SAX handler if it's different from the default handler */
    if (_context->sax != &xmlDefaultSAXHandler)
      xmlFree(_context->sax);

    /* Set the SAX handler to the lixmlSAXHandler structure declared above */
    _context->sax = &libxmlSAXHandler;

    /* The SAX handler functions get access to the parser through userData */
    _context->userData = (void *)this;

    /* Initiate parse of the document */
    xmlParseDocument(_context);
    
    /* Set an error if the document was not well-formed */
    if (!_context->wellFormed)
      _logHandler->SetError("Document not well-formed.");

    /* Reset the SAX handler and user data pointers of the parser context */
    _context->sax = NULL;
    _context->userData = NULL;

    /* Free the parser context and set it to NULL */
    xmlFreeParserCtxt(_context);
    _context = NULL;
  }
  else
    _logHandler->SetError("System ID is NULL, cannot parse.");
}


/******************************************************************************
 * libxmlResolveEntity --
 *
 * Resolve the entity using the parser's entity resolver.  Translate the
 * resulting FastSAX_InputSource, if any, to a libxml xmlParserInput
 * structure.
 *
 * Currently, only local files are supported.  This means that the filename
 * variable of the xmlParserInput structure is set to the systemId of the
 * FastSAX_InputSource, regardless of whether this systemId actually identifies
 * a local file.
 *
 * If the entity resolver of the parser returns NULL, so does this function.
 * This is the default behaviour as specified in the SAX1 specification.
 *
 * @param userData - A pointer to the FastSAX_libxmlParser instance.
 * @param publicId - The public identifier, or NULL if none is available.
 * @param systemId - The system identifier provided in the XML document.
 ******************************************************************************/
xmlParserInputPtr
libxmlResolveEntity(void *          userData,
                    const xmlChar * publicId,
                    const xmlChar * systemId )
{
  FastSAX_libxmlParser * parser = (FastSAX_libxmlParser *)userData;
  FastSAX_InputSource *  inputSource;
  char *                 fileName;
  xmlParserInputPtr      parserInput = NULL;

  /* Obtain a SAX1 input source by relaying to the parser's entity resolver */
  inputSource =
    parser->_entityResolver->resolveEntity((const char *)publicId,
                                           (const char *)systemId );

  /* Translate to an xmlParserInput structure if the input source is not NULL */
  if (inputSource != NULL)
  {
    /* Allocate memory for the xmlParserInput structure */
    parserInput = (xmlParserInputPtr)malloc(sizeof(xmlParserInput));

    /* Allocate file name string and assign the system ID of the input source */
    fileName = (char *)malloc(strlen(inputSource->getSystemId()) + 1);
    strcpy(fileName, inputSource->getSystemId());

    /* Set filename variable in the xmlParserInput structure to this string */
    parserInput->filename = fileName;

    /* FastSAX_InputSource instance not needed anymore */
    delete inputSource;
  }

  /* Return the xmlParserInput structure to libxml */
  return parserInput;
}


/******************************************************************************
 * libxmlNotationDecl --
 *
 * Redirect the notationDecl event to the notationDecl() method of the parser's
 * DTD handler.
 *
 * @param userData - A pointer to the FastSAX_libxmlParser instance.
 * @param name     - The notation name.
 * @param publicId - The notation's public identifier, or NULL if none was
 *                   given.
 * @param systemId - The notation's system identifier, or NULL if none was
 *                   given.
 ******************************************************************************/
void
libxmlNotationDecl(void *          userData,
                   const xmlChar * name,
                   const xmlChar * publicId,
                   const xmlChar * systemId )
{
  FastSAX_libxmlParser * parser = (FastSAX_libxmlParser *)userData;

  parser->_DTDHandler->notationDecl((const char *)name,
                                    (const char *)publicId,
                                    (const char *)systemId );
}


/******************************************************************************
 * libxmlUnparsedEntityDecl --
 *
 * Redirect the unparsedEntityDecl event to the unparsedEntityDecl() method of
 * the parser's DTD handler.
 *
 * @param userData     - A pointer to the FastSAX_libxmlParser instance.
 * @param name         - The unparsed entity's name.
 * @param publicId     - The entity's public identifier, or NULL if none was
 *                       given.
 * @param systemId     - The entity's system identifier.
 * @param notationName - The name of the associated notation.
 ******************************************************************************/
void
libxmlUnparsedEntityDecl(void *          userData,
                         const xmlChar * name,
                         const xmlChar * publicId,
                         const xmlChar * systemId,
                         const xmlChar * notationName)
{
  FastSAX_libxmlParser * parser = (FastSAX_libxmlParser *)userData;

  parser->_DTDHandler->unparsedEntityDecl((const char *)name,
                                          (const char *)publicId,
                                          (const char *)systemId,
                                          (const char *)notationName);
}


/******************************************************************************
 * libxmlSetDocumentLocator --
 *
 * Set the xmlSAXLocator of the parser's FastSAX_libxmlLocator instance, and
 * consequently set the document locator of the parser's document handler to
 * the parser's FastSAX_libxmlLocator instance.
 *
 * @param userData - A pointer to the FastSAX_libxmlParser instance.
 * @param locator  - The xmlSAXLocator to use for associating document events
 *                   with locations.
 ******************************************************************************/
void
libxmlSetDocumentLocator(void * userData, xmlSAXLocatorPtr locator)
{
  FastSAX_libxmlParser  * parser = (FastSAX_libxmlParser *)userData;

  /* Set the xmlSAXLocator of the parser's FastSAX_libxmlLocator instance */
  parser->_locator->_locator = locator;

  /* Set the document locator of the parser's document handler */
  parser->_documentHandler->setDocumentLocator(parser->_locator);
}


/******************************************************************************
 * libxmlStartDocument --
 *
 * Redirect the startDocument event to the startDocument() method of the
 * parser's document handler.
 *
 * @param userData     - A pointer to the FastSAX_libxmlParser instance.
 ******************************************************************************/
void
libxmlStartDocument(void * userData)
{
  FastSAX_libxmlParser * parser = (FastSAX_libxmlParser *)userData;

  parser->_documentHandler->startDocument();
}


/******************************************************************************
 * libxmlEndDocument --
 *
 * Redirect the endDocument event to the endDocument() method of the parser's
 * document handler.
 *
 * @param userData     - A pointer to the FastSAX_libxmlParser instance.
 ******************************************************************************/
void
libxmlEndDocument(void * userData)
{
  FastSAX_libxmlParser * parser = (FastSAX_libxmlParser *)userData;

  parser->_documentHandler->endDocument();
}


/******************************************************************************
 * libxmlStartElement --
 *
 * Redirect the startElement event to the startElement() method of the parser's
 * document handler, after having converted the array of attribute pointers to
 * a FastSAX_libxmlAttributeList.
 *
 * @param userData      - A pointer to the FastSAX_libxmlParser instance.
 * @param name          - The element type name.
 * @param attributeList - The attributes of the element, if any.
 ******************************************************************************/
void
libxmlStartElement(void *           userData, 
                   const xmlChar *  name,
                   const xmlChar ** attributeList)
{
  FastSAX_libxmlParser * parser = (FastSAX_libxmlParser *)userData;

  /* Convert the array of attribute pointers to a FastSAX_libxmlAttributeList */
  parser->_attributeList->setAttributeList(attributeList);

  /* Redirect the event to the parser's document handler */
  parser->_documentHandler->startElement((const char *)name,
                                         parser->_attributeList);
}


/******************************************************************************
 * libxmlEndElement --
 *
 * Redirect the endElement event to the endElement() method of the parser's
 * document handler.
 *
 * @param userData - A pointer to the FastSAX_libxmlParser instance.
 * @param name     - The element type name.
 ******************************************************************************/
void
libxmlEndElement(void * userData, const xmlChar * name)
{
  FastSAX_libxmlParser * parser = (FastSAX_libxmlParser *)userData;

  parser->_documentHandler->endElement((const char *)name);
}


/******************************************************************************
 * libxmlCharacters --
 *
 * Redirect the characters event to the characters() method of the parser's
 * document handler.  The start position in the array is always 0.
 *
 * @param userData - A pointer to the FastSAX_libxmlParser instance.
 * @param data     - The characters from the XML document.
 * @param length   - The number of characters to read from the array.
 ******************************************************************************/
void
libxmlCharacters(void * userData, const xmlChar * data, int length)
{
  FastSAX_libxmlParser * parser = (FastSAX_libxmlParser *)userData;

  /* The start position in the array is always 0... */
  parser->_documentHandler->characters((const char *)data, 0, length);
}


/******************************************************************************
 * libxmlIgnorableWhitespace --
 *
 * Redirect the ignorableWhitespace event to the ignorableWhitespace() method
 * of the parser's document handler.  The start position in the array is always
 * 0.
 *
 * @param userData - A pointer to the FastSAX_libxmlParser instance.
 * @param data     - The characters from the XML document.
 * @param length   - The number of characters to read from the array.
 ******************************************************************************/
void
libxmlIgnorableWhitespace(void * userData, const xmlChar * data, int length)
{
  FastSAX_libxmlParser * parser = (FastSAX_libxmlParser *)userData;

  /* The start position in the array is always 0... */
  parser->_documentHandler->ignorableWhitespace((const char *)data, 0, length);
}


/******************************************************************************
 * libxmlProcessingInstruction --
 *
 * Redirect the processingInstruction event to the procesingInstruction()
 * method of the parser's document handler.
 *
 * @param userData - A pointer to the FastSAX_libxmlParser instance.
 * @param target   - The processing instruction target.
 * @param data     - The processing instruction data, or NULL if none was
 *                   given.
 ******************************************************************************/
void
libxmlProcessingInstruction(void *          userData,
                            const xmlChar * target,
                            const xmlChar * data     )
{
  FastSAX_libxmlParser * parser = (FastSAX_libxmlParser *)userData;

  parser->_documentHandler->processingInstruction((const char *)target,
                                                  (const char *)data   );
}


/******************************************************************************
 * libxmlWarning --
 *
 * Redirect a libxml parse warning to the warning() method of the parser's
 * error handler, embedding the warning information in a FastSAX_ParseException
 * instance.
 *
 * @param userData - A pointer to the FastSAX_libxmlParser instance.
 * @param format   - The format string for the warning message.
 * @param ...      - Optional parameters to be embedded in the warning message.
 ******************************************************************************/
void 
libxmlWarning(void * userData, const char * format, ...)
{
  FastSAX_libxmlParser * parser = (FastSAX_libxmlParser *)userData;
  char                   message[1024];

  /* Format the warning message from the format string and optional arguments */
  va_list arguments;
  va_start(arguments, format);
  vsnprintf(message, 1024, format, arguments);
  va_end(arguments);

  /* Create FastSAX_ParseException instance embedding the warning information */
  FastSAX_ParseException parseException(message, parser->_locator);

  /* Redirect to the warning() method of the parser's error handler */
  parser->_errorHandler->warning(parseException);
}


/******************************************************************************
 * libxmlError --
 *
 * Redirect a libxml parse error to the error() method of the parser's error
 * handler, embedding the error information in a FastSAX_ParseException
 * instance.
 *
 * @param userData - A pointer to the FastSAX_libxmlParser instance.
 * @param format   - The format string for the error message.
 * @param ...      - Optional parameters to be embedded in the error message.
 ******************************************************************************/
void 
libxmlError(void * userData, const char * format, ...)
{
  FastSAX_libxmlParser * parser = (FastSAX_libxmlParser *)userData;
  char                   message[1024];

  /* Format the error message from the format string and optional arguments */
  va_list arguments;
  va_start(arguments, format);
  vsnprintf(message, 1024, format, arguments);
  va_end(arguments);

  /* Create FastSAX_ParseException instance embedding the error information */
  FastSAX_ParseException parseException(message, parser->_locator);

  /* Redirect to the warning() method of the parser's error handler */
  parser->_errorHandler->error(parseException);
}


/******************************************************************************
 * libxmlFatalError --
 *
 * Redirect a fatal libxml parse error to the error() method of the parser's
 * error handler, embedding the error information in a FastSAX_ParseException
 * instance.
 *
 * @param userData - A pointer to the FastSAX_libxmlParser instance.
 * @param format   - The format string for the error message.
 * @param ...      - Optional parameters to be embedded in the error message.
 ******************************************************************************/
void 
libxmlFatalError(void * userData, const char * format, ...)
{
  FastSAX_libxmlParser * parser = (FastSAX_libxmlParser *)userData;
  char                   message[1024];

  /* Format the error message from the format string and optional arguments */
  va_list arguments;
  va_start(arguments, format);
  vsnprintf(message, 1024, format, arguments);
  va_end(arguments);

  /* Create FastSAX_ParseException instance embedding the error information */
  FastSAX_ParseException parseException(message, parser->_locator);

  /* Redirect to the warning() method of the parser's error handler */
  parser->_errorHandler->fatalError(parseException);
}

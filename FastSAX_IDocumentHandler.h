#ifndef _FASTSAX_IDOCUMENTHANDLER_H
#define _FASTSAX_IDOCUMENTHANDLER_H
/******************************************************************************
 * FastSAX_IDocumentHandler.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 *
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_IDocumentHandler.h,v 1.4 2001/02/13 11:45:13 ablehr Exp $
 * $Log: FastSAX_IDocumentHandler.h,v $
 * Revision 1.4  2001/02/13 11:45:13  ablehr
 * - kdoc documentation complete (run `make doc').
 * - Consolidation complete.
 *
 * Revision 1.3  2001/02/09 12:07:47  ablehr
 * - Consolidated.
 *
 * Revision 1.2  2001/02/08 12:17:45  ablehr
 * - Added a few comments and made minor modifications.  A little closer to 1.0...
 *
 ******************************************************************************/

#include <ftutil/Fast_EncodingUtility.h>

#include "FastSAX_ILocator.h"
#include "FastSAX_IAttributeList.h"


/**//**************************************************************************
 * [Most or all of this documentation is copied from David Megginson's official
 * SAX1 for Java release; cf. http://www.megginson.com/SAX/.]
 * 
 * Receive notification of general document events.
 *
 * The order of events in this interface is very important, and mirrors the
 * order of information in the document itself.  For example, all of an
 * element's content (character data, processing instructions, and/or
 * subelements) will appear, in order, between the @ref startElement() event
 * and the corresponding @ref endElement() event.
 *
 * Application writers who do not want to implement the entire interface can
 * derive a class from @ref FastSAX_DocumentHandlerSkeleton, which implements
 * the default functionality; parser writers can instantiate @ref
 * FastSAX_DocumentHandlerSkeleton to obtain a default handler.  The
 * application can find the location of any document event using the @ref
 * FastSAX_ILocator interface supplied by the @ref FastSAX_IParser through the
 * @ref setDocumentLocator() method.
 *
 * @author  Anders Blehr
 * @version $Id: FastSAX_IDocumentHandler.h,v 1.4 2001/02/13 11:45:13 ablehr Exp $
 *///**************************************************************************
class FastSAX_IDocumentHandler
{
public:
  /**//************************************************************************
   * Receive an object for locating the origin of SAX document events.
   *
   * SAX parsers are strongly encouraged (though not absolutely required) to
   * supply a locator: if it does so, it must supply the locator to the
   * application by invoking this method before invoking any of the other
   * methods in the FastSAX_IDocumentHandler interface.
   *
   * The locator allows the application to determine the end position of any
   * document-related event, even if the parser is not reporting an error.
   * Typically, the application will use this information for reporting its own
   * errors (such as character content that does not match the application's
   * business rules).  The information returned by the locator is probably not
   * sufficient for use with a search engine.
   *
   * Not that the locator will return correct information only during the
   * invocation of the events in this interface.  The application should not
   * attempt to use it at any other time.
   *
   * @see FastSAX_ILocator
   *
   * @param locator An object that can return the location of any SAX document
   *        event.
   *///************************************************************************
  virtual void setDocumentLocator(FastSAX_ILocator * locator) = 0;

  /**//************************************************************************
   * Receive notification of the beginning of a document.
   *
   * The SAX parser will invoke this method only once, before any other methods
   * in this interface or in @ref FastSAX_IDTDHandler (except for @ref
   * setDocumentLocator()).
   *///************************************************************************
  virtual void startDocument() = 0;

  /**//************************************************************************
   * Receive notification of the end of a document.
   *
   * The SAX parser will invoke this method only once, and it will be the last
   * method invoked during the parse.  The parser shall not invoke this method
   * until it has either abandoned parsing (because of an unrecoverable error)
   * or reached the end of input.
   *///************************************************************************
  virtual void endDocument() = 0;

  /**//************************************************************************
   * Receive notification of the beginning of an element.
   *
   * The parser will invoke this method at the beginning of every element in
   * the XML document; there will be a corresponding @ref endElement() event
   * (even when the element is empty).  All of the element's content will be
   * reported, in order, before the corresponding @ref endElement() event.
   *
   * If the element name has a namespace prefix, the prefix will still be
   * attached.  Note that the attribute list will contain only attributes with
   * explicit values (specified or defaulted): #IMPLIED attributes will be
   * omitted.
   *
   * @param name          The element type name
   * @param attributeList The attributes of the element, if any.
   *///************************************************************************
  virtual void startElement(const char *             name,
                            FastSAX_IAttributeList * attributeList) = 0;

  /**//************************************************************************
   * Receive notification of the end of an element.
   *
   * The SAX parser will invoke this method at the end of every element in the
   * XML document; there will be a corresponding @ref startElement() event for
   * every endElement() event (even when the element is empty).
   *
   * If the element has a namespace prefix, the prefix will still be attached
   * to the name.
   *
   * @param name The element type name.
   *///************************************************************************
  virtual void endElement(const char * name) = 0;

  /**//************************************************************************
   * Receive notification of character data.
   *
   * The parser will call this method to report each chunk of character data.
   * SAX parsers may return all contiguous character data in a single chunk, or
   * they may split it into several chunks; however, all of the characters in
   * any single event must come from the same external entity, so that the
   * locator provides useful information.
   *
   * The application must not attempt to read from the array outside of the
   * specified range.
   *
   * Note that some parsers will report whitespace using the @ref
   * ignorableWhitespace() method rather than this one (validating parsers must
   * do so).
   *
   * @see ignorableWhitespace()
   *
   * @param data   The characters from the XML document.
   * @param start  The start position int the array.
   * @param length The number of characters to read from the array.
   *///************************************************************************
  virtual void characters(const char * data, int start, int length) = 0;

  /**//************************************************************************
   * Receive notification of ignorable whitespace content in element content.
   *
   * Validating parsers must use this method to report each chunk of igonrable
   * whitespace (see the W3C XML 1.0 recommendation, section 2.10): non-
   * validating parsers may also use this method if they are capable of parsing
   * and using content models.
   *
   * SAX parsers may return all contiguous whitespace in a single chunk, or
   * they may split it into several chunks; however, all of the characters in
   * any single event must come from the same external entity, so that the
   * locator provides useful information.
   *
   * @see characters()
   *
   * @param data   The characters from the XML document.
   * @param start  The start position in the array.
   * @param length The number of characters to read from the array.
   *///************************************************************************
  virtual void ignorableWhitespace(const char * data, int start, int length) = 0;

  /**//************************************************************************
   * Receive notification of a processing instruction.
   *
   * The parser will invoke this method once for each processing instruction
   * found: note that processing instructions may occur before or after the
   * main document element.
   *
   * A SAX parser should never report an XML declaration (XML 1.0, section 2.8)
   * or a text declaration (XML 1.0, section 4.3.1) using this method.
   *
   * @param target The processing instruction target.
   * @param data   The processing instruction data, or NULL if none was
   *               supplied.
   *///************************************************************************
  virtual void processingInstruction(const char * target, const char * data) = 0;
};


#endif

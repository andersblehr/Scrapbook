#ifndef _FASTSAX_IDTDHANDLER_H
#define _FASTSAX_IDTDHANDLER_H
/******************************************************************************
 * FastSAX_IDTDHandler.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 *
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_IDTDHandler.h,v 1.3 2001/02/09 12:07:47 ablehr Exp $
 * $Log: FastSAX_IDTDHandler.h,v $
 * Revision 1.3  2001/02/09 12:07:47  ablehr
 * - Consolidated.
 *
 * Revision 1.2  2001/02/08 12:17:45  ablehr
 * - Added a few comments and made minor modifications.  A little closer to 1.0...
 *
 ******************************************************************************/

/**//**************************************************************************
 * [Most or all of this documentation is copied from David Megginson's official
 * SAX1 for Java release; cf. http://www.megginson.com/SAX/.]
 * 
 * Receive notification of basic DTD-related events.
 *
 * If a SAX application needs information about notations and unparsed
 * entities, then the application implements this interface and registers an
 * instance with the SAX parser using the parser's @ref setDTDHandler() method.
 * The parser uses the instance to report notation and unparsed entity
 * declarations to the application.
 *
 * Note that this interface includes only those DTD events that the XML
 * recommendation requires processors to report: notation and unparsed entity
 * declarations.
 *
 * The SAX parser may report these events in any order, regardless of the order
 * in which the notations and unparsed entities were declared; however, all DTD
 * events must be reported after the document handler's @ref startDocument()
 * event, and before the first @ref startElement() event.
 *
 * It is up to the application to store the information for future use (perhaps
 * in a hash table or object tree).  If the application encounters attributes
 * of type "NOTATION", "ENTITY", or "ENTITIES", it can use the information that
 * it obtained through this interface to find the entity and/or notation
 * corresponding with the attribute value.
 *
 * @see setDTDHandler()
 * @see FastSAX_HandlerBase
 *
 * @author  Anders Blehr
 * @version $Id: FastSAX_IDTDHandler.h,v 1.3 2001/02/09 12:07:47 ablehr Exp $
 *///**************************************************************************
class FastSAX_IDTDHandler
{
public:
  /**//************************************************************************
   * Receive notification of a notation declaration event.
   *
   * It is up to the application to record the notation for later, if
   * necessary.
   *
   * At least one of publicId and systemId must be non-NULL.  If a system
   * identifier is present, and it is a URL, the SAX parser must fully resolve
   * it before passing it to the application through this event.
   * 
   * There is no guarantee that the notation declaration will be reported
   * before any unparsed entities that use it.
   *
   * @see unparsedEntityDecl()
   * @see FastSAX_IAttributeList
   *
   * @param name     The notation name.
   * @param publicId The notation's public identifier, or NULL if none was
   *                 given.
   * @param systemId The notation's system identifier, or NULL if none was
   *                 given.
   *///************************************************************************
  virtual void notationDecl(const char * name,
                            const char * publicId,
                            const char * systemID ) = 0;

  /**//************************************************************************
   * Receive notification of an unparsed entity declaration event.
   *
   * Note that the notation name corresponds to a notation reported by the @ref
   * notationDecl() event.  It is up to the application to record the entity
   * for later reference, if necessary.
   *
   * @see notationDecl()
   * @see FastSAX_IAttributeList
   *
   * @param name         The unparsed entity's name.
   * @param publicId     The entity's public identifier, or NULL if none was
   *                     given.
   * @param systemId     The entity's system identifier.
   * @param notationName The name of the associated notation.
   *///************************************************************************
  virtual void unparsedEntityDecl(const char * name,
                                  const char * publicId,
                                  const char * systemId,
                                  const char * notationName) = 0;
};


#endif

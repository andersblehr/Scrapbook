#ifndef _FASTSAX_ENTITYRESOLVER_H
#define _FASTSAX_ENTITYRESOLVER_H
/******************************************************************************
 * FastSAX_IEntityResolver.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 *
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_IEntityResolver.h,v 1.4 2001/02/13 11:45:13 ablehr Exp $
 * $Log: FastSAX_IEntityResolver.h,v $
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

#include "FastSAX_InputSource.h"


/**//**************************************************************************
 * [Most or all of this documentation is copied from David Megginson's official
 * SAX1 for Java release; cf. http://www.megginson.com/SAX/.]
 * 
 * Basic interface for resolving entities.
 *
 * If a SAX application needs to implement customized handling for external
 * entities, it must implement this interface and register an instance with the
 * SAX parser using the parser's @ref setEntityResolver() method.
 *
 * The parser will then allow the application to intercept any external
 * entities (including the external DTD subset and external parameter entities,
 * if any) before including them.
 *
 * Many SAX applications will not need to implement this interface, but it will
 * be especially useful for applications that build XML documents from
 * databases or other specialized input sources, or for applications that use
 * URI types rather than URLs.
 *
 * The following resolver would provide the application with a special
 * character stream for the entity with system identifier
 * "http://www.myhost.com/today":
 *
 * The application can also use this interface to redirect identifiers to local
 * URIs or to look up replacements in a catalog (possibly by using the public
 * identifier).
 *
 * The @ref FastSAX_HandlerBase class implements the default behavious for this
 * interface, which is simply to always return NULL (to request that the parser
 * use the default system identifier).
 *
 * @see setEntityResolver()
 * @see FastSAX_InputSource
 * @see FastSAX_HandlerBase
 *
 * @author  Anders Blehr
 * @version $Id: FastSAX_IEntityResolver.h,v 1.4 2001/02/13 11:45:13 ablehr Exp $
 *///**************************************************************************
class FastSAX_IEntityResolver
{
public:
  /**//************************************************************************
   * Allow the application to resolve external entities.
   *
   * The parser will call this method before opening any external entity except
   * the top-level document entity (including the external DTD subset, external
   * entities referenced within the DTD, and external entities referenced
   * within the document element): the application may request that the parser
   * resolve the entity itself, that it use an alternative URI, or that it use
   * an entirely different input source.
   *
   * Application writers can use this method to redirect external system
   * identifiers to secure and/or local URIs, to look up public identifiers in
   * a catalogue, or to read an entity from a database or other input source
   * (including, for example, a dialog box).
   *
   * If the system identifier is a URL, the SAX parser must resolve it before
   * reporting it to the application.
   *
   * @see FastSAX_InputSource
   *
   * @return A @ref FastSAX_InputSource object describing the new input source,
   *         or NULL to request that the parser open a regular URI connection
   *         to the system identifier.
   *
   * @param publicId The public identifier of the external entity being
   *                 referenced, or NULL if none was supplied.
   * @param systemId The system identifier of the external entity being
   *                 referenced.
   *///************************************************************************
  virtual FastSAX_InputSource * resolveEntity(const char * publicId,
                                              const char * systemId ) = 0;
};


#endif

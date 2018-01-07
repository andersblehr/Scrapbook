#ifndef _FASTSAX_PARSERFACTORY_H
#define _FASTSAX_PARSERFACTORY_H
/******************************************************************************
 * FastSAX_ParserFactory.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 *
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_ParserFactory.h,v 1.3 2001/02/13 11:45:13 ablehr Exp $
 * $Log: FastSAX_ParserFactory.h,v $
 * Revision 1.3  2001/02/13 11:45:13  ablehr
 * - kdoc documentation complete (run `make doc').
 * - Consolidation complete.
 *
 ******************************************************************************/

#include <fastlib/util/string.h>
#include <ftutil/Fast_LogHandler.h>

#include "FastSAX_IParser.h"


#define _C_SAXTYPE_NONE    "none"
#define _C_SAXTYPE_LIBXML  "libxml"
#define _C_SAXTYPE_XERCES  "Xerces"

#define _C_SAXTYPE_DEFAULT _C_SAXTYPE_LIBXML


/**//**************************************************************************
 * Allow an application to create FastSAX parsers when needed, without having
 * to specify which implementation of the @ref FastSAX_IParser interface to
 * instantiate.
 *
 * FastSAX_ParserFactory implements the 'singleton' design pattern, which means
 * that it can have one and only one instance for a given application.  This
 * instance knows whether to create libxml, Xerces, or other FastSAX parsers.
 * If it creates libxml FastSAX parsers, it will not create any other FastSAX
 * parsers.  This ensures that one and only one @ref FastSAX_IParser
 * implementation will be used througout the application.
 *
 * It is not possible to call the @ref createParser() method unless the parser
 * factory has been created first.
 *
 * When the parser factory is no longer needed, the @ref destroyFactory()
 * method should be called to free up the memory occupied by the parser
 * factory.
 *
 * Note that the application is responsible for deleting the parser instances
 * created by the parser factory.
 * 
 * @see FastSAX_IParser
 * @see FastSAX_libxmlParser
 *
 * @author  Anders Blehr
 * @version $Id: FastSAX_ParserFactory.h,v 1.3 2001/02/13 11:45:13 ablehr Exp $
 *///**************************************************************************
class FastSAX_ParserFactory
{
protected:
  /**
   * A static pointer to the instantiated parser factory.  It is NULL if the
   * parser factory has not been instantiated.
   */
  static FastSAX_ParserFactory * _factory;

  /**
   * The parser type specification.  The parser factory uses the type
   * specification to know which @ref FastSAX_IParser implementation to
   * instantiate.  All parsers created by a given instance of the parser
   * factory will have the same type.
   */
  Fast_String _type;

  /**
   * The Fast_LogHandler instance for this class.
   */
  Fast_LogHandler * _logHandler;

  /**//************************************************************************
   * Constructor.
   *
   * This constructor is protected, which means that the only way of
   * instantiating a parser factory, is through the use of the static @ref
   * createFactory() method.
   *
   * @see createFactory()
   *
   * @param type The parser type specification to use in this instance.
   *///************************************************************************  
  FastSAX_ParserFactory(const char * type);

  /**//************************************************************************
   * Destructor.
   *
   * This destructor is protected, which means that the only way to destroy a
   * parser factory, is through the use of the static @ref destroyFactory()
   * method.
   *
   * Note that none of the parser instances created by a parser factory
   * instance are deleted upon destruction of the parser factory.
   *
   * @see destroyFactory()
   *///************************************************************************  
  virtual ~FastSAX_ParserFactory();

public:
  /**//************************************************************************
   * Create a parser factory with the default type specification.
   *
   * This method is useful for application writers who don't care which @ref
   * FastSAX_IParser implementation the application uses.
   *
   * Currently (Feb 2001), the default type specification is 'libxml'.  I.e.,
   * a parser factory created using this method will create @ref
   * FastSAX_libxmlParser instances.
   *
   * Using this method to create a parser factory is the exact equivalent of
   * the following:
   *
   * <pre>
   *   FastSAX_ParserFactory * factory = new FastSAX_ParserFactory(_C_SAXTYPE_DEFAULT);
   * </pre>
   *
   * @see createFactory(const char *)
   * @see getFactory()
   *
   * @return A pointer to the newly created parser factory.
   *///************************************************************************  
  static FastSAX_ParserFactory * createFactory();

  /**//************************************************************************
   * Create a parser factory with the specified type specification.
   *
   * This method is useful for application writers who want to control which
   * @ref FastSAX_IParser implementation the application should use.
   *
   * Note: Rather than hardcode the type specifier string in the call to this
   * method, the _C_SAXTYPE_<type> #defines defined in the
   * FastSAX_ParserFactory.h header file should be used.  Use
   * _C_SAXTYPE_DEFAULT to specify the default type.
   *
   * If the type specification specifies a non-recognized or non-supported
   * parser type, an error is set.
   *
   * @see createFactory()
   * @see getFactory()
   *
   * @return A pointer to the newly created parser factory.
   *
   * @param type A string containing the parser type specification.
   *///************************************************************************  
  static FastSAX_ParserFactory * createFactory(const char * type);

  /**//************************************************************************
   * Delete (destroy) the parser factory instance.
   *
   * This method should be called whenever there is no more use for the parser
   * factory, and at any rate upon termination of the application.
   *
   * Application writers who want to use more than one @ref FastSAX_IParser
   * implementation in their application may use this method to delete the
   * parser factory before creating a new one with a different type
   * specification.
   *///************************************************************************  
  static void destroyFactory();

  /**//************************************************************************
   * Return a pointer to the singleton FastSAX_ParserFactory instance.
   *
   * If the parser factory has not been instantiated when this method is
   * called, a warning is given, whereupon a parser factory with the default
   * type specification is created and a pointer to this factory returned.
   *
   * @see createFactory()
   *
   * @return A pointer to the singleton parser factory instance.
   *///************************************************************************  
  static FastSAX_ParserFactory * getFactory();

  /**//************************************************************************
   * Create a @ref FastSAX_IParser instance as specified by the type
   * specification held by the @ref _type member variable.
   *
   * Note that the instance created by this method must be deleted by the
   * application.
   *
   * @see createFactory()
   *
   * @return A pointer to the newly created FastSAX_IParser instance.
   *///************************************************************************  
  FastSAX_IParser * createParser();
};


#endif

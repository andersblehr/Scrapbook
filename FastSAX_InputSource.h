#ifndef _FASTSAX_INPUTSOURCE_H
#define _FASTSAX_INPUTSOURCE_H
/******************************************************************************
 * FastSAX_InputSource.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 *
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastSAX_InputSource.h,v 1.3 2001/02/13 11:45:13 ablehr Exp $
 * $Log: FastSAX_InputSource.h,v $
 * Revision 1.3  2001/02/13 11:45:13  ablehr
 * - kdoc documentation complete (run `make doc').
 * - Consolidation complete.
 *
 * Revision 1.2  2001/02/09 12:07:47  ablehr
 * - Consolidated.
 *
 ******************************************************************************/

#include <iostream>

#include <fastlib/util/string.h>


/**//**************************************************************************
 * [Most or all of this documentation is copied from David Megginson's official
 * SAX1 for Java release; cf. http://www.megginson.com/SAX/.]
 *
 * A single input source for an XML entity.
 *
 * The class allows a SAX application to encapsulate information about an input
 * source in a single object, which may include a public identifier, a system
 * identifier, and/or a byte stream (possibly with a specified encoding).
 *
 * There are two places that the application will deliver this input source to
 * the parser: as the argument to the @ref parse() method, or as the return
 * value of the @ref resolveEntity() method.
 *
 * The SAX parser will use the FastSAX_InputSource object to determine how to
 * read XML input.  If there is a byte stream available, the parser will read
 * that stream directly; if not, the parser will attempt to open a URI
 * connection to the resource identified by the system identifier.
 *
 * A FastSAX_InputSource object belongs to the application: the SAX parser
 * shall never modify it in any way (it may modify a copy if necessary).
 *
 * @see parse()
 * @see resolveEntity()
 *
 * @author  Anders Blehr
 * @version $Id: FastSAX_InputSource.h,v 1.3 2001/02/13 11:45:13 ablehr Exp $
 *///**************************************************************************
class FastSAX_InputSource
{
protected:
  /**
   * An STL input stream (byte stream).
   */
  std::istream * _byteStream;

  /**
   * The public identifier for this input source.
   */
  Fast_String _publicId;

  /**
   * The system identifier for this input source.
   */
  Fast_String _systemId;

  /**
   * The character encoding for the byte stream or URI.
   */
  Fast_String _encoding;

public:
  /**//************************************************************************
   * Zero-argument default constructor.
   *
   * @see setPublicId()
   * @see setSystemId()
   * @see setByteStream()
   * @see setEncoding()
   *///************************************************************************
  FastSAX_InputSource();

  /**//************************************************************************
   * Create an input source with a system identifier.
   *
   * Applications may use @ref setPublicId() to include a public identifier as
   * well, or @ref setEncoding() to specify the character encoding, if known.
   *
   * If the system identifier is a URL, it must be fully resolved.
   *
   * @see setPublicId()
   * @see setSystemId()
   * @see setByteStream()
   * @see setEncoding()
   *
   * @param systemId The system identifier (URI).
   *///************************************************************************
  FastSAX_InputSource(const char * systemId);

  /**//************************************************************************
   * Create a new input source with a byte stream.
   *
   * Application writers may use @ref setSystemId() to provide a base for
   * resolving relative URIs, @ref setPublicId() to include a public
   * identifier, and/or @ref setEncoding() to specify the object's character
   * encoding.
   *
   * @see setPublicId()
   * @see setSystemId()
   * @see setByteStream()
   * @see setEncoding()
   *
   * @param byteStream The raw byte stream containing the document.
   *///************************************************************************
  FastSAX_InputSource(std::istream * byteStream);

  /**//************************************************************************
   * Destructor.
   *///************************************************************************
  virtual ~FastSAX_InputSource();

  /**//************************************************************************
   * Set the public identifier for this input source.
   *
   * The public identifier is always optional: if the application writer
   * includes one, it will be provided as part of the location information.
   *
   * @see getPublicId()
   *
   * @param publicId The public identifier as a string.
   *///************************************************************************
  void setPublicId(const char * publicId);

  /**//************************************************************************
   * Get the public identifier for this input source.
   *
   * @see setPublicId()
   *
   * @return The public identifier, or NULL if none was supplied.
   *///************************************************************************
  const char * getPublicId();

  /**//************************************************************************
   * Set the system identifier for this input source.
   *
   * The system identifier is optional if there is a byte stream, but it is
   * still useful to provide one, since the application can use it to resolve
   * relative URIs and can include it in error messages and warnings (the
   * parser will attempt to open a connection to the URI only if htere is no
   * byte stream specified).
   *
   * If the application knows the character encoding of the object pointed to
   * by the system identifier, it can register the encoding using the @ref
   * setEncoding() method.
   *
   * If the system ID is a URL, it must be fully resolved.
   *
   * @see getSystemId()
   * @see setEncoding()
   *
   * @param systemId The system identifier as a string.
   *///************************************************************************
  void setSystemId(const char * systemId);

  /**//************************************************************************
   * Get the system identifier for this input source.
   *
   * The @ref getEncoding() method will return the character encoding of the
   * object pointed to, or NULL if unknown.
   *
   * If the system ID is a URL, it will be fully resolved.
   *
   * @see setSystemId()
   * @see getEncoding()
   *
   * @return The system identifier.
   *///************************************************************************
  const char * getSystemId();

  /**//************************************************************************
   * Set the byte stream for this input source.
   *
   * The SAX parser will use a byte stream in preference to opening a URI
   * connection itself.
   *
   * If the application knows the character encoding of the byte stream, it
   * should set it the @ref setEncoding() method.
   *
   * @see getByteStream()
   * @see setEncoding()
   * @see getEncoding()
   *
   * @param byteStream A byte stream containing an XML document or other
   *                   entity.
   *///************************************************************************
  void setByteStream(std::istream * byteStream);

  /**//************************************************************************
   * Get the byte stream for this input source.
   *
   * The @ref getEncoding() method will return the character encoding for this
   * byte stream, or NULL if unknown.
   *
   * @see setByteStream()
   * @see getEncoding()
   *
   * @return The byte stream, or NULL if none was supplied.
   *///************************************************************************
  std::istream * getByteStream();

  /**//************************************************************************
   * Set the character encoding, if known.
   *
   * The encoding must be a string acceptable for an XML encoding declaration
   * (see section 4.3.3 of the XML 1.0 recommendation).
   *
   * @see getEncoding()
   * @see setSystemId()
   * @see setByteStream()
   *
   * @param encoding A string describing the character encoding.
   *///************************************************************************
  void setEncoding(const char * encoding);
  
  /**//************************************************************************
   * Get the character encoding for a byte stream or URI.
   *
   * @see setEncoding()
   * @see getSystemId()
   * @see setByteStream()
   * @see getByteStream()
   *
   * @return The encoding, or NULL if none was supplied.
   *///************************************************************************
  const char * getEncoding();
};


#endif

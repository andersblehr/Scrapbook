#ifndef _FAST_GENERICTOKENIZER_H
#define _FAST_GENERICTOKENIZER_H
/*****************************************************************************
 * Fast_GenericTokenizer.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: Fast_GenericTokenizer.h,v 1.9 2001/02/06 10:46:39 ablehr Exp $
 * $Log: Fast_GenericTokenizer.h,v $
 * Revision 1.9  2001/02/06 10:46:39  ablehr
 * - Fast_LogManager split into singleton Fast_LogManager and module/class
 *   specific Fast_LogHandler.  Cf. class documentation for changes.
 * - Fast_Tokenizer::PutAlternate() renamed to Fast_Tokenizer::Put().
 * - Fast_Exception constructor changed to take variable parameter list for
 *   accompanying message.
 *
 * Revision 1.8  2000/12/07 13:49:44  ablehr
 * - Added support for 64 bit values to Fast_Tokenizer::AsNumber()
 * - Fixed bug in Fast_GenericTokenizer::IsNumber()
 *
 * Revision 1.7  2000/11/29 15:08:57  ablehr
 * Reorganized and configurized.
 *
 * Revision 1.4  2000/11/29 10:17:29  ablehr
 * Added CVS log to file headers.
 *
 *****************************************************************************/

#include "Fast_Tokenizer.h"


/**//*************************************************************************
 * Fast_GenericTokenizer implements the same tokenizing functionality that was
 * previously implemented and reimplemented in various FAST indexers and query
 * parsers.  It does this by subclassing @ref Fast_Tokenizer and
 * reimplementing the @ref DetermineTokenType() and @ref Reset() methods.
 *
 * @see Fast_Tokenizer
 *
 * @author  Anders Blehr
 * @version $Id: Fast_GenericTokenizer.h,v 1.9 2001/02/06 10:46:39 ablehr Exp $
 *///*************************************************************************
class Fast_GenericTokenizer : public Fast_Tokenizer
{
protected:
  /**//************************************************************************
   * Determines the token type of the character currently being tokenized.  If
   * the current character is a word character, it is examined again to find
   * out if it's an ideographic character.  For ideographic characters, every
   * consecutive pair of characters is indexed as a word.  This is done by
   * having DetermineTokenType() return a "dummy" word separator token type
   * whenever two ideographic characters have been encountered.
   *
   * @see Reset
   *
   * @return The token type of the character currently being tokenized.
   *///************************************************************************
  virtual int DetermineTokenType();

  /**//************************************************************************
   * In addition to calling the Reset() method of the base class @ref
   * Fast_Tokenizer, Reset() checks if we're between bigrams (i.e., pairs of
   * ideographic characters), and if so, backsteps one character to obtain the
   * overlapping bigram.  Backstepping is done in both the UCS-4 and UTF-8
   * buffers.
   *///************************************************************************
  virtual void Reset();

public:
  /**//************************************************************************
   * Creates an instance with no token listener.  Cf. @ref
   * Fast_Tokenizer::Fast_Tokenizer.
   *///************************************************************************
  Fast_GenericTokenizer() :
    Fast_Tokenizer() {}

  /**//************************************************************************
   * Creates an instance with a token listener.  Cf. @ref
   * Fast_Tokenizer::Fast_Tokenizer.
   *///************************************************************************
  Fast_GenericTokenizer(Fast_TokenListener * tokenListener) :
    Fast_Tokenizer(tokenListener) {}

  /**//************************************************************************
   * Destructor.  Does nothing in particular; all clean-up is handled by the
   * destructor of the base class @ref Fast_Tokenizer.
   *///************************************************************************
  virtual ~Fast_GenericTokenizer() {}

  /**//************************************************************************
   * Returns true if the current token is a number.  Instead of using the
   * token type to determine if the token is a number (too cumbersome to set
   * the token type correctly as long as numbers are valid word characters),
   * all characters in the token are examined to find out if they represent
   * numbers.
   *
   * @return True if all characters in the current token are numbers; false
   *         otherwise.
   *///************************************************************************
  virtual bool IsNumber() const;
};

#endif

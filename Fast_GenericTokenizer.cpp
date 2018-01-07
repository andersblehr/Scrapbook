/*****************************************************************************
 * Fast_GenericTokenizer.cpp
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: Fast_GenericTokenizer.cpp,v 1.12 2001/02/06 10:46:39 ablehr Exp $
 * $Log: Fast_GenericTokenizer.cpp,v $
 * Revision 1.12  2001/02/06 10:46:39  ablehr
 * - Fast_LogManager split into singleton Fast_LogManager and module/class
 *   specific Fast_LogHandler.  Cf. class documentation for changes.
 * - Fast_Tokenizer::PutAlternate() renamed to Fast_Tokenizer::Put().
 * - Fast_Exception constructor changed to take variable parameter list for
 *   accompanying message.
 *
 * Revision 1.11  2000/12/12 14:05:25  ablehr
 * - Set token type FTOK_SPACE for (white)space characters.
 *
 * Revision 1.10  2000/12/07 13:49:44  ablehr
 * - Added support for 64 bit values to Fast_Tokenizer::AsNumber()
 * - Fixed bug in Fast_GenericTokenizer::IsNumber()
 *
 * Revision 1.9  2000/12/05 09:42:49  ablehr
 * Changed references to fastserver4/src/... to fastserver4/...
 *
 * Revision 1.8  2000/11/29 15:08:57  ablehr
 * Reorganized and configurized.
 *
 * Revision 1.3  2000/11/29 10:17:28  ablehr
 * Added CVS log to file headers.
 *
 *****************************************************************************/

#include <fastserver4/util/unicodeutil.h>

#include "Fast_GenericTokenizer.h"


/*****************************************************************************
 ******* > >  P R O T E C T E D   M E M B E R   F U N C T I O N S  < < *******
 *****************************************************************************/

/*****************************************************************************
 * DetermineTokenType -- Cf. header file for function description.
 *****************************************************************************/
int
Fast_GenericTokenizer::DetermineTokenType()
{
  int tokenType = FTOK_IGNORABLE;

  /* We're only interested in word characters, ideographic or not */
  if (FastS_UnicodeUtil::IsWordChar(*_tokenCharacter))
  {
    if (FastS_UnicodeUtil::IsIdeographicChar(*_tokenCharacter))
    {
      /* We index pairs of ideographic characters as separate words */
      if ((_tokenType == FTOK_BIGRAM) && (_tokenCharacter - _tokenStart == 2))
        /* Set the token type to "null separator" if we have a pair */
        tokenType = FTOK_NULL_SEPARATOR;
      else
        /* Set it to bigram otherwise */
        tokenType = FTOK_BIGRAM;
    }
    else
      tokenType = FTOK_WORD;
  }
  else if (FastS_UnicodeUtil::IsSpaceChar(*_tokenCharacter))
    tokenType = FTOK_SPACE;

  return tokenType;
}


/*****************************************************************************
 * Reset -- Cf. header file for function description.
 *****************************************************************************/
void
Fast_GenericTokenizer::Reset()
{
  /* If we have just indexed an ideographic pair ... */
  if ((_tokenType == FTOK_BIGRAM) && (_nextTokenType == FTOK_NULL_SEPARATOR))
  {
    /* ... move back one character to obtain the "overlapping" pair */
    _tokenCharacter--;
    _UTF8TokenCharacter -= _lastUTF8CharacterWidth;

    /* Set the next token type to be what it really is... */
    _nextTokenType = FTOK_BIGRAM;
  }

  /* Call the Reset() method of the base class */
  this->Fast_Tokenizer::Reset();
}


/*****************************************************************************
 * IsNumber -- Cf. header file for function description.
 *****************************************************************************/
bool
Fast_GenericTokenizer::IsNumber() const
{
  bool     isNumber = true;
  ucs4_t * character;

  /* Only return true if all token characters are digits */
  for (character = _tokenStart; character < _tokenCharacter; character++)
    isNumber = isNumber && FastS_UnicodeUtil::IsDigit(*character);

  return isNumber;
}

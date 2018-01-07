/*****************************************************************************
 * Fast_Tokenizer.cpp
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 *
 * $Id: Fast_Tokenizer.cpp,v 1.13 2001/02/19 11:35:10 ablehr Exp $
 * $Log: Fast_Tokenizer.cpp,v $
 * Revision 1.13  2001/02/19 11:35:10  ablehr
 * - [blush]
 *
 * Revision 1.12  2001/02/19 11:30:03  ablehr
 * - Improved error message when non-number encountered in AsNumber().
 *
 * Revision 1.11  2001/02/06 10:46:39  ablehr
 * - Fast_LogManager split into singleton Fast_LogManager and module/class
 *   specific Fast_LogHandler.  Cf. class documentation for changes.
 * - Fast_Tokenizer::PutAlternate() renamed to Fast_Tokenizer::Put().
 * - Fast_Exception constructor changed to take variable parameter list for
 *   accompanying message.
 *
 * Revision 1.10  2000/12/19 13:36:26  ablehr
 * - Set _C_MB_LEN_MAX to 6 if platform is WIN32, to MB_LEN_MAX otherwise
 *
 * Revision 1.9  2000/12/07 13:49:44  ablehr
 * - Added support for 64 bit values to Fast_Tokenizer::AsNumber()
 * - Fixed bug in Fast_GenericTokenizer::IsNumber()
 *
 * Revision 1.8  2000/12/05 09:42:49  ablehr
 * Changed references to fastserver4/src/... to fastserver4/...
 *
 * Revision 1.7  2000/12/04 11:43:55  ablehr
 * Fixed autoconf bug; added Fast_Tokenizer::SetAlternateEncoding() and Fast_Tokenizer::PutAlternate() methods.
 *
 * Revision 1.6  2000/11/29 15:08:57  ablehr
 * Reorganized and configurized.
 *
 * Revision 1.4  2000/11/29 10:17:29  ablehr
 * Added CVS log to file headers.
 *
 *****************************************************************************/

#include <fastserver4/util/unicodeutil.h>
#include <fastlib/util/hashtable.h>

#include "Fast_Tokenizer.h"


/*****************************************************************************
 ********* > >  P R I V A T E   M E M B E R   F U N C T I O N S  < < *********
 *****************************************************************************/

/*****************************************************************************
 * Initialize -- Cf. header file for function description.
 *****************************************************************************/
void
Fast_Tokenizer::Initialize(Fast_TokenListener * tokenListener)
{
  int UTF8BufferSize = _C_BUFFER_BLOCK_SIZE * _C_MB_LEN_MAX / _C_UCS4_SIZE;

  /* Create a Fast_logHandler instance */
  _logHandler = Fast_LogManager::GetLogHandler("Fast_Tokenizer");

  /* Initialize the FAST Unicode utility */
  FastS_UnicodeUtil::InitTables();

  /* Initialize member variables */
  _propertyHash = new Fast_HashTable<const char *>(_C_PROPERTY_TABLE_SIZE);
  _bufferSize = _C_BUFFER_BLOCK_SIZE;
  _buffer = new ucs4_t[_bufferSize / _C_UCS4_SIZE];
  _UTF8Buffer = new utf8_t[UTF8BufferSize];
  _lowerCaseUCS4Buffer = new ucs4_t[_bufferSize / _C_UCS4_SIZE];
  _lowerCaseUTF8Buffer = new utf8_t[UTF8BufferSize];
  _byteLength = 0;
  _UTF8ByteLength = 0;
  _characterLength = 0;
  _tokenType = FTOK_NONE;
  _nextTokenType = FTOK_NONE;
  _lowerCaseOK = false;
  _synchronized = false;
  _tokenListener = tokenListener;
  strcpy(_alternateEncoding, _C_ENCODING_UNKNOWN);

  /* Point the token listener to the current token (i.e., this tokenizer) */
  if (_tokenListener != NULL)
    _tokenListener->SetToken(this);

  /* Open conversion descriptors between UCS-4 and UTF-8 */
  _cd_UTF8_to_UCS4 = iconv_open(_C_ENCODING_UCS4, _C_ENCODING_UTF8);
  _cd_UCS4_to_UTF8 = iconv_open(_C_ENCODING_UTF8, _C_ENCODING_UCS4);

  /* This conversion descriptor won't be opened until we know the encoding */
  _cd_AlternateEncoding_to_UCS4 = (iconv_t)_C_ICONV_ERROR;
}


/*****************************************************************************
 * ExtendCapacity -- Cf. header file for function description.
 *****************************************************************************/
void
Fast_Tokenizer::ExtendCapacity(int requiredCapacity)
{
  int      UTF8BufferSize;
  ucs4_t * newUCS4Buffer;
  utf8_t * newUTF8Buffer;

  /* Compute UCS-4 and UTF-8 buffer sizes, using the required capacity */
  _bufferSize =
    _C_BUFFER_BLOCK_SIZE * (requiredCapacity / _C_BUFFER_BLOCK_SIZE + 1);
  UTF8BufferSize = _bufferSize * _C_MB_LEN_MAX / _C_UCS4_SIZE;

  /* Allocate memory for the new buffers */
  newUCS4Buffer = new ucs4_t[_bufferSize / _C_UCS4_SIZE];
  newUTF8Buffer = new utf8_t[UTF8BufferSize];
  
  /* Copy existing data from the existing to the new buffers */
  if (_byteLength > 0)
    memcpy(newUCS4Buffer, _buffer, _byteLength);
  if (_UTF8ByteLength > 0)
    memcpy(newUTF8Buffer, _UTF8Buffer, _UTF8ByteLength);

  /* Delete the existing buffers */
  delete [] _buffer;
  delete [] _UTF8Buffer;
  delete [] _lowerCaseUCS4Buffer;
  delete [] _lowerCaseUTF8Buffer;

  /* Replace the existing buffers with the new ones */
  _buffer = newUCS4Buffer;
  _UTF8Buffer = newUTF8Buffer;

  /* Create empty lower case buffers */
  _lowerCaseUCS4Buffer = new ucs4_t[_bufferSize / _C_UCS4_SIZE];
  _lowerCaseUTF8Buffer = new utf8_t[UTF8BufferSize];
}


/*****************************************************************************
 ******* > >  P R O T E C T E D   M E M B E R   F U N C T I O N S  < < *******
 *****************************************************************************/

/*****************************************************************************
 * DetermineTokenType -- Cf. header file for function description.
 *****************************************************************************/
int
Fast_Tokenizer::DetermineTokenType()
{
  int tokenType = FTOK_IGNORABLE;

  /* By default, only word characters are handled */
  if (FastS_UnicodeUtil::IsWordChar(*_tokenCharacter))
    tokenType = FTOK_WORD;
  
  return tokenType;
}


/*****************************************************************************
 * Reset -- Cf. header file for function description.
 *****************************************************************************/
void
Fast_Tokenizer::Reset()
{
  /* Advance pointers and token type to next token */
  _tokenType = _nextTokenType;
  _tokenStart = _tokenCharacter;
  _UTF8TokenStart = _UTF8TokenCharacter;
}


/*****************************************************************************
 ********** > >  P U B L I C   M E M B E R   F U N C T I O N S  < < **********
 *****************************************************************************/

/*****************************************************************************
 * ~Fast_Tokenizer -- Cf. header file for function description.
 *****************************************************************************/
Fast_Tokenizer::~Fast_Tokenizer()
{
  /* Delete the prpoerty hash table */
  delete _propertyHash;

  /* Delete data buffers */
  delete [] _buffer;
  delete [] _UTF8Buffer;
  delete [] _lowerCaseUCS4Buffer;
  delete [] _lowerCaseUTF8Buffer;

  /* Close iconv conversion descriptors */
  iconv_close(_cd_UTF8_to_UCS4);
  iconv_close(_cd_UCS4_to_UTF8);

  /* Only close the alternate conversion descriptor if it's open */
  if (_cd_AlternateEncoding_to_UCS4 != (iconv_t)_C_ICONV_ERROR)
    iconv_close(_cd_AlternateEncoding_to_UCS4);
}


/*****************************************************************************
 ******* > >  P R O T E C T E D   M E M B E R   F U N C T I O N S  < < *******
 *****************************************************************************/

/*****************************************************************************
 * Synchronize -- Cf. header file for function description.
 *****************************************************************************/
void
Fast_Tokenizer::Synchronize()
{
  /* If the data is in an alternate encoding, convert it to UCS-4 */
  if (strcmp(_alternateEncoding, _C_ENCODING_UNKNOWN) != 0)
  {
    Fast_EncodingUtility::Convert(_cd_AlternateEncoding_to_UCS4,
                                  (char *)_UTF8Buffer,
                                  (char *)_buffer,
                                  _UTF8ByteLength,
                                  &_byteLength                  );

    _UTF8ByteLength = 0;
    _characterLength = _byteLength / _C_UCS4_SIZE;
  }

  /* Synchronize UCS-4 and UTF-8 buffers */
  if ((_byteLength == 0) && (_UTF8ByteLength > 0))
  {
    Fast_EncodingUtility::Convert(_cd_UTF8_to_UCS4,
                                  (char *)_UTF8Buffer,
                                  (char *)_buffer,
                                  _UTF8ByteLength,
                                  &_byteLength        );

    _characterLength = _byteLength / _C_UCS4_SIZE;
  }
  else if ((_UTF8ByteLength == 0) && (_byteLength > 0))
    Fast_EncodingUtility::Convert(_cd_UCS4_to_UTF8,
                                  (char *)_buffer,
                                  (char *)_UTF8Buffer,
                                  _byteLength,
                                  &_UTF8ByteLength    );

  /* Initialize pointers */
  _tokenStart = _buffer;
  _tokenCharacter = _buffer;
  _UTF8TokenStart = _UTF8Buffer;
  _UTF8TokenCharacter = _UTF8Buffer;
  _bufferEnd = _tokenStart + _characterLength;

  /* Get initial token type */
  _nextTokenType = DetermineTokenType();
  _tokenType = _nextTokenType;

  /* OK, done, don't do it again... */
  _synchronized = true;
}


/*****************************************************************************
 * InitializeLowerCaseBuffers -- Cf. header file for function description.
 *****************************************************************************/
void
Fast_Tokenizer::InitializeLowerCaseBuffers()
{
  int i;

  /* Obtain lower case UCS-4 buffer by lower casing the UCS-4 buffer */
  for (i = 0; i < _characterLength; i++)
    _lowerCaseUCS4Buffer[i] = FastS_UnicodeUtil::ToLower(_buffer[i]);

  /* Obtain lower case UTF-8 buffer by converting the lower case UCS-4 buffer */
  Fast_EncodingUtility::Convert(_cd_UCS4_to_UTF8,
                                (char *)_lowerCaseUCS4Buffer,
                                (char *)_lowerCaseUTF8Buffer,
                                _byteLength                  );

  /* OK, done, don't do it again... */
  _lowerCaseOK = true;
}


/*****************************************************************************
 ********** > >  P U B L I C   M E M B E R   F U N C T I O N S  < < **********
 *****************************************************************************/

/*****************************************************************************
 * Put -- Cf. header file for function description.
 *****************************************************************************/
void
Fast_Tokenizer::Put(const ucs4_t * UCS4String, int byteLength)
{
  /* Ensure that there is enough room in the buffers for additional data */
  EnsureCapacity(_byteLength + byteLength);

  /* Append the data to the end of the UCS-4 buffer */
  memcpy(_buffer + _characterLength, UCS4String, byteLength);
  
  /* Update the byte and character length member variables */
  _byteLength += byteLength;
  _characterLength = _byteLength / _C_UCS4_SIZE;

  /* Appending implicitly cancels previous lower casing and synchronizing */
  _lowerCaseOK = false;
  _synchronized = false;
}


/*****************************************************************************
 * Put -- Cf. header file for function description.
 *****************************************************************************/
void
Fast_Tokenizer::Put(const utf8_t * UTF8String, int byteLength)
{
  /* Use strlen to obtain the byte length if it's not given */
  if (byteLength == _C_UNKNOWN)
    byteLength = strlen((const char *)UTF8String);

  /* Ensure that there is enough room in the buffers for additional data */
  EnsureCapacity((_UTF8ByteLength + byteLength) * _C_UCS4_SIZE);

  /* Append the data to the end of the UTF-8 buffer */
  memcpy(_UTF8Buffer + _UTF8ByteLength, UTF8String, byteLength);

  /* Update the UTF-8 byte length member variable */
  _UTF8ByteLength += byteLength;

  /* Appending implicitly cancels previous lower casing and synchronizing */
  _lowerCaseOK = false;
  _synchronized = false;
}


/*****************************************************************************
 * Put -- Cf. header file for function description.
 *****************************************************************************/
void
Fast_Tokenizer::Put(const char * encodedString, int byteLength)
{
  /* Append to UTF-8 buffer only if an alternate encoding has been specified */
  if (_alternateEncoding != _C_ENCODING_UNKNOWN)
    Put((const utf8_t *)encodedString, byteLength);
  else
    _logHandler->SetError("Cannot Put() non-UTF-8 and non-UCS-4 data without "
                          "specifying the alternate encoding.  Use "
                          "SetAlternateEncoding() to specify the alternate "
                          "encoding."                                         );
}


/*****************************************************************************
 * SetAlternateEncoding -- Cf. header file for function description.
 *****************************************************************************/
void
Fast_Tokenizer::SetAlternateEncoding(const char * encoding)
{
  /* Close the alternate conversion descriptor if it's already open */
  if (_cd_AlternateEncoding_to_UCS4 != (iconv_t)_C_ICONV_ERROR)
    iconv_close(_cd_AlternateEncoding_to_UCS4);
  
  /* Try to open the conversion descriptor for the desired conversion */
  _cd_AlternateEncoding_to_UCS4 = iconv_open(_C_ENCODING_UCS4, encoding);

  /* Keep the encoding if the conversion descriptor is OK; set error if not */
  if (_cd_AlternateEncoding_to_UCS4 != (iconv_t)_C_ICONV_ERROR)
    strcpy(_alternateEncoding, encoding);
  else
    _logHandler->
      SetError("Conversion from %s to UCS-4 not supported by iconv [%s]\n",
               encoding, strerror(errno));
}


/*****************************************************************************
 * BuildNextToken -- Cf. header file for function description.
 *****************************************************************************/
bool
Fast_Tokenizer::BuildNextToken()
{
  bool tokenOK = false;

  /* If not synchronized, synchronize! */
  if (!_synchronized)
    Synchronize();

  /* Reset token variables by calling the virtual Reset() function */
  Reset();

  /* Only do something if we're not at the end of the UCS-4 buffer */
  if (_tokenStart < _bufferEnd)
  {
    /* There will be a token if we're not at the end of the buffer */
    tokenOK = true;

    /* Move to next character as long as the token type is the same */
    while (_nextTokenType == _tokenType)
    {
      /* Determine the next token type (FTOK_NONE if at end of buffer) */
      if (++_tokenCharacter < _bufferEnd)
        _nextTokenType = DetermineTokenType();
      else
        _nextTokenType = FTOK_NONE;

      /* Determine how many bytes the current UTF-8 character occupies */
      if (~*_UTF8TokenCharacter & 0x80)
        _lastUTF8CharacterWidth = 1;
      else if (~*_UTF8TokenCharacter & 0x20)
        _lastUTF8CharacterWidth = 2;
      else if (~*_UTF8TokenCharacter & 0x10)
        _lastUTF8CharacterWidth = 3;
      else if (~*_UTF8TokenCharacter & 0x08)
        _lastUTF8CharacterWidth = 4;
      else if (~*_UTF8TokenCharacter & 0x04)
        _lastUTF8CharacterWidth = 5;
      else if (~*_UTF8TokenCharacter & 0x02)
        _lastUTF8CharacterWidth = 6;

      /* Move to the next UTF-8 character */
      _UTF8TokenCharacter += _lastUTF8CharacterWidth;
    }
  }
  else
  {
    /* Reset length variables if at end of buffer (means we're done) */
    _byteLength = 0;
    _UTF8ByteLength = 0;
    _characterLength = 0;
  }

  /* Return true if we produced a token, false otherwise */
  return tokenOK;
}


/*****************************************************************************
 * Tokenize -- Cf. header file for function description.
 *****************************************************************************/
void
Fast_Tokenizer::Tokenize()
{
  /* Only tokenize if we have a token listener (set error otherwise) */
  if (_tokenListener != NULL)
    /* Call the OnToken() method of the token listener while more tokens */
    while (BuildNextToken())
      _tokenListener->OnToken();
  else
    _logHandler->SetError("Cannot call Tokenize() without token listener.");
}


/*****************************************************************************
 * AsUCS4 -- Cf. header file for function description.
 *****************************************************************************/
char *
Fast_Tokenizer::AsUCS4(int * byteLength)
{
  /* Set the byteLength return variable if not NULL */
  if (byteLength != NULL)
    *byteLength = (_tokenCharacter - _tokenStart) * _C_UCS4_SIZE;

  /* Return a pointer to the current token as UCS-4 */
  return (char *)_tokenStart;
}


/*****************************************************************************
 * AsUTF8 -- Cf. header file for function description.
 *****************************************************************************/
char *
Fast_Tokenizer::AsUTF8(int * byteLength)
{
  /* Set the byteLength return variable if not NULL */
  if (byteLength != NULL)
    *byteLength = _UTF8TokenCharacter - _UTF8TokenStart;

  /* Return a pointer to the current token as UTF-8 */
  return (char *)_UTF8TokenStart;
}


/*****************************************************************************
 * AsLowerCaseUCS4 -- Cf. header file for function description.
 *****************************************************************************/
char *
Fast_Tokenizer::AsLowerCaseUCS4(int * byteLength)
{
  /* Initialize lower case buffers if it hasn't already been done */
  if (!_lowerCaseOK)
    InitializeLowerCaseBuffers();

  /* Set the byteLength return variable if not NULL */
  if (byteLength != NULL)
    *byteLength = (_tokenCharacter - _tokenStart) * _C_UCS4_SIZE;

  /* Return a pointer to the current token as lower case UCS-4 */
  return (char *)(_lowerCaseUCS4Buffer + (_tokenStart - _buffer));
}


/*****************************************************************************
 * AsLowerCaseUTF8 -- Cf. header file for function description.
 *****************************************************************************/
char *
Fast_Tokenizer::AsLowerCaseUTF8(int * byteLength)
{
  /* Initialize lower case buffers if it hasn't already been done */
  if (!_lowerCaseOK)
    InitializeLowerCaseBuffers();

  /* Set the byteLength return variable if not NULL */
  if (byteLength != NULL)
    *byteLength = _UTF8TokenCharacter - _UTF8TokenStart;

  /* Return a pointer to the current token as lower case UTF-8 */
  return (char *)(_lowerCaseUTF8Buffer + (_UTF8TokenStart - _UTF8Buffer));
}


/*****************************************************************************
 * AsNumber -- Cf. header file for function description.
 *****************************************************************************/
uint64_t
Fast_Tokenizer::AsNumber()
{
  uint64_t value = 0;
  utf8_t * character = _UTF8TokenStart;
  char *   token;
  int      tokenLength;

  /* Convert to number if token is numeric; set error otherwise */
  if (IsNumber())
  {
    while (character < _UTF8TokenCharacter)
    {
      value *= 10;
      value += *(char *)character - '0';
      character++;
    }
  }
  else
  {
    tokenLength = GetByteLengthAsUTF8();
    token = new char[tokenLength + 1];
    strncpy(token, (char *)_UTF8TokenStart, tokenLength);
    token[tokenLength] = '\0';

    _logHandler->
      SetWarning("Cannot return non-numeric value \"%s\" as number\n", token);

    delete token;
  }

  return value;
}

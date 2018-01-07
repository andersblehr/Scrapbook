#ifndef _FAST_TOKENIZER_H
#define _FAST_TOKENIZER_H
/*****************************************************************************
 * Fast_Tokenizer.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 *
 * $Id: Fast_Tokenizer.h,v 1.13 2001/02/06 10:46:39 ablehr Exp $
 * $Log: Fast_Tokenizer.h,v $
 * Revision 1.13  2001/02/06 10:46:39  ablehr
 * - Fast_LogManager split into singleton Fast_LogManager and module/class
 *   specific Fast_LogHandler.  Cf. class documentation for changes.
 * - Fast_Tokenizer::PutAlternate() renamed to Fast_Tokenizer::Put().
 * - Fast_Exception constructor changed to take variable parameter list for
 *   accompanying message.
 *
 * Revision 1.12  2001/01/09 12:05:20  ablehr
 * - Made include path to ftutil include files relative to compiler include
 *   path, rather than to the location of tokenizer files.
 *
 * Revision 1.11  2000/12/07 13:49:44  ablehr
 * - Added support for 64 bit values to Fast_Tokenizer::AsNumber()
 * - Fixed bug in Fast_GenericTokenizer::IsNumber()
 *
 * Revision 1.10  2000/12/05 09:43:52  ablehr
 * Cleaned up kdoc comments
 *
 * Revision 1.8  2000/12/04 11:43:55  ablehr
 * Fixed autoconf bug; added Fast_Tokenizer::SetAlternateEncoding() and Fast_Tokenizer::PutAlternate() methods.
 *
 * Revision 1.7  2000/11/29 15:49:15  ablehr
 * Minor (sic) change
 *
 * Revision 1.6  2000/11/29 15:08:57  ablehr
 * Reorganized and configurized.
 *
 * Revision 1.4  2000/11/29 10:17:29  ablehr
 * Added CVS log to file headers.
 *
 *****************************************************************************/

#include <iconv.h>

#include <fastlib/util/hashtable.h>

#include <ftutil/Fast_LogHandler.h>
#include <ftutil/Fast_EncodingUtility.h>

#include "Fast_TokenListener.h"


#define FTOK_NONE                0
#define FTOK_SPACE               (1<<0)
#define FTOK_NULL_SEPARATOR      (1<<1)
#define FTOK_WORD                (1<<2)
#define FTOK_BIGRAM              (1<<3)
#define FTOK_NUMBER              (1<<4)
#define FTOK_DIACRITICON         (1<<5)
#define FTOK_IGNORABLE           (1<<6)

#define _C_BUFFER_BLOCK_SIZE     1024
#define _C_TOKEN_BLOCK_SIZE      256
#define _C_PROPERTY_TABLE_SIZE   32
#define _C_ENCODING_SIZE         32


/**//*************************************************************************
 * Fast_Tokenizer is the base class for all FAST tokenizers.  It implements a
 * generic algorithm for identifying tokens in a text stream.  The text stream
 * may be either UCS-4 or UTF-8.  The internal processing is done using UCS-4.
 *
 * In principle, it should be possible to alter the manner in which the
 * tokenizer identifies and classifies tokens by reimplementing only two
 * methods, namely the @ref DetermineTokenType() and @ref Reset() methods
 * (@ref Fast_GenericTokenizer is an example of how this can be done).  This,
 * however, assumes that you want to reuse the underlying algorithm.  If you
 * don't want to do this, e.g. because you want to wrap a third party
 * tokenizer, practically all methods are reimplementable (i.e., virtual).
 *
 * Normally, Fast_Tokenizer is subclassed, but it is possible to instantiate
 * it, too, in which case you get a very rudimentary tokenizer that only
 * differentiates between words and non-words.
 *
 * @see Fast_TokenListener
 * @see Fast_GenericTokenizer
 *
 * @author  Anders Blehr
 * @version $Id: Fast_Tokenizer.h,v 1.13 2001/02/06 10:46:39 ablehr Exp $
 *///*************************************************************************
class Fast_Tokenizer
{
private:
  /**
   * Hash table that allows the definition of tokenizer properties.
   */
  Fast_HashTable<const char *> * _propertyHash;

  /**//*************************************************************************
   * Common initialization method called from the class' constructors and
   * initializes the instance according to the values of its parameters.
   *
   * @param tokenListener A pointer to the token listener to be used by the
   *                      tokenizer.  If NULL, no token listener is used.
   *///*************************************************************************
  void Initialize(Fast_TokenListener * tokenListener);

  /**//*************************************************************************
   * Extends the capacity of all four data buffers, based on the required
   * capacity (exact or estimated) for the UCS-4 buffers.  The capacity of the
   * UTF-8 buffers is set 50% higher than the UCS-4 capacity.  This is done in
   * order to handle the case where all UCS-4 characters occupy 6 bytes in
   * UTF-8 (which will hardly ever be the case...).  Which is all well
   *
   * @param requiredCapacity The required capacity for the UCS-4 buffers (exact
   *                         or estimated).  The capacity of the UTF-8 buffers
   *                         is set 50% higher to accomodate all 6 byte
   *                         characters.
   *///*************************************************************************
  void ExtendCapacity(int requiredCapacity);

  /**//*************************************************************************
   * Syncronizes the two mixed-case data buffers.  I.e., if the data has been
   * entered (Put()) as UCS-4, the UTF-8 buffer is initialized, and vice versa.
   * In addition, token pointers are (re)initialized.
   *///*************************************************************************
  void Synchronize();

  /**//*************************************************************************
   * Initializes the two lower case buffers.  First, the UCS-4 lower case
   * buffer is filled with data by converting the mixed case UCS-4 buffer to
   * lower case.  Then the lower case UTF-8 buffer is created by converting the
   * lower case UCS-4 buffer to UTF-8.
   *///*************************************************************************
  void InitializeLowerCaseBuffers();

protected:
  /**
   * The size in bytes of the UCS-4 buffers.  The UTF-8 buffers are 50% larger
   * to accommodate the case where all UTF-8 characters are 6 bytes long.
   */
  int _bufferSize;

  /**
   * The mixed case UCS-4 buffer.  The actual tokenizing is done here.
   */
  ucs4_t * _buffer;

  /**
   * Pointer to the first character of the current token.
   */
  ucs4_t * _tokenStart;

  /**
   * Pointer to the character that's currently being tokenized.  When a token
   * has been identified, this pointer points to the first character of the
   * next token.
   */
  ucs4_t * _tokenCharacter;

  /**
   * Points one character past the end of the tokenizable data in @ref _buffer.
   */
  ucs4_t * _bufferEnd;

  /**
   * The mixed case UTF-8 buffer.  Holds the same data as the mixed case UCS-4
   * buffer.
   */
  utf8_t * _UTF8Buffer;

  /**
   * Pointer to the first character of the current token in the mixed case UTF-8
   * buffer.
   */
  utf8_t * _UTF8TokenStart;

  /**
   * Pointer to the character in the mixed case UTF-8 buffer that's currently
   * being tokenized in the mixed case UCS-4 buffer.  When a token has been
   * identified, this pointer points to the first character of the next token.
   */
  utf8_t * _UTF8TokenCharacter;

  /**
   * The lower case UCS-4 buffer.  Used to return lower case UCS-4 tokens.
   */
  ucs4_t * _lowerCaseUCS4Buffer;

  /**
   * The lower case UTF-8 buffer.  Used to return lower case UTF-8 tokens.
   */
  utf8_t * _lowerCaseUTF8Buffer;

  /**
   * The byte length of the tokenizable data in the mixed case UCS-4 buffer.
   */
  int _byteLength;

  /**
   * The byte length of the tokenizable data in the mixed case UTF-8 buffer.
   */
  int _UTF8ByteLength;

  /**
   * The width in bytes of the last tokenized UTF-8 character.  Used for
   * backstepping (i.e., with overlapping bigrams in ideographic text).
   */
  int _lastUTF8CharacterWidth;

  /**
   * The number of tokenizable characters.
   */
  int _characterLength;

  /**
   * The type of the current token.  The token type indicates whether the token
   * is a word, a bigram, a number, space, diacritica, etc.
   */
  int _tokenType;

  /**
   * The token type for the character currently being tokenized.  By definition,
   * a token has been identified when the next token type differs from the
   * current.
   */
  int _nextTokenType;

  /**
   * Flag that indicates whether lower case tokens can be extracted from the
   * lower case buffers.  If false, the lower case buffers are either empty or
   * have not been synchronized with the mixed case buffers, in which case @ref
   * SynchronizeLowerCaseBuffers() must be called before lower case tokens can
   * be returned.
   */
  bool _lowerCaseOK;

  /**
   * Flag that indicates whether the mixed case buffers have been synchronized.
   * If false, @ref Synchronize() must be called before tokenizing can start.
   */
  bool _synchronized;

  /**
   * A pointer to the token listener.  If not NULL, the token listener's @ref
   * OnToken() method is called from @ref Tokenize() for each identified token.
   */
  Fast_TokenListener * _tokenListener;

  /**
   * A pointer to a @ref Fast_LogHandler instance.  Fast_logHandler
   * wraps the FAST logging mechanisms and adds error handling and additional
   * logging functionality.
   */
  Fast_LogHandler *   _logHandler;

  /**
   * iconv conversion descriptor for converting from UTF-8 to UCS-4.  Opened at
   * instantiation and closed at destruction.
   */
  iconv_t _cd_UTF8_to_UCS4;

  /**
   * iconv conversion descriptor for converting from UCS-4 to UTF-8.  Opened at
   * instantiation and closed at destruction.
   */
  iconv_t _cd_UCS4_to_UTF8;

  /**
   * iconv conversion descriptor for converting from an alternate encoding to
   * UCS-4.  Opened in @ref Put() when the input encoding is neither UCS-4 nor
   * UTF-8.  Closed and reopened in @ref Put() if the input encoding changes
   * during tokenizing.  Closed at destruction if opened.
   */
  iconv_t _cd_AlternateEncoding_to_UCS4;

  /**
   * String that holds the current alternate input encoding.  Needed in order
   * to be able to detect when (if) the input encoding chages.
   */
  char _alternateEncoding[_C_ENCODING_SIZE];

  /**//************************************************************************
   * Determines if the buffer needs to be extended to accommodate the
   * given number of bytes.  If it needs to be extended, @ref ExtendCapacity()
   * is called.
   *
   * @param requiredCapacity The required capacity for the UCS-4 buffers (exact
   *                         or estimated).  The capacity of the UTF-8 buffers
   *                         is set 50% higher to accomodate all 6 byte
   *                         characters.
   *///************************************************************************
  void EnsureCapacity(int requiredCapacity)
    { if (requiredCapacity > _bufferSize) ExtendCapacity(requiredCapacity); }

  /**//************************************************************************
   * Determines the token type of the character currently being tokenized.  The
   * default implementation returns FTOK_WORD if the character is a word
   * character, and FTOK_IGNORABLE for all other characters.  Reimplement this
   * method in order to identify more granular token types.
   *
   * @return The token type of the character currently being tokenized.
   *///************************************************************************
  virtual int DetermineTokenType();

  /**//************************************************************************
   * This method is called at the very beginning of @ref BuildNextToken().  It
   * does the necessary resetting of pointers etc. in order to be ready to look
   * for the next token.  Default action is to set @ref _tokenType equal to
   * @ref _nextTokenType, set @ref _tokenStart to point to @ref _tokenCharacter,
   * and set @ref _UTF8TokenStart to point to @ref _UTF8TokenCharacter.
   * Reimplement this method if you need certain things to be done before
   * you're ready to start looking for the next token.
   *///************************************************************************
  virtual void Reset();

public:
  /**//************************************************************************
   * Creates an instance with no token listener.  Only @ref BuildNextToken()
   * can be called; calls to @ref Tokenize() will throw an error exception.
   *///************************************************************************
  Fast_Tokenizer()
    { Initialize(NULL); }

  /**//************************************************************************
   * Creates an instance with a token listener.  Both @ref Tokenize() and @ref
   * BuildNextToken() can be called.
   *
   * @param tokenListener Pointer to the Fast_TokenListener instance to be used
   *                      by the tokenizer.
   *///************************************************************************
  Fast_Tokenizer(Fast_TokenListener * tokenListener)
    { Initialize(tokenListener); }

  /**//************************************************************************
   * Destructor.  Frees allocated memory and closes iconv conversion
   * descriptors.
   *///************************************************************************
  virtual ~Fast_Tokenizer();

  /**//************************************************************************
   * Appends UCS-4 data to the mixed case UCS-4 buffer.  This method should
   * be used to put alternately encoded data.
   *
   * @param   UCS4String  A string of UCS-4 characters.
   * @param   byteLength  The number of bytes in UCS4String to append.
   *///************************************************************************
  virtual void Put(const ucs4_t * UCS4String, int byteLength);

  /**//************************************************************************
   * Appends UTF-8 data to the mixed case UTF-8 buffer.  If an alternate
   * encoding has been set (cf. @ref SetAlternateEncoding()), this method can
   * be used to put the alternately encoded data as well.
   *
   * @param UTF8String A string of UTF-8 (or alternateley encoded) characters.
   * @param byteLength The number of bytes in UTF8String to append.  It
   *                   defaults to _C_UNKNOWN, in which case strlen() is used
   *                   to determine the byte length of UTF8String.  The usage
   *                   of strlen() assumes that UTF8String is zero terminated.
   *///************************************************************************
  virtual void Put(const utf8_t * UTF8String, int byteLength = _C_UNKNOWN);

  /**//************************************************************************
   * Appends alternately encoded data (cf. @ref SetAlternateEncoding()) to the
   * mixed case UTF-8 buffer.  When no more data (i.e., when either @ref
   * Tokenize() or @ref BuildNextToken() is called), this data will be
   * converted to UCS-4 in the mixed case UCS-4 buffer and then be written back
   * to the mixed case UTF-8 buffer as UTF-8 converted from UCS-4.
   * 
   * @param encodedString The encoded data.
   * @param byteLength    The number of bytes in encodedString to append.
   *///************************************************************************
  virtual void Put(const char * encodedString, int byteLength);

  /**//************************************************************************
   * Sets an alternate encoding for input data.  In order to prepare the the
   * tokenizer to receive data in the specified encoding, this method should
   * be called prior to @ref Put()-ting data whenever the input encoding is
   * neither UCS-4 nor UTF-8.  If the type used for the alternately encoded
   * data is (char *), @ref PutAlternate() should be used rather than @ref
   * Put().
   * 
   * @param encoding      The encoding used in the input data.
   *///************************************************************************
  virtual void SetAlternateEncoding(const char * encoding);

  /**//*************************************************************************
   * Builds the next token.  This is done by moving the @ref _tokenCharacter
   * pointer forward to one character past the end of the next token in the
   * mixed case UCS-4 buffer.  The @ref DetermineTokenType() method is called
   * for each character in the buffer, and the end of the next token has been
   * reached when the token type for the current character differs from the
   * token type for the previous.  When the end of the next token has been
   * reached, the @ref _UTF8TokenCharacter pointer is moved one character past
   * the end of the next token in the mixed case UTF-8 buffer.  These pointers
   * are used by the access methods to determine the length of the current
   * token.
   *
   * @return A boolean value indicating whether a new token is available or not.
   *///*************************************************************************
  virtual bool BuildNextToken();

  /**//*************************************************************************
   * Tokenizes the entire contents of the data buffer by calling @ref
   * BuildNextToken() as long as there are more tokens.  For each token, the
   * OnToken() method of the tokenizer's token listener (pointed to by the @ref
   * _tokenListener member variable) is called.  Calling Tokenize() without a
   * token listener (_tokenListener is NULL) causes an error exception to be
   * raised.
   *///*************************************************************************
  virtual void Tokenize();

  /**//*************************************************************************
   * Returns true if the current token has token type FTOK_WORD.
   *
   * @return true if the current token is a word; false otherwise.
   *///*************************************************************************
  virtual inline bool IsWord() const
    { return (_tokenType == FTOK_WORD); }

  /**//*************************************************************************
   * Returns true if the current token has token type FTOK_BIGRAM.
   *
   * @return true if the current token is a bigram; false otherwise.
   *///*************************************************************************
  virtual inline bool IsBigram() const
    { return (_tokenType == FTOK_BIGRAM); }

  /**//*************************************************************************
   * Returns true if the current token has token type FTOK_NUMBER.
   *
   * @return true if the current token is a number; false otherwise.
   *///*************************************************************************
  virtual inline bool IsNumber() const
    { return (_tokenType == FTOK_NUMBER); }

  /**//*************************************************************************
   * Returns true if the current token has token type FTOK_SPACE.
   *
   * @return true if the current token is space; false otherwise.
   *///*************************************************************************
  virtual inline bool IsSpace() const
    { return (_tokenType == FTOK_SPACE); }

  /**//*************************************************************************
   * Returns true if the current token has token type FTOK_IGNORABLE.
   *
   * @return true if the current token is ignorable; false otherwise.
   *///*************************************************************************
  virtual inline bool IsIgnorable() const
    { return (_tokenType == FTOK_IGNORABLE); }

  /**//*************************************************************************
   * Returns a pointer to the current token as UCS-4.
   *
   * @return  A pointer to the current token as UCS-4.
   * @param   byteLength  A pointer to a return parameter that holds the byte
   *                      length of the current token.  Defaults to NULL, in
   *                      which case the byte length is not returned.
   *///*************************************************************************
  virtual char * AsUCS4(int * byteLength = NULL);

  /**//*************************************************************************
   * Returns a pointer to the current token as UTF-8.
   *
   * @return  A pointer to the current token as UTF-8.
   * @param   byteLength  A pointer to a return parameter that holds the byte
   *                      length of the current token.  Defaults to NULL, in
   *                      which case the byte length is not returned.
   *///*************************************************************************
  virtual char * AsUTF8(int * byteLength = NULL);

  /**//*************************************************************************
   * Returns a pointer to the current token as lower case UCS-4.
   *
   * @return  A pointer to the current token as lower case UCS-4.
   * @param   byteLength  A pointer to a return parameter that holds the byte
   *                      length of the current token.  Defaults to NULL, in
   *                      which case the byte length is not returned.
   *///*************************************************************************
  virtual char * AsLowerCaseUCS4(int * byteLength = NULL);

  /**//*************************************************************************
   * Returns a pointer to the current token as lower case UTF-8.
   *
   * @return  A pointer to the current token as lower case UTF-8.
   * @param   byteLength  A pointer to a return parameter that holds the byte
   *                      length of the current token.  Defaults to NULL, in
   *                      which case the byte length is not returned.
   *///*************************************************************************
  virtual char * AsLowerCaseUTF8(int * byteLength = NULL);

  /**//*************************************************************************
   * Checks if the current token is numeric by calling @ref IsNumber() and
   * returns a numeric representation of the token if this is the case;
   * otherwise an error exception is thrown.
   *///*************************************************************************
  virtual uint64_t AsNumber();

  /**//*************************************************************************
   * Adds property with property name and value as given to the property hash
   * (@ref _propertyHash).
   *
   * @param name  The property's name.
   * @param value The property's value.
   *///*************************************************************************
  inline void SetProperty(const char * name, const char * value)
    { _propertyHash->Insert(name, value); }

  /**//*************************************************************************
   * Retrieves the value of the property with the given name from the property
   * hash (@ref _propertyHash).
   *
   * @return The value associated with the property with the given name.
   * @param  name  The property's name.
   *///*************************************************************************
  inline const char * GetProperty(const char * name) const
    { return _propertyHash->Find(name); }

  /**//*************************************************************************
   * Sets the token listener.  Assumes that the tokenListener pointer is not
   * NULL.  Calls to @ref Tokenize() are OK after the token listener has been
   * set.
   *///*************************************************************************
  inline void SetTokenListener(Fast_TokenListener * tokenListener)
    { _tokenListener = tokenListener; _tokenListener->SetToken(this); }

  /**//*************************************************************************
   * Returns a pointer to the token listener.
   *
   * @return A pointer to the token listener.
   *///*************************************************************************
  inline Fast_TokenListener * GetTokenListener() const
    { return _tokenListener; }

  /**//*************************************************************************
   * Returns the token type of the current token.
   *
   * @return The token type of the current token.
   *///*************************************************************************
  virtual inline int GetTokenType()
    { return _tokenType; }

  /**//*************************************************************************
   * Returns the byte length of the current token as UCS-4.
   *
   * @return The byte length of the current token as UCS-4.
   *///*************************************************************************
  virtual inline int GetByteLengthAsUCS4()
    { return ((_tokenCharacter - _tokenStart) * _C_UCS4_SIZE); }

  /**//*************************************************************************
   * Returns the byte length of the current token as UTF-8.
   *
   * @return The byte length of the current token as UTF-8.
   *///*************************************************************************
  virtual inline int GetByteLengthAsUTF8()
    { return _UTF8TokenCharacter - _UTF8TokenStart; }

  /**//*************************************************************************
   * Returns the number of characters in the current token.
   *
   * @return The number of characters in the current token.
   *///*************************************************************************
  virtual inline int GetCharacterLength()
    { return _tokenCharacter - _tokenStart; }
};


#endif

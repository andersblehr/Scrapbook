#ifndef _FAST_TOKENLISTENER_H
#define _FAST_TOKENLISTENER_H
/*****************************************************************************
 * Fast_TokenListener.h
 * 
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 *
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: Fast_TokenListener.h,v 1.6 2001/02/06 10:46:39 ablehr Exp $
 * $Log: Fast_TokenListener.h,v $
 * Revision 1.6  2001/02/06 10:46:39  ablehr
 * - Fast_LogManager split into singleton Fast_LogManager and module/class
 *   specific Fast_LogHandler.  Cf. class documentation for changes.
 * - Fast_Tokenizer::PutAlternate() renamed to Fast_Tokenizer::Put().
 * - Fast_Exception constructor changed to take variable parameter list for
 *   accompanying message.
 *
 * Revision 1.5  2000/11/29 15:08:57  ablehr
 * Reorganized and configurized.
 *
 * Revision 1.3  2000/11/29 10:17:29  ablehr
 * Added CVS log to file headers.
 *
 *****************************************************************************/


/**//*************************************************************************
 * Fast_TokenListener is an abstract class defining the token listener
 * interface that must be implemented by all classes that want to be able to
 * receive tokens through callbacks.  Callbacks are done through the @ref
 * OnToken() method.
 *
 * @see Fast_Tokenizer
 *
 * @author  Anders Blehr
 * @version $Id: Fast_TokenListener.h,v 1.6 2001/02/06 10:46:39 ablehr Exp $
 *///*************************************************************************
class Fast_TokenListener
{
/**//*************************************************************************
 * The @ref Fast_Tokenizer class is declared as a friend, since this allows
 * for the @ref SetToken() method to be called from @ref Fast_Tokenizer.
 *///*************************************************************************
friend class Fast_Tokenizer;

private:
  /**//************************************************************************
   * This method is only called from the constructor of the @ref Fast_Tokenizer
   * class.  It sets the @ref _token member variable to point to the
   * @ref Fast_Tokenizer instance that owns the Fast_TokenListener instance.
   * This is done so that the class that implements the Fast_TokenListener
   * interface has access to the tokenizer access methods in the @ref OnToken()
   * callback member function.
   *///************************************************************************
  inline void SetToken(Fast_Tokenizer * tokenizer) { _token = tokenizer; }

protected:
  /**
   * Pointer to the tokenizer that owns the token listener.  It is given the
   * name _token so that it is more aligned with the names given to the token
   * accessor methods in the @ref Fast_Tokenizer class.
   */
  Fast_Tokenizer * _token;

public:
  /**//************************************************************************
   * This constructor is only called at instantiation of a subclass.  It
   * initializes the @ref _token member variable to NULL.
   *///************************************************************************
  Fast_TokenListener() { _token = NULL; }

  /**//************************************************************************
   * Empty destructor.
   *///************************************************************************
  virtual ~Fast_TokenListener() {}

  /**//************************************************************************
   * Pure virtual definition of the callback function.  Subclasses must
   * implement this function.  Access to the current token is provided through
   * the @ref _token pointer.
   *///************************************************************************
  virtual void OnToken() = 0;
};

#endif

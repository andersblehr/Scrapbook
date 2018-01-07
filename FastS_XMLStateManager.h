#ifndef _FASTS_XMLSTATEMANAGER_H
#define _FASTS_XMLSTATEMANAGER_H
/*****************************************************************************
 * FastS_XMLStateManager.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastS_XMLStateManager.h,v 1.3 2001/02/19 14:04:56 ablehr Exp $
 * $Log: FastS_XMLStateManager.h,v $
 * Revision 1.3  2001/02/19 14:04:56  ablehr
 * - kdoc documentation complete.  Run `make doc'.
 * - Released as 1.0.
 *
 *****************************************************************************/

#include <fastlib/monitor/variablemonitor.h>
#include <fast/fixapi/fixapiconfiguration.h>
#include <ftutil/Fast_LogHandler.h>

#include "FastS_XMLStateStack.h"


/**//*************************************************************************
 * Manage the parse state for the indexer.
 * 
 * Create a new state whenever a new element is encountered in the data file,
 * and make the previous state current the whenever an element ends.  Add
 * mappings that apply to this occurrence of the element to the mapping list
 * maintained by the state.
 *
 * Initialize a new document when the opening tag for the document delimiter
 * element is encountered, and commit the document when the correspoding
 * closing tag is encountered.  Handle the aborting of documents when a parse
 * error has occurred, and keep track of the number of aborted documents.
 *
 * @see FastS_XMLState
 * @see FastS_XMLStateStack
 * @see FastS_XMLMapping
 * @see FastS_XMLMappingList
 * @see FastS_FIXAPI_Configuration
 *
 * @author  Anders Blehr
 * @version $Id: FastS_XMLStateManager.h,v 1.3 2001/02/19 14:04:56 ablehr Exp $
 *///*************************************************************************
class FastS_XMLStateManager
{
protected:
  /**
   * A Fast_LogHandler instance for this class.
   */
  Fast_LogHandler *            _logHandler;

  /**
   * The current state.
   */
  FastS_XMLState *             _state;

  /**
   * Stack containing the states that "enclose" the current state.
   *
   * Whenever a new element begins, the current state is pushed onto the stack
   * and a new state is created and made current.  Whenever an element ends,
   * the current state is deleted, and the previous state is popped from the 
   * stack and made current.
   */
  FastS_XMLStateStack *        _stateStack;

  /**
   * A string containing the name of the element that functions as document
   * delimiter for this set of mapping.  It is needed in order to know when to
   * initiate a new document and when to commit a document that has been fully
   * indexed.
   */
  Fast_String                  _documentDelimiter;

  /**
   * An instance of the FastS_FIXAPI_Configuration class.  This class maintains
   * the index layout as a hierarchy of classes corresponding to the contexts,
   * summary fields, and rank fields that make up the index.  It is used in
   * this class to initiate and commit documents during indexing.
   */
  FastS_FIXAPI_Configuration * _configuration;

  /**
   * An instance of the Fast_VariableMonitor class, which monitors generic
   * variables througout an application for integration with management tools
   * and GUI applications.
   */
  Fast_VariableMonitor *       _statusMonitor;

  /**
   * Generic variable keeping track of the number of documents that have been
   * indexed successfully.
   */
  Fast_IntegerVariable *       _documentsOK;

  /**
   * Generic variable keeping track of the number of documents that have
   * aborted.
   */
  Fast_IntegerVariable *       _documentsAborted;

  /**
   * Flag indicating whether we are in the middle of a document or between
   * documents.
   */
  bool                         _inDocument;

  /**
   * Flag indicating whether the current document has been aborted.
   */
  bool                         _aborted;

public:
  /**//************************************************************************
   * Constructor.
   *
   * Create the state stack and initialize the current state.  Create monitor
   * variables for monitoring the number of successfully indexed vs. aborted
   * documents.
   *
   * @see FastS_FIXAPI_Configuration
   *
   * @param configuration     A pointer to a valid FIXAPI configuration.
   * @param documentDelimiter The name of the element that functions as
   *                          document delimiter for this set of mappings.
   *///************************************************************************  
  FastS_XMLStateManager(FastS_FIXAPI_Configuration * configuration,
                        const char *                 documentDelimiter);

  /**//************************************************************************
   * Destructor.
   *///************************************************************************  
  virtual ~FastS_XMLStateManager();

  /**//************************************************************************
   * Create a new state that has no associated element.
   *
   * This should be done whenever a SAX startDocument event occurs.  This state
   * will never have any associated mappings.
   *
   * @see newState(const char *)
   * @see newState(FastS_XMLMapping *)
   * @see popState()
   * @see FastS_XMLState
   *///************************************************************************  
  void newState();

  /**//************************************************************************
   * Create a new state with an associated element.
   *
   * This state will have as many associated mappings as apply to this
   * occurence of the element, as determined by the set of possible mappings
   * identified by the mapping manager, in combination with the set of
   * attributes and attribute values defined for this occurrence.
   *
   * @see newState()
   * @see newState(FastS_XMLMapping *)
   * @see popState()
   * @see FastS_XMLState
   *
   * @param elementName The name of the element to be associated with the
   *                    state.
   *///************************************************************************  
  void newState(const char * elementName);

  /**//************************************************************************
   * Create a new state with one and only one associated mapping.
   *
   * This type of state is created whenever an attribute's value is to be
   * indexed.  This value is sent to the tokenizer for immediate tokenizing,
   * and the mapping is retrieved from the state whenever tokens are received.
   *
   * @see newState()
   * @see newState(const char *)
   * @see popState()
   * @see FastS_XMLState
   *
   * @param mapping The mapping to associate with the state.
   *///************************************************************************  
  void newState(FastS_XMLMapping * mapping);

  /**//************************************************************************
   * Pop the previous state from the state stack and make it current.
   *
   * This method is invoked from the indexer whenever an element ends (i.e., a
   * SAX endElement event is received), or when the value of an attribute has
   * been indexed.
   *
   * @see newState()
   * @see newState(const char *)
   * @see newState(FastS_XMLMapping *)
   * @see FastS_XMLState
   *///************************************************************************  
  void popState();

  /**//************************************************************************
   * Query if the current state is tokenizable.
   *
   * @return true if the current state is tokenizable; false otherwise.
   *///************************************************************************  
  bool canTokenize();

  /**//************************************************************************
   * Abort the current document.
   *
   * Give a warning that the current document is being aborted, commit whatever
   * has been indexed of the document so far, and increment the number of
   * aborted documents.
   *
   * A document that is aborted may still make it into the index.  In fact, if
   * the parse error that caused the document abort was not severe, the entire
   * document may be intact in the index.  However, if a parse error has
   * occurred, the indexer in no way guarantees that documents in which it
   * occurred will be intact; in most cases, this will not be the case.
   *///************************************************************************  
  void abortDocument();

  /**//************************************************************************
   * Verify that the state stack has been completely unwound and give a warning
   * if this is not the case.
   *
   * This method is called ny the indexer when it reveives notification of SAX
   * endDocument events.
   *///************************************************************************  
  void reset();

  /**//************************************************************************
   * Associate a mapping with the current state.
   *
   * This method is called by the indexer when it determines that a certain
   * mapping for an element applies to a certain occurrence of that element.
   *
   * @param mapping A mapping that is to be associated with the current state.
   *///************************************************************************  
  void addMapping(FastS_XMLMapping * mapping);

  /**//************************************************************************
   * Get the list of mappings that is associated with the current state.
   *
   * This method is called by the indexer whenever it receives a token from the
   * tokenizer.
   *
   * @return A list of mappings, or NULL if no mappings are associated with the
   *         current state.
   *///************************************************************************  
  FastS_XMLMappingList * getMappings();

  /**//************************************************************************
   * Return the number of documents that have been indexed successfully so far.
   *
   * @see getNumDocumentsAborted()
   *
   * @return The number of documents that have been indexed successfully.
   *///************************************************************************
  int getNumDocumentsOK();

  /**//************************************************************************
   * Return the number of documents that have aborted so far.
   *
   * @see getNumDocumentsOK()
   *
   * @return The number of documents that have aborted.
   *///************************************************************************
  int getNumDocumentsAborted();
};


#endif

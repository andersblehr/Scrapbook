/******************************************************************************
 * FastS_XMLStateManager.cpp
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastS_XMLStateManager.cpp,v 1.3 2001/02/19 14:04:56 ablehr Exp $
 * $Log: FastS_XMLStateManager.cpp,v $
 * Revision 1.3  2001/02/19 14:04:56  ablehr
 * - kdoc documentation complete.  Run `make doc'.
 * - Released as 1.0.
 *
 ******************************************************************************/

#include "FastS_XMLStateManager.h"


/*****************************************************************************
 ********** > >  P U B L I C   M E M B E R   F U N C T I O N S  < < **********
 *****************************************************************************/

/*****************************************************************************
 * FastS_XMLStateManager -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLStateManager::FastS_XMLStateManager(FastS_FIXAPI_Configuration * 
                                               configuration,
                                             const char * documentDelimiter)
{
  /* Obtain a Fast_LogHandler instance for this class */
  _logHandler = Fast_LogManager::GetLogHandler("FastS_XMLStateManager");

  /* Initialize member variables */
  _configuration = configuration;
  _documentDelimiter = documentDelimiter;

  /* Create the state stack and initialize the current state */
  _stateStack = new FastS_XMLStateStack();
  _state = NULL;

  /* Create the status monitor and obtain monitor variables */
  _statusMonitor = new Fast_VariableMonitor(Fast_LogManager::GetModuleName());
  _documentsOK = _statusMonitor->NewIntegerVariable("documentsOK", 0);
  _documentsAborted = _statusMonitor->NewIntegerVariable("documentsAborted", 0);

  /* Initialize flags to false */
  _inDocument = false;
  _aborted = false;
}


/*****************************************************************************
 * ~FastS_XMLStateManager -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLStateManager::~FastS_XMLStateManager()
{
  delete _stateStack;
  delete _statusMonitor;
}


/*****************************************************************************
 * newState -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLStateManager::newState()
{
  /* The state should be NULL if we're at the start of an XML file */
  if (_state != NULL)
    _logHandler->SetError("Root-level state already exists, cannot create.");

  /* Create a root-level state and make it the current state */
  _state = new FastS_XMLState();
}


/*****************************************************************************
 * newState -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLStateManager::newState(const char * elementName)
{
  /* Only create a new state if the current document has not aborted */
  if (!_aborted)
  {
    /* Push the current state onto the stack and create a new current state */
    _stateStack->push(_state);
    _state = new FastS_XMLState(elementName);

    /* Start a new document if the element is the document delimiter */
    if (_documentDelimiter == elementName)
    {
      _state->makeDelimiter();
      _configuration->BeginDocument();

      _inDocument = true;
    }
  }
}


/*****************************************************************************
 * newState -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLStateManager::newState(FastS_XMLMapping * mapping)
{
  /* Only create a new state if the current document has not aborted */
  if (!_aborted)
  {
    /* Push the current state onto the stack and create a new current state */
    _stateStack->push(_state);
    _state = new FastS_XMLState(mapping);
  }
}


/*****************************************************************************
 * popState -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLStateManager::popState()
{
  FastS_XMLState * poppedState = _stateStack->pop();

  /* This method should only be called if the current state is non-NULL */
  if (_state != NULL)
  {
    /* Commit document if current state represents the document delimiter */
    if (_state->isDelimiter() && _inDocument && !_aborted)
    {
      _configuration->CommitDocument();
      _documentsOK->Increment();

      _inDocument = false;
    }

    /* Delete the current state, pop and make current the previous state */
    delete _state;
    _state = poppedState;
  }
  else
    _logHandler->SetError("At root-level, cannot pop to previous state.");
}


/*****************************************************************************
 * canTokenize -- Cf. header file for function description.
 *****************************************************************************/
bool
FastS_XMLStateManager::canTokenize()
{
  /* We can tokenize if the document is OK and the state is tokenizable */
  return (!_aborted && _state->isTokenizable());
}


/*****************************************************************************
 * abortDocument -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLStateManager::abortDocument()
{
  /* Only abort if we're in a document and are not already aborted */
  if (_inDocument && !_aborted)
  {
    _logHandler->SetWarning("Comitting aborted document.");

    /* Commit document in its current state and increment aborted counter */
    _configuration->CommitDocument();
    _documentsAborted->Increment();

    /* Set flags */
    _inDocument = false;
    _aborted = true;
  }
}


/*****************************************************************************
 * reset -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLStateManager::reset()
{
  /* This should set the current state to NULL */
  popState();

  /* Give warning and empty the stack if it for some reason is not empty */
  if (!_stateStack->isEmpty())
  {
    if (!_aborted)
      _logHandler->SetWarning("State stack did not unwind completely, "
                              "check message log for SAX messages."    );

    _stateStack->makeEmpty();
  }
}


/*****************************************************************************
 * addMapping -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLStateManager::addMapping(FastS_XMLMapping * mapping)
{
  if (!_aborted)
    _state->addMapping(mapping);
}


/*****************************************************************************
 * getMappings -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLMappingList *
FastS_XMLStateManager::getMappings()
{
  /* Return mappings associated with the state, or NULL if state is NULL */
  return (_state ? _state->getMappings() : NULL);
}


/*****************************************************************************
 * getNumDocumentsOK -- Cf. header file for function description.
 *****************************************************************************/
int
FastS_XMLStateManager::getNumDocumentsOK()
{
  return (int)_documentsOK->GetValue();
}


/*****************************************************************************
 * getNumDocumentsAborted -- Cf. header file for function description.
 *****************************************************************************/
int
FastS_XMLStateManager::getNumDocumentsAborted()
{
  return (int)_documentsAborted->GetValue();
}

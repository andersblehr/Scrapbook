/******************************************************************************
 * FastS_XMLMapping.cpp
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastS_XMLMapping.cpp,v 1.3 2001/02/19 14:04:56 ablehr Exp $
 * $Log: FastS_XMLMapping.cpp,v $
 * Revision 1.3  2001/02/19 14:04:56  ablehr
 * - kdoc documentation complete.  Run `make doc'.
 * - Released as 1.0.
 *
 * Revision 1.2  2001/02/15 14:10:54  ablehr
 * - Bugfix
 *
 ******************************************************************************/

#include "FastS_XMLMapping.h"


/*****************************************************************************
 ********** > >  P U B L I C   M E M B E R   F U N C T I O N S  < < **********
 *****************************************************************************/

/*****************************************************************************
 * FastS_XMLMapping -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLMapping::FastS_XMLMapping(FastS_FIXAPI_Configuration * configuration,
                                   const char *                 element,
                                   const char *                 attribute,
                                   const char *                 ifValue       )
{
  /* Obtain a Fast_LogHandler instance for this class */
  _logHandler = Fast_LogManager::GetLogHandler("FastS_XMLMapping");

  /* Verify that the configuration and element are non-NULL */
  if (configuration == NULL)
    _logHandler->SetError("FIXAPI configuration is NULL, cannot create mapping.");

  if (element == NULL)
    _logHandler->SetError("From-element is NULL, cannot create mapping.");

  /* Initialize member variables */
  _configuration = configuration;
  _element = element;
  _attribute = attribute;
  _ifValue = ifValue;

  /* Determine the mapping type */
  if ((_attribute == "") && (_ifValue == ""))
    _type = _C_MAPPINGTYPE_ELEMENT;
  else if (_ifValue == "")
    _type = _C_MAPPINGTYPE_ATTRIBUTE;
  else
    _type = _C_MAPPINGTYPE_IFVALUE;

  /* Create the context, summary field, and rank field lists */
  _contextList = new Fast_DList();
  _summaryFieldList = new Fast_DList();
  _rankFieldList = new Fast_DList();

  /* Create the corresponding list enumerators (iterators) */
  _contextEnumerator = new Fast_DListEnumerator(*_contextList);
  _summaryFieldEnumerator = new Fast_DListEnumerator(*_summaryFieldList);
  _rankFieldEnumerator = new Fast_DListEnumerator(*_rankFieldList);

  /* Initialize flags to false */
  _hasContexts = false;
  _hasSummaryFields = false;
  _hasRankFields = false;
}


/*****************************************************************************
 * ~FastS_XMLMapping -- Cf. header file for function description.
 *****************************************************************************/
FastS_XMLMapping::~FastS_XMLMapping()
{
  Fast_DListElement * element;

  /* Reset list enumerators */
  _contextEnumerator->Reset();
  _summaryFieldEnumerator->Reset();
  _rankFieldEnumerator->Reset();

  /* Set context pointers to NULL to avoid deleting them when freeing list */
  element = (Fast_DListElement *)_contextEnumerator->GetNext();

  while (element != NULL)
  {
    element->_data = NULL;
    element = (Fast_DListElement *)_contextEnumerator->GetNext();
  }

  /* Set sField pointers to NULL to avoid deleting them when freeing list */
  element = (Fast_DListElement *)_summaryFieldEnumerator->GetNext();

  while (element != NULL)
  {
    element->_data = NULL;
    element = (Fast_DListElement *)_summaryFieldEnumerator->GetNext();
  }

  /* Set rField pointers to NULL to avoid deleting them when freeing list */
  element = (Fast_DListElement *)_rankFieldEnumerator->GetNext();

  while (element != NULL)
  {
    element->_data = NULL;
    element = (Fast_DListElement *)_rankFieldEnumerator->GetNext();
  }

  /* Free lists (not done by the Fast_DList destructor */
  _contextList->FreeList();
  _summaryFieldList->FreeList();
  _rankFieldList->FreeList();

  /* Delete lists */
  delete _contextList;
  delete _summaryFieldList;
  delete _rankFieldList;

  /* Delete list enumerators */
  delete _contextEnumerator;
  delete _summaryFieldEnumerator;
  delete _rankFieldEnumerator;
}


/*****************************************************************************
 * addContext -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLMapping::addContext(const char * catalogName, const char * contextName)
{
  FastS_FIXAPI_Catalog * catalog;
  FastS_FIXAPI_Context * context;
  Fast_DListElement *    element;

  /* Obtain catalog from FIXAPI configuration */
  catalog = _configuration->GetCatalog(catalogName);

  /* Give warning if catalog not found; continue otherwise */
  if (catalog == NULL)
    _logHandler->SetWarning("Unknown catalog: \"%s\".", catalogName);
  else
  {
    /* Obtain context from catalog */
    context = catalog->GetContext(contextName);

    /* Give warning if context not found; add it to list otherwise */
    if (context == NULL)
      _logHandler->SetWarning("Unknown context: \"%s\" (catalog \"%s\").",
                              contextName, catalogName                    );
    else
    {
      element = new Fast_DListElement();
      element->_data = (void *)context;

      _contextList->AddTail(element);

      _hasContexts = true;
    }
  }
}


/*****************************************************************************
 * addSummaryField -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLMapping::addSummaryField(const char * summaryClassName,
                                  const char * summaryFieldName )
{
  FastS_FIXAPI_Summary      * summaryClass;
  FastS_FIXAPI_SummaryField * summaryField;
  Fast_DListElement *         element;

  /* Obtain summary class from FIXAPI configuration */
  summaryClass = _configuration->GetSummary(summaryClassName);

  /* Give warning if summary class not found; continue otherwise */
  if (summaryClass == NULL)
    _logHandler->SetWarning("Unknown summary class: \"%s\".", summaryClassName);
  else
  {
    /* Obtain summary field from summary class */
    summaryField = 
      summaryClass->GetSummaryField((const xmlChar *)summaryFieldName);

    /* Give warning if summary field not found; add it to list otherwise */
    if (summaryField == NULL)
      _logHandler->
        SetWarning("Unknown summary field: \"%s\" (summary class \"%s\").",
                   summaryFieldName, summaryClassName                      );
    else
    {
      element = new Fast_DListElement();
      element->_data = (void *)summaryField;

      _summaryFieldList->AddTail(element);

      _hasSummaryFields = true;
    }
  }
}


/*****************************************************************************
 * addRankField -- Cf. header file for function description.
 *****************************************************************************/
void
FastS_XMLMapping::addRankField(const char * rankClassName,
                               const char * rankFieldName )
{
  FastS_FIXAPI_Rank      * rankClass;
  FastS_FIXAPI_RankField * rankField;
  Fast_DListElement *      element;

  /* Obtain rank class from FIXAPI configuration */
  rankClass = _configuration->GetRank(rankClassName);

  /* Give warning if rank class not found; continue otherwise */
  if (rankClass == NULL)
    _logHandler->SetWarning("Unknown rank class: \"%s\".", rankClassName);
  else
  {
    /* Obtain rank field from rank class */
    rankField = rankClass->GetRankField((const xmlChar *)rankFieldName);

    /* Give warning if rank field not found; add it to list otherwise */
    if (rankField == NULL)
      _logHandler->
        SetWarning("Unknown rank field: \"%s\" (rank class \"%s\").",
                   rankFieldName, rankClassName                      );
    else
    {
      element = new Fast_DListElement();
      element->_data = (void *)rankField;

      _rankFieldList->AddTail(element);

      _hasRankFields = true;
    }
  }
}


/*****************************************************************************
 * getElement -- Cf. header file for function description.
 *****************************************************************************/
const char *
FastS_XMLMapping::getElement()
{
  /* Return element, or NULL if not set (should never happen...) */
  return (_element != "") ? _element.CString() : NULL;
}


/*****************************************************************************
 * getAttribute -- Cf. header file for function description.
 *****************************************************************************/
const char *
FastS_XMLMapping::getAttribute()
{
  /* Return attribute, or NULL if not set */
  return (_attribute != "") ? _attribute.CString() : NULL;
}


/*****************************************************************************
 * getIfValue -- Cf. header file for function description.
 *****************************************************************************/
const char *
FastS_XMLMapping::getIfValue()
{
  /* Return ifValue, or NULL if not set */
  return (_ifValue != "") ? _ifValue.CString() : NULL;
}


/*****************************************************************************
 * getType -- Cf. header file for function description.
 *****************************************************************************/
int
FastS_XMLMapping::getType()
{
  return _type;
}


/*****************************************************************************
 * getFirstContext -- Cf. header file for function description.
 *****************************************************************************/
FastS_FIXAPI_Context *
FastS_XMLMapping::getFirstContext()
{
  /* Reset enumerator before returning next context */
  _contextEnumerator->Reset();

  return getNextContext();
}


/*****************************************************************************
 * getNextContext -- Cf. header file for function description.
 *****************************************************************************/
FastS_FIXAPI_Context *
FastS_XMLMapping::getNextContext()
{
  /* Return context pointer from next list element, or NULL if none */
  Fast_DListElement * element =
    (Fast_DListElement *)_contextEnumerator->GetNext();

  return element ? (FastS_FIXAPI_Context *)element->_data : NULL;
}


/*****************************************************************************
 * getFirstSummaryField -- Cf. header file for function description.
 *****************************************************************************/
FastS_FIXAPI_SummaryField *
FastS_XMLMapping::getFirstSummaryField()
{
  /* Reset enumerator before returning next summary field */
  _summaryFieldEnumerator->Reset();

  return getNextSummaryField();
}


/*****************************************************************************
 * getNextSummaryField -- Cf. header file for function description.
 *****************************************************************************/
FastS_FIXAPI_SummaryField *
FastS_XMLMapping::getNextSummaryField()
{
  /* Return summary field pointer from next list element, or NULL if none */
  Fast_DListElement * element =
    (Fast_DListElement *)_summaryFieldEnumerator->GetNext();

  return element ? (FastS_FIXAPI_SummaryField *)element->_data : NULL;
}


/*****************************************************************************
 * getFirstRankField -- Cf. header file for function description.
 *****************************************************************************/
FastS_FIXAPI_RankField *
FastS_XMLMapping::getFirstRankField()
{
  /* Reset enumerator before returning next rank field */
  _rankFieldEnumerator->Reset();

  return getNextRankField();
}


/*****************************************************************************
 * getNextRankField -- Cf. header file for function description.
 *****************************************************************************/
FastS_FIXAPI_RankField *
FastS_XMLMapping::getNextRankField()
{
  /* Return rank field pointer from next list element, or NULL if none */
  Fast_DListElement * element =
    (Fast_DListElement *)_rankFieldEnumerator->GetNext();

  return element ? (FastS_FIXAPI_RankField *)element->_data : NULL;
}


/*****************************************************************************
 * hasContexts -- Cf. header file for function description.
 *****************************************************************************/
bool
FastS_XMLMapping::hasContexts()
{
  return _hasContexts;
}


/*****************************************************************************
 * hasSummaryFields -- Cf. header file for function description.
 *****************************************************************************/
bool
FastS_XMLMapping::hasSummaryFields()
{
  return _hasSummaryFields;
}


/*****************************************************************************
 * hasRankFields -- Cf. header file for function description.
 *****************************************************************************/
bool
FastS_XMLMapping::hasRankFields()
{
  return _hasRankFields;
}

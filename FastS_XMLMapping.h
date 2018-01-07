#ifndef _FASTS_XMLMAPPING_H
#define _FASTS_XMLMAPPING_H
/*****************************************************************************
 * FastS_XMLMapping.h
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: FastS_XMLMapping.h,v 1.3 2001/02/19 14:04:56 ablehr Exp $
 * $Log: FastS_XMLMapping.h,v $
 * Revision 1.3  2001/02/19 14:04:56  ablehr
 * - kdoc documentation complete.  Run `make doc'.
 * - Released as 1.0.
 *
 * Revision 1.2  2001/02/15 14:10:54  ablehr
 * - Bugfix
 *
 *****************************************************************************/

#include <fastlib/util/dlist.h>
#include <fastlib/util/string.h>
#include <fast/fixapi/fixapiconfiguration.h>
#include <ftutil/Fast_LogHandler.h>


#define _C_MAPPINGTYPE_ELEMENT    0
#define _C_MAPPINGTYPE_ATTRIBUTE  1
#define _C_MAPPINGTYPE_IFVALUE    2


/**//*************************************************************************
 * Represent a mapping from an XML element to one or more contexts, summary
 * fields, and/or rank fields, and provide access to these.
 *
 * A mapping can be of either of three types - "element": Map unconditionally
 * from the character data of an element to the associated context(s), summary
 * field(s), and/or rank field(s); "attribute": If the specified attribute is
 * defined for the element, map unconditionally from the attribute's value to
 * the associated context(s), summary field(s), and/or rank field(s);
 * "ifValue": Map from the character data of an element to the associated
 * context(s), summary field(s), and/or rank field(s), but only if the
 * specified attribute is defined for the element and has the specified value.
 *
 * The type is determined in the constructor based on which of the parameters
 * are set.
 *
 * A complete mapping from an element/attribute to all of its associated
 * context(s), summary fields(s), and/or rank field(s) is built by the @ref
 * FastS_XMLMappingManager during the parse of the mapping file.  Whenever the
 * mapping file specifies a mapping to a context, summary field, or rank field,
 * an instance of an object corresponding to it is retrieved from the FIXAPI
 * configuration and added to the mapping using one of the add methods.
 *
 * The class offers three boolean methods for determining if the mapping has
 * associated context(s), summary field(s), or rank field(s), and a set of
 * methods for accessing these.
 *
 * @see FastS_XMLMappingManager
 * @see FastS_FIXAPI_Configuration
 * @see FastS_FIXAPI_Context
 * @see FastS_FIXAPI_SummaryField
 * @see FastS_FIXAPI_RankField
 *
 * @author  Anders Blehr
 * @version $Id: FastS_XMLMapping.h,v 1.3 2001/02/19 14:04:56 ablehr Exp $
 *///*************************************************************************
class FastS_XMLMapping
{
protected:
  /**
   * A Fast_LogHandler instance for this class.
   */
  Fast_LogHandler * _logHandler;

  /**
   * A string containing the name of the element associated with the mapping.
   */
  Fast_String _element;

  /**
   * A string containing the name of an attribute associated with the @ref
   * _element.  If it is empty, the mapping type is "element", which means that
   * the character data of the element will be mapped unconditionally.  If it
   * is set, and the @ref _ifValue is empty, the mapping type is "attribute",
   * which means that the attribute's value will be mapped whenever it is
   * defined for the @ref _element.  If it is set and @ref _ifValue is also
   * set, the mapping type is "ifValue", which means that the character data
   * of the @ref _element will be mapped only if the attribute specified here
   * is defined for the @ref _element and has the value specified by @ref
   * _ifValue.
   */
  Fast_String _attribute;

  /**
   * A string specifying the value that @ref _attribute must have for the
   * character data of @ref _element to be mapped.
   */
  Fast_String _ifValue;

  /**
   * An integer representing the mapping type.
   */
  int                          _type;

  /**
   * An instance of the FastS_FIXAPI_Configuration class.  This class maintains
   * the index layout as a hierarchy of classes corresponding to the contexts,
   * summary fields, and rank fields that make up the index.  It is used in
   * this class to obtain FastS_FIXAPI_Context, FastS_FIXAPI_SummaryField, and
   * FastS_FIXAPI_RankField instances correspoding to the context(s), summary
   * field(s), and/or rank field(s) associated with the mapping.  References to
   * these instances are stored in the class, and are retrieved using the
   * appropriate access methods for use during indexing.
   */
  FastS_FIXAPI_Configuration * _configuration;

  /**
   * A list of references to the FastS_FIXAPI_Context instances corresponding
   * to the context(s) associated with the mapping.
   */
  Fast_DList * _contextList;

  /**
   * A list of references to the FastS_FIXAPI_SummaryField instances
   * corresponding to the summary field(s) associated with the mapping.
   */
  Fast_DList * _summaryFieldList;

  /**
   * A list of references to the FastS_FIXAPI_RankField instances corresponding
   * to the rank field(s) associated with the mapping.
   */
  Fast_DList * _rankFieldList;

  /**
   * An enumerator for iterating through the @ref _contextList.  Used by the
   * @ref getFirstContext() and @ref getNextContext() methods.
   */
  Fast_DListEnumerator * _contextEnumerator;

  /**
   * An enumerator for iterating through the @ref _summaryFieldList.  Used by
   * the @ref getFirstSummaryField() and @ref getNextSummaryField() methods.
   */
  Fast_DListEnumerator * _summaryFieldEnumerator;

  /**
   * An enumerator for iterating through the @ref _rankFieldList.  Used by the
   * @ref getFirstRankField() and @ref getNextRankField() methods.
   */
  Fast_DListEnumerator * _rankFieldEnumerator;

  /**
   * Flag indicating whether there is one or more contexts associated with the
   * mapping.
   */
  bool _hasContexts;

  /**
   * Flag indicating whether there is one or more summary fields associated
   * with the mapping.
   */
  bool _hasSummaryFields;

  /**
   * Flag indicating whether there is one or more rank fields associated with
   * the mapping.
   */
  bool _hasRankFields;

public:
  /**//************************************************************************
   * Constructor.
   *
   * Create a new mapping for a given element.  The parameter list determines
   * the mapping type.
   *
   * @see FastS_FIXAPI_Configuration
   *
   * @param configuration A pointer to a valid FIXAPI configuration.
   * @param element       The name of the element to which the mapping applies.
   *                      Cf. the @ref _element member variable.
   * @param attribute     The name of an attribute that is to be used in this
   *                      mapping, if any.  Cf. the @ref _attribute member
   *                      variable.
   * @param ifValue       An attribute value, if any, to be used in this
   *                      mapping.  Cf. the @ref _ifValue member variable.
   *///************************************************************************  
  FastS_XMLMapping(FastS_FIXAPI_Configuration * configuration,
                   const char *                 element,
                   const char *                 attribute = NULL,
                   const char *                 ifValue = NULL   );

  /**//************************************************************************
   * Destructor.
   *///************************************************************************  
  virtual ~FastS_XMLMapping();

  /**//************************************************************************
   * Map to a context.
   *
   * The FastS_FIXAPI_Context instance representing the context is looked up in
   * the FIXAPI configuration using the context and catalog names.  If the
   * context or the catalog does not exist in the configuration, an warning is
   * given.
   *
   * @see FastS_FIXAPI_Context
   * @see FastS_FIXAPI_Catalog
   * @see setSummaryField()
   * @see setRankField()
   *
   * @param contextName The name of the context.
   * @param catalogName The name of the catalog that the context belongs to.
   *///************************************************************************  
  void addContext(const char * contextName, const char * catalogName);

  /**//************************************************************************
   * Map to a summary field.
   *
   * The FastS_FIXAPI_SummaryField instance representing the summary field is
   * looked up in the FIXAPI configuration using the summary field and summary
   * class names.  If the summary field or the summary class does not exist in
   * the configuration, an warning is given.
   *
   * @see FastS_FIXAPI_SummaryField
   * @see FastS_FIXAPI_Summary
   * @see setContext()
   * @see setRankField()
   *
   * @param summaryFieldName The name of the summary field.
   * @param summaryClassName The name of the summary class that the summary
   *                         field belongs to.
   *///************************************************************************  
  void addSummaryField(const char * summaryFieldName,
                       const char * summaryClassName);

  /**//************************************************************************
   * Map to a rank field.
   *
   * The FastS_FIXAPI_RankField instance representing the rank field is looked
   * up in the FIXAPI configuration using the rank field and rank class names.
   * If the rank field or the rank class does not exist in the configuration,
   * an warning is given.
   *
   * @see FastS_FIXAPI_RankField
   * @see FastS_FIXAPI_Rank
   * @see setContext()
   * @see setSummaryField()
   *
   * @param rankFieldName The name of the rank field.
   * @param rankClassName The name of the rank class that the rank field
   *                      belongs to.
   *///************************************************************************  
  void addRankField(const char * rankFieldName, const char * rankClassName);

  /**//************************************************************************
   * Return the name of the element to which the mapping applies.
   *
   * @see getAttribute()
   * @see getIfValue()
   *
   * @return The name of the element as a string.
   *///************************************************************************  
  const char * getElement();

  /**//************************************************************************
   * Return the name of the attribute associated with the mapping, if any.
   *
   * @see getElement()
   * @see getIfValue()
   *
   * @return The name of the attribute as a string, or NULL if no attribute is
   *         associated with the mapping.
   *///************************************************************************  
  const char * getAttribute();

  /**//************************************************************************
   * Return the attribute value associated with the mapping, if any.
   *
   * @see getElement()
   * @see getAttribute()
   *
   * @return The attribute value as a string, or NULL if no attribute value is
   *         associated with the mapping.
   *///************************************************************************  
  const char * getIfValue();

  /**//************************************************************************
   * Return the mapping type.
   *
   * @return An integer representing the mapping type.
   *///************************************************************************  
  int getType();

  /**//************************************************************************
   * Obtain a pointer to the first context in the list of contexts associated
   * with the mapping.
   *
   * @see FastS_FIXAPI_Context
   * @see getNextContext()
   *
   * @return A pointer to the first context in the context list, or NULL if no
   *         contexts are associated with the mapping.
   *///************************************************************************  
  FastS_FIXAPI_Context * getFirstContext();

  /**//************************************************************************
   * Obtain a pointer to the next context in the list of contexts associated
   * with the mapping.
   *
   * @see FastS_FIXAPI_Context
   * @see getFirstContext()
   *
   * @return A pointer to the next context in the context list, or NULL if no
   *         more contexts are associated with the mapping.
   *///************************************************************************  
  FastS_FIXAPI_Context * getNextContext();

  /**//************************************************************************
   * Obtain a pointer to the first summary field in the list of summary fields
   * associated with the mapping.
   *
   * @see FastS_FIXAPI_SummaryField
   * @see getNextSummaryField()
   *
   * @return A pointer to the first summary field in the summary field list, or
   *         NULL if no summary fields are associated with the mapping.
   *///************************************************************************  
  FastS_FIXAPI_SummaryField * getFirstSummaryField();

  /**//************************************************************************
   * Obtain a pointer to the next summary field in the list of summary fields
   * associated with the mapping.
   *
   * @see FastS_FIXAPI_SummaryField
   * @see getFirstSummaryField()
   *
   * @return A pointer to the next summary field in the summary field list, or
   *         NULL if no more summary fields are associated with the mapping.
   *///************************************************************************  
  FastS_FIXAPI_SummaryField * getNextSummaryField();

  /**//************************************************************************
   * Obtain a pointer to the first rank field in the list of rank fields
   * associated with the mapping.
   *
   * @see FastS_FIXAPI_RankField
   * @see getNextRankField()
   *
   * @return A pointer to the first rank field in the rank field list, or NULL
   *         if no rank fields are associated with the mapping.
   *///************************************************************************  
  FastS_FIXAPI_RankField * getFirstRankField();

  /**//************************************************************************
   * Obtain a pointer to the next rank field in the list of rank fields
   * associated with the mapping.
   *
   * @see FastS_FIXAPI_RankField
   * @see getFirstRankField()
   *
   * @return A pointer to the next rank field in the rank field list, or NULL
   *         if no more rank fields are associated with the mapping.
   *///************************************************************************  
  FastS_FIXAPI_RankField * getNextRankField();

  /**//************************************************************************
   * Determine whether the mapping has associated contexts.
   *
   * @return true if the mapping has associated contexts; false otherwise.
   *///************************************************************************  
  bool hasContexts();

  /**//************************************************************************
   * Determine whether the mapping has associated summary fields.
   *
   * @return true if the mapping has associated summary fields; false
   *         otherwise.
   *///************************************************************************  
  bool hasSummaryFields();

  /**//************************************************************************
   * Determine whether the mapping has associated rank fields.
   *
   * @return true if the mapping has associated rank fields; false otherwise.
   *///************************************************************************  
  bool hasRankFields();
};


#endif

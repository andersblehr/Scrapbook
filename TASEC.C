/****************************************************************************
*
*  File Name        : TASEC.C
*                     
*  Description      : Window instance management APIs
*
*  Public Functions : _TaSecUserProfile
*
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/13/95  AB           Created.
*
****************************************************************************/

#ifdef DTA_OS2_APP
#define CTA_DLL_NAME "TASECO"
#endif

/****************************************************************************
*  #include Files
****************************************************************************/

#define  DTA_ERR_INCL

#include <tasarch.h>
#include "tasec.h"

/****************************************************************************
*  #define Constants
****************************************************************************/

/****************************************************************************
*  #define Macros
****************************************************************************/

/****************************************************************************
*  Global variables for this source file
****************************************************************************/

/****************************************************************************
*  Internal function prototypes
****************************************************************************/


/****************************************************************************
*                 P U B L I C - F U N C T I O N S
****************************************************************************/

/****************************************************************************
*
*  Function         : _TaSecUserProfile
*                     
*  Description      : Returns the user profile of the current user.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/13/95  AB           Created.
*
****************************************************************************/

VOID TAENTRYFIX _TaSecUserProfile  ( PTTA_USER_PROFILE        pUserProfile,
                                     PTTA_ABHI                pABHI,
                                     PTTA_CHAR                pszFileName,
                                     INT                      iLineNumber  )
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    
    TaErrFuncStartArch ("_TaSecUserProfile");
    strcpy(pUserProfile->szUserName, "USER0001");
    pUserProfile->fRestrictTaxPayers = TRUE;
    pUserProfile->fSupervisor = TRUE;
    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        CTA_EMPTY_STRING,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaSecUserProfile");

} /* End TaSecUserProfile */


/****************************************************************************
*
*  Function         : _TaSecWindowAccess
*
*  Description      : Returns the name of the window.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/13/95  AB           Created.
*
****************************************************************************/

TTA_WIN_ACC TAENTRYFIX _TaSecWindowAccess  ( PTTA_CHAR  pszWindowName,
                                             PTTA_ABHI  pABHI,
                                             PTTA_CHAR  pszFileName,
                                             INT        iLineNumber  )
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;

    TaErrFuncStartArch ("_TaSecWindowAccess");
    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        CTA_EMPTY_STRING,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaSecWindowAccess");
    return (CTA_SEC_WIN_MODIFY);

} /* End TaSecUserProfile */


/****************************************************************************
*  End of file TASEC.c
****************************************************************************/

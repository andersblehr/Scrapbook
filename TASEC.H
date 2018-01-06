#ifndef DTA_SEC_H
#define DTA_SEC_H
/****************************************************************************
*
*  File Name        : TASEC.H
*
*  Description      : Header file for security APIs.
*
*  Public APIs      : TaSecUserProfile
*  (macros)           TaSecWindowAccess
*
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/13/95  AB           Created.
****************************************************************************/

/****************************************************************************
*  #define Constants
****************************************************************************/

#define CTA_SEC_WIN_MODIFY             0
#define CTA_SEC_WIN_BROWSE             1
#define CTA_SEC_WIN_NO_ACCESS          2


/****************************************************************************
*  #define API's and Public function prototypes
****************************************************************************/

/*----------------------------
    _TaSecUserProfile
----------------------------*/
VOID TAENTRYFIX _TaSecUserProfile ( PTTA_USER_PROFILE pUserProfile,
                                    PTTA_ABHI         pABHI,
                                    PTTA_CHAR         pszFileName,
                                    INT               iLineNumber  );
#define  TaSecUserProfile(pUseProfile) \
        _TaSecUserProfile(pUseProfile, pABHI, __FILE__, __LINE__)



/*----------------------------
    _TaSecWindowAccess
----------------------------*/
SHORT _TaSecWindowAccess ( PTTA_CHAR  pszWindowName,
                           PTTA_ABHI  pABHI,
                           PTTA_CHAR  pszFileName,
                           INT        iLineNumber  );
#define  TaSecWindowAccess(pszWindowName) \
        _TaSecWindowAccess(pszWindowName, pABHI, __FILE__, __LINE__)

/****************************************************************************
*  End of file tasec.h
****************************************************************************/
#endif /* DTA_SEC_H */

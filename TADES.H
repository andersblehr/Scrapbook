#ifndef DTA_DES_H
#define DTA_DES_H
/****************************************************************************
*
*  File Name        : TADES.H
*
*  Description      : Header file for main window APIs.
*
*  Public APIs      : TaDesReadIniFile
*  (macros)           TaDesSetTitle
*                     TaDesWriteIniFile
*
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  04/19/95  AB           Created.
*
****************************************************************************/

/****************************************************************************
*  #define Constants
****************************************************************************/
#define CTA_DES_IDTYPE_EIN          "EIN"
#define CTA_DES_IDTYPE_JNT          "JNT"
#define CTA_DES_IDTYPE_SSN          "SSN"
#define CTA_DES_IDTYPE_TEMP         "TEMP"



/****************************************************************************
*  #define API's and Public function prototypes
****************************************************************************/

/*----------------------------
    _TaDesReadIniFile
----------------------------*/
VOID TAENTRYFIX _TaDesReadIniFile ( PTTA_ABHI           pABHI,
                                    PTTA_CHAR           pszFileName,
                                    INT                 iLineNumber  );

#define  TaDesReadIniFile() \
        _TaDesReadIniFile(pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaDesSetTitle
----------------------------*/
VOID TAENTRYFIX _TaDesSetTitle ( HWND           hHWND,
                                 PTTA_TITLEDATA pstTitleData,
                                 PTTA_ABHI      pABHI,
                                 PTTA_CHAR      pszFileName,
                                 INT            iLineNumber  );

#define  TaDesSetTitle(TITLEDATA) \
        _TaDesSetTitle(CBI_hwnd, TITLEDATA, pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaDesWriteIniFile
----------------------------*/
VOID TAENTRYFIX _TaDesWriteIniFile ( PTTA_ABHI          pABHI,
                                     PTTA_CHAR          pszFileName,
                                     INT                iLineNumber  );

#define  TaDesWriteIniFile() \
        _TaDesWriteIniFile(pABHI, __FILE__, __LINE__)


/****************************************************************************
*  End of file tades.h
****************************************************************************/
#endif /* DTA_DES_H */

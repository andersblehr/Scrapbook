#ifndef DTA_MEN_H
#define DTA_MEN_H
/****************************************************************************
*
*  File Name        : TAMEN.H
*
*  Description      : Header file for TAS Main Menu APIs.
*
*  Public APIs      : TaMenItemCheck
*  (macros)           TaMenItemUncheck
*                     TaMenItemShow
*                     TaMenItemHide
*                     TaMenItemEnable
*                     TaMenItemDisable
*                     TaMenItemAdd
*                     _TaMenActivate
*                     _TaMenPredisplay
*                     TaMenItemSelect
*                     TaMenTaxpayerItemAdd
*                     TaMenTaxpayerItemSelect
*                     TaMenWindowItemAdd
*                     TaMenWindowItemCheck
*                     TaMenWindowItemRemove
*                     TaMenWindowItemSelect
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  02/15/95  SR           Created.
*  04/07/95  AB           Added TaMenWindowItemAdd, -Remove and -Select.
*  04/19/95  AB           Added TaMenTaxpayerItemAdd and -Select.
*  05/04/95  AB           Added TaMenWindowItemCheck
*
****************************************************************************/

/****************************************************************************
*  #define Constants
****************************************************************************/
#define CTA_FUN_NOTES               "TA003MN_FUNCTIONS_NOTES",          8
#define CTA_FUN_NOTES_VIEW          "TA028MI_FUN_NOTES_VIEW",           9
#define CTA_FUN_NOTES_ADD           "TA009MI_FUN_NOTES_ADD",            10
#define CTA_FUN_AUDIT_TRAIL         "TA011MI_FUN_AUDIT_TRAIL",          11

/* These constants are the indices for the dynamic menu functions.     */
/* These do NOT correspond to the respective index in the status list. */
#define CTA_DYN_FUNC_1      0
#define CTA_DYN_FUNC_2      1
#define CTA_DYN_FUNC_3      2
#define CTA_DYN_FUNC_4      3
#define CTA_DYN_FUNC_5      4
#define CTA_DYN_FUNC_6      5
#define CTA_DYN_FUNC_7      6
#define CTA_DYN_FUNC_8      7
#define CTA_DYN_NOTES_ADD   8
#define CTA_DYN_NOTES_VIEW  9
#define CTA_DYN_AUDIT_TRAIL 10

#define CTA_MEN_WINDOW_1    0
#define CTA_MEN_WINDOW_2    1
#define CTA_MEN_WINDOW_3    2
#define CTA_MEN_WINDOW_4    3
#define CTA_MEN_WINDOW_5    4

#define CTA_MEN_TAXPAYER_1  0
#define CTA_MEN_TAXPAYER_2  1
#define CTA_MEN_TAXPAYER_3  2
#define CTA_MEN_TAXPAYER_4  3
#define CTA_MEN_TAXPAYER_5  4



/****************************************************************************
*  #define API's and Public function prototypes
****************************************************************************/

/*----------------------------
    _TaMenHandleDynFuncCall
----------------------------*/
#define TaMenHandleDynFuncCall()                                            \
{                                                                           \
    PTTA_CBK    pfuncUserCbk;                                               \
                                                                            \
    if (CBI_IWApplMsg == CTA_MSG_DYN_FUNC_CALL)                             \
    {                                                                       \
        pfuncUserCbk = (PTTA_CBK)CBI_IWApplParm;                            \
                                                                            \
        (*pfuncUserCbk) ( pEventInfo,                                       \
                          pEAIA,                                            \
                          NULL,                                             \
                          pWesMap,                                          \
                          pWindContextData,                                 \
                          pABHI             );                              \
    }                                                                       \
}


/*----------------------------
    _TaMenItemCheck
----------------------------*/
VOID TAENTRYFIX _TaMenItemCheck ( PTTA_ABHI pABHI,
                                  PTTA_CHAR pszFileName,
                                  INT       iLineNumber,
                                  PTTA_CHAR pszName,
                                  ...);

#define TaMenItemCheck(NAME) \
       _TaMenItemCheck(pABHI,__FILE__,__LINE__,NAME,-1)

/*----------------------------
    _TaMenItemUncheck
----------------------------*/
VOID TAENTRYFIX _TaMenItemUncheck ( PTTA_ABHI pABHI,
                                    PTTA_CHAR pszFileName,
                                    INT       iLineNumber,
                                    PTTA_CHAR pszName,
                                    ...);

#define TaMenItemUncheck(NAME) \
       _TaMenItemUncheck(pABHI,__FILE__,__LINE__,NAME,-1)
/*----------------------------
    _TaMenItemEnable
----------------------------*/
VOID TAENTRYFIX _TaMenItemEnable ( PTTA_ABHI pABHI,
                                   PTTA_CHAR pszFileName,
                                   INT       iLineNumber,
                                   PTTA_CHAR pszName,
                                   ...);

#define TaMenItemEnable(NAME) \
       _TaMenItemEnable(pABHI,__FILE__,__LINE__,NAME,-1)
/*----------------------------
    _TaMenItemDisable
----------------------------*/
VOID TAENTRYFIX _TaMenItemDisable ( PTTA_ABHI pABHI,
                                    PTTA_CHAR pszFileName,
                                    INT       iLineNumber,
                                    PTTA_CHAR pszName,
                                    ...);

#define TaMenItemDisable(NAME) \
       _TaMenItemDisable(pABHI,__FILE__,__LINE__,NAME,-1)
/*----------------------------
    _TaMenItemHide
----------------------------*/
VOID TAENTRYFIX _TaMenItemHide ( PTTA_ABHI pABHI,
                                 PTTA_CHAR pszFileName,
                                 INT       iLineNumber,
                                 PTTA_CHAR pszName,
                                 ...);

#define TaMenItemHide(NAME) \
       _TaMenItemHide(pABHI,__FILE__,__LINE__,NAME,-1)
/*----------------------------
    _TaMenItemShow
----------------------------*/
VOID TAENTRYFIX _TaMenItemShow ( PTTA_ABHI pABHI,
                                 PTTA_CHAR pszFileName,
                                 INT       iLineNumber,
                                 PTTA_CHAR pszName,
                                 ...);

#define TaMenItemShow(NAME) \
       _TaMenItemShow(pABHI,__FILE__,__LINE__,NAME,-1)
/*----------------------------
    _TaMenItemAdd
----------------------------*/
VOID TAENTRYFIX _TaMenItemAdd ( PTTA_CHAR           pszNewItem,
                                PTTA_CBK            pfuncUserCbk,
                                PCALLBACKEVENTINFO  pEventInfo,
                                PEAIA               pEAIA,
                                PTTA_WESMAPNAME     pWesMap,
                                PTTA_VOID           pWindContextData,
                                PTTA_ABHI           pABHI,
                                PTTA_CHAR           pszFileName,
                                INT                 iLineNumber);

#define TaMenItemAdd(NAME, FUNC) \
       _TaMenItemAdd(NAME,FUNC,pEventInfo,pEAIA,pWesMap,pWindContextData,pABHI,__FILE__,__LINE__)


/*----------------------------
    _TaMenActivate
----------------------------*/

VOID TAENTRYFIX _TaMenActivate ( PTTA_WIN_MEN_DATA pstUserMenData);

/*----------------------------
    _TaMenPredisplay
----------------------------*/
VOID TAENTRYFIX _TaMenPredisplay ( PTTA_WIN_MEN_DATA pstUserMenData);

/*----------------------------
    _TaMenMainPredisplay
----------------------------*/
VOID TAENTRYFIX _TaMenMainPredisplay ( FND_HWND WIN_hwnd);


/*----------------------------
    _TaMenItemSelect
----------------------------*/
VOID TAENTRYFIX _TaMenItemSelect ( SHORT     sIndex,
                                   PTTA_VOID pEventInfo,
                                   PTTA_VOID pEAIA,
                                   PTTA_VOID pWesMap,
                                   PTTA_VOID pWindContextData,
                                   PTTA_ABHI pABHI,
                                   PTTA_CHAR pszFileName,
                                   INT       iLineNumber);

#define TaMenItemSelect(NAME) \
       _TaMenItemSelect(NAME,pEventInfo,pEAIA,pWesMap,pWindContextData,pABHI,__FILE__,__LINE__)


/*----------------------------
    _TaMenTaxpayerItemAdd
----------------------------*/
VOID TAENTRYFIX _TaMenTaxpayerItemAdd ( PTTA_CHAR pszName,
                                        PTTA_CHAR pszID,
                                        PTTA_ABHI pABHI,
                                        PTTA_CHAR pszFileName,
                                        INT       iLineNumber  );

#define TaMenTaxpayerItemAdd(NAME, ID) \
       _TaMenTaxpayerItemAdd(NAME, ID, pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaMenTaxpayerItemSelect
----------------------------*/
VOID TAENTRYFIX _TaMenTaxpayerItemSelect ( USHORT       usIndex,
                                           PTTA_CHAR    pszInternalID,
                                           PTTA_CHAR    pszName,
                                           PTTA_ABHI    pABHI,
                                           PTTA_CHAR    pszFileName,
                                           INT          iLineNumber      );

#define TaMenTaxpayerItemSelect(INDEX, ID) \
       _TaMenTaxpayerItemSelect(INDEX, ID, NULL, pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaMenWindowItemAdd
----------------------------*/
VOID TAENTRYFIX _TaMenWindowItemAdd ( HWND      hHWND,
                                      PTTA_ABHI pABHI,
                                      PTTA_CHAR pszFileName,
                                      INT       iLineNumber  );

#define TaMenWindowItemAdd(HWND) \
       _TaMenWindowItemAdd(HWND, pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaMenWindowItemCheck
----------------------------*/
VOID TAENTRYFIX _TaMenWindowItemCheck ( HWND        hActive,
                                        HWND        hPreviouslyActive,
                                        PTTA_ABHI   pABHI,
                                        PTTA_CHAR   pszFileName,
                                        INT         iLineNumber        );

#define TaMenWindowItemCheck(HWND1, HWND2) \
       _TaMenWindowItemCheck(HWND1, HWND2, pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaMenWindowItemRemove
----------------------------*/
VOID TAENTRYFIX _TaMenWindowItemRemove ( HWND      hHWND,
                                         PTTA_ABHI pABHI,
                                         PTTA_CHAR pszFileName,
                                         INT       iLineNumber  );

#define TaMenWindowItemRemove(HWND) \
       _TaMenWindowItemRemove(HWND, pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaMenWindowItemSelect
----------------------------*/
VOID TAENTRYFIX _TaMenWindowItemSelect ( USHORT    usIndex,
                                         PTTA_ABHI pABHI,
                                         PTTA_CHAR pszFileName,
                                         INT       iLineNumber  );

#define TaMenWindowItemSelect(INDEX) \
       _TaMenWindowItemSelect(INDEX, pABHI, __FILE__, __LINE__)

/*----------------------------
    _TaMenNaaAddFunc
-----------------------------/
SHORT TAENTRYFIX _TaMenNaaAddFunc ( USHORT    usIndex,
                                    PTTA_CBK  usNaaFunc );

/****************************************************************************
*  End of file tamen.h
****************************************************************************/
#endif /* DTA_MEN_H */

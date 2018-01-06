#ifndef DTA_WIM_H
#define DTA_WIM_H
/****************************************************************************
*
*  File Name        : TAWIM.H
*
*  Description      : Header file for window instance management APIs.
*
*  Public APIs      : TaWimCascadeWindows
*  (macros)           TaWimClose
*                     TaWimCreateWindowList
*                     TaWimDestroy
*                     TaWimDisable
*                     TaWimEnable
*                     TaWimHandleArchEvents
*                     TaWimMinimize
*                     TaWimMove
*                     TaWimOpen
*                     TaWimQueryActiveHWND
*                     TaWimQueryChanged
*                     TaWimQueryDefaultPosition
*                     TaWimQueryHandle
*                     TaWimQueryState
*                     TaWimQueryWindowList
*                     TaWimRegisterHandle
*                     TaWimRegisterTaskList
*                     TaWimSetChanged
*                     TaWimSetDefaultPositions
*                     TaWimSetFocus
*                     TaWimValidHandle
*                     TaWimQueryAuditTrail
*
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/09/95  AB           Created.
*  04/12/95  SM           Added TaWimQueryAuditTrail.
*  04/19/95  AB           Added TaWimSetPointerType
*
****************************************************************************/

/****************************************************************************
*  #define Constants
****************************************************************************/
#define CTA_WIM_OPEN_MODELESS           0x0000
#define CTA_WIM_OPEN_MODAL              0x0001
#define CTA_WIM_OPEN_DIALOG             0x0002

#define CTA_WIM_POINTER_ARROW           FNDSYSPTR_ARROW
#define CTA_WIM_POINTER_WAIT            FNDSYSPTR_WAIT
#define CTA_WIM_POINTER_TEXT            FNDSYSPTR_TEXT

#define CTA_WIM_NO_WINDOW               CTA_WIM_MAX_WINDOWS + 1

/****************************************************************************
*  Variables
****************************************************************************/
STATIC BOOL     fAccel  = FALSE;


/****************************************************************************
*  #define API's and Public function prototypes
****************************************************************************/

/*----------------------------
    _TaWimAbortClose
----------------------------*/
VOID TAENTRYFIX _TaWimAbortClose ( PTTA_SHORT   psProc );

#define  TaWimAbortClose() \
        _TaWimAbortClose(&CBI_Proc)


/*----------------------------
    _TaWimCascadeWindows
----------------------------*/
VOID TAENTRYFIX _TaWimCascadeWindows ( PTTA_ABHI  pABHI,
                                       PTTA_CHAR  pszFileName,
                                       INT        iLineNumber  );

#define  TaWimCascadeWindows() \
        _TaWimCascadeWindows(pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaWimClose
----------------------------*/
BOOL TAENTRYFIX _TaWimClose ( HWND       hHWND,
                              PTTA_ABHI  pABHI,
                              PTTA_CHAR  pszFileName,
                              INT        iLineNumber  );

#define  TaWimClose(WINDOWHANDLE) \
        _TaWimClose(WINDOWHANDLE, pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaWimCreateWindowList
----------------------------*/
PTTA_WINLIST TAENTRYFIX _TaWimCreateWindowList( HWND      hMainWindowHWND,
                                                PTTA_ABHI pABHI,
                                                PTTA_CHAR pszFileName,
                                                INT       iLineNumber      );

#define  TaWimCreateWindowList() \
        _TaWimCreateWindowList(CBI_hwnd, pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaWimDestroy
----------------------------*/
VOID TAENTRYFIX _TaWimDestroy ( HWND       hHWND,
                                PTTA_SHORT psProc,
                                PTTA_ABHI  pABHI,
                                PTTA_CHAR  pszFileName,
                                INT        iLineNumber  );

#define  TaWimDestroy() \
        _TaWimDestroy(CBI_hwnd, &CBI_Proc, pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaWimDisable
----------------------------*/
VOID TAENTRYFIX _TaWimDisable ( HWND       hHWND,
                                PTTA_ABHI  pABHI,
                                PTTA_CHAR  pszFileName,
                                INT        iLineNumber  );

#define  TaWimDisable(WINDOWHANDLE) \
        _TaWimDisable(WINDOWHANDLE, pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaWimEnable
----------------------------*/
VOID TAENTRYFIX _TaWimEnable ( HWND       hHWND,
                               PTTA_ABHI  pABHI,
                               PTTA_CHAR  pszFileName,
                               INT        iLineNumber  );

#define  TaWimEnable(WINDOWHANDLE) \
        _TaWimEnable(WINDOWHANDLE, pABHI, __FILE__, __LINE__)


/*----------------------------
    TaWimHandleArchEvents
----------------------------*/
#define  TaWimHandleArchEvents()                                              \
{                                                                             \
    PTTA_WINLIST    pstWindowList;                                            \
    PTTA_HWND       pHWND;                                                    \
    PSWP            pSWP;                                                     \
    USHORT          usIndex;                                                  \
    SHORT           i;                                                        \
    HAB             hab;                                                      \
    HACCEL          hAccelMain;                                               \
    STATIC PQMSG    pstQMsg;                                                  \
                                                                              \
    switch (CBI_IWApplMsg)                                                    \
    {                                                                         \
        case WM_ACTIVATE :                                                    \
                                                                              \
            pstWindowList = _TaWimQueryWindowList();                          \
            TaOpsMemAlloc(pHWND, sizeof(HWND));                               \
                                                                              \
            if (CBI_GUImp1)                                                   \
            {                                                                 \
                *pHWND = CBI_hwnd;                                            \
                                                                              \
                TaMsgInterWinPost( pstWindowList->hMainWindowHWND,            \
                                   (PTTA_VOID)pHWND,                          \
                                   CTA_MSG_WIN_RECEIVE_FOCUS );               \
            }                                                                 \
            else                                                              \
                TaMsgInterWinPost( pstWindowList->hMainWindowHWND,            \
                                   NULL,                                      \
                                   CTA_MSG_WIN_LOSE_FOCUS );                  \
                                                                              \
            break;                                                            \
                                                                              \
        case WM_MINMAXFRAME :                                                 \
                                                                              \
            pSWP = (PSWP)CBI_GUImp1;                                          \
            pstWindowList = TaWimQueryWindowList();                           \
            TaWimValidHandle(CBI_hwnd, &usIndex);                             \
                                                                              \
            if (pSWP->fl & SWP_MINIMIZE)                                      \
            {                                                                 \
                for (i = 0; i < pstWindowList->usNumWindows; i++)             \
                    if ((pstWindowList->apstWindow[i]->hOwnerHWND == CBI_hwnd)\
                        && (!pstWindowList->apstWindow[i]->fMinimized) )      \
                        FndWindowHide( pstWindowList->apstWindow[i]->hHWND,   \
                                       (PTTA_FND_ERROR_BLOCK)pABHI );         \
                                                                              \
                pstWindowList->apstWindow[usIndex]->fMinimized = TRUE;        \
            }                                                                 \
            else if (pSWP->fl & SWP_RESTORE)                                  \
            {                                                                 \
                for (i = 0; i < pstWindowList->usNumWindows; i++)             \
                    if ((pstWindowList->apstWindow[i]->hOwnerHWND == CBI_hwnd)\
                        && (!pstWindowList->apstWindow[i]->fMinimized ) )     \
                        FndWindowShow( pstWindowList->apstWindow[i]->hHWND,   \
                                       (PTTA_FND_ERROR_BLOCK)pABHI );         \
                                                                              \
                pstWindowList->apstWindow[usIndex]->fMinimized = FALSE;       \
            }                                                                 \
                                                                              \
        case WM_TRANSLATEACCEL :                                              \
                                                                              \
            fAccel = TRUE;                                                    \
                                                                              \
            pstQMsg = (PQMSG)CBI_GUImp1;                                      \
                                                                              \
            break;                                                            \
                                                                              \
        case WM_CHAR :                                                        \
                                                                              \
            if (fAccel)                                                       \
            {                                                                 \
                pstWindowList = TaWimQueryWindowList();                       \
                                                                              \
                hab = WinQueryAnchorBlock(pstWindowList->hMainWindowHWND);    \
                hAccelMain =                                                  \
                     WinQueryAccelTable(hab,                                  \
                                        pstWindowList->hMainWindowHWND);      \
                                                                              \
                if (WinTranslateAccel(hab, CBI_hwnd, hAccelMain, pstQMsg))    \
                    WinPostMsg( pstWindowList->hMainWindowHWND,               \
                                WM_COMMAND,                                   \
                                (PTTA_VOID)pstQMsg->mp1,                      \
                                (PTTA_VOID)pstQMsg->mp2         );            \
                else                                                          \
                {                                                             \
                    WinPostMsg( pstWindowList->hMainWindowHWND,               \
                                WM_TRANSLATEACCEL,                            \
                                (PTTA_VOID)pstQMsg,                           \
                                (PTTA_VOID)0                    );            \
                                                                              \
                    WinPostMsg( pstWindowList->hMainWindowHWND,               \
                                WM_CHAR,                                      \
                                CBI_GUImp1,                                   \
                                CBI_GUImp2                      );            \
                }                                                             \
                                                                              \
                fAccel = FALSE;                                               \
            }                                                                 \
                                                                              \
            break;                                                            \
    }                                                                         \
}


/*----------------------------
    _TaWimMinimize
----------------------------*/
VOID TAENTRYFIX _TaWimMinimize ( HWND       hHWND,
                                 PTTA_ABHI  pABHI,
                                 PTTA_CHAR  pszFileName,
                                 INT        iLineNumber  );

#define  TaWimMinimize(WINDOWHANDLE) \
        _TaWimMinimize(WINDOWHANDLE, pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaWimMove
----------------------------*/
VOID TAENTRYFIX _TaWimMove ( HWND       hHWND,
                             LONG       lDestX,
                             LONG       lDestY,
                             PTTA_ABHI  pABHI,
                             PTTA_CHAR  pszFileName,
                             INT        iLineNumber  );

#define  TaWimMove(WINDOWHANDLE, DESTX, DESTY) \
        _TaWimMove(WINDOWHANDLE, DESTX, DESTY, pABHI, __FILE__, __LINE__)

/*----------------------------
    _TaWimOpen
----------------------------*/
VOID TAENTRYFIX _TaWimOpen ( PTTA_CHAR  pszWindowName,
                             PTTA_CHAR  pszInstanceName,
                             HWND       hOwnerHWND,
                             PTTA_VOID  pInitData,
                             ULONG      ulFuncCode,
                             PTTA_ABHI  pABHI,
                             PTTA_CHAR  pszFileName,
                             INT        iLineNumber      );

#define  TaWimOpen(WINDOWNAME, INSTANCENAME, INITDATA, FUNCCODE) \
        _TaWimOpen(WINDOWNAME, INSTANCENAME, CBI_hwnd, INITDATA, FUNCCODE, pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaWimQueryActiveHWND
----------------------------*/
HWND TAENTRYFIX _TaWimQueryActiveHWND ();

#define  TaWimQueryActiveHWND() \
        _TaWimQueryActiveHWND()


/*----------------------------
    _TaWimQueryAuditTrail
----------------------------*/
VOID TAENTRYFIX _TaWimQueryAuditTrail ( PTTA_CHAR  pszWindowName,
                                        PTTA_BOOL  fAuditTrailPoss,
                                        PTTA_BOOL  fAuditTrailMand,
                                        PTTA_ABHI  pABHI,
                                        PTTA_CHAR  pszFileName,
                                        INT        iLineNumber      );

#define  TaWimQueryAuditTrail(WINDOWNAME, AUDPOSS, AUDMAND) \
        _TaWimQueryAuditTrail(WINDOWNAME, AUDPOSS, AUDMAND, pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaWimQueryChanged
----------------------------*/
BOOL TAENTRYFIX _TaWimQueryChanged ( HWND       hHWND,
                                     PTTA_ABHI  pABHI,
                                     PTTA_CHAR  pszFileName,
                                     INT        iLineNumber  );

#define  TaWimQueryChanged(WINDOWHANDLE) \
        _TaWimQueryChanged(WINDOWHANDLE, pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaWimQueryDefaultPosition
----------------------------*/
VOID TAENTRYFIX _TaWimQueryDefaultPosition ( PTTA_CHAR   pszWindowName,
                                             PTTA_LONG   plDefaultX,
                                             PTTA_LONG   plDefaultY,
                                             PTTA_ABHI   pABHI,
                                             PTTA_CHAR   pszFileName,
                                             INT         iLineNumber  );

#define  TaWimQueryDefaultPosition(WINDOWNAME, X, Y) \
        _TaWimQueryDefaultPosition(WINDOWNAME, X, Y, pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaWimQueryHandle
----------------------------*/
HWND TAENTRYFIX _TaWimQueryHandle ( PTTA_CHAR  pszWindowName,
                                    PTTA_CHAR  pszInstanceName,
                                    PTTA_ABHI  pABHI,
                                    PTTA_CHAR  pszFileName,
                                    INT        iLineNumber      );

#define  TaWimQueryHandle(WINDOWNAME, INSTANCENAME) \
        _TaWimQueryHandle(WINDOWNAME, INSTANCENAME, pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaWimQueryState
----------------------------*/
CHAR TAENTRYFIX _TaWimQueryState ( HWND       hHWND,
                                   PTTA_ABHI  pABHI,
                                   PTTA_CHAR  pszFileName,
                                   INT        iLineNumber  );

#define  TaWimQueryState(WINDOWHANDLE) \
        _TaWimQueryState(WINDOWHANDLE, pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaWimQueryWindowList
----------------------------*/
PTTA_WINLIST TAENTRYFIX _TaWimQueryWindowList ();

#define  TaWimQueryWindowList() \
        _TaWimQueryWindowList()


/*----------------------------
    _TaWimRegisterHandle
----------------------------*/
VOID TAENTRYFIX _TaWimRegisterHandle ( HWND hHWND );

#define  TaWimRegisterHandle(HWND) \
        _TaWimRegisterHandle(HWND)


/*----------------------------
    _TaWimRegisterTaskList
----------------------------*/
VOID TAENTRYFIX _TaWimRegisterTaskList ( HWND       hHWND,
                                         PTTA_ABHI  pABHI,
                                         PTTA_CHAR  pszFileName,
                                         INT        iLineNumber  );

#define  TaWimRegisterTaskList(HWND) \
        _TaWimRegisterTaskList(HWND, pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaWimSetChanged
----------------------------*/
VOID TAENTRYFIX _TaWimSetChanged ( HWND       hHWND,
                                   PTTA_ABHI  pABHI,
                                   PTTA_CHAR  pszFileName,
                                   INT        iLineNumber  );

#define  TaWimSetChanged(WINDOWHANDLE) \
        _TaWimSetChanged(WINDOWHANDLE, pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaWimSetDefaultPositions
----------------------------*/
VOID TAENTRYFIX _TaWimSetDefaultPositions ( PTTA_ABHI  pABHI,
                                            PTTA_CHAR  pszFileName,
                                            INT        iLineNumber  );

#define  TaWimSetDefaultPositions() \
        _TaWimSetDefaultPositions(pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaWimSetFocus
----------------------------*/
VOID TAENTRYFIX _TaWimSetFocus ( HWND       hHWND,
                                 PTTA_ABHI  pABHI,
                                 PTTA_CHAR  pszFileName,
                                 INT        iLineNumber  );

#define  TaWimSetFocus(WINDOWHANDLE) \
        _TaWimSetFocus(WINDOWHANDLE, pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaWimSetPointerType
----------------------------*/
VOID TAENTRYFIX _TaWimSetPointerType ( SHORT      sPointerType,
                                       HWND       hHWND,
                                       PTTA_ABHI  pABHI,
                                       PTTA_CHAR  pszFileName,
                                       INT        iLineNumber  );

#define  TaWimSetPointerType(POINTERTYPE, WINDOWHANDLE) \
{ \
    _TaWimSetPointerType(POINTERTYPE, WINDOWHANDLE, pABHI, __FILE__, __LINE__); \
    if (POINTERTYPE == CTA_WIM_POINTER_WAIT) \
        WindowPointerMode = FALSE; \
    else \
        WindowPointerMode = TRUE; \
}


/*----------------------------
    _TaWimSetUnchanged
----------------------------*/
VOID TAENTRYFIX _TaWimSetUnchanged ( HWND       hHWND,
                                     PTTA_ABHI  pABHI,
                                     PTTA_CHAR  pszFileName,
                                     INT        iLineNumber  );

#define  TaWimSetUnchanged(WINDOWHANDLE) \
        _TaWimSetUnchanged(WINDOWHANDLE, pABHI, __FILE__, __LINE__)


/*----------------------------
    _TaWimValidHandle
----------------------------*/
BOOL TAENTRYFIX _TaWimValidHandle( HWND        hHWND,
                                   PTTA_USHORT pusWindowIndex );

#define  TaWimValidHandle(WINDOWHANDLE, INDEX) \
        _TaWimValidHandle(WINDOWHANDLE, INDEX)


/****************************************************************************
*  End of file tawim.h
****************************************************************************/
#endif /* DTA_WIM_H */

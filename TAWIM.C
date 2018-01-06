/****************************************************************************
*
*  File Name        : TAWIM.C
*                     
*  Description      : Window instance management APIs
*
*  Public Functions : _TaWimAbortClose
*                     _TaWimCascadeWindows
*                     _TaWimClose
*                     _TaWimCreateWindowList
*                     _TaWimDestroy
*                     _TaWimDisable
*                     _TaWimEnable
*                     _TaWimMinimize
*                     _TaWimMove
*                     _TaWimOpen
*                     _TaWimQueryActiveHWND
*                     _TaWimQueryAuditTrail
*                     _TaWimQueryChanged
*                     _TaWimQueryDefaultPosition
*                     _TaWimQueryHandle
*                     _TaWimQueryState
*                     _TaWimQueryWindowList
*                     _TaWimRegisterHandle
*                     _TaWimRegisterTaskList
*                     _TaWimSetChanged
*                     _TaWimSetDefaultPositions
*                     _TaWimSetFocus
*                     _TaWimSetPointerType
*                     _TaWimSetUnchanged
*                     _TaWimValidHandle
*
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/09/95  AB           Created.
*  04/12/95  SM           Added Profile Table handling and QueryAuditTrail.
*  04/19/95  AB           Added TaWimSetPointerType
*
****************************************************************************/

#ifdef DTA_OS2_APP
#define CTA_DLL_NAME "TAWIMO"
#endif

/****************************************************************************
*  #include Files
****************************************************************************/

#define  DTA_ERR_INCL
#define  DTA_OPS_INCL
#define  DTA_SEC_INCL
#define  DTA_MEN_INCL
#define  DTA_CFE_INCL

#include <tasarch.h>
#include "tawim.h"


/****************************************************************************
*  Global variables for this source file
****************************************************************************/
STATIC PTTA_WINLIST    pstWindowList = NULL;

/****************************************************************************
*  #define Constants
****************************************************************************/
#define CTA_WIM_RET_MSG_SIZE        100

#define CTA_ALIGN_WITH_DESKTOP_X    6
#define CTA_ALIGN_WITH_DESKTOP_Y    83
#define CTA_WIM_CASCADE_OFFSET      18

/****************************************************************************
*  #define Macros
****************************************************************************/

/****************************************************************************
*  Internal function prototypes
****************************************************************************/

STATIC VOID __TaWimOpenModal    ( PTTA_CHAR     pszWindowName,
                                  PTTA_CHAR     pszInstanceName,
                                  HWND          hOwnerHWND,
                                  PTTA_VOID     pInitData,
                                  PTTA_ABHI     pABHI,
                                  PTTA_CHAR     pszFileName,
                                  INT           iLineNumber      );

STATIC BOOL __TaWimWindowExists ( PTTA_CHAR     pstWindowName,
                                  PTTA_CHAR     pstInstanceName,
                                  PTTA_USHORT   pusIndex         );


/****************************************************************************
*                 P U B L I C - F U N C T I O N S
****************************************************************************/

/****************************************************************************
*
*  Function         : _TaWimAbortClose
*                     
*  Description      : Overrides PREDESTROY, thus aborting window shutdown.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  04/10/95  AB           Created.
*
****************************************************************************/

VOID TAENTRYFIX _TaWimAbortClose ( PTTA_SHORT   psProc )
{
    TaErrFuncStartArch ("_TaWimAbortClose");

    /* Override PREDESTROY */
    *psProc = FND_OVERRIDE_DEFAULT;

    TaErrFuncStopArch ("_TaWimAbortClose");
} /* End TaWimAbortClose */



/****************************************************************************
*
*  Function         : _TaWimCascadeWindows
*                     
*  Description      : Cascades all open non-minimized windows
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/09/95  AB           Created.
*
****************************************************************************/

VOID TAENTRYFIX _TaWimCascadeWindows ( PTTA_ABHI  pABHI,
                                       PTTA_CHAR  pszFileName,
                                       INT        iLineNumber  )
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    CHAR      szRetMsg[CTA_WIM_RET_MSG_SIZE];
    USHORT    usIndex;
    SHORT     i = 0;
    LONG      lX;
    LONG      lY;

    TaErrFuncStartArch ("_TaWimCascadeWindows");

    memset(szRetMsg, 0, CTA_WIM_RET_MSG_SIZE);

    if (pstWindowList->usNumWindows)
    {
        /* Initialize X and Y positions */
        lX = CTA_ALIGN_WITH_DESKTOP_X;
        lY = CTA_ALIGN_WITH_DESKTOP_Y;

        /* Compute index of first window to move */
        usIndex = pstWindowList->usNumWindows - (i + 1);

        for (; i < pstWindowList->usNumWindows; i++)
        {
            /* Move each window in the window list */
            TaWimMove( pstWindowList->apstWindow[usIndex]->hHWND,
                       lX + (i * CTA_WIM_CASCADE_OFFSET),
                       lY + (i * CTA_WIM_CASCADE_OFFSET)    );

            /* Use FndWindowActivate() to avoid changing the window list */
            FndWindowActivate(pstWindowList->apstWindow[usIndex]->szWindowName,
                              pstWindowList->apstWindow[usIndex]->szInstanceName,
                              pstWindowList->apstWindow[usIndex]->hOwnerHWND,
                              NULL,
                              NULL,
                              (PTTA_FND_ERROR_BLOCK)pABHI );

            usIndex--;
        }
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaWimCascadeWindows");
} /* End TaWimCascadeWindows */



/****************************************************************************
*
*  Function         : _TaWimClose
*                     
*  Description      : Closes the window and removes it from memory and from
*                     the window list
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/09/95  AB           Created.
*
****************************************************************************/

BOOL TAENTRYFIX _TaWimClose ( HWND       hHWND,
                              PTTA_ABHI  pABHI,
                              PTTA_CHAR  pszFileName,
                              INT        iLineNumber  )
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    CHAR      szRetMsg[CTA_WIM_RET_MSG_SIZE];
    BOOL      fContinue = TRUE;
    BOOL      fModal;
    USHORT    usNumWindows;
    SHORT     i;

    TaErrFuncStartArch ("_TaWimClose");

    memset(szRetMsg, 0, CTA_WIM_RET_MSG_SIZE);

    /* If the window is in the list it is not modal */
    fModal = !TaWimValidHandle(hHWND, NULL);

    /* Destroy the window */
    sRetCode2 = FndWindowDestroy(hHWND, (PTTA_FND_ERROR_BLOCK)pABHI);

    if (sRetCode2)
    {
        if ((sRetCode2 == WIND_WINDOW_STOP_CLOSE) ||
            (sRetCode2 == WIND_CHILD_STOP_CLOSE )    )
        {
            /* Window shutdown stopped by user */
            sRetCode = ETA_WIM_CLOSE_STOPPED;
            sprintf(szRetMsg, "_TaWimClose: Shutdown stopped by user");
        }
        else
        {
            /* FndWindowDestroy failed - log error */
            sRetCode = ETA_WIM_CLOSE_FAILED;
            sprintf(szRetMsg, "_TaWimClose: Unable to close window");
        }
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaWimClose");

    return(!sRetCode);

} /* End TaWimClose */



/****************************************************************************
*
*  Function         : _TaWimCreateWindowList
*                     
*  Description      : Allocates memory and initializes the window list
*                     structure.  Called from PREDISPLAY of the main window.
*
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/13/95  AB           Created.
*
****************************************************************************/
PTTA_WINLIST TAENTRYFIX _TaWimCreateWindowList( HWND      hMainWindowHWND,
                                                PTTA_ABHI pABHI,
                                                PTTA_CHAR pszFileName,
                                                INT       iLineNumber      )
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    CHAR      szRetMsg[CTA_WIM_RET_MSG_SIZE];
    SHORT     i;

    TaErrFuncStartArch ("_TaWimCreateWindowList");

    TaOpsMemAlloc(pstWindowList, sizeof(TTA_WINLIST));

    if (TaErrOK)
    {
        pstWindowList->hMainWindowHWND = hMainWindowHWND;
        pstWindowList->usNumWindows = 0;
        memset(pstWindowList->stWindowLiterals, 0, sizeof(TTA_WIN_LIT_INFO));

        for (i = 0; i < CTA_WIM_MAX_WINDOWS; i++)
            pstWindowList->apstWindow[i] = NULL;
    }
    else
    {
        pstWindowList = NULL;

        sRetCode = ETA_WIM_ERROR;
        sprintf(szRetMsg, "_TaWimCreateWindowList: Could not allocate memory for window list");
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaWimCreateWindowList");

    return(pstWindowList);

} /* End _TaWimCreateWindowList */



/****************************************************************************
*
*  Function         : _TaWimDestroy
*                     
*  Description      : Removes the window from the window list.  Called from
*                     TaErrCbkStop when the callback ID is WINDOW_CLOSE.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/09/95  AB           Created.
*
****************************************************************************/

VOID TAENTRYFIX _TaWimDestroy ( HWND       hHWND,
                                PTTA_SHORT psProc,
                                PTTA_ABHI  pABHI,
                                PTTA_CHAR  pszFileName,
                                INT        iLineNumber  )
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    CHAR      szRetMsg[CTA_WIM_RET_MSG_SIZE];
    BOOL      fContinue = TRUE;
    BOOL      fWindowInList = TRUE;
    USHORT    usIndex;
    USHORT    usNumWindows;
    SHORT     i;

    TaErrFuncStartArch ("_TaWimDestroy");

    memset(szRetMsg, 0, CTA_WIM_RET_MSG_SIZE);

    /* Log a message if the window is not registered in the window list */
    if (!TaWimValidHandle(hHWND, &usIndex))
    {
        sprintf(szRetMsg, "_TaWimDestroy: Window is not in window list");
        fWindowInList = FALSE;
    }

    /* psProc is NULL when calling TaWimDestroy from TaWim */
    if ((psProc) && (fWindowInList))
    {
        /* Close all child windows too */
        usNumWindows = pstWindowList->usNumWindows;
        for (i = usNumWindows - 1; ((i >= 0) && (fContinue)); i--)
            if (pstWindowList->apstWindow[i]->hOwnerHWND == hHWND)
                fContinue = _TaWimClose( pstWindowList->apstWindow[i]->hHWND,
                                         pABHI,
                                         pszFileName,
                                         iLineNumber  );
    }

    /* Continue only if all child windows closed */
    if (fContinue)
    {
        /* Only do this for windows that are in the window list */
        if (fWindowInList)
        {
            /* Remove window from Windows menu on main window */
            TaMenWindowItemRemove(hHWND);

            /* Remove window from window list */
            TaOpsMemFree(pstWindowList->apstWindow[usIndex]);

            /* Shift open windows to the front of the window list */
            for (i = usIndex; i < pstWindowList->usNumWindows - 1; i++)
                pstWindowList->apstWindow[i] =
                        pstWindowList->apstWindow[i + 1];

            pstWindowList->apstWindow[i] = NULL;
            pstWindowList->usNumWindows--;

            if (pstWindowList->usNumWindows)
                /* Set focus to the previously active window */
                _TaWimSetFocus( pstWindowList->apstWindow[0]->hHWND,
                                pABHI,
                                pszFileName,
                                iLineNumber  );
            else
                /* Notify the TaMen class that no window is active */
                _TaMenActivate(NULL);
        }
    }
    else if (psProc)
    {
        /* Stop shutdown of window by overriding PREDESTROY */
        *psProc = FND_OVERRIDE_DEFAULT;
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaWimDestroy");
} /* End TaWimDestroy */



/****************************************************************************
*
*  Function         : _TaWimDisable
*                     
*  Description      : Disables the window
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/09/95  AB           Created.
*
****************************************************************************/

VOID TAENTRYFIX _TaWimDisable ( HWND       hHWND,
                                PTTA_ABHI  pABHI,
                                PTTA_CHAR  pszFileName,
                                INT        iLineNumber  )
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    CHAR      szRetMsg[CTA_WIM_RET_MSG_SIZE];

    TaErrFuncStartArch ("_TaWimDisable");

    memset(szRetMsg, 0, CTA_WIM_RET_MSG_SIZE);

    /* Verify that the window handle is valid */
    if (TaWimValidHandle(hHWND, NULL))
    {
        /* Disable the window */
        sRetCode2 = FndWindowDisable(hHWND, (PTTA_FND_ERROR_BLOCK)pABHI);

        if (sRetCode2)
        {
            /* Disable failed - log error */
            sRetCode = ETA_WIM_DISABLE_FAILED;
            sprintf(szRetMsg, "_TaWimDisable: Unable to disable window");
        }
    }
    else
    {
        /* The window handle is invalid - log error */
        sRetCode = ETA_WIM_INVALID_HANDLE;
        sprintf(szRetMsg, "_TaWimDisable: Invalid window handle");
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaWimDisable");
} /* End TaWimDisable */



/****************************************************************************
*
*  Function         : _TaWimEnable
*                     
*  Description      : Enables the window
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/09/95  AB           Created.
*
****************************************************************************/

VOID TAENTRYFIX _TaWimEnable ( HWND       hHWND,
                               PTTA_ABHI  pABHI,
                               PTTA_CHAR  pszFileName,
                               INT        iLineNumber  )
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    CHAR      szRetMsg[CTA_WIM_RET_MSG_SIZE];

    TaErrFuncStartArch ("_TaWimEnable");

    memset(szRetMsg, 0, CTA_WIM_RET_MSG_SIZE);

    /* Verify that the window handle is valid */
    if (TaWimValidHandle(hHWND, NULL))
    {
        /* Enable the window */
        sRetCode2 = FndWindowEnable(hHWND, (PTTA_FND_ERROR_BLOCK)pABHI);

        if (sRetCode2)
        {
            /* Enable failed - log error */
            sRetCode = ETA_WIM_ENABLE_FAILED;
            sprintf(szRetMsg, "_TaWimEnable: Unable to enable window");
        }
    }
    else
    {
        /* The window handle is invalid - log error */
        sRetCode = ETA_WIM_INVALID_HANDLE;
        sprintf(szRetMsg, "_TaWimEnable: Invalid window handle");
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaWimEnable");
} /* End TaWimEnable */



/****************************************************************************
*
*  Function         : _TaWimMinimize
*                     
*  Description      : Minimizes the window
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/09/95  AB           Created.
*
****************************************************************************/

VOID TAENTRYFIX _TaWimMinimize ( HWND       hHWND,
                                 PTTA_ABHI  pABHI,
                                 PTTA_CHAR  pszFileName,
                                 INT        iLineNumber  )
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    CHAR      szRetMsg[CTA_WIM_RET_MSG_SIZE];

    TaErrFuncStartArch ("_TaWimMinimize");

    memset(szRetMsg, 0, CTA_WIM_RET_MSG_SIZE);

    if (TaWimValidHandle(hHWND, NULL))
    {
        sRetCode2 = FndWindowMinimize(hHWND, (PTTA_FND_ERROR_BLOCK)pABHI);

        if (sRetCode2)
        {
            /* Error returned from FND API */
            sRetCode = ETA_WIM_MINIMIZE_FAILED;
            sprintf(szRetMsg, "_TaWimMinimize: Unable to minimize window");
        }
    }
    else
    {
        /* Invalid window handle */
        sRetCode = ETA_WIM_INVALID_HANDLE;
        sprintf(szRetMsg, "_TaWimMinimize: Invalid window handle");
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaWimMinimize");
} /* End TaWimMinimize */



/****************************************************************************
*
*  Function         : _TaWimMove
*                     
*  Description      : Moves the window to the specified position
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/09/95  AB           Created.
*
****************************************************************************/

VOID TAENTRYFIX _TaWimMove ( HWND       hHWND,
                             LONG       lDestX,
                             LONG       lDestY,
                             PTTA_ABHI  pABHI,
                             PTTA_CHAR  pszFileName,
                             INT        iLineNumber  )
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    CHAR      szRetMsg[CTA_WIM_RET_MSG_SIZE];

    TaErrFuncStartArch ("_TaWimMove");

    memset(szRetMsg, 0, CTA_WIM_RET_MSG_SIZE);

    if (TaWimValidHandle(hHWND, NULL))
    {
        /* Move the window to destination position */
        sRetCode2 = FndWindowMove( hHWND,
                                   lDestX,
                                   lDestY,
                                   (PTTA_FND_ERROR_BLOCK)pABHI );

        if (sRetCode2)
        {
            /* Error returned from FND API */
            sRetCode = ETA_WIM_MOVE_FAILED;
            sprintf(szRetMsg, "_TaWimMove: Unable to move window");
        }
    }
    else
    {
        /* Invalid window handle */
        sRetCode = ETA_WIM_INVALID_HANDLE;
        sprintf(szRetMsg, "_TaWimMove: Invalid window handle");
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaWimMove");
} /* End TaWimMove */



/****************************************************************************
*
*  Function         : _TaWimOpen
*                     
*  Description      : Opens the window.  If it is already open, it receives
*                     focus, otherwise it is created and inserted into the
*                     window list.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/09/95  AB           Created.
*
****************************************************************************/

VOID TAENTRYFIX _TaWimOpen ( PTTA_CHAR  pszWindowName,
                             PTTA_CHAR  pszInstanceName,
                             HWND       hOwnerHWND,
                             PTTA_VOID  pInitData,
                             ULONG      ulFuncCode,
                             PTTA_ABHI  pABHI,
                             PTTA_CHAR  pszFileName,
                             INT        iLineNumber      )
{
    SHORT            sRetCode  = ETA_OK;
    SHORT            sRetCode2 = ETA_OK;
    SHORT            sRetCode3 = ETA_OK;
    CHAR             szRetMsg[CTA_WIM_RET_MSG_SIZE];
    CHAR             szRetMsg2[CTA_WIM_RET_MSG_SIZE];
    SHORT            sWindowAccess;
    USHORT           usIndex;
    USHORT           i;
    _FND_WINDOW_OVRD stOverride;
    HWND             hHWND;
    _FND_ERROR_BLOCK stErrorBlock;

    TaErrFuncStartArch ("_TaWimOpen");

    memset(&stErrorBlock, 0, sizeof(_FND_ERROR_BLOCK));
    memset(szRetMsg, 0, CTA_WIM_RET_MSG_SIZE);
    memset(szRetMsg2, 0, CTA_WIM_RET_MSG_SIZE);

    if (TaCfeIsWindowAvailable (pszWindowName))
    {
        /* DLL is not loaded, can't open window */
        sRetCode = ETA_WIM_OPEN_FAILED;
        sprintf(szRetMsg, "_TaWimOpen(%s): DLL is not loaded. Check the window profile table.",
                          pszWindowName);
 
    }
    else if (__TaWimWindowExists(pszWindowName, pszInstanceName, &usIndex))
    {
        /* Set focus to the window if it already exists */
        _TaWimSetFocus( pstWindowList->apstWindow[usIndex]->hHWND,
                        pABHI,
                        pszFileName,
                        iLineNumber  );

        if (!TaErrOK)
        {
            /* Error occurred during execution of _TaWimSetFocus */
            sRetCode = ETA_WIM_OPEN_FAILED;
            sprintf(szRetMsg, "_TaWimOpen(%s, %s): Window exists, set focus failed",
                              pszWindowName,
                              pszInstanceName);
        }
    }
    else if (ulFuncCode == CTA_WIM_OPEN_MODAL)
        /* Open a modal window (override design) */
        __TaWimOpenModal( pszWindowName,
                          pszInstanceName,
                          hOwnerHWND,
                          pInitData,
                          pABHI,
                          pszFileName,
                          iLineNumber      );
    else
    {
        /* Get the access rights of the user */
        sWindowAccess = TaSecWindowAccess( pszWindowName );

        /* Check that the user is autorized to open the window */
        if ((TaErrOK) && (sWindowAccess != CTA_SEC_WIN_NO_ACCESS))
        {
            /* Verify that window list has been initialized */
            if (!pstWindowList)
            {
                /* Window list has not been initialized */
                sRetCode = ETA_WIM_OPEN_FAILED;
                sprintf(szRetMsg, "_TaWimOpen(%s, %s): Window list not initialized",
                                  pszWindowName,
                                  pszInstanceName);
            }
            else if (pstWindowList->usNumWindows < CTA_WIM_MAX_WINDOWS)
            {
                usIndex = pstWindowList->usNumWindows;

                /* Allocate memory for the window header */
                TaOpsMemAlloc(pstWindowList->apstWindow[usIndex],
                              sizeof(TTA_WINHEADER));

                if (TaErrOK)
                {
                    /* Move existing windows one place back */
                    for (i = usIndex; i > 0; i--)
                        *(pstWindowList->apstWindow[i]) =
                                *(pstWindowList->apstWindow[i - 1]);

                    /* Initialize window header */
                    memset(pstWindowList->apstWindow[0], 0,
                           sizeof(TTA_WINHEADER) );
                }
                else
                {
                    /* Free memory if allocation failed */
                    TaOpsMemFree(pstWindowList->apstWindow[usIndex]);
                    pstWindowList->apstWindow[usIndex] = NULL;
                }

                if (TaErrOK)
                {
                    /* Determine whether the TAS desktop is the parent */
                    if (ulFuncCode == CTA_WIM_OPEN_MODELESS)
                        hOwnerHWND = pstWindowList->hMainWindowHWND;

                    /* Insert window into list */
                    pstWindowList->apstWindow[0]->hOwnerHWND = hOwnerHWND;
                    pstWindowList->usNumWindows++;
                    strncpy(pstWindowList->apstWindow[0]->szWindowName,
                            pszWindowName, strlen(pszWindowName) + 1);
                    strncpy(pstWindowList->apstWindow[0]->szInstanceName,
                            pszInstanceName, strlen(pszInstanceName) + 1);
                    pstWindowList->apstWindow[0]->fChanged = FALSE;
                    pstWindowList->apstWindow[0]->fMinimized = FALSE;
                }
                else
                {
                    /* Error occurred before window was inserted into list */
                    sRetCode = ETA_WIM_OPEN_FAILED;
                    sprintf(szRetMsg, "_TaWimOpen(%s, %s): Unable to add window to window list, closing...",
                                      pszWindowName,
                                      pszInstanceName);
                }

                /* Create the window */
                if (!sRetCode)
                {
                    strncpy(stOverride.Version, FND_WINDOW_FIRST_VER, 2);
                    stOverride.ModalityOvrd     = FND_WINDOW_DEFAULT;
                    stOverride.VisibilityOvrd   = FND_WINDOW_DEFAULT;
                    stOverride.InitialStateOvrd = FND_WINDOW_DEFAULT;
                    stOverride.WindowTypeOvrd   = FND_WINDOW_DEFAULT;
                    stOverride.NatlLanguageOvrd = FND_WINDOW_DEFAULT;
                    stOverride.SizingOvrd       = FND_WINDOW_DEFAULT;
                    stOverride.PositionOvrd     = FND_WINDOW_SETORIGIN;
                    stOverride.RefWindow        = FND_WINDOW_DESKTOP;

                    /* Paint the window in its default position */
                    TaWimQueryDefaultPosition( pszWindowName,
                                               &(stOverride.xOriginOvrd),
                                               &(stOverride.yOriginOvrd)  );

                    _TaMenPredisplay(&(pstWindowList->apstWindow[0]->stMenuData));

                    /* Cannot use pABHI because PREDISPLAY overwrites it */
                    sRetCode2 = FndWindowCreate( pszWindowName,
                                                 pszInstanceName,
                                                 hOwnerHWND,
                                                 &stOverride,
                                                 pInitData,
                                                 &stErrorBlock    );

                    if (!sRetCode2)
                    {
                        /* Disable window if user has only browse rights */
                        if (sWindowAccess == CTA_SEC_WIN_BROWSE)
                            _TaWimDisable( pstWindowList->apstWindow[0]->hHWND,
                                           pABHI,
                                           pszFileName,
                                           iLineNumber  );

                        /* Register window in task list */
                        TaWimRegisterTaskList(pstWindowList->apstWindow[0]->hHWND);

                        /* Register window in Windows menu */
                        TaMenWindowItemAdd(pstWindowList->apstWindow[0]->hHWND);
                    }
                    else
                    {
                        /* Error creating window */
                        sRetCode = ETA_WIM_OPEN_FAILED;
                        sprintf(szRetMsg, "_TaWimOpen(%s, %s): Error occurred while creating window",
                                          pszWindowName,
                                          pszInstanceName);

                        /* Copy the error block to pABHI */
                        memcpy(pABHI, &stErrorBlock, sizeof(stErrorBlock));

                        /* Remove window from list using fake HWND */
                        pstWindowList->apstWindow[0]->hHWND = 0;
                        _TaWimDestroy(0, NULL, pABHI, pszFileName, iLineNumber);
                    }
                }
            }
            else
            {
                /* Too many open windows */
                sRetCode = ETA_WIM_TOO_MANY_WINDOWS;
                sprintf(szRetMsg, "_TaWimOpen(%s, %s): Too many open windows",
                                  pszWindowName,
                                  pszInstanceName);

                _TaErrDisplayMsg( sRetCode,
                                  NULL,
                                  NULL,
                                  CTA_MSGBOX_OK,
                                  CTA_MSGBOX_BUTTON_OK,
                                  pstWindowList->hMainWindowHWND,
                                  pABHI,
                                  pszFileName,
                                  iLineNumber                     );
            }
        }
        else if (sWindowAccess == CTA_SEC_WIN_NO_ACCESS)
        {
            /* User has no access to this window */
            sRetCode = ETA_WIM_NO_ACCESS;
            sprintf(szRetMsg, "_TaWimOpen(%s, %s): User has no access to this window",
                              pszWindowName,
                              pszInstanceName);

            _TaErrDisplayMsg( sRetCode,
                              NULL,
                              NULL,
                              CTA_MSGBOX_OK,
                              CTA_MSGBOX_BUTTON_OK,
                              pstWindowList->hMainWindowHWND,
                              pABHI,
                              pszFileName,
                              iLineNumber                     );
        }
        else if (!TaErrOK)
        {
            /* Error occurred when requesting user profile */
            sRetCode = ETA_WIM_NO_PROFILE;
            sprintf(szRetMsg, "_TaWimOpen(%s, %s): Unable to obtain user profile",
                              pszWindowName,
                              pszInstanceName);
        }
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaWimOpen");
} /* End TaWimOpen */



/****************************************************************************
*
*  Function         : _TaWimQueryActiveHWND;
*                     
*  Description      : Returns a pointer to the window list.  Only to be used
*                     by the main window.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/30/95  AB           Created.
*
****************************************************************************/

HWND TAENTRYFIX _TaWimQueryActiveHWND ()
{
    if (pstWindowList->usNumWindows)
        /* The active window is the first in the window list */
        return (pstWindowList->apstWindow[0]->hHWND);
    else
        /* No actiev application window */
        return(0);

} /* End TaWimQueryActiveHWND */



/****************************************************************************
*
*  Function         : _TaWimQueryAuditTrail
*
*  Description      : Get the audit trail data for a specified window.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  04/12/95  SM           Created.
*
****************************************************************************/
VOID TAENTRYFIX _TaWimQueryAuditTrail ( PTTA_CHAR  pszWindowName,
                                        PTTA_BOOL  fAuditTrailPoss,
                                        PTTA_BOOL  fAuditTrailMand,
                                        PTTA_ABHI  pABHI,
                                        PTTA_CHAR  pszFileName,
                                        INT        iLineNumber  )
{
    SHORT     sRetCode      = ETA_OK;
    SHORT     sRetCode2     = ETA_OK;
    CHAR      szRetMsg[CTA_WIM_RET_MSG_SIZE];
    SHORT     i             = 0;

    TaErrFuncStartArch ("_TaWimQueryAuditTrail");

    memset(szRetMsg, 0, CTA_WIM_RET_MSG_SIZE);

    /* Try to locate the window's profile data */
    while ((strcmp(((pstWindowProfile)+i)->szWindowName, pszWindowName)) &&
           (strcmp(((pstWindowProfile)+i)->szWindowName, "")))
        i++;

    if (!strcmp(((pstWindowProfile)+i)->szWindowName, pszWindowName))
    {
        *fAuditTrailPoss = ((pstWindowProfile)+i)->fAuditPossible;
        *fAuditTrailMand = ((pstWindowProfile)+i)->fAuditMandatory;
    }
    else
    {
        sRetCode = ETA_WIM_WINDOW_PROF_NOT_FOUND;
        sprintf(szRetMsg,
                "_TaWimQueryAuditTrail: Profile for window %s not found.",
                pszWindowName);
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaWimQueryAuditTrail");
} /* End TaWimQueryAuditTrail */


/****************************************************************************
*
*  Function         : _TaWimQueryChanged
*                     
*  Description      : Returns TRUE if the window contents have changed;
*                     FALSE if they have not.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/09/95  AB           Created.
*
****************************************************************************/

BOOL TAENTRYFIX _TaWimQueryChanged ( HWND       hHWND,
                                     PTTA_ABHI  pABHI,
                                     PTTA_CHAR  pszFileName,
                                     INT        iLineNumber  )
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    CHAR      szRetMsg[CTA_WIM_RET_MSG_SIZE];
    USHORT    usIndex;
    BOOL      fWindowChanged = FALSE;

    TaErrFuncStartArch ("_TaWimQueryChanged");

    memset(szRetMsg, 0, CTA_WIM_RET_MSG_SIZE);

    if (TaWimValidHandle(hHWND, &usIndex))
    {
        fWindowChanged = pstWindowList->apstWindow[usIndex]->fChanged;
    }
    else
    {
        /* Invalid window handle */
        sRetCode = ETA_WIM_INVALID_HANDLE;
        sprintf(szRetMsg, "_TaWimQueryChanged: Invalid window handle");
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaWimQueryChanged");

    return (fWindowChanged);
} /* End TaWimQueryChanged */



/****************************************************************************
*
*  Function         : _TaWimQueryDefaultPosition
*                     
*  Description      : Returns the default position of the window
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/09/95  AB           Created.
*  04/13/95  SM           Added logic to get default position.
*
****************************************************************************/
VOID TAENTRYFIX _TaWimQueryDefaultPosition ( PTTA_CHAR   pszWindowName,
                                             PTTA_LONG   plDefaultX,
                                             PTTA_LONG   plDefaultY,
                                             PTTA_ABHI   pABHI,
                                             PTTA_CHAR   pszFileName,
                                             INT         iLineNumber  )
{
    SHORT     i         = 0;
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    CHAR      szRetMsg[CTA_WIM_RET_MSG_SIZE];

    TaErrFuncStartArch ("_TaWimQueryDefaultPosition");

    memset(szRetMsg, 0, CTA_WIM_RET_MSG_SIZE);

    /* Try to locate the window's profile data */
    while ((strcmp(((pstWindowProfile)+i)->szWindowName, pszWindowName)) &&
            (strcmp(((pstWindowProfile)+i)->szWindowName, "")))
        i++;

    if (!strcmp(((pstWindowProfile)+i)->szWindowName, pszWindowName))
    {
        *plDefaultX = ((pstWindowProfile)+i)->usXPos;
        *plDefaultY = ((pstWindowProfile)+i)->usYPos;
    }
    else
    {
        *plDefaultX = 0;
        *plDefaultY = 0;

        sRetCode = ETA_WIM_WINDOW_PROF_NOT_FOUND;
        sprintf(szRetMsg,
                "_TaWimQueryDefaultPosition: Profile for window %s not found.",
                pszWindowName);
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaWimQueryDefaultPosition");
} /* End TaWimQueryDefaultPosition */



/****************************************************************************
*
*  Function         : _TaWimQueryHandle
*                     
*  Description      : Returns the window handle of the window with the given
*                     combination of window and instance names
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/09/95  AB           Created.
*
****************************************************************************/

HWND TAENTRYFIX _TaWimQueryHandle ( PTTA_CHAR  pszWindowName,
                                    PTTA_CHAR  pszInstanceName,
                                    PTTA_ABHI  pABHI,
                                    PTTA_CHAR  pszFileName,
                                    INT        iLineNumber      )
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    CHAR      szRetMsg[CTA_WIM_RET_MSG_SIZE];
    USHORT    usIndex;
    HWND      hHWND = 0;

    TaErrFuncStartArch ("_TaWimQueryHandle");

    memset(szRetMsg, 0, CTA_WIM_RET_MSG_SIZE);

    /* Verify that the window exists in the window list */
    if (__TaWimWindowExists(pszWindowName, pszInstanceName, &usIndex))
    {
        /* Get the handle from the window list */
        hHWND = pstWindowList->apstWindow[usIndex]->hHWND;
    }
    else
    {
        /* The window does not exist in the window list - log error */
        sRetCode = ETA_WIM_NO_HANDLE;
        sprintf(szRetMsg, "_TaWimQueryHandle(%s, %s): No handle found",
                          pszWindowName,
                          pszInstanceName);
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaWimQueryHandle");

    return (hHWND);
} /* End TaWimGetWindowHandle */



/****************************************************************************
*
*  Function         : _TaWimQueryState
*                     
*  Description      : Returns the window's state (minimized/maximized/normal)
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/09/95  AB           Created.
*
****************************************************************************/

CHAR TAENTRYFIX _TaWimQueryState ( HWND       hHWND,
                                   PTTA_ABHI  pABHI,
                                   PTTA_CHAR  pszFileName,
                                   INT        iLineNumber  )
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    CHAR      szRetMsg[CTA_WIM_RET_MSG_SIZE];
    CHAR      chState = '\0';

    TaErrFuncStartArch ("_TaWimQueryState");

    memset(szRetMsg, 0, CTA_WIM_RET_MSG_SIZE);

    if (TaWimValidHandle(hHWND, NULL))
    {
        sRetCode2 = FndWindowQueryState( hHWND,
                                         &chState,
                                         (PTTA_FND_ERROR_BLOCK)pABHI );
    }
    else
    {
        /* Invalid window handle */
        sRetCode = ETA_WIM_INVALID_HANDLE;
        sprintf(szRetMsg, "_TaWimQueryState: Invalid window handle");
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaWimQueryState");

    return (chState);
} /* End TaWimQueryState */



/****************************************************************************
*
*  Function         : _TaWimQueryWindowList
*                     
*  Description      : Returns a pointer to the window list.  Only to be used
*                     by the main window.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/30/95  AB           Created.
*
****************************************************************************/

PTTA_WINLIST TAENTRYFIX _TaWimQueryWindowList ()
{
    /* Return the pointer to the window list */
    return (pstWindowList);
} /* End TaWimQueryWindowList */



/****************************************************************************
*
*  Function         : _TaWimRegisterHandle
*                     
*  Description      : Registers the window handle in the window list if the
*                     last entry has a handle that is zero.  Called from
*                     TaErrCbkStart when the event ID is PREDISPLAY.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  04/21/95  AB           Created.
*
****************************************************************************/

VOID TAENTRYFIX _TaWimRegisterHandle ( HWND hHWND )
{
    TaErrFuncStartArch ("_TaWimRegisterHandle");

    if ((pstWindowList) && (!TaWimQueryActiveHWND()))
        /* Register the handle in the window list */
        pstWindowList->apstWindow[0]->hHWND = hHWND;

    TaErrFuncStopArch ("_TaWimRegisterHandle");
} /* End TaWimRegisterHandle */



/****************************************************************************
*
*  Function         : _TaWimRegisterTaskList
*                     
*  Description      : Registers the window in the OS/2 task list.  Called
*                     from TaWimOpen for modeless and dialog windows.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/29/95  AB           Created.
*
****************************************************************************/

VOID TAENTRYFIX _TaWimRegisterTaskList ( HWND       hHWND,
                                         PTTA_ABHI  pABHI,
                                         PTTA_CHAR  pszFileName,
                                         INT        iLineNumber  )
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    CHAR      szRetMsg[CTA_WIM_RET_MSG_SIZE];
    SWCNTRL   stSwitchControl;
    HSWITCH   hSwitch;
    PID       pid;
    HAB       hab;

    TaErrFuncStartArch ("_TaWimRegisterTaskList");

    memset(szRetMsg, 0, CTA_WIM_RET_MSG_SIZE);

    /* Get the PID of the window from the system */
    WinQueryWindowProcess(hHWND, &pid, NULL);

    /* Fill the switch (task list) control structure */
    stSwitchControl.hwnd          = hHWND;
    stSwitchControl.hwndIcon      = NULLHANDLE;
    stSwitchControl.hprog         = NULLHANDLE;
    stSwitchControl.idProcess     = pid;
    stSwitchControl.idSession     = 0;
    stSwitchControl.uchVisibility = SWL_VISIBLE;
    stSwitchControl.fbJump        = SWL_JUMPABLE;

    /* The task list entry text should be the window title */
    sRetCode2 = FndWindowQueryText( hHWND,
                                    MAX_WINDOWTITLELEN + 1,
                                    stSwitchControl.szSwtitle,
                                    (PTTA_FND_ERROR_BLOCK)pABHI );

    if (!sRetCode2)
        /* Add the window title to the task list */
        hSwitch = WinAddSwitchEntry(&stSwitchControl);

    if ((!hSwitch) || (sRetCode2))
    {
        if (!sRetCode2)
        {
            /* Get the OS/2 error code */
            hab = WinQueryAnchorBlock(hHWND);
            sRetCode2 = WinGetLastError(hab);
        }

        sRetCode = ETA_WIM_TASKLIST_FAILED;
        sprintf(szRetMsg, "_TaWimRegisterTaskList: Couldn't register window in task list");
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaWimRegisterTaskList");
} /* End TaWimRegisterTaskList */



/****************************************************************************
*
*  Function         : _TaWimSetChanged
*                     
*  Description      : Marks the window as changed.  Should be called from
*                     WINDOW_CHANGE.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/09/95  AB           Created.
*
****************************************************************************/

VOID TAENTRYFIX _TaWimSetChanged ( HWND       hHWND,
                                   PTTA_ABHI  pABHI,
                                   PTTA_CHAR  pszFileName,
                                   INT        iLineNumber  )
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    CHAR      szRetMsg[CTA_WIM_RET_MSG_SIZE];
    USHORT    usIndex;

    TaErrFuncStartArch ("_TaWimSetChanged");

    memset(szRetMsg, 0, CTA_WIM_RET_MSG_SIZE);

    if (TaWimValidHandle(hHWND, &usIndex))
        pstWindowList->apstWindow[usIndex]->fChanged = TRUE;
    else
    {
        /* Invalid window handle */
        sRetCode = ETA_WIM_INVALID_HANDLE;
        sprintf(szRetMsg, "_TaWimSetChanged: Invalid window handle");
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaWimSetChanged");
} /* End TaWimSetChanged */



/****************************************************************************
*
*  Function         : _TaWimSetDefaultPositions
*                     
*  Description      : Moves all open and non-minimized windows to their
*                     default positions.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/09/95  AB           Created.
*
****************************************************************************/

VOID TAENTRYFIX _TaWimSetDefaultPositions ( PTTA_ABHI  pABHI,
                                            PTTA_CHAR  pszFileName,
                                            INT        iLineNumber  )
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    CHAR      szRetMsg[CTA_WIM_RET_MSG_SIZE];
    SHORT     i;
    LONG      lX;
    LONG      lY;

    TaErrFuncStartArch ("_TaWimSetDefaultPositions");

    memset(szRetMsg, 0, CTA_WIM_RET_MSG_SIZE);

    if (pstWindowList)
    {
        /* Loop for all windows in the window list... */
        for (i = pstWindowList->usNumWindows - 1; i >= 0; i--)
        {
            /* Query the default position of the current window */
            TaWimQueryDefaultPosition( pstWindowList->apstWindow[i]->szWindowName,
                                       &lX,
                                       &lY  );

            /* Move the window to its default position */
            TaWimMove( pstWindowList->apstWindow[i]->hHWND,
                       lX,
                       lY  );
        }
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaWimSetDefaultPositions");
} /* End TaWimSetDefaultPositions */



/****************************************************************************
*
*  Function         : _TaWimSetFocus
*                     
*  Description      : Sets the focus to the specified window.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/09/95  AB           Created.
*
****************************************************************************/

VOID TAENTRYFIX _TaWimSetFocus ( HWND       hHWND,
                                 PTTA_ABHI  pABHI,
                                 PTTA_CHAR  pszFileName,
                                 INT        iLineNumber  )
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    CHAR      szRetMsg[CTA_WIM_RET_MSG_SIZE];
    USHORT    usIndex;

    TaErrFuncStartArch ("_TaWimSetFocus");

    memset(szRetMsg, 0, CTA_WIM_RET_MSG_SIZE);

    if (TaWimValidHandle(hHWND, &usIndex))
    {
        sRetCode2 = FndWindowActivate(pstWindowList->apstWindow[usIndex]->szWindowName,
                                      pstWindowList->apstWindow[usIndex]->szInstanceName,
                                      pstWindowList->apstWindow[usIndex]->hOwnerHWND,
                                      NULL,
                                      NULL,
                                      (PTTA_FND_ERROR_BLOCK)pABHI );

        if (sRetCode2)
        {
            /* Error returned from FND API */
            sRetCode = ETA_WIM_SET_FOCUS_FAILED;
            sprintf(szRetMsg, "_TaWimSetFocus: Unable to activate window");
        }
    }
    else
    {
        /* Invalid window handle */
        sRetCode = ETA_WIM_INVALID_HANDLE;
        sprintf(szRetMsg, "_TaWimSetFocus: Invalid window handle");
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaWimSetFocus");
} /* End TaWimSetFocus */



/****************************************************************************
*
*  Function         : _TaWimSetPointerType
*
*  Description      : Sets the pointer type associated with the window.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  04/11/95  AB           Created.
*
****************************************************************************/

VOID TAENTRYFIX _TaWimSetPointerType ( SHORT      sPointerType,
                                       HWND       hHWND,
                                       PTTA_ABHI  pABHI,
                                       PTTA_CHAR  pszFileName,
                                       INT        iLineNumber   )
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    CHAR      szRetMsg[CTA_WIM_RET_MSG_SIZE];

    TaErrFuncStartArch ("_TaWimSetPointerType");

    memset(szRetMsg, 0, CTA_WIM_RET_MSG_SIZE);

    if (TaWimValidHandle(hHWND, NULL))
    {
        /* Call FND API */
        sRetCode2 = FndWindowSetPointer( hHWND,
                                         sPointerType,
                                         (PTTA_FND_ERROR_BLOCK)pABHI );

        if (sRetCode2)
        {
            /* Error returned from FND API */
            sRetCode = ETA_WIM_SET_POINTER_FAILED;
            sprintf(szRetMsg, "_TaWimSetPointerType: Error setting pointer");
        }
    }
    else
    {
        /* Invalid window handle */
        sRetCode = ETA_WIM_INVALID_HANDLE;
        sprintf(szRetMsg, "_TaWimSetPointerType: Invalid window handle");
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaWimSetPointerType");
} /* End TaWimSetPointerType */



/****************************************************************************
*
*  Function         : _TaWimSetUnchanged
*                     
*  Description      : Marks the window as not changed.  Should be called
*                     upon return of the window's update service.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  04/11/95  AB           Created.
*
****************************************************************************/

VOID TAENTRYFIX _TaWimSetUnchanged ( HWND       hHWND,
                                     PTTA_ABHI  pABHI,
                                     PTTA_CHAR  pszFileName,
                                     INT        iLineNumber  )
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    CHAR      szRetMsg[CTA_WIM_RET_MSG_SIZE];
    USHORT    usIndex;

    TaErrFuncStartArch ("_TaWimSetUnchanged");

    memset(szRetMsg, 0, CTA_WIM_RET_MSG_SIZE);

    if (TaWimValidHandle(hHWND, &usIndex))
        pstWindowList->apstWindow[usIndex]->fChanged = FALSE;
    else
    {
        /* Invalid window handle */
        sRetCode = ETA_WIM_INVALID_HANDLE;
        sprintf(szRetMsg, "_TaWimSetUnchanged: Invalid window handle");
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaWimSetUnchanged");
} /* End TaWimSetUnchanged */



/****************************************************************************
*
*  Function         : _TaWimValidHandle
*                     
*  Description      : Returns TRUE if a window with the given handle exists
*                     in the window list, FALSE otherwise.  If pusWindowIndex
*                     is not NULL and the handle is in the list, the window's
*                     index in the list is returned here.
*
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/14/95  AB           Created.
*
****************************************************************************/
BOOL TAENTRYFIX _TaWimValidHandle( HWND        hHWND,
                                   PTTA_USHORT pusWindowIndex )
{
    SHORT i;
    BOOL  fHandleFound = FALSE;

    TaErrFuncStartArch ("_TaWimValidHandle");

    if (pstWindowList)
    {
        for (i = 0; (!fHandleFound) && (i < pstWindowList->usNumWindows); i++)
            fHandleFound = (pstWindowList->apstWindow[i]->hHWND == hHWND);
    }

    /* Return the window's index in the window list if handle is valid */
    if (pusWindowIndex != NULL)
    {
        if (fHandleFound)
            *pusWindowIndex = i - 1;
        else
            *pusWindowIndex = CTA_WIM_NO_WINDOW;
    }

    TaErrFuncStopArch ("_TaWimValidHandle");

    return(fHandleFound);
} /* End _TaWimValidHandle */


/****************************************************************************
*        A R C H I T E C T U R E - I N T E R N A L - F U N C T I O N S
****************************************************************************/

/****************************************************************************
*
*  Function         : __TaWimOpenModal
*                     
*  Description      : Opens a modal window.  Modal windows are not inserted
*                     into the window list.
*
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  04/04/95  AB           Created.
*
****************************************************************************/
STATIC VOID __TaWimOpenModal( PTTA_CHAR     pszWindowName,
                              PTTA_CHAR     pszInstanceName,
                              HWND          hOwnerHWND,
                              PTTA_VOID     pInitData,
                              PTTA_ABHI     pABHI,
                              PTTA_CHAR     pszFileName,
                              INT           iLineNumber      )
{
    SHORT            sRetCode  = ETA_OK;
    SHORT            sRetCode2 = ETA_OK;
    CHAR             szRetMsg[CTA_WIM_RET_MSG_SIZE];
    _FND_WINDOW_OVRD stOverride;

    TaErrFuncStartArch ("__TaWimOpenModal");

    memset(szRetMsg, 0, CTA_WIM_RET_MSG_SIZE);

    strncpy(stOverride.Version, FND_WINDOW_FIRST_VER, 2);
    stOverride.ModalityOvrd     = FND_WINDOW_MODAL; /* Override modality */
    stOverride.VisibilityOvrd   = FND_WINDOW_DEFAULT;
    stOverride.InitialStateOvrd = FND_WINDOW_DEFAULT;
    stOverride.WindowTypeOvrd   = FND_WINDOW_DIALOG;
    stOverride.NatlLanguageOvrd = FND_WINDOW_DEFAULT;
    stOverride.SizingOvrd       = FND_WINDOW_DEFAULT;
    stOverride.PositionOvrd     = FND_WINDOW_SETORIGIN;
    stOverride.RefWindow        = FND_WINDOW_OWNER;

    /* Paint the window in its default position */
    _TaWimQueryDefaultPosition( pszWindowName,
                                &(stOverride.xOriginOvrd),
                                &(stOverride.yOriginOvrd),
                                pABHI,
                                pszFileName,
                                iLineNumber                );

    /* Create the window, but don't insert it into the window list */
    sRetCode2 = FndWindowCreate( pszWindowName,
                                 pszInstanceName,
                                 hOwnerHWND,
                                 &stOverride,
                                 pInitData,
                                 (PTTA_FND_ERROR_BLOCK)pABHI );

    if (sRetCode2)
    {
        /* Error creating window */
        sRetCode = ETA_WIM_OPEN_FAILED;
        sprintf(szRetMsg, "_TaWimOpen(%s, %s): Error occurred while creating window",
                          pszWindowName,
                          pszInstanceName);
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("__TaWimOpenModal");

}  /* End __TaWimOpenModal



/****************************************************************************
*
*  Function         : __TaWimWindowExists
*                     
*  Description      : Returns TRUE if the window exists in the window list,
*                     FALSE otherwise.
*
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/13/95  AB           Created.
*
****************************************************************************/
STATIC BOOL __TaWimWindowExists( PTTA_CHAR   pszWindowName,
                                 PTTA_CHAR   pszInstanceName,
                                 PTTA_USHORT pusWindowIndex   )
{
    SHORT i;
    BOOL  fWindowFound = FALSE;

    TaErrFuncStartArch ("__TaWimWindowExists");

    if (pstWindowList)
    {
        for (i = 0; (!fWindowFound) && (i < pstWindowList->usNumWindows); i++)
            fWindowFound =
                (!strcmp(pszWindowName,   pstWindowList->apstWindow[i]->szWindowName  ) &&
                 !strcmp(pszInstanceName, pstWindowList->apstWindow[i]->szInstanceName)    );
    }

    /* Return the window's index in the window list if the window exists */
    if (pusWindowIndex != NULL)
    {
        if (fWindowFound)
            *pusWindowIndex = i - 1;
        else
            *pusWindowIndex = CTA_WIM_NO_WINDOW;
    }

    TaErrFuncStopArch ("__TaWimWindowExists");

    return(fWindowFound);

} /* End __TaWimWindowExists */



/****************************************************************************
*  End of file TAWIM.c
****************************************************************************/

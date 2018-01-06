/****************************************************************************
*
*  File Name        : TAMEN.C
*                     
*  Description      : This file contains APIs that handle the main MENUS.
*
*  Public Functions : _TaMenItemCheck
*                     _TaMenItemUncheck
*                     _TaMenItemHide
*                     _TaMenItemShow
*                     _TaMenItemEnable
*                     _TaMenItemDisable
*                     _TaMenPredisplay
*                     _TaMenMainPredisplay
*                     _TaMenActivate
*                     _TaMenItemAdd
*                     _TaMenItemSelect
*                     _TaMenTaxpayerItemAdd
*                     _TaMenTaxpayerItemSelect
*                     _TaMenWindowItemAdd
*                     _TaMenWindowItemCheck
*                     _TaMenWindowItemRemove
*                     _TaMenWindowItemSelect
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  03/29/95  SR           Created.
*  04/07/95  AB           Added TaMenWindowItemAdd, -Remove and -Select.
*  04/19/95  AB           Added TaMenTaxpayerItemAdd and -Select.
*  05/04/95  AB           Added TaMenWindowItemCheck
*
****************************************************************************/
#ifdef  DTA_OS2_APP
#define CTA_DLL_NAME "TAMENO"
#endif

#define  DTA_ERR_INCL
#define  DTA_OPS_INCL
#define  DTA_MSG_INCL
#define  DTA_WIM_INCL
/****************************************************************************
*  #include Files
****************************************************************************/
#include <tasarch.h>
#include "tamen.h"
#include <stdarg.h>  /* For variable number of parameters. */


/****************************************************************************
*  #define Constants
****************************************************************************/
#define CTA_MEN_PREDISPLAY  'P'
#define CTA_MEN_ACTIVE      'A'
#define CTA_MEN_SHOW        01
#define CTA_MEN_UNCHECK     02
#define CTA_MEN_ENABLE      04

/****************************************************************************
*  #define Macros
****************************************************************************/

/****************************************************************************
*  Global variables for this source file
****************************************************************************/
STATIC UCHAR     uchWindowStatus = 0;
STATIC USHORT    usMenItemCt     = 0;
STATIC USHORT    usWinItemCt     = 0;
STATIC USHORT    usTPItemCt      = 0;
STATIC FND_HWND  TAS_hwnd        = 0;
STATIC PTTA_WIN_MEN_DATA pstMenData;
STATIC TTA_WIN_MEN_DATA  stMainMenData;

STATIC PTTA_CHAR pWidNames[] =
{
    "TA013MI_FUN_DYNAMIC_1",
    "TA014MI_FUN_DYNAMIC_2",
    "TA015MI_FUN_DYNAMIC_3",
    "TA016MI_FUN_DYNAMIC_4",
    "TA017MI_FUN_DYNAMIC_5",
    "TA018MI_FUN_DYNAMIC_6",
    "TA019MI_FUN_DYNAMIC_7",
    "TA020MI_FUN_DYNAMIC_8",
    "TA003MN_FUNCTIONS_NOTES",
    "TA028MI_FUN_NOTES_VIEW",
    "TA009MI_FUN_NOTES_ADD",
    "TA011MI_FUN_AUDIT_TRAIL",
    "TA006PB_NOTE",
    "TA009PB_ADD_NOTE",
    "TA002PB_AUDIT_TRAIL"
};

STATIC PTTA_CHAR apszWindowItemNames[] =
{
    "TA074MI_WIN_WINDOW_1",
    "TA075MI_WIN_WINDOW_2",
    "TA076MI_WIN_WINDOW_3",
    "TA077MI_WIN_WINDOW_4",
    "TA078MI_WIN_WINDOW_5"
};

STATIC PTTA_CHAR apszTaxpayerItemNames[] =
{
    "TA003MI_FIL_TAXPAYER_1",
    "TA004MI_FIL_TAXPAYER_2",
    "TA005MI_FIL_TAXPAYER_3",
    "TA006MI_FIL_TAXPAYER_4",
    "TA007MI_FIL_TAXPAYER_5"
};

STATIC TTA_TAXPAYERDATA astTaxpayer[CTA_MEN_MAX_TAXPAYERS];

/****************************************************************************
*  Internal function prototypes
****************************************************************************/
STATIC SHORT __TaMenGetWidgetName(PTTA_CHAR pszItemName);

STATIC SHORT __TaMenGetLinkIndex ( SHORT sIndex );


/****************************************************************************
*                 P U B L I C - F U N C T I O N S
****************************************************************************/

/****************************************************************************
*
*  Function         : _TaMenItemCheck
*                     
*  Description      : This puts a check mark beside a menu item.  Nothing
*                     happens if the item is already checked. Pushbuttons
*                     cannot be checked.  If programmer tries to do this,
*                     an error message will be returned.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  02/15/95  SR           Created.
*
****************************************************************************/
VOID TAENTRYFIX _TaMenItemCheck ( PTTA_ABHI pABHI,
                                  PTTA_CHAR pszFileName,
                                  INT       iLineNumber,
                                  PTTA_CHAR pszName,
                                  ...)
{
    SHORT     sRetCode   = ETA_OK;
    SHORT     sRetCode2  = ETA_OK;
    SHORT     sIndex     = 0;
    CHAR      szRetMsg[50];
    va_list   ap;

    TaErrFuncStartArch ("_TaMenItemCheck");
    szRetMsg[0] = 0;

    /* Get index number for STATIC menu item.  If item is dynamic,   */
    /* index will be -1 and the appropriate index will be retrieved. */
    va_start(ap, pszName);
    sIndex = va_arg(ap, SHORT);

    if (sIndex == -1) 
        sIndex = 0;

    va_end(ap);

    if(sIndex >= CTA_MEN_TOT_PB_ITEM)
        sRetCode = ETA_MEN_CANNOT_CHECK_PB;

    else
    {
        /* Get index of dynamic menu item. */
        if (sIndex == 0)
           if((sIndex = __TaMenGetWidgetName(pszName)) == -1)
                sRetCode = ETA_MEN_INVALID_ITEM_NAME;

        if ( (sIndex != -1) && (uchWindowStatus == CTA_MEN_ACTIVE) )
        {
            sRetCode2 = FndCommandCheckMenu( TAS_hwnd,
                                             pWidNames[sIndex],
                                             (PTTA_FND_ERROR_BLOCK)pABHI); 
            if(!sRetCode2)
                pstMenData->stMenStatus[sIndex].usUncheck = 0;

            else
                sRetCode = ETA_MEN_ITEM_STAT_CHG_FAILED;
        }
        else
            pstMenData->stMenStatus[sIndex].usUncheck = 0;
    }
    if(sRetCode)
        sprintf(szRetMsg, "Could not Check MI %s.", pszName);

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch("_TaMenItemCheck");

} /* End TaMenItemCheck  */


/****************************************************************************
*
*  Function         : _TaMenItemUncheck
*
*  Description      : This takes away a check mark beside a menu item.
*                     Nothing happens if the item is already unchecked.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  02/15/95  SR           Created.
*
****************************************************************************/
VOID TAENTRYFIX _TaMenItemUncheck ( PTTA_ABHI pABHI,
                                    PTTA_CHAR pszFileName,
                                    INT       iLineNumber,
                                    PTTA_CHAR pszName,
                                    ...)
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    SHORT     sIndex    = 0;
    CHAR      szRetMsg[50];
    va_list   ap;

    TaErrFuncStartArch ("_TaMenItemUncheck");
    szRetMsg[0] = 0;

    /* Get index number for static menu item.  If item is dynamic,   */
    /* index will be -1 and the appropriate index will be retrieved. */
    va_start(ap, pszName);
    sIndex = va_arg(ap, SHORT);

    if (sIndex == -1)
        sIndex = 0;

    va_end(ap);

    if(sIndex >= CTA_MEN_TOT_PB_ITEM)
        sRetCode = ETA_MEN_CANNOT_CHECK_PB;

    else
    {
        /* Get index of dynamic menu item. */
        if (sIndex == 0)
           if((sIndex = __TaMenGetWidgetName(pszName)) == -1)
                sRetCode = ETA_MEN_INVALID_ITEM_NAME;

        if ( (sIndex != -1) && (uchWindowStatus == CTA_MEN_ACTIVE) )
        {
            sRetCode2 = FndCommandUncheckMenu( TAS_hwnd,
                                               pWidNames[sIndex],
                                               (PTTA_FND_ERROR_BLOCK)pABHI);
            if(!sRetCode2)
                pstMenData->stMenStatus[sIndex].usUncheck = 1;

            else
                sRetCode = ETA_MEN_ITEM_STAT_CHG_FAILED;
        }
        else
            pstMenData->stMenStatus[sIndex].usUncheck = 1;
    }
    if(sRetCode)
        sprintf(szRetMsg, "Could not Uncheck MI %s.", pszName);

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch("_TaMenItemUncheck");

} /* End TaMenItemUncheck  */


/****************************************************************************
*
*  Function         : _TaMenItemHide
*
*  Description      : This hides a menu item.  Nothing happens of the item
*                     is already hidden.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  02/15/95  SR           Created.
*
****************************************************************************/
VOID TAENTRYFIX _TaMenItemHide ( PTTA_ABHI pABHI,
                                 PTTA_CHAR pszFileName,
                                 INT       iLineNumber,
                                 PTTA_CHAR pszName,
                                 ...)
{
    SHORT     sRetCode   = ETA_OK;
    SHORT     sRetCode2  = ETA_OK;
    SHORT     sIndex     = 0;
    SHORT     sLinkIndex = 0;
    CHAR      szRetMsg[50];
    va_list   ap;

    TaErrFuncStartArch ("_TaMenItemHide");
    szRetMsg[0] = 0;

    /* Get index number for static menu item.  If item is dynamic,   */
    /* index will be -1 and the appropriate index will be retrieved. */
    va_start(ap, pszName);
    sIndex = va_arg(ap, SHORT);

    if (sIndex == -1)
        sIndex = 0;

    va_end(ap);

    /* Get index of dynamic menu item. */
    if (sIndex == 0)
       if((sIndex = __TaMenGetWidgetName(pszName)) == -1)
            sRetCode = ETA_MEN_INVALID_ITEM_NAME;

    if (sIndex != -1)
    {
        if(uchWindowStatus == CTA_MEN_ACTIVE)
        {
            sRetCode2 = FndCommandHide( TAS_hwnd,
                                        pWidNames[sIndex],
                                        (PTTA_FND_ERROR_BLOCK)pABHI);

            if(!sRetCode2)
                pstMenData->stMenStatus[sIndex].usShow = 0;

            else
                sRetCode = ETA_MEN_ITEM_STAT_CHG_FAILED;
        }
        else
            pstMenData->stMenStatus[sIndex].usShow = 0;

        if( !sRetCode )
        {
            /* Get link index if one exists. */
            sLinkIndex = __TaMenGetLinkIndex( sIndex );

            if(sLinkIndex != -1)
            {
                if(uchWindowStatus == CTA_MEN_ACTIVE)
                {
                    sRetCode2 = FndCommandHide( TAS_hwnd,
                                                pWidNames[sLinkIndex],
                                                (PTTA_FND_ERROR_BLOCK)pABHI);

                    if(!sRetCode2)
                        pstMenData->stMenStatus[sLinkIndex].usShow = 0;

                    else
                        sRetCode = ETA_MEN_ITEM_STAT_CHG_FAILED;
                }
                else
                    pstMenData->stMenStatus[sLinkIndex].usShow = 0;
            }
        }
    }

    if(sRetCode)
        sprintf(szRetMsg, "Could not Hide MI %s.", pszName);

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch("_TaMenItemHide");

} /* End TaMenItemHide  */

/****************************************************************************
*
*  Function         : _TaMenItemShow
*
*  Description      : This shows a menu item.  Nothing happens if the
*                     item is already shown.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  02/15/95  SR           Created.
*
****************************************************************************/
VOID TAENTRYFIX _TaMenItemShow ( PTTA_ABHI pABHI,
                                 PTTA_CHAR pszFileName,
                                 INT       iLineNumber,
                                 PTTA_CHAR pszName,
                                 ...)
{
    SHORT     sRetCode   = ETA_OK;
    SHORT     sRetCode2  = ETA_OK;
    SHORT     sIndex     = 0;
    SHORT     sLinkIndex = 0;
    CHAR      szRetMsg[50];
    va_list   ap;

    TaErrFuncStartArch ("_TaMenItemShow");
    szRetMsg[0] = 0;

    /* Get index number for static menu item.  If item is dynamic,   */
    /* index will be -1 and the appropriate index will be retrieved. */
    va_start(ap, pszName);
    sIndex = va_arg(ap, SHORT);

    if (sIndex == -1)
        sIndex = 0;

    va_end(ap);

    /* Get index of dynamic menu item. */
    if (sIndex == 0)
       if((sIndex = __TaMenGetWidgetName(pszName)) == -1)
            sRetCode = ETA_MEN_INVALID_ITEM_NAME;

    if (sIndex != -1)
    {
        if(uchWindowStatus == CTA_MEN_ACTIVE)
        {
            sRetCode2 = FndCommandShow( TAS_hwnd,
                                        pWidNames[sIndex],
                                        (PTTA_FND_ERROR_BLOCK)pABHI);

            if(!sRetCode2)
                pstMenData->stMenStatus[sIndex].usShow = 1;

            else
                sRetCode = ETA_MEN_ITEM_STAT_CHG_FAILED;
        }
        else
            pstMenData->stMenStatus[sIndex].usShow = 1;

        if( !sRetCode )
        {
            /* Get link index if one exists. */
            sLinkIndex = __TaMenGetLinkIndex( sIndex );

            if(sLinkIndex != -1)
            {
                if(uchWindowStatus == CTA_MEN_ACTIVE)
                {
                    sRetCode2 = FndCommandShow( TAS_hwnd,
                                                pWidNames[sLinkIndex],
                                                (PTTA_FND_ERROR_BLOCK)pABHI);

                    if(!sRetCode2)
                        pstMenData->stMenStatus[sLinkIndex].usShow = 1;

                    else
                        sRetCode = ETA_MEN_ITEM_STAT_CHG_FAILED;
                }
                else
                    pstMenData->stMenStatus[sLinkIndex].usShow = 1;
            }
        }
    }

    if(sRetCode)
        sprintf(szRetMsg, "Could not Show MI %s.", pszName);

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch("_TaMenItemShow");

} /* End TaMenItemShow  */

/****************************************************************************
*
*  Function         : _TaMenItemEnable
*
*  Description      : This enables a menu item.  Nothing
*                     happens if the item is already enabled.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  02/15/95  SR           Created.
*
****************************************************************************/
VOID TAENTRYFIX _TaMenItemEnable ( PTTA_ABHI pABHI,
                                   PTTA_CHAR pszFileName,
                                   INT       iLineNumber,
                                   PTTA_CHAR pszName,
                                   ...)
{
    SHORT     sRetCode   = ETA_OK;
    SHORT     sRetCode2  = ETA_OK;
    SHORT     sIndex     = 0;
    SHORT     sLinkIndex = 0;
    CHAR      szRetMsg[50];
    va_list   ap;

    TaErrFuncStartArch ("_TaMenItemEnable");
    szRetMsg[0] = 0;

    /* Get index number for static menu item.  If item is dynamic,   */
    /* index will be -1 and the appropriate index will be retrieved. */
    va_start(ap, pszName);
    sIndex = va_arg(ap, SHORT);

    if (sIndex == -1)
        sIndex = 0;

    va_end(ap);

    /* Get index of dynamic menu item. */
    if (sIndex == 0)
       if((sIndex = __TaMenGetWidgetName(pszName)) == -1)
            sRetCode = ETA_MEN_INVALID_ITEM_NAME;

    if (sIndex != -1)
    {
        if(uchWindowStatus == CTA_MEN_ACTIVE)
        {
            sRetCode2 = FndCommandEnable( TAS_hwnd,
                                          pWidNames[sIndex],
                                          (PTTA_FND_ERROR_BLOCK)pABHI);

            if(!sRetCode2)
                pstMenData->stMenStatus[sIndex].usEnable = 1;

            else
                sRetCode = ETA_MEN_ITEM_STAT_CHG_FAILED;
        }
        else
            pstMenData->stMenStatus[sIndex].usEnable = 1;

        if( !sRetCode )
        {
            /* Get link index if one exists. */
            sLinkIndex = __TaMenGetLinkIndex( sIndex );

            if(sLinkIndex != -1)
            {
                if(uchWindowStatus == CTA_MEN_ACTIVE)
                {
                    sRetCode2 = FndCommandEnable(TAS_hwnd,
                                                 pWidNames[sLinkIndex],
                                                 (PTTA_FND_ERROR_BLOCK)pABHI);

                    if(!sRetCode2)
                        pstMenData->stMenStatus[sLinkIndex].usEnable = 1;

                    else
                        sRetCode = ETA_MEN_ITEM_STAT_CHG_FAILED;
                }
                else
                    pstMenData->stMenStatus[sLinkIndex].usEnable = 1;
            }
        }
    }

    if(sRetCode)
        sprintf(szRetMsg, "Could not Enable MI %s.", pszName);

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch("_TaMenItemEnable");

} /* End TaMenItemEnable  */

/****************************************************************************
*
*  Function         : _TaMenItemDisable
*
*  Description      : This disables a menu item.  Nothing
*                     happens if the item is already disabled.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  02/15/95  SR           Created.
*
****************************************************************************/
VOID TAENTRYFIX _TaMenItemDisable ( PTTA_ABHI pABHI,
                                    PTTA_CHAR pszFileName,
                                    INT       iLineNumber,
                                    PTTA_CHAR pszName,
                                    ...)
{
    SHORT     sRetCode   = ETA_OK;
    SHORT     sRetCode2  = ETA_OK;
    SHORT     sIndex     = 0;
    SHORT     sLinkIndex = 0;
    CHAR      szRetMsg[50];
    va_list   ap;

    TaErrFuncStartArch ("_TaMenItemDisable");
    szRetMsg[0] = 0;

    /* Get index number for static menu item.  If item is dynamic,   */
    /* index will be -1 and the appropriate index will be retrieved. */
    va_start(ap, pszName);
    sIndex = va_arg(ap, SHORT);

    if (sIndex == -1)
        sIndex = 0;

    va_end(ap);

    /* Get index of dynamic menu item. */
    if (sIndex == 0)
       if((sIndex = __TaMenGetWidgetName(pszName)) == -1)
            sRetCode = ETA_MEN_INVALID_ITEM_NAME;

    if (sIndex != -1)
    {
        if(uchWindowStatus == CTA_MEN_ACTIVE)
        {
            sRetCode2 = FndCommandDisable( TAS_hwnd,
                                           pWidNames[sIndex],
                                           (PTTA_FND_ERROR_BLOCK)pABHI);

            if(!sRetCode2)
                pstMenData->stMenStatus[sIndex].usEnable = 0;

            else
                sRetCode = ETA_MEN_ITEM_STAT_CHG_FAILED;
        }
        else
            pstMenData->stMenStatus[sIndex].usEnable = 0;

        if( !sRetCode )
        {
            /* Get link index if one exists. */
            sLinkIndex = __TaMenGetLinkIndex( sIndex );

            if(sLinkIndex != -1)
            {
                if(uchWindowStatus == CTA_MEN_ACTIVE)
                {
                    sRetCode2 = FndCommandDisable(TAS_hwnd,
                                                  pWidNames[sLinkIndex],
                                                  (PTTA_FND_ERROR_BLOCK)pABHI);

                    if(!sRetCode2)
                        pstMenData->stMenStatus[sLinkIndex].usEnable = 0;

                    else
                        sRetCode = ETA_MEN_ITEM_STAT_CHG_FAILED;
                }
                else
                    pstMenData->stMenStatus[sLinkIndex].usEnable = 0;
            }
        }
    }

    if(sRetCode)
        sprintf(szRetMsg, "Could not Disable MI %s.", pszName);

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch("_TaMenItemDisable");

} /* End TaMenItemDisable  */


/****************************************************************************
*
*  Function         : _TaMenPredisplay
*
*  Description      : This initializes structures necessary for processing
*                     menu data.  This function has to be run before the
*                     programmer starts changing the menus.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  02/15/95  SR           Created.
*
****************************************************************************/
VOID TAENTRYFIX _TaMenPredisplay ( PTTA_WIN_MEN_DATA pstUserMenData)
{
    USHORT  i;

    TaErrFuncStartArch ("_TaMenPredisplay");

    /* Want this to point to "WIM's" version of the structure. */
    pstMenData = pstUserMenData;

    uchWindowStatus = CTA_MEN_PREDISPLAY;
    usMenItemCt     = 0;

    /* Initialize dynamic menu item status to defaults. */
    for (i = 0; i < CTA_MEN_TOT_LIT ; i++ )
    {
        pstMenData->stMenStatus[i].usShow =
            pstMenData->stMenStatus[i].usEnable  = 0;

        pstMenData->stMenStatus[i].usUncheck = 1;
    }

    /* Currently, the defaults for all of these items is shown, */
    /* Unchecked and disabled.                                  */
    /* Initialize static menu item status to defaults. */
    for (i = CTA_MEN_TOT_LIT; i < CTA_MEN_TOT_PB_ITEM ; i++ )
   
        pstMenData->stMenStatus[i].usShow = 
            pstMenData->stMenStatus[i].usUncheck = 1;
        pstMenData->stMenStatus[i].usEnable  = 0;

    TaErrFuncStopArch("_TaMenPredisplay");

} /* End TaMenPredisplay  */

/****************************************************************************
*
*  Function         : _TaMenMainPredisplay
*
*  Description      : This initializes the structure that initializes the
*                     menus and PBs for the TAS Main window.  This is kept
*                     in memory.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  04/10/95  SR           Created.
*
****************************************************************************/
VOID TAENTRYFIX _TaMenMainPredisplay ( FND_HWND  WIN_hwnd )
{
    USHORT  i;

    TaErrFuncStartArch ("_TaMenMainPredisplay");

    /* Initialize main window status structure. */
    memset( (PTTA_VOID)&stMainMenData, 
            0, 
            sizeof(TTA_WIN_MEN_DATA));

    TAS_hwnd        = WIN_hwnd; 

    /* Initialize dynamic menu item status to defaults. */
    for (i = 0; i < CTA_MEN_TOT_LIT ; i++ )
    {
        stMainMenData.stMenStatus[i].usShow =
            stMainMenData.stMenStatus[i].usEnable  = 0;

        stMainMenData.stMenStatus[i].usUncheck = 1;
    }

    /* Initialize static menu item status to defaults. */
    /* Current standards are that these are shown, unchecked */
    /* and disabled.                                         */
    for (i = CTA_MEN_TOT_LIT; i < CTA_MEN_TOT_PB_ITEM ; i++ )

        stMainMenData.stMenStatus[i].usShow =
            stMainMenData.stMenStatus[i].usUncheck = 1;
        stMainMenData.stMenStatus[i].usEnable  = 0;

    TaErrFuncStopArch("_TaMenMainPredisplay");

} /* End TaMenMainPredisplay  */


/****************************************************************************
*
*  Function         : _TaMenActivate
*
*  Description      : This resets the menus to as defined in the menu
*                     status list that was passed by WIM.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  02/15/95  SR           Created.
*
****************************************************************************/
VOID TAENTRYFIX _TaMenActivate ( PTTA_WIN_MEN_DATA pstUserMenData)
{
    USHORT            i;
    SHORT             sRetCode;
    _FND_ERROR_BLOCK  ErrorBlock;

    TaErrFuncStartArch ("_TaMenActivate");

    if(pstUserMenData == NULL)
        /* Sent from main window; set to defaults. */
        pstMenData = &stMainMenData;

    else
    {
        /* Want this to point to "WIM's" version of the structure. */
        pstMenData = pstUserMenData;
        uchWindowStatus = CTA_MEN_ACTIVE;
    }

    /* Now set menu items to what they should be.                */
    /* The design team has told me that the only menu that might */
    /* change is the functions window.                           */
    for( i = 0; i < CTA_MEN_TOT_ITEM; i++)
    {
        /* Test if shown or hidden. */
        if(pstMenData->stMenStatus[i].usShow)
            sRetCode = FndCommandShow( TAS_hwnd,
                                       pWidNames[i],
                                       &ErrorBlock);
        else
            sRetCode = FndCommandHide( TAS_hwnd,
                                       pWidNames[i],
                                       &ErrorBlock);

        /* Test if checked or unchecked. */
        if(!pstMenData->stMenStatus[i].usUncheck)
            sRetCode = FndCommandCheckMenu( TAS_hwnd,
                                            pWidNames[i],
                                            &ErrorBlock);
        else
            sRetCode = FndCommandUncheckMenu( TAS_hwnd,
                                              pWidNames[i],
                                              &ErrorBlock);

        /* Test if enabled or disabled. */
        if(pstMenData->stMenStatus[i].usEnable)
            sRetCode = FndCommandEnable( TAS_hwnd,
                                         pWidNames[i],
                                         &ErrorBlock);
        else
            sRetCode = FndCommandDisable( TAS_hwnd,
                                          pWidNames[i],
                                          &ErrorBlock);
    }

    /* Now set PB's. */
    for( i = CTA_MEN_TOT_ITEM; i < CTA_MEN_TOT_PB_ITEM; i++)
    {
        /* Test if shown or hidden. */
        if(pstMenData->stMenStatus[i].usShow)
            sRetCode = FndCommandShow( TAS_hwnd,
                                       pWidNames[i],
                                       &ErrorBlock);
        else
            sRetCode = FndCommandHide( TAS_hwnd,
                                       pWidNames[i],
                                       &ErrorBlock);

        /* Test if enabled or disabled. */
        if(pstMenData->stMenStatus[i].usEnable)
            sRetCode = FndCommandEnable( TAS_hwnd,
                                         pWidNames[i],
                                         &ErrorBlock);
        else
            sRetCode = FndCommandDisable( TAS_hwnd,
                                          pWidNames[i],
                                          &ErrorBlock);
    }

    /* Now change the text of the dynamic menu items. */
    for( i = 0;
         i < CTA_MEN_TOT_LIT && pstMenData->stDynLitData[i].szName[0] != 0;
         i++)
    {
        /* Need this because PM does not let you change text of a */
        /* hidden MI.                                             */
        if (pstMenData->stMenStatus[i].usShow == 0)
        {
            sRetCode = FndCommandShow( TAS_hwnd,
                                       pWidNames[i],
                                       &ErrorBlock);

            sRetCode = FndCommandSetText( TAS_hwnd,
                                          pWidNames[i],
                                          pstMenData->stDynLitData[i].szName,
                                          &ErrorBlock);

            sRetCode = FndCommandHide( TAS_hwnd,
                                       pWidNames[i],
                                       &ErrorBlock);
        }
        else

            sRetCode = FndCommandSetText( TAS_hwnd,
                                          pWidNames[i],
                                          pstMenData->stDynLitData[i].szName,
                                          &ErrorBlock);
    }

    TaErrFuncStopArch("_TaMenActivate");

} /* End TaMenActivate  */

/****************************************************************************
*
*  Function         : _TaMenItemAdd
*
*  Description      : This changes the text of a menu item and sets the
*                     status flag to enabled and shown.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  02/15/95  SR           Created.
*
****************************************************************************/
VOID TAENTRYFIX _TaMenItemAdd ( PTTA_CHAR           pszNewItem,
                                PTTA_CBK            pfuncUserCbk,
                                PCALLBACKEVENTINFO  pEventInfo,
                                PEAIA               pEAIA,
                                PTTA_WESMAPNAME     pWesMap,
                                PTTA_VOID           pWindContextData,
                                PTTA_ABHI           pABHI,
                                PTTA_CHAR           pszFileName,
                                INT                 iLineNumber)
{
    SHORT sRetCode = ETA_OK;
    CHAR  szRetMsg[50];

    TaErrFuncStartArch ("_TaMenItemAdd");

    szRetMsg[0] = 0;

    if(uchWindowStatus != CTA_MEN_PREDISPLAY)
    {
        sRetCode = ETA_MEN_CANNOT_ADD_ITEM;
        strcpy(szRetMsg, "You can only add items in PREDISPLAY.");
    }

    else if(usMenItemCt == CTA_MEN_TOT_LIT)
    {
        sRetCode = ETA_MEN_TOO_MANY_ITEMS;
        sprintf(szRetMsg, "You can only add %d items.", CTA_MEN_TOT_LIT);
    }

    else
    {
        strncpy( pstMenData->stDynLitData[usMenItemCt].szName,
                 pszNewItem, 
                 CTA_MEN_LIT_LEN );

        /* Copy function to Dynamic Literal data info. */
        pstMenData->stDynLitData[usMenItemCt].pfuncUserCbk = pfuncUserCbk;
        /* Set status flags. */

        pstMenData->stMenStatus[usMenItemCt].usShow =
                pstMenData->stMenStatus[usMenItemCt].usEnable = 1;
 
        /* Increment item counter. */
        usMenItemCt++;

        /* Copy CBK information to window. */
        pstMenData->stDynCbkInfo.pEventInfo       = pEventInfo;
        pstMenData->stDynCbkInfo.pEAIA            = pEAIA;
        pstMenData->stDynCbkInfo.pWesMap          = pWesMap;
        pstMenData->stDynCbkInfo.pWindContextData = pWindContextData;
        pstMenData->stDynCbkInfo.pABHI            = pABHI;
    }
 
    TaErrSetAndLogArch (sRetCode,
                        0,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch("_TaMenItemAdd");

} /* End TaMenItemAdd  */


/****************************************************************************
*
*  Function         : _TaMenItemSelect
*
*  Description      : Posts interwindow message to active window, passing
*                     address of function being called.  This function
*                     called from TAS Main when dyn item is clicked.
*                     Access global variable containing menu info for
*                     active window.
*                     This function can also be called for one of the three
*                     NAA items.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  02/15/95  SR           Created.
*
****************************************************************************/
VOID TAENTRYFIX _TaMenItemSelect ( SHORT     sIndex,
                                   PTTA_VOID pEventInfo,
                                   PTTA_VOID pEAIA,
                                   PTTA_VOID pWesMap,
                                   PTTA_VOID pWindContextData,
                                   PTTA_ABHI pABHI,
                                   PTTA_CHAR pszFileName,
                                   INT       iLineNumber)

{
    SHORT   sRetCode = ETA_OK;

    TaErrFuncStartArch ("_TaMenItemSelect");

    /* Commented out because implemenation is through interwindow post. */
    /* If changed to the direct call method, will have to change.       */
    /*(*pstMenData->stDynLitData[sIndex].pfuncUserCbk) 
                     ( pstMenData->stDynCbkInfo.pEventInfo,
                       pstMenData->stDynCbkInfo.pEAIA,
                       NULL,
                       pstMenData->stDynCbkInfo.pWesMap,
                       pstMenData->stDynCbkInfo.pWindContextData,
                       pstMenData->stDynCbkInfo.pABHI ); */

    TaMsgInterWinPost(TaWimQueryActiveHWND(),
                      (PTTA_VOID)pstMenData->stDynLitData[sIndex].pfuncUserCbk,
                      CTA_MSG_DYN_FUNC_CALL );

    TaErrSetAndLogArch (sRetCode,
                        0,
                        "",
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch("_TaMenItemSelect");

}  /* End TaMenItemSelect  */


/****************************************************************************
*
*  Function         : _TaMenTaxpayerItemAdd
*
*  Description      : Pushes the taxpayer's name onto the main window's File
*                     menu.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  04/19/95  AB           Created.
*
****************************************************************************/
VOID TAENTRYFIX _TaMenTaxpayerItemAdd ( PTTA_CHAR   pszName,
                                        PTTA_CHAR   pszID,
                                        PTTA_ABHI   pABHI,
                                        PTTA_CHAR   pszFileName,
                                        INT         iLineNumber  )
{
    SHORT   sRetCode  = ETA_OK;
    SHORT   sRetCode2 = ETA_OK;
    CHAR    szRetMsg[50];
    SHORT   i;
    CHAR    szTaxpayerItemText[CTA_LEN_TAXPAYER_NAME + 4];

    TaErrFuncStartArch ("_TaMenTaxpayerItemAdd");

    memset(szRetMsg, 0, 50);

    /* Push taxpayers already in list */
    for (i = usTPItemCt; i > 0; i--)
        if (i < CTA_MEN_MAX_TAXPAYERS)
            astTaxpayer[i] = astTaxpayer[i - 1];

    /* Add new taxpayer to front of list */
    strcpy(astTaxpayer[0].szName, pszName);
    strcpy(astTaxpayer[0].szID, pszID);

    /* If less than max number of taxpayers in list, show hidden item */
    if (usTPItemCt < CTA_MEN_MAX_TAXPAYERS)
    {
        sRetCode2 = FndCommandShow( TAS_hwnd,
                                    apszTaxpayerItemNames[usTPItemCt],
                                    (PTTA_FND_ERROR_BLOCK)pABHI        );

        /* Increase taxpayer count if OK */
        if (!sRetCode2)
            usTPItemCt++;
    }

    if (!sRetCode2)
    {
        for (i = 0; (i < usTPItemCt) && (!sRetCode2); i++)
        {
            /* Format taxpayer item text for each taxpayer */
            sprintf( szTaxpayerItemText,
                     "~%u. %s",
                     i + 1,
                     astTaxpayer[i].szName );

            /* Set the menu item text */
            sRetCode2 = FndCommandSetText( TAS_hwnd,
                                           apszTaxpayerItemNames[i],
                                           szTaxpayerItemText,
                                           (PTTA_FND_ERROR_BLOCK)pABHI );
        }
    }

    if (sRetCode2)
    {
        /* An FND error occurred */
        sRetCode = ETA_MEN_TPITEM_ADD_FAILED;
        sprintf(szRetMsg, "_TaMenTaxpayerItemAdd: An FND error occurred");
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaMenTaxpayerItemAdd");

} /* End TaMenTaxpayerItemAdd */



/****************************************************************************
*
*  Function         : _TaMenTaxpayerItemSelect
*
*  Description      : Looks up the taxpayer corresponding to the selected
*                     name given in the File menu and returns the internal
*                     ID of the taxpayer.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  04/19/95  AB           Created.
*
****************************************************************************/
VOID TAENTRYFIX _TaMenTaxpayerItemSelect ( USHORT       usIndex,
                                           PTTA_CHAR    pszInternalID,
                                           PTTA_CHAR    pszName,
                                           PTTA_ABHI    pABHI,
                                           PTTA_CHAR    pszFileName,
                                           INT          iLineNumber      )
{
    SHORT           sRetCode  = ETA_OK;
    SHORT           sRetCode2 = ETA_OK;
    CHAR            szRetMsg[50];

    TaErrFuncStartArch ("_TaMenTaxpayerItemSelect");

    memset(szRetMsg, 0, 50);

    /* Return the internal ID of the taxpayer with index usIndex */
    strcpy(pszInternalID, astTaxpayer[usIndex].szID);

    if (pszName)
        /* Called from TaDesWriteIniFile - return taxpayer name too */
        strcpy(pszName, astTaxpayer[usIndex].szName);

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaMenTaxpayerItemSelect");

} /* End TaMenTaxpayerItemSelect */



/****************************************************************************
*
*  Function         : _TaMenWindowItemAdd
*
*  Description      : Adds the window's title to the main window's Windows
*                     menu
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  04/07/95  AB           Created.
*
****************************************************************************/
VOID TAENTRYFIX _TaMenWindowItemAdd ( HWND      hHWND,
                                      PTTA_ABHI pABHI,
                                      PTTA_CHAR pszFileName,
                                      INT       iLineNumber  )
{
    SHORT           sRetCode  = ETA_OK;
    SHORT           sRetCode2 = ETA_OK;
    CHAR            szRetMsg[50];
    CHAR            szWindowTitle[MAX_WINDOWTITLELEN + 1];
    PTTA_WINLIST    pstWindowList;
    CHAR            szWindowItemText[MAX_WINDOWTITLELEN + 4];
    SHORT           i;

    TaErrFuncStartArch ("_TaMenWindowItemAdd");

    memset(szRetMsg, 0, 50);
    usWinItemCt++;
    pstWindowList = TaWimQueryWindowList();

    /* Query the window's title */
    sRetCode2 = FndWindowQueryText( hHWND,
                                    MAX_WINDOWTITLELEN + 1,
                                    szWindowTitle,
                                    (PTTA_FND_ERROR_BLOCK)pABHI );

    /* Add the handle and title to the list of Windows menu items */
    pstWindowList->stWindowLiterals[usWinItemCt - 1].hHWND = hHWND;
    strcpy( pstWindowList->stWindowLiterals[usWinItemCt - 1].szLiteral,
            szWindowTitle );

    /* Create menu item text (No + Window Title) */
    sprintf(szWindowItemText, "~%u. %s", usWinItemCt, szWindowTitle);

    /* Show the menu item */
    sRetCode2 = FndCommandShow( pstWindowList->hMainWindowHWND,
                                apszWindowItemNames[usWinItemCt - 1],
                                (PTTA_FND_ERROR_BLOCK)pABHI       );
    if (!sRetCode2)
        /* Set the text of the menu item */
        sRetCode2 = FndCommandSetText( TAS_hwnd,
                                       apszWindowItemNames[usWinItemCt - 1],
                                       szWindowItemText,
                                       (PTTA_FND_ERROR_BLOCK)pABHI       );

    if (sRetCode2)
    {
        /* Hide the menu item if an error occurred */
        FndCommandHide( TAS_hwnd,
                        apszWindowItemNames[usWinItemCt - 1],
                        (PTTA_FND_ERROR_BLOCK)pABHI           );

        usWinItemCt--;

        sRetCode = ETA_MEN_WINITEM_ADD_ERROR;
        sprintf(szRetMsg, "_TaMenWindowItemAdd: Unable to add window to Windows menu");
    }
    else
        _TaMenWindowItemCheck( hHWND,
                               pstWindowList->apstWindow[1]
                                   ? pstWindowList->apstWindow[1]->hHWND
                                   : 0,
                               pABHI,
                               pszFileName,
                               iLineNumber                           );

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaMenWindowItemAdd");

} /* End TaMenWindowItemAdd */


/****************************************************************************
*
*  Function         : _TaMenWindowItemCheck
*
*  Description      : Checks the window's item in the Windows menu and
*                     unchecks the window item that was previously checked.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  05/04/95  AB           Created.
*
****************************************************************************/
VOID TAENTRYFIX _TaMenWindowItemCheck ( HWND        hActive,
                                        HWND        hPreviouslyActive,
                                        PTTA_ABHI   pABHI,
                                        PTTA_CHAR   pszFileName,
                                        INT         iLineNumber        )
{
    SHORT           sRetCode  = ETA_OK;
    SHORT           sRetCode2 = ETA_OK;
    CHAR            szRetMsg[50];
    PTTA_WINLIST    pstWindowList;
    SHORT           i;

    TaErrFuncStartArch ("_TaMenWindowItemCheck");

    memset(szRetMsg, 0, 50);
    pstWindowList = TaWimQueryWindowList();

    if (hPreviouslyActive)
    {
        for (i = 0;
             (i < CTA_WIM_MAX_WINDOWS) &&
              (pstWindowList->stWindowLiterals[i].hHWND != hPreviouslyActive);
             i++);

        sRetCode2 = FndCommandUncheckMenu( TAS_hwnd,
                                           apszWindowItemNames[i],
                                           (PTTA_FND_ERROR_BLOCK)pABHI );
    }

    if (!sRetCode2)
    {
        for (i = 0;
             (i < CTA_WIM_MAX_WINDOWS) &&
                  (pstWindowList->stWindowLiterals[i].hHWND != hActive);
             i++);

        sRetCode2 = FndCommandCheckMenu( TAS_hwnd,
                                         apszWindowItemNames[i],
                                         (PTTA_FND_ERROR_BLOCK)pABHI );
    }

    if (sRetCode2)
    {
        sRetCode = ETA_MEN_WINITEM_CHK_ERROR;
        sprintf(szRetMsg, "_TaMenWindowItemCheck: An FND error occurred");
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaMenWindowItemCheck");

} /* End TaMenWindowItemCheck */



/****************************************************************************
*
*  Function         : _TaMenWindowItemRemove
*
*  Description      : Removes the window's title from the main window's
*                     Windows menu
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  04/07/95  AB           Created.
*
****************************************************************************/
VOID TAENTRYFIX _TaMenWindowItemRemove ( HWND      hHWND,
                                         PTTA_ABHI pABHI,
                                         PTTA_CHAR pszFileName,
                                         INT       iLineNumber  )
{
    SHORT           sRetCode  = ETA_OK;
    SHORT           sRetCode2 = ETA_OK;
    CHAR            szRetMsg[50];
    CHAR            szWindowItemText[MAX_WINDOWTITLELEN + 4];
    PTTA_WINLIST    pstWindowList;
    SHORT           i;

    TaErrFuncStartArch ("_TaMenWindowItemAdd");

    memset(szRetMsg, 0, 50);
    pstWindowList = TaWimQueryWindowList();

    /* Find the index of the window's entry in the Windows menu */
    for ( i = 0;
          (i < CTA_WIM_MAX_WINDOWS) &&
                  (pstWindowList->stWindowLiterals[i].hHWND != hHWND);
          i++                                                         );

    /* Only try to remove item if it was found in the list */
    if (i < CTA_WIM_MAX_WINDOWS)
    {
        /* Uncheck window item */
        sRetCode2 = FndCommandUncheckMenu( TAS_hwnd,
                                           apszWindowItemNames[i],
                                           (PTTA_FND_ERROR_BLOCK)pABHI );

        if (!sRetCode2)
        {
            if (i + 1 < usWinItemCt)
                /* Advance the bottom part of the list by one */
                for (; i < usWinItemCt - 1; i++)
                {
                    pstWindowList->stWindowLiterals[i].hHWND =
                            pstWindowList->stWindowLiterals[i + 1].hHWND;
                    strcpy( pstWindowList->stWindowLiterals[i].szLiteral,
                            pstWindowList->stWindowLiterals[i + 1].szLiteral);
                }

            /* Hide the bottom item */
            sRetCode2 = FndCommandHide( TAS_hwnd,
                                        apszWindowItemNames[usWinItemCt - 1],
                                        (PTTA_FND_ERROR_BLOCK)pABHI );
        }

        if (sRetCode2)
        {
            sRetCode = ETA_MEN_WINITEM_RM_ERROR;
            sprintf(szRetMsg, "_TaMenWindowItemAdd: Uncheck or hide menu item failed");
        }
        else
        {
            usWinItemCt--;

            /* Redefine the text of the window items */
            for (i = 0; i < usWinItemCt; i++)
            {
                /* Create menu item text (No + Window Title) */
                sprintf( szWindowItemText,
                         "~%u. %s",
                         i + 1,
                         pstWindowList->stWindowLiterals[i].szLiteral);

                /* Set the text of the menu item */
                sRetCode2 = FndCommandSetText( TAS_hwnd,
                                               apszWindowItemNames[i],
                                               szWindowItemText,
                                               (PTTA_FND_ERROR_BLOCK)pABHI );
            }
        }
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaMenWindowItemAdd");

} /* End TaMenWindowItemAdd */


/****************************************************************************
*
*  Function         : _TaMenWindowItemSelect
*
*  Description      : Sets focus to the window corresponding to the selected
*                     item in the Windows menu
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  04/07/95  AB           Created.
*
****************************************************************************/
VOID TAENTRYFIX _TaMenWindowItemSelect ( USHORT    usIndex,
                                         PTTA_ABHI pABHI,
                                         PTTA_CHAR pszFileName,
                                         INT       iLineNumber  )
{
    SHORT           sRetCode  = ETA_OK;
    SHORT           sRetCode2 = ETA_OK;
    CHAR            szRetMsg[50];
    PTTA_WINLIST    pstWindowList;
    SHORT           i;

    TaErrFuncStartArch ("_TaMenWindowItemSelect");

    memset(szRetMsg, 0, 50);
    pstWindowList = TaWimQueryWindowList();

    _TaWimSetFocus( pstWindowList->stWindowLiterals[usIndex].hHWND,
                    pABHI,
                    pszFileName,
                    iLineNumber  );

    if (!TaErrOK)
    {
        sRetCode = ETA_MEN_WINITEM_SEL_ERROR;
        sprintf(szRetMsg, "_TaMenWindowItemSelect: TaWimSetFocus failed");
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaMenWindowItemSelect");

} /* End TaMenWindowItemSelect */



/****************************************************************************
*
*  Function         : _TaMenNaaAddFunc
*
*  Description      : Adds function pointer to memory for the NAA class
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  04/07/95  AB           Created.
*
****************************************************************************/
SHORT TAENTRYFIX _TaMenNaaAddFunc ( USHORT    usIndex,
                                    PTTA_CBK  pNaaFunc )
{
    SHORT   sRetCode  = ETA_OK;

    TaErrFuncStartArch ("_TaMenNaaAddFunc");

    if( (usIndex >= CTA_DYN_NOTES_ADD) &&
        (usIndex <= CTA_DYN_AUDIT_TRAIL) )

        /* If implementation changes to a direct call, must add */
        /* callback info here as in above in men item add.      */
        pstMenData->stDynLitData[usIndex].pfuncUserCbk = pNaaFunc;

    else
        sRetCode = ETA_MEN_NAA_RANGE_ERROR;

    TaErrFuncStopArch ("_TaMenNaaAddFunc");
    return(sRetCode);

} /* End TaMenWindowItemSelect */



/****************************************************************************
*        A R C H I T E C T U R E - I N T E R N A L - F U N C T I O N S
****************************************************************************/

/****************************************************************************
*
*  Function         : __TaMenGetWidgetName
*                     
*  Description      : This function returns the index of the user's menu item.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  02/15/95  SR           Created.
*
****************************************************************************/
STATIC SHORT __TaMenGetWidgetName(PTTA_CHAR pszItemName)
{
    SHORT i = 0;

    TaErrFuncStartArch ("__TaMenGetWidgetName");

    for(i = 0; i < CTA_MEN_TOT_LIT; i++)

        if( !strcmp(pszItemName, pstMenData->stDynLitData[i].szName) )
            return(i);

    TaErrFuncStopArch("__TaMenGetWidgetName");
    return (-1);
} /* End TaMenGetWidgetName */


/****************************************************************************
*
*  Function         : __TaMenGetWidgetName
*
*  Description      : Gets index of PB that MI is linked to if link exists.
*                     Returns -1 otherwise.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  04/10/95  SR           Created.
*
****************************************************************************/
STATIC SHORT __TaMenGetLinkIndex( SHORT sIndex )
{
    SHORT   sMIStartLinkIndex;
    SHORT   sPBStartLinkIndex;
    SHORT   sLinkOffset;

    TaErrFuncStartArch ("__TaMenGetWidgetName");

    /* First see if index in link range.  */
    /* If it is, return PB index.         */
    /* Items in list are orders as follows: Dyn MIs, MIs w/ no link, */
    /* MIs w/ link, PBs w/ no link and PBs w/ link.     */
    /* It is very important that the four constants are maintainted!!! */

    sMIStartLinkIndex = CTA_MEN_TOT_ITEM - CTA_MEN_TOT_LINK;

    if( sMIStartLinkIndex <= sIndex )
    {
        sPBStartLinkIndex = CTA_MEN_TOT_PB_ITEM - CTA_MEN_TOT_LINK;
        sLinkOffset = sIndex - sMIStartLinkIndex;

        TaErrFuncStopArch("__TaMenGetLinkIndex");
        return(sPBStartLinkIndex + sLinkOffset);
    }

    TaErrFuncStopArch("__TaMenGetLinkIndex");

    return (-1);
} /* End __TaMenGetLinkIndex */

/****************************************************************************
*  End of file TAMEN.c
****************************************************************************/

/****************************************************************************
*
*  File Name        : TADES.C
*                     
*  Description      : Window instance management APIs
*
*  Public Functions : _TaDesReadIniFile
*                     _TaDesSetTitle
*                     _TaDesWriteIniFile
*
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  04/19/95  AB           Created.
*
****************************************************************************/

#ifdef DTA_OS2_APP
#define CTA_DLL_NAME "TADESO"
#endif

/****************************************************************************
*  #include Files
****************************************************************************/

#define  DTA_ERR_INCL
#define  DTA_WIM_INCL
#define  DTA_MEN_INCL

#include <tasarch.h>
#include "tades.h"


/****************************************************************************
*  #define Constants
****************************************************************************/
#define CTA_DES_RET_MSG_SIZE        100
#define CTA_DES_LEN_TITLE           70
#define CTA_DES_MAX_LINE_LEN        128

#define CTA_DES_INI_FILE            getenv("TA_INI_FILE")

#define CTA_DES_DELIM_MODE_LEFT     '['
#define CTA_DES_DELIM_MODE_RIGHT    "]"
#define CTA_DES_DELIM_NAME_ID       ":"

#define CTA_DES_STR_BLANK_LINE      "\n"
#define CTA_DES_STR_TAXPAYERS       "TAXPAYERS"

#define CTA_DES_MODE_NONE          -1
#define CTA_DES_MODE_TAXPAYERS      0

#define CTA_DES_MODE_FIRST          CTA_DES_MODE_TAXPAYERS


/****************************************************************************
*  Global variables for this source file
****************************************************************************/
STATIC PTTA_CHAR apszModeIndicators[] =
{
    CTA_DES_STR_TAXPAYERS,

    NULL
};


/****************************************************************************
*  #define Macros
****************************************************************************/

/****************************************************************************
*  Internal function prototypes
****************************************************************************/


/****************************************************************************
*                 P U B L I C - F U N C T I O N S
****************************************************************************/

/****************************************************************************
*
*  Function         : _TaDesReadIniFile
*                     
*  Description      : Reads the .INI file and initializes the appropriate
*                     structures.  Called from PREDISPLAY of the main window.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  04/19/95  AB           Created.
*
****************************************************************************/

VOID TAENTRYFIX _TaDesReadIniFile ( PTTA_ABHI   pABHI,
                                    PTTA_CHAR   pszFileName,
                                    INT         iLineNumber  )
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    CHAR      szRetMsg[CTA_DES_RET_MSG_SIZE];
    PTTA_CHAR pszIniFile;
    PTTA_FILE pIniFile;
    SHORT     sMode = CTA_DES_MODE_NONE;
    SHORT     i = 0;
    CHAR      szLine[CTA_DES_MAX_LINE_LEN + 1];
    PTTA_CHAR pszMode;
    PTTA_CHAR pszName;
    PTTA_CHAR pszID;
    BOOL      fOK = TRUE;

    TaErrFuncStartArch ("_TaDesReadIniFile");

    memset(szRetMsg, 0, CTA_DES_RET_MSG_SIZE);

    if ((pszIniFile = CTA_DES_INI_FILE) == NULL)
        pszIniFile = "tas.ini";

    if (pIniFile = fopen(pszIniFile, "r"))
    {
        while ((fgets(szLine, CTA_DES_MAX_LINE_LEN, pIniFile)) && (fOK))
        {
            if (szLine[0] == CTA_DES_DELIM_MODE_LEFT)
            {
                pszMode = strtok(szLine + 1, CTA_DES_DELIM_MODE_RIGHT);

                if (!strcmp(pszMode, CTA_DES_STR_TAXPAYERS))
                    sMode = CTA_DES_MODE_TAXPAYERS;
            }
            else if (szLine[0] != '\n')  /* Skip blank lines */
                switch (sMode)
                {
                    case CTA_DES_MODE_NONE :

                        break;

                    case CTA_DES_MODE_TAXPAYERS :

                        pszName = strtok(szLine, CTA_DES_DELIM_NAME_ID);
                        pszID = strtok(NULL, "\n");

                        if ((pszName) && (pszID))
                            TaMenTaxpayerItemAdd(pszName, pszID);
                        else
                        {
                            sRetCode = ETA_DES_INI_FILE_ERROR;
                            sprintf(szRetMsg, "_TaDesReadIniFile: Error in .INI file");

                            fOK = FALSE;
                        }

                        break;

                    default :

                        break;
                }
        }

        fclose(pIniFile);
    }
    else
    {
        sRetCode = ETA_DES_NO_INI_FILE;
        sprintf(szRetMsg, "_TaDesReadIniFile: No .INI file, check TA_INI_FILE variable");
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaDesReadIniFile");
} /* End TaDesReadIniFile */



/****************************************************************************
*
*  Function         : _TaDesSetTitle
*                     
*  Description      : Sets the title of the TAS desktop depending on the
*                     active taxpayer/case/etc.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  04/19/95  AB           Created.
*
****************************************************************************/

VOID TAENTRYFIX _TaDesSetTitle ( HWND           hHWND,
                                 PTTA_TITLEDATA pstTitleData,
                                 PTTA_ABHI      pABHI,
                                 PTTA_CHAR      pszFileName,
                                 INT            iLineNumber  )
{
    SHORT           sRetCode  = ETA_OK;
    SHORT           sRetCode2 = ETA_OK;
    CHAR            szRetMsg[CTA_DES_RET_MSG_SIZE];
    PTTA_WINLIST    pstWindowList;
    CHAR            szTitleString[CTA_DES_LEN_TITLE + 1];
    USHORT          usIndex;

    TaErrFuncStartArch ("_TaDesSetTitle");

    memset(szRetMsg, 0, CTA_DES_RET_MSG_SIZE);

    /* Query the window list */
    pstWindowList = TaWimQueryWindowList();

    /* Get the window's index in the window list */
    if (TaWimValidHandle(hHWND, &usIndex))
    {
        /* pstTitleData is always NULL, except in PREDISPLAY */
        if (pstTitleData)
            pstWindowList->apstWindow[usIndex]->stTitleData = *pstTitleData;

        /* Format title text depending on whether case ID exists */
        if (pstWindowList->apstWindow[usIndex]->stTitleData.szCaseID[0])
            sprintf(szTitleString, "TAS - %s: %s/%c\\%.31s\\%s",
                    pstWindowList->apstWindow[usIndex]->stTitleData.szTaxpayerIDType,
                    pstWindowList->apstWindow[usIndex]->stTitleData.szTaxpayerID,
                    pstWindowList->apstWindow[usIndex]->stTitleData.chIDOccurrence,
                    pstWindowList->apstWindow[usIndex]->stTitleData.szTaxpayerName,
                    pstWindowList->apstWindow[usIndex]->stTitleData.szCaseID          );
        else if (pstWindowList->apstWindow[usIndex]->stTitleData.szTaxpayerName[0])
            sprintf(szTitleString, "TAS - %s: %s/%c\\%.42s",
                    pstWindowList->apstWindow[usIndex]->stTitleData.szTaxpayerIDType,
                    pstWindowList->apstWindow[usIndex]->stTitleData.szTaxpayerID,
                    pstWindowList->apstWindow[usIndex]->stTitleData.chIDOccurrence,
                    pstWindowList->apstWindow[usIndex]->stTitleData.szTaxpayerName    );
        else
            strcpy(szTitleString, "TAS");
    }
    else if (hHWND == pstWindowList->hMainWindowHWND)
        /* The main window has focus */
        strcpy(szTitleString, "TAS");

    /* Copy title text to desktop title bar */
    sRetCode2 = FndWindowSetText( pstWindowList->hMainWindowHWND,
                                  szTitleString,
                                  (PTTA_FND_ERROR_BLOCK)pABHI     );

    if (sRetCode2)
    {
        /* An FND error occurred */
        sRetCode = ETA_DES_SET_TITLE_FAILED;
        sprintf(szRetMsg, "_TaDesSetTitle: Couldn't set desktop title");
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaDesSetTitle");
} /* End TaDesSetTitle */



/****************************************************************************
*
*  Function         : _TaDesWriteIniFile
*                     
*  Description      : Writes the .INI file.  Called from PREDESTROY of the
*                     main window.
*
*  Revision History :
*  Date      Revised By   Description
*  --------  -----------  ------------------------------------------------
*  04/19/95  AB           Created.
*
****************************************************************************/

VOID TAENTRYFIX _TaDesWriteIniFile ( PTTA_ABHI          pABHI,
                                     PTTA_CHAR          pszFileName,
                                     INT                iLineNumber     )
{
    SHORT     sRetCode  = ETA_OK;
    SHORT     sRetCode2 = ETA_OK;
    CHAR      szRetMsg[CTA_DES_RET_MSG_SIZE];
    PTTA_CHAR pszIniFile;
    PTTA_FILE pIniFile;
    SHORT     sMode = CTA_DES_MODE_FIRST;
    SHORT     i;
    CHAR      szLine[CTA_DES_MAX_LINE_LEN + 1];
    CHAR      szTaxpayerID[CTA_LEN_INTERNAL_ID + 1];
    CHAR      szTaxpayerName[CTA_LEN_TAXPAYER_NAME + 1];

    TaErrFuncStartArch ("_TaDesWriteIniFile");

    memset(szRetMsg, 0, CTA_DES_RET_MSG_SIZE);

    if ((pszIniFile = CTA_DES_INI_FILE) == NULL)
        pszIniFile = "tas.ini";

    if (pIniFile = fopen(pszIniFile, "r"))
    {
        while (apszModeIndicators[sMode])
        {
            sprintf( szLine, "%c%s%s\n",
                     CTA_DES_DELIM_MODE_LEFT,
                     apszModeIndicators[sMode],
                     CTA_DES_DELIM_MODE_RIGHT   );

            fputs(szLine, pIniFile);

            switch (sMode)
            {
                case CTA_DES_MODE_TAXPAYERS :

                    for (i = CTA_MEN_TAXPAYER_5; i >= CTA_MEN_TAXPAYER_1; i--)
                    {
                        _TaMenTaxpayerItemSelect( i,
                                                  szTaxpayerID,
                                                  szTaxpayerName,
                                                  pABHI,
                                                  pszFileName,
                                                  iLineNumber     );

                        sprintf( szLine, "%s%s%s\n",
                                 szTaxpayerName,
                                 CTA_DES_DELIM_NAME_ID,
                                 szTaxpayerID           );

                        fputs(szLine, pIniFile);
                    }

                    break;

                default :

                    break;
            }

            fputs(CTA_DES_STR_BLANK_LINE, pIniFile);

            sMode++;
        }

        fclose(pIniFile);
    }
    else
    {
        sRetCode = ETA_DES_ERROR_CREATE_FILE;
        sprintf(szRetMsg, "_TaDesWriteIniFile: Error opening .INI file, check TA_INI_FILE variable");
    }

    TaErrSetAndLogArch (sRetCode,
                        sRetCode2,
                        szRetMsg,
                        pABHI,
                        pszFileName,
                        iLineNumber);

    TaErrFuncStopArch ("_TaDesWriteIniFile");
} /* End TaDesWriteIniFile */



/****************************************************************************
*        A R C H I T E C T U R E - I N T E R N A L - F U N C T I O N S
****************************************************************************/



/****************************************************************************
*  End of file TADES.c
****************************************************************************/

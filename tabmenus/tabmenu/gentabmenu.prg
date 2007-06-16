**************************************************************************************
*$PROGRAM$ GenTabMenu
*$CREATED$ 15/02/2007
**************************************************************************************
LPARAMETERS vcProjDBF, vnRecno

LOCAL llReturn

STORE .f. TO llReturn

IF PARAMETERS() = 2
  *-- We have the information we need to proceed.
  IF spSetUp(m.vcProjDBF, m.vnRecno)
    llReturn = spGenerate(m.vcProjDBF, m.vnRecno)
  ENDIF
  DO spCleanUp WITH m.llReturn
ELSE
  *-- Display the error message
  MESSAGEBOX("You have not passed the correct number of parameters.", 16, "Tab Menu Generator")
ENDIF

RETURN IIF(m.llReturn, 0, 1)

**************************************************************************************
*$FUNCTION$ spSetUp()
*$CREATED$ 15/02/2007
**************************************************************************************
FUNCTION spSetUp(vcProjDBF, vnRecno)
  LOCAL llReturn, lcOutFile, lnSelect, lcTmpFile
  
  llReturn  = .t.
  lnSelect  = 0
  lcOutFile = ""
  lcTmpFile = ""

  CLEAR PROGRAM
  CLEAR GETS
  
  *-- Open the project table again 
  SELECT 0
  USE (m.vcProjDBF) AGAIN
  lnSelect = SELECT()
  
  IF RECCOUNT() >= m.vnRecno
    GO m.vnRecno
    lcOutFile  = ALLTRIM(outfile)
  ELSE
    llReturn = .f.
  ENDIF
  
  *-- Close the project table opened here
  USE IN (m.lnSelect)
  
  *-- Create the cursor to hold the system menu data
  lcTmpFile = ADDBS(SYS(2023)) + SYS(2015)
  STRTOFILE(LOWER(STRTRAN(SYS(2013)," ",CHR(13))), lcTmpFile,0)
  
  SELECT 0
  CREATE CURSOR w_menudata (sysmenuname C(40))
  APPEND FROM (lcTmpFile) TYPE DELIMITED

  ERASE (lcTmpFile)

  IF m.llReturn
    SET TEXTMERGE TO (lcOutFile) NOSHOW
    SET TEXTMERGE ON
  ENDIF
  
  RETURN m.llReturn
ENDFUNC

**************************************************************************************
*$FUNCTION$ spCleanUp()
*$CREATED$ 15/02/2007
**************************************************************************************
FUNCTION spCleanUp(vlReturn)
  LOCAL llReturn, lcOutFile
  llReturn = .t.
  lcOutFile = SET("TEXTMERGE",2)
  
  IF USED("w_menudata")
    USE IN w_menudata
  ENDIF
    
  SET TEXTMERGE TO 
  SET TEXTMERGE OFF
  
  IF vlReturn = .f.
    *-- this means that something went wrong
    * so we should delete the output file
    ERASE (lcOutFile)
  ENDIF

  RETURN m.llReturn
ENDFUNC

**************************************************************************************
*$FUNCTION$ spGenerate()
*$CREATED$ 15/02/2007
**************************************************************************************
FUNCTION spGenerate(vcProjDBF, vnRecno)
  PRIVATE poMenuDefault
  
  LOCAL llReturn, lnSelect, lcMenuFile

  llReturn = .t.
  lnSelect = 0
  
  *-- Open the project table again 
  SELECT 0
  USE (m.vcProjDBF) AGAIN
  lnSelect = SELECT()
  
  IF RECCOUNT() >= m.vnRecno
    GO m.vnRecno
    lcMenuFile = ALLTRIM(name)
  ENDIF
  
  *-- Close the project table opened here
  USE IN (m.lnSelect)
  
  IF FILE(lcMenuFile)
    *-- Open the menu table
    SELECT 0
    USE (m.lcMenuFile) AGAIN
    lnSelect = SELECT()
    
    LOCATE FOR objtype = 1 AND ObjCode = 22
    IF FOUND()
      SCATTER MEMO NAME poMenuDefault
      
      *-- Add some additional properties to the default row
      ADDPROPERTY(poMenuDefault, "ExecuteEventCode", "")
      ADDPROPERTY(poMenuDefault, "DefEvent", "MenuDefault")
      ADDPROPERTY(poMenuDefault, "DefEventCode", "")
    ENDIF
    
    LOCATE FOR objtype = 2 AND objcode = 1
    IF FOUND()
      *-- Store any code attached to the system menu bar to the default event
      poMenuDefault.DefEventCode = ALLTRIM(procedure)
      
      *-- We are in a valid menu table so we should write out the header block
      llReturn = llReturn AND spProcessHeader()
      
      IF NOT EMPTY(poMenuDefault.SetUp) 
        *-- We need to create a setup code snippet
        llReturn = llReturn AND spProcessSetup()
      ENDIF
      
      *-- Begin the work of processing the menu data
      llReturn = llReturn AND spProcessMenu(m.lcMenuFile, 0, LevelName)

      IF NOT EMPTY(poMenuDefault.CleanUp) 
        *-- We need to create a cleanup code snippet
        llReturn = llReturn AND spProcessCleanup()
      ENDIF

      *-- Generate the footer
      llReturn = llReturn AND spProcessFooter()
    ENDIF
    
    *-- Close the menu table opened here
    USE IN (lnSelect)
  ENDIF
  
  *-- release the private variables used
  RELEASE poMenuDefault
  
  RETURN m.llReturn
ENDFUNC

**************************************************************************************
*$FUNCTION$ spProcessMenu()
*$CREATED$ 15/02/2007
**************************************************************************************
FUNCTION spProcessMenu(vcMenuFile, vnLevel, vcLevelName, vcItemKey, vnTabNumber)
  LOCAL llReturn, lcCursor, lnSelect, loMenuData, lnMenuFile, lnTabNumber, ;
        llDefPopup
  
  lnSelect    = SELECT()
  lcCursor    = "r" + SYS(2015)
  lnMenuFile  = 0
  vcItemKey   = IIF(EMPTY(vcItemKey),"",vcItemKey)
  lnTabNumber = IIF(EMPTY(vnTabNumber), 0, vnTabNumber)
  llReturn    = .t.
  llDefPopup  = .f.
  
  *-- Determine the top level menu data
  SELECT *, RECNO() AS itemrecno FROM (m.vcMenuFile) WHERE (LevelName = vcLevelName) AND (VAL(ItemNum) > 0) AND (ALLTRIM(prompt) <> "\-") INTO CURSOR (lcCursor)
  
  SCAN FOR NOT DELETED()
    SCATTER MEMO NAME loMenuData
    
    *-- Add the properties needed to the data
    ADDPROPERTY(loMenuData, "Submenu", .f.)
    ADDPROPERTY(loMenuData, "MarkExp", "")
    ADDPROPERTY(loMenuData, "ActionExp", "")
    ADDPROPERTY(loMenuData, "ActionTip", "")
    ADDPROPERTY(loMenuData, "BarSize", "NORM")
    
    IF "\+" $ loMenuData.Prompt
      *-- The prompt indicates that the menu option has a submenu
      loMenuData.Submenu = .t.
    ENDIF
    
    IF "*:MARKEXP" $ UPPER(loMenuData.Comment)
      *-- The menu bar has additional directives in the comment
      * which need to be parsed and included in the menu data object
      loMenuData.MarkExp = spGetDirective("*:MARKEXP", loMenuData.Comment)
    ENDIF
    
    IF "*:ACTIONEXP" $ UPPER(loMenuData.Comment)
      *-- The menu bar has additional directives in the comment
      * which need to be parsed and included in the menu data object
      loMenuData.ActionExp = spGetDirective("*:ACTIONEXP", loMenuData.Comment)
    ENDIF

    IF "*:ACTIONTIP" $ UPPER(loMenuData.Comment)
      *-- The menu bar has additional directives in the comment
      * which need to be parsed and included in the menu data object
      loMenuData.ActionTip = spGetDirective("*:ACTIONTIP", loMenuData.Comment)
    ENDIF

    IF "*:BARSIZE" $ UPPER(loMenuData.Comment)
      *-- The menu bar has additional directives in the comment
      * which need to be parsed and included in the menu data object
      loMenuData.BarSize = spGetDirective("*:BARSIZE", loMenuData.Comment)
    ENDIF
        
    *-- Format the text
    loMenuData.Prompt = STRTRAN(loMenuData.Prompt, "\-", "")
    loMenuData.Prompt = STRTRAN(loMenuData.Prompt, "\+", "")
    loMenuData.Prompt = CHRTRAN(loMenuData.Prompt, "\<", "")
    
    IF EMPTY(loMenuData.Prompt)
      *-- No data here so skip it
      LOOP
    ENDIF

    loMenuData.KeyLabel = STRTRAN(UPPER(loMenuData.KeyLabel), "CTRL+", "")
    loMenuData.KeyLabel = STRTRAN(UPPER(loMenuData.KeyLabel), "ALT+", "")
    
    IF vnLevel = 0
      *-- Increment the tab number if we are on the top most level
      lnTabNumber = lnTabNumber + 1
    ENDIF
    *-- Build up the item key as a string based on the structure of the menu
    lcItemKey = vcItemKey + IIF(EMPTY(vcItemKey),"",".") + UPPER(CHRTRAN(loMenuData.Prompt," .",""))

    IF loMenuData.objtype = 3 AND loMenuData.objCode = 77
      *-- The way to determine this seems to be to position on the relevant menu record 
      * and then find the next popup record in the data
      SELECT 0
      USE (m.vcMenuFile) AGAIN
      lnMenuFile = SELECT()
      
      GO loMenuData.ItemRecno
      LOCATE REST FOR objtype = 2 AND objcode = 0
      IF FOUND() AND (numItems > 0 OR loMenuData.Submenu)
        IF loMenuData.Submenu AND vnLevel > 0
          *-- The submenu type is treated differently if the items has been marked to 
          * display a popup submenu so in this case the submenu needs to be processed 
          * slightly differently.  They are not allowed at the top level because it
          * does not make sense to have these kinds of controls as the page tabs
          IF vnLevel = 1 
            *-- We are in the level below the menu so we need to know if the
            * default popup has been created because commands or procedures at 
            * this level need to be added to that.
            IF NOT llDefPopup
              \*-- Add the <<ALLTRIM(vcLevelName)>> default popup
              \<<"loDefPopup = _SCREEN.oTabMenu.AddPopup(''," + ALLTRIM(STR(lnTabNumber,3,0)) + ")">>
              \<<"loDefPopup.nColumns = " + STR(INT(RECCOUNT(lcCursor)/3)+IIF(MOD(RECCOUNT(lcCursor),3) = 0,0,1),3,0)>>
              \<<"loDefPopup.Width = loDefPopup.nColumns * _SCREEN.oTabMenuHandler.nDefaultItemWidth">>
              \<<"loDefPopup.Alignment = _SCREEN.oTabMenuHandler.nDefaultAlignment">>
              llDefPopup = .t.
            ENDIF
            \<<"loPopup = loDefPopup">>
          ENDIF
          \
          \<<"loItem = loPopup.AddPopupItem('" + loMenuData.Prompt + "','" + loMenuData.BarSize + "','" + loMenuData.keylabel + "')">>
          IF NOT EMPTY(loMenuData.ResName) AND loMenuData.SysRes <> 1
            \<<"loItem.cPicture = '" + loMenuData.ResName + "'">>
          ENDIF
          IF NOT EMPTY(loMenuData.SkipFor)
            \<<"loItem.cSkipForExp = [" + loMenuData.SkipFor + "]">>
          ENDIF
          IF NOT EMPTY(loMenuData.Message)
            \<<"loItem.ToolTipText = [" + loMenuData.Message + "]">>
          ENDIF
          IF NOT EMPTY(lcItemKey)
            \<<"loItem.cItemKey = '" + lcItemKey + "'">>
          ENDIF
          IF loMenuData.SubMenu
            \<<"loItem.nShowSubmenu = 1">>
          ENDIF    
          
          lcBindEvent = "u" + SYS(2015)
          
          *-- Call the function to create the submenu popup
          llReturn = llReturn AND spProcessSubMenu(m.vcMenuFile, loMenuData.ItemRecno, LEFT(ALLTRIM(Name) + SPACE(LEN(LevelName)), LEN(LevelName)), lcItemKey, lcBindEvent)
          
          \BINDEVENT(loItem, "Execute", _SCREEN.oTabMenuHandler, "<<lcBindEvent>>")        
                
        ELSE
          *-- This is a submenu so there are items below this one.  
          IF vnLevel = 0
            *-- These are the menu tabs
            \
            \*-- Add the <<loMenuData.Prompt>> Menu Tab
            \<<"loMenuTab = _SCREEN.oTabMenu.AddMenuItem('" + loMenuData.Prompt + "','" + loMenuData.keylabel + "')">>
          ELSE
            *-- These are the popups within the menu tabs
            \
            \*-- Add the <<loMenuData.Prompt>> popup
            \<<"loPopup = _SCREEN.oTabMenu.AddPopup('" + loMenuData.Prompt + "'," + ALLTRIM(STR(lnTabNumber,3,0)) + ")">>
            \<<"loPopup.Width = _SCREEN.oTabMenuHandler.nDefaultItemWidth">>
            \<<"loPopup.Alignment = _SCREEN.oTabMenuHandler.nDefaultAlignment">>
            
            IF NOT EMPTY(loMenuData.ActionExp)
              *-- The popup itself has an action that needs to be executed
              \<<"loPopup.cActionExp = " + loMenuData.ActionExp>>
              IF NOT EMPTY(loMenuData.ActionTip)
                \<<"loPopup.cActionTip = " + loMenuData.ActionTip>>
              ENDIF
            ENDIF
          ENDIF
        
          IF NOT EMPTY(procedure)
            *-- The developer has added some code to the setup of this 
            * popup so that needs to be included in the generated program
            \<<ALLTRIM(procedure)>>
          ENDIF
          llReturn = llReturn AND spProcessMenu(m.vcMenuFile, vnLevel + 1, LEFT(ALLTRIM(Name) + SPACE(LEN(LevelName)), LEN(LevelName)), lcItemKey, lnTabNumber)
        ENDIF
      ELSE
        *-- there are no submenu items so its possible that the developer
        * simply did not select the correct object type.  We will assume 
        * that its a menu item in the default popup
        IF NOT llDefPopup
          \*-- Add the <<ALLTRIM(vcLevelName)>> default popup
          \<<"loDefPopup = _SCREEN.oTabMenu.AddPopup(''," + ALLTRIM(STR(lnTabNumber,3,0)) + ")">>
          \<<"loDefPopup.nColumns = " + STR(INT(RECCOUNT(lcCursor)/3)+IIF(MOD(RECCOUNT(lcCursor),3) = 0,0,1),3,0)>>
          \<<"loDefPopup.Width = loDefPopup.nColumns * _SCREEN.oTabMenuHandler.nDefaultItemWidth">>
          \<<"loDefPopup.Alignment = _SCREEN.oTabMenuHandler.nDefaultAlignment">>
          llDefPopup = .t.
        ENDIF
        
        \
        \<<"loItem = loPopup.AddPopupItem('" + loMenuData.Prompt + "','" + loMenuData.BarSize + "','" + loMenuData.keylabel + "')">>
        IF NOT EMPTY(loMenuData.ResName)
          \<<"loItem.cPicture = '" + loMenuData.ResName + "'">>
        ENDIF
        IF NOT EMPTY(loMenuData.SkipFor)
          \<<"loItem.cSkipForExp = [" + loMenuData.SkipFor + "]">>
        ENDIF
        IF NOT EMPTY(loMenuData.Message)
          \<<"loItem.ToolTipText = [" + loMenuData.Message + "]">>
        ENDIF
        IF NOT EMPTY(lcItemKey)
          \<<"loItem.cItemKey = '" + lcItemKey + "'">>
        ENDIF

        lcEventCode  = ""
        
        DO CASE
          CASE loMenuData.ObjCode = 67
            *-- The menu item is defined as a command
            IF EMPTY(loMenuData.Command)
              lcBindEvent = poMenuDefault.DefEvent
            ELSE
              lcBindEvent = "c" + SYS(2015)
              lcEventCode = loMenuData.Command
            ENDIF
          CASE loMenuData.ObjCode = 80
            *-- The menu item is defined as a procedure
            IF EMPTY(loMenuData.procedure)
              lcBindEvent = poMenuDefault.DefEvent
            ELSE
              lcBindEvent = "p" + SYS(2015)
              lcEventCode = loMenuData.Procedure
            ENDIF
          CASE loMenuData.ObjCode = 78 AND USED("w_menudata")
            *-- The menu item is defines as a system menu bar #
            lcBindEvent = "b" + SYS(2015)
            lcEventCode = ""
            
            SELECT w_menudata
            LOCATE FOR w_menudata.sysmenuname = LOWER(loMenuData.Name)
            IF FOUND() AND NOT EMPTY(loMenuData.Name)
              DO WHILE NOT BOF("w_menudata")
                SKIP -1
                IF AT("_",w_menudata.sysmenuname,2) = 0
                  lcEventCode = "SYS(1500, '" + LOWER(loMenuData.Name) + "', '" + ALLTRIM(w_menudata.sysmenuname) + "')"
                  EXIT
                ENDIF
              ENDDO
            ELSE
              *-- Bind it to the default event
              lcBindEvent = poMenuDefault.DefEvent
            ENDIF

          OTHERWISE
            *-- The menu item needs to use the default event
            lcBindEvent = poMenuDefault.DefEvent
        ENDCASE
        
        IF NOT EMPTY(lcEventCode)
          poMenuDefault.ExecuteEventCode = poMenuDefault.ExecuteEventCode + CHR(13) + ;
          "FUNCTION " + lcBindEvent + "()" + CHR(13) + ;
          lcEventCode + CHR(13) + ;
          "ENDFUNC" + CHR(13)
        ENDIF
        
        \BINDEVENT(loItem, "Execute", _SCREEN.oTabMenuHandler, "<<lcBindEvent>>")        
      ENDIF
      
      USE IN (lnMenuFile)
    ELSE
      IF vnLevel = 0
        *-- commands in the top level are added to the quick bar
        \<<"IF FILE('" + loMenuData.Prompt + "')">>
        \<<"  loItem = _SCREEN.oTabMenu.cntQuickBar.AddItem('" + loMenuData.Prompt + "')">>
        IF NOT EMPTY(loMenuData.SkipFor)
          \<<"  loItem.cSkipForExp = [" + loMenuData.SkipFor + "]">>
        ENDIF
        IF NOT EMPTY(loMenuData.Message)
          \<<"  loItem.ToolTipText = [" + loMenuData.Message + "]">>
        ENDIF
        IF NOT EMPTY(lcItemKey)
          \<<"  loItem.cItemKey = 'QUICK." + lcItemKey + "'">>
        ENDIF
        \ENDIF
      ELSE
        *-- These are the menu items within the popups
        IF vnLevel = 1 
          *-- We are in the level below the menu so we need to know if the
          * default popup has been created because commands or procedures at 
          * this level need to be added to that.
          IF NOT llDefPopup
            \*-- Add the <<ALLTRIM(vcLevelName)>> default popup
            \<<"loDefPopup = _SCREEN.oTabMenu.AddPopup(''," + ALLTRIM(STR(lnTabNumber,3,0)) + ")">>
            \<<"loDefPopup.nColumns = " + STR(INT(RECCOUNT(lcCursor)/3)+IIF(MOD(RECCOUNT(lcCursor),3) = 0,0,1),3,0)>>
            \<<"loDefPopup.Width = loDefPopup.nColumns * _SCREEN.oTabMenuHandler.nDefaultItemWidth">>
            \<<"loDefPopup.Alignment = _SCREEN.oTabMenuHandler.nDefaultAlignment">>
            llDefPopup = .t.
          ENDIF
          \<<"loPopup = loDefPopup">>
        ENDIF
        \
        \<<"loItem = loPopup.AddPopupItem('" + loMenuData.Prompt + "','" + loMenuData.BarSize + "','" + loMenuData.keylabel + "')">>
        IF NOT EMPTY(loMenuData.ResName) AND loMenuData.SysRes <> 1
          \<<"loItem.cPicture = '" + loMenuData.ResName + "'">>
        ENDIF
        IF NOT EMPTY(loMenuData.SkipFor)
          \<<"loItem.cSkipForExp = [" + loMenuData.SkipFor + "]">>
        ENDIF
        IF NOT EMPTY(loMenuData.Message)
          \<<"loItem.ToolTipText = [" + loMenuData.Message + "]">>
        ENDIF
        IF NOT EMPTY(lcItemKey)
          \<<"loItem.cItemKey = '" + lcItemKey + "'">>
        ENDIF
        IF loMenuData.SubMenu
          \<<"loItem.nShowSubmenu = 2">>
        ENDIF
      ENDIF
      
      lcEventCode  = ""
      
      DO CASE
        CASE loMenuData.ObjCode = 67
          *-- The menu item is defined as a command
          IF EMPTY(loMenuData.Command)
            lcBindEvent = poMenuDefault.DefEvent
          ELSE
            lcBindEvent = "c" + SYS(2015)
            lcEventCode = loMenuData.Command
          ENDIF
        CASE loMenuData.ObjCode = 80
          *-- The menu item is defined as a procedure
          IF EMPTY(loMenuData.procedure)
            lcBindEvent = poMenuDefault.DefEvent
          ELSE
            lcBindEvent = "p" + SYS(2015)
            lcEventCode = loMenuData.Procedure
          ENDIF
        CASE loMenuData.ObjCode = 78 AND USED("w_menudata")
          *-- The menu item is defines as a system menu bar #
          lcBindEvent = "b" + SYS(2015)
          lcEventCode = ""
          
          SELECT w_menudata
          LOCATE FOR w_menudata.sysmenuname = LOWER(loMenuData.Name)
          IF FOUND() AND NOT EMPTY(loMenuData.Name)
            DO WHILE NOT BOF("w_menudata")
              SKIP -1
              IF AT("_",w_menudata.sysmenuname,2) = 0
                lcEventCode = "SYS(1500, '" + LOWER(loMenuData.Name) + "', '" + ALLTRIM(w_menudata.sysmenuname) + "')"
                EXIT
              ENDIF
            ENDDO
          ELSE
            *-- Bind it to the default event
            lcBindEvent = poMenuDefault.DefEvent
          ENDIF
        OTHERWISE
          *-- The menu item needs to use the default event
          lcBindEvent = poMenuDefault.DefEvent
      ENDCASE
      
      IF NOT EMPTY(lcEventCode)
        poMenuDefault.ExecuteEventCode = poMenuDefault.ExecuteEventCode + CHR(13) + ;
        "FUNCTION " + lcBindEvent + "()" + CHR(13) + ;
        lcEventCode + CHR(13) + ;
        "ENDFUNC" + CHR(13)
      ENDIF
      
      \BINDEVENT(loItem, "Execute", _SCREEN.oTabMenuHandler, "<<lcBindEvent>>")
    ENDIF

  ENDSCAN
  
  *-- Close the cursor opened here
  USE IN (lcCursor)

  *-- Reselect the previous work area
  SELECT (lnSelect)
  
  RETURN m.llReturn
ENDFUNC

**************************************************************************************
*$FUNCTION$ spProcessHeader()
*$CREATED$ 15/02/2007
**************************************************************************************
FUNCTION spProcessHeader()
  LOCAL llReturn
  llReturn = .t.

\\**************************************************************************************
\*$PROGRAM$ <<JUSTFNAME(SET("TEXTMERGE",2))>>
\*$CREATED$ <<DATE()>>
\**************************************************************************************
\

  TEXT TO TEXTMERGE

*-- Initialise the variables
LOCAL loToolbar, loMenuTab, loPopup, loItem, loDefPopup

#define WM_GETMINMAXINFO    0x0024
#define GWL_WNDPROC         (-4)
#define WM_ACTIVATEAPP      0x001C
#define WM_KEYDOWN          0x0100
#define WM_KEYUP            0x0101
#define WM_SYSKEYUP         0x0105

*-- Need to declare the Windows API command to determine the windows process handle
DECLARE INTEGER GetWindowLong IN WIN32API INTEGER hWnd, INTEGER nIndex

*-- The toolbar tabmenu container will be added to the _SCREEN object because we
* can guarantee a path to this object in all VFP applications and that way do
* not require any additional global variables the same is true for the menu event 
* handler object
_SCREEN.AddProperty('oTabMenu')
_SCREEN.AddProperty('oTabMenuHandler')

IF TYPE("_SCREEN.ActiveForm") = "O" AND _SCREEN.ActiveForm.ShowWindow = 2
  *-- The top level form exists so the tabmenu toolbar should be added to this form
  * as should the nOldProc property to store the windows processs handle
  _SCREEN.ActiveForm.AddProperty('oToolBar')
  _SCREEN.ActiveForm.AddProperty('nOldProc')

  _SCREEN.ActiveForm.oToolbar = CREATEOBJECT("tbrTabMenu")
  _SCREEN.ActiveForm.oToolbar.Left = 0 - SYSMETRIC(3) - _SCREEN.ActiveForm.oToolbar.cntTabMenu.Left
  _SCREEN.ActiveForm.oToolbar.Top = 0 - SYSMETRIC(34) - SYSMETRIC(4) - _SCREEN.ActiveForm.oToolbar.cntTabMenu.Top
  
  _SCREEN.ActiveForm.nOldProc = GetWindowLong(_SCREEN.ActiveForm.hWnd, GWL_WNDPROC)

  _SCREEN.oTabMenu = _SCREEN.ActiveForm.oToolbar.cntTabMenu
  _SCREEN.oTabMenu.nOldProc  = _SCREEN.ActiveForm.nOldProc 
  _SCREEN.oTabMenu.cCaption  = _SCREEN.ActiveForm.Caption
  _SCREEN.oTabMenu.Width     = _SCREEN.ActiveForm.Width 
  _SCREEN.oTabMenu.oMainForm = _SCREEN.ActiveForm
  
  BINDEVENT(_SCREEN.ActiveForm.hWnd, WM_ACTIVATEAPP, _SCREEN.oTabMenu, "WMEventHandler")
  BINDEVENT(_SCREEN.ActiveForm.hWnd, WM_KEYDOWN, _SCREEN.oTabMenu, "WMEventHandler")
  BINDEVENT(_SCREEN.ActiveForm.hWnd, WM_KEYUP, _SCREEN.oTabMenu, "WMEventHandler")
  BINDEVENT(_SCREEN.ActiveForm.hWnd, WM_SYSKEYUP, _SCREEN.oTabMenu, "WMEventHandler")
  BINDEVENT(_SCREEN.ActiveForm, "Resize", _SCREEN.oTabMenu, "MainFormResize")
ELSE
  *-- The screen is being used as the main form so the toolbar will be added in the VFP screen
  * as should the nOldProc property to store the windows processs handle
  _SCREEN.AddProperty('oToolBar')
  _SCREEN.AddProperty('nOldProc')
  
  _SCREEN.oToolbar = CREATEOBJECT("tbrTabMenu")
  _SCREEN.oToolbar.Left = 0 - SYSMETRIC(3) - _SCREEN.oToolbar.cntTabMenu.Left
  _SCREEN.oToolbar.Top = 0 - SYSMETRIC(34) - SYSMETRIC(4) - _SCREEN.oToolbar.cntTabMenu.Top

  _SCREEN.nOldProc = GetWindowLong(_VFP.hWnd, GWL_WNDPROC)

  _SCREEN.oTabMenu = _SCREEN.oToolbar.cntTabMenu
  _SCREEN.oTabMenu.nOldProc = _SCREEN.nOldProc 
  _SCREEN.oTabMenu.cCaption = _SCREEN.Caption
  _SCREEN.oTabMenu.Width    = _SCREEN.Width
  
  *-- Get rid of the system menu as this is supposed to replace it
  SET SYSMENU OFF

  BINDEVENT(_VFP.hWnd, WM_ACTIVATEAPP, _SCREEN.oTabMenu, "WMEventHandler")
  BINDEVENT(_VFP.hWnd, WM_KEYDOWN, _SCREEN.oTabMenu, "WMEventHandler")
  BINDEVENT(_VFP.hWnd, WM_KEYUP, _SCREEN.oTabMenu, "WMEventHandler")
  BINDEVENT(_VFP.hWnd, WM_SYSKEYUP, _SCREEN.oTabMenu, "WMEventHandler")
  BINDEVENT(_SCREEN, "Resize", _SCREEN.oTabMenu, "MainFormResize")
ENDIF

*-- Make sure that the menu event handler object exists as this is the thing
* that all menu events will be bound to
_SCREEN.otabMenuHandler = CREATEOBJECT("cusMenuEventHandler")

  ENDTEXT

  RETURN m.llreturn
ENDFUNC

**************************************************************************************
*$FUNCTION$ spProcessSetup()
*$CREATED$ 15/02/2007
**************************************************************************************
FUNCTION spProcessSetup()
  LOCAL llReturn
  llReturn = .t.

\**************************************************************************************
\*Setup code for the menu
\**************************************************************************************
\
  TEXT TO TEXTMERGE
<<poMenuDefault.Setup>>  
  ENDTEXT
    
  RETURN m.llreturn
ENDFUNC

**************************************************************************************
*$FUNCTION$ spProcessCleanup()
*$CREATED$ 15/02/2007
**************************************************************************************
FUNCTION spProcessCleanup()
  LOCAL llReturn
  llReturn = .t.

\
\**************************************************************************************
\*Cleanup code for the menu
\**************************************************************************************
\
  TEXT TO TEXTMERGE
<<poMenuDefault.Cleanup>>  
  ENDTEXT
  
  RETURN m.llreturn
ENDFUNC

**************************************************************************************
*$FUNCTION$ spProcessFooter()
*$CREATED$ 15/02/2007
**************************************************************************************
FUNCTION spProcessFooter()
  LOCAL llReturn
  llReturn = .t.

\_SCREEN.oTabMenu.SelectMenuItem(1)

\IF TYPE("_SCREEN.ActiveForm") = "O" AND _SCREEN.ActiveForm.ShowWindow = 2
\  _SCREEN.ActiveForm.oToolbar.Refresh()
\  _SCREEN.ActiveForm.oToolbar.Show()
\ELSE
\  _SCREEN.oToolbar.Refresh()
\  _SCREEN.oToolbar.Show()
\ENDIF
\
\RETURN
\
\**************************************************************************************
\*$CLASS$ cusMenuEventHandler
\**************************************************************************************
\DEFINE CLASS cusMenuEventHandler AS Custom
\
\  *-- Initialise the properties
\  nDefaultItemWidth = 150
\  nDefaultAlignment = 2
\
\**************************************************************************************
\*$METHOD$ <<poMenuDefault.DefEvent>>()
\*
\*$PURPOSE$
\* This method contains the code run by the selected menu options if the menu option 
\* has no code of its own.
\*$PURPOSE$
\**************************************************************************************
\FUNCTION <<poMenuDefault.DefEvent>>()
\<<poMenuDefault.DefEventCode>>
\ENDFUNC
\
\<<poMenuDefault.ExecuteEventCode>>
\
IF NOT EMPTY(poMenuDefault.procedure)
\<<poMenuDefault.procedure>>
ENDIF
\ENDDEFINE
\**************************************************************************************
  
  RETURN m.llreturn
ENDFUNC

**************************************************************************************
*$FUNCTION$ spProcessSubMenu()
*$CREATED$ 23/02/2007
**************************************************************************************
FUNCTION spProcessSubMenu(vcMenuFile, vnItemRecno, vcLevelName, vcItemKey, vcBindEvent)
  LOCAL llReturn, lcCursor, lnSelect, loMenuData, lcEventCode, lcItemKey, lnMenuFile, ;
        lcSubCode, lcBindEvent
  
  lnSelect    = SELECT()
  lcCursor    = "r" + SYS(2015)
  vcItemKey   = IIF(EMPTY(vcItemKey),"",vcItemKey)
  llReturn    = .t.
  lcEventCode = ""
  lcSubCode   = ""
  lcSubEvent  = ""
  lcItemKey   = ""
  lnMenuFile  = 0

  *-- Need to see if there is any specific code added to this submenu
  SELECT 0
  USE (m.vcMenuFile) AGAIN
  lnMenuFile = SELECT()
  
  GO vnItemRecno
  LOCATE REST FOR objtype = 2 AND objcode = 0
  IF FOUND() 
    IF NOT EMPTY(ALLTRIM(procedure))
      lcSubCode = "*-- Add the submenu specific code here" + CHR(13) + ;
                  ALLTRIM(procedure) + CHR(13)
    ENDIF
  ENDIF
  
  USE IN (lnMenuFile)
  
  *-- Determine the sub menu data
  SELECT *, RECNO() AS itemrecno FROM (m.vcMenuFile) WHERE (LevelName = vcLevelName) AND (VAL(ItemNum) > 0) AND (ALLTRIM(prompt) <> "\-") INTO CURSOR (lcCursor)
  
  lcEventCode = "LOCAL loItem, loSubMenu" + CHR(13) + ;
                "AEVENTS(paSource,0)" + CHR(13) + ;
                "paSource[1].lSelected = .t." + CHR(13) + ;
                "losubMenu = CREATEOBJECT('frmPopup', paSource[1], _SCREEN.oTabMenu)" + CHR(13) + ;
                "WITH losubMenu" + CHR(13) + ;
                "  *-- Resize the window" + CHR(13) + ;
                "  .Width  = _SCREEN.oTabMenuHandler.nDefaultItemWidth" + CHR(13) + ;
                "  .Height = " + STR(RECCOUNT(lcCursor)*24,3,0) + CHR(13) + ;
                "  .nPopupStyle = 1" + CHR(13) + ;
                lcSubCode + ;
                "  .Resize()" + CHR(13)
 
  SCAN FOR NOT DELETED()
    SCATTER MEMO NAME loMenuData

    *-- Add the properties needed to the data
    ADDPROPERTY(loMenuData, "Submenu", .f.)
    ADDPROPERTY(loMenuData, "MarkExp", "")

    IF "*:MARKEXP" $ UPPER(loMenuData.Comment)
      *-- The menu bar has additional directives in the comment
      * which need to be parsed and included in the menu data object
      loMenuData.MarkExp = spGetDirective("*:MARKEXP", loMenuData.Comment)
    ENDIF

    *-- Format the text
    loMenuData.Prompt = STRTRAN(loMenuData.Prompt, "\-", "")
    loMenuData.Prompt = STRTRAN(loMenuData.Prompt, "\+", "")
    loMenuData.Prompt = CHRTRAN(loMenuData.Prompt, "\<", "")
    
    IF EMPTY(loMenuData.Prompt)
      *-- No data here so skip it
      LOOP
    ENDIF

    loMenuData.KeyLabel = STRTRAN(UPPER(loMenuData.KeyLabel), "CTRL+", "")
    loMenuData.KeyLabel = STRTRAN(UPPER(loMenuData.KeyLabel), "ALT+", "")

    *-- Build up the item key as a string based on the structure of the menu
    lcItemKey = vcItemKey + IIF(EMPTY(vcItemKey),"",".") + UPPER(CHRTRAN(loMenuData.Prompt," .",""))
    
    lcEventCode = lcEventCode + "loItem = .cntPopupItems.AddPopupItem('" + loMenuData.Prompt + "', 'NORM','" + loMenuData.KeyLabel + "')" + CHR(13)
    IF NOT EMPTY(loMenuData.ResName) AND loMenuData.SysRes <> 1
      lcEventCode = lcEventCode + "loItem.cPicture = '" + loMenuData.ResName + "'" + CHR(13)
    ENDIF
    IF NOT EMPTY(loMenuData.SkipFor)
      lcEventCode = lcEventCode + "loItem.cSkipForExp = [" + loMenuData.SkipFor + "]" + CHR(13)
    ENDIF
    IF NOT EMPTY(loMenuData.Message)
      lcEventCode = lcEventCode + "loItem.ToolTipText = [" + loMenuData.Message + "]"  + CHR(13)
    ENDIF
    IF NOT EMPTY(loMenuData.MarkExp)
      lcEventCode = lcEventCode + "loItem.cMarkExp = [" + loMenuData.MarkExp + "]" + CHR(13)
    ENDIF
    IF NOT EMPTY(lcItemKey)
      lcEventCode = lcEventCode + "loItem.cItemKey = '" + lcItemKey + "'" + CHR(13)
    ENDIF
    
    lcSubEvent  = ""
    
    DO CASE
      CASE loMenuData.ObjCode = 67
        *-- The menu item is defined as a command
        IF EMPTY(loMenuData.Command)
          lcBindEvent = poMenuDefault.DefEvent
        ELSE
          lcBindEvent = "c" + SYS(2015)
          lcSubEvent = loMenuData.Command
        ENDIF
      CASE loMenuData.ObjCode = 80
        *-- The menu item is defined as a procedure
        IF EMPTY(loMenuData.procedure)
          lcBindEvent = poMenuDefault.DefEvent
        ELSE
          lcBindEvent = "p" + SYS(2015)
          lcSubEvent = loMenuData.Procedure
        ENDIF
      CASE loMenuData.ObjCode = 78 AND USED("w_menudata")
        *-- The menu item is defines as a system menu bar #
        lcBindEvent = "b" + SYS(2015)
        lcSubEvent = ""
        
        SELECT w_menudata
        LOCATE FOR w_menudata.sysmenuname = LOWER(loMenuData.Name)
        IF FOUND() AND NOT EMPTY(loMenuData.Name)
          DO WHILE NOT BOF("w_menudata")
            SKIP -1
            IF AT("_",w_menudata.sysmenuname,2) = 0
              lcSubEvent = "SYS(1500, '" + LOWER(loMenuData.Name) + "', '" + ALLTRIM(w_menudata.sysmenuname) + "')"
              EXIT
            ENDIF
          ENDDO
        ELSE
          *-- Bind it to the default event
          lcBindEvent = poMenuDefault.DefEvent
        ENDIF
      OTHERWISE
        *-- The menu item needs to use the default event
        lcBindEvent = poMenuDefault.DefEvent
    ENDCASE
    
    IF NOT EMPTY(lcSubEvent)
      poMenuDefault.ExecuteEventCode = poMenuDefault.ExecuteEventCode + CHR(13) + ;
      "FUNCTION " + lcBindEvent + "()" + CHR(13) + ;
      lcSubEvent + CHR(13) + ;
      "ENDFUNC" + CHR(13)
    ENDIF
    
    lcEventCode = lcEventCode + [BINDEVENT(loItem, "Execute", _SCREEN.oTabMenuHandler, "] + lcBindEvent + [")] + CHR(13)
  ENDSCAN

  lcEventCode = lcEventCode + CHR(13) + ;
                "  _SCREEN.oTabMenu.oSubMenu = loSubMenu" + CHR(13) + ;
                "  .Show()" + CHR(13) + ;
                "ENDWITH"
  
  IF NOT EMPTY(lcEventCode)
    poMenuDefault.ExecuteEventCode = poMenuDefault.ExecuteEventCode + CHR(13) + ;
    "FUNCTION " + vcBindEvent + "()" + CHR(13) + ;
    lcEventCode + CHR(13) + ;
    "ENDFUNC" + CHR(13)
  ENDIF

  *-- Close the cursor opened here
  USE IN (lcCursor)

  *-- Reselect the previous work area
  SELECT (lnSelect)
  
  RETURN m.llReturn
ENDFUNC

**************************************************************************************
*$FUNCTION$ spGetDirective()
*$CREATED$ 17/03/2007
**************************************************************************************
FUNCTION spGetDirective(vcSearchFor, vcSearchIn)
  LOCAL lcReturn, lnCount, lcText

  STORE "" TO lcReturn

  _MLINE = 0
  FOR lnCount = 1 TO MEMLINES(m.vcSearchIn)
    lcText = MLINE(m.vcSearchIn, 1, _MLINE)
    IF UPPER(m.vcSearchFor) $ UPPER(m.lcText)
      lcReturn = ALLTRIM(SUBSTR(m.lcText, LEN(m.vcSearchFor) + 1))
    ENDIF
  NEXT
  
  RETURN m.lcReturn
ENDFUNC
* Program....: FoxMenu.prg
* Notice.....: Copyright (c) 2002 Microsoft Corp.
* Compiler...: Visual FoxPro 8.0
* Abstract...:
*	Wraps context-sensitive (right-click) menu functionality in an object.
* Changes....:


DEFINE CLASS ContextMenu AS Custom
	MenuBarCount = 0  && defined so we can hook an _Access method to this
	ShowInScreen = .F.
	FormName = ''

	ADD OBJECT PopupNames AS Collection
	ADD OBJECT MenuItems AS Collection
	
	PROCEDURE Init()
	ENDPROC
	
	PROCEDURE Destroy()
		LOCAL cRelName
		FOR EACH cRelName IN THIS.PopupNames
			RELEASE POPUP &cRelName
		ENDFOR
	ENDPROC
	
	PROCEDURE Error(nError, cMethod, nLine)
		IF nError == 182
			RETURN  && ignore the error -- see Bug ID 50049
		ENDIF
	ENDPROC
	
	PROCEDURE ShowInScreen_Assign(lShowInScreen)
		THIS.ShowInScreen = lShowInScreen
	ENDPROC

	FUNCTION MenuBarCount_Access()
		RETURN THIS.MenuItems.Count
	ENDFUNC

	
	FUNCTION AddMenu(cCaption, cActionCode, cPicture, lChecked, lEnabled, lBold)
		LOCAL oMenuItem
		
		IF PCOUNT() < 5
			lEnabled = .T.
		ENDIF
		
		* we could pass a menu object rather than a caption
		* (this is our technique for overloading a function!)
		IF VARTYPE(cCaption) == 'O'
			oMenuItem = cCaption
		ELSE
			* don't add 2 menu separators in a row
			IF m.cCaption == "\-" AND THIS.MenuItems.Count > 0 AND THIS.MenuItems.Item(THIS.MenuItems.Count).Caption == "\-"
				RETURN .NULL.
			ENDIF
		
			oMenuItem = CREATEOBJECT("MenuItem")
			WITH oMenuItem
				oMenuItem.Caption = cCaption
				IF VARTYPE(cPicture) == 'C'
					.Picture = cPicture
				ENDIF
				IF VARTYPE(lChecked) == 'L'
					.Checked = lChecked
				ENDIF
				IF VARTYPE(cActionCode) == 'C'
					.ActionCode = cActionCode
				ENDIF
				IF VARTYPE(lEnabled) == 'L'
					.IsEnabled = lEnabled
				ENDIF
				IF VARTYPE(lBold) == 'L'
					.Bold = lBold
				ENDIF
			ENDWITH
		ENDIF
		THIS.MenuItems.Add(oMenuItem)
		
		RETURN oMenuItem
	ENDFUNC


	PROCEDURE Show(nRow, nCol, cFormName)
*!*			IF VARTYPE(m.nRow) <> 'N'
*!*				IF THIS.ShowInScreen
*!*					m.nRow = MROW("")
*!*				ELSE
*!*					m.nRow = MROW()
*!*				ENDIF
*!*			ENDIF
*!*			IF VARTYPE(m.nCol) <> 'N'
*!*				IF THIS.ShowInScreen
*!*					m.nCol = MCOL("")
*!*				ELSE
*!*					m.nCol = MCOL()
*!*				ENDIF
*!*			ENDIF
		IF VARTYPE(m.nRow) <> 'N'
			m.nRow = MROW(0)
		ENDIF
		IF VARTYPE(m.nCol) <> 'N'
			m.nCol = MCOL(0)
		ENDIF
		IF (VARTYPE(m.cFormName) <> 'C' OR EMPTY(m.cFormName)) AND TYPE("THISFORM") == 'O' AND !ISNULL(THISFORM)
			m.cFormName = THISFORM.Name
		ENDIF

		THIS.PopupNames.Remove(-1)

		ACTIVATE screen 
		oForm.AllowOutput= .T.
		ACTIVATE WINDOW (oForm.Name)
		

		THIS.BuildMenu("shortcut", m.nRow, m.nCol, m.cFormName)

		ACTIVATE POPUP shortcut
		
		oForm.AllowOutput = .F.
	ENDPROC

	* Render the menu
	FUNCTION BuildMenu(cMenuName, nRow, nCol, m.cFormName)
		LOCAL nBar
		LOCAL oMenuItem
		LOCAL cActionCode
		LOCAL cSubMenu
		LOCAL cSkipFor
		LOCAL cStyle

		IF VARTYPE(cMenuName) <> 'C'
			m.cMenuName = SYS(2015)
		ENDIF
		
*!*			IF THIS.ShowInScreen
*!*				IF PCOUNT() < 3
*!*					DEFINE POPUP (m.cMenuName) SHORTCUT RELATIVE IN WINDOW "Screen"
*!*				ELSE
*!*					DEFINE POPUP (m.cMenuName) SHORTCUT RELATIVE FROM m.nRow, m.nCol IN WINDOW "Screen"
*!*				ENDIF
*!*			ELSE
*!*				IF PCOUNT() < 3
*!*					DEFINE POPUP (m.cMenuName) SHORTCUT RELATIVE
*!*				ELSE
*!*					DEFINE POPUP (m.cMenuName) SHORTCUT RELATIVE FROM m.nRow, m.nCol
*!*				ENDIF
*!*			ENDIF

		IF VARTYPE(m.cFormName) == 'C' AND !EMPTY(m.cFormName)
			DEFINE POPUP (m.cMenuName) SHORTCUT RELATIVE FROM m.nRow, m.nCol 
		      * IN WINDOW (m.cFormName)
		ELSE
			IF PCOUNT() < 3
				DEFINE POPUP (m.cMenuName) SHORTCUT RELATIVE
			ELSE
				DEFINE POPUP (m.cMenuName) SHORTCUT RELATIVE FROM m.nRow, m.nCol
			ENDIF
		ENDIF
		
		THIS.PopupNames.Add(m.cMenuName)

		m.nBar = 0
		FOR EACH oMenuItem IN THIS.MenuItems
			m.cActionCode = oMenuItem.ActionCode

			IF oMenuItem.IsEnabled
				m.cSkipFor = ''
			ELSE
				m.cSkipFor = "SKIP FOR .T."
			ENDIF

			IF oMenuItem.Bold
				m.cStyle = [STYLE "B"]
			ELSE
				m.cStyle = ''
			ENDIF
			
			m.nBar = m.nBar + 1
			DEFINE BAR (m.nBar) OF (m.cMenuName) PROMPT (oMenuItem.Caption) PICTURE (oMenuItem.Picture) &cStyle &cSkipFor
			
			IF VARTYPE(m.cActionCode) == 'C' AND !EMPTY(m.cActionCode)
				ON SELECTION BAR (m.nBar) OF (m.cMenuName) &cActionCode
			ENDIF
			
			IF oMenuItem.Checked
				SET MARK OF BAR (m.nBar) OF (m.cMenuName) TO .T.
			ENDIF
			
			IF oMenuItem.SubMenu.MenuItems.Count > 0
				m.cSubMenu = SYS(2015)
				
				ON BAR (m.nBar) OF (m.cMenuName) ACTIVATE POPUP &cSubMenu

				oMenuItem.SubMenu.BuildMenu(m.cSubMenu)
			ENDIF
		ENDFOR
	ENDFUNC
ENDDEFINE


DEFINE CLASS MenuItem AS Custom
	Name        = "MenuItem"
	Caption     = ''
	Picture     = ''
	Checked     = .F.
	ActionCode  = ''
	IsEnabled   = .T.
	Bold        = .F.

	SubMenu = .NULL.

	PROCEDURE Init(cCaption, cActionCode, cPicture, lChecked, lEnabled)
		THIS.SubMenu = CREATEOBJECT("ContextMenu")

		IF VARTYPE(cCaption) == 'C'
			THIS.Caption = cCaption
		ENDIF
		IF VARTYPE(cPicture) == 'C'
			THIS.Picture = cPicture
		ENDIF
		IF VARTYPE(lChecked) == 'L'
			THIS.Checked = lChecked
		ENDIF
		IF VARTYPE(cActionCode) == 'C'
			THIS.ActionCode = cActionCode
		ENDIF
		IF VARTYPE(lEnabled) == 'L' AND PCOUNT() >= 5
			THIS.IsEnabled = lEnabled
		ENDIF
	ENDPROC

ENDDEFINE

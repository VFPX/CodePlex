* Program....: FoxMenu.prg
* Notice.....: Copyright (c) 2002 Microsoft Corp.
* Compiler...: Visual FoxPro 8.0
* Abstract...:
*	Wraps context-sensitive (right-click) menu functionality in an object.
* Changes....:
#include "foxpro.h"

DEFINE CLASS ContextMenu AS Custom
	MenuBarCount = 0  && defined so we can hook an _Access method to this
	ShowInScreen = .F.
	FormName = ''

	DIMENSION aScript[1]

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
		ELSE
			MESSAGEBOX(MESSAGE(), MB_ICONEXCLAMATION)
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
				IF INLIST(VARTYPE(cActionCode), 'C', 'N')
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
		PRIVATE oMenuRef

		oMenuRef = THIS

		IF (VARTYPE(m.cFormName) <> 'C' OR EMPTY(m.cFormName)) 
			IF TYPE("oForm") == 'O' AND !ISNULL(oForm)
				m.cFormName = oForm.Name
			ELSE
				IF TYPE("THISFORM") == 'O' AND !ISNULL(THISFORM)
					m.cFormName = THISFORM.Name
				ENDIF
			ENDIF
		ENDIF

		ACTIVATE screen 

		IF VARTYPE(oForm) == 'O'
			oForm.AllowOutput= .T.
		ENDIF
		ACTIVATE WINDOW (m.cFormName)

		IF VARTYPE(m.nRow) <> 'N'
			m.nRow = MROW()
		ENDIF
		IF VARTYPE(m.nCol) <> 'N'
			m.nCol = MCOL()
		ENDIF

		THIS.PopupNames.Remove(-1)

		THIS.BuildMenu("shortcut", m.nRow, m.nCol, m.cFormName)

		ACTIVATE POPUP shortcut
		
		IF VARTYPE(oForm) == 'O'
			oForm.AllowOutput = .F.
		ENDIF
	ENDPROC

	* Render the menu
	FUNCTION BuildMenu(cMenuName, nRow, nCol, m.cFormName)
		LOCAL nBar
		LOCAL oMenuItem
		LOCAL cActionCode
		LOCAL cSubMenu
		LOCAL cSkipFor
		LOCAL cStyle
		LOCAL nScriptCnt

		IF VARTYPE(cMenuName) <> 'C'
			m.cMenuName = SYS(2015)
		ENDIF
		
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

		nScriptCnt = 0			

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
			
			IF VARTYPE(m.cActionCode) == 'N'
				DEFINE BAR (m.cActionCode) OF (m.cMenuName) PROMPT (oMenuItem.Caption) PICTURE (oMenuItem.Picture) &cStyle &cSkipFor
			ELSE
				m.nBar = m.nBar + 1
				DEFINE BAR (m.nBar) OF (m.cMenuName) PROMPT (oMenuItem.Caption) PICTURE (oMenuItem.Picture) &cStyle &cSkipFor
			ENDIF
						
			IF VARTYPE(m.cActionCode) == 'C' AND !EMPTY(m.cActionCode)
				IF oMenuItem.RunAsScript
					nScriptCnt = nScriptCnt + 1
					DIMENSION THIS.aScript[nScriptCnt]

					THIS.aScript[nScriptCnt] = cActionCode

					cActionCode = "EXECSCRIPT(oMenuRef.aScript[" + TRANSFORM(nScriptCnt) + "], oParameter)"

				ENDIF
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
	RunAsScript = .F.
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

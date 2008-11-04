********************************************************************
*** Name.....: PROGRAM2
*** Author...: Marcia G. Akins
*** Date.....: 01/15/2007
*** Notice...: Copyright (c) 2007 Tightline Computers, Inc
*** Compiler.: Visual FoxPro 09.00.0000.3504 for Windows
*** Function.: Modeless Replacement for the edit property/method dialog -
*** ...................: also handles removing member data when you remove the member
*** Returns..: Logical
********************************************************************

#include NewEditPropertyDialog.H
Local lcPath, ;
	lcMenuContextCode, ;
	lcAppPath, ;
	lcEditPropertyCode, ;
	lcEditPropertyMenuCode, ;
	lnSelect
lcPath = Addbs(Justpath(Sys(16)))

* Create the code for the MENUCONTEXT script record.
lcMenuContextCode = GetMenuContextCode ()

* Create the code for the Edit Property shortcut menu.
lcAppPath = Forcepath('NewEditPropertyDialog.app', lcPath)
lcEditPropertyCode = GetEditPropertyCode(lcAppPath)

* Create the code for the Edit Property/Method menu items.
lcEditPropertyMenuCode = GetEditPropertyMenuCode(lcAppPath)

* Add the records to FOXCODE.

lnSelect = Select()
Select 0
Use (_Foxcode) Again Shared Alias Foxcode Order 1

If Not Seek('SMENUCONTEXT')
	Insert Into Foxcode (Type, ABBREV, Data) Values ('S', 'MENUCONTEXT', lcMenuContextCode)
Else
	Replace Data With lcMenuContextCode In Foxcode
Endif Not Seek('SMENUCONTEXT')

If Not Seek('M24460')
	Insert Into Foxcode (Type, ABBREV, Data) Values ('M', '24460', lcEditPropertyCode)
Else
	Replace Data With lcEditPropertyCode In Foxcode
Endif Not Seek('M24460')

If Not Seek('MEDIT PROPERTY/METHOD...')
	Insert Into Foxcode (Type, ABBREV, Data) Values ('M', 'EDIT PROPERTY/METHOD...', lcEditPropertyMenuCode)
Else
	Replace Data With lcEditPropertyMenuCode In Foxcode
Endif Not Seek('MEDIT PROPERTY/METHOD...')

Use
Select (lnSelect)
Messagebox(ccLOC_DIALOG_REGISTERED, MB_OK + MB_ICONINFORMATION)
Return




****************************************************************
****************************************************************

Procedure GetMenuContextCode

	Local lcMenuContextCode
	****************************************************************
	* beginning of text / endtext
	TEXT to lcMenuContextCode noshow
LPARAMETERS toParameter

LOCAL lnSelect, lcCode, llReturn, lScriptHandled

TRY
	* First try FoxCode lookup for Type="M" records
	lnSelect = SELECT()
	SELECT 0
	USE (_FOXCODE) AGAIN SHARE ORDER 1
	IF SEEK('M' + PADR(UPPER(toParameter.MenuItem), LEN(ABBREV)))
		lcCode = DATA
	ENDIF
	USE
	SELECT (lnSelect)
	IF NOT EMPTY(lcCode)
		llReturn = EXECSCRIPT(lcCode, toParameter)
		lScriptHandled=.T.
	ENDIF

	* Handle by passing to external routine as specified in Tip field
	IF !lScriptHandled
		lcProgram = ALLTRIM(toParameter.Tip)
		IF FILE(lcProgram)
			DO (lcProgram) WITH toParameter,llReturn
		ENDIF
	ENDIF

	* Custom script successful so let's disable native behavior
	IF llReturn
		toParameter.ValueType = 'V'
	ENDIF
CATCH
ENDTRY

RETURN llReturn
	ENDTEXT

	* end of text / endtext
	****************************************************************
	Return lcMenuContextCode

Endproc


****************************************************************
****************************************************************

Procedure GetEditPropertyCode(lcAppPath)

	Local lcEditPropertyCode
	****************************************************************
	* beginning of text / endtext
	TEXT to lcEditPropertyCode noshow textmerge
	Lparameter oParm

	Local lcPEM, laObjs, laDock, lnPos, lnRow, lnCol, lnDockPos, lcWin, llHandle, llProperty, llMethod, llCustom, llInherited

	Private plDoForm, plZoom

	plDoForm = .F.
	plZoom = .F.
	lcPEM = oParm.UserTyped
	lnDockPos = 0

	Dimension laObjs[1]

	Do Case
		Case Aselobj(laObjs) # 0
			loObject = laObjs[1]
			llHandle = .T.
		Case Aselobj(laObjs,1) # 0
			loObject = laObjs[1]
			*** This is the case we want to handle
			llHandle = .T.
		Otherwise
			loObject=_Screen
	Endcase

	If llHandle
		*** See if it is user defined and whether it
		*** is a property or a method to decide how to construct the menu
		llProperty = Lower( Alltrim( Pemstatus( loObject, lcPEM, 3 ) ) ) = [property]
		llMethod = Inlist( Lower( Alltrim( Pemstatus( loObject, lcPEM, 3 ) ) ), [method], [event]  )
		llCustom = Pemstatus( loObject, lcPEM, 4 )
		llInherited = Pemstatus( loObject, lcPEM, 6 )

		*!*   Commented by calloatti
		*!*	  ACTIVATE SCREEN
		*!*	  lnRow = MROW("")
		*!*	  lnCol = MCOL("")

		*!*	  IF lnCol = -1
		*!*	  	DIMENSION laDock[1]
		*!*	  	ADOCKSTATE(laDock)
		*!*	  	lnPos = ASCAN(laDock, "PROPERTIES", -1, -1, 1, 14)
		*!*	  	IF laDock[lnPos, 2] = 1				&& Properties Window is not docked or docked to desktop
		*!*	  		IF EMPTY(laDock[lnPos, 4]) OR laDock[lnPos, 4] == _SCREEN.Caption 	&& check if docked to another window
		*!*	  			lnDockPos = laDock[lnPos, 3]
		*!*	  		ELSE
		*!*	  			* we need to traverse through other windows to find actual dock location
		*!*	  			lcWin = laDock[lnPos, 4]
		*!*	  			DO WHILE .T.
		*!*	  				lnPos = ASCAN(laDock, lcWin, -1, -1, 1, 14)
		*!*	  				DO CASE
		*!*	  				CASE lnPos = 0
		*!*	  					* Yikes
		*!*	  					EXIT
		*!*	  				CASE EMPTY(laDock[lnPos, 4]) OR laDock[lnPos, 4] == _SCREEN.Caption
		*!*	  					lnDockPos = laDock[lnPos, 3]
		*!*	  					EXIT
		*!*	  				OTHERWISE
		*!*	  					lcWin = laDock[lnPos, 4]
		*!*	  				ENDCASE
		*!*	  			ENDDO
		*!*	  		ENDIF
		*!*	  		DO CASE
		*!*	  		CASE lnDockPos  = 1
		*!*	  			lnCol = 0 - WCOL("Properties") + (MCOL("Properties",3)/FONTMETRIC(6,_SCREEN.FontName,_SCREEN.FontSize))
		*!*	  		CASE lnDockPos = 2
		*!*	  			lnCol = WCOL("") + (MCOL("Properties",3)/FONTMETRIC(6,_SCREEN.FontName,_SCREEN.FontSize))
		*!*	  		ENDCASE
		*!*	  	ENDIF
		*!*	  ENDIF

		*!* calloatti
		Local lcPoint, lnx, lny

		m.lcPoint = 0h0000000000000000

		apiGetCursorPos_pemeditor(@m.lcPoint)
		apiScreenToClient_pemeditor(_Screen.HWnd, @m.lcPoint)

		m.lnx = CToBin(Substr(m.lcPoint, 1, 4), "4rs")
		m.lny = CToBin(Substr(m.lcPoint, 5, 4), "4rs")

		m.lnCol = ScreenPixelsToCols(m.lnx)
		m.lnRow = ScreenPixelsToRows(m.lny)
		*!* calloatti

		Define Popup myPopup From lnRow, lnCol SHORTCUT

		Define Bar 1 Of myPopup Prompt "\<Reset to Default"
		If llProperty
			Define Bar 2 Of myPopup Prompt "\<Zoom"
			If .T. && llCustom AND NOT llInherited
				Define Bar 3 Of myPopup Prompt "E\<dit Property/Method"
				Define Bar 4 Of myPopup Prompt "Add to \<Favorites"
				Define Bar 5 Of myPopup Prompt "\<MemberData Editor..."
			Else
				Define Bar 3 Of myPopup Prompt "Add to \<Favorites"
				Define Bar 4 Of myPopup Prompt "\<MemberData Editor..."
			Endif
		Else
			If .T. && llCustom AND NOT llInherited
				Define Bar 2 Of myPopup Prompt "E\<dit Property/Method"
				Define Bar 3 Of myPopup Prompt "Add to \<Favorites"
				Define Bar 4 Of myPopup Prompt "\<MemberData Editor..."
			Else
				Define Bar 2 Of myPopup Prompt "Add to \<Favorites"
				Define Bar 3 Of myPopup Prompt "\<MemberData Editor..."
			Endif
		Endif
		*** DougHennig 08/15/2007: use WITH for DO command
		***  ON SELECTION BAR 1 OF myPopup do <<addbs(justpath(lcAppPath))>>Reset2Default(loObject, lcPEM)
		On Selection Bar 1 Of myPopup Do '<<addbs(justpath(lcAppPath))>>Reset2Default' With loObject, lcPEM
		If llProperty
			On Selection Bar 2 Of myPopup plZoom = .T.
			If .T. && .llCustom AND NOT llInherited
				On Selection Bar 3 Of myPopup plDoForm = .T.
				On Selection Bar 4 Of myPopup Do (_Builder) With loObject, "MemberData", 11, lcPEM
				On Selection Bar 5 Of myPopup Do (_Builder) With loObject, "MemberData", 1, lcPEM
			Else
				On Selection Bar 3 Of myPopup Do (_Builder) With loObject, "MemberData", 11, lcPEM
				On Selection Bar 4 Of myPopup Do (_Builder) With loObject, "MemberData", 1, lcPEM
			Endif
		Else
			If .T. && llCustom AND NOT llInherited
				On Selection Bar 2 Of myPopup plDoForm = .T.
				On Selection Bar 3 Of myPopup Do (_Builder) With loObject, "MemberData", 11, lcPEM
				On Selection Bar 4 Of myPopup Do (_Builder) With loObject, "MemberData", 1, lcPEM
			Else
				On Selection Bar 2 Of myPopup Do (_Builder) With loObject, "MemberData", 11, lcPEM
				On Selection Bar 3 Of myPopup Do (_Builder) With loObject, "MemberData", 1, lcPEM
			Endif
		Endif
		Activate Popup myPopup
	Endif

	Do Case
		Case plDoForm
			Release _oNewEditProperty
			Public _oNewEditProperty
			_oNewEditProperty = Newobject('NewEditPropertyDialog', 'NewEditProperty.vcx', ;
				'<<lcAppPath>>', llMethod, lcPEM )
			_oNewEditProperty.Show()
			Return llHandle

		Case plZoom
			Release _oNewZoom
			Public _oNewZoom
			_oNewZoom = Newobject('NewZoom', 'NewEditProperty.vcx', ;
				'<<lcAppPath>>', loObject, lcPEM )
			_oNewZoom.Show()
			Return llHandle

		Otherwise
			Return llHandle
	Endcase

	Function apiGetCursorPos_pemeditor
		Lparameters lpPoint
		Declare Integer GetCursorPos In win32api As apiGetCursorPos_pemeditor;
			String  @lpPoint
		Return apiGetCursorPos_pemeditor(@m.lpPoint)
	Endfunc

	Function apiScreenToClient_pemeditor
		Lparameters nHwnd, lpPoint
		Declare Integer ScreenToClient In win32api As apiScreenToClient_pemeditor ;
			Integer nhWnd, ;
			String  @lpPoint
		Return apiScreenToClient_pemeditor(m.nHwnd, @m.lpPoint)
	Endfunc

	Function ScreenPixelsToRows
		Lparameters tnPixels
		Return ScreenPixelsToFoxels(m.tnPixels, .T.)
	Endfunc

	Function ScreenPixelsToCols
		Lparameters tnPixels
		Return ScreenPixelsToFoxels(m.tnPixels, .F.)
	Endfunc

	Function ScreenPixelsToFoxels
		Lparameter tnPixels, tlVertical

		Local lnFoxels, lcFontStyle
		m.lcFontStyle = ""

		If _Screen.FontBold = .T. Then
			m.lcFontStyle = m.lcFontStyle + "B"
		Endif

		If _Screen.FontItalic = .T. Then
			m.lcFontStyle = m.lcFontStyle + "I"
		Endif

		m.lnFoxels = m.tnPixels/Fontmetric(Iif(m.tlVertical, 1, 6), _Screen.FontName, _Screen.FontSize, m.lcFontStyle)

		Return m.lnFoxels
	Endfunc

	ENDTEXT

	* end of text / endtext
	****************************************************************
	Return lcEditPropertyCode

Endproc

****************************************************************
****************************************************************


Procedure GetEditPropertyMenuCode(lcAppPath)

	Local lcEditPropertyMenuCode
	****************************************************************
	* beginning of text / endtext
	TEXT to lcEditPropertyMenuCode noshow textmerge
lparameters toParameter
local llReturn
try
	release _oNewEditProperty
	public _oNewEditProperty
    _oNewEditProperty = NEWOBJECT('NewEditPropertyDialog', 'NewEditProperty.vcx', ;
      '<<lcAppPath>>', .F., '' )
    _oNewEditProperty.SHOW()
	llReturn = .T.
catch
endtry
return llReturn
	ENDTEXT

	* end of text / endtext
	****************************************************************
	Return lcEditPropertyMenuCode

Endproc

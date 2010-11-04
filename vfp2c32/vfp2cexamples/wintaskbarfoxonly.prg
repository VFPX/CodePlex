&& TEST 
LOCAL loTaskbar
loTaskbar = CREATEOBJECT('WinTaskbar')

? "Autohide is ", IIF(loTaskbar.Autohide ,'ON','OFF')
? "Setting Autohide ON"
loTaskbar.Autohide = .T.
? "Autohide is ", IIF(loTaskbar.Autohide,'ON','OFF')

INKEY(5,'H')
? "Setting Autohide OFF"
loTaskbar.Autohide = .F.
? "Autohide is ", IIF(loTaskbar.Autohide,'ON','OFF')

? "AlwaysOnTop is ", IIF(loTaskbar.AlwaysOnTop,'ON','OFF')
? "Setting AlwaysOnTop OFF"
loTaskbar.AlwaysOnTop = .F.
? "AlwaysOnTop is ", IIF(loTaskbar.AlwaysOnTop,'ON','OFF')

INKEY(5,'H')
? "Setting AlwaysOnTop ON"
loTaskbar.AlwaysOnTop = .T.
? "AlwaysOnTop is ", IIF(loTaskbar.AlwaysOnTop,'ON','OFF')
&& END TEST 

DEFINE CLASS WinTaskbar AS Custom

#DEFINE ABM_GETSTATE		4
#DEFINE ABM_SETSTATE      	10
#DEFINE ABS_AUTOHIDE		1
#DEFINE ABS_ALWAYSONTOP		2

	Autohide = .F.
	AlwaysOnTop = .F.
	
	FUNCTION Init
		DECLARE INTEGER SHAppBarMessage IN shell32.dll INTEGER dwMessage, STRING @pData
	ENDFUNC
	
	FUNCTION Destroy
		CLEAR DLLS 'SHAppBarMessage'
	ENDFUNC

	FUNCTION Autohide_Access
		LOCAL lcAppBar, lnResult
		m.lcAppBar = BINTOC(36,'4RS') + REPLICATE(CHR(0),32)
		m.lnResult = SHAppBarMessage(ABM_GETSTATE, @m.lcAppBar)
		RETURN BITAND(m.lnResult,ABS_AUTOHIDE) > 0
	ENDFUNC

	FUNCTION Autohide_Assign
		LPARAMETERS lbAutohide
		LOCAL lcAppBar, lnResult, lnLParam
		m.lcAppBar = BINTOC(36,'RS') + REPLICATE(CHR(0),32)
		m.lnResult = SHAppBarMessage(ABM_GETSTATE, @m.lcAppBar)
		&& set the lParam member of the APPBARDATA structure to the new state
		&& BITOR(... will add the ABS_AUTOHIDE bit if not set
		&& BITAND(... will remove the ABS_AUTOHIDE bit if set
		m.lnLParam = IIF(m.lbAutohide,BITOR(m.lnResult,ABS_AUTOHIDE),BITAND(m.lnResult,BITNOT(ABS_AUTOHIDE)))
		m.lcAppBar = BINTOC(36,'RS') + REPLICATE(CHR(0),28) + BINTOC(m.lnLParam,'RS')
		m.lnResult = SHAppBarMessage(ABM_SETSTATE, @m.lcAppBar)
	ENDFUNC
	
	FUNCTION AlwaysOnTop_Access
		LOCAL lcAppBar, lnResult
		m.lcAppBar = BINTOC(36,'4RS') + REPLICATE(CHR(0),32)
		m.lnResult = SHAppBarMessage(ABM_GETSTATE, @m.lcAppBar)
		RETURN BITAND(m.lnResult,ABS_ALWAYSONTOP) > 0
	ENDFUNC
	
	FUNCTION AlwaysOnTop_Assign
		LPARAMETERS lbAlwaysOnTop
		LOCAL lcAppBar, lnResult, lnLParam
		m.lcAppBar = BINTOC(36,'RS') + REPLICATE(CHR(0),32)
		m.lnResult = SHAppBarMessage(ABM_GETSTATE, @m.lcAppBar)
		&& set the lParam member of the APPBARDATA structure to the new state
		&& BITOR(... will add the ABS_AUTOHIDE bit if not set
		&& BITAND(... will remove the ABS_AUTOHIDE bit if set
		m.lnLParam = IIF(m.lbAlwaysOnTop,BITOR(m.lnResult,ABS_ALWAYSONTOP),BITAND(m.lnResult,BITNOT(ABS_ALWAYSONTOP)))
		m.lcAppBar = BINTOC(36,'RS') + REPLICATE(CHR(0),28) + BINTOC(m.lnLParam,'RS')
		m.lnResult = SHAppBarMessage(ABM_SETSTATE, @m.lcAppBar)
	ENDFUNC	
		
ENDDEFINE

&& If you prefer global functions ....

*!*	#DEFINE ABM_GETSTATE		4
*!*	#DEFINE ABM_SETSTATE      	10
*!*	#DEFINE ABS_AUTOHIDE		1

*!*		FUNCTION SetAutoHideState
*!*			LPARAMETERS lbAutohide
*!*			DECLARE INTEGER SHAppBarMessage IN shell32.dll INTEGER dwMessage, STRING @pData
*!*			LOCAL lcAppBar, lnResult, lnLParam
*!*			m.lcAppBar = BINTOC(36,'RS') + REPLICATE(CHR(0),32)
*!*			m.lnResult = SHAppBarMessage(ABM_GETSTATE, @m.lcAppBar)
*!*			&& set the lParam member of the APPBARDATA structure to the new state
*!*			&& BITOR(... will add the ABS_AUTOHIDE bit if not set
*!*			&& BITAND(... will remove the ABS_AUTOHIDE bit if set
*!*			m.lnLParam = IIF(m.lbAutohide,BITOR(m.lnResult,ABS_AUTOHIDE),BITAND(m.lnResult,BITNOT(ABS_AUTOHIDE)))
*!*			m.lcAppBar = BINTOC(36,'RS') + REPLICATE(CHR(0),28) + BINTOC(m.lnLParam,'RS')
*!*			m.lnResult = SHAppBarMessage(ABM_SETSTATE, @m.lcAppBar)
*!*		ENDFUNC

*!*		FUNCTION GetAutoHideState
*!*			DECLARE INTEGER SHAppBarMessage IN shell32.dll INTEGER dwMessage, STRING @pData
*!*			LOCAL lcAppBar, lnResult
*!*			m.lcAppBar = BINTOC(36,'4RS') + REPLICATE(CHR(0),32)
*!*			m.lnResult = SHAppBarMessage(ABM_GETSTATE, @m.lcAppBar)
*!*			RETURN BITAND(m.lnResult,ABS_AUTOHIDE) > 0
*!*		ENDFUNC
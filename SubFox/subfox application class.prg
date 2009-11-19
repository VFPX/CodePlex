*-- SubFox Application Class --*

DEFINE CLASS SubFox_Application AS Session && OLEPUBLIC
	*-- properties --*
	UseToolbar = .F.
	Toolbar = NULL

*******************************************************************************
FUNCTION Toolbar_ACCESS() AS Object
	IF ISNULL( this.Toolbar )
		this.Toolbar = NEWOBJECT( "sfToolbar", "SubFox" )
		this.Toolbar.Show()
		this.Toolbar.Dock(0)
	ENDIF
	RETURN this.Toolbar
ENDFUNC && Toolbar_ACCESS

*******************************************************************************
FUNCTION Toolbar_ASSIGN(oParam) AS VOID
	LOCAL s
	s = PROGRAM( PROGRAM(-1) - 1 )
	_cliptext = s
*	IF s != "abc"
*	 	ERROR "Toolbar properties is READ-ONLY"
*	ENDIF
	this.Toolbar = oParam
ENDFUNC && Toolbar_ASSIGN

*******************************************************************************
FUNCTION FullPath(sFName AS String, sBasePath AS String) AS String
	LOCAL i, sDrive, sSubPath
	IF (LEN(sFName) >= 3 AND SUBSTR( sFName, 2, 2 ) == ":\") ;
	OR (OCCURS( "\", sFName ) >= 3 AND PADR( sFName, 2 ) == "\\") ;
	OR EMPTY( sBasePath )
		RETURN LOWER( sFName )
	ENDIF
	sBasePath = LOWER( ADDBS( sBasePath ) )
	IF LEN(sBasePath) >= 3 AND SUBSTR( sBasePath, 2, 2 ) == ":\"
		sDrive = LEFT( sBasePath, 3 )
		sSubPath = SUBSTR( sBasePath, 4 )
	ELSE
		IF OCCURS( "\", sBasePath ) >= 4 AND PADR( sBasePath, 2 ) == "\\"
			i = AT( "\", sBasePath, 4 )
			sDrive = LEFT( sBasePath, i )
			sSubPath = SUBSTR( sBasePath, i+1 )
		ELSE
			RETURN LOWER( sFName )
		ENDIF
	ENDIF
	DO WHILE .T.
		IF PADR( sFName, 3 ) == "..\"
			sFName = SUBSTR( sFName, 4 )
			i = RAT( "\", sSubPath, 2 )
			sSubPath = IIF( i == 0, "", LEFT( sSubPath, i ) )
		ELSE
			EXIT
		ENDIF
	ENDDO
	sFName = LOWER( sDrive + sSubPath + sFName )
	sFName = STRTRAN( sFName, "\.\", "\" )
	RETURN sFName
ENDFUNC && FullPath

*******************************************************************************
FUNCTION CreateMenu()
	LOCAL s, sPath, sAppFName, sLocate, sPicFName
	sAppFName = LOWER( SYS(16,0) )
	sPath = JUSTPATH( sAppFName )
	DEFINE POPUP _msubfox MARGIN RELATIVE SHADOW COLOR SCHEME 4
	DEFINE BAR 1234 OF _mfile BEFORE _mfi_import PROMPT "SubFox" PICTURE "images\subfox16.bmp"
	ON BAR 1234 OF _mfile ACTIVATE POPUP _msubfox

	sPicFName = LOCFILE( ADDBS(sPath) + "images\download16.bmp", "bmp", "Where is DOWNLOAD16.BMP" )
	DEFINE BAR 1 OF _msubfox PICTURE sPicFName PROMPT "Download from Repository..."
	ON SELECTION BAR 1 OF _msubfox ; && DO FORM SubFox_Download
		DO ("&sAppFName") WITH 'Download'

	sPicFName = LOCFILE( ADDBS(sPath) + "images\merge16.bmp", "bmp", "Where is MERGE16.BMP" )
	DEFINE BAR 2 OF _msubfox PICTURE sPicFName PROMPT "Resolve Conflicts..."
	ON SELECTION BAR 2 OF _msubfox ; && DO FORM SubFox_ConflictEditor
		DO ("&sAppFName") WITH 'Resolve'

	sPicFName = LOCFILE( ADDBS(sPath) + "images\upload16.bmp", "bmp", "Where is UPLOAD16.BMP" )
	DEFINE BAR 3 OF _msubfox PICTURE sPicFName PROMPT "Upload to Repository..."
	ON SELECTION BAR 3 OF _msubfox ; && DO FORM SubFox_Upload
		DO ("&sAppFName") WITH 'Upload'

	DEFINE BAR 4 OF _msubfox PROMPT "\-"

	sPicFName = LOCFILE( ADDBS(sPath) + "images\include16.bmp", "bmp", "Where is INCLUDE16.BMP" )
	DEFINE BAR 5 OF _msubfox PICTURE sPicFName PROMPT "Setup Versioned Files..."
	ON SELECTION BAR 5 OF _msubfox ; && DO FORM SubFox_Includes
		DO ("&sAppFName") WITH 'Setup'

	sPicFName = LOCFILE( ADDBS(sPath) + "images\gears16.bmp", "bmp", "Where is GEARS16.BMP" )
	DEFINE BAR 6 OF _msubfox PICTURE sPicFName PROMPT "Translate Source Files..."
	ON SELECTION BAR 6 OF _msubfox ; && DO FORM SubFox_Translator
		DO ("&sAppFName") WITH 'Translate'

	sPicFName = LOCFILE( ADDBS(sPath) + "images\tortoise16.bmp", "bmp", "Where is TORTOISE16.BMP" )
	DEFINE BAR 7 OF _msubfox PICTURE sPicFName PROMPT "Install Tortoise Hooks"
	ON SELECTION BAR 7 OF _msubfox ; 
		DO ("&sAppFName") WITH 'Tortoise'

	sPicFName = LOCFILE( ADDBS(sPath) + "images\help16.bmp", "bmp", "Where is HELP16.BMP" )
	DEFINE BAR 8 OF _msubfox PICTURE sPicFName PROMPT "Help"
	ON SELECTION BAR 8 OF _msubfox ; && this.ShowHelp()
		DO ("&sAppFName") WITH 'Help'

	SET SYSMENU SAVE
ENDFUNC && CreateMenu

*******************************************************************************
FUNCTION ShowHelp()
	LOCAL s,ss
	s = ADDBS( HOME() ) + "SubFoxDocs.html"
	ss = "subfox documentation.html"
	IF FILE(ss) && new logic
		LOCAL oPopup
		s = FILETOSTR( ss )
		s = STRTRAN( s, "<h1><span class=SpellE>SubFox</span> Documentation</h1>", "", 1, 1 )
		DO FORM SubFox_Help WITH "SubFox Documentation", s NAME oPopup
		RETURN
	ENDIF
	IF FILE(ss)
		IF FILE(s)
			DELETE FILE (s)
		ENDIF
		*COPY FILE (ss) TO (s)
		STRTOFILE( FILETOSTR(ss), s )
	ENDIF
	IF FILE(s)
		DECLARE INTEGER ShellExecute IN shell32.DLL ;
			INTEGER hWnd, STRING sAction, STRING sFileName, STRING sParams, STRING sDir, INTEGER nShowWin
		IF ShellExecute( 0, "open", s, "", HOME(), 1 ) < 33 && Failure returns 32 or less
			MESSAGEBOX( "Windows reported an error when attempting to open the SubFox help document", ;
						64, "SubFox Internal Error" )
		ENDIF
	ENDIF
ENDFUNC && ShowHelp

ENDDEFINE && SubFox_Application

*-
*- foundation class for MailMerge
*-

#INCLUDE "mailmrge.h"
#INCLUDE "DDECmd.h"				&& localized DDE and WordBasic commands

#DEFINE L_DEBUG .F.

DEFINE CLASS MailMerge AS CUSTOM

	cAppTitle	= ALERTTITLE_LOC	&& application name, used in Alerts
	
	iMaxWordProc = N_COMMADELIM		&& maximum value for word processors
	
	nWordProc	= N_WORD60			&& default is Word 6.0
	nNewDoc		= N_NEW_DOC			&& create a new or use an existing document
	cDocName	= ""				&& name of master merge document
	nTemplate	= N_FORMLETTER		&& type of document to create (Word 6.0 only)
	cMrgData	= ""				&& file that will contain merge data if non-60

	*- these properties are internal, and not exposed in the UI
	cFieldList	= ""
	cDataFile	= ""				&& 2.6 copy of 3.0 DBF table
	cDataSrc	= ""				&& datasource
	cODBCSource = ""				&& connection string
	cSqlStmt	= ""				&& SQL statement for extracting data
	cSqlStmt2	= ""				&& SQL statement for extracting data
	cSaveFile	= ""				&& file for holding merged data (may not be used in some cases)
	cTmpFile	= ""
	cDataPath	= ""				&& path to FROM table

	currentOS	= 0					&& operating system
	lHasVerWord = .F.				&& verified that Word exists
	cWordVersion = ""				&& version of Word installed, as char (e.g., '8')
	lEnglish	= .T.				&& Does Word recognize English WordBasic commands?

	lAlerted	= .F.				&& has user been notified of failure?

	cExe		= ""				&& full path to the Word application

	DIMENSION aODBCDrivers[1,2]		&& array of installed drivers
	aODBCDrivers = ""

	sysch	= -1					&& DDE channel

	DIMENSION aWPMrg[2]				&& procedures for handling various merge styles

	aWPMrg[1] = "THIS.MrgWord"
	aWPMrg[2] = IIF(_mac,"THIS.MrgCommaDel(CHR(9))","THIS.MrgCommaDel")

#IF L_DEBUG
	PROCEDURE Error
		PARAMETER ErrorNum, Method, Line
		THIS.ALERT("Error: " + message() + C_CRLF + ;
			"Error Number: " + ALLT(STR(m.Errornum)) + C_CRLF + ;
			"Method: " + m.Method + C_CRLF + ;
			"Line: " + LTRIM(STR(LINENO())) + ": " + message(1))
		SET TRBE OFF
		ACTI WINDOW DEBUG
		ACTI WINDOW TRACE
		SUSPEND
	ENDPROC
#ENDIF


	*----------------------------------
	PROCEDURE Init
	*----------------------------------
		IF _mac
			THIS.SetErrorOff = .T.
			THIS.cExe = THIS.LocateApp(C_MSWORDCREATOR)
			IF EMPTY(THIS.cExe)
				*- assume word is not installed
				IF "FOXTOOLS" $ SET("LIBRARY")
					*- assume library loaded and was okay, and Word really isn;t there
					THIS.Alert(E_NOWORDMACERR_LOC)
				ENDIF
				RETURN .F.
			ENDIF
			THIS.SetErrorOff = .F.
		ENDIF

		THIS.sysch = -1
		THIS.aODBCDrivers = ""
		THIS.aAutoFields = ""
		
		
		RETURN .T.

	ENDPROC

	*----------------------------------
	PROCEDURE Merge
	*----------------------------------
	
		LOCAL m.cProc
		
		*- call the procedure that does the work
		
		*- make sure values are reasonable
		IF !BETWEEN(THIS.nWordProc,1,THIS.iMaxWordProc)
			*- invalid word processor index
			THIS.Alert(E_BADWORDPROC_LOC)
			RETURN
		ENDIF

		IF !BETWEEN(THIS.nTemplate,1,N_CATALOG)
			*- invalid template index (should be 1 - 4)
			THIS.Alert(E_BADTEMPLATE_LOC)
			RETURN
		ENDIF

		IF THIS.nNewDoc == N_EXISTING_DOC AND EMPTY(THIS.cDocName)
			*- no existing document was specified
			THIS.Alert(E_BADEXDOC_LOC)
			RETURN
		ENDIF
		 
		IF THIS.nWordProc == N_COMMADELIM AND EMPTY(THIS.cMrgData)
			*- no destination file for merge data specified
			THIS.Alert(E_BADMRGDATA_LOC)
			RETURN
		ENDIF

		IF EMPTY(THIS.cAlias)
			*- no alias specified
			THIS.Alert(E_NODATA_LOC)
			RETURN
		ENDIF
		
		IF EMPTY(THIS.aAutoFields[1,1])
			*- no alias specified
			THIS.Alert(E_NOFIELDS_LOC)
			RETURN
		ENDIF
		
		THIS.MakeFieldList(255)
		
		cProc = THIS.aWPMrg[THIS.nWordProc]
		&cProc
		
	ENDPROC
	
	*----------------------------------
	PROCEDURE MrgWord
	*----------------------------------
		*- drive versions of MS Word
		IF !THIS.PrepData()
			RETURN .F.
		ENDIF
	
		IF _mac
			*- we'll use Applescript for doing this on the Mac
			RETURN THIS.MailMergeMacWord6()
		ENDIF
	
		*- get the version of Word that's installed (and while we're at it, the command line)
		THIS.cexe = THIS.GetMSW(C_WORD6_OR_LATER)		&& will also fill in THIS.cWordVersion
		
		DO CASE
			CASE THIS.cWordVersion = '8'
				THIS.MailMergeWinWord6			
				*- THIS.MailMergeWinWord8
			OTHERWISE
				THIS.MailMergeWinWord6			
		ENDCASE
		
	ENDPROC
	
	*----------------------------------
	PROCEDURE MakeFieldList
	*----------------------------------
		PARAMETER iMaxFldLen, cDelimit
		
		*- make field list
		THIS.cFieldList = ""
		FOR m.i = 1 TO ALEN(THIS.aAutoFields)
			THIS.cFieldList = THIS.cFieldList + LEFT(THIS.aAutoFields[i],iMaxFldLen) + ','
		NEXT
		THIS.cFieldList = LEFT(	THIS.cFieldList,LEN(THIS.cFieldList) - 1)	&& remove extra delimiter

	ENDPROC

	*----------------------------------
	PROCEDURE PrepData
	*----------------------------------
	
		*- prepare data source
		
		LOCAL cFlds, cOldSafe, iLen, iFH, lCopyFile, cDBQPath
		
		IF THIS.nNewDoc = N_EXISTING_DOC
			THIS.cDocName = ALLT(THIS.cDocName)
			IF EMPTY(THIS.cDocName)
				RETURN .F.
			ENDIF
		ENDIF

		IF !_mac												&& we aren't using ODBC on Mac
			*- get ODBC drivers -- we'll need this info later on
			*- Check for proper ODBC drivers
			IF !THIS.ODBCCheck()
				RETURN .F.
			ENDIF
		ENDIF

		m.lCopyFile = .F.

		IF THIS.lHas30Drivers AND CURSORGETPROP('sourcetype') # K_TABLE
			*- assume is a view that Word 6.0 can't handle -- don't use datasource
			THIS.cDataSrc = ""
		ELSE
			THIS.cDataSrc = DBF()
		ENDIF

		*- Check if we have a DBC in use
		SELECT (THIS.cAlias)

		*- Check if 3.0 DBC is opened exclusively
		IF THIS.lHas30Drivers AND !EMPTY(THIS.cDBCAlias) AND ISEXCL(THIS.JustStem(THIS.cDBCAlias),2)
			IF THIS.ALERT(C_EXCLDBC1_LOC + THIS.cDBCAlias + C_EXCLDBC2_LOC,36) == "YES"
				cTmpDbcAlias = THIS.cDBCAlias
				SET DATABASE TO (m.cTmpDbcAlias)
				CLOSE DATABASE 
				OPEN DATABASE (THIS.cDBCName) SHARED
				USE (THIS.cDBCTable) ALIAS (THIS.cAlias) SHARED
			ELSE
				RETURN
			ENDIF
		ENDIF
		
		*- Check for 3.0 Table type OR View
		*- Mac doesn't use ODBC so can handle 3.0 files, but can't handle Views
		IF !m.lCopyFile AND ;
			((!_mac AND !THIS.lHas30Drivers AND;
			(VAL(SYS(2029)) = DBFTYPE_30 OR CURSORGETPROP('sourcetype') # K_TABLE)) OR;
			(_mac AND CURSORGETPROP("sourcetype") # K_TABLE))
			IF THIS.Alert(IIF(_mac,C_COPYFOX3_LOC,C_COPYFOX2_LOC),36) $ "YES"
				lCopyFile = .T.
			ELSE
				RETURN .F.
			ENDIF
		ENDIF


		IF m.lCopyFile		
					
			LOCAL m.cSaveFile

			cFlds = THIS.cFieldList

			IF CURSORGETPROP('sourcetype') # 3		 && OR ATC(".TMP",DBF())#0
				THIS.cDataFile = CursorGetprop("sourcename")
			ELSE
				THIS.cDataFile = THIS.JustStem(DBF())
			ENDIF

			iLen = LEN(THIS.cDataFile)
			IF RIGHT(STR(VAL(THIS.cDataFile) + 10^iLen,iLen + 1),iLen) = THIS.cDataFile
				*- apparently a view? The filename is all numbers
				*- use the alias instead
				THIS.cDataFile = LEFT(THIS.cAlias,6)
			ENDIF
			DO CASE
			CASE LEN(THIS.cDataFile) < 7
				THIS.cDataFile = THIS.cDataFile + "_2"
			CASE LEN(THIS.cDataFile) = 7
				THIS.cDataFile = THIS.cDataFile + "2"
			CASE RIGHT(THIS.cDataFile,1) = "2"
				THIS.cDataFile = LEFT(THIS.cDataFile,7) + "_"
			OTHERWISE
				THIS.cDataFile = LEFT(THIS.cDataFile,7) + "2"
			ENDCASE
							
			m.coldsafe = SET("SAFE")
			SET SAFETY ON
			THIS.cDataFile = PUTFILE(C_COPYPROMPT_LOC,THIS.cDataFile + ".dbf","DBF")
			SET SAFETY &coldsafe
			IF EMPTY(THIS.cDataFile)
				RETURN .F.
			ENDIF

			THIS.cDataFile = THIS.FORCEEXT(THIS.cDataFile,"DBF")

			*- check if file exists, and if so, make sure that we can overwrite it
			IF FILE(THIS.cDataFile)
				THIS.SetErrorOff = .t.
				ERASE (THIS.cDataFile)
				THIS.SetErrorOff = .f.
				IF FILE(THIS.cDataFile)
					*- can't get rid of file, so fail
					THIS.Alert(E_NOREPLACETBL_LOC)
					RETURN .F.
				ENDIF
			ENDIF
			
			IF CURSORGETPROP("sourcetype") # K_TABLE
				=REQUERY()			&& get some data
			ENDIF
			COPY FIELDS &cFlds TO (THIS.cDataFile) TYPE FOX2

			*- Copied ok?
			IF !FILE(THIS.cDataFile)
				RETURN .F.
			ENDIF

			SELECT 0
			USE (THIS.cDataFile) SHARED

			*- Failed somewhere
			IF EMPTY(ALIAS()) OR VAL(SYS(2029))=DBFTYPE_30
				RETURN .F.
			ELSE
				*- get the SQL statement now, while we are using this temp table
				THIS.cDataSrc = THIS.cDataFile
				*- redo field list, since max for Fox 2.x table is only 10 chars
				THIS.MakeFieldList(10)
				THIS.GetSQLSt
			ENDIF
			USE

			SELECT (THIS.cAlias)

		ELSE
			THIS.cDataFile = DBF()
			THIS.GetSQLSt
		ENDIF

		THIS.cSqlStmt = STRTRAN(THIS.cSqlStmt,'"',"")		&& Word complains if quotes surround the table name
															&& but VFP won't execute SQL statement unless they are there

		IF THIS.nWordProc = N_WORD60 AND !_mac
			DO CASE
				CASE LEN(THIS.csqlstmt) > 510
					THIS.Alert(C_ERROR_SQL_LOC)
					THIS.csqlstmt = ""			&& error return below
				CASE LEN(THIS.csqlstmt) > 255
					THIS.csqlstmt2 = SUBS(THIS.csqlstmt,256)
					THIS.csqlstmt = LEFT(THIS.csqlstmt,255)
				OTHERWISE
					*- do nothing
			ENDCASE
		ENDIF

		IF EMPTY(THIS.csqlstmt)
			*- couldn't come up with SQL statement
			RETURN .F.
		ENDIF

		*- need to open table as shared access
		IF ISEXCLUSIVE() AND CURSORGETPROP('sourcetype') = K_TABLE
			USE IN (THIS.cAlias)
			m.iFH = FOPEN(THIS.cDataFile,0)
			IF m.iFH == -1
				*- can't open file, so fail
				THIS.ALERT(E_NOOPENTBL_LOC)
				RETURN .F.
			ELSE
				=FCLOSE(m.iFH)
			ENDIF
			USE (THIS.cDataFile) ALIAS (THIS.cAlias) SHARED
		ENDIF

		*- Get data -- should use same directory as foxpro table
		SELECT (THIS.cAlias)
		m.cDBQPath = IIF(EMPTY(THIS.cDataPath),SYS(2027,SET("DEFA") + SYS(2003)),THIS.cDataPath)

 		IF THIS.lHas30Drivers
			THIS.cODBCSource = "DSN="+THIS.cODBC_DSN+;
						 ";SourceDB="+IIF(EMPTY(THIS.cDBCName),m.cDBQPath,THIS.cDBCName)+;
						 ";SourceType="+IIF(EMPTY(THIS.cDBCName),"DBF","DBC")+;
						 ";Exclusive=No"+;
						 ";BackgroundFetch=Yes;"
        ELSE
			THIS.cODBCSource =	"DSN=" + THIS.cODBC_DSN + ;
							";DBQ=" + m.cDBQPath + ;
							";DefaultDir=" + m.cDBQPath + ;
							";FIL=" + THIS.cODBC_FIL +";"
		ENDIF

	ENDPROC
	
	
	*----------------------------------
	PROCEDURE MailMergeWinWord8
	*----------------------------------
		*- drive MS Word 6.0

		PRIVATE colddocs, wa
		LOCAL cDummy, nWordDocType, cSqlStmt, cODBCSource, cDBQPath
		LOCAL oDoc

		*- We need to set the Localization ID to english (1033)
		*- so that OLE Automation will be understood by OLE server.
		=SYS(3006,I_ENGLISH)
		
		*- create word object
		wa = CreateObject(WIN_8OBJ)

		*- Check if problem creating Word object
		IF TYPE('wa') # 'O'
			THIS.ALERT(E_NOOPENWORD_LOC)
			RETURN
		ENDIF

		*- Test language
		THIS.lEnglish = (wa.application.international[26] == I_ENGLISH)


		IF THIS.nNewDoc = N_EXISTING_DOC
			oDoc = wa.documents.open(THIS.cDocName)
		ELSE
			oDoc = wa.documents.new
			*- set main document type
			DO CASE
				CASE THIS.nTemplate = N_LABEL
					m.nWordDocType = 1
				CASE THIS.nTemplate = N_ENVELOPE
					m.nWordDocType = 2
				CASE THIS.nTemplate = N_CATALOG
					m.nWordDocType = 3
				OTHERWISE
					m.nWordDocType = 0
			ENDCASE
			oDoc.MailMerge.MainDocumentType = m.nWordDocType
		ENDIF

		*- attach data file
		oDoc.MailMerge.OpenDataSource(THIS.cDataSrc,0,0,0,0,0,"","",0,"","",m.cODBCSource,;
			THIS.csqlstmt, THIS.csqlstmt2)

		*- activate MSW with proper document
		wa.Visible = .T.
		wa.Activate
		

		*- try to display the appropriate dialog 
		IF THIS.nNewDoc = N_NEW_DOC
			*- display Word MailMergeHelper dialog
			wa.Dialogs[I_WDDIALOGMAILMERGEHELPER].Show
		ENDIF

		*- terminate the connection
		wa = .NULL.

		RETURN
	
	ENDPROC
	
	*----------------------------------
	PROCEDURE MailMergeWinWord6
	*----------------------------------
		*- drive MS Word 6.0

		PRIVATE colddocs, wa
		LOCAL cDummy, nWordDocType, cSqlStmt, cODBCSource, cDBQPath

		*- launch MSW, so it hangs around after word.basic is done
		IF !THIS.StartWord(C_WORD6)
			RETURN .F.
		ELSE
			*- We need to set the Localization ID to english (1033)
			*- so that OLE Automation will be understood by OLE server.
			=SYS(3006,I_ENGLISH)
		ENDIF
		
		*- create word object
		wa = CreateObject(WIN_6OBJ)

		*- Check if problem creating Word object
		IF TYPE('wa') # 'O'
			THIS.ALERT(E_NOOPENWORD_LOC)
			RETURN
		ENDIF

		*- Test language
		THIS.lEnglish = .T.
		THIS.SetErrorOff = .t.
		m.cdummy = wa.AppInfo(16)
		IF THIS.HadError
			THIS.lEnglish = .f.
			THIS.HadError = .f.
		ENDIF
		THIS.SetErrorOff = .f.

		*- Get data -- should use same directory as foxpro table
		SELECT (THIS.cAlias)
		m.cDBQPath = IIF(EMPTY(THIS.cDataPath),SYS(2027,SET("DEFA") + SYS(2003)),THIS.cDataPath)

 		IF THIS.lHas30Drivers
			cODBCSource = "DSN="+THIS.cODBC_DSN+;
						 ";SourceDB="+IIF(EMPTY(THIS.cDBCName),m.cDBQPath,THIS.cDBCName)+;
						 ";SourceType="+IIF(EMPTY(THIS.cDBCName),"DBF","DBC")+;
						 ";Exclusive=No"+;
						 ";BackgroundFetch=Yes;"
        ELSE
			cODBCSource =	"DSN=" + THIS.cODBC_DSN + ;
							";DBQ=" + m.cDBQPath + ;
							";DefaultDir=" + m.cDBQPath + ;
							";FIL=" + THIS.cODBC_FIL +";"
		ENDIF

		IF THIS.lEnglish
			IF THIS.nNewDoc = N_EXISTING_DOC
				wa.ENG_OLE_FILEOPEN(THIS.cDocName)
			ELSE
				wa.ENG_OLE_FILENEW
				*- set main document type
				DO CASE
					CASE THIS.nTemplate = N_LABEL
						m.nWordDocType = 1
					CASE THIS.nTemplate = N_ENVELOPE
						m.nWordDocType = 2
					CASE THIS.nTemplate = N_CATALOG
						m.nWordDocType = 3
					OTHERWISE
						m.nWordDocType = 0
				ENDCASE
				IF THIS.lEnglish
					wa.ENG_OLE_MMERGEDOCTYPE(m.nWordDocType)
				ELSE
					wa.X_OLE_MMERGEDOCTYPE_LOC(m.nWordDocType)
				ENDIF
			ENDIF

			*- attach data file
			wa.ENG_OLE_MMERGEOPENSRC(THIS.cDataSrc,0,0,0,0,"","",0,"","",m.cODBCSource,;
				THIS.csqlstmt, THIS.csqlstmt2)

			*- activate MSW with proper document
			wa.ENG_OLE_APPRESTORE				&& this doesn't seem to work, hence... 

			THIS.sysch = DDEInitiate(C_MSWORDWIN,"System")
			IF THIS.sysch > 0
				=DDEExecute(THIS.sysch,ENG_APPRESTORE)
				=DDETerminate(THIS.sysch)
			ENDIF

			wa.ENG_OLE_APPACTIVATE(WIN_SECT6,1)

		ELSE
			IF THIS.nNewDoc = N_EXISTING_DOC
				wa.X_OLE_FILEOPEN_LOC(THIS.cDocName)
			ELSE
				wa.X_OLE_FILENEW_LOC
			ENDIF

			*- attach data file
			wa.X_OLE_MMERGEOPENSRC_LOC(THIS.cDataSrc,0,0,0,0,"","",0,"","",m.cODBCSource,;
				THIS.csqlstmt, THIS.csqlstmt2)

			*- activate MSW with proper document
			wa.X_OLE_APPRESTORE_LOC

			THIS.sysch = DDEInitiate(C_MSWORDWIN,"System")
			IF THIS.sysch > 0
				=DDEExecute(THIS.sysch,X_APPRESTORE_LOC)
				=DDETerminate(THIS.sysch)
			ENDIF

			wa.X_OLE_APPACTIVATE_LOC(WIN_SECT6,1)
		ENDIF

		*- try to display the appropriate dialog 
		IF THIS.nNewDoc = N_NEW_DOC
			*- display appropriate Word dialog
			DO CASE
				CASE THIS.nTemplate = N_LABEL
					THIS.mswmldlg(N_LABEL)
				CASE THIS.nTemplate = N_ENVELOPE
					THIS.mswmldlg(N_ENVELOPE)
				CASE THIS.nTemplate = N_CATALOG
					THIS.mswmldlg(N_CATALOG)
				OTHERWISE
			ENDCASE
		ENDIF

		*- terminate the connection
		wa = .NULL.

		RETURN
	ENDFUNC

	*----------------------------------
	FUNCTION  mswmldlg
	*----------------------------------
		PARAMETER itmpl


		IF THIS.nWordProc # N_WORD60
			RETURN .T.
		ENDIF

		IF THIS.lEnglish
			wa.ENG_OLE_TOOLSMACRO("MailMergeHelper",1,0)
		ELSE
			wa.X_OLE_TOOLSMACRO_LOC(X_OLE_MAILMERGEHELPER_LOC,1,0)
		ENDIF

		RETURN .T.

	ENDFUNC

	*----------------------------------
	FUNCTION StartWord
	*----------------------------------
		PARAMETER cversion
		*- Routine is called to check if Word is 
		*- running and/or DDE system channel is set.
		*- Also check if Word was closed by user
		*- while FoxPro screen open.

		LOCAL llauncherr, lsafety, cworddir, claunchmsg, m.nLastDDEError, cSysItems,;
			cScript, cExe

		m.llauncherr = .F.

		DO CASE
			CASE _windows
				THIS.cexe = C_MSWORDEXE
			CASE _mac
				THIS.cexe = C_MSWORDMAC
			OTHERWISE
				THIS.cexe = ""
		ENDCASE

		DO CASE
			CASE cversion = C_WORD6
				m.cLaunchMsg = C_STARTWORD60_LOC
			OTHERWISE
				RETURN .F.
		ENDCASE
			
		m.cOldErr = ON('ERROR')
		ON ERROR m.llauncherr = .T.

		IF _mac
			*-
			*- note -- the following is to support interacting with Word via OLE automation 
			*- It is not currently used (Applescript is used instead, called above)
			*-
			*- get word location
			*- force user to locate it

			THIS.cexe = "Raw:Apps:Microsoft Office:Microsoft Word 6:Microsoft Word"
			IF !FILE(THIS.cexe)
				THIS.cexe = SYS(2027,GETFILE("","Locate " + ALLT(THIS.cexe),"",0,'APPL'))
			ENDIF
			IF EMPTY(THIS.cexe)
				*- cancelled
				RETURN .F.
			ELSE
				*- update prefs
				*=PutPref('PREFM',K_WORD6ID,'MS Word 6.0 Location',.F.,C_MSWORDMAC)
			ENDIF

			*- create Applescript
			cScript = SYS(2027,SYS(2023)) + SYS(3) + ".script"

			SET TEXTMERGE TO (m.cScript)
			SET TEXTMERGE ON NOSHOW
			\\ -- AppleScriptª script to launch MS Word for Macintosh 6.0
			\tell application "<<THIS.cexe>>"
			\	Run
			\end tell
			*- close textmerge file, strip out linefeeds
			SET TEXTMERGE TO
			THIS.FxStripLF(m.cScript)
			*- run Applescript
			RUNSCRIPT (m.cScript)

		ELSE
			*- Not Macintosh
			*- Terminate a prior channel if user quit Word
			*- while still in screen.
			IF THIS.sysch # -1
				=DDERequest(THIS.sysch,'topics')
				m.nLastDDEError = DDELastError()
				IF m.nLastDDEError == N_NOCLIENTERR OR m.nLastDDEError == N_BADCHANNELERR 
					=DDETerminate(THIS.sysch)
					THIS.sysch = -1
				ENDIF
			ENDIF
			IF THIS.sysch = -1
				m.lsafety = DDESetOption("SAFETY")
				=DDESetOption("SAFETY",.F.)
				THIS.sysch = DDEInitiate(C_MSWORDWIN,"System")
				IF THIS.sysch = -1				&& failed
					*- obtain Word directory
					THIS.cexe = THIS.GetMSW(m.cversion)
					IF EMPTY(THIS.cexe)
						*- failed to find .INI info, so fail
						THIS.sysch = -1
					ELSE
						WAIT WINDOW m.cLaunchMsg NOWAIT
						m.cexe = THIS.cexe
						RUN /N7 &cexe
						THIS.sysch = DDEInitiate(C_MSWORDWIN,"System")
					ENDIF
				ENDIF
				IF THIS.sysch = -1 AND !THIS.lAlerted
					THIS.ALERT(E_NOMSWLAUNCH_LOC)
				ENDIF
			ENDIF
			IF THIS.sysch <> -1
				*- if they got it launched
				*- check version of word
				IF !THIS.checkver(m.cversion)
					THIS.ALERT(E_WRONGWORD_LOC)
					=DDETerminate(THIS.sysch)
					THIS.sysch = -1
				ENDIF
			ENDIF
		ENDIF

		*- okay, re-set error handler
		ON ERROR &cOldErr
		IF _mac
			THIS.sysch = 0		&& so it looks like success
		ELSE
			=DDESetOption("SAFETY",m.lsafety)
		ENDIF
		WAIT CLEAR

		RETURN (THIS.sysch # -1)

	ENDPROC	&& startword


	*----------------------------------
	FUNCTION checkver
	*----------------------------------

		*- Verify WORD version

		PARAMETER m.cversion

		LOCAL lwoozle

		m.lwoozle = ("Woozle" $ DDERequest(THIS.sysch,'Formats'))
		RETURN ((m.cversion = "2.0" AND !m.lwoozle) OR (m.cversion = "6.0" AND m.lwoozle))
	ENDFUNC

	*----------------------------------
	FUNCTION GetMSW
	*----------------------------------
		*- get the MS Word command line from registry file

		PARAMETER m.cversion

		LOCAL cCommand, cExtKey, oReg

		cCommand = ""
		cExtKey = ""

		IF !("REGISTRY" $ SET("PROC"))
			SET PROCEDURE TO registry ADDITIVE
		ENDIF
		
		oReg = CREATE("registry")
		IF TYPE("oReg") # 'O'
			*- failed to create registry object, so fail...
			RETURN ""
		ENDIF

		DO CASE
		
			CASE m.cversion = C_WORD6_OR_LATER

				*- look in the Registry for the current installed version of Word
				IF (oReg.GetLatestVersion(REG_MSWDOC_KEY,@cExtKey,@cCommand) != ERROR_SUCCESS)
					RETURN ""
				ENDIF
				
				THIS.cWordVersion = RIGHT(cExtKey,1)
				IF VAL(THIS.cWordVersion) < VAL(C_WORD6)
					*- no Word 6.0 or later in Registry
					RETURN ""
				ENDIF
				
				*- strip off any command line options (e.g., "/W")
				m.cCommand = ALLT(IIF("/" $ m.cCommand,LEFT(m.cCommand,AT("/",m.cCommand) - 1),m.cCommand))

				*-------------------------------------------------
				*- if MS Word 6.0 or later, make sure ODBC stuff is present

				IF !THIS.IsODBC(FOXODBC_ANY,"D")
					WAIT CLEAR
					THIS.Alert(E_ODBC2_LOC)
					THIS.lAlerted = .T.
					RETURN ""
				ENDIF

				*- set the data source
				THIS.GetDSN
				IF EMPTY(THIS.aODBCDrivers[1,1])
					RETURN ""
				ENDIF

			OTHERWISE
				m.nRetLen = 0
		ENDCASE
		
		IF EMPTY(m.cCommand)
			*- couldn't get the info
			WAIT CLEAR
			THIS.Alert(STRTRAN(E_NOWORDERR_LOC,"@1",m.cversion))
			THIS.lAlerted = .T.
		ENDIF

		RETURN m.cCommand

	ENDFUNC

	*----------------------------------
	FUNCTION GetSQLSt
	*----------------------------------
		*- get the SQL statement for extracting data

		PRIVATE m.nfh, m.cext, m.ccurtable

		STORE "" TO csqlstmt, cconnstmt
		m.cfname = ""

		IF CURSORGETPROP("sourcetype") = K_TABLE
			*- simple table, so give them the whole mess
			THIS.csqlstmt = [select ] + THIS.cFieldList + [ from '] + THIS.JustFName(SYS(2027,THIS.cDataSrc)) + [']
			THIS.cDataPath = THIS.AddBS(THIS.JustPath(SYS(2027,THIS.cDataSrc)))
		ELSE
			THIS.csqlstmt = DBGETPROP(THIS.cDBCTable,"VIEW","SQL")
		ENDIF
		RETURN
	ENDFUNC


	*----------------------------------
	PROCEDURE MrgCommaDel
	*----------------------------------
	*-Generate a delimted text file of data
		PARAMETER cdelimit

		IF PARAMETER() = 0
			cdelimit = ","
		ENDIF

		PRIVATE ncurselect, lretval

		m.ncurselect = SELECT()

		THIS.cDataSrc = DBF()

		THIS.GetSQLSt
		IF EMPTY(THIS.csqlstmt)
			*- couldn't come up with SQL statement
			RETURN .F.
		ENDIF

		THIS.cSaveFile = ALLT(PUTFILE(C_MMSAVEAS_LOC,C_DFLTNAME_LOC,EXT_TXT))
		IF EMPTY(THIS.cSaveFile)
			RETURN .F.
		ENDIF

		THIS.SaveSql(L_DONTGETFILE)
		IF !EMPTY(THIS.ctmpfile) AND FILE(THIS.ctmpfile)
			SELECT 0
			USE (THIS.ctmpfile)
		ELSE
			RETURN .F.
		ENDIF
	

		m.lretval = THIS.wzmmdata(THIS.cSaveFile,m.cdelimit)

		IF !EMPTY(THIS.cTmpFile)
			*- close temp file
			USE
			ERASE (THIS.cTmpFile)
			IF FILE(THIS.JustStem(THIS.ctmpfile) + ".FPT")
				ERASE (THIS.JustStem(THIS.ctmpfile) + ".FPT")
			ENDIF
			IF FILE(THIS.JustStem(THIS.ctmpfile) + ".CDX")
				ERASE (THIS.JustStem(THIS.ctmpfile) + ".CDX")
			ENDIF
		ENDIF

		*- reselect current work area
		SELECT (ncurselect)

		RETURN m.lretval

	ENDFUNC	&& MrgCommaDel


	*----------------------------------
	FUNCTION wzmmdata
	*----------------------------------
		*-	Copy data to a text file, with field names on line 1
		*-	Assumes source file is open in current work area
		*-
		*-	Parameters	csavefile	C	name of text file to hold results
		*-				cdelimit		C	delimter
		*-
		*-	Returns .T. if success, otherwise .F.

		PARAMETER csavefile, cdelimit

		PRIVATE wzmmflds, nctr, nfh, ntempfh, nfsize, cbytesread, wztempfile
		LOCAL ccrlf

		IF _mac
			ccrlf = IIF(THIS.nWordProc = N_WORD60,CHR(13) + CHR(10), CHR(13))	&& so it matches the way Fox exports the data
		ELSE
			ccrlf = CHR(13) + CHR(10)
		ENDIF


		STORE -1 TO m.nfh, m.ntempfh
		m.wztempfile = ""

		*- step 1: create the destination file
		m.nfh = FCREATE(m.csavefile,0)
		IF m.nfh = -1
			*- failed to create file
			THIS.MMCleanup(.F.,m.nfh, m.ntempfh, m.wztempfile)
			RETURN .F.
		ENDIF

		*- step 2 -- write out header (field names)
		m.nfcount = AFIELDS(wzmmflds)
		FOR m.nctr = 1 TO m.nfcount
			*- keep last field name even if memo, to prevent invalid field name err
			IF wzmmflds[m.nctr,2] $ 'MG' AND m.nctr < m.nfcount
				*- skip Memo fields and General fields
				LOOP
			ENDIF
			IF FWRITE(m.nfh,wzmmflds[m.nctr,1]) = 0
				THIS.MMCleanup(.F.,m.nfh, m.ntempfh, m.wztempfile)
				RETURN .F.
			ENDIF
			IF m.nctr < m.nfcount
				IF FWRITE(m.nfh,cdelimit) = 0
					THIS.MMCleanup(.F.,m.nfh, m.ntempfh, m.wztempfile)
					RETURN .F.
				ENDIF
			ENDIF	
		NEXT

		IF m.nfcount = 1 AND THIS.nWordProc = N_WORD60 AND _mac
			*- Word complains if there is only one field
			IF FWRITE(m.nfh,cdelimit) = 0
			THIS.MMCleanup(.F.,m.nfh, m.ntempfh, m.wztempfile)
			RETURN .F.
		ENDIF
		ENDIF

		IF FWRITE(m.nfh,ccrlf) = 0
			THIS.MMCleanup(.F.,m.nfh, m.ntempfh, m.wztempfile)
			RETURN .F.
		ENDIF

		*- step 3 -- write data out to a separate file
		m.wztempfile = SYS(3) + ".TXT"

		IF m.cdelimit = K_TAB
			COPY TO (m.wztempfile) DELI WITH TAB
		ELSE
			COPY TO (m.wztempfile) DELI
		ENDIF

		*- step 4: move temp file data to end of destination file
		m.ntempfh = FOPEN(m.wztempfile,0)
		IF m.ntempfh = -1
			*- failed to open temp file
			THIS.MMCleanup(.F.,m.nfh, m.ntempfh, m.wztempfile)
			RETURN .F.
		ENDIF

		*- get file size, and return pointer to top of file
		=FSEEK(m.ntempfh,0)

		*- Readin' and writin'
		DO WHILE !FEOF(m.ntempfh)
			m.cbytesread = FREAD(m.ntempfh,K_TRANSFER)
			IF m.nfcount = 1 AND THIS.nWordProc = N_WORD60 AND _mac
				*- add a extra delimiter
				m.cbytesread = STRTRAN(m.cbytesread,ccrlf,cdelimit + ccrlf)
			ENDIF
			IF THIS.nWordProc # N_WORD60 AND _mac
				*- remove LFs on Mac
				m.cbytesread = STRTRAN(m.cbytesread,CHR(10),'')
			ENDIF
			m.nbyteswrit = FWRITE(m.nfh, m.cbytesread)
			IF m.nbyteswrit <> LEN(m.cbytesread)
				*- error writing file
				THIS.MMCleanup(.F.,m.nfh, m.ntempfh, m.wztempfile)
				RETURN .F.
			ENDIF
		ENDDO

		*- that should be it
		THIS.MMCleanup(.T.,m.nfh, m.ntempfh, m.wztempfile)

		RETURN .T.
	ENDFUNC

	*----------------------------------
	FUNCTION MMCleanup
	*----------------------------------
		*-     Close files, erase temp file
		PARAMETER lok, nfh1, nfh2, ctempfile

		IF !m.lok
			THIS.ALERT(E_FILEERR_LOC)
		ENDIF

		IF m.nfh1 > -1
			=FCLOSE(m.nfh1)
		ENDIF

		IF m.nfh2 > -1
			=FCLOSE(m.nfh2)
		ENDIF

		IF !EMPTY(ctempfile) AND FILE(ctempfile)
			ERASE (ctempfile)
		ENDIF

		RETURN  .T.
	ENDFUNC

	*----------------------------------
	FUNCTION SaveSql
	*----------------------------------
	*- Generate a table of the SQL query results

		PARAMETER lgetfname

		PRIVATE m.ccurtable
		
		LOCAL cOldDefa

		IF lgetfname
				m.coldsafe = SET("SAFE")
				SET SAFETY ON
				THIS.ctmpfile = PUTFILE(C_MMSAVEAS_LOC,C_DFLTDBF_LOC,EXT_DBF)
				SET SAFETY &coldsafe
		ELSE
			THIS.ctmpfile = SYS(3) + ".DBF"
		ENDIF

		IF EMPTY(THIS.ctmpfile)
			RETURN .F.
		ELSE
			m.ccurtable = IIF(!EMPTY(ALIAS()),ALIAS(),"")
			m.csqlstmt = THIS.csqlstmt

			*- execute the SQL query
			cOldDefa = SET("DEFAULT") + CURDIR()
			IF !EMPTY(THIS.cDataPath)
				SET DEFAULT TO (THIS.cDataPath)
			ENDIF
			&csqlstmt INTO DBF (THIS.cTmpFile)
			THIS.ctmpfile = FULLPATH(THIS.ctmpfile)
			USE
			IF !EMPTY(m.ccurtable) AND USED(m.ccurtable)
				SELECT (ccurtable)
			ENDIF
			THIS.csqlstmt = "SELECT * FROM " + THIS.JustFName(THIS.cTmpFile)
			THIS.cDataPath = THIS.AddBS(THIS.JustPath(THIS.cTmpFile))
			SET DEFAULT TO (m.cOldDefa)	
		ENDIF
		RETURN .T.

	ENDFUNC	&& SaveSql

	
	*----------------------------------
	PROCEDURE IsODBC
	*----------------------------------
		PARAMETER cODBCStr, cItemType
		*- check aODBCDrivers array for presence of requested driver
		*- cItemType = "D" search for driver (column 2)
		*-           = "S" search for data source (column 1)

		LOCAL cOldExact, nVal

		m.cOldExact = SET("EXACT")
		SET EXACT OFF
		nVal = THIS.AScanAny("THIS.aODBCDrivers",cODBCStr,IIF(cItemType = "S",1,2))
		SET EXACT &cOldExact

		RETURN (nVal > 0)

	ENDPROC

	*----------------------------------
	PROCEDURE GetDSN
	*----------------------------------
		*- set value of DSN
		*- do cascading list of drivers
		LOCAL cOldExact, nVal

		m.cOldExact = SET("EXACT")
		SET EXACT OFF

		nVal = THIS.AScanAny("THIS.aODBCDrivers",FOXODBC_30,2)
		IF nVal > 0
			THIS.cODBC_DSN = THIS.aODBCDrivers[nVal,1]
		ELSE		
			nVal = THIS.AScanAny("THIS.aODBCDrivers",FOXODBC_26,2)
			IF nVal > 0
				THIS.cODBC_DSN = THIS.aODBCDrivers[nVal,1]
			ELSE
				nVal = THIS.AScanAny("THIS.aODBCDrivers",FOXODBC_25,2)
				IF nVal > 0
					THIS.cODBC_DSN = THIS.aODBCDrivers[nVal,1]
				ENDIF
			ENDIF
		ENDIF

		SET EXACT &cOldExact

	ENDPROC		&&	GetDSN

	*----------------------------------
	PROCEDURE GetODBC
	*----------------------------------
		*- get a list of the ODBC drivers, and store in a property of the merge engine
		PARAMETER cSect
		LOCAL aODBCSects,retval,oINI,cValue,nArrLen,i
		LOCAL nPos,cSaveExact, retval, cValue

		DIMENSION aODBCSects[1]

		IF PARAMETERS()=0
			cSect = 0
		ENDIF

 		IF _mac
			*- look in ODBC preferences file
			*- get location of System Folder:Preferences
			*-
			*- NOTE: we check only the ODBC Settings file (NOT ODBC Settings PPC),
			*- since the Foxpro Driver is 68K only
			*-
			retval = THIS.GetINISection(@aODBCSects,ODBC_SOURCE,ODBC_FILE_68K)
			DO CASE
				CASE m.retval = ERROR_NOINIFILE
					THIS.Alert(E_ODBC1_LOC)
					RETURN .F.
				CASE m.retval = ERROR_NOINIENTRY
					*- do nothing
				CASE m.retval = ERROR_FAILINI
					*- do nothing
				OTHERWISE
					FOR i = 1 TO ALEN(aODBCSects)
						cValue = ""
						IF _mac
							cValue = THIS.GetPref(ODBC_SOURCE,aODBCSects[m.i],ODBC_FILE_68K)
						ENDIF
						IF ATC(FOXODBC_ANY,cValue) # 0
							IF !EMPTY(THIS.aODBCDrivers[1])
								DIMENSION THIS.aODBCDrivers[ALEN(THIS.aODBCDrivers,1)+1,2]
							ENDIF
							THIS.aODBCDrivers[ALEN(THIS.aODBCDrivers,1),1] = aODBCSects[m.i]
							THIS.aODBCDrivers[ALEN(THIS.aODBCDrivers,1),2] = m.cValue			
						ENDIF
					ENDFOR
			ENDCASE

			IF EMPTY(THIS.aODBCDrivers[1])
				*- failed to find any ODBC sources
				THIS.ALERT(E_ODBC2_LOC)
				THIS.aODBCDrivers = ""
			ENDIF

			*- need to check for 3.0 drivers?

		ELSE
			retval = oReg.GetINISection(@aODBCSects,m.cSect,ODBC_FILE)
			DO CASE
				CASE m.retval = ERROR_NOINIFILE
					THIS.Alert(E_ODBCDLL_LOC)
					RETURN .F.
				CASE m.retval = ERROR_NOINIENTRY
					*- do nothing
				CASE m.retval = ERROR_FAILINI
					*- do nothing
				OTHERWISE
					FOR i = 1 TO ALEN(aODBCSects)
						cValue = ""
						=oReg.GetINIEntry(@cValue,m.cSect,aODBCSects[m.i],ODBC_FILE)
						IF ATC("FoxPro",cValue) # 0
							IF !EMPTY(THIS.aODBCDrivers[1])
								DIMENSION THIS.aODBCDrivers[ALEN(THIS.aODBCDrivers,1) + 1, 2]
							ENDIF
							THIS.aODBCDrivers[ALEN(THIS.aODBCDrivers, 1),1] = aODBCSects[m.i]
							THIS.aODBCDrivers[ALEN(THIS.aODBCDrivers, 1),2] = m.cValue			
						ENDIF
					ENDFOR
			ENDCASE

			RETURN .T.

		ENDIF		&& _mac

	ENDPROC

	*----------------------------------
	PROCEDURE ODBCCheck
	*----------------------------------

		* Checks and gets FoxPro ODBC data sources for MS Query to use
		* when called by Excel thru OLE automation. Note: MS Query 1.0
		* reads from INI files and NOT the Registry.
		
		LOCAL cBuffer,nBufSize,cDLLName,i,cSection,cValue,aODBCSects
		cValue = ""

		SET PROCEDURE TO registry ADDITIVE
		oReg = CREATE('registry')
		
		*- Check to see if we have a registered FoxPro ODBC Data Source in ODBC.INI.
		IF !THIS.GetODBC(ODBC_SOURCE)
			THIS.ALERT(E_ODBC1_LOC)
			RETURN .F.
		ENDIF
		
		*- Check to see if we have a registered FoxPro ODBC 32 bit Data Source in ODBC.INI.
		IF !THIS.GetODBC(ODBC_32SOURCE)
			THIS.ALERT(E_ODBC1_LOC)
			RETURN .F.
		ENDIF
		
		*- Finally, check if "FoxPro Files" is a section but somehow 
		*- was not listed as a registered ODBC Data Source. Let's
		*- by default set it to FoxPro 2.6 driver.
		IF EMPTY(THIS.aODBCDrivers[1])
			DIMENSION aODBCSects[1]
			IF oReg.GetINISection(@aODBCSects,THIS.cODBC_DSN,ODBC_FILE) = ERROR_SUCCESS
				m.cSection = THIS.cODBC_DSN
				THIS.aODBCDrivers[1,1] = THIS.cODBC_DSN
				THIS.aODBCDrivers[1,2] = FOXODBC_26FIX
			ENDIF
		ENDIF
		
		*- Failed to find a FoxPro section
		IF EMPTY(THIS.aODBCDrivers[1])
			*- failed to find any ODBC sources
			THIS.ALERT(E_ODBC2_LOC)
			RETURN .F.
		ENDIF

		*- Get Data Driver name and File type here
		THIS.GetODBCData()
		
		*- Check for correct driver installed
		THIS.CheckODBCFoxVer()

		RETURN .T.
	ENDPROC


	*----------------------------------
	PROCEDURE GetODBCData
	*----------------------------------
		LOCAL nPos,cSaveExact
		
		*- First check to see if we have 3.0 drivers
		FOR nPOS = 1 TO ALEN(THIS.aODBCDrivers,1)
			IF ATC(FOXODBC_30, THIS.aODBCDrivers[m.nPos, 1]) # 0
				THIS.cODBC_DSN = THIS.aODBCDrivers[m.nPos, 1]
				THIS.lHas30Drivers = .T.
				RETURN
			ENDIF
		ENDFOR
		
		*- Check to see if we have "FoxPro Files" generic 2.6 driver
		cSaveExact = SET("EXACT")
		SET EXACT ON
		nPOS = ASCAN(THIS.aODBCDrivers, THIS.cODBC_DSN)
		IF m.nPOS == 0 OR nPos = ALEN(THIS.aODBCDrivers)
			nPOS = 1
			THIS.cODBC_DSN = THIS.aODBCDrivers[1, 1]
		ENDIF
		SET EXACT &cSaveExact
	ENDPROC


	*----------------------------------
	PROCEDURE CheckODBCFoxVer
	*----------------------------------
		*- This checks for the Win32s (16bit) DriverID ODBC.INI
		*- setting for FoxPro Files 2.6 section. It merely alerts user if there
		*- is an old driver installed.

		IF THIS.lHas30Drivers
			RETURN
		ENDIF	

		LOCAL aFoxSect,retlen,i,cValue
		DIMENSION aFoxSect[1]
		IF THIS.nCurrentOS = OS_W32S	&& Win322
			IF oreg.GetINISection(@aFoxSect,THIS.aODBCDrivers[1,1],ODBC_FILE)#0
				*- Failed to read INI file, so skip this check
				RETURN
			ENDIF
			FOR i = 1 TO ALEN(aFoxSect)
				IF ATC(C_DRIVEID,aFoxSect[m.i])#0	&& Look for DriverID
					cValue = ""			
					oreg.GetINIEntry(@cValue,THIS.aODBCDrivers[1,1],aFoxSect[m.i],ODBC_FILE)
					IF VAL(m.cValue) = FOX_DRIVEID	&&24
						THIS.ALERT(C_ODBCOLDVER_LOC)
					ENDIF
					EXIT
				ENDIF
			ENDFOR
		ELSE
			*- Check for correct version in NT, Win95
			IF oReg.EnumOptions(@aFoxSect,ODBC_DATA_KEY+THIS.aODBCDrivers[1,1],HKEY_CURRENT_USER,.F.)#0
				*- Failed to read Registry, so skip this check
				RETURN
			ENDIF
			FOR i = 1 TO ALEN(aFoxSect,1)
				IF ATC(C_FIL,aFoxSect[m.i,1])#0	AND ATC(C_FOX2,aFoxSect[m.i,2]) # 0		&& Look for FIL
					THIS.ALERT(C_ODBCOLDVER_LOC)
					EXIT
				ENDIF
				IF ATC(C_DRIVEID,aFoxSect[m.i,1])#0	&&Look for DriverID
					*- test for DWORD first and then ASCII
					IF (ASC(SUBSTR(aFoxSect[m.i,2],1,1)) = FOX_DRIVEID AND ASC(SUBSTR(aFoxSect[m.i,2],2,1))=0) OR;
						VAL(aFoxSect[m.i,2]) = FOX_DRIVEID
						THIS.ALERT(C_ODBCOLDVER_LOC)
						EXIT
					ENDIF
				ENDIF
			ENDFOR
		ENDIF
	ENDPROC



	*----------------------------------
	FUNCTION MailMergeMacWord6
	*----------------------------------
		*- drive MS Word for Macintosh 6.0
		*-
		*- step 1: Create text file of data
		*- step 2: Create Applescript using textmerge that will open specified
		*-         file, and attach data to it.
		*- step 3: Run Applescript
	
		LOCAL cscript, lscripterr

		IF !_mac
			*- this is only for the Mac
			RETURN .F.
		ENDIF

		IF EMPTY(THIS.cexe)
			THIS.cexe = ""
			*- locate MS Word 6.0
			*- look to see if there is a "Word Settings (6)" file in
			*- the Preferences folder
			*- check the resource file
			IF !FILE(SYS(2033,2) + ":" + C_WORDSETTINGS)
				*- assume word is not installed
				THIS.Alert(E_NOWORDMACERR_LOC)
				RETURN .F.
			ENDIF
			THIS.cexe = THIS.GetPref(C_MAILMRG_SECT,C_WORD6ID,C_FOXPROINI_MAC)
			IF !FILE(THIS.cexe)
				THIS.cexe = ""
			ENDIF
			IF EMPTY(THIS.cexe)
				THIS.cexe = SYS(2027,GETFILE("",C_LOCATE_LOC + C_MSWORDMAC,"",0,'APPL'))
				IF EMPTY(THIS.cexe)
					*- cancelled
					RETURN .F.
				ELSE
					*- update prefs
					=THIS.PutPref(C_MAILMRG_SECT,C_WORD6ID,THIS.cexe,C_FOXPROINI_MAC)
				ENDIF
			ENDIF
		ENDIF

		*- works the same as Word for DOS, except will go on
		*- to pass name of text data file to Word via DDE
		IF !THIS.MrgCommaDel(',')
			RETURN .F.
		ENDIF


		WAIT WINDOW NOWAIT C_STARTWORD60_LOC

		*- prepare to create Applescript
		cscript = SYS(2027,SYS(2023)) + SYS(3) + ".script"

		SET TEXTMERGE TO (m.cscript)
		SET TEXTMERGE ON NOSHOW
		\\ -- AppleScript<<CHR(170)>> script to drive MS Word for Macintosh 6.0
		\tell application "<<THIS.cExe>>"
		*- bring to front
		\	Activate
		*- open document, or create a new one
		IF THIS.nNewDoc = N_EXISTING_DOC
			\	Open "<<THIS.cDocName>>"
			\	do script <<CHR(194)>>
			\		"MailMergeOpenDataSource .Name = \"<<SYS(2027,THIS.cSaveFile)>>\"
		ELSE
			\	do script <<CHR(194)>>
			\		"
			\\FileNew
			DO CASE
				CASE THIS.nTemplate = N_LABEL
					\		MailMergeMainDocumentType 1
				CASE THIS.nTemplate = N_ENVELOPE
					\		MailMergeMainDocumentType 2
				CASE THIS.nTemplate = N_CATALOG
					\		MailMergeMainDocumentType 3
			ENDCASE
			*- attach data file
			\		MailMergeOpenDataSource .Name = \"<<SYS(2027,THIS.cSaveFile)>>\"
		ENDIF


#IF 0
	*- the next few lines show how to use ODBC
	*- in this version we generate a text file of data instead, and attach it to a Word
	*- doc for the user (see above)
		\		MailMergeOpenDataSource .Name = \"<<SYS(2027,THIS.cDataSrc)>>\",
		\\ .Connection = \"DSN=<<THIS.cODBC_DSN>>;DBQ=<<SYS(2027,SET("DEFA") + SYS(2003))>>;FIL=<<THIS.cODBC_FIL>>\", 
		\\ .SQLStatement = \"<<THIS.csqlstmt>>\"
#ENDIF

		IF THIS.nNewDoc = N_NEW_DOC AND (THIS.nTemplate = N_LABEL OR THIS.nTemplate = N_ENVELOPE)
			\		Dim dlg As MailMergeHelper
			\		GetCurValues dlg
			\		x = Dialog(dlg)
		ENDIF
		*- end WordBasic script
		\		"
		\end tell
		\

		*- close textmerge file, strip out linefeeds
		SET TEXTMERGE TO
		THIS.FxStripLF(m.cscript)

		THIS.SetErrorOff = .T.

		*- now go ahead and run it
		RUNSCRIPT (m.cscript)

		*- restore normal error handling
		THIS.SetErrorOff = .F.

#IF 0
		*- second script, to display appropriate dialog, if labels or envelopes
		IF THIS.nNewDoc = N_NEW_DOC AND (THIS.nTemplate = N_LABEL OR THIS.nTemplate = N_ENVELOPE)
			cscript2 = SYS(2027,SYS(2023)) + SYS(3) + ".script"

			SET TEXTMERGE TO (m.cscript2)
			SET TEXTMERGE ON NOSHOW
			\\ -- AppleScript<<CHR(170)>> script to drive MS Word for Macintosh 6.0
			\tell application "<<THIS.cExe>>"
			\	with timeout of 0 seconds
			\		do script <<CHR(194)>>
			\			"Dim dlg As MailMergeHelper
			\			GetCurValues dlg
			\			x = Dialog(dlg)"
			\	end timeout
			\end tell
			\

			*- close textmerge file, strip out linefeeds
			SET TEXTMERGE TO
			THIS.FxStripLF(m.cscript2)

			THIS.SetErrorOff = .T.

			*- now go ahead and run it
			RUNSCRIPT (m.cscript2)

			*- restore normal error handling
			THIS.SetErrorOff = .F.

			*- toss the script file 2
			ERASE (m.cscript2)

		ENDIF
#ENDIF
		IF !L_DEBUG
			*- toss the script file 1
			ERASE (m.cscript)
		ENDIF

		WAIT CLEAR

		RETURN .T.

	ENDFUNC


	*----------------------------------
	FUNCTION  mswerr
	*----------------------------------
		*- Error handler while script is being run
		PARAMETER errnum, cmsg

		#DEFINE N_RUNSCRIPTFAIL		1921	&& FP error numbers
		#DEFINE N_SCRIPTERROR		1917

		IF errnum = K_RUNSCRIPTFAIL
			THIS.MrgCommaDel
			THIS.ALERT(E_NOAPPLESCRIPT_LOC)
		ENDIF

		RETURN .T.

	ENDFUNC



ENDDEFINE	&& MailMerge

*- eof
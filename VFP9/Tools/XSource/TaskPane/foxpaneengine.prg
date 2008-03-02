#include "foxpro.h"
#include "foxpane.h"

DEFINE CLASS FoxPaneEngine AS Session
	Name = "FoxPaneEngine"

	PaneTable        = "TaskPane.dbf"
	PaneContentTable = "PaneContent.dbf"

	* these aren't constant -- may get changed if specified
	* differently in FoxUser or if we can't find in
	* default location
	PaneDir          = ADDBS(HOME(7)) + "TaskPane"
	CacheHomeDir     = ADDBS(HOME(7)) + "TaskPane\PaneCache"

	CurrentPane      = .NULL.
	oPaneCollection  = .NULL.

	LastPaneID       = ''	
	DefaultPaneID    = ''
	
	RefreshFreq      = REFRESHFREQ_TASKLOAD
	
	ProxyOption   = PROXY_NONE
	ProxyServer   = ''
	ProxyPort     = 0
	ProxyUser     = ''
	ProxyPassword = ''
	
	ConnectTimeout = 0

	* used to keep track of our environment
	cTalk           = ''
	nLangOpt        = 0
	cEscapeState    = ''
	cSYS3054        = ''
	cSaveUDFParms   = ''
	cSaveLib        = ''
	cExclusive      = ''
	cCompatible     = ''

	oResource       = .NULL.
	
	lInitError      = .F.
	lNoSaveCache    = .F.

	* [lNoOpen] = TRUE to not try to open the files on Init, because we may need to create them yet
	PROCEDURE Init(lNoOpen)
		LOCAL nSelect
		
		THIS.cTalk = SET("TALK")
		SET TALK OFF
		SET DELETED ON
		SET CENTURY ON	
	
		THIS.cCompatible = SET("COMPATIBLE")		
		SET COMPATIBLE OFF
		
		THIS.cExclusive = SET("EXCLUSIVE")
		SET EXCLUSIVE OFF

		THIS.nLangOpt = _VFP.LanguageOptions
		_VFP.LanguageOptions=0

		THIS.cEscapeState = SET("ESCAPE")
		SET ESCAPE OFF

		THIS.cSYS3054 = SYS(3054)
		SYS(3054,0)

		THIS.cSaveLib      = SET("LIBRARY")

		THIS.cSaveUDFParms = SET("UDFPARMS")
		SET UDFPARMS TO VALUE

		SET EXACT OFF

		THIS.oPaneCollection = CREATEOBJECT("Collection")

		THIS.RestorePrefs()


		IF EMPTY(THIS.PaneDir)
			THIS.PaneDir = FULLPATH(THIS.PaneDir)
		ENDIF

		IF m.lNoOpen
			THIS.lNoSaveCache = .T.
		ELSE
			THIS.lInitError = !THIS.LoadPanes()
		ENDIF

	ENDPROC
	
	
	FUNCTION HandleAction(cAction, oParameters, oBrowser)
		IF TYPE("THIS.CurrentPane") == 'O' AND !ISNULL(THIS.CurrentPane)
			THIS.CurrentPane.HandleAction(m.cAction, m.oParameters, m.oBrowser)
		ENDIF
	ENDFUNC


	* Return the default directory for creating the TaskPane
	* folder beneath.  Used when locating/creating the TaskPane
	* working folder, and when we restore to default.
	FUNCTION GetHomeDir()
		LOCAL cDir

		m.cDir = ADDBS(JUSTPATH(THIS.PaneDir))
		IF !DIRECTORY(m.cDir, 1)
			m.cDir = HOME(7)
			IF !DIRECTORY(m.cDir, 1)
				IF !DIRECTORY(m.cDir, 1)
					m.cDir = HOME()
				ENDIF
			ENDIF
		ENDIF

		RETURN ADDBS(m.cDir)
	ENDFUNC

	* create a backup of the TaskPane and PaneContent tables
	FUNCTION BackupTables()
		LOCAL oException
		LOCAL cTable
		LOCAL cHomeDir
		LOCAL nSelect
		LOCAL lSuccess

		m.nSelect = SELECT()

		m.cHomeDir = THIS.GetHomeDir()
		m.lSuccess = .F.
		TRY
			IF ADDBS(UPPER(FULLPATH(THIS.PaneDir))) == ADDBS(UPPER(m.cHomeDir + "TaskPane"))
				m.lSuccess = .T.
				IF THIS.OpenTable(THIS.PaneTable, "TaskPane")
					SELECT TaskPane
					COPY TO (ADDBS(THIS.PaneDir) + JUSTSTEM(THIS.PaneTable) + "Backup.dbf") WITH PRODUCTION
				ELSE
					m.lSuccess = .F.
				ENDIF

				IF THIS.OpenTable(THIS.PaneContentTable, "PaneContent")
					SELECT PaneContent
					COPY TO (ADDBS(THIS.PaneDir) + JUSTSTEM(THIS.PaneContentTable) + "Backup.dbf") WITH PRODUCTION
				ELSE
					m.lSuccess = .F.
				ENDIF
			ENDIF
		CATCH TO oException
		ENDTRY
		
		SELECT (m.nSelect)
		
		RETURN m.lSuccess
	ENDFUNC


	* -- Cleanup tables used by Task Pane Manager (pack)
	* -- First creates a backup
	FUNCTION Cleanup()
		LOCAL nSelect
		LOCAL lSuccess
		LOCAL cBackupTable
		LOCAL oException
		LOCAL cSafety
		LOCAL cBackupTable
		
		
		m.nSelect = SELECT()
		
		m.lSuccess = .T.
		IF THIS.BackupTables() OR MESSAGEBOX(ERROR_NOBACKUP_LOC, MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2, APPNAME_LOC) == IDYES
			IF USED("TaskPane")
				USE IN TaskPane
			ENDIF
			IF USED("PaneContent")
				USE IN PaneContent
			ENDIF

			m.cBackupTable = ADDBS(THIS.PaneDir) + SYS(2015)
			m.cSafety = SET("SAFETY")
			SET SAFETY OFF

			TRY
				USE (ADDBS(THIS.PaneDir) + THIS.PaneTable) ALIAS TaskPane IN 0 EXCLUSIVE
				USE (ADDBS(THIS.PaneDir) + THIS.PaneContentTable) ALIAS PaneContent IN 0 EXCLUSIVE

				SELECT TaskPane
				COPY TO (m.cBackupTable)
				ZAP IN TaskPane
				APPEND FROM (m.cBackupTable)

				SELECT PaneContent
				COPY TO (m.cBackupTable)
				ZAP IN PaneContent
				APPEND FROM (m.cBackupTable)
				
			CATCH TO oException
				m.lSuccess = .F.
				MESSAGEBOX(ERROR_CLEANUP_LOC + CHR(10) + CHR(10) + m.oException.Message, MB_ICONEXCLAMATION, APPNAME_LOC)
			FINALLY
				IF USED("TaskPane")
					USE IN TaskPane
				ENDIF
				IF USED("PaneContent")
					USE IN PaneContent
				ENDIF
			ENDTRY
			
			ERASE (m.cBackupTable + ".dbf")
			ERASE (m.cBackupTable + ".fpt")

			SET SAFETY &cSafety
		ELSE
			m.lSuccess = .F.
		ENDIF


		IF m.lSuccess
			THIS.LoadPanes()
		ENDIF

		SELECT (m.nSelect)
		
		RETURN m.lSuccess
	ENDFUNC


	FUNCTION RestoreToDefault()
		LOCAL oException
		LOCAL cOldPaneDir
		LOCAL cOldCacheHomeDir
		LOCAL cTable
		LOCAL cHomeDir
		LOCAL lSuccess

		m.cOldPaneDir      = THIS.PaneDir
		m.cOldHomeCacheDir = THIS.CacheHomeDir

		m.cHomeDir = THIS.GetHomeDir()

		m.lSuccess = .F.

		IF THIS.BackupTables() OR MESSAGEBOX(ERROR_NOBACKUP_LOC, MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2, APPNAME_LOC) == IDYES
			IF USED("TaskPane")
				USE IN TaskPane
			ENDIF
			IF USED("PaneContent")
				USE IN PaneContent
			ENDIF


			THIS.PaneDir          = m.cHomeDir + "TaskPane"
			THIS.CacheHomeDir     = m.cHomeDir + "TaskPane\PaneCache"

			TRY			
				m.cTable = ADDBS(THIS.PaneDir) + JUSTSTEM(THIS.PaneTable)
				ERASE (m.cTable + ".dbf")
				ERASE (m.cTable + ".fpt")
				ERASE (m.cTable + ".cdx")

				m.cTable = ADDBS(THIS.PaneDir) + JUSTSTEM(THIS.PaneContentTable)
				ERASE (m.cTable + ".dbf")
				ERASE (m.cTable + ".fpt")
				ERASE (m.cTable + ".cdx")

				m.lSuccess = .T.
			CATCH TO oException
				MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, APPNAME_LOC)
			ENDTRY
			IF !THIS.LoadPanes()
				THIS.PaneDir          = m.cOldPaneDir
				THIS.CacheHomeDir     = m.cOldCacheHomeDir
			ENDIF
		ENDIF
		
		RETURN m.lSuccess
	ENDFUNC
	
	* Save all Pane and Content options back to
	* the appropriate tables
	FUNCTION SaveOptions()
		LOCAL oPane
		LOCAL i

		* save the options
		IF THIS.OpenTable(THIS.PaneContentTable, "PaneContent")
			FOR i = 1 TO THIS.oPaneCollection.Count
				oPane = THIS.oPaneCollection.Item(i)
				THIS.SaveContentOptions(oPane.oContentCollection)
			ENDFOR
			
			USE IN PaneContent
		ENDIF
	ENDFUNC

	FUNCTION SaveContentOptions(oContentCollection)
		LOCAL oContent
		LOCAL cOptionData
		LOCAL oOption

		FOR EACH oContent IN oContentCollection
			IF SEEK(oContent.UniqueID, "PaneContent", "UniqueID")
				cOptionData = ''
				FOR EACH oOption IN oContent.oOptionCollection
					cOptionData = cOptionData + IIF(EMPTY(cOptionData), '', CHR(13) + CHR(10)) + oOption.OptionName + '=' + oOption.OptionValue
				ENDFOR

				* if the options changed, then clear out the cache
				IF !(PaneContent.OptionData == m.cOptionData)
					REPLACE CacheTime WITH {} IN PaneContent
				ENDIF

				REPLACE ;
				  RefrshFreq WITH oContent.RefreshFreq, ;
				  Inactive WITH oContent.Inactive, ;
				  OptionData WITH cOptionData, ;
				  Modified WITH DATETIME() ;
				 IN PaneContent
			ENDIF

			THIS.SaveContentOptions(oContent.oContentCollection)
		ENDFOR
	ENDFUNC


	* restore the original pane tables to default
	FUNCTION CreateContent(lRestoreToDefault)
		LOCAL nSelect
		LOCAL lSuccess
		LOCAL oException
		LOCAL cSafety
		LOCAL lNoBackup
		
		
		m.nSelect = SELECT()
	
		m.lSuccess = .F.

		m.cSafety = SET("SAFETY")
		SET SAFETY OFF
		
		m.lNoBackup = .F.
		IF m.lRestoreToDefault
			TRY
				SELECT TaskPane
				COPY TO (ADDBS(THIS.PaneDir) + JUSTSTEM(THIS.PaneTable) + "Backup.dbf") WITH PRODUCTION

				SELECT PaneContent
				COPY TO (ADDBS(THIS.PaneDir) + JUSTSTEM(THIS.PaneContentTable) + "Backup.dbf") WITH PRODUCTION
			CATCH
				m.lNoBackup = .T.
			ENDTRY
		ENDIF

		IF !m.lRestoreToDefault OR !m.lNoBackup OR MESSAGEBOX(ERROR_NOBACKUP_LOC, MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2, APPNAME_LOC) == IDYES
			TRY
				IF USED("TaskPane")
					USE IN TaskPane
				ENDIF
				IF USED("PaneContent")
					USE IN PaneContent
				ENDIF

				USE TaskPaneDefault IN 0 SHARED AGAIN
				SELECT TaskPaneDefault
				COPY TO (ADDBS(THIS.PaneDir) + THIS.PaneTable) WITH PRODUCTION

				SELECT PaneContentDefault
				COPY TO (ADDBS(THIS.PaneDir) + THIS.PaneContentDefault) WITH PRODUCTION
				m.lSuccess = .T.

			CATCH TO oException
				IF m.lRestoreToDefault
					MESSAGEBOX(ERROR_RESTORETODEFAULT_LOC + CHR(10) + CHR(10) + m.oException.Message, MB_ICONEXCLAMATION, APPNAME_LOC)
				ELSE
					MESSAGEBOX(ERROR_CREATETABLES_LOC + CHR(10) + CHR(10) + m.oException.Message, MB_ICONEXCLAMATION, APPNAME_LOC)
				ENDIF
			ENDTRY

			IF USED("TaskPaneDefault")
				USE IN TaskPaneDefault
			ENDIF
			IF USED("PaneContentDefault")
				USE IN PaneContentDefault
			ENDIF
		ENDIF

		SET SAFETY &cSafety

		m.lSuccess = THIS.LoadPanes()

		SELECT (m.nSelect)
		
		RETURN m.lSuccess
	ENDFUNC



	FUNCTION SavePrefs()
		LOCAL oResource

		m.oResource = NEWOBJECT("FoxResource", "FoxResource.prg")

		m.oResource.Load("TASKPANE")
		m.oResource.Set("PaneDir", THIS.PaneDir)
		m.oResource.Set("CacheHomeDir", THIS.CacheHomeDir)


		m.oResource.Set("DefaultPaneID", THIS.DefaultPaneID)
		IF TYPE("THIS.CurrentPane") == 'O' AND !ISNULL(THIS.CurrentPane)
			m.oResource.Set("LastPaneID", THIS.CurrentPane.UniqueID)
		ELSE
			m.oResource.Set("LastPaneID", '')
		ENDIF
		m.oResource.Set("RefreshFreq", THIS.RefreshFreq)

		* Proxy options
		m.oResource.Set("ProxyOption", THIS.ProxyOption)
		m.oResource.Set("ProxyServer", THIS.ProxyServer)
		m.oResource.Set("ProxyPort", THIS.ProxyPort)
		m.oResource.Set("ProxyUser", THIS.ProxyUser)
		m.oResource.Set("ProxyPassword", THIS.ProxyPassword)

		m.oResource.Set("ConnectTimeout", THIS.ConnectTimeout)


		m.oResource.Save("TASKPANE")
	
		m.oResource = .NULL.
	ENDFUNC

	
	FUNCTION RestorePrefs()
		LOCAL oResource
		LOCAL cValue
		LOCAL nValue
		LOCAL lValue
		
		m.oResource = NEWOBJECT("FoxResource", "FoxResource.prg")
		m.oResource.Load("TASKPANE")
		
		* THIS.PaneTable        = NVL(m.oResource.Get("PaneTable"), '')
		* THIS.PaneContentTable = NVL(m.oResource.Get("PaneContentTable"), '')
		m.cValue = m.oResource.Get("PaneDir")
		IF VARTYPE(m.cValue) == 'C' AND !EMPTY(m.cValue)
			THIS.PaneDir = m.cValue
		ENDIF

		m.cValue = m.oResource.Get("CacheHomeDir")
		IF VARTYPE(m.cValue) == 'C' AND !EMPTY(m.cValue)
			THIS.CacheHomeDir = m.cValue
		ENDIF


		m.cValue = m.oResource.Get("DefaultPaneID")
		IF VARTYPE(m.cValue) == 'C' AND !EMPTY(m.cValue)
			THIS.DefaultPaneID = m.cValue
		ENDIF

		m.cValue = m.oResource.Get("LastPaneID")
		IF VARTYPE(m.cValue) == 'C' AND !EMPTY(m.cValue)
			THIS.LastPaneID = m.cValue
		ENDIF

		m.nValue = m.oResource.Get("RefreshFreq")
		IF VARTYPE(m.nValue) == 'N'
			THIS.RefreshFreq = m.nValue
		ENDIF

		* Proxy options
		m.nValue = m.oResource.Get("ProxyOption")
		IF VARTYPE(m.nValue) == 'N'
			THIS.ProxyOption = MAX(MIN(m.nValue, 3), 1)
		ENDIF
		m.cValue = m.oResource.Get("ProxyServer")
		IF VARTYPE(m.cValue) == 'C'
			THIS.ProxyServer = m.cValue
		ENDIF
		m.nValue = m.oResource.Get("ProxyPort")
		IF VARTYPE(m.nValue) == 'N'
			THIS.ProxyPort = m.nValue
		ENDIF
		m.cValue = m.oResource.Get("ProxyUser")
		IF VARTYPE(m.cValue) == 'C'
			THIS.ProxyUser= m.cValue
		ENDIF
		m.cValue = m.oResource.Get("ProxyPassword")
		IF VARTYPE(m.cValue) == 'C'
			THIS.ProxyPassword = m.cValue
		ENDIF


		m.nValue = m.oResource.Get("ConnectTimeout")
		IF VARTYPE(m.nValue) == 'N'
			THIS.ConnectTimeout = m.nValue
		ENDIF

		m.oResource = .NULL.
	ENDFUNC


	FUNCTION GetCurrentPaneID()
		IF ISNULL(THIS.CurrentPane)
			RETURN ''
		ELSE
			RETURN THIS.CurrentPane.UniqueID
		ENDIF
	ENDFUNC

	* return all panes as a collection object
	FUNCTION LoadPanes()
		LOCAL nSelect
		LOCAL lSuccess
		LOCAL oPaneContent
		LOCAL oPane
		LOCAL cPaneID
		LOCAL oException
		LOCAL i
		LOCAL nCnt
		LOCAL cFolder
		LOCAL cGotoPaneID
		LOCAL ARRAY aContentList[1]
		
		m.nSelect = SELECT()

		* loop until we find a valid TaskPane folder or they Cancel out of the Locate dialog
		m.lSuccess = THIS.CreateWorkingFolders()
		DO WHILE !m.lSuccess
			DO FORM FoxPaneLocate WITH THIS TO m.cFolder
			IF EMPTY(m.cFolder)
				RETURN .F.
			ELSE
				m.lSuccess = THIS.CreateWorkingFolders(m.cFolder, ADDBS(m.cFolder) + "PaneCache")
			ENDIF
		ENDDO

		

		IF TYPE("THIS.CurrentPane") == 'O' AND !ISNULL(THIS.CurrentPane)
			m.cPaneID = THIS.CurrentPane.UniqueID
		ELSE
			m.cPaneID = ''
		ENDIF

		THIS.oPaneCollection.Remove(-1)
		THIS.CurrentPane = .NULL.


		m.lSuccess = THIS.OpenTable(THIS.PaneTable, "TaskPane")
		IF m.lSuccess
			m.lSuccess = THIS.OpenTable(THIS.PaneContentTable, "PaneContent")
			IF !m.lSuccess
				MESSAGEBOX(ERROR_OPENCONTENT_LOC, MB_ICONEXCLAMATION, APPNAME_LOC)
			ENDIF
		ELSE
			MESSAGEBOX(ERROR_OPENTASKPANE_LOC, MB_ICONEXCLAMATION, APPNAME_LOC)
		ENDIF

		IF m.lSuccess
			THIS.CreateFiles(THIS.CacheHomeDir)

			SELECT TaskPane
			SET ORDER TO DisplayOrd
			SCAN ALL FOR !Inactive
				oPane = CREATEOBJECT("Pane")

				oPane.PaneType      = TaskPane.PaneType
				oPane.UniqueID      = TaskPane.UniqueID
				oPane.TaskPane	    = STRTRAN(RTRIM(TaskPane.TaskPane), "\<", '')
				oPane.DisplayAs     = RTRIM(TaskPane.TaskPane)
				oPane.PaneImage     = TaskPane.PaneImage
				oPane.PaneClassLib  = TaskPane.ClassLib
				oPane.PaneClassName = TaskPane.ClassName
				oPane.RefreshFreq   = THIS.RefreshFreq
				oPane.User          = TaskPane.User
				oPane.Inactive      = TaskPane.Inactive
				oPane.DebugMode     = TaskPane.DebugMode
				oPane.ToolboxID     = TaskPane.ToolboxID
				oPane.Handler       = TaskPane.Handler
				oPane.OptionsClassName = ''
				oPane.OptionsClassLib  = ''

				oPane.ProxyOption    = THIS.ProxyOption
				oPane.ProxyServer    = THIS.ProxyServer
				oPane.ProxyPort      = THIS.ProxyPort
				oPane.ProxyUser      = THIS.ProxyUser
				oPane.ProxyPassword  = THIS.ProxyPassword
				oPane.ConnectTimeout = THIS.ConnectTimeout
			
				
				IF !EMPTY(TaskPane.OptionPage)
					IF '!' $ TaskPane.OptionPage
						oPane.OptionsClassName = SUBSTRC(TaskPane.OptionPage, AT_C('!', TaskPane.OptionPage) + 1)
						oPane.OptionsClassLib  = LEFTC(TaskPane.OptionPage, AT_C('!', TaskPane.OptionPage) - 1)
					ELSE
						oPane.OptionsClassName = ALLTRIM(TaskPane.OptionPage)
						oPane.OptionsClassLib  = "foxpaneoptions.vcx"
					ENDIF
					IF EMPTY(JUSTEXT(oPane.OptionsClassLib))
						oPane.OptionsClassLib = FORCEEXT(oPane.OptionsClassLib, "vcx")
					ENDIF
				ENDIF

				IF !DIRECTORY(THIS.CacheHomeDir, 1)
					TRY
						MD (THIS.CacheHomeDir)
					CATCH TO oException
						MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, APPNAME_LOC)
					ENDTRY
				ENDIF
					
				IF DIRECTORY(THIS.CacheHomeDir, 1)
					oPane.CacheHomeDir  = ADDBS(THIS.CacheHomeDir)
					oPane.CacheDir      = ADDBS(ADDBS(THIS.CacheHomeDir) + RTRIM(oPane.UniqueID))
					IF !DIRECTORY(oPane.CacheDir, 1)
						TRY
							MD (oPane.CacheDir)
						CATCH TO oException
							MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, APPNAME_LOC)
						ENDTRY
					ENDIF
				ENDIF

				THIS.CreateFiles(oPane.CacheDir, TaskPane.UniqueID)

				
				* load the content for the pane
				SELECT ;
				  PaneContent.UniqueID ;
				 FROM PaneContent ;
				 WHERE ;
				  PaneContent.InfoType == INFOTYPE_CONTENT AND ;
				  PaneContent.TaskPaneID == m.oPane.UniqueID AND ;
				  EMPTY(PaneContent.ParentID) AND ;
				  !PaneContent.Inactive ;
				 ORDER BY PaneContent.DisplayOrd ;
				 INTO ARRAY aContentList
				m.nCnt = _TALLY
				FOR m.i = 1 TO m.nCnt
					IF !oPane.AddContent(aContentList[m.i, 1])
						* To-Do: error message goes here
					ENDIF
				ENDFOR
				
				TRY
					THIS.oPaneCollection.Add(oPane, RTRIM(oPane.UniqueID))
				CATCH
				ENDTRY
			ENDSCAN


			IF !EMPTY(m.cPaneID)
				THIS.CurrentPane = THIS.GetPane(m.cPaneID)
			ENDIF

			
			IF ISNULL(THIS.CurrentPane)
				IF EMPTY(THIS.DefaultPaneID)
					m.cGotoPaneID = THIS.LastPaneID
				ELSE
					m.cGotoPaneID = THIS.DefaultPaneID
				ENDIF
				
				* don't allow startup to community pane due to bug
				IF !WEXIST("Command") AND ALLTRIM(m.cGotoPaneID) == "microsoft.community"
					m.cGotoPaneID = "microsoft.start"
				ENDIF
				THIS.CurrentPane = THIS.GetPane(m.cGotoPaneID)
			ENDIF

			IF ISNULL(THIS.CurrentPane) AND THIS.oPaneCollection.Count > 0
				THIS.CurrentPane = THIS.oPaneCollection.Item(1)
			ENDIF

		ELSE
			* To-Do: error message goes here
		ENDIF

		SELECT (m.nSelect)
		
		RETURN m.lSuccess
	ENDFUNC


	FUNCTION OpenTable(cTableName, cAlias, lSecondTry)
		LOCAL oException
		LOCAL cDir
		LOCAL nCnt
		LOCAL cFullTable
		LOCAL cHomeDir
		LOCAL ARRAY aFileExists[1]
		
		m.oException = .NULL.

		m.cDir = JUSTPATH(m.cTableName)
		IF EMPTY(m.cDir)
			m.cDir = THIS.PaneDir
			m.cFullTable = FORCEPATH(m.cTableName, m.cDir)
		ENDIF

		IF VARTYPE(m.cAlias) <> 'C' OR EMPTY(m.cAlias)
			m.cAlias = JUSTSTEM(m.cTableName)
		ENDIF
		IF !USED(m.cAlias)
			TRY
				nCnt = ADIR(aFileExists, m.cFullTable)
			CATCH TO oException
				* MESSAGEBOX(ERROR_INVALIDFILE_LOC, MB_ICONEXCLAMATION, APPNAME_LOC)
			ENDTRY

			IF ISNULL(m.oException) AND nCnt == 0
				* try to create the table
				IF FILE(JUSTSTEM(m.cTableName) + "Default.dbf")
					TRY
						IF !DIRECTORY(m.cDir, 1)
							MD (m.cDir)
						ENDIF

						USE (JUSTSTEM(m.cTableName) + "Default") IN 0 SHARED AGAIN ALIAS CopyCursor
						SELECT CopyCursor
						COPY TO (m.cFullTable) WITH PRODUCTION
					CATCH TO oException
					ENDTRY
				ENDIF
			ENDIF
			IF USED("CopyCursor")
				USE IN CopyCursor
			ENDIF
			
			IF ISNULL(oException)
				TRY
					USE (m.cFullTable) ALIAS (m.cAlias) IN 0 SHARED AGAIN
				CATCH TO oException
				ENDTRY
			ENDIF
		ENDIF
		
		IF VARTYPE(oException) == 'O' AND oException.ErrorNo <> 3 && 3 = file is in use
			IF !m.lSecondTry
				IF MESSAGEBOX(ERROR_OPENTABLE_LOC + CHR(10) + CHR(10) + oException.Message + CHR(10) + CHR(10) + ERROR_RESTORE_LOC, MB_ICONEXCLAMATION + MB_YESNO, APPNAME_LOC) == IDYES
					IF DIRECTORY(HOME(7), 1)
						m.cHomeDir = ADDBS(HOME(7))
					ELSE
						m.cHomeDir = ADDBS(HOME())
					ENDIF

					THIS.PaneDir          = m.cHomeDir + "TaskPane"
					THIS.CacheHomeDir     = m.cHomeDir + "TaskPane\PaneCache"

					IF THIS.OpenTable(m.cTableName, m.cAlias, .T.)
						m.oException = .NULL.
					ENDIF
				ENDIF
			ENDIF
		ENDIF

		RETURN ISNULL(m.oException)
	ENDFUNC

	* Create the TASKPANE folder beneath the specified 
	* Parent Folder, and copy the TaskPane and PaneContent
	* tables into this directory.  Also create the 
	* PaneCache folder
	FUNCTION CreateWorkingFolders(m.cPaneDir, m.cCacheHomeDir)
		LOCAL oException
		LOCAL lSuccess
		LOCAL lCacheSuccess
		LOCAL nSelect
		LOCAL cErrorMsg


		m.nSelect = SELECT()

		m.lSuccess      = .T.
		m.lCacheSuccess = .T.
		m.cErrorMsg     = ''

		IF VARTYPE(m.cPaneDir) <> 'C' OR EMPTY(m.cPaneDir)
			m.cPaneDir = THIS.PaneDir
		ENDIF
		IF VARTYPE(m.cCacheHomeDir) <> 'C' OR EMPTY(m.cCacheHomeDir)
			m.cCacheHomeDir = THIS.CacheHomeDir
		ENDIF

		IF DIRECTORY(JUSTPATH(m.cPaneDir)) && make sure our parent directory exists
		
			* create the TaskPane directory
			IF !DIRECTORY(m.cPaneDir, 1)
				TRY
					MD (m.cPaneDir)
				CATCH TO oException
					m.cErrorMsg = oException.Message
					m.lSuccess = .F.
				ENDTRY
			ENDIF
			

			IF m.lSuccess
				* create the PaneCache directory
				IF !DIRECTORY(m.cCacheHomeDir, 1)
					TRY
						MD (m.cCacheHomeDir)
					CATCH TO oException
						m.lCacheSuccess = .F.
					ENDTRY
					
					* if we couldn't create it in the original specified location, then try
					* to create it beneath the TaskPane folder
					IF !m.lCacheSuccess AND !(UPPER(JUSTPATH(m.cCacheHomeDir)) == UPPER(JUSTPATH(m.cPaneDir)))
						m.cCacheHomeDir = ADDBS(m.cPaneDir) + "PaneCache"

						IF !DIRECTORY(m.cCacheHomeDir, 1)
							TRY
								MD (m.cCacheHomeDir)
							CATCH TO oException
								m.cErrorMsg = oException.Message
								m.lSuccess = .F.
							ENDTRY
						ENDIF
					ENDIF
				ENDIF
			ENDIF
		ELSE
			m.lSuccess = .F.
		ENDIF		
		
		IF m.lSuccess
			THIS.PaneDir = m.cPaneDir
			THIS.CacheHomeDir = m.cCacheHomeDir
		ENDIF
		
		SELECT (m.nSelect)

		RETURN m.lSuccess
	ENDFUNC


	FUNCTION SetPane(cPaneID)
		LOCAL oPane

		IF VARTYPE(m.cPaneID) <> 'C' OR EMPTY(m.cPaneID)
			m.oPane = THIS.CurrentPane
		ELSE		
			m.oPane = THIS.GetPane(m.cPaneID)
		ENDIF
		
		IF !ISNULL(m.oPane)
			THIS.CurrentPane = m.oPane
			
			IF !EMPTY(m.oPane.ToolboxID)
				THIS.ShowToolbox(m.oPane.ToolboxID)
			ENDIF
		ENDIF

		RETURN THIS.CurrentPane
	ENDFUNC


	* return a pane by its UniqueID
	FUNCTION GetPane(cPaneID)
		LOCAL oPane

		TRY
			oPane = THIS.oPaneCollection.Item(RTRIM(m.cPaneID))
		CATCH
			oPane = .NULL.
		ENDTRY
		
		RETURN oPane
	ENDFUNC


	FUNCTION SaveCache(oContentCollection)
		FOR EACH oContent IN oContentCollection
			IF !oContent.LocalData
				IF SEEK(oContent.UniqueID, "PaneContent", "UniqueID")
					IF oContent.CacheUpdated
						REPLACE CacheTime WITH oContent.CacheTime IN PaneContent
					ENDIF
				ENDIF
			ENDIF
			THIS.SaveCache(oContent.oContentCollection)
		ENDFOR
	ENDFUNC

	FUNCTION SavePaneCache()
		LOCAL oPane
		LOCAL i

		IF !THIS.lNoSaveCache AND TYPE("THIS.oPaneCollection") == 'O' AND !ISNULL(THIS.oPaneCollection)
			* save cache entries and options
			IF THIS.OpenTable(THIS.PaneContentTable, "PaneContent")
				FOR m.i = 1 TO THIS.oPaneCollection.Count
					oPane = THIS.oPaneCollection.Item(m.i)
					THIS.SaveCache(oPane.oContentCollection)
				ENDFOR
				
				USE IN PaneContent
			ENDIF
		ENDIF
	ENDFUNC

	FUNCTION ShowToolbox(cUniqueID)
		IF VARTYPE(m.cUniqueID) <> 'C'
			m.cUniqueID = ''
		ENDIF
		
		IF FILE(_Toolbox)
			DO (_Toolbox) WITH m.cUniqueID
		ENDIF
	ENDFUNC

	* create all files that apply to all panes in the Cache home directory
	FUNCTION CreateFiles(cCacheDir, cTaskPaneID)
		LOCAL nSelect
		LOCAL oException
		LOCAL cFilename
		LOCAL lUpdateFile
		LOCAL nCnt
		LOCAL ARRAY aFileList[1]
		
		m.nSelect = SELECT()

		IF !DIRECTORY(m.cCacheDir, 1)
			TRY
				MD (m.cCacheDir)
			CATCH
			ENDTRY
		ENDIF

		IF VARTYPE(m.cTaskPaneID) <> 'C'
			m.cTaskPaneID = REPLICATE(' ', LENC(PaneContent.TaskPaneID))
		ENDIF

		IF DIRECTORY(m.cCacheDir, 1)
			SELECT PaneContent
			SCAN ALL FOR TaskPaneID == m.cTaskPaneID AND InfoType == INFOTYPE_FILE AND !EMPTY(FileData) AND !Inactive
				m.cFilename = ADDBS(m.cCacheDir) + RTRIM(PaneContent.Content)

				* see if it's been updated
				m.lUpdateFile = .T.
				IF !EMPTY(PaneContent.CacheTime) AND ADIR(aFileList, m.cFilename) > 0 AND FDATE(m.cFilename, 1) >= PaneContent.CacheTime
					m.lUpdateFile = .F.
				ENDIF
					
				IF m.lUpdateFile
					TRY
						COPY MEMO FileData TO (m.cFilename)
						REPLACE CacheTime WITH FDATE(m.cFilename, 1) IN PaneContent
					CATCH TO oException
					ENDTRY
				ENDIF
			ENDSCAN
		ENDIF
		
		SELECT (m.nSelect)
	ENDFUNC



	* Returns TRUE if user currently has an internet connection
	FUNCTION Offline()
		LOCAL nFlags AS Long
		LOCAL lOffline
		
		DECLARE SHORT InternetGetConnectedState IN wininet ;
			INTEGER @ lpdwFlags,; 
			INTEGER   dwReserved 

		m.nFlags = 0
		m.lOffLine = !InternetGetConnectedState(@m.nFlags, 0) <> 0

		CLEAR DLLS "InternetGetConnectedState"

		RETURN m.lOffline
	ENDFUNC

	* Given a collection of Task Pane UniqueID's, 
	* update the display order in the same
	* order they were put into the collection
	FUNCTION SaveDisplayOrd(oDisplayCollection)
		LOCAL i
		LOCAL cUniqueID
		
		IF THIS.OpenTable(THIS.PaneTable, "TaskPane")
			FOR m.i = 1 TO m.oDisplayCollection.Count
				m.cUniqueID = m.oDisplayCollection.Item(m.i)
				IF SEEK(m.cUniqueID, "TaskPane", "UniqueID")
					REPLACE DisplayOrd WITH m.i, Modified WITH DATETIME() IN TaskPane
				ENDIF
			ENDFOR
			
			USE IN TaskPane
		ENDIF
		
	ENDFUNC


	* return the executing .APP name
	FUNCTION GetAppName()
		IF EMPTY(_TASKPANE)
			RETURN HOME() + "TASKPANE.APP"
		ELSE
			RETURN _TASKPANE
		ENDIF
	ENDFUNC

	FUNCTION GetStartupApp()
		LOCAL oFoxReg
		LOCAL cOptionValue
		
		m.cOptionValue = ''
		TRY
			m.oFoxReg = NEWOBJECT("foxreg", "registry.vcx")
			m.oFoxReg.GetFoxOption("_STARTUP", @cOptionValue)
		CATCH
		FINALLY
			m.oFoxReg = .NULL.
		ENDTRY

		
		IF VARTYPE(m.cOptionValue) <> 'C'
			m.cOptionValue = ''
		ENDIF

		IF LEFTC(m.cOptionValue, 1) == ["] AND RIGHTC(m.cOptionValue, 1) == ["]
			m.cOptionValue = SUBSTRC(m.cOptionValue, 2, LENC(m.cOptionValue) - 2)
		ENDIF

		RETURN m.cOptionValue
	ENDFUNC
	
	FUNCTION SetStartupSetting(lStartup)
		LOCAL cAppName
		LOCAL cStartupApp
		LOCAL lUpdateReg
		
		m.lUpdateReg = .T.
		m.cAppName = THIS.GetAppName()
		m.cStartupApp = UPPER(THIS.GetStartupApp())

		IF m.lStartup
			IF !EMPTY(m.cAppName)
				TRY
					IF !EMPTY(m.cStartupApp) AND !(UPPER(m.cStartupApp) == UPPER(m.cAppName))
						IF MESSAGEBOX(STARTUP_MSG1_LOC + CHR(10) + CHR(10) + ;
						 m.cStartupApp + CHR(10) + CHR(10) + ;
						 STARTUP_MSG2_LOC, MB_ICONQUESTION + MB_YESNO) == IDNO
							m.lUpdateReg = .F.
						ENDIF
					ENDIF
				CATCH TO oException
					MESSAGEBOX(oException.Message, MB_ICONSTOP, APPNAME_LOC)
				ENDTRY
			ELSE
				m.lUpdateReg = .F.
			ENDIF
		ELSE
			IF !EMPTY(m.cStartupApp) AND !(UPPER(m.cStartupApp) == UPPER(m.cAppName))
				m.lUpdateReg = .F.
			ENDIF
			m.cAppName = ''
		ENDIF
		
		IF m.lUpdateReg
			TRY
				m.oFoxReg = NEWOBJECT("foxreg", "registry.vcx")
				m.oFoxReg.SetFoxOption("_STARTUP", ["] + m.cAppName + ["])
			CATCH
			FINALLY
				m.oFoxReg = .NULL.
			ENDTRY
		ENDIF
	ENDFUNC

	* Because some of the data fields in PaneContent
	* can contain XML, we encode our XML so it doesn't
	* get confused with the manifest XML.
	FUNCTION PublishEncode(cData)
		RETURN STRTRAN(STRTRAN(m.cData, "<", PUBLISH_ENCODE_START + "<" + PUBLISH_ENCODE_END), ">", PUBLISH_ENCODE_START + ">" + PUBLISH_ENCODE_END)
	ENDFUNC
	FUNCTION PublishDecode(cData)
		RETURN STRTRAN(STRTRAN(m.cData, PUBLISH_ENCODE_START + "<" + PUBLISH_ENCODE_END, '<'), PUBLISH_ENCODE_START + ">" + PUBLISH_ENCODE_END, '>')
	ENDFUNC

	* Create a manifest file for a pane or selected content within a pane
	* <cUniqueID> = UniqueID of Task Pane to publish
	* [oContentCollection] = collection of PaneContent uniqueID's to publish, or NULL to publish all
	* [lPaneFiles]      = TRUE to publish pane file data
	* [lCommonFiles]    = TRUE to publish common file data
	FUNCTION Publish(cUniqueID, oContentCollection, lPaneFiles, lCommonFiles)
		LOCAL nSelect
		LOCAL lSuccess
		LOCAL nSelect
		LOCAL oXMLAdapter AS XMLAdapter
		LOCAL cXML
		LOCAL cContentUniqueID
		LOCAL cFilename
		LOCAL oException
		LOCAL cWhere
		
		m.nSelect = SELECT()

		m.lSuccess = THIS.OpenTable(THIS.PaneTable, "TaskPane")
		IF m.lSuccess
			m.lSuccess = THIS.OpenTable(THIS.PaneContentTable, "PaneContent")
		ENDIF

		IF m.lSuccess AND SEEK(m.cUniqueID, "TaskPane", "UniqueID")
			m.cFilename = PUTFILE('', CHRTRANC(STRTRAN(ALLTRIM(TaskPane.TaskPane), "\<", ''), ' ', '_') + ".xml", "xml")
			IF !EMPTY(m.cFilename)
				CREATE CURSOR InstallDef (Version N(3,0), UpdateAll L, Created T)
				APPEND BLANK IN InstallDef
				REPLACE ;
				  Version WITH PUBLISH_VERSION, ;
				  Created WITH DATETIME() ;
				 IN InstallDef

			
				IF USED("PublishCursor")
					USE IN PublishCursor
				ENDIF
				CREATE CURSOR PublishCursor ( ;
				  UniqueID C(25) ;
				 )

				SELECT ;
				  UniqueID, ;
				  VendorName, ;
				  PaneType, ;
				  TaskPane, ;
				  PaneImage, ;
				  ClassLib, ;
				  ClassName, ;
				  OptionPage, ;
				  HelpFile, ;
				  Handler, ;
				  User ;
				 FROM TaskPane ;
				 WHERE ;
				  UniqueID == m.cUniqueID ;
				 INTO CURSOR TaskPaneUpdate NOFILTER

				IF TYPE("oContentCollection") == 'O' AND !ISNULL(oContentCollection)
					REPLACE UpdateAll WITH .F. IN InstallDef
					FOR EACH cContentUniqueID IN oContentCollection
						INSERT INTO PublishCursor (UniqueID) VALUES (m.cContentUniqueID)
					ENDFOR
				ELSE
					REPLACE UpdateAll WITH .T. IN InstallDef
				 
					SELECT PaneContent
					SCAN ALL FOR TaskPaneID == m.cUniqueID
						INSERT INTO PublishCursor (UniqueID) VALUES (PaneContent.UniqueID)
					ENDSCAN
				ENDIF

				IF m.lPaneFiles
					m.cWhere = "(UniqueID IN (SELECT UniqueID FROM PublishCursor) AND TaskPaneID == m.cUniqueID)"
				ELSE
					m.cWhere = "(UniqueID IN (SELECT UniqueID FROM PublishCursor) AND TaskPaneID == m.cUniqueID AND InfoType == '" + INFOTYPE_CONTENT + "')"
				ENDIF
				IF m.lCommonFiles
					m.cWhere = m.cWhere + " OR (EMPTY(TaskPaneID) AND EMPTY(ParentID) AND InfoType == '" + INFOTYPE_FILE + "')"
				ENDIF
				
				SELECT ;
				  UniqueID, ;
				  InfoType, ;
				  TaskPaneID, ;
				  ParentID, ;
				  Content, ;
				  RenderType, ;
				  DataSrc, ;
				  Data, ;
				  XFormType, ;
				  XFormSrc, ;
				  XFormData, ;
				  DisplayOrd, ;
				  LocalData, ;
				  Options, ;
				  OptionPage, ;
				  RefrshFreq, ;
				  Handler, ;
				  HelpURL, ;
				  HelpFile, ;
				  FileData, ;
				  User ;
				 FROM PaneContent ;
				 WHERE ;
				  &cWhere ;
				 INTO CURSOR PaneContentUpdate READWRITE
				 
				SELECT PaneContentUpdate
				REPLACE ALL ;
				  Data WITH THIS.PublishEncode(Data), ;
				  XFormData WITH THIS.PublishEncode(XFormData), ;
				  FileData WITH THIS.PublishEncode(FileData) ;
				 IN PaneContentUpdate

				IF USED("PublishCursor")
					USE IN PublishCursor
				ENDIF

				m.cXML = ''
				TRY
					oXMLAdapter = CREATEOBJECT("XMLAdapter")
					WITH oXMLAdapter
						.ForceCloseTag = .T.
						.AddTableSchema("InstallDef", .T.,,,, .T., .T.)
						.AddTableSchema("TaskPaneUpdate", .T.,,,, .T., .T.)
						.AddTableSchema("PaneContentUpdate", .T.,,,, .T., .T.)
						
						.ToXML("cXML", "", .F.)

						STRTOFILE(m.cXML, m.cFilename, 0)
					ENDWITH
					m.lSuccess = .T.

				CATCH TO oException
					MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, APPNAME_LOC)
				ENDTRY
				
				IF USED("TaskPaneUpdate")
					USE IN TaskPaneUpdate
				ENDIF
				IF USED("PaneContentUpdate")
					USE IN PaneContentUpdate
				ENDIF
				IF USED("InstallDef")
					USE IN InstallDef
				ENDIF
			ENDIF
		ENDIF
		SELECT (m.nSelect)
		
		RETURN m.lSuccess
	ENDFUNC

	* install a published pane
	FUNCTION InstallPane(cFilename)
		LOCAL oXMLAdapter AS XMLAdapter
		LOCAL cXML
		LOCAL oTable
		LOCAL oRec
		LOCAL lSuccess
		LOCAL nDisplayOrd
		LOCAL cUniqueID
		LOCAL cErrorMsg
		LOCAL ARRAY aMaxDisplayOrd[1]

		m.lSuccess	 = .F.
		m.cUniqueID  = ''
		m.cErrorMsg  = ''

		TRY
			oXMLAdapter = CREATEOBJECT("XMLAdapter")
			WITH oXMLAdapter
				IF .LoadXML(m.cFilename, .T., .T.)
					FOR EACH oTable IN .Tables
						IF INLIST(UPPER(oTable.Alias), "INSTALLDEF", "TASKPANEUPDATE", "PANECONTENTUPDATE")
							oTable.ToCursor(.F.)
						ENDIF
					ENDFOR
				ENDIF
			ENDWITH
		CATCH
			m.cErrorMsg = INSTALL_BADFILE_LOC
		ENDTRY
			
		IF ;
		 THIS.IsValidInstallDefFile("InstallDef") AND ;
		 THIS.IsValidTaskPaneFile("TaskPaneUpdate") AND ;
		 THIS.IsValidContentFile("PaneContentUpdate")
			IF InstallDef.Version == PUBLISH_VERSION && make sure the install file matches version of our Task Pane Manager
				IF THIS.OpenTable(THIS.PaneTable, "TaskPane") AND THIS.OpenTable(THIS.PaneContentTable, "PaneContent")
					* because the fields that could contain XML data
					* are encoded, we need to decode here
					REPLACE ALL ;
					  Data WITH THIS.PublishDecode(Data), ;
					  XFormData WITH THIS.PublishDecode(XFormData), ;
					  FileData WITH THIS.PublishDecode(FileData) ;
					 IN PaneContentUpdate

					m.nDisplayOrd = 0
					IF InstallDef.UpdateAll
						SELECT TaskPane
						LOCATE FOR UniqueID == TaskPaneUpdate.UniqueID
						IF FOUND()
							m.nDisplayOrd = TaskPane.DisplayOrd
						ENDIF
					
						* clear out the old before bringing in the new
						SELECT TaskPaneUpdate
						SCAN ALL FOR !EMPTY(UniqueID)
							DELETE ALL FOR UniqueID == TaskPaneUpdate.UniqueID IN TaskPane
							DELETE ALL FOR TaskPaneID == TaskPaneUpdate.UniqueID IN PaneContent
						ENDSCAN
					ENDIF
					
					IF m.nDisplayOrd == 0
						SELECT MAX(DisplayOrd) ;
						 FROM TaskPane ;
						 INTO ARRAY aMaxDisplayOrd
						IF _TALLY > 0 AND !ISNULL(aMaxDisplayOrd[1])
							m.nDisplayOrd = aMaxDisplayOrd[1] + 1
						ELSE
							m.nDisplayOrd = 1
						ENDIF
					ENDIF
	
					SELECT TaskPaneUpdate
					SCAN ALL FOR !EMPTY(UniqueID)
						IF EMPTY(m.cUniqueID)
							m.cUniqueID = TaskPaneUpdate.UniqueID
						ENDIF

						SELECT TaskPaneUpdate
						SCATTER MEMO NAME oRec
						
						SELECT TaskPane
						LOCATE FOR UniqueID == TaskPaneUpdate.UniqueID
						IF FOUND()
							IF InstallDef.UpdateAll
								GATHER MEMO NAME oRec
							ENDIF
						ELSE
							INSERT INTO TaskPane FROM NAME oRec
							REPLACE DisplayOrd WITH m.nDisplayOrd IN TaskPane
						ENDIF
					ENDSCAN

					SELECT PaneContentUpdate
					SCAN ALL FOR !EMPTY(UniqueID)
						SELECT PaneContentUpdate
						SCATTER MEMO NAME oRec

						SELECT PaneContent
						LOCATE FOR UniqueID == PaneContentUpdate.UniqueID AND TaskPaneID == PaneContentUpdate.TaskPaneID
						IF FOUND()
							GATHER MEMO NAME oRec
							REPLACE CacheTime WITH {} IN PaneContent
						ELSE
							IF oRec.DisplayOrd == 0
								SELECT MAX(DisplayOrd) ;
								 FROM PaneContent ;
								 WHERE TaskPaneID == PaneContentUpdate.TaskPaneID ;
								 INTO ARRAY aMaxDisplayOrd
								IF _TALLY > 0 AND !ISNULL(aMaxDisplayOrd[1])
									oRec.DisplayOrd = aMaxDisplayOrd[1] + 1
								ELSE
									oRec.DisplayOrd = 1
								ENDIF
							ELSE
								SELECT PaneContent
								REPLACE ALL DisplayOrd WITH DisplayOrd + 1 ;
								 FOR TaskPaneID == PaneContentUpdate.TaskPaneID AND ;
								  InfoType == INFOTYPE_CONTENT AND ;
								  DisplayOrd >= oRec.DisplayOrd ;
								 IN PaneContent
							ENDIF

							INSERT INTO PaneContent FROM NAME oRec
						ENDIF
					ENDSCAN

					m.lSuccess = .T.
				ELSE
					* error - unable to oepn
					m.cErrorMsg = INSTALL_UNABLETOOPEN_LOC
				ENDIF
			ELSE
				* error - wrong version
				m.cErrorMsg = INSTALL_BADVERSION_LOC
			ENDIF
		ELSE
			* error - bad install file
			m.cErrorMsg = INSTALL_BADFILE_LOC
		ENDIF

		* close the cursors we're not using anymore
		IF USED("TaskPaneUpdate")
			USE IN TaskPaneUpdate
		ENDIF
		IF USED("PaneContentUpdate")
			USE IN PaneContentUpdate
		ENDIF
		IF USED("InstallDef")
			USE IN InstallDef
		ENDIF
		
		IF m.lSuccess
			THIS.LoadPanes()
			THIS.SetPane(m.cUniqueID)
		ELSE
			IF !EMPTY(m.cErrorMsg)
				MESSAGEBOX(m.cErrorMsg, MB_ICONEXCLAMATION, APPNAME_LOC)
			ENDIF
		ENDIF
		
		RETURN m.lSuccess
	ENDFUNC


	* returns TRUE if the Task Pane file from an installable pane is valid
	FUNCTION IsValidInstallDefFile(cAlias)
		LOCAL nSelect
		LOCAL lIsValid

		IF USED(m.cAlias)
			m.nSelect = SELECT()

			SELECT (m.cAlias)
			m.lIsValid = ;
			  TYPE("Version") == 'N' AND ;
			  TYPE("UpdateAll") == 'L' AND ;
			  TYPE("Created") == 'T' AND ;
			  RECCOUNT() > 0

			SELECT (m.nSelect)
		ELSE
			m.lIsValid = .F.
		ENDIF


		RETURN m.lIsValid
	ENDFUNC

	* returns TRUE if the Task Pane file from an installable pane is valid
	FUNCTION IsValidTaskPaneFile(cAlias)
		LOCAL nSelect
		LOCAL lIsValid


		IF USED(m.cAlias)
			m.nSelect = SELECT()
			SELECT (m.cAlias)

			m.lIsValid = ;
			  TYPE("UniqueID") == 'C' AND ;
			  TYPE("VendorName") == 'C' AND ;
			  TYPE("PaneType") == 'C' AND ;
			  TYPE("TaskPane") == 'C' AND ;
			  TYPE("PaneImage") == 'M' AND ;
			  TYPE("ClassLib") == 'M' AND ;
			  TYPE("ClassName") == 'M' AND ;
			  TYPE("OptionPage") == 'M' AND ;
			  TYPE("HelpFile") == 'M' AND ;
			  TYPE("Handler") == 'M' AND ;
			  TYPE("User") == 'M' AND ;
			  !EMPTY(UniqueID) AND ;
			  !EMPTY(VendorName) AND ;
			  !EMPTY(TaskPane) AND ;
			  INLIST(PaneType, PANETYPE_XML, PANETYPE_HTML, PANETYPE_FOX, PANETYPE_WEBPAGE)

			SELECT (m.nSelect)
		ELSE
			m.lIsValid = .F.
		ENDIF


		RETURN m.lIsValid
	ENDFUNC

	* returns TRUE if the content file from an installable pane is valid
	FUNCTION IsValidContentFile(cAlias)
		LOCAL nSelect
		LOCAL lIsValid

		IF USED(m.cAlias)
			m.nSelect = SELECT()
			SELECT (m.cAlias)

			m.lIsValid = ;
			  TYPE("UniqueID") == 'C' AND ;
			  TYPE("InfoType") == 'C' AND ;
			  TYPE("TaskPaneID") == 'C' AND ;
			  TYPE("ParentID") == 'C' AND ;
			  TYPE("Content") == 'C' AND ;
			  TYPE("RenderType") == 'C' AND ;
			  TYPE("DataSrc") == 'C' AND ;
			  TYPE("Data") == 'M' AND ;
			  TYPE("XFormType") == 'C' AND ;
			  TYPE("XFormSrc") == 'C' AND ;
			  TYPE("XFormData") == 'M' AND ;
			  TYPE("DisplayOrd") == 'N' AND ;
			  TYPE("LocalData") == 'L' AND ;
			  TYPE("Options") == 'M' AND ;
			  TYPE("OptionPage") == 'M' AND ;
			  TYPE("RefrshFreq") == 'N' AND ;
			  TYPE("Handler") == 'M' AND ;
			  TYPE("HelpURL") == 'M' AND ;
			  TYPE("HelpFile") == 'M' AND ;
			  TYPE("FileData") == 'M' AND ;
			  TYPE("User") == 'M' AND ;
			  !EMPTY(UniqueID) AND ;
			  !EMPTY(TaskPaneID) AND ;
			  !EMPTY(Content) AND ;
			  INLIST(RenderType, RENDERTYPE_XML, RENDERTYPE_HTML, RENDERTYPE_FOX, RENDERTYPE_WEBPAGE, RENDERTYPE_NONE) AND ;
			  INLIST(InfoType, INFOTYPE_CONTENT, INFOTYPE_FILE) AND ;
			  INLIST(DataSrc, SRC_MEMO, SRC_FILE, SRC_URL, SRC_SCRIPT, SRC_WEBSERVICE, SRC_XML, SRC_NONE, '') AND ;
			  INLIST(XFormSrc, SRC_MEMO, SRC_FILE, SRC_URL, SRC_SCRIPT, SRC_WEBSERVICE, SRC_XML, SRC_NONE, '') AND ;
			  INLIST(XFormType, XFORM_TYPE_XSL, XFORM_TYPE_SCRIPT, XFORM_TYPE_NONE, '')

			SELECT (m.nSelect)
		ELSE
			m.lIsValid = .F.
		ENDIF
				  


		RETURN m.lIsValid
	ENDFUNC

	FUNCTION Destroy()
		LOCAL cCompatible

		IF !THIS.lInitError
			THIS.SavePaneCache()
		ENDIF

		IF THIS.cEscapeState = "ON"
			SET ESCAPE ON		
		ENDIF
		IF THIS.cTalk = "ON"
			SET TALK ON	
		ENDIF
		IF THIS.cExclusive = "ON"
			SET EXCLUSIVE ON
		ENDIF
		SYS(3054,INT(VAL(THIS.cSYS3054)))

		_VFP.LanguageOptions = THIS.nLangOpt

		IF THIS.cSaveUDFParms = "REFERENCE"
			SET UDFPARMS TO REFERENCE
		ENDIF
		
		m.cCompatible = THIS.cCompatible
		SET COMPATIBLE &cCompatible
	ENDFUNC

ENDDEFINE


DEFINE CLASS Pane AS Custom
	Name          = "Pane"

	UniqueID      = ''
	VendorName    = ''
	PaneType      = ''
	TaskPane      = ''
	DisplayAs     = ''
	PaneImage     = ''
	PaneClassLib  = ''
	PaneClassName = ''
	XSLSrc        = ''
	XSLData       = ''
	XMLSRC        = ''
	XMLData       = ''
	CSSSrc        = ''
	CSSData       = ''
	Handler       = ''
	User          = ''
	Inactive      = .F.
	Modified      = DATETIME()

	LocalDataOnly = .T.  && True if pane is made up of all Local Data
	DebugMode     = .F.
	ToolboxID     = ''

	CacheHomeDir  = ''
	CacheDir      = ''
	RefreshFreq   = REFRESHFREQ_PANELOAD

	ForceRefresh  = .F.  && set to true to force a refresh the next time rendered regardless of cache settings

	* Web Services proxy info
	ProxyOption    = PROXY_NONE
	ProxyServer    = ''
	ProxyPort      = 0
	ProxyUser      = ''
	ProxyPassword  = ''
	ConnectTimeout = 0

	* page class used to display options for this pane
	OptionsClassLib  = ''
	OptionsClassName = ''

	oContentCollection = .NULL.
	oErrorCollection   = .NULL.

	oParameters = .NULL.
	Action = ''

	

	PROCEDURE Init()
		LOCAL oContent

		THIS.oContentCollection = CREATEOBJECT("Collection")
		THIS.oParameters        = CREATEOBJECT("ParameterCollection")
		THIS.oErrorCollection   = CREATEOBJECT("Collection")
	ENDPROC
	
	FUNCTION PaneImage_Access()
		LOCAL cPaneImage

		IF EMPTY(THIS.PaneImage)
			* if no pane image is specified in TaskPane table, then
			* use "default.bmp" in the Pane's cache folder if it exists
			m.cPaneImage = THIS.CacheDir + "default.bmp"
		ELSE
			m.cPaneImage = ALLTRIM(THIS.PaneImage)
			* if the filename is surrounded by parens, then evaluate it as an expression
			IF LEFTC(m.cPaneImage, 1) == '(' AND RIGHTC(m.cPaneImage, 1) == ')'
				TRY
					m.cPaneImage = EVALUATE(m.cPaneImage)
				CATCH
					m.cPaneImage = ''
				ENDTRY
			ENDIF
			IF EMPTY(JUSTPATH(m.cPaneImage))
				m.cPaneImage = FORCEPATH(m.cPaneImage, THIS.CacheDir)
			ENDIF
		ENDIF

		IF VARTYPE(m.cPaneImage) <> 'C' OR EMPTY(m.cPaneImage) OR !FILE(m.cPaneImage)
			m.cPaneImage = ''
		ENDIF
		
		RETURN m.cPaneImage
	ENDFUNC	


	* write out debug info
	FUNCTION WriteDebugInfo(cText, cFilename)
		IF THIS.DebugMode
			IF ISNULL(m.cText)
				m.cText = "null"
			ENDIF
			STRTOFILE(m.cText, ADDBS(THIS.CacheDir) + "Debug_" + m.cFilename)
		ENDIF
	ENDFUNC

	* Return .T. if content making up the pane
	* comes from an online source
	FUNCTION OnlineData()
		LOCAL i
		LOCAL oContent
		LOCAL lOnlineData
		
		m.lOnlineData = .F.
		FOR m.i = 1 TO THIS.oContentCollection.Count
			oContent = THIS.oContentCollection.Item(m.i)
			m.lOnlineData = oContent.OnlineData(THIS.ForceRefresh)
			IF m.lOnlineData
				EXIT
			ENDIF
		ENDFOR
		
		RETURN m.lOnlineData
	ENDFUNC

	FUNCTION RenderPane(oEngine, cAction AS String, oParameters AS Collection)
		LOCAL oContent
		LOCAL cContent
		LOCAL cFilename
		LOCAL i
		LOCAL oException

		IF VARTYPE(m.cAction) <> 'C'
			m.cAction = ''
		ENDIF
		IF VARTYPE(m.oParameters) <> 'O'
			m.oParameters = CREATEOBJECT("ParameterCollection")
		ENDIF
		THIS.oErrorCollection.Remove(-1)
		
		IF VARTYPE(m.oEngine) <> 'O'
			m.oEngine = .NULL.
		ENDIF


		IF THIS.PaneType == PANETYPE_WEBPAGE
			oContent = THIS.oContentCollection.Item(1)
			IF !m.oContent.Inactive
				m.cContent = NVL(m.oContent.RenderContent(m.oEngine, THIS, m.cAction, m.oParameters, THIS.ForceRefresh), '')
			ENDIF
			RETURN m.cContent
		ENDIF


		* create XML file out of the contents
		* We grab the HTML content from the individual content definition and wrap
		* it into an XML string.  We'll end up with something like this (everything
		* between the <HTMLText> tags is Content specific):
		*
		*	<?xml version="1.0" encoding="UTF-16"?>
		*	<VFPData>
		*		<PaneContent>
		*			<Title>Sample Title</Title>
		*			<HTMLText>
		*				<TABLE>
		*					<TR></TD>sample HTML content</TD></TR>
		*				</TABLE>
		*			</HTMLText>
		*		</PaneContent>
		*	</VFPData>
		m.cContent = ''
		FOR m.i = 1 TO THIS.oContentCollection.Count
			oContent = THIS.oContentCollection.Item(m.i)
			IF !m.oContent.Inactive
				BINDEVENT(m.oContent, "OnShowProgress", THIS, "OnShowProgress")
				m.cContent = m.cContent + NVL(m.oContent.RenderContent(m.oEngine, THIS, m.cAction, m.oParameters, THIS.ForceRefresh), '')
				UNBINDEVENTS(m.oContent)
			ENDIF
		ENDFOR
		
		DO CASE
		CASE THIS.PaneType == PANETYPE_HTML
			m.cFilename = THIS.CacheDir + "pane.htm"

		CASE THIS.PaneType == PANETYPE_XML
			m.cFilename = THIS.CacheDir + "pane.xml"

		OTHERWISE
			m.cFilename = ''
		ENDCASE

		IF !EMPTY(m.cFilename)
			TRY
				STRTOFILE(m.cContent, m.cFilename)
			CATCH TO oException
				MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, APPNAME_LOC)
			ENDTRY
		ENDIF

		RETURN m.cFilename
	ENDFUNC


	* -- Add content record to the pane
	FUNCTION AddContent(cUniqueID, oParent)
		LOCAL oContent
		LOCAL nCnt
		LOCAL i
		LOCAL nPos
		LOCAL i
		LOCAL nCnt
		LOCAL oPaneContentRec
		LOCAL nSelect
		LOCAL ARRAY aContentList[1]

		m.nSelect = SELECT()

		IF VARTYPE(oParent) <> 'O'
			oParent = THIS
		ENDIF


		m.oContent = .NULL.
		IF SEEK(m.cUniqueID, "PaneContent", "UniqueID")
			SELECT PaneContent
			SCATTER MEMO NAME oPaneContentRec

			oContent = NEWOBJECT("Content", "FoxPaneContent.prg")
			IF !ISNULL(oContent)
				oContent.CacheDir     = THIS.CacheDir
				oContent.UniqueID     = oPaneContentRec.UniqueID
				oContent.InfoType     = oPaneContentRec.InfoType
				oContent.TaskPaneID   = oPaneContentRec.TaskPaneID
				oContent.ContentTitle = RTRIM(oPaneContentRec.Content)
				oContent.ParentID     = oPaneContentRec.ParentID && IIF(EMPTY(oPaneContentRec.ParentID), oPaneContentRec.UniqueID, oPaneContentRec.ParentID)
				* oContent.RenderType   = oPaneContentRec.RenderType
				oContent.PaneType     = oParent.PaneType
				oContent.DataSrc      = oPaneContentRec.DataSrc
				oContent.Data         = oPaneContentRec.Data
				oContent.XFormType    = oPaneContentRec.XFormType
				oContent.XFormSrc     = oPaneContentRec.XFormSrc
				oContent.XFormData    = oPaneContentRec.XFormData
				oContent.LocalData    = oPaneContentRec.LocalData
				oContent.FileData     = oPaneContentRec.FileData
				oContent.DebugMode    = oPaneContentRec.DebugMode
				oContent.Options      = oPaneContentRec.Options
				oContent.OptionData   = oPaneContentRec.OptionData
				oContent.OptionPage   = oPaneContentRec.OptionPage
				oContent.User         = oPaneContentRec.User
				oContent.Inactive     = oPaneContentRec.Inactive
				oContent.RefreshFreq  = oPaneContentRec.RefrshFreq
				oContent.HelpURL      = oPaneContentRec.HelpURL
				oContent.HelpFile     = oPaneContentRec.HelpFile
				oContent.HelpID       = oPaneContentRec.HelpID
				oContent.CacheTime    = IIF(EMPTY(oPaneContentRec.CacheTime), .NULL., oPaneContentRec.CacheTime)
				oContent.Handler      = oPaneContentRec.Handler

				oContent.DefaultRefreshFreq = THIS.RefreshFreq

				oContent.ProxyOption    = THIS.ProxyOption
				oContent.ProxyServer    = THIS.ProxyServer
				oContent.ProxyPort      = THIS.ProxyPort
				oContent.ProxyUser      = THIS.ProxyUser
				oContent.ProxyPassword  = THIS.ProxyPassword
				oContent.ConnectTimeout = THIS.ConnectTimeout

			
				THIS.LocalDataOnly    = THIS.LocalDataOnly AND oPaneContentRec.LocalData

				oParent.oContentCollection.Add(oContent)

				* add in the subcontent
				SELECT ;
				  PaneContent.UniqueID ;
				 FROM PaneContent ;
				 WHERE ;
				   PaneContent.ParentID == m.oContent.UniqueID AND ;
				   PaneContent.InfoType == INFOTYPE_CONTENT ;
				 ORDER BY PaneContent.DisplayOrd ;
				 INTO ARRAY aContentList
				m.nCnt = _TALLY
				FOR m.i = 1 TO m.nCnt
					oParent.AddContent(aContentList[m.i, 1], oContent)
				ENDFOR
			ENDIF
		ENDIF
		
		SELECT (m.nSelect)

		RETURN !ISNULL(oContent)
	ENDFUNC

	* Set the Inactive status for a content provider
	* of this pane
	* <cUniqueID> = content ID to set state for
	* <lInactive> = TRUE if should be Inactive, FALSE otherwise
	FUNCTION SetContentState(cUniqueID, lInactive, oContentCollection)
		LOCAL oContent
		LOCAL i

		IF TYPE("oContentCollection") <> 'O' OR ISNULL(oContentCollection)
			oContentCollection = THIS.oContentCollection
		ENDIF

		FOR m.i = 1 TO m.oContentCollection.Count
			m.oContent = m.oContentCollection.Item(m.i)
			IF m.oContent.UniqueID == m.cUniqueID
				m.oContent.Inactive = m.lInactive
				EXIT
			ENDIF
			THIS.SetContentState(m.cUniqueID, m.lInactive, m.oContent.oContentCollection)
		ENDFOR
	ENDFUNC

	FUNCTION HandleAction(cAction, oParameters, oBrowser)
		LOCAL oException
		LOCAL i
		LOCAL oContent
		LOCAL lHandled
		LOCAL lPaneHandled

		m.lHandled = .F.
		FOR m.i = 1 TO THIS.oContentCollection.Count
			m.oContent = THIS.oContentCollection.Item(m.i)
			m.lHandled = m.oContent.HandleAction(m.cAction, m.oParameters, m.oBrowser) OR m.lHandled
		ENDFOR		

		IF !EMPTY(THIS.Handler)
			TRY
				m.lPaneHandled = EXECSCRIPT(THIS.Handler, cAction, oParameters, m.oBrowser, THIS)
				IF VARTYPE(m.lPaneHandled) <> 'L'
					m.lPaneHandled = .T.
				ENDIF
				m.lHandled = m.lHandled OR m.lPaneHandled
			CATCH TO oException
			ENDTRY
		ENDIF

		RETURN m.lHandled
	ENDFUNC


	FUNCTION LogError(m.cErrorTitle, m.cErrorMsg, m.cOptionMsg, m.cOptionLink)
		LOCAL oErrorMsg

		m.oErrorMsg = CREATEOBJECT("ErrorMsg")
		WITH oErrorMsg
			.ErrorTitle  = m.cErrorTitle

			IF VARTYPE(m.cErrorMsg) == 'C'
				.ErrorMsg = m.cErrorMsg
			ENDIF
			IF VARTYPE(m.cOptionMsg) == 'C'
				.OptionMsg = m.cOptionMsg
			ENDIF
			IF VARTYPE(m.cOptionLink) == 'C'
				.OptionLink = m.cOptionLink
			ENDIF
		ENDWITH
		THIS.oErrorCollection.Add(m.oErrorMsg)
		RELEASE m.oErrorMsg
	ENDFUNC
	

	* we use BINDEVENT() in TaskPane form to bind to this in order to
	* show status messages as content is retrieved
	PROCEDURE OnShowProgress(cMsg)
		*** do not remove!!!
	ENDPROC

ENDDEFINE



* Browser parameter collection
* Used by the PaneBrowser class
DEFINE CLASS ParameterCollection AS Collection
	FUNCTION GetParam(cParamName, xDefault)
		LOCAL xValue
		LOCAL i

		xValue = IIF(PCOUNT() > 1, xDefault, '')

		FOR m.i = 1 TO THIS.Count
			IF UPPER(THIS.GetKey(m.i)) == UPPER(cParamName)
				xValue = THIS.Item(m.i)
				EXIT
			ENDIF
		ENDFOR
		
		IF TYPE("xValue") == 'C' AND !ISNULL(xValue)
			xValue = STRTRAN(xValue, "%20", ' ')
		ENDIF
		
		RETURN xValue
	ENDFUNC
ENDDEFINE

DEFINE CLASS ErrorMsg AS Custom
	ErrorTitle   = ''
	ErrorMsg     = ''
	OptionMsg    = ''
	OptionLink   = ''
ENDDEFINE

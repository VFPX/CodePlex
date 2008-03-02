* Abstract...:
*	Primary class for References application.
*
* Changes....:
*
#ifdef TESTING
* Below is a sample of using the FoxRef
* class programmatically
PUBLIC o AS FoxRef OF foxref.prg

cProject = "foxref"

cPattern   = "oApp"
cFileDir   = "c:\code\visgift"
* cSkeleton  = "*.scx"
cFileTypes = "*.prg *.scx"

o = NEWOBJECT("FoxRef", "foxref.prg")

IF o.SetProject(cProject)
	o.Quiet = .F.
	o.FileTypes = cFileTypes
	o.Search("for")

	o.OverwritePrior = .F.
	o.WildCards = .T.
	o.Search("whil?")
ELSE
	? "Unable to open project"
ENDIF

RETURN
#endif

#include "foxpro.h"
#include "foxref.h"

DEFINE CLASS FoxRef AS Session
	PROTECTED lIgnoreErrors AS Boolean
	PROTECTED lRefreshMode
	PROTECTED cProgressForm
	PROTECTED lCancel
	PROTECTED tTimeStamp
	PROTECTED lIgnoreErrors
	PROTECTED ARRAY aFileTypes[1]
	PROTECTED nFileTypeCnt


	oSearchEngine   = .NULL.

	Comments        = COMMENTS_INCLUDE
	MatchCase       = .T.
	WholeWordsOnly  = .F.

	SubFolders      = .F.
	Wildcards       = .F.
	Quiet           = .F.  && quiet mode -- don't display search progress
	ShowProgress    = .T.  && show a progress form

	FileTypes       = ''
	ReportFile      = REPORT_FILE
	
	* MRU array lists
	DIMENSION aLookForMRU[10]
	DIMENSION aReplaceMRU[10]
	DIMENSION aFolderMRU[10]
	DIMENSION aFileTypesMRU[10]
	aLookForMRU     = ''
	aReplaceMRU     = ''
	aFolderMRU      = ''
	aFileTypesMRU   = ''

	Pattern         = ''
	OverwritePrior  = .T.

	RefTable        = ''
	ProjectFile     = ''
	FileDirectory   = ''
	
	cSetID          = ''
	lRefreshMode    = .F.

	lIgnoreErrors   = .F.
	
	oProgressForm   = .NULL.
	lCancel         = .F.
	tTimeStamp      = .NULL.

	nFileTypeCnt    = 0	
	
	cTalk           = ''
	nLangOpt        = 0
	cMessage        = ''
	cEscapeState    = ''
	cSYS3054        = ''
	cSaveUDFParms   = ''
	cSaveLib        = ''
	cExclusive      = ''

	PROCEDURE Init()
		THIS.cTalk = SET("TALK")
		SET TALK OFF

		SET DELETED ON
		
		THIS.cExclusive = SET("EXCLUSIVE")
		SET EXCLUSIVE OFF

		THIS.cMessage = SET("MESSAGE",1)

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


		THIS.RestorePrefs()

		* Create file type engine objects
		THIS.AddFileType('', FILETYPE_CLASS_DEFAULT, FILETYPE_LIBRARY_DEFAULT)  && default search engine
		THIS.AddFileType("PRG", FILETYPE_CLASS_PRG, FILETYPE_LIBRARY_PRG)  && program
		THIS.AddFileType("H",   FILETYPE_CLASS_H,   FILETYPE_LIBRARY_H)    && header
		THIS.AddFileType("SCX", FILETYPE_CLASS_SCX, FILETYPE_LIBRARY_SCX)  && form
		THIS.AddFileType("VCX", FILETYPE_CLASS_VCX, FILETYPE_LIBRARY_VCX)  && class library
		THIS.AddFileType("DBF", FILETYPE_CLASS_DBF, FILETYPE_LIBRARY_DBF)  && table
		THIS.AddFileType("DBC", FILETYPE_CLASS_DBC, FILETYPE_LIBRARY_DBC)  && database container
		THIS.AddFileType("FRX", FILETYPE_CLASS_FRX, FILETYPE_LIBRARY_FRX)  && report
		THIS.AddFileType("LBX", FILETYPE_CLASS_LBX, FILETYPE_LIBRARY_LBX)  && label
		THIS.AddFileType("MNX", FILETYPE_CLASS_MNX, FILETYPE_LIBRARY_MNX)  && menu
		THIS.AddFileType("SPR", FILETYPE_CLASS_SPR, FILETYPE_LIBRARY_SPR)  && screen
		THIS.AddFileType("QPR", FILETYPE_CLASS_QPR, FILETYPE_LIBRARY_QPR)  && query
		THIS.AddFileType("MPR", FILETYPE_CLASS_MPR, FILETYPE_LIBRARY_MPR)  && menu
	ENDFUNC


	PROCEDURE Destroy()
		THIS.CloseProgress()

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
	ENDFUNC

*!*		PROCEDURE Error(nError, cMethod, nLine)
*!*			IF THIS.lIgnoreErrors
*!*				RETURN
*!*			ENDIF
*!*			DODEFAULT(nError, cMethod, nLine)
*!*		ENDPROC


	* To-Do: change this to a collection
	* Add a filetype search -- This can be a collection in VFP8!!!
	FUNCTION AddFileType(cFileType, cClassName, cClassLibrary)
		LOCAL nIndex
		LOCAL lSuccess

		cFileType = ALLTRIM(UPPER(cFileType))
		IF LEFT(cFileType, 1) == '.'
			cFileType = SUBSTR(cFileType, 2)
		ENDIF

		lSuccess = .F.		
		
		nIndex = 0
		IF VARTYPE(cFileType) <> 'C' OR EMPTY(cFileType)
			cFileType = ''
			nIndex = 1 && default search engine always the first row in the array
		ELSE
			IF THIS.nFileTypeCnt > 0
				nIndex = ASCAN(THIS.aFileTypes, cFileType, -1, -1, 1, 14)  && 14 = return row number, Exact On
			ENDIF
		ENDIF
		IF PCOUNT() == 1
			IF nIndex > 0
				* remove filetype
				=ADEL(THIS.aFileTypes, nIndex, 2)
				THIS.nFileTypeCnt = THIS.nFileTypeCnt - 1
				
				lSuccess = .T.
			ENDIF
		ELSE
			IF VARTYPE(cClassLibrary) <> 'C' OR EMPTY(cClassLibrary)
				cClassLibrary = FILETYPE_LIBRARY
			ENDIF
			oEngine = NEWOBJECT(cClassName, cClassLibrary)
			IF VARTYPE(oEngine) == 'O'
				IF nIndex == 0 OR THIS.nFileTypeCnt == 0
					THIS.nFileTypeCnt = THIS.nFileTypecnt + 1
					nIndex = THIS.nFileTypeCnt
					DIMENSION THIS.aFileTypes[THIS.nFileTypeCnt, 2]
				ENDIF
				THIS.aFileTypes[nIndex, FILETYPE_EXTENSION] = cFileType
				THIS.aFileTypes[nIndex, FILETYPE_ENGINE]    = oEngine
				
				lSuccess = .T.
			ENDIF
		ENDIF

		RETURN lSuccess
	ENDFUNC

	PROCEDURE SearchInit()
		LOCAL i

		IF THIS.Wildcards
			THIS.oSearchEngine = NEWOBJECT("Wildcard", "foxmatch.prg")
		ELSE
			THIS.oSearchEngine = NEWOBJECT("MatchDefault", "foxmatch.prg")
		ENDIF
		THIS.oSearchEngine.MatchCase      = THIS.MatchCase
		THIS.oSearchEngine.WholeWordsOnly = THIS.WholeWordsOnly
		
		FOR i = 1 TO THIS.nFileTypecnt
			WITH THIS.aFileTypes[i, FILETYPE_ENGINE]
				.SetID          = THIS.cSetID
				.oSearchEngine  = THIS.oSearchEngine
				.Pattern        = THIS.Pattern
				.Comments       = THIS.Comments
			ENDWITH
		ENDFOR
	ENDPROC



	* Do a replacement on designated file
	FUNCTION ReplaceFile(cUniqueID, cReplaceText)
		LOCAL nSelect
		LOCAL nFileTypeIndex
		LOCAL cFileType
		LOCAL oFoxRefRecord
		LOCAL lSuccess
		
		lSuccess = .F.
		IF USED("FoxRefCursor") AND VARTYPE(cUniqueID) == 'C' AND !EMPTY(cUniqueID) AND (FoxRefCursor.UniqueID == cUniqueID OR SEEK(cUniqueID, "FoxRefCursor", "UniqueID"))
			nSelect = SELECT()

			cFilename = ADDBS(RTRIM(FoxRefCursor.Folder)) + RTRIM(FoxRefCursor.Filename)
			IF FILE(cFilename)
				cFileType = UPPER(JUSTEXT(cFilename))

				nFileTypeIndex = ASCAN(THIS.aFileTypes, cFileType, -1, -1, 1, 14)  && 14 = return row number, Exact On
				IF nFileTypeIndex == 0
					nFileTypeIndex = 1  && this is the default search/replace engine to use
				ENDIF

				SELECT FoxRefCursor
				SCATTER MEMO NAME oFoxRefRecord
				WITH THIS.aFileTypes[nFileTypeIndex, FILETYPE_ENGINE]
					lSuccess = .ReplaceWith(cReplaceText, oFoxRefRecord)
				ENDWITH
			ENDIF
			
			SELECT (nSelect)
		ENDIF

		RETURN lSuccess
	ENDFUNC
	

	

	PROCEDURE FileTypes_Assign(cFileTypes)
		THIS.FileTypes = CHRTRAN(cFileTypes, ',;', '  ')
	ENDFUNC

	FUNCTION CreateRefTable(cRefTable)
		LOCAL lSuccess
		LOCAL cSafety

		lSuccess = .T.

		THIS.RefTable = ''
		
		cSafety = SET("SAFETY")
		SET SAFETY OFF
		IF USED(JUSTSTEM(cRefTable))
			USE IN (cRefTable)
		ENDIF

		CREATE TABLE (cRefTable) FREE ( ;
	 	  UniqueID C(10), ;
		  SetID C(10), ;
		  RefID C(10), ;
	 	  RefType C(1), ;
	 	  DefType C(1), ;
	 	  Folder C(240), ;
		  Filename C(100), ;
		  Symbol C(254), ;
		  ClassName C(254), ;
		  ProcName C(254), ;
		  ProcLineNo I, ;
		  LineNo I, ;
		  ColPos I, ;
		  MatchLen I, ;
		  RefCode C(254), ;
		  RecordID C(10), ;
		  UpdField C(10), ;
		  Checked L, ;
		  TimeStamp T NULL, ;
		  Inactive L ;
		 )
		INDEX ON RefType TAG RefType
		INDEX ON SetID TAG SetID
		INDEX ON RefID TAG RefID
		INDEX ON UniqueID TAG UniqueID
		INDEX ON Filename TAG Filename
		INDEX ON Checked TAG Checked


		* add the record that holds our results window search position & other options
		INSERT INTO (cRefTable) ( ;
		  UniqueID, ;
		  SetID, ;
		  RefType, ;
		  Folder, ;
		  FileName, ;
		  Symbol, ;
		  ClassName, ;
		  ProcName, ;
		  ProcLineNo, ;
		  LineNo, ;
		  ColPos, ;
		  MatchLen, ;
		  RefCode, ;
		  RecordID, ;
		  UpdField, ;
		  Timestamp, ;
		  Inactive ;
		 ) VALUES ( ;
		  SYS(2015), ;
		  '', ;
		  REFTYPE_INIT, ;
		  THIS.ProjectFile, ;
		  '', ;
		  '', ;
		  '', ;
		  '', ;
		  0, ;
		  0, ;
		  0, ;
		  0, ;
		  '', ;
		  '', ;
		  '', ;
		  DATETIME(), ;
		  .F. ;
		 )
*		  IIF(THIS.ProjectName == PROJECT_GLOBAL, cProjectOrDir, ''), ;
*		  IIF(!(THIS.ProjectName == PROJECT_GLOBAL), cProjectOrDir, ''), ;
*		  IIF(cScope == SCOPE_FOLDER, cProjectOrDir, ''), ;
*		  IIF(cScope <> SCOPE_FOLDER, cProjectOrDir, ''), ;

		THIS.RefTable = cRefTable

		USE IN (JUSTSTEM(cRefTable))

		SET Safety &cSafety

		RETURN lSuccess
	ENDFUNC
	
	* Open a FoxRef table 
	* Return TRUE if table exists and it's in the correct format
	* [lCreate] = True to create table if it doesn't exist
	FUNCTION OpenRefTable(cRefTable)
		LOCAL lSuccess

		IF USED("FoxRefCursor")
			USE IN FoxRefCursor
		ENDIF		
		THIS.RefTable = ''

		lSuccess = .T.

		IF !FILE(FORCEEXT(cRefTable, "DBF"))
			lSuccess = THIS.CreateRefTable(cRefTable)
		ENDIF

		IF lSuccess
			USE (cRefTable) ALIAS FoxRefCursor IN 0 SHARED AGAIN
			IF TYPE("FoxRefCursor.RefType") == 'C'
				THIS.RefTable = cRefTable
			ELSE
				lSuccess = .F.
				MESSAGEBOX(BADTABLE_LOC + CHR(10) + CHR(10) + FORCEEXT(cRefTable, "DBF"), MB_ICONSTOP, APPNAME_LOC)
			ENDIF
		ENDIF
		
		RETURN lSuccess
	ENDFUNC

	* Abstract:
	*   Set a specific project to display result sets for.
	*	Pass an empty string or "global" to display result sets
	*	that are not associated with a project.
	*
	* Parameters:
	*   [cProject]
	FUNCTION SetProject(cProjectFile, lOverwrite)
		LOCAL lInUse
		LOCAL lSuccess
		LOCAL cRefTable
		LOCAL i
		LOCAL lFoundProject
		
		lSuccess = .F.

		IF VARTYPE(cProjectFile) <> 'C' 
			cProjectfile = THIS.ProjectFile
		ENDIF
		IF EMPTY(cProjectFile)
			* use the active project if a project name is not passsed
			IF Application.Projects.Count > 0
				cProjectFile = Application.ActiveProject.Name
			ELSE
				cProjectFile = PROJECT_GLOBAL
			ENDIF
			
			lSuccess = .T.
		ELSE
			* make sure Project specified is open
			IF cProjectFile == PROJECT_GLOBAL
				lSuccess = .T.
			ELSE
				cProjectFile = UPPER(FORCEEXT(FULLPATH(cProjectFile), "PJX"))

				FOR i = 1 TO Application.Projects.Count
					IF UPPER(Application.Projects(i).Name) == cProjectFile
						cProjectFile = Application.Projects(i).Name
						lSuccess = .T.
						EXIT
					ENDIF
				ENDFOR
				IF !lSuccess
					IF FILE(cProjectFile)
						* open the project
						MODIFY PROJECT (cProjectFile) NOWAIT
						
						* search again to find where in the Projects collection it is
						FOR i = 1 TO Application.Projects.Count
							IF UPPER(Application.Projects(i).Name) == cProjectFile
								cProjectFile = Application.Projects(i).Name
								lSuccess = .T.
								EXIT
							ENDIF
						ENDFOR
					ENDIF
				ENDIF
			ENDIF
		ENDIF


		IF lSuccess
			IF EMPTY(cProjectFile) OR cProjectFile == PROJECT_GLOBAL
				THIS.ProjectFile = PROJECT_GLOBAL
				cRefTable        = ADDBS(HOME()) + GLOBAL_TABLE + RESULT_EXT
			ELSE
				THIS.ProjectFile = UPPER(cProjectFile)
				cRefTable        = ADDBS(JUSTPATH(cProjectFile)) + JUSTSTEM(cProjectFile) + RESULT_EXT
			ENDIF

			IF lOverwrite
				lSuccess = THIS.CreateRefTable(cRefTable)
			ELSE
				lSuccess = THIS.OpenRefTable(cRefTable)
			ENDIF
		ENDIF

		RETURN lSuccess
	ENDFUNC


	FUNCTION Search(cPattern)
		IF VARTYPE(cPattern) <> 'C' OR EMPTY(cPattern)
			DO FORM FoxRefFind WITH THIS
		ELSE
			IF THIS.SetProject(, THIS.OverwritePrior)
				IF THIS.ProjectFile == PROJECT_GLOBAL OR EMPTY(THIS.ProjectFile)
					THIS.FolderSearch(cPattern)
				ELSE
					THIS.ProjectSearch(cPattern)
				ENDIF
			ENDIF
		ENDIF
	ENDFUNC


	* Determine if the Reference table we want to open is 
	* actually one of ours.  If we're overwriting or a reference
	* table doesn't exist for this project, then create a new 
	* Reference Table.
	*
	* Once we have a reference table, then we add a new record
	* that represents the search criteria for this particular
	* search.
	FUNCTION UpdateRefTable(cScope, cPattern, cProjectOrDir)
		LOCAL nSelect
		LOCAL cSafety
		LOCAL cSearchOptions
		LOCAL cRefTable
		
		nSelect = SELECT()
		
		IF VARTYPE(cRefTable) <> 'C' OR EMPTY(cRefTable)
			cRefTable = THIS.RefTable
		ENDIF

		IF EMPTY(cRefTable)
			RETURN .F.
		ENDIF

		IF USED("FoxRefCursor")
			USE IN FoxRefCursor
		ENDIF

*!*			IF FILE(FORCEEXT(cRefTable, "DBF"))
*!*				IF !THIS.OpenRefTable(cRefTable)
*!*					RETURN .F.
*!*				ENDIF
*!*			ENDIF

		IF !THIS.OpenRefTable(cRefTable)
			RETURN .F.
		ENDIF

		THIS.tTimeStamp = DATETIME()


		* build a string representing the search options that
		* we can store to the FoxRef cursor
		cSearchOptions = IIF(THIS.Comments == COMMENTS_EXCLUDE, 'X', '') + ;
		                 IIF(THIS.Comments == COMMENTS_ONLY, 'C', '') + ;
		                 IIF(THIS.MatchCase, 'M', '') + ;
		                 IIF(THIS.WholeWordsOnly, 'W', '') + ;
		                 IIF(THIS.SubFolders, 'S', '') + ;
		                 IIF(THIS.Wildcards, 'Z', '') + ;
		                 ';' + THIS.FileTypes
		
		
		* if we've already searched for this same exact symbol
		* with the same exact criteria in the same exact project/folder,
		* then simply update what we have
		SELECT FoxRefCursor
		LOCATE FOR RefType == REFTYPE_SEARCH AND Folder == PADR(cProjectOrDir, LEN(FoxRefCursor.Folder)) AND Symbol == PADR(cPattern + PATTERN_EOL, LEN(FoxRefCursor.Symbol)) AND RefCode == PADR(cSearchOptions, LEN(FoxRefCursor.RefCode))
		THIS.lRefreshMode = FOUND()
		IF THIS.lRefreshMode
			THIS.tTimeStamp = FoxRefCursor.TimeStamp

			THIS.cSetID = FoxRefCursor.SetID
			REPLACE ALL Inactive WITH .T. ;
			  FOR SetID == THIS.cSetID AND (RefType == REFTYPE_RESULT OR RefType == REFTYPE_DEFINITION) ;
			 IN FoxRefCursor
		ELSE
			THIS.cSetID = SYS(2015)
	
			* add the record that specifies the search criteria, etc
			INSERT INTO FoxRefCursor ( ;
			  UniqueID, ;
			  SetID, ;
			  RefType, ;
			  Folder, ;
			  FileName, ;
			  Symbol, ;
			  ClassName, ;
			  ProcName, ;
			  ProcLineNo, ;
			  LineNo, ;
			  ColPos, ;
			  MatchLen, ;
			  RefCode, ;
			  RecordID, ;
			  UpdField, ;
			  Timestamp, ;
			  Inactive ;
			 ) VALUES ( ;
			  SYS(2015), ;
			  THIS.cSetID, ;
			  REFTYPE_SEARCH, ;
			  cProjectOrDir, ;
			  '', ;
			  cPattern + PATTERN_EOL, ;
			  '', ;
			  '', ;
			  0, ;
			  0, ;
			  0, ;
			  0, ;
			  cSearchOptions, ;
			  '', ;
			  '', ;
			  THIS.tTimeStamp, ;
			  .F. ;
			 )
		ENDIF
		
		SELECT (nSelect)
		
		RETURN .T.
	ENDFUNC


	* -- Search a Folder
	FUNCTION FolderSearch(cPattern, cFileDir)
		LOCAL nFileCnt
		LOCAL i, j
		LOCAL cFileDir
		LOCAL nFileTypesCnt
		LOCAL cFileTypes
		LOCAL lAutoYield
		LOCAL ARRAY aFileList[1]
		LOCAL ARRAY aFileTypes[1]

		IF VARTYPE(cPattern) <> 'C'
			cPattern = THIS.Pattern
		ENDIF

		IF VARTYPE(cFileDir) <> 'C' OR EMPTY(cFileDir)
			cFileDir = ADDBS(THIS.FileDirectory)
		ELSE
			cFileDir = ADDBS(cFileDir)
		ENDIF
		
		IF !DIRECTORY(cFileDir)
			RETURN .F.
		ENDIF

		THIS.SetProject(PROJECT_GLOBAL, THIS.OverwritePrior)
		
		IF !THIS.UpdateRefTable(SCOPE_FOLDER, cPattern, cFileDir)
			RETURN .F.
		ENDIF

		THIS.SearchInit()
		
		
		cFileTypes = CHRTRAN(THIS.FileTypes, ',;', '  ')
		nFileTypesCnt = ALINES(aFileTypes, cFileTypes, .T., ' ')

		lAutoYield = _VFP.AutoYield
		_VFP.AutoYield = .T.


		THIS.ProcessFolder(cFileDir, cPattern, @aFileTypes, nFileTypesCnt)

		THIS.CloseProgress()
		
		_VFP.AutoYield = lAutoYield

		THIS.UpdateLookForMRU(cPattern)
		THIS.UpdateFolderMRU(cFileDir)
		THIS.UpdateFileTypesMRU(cFileTypes)
		
		RETURN .T.
	ENDFUNC

	* used in conjuction with FolderSearch() for
	* when we're searching subfolders
	FUNCTION ProcessFolder(cFileDir, cPattern, aFileTypes, nFileTypesCnt)
		LOCAL nFileCnt
		LOCAL nFolderCnt
		LOCAL cFilename
		LOCAL i, j
		LOCAL ARRAY aFileList[1]
		LOCAL ARRAY aFolderList[1]

		cFileDir = ADDBS(cFileDir)
		FOR i = 1 TO nFileTypesCnt
			IF THIS.lCancel
				EXIT
			ENDIF

			nFileCnt = ADIR(aFileList, cFileDir + aFileTypes[i], '', 1)
			FOR j = 1 TO nFileCnt
				IF THIS.lCancel
					EXIT
				ENDIF

				cFilename = aFileList[j, 1]

				THIS.FileSearch(cFileDir + cFilename, cPattern)
			ENDFOR
		ENDFOR
		
		* Process any sub-directories
		IF !THIS.lCancel
			IF THIS.SubFolders
				nFolderCnt = ADIR(aFolderList, cFileDir + "*.*", 'D', 1)
				FOR i = 1 TO nFolderCnt
					IF !aFolderList[i, 1] == '.' AND !aFolderList[i, 1] == '..' AND 'D'$aFolderList[i, 5] AND DIRECTORY(cFileDir + aFolderList[i, 1])
						THIS.ProcessFolder(cFileDir + aFolderList[i, 1], cPattern, @aFileTypes, nFileTypesCnt)
					ENDIF
					IF THIS.lCancel
						EXIT
					ENDIF
				ENDFOR
			ENDIF
		ENDIF
	ENDFUNC

	
	* -- Search files in a Project
	FUNCTION ProjectSearch(cPattern, cProjectFile)
		LOCAL nFileIndex
		LOCAL nProjectIndex
		LOCAL oProjectRef
		LOCAL oFileRef
		LOCAL cFileTypes
		LOCAL nFileTypesCnt
		LOCAL lAutoYield
		LOCAL lSuccess
		LOCAL ARRAY aFileTypes[1]
		LOCAL ARRAY aFileList[1]

		IF VARTYPE(cPattern) <> 'C'
			cPattern = THIS.Pattern
		ENDIF
		
*!*			IF VARTYPE(cProjectFile) == 'C' AND !EMPTY(cProjectFile)
*!*				cProjectFile = UPPER(FORCEEXT(FULLPATH(cProjectFile), "PJX"))
*!*			ELSE
*!*				cProjectFile = ''
*!*			ENDIF

*!*			IF !THIS.SetProject(cProjectFile)
*!*				RETURN .F.
*!*			ENDIF
		IF VARTYPE(cProjectFile) <> 'C' OR EMPTY(cProjectFile)
			cProjectFile = THIS.ProjectFile
		ENDIF
		IF !THIS.SetProject(cProjectFile, THIS.OverwritePrior)
			RETURN .F.
		ENDIF
		

		IF !THIS.UpdateRefTable(SCOPE_PROJECT, cPattern, THIS.ProjectFile)
			RETURN .F.
		ENDIF

		THIS.SearchInit()

		cFileTypes = THIS.FileTypes

		lAutoYield = _VFP.AutoYield
		_VFP.AutoYield = .T.

		FOR EACH oProjectRef IN Application.Projects
			IF UPPER(oProjectRef.Name) == THIS.ProjectFile
				* process each file in the project
				FOR EACH oFileRef IN oProjectRef.Files
					IF THIS.WildCardMatch(cFileTypes, JUSTFNAME(oFileRef.Name))
						THIS.FileSearch(oFileRef.Name, cPattern)
					ENDIF
					IF THIS.lCancel
						EXIT
					ENDIF
				ENDFOR
				
				EXIT
			ENDIF
		ENDFOR
		THIS.CloseProgress()

		_VFP.AutoYield = lAutoYield

		THIS.UpdateLookForMRU(cPattern)
		THIS.UpdateFileTypesMRU(cFileTypes)
				
		RETURN .T.
	ENDFUNC


	* Search a file
	FUNCTION FileSearch(cFilename, cPattern)
		LOCAL cFileType
		LOCAL nSelect
		LOCAL cFileFind
		LOCAL cFolderFind
		LOCAL lSearch
		LOCAL nSelect
		LOCAL nFileTypeIndex
		LOCAL ARRAY aFileList[1]

		THIS.UpdateProgress(cFilename)
		IF THIS.lCancel
			RETURN
		ENDIF

		IF VARTYPE(cPattern) <> 'C'
			cPattern = THIS.Pattern
		ENDIF

		nSelect = SELECT()

		lSearch = .T.

		* determine which search engine to use based upon the filetype
		cFileType = UPPER(JUSTEXT(cFilename))
		nFileTypeIndex = ASCAN(THIS.aFileTypes, cFileType, -1, -1, 1, 14)  && 14 = return row number, Exact On
		IF nFileTypeIndex == 0
			nFileTypeIndex = 1  && this is the default search engine to use
		ENDIF

		WITH THIS.aFileTypes[nFileTypeIndex, FILETYPE_ENGINE]
			.Filename       = cFilename
			* .FileTimeStamp  = THIS.FileTimeStamp
			
	
			* don't try to check the timestamp on a Table (DBF) 
			* because it isn't always updated when we modify
			* certain things (such as values that are really stored in the 
			* database container)
			IF THIS.lRefreshMode AND !.NoRefresh
				* if we're refreshing results, then first see if
				* we've already searched this file and the timestamp
				* hasn't changed at all

				cFileFind   = PADR(JUSTFNAME(cFilename), 100)
				cFolderFind = PADR(JUSTPATH(cFilename), 240)

				SELECT FoxRefCursor
				LOCATE FOR SetID == THIS.cSetID AND (RefType == REFTYPE_RESULT OR RefType == REFTYPE_DEFINITION OR RefType == REFTYPE_NOMATCH) AND FileName == cFileFind AND Folder == cFolderFind
				IF FOUND()
					IF FoxRefCursor.TimeStamp == .FileTimeStamp
						UPDATE FoxRefCursor SET Inactive = .F. WHERE SetID == THIS.cSetID AND (RefType == REFTYPE_RESULT OR RefType == REFTYPE_DEFINITION OR RefType == REFTYPE_NOMATCH) AND FileName == cFileFind AND Folder == cFolderFind
						lSearch = .F.
					ENDIF
				ENDIF
			ENDIF


			IF lSearch
				.SearchFor(cPattern)
			ENDIF
		ENDWITH
		
		
		SELECT (nSelect)

	ENDFUNC
	

	
	* refresh results for all Sets in the Ref table or a single set
	FUNCTION RefreshResults(cSetID)
		LOCAL nSelect
		LOCAL lInUse
		LOCAL i
		LOCAL nCnt
		LOCAL ARRAY aRefList[1]

		nSelect = SELECT()

		IF VARTYPE(cSetID) == 'C' AND !EMPTY(cSetID)
			THIS.RefreshResultSet(cSetID)
		ELSE
			IF FILE(FORCEEXT(THIS.RefTable, "dbf"))
				nSelect = SELECT()

				lInUse = USED("FoxRefCursor")
				IF !lInUse
					USE (THIS.RefTable) ALIAS FoxRefCursor IN 0 SHARED AGAIN
				ENDIF
				
				SELECT SetID ;
				 FROM FoxRefCursor ;
				 WHERE RefType == REFTYPE_SEARCH AND !Inactive ;
				 INTO ARRAY aRefList
				nCnt = _TALLY
*!*					IF !lInUse AND USED("FoxRefCursor")
*!*						USE IN FoxRefCursor
*!*					ENDIF

				FOR i = 1 TO nCnt
					THIS.RefreshResultSet(aRefList[i])
				ENDFOR


				SELECT (nSelect)
			ENDIF
			THIS.cSetID = ''
		ENDIF
	ENDFUNC

	* refresh an existing search set
	FUNCTION RefreshResultSet(cSetID)
		LOCAL lInUse
		LOCAL nSelect
		LOCAL lSuccess
		LOCAL cScope
		LOCAL cFolder
		LOCAL cProject
		LOCAL cPattern
		LOCAL cSearchOptions

		lSuccess = .F.
		IF FILE(FORCEEXT(THIS.RefTable, "dbf"))
			nSelect = SELECT()

			lInUse = USED("FoxRefCursor")
			IF !lInUse
				USE (THIS.RefTable) ALIAS FoxRefCursor IN 0 SHARED AGAIN
			ENDIF
			
			SELECT FoxRefCursor
			LOCATE FOR RefType == REFTYPE_SEARCH AND SetID == cSetID 
			lSuccess = FOUND()
			IF lSuccess
				cSearchOptions = LEFT(FoxRefCursor.RefCode, AT(';', FoxRefCursor.RefCode) - 1)
				IF 'X'$cSearchOptions
					THIS.Comments = COMMENTS_EXCLUDE
				ENDIF
				IF 'C'$cSearchOptions
					THIS.Comments = COMMENTS_ONLY
				ENDIF
				THIS.MatchCase      = 'M' $ cSearchOptions
				THIS.WholeWordsOnly = 'W' $ cSearchOptions
				THIS.SubFolders     = 'S' $ cSearchOptions
				THIS.Wildcards      = 'Z' $ cSearchOptions
				
				THIS.OverwritePrior = .F.

				THIS.FileTypes = ALLTRIM(SUBSTR(FoxRefCursor.RefCode, AT(';', FoxRefCursor.RefCode) + 1))
				cFolder  = RTRIM(FoxRefCursor.Folder)
				cProject = ''

				IF UPPER(JUSTEXT(cFolder)) == "PJX"
					cScope = SCOPE_PROJECT
					cProject = cFolder
				ELSE
					cScope = SCOPE_FOLDER
				ENDIF
				
				IF PATTERN_EOL $ FoxRefCursor.Symbol
					cPattern = LEFT(FoxRefCursor.Symbol, AT(PATTERN_EOL, FoxRefCursor.Symbol) - 1)
				ELSE
					cPattern = RTRIM(FoxRefCursor.Symbol)
				ENDIF
			ENDIF

			IF !lInUse AND USED("FoxRefCursor")
				USE IN FoxRefCursor
			ENDIF


			IF lSuccess
				DO CASE
				CASE cScope == SCOPE_FOLDER
					THIS.FolderSearch(cPattern, cFolder)
				CASE cScope == SCOPE_PROJECT
					THIS.ProjectSearch(cPattern, cProject)
				OTHERWISE
					lSuccess = .F.
				ENDCASE
			ENDIF
			
			SELECT (nSelect)
		ENDIF
		
		RETURN lSuccess
	ENDFUNC

	FUNCTION SetChecked(cUniqueID, lChecked)
		IF PCOUNT() < 2
			lChecked = .T.
		ENDIF
		IF USED("FoxRefCursor") AND SEEK(cUniqueID, "FoxRefCursor", "UniqueID")
			REPLACE Checked WITH lChecked IN FoxRefCursor
		ENDIF
	ENDFUNC


	* -- Show the Results form
	FUNCTION ShowResults()
		LOCAL i

		* first see if there is an open Results window for this
		* project and display that if there is
		FOR i = 1 TO _SCREEN.FormCount
			IF PEMSTATUS(_SCREEN.Forms(i), "oFoxRef", 5) AND ;
			   UPPER(_SCREEN.Forms(i).Name) == "FRMFOXREFRESULTS" AND ;
			   VARTYPE(_SCREEN.Forms(i).oFoxRef) == 'O' AND UPPER(_SCREEN.Forms(i).oFoxRef.ProjectFile) == THIS.ProjectFile
				* _SCREEN.Forms(i).RefreshResults(THIS.cSetID)
				_SCREEN.Forms(i).SetRefTable(THIS.cSetID)
				RETURN
			ENDIF
		ENDFOR
		
		DO FORM FoxRefResults WITH THIS
	ENDFUNC

	* goto a specific reference
	FUNCTION GotoReference(cUniqueID)
		LOCAL nSelect
		LOCAL cFilename
		LOCAL cFileType
		LOCAL cClassName
		LOCAL cProcName

		IF VARTYPE(cUniqueID) <> 'C' OR EMPTY(cUniqueID)
			RETURN .F.
		ENDIF

		IF USED("FoxRefCursor") AND SEEK(cUniqueID, "FoxRefCursor", "UniqueID")
			nSelect = SELECT()
		
			cFilename  = ADDBS(RTRIM(FoxRefCursor.Folder)) + RTRIM(FoxRefCursor.FileName)
			cClassName = RTRIM(FoxRefCursor.ClassName)
			cProcName  = RTRIM(FoxRefCursor.ProcName)
			cFileType  = UPPER(JUSTEXT(cFileName))

			DO CASE
			CASE cFileType == "SCX"
				EDITSOURCE(cFileName, MAX(FoxRefCursor.ProcLineNo, 1), cClassName, cProcName)

			CASE cFileType == "VCX"
				EDITSOURCE(cFileName, MAX(FoxRefCursor.ProcLineNo, 1), cClassName, cProcName)

			CASE cFileType == "DBF"
				* do a TRY/CATCH here
				IF USED(JUSTSTEM(cFilename))
					SELECT (JUSTSTEM(cFilename))
				ELSE
					SELECT 0
					USE (cFilename) EXCLUSIVE
				ENDIF
				MODIFY STRUCTURE

			OTHERWISE
				EDITSOURCE(cFileName, FoxRefCursor.LineNo)
			ENDCASE
			
			SELECT (nSelect)
		ENDIF
	
	ENDFUNC


	* -- goto the definition of a reference
	FUNCTION GotoDefinition(cUniqueID)
		LOCAL nSelect
		LOCAL lSuccess
		LOCAL cFilename
		LOCAL cClassName
		LOCAL cProcName
		LOCAL cSymbol
		LOCAL nCnt

		IF VARTYPE(cUniqueID) <> 'C' OR EMPTY(cUniqueID)
			RETURN .F.
		ENDIF

		lSuccess = .F.
		IF USED("FoxRefCursor") AND SEEK(cUniqueID, "FoxRefCursor", "UniqueID")
			nSelect = SELECT()
		
			cSymbol    = UPPER(FoxRefCursor.Symbol)
			cFolder    = FoxRefCursor.Folder
			cFilename  = FoxRefCursor.FileName
			cClassName = FoxRefCursor.ClassName
			cProcName  = FoxRefCursor.ProcName

			* now find all appropriate definitions
			SELECT ;
			  UniqueID, ;
			  Symbol, ;
			  DefType, ;
			  Filename, ;
			  Folder, ;
			  ClassName, ;
			  ProcName, ;
			  RefCode, ;
			  IIF(Filename == cFilename AND ClassName == cClassName AND ProcName == cProcName, 1, ;
			      IIF(Filename == cFilename AND ClassName == cClassName, 2, ;
			      IIF(Filename == cFilename, 3, ;
			      4))) AS Context ;
			 FROM (THIS.RefTable) ;
			 WHERE ;
			  UPPER(Symbol) == cSymbol AND ;
			  RefType == REFTYPE_DEFINITION AND ;
			  !Inactive ;
			 ORDER BY Context ;
			 INTO CURSOR DefinitionCursor
			nCnt = _TALLY

			DO CASE
			CASE nCnt == 0
				* no matches found
				MESSAGEBOX(NODEFINITION_LOC + CHR(10) + CHR(10) + RTRIM(FoxRefCursor.Symbol), MB_ICONEXCLAMATION, GOTODEFINITION_LOC)
			CASE nCnt == 1
				* only a single match, so go right to it
				THIS.GotoReference(DefinitionCursor.UniqueID)
			OTHERWISE
				* more than one match found, so display a cursor of
				* the available matches.
				DO FORM FoxRefGotoDef WITH THIS, RTRIM(FoxRefCursor.Symbol)
			ENDCASE

			IF USED("DefinitionCursor")
				USE IN DefinitionCursor
			ENDIF
			
			SELECT (nSelect)
		ENDIF
	
		RETURN lSuccess
	ENDFUNC

	* Show a progress form while searching
	FUNCTION UpdateProgress(cMsg)
		IF THIS.ShowProgress
			IF VARTYPE(THIS.oProgressForm) <> 'O'
				THIS.lCancel = .F.
				DO FORM FoxRefProgress NAME THIS.oProgressForm LINKED
			ENDIF
			IF THIS.oProgressForm.SetProgress(cMsg)  && TRUE is returned if Cancel button is pressed
				IF MESSAGEBOX(SEARCH_CANCEL_LOC, MB_ICONQUESTION + MB_YESNO, APPNAME_LOC) == IDYES
					THIS.lCancel = .T.
				ELSE
					THIS.oProgressForm.lCancel = .F.
				ENDIF
			ENDIF
			DOEVENTS
		ENDIF
	ENDFUNC

	FUNCTION CloseProgress()
		IF VARTYPE(THIS.oProgressForm) == 'O'
			THIS.oProgressForm.Release()
		ENDIF
		THIS.lCancel = .F.
	ENDFUNC


	* Export reference table
	FUNCTION ExportReferences(cExportType, cFilename, lSelectedOnly)
		LOCAL nSelect
		LOCAL cFor

		nSelect = SELECT()
		SELECT 0		

		IF VARTYPE(cExportType) <> 'C' OR EMPTY(cExportType)
			cExportType = EXPORTTYPE_DBF
		ENDIF
		IF VARTYPE(lSelectedOnly) <> 'L'
			lSelectedOnly = .F.
		ENDIF
		IF VARTYPE(cFilename) <> 'C'
			RETURN .F.
		ENDIF
		cFilename = FULLPATH(cFilename)
		IF !DIRECTORY(JUSTPATH(cFilename))
			RETURN .F.
		ENDIF


		
		cFor = "RefType == [" + REFTYPE_RESULT + "] AND !Inactive"
		IF lSelectedOnly
			cFor = cFor + " AND Checked"
		ENDIF

		
		DO CASE
		CASE cExportType == EXPORTTYPE_DBF
			USE (THIS.RefTable) ALIAS ExportCursor IN 0 SHARED AGAIN
			SELECT ExportCursor

			COPY TO (cFilename) ;
			 FIELDS ;
			  Symbol, ;
			  Folder, ;
			  Filename, ;
			  ClassName, ;
			  ProcName, ;
			  ProcLineNo, ;
			  LineNo, ;
			  ColPos, ;
			  MatchLen, ;
			  RefCode, ;
			  TimeStamp ;
			 FOR &cFor

		CASE cExportType == EXPORTTYPE_TXT
			USE (THIS.RefTable) ALIAS ExportCursor IN 0 SHARED AGAIN
			SELECT ExportCursor

			COPY TO (cFilename) ;
			 FIELDS ;
			  Symbol, ;
			  Folder, ;
			  Filename, ;
			  ClassName, ;
			  ProcName, ;
			  ProcLineNo, ;
			  LineNo, ;
			  ColPos, ;
			  MatchLen, ;
			  RefCode, ;
			  TimeStamp ;
			 FOR &cFor ;
			 DELIMITED
			
		CASE cExportType == EXPORTTYPE_XML
			IF lSelectedOnly
				SELECT ;
				  Symbol, ;
				  Folder, ;
				  Filename, ;
				  ClassName, ;
				  ProcName, ;
				  ProcLineNo, ;
				  LineNo, ;
				  ColPos, ;
				  MatchLen, ;
				  RefCode, ;
				  TimeStamp ;
				 FROM (THIS.RefTable) ;
				 WHERE ;
				  RefType == REFTYPE_RESULT AND ;
				  Checked AND ;
				  !Inactive ;
				 INTO CURSOR ExportCursor
			ELSE		
				SELECT ;
				  Symbol, ;
				  Folder, ;
				  Filename, ;
				  ClassName, ;
				  ProcName, ;
				  ProcLineNo, ;
				  LineNo, ;
				  ColPos, ;
				  MatchLen, ;
				  RefCode, ;
				  TimeStamp ;
				 FROM (THIS.RefTable) ;
				 WHERE ;
				  RefType == REFTYPE_RESULT AND ;
				  !Inactive ;
				 INTO CURSOR ExportCursor
			ENDIF			 
			
			IF EMPTY(JUSTEXT(cFilename))
				cFilename = FORCEEXT(cFilename, "xml")
			ENDIF

			CURSORTOXML("ExportCursor", cFilename, 1, 514, 0, '1')
		ENDCASE
		
		IF USED("ExportCursor")
			USE IN ExportCursor
		ENDIF
		
		SELECT (nSelect)
		
		RETURN .T.
	ENDFUNC


	* Print a report of found references
	FUNCTION PrintReferences(lPreview, cSetID, lSelectedOnly)
		LOCAL nSelect
		LOCAL cWhere
		LOCAL lSuccess
		LOCAL cRptFile

		nSelect = SELECT()
		SELECT 0
		
		lSuccess = .F.

		IF VARTYPE(lPreview) <> 'L'
			lPreview = .F.
		ENDIF
		IF VARTYPE(lSelectedOnly) <> 'L'
			lSelectedOnly = .F.
		ENDIF
		IF VARTYPE(cSetID) <> 'C'
			cSetID = ''
		ENDIF

		cRptFile = THIS.ReportFile
		IF EMPTY(JUSTEXT(cRptFile))
			cRptFile = FORCEEXT(cRptFile, ".frx")
		ENDIF

		IF FILE(cRptFile)
			cWhere = "RefType == [" + REFTYPE_RESULT + "] AND !Inactive"
			IF !EMPTY(cSetID)
				cWhere = cWhere + " AND SetID == [" + cSetID + "]"
			ENDIF
			IF lSelectedOnly
				cWhere = cWhere + " AND Checked"
			ENDIF

			SELECT ;
			  SetID, ;
			  Symbol, ;
			  Folder, ;
			  Filename, ;
			  ClassName, ;
			  ProcName, ;
			  ProcLineNo, ;
			  LineNo, ;
			  ColPos, ;
			  MatchLen, ;
			  RefCode, ;
			  TimeStamp ;
			 FROM (THIS.RefTable) ;
			 WHERE &cWhere ;
			 INTO CURSOR RptCursor

			IF _TALLY > 0
				IF lPreview
					REPORT FORM (cRptFile) PREVIEW
				ELSE
					REPORT FORM (cRptFile) NOCONSOLE TO PRINTER
				ENDIF
			
				lSuccess = .T.
			ENDIF

			IF USED("RptCursor")
				USE IN RptCursor
			ENDIF
		ENDIF

		SELECT (nSelect)
		
		RETURN lSuccess
	ENDFUNC
	
	* retrieve a preference from the FoxPro Resource file
	FUNCTION RestorePrefs()
		LOCAL nSelect
		LOCAL lSuccess
		LOCAL nMemoWidth

		LOCAL ARRAY FOXREF_LOOKFOR_MRU[10]
		LOCAL ARRAY FOXREF_REPLACE_MRU[10]
		LOCAL ARRAY FOXREF_FOLDER_MRU[10]
		LOCAL ARRAY FOXREF_FILETYPES_MRU[10]

		LOCAL FOXREF_COMMENTS
		LOCAL FOXREF_MATCHCASE
		LOCAL FOXREF_WHOLEWORDSONLY
		LOCAL FOXREF_SUBFOLDERS
		LOCAL FOXREF_OVERWRITE

		nSelect = SELECT()
		
		lSuccess = .F.
		
		IF FILE(SYS(2005))    && resource file not found.
			USE (SYS(2005)) IN 0 SHARED AGAIN ALIAS FoxResource
			IF USED("FoxResource")
				nMemoWidth = SET('MEMOWIDTH')
				SET MEMOWIDTH TO 255

				SELECT FoxResource
				LOCATE FOR UPPER(ALLTRIM(type)) == "PREFW" ;
		   			AND UPPER(ALLTRIM(id)) == RESOURCE_ID ;
		   			AND !DELETED()

				IF FOUND() AND !EMPTY(Data) AND ckval == VAL(SYS(2007, Data)) AND EMPTY(name)
					RESTORE FROM MEMO Data ADDITIVE

					IF TYPE("FOXREF_LOOKFOR_MRU") == 'C'
						=ACOPY(FOXREF_LOOKFOR_MRU, THIS.aLookForMRU)
					ENDIF
					IF TYPE("FOXREF_REPLACE_MRU") == 'C'
						=ACOPY(FOXREF_REPLACE_MRU, THIS.aReplaceMRU)
					ENDIF
					IF TYPE("FOXREF_FOLDER_MRU") == 'C'
						=ACOPY(FOXREF_FOLDER_MRU, THIS.aFolderMRU)
					ENDIF
					IF TYPE("FOXREF_FILETYPES_MRU") == 'C'
						=ACOPY(FOXREF_FILETYPES_MRU, THIS.aFileTypesMRU)
					ENDIF
					
					IF TYPE("FOXREF_COMMENTS") == 'N'
						THIS.Comments = FOXREF_COMMENTS
					ENDIF
					
					IF TYPE("FOXREF_MATCHCASE") == 'L'
						THIS.MatchCase = FOXREF_MATCHCASE
					ENDIF
					IF TYPE("FOXREF_WHOLEWORDSONLY") == 'L'
						THIS.WholeWordsOnly = FOXREF_WHOLEWORDSONLY
					ENDIF
					IF TYPE("FOXREF_SUBFOLDERS") == 'L'
						THIS.SubFolders = FOXREF_SUBFOLDERS
					ENDIF
					IF TYPE("FOXREF_OVERWRITE") == 'L'
						THIS.OverwritePrior = FOXREF_OVERWRITE
					ENDIF

					lSuccess = .T.
				ENDIF
				
				* if no preferences or filetypes are empty,
				* then set a default
				IF EMPTY(THIS.aFileTypesMRU[1])
					THIS.aFileTypesMRU[1] = FILETYPES_DEFAULT
				ENDIF

				SET MEMOWIDTH TO (nMemoWidth)

				USE IN FoxResource
			ENDIF
		ENDIF

		SELECT (nSelect)
		
		RETURN lSuccess
	
	ENDFUNC
	
	* retrieve a preference from the FoxPro Resource file
	FUNCTION SavePrefs()
		LOCAL nSelect
		LOCAL lSuccess
		LOCAL nMemoWidth
		LOCAL nCnt
		LOCAL cData

		LOCAL ARRAY aFileList[1]
		LOCAL ARRAY FOXREF_LOOKFOR_MRU[10]
		LOCAL ARRAY FOXREF_FOLDER_MRU[10]
		LOCAL ARRAY FOXREF_FILETYPES_MRU[10]

		LOCAL FOXREF_COMMENTS
		LOCAL FOXREF_MATCHCASE
		LOCAL FOXREF_WHOLEWORDSONLY
		LOCAL FOXREF_SUBFOLDERS
		LOCAL FOXREF_OVERWRITE

		=ACOPY(THIS.aLookForMRU, FOXREF_LOOKFOR_MRU)
		=ACOPY(THIS.aReplaceMRU, FOXREF_REPLACE_MRU)
		=ACOPY(THIS.aFolderMRU, FOXREF_FOLDER_MRU)
		=ACOPY(THIS.aFileTypesMRU, FOXREF_FILETYPES_MRU)

		FOXREF_COMMENTS       = THIS.Comments
		FOXREF_MATCHCASE      = THIS.MatchCase
		FOXREF_WHOLEWORDSONLY = THIS.WholeWordsOnly
		FOXREF_SUBFOLDERS     = THIS.SubFolders
		FOXREF_OVERWRITE      = THIS.OverwritePrior
		FOXREF_FILETYPES      = THIS.FileTypes

	
		nSelect = SELECT()
		
		lSuccess = .F.

  		* make sure Resource file exists and is not read-only
  		nCnt = ADIR(aFileList, SYS(2005))		
		IF nCnt > 0 AND ATC('R', aFileList[1, 5]) == 0
			USE (SYS(2005)) IN 0 SHARED AGAIN ALIAS FoxResource
			IF USED("FoxResource") AND !ISREADONLY("FoxResource")
				nMemoWidth = SET('MEMOWIDTH')
				SET MEMOWIDTH TO 255

				SELECT FoxResource
				LOCATE FOR UPPER(ALLTRIM(type)) == "PREFW" AND UPPER(ALLTRIM(id)) == RESOURCE_ID AND EMPTY(name)
				IF !FOUND()
					APPEND BLANK IN FoxResource
					REPLACE ; 
					  Type WITH "PREFW", ;
					  ID WITH RESOURCE_ID, ;
					  ReadOnly WITH .F. ;
					 IN FoxResource
				ENDIF

				IF !FoxResource.ReadOnly
					SAVE TO MEMO Data ALL LIKE FOXREF_*

					REPLACE ;
					  Updated WITH DATE(), ;
					  ckval WITH VAL(SYS(2007, FoxResource.Data)) ;
					 IN FoxResource

					lSuccess = .T.
				ENDIF
				SET MEMOWIDTH TO (nMemoWidth)
			
				USE IN FoxResource
			ENDIF
		ENDIF

		SELECT (nSelect)
		
		RETURN lSuccess
	ENDFUNC

	FUNCTION SaveWindowPosition(nTop, nLeft, nHeight, nWidth)
		LOCAL lInUse
		
		IF FILE(FORCEEXT(THIS.RefTable, "DBF"))
			lInUse = USED(THIS.RefTable)
			IF !lInUse
				USE (THIS.RefTable) ALIAS FoxRefCursor IN 0 SHARED AGAIN
			ENDIF

			GOTO TOP IN FoxRefCursor
			IF TYPE("FoxRefCursor.RefType") == 'C' AND FoxRefCursor.RefType == REFTYPE_INIT
				REPLACE RefCode WITH ;
				  TRANSFORM(nTop) + ',' + TRANSFORM(nLeft) + ',' + TRANSFORM(nHeight) + ',' + TRANSFORM(nWidth) ;
				 IN FoxRefCursor
			ENDIF
			
			IF !lInUse AND USED("FoxRefCursor")
				USE IN FoxRefCursor
			ENDIF
		ENDIF
	ENDFUNC

	FUNCTION UpdateLookForMRU(cPattern)
		LOCAL nRow
		
		nRow = ASCAN(THIS.aLookForMRU, cPattern, -1, -1, 1, 15)
		IF nRow > 0
			=ADEL(THIS.aLookForMRU, nRow)
		ENDIF
		=AINS(THIS.aLookForMRU, 1)
		THIS.aLookForMRU[1] = cPattern
	ENDFUNC

	FUNCTION UpdateReplaceMRU(cReplaceText)
		LOCAL nRow
		
		nRow = ASCAN(THIS.aReplaceMRU, cReplaceText, -1, -1, 1, 15)
		IF nRow > 0
			=ADEL(THIS.aReplaceMRU, nRow)
		ENDIF
		=AINS(THIS.aReplaceMRU, 1)
		THIS.aReplaceMRU[1] = cReplaceText
	ENDFUNC

	FUNCTION UpdateFolderMRU(cFolder)
		LOCAL nRow
		
		nRow = ASCAN(THIS.aFolderMRU, cFolder, -1, -1, 1, 15)
		IF nRow > 0
			=ADEL(THIS.aFolderMRU, nRow)
		ENDIF
		=AINS(THIS.aFolderMRU, 1)
		THIS.aFolderMRU[1] = cFolder
	ENDFUNC


	FUNCTION UpdateFileTypesMRU(cFileTypes)
		LOCAL nRow
		
		nRow = ASCAN(THIS.aFileTypesMRU, cFileTypes, -1, -1, 1, 15)
		IF nRow > 0
			=ADEL(THIS.aFileTypesMRU, nRow)
		ENDIF
		=AINS(THIS.aFileTypesMRU, 1)
		THIS.aFileTypesMRU[1] = cFileTypes
	ENDFUNC

	* stolen from Class Browser
	FUNCTION WildCardMatch(tcMatchExpList, tcExpressionSearched, tlMatchAsIs)
		LOCAL lcMatchExpList,lcExpressionSearched,llMatchAsIs,lcMatchExpList2
		LOCAL lnMatchLen,lnExpressionLen,lnMatchCount,lnCount,lnCount2,lnSpaceCount
		LOCAL lcMatchExp,lcMatchType,lnMatchType,lnAtPos,lnAtPos2
		LOCAL llMatch,llMatch2

		IF ALLTRIM(tcMatchExpList) == "*.*"
			RETURN .T.
		ENDIF

		IF EMPTY(tcExpressionSearched)
			IF EMPTY(tcMatchExpList) OR ALLTRIM(tcMatchExpList) == "*"
				RETURN .T.
			ENDIF
			RETURN .F.
		ENDIF
		lcMatchExpList=LOWER(ALLTRIM(STRTRAN(tcMatchExpList,TAB," ")))
		lcExpressionSearched=LOWER(ALLTRIM(STRTRAN(tcExpressionSearched,TAB," ")))
		lnExpressionLen=LEN(lcExpressionSearched)
		IF lcExpressionSearched==lcMatchExpList
			RETURN .T.
		ENDIF
		llMatchAsIs=tlMatchAsIs
		IF LEFT(lcMatchExpList,1)==["] AND RIGHT(lcMatchExpList,1)==["]
			llMatchAsIs=.T.
			lcMatchExpList=ALLTRIM(SUBSTR(lcMatchExpList,2,LEN(lcMatchExpList)-2))
		ENDIF
		IF NOT llMatchAsIs AND " "$lcMatchExpList
			llMatch=.F.
			lnSpaceCount=OCCURS(" ",lcMatchExpList)
			lcMatchExpList2=lcMatchExpList
			lnCount=0
			DO WHILE .T.
				lnAtPos=AT(" ",lcMatchExpList2)
				IF lnAtPos=0
					lcMatchExp=ALLTRIM(lcMatchExpList2)
					lcMatchExpList2=""
				ELSE
					lnAtPos2=AT(["],lcMatchExpList2)
					IF lnAtPos2<lnAtPos
						lnAtPos2=AT(["],lcMatchExpList2,2)
						IF lnAtPos2>lnAtPos
							lnAtPos=lnAtPos2
						ENDIF
					ENDIF
					lcMatchExp=ALLTRIM(LEFT(lcMatchExpList2,lnAtPos))
					lcMatchExpList2=ALLTRIM(SUBSTR(lcMatchExpList2,lnAtPos+1))
				ENDIF
				IF EMPTY(lcMatchExp)
					EXIT
				ENDIF
				lcMatchType=LEFT(lcMatchExp,1)
				DO CASE
					CASE lcMatchType=="+"
						lnMatchType=1
					CASE lcMatchType=="-"
						lnMatchType=-1
					OTHERWISE
						lnMatchType=0
				ENDCASE
				IF lnMatchType#0
					lcMatchExp=ALLTRIM(SUBSTR(lcMatchExp,2))
				ENDIF
				llMatch2=THIS.WildCardMatch(lcMatchExp,lcExpressionSearched, .T.)
				IF (lnMatchType=1 AND NOT llMatch2) OR (lnMatchType=-1 AND llMatch2)
					RETURN .F.
				ENDIF
				llMatch=(llMatch OR llMatch2)
				IF lnAtPos=0
					EXIT
				ENDIF
			ENDDO
			RETURN llMatch
		ELSE
			IF LEFT(lcMatchExpList,1)=="~"
				RETURN (DIFFERENCE(ALLTRIM(SUBSTR(lcMatchExpList,2)),lcExpressionSearched)>=3)
			ENDIF
		ENDIF
		lnMatchCount=OCCURS(",",lcMatchExpList)+1
		IF lnMatchCount>1
			lcMatchExpList=","+ALLTRIM(lcMatchExpList)+","
		ENDIF
		FOR lnCount = 1 TO lnMatchCount
			IF lnMatchCount=1
				lcMatchExp=LOWER(ALLTRIM(lcMatchExpList))
				lnMatchLen=LEN(lcMatchExp)
			ELSE
				lnAtPos=AT(",",lcMatchExpList,lnCount)
				lnMatchLen=AT(",",lcMatchExpList,lnCount+1)-lnAtPos-1
				lcMatchExp=LOWER(ALLTRIM(SUBSTR(lcMatchExpList,lnAtPos+1,lnMatchLen)))
			ENDIF
			FOR lnCount2 = 1 TO OCCURS("?",lcMatchExp)
				lnAtPos=AT("?",lcMatchExp)
				IF lnAtPos>lnExpressionLen
					IF (lnAtPos-1)=lnExpressionLen
						lcExpressionSearched=lcExpressionSearched+"?"
					ENDIF
					EXIT
				ENDIF
				lcMatchExp=STUFF(lcMatchExp,lnAtPos,1,SUBSTR(lcExpressionSearched,lnAtPos,1))
			ENDFOR
			IF EMPTY(lcMatchExp) OR lcExpressionSearched==lcMatchExp OR ;
					lcMatchExp=="*" OR lcMatchExp=="?" OR lcMatchExp=="%%"
				RETURN .T.
			ENDIF
			IF LEFT(lcMatchExp,1)=="*"
				RETURN (SUBSTR(lcMatchExp,2)==RIGHT(lcExpressionSearched,LEN(lcMatchExp)-1))
			ENDIF
			IF LEFT(lcMatchExp,1)=="%" AND RIGHT(lcMatchExp,1)=="%" AND ;
					SUBSTR(lcMatchExp,2,lnMatchLen-2)$lcExpressionSearched
				RETURN .T.
			ENDIF
			lnAtPos=AT("*",lcMatchExp)
			IF lnAtPos>0 AND (lnAtPos-1)<=lnExpressionLen AND ;
					LEFT(lcExpressionSearched,lnAtPos-1)==LEFT(lcMatchExp,lnAtPos-1)
				RETURN .T.
			ENDIF
		ENDFOR
		RETURN .F.
	ENDFUNC

ENDDEFINE

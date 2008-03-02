* Abstract...:
*	Main engine for searching files.
*	Many of these methods are overridden
*	for specific file types.
*
* Changes....:
*
#include "foxref.h"
#include "foxpro.h"

DEFINE CLASS RefSearch AS Custom
	Name = "RefSearch"

	* this is a reference to the engine object (see FoxMatch.prg) that
	* searches a text string -- for example, it could be replaced 
	* with a regular expression search engine.
	oSearchEngine  = .NULL.
	oEngineController = .NULL.
	
	* set to true to not allow this filetype to refreshed (must always re-search)
	NoRefresh       = .F. 
	
	* comma-delimited list of file extensions to backup -- override in subclasses
	* set to empty string to not backup at all 
	BackupExtensions = .NULL.
	
	IncludeDefTable = .T.
	FormProperties  = .T.
	CodeOnly        = .F.
	PreserveCase    = .F. && TRUE to preserve case during a Replace operation

	Filename        = ''
	FName           = ''  && filename w/o path
	Folder          = ''  && folder file is in
	Pattern         = ''
	Comments        = COMMENTS_INCLUDE
	FileTimeStamp   = .NULL.

	FileID			= ''

	SetID          = ''
	RefID          = ''
	
	ReplaceLog     = ''

	* if an error occurs in a TRY/CATCH, then store it to this property
	oErr           = .NULL.

	* used internally to track when we need to create a new
	* unique RefID.  Each reference that appears on the
	* same line gets the same RefID. 
	nLastLineNo    = -1
	cLastProcName  = ''
	cLastClassName = ''
	cLastFilename  = ''
	
	nMatchCnt      = 0
	
	* text of the file we opened
	cFileText      = ''

	
	lDefinitionsOnly = .F.
	
	cExtendedPropertyText = REPLICATE(CHR(1), 517)

	
	PROCEDURE Init()
		SET TALK OFF
		SET DELETED ON
	
		THIS.SetID = SYS(2015)  && unique ID	
		THIS.FileTimeStamp = DATETIME()
	ENDPROC
	
	PROCEDURE Destroy()
	ENDPROC
	

	FUNCTION OpenFile(lReadWrite)
		LOCAL oException

		m.oException = .NULL.
		IF FILE(THIS.Filename)
			TRY
				THIS.cFileText = FILETOSTR(THIS.Filename)
			CATCH TO oException
			ENDTRY
		ENDIF

		RETURN m.oException
	ENDFUNC
	
	FUNCTION CloseFile
		THIS.cFileText = ''
	ENDFUNC

	* Create a backup of the file
	* nBackupStyle: 1 = filename.ext.bak  2 = Backup of filename.ext
	FUNCTION BackupFile(cFilename, nBackupStyle)
		LOCAL cBackupFile
		LOCAL cFileToBackup
		LOCAL lSuccess
		LOCAL cExt
		LOCAL i
		LOCAL nCnt
		LOCAL cSafety
		LOCAL oErr
		LOCAL ARRAY aExtensions[1]

		IF EMPTY(THIS.BackupExtensions)
			RETURN .T.
		ENDIF

		m.lSuccess = .T.
		
		IF VARTYPE(m.cFilename) <> 'C' OR EMPTY(m.cFilename)
			m.cFilename = THIS.Filename
		ENDIF

		m.cSafety = SET("SAFETY")
		SET SAFETY OFF
		IF ISNULL(THIS.BackupExtensions)
			* assume it's a text file and we only have one file to backup
			m.cBackupFile = THIS.CreateBackupFilename(m.cFilename, m.nBackupStyle)
			TRY
				COPY FILE (m.cFilename) TO (m.cBackupFile)
			CATCH TO oErr
				m.lSuccess = .F.
			ENDTRY
		ELSE
			m.nCnt = ALINES(m.aExtensions, THIS.BackupExtensions, .T., ',')
			FOR m.i = 1 TO m.nCnt
				IF !EMPTY(m.aExtensions[i])
					m.cFileToBackup = FORCEEXT(m.cFilename, m.aExtensions[i])
					m.cBackupFile = THIS.CreateBackupFilename(m.cFileToBackup, m.nBackupStyle)
					IF FILE(m.cFileToBackup) AND !EMPTY(m.cBackupFile)
						TRY
							COPY FILE (m.cFileToBackup) TO (m.cBackupFile)
						CATCH TO oErr
							m.lSuccess = .F.
						ENDTRY
					ENDIF
				ENDIF
			ENDFOR
		ENDIF
		SET SAFETY &cSafety

		
		RETURN m.lSuccess
	ENDFUNC
	
	* nBackupStyle: 1 = filename.ext.bak  2 = Backup of filename.ext
	PROTECTED FUNCTION CreateBackupFilename(cFilename, nBackupStyle)
		DO CASE
		CASE m.nBackupStyle == 1 && filename.ext.bak
			m.cFilename = m.cFilename + '.' + BACKUP_EXTENSION

		CASE m.nBackupStyle == 2 && "Backup of filename.ext"
			m.cFilename = ADDBS(JUSTPATH(m.cFilename)) + BACKUP_PREFIX_LOC + ' ' + JUSTFNAME(m.cFilename)

		OTHERWISE && same as style = 1
			m.cFilename = m.cFilename + '.' + BACKUP_EXTENSION
		ENDCASE
		
		RETURN m.cFilename
	ENDFUNC


	PROCEDURE SetTimeStamp()
		TRY
			THIS.FileTimeStamp = FDATE(THIS.Filename, 1)
		CATCH
			THIS.FileTimeStamp = DATETIME()
		ENDTRY
	ENDFUNC

	* Generate a FoxPro 3.0-style row timestamp
	PROTECTED FUNCTION RowTimeStamp(tDateTime)
		LOCAL cTimeValue
		IF VARTYPE(m.tDateTime) <> 'T'
			m.tDateTime = DATETIME()
			m.cTimeValue = TIME()
		ELSe
			m.cTimeValue = TTOC(m.tDateTime, 2)
		ENDIF

		RETURN ((YEAR(m.tDateTime) - 1980) * 2 ** 25);
			+ (MONTH(m.tDateTime) * 2 ** 21);
			+ (DAY(m.tDateTime) * 2 ** 16);
			+ (VAL(LEFTC(m.cTimeValue, 2)) * 2 ** 11);
			+ (VAL(SUBSTRC(m.cTimeValue, 4, 2)) * 2 ** 5);
			+  VAL(RIGHTC(m.cTimeValue, 2))
	ENDFUNC


	* -- This is the method that should get overridden
	FUNCTION DoSearch()
		RETURN THIS.FindInText(THIS.cFileText, FINDTYPE_TEXT, '', '', SEARCHTYPE_NORMAL)
	ENDFUNC

	* -- Abstract method for parsing symbol definitions
	* -- out of a file
	FUNCTION DoDefinitions()
	ENDFUNC

	* do a replacement on text
	FUNCTION DoReplace(cReplaceText, oReplaceCollection)
		LOCAL cCodeBlock
		LOCAL oException
		LOCAL oFoxRefRecord
		LOCAL i
		
		m.oException = .NULL.

		m.cCodeBlock = THIS.cFileText
		FOR m.i = oReplaceCollection.Count TO 1 STEP -1
			oFoxRefRecord = oReplaceCollection.Item(m.i)
			m.cCodeBlock = THIS.ReplaceText(m.cCodeBlock, oFoxRefRecord.LineNo, oFoxRefRecord.ColPos, oFoxRefRecord.MatchLen, m.cReplaceText, oFoxRefRecord.Abstract)
		ENDFOR
		TRY
			IF ISNULL(m.cCodeBlock)
				THROW ERROR_REPLACE_LOC
			ELSE
				IF (STRTOFILE(m.cCodeBlock, THIS.Filename) == 0)
					THROW ERROR_WRITE_LOC
				ENDIF
			ENDIF

		CATCH TO oException
		ENDTRY
				
		RETURN m.oException
	ENDFUNC

	* return what to add to the replace log
	FUNCTION DoReplaceLog(cReplaceText, oReplaceCollection)
		RETURN ''
	ENDFUNC

	* add an error in the FoxRef cursor
	FUNCTION AddError(cErrorMsg)
		IF SEEK(REFTYPE_INACTIVE, "FoxRefCursor", "RefType")
			REPLACE ;
			  SetID WITH THIS.SetID, ;
			  RefID WITH SYS(2015), ;
			  RefType WITH REFTYPE_ERROR, ;
			  FileID WITH THIS.FileID, ;
			  Symbol WITH '', ;
			  ClassName WITH '', ;
			  ProcName WITH '', ;
			  ProcLineNo WITH 0, ;
			  LineNo WITH 0, ;
			  ColPos WITH 0, ;
			  MatchLen WITH 0, ;
			  Abstract WITH m.cErrorMsg, ;
			  RecordID WITH '', ;
			  UpdField WITH '', ;
			  Checked WITH .F., ;
			  NoReplace WITH .F., ;
			  TimeStamp WITH DATETIME(), ;
			  Inactive WITH .F. ;
			 IN FoxRefCursor
		ELSE
			INSERT INTO FoxRefCursor ( ;
			  UniqueID, ;
			  SetID, ;
			  RefID, ;
			  RefType, ;
			  FileID, ;
			  Symbol, ;
			  ClassName, ;
			  ProcName, ;
			  ProcLineNo, ;
			  LineNo, ;
			  ColPos, ;
			  MatchLen, ;
			  Abstract, ;
			  RecordID, ;
			  UpdField, ;
			  Checked, ;
			  NoReplace, ;
			  Timestamp, ;
			  Inactive ;
			 ) VALUES ( ;
			  SYS(2015), ;
			  THIS.SetID, ;
			  SYS(2015), ;
			  REFTYPE_ERROR, ;
			  THIS.FileID, ;
			  '', ;
			  '', ;
			  '', ;
			  0, ;
			  0, ;
			  0, ;
			  0, ;
			  m.cErrorMsg, ;
			  '', ;
			  '', ;
			  .F., ;
			  .F., ;
			  DATETIME(), ;
			  .F. ;
			 )
		ENDIF
	ENDFUNC

	FUNCTION AddMatch(cFindType, cClassName, cProcName, nProcLineNo, nLineNo, nColPos, nMatchLen, cCode, cRecordID, cUpdField, lNoReplace)
		LOCAL cSymbol
		LOCAL ARRAY aPropInfo[1]
		
		THIS.nMatchCnt = THIS.nMatchCnt + 1

		IF THIS.nLastLineNo <> nLineNo OR !(THIS.cLastProcName == cProcName) OR !(THIS.cLastClassName == cClassName) OR !(THIS.cLastFilename == THIS.Filename)
			THIS.RefID = SYS(2015)
		ENDIF


		* if it's a property and occured in an extended property (multi-line property), then get the symbol
		IF m.cFindType == FINDTYPE_PROPERTYVALUE AND m.nProcLineNo > 1
			IF ALINES(aPropInfo, m.cCode) >= m.nProcLineNo
				m.cSymbol = SUBSTRC(aPropInfo[m.nProcLineNo], m.nColPos, m.nMatchLen)
			ELSE
				m.cSymbol = SUBSTRC(m.cCode, m.nColPos, m.nMatchLen)	
			ENDIF
		ELSE
			m.cSymbol = SUBSTRC(m.cCode, m.nColPos, m.nMatchLen)	
		ENDIF


		
		SELECT FoxRefCursor
		IF SEEK(REFTYPE_INACTIVE, "FoxRefCursor", "RefType")
			REPLACE ;
			  SetID WITH THIS.SetID, ;
			  RefID WITH THIS.RefID, ;
			  RefType WITH REFTYPE_RESULT, ;
			  FindType WITH m.cFindtype, ;
			  FileID WITH THIS.FileID, ;
			  Symbol WITH cSymbol, ;
			  ClassName WITH m.cClassName, ;
			  ProcName WITH m.cProcName, ;
			  ProcLineNo WITH m.nProcLineNo, ;
			  LineNo WITH m.nLineNo, ;
			  ColPos WITH m.nColPos, ;
			  MatchLen WITH m.nMatchLen, ;
			  Abstract WITH m.cCode, ;
			  RecordID WITH m.cRecordID, ;
			  UpdField WITH m.cUpdField, ;
			  Checked WITH .F., ;
			  NoReplace WITH m.lNoReplace, ;
			  TimeStamp WITH THIS.FileTimeStamp, ;
			  Inactive WITH .F. ;
			 IN FoxRefCursor
		ELSE
			INSERT INTO FoxRefCursor ( ;
			  UniqueID, ;
			  SetID, ;
			  RefID, ;
			  RefType, ;
			  FindType, ;
			  FileID, ;
			  Symbol, ;
			  ClassName, ;
			  ProcName, ;
			  ProcLineNo, ;
			  LineNo, ;
			  ColPos, ;
			  MatchLen, ;
			  Abstract, ;
			  RecordID, ;
			  UpdField, ;
			  Checked, ;
			  NoReplace, ;
			  Timestamp, ;
			  Inactive ;
			 ) VALUES ( ;
			  SYS(2015), ;
			  THIS.SetID, ;
			  THIS.RefID, ;
			  REFTYPE_RESULT, ;
			  m.cFindType, ;
			  THIS.FileID, ;
			  m.cSymbol, ;
			  m.cClassName, ;
			  m.cProcName, ;
			  m.nProcLineNo, ;
			  m.nLineNo, ;
			  m.nColPos, ;
			  m.nMatchLen, ;
			  m.cCode, ;
			  m.cRecordID, ;
			  m.cUpdField, ;
			  .F., ;
			  m.lNoReplace, ;
			  THIS.FileTimeStamp, ;
			  .F. ;
			 )
		ENDIF
				 
		THIS.nLastLineNo    = m.nLineNo
		THIS.cLastProcName  = m.cProcName
		THIS.cLastClassName = m.cClassName
		THIS.cLastFilename  = THIS.Filename
	ENDFUNC


	FUNCTION AddDefinition(cSymbol, cDefType, cClassName, cProcName, nProcLineNo, nLineNo, cCode, lIncludeFile)
		m.cSymbol = UPPER(m.cSymbol)

		IF !m.lIncludeFile
			* if definition name doesn't begin with an underscore or Alpha character
			* then assume it's not a valid symbol name
			IF !ISALPHA(m.cSymbol) AND LEFTC(m.cSymbol, 1) <> '_'
				RETURN .F.
			ENDIF
		
			* remove any memory variable designations
			IF LEFTC(m.cSymbol, 2) == "M."	
				m.cSymbol = SUBSTRC(m.cSymbol, 3)
				IF EMPTY(m.cSymbol)
					RETURN .F.
				ENDIF
			ENDIF
		ENDIF
			
		THIS.nMatchCnt = THIS.nMatchCnt + 1

		IF THIS.nLastLineNo <> nLineNo OR !(THIS.cLastProcName == cProcName) OR !(THIS.cLastClassName == cClassName) OR !(THIS.cLastFilename == THIS.Filename)
			THIS.RefID = SYS(2015)
		ENDIF

		IF SEEK(.T., "FoxDefCursor", "Inactive")
			REPLACE ;
			  DefType WITH m.cDefType, ;
			  FileID WITH THIS.FileID, ;
			  Symbol WITH m.cSymbol, ;
			  ClassName WITH m.cClassName, ;
			  ProcName WITH m.cProcName, ;
			  ProcLineNo WITH m.nProcLineNo, ;
			  LineNo WITH m.nLineNo, ;
			  Abstract WITH THIS.StripTabs(m.cCode), ;
			  Inactive WITH .F. ;
			 IN FoxDefCursor
		ELSE
			INSERT INTO FoxDefCursor ( ;
			  UniqueID, ;
			  DefType, ;
			  FileID, ;
			  Symbol, ;
			  ClassName, ;
			  ProcName, ;
			  ProcLineNo, ;
			  LineNo, ;
			  Abstract, ;
			  Inactive ;
			 ) VALUES ( ;
			  SYS(2015), ;
			  m.cDefType, ;
			  THIS.FileID, ;
			  m.cSymbol, ;
			  m.cClassName, ;
			  m.cProcName, ;
			  m.nProcLineNo, ;
			  m.nLineNo, ;
			  THIS.StripTabs(m.cCode), ;
			  .F. ;
			 )
		ENDIF
				 
		THIS.nLastLineNo    = m.nLineNo
		THIS.cLastProcName  = m.cProcName
		THIS.cLastClassName = m.cClassName
		THIS.cLastFilename  = THIS.Filename
		
		RETURN .T.
	ENDFUNC

	* Add a file to process -- usually when we encounter
	* #include files while we're processing definitions
	FUNCTION AddFileToProcess(cDefType, cFilename, cClassName, cProcName, nProcLineNo, nLineNo, cCode)
		IF LEFTC(m.cFilename, 1) == '"'
			m.cFilename = SUBSTRC(m.cFilename, 2)
		ENDIF
		IF RIGHTC(m.cFilename, 1) == '"'
			m.cFilename = LEFTC(m.cFilename, LENC(m.cFilename) - 1)
		ENDIF

		IF VARTYPE(THIS.oEngineController) == 'O'
			THIS.oEngineController.AddFileToProcess(m.cFilename)
		ENDIF

		THIS.AddDefinition(m.cFilename, m.cDefType, m.cClassName, m.cProcName, m.nProcLineNo, m.nLineNo, m.cCode, .T.)
	ENDFUNC	

	FUNCTION AddFileToSearch(cFilename)
		IF VARTYPE(THIS.oEngineController) == 'O'
			THIS.oEngineController.AddFileToSearch(m.cFilename)
		ENDIF
	ENDFUNC


	FUNCTION ProcessDefinitions(oEngineController)
		IF VARTYPE(m.oEngineController) == 'O'
			THIS.oEngineController = m.oEngineController
		ENDIF
		THIS.DoDefinitions()
		THIS.oEngineController = .NULL.
	
	ENDFUNC

	* Returns the FileAction ('N' = Processed w/o Definitions, 'D' = Processed w/definitions, 'E' = Error, 'S' = Stop immediately)
	FUNCTION SearchFor(cPattern, lSearch, lDefinitions, oEngineController)
		LOCAL cFileAction && file action to return
		LOCAL oException
		LOCAL nSelect
		
		m.nSelect = SELECT()
		
		IF VARTYPE(m.oEngineController) == 'O'
			THIS.oEngineController = m.oEngineController
		ENDIF
		
		IF VARTYPE(m.cPattern) == 'C'
			THIS.Pattern = m.cPattern
		ENDIF

		IF PCOUNT() < 3
			m.lDefinitions = THIS.IncludeDefTable
		ENDIF
	
		m.cFileAction = ''

		THIS.FName  = JUSTFNAME(THIS.Filename)
		THIS.Folder = JUSTPATH(THIS.Filename)
		THIS.nMatchCnt = 0

		IF THIS.oSearchEngine.SetPattern(THIS.Pattern)
			m.oException = THIS.OpenFile()
			IF ISNULL(m.oException)
				TRY
					IF m.lDefinitions
						THIS.nLastLineNo = -1
						THIS.DoDefinitions()
						
						m.cFileAction = FILEACTION_DEFINITIONS
					ENDIF

					IF lSearch AND !EMPTY(m.cPattern) && if no search pattern passed, then only do definitions
						THIS.nLastLineNo = -1
						IF !THIS.DoSearch()
							m.cFileAction = FILEACTION_STOP
						ENDIF
					ENDIF

					THIS.CloseFile()

					IF THIS.nMatchCnt == 0 AND !(m.cFileAction == FILEACTION_STOP)
						IF SEEK(REFTYPE_INACTIVE, "FoxRefCursor", "RefType")
							REPLACE ;
							  SetID WITH THIS.SetID, ;
							  RefID WITH SYS(2015), ;
							  RefType WITH REFTYPE_NOMATCH, ;
							  FileID WITH THIS.FileID, ;
							  Symbol WITH '', ;
							  ClassName WITH '', ;
							  ProcName WITH '', ;
							  ProcLineNo WITH 0, ;
							  LineNo WITH 0, ;
							  ColPos WITH 0, ;
							  MatchLen WITH 0, ;
							  Abstract WITH '', ;
							  RecordID WITH '', ;
							  UpdField WITH '', ;
							  Checked WITH .F., ;
							  NoReplace WITH .F., ;
							  TimeStamp WITH THIS.FileTimeStamp, ;
							  Inactive WITH .F. ;
							 IN FoxRefCursor
						ELSE
							* no matches, but still record that we searched this file
							INSERT INTO FoxRefCursor ( ;
							  UniqueID, ;
							  SetID, ;
							  RefID, ;
							  RefType, ;
							  FileID, ;
							  Symbol, ;
							  ClassName, ;
							  ProcName, ;
							  ProcLineNo, ;
							  LineNo, ;
							  ColPos, ;
							  MatchLen, ;
							  Abstract, ;
							  RecordID, ;
							  UpdField, ;
							  Checked, ;
							  NoReplace, ;
							  Timestamp, ;
							  Inactive ;
							 ) VALUES ( ;
							  SYS(2015), ;
							  THIS.SetID, ;
							  SYS(2015), ;
							  REFTYPE_NOMATCH, ;
							  THIS.FileID, ;
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
							  .F., ;
							  .F., ;
							  THIS.FileTimeStamp, ;
							  .F. ;
							 )
						ENDIF
					ENDIF
				CATCH TO oException
					* error is recorded below
				ENDTRY
			ENDIF
			
			IF VARTYPE(oException) == 'O'
				THIS.AddError(IIF(EMPTY(m.oException.UserValue), m.oException.Message, m.oException.UserValue))
				m.cFileAction = FILEACTION_ERROR
			ENDIF
		ELSE
			* unable to set the pattern
			m.cFileAction = FILEACTION_STOP
		ENDIF

		THIS.oEngineController = .NULL.
		
		SELECT (m.nSelect)
		
		RETURN m.cFileAction
	ENDFUNC

	* this is what FoxRefEngine calls to do the replacements
	FUNCTION ReplaceWith(cReplaceText, oReplaceCollection, cFilename) AS Boolean
		LOCAL lSuccess
		LOCAL nSelect
		LOCAL oException
	
		THIS.Filename = m.cFilename

		m.nSelect = SELECT()

		m.oException = THIS.OpenFile(.T.)

		IF ISNULL(m.oException)
			TRY
				m.oException = THIS.DoReplace(m.cReplaceText, m.oReplaceCollection)
			CATCH TO m.oException
			ENDTRY
			
			THIS.ReplaceLog = THIS.DoReplaceLog(m.cReplaceText, m.oReplaceCollection)

			THIS.CloseFile()
		ENDIF
	
		SELECT (m.nSelect)

		RETURN m.oException
	ENDFUNC

	* take the original text, determine the case,
	* and apply it the new text
	FUNCTION SetCasePreservation(cOriginalText, cReplacementText)
		LOCAL i
		LOCAL ch
		LOCAL lLower
		LOCAL lUpper

		IF ISUPPER(LEFTC(m.cOriginalText, 1)) AND ISLOWER(SUBSTRC(m.cOriginalText, 2, 1))
			* proper case
			m.cReplacementText = PROPER(m.cReplacementText)
		ELSE
			m.lLower = .F.
			m.lUpper = .F.
			FOR m.i = 1 TO LENC(m.cOriginalText)
				ch = SUBSTRC(m.cOriginalText, m.i, 1)
				DO CASE
				CASE BETWEEN(ch, 'A', 'Z')
					m.lUpper = .T.
				CASE BETWEEN(ch, 'a', 'z')
					m.lLower = .T.
				ENDCASE
				
				IF m.lLower AND m.lUpper
					EXIT
				ENDIF
			ENDFOR
			
			DO CASE
			CASE m.lLower AND !m.lUpper
				m.cReplacementText = LOWER(m.cReplacementText)
			CASE !m.lLower AND m.lUpper
				m.cReplacementText = UPPER(m.cReplacementText)
			ENDCASE
		ENDIF
				
		RETURN m.cReplacementText
	ENDFUNC

	* perform a replacement on text
	*  NOTE: cOldCode contains the original text as it was when we original searched, but we don't use it here anymore
	FUNCTION ReplaceText(cCodeBlock, nLineNo, nColPos, nMatchLen, cNewText, cOldCode)
		LOCAL nLineCnt
		LOCAL i
		LOCAL lSuccess
		LOCAL cOriginalText
		LOCAL cReplacementText
		LOCAL ARRAY aCodeList[1]
		
		IF ISNULL(cCodeBlock)
			RETURN .NULL.
		ENDIF
	
		m.lSuccess = .F.

		m.cReplacementText = m.cNewText
		IF m.nLineNo == 0
			IF THIS.PreserveCase
				m.cOriginalText = SUBSTRC(m.cCodeBlock, m.nColPos, m.nMatchLen)
				m.cNewText = THIS.SetCasePreservation(m.cOriginalText, m.cReplacementText)
			ENDIF
		
			m.cCodeBlock = LEFTC(m.cCodeBlock, m.nColPos - 1) + m.cNewText + IIF(m.nColPos + m.nMatchLen > LENC(m.cCodeBlock), '', SUBSTRC(m.cCodeBlock, m.nColPos + m.nMatchLen))
			m.lSuccess = .T.
		ELSE
			m.nLineCnt = ALINES(m.aCodeList, m.cCodeBlock, .F.)
			IF m.nLineNo <= m.nLineCnt
				IF THIS.PreserveCase
					m.cOriginalText = SUBSTRC(m.aCodeList[m.nLineNo], m.nColPos, m.nMatchLen)
					m.cNewText = THIS.SetCasePreservation(m.cOriginalText, m.cReplacementText)
				ENDIF

				m.aCodeList[m.nLineNo] = LEFTC(m.aCodeList[m.nLineNo], m.nColPos - 1) + m.cNewText + IIF(m.nColPos + m.nMatchLen > LENC(m.aCodeList[m.nLineNo]), '', SUBSTRC(m.aCodeList[m.nLineNo], m.nColPos + m.nMatchLen))
				
				m.cCodeBlock = ''
				FOR m.i = 1 TO nLineCnt
					m.cCodeBlock = m.cCodeBlock + IIF(m.i == 1, '', CHR(13) + CHR(10)) + m.aCodeList[m.i]
				ENDFOR
				
				m.lSuccess = .T.
			ENDIF
		ENDIF
			
		IF !m.lSuccess
			m.cCodeBlock = .NULL.
		ENDIF

		RETURN m.cCodeBlock
	ENDFUNC



	* -- This is the meat of our find.  Searches through text or code
	FUNCTION FindInCode(cTextBlock, cFindType, cClassName, cObjName, nSearchType, cRecordID, cUpdField, lNoReplace)
		LOCAL i
		LOCAL nSelect
		LOCAL nLineCnt
		LOCAL cProcName
		LOCAL nProcLineNo
		LOCAL cFirstChar
		LOCAL nOffset
		LOCAL lFound
		LOCAL nCommentPos
		LOCAL lExitLine
		LOCAL nWordNum
		LOCAL cFirstWord
		LOCAL lComment
		LOCAL nMatchCnt
		LOCAL nLastLineNo
		LOCAL nMatchIndex
		LOCAL oMatch
		LOCAL lMethodName
		LOCAL lUseMemLines
		LOCAL cCodeLine
		LOCAL nMemoWidth
		LOCAL lCommentAndContinue
		LOCAL ARRAY aCodeList[1]

		m.nMatchCnt = THIS.oSearchEngine.Execute(m.cTextBlock)
		IF m.nMatchCnt <= 0
			RETURN (m.nMatchCnt >= 0)
		ENDIF

		IF VARTYPE(m.cClassName) <> 'C'
			m.cClassName = ''
		ENDIF

		IF VARTYPE(m.cObjName) <> 'C'
			m.cObjName = ''
		ENDIF

		IF m.nSearchType == SEARCHTYPE_METHOD  && search in method code of .vcx or .scx
			m.nOffset = -1
		ELSE
			m.nOffset = 0
		ENDIF

		* this is the UNIQUEID field from a form or class library
		IF VARTYPE(m.cRecordID) <> 'C'
			m.cRecordID = ''
		ENDIF
		IF VARTYPE(m.cUpdField) <> 'C'
			m.cUpdField = ''
		ENDIF

		m.cProcName   = ''
		m.nProcLineNo = 0
		m.lComment    = .F.
		m.lCommentAndContinue = .F.
		
		m.nSelect = SELECT()

		nMatchIndex    = 1


		* ALINES should be faster, but we can't use that if
		* there are more than 65k lines in the code block
		m.lUseMemLines = .F.
		TRY
			m.nLineCnt = ALINES(aCodeList, m.cTextBlock, .F.)
		CATCH
			m.lUseMemLines = .T.
		ENDTRY
		
		IF m.lUseMemLines
			m.nMemoWidth = SET("MEMOWIDTH")
			SET MEMOWIDTH TO 8192
			m.nLineCnt = MEMLINES(m.cTextBlock)
			_MLINE = 0
		ENDIF


		m.nLastLineNo  = MIN(THIS.oSearchEngine.oMatches(m.nMatchCnt).MatchLineNo, m.nLineCnt)
		FOR m.i = 1 TO m.nLastLineNo
			IF m.lUseMemLines
				m.cCodeLine = MLINE(m.cTextBlock, 1, _MLINE)
			ELSE
				m.cCodeLine = aCodeList[m.i]
			ENDIF

			m.lMethodName = .F.
		
			* get first word
			m.nWordNum = 1
			m.cFirstWord = UPPER(GETWORDNUM(m.cCodeLine, m.nWordNum, WORD_DELIMITERS))

			IF m.lCommentAndContinue
				* since the last line was a comment line and also
				* was a continuation line, then this is a comment line
				m.lComment = .T.
			ELSE
				m.lComment = m.cFirstWord = '*' OR (m.cFirstWord = ("&" + "&")) OR m.cFirstWord == "NOTE"
			ENDIF


			IF (m.lComment AND THIS.Comments == COMMENTS_EXCLUDE)
				m.nProcLineNo = m.nProcLineNo + 1

				* if this line was a comment line and also
				* was a continuation line, then the next line
				* is also a comment
				m.lCommentAndContinue = m.lComment AND RIGHTC(RTRIM(m.cCodeLine), 1) == ';'

				LOOP
			ENDIF

			IF !m.lComment AND LENC(m.cFirstWord) >= 4 AND INLIST(m.cFirstWord, 'E', 'H', 'P', 'F', 'L', 'D')
				IF "PROTECTED" = m.cFirstWord OR "HIDDEN" = m.cFirstWord
					m.nWordNum = m.nWordNum + 1
					m.cFirstWord = UPPER(GETWORDNUM(m.cCodeLine, m.nWordNum, WORD_DELIMITERS))
				ENDIF

				DO CASE
				CASE "PROCEDURE" = m.cFirstWord
					m.cProcName = GETWORDNUM(m.cCodeLine, m.nWordNum + 1, METHOD_DELIMITERS)
					m.nProcLineNo = 0
					m.lMethodName = .T.
					
				CASE "FUNCTION" = cFirstWord
					m.cProcName = GETWORDNUM(m.cCodeLine, m.nWordNum + 1, METHOD_DELIMITERS)
					m.nProcLineNo = 0

				CASE "ENDFUNC" = m.cFirstWord
					m.cProcName = ''
					m.nProcLineNo = 0

				CASE "ENDPROC" = m.cFirstWord
					m.cProcName = ''
					m.nProcLineNo = 0

				CASE "DEFINE" = m.cFirstWord
					m.cSecondWord = UPPER(GETWORDNUM(m.cCodeLine, m.nWordNum + 1, WORD_DELIMITERS))
					IF LENC(m.cSecondWord) >= 4 AND "CLASS" = m.cSecondWord
						m.cClassName = GETWORDNUM(m.cCodeLine, m.nWordNum + 2, WORD_DELIMITERS)
						m.cProcName = ''
						m.nProcLineNo = 0
					ENDIF

				CASE "ENDDEFINE" = m.cFirstWord
					m.cClassName  = ''
					m.cProcName   = ''
					m.nProcLineNo = 0

				ENDCASE
			ENDIF

			m.nProcLineNo = m.nProcLineNo + 1

			IF THIS.Comments == COMMENTS_EXCLUDE OR THIS.Comments == COMMENTS_ONLY
				m.nCommentPos = AT_C('&' + '&', m.cCodeLine)

				* if this line was a comment line and also
				* was a continuation line, then the next line
				* is also a comment
				m.lCommentAndContinue = m.nCommentPos > 0 AND RIGHTC(RTRIM(m.cCodeLine), 1) == ';'
			ELSE
				m.nCommentPos = 0
			ENDIF


			FOR m.j = m.nMatchIndex TO m.nMatchCnt
				oMatch = THIS.oSearchEngine.oMatches(m.j)
	
				IF oMatch.MatchLineNo == m.i
					IF (THIS.Comments == COMMENTS_EXCLUDE AND m.nCommentPos > 0 AND oMatch.MatchPos >= m.nCommentPos)
						EXIT
					ENDIF

					IF THIS.Comments <> COMMENTS_ONLY OR m.lComment OR (m.nCommentPos > 0 AND oMatch.MatchPos >= m.nCommentPos)
						THIS.AddMatch( ;
						  m.cFindType, ;
						  m.cClassName, ;
						  m.cObjName + IIF(EMPTY(m.cObjName) OR EMPTY(m.cProcName), '', '.') + m.cProcName, ;
						  IIF(nSearchType == SEARCHTYPE_EXPR, 0, m.nProcLineNo + m.nOffset), ;
						  IIF(nSearchType == SEARCHTYPE_EXPR, 0, m.i), ;
						  oMatch.MatchPos, ;
						  oMatch.MatchLen, ;
						  m.cCodeLine, ;
						  m.cRecordID, ;
						  IIF(m.lMethodName, "METHODNAME", m.cUpdField), ;
						  IIF(m.lMethodName, .T., m.lNoReplace) ;
						 )
					ENDIF

				ELSE
					IF oMatch.MatchLineNo > m.i
						EXIT
					ENDIF
				ENDIF

				m.nMatchIndex = m.nMatchIndex + 1
			ENDFOR

		ENDFOR

		IF m.lUseMemLines
			SET MEMOWIDTH TO (m.nMemoWidth)
		ENDIF
		
		SELECT (m.nSelect)
	ENDFUNC

	* -- This searches a text block, assuming it's NOT code so there's
	* -- no reason to locate comments, entering & exiting procedures, etc
	FUNCTION FindInText(cTextBlock, cFindType, cClassName, cObjName, nSearchType, cRecordID, cUpdField, lNoReplace)
		LOCAL i
		LOCAL nSelect
		LOCAL nLineCnt
		LOCAL lUseMemLines
		LOCAL nMemoWidth
		LOCAL ARRAY aCodeList[1]

		m.nSelect = SELECT()

		IF VARTYPE(m.cClassName) <> 'C'
			m.cClassName = ''
		ENDIF

		IF VARTYPE(m.cObjName) <> 'C'
			m.cObjName = ''
		ENDIF

		* this is the UNIQUEID field from a form or class library
		IF VARTYPE(m.cRecordID) <> 'C'
			m.cRecordID = ''
		ENDIF
		IF VARTYPE(m.cUpdField) <> 'C'
			m.cUpdField = ''
		ENDIF

		m.nMatchCnt = THIS.oSearchEngine.Execute(m.cTextBlock)
		IF m.nMatchCnt > 0
			* ALINES should be faster, but we can't use that if
			* there are more than 65k lines in the code block
			m.lUseMemLines = .F.
			TRY
				m.nLineCnt = ALINES(aCodeList, m.cTextBlock, .F.)
			CATCH
				m.lUseMemLines = .T.
			ENDTRY
			
			IF m.lUseMemLines
				m.nMemoWidth = SET("MEMOWIDTH")
				SET MEMOWIDTH TO 8192
				m.nLineCnt = MEMLINES(m.cTextBlock)
			ENDIF

			FOR EACH oMatch IN THIS.oSearchEngine.oMatches
				THIS.AddMatch( ;
				  m.cFindType, ;
				  m.cClassName, ;
				  m.cObjName, ;
				  oMatch.MatchLineNo, ;
				  oMatch.MatchLineNo, ;
				  oMatch.MatchPos, ;
				  oMatch.MatchLen, ;
				  IIF(m.lUseMemLines, MLINE(m.cTextBlock, oMatch.MatchLineNo), aCodeList[oMatch.MatchLineNo]), ;
				  m.cRecordID, ;
				  m.cUpdField, ;
				  m.lNoReplace ;
				 )
				
			ENDFOR
		ENDIF

		IF m.lUseMemLines
			SET MEMOWIDTH TO (m.nMemoWidth)
		ENDIF

		SELECT (m.nSelect)		
	ENDFUNC

	* perform search on a single line of text (no line # recorded)
	FUNCTION FindInLine(cTextBlock, cFindType, cClassName, cObjName, nSearchType, cRecordID, cUpdField, lNoReplace, cAbstract, nColOffset, nLineNo)
		LOCAL nSelect
		LOCAL nMatchLen
		LOCAL nMatchCnt

		m.nSelect = SELECT()

		IF VARTYPE(m.cClassName) <> 'C'
			m.cClassName = ''
		ENDIF

		IF VARTYPE(m.cObjName) <> 'C'
			m.cObjName = ''
		ENDIF

		* this is the UNIQUEID field from a form or class library
		IF VARTYPE(m.cRecordID) <> 'C'
			m.cRecordID = ''
		ENDIF
		IF VARTYPE(m.cUpdField) <> 'C'
			m.cUpdField = ''
		ENDIF
		IF VARTYPE(m.nColOffset) <> 'N'
			m.nColOffset = 0
		ENDIF
		IF VARTYPE(m.nLineNo) <> 'N'
			m.nLineNo = 0
		ENDIF

		THIS.RefID = SYS(2015)


		* see if reference occurs on this line
		m.nMatchCnt = THIS.oSearchEngine.Execute(m.cTextBlock)
		IF m.nMatchCnt > 0

			FOR EACH oMatch IN THIS.oSearchEngine.oMatches
				THIS.AddMatch( ;
				  m.cFindType, ;
				  m.cClassName, ;
				  m.cObjName, ;
				  oMatch.MatchLineNo, ;
				  m.nLineNo, ;
				  oMatch.MatchPos + m.nColOffset, ;
				  oMatch.MatchLen, ;
				  IIF(VARTYPE(m.cAbstract) == 'C', m.cAbstract, m.cTextBlock), ;
				  m.cRecordID, ;
				  m.cUpdField, ;
				  m.lNoReplace ;
				 )

			ENDFOR
		ENDIF
		
		SELECT (m.nSelect)
		
		RETURN m.nMatchCnt >= 0 && -1 returned on error
	ENDFUNC


	* -- This searches a property list
	FUNCTION FindInProperties(cTextBlock, cPEMList, cClassName, cObjName, nSearchType, cRecordID)
		LOCAL i
		LOCAL j
		LOCAL nSelect
		LOCAL nLineCnt
		LOCAL nMatchLen
		LOCAL cPropertyName
		LOCAL nEqualPos
		LOCAL cPropertyValue
		LOCAL lSuccess
		LOCAL nPEMCnt
		LOCAL cProperty
		LOCAL nLen
		LOCAL nPos
		LOCAL ARRAY aCodeList[1]
		LOCAL ARRAY aPEMList[1]

		IF (THIS.Comments == COMMENTS_ONLY)
			RETURN
		ENDIF

		m.nSelect = SELECT()

		m.lSuccess = .T.

		IF VARTYPE(m.cClassName) <> 'C'
			m.cClassName = ''
		ENDIF

		IF VARTYPE(m.cObjName) <> 'C'
			m.cObjName = ''
		ENDIF

		* this is the UNIQUEID field from a form or class library
		IF VARTYPE(m.cRecordID) <> 'C'
			m.cRecordID = ''
		ENDIF
		
		IF EMPTY(m.cPEMList)
			m.nPEMCnt = 0
		ELSE
			m.nPEMCnt = ALINES(aPEMList, m.cPEMList, .T.)
		ENDIF

		m.nLineCnt = 0
		m.cProperty = RTRIM(GETWORDNUM(m.cTextBlock, 1, CHR(10)), 0, CHR(13))
		DO WHILE !EMPTY(m.cProperty)
			m.nEqualPos = AT_C(' = ', m.cProperty)
			IF m.nEqualPos > 3
				IF SUBSTR(m.cProperty, m.nEqualPos + 3, 517) == THIS.cExtendedPropertyText
					* we have an extended propererty
					m.cPropertyName = LEFTC(m.cProperty, m.nEqualPos - 1)
					
					m.nLen = VAL(SUBSTR(m.cProperty, m.nEqualPos + 3 + 517, 8))

					m.cProperty = m.cPropertyName + " = " + SUBSTR(m.cProperty, m.nEqualPos + 3 + 517 + 8, nLen)
					m.cTextBlock = SUBSTR(m.cTextBlock, m.nEqualPos + 5 + 517 + 8 + nLen)
				ELSE
					m.nPos = AT(CHR(10), m.cTextBlock)
					IF m.nPos = 0 
						m.nPos = AT(CHR(13), m.cTextBlock)
					ENDIF
					IF m.nPos > 0
						m.cTextBlock = SUBSTR(m.cTextBlock, m.nPos + 1)
					ELSE
						m.cTextBlock = ''
					ENDIF
				ENDIF
				
				m.nLineCnt = m.nLineCnt + 1
				DIMENSION aCodeList[m.nLineCnt]
				aCodeList[m.nLineCnt] = m.cProperty
				
				m.cProperty = RTRIM(GETWORDNUM(m.cTextBlock, 1, CHR(10)), 0, CHR(13))
			ELSE
				m.cProperty = ''
			ENDIF
		ENDDO
		
		FOR m.i = 1 TO m.nLineCnt
			* First see if we have a match for PropertName = Propertyvalue (e.g. Width = 300)
			m.nEqualPos = AT_C(' = ', aCodeList[m.i])
			IF m.nEqualPos > 3
				m.cPropertyName = LEFTC(aCodeList[m.i], m.nEqualPos - 1)

				* if the property name occurs here, zero it out from the PEMList
				* so we don't find it again
				FOR m.j = 1 TO m.nPEMCnt
					* this won't find method names because they start with '*'
					IF aPEMList[m.j] == m.cPropertyName
						aPEMList[m.j] = ''
					ENDIF
				ENDFOR

				m.cProperty = aCodeList[m.i]
				m.lSuccess = THIS.FindInLine(m.cProperty, FINDTYPE_PROPERTYVALUE, m.cClassName, m.cObjName, SEARCHTYPE_NORMAL, m.cRecordID, "PROPERTYNAME", .T., m.cProperty,, m.i)
				IF !m.lSuccess
					* see if reference occurs in the value portion of the property name
					m.cPropertyValue = SUBSTRC(m.cProperty, m.nEqualPos + 3)

					m.lSuccess = THIS.FindInLine(m.cPropertyName, FINDTYPE_PROPERTYNAME, m.cClassName, m.cObjName, SEARCHTYPE_NORMAL, m.cRecordID, "PROPERTYNAME", .T., m.cProperty,, m.i) OR m.lSuccess
					m.lSuccess = THIS.FindInLine(m.cPropertyValue, FINDTYPE_PROPERTYVALUE, m.cClassName, m.cObjName + IIF(EMPTY(m.cObjName) OR EMPTY(m.cPropertyName), '', '.') + m.cPropertyName, SEARCHTYPE_NORMAL, m.cRecordID, "PROPERTYVALUE", .T., m.cProperty, m.nEqualPos + 2, m.i) OR m.lSuccess
				ENDIF
			ENDIF
		ENDFOR

		* see if match occurs in a defined property that has a default value
		* (if it has a default value, it won't show up in the Properties field)
		FOR m.i = 1 TO m.nPEMCnt
			IF !EMPTY(aPEMList[m.i]) AND LEFTC(aPEMList[m.i], 1) <> '*'
				m.lSuccess = THIS.FindInLine(aPEMList[m.i], FINDTYPE_PROPERTYNAME, m.cClassName, m.cObjName, SEARCHTYPE_NORMAL, m.cRecordID, "PROPERTYNAME", .T., aPEMList[m.i],, m.i) OR m.lSuccess
			ENDIF
		ENDFOR


		SELECT (m.nSelect)		
		
		RETURN m.lSuccess
	ENDFUNC

	* find any defined Methods
	FUNCTION FindDefinedMethods(cTextBlock, cClassName, cObjName, nSearchType, cRecordID)
		LOCAL i
		LOCAL nLineCnt
		LOCAL nMatchLen
		LOCAL cPEMName
		LOCAL lSuccess
		LOCAL ARRAY aCodeList[1]

		IF (THIS.Comments == COMMENTS_ONLY)
			RETURN
		ENDIF

		m.lSuccess = .T.

		IF VARTYPE(m.cClassName) <> 'C'
			m.cClassName = ''
		ENDIF

		IF VARTYPE(m.cObjName) <> 'C'
			m.cObjName = ''
		ENDIF

		* this is the UNIQUEID field from a form or class library
		IF VARTYPE(m.cRecordID) <> 'C'
			m.cRecordID = ''
		ENDIF

		m.nLineCnt = ALINES(aCodeList, m.cTextBlock, .F.)
		FOR m.i = 1 TO m.nLineCnt
			IF LEFTC(aCodeList[m.i], 1) == '*' && methods begin with '*' in reserved3 field
				m.cPEMName = SUBSTRC(aCodeList[m.i], 2)
				m.lSuccess = THIS.FindInLine(m.cPEMName, FINDTYPE_PROPERTYNAME, m.cClassName, m.cObjName, SEARCHTYPE_NORMAL, m.cRecordID, "METHOD", .T., m.cPEMName,, m.i)
			ENDIF
		ENDFOR
		
		RETURN m.lSuccess
	ENDFUNC

	FUNCTION ParseLine(cLine, aTokens, nTokenCnt)
		LOCAL cEndQuote
		LOCAL cWord
		LOCAL cLastCh
		LOCAL ch
		LOCAL nTerminal
		LOCAL lInQuote
		LOCAL lInSymbol
		LOCAL nTokenCnt
		LOCAL nLen
		LOCAL i


		nTerminal = 0
		cWord     = ''
		nLen      = LENC(cLine)
		cLastCh   = ''
		FOR i = 1 TO nLen
			ch = SUBSTRC(cLine, i, 1)

			IF lInQuote
				IF ch == cEndQuote
					nTerminal = 1
					cEndQuote = ''
					cWord = cWord + ch
					ch = ''
					lInQuote = .F.
				ELSE
					nTerminal = 0
				ENDIF
			ELSE
				IF ch == '_' OR IsAlpha(ch) OR ch == '.' OR ch $ "0123456789"
					IF lInSymbol
						nTerminal = 0
					ELSE
						lInSymbol = .T.
						nTerminal = 1
					ENDIF
				ELSE
					lInSymbol = .F.

					DO CASE
					CASE ch == ' ' OR ch == TAB
						nTerminal = 2

					CASE ch == '"' OR ch == '[' OR ch == "'"
						nTerminal = 1
						cEndQuote = IIF(ch == '[', ']', ch)
						lInQuote  = .T.

					CASE ch == '&' AND cLastCh == '&'
						nTerminal = 2
						EXIT

					CASE ch == ';'
						nTerminal = 1

					OTHERWISE
						nTerminal = 1

					ENDCASE
				ENDIF
			ENDIF
				
			IF nTerminal <> 0
				IF !EMPTY(cWord) AND nTokenCnt < MAX_TOKENS
					nTokenCnt = nTokenCnt + 1
					aTokens[nTokenCnt] = cWord
				ENDIF
				IF nTerminal <> 2
					cWord = ch
				ELSE
					cWord = ''
				ENDIF
				nTerminal = 0
			ELSE
				cWord = cWord + ch
			ENDIF
			cLastCh = ch
		ENDFOR

		IF nTerminal <> 2 AND !EMPTY(cWord) AND nTokenCnt < MAX_TOKENS
			nTokenCnt = nTokenCnt + 1
			aTokens[nTokenCnt] = cWord
		ENDIF
		
		RETURN nTokenCnt
	ENDFUNC

	* -- Given a code block, create list of definitions
	* -- Definitions are:
	* --   Class Definitions (DEFINE CLASS)
	* --   Procedures/Functions (FUNCTION/PROCEDURE)
	* --   Parameters (PARAMETERS/LPARAMETERS/Inline)
	* --   LOCAL/PUBLIC/PRIVATE/HIDDEN/PROTECTED declarations
	* --   #define
	FUNCTION FindDefinitions(cTextBlock, cClassName, cObjName, nSearchType)
		LOCAL i, j
		LOCAL nLineCnt
		LOCAL cProcName
		LOCAL nProcLineNo
		LOCAL nOffset
		LOCAL cDefType
		LOCAL cDefinition
		LOCAL nDefWordNum
		LOCAL cUpperDefinition
		LOCAL lInClassDef
		LOCAL nTokenCnt
		LOCAL nToken
		LOCAL cStopToken
		LOCAL lUseMemLines
		LOCAL nMemoWidth
		LOCAL cCodeLine
		LOCAL ARRAY aCodeList[1]
		LOCAL ARRAY aTokens[MAX_TOKENS]
		
		IF VARTYPE(m.cClassName) <> 'C'
			m.cClassName = ''
		ENDIF

		IF VARTYPE(m.cObjName) <> 'C'
			m.cObjName = ''
		ENDIF

		IF m.nSearchType == SEARCHTYPE_METHOD  && search in method code of .vcx or .scx
			m.nOffset = -1
		ELSE
			m.nOffset = 0
		ENDIF

		m.cProcName     = ''   && name of procedure/function we're in
		m.nProcLineNo   = 1
		m.lInClassDef   = .F.  && in a class definition?
		m.nTokenCnt     = 0
		m.cStopToken    = ''


		* ALINES should be faster, but we can't use that if
		* there are more than 65k lines in the code block
		m.lUseMemLines = .F.
		TRY
			m.nLineCnt = ALINES(aCodeList, m.cTextBlock, .F.)
		CATCH
			m.lUseMemLines = .T.
		ENDTRY
		
		IF m.lUseMemLines
			m.nMemoWidth = SET("MEMOWIDTH")
			SET MEMOWIDTH TO 8192
			m.nLineCnt = MEMLINES(m.cTextBlock)
			_MLINE = 0
		ENDIF

		
		FOR m.i = 1 TO m.nLineCnt
			IF m.lUseMemLines
				m.cCodeLine = MLINE(m.cTextBlock, 1, _MLINE)
			ELSE
				m.cCodeLine = aCodeList[m.i]
			ENDIF
			
		
			m.nTokenCnt = THIS.ParseLine(m.cCodeLine, @aTokens, m.nTokenCnt)
			IF m.nTokenCnt > 0 AND aTokens[m.nTokenCnt] == ';'
				m.nProcLineNo = m.nProcLineNo + 1
				m.nTokenCnt = m.nTokenCnt - 1
				LOOP
			ENDIF

			m.nToken = 0
			IF m.nTokenCnt > 1
				IF LENC(aTokens[1]) >= 4
					m.nStopToken = m.nTokenCnt
					m.cWord1 = UPPER(aTokens[1])
					m.cWord2 = UPPER(aTokens[2])

					DO CASE
					CASE m.nTokenCnt > 2 AND ("PROTECTED" = m.cWord1 OR "HIDDEN" = m.cWord1) AND (LENC(m.cWord2) >= 4 AND ("PROCEDURE" = m.cWord2 OR "FUNCTION" = m.cWord2))
						m.cProcName   = aTokens[3]
						m.nProcLineNo = 0
						m.lInClassDef = .F.
						m.cStopToken = ')'

						THIS.AddDefinition( ;
						  m.cProcName, ;
						  DEFTYPE_PROCEDURE, ;
						  m.cClassName, ;
						  m.cObjName + IIF(EMPTY(m.cObjName) OR EMPTY(m.cProcName), '', '.') + m.cProcName, ;
						  0, ;
						  m.i, ;
						  m.cCodeLine ;
						 )
						
						m.cDefType = DEFTYPE_PARAMETER
						m.nToken = 4
						m.cStopToken  = ')'

					CASE "PROCEDURE" = m.cWord1 OR "FUNCTION" = m.cWord1 
						m.cProcName   = aTokens[2]
						m.nProcLineNo = 0
						m.lInClassDef = .F.

						THIS.AddDefinition( ;
						  m.cProcName, ;
						  DEFTYPE_PROCEDURE, ;
						  m.cClassName, ;
						  m.cObjName + IIF(EMPTY(m.cObjName) OR EMPTY(m.cProcName), '', '.') + m.cProcName, ;
						  0, ;
						  m.i, ;
						  m.cCodeLine ;
						 )
						
						m.cDefType = DEFTYPE_PARAMETER
						m.nToken = 3
						m.cStopToken  = ')'

					CASE "ENDFUNC" = m.cWord1
						m.cProcName = ''
						m.nProcLineNo = 0
						m.lInClassDef = .F.

					CASE "ENDPROC" = m.cWord1
						m.cProcName   = ''
						m.nProcLineNo = 0
						m.lInClassDef = .F.

					CASE "LOCAL" = m.cWord1
						m.cDefType = DEFTYPE_LOCAL
						m.nToken = 2

					CASE "LPARAMETERS" = m.cWord1
						m.cDefType = DEFTYPE_PARAMETER
						m.lInClassDef = .F.
						m.nToken = 2

					CASE "PARAMETERS" = m.cWord1
						m.cDefType = DEFTYPE_PARAMETER
						m.lInClassDef = .F.
						m.nToken = 2

					CASE "PUBLIC" = m.cWord1
						m.cDefType = DEFTYPE_PUBLIC
						m.nToken = 2

					CASE "PRIVATE" = m.cWord1
						m.cDefType = DEFTYPE_PRIVATE
						m.nToken = 2

					CASE "HIDDEN" = m.cWord1
						m.cDefType = DEFTYPE_PROPERTY
						m.nToken = 2

					CASE "PROTECTED" = m.cWord1
						m.cDefType = DEFTYPE_PROPERTY
						m.nToken = 2

					CASE "DEFINE" = m.cWord1
						IF LENC(m.cWord2) >= 4 AND "CLASS" = m.cWord2 AND m.nTokenCnt > 2
							m.cClassName  = aTokens[3]
							m.cProcName   = ''
							m.nProcLineNo = 0
							m.lInClassDef = .T.

							m.cDefType = DEFTYPE_CLASS
							m.nToken = 3
							m.nStopToken = 3
							
							* if this is a "DEFINE CLASS <classname> AS <parentclass> OF <classlibrary>"
							* then add the class library to files to process
							IF m.nTokenCnt >= 7 AND UPPER(aTokens[6]) == "OF"
								* add to collection of files we found to process
								THIS.AddFileToProcess( ;
								  DEFTYPE_SETCLASSPROC, ;
								  aTokens[7], ;
								  m.cClassName, ;
								  m.cObjName + IIF(EMPTY(m.cObjName) OR EMPTY(m.cProcName), '', '.') + m.cProcName, ;
								  m.nProcLineNo, ;
								  m.i, ;
								  m.cCodeLine ;
								 )
							ENDIF
						ENDIF

					CASE "ENDDEFINE" = m.cWord1
						m.cClassName  = ''
						m.cProcName   = ''
						m.nProcLineNo = 0
						m.lInClassDef = .F.
						
					CASE m.lInClassDef AND ("DIMENSION" = m.cWord1 OR "DECLARE" = m.cWord1)
						m.cDefType = DEFTYPE_PROPERTY
						m.nToken = 2
						m.nStopToken = 2

					CASE m.lInClassDef AND aTokens[2] == '='
						* if we're in a class definition and we have an
						* assignment or DIMENSION/DECLARE statement, 
						* then that's a Property definition
						m.cDefType = DEFTYPE_PROPERTY
						m.nToken = 1
						m.nStopToken = 1
					ENDCASE
				ELSE
					DO CASE
					CASE aTokens[1] == "#" AND LENC(aTokens[2]) >= 4 AND "DEFINE" = UPPER(aTokens[2]) && #define
						m.cDefType = DEFTYPE_DEFINE
						m.nToken = 3
						m.nStopToken = 3

					CASE aTokens[1] == "#" AND LENC(aTokens[2]) >= 4 AND "INCLUDE" = UPPER(aTokens[2]) && #include
						* add to collection of files we found to process
						THIS.AddFileToProcess( ;
						  DEFTYPE_INCLUDEFILE, ;
						  aTokens[3], ;
						  m.cClassName, ;
						  m.cObjName + IIF(EMPTY(m.cObjName) OR EMPTY(m.cProcName), '', '.') + m.cProcName, ;
						  m.nProcLineNo, ;
						  m.i, ;
						  m.cCodeLine ;
						 )

					CASE UPPER(aTokens[1]) == "SET"
						m.cWord2 = UPPER(aTokens[2])
						* SET PROCEDURE TO <program> or SET CLASSLIB TO <classlibrary>
						IF LENC(m.cWord2) >= 4 AND m.nTokenCnt >= 4 AND UPPER(aTokens[3]) == "TO"
							DO CASE
							CASE "CLASSLIB" = m.cWord2 
								* add to collection of files we found to process
								THIS.AddFileToProcess( ;
								  DEFTYPE_SETCLASSPROC, ;
								  DEFAULTEXT(aTokens[4], "vcx"), ;
								  m.cClassName, ;
								  m.cObjName + IIF(EMPTY(m.cObjName) OR EMPTY(m.cProcName), '', '.') + m.cProcName, ;
								  m.nProcLineNo, ;
								  m.i, ;
								  m.cCodeLine ;
								 )

							CASE "PROCEDURE" = m.cWord2
								* SET PROCEDURE TO supports a comma-delimited list of filenames
								FOR m.j = 4 TO m.nTokenCnt
									IF LENC(aTokens[m.j]) >= 4 AND "ADDI" = UPPER(aTokens[m.j])
										EXIT
									ENDIF
									THIS.AddFileToProcess( ;
									  DEFTYPE_SETCLASSPROC, ;
									  DEFAULTEXT(aTokens[m.j], "prg"), ;
									  m.cClassName, ;
									  m.cObjName + IIF(EMPTY(m.cObjName) OR EMPTY(m.cProcName), '', '.') + m.cProcName, ;
									  m.nProcLineNo, ;
									  m.i, ;
									  m.cCodeLine ;
									 )
								ENDFOR
							ENDCASE
						ENDIF

					CASE m.lInClassDef AND aTokens[2] == '='
						* if we're in a class definition and we have an
						* assignment or DIMENSION/DECLARE statement, 
						* then that's a Property definition
						m.cDefType = DEFTYPE_PROPERTY
						m.nToken = 1
						m.nStopToken = 1
					ENDCASE
				ENDIF
			ENDIF

			* Grab all definitions from this line
			IF m.nToken > 0
				DO WHILE m.nToken <= m.nStopToken
					m.cDefinition= aTokens[m.nToken]

					IF m.cDefinition == m.cStopToken
						EXIT
					ENDIF

					IF ISALPHA(m.cDefinition) OR m.cDefinition = '_'
						m.cUpperDefinition = UPPER(m.cDefinition)

						DO CASE
						CASE m.cUpperDefinition == "ARRAY" OR m.cUpperDefinition == "ARRA"
							m.nToken = m.nToken + 1
							LOOP

						CASE m.cUpperDefinition == "AS" OR m.cUpperDefinition == "OF" OR (LENC(m.cUpperDefinition) >= 4 AND m.cUpperDefinition = "OLEPUBLIC")
							m.nToken = m.nToken + 2
							LOOP

						ENDCASE
							
						THIS.AddDefinition( ;
						  m.cDefinition, ;
						  m.cDefType, ;
						  IIF(m.cDefType == DEFTYPE_CLASS, '', m.cClassName), ;
						  m.cObjName + IIF(EMPTY(m.cObjName) OR EMPTY(m.cProcName), '', '.') + m.cProcName, ;
						  IIF(nSearchType == SEARCHTYPE_EXPR, 0, m.nProcLineNo + m.nOffset), ;
						  IIF(nSearchType == SEARCHTYPE_EXPR, 0, m.i), ;
						  m.cCodeLine ;
						 )

						IF m.cDefType == DEFTYPE_DEFINE && for a #DEFINE, only grab the word after the #DEFINE statement
							EXIT
						ENDIF
					ENDIF
					m.nToken = m.nToken + 1
				ENDDO
			ENDIF

			m.nProcLineNo = m.nProcLineNo + 1
			m.nTokenCnt = 0
		ENDFOR

		IF m.lUseMemLines
			SET MEMOWIDTH TO (m.nMemoWidth)
		ENDIF
		
	ENDFUNC


	* Abstract:
	*   Strip tabs, spaces from the beginning
	*	of a code line.
	*	This is necessary because LTRIM()
	*	does not handle tabs (only spaces)
	*
	FUNCTION StripTabs(cRefCode)
		RETURN ALLTRIM(CHRTRAN(RTRIM(m.cRefCode), TAB, ' '))
	ENDFUNC

	* compile a block of code and return the compiled 
	* version of it
	FUNCTION CompileCode(cCodeBlock)
		LOCAL cObjCode
		LOCAL cTempFile
		LOCAL cSafety

		cObjCode = .NULL.
		cTempFile = ADDBS(GETENV("TMP")) + RIGHTC(SYS(2015), 8)
		
		cSafety = SET("SAFETY")
		SET Safety OFF

		IF STRTOFILE(cCodeBlock, cTempFile + ".prg") > 0
			COMPILE (cTempFile + ".prg")
			cObjCode = FILETOSTR(cTempFile + ".fxp")
		ENDIF
		ERASE (cTempFile + ".prg")
		ERASE (cTempFile + ".fxp")
		
		SET Safety &cSafety)
		
		RETURN cObjCode
	ENDFUNC
ENDDEFINE

* Abstract...:
*	Search / Replace functionality for a database container (DBC).
*
* Changes....:
*
#include "foxref.h"
#include "foxpro.h"

DEFINE CLASS RefSearchDatabase AS RefSearch OF FoxRefSearch.prg
	Name = "RefSearchDatabase"

	* NoRefresh     = .T. && we must always re-search a database container
	BackupExtensions = "DBC,DCX,DCT"

	FUNCTION OpenFile(lReadWrite)
		LOCAL oError
		
		m.oError = .NULL.
		
		TRY
			IF m.lReadWrite
				OPEN DATABASE (THIS.Filename) EXCLUSIVE
			ELSE
				OPEN DATABASE (THIS.Filename) SHARED NOUPDATE
			ENDIF
		CATCH TO oError
		ENDTRY

		IF DBUSED(THIS.Filename)
			SET DATABASE TO (THIS.Filename)
		ENDIF

		RETURN m.oError
	ENDFUNC

	FUNCTION CloseFile()
		IF DBUSED(THIS.Filename)
			SET DATABASE TO (THIS.Filename)
			CLOSE DATABASES
		ENDIF
		
		RETURN .T.
	ENDFUNC


	FUNCTION DoSearch()
		LOCAL nSelect
		LOCAL nCnt
		LOCAL i
		LOCAL cTempFile
		LOCAL cSafety
		LOCAL lSuccess
		LOCAL cCode
		LOCAL lSuccess
		LOCAL cTableName
		LOCAL aDBList[1]

		m.nSelect = SELECT()

		m.cSafety = SET("SAFETY")
		SET SAFETY OFF

		* search database comment
		IF THIS.Comments <> COMMENTS_EXCLUDE
			THIS.FindInText(DBGETPROP(JUSTFNAME(THIS.Filename), "DATABASE", "Comment"), FINDTYPE_TEXT, '', DBC_COMMENT_LOC, SEARCHTYPE_NORMAL, '', "Comment")
		ENDIF

		* Search stored procedures
		m.cCode = ''
		m.cTempFile = ADDBS(SYS(2023)) + RIGHTC(SYS(2015), 8) + ".tmp"
		TRY
			* copy the stored procedure out to a text
			* file so we can search through it
			COPY PROCEDURES TO (m.cTempFile)
			m.cCode = FILETOSTR(m.cTempFile)
			ERASE (m.cTempFile)
		CATCH
		ENDTRY
		
		m.lSuccess = THIS.FindInCode(m.cCode, FINDTYPE_CODE, DBC_STOREDPROCEDURE_LOC, '', SEARCHTYPE_NORMAL, '', "StoredProcedure")
		IF m.lSuccess
			* Add tables in DBC to search list
			m.nCnt = ADBOBJECTS(aDBList, "TABLE")
			FOR m.i = 1 TO m.nCnt
				TRY
					m.cTableName = DBGETPROP(aDBList[m.i], "TABLE", "PATH")
					THIS.AddFileToSearch(FULLPATH(m.cTableName, ADDBS(THIS.Folder)))
				CATCH
					* ignore error (we might possibly get one on DBGETPROP)
				ENDTRY
				
			ENDFOR


			SET SAFETY &cSafety
			IF !THIS.CodeOnly
				* Search View properties
				m.nCnt = ADBOBJECTS(aDBList, "VIEW")
				FOR m.i = 1 TO m.nCnt
					THIS.FindInLine(aDBList[m.i], FINDTYPE_OTHER, aDBList[m.i], DBC_VIEWNAME_LOC, SEARCHTYPE_NORMAL, '', "ViewName", .T.)
					THIS.FindInLine(DBGETPROP(aDBList[m.i], "VIEW", "SQL"), FINDTYPE_OTHER, aDBList[m.i], DBC_VIEWSQL_LOC, SEARCHTYPE_NORMAL, '', "SQL", .T.)
					THIS.FindInLine(DBGETPROP(aDBList[m.i], "VIEW", "ParameterList"), FINDTYPE_OTHER, aDBList[m.i], DBC_VIEWPARAMETERS_LOC, SEARCHTYPE_NORMAL, '', "ParameterList", .T.)
					THIS.FindInLine(DBGETPROP(aDBList[m.i], "VIEW", "ConnectName"), FINDTYPE_OTHER, aDBList[m.i], DBC_VIEWCONNECTNAME_LOC, SEARCHTYPE_NORMAL, '', "ViewConnectName", .T.)
					THIS.FindInLine(DBGETPROP(aDBList[m.i], "VIEW", "RuleExpression"), FINDTYPE_EXPR, aDBList[m.i], DBC_VIEWRULEEXPR_LOC, SEARCHTYPE_NORMAL, '', "RuleExpression", .T.)
					THIS.FindInLine(DBGETPROP(aDBList[m.i], "VIEW", "RuleText"), FINDTYPE_OTHER, aDBList[m.i], DBC_VIEWRULETEXT_LOC, SEARCHTYPE_NORMAL, '', "RuleText", .T.)

					IF THIS.Comments <> COMMENTS_EXCLUDE
						THIS.FindInText(DBGETPROP(aDBList[m.i], "VIEW", "Comment"), FINDTYPE_TEXT, aDBList[m.i], DBC_VIEWCOMMENT_LOC, SEARCHTYPE_NORMAL, '', "Comment", .T.)
					ENDIF
				ENDFOR

				* Search Connection properties
				m.nCnt = ADBOBJECTS(aDBList, "CONNECTION")
				FOR m.i = 1 TO m.nCnt
					THIS.FindInText(aDBList[m.i], FINDTYPE_OTHER, aDBList[m.i], DBC_CONNECTNAME_LOC, SEARCHTYPE_NORMAL, '', "ConnectName", .T.)
					THIS.FindInText(DBGETPROP(aDBList[m.i], "CONNECTION", "ConnectString"), FINDTYPE_OTHER, aDBList[m.i], DBC_CONNECTSTRING_LOC, SEARCHTYPE_NORMAL, '', "ConnectString", .T.)
					THIS.FindInText(DBGETPROP(aDBList[m.i], "CONNECTION", "Database"), FINDTYPE_OTHER, aDBList[m.i], DBC_CONNECTDATABASE_LOC, SEARCHTYPE_NORMAL, '', "Database", .T.)
					THIS.FindInText(DBGETPROP(aDBList[m.i], "CONNECTION", "DataSource"), FINDTYPE_OTHER, aDBList[m.i], DBC_CONNECTDATASOURCE_LOC, SEARCHTYPE_NORMAL, '', "DataSource", .T.)
					THIS.FindInText(DBGETPROP(aDBList[m.i], "CONNECTION", "UserId"), FINDTYPE_OTHER, aDBList[m.i], DBC_CONNECTUSERID_LOC, SEARCHTYPE_NORMAL, '', "UserId", .T.)
					THIS.FindInText(DBGETPROP(aDBList[m.i], "CONNECTION", "PassWord"), FINDTYPE_OTHER, aDBList[m.i], DBC_CONNECTPASSWORD_LOC, SEARCHTYPE_NORMAL, '', "PassWord", .T.)

					IF THIS.Comments <> COMMENTS_EXCLUDE
						THIS.FindInText(DBGETPROP(aDBList[m.i], "CONNECTION", "Comment"), FINDTYPE_TEXT, aDBList[m.i], DBC_CONNECTCOMMENT_LOC, SEARCHTYPE_NORMAL, '', "Comment", .T.)
					ENDIF
				ENDFOR
			ENDIF
		ENDIF
		
		SELECT (nSelect)
		
		RETURN m.lSuccess
	ENDFUNC

	FUNCTION DoReplace(cReplaceText, oReplaceCollection AS Collection)
		LOCAL nSelect
		LOCAL nRecNo
		LOCAL cSafety
		LOCAL cCodeBlock
		LOCAL cTempFile
		LOCAL oError
		LOCAL cRefCode
		LOCAL cNewText
		LOCAL cColumn
		LOCAL cTable
		LOCAL cUpdField
		LOCAL oFoxRefRecord
		LOCAL oFoxRefReplace
		LOCAL i
		
		m.nSelect = SELECT()

		m.cLog = ''
		m.oError = .NULL.

		oFoxRefRecord = oReplaceCollection.Item(1)
		cRefCode  = oFoxRefRecord.Abstract
		cColumn   = RTRIM(oFoxRefRecord.ClassName)
		cTable    = JUSTSTEM(THIS.Filename)
		cUpdField = RTRIM(oFoxRefRecord.UpdField)
		cNewText  = cRefCode

		FOR m.i = oReplaceCollection.Count TO 1 STEP -1
			oFoxRefRecord = oReplaceCollection.Item(m.i)
			m.cNewText = THIS.ReplaceText(m.cNewText, oFoxRefRecord.LineNo, oFoxRefRecord.ColPos, oFoxRefRecord.MatchLen, m.cReplaceText, oFoxRefRecord.Abstract)
		ENDFOR

*!*			FOR EACH oFoxRefReplace IN oReplaceCollection
*!*				cNewText = THIS.ReplaceText(cNewText, oFoxRefReplace.LineNo, oFoxRefReplace.ColPos, oFoxRefReplace.MatchLen, cReplaceText, oFoxRefReplace.Abstract)
*!*			ENDFOR

		* only handle stored procedures in this version
		DO CASE
		CASE cUpdField == "Comment"
			TRY
				DBSETPROP(JUSTSTEM(THIS.Filename), "DATABASE", "Comment", cNewText)
			CATCH TO oError
			ENDTRY

		CASE cUpdField == "StoredProcedure"
			m.cSafety = SET("SAFETY")
			SET SAFETY OFF

			m.cTempFile = ADDBS(SYS(2023)) + RIGHTC(SYS(2015), 8) + ".tmp"
			TRY
				COPY PROCEDURES TO (m.cTempFile)
				m.cCodeBlock = FILETOSTR(m.cTempFile)
			CATCH TO oError
			ENDTRY

			IF ISNULL(m.oError)
				m.cCodeBlock = THIS.ReplaceText(m.cCodeBlock, m.oFoxRefRecord.LineNo, m.oFoxRefRecord.ColPos, m.oFoxRefRecord.MatchLen, m.cReplaceText, m.oFoxRefRecord.Abstract)
				IF !ISNULL(m.cCodeBlock)
					* write the code back out to our temp file so that we
					* can use APPEND PROCEDURES to get it back into our database
					TRY
						STRTOFILE(m.cCodeBlock, m.cTempFile, 0)
						APPEND PROCEDURES FROM (m.cTempFile) OVERWRITE
					CATCH TO oError
					ENDTRY
				ENDIF
			ENDIF


			ERASE (m.cTempFile)

			SET SAFETY &cSafety

		CASE cUpdField == "ViewName"
			* not supported
		CASE cUpdField == "SQL"
			* not supported
		CASE cUpdField == "ParameterList"
			* not supported
		CASE cUpdField == "ViewName"
			* not supported
		CASE cUpdField == "ViewConnectName"
			* not supported
		CASE cUpdField == "RuleExpr"
			* not supported
		CASE cUpdField == "RuleText"
			* not supported
		ENDCASE
			
		SELECT (m.nSelect)
		
		RETURN m.oError
	ENDFUNC

	
	FUNCTION DoReplaceLog(cReplaceText, oReplaceCollection)
		LOCAL cRefCode
		LOCAL cNewText
		LOCAL cColumn
		LOCAL cTable
		LOCAL cRuleExpr
		LOCAL cUpdField
		LOCAL cLog
		LOCAL oError
		LOCAL oFoxRefRecord
		LOCAL cDatabase

		m.cLog = ''
		m.oError = .NULL.

		oFoxRefRecord = oReplaceCollection.Item(1)
		cRefCode  = oFoxRefRecord.Abstract
		cColumn   = RTRIM(oFoxRefRecord.ClassName)
		cTable    = JUSTSTEM(THIS.Filename)
		cUpdField = RTRIM(oFoxRefRecord.UpdField)

		cNewText  = cRefCode
		FOR EACH oFoxRefRecord IN oReplaceCollection
			cNewText  = LEFTC(cNewText, oFoxRefRecord.ColPos - 1) + cReplaceText + SUBSTRC(cNewText, oFoxRefRecord.ColPos + oFoxRefRecord.MatchLen)
		ENDFOR

		DO CASE
		CASE cUpdField == "Comment"
		CASE cUpdField == "StoredProcedure"
		OTHERWISE
			m.cLog = LOG_PREFIX + REPLACE_NOTSUPPORTED_LOC
		ENDCASE


		RETURN m.cLog
	
	ENDFUNC

ENDDEFINE

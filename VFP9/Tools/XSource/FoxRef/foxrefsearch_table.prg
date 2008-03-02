* Abstract...:
*	Search / Replace functionality for a table (DBF).
*
* Changes....:
*
#include "foxref.h"
#include "foxpro.h"

DEFINE CLASS RefSearchTable AS RefSearch OF FoxRefSearch.prg
	Name = "RefSearchTable"

	NoRefresh        = .T. && we must always re-search a database container
	BackupExtensions = ''
	
	* if table is in a database, save the name of it
	* so we can close it later
	cDBCName = ''

	FUNCTION OpenFile(lReadWrite)
		LOCAL oError

		m.oError = .NULL.
		
		IF USED(TABLEFIND_ALIAS)
			USE IN (TABLEFIND_ALIAS)
		ENDIF
		
		TRY
			IF m.lReadWrite
				USE (THIS.Filename) ALIAS TABLEFIND_ALIAS IN 0 EXCLUSIVE
			ELSE
				USE (THIS.Filename) ALIAS TABLEFIND_ALIAS IN 0 SHARED AGAIN NOUPDATE
			ENDIF

		CATCH TO oError
		ENDTRY

		IF ISNULL(m.oError) AND USED(TABLEFIND_ALIAS)
			SELECT TABLEFIND_ALIAS

			THIS.cDBCName = JUSTSTEM(CURSORGETPROP("Database"))
			IF !EMPTY(THIS.cDBCName)
				TRY
					SET DATABASE TO (THIS.cDBCName)
				CATCH TO oError
					THIS.cDBCName = ''
				ENDTRY
			ENDIF
		ENDIF

		RETURN m.oError
	ENDFUNC
	
	FUNCTION CloseFile()
		IF EMPTY(THIS.cDBCName)
			IF USED(TABLEFIND_ALIAS)
				USE IN (TABLEFIND_ALIAS)
			ENDIF
		ELSE
			TRY
				SET DATABASE TO (THIS.cDBCName)
				CLOSE DATABASES
			CATCH
			ENDTRY
					
			THIS.cDBCName = ''
		ENDIF
		
		RETURN .T.
	ENDFUNC

	FUNCTION DoSearch()
		LOCAL nSelect
		LOCAL i
		LOCAL nCnt
		LOCAL lSuccess
		LOCAL ARRAY aFieldList[1]
		LOCAL ARRAY aTagList[1]

		m.nSelect = SELECT()
		
		m.lSuccess = .T.

		m.nCnt = AFIELDS(aFieldList, TABLEFIND_ALIAS)
		IF m.nCnt > 0
			IF !THIS.CodeOnly
				THIS.FindInLine(aFieldList[1, 12], FINDTYPE_NAME, DBF_TABLELONGNAME_LOC, '', SEARCHTYPE_EXPR, '', "LONGNAME", .T.)
			ENDIF


			FOR m.i = 1 TO m.nCnt
				IF !THIS.CodeOnly
					IF m.lSuccess
						m.lSuccess = THIS.FindInLine(aFieldList[m.i, 1], FINDTYPE_NAME, DBF_FIELDNAME_LOC, '', SEARCHTYPE_EXPR, '', "FIELDNAME", .T.)
					ENDIF
				ENDIF
				IF m.lSuccess
					m.lSuccess = THIS.FindInLine(aFieldList[m.i, 7], FINDTYPE_EXPR, aFieldList[m.i, 1], DBF_FIELDVALIDATIONEXPR_LOC, SEARCHTYPE_EXPR, '', "RULEEXPR")
				ENDIF

				IF m.lSuccess
					m.lSuccess = THIS.FindInLine(aFieldList[m.i, 8], FINDTYPE_OTHER, aFieldList[m.i, 1], DBF_FIELDVALIDATIONTEXT_LOC, SEARCHTYPE_EXPR, '', "RULETEXT")
				ENDIF
				IF m.lSuccess
					m.lSuccess = THIS.FindInLine(aFieldList[m.i, 9], FINDTYPE_EXPR, aFieldList[m.i, 1], DBF_DEFAULTVALUE_LOC, SEARCHTYPE_EXPR, '', "DEFAULTVAL")
				ENDIF
				IF THIS.Comments <> COMMENTS_EXCLUDE AND m.lSuccess
					* TO-DO: when AFIELDS is fixed to return the correct comment, then we'll uncomment this
					* Right now, AFIELDS is returning the table comment!
					* THIS.FindInText(aFieldList[m.i, 16], FINDTYPE_TEXT, m.cPattern, m.cFilename, aFieldList[m.i, 1], COMMENT_LOC, SEARCHTYPE_NORMAL, '', "COMMENT")
				ENDIF
				
				IF !m.lSuccess
					EXIT
				ENDIF
			ENDFOR

			IF m.lSuccess
				m.lSuccess = THIS.FindInLine(aFieldList[1, 10], FINDTYPE_EXPR, '', DBF_TABLEVALIDATIONEXPR_LOC, SEARCHTYPE_EXPR, '', "TABLEEXPR")
			ENDIF
			IF m.lSuccess
				m.lSuccess = THIS.FindInLine(aFieldList[1, 11], FINDTYPE_OTHER, '', DBF_TABLEVALIDATIONTEXT_LOC, SEARCHTYPE_EXPR, '', "TABLETEXT")
			ENDIF
			IF m.lSuccess
				m.lSuccess = THIS.FindInLine(aFieldList[1, 13], FINDTYPE_EXPR, '', DBF_INSERTTRIGGER_LOC, SEARCHTYPE_EXPR, '', "INSERTTRIG")
			ENDIF
			IF m.lSuccess
				m.lSuccess = THIS.FindInLine(aFieldList[1, 14], FINDTYPE_EXPR, '', DBF_UPDATETRIGGER_LOC, SEARCHTYPE_EXPR, '', "UPDATETRIG")
			ENDIF
			IF m.lSuccess
				m.lSuccess = THIS.FindInLine(aFieldList[1, 15], FINDTYPE_EXPR, '', DBF_DELETETRIGGER_LOC, SEARCHTYPE_EXPR, '', "DELETETRIG")
			ENDIF
		ENDIF
						
		SELECT (m.nSelect)
		
		RETURN m.lSuccess
	ENDFUNC

	FUNCTION DoReplace(cReplaceText, oReplaceCollection AS Collection)
		RETURN .NULL.

* NOT SUPPORTED
*!*			LOCAL cRefCode
*!*			LOCAL cNewText
*!*			LOCAL cColumn
*!*			LOCAL cDatabase
*!*			LOCAL cTable
*!*			LOCAL cRuleExpr
*!*			LOCAL cUpdField
*!*			LOCAL oError
*!*			LOCAL cCodeBlock
*!*			LOCAL oFoxRefRecord


*!*			m.oError = .NULL.

*!*			oFoxRefRecord = oReplaceCollection.Item(1)
*!*			cRefCode  = oFoxRefRecord.Abstract
*!*			cColumn   = RTRIM(oFoxRefRecord.ClassName)
*!*			cTable    = JUSTSTEM(THIS.Filename)
*!*			cUpdField = RTRIM(oFoxRefRecord.UpdField)
*!*			cNewText  = cRefCode

*!*			IF cUpdField = "COMMENT" OR cUpdField = "TBLCOMMENT"
*!*				FOR EACH oFoxRefRecord IN oReplaceCollection
*!*					cNewText = THIS.ReplaceText(cNewText, oFoxRefRecord.LineNo, oFoxRefRecord.ColPos, oFoxRefRecord.MatchLen, cReplaceText, oFoxRefRecord.Abstract)
*!*				ENDFOR
*!*			ELSE
*!*				FOR EACH oFoxRefRecord IN oReplaceCollection
*!*					cNewText  = LEFTC(cNewText, oFoxRefRecord.ColPos - 1) + cReplaceText + SUBSTR(cNewText, oFoxRefRecord.ColPos + oFoxRefRecord.MatchLen)
*!*				ENDFOR
*!*			ENDIF

*!*			IF ISNULL(m.oError)
*!*				TRY
*!*					DO CASE
*!*					CASE cUpdField = "COMMENT"
*!*						IF !ISNULL(cNewText)
*!*							DBSETPROP(cTable + '.' + cColumn, "FIELD", "Comment", cNewText)
*!*						ENDIF

*!*					CASE cUpdField = "TBLCOMMENT"
*!*						IF !ISNULL(cNewText)
*!*							DBSETPROP(cTable, "TABLE", "Comment", cNewText)
*!*						ENDIF

*!*					CASE cUpdField = "FIELDNAME"
*!*						ALTER TABLE (THIS.Filename) RENAME COLUMN (cRefCode) TO (cNewText)

*!*					CASE cUpdField = "RULEEXPR"
*!*						ALTER TABLE (THIS.Filename) ALTER COLUMN (cColumn) SET CHECK &cNewText

*!*					CASE cUpdField = "RULETEXT"
*!*						cRuleExpr = DBGETPROP(cTable + '.' + cColumn, "FIELD", "RuleExpression")
*!*						ALTER TABLE (THIS.Filename) ALTER COLUMN (cColumn) SET CHECK &cRuleExpr ERROR &cNewText

*!*					CASE cUpdField = "DEFAULTVAL"
*!*						ALTER TABLE (THIS.Filename) ALTER COLUMN (cColumn) SET DEFAULT &cNewText


*!*					CASE cUpdField = "TABLEEXPR"
*!*						ALTER TABLE (THIS.Filename) SET CHECK &cNewText

*!*					CASE cUpdField = "TABLETEXT"
*!*						cRuleExpr = DBGETPROP(cTable, "FIELD", "RuleExpression")
*!*						ALTER TABLE (THIS.Filename) SET CHECK &cRuleExpr ERROR &cNewText

*!*					CASE cUpdField = "INSERTTRIG"
*!*						CREATE TRIGGER ON (THIS.Filename) FOR INSERT AS &cNewText

*!*					CASE cUpdField = "UPDATETRIG"
*!*						CREATE TRIGGER ON (THIS.Filename) FOR UPDATE AS &cNewText

*!*					CASE cUpdField = "DELETETRIG"
*!*						CREATE TRIGGER ON (THIS.Filename) FOR DELETE AS &cNewText

*!*					CASE cUpdField = "LONGNAME"
*!*					ENDCASE

*!*				CATCH TO oError
*!*				ENDTRY

*!*			ENDIF

*!*					
*!*			RETURN m.oError
	ENDFUNC

	FUNCTION DoReplaceLog(cReplaceText, oReplaceCollection AS Collection)
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

		m.oFoxRefRecord = m.oReplaceCollection.Item(1)
		m.cRefCode  = m.oFoxRefRecord.Abstract
		m.cColumn   = RTRIM(oFoxRefRecord.ClassName)
		m.cTable    = JUSTSTEM(THIS.Filename)
		m.cUpdField = RTRIM(m.oFoxRefRecord.UpdField)
		m.cNewText  = m.cRefCode

		IF cUpdField = "COMMENT" OR cUpdField = "TBLCOMMENT"
			FOR EACH oFoxRefRecord IN oReplaceCollection
				cNewText = THIS.ReplaceText(cNewText, oFoxRefRecord.LineNo, oFoxRefRecord.ColPos, oFoxRefRecord.MatchLen, cReplaceText, oFoxRefRecord.Abstract)
			ENDFOR
		ELSE
			m.cLog = m.cLog + IIF(EMPTY(m.cLog), '', CHR(13) + CHR(10)) + LOG_PREFIX + REPLACE_NOTSUPPORTED_LOC
			FOR EACH oFoxRefRecord IN oReplaceCollection
				cNewText  = LEFTC(cNewText, oFoxRefRecord.ColPos - 1) + cReplaceText + SUBSTR(cNewText, oFoxRefRecord.ColPos + oFoxRefRecord.MatchLen)
			ENDFOR
		ENDIF



		TRY
			DO CASE
			CASE cUpdField = "FIELDNAME"
				m.cLog = m.cLog + IIF(EMPTY(m.cLog), '', CHR(13) + CHR(10)) + [ALTER TABLE ] + THIS.Filename +  [ RENAME COLUMN ] + cRefCode + [ TO ] + cNewText

			CASE cUpdField = "RULEEXPR"
				m.cLog = m.cLog + IIF(EMPTY(m.cLog), '', CHR(13) + CHR(10)) + [ALTER TABLE ] + THIS.Filename + [ ALTER COLUMN ] + cColumn + [ SET CHECK ] + cNewText

			CASE cUpdField = "RULETEXT"
				cRuleExpr = DBGETPROP(m.cTable + '.' + cColumn, "FIELD", "RuleExpression")
				m.cLog = m.cLog + IIF(EMPTY(m.cLog), '', CHR(13) + CHR(10)) + [ALTER TABLE ] + THIS.Filename + [ ALTER COLUMN ] + cColumn + [ SET CHECK ] + cRuleExpr + [ ERROR ] + cNewText

			CASE cUpdField = "DEFAULTVAL"
				m.cLog = m.cLog + IIF(EMPTY(m.cLog), '', CHR(13) + CHR(10)) + [ALTER TABLE ] + THIS.Filename + [ ALTER COLUMN ] + cColumn + [ SET DEFAULT ] + cNewText

			CASE cUpdField = "COMMENT"
				cNewText = THIS.ReplaceText(cRefCode, oFoxRefRecord.LineNo, oFoxRefRecord.ColPos, oFoxRefRecord.MatchLen, cReplaceText, oFoxRefRecord.Abstract)
				IF !ISNULL(cNewText)
					m.cLog = m.cLog + IIF(EMPTY(m.cLog), '', CHR(13) + CHR(10)) + [DBSETPROP(] + m.cTable + '.' + cColumn + [, "FIELD", "Comment", ] + cNewText + [)]
				ENDIF

			CASE cUpdField = "TABLEEXPR"
				m.cLog = m.cLog + IIF(EMPTY(m.cLog), '', CHR(13) + CHR(10)) + [ALTER TABLE (] + THIS.Filename+ [) SET CHECK ] + cNewText

			CASE cUpdField = "TABLETEXT"
				cRuleExpr = DBGETPROP(m.cTable, "FIELD", "RuleExpression")
				m.cLog = m.cLog + IIF(EMPTY(m.cLog), '', CHR(13) + CHR(10)) + [ALTER TABLE (] + THIS.Filename + [ SET CHECK ] + cRuleExpr + [ ERROR ] + cNewText

			CASE cUpdField = "INSERTTRIG"
				m.cLog = m.cLog + IIF(EMPTY(m.cLog), '', CHR(13) + CHR(10)) + [CREATE TRIGGER ON ] + THIS.Filename + [ FOR INSERT AS ] + cNewText

			CASE cUpdField = "UPDATETRIG"
				m.cLog = m.cLog + IIF(EMPTY(m.cLog), '', CHR(13) + CHR(10)) + [CREATE TRIGGER ON ] + THIS.Filename+ [ FOR UPDATE AS ] + cNewText

			CASE cUpdField = "DELETETRIG"
				m.cLog = m.cLog + IIF(EMPTY(m.cLog), '', CHR(13) + CHR(10)) + [CREATE TRIGGER ON ] + THIS.Filename + [ FOR DELETE AS ] + cNewText

			CASE cUpdField = "TBLCOMMENT"
				cNewText = THIS.ReplaceText(cRefCode, oFoxRefRecord.LineNo, oFoxRefRecord.ColPos, oFoxRefRecord.MatchLen, cReplaceText, oFoxRefRecord.Abstract)
				IF !ISNULL(cNewText)
					m.cLog = m.cLog + IIF(EMPTY(m.cLog), '', CHR(13) + CHR(10)) + [DBSETPROP(] + m.cTable + [, "TABLE", "Comment", ] + cNewText + [)]
				ENDIF

			CASE cUpdField = "LONGNAME"
			ENDCASE

		CATCH TO oError
		ENDTRY
	
		RETURN m.cLog
	ENDFUNC

ENDDEFINE

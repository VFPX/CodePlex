* Abstract...:
*	Search / Replace functionality for a Report or Label (FRX, LBX).
*
* Changes....:
*
#include "foxref.h"
#include "foxpro.h"

* -- Find in expressions or dataenvironment of a report (FRX)
DEFINE CLASS RefSearchReport AS RefSearch OF FoxRefSearch.prg
	Name = "RefSearchReport"

	NoRefresh        = .F.
	BackupExtensions = "FRX,FRT"

	FUNCTION OpenFile(lReadWrite)
		LOCAL oError
		
		m.oError = .NULL.
		
		IF USED(TABLEFIND_ALIAS)
			USE IN (TABLEFIND_ALIAS)
		ENDIF
		
		TRY
			IF m.lReadWrite
				USE (THIS.Filename) ALIAS TABLEFIND_ALIAS IN 0 SHARED AGAIN
			ELSE
				USE (THIS.Filename) ALIAS TABLEFIND_ALIAS IN 0 SHARED AGAIN NOUPDATE
			ENDIF
		CATCH TO oError
		ENDTRY

		IF ISNULL(m.oError) AND USED(TABLEFIND_ALIAS)
			TRY
				&& only process if Expr, Platform, and UniqueID fields exist
				IF ;
				 TYPE(TABLEFIND_ALIAS + ".Expr") == 'M' AND ;
				 TYPE(TABLEFIND_ALIAS + ".Platform") == 'C' AND ;
				 TYPE(TABLEFIND_ALIAS + ".UniqueID") == 'C'
					SELECT TABLEFIND_ALIAS
				ELSE
					USE IN (TABLEFIND_ALIAS)
					THROW ERROR_NOTREPORT_LOC
				ENDIF

			CATCH TO oError WHEN oError.ErrorNo == 2071
			CATCH TO oError
			ENDTRY
		ENDIF

		RETURN m.oError
	ENDFUNC
	
	FUNCTION CloseFile()
		IF USED(TABLEFIND_ALIAS)
			USE IN (TABLEFIND_ALIAS)
		ENDIF
		
		RETURN .T.
	ENDFUNC

	FUNCTION DoDefinitions()
		LOCAL nSelect
		LOCAL cObjType

		m.nSelect = SELECT()

		SELECT TABLEFIND_ALIAS
		SCAN ALL FOR Platform = "WINDOWS" AND ObjType == RPTTYPE_DATAENV
			* THIS.TimeStamp = TimeStamp

			* Data Environment code
			THIS.FindDefinitions(Tag, OBJECTTYPE_DATAENV_LOC, '', SEARCHTYPE_NORMAL)
		ENDSCAN
		
		SELECT (m.nSelect)
	ENDFUNC
	

	FUNCTION DoSearch()
		LOCAL nSelect
		LOCAL cObjType
		LOCAL lSuccess

		m.nSelect = SELECT()
		
		m.lSuccess = .T.

		SELECT TABLEFIND_ALIAS
		SCAN ALL FOR Platform = "WINDOWS"
			DO CASE
			CASE ObjType == RPTTYPE_HEADER
				cObjType = OBJECTTYPE_HEADER_LOC
			CASE ObjType == RPTTYPE_DBF
				cObjType = OBJECTTYPE_DBF_LOC
			CASE ObjType == RPTTYPE_INDEX
				cObjType = OBJECTTYPE_INDEX_LOC
			CASE ObjType == RPTTYPE_RELATION
				cObjType = OBJECTTYPE_RELATION_LOC
			CASE ObjType == RPTTYPE_LABEL
				cObjType = OBJECTTYPE_LABEL_LOC
			CASE ObjType == RPTTYPE_LINE
				cObjType = OBJECTTYPE_LINE_LOC
			CASE ObjType == RPTTYPE_BOX
				cObjType = OBJECTTYPE_BOX_LOC
			CASE ObjType == RPTTYPE_GET
				cObjType = OBJECTTYPE_GET_LOC
			CASE ObjType == RPTTYPE_BAND
				DO CASE
				CASE ObjCode == RPTCODE_TITLE
					cObjType = OBJECTTYPE_TITLE_LOC
				CASE ObjCode == RPTCODE_PGHEAD
					cObjType = OBJECTTYPE_PGHEAD_LOC
				CASE ObjCode == RPTCODE_COLHEAD
					cObjType = OBJECTTYPE_COLHEAD_LOC
				CASE ObjCode == RPTCODE_GRPHEAD
					cObjType = OBJECTTYPE_GRPHEAD_LOC
				CASE ObjCode == RPTCODE_DETAIL
					cObjType = OBJECTTYPE_DETAIL_LOC
				CASE ObjCode == RPTCODE_GRPFOOT
					cObjType = OBJECTTYPE_GRPFOOT_LOC
				CASE ObjCode == RPTCODE_COLFOOT
					cObjType = OBJECTTYPE_COLFOOT_LOC
				CASE ObjCode == RPTCODE_PGFOOT
					cObjType = OBJECTTYPE_PGFOOT_LOC
				CASE ObjCode == RPTCODE_SUMMARY
					cObjType = OBJECTTYPE_SUMMARY_LOC
				OTHERWISE
					cObjType = OBJECTTYPE_BAND_LOC
				ENDCASE

			CASE ObjType == RPTTYPE_GROUP
				cObjType = OBJECTTYPE_GROUP_LOC
			CASE ObjType == RPTTYPE_PICTURE
				cObjType = OBJECTTYPE_PICTURE_LOC
			CASE ObjType == RPTTYPE_VAR
				cObjType = OBJECTTYPE_VAR_LOC
			CASE ObjType == RPTTYPE_FONT
				cObjType = OBJECTTYPE_FONT_LOC
			CASE ObjType == RPTTYPE_DATAENV
				cObjType = OBJECTTYPE_DATAENV_LOC
			CASE ObjType == RPTTYPE_DERECORD
				cObjType = OBJECTTYPE_DERECORD_LOC
			OTHERWISE
				cObjType = OBJECTTYPE_UNKNOWN_LOC
			ENDCASE

			DO CASE
			CASE ObjType == RPTTYPE_HEADER
			CASE INLIST(ObjType, RPTTYPE_LABEL, RPTTYPE_LINE, RPTTYPE_BOX, RPTTYPE_PICTURE)
				IF !THIS.CodeOnly
					m.lSuccess = THIS.FindInLine(Expr, FINDTYPE_EXPR, cObjType, EXPRESSION_LOC, SEARCHTYPE_EXPR, UniqueID, "EXPR")
				ENDIF
				IF m.lSuccess
					m.lSuccess = THIS.FindInLine(SupExpr, FINDTYPE_EXPR, cObjType, FRX_PRINTONLYWHEN_LOC, SEARCHTYPE_EXPR, UniqueID, "SUPEXPR")
				ENDIF
				
			CASE ObjType == RPTTYPE_GET
				m.lSuccess = THIS.FindInLine(Expr, FINDTYPE_EXPR, cObjType, EXPRESSION_LOC, SEARCHTYPE_EXPR, UniqueID, "EXPR")
				IF m.lSuccess
					m.lSuccess = THIS.FindInLine(SupExpr, FINDTYPE_EXPR, cObjType, FRX_PRINTONLYWHEN_LOC, SEARCHTYPE_EXPR, UniqueID, "SUPEXPR")
				ENDIF

			CASE ObjType == RPTTYPE_BAND
			
				* OnEntry
				m.lSuccess = THIS.FindInLine(Tag, FINDTYPE_EXPR, cObjType, FRX_ONENTRYEXPR_LOC, SEARCHTYPE_EXPR, UniqueID, "TAG")
				* OnExit
				IF m.lSuccess
					m.lSuccess = THIS.FindInLine(Tag2, FINDTYPE_EXPR, cObjType, FRX_ONEXITEXPR_LOC, SEARCHTYPE_EXPR, UniqueID, "TAG2")
				ENDIF

				IF ObjCode == RPTCODE_GRPHEAD AND m.lSuccess
					m.lSuccess = THIS.FindInLine(Expr, FINDTYPE_EXPR, cObjType, EXPRESSION_LOC, SEARCHTYPE_EXPR, UniqueID, "EXPR")
				ENDIF

			CASE ObjType == RPTTYPE_VAR
				m.lSuccess = THIS.FindInLine(Name, FINDTYPE_EXPR, cObjType, NAME_LOC, SEARCHTYPE_EXPR, UniqueID, "NAME")
				IF m.lSuccess
					m.lSuccess = THIS.FindInLine(Expr, FINDTYPE_EXPR, cObjType, EXPRESSION_LOC, SEARCHTYPE_EXPR, UniqueID, "EXPR")
				ENDIF

			CASE ObjType == RPTTYPE_DATAENV
				* Data Environment code
				m.lSuccess = THIS.FindInCode(Tag, FINDTYPE_CODE, cObjType, '', SEARCHTYPE_NORMAL, "DATAENV", "TAG")
				
			ENDCASE

			IF THIS.Comments <> COMMENTS_EXCLUDE AND m.lSuccess
				m.lSuccess = THIS.FindInText(Comment, FINDTYPE_TEXT, cObjType, COMMENT_LOC, SEARCHTYPE_NORMAL, UniqueID, "COMMENT")
			ENDIF

		ENDSCAN
		
		SELECT (m.nSelect)
		
		RETURN m.lSuccess
	ENDFUNC

	FUNCTION DoReplace(cReplaceText, oReplaceCollection AS Collection)
		LOCAL cRefCode
		LOCAL cNewText
		LOCAL cColumn
		LOCAL cDatabase
		LOCAL cTable
		LOCAL cRuleExpr
		LOCAL cUpdField
		LOCAL oError
		LOCAL cCodeBlock
		LOCAL oFoxRefRecord
		LOCAL nSelect
		LOCAL cRecordID
		LOCAL i

		m.oError = .NULL.

		oFoxRefRecord = oReplaceCollection.Item(1)
		cRefCode  = oFoxRefRecord.Abstract
		cColumn   = oFoxRefRecord.ClassName
		cTable    = JUSTSTEM(THIS.Filename)
		cUpdField = RTRIM(oFoxRefRecord.UpdField)
		cRecordID = RTRIM(oFoxRefRecord.RecordID)
		cNewText  = cRefCode

		FOR m.i = oReplaceCollection.Count TO 1 STEP -1
			oFoxRefRecord = oReplaceCollection.Item(m.i)
			m.cNewText = THIS.ReplaceText(m.cNewText, oFoxRefRecord.LineNo, oFoxRefRecord.ColPos, oFoxRefRecord.MatchLen, m.cReplaceText, oFoxRefRecord.Abstract)
		ENDFOR

*!*			FOR EACH oFoxRefRecord IN oReplaceCollection
*!*				cNewText = THIS.ReplaceText(cNewText, oFoxRefRecord.LineNo, oFoxRefRecord.ColPos, oFoxRefRecord.MatchLen, cReplaceText, oFoxRefRecord.Abstract)
*!*			ENDFOR

		m.nSelect = SELECT()

		TRY
			IF ISNULL(cNewText)
				THROW ERROR_REPLACE_LOC
			ELSE
				SELECT TABLEFIND_ALIAS
				IF cRecordID == "DATAENV"
					LOCATE FOR ObjType == RPTTYPE_DATAENV
					cUpdField = "Tag"
				ELSE
					LOCATE FOR UniqueID = cRecordID
				ENDIF
				IF FOUND()
					REPLACE (cUpdField) WITH cNewText

					IF !EMPTY(TimeStamp)
						REPLACE TimeStamp WITH THIS.RowTimeStamp() IN TABLEFIND_ALIAS
					ENDIF
				ELSE
					THROW ERROR_REPLACE_LOC
				ENDIF
			ENDIF
		CATCH TO oError
		ENDTRY
		
		SELECT (m.nSelect)
		
		RETURN m.oError
	ENDFUNC
ENDDEFINE

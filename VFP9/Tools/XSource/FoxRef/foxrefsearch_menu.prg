* Abstract...:
*	Search / Replace functionality for a menu (mnx).
*
* Changes....:
*
#include "foxref.h"
#include "foxpro.h"

DEFINE CLASS RefSearchMenu AS RefSearch OF FoxRefSearch.prg
	Name = "RefSearchMenu"

	NoRefresh        = .F.
	BackupExtensions = "MNX,MNT"

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

		IF !ISNULL(m.oError) AND USED(TABLEFIND_ALIAS)
			TRY
				IF TYPE(TABLEFIND_ALIAS + ".ObjType") == 'N'
					SELECT TABLEFIND_ALIAS
				ELSE
					USE IN (TABLEFIND_ALIAS)
					THROW ERROR_NOTMENU_LOC
				ENDIF

			CATCH TO oError WHEN oError.ErrorNo == 2071
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

	FUNCTION DoSearch()
		LOCAL nSelect
		LOCAL cMenuName
		LOCAL cUniqueID
		LOCAL lSuccess


		nSelect = SELECT()

		m.lSuccess = .T.

		SELECT (TABLEFIND_ALIAS)
		SCAN ALL
			m.cMenuName = RTRIM(IIF(EMPTY(Name), Prompt, Name))

			cUniqueID = TRANSFORM(RECNO())
			IF !THIS.CodeOnly
				m.lSuccess = THIS.FindInLine(Name, FINDTYPE_NAME, MNX_NAME_LOC, '', SEARCHTYPE_NORMAL, cUniqueID, "Name")
			ENDIF
			
			IF m.lSuccess
				m.lSuccess = THIS.FindInText(Prompt, FINDTYPE_TEXT, m.cMenuName, MNX_PROMPT_LOC, SEARCHTYPE_NORMAL, cUniqueID, "Prompt")
			ENDIF

			IF m.lSuccess
				m.lSuccess = THIS.FindInLine(Command, FINDTYPE_EXPR, m.cMenuName, MNX_COMMAND_LOC, SEARCHTYPE_NORMAL, cUniqueID, "Command")
			ENDIF
			IF m.lSuccess
				m.lSuccess = THIS.FindInLine(Message, FINDTYPE_EXPR, m.cMenuName, MNX_MESSAGE_LOC, SEARCHTYPE_NORMAL, cUniqueID, "Message")
			ENDIF
			IF m.lSuccess
				m.lSuccess = THIS.FindInCode(Procedure, FINDTYPE_CODE, m.cMenuName, MNX_PROCEDURE_LOC, SEARCHTYPE_NORMAL, cUniqueID, "Procedure")
			ENDIF
			IF m.lSuccess
				m.lSuccess = THIS.FindInCode(Setup, FINDTYPE_CODE, m.cMenuName, MNX_SETUP_LOC, SEARCHTYPE_NORMAL, cUniqueID, "Setup")
			ENDIF
			IF m.lSuccess
				m.lSuccess = THIS.FindInCode(Cleanup, FINDTYPE_CODE, m.cMenuName, MNX_CLEANUP_LOC, SEARCHTYPE_NORMAL, cUniqueID, "Cleanup")
			ENDIF
			IF m.lSuccess
				m.lSuccess = THIS.FindInLine(SkipFor, FINDTYPE_EXPR, m.cMenuName, MNX_SKIPFOR_LOC, SEARCHTYPE_NORMAL, cUniqueID, "SkipFor")
			ENDIF
			IF TYPE("ResName") == 'C' AND m.lSuccess  && older menus don't have this field
				m.lSuccess = THIS.FindInText(ResName, FINDTYPE_OTHER, m.cMenuName, MNX_RESOURCE_LOC, SEARCHTYPE_NORMAL, cUniqueID, "ResName")
			ENDIF
			IF THIS.Comments <> COMMENTS_EXCLUDE AND m.lSuccess
				m.lSuccess = THIS.FindInText(Comment, FINDTYPE_TEXT, m.cMenuName, MNX_COMMENT_LOC, SEARCHTYPE_NORMAL, cUniqueID, "Comment")
			ENDIF
		ENDSCAN
		
		SELECT (nSelect)
		
		RETURN m.lSuccess
	ENDFUNC

	FUNCTION DoReplace(cReplaceText AS String, oFoxRefRecord)
		LOCAL nSelect
		LOCAL cUpdField
		LOCAL oError
		LOCAL cCodeBlock
		LOCAL nRecordNo
		
		m.oError = .NULL.

		m.nSelect = SELECT()
		
		m.nRecordNo = VAL(oFoxRefRecord.RecordID)

		SELECT TABLEFIND_ALIAS
		IF BETWEEN(m.nRecordNo, 1, RECCOUNT())
			TRY
				GOTO (m.nRecordNo)
				m.cUpdField = RTRIM(oFoxRefRecord.UpdField)
				m.cCodeBlock = THIS.ReplaceText(EVALUATE(m.cUpdField), oFoxRefRecord.LineNo, oFoxRefRecord.ColPos, oFoxRefRecord.MatchLen, m.cReplaceText, oFoxRefRecord.Abstract)
				IF ISNULL(cCodeBlock)
					THROW ERROR_REPLACE_LOC
				ELSE
					REPLACE (cUpdField) WITH cCodeBlock
				ENDIF

			CATCH TO oError
			ENDTRY
		ENDIF
		
		SELECT (m.nSelect)
		
		RETURN m.oError
	ENDFUNC
ENDDEFINE

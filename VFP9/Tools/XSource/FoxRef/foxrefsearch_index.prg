* Abstract...:
*	Search / Replace functionality for an index (currently CDX only)
*
* Changes....:
*
#include "foxref.h"
#include "foxpro.h"

DEFINE CLASS RefSearchIndex AS RefSearch OF FoxRefSearch.prg
	Name = "RefSearchIndex"

	NoRefresh        = .F.
	BackupExtensions = ''
	
	* if table is in a database, save the name of it
	* so we can close it later
	cDBCName = ''

	FUNCTION OpenFile(lReadWrite)
		LOCAL cTableName
		LOCAL oError

		m.oError = .NULL.

		IF USED(TABLEFIND_ALIAS)
			USE IN (TABLEFIND_ALIAS)
		ENDIF

		m.cTableName = FORCEEXT(THIS.Filename, "DBF")
		
		TRY
			IF m.lReadWrite
				USE (m.cTableName) ALIAS TABLEFIND_ALIAS IN 0 SHARED AGAIN
			ELSE
				USE (m.cTableName) ALIAS TABLEFIND_ALIAS IN 0 SHARED AGAIN NOUPDATE
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
		LOCAL ARRAY aTagList[1]

		m.nSelect = SELECT()

		m.lSuccess = .T.

		* search CDX
		m.nCnt = ATAGINFO(m.aTagList, '', TABLEFIND_ALIAS)
		FOR m.i = 1 TO m.nCnt
			* tag name
			IF !THIS.CodeOnly
				m.lSuccess = THIS.FindInLine(aTagList[m.i, 1], FINDTYPE_OTHER, DBF_TAGNAME_LOC, '', SEARCHTYPE_EXPR, '', "TAGNAME", .T.)
			ENDIF

			* index expression
			IF m.lSuccess
				m.lSuccess = THIS.FindInLine(aTagList[m.i, 3], FINDTYPE_EXPR, aTagList[m.i, 1], DBF_TAGEXPR_LOC, SEARCHTYPE_EXPR, '', "TAGEXPR", .T.)
			ENDIF
					
			* index filter
			IF m.lSuccess
				m.lSuccess = THIS.FindInLine(aTagList[m.i, 4], FINDTYPE_EXPR, aTagList[m.i, 1], DBF_TAGFILTER_LOC, SEARCHTYPE_EXPR, '', "TAGFILTER", .T.)
			ENDIF
		ENDFOR
				
		SELECT (m.nSelect)
		
		RETURN m.lSuccess
	ENDFUNC

	FUNCTION DoReplace(cReplaceText, oFoxRefRecord)
		* no replacements allowed for an index
		
		RETURN .NULL.
	ENDFUNC
ENDDEFINE

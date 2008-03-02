* Abstract...:
*	Search functionality for an open window.
*
* Changes....:
*
#include "foxref.h"
#include "foxpro.h"

DEFINE CLASS RefSearchWindow AS RefSearch OF FoxRefSearch.prg
	Name = "RefSearchWindow"

	FileID = "WINDOW"
	WindowHandle = -1


	PROCEDURE Init()
	ENDPROC

	PROCEDURE Filename_Assign(cFilename)
		THIS.Filename = cFilename
	ENDPROC

	* no file to really open, but we can
	* read textfrom the underlying window
	FUNCTION OpenFile(lReadWrite)
		* grab the top-most window now before any other windows take its place
		LOCAL cFoxToolsLibary
		LOCAL nWindowHandle
		LOCAL nRetCode
		LOCAL lLibraryOpen
 		LOCAL ARRAY aEdEnv[25]

		DoDefault()

		IF ATC("FOXTOOLS.FLL", SET("LIBRARY")) == 0
			m.lLibraryOpen = .F.
			m.cFoxtoolsLibrary = SYS(2004) + "FOXTOOLS.FLL"
			IF !FILE(m.cFoxToolsLibrary)
				MessageBox(ERROR_FOXTOOLS_LOC, MB_ICONEXCLAMATION, APPNAME_LOC)
				RETURN .F.
			ENDIF

			SET LIBRARY TO (m.cFoxToolsLibrary) ADDITIVE
		ELSE
			m.lLibraryOpen = .T.
		ENDIF

		IF THIS.WindowHandle >= 0
			m.nWindowHandle = THIS.WindowHandle
		ELSE
			m.nWindowHandle = _wontop()
			THIS.Filename = _WTITLE(m.nWindowHandle)
		ENDIF
		IF m.nWindowHandle >= 0
			* we have a window handle, now grab the text

			* Check environment of window
			* get the length of the window
			m.nRetCode = _edgetenv(m.nWindowHandle, @aEdEnv)
			IF m.nRetCode == 1 && AND (aEdEnv[EDENV_LENGTH] == 0)
				IF aEdEnv[EDENV_LENGTH] > 0
					THIS.cFileText = _EdGetStr(m.nWindowHandle, 0, aEdEnv[EDENV_LENGTH] - 1)
				ENDIF
			ENDIF
		ENDIF
		
		IF !m.lLibraryOpen
			RELEASE LIBRARY (m.cFoxToolsLibrary)
		ENDIF
		
		RETURN .T.
	ENDFUNC

	FUNCTION DoSearch()
		IF THIS.OpenFile()
			RETURN THIS.FindInCode(THIS.cFileText, FINDTYPE_WINDOW, '', '', SEARCHTYPE_NORMAL, '', '', .T.)
		ELSE
			RETURN .T.
		ENDIF
	ENDFUNC

	FUNCTION DoReplace(cReplaceText AS String, oFoxRefRecord)
		RETURN .NULL.
	ENDFUNC

	FUNCTION DoDefinitions()
		IF THIS.OpenFile()
			THIS.FindDefinitions(THIS.cFileText, '', '', SEARCHTYPE_NORMAL)
		ENDIF
	ENDFUNC
	
	* return the name of the procedure a given
	* line number occurs in
	FUNCTION GetProcedure(nLineNo)
		LOCAL cTempFilename
		LOCAL cSafety
		LOCAL nCnt
		LOCAL i
		LOCAL cProcName
		LOCAL ARRAY aFileInfo[1]

		IF m.nLineNo == 0 OR EMPTY(THIS.cFileText)
			RETURN ''
		ENDIF		
		
		m.cProcName = ''
		m.cTempFilename = ADDBS(SYS(2023)) + SYS(2015) + ".tmp"

		TRY
			STRTOFILE(THIS.cFileText, m.cTempFilename, 0)
			m.nCnt = APROCINFO(aFileInfo, m.cTempFilename, 0)
		CATCH
			m.nCnt = 0
		ENDTRY
		FOR m.i = 1 TO nCnt
			IF m.nLineNo <= aFileInfo[m.i, 2]
				EXIT
			ENDIF

			DO CASE
			CASE aFileInfo[m.i, 3] == "Procedure"
				m.cProcName = aFileInfo[m.i, 1]
				IF AT('.', m.cProcName) > 0
					m.cProcName = SUBSTRC(m.cProcName, AT('.', m.cProcName) + 1)
				ENDIF

			CASE aFileInfo[m.i, 3] == "Class"
				m.cProcName = ''
			ENDCASE
		ENDFOR
		
		m.cSafety = SET("SAFETY")
		SET SAFETY OFF
		ERASE (m.cTempFilename)
		SET SAFETY &cSafety
		
		RETURN m.cProcName
	ENDFUNC
ENDDEFINE

PROCEDURE _wontop
PROCEDURE _wtitle
PROCEDURE _edgetenv
PROCEDURE _edsetenv
PROCEDURE _edgetchar
PROCEDURE _edselect
PROCEDURE _edgetstr
PROCEDURE _eddelete
PROCEDURE _edinsert
PROCEDURE _edsetpos
PROCEDURE _edgetpos

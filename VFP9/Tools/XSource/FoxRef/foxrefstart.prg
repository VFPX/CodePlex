* Program....: FOXREFSTART.PRG
* Version....: 1.0
* Date.......: February 26, 2002
* Abstract...: Entry point for Visual FoxPro References (foxref)
* Changes....:
* Parameters.:
*	[oAction]    = symbol information to lookup, as passed by VFP
*
#include "foxref.h"
#include "foxpro.h"
LPARAMETERS oAction

=CREATEOBJECT("CFoxRefStart", m.oAction)

RETURN

DEFINE CLASS CFoxRefStart AS Session
	PROCEDURE Init(oAction)
		LOCAL oFoxRef AS FoxRef OF foxref.prg
		LOCAL lOverwrite
		LOCAL lShowResults
		LOCAL cSymbol
		LOCAL nMode
		LOCAL cFilename
		LOCAL nLineNo
		LOCAL cClassName
		LOCAL cProcName
		LOCAL cSelectedText
		LOCAL nHWND
		LOCAL nMousePointer
		LOCAL i
		LOCAL lLibraryOpen
		LOCAL cFoxToolsLibrary
		LOCAL oError
		LOCAL lSuccess
		LOCAL cTalk
		LOCAL ARRAY aEdEnv[25]

		SET TALK OFF

		IF VARTYPE(m.oAction) == 'O'
			m.nMode      = m.oAction.Mode
			m.cSymbol    = m.oAction.Word  && word under the cursor
			m.cFilename  = m.oAction.Filename
			m.nLineNo    = m.oAction.LineNo
			m.cClassName = m.oAction.Class
			m.cProcName  = m.oAction.Proc
			m.nHWND      = m.oAction.HWND
		ELSE
			m.nMode      = MODE_REFERENCES
			m.cSymbol    = ''
			m.cFilename  = ''
			m.nLineNo    = 0
			m.cClassName = ''
			m.cProcName  = ''
			m.nHWND      = -1
		ENDIF

		m.nMousePointer = _SCREEN.MousePointer
		_SCREEN.MousePointer = MOUSE_HOURGLASS
			

		* -- see if we have an open window
		m.oFoxRef = .NULL.
		FOR m.i = 1 TO _SCREEN.FormCount
			IF _SCREEN.Forms(m.i).Name == "frmFoxRefResults" AND TYPE("_SCREEN.Forms(m.i).oFoxRef") == 'O' AND !ISNULL(_SCREEN.Forms(m.i).oFoxRef)
				m.oFoxRef = _SCREEN.Forms(m.i).oFoxRef
				EXIT
			ENDIF
		ENDFOR
		IF VARTYPE(m.oFoxRef) <> 'O'
			m.oFoxRef = NEWOBJECT("FoxRef", "FoxRefEngine.prg", .NULL., .T.)
		ENDIF

		IF !m.oFoxRef.lInitError
			m.oFoxRef.WindowHandle   = m.nHWND
			m.oFoxRef.WindowFilename = m.cFilename
			m.oFoxRef.WindowLineNo   = m.nLineNo

			* grab the selected line
			m.cSelectedText = m.cSymbol
			IF m.nHWND >= 0 AND m.nLineNo > 0
				TRY
					IF ATCC("FOXTOOLS.FLL", SET("LIBRARY")) == 0
						m.lLibraryOpen = .F.
						m.cFoxtoolsLibrary = SYS(2004) + "FOXTOOLS.FLL"
						IF FILE(m.cFoxtoolsLibrary)
							SET LIBRARY TO (m.cFoxToolsLibrary) ADDITIVE
						ENDIF
					ELSE
						m.lLibraryOpen = .T.
					ENDIF
					
					IF _edgetenv(m.nHWND, @aEdEnv) == 1
						IF aEdEnv[EDENV_LENGTH] > 0 && AND aEdEnv[EDENV_SELSTART] > -1 AND aEdEnv[EDENV_SELEND] > 0
							m.cSelectedText = _edgetstr(m.nHWND, aEdEnv[EDENV_SELSTART], aEdEnv[EDENV_SELEND] - 1)
							* make sure we get a single line
							DO CASE
							CASE CHR(10)$m.cSelectedText AND CHR(13)$m.cSelectedText
								m.cSelectedText = LEFT(m.cSelectedText, MIN(AT(CHR(10), m.cSelectedText), AT(CHR(13), m.cSelectedText)) - 1)
							CASE CHR(10)$m.cSelectedText
								m.cSelectedText = LEFT(m.cSelectedText, AT(CHR(10), m.cSelectedText) - 1)
							CASE CHR(13)$m.cSelectedText
								m.cSelectedText = LEFT(m.cSelectedText, AT(CHR(13), m.cSelectedText) - 1)
							ENDCASE
						ENDIF
					ENDIF
					
					IF !m.lLibraryOpen AND ATCC(m.cFoxToolsLibrary, SET("LIBRARY")) > 0
						RELEASE LIBRARY (m.cFoxToolsLibrary)
					ENDIF

				CATCH
				ENDTRY	
			ENDIF

			* m.oFoxRef.RestorePrefs()

			DO CASE
			CASE m.nMode == MODE_REFERENCES
				m.oFoxRef.WindowHandle = -1
				m.oFoxRef.SetProject()
				IF m.oFoxRef.SearchCount() > 0
					m.oFoxRef.ShowResults()
				ELSE
					m.oFoxRef.Search(m.cSelectedText, .T.)
				ENDIF

			CASE m.nMode == MODE_LOOKUP
				m.oFoxRef.SetProject()
				IF m.oFoxRef.SearchCount() > 0 AND VARTYPE(m.oAction) <> 'O'
					m.oFoxRef.ShowResults()
				ELSE
					m.oFoxRef.Search(m.cSelectedText, .T.)
				ENDIF

			CASE m.nMode == MODE_GOTODEF
				IF !EMPTY(m.cSelectedText)
					m.cSymbol = m.cSelectedText
				ENDIF

				IF !EMPTY(m.cSymbol)
					IF m.oFoxRef.WindowHandle >= 0
						m.oFoxRef.CollectDefinitions(.T.) && grab locals only first from current window
						m.lSuccess = m.oFoxRef.GotoSymbol(m.cSymbol, m.cFilename, m.cClassName, m.cProcName, m.nLineNo, .T.)
					ELSE
						m.lSuccess = .F.
					ENDIF
					
					IF !m.lSuccess
						m.oFoxRef.CollectDefinitions()
						m.oFoxRef.GotoSymbol(m.cSymbol, m.cFilename, m.cClassName, m.cProcName, m.nLineNo)
					ENDIF
				ENDIF
			ENDCASE
		ENDIF

		_SCREEN.MousePointer = m.nMousePointer

		RETURN
	ENDPROC
	
	PROCEDURE Destroy()
	ENDPROC
ENDDEFINE

PROCEDURE _edgetstr
PROCEDURE _edgetenv
PROCEDURE _edgetlpos

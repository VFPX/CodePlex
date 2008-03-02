* Program....: DataExplorerStart.prg
* Version....: 1.0
* Date.......: July 7, 2004
* Abstract...: Entry point for Visual FoxPro Data Explorer
* Changes....:
* Parameters.:
*	-r = restore default data explorer table
*   -m = add to menu
*   or specify the name of the DataExplorer table to use
*
#include "foxpro.h"
#include "dataexplorer.h"
LPARAMETERS cAction
LOCAL cTalk
LOCAL oDataExp
LOCAL cOption
LOCAL i
LOCAL nBar
LOCAL nLevel
LOCAL cAppName

SET CONSOLE OFF
m.cTalk = SET("TALK")
SET CONSOLE ON
SET TALK OFF


IF VARTYPE(m.cAction) <> 'C'
	m.cAction = ''
ENDIF

IF LEFT(m.cAction, 1) == '-' OR LEFT(m.cAction, 1) == '/'
	m.cOption = LOWER(SUBSTR(m.cAction, 2, 1))

	DO CASE
	CASE m.cOption = "r"
		m.oDataExp = NEWOBJECT("DataExplorerEngine", "DataExplorerEngine.prg")
		m.oDataExp.RestoreToDefault()
		RETURN

	CASE m.cOption == "m"  && add to menu
		m.nLevel = 1
		DO WHILE !EMPTY(SYS(16, m.nLevel))
			IF EMPTY(m.cAppName) OR ATC(".app", SYS(16, m.nLevel)) > 0
				m.cAppName = SYS(16, m.nLevel)
			ENDIF
			m.nLevel = m.nLevel + 1
		ENDDO
		IF FILE(m.cAppName)
			m.nBar = 0
			FOR m.i = 1 TO CNTBAR("_MTOOLS")
				IF PRMBAR("_MTOOLS", GETBAR("_MTOOLS", m.i)) == STRTRAN(MENU_PROMPT_LOC, '\<', '')
					m.nBar = GETBAR("_MTOOLS", m.i)
					EXIT
				ENDIF
			ENDFOR
			IF m.nBar == 0
				m.nBar = CNTBAR("_MTOOLS") + 1
			ENDIF
			
			m.cAppName = [DO LOCFILE("] + m.cAppName + [", "APP")]
			DEFINE BAR m.nBar OF _mtools AFTER _mtl_toolbox ;
			 PROMPT MENU_PROMPT_LOC ;
			 MESSAGE MENU_MESSAGE_LOC
			ON SELECTION BAR m.nBar OF _mtools &cAppName
		ENDIF
		SET TALK &cTalk

		RETURN
	OTHERWISE
		* option not recognized, so simply ignore
	ENDCASE
ENDIF

DO FORM DataExplorer NAME DataExplorer

* Program....: ENVMGRSTART.PRG
* Version....: 2.0
* Date.......: July 30, 2002
* Abstract...: Entry point for Visual FoxPro Environment Manager
* Changes....:
* Parameters.:
*	<cAction> = SetName to goto -or-
*				-g:UniqueID = uniqueID of set name to goto -or-
*				-e:UniqueID = uniqueID of set name to edit
*	[lQuiet]  = .T. to not display messagebox after environment is set
*	<cTable>  = environment manager table if not the default
#include "foxpro.h"
#include "envmgr.h"
LPARAMETERS cAction, lQuiet, cTable

LOCAL oEnvMgrEngine
LOCAL oEnvMgrForm
LOCAL cOption
LOCAL cUniqueID
LOCAL nLevel
LOCAL cAppName
LOCAL nBar
LOCAL i
LOCAL cTalk

SET CONSOLE OFF
m.cTalk = SET("TALK")
SET CONSOLE ON
SET TALK OFF


IF VARTYPE(m.cAction) <> 'C'
	m.cAction = ''
ENDIF

IF VARTYPE(m.cTable) <> 'C'
	m.cTable = ''
ENDIF

IF LEFT(m.cAction, 1) == '-' OR LEFT(m.cAction, 1) == '/'
	m.cOption = LOWER(SUBSTR(m.cAction, 2, 1))
	m.cUniqueID = SUBSTR(m.cAction, 4)
ELSE
	m.cOption = ''
	m.cUniqueID = m.cAction
ENDIF

DO CASE
CASE m.cOption == "g"  && goto
	SET TALK &cTalk
	oEnvMgrEngine = NEWOBJECT("EnvMgrEngine", "EnvMgrEngine.prg", .NULL., m.cTable)
	oEnvMgrEngine.SetEnv(m.cUniqueID)

CASE m.cOption == "e"  && edit
	SET TALK &cTalk
	oEnvMgrForm = NEWOBJECT("CEnvMgrForm", "EnvMgr.vcx", .NULL., m.cUniqueID, m.cTable)
	oEnvMgrForm.Show()

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
	
OTHERWISE
	SET TALK &cTalk
	IF EMPTY(m.cUniqueID)
		oEnvMgrForm = NEWOBJECT("CEnvMgrForm", "EnvMgr.vcx", .NULL., m.cUniqueID, m.cTable)
		oEnvMgrForm.Show()
	ELSE
		oEnvMgrEngine = NEWOBJECT("EnvMgrEngine", "EnvMgrEngine.prg", .NULL., m.cTable)
		oEnvMgrEngine.SetEnv(m.cUniqueID, lQuiet)
	ENDIF
ENDCASE


RETURN

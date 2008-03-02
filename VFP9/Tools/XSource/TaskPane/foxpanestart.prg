* Program....: FoxPaneStart.prg
* Version....: 1.0
* Date.......: May 9, 2002
* Abstract...: Entry point for Visual FoxPro Task Pane Manager
* Changes....:
* Parameters.:
*	[cUniqueID] = UniqueID of pane to position to by default
*				  "-s" = run Pane Setup
*				  "startup" = set in registry as startup program
*
#include "foxpro.h"
#include "foxpane.h"
LPARAMETERS cUniqueID
LOCAL oEngine

* Only allow Task Pane to run in Interactive mode
*!*	IF _VFP.StartMode <> 0
*!*		RETURN
*!*	ENDIF

IF VARTYPE(m.cUniqueID) <> 'C'
	m.cUniqueID = ''
ENDIF

* set TaskPane as our startup program in the registry
IF LOWER(m.cUniqueID) == "_startup"
	m.oEngine = NEWOBJECT("FoxPaneEngine", "FoxPaneEngine.prg")
	IF VARTYPE(m.oEngine) == 'O'
		m.oEngine.SetStartupSetting(.T.)
	ENDIF
ENDIF


IF LOWER(m.cUniqueID) == "-s"
	DO FORM FoxPaneSetup
ELSE
	DO FORM FoxPane WITH m.cUniqueID
ENDIF

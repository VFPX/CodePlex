#include "tasklist.h"

LOCAL lcOldTalk
SET CONSOLE OFF
lcOldTalk = SET("TALK")
SET CONSOLE ON
SET TALK OFF

If Type("_oTasklist.class") <> "C"
	Public _oTaskList
	_otaskList = NewObject("tasklist","programs\tasklist.prg")
Endif

IF VARTYPE(_otaskList) == 'O' AND !ISNULL(_oTaskList)
	_otaskList.showUI()
ELSE
	=MESSAGEBOX(ERROR_NOINIT_LOC, MB_ICONSTOP + MB_OK)
ENDIF

SET TALK &lcOldTalk

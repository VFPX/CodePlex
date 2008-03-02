* Abstract...:
*	Search / Replace functionality for a .PRG, .H, .QPR, .MPR, etc
*
* Changes....:
*
#include "foxref.h"
#include "foxpro.h"

DEFINE CLASS RefSearchProgram AS RefSearch OF FoxRefSearch.prg
	Name = "RefSearchProgram"

	FUNCTION DoSearch()
		RETURN THIS.FindInCode(THIS.cFileText, FINDTYPE_CODE, '', '', SEARCHTYPE_NORMAL)
	ENDFUNC

	FUNCTION DoDefinitions()
		* THIS.FindDefinitions(FILETOSTR(THIS.Filename), '', '', SEARCHTYPE_NORMAL)
		THIS.FindDefinitions(THIS.cFileText, '', '', SEARCHTYPE_NORMAL)
	ENDFUNC
ENDDEFINE

* Program....: ToolboxStart.prg
* Version....: 1.0
* Date.......: May 24, 2002
* Abstract...: Entry point for Visual FoxPro Toolbox
* Changes....:
* Parameters.:
*	[cUniqueID] = UniqueID of toolbox category to position to by default
*
#include "foxpro.h"
LPARAMETERS cUniqueID, lDesktop

IF VARTYPE(m.lDesktop) == 'L' AND m.lDesktop
	DO FORM ToolboxDesktop WITH m.cUniqueID
ELSE
	DO FORM Toolbox WITH m.cUniqueID NAME Toolbox
ENDIF

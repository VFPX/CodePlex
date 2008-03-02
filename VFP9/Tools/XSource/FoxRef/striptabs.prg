* Abstract:
*   Strip tabs, spaces from the beginning
*	of a code line.
*	This is necessary because LTRIM()
*	does not handle tabs (only spaces)
*
* Parameters:
*	<cAbstract> = string to strip tabs/spaces from
#include "foxref.h"
LPARAMETERS cAbstract

RETURN ALLTRIM(CHRTRANC(RTRIM(m.cAbstract), TAB, ' '))


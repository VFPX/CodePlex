*==============================================================================
* Function:			CloseOpenedCursors
* Purpose:			Closes any cursors opened by a process
* Author:			Doug Hennig
* Last revision:	06/21/2002
* Parameters:		taUsed - a snapshot of cursors open before the process
* Returns:			.T.
* Environment in:	none
* Environment out:	any cursors open now that weren't open before the process
*						are closed
*==============================================================================

lparameters taUsed
local laUsed[1], ;
	lnUsed, ;
	lnI, ;
	lcCursor
lnUsed = aused(laUsed)
for lnI = 1 to lnUsed
	lcCursor = laUsed[lnI, 1]
	if ascan(taUsed, lcCursor, -1, -1, 1, 6) = 0
		use in (lcCursor)
	endif ascan(taUsed, lcCursor, -1, -1, 1, 6) = 0
next lnI
return

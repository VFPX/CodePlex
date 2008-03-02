*==============================================================================
* Function:			GetTablesFromSelect
* Purpose:			Returns a list of tables specified in a SQL SELECT
*						statement
* Author:			Doug Hennig
* Last revision:	11/27/2002
* Parameters:		taTables - an array (passed by reference) to fill with
*						the tables
*					tcSelect - the SQL SELECT statement
* Returns:			the number of tables found
* Environment in:	none
* Environment out:	taTables is a 2-dimensional array, with the first column
*						containing the original table name and the second the
*						alias (same as the table if no alias is provided)
*==============================================================================

lparameters taTables, ;
	tcSelect
external array taTables
local lnPos, ;
	lcTables, ;
	laTables[1], ;
	lnTables, ;
	lnI, ;
	lcTable, ;
	lcAlias
lnPos = atc(' FROM ', tcSelect)
if lnPos > 0
	lcTables = substr(tcSelect, lnPos + 6)
else
	lcTables = ''
endif lnPos > 0
lnPos = atc(' WHERE ', lcTables)
if lnPos > 0
	lcTables = left(lcTables, lnPos - 1)
endif lnPos > 0
lnPos = atc(' GROUP BY ', lcTables)
if lnPos > 0
	lcTables = left(lcTables, lnPos - 1)
endif lnPos > 0
lnPos = atc(' ORDER BY ', lcTables)
if lnPos > 0
	lcTables = left(lcTables, lnPos - 1)
endif lnPos > 0
lcTables = strtran(lcTables, ' RIGHT ', ' ', -1, -1, 1)
lcTables = strtran(lcTables, ' LEFT ',  ' ', -1, -1, 1)
lcTables = strtran(lcTables, ' FULL ',  ' ', -1, -1, 1)
lcTables = strtran(lcTables, ' INNER ', ' ', -1, -1, 1)
lcTables = strtran(lcTables, ' OUTER ', ' ', -1, -1, 1)
lnTables = alines(laTables, lcTables, .T., ' JOIN ', ' join ', 'Join', ',')
dimension taTables[max(lnTables, 1), 2]
for lnI = 1 to lnTables
	lcTable = laTables[lnI]
	lnPos   = atc(' ON ', lcTable)
	if lnPos > 0
		lcTable = left(lcTable, lnPos - 1)
	endif lnPos > 0
	lnPos = atc(' AS ', lcTable)
	if lnPos > 0
		lcAlias = getwordnum(substr(lcTable, lnPos + 4), 1)
		lcTable = left(lcTable, lnPos - 1)
	else
		lcAlias = lcTable
	endif lnPos > 0
	taTables[lnI, 1] = lcTable
	taTables[lnI, 2] = lcAlias
next lnI
return iif(lnTables = 1 and empty(taTables[1]), 0, lnTables)

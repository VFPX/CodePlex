*==============================================================================
* Function:			GetObjectName
* Purpose:			Adds delimiters to the specified name if it contains any
*						illegal characters
* Author:			Doug Hennig
* Last revision:	09/20/2004
* Parameters:		tcName - the name
* Returns:			the name with delimiters added if necessary
* Environment in:	none
* Environment out:	none
*==============================================================================

#include DECABuilder.H
lparameters tcName
local lcName
lcName = iif(chrtran(tcName, ccILLEGAL, '') <> tcName and ;
	left(alltrim(tcName), 1) <> ccLEFT_TABLE_DELIMITER, ;
	ccLEFT_TABLE_DELIMITER + tcName + ccRIGHT_TABLE_DELIMITER, tcName)
return lcName

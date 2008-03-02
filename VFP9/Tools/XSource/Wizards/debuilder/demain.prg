*==============================================================================
* Program:			DEMain
* Purpose:			Main program for the DataEnvironment and CursorAdapter
*					builders
* Author:			Doug Hennig
* Last revision:	08/07/2002
* Parameters:		tcParm1 - tcParm16: parameters passed by BUILDER.APP
* Returns:			.T.
*==============================================================================

lparameters tcParm1, ;
	tcParm2, ;
	tcParm3, ;
	tcParm4, ;
	tcParm5, ;
	tcParm6, ;
	tcParm7, ;
	tcParm8, ;
	tcParm9, ;
	tcParm10, ;
	tcParm11, ;
	tcParm12, ;
	tcParm13, ;
	tcParm14, ;
	tcParm15, ;
	tcParm16
local lnSelect, ;
	loBuilder
#include DECABuilder.h

* Auto-register ourselves if we're called directly.

if program(0) == ccMAIN_PROGRAM
	lnSelect = select()
	select 0
	use home() + 'Wizards\Builder' shared again
	locate for Name = 'CursorAdapter Builder'
	if not found()
		insert into Builder ;
				(Name, ;
				Descript, ;
				Type, ;
				Program, ;
				ClassLib, ;
				ClassName) ;
			values ;
				('CursorAdapter Builder', ;
				ccLOC_CABUILDER_DESCRIP, ;
				'CURSORADAPTER', ;
				'Wizards\DEBuilder.app', ;
				'DECABuilder.vcx', ;
				'CursorAdapterBuilderForm')
	endif not found()
	locate for Name = 'DataEnvironment Builder'
	if not found()
		insert into Builder ;
				(Name, ;
				Descript, ;
				Type, ;
				Program, ;
				ClassLib, ;
				ClassName) ;
			values ;
				('DataEnvironment Builder', ;
				ccLOC_DEBUILDER_DESCRIP, ;
				'DATAENVIRONMENT', ;
				'Wizards\DEBuilder.app', ;
				'DECABuilder.vcx', ;
				'DEBuilderForm')
	endif not found()
	use
	select (lnSelect)
	messagebox(ccLOC_BUILDER_INSTALLED, MB_OK + MB_ICONINFORMATION)
	return
endif program(0) == ccMAIN

* Ensure we were called from BUILDER.APP.

if type('wboObject') <> 'O'
	messagebox(ccLOC_BAD_BUILDER_CALL, MB_OK + MB_ICONSTOP)
	return
endif type('wboObject') <> 'O'

* We want our builders to be modal, so flip the flag accordingly.

wboObject.wblModal = .T.

* If we're supposed to be modal, we'll instantiate the specified builder class;
* otherwise, we'll DO the form of the same name.

if wboObject.wblModal
	set classlib to DECABuilder additive
	loBuilder = createobject(wboObject.wbcBldrClass)
	if vartype(loBuilder) = 'O'
		loBuilder.Show(1)
	endif vartype(loBuilder) = 'O'
else
	do form (wboObject.wbcBldrClass)
endif wboObject.wblModal

* This function is here simply to fool the Project Manager into not giving
* an error when building the project.

function wbaControl

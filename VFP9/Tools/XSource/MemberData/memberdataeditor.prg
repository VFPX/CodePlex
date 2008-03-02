*==============================================================================
* Program:			MemberDataEditor.PRG
* Purpose:			Main program for MemberData Editor
* Last revision:	11/12/2004
* Parameters:		tcParameter1 - passed by Builder.APP but not used
*					tcParameter2 - passed by Builder.APP but not used
*					tcParameter3 - passed by Builder.APP but not used
*					toObject     - a reference to the selected object
*					tnAction     - 0 if called from the Class Designer, 1 if
*						called from the Form Designer, 10 if called from the
*						Add to Favorites menu item in the Form Designer, or 11
*						if called from Add to Favorites in the Class Designer
*					tcMember     - the name of the member we're supposed to
*						Add to Favorites
* Returns:			.T.
*==============================================================================

lparameters tcParameter1, ;
	tcParameter2, ;
	tcParameter3, ;
	toObject, ;
	tnAction, ;
	tcMember
#include MemberDataEditor.H
local lcCurrTalk, ;
	lcCurrExact, ;
	lcPath, ;
	loEngine, ;
	llAddToFavorites

* Set up the environment.

if set('TALK') = 'ON'
	set talk off
	lcCurrTalk = 'ON'
else
	lcCurrTalk = 'OFF'
endif set('TALK') = 'ON'
lcCurrExact = set('EXACT')
set exact off

* Get the path.

lcPath = addbs(justpath(sys(16)))

* Create the engine class and set things up.

loEngine = newobject('MemberDataEngine', 'MemberDataEngine.prg')
if vartype(tcMember) = 'C'
	loEngine.cSelectedMember = lower(tcMember)
endif vartype(tcMember) = 'C'
if vartype(toObject) = 'O'
	loEngine.oObject = toObject
endif vartype(toObject) = 'O'
loEngine.lClassDesigner = vartype(tnAction) = 'N' and ;
	inlist(tnAction, cnCALLED_FROM_CLASS, cnADD_TO_FAVORITES_CLASS)
llAddToFavorites = vartype(tnAction) = 'N' and ;
	inlist(tnAction, cnADD_TO_FAVORITES_FORM, cnADD_TO_FAVORITES_CLASS)
loEngine.SetupEngine(llAddToFavorites)
do case

* We had a problem during setup, so display a warning.

	case not empty(loEngine.cErrorMessage)
		messagebox(loEngine.cErrorMessage, MB_OK + MB_ICONSTOP, ;
			ccLOC_CAP_MEMBER_DATA_EDITOR)

* If no object is selected and no parameters were passed, this must be a
* "registration" call, so do the registration tasks. Note: set
* lCreateGetMemberDataRecord or clAUTO_CREATE_MEMBER_DATA (defined in
* MemberDataEditor.H) to .F. if we don't want to automatically create an
* _MemberData property for objects when they're opened in the Form or Class
* Designer.

	case vartype(loEngine.oObject) <> 'O' and pcount() = 0
		loEngine.lCreateGetMemberDataRecord = clAUTO_CREATE_MEMBER_DATA
		loEngine.RegisterMemberDataEditor(lcPath)
		messagebox(ccLOC_EDITOR_REGISTERED, MB_OK + MB_ICONINFORMATION, ;
			ccLOC_CAP_MEMBER_DATA_EDITOR)

* If no object is selected, we have an invalid call.

	case vartype(loEngine.oObject) <> 'O'
		messagebox(ccLOC_BAD_CALL, MB_OK + MB_ICONSTOP, ;
			ccLOC_CAP_MEMBER_DATA_EDITOR)

* If we're supposed to add the specified member to Favorites, do so.

	case llAddToFavorites and not loEngine.lNoObjectMemberData
		loEngine.AddMemberToFavorites()
		if not empty(loEngine.cErrorMessage)
			messagebox(loEngine.cErrorMessage, MB_OK + MB_ICONSTOP, ;
				ccLOC_CAP_MEMBER_DATA_EDITOR)
		endif not empty(loEngine.cErrorMessage)
	case llAddToFavorites

* Launch the MemberData Editor for the selected object.

	otherwise
		loEngine.CreateMemberDataCollection()
		if not empty(loEngine.cErrorMessage)
			messagebox(loEngine.cErrorMessage, MB_OK + MB_ICONSTOP, ;
				ccLOC_CAP_MEMBER_DATA_EDITOR)
		endif not empty(loEngine.cErrorMessage)
		do form (lcPath + 'MemberDataEditor') with loEngine
endcase

* Clean up and exit.

release loEngine
if lcCurrTalk = 'ON'
	set talk on
endif lcCurrTalk = 'ON'
if lcCurrExact = 'ON'
	set exact on
endif lcCurrExact = 'ON'

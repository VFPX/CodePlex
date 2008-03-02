* Program:		BUILDER.PRG
* Description:	Main program of Builder.app

* Parameters:
*	wbopCtrl		- possible object reference
*	wbcpOrigin		- origin of call to builder - PSHEET, RTMOUSE, TOOLBOX
*	wbcpName		= (reserved)
*	wbcpOptions		- (reserved)
* 	wbcpP1-9		- optional parameters to pass to builder
* -----------------------------------------------------------------------------------------------------

parameters wbopCtrl, wbcpOrigin, wbcpClass, wbcpName, wbcpOptions, wbcpP1, wbcpP2, wbcpP3, wbcpP4, wbcpP5, wbcpP6, wbcpP7, wbcpP8, wbcpP9

LOCAL toObject,tuSource,tcRunBuilder
LOCAL lcBuilder,lcBuilder2, cTopWindow, wblPropSheetDock

LOCAL liOldLanguageOptions, liBuilderResult
liOldLanguageOptions = _vfp.LanguageOptions
_vfp.LanguageOptions = 0	&& turn off strict memvar checking (jd 11/26/00)

#DEFINE C_BUILDER_LOC			"BUILDER"
#INCLUDE "BUILDERS\BUILDER.H"

IF SET("TALK") = "ON"
	SET TALK OFF
	m.wbTalk = "ON"
ELSE
	m.wbTalk = "OFF"
ENDIF

* -------------------------------------------------
* DEBUG - set timer flag .T. to time builder - debug window line is
* 	fwrite(fp,padr(prog(),80)+str(line(),4)+str(seconds(),10,3)+chr(13))
_TIMING = IIF(TYPE("_TIMING") <> "L", .f., _TIMING)
_TIMECODE = 1		&& 0 - time load, up to show
					&& 1 - time entire code

* Create timer log
IF _TIMING
	starttime = seconds()
	fp=fcrea("log.txt")
ENDIF
* -------------------------------------------------

m.wbOptionalParms = parameters() - 4				&& first 4 are known parameters, remainder are optional

tcRunBuilder=wbcpClass

m.wbcBldVer = " version .078"

m.wbStartingProc = SET("PROCEDURE")

* Special handling for MemberData
IF TYPE("wbcpOrigin")="C" AND UPPER(wbcpOrigin)=="MEMBERDATA"
	wbcpP1 = wbopCtrl		&& object reference
	wbcpP2 = wbcpClass		&& action
	wbcpP3 = wbcpName		&& selected PEM
	wbOptionalParms = 3
	wbcpName = "MemberData"
ENDIF

IF TYPE("wbopCtrl") <> "O"							&& We may have an object reference passed in,
	FOR m.wbi=9 to 2 step -1						&& so we may need to adjust parameters.
		thisp = "wbcpP" + ltrim(str(m.wbi))			&& In any case, we now use ASELOBJ() to determine selected object(s).
		prevp = "wbcpP" + ltrim(str(m.wbi-1))
		&thisp = &prevp
	ENDFOR
	wbcpP1 = wbcpOptions
	wbcpOptions = wbcpName
	wbcpName = wbcpClass
	wbcpClass = wbcpOrigin
	wbcpOrigin = wbopCtrl
ENDIF


* Check for 5.0 or later
IF  VAL(SUBSTR(VERSION(),ATC("FOXPRO",VERSION())+7)) < 5
		=MESSAGEBOX(C_VERS5_LOC)
#if !C_DEBUG
		_vfp.LanguageOptions = liOldLanguageOptions 	&& restore memvar checking value (jd 11/26/00)
		RETURN
#endif
ENDIF


PUBLIC wbaControl[1], wbaContainer[1]
m.wbSelNum 	  = ASELOBJ(wbaSelObj)
m.wbContainer = ASELOBJ(wbaContainer, 1)

IF m.wbSelNum = 0 AND m.wbContainer >0 AND wbaContainer[1].class = "Page"
	IF TYPE("wbopCtrl")#"O" OR !INLIST(UPPER(wbopCtrl.BaseClass),"DATAENVIRONMENT","CURSORADAPTER")
*** Commented out this code since users can now create Page leaf classes and MemberData also can use it.	
*!*			=MessageBox(C_WRONGCLASS_LOC,ERRORTITLE_LOC)
*!*			RELEASE wbaControl,wbaContainer
*!*			_vfp.LanguageOptions = liOldLanguageOptions 	&& restore memvar checking value (jd 11/26/00)
*!*			RETURN
	ENDIF
ENDIF

IF TYPE("m.wbcpOrigin")=="C" AND UPPER(m.wbcpOrigin)=="QFORM" AND ;
		NOT LOWER(m.wbaContainer[1].BaseClass)=="form"
	MESSAGEBOX(C_NOFORM_LOC,ERRORTITLE_LOC)
	RELEASE wbaControl,wbaContainer
	_vfp.LanguageOptions = liOldLanguageOptions 	&& restore memvar checking value (jd 11/26/00)
	RETURN
ENDIF

IF TYPE("wbopCtrl") <> "O"						&& no object was passed in...use selected object(s),
	IF TYPE("wbaSelObj[1]") = "O"				&& or container object, or _SCREEN
		DIMENSION wbaControl[m.wbSelNum]
		= ACOPY(wbaSelObj, wbaControl)
	ELSE
		IF TYPE("wbaContainer[1]") = "O"
			wbaControl[1] = wbaContainer[1]
		ELSE
			wbaControl[1] = _SCREEN
		ENDIF
	ENDIF
ELSE											&& object was passed in (usual case)

	m.lUseParameter = .t.
	IF TYPE("wbaSelObj[1]") = "O"					&& we have a selected object
		IF UPPER(m.wbcpOrigin) = "AUTOFORMAT"			&& we want autoformat button to go against all selected
			m.lSelObjInList = .t.						&& objects - currently, the product passes in a ref to the form
		ELSE
			m.lSelObjInList = .f.
			FOR m.wbi = 1 TO m.wbSelNum
				IF COMPOBJ(wbaSelObj[m.wbi], wbopCtrl)
					m.lSelObjInList = .t.
					EXIT
				ENDIF
			ENDFOR
		ENDIF
		IF m.lSelObjInList
			DIMENSION wbaControl[m.wbSelNum]			&& object passed in is among selected object(s) (usual case) -
			= ACOPY(wbaSelObj, wbaControl)				&& builder will work against all selected objects
			m.lUseParameter = .f.
		ENDIF
	ENDIF
	IF m.lUseParameter
		wbaControl[1] = wbopCtrl					&& Otherwise, make the passed-in object the target of the builder.
													&& If selected control and container are the same object, then
													&& container is in edit mode and prop sheet will crash on return.
													&& This condition is trapped for in CheckBuilderSupport() in
													&& BuilderTemplate, called from Load of each builder.
		
		IF TYPE("m.wbcpOrigin")=="C" AND TYPE("wbopCtrl.PARENT") = "O" AND ;
				NOT COMPOBJ(wbaControl[1],wbaContainer[1])
			wbaContainer[1] = wbopCtrl.PARENT
		ENDIF
	ENDIF
ENDIF

IF TYPE("wbaControl[1]") <> "O"						&& Some object reference is required, stored in wbaControl. Release
	DO wbSetTalk
	_vfp.LanguageOptions = liOldLanguageOptions 	&& restore memvar checking value (jd 11/26/00)
	RETURN											&& others.
ENDIF
IF TYPE("wbaSelObj[1]") = "O"
	RELEASE wbaSelObj
ENDIF
IF TYPE("wbopctrl") = "O"
	RELEASE wbopctrl
ENDIF

wboForm = ""
IF TYPE("wbaContainer[1]") = "O"
	wboForm = wbaContainer[1]
	DO WHILE TYPE("wboForm.Parent") = "O"
		IF LOWER(wboForm.Baseclass) = "form"
			EXIT
		ENDIF
		wboForm = wboForm.Parent
	ENDDO
ENDIF

toObject=wbaControl[1]
tuSource=wbcpOrigin

*--	Check for object containing a Builder property.
*	A Builder property will automatically execute a specific builder.
lcBuilder=""
IF NOT ISNULL(tcRunBuilder) AND IIF(TYPE("wbcpOrigin")="C" AND UPPER(wbcpOrigin)=="MEMBERDATA",.F.,.T.)

*-- Check for specified tcRunBuilder.
	IF TYPE("tcRunBuilder")=="C" AND NOT EMPTY(tcRunBuilder)
		lcBuilder=tcRunBuilder
		liBuilderResult = DoBuilder(toObject,tuSource,lcBuilder,.T.)
		_vfp.LanguageOptions = liOldLanguageOptions 	&& restore memvar checking value (jd 11/26/00)
		RETURN liBuilderResult
	ENDIF

*-- Check for specified BuilderX property.
	IF TYPE("toObject.BuilderX")=="C" AND NOT EMPTY(toObject.BuilderX)
		lcBuilder=toObject.BuilderX
		liBuilderResult = DoBuilder(toObject,tuSource,lcBuilder)
		_vfp.LanguageOptions = liOldLanguageOptions 	&& restore memvar checking value (jd 11/26/00)
		RETURN liBuilderResult
	ENDIF

*-- Check for specified Builder property.
	IF TYPE("toObject.Builder")=="C" AND NOT EMPTY(toObject.Builder)
		lcBuilder=toObject.Builder
		liBuilderResult = DoBuilder(toObject,tuSource,lcBuilder)
		_vfp.LanguageOptions = liOldLanguageOptions 	&& restore memvar checking value (jd 11/26/00)
		RETURN liBuilderResult
	ENDIF

ENDIF

IF NOT ISNULL(lcBuilder) AND NOT EMPTY(lcBuilder) AND NOT FILE(lcBuilder)
	lcBuilder2=LOWER(FULLPATH(JUSTFNAME(lcBuilder),HOME()))
	IF NOT FILE(lcBuilder2)
		=FileNotFoundMsg(lcBuilder)
		_vfp.LanguageOptions = liOldLanguageOptions 	&& restore memvar checking value (jd 11/26/00)
		RETURN .F.
	ENDIF
	lcBuilder=lcBuilder2
ENDIF
IF TYPE("tuSource")#"C"
	tuSource=""
ENDIF

IF ALEN(wbaControl) = 1	AND TYPE("wbaControl[1].Builder")=="C" AND NOT EMPTY(wbaControl[1].Builder)
	lcBuilder=wbaControl[1].Builder
	DoBuilder(wbaControl[1],tuSource,lcBuilder)
	_vfp.LanguageOptions = liOldLanguageOptions 	&& restore memvar checking value (jd 11/26/00)
	RETURN
ENDIF
toObject=.NULL.

m.WBRow = 0
m.WBCol = 0
IF EMPTY(m.wbcpOrigin)
	m.wbcpOrigin = "PSHEET"
ENDIF
IF m.wbcpOrigin = "RTMOUSE"
	m.WBRow = MROW(WONTOP())	&& * (FONTMETRIC(4) + FONTMETRIC(1))
	m.WBCol = MCOL(WONTOP()) 	&& * FONTMETRIC(7)
ENDIF

IF NOT "WBMAIN" $ SET("PROCEDURE")
	SET PROCEDURE TO WBMAIN.FXP ADDITIVE				&& main wizard/builder class library
ENDIF

m.wbReturnValue = ""						&& return value from BUILDER.APP
m.wblError = .f.
m.wbcAlertTitle = ""
m.Debug = .t.

m.wboObject = CREATEOBJ("builder")				&& create builder object - class definition below

WITH wboObject
	.wbOptParms = m.wbOptionalParms
	IF UPPER(wbaControl[1].Name) <> "SCREEN"
		.wbcClass = wbaControl[1].Class
		.wbcBaseClass = wbaControl[1].BaseClass
	ENDIF
	.wbcNamedClass = IIF(TYPE("m.wbcpClass") = "C", m.wbcpClass, "")


	IF UPPER(m.wbcpOrigin) = "AUTOFORMAT"
		.wbcClass = "AUTOFORMAT"
	ELSE
		IF ALEN(wbaControl) > 1
			.wbcClass = "MULTISELECT"
		ENDIF
	ENDIF
ENDWITH
* ---------------------------------------------
* DEBUG - when timing builder, make it modeless
IF _TIMING OR C_DEBUG
	IF TYPE("wbcpOptions") <> "C"
		wbcpOptions = ""
	ENDIF
	IF NOT " SNOQUALMIE::FLEW " $ " " + UPPER(ALLTRIM(wbcpOptions)) + " "
		wbcpOptions = wbcpOptions + " SNOQUALMIE::FLEW "
	ENDIF
ENDIF
* ---------------------------------------------
WITH wboObject
	.wblModal = .t.
	IF TYPE("wbcpOptions") = "C"
		IF  (" SNOQUALMIE::FLEW " $ " " + UPPER(m.wbcpOptions) + " ")
			.wblModal = .f.
		ENDIF
	ENDIF
	* Testing will pass in "SNOQUALMIE::FLEW" as parameter 4

	.WBSaveEnvironment
	.WBSetProps
	.WBCheckparms
	.WBCheckErrors
	IF m.wblError
		RETURN 
	ENDIF
	.WBSetTools
	.WBSetPlatform

	.WBGetRegTable
ENDWITH

m.wblHavePropSheet = WEXIST("PROPERTIES")
IF m.wblHavePropSheet						&& test for dockability - don't change this if dockable
	m.wblPropSheetDock = WDOCKABLE("PROPERTIES")
ENDIF
IF NOT EMPTY(wboObject.wbcRegTable)
	wboObject.WBGetName
	IF NOT EMPTY(wboObject.wbcName)
		IF m.wblHavePropSheet
			cTopWindow = WONTOP()			&& remember top window
			IF !m.wblPropSheetDock
				HIDE WINDOW PROPERTIES
			ENDIF
		ENDIF

		wboObject.WBCall					&& call specific builder
		
		* -----
		* DEBUG
		IF _TIMING
			? SECONDS() - STARTTIME
		ENDIF
		IF _TIMING AND _TIMECODE = 0
			DO LOGTIMES
		ENDIF
		* -----

		IF m.wblHavePropSheet AND wboObject.wblModal
			IF !m.wblPropSheetDock
				SHOW WINDOW PROPERTIES
			ENDIF
			SHOW WINDOW "&cTopWindow"		&& make sure the window is on top of properties window, if "always on top"
											&& is not checked
		ENDIF
	ENDIF
ENDIF

m.wbReturnValue = wboObject.wbReturnValue
IF wboObject.wblModal
	wboObject.WBSetEnvironment					&& reset environment if modal, else we're in automated test
	RELEASE wboObject, wbaControl, wbaContainer

	IF NOT EMPTY(m.wbStartingProc)
		SET PROCEDURE TO &wbStartingProc
	ELSE
		SET PROCEDURE TO
	ENDIF
ENDIF

*------
* DEBUG 
IF _TIMING AND _TIMECODE = 1
	DO LOGTIMES
ENDIF
*------

DO wbSetTalk
_vfp.LanguageOptions = liOldLanguageOptions 	&& restore memvar checking value (jd 11/26/00)
RETURN m.wbReturnValue


PROCEDURE wbSetTalk

IF m.wbTalk = "ON"
	SET TALK ON
ENDIF

RETURN


PROCEDURE LOGTIMES
	=fclose(fp)

	sele 0
	crea tabl tim (prog c(80),line c(4),sec n(10,4),diff n(10,4))
	appe from log.txt sdf
	if !eof()

		locate
		m=sec
		repl all sec with sec-m
		locate
		m=sec
		skip
		scan rest
			repl diff with sec-m
			m=sec
		endscan
		inde on -diff tag t
		brow nowait field prog,line,diff
	ENDIF

RETURN


DEFINE CLASS Builder AS WizBldr		&& WizBldr class is defined in the WB.PRG library
* ---------------------------------------------------------------------------------------

	m.wbcType = "BUILDER"					&& do not localize
	m.wbcTypeDisplay = C_BUILDER_LOC		&& this line is localizable, defined at top of this file

ENDDEFINE



PROC LENC(dummy)
RETURN LEN(m.dummy)

PROC SUBSTRC(dummy1,dummy2,dummy3)
RETURN SUBSTR(m.dummy1,m.dummy2,m.dummy3)

PROC IsLeadByte(dummy)
RETURN .f.



FUNCTION DoBuilder(toObject,tuSource,tcBuilder,tlSkipSearch)
LOCAL lcBuilder,lnAtPos,lcClass,lcLastOnError,lnLastMemoWidth
LOCAL laInstance[1]

lnLastMemoWidth=SET("MEMOWIDTH")
SET MEMOWIDTH TO 1024
lcBuilder=ALLTRIM(MLINE(tcBuilder,1))
lnAtPos=AT(",",lcBuilder)
IF lnAtPos=0
	lcClass=""
ELSE
	lcClass=LOWER(ALLTRIM(SUBSTR(lcBuilder,lnAtPos+1)))
	lcBuilder=LOWER(ALLTRIM(MLINE(LEFT(lcBuilder,lnAtPos-1),1)))
	IF EMPTY(lcBuilder)
		lcBuilder=toObject.ClassLibrary
	ENDIF
	IF EMPTY(JUSTEXT(lcBuilder))
		lcBuilder=FORCEEXT(lcBuilder,"vcx")
	ENDIF
ENDIF
SET MEMOWIDTH TO (lnLastMemoWidth)

IF lcBuilder=="?"
*--	Execute dialog to select builder program.
	lcBuilder=GETFILE("prg;scx;app","Select Builder program:","Open")
	IF EMPTY(lcBuilder)
		RETURN
	ENDIF
ENDIF

IF lcBuilder=="*"
*--	Create public reference o and activate the Command window.
	RELEASE o
	PUBLIC o
	o=toObject
	WAIT WINDOW LEFT("Name:  "+toObject.Name+SPACE(10)+CHR(13)+ ;
			"Type: "+tuSource+SPACE(10)+CHR(13)+ ;
			"Class:  "+toObject.Class+SPACE(10)+CHR(13)+ ;
			"ParentClass:  "+toObject.ParentClass+SPACE(10)+CHR(13)+ ;
			"Base Class:  "+toObject.BaseClass+SPACE(10)+CHR(13)+ ;
			"Reference:  o"+SPACE(10),254) NOWAIT
	ACTIVATE WINDOW Command
	RETURN
ENDIF

*--	Execute builder specified in _BuilderX memvar.
IF EMPTY(JUSTEXT(lcBuilder))
	lcBuilder=FORCEEXT(lcBuilder,"prg")
ENDIF
IF (NOT EMPTY(lcBuilder) OR EMPTY(lcClass)) AND NOT FILE(lcBuilder)
	IF NOT "\"$lcBuilder
		lcBuilder=FULLPATH(JUSTFNAME(lcBuilder),toObject.ClassLibrary)
	ENDIF
	IF NOT FILE(lcBuilder)
		lcBuilder2=LOWER(FULLPATH(JUSTFNAME(lcBuilder),HOME()))
		IF NOT FILE(lcBuilder2)
			=FileNotFoundMsg(lcBuilder)
			RETURN .F.
		ENDIF
		lcBuilder=lcBuilder2
	ENDIF
ENDIF
DO CASE
	CASE NOT EMPTY(lcClass)
		IF TYPE("_BuilderEdit")=="L" AND _BuilderEdit
			_BuilderEdit=.F.
			IF AINSTANCE(laInstance,lcClass)>0
				WAIT WINDOW [Class "]+lcClass+[" is in use] NOWAIT
				RETURN
			ENDIF
			MODIFY CLASS (lcClass) OF (lcBuilder) NOWAIT
			RETURN
		ENDIF
		lnCount=0
		DO WHILE .T.
			lnCount=lnCount+1
			lcObjName=PROPER(lcClass+ALLTRIM(STR(lnCount)))
			IF TYPE(lcObjName)=="U"
				EXIT
			ENDIF
		ENDDO
		DOEVENTS
		WAIT CLEAR
		lcLastOnError=ON("ERROR")
		ON ERROR =.F.
		oNewObject=NEWOBJECT(lcClass,lcBuilder,"",toObject,tuSource,tlSkipSearch)
		IF EMPTY(lcLastOnError)
			ON ERROR
		ELSE
			ON ERROR &lcLastOnError
		ENDIF
		IF TYPE("oNewObject")#"O" OR ISNULL(oNewObject)
			ShowMsg([Class (]+lcClass+ ;
					[) of "]+LOWER(lcBuilder)+[" could not be instantiated.])
			RETURN .F.
		ENDIF
		PUBLIC (lcObjName)
		lcCode=lcObjname+[=oNewObject]
		&lcCode
		IF oNewObject.lAutoShow
			oNewObject.Show()
		ENDIF
		IF TYPE("oNewObject")#"O" OR ISNULL(oNewObject)
			RETURN .F.
		ENDIF
		IF oNewObject.lAutoRelease
			oNewObject.Release()
			RELEASE (lcObjName)
		ENDIF
		RETURN
	CASE LOWER(RIGHT(lcBuilder,4))==".scx"
		IF TYPE("_BuilderEdit")=="L" AND _BuilderEdit
			_BuilderEdit=.F.
			MODIFY FORM (lcBuilder) NOWAIT
			RETURN
		ENDIF
		DO FORM (lcBuilder) WITH (toObject),(tuSource)
		RETURN
	CASE LOWER(RIGHT(lcBuilder,4))==".vcx"
		RETURN ShowMsg([File "]+LOWER(lcBuilder)+ ;
				[" requires class name (ex. TestLib,TestClass).])
	CASE LOWER(RIGHT(lcBuilder,4))==".prg"
		IF TYPE("_BuilderEdit")=="L" AND _BuilderEdit
			_BuilderEdit=.F.
			MODIFY COMM (lcBuilder) NOWAIT
			RETURN
		ENDIF
		DO (lcBuilder) WITH (toObject),(tuSource)
		RETURN
ENDCASE
IF TYPE("tuSource")#"C"
	tuSource=""
ENDIF
DO (lcBuilder) WITH (toObject),(tuSource)
RETURN



FUNCTION ShowMsg
LPARAMETERS tcMessage
LOCAL lnResult

lnResult=MESSAGEBOX(tcMessage,48,"Builder")
WAIT CLEAR
RETURN lnResult



FUNCTION FileNotFoundMsg
LPARAMETERS tcFileName

RETURN ShowMsg([File "]+LOWER(tcFileName)+[" not found.])

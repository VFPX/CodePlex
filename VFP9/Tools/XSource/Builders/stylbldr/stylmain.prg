* Program:		stylMain.PRG
* Description:	Main program file for Command Builder
*               Intended to be called from BUILDER.APP, so all environment
*               and other settings should have been made there.
* Version:		.050
* -----------------------------------------------------------------------------------------

#DEFINE C_BADCALL1_LOC	"The Autoformat Builder cannot be run as a standalone application. Use BUILDER.APP instead."
#DEFINE C_BADCALL2_LOC	"The proper context for the Autoformat Builder has not been established."
#DEFINE C_VCX			"stylbldr.vcx"
#DEFINE C_MAIN			"STYLMAIN"

PARAMETERS p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16

PRIVATE m.wbReturnValue, m.cParmstring
LOCAL wbi

*- make sure we are not called directly
IF PROGRAM(0) == C_MAIN
	*- called directly, so fail
	=MESSAGEBOX(C_BADCALL1_LOC)
	RETURN
ENDIF

IF TYPE("wboObject") # 'O'
	*- environment doesn't appear to be set up properly
	=MESSAGEBOX(C_BADCALL2_LOC)
	RETURN
ENDIF

RELEASE wboName
PUBLIC wboName

m.cParmstring = ""
FOR m.wbi = 1 to PARAMETERS()
	m.thisp = "p" + LTRIM(STR(m.wbi))
	m.cParmstring = m.cParmstring + IIF(!EMPTY(cParmString),",","") + m.thisp	&& will create ...,p1,p2,..." etc
ENDFOR

SELECT (wboObject.wbaEnvir[5])

m.wbReturnValue = wboObject.wbReturnValue

SET CLASSLIB TO C_VCX ADDITIVE

wboName = CREATEOBJ(wboObject.wbcBldrClass, &cParmstring)		&& all builders and wizards are modal formsets

IF TYPE("_TIMING") <> "U" AND _TIMING
	RETURN
ENDIF

IF TYPE("wboName") = "O"
	wboName.SHOW
ENDIF

wboObject.wbReturnValue = m.wbReturnValue

IF wboObject.wblModal							&& don't release, if modeless for testing
	RELEASE wboName
	IF FILE(C_VCX)
		RELEASE CLASSLIB C_VCX
	ENDIF
ENDIF

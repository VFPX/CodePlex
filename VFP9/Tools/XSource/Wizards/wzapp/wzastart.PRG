* This is the stub which you should copy (place the modified version in
* your Wizard's directory), rename, and modify to call your wizard.

PARAMETER cOutFileVarName, p2, p3, p4, p5, p6, p7, p8, p9
LOCAL cClassLib,cProcs,cWizardToRun

m.cClassLib = set('classlib')

*  Parm checking
IF TYPE("m.p2") #"C"
	m.p2 = ""
ENDIF

* Handle AUTOFORM case here
IF "AUTOFORM" $ UPPER(m.p2)
	cProcs = set('procedure')
	SET PROCEDURE TO wzengine
	SET PROCEDURE TO wzapp ADDITIVE
	oWizard=create('GenerateApplication')
	IF !EMPTY(m.cOutFileVarName)	&& output file name provided
		oWizard.cOutFile = m.cOutFileVarName
	ENDIF
	oWizard.autoform
	m.cOutFileVarName = oWizard.cOutFile
	RELEASE oWizard
	SET PROCEDURE TO &cProcs
	RETURN
ENDIF

m.cWizardToRun = "applicationwizard"		&& Application wizard

SET CLASSLIB TO wzapp ADDITIVE
set CLASSLIB TO WIZARD ADDITIVE

* The name "oWizard" is used in automated testing and should *NOT* be changed.
public oWizard
oWizard = createobj(m.cWizardToRun,m.cOutFileVarName, m.p2, m.p3, m.p4, ;
	m.p5, m.p6, m.p7, m.p8, m.p9)
	
if type('oWizard') = 'O' .and. .not. isnull(oWizard)
	oEngine.aEnvironment[17,1] = m.cClassLib
	oWizard.Show
endif
if type('oWizard') = 'O' .and. .not. isnull(oWizard)
	* It must be modeless, so leave it alone
else
	release oWizard
endif
IF ATC("\wzapp.vcx",SET("CLASSLIB"))>0
	RELEASE CLASSLIB wzapp
ENDIF
IF ATC("\wizard.vcx",SET("CLASSLIB"))>0
	RELEASE CLASSLIB WIZARD
ENDIF


PROCEDURE dummy
	* This routine is used to resolve Project array references.
	public aflddata[1],afielddata[1],atmpglobals,awizfields,aparms
	public aflddata[1],aglobals[1],aafielddata[1],atmpglobals[1]
	public awizfields[1],aparms[1]
ENDPROC

PROCEDURE fxsettype
	PARAMETER p1, p2, p3
	*This resolves Mac FOXTOOLS reference
ENDPROC
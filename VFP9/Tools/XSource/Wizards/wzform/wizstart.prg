* This is the stub which you should copy (place the modified version in
* your Wizard's directory), rename, and modify to call your wizard.

PARAMETER cOutFileVarName, p2, p3, p4, p5, p6, p7, p8, p9
LOCAL cClassLib,cProcs,cWizardToRun

m.cClassLib = set('classlib')

*  Parm checking
IF TYPE("m.p2") #"C"
	m.p2 = ""
ENDIF

IF TYPE("m.p3") #"C"
	m.p3 = ""
ENDIF

* Handle AUTOFORM case here
IF "AUTOFORM" $ UPPER(m.p2)
	cProcs = set('procedure')
	SET PROCEDURE TO wzengine
	SET PROCEDURE TO wizform ADDITIVE
	oWizard=create('formwizengine')
	
  	IF LOWER(m.cOutFileVarName) = "wbreturnvalue" AND TYPE(cOutFileVarName) = 'C'
		m.cOutFileVarName = EVAL(cOutFileVarName)
	ENDIF
	  
	IF !EMPTY(m.cOutFileVarName)	&& output file name provided
		oWizard.cOutFile = m.cOutFileVarName
	ENDIF
	oWizard.autoform(m.p4)
	* Check for error
	IF TYPE("oWizard") = "O"	AND !ISNULL(oWizard)
		m.cOutFileVarName = oWizard.cOutFile
		RELEASE oWizard
	ENDIF
	SET PROCEDURE TO &cProcs
	RETURN
ENDIF

DO CASE
	CASE "1MANY" $ UPPER(m.p2)
		m.cWizardToRun = "mformwizard"		&& 1-Many Form wizard
	OTHERWISE
		m.cWizardToRun = "formwizard"		&& Form wizard
ENDCASE

SET CLASS TO FORMWIZ ADDITIVE


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
	CLEAR CLASS &cWizardToRun
	CLEAR CLASS wiztemplate
endif


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
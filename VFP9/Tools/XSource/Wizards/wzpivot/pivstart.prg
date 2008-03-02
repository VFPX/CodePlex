* This is the stub which you should copy (place the modified version in
* your Wizard's directory), rename, and modify to call your wizard.

PARAMETER cOutFileVarName, p2, p3, p4, p5, p6, p7, p8, p9
LOCAL cClassLib,cProcs,cWizardToRun

m.cClassLib = set('classlib')

* Check parms
IF TYPE("m.p2") #"C"
	m.p2 = ""
ENDIF

IF "XTAB" $ UPPER(m.p2)
	m.cWizardToRun = "xtabwizard"		&& cross tab wizard
ELSE
	m.cWizardToRun = "pivotwizard"		&& pivot wizard
ENDIF

SET CLASS TO pivot ADDITIVE

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

return

PROCEDURE dummy
	* This routine is used to resolve Project array references.
	public aflddata[1],afielddata[1],atmpglobals,awizfields,aparms
	public aflddata[1],aglobals[1],aafielddata[1],atmpglobals[1]
	public awizfields[1],aparms[1]
ENDPROC
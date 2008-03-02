* This is the stub which you should copy (place the modified version in
* your Wizard's directory), rename, and modify to call your wizard.

* Note: cOutFileVar is not used with GraphWizard, but is used in WIZTEMPLATE
* so let's switch parameters if we have a query source.

PARAMETER cOutFileVar, p2, p3, p4, p5, p6, p7, p8, p9, p10
LOCAL cClassLib,cProcs,cWizardToRun,cTempVar

m.cClassLib = set('classlib')
m.cProcs = set('proc')
m.cTempVar = ""

* Check Parms
IF TYPE("m.cOutFileVar") = "C"
	m.cTempVar = m.cOutFileVar
ENDIF

* Handle AUTOGRAPH case here
IF ATC("AUTOGRAPH",m.cTempVar) # 0
	cProcs = set('proc')
	SET PROCEDURE TO wzengine
	SET PROCEDURE TO graphwiz ADDITIVE
	oWizard=create('graphengine')
	IF TYPE("m.oWizard") = "O"
		oWizard.AutoGraph(m.p2,m.p3,m.p4,m.p5,m.p6,m.p7,m.p8,m.p9,m.p10)
	ENDIF
	RELEASE oWizard
	SET PROCEDURE TO &cProcs
	RETURN .T.
ENDIF

IF ATC("QUERY",m.cTempVar) # 0
	m.p2 = "QUERY"
ENDIF

IF ATC("WIZARD",m.cTempVar) # 0
	m.p2 = "WIZARD"
ENDIF


m.cWizardToRun = "graphwizard"

SET CLASS TO graph ADDITIVE

* The name "oWizard" is used in automated testing and should *NOT* be changed.
public oWizard
oWizard = createobj(m.cWizardToRun,m.cOutFileVar, m.p2, m.p3, m.p4, ;
	m.p5, m.p6, m.p7, m.p8, m.p9)

if type('oWizard') = 'O' .and. .not. isnull(oWizard)
	oEngine.aEnvironment[17,1] = m.cClassLib
	oWizard.Show
endif
if type('oWizard') = 'O' .and. .not. isnull(oWizard)
	* It must be modeless, so leave it alone
else
	release oWizard
	CLEAR CLASS graphwizard
	CLEAR CLASS wiztemplate
endif

return

PROCEDURE dummy
	* This routine is used to resolve Project array references.
	public aflddata[1],afielddata[1],atmpglobals,awizfields,aparms
	public aflddata[1],aglobals[1],aafielddata[1],atmpglobals[1]
	public awizfields[1],aparms[1]
ENDPROC
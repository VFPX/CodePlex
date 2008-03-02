parameters cOutFileVarName, p2, p3, p4, p5, p6, p7, p8, p9
private cClassLib

m.cClassLib = set('classlib')
set classlib to wizard additive
set classlib to therm additive
set classlib to myctrls additive

PUBLIC oWizard
oWizard = createobj('UpsizingWizard', m.cOutFileVarName, m.p2, m.p3, m.p4, ;
	m.p5, m.p6, m.p7, m.p8, m.p9)

if type('oWizard') = 'O' .and. .not. isnull(oWizard)
	oEngine.aEnvironment[17,1] = m.cClassLib
	oWizard.Show
endif
if type('oWizard') = 'O' .and. .not. isnull(oWizard)
	* It must be modeless, so leave it alone
else
	release oWizard
	CLEAR CLASS UpsizingWizard
	CLEAR CLASS wiztemplate
endif

RETURN
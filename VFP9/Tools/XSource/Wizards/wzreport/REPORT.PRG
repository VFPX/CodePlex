* STUB for the Report Wizard

* This is the stub which you should copy (place the modified version in
* your Wizard's directory), rename, and modify to call your wizard.

LPARAMETER cOutFileVarName, p2, p3, p4, p5, p6, p7, p8, p9
LOCAL cClassLib, cProcs, cWizardToRun

m.cClassLib = set('classlib')
m.cProcs = set('proc')

IF TYPE("m.p2") #"C"
	m.p2 = ""
ENDIF

IF TYPE("m.p3") # "C"
   m.p3 = ""
ENDIF

DO CASE 
   CASE "AUTOREPORT"$UPPER(m.p2)
      SET PROCEDURE TO RptEngin, ..\WZCommon\WZEngine

      m.oWizard=CreateObj("ReportEngine")
   
	  IF LOWER(m.cOutFileVarName) = "wbreturnvalue" AND TYPE(cOutFileVarName) = 'C'
	  	m.cOutFileVarName = EVAL(cOutFileVarName)
	  ENDIF
	  
      IF !EMPTY(m.cOutFileVarName)	&& output file name provided
          m.oWizard.cOutFile = m.cOutFileVarName
      ENDIF
		
      m.oWizard.AutoReport(m.p4)

      RELEASE m.oWizard

      SET PROC TO &cProcs
      SET CLASSLIB TO &cClassLib

      RETURN
      
   CASE "AUTOLABEL"$UPPER(m.p2)
      SET PROCEDURE TO RptEngin, ..\WZCommon\WZEngine

      m.oWizard=CreateObj("LabelEngine")
   
	  IF LOWER(m.cOutFileVarName) = "wbreturnvalue" AND TYPE(cOutFileVarName) = 'C'
	  	m.cOutFileVarName = EVAL(cOutFileVarName)
	  ENDIF
	  
      IF !EMPTY(m.cOutFileVarName)	&& output file name provided
         m.oWizard.cOutFile = m.cOutFileVarName
      ENDIF
		
      m.oWizard.AutoReport(m.p4)

      RELEASE m.oWizard

      SET PROC TO &cProcs
      SET CLASSLIB TO &cClassLib

      RETURN
      
   CASE "1MANY" $ UPPER(m.p2)
      m.cWizardToRun = "mReportWizard"      && 1-Many Report Wizard
   CASE "LABEL" $ UPPER(m.p2)
      m.cWizardToRun = "LabelWizard"        && Group & Total Report Wizard
   OTHERWISE
      m.cWizardToRun = "ReportWizard"       && Report Wizard
ENDCASE


* Modify here to reference your wizard's .vcx.

set classlib to RptWiz

public oWizard

* The name "oWizard" is used in automated testing and should *NOT* be changed.
oWizard = createobj(m.cWizardToRun, m.cOutFileVarName, m.p2, m.p3, m.p4, ;
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

CLEAR CLASS &cWizardToRun
CLEAR CLASS wiztemplate

return


PROCEDURE dummy
	* This routine is used to resolve Project array references.
	public aflds[1], aFieldsToDraw[1]
ENDPROC


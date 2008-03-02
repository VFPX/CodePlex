PARAMETERS cOutputVarname, p2, p3, p4, p5, p6, p7, p8, p9

* cOutputVarname holds the name of the wizard.app memvar, as a char string, that will return the name
* of the created file to the project manager. This parameter is passed into the wizard in the CREATE 
* statement below. Wiztemplate handles storing the name of the created file to the contents of this memvar.

* cOutputFilename is a memvar created in this program that will also hold the name of the created file, to
* support the MODIFY and BROWSE options below, coming out of the wizard. It gets updated in the ProcessOutput
* method of the wizard's engine, and has nothing to do with Wiztemplate or the memvar that gets passed back to
* the Project Manager.

private cClassLib
local cOnError, lError

m.wzt_outoption = 1
m.cOutputFilename = ""

m.cClassLib = set('classlib')

SET CLASSLIB TO wztable

PUBLIC oWizard

* The name "oWizard" is used in automated testing and should *NOT* be changed.
* The wizard will save and restore the environment, so no need to do it here

oWizard = CREATE("TableWizard",m.cOutputVarname, m.p2, m.p3, m.p4, m.p5, m.p6, m.p7, m.p8, m.p9)
#if .f.
on error &cOnError
#endif

if type('oWizard') = 'O' .and. .not. isnull(oWizard)
	oEngine.aEnvironment[17,1] = m.cClassLib
	oWizard.Show
endif
if type('oWizard') = 'O' .and. .not. isnull(oWizard)
	* It must be modeless, so leave it alone
else
	release oWizard
	CLEAR CLASS TableWizard
	CLEAR CLASS wiztemplate
endif

SET MESSAGE TO

IF TYPE("m.cOutputFilename") = "C"
	IF NOT EMPTY(m.cOutputFilename) 
		IF FILE(m.cOutputFilename)
			DO CASE
				CASE m.wzt_outoption = 2
					USE (m.cOutputFilename)
	  				BROWSE NORMAL NOWAIT
				CASE m.wzt_outoption = 3
					USE (m.cOutputFilename) EXCLUSIVE
					MODIFY STRUCTURE
			ENDCASE
		ENDIF
	ENDIF
ENDIF



RETURN

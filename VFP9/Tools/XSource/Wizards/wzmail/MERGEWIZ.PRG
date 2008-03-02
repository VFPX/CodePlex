EXTERNAL ARRAY addfields

#INCLUDE "mergewiz.h"

#DEFINE ISWORD20 .F.
#DEFINE L_DEBUG .F.

DEFINE CLASS MergeEngine AS WizEngineAll

	cWizClass	= "ole"				&& wizard class	(e.g., report)
	cWizName	= "mergewizard"		&& wizard name or class (e.g., Group/Total report)

	nWordProc	= N_WORD60			&& default is Word 6.0
	nNewDoc		= N_NEW_DOC			&& create a new or use an existing document
	nTemplate	= N_FORMLETTER		&& type of document to create (Word 6.0 only)
	cDocName	= ""				&& name of master merge document
	cMrgData	= ""				&& file that will contain merge data if non-60

	oMM			= .NULL.			&& the MailMerge object
	
#IF L_DEBUG
	PROCEDURE Error
		PARAMETER ErrorNum, Method, Line
		THIS.ALERT("Error: " + message() + C_CRLF + ;
			"Error Number: " + ALLT(STR(m.Errornum)) + C_CRLF + ;
			"Method: " + m.Method + C_CRLF + ;
			"Line: " + LTRIM(STR(LINENO())) + ": " + message(1))
		SET TRBE OFF
		ACTI WINDOW DEBUG
		ACTI WINDOW TRACE
		SUSPEND
	ENDPROC
#ENDIF

	*----------------------------------
	PROCEDURE Init2
	*----------------------------------
		THIS.GetOS()	&& fills in THIS.nCurrentOS
		IF THIS.nCurrentOS == OS_DOS OR THIS.nCurrentOS == OS_UNIX  && fail
			RETURN .F.
		ENDIF

		THIS.iHelpContextID = N_HELPCONTEXT_ID

		*- create the MailMerge object
		SET CLASS TO MailMrge ADDITIVE
		THIS.oMM = CREATEOBJECT("MailMerge")
		
		IF TYPE("THIS.oMM") # 'O'
			THIS.Alert(E_NOMAILMERGE_LOC)
			RETURN .F.
		ENDIF
		
		RETURN .T.

	ENDPROC


	*----------------------------------
	PROCEDURE Destroy
	*----------------------------------
		RELEASE CLASSLIB MailMrge
		
		WizEngineAll::Destroy
		
	ENDPROC
	
	
	*----------------------------------
	PROCEDURE MakeMergeFile
	*----------------------------------

		THIS.oMM.cAppTitle = ALERTTITLE_LOC		&& the name of our app
		THIS.oMM.nWordProc = THIS.nWordProc		&& word processor
		THIS.oMM.nNewDoc = THIS.nNewDoc			&& is it a new doc?
		THIS.oMM.nTemplate = THIS.nTemplate		&& type of main document (Word only)
		THIS.oMM.cDocName = THIS.cDocName		&& doc file if not new

		THIS.oMM.cAlias = THIS.cWizAlias
		THIS.oMM.cDBCTable = THIS.cDBCTable
		THIS.oMM.cDBCName = THIS.cDBCName
		
		ACOPY(THIS.aWizFields, THIS.oMM.aAutoFields)
		
		
		THIS.oMM.MakeOutput

		RETURN
		
	ENDPROC

ENDDEFINE		&& MergeEngine
*- eof

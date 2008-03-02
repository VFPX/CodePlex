#INCLUDE "PIVOT.H"

DEFINE CLASS PivotEngine AS WizEngineAll

	cWizClass = "ole"			&&wizard class	(e.g., report)
	cWizName  = "pivotwizard"	&&wizard name or class (e.g., Group/Total report)
	
	iHelpContextID = N_HELPCONTEXT_ID	&&help id

	cPivFldData = ""			&&Pivot data field
	cPivFldPage = ""			&&Pivot page field
	cPivFldRow = ""				&&Pivot row field
	cPivFldCol = ""				&&Pivot column field

	oPiv		= .NULL.		&& the PivotTable object

	lHasColumnTotals = .T.		&&Column totals
	lHasRowTotals = .T.			&&Row totals
	lIsNumeric = .F.			&&numeric data type
	
	nCurrentOS = 0				&&operating system
	
	*----------------------------------
	PROCEDURE Init2
	*----------------------------------

		THIS.GetOS()
		IF THIS.nCurrentOS > 4  &&fail
			RETURN .F.
		ENDIF

		*- create the PivotTable object
		SET CLASS TO PivTable ADDITIVE
		THIS.oPiv = CREATEOBJECT("PivotTable")
		
		IF TYPE("THIS.oPiv") # 'O'
			THIS.Alert(E_NOPIVOTTBL_LOC)
			RETURN .F.
		ENDIF
		
		*- OK, so let's proceed
		RETURN .T.
	ENDPROC
	
	*----------------------------------
	PROCEDURE Destroy
	*----------------------------------
		RELEASE CLASSLIB PivTable
		
		WizEngineAll::Destroy
		
	ENDPROC
	
	
	*----------------------------------
	PROCEDURE GetSaveFile
	*----------------------------------
		PARAMETER cCurAlias
		IF THIS.nWizAction # 2	&&no Form created -- output to XL
			RETURN .T.
		ENDIF
		LOCAL getfname
		THIS.GetOS()

		DO CASE
		CASE THIS.nCurrentOS = OS_W32S AND ;
		  CURSORGETPROP("sourcetype",m.cCurAlias) = 3
			* use short DOS name for Win32S
			getfname = THIS.ForceExt(DBF(m.cCurAlias),"SCX")
		CASE THIS.nCurrentOS = OS_W32S
			getfname = LEFT(m.cCurAlias,8) + ".SCX"
		OTHERWISE
			getfname = THIS.ForceExt(cursorgetprop("sourcename",m.cCurAlias),"SCX")
		ENDCASE
		
		RETURN THIS.SaveOutFile(C_SAVEPROMPT_LOC,m.getfname,"SCX")  &&use canceled
	ENDPROC

	*----------------------------------
	PROCEDURE MakeOutput
	*----------------------------------

		THIS.cWizAlias = ALIAS()

		THIS.oPiv.cAppTitle = ALERTTITLE_LOC		&& the name of our app
		*- Assure we have some default output action
		IF TYPE('THIS.nWizAction') # 'N' 
			THIS.oPiv.nAction = 1
		ELSE
			THIS.oPiv.nAction = THIS.nWizAction
		ENDIF
		
		THIS.oPiv.cAlias = THIS.cWizAlias
		THIS.oPiv.cOldMessage = SET("MESSAGE",1)
		THIS.oPiv.cDBCTable = THIS.cDBCTable
		THIS.oPiv.cDBCName = THIS.cDBCName
		
		THIS.oPiv.cPivFldRow = THIS.cPivFldRow
		THIS.oPiv.cPivFldCol = THIS.cPivFldCol
		THIS.oPiv.cPivFldData = THIS.cPivFldData
		THIS.oPiv.cPivFldPage = THIS.cPivFldPage
		
		THIS.oPiv.lHasColumnTotals = THIS.lHasColumnTotals
		THIS.oPiv.lHasRowTotals = THIS.lHasRowTotals
		
		THIS.oPiv.cOutFile = THIS.cOutFile
		THIS.oPiv.cFormSCX = "excel1"
		THIS.oPiv.lHasNoTask = THIS.lHasNoTask
		
		=ACOPY(THIS.aWizFields, THIS.oPiv.aAutoFields)
		=ACOPY(THIS.aWizFList, THIS.oPiv.aFldList)

		THIS.oPiv.MakeOutput

		RETURN

	ENDPROC

ENDDEFINE
#DEFINE 	C_SAVEPROMPT_LOC	"Save query as:"
#DEFINE		NOGENXTAB_LOC		"Could not locate GENXTAB.PRG file. Make sure you have it properly installed."
#DEFINE		GENXTAB_FILE		"VFPXTAB.PRG"
#DEFINE		FIELDERR_LOC		"Could not create crosstab from table selected."
#DEFINE		RUNQUERY_LOC		"Running query..."
#DEFINE		C_NOVIEWS_LOC		"Views are not supported in QPR files."
#DEFINE		C_CRLF 				CHR(13)+CHR(10)
#DEFINE 	OS_W32S				1

DEFINE CLASS XtabEngine AS WizEngineAll

	cWizClass = "misc"			&&wizard class	(e.g., report)
	cWizName  = "xtabwizard"	&&wizard name or class (e.g., Group/Total report)
	iHelpContextID = 1895825410	&&help id

	cPivFldData = ""			&&Pivot data field
	cPivFldPage = ""			&&Pivot page field
	cPivFldRow = ""				&&Pivot row field
	cPivFldCol = ""				&&Pivot column field

	lHasColumnTotals = .T.		&&Column totals
	lHasRowTotals = .T.			&&Row totals
	lIsNumeric = .F.			&&numeric data type
	nTotalType = 0				&&total type (1-sum,2-count,3-% total)
	nFldSumType = 1				&&field sum type (1-sum,2-count,3-average,4-max,5-min)
	lDisplayNulls = .T.			&&display null values
	
	ordExpr = ""				&&order by, group by expression
	fldExpr = ""				&&fields expression
	cXtabAlias = ""				&&alias for query
	cXtabSource = ""			&&data source for query
	
	PROCEDURE Init2
		THIS.GetOS()
	ENDPROC

	PROCEDURE GetSaveFile
		PARAMETER cCurAlias
		LOCAL getfname
		IF THIS.nWizAction = 0
			RETURN .T.
		ENDIF
		DO CASE
		CASE THIS.nCurrentOS = OS_W32S AND ;
		  CURSORGETPROP("sourcetype",m.cCurAlias) = 3
			* use short DOS name for Win32S
			getfname = THIS.ForceExt(DBF(m.cCurAlias),"QPR")
		CASE THIS.nCurrentOS = OS_W32S 
			getfname = LEFT(m.cCurAlias,8) + ".QPR"
		OTHERWISE
			getfname = THIS.ForceExt(cursorgetprop("sourcename",m.cCurAlias),"QPR")
		ENDCASE

		RETURN THIS.SaveOutFile(C_SAVEPROMPT_LOC,m.getfname,"QPR")  &&use canceled
	ENDPROC

	PROCEDURE MakeOutput
		LOCAL cQPRFile,cDataFld 
		* Make sure we have _GENXTAB file
		IF EMPTY(_GENXTAB)
			IF FILE(HOME()+GENXTAB_FILE)
				_GENXTAB = HOME()+GENXTAB_FILE
			ELSE
				THIS.ALERT(NOGENXTAB_LOC)
				RETURN	
			ENDIF
		ENDIF
		
		IF TYPE('THIS.nWizAction') # 'N'
			THIS.nWizAction = 3
		ENDIF
		
		* Check fields
		IF EMPTY(THIS.cPivFldData)
			THIS.cPivFldData= THIS.GetNewField(0)
		ENDIF
		IF EMPTY(THIS.cPivFldRow)
			THIS.cPivFldRow = THIS.GetNewField()
		ENDIF
		IF EMPTY(THIS.cPivFldCol)
			THIS.cPivFldCol= THIS.GetNewField()
		ENDIF

		IF EMPTY(THIS.cPivFldRow) OR EMPTY(THIS.cPivFldCol) OR EMPTY(THIS.cPivFldData)
			THIS.ALERT(FIELDERR_LOC)
			RETURN
		ENDIF
		
		IF !EMPTY(CURSORGETPROP("database"))			&& DBC stuff
			THIS.cXtabSource = PROPER(CURSORGETPROP("SourceName"))
		ELSE											&& free tables
			THIS.cXtabSource = SYS(2014,DBF(),THIS.cOutFile)
		ENDIF

		THIS.cXtabAlias = ALIAS()
		
		* Get SQL Select statement pieces
		THIS.ordExpr = THIS.cXtabAlias +"."+THIS.cPivFldRow+", "+THIS.cXtabAlias+"."+THIS.cPivFldCol
		
		* Get field expression
		m.cDataFld = THIS.cXtabAlias +"."+THIS.cPivFldData

		DO CASE
		CASE INLIST(THIS.nFldSumType,1,3) AND ATC(TYPE(m.cDataFld),"NFIYB")=0 
			* non-numeric data type
			THIS.fldExpr = THIS.ordExpr+", "+m.cDataFld
			THIS.ordExpr = THIS.fldExpr
		CASE THIS.nFldSumType = 1	&& sum
			THIS.fldExpr = THIS.ordExpr+", SUM("+m.cDataFld+")"
		CASE THIS.nFldSumType = 2	&& count
			THIS.fldExpr = THIS.ordExpr+", COUNT("+m.cDataFld+")"
		CASE THIS.nFldSumType = 3	&& average
			THIS.fldExpr = THIS.ordExpr+", AVG("+m.cDataFld+")"
		CASE THIS.nFldSumType = 4	&& max
			THIS.fldExpr = THIS.ordExpr+", MAX("+m.cDataFld+")"
		CASE THIS.nFldSumType = 5	&& min		
			THIS.fldExpr = THIS.ordExpr+", MIN("+m.cDataFld+")"
		ENDCASE
		
		* Check totaling
		THIS.lHasRowTotals = (THIS.nTotalType#4)
		
		* Map total property to that of VFPXTAB 
		THIS.nTotalType = THIS.nTotalType - 1
		
		* User hit Preview button
		IF THIS.nWizAction = 0
			THIS.RunXtab()
			THIS.nTotalType = THIS.nTotalType + 1
			RETURN
		ENDIF
		
		m.cQPRFile = "'"+THIS.cOutFile+"'"
		THIS.MakeQPR()

		* Handle View since we did a USE ... NODATA in Wizard
		IF CURSORGETPROP("SourceType") # 3
			IF THIS.nWizAction = 1
				USE
			ELSE
				=REQUERY()
				GO TOP
			ENDIF
		ENDIF
		
		DO CASE
		CASE THIS.nWizAction = 1	&&save cross tab query
			* Nothing - just return
		CASE THIS.nWizAction = 2	&&save and run cross tab query
			_SHELL = [DO &cQPRFile]
		CASE THIS.nWizAction = 3	&&save and modify cross tab query
			_SHELL = [MODIFY QUERY &cQPRFile NOWAIT]
		ENDCASE
		
	ENDPROC

	PROCEDURE RunXtab
		* Preview here
		LOCAL cAlias,cOrd,cFld,cTmpAlias
		m.cAlias = THIS.cXtabAlias
		m.cOrd = THIS.ordExpr
		m.cFld = THIS.fldExpr

		SELECT &cFld ;
			FROM &cAlias ; 
			GROUP BY &cOrd ; 
			ORDER BY &cOrd ;
			INTO CURSOR SYS(2015)
		m.cTmpAlias = ALIAS()
		WAIT CLEAR
		
		IF !THIS.haderror
			DO (_GENXTAB) WITH "wizquery",.t.,.t.,.t.,,,,THIS.lHasRowTotals,THIS.nTotalType,THIS.lDisplayNulls
			IF UPPER(ALIAS())="WIZQUERY"
				BROWSE NOMODIFY NORMAL
			ENDIF
		ENDIF
		
		* Check to see if VFPXTAB failed
		IF USED(m.cTmpAlias)
			USE IN (m.cTmpAlias)
		ENDIF
	ENDPROC
	
	PROCEDURE MakeQPR
		* Makes a temporary cursor with memo to create QPR files
		LOCAL cTmpCursor,nWkArea,cFullTable,cDBCPath
		m.nWkArea = SELECT()
		m.cTmpCursor = SYS(2015)
		m.cFullTable = THIS.cXtabSource

		IF !EMPTY(CURSORGETPROP('database'))  &&lets put the DBC alias before table
			cDBCPath = THIS.JustStem(SYS(2014,CURSORGETPROP('database'),THIS.cOutFile))
			cFullTable = m.cDBCPath + "!" + m.cFullTable
		ENDIF
		
		cFullTable = "'"+m.cFullTable+"' "+THIS.cXtabAlias
		
		CREATE CURSOR (m.cTmpCursor) (sqlstring m)
		APPEND BLANK
		REPLACE sqlstring WITH ;
			"SELECT "+THIS.fldExpr + ";" + C_CRLF +;
			"    FROM " + m.cFullTable + ";" + C_CRLF +;
			"    GROUP BY " + THIS.ordExpr + ";" + C_CRLF +;
			"    ORDER BY " + THIS.ordExpr + ";" + C_CRLF +;
			"    INTO CURSOR SYS(2015)" + C_CRLF +;
			"DO (_GENXTAB) WITH 'Query'"+;
			IIF(THIS.lHasRowTotals,",.t.,.t.,.t.,,,,.t.,"+ALLTRIM(STR(THIS.nTotalType))+;
			IIF(THIS.lDisplayNulls,',.t.',',.f.'),IIF(!THIS.lDisplayNulls,"",",,,,,,,,,.t.")) + C_CRLF +;
			"BROWSE NOMODIFY" ADDITIVE


		COPY MEMO sqlstring TO (THIS.cOutFile)
		USE
		SELECT (m.nWkArea)
	ENDPROC
	
	PROCEDURE GetNewField
		LPARAMETER p1
		* This routine finds a field if one not selected.
		LOCAL i,tmparr,lNumPref 
		m.lNumPref = (PARAMETER()=1)
		DIMENSION tmparr[1]
		=AFIELDS(tmparr)
		
		IF m.lNumPref 
			FOR i = 1 TO FCOUNT()
				* Check to make sure field is not being used or General/Memo field.
				IF !INLIST(FIELD(m.i),UPPER(THIS.cPivFldRow),;
					UPPER(THIS.cPivFldCol),UPPER(THIS.cPivFldData)) AND ;
					INLIST(tmparr[m.i,2],"N","F","Y","B")
					RETURN FIELD(m.i)
				ENDIF
			ENDFOR
		ENDIF

		FOR i = 1 TO FCOUNT()
			* Check to make sure field is not being used or General/Memo field.
			IF !INLIST(FIELD(m.i),UPPER(THIS.cPivFldRow),;
				UPPER(THIS.cPivFldCol),UPPER(THIS.cPivFldData)) AND ;
				!INLIST(tmparr[m.i,2],"G","M")
				RETURN FIELD(m.i)
			ENDIF
		ENDFOR
		
		RETURN ""
	ENDPROC
	
	FUNCTION stripext
		LPARAMETER filename
		LOCAL dotpos, terminator
		dotpos = RAT(".", m.filename)
		terminator = MAX(RAT("\", m.filename), RAT(":", m.filename))
		IF m.dotpos > m.terminator
		   filename = LEFT(m.filename,m.dotpos-1)
		ENDIF
		RETURN m.filename
	ENDFUNC
	
ENDDEFINE
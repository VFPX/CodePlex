* Program....: rptengin.prg
* Notice.....: Copyright (c) 1995 - 2004 Microsoft Corp.
* Abstract...:
*  Report wizard engine.  Processing for:
*     1) Regular reports
*     2) Multi-column reports
*     3) Group reports
*     4) Labels
*     5) AutoReport


#INCLUDE "FOXPRO.H"
#INCLUDE "RPTENGIN.H"

#DEFINE SCREEN_DPI	96		&& designer is hard-coded to 96

EXTERNAL ARRAY aWizFList
EXTERNAL ARRAY aWizTables
EXTERNAL ARRAY aWizSorts
EXTERNAL ARRAY aSortArray


*--------------------------------------------------------------------
*>> Class Definition: MainEngine
* Abstract:
*  The ReportEngine and LabelEngine are derived from this class.
*  Primarily common data members & support methods used by
*  both classes.
*--------------------------------------------------------------------
DEFINE CLASS MainEngine AS WizEngineAll
	PROTECTED ThermWinName, nThermCurrent, nThermTotal, cPlatform

	cPlatform		= "WINDOWS"
	lModified		= .T.      && set to TRUE if any options have been changed
	lSaveEnviron	= .T.      && save environment
	cStyleFile		= ""       && report file containing our style template
	nColumns		= 1        && number of columns on report
	lTruncate		= .F.      && Truncate (.T.) or wrap (.F.) fields that don't fit
	lUseMask		= .F.		&& use inputmask and format settings store in the DBC
	lPercentOfTotal = .F.		&& include percent of total for sums

	DIMENSION aStyleRec[1,3]
	aStyleRec = ""


	* Properties for thermometer
	ThermWinName = ""       && thermometer ref
	lUseTherm = .T.         && use a thermometer?
	nThermCurrent = 0       && thermometer percent
	nThermTotal = 0         && thermometer percent

	** One to Many Specific properties
	cParentAlias = ""
	cParentDBCName = ""
	cParentDBCAlias = ""
	cParentDBCTable = ""
	cMainKey = ""
	cRelatedKey = ""
	DIMENSION aParentFields[1,1]
	aParentFields= ""
	DIMENSION aParentFList[1,1]
	aParentFList = ""
	DIMENSION aParentLabels[1,1]
	aParentLabels = ""
	DIMENSION aParentSorts[1,1]
	aParentSorts = ""


	PROCEDURE Init2
		DO CASE
		CASE _WINDOWS
			THIS.cPlatform = "WINDOWS"
		CASE _DOS
			THIS.cPlatform = "DOS"
		CASE _MAC
			THIS.cPlatform = "MAC"
		ENDCASE
	ENDPROC


	*>> AutoReport: Generate auto report
	* Abstract:
	*   Creates a vertical-layout report using _ALL_ the field in the current table.
	*-  Supports passing an object
	PROCEDURE AutoReport
		PARAMETER oSettings
		LOCAL i,aStyParms,nTotTables,aDBCTables, cGetFname
		LOCAL lHasObj

		IF PARAMETERS() = 1 AND TYPE("oSettings") = "O"
			lHasObj = .T.
		ENDIF

		IF !m.lHasObj AND EMPTY(ALIAS())
			RETURN
		ENDIF

		IF m.lHasObj AND PEMSTATUS(m.oSettings,'cWizTable',5) AND;
				!EMPTY(oSettings.cWizTable) AND FILE(oSettings.cWizTable)
			IF PEMSTATUS(m.oSettings,'cWizAlias',5) AND !EMPTY(oSettings.cWizAlias)
				IF USED(oSettings.cWizAlias)
					SELECT (oSettings.cWizAlias)
				ELSE
					SELECT 0
					USE (oSettings.cWizTable) AGAIN  ALIAS (oSettings.cWizAlias)
				ENDIF
			ELSE
				SELECT 0
				USE (oSettings.cWizTable) AGAIN
			ENDIF
		ENDIF

		IF !EMPTY(ALIAS())  && DBF selected

			THIS.cWizAlias = ALIAS()
			THIS.cDBCName = CURSORGETPROP('Database')

			IF !EMPTY(THIS.cDBCName)
				THIS.cDBCTable = CURSORGETPROP('SourceName')	 && DBC Table name
				IF ATC(SET("DATA"),THIS.cDBCName) = 0
					SET DATABASE TO (THIS.cDBCName)
				ENDIF
			ENDIF

			*- Get field list
			DO CASE
				CASE m.lHasObj AND TYPE("m.oSettings.lBlankForm")="L" AND !EMPTY(oSettings.lBlankForm)
					DIMENSION THIS.aWizFields[1]
					THIS.aWizFields = ""
				CASE m.lHasObj AND TYPE("m.oSettings.aWizFields[1,1]")="C" AND !EMPTY(oSettings.aWizFields)
					=ACOPY(oSettings.aWizFields,THIS.aWizFields)
				OTHERWISE
					DIMENSION THIS.aWizFields[FCOUNT(),1]
					FOR i = 1 TO FCOUNT()
						THIS.aWizFields[m.i,1] = PROPER(FIELD[m.i])
					ENDFOR
			ENDCASE
			=AFIELDS(THIS.aWizFList)

			*- Get style
			IF m.lHasObj AND PEMSTATUS(m.oSettings,'cStyleFile',5)
				IF !EMPTY(oSettings.cStyleFile)
					IF !FILE(oSettings.cStyleFile)
						RETURN
					ELSE
						THIS.cStyleFile = oSettings.cStyleFile
					ENDIF
				ENDIF
			ENDIF

			* Get sort field list
			IF m.lHasObj AND TYPE("m.oSettings.aWizSorts[1]")="C" AND !EMPTY(oSettings.aWizSorts)
				=ACOPY(oSettings.aWizSorts,THIS.aWizSorts)
			ENDIF

			*- Get sort ascend
			IF m.lHasObj AND PEMSTATUS(m.oSettings,'lSortAscend ',5)
				THIS.lSortAscend = oSettings.lSortAscend
			ENDIF

			*- Get truncate
			IF m.lHasObj AND PEMSTATUS(m.oSettings,'lTruncate',5)
				THIS.lTruncate = oSettings.lTruncate
			ENDIF

		ENDIF	&& DBF selected

		IF m.lHasObj AND PEMSTATUS(m.oSettings,'cOutFile',5) 
			IF !EMPTY(oSettings.cOutFile)
				THIS.cOutFile= THIS.FORCEEXT(oSettings.cOutFile,"FRX")
			ELSE
				m.cGetFname = IIF(EMPTY(ALIAS()), C_DEFAULTREPORT_LOC, THIS.ForceExt(DBF(),"FRX"))
				IF !THIS.SaveOutFile(SAVEAS_LOC, m.cGetFname, "FRX")
					* Note: SaveOutFile sets THIS.cOutFile property
					RETURN
				ENDIF
			ENDIF
			oSettings.cOutFile = THIS.cOutFile
		ELSE
			IF !THIS.SaveOutFile(SAVEAS_LOC, THIS.ForceExt(DBF(),"FRX"), "FRX")
				* Note: SaveOutFile sets THIS.cOutFile property
				RETURN
			ENDIF
		ENDIF

		*- Get layout
		IF m.lHasObj AND PEMSTATUS(m.oSettings,'nLayout',5)
			THIS.nLayout = oSettings.nLayout
		ENDIF

		*- Get # of columns
		IF m.lHasObj AND PEMSTATUS(m.oSettings,'nColumns',5)
			THIS.nColumns = oSettings.nColumns
		ENDIF

		*- Get landscape
		IF m.lHasObj AND PEMSTATUS(m.oSettings,'lLandscape',5)
			THIS.lLandscape = oSettings.lLandscape
		ENDIF

		* Get action to perform when done processing
		IF m.lHasObj AND PEMSTATUS(m.oSettings,'nWizAction',5) AND !EMPTY(oSettings.nWizAction)
			THIS.nWizAction = oSettings.nWizAction
		ELSE
			THIS.nWizAction = GO_MODIFY
		ENDIF

		* Get report title
		DO CASE
			CASE m.lHasObj AND PEMSTATUS(m.oSettings,'cWizTitle',5) AND !EMPTY(oSettings.cWizTitle)
				THIS.cWizTitle = oSettings.cWizTitle
			CASE EMPTY(ALIAS())
				THIS.cWizTitle = JUSTSTEM(THIS.cOutFile) 
			OTHERWISE
				THIS.cWizTitle = PROPER(ALIAS())
		ENDCASE

		THIS.Process()

	ENDPROC



	*>> SetTherm: Setup the thermometer
	PROCEDURE SetTherm
		LPARAMETER cMessage, nTotal, nCurrent

		IF !THIS.lUseTherm
			RETURN
		ENDIF


		IF TYPE("m.cMessage") <> "C"
			m.cMessage = THERM_MSG_LOC
		ENDIF

		IF TYPE("m.nTotal") <> "N"
			m.nTotal = 5 + ALEN(THIS.aWizFields)
		ENDIF

		IF TYPE("m.nCurrent") <> "N"
			m.nCurrent = 0
		ENDIF

		IF TYPE('THIS.ThermRef') # "O" .OR. ISNULL(THIS.ThermRef)
			THIS.AddTherm(m.cMessage)
		ENDIF
		THIS.nThermCurrent = m.nCurrent
		THIS.nThermTotal = m.nTotal


		THIS.ThermWinName = THIS.ThermRef.Name
		THIS.ThermRef.visible = .t.

	ENDPROC

	*>> DoTherm: Display thermometer updates
	PROCEDURE DoTherm
		LPARAMETER nPercent, cMessage, cAction

		IF !THIS.lUseTherm
			RETURN
		ENDIF



		IF TYPE('m.nPercent') # 'N'
			m.nPercent = 0
		ENDIF

		IF TYPE('m.cMessage') # 'C'
			m.cMessage = ""
		ENDIF

		IF TYPE('m.cAction') # 'C'
			m.cAction = ""
		ENDIF

		IF !EMPTY(m.cAction) AND TYPE('THIS.ThermRef') = "O"
			DO CASE
			CASE UPPER(m.cAction) = "HIDE"
				THIS.ThermRef.visible = .f.
			CASE UPPER(m.cAction) = "SHOW"
				THIS.ThermRef.visible = .t.
			ENDCASE
			RETURN
		ENDIF


		IF TYPE('THIS.ThermRef') # "O" AND m.nPercent = -1
			RETURN
		ENDIF

		* First time
		IF TYPE('THIS.ThermRef') # "O"
			THIS.SetTherm()
		ENDIF

		IF THIS.ThermRef.visible = .F.
			THIS.ThermRef.visible = .T.
		ENDIF

		* Done
		IF m.nPercent = -1
			THIS.ThermRef.Complete()
			THIS.ThermRef.Hide()
			RELEASE WINDOW (THIS.ThermWinName)
			RETURN
		ENDIF

		THIS.nThermCurrent = THIS.nThermCurrent + 1        && thermometer percent

		IF m.nPercent = 0
			m.nPercent = ROUND(THIS.nThermCurrent/THIS.nThermTotal*100,0)
		ENDIF
		m.nPercent = MIN(100,m.nPercent)

		*- Update thermometer
		THIS.ThermRef.Update(m.nPercent,m.cMessage)

	ENDPROC



	*>> InsDataEnv: Insert Data Environment
	* Abstract:
	*   Create the data environment records for the new report.
	*   This method will also call AddCdxTag to do any indexing which
	*   is required.
	*
	PROTECTED PROCEDURE InsDataEnv
		LPARAMETERS oEnviron
		LOCAL i, j, nSelect, cName, cExpr, cTagName, cDBC
		LOCAL cSumVar, cBeforeOpenTablesCode, cAfterCloseCode

		IF !THIS.lSaveEnviron .OR. TYPE("oEnviron") <> "O"
			RETURN
		ENDIF

		*- if no datasource, return
		IF EMPTY(THIS.cWizAlias)
			RETURN
		ENDIF
		
		m.cDBC = DBC()
		m.nSelect = SELECT()

		m.cBeforeOpenTablesCode = ""
		m.cAfterCloseCode = ""
		
		* Add data environment record
		m.cExpr = [Name = "Dataenvironment"] + NEWLINE


		IF !EMPTY(THIS.cParentAlias)
			m.cExpr = m.cExpr + [InitialSelectedAlias = "] + LOWER(THIS.cParentAlias) + ["] + NEWLINE
		ENDIF

		*- add code to calculate the % of total if group report, and including sums, 
		*- and have checked lPercentOfTotal checkbox, and there is something to sum
		IF THIS.lPercentOfTotal AND THIS.nTotalCnt > 0
			*- each field that is to be summed will also be percented
			*- xxx
			cSumVars = ""
			FOR i = 1 TO THIS.nTotalCnt
				cSumVars = cSumVars + "," + ALLTRIM(THIS.aWizTotals[i, 1])
			NEXT
			cSumVars = SUBS(cSumVars,2)
			m.cBeforeOpenTablesCode = STRTRAN(C_PROCSTART,"@1","BeforeOpenTables") + ;
								C_DECODE_A1 + ;
								C_DECODE_A1A + ;
								STRTRAN(C_DECODE_A2,"%1",LTRIM(STR(THIS.nTotalCnt))) + ;
								C_DECODE_A3 + ;
								STRTRAN(C_DECODE_A4,"%1",cSumVars) + ;
								C_DECODE_A5 + ;
								C_PROCEND
								
			m.cAfterCloseCode = STRTRAN(C_PROCSTART,"@1","AfterCloseTables") + ;
								C_DECODE_A1A + ;
								C_PROCEND

		ENDIF
		
		
		WITH oEnviron
			.ObjType = OT_DATAENV
			.Name    = [dataenvironment]
			.Expr    = m.cExpr
			.Environ = .F.	&& Set to TRUE for a Private Data Session
			.Tag = m.cBeforeOpenTablesCode + m.cAfterCloseCode
		ENDWITH


		THIS.OInsert(oEnviron, "NewRpt")

		* Add parent database/table record (for 1-to-many reports)
		IF !EMPTY(THIS.cParentAlias)
			SELECT (THIS.cParentAlias)

			m.cExpr = ""

			* Update thermometer status
			THIS.DoTherm(0, THERM_INDEX_LOC)

			IF !EMPTY(THIS.aParentSorts[1,1])
				IF THIS.lHasSortTag
					m.cTagName = THIS.aParentSorts[1,1]
				ELSE
					m.cTagName = THIS.AddCdxTag("aParentSorts", "aParentFList")
				ENDIF
				m.cExpr = m.cExpr + [Order = "] + LOWER(m.cTagName) + ["] + NEWLINE
			ELSE
				*- make sure index isn't still going to be used
				SET ORDER TO 0
			ENDIF

			m.cExpr = m.cExpr + [Alias = "] + LOWER(THIS.cParentAlias) + ["] + NEWLINE

			IF EMPTY(THIS.cParentDBCName)
				* SYS(2014) in the following command returns the minimum path, in this case
				* relative to where the report file is going
				m.cExpr = m.cExpr + [CursorSource = ] + LOWER(SYS(2014, DBF(), THIS.cOutFile)) + NEWLINE
			ELSE
				m.cExpr = m.cExpr + [Database = ] + LOWER(THIS.cParentDBCName) + NEWLINE
				m.cExpr = m.cExpr + [CursorSource = "] + LOWER(THIS.cParentDBCTable) + ["] + NEWLINE

				* If this is a view, then requery if record count is 0 because that means
				* the view was opened with the NODATA clause.
				SET DATABASE TO (THIS.cParentDBCName)
				IF INDBC(THIS.cParentDBCTable, "VIEW") .AND. RECCOUNT(THIS.cParentAlias) == 0
					This.SetErrorOff = .t.
					=REQUERY(THIS.cParentAlias)
					This.SetErrorOff = .f.
				ENDIF
			ENDIF

			m.cExpr = m.cExpr + [Name = "cursor1"] + NEWLINE

			WITH oEnviron
				.ObjType = OT_DERECORD
				.Name = "cursor"
				.Expr = m.cExpr
				.Tag = ""
			ENDWITH
			THIS.OInsert(oEnviron, "NewRpt")


			* Set the sort field for the child alias to be the related key -- index below
			THIS.aWizSorts[1, 1] = THIS.cRelatedKey
		ENDIF

		THIS.DoTherm(0, THERM_INDEX_LOC)

		* Add primary database/table record
		SELECT (THIS.cWizAlias)

		m.cExpr = ""

		* Index if we have any sort fields defined
		IF !EMPTY(THIS.aWizSorts[1, 1])
			IF EMPTY(THIS.lHasSortTag)
				m.cTagName = THIS.AddCdxTag("aWizSorts","aWizFList")
			ELSE
				m.cTagName = THIS.aWizSorts[1,1]
			ENDIF
			m.cExpr = m.cExpr + [Order = "] + LOWER(m.cTagName) + ["] + NEWLINE
		ENDIF

		m.cExpr = m.cExpr + [Alias = "] + LOWER(THIS.cWizAlias) + ["] + NEWLINE
		IF EMPTY(THIS.cDBCName)
			* SYS(2014) in the following command returns the minimum path, in this case
			* relative to where the report file is going
			m.cExpr = m.cExpr + [CursorSource = ] + LOWER(SYS(2014, DBF(), THIS.cOutFile)) + NEWLINE
		ELSE
			m.cExpr = m.cExpr + [Database = ] + LOWER(THIS.cDBCName) + NEWLINE
			m.cExpr = m.cExpr + [CursorSource = "] + LOWER(THIS.cDBCTable) + ["] + NEWLINE

			* If this is a view, then requery if record count is 0 because that means
			* the view was opened with the NODATA clause.
			SET DATABASE TO (THIS.cDBCName)
			IF INDBC(THIS.cDBCTable, "VIEW") .AND. RECCOUNT(THIS.cWizAlias) == 0
				This.SetErrorOff = .t.
				=REQUERY(THIS.cWizAlias)
				This.SetErrorOff = .f.
			ENDIF
		ENDIF

		m.cExpr = m.cExpr + [Name = "] + IIF(EMPTY(THIS.cParentAlias), "cursor1", "cursor2") + ["] + NEWLINE
		WITH oEnviron
			.ObjType = OT_DERECORD
			.Name = "cursor"
			.Expr = m.cExpr
		ENDWITH
		THIS.OInsert(oEnviron, "NewRpt")

		* Insert the relationship record
		IF !EMPTY(THIS.cParentAlias)
			m.cExpr = ""
			m.cExpr = m.cExpr + [Name = "relation1"] + NEWLINE
			m.cExpr = m.cExpr + [ParentAlias = "] + LOWER(THIS.cParentAlias) + ["] + NEWLINE
			m.cExpr = m.cExpr + [RelationalExpr = "] + LOWER(THIS.cMainKey) + ["] + NEWLINE
			m.cExpr = m.cExpr + [ChildAlias = "] + LOWER(THIS.cWizAlias) + ["] + NEWLINE
			m.cExpr = m.cExpr + [ChildOrder = "] + LOWER(m.cTagName) + ["] + NEWLINE
			m.cExpr = m.cExpr + [OneToMany = .T.] + NEWLINE

			WITH oEnviron
				.ObjType = OT_DERECORD
				.Name = "relation"
				.Expr = m.cExpr
			ENDWITH
			THIS.OInsert(oEnviron, "NewRpt")
		ENDIF

		IF !EMPTY(m.cDBC)
			SET DATABASE TO (m.cDBC)
		ENDIF

		SELECT (m.nSelect)
	ENDPROC



	*>> TStamp: Generate a FoxPro 3.0-style timestamp
	PROTECTED FUNCTION TStamp
		LPARAMETER wzpdate,wzptime
		PRIVATE d,t

		m.d = IIF(EMPTY(m.wzpdate),DATE(),m.wzpdate)
		m.t = IIF(EMPTY(m.wzptime),TIME(),m.wzptime)

		RETURN ((YEAR(m.d)-1980)    * 2 ** 25);
			+ (MONTH(m.d)        * 2 ** 21);
			+ (DAY(m.d)          * 2 ** 16);
			+ (VAL(LEFT(m.t,2))     * 2 ** 11);
			+ (VAL(SUBSTR(m.t,4,2)) * 2 **  5);
			+  VAL(RIGHT(m.t,2))
	ENDFUNC

	*>> OGather: Gather fields from the passed record object into the current table record
	* Abstract:
	*   While gathering, also sets the timestamp, uniqueid, and the platform, as
	*   well as clears the comment field.
	* Parameters:
	*   oRecord = object record to gather
	PROCEDURE OGather
		LPARAMETERS oRecord
		oRecord.Comment = ""

		IF TYPE("oRecord.UniqueID") == "C"
			oRecord.UniqueID  = SYS(2015)
		ENDIF
		IF TYPE("oRecord.TimeStamp") == "N"
			oRecord.TimeStamp = THIS.TStamp()
		ENDIF
		oRecord.Platform   = THIS.cPlatform

		GATHER NAME oRecord MEMO

		RETURN
	ENDPROC

	*>> OInsert: Inserts data from record object into specified table
	* Abstract:
	*   Inserts a new record into the specified table, and fills that record
	*   with data from the specified object record.
	* Parameters:
	*   oRecord = Object record to insert
	*   cAlias  = Alias of table to insert object record into
	PROCEDURE OInsert
		LPARAMETERS oRecord, cAlias
		LOCAL m.nSelect

		m.nSelect = SELECT()
		IF TYPE("m.cAlias") = "C"
			SELECT (m.cAlias)
		ENDIF

		APPEND BLANK
		THIS.oGather(oRecord)

		SELECT (m.nSelect)
		RETURN
	ENDPROC

	*>> Safe GOTO method
	PROTECTED FUNCTION GotoRec
		LPARAMETERS nRecNo, cAlias

		IF !EMPTY(m.cAlias)
			SELECT (m.cAlias)
		ENDIF
		DO CASE
		CASE EMPTY(alias())
		CASE BETWEEN(m.nRecNo, 1, reccount())
			GOTO m.nRecNo
		OTHERWISE
			GO BOTTOM
			IF .NOT. EOF()
				SKIP
			ENDIF && .NOT. EOF()
		ENDCASE
		RETURN (RECNO() == m.nRecNo)
	ENDFUNC


	*>> Read the properties for a given style object from the underlying style table
	FUNCTION ReadStyleRec()
		LPARAMETER cObject
		LOCAL m.nPos, m.nSelect, m.cType, m.nRecNo

		m.cObject = UPPER(m.cObject)
		m.nPos = ASCAN(THIS.aStyleRec, m.cObject)
		IF m.nPos > 0
			m.nPos = ASUBSCRIPT(THIS.aStyleRec, m.nPos, 1)

			m.nSelect = SELECT()
			m.nRecNo = RECNO()
			THIS.GotoRec(THIS.aStyleRec[m.nPos, 3], "StyleFile")

			m.cType = THIS.aStyleRec[m.nPos, 2]

			DO CASE
			CASE m.cType = "FIELD"
				SCATTER NAME (m.cObject) MEMO FIELDS ;
					Platform, UniqueID, TimeStamp, ObjType, ObjCode, Comment, Name, Float, Stretch, ;
					StretchTop, SuprPCol, SupAlways, SupOvflow, SupGroup, SupValChng, SupExpr, ;
					SupType, SupRest, Expr, VPos, Hpos, Height, Width, Style, Picture, PenRed, ;
					PenGreen, PenBlue, FillRed, FillGreen, FillBlue, FontFace, FontStyle, ;
					FontSize, Mode, Top, Bottom, ResetRpt, Spacing, TopMargin, TotalType, ;
					ResetTotal, NoRepeat, Offset, FillChar, General

			CASE m.cType = "LABEL"
				SCATTER NAME (m.cObject) MEMO FIELDS ;
					Platform, UniqueID, TimeStamp, ObjType, ObjCode, Comment, Name, Float, Stretch, ;
					StretchTop, SuprPCol, SupAlways, SupOvflow, SupGroup, SupValChng, SupExpr, ;
					SupType, SupRest, Expr, VPos, Hpos, Height, Width, Style, Picture, PenRed, ;
					PenGreen, PenBlue, FontFace, FontStyle, FontSize, Mode, NoRepeat, Offset, Top, Bottom

			CASE m.cType = "LINE"
				SCATTER NAME (m.cObject) MEMO FIELDS ;
					Platform, UniqueID, TimeStamp, ObjType, ObjCode, Comment, Name, Float, Stretch, ;
					StretchTop, SuprPCol, SupAlways, SupOvflow, SupGroup, SupValChng, SupExpr, SupType, ;
					SupRest, VPos, HPos, Height, Width, PenRed, PenGreen, PenBlue, FillRed, ;
					FillGreen, FillBlue, PenSize, PenPat, FillPat, FontSize, Offset

			CASE m.cType = "BAND"
				SCATTER NAME (m.cObject) MEMO FIELDS ;
					Platform, UniqueID, TimeStamp, ObjType, ObjCode, Comment, Name, Float, Stretch, ;
					StretchTop, SuprPCol, SupAlways, SupOvflow, SupGroup, SupValChng, SupExpr, SupType, ;
					SupRest, Expr, Height, Width, PageBreak, ColBreak, ResetPage, Plain

			CASE m.cType = "HEADER"
				SCATTER NAME (m.cObject) MEMO FIELDS ;
					Platform, UniqueID, TimeStamp, ObjType, ObjCode, Comment, Name, Float, Stretch, ;
					StretchTop, SuprPCol, SupAlways, SupOvflow, SupGroup, SupValChng, SupExpr, SupType, ;
					SupRest, VPos, HPos, Height, Width, Tag, Tag2, FontFace, FontStyle, FontSize, ;
					Environ, PenRed, PenGreen, Ruler, RulerLines, Grid, GridV, GridH, Top, Bottom, ;
					NoRepeat, AddAlias, CurPos, Expr, Unique

			CASE m.cType = "ENVIRONMENT"
				SCATTER NAME (m.cObject) MEMO FIELDS ;
					Platform, ObjType, ObjCode, Comment, Name, Expr, Environ, Tag
			ENDCASE

			IF VERSION(3) = "82" AND TYPE("&cObject..FontFace") # 'U' AND &cObject..FontFace = "Arial"
				&cObject..FontFace = "Courier New"
			ENDIF

			SELECT (m.nSelect)
			THIS.GotoRec(m.nRecNo)

		ENDIF
	ENDPROC


	*>> AddStyleRec: Add style record to style object list -- keeps track of where in
	*           the style table we can find the original style properties for a
	*           style object.
	FUNCTION AddStyleRec()
		LPARAMETER cObject, cType
		LOCAL m.nNextPos

		m.cObject = UPPER(m.cObject)
		m.cType = UPPER(m.cType)

		m.nNextPos = ASCAN(THIS.aStyleRec, m.cObject)
		IF m.nNextPos = 0
			m.nNextPos = ALEN(THIS.aStyleRec, 1)
			IF !EMPTY(THIS.aStyleRec[m.nNextPos, 1])
				m.nNextPos = m.nNextPos + 1
				DIMENSION THIS.aStyleRec[m.nNextPos, 3]
			ENDIF
		ELSE
			m.nNextPos = ASUBSCRIPT(THIS.aStyleRec, m.nNextPos, 1)
		ENDIF


		THIS.aStyleRec[m.nNextPos, 1] = m.cObject
		THIS.aStyleRec[m.nNextPos, 2] = m.cType
		THIS.aStyleRec[m.nNextPos, 3] = RECNO()

		THIS.ReadStyleRec(m.cObject)


	ENDFUNC


	*>> GetFldWidth: Returns width of a field in term of foxels
	FUNCTION GetFldWidth(cDataType, nLength, nDec, cFontStyle, cFontFace, nFontSize)
		LOCAL nWidth
		LOCAL cFormatStr

		IF TYPE("cFontStyle") = "N"
			m.cFontStyle = THIS.GetStyleCode(m.cFontStyle)
		ENDIF
		
		IF SET("REPORTBEHAVIOR") >= 90
			DO CASE
			CASE INLIST(m.cDataType, DT_NUM, DT_FLOAT, DT_DOUBLE)
				m.cFormatStr = REPLICATE('9', m.nLength) + IIF(m.nDec > 0, '.' + REPLICATE('9', m.nDec), '')

			CASE m.cDataType = DT_INT
				m.cFormatStr = REPLICATE('9', m.nLength)

			CASE m.cDataType = DT_DATE
				m.cFormatStr = DTOC(DATE())

			CASE m.cDataType = DT_TIME
				m.cFormatStr = TTOC(DATETIME())

			CASE m.cDataType = DT_MONEY
				m.cFormatStr = "999,999,999.99"

			OTHERWISE
				m.cFormatStr = REPLICATE(THIS.GetAvgChar(m.cDataType, m.nLength), m.nLength)
			ENDCASE
			m.cFormatStr = m.cFormatStr + '9' && add a fudge factor
			m.nWidth = THIS.GetFruTextWidth(m.cFormatStr, m.cFontFace, m.nFontSize, m.cFontStyle)

		ELSE		
			DO CASE
			CASE INLIST(m.cDataType, DT_NUM, DT_FLOAT, DT_DOUBLE)
				m.nWidth=(m.nLength + IIF(m.nDec = 0, ;
					INT((m.nLength - 1) / 3), ;
					INT((m.nLength - m.nDec - 2) / 3))) * ;
					TXTWIDTH(THIS.GetAvgChar(m.cDataType, m.nLength), ;
					m.cFontFace, m.nFontSize, m.cFontStyle) * ;
					IIF(_mac, RPT_PTPERPIX_MAC, RPT_PTPERPIX) * FONT(6, m.cFontFace, m.nFontSize, m.cFontStyle)

			CASE m.cDataType = DT_INT
				m.nWidth=TXTWIDTH('9999999999', m.cFontFace, m.nFontSize, m.cFontStyle) * ;
					IIF(_mac, RPT_PTPERPIX_MAC, RPT_PTPERPIX) * FONT(6, m.cFontFace, m.nFontSize, m.cFontStyle)

			CASE m.cDataType = DT_DATE
				m.nWidth=TXTWIDTH('99/99/99', m.cFontFace, m.nFontSize, m.cFontStyle) * ;
					IIF(_mac, RPT_PTPERPIX_MAC, RPT_PTPERPIX) * FONT(6, m.cFontFace, m.nFontSize, m.cFontStyle)

			CASE m.cDataType = DT_TIME
				m.nWidth=TXTWIDTH(TTOC(DATETIME()), m.cFontFace, m.nFontSize, m.cFontStyle) * ;
					IIF(_mac, RPT_PTPERPIX_MAC, RPT_PTPERPIX) * FONT(6, m.cFontFace, m.nFontSize, m.cFontStyle)

			CASE m.cDataType = DT_MONEY
				m.nWidth=TXTWIDTH('999,999,999.99', m.cFontFace, m.nFontSize, m.cFontStyle) * ;
					IIF(_mac, RPT_PTPERPIX_MAC, RPT_PTPERPIX) * FONT(6, m.cFontFace, m.nFontSize, m.cFontStyle)

			OTHERWISE
				m.nWidth=m.nLength * TXTWIDTH(THIS.GetAvgChar(m.cDataType, m.nLength), ;
					m.cFontFace, m.nFontSize, m.cFontStyle) * IIF(_mac, RPT_PTPERPIX_MAC, RPT_PTPERPIX) * ;
					FONT(6, m.cFontFace, m.nFontSize, m.cFontStyle)
			ENDCASE
		ENDIF
		RETURN m.nWidth + RPT_KLUDGE

	ENDFUNC

	*>> GetTxtWidth: Returns width of text label in terms of foxels
	FUNCTION GetTxtWidth(cStr, cFontStyle, cFontFace, nFontSize)
		LOCAL nWidth

		* Remove leading & trailing quotes from expression
		IF LEN(m.cStr) > 2 .AND. LEFT(m.cStr, 1) = ["] .AND. RIGHT(m.cStr, 1) = ["]
			m.cStr = SUBSTR(LEFT(m.cStr, LEN(m.cStr)-1), 2)
		ENDIF

		IF TYPE("cFontStyle") = DT_NUM
			m.cFontStyle = THIS.GetStyleCode(m.cFontStyle)
		ENDIF

		IF SET("REPORTBEHAVIOR") >= 90
			m.nWidth = THIS.GetFruTextWidth(m.cStr, m.cFontFace, m.nFontSize, m.cFontStyle)
		ELSE
			m.nWidth=TXTW(m.cStr, m.cFontFace, m.nFontSize, m.cFontStyle) * ;
				FONT(6, m.cFontFace, m.nFontSize, m.cFontStyle) * IIF(_mac, RPT_PTPERPIX_MAC, RPT_PTPERPIX)
		ENDIF
		
		RETURN ROUND(m.nWidth, 3)
	ENDFUNC

	*=======================================================
	* GetFruTextWidth( cText, cTypeface, iSize [, cStyle ] )
	*
	* Returns the width of a given string in FRUs
	*=======================================================
	FUNCTION GetFruTextWidth(cText, cTypeFace, iSize, cStyle)
		if parameters() < 4
			cStyle = "N"
		endif
			
		*-------------------------------------------------------
		* obtain text width in pixels. Remember that txtwidth() returns
		* number of equivalent average characters, so must multiply by
		* the overall average character width:
		*-------------------------------------------------------
		local iWidth

		iWidth = txtwidth( cText,  cTypeFace, iSize, cStyle ) 
		iWidth = m.iWidth * fontmetric(6, cTypeFace, iSize, cStyle ) 

		*-------------------------------------------------------
		* convert pixels to FRU:
		*-------------------------------------------------------
		return this.pixelsToFru( m.iWidth )
	ENDFUNC


	*=======================================================
	* PixelsToFru( int )
	*
	* return a value in FRUs of a given pixel dimension
	*=======================================================
	FUNCTION PixelsToFru(nPix)
		return round(( nPix * 10000 )/SCREEN_DPI, 3 )
	ENDFUNC

	*>> GetAvgChar: Returns average size of a character to use in TXTWIDTH()
	* Routine takes the width of a database field
	* and returns a character which can be used
	* as the average size in a TXTWIDTH expression
	* to determine the width of am @..GET field.
	FUNCTION GetAvgChar(cDataType, nLength)
		LOCAL cAvgChar

		DO CASE
		CASE INLIST(m.cDataType, DT_NUM, DT_FLOAT, DT_DOUBLE, DT_MONEY, DT_INT)  &&number
			m.cAvgChar = '0'

		CASE m.nLength < 6   &&largest
			m.cAvgChar = 'W'

		CASE m.nLength < 13  &&below largest
			m.cAvgChar = 'Q'

		OTHERWISE
			m.cAvgChar = 'B'         &&average size
		ENDCASE
		RETURN m.cAvgChar
	ENDFUNC


	*>> GetStyleCode: Convert numeric font style to character font style
	* Abstract:
	*  Takes font style in FRX file and converts to font style code
	*  used by FONTMETRIC functions.
	FUNCTION GetStyleCode
		LPARAMETER nFntStyle
		LOCAL cStyle

		DO CASE
		CASE m.nFntStyle= 1  && BOLD
			m.cStyle = 'B'
		CASE m.nFntStyle= 2  && ITALIC
			m.cStyle = 'I'
		CASE m.nFntStyle= 3  && BOLD ITALIC
			m.cStyle = 'BI'
		CASE m.nFntStyle= 4  && UNDERLINE
			m.cStyle = 'U'
		CASE m.nFntStyle= 5  && UNDERLINE BOLD
			m.cStyle = 'BU'
		CASE m.nFntStyle= 6  && UNDERLINE ITALIC
			m.cStyle = 'UI'
		CASE m.nFntStyle= 7  && UNDERLINE ITALIC BOLD
			m.cStyle = 'UBI'
		OTHERWISE            && NORMAL
			m.cStyle = 'N'
		ENDCASE

		RETURN m.cStyle
	ENDFUNC


	*>> CreateIndex: called by AddCdxTag to open the file exclusive & create the index
	PROTECTED FUNCTION CreateIndex
		LPARAMETERS sTagExpr, sTagName, wzstagdesc

		LOCAL wzIsExcl, nBuffering, wzHadErr

		* Create new index tag here
		m.wzHadErr = .F.
		m.wzIsExcl = .T.

		m.nbuffering = CURSORGETPROP('buffering')

		* check if file is opened exclusively, else try to open it that way
		IF !ISFLOCKED()
			m.wzisexcl=.F.
			*- Set up for error handling
			THIS.SetErrorOff = .T.
			USE (m.sDBF) AGAIN ALIAS (m.sCurAlias) EXCLUSIVE
			IF EMPTY(ALIAS()) && file in use error -- could not open exclusive
				m.wzHadErr = .T.
			ENDIF && EMPTY(ALIAS())   && file in use error -- could not open exclusive
			THIS.SetErrorOff = .F.
		ENDIF && !ISFLOCKED()

		IF !m.wzHadErr
			IF m.nbuffering > 3   &&tablebuffering
				=TABLEUPDATE(.T., .T.)
				=CURSORSETPROP('buffering', DB_BUFOFF)
			ENDIF && m.nbuffering > 3   &&tablebuffering
			INDEX ON &sTagExpr TAG &sTagName &wzstagdesc

			IF m.nbuffering > 3   &&tablebuffering
				=CURSORSETPROP('buffering', m.nbuffering)
			ENDIF && m.nbuffering > 3  &&tablebuffering
		ENDIF

		DO CASE
		CASE m.wzHadErr   && an error occured so reset original
			USE (m.sDBF) AGAIN ALIAS (m.sCurAlias) SHARED
		CASE !m.wzIsExcl  &&need to restore to original
			USE (m.sDBF) AGAIN ALIAS (m.sCurAlias) SHARED ORDER &sTagName
		OTHERWISE
			*already indexed -- do nothing
		ENDCASE

		RETURN !m.wzHadErr

	ENDFUNC && CreateIndex


	*>> GetFullTagExpr
	* Abstract:
	*   Overrides method of same name defined in WzEngine.
	*   Necessary to handle group tags, which may not be
	*   regular field expressions
	*
	PROCEDURE GetFullTagExpr
		* Get tag expression looping through fields and type casting
		* for different data types on fields.
		* This method assumes that DBF is already selected!!!

		LPARAMETER aSortArray
		LOCAL aFldData,i,ipos,sFldExpr,sTagExpr
		IF EMPTY(aSortArray[1])
			RETURN ""
		ENDIF
		DIMENSION aFldData[1]
		=AFIELDS(aFldData)
		sTagExpr = ""
		FOR i = 1 TO ALEN(aSortArray)

			IF EMPTY(aSortArray[m.i])
				LOOP
			ENDIF

			FOR iPos = 1 TO ALEN(aFldData,1)
				IF UPPER(aFldData[m.iPos,1])==UPPER(aSortArray[m.i])
					EXIT
				ENDIF
			ENDFOR

			*- if field not found, index as-is
			IF m.iPos > ALEN(aFldData, 1)
				sFldExpr = aSortArray[m.i]
			ELSE
				sFldExpr = THIS.GetTagExpr(aSortArray[m.i],aFldData[m.iPos,2],aFldData[m.iPos,3],aFldData[m.iPos,4],(ALEN(aSortArray)=1))
			ENDIF

			IF !EMPTY(m.sFldExpr)
				sTagExpr = m.sTagExpr + IIF(EMPTY(m.sTagExpr),"","+") + m.sFldExpr
			ENDIF
		ENDFOR
		RETURN sTagExpr
	ENDPROC



	*>> AddCdxTag
	* Abstract:
	*   Overrides method of same name defined in WzEngine.
	*   Necessary to handle group tags, which may not be
	*   regular field expressions
	*
	PROCEDURE AddCdxTag
		* Takes contents from THIS.aWizSorts array and creates an index TAG
		* from the fields passed in array. If an expression already exists
		* no tag is made and the tag name is returned.
		* Assume database is already selected since a new index TAG is created.
		* Parameters:
		*  aSrtArray - reference of sort fields array (e.g., aSortFields)
		*  aFieldsRef - reference of instance array (e.g., aWizFList, aGridFList)

		PARAMETER aSortRef,aFieldsRef

		IF PARAMETER() # 2
			THIS.ALERT(C_BADPARMS_LOC)
			RETURN ""
		ENDIF && PARAMETER() # 2

		PRIVATE aSorts
		DIMENSION aSorts[1,1]
		STORE "" TO aSorts
		=ACOPY(THIS.&aSortRef.,aSorts)

		LOCAL lWizardName, iAryLen
		PRIVATE sTagName,sFldExpr,sTagExpr,lHasmemo,sCurAlias,cSortFld
		PRIVATE sCdxName,i,sDBF,wzaCDX,aFileInfo,nTmpCnt,cTmpName,nbuffering
		STORE '' TO sFldExpr,sTagExpr,sTagName,cTmpName,iPos
		STORE 1 TO nTmpCnt

		m.nBuffering = 0

		* Nothing to sort
		IF EMPTY(aSorts[1,1])
			RETURN ''
		ENDIF && EMPTY(aSorts[1,1])

		m.lWizardName = .F.

		* Check if cursor in use
		IF AT('.TMP',DBF()) # 0
			RETURN ''
		ENDIF && AT('.TMP',DBF()) # 0

		* Also check if read-only
		=ADIR(aFileInfo,DBF())
		IF AT('R',aFileInfo[5])#0
			RETURN ''
		ENDIF && AT('R',aFileInfo[5])#0
		RELEASE aFileInfo

		m.sCurAlias=ALIAS()                    &&alias name
		m.sDBF = DBF()                      &&DBF stem
		m.sCdxName = THIS.FORCEEXT(m.sDBF,'CDX')  &&CDX name

		* make sure we have variable defined
		IF TYPE('THIS.lSortAscend')#'L'
			THIS.lSortAscend = .T.
		ENDIF && TYPE('THIS.lSortAscend')#'L'

		* Get index expression here
		= ACOPY(aSorts,wzaCdx)
		STORE .F. TO wzaCdx

		* Get tag expression looping through fields and type casting
		* for different data types on fields.
		FOR i = 1 TO ALEN(aSorts)

			*- workaround for VFP code problem (jd 11/14/95)
			iAryLen = ALEN(THIS.&aFieldsRef.,1)

			FOR iPos = 1 TO m.iAryLen
				IF UPPER(THIS.&aFieldsRef.[m.iPos,1])==UPPER(aSorts[m.i])
					EXIT
				ENDIF && UPPER(THIS.&aFieldsRef.[m.iPos,1])==UPPER(aSorts[m.i])
			ENDFOR && iPos = 1 TO ALEN(THIS.&aFieldsRef.,1)

			*- if field not found, index as-is
			IF m.iPos > ALEN(THIS.&aFieldsRef., 1)
				m.sTagExpr = m.sTagExpr + IIF(EMPTY(m.sTagExpr),"","+") + aSorts[m.i]
				m.lWizardName = .T.
			ELSE
				m.cSortFld = THIS.&aFieldsRef.[m.iPos,1]

				* check if alias used
				IF AT('.',m.cSortFld) # 0
					m.cSortFld = SUBSTR(m.cSortFld,AT('.',m.cSortFld)+1)
				ENDIF && AT('.',m.cSortFld) # 0

				m.sFldExpr = THIS.GetTagExpr(m.cSortFld,THIS.&aFieldsRef.[m.iPos,2],THIS.&aFieldsRef.[m.iPos,3],THIS.&aFieldsRef.[m.iPos,4],(ALEN(aSorts)=1))

				IF !EMPTY(m.sFldExpr)
					m.sTagExpr = m.sTagExpr + IIF(EMPTY(m.sTagExpr),"","+") + m.sFldExpr
				ENDIF && !EMPTY(m.sFldExpr)
			ENDIF && m.iPos > ALEN(THIS.&aFieldsRef., 1)
		ENDFOR && i = 1 TO ALEN(aSorts)

		* Get CDX Tag name - use WIZARD_1, WIZARD_2, etc. if expression
		IF ALEN(aSorts) = 1 AND !m.lWizardName
			m.sTagName = LEFT(aSorts[1],10)
		ELSE
			m.sTagName = "WIZARD_1"
		ENDIF && ALEN(aSorts) = 1 AND !m.lWizardName

		* Check for unique Tag name
		DO WHILE TAGNO(m.sTagName)#0
			nTmpCnt = nTmpCnt + 1
			m.sTagName = "WIZARD_"+ALLTRIM(STR(nTmpCnt))
		ENDDO && TAGNO(m.sTagName)#0


		m.wzHadErr = .F.
		m.wzstagdesc=IIF(THIS.lSortAscend,'',' DESC')

		* create tag since we now have dbf exclusive
		* Check if a tag already exists with same expression
		IF FILE(m.sCdxName)
			FOR m.i = 1 TO 256      &&max # tags
				IF EMPTY(TAG(m.sCdxName,m.i))
					m.wzhaderr = !THIS.CreateIndex(sTagExpr, sTagName, wzstagdesc)

					EXIT
				ENDIF && EMPTY(TAG(m.sCdxName,m.i))
				* found tag with same expr (checks 4 asce/desc)
				* use NORMALIZE function to ensure that functions not abbrev
				IF UPPER(NORM(KEY(m.sCdxName,m.i)))=UPPER(NORM(m.sTagExpr))
					wzsTmpTag=TAG(m.sCdxName,m.i)
					SET ORDER TO &wzsTmpTag
					IF (!THIS.lSortAscend AND 'DESCENDING'$SET('ORDER')) OR ;
							(THIS.lSortAscend AND !'DESCENDING'$SET('ORDER'))
						sTagName=TAG(m.sCdxName,m.i)
						EXIT
					ENDIF && (!THIS.lSortAscend AND 'DESCENDING'$SET('ORDER')) OR
				ENDIF && UPPER(NORM(KEY(m.sCdxName,m.i)))=UPPER(NORM(m.sTagExpr))
			ENDFOR && m.i = 1 TO 256     && max # tags
		ELSE
			m.wzhaderr = !THIS.CreateIndex(sTagExpr, sTagName, wzstagdesc)
		ENDIF && FILE(m.sCdxName)

		* We probably couldn't get the table open exclusive, so unable to
		* index -- therefore, generate an error
		IF m.wzHadErr
			ERROR ERR_EXCLUSIVE_LOC
		ENDIF

		LOCATE   &&goto top
		RETURN m.sTagName

	ENDPROC && AddCdxTag



	*>> InsOtherInfo: Insert font, variable, & dataenvironment objects at very end of report
	PROTECTED PROCEDURE InsOtherInfo
		LOCAL nSelect, aTemp
		m.nSelect = SELECT()
		SELECT StyleFile

		DIMENSION aTemp[1]
		SCAN FOR INLIST(ObjType, OT_FONT, OT_VAR) AND platform = THIS.cPlatform
			SCATTER TO aTemp MEMO
			*- change platform to current platform
			aTemp[1] = THIS.cPlatform
			INSERT INTO NewRpt FROM ARRAY aTemp
		ENDSCAN


		SELECT (m.nSelect)
	ENDPROC && InsOtherInfo


ENDDEFINE


*--------------------------------------------------------------------
*>> Class Definition: ReportEngine
*--------------------------------------------------------------------
DEFINE CLASS ReportEngine AS MainEngine
	PROTECTED nPageWidth, nPrintWidth , nColWidth
	PROTECTED nDetailRows
	PROTECTED nFldOffset, nLblOffset, nColOffset, nDetailOffset, nGrpHdrOffset
	PROTECTED nGrpFOffset, nGrpHOffset, nGrpCnt
	PROTECTED nTotalCnt, nCountCnt, nAvgCnt, nMaxCnt, nMinCnt

	nTotalCnt = 0
	nCountCnt = 0
	nAvgCnt = 0
	nMaxCnt = 0
	nMinCnt = 0

	DIMENSION aWizTotals[1,6]  && List of fields to total on [name, width]
	aWizTotals = ""

	DIMENSION aWizPctTotals[1,6]  && Pct of totals
	aWizPctTotals = ""

	DIMENSION aWizCount[1,6]  && List of fields to count [name, width]
	aWizCount = ""

	DIMENSION aWizAvg[1,6]  && List of fields to average [name, width]
	aWizAvg = ""

	DIMENSION aWizMin[1,6]  && List of fields to determine min [name, width]
	aWizMin = ""

	DIMENSION aWizMax[1,6]  && List of fields to determine max [name, width]
	aWizMax = ""

	DIMENSION aWizGroups[3,4]  && Groups -- up to 3
	aWizGroups = ""

	DIMENSION aWizGrpExpr[3, 4]    && Group expressions ie [C1, LEFT(TEAM, 1), etc]
	aWizGrpExpr = ""


	* We'll probably get this from the current printer definition
	DIMENSION aPaperSizes[1, 3]    && Paper sizes ("Letter", "Legal", etc)
	aPaperSizes = ""


	nLayout      = RPT_LAYVERT	&& tabular (horiz) or columnar (vert)
	lGroupRpt    = .F.       	&& Group report
	lSubTotals   = .F.       	&& Include subtotals in group report
	lGrandTotals = .F.      	&& Include grand totals in group report
	lOneToMany   = .F.       	&& One to Many report

	cStyleFile  = "STYLES\STYLE1V.FRX"      && report file containing our style template
	cPaperSize  = PAPER_LTR_LOC
	lLandscape  = .F.         && Set to .T. to print in Landscape


	nPageWidth  = 0      && actual page width -- ie 80000 for portrait, 11000 for landscape
	nPrintWidth = 0      && Print width of a page, after taking into account the margins
	nColWidth   = 0      && Print width of a column (including for single-column reports)

	nDetailRows = 1      && number of detail rows to accomodate lots of fields

	* The following values are added to objects to scootch them down below
	* to the correct position when:
	*   1) using multiple columns
	*   2) we exceed the page width & must wrap labels and fields
	*   3) general fields force us to increase the height of our detail band
	*
	nColOffset  = 0      && Vertical size of the column header band
	nFldOffset  = 0      && Vertical size of the detail band when rows > 1
	nLblOffset  = 0      && Vertical size of the page header band when rows > 1
	nGrpHOffset = 0      && Vertical size of the group header bands
	nGrpFOffset = 0      && Vertical size of the group footer bands
	nDetailOffset = 0    && Length that detail band increases by adding
&& general fields, additional field rows, etc
	n1MOffset   = 0      && Length that group header band increases in One-to-Many report
	nGrpCnt     = 0      && number of groups (0 for a non-group report)


	*-------------------------------------------------------
	* All of the properties below deal with the style file:

	PROTECTED nTitleBandHt, nPageHdrBandHt, nPageFtrBandHt
	PROTECTED nGrpHdrBandHt, nGrpFtrBandHt, nColHdrBandHt, nColFtrBandHt
	PROTECTED nSummaryBandHt, nDetailBandHt

	PROTECTED nGrpHdrRealHt, nGrpFtrRealHt


	PROTECTED oBand
	PROTECTED oRptHeader, oRptField, oRptLabel, oRptDataEnv
	PROTECTED oRptMemo, oRptGeneral, oRptField2, oRptGrpField
	PROTECTED oParentLabel, oParentField, oParentField2

	nTitleBandHt   = 0
	nPageHdrBandHt = 0
	nPageFtrBandHt = 0
	nGrpHdrBandHt  = 0
	nGrpFtrBandHt  = 0
	nColHdrBandHt  = 0
	nColFtrBandHt  = 0
	nSummaryBandHt = 0
	nDetailBandHt  = 0

	nGrpHdrRealHt  = 0
	nGrpFtrRealHt  = 0

	oBand          = .NULL.
	oRptField      = .NULL. && sample field
	oRptMemo       = .NULL. && sample memo field
	oRptGeneral    = .NULL. && sample general field
	oRptField2     = .NULL. && secondary sample field
	oRptLabel      = .NULL. && sample label
	oRptGrpField   = .NULL.   && sample group field
	oParentLabel   = .NULL.   && sample parent label
	oParentField   = .NULL.   && sample parent field
	oParentField2  = .NULL.  && second sample parent field (for field spacing)

	oRptHeader  = .NULL.
	oDetailBand = .NULL.
	oRptDataEnv = .NULL.

	oRptVDivider = .NULL. && we won't know what type this is until
&& we find the record in the style file
	oRptHDivider = .NULL.

	nFldHPos    = 0      && Starting field horizontal position
	nFldVPos    = 0      && Starting field vertical position
	nLblHPos    = 0      && Starting label horizontal position
	nLblVPos    = 0      && Starting label vertical position
	nGrpHdrHt   = 0      && height of group & column headers in style file
	nGrpFtrHt   = 0      && height of group & column footers in style file
	n1MFldHPos  = 0      && Starting parent field horizontal position
	n1MFldVPos  = 0      && Starting parent field vertical position
	n1MLblVPos  = 0      && Starting parent label vertical position
	n1MLblHPos  = 0      && Starting parent label vertical position

	nVertSpacing  = 0    && space between fields in vertical report
	nHorzSpacing  = 0    && space between fields in horizontal report
	nLblSpacing   = 0    && space between labels & fields (vert reports only)

	nIndent     = 1500   && amount to indent when we go to multiple rows

	nSubtotWidth = 0
	
	*-------------------------------------------------------





	*>> Init: Initialization
	PROCEDURE Init2
		MainEngine::Init2()

		DIMENSION THIS.aPaperSizes[4, 3]
		THIS.aPaperSizes[1, 1] = PAPER_LTR_LOC
		THIS.aPaperSizes[1, 2] = 85000.00			&& Portrait
		THIS.aPaperSizes[1, 3] = 110000.00			&& Landscape

		THIS.aPaperSizes[2, 1] = PAPER_LGL_LOC
		THIS.aPaperSizes[2, 2] = 85000.00			&& Portrait
		THIS.aPaperSizes[2, 3] = 140000.50			&& Landscape


		THIS.aPaperSizes[3, 1] = PAPER_LGR_LOC		&& ledger
		THIS.aPaperSizes[3, 2] = 85000.00			&& Portrait
		THIS.aPaperSizes[3, 3] = 161250.00			&& Landscape

		THIS.aPaperSizes[4, 1] = PAPER_A4_LOC
		THIS.aPaperSizes[4, 2] = 77604.17			&& Portrait
		THIS.aPaperSizes[4, 3] = 112812.50			&& Landscape

	ENDPROC



	*>> SetLabels: set friendly labels
	* Abstract:
	*  Use captions from the DBC for label names if we're operating on a table
	*  which resides in a DBC.  Otherwise, clean up the labels:
	*          - replace "_" with space
	*          - proper case
	*
	*  ie SetLabels("aWizFields", "aWizLabels", THIS.cDBCAlias, THIS.cDBCTable, THIS.oRptLabel.Expr)
	PROCEDURE SetLabels
		LPARAMETERS aFldsRef, aLabelsRef, cDBCAlias, cDBCTable, cLblTemplate, cLblDefine
		LOCAL i, cLabel, cExpr, cField, lInDBC, cSaveDBC
		=ACOPY(THIS.&aFldsRef.,aFlds)
		=ACOPY(THIS.&aLabelsRef.,aLabels)

		IF TYPE("m.cLblDefine") <> "C"
			m.cLblDefine = C_LBL
		ENDIF

		DIMENSION aLabels[ALEN(aFlds, 1), 1]
		aLabels = ""
		m.cExpr = UPPER(m.cLblTemplate)

		IF LEN(m.cExpr) > 1 .AND. LEFT(m.cExpr, 1) = ["]
			m.cExpr = SUBSTR(m.cExpr, 2, LEN(m.cExpr) - 2)
		ENDIF


		m.lInDBC = !EMPTY(m.cDBCAlias)
		IF m.lInDBC
			m.cSaveDBC = DBC()
			SET DATABASE TO (m.cDBCAlias)
		ENDIF
		FOR m.i = 1 TO ALEN(aFlds, 1)
			m.cField = aFlds[m.i, 1]

			IF EMPTY(m.cField)
				LOOP
			ENDIF

			* Localizer: May want to remove the reference to Proper() function.
			IF m.lInDBC
				m.cLabel = DBGetProp(m.cDBCTable + "." + m.cField, "FIELD", "CAPTION")
			ELSE
				m.cLabel = ""
			ENDIF
			IF EMPTY(m.cLabel)
				m.cLabel = PROPER(STRTRAN(m.cField, "_", " "))
			ENDIF
			m.cLabel = STRTRAN(m.cExpr, m.cLblDefine, m.cLabel)

			aLabels[m.i, 1] = m.cLabel
		ENDFOR
		IF !EMPTY(m.cSaveDBC)
			SET DATABASE TO (m.cSaveDBC)
		ENDIF

		DIMENSION THIS.&aLabelsRef.[ALEN(aLabels, 1), 1]
		=ACOPY(aLabels, THIS.&aLabelsRef.)
	ENDPROC




	*>> InsPageInfo: Insert title & page bands info
	* Abstract:
	*   Scan the style file, and insert title & page header
	*   info found there into the new report.  It will only
	*   look at objects (labels, lines, etc) whose vertical
	*   position falls between the specified range.
	* Parameters:
	*   nVertStart = starting vertical position
	*   nVertEnd   = ending vertical position
	*   nOffset   = vertical offset for objects inserted into new report
	*   nMaxWidth  = if horizontal stretch is specified for an object,
	*           then this specifies the width to stretch it to
	*   nVStretch  = vertical stretch offset for boxes
	*
	PROTECTED PROCEDURE InsPageInfo
		LPARAMETERS nVertStart, nVertEnd, nOffset, nMaxWidth, nVStretch

		LOCAL oRecord

		IF TYPE("m.nMaxWidth") <> "N"
			m.nMaxWidth = THIS.nPrintWidth
		ENDIF
		IF TYPE("m.nVStretch") <> "N"
			m.nVStretch = 0
		ENDIF

		SELECT StyleFile

		m.nVertStart = m.nVertStart - RPT_CUSHION
		m.nVertEnd = m.nVertEnd - RPT_CUSHION
		SCAN FOR INLIST(ObjType, OT_LABEL, OT_LINE, OT_BOX, OT_GET) .AND. ;
				VPos >= m.nVertStart .AND. VPos < m.nVertEnd .AND. ;
				!UPPER(Name)$SKIP_NAME .AND. !UPPER(Expr)$SKIP_EXPR .AND. ;
				!(C_HDIVIDER$UPPER(Comment)) .AND. !(C_VDIVIDER$UPPER(Comment)) .AND. ;
				!(C_LBL$UPPER(Expr)) .AND. !(C_1MLBL$UPPER(Expr)) AND TRIM(platform) = THIS.cPlatform


			SCATTER NAME oRecord MEMO
			oRecord.VPos = oRecord.VPos + m.nOffset

			DO CASE
				CASE C_PAGE$UPPER(Expr)
					oRecord.Expr = STRTRAN(Expr, C_PAGE, PAGEDESC_LOC)
			ENDCASE

			IF UPPER(EXPR) = C_TITLE
				IF ISNULL(THIS.cWizTitle) .OR. EMPTY(THIS.cWizTitle)
					LOOP
				ENDIF
				m.cComment = UPPER(Comment)
				DO CASE
				CASE C_UPPER$m.cComment
					m.cMyTitle = ALLTRIM(UPPER(THIS.cWizTitle))
				CASE C_LOWER$m.cComment
					m.cMyTitle = ALLTRIM(LOWER(THIS.cWizTitle))
				CASE C_PROPER$m.cComment
					m.cMyTitle = ALLTRIM(PROPER(THIS.cWizTitle))
				OTHERWISE
					m.cMyTitle = ALLTRIM(THIS.cWizTitle)
				ENDCASE
				oRecord.Expr = ["] + m.cMyTitle + ["]
				oRecord.Width = THIS.GetTxtWidth(oRecord.Expr, oRecord.FontStyle, ;
					oRecord.FontFace, oRecord.FontSize)
			ELSE
				* Horizontal stretch
				IF C_HSTRETCH$UPPER(Comment) .OR. ;
						oRecord.HPos + oRecord.Width > m.nMaxWidth
					oRecord.Width = m.nMaxWidth - oRecord.HPos
				ENDIF

				IF oRecord.ObjType = OT_BOX
					oRecord.Height = oRecord.Height + m.nVStretch
				ENDIF
			ENDIF

			THIS.OInsert(oRecord, "NewRpt")

		ENDSCAN

		RETURN
	ENDPROC


	*>> InsTitle: Insert title band info
	PROTECTED PROCEDURE InsTitle
		THIS.InsPageInfo(0, THIS.nTitleBandHt, 0, THIS.nPrintWidth)
	ENDPROC



	*>> InsPrePage: Insert page header (objects up to first label)
	* Abstract:
	*   Insert all page header info up to the first
	*   label. Labels can stretch, so we'll add the rest
	*   after we know the stretch offset.
	PROTECTED PROCEDURE InsPrePage
		LOCAL nOffset

		DO CASE
		CASE THIS.lOneToMany
			THIS.InsPageInfo(THIS.nTitleBandHt, ;
				THIS.nTitleBandHt + ;
				THIS.nPageHdrBandHt, ;
				THIS.nColOffset, THIS.nColWidth)
		CASE THIS.nLayout == RPT_LAYHORZ
			THIS.InsPageInfo(THIS.nTitleBandHt, THIS.nLblVPos, ;
				THIS.nColOffset, THIS.nColWidth)
		CASE THIS.nLayout == RPT_LAYVERT
			THIS.InsPageInfo(THIS.nTitleBandHt, ;
				THIS.nTitleBandHt + ;
				THIS.nPageHdrBandHt, ;
				THIS.nColOffset, THIS.nColWidth)
		ENDCASE
	ENDPROC

	*>> InsPostPage: Insert page header (objects after labels)
	* Abstract:
	*   Insert page header info which comes after the labels.
	*   We now know our label offset, so can insert properly.
	PROTECTED PROCEDURE InsPostPage
		LOCAL nBandStart, nBandEnd, nStretch

		IF THIS.nLayout = RPT_LAYVERT
			RETURN
		ENDIF


		m.nBandStart = THIS.nLblVPos
		m.nBandEnd = THIS.nTitleBandHt + ;
			THIS.nPageHdrBandHt && - WZ_BASEBAND/2

		m.nStretch = THIS.nDetailOffset

		THIS.InsPageInfo(m.nBandStart, m.nBandEnd, THIS.nColOffset + THIS.nLblOffset, ;
			THIS.nColWidth, m.nStretch)

	ENDPROC && InsPostPage


	*>> InsPreGroup: Insert lines & boxes that belong in the group header band
	PROTECTED PROCEDURE InsPreGroup
		LOCAL m.i

		* Insert lines/boxes found in the group header template
		FOR m.i = 1 TO THIS.nGrpCnt
			IF !EMPTY(THIS.aWizGroups[m.i, GRP_FIELD])

				IF THIS.lOneToMany
					THIS.InsPageInfo(THIS.nTitleBandHt + THIS.nPageHdrBandHt, ;
						THIS.oParentField2.VPos, ;
						(m.i - 1) * (THIS.nGrpHdrBandHt), THIS.nColWidth, 0)
				ELSE
					THIS.InsPageInfo(THIS.nTitleBandHt + THIS.nPageHdrBandHt, ;
						THIS.nTitleBandHt + THIS.nPageHdrBandHt + THIS.nColHdrBandHt + ;
						THIS.nGrpHdrBandHt, ;
						(m.i - 1) * (THIS.nGrpHdrBandHt), THIS.nColWidth, 0)
				ENDIF
			ENDIF
		ENDFOR

	ENDPROC && InsPreGroup



	*>> Insert lines/boxes in the group footer template
	PROTECTED PROCEDURE InsPostGroup
		LOCAL m.i
		FOR m.i = 1 TO THIS.nGrpCnt
			IF !EMPTY(THIS.aWizGroups[m.i, GRP_FIELD])
				THIS.InsPageInfo(THIS.nTitleBandHt + THIS.nPageHdrBandHt + THIS.nDetailBandHt + ;
					THIS.nGrpHdrHt, ;
					THIS.nTitleBandHt + THIS.nPageHdrBandHt + THIS.nGrpHdrHt + ;
					THIS.nDetailBandHt + THIS.nGrpFtrHt, ;
					(m.i - 1) * (THIS.nGrpFtrBandHt) + THIS.nLblOffset + ;
					THIS.nDetailOffset + THIS.nGrpHOffset + THIS.nColOffset - ;
					THIS.nGrpHdrHt, THIS.nColWidth, 0)
			ENDIF
		ENDFOR
	ENDPROC && InsPostGroup



	*>> InsTotals: Insert subtotals & grand totals
	* Abstract:
	*	Insert Subtotal and Grand Total information into report,
	*   and adjust the heights of the group footer bands to accomodate
	*   wrapping of fields.
	* Notes:
	*   THIS.aWizTotals:	1 = Expr
	*						2 = Band #
	*						3 = Picture
	*						4 = DataType
	*						5 = HPos
	*						6 = Width
	PROTECTED PROCEDURE InsTotals
		LOCAL m.i, m.nVPos, m.cSample, m.j, m.wzGrpField, m.nSummaryVPos
		LOCAL m.nLastBand, m.nOffset, m.nSelect, m.nRowsOffset
		LOCAL iSummRows,iNumTotRows
		
		IF THIS.nTotalCnt = 0 AND ;
				THIS.nCountCnt = 0 AND ;
				THIS.nAvgCnt = 0 AND ;
				THIS.nMaxCnt = 0 AND ;
				THIS.nMinCnt = 0
			RETURN
		ENDIF

		iNumTotRows = IIF(THIS.nTotalCnt > 0,1 + IIF(THIS.lPercentOfTotal,1,0),0) + ;
			IIF(THIS.nCountCnt > 0,1,0) + ;
			IIF(THIS.nAvgCnt > 0,1,0) + ;
			IIF(THIS.nMinCnt > 0,1,0) + ;
			IIF(THIS.nMaxCnt > 0,1,0)

		m.nSelect = SELECT()

		m.nOffset = 0
		THIS.oRptField.SupValChng = .F.    && do not suppress repeated values
		THIS.oRptField.SupAlways = .T.
		THIS.oRptField.Offset    = 1    	&& right justify

		m.iSummRows = 0
		m.nVPos = THIS.nFldVPos + THIS.nDetailOffset + THIS.nDetailBandHt + ;
			THIS.nGrpHOffset + THIS.nLblOffset + THIS.nColOffset
		nSummaryVPos = 0

		*- precalculate size of group footer
		IF THIS.lSubTotals
			IF THIS.nTotalCnt > 0
				THIS.CalcGrpFOffset("THIS.aWizTotals", THIS.nTotalCnt, @iSummRows)
				IF THIS.lPercentOfTotal
					THIS.CalcGrpFOffset("THIS.aWizPctTotals", THIS.nTotalCnt, @iSummRows)
				ENDIF
			ENDIF
			IF THIS.nCountCnt > 0
				THIS.CalcGrpFOffset("THIS.aWizCount", THIS.nCountCnt, @iSummRows)
			ENDIF
			IF THIS.nAvgCnt > 0
				THIS.CalcGrpFOffset("THIS.aWizAvg", THIS.nAvgCnt, @iSummRows)
			ENDIF
			IF THIS.nMinCnt > 0
				THIS.CalcGrpFOffset("THIS.aWizMin", THIS.nMinCnt, @iSummRows)
			ENDIF
			IF THIS.nMaxCnt > 0
				THIS.CalcGrpFOffset("THIS.aWizMax", THIS.nMaxCnt, @iSummRows)
			ENDIF
		ELSE
			IF THIS.nGrpCnt > 0
				SELECT NewRpt
				REPLACE ALL Height WITH HEIGHT + THIS.oRptField.Height + IIF(_mac, RPT_PTPERPIX_MAC, RPT_PTPERPIX) FOR ObjType == OT_BAND .AND. ;
					(ObjCode == OC_GRPFOOT .OR. ObjCode == OC_SUMMARY)
				THIS.nGrpFOffset = THIS.nGrpFOffset + THIS.oRptField.Height + IIF(_mac, RPT_PTPERPIX_MAC, RPT_PTPERPIX)
			ENDIF
		ENDIF
		
		m.iSummRows = 0
		*- insert summary of each type (count, sum, etc.)
		IF THIS.nTotalCnt > 0
			THIS.InsSummary("THIS.aWizTotals", THIS.nTotalCnt, I_TOTAL_SUM, @nVPos, @nSummaryVPos, @iSummRows, iNumTotRows)
			IF THIS.lPercentOfTotal
				THIS.InsSummary("THIS.aWizPctTotals", THIS.nTotalCnt, I_TOTAL_PCT, @nVPos, @nSummaryVPos, @iSummRows, iNumTotRows)
			ENDIF
		ENDIF
		IF THIS.nCountCnt > 0
			THIS.InsSummary("THIS.aWizCount", THIS.nCountCnt, I_TOTAL_COUNT, @nVPos, @nSummaryVPos, @iSummRows, iNumTotRows)
		ENDIF
		IF THIS.nAvgCnt > 0
			THIS.InsSummary("THIS.aWizAvg", THIS.nAvgCnt, I_TOTAL_AVG, @nVPos, @nSummaryVPos, @iSummRows, iNumTotRows)
		ENDIF
		IF THIS.nMinCnt > 0
			THIS.InsSummary("THIS.aWizMin", THIS.nMinCnt, I_TOTAL_MIN, @nVPos, @nSummaryVPos, @iSummRows, iNumTotRows)
		ENDIF
		IF THIS.nMaxCnt > 0
			THIS.InsSummary("THIS.aWizMax", THIS.nMaxCnt, I_TOTAL_MAX, @nVPos, @nSummaryVPos, @iSummRows, iNumTotRows)
		ENDIF
		
		SELECT (m.nSelect)

		RETURN

	ENDPROC && InsTotals

	
	*>> CalcGrpFOffset: Calculate the group footer offset
	* Abstract:
	*   we need to determine how big a group footer we will have
	*   before we start adding the footer and summary items
	*   cArrays = name of one of totals arrays
	*	iCount = count of items in array
	*	iSummRows = placeholder for # of times we have been here
	PROCEDURE CalcGrpFOffset
		PARAMETER cArray, iCount, iSummRows
		LOCAL nRowCnt, nLastband, nLastBand, i
		*- pre-calculate THIS.nGrpFOffset
		m.nRowCnt = 1
		m.nLastBand = &cArray[1, 2]
		FOR m.i = 2 TO iCount
			IF &cArray[m.i, 2] <> m.nLastBand
				m.nRowCnt = m.nRowCnt + 1
			ENDIF
			m.nLastBand = &cArray[m.i, 2]
		ENDFOR
		THIS.nGrpFOffset = THIS.nGrpFOffset + (m.nRowCnt * THIS.oRptField.Height * THIS.nGrpCnt)
		iSummRows = iSummRows + 1
	ENDPROC
	
	*>> InsSummary: Insert summary fields (count, sum, etc.)
	* Abstract:
	*   Insert Subtotal and Grand Total information into report,
	*   and adjust the heights of the group footer bands to accomodate
	*   wrapping of fields.
	* Notes: Uses aWizCount, aWizTotals, aWizAvg, aWizMin, aWizMax, passed as cArray
	*   cArray:	1 = Expr
	*			2 = Band #
	*			3 = Picture
	*			4 = DataType
	*			5 = HPos
	*			6 = Width
	*	iCount = count of items in array
	*	iTotalType = code for TotalType field
	*	iSummRows = placeholder for # of times we have been here
	PROCEDURE InsSummary
	
		PARAMETER cArray, iCount, iTotalType, nvPos, nSummaryVPos, iSummRows, iNumTotRows
		LOCAL nRowCnt, nLastband, nRowsOffset, nLastBand, nOffset, i, j
		LOCAL cSubTotal, cGrandTotal, cTotal, nOrigVPos, nOrigSummaryVPos

		* Calculate how many "rows" of totals we have
		m.nOffset = 0
		m.nRowCnt = 1	
		m.nLastBand = &cArray[1, 2]
		FOR m.i = 2 TO iCount
			IF &cArray[m.i, 2] <> m.nLastBand
				m.nRowCnt = m.nRowCnt + 1
			ENDIF
			m.nLastBand = &cArray[m.i, 2]
		ENDFOR
		m.nRowsOffset = (m.nRowCnt + 1) * THIS.oRptField.Height	&&  + iSummRows
		
		nOrigVPos = m.nVPos					&& this is where we will put the subtotal label
		
		* Insert the calculated subtotal fields in each of the group footers
		IF THIS.lSubTotals
			m.nLastBand = &cArray[1, 2]
			FOR m.i = 1 TO iCount
				*- Insert the actual calculated fields
				IF &cArray[m.i, 2] <> m.nLastBand
					m.nOffset = m.nOffset + THIS.oRptField.Height + IIF(_mac, RPT_PTPERPIX_MAC, RPT_PTPERPIX)
					m.nVPos = m.nVPos + m.nOffset
				ENDIF
				WITH THIS.oRptField
					.Expr		= &cArray[m.i, 1]
					.Picture	= &cArray[m.i, 3]
					.FillChar	= &cArray[m.i, 4]
					.HPos		= &cArray[m.i, 5]
					.Width		= &cArray[m.i, 6]
					.TotalType	= IIF(iTotalType = I_TOTAL_PCT, I_TOTAL_SUM, iTotalType)
					.VPos		= m.nVPos
				ENDWITH
				
				FOR m.j = 1 TO THIS.nGrpCnt
					THIS.oRptField.ResetTotal = 6 + THIS.nGrpCnt - m.j  && band code (6-8)
					THIS.OInsert(THIS.oRptField, "NewRpt")   && insert into group band
					THIS.oRptField.VPos = THIS.oRptField.VPos + THIS.nGrpFtrRealHt + m.nRowsOffset
				ENDFOR

				m.nLastBand = &cArray[m.i, 2]
				
			ENDFOR
		ENDIF		&& THIS.lSubTotals
		
		m.nOffset = m.nOffset + THIS.oRptField.Height + IIF(_mac, RPT_PTPERPIX_MAC, RPT_PTPERPIX)
		m.nSummaryVPos = m.nVPos + THIS.nGrpFOffset + THIS.nPageFtrBandHt
		m.nVPos = m.nVPos + THIS.oRptField.Height + IIF(_mac, RPT_PTPERPIX_MAC, RPT_PTPERPIX)
		
		*- Adjust the height of the group footer band to accommodate multiple rows of totals, and also wrapping
		*- totals
		SELECT NewRpt
		IF THIS.lSubTotals
			REPLACE ALL Height WITH HEIGHT + m.nOffset FOR ObjType == OT_BAND .AND. ;
				(ObjCode == OC_GRPFOOT)
		ENDIF
		
		IF THIS.lGrandTotals
			THIS.oRptField.ResetTotal =  1       && reset at end of report

			nOrigSummaryVPos = m.nSummaryVPos	&& this is where we will put the grand total label
			m.nLastBand = &cArray[1, 2]
			m.nOffset = 0
			FOR m.i = 1 TO iCount
				*- Insert the actual calculated fields
				IF &cArray[m.i, 2] <> m.nLastBand
					m.nOffset = m.nOffset + THIS.oRptField.Height + IIF(_mac, RPT_PTPERPIX_MAC, RPT_PTPERPIX)
					m.nSummaryVPos = m.nSummaryVPos + m.nOffset
				ENDIF
				THIS.oRptField.VPos = m.nSummaryVPos

				THIS.oRptField.Expr  = IIF(iTotalType = I_TOTAL_PCT,"100.00",&cArray[m.i, 1])
				THIS.oRptField.Picture  = &cArray[m.i, 3]
				THIS.oRptField.FillChar = &cArray[m.i, 4]
				THIS.oRptField.HPos  = &cArray[m.i, 5]
				THIS.oRptField.Width = &cArray[m.i, 6]
				THIS.oRptField.TotalType = IIF(iTotalType = I_TOTAL_PCT, 0, iTotalType)


				THIS.OInsert(THIS.oRptField, "NewRpt")   && insert into group band

				m.nLastBand = &cArray[m.i, 2]
			ENDFOR
			
			IF !THIS.lSubTotals
				*- remember the extra lines we may have inserted if the totals wrap
				nvPos = nvPos +  m.nOffset
			ENDIF
			
			REPLACE ALL Height WITH HEIGHT + m.nOffset + THIS.oRptField.Height + IIF(_mac, RPT_PTPERPIX_MAC, RPT_PTPERPIX) ;
				FOR ObjType == OT_BAND .AND. ObjCode == OC_SUMMARY

		ENDIF

		THIS.ReadStyleRec("THIS.oRptField")

		THIS.oRptField.Stretch = .T.    && allow text labels to stretch here

		DO CASE
			CASE iTotalType == I_TOTAL_COUNT
				cSubtotal = SUBCNT_LOC
				cGrandTotal = GRANDCNT_LOC
				cTotal = COUNT_LOC
			CASE iTotalType == I_TOTAL_SUM
				cSubtotal = SUBTOT_LOC
				cGrandTotal = GRANDTOT_LOC
				cTotal = TOTAL_LOC
			CASE iTotalType == I_TOTAL_PCT
				cSubtotal = SUBPCT_LOC
				cGrandTotal = GRANDPCT_LOC
				cTotal = PCT_LOC
			CASE iTotalType == I_TOTAL_AVG
				cSubtotal = SUBAVG_LOC
				cGrandTotal = GRANDAVG_LOC
				cTotal = AVG_LOC
			CASE iTotalType == I_TOTAL_MIN
				cSubtotal = SUBMIN_LOC
				cGrandTotal = GRANDMIN_LOC
				cTotal = MIN_LOC
			CASE iTotalType == I_TOTAL_MAX
				cSubtotal = SUBMAX_LOC
				cGrandTotal = GRANDMAX_LOC
				cTotal = MAX_LOC
		ENDCASE
		
		* Insert text labels associated with subtotals
		IF THIS.lSubTotals
			m.nGrpVPos = m.nVPos
			IF oEngine.lOneToMany
				WITH THIS.oRptField
					.WIDTH = IIF(THIS.nSubtotWidth == 0, THIS.nIndent, THIS.nSubtotWidth)
					IF iTotalType == I_TOTAL_PCT
						.EXPR = "[" + cSubTotal + "]"
					ELSE
						.EXPR = "[" + cSubTotal + "]+" + THIS.cMainKey + "+[:]"
					ENDIF
					.OFFSET = 1     && right justify
					.HPOS = THIS.nLblHPos
					.VPOS = m.nOrigVPos
				ENDWITH

				THIS.OInsert(THIS.oRptField, "NewRpt")

				* adjust vertical position to be in the next group band
				m.nGrpVPos = m.nGrpVPos + THIS.nGrpFtrRealHt + m.nRowsOffset

			ELSE
				m.nGrpVPos = m.nOrigVPos
				FOR m.i = THIS.nGrpCnt TO 1 STEP -1
					IF !EMPTY(THIS.aWizGrpExpr[m.i, MOD_RPTEXPR])
						m.wzGrpField = UPPER(THIS.aWizGroups[m.i, GRP_FIELD])

						WITH THIS.oRptField
							.WIDTH = IIF(THIS.nSubtotWidth == 0, THIS.nIndent, THIS.nSubtotWidth)
							IF iTotalType == I_TOTAL_PCT
								.EXPR = "[" + cSubTotal + "]"
							ELSE
								.EXPR = "[" + cSubTotal + "]+" + THIS.aWizGrpExpr[m.i, MOD_RPTEXPR] + "+[:]"
							ENDIF
							.OFFSET = 1     && right justify
							.HPOS = THIS.nLblHPos
							.VPOS = m.nGrpVPos
						ENDWITH

						THIS.OInsert(THIS.oRptField, "NewRpt")

						* adjust vertical position to be in the next group band
						m.nGrpVPos = m.nGrpVPos + THIS.nGrpFtrRealHt + m.nRowsOffset

					ENDIF	&& no group expression
					
				ENDFOR
			ENDIF
		ENDIF

		* Insert "Grand Total" text label
		IF THIS.lGrandTotals
			WITH THIS.oRptField
				.WIDTH = IIF(THIS.nSubtotWidth == 0, THIS.GetTxtWidth("[" + cGrandTotal + "]",;
				    .FontStyle, .FontFace, .FontSize),;
					THIS.nSubtotWidth)
*				.WIDTH = IIF(THIS.nSubtotWidth == 0, THIS.nIndent, THIS.nSubtotWidth)
				.EXPR = "[" + cGrandTotal + "]"
				.OFFSET = 1      && right justify
				.HPOS = THIS.nLblHPos
				.VPOS = m.nOrigSummaryVPos
			ENDWITH

			THIS.OInsert(THIS.oRptField, "NewRpt")
		ENDIF

		
		m.iSummRows = m.iSummRows + 1

	ENDPROC		&& InsSummary

	*>> InsElements: Insert elements found in the detail band into other bands or the detail band
	* Abstract:
	*   This method inserts into the new report elements found in the detail
	*   band, such as lines and boxes.  Using this method we can take elements
	*   from the detail band of the style file and insert them into any other band of
	*   the same height (ie the group header band, group footer, etc)
	* Parameters:
	*   nOffset = vertical offset to adjust elements in the style file when inserting
	*         into the new report file.
	PROTECTED PROCEDURE InsElements
		LPARAMETERS nOffset
		LOCAL nBandStart, nBandEnd

		IF TYPE("m.nOffset") <> "N"
			m.nOffset = 0
		ENDIF


		* nBandStart & nBandEnd are the boundaries of the detail band in the style file
		m.nBandStart = THIS.nTitleBandHt + ;
			THIS.nPageHdrBandHt + THIS.nGrpHdrHt

		m.nBandEnd   = THIS.nTitleBandHt + ;
			THIS.nPageHdrBandHt + THIS.nGrpHdrHt + ;
			THIS.nDetailBandHt

		THIS.InsPageInfo(m.nBandStart, m.nBandEnd, m.nOffset, ;
			THIS.nColWidth, 0)
	ENDPROC





	*>> InsPageFtr: Insert page footer
	PROTECTED PROCEDURE InsPageFtr
		LOCAL nBandStart, nBandEnd, nOffset


		m.nBandStart = THIS.nTitleBandHt + ;
			THIS.nPageHdrBandHt + THIS.nGrpHdrHt + THIS.nGrpFtrHt + ;
			THIS.nDetailBandHt

		m.nBandEnd = m.nBandStart + THIS.nPageFtrBandHt + WZ_BASEBAND * 4

		m.nOffset = THIS.nLblOffset + THIS.nDetailOffset - THIS.nGrpHdrHt - THIS.nGrpFtrHt + ;
			THIS.nGrpHOffset + THIS.nGrpFOffset + THIS.nColOffset + THIS.nColOffset

		THIS.InsPageInfo(m.nBandStart, m.nBandEnd, m.nOffset, THIS.nColWidth)
	ENDPROC



	*>> InsGrpHdr: Insert group header information
	PROTECTED FUNCTION InsGrpHdr
		LPARAMETER cExpr, m.nGrpHPos, m.nGrpVPos, m.cSample, m.cDataType, m.nLength, m.nDec

		WITH THIS.oRptGrpField
			.Expr      = m.cExpr
			.FontStyle = 1
			.Picture   = ""
			.HPos      = m.nGrpHPos
			.VPos      = m.nGrpVPos + THIS.nColOffset
		ENDWITH

		IF EMPTY(m.cSample)
			THIS.oRptGrpField.Width = THIS.GetFldWidth(m.cDataType, m.nLength, m.nDec, ;
				THIS.oRptGrpField.FontStyle, ;
				THIS.oRptGrpField.FontFace, ;
				THIS.oRptGrpField.FontSize)
		ELSE
			THIS.oRptGrpField.Width = THIS.GetTxtWidth(m.cSample, THIS.oRptGrpField.FontStyle, ;
				THIS.oRptGrpField.FontFace, ;
				THIS.oRptGrpField.FontSize) + RPT_KLUDGE
		ENDIF

		RETURN THIS.oRptGrpField
	ENDFUNC


	*>> InsLabel: Insert label information in the appropriate band
	PROTECTED PROCEDURE InsLabel
		LPARAMETER m.cLblObject, cLabel, m.nLblHPos, m.nLblVPos, m.nWidth, m.lFloat, m.nFldWidth
		LOCAL m.oLabel

		m.oLabel = EVAL(m.cLblObject)
		IF ISNULL(m.oLabel)
			RETURN
		ENDIF

		* Set original label properties -- just in case they got changed along the way
		THIS.ReadStyleRec(m.cLblObject)

		m.oLabel.Expr = '"' + m.cLabel + '"'

		m.oLabel.HPos = m.nLblHPos              && Set HPos
		m.oLabel.VPos = m.nLblVPos + THIS.nColOffset && Set VPos

		IF TYPE("m.nWidth") = "N" .AND. m.nWidth > 0
			* Labels for vertical-layout reports should all be the same width
			m.oLabel.Width = m.nWidth
		ELSE
			m.oLabel.Width = THIS.GetTxtWidth(m.cLabel, m.oLabel.FontStyle, ;
				m.oLabel.FontFace, ;
				m.oLabel.FontSize)
		ENDIF

		* Support right justifying labels for numeric fields
		IF m.nFldWidth > m.oLabel.Width
			IF !EMPTY(THIS.aWizGroups[1, GRP_FIELD]) AND THIS.aWizGroups[1,GRP_MODCODE]="N0"
				m.oLabel.HPos = m.oLabel.HPos
			ELSE
				m.oLabel.HPos = m.oLabel.HPos + (m.nFldWidth - m.oLabel.Width)
			ENDIF
		ENDIF

		IF m.lFloat
			m.oLabel.Float = .T.
			m.oLabel.Top  = .F.
		ENDIF


		THIS.OInsert(m.oLabel, "NewRpt")

	ENDPROC


	*>> InsGenField: Insert General field
	PROTECTED PROCEDURE InsGenField
		LPARAMETER cExpr

		THIS.ReadStyleRec("THIS.oRptGeneral")
		THIS.oRptGeneral.Expr = ""
		THIS.oRptGeneral.Name = m.cExpr

		RETURN THIS.oRptGeneral

	ENDPROC

	*>> InsMemoField: Insert memo field
	PROTECTED FUNCTION InsMemoField
		LPARAMETER cExpr

		THIS.ReadStyleRec("THIS.oRptMemo")
		THIS.oRptMemo.Expr = m.cExpr


		RETURN THIS.oRptMemo
	ENDFUNC


	*>> InsField: Insert normal field
	PROTECTED FUNCTION InsField
		LPARAMETERS cExpr, cDataType, nLength, nDec

		IF m.nLength > RPT_MAXCHAR
			RETURN THIS.InsMemoField(m.cExpr)
		ENDIF

		THIS.ReadStyleRec("THIS.oRptField")

		THIS.oRptField.Expr = m.cExpr

		* Special handling for different data types
		DO CASE
		CASE INLIST(m.cDataType, DT_MONEY, DT_NUM, DT_FLOAT, DT_DOUBLE, DT_INT)
			THIS.oRptField.SupValChng = .F.    && print repeated values for numerics
			THIS.oRptField.SupAlways  = .T.
			THIS.oRptField.FillChar = "N"
			THIS.oRptField.Offset = 1

		CASE INLIST(m.cDataType, DT_CHAR, DT_MEMO, DT_VARCHAR, DT_VARBINARY, DT_BLOB)
			THIS.oRptField.FillChar = "C"

		CASE INLIST(m.cDataType, DT_DATE, DT_TIME)
			THIS.oRptField.FillChar = "D"

		ENDCASE

		THIS.oRptField.Width = THIS.GetFldWidth(m.cDataType, m.nLength, m.nDec, ;
			THIS.oRptField.FontStyle, ;
			THIS.oRptField.FontFace, ;
			THIS.oRptField.FontSize)


		RETURN THIS.oRptField

	ENDFUNC


	*>> InsOneToMany: Insert one-to-many parent information in a group header
	* Abstract:
	*   The parent info in a one-to-many report is displayed in a group header band,
	*   with the many (child) information contained in the detail band.
	*   This method inserts the parent information into the group header band,
	*   while InsDetail() will insert the child information.  Parent information is
	*   ALWAYS layed out vertically, so that is all this method handles.  InsDetail(),
	*   on the other hand, handles horizontal & layout reports. But in a 1-Many, the
	*   child info is always horizontal.
	*
	PROCEDURE InsOneToMany
		LOCAL i, nFldPos, cName, cDataType, nLength, nDec
		LOCAL nSelect, nFldVPos, nFldHPos, nLblVPos, nLblHPos
		LOCAL nTempWidth, nMaxLblWidth, nMaxHeight
		LOCAL oNewFldRec, oNewGrpRec
		LOCAL j, lFloat

		m.lFloat = .F.

		m.nFldVPos = THIS.n1MFldVPos + THIS.nColoffset + THIS.nGrpHOffset
		m.nFldHPos = THIS.n1MFldHPos
		m.nLblVPos = THIS.n1MLblVPos
		m.nLblHPos = THIS.n1MLblHPos

		m.nMaxLblWidth = 0
		* Determine maximum label width
		IF !ISNULL(THIS.oParentLabel)
			FOR m.i = 1 TO ALEN(THIS.aParentLabels, 1)
				m.nTempWidth = THIS.GetTxtWidth(THIS.aParentLabels[m.i, 1], ;
					THIS.oParentLabel.FontStyle, ;
					THIS.oParentLabel.FontFace, ;
					THIS.oParentLabel.FontSize)
				IF m.nTempWidth > m.nMaxLblWidth
					m.nMaxLblWidth = m.nTempWidth
				ENDIF
			ENDFOR && i = 1 TO ALEN(THIS.aParentLabels, 1)
		ENDIF

		m.nFldHPos = m.nLblHPos + m.nMaxLblWidth + THIS.nLblSpacing

		#if .F.
			* Insert divider for the vertical report (between the label & the field)
			IF TYPE("THIS.oRptVDivider") = "O"
				THIS.oRptVDivider.HPos = m.nFldHPos - (THIS.nFldHPos - THIS.oRptVDivider.HPos)
				THIS.oRptVDivider.VPos = THIS.oRptVDivider.VPos + THIS.nColoffset
				THIS.OInsert(THIS.oRptVDivider, "NewRpt")
			ENDIF
		#endif

		IF TYPE("THIS.oRptHDivider") = "O"
			IF C_HSTRETCH $ UPPER(THIS.oRptHDivider.Comment) .OR. ;
					THIS.oRptHDivider.HPos + THIS.oRptHDivider.Width > THIS.nColWidth

				THIS.oRptHDivider.Width = THIS.nColWidth - THIS.oRptHDivider.HPos

			ENDIF
		ENDIF


		m.nSelect = SELECT()
		SELECT NewRpt

		m.nMaxHeight = 0
		* For every selected field, add it to the report
		FOR m.i = 1 TO ALEN(THIS.aParentFields, 1)
			THIS.DoTherm(0, THERM_DETAIL_LOC)

			IF EMPTY(THIS.aParentFields[m.i, 1])
				LOOP
			ENDIF


			* Find the selected field in the big field list so that we
			* can retrieve data type, length, etc
			m.cUpperFld = UPPER(THIS.aParentFields[m.i, 1])
			FOR m.nFldPos = 1 TO ALEN(THIS.aParentFList, 1)
				IF m.cUpperFld == UPPER(THIS.aParentFList[m.nFldPos, 1])
					EXIT
				ENDIF
			ENDFOR &&

			* The selected field wasn't found in the field list.
			* This could be a fairly serious problem, but in this
			* case we'll just grab the next selected field & continue on.
			IF m.nFldPos > ALEN(THIS.aParentFList, 1)
				LOOP
			ENDIF

			* Quick references to the array values
			m.cName  = THIS.cParentAlias + "." + THIS.aParentFList[m.nFldPos, FLD_NAME]
			m.cDataType = THIS.aParentFList[m.nFldPos, FLD_TYPE]
			m.nLength   = THIS.aParentFList[m.nFldPos, FLD_LEN]
			m.nDec   = THIS.aParentFList[m.nFldPos, FLD_DEC]

			* Insert the specific field type
			DO CASE
			CASE cDataType = DT_GEN     && General field
				oNewFldRec = THIS.InsGenField(m.cName)

			CASE cDataType = DT_MEMO    && Memo field
				oNewFldRec = THIS.InsMemoField(m.cName)

			CASE cDataType = DT_BLOB && Memo field
				oNewFldRec = THIS.InsMemoField(m.cName)

			OTHERWISE
				oNewFldRec = THIS.InsField(m.cName, m.cDataType, m.nLength, m.nDec)

			ENDCASE

			* Set the horizontal & vertical positions for this field.
			oNewFldRec.HPOS = m.nFldHPos
			oNewFldRec.VPOS = m.nFldVPos

			* If our field exceeds our report width, then shorten it
			IF (m.nFldHPOS + oNewFldRec.Width) > THIS.nColWidth
				oNewFldRec.Width = THIS.nColWidth - m.nFldHPos
			ENDIF

			* Insert a horizontal divider between each field
			IF TYPE("THIS.oRptHDivider") = "O" .AND. m.i > 1
				THIS.oRptHDivider.VPos = oNewFldRec.VPos - THIS.nVertSpacing/2
				THIS.OInsert(THIS.oRptHDivider, "NewRpt")
			ENDIF

			THIS.n1MOffset = THIS.n1MOffset + ;
				oNewFldRec.Height + ;
				THIS.nVertSpacing


			* Insert the label before the field
			IF !ISNULL(THIS.oParentLabel)
				m.cLabel = THIS.aParentLabels[m.i, 1]
				THIS.InsLabel("THIS.oParentLabel", m.cLabel, m.nLblHPos, m.nLblVPos, m.nMaxLblWidth, m.lFloat, 0)
			ENDIF

			oNewFldRec.PICTURE = THIS.GetPicture(m.cDataType, m.nLength, m.nDec, oNewFldRec.expr)

			* If a stretched field was placed above us, then make this field float
			IF m.lFloat
				oNewFldRec.Float = .T.
				oNewFldRec.Top  = .F.
			ELSE
				IF oNewFldRec.Stretch
					m.lFloat = .T.
					IF TYPE("THIS.oRptHDivider") = "O"
						THIS.oRptHDivider.Float = .T.
					ENDIF
				ENDIF
			ENDIF


			* Insert modified field record into the new report file
			THIS.OInsert(oNewFldRec, "NewRpt")


			IF !ISNULL(THIS.oParentLabel)
				m.nLblVPos = m.nLblVPos + THIS.nVertSpacing + oNewFldRec.Height
			ENDIF
			m.nFldVPos = m.nFldVPos + THIS.nVertSpacing + oNewFldRec.Height

		ENDFOR && i = 1 TO ALEN(aParentFields, 1)

		THIS.n1MOffset = THIS.n1MOffset - THIS.nVertSpacing - ;
			THIS.oParentField2.Height - THIS.oParentField.Height


		SELECT (m.nSelect)


	ENDPROC


	*>> InsDetail: Insert information that belongs in the detail band
	* Abstract:
	*   This is the guts of the engine. It processes each selected field,
	*   putting it on the report at the proper position in the detail band.
	*   In addition, as it adds each field it also adds a label and
	*   (optionally) a divider.
	*
	*   The label is inserted in the page header band if this is a single
	*   column report, in the column header band otherwise.
	*
	*   If all the fields don't fit in the specified page width, both
	*   fields & labels "wrap" to subsequent lines.  NOTE: the band
	*   heights are not adjusted in this method, but in the AdjustBands()
	*   method after all the fields have been added.
	*
	*   If a divider is specified in the style template, then that divider
	*   (usually a vertical line) is displayed in the detail band between
	*   each of the fields.
	*
	*   Note that tabular & columnar reports are handled somewhat
	*   differently in many aspects, and specific cases related to
	*   each are tested for as we go along.   (Perhaps clarity could
	*   be improved if we separated these into two different methods???)
	*
	PROTECTED PROCEDURE InsDetail
		LOCAL i, nFldPos, cName, cDataType, nLength, nDec
		LOCAL nSelect, nFldVPos, nFldHPos, nLblVPos, nLblHPos, nGrpVPos
		LOCAL nTempWidth, nMaxLblWidth, nMaxHeight, nIncreaseWidth, nLabelWidth
		LOCAL oNewFldRec, oNewGrpRec, cWzTotalIndex
		LOCAL nStretchRow, nFldWidth
		LOCAL iSelect, cFillCharType
		LOCAL lIsModiNum, lHasAnyTotals

		* No fields selected?

		m.nFldVPos = THIS.nFldVPos + THIS.nColoffset + THIS.nGrpHOffset + THIS.n1MOffset
		m.nFldHPos = THIS.nFldHPos
		m.nLblVPos = THIS.nLblVPos + THIS.n1MOffset
		m.nLblHPos = THIS.nLblHPos

		m.nStretchRow = 99  && Row that first stretch field appears on (ie memo or general)

		* Calculate the relative vertical position of group headers within the group band
		IF THIS.oRptGrpField.VPos = 0
			m.nGrpVPos = THIS.nTitleBandHt + THIS.nPageHdrBandHt + ;
				IIF(_mac, RPT_PTPERPIX_MAC, RPT_PTPERPIX) * 3
		ELSE
			m.nGrpVPos = THIS.nTitleBandHt + THIS.nPageHdrBandHt + ;
				THIS.nGrpHdrBandHt + ;
				(THIS.oRptGrpField.VPos - (THIS.nTitleBandHt + ;
				THIS.nPageHdrBandHt + THIS.nGrpHdrBandHt))
		ENDIF

		* Determine maximum label width
		m.nMaxLblWidth = 0
		IF !ISNULL(THIS.oRptLabel)
			FOR m.i = 1 TO ALEN(THIS.aWizLabels, 1)

				m.nTempWidth = THIS.GetTxtWidth(THIS.aWizLabels[m.i, 1], ;
					THIS.oRptLabel.FontStyle, ;
					THIS.oRptLabel.FontFace, ;
					THIS.oRptLabel.FontSize)
				IF m.nTempWidth > m.nMaxLblWidth
					m.nMaxLblWidth = m.nTempWidth
				ENDIF
			ENDFOR && i = 1 TO ALEN(THIS.aWizLabels, 1)
		ENDIF

		IF THIS.nLayout = RPT_LAYVERT
			m.nFldHPos = THIS.nLblHPos + m.nMaxLblWidth + THIS.nLblSpacing

			* Insert divider for the vertical report (between the label & the field)
			* The divider for horizontal reports is handled further down in the method...
			IF TYPE("THIS.oRptVDivider") = "O"
				THIS.oRptVDivider.HPos = m.nFldHPos - (THIS.nFldHPos - THIS.oRptVDivider.HPos)
				THIS.oRptVDivider.VPos = THIS.oRptVDivider.VPos + THIS.nColoffset + THIS.nGrpHOffset
				THIS.OInsert(THIS.oRptVDivider, "NewRpt")

			ENDIF

		ENDIF

		IF TYPE("THIS.oRptVDivider") = "O"
			THIS.oRptVDivider.VPos = THIS.oRptVDivider.VPos + THIS.nColOffset + THIS.nGrpHOffset - THIS.nGrpHdrHt
		ENDIF

		IF TYPE("THIS.oRptHDivider") = "O"
			IF C_HSTRETCH $ UPPER(THIS.oRptHDivider.Comment)
				THIS.oRptHDivider.Width = THIS.nColWidth - THIS.oRptHDivider.HPos
			ENDIF
		ENDIF

		m.nSelect = SELECT()
		
		IF USED("_summary")
			SELECT _summary
			LOCATE FOR lSum OR lAvg OR lCount OR lMin OR lMax
			lHasAnyTotals = FOUND()
			SELECT NewRpt
		ELSE
			lHasAnyTotals = .F.
		ENDIF
		
		m.nMaxHeight = 0
		* For every selected field, add it to the report
		FOR m.i = 1 TO ALEN(THIS.aWizFields, 1)
			THIS.DoTherm(0, THERM_DETAIL_LOC)

			IF EMPTY(THIS.aWizFields[m.i, 1])
				LOOP
			ENDIF

			m.nIncreaseWidth = 0
			m.nLabelWidth = 0

			* Find the selected field in the big field list so that we
			* can retrieve data type, length, etc
			m.cUpperFld = UPPER(THIS.aWizFields[m.i, 1])

			FOR m.nFldPos = 1 TO ALEN(THIS.aWizFList, 1)
				IF m.cUpperFld == UPPER(THIS.aWizFList[m.nFldPos, 1])
					EXIT
				ENDIF
			ENDFOR

			* The selected field wasn't found in the field list.
			* This could be a fairly serious problem, but in this
			* case we'll just grab the next selected field & continue on.
			IF m.nFldPos > ALEN(THIS.aWizFList, 1)
				LOOP
			ENDIF

			* Quick references to the array values
			m.cName  = IIF(THIS.lOneToMany, THIS.cWizAlias + ".", "") + THIS.aWizFList[m.nFldPos, FLD_NAME]
			m.cDataType = THIS.aWizFList[m.nFldPos, FLD_TYPE]
			m.nLength   = THIS.aWizFList[m.nFldPos, FLD_LEN]
			m.nDec   = THIS.aWizFList[m.nFldPos, FLD_DEC]


			oNewGrpRec = .NULL.

			* If this is a group report, then add group header & lengthen numeric fields:
			IF THIS.lGroupRpt
				IF m.i <= THIS.nGrpCnt
					* Insert group header
					IF !EMPTY(THIS.aWizGroups[m.i, GRP_FIELD]) AND !EMPTY(THIS.aWizGrpExpr[m.i, MOD_RPTEXPR])
						oNewGrpRec = THIS.InsGrpHdr(THIS.aWizGrpExpr[m.i, MOD_RPTEXPR], m.nLblHPos, m.nGrpVPos, THIS.aWizGrpExpr[m.i, MOD_TXTWID], ;
							m.cDataType, m.nLength, m.nDec)

						m.nGrpVPos = m.nGrpVPos + THIS.nGrpHdrRealHt
					ENDIF
				ENDIF
				
				lIsModiNum = (i <= ALEN(THIS.aWizGroups,1) AND (!EMPTY(THIS.aWizGroups[m.i, GRP_FIELD]) AND ;
						LEFT(THIS.aWizGroups[m.i, GRP_MODCODE],1) = "N" AND VAL(SUBS(THIS.aWizGroups[m.i, GRP_MODCODE],2,1)) > 0))
				*- If first non-grouping field, or field is modified numeric field
				IF (m.i > THIS.nGrpCnt) OR lIsModiNum OR (m.i == 1 AND THIS.lOneToMany AND m.lHasAnyTotals)
					* This is our first non-Group field.  Therefore, change the default
					* horizontal position for fields & labels so that when we wrap, we
					* don't end up beneath the group fields.  For example:
					*   Group1
					*     Group2
					*       Field1   Field2 Field3
					*       Field4   Field5
					IF (m.i == (THIS.nGrpCnt + 1) AND !THIS.lOneToMany) OR lIsModiNum OR (m.i == 1 AND THIS.lOneToMany AND m.lHasAnyTotals)

						IF THIS.lSubTotals OR THIS.lGrandTotals 
							IF !INLIST(m.cDataType, DT_MEMO, DT_GEN, DT_LOGIC)
								m.nFldHPos = MAX(m.nFldHPos, 17000)
							ENDIF
							m.nLblHPos = m.nFldHPos
						ENDIF

						THIS.nIndent = m.nLblHPos - THIS.nLblHPos

					ENDIF


					IF INLIST(m.cDataType, DT_FLOAT, DT_NUM, DT_DOUBLE, DT_MONEY, DT_INT) .AND. (THIS.lGrandTotals .OR. THIS.lSubTotals)
						* If we're going to total a field, then lengthen it to handle a large total
						m.nLength = m.nLength + 3
					ENDIF
				ENDIF
			ENDIF


			* Insert the specific field type
			DO CASE
			CASE cDataType = DT_GEN     && General field
				oNewFldRec = THIS.InsGenField(m.cName)

			CASE cDataType = DT_MEMO    && Memo field
				oNewFldRec = THIS.InsMemoField(m.cName)

			CASE cDataType = DT_BLOB   && Blob field
				oNewFldRec = THIS.InsMemoField(m.cName)

			OTHERWISE
				oNewFldRec = THIS.InsField(m.cName, m.cDataType, m.nLength, m.nDec)

			ENDCASE



			* Determine the label width now so that we can determine if we're going to
			* overrun the page length -- do the actual insertion of the label a little later
			* in this method.
			IF THIS.nLayout = RPT_LAYHORZ .AND. !ISNULL(THIS.oRptLabel)
				m.nMaxLblWidth = THIS.GetTxtWidth(THIS.aWizLabels[m.i, 1], ;
					THIS.oRptLabel.FontStyle, ;
					THIS.oRptLabel.FontFace, ;
					THIS.oRptLabel.FontSize)
			ENDIF



			* Set the horizontal & vertical positions for this field.
			oNewFldRec.HPOS = m.nFldHPos
			oNewFldRec.VPOS = m.nFldVPos


			* If we've exceeded the field width then handle wrapping the
			* labels & fields to new lines.
			DO CASE
			CASE THIS.nLayout = RPT_LAYHORZ .AND. ;
					(m.nFldHPOS + oNewFldRec.Width > THIS.nColWidth .OR. ;
					m.nLblHPos + m.nMaxLblWidth > THIS.nColWidth)


				* If we're truncating fields, then we want to exit now rather than
				* perform any wrapping.
				IF THIS.lTruncate
					EXIT
				ENDIF

				* Adjust field position
				m.nFldHPos = THIS.nFldHPos + THIS.nIndent


				m.nFldVPos = m.nFldVPos + m.nMaxHeight + IIF(_mac, RPT_PTPERPIX_MAC, RPT_PTPERPIX)


				* Adjust label position
				IF !ISNULL(THIS.oRptLabel)
					m.nLblHPos = THIS.nLblHPos + THIS.nIndent
					m.nLblVPos = m.nLblVPos + THIS.oRptLabel.Height + IIF(_mac, RPT_PTPERPIX_MAC, RPT_PTPERPIX)
				ENDIF


				oNewFldRec.HPOS = m.nFldHPos
				oNewFldRec.VPOS = m.nFldVPos

				THIS.nDetailRows = THIS.nDetailRows + 1
				THIS.nDetailOffset = THIS.nDetailOffset + m.nMaxHeight + IIF(_mac, RPT_PTPERPIX_MAC, RPT_PTPERPIX)

				m.nMaxHeight = 0

			CASE THIS.nLayout = RPT_LAYHORZ .AND. m.i > 1 .AND. ;
					TYPE("THIS.oRptVDivider") = "O" .AND. ;
					THIS.nDetailRows = 1 .AND. m.i > THIS.nGrpCnt

				* Insert the divider which appears between each field
				* (But, only if this is the first detail row)
				THIS.oRptVDivider.HPos = oNewFldRec.HPos - THIS.nHorzSpacing/2

				*- The vertical position of the divider needs adjusting only once
				if m.i = 2
					THIS.oRptVDivider.VPos = THIS.oRptVDivider.VPos + THIS.n1MOffset
				endif

				THIS.OInsert(THIS.oRptVDivider, "NewRpt")


			CASE THIS.nLayout = RPT_LAYVERT
				* If our field exceed our report width, then shorten it
				IF (m.nFldHPOS + oNewFldRec.Width) > THIS.nColWidth
					oNewFldRec.Width = THIS.nColWidth - m.nFldHPos
				ENDIF

				* Insert a horizontal divider between each field
				IF TYPE("THIS.oRptHDivider") = "O" .AND. m.i > 1

					* If this is NOT an invisible line or this line floats, then insert it
					IF THIS.oRptHDivider.PenPat > 0 .OR. THIS.oRptHDivider.Float
						THIS.oRptHDivider.VPos = oNewFldRec.VPos - THIS.nVertSpacing/2
						THIS.OInsert(THIS.oRptHDivider, "NewRpt")
					ENDIF
				ENDIF

				THIS.nDetailOffset = THIS.nDetailOffset + ;
					oNewFldRec.Height + ;
					THIS.nVertSpacing

			ENDCASE


			* Insert the label before the field
			IF !ISNULL(THIS.oRptLabel)
				m.cLabel = THIS.aWizLabels[m.i, 1]

				* If we're in a horizontal layout, and this is a numeric field, then we
				* want to right justify the label to line it up properly with the field.
				* Therefore, we'll pass the field width to the InsLabel method.  If we
				* don't want to line it up, pass a 0.
				IF THIS.nLayout == RPT_LAYHORZ AND INLIST(m.cDataType, DT_FLOAT, DT_NUM, DT_DOUBLE, DT_MONEY, DT_INT)
					m.nFldWidth = oNewFldRec.Width
				ELSE
					m.nFldWidth = 0
				ENDIF

				THIS.InsLabel("THIS.oRptLabel", m.cLabel, m.nLblHPos, m.nLblVPos, ;
					m.nMaxLblWidth, ;
					m.nStretchRow < THIS.nDetailRows .AND. THIS.nLayout == RPT_LAYVERT, m.nFldwidth)
			ENDIF


			* Insert the normal field or the group field -- but not both (unless group by modified numeric)
			IF !ISNULL(oNewGrpRec)
				* If we have a group header, insert it now
				THIS.OInsert(oNewGrpRec, "NewRpt")

				m.nIncreaseWidth = m.nMaxLblWidth + THIS.nIndent

				IF !EMPTY(THIS.aWizGroups[m.i, GRP_FIELD]) AND ;
						LEFT(THIS.aWizGroups[m.i, GRP_MODCODE],1) = "N" AND VAL(SUBS(THIS.aWizGroups[m.i, GRP_MODCODE],2,1)) > 0
					*- grouping by numerical modifier, so include actual numeric field
					oNewGrpRec = .NULL.
				ENDIF
			ENDIF
			IF ISNULL(oNewGrpRec)
				* Keep track of the tallest element on each detail line
				m.nMaxHeight = MAX(m.nMaxHeight, oNewFldRec.Height)

				oNewFldRec.Picture = THIS.GetPicture(m.cDataType, m.nLength, m.nDec,oNewFldRec.Expr)

				* If a stretched field was placed above us, then make this field float
				IF m.nStretchRow < THIS.nDetailRows
					oNewFldRec.Float = .T.
					oNewFldRec.Top = .F.
				ENDIF

				IF m.nStretchRow = 99 .AND. oNewFldRec.Stretch
					m.nStretchRow = THIS.nDetailRows
					IF TYPE("THIS.oRptHDivider") = "O"
						THIS.oRptHDivider.Float = .T.
					ENDIF

				ENDIF

				* Insert modified field record into the new report file
				THIS.OInsert(oNewFldRec, "NewRpt")

				m.nIncreaseWidth = oNewFldRec.Width

			ENDIF


			*- Insert subtotals and subtotal text for groups. We don't subtotal for grouping fields, unless it's a modified numeric field
			IF THIS.lGroupRpt AND (THIS.lSubTotals .OR. THIS.lGrandTotals) AND (m.i > THIS.nGrpCnt OR ISNULL(oNewGrpRec))

				*- we can have multiple total types (e.g., count + sum + min + max + avg)
				IF !INLIST(m.cDataType, DT_MEMO, DT_GEN)
					* Special handling for different data types
					DO CASE
						CASE INLIST(m.cDataType, DT_MONEY, DT_NUM, DT_FLOAT, DT_DOUBLE, DT_INT)
							m.cFillCharType = "N"
						CASE INLIST(m.cDataType, DT_CHAR, DT_MEMO)
							m.cFillCharType = "C"
						CASE INLIST(m.cDataType, DT_DATE, DT_TIME)
							m.cFillCharType = "D"
					ENDCASE

					*- check each summary type (count, sum, min, max, avg)
					iSelect = SELECT()

					SELECT _summary
					LOCATE FOR UPPER(THIS.aWizFList[m.nFldPos, FLD_NAME]) = UPPER(cField)
					IF FOUND()
						IF INLIST(m.cDataType, DT_FLOAT, DT_NUM, DT_DOUBLE, DT_MONEY, DT_INT, DT_DATE, DT_TIME)
							*- can't sum or average dates
							IF INLIST(m.cDataType, DT_FLOAT, DT_NUM, DT_DOUBLE, DT_MONEY, DT_INT)
								*- can only sum and avg numeric type fields
								IF lSum
									THIS.nTotalCnt = THIS.nTotalCnt + 1
									DIMENSION THIS.aWizTotals[THIS.nTotalCnt, 6]
									THIS.aWizTotals[THIS.nTotalCnt, 1] = oNewFldRec.Expr
									THIS.aWizTotals[THIS.nTotalCnt, 2] = THIS.nDetailRows
									THIS.aWizTotals[THIS.nTotalCnt, 3] = oNewFldRec.Picture
									THIS.aWizTotals[THIS.nTotalCnt, 4] = m.cFillCharType
									THIS.aWizTotals[THIS.nTotalCnt, 5] = oNewFldRec.HPos
									THIS.aWizTotals[THIS.nTotalCnt, 6] = oNewFldRec.Width
									IF THIS.lPercentOfTotal
										DIMENSION THIS.aWizPctTotals[THIS.nTotalCnt, 6]
										cWzTotalIndex = LTRIM(STR(THIS.nTotalCnt))
										*- use a divisor of .00001 if total == 0
										THIS.aWizPctTotals[THIS.nTotalCnt, 1] = "(" + ALLT(oNewFldRec.Expr) + ")/IIF(_wztotals[" + cWzTotalIndex + "] = 0, .00001, _wztotals[" + cWzTotalIndex + "])* 100"
										THIS.aWizPctTotals[THIS.nTotalCnt, 2] = THIS.nDetailRows
										THIS.aWizPctTotals[THIS.nTotalCnt, 3] = ["999.99%"]
										THIS.aWizPctTotals[THIS.nTotalCnt, 4] = m.cFillCharType
										THIS.aWizPctTotals[THIS.nTotalCnt, 5] = oNewFldRec.HPos
										THIS.aWizPctTotals[THIS.nTotalCnt, 6] = oNewFldRec.Width							
									ENDIF

								ENDIF

								IF lAvg
									THIS.nAvgCnt = THIS.nAvgCnt + 1
									DIMENSION THIS.aWizAvg[THIS.nAvgCnt, 6]
									THIS.aWizAvg[THIS.nAvgCnt, 1] = oNewFldRec.Expr
									THIS.aWizAvg[THIS.nAvgCnt, 2] = THIS.nDetailRows
									THIS.aWizAvg[THIS.nAvgCnt, 3] = oNewFldRec.Picture
									THIS.aWizAvg[THIS.nAvgCnt, 4] = m.cFillCharType
									THIS.aWizAvg[THIS.nAvgCnt, 5] = oNewFldRec.HPos
									THIS.aWizAvg[THIS.nAvgCnt, 6] = oNewFldRec.Width
								ENDIF
							ENDIF
							IF lMin
								THIS.nMinCnt = THIS.nMinCnt + 1
								DIMENSION THIS.aWizMin[THIS.nMinCnt, 6]
								THIS.aWizMin[THIS.nMinCnt, 1] = oNewFldRec.Expr
								THIS.aWizMin[THIS.nMinCnt, 2] = THIS.nDetailRows
								THIS.aWizMin[THIS.nMinCnt, 3] = oNewFldRec.Picture
								THIS.aWizMin[THIS.nMinCnt, 4] = m.cFillCharType
								THIS.aWizMin[THIS.nMinCnt, 5] = oNewFldRec.HPos
								THIS.aWizMin[THIS.nMinCnt, 6] = oNewFldRec.Width
							ENDIF

							IF lMax
								THIS.nMaxCnt = THIS.nMaxCnt + 1
								DIMENSION THIS.aWizMax[THIS.nMaxCnt, 6]
								THIS.aWizMax[THIS.nMaxCnt, 1] = oNewFldRec.Expr
								THIS.aWizMax[THIS.nMaxCnt, 2] = THIS.nDetailRows
								THIS.aWizMax[THIS.nMaxCnt, 3] = oNewFldRec.Picture
								THIS.aWizMax[THIS.nMaxCnt, 4] = m.cFillCharType
								THIS.aWizMax[THIS.nMaxCnt, 5] = oNewFldRec.HPos
								THIS.aWizMax[THIS.nMaxCnt, 6] = oNewFldRec.Width
							ENDIF
						ENDIF
						
						IF lCount
							THIS.nCountCnt = THIS.nCountCnt + 1
							DIMENSION THIS.aWizCount[THIS.nCountCnt, 6]
							THIS.aWizCount[THIS.nCountCnt, 1] = oNewFldRec.Expr
							THIS.aWizCount[THIS.nCountCnt, 2] = THIS.nDetailRows
							THIS.aWizCount[THIS.nCountCnt, 3] = REPLICATE('9',MIN(15,LEN(oNewFldRec.Picture)))	&& oNewFldRec.Picture
							THIS.aWizCount[THIS.nCountCnt, 4] = 'N'
							THIS.aWizCount[THIS.nCountCnt, 5] = oNewFldRec.HPos
							THIS.aWizCount[THIS.nCountCnt, 6] = oNewFldRec.Width
						ENDIF

					ENDIF
					SELECT (iSelect)
				ENDIF		&& !INLIST(m.cDataType, DT_MEMO, DT_GEN)
			ENDIF

			* Update horizontal & vertical positions for the NEXT field
			IF THIS.nLayout = RPT_LAYHORZ
				m.nFldHPos = m.nFldHPos + MAX(m.nMaxLblWidth, m.nIncreaseWidth) + ;
					THIS.nHorzSpacing
				m.nLblHPos = m.nLblHPos + MAX(m.nMaxLblWidth, m.nIncreaseWidth) + ;
					THIS.nHorzSpacing
			ELSE
				IF !ISNULL(THIS.oRptLabel)
					m.nLblVPos = m.nLblVPos + THIS.nVertSpacing + oNewFldRec.Height
				ENDIF
				m.nFldVPos = m.nFldVPos + THIS.nVertSpacing + oNewFldRec.Height
				THIS.nDetailRows = THIS.nDetailRows + 1

			ENDIF


			IF THIS.lGroupRpt AND m.i == (THIS.nGrpCnt + 1) AND INLIST(m.cDataType, DT_LOGIC, DT_MEMO, DT_GEN) && !INLIST(m.cDataType, DT_FLOAT, DT_NUM, DT_DOUBLE, DT_MONEY, DT_INT)
				THIS.nSubtotWidth = THIS.nIndent + oNewFldRec.Width
			ENDIF

		ENDFOR && i = 1 TO ALEN(aWizFields, 1)


		* Adjust label & field offsets
		IF THIS.nLayout = RPT_LAYHORZ
			THIS.nFldOffset = m.nFldVPos - THIS.nFldVPos
			THIS.nLblOffset = m.nLblVPos - THIS.nLblVPos
			THIS.nDetailOffset = THIS.nDetailOffset + m.nMaxHeight - THIS.oRptField.Height && - (IIF(_mac, RPT_PTPERPIX_MAC, RPT_PTPERPIX) * (THIS.nDetailRows - 1))
		ENDIF


		SELECT (m.nSelect)

	ENDPROC



	*>> InsBands: Insert records for each band type
	* Abstract:
	*   Different bands get inserted into the new report depending on
	*   the properties set:
	*    - Group reports get group header and footer bands, and summary
	*    - Multi-column reports get column headers & footers, and set
	*     the page header to no height.
	*
	PROTECTED PROCEDURE InsBands
		LOCAL nSaveHeight

		SELECT StyleFile

		SCAN FOR objtype=OT_BAND AND TRIM(platform) = THIS.cPlatform
			DO CASE
			CASE ObjCode=OC_TITLE
				THIS.nTitleBandHt = Height + WZ_BASEBAND

			CASE ObjCode=OC_PGHEAD
				THIS.nPageHdrBandHt = Height + WZ_BASEBAND

			CASE ObjCode=OC_PGFOOT
				THIS.nPageFtrBandHt = Height + WZ_BASEBAND

			CASE ObjCode=OC_DETAIL
				THIS.nDetailBandHt = Height + WZ_BASEBAND
				THIS.AddStyleRec("THIS.oBand", "BAND")

			CASE ObjCode=OC_GRPHEAD .AND. (THIS.lGroupRpt .OR. THIS.lOneToMany)
				THIS.nGrpHdrBandHt = Height + WZ_BASEBAND

			CASE ObjCode=OC_GRPFOOT .AND. THIS.nGrpFtrBandHt = 0 .AND. ;
					(THIS.lGroupRpt .OR. THIS.lOneToMany)
				*- if we are totalling in a 1-Many report, override size of group footer band
				THIS.nGrpFtrBandHt = IIF((THIS.lGroupRpt .AND. THIS.lOneToMany),0,Height) + WZ_BASEBAND

			ENDCASE
		ENDSCAN

		THIS.nColFtrBandHt = 0

		THIS.nGrpHdrRealHt = IIF(THIS.nGrpHdrBandHt <= WZ_BASEBAND, THIS.nDetailBandHt, THIS.nGrpHdrBandHt)
		THIS.nGrpFtrRealHt = IIF(THIS.nGrpFtrBandHt <= WZ_BASEBAND, THIS.nDetailBandHt, THIS.nGrpFtrBandHt)

		* Insert title band
		THIS.oBand.Height = THIS.nTitleBandHt - WZ_BASEBAND
		THIS.oBand.ObjCode = OC_TITLE
		THIS.OInsert(THIS.oBand, "NewRpt")


		m.nSaveHeight = THIS.nPageHdrBandHt

		IF THIS.nColumns > 1
			* This is the page header record and there are multiple columns.
			* Create a column header record & assign the page header
			*  height to the column header height.
			* Set the page header height to 0.
			* Insert the page header before the column header.

			THIS.nColHdrBandHt = THIS.nPageHdrBandHt
			THIS.oBand.Height = 0
		ELSE
			THIS.oBand.Height = THIS.nPageHdrBandHt - WZ_BASEBAND
		ENDIF


		* Insert page header band
		THIS.oBand.ObjCode = OC_PGHEAD
		THIS.OInsert(THIS.oBand, "NewRpt")

		* Insert column header band
		IF THIS.nColumns > 1
			THIS.oBand.Height = THIS.nColHdrBandHt - WZ_BASEBAND
			THIS.oBand.ObjCode = OC_COLHEAD
			THIS.OInsert(THIS.oBand, "NewRpt")
		ENDIF

		* Insert group header bands
		IF THIS.lGroupRpt .OR. THIS.lOneToMany
			THIS.oBand.Height = THIS.nGrpHdrRealHt - WZ_BASEBAND
			THIS.oBand.ObjCode = OC_GRPHEAD
			THIS.oBand.Plain = .F.

			FOR m.i = 1 TO THIS.nGrpCnt
				* Exit if we hit an empty group
				IF EMPTY(THIS.aWizGroups[i, GRP_FIELD])
					EXIT
				ENDIF


				IF THIS.lOneToMany
					THIS.oBand.Expr = THIS.aWizGroups[m.i, GRP_FIELD]
				ELSE
					THIS.oBand.Expr = THIS.aWizGrpExpr[m.i, MOD_GRPEXPR]
				ENDIF

				* Width field of a group band is actually minimum distance from bottom
				* that the group header will print. We'll use the following formula:
				*  Group header height + three times the detail height
				THIS.oBand.Width = THIS.oBand.Height + (THIS.nDetailBandHt * 3)

				THIS.OInsert(THIS.oBand, "NewRpt")

				* Set offset for fields
				THIS.nGrpHOffset = THIS.nGrpHOffset + THIS.oBand.Height + WZ_BASEBAND
			ENDFOR
			THIS.ReadStyleRec("THIS.oBand")
		ENDIF

		* Insert detail band
		THIS.oBand.ObjCode = OC_DETAIL
		THIS.oBand.Height = THIS.nDetailBandHt - WZ_BASEBAND
		THIS.OInsert(THIS.oBand, "NewRpt")

		* Insert group footer bands
		IF THIS.lGroupRpt .OR. THIS.lOneToMany
			THIS.oBand.ObjCode = OC_GRPFOOT

			THIS.oBand.Plain = .F.

			DO CASE
				CASE THIS.lOneToMany AND !THIS.lSubTotals
					THIS.oBand.Height = MAX(THIS.nGrpFtrBandHt - WZ_BASEBAND, 0)
				CASE !THIS.lSubTotals
					THIS.nGrpFtrBandHt = 0
					THIS.oBand.Height = 0
				OTHERWISE
					THIS.oBand.Height = THIS.nGrpFtrRealHt - WZ_BASEBAND
			ENDCASE


			FOR m.i = 1 TO THIS.nGrpCnt
				* Exit if we hit an empty group
				IF THIS.nGrpCnt = 0
					EXIT
				ENDIF
				THIS.OInsert(THIS.oBand, "NewRpt")

				* Set offset for fields
				THIS.nGrpFOffset = THIS.nGrpFOffset + THIS.oBand.Height + WZ_BASEBAND

			ENDFOR
			THIS.ReadStyleRec("THIS.oBand")

		ENDIF

		* Insert column footer band
		IF THIS.nColumns > 1
			THIS.nColFtrBandHt = WZ_BASEBAND
			THIS.oBand.ObjCode = OC_COLFOOT
			THIS.oBand.Height = THIS.nColFtrBandHt - WZ_BASEBAND

			THIS.OInsert(THIS.oBand, "NewRpt")
		ENDIF

		* Insert page footer footer band
		THIS.oBand.ObjCode = OC_PGFOOT
		THIS.oBand.Height = THIS.nPageFtrBandHt - WZ_BASEBAND
		THIS.OInsert(THIS.oBand, "NewRpt")

		* Insert summary band
		IF THIS.lGroupRpt .AND. THIS.lGrandTotals
			* Insert summary band
			THIS.oBand.ObjCode = OC_SUMMARY
			THIS.oBand.Height = THIS.nGrpFtrBandHt - WZ_BASEBAND
			THIS.oBand.Height = IIF(THIS.nGrpFtrBandHt <= WZ_BASEBAND, THIS.nDetailBandHt, THIS.nGrpFtrBandHt) - WZ_BASEBAND
			THIS.OInsert(THIS.oBand, "NewRpt")
		ENDIF

	ENDPROC


	*>> Adjust1MBand: Adjust the 1-To-Many group header band height & objects in it
	* Abstract:
	*   After adding fields (vertical layout style) to the group header band for the
	*   One-To-Many report, we need to adjust lines & boxes which fall within that
	*   band downwards.
	* Parameters:
	*   nOffset = Amount to adjust
	*   lSkipHeight = .T. to NOT adjust the height of the band itself, .F. otherwise
	*            (necessary because we can call this method twice)
	*
	PROTECTED PROCEDURE Adjust1MBands
		LPARAMETERS nOffset, lSkipHeight

		LOCAL nSelect, nVertStart, nVertEnd

		nSelect = SELECT()
		SELECT NewRpt

		* Adjust the group header band
		* Adjust the detail band
		IF !m.lSkipHeight
			LOCATE FOR ObjType=OT_BAND .AND. ObjCode=OC_GRPHEAD
			REPLACE Height WITH HEIGHT + THIS.n1MOffset
		ENDIF

		* Adjust the vertical positions of the objects within the group header band
		* Specifically, move all lines, boxes, gets, etc which fall below the first
		* label down by nLblOffset. Increase the height of boxes which fall in
		* the detail band by the same amount that the detail band grew.
		m.nVertStart = THIS.nTitleBandHt + THIS.nPageHdrBandHt + THIS.nColOffset - WZ_BASEBAND
		m.nVertEnd = m.nVertStart + WZ_BASEBAND + THIS.nGrpHdrBandHt
		SCAN FOR INLIST(ObjType, OT_LINE, OT_BOX) .AND. ;
				BETWEEN(VPos, m.nVertStart, m.nVertEnd)
			IF !(objType == OT_LINE .AND. Width > Height)
				REPLACE HEIGHT WITH HEIGHT + m.nOffset
			ENDIF
		ENDSCAN

		SELECT (nSelect)

	ENDPROC && Adjust1MBands


	*>> AdjustBands: Adjust bands of new report AFTER adding fields
	* Abstract:
	*   Since we allow the user to wrap fields if they exceed the
	*   report width, we must adjust the detail, page/column header, and group footer
	*   bands accordingly.  This method updates these bands in the _new_ report as necessary.
	PROTECTED PROCEDURE AdjustBands
		LOCAL nOffset, nSelect, nVertStart, nNewHeight

		nSelect = SELECT()
		SELECT NewRpt

		IF THIS.nLayout == RPT_LAYHORZ
			* Determine which band the labels are in, and increase the width
			* of that band accordingly:
			*
			*  Multiple Column Reports -> Column Header
			*  One-To-Many Reports  -> Group Header
			*  Any other case       -> Page Header
			*
			DO CASE
			CASE THIS.nColumns > 1
				LOCATE FOR OBJTYPE=OT_BAND .AND. OBJCODE=OC_COLHEAD
			CASE THIS.lOneToMany
				LOCATE FOR OBJTYPE=OT_BAND .AND. OBJCODE=OC_GRPHEAD
			OTHERWISE
				LOCATE FOR OBJTYPE=OT_BAND .AND. OBJCODE=OC_PGHEAD
			ENDCASE

			IF !ISNULL(THIS.oRptLabel)
				m.nOffset = (THIS.oRptLabel.Height + IIF(_mac, RPT_PTPERPIX_MAC, RPT_PTPERPIX) + 1.0) * (THIS.nDetailRows - 1)
				REPLACE Height WITH Height + m.nOffset
			ENDIF


			* Adjust the detail band
			LOCATE FOR ObjType=OT_BAND .AND. ObjCode=OC_DETAIL
			REPLACE Height WITH Height + THIS.nDetailOffset


			* Adjust the vertical positions of the objects within the detail band
			* Specifically, move all lines, boxes, gets, etc which fall below the first
			* label down by nLblOffset. Increase the height of boxes which fall in
			* the detail band by the same amount that the detail band grew.
			IF THIS.lOneToMany
				m.nVertStart = THIS.nTitleBandHt + THIS.nPageHdrBandHt + THIS.nColOffset - WZ_BASEBAND + ;
					THIS.n1MOffset + THIS.nGrpHdrBandHt
			ELSE
				m.nVertStart = THIS.nTitleBandHt + THIS.nPageHdrBandHt + THIS.nColOffset - WZ_BASEBAND
			ENDIF

			SCAN FOR INLIST(ObjType, OT_LINE, OT_BOX, OT_GET, OT_PICTURE) .AND. ;
					VPos >= m.nVertStart
				REPLACE VPOS WITH VPOS + THIS.nLblOffset - THIS.n1MOffset

				IF INLIST(ObjType, OT_BOX, OT_LINE) .AND. VPos > THIS.nTitleBandHt + ;
						THIS.nPageHdrBandHt + THIS.nLblOffset + THIS.nGrpHOffset - RPT_CUSHION

					IF !(objType == OT_LINE .AND. Width > Height)
						REPLACE HEIGHT WITH HEIGHT + THIS.nDetailOffset
					ENDIF
				ENDIF
			ENDSCAN


			* Adjust vertical positions of our subtotals text & actual subtotal fields
			* in the group footers
			* Note: group reports must be horizontal layout, so we don't have to
			*     worry about this in vertical layout reports
			IF THIS.lGroupRpt .AND. (THIS.lSubTotals .OR. THIS.lGrandTotals)
				SCAN FOR (TotalType > I_TOTAL_NONE .OR. SUBTOT_LOC$Expr .OR. GRANDTOT_LOC$Expr).AND. VPos > m.nVertStart
					REPLACE VPOS WITH VPOS + THIS.nLblOffset + THIS.nDetailOffset
				ENDSCAN
			ENDIF

		ELSE

			* Adjust the detail band for vertical report
			LOCATE FOR ObjType = OT_BAND .AND. ObjCode = OC_DETAIL
			THIS.nDetailOffset = THIS.nDetailOffset + ;
				(THIS.nFldVPos - THIS.nTitleBandHt - THIS.nPageHdrBandHt)
			m.nNewHeight = THIS.nDetailOffset - Height
			REPLACE Height WITH THIS.nDetailOffset

			THIS.nDetailOffset = m.nNewHeight

			* Adjust the height of boxes and vertical lines
			m.nVertStart = THIS.nTitleBandHt + THIS.nPageHdrBandHt - WZ_BASEBAND/2
			SCAN FOR INLIST(ObjType, OT_LINE, OT_BOX) .AND. ;
					VPos > m.nVertStart
				IF !(objType == OT_LINE .AND. Width > Height)
					REPLACE HEIGHT WITH (Height + THIS.nDetailOffset)
				ENDIF
			ENDSCAN


		ENDIF

		SELECT (nSelect)
	ENDPROC				&& AdjustBands




	*>> InsSetup: Insert setup & header information
	* Abstract:
	*   Insert into the new report .FRX the setup record.
	*
	*
	PROTECTED PROCEDURE InsSetup
		LOCAL nColumns, cTempFile, nSelect

		m.nSelect = SELECT()

		THIS.oRptHeader.Environ = THIS.lSaveEnviron
		THIS.oRptHeader.Tag    = ""
		THIS.oRptHeader.Tag2   = ""

		*- make sure we default to 1 copy
		THIS.oRptHeader.Expr   =	"ORIENTATION="+IIF(THIS.lLandscape, "1", "0") + NEWLINE + ;
			"COPIES=1"

		m.nColumns = THIS.nColumns
		IF nColumns > 1
			WITH THIS.oRptHeader
				.VPos = m.nColumns     && number of columns
				.Bottom = .F.
				.Width   = THIS.nColWidth  && column width
			ENDWITH
		ENDIF

		IF THIS.nWizAction == GO_PREVIEW
			* This is a special flag which forces the display of
			* "<untitled>" or whatever in the Preview Window title.  If
			* it weren't for this, the Preview would display our temp filename
			* as the window title.
			THIS.oRptHeader.Unique = .T.
		ENDIF

		THIS.OInsert(THIS.oRptHeader, "NewRpt")

	ENDPROC



	*>> SetPicture
	PROTECTED FUNCTION SetPicture
		LPARAMETERS cSetPic, cPicture

		IF TYPE("m.cPicture") <> "C"
			m.cPicture = ""
		ENDIF
		DO CASE
		CASE "@"$m.cPicture .AND. "@"$m.cSetPic
			m.cPicture = STRTRAN(m.cPicture, "@", m.cSetPic)
		CASE "@"$m.cSetPic
			m.cPicture = RTRIM(m.cSetPic + " " + m.cPicture)
		CASE "@"$m.cPicture
			m.cPicture = m.cPicture + " " + m.cSetPic
		OTHERWISE
			m.cPicture = m.cPicture + m.cSetPic
		ENDCASE

		RETURN m.cPicture
	ENDFUNC

	*>> GetPicture:
	PROTECTED FUNCTION GetPicture
		LPARAMETERS cDataType, nLength, nDec, cExpr
		LOCAL cPicture, cFormat, cInputMask
		STORE "" TO cPicture, cFormat, cInputMask
		IF VARTYPE(cExpr)#"C"
			cExpr = ""
		ENDIF
		*- if we are using a DBC, and the user has said to use format/inputmask info from the DBC
		*- go ahead and use that
		IF !EMPTY(cExpr) AND !EMPTY(THIS.cDBCAlias) AND;
		 THIS.lUseMask AND CURSORGETPROP("sourcetype",THIS.cWizAlias)=3
			cFormat = DBGETPROP(IIF('.' $ m.cExpr, m.cExpr, THIS.cDBCTable + '.' + m.cExpr),"FIELD","FORMAT")
			cInputMask = DBGETPROP(IIF('.' $ m.cExpr, m.cExpr, THIS.cDBCTable + '.' + m.cExpr),"FIELD","INPUTMASK")
		ENDIF
		
		DO CASE
			CASE !EMPTY(m.cFormat) OR !EMPTY(m.cInputMask)
				m.cPicture = ["] + IIF(!EMPTY(m.cFormat), '@' + TRIM(m.cFormat) + " ","") + TRIM(m.cInputMask) + ["]
				
			CASE m.cDataType = DT_CHAR
				m.cPicture = ""

			CASE m.cDataType = DT_VARCHAR
				m.cPicture = ""

			CASE m.cDataType = DT_VARBINARY
				m.cPicture = ""

			CASE m.cDataType = DT_LOGIC
				m.cPicture = ["Y"]

			CASE m.cDataType = DT_MONEY
				m.cPicture = ["99,999,999.99"]

			CASE m.cDataType = DT_INT  && Integer
				m.cPicture = ["9999999999"]

			CASE INLIST(m.cDataType, DT_NUM, DT_FLOAT, DT_DOUBLE)   && Number
				IF m.nDec = 0
					m.cPicture = ["] + THIS.GetNumStr(m.nLength) + ["]
				ELSE
					m.cPicture = ["] + THIS.GetNumStr(m.nLength - 1;
						- m.nDec) + "." + ;
						+ REPL("9", m.nDec) + ["]
				ENDIF
			OTHERWISE
				m.cPicture = ""
		ENDCASE

		RETURN m.cPicture
	ENDPROC

	*>> GetNumStr:
	PROTECTED FUNCTION GetNumStr
		LPARAMETER nNumChars
		LOCAL cNumStr, z
		cNumStr = ""
		FOR z = 1 TO nNumChars
			IF m.z > 3 .AND. MOD(m.z, 3) = 1
				m.cNumStr = "9," + m.cNumStr
			ELSE
				m.cNumStr = "9" + m.cNumStr
			ENDIF
		ENDFOR
		RETURN m.cNumStr
	ENDPROC



	*>> SetupRpt: Setup report defaults & options
	* Abstract:
	*   This method sets options which are derived directly from
	*   values entered in the UI, and thus can't be computed in the INIT
	*   method -- things such as page width based upon paper size &
	*   orientation & margins, style defaults, etc
	*
	PROTECTED FUNCTION SetupRpt
		LOCAL i, j, nSelect, lInUse, wzGrpField, cError, nMargin, nColSeparation
		LOCAL nPrtInfo, nSelect

		m.nSelect = SELECT()

		IF EMPTY(THIS.cStyleFile)
			THIS.Alert(ERR_NOSTYLE_LOC)
			THIS.haderror = .T.
			RETURN .F.
		ENDIF


		* Clear variables
		THIS.nTotalCnt = 0
		THIS.nCountCnt = 0
		THIS.nAvgCnt = 0
		THIS.nMaxCnt = 0
		THIS.nMinCnt = 0

		THIS.nPageWidth  = 0     && actual page width -- ie 80000 for portrait, 11000 for landscape
		THIS.nPrintWidth = 0     && Print width of a page, after taking into account the margins
		THIS.nColWidth   = 0     && Print width of a column (including for single-column reports)
		THIS.nDetailRows = 1     && number of detail rows to accomodate lots of fields
		THIS.nColOffset  = 0     && Vertical size of the column header band
		THIS.nFldOffset  = 0     && Vertical size of the detail band when rows > 1
		THIS.nLblOffset  = 0     && Vertical size of the page header band when rows > 1
		THIS.nGrpHOffset = 0     && Vertical size of the group header bands
		THIS.nGrpFOffset = 0     && Vertical size of the group footer bands
		THIS.nDetailOffset = 0   && Length that detail band increases by adding
&& general fields, additional field rows, etc
		THIS.n1MOffset   = 0     && Length that group header band increases in One-to-Many report
		THIS.nGrpCnt    = 0      && number of groups (0 for a non-group report)
		THIS.nTitleBandHt   = 0
		THIS.nPageHdrBandHt = 0
		THIS.nPageFtrBandHt = 0
		THIS.nGrpHdrBandHt  = 0
		THIS.nGrpFtrBandHt  = 0
		THIS.nColHdrBandHt  = 0
		THIS.nColFtrBandHt  = 0
		THIS.nSummaryBandHt = 0
		THIS.nDetailBandHt  = 0
		THIS.nGrpHdrRealHt  = 0
		THIS.nGrpFtrRealHt  = 0

		THIS.oBand      = .NULL.
		THIS.oRptField  = .NULL. && sample field
		THIS.oRptMemo   = .NULL. && sample memo field
		THIS.oRptGeneral   = .NULL. && sample general field
		THIS.oRptField2 = .NULL. && secondary sample field
		THIS.oRptLabel  = .NULL. && sample label
		THIS.oRptGrpField = .NULL.  && sample group field
		THIS.oParentLabel = .NULL.  && sample parent label
		THIS.oParentField = .NULL.  && sample parent field
		THIS.oParentField2 = .NULL. && second sample parent field (for field spacing)
		THIS.oRptHeader = .NULL.
		THIS.oDetailBand   = .NULL.
		THIS.oRptDataEnv   = .NULL.
		THIS.oRptVDivider = .NULL.
		THIS.oRptHDivider = .NULL.

		THIS.nFldHPos    = 0     && Starting field horizontal position
		THIS.nFldVPos    = 0     && Starting field vertical position
		THIS.nLblHPos    = 0     && Starting label horizontal position
		THIS.nLblVPos    = 0     && Starting label vertical position
		THIS.nGrpHdrHt   = 0     && height of group & column headers in style file
		THIS.nGrpFtrHt   = 0     && height of group & column footers in style file
		THIS.n1MFldHPos  = 0     && Starting parent field horizontal position
		THIS.n1MFldVPos  = 0     && Starting parent field vertical position
		THIS.n1MLblVPos  = 0     && Starting parent label vertical position
		THIS.n1MLblHPos  = 0     && Starting parent label vertical position

		THIS.nVertSpacing  = 0   && space between fields in vertical report
		THIS.nHorzSpacing  = 0   && space between fields in horizontal report
		THIS.nLblSpacing   = 0   && space between labels & fields (vert reports only)

		THIS.nIndent    = 1500   && amount to indent when we go to multiple rows
		THIS.nSubtotWidth = 0

		IF ISNULL(THIS.nColumns)
			THIS.nColumns = 1
		ENDIF

		* Set default options for different reports
		* Certain options just don't go together, so make sure they're not
		* set "together"
		DO CASE
		CASE THIS.lOneToMany
			THIS.nLayout     = RPT_LAYHORZ
			THIS.nColumns    = 1
		CASE THIS.lGroupRpt
			THIS.nLayout     = RPT_LAYHORZ
			THIS.nColumns    = 1
			THIS.cMainKey    = ""
			THIS.cRelatedKey  = ""
		OTHERWISE
			IF THIS.nColumns < 1
				THIS.nColumns = 1
			ENDIF
			IF THIS.nColumns > 3
				THIS.nColumns = 3
			ENDIF
			THIS.lSubTotals   = .F.
			THIS.lGrandTotals = .F.
			THIS.cMainKey    = ""
			THIS.cRelatedKey  = ""
		ENDCASE


		m.cError = THIS.ReadStyle(THIS.cStyleFile)
		IF !EMPTY(m.cError)
			THIS.Alert(m.cError)
			THIS.haderror = .T.
			RETURN .F.
		ENDIF

		SELECT StyleFile

		IF USED("NewRpt")
			USE IN NewRpt
		ENDIF
		IF AT(".", THIS.cOutFile) = 0
			THIS.cOutFile = THIS.cOutFile + ".FRX"
		ENDIF

		THIS.cOutFile = FULLPATH(THIS.cOutFile)

		COPY STRUCTURE TO (THIS.cOutFile)
		USE (THIS.cOutFile) EXCLUSIVE ALIAS NewRpt IN 0

		* ---------------------------------
		* Setup for all Report Wizard types
		* ---------------------------------
		IF !EMPTY(THIS.cWizAlias)
			m.lInUse = USED(THIS.cWizAlias)
			IF m.lInUse
				SELECT (THIS.cWizAlias)
			ELSE
				SELECT 0
				USE (THIS.cWizAlias)
			ENDIF
			=AFIELDS(THIS.aWizFList)

			IF !(m.lInUse)
				USE
			ENDIF
		ENDIF

		#ifdef NOPE
		* If the print width property wasn't set by the user, then we'll
		* set it ourselves (preferable) based upon the paper size & orientation
		IF TYPE("THIS.nPageWidth") <> "N" .OR. THIS.nPageWidth = 0
			* Determine actual width based on paper size & orientation & margins
			FOR m.i = 1 TO ALEN(THIS.aPaperSizes, 1)
				IF UPPER(THIS.cPaperSize) = UPPER(THIS.aPaperSizes[m.i, 1])
					* Landscape or Portrait?
					IF THIS.lLandscape
						THIS.nPageWidth = THIS.aPaperSizes[m.i, 3]
					ELSE
						THIS.nPageWidth = THIS.aPaperSizes[m.i, 2]
					ENDIF
					EXIT
				ENDIF
			ENDFOR		&& i = 1 TO ALEN(aPaperSizes)

		ENDIF
	#endif

	m.nPrtInfo = PRTPAPER_LETTER
	THIS.SetErrorOff = .T.

	m.nPrtInfo = PRTINFO(PRT_PAPERSIZE)
	THIS.SetErrorOff = .F.
	m.nSelect = SELECT()

	USE RptPaper AGAIN ALIAS WzRptPaper IN 0
	SELECT WzRptPaper
	LOCATE FOR WzRptPaper.PaperNo = m.nPrtInfo
	IF !FOUND()
		GOTO 1
	ENDIF
	IF THIS.lLandscape
		THIS.nPageWidth = WzRptPaper.Landscape * 10000
	ELSE
		THIS.nPageWidth = WzRptPaper.Portrait * 10000
	ENDIF
	IF WzRptPaper.Metric
		THIS.nPageWidth = THIS.nPageWidth * .039
	ENDIF

	USE

	SELECT (m.nSelect)


	* Printable area of the page - everything but the margins
	m.nMargin = THIS.oRptHeader.HPos * 2
	m.nColSeparation = THIS.oRptHeader.Height

	THIS.nPrintWidth = THIS.nPageWidth - m.nMargin
	THIS.nColWidth = (THIS.nPrintWidth - m.nColSeparation * (THIS.nColumns - 1)) / THIS.nColumns


	* Set a vertical column offset to handle a column band (if any)
	THIS.nColOffset = IIF(THIS.nColumns > 1, WZ_BASEBAND, 0)


	THIS.nGrpCnt = 0

	* ----------------------------------
	* Do setup specific to group reports
	* ----------------------------------
	IF THIS.lGroupRpt
		THIS.nLayout = RPT_LAYHORZ  && force group reports to be horizontal
	ENDIF
	IF THIS.lGroupRpt .AND. !EMPTY(THIS.aWizGroups[1, GRP_FIELD]) AND !THIS.lOneToMany

		IF !USED("WizMod")
			SELECT 0
			USE WizMod ALIAS WizMod
		ENDIF

		THIS.nGrpCnt = ALEN(THIS.aWizGroups, 1)
		* Setup for groups
		FOR m.i = THIS.nGrpCnt TO 1 STEP -1
			IF EMPTY(THIS.aWizGroups[m.i, GRP_FIELD])
				LOOP
			ENDIF

			* Create an array of the group expressions & width templates
			* ie LEFT(Team, 1) if we're grouping on First Character of Team Name
			m.wzGrpField = UPPER(RTRIM(THIS.aWizGroups[m.i, GRP_FIELD]))
			THIS.aWizGrpExpr[m.i, MOD_GRPEXPR] = EVAL(LOOKUP(WizMod.GrpExpr, ;
				THIS.aWizGroups[m.i, GRP_MODCODE], ;
				WizMod.ModCode))

			THIS.aWizGrpExpr[m.i, MOD_RPTEXPR] = EVAL(LOOKUP(WizMod.RptExpr, ;
				THIS.aWizGroups[m.i, GRP_MODCODE], ;
				WizMod.ModCode))

			THIS.aWizGrpExpr[m.i, MOD_CDXEXPR] = EVAL(LOOKUP(WizMod.CDXExpr, ;
				THIS.aWizGroups[m.i, GRP_MODCODE], ;
				WizMod.ModCode))


			THIS.aWizGrpExpr[m.i, MOD_TXTWID] = RTRIM(LOOKUP(WizMod.TxtWid, ;
				THIS.aWizGroups[m.i, GRP_MODCODE], ;
				WizMod.ModCode))


			*- Add grouped fields to the beginning of the sort list
			IF !EMPTY(THIS.aWizSorts[1, 1])
				DIMENSION THIS.aWizSorts[ALEN(THIS.aWizSorts, 1) + 1, 1]
				=AINS(THIS.aWizSorts, 1)
			ENDIF

			IF EMPTY(THIS.aWizGrpExpr[m.i, MOD_CDXEXPR])
				THIS.aWizSorts[1, 1] = THIS.aWizGroups[m.i, GRP_FIELD]
			ELSE
				THIS.aWizSorts[1, 1] = THIS.aWizGrpExpr[m.i, MOD_CDXEXPR]
			ENDIF


			*- Move grouped fields to the left side of the report
			FOR m.j = 1 TO ALEN(THIS.aWizFields, 1)
				IF UPPER(THIS.aWizFields[m.j, 1]) == UPPER(THIS.aWizGroups[m.i, GRP_FIELD])
					EXIT
				ENDIF
			ENDFOR
			=ADEL(THIS.aWizFields, m.j)

		ENDFOR

		FOR m.i = THIS.nGrpCnt TO 1 STEP -1
			IF EMPTY(THIS.aWizGroups[m.i, GRP_FIELD])
				LOOP
			ENDIF

			=AINS(THIS.aWizFields, 1)
			THIS.aWizFields[1, 1] = THIS.aWizGroups[m.i, GRP_FIELD]

		ENDFOR
	ENDIF


	* ----------------------------------------
	* Do setup specific to One-to-Many Reports
	* ----------------------------------------
	IF THIS.lOneToMany

		* Create field list for parent table of one-to-many report
		m.lInUse = USED(THIS.cParentAlias)
		IF m.lInUse
			SELECT (THIS.cParentAlias)
		ELSE
			SELECT 0
			USE (THIS.cParentAlias) SHARED
		ENDIF
		=AFIELDS(THIS.aParentFList)

		IF !(m.lInUse)
			USE
		ENDIF


		* Pretend it's a one-level group report, since we put the
		* parent information in a group band.
		THIS.nGrpCnt = 1
		DIMENSION THIS.aWizGroups[1, 4]
		THIS.aWizGroups[1, 1] = THIS.cMainKey
		THIS.aWizGroups[1, 2] = "C0"
		THIS.aWizGroups[1, 3] = ""  && was "entire field"
		THIS.aWizGroups[1, 4] = 0


		* Create labels for the parents (take from DBC Caption property if we can)
		THIS.SetLabels("aParentFields", "aParentLabels", THIS.cParentDBCAlias, ;
			THIS.cParentDBCTable, THIS.oParentLabel.Expr, C_1MLBL)

	ENDIF

	* Set field captions
	THIS.SetLabels("aWizFields", "aWizLabels", THIS.cDBCAlias, THIS.cDBCTable, THIS.oRptLabel.Expr)


	SELECT (m.nSelect)

	RETURN .T.
ENDFUNC



*>> Destroy
	PROCEDURE Destroy
		MainEngine::Destroy()
		IF USED("NewRpt")
			USE IN NewRpt
		ENDIF

		IF USED("WizMod")
			USE IN WizMod
		ENDIF

		IF USED("StyleFile")
			USE IN StyleFile
		ENDIF

	ENDPROC


	*>> ReadStyle: read global style properties in from Report Style file
	* Abstract:
	*   This method reads in the style definition, such as where labels & fields
	*   go in the bands, what their fonts & sizes are, etc.  This does not
	*   read in the band information, as that is done in InsBands().
	*
	FUNCTION ReadStyle
		LPARAMETER cStyleFile

		LOCAL nSelect, cError

		m.cError = ""

		* Open up the report style file
		m.nSelect = SELECT()
		IF AT(".", m.cStyleFile) = 0
			m.cStyleFile = m.cStyleFile + ".FRX"
		ENDIF
		SELECT 0

		*- Set up for error handling
		THIS.SetErrorOff = .T.
		IF !FILE(m.cStyleFile)
			m.cStyleFile = EVAL(m.cStyleFile)
		ENDIF
		USE (m.cStyleFile) AGAIN ALIAS StyleFile SHARED
		THIS.SetErrorOff = .F.
		IF EMPTY(ALIAS()) && file did not get opened for some reason
			m.cError = ERR_NOFILE_LOC + " " + m.cStyleFile
			SELECT (m.nSelect)
			RETURN m.cError
		ENDIF



		* Scan thru the style file looking for the records we're interested in, and scatter
		* those records to objects
		SCAN FOR TRIM(platform) = THIS.cPlatform
			DO CASE
			CASE objtype = OT_HEADER
				* Report Header
				THIS.AddStyleRec("THIS.oRptHeader", "HEADER")

			CASE objtype = OT_DATAENV
				* Data Environment environment info
				THIS.AddStyleRec("THIS.oRptDataEnv", "ENVIRONMENT")

			CASE objtype = OT_BAND .AND. INLIST(objcode, OC_GRPHEAD, OC_COLHEAD)
				THIS.nGrpHdrHt = THIS.nGrpHdrHt + Height + WZ_BASEBAND

			CASE objtype = OT_BAND .AND. INLIST(objcode, OC_GRPFOOT, OC_COLFOOT)
				THIS.nGrpFtrHt = THIS.nGrpFtrHt + Height + WZ_BASEBAND

			CASE C_MEMO$UPPER(expr)
				* Get memo info
				THIS.AddStyleRec("THIS.oRptMemo", "FIELD")

			CASE C_GEN$UPPER(name)
				* General field info
				THIS.AddStyleRec("THIS.oRptGeneral", "FIELD")

			CASE objtype=OT_GET AND C_FLD$UPPER(Expr)
				* Normal field info
				THIS.AddStyleRec("THIS.oRptField", "FIELD")
				THIS.AddStyleRec("THIS.oRptField2", "FIELD")
				IF ISNULL(THIS.oRptGrpField)
					THIS.AddStyleRec("THIS.oRptGrpField", "FIELD")
					THIS.oRptGrpField.VPos = 0
				ENDIF

			CASE objtype=OT_GET AND C_1MFLD$UPPER(Expr)
				* Normal field info
				IF ISNULL(THIS.oParentField)
					THIS.AddStyleRec("THIS.oParentField", "FIELD")
				ELSE
					THIS.AddStyleRec("THIS.oParentField2", "FIELD")
				ENDIF

			CASE objtype=OT_GET AND C_GRP$UPPER(expr)
				* Group field info
				THIS.AddStyleRec("THIS.oRptGrpField", "FIELD")

			CASE C_LBL$UPPER(Expr) .AND. (objtype == OT_GET .OR. objtype == OT_LABEL)
				* Label info
				THIS.AddStyleRec("THIS.oRptLabel", "LABEL")

			CASE C_1MLBL$UPPER(Expr) .AND. (objtype == OT_GET .OR. objtype == OT_LABEL)
				* Label info for One-to-Many report parents
				THIS.AddStyleRec("THIS.oParentLabel", "LABEL")

			CASE C_VDIVIDER$UPPER(comment)
				* Vertical divider

				DO CASE
				CASE INLIST(ObjType, OT_BOX, OT_LINE)
					THIS.AddStyleRec("THIS.oRptVDivider", "LINE")
				CASE ObjType = OT_LABEL
					THIS.AddStyleRec("THIS.oRptVDivider", "LABEL")
				CASE ObjType = OT_GET
					THIS.AddStyleRec("THIS.oRptVDivider", "FIELD")
				ENDCASE

			CASE C_HDIVIDER$UPPER(comment)
				* Horizontal divider
				DO CASE
				CASE INLIST(ObjType, OT_BOX, OT_LINE)
					THIS.AddStyleRec("THIS.oRptHDivider", "LINE")
				CASE ObjType = OT_LABEL
					THIS.AddStyleRec("THIS.oRptHDivider", "LABEL")
				CASE ObjType = OT_GET
					THIS.AddStyleRec("THIS.oRptHDivider", "FIELD")
				ENDCASE
			ENDCASE

		ENDSCAN

		IF ISNULL(OT_DATAENV)
			GO TOP
			THIS.AddStyleRec("THIS.oRptDataEnv", "ENVIRONMENT")
		ENDIF

		SELECT (m.nSelect)

		* Error handling: if one of the required components of style file is not found,
		* then exit with an error
		DO CASE
		CASE ISNULL(THIS.oRptHeader)
			RETURN ERR_NOHEADER_LOC
		CASE ISNULL(THIS.oRptMemo)
			RETURN ERR_NOMEMO_LOC
		CASE ISNULL(THIS.oRptGeneral)
			RETURN ERR_NOGENERAL_LOC
		CASE ISNULL(THIS.oRptField)
			RETURN ERR_NOFIELD_LOC
		ENDCASE


		* Determine spacing between records/fields
		* The conditional code handles the fact that we don't
		* care whether the field or the memo types are found first in
		* the style file.

		* Space between fields in horizontal report
		THIS.nHorzSpacing = ABS(THIS.oRptMemo.HPOS - THIS.oRptField.HPOS)
		IF THIS.oRptMemo.HPOS > THIS.oRptField.HPOS
			THIS.nHorzSpacing = THIS.nHorzSpacing - THIS.oRptField.Width
		ELSE
			THIS.nHorzSpacing = THIS.nHorzSpacing - THIS.oRptMemo.Width
		ENDIF

		* Space between fields in vertical report
		THIS.nVertSpacing = ABS(THIS.oRptMemo.VPOS - THIS.oRptField.VPOS)
		IF THIS.oRptMemo.VPOS > THIS.oRptField.VPOS
			THIS.nVertSpacing = THIS.nVertSpacing - THIS.oRptField.Height
		ELSE
			THIS.nVertSpacing = THIS.nVertSpacing - THIS.oRptMemo.Height
		ENDIF

		* Space between labels & fields (for vertical reports)
		IF ISNULL(THIS.oRptLabel)
			THIS.nLblSpacing = 0
			THIS.nLblVPos = 0
			THIS.nLblHPos = THIS.oRptField.HPos
		ELSE
			THIS.nLblSpacing = THIS.oRptField.HPOS - THIS.oRptLabel.HPos - THIS.oRptLabel.Width

			* First label coordinates
			THIS.nLblVPos = THIS.oRptLabel.VPos
			THIS.nLblHPos = THIS.oRptLabel.HPos
		ENDIF

		* First field coordinates
		THIS.nFldVPos = THIS.oRptField.VPos - THIS.nGrpHdrHt
		THIS.nFldHPos = THIS.oRptField.HPos

		* One to many properties
		IF THIS.lOneToMany
			THIS.nLblSpacing = THIS.oParentField.HPOS - THIS.oParentLabel.HPos - THIS.oParentLabel.Width
			THIS.nVertSpacing = MAX(THIS.oParentField2.VPOS - (THIS.oParentField.VPOS + THIS.oParentField.Height), 1)

			* First field coordinates
			THIS.n1MFldVPos = THIS.oParentField.VPos - THIS.nGrpHdrHt
			THIS.n1MFldHPos = THIS.oParentField.HPos

			* First label coordinates
			THIS.n1MLblVPos = THIS.oParentLabel.VPos
			THIS.n1MLblHPos = THIS.oParentLabel.HPos


		ENDIF


		SELECT (m.nSelect)


		* Verify that the values we got from the style are valid
		IF THIS.nLblVPos < 0 .OR. THIS.nLblHpos < 0 .OR. THIS.nFldVPos < 0 .OR. THIS.nFldHPos < 0
			m.cError = ERR_NEGATIVE_LOC
		ENDIF

		RETURN m.cError
	ENDFUNC


	*----------------------------------
	PROCEDURE CompileFRX
	*----------------------------------
		*- take code from TAG field of DataEnvironment record, and 
		*- compile it as an FXP, then append it into the TAG2 field
		*- There is no "COMPILE REPORT" command
		LOCAL cTmpFile

		LOCATE FOR objtype = OT_DATAENV
		IF !FOUND()
			RETURN
		ENDIF
		
		cTmpFile = SYS(3) + ".PRG"

		COPY MEMO tag TO (cTmpFile)
		COMPILE (cTmpFile)
		IF !_mac
			APPEND MEMO tag2 FROM (THIS.ForceExt(cTmpFile,"FXP"))
		ELSE
			LOCAL iFH, iBuffer
			iFH = FOPEN(THIS.ForceExt(cTmpFile,"FXP"))
			IF iFH # -1
				DO WHILE !FEOF(iFH)
					iBuffer = FREAD(iFH, N_BUFFSZ)
					REPLACE tag2 WITH iBuffer ADDITIVE
				ENDDO
				=FCLOSE(iFH)
			ELSE
				*- some kind of error
			ENDIF
		ENDIF
		ERASE (cTmpFile)
		ERASE (THIS.ForceExt(cTmpFile,"FXP"))

		RETURN

	ENDPROC		&& CompileFRX



	*>> Process: Main processing engine of Report Wizard
	PROCEDURE Process
		LOCAL nSelect, cTempFile, cSafety, i

		m.nSelect = SELECT()
		m.cSafety = SET("SAFETY")
		SET SAFETY OFF

		IF EMPTY(THIS.cWizAlias)
			THIS.cWizAlias = THIS.aWizTables[1, 1]
		ENDIF
		IF EMPTY(THIS.aWizTables[1, 1])
			THIS.aWizTables[1, 1] = THIS.cWizAlias
		ENDIF

		THIS.oRptVDivider = .F.
		THIS.oRptVDivider = .NULL. && we won't know what type this is until
									&& we find the record in the style file
		THIS.oRptHDivider = .F.
		THIS.oRptHDivider = .NULL.

		DO CASE
		CASE THIS.nWizAction = GO_PREVIEW
			* If we're doing a preview, then set up a temporary output report
			m.cTempFile = FULLPATH(SYS(2023) + "\" + SYS(3))
			THIS.cOutFile = m.cTempFile + ".FRX"

		CASE EMPTY(THIS.cOutFile)
			THIS.cOutFile = THIS.aWizTables[1, 1]
			IF !THIS.SaveOutFile(SAVEAS_LOC, THIS.cOutFile, "FRX")
				RETURN
			ENDIF
			IF AT(".", THIS.cOutFile) = 0
				THIS.cOutFile = THIS.cOutFile + ".FRX"
			ENDIF

		ENDCASE

		DO CASE
		CASE THIS.lOneToMany
			THIS.SetTherm(THERM_MSG_LOC, 7 + ALEN(THIS.aWizFields, 1) + ALEN(THIS.aParentFields, 1), 0)
		CASE THIS.lGroupRpt
			THIS.SetTherm(THERM_MSG_LOC, 6 + ALEN(THIS.aWizFields, 1), 0)
		OTHERWISE
			THIS.SetTherm(THERM_MSG_LOC, 6 + ALEN(THIS.aWizFields, 1), 0)
		ENDCASE
		THIS.DoTherm(0, THERM_STYLE_LOC)

		IF THIS.SetupRpt()
			* Show thermometer
			THIS.DoTherm(0, THERM_CREATE_LOC)

			THIS.InsSetup()
			THIS.InsBands()
			THIS.InsTitle()
			THIS.InsPrePage()

			THIS.InsPreGroup()    && insert lines & boxes into the group headers

			IF THIS.lOneToMany
				THIS.InsOneToMany()
				THIS.Adjust1MBands(THIS.n1MOffset, .F.)
				THIS.InsPageInfo(THIS.oParentField2.VPos, ;
					THIS.nTitleBandHt + THIS.nPageHdrBandHt + THIS.nColHdrBandHt + ;
					THIS.nGrpHdrBandHt, THIS.n1MOffset, THIS.nColWidth, 0)

			ENDIF

			* Insert lines/boxes into the detail band
			THIS.InsElements(THIS.nColOffset + THIS.nLblOffset + THIS.nGrpHOffset - THIS.nGrpHdrHt + THIS.n1MOffset)
			THIS.InsDetail()


			THIS.DoTherm(0, THERM_FORMAT_LOC)

			THIS.AdjustBands()

			IF THIS.lOneToMany
				THIS.Adjust1MBands(THIS.nLblOffset - THIS.n1MOffset, .T.)
			ENDIF

			THIS.InsTotals()   && Add subtotals/totals
			THIS.InsPostGroup()  && Insert lines/boxes in the group footer template
			THIS.InsPostPage()
			THIS.InsPageFtr()
			THIS.InsOtherInfo()
			THIS.InsDataEnv(THIS.oRptDataEnv)
			IF THIS.lPercentOfTotal
				*- we added some code, so compile it
				SELECT NewRpt
				THIS.CompileFRX
			ENDIF

			IF USED("StyleFile")
				USE IN StyleFile
			ENDIF

			IF USED("WizMod")
				USE IN WizMod
			ENDIF

			IF USED("NewRpt")
				USE IN NewRpt
			ENDIF

			* Complete and release thermometer
			THIS.DoTherm(-1)

			DO CASE
			CASE THIS.nWizAction = GO_PREVIEW
				SELECT (THIS.cWizAlias)
				SET ORDER TO

				REPORT FORM (THIS.cOutFile) PREVIEW

				IF !EMPTY(SYS(2000, m.cTempFile + ".FRX"))
					DELETE FILE (m.cTempFile + ".FRX")
				ENDIF
				IF !EMPTY(SYS(2000, m.cTempFile + ".FRT"))
					DELETE FILE (m.cTempFile + ".FRT")
				ENDIF
			CASE THIS.nWizAction = GO_MODIFY
				cNewFile = THIS.cOutFile
				_SHELL = [MODIFY REPORT "&cNewFile" NOWAIT]

			CASE THIS.nWizAction = GO_RUN
				cNewFile = THIS.cOutFile
				_SHELL = [REPORT FORM "&cNewFile" TO PRINT NOCONSOLE]

			ENDCASE

		ELSE
			THIS.DoTherm(-1)
			THIS.cOutFile = ""
		ENDIF


		SET SAFETY &cSafety
		SELECT (m.nSelect)


	ENDPROC

ENDDEFINE


*--------------------------------------------------------------------
*>> Class Definition: LabelEngine
*--------------------------------------------------------------------
DEFINE CLASS LabelEngine AS MainEngine
	PROTECTED cLblName, nLblWidth, nLblHeight, nLblTopMargin, nLblSpacing
	PROTECTED nLblLeftMargin

	DIMENSION aLblLines[1, 1]
	aLblLines = ""

	cLblData    = ""           && character data which defines label spec
	lMetric     = .F.          && TRUE for metric ruler, FALSE otherwise

	nLblWidth      = 0         && label width in pixels (ie 40000 = 4")
	nLblHeight     = 0         && label height
	nLblTopMargin  = 0         && top margin (ie page header height)
	nLblSpacing    = 0         && space between columns
	nLblLeftMargin = 0         && left margin

	*- font characteristics
	cFontName = ""
	nFontSize = 0
	cFontStyle = ""

	*-------------------------------------------------------
	* All of the properties below deal with the style file
	PROTECTED oRptHeader, oRptDataEnv, oRptField
	PROTECTED oPageHdrBand, oDetailBand, oColHdrBand, oColFtrBand, oPageFtrBand

	oRptHeader   = .NULL.
	oRptDataEnv  = .NULL.
	oRptField    = .NULL.
	oPageHdrBand = .NULL.
	oDetailBand  = .NULL.
	oColHdrBand  = .NULL.
	oColFtrBand  = .NULL.
	oPageFtrBand = .NULL.
	*-------------------------------------------------------



	*>> Init: Initialization
	PROCEDURE Init2
		MainEngine::Init2()
	ENDPROC


	*>> AutoReport: Generate auto labels
	* Abstract:
	*   Creates a label
	*>> AutoReport: Generate auto report
	* Abstract:
	*   Creates a vertical-layout report using _ALL_ the field in the current table.
	PROCEDURE AutoReport
		PARAMETER oSettings
		LOCAL i,aStyParms,nTotTables,aDBCTables, cGetFname
		LOCAL lHasObj

		IF PARAMETERS() = 1 AND TYPE("oSettings") = "O"
			lHasObj = .T.
		ENDIF

		IF m.lHasObj AND PEMSTATUS(m.oSettings,'cWizTable',5) AND;
				!EMPTY(oSettings.cWizTable) AND FILE(oSettings.cWizTable)
			IF PEMSTATUS(m.oSettings,'cWizAlias',5) AND !EMPTY(oSettings.cWizAlias)
				IF USED(oSettings.cWizAlias)
					SELECT (oSettings.cWizAlias)
				ELSE
					SELECT 0
					USE (oSettings.cWizTable) AGAIN  ALIAS (oSettings.cWizAlias)
				ENDIF
			ELSE
				SELECT 0
				USE (oSettings.cWizTable) AGAIN
			ENDIF
		ENDIF

		IF !EMPTY(ALIAS())  && DBF selected

			THIS.cWizAlias = ALIAS()
			THIS.cDBCName = CURSORGETPROP('Database')

			IF !EMPTY(THIS.cDBCName)
				THIS.cDBCTable = CURSORGETPROP('SourceName')	 &&DBC Table name
				IF ATC(SET("DATA"),THIS.cDBCName) = 0
					SET DATABASE TO (THIS.cDBCName)
				ENDIF
			ENDIF

			* Get field list
			DO CASE
				CASE m.lHasObj AND TYPE("m.oSettings.lBlankForm")="L" AND !EMPTY(oSettings.lBlankForm)
					DIMENSION THIS.aWizFields[1]
					THIS.aWizFields = ""
				CASE m.lHasObj AND TYPE("m.oSettings.aWizFields[1,1]")="C" AND !EMPTY(oSettings.aWizFields)
					=ACOPY(oSettings.aWizFields,THIS.aWizFields)
				OTHERWISE
					DIMENSION THIS.aWizFields[FCOUNT(),1]
					FOR i = 1 TO FCOUNT()
						THIS.aWizFields[m.i,1] = PROPER(FIELD[m.i])
					ENDFOR
			ENDCASE
			=AFIELDS(THIS.aWizFList)

			* Get sort field list
			IF m.lHasObj AND TYPE("m.oSettings.aWizSorts[1]")="C" AND !EMPTY(oSettings.aWizSorts)
				=ACOPY(oSettings.aWizSorts,THIS.aWizSorts)
			ENDIF

			*- Get sort tag
			IF m.lHasObj AND PEMSTATUS(m.oSettings,'lHasSortTag',5)
				THIS.lHasSortTag = oSettings.lHasSortTag
			ENDIF

			*- Get sort ascend
			IF m.lHasObj AND PEMSTATUS(m.oSettings,'lSortAscend',5)
				THIS.lSortAscend = oSettings.lSortAscend
			ENDIF

		ENDIF	&& DBF selected

		*- get label definition
		IF m.lHasObj AND PEMSTATUS(m.oSettings,'cLblData',5)
			IF !EMPTY(oSettings.cLblData)
				THIS.cLblData = oSettings.cLblData
			ELSE
				RETURN
			ENDIF
		ENDIF

		*- Get label lines
		IF m.lHasObj AND TYPE("m.oSettings.aLblLines[1]")="C" AND !EMPTY(oSettings.aLblLines)
			=ACOPY(oSettings.aLblLines,THIS.aLblLines)
		ENDIF

		*- Get metric
		IF m.lHasObj AND PEMSTATUS(m.oSettings,'lMetric',5)
			THIS.lMetric = oSettings.lMetric
		ENDIF

		IF m.lHasObj AND PEMSTATUS(m.oSettings,'cOutFile',5) AND !EMPTY(oSettings.cOutFile)
			THIS.cOutFile= THIS.FORCEEXT(oSettings.cOutFile,"LBX")
		ELSE
			m.cGetFname = IIF(EMPTY(ALIAS()), C_DEFAULTLABEL_LOC, THIS.ForceExt(DBF(),"LBX"))
			IF !THIS.SaveOutFile(SAVEAS_LOC, m.cGetFname, "LBX")
				* Note: SaveOutFile sets THIS.cOutFile property
				RETURN
			ENDIF
		ENDIF
		oSettings.cOutFile = THIS.cOutFile

		* Get action to perform when done processing
		IF m.lHasObj AND PEMSTATUS(m.oSettings,'nWizAction',5) AND !EMPTY(oSettings.nWizAction)
			THIS.nWizAction = oSettings.nWizAction
		ELSE
			THIS.nWizAction = GO_MODIFY
		ENDIF

		THIS.Process()

	ENDPROC


	*>> GetLblExpr: Returns expression for an entire label line
	* Abstract:
	*   For example:  (values in parens represent CHR values)
	*      (228)LAST(228)(225),(228)FIRST(228)(225)Ryan
	*                 -yields-
	*       ALLT(LAST)+","+ALLT(FIRST)+"Ryan"
	* Parameters:
	*   cLine = encoded line to parse
	*   nWidth = pass by reference -- we return the line width in this parameter
	*   cExprType = pass by reference -- we return the data type in this parameter
	*
	FUNCTION GetLblExpr
		LPARAMETERS cLine, nWidth, cExprType
		LOCAL m.i, m.j, m.cDataType, m.cExpr, m.cValue, m.nPos, m.nOccurs

		m.cExpr = ""
		m.cExprType = DT_CHAR

		m.nWidth = 0
		m.nOccurs = OCCURS(LBL_DELIMITER, m.cLine)
		FOR m.i = 1 TO m.nOccurs

			* Parse out the field name or text string
			m.nPos = AT(LBL_DELIMITER, m.cLine, m.i)
			IF m.i = m.nOccurs
				m.cValue = SUBSTR(m.cLine, m.nPos + 1)
			ELSE
				m.cValue = SUBSTR(m.cLine, m.nPos + 1, AT(LBL_DELIMITER, m.cLine, m.i + 1) - m.nPos - 1)
			ENDIF

			IF LEFT(m.cValue, 1) = LBL_TEXT
				m.cValue = SUBSTR(m.cValue, 2)
				IF RIGHT(m.cExpr, 1) = ["]
					m.cExpr = SUBSTR(m.cExpr, 1, LEN(m.cExpr) - 1) + m.cValue + ["]
				ELSE
					m.cExpr = m.cExpr + IIF(EMPTY(m.cExpr), ["], [+"]) + m.cValue + ["]
				ENDIF
				m.nWidth = m.nWidth + THIS.GetTxtWidth(m.cValue, ;
					THIS.oRptField.FontStyle, ;
					THIS.oRptField.FontFace, ;
					THIS.oRptField.FontSize)

			ELSE

				FOR m.j = 1 TO ALEN(THIS.aWizFList, 1)
					IF UPPER(THIS.aWizFList[m.j, 1]) == UPPER(m.cValue)
						EXIT
					ENDIF
				ENDFOR

				IF m.j > ALEN(THIS.aWizFList, 1)
					LOOP
				ENDIF

				m.nWidth = m.nWidth + THIS.GetFldWidth(THIS.aWizFList[m.j, FLD_TYPE], ;
					THIS.aWizFList[m.j, FLD_LEN], ;
					THIS.aWizFList[m.j, FLD_DEC], ;
					THIS.oRptField.FontStyle, ;
					THIS.oRptField.FontFace, ;
					THIS.oRptField.FontSize)

				m.cDataType = THIS.aWizFList[m.j, FLD_TYPE]

				IF m.nOccurs = 1
					m.cExpr = m.cValue
					m.cExprType = m.cDataType
				ELSE
					DO CASE
					CASE m.cDataType = DT_CHAR
						m.cValue = "ALLT(" + m.cValue + ")"

					CASE m.cDataType = DT_VARCHAR
						* use exact expression
					CASE m.cDataType = DT_VARBINARY
						* use exact expression
						
					CASE m.cDataType = DT_LOGIC
						m.cValue = "IIF(" + m.cValue + ",'Y','N')"

					CASE INLIST(m.cDataType, DT_NUM, DT_FLOAT, DT_DOUBLE, DT_MONEY, DT_INT)
						m.cValue = "LTRIM(STR(" + m.cValue + "," + ALLT(STR(THIS.aWizFList[m.j, FLD_LEN])) + ;
							"," + ALLT(STR(THIS.aWizFList[m.j, FLD_DEC])) + "))"

					CASE m.cDataType = DT_DATE
						m.cValue = "DTOC(" + m.cValue + ")"

					CASE m.cDataType = DT_TIME
						m.cValue = "TTOC(" + m.cValue + ")"
					ENDCASE
					m.cExpr = m.cExpr + IIF(EMPTY(m.cExpr), "", [+]) + m.cValue
				ENDIF
			ENDIF
		ENDFOR

		RETURN m.cExpr

	ENDFUNC


	*>> InsDetail: Insert information that belongs in the detail band
	* Abstract:
	*   This is the guts of the engine. It processes each selected field,
	*   putting it on the label at the proper position in the detail band.
	*
	PROTECTED PROCEDURE InsDetail
		LOCAL m.nSelect, m.i, m.nVPos, m.nWidth, m.nMaxWidth, m.nLines, m.nHPos
		LOCAL m.cLine, m.cExpr, m.cDataType

		* No fields selected?
		IF ALEN(THIS.aLblLines, 1) == 1 .AND. EMPTY(THIS.aLblLines[1, 1])
			RETURN
		ENDIF
		m.nSelect = SELECT()
		SELECT NewRpt

		m.nLines = ALEN(THIS.aLblLines, 1)
		m.nVPos = WZ_BASEBAND + IIF(THIS.nColumns == 0, 0, WZ_BASEBAND) + ;
			MAX(0, THIS.oDetailBand.Height/2 - (THIS.oRptField.Height * m.nLines)/2) + ;
			THIS.nLblTopMargin

		m.nMaxWidth = 0

		FOR m.i = 1 TO m.nLines
			THIS.DoTherm(0, THERM_DETAIL_LOC)

			m.cLine = THIS.aLblLines[m.i, 1]
			IF !EMPTY(m.cLine)
				m.nWidth = 0
				THIS.oRptField.Expr = THIS.GetLblExpr(m.cLine, @m.nWidth, @m.cDataType)

				m.nMaxWidth = MAX(m.nMaxWidth, m.nWidth)
				THIS.oRptField.VPos = m.nVPos

				DO CASE
				CASE INLIST(m.cDataType, DT_FLOAT, DT_NUM, DT_DOUBLE, DT_MONEY, DT_INT)
					THIS.oRptField.FillChar = "N"
					THIS.oRptField.Picture = ["@B"]      && left justify
				CASE INLIST(m.cDataType, DT_DATE, DT_TIME)
					THIS.oRptField.FillChar = "D"
				OTHERWISE
					THIS.oRptField.FillChar = "C"
				ENDCASE

				THIS.OInsert(THIS.oRptField, "NewRpt")
			ENDIF
			m.nVPos = m.nVPos + THIS.oRptField.Height
		ENDFOR

		m.nHPos = MAX(0, THIS.nLblWidth/2 - m.nMaxWidth / 2)
		REPLACE ALL Width WITH MIN(m.nMaxWidth, THIS.nLblWidth), HPos WITH m.nHPos FOR ObjType = OT_GET

		SELECT (m.nSelect)

	ENDPROC

	*>> InsBands: Insert records for each band type
	* Abstract:
	*   Insert band records into the new report (ie page hdr, column hdr, detail, etc)
	*
	PROTECTED PROCEDURE InsBands
		LOCAL m.nSelect

		m.nSelect = SELECT()

		SELECT NewRpt
		THIS.oPageHdrBand.Height = THIS.nLblTopMargin
		THIS.OInsert(THIS.oPageHdrBand, "NewRpt")

		IF THIS.nColumns > 1
			THIS.OInsert(THIS.oColHdrBand, "NewRpt")
		ENDIF

		THIS.oDetailBand.Height = THIS.nLblHeight
		THIS.OInsert(THIS.oDetailBand, "NewRpt")

		IF THIS.nColumns > 1
			THIS.OInsert(THIS.oColFtrBand, "NewRpt")
		ENDIF

		THIS.OInsert(THIS.oPageFtrBand, "NewRpt")

		SELECT (m.nSelect)
	ENDPROC



	*>> InsSetup: Insert setup information
	PROTECTED PROCEDURE InsSetup

		WITH THIS.oRptHeader
			.VPos    = THIS.nColumns
			.HPos    = THIS.nLblLeftMargin
			.Height  = THIS.nLblSpacing
			.Width   = IIF(THIS.nColumns = 1, -1, THIS.nLblWidth)
			.Ruler   = IIF(THIS.lMetric, 2, 1)
			.Environ = THIS.lSaveEnviron
		ENDWITH

		IF THIS.nWizAction == GO_PREVIEW
			* This is a special flag which forces the display of
			* "<untitled>" or whatever in the Preview Window title.  If
			* it weren't for this, the Preview would display our temp filename
			* as the window title.
			THIS.oRptHeader.Unique = .T.
		ENDIF

		THIS.oRptHeader.Tag    = ""
		THIS.oRptHeader.Tag2   = ""

		THIS.oRptHeader.Expr   = ""

		THIS.OInsert(THIS.oRptHeader, "NewRpt")

	ENDPROC



	*>> SetupRpt: Setup label defaults & options
	* Abstract:
	*   This method sets options which are derived directly from
	*   values entered in the UI, and thus can't be computed in the INIT
	*   method -- things such as page width based upon paper size &
	*   orientation & margins, style defaults, etc
	*
	FUNCTION SetupRpt
		LOCAL nSelect, lInUse, cError, cSafety

		THIS.oRptHeader   = .NULL.
		THIS.oRptDataEnv  = .NULL.
		THIS.oRptField    = .NULL.
		THIS.oPageHdrBand = .NULL.
		THIS.oDetailBand  = .NULL.
		THIS.oColHdrBand  = .NULL.
		THIS.oColFtrBand  = .NULL.
		THIS.oPageFtrBand = .NULL.

		m.nSelect = SELECT()

		IF EMPTY(THIS.cLblData)
			THIS.Alert(ERR_NOLBL_LOC)
			THIS.haderror = .T.
			RETURN .F.
		ENDIF

		IF EMPTY(THIS.cStyleFile)
			THIS.cStyleFile = "STYLES\STYLELBL"
		ENDIF

		IF AT(".", THIS.cStyleFile) = 0
			THIS.cStyleFile = THIS.cStyleFile + ".LBX"
		ENDIF

		m.cError = THIS.ReadStyle(THIS.cStyleFile)
		IF !EMPTY(m.cError)
			THIS.Alert(m.cError)
			THIS.haderror = .T.
			RETURN .F.
		ENDIF

		m.cSafety = SET("SAFETY")
		SET SAFETY OFF


		* Get number of columns & label width from the label data
		THIS.nColumns = VAL(SUBSTR(THIS.cLblData, 48, 2))
		THIS.nLblWidth = VAL(SUBSTR(THIS.cLblData, 58, 8))
		THIS.nLblHeight = VAL(SUBSTR(THIS.cLblData, 74, 8))
		THIS.nLblTopMargin = VAL(SUBSTR(THIS.cLblData, 66, 8))
		THIS.nLblSpacing = VAL(SUBSTR(THIS.cLblData, 50, 8))
		THIS.nLblLeftMargin = MAX(VAL(SUBSTR(THIS.cLblData, 40, 8)), IIF(THIS.lMetric, N_MINLEFTMARGINMET, N_MINLEFTMARGINENG))

		SELECT StyleFile


		IF USED("NewRpt")
			USE IN NewRpt
		ENDIF
		IF AT(".", THIS.cOutFile) = 0
			THIS.cOutFile = THIS.cOutFile + ".LBX"
		ENDIF
		THIS.cOutFile = FULLPATH(THIS.cOutFile)

		COPY STRUCTURE TO (THIS.cOutFile)
		USE (THIS.cOutFile) EXCLUSIVE ALIAS NewRpt IN 0

		#IF .F.
			CREATE REPORT (THIS.cOutFile) FROM (THIS.cStyleFile)
			SELECT 0
			USE (THIS.cOutFile) EXCLUSIVE ALIAS NewRpt

			THIS.oRptHeader.Tag = Tag
			THIS.oRptHeader.Tag2 = Tag2
			ZAP
		#ENDIF

		SELECT StyleFile

		m.lInUse = USED(THIS.cWizAlias)
		IF m.lInUse
			SELECT (THIS.cWizAlias)
		ELSE
			SELECT 0
			USE (THIS.cWizAlias)
		ENDIF
		=AFIELDS(THIS.aWizFList)



		IF !(m.lInUse)
			USE
		ENDIF

		SELECT (m.nSelect)
		SET SAFETY &cSafety

		RETURN .T.
	ENDFUNC




	*>> Destroy
	PROCEDURE Destroy
		MainEngine::Destroy()

		IF USED("NewRpt")
			USE IN NewRpt
		ENDIF

		IF USED("StyleFile")
			USE IN StyleFile
		ENDIF

	ENDPROC

	*>> Process: Main processing engine for Labels
	PROCEDURE Process
		LOCAL nSelect, cTempFile, cSafety, i


		m.nSelect = SELECT()
		m.cSafety = SET("SAFETY")
		SET SAFETY OFF

		IF EMPTY(THIS.cWizAlias)
			THIS.cWizAlias = THIS.aWizTables[1, 1]
		ENDIF
		IF EMPTY(THIS.aWizTables[1, 1])
			THIS.aWizTables[1, 1] = THIS.cWizAlias
		ENDIF



		DO CASE
		CASE THIS.nWizAction = GO_PREVIEW
			* If we're doing a preview, then set up a temporary output label
			m.cTempFile = FULLPATH(SYS(2023) + "\" + "_" + LEFT(SYS(3), 7))
			THIS.cOutFile = m.cTempFile + ".LBX"

		CASE EMPTY(THIS.cOutFile)
			THIS.cOutFile = THIS.aWizTables[1, 1]
			IF !THIS.SaveOutFile(SAVELBL_LOC, THIS.cOutFile, "LBX")
				RETURN
			ENDIF
			IF AT(".", THIS.cOutFile) = 0
				THIS.cOutFile = THIS.cOutFile + ".LBX"
			ENDIF

		ENDCASE


		THIS.SetTherm(THERM_LBLMSG_LOC, 4 + ALEN(THIS.aWizFields), 0)
		THIS.DoTherm(0, THERM_LBLCREATE_LOC)
		IF THIS.SetupRpt()

			THIS.InsSetup()
			THIS.InsBands()

			THIS.InsDetail()

			THIS.DoTherm(0, THERM_LBLFORMAT_LOC)

			THIS.InsOtherInfo()
			THIS.InsDataEnv(THIS.oRptDataEnv)


			IF USED("StyleFile")
				USE IN StyleFile
			ENDIF

			IF USED("NewRpt")
				USE IN NewRpt
			ENDIF

			THIS.DoTherm(-1)



			DO CASE
			CASE THIS.nWizAction = GO_PREVIEW
				SELECT (THIS.cWizAlias)

				LABEL FORM (THIS.cOutFile) PREVIEW
				IF !EMPTY(SYS(2000, m.cTempFile + ".LBX"))
					DELETE FILE (m.cTempFile + ".LBX")
				ENDIF
				IF !EMPTY(SYS(2000, m.cTempFile + ".LBT"))
					DELETE FILE (m.cTempFile + ".LBT")
				ENDIF

			CASE THIS.nWizAction = GO_MODIFY
				cNewFile = THIS.cOutFile
				_SHELL = [MODIFY LABEL "&cNewFile" NOWAIT]

			CASE THIS.nWizAction = GO_RUN
				cNewFile = THIS.cOutFile
				_SHELL = [LABEL FORM "&cNewFile" TO PRINTER NOCONSOLE]

			ENDCASE
		ELSE
			THIS.cOutFile = ""
		ENDIF

		SET SAFETY &cSafety
		SELECT (m.nSelect)

	ENDPROC


	*>> ReadStyle: read global style properties in from Label Style file
	FUNCTION ReadStyle
		LPARAMETERS cStyleFile

		LOCAL nSelect, cError

		m.cError = ""

		* Open up the report style file
		m.nSelect = SELECT()
		IF AT(".", m.cStyleFile) = 0
			m.cStyleFile = m.cStyleFile + ".LBX"
		ENDIF
		SELECT 0
		USE (m.cStyleFile) ALIAS StyleFile

		* Get report info
		LOCATE FOR objtype = OT_HEADER AND TRIM(platform) = THIS.cPlatform
		IF !FOUND()
			SELECT (m.nSelect)
			RETURN ERR_NOHEADER_LOC
		ENDIF
		THIS.AddStyleRec("THIS.oRptHeader", "HEADER")

		* Get dbf environment info
		LOCATE FOR objtype=OT_DATAENV AND TRIM(platform) = THIS.cPlatform
		IF !FOUND()
			GO TOP
		ENDIF
		THIS.AddStyleRec("THIS.oRptDataEnv", "ENVIRONMENT")

		SCAN FOR ObjType = OT_BAND AND TRIM(platform) = THIS.cPlatform
			DO CASE
			CASE ObjCode = OC_PGHEAD
				THIS.AddStyleRec("THIS.oPageHdrBand", "BAND")

			CASE ObjCode = OC_COLHEAD
				THIS.AddStyleRec("THIS.oColHdrBand", "BAND")

			CASE ObjCode = OC_DETAIL
				THIS.AddStyleRec("THIS.oDetailBand", "BAND")

			CASE ObjCode = OC_COLFOOT
				THIS.AddStyleRec("THIS.oColFtrBand", "BAND")

			CASE ObjCode = OC_PGFOOT
				THIS.AddStyleRec("THIS.oPageFtrBand", "BAND")

			ENDCASE
		ENDSCAN


		IF ISNULL(THIS.oPageFtrBand) .OR. ISNULL(THIS.oPageHdrBand) .OR. ;
				ISNULL(THIS.oColHdrBand) .OR. ISNULL(THIS.oColFtrBand) .OR. ;
				ISNULL(THIS.oDetailBand)
			SELECT (m.nSelect)
			RETURN ERR_NOHEADER_LOC
		ENDIF



		* Get normal field info
		LOCATE FOR objtype=OT_GET AND C_FLD$UPPER(expr) AND TRIM(platform) = THIS.cPlatform
		IF !FOUND()
			SELECT (m.nSelect)
			RETURN ERR_NOFIELD_LOC
		ENDIF
		THIS.AddStyleRec("THIS.oRptField", "FIELD")

		IF !EMPTY(THIS.cFontName)
			THIS.oRptField.FontFace = THIS.cFontName
			THIS.oRptField.FontSize = THIS.nFontSize

			*- convert style from char style to num style
			THIS.oRptField.FontStyle = 0
			m.cStyleCodes = "BIUOSCE"   && bold (1), italic (2), underline (4), outline (8),
&& shadow (16), condensed (32), extended (64)
			FOR i = 1 TO LEN(THIS.cFontStyle)
				m.iPower = AT(SUBSTR(THIS.cFontStyle,i,1), m.cStyleCodes) - 1
				IF iPower >= 0
					THIS.oRptField.FontStyle = THIS.oRptField.FontStyle + (2 ^ iPower)
				ENDIF
			NEXT
		ENDIF

		SELECT (m.nSelect)


		RETURN m.cError
	ENDFUNC


ENDDEFINE


*---------------------------------------
* Additional Information
*---------------------------------------
* Labels definitions are stored in DATA field of the resource file.  The
* following code (extracted from AddLabel) demonstrates the format of
* this field:
* REPLACE thereso.data WITH CHR(4) + CHR(0) + PADR(ALLTRIM(ThisForm.Description.Value),37,' ') + ;
*  PADL(ALLTRIM(ThisForm.LeftMargin.Value),8,"0") + ;
*  PADL(ALLTRIM(ThisForm.NumberAcross.Value),2,"0") + ;
*  PADL(ALLTRIM(ThisForm.SpacesBetween.Value),8,"0") + ;
*  PADL(ALLTRIM(ThisForm.LabelWidth.Value),8,"0") + ;
*  PADL(ALLTRIM(ThisForm.TopMargin.Value),8,"0") + ;
*  PADL(ALLTRIM(ThisForm.LabelHeight.Value),8,"0") + ;
*  IIF(ThisForm.Metric.Value = 1,'T','F')
* Columns = SUBSTR(Data, 48, 2)
* Width = SUBSTR(Data, 58, 8)
* TopMargin = SUBSTR(Data, 66, 8)
* Height = SUBSTR(Data, 74, 8)


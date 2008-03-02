#DEFINE E_NOAUTGRAPH_LOC	"Failed to create AutoGraph Object."

* _GENGRAPH assumes that the table to chart is already selected. The 
* category axis is based on the first field. The other fields (those
* which are numeric) are used as data fields.

****************Sample/Testing****************
#IFDEF devmode
SET PROCEDURE TO wzengine ADDITIVE
SET CLASS TO graph
x=CREATE('GraphEngine')
x.nWizAction = 1
x.lSeriesByRow = .F.			&&Chart SubType
*x.lUseAutoFormat = .T.
*x.cChartAutoGallery = 4
*x.cChartAutoFormat = 8
x.nChartType = 	  5				&&Chart Type
x.nChartSubType = 1				&&Chart SubType
x.cCategoryField = 'country'
USE offices
x.makeoutput
#ENDIF
***************************************

DEFINE CLASS GraphEngine AS WizEngineAll

	oG = .NULL.					&& graph automation object reference
	oGraphRef = ""				&&graph reference
	graphpreview = ""			&&preview reference
	iHelpContextID = 1895825413	&&help id
	nSaveLocaleId = 1033		&&saved locale id
	nGraphVersion = 5			&&graph version
	
	nWizAction = 1				&& 1 = save to form, 2 = save to graph, 3 = save as query
	cWizClass = "ole"			&&wizard class	(e.g., report)
	cWizName  = "graphwizard"	&&wizard name or class (e.g., Group/Total report)
	cDefNewField = "olegraph"	&&default field name in new table
	cOutFile = ""
	cWizAlias = ""
	lHadPreview = .F.			&&had a preview already and may have changed data in MS Graph
	cLastDataRow = ""			&&last contents added to Series by Row
	cLastDataCol = ""			&&last contents added to Series by Col
	cOutGenField = ""			&&output field name

	lAddLegend = .T.			&&Add Legend
	lAddTitle  = .T.			&&Add Title
	lSeriesByRow = .T.			&&Series by Row (.T.), by Column (.F.)
	lUseAutoFormat = .F.		&&Use autoformat
	cTitle = ""					&&Title
	nCatCapital = 0				&&Category capitalization (3-proper,1-lower,2-upper)
	lAutoGraph = .F.			&&Autograph
	lShowNulls = .T.			&&Include rows with null values
	lAddedData = .F.			&& has data been added to the graph?
	
	nChartType = 1				&&Chart Type
	nChartSubType = 1			&&Chart SubType
	cChartAutoGallery = 1		&&Chart autoformat gallery
	cChartAutoFormat = 1 		&&Chart autoformat format
	lReplaceDBF = .T.			&&Replace Graph DBF vs Append
	cOpenAlias = ""				&&Alias of output table if already opened
	
	DIMENSION aDataFields[1]
	aDataFields = ""						&& data fields used
	cCategoryField = ""						&& category field used
	
	* Defaults
	cGraphDBF = "wizgraph.dbf"				&& DBF containing cGraphField
	cGraphFldRow = "graph_row"				&& General field containing setup Graph (series by row)
	cGraphFldCol = "graph_col"				&& General field containing setup Graph (series by col)
	cOleServer	= "msgraph.application.5"
	cGraphField = "graph_row"				&& graph_row or graph_col type
	cGraphPrevClass = "GraphPreview"		&& Class containing preview form

	PROCEDURE AutoGraph
		LPARAMETER p1,p2,p3,p4,p5,p6,p7,p8,p9
		*   parm1 - chart type (number)
		*   parm2 - chart subtype (number)
		*   parm3 - title (if not empty)
		*   parm4 - series by row (.T.), by column (.F.)
		*   parm5 - has legend (.T.)
		*   parm6 - use autoformat (.F.)
		*   parm7 - file name for graph output
		*   parm8 - don't open graph when done
		*	parm9 - show nulls
		
		* Get Chart Type (Also AutoFormat Gallery)
		LOCAL nMaxType,nMaxSubType,lNoModify
		m.nMaxType = IIF(TYPE("m.P6")="L" AND m.P6,15,17)
		m.nMaxSubType = IIF(TYPE("m.P6")="L" AND m.P6,12,4)
		THIS.lAutoGraph = .T.
		m.lNoModify = .F.

		* Get Chart Type (Also AutoGallery Format)
		IF PARAMETERS() > 0 AND TYPE("m.p1")="N"
			THIS.nChartType = m.p1
		ENDIF
		
		* Get Chart SubType (Also AutoFormat Format)
		IF PARAMETERS() > 1 AND TYPE("m.p2")="N"
			THIS.nChartSubType = m.p2
		ENDIF

		* Get Chart Title
		IF PARAMETERS() > 2 AND TYPE("m.p3")="C" AND !EMPTY(m.p3)
			THIS.cTitle = m.p3
			THIS.lAddTitle = .T.
		ENDIF

		* Get Series by row
		IF PARAMETERS() > 3 AND TYPE("m.p4")="L"
			THIS.lSeriesByRow = m.p4
		ENDIF
		
		* Get Chart Legend
		IF PARAMETERS() > 4 AND TYPE("m.p5")="L"
			THIS.lAddLegend = m.p5
		ENDIF

		* Get Use AutoFormat
		IF PARAMETERS() > 5 AND TYPE("m.p6")="L"
			THIS.lUseAutoFormat = m.p6
			THIS.cChartAutoGallery = THIS.nChartType   && Chart autoformat gallery
			THIS.cChartAutoFormat = THIS.nChartSubType && Chart autoformat format
		ENDIF
		
		* Get Output file
		IF PARAMETERS() > 6 AND TYPE("m.p7")="C" AND !EMPTY(m.p7)
			DO CASE 
				CASE THIS.og.ngraphVersion >= 8 AND UPPER(JUSTEXT(m.p7)) == "DBF"
					THIS.nWizAction = 2
				CASE THIS.og.ngraphVersion >= 8
					m.p7 = THIS.ForceExt(m.p7,"SCX")
					THIS.nWizAction = 1
				OTHERWISE
					*- graph 5
					m.p7 = THIS.ForceExt(m.p7,"DBF")
					THIS.nWizAction = 2
			ENDCASE
			THIS.cOutFile = m.p7
		ENDIF
		
		* Get whether to open graph in form/dbf when done
		IF TYPE("m.p8")="L" AND m.p8
			m.lNoModify = .T.
		ENDIF

		* Get Null display
		IF PARAMETERS() > 8 AND TYPE("m.p9")="L"
			THIS.lShowNulls = m.p9
		ENDIF
	
		THIS.lHadPreview = .F.

		THIS.MakeOutPut()
		IF m.lNoModify
			_SHELL = ""
		ENDIF
		
	ENDPROC

	*----------------------------------
	PROCEDURE Init2
	*----------------------------------
		*- create the AutoGraph object
		SET CLASS TO AutGraph ADDITIVE
		THIS.oG = CREATEOBJECT("AutoGraph")
		
		IF TYPE("THIS.oG") # 'O'
			THIS.Alert(E_NOAUTGRAPH_LOC)
			RETURN .F.
		ENDIF
		
		THIS.nGraphVersion = THIS.oG.nGraphVersion

		RETURN .T.
	ENDPROC
	
	*----------------------------------
	PROCEDURE Destroy
	*----------------------------------
		RELEASE CLASSLIB AutGraph

		WizEngineAll::Destroy()		
	ENDPROC
	
	*----------------------------------
	PROCEDURE MakeOutput
	*----------------------------------

		LOCAL lRetVal
		
		THIS.oG.cAlias = THIS.cWizAlias
		THIS.oG.cOutFile = THIS.cOutFile
		THIS.oG.nAction = THIS.nWizAction
		THIS.oG.nGraphVersion = THIS.nGraphVersion
		THIS.oG.cTitle = THIS.cTitle
		THIS.oG.nChartAutoGallery = THIS.cChartAutoGallery
		THIS.oG.nChartAutoFormat = THIS.cChartAutoFormat
		THIS.oG.cGraphFldRow = THIS.cGraphFldRow
		THIS.oG.cGraphFldCol = THIS.cGraphFldCol
		THIS.oG.lAddTitle = THIS.lAddTitle
		THIS.oG.nChartType = THIS.nChartType 
		THIS.oG.nChartSubType = THIS.nChartSubType 
		THIS.oG.lSeriesByRow = THIS.lSeriesByRow 
		THIS.oG.lAddLegend = THIS.lAddLegend 
		THIS.oG.lUseAutoFormat = THIS.lUseAutoFormat 
		THIS.oG.lShowNulls = THIS.lShowNulls
		THIS.oG.cGraphDBF = THIS.cGraphDBF
		THIS.oG.cGraphPrevClass = THIS.cGraphPrevClass
		THIS.oG.cGraphField = THIS.cGraphField
		THIS.oG.cOleServer = THIS.cOleServer
		THIS.oG.cDefNewField = THIS.cDefNewField
		THIS.oG.cCategoryField = THIS.cCategoryField
		THIS.oG.lAddedData = THIS.lAddedData
		THIS.oG.lAutoGraph = THIS.lAutoGraph
		DIMENSION THIS.oG.aDataFields[ALEN(THIS.aDataFields,1)]
		ACOPY(THIS.aDataFields, THIS.oG.aDataFields)

		lRetVal = THIS.oG.MakeOutput()

		IF TYPE("THIS.oG") == 'O' AND !ISNULL(THIS.oG)
			THIS.lAddedData = THIS.oG.lAddedData
		ENDIF
		
		RETURN lRetVal
		
	ENDPROC

ENDDEFINE

DEFINE CLASS autographform AS FORM
	ADD OBJECT oleboundcontrol1 AS oleboundcontrol
ENDDEFINE
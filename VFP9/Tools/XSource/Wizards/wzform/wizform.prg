* this is the form wizard engine

#INCLUDE "FORMWIZ.H"

#DEFINE WIZFORM_CLASS		"form"
#DEFINE WIZFORM_NAME		"formwizard"
#DEFINE	C_SAVEFORM_LOC		"Save form as:"
#DEFINE	C_DEFFORMNAME_LOC	"MYFORM.SCX"

* Thermometer messages

#DEFINE THERM_CREATE_LOC	"Creating form..."	
#DEFINE THERM_DETAIL_LOC	"Adding fields to form..."	
#DEFINE THERM_INDEX_LOC		"Adding data environment..."
#DEFINE THERM_SAVE_LOC		"Saving form..."
#DEFINE THERM_DONE_LOC		"Finished."	
#DEFINE THERM_STYLE_LOC	 	"Reading style data..."
#DEFINE C_THERMTITLEWIZ_LOC	'Form Wizard'	&&Thermometer title for Wizard
#DEFINE C_THERMTITLEBLD_LOC	'Form Builder'	&&Thermometer title for Builder
#DEFINE C_THERMHEADER_LOC	'Processing New Form:'	&&Thermometer header caption

** Used for testing ***
#DEFINE THERM_STYLE1_LOC	 "Init style data..."
#DEFINE THERM_STYLE2_LOC	 "Layout style data..."
#DEFINE THERM_STYLE3_LOC	 "Field style data..."
#DEFINE THERM_STYLE4_LOC	 "Valid start data..."
#DEFINE THERM_STYLE5_LOC	 "Valid end data..."

*******************************************
DEFINE CLASS FormWizEngine AS WizEngineAll
*******************************************

	* Style Object Classes:
	*  These are properties which contain the name of 
	*  object referenced in style property reference.
	* Style Object Classes References:
	*  These are property names used in styles which
	*  reference various objects used for fields and layout.
	* Style Object Classes Types:
	*  These are property class types used in styles.
	
	iHelpContextID = 95825512		&&help context id
	styleform = ""				&&reference to main form
	nf = ""						&&reference to main form
	gridform = ""				&&reference to grid form
	oLayout = ""				&& layout class name
	oLayoutRef = "WizLayout"
	oBorder = 	""				&& Border member name (in Layout Class)
	oBorderRef = "oDimensions"
	oLblPos1 = 	""				&& 1st Label Position member name (in Layout Class)
	oLblPos1Ref ="oLabel1"
	oLblPos2 = 	""				&& 2nd Label Position member name (in Layout Class)
	oLblPos2Ref = "oLabel2"
	oLblCol2 = 	""				&& 2nd Column Position member name (in Layout Class)
	oLblCol2Ref = "oCol2"
	oTitle = ""					&& Title class name
	oTitleRef = "WizTitle"
	oLabel = ""
	oLabelRef = "WizLabel"
	oLabelType = "LABEL"
	oField = ""					&& field class name
	oFieldRef = "WizField"
	oFieldType = "TEXTBOX"
	oMemo = ""					&& memo class name
	oMemoRef = "WizMemo"
	oMemoType = "EDITBOX"
	oLogic = ""					&& logic class name
	oLogicRef = "WizLogic"
	oLogicType = "CHECKBOX"
	oOle = ""					&& OLE class name
	oOleRef = "WizOle"
	oOleType = "OLEBOUNDCONTROL"
	oGrid = ""					&& Grid class name
	oGridRef = "WizGrid"
	oGrdType = "GRID"
	
	*Misc Style properties
	oMaxChar = C_MAXCHAR		&& Max chars to convert chr->memo (default 60) 
	oMaxChRef = "WizMaxCharFld"
	oLblSuffix = ":"			&& Suffix used on label		
	oLblSufRef = "WizLblSuffix"
	oLblCaps = "proper"			&& Capitalization for label
	oLblCapRef = "WizLblCap"
	oLblDefWid = .T.			&& Use default label width
	oLblDefWidRef = "WizLblDefWid"
	oFormStretch =  .T.			&& Stretch Form
	oFormStretchRef = "WizFormStretch"
	oCodeStyle = .T.			&& Whether to use code style or button style
	oCodeStyleRef = "WizCodeStyle"
	oWizVerify = .T.			&& Whether to check/verify style (performance enhancer)
	oWizVerifyRef = "WizVerify"
	oWizButtons = ""			&& Name of button class
	oWizButtonsRef = "WizButtons"
	oWizBtnPos = 0				&& Button position centering (0-none,1-hori,2-vert,3-both)
	oWizBtnPosRef = "WizBtnPos"
	oBtnLayout=""				&& Button position object if object used
	oBtnLayoutRef = "WizBtnLayout"
	oWizCaptions = .T.			&& Use English DBC captions
	oWizCaptionsRef = "WizCaptions"
	oWizBuffering = 5			&& Table buffering for DE
	oWizBufferingRef = "WizBuffering"
	oWizGridForm = .F.			&& Has a form in formset for using as Grid form
	oWizGridFormRef = "WizGridForm"
	oWizLblSpace = 20			&& space between label-field (used only if no wizfield container!)
	oWizLblSpaceRef = "WizLblSpace"
	oWizCboxLbl = .F.			&& use separate lbl with checkbox
	oWizCboxLblRef = "WizCboxLbl"
	oWizPages = 0				&& use pages 
	oWizPagesRef = "WizPages"
	oWizPageStyle = ""
	oWizPageStyleRef = "WizPageStyle"
	gridname = ""
	cStyName = ""				&& style name
	cCodeName = ""			&& code style name

	* Dimensional properties (pixels)
	nHeader = 0					&& header size
	nFooter = 0					&& footer size
	nLeftMargin = 0				&& left margin	
	nRightMargin = 0			&& right margin
	nLTopPos = 0				&& label top starting position
	nLLeftPos = 0				&& label left starting position
	nVLblSpace = 0				&& vertical space between labels
	nHLblSpace = 0				&& hori space between labels
	nHSpace = 0					&& label-field horizontal space
	nVSpace = 0					&& label-field vertical space
	nBtnLeft = 0				&& left buttonset pos
	nBtnTop = 0					&& top buttonset pos
	nFormColor = 0				&& form backcolor
	cFormPicture = ""			&& form picture
	nVLPOS = 0					&& current vert pos for lbl placement
	nHLPOS = 0					&& current hori pos for lbl placement
	nVINC = 0					&& increment vert adj for lbl/fld placement
	nHINC = 0					&& increment hori adj for lbl/fld placement
	nLastVINC = 0				&& last vert adj for use with multi columns
	nDefLblWid = 0				&& default label width
	nCurHgt = 0					&& current object height
	nBottom  = 0				&& bottom footer
	lIs1col = .T.				&& whether using a single column or multi
	nMaxCols = 0				&& max number of columns
	nMaxRight = 0				&& max right margin
	nColWidth = 0				&& column width
	nRightEdge = 0 				&& right edge
	nCurrCol = 1				&& current column position
	nFrmStartHgt = 0			&& form starting height
	* Class references
	cStyle = "Embossed"			&& visual style class desc
	styleref = "Embossedform"	&& visual style class
	vcxref = "wizembss.vcx"		&& visual style class vcx location
	buttonstyle = ""			&& code/button style class desc
	codevcxref = "wizbtns.vcx"	&& code/button style vcx location
	coderef = "txtbtns"			&& code/button style class
	codetype = "B"				&& code or button class type
	PreVisual = ""				&& method to run before 
	PostVisual = ""				&& method to run after
	PreCode = ""				&& method to run before
	PostCode = ""				&& method to run after
	DataEnvRef = ""				&& data environment object reference
	ThermWinName = ""			&& thermometer ref
	lUseTherm = .T.				&& use a thermometer?
	nThermCurrent = 0			&& thermometer percent
	nThermTotal = 0				&& thermometer percent
	cThermTitle = ""
	
	* Misc settings
	cFieldName = ""				&& current field name
	lExpandForm = .F.			&& allow form to expand
	lVertPref = .T.				&& field layout orientation preference
	nCols = 20					&& max columns for field layout
	lSavePrefs = .F.			&& save preferences
	lRunningWizard = .T.		&& running wizard 
	lRunningBuilder = .F.		&& running builder
	oldExact = ""				&& SET EXACT old settings (ON for ASCANs)
	lIsGrid = .F.				&& use grid object	
	nVertAdj = 152				&& vertical resolution adjustment (include for toolbar)
	nHoriAdj = 20				&& horizontal resolution adjustment
	nVertRes = 480				&& vertical resolution (VGA - 480)
	nHoriRes = 640				&& horizontal resolution (VGA - 640)
	cCodeSty1 = ""				&& code style 1 -- Text Buttons 
	cCodeSty2 = ""				&& code style 2 -- Picture Buttons 
	cCodeSty3 = ""				&& code style 3 -- No Buttons	
	cWizClass = WIZFORM_CLASS	&&wizard class	(e.g., report)
	cWizName = WIZFORM_NAME		&&wizard name or class (e.g., Group/Total report)
	lUsingContainers = .f.		&&using container classes
	lUsingCheckboxes = .f.		&&using checkboxes classes
	lHasGenFlds = .F.			&&general field in selected fields list
	lHasBlobFlds = .F.			&&blob field in selected fields list
	lHasMemoFlds = .F.			&&memo field in selected fields list
	lHasLogicFlds = .F.			&&logic field in selected fields list
	lUsePages = .F.				&& whether to use pages
	lOverrideStyle = .F.		&& override style with values in DBC
	lUseFieldMappings = .F.		&& use field mappings that are stored in registry
	oReg = .NULL.				&& a registry class instance for plumbing the field mappings
	lAddAppObject = .F.			&& automatically add app object
	
	DIMENSION aVisStyles[1,2]	&&array of visual styles
	aVisStyles=""
	DIMENSION aCodeStyles[1]	&&array of code styles
	aCodeStyles=""
	DIMENSION aGlobals[9,1]		
	aGlobals = 0
	DIMENSION aUser[1,1]		
	aUser = ""
	DIMENSION aPreMembers[1]
	aPreMembers = ""
	DIMENSION aCaptions[1]		&&DBC Caption names
	aCaptions= ""

	** One to Many Specific properties
	cGridAlias = ""
	cGridDBCName = ""
	cGridDBCAlias = ""
	cGridDBCTable = ""
	cMainKey = ""
	cRelatedKey = ""
	DIMENSION aGridFields[1,1]
	aGridFields= ""
	DIMENSION aGridFList[1,1]
	aGridFList = ""
	DIMENSION aGridSorts[1,1]
	aGridSorts = ""

	PROCEDURE AutoForm
		PARAMETER oSettings
		LOCAL i,aStyParms,nTotTables,aDBCTables,getfname
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

		IF !EMPTY(ALIAS())  		&&no DBF selected
	
			THIS.cWizAlias = ALIAS()
			THIS.cDBCName = CURSORGETPROP('Database')

			IF !EMPTY(THIS.cDBCName)
				THIS.cDBCTable = CURSORGETPROP('SourceName')		&&DBC Table name
				IF ATC(SET("DATA"),THIS.cDBCName) = 0
					SET DATABASE TO (THIS.cDBCName)
				ENDIF
			ENDIF
			
			* Get field list
			DO CASE
			CASE m.lHasObj AND TYPE("m.oSettings.lBlankForm")="L" AND !EMPTY(oSettings.lBlankForm)
				DIMENSION THIS.aWizFields[1]
				THIS.aWizFields = ""
			CASE m.lHasObj AND TYPE("m.oSettings.aWizFields[1]")="C" AND !EMPTY(oSettings.aWizFields)
				=ACOPY(oSettings.aWizFields,THIS.aWizFields)
			OTHERWISE
				DIMENSION THIS.aWizFields[FCOUNT()]
				FOR i = 1 TO FCOUNT()
					THIS.aWizFields[m.i] = PROPER(FIELD[m.i])
				ENDFOR
			ENDCASE
			AFIELDS(THIS.aWizFList)
			
			* Get sort field list
			IF m.lHasObj AND TYPE("m.oSettings.aWizSorts[1]")="C" AND !EMPTY(oSettings.aWizSorts)
				=ACOPY(oSettings.aWizSorts,THIS.aWizSorts)
			ENDIF

			* Get sort ascend
			IF m.lHasObj AND PEMSTATUS(m.oSettings,'lSortAscend ',5)
				THIS.lSortAscend = oSettings.lSortAscend 
			ENDIF

			* Get Uses pages option
			IF m.lHasObj AND PEMSTATUS(m.oSettings,'lUsePages',5)
				THIS.lUsePages = oSettings.lUsePages
			ENDIF
		ENDIF
		
		* Get output file name
		IF m.lHasObj AND PEMSTATUS(m.oSettings,'cOutFile',5) 
			IF !EMPTY(oSettings.cOutFile)
				THIS.cOutFile= THIS.FORCEEXT(oSettings.cOutFile,"SCX")
			ELSE
				m.getfname = IIF(EMPTY(ALIAS()),C_DEFFORMNAME_LOC,THIS.FORCEEXT(DBF(),"SCX"))
				IF !THIS.SaveOutFile(C_SAVEFORM_LOC,m.getfname,"SCX")
					* Note: SaveOutFile sets THIS.cOutFile property
					RETURN
				ENDIF
			ENDIF
			oSettings.cOutFile = THIS.cOutFile
		ELSE
			IF !THIS.SaveOutFile(C_SAVEFORM_LOC,THIS.FORCEEXT(DBF(),"SCX"),"SCX")
				* Note: SaveOutFile sets THIS.cOutFile property
				RETURN
			ENDIF
		ENDIF

		* Get action to perform when done processing
		IF m.lHasObj AND PEMSTATUS(m.oSettings,'nWizAction',5) AND !EMPTY(oSettings.nWizAction)
			THIS.nWizAction = oSettings.nWizAction
		ELSE
			THIS.nWizAction = 2		&&Run Form
		ENDIF
		
		* Get Form title
		DO CASE
		CASE m.lHasObj AND PEMSTATUS(m.oSettings,'cWizTitle',5) AND !EMPTY(oSettings.cWizTitle)
			THIS.cWizTitle = oSettings.cWizTitle 
		CASE EMPTY(ALIAS())
			THIS.cWizTitle = juststem(THIS.cOutFile)
		CASE !EMPTY(CURSORGETPROP("DATABASE"))
			*- if part of DBC, use DBC object name
			THIS.cWizTitle = PROPER(CURSORGETPROP("SourceName",ALIAS()))
		OTHERWISE
			THIS.cWizTitle = PROPER(ALIAS())
		ENDCASE
		
		* Set AppObjectFlag
		IF m.lHasObj AND TYPE("m.oSettings.lAddAppObject")="L"
			THIS.lAddAppObject = m.oSettings.lAddAppObject
		ENDIF		
	
		* Get style information
		IF m.lHasObj AND TYPE("m.oSettings.aWizStyles[1]")="C" AND !EMPTY(oSettings.aWizStyles)
			THIS.styleref = oSettings.aWizStyles[1,1]
			THIS.vcxref = oSettings.aWizStyles[1,2]
			THIS.coderef = oSettings.aWizStyles[2,1]
			THIS.codevcxref = oSettings.aWizStyles[2,2]
		ENDIF
		DIMENSION aStyParms[2,2]
		aStyParms[1,1] = THIS.styleref
		aStyParms[1,2] = THIS.vcxref 
		aStyParms[2,1] = THIS.coderef 
		aStyParms[2,2] = THIS.codevcxref
		
		* Initialize styles settings
		THIS.InitStyle(@aStyParms)
		IF THIS.HadError
			RETURN
		ENDIF
		
		* Read and check styles
		THIS.ReadStyle()
		IF THIS.HadError
			RETURN
		ENDIF
		
		* If no fields select, default to original form size
		IF EMPTY(THIS.aWizFields[1]) OR EMPTY(THIS.cWizAlias)
			THIS.oFormStretch = .F.
		ENDIF
		
		* Pre load processing
		THIS.InitProcess()
		IF THIS.HadError
			RETURN
		ENDIF
		
		* Create new form
		THIS.CreateForm()
		
	ENDPROC

	PROCEDURE AddAppObject
		LOCAL lcAppClassLib
		IF TYPE("THIS.NF.WizAppObject")="U" OR;
			TYPE("THIS.NF.WizAppClass")#"C" OR;
			EMPTY(THIS.NF.WizAppClass) OR;
			TYPE("THIS.NF.WizAppClassLibrary")#"C" OR;
			EMPTY(THIS.NF.WizAppClassLibrary) OR;
			!THIS.lAddAppObject
			RETURN .F.
		ENDIF
	
		IF EMPTY(THIS.NF.WizAppObject) OR TYPE("THIS.NF.WizAppObject")#"C"
			THIS.NF.WizAppObject = "APP_MEDIATOR"
		ENDIF
		
		DO CASE
		CASE FILE(THIS.NF.WizAppClassLibrary)
			lcAppClassLib = THIS.NF.WizAppClassLibrary
		CASE FILE(HOME()+"WIZARDS\"+THIS.NF.WizAppClassLibrary)
			lcAppClassLib = HOME()+"WIZARDS\"+THIS.NF.WizAppClassLibrary
		CASE FILE(HOME()+THIS.NF.WizAppClassLibrary)
			lcAppClassLib = HOME()+THIS.NF.WizAppClassLibrary
		OTHERWISE
			RETURN .F.
		ENDCASE	
		THIS.NF.Newobject(THIS.NF.WizAppObject,THIS.NF.WizAppClass,lcAppClassLib)
	ENDPROC
	
	PROCEDURE ResetStyle
		THIS.NF = ""
		THIS.STYLEFORM = ""
		IF TYPE('THIS.oStyleRef') = "O"
			THIS.REMOVEOBJECT("oStyleRef")
		ENDIF
		THIS.THERMREF=""
		
		*Misc Style properties
		THIS.nThermCurrent = 0
		THIS.nThermTotal = 	0
		THIS.nCurrCol = 1
		THIS.HadError = .F.
		THIS.oMaxChar = C_MAXCHAR		&& Max chars to convert chr->memo (default 60) 
		THIS.oLblSuffix = ":"			&& Suffix used on label		
		THIS.oLblCaps = "proper"		&& Capitalization for label
		THIS.oLblDefWid = .T.			&& Use default label width
		THIS.oFormStretch =  .T.		&& Stretch Form
		THIS.oCodeStyle = .T.			&& Whether to use code style or button style
		THIS.oWizVerify = .T.			&& Whether to check/verify style (performance enhancer)
		THIS.oWizButtons = ""			&& Name of button class
		THIS.oWizBtnPos = 0				&& Button position centering (0-none,1-hori,2-vert,3-both)
		THIS.oBtnLayout=""				&& Button position object if object used
		THIS.oWizCaptions = .T.			&& Use English DBC captions
		THIS.oWizBuffering = 5			&& Table buffering for DE
		THIS.oWizGridForm = .F.			&& Has a form in formset for using as Grid form
		THIS.oWizLblSpace = 20			&& space between label-field (used only if no wizfield container!)
		THIS.oWizCboxLbl = .F.			&& use separate lbl with checkbox

		THIS.ResetArrays()
	ENDPROC
	
	PROCEDURE ResetArrays
		DIMENSION THIS.aCodeStyles[1]	&&array of code styles
		THIS.aCodeStyles=""
		DIMENSION THIS.aGlobals[9,1]		
		THIS.aGlobals = 0
		DIMENSION THIS.aUser[1,1]		
		THIS.aUser = ""
		DIMENSION THIS.aPreMembers[1]
		THIS.aPreMembers = ""
		DIMENSION THIS.aCaptions[1]		&&DBC Caption names
		THIS.aCaptions= ""
	ENDPROC
	
	PROCEDURE ResetGrid
		** One to Many Specific properties
		DIMENSION THIS.aGridFields[1,1]
		THIS.aGridFields= ""
		DIMENSION THIS.aGridFList[1,1]
		THIS.aGridFList = ""
		DIMENSION THIS.aGridSorts[1,1]
		THIS.aGridSorts = ""
	ENDPROC

	PROCEDURE DoTherm
		LPARAMETER nPercent,cMessage,cAction
		
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
			CASE UPPER(m.cAction) = "RESET"
				THIS.nThermCurrent = 0
				THIS.nThermTotal = 	0
				THIS.ThermRef.Update(1," ")
			CASE UPPER(m.cAction) = "HIDE"
				THIS.ThermRef.visible = .f.
			CASE UPPER(m.cAction) = "SHOW"
				THIS.ThermRef.visible = .t.
			ENDCASE
			RETURN
		ENDIF
		
		* Some integrity checks
		DO CASE
		CASE !THIS.lUseTherm OR EMPTY(m.cMessage)
			RETURN
		CASE TYPE('THIS.ThermRef') # "O" AND m.nPercent = -1
			RETURN
		ENDCASE
		
		* Create thermometer first time only	
		IF TYPE('THIS.ThermRef') # "O"
			THIS.AddTherm(C_THERMHEADER_LOC)
			* No longer using Titlebar here.
			* THIS.ThermRef.Caption = THIS.cThermTitle	&& "Form Wizard"
			THIS.ThermRef.visible = .t.
			THIS.ThermWinName = THIS.ThermRef.Name
		ENDIF

		IF THIS.ThermRef.visible = .F.
			THIS.ThermRef.visible = .T.
		ENDIF

		IF THIS.nThermCurrent = 0
			THIS.nThermTotal = 	5 + ALEN(THIS.aWizFields)	&& thermometer total
		ENDIF
		
		* Done
		IF m.nPercent = -1
			THIS.ThermRef.Complete()
			THIS.ThermRef.Hide()
			RETURN
		ENDIF

		THIS.nThermCurrent = THIS.nThermCurrent + 1			&& thermometer percent

		IF	m.nPercent = 0
			m.nPercent = ROUND(THIS.nThermCurrent/THIS.nThermTotal*100,0)
		ENDIF
		m.nPercent = MIN(100,m.nPercent)
				
		*** Update thermometer
		m.cMessage = PADR(m.cMessage,40)
		THIS.ThermRef.Update(nPercent,m.cMessage)
		
	ENDPROC

	PROCEDURE InitStyle
		PARAMETER aParms
		LOCAL cVizVCX,cCodeVCX,oTmpObj
		LOCAL cTmpWizVcx
		
		IF PARAMETER()#1 OR EMPTY(aParms[1,1]) OR EMPTY(aParms[1,2])
			THIS.haderror = .T.
			RETURN
		ENDIF
	
		THIS.DOTHERM(0,THERM_STYLE_LOC)
	
		THIS.cStyName = aParms[1,1]
		
		* Check for file location
		DO CASE
		CASE EMPTY(THIS.cStyName)
			THIS.haderror = .T.
			THIS.ALERT(ERR_NOSTYLE_LOC)
		CASE EMPTY(aParms[1,2])
			THIS.haderror = .T.
			THIS.ALERT(ERR_NOSTYLEVCX_LOC)
		OTHERWISE
			m.cVizVCX = THIS.GetVCXFile(aParms[1,2])
			IF EMPTY(m.cVizVCX)
				THIS.haderror = .T.
			ENDIF
		ENDCASE
		
		IF !THIS.haderror

			SET CLASSLIB TO (m.cVizVCX) ADDITIVE
		
			* Let's always set classlib to WIZSTYLE so folks can use
			* classes in WIZSTYLE with their custom wizard
			IF ATC(WIZ_STYVCX,SET("CLASS"))=0
				cTmpWizVcx = THIS.WizLocFile(WIZ_STYVCX,C_LOCATE_LOC+LOWER(WIZ_STYVCX))
				IF !EMPTY(m.cTmpWizVcx)
					SET CLASSLIB TO (m.cTmpWizVcx) ADDITIVE			
				ENDIF
			ENDIF
			
			IF TYPE("THIS.oStyleRef") = "O"
				THIS.REMOVEOBJECT("oStyleRef")
			ENDIF
			THIS.ADDOBJECT("oStyleRef",THIS.cStyName)

			* Check to see if we have a form or formset here
			DO CASE
			CASE TYPE("THIS.oStyleRef") # "O"
				* No object created
				THIS.HadError = .T.
				RETURN
			CASE UPPER(THIS.oStyleRef.BaseClass) == "FORMSET"
				* Note: Main form must be first form in formset
				* So that we can check to see if using a 
				* separate Grid Form.
				THIS.styleform = THIS.oStyleRef.Forms[1]
			CASE UPPER(THIS.oStyleRef.BaseClass) == "FORM"
				* Good
				THIS.styleform = THIS.oStyleRef
			OTHERWISE
				THIS.HadError = .T.
			ENDCASE

		ENDIF
		
		* Check for error here to return
		IF THIS.haderror
			THIS.REMOVEOBJECT("oStyleRef")
			RETURN
		ENDIF

		THIS.ValidStyle()

		IF !EMPTY(aParms[2,1]) AND !EMPTY(aParms[2,2])
			THIS.cCodeName = aParms[2,1]
			IF aParms[2,2] # aParms[1,2]
				m.cCodeVCX = THIS.GetVCXFile(aParms[2,2])
				IF !EMPTY(m.cCodeVCX)
					IF ATC(m.cCodeVCX,SET("CLASS"))=0
						SET CLASSLIB TO (m.cCodeVCX) ADDITIVE
					ENDIF			
				ELSE
					THIS.haderror = .T.
				ENDIF
			ENDIF
		ENDIF
		
		* Check for General,Memo or Logic field in set
		THIS.FieldTypes()

		THIS.oldExact = SET("EXACT")
		SET EXACT ON
	ENDPROC
	
	PROCEDURE FieldTypes
		LOCAL i
		* Reset
		THIS.lHasGenFlds = .F.
		THIS.lHasBlobFlds = .F.
		THIS.lHasMemoFlds = .T.
		THIS.lHasLogicFlds = .F.
		FOR i = 1 TO ALEN(THIS.aWizFields)
			DO CASE
				CASE TYPE(THIS.aWizFields[m.i]) = "G"
					THIS.lHasGenFlds = .T.
				CASE TYPE(THIS.aWizFields[m.i]) = "W"
					THIS.lHasBlobFlds = .T.
				CASE TYPE(THIS.aWizFields[m.i]) = "M"
					* Since we may have char fields in excess of 
					* max, we must always create memo object
					* THIS.lHasMemoFlds = .T.
				CASE TYPE(THIS.aWizFields[m.i]) = "L"
					THIS.lHasLogicFlds = .T.
			ENDCASE
		ENDFOR
	ENDPROC
	
	PROCEDURE ReadStyle
	
		LOCAL retval,oCodeRef,aMyProps
		DIMENSION aMyProps[1]
		
		PUBLIC aWizStyleProps,aWizStyleObjs
		DIMENSION aWizStyleProps[1]		&&array of properties for style obj
		DIMENSION aWizStyleObjs[1]		&&array of objects for style obj
		=AMEMBERS(aWizStyleProps,THIS.styleform)
		=AMEMBERS(aWizStyleObjs,THIS.styleform,2)
		
		* Override verification of style to improve performance
		* Set this only after thorough testing of style.
		m.retval = THIS.getpropval(THIS.oWizVerifyRef,THIS.oWizVerify)
		THIS.oWizVerify = IIF(TYPE('m.retval')='L',m.retval,THIS.oWizVerify)

		* Verify that style is valid
		IF THIS.VerifyStyle()	&&value returned is THIS.HadError
			RETURN .F.
		ENDIF

		* Get Form height and width
		WITH THIS.styleform
			.scalemode = 3	&&make sure we have pixels
			THIS.nFormColor = .backcolor
			THIS.cFormPicture = .picture
		ENDWITH

		* Get Layout Info
		IF !THIS.LayoutInfo()
			RETURN .F.
		ENDIF
				
		* Get Max Chars per field
		m.retval = THIS.getpropval(THIS.oMaxChRef,THIS.oMaxChar)
		DO CASE
		CASE TYPE('retval') ='C'
			m.retval = 	VAL(m.retval)
		CASE AT(TYPE('m.retval'),'NF') = 0  &&invalid data type
			m.retval = THIS.oMaxChar
		ENDCASE
		THIS.oMaxChar = IIF(m.retval>0,m.retval,THIS.oMaxChar)
		
		* Get label suffix
		m.retval = THIS.getpropval(THIS.oLblSufRef,THIS.oLblSuffix)
		THIS.oLblSuffix = IIF(TYPE('m.retval')='C',m.retval,THIS.oLblSuffix)

		* Get label capitalization
		m.retval = THIS.getpropval(THIS.oLblCapRef,THIS.oLblCaps)
		THIS.oLblCaps = IIF(TYPE('m.retval')='C',m.retval,THIS.oLblCaps)
		
		* Get use default label width
		m.retval = THIS.getpropval(THIS.oLblDefWidRef,THIS.oLblDefWid)
		THIS.oLblDefWid = IIF(TYPE('m.retval')='L',m.retval,THIS.oLblDefWid)

		* Get allow form stretch
		m.retval = THIS.getpropval(THIS.oFormStretchRef,THIS.oFormStretch)
		THIS.oFormStretch= IIF(TYPE('m.retval')='L',m.retval,THIS.oFormStretch)
	
		* Get using English DBC captions
		m.retval = THIS.getpropval(THIS.oWizCaptionsRef,THIS.oWizCaptions)
		THIS.oWizCaptions = IIF(TYPE('m.retval')='L',m.retval,THIS.oWizCaptions)
	
		* Get has a secondary Grid form in formset
		m.retval = THIS.getpropval(THIS.oWizGridFormRef,THIS.oWizGridForm)
		THIS.oWizGridForm = IIF(TYPE('m.retval')='L',m.retval,THIS.oWizGridForm)

		* Table buffering for DE
		m.retval = THIS.getpropval(THIS.oWizBufferingRef,THIS.oWizBuffering)
		DO CASE
		CASE TYPE('retval') ='C'
			m.retval = 	VAL(m.retval)
		CASE TYPE('m.retval')#'N'  &&invalid data type
			m.retval = THIS.oWizBuffering
		ENDCASE		
		THIS.oWizBuffering = IIF(BETWEEN(m.retval,1,5),m.retval,THIS.oWizBuffering)
	
		* Label - Field spacing
		m.retval = THIS.getpropval(THIS.oWizLblSpaceRef,THIS.oWizLblSpace)
		DO CASE
		CASE TYPE('retval') ='C'
			m.retval = 	VAL(m.retval)
		CASE TYPE('m.retval')#'N'  &&invalid data type
			m.retval = THIS.oWizLblSpace 
		ENDCASE		
		THIS.oWizLblSpace = IIF(m.retval > 0,m.retval,THIS.oWizLblSpace)

		* Get whether to use separate label with logic field 
		* check boxes or just Checkbox caption.
		m.retval = THIS.getpropval(THIS.oWizCboxLblRef,THIS.oWizCboxLbl)
		THIS.oWizCboxLbl = IIF(TYPE('m.retval')='L',m.retval,THIS.oWizCboxLbl)
	
		* Get allow using Code Style
		m.retval = THIS.getpropval(THIS.oCodeStyleRef,THIS.oCodeStyle)
		THIS.oCodeStyle= IIF(TYPE('m.retval')='L',m.retval,THIS.oCodeStyle)

		* Get Button Layout information
		THIS.oWizBtnPos = 3 	&&default center in footer		
		IF !EMPTY(THIS.oBtnLayout)
			WITH EVAL("THIS.styleform."+THIS.oBtnLayout )
				THIS.nBtnTop = .top
				THIS.nBtnLeft =  .left
			ENDWITH
			m.retval = THIS.getpropval(THIS.oWizBtnPosRef,THIS.oWizBtnPos)
			DO CASE
			CASE TYPE('retval') ='C'
				THIS.oWizBtnPos = VAL(m.retval)
			CASE AT(TYPE('m.retval'),'N') # 0  &&valid data type
				THIS.oWizBtnPos = m.retval
			ENDCASE
		ENDIF
		
		* Now get code/button style reference info
		IF !EMPTY(THIS.cCodeName)
			m.oCodeRef = CREATE(THIS.cCodeName)
			* Check for error here!
			IF THIS.haderror
				RETURN
			ENDIF
			DO CASE
			CASE UPPER(m.oCodeRef.baseclass) # "FORM"
				* Check for normal button
				THIS.oWizButtons = THIS.cCodeName
			CASE THIS.oCodeStyle &&allows code style
				* Check for code style
				=AMEMBERS(aWizStyleProps,m.oCodeRef) 
				 
				* Check for an optional button object. Note: the button
				* set must be on form so that it can be located!!!
				=AMEMBERS(aWizStyleObjs,m.oCodeRef,2)	
				THIS.oWizButtons = THIS.getpropval(THIS.oWizButtonsRef,"")
				THIS.oWizButtons = IIF(TYPE("THIS.oWizButtons")#"C","",THIS.oWizButtons)
				IF ASCAN(aWizStyleObjs,UPPER(THIS.oWizButtons))=0
					THIS.oWizButtons = ""
				ENDIF
			ENDCASE
		ENDIF
		
		* Get Wiz Pages
		m.retval = THIS.getpropval(THIS.oWizPagesRef,THIS.oWizPages)
		DO CASE
		CASE TYPE('m.retval') ='C'
			m.retval = 	VAL(m.retval)
		CASE TYPE('m.retval')#'N'  &&invalid data type
			m.retval = THIS.oWizPages 
		ENDCASE		
		THIS.oWizPages = IIF(BETWEEN(m.retval,0,2),m.retval,THIS.oWizPages)
		IF !THIS.lUsePages 
			THIS.oWizPages = 0
		ENDIF

		* Get WizPageStyle
		m.retval = THIS.getpropval(THIS.oWizPageStyleRef,THIS.oWizPageStyle)
		THIS.oWizPageStyle = IIF(TYPE("m.retval")#'C',"",m.retval)
		
		RELEASE aWizStyleProps,aWizStyleObjs
		
	ENDPROC
	
	FUNCTION GetVCXFile
		LPARAMETER cVCXFile
		LOCAL cWizFile
		IF FILE(m.cVCXFile)
			RETURN m.cVCXFile
		ENDIF
		cWizFile = HOME()+WIZ_DIR+JustFName(m.cVCXFile)
		IF FILE(m.cWizFile)
			RETURN m.cWizFile
		ENDIF
		RETURN THIS.WizLocFile(m.cVCXFile,C_LOCATE_LOC+LOWER(THIS.JustFName(m.cVCXFile)))
	ENDFUNC
	
	FUNCTION ValidStyle
		* Quick check to see if custom defined form based on BaseForm.
		IF  TYPE('EVAL("THIS.styleform."+THIS.oWizVerifyRef)')="U"
			THIS.HADERROR = .T.
		ENDIF
		RETURN !THIS.HADERROR
	ENDFUNC

	FUNCTION getobjref
	
		LPARAMETER objref,errmess,lAllowContainer,cClassType,lAllowBoth
		LOCAL otmpobj,i,cClassName,lOldError,cBaseClass,lStyleError,aTmpArr,nTotMembers
		LOCAL lHasObject,lHasLabel
		DIMENSION aTmpArr[1]
		lOldError = THIS.haderror
		lStyleError = .F.
		lHasObject = .F.
		lHasLabel = .F.
		
		IF ASCAN(aWizStyleProps,UPPER(m.objref)) # 0

			* Test to see if Class exists
			* Note: since no rules to validate custom property type we need to check here.

			cClassName = EVAL("THIS.styleform."+m.objref)
			IF THIS.oWizVerify
	
				DO CASE
				CASE TYPE("m.cClassName")#"C" AND EMPTY(m.errmess)
					RETURN ""
				CASE TYPE("m.cClassName")#"C"
					THIS.ALERT(m.errmess)
					THIS.haderror = .T.
					RETURN ""
				CASE EMPTY(m.cClassName)
					RETURN ""
				CASE EMPTY(m.errmess) AND TYPE((m.cClassName))#"U"
					* This checks for "0" or ".F." , etc.
					THIS.SetErrorOff = .T.
				ENDCASE
				
				* only forms may contain an oleboundcontrol
				IF TYPE("m.cClassType")="C" AND (m.cClassType == THIS.oOleType)
					RETURN m.cClassName
				ENDIF
				
				otmpobj = CREATE(m.cClassName)
				
				* Check if we have a "Control" class or wrong class
				IF TYPE("otmpobj") = "O"
					cBaseClass = UPPER(otmpobj.baseclass)
					
					* Check for Control class being used
					IF ATC(m.cBaseClass,"CONTROL")#0
						lStyleError = .T.
					ENDIF
					
					IF TYPE("m.lAllowBoth") #"L"
						m.lAllowBoth = .F.
					ENDIF

					IF !m.lStyleError AND PARAMETERS() > 3
						
						* Check for containers being allowed
						DO CASE
						CASE !m.lAllowContainer AND m.cBaseClass="CONTAINER"
							lStyleError = .T.
						CASE m.lAllowContainer AND !m.lAllowBoth AND;
						  	((m.cBaseClass = "CONTAINER" AND !THIS.lUsingContainers) OR;
						  	(m.cBaseClass # "CONTAINER" AND THIS.lUsingContainers))
							lStyleError = .T.
						CASE (!m.lAllowContainer OR m.cBaseClass#"CONTAINER") AND;
						  	ATC(m.cBaseClass,m.cClassType)=0
							lStyleError = .T.
						CASE m.lAllowContainer AND m.cBaseClass="CONTAINER"
							* A container must have a label and object (cClassType)!
							nTotMembers = AMEMBERS(aTmpArr,otmpobj,2)		
							IF m.nTotMembers = 0
								lStyleError = .T.	&&empty container						
							ELSE
								FOR i = 1 TO m.nTotMembers
									m.cBaseClass = EVAL("otmpobj."+aTmpArr[m.i]+".BaseClass")
									IF ATC(m.cBaseClass,m.cClassType)#0
										lHasObject = .T.
									ENDIF
									IF ATC(m.cBaseClass,THIS.oLabelRef)#0
										lHasLabel = .T.
									ENDIF									
								ENDFOR
								IF !m.lAllowBoth AND (!m.lHasLabel OR !m.lHasObject)
									lStyleError = .T.	&&empty container							
								ENDIF
							ENDIF
						ENDCASE
					ENDIF
				ENDIF
				
				IF m.lStyleError
					THIS.haderror = .T.
					THIS.ALERT(ERR_BADSTYLE_LOC+m.objref)
					RETURN ""
				ENDIF
				
				RELEASE otmpobj
				
				THIS.SetErrorOff = .F.
			ENDIF

			* If no error message passed, then use this as flag that object is not required!
			IF EMPTY(m.errmess) AND THIS.haderror AND !m.lOldError 
				THIS.haderror = .F.
				RETURN ""
			ENDIF
			RETURN m.cClassName
			
		ENDIF
		
		* Either object not found or error occurred.
		IF !EMPTY(m.errmess)
			THIS.ALERT(m.errmess)
			THIS.haderror = .T.
		ENDIF
		
		RETURN ""

	ENDFUNC
	
	FUNCTION getpropval
		PARAMETER objref,defvalue
		IF ASCAN(aWizStyleProps,UPPER(m.objref))#0
			RETURN EVAL("THIS.styleform."+m.objref)
		ENDIF
		RETURN defvalue
	ENDFUNC

	FUNCTION VerifyStyle
		* Check for missing style reference properties
		* Note: no error returned if 2nd parm empty such as with logic and grid

		* Check Required elements first
 		** THIS.oLayout = THIS.getobjref(THIS.oLayoutRef,ERR_STY1_LOC)
		THIS.oLayout = EVAL("THIS.styleform."+THIS.oLayoutRef)

		* Get Field Object Info
		THIS.oField = THIS.getobjref(THIS.oFieldRef,ERR_STY2_LOC)
		DO CASE 
		CASE THIS.haderror
			RETURN THIS.haderror
		CASE EMPTY(THIS.oField)
			THIS.oField = THIS.oFieldType	
		CASE !THIS.FieldInfo()
			RETURN THIS.haderror
		ENDCASE
		
		* Get OLE Object Info
		* Note: Cannot created OleControl objects that
		* do not exist on forms.
		IF THIS.lHasGenFlds
			THIS.oOle = THIS.getobjref(THIS.oOleRef,ERR_STY4_LOC,.T.,THIS.oOleType)
			DO CASE
			CASE THIS.haderror
				RETURN THIS.haderror
			CASE EMPTY(THIS.oOle) AND !THIS.lUsingContainers
				THIS.oOle = THIS.oOleType
			CASE EMPTY(THIS.oOle)
				THIS.oOle = ""
			ENDCASE
		ENDIF
		
		* Get Memo Object Info
		IF THIS.lHasMemoFlds
			THIS.oMemoType = "EDITBOX"	&&reset			
			THIS.oMemo = THIS.getobjref(THIS.oMemoRef,"",.T.,THIS.oMemoType)
			DO CASE 
			CASE THIS.haderror
				RETURN THIS.haderror
			CASE EMPTY(THIS.oMemo) AND !THIS.lUsingContainers
				THIS.oMemo = THIS.oMemoType
			CASE EMPTY(THIS.oMemo)
				THIS.oMemo = THIS.oField
				THIS.oMemoType = THIS.oFieldType			
			ENDCASE
		ENDIF
		
		* Logic object - overwrite field using checkbox object
		IF THIS.lHasLogicFlds
			THIS.oLogicType = "CHECKBOX"	&&reset
			THIS.oLogic = THIS.getobjref(THIS.oLogicRef,"",.T.,THIS.oLogicType+THIS.oFieldType,.T.)
			DO CASE
			CASE THIS.haderror
				RETURN THIS.haderror
			CASE EMPTY(THIS.oLogic) AND !THIS.lUsingContainers
				THIS.oLogic = THIS.oLogicType
			CASE EMPTY(THIS.oLogic)
				THIS.oLogic = THIS.oField
				THIS.oLogicType = THIS.oFieldType
			ENDCASE
		ENDIF
				
		* Label element
		IF THIS.lUsingContainers
			THIS.oLabel = THIS.oField
		ELSE
			THIS.oLabel = THIS.getobjref(THIS.oLabelRef,"",.F.,THIS.oLabelType)
			DO CASE
			CASE THIS.haderror
				RETURN THIS.haderror
			CASE EMPTY(THIS.oLabel)
				THIS.oLabel = THIS.oLabelType
			ENDCASE
		ENDIF
	
		* Check optional elements
		
		THIS.oGrid = THIS.getobjref(THIS.oGridRef,"",.F.,THIS.oGrdType)
		IF THIS.haderror
			RETURN THIS.haderror
		ENDIF
		
		* Title object - title must exist on form for positioning.
		THIS.oTitle = THIS.getpropval(THIS.oTitleRef,"")
		IF !EMPTY(THIS.oTitle) AND ASCAN(aWizStyleObjs,UPPER(THIS.oTitle))=0
			THIS.oTitle = ""
		ENDIF
		
		* Button position object
		THIS.oBtnLayout = THIS.getobjref(THIS.oBtnLayoutRef,"")
		RETURN THIS.haderror
	ENDFUNC
	
	PROCEDURE LayoutInfo
	
		LOCAL aLayProps,aLayObjs,nTmpHgt,nLayTop,nLayLeft
		DIMENSION aLayProps[1]
		DIMENSION aLayObjs[1]
		
		* Check to make sure layout object is here
		IF ASCAN(aWizStyleObjs,UPPER(THIS.oLayout))=0
			THIS.ALERT(ERR_STY5_LOC)
			RETURN .F.
		ENDIF
		
		=AMEMBERS(aLayProps,EVAL("THIS.styleform."+THIS.oLayout))
		=AMEMBERS(aLayObjs,EVAL("THIS.styleform."+THIS.oLayout),2)

		* Check for missing layout border reference property
		IF THIS.oWizVerify
		  IF ASCAN(aLayProps,UPPER(THIS.oBorderRef)) = 0 OR ;
		    ASCAN(aLayProps,UPPER(THIS.oLblPos1Ref)) = 0 OR ;
		    ASCAN(aLayProps,UPPER(THIS.oLblPos2Ref)) = 0
			  THIS.ALERT(ERR_STY6_LOC)
			  RETURN .F.
		  ENDIF
		ENDIF
		
		THIS.oBorder  = EVAL("THIS.styleform."+THIS.oLayout+"."+THIS.oBorderRef)
		THIS.oLblPos1 = EVAL("THIS.styleform."+THIS.oLayout+"."+THIS.oLblPos1Ref)
		THIS.oLblPos2 = EVAL("THIS.styleform."+THIS.oLayout+"."+THIS.oLblPos2Ref)

		* Check for missing layout objects
		IF THIS.oWizVerify
		  IF ASCAN(aLayObjs,UPPER(THIS.oBorder)) = 0 OR ;
		   ASCAN(aLayObjs,UPPER(THIS.oLblPos1)) = 0 OR ;
		   ASCAN(aLayObjs,UPPER(THIS.oLblPos2)) = 0
			THIS.ALERT(ERR_STY7_LOC)
			RETURN .F.
		  ENDIF
		ENDIF
		
		* Check for 2nd Column reference property
		THIS.lIs1col = .T.		&&initialize
		IF ASCAN(aLayProps,UPPER(THIS.oLblCol2Ref))#0
			THIS.oLblCol2=EVAL("THIS.styleform."+THIS.oLayout+"."+THIS.oLblCol2Ref)
			IF ASCAN(aLayObjs,UPPER(THIS.oLblCol2))#0
				THIS.lIs1col = .F.		&&has 2nd column object
			ENDIF
		ENDIF
		 
		* Get border information
		WITH EVAL("THIS.styleform."+THIS.oLayout)
			m.nLayTop = .top
			m.nLayLeft =  .left
		ENDWITH

		WITH EVAL("THIS.styleform."+THIS.oLayout+"."+THIS.oborder)
			THIS.nHeader = .top + m.nLayTop 
			THIS.nFooter = .top + .height + m.nLayTop 
			THIS.nLeftMargin =  .left + m.nLayLeft
			THIS.nRightMargin = .left + .width + m.nLayLeft 
		ENDWITH
	
		* Get starting position information
		WITH EVAL("THIS.styleform."+THIS.oLayout+"."+THIS.oLblPos1)
			THIS.nLTopPos =  .top		&&label top starting position
			THIS.nLLeftPos = .left		&&label left starting position
			m.nTmpHgt = .height
		ENDWITH

		* Get label spacing information
		WITH EVAL("THIS.styleform."+THIS.oLayout+"."+THIS.oLblPos2)
			THIS.nVLblSpace = .top  - THIS.nLTopPos - m.nTmpHgt &&vertical space between labels
			THIS.nHLblSpace = .left - THIS.nLLeftPos	&&hori space between labels
		ENDWITH

		* Get 2nd Column position
		THIS.nColWidth = 0
		IF !THIS.lIs1col  
			WITH EVAL("THIS.styleform."+THIS.oLayout+"."+THIS.oLblCol2)
				THIS.nColWidth = .left - THIS.nLLeftPos 
			ENDWITH
		ENDIF

	ENDPROC
	
	PROCEDURE FieldInfo

		LOCAL i,tmpclass,oTemp,aFldObjs,nTmpleft
		LOCAL nLWidth,nFTopPos,nFLeftPos,nLblLoc,nFldLoc
		DIMENSION aFldObjs[1]

		THIS.nHSpace = THIS.oWizLblSpace
		THIS.lUsingContainers = .F.		&&initialize
		
		IF EMPTY(THIS.oField)
			RETURN
		ENDIF

		oTemp = CREATE(THIS.ofield)
		
		* Check for valid class type
		DO CASE
		CASE UPPER(oTemp.baseclass) = 'TEXTBOX'
			RETURN .T.
		CASE UPPER(oTemp.baseclass) # 'CONTAINER'
			THIS.HadError = .T.
			RETURN .F.
		ENDCASE
		
		* Determine here whether we have a valid Container class
		* containing both a label and field. Otherwise, we should
		* default to using separate fields / labels.
				
		=AMEMBERS(aFldObjs,oTemp,2)
		* Check for field and label in FieldSty
		FOR i = 1 TO ALEN(aFldObjs)
			tmpclass=EVAL("oTemp."+aFldObjs[m.i]+".BASECLASS")
			DO CASE
			CASE UPPER(m.tmpclass) = "LABEL"
				m.nLblLoc = m.i
			CASE UPPER(m.tmpclass) = "TEXTBOX"
				m.nFldLoc = m.i
			ENDCASE
		ENDFOR
		
		DO CASE
		CASE m.nLblLoc = 0
			THIS.ALERT(ERR_STY8_LOC)
			RETURN .F.
		CASE m.nFldLoc = 0
			THIS.ALERT(ERR_STY9_LOC)
			RETURN .F.
		ENDCASE
		
		* Get Label / Field positions and spacing
		WITH oTemp.&aFldObjs[m.nLblLoc]
			m.nLWidth   = .width
			m.nTmpleft = .left
		ENDWITH

		WITH oTemp.&aFldObjs[m.nFldLoc]
			m.nFTopPos =  .top	 		&&field top starting position
			m.nFLeftPos = .left 		&&field left starting position
		ENDWITH

		THIS.nHSpace = m.nFLeftPos - m.nLWidth - m.nTmpleft &&label-field horizontal space
		THIS.nVSpace = m.nFTopPos -  THIS.nLTopPos			&&label-field vertical space (fixed height label)
		THIS.oWizLblSpace = THIS.nHSpace
		THIS.lUsingContainers = .T.
		
	ENDPROC

	PROCEDURE destroy
		THIS.FormWizCleanup()
		WizEngineAll::Destroy()
	ENDPROC

	PROCEDURE initprocess
		PARAMETER oFRef,aParms
		LOCAL i,j,aTmpArr
		
		* optional 3rd parameter container for Form builder
		IF TYPE("aParms[1]")#"U"
			=ACOPY(aParms,THIS.aUser)
		ENDIF
		
		* Get output container
		THIS.GetContainer()

		THIS.cWizAlias = ALLTRIM(THIS.cWizAlias)
		THIS.CheckExclusive(THIS.cWizAlias)
		THIS.cGridAlias = ALLTRIM(THIS.cGridAlias)
		THIS.CheckExclusive(THIS.cGridAlias)

		* Check for grid object here.
		THIS.lIsGrid = !EMPTY(THIS.cGridAlias)
		IF THIS.lIsGrid	&& using 1-Many form wizard
			
			* Disallow pages for 1-Many forms 
			THIS.oWizPages = 0		

			THIS.cWizName = "mformwizard"
			IF UPPER(THIS.oStyleRef.BaseClass) # "FORMSET"
				THIS.oWizGridForm = .F.
				THIS.gridform = THIS.oStyleRef
			ENDIF			

			* See if we have separate grid form
			IF THIS.oWizGridForm AND;
			   THIS.oStyleRef.FormCount >1 AND ;
			   THIS.oWizGridForm
				
				FOR i = 2 TO ALEN(THIS.oStyleRef.Forms)
					IF UPPER(THIS.oStyleRef.Forms[m.i].BaseClass) # "FORM"
						LOOP
					ENDIF
					DIMENSION aTmpArr[1]
					IF AMEMBERS(aTmpArr,THIS.oStyleRef.Forms[m.i],2)#0
						FOR j = 1 TO ALEN(aTmpArr)
							IF UPPER(EVAL("THIS.oStyleRef.Forms[m.i]."+aTmpArr[m.j]+".BaseClass")) = "GRID"
								THIS.gridform = THIS.oStyleRef.Forms[m.i]
								THIS.gridname = aTmpArr[m.j]
								EXIT
							ENDIF	
						ENDFOR
					ENDIF
					IF TYPE("THIS.gridform") = "O"
						EXIT
					ENDIF				
				ENDFOR
				
				* Failed to find valid form with grid in formset
				IF TYPE("THIS.gridform") # "O"
					THIS.oWizGridForm = .F.				
					THIS.gridform = THIS.oStyleRef.Forms[1]
				ENDIF
			ENDIF
			
			* Failed to check formset and set grid form
			IF TYPE("THIS.gridform") # "O"
				THIS.oWizGridForm = .F.				
				THIS.gridform = THIS.NF
			ENDIF
		ENDIF

		*Starting positions
		THIS.setdims()
	ENDPROC

	PROCEDURE CheckExclusive
		PARAMETER cAlias
				
		* Check to see if tables are open exclusively
		LOCAL nSaveArea,cTableSource,i,nPos,nPos2,cDataSource 
		LOCAL cTables,aTables,nNumTables,aAllUsed

		IF EMPTY(m.cAlias) OR CURSORGETPROP('sourcetype') = 2
			RETURN
		ENDIF
		nSaveArea = SELECT()
		SELECT (m.cAlias)
		
		* Check if we have this puppy opened exclusively
		DO CASE
		CASE CURSORGETPROP('sourcetype') = 3 OR CURSORGETPROP('offline')
			* Check for a table or OFFLINE views
			IF ISEXCLUSIVE()
				cTableSource = CURSORGETPROP("sourcename")
				cDataSource = CURSORGETPROP("database")
				IF !EMPTY(m.cDataSource) AND ATC(SET("DATA"),m.cDataSource) = 0
					SET DATABASE TO (m.cDataSource)
				ENDIF
				THIS.SetErrorOff = .T.
				USE (m.cTableSource) AGAIN SHARED ALIAS (m.cAlias)
				THIS.SetErrorOff = .F.
				IF EMPTY(ALIAS())
					USE (m.cTableSource) AGAIN EXCLUSIVE ALIAS (m.cAlias)
				ENDIF
			ENDIF
		OTHERWISE
			* Check for a local view
			DIMENSION aTables[1]
			cTables = cursorgetprop('tables')
			nNumTables = OCCURS(",",m.cTables)+1
			DIMENSION aTables[m.nNumTables]
			nPos = 1
			FOR i = 1 TO (m.nNumTables-1)
				nPos2 = ATC(",",m.cTables,m.i)
				aTables[m.i] = SUBSTR(m.cTables,m.nPos,m.nPos2-m.nPos)
				nPos = nPos2+1
			ENDFOR
			aTables[ALEN(aTables)] = SUBSTR(m.cTables,m.nPos)
			DIMENSION aAllUsed[1]
			=AUSED(aAllUsed)
			FOR i = 1 TO m.nNumTables
				* Check also for bogus data in DBC which may have
				* happened during certain betas.
				IF ASCAN(aAllUsed,UPPER(aTables[m.i]))=0
					LOOP
				ENDIF
				IF ISEXCLUSIVE(aTables[m.i])
					SELECT (aTables[m.i])
					cAlias = ALIAS()
					cTableSource = CURSORGETPROP("sourcename")
					cDataSource = CURSORGETPROP("database")
					IF !EMPTY(m.cDataSource) AND ATC(SET("DATA"),m.cDataSource) = 0
						SET DATABASE TO (m.cDataSource)
					ENDIF
					USE (m.cTableSource) AGAIN SHARED ALIAS (m.cAlias)		
				ENDIF
			ENDFOR
			
		ENDCASE
		
		SELECT (m.nSaveArea)
	ENDPROC

	PROCEDURE FormWizCleanup
		IF USED("formstyles")
			USE IN formstyles
		ENDIF
		IF THIS.oldExact = "OFF"
			SET EXACT OFF
		ENDIF

		THIS.NF = ""
		THIS.GridForm = ""
		
		IF TYPE("THIS.Form1") = "O"
			THIS.REMOVEOBJECT("Form1")
		ENDIF
		
		IF TYPE("THIS.Formset1") = "O"
			THIS.REMOVEOBJECT("Formset1")
		ENDIF

		IF TYPE("THIS.oStyleRef") = "O"
			THIS.styleform = ""
			THIS.REMOVEOBJECT("oStyleRef")
		ENDIF

		RELEASE aWizStyleProps,aWizStyleObjs

	ENDPROC
	
	PROCEDURE OpenStyles
		LOCAL cStyFile
		SELECT 0
		DO CASE
		CASE USED("formstyles")
			SELECT formstyles
		CASE FILE(HOME()+WIZ_DIR+WIZ_STYDBF)
			* Use styles.dbf in wizards directory file
			USE HOME()+WIZ_DIR+WIZ_STYDBF ALIAS formstyles AGAIN SHARED
		CASE FILE(HOME()+WIZ_STYDBF)
			* Use styles.dbf in root directory file
			USE HOME()+WIZ_STYDBF ALIAS formstyles AGAIN SHARED
		OTHERWISE
			* Use styles.dbf in project file
			USE styles ALIAS formstyles AGAIN SHARED
			COPY TO (HOME()+WIZ_DIR+WIZ_STYDBF)
		ENDCASE
	ENDPROC
	
	PROCEDURE LoadFormStyles
		LOCAL oldarea,lRunningWizard,lRunningBuilder

		oldarea = SELECT()
		THIS.OpenStyles()
		
		* Bug with using THIS in SQL SELECT
		lRunningWizard = THIS.lRunningWizard
		lRunningBuilder = THIS.lRunningBuilder

		SELECT styledesc,bmpfile FROM formstyles ;
		 WHERE UPPER(styletype) = "V" AND;
		 ((m.lRunningWizard AND;
		 IIF(THIS.cWizName = "mformwizard",onemany,wizard)) OR ;
		 (m.lRunningBuilder AND builder)) ;
		 INTO ARRAY THIS.aVisStyles

		IF EMPTY(THIS.cStyle) OR ASCAN(THIS.aVisStyles,THIS.cStyle)=0
		  THIS.cStyle = THIS.aVisStyles[1]
		ENDIF
		
		SELECT styledesc FROM formstyles ;
		 WHERE INLIST(UPPER(styletype),"B","C","G") AND ;
		 ((m.lRunningWizard AND;
		 IIF(THIS.cWizName = "mformwizard",onemany,wizard)) OR ;
		  (m.lRunningBuilder AND builder)) ;
		 INTO ARRAY THIS.aCodeStyles
		
		* Get Specific Radio Button options
		LOCATE FOR UPPER(styletype) = "1"
		THIS.cCodeSty1 = ALLTRIM(styledesc)
		LOCATE FOR UPPER(styletype) = "2"
		THIS.cCodeSty2 = ALLTRIM(styledesc)
		LOCATE FOR UPPER(styletype) = "3"
		THIS.cCodeSty3 = ALLTRIM(styledesc)

		THIS.buttonstyle = STRTRAN(THIS.cCodeSty1,"\<")
		
		SELECT (m.oldarea)
	ENDPROC
	
	PROCEDURE GetFormStyle
		LOCAL oldarea
		oldarea = SELECT()
		THIS.OpenStyles()

		* Get visual style 
		LOCATE for styledesc = ALLTRIM(THIS.cStyle) ;
		  AND UPPER(styletype) = "V"
		THIS.styleref = ALLTRIM(stylename)
		THIS.vcxref = ALLTRIM(vcxfile)
		THIS.PreVisual = ALLTRIM(premethod)		&&method to run before 
		THIS.PostVisual = ALLTRIM(postmethod)	&&method to run after

		* Get code/button style -- not used for Form Builder
		LOCATE for STRTRAN(styledesc,"\<") = ALLTRIM(STRTRAN(THIS.buttonstyle,"\<"));
		  AND UPPER(styletype)#"V"
		THIS.coderef = ALLTRIM(stylename)
		THIS.codevcxref = ALLTRIM(vcxfile)
		THIS.codetype = ALLTRIM(styletype)
		THIS.PreCode = ALLTRIM(premethod)	&&method to run before
		THIS.PostCode = ALLTRIM(postmethod)	&&method to run after
		
		SELECT (m.oldarea)
	ENDPROC
	
	PROCEDURE setdims
		* setup dimensions
		THIS.nVLPOS = THIS.nLTopPos + THIS.nHeader		&&current vert pos for lbl placement
		THIS.nHLPOS = THIS.nLLeftPos + THIS.nLeftMargin	&&current hori pos for lbl placement
		THIS.nVINC  = 0
		THIS.nHINC  = THIS.nHLblSpace
		THIS.nCurrCol = 1
		THIS.cThermTitle = C_THERMTITLEWIZ_LOC
		THIS.nRightEdge = THIS.nRightMargin
		THIS.nMaxCols = IIF(THIS.lIs1col,1,THIS.nCols)
		THIS.nColWidth = IIF(THIS.lIs1col,0,THIS.nColWidth)
		THIS.nFrmStartHgt = THIS.nf.Height
		THIS.GetScrnRes()
		THIS.nBottom = IIF(!THIS.oFormStretch,THIS.nFooter,THIS.nVertRes-THIS.nf.height+THIS.nFooter)
	ENDPROC
	
	PROCEDURE GetScrnRes
		LOCAL oReg,cResWidValue,cResHgtValue,nErrNum
		
		IF _mac
			*- not applicable
			RETURN
		ENDIF
		
		STORE "" TO cResWidValue,cResHgtValue
		STORE 0 TO nErrNum
		IF !("REGISTRY" $ SET("CLASS"))
			SET CLASSLIB TO Registry ADDITIVE
		ENDIF
		oReg = CREATEOBJ('FoxReg')

		* Get ResWidth setting
		m.nErrNum = oReg.GetFoxOption(C_RESWIDTH,@cResWidValue)  
		cResWidValue = IIF(m.nErrNum=0,VAL(m.cResWidValue),SYSMETRIC(1))
			
		* Get ResHeight setting
		m.nErrNum = oReg.GetFoxOption(C_RESHEIGHT,@cResHgtValue)  
		cResHgtValue = IIF(m.nErrNum=0,VAL(m.cResHgtValue),SYSMETRIC(2))

		* RMK - reset these to maximums
		THIS.nVertRes = 480				&& vertical resolution (VGA - 480)
		THIS.nHoriRes = 640				&& horizontal resolution (VGA - 640)

		THIS.nHoriRes = MAX(THIS.nHoriRes, m.cResWidValue) - THIS.nHoriAdj		&& horizontal resolution (VGA - 640)
		THIS.nVertRes = MAX(THIS.nVertRes, m.cResHgtValue) - THIS.nVertAdj		&& vertical resolution (VGA - 480)
	ENDPROC

	PROCEDURE CreateForm
		LOCAL tmpnf
	
		IF !("REGISTRY" $ SET("CLASS"))
			SET CLASSLIB TO Registry ADDITIVE
		ENDIF
		THIS.oReg = CREATE("registry")
		
		* Form setup and creation methods
		THIS.PreProcess
		THIS.FormSetup		&&has DoTherm
		THIS.SetHeader
		
		* Add fields and grids to form
		tmpnf = THIS.NF 		&&restore later if using Pages
		THIS.AddDetail		&&has DoTherm
		THIS.AddGrid
		THIS.NF = m.tmpnf		&&restore if using Pages
	
		* Form cleanup
		THIS.SetFooter
		THIS.AddCodeBtns
		THIS.FormCleanup
		THIS.PostProcess
		
		* Form Output action
		THIS.OutputAction	&&has DoTherm And DataEnvironment
		
	ENDPROC
	
	PROCEDURE OutputAction
		LOCAL cOldSafe,cNewFile,loldClose,nSaveWType
		LOCAL noldWinType,cTagName,i,cTmpKey,oFormTmpRef 
		m.cNewFile = THIS.cOutFile
		m.cOldSafe = SET('SAFE')
		SET SAFE OFF

		* Check if preview here
		IF THIS.nWizAction = 0

			IF THIS.lIsGrid
				* See if we can set a relation here
				SELECT (THIS.cGridAlias)
				m.cTagName = ""
				FOR i = 1 TO TagCount()
					IF UPPER(KEY(m.i)) == UPPER(THIS.cRelatedKey)
						m.cTagName = TAG(m.i)
						EXIT
					ENDIF
				ENDFOR
				SELECT (THIS.cWizAlias)
				IF !EMPTY(m.cTagName)
					SET ORDER TO (m.cTagName) IN (THIS.cGridAlias)
					cTmpKey = THIS.cMainKey
					SET RELATION TO &cTmpKey INTO (THIS.cGridAlias)
					GOTO TOP
				ENDIF
			ENDIF
			
			THIS.NF.ADDOBJECT("retwiz","cmdRetWiz")
			THIS.NF.RETWIZ.VISIBLE = .T.
			THIS.NF.RETWIZ.TOP = 2
			THIS.NF.RETWIZ.LEFT = (THIS.NF.WIDTH-THIS.NF.RETWIZ.WIDTH)/2
			
			m.loldClose = THIS.NF.CLOSABLE
			m.noldWinType = THIS.NF.WINDOWTYPE
			THIS.NF.WINDOWTYPE = 1
			THIS.NF.CLOSABLE = .F. 
		
			IF TYPE("THIS.NF.ButtonSet1.PreviewMode") # "U"
				THIS.NF.ButtonSet1.PreviewMode = .T.
			ENDIF
			IF TYPE("THIS.NF.ButtonSet1.PreviewInit") # "U"
				THIS.NF.ButtonSet1.PreviewInit = .T.
			ENDIF

			THIS.DoTherm(0,"","HIDE")
			
			* Show form for preview
			IF UPPER(THIS.oStyleRef.Baseclass) == "FORMSET"
				m.nSaveWType = THIS.NF.Parent.WindowType				
				THIS.NF.Parent.WindowType = 1
				THIS.NF.Parent.Refresh()
				THIS.NF.Parent.Visible = .T.
			ELSE
				THIS.NF.AutoCenter = THIS.NF.AutoCenter
				THIS.NF.Refresh()
				THIS.NF.Show()
			ENDIF
			
			
			IF TYPE("THIS.NF")="O" AND !ISNULL(THIS.NF)  &&form somehow released during preview
			
				* Make sure window is not visible
				IF THIS.NF.VISIBLE
					THIS.NF.VISIBLE = .F.
				ENDIF

				IF TYPE("THIS.NF.ButtonSet1") = "O"	
					THIS.NF.BUTTONSET1.SETALL("Enabled",.T.,"CommandButton")
				ENDIF
				THIS.NF.REMOVEOBJECT("retwiz")
				
				THIS.NF.WINDOWTYPE = m.noldWinType
				THIS.NF.CLOSABLE = m.loldClose
				IF UPPER(THIS.oStyleRef.Baseclass) == "FORMSET"
					THIS.NF.Parent.Hide()
					THIS.NF.Parent.WindowType = m.nSaveWType 
				ENDIF	
			ENDIF
			IF TYPE("THIS.ThermRef") = "O"
				THIS.ThermRef = ""
			ENDIF
			RETURN
		ENDIF preview
	
		** Output action here if NOT preview!!!
			
		THIS.ADD_DataEnv()
		
		THIS.DoTherm(0,THERM_SAVE_LOC)
		
		* Make sure we reset PreviewMode when saving form
		IF TYPE("THIS.NF.ButtonSet1.PreviewMode") # "U"
			THIS.NF.ButtonSet1.PreviewMode = .F.
		ENDIF
		
		IF THIS.lIsGrid 
			* Need to do this because Grid resets columns if bound table closed
			* and reopened (AddCdxTag).
			THIS.setgridfields()
		ENDIF

		THIS.AddAppObject()
		
		DO CASE
		CASE UPPER(THIS.oStyleRef.Baseclass) == "FORM"
			THIS.NF.Name = "Form1"
			m.oFormTmpRef = THIS.NF
		CASE UPPER(THIS.oStyleRef.Baseclass) == "FORMSET"
			THIS.NF.Parent.Name = "Formset1"
			m.oFormTmpRef = THIS.NF.Parent		
		ENDCASE
		
		* Reset readonly property in case preview form with
		* txtbtns had it enabled.
		oFormTmpRef.SetAll("ReadOnly",.F.)
		oFormTmpRef.Move(-5000)
		oFormTmpRef.ResetToDefault("LockScreen")
		oFormTmpRef.ResetToDefault("Visible")

		* See if we have a DataEnv here
		IF TYPE("THIS.DataEnvRef") = "O"
			* Set Datasessions ON -- use Baseform setting
			m.oFormTmpRef.saveas(m.cNewFile,THIS.DataEnvRef)
		ELSE
			m.oFormTmpRef.saveas(m.cNewFile)
		ENDIF
		oFormTmpRef.lSaveBufferedData = .F.
		oFormTmpRef.Release()
		
		* Reset so that when wizard is released buttonset Destroy event
		* doesn't mess things up.
		IF TYPE("THIS.NF.ButtonSet1.PreviewMode") # "U"
			THIS.NF.BUTTONSET1.PREVIEWMODE = .T.
		ENDIF

		SET SAFE &cOldSafe
		
		* Add extra quotes here for Mac paths.
		m.cNewFile = [']+m.cNewFile+[']

		DO CASE
		CASE THIS.nWizAction = 2
			_SHELL = [DO FORM &cNewFile]
		CASE THIS.nWizAction = 3
			_SHELL = [MODIFY FORM &cNewFile NOWAIT]
		ENDCASE
				
		* End of Form Engine
		THIS.DoTherm(-1,THERM_DONE_LOC)
	
	ENDPROC

	PROCEDURE Add_DataEnv
		LOCAL cTagName,lHasView,i,temprecsrc 

		THIS.DoTherm(0,THERM_INDEX_LOC)
		
		IF EMPTY(THIS.cWizAlias)
			RETURN
		ENDIF
		
		* Add parent sort index tag if needed
		SELECT (THIS.cWizAlias)
		IF !EMPTY(THIS.aWizSorts[1])
			IF THIS.lHasSortTag
				m.cTagName = THIS.aWizSorts[1]
			ELSE
				IF TYPE("THIS.nf.WizScrollGrid1") =  "O"
					* AddCdxTag resets grid columns since a table is opened excl
					* to create index tag. This saves and restores columns.
					temprecsrc = THIS.nf.WizScrollGrid1.recordsource
					THIS.nf.WizScrollGrid1.recordsource = ""
					m.cTagName = THIS.AddCdxTag("aWizSorts","aWizFList")
					THIS.nf.WizScrollGrid1.recordsource = m.temprecsrc
				ELSE
					m.cTagName = THIS.AddCdxTag("aWizSorts","aWizFList")
				ENDIF
			ENDIF
		ENDIF
		
		* Add DataEnvironment record
		THIS.DataEnvRef  = CREATE("DataEnvironment")
		
		* Add Parent Cursor record
		THIS.DataEnvRef.ADDOBJECT("cursor1","cursor")
		WITH THIS.DataEnvRef.Cursor1
			.Alias = LOWER(THIS.cWizAlias)
			IF EMPTY(THIS.cDBCName)
				.CursorSource = LOWER(DBF())
			ELSE
				.Database = LOWER(THIS.cDBCName)
				.CursorSource = LOWER(THIS.cDBCTable)
			ENDIF
			IF TYPE("m.cTagName")="C" AND !EMPTY(m.cTagName)
				.order = LOWER(m.cTagName)
			ENDIF
			.BufferModeOverride = THIS.oWizBuffering
		ENDWITH
				
		IF THIS.lIsGrid
			* Must have a tag set here!!! for relation
			SELECT (THIS.cGridAlias)

			* Add DataEnvironment Cursor record
			THIS.DataEnvRef.ADDOBJECT('cursor2','cursor')
			WITH THIS.DataEnvRef.Cursor2
				.Alias = LOWER(THIS.cGridAlias)
				IF EMPTY(THIS.cGridDBCName)
					.CursorSource = LOWER(DBF())
				ELSE
					.Database = LOWER(THIS.cGridDBCName)
					.CursorSource = LOWER(THIS.cGridDBCTable)
				ENDIF
				.BufferModeOverride = THIS.oWizBuffering
			ENDWITH
			
			* Check if we have a view selected as Grid Alias
			lHasView = CURSORGETPROP('sourcetype')#3
			
			IF !m.lHasView
				* Scan for tag name, else create it
				m.cTagName = ""
				FOR i = 1 TO TagCount()
					IF UPPER(KEY(m.i)) == UPPER(THIS.cRelatedKey)
						m.cTagName = TAG(m.i)
						EXIT
					ENDIF
				ENDFOR
				
				* Failed to find existing tag, create new one.
				IF EMPTY(m.cTagName)
					THIS.aGridSorts[1,1] = THIS.cRelatedKey
					m.cTagName = THIS.AddCdxTag("aGridSorts","aGridFList")
				ENDIF
				
				THIS.DataEnvRef.ADDOBJECT('relation1','relation')
				WITH THIS.DataEnvRef.Relation1
					.ParentAlias = LOWER(THIS.cWizAlias)
					.ChildAlias = LOWER(THIS.cGridAlias)
					.ChildOrder = LOWER(m.cTagName)
					
					.RelationalExpr = LOWER(THIS.cMainKey)
							
				ENDWITH
			ENDIF
			
			SELECT (THIS.cWizAlias)
			GO TOP
		ENDIF
		 
	ENDPROC

	PROCEDURE SetupObj
		PARAMETER cNewname,cClassName,styrefname,controltype
		LOCAL aTmparr
		DIMENSION aTmparr[1]
		* Check if this member already exists
		IF TYPE('EVAL("THIS."+m.cNewname)') = "O"
			THIS.REMOVEOBJECT(m.cNewname)			
		ENDIF
		THIS.ADDOBJECT(m.cNewname,m.cClassName)
		IF !EMPTY(m.styrefname)
			=ACOPY(THIS.aGlobals,aTmparr)
			THIS.&cNewname..setname(m.styrefname)
			THIS.&cNewname..setglobals(@aTmparr)
			THIS.&cNewname..setobjs(m.controltype,(m.controltype=THIS.oOleType))
		ENDIF
	ENDPROC

	PROCEDURE GetContainer

		THIS.nf = THIS.styleform
		THIS.nf.scalemode = 3
		=AMEMBERS(THIS.aPreMembers,THIS.nf,2)
		
	ENDPROC
	
	PROTECTED PROCEDURE GetCaps
		PARAMETER cFieldCaption
		LOCAL ctmpCaption
		DO CASE
		CASE UPPER(THIS.oLblCaps) = "NORMAL"
			ctmpCaption = m.cFieldCaption
		CASE UPPER(THIS.oLblCaps) = "UPPER"
			ctmpCaption = UPPER(m.cFieldCaption)
		CASE UPPER(THIS.oLblCaps) = "LOWER" 
			ctmpCaption = LOWER(m.cFieldCaption)
		OTHERWISE
			ctmpCaption = PROPER(m.cFieldCaption)
		ENDCASE
		RETURN m.ctmpCaption
	ENDPROC
	
	PROCEDURE GetCaptions
		LOCAL i,cTmpCaption
		IF EMPTY(THIS.aWizFields)
			RETURN
		ENDIF	
		=ACOPY(THIS.aWizFields,THIS.aCaptions)

		* Get label capitalization
		FOR i = 1 TO ALEN(THIS.aCaptions)
			THIS.aCaptions[m.i] = THIS.GetCaps(THIS.aCaptions[m.i])
		ENDFOR

		* Skip if WizCaptions = .F.
		IF !THIS.oWizCaptions
			RETURN
		ENDIF

		IF !EMPTY(THIS.cDBCName)
			FOR i = 1 TO ALEN(THIS.aCaptions)
				m.cTmpCaption = dbgetprop(THIS.cDBCTable+"."+THIS.aCaptions[m.i],'field','caption')
				IF !EMPTY(m.cTmpCaption)
					THIS.aCaptions[m.i] = m.cTmpCaption
				ENDIF
			ENDFOR
		ENDIF
	ENDPROC
	
	PROCEDURE FormSetup
		LOCAL tmpArr1
		DIMENSION tmpArr1[1]
		
		THIS.DoTherm(0,THERM_CREATE_LOC)
		THIS.nf.scalemode = 3
		
		* Set title of form
		IF !EMPTY(THIS.cWizTitle)
			THIS.nf.caption = STRTRAN(THIS.cWizTitle,'"',CHR(34))
		ENDIF
		
		* Get English Captions
		THIS.GetCaptions()
		
		* Set up global array to pass to objects
		THIS.aGlobals[3] = THIS.oLblSuffix
		THIS.aGlobals[4] = THIS.oLblCaps
		THIS.aGlobals[5] = THIS.nHSpace
		THIS.aGlobals[6] = THIS.oLblDefWid
		THIS.aGlobals[7] = THIS.cWizAlias
		THIS.aGlobals[8] = THIS.lOverrideStyle
		THIS.aGlobals[9] = THIS.lUseFieldMappings
		
		* Initialize label object

		THIS.SetupObj("labelrec","labeldata",THIS.oLabel,"LABEL")

		=ACOPY(THIS.aCaptions,tmparr1)
		THIS.nDefLblWid = THIS.labelrec.GetLblWid(@tmparr1,THIS.oLblSuffix)
		THIS.aGlobals[1] = THIS.nDefLblWid
		THIS.aGlobals[2] = THIS.nDefLblWid - THIS.labelrec.nNewFieldWid
		
		* Initialize character field data types
		THIS.SetupObj("ocType","charflds",THIS.ofield,THIS.oFieldType)

		* Initialize logic field data types (checkboxes)
		IF THIS.lHasLogicFlds AND THIS.oLogic # THIS.oField
			THIS.SetupObj("olType","logicflds",THIS.oLogic,THIS.oLogicType)
			IF TYPE("THIS.olType.lCheckBox") # "U"
				THIS.lUsingCheckBoxes = .T.
			ENDIF
		ENDIF
		
		* Initialize memo field data types
		IF THIS.lHasMemoFlds OR THIS.lHasBlobFlds
			THIS.SetupObj("omType","memoflds",THIS.oMemo,THIS.oMemoType)
		ENDIF
		
		* Initialize general field data types
		IF THIS.lHasGenFlds
			THIS.SetupObj("ogType","genflds",THIS.oOle,THIS.oOleType)
		ENDIF

		
		* Initialize grid object type
		IF THIS.lIsGrid
			THIS.SetupObj("ogridType","gridflds",THIS.oGrid,THIS.oGrdType)
		ENDIF
		
		* Check to see if single column fields or if exceed form
		THIS.CheckFields()

	ENDPROC
	
	PROCEDURE SetHeader
		* Handle titles and any information in header
		LOCAL nFont6,cFStyle
		IF	!EMPTY(THIS.oTitle)
			WITH EVAL("THIS.nf."+THIS.oTitle)
				m.cFStyle = THIS.GETSTYLE(.fontbold,.fontitalic,.fontunderline)
				m.nFont6= FONT(6,.fontname,.fontsize,m.cfstyle)	&& Font 6 conversion factor
				.CAPTION = STRTRAN(THIS.cWizTitle,'"',CHR(34))
				.WIDTH = TXTWIDTH(STRTRAN(THIS.cWizTitle,'"',CHR(34)),;
					.fontname,.fontsize,m.cFStyle)*m.nFont6+;
					FONT(18,.fontname,.fontsize,m.cFStyle)				
			ENDWITH
		ENDIF
	ENDPROC
	
	FUNCTION GetObjectName
		* Gets a unique object name
		PARAMETER cObjPrefix
		LOCAL cNewFld,i
		i = 1
		DO WHILE .T.
			cNewFld = IIF(TYPE("m.cObjPrefix")="C",m.cObjPrefix,"") +;
				 PROPER(THIS.cFieldName) + ALLTRIM(STR(m.i))
			IF TYPE("EVAL('THIS.nf.'+m.cNewFld)") # "O"
				EXIT
			ENDI
			i = m.i + 1
		ENDDO
		RETURN m.cNewFld	&&prevents a potential name conflict
	ENDFUNC

	PROCEDURE AddScrollGrid
		LOCAL nCon, i
		nCon = 0
		THIS.oWizPages = 0
		THIS.nVLPOS = THIS.nLTopPos + 0  && a little extra buffer
		THIS.nHLPOS = THIS.nLLeftPos
		THIS.oFormStretch = .F.
		THIS.nBottom = THIS.nFooter
		THIS.NF.ADDOBJECT("WizScrollGrid1",this.cCodeName)
		* Check for button style on grid
		IF TYPE("THIS.NF.WizScrollGrid1.WizBtnStyle")="C" AND; 
		  !EMPTY(THIS.NF.WizScrollGrid1.WizBtnStyle)
			THIS.oWizButtons = THIS.NF.WizScrollGrid1.WizBtnStyle
		ELSE
			THIS.oWizButtons = ""
		ENDIF

		IF THIS.NF.WizScrollGrid1.ColumnCount = -1
			THIS.NF.WizScrollGrid1.ColumnCount = 1
		ENDIF
		FOR i = 1 TO THIS.NF.WizScrollGrid1.Columns[1].ControlCount
			IF LOWER(THIS.NF.WizScrollGrid1.Columns[1].Controls[m.i].BaseClass) = "container"
				nCon = m.i
				EXIT
			ENDIF
		ENDFOR
		WITH THIS.NF.WizScrollGrid1
			.LEFT = THIS.nLeftMargin
			.TOP = THIS.nHeader
			.WIDTH = THIS.nRightMargin - THIS.nLeftMargin
			.HEIGHT = THIS.nFooter - THIS.nHeader
			.ROWHEIGHT = .HEIGHT
			.COLUMNS[1].WIDTH= .WIDTH - 16
			.COLUMNS[1].CONTROLS[m.nCon].LEFT =  0
			.COLUMNS[1].CONTROLS[m.nCon].TOP =  0
			.COLUMNS[1].CONTROLS[m.nCon].WIDTH =  .WIDTH - 20
			.COLUMNS[1].CONTROLS[m.nCon].HEIGHT =  .HEIGHT
			.VISIBLE = .T.
		ENDWITH
		THIS.NF = THIS.NF.WizScrollGrid1.Columns[1].CONTROLS[m.nCon]
		THIS.nRightEdge = THIS.nRightEdge - 22
	ENDPROC

	PROCEDURE AddPages
		THIS.lIs1Col = (THIS.oWizPages = 1)
		THIS.nVLPOS = THIS.nLTopPos + 4 &&little extra buffer
		THIS.nVINC = 0
		THIS.nHINC  = THIS.nHLblSpace
		THIS.nHLPOS = THIS.nLLeftPos
		THIS.nCurrCol = 1
		THIS.oFormStretch = .F.
		THIS.nBottom = THIS.nFooter
		THIS.NF.ADDOBJECT("WizFrame1",IIF(EMPTY(THIS.oWizPageStyle),"PageFrame",THIS.oWizPageStyle))
		WITH THIS.NF.WizFrame1
			.LEFT = THIS.nLeftMargin
			.TOP = THIS.nHeader
			.WIDTH = THIS.nRightMargin - THIS.nLeftMargin
			.HEIGHT = THIS.nFooter - THIS.nHeader
			* Reset only if not using page style
			IF EMPTY(THIS.oWizPageStyle)
				.PAGECOUNT = 1
			ENDIF
			.VISIBLE = .T.
		ENDWITH
		THIS.NF = THIS.NF.WizFrame1.Pages[1]
		IF EMPTY(THIS.oWizPageStyle)
			* Reset only if not using page style
			THIS.NF.FontName = THIS.LabelRec.cfont
			THIS.NF.FontSize = THIS.LabelRec.nfsize
		ENDIF
	ENDPROC
	
	PROCEDURE AddDetail

		LOCAL ii,nPos,tmparr,nTmpWid,aDetail,tmpnf,saveRef,nSavePages,nPageNum 
		LOCAL cObjName,cObjName2,oTmpRef,oTmpRef2,lUsingClone,lExceedPage
		LOCAL m.cTempNewObjRef, m.cTempNewLabelObjRef, m.cTempOldLabelRef, m.lTempUsingContainers
		LOCAL cNewLabelRef, lContainer, cTempNewLabelObjClassLib, cxsmessage, lnNumFields
		LOCAL cDisplayClassLibrary, cDisplayClass, cType, cRegKey, cIntelliClass

		DIMENSION tmparr[1]
		ACOPY(THIS.aWizFList,tmparr)		
		lnNumFields = ALEN(THIS.aWizFList,2)
		IF lnNumFields = 0
			lnNumFields = NUM_AFIELDS
		ENDIF
		DIMENSION aDetail[lnNumFields, 1]
		
		nSavePages = 0
		lExceedPage = .F.
		lUsingClone = .T.
		IF THIS.lIs1Col		&& single column
			THIS.oWizPages = 0
		ENDIF

		DO CASE
			CASE UPPER(THIS.CodeType) = "G"
				* Scrolling grid style
				m.lUsingClone = .F.
				THIS.oWizPages = 0
				THIS.AddScrollGrid
			CASE THIS.oWizPages = 0
				m.lUsingClone = .F.
			CASE THIS.oWizPages # 0 AND m.lUsingClone
				* Create a temporary form here to test for fitting on pages
				saveRef = THIS.NF
				THIS.ADDOBJECT("oStyleRef2",THIS.cStyName)
				THIS.NF = THIS.oStyleRef2
				nSavePages = THIS.oWizPages
				THIS.oWizPages = 0
			OTHERWISE
		ENDCASE

		FOR ii = 1 TO ALEN(THIS.aWizFields,1)
			IF EMPTY(THIS.aWizFields[m.ii])
	   		 	EXIT
	  		ENDIF
	  		IF !m.lUsingClone 
				THIS.DoTherm(0,THERM_DETAIL_LOC)
	  		ENDIF
	  		THIS.cFieldName = UPPER(THIS.aWizFields[m.ii])
	  		m.nPos = THIS.ACOLSCAN(@tmparr,THIS.cFieldName,1,.T.)
	  		
			IF m.nPos = 0	&& safety exit -- should never happen
				EXIT
			ENDIF
	    
			* Copy AFIELDS array elements to aDetail array
			=ACOPY(tmparr,aDetail,AELEMENT(tmparr,m.nPos,1),lnNumFields)
		    
			* Get object and if not available skip it
			m.oCurObj = THIS.gettypeobj(@aDetail)
			IF ISNULL(m.oCurObj) OR EMPTY(m.oCurObj.cNewObjectRef)   
				LOOP
			ENDIF

			* Get new object and set properties
			cObjName = THIS.GetObjectName()
			*- determine if there is a display class for this field in the DBC, and if so, use it
			cTempNewObjRef = m.oCurObj.cNewObjectRef
			cTempNewLabelObjRef = THIS.labelrec.cNewObjectRef
			m.lTempUsingContainers = THIS.lUsingContainers
			cNewLabelRef = m.oCurObj.cNewLabelRef
			lContainer = m.oCurObj.lContainer

			cDisplayClassLibrary = ""
			cDisplayClass = ""
			
			*- if user also wants to override styles with display class stored in DBC, check that first
			*- if user wants to use field mappings stored in registry,
			*- only use that if display class is empty for that field type
			IF !EMPTY(THIS.cDBCName) AND THIS.lOverrideStyle
				cDisplayClassLibrary = DBGETPROP(THIS.cDBCTable + "." + aDetail[1],"FIELD","DisplayClassLibrary")
				cDisplayClass = DBGETPROP(THIS.cDBCTable + "." + aDetail[1],"FIELD","DisplayClass")
			ENDIF
			
			IF THIS.lUseFieldMappings AND EMPTY(cDisplayClass)
				*- determine field type/key
				m.cType = aDetail[2]
				DO CASE
					CASE m.cType = 'C' AND aDetail[6]
						cIntelliClass = 'Character (binary)'
					CASE m.cType = 'C'
						cIntelliClass = 'Character'
					CASE m.cType = 'D'
						cIntelliClass = 'Date'
					CASE m.cType = 'L'
						cIntelliClass = 'Logical'
					CASE m.cType = 'M' AND aDetail[6]
						cIntelliClass = 'Memo (binary)'
					CASE m.cType = 'M'
						cIntelliClass = 'Memo'
					CASE m.cType = 'N'
						cIntelliClass = 'Numeric'
					CASE m.cType = 'F'
						cIntelliClass = 'Float'
					CASE m.cType = 'I'
						cIntelliClass = 'Integer'
					CASE m.cType = 'B'
						cIntelliClass = 'Double'
					CASE m.cType = 'Y'
						cIntelliClass = 'Currency'
					CASE m.cType = 'T'
						cIntelliClass = 'DateTime'
					CASE m.cType = 'G'
						cIntelliClass = 'General'
					*- multiple objects: 'Multiple'
					OTHERWISE
						cIntelliClass = ""
				ENDCASE
				
				IF !EMPTY(m.cIntelliClass)
					m.errnum = THIS.oReg.GetRegKey("ClassLocation",@cDisplayClassLibrary, VFP_INTELLIDROP_KEY + m.cIntelliClass, HKEY_CURRENT_USER)
					IF m.errnum == ERROR_SUCCESS
						m.errnum = THIS.oReg.GetRegKey("ClassName",@cDisplayClass, VFP_INTELLIDROP_KEY + m.cIntelliClass, HKEY_CURRENT_USER)
					ENDIF
				
					*- should we override label class too?
					cTempNewLabelObjClassLib = ""
					m.errnum = THIS.oReg.GetRegKey("ClassLocation",@cTempNewLabelObjClassLib, VFP_INTELLIDROP_KEY + "Label", HKEY_CURRENT_USER)
					IF m.errnum == ERROR_SUCCESS
						m.errnum = THIS.oReg.GetRegKey("ClassName",@cTempNewLabelObjRef, VFP_INTELLIDROP_KEY +  "Label", HKEY_CURRENT_USER)
					ENDIF
				ENDIF
			ENDIF
			
*			IF (THIS.lUseFieldMappings OR (!EMPTY(THIS.cDBCName) AND THIS.lOverrideStyle))
			IF !EMPTY(m.cDisplayClass)
				*- add class to open class list if not there already
				IF !EMPTY(m.cDisplayClassLibrary) AND FILE(m.cDisplayClassLibrary)
					IF !(UPPER(cDisplayClassLibrary) $ SET("CLASS"))
						SET CLASSLIB TO (m.cDisplayClassLibrary) ADDITIVE
					ENDIF
				ENDIF
				cTempNewObjRef = m.cDisplayClass
				
				*- ignore container info if we are overriding the class
				IF m.lTempUsingContainers
					cTempNewLabelObjRef = "StandardLabel"
					THIS.lUsingContainers = .F. && m.lTempUsingContainers = .F.
				ENDIF
			ENDIF

			IF THIS.lUsingContainers && m.lTempUsingContainers
				*- THIS.nf.ADDOBJECT(PROPER(m.cObjName),m.oCurObj.cNewObjectRef)
				THIS.nf.ADDOBJECT(PROPER(m.cObjName), m.cTempNewObjRef)
				m.oTmpRef = EVAL("THIS.nf."+m.cObjName)
				m.oCurObj.SetProps(@oTmpRef,@aDetail,THIS.aCaptions[m.ii])

				* Set new object coordinates -- this is for Containers
				WITH m.oTmpRef
					.TOP = THIS.GetNextVPOS(.WIDTH)
					.LEFT = THIS.GetNextHPOS(.WIDTH)
					.VISIBLE = .T.
				ENDWITH
			ELSE
				* Add label object
				IF aDetail[2]#"L" or !THIS.lUsingCheckBoxes or THIS.oWizCboxLbl
					cObjName2 =  THIS.GetObjectName("lbl")
					THIS.nf.ADDOBJECT(m.cObjName2,cTempNewLabelObjRef)
					m.oTmpRef = EVAL("THIS.nf."+m.cObjName2)
					THIS.labelrec.SetProps(@oTmpRef,@aDetail,THIS.aCaptions[m.ii])
				ENDIF
				
				* Add field object		
				THIS.nf.ADDOBJECT(PROPER(m.cObjName), m.cTempNewObjRef)
				m.oTmpRef2 = EVAL("THIS.nf."+m.cObjName)
				
				IF m.lTempUsingContainers
					*- we are overriding a "container" type class, so hide label ref
					m.oCurObj.cNewLabelRef = ""
					m.oCurObj.lContainer = .F.
				ENDIF
				
				m.oCurObj.SetProps(@oTmpRef2,@aDetail,THIS.aCaptions[m.ii])

				IF aDetail[2]="L" AND !THIS.oWizCboxLbl AND THIS.lUsingCheckBoxes 
					WITH m.oTmpRef2
						.TOP = THIS.GetNextVPOS(.width)
						.LEFT = THIS.GetNextHPOS(.width)
						.VISIBLE = .T.
					ENDWITH
				ELSE
					nTmpWid = m.oTmpRef.Width + m.oTmpRef2.Width + This.oWizLblSpace
					WITH m.oTmpRef
						.TOP = THIS.GetNextVPOS(m.nTmpWid)
						.LEFT = THIS.GetNextHPOS(m.nTmpWid)
						.VISIBLE = .T.
					ENDWITH
					WITH m.oTmpRef2
						.TOP = m.oTmpRef.Top
						* Make minor adjustments to 
						DO CASE
						CASE aDetail[2]="L" AND THIS.lUsingCheckBoxes
							.CAPTION = ""
							.AUTOSIZE = .T.
						CASE TYPE(".BorderStyle")#"U" AND .BorderStyle = 0	&&no border
							.TOP = .Top - 2
						CASE TYPE(".SpecialEffect")#"U" AND .SpecialEffect = 1	&&plain border
							.TOP = .Top - 3
						CASE TYPE(".SpecialEffect")#"U" AND .SpecialEffect = 0	&&3D border
							.TOP = .Top - 4
						ENDCASE
						.LEFT = m.oTmpRef.Left+m.oTmpRef.Width+This.oWizLblSpace
						.VISIBLE = .T.
					ENDWITH
				ENDIF
			ENDIF
			
			*- restore the values that we may have temporarily changed...
			THIS.lUsingContainers = m.lTempUsingContainers
			m.oCurObj.cNewLabelRef = m.cNewLabelRef
			m.oCurObj.lContainer = m.lContainer
			
			* Check if our new object exceeded detail dimensions and remove it (only if using pages)		
			THIS.nCurHgt = m.oCurObj.nObjHgt
			*    Exit loop when:
			* 	1. Exceeds vertical boundary of form
			* 	2. Exceeds boundary with Grid coming up

			DO CASE
				CASE THIS.oWizPages#0 AND;
				   THIS.nVLPOS+THIS.nCurHgt+26 > (THIS.nFooter-THIS.nHeader)
					
					THIS.NF.REMOVEOBJECT(m.cObjName)
					IF TYPE("EVAL('THIS.nf.'+m.cObjName2)") = "O"
						THIS.NF.REMOVEOBJECT(m.cObjName2)
					ENDIF

					m.nPageNum = m.nPageNum + 1
					IF	THIS.NF.PARENT.PAGECOUNT < m.nPageNum
						THIS.NF.PARENT.PAGECOUNT = m.nPageNum				
					ENDIF
					
					THIS.NF = THIS.NF.PARENT.Pages[m.nPageNum]
					IF EMPTY(THIS.oWizPageStyle)
						THIS.NF.FontName = THIS.LabelRec.cfont
						THIS.NF.FontSize = THIS.LabelRec.nfsize
					ENDIF
					THIS.nVLPOS = THIS.nLTopPos + 4
					THIS.nVINC = 0
					THIS.nHLPOS = THIS.nLLeftPos	&&current hori pos for lbl placement
					THIS.nCurrCol = 1
					ii = m.ii - 1

				CASE THIS.lUsePages AND THIS.oWizPages=0 AND;
					(THIS.nVLPOS+THIS.nCurHgt+IIF(THIS.lIsGrid AND !THIS.oWizGridForm,;
					THIS.ogridType.nObjectHgt,0) > THIS.nBottom) OR;
					(UPPER(THIS.CodeType) = "G" AND ;
					THIS.nVLPOS+THIS.nCurHgt > THIS.nFooter-THIS.nHeader)

					
					*- always grow form, and use scroll bars
					* Reset left side for next object, etc.
    				IF m.oTmpRef.left = THIS.nHLPOS
		   		    	THIS.nVLPOS = THIS.nVLPOS - THIS.nVINC
					ENDIF
					THIS.NF.REMOVEOBJECT(m.cObjName)
					IF TYPE("EVAL('THIS.nf.'+m.cObjName2)") = "O"
						THIS.nf.REMOVEOBJECT(m.cObjName2)
					ENDIF

					* Could not fit all fields
					IF m.lUsingClone
						lExceedPage = .T.
					ELSE
						cxsmessage=IIF(THIS.lRunningWizard,C_XSFIELDS_LOC,C_XSFIELDSBLDR_LOC)
						THIS.ALERT(IIF(THIS.lIsGrid,C_XSFIELDS2_LOC,m.cxsmessage))
						EXIT  && exit add field loop
					ENDIF
									
				OTHERWISE
					*This is for builders where right edge can adjust
					IF THIS.lUsingContainers
						THIS.nMaxRight = MAX(THIS.nMaxRight,m.oTmpRef.left+m.oTmpRef.width)
					ELSE
						THIS.nMaxRight = MAX(THIS.nMaxRight,m.oTmpRef.left+m.oTmpRef.width,m.oTmpRef2.left+m.oTmpRef2.width)
					ENDIF
					* Reset counters and settings
					THIS.SetNextVPOS()
			ENDCASE

			* Adjust ScrollGrid settings for RowHeight
			IF UPPER(THIS.NF.Parent.Baseclass)="COLUMN"
				IF TYPE("THIS.NF.Parent.Parent.WizRowStretch")="L" AND; 
				  THIS.NF.Parent.Parent.WizRowStretch
						THIS.NF.Parent.Parent.RowHeight = THIS.nVLPOS+THIS.nVINC
				ENDIF
			ENDIF

			IF m.lUsingClone AND m.ii=ALEN(THIS.aWizFields,1)
				lUsingClone = .F.
				THIS.NF = m.SaveRef
				THIS.REMOVEOBJECT("oStyleRef2")
				ii = 0
				IF m.lExceedPage
					THIS.oWizPages = m.nSavePages
					THIS.AddPages
					m.nPageNum = 1
				ELSE
					THIS.nVINC = 0
					THIS.nVLPOS = THIS.nLTopPos + THIS.nHeader		&&current vert pos for lbl placement
					THIS.nHLPOS = THIS.nLLeftPos + THIS.nLeftMargin	&&current hori pos for lbl placement
					THIS.nHINC  = THIS.nHLblSpace
					THIS.nCurrCol = 1
				ENDIF
			ENDIF
		ENDFOR
		
		IF THIS.oWizPages#0 AND THIS.NF.PARENT.TabStyle = 1
			THIS.NF.PARENT.TabStyle = 1
		ENDIF
	ENDPROC
	
	PROCEDURE AddGrid
		* Add Grid Object
		LOCAL nWArea,lHasView,oTmpRef
		nWArea = SELECT()
		IF !THIS.lIsGrid
			RETURN
		ENDIF
		IF EMPTY(THIS.ogridType.cNewObjectRef)
			&&Fail -- class not available
			THIS.ALERT(E_NOGRID_LOC)
			RETURN
		ENDIF
				
		SELECT (THIS.cGridAlias)
		lHasView = CURSORGETPROP("sourcetype")#3
		
		* Add new object and set properties
		IF THIS.oWizGridForm
			oTmpRef = EVAL("THIS.GridForm."+THIS.GridName)
		ELSE
			THIS.nf.ADDOBJECT("Grid1",THIS.ogridType.cNewObjectRef)
			oTmpRef = THIS.nf.Grid1
		ENDIF
		
		WITH m.oTmpRef
			* Don't adjust grid if using other grid form 
			IF !THIS.oWizGridForm
				DO CASE
				CASE THIS.oWizPages#0
					.WIDTH = THIS.NF.Parent.Width - (2*(THIS.nLeftMargin+THIS.nLLeftPos))
					.LEFT = THIS.nLLeftPos+THIS.nLeftMargin
					.HEIGHT = MIN(.HEIGHT,THIS.nFooter-THIS.nHeader-THIS.nVLPOS-30)
				CASE !THIS.oFormStretch
					* Center in Layout and keep same width as default
					* Use default label position
					.LEFT = THIS.nLLeftPos+THIS.nLeftMargin
				OTHERWISE
					.WIDTH = THIS.nRightMargin - THIS.nLeftMargin
					.LEFT = (THIS.nf.width - .width)/2
				ENDCASE
				.TOP = THIS.GetNextVPOS(.WIDTH)
			ENDIF

			* Special handling of views--store key in Tag property
			.COMMENT = IIF(m.lHasView,UPPER(THIS.cMainKey),"")
			.TAG = IIF(m.lHasView,UPPER(THIS.cRelatedKey),"")
			.VISIBLE = .T.
		ENDWITH
		
		THIS.setgridfields()

		IF !THIS.oWizGridForm
			THIS.nCurHgt = m.oTmpRef.HEIGHT
			THIS.SetNextVPOS()
		ENDIF	
		SELECT (m.nWArea)
	ENDPROC
	
	PROCEDURE setgridfields
		LOCAL oTmpRef
		
		IF !THIS.lIsGrid
			RETURN 
		ENDIF
		
		DO CASE
		CASE THIS.oWizPages#0 AND ATC("PAGE",THIS.NF.BASECLASS)=0 AND TYPE("THIS.NF.WizFrame1")="O"
			m.oTmpRef = THIS.NF.WizFrame1.Pages[THIS.NF.WizFrame1.PageCount].Grid1
		CASE THIS.oWizGridForm
			m.oTmpRef = EVAL("THIS.GridForm."+THIS.GridName)
		OTHERWISE
			m.oTmpRef = THIS.NF.Grid1
		ENDCASE

		IF m.oTmpRef.ColumnCount = ALEN(THIS.aGridFields)
			* RETURN
		ENDIF
		
		WITH m.oTmpRef
			.COLUMNCOUNT = ALEN(THIS.aGridFields)
			.RECORDSOURCETYPE = 1  					&&alias
			.RECORDSOURCE = LOWER(THIS.cGridAlias)
			FOR i = 1 TO .ColumnCount
				WITH EVAL(".COLUMN"+ALLTRIM(STR(m.i))) 
					.CONTROLSOURCE = LOWER(THIS.cGridAlias)+"."+LOWER(THIS.aGridFields[m.i])
					.HEADER1.CAPTION = PROPER(THIS.aGridFields[m.i])
					.WIDTH = -1						&& force to autosize
				ENDWITH
			ENDFOR
		ENDWITH
	ENDPROC
	
	PROCEDURE gettypeobj
		PARAMETER aFldData
		 * Determine which type here and returns object ref
		DO CASE
			CASE aFldData[2] = "C" AND aFldData[3] > THIS.oMaxChar
				RETURN THIS.omType
			CASE aFldData[2] = "V" AND aFldData[3] > THIS.oMaxChar
				RETURN THIS.omType
			CASE aFldData[2]  = "L" AND THIS.oLogic # THIS.oField
				RETURN THIS.olType	
			CASE ATC(aFldData[2],"CDTNIFYBLVQ")#0
				RETURN THIS.ocType
			CASE aFldData[2]  = "M"
				RETURN THIS.omType
			CASE aFldData[2]  = "W"
				RETURN THIS.omType
			OTHERWISE
				RETURN THIS.ogType
		ENDCASE
	ENDPROC

	FUNCTION AddBmps
		* Creates a directory if needed and adds BMP files
		* for picture buttons.

		LOCAL iSvarea,sTmpDBF,sTmpName,aTemparr,cDirName
		DIMENSION aTemparr[1]

		cDirName = THIS.addbs(THIS.justpath(_wizard))+WZ_DIRNAME

		* Check to see directory exists
		IF ADIR(aTemparr,m.cDirName,'D')=0
			MD (m.cDirName)
			DIMENSION aTemparr[1]
			* Test to see if failed to create directory			
		    IF ADIR(aTemparr,m.cDirName,'D')=0
		      THIS.ALERT(ERR_NODIR_LOC)
		      RETURN .F.
		    ENDIF
		ENDIF

		iSvarea=SELECT()
		sTmpDBF=SYS(3)
		sTmpName=""

		SELECT * FROM wizbmp INTO DBF(m.sTmpDBF)

		SCAN
			m.sTmpName = m.cDirName + '\' + ALLTRIM(UPPER(fname))
			IF !FILE(m.sTmpName)
		    	COPY MEMO bmp TO (m.sTmpName)
		    	* add file type and creator for Macs
		    	IF _MAC
		    	  ** Note - must have FOXTOOLS.MLB loaded for this funtion
		    	  =FxSetType(SYS(2027,m.sTmpName),'????','????')
		    	ENDIF
			ENDIF
		ENDSCAN

		USE
		USE in wizbmp
		DELETE FILE (m.sTmpDBF)+'.DBF'
		DELETE FILE (m.sTmpDBF)+'.FPT'
		SELECT (m.iSvarea)
		RETURN .T.
	ENDPROC
	
	PROCEDURE AddCodeBtns
		IF !THIS.oCodeStyle
			RETURN
		ENDIF
		IF EMPTY(THIS.oWizButtons)
			RETURN
		ENDIF
		THIS.nf.AddObject("ButtonSet1",THIS.oWizButtons)
		IF THIS.oFormStretch
			LOCAL nNewHeight	
			m.nNewFoot = THIS.nFooter - (THIS.nVLPOS+THIS.nVINC)
		ENDIF	
		DO CASE 
		CASE THIS.oWizBtnPos = 0	&& use coordinates of object
			THIS.nf.ButtonSet1.LEFT = THIS.nBtnLeft
			THIS.nf.ButtonSet1.TOP = THIS.nBtnTop
		CASE THIS.oWizBtnPos = 1  && center horizontally
			THIS.nf.ButtonSet1.TOP = THIS.nBtnTop
			THIS.nf.ButtonSet1.LEFT = (THIS.nf.width-THIS.nf.ButtonSet1.width)/2
		CASE THIS.oWizBtnPos = 2	&& center vertically
			THIS.nf.ButtonSet1.LEFT = THIS.nBtnLeft
			THIS.nf.ButtonSet1.TOP = THIS.nbottom +;
			 ((THIS.nf.height - THIS.nbottom) -;
			   THIS.nf.ButtonSet1.height)/2
		OTHERWISE  && center both hori and vert -- default
				THIS.nf.ButtonSet1.LEFT = (THIS.nf.width-THIS.nf.ButtonSet1.width)/2	
				THIS.nf.ButtonSet1.TOP = THIS.nbottom +;
				 ((THIS.nFrmStartHgt-THIS.nFooter) -;
				   THIS.nf.ButtonSet1.height)/2
		ENDCASE
		THIS.nf.ButtonSet1.VISIBLE = .T.
		IF !THIS.lUsePages AND THIS.nf.Height>THIS.nf.ViewPortHeight
			* Adjust width for extra scrollbar.
			THIS.nf.width = THIS.nf.width + SYSMETRIC(5)
		ENDIF
	ENDPROC
	
	PROCEDURE SetFooter
		* resize form
		LOCAL nNewFoot,i,nMembers,aMemArr,oMemRef,nFooter
		DIMENSION aMemArr[1]
		IF THIS.oFormStretch		
			m.nNewFoot = THIS.nFooter - (THIS.nVLPOS+THIS.nVINC)

			THIS.nBottom = THIS.nVLPOS+THIS.nVINC
			IF  m.nNewFoot # 0 AND TYPE("THIS.nf") = "O"
				m.nMembers=ALEN(THIS.aPreMembers)
				m.nFooter = THIS.nFooter  	&&original footer position
				FOR i = 1 TO m.nMembers
					m.oMemRef = EVAL("THIS.nf."+THIS.aPreMembers[m.i])
					WITH m.oMemRef
						IF .TOP >  m.nFooter
							.TOP = .TOP - m.nNewFoot
						ENDIF
					ENDWITH
				ENDFOR
				THIS.nf.ScrollBars = IIF(THIS.lUsePages,0,3)
				THIS.nf.height = MIN(THIS.nVertRes,THIS.nf.height-m.nNewFoot)
			ENDIF
		ENDIF
	ENDPROC
	
	PROCEDURE FormCleanup
		* Hide layout object
		WITH EVAL("THIS.nf."+THIS.oLayout)
			* Can't remove layout object so hide it
			.VISIBLE = .F.
			.LEFT = .LEFT+4000
		ENDWITH

		* Hide button object
		IF !EMPTY(THIS.oBtnLayout)
			WITH EVAL("THIS.nf."+THIS.oBtnLayout)
				* .ENABLED = .F.
				.VISIBLE = .F.
				.LEFT = .LEFT+4000
			ENDWITH
		ENDIF
		
		THIS.nf.refresh
	ENDPROC

	PROCEDURE RunMethod
		LPARAMETER cMethodRef
		LOCAL aTmpProcs,nPos
		IF EMPTY(m.cMethodRef)
			RETURN
		ENDIF
		DIMENSION aTmpProcs[1]
		=AMEMBERS(aTmpProcs,THIS,1)
		m.nPos =  ASCAN(aTmpProcs,UPPER(m.cMethodRef))
		IF m.nPos #0 AND m.nPos#ALEN(aTmpProcs) AND ;
			UPPER(aTmpProcs[m.nPos+1]) = "METHOD"
			THIS.&cMethodRef
		ELSE
			this.SetErrorOff = .T.
			m.cMethodRef = "DO "+ m.cMethodRef
			&cMethodRef
			this.SetErrorOff = .F.
		ENDIF
	ENDPROC
	
	PROCEDURE PreProcess
		*  preprocess method
		IF !EMPTY(THIS.PreVisual)
			THIS.RunMethod(THIS.PreVisual)
		ENDIF
		IF !EMPTY(THIS.PreCode)
			THIS.RunMethod(THIS.PreCode)
		ENDIF
	ENDPROC

	PROCEDURE PostProcess
		*  postprocess method
		IF !EMPTY(THIS.PostVisual)
			THIS.RunMethod(THIS.PostVisual)
		ENDIF
		IF !EMPTY(THIS.PostCode)
			THIS.RunMethod(THIS.PostCode)
		ENDIF
	ENDPROC
	
	PROCEDURE GetNextVPOS
		PARAMETER pWidth
		* single column only
	    	IF THIS.lIs1col=.T.
	 			THIS.nVLPOS = THIS.nVLPOS + THIS.nVINC
	    		RETURN THIS.nVLPOS
	    	ENDIF
	    	
			* multiple columns
	    	DO CASE
	    	CASE THIS.nCurrCol > 1
	     		* At second column
	  			IF m.pWidth > (THIS.nRightEdge - ;
	    			((THIS.nCurrCol-1)*THIS.nColWidth+THIS.nHLPOS)-4)
			   		* exceeds width -- go to next row position
	    			THIS.nVLPOS = THIS.nVLPOS + THIS.nVINC
	   				THIS.nLastVINC = 0
	  				THIS.nCurrCol = 1
				ENDIF
				* else stay here
	    	OTHERWISE
	 		   	* At first column
	   			THIS.nVLPOS = THIS.nVLPOS + THIS.nVINC
				THIS.nLastVINC = 0
	    	ENDCASE
	    	
	    	RETURN THIS.nVLPOS
	ENDPROC

	PROCEDURE SetNextVPOS
		* set next increment to add to THIS.nVLPos
		THIS.nVINC = THIS.nVLblSpace + THIS.nCurHgt
		
		* single column
		IF THIS.lIs1col
			RETURN
		ENDIF
		
		* multi column
		THIS.nVINC = MAX(THIS.nLastVINC,THIS.nVINC)
		THIS.nLastVINC = THIS.nVINC
	ENDPROC
	
	PROCEDURE GetNextHPOS
		* Note: add 2 as cushion between columns
		PARAMETER pWidth
		LOCAL nNextHPos
		DO CASE
		CASE THIS.lIs1col	&&single column
			* always use 1st col starting position
			m.nNextHPos = THIS.nHLPOS
			
		OTHERWISE  &&multi column
			IF m.pWidth > (THIS.nRightEdge - ;
			  ((THIS.nCurrCol-1)*THIS.nColWidth+THIS.nHLPOS) - 2)
				m.nNextHPos = THIS.nHLPOS
				THIS.nCurrCol = 1
			ELSE
				m.nNextHPos = THIS.nHLPOS+((THIS.nCurrCol-1)*THIS.nColWidth)
			ENDIF

			* Get next starting column
			DO WHILE .T.
				THIS.nCurrCol = THIS.nCurrCol + 1
				IF THIS.nCurrCol > THIS.nMaxCols
					THIS.nCurrCol = 1
					EXIT
				ENDIF
				IF (m.nNextHPos+m.pWidth) < (THIS.nHLPOS+THIS.nColWidth*(THIS.nCurrCol-1))
					EXIT
				ENDIF
			ENDDO

		ENDCASE
		RETURN m.nNextHPos
	ENDPROC

	FUNCTION CheckFields
		* Checks if fields will fit in a single column
		* Note: to check for horizontal fit of all fields would 
		* be considerable more work and impact performance.
		
		LOCAL aDetail,tmparr2,tmparr3,ntmpvpos,i,oCurObj,lcSaveExact,lnNumFields
		IF THIS.lIs1col &&no second column available
			RETURN
		ENDIF

		IF THIS.lIsGrid AND !THIS.oWizGridForm AND !EMPTY(THIS.aGridFields[1])	&& default to multi columns
			THIS.lIs1col=.F.
			RETURN
		ENDIF

		THIS.lIs1col = .T.  &&initialize for check

		lnNumFields = ALEN(THIS.aWizFList,2)
		IF lnNumFields = 0
			lnNumFields = NUM_AFIELDS
		ENDIF

		DIMENSION aDetail[lnNumFields,1]
		DIMENSION tmparr2[1]
		DIMENSION tmparr3[1]
		
		ACOPY(THIS.aWizFields,tmparr3)
		IF EMPTY(tmparr3[1])  &&no fields selected
			RETURN
		ENDIF
		FOR i = 1 TO ALEN(tmparr3)
			tmparr3[m.i] = PROPER(tmparr3[m.i])
		ENDFOR
		
		ACOPY(THIS.aWizFList,tmparr2)	&&should be all uppercase from AFIELDS()
		
		m.ntmpvpos = THIS.nVLPOS
		
		lcSaveExact = SET("EXACT")
		SET EXACT ON
		
		* Loop thru field list
		FOR m.i = 1 TO ALEN(tmparr2,1)

			IF ASCAN(tmparr3,PROPER(tmparr2[m.i,1]))=0
				LOOP
			ENDIF

			ACOPY(tmparr2,aDetail,AELEMENT(tmparr2,m.i,1),lnNumFields)
			m.oCurObj = THIS.gettypeobj(@aDetail)
			IF !ISNULL(m.oCurObj)
				m.ntmpvpos = m.ntmpvpos + m.oCurObj.nObjectHgt + THIS.nVLblSpace

				IF m.ntmpvpos > THIS.nBottom
			    	THIS.lIs1col=.F.
			    	EXIT
				ENDIF
			ENDIF

		ENDFOR
		SET EXACT &lcSaveExact
	ENDFUNC
	
ENDDEFINE


*******************************************
DEFINE CLASS inputs as custom
*******************************************

	DIMENSION aFldObjs[1,1]
	aFldObjs = ""
	
	DIMENSION aFldData[1,1]
	aFldData = ""

	cNewObjectRef = " "	&&name of object
	nObjectHgt = 0		&&object height
	nObjectWid = 0		&&object width
	cNewLabelRef = " "  &&make sure space stays here
	cNewFieldRef = " "	&&field reference
	nNewLabelWid = 0	&&label width
	nNewFieldWid = 0	&&field width
	nfdiff = 0
	lAddLblDiff = .T.	&&add label diff spacing to field
	nObjHgt = 0 		&&current object height
	cLblSuffix = ""		&&label suffix
	cLblCaps = ""		&&label caps
	nHSpace = 0			&&horizontal space between label and field
	lblright = 0
	nLbldelta = 0		&&difference between label default width and template
	nLbldiff = 0
	nCurrLblEnd = 0		&&current label right edge after autosize
	nCurrFldEnd = 0		&&current field right edge after autosize
	lLblDefWid = .T.	&&use default label width
	nDefLblWid = 0		&&default label width 
	haderror = .F.		&&had an error
	cAlias = ""			&&current alias
	cCaption = ""		&&caption
	cFieldName = ""		&&field name
	lcontainer = .T.	&&using a container object
	lOverrideStyle = .F.	&& override style with values in DBC
	lUseFieldMappings = .F.	&& use field mappings that are stored in registry

	PROTECTED cfstyle,lfbold,lfitalic,lfunder,nFONT6,nFONT18
	PROTECTED cLfont,nLfsize,cLfstyle,lLfbold,lLfitalic,lLfunder,nLFONT6,nLFONT18

	* field font default information
	cfont = C_WINFONT		&& MS Sans Serif
	nfsize = C_WINFSIZE		&& 8
	cfstyle =  C_WINFSTYLE	&& B (bold)
	lfbold = C_WINFBOLD		&& bold - true
	lfitalic = C_WINFITALIC	&& italic - false
	lfunder = C_WINFUNDER	&& underline - false
	nFONT6 = 0				&& Font 6 conversion factor
	nFONT18 = 0				&& Extra pixel overhanging
	
	* label font default information
	cLfont = C_WINFONT		&& MS Sans Serif
	nLfsize = C_WINFSIZE	&& 8
	cLfstyle =  C_WINFSTYLE	&& B (bold)
	lLfbold = C_WINFBOLD	&& bold - true
	lLfitalic = C_WINFITALIC && italic - false
	lLfunder = C_WINFUNDER	&& underline - false
	nLFONT6 = 0				&& Font 6 conversion factor
	nLFONT18 = 0			&& Extra pixel overhanging

	PROTECTED FUNCTION getstyle
		PARAMETER lIsBold,lIsItalic,lIsUnder
		DO CASE
		CASE m.lIsBold AND m.lIsItalic AND m.lIsUnder
			RETURN "BIU"
		CASE m.lIsBold AND m.lIsItalic 
			RETURN "BI"
		CASE m.lIsBold AND m.lIsUnder
			RETURN "BU"
		CASE m.lIsItalic AND m.lIsUnder
			RETURN "IU"
		CASE m.lIsBold 
			RETURN "B"
		CASE m.lIsItalic 
			RETURN "I"
		CASE m.lIsUnder
			RETURN "U"
		OTHERWISE
			RETURN "N"
		ENDCASE
	ENDFUNC

	PROCEDURE SetProps
		PARAMETER oNewObj,aAfieldData,cCaption
	
		=ACOPY(aAfieldData,THIS.aFldData)
		THIS.cFieldName = UPPER(aAfieldData[1])
		THIS.cCaption = IIF(!EMPTY(m.cCaption),m.cCaption,THIS.cFieldName)
		* Container object
		* Note: this can also be a separate control such as
		* a checkbox which is not stored in a Controls class.
		
		WITH m.oNewObj
			* Add label portion of object
			THIS.SetLabels()
			
			* Add field portion of object
			IF UPPER(.BASECLASS) = "CONTAINER"
				WITH EVAL("."+THIS.cNewFieldRef)
					THIS.SetFields()
				ENDWITH
			ELSE
				THIS.SetFields()
			ENDIF
			
			* Add special effects portion of object
			THIS.SetFX()
			
			* set Container object properties
			IF UPPER(.BASECLASS) = "CONTAINER"  	&& "CONTROLS"
				.WIDTH = .WIDTH + IIF(THIS.lAddLblDiff,THIS.nLbldiff,0) + THIS.nfdiff
			ENDIF
			
			THIS.nObjHgt = .HEIGHT		&&current object height
			
		ENDWITH

		* Handle any user subclassing special effects
		THIS.UserSetFx()

	ENDPROC
	
	PROCEDURE SetLabels
		* Add label portion of object
		IF EMPTY(THIS.cNewLabelRef)  &&checkbox w/o label
			RETURN
		ENDIF
		WITH EVAL("."+THIS.cNewLabelRef)	&&label
			* FP2.6 Wizards stored alias with field name. This can conflict with
			* long field names containing periods.
			.CAPTION = THIS.cCaption+THIS.cLblSuffix
			IF THIS.lLblDefWid
				.WIDTH = THIS.nDefLblWid
			ELSE
				.AUTOSIZE = .T.
				* Note: this next line resets .width since autosize only works in design mode
				.WIDTH = TXTWIDTH(.CAPTION,THIS.cLfont,THIS.nLfsize,THIS.cLfstyle) * ;
					THIS.nLFONT6 + THIS.nLFONT18
	      	ENDIF	
			THIS.nCurrLblEnd = .LEFT + .WIDTH
		ENDWITH
	ENDPROC

	PROCEDURE SetFields
		* Let's be smart here. If field LEFT is greater 
		* than label LEFT and WIDTH then add nLbldiff.
		LOCAL lcSourceField,lcDataType
		IF THIS.lContainer AND THIS.lAddLblDiff
			.LEFT = .LEFT + THIS.nLbldiff
		ENDIF
		
		* Adds specific properties for control (e.g., InputMsk)
		THIS.AddObjProps()
		THIS.nCurrFldEnd = .LEFT + .WIDTH
		IF TYPE(".ControlSource")#"U"
			lcSourceField = LOWER(IIF(!EMPTY(THIS.cAlias),ALLT(THIS.cAlias)+"."+THIS.cFieldName,THIS.cFieldName))
			* Certain class types except
			IF ATC("textbox",.baseclass)=0
				lcDataType= TYPE(lcSourceField)
				* Test for valid data types and skip binding if invalid
				DO CASE
				CASE ATC(.baseclass,"editbox")#0 AND ATC(lcDataType,"CM")=0
					RETURN
				CASE ATC(.baseclass,"spinner")#0 AND ATC(lcDataType,"NY")=0
					RETURN
				CASE ATC(.baseclass,"checkbox")#0 AND ATC(lcDataType,"LN")=0
					RETURN
				CASE ATC(.baseclass,"optiongroup,listbox,combobox")#0 AND ATC(lcDataType,"CN")=0
					RETURN
				ENDCASE
			ENDIF
			.ControlSource = lcSourceField
		ENDIF
	ENDPROC
	
	PROCEDURE SetFx
		LOCAL nSpecialFx,jj,cFxObj
		* Add special effects				
		IF !THIS.lContainer
			RETURN
		ENDIF
		FOR jj = 1 TO ALEN(THIS.aFldObjs)
			IF EMPTY(THIS.aFldObjs[m.jj])
				LOOP
			ENDIF
			cFxObj = UPPER(THIS.aFldObjs[m.jj])
			IF INLIST(m.cFxObj,UPPER(THIS.cNewFieldRef),;
				UPPER(THIS.cNewLabelRef))
				LOOP
			ENDIF
			
			*** Handle special effects here Currently, 
			*** using TAG field to effects values
			WITH EVAL("."+m.cFxObj)				&&Special FX Shapes
				
				* Get special effect for object
				* 1. Check for WizEffect property in object
				* 2. Check for WizEffect property in parent container
				* 3. Check for Tag property in object
				DO CASE
				CASE TYPE('.WizEffect') # "U"
					m.nSpecialFx = .WizEffect
				CASE TYPE('.Parent.WizEffect') # "U"
					m.nSpecialFx = .Parent.WizEffect
				CASE TYPE('.Tag') # "U"
					m.nSpecialFx = .TAG
				OTHERWISE
					m.nSpecialFx = 0 
				ENDCASE
				
				* Convert to numeric if "1" passed for example
				IF TYPE('m.nSpecialFx') = "C"
					m.nSpecialFx = VAL(m.nSpecialFx)			
				ENDIF
				
				* Last check in case some garbage passed our way
				IF TYPE('m.nSpecialFx') # "N"
					m.nSpecialFx = 0
				ENDIF
				
				* Apply Special Effect
				DO CASE
				CASE m.nSpecialFx = 0	&&stretch and move with field
					* TAG = 0 or no tag, this fx is used for
					* Chiseled or Shadowed style where an object 
					* moves and stretches (width) with field 
					.WIDTH =.WIDTH + THIS.nfdiff
					IF THIS.lAddLblDiff
						.LEFT = .LEFT + THIS.nLbldiff
					ENDIF		
				CASE m.nSpecialFx = 1  &&stretch with label/field
					* TAG = 1, this fx is used for Boxed style
					* where an object stretches (width) with field
					* to MAX label or field.
					.WIDTH =.WIDTH + THIS.nfdiff
					IF THIS.nCurrLblEnd > THIS.nCurrFldEnd
						.WIDTH =.WIDTH + THIS.nCurrLblEnd - THIS.nCurrFldEnd
						THIS.nfdiff = THIS.nfdiff + THIS.nCurrLblEnd - THIS.nCurrFldEnd
					ENDIF
				CASE m.nSpecialFx = 2  &&stretch over all
					* TAG = 2, this fx is used for a style
					* where an object stretches with both label + field
					* as with boxed horizontal layout type style.
					.WIDTH =.WIDTH + THIS.nLbldiff + THIS.nfdiff
				ENDCASE
				* User sets or enhances special fx
			ENDWITH
		ENDFOR	
	ENDPROC

	PROCEDURE UserSetFx
		* Stub for users to subclass and handle special fx
	ENDPROC

	PROCEDURE SetGlobals
		PARAMETER aTmpGlobals
		THIS.nDefLblWid = aTmpGlobals[1]
		THIS.nLbldelta = aTmpGlobals[2]
		THIS.nHSpace = aTmpGlobals[5]
		THIS.cLblSuffix = aTmpGlobals[3]
		THIS.cLblCaps  = aTmpGlobals[4]
		THIS.lLblDefWid = aTmpGlobals[6]
		THIS.cAlias = aTmpGlobals[7]
		THIS.lOverrideStyle = aTmpGlobals[8]
		THIS.lUseFieldMappings = aTmpGlobals[9]
	ENDPROC

	PROTECTED PROCEDURE GetFWidth
		PARAMETER nWidth,nDecimals
		RETURN THIS.nNewFieldWid
	ENDPROC
	
	PROTECTED PROCEDURE AddObjProps
	ENDPROC
	
	PROCEDURE setname
		PARAMETER cStyref
		THIS.cNewObjectRef = m.cStyref
	ENDPROC

	PROCEDURE setobjs
		PARAMETER cControlName,lAddToForm
		LOCAL i,oTemp,nMemCount,otmpref,nlblleft,nfldleft,nTmpSpace,oTmpForm
		STORE .NULL. TO m.nlblleft,m.nfldleft
		
		* Special handling for General fields
		IF TYPE("m.lAddToForm") = "L" AND m.lAddToForm
			oTmpForm = Create('Form')
			oTmpForm.AddObject('oTmpOle',THIS.cNewObjectRef)
			oTemp = oTmpForm.oTmpOle
		ELSE
			oTemp = CREATE(THIS.cNewObjectRef)
		ENDIF
		
		THIS.nObjectHgt = oTemp.height
		THIS.nObjectWid = oTemp.width
		THIS.lcontainer = (UPPER(oTemp.baseclass) = "CONTAINER")
		m.nMemCount=AMEMBERS(THIS.aFldObjs,oTemp,2)
		
		* Check if we have an object with no members (i.e., checkbox)
		IF !THIS.lcontainer OR m.nMemCount = 0
			DIMENSION THIS.aFldObjs[1,1]
			THIS.aFldObjs = ""
			m.nMemCount = 1
			m.tmpclass=UPPER(oTemp.BASECLASS)
			THIS.cNewFieldRef = oTemp.NAME
			otmpref = oTemp
		ENDIF
		
		* Check for field and label in style
		FOR m.i = 1 TO m.nMemCount
			IF !EMPTY(THIS.aFldObjs[m.i])  &&has members
				m.tmpclass=UPPER(EVAL("oTemp."+THIS.aFldObjs[m.i]+".BASECLASS"))
			ENDIF
			DO CASE
			CASE m.tmpclass = UPPER(m.cControlName)
				IF !EMPTY(THIS.aFldObjs[m.i])  &&has members
					THIS.cNewFieldRef = EVAL("oTemp."+THIS.aFldObjs[m.i]+".NAME")
					otmpref = EVAL("oTemp."+THIS.cNewFieldRef)
				ENDIF
				WITH otmpref
					m.nfldleft = .LEFT
					THIS.nNewFieldWid = .width
					&& bugbug -- make sure this doesn't change
					IF TYPE(".fontname") # ""
						THIS.cFont = .fontname
						THIS.nFsize = .fontsize
						THIS.lFbold = .fontbold
						THIS.lFitalic = .fontitalic
						THIS.lFunder =	.fontunderline
						THIS.cFstyle = THIS.GETSTYLE(.fontbold,.fontitalic,.fontunderline) 	&& fontstyle
						THIS.nFONT6 = FONT(6,.fontname,.fontsize,THIS.cfstyle)				&& Font 6 conversion factor
						THIS.nFONT18 = FONT(18,.fontname,.fontsize,THIS.cfstyle)			&& Font 18 extra pixels
					ENDIF
				ENDWITH
			CASE m.tmpclass = "LABEL"
				THIS.cNewLabelRef = EVAL("oTemp."+THIS.aFldObjs[m.i]+".NAME")
				otmpref = EVAL("oTemp."+THIS.cNewLabelRef)
				WITH otmpref
					m.nlblleft = .LEFT
					THIS.nNewLabelWid = .width
					THIS.cLFont = .fontname
					THIS.nLFsize = .fontsize	
					THIS.lLFbold = .fontbold	
					THIS.lLFitalic = .fontitalic
					THIS.lLFunder =	.fontunderline
					THIS.cLFstyle = THIS.GETSTYLE(.fontbold,.fontitalic,.fontunderline) && fontstyle
					THIS.nLFONT6 = FONT(6,.fontname,.fontsize,THIS.cLfstyle)			&& Font 6 conversion factor
					THIS.nLFONT18 = FONT(18,.fontname,.fontsize,THIS.cLfstyle)			&& Font 18 extra pixels
				ENDWITH
			ENDCASE
		ENDFOR

		* Get spacing in a container object between label and field
		IF !ISNULL(m.nfldleft) AND !ISNULL(m.nlblleft)
			m.nTmpSpace = m.nfldleft - (m.nlblleft + THIS.nNewLabelWid)	
			IF m.nTmpSpace < 0
				THIS.lAddLblDiff = .F.
			ENDIF
			THIS.nLbldiff = (THIS.nDefLblWid - THIS.nNewLabelWid) +;
				(THIS.nHSpace - m.nTmpSpace)
		ENDIF
		
		RELEASE oTemp
		IF TYPE("m.oTmpForm") = "O"
			RELEASE oTmpForm
		ENDIF
	ENDPROC
	
	PROTECTED FUNCTION GetAveCh
		* Routine takes the width of a database field
		* and returns a character which can be used
		* as the average size in a TXTWIDTH expression
		* to determine the width of am @..GET field. 	

		**Need to estimate average character width	
		PARAMETER fwidth
		DO CASE
		CASE m.fwidth < 6	&&largest
			RETURN  'W'
		CASE m.fwidth < 13	&&above average
			RETURN 	'Q'
		OTHERWISE			&&average size
			RETURN 	'B'				
		ENDCASE
	ENDFUNC

	PROTECTED FUNCTION getnumstr
		PARAMETER numchars
		LOCAL cGetnumstr,z
		m.cGetnumstr=''
		FOR z = 1 TO m.numchars
	 		IF m.z > 3 AND MOD(m.z,3) = 1 
	  	 		m.cGetnumstr = '9,'+m.cGetnumstr
	 		ELSE
	   			m.cGetnumstr = '9'+m.cGetnumstr
	  		ENDIF
		ENDFOR
		RETURN m.cGetnumstr
	ENDFUNC
	
	PROTECTED PROCEDURE AddFWidth
		LOCAL ntmpfwid
		m.ntmpfwid = THIS.GetFWidth() + 4
		IF TYPE(".SpecialEffect")#"U" AND TYPE(".BorderStyle")#"U"
			IF .BorderStyle#0
				m.ntmpfwid = m.ntmpfwid + IIF(.SpecialEffect=0,4,2)
			ENDIF
		ELSE
		ENDIF
		THIS.nfdiff = m.ntmpfwid - .Width
		RETURN m.ntmpfwid
	ENDPROC
	
ENDDEFINE


*******************************************
DEFINE CLASS charflds as inputs
*******************************************

	PROTECTED PROCEDURE GetFWidth
		DO CASE
			CASE INLIST(THIS.aFldData[2], "C", "Q")  &&Char
				RETURN THIS.aFldData[3]*TXTWIDTH(THIS.GetAveCh(THIS.aFldData[3]),;
				  THIS.cfont,THIS.nfsize,THIS.cfstyle)*THIS.nFONT6 + THIS.nFONT18 + 2
			CASE ATC(THIS.aFldData[2],"NF")#0		&&number,float
				RETURN (THIS.aFldData[3]+IIF(THIS.aFldData[4] = 0,INT((THIS.aFldData[3]- 1)/3),;
		    	  INT((THIS.aFldData[3]- THIS.aFldData[4])/3)))*THIS.nFONT6;
		    	  * TXTWIDTH("9",THIS.cfont,THIS.nfsize,THIS.cfstyle) + THIS.nFONT18 + 4
			CASE THIS.aFldData[2] = "D" 		&&Date
				RETURN TXTWIDTH('99/99/9999',THIS.cfont,THIS.nfsize,THIS.cfstyle);
			      * THIS.nFONT6 + THIS.nFONT18
			CASE THIS.aFldData[2] = "T"  &&DateTime
				RETURN TXTWIDTH('99/99/9999 99:99:99pm',THIS.cfont,THIS.nfsize,THIS.cfstyle);
		    	  * THIS.nFONT6 + THIS.nFONT18
			CASE THIS.aFldData[2] = "B"  &&Double
				* No need for commas since this will usually 
				* be represented in scientific notation.
				RETURN (20 + THIS.aFldData[4]) * TXTWIDTH("9",THIS.cfont,THIS.nfsize,THIS.cfstyle);
					*THIS.nFONT6 + THIS.nFONT18
			CASE THIS.aFldData[2] = "Y"  &&Currency
				RETURN TXTWIDTH("9,999,999,999,999,999.99",THIS.cfont,THIS.nfsize,THIS.cfstyle);
					*THIS.nFONT6 + THIS.nFONT18
			CASE THIS.aFldData[2] = "L"  &&Logic
				RETURN TXTWIDTH('W',THIS.cfont,THIS.nfsize,THIS.cfstyle);
			      * THIS.nFONT6		
			OTHERWISE
				RETURN THIS.aFldData[3]*TXTWIDTH(THIS.GetAveCh(THIS.aFldData[3]),;
				  THIS.cfont,THIS.nfsize,THIS.cfstyle)*THIS.nFONT6 + THIS.nFONT18
		ENDCASE
		
	ENDPROC
	
	PROTECTED PROCEDURE AddObjProps
		LOCAL cInputMask, cFormat, cDBFRef
		
		cInputMask = ""
		cFormat = ""
		
		IF !EMPTY(CURSORGETPROP("DATABASE"))
			*- see if an inputmask and/or format is there
			cDBFRef = CURSORGETPROP("SourceName",THIS.cAlias)
			cInputMask = DBGETPROP(cDBFRef + "." + THIS.aFldData[1],"FIELD","InputMask")
			cFormat = DBGETPROP(cDBFRef + "." + THIS.aFldData[1],"FIELD","Format")
			*- use inputmask and format values from DBC
			IF TYPE(".InputMask")#"U"
				.InputMask = cInputMask
				.Format = cFormat
			ENDIF
		ENDIF

		
		IF TYPE(".InputMask")#"U" AND EMPTY(.InputMask) AND EMPTY(.Format)
			*- we may have filled those in from DBC settings, so don't change
			DO CASE
				CASE THIS.aFldData[2] = "C"  &&Char
					.InputMask = REPL("X",THIS.aFldData[3])
				CASE ATC(THIS.aFldData[2],"DITW") # 0  &&date,datetime,integer,blob
					* skip
				CASE THIS.aFldData[2] = "Y"  &&Currency
				    .InputMask = "9,999,999,999,999,999.99"
				    .format = "$"
				CASE THIS.aFldData[2] = "L"  &&Logic
				    .InputMask = "Y"
				CASE THIS.aFldData[2] = "Q"  &&varbinary
				    .InputMask = REPLICATE('H', THIS.aFldData[3])
				    .MaxLength = THIS.aFldData[3] * 2
				    .Format = 'F'

				CASE THIS.aFldData[2] = "V"  &&varchar
				    .MaxLength = THIS.aFldData[3]
				    .Format = 'F'
				    
				CASE THIS.aFldData[2] = "B"  &&Double
				    .InputMask = "99999999999999999999"+ ;
				    IIF(THIS.aFldData[4]=0,"","."+REPL("9",THIS.aFldData[4]))
				    .format = "^"
				CASE THIS.aFldData[4]=0	&& no decimals
				    .InputMask = THIS.getnumstr(THIS.aFldData[3])
				OTHERWISE	&&numbers/floats
				  	.InputMask = THIS.getnumstr(THIS.aFldData[3]-THIS.aFldData[4]-1) +;
				  		"." + REPL("9",THIS.aFldData[4])
			ENDCASE
		ENDIF
				
		IF TYPE(".Alignment")#"U" AND ATC(THIS.aFldData[2],"NFIYB") # 0  &&numbers
			.Alignment = 1		&&force to right alignment
		ENDIF

		.Width = THIS.AddFWidth()
	ENDPROC
 
ENDDEFINE


*******************************************
DEFINE CLASS logicflds as inputs
*******************************************
	lCheckBox = .T.
	
	PROTECTED PROCEDURE AddObjProps
		LOCAL nOldfwid
		IF !EMPTY(THIS.cNewLabelRef)
			RETURN
		ENDIF
		* FP2.6 Wizards stored alias with field name. This can conflict with
		* long field names containing periods.

		IF TYPE(".Caption")#"U"
			.Caption = THIS.cCaption + THIS.cLblSuffix
		ENDIF
		m.nOldfwid = .Width
		.Width = TXTWIDTH(THIS.cCaption + THIS.cLblSuffix,THIS.cfont,THIS.nfsize,THIS.cfstyle) * ;
			THIS.nFONT6 + THIS.nFONT18 + 20  &&amount for cbox
		THIS.nfdiff = .Width - m.nOldfwid
	ENDPROC

ENDDEFINE

*******************************************
DEFINE CLASS memoflds as inputs
*******************************************
ENDDEFINE

*******************************************
DEFINE CLASS genflds as inputs 
*******************************************
	
	PROCEDURE error
		PARAMETERS nError,cMethod,nLine
		* We need to handle a corrupted OLE object
		* this can get triggered when ControlSource is set
		LOCAL aErr
		DIMENSION aErrX[1]
		IF AERROR(aErrX)>0 AND aErrX[1,1] = 1420
			* ignore it and pass back
			=MESSAGEBOX(C_BADGENFLD_LOC)
			RETURN
		ENDIF
		
		* Otherwise pass it on
		DoDefault(nError,cMethod,nLine)
	ENDPROC
	
ENDDEFINE

*******************************************
DEFINE CLASS gridflds as inputs
*******************************************
ENDDEFINE

*******************************************
DEFINE CLASS labeldata as inputs
*******************************************

	PROCEDURE SetProps
		PARAMETER oNewObj,aAfieldData,cCaption
	
		ACOPY(aAfieldData,THIS.aFldData)
		THIS.cFieldName = UPPER(aAfieldData[1])
		THIS.cCaption = IIF(!EMPTY(m.cCaption),m.cCaption,THIS.cFieldName)
		* Container object
		* Note: this can also be a separate control such as
		* a checkbox which is not stored in a Controls class.
		
		WITH m.oNewObj
			* Add label portion of object
			* FP2.6 Wizards stored alias with field name. This can conflict with
			* long field names containing periods.
			IF TYPE(".Caption")#"U"
				.CAPTION = THIS.cCaption + THIS.cLblSuffix
			ENDIF
			IF THIS.lLblDefWid
				.WIDTH = THIS.nDefLblWid
			ELSE
				* Note: this next line resets .width since autosize only works in design mode
				IF TYPE(".AutoSize")#"U"
					.AutoSize = .T.
				ENDIF
				.WIDTH = .WIDTH
	      	ENDIF
		ENDWITH

	ENDPROC

	FUNCTION GetLblWid
		** get maximum label width so that we can align
		** fields uniformly
		PARAMETER aWizFields,clblsuffix
		LOCAL ctmpstr,ntmpwid,nlblwid,i
		m.nlblwid = 0
		FOR i = 1 TO ALEN(aWizFields)
			* get expression -- adjust if it has alias in it
			* FP2.6 Wizards stored alias with field name. This can conflict with
			* long field names containing periods.
			* ctmpstr=SUBSTR(aWizFields[m.i],AT('.',aWizFields[m.i])+1)+m.cLblSuffix
			ctmpstr = aWizFields[m.i] + m.cLblSuffix
			ntmpwid = TXTWIDTH(m.ctmpstr,THIS.cfont,THIS.nfsize,THIS.cfstyle)
			IF m.ntmpwid > m.nlblwid
				m.nlblwid=m.ntmpwid
			ENDIF
		ENDFOR
		
		* convert label width to pixels
		THIS.nDefLblWid = m.nlblwid*THIS.nfont6+THIS.nfont18
		RETURN THIS.nDefLblWid
	ENDFUNC


ENDDEFINE



******************************************************************************************
DEFINE CLASS FormBldrEngine AS FormWizEngine 
******************************************************************************************

	lRunningWizard = .F.
	lRunningBuilder = .T.		
	lAddColor = .T.				&&add background form color
	lExpandForm = .T.			&&allow form to expand
	lVertPref = .F.				&&field layout orientation preference
	nCols = 20					&&max columns for field layout
	nf = ""						&&reference to output container
	nSaveScaleMode = 3
	lUsePages = .F.	

	PROCEDURE GetContainer
		* optional 3rd parameter container for Form builder
		IF TYPE("m.oFRef")#"O"
			THIS.haderror = .T.
			RETURN
		ENDIF
		THIS.nf = m.oFRef
		THIS.nSaveScaleMode = THIS.nf.scalemode
		THIS.nf.scalemode = 3
	ENDPROC
	
	PROCEDURE setdims
		* setup dimensions
		THIS.nVLPOS = THIS.nLTopPos +  THIS.aUser[1]		&&current vert pos for lbl placement
		THIS.nHLPOS = THIS.nLLeftPos + THIS.aUser[2]		&&current hori pos for lbl placement
		THIS.nVINC  = 0
		THIS.nHINC  = THIS.nHLblSpace
		THIS.lAddColor = THIS.lAddColor
		THIS.nRightEdge = IIF(THIS.lExpandForm,THIS.nHoriRes,THIS.nf.width)	
		IF THIS.nColWidth > 0
			THIS.nMaxCols = MIN(THIS.nCols,INT((THIS.nRightEdge-THIS.nHLPOS)/THIS.nColWidth))
		ENDIF
		THIS.cThermTitle = C_THERMTITLEBLD_LOC
		THIS.nCurrCol = 1
		THIS.nMaxCols = IIF(THIS.nMaxCols<1,1,THIS.nMaxCols)
		IF THIS.nMaxCols > 1
			THIS.lIs1col = .F.
		ENDIF
		THIS.GetScrnRes()
		THIS.nBottom  = IIF(THIS.lExpandForm,THIS.nVertRes,THIS.nf.height)
	ENDPROC
	
	PROCEDURE CreateForm
		
		LOCAL nLClick,nTClick
		nTClick = THIS.nLTopPos + THIS.aUser[1]  + THIS.nf.top + 1 + SYSM(9) + SYSM(4)
		nLClick = THIS.nLLeftPos + THIS.aUser[2] + THIS.nf.left + 1  + SYSM(3)
		
		THIS.PreProcess
		THIS.FormSetup
		m.tmpleft = THIS.nf.left
		THIS.nf.left = 5000
		IF THIS.laddcolor
			THIS.nf.backcolor = THIS.nFormColor
			THIS.nf.picture = THIS.cFormPicture
		ENDIF
		IF !THIS.lVertPref AND THIS.nMaxCols > 1
			THIS.lIs1col = .F.
		ENDIF
		
		THIS.AddDetail		
		THIS.nf.left = m.tmpleft	
		THIS.SetFooter
		THIS.FormCleanup
		THIS.PostProcess
		THIS.DoTherm(-1,THERM_DONE_LOC)

	ENDPROC

	PROCEDURE SetFooter
		IF THIS.lExpandForm
			THIS.nf.height = MAX(THIS.nf.height,THIS.nVLPOS+THIS.nVINC+4)
			THIS.nf.width = MAX(THIS.nMaxRight+4,THIS.nf.width)
			THIS.nf.ScrollBars = IIF(THIS.lUsePages,0,3)
		ENDIF
	ENDPROC

	PROCEDURE FormCleanup
		THIS.nf.scalemode = THIS.nSaveScaleMode
		THIS.nf.refresh
	ENDPROC

ENDDEFINE

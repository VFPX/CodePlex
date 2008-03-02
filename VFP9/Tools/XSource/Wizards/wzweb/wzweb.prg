#INCLUDE "wzweb.h"

*--------------------------------------
DEFINE CLASS HTMLEngine AS WizEngineAll
*--------------------------------------
	
	cWizTitle=""
	cWebStyle=""
	cWebLayout=""
	cStyleSheet=""
	cBodyColor=""
	cBodyImage=""
	lCopyImages = .F.
	cGenHTMLAlias = ""
	cOptionsID = ""
	nHTMLFrames = 0
	lProcessCustomProperties = .F.
	vPreviewScope = 50
	cSourceName = ""
	cStyleName = ""
	
	DIMENSION aCustomTags[1,15]
	aCustomTags=""

	DIMENSION aWebStyles[1]
	aWebStyles=""
	
	DIMENSION aStyleOrder[1]
	aStyleOrder=""

	DIMENSION aOptions[1]
	aOptions=""

	DIMENSION aSaveOptions[1]
	aSaveOptions=""

	DIMENSION aTempFiles[1]
	aTempFiles=""

	PROCEDURE Destroy
		LOCAL i
		THIS.SetErrorOff=.T.
		FOR i = 1 TO ALEN(THIS.aTempFiles)
			IF FILE(THIS.aTempFiles[m.i])
				DELETE FILE (THIS.aTempFiles[m.i])
			ENDIF				
		ENDFOR
		THIS.SetErrorOff=.F.
		THIS.HadError=.F.
		DoDefault()
	ENDPROC

	PROCEDURE ProcessOutput
		*- the ProcessOutput method of the sample wizard will call this function

		LOCAL cValue, i, lnNumFields, lnAction, lcSortText, lcFieldText, oNewTag
		LOCAL lcWebLayout, lnSaveArea, lcID, lcSQL, lcData, lcScope
		LOCAL lcFldList, lnSaveRecord 

		lcScope = ""
		lnNumFields = ALEN(THIS.aWizFields,1)
		lcFieldText = ""
		FOR i = 1 TO lnNumFields
			lcFieldText = lcFieldText + THIS.aWizFields[m.i,1]+;
				IIF(m.i=lnNumFields,"",",")
		ENDFOR

		*- if the user selected a sort order, implement that here
		lnNumFields = ALEN(THIS.aWizSorts,1)
		lcSortText = ""

		IF THIS.lHasSortTag
			i = 1
			DO WHILE !EMPTY(KEY(m.i))
				IF UPPER(TAG(m.i)) == UPPER(THIS.aWizSorts[1])
					IF ATC(")",KEY(m.i))#0 OR ATC("+",KEY(m.i))#0
						THIS.aWizSorts[1] = ""
					ELSE
						THIS.aWizSorts[1] = KEY(m.i)
					ENDIF
					EXIT
				ENDIF
				i = m.i + 1
			ENDDO
		ENDIF
		
		IF !EMPTY(THIS.aWizSorts[1])
			lcSortText = "ORDER BY "
			FOR i = 1 TO lnNumFields
				lcSortText = lcSortText + THIS.aWizSorts[m.i,1]+;
					IIF(m.i=m.lnNumFields,"",",")
			ENDFOR
			lcSortText = m.lcSortText + IIF(!THIS.lSortAscend," DESC","")	
		ENDIF
		
		IF !ALIAS()==UPPER(THIS.cWizAlias)
			SELECT (THIS.cWizAlias)
		ENDIF

		lcData = CURSORGETPROP("sourcename")
		THIS.cSourceName = CURSORGETPROP("sourcename")
		IF !EMPTY(CURSORGETPROP("database")) AND SET("DATA")#THIS.cDBCAlias
			OPEN DATABASE (THIS.cDBCName)
		ENDIF
		IF  CURSORGETPROP("sourcetype")#3
			* Need to handle Parameterized view problems
			THIS.SetErrorOff = .T.
			REQUERY()
			THIS.SetErrorOff = .F.
			IF THIS.HadError
				THIS.HadError = .F.
				MESSAGEBOX(MESSAGE())
				RETURN
			ENDIF
		ENDIF
		
		SELECT &lcFieldText. FROM (lcData) &lcSortText. INTO CURSOR webwizard_query
		
		THIS.SaveProfile()			&&add layout and style info
		THIS.SetCustomOptions(.t.)	&&add layout specific options for processing before generation
		THIS.SetCustomOptions()		&&add layout specific options for processing after generation
		THIS.AddCustomTags(3)		&&add header custom tags
		THIS.AddCustomTags(1)		&&add before body custom tags
		THIS.AddCustomTags(2)		&&add after body custom tags

		* lcWebLayout = THIS.cWebLayout
		lcWebLayout = TYPE_WIZARD		
		lnAction=5
		
		DO CASE
		CASE VARTYPE(THIS.vPreviewScope)="C"
			lcScope = ALLTRIM(THIS.vPreviewScope)
		CASE VARTYPE(THIS.vPreviewScope)="N" AND ;
		  THIS.nWizAction = 9 AND !EMPTY(THIS.vPreviewScope)
			lcScope = "NEXT "+TRANS(THIS.vPreviewScope)		&&do not localize
		ENDCASE
				
		DO (_GENHTML) WITH THIS.cOutFile,ALIAS(),lnAction,,lcWebLayout,lcScope

		* Reset Field Caption
		_oHTML.cPreGenerateTableScript="oEngine.UpdateFieldList()"
		_oHTML.Generate()

		* Run script code for any styles selected
		FOR i = 1 TO ALEN(THIS.aWebStyles)
			_oHTML.RunScript(THIS.aWebStyles[m.i])
		ENDFOR
		
		* Save Wizard record
		IF THIS.nWizAction = 4 OR !EMPTY(THIS.cStyleName)
			lnSaveArea=SELECT()
			SELECT (THIS.cGenHTMLAlias)
			lcID = IIF(EMPTY(THIS.cStyleName),SYS(2015),LEFT(ALLTRIM(THIS.cStyleName),24))
			lnSaveRecord = RECNO()
			LOCATE FOR ALLTRIM(type)==TYPE_WIZARD AND;
				ALLTRIM(UPPER(id))==UPPER(lcID) AND !DELETED()
			IF FOUND()
				DELETE
			ENDIF
			GO lnSaveRecord
			REPLACE ID WITH lcID, SAVE WITH .T.
			SELECT (lnSaveArea)
		ENDIF
		
		* Handle output action
		DO CASE
		CASE THIS.nWizAction = 2
			*- create and open HTML file in a text editor
			_oHTML.ViewSource()
		CASE THIS.nWizAction = 3
			*- create and open HTML file in a browser
			_oHTML.Show()
		CASE THIS.nWizAction = 4
			*- create script
			IF EMPTY(THIS.cOutFile)
				RETURN
			ENDIF
					
			STRTOFILE(SCRIPTHEADER_LOC,THIS.cOutFile)
			STRTOFILE("LOCAL lnSaveArea"+C_CRLF,THIS.cOutFile,.T.)
			STRTOFILE("lnSaveArea=SELECT()"+C_CRLF,THIS.cOutFile,.T.)
			STRTOFILE("SELECT 0"+C_CRLF+C_CRLF,THIS.cOutFile,.T.)
			SELECT (THIS.cWizAlias)
			IF !EMPTY(CURSORGETPROP("database"))
				STRTOFILE([OPEN DATABASE "]+THIS.cDBCName+["]+C_CRLF,THIS.cOutFile,.T.)
			ENDIF
			lcData = CURSORGETPROP("sourcename")
			lcSQL = [SELECT ] + lcFieldText + [ FROM "]+lcData+[" ;]+C_CRLF+;
					[  ]+lcSortText + [ INTO CURSOR webwizard_query] + C_CRLF+C_CRLF
			STRTOFILE(lcSQL,THIS.cOutFile,.T.)
			lcFldList = THIS.UpdateFieldList()
			IF !EMPTY(lcFldList)
				lcFldList = [+"]+lcFldList+["]
			ENDIF

			STRTOFILE([IF EMPTY(_GENHTML)]+C_CRLF,THIS.cOutFile,.T.)
			STRTOFILE("  _GENHTML='GenHTML.PRG'"+C_CRLF,THIS.cOutFile,.T.)
			STRTOFILE("ENDIF"+C_CRLF,THIS.cOutFile,.T.)

			STRTOFILE([DO (_GENHTML) WITH "]+FORCEEXT(THIS.cOutFile,"HTM")+ [",ALIAS()]+lcFldList+[,2,,"]+lcID+["]+C_CRLF+C_CRLF,;
				THIS.cOutFile,.T.)
			STRTOFILE([IF USED("webwizard_query")]+C_CRLF,THIS.cOutFile,.T.)
			STRTOFILE("  USE IN webwizard_query"+C_CRLF,THIS.cOutFile,.T.)
			STRTOFILE("ENDIF"+C_CRLF,THIS.cOutFile,.T.)
			STRTOFILE("SELECT (lnSaveArea)"+C_CRLF,THIS.cOutFile,.T.)
			MODIFY COMMAND (THIS.cOutFile) NOWAIT
		CASE THIS.nWizAction = 9
			*- Preview
			* Need to keep trap of temp files so we can clean up later
			DIMENSION THIS.aTempFiles[ALEN(THIS.aTempFiles)+1]
			THIS.aTempFiles[ALEN(THIS.aTempFiles)]= THIS.cOutFile
			* Check if layout created extra files as well
			IF PEMSTATUS(_oHTML,"aGeneratedFiles",5) AND TYPE("_oHTML.aGeneratedFiles[1]")="C"
				FOR i = 1 TO ALEN(_OHTML.aGeneratedFiles)
					DIMENSION THIS.aTempFiles[ALEN(THIS.aTempFiles)+1]
					THIS.aTempFiles[ALEN(THIS.aTempFiles)]= _OHTML.aGeneratedFiles[m.i]
				ENDFOR
			ENDIF
			_oHTML.Show()
		OTHERWISE
			*- create HTML file only
			_oHTML.CreateOutFile(_oHTML.cOutFile)
		ENDCASE

		IF USED("webwizard_query")
  			USE IN webwizard_query
		ENDIF

		RELEASE _oHTML

	ENDPROC

	PROCEDURE UpdateFieldList
		LOCAL i,lcSource,lcCaption,lcFldStr,llFoundCaption
		IF EMPTY(THIS.cDBCName)
			RETURN ""
		ENDIF
		IF SET("DATA")#THIS.cDBCAlias
			OPEN DATABASE (THIS.cDBCName)
		ENDIF
		llFoundCaption=.F.
		lcFldStr = ""
		lcSource = THIS.cSourceName
		FOR i = 1 TO ALEN(_oHTML.aFieldList,1)
			lcFldStr = lcFldStr + ","
			lcCaption = ALLTRIM(DBGETPROP(lcSource+"."+_oHTML.aFieldList[m.i,1],"field","caption"))
			IF !EMPTY(lcCaption)
				llFoundCaption=.T.
				_oHTML.aFieldList[m.i,5] = lcCaption
				lcFldStr = lcFldStr + lcCaption +"@"
			ENDIF
			lcFldStr = lcFldStr + _oHTML.aFieldList[m.i,1]
		ENDFOR
		RETURN IIF(llFoundCaption,lcFldStr,"")
	ENDPROC

	PROCEDURE AddCustomTags(nTagPosition)

		LOCAL i,oHTMLTag,oHTMLTag2,lnTagType,lcHeading,lHasFontTag,lcTagStr,lnSaveArea
		LOCAL lcHTMLTag,llSetTopTag
		PRIVATE laTags
		DIMENSION laTags[1]
		STORE "" TO laTags
		IF EMPTY(THIS.aCustomTags[1])
			RETURN 
		ENDIF
				
		DO CASE
		CASE nTagPosition = 1
			lcHTMLTag = "_oHTML.Body"
		CASE nTagPosition = 2
			lcHTMLTag = "_oHTML.Body"
		CASE nTagPosition = 3
			lcHTMLTag = "_oHTML.Body"
		ENDCASE

		FOR i = 1 TO ALEN(THIS.aCustomTags,1)
			IF THIS.aCustomTags[m.i,2]#nTagPosition
				LOOP
			ENDIF
			IF !llSetTopTag
				THIS.InsaItem(@laTags,[oHTMLTag = .NULL.])
				THIS.InsaItem(@laTags,[IF _oHTML.lBodyTag])
				THIS.InsaItem(@laTags,[  oHTMLTag = _oHTML.Body])
				THIS.InsaItem(@laTags,[ELSE])
				THIS.InsaItem(@laTags,[  oHTMLTag = _oHTML])
				THIS.InsaItem(@laTags,[ENDIF])
				llSetTopTag = .T.			
			ENDIF
			lnTagType = THIS.aCustomTags[m.i,15]
			
			DO CASE
			CASE lnTagType = 1		&&text
				THIS.AddFontTag("oHTMLTag",m.i,@laTags)
				THIS.AddBoldTag("oHTMLTag",m.i,@laTags)
				THIS.AddItalicTag("oHTMLTag",m.i,@laTags)
				THIS.InsaItem(@laTags,[oHTMLTag.AddItem("]+THIS.aCustomTags[m.i,5]+[")])

			CASE lnTagType = 2		&&hyperlink
				IF !EMPTY(THIS.aCustomTags[m.i,11])
					THIS.aCustomTags[m.i,13]=""				
					THIS.InsaItem(@laTags,[oHTMLTag2 = oHTMLTag.AddTag("A")])
					THIS.InsaItem(@laTags,[oHTMLTag2.HREF = "]+THIS.GetHREF(THIS.aCustomTags[m.i,11])+["])
					THIS.AddFontTag("oHTMLTag2",m.i,@laTags)
					THIS.AddBoldTag("oHTMLTag2",m.i,@laTags)
					THIS.AddItalicTag("oHTMLTag2",m.i,@laTags)
					THIS.InsaItem(@laTags,[oHTMLTag2.AddItem("]+IIF(EMPTY(THIS.aCustomTags[m.i,5]),;
						THIS.aCustomTags[m.i,11],THIS.aCustomTags[m.i,5])+[")])
				ENDIF

			CASE lnTagType = 3		&&image
				IF !EMPTY(THIS.aCustomTags[m.i,11])
					THIS.InsaItem(@laTags,[oHTMLTag2 = oHTMLTag.AddTag("IMG")])
					THIS.InsaItem(@laTags,[oHTMLTag2.SRC = "]+THIS.GetHREF(THIS.aCustomTags[m.i,11])+["])
				ENDIF

			CASE lnTagType = 4		&&marquee
				THIS.aCustomTags[m.i,14]=0
				THIS.InsaItem(@laTags,[oHTMLTag2 = oHTMLTag.AddTag("Marquee")])
				IF !EMPTY(THIS.aCustomTags[m.i,12])
					THIS.InsaItem(@laTags,[oHTMLTag2.BgColor = "]+THIS.aCustomTags[m.i,12]+["])
				ENDIF
				THIS.AddFontTag("oHTMLTag2",m.i,@laTags)
				THIS.AddBoldTag("oHTMLTag2",m.i,@laTags)
				THIS.AddItalicTag("oHTMLTag2",m.i,@laTags)
				THIS.InsaItem(@laTags,[oHTMLTag2.AddItem("]+THIS.aCustomTags[m.i,5]+[")])

			CASE lnTagType = 5		&&horizontal rule
				THIS.InsaItem(@laTags,[oHTMLTag2 = oHTMLTag.AddTag("HR")])
				THIS.InsaItem(@laTags,[oHTMLTag2.Align = ]+THIS.GetAlign(THIS.aCustomTags[m.i,14]))
				IF !EMPTY(THIS.aCustomTags[m.i,12])
					THIS.InsaItem(@laTags,[oHTMLTag2.Color = "]+THIS.aCustomTags[m.i,12]+["])
				ENDIF
				
			CASE lnTagType = 6		&&line break
				THIS.InsaItem(@laTags,[oHTMLTag2 = oHTMLTag.AddTag("BR")])
				
			CASE lnTagType = 7		&&tag
				THIS.InsaItem(@laTags,[oHTMLTag.AddItem("]+THIS.aCustomTags[m.i,5]+[")])
				
			ENDCASE
			
			* Add Class attribute
			IF !EMPTY(THIS.aCustomTags[m.i,4]) AND !INLIST(lnTagType,1,7)
				THIS.InsaItem(@laTags,[oHTMLTag2._Class = "]+THIS.aCustomTags[m.i,4]+["])
			ENDIF
		ENDFOR
		
		lcTagStr=""
		FOR i = 1 TO ALEN(laTags)
			IF !EMPTY(ALLTRIM(laTags[m.i]))
				lcTagStr = lcTagStr+ALLTRIM(laTags[m.i])+C_CRLF
			ENDIF
		ENDFOR
		lnSaveArea=SELECT()
		SELECT (THIS.cGenHTMLAlias)
		
		DO CASE
		CASE nTagPosition = 1	&&before data
			REPLACE PreScript WITH PreScript + C_CRLF + lcTagStr
		CASE nTagPosition = 2	&&after data
			REPLACE GenScript WITH GenScript + C_CRLF + lcTagStr
		CASE nTagPosition = 3	&&header
			REPLACE PreScript WITH PreScript + C_CRLF + lcTagStr
		ENDCASE
		
		SELECT (lnSaveArea)
	ENDPROC

	PROCEDURE SortStyles
		* Cannot simply do an ACOPY since aWebStyles may 
		* have changed since sorting done.
		LOCAL i,laTmp,lcSaveExact
		DIMENSION laTmp[1]
		IF EMPTY(THIS.aStyleOrder[1])
			* No sort order applied
			RETURN
		ENDIF
		ACOPY(THIS.aStyleOrder,laTmp)
		lcSaveExact=SET("EXACT")
		SET EXACT ON
		* Get valid sorts
		FOR i = ALEN(THIS.aStyleOrder) TO 1 Step -1
			IF ASCAN(THIS.aWebStyles,laTmp[m.i])=0
				ADEL(laTmp,m.i)
				IF ALEN(laTmp)>1
					DIMENSION laTmp[ALEN(latmp)-1]
				ENDIF
			ENDIF
		ENDFOR
		IF ALEN(THIS.aWebStyles)#ALEN(laTmp) OR EMPTY(laTmp[1])
			FOR i = 1 TO ALEN(THIS.aWebStyles)
				IF ASCAN(laTmp,THIS.aWebStyles[m.i])#0
					LOOP
				ENDIF
				DIMENSION laTmp[ALEN(laTmp)+1]
				laTmp[ALEN(laTmp)] = THIS.aWebStyles[m.i]
			ENDFOR
		ENDIF
		DIMENSION THIS.aWebStyles[1]
		ACOPY(laTmp,THIS.aWebStyles)
		SET EXACT &lcSaveExact
	ENDPROC
	
	PROCEDURE SaveProfile
		LOCAL lnSaveArea,lcLinkStr,i,lcPreStr,lcPostStr,laPreScript,laPostScript,lcTmpStr
		THIS.SortStyles()
		lnSaveArea = SELECT()
		DIMENSION laPreScript[1]
		DIMENSION laPostScript[1]
		store "" to laPreScript,laPostScript
		SELECT (THIS.cGenHTMLAlias)
		LOCATE FOR ALLTRIM(id)==TYPE_WIZARD AND ALLTRIM(type)==TYPE_WIZARD AND !DELETED()
		IF !FOUND()
			INSERT INTO (DBF()) (type,id) ;
				VALUES(TYPE_WIZARD,TYPE_WIZARD)
		ENDIF
		REPLACE PreScript with "",PostScript WITH "",GenScript WITH ""
		* Get string for Links field
		lcLinkStr = ""
		FOR i = 1 TO ALEN(THIS.aWebStyles)
			IF !EMPTY(THIS.aWebStyles[m.i])
				lcLinkStr = lcLinkStr + ALLTRIM(THIS.aWebStyles[m.i]) + C_CRLF
			ENDIF
		ENDFOR
		lcLinkStr = lcLinkStr + THIS.cWebLayout

		* Get string for Prescript field
		lcPropStr=""
	
		* Add style sheet and custom body settings
		IF !EMPTY(THIS.cStyleSheet)
			THIS.Insaitem(@laPreScript,[oNewTag = _oHTML.Head.AddTag("Link")])
			THIS.Insaitem(@laPreScript,[oNewTag.rel = "stylesheet"])
			THIS.Insaitem(@laPreScript,[oNewTag.href = "]+THIS.cStyleSheet+["])
		ENDIF
		IF !EMPTY(THIS.cWizTitle)
			THIS.Insaitem(@laPreScript,[_oHTML.Head.Title.AddText("]+THIS.cWizTitle+[")])
		ENDIF
		IF !EMPTY(THIS.cBodyColor)
			THIS.Insaitem(@laPreScript,[_oHTML.Body.bgColor = "]+THIS.cBodyColor+["])
		ENDIF
		IF !EMPTY(THIS.cBodyImage)
			THIS.Insaitem(@laPreScript,[_oHTML.Body.background = "]+THIS.GetHREF(THIS.cBodyImage)+["])
		ENDIF

		lcPreStr=""
		FOR i = 1 TO ALEN(laPreScript)
			IF !EMPTY(ALLTRIM(laPreScript[m.i]))
				lcPreStr = lcPreStr+ALLTRIM(laPreScript[m.i])+C_CRLF
			ENDIF
		ENDFOR

		lcPostStr=""
		FOR i = 1 TO ALEN(laPostScript)
			IF !EMPTY(ALLTRIM(laPostScript[m.i]))
				lcPostStr = lcPostStr+ALLTRIM(laPostScript[m.i])+C_CRLF
			ENDIF
		ENDFOR

		REPLACE Links WITH lcLinkStr, Prescript WITH lcPreStr, Postscript WITH lcPostStr

		SELECT (lnSaveArea)
	ENDPROC

	PROCEDURE SetCustomOptions
		LPARAMETER tlSetBefore
		LOCAL i,lcStyleProp,lcStyleVal,laStyles,lcSaveExact,laGenScript,lnSaveArea,lcGenStr,llSetBefore
		DIMENSION laStyles[1,2]
		DIMENSION laGenScript[1]
		STORE "" TO laGenScript
		lcSaveExact = SET("EXACT")
		IF VARTYPE(tlSetBefore)#"L"
			tlSetBefore = .F.
		ENDIF
		llSetBefore=tlSetBefore
		
		IF !THIS.lProcessCustomProperties OR EMPTY(THIS.aSaveOptions[1])
			RETURN
		ENDIF
		SET EXACT ON
		FOR i = 1 TO ALEN(THIS.aOptions)
			IF THIS.aSaveOptions[m.i,3]#llSetBefore
				LOOP
			ENDIF
			
			* Test for HREF flag to CopyFile
			IF BITTEST(THIS.aSaveOptions[m.i,5],0)
				lcStyleProp=ALLTRIM(LEFT(THIS.aOptions[m.i],ATC("=",THIS.aOptions[m.i])-1))
				lcStyleVal=ALLTRIM(THIS.aSaveOptions[m.i,2])
				lcNewHref = THIS.GetHREF(lcStyleVal)
				IF !UPPER(lcNewHref)==UPPER(lcStyleVal)
					THIS.aOptions[m.i]=lcStyleProp+[="]+lcNewHref+["]
					THIS.aSaveOptions[m.i,2] = lcNewHref 
				ENDIF
			ENDIF
			
			* Get styles
			IF !EMPTY(THIS.aSaveOptions[m.i,4])
				lcStyleProp=ALLTRIM(LEFT(THIS.aOptions[m.i],ATC("=",THIS.aOptions[m.i])-1))
				lcStyleVal=ALLTRIM(SUBSTR(THIS.aOptions[m.i],ATC("=",THIS.aOptions[m.i])+1))
				IF !EMPTY(laStyles[1])
					lnPos=ASCAN(laStyles,lcStyleProp)
					IF lnPos#0	&&style already exists, so lets add to it
						laStyles[lnPos+1] = laStyles[lnPos+1]+"; "+THIS.aSaveOptions[m.i,4]+": "+lcStyleVal
						LOOP
					ENDIF
					DIMENSION laStyles[ALEN(laStyles,1)+1,2]
				ENDIF
				laStyles[ALEN(laStyles,1),1] = lcStyleProp
				laStyles[ALEN(laStyles,1),2] = THIS.aSaveOptions[m.i,4]+": "+lcStyleVal
				LOOP
			ENDIF
			
			lcCmd = THIS.aOptions[m.i]
			IF !EMPTY(lcCmd)
				THIS.INSAITEM(@laGenScript,lcCMD)
			ENDIF
		ENDFOR
		SET EXACT &lcSaveExact
		
		* Process styles
		FOR i = 1 TO ALEN(laStyles,1)
			IF EMPTY(laStyles[m.i,1]) OR EMPTY(laStyles[m.i,2])
				LOOP
			ENDIF
			lcCmd = laStyles[m.i,1] + "=[" + laStyles[m.i,2] +"]"
			THIS.INSAITEM(@laGenScript,lcCMD)
		ENDFOR
		
		* Update fields		
		lcGenStr=""
		FOR i = 1 TO ALEN(laGenScript)
			IF !EMPTY(ALLTRIM(laGenScript[m.i]))
				lcGenStr = lcGenStr + "_oHTML." + ALLTRIM(laGenScript[m.i])+C_CRLF
			ENDIF
		ENDFOR
		
		lnSaveArea=SELECT()
		SELECT (THIS.cGenHTMLAlias)
		IF llSetBefore
			REPLACE Prescript WITH Prescript + C_CRLF + lcGenStr
		ELSE
			REPLACE GenScript WITH GenScript + C_CRLF + lcGenStr
		ENDIF
		SELECT (lnSaveArea)
		
	ENDPROC

	FUNCTION GetAlign(lnAlignCode)
		DO CASE
		CASE lnAlignCode = 1
			RETURN ["left"]
		CASE lnAlignCode = 2
			RETURN ["right"]
		CASE lnAlignCode = 3
			RETURN ["center"]
		OTHERWISE
			RETURN ["left"]
		ENDCASE
	ENDPROC

	FUNCTION GetHeading(lnHeadingCode)
		IF lnHeadingCode=1
			RETURN ""
		ELSE
			RETURN "H"+TRANS(lnHeadingCode-1)
		ENDIF
	ENDPROC

	FUNCTION GetHREF(lcHRef)
		LOCAL lcJustFname,lcNewFile
		IF ATC("://",lcHRef)#0
			RETURN lcHREF
		ENDIF
		IF ATC("www.",LEFT(lcHRef,4))#0
			RETURN "http://"+ALLTRIM(lcHREF)
		ENDIF
		* Assume user specified a local file
		* Don't copy file if Previewing to avoid creating unneeded files.
		IF THIS.lCopyImages AND THIS.nWizAction#9 AND FILE(lcHREF)
			lcJustFname = JUSTFNAME(lcHREF)
			lcNewFile = ADDBS(JUSTPATH(THIS.cOutFile))+lcJustFname
			IF !FILE(lcNewFile)
				COPY FILE (lcHREF) TO (lcNewFile)
			ENDIF
			lcHREF = lcJustFname
		ENDIF
		RETURN lcHREF
	ENDPROC
	
	FUNCTION AddBoldTag(tcHTMLTagRef,tnElement,taTags)
		* Add bold tag
		IF THIS.aCustomTags[m.tnElement,9]
			THIS.InsaItem(@taTags,tcHTMLTagRef+[ = ]+tcHTMLTagRef+[.AddTag("strong")])
		ENDIF
	ENDPROC

	FUNCTION AddItalicTag(tcHTMLTagRef,tnElement,taTags)
		* Add italic tag
		IF THIS.aCustomTags[m.tnElement,10]
			THIS.InsaItem(@taTags,tcHTMLTagRef+[ = ]+tcHTMLTagRef+[.AddTag("em")])
		ENDIF
	ENDPROC

	FUNCTION AddFontTag(tcHTMLTagRef,tnElement,taTags)
		LOCAL lcHeading,lHasFontTag

		* Check if using heading (Hn)
		lcHeading = THIS.GetHeading(THIS.aCustomTags[m.tnElement,6])
		IF !EMPTY(lcHeading)
			THIS.InsaItem(@taTags,tcHTMLTagRef+[ = ]+tcHTMLTagRef+[.AddTag("]+lcHeading+[")])
			THIS.InsaItem(@taTags,tcHTMLTagRef+[.Align = ]+THIS.GetAlign(THIS.aCustomTags[m.tnElement,14]))
		ENDIF

		IF EMPTY(lcHeading)
			IF THIS.aCustomTags[m.tnElement,14]>0
				THIS.InsaItem(@taTags,tcHTMLTagRef+[ = ]+tcHTMLTagRef+[.AddTag("P")])
				THIS.InsaItem(@taTags,tcHTMLTagRef+[.Align = ]+THIS.GetAlign(THIS.aCustomTags[m.tnElement,14]))
			ENDIF

			* Add Font tag
			IF !EMPTY(THIS.aCustomTags[m.tnElement,7]) OR !EMPTY(THIS.aCustomTags[m.tnElement,8])			
				THIS.InsaItem(@taTags,tcHTMLTagRef+[ = ]+tcHTMLTagRef+[.AddTag("font")])
				lHasFontTag = .T.
				IF !EMPTY(THIS.aCustomTags[m.tnElement,7])
					THIS.InsaItem(@taTags,tcHTMLTagRef+[.face = "]+ALLTRIM(THIS.aCustomTags[m.tnElement,7])+["])
				ENDIF
				IF !EMPTY(THIS.aCustomTags[m.tnElement,8])
					THIS.InsaItem(@taTags,tcHTMLTagRef+[.Size = ]+TRANS(THIS.aCustomTags[m.tnElement,8]))
				ENDIF
			ENDIF
		ENDIF
		
		* Add the forecolor
		IF !EMPTY(THIS.aCustomTags[m.tnElement,13])
			IF !m.lHasFontTag
				THIS.InsaItem(@taTags,tcHTMLTagRef+[ = ]+tcHTMLTagRef+[.AddTag("font")])
			ENDIF
			THIS.InsaItem(@taTags,tcHTMLTagRef+[.Color = "]+TRANS(THIS.aCustomTags[m.tnElement,13])+["])
		ENDIF
	ENDPROC

ENDDEFINE

LPARAMETERS tcFile

IF NOT PEMSTATUS(_SCREEN,"_analyst",5)
	_SCREEN.newobject("_analyst","_codeanalyzer","MAIN.PRG",HOME()+"CODEANAL.APP")
ENDIF

_SCREEN._analyst.Analyze(tcFile)

DEFINE CLASS _codeanalyzer AS CUSTOM
	cFile = ""
	cMainProgram = ""
	lLineRules = .F.
	cLine = ""
	cError = ""
	nLine = 0
	cFuncName = ""
	oTherm = .NULL.
	oObject = .NULL.
	cObject= ""
	cCode = ""
	cHomeDir = ""
	cAnalysisCursor = ""
	nFuncLines = 0
	cWarningID = ""
	nFileLines = 0
	cMessage = ""
	lDisplayMessage = .T.
	lDisplayForm = .T.
	cTable = ""


	PROCEDURE CreateRuleTable

		IF NOT FILE(THIS.cHomeDir+"CODERULE.DBF")
			LOCAL lnArea
			lnarea = SELECT()
			SELECT 0
			CREATE TABLE (THIS.cHomeDir+"CODERULE.DBF") (; 
				Type C(1),;
				NAME C(30),;
				Active L,;
				Descript M,;
				Script M,;
				Program M,;
				Classlib C(30),;
				Classname C(50),;
				TimeStamp T,;
				UniqueID C(10);
				)
		ENDIF
		
	ENDPROC
	
	PROCEDURE Destroy
		IF NOT ISNULL(THIS.oTherm)
			THIS.otherm.hide()
			THIS.otherm.release()
		ENDIF
	ENDPROC
	
	PROCEDURE Configure
		LOCAL lnArea
		lnArea = SELECT()
		IF NOT USED("CODERULE")
		USE HOME()+"CODERULE" IN 0
		ENDIF
		DO FORM ConfigureAnalyst
		SELECT (lnArea)
	ENDPROC

	PROCEDURE AddWarning
		LPARAMETERS tcWarning,tcType
		IF NOT EMPTY(THIS.aWarnings(1,1))
			DIMENSION THIS.aWarnings(ALEN(THIS.aWarnings,1)+1,3)
		ENDIF
		DIMENSION THIS.aWarnings(ALEN(THIS.aWarnings,1),3)
		THIS.aWarnings(ALEN(THIS.aWarnings,1),1)=tcWarning
		IF EMPTY(THIS.cFile)
			THIS.cFile = "Unknown"
		ENDIF
		THIS.aWarnings(ALEN(THIS.aWarnings,1),2)=THIS.cFile
		THIS.aWarnings(ALEN(THIS.aWarnings,1),3)=THIS.cWarningID
		IF USED(THIS.cAnalysisCursor)
			LOCAL lnArea
			lnArea = SELECT()
			SELECT (THIS.cAnalysisCursor)
			THIS.AddWarningCursor(tcWarning)
			*!* REPLACE warnings WITH warnings + tcWarning +CHR(13)+CHR(10)
			SELECT (lnArea)
		ENDIF
		
	ENDPROC
	PROCEDURE AddWarningCursor
		LPARAMETERS tcWarning
		
		LOCAL lcFile,lcID,lcFunc,lcType
		lcType = "Warning"
		lcID = THIS.cWarningID
		lcFile = THIS.cFile
		lcFunc = THIS.cFuncName
		IF NOT EMPTY(THIS.cObject)
			lcFunc = TRIM(THIS.cObject) + "."+lcFunc
		ENDIF
		IF EMPTY(THIS.cAnalysisCursor)
			THIS.BuildAnalysisCursor()
		ENDIF
		lcFileType = THIS.GetFileType()
		
		INSERT INTO (THIS.cAnalysisCursor) (cfunc,cprog,cType,cFileType,cWarning,warnings) ;
			VALUES (lcFunc,lcFile,lcType,lcFileType,lcID,tcWarning)
		
	ENDPROC
	
	PROCEDURE GetFileType
		LOCAL lcExt,lcRet
		lcRet = "Code"
		lcExt = UPPER(JUSTEXT(THIS.cFile))
		DO CASE
			CASE lcExt = "VCX"
				lcRet = "Classes"
			CASE lcExt = "SCX"
				lcRet = "Forms"
			CASE lcExt = "MNX"
				lcRet = "Menus"
			CASE lcExt = "PRG"
				lcRet = "Programs"
			CASE lcExt = "APP"
				lcRet = "Apps"

		ENDCASE
		RETURN lcRet
	ENDPROC
	
	PROCEDURE AddMessage
		LPARAMETERS tcMsg
		THIS.cMessage = THIS.cMessage + IIF(EMPTY(THIS.cMessage),"",CHR(13)+CHR(10))+tcMsg
	ENDPROC
	
	PROCEDURE INIT
		THIS.cHomeDir = HOME()

		IF NOT PEMSTATUS(THIS,"aCode",5)
			THIS.ADDPROPERTY("aCode(1,3)")
		ENDIF
		IF NOT PEMSTATUS(THIS,"awarnings",5)
			THIS.AddProperty("awarnings(1,3)")
		ENDIF
		THIS.aWarnings(1,1) = ""
		THIS.aWarnings(1,2) = ""
		THIS.aWarnings(1,3) = ""
		THIS.aCode(1,1) = ""
		IF NOT PEMSTATUS(THIS,"aRules",5)
			THIS.ADDPROPERTY("aRules(1,5)")
		ENDIF
		THIS.CreateRuleTable()
		
		THIS.LoadRules()

		DEFINE BAR 5942 OF _MTOOLS PROMPT "Code Analyst..." AFTER  _MTL_TOOLBOX
		ON SELECTION BAR 5942 OF _MTOOLS DO HOME()+"CODEANAL.APP"

	ENDPROC

	PROCEDURE BuildAnalysisCursor
		LOCAL lnArea
		lnArea = SELECT()
		SELECT 0
		THIS.cAnalysisCursor = "_AnalysisResults" && SYS(2015)
		CREATE CURSOR (THIS.cAnalysisCursor) (;
			cFileType C(10),;
			cFunc C(50),;
			cProg C(125),;
			cType C(10),;
			cWarning C(10),;
			Warnings M;
			)
		INDEX ON cFunc+cProg TAG funcProg
		
		SELECT (lnArea)
		
	ENDPROC
	
	PROCEDURE AddToCursor
		LPARAMETERS tcFunc,tcProg,tcType
		
		IF EMPTY(tcType)
			tcType = JUSTEXT(tcProg)
		ENDIF
		IF EMPTY(tcType)
			tcType = "Unknown"
		ENDIF
		IF EMPTY(THIS.cAnalysisCursor) OR NOT USED(THIS.cAnalysisCursor)
			THIS.BuildAnalysisCursor()
		ENDIF
		IF EMPTY(tcFunc)
			tcFunc = THIS.cFile
		ENDIF
		IF EMPTY(tcProg)
			tcProg = THIS.cFuncName
		ENDIF
		tcFunc = PADR(tcFunc,50)
		tcProg = PADR(tcProg,125)
		IF NOT SEEK(tcfunc+tcProg,THIS.cAnalysisCursor)
		
		INSERT INTO (THIS.cAnalysisCursor) (cfunc,cprog,cType) ;
			VALUES (tcFunc,tcProg,tcType)
		ENDIF
	ENDPROC
	
	PROCEDURE LoadRules
		IF FILE(HOME()+"CODERULE.DBF")
			SELECT NAME,TYPE,script,uniqueid FROM HOME()+"CODERULE" WHERE Active INTO ARRAY THIS.aRules
			LOCAL lni
			FOR lni = 1 TO ALEN(THIS.aRules,1)
				IF EMPTY(THIS.aRules(lni,1))
					LOOP
				ENDIF
				IF THIS.aRules(lni,2)="L"
					THIS.lLineRules = .T. && Needed for performance checks
					EXIT
				ENDIF
			ENDFOR
		ENDIF

	ENDPROC

	PROCEDURE ResetArrays
		DIMENSION THIS.aCode(1,3)
		THIS.aCode(1,1) = ""
		DIMENSION THIS.aWarnings(1,3)
		THIS.aWarnings(1,1) = ""
		THIS.aWarnings(1,2) = ""
		THIS.aWarnings(1,3) = ""
	
	ENDPROC
	
	PROCEDURE Analyze
		LPARAMETERS tcFile
		THIS.cMessage = ""
		THIS.cMainProgram = tcFile
		IF ISNULL(THIS.oTherm)
			THIS.oTherm = NEWOBJECT("cprogressform","foxref.vcx",HOME()+"CODEANAL.APP")
			THIS.oTherm.SetMax(100)
		ENDIF
		LOCAL lc
		THIS.ResetArrays()
		IF EMPTY(tcFile)
			IF ASELOBJ(la,1)=0
				IF TYPE("_VFP.ActiveProject")="U"
				
				tcFile = GETFILE("PRG;PJX;VCX;SCX","Select file","Open",1,"Select file to analyze")
				IF EMPTY(tcFile)
					RETURN
				ENDIF
				ELSE
					tcFile = _VFP.ActiveProject.Name  
				ENDIF
			ENDIF
		ENDIF

		IF EMPTY(tcFile)
			lc = "Current Object"
			THIS.cFile = lc
			THIS.cMainProgram = lc
			THIS.oTherm.SetDescription("Analyzing "+lc)
			THIS.oTherm.SetProgress(1)
			DOEVENTS
			THIS.oTherm.Show()
			THIS.AddToCursor(la(1).Name,la(1).Name,"Object")
			
			THIS.AnalyzeCurrObj()
		ELSE
			lc = tcFile
			IF EMPTY(THIS.cMainProgram)
			THIS.cMainProgram = lc
			ENDIF
			THIS.cFile = lc
			THIS.oTherm.SetDescription("Analyzing "+lc)
			THIS.oTherm.SetProgress(1)
			DOEVENTS
			THIS.oTherm.Show()
			THIS.AddToCursor(lc,lc,"File")
			THIS.AnalFile(tcFile)
		ENDIF

		THIS.oTherm.Hide()
		IF THIS.lDisplayForm
			IF NOT WEXIST("frmCodeAnalResults")
				SELECT 0
				DO FORM codeanalresults 
			ENDIF
		ENDIF

	PROCEDURE AnalyzeCurrObj
		LPARAMETERS tlWork

		THIS.cFile = "Current Object: "+la(1).Name
		DIMENSION THIS.aCode(1,3)
		THIS.aCode(1,1) = ""

		THIS.analyzeObj(la(1))
		lc = "Code Review" + CHR(13)+CHR(10)

		IF NOT EMPTY(THIS.aCode(1,1))
		=ASORT(THIS.aCode,2)
		
		ENDIF
		lc = lc + CHR(13)+CHR(10)+"--- Good Code ---"+CHR(13)+CHR(10)
		LOCAL llTitle
		llTitle = .F.
		FOR lni = 1 TO ALEN(THIS.aCode,1)
			IF EMPTY(THIS.aCode(lni,1))
				LOOP
			ENDIF
			IF THIS.aCode(lni,2)>40 AND NOT llTitle
				llTitle = .T.
				lc = lc + CHR(13)+CHR(10)+"--- Possible Candidates ---"+CHR(13)+CHR(10)
			ENDIF
			IF NOT tlWork  OR (tlWork AND ;
					(THIS.aCode(lni,2)>40 OR ;
					(THIS.aCode(lni,3)<(MAX(1,THIS.aCode(lni,2)/2)) AND NOT ;
					THIS.aCode(lni,3)=THIS.aCode(lni,2))))

			ELSE
				THIS.aCode(lni,1) = "DELETE"
			ENDIF
		ENDFOR

		ln = ALEN(THIS.aCode,1)
		ln2 = 1
		FOR lni = 1 TO ln
			IF NOT EMPTY(THIS.aCode(lni,1))
				IF THIS.aCode(lni,1)="DELETE"
					=ADEL(THIS.aCode,lni)
					lni = lni-1
					LOOP
				ELSE
					ln2=ln2+1
				ENDIF
			ENDIF
		ENDFOR
		DIMENSION THIS.aCode(ln2,3)
		IF EMPTY(THIS.aCode(ln2,1))
			THIS.aCode(ln2,1)=""
		ENDIF
		RETURN


	PROCEDURE analyzeObj
		LPARAMETERS toObj

		LOCAL lni
		LOCAL lcText
		lcText = ""
		LOCAL loObj

		LOCAL la(1)
		LOCAL lnMethods
		THIS.otherm.setstatus("Object: "+toObj.Name)
		lnMethods = AMEMBERS(la,toObj,1)

		THIS.AddToCursor(toObj.Name,toObj.Name,"Object")
		
		IF NOT PEMSTATUS(toObj,"Name",5)
			RETURN
		ENDIF

		FOR lni = 1 TO lnMethods
			IF la(lni,2)="M" OR la(lni,2)="E"
				IF PEMSTATUS(toObj,"ReadMethod",5)
					lcContent = toObj.READMETHOD(la(lni,1))
					IF NOT EMPTY(lcContent)
						THIS.Add2Array(toObj.NAME+"."+la(lni,1),ALINES(laX,lcContent),@laX)
					*!* lcText = lcText + toobj.Name+"."+la(lni,1) + " - "+LTRIM(STR(ALINES(laX,lcCOntent)))+CHR(13)+CHR(10)
					ENDIF
				ENDIF
			ENDIF
		ENDFOR
		THIS.ValidateObject(toObj)

		FOR lni = 1 TO lnMethods
			IF la(lni,2)="Object"
				loObj = toObj.&la(lni,1)
				THIS.analyzeObj(loObj)
			ENDIF
		ENDFOR


	PROCEDURE AnalyzeCode
		LPARAMETERS tcFile,tlWork
		IF EMPTY(tcFile)
			tcFile = GETFILE("PRG")
		ENDIF

		DIMENSION THIS.aCode(1,3)
		THIS.aCode(1,1) = ""
		THIS.aCode(1,2) = 0
		THIS.aCode(1,3) = 0
		LOCAL lni
		IF MEMLINES(tcFile)>1
			THIS.analstring(tcFile)

		ELSE
			THIS.analFile(tcFile)
		ENDIF

		lc = "Code Review" + CHR(13)+CHR(10)

		=ASORT(THIS.aCode,2)

	ENDPROC
	
	PROCEDURE ScanSCXVCX
		LPARAMETERS tcFile
		THIS.cFile = tcFile
		LOCAL lnArea
		LOCAL lcAlias
		lcAlias = SYS(2015)
		lnArea = SELECT()
		SELECT 0
		USE (tcFile) AGAIN SHARED ALIAS &lcAlias
		SCAN FOR NOT EMPTY(methods)
			THIS.cObject = TRIM(parent)+IIF(EMPTY(parent),"",".")+TRIM(objname)
			THIS.AnalString(methods,tcFile)
			THIS.cObject = ""
		ENDSCAN
		USE
		SELECT (lnArea)
	ENDPROC

	PROCEDURE ScanMNX
		LPARAMETERS tcFile
		THIS.cFile = tcFile
		LOCAL lnArea,lcAlias
		lcALias = SYS(2015)
		lnArea = SELECT()
		SELECT 0
		USE (tcFile) AGAIN SHARED ALIAS &lcAlias
		SCAN
			IF NOT EMPTY(setup)
			THIS.AnalString(setup,tcFile+" Setup")
			ENDIF
			IF NOT EMPTY(procedure)
			THIS.AnalString(procedure,tcFile + " Procedures")
			ENDIF
			IF NOT EMPTY(cleanup)
			THIS.AnalString(cleanup,tcFile + " Cleanup")
			ENDIF
		ENDSCAN
		USE
		SELECT (lnArea)
	ENDPROC

	PROCEDURE scanProject
	LPARAMETERS tcFile
		THIS.cFile = tcFile
		LOCAL lnArea,lcFile,lcAlias
		lcAlias = SYS(2015)
		lnArea = SELECT()
		SELECT 0
		USE (tcFile) AGAIN SHARED ALIAS &lcALias
		SCAN FOR NOT type="H"
			THIS.oTherm.SetProgress(RECNO()/RECCOUNT()*95)
			lcFile = STRTRAN(name,CHR(0))
			THIS.AnalFile(lcFile)
		ENDSCAN
		SELECT (lcAlias)
		USE
		SELECT (lnArea)
	
	ENDPROC
	PROCEDURE analFile
		LPARAMETERS tcFile
		
		THIS.oTherm.SetDescription("Analyzing "+tcFile)
		THIS.cFile = tcFile
		LOCAL lcExt
		lcExt = UPPER(JUSTEXT(tcFile))
		DO CASE
			CASE lcExt = "PRG"
				RETURN THIS.analstring(FILETOSTR(tcFile))
			CASE lcExt = "SCX"
				RETURN THIS.ScanSCXVCX(tcFile)
			CASE lcExt = "MNX"
				RETURN THIS.ScanMNX(tcFile)
			
			CASE lcExt = "FRX"
				RETURN ""
			
			CASE lcExt = "APP"
				RETURN ""

			CASE lcExt = "FLL"
				RETURN ""

			CASE lcExt = "PJX"
				RETURN THIS.ScanProject(tcFile)
			
			CASE lcExt = "VCX"
				RETURN THIS.ScanSCXVCX(tcFile)
			
			CASE INLIST(lcExt,"BMP","TXT","MSK","INC","H","JPG","GIF","ICO")

			OTHERWISE
				RETURN THIS.analstring(FILETOSTR(tcFile))
		ENDCASE


	PROCEDURE analstring
		** Takes a piece of code and looks for any breaks in it.
		** if someone wanted to write a rule to analyze entire pieces of code, here is where
		** it would go.
		** so the first rule is to break it into individual lines and analyze them.

		LPARAMETERS tcString,tcName

		LOCAL la(1)
		LOCAL laBreak(3)
		laBreak(1) = "PROCEDURE"
		laBreak(2) = "FUNCTION"
		laBreak(3) = "DEFINE"

		LOCAL lnTotal
		lnTotal=ALINES(la,tcString)

		LOCAL lni

		LOCAL lcText
		lcText = ""
		LOCAL lcFunc,lcWord
		LOCAL lnCount
		lnCount = 0
		LOCAL laX(1)
		laX(1)= ""
		lcFunc = "Program" && JUSTFNAME(tcFile)
		FOR lni = 1 TO lnTotal
			THIS.oTherm.SetStatus("Line "+LTRIM(STR(lni))+" of "+LTRIM(STR(lnTotal)))
			lcText = la(lni)
			lcText = ALLTRIM(UPPER(STRTRAN(lcText,"	")))
			IF EMPTY(lcText)
				LOOP
			ENDIF
			*!* THIS.ValidateLine(lcText)
			lcWord = LEFT(lcText,ATC(" ",lcText)-1)
			IF EMPTY(lcWord) OR ASCAN(laBreak,UPPER(lcWord))=0
				lnCount = lnCount+1
				DIMENSION laX(IIF(EMPTY(laX(1)),1,ALEN(laX,1)+1))
				laX(ALEN(laX,1))=lcText
			ELSE
				THIS.Add2Array(lcFunc,lnCount,@laX)
				lnCount = 0
				IF lcText = "DEFINE CLASS"
					lcFunc = ALLTRIM(STRTRAN(lcText,"DEFINE CLASS"))
					lcFunc = LEFT(lcFunc,ATC(" ",lcFunc)-1)
					THIS.cObject = lcFunc
				ELSE
				lcFunc = ALLTRIM(STRTRAN(lcText,lcWord))
				ENDIF
				DIMENSION laX(1)
				laX(1) = ""
			ENDIF
		ENDFOR
		THIS.Add2Array(lcFunc,lnCount,@laX)
		THIS.nFileLines = lnTotal
		THIS.AddToCursor(tcName,tcName,"File")
		THIS.ValidateFile(tcString,tcName)

	ENDPROC

	PROCEDURE ValidateObject
		LPARAMETERS toObj
		LOCAL lni,lcFunc
		THIS.oObject = toObj
		THIS.cObject = toObj.Name
		FOR lni = 1 TO ALEN(THIS.aRules,1)
			IF EMPTY(THIS.aRules(lni,1))
				LOOP
			ENDIF
			IF ALEN(THIS.aRules,2)>3
			THIS.cWarningID = THIS.aRules(lni,4)
			ELSE
			THIS.cWarningID = ""
			
			ENDIF
			IF THIS.aRules(lni,2)="O"
				lcFunc = THIS.aRules(lni,3)
				EXECSCRIPT(lcFunc)
			ENDIF
		ENDFOR
		
	ENDPROC
	PROCEDURE ValidateLine
		LPARAMETERS tcLine
		LOCAL lni,lcFunc

		THIS.cLine = tcLine
		FOR lni = 1 TO ALEN(THIS.aRules,1)
			IF EMPTY(THIS.aRules(lni,1))
				LOOP
			ENDIF
			IF ALEN(THIS.aRules,2)>3
			THIS.cWarningID = THIS.aRules(lni,4)
			ELSE
			THIS.cWarningID = ""
			
			ENDIF
			IF THIS.aRules(lni,2)="L"
				lcFunc = THIS.aRules(lni,3)
				EXECSCRIPT(lcFunc)
			ENDIF
		ENDFOR

	PROCEDURE ValidateFile
		LPARAMETERS tcFile,tcName

		LOCAL lni,lcFunc
		THIS.cFile = tcName
		THIS.cCode = tcFile
		FOR lni = 1 TO ALEN(THIS.aRules,1)
			IF EMPTY(THIS.aRules(lni,1))
				LOOP
			ENDIF
			IF ALEN(THIS.aRules,2)>3
			THIS.cWarningID = THIS.aRules(lni,4)
			ELSE
			THIS.cWarningID = ""
			
			ENDIF
			IF THIS.aRules(lni,2)="F"
				lcFunc = THIS.aRules(lni,3)
				EXECSCRIPT(lcFunc)
			ENDIF
		ENDFOR

	PROCEDURE ValidateCode
		LPARAMETERS tcCode,tcName

		THIS.cFuncName = tcName
		THIS.oTherm.SetStatus("Function: "+tcName)
		IF EMPTY(tcName) OR tcName="Program"
			THIS.cFuncName = THIS.cFile
		ENDIF
		LOCAL lni,lcFunc
		THIS.cCode = tcCode
		FOR lni = 1 TO ALEN(THIS.aRules,1)
			IF EMPTY(THIS.aRules(lni,1))
				LOOP
			ENDIF
			IF ALEN(THIS.aRules,2)>3
			THIS.cWarningID = THIS.aRules(lni,4)
			ELSE
			THIS.cWarningID = ""
			
			ENDIF
			IF THIS.aRules(lni,2)="M"
				lcRule = THIS.aRules(lni,1)
				lcFunc = THIS.aRules(lni,3)
				TRY
				EXECSCRIPT(lcFunc)
				CATCH TO loErr
					THIS.AddError(loErr,lcRule,lcFunc)
					THIS.aRules(lni,1) = ""
				ENDTRY
			ENDIF
		ENDFOR

	PROCEDURE AddError
		LPARAMETERS toErr,tcRule,tcFunc
		THIS.cError = THIS.cError + loErr.Message+" occurred on line "+LTRIM(STR(loErr.Lineno))+" ("+loErr.LineContents+") in rule "+tcRule + CHR(13)+CHR(10)
		
	PROCEDURE Add2Array
		LPARAMETERS tcCode,tnLines,taArray

		IF NOT EMPTY(THIS.aCode(1,1))
			DIMENSION THIS.aCode(ALEN(THIS.aCode,1)+1,3)
		ENDIF
		
		THIS.cFuncName = tcCode
		IF NOT EMPTY(THIS.cObject)
			THIS.cFuncName = LOWER(THIS.cObject+"."+THIS.cFuncName)
		ELSE
		IF EMPTY(tcCode) OR tcCode="Program"
			THIS.cFuncName = THIS.cFile
		ENDIF
		ENDIF

		THIS.aCode(ALEN(THIS.aCode,1),1) = THIS.cFuncName
		THIS.aCode(ALEN(THIS.aCode,1),2) = tnLines
		IF EMPTY(THIS.aCode(ALEN(THIS.aCode,1),1))
			THIS.aCode(ALEN(THIS.aCode,1),1) = ""
		ENDIF
		LOCAL lcCode
		lcCode = ""
		LOCAL lni
		lnReal=0
		FOR lni = 1 TO ALEN(taArray,1)
			IF THIS.lLineRules
				IF ALLTRIM(STRTRAN(taArray(lni),"	"))<>"*"
					IF NOT EMPTY(taArray(lni))
						THIS.nLine = lni
						THIS.AddToCursor(THIS.cFile,THIS.cFuncName,"Function")
						THIS.ValidateLine(taArray(lni))

						lnReal = lnReal+1
					ENDIF
				ENDIF
			ENDIF
			lcCode = lcCode + taArray(lni)+CHR(13)+CHR(10)
		ENDFOR

		THIS.aCode(ALEN(THIS.aCode,1),3) = lnReal
		THIS.nFuncLines = tnLines
		THIS.AddToCursor(THIS.cFile,THIS.cFuncName,"Function")
		THIS.ValidateCode(lcCode,tcCode)
	ENDPROC

ENDDEFINE

DEFINE CLASS frmResults AS FORM


	DOCREATE = .T.
	AUTOCENTER = .T.
	CAPTION = "Refactoring Results"
	WINDOWTYPE = 1
	Width = 400
	NAME = "Form1"


	ADD OBJECT list1 AS LISTBOX WITH ;
		COLUMNCOUNT = 3, ;
		COLUMNWIDTHS = "250,50,50", ;
		HEIGHT = 144, ;
		LEFT = 24, ;
		TOP = 60, ;
		FOntSize=8,;
		WIDTH = 374, ;
		NAME = "List1"


	ADD OBJECT command1 AS COMMANDBUTTON WITH ;
		TOP = 216, ;
		LEFT = 264, ;
		HEIGHT = 27, ;
		WIDTH = 84, ;
		CAPTION = "\<OK", ;
		NAME = "Command1"


	ADD OBJECT label1 AS LABEL WITH ;
		AUTOSIZE = .T., ;
		CAPTION = "Object Name", ;
		HEIGHT = 17, ;
		LEFT = 24, ;
		TOP = 12, ;
		WIDTH = 74, ;
		NAME = "Label1"


	ADD OBJECT label2 AS LABEL WITH ;
		AUTOSIZE = .T., ;
		CAPTION = "Method", ;
		HEIGHT = 17, ;
		LEFT = 24, ;
		TOP = 36, ;
		WIDTH = 42, ;
		NAME = "Label2"


	ADD OBJECT label3 AS LABEL WITH ;
		AUTOSIZE = .T., ;
		CAPTION = "# Lines", ;
		HEIGHT = 17, ;
		LEFT = 228, ;
		TOP = 36, ;
		WIDTH = 43, ;
		NAME = "Label3"


	ADD OBJECT label4 AS LABEL WITH ;
		AUTOSIZE = .T., ;
		CAPTION = "# Code", ;
		HEIGHT = 17, ;
		LEFT = 288, ;
		TOP = 36, ;
		WIDTH = 42, ;
		NAME = "Label4"


	PROCEDURE INIT
		LPARAMETERS tcObj, taArray,tlWork

		IF EMPTY(tlWork)
			THIS.CAPTION = "Object Overview"
		ELSE
			THIS.CAPTION = "Recommended Review Areas"
		ENDIF

		THIS.label1.CAPTION = tcObj

		LOCAL lni,llTitle
		llTitle = .F.
		FOR lni =1 TO ALEN(_SCREEN._analyst.awarnings,1)
			WITH THIS.list1
				IF NOT EMPTY(_SCREEN._analyst.awarnings(lni,1))
					IF NOT llTitle
						.AddItem("*** Warnings ***")
						llTitle = .T.
					ENDIF
					.ADDITEM(_SCREEN._analyst.awarnings(lni,1))
				ENDIF
			ENDWITH
		ENDFOR
		THIS.List1.ColumnCount=1

		IF .F.
		LOCAL lni
		FOR lni =1 TO ALEN(taArray,1)
			WITH THIS.list1
				IF NOT EMPTY(taArray(lni,1))
					.ADDITEM(taArray(lni,1))
					.LIST(.LISTCOUNT,2) = LTRIM(STR(taArray(lni,2)))
					.LIST(.LISTCOUNT,3) = LTRIM(STR(taArray(lni,3)))
				ENDIF
			ENDWITH
		ENDFOR
		ENDIF
		THIS.list1.LISTINDEX = 1
	ENDPROC


	PROCEDURE command1.CLICK
		THISFORM.RELEASE()
	ENDPROC


ENDDEFINE

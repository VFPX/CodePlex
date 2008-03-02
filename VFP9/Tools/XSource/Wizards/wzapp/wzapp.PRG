* APPWIZ.PRG - Application Wizard.
*
* Copyright (c) 1996-1997 Microsoft Corp.
* 1 Microsoft Way
* Redmond, WA 98052
*
* Description:
* Application Wizard.
*

#INCLUDE "wzapp.h"
* WZAPP.H - Header file for Application Wizard files.
*

LPARAMETERS tcOutFileVarName,p2,p3,p4,p5,p6,p7,p8,p9
LOCAL lcLastSetTalk,lcLastSetSafety,lnLastTypeAhead
LOCAL lcFileName,lcFileName2,lcFileName3,lnFileCount,lcWizardDir,lnCount
PRIVATE lcProgramName
LOCAL laDir[1],laFiles[1]

lcLastSetTalk=SET("TALK")
SET TALK OFF
lcLastSetSafety=SET("SAFETY")
SET SAFETY OFF
lnLastTypeAhead=SET("TYPEAHEAD")
SET TYPEAHEAD TO 255
lcProgramName=ProgramName()
DO WHILE ADIR(laDir,"","D")=0
	CD ..
ENDDO
lcWizardDir=HOME()+"WIZARDS\"
lnFileCount=10
DIMENSION laFiles[lnFileCount]
laFiles[1]="APPWIZ.DBF"
laFiles[2]="APPWIZ.FPT"
laFiles[3]="APPWIZ.MNX"
laFiles[4]="APPWIZ.MNT"
laFiles[5]="APPWIZ.PJX"
laFiles[6]="APPWIZ.PJT"
laFiles[7]="APPWIZ.VCX"
laFiles[8]="APPWIZ.VCT"
laFiles[9]="APPWIZ.H"
laFiles[10]="FOXQSTRT.BMP"
FOR lnCount = 1 TO lnFileCount
	lcFileName=laFiles[lnCount]
	lcFileName2=lcWizardDir+lcFileName
	lcFileName=UPPER(FULLPATH(lcFileName))
	IF EMPTY(SYS(2000,lcFileName2)) AND FILE(lcFileName)
		IF RIGHTC(lcFileName,4)==".TXT" OR RIGHTC(lcFileName,2)==".H" OR ;
				RIGHTC(lcFileName,4)==".BMP"
			CREATE CURSOR _temp000 (Text M)
			APPEND BLANK
			APPEND MEMO Text FROM (lcFileName) OVERWRITE
			COPY MEMO Text TO (lcFileName2)
			USE
		ELSE
			IF (lnCount/2)=INT(lnCount/2)
				LOOP
			ENDIF
			lcFileName3=lcWizardDir+"temp0000"+RIGHTC(lcFileName,4)
			ERASE (lcFileName3)
			SELECT 0
			USE (lcFileName)
			COPY TO (lcFileName3)
			USE
			RENAME (lcFileName3) TO (lcWizardDir+laFiles[lnCount])
			lcFileName=laFiles[lnCount+1]
			lcFileName3=lcWizardDir+"temp0000"+RIGHTC(lcFileName,4)
			RENAME (lcFileName3) TO (lcWizardDir+lcFileName)
		ENDIF
	ENDIF
ENDFOR
DO wzastart WITH tcOutFileVarName,p2,p3,p4,p5,p6,p7,p8,p9
SET TYPEAHEAD TO (lnLastTypeAhead)
IF lcLastSetSafety=="ON"
	SET SAFETY ON
ELSE
	SET SAFETY OFF
ENDIF
IF lcLastSetTalk=="ON"
	SET TALK ON
ELSE
	SET TALK OFF
ENDIF
RETURN


FUNCTION ProgramName
LOCAL lcProgramName,lnAtPos

lcProgramName=LOWER(SYS(16))
lnAtPos=RATC(" ",lcProgramName)
IF lnAtPos>0
	lcProgramName=ALLTRIM(SUBSTRC(lcProgramName,lnAtPos+1))
ENDIF
RETURN lcProgramName
ENDFUNC


FUNCTION AppWizFinish(oAppWiz,tlNoRelease)
LOCAL oFinish,llComplete

ACTIVATE SCREEN
SET PROCEDURE TO wzengine ADDITIVE
oFinish=CREATEOBJECT("GenerateApplication")
IF TYPE("oFinish")#"O" OR ISNULL(oFinish)
	RETURN .F.
ENDIF
llComplete=oFinish.Do(oAppWiz,tlNoRelease)
IF tlNoRelease OR TYPE("oFinish")#"O" OR ISNULL(oFinish)
	RETURN .F.
ENDIF
RETURN llComplete
ENDFUNC



FUNCTION AutoApp(oAppWiz)
LOCAL oAutoApp

oAutoApp=oAppWiz.oAutoApp
WITH oAppWiz.Form1
	WITH .Pageframe1.Page1.Pageframe1
		WITH .Page1
			.opgAppType.Value=oAutoApp.nProjectType
			.opgAppType.InteractiveChange
			.txtProjectName.Value=oAutoApp.cProjectName
			.txtProjectName.Valid
			.txtProjectFile.Value=oAutoApp.cOutFile
			.txtProjectFile.Valid
			.chkCreateProjDir.Value=oAutoApp.lCreateDir
			.chkCreateProjDir.InteractiveChange
		ENDWITH
	ENDWITH
	.cmdNext.Click
	WITH .Pageframe1.Page1.Pageframe1
		WITH .Page2
			.opgDatabase.Value=oAutoApp.nDatabaseType
			.opgDatabase.InteractiveChange
			.txtExistingDatabase.Value=oAutoApp.cExistingDBC
			.txtExistingDatabase.Valid
			.cboNewDatabase.Value=oAutoApp.cDatabaseTemplate
			.cboNewDatabase.Valid
		ENDWITH
	ENDWITH
	.cmdNext.Click
	.cmdNext.Click
	.cmdNext.Click
	WITH .Pageframe1.Page2
		.opgSave.Value=oAutoApp.nWizAction
		.opgSave.InteractiveChange
	ENDWITH
ENDWITH
ENDFUNC



DEFINE CLASS GenerateApplicationTest AS GenerateApplication


	FUNCTION Init
	ENDFUNC


	FUNCTION Cleanup
	ENDFUNC


ENDDEFINE


DEFINE CLASS GenerateApplication AS WizEngineAll


	oAppWiz=.NULL.
	oPageFrame=.NULL.
	lFrameworkOnly=.F.
	l98Framework=.F.
	cProjectName=""
	cMainPJX=""
	cMainAPP=""
	cMainERR=""
	lCreateProjDir=.F.
	cProjectDir=""
	cProjectBaseFileName=""
	nSaveMode=1
	cStartupMenu=""
	cStartupForm=""
	cLastDir=""
	cWizardDir=""
	cWizardDir2=""
	cAppWizVCX=""
	cMainVCX=""
	cMainPRG=""
	cMainH=""
	cAboutSCX=""
	cQuickStartSCX=""
	lExistingDatabase=.F.
	cExistingDatabase=""
	cLastSetPath=""
	nLastSelect=0
	nDocumentCount=0
	nMenuCount=0
	lError=.F.
	lBuildMode=.F.
	cMessageText=""
	nDBCCount=0
	cHeaderText=""
	
	DIMENSION aDBC[1]

	FUNCTION Destroy

	SET PATH TO (this.cLastSetPath)
	SET MESSAGE TO ""
	IF USED("_appwiz")
		USE IN _appwiz
	ENDIF
	IF USED("project")
		SELECT _project
		PACK
		USE
	ENDIF
	IF USED("_menu")
		SELECT _menu
		PACK
		USE
	ENDIF
	IF USED("_templatedbf")
		SELECT _templatedbf
		USE
	ENDIF
	SELECT (this.nLastSelect)
	SET MESSAGE TO
	DODEFAULT()
	ENDFUNC


	FUNCTION Do(oAppWiz,tlNoRelease)
	LOCAL lnCount,lcText,lcWindowName,lcFileName,llDuplicate,lnCheckCount,lcNewBaseName
	LOCAL lnAtPos,lnLastSelect,lcTableName

	this.oAppWiz=oAppWiz
	oAppWiz=.NULL.
	IF TYPE("this.oAppWiz.Form1.Pageframe1.Page1.Pageframe1")=="O"
		this.oPageFrame=this.oAppWiz.Form1.Pageframe1.Page1.Pageframe1
	ELSE
		this.oPageFrame=this.oAppWiz.Form1.Pageframe1
	ENDIF
	CLEAR TYPEAHEAD
	WAIT CLEAR
	SET MESSAGE TO ""
	this.cLastSetPath=SET("PATH")
	this.nLastSelect=SELECT()
	IF USED("_project")
		USE IN _project
	ENDIF
	this.cLastDir=LOWER(SYS(5)+CURDIR())
	IF EMPTY(this.oAppWiz.ClassLibrary)
		this.cWizardDir=this.oAppWiz.TrimFile(SYS(1271,this.oAppWiz))
	ELSE
		this.cWizardDir=this.oAppWiz.TrimFile(this.oAppWiz.ClassLibrary)
	ENDIF

	this.cWizardDir2=HOME()+"wizards\"
	IF EMPTY(this.cWizardDir)
		this.cWizardDir=HOME()+"wizards\"
	ENDIF
	this.OpenAppWiz
	IF NOT USED("_appwiz")
		this.oAppWiz=.NULL.
		this.oPageframe=.NULL.
		RETURN .F.
	ENDIF
	this.lFrameworkOnly=(this.oPageFrame.Page1.opgAppType.Value>1)
	this.l98Framework=(this.oPageFrame.Page1.opgAppType.Value=3)
	this.cProjectName=ALLTRIM(this.oPageFrame.Page1.txtProjectName.Value)
	lcText="Building "+IIF(this.nSaveMode=3,"application","project")+ ;
			" "+this.cProjectName
	this.cMessageText=lcText
	SET MESSAGE TO (this.cMessageText+" ...")
	this.cMainPJX=LOWER(ALLTRIM(FULLPATH(this.oPageFrame.Page1.txtProjectFile.Value)))
	this.lExistingDatabase=(this.oPageFrame.Page2.opgDatabase.Value=1)
	this.cExistingDatabase=ALLTRIM(this.oPageFrame.Page2.txtExistingDatabase.Value)
	this.cProjectBaseFileName=ALLTRIM(this.oAppWiz.TrimPath(this.cMainPJX,.T.))
	lcNewBaseName=this.cProjectBaseFileName
	lnCheckCount=0
	DO WHILE .T.
		llDuplicate=.F.
		lnCheckCount=lnCheckCount+1
		FOR lnCount = 1 TO this.oPageFrame.Page3.oleDocumentList.object.Nodes.Count
			lcFileName=LOWER(ALLTRIM(this.oPageFrame.Page3.oleDocumentList.object.Nodes[lnCount].Text))
			IF NOT "."$lcFileName OR NOT ":"$lcFileName
				LOOP
			ENDIF
			lnAtPos=AT_C("(",lcFileName)
			IF lnAtPos>0
				lcFileName=ALLTRIM(LEFTC(lcFileName,lnAtPos-1))
			ENDIF
			IF LOWER(lcNewBaseName)==this.oAppWiz.TrimPath(lcFileName,.T.)
				llDuplicate=.T.
				lcNewBaseName=this.cProjectBaseFileName+ALLTRIM(STR(lnCheckCount,4))
				EXIT
			ENDIF
		ENDFOR
		IF NOT llDuplicate
			EXIT
		ENDIF
	ENDDO
	IF	NOT this.cProjectBaseFileName==lcNewBaseName
		this.cProjectBaseFileName=lcNewBaseName
	ENDIF
	this.aDBC=""
	lnLastSelect=SELECT()
	FOR lnCount = 0 TO this.oPageFrame.Page3.oleDocumentList.object.Nodes.Count
		IF lnCount=0
			IF NOT this.lExistingDatabase OR EMPTY(this.cExistingDatabase)
				LOOP
			ENDIF
			lcFileName=this.cExistingDatabase
		ELSE
			lcFileName=LOWER(ALLTRIM(this.oPageFrame.Page3.oleDocumentList.object.Nodes[lnCount].Text))
		ENDIF
		lnAtPos=AT_C("(",lcFileName)
		IF lnAtPos>0
			lcFileName=ALLTRIM(LEFTC(lcFileName,lnAtPos-1))
		ENDIF
		lnAtPos=RATC(".",lcFileName)
		lcFileExt=IIF(lnAtPos=0,"",LOWER(RIGHTC(lcFileName,LEN(lcFileName)-lnAtPos+1)))
		IF NOT lcFileExt==".dbc" OR NOT FILE(lcFileName)
			LOOP
		ENDIF
		SELECT 0
		USE (lcFileName) AGAIN SHARED ALIAS _tempdbc
		IF NOT USED()
			SELECT (lnLastSelect)
			LOOP
		ENDIF
		SCAN ALL FOR ALLTRIM(LOWER(ObjectType))=="table"
			lcTableName=SUBSTRC(Property,16)
			lnAtPos=AT_C(CHR(0),lcTableName)
			IF lnAtPos=0
				LOOP
			ENDIF
			lcTableName=LOWER(ALLTRIM(LEFTC(lcTableName,lnAtPos-1)))
			IF ASCAN(this.aDBC,lcTableName)>0
				LOOP
			ENDIF
			this.nDBCCount=this.nDBCCount+1
			DIMENSION this.aDBC[this.nDBCCount]
			this.aDBC[this.nDBCCount]=lcTableName
		ENDSCAN
		USE
		SELECT (lnLastSelect)
	ENDFOR
	this.cMainAPP=this.oAppWiz.TrimExt(this.cMainPJX)+".app"
	this.cMainERR=this.oAppWiz.TrimExt(this.cMainPJX)+".err"
	this.lCreateProjDir=this.oPageFrame.Page1.chkCreateProjDir.Value
	this.cProjectDir=this.oAppWiz.TrimFile(this.cMainPJX)
	IF EMPTY(this.cProjectDir)
		MESSAGEBOX("No project directory specified.",16,this.oAppWiz.Form1.Caption)
		this.oAppWiz=.NULL.
		this.oPageframe=.NULL.
		RETURN .F.
	ENDIF
	IF NOT EMPTY(this.oAppWiz.cTemplateDBF) AND FILE(this.oAppWiz.cTemplateDBF)
		lnLastSelect=SELECT()
		SELECT 0
		USE (this.oAppWiz.cTemplateDBF) AGAIN SHARED ALIAS _templatedbf
		IF USED("_templatedbf")
			IF TYPE("Name")=="U" OR TYPE("Properties")=="U"
				USE IN _templatedbf
			ELSE
				SET FILTER TO NOT DELETED()
				LOCATE
			ENDIF
		ENDIF
		SELECT (lnLastSelect)
	ENDIF
	IF TYPE("this.oAppWiz.Form1.Pageframe1.Page2.opgSave")=="O"
		this.nSaveMode=this.oAppWiz.Form1.Pageframe1.Page2.opgSave.Value
	ELSE
		this.nSaveMode=this.oPageFrame.fpgFinish.opgSave.Value
	ENDIF
	
	this.cStartupMenu=this.cProjectDir+this.GetDirName("menus")+ ;
			this.cProjectBaseFileName+".mnx"
	this.cAppWizVCX=this.cWizardDir+"appwiz.vcx"
	this.cMainVCX=this.cProjectDir+this.GetDirName("libs")+ ;
			this.cProjectBaseFileName+".vcx"
	this.cMainPRG=this.cProjectDir+this.GetDirName("progs")+ ;
			this.cProjectBaseFileName+".prg"
	this.cMainH=this.cProjectDir+this.GetDirName("include")+ ;
			this.cProjectBaseFileName+".h"
	this.cAboutSCX=this.cProjectDir+this.GetDirName("forms")+ ;
			"About.scx"
	this.cQuickStartSCX=this.cProjectDir+this.GetDirName("forms")+ ;
			"QckStart.scx"
	IF NOT EMPTY(SYS(2000,this.cMainAPP))
		CLEAR PROGRAM (this.cMainAPP)
		ERASE (this.cMainAPP)
	ENDIF
	IF NOT EMPTY(SYS(2000,this.cMainERR))
		lcWindowName=this.oAppWiz.TrimPath(this.cMainERR)
		IF WEXIST(lcWindowName)
			RELEASE WINDOW (lcWindowName)
		ENDIF
		ERASE (this.cMainERR)
	ENDIF
	IF NOT this.CreateApplication()
		MESSAGEBOX(this.oAppWiz.Form1.Caption+" not completed.",16, ;
				this.oAppWiz.Form1.Caption)
		this.oAppWiz=.NULL.
		this.oPageframe=.NULL.
		RETURN .F.
	ENDIF
	IF NOT tlNoRelease
		this.oAppWiz.Hide
	ENDIF
	this.oAppWiz=.NULL.
	this.oPageframe=.NULL.
	CD (this.cProjectDir)
	CLEAR TYPEAHEAD
	DO CASE
		CASE this.nSaveMode=1
			this.BuildProject
		CASE this.nSaveMode=2
			this.BuildProject
			this.ModifyProject
		CASE this.nSaveMode=3
			this.BuildApplication
	ENDCASE
	IF NOT this.DisplayErrorFile() AND this.nSaveMode=3
		this.RunApplication
	ENDIF
	ENDFUNC


	FUNCTION CreateApplication
		
	IF NOT this.CreateDirs() OR NOT this.CreateProject() OR ;
			NOT this.UpdateProject()
		RETURN .F.
	ENDIF
	ENDFUNC


	FUNCTION BuildProject
	LOCAL lnCount

	IF USED("_project")
		SELECT _project
		PACK
		USE
	ENDIF
	IF USED("_menu")
		SELECT _menu
		PACK
		USE
	ENDIF
	SELECT 0
	SET MESSAGE TO
	FOR lnCount = 1 TO 5000
	ENDFOR
	this.lBuildMode=.T.
	BUILD PROJECT (this.cMainPJX)
	this.lBuildMode=.F.
	ENDFUNC


	FUNCTION BuildApplication
	LOCAL lcKeyboard,lcFileName,lcFileName2

	IF USED("_project")
		SELECT _project
		PACK
		USE
	ENDIF
	IF USED("_menu")
		SELECT _menu
		PACK
		USE
	ENDIF
	SELECT 0
	SET MESSAGE TO
	lcFileName=this.cMainAPP
	IF " "$lcFileName
		lcFileName=[("]+lcFileName+[")]
	ENDIF
	lcFileName2=this.cMainPJX
	IF " "$lcFileName2
		lcFileName2=[("]+lcFileName2+[")]
	ENDIF
	lcKeyboard=[{Ctrl+F2}{Ctrl+END}BUILD APP ]+lcFileName
	KEYBOARD (lcKeyboard) PLAIN
	lcKeyboard=[ FROM ]+lcFileName2+[{ENTER}]
	KEYBOARD (lcKeyboard) PLAIN
	CLEAR PROGRAM (this.cMainAPP)
	ENDFUNC


	FUNCTION ModifyProject
	LOCAL lcKeyboard,lcFileName

	lcFileName=this.cMainPJX
	IF " "$lcFileName
		lcFileName=[("]+lcFileName+[")]
	ENDIF
	lcKeyboard=[{Ctrl+F2}{Ctrl+END}MODIFY PROJECT ]+lcFileName+[ NOWAIT{ENTER}]
	KEYBOARD (lcKeyboard) PLAIN
	ENDFUNC


	FUNCTION RunApplication
	LOCAL lcKeyboard,lcFileName

	IF USED("_project")
		USE IN _project
	ENDIF
	lcFileName=this.cMainAPP
	IF " "$lcFileName
		lcFileName=[("]+lcFileName+[")]
	ENDIF
	lcKeyboard=[{Ctrl+F2}{Ctrl+END}DO ]+lcFileName+[{ENTER}]
	KEYBOARD (lcKeyboard) PLAIN
	ENDFUNC


	FUNCTION DisplayErrorFile
	
	IF EMPTY(SYS(2000,this.cMainERR))
		RETURN .F.
	ENDIF
	MODIFY FILE (this.cMainERR) NOWAIT
	ENDFUNC

	FUNCTION CreateDirs
	LOCAL lcLastDir
	
	this.CreateDir(this.cProjectDir)
	IF this.lCreateProjDir
		this.CreateDir(this.cProjectDir+this.GetDirName("data"))
		this.CreateDir(this.cProjectDir+this.GetDirName("include"))
		this.CreateDir(this.cProjectDir+this.GetDirName("forms"))
		this.CreateDir(this.cProjectDir+this.GetDirName("graphics"))
		this.CreateDir(this.cProjectDir+this.GetDirName("help"))
		this.CreateDir(this.cProjectDir+this.GetDirName("libs"))
		this.CreateDir(this.cProjectDir+this.GetDirName("menus"))
		this.CreateDir(this.cProjectDir+this.GetDirName("progs"))
		this.CreateDir(this.cProjectDir+this.GetDirName("reports"))
   	ENDIF
	ENDFUNC


	FUNCTION CreateDir(tcDir)
	LOCAL laDir[1]
	IF EMPTY(tcDir)
		RETURN .F.
	ENDIF
	IF NOT RIGHTC(tcDir,2)==":\" AND ADIR(laDir,tcDir,"D")=0
		MD (tcDir)
	ENDIF
	ENDFUNC


	FUNCTION CreateProject
	LOCAL lnLastSelect,lcFileName

	lcProjectWindow="Project Manager - "+this.oAppWiz.TrimPath(this.cMainPJX,.T.)
	IF WEXIST(lcProjectWindow)
		RELEASE WINDOW (lcProjectWindow)
	ENDIF
	SELECT 0
	USE (this.cWizardDir+"appwiz.pjx") AGAIN SHARED
	SET FILTER TO NOT DELETED()
	LOCATE
	COPY TO (this.cMainPJX)
	USE
	USE (this.cMainPJX) EXCLUSIVE ALIAS _project
	IF NOT USED()
		SELECT 0
		WAIT CLEAR
		MESSAGEBOX("Project file could not be created and opened.",16, ;
				this.oAppWiz.Form1.Caption)
		RETURN .F.
	ENDIF
	REPLACE ALL SCCData WITH ""
	SET FILTER TO NOT DELETED()
	LOCATE FOR Type=="H"
	REPLACE Name WITH this.cMainPJX+CHR(0), ;
			HomeDir WITH this.cProjectDir+CHR(0), ;
			Object WITH this.cProjectDir+CHR(0), ;
			Reserved1 WITH this.cMainPJX+CHR(0)
	SKIP
	SCAN ALL FOR NOT EMPTY(Name) AND NOT Type=="H"
		lcFileName=LOWER(ALLTRIM(STRTRAN(MLINE(Name,1),CHR(0),"")))
		lcFileName=LOWER(SYS(2014,FULLPATH(lcFileName,this.cWizardDir),this.cProjectDir))
		REPLACE Name WITH lcFileName+CHR(0)
	ENDSCAN
	IF THIS.l98Framework
		LOCATE FOR ATCC("foxqstrt",name)#0
		IF FOUND()
			DELETE
			PACK
		ENDIF
	ENDIF
	LOCATE
	ENDFUNC


	FUNCTION OpenAppWiz

	IF USED("_appwiz")
		RETURN
	ENDIF
	SELECT 0
	USE (this.cWizardDir+"appwiz") AGAIN SHARED ALIAS _appwiz
	SET FILTER TO AppWizData AND NOT DELETED()
	LOCATE
	ENDFUNC


	FUNCTION UpdateProject
	IF THIS.l98Framework
		THIS.UpdateProjectNew()
		RETURN
	ENDIF
	LOCAL lcCode,lcInitCode,oTemp,lcLastSetClassLib,lcPath,lcData1,lcDirectory
	
	COPY FILE (this.cWizardDir+"foxqstrt.bmp") ;
			TO (this.cProjectDir+this.GetDirName("graphics")+"foxqstrt.bmp")
	COPY FILE (this.cWizardDir+"appwiz.h") TO (this.cMainH)
	lcLastSetClassLib=SET("CLASSLIB")
	SET CLASSLIB TO (this.cAppWizVCX) ADDITIVE
	oTemp=CREATEOBJECT("wzApplication")
	oTemp.SaveAsClass(this.cMainVCX,"cApplication","Application class.")
	oTemp=.NULL.
	oTemp=CREATEOBJECT("wzAboutDialog")
	IF FILE(this.cAboutSCX)
		ERASE (this.cAboutSCX)
	ENDIF
	oTemp.SaveAs(this.cAboutSCX)
	oTemp=.NULL.
	oTemp=CREATEOBJECT("wzQuickStartForm")
	IF FILE(this.cQuickStartSCX)
		ERASE (this.cQuickStartSCX)
	ENDIF
	oTemp.SaveAs(this.cQuickStartSCX)
	oTemp=.NULL.
	IF NOT SET("CLASSLIB")==lcLastSetClassLib
		RELEASE CLASSLIB (this.cAppWizVCX)
	ENDIF
	SELECT 0
	USE (this.cWizardDir+"appwiz.mnx") AGAIN SHARED
	SET FILTER TO NOT DELETED()
	LOCATE
	COPY TO (this.cStartupMenu)
	USE
	IF NOT this.lFrameworkOnly
		this.UpdateMenu
		IF this.lExistingDatabase AND NOT EMPTY(this.cExistingDatabase)
			this.AddProjectItem(this.cExistingDatabase,.T.)
		ENDIF
	ENDIF
	this.AddProjectItem(this.cMainH,.T.)
	this.AddProjectItem(this.cMainVCX)
	this.AddProjectItem(this.cStartupMenu)
	this.AddProjectItem(this.cAboutSCX,,,,.T.)
	this.AddProjectItem(this.cQuickStartSCX,,,,.T.)
	SELECT _appwiz
	LOCATE FOR UPPER(ALLTRIM(Type))=="STARTUP PROGRAM"
	lcCode=STRTRAN(ALLTRIM(Data1),LF,"")
	lcInitCode=CR
	lcInitCode=lcInitCode+[goApp.SetCaption("]+ ;
			this.cProjectName+[")]+CR
	IF NOT EMPTY(this.cStartupMenu)
		this.cStartupMenu=LOWER(SYS(2014,this.oAppWiz.TrimExt(this.cStartupMenu), ;
				this.cProjectDir))
	ENDIF
	lcInitCode=lcInitCode+[goApp.cStartupMenu="]+this.cStartupMenu+["]+CR
	IF NOT EMPTY(this.cStartupForm)
		this.cStartupForm=LOWER(SYS(2014,this.oAppWiz.TrimExt(this.cStartupForm), ;
				this.cProjectDir))
	ENDIF
	lcInitCode=lcInitCode+[goApp.cStartupForm="]+this.cStartupForm+["]+CR
	lcCode=STRTRAN(lcCode,CR+"*<Initalize>*"+CR,lcInitCode)
	IF NOT EMPTY(this.cMainVCX)
		this.cMainVCX=LOWER(SYS(2014,this.oAppWiz.TrimExt(this.cMainVCX),this.cProjectDir))
	ENDIF
	lcCode=STRTRAN(lcCode,"*<MAIN.VCX>*",this.cMainVCX)
	lcCode=STRTRAN(lcCode,"*<Dummy project references>*","DO "+ ;
			FORCEEXT(this.cStartupMenu,".mpx"))
	lcDirectory=this.cProjectDir
	IF LOWER(LEFTC(lcDirectory,2))==LOWER(LEFTC(this.cWizardDir,2))
		lcDirectory=ALLTRIM(SUBSTRC(lcDirectory,3))
	ENDIF
	lcCode=STRTRAN(lcCode,"*<CDPath>*",lcDirectory)
	lcCode=STRTRAN(lcCode,"*<MAIN.PRG>*",LOWER(SYS(2014,this.oAppWiz.TrimExt(this.cMainPRG), ;
			this.cProjectDir)))
	IF this.lCreateProjDir
		lcPath=""
		SELECT _appwiz
		SCAN ALL FOR UPPER(RIGHTC(ALLTRIM(Type),10))==" DIRECTORY"
			lcData1=STRTRAN(ALLTRIM(MLINE(Data1,1)),"\","")
			IF EMPTY(lcData1)
				LOOP
			ENDIF
			lcPath=lcPath+";"+lcData1
		ENDSCAN
		lcPath=[SET PATH TO ]+lcPath
	ELSE
		lcPath=[SET PATH TO]
	ENDIF
	lcCode=STRTRAN(lcCode,"*<PATH>*",lcPath)
	lcCode=STRTRAN(lcCode,CR,CR_LF)
	CREATE CURSOR _temp000 (Code M)
	APPEND BLANK
	REPLACE Code with lcCode
	COPY MEMO code to (this.cMainPRG)
	USE
	this.AddProjectItem(this.cMainPRG,,.T.)
	ENDFUNC


	FUNCTION UpdateMenu
	LOCAL lcFileName,lcFileName2,lcAddFileName,lcFileExt,oNode,lcImage,lcKey
	LOCAL lcLevelName,lcLevelName2,lcSubDir,lnAtPos,lnLastSelect

	lnLastSelect=SELECT()
	SELECT 0
	USE (this.cStartupMenu) EXCLUSIVE ALIAS _menu
	IF NOT USED("_menu")
		SELECT (lnLastSelect)
		RETURN .F.
	ENDIF
	SET FILTER TO NOT DELETED()
	LOCATE
	this.nMenuCount=this.oPageFrame.Page4.oleMenuList.object.Nodes.Count
	FOR lnCount = 1 TO this.nMenuCount
		oNode=this.oPageFrame.Page4.oleMenuList.Nodes[lnCount]
		lcImage=ALLTRIM(oNode.Image)
		IF EMPTY(lcImage) OR lcImage=="menus"
			LOOP
		ENDIF
		lcKey=LOWER(ALLTRIM(oNode.Key))
		GO (this.oAppWiz.aMenus[lnCount])
		lcLevelName=LOWER(ALLTRIM(MLINE(LevelName,1)))
		DELETE
		IF ObjCode=77
			SKIP
			IF ObjCode#0
				LOOP
			ENDIF
			lcLevelName2=LOWER(ALLTRIM(MLINE(LevelName,1)))
			DELETE
			DELETE ALL FOR LOWER(ALLTRIM(MLINE(LevelName,1)))==lcLevelName2
		ENDIF
		IF TYPE("oNode.parent.Key")=="C"
			LOCATE FOR LOWER(ALLTRIM(MLINE(Name,1)))==lcLevelName
			IF EOF()
				LOOP
			ENDIF
			IF NumItems>0
				REPLACE NumItems WITH NumItems-1
			ENDIF
			LOOP
		ENDIF
		GO 2
		IF NumItems>0
			REPLACE NumItems WITH NumItems-1
		ENDIF
	ENDFOR
	oNode=.NULL.
	this.nDocumentCount=this.oPageFrame.Page3.oleDocumentList.object.Nodes.Count
	IF this.nDocumentCount=0
		SELECT (lnLastSelect)
		RETURN
	ENDIF
	FOR lnCount = 1 TO this.nDocumentCount
		lcFileName=ALLTRIM(this.oPageFrame.Page3.oleDocumentList.object.Nodes[lnCount].Text)

		IF NOT "."$lcFileName
			LOOP
		ENDIF
		IF NOT ":"$lcFileName
			IF RIGHTC(lcFileName,LEN(M_STARTUP_MARKER_LOC))==M_STARTUP_MARKER_LOC
				lcFileName=LEFTC(lcFileName,LEN(lcFileName)-LEN(M_STARTUP_MARKER_LOC))
				this.cStartupForm=this.cProjectDir+this.GetDirName("forms")+lcFileName
			ENDIF
			LOOP
		ENDIF
		SET MESSAGE TO (this.cMessageText+":  "+lcFileName)
		IF RIGHTC(lcFileName,LEN(M_STARTUP_MARKER_LOC))==M_STARTUP_MARKER_LOC
			lcFileName=LEFTC(lcFileName,LEN(lcFileName)-LEN(M_STARTUP_MARKER_LOC))
			this.cStartupForm=lcFileName
		ENDIF
		IF NOT RIGHTC(lcFileName,LEN(M_TEMPLATE_MARKER_LOC))==M_TEMPLATE_MARKER_LOC
			this.AddProjectItem(lcFileName)
			LOOP
		ENDIF
		lcFileName=LEFTC(lcFileName,LEN(lcFileName)-LEN(M_TEMPLATE_MARKER_LOC))
		IF NOT FILE(lcFileName)
			LOOP
		ENDIF
		lcSubDir=ALLTRIM(this.oAppWiz.TrimFile(lcFileName))
		IF RIGHTC(lcSubDir,1)=="\"
			lcSubDir=ALLTRIM(LEFTC(lcSubDir,LEN(lcSubDir)-1))
		ENDIF
		lnAtPos=RATC("\",lcSubDir)
		IF lnAtPos>0
			lcSubDir=ALLTRIM(SUBSTRC(lcSubDir,lnAtPos+1))
		ENDIF
		lcFileName2=LOWER(FULLPATH(this.oAppWiz.TrimPath(lcFileName), ;
				this.cProjectDir+this.GetDirName(lcSubDir)))
		lnAtPos=RATC(".",lcFileName2)
		lcFileExt=IIF(lnAtPos=0,"",LOWER(RIGHTC(lcFileName2,LEN(lcFileName2)-lnAtPos+1)))
		IF INLIST(lcFileExt,".scx",".vcx",".frx",".lbx",".mnx",".dbf",".dbc",".pjx")
			COPY FILE (lcFileName) TO (lcFileName2)
			lcAddFileName=lcFileName2
			IF lcFileExt==".dbf"
				lcFileExt=".fpt"
				lcFileName=LEFTC(lcFileName,LEN(lcFileName)-3)+"fpt"
				IF NOT FILE(lcFileName)
					LOOP
				ENDIF
				lcFileName2=LEFTC(lcFileName2,LEN(lcFileName2)-3)+"fpt"
				COPY FILE (lcFileName) TO (lcFileName2)
				this.AddProjectItem(lcAddFileName)
				LOOP
			ENDIF
			IF lcFileExt==".dbc"
				lcFileExt=".dcx"
				lcFileName=LEFTC(lcFileName,LEN(lcFileName)-3)+"dcx"
				IF NOT FILE(lcFileName)
					LOOP
				ENDIF
				lcFileName2=LEFTC(lcFileName2,LEN(lcFileName2)-3)+"dcx"
				COPY FILE (lcFileName) TO (lcFileName2)
			ENDIF
			lcFileName=LEFTC(lcFileName,LEN(lcFileName)-1)+"t"
			IF NOT FILE(lcFileName)
				LOOP
			ENDIF
			lcFileName2=LEFTC(lcFileName2,LEN(lcFileName2)-1)+"t"
			COPY FILE (lcFileName) TO (lcFileName2)
			this.AddProjectItem(lcAddFileName)
		ELSE
			IF INLIST(lcFileExt,".sct",".vct",".frt",".lbt",".mnt",".fpt",".dct",".pjt")
				LOOP
			ENDIF
			COPY FILE (lcFileName) TO (lcFileName2)
			IF INLIST(lcFileExt,".cdx")
				LOOP
			ENDIF
			this.AddProjectItem(lcFileName2)
		ENDIF
	ENDFOR
	SET MESSAGE TO (this.cMessageText+" ...")
	SELECT (lnLastSelect)
	ENDFUNC


	FUNCTION AddMenuItem(tcFileName,tcParam2,tcParam3,tcParam4)
	LOCAL lcFileName,lcFileExt,lcName,lnRecNo,lnNumItems,lcLevelName,lcProperties
	LOCAL lcPrompt,lcCommand,lcMark,lnAtPos,lnLastSelect,lcClassLoc,lcNewClassLoc

	IF EMPTY(tcFileName) OR NOT USED("_menu")
		RETURN .F.
	ENDIF
	lnLastSelect=SELECT()
	lcFileName=this.oAppWiz.TrimPath(tcFileName)
	lnAtPos=RATC(".",lcFileName)
	lcFileExt=IIF(lnAtPos=0,"",LOWER(RIGHTC(lcFileName,LEN(lcFileName)-lnAtPos+1)))
	IF INLIST(lcFileExt,".sct",".vct",".frt",".lbt",".mnt",".fpt",".dct",".pjt")
		SELECT (lnLastSelect)
		RETURN .F.
	ENDIF
	lcPrompt=""
	IF USED("_templatedbf")
		SELECT _templatedbf
		LOCATE FOR LOWER(ALLTRIM(MLINE(Name,1)))==LOWER(lcFileName)
		IF NOT EOF()
			lcProperties=STRTRAN(STRTRAN(ALLTRIM(Properties),CR_LF,CR),CR+CR,CR)
			IF EMPTY(lcProperties)
				LOOP
			ENDIF
			lcProperties=CR+ALLTRIM(lcProperties)+CR
			IF ATCC(CR+"nomenu"+CR,lcProperties)>0
				SELECT (lnLastSelect)
				RETURN .F.
			ENDIF
			lnAtPos=AT_C(CR+"menucaption=",lcProperties)
			IF lnAtPos=0
				lnAtPos=ATCC(CR+"menucaption =",lcProperties)
			ENDIF
			IF lnAtPos>0
				lcPrompt=ALLTRIM(MLINE(SUBSTRC(lcProperties,lnAtPos+1),1))
				lnAtPos=AT_C("=",lcPrompt)
				lcPrompt=ALLTRIM(SUBSTRC(lcPrompt,lnAtPos+1))
			ENDIF
			DO CASE
				CASE lcFileExt==".scx"
					IF ATCC(CR+"nomultipleinstances"+CR,lcProperties)>0
						tcParam3=".T."
					ENDIF
					IF ATCC(CR+"noshow"+CR,lcProperties)>0
						tcParam4=".T."
					ENDIF
				CASE lcFileExt==".frx"
					IF ATCC(CR+"nopreview"+CR,lcProperties)>0
						tcParam2=".T."
					ENDIF
			ENDCASE
		ENDIF
		SELECT (lnLastSelect)
	ENDIF
	lcParams=""
	IF NOT EMPTY(tcParam2)
		lcParams=lcParams+","+tcParam2
	ENDIF
	IF NOT EMPTY(tcParam3)
		lcParams=lcParams+","+tcParam3
	ENDIF
	IF NOT EMPTY(tcParam4)
		lcParams=lcParams+","+tcParam4
	ENDIF
	IF lcFileExt==".scx" OR lcFileExt==".vcx"
		SELECT 0
		USE (tcFileName) AGAIN SHARED ALIAS _vcxscxdata
		IF USED("_vcxscxdata")
			SCAN ALL FOR NOT EMPTY(ClassLoc)
				lcClassLoc=LOWER(ALLTRIM(ClassLoc))
				IF NOT "\"$lcClassLoc OR lcClassLoc==this.oAppWiz.TrimPath(lcClassLoc) OR ;
						LEFTC(lcClassLoc,8)=="..\libs\"
					LOOP
				ENDIF
				lcClassLoc=LOWER(FULLPATH(lcClassLoc,tcFileName))
				lcNewClassLoc=LOWER(ALLTRIM(SYS(2014,HOME()+"wizards\"+ ;
						this.oAppWiz.TrimPath(lcClassLoc), ;
						this.cProjectDir+this.GetDirName("forms"))))
				IF lcClassLoc==lcNewClassLoc
					LOOP
				ENDIF
				CLEAR CLASS (MLINE(Class,1))
				REPLACE ClassLoc WITH lcNewClassLoc
			ENDSCAN
			USE
		ENDIF
		SELECT (lnLastSelect)
	ENDIF
	DO CASE
		CASE lcFileExt==".scx"
			lcName="Forms"
			lcCommand=[goApp.DoForm("]+LOWER(SYS(2014,tcFileName,this.cProjectDir))+ ;
					lcParams+[")]
			IF EMPTY(lcPrompt)
				SELECT 0
				USE (tcFileName) AGAIN SHARED
				IF NOT USED()
					SELECT (lnLastSelect)
					RETURN .F.
				ENDIF
				SET FILTER TO NOT DELETED()
				LOCATE FOR LOWER(LEFTC(BaseClass,4))=="form" OR LOWER(BaseClass)=="toolbar"
				lcPrompt=ALLTRIM(Properties)
				lnAtPos=ATCC(LF+"Caption = ",lcPrompt)
				IF lnAtPos=0
					lcPrompt=this.oAppWiz.TrimExt(lcFileName)
				ELSE
					lcPrompt=MLINE(SUBSTRC(lcPrompt,lnAtPos+10),1)
					lcPrompt=EVALUATE(lcPrompt)
				ENDIF
				USE
			ENDIF
		CASE lcFileExt==".frx" OR lcFileExt==".lbx"
			lcName="Reports"
			lcCommand=[goApp.Do]+IIF(lcFileExt==".frx","Report","Label")+ ;
					[("]+LOWER(SYS(2014,tcFileName,this.cProjectDir))+lcParams+[")]
			IF EMPTY(lcPrompt)
				SELECT 0
				USE (tcFileName) AGAIN SHARED
				IF NOT USED()
					SELECT (lnLastSelect)
					RETURN .F.
				ENDIF
				SET FILTER TO NOT DELETED()
				LOCATE FOR ObjType=5
				lcPrompt=ALLTRIM(Expr)
				IF MEMLINES(lcPrompt)>1
					lcPrompt=MLINE(lcPrompt,1)+["]
				ENDIF
				IF NOT EMPTY(lcPrompt)
					lcPrompt=EVALUATE(lcPrompt)
				ENDIF
				IF EMPTY(lcPrompt)
					lcPrompt=this.oAppWiz.TrimExt(lcFileName)
				ENDIF
				USE
			ENDIF
		OTHERWISE
			SELECT (lnLastSelect)
			RETURN .F.
	ENDCASE
	SELECT _menu
	LOCATE FOR ALLTRIM(MLINE(Name,1))==lcName
	IF EOF()
		SELECT (lnLastSelect)
		RETURN .F.
	ENDIF
	lnRecNo=RECNO()
	lnNumItems=NumItems+1
	lcMark=Mark
	lcLevelName=LevelName
	REPLACE NumItems WITH lnNumItems
	SKIP (lnNumItems-1)
	INSERT BLANK
	REPLACE ObjType WITH 3, ;
			ObjCode WITH 67, ;
			Prompt WITH lcPrompt, ;
			Command WITH lcCommand, ;
			Mark WITH lcMark, ;
			LevelName WITH lcLevelName, ;
			ItemNum WITH TRANSFORM(lnNumItems,"###")
	SELECT (lnLastSelect)
	ENDFUNC
	

	FUNCTION GetDirName(tcKey)
	LOCAL lcFullKey,lcDirName,lnLastSelect

	IF EMPTY(tcKey) OR NOT this.lCreateProjDir
		RETURN ""
	ENDIF
	lcFullKey=UPPER(ALLTRIM(tcKey))+" DIRECTORY"
	lnLastSelect=SELECT()
	SELECT _appwiz
	LOCATE FOR UPPER(ALLTRIM(Type))==lcFullKey
	IF EOF()
		lcDirName=""
	ELSE
		lcDirName=ALLTRIM(MLINE(Data1,1))
		IF LEFTC(lcDirName,1)=="\"
			lcDirName=ALLTRIM(SUBSTRC(lcDirName,2))
		ENDIF
		IF NOT RIGHTC(lcDirName,1)=="\"
			lcDirName=lcDirName+"\"
		ENDIF
	ENDIF
	SELECT (lnLastSelect)
	RETURN lcDirName
	ENDFUNC


	FUNCTION AddProjectItem(tcFileName,tlExclude,tlMainProg,tlSkipScan,tlNoMenu)
	LOCAL lcFileName,llExclude,lcFileName2,lcType,lnLastSelect,lnLastRecNo
	LOCAL lcAlias,lnAtPos,lnParms
	lnParms = PCOUNT()
	lcFileName=LOWER(ALLTRIM(tcFileName))
	llExclude=tlExclude
	lnAtPos=RATC(".",lcFileName)
	lnLastSelect=SELECT()
	lcFileExt=IIF(lnAtPos=0,"",LOWER(RIGHTC(lcFileName,LENC(lcFileName)-lnAtPos+1)))
	DO CASE
		CASE lcFileExt==".scx"
			lcType="K"
		CASE lcFileExt==".frx"
			lcType="R"
		CASE lcFileExt==".lbx"
			lcType="B"
		CASE lcFileExt==".mnx"
			lcType="M"
		CASE lcFileExt==".vcx"
			lcType="V"
		CASE lcFileExt==".prg"
			lcType="P"
		CASE INLIST(lcFileExt,".txt",".h",".log",".fpw")
			lcType="T"
		CASE lcFileExt==".qpr"
			lcType="Q"
		CASE lcFileExt==".dbf"
			IF ASCAN(this.aDBC,LOWER(this.oAppWiz.TrimPath(lcFileName)))>0
				RETURN .F.
			ENDIF
			lcType="D"
			IF lnParms < 2
				llExclude=.T.
			ENDIF
		CASE lcFileExt==".dbc"
			lcType="d"
			llExclude=.T.
		CASE lcFileExt==".fll"
			lcType="L"
		CASE lcFileExt==".app"
			lcType="Z"
		OTHERWISE
			lcType="x"
	ENDCASE
	SELECT _project
	LOCATE FOR LOWER(Name)==LOWER(lcFileName+EOL)
	IF EOF()
		APPEND BLANK
	ENDIF
	REPLACE Type WITH lcType, Name WITH lcFileName+EOL, ;
			Exclude WITH llExclude, MainProg WITH tlMainProg
	IF NOT tlNoMenu AND INLIST(lcFileExt,".scx",".frx",".lbx",".h")
		this.AddMenuItem(lcFileName)
	ENDIF
	IF tlSkipScan OR (NOT lcType=="K" AND NOT lcType=="V")
		SELECT (lnLastSelect)
		RETURN
	ENDIF
	SELECT 0
	lcAlias=" _metafile_"+this.oAppWiz.TrimPath(lcFileName,.T.)+"_"+STRTRAN(lcFileExt,".","")
	lcAlias=CHRTRANC(lcAlias,". ","__")
	IF USED(lcAlias)
		SELECT (lnLastSelect)
		RETURN
	ENDIF
	USE (lcFileName) AGAIN SHARED ALIAS (lcAlias)
	IF NOT USED()
		SELECT (lnLastSelect)
		RETURN
	ENDIF
	SCAN ALL
		IF NOT EMPTY(ClassLoc)
			lcFileName2=LOWER(FULLPATH(ALLTRIM(MLINE(ClassLoc,1)),lcFileName))
			IF NOT lcFileName2==lcFileName AND FILE(lcFileName2)
				lnLastRecNo=RECNO()
				this.AddProjectItem(lcFileName2)
				SELECT (lcAlias)
				GO (lnLastRecNo)
			ENDIF
		ENDIF
		IF NOT EMPTY(Reserved8)
			lcFileName2=LOWER(FULLPATH(ALLTRIM(MLINE(Reserved8,1)),lcFileName))
			IF NOT lcFileName2==lcFileName AND FILE(lcFileName2)
				lnLastRecNo=RECNO()
				this.AddProjectItem(lcFileName2,.T.)
				SELECT (lcAlias)
				GO (lnLastRecNo)
			ENDIF
		ENDIF
	ENDSCAN
	USE
	SELECT (lnLastSelect)
	ENDFUNC


	FUNCTION Error
	LPARAMETERS nError, cMethod, nLine
	LOCAL lcErrorMsg,lcCodeLineMsg

	WAIT CLEAR
	IF this.lError
		RELEASE this
		RETURN .F.
	ENDIF
	IF this.lBuildMode
		RETURN
	ENDIF
	lcErrorMsg=MESSAGE()+CR+CR+M_APPLICATION_WIZARD_LOC+":   "+this.Name+CR
	lcErrorMsg=lcErrorMsg+"Method:    "+cMethod
	lcCodeLineMsg=MESSAGE(1)
	IF BETWEEN(nLine,1,10000) AND NOT lcCodeLineMsg="..."
		lcErrorMsg=lcErrorMsg+CR+"Line:         "+ALLTRIM(STR(nLine))
		IF NOT EMPTY(lcCodeLineMsg)
			lcErrorMsg=lcErrorMsg+CR+CR+lcCodeLineMsg
		ENDIF
	ENDIF
	IF MESSAGEBOX(lcErrorMsg,17,"Application Wizard")#1
		this.lError=.T.
		RELEASE this
		RETURN .F.
	ENDIF
	ENDFUNC

	*** New VFP98 Framework functions ***
	FUNCTION UpdateProjectNew

		LOCAL lcGoMenu, lcReadMe, lcLogFile, lcConfFile, lcCommonName, ;
			liSelect, lcMetaTable, lcTempString, lcAlias, ;
			lcMainMenu, lcTopMenu, lcAppendMenu, lcTopGoMenu
		
		WAIT WINDOW APPGENERATING_LOC NOWAIT
		* determine the filenames for the pieces we will generate:
		lcCommonName = JUSTSTEM(THIS.cMainPJX)+APP_BUILDER_FILE_SUFFIX
		lcMainMenu = THIS.cProjectDir+THIS.GetDirName("menus")+ ;
			  			STRTRAN(lcCommonName,;
						        APP_BUILDER_FILE_SUFFIX,;
				    		    APP_BUILDER_MAINMENU_SUFFIX)+".MNX"			    		    
		lcGoMenu = 		STRTRAN(lcMainMenu, ;
		                    	APP_BUILDER_MAINMENU_SUFFIX, ;
			                    APP_BUILDER_GOMENU_SUFFIX)
		lcTopMenu = 	STRTRAN(lcMainMenu, ;
		    	                APP_BUILDER_MAINMENU_SUFFIX, ;
		        	            APP_BUILDER_TOPMENU_SUFFIX)
		lcAppendMenu = 	STRTRAN(lcMainMenu, ;
		            	        APP_BUILDER_MAINMENU_SUFFIX, ;
		                	    APP_BUILDER_APPENDMENU_SUFFIX)

		THIS.cMainH = THIS.cProjectDir+lcCommonName+".H"
		lcConfigFile = THIS.cProjectDir+"CONFIG.FPW"
		THIS.cMainVCX=THIS.cProjectDir+THIS.GetDirName("libs")+ ;
			lcCommonName+".VCX"

		THIS.cStartupMenu = lcMainMenu

		THIS.cMainPRG=THIS.cProjectDir+THIS.GetDirName("progs")+ ;
			lcCommonName+".PRG"
		lcReadMe = FORCEEXT(THIS.cMainH,"HTM")
		lcLogFile = FORCEEXT(THIS.cMainH,"LOG")
		lcMetaTable = FORCEEXT(THIS.cMainH,"DBF")

		* create the meta table:
		liSelect = SELECT()	
		lcAlias = "F"+SYS(2015)
		SELECT 0
		USE (THIS.cWizardDir2+"_framewk.dbf") AGAIN SHARED ALIAS (lcAlias)
		LOCATE FOR ALLTR(LOWER(fname)) == "t_head.txt"
		THIS.cHeaderText = contents
		LOCATE FOR ALLTR(LOWER(fname)) == "t_meta.dbf"
		COPY MEMO Contents TO (LOWER(lcMetaTable))
		LOCATE FOR ALLTR(LOWER(fname)) == "t_meta.fpt"
		COPY MEMO Contents TO (LOWER(FORCEEXT(lcMetaTable,"FPT")))
		LOCATE FOR ALLTR(LOWER(fname)) == "t_meta.cdx"	
		COPY MEMO Contents TO (LOWER(FORCEEXT(lcMetaTable,"CDX")))

		* create the header file:
		LOCATE FOR ALLTR(LOWER(fname)) == "t_meta.h"		
		lcTempString = Contents
		* first do the standard fix for project name and header info:
		lcTempString = THIS.AdjustString(lcTempString)
		* now do the .H-file-specific stuff:
		lcTempString = THIS.AdjustString(lcTempString, "*<AppClassName>*", APP_BUILDER_CLASS_PREFIX+"_application")
		* for now, all the following are set here, but they would
		* be set by the appbuilder:
		lcTempString = THIS.AdjustString(lcTempString,"*<AppName>*",THIS.cProjectName) && for now
		lcTempString = THIS.AdjustString(lcTempString,"*<AppSplashClass>*",APP_BUILDER_CLASS_PREFIX+"_splash")

		STRTOFILE(lcTempString,LOWER(THIS.cMainH))

		* create the ancillary textfiles and adjust appropriately with headers etc:

		* config.fpw
		LOCATE FOR ALLTR(LOWER(fname)) == "t_config.fpw"		
		lcTempString = Contents
		* first do the standard fix for project name and header info:
		lcTempString = THIS.AdjustString(lcTempString)
		* then there is one item, TITLE=, that gets more customized in this file:
		lcTempString = THIS.AdjustString(lcTempString,"*<AppName>*",THIS.cProjectName) && for now
		STRTOFILE(lcTempString,LOWER(lcConfigFile))

		* project hook action log
		LOCATE FOR ALLTR(LOWER(fname)) == "t_log.txt"
		lcTempString = Contents
		* standard fix for project name and header info:
		lcTempString = THIS.AdjustString(lcTempString)
		STRTOFILE(lcTempString,LOWER(lcLogFile))

		* create the program to instantiate the app object:
		LOCATE FOR ALLTR(LOWER(fname)) == "t_start.prg"
		lcTempString = Contents
		* standard fix for project name and header info:
		lcTempString = THIS.AdjustString(lcTempString)
		STRTOFILE(lcTempString,LOWER(THIS.cMainPRG))

		* create the application classlibrary and its subclasses of _FRAMEWK:
		LOCATE FOR ALLTR(LOWER(fname)) == "t_meta.vcx"	
		COPY MEMO Contents TO (LOWER(THIS.cMainVCX))
		LOCATE FOR ALLTR(LOWER(fname)) == "t_meta.vct"	
		COPY MEMO Contents TO (LOWER(FORCEEXT(THIS.cMainVCX,"VCT")))
       
		* create menus
		LOCATE FOR ALLTR(LOWER(fname)) == "t_main.mnx"	
		COPY MEMO Contents TO (LOWER(lcMainMenu))
		LOCATE FOR ALLTR(LOWER(fname)) == "t_main.mnt"	
		COPY MEMO Contents TO (LOWER(FORCEEXT(lcMainMenu,"MNT")))
		
		LOCATE FOR ALLTR(LOWER(fname)) == "t_top.mnx"	
		COPY MEMO Contents TO (LOWER(lcTopMenu))
		LOCATE FOR ALLTR(LOWER(fname)) == "t_top.mnt"	
		COPY MEMO Contents TO (LOWER(FORCEEXT(lcTopMenu,"MNT")))
		
		LOCATE FOR ALLTR(LOWER(fname)) == "t_append.mnx"	
		COPY MEMO Contents TO (LOWER(lcAppendMenu))
		LOCATE FOR ALLTR(LOWER(fname)) == "t_append.mnt"	
		COPY MEMO Contents TO (LOWER(FORCEEXT(lcAppendMenu,"MNT")))
		
		LOCATE FOR ALLTR(LOWER(fname)) == "t_go.mnx"
		COPY MEMO Contents TO (LOWER(lcGoMenu))
		LOCATE FOR ALLTR(LOWER(fname)) == "t_go.mnt"
		COPY MEMO Contents TO (LOWER(FORCEEXT(lcGoMenu,"MNT")))
		
		* adjust these menus with appropriate header info...

		THIS.UpdateMenuNew(lcMainMenu)
		THIS.UpdateMenuNew(lcTopMenu)
		THIS.UpdateMenuNew(lcAppendMenu)		
		THIS.UpdateMenuNew(lcGoMenu)
		
		* Now adjust subclass vcx,properties of application object, and 
		* potentially properties of splash class and other subclasses if we want...
		
		USE (THIS.cMainVCX) ALIAS (lcAlias)
		REPLACE ALL ClassLoc WITH LOWER(THIS.cWizardDir2+"_framewk.vcx") ;
		        FOR NOT EMPTY(ClassLoc)
		REPLACE ALL ObjName WITH LOWER(APP_BUILDER_CLASS_PREFIX+ObjName) ;
		        FOR NOT EMPTY(ObjName)
		        
		LOCATE FOR ALLTR(LOWER(objName)) == LOWER(APP_BUILDER_CLASS_PREFIX+"_application") ;
			AND NOT DELETED()
			
		THIS.AdjustProperties("cCaption",ALLTRIM(THIS.cProjectName))
		THIS.AdjustProperties("cProjectName",ALLTRIM(THIS.cProjectName))
		THIS.AdjustProperties("cgomenufile",JUSTSTEM(lcGoMenu))
		THIS.AdjustProperties("cstartupmenu",JUSTSTEM(THIS.cStartupMenu))
		THIS.AdjustProperties("cmetatable",JUSTSTEM(lcMetaTable))
		THIS.AdjustProperties("caboutboxclass",APP_BUILDER_CLASS_PREFIX+"_aboutbox")
		THIS.AdjustProperties("cerrorviewerclass",APP_BUILDER_CLASS_PREFIX+"_errorlogviewer")
		THIS.AdjustProperties("cstartupformclass",APP_BUILDER_CLASS_PREFIX+"_favoritepicker")
		THIS.AdjustProperties("cnavtoolbarclass",APP_BUILDER_CLASS_PREFIX+"_navtoolbar")
		THIS.AdjustProperties("cstartuptoolbarclass",APP_BUILDER_CLASS_PREFIX+"_standardtoolbar")
		THIS.AdjustProperties("cnewopenclass",APP_BUILDER_CLASS_PREFIX+"_newopen")
		THIS.AdjustProperties("coptionsdialogclass",APP_BUILDER_CLASS_PREFIX+"_options")
		THIS.AdjustProperties("creportdialogclass",APP_BUILDER_CLASS_PREFIX+"_reportpicker")
		THIS.AdjustProperties("cuserloginclass",APP_BUILDER_CLASS_PREFIX+"_userlogin")
		THIS.AdjustProperties("cchangepasswordclass",APP_BUILDER_CLASS_PREFIX+"_changepassword")

		USE
		SELECT (liSelect)		

		IF THIS.lExistingDatabase AND NOT EMPTY(THIS.cExistingDatabase)
			THIS.AddProjectItem(THIS.cExistingDatabase,.T.)
		ENDIF

		THIS.AddProjectItem(THIS.cMainH,.T.)
		THIS.AddProjectItem(lcMetaTable,.F.)
		THIS.AddProjectItem(lcConfigFile,.T.)
		THIS.AddProjectItem(lcLogFile,.T.)
		THIS.AddProjectItem(THIS.cMainVCX)
		THIS.AddProjectItem(THIS.cStartupMenu)
		THIS.AddProjectItem(lcGoMenu)
		THIS.AddProjectItem(THIS.cMainPRG,,.T.)
		THIS.AddProjectItem(HOME()+REPORTS_CLASSLIB)
		WAIT CLEAR
	ENDFUNC

	FUNCTION UpdateMenuNew(tcMenu)
		IF EMPTY(tcMenu)
			RETURN
		ENDIF
		LOCAL liSelect
		liSelect = SELECT()
		SELE 0
		USE (tcMenu) AGAIN SHARED
		REPLACE Setup WITH THIS.AdjustString(ALLTR(Setup))
		USE
		SELECT (liSelect)
	ENDFUNC

	FUNCTION AdjustProperties(tcProperty,tvValue)
		* this function assumes that you are pointed
		* at the right record of a VCX already....
		ASSERT TYPE(ALIAS()+".Properties") = "M" AND NOT EOF()
		IF TYPE("tcProperty") # "C" OR EMPTY(tcProperty)
			RETURN
		ENDIF
		LOCAL liLines, lcProperties, lcValue, ;
			llFound, liPos, lcLine, liIndex, lcNewLine
		liLines = MEMLINES(Properties)
		lcProperties = Properties
		_MLINE = 0
		DO CASE
			CASE PCOUNT() < 2
				lcValue = NULL
			CASE TYPE("tvValue") = "C"
				lcValue = ALLTRIM(tvValue)
			OTHERWISE
				lcValue = TRANSFORM(tvValue)
		ENDCASE

		FOR liIndex = 1 TO liLines
			lcLine = MLINE(lcProperties, 1, _MLINE)
			IF NOT EMPTY(ATCC(tcProperty+" =",lcLine))
				IF ISNULL(lcValue) && resettodefault
					lcProperties = STRTRAN(lcProperties,lcLine+CHR(13)+CHR(10),"")
				ELSE
					liPos = ATCC("=",lcLine)
					lcNewLine = SUBSTRC(lcLine,1,liPos)+" "+lcValue
					lcProperties = STRTRAN(lcProperties,lcLine,lcNewLine)
				ENDIF
				llFound = .T.
				EXIT
			ENDIF
		ENDFOR
		IF NOT llFound && add this information at the bottom
			lcProperties = lcProperties+ ;
				ALLTR(tcProperty)+" = "+lcValue + ;
				CHR(13)+CHR(10)
		ENDIF

		REPLACE Properties WITH lcProperties

		RETURN
	ENDFUNC

	FUNCTION AdjustString(tcString,tcMetaString,tcReplacement)
		LOCAL lcString, lcHeaderText
		ASSERT LOWER(DBF()) == LOWER(THIS.cWizardDir2+"_framewk.dbf")
		IF EMPTY(tcString)
			RETURN
		ENDIF
		IF EMPTY(tcMetaString)
			lcString = STRTRAN(tcString,"*<PATHED_PROJECTNAME>*",UPPER(FORCEEXT(THIS.cMainPJX,"")))
			lcString = STRTRAN(lcString,"*<STANDARD HEADER>*", THIS.cHeaderText)
			lcString = STRTRAN(lcString,"*<PROJECTNAME>*",UPPER(JUSTSTEM(THIS.cMainPJX)))
		ELSE
			IF EMPTY(tcReplacement)
				lcString = STRTRAN(tcString, tcMetaString)
			ELSE
				lcString = STRTRAN(tcString, tcMetaString,tcReplacement)
			ENDIF
		ENDIF
		RETURN lcString
	ENDFUNC

	*** New VFP98 Framework functions ***

ENDDEFINE

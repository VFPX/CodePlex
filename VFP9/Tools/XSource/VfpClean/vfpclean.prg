
#DEFINE CRLF					CHR(13)+CHR(10)
#DEFINE DEBUG_VFPCLEAN			.F.

#DEFINE MB_NONSTARTMODE_LOC		"This utility can only be run in the full development version of Visual FoxPro."
#DEFINE MB_NOCOREFILES_LOC		"It appears that critical files (e.g., Wizards) are missing from your Visual FoxPro installation. It is recommended that you rereun the Visual FoxPro setup to reinstall these files."
#DEFINE MB_OLDDEFFILE_LOC		"You have references to critical files (e.g., Wizards) which appear to be those of an older version of Visual FoxPro.  Would you like to change your references to use files from the current version (Yes) or keep using the older ones (No)?"
#DEFINE MB_NONDEFFILE_LOC		"You have references to critical files (e.g., Wizards) which are not the default ones (you may have overridden the default setting with your own custom version). Would you like to keep your current settings (Yes) or reset to the default ones (No)?"
#DEFINE MB_RESTART_LOC			"Changes were made that require you to quit and restart Visual FoxPro."
#DEFINE MB_NORMALSTART_LOC		"The VFPClean utility will check and repair invalid Visual FoxPro options registry keys and certain critical product files."
#DEFINE MB_NORMALSTART2_LOC		"If you are running VFPClean just after installing Visual FoxPro, select <Yes>. This silent option is typically used if you "+;
								"had a previous Beta version on your machine and want to restore to a clean install state."
#DEFINE MB_NORMALSTART3_LOC		"Select <No> if you want to run VFPClean in normal interactive mode to detect invalid registry keys and critical product files. "+;
								"See the Visual FoxPro readme.htm file for more details."

#DEFINE LOG_START_LOC			"VFPClean detected and repaired the following issues (note -- the IntelliSense Manager will automatically check for valid Foxcode tables):"
#DEFINE LOG_BADREGKEY_LOC		"The following Visual FoxPro options registry keys were updated: "
#DEFINE LOG_BADFOXWS_LOC		"An outdated web services table (FOXWS.DBF) was found, backed up and deleted in the original location. This table will automatically be recreated the next time you use one of the Web Services components."
#DEFINE LOG_OLDFOXCODE_LOC		"The foxcode table (_FOXCODE) was backed up and replaced in the original location."
#DEFINE LOG_NOFOXCODE_LOC		"Your foxcode table (_FOXCODE) could not be found. Please run the IntelliSense Manager to restore it."
#DEFINE LOG_UPDATEFOXCODE_LOC	"Would you like to replace your foxcode table (_FOXCODE) with a clean copy from your home directory (a backup of your original will be made)?"
#DEFINE LOG_NOISSUES_LOC		"No issues found"
#DEFINE LOG_CHM_LOC				"The HTML Help (.CHM) file extension was found to be broken and restored."
#DEFINE LOG_APPKEY_LOC			"The HKCR Applications registry key for Visual FoxPro was invalid and restored."

#DEFINE OPEN_EXISTING			3
#DEFINE GENERIC_READ			0x80000000
#DEFINE FILE_SHARE_READ			0x00000001
#DEFINE FILE_ATTRIBUTE_READONLY	0x00000001
#DEFINE HKEY_CLASSES_ROOT		-2147483648  && BITSET(0,31)

LOCAL loApp
loApp = CREATEOBJECT("vfpclean")
IF VARTYPE(loApp)#"O"
	RETURN
ENDIF
loApp.StartClean()


DEFINE CLASS vfpclean AS Session

oFoxReg = ""
lHadError = .F.
lStartup = .F.
lShowMsgBox = .F.
lSkipOldFiles = .F.
lSkipOldFilesMsgBox = .F.
lSkipNonDefFiles = .F.
lSkipNonDefFilesMsgBox = .F.
lRequiresRestart = .F.
lDisplayLog = .F.
DIMENSION aLogs[1] = ""

PROCEDURE StartClean
	IF !THIS.CheckStartup()
		RETURN
	ENDIF
	THIS.CleanFoxReg()
	THIS.CleanSamples()
	THIS.CleanFoxCode()
	THIS.CleanFoxTask()
	THIS.CleanFoxXtras()
	THIS.CleanCHMs()
	THIS.CleanAppKey()
	SYS(3056)	&& force reread of registry
ENDPROC

PROCEDURE CheckStartup
	LOCAL lcOptionValue, lnMB, lnErr
	lcOptionValue=""
	lnErr = THIS.oFoxReg.GetFoxOption("_STARTUP", @lcOptionValue)
	THIS.lStartup = ATC("VFPCLEAN",lcOptionValue)#0
	IF !THIS.lStartup
		lnMB = MESSAGEBOX(MB_NORMALSTART_LOC+CRLF+CRLF+MB_NORMALSTART2_LOC+CRLF+CRLF+MB_NORMALSTART3_LOC,35)
		DO CASE
		CASE lnMB = 6
			THIS.lStartup = .T.
		CASE lnMB = 7
			THIS.lStartup = .F.
		OTHERWISE
			RETURN .F.
		ENDCASE
	ENDIF
	THIS.lDisplayLog = !THIS.lStartup
ENDPROC

PROCEDURE CleanFoxReg
	THIS.CheckFoxReg("_BEAUTIFY",HOME()+"BEAUTIFY.APP")
	THIS.CheckFoxReg("_BROWSER",HOME()+"BROWSER.APP")
	THIS.CheckFoxReg("_BUILDER",HOME()+"BUILDER.APP")
	THIS.CheckFoxReg("_CODESENSE",HOME()+"FOXCODE.APP")
	THIS.CheckFoxReg("_CONVERTER",HOME()+"CONVERT.APP")
	THIS.CheckFoxReg("_COVERAGE",HOME()+"COVERAGE.APP")
	THIS.CheckFoxReg("_GALLERY",HOME()+"GALLERY.APP")
	THIS.CheckFoxReg("_GENHTML",HOME()+"GENHTML.PRG")
	THIS.CheckFoxReg("_GENMENU",HOME()+"GENMENU.PRG")
	THIS.CheckFoxReg("_GENXTAB",HOME()+"VFPXTAB.PRG")
	THIS.CheckFoxReg("_OBJECTBROWSER",HOME()+"OBJECTBROWSER.APP")
	THIS.CheckFoxReg("_SCCTEXT",HOME()+"SCCTEXT.PRG")
	THIS.CheckFoxReg("_TASKLIST",HOME()+"TASKLIST.APP")
	THIS.CheckFoxReg("_WIZARD",HOME()+"WIZARD.APP")
	THIS.CheckFoxReg("_TOOLBOX",HOME()+"TOOLBOX.APP")
	THIS.CheckFoxReg("_FOXREF",HOME()+"FOXREF.APP")
	THIS.CheckFoxReg("HelpTo",HOME()+"DV_FOXHELP.CHM")
ENDPROC

PROCEDURE CleanSamples
	LOCAL lcOptionValue
	lcOptionValue=""
	lnErr = THIS.oFoxReg.GetFoxOption("_SAMPLES", @lcOptionValue)
	IF EMPTY(lcOptionValue) OR lnErr#0
		RETURN
	ENDIF
	IF LEFT(lcOptionValue,1)='"'
		lcOptionValue = EVALUATE(lcOptionValue)
	ENDIF
	IF UPPER(ADDBS(lcOptionValue))==UPPER(HOME()+"Samples\")
		RETURN
	ENDIF
	lcOptionValue = '"' + UPPER(HOME()+"Samples\") + '"'
	THIS.UpdateLog("_SAMPLES")
	THIS.oFoxReg.SetFoxOption("_SAMPLES", lcOptionValue)	
ENDPROC

PROCEDURE CheckFoxReg(tcRegkey, tcDefaultFile)
	LOCAL lcOptionValue, lcOptionName, lcDefaultFile
	lcOptionName = tcRegkey
	lcOptionValue=""
	lcDefaultFile = tcDefaultFile
	IF VARTYPE(lcOptionName) #"C" OR EMPTY(lcOptionName)
		RETURN
	ENDIF
	
	* Get value in registry
	lnErr = THIS.oFoxReg.GetFoxOption(lcOptionName, @lcOptionValue)
	IF EMPTY(lcOptionValue) OR lnErr#0
		RETURN
	ENDIF
	IF LEFT(lcOptionValue,1)='"'
		lcOptionValue = EVALUATE(lcOptionValue)
	ENDIF
	
	* quick check for default file -- most fall thru here
	IF FILE(m.lcDefaultFile) AND UPPER(lcDefaultFile)==UPPER(lcOptionValue)
		RETURN
	ENDIF

	* check if default doesn't exist but current one does
	* we'll be smart here and not prompt user in this case.
	IF !FILE(m.lcDefaultFile) AND FILE(lcOptionValue)
		RETURN
	ENDIF

	* Issue with setup not installing proper files
	IF !FILE(m.lcDefaultFile)
		IF !THIS.lShowMsgBox
			MESSAGEBOX(MB_NOCOREFILES_LOC)
			THIS.lShowMsgBox = .T.
		ENDIF
		RETURN
	ENDIF

	* Check for custom override file (e.g., GENMENUX)
	* but only if not first time (_startup = "").
	IF !THIS.lStartup
		DO CASE
		CASE !FILE(lcOptionValue)
			* File in registry doesn't exit -- just skip and replace with default
		CASE UPPER(JUSTFNAME(lcDefaultFile))==UPPER(JUSTFNAME(lcOptionValue))
			* Same file name but different path - possible older version
			IF !THIS.lSkipOldFilesMsgBox
				IF MESSAGEBOX(MB_OLDDEFFILE_LOC,36)#6
					THIS.lSkipOldFiles = .T.
				ENDIF
				THIS.lSkipOldFilesMsgBox = .T.
			ENDIF
			IF THIS.lSkipOldFiles
				RETURN
			ENDIF			
		OTHERWISE
			* Different file name (e.g., GENMENUX)
			IF !THIS.lSkipNonDefFilesMsgBox
				IF MESSAGEBOX(MB_NONDEFFILE_LOC,36)=6
					THIS.lSkipNonDefFiles = .T.
				ENDIF			
				THIS.lSkipNonDefFilesMsgBox = .T.
			ENDIF
			IF THIS.lSkipNonDefFiles
				RETURN
			ENDIF			
		ENDCASE
	ENDIF
	
	* Update registry key
	THIS.UpdateLog(lcOptionName)
	THIS.oFoxReg.SetFoxOption(lcOptionName,'"' + lcDefaultFile + '"')
ENDPROC

PROCEDURE GetBackupFile(tcFileName)
	LOCAL lnFileCount, lcBackFile, lcFileName
	lnFileCount = 0
	lcFileName = ADDBS(JUSTPATH(tcFileName)) + JUSTSTEM(tcFileName)
	DO WHILE .T.
  	  	lnFileCount=lnFileCount+1
  	  	lcBackFile = lcFileName + "_" + TRANSFORM(lnFileCount) + ".DBF"
  		IF !FILE(lcBackFile)
	    	EXIT
  		ENDIF
   	ENDDO
   	RETURN lcBackFile 
ENDPROC

PROCEDURE CleanFoxTask()
	LOCAL lcFileName
	lcFileName=_FOXTASK
	IF EMPTY(lcFileName) OR !FILE(_FOXTASK)
		* Simple check for valid file. Let's reset file here so it doesn't cause SYS(3056) to fail.
		THIS.oFoxReg.SetFoxOption("_FOXTASK","")
	ENDIF
ENDPROC

PROCEDURE CleanFoxCode()
	LOCAL lcFileName, lcBackupFile, lcEditOptions, lcHomeFile, ltFile1, ltFile2

	* Use IntelliSense Manager for most restores. This is only for startup.
	lcFileName=_FOXCODE
	IF EMPTY(lcFileName) OR !FILE(_FOXCODE)
		* Let's reset file here so it doesn't cause SYS(3056) to fail.
		THIS.oFoxReg.SetFoxOption("_FOXCODE","")
		THIS.UpdateLog(LOG_NOFOXCODE_LOC)
		RETURN
	ENDIF

	* Skip if home version not available
	lcHomeFile = HOME()+JUSTFNAME(lcFileName)
	IF !FILE(lcHomeFile) OR UPPER(lcHomeFile)==UPPER(lcFileName)
		RETURN
	ENDIF

	IF !THIS.lStartup AND MESSAGEBOX(LOG_UPDATEFOXCODE_LOC,36)=7
		RETURN
	ENDIF

	lcEditOptions = _VFP.EditorOptions
	IF ATC("Q",lcEditOptions)=0
		lcEditOptions="Q"+lcEditOptions
	ENDIF
	IF ATC("L",lcEditOptions)=0
		lcEditOptions="L"+lcEditOptions
	ENDIF
	_VFP.EditorOptions=""

	* Create backup
	lcBackupFile = THIS.GetBackupFile(lcFileName)
	USE (lcFileName) SHARED AGAIN
	IF !EMPTY(ALIAS())
		COPY TO (lcBackupFile)
		USE
		DELETE FILE (lcFileName)  RECYCLE
		DELETE FILE (FORCEEXT(lcFileName,"FPT"))  RECYCLE
		USE (lcHomeFile) SHARED AGAIN
		IF !EMPTY(ALIAS())
			COPY TO (lcFileName)
			USE
		ENDIF
		THIS.UpdateLog(LOG_OLDFOXCODE_LOC)
	ENDIF
	_VFP.EditorOptions=lcEditOptions
ENDPROC

PROCEDURE CleanFoxXtras
	* This routine cleans up extra files such as FOXREFS and FOXWS
	LOCAL lcFileName, lnFoxCodeVer, lcBackupFile, lcHomeFile

	* Delete the Foxrefs file (First time startup install only)
	lcFileName = HOME() + "foxrefs.dbf"
	IF FILE(lcFileName) AND THIS.lStartup
		USE (lcFileName) AGAIN SHARED
		IF !EMPTY(ALIAS())
			IF UPPER(FIELD(1))="CACTIVEX" AND UPPER(FIELD(2))="CFNAME"
				USE
				DELETE FILE (lcFileName)  RECYCLE
				DELETE FILE (FORCEEXT(lcFileName,"FPT"))  RECYCLE
			ENDIF
			USE
		ENDIF
	ENDIF

	* Check the FoxWS file (validate version parity with FOXCODE)
	lcFileName= ADDBS(JUSTPATH(_FOXCODE))+"foxws.dbf"
	IF FILE(lcFileName)
		lcHomeFile = HOME()+"foxcode.dbf"
		IF FILE(lcHomeFile)
			USE (lcHomeFile) AGAIN SHARED
			IF EMPTY(ALIAS())
				RETURN
			ENDIF
			GO TOP
			lnFoxCodeVer = VAL(expanded)
			USE
			USE (lcFileName) AGAIN SHARED
			IF !EMPTY(ALIAS())
				GO TOP
				IF VAL(name) # lnFoxCodeVer
					lcBackupFile = THIS.GetBackupFile(lcFileName)
					COPY TO (lcBackupFile)
					USE
					DELETE FILE (lcFileName)  RECYCLE
					DELETE FILE (FORCEEXT(lcFileName,"FPT"))  RECYCLE
					THIS.UpdateLog(LOG_BADFOXWS_LOC)
				ENDIF
			ENDIF
		ENDIF
	ENDIF
	USE
ENDPROC

PROCEDURE CleanCHMs()
	* This routine resets CHM file associations which may have been broken by
	* uninstalls of certain VS.Net and VFP7 Betas.
	LOCAL lcHHEXE,lcValue
	lcValue = ""
	* Check .CHM file extension
	IF THIS.oFoxReg.GetRegKey("",@lcValue,".chm",HKEY_CLASSES_ROOT)#0
		IF ATC("chm.file",lcValue)=0
			THIS.oFoxReg.SetRegKey("","chm.file",".chm",HKEY_CLASSES_ROOT,.T.)
		ENDIF
	ENDIF
	* Check chm.file registry key
	lcValue = ""
	IF THIS.oFoxReg.GetRegKey("",@lcValue,"chm.file",HKEY_CLASSES_ROOT)#0
		IF ATC("HTML Help",lcValue)=0
			lcHHEXE = ADDBS(GETENV("windir")) + "hh.exe"
			IF !EMPTY(GETENV("windir")) AND FILE(lcHHEXE)
				THIS.UpdateLog(LOG_CHM_LOC)
				THIS.oFoxReg.SetRegKey("","Compiled HTML Help file","chm.file",HKEY_CLASSES_ROOT,.T.)
				THIS.oFoxReg.SetRegKey("",lcHHEXE+",0","chm.file\DefaultIcon",HKEY_CLASSES_ROOT,.T.)
				THIS.oFoxReg.SetRegKey("",["]+lcHHEXE+[" %1],"chm.file\shell\open\command",HKEY_CLASSES_ROOT,.T.)
			ENDIF
		ENDIF
	ENDIF
ENDPROC

PROCEDURE CleanAppKey()
	* This routine checks for valid HKCR\Applications regkey setting of vfp7.exe.
	LOCAL lcFile, lcValue, lcKey
	lcKey =	"applications\" + JUSTFNAME(_VFP.ServerName) + "\shell\open\command"
	lcValue=""
	IF THIS.oFoxReg.GetRegKey("",@lcValue,lcKey,HKEY_CLASSES_ROOT)#0
		RETURN
	ENDIF
	IF EMPTY(lcValue)
		RETURN
	ENDIF
	lcFile = ALLTRIM(LEFT(lcValue,ATC(JUSTFNAME(_VFP.ServerName),lcValue)+7))
	IF LEFT(lcValue,1)=["]
		lcFile = SUBSTR(lcFile,2)
	ENDIF
	IF FILE(lcFile)
		RETURN
	ENDIF
	* set to valid value only if it exists
	THIS.oFoxReg.SetRegKey("",["] + _VFP.ServerName + ["] + [ -SHELLOPEN "%1"],lcKey,HKEY_CLASSES_ROOT,.T.)
	THIS.UpdateLog(LOG_APPKEY_LOC)
ENDPROC

PROCEDURE UpdateLog(tcDesc)
	IF !EMPTY(THIS.aLogs)
		DIMENSION THIS.aLogs[ALEN(THIS.aLogs)+1]
	ENDIF
	THIS.aLogs[ALEN(THIS.aLogs)] = tcDesc
ENDPROC

PROCEDURE Init
	IF _VFP.StartMode #0
		MESSAGEBOX(MB_NONSTARTMODE_LOC)
		RETURN .F.
	ENDIF
	THIS.oFoxReg=NEWOBJECT("foxreg", "..\FFC\registry")
*	THIS.oFoxReg=NEWOBJECT("foxreg", HOME()+"FFC\registry")
	IF VARTYPE(THIS.oFoxReg) # "O"
		RETURN .F.
	ENDIF
	THIS.aLogs[1] = ""
ENDPROC

PROCEDURE Destroy
	LOCAL lcLogStr,i
	IF THIS.lRequiresRestart
		MESSAGEBOX(MB_RESTART_LOC)
	ENDIF
	IF THIS.lStartup
		THIS.oFoxReg.SetFoxOption("_STARTUP", "")
	ENDIF
	IF THIS.lDisplayLog
		lcLogStr=LOG_START_LOC+CRLF
		IF EMPTY(THIS.aLogs)
			lcLogStr = lcLogStr+CRLF+LOG_NOISSUES_LOC
		ELSE
			IF LEFT(THIS.aLogs,1)="_"
				lcLogStr = lcLogStr+CRLF+LOG_BADREGKEY_LOC+CRLF
			ENDIF
			FOR i = 1 TO ALEN(THIS.aLogs)
				IF LEFT(THIS.aLogs[m.i], 1)="_"
					lcLogStr = lcLogStr+THIS.aLogs[m.i]+CRLF
				ELSE
					lcLogStr = lcLogStr + CRLF+THIS.aLogs[m.i] +CRLF
				ENDIF
			ENDFOR
		ENDIF
		MESSAGEBOX(lcLogStr)
	ENDIF
ENDPROC

PROCEDURE Error(nError, cMethod, nLine)
	THIS.lHadError = .T.
	IF DEBUG_VFPCLEAN
		? "VFPClean Error: ",nError, cMethod, nLine
	ENDIF
ENDPROC

ENDDEFINE

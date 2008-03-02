* Program:		WBMAIN.PRG
* Description:	Wizard-Builder parent class, used by wizard and builder programs.
*				_BUILDER and _WIZARD programs will SET PROC (later, SET CLASSLIB)
*				to this file and then create builder/wizard object AS WizBldr,
*				inheriting common methods and properties and overriding them as
*				appropriate.
* -----------------------------------------------------------------------------------------

#INCLUDE "WB.H"

DEFINE CLASS WizBldr AS CUSTOM
	wbcAppDir		= ""							&& .app's path
	wbcVersion		= ""
	wbcClass		= ""							&& class of underlying control
	wbcBaseClass	= ""							&& base class of underlying control
	wbcNamedClass	= ""							&& named class, passed in as parameter to builder.app
	wbcRegTable		= ""							&& holds name of registration table
	wbcRegTblLoc    = ""
	wbcLibrary		= ""							&& name of class library for specific wizard/builder
	wbcToolLibrary	= ""							&& fully qualified name of tool library
	wbcType			= ""							&& object type - wizard or builder
	wbcTypeDisplay	= ""							&& object type, localizable - wizard or builder
	wbcName			= ""							&& name of wizard/builder from reg table
	wbcBldrClass	= ""							&& name of class from reg table
	wbcDefTable		= ""							&& default reg table name
	wbcDefFPT		= ""						
	wbcDefLib		= ""							&& default library
	wbcDefDir		= ""							&& default reg table directory
	wbcLocMsg		= ""							&& specific alert message strings
	wbcNoWB			= ""
	wbcBadTable		= ""
	wbcNoName		= ""
	wbcNoClassLib	= ""
	wbcNoReg		= ""
	wbcNoDesc		= ""
	wbcStatMsg		= ""
	wbcAlertTitle	= ""
	wboName			= ""							&& created object name
	wbcTemplateTbl	= ""							&& name of table to build new reg table from
	wbReturnValue	= ""							&& passed by reference to wizards, so they can return a value
	wbParm			= ""							&& parameter string
	wbOptParms		= 0								&& number of optional parameters received
	wblModal		= .t.							&& flag for modality of wizards/builders. See Builder.prg.
	
	wblObject		= .f.							&& wizard/builder is an object, not a program
	wblNoScrn		= .f.							&& flags for wbcpOptions parameter
	wblModify		= .f.
	
	DIMENSION wbaEnvir[30]							&& holds environment settings
	DIMENSION wbaAreas[1]							&& holds work areas we've opened
	DIMENSION wbaAllData[1,8]						&& all selected data from reg table
	DIMENSION wbaData[1,8]							&& data about specific wizard/builder
	DIMENSION wbaSearchOrder[7]						&& specifies search sequence for locating files

	wbaEnvir	= ""
	wbaAreas	= ""
	wbaAllData	= ""
	wbaData		= ""
	wbaSearchOrder[1] = "WIZARDS"					&& "wizards" subdir under wizard.app
	wbaSearchOrder[2] = "REGLOC"					&& wherever the reg table is
	wbaSearchOrder[3] = "CURRENT"					&& current directory
	wbaSearchOrder[4] = "APPDIR"					&& wizard.app's directory
	wbaSearchOrder[5] = "ROOTWIZARDS"				&& "wizards" subdir under SYS(2004)
	wbaSearchOrder[6] = "STARTUP"					&& SYS(2004)
	wbaSearchOrder[7] = "FULLPATH"					&& uses FILE()
	
	
	PROCEDURE WBSaveEnvironment
	* ----------------------------------------------------------------------------
	* Save some environment settings coming in. 
	* ----------------------------------------------------------------------------
		WITH THIS
			.wbaEnvir[1] = SET("TALK")
				SET TALK OFF
			.wbaEnvir[2] = SET("STEP")
				SET STEP OFF
			.wbaEnvir[3] = SET("COMPATIBLE")
				SET COMPATIBLE OFF NOPROMPT
			.wbaEnvir[4] = SET("PROCEDURE")
			.wbaEnvir[5] = SELECT()
			.wbaEnvir[6] = SET("LIBRARY", 1)
			.wbaEnvir[7] = SET("MESSAGE", 1)
			.wbaEnvir[8] = SET("SAFETY")
				SET SAFETY OFF
			.wbaEnvir[9] = SET("PATH")
			.wbaEnvir[10] = SET("TRBETWEEN")
				SET TRBETWEEN OFF
			.wbaEnvir[11] = SET("DEVELOPMENT")
				SET DEVELOPMENT OFF
			.wbaEnvir[12] = SET("FIELDS")
				SET FIELDS OFF
			.wbaEnvir[13] = SET("FIELDS", 2)
				SET FIELDS LOCAL
			.wbaEnvir[14] = ON("ERROR")
			.wbaEnvir[15] = SET("HELP")
			.wbaEnvir[16] = SET("HELP",1)
			.wbaEnvir[17] = SET("CLASSLIB")
				SET CLASSLIB TO
			.wbaEnvir[18] = SET("ESCAPE")
				SET ESCAPE OFF
			.wbaEnvir[19] = SET("EXACT")
				SET EXACT ON
			.wbaEnvir[20] = SET("ECHO")
				SET ECHO OFF
			.wbaEnvir[21] = SET("MEMOWIDTH")
			.wbaEnvir[22] = SET("UDFPARMS")
				SET UDFPARMS TO VALUE
			.wbaEnvir[23] = SET("NEAR")
				SET NEAR OFF
			.wbaEnvir[24] = SET("UNIQUE")
				SET UNIQUE OFF
			.wbaEnvir[25] = SET("ANSI")
				SET ANSI OFF
			.wbaEnvir[26] = SET("CARRY")
				SET CARRY OFF
			.wbaEnvir[27] = SET("CPDIALOG")
				SET CPDIALOG OFF		
			.wbaEnvir[28] = SET("STATUS BAR")
			.wbaEnvir[29] = SELECT()
			.wbaEnvir[30] = SYS(3054)
				SYS(3054,0)
		ENDWITH
		PUSH KEY CLEAR
		
		SET SKIP OF BAR _mwi_hide OF _mwindow .t.
		SET SKIP OF BAR _mwi_arran OF _mwindow .t.
		SET SKIP OF BAR _mwi_rotat OF _mwindow .t.
	
	ENDPROC
	
	PROCEDURE WBSetEnvironment
	* ----------------------------------------------------------------------------
	* Reset saved environment settings before leaving. 
	* ----------------------------------------------------------------------------

		PRIVATE m.wbiLength, m.wbi, m.wbtemp

		WITH THIS
			IF NOT EMPTY(.wbaAreas[1])				&& close any files opened
				m.wbiLength = ALEN(THIS.wbaAreas, 1)
				FOR m.wbi=1 TO m.wbiLength
					IF USED(.wbaAreas[m.wbi])
						USE IN (.wbaAreas[m.wbi])
					ENDIF
				ENDFOR
			ENDIF

			IF .wbaEnvir[1] = "ON"
				SET TALK ON
			ENDIF
			
			IF .wbaEnvir[3] = "ON"
				SET COMPATIBLE ON
			ENDIF
			
			SET PROCEDURE TO
			
			IF NOT EMPTY(.wbaEnvir[4])
				m.wbatemp = .wbaEnvir[4]
				SET PROCEDURE TO &wbatemp
			ENDIF
			
			IF NOT EMPTY(.wbaEnvir[7])
				SET MESSAGE TO .wbaEnvir[7]
			ELSE
				SET MESSAGE TO
			ENDIF
			
			IF .wbaEnvir[8] = "ON"
				SET SAFETY ON
			ENDIF
			
			IF NOT EMPTY(.wbaEnvir[9])
				SET PATH TO (.wbaEnvir[9])
			ENDIF
			
			IF .wbaEnvir[10] = "ON"
				SET TRBETWEEN ON
			ENDIF
			
			IF .wbaEnvir[11] = "ON"
				SET DEVELOPMENT ON
			ENDIF
			
			IF .wbaEnvir[12] = "ON"
				SET FIELDS ON
			ENDIF
			
			IF .wbaEnvir[13] = "GLOBAL"
				SET FIELDS GLOBAL
			ENDIF

			IF NOT EMPTY(.wbaEnvir[14])
				m.wbtemp = .wbaEnvir[14]
				ON ERROR &wbtemp
			ELSE
				ON ERROR
			ENDIF
			
			IF NOT EMPTY(.wbaEnvir[15]) AND SET("HELP") <> .wbaEnvir[15]
				m.wbtemp = .wbaEnvir[15]
				set help &wbtemp
			ENDIF
			
			IF NOT EMPTY(.wbaEnvir[16]) AND SET("HELP",1) <> .wbaEnvir[16]
				m.wbtemp = .wbaEnvir[16]
				set help to (m.wbtemp)
			ENDIF

			IF NOT EMPTY(.wbaEnvir[17])
				m.templib = .wbaEnvir[17]
				SET CLASSLIB TO &templib
			ELSE
				SET CLASSLIB TO
			ENDIF

			IF .wbaEnvir[18] = "ON"
				SET ESCAPE ON
			ENDIF

			IF SET("EXACT") <> .wbaEnvir[19]
				m.wbtemp = .wbaEnvir[19]
				SET EXACT &wbtemp
			ENDIF

			IF SET("MEMOWIDTH") <> .wbaEnvir[21]
				SET MEMOWIDTH TO (.wbaEnvir[21])
			ENDIF
			
			IF SET("UDFPARMS") <> .wbaEnvir[22]
				m.wbtemp = .wbaEnvir[22]
				SET UDFPARMS TO &wbtemp
			ENDIF
			
			IF SET("NEAR") <> .wbaEnvir[23]
				m.wbtemp = .wbaEnvir[23]
				SET NEAR &wbtemp
			ENDIF
			
			IF SET("UNIQUE") <> .wbaEnvir[24]
				m.wbtemp = .wbaEnvir[24]
				SET UNIQUE &wbtemp
			ENDIF
			
			IF SET("ANSI") <> .wbaEnvir[25]
				m.wbtemp = .wbaEnvir[25]
				SET ANSI &wbtemp
			ENDIF
			
			IF SET("CARRY") <> .wbaEnvir[26]
				m.wbtemp = .wbaEnvir[26]
				SET CARRY &wbtemp
			ENDIF
			
			IF SET("CPDIALOG") <> .wbaEnvir[27]
				m.wbtemp = .wbaEnvir[27]
				SET CPDIALOG &wbtemp
			ENDIF
			
			IF SET("STATUS BAR") <> .wbaEnvir[28]
				m.wbtemp = .wbaEnvir[28]
				SET STATUS BAR &wbtemp
			ENDIF
			SELECT (.wbaEnvir[29])	&&RED00KDY  Added this
			
			SYS(3054,INT(VAL(.wbaEnvir[30])))
		ENDWITH
	
		POP KEY
		SET SKIP OF BAR _mwi_hide OF _mwindow .f.
		SET SKIP OF BAR _mwi_arran OF _mwindow .f.
		SET SKIP OF BAR _mwi_rotat OF _mwindow .f.
		set skip of bar _mpr_suspend of _mprog .F.
		set skip of popup _mtools .F.

	ENDPROC
	
	PROCEDURE WBCheckparms
	* ----------------------------------------------------------------------------
	* Parameter checking
	* ----------------------------------------------------------------------------

		IF THIS.wbcType = "WIZARD"
			m.wbcpClass = IIF(type("m.wbcpClass") <> "C", "", m.wbcpClass)
			m.wbcpName  = IIF(type("m.wbcpName") <> "C", "", m.wbcpName)
			m.wbcpOptions  = IIF(type("m.wbcpOptions") <> "C", "", m.wbcpOptions)

			THIS.wblNoScrn = C_NOSCRN $ m.wbcpOptions
			THIS.wblModify = C_MODIFY $ m.wbcpOptions
			THIS.wbcClass  = m.wbcpClass
		ELSE
			wbaControl[1] = IIF(type("wbaControl[1]") <> "O", "", wbaControl[1])
			m.wbcpOrigin  = IIF(type("m.wbcpOrigin") <> "C", "", m.wbcpOrigin)
			m.wbcpOptions  = IIF(type("m.wbcpOptions") <> "C", "", m.wbcpOptions)
			m.wbcpName  = IIF(type("m.wbcpName") <> "C", "", m.wbcpName)
		ENDIF

	ENDPROC
	
	PROCEDURE WBCheckErrors
	* ----------------------------------------------------------------------------
	* Basic entry-level error checking
	* ----------------------------------------------------------------------------

		DO CASE
			CASE VAL(SUBSTR(VERSION(),ATC("FOXPRO",VERSION())+7)) < N_MINFOXVERSION
				THIS.WBAlert(IIF(THIS.wbcType = "WIZARD", C_BADWIZVERSION_LOC, C_BADBDRVERSION_LOC))
				m.wblError = .t.
			CASE _UNIX or _MAC or _DOS 							&& other platforms
				THIS.WBAlert(IIF(THIS.wbcType = "WIZARD", C_BADWIZPLATFORM_LOC, C_BADBDRPLATFORM_LOC))
				m.wblError = .t.
			CASE VERSION(2) = 0									&& use of runtime library
				* THIS.WBAlert(IIF(THIS.wbcType = "WIZARD", C_RUNTIMEWIZ_LOC, C_RUNTIMEBDR_LOC))
				* m.wblError = .t.
		ENDCASE

		IF m.wblError
			THIS.WBSetEnvironment
			RETURN
		ENDIF
	ENDPROC
	
	PROCEDURE WBSetTools
	* ----------------------------------------------------------------------------
	* Set library here
	* ----------------------------------------------------------------------------

	*	set library to (THIS.wbcToolLibrary)

	ENDPROC
	
	PROCEDURE WBSetPlatform
	* ----------------------------------------------------------------------------
	* Platform-specific code
	* ----------------------------------------------------------------------------

	ENDPROC

	PROCEDURE WBSetProps
	* ----------------------------------------------------------------------------
	* Set properties here based on whether this is a wizard or a builder.
	* ----------------------------------------------------------------------------
	
		WITH THIS
			.wbcVersion		= IIF(.wbcType = "WIZARD", m.wbcWizVer, m.wbcBldVer)
			.wbcDefTable	= IIF(.wbcType = "WIZARD", C_REGDBFWIZ, C_REGDBFBDR)
			.wbcDefFPT		= IIF(.wbcType = "WIZARD", C_REGFPTWIZ, C_REGFPTBDR)
			.wbcDefDir  	= IIF(.wbcType = "WIZARD", C_DIRWIZ, C_DIRBDR)
			.wbcDefLib  	= IIF(.wbcType = "WIZARD", C_LIBWIZ, C_LIBBDR)
			.wbcLocMsg		= IIF(.wbcType = "WIZARD", C_FINDWIZREG_LOC, C_FINDBDRREG_LOC)
			.wbcNoWB   		= IIF(.wbcType = "WIZARD", C_NOWIZARDS_LOC, C_NOBUILDERS_LOC)
			.wbcBadTable  	= C_BADREGTABLE_LOC
			.wbcNoName   	= IIF(.wbcType = "WIZARD", C_NOWIZNAME_LOC, C_NOBDRNAME_LOC)
			.wbcNoClassLib	= IIF(.wbcType = "WIZARD", C_NOWIZLIB_LOC, C_NOBDRLIB_LOC)
			.wbcNoReg		= IIF(.wbcType = "WIZARD", C_NOWIZREG_LOC, C_NOBDRREG_LOC)
			.wbcNoDesc   	= IIF(.wbcType = "WIZARD", C_NOWIZDESC_LOC, C_NOBDRDESC_LOC)
			.wbcStatMsg   	= IIF(.wbcType = "WIZARD", C_STATMSGWIZ_LOC, C_STATMSGBDR_LOC)
			.wbcTemplateTbl	= IIF(.wbcType = "WIZARD", C_TPLDBFWIZ, C_TPLDBFBDR)
			.wbcAlertTitle 	= IIF(.wbcType = "WIZARD", MB_MSGBOXWIZTITLE_LOC, MB_MSGBOXBDRTITLE_LOC)
		ENDWITH
	
		SET MESSAGE TO THIS.wbcStatMsg

		this.wbcAppDir=""
		IF ATC("BUILDER.FXP",SYS(16,1))>0
			this.wbcDefDir="BUILDERS\"
			RETURN
		ENDIF
		FOR m.wbi = 1 TO 10000
			m.wbtestdir = SYS(16,m.wbi)
			IF NOT EMPTY(m.wbtestdir)
				THIS.wbcAppDir = m.wbtestdir
				m.appslash = RAT("\",THIS.wbcAppDir)
				m.wbappname = IIF(m.appslash>0, SUBSTR(THIS.wbcAppDir,m.appslash+1), "")
				m.wbapptest = UPPER(THIS.wbcType + ".APP")		&& do not localize
				IF m.wbapptest $ UPPER(m.wbappname)
					EXIT
				ENDIF
			ELSE
				EXIT
			ENDIF
		ENDFOR		
		
		THIS.wbcAppDir = LEFT(THIS.wbcAppDir, RAT("\",THIS.wbcAppDir))
		IF LEFT(this.wbcAppDir,10)=="PROCEDURE "
			this.wbcAppDir=ALLTRIM(SUBSTR(this.wbcAppDir,RAT(" ",this.wbcAppDir)+1))
		ENDIF

	ENDPROC

	
	PROCEDURE WBGetRegTable
	* ----------------------------------------------------------------------------
	* Locate the registration table, verify its integrity, build a new one if
	* necessary. Populate array wbaAllData[] with info about the wizards/builders
	* of interest, update registration table preference in FoxUser.dbf. Return
	* name of registration table.
	* ----------------------------------------------------------------------------

		PRIVATE m.wbcTable, m.wbcOnError, m.wblError, m.wbiSelect, m.wbi, m.wbi2, m.wbiLength, ;
		        m.defTable, m.defDir, m.wblPrefIsDef, m.wbcJustname

		m.wblError	= .f.
		m.wbiSelect	= SELECT()
		
		* Find the registration table.
		* ----------------------------		
		m.wbcTable	= THIS.WBGetRegPref("PREFW", THIS.wbcTypeDisplay + "S", C_REGTBLSTRING_LOC)
		
		IF empty(m.wbcTable)
			m.wbcTable = THIS.wbcDefTable		
		ENDIF
		
		m.wbcJustname = SUBSTR(m.wbcTable, RAT("\",m.wbcTable) + 1)
		m.wblPrefIsDef = m.wbcJustname = THIS.wbcDefTable			&& preference name = default name?
		IF not file(m.wbcTable)										&& if specified file does not exist,
			m.wbcTable = THIS.WBSearch(m.wbcTable)					&& look for it
			
			IF empty(m.wbcTable) and not m.wblPrefIsDef
				m.wbcTable = THIS.WBSearch(THIS.wbcDefTable)		&& look for default reg table
			ELSE
				IF NOT FILE(m.wbcTable)
					m.wbcTable=""
				ENDIF
			ENDIF
			IF empty(m.wbcTable)
				IF NOT "WBPICK" $ UPPER(SET("CLASSLIB"))
					SET CLASSLIB TO wbpick ADDITIVE
				ENDIF
				m.cLocAction = ""
				oLocate = CREATE("wbLocate", THIS.wbcType, THIS.wbcTypeDisplay)			&& updates m.cLocAction
				oLocate.SHOW
				RELEASE oLocate
				RELEASE CLASS WBPICK
				DO CASE
					CASE m.cLocAction = "Locate"
						m.wbcTable = THIS.WBFindFile(THIS.wbcDefTable, "DBF")
					CASE m.cLocAction = "Create"					
						m.wbcTable = THIS.WBMakeRegTable()
				ENDCASE
			ENDIF
		ENDIF
		
		* See IF we can open the reg table.
		* ---------------------------------
		IF NOT EMPTY(m.wbcTable)						&& check for no table name - WBMakeRegTable() may
			IF USED("_wbregtbl_")						&& have failed
				SELECT _wbregtbl_
			ELSE
				SELECT 0
			ENDIF

			m.wbcOnError = on("error")
			ON ERROR m.wblError = .t.

			USE (m.wbcTable) AGAIN ALIAS _wbregtbl_ SHARED

			ON ERROR &wbcOnError
			IF m.wblError
				= THIS.WBAlert(C_BADREGOPEN_LOC + m.wbcTable)
				m.wbcTable = ""
			ELSE
				= THIS.WBAddArea(ALIAS())
			ENDIF
		ENDIF
		
		* See if reg table is populated. If not, offer to recreate the default reg table.
		* -------------------------------------------------------------------------------
		IF NOT EMPTY(m.wbcTable)
			IF eof("_wbregtbl_")
				USE IN _wbregtbl_
				IF THIS.WBAlert(THIS.wbcNoWB, MB_OKCANCEL) = MB_RET_OK
					m.wbcTable = THIS.WBMakeRegTable()
				ELSE
  					m.wbcTable = ""
				ENDIF
			ENDIF
		ENDIF
				  
		* Verify structure of reg table. If bad, offer to recreate the default table.
		* ---------------------------------------------------------------------------
		IF NOT EMPTY(m.wbcTable)
			USE (m.wbcTable) AGAIN ALIAS _wbregtbl_ SHARED
			IF NOT (type("name") = "C" AND type("descript") = "M" AND type("bitmap") = "M" AND ;
			        type("type") = "C" AND type("program") = "M" AND type("classlib") = "M" AND ;
			        type("classname") = "M" AND type("parms") = "M")
				IF THIS.WBAlert(m.wbcTable + THIS.wbcBadTable, MB_YESNO) = MB_RET_YES
					USE IN _wbregtbl_
					m.wbcTable = THIS.WBMakeRegTable()
				ELSE
					m.wbcTable = ""
				ENDIF
			ENDIF
		ENDIF
				  

		* Update preference in foxuser.
		* -----------------------------
		IF NOT EMPTY(m.wbcTable)
			USE (m.wbcTable) AGAIN ALIAS _wbregtbl_ SHARED
			= THIS.WBPutRegPref('PREFW', THIS.wbcTypeDisplay + "S", C_REGTBLSTRING_LOC, .f., m.wbcTable)
		ENDIF
		
		THIS.wbcRegTblLoc = LEFT(m.wbcTable,RAT("\",m.wbcTable)-1)
			
		* Populate the wbaAllData[] array.
		* --------------------------------
		IF NOT EMPTY(m.wbcTable)
			THIS.WBGetData
		ENDIF
		
		IF USED("_wbregtbl_")
			USE IN _wbregtbl_
		ENDIF
		SELECT (m.wbiSelect)

		THIS.wbcRegTable = m.wbcTable
		
	ENDPROC
	

	PROCEDURE WBGetData
	* ----------------------------------------------------------------------------
	* Populate the wbaAllData[] array from the registration table.
	* ----------------------------------------------------------------------------	
	
		m.wbiTally = 0
		
		IF NOT EMPTY(m.wbcpName)											&& specific file requested
			m.wbiTally = THIS.WBDoSelect("NAMEDFILE")
		ENDIF
		
		IF m.wbiTally = 0 AND NOT EMPTY(THIS.wbcNamedClass)					&& specific class requested (builders only)
			m.wbiTally = THIS.WBDoSelect("NAMEDCLASS")
		ENDIF
		
		IF m.wbiTally = 0 AND NOT EMPTY(THIS.wbcClass)						&& class of selected control, or wizard class
			m.wbiTally = THIS.WBDoSelect("CLASS")
		ENDIF

		IF m.wbiTally = 0 AND NOT EMPTY(THIS.wbcBaseClass)					&& base class of selected control (builders only)
			m.wbiTally = THIS.WBDoSelect("BASECLASS")
		ENDIF
				
		IF m.wbiTally = 0
			DO CASE
				CASE NOT EMPTY(m.wbcpName)								&& specific file not found
					= THIS.WBAlert(THIS.wbcNoName)

				CASE NOT EMPTY(THIS.wbcClass)								&& specific type of file not found
					IF TYPE("m.wbcpOrigin")= "U" OR m.wbcpOrigin <> "TOOLBOX"
						= THIS.WBAlert(THIS.wbcNoClassLib)
					ENDIF
				
				OTHERWISE
					IF m.wbiTally = 0
						m.wbiTally = THIS.WBDoSelect("")
					ENDIF
			ENDCASE
		ENDIF

		IF m.wbiTally = 0
			m.wbcTable = ""
		ELSE
			IF NOT EMPTY(ALLTRIM(m.wbcpOptions))
				m.wbiLength = ALEN(THIS.wbaAllData, 1)						&& react to params if any - make copy of 
				m.wbCopysize = 0											&& array for those with correct param, update
				FOR m.wbi=1 TO m.wbiLength									&& wbaAllData from that
					IF ! EMPTY(THIS.wbaAllData[m.wbi, 8])
						IF " " + UPPER(ALLTRIM(THIS.wbaAllData[m.wbi, 8])) + " " $ " " + UPPER(m.wbcpOptions) + " "
							m.wbCopysize = m.wbCopysize + 1
							DIMENSION wbaCopy[m.wbCopysize, 8]
							FOR m.wbi2 = 1 to 8
								wbaCopy[m.wbCopysize, m.wbi2] = THIS.wbaAllData[m.wbi, m.wbi2]
							ENDFOR
						ENDIF
					ENDIF
				ENDFOR
				
				IF m.wbCopysize > 0										&& One or more registered entries had something
					DIMENSION THIS.wbaAllData[ALEN(wbaCopy,1), 8]		&& in the PARAMS field that is also in the
					= ACOPY(wbaCopy,THIS.wbaAllData)					&& m.wbcpOptions parameter. Alter wbaAllData[]
				ENDIF													&& to include only these.
			ENDIF

			m.wbiLength = ALEN(THIS.wbaAllData, 1)						&& supply generic description message
			FOR m.wbi=1 TO m.wbiLength									&& where needed
				IF EMPTY(THIS.wbaAllData[m.wbi, 2])
					THIS.wbaAllData[m.wbi, 2] = THIS.wbcNoDesc
				ENDIF
				FOR m.wbi2=3 TO 7
					THIS.wbaAllData[m.wbi, m.wbi2] = UPPER(THIS.wbaAllData[m.wbi, m.wbi2])
				ENDFOR
			ENDFOR
		ENDIF

	ENDPROC


	PROCEDURE WBDoSelect
	* Suppress "auto" wizard types unless they're being explicitly asked for by the product
	* ----------------------------------------------------------------------------
		PARAMETER wbcSelectCode
		LOCAL lnDataCompat
		lnDataCompat=SYS(3099)
		SYS(3099,70)
		DO CASE
			CASE m.wbcSelectCode == "NAMEDFILE"
		  																		&& in program field
				SELECT name, descript, bitmap, type, program, ;
					classlib, classname, parms ;
					FROM _wbregtbl_ ;
					WHERE UPPER(m.wbcpName) $ UPPER(program) OR UPPER(type) = C_ALL  ;
					INTO ARRAY THIS.wbaAllData ;
					ORDER BY name ;
					GROUP BY name
				IF _tally = 0													&& if no program, look in classname field
					SELECT name, descript, bitmap, type, program, ;
						classlib, classname, parms ;
						FROM _wbregtbl_ ;
						WHERE UPPER(m.wbcpName) = UPPER(classname) OR UPPER(type) = C_ALL ;
						INTO ARRAY THIS.wbaAllData ;
						ORDER BY name ;
						GROUP BY name
				ENDIF
			
			CASE m.wbcSelectCode == "NAMEDCLASS" OR m.wbcSelectCode == "CLASS" OR m.wbcSelectCode == "BASECLASS"
				DO CASE
					CASE m.wbcSelectCode == "NAMEDCLASS"
						m.wbcThisclass = THIS.wbcNamedClass
					CASE m.wbcSelectCode == "CLASS"
						m.wbcThisclass = THIS.wbcClass
					CASE m.wbcSelectCode == "BASECLASS"
						m.wbcThisclass = THIS.wbcBaseClass
				ENDCASE
				
				IF LEFT(UPPER(m.wbcThisclass),4) = "AUTO"
					SELECT name, descript, bitmap, type, program, ;
						classlib, classname, parms ;
						FROM _wbregtbl_ ;
						WHERE upper(type) = upper(m.wbcThisclass) OR UPPER(type) = C_ALL ;
						INTO ARRAY THIS.wbaAllData ;
						ORDER BY name ;
						GROUP BY name
			ELSE
					SELECT name, descript, bitmap, type, program, ;
						classlib, classname, parms ;
						FROM _wbregtbl_ ;
						WHERE (UPPER(type) = UPPER(m.wbcThisclass) OR UPPER(type) = C_ALL) AND LEFT(UPPER(type),4) <> "AUTO" ;
						INTO ARRAY THIS.wbaAllData ;
						ORDER BY name ;
						GROUP BY name
			ENDIF

			OTHERWISE															&& otherwise take all entries
				SELECT name, descript, bitmap, type, program, ;
					classlib, classname, parms ;
				FROM _wbregtbl_ ;
				WHERE LEFT(UPPER(type),4) <> "AUTO" OR UPPER(type) = C_ALL  ;
				INTO ARRAY THIS.wbaAllData ;
				ORDER BY name ;
				GROUP BY name
		ENDCASE
		SYS(3099,lnDataCompat)
		
		RETURN _TALLY

	ENDPROC

	PROCEDURE WBGetName
	* ----------------------------------------------------------------------------
	* Find specific file to run.
	* ----------------------------------------------------------------------------

		PRIVATE wbcToDo, wbcToFind, wbcFile, wbi, wbiSlot, wbiSelect, wblUserLib

		m.wbiSelect = SELECT()
		STORE "" TO m.wbcToDo, wbcToFind
		m.wblUserLib = .f.

		* one and only one entry found
		IF ALEN(THIS.wbaAllData,1) = 1 and NOT EMPTY(THIS.wbaAllData[1,1])
			m.wbiSlot = 1
		ELSE
			m.wbiSlot = THIS.WBNameSelect()		&& pick list, returns slot of desired entry in wbaAllData[]
			IF TYPE("wbiSlot") <> "N" OR m.wbiSlot = 0
				RETURN ""						&& user bailed out of picklist
			ENDIF
		ENDIF
		
		* We now have a slot with an entry, store it to wbaData[].
		FOR m.wbi = 1 TO 8
			THIS.wbaData[1, m.wbi] = ALLTRIM(THIS.wbaAllData[m.wbiSlot, m.wbi])
		ENDFOR
		
		* Handle cases of what's registered. Program names have priority, otherwise use the class
		* library to create an instance.

		DO CASE
			CASE NOT EMPTY(THIS.wbaData[1,5])					&& program name
				m.wbcToDo = alltrim(THIS.wbaData[1,5])
				THIS.wbcBldrClass = ALLTRIM(THIS.wbaData[1,7])
				
			CASE NOT EMPTY(THIS.wbaData[1,7])
				THIS.wblObject = .t.
				m.wbcToDo = THIS.wbaData[1, 7]					&& class name
				THIS.wbcLibrary = THIS.wbaData[1, 6]			&& class library containing this class definition
				IF empty(THIS.wbcLibrary)
					THIS.wbcLibrary = THIS.wbcAppDir + THIS.wbcDefDir + THIS.wbcDefLib		&& assume default library
				ELSE																	&& if none specified
					m.wblUserLib = .t.
				ENDIF																	
				
			OTHERWISE
				IF m.wbcpOrigin <> "TOOLBOX"
					= THIS.WBAlert(THIS.wbcNoReg)				&& neither a program nor a class
				ENDIF
				
				RETURN ""									&& was registered
		ENDCASE

		m.wbcFile = ""

		* If it's a .prg, look for that. If it's an object, look for the class
		* library, and then look in that for the class name. If we can't find the 
		* user-specified class library, look in the default class library (WIZARD.VCX
		* or BUILDER.VCX). If either a library can't be found, or the class name can't be
		* found in the library, alert message asks user if they want to locate the
		* library containing the definition
		
		m.wbcToFind = IIF(THIS.wblObject, THIS.wbcLibrary, m.wbcToDo)

		DO WHILE .t.

			m.wbcFile = THIS.WBSearch(m.wbcToFind)
		  
			* if user-specified library not found, try default class library
			IF empty(m.wbcFile) and m.wblUserLib
				THIS.wbcLibrary = THIS.wbcAppDir + THIS.wbcDefDir + THIS.wbcDefLib
				m.wblUserLib = .f.
				m.wbcToFind = THIS.wbcLibrary
				loop
			ENDIF
			
			DO CASE
				CASE not THIS.wblObject				&& not an object
					m.wbcToDo = m.wbcFile
					IF empty(m.wbcToDo)
						= THIS.WBAlert(THIS.wbcNoName)
					ELSE
						IF !FILE(m.wbcToDo)
							wbcToDo = HOME() + wbcToDo
							IF !FILE(m.wbcToDo)
								THIS.WBAlert(THIS.wbcNoName)
								m.wbcToDo = ""
							ENDIF
						ENDIF
					ENDIF
					
				CASE NOT EMPTY(m.wbcFile)			&& found an object library - now be sure that
					THIS.wbcLibrary = m.wbcFile		&& class definition exists also
					SELECT 0
					USE (THIS.wbcLibrary) AGAIN ALIAS _WBlib SHARED NOUPDATE
					= THIS.WBAddArea(ALIAS())
					locate for alltrim(upper(objname)) == alltrim(THIS.wbaData[1, 7]) and empty(parent)	&& class definition
					IF not found()
						m.wbcToDo = ""
						IF THIS.WBAlert(THIS.wbcNoClassLib + CHR(13) + C_NOLIB2_LOC, MB_OKCANCEL) = MB_RET_OK
							loop
						ENDIF
					ELSE
						m.wbcToDo = alltrim(THIS.wbaData[1, 7])
					ENDIF
					USE IN _WBlib
					
				otherwise							&& class library not found
					IF THIS.WBAlert(THIS.wbcNoClassLib + CHR(13) + C_NOLIB2_LOC, MB_OKCANCEL) = MB_RET_OK
						loop
					ENDIF
			ENDCASE
			
			exit

		enddo

		THIS.wbcName = m.wbcToDo

		THIS.WBAddparms
	
	ENDPROC
	
	
	PROCEDURE WBAddparms
	* ----------------------------------------------------------------------------
	* Construct parameters string. In general, two types of parameters are possible. Parameters can be 
	* passed in to a specific wizard or builder ("DO <wizard> WITH <param1>, <param2>", etc). Also, wizards/builders
	* can have variations and these can be registered in the parms field of the reg table. For example, DO FORMWIZ.APP
	* WITH "NORMALFORM", or DO FORMWIZ.APP WITH "ONE_TO_MANY" - the same formwiz.app runs either wizard, depending
	* on this flag. This function prepends any parameters in the parms field of the reg table onto whatever parameter
	* string may exist.
	* ----------------------------------------------------------------------------
	
		THIS.wbParm = "'wbReturnValue'"											&& return value reference
		THIS.wbParm = THIS.wbParm + ",'" + alltrim(THIS.wbaData[1, 8]) + "'"	&& entry in parms field of reg table
		THIS.wbParm = THIS.wbParm + ",m.wbcpOptions"							&& optional keyword parameter (eg "NOSCRN")
		
		FOR m.wbi=1 to THIS.wbOptParms
			m.thisp = "wbcpP" + LTRIM(STR(m.wbi))
			THIS.wbParm = THIS.wbParm + "," + m.thisp	&& will create ...,wbcpP1,wbcpP2..." etc
		ENDFOR
	
		* Sample result - THIS.wbParm = "'wbReturnValue','',m.wbcpOptions,wbcpP1,wbcpP2"
	
	ENDPROC
	
	
	PROCEDURE WBCall
	* ----------------------------------------------------------------------------
	* Call the file. 
	* ----------------------------------------------------------------------------

		SELECT (THIS.wbaEnvir[5])

		PRIVATE m.wbReturnValue, m.cParmstring
		m.wbReturnValue = THIS.wbReturnValue
		m.cParmstring = THIS.wbParm

		IF THIS.wblObject
			SET CLASSLIB TO (THIS.wbcLibrary) ADDITIVE
			
			PUBLIC wboName

			wboName = CREATEOBJ(THIS.wbcName, &cParmstring)		&& all builders and wizards are modal formsets


			IF TYPE("_TIMING") <> "U" AND _TIMING
				RETURN
			ENDIF
			
			IF TYPE("wboName") = "O"
				wboName.SHOW
				IF THIS.wbcName = "RIBUILDR"
					SET SKIP OF BAR _MWI_DEBUG OF _MSM_TOOLS .f.
					SET SKIP OF BAR _MWI_TRACE OF _MSM_TOOLS .f.
				ENDIF
			ENDIF

		ELSE
			
			IF UPPER(JUSTEXT(THIS.wbcName))="SCX"
				DO FORM (THIS.wbcName) WITH &cParmstring
			ELSE
				DO (THIS.wbcName) WITH &cParmstring
			ENDIF
		ENDIF

		THIS.wbReturnValue = m.wbReturnValue
		
		IF THIS.wblModal							&& don't release, if modeless for testing
			RELEASE wboName
			IF THIS.wblObject AND FILE(THIS.wbcLibrary)
				RELEASE CLASSLIB (THIS.wbcLibrary)
			ENDIF
		ENDIF
		
	ENDPROC
	
	PROCEDURE WBSearch
	* ----------------------------------------------------------------------------
	* Locates program files or class libraries, using a flexible search logic as 
	* specified in THIS.SearchOrder array. 
	* ----------------------------------------------------------------------------

		PARAMETERS wbcFind

		PRIVATE m.wbcFind, m.wbiLength, m.wbi, m.wblFoundit
		
		IF TYPE("m.wbcFind") <> "C"
			RETURN ""
		ENDIF

		IF "\" $ m.wbcFind
			* qualified filename is okay
			IF !FILE(m.wbcFind) AND TYPE("EVAL(m.wbcFind)")=="C" AND FILE(EVAL(m.wbcFind))
				m.wbcFind = EVAL(m.wbcFind)
			ENDIF
		ELSE
			m.wbjustfile = m.wbcFind
			IF "\" $ m.wbjustfile
				m.wbjustfile = SUBSTR(m.wbjustfile,RAT("\",m.wbjustfile)+1)
			ENDIF
			m.wbiLength = ALEN(THIS.wbaSearchOrder, 1)
			m.wblFoundit = .f.
			FOR m.wbi = 1 TO m.wbiLength
			
				* For specific directory testing, use ADIR() because FILE() will find files of the same name
				* inside the .app and incorrectly return .t.
				
				DO CASE
					CASE THIS.wbaSearchOrder[m.wbi] = "WIZARDS" ;
						AND ADIR(wbaTemp, THIS.wbcAppDir + THIS.wbcDefDir + m.wbjustfile) > 0		&& check wizards subdirectory
							m.wbcFind = THIS.wbcAppDir + THIS.wbcDefDir + m.wbjustfile				&& under wizard.app, SYS(16,1)
							m.wblFoundit = .t.
							EXIT
					CASE THIS.wbaSearchOrder[m.wbi] = "REGLOC" AND NOT EMPTY(THIS.wbcRegTblLoc) ;
						AND ADIR(wbaTemp, THIS.wbcRegTblLoc + "\" + m.wbjustfile) > 0		&& check reg table location,
							m.wbcFind = THIS.wbcRegTblLoc + "\" + m.wbjustfile				&& whereever that is
							m.wblFoundit = .t.
							EXIT
					CASE THIS.wbaSearchOrder[m.wbi] = "CURRENT" ;
						AND ADIR(wbaTemp, IIF(SYS(2003)=="\","",SYS(2003)) + "\" + ;
								m.wbjustfile) > 0		&& check current subdirectory
							m.wbcFind = SYS(2003) + "\" + m.wbjustfile
							m.wblFoundit = .t.
							EXIT
					CASE THIS.wbaSearchOrder[m.wbi] = "APPDIR" ;
						AND ADIR(wbaTemp, THIS.wbcAppDir + m.wbjustfile) > 0		&& check wizard.app's directory, SYS(16,1)
							m.wbcFind = THIS.wbcAppDir + m.wbjustfile
							m.wblFoundit = .t.
							EXIT
					CASE THIS.wbaSearchOrder[m.wbi] = "ROOTWIZARDS" ;
						AND ADIR(wbaTemp, SYS(2004) + THIS.wbcDefDir + m.wbjustfile) > 0		&& check SYS(2004)\wizards subdirectory
							m.wbcFind = SYS(2004) + THIS.wbcDefDir + m.wbjustfile
							m.wblFoundit = .t.
							EXIT
					CASE THIS.wbaSearchOrder[m.wbi] = "STARTUP" ;
						AND ADIR(wbaTemp, SYS(2004) + m.wbjustfile) > 0						&& check startup directory, SYS(2004)
							m.wbcFind = SYS(2004) + m.wbjustfile
							m.wblFoundit = .t.
							EXIT
					CASE THIS.wbaSearchOrder[m.wbi] = "FULLPATH" ;
						AND FILE(m.wbjustfile)										&& check full path with file() 
							m.wblFoundit = .t.
							EXIT
				ENDCASE
			ENDFOR
		    IF NOT m.wblFoundit 
				m.wbcFind = ""
			ENDIF
		ENDIF

		RETURN m.wbcFind

	ENDPROC
	
	PROCEDURE WBFindFile
	* ----------------------------------------------------------------------------
	* Uses GETFILE() to locate a particular file.
	* ----------------------------------------------------------------------------

		PARAMETERS m.wbcFile, wbcExtension, wbcBtnCaption

		PRIVATE wbcFile, wbcExtension, wbcBtnCaption
		m.wbcExtension = IIF(empty(m.wbcExtension), "", m.wbcExtension)
		m.wbcBtnCaption = IIF(empty(m.wbcBtnCaption), "OK", m.wbcBtnCaption)

		RETURN getfile(m.wbcExtension, C_LOCATE_LOC + alltrim(m.wbcFile) + ":", m.wbcBtnCaption)
	ENDPROC
	
	PROCEDURE WBMakeRegTable
	* ----------------------------------------------------------------------------
	* Creates subdirectory if necessary and calls WBPutRegTable() to create
	* the registration table.
	* ----------------------------------------------------------------------------

		PRIVATE wbcTblName

		m.wbcTblName = ""
		IF ADIR(wbaTemp, THIS.wbcAppDir + STRTRAN(THIS.wbcDefDir, "\"), "D") = 0
			MD (THIS.wbcAppDir + STRTRAN(THIS.wbcDefDir, "\"))						&& create directory
		ENDIF

		DO WHILE .t.
			m.wbcTblName = THIS.WBPutRegTable(THIS.wbcAppDir + THIS.wbcDefDir)
			IF EMPTY(m.wbcTblName)
				IF THIS.WBAlert(C_MAKEREGERROR_LOC, MB_OKCANCEL) = MB_RET_OK
					LOOP
				ENDIF
			ENDIF
			EXIT
		ENDDO

		RETURN m.wbcTblName
	ENDPROC
	
	PROCEDURE WBPutRegTable
	* ----------------------------------------------------------------------------
	* Creates registration table.
	* ----------------------------------------------------------------------------

		PARAMETER m.wbcStartDir

		PRIVATE m.wbcStartDir, wbcDirName, wbiSelect, wbcOnerror, wblError

		m.wblError = .f.
		DO WHILE .t.
			m.wbcDirName = IIF(!EMPTY(m.wbcStartDir), m.wbcStartDir,  ;
				GETDIR(CURDIR(), C_SELDIR_LOC))
			m.wbcStartDir = ""
			IF EMPTY(m.wbcDirName)
				EXIT
			ENDIF
			m.wbiSelect = SELECT()
			SELECT 0
			m.wbcOnError = ON("ERROR")
			ON ERROR m.wblError = .t.
			IF NOT USED("_wbnewreg_")
				USE (THIS.wbcTemplateTbl) ALIAS _wbnewreg_		&& wRegTbl.dbf/bRegTbl.dbf will be burned into app
			ELSE
				SELECT _wbnewreg_
			ENDIF
			= THIS.WBAddArea(ALIAS())
					
			m.wblProVersion = VERSION(2) = 2					&& pro version = 2, standard = 1, runtime = 0
			m.wblStdVersion = VERSION(2) = 1
			
			IF FILE(m.wbcDirName + THIS.wbcDefTable)		&& table could exist with bad structure, make
				m.wzstest = m.wbcDirName + THIS.wbcDefTable	&& sure it's writable
				m.wzihandle = FOPEN(m.wzstest,12)
				IF m.wzihandle < 0
			    	= THIS.WBAlert(UPPER(m.wzstest) + " " + C_BADOPEN_LOC,0)
			    	m.wbcDirName = ""
    				EXIT
  				ELSE
    				= FCLOSE(m.wzihandle)
				ENDIF
				
				m.cMemoname = IIF(UPPER(RIGHT(m.wzstest,4)) = ".DBF",LEFT(m.wzstest,LEN(m.wzstest)-4),m.wzstest) + ".fpt"
				IF FILE(m.cMemoname)
					m.wzihandle = FOPEN(m.cMemoname,12)
					IF m.wzihandle < 0
						= THIS.WBAlert(UPPER(m.wzstest) + " " + C_BADOPEN_LOC,0)
			    		m.wbcDirName = ""
	    				EXIT
  					ELSE
    					= FCLOSE(m.wzihandle)
					ENDIF
				ENDIF
			ENDIF
			
			IF m.wblProVersion
				DO CASE
					CASE _DOS
						COPY TO (m.wbcDirName + THIS.wbcDefTable) ;
						FIELDS name, descript, bitmap, type, program, classlib, classname, parms ;
						FOR platform = "D"

					CASE _WINDOWS
						COPY TO (m.wbcDirName + THIS.wbcDefTable) ;
						FIELDS name, descript, bitmap, type, program, classlib, classname, parms ;
						FOR platform = "W"
					  
					CASE _MAC
						COPY TO (m.wbcDirName + THIS.wbcDefTable) ;
						FIELDS name, descript, bitmap, type, program, classlib, classname, parms ;
						FOR platform = "M"
				ENDCASE
			ENDIF
			
			IF m.wblStdVersion
				DO CASE
					CASE _DOS
						COPY TO (m.wbcDirName + THIS.wbcDefTable) ;
						FIELDS name, descript, bitmap, type, program, classlib, classname, parms ;
						FOR platform = "D" AND NOT proversion

					CASE _WINDOWS
						COPY TO (m.wbcDirName + THIS.wbcDefTable) ;
						FIELDS name, descript, bitmap, type, program, classlib, classname, parms ;
						FOR platform = "W" AND NOT proversion
					  
					CASE _MAC
						COPY TO (m.wbcDirName + THIS.wbcDefTable) ;
						FIELDS name, descript, bitmap, type, program, classlib, classname, parms ;
						FOR platform = "M" AND NOT proversion
				ENDCASE
			ENDIF
			
			USE IN _wbnewreg_
			
			ON ERROR &wbcOnError
			IF m.wblError
				IF FILE(m.wbcDirName + THIS.wbcDefTable)
					ERASE (m.wbcDirName + THIS.wbcDefTable)
				ENDIF
				IF FILE(m.wbcDirName + THIS.wbcDefFPT)
					ERASE (m.wbcDirName + THIS.wbcDefFPT)
				ENDIF
				IF THIS.WBAlert(C_MAKEREGERROR_LOC, MB_OKCANCEL) = MB_RET_OK		&& Error - try again?
					LOOP
				ELSE
					m.wbcDirName = ""
				ENDIF
			ENDIF
			EXIT
		ENDDO

		RETURN m.wbcDirName + IIF(!empty(m.wbcDirName), THIS.wbcDefTable, "")
		
	ENDPROC
	
	PROCEDURE WBGetRegPref
	* ----------------------------------------------------------------------------
	* Locates the registration preference entry in the resource file.
	* ----------------------------------------------------------------------------

		PARAMETERS m.wbcPrefType, m.wbcPrefID, m.wbcPrefName

		PRIVATE wbcPrefType, wbcPrefID, wbcPrefName, wbiSelect, wbcOnError, ;
				wbcErrorMsg, wblError, wbcExact, wbcData

		IF set("resource") = "OFF"
			RETURN ""
		ENDIF
		IF empty(m.wbcPrefType) and empty(m.wbcPrefID) and empty(m.wbcPrefName)
			RETURN ""
		ENDIF

		m.wbcPrefType = IIF(empty(m.wbcPrefType), "", m.wbcPrefType)
		m.wbcPrefID = IIF(empty(m.wbcPrefID), "", m.wbcPrefID)
		m.wbcPrefName = IIF(empty(m.wbcPrefName), "", m.wbcPrefName)
		m.wbcErrMsg = C_RSCERROR_LOC + CHR(13) + CHR(13) + SYS(2005)

		m.wbiSelect = SELECT()
		SELECT 0
		m.wbcOnError = on("error")
		m.wblError = .f.
		ON ERROR m.wblError = .t.
		USE SYS(2005) AGAIN ALIAS wbcRsc SHARED
		IF m.wblError
			m.wblError = .f.
			= THIS.WBAlert(m.wbcErrMsg)
			IF m.wblError
				wait window m.wbcErrorMsg
			ELSE
				m.wblError = .t.
			ENDIF
		ENDIF
		ON ERROR &wbcOnError
		IF m.wblError
			SELECT (m.wbiSelect)
			RETURN ""
		ELSE
			= THIS.WBAddArea(ALIAS())
		ENDIF

		m.wbcExact = set("exact")
		set exact on
		locate for IIF(!empty(m.wbcPrefType), type = m.wbcPrefType, .t.) ;
			and IIF(!empty(m.wbcPrefID), id = m.wbcPrefID, .t.) ;
			and IIF(!empty(m.wbcPrefName), name = m.wbcPrefName, .t.)
		m.wbcData = IIF(found(), data, "")
		set exact &wbcExact

		USE IN wbcRsc
		SELECT (m.wbiSelect)

		RETURN m.wbcData
	ENDPROC
	
	PROCEDURE WBPutRegPref
	* ----------------------------------------------------------------------------
	* Updates the registration preference entry in the resource file.
	* ----------------------------------------------------------------------------

		PARAMETERS m.wbcPrefType, m.wbcPrefID, m.wbcPrefName, m.wblReadonly, m.wbcData

		PRIVATE m.wbcPrefType, m.wbcPrefID, m.wbcPrefName, m.wblReadonly, m.wbcData, ;
				m.wbiSelect, m.wbcOnError, m.wblError, m.wbcExact

		IF set("resource") = "OFF"
			RETURN .f.
		ENDIF
		IF empty(m.wbcPrefType) and empty(m.wbcPrefID) and empty(m.wbcPrefName)
			RETURN .f.
		ENDIF

		m.wbcPrefType = IIF(empty(m.wbcPrefType), "", m.wbcPrefType)
		m.wbcPrefID = IIF(empty(m.wbcPrefID), "", m.wbcPrefID)
		m.wbcPrefName = IIF(empty(m.wbcPrefName), "", m.wbcPrefName)
		m.wbcData = IIF(empty(m.wbcData), "", m.wbcData)
		m.wbcErrorMsg = C_RSCERROR_LOC + CHR(13) + CHR(13) + SYS(2005)

		m.wbiSelect = SELECT()
		SELECT 0
		m.wbcOnError = ON("error")
		m.wblError = .f.
		ON ERROR m.wblError = .t.
		USE SYS(2005) AGAIN ALIAS wbcRsc SHARED
		IF m.wblError
			m.wblError = .f.
			= THIS.WBAlert(m.wbcErrMsg)
			IF m.wblError
				= MESSAGEBOX(m.wbcErrorMsg)
			ELSE
				m.wblError = .t.
			ENDIF
		ENDIF
		IF ISREADONLY()
			USE IN wbcRsc
			m.wblError = .t.
		ENDIF
		IF m.wblError
			ON ERROR &wbcOnError
			SELECT (m.wbiSelect)
			RETURN .f.
		ELSE
			= THIS.WBAddArea(ALIAS())	
		ENDIF

		m.wbcExact = set("exact")
		SET EXACT ON
		LOCATE FOR IIF(!empty(m.wbcPrefType), type = m.wbcPrefType, .t.) ;
			AND IIF(!empty(m.wbcPrefID), id = m.wbcPrefID, .t.) ;
			AND IIF(!empty(m.wbcPrefName), name = m.wbcPrefName, .t.)
			   
		IF FOUND()
			REPLACE readonly WITH m.wblReadonly,  ;
					ckval WITH VAL(SYS(2007, m.wbcData)),  ;
					data WITH m.wbcData,  ;
					updated WITH date()
		ELSE
			APPEND BLANK
			REPLACE type WITH m.wbcPrefType,  ;
					id WITH m.wbcPrefID,  ;
					name WITH m.wbcPrefName,  ;
					readonly WITH m.wblReadonly,  ;
					ckval WITH VAL(SYS(2007, m.wbcData)),  ;
					data WITH m.wbcData,  ;
					updated WITH date()
		ENDIF
		SET EXACT &wbcExact
		ON ERROR &wbcOnError

		USE IN wbcRsc
		SELECT (m.wbiSelect)

		RETURN !m.wblError
		
	ENDPROC
	
	PROCEDURE WBAddArea
	* ----------------------------------------------------------------------------
	* Whenever we SELECT 0 to use a table, record that work area in the wbaAreas[]
	* array. Procedure WBSetEnvironment issues a USE in all such work areas on the 
	* way out. Tables originally in use should not be affected by this app, and
	* tables opened by this app should be closed.
	* ----------------------------------------------------------------------------

		PARAMETER wbiAlias

		PRIVATE m.wbiAlias

		IF ASCAN(THIS.wbaAreas, m.wbiAlias) = 0
			IF NOT EMPTY(THIS.wbaAreas[1])
				DIMENSION THIS.wbaAreas[ALEN(THIS.wbaAreas, 1) + 1]
			ENDIF
			THIS.wbaAreas[ALEN(THIS.wbaAreas, 1)] = m.wbiAlias
		ENDIF

	ENDPROC
	
	PROCEDURE WBNameSelect
	* ----------------------------------------------------------------------------
	* Presents a form with a picklist of relevant entries for the user to 
	* select from, using the wbaAllData[] array for the list. The form called 
	* here should be based on the wizard or builder base class. Returns the row 
	* number in wbaAllData[], or 0 IF user cancels. 
	* ----------------------------------------------------------------------------

		PRIVATE m.wbiPicked, m.wbi, m.wbarrlen

		m.wbiPicked = 1

		IF NOT "WBPICK" $ UPPER(SET("CLASSLIB"))
			SET CLASSLIB TO wbpick ADDITIVE
		ENDIF
		oPick = CREATEOBJECT("wbpicklist")
		oPick.SHOW
		
		RELEASE oPick
		RELEASE CLASS wbpick
		
		IF TYPE("wbipicked") <> "N"
			m.wbipicked = 0
		ENDIF
				
		RETURN m.wbiPicked

	ENDPROC
	
	PROCEDURE WBHelp
	* ----------------------------------------------------------------------------
	* Custom help for wizards/builders.
	* ----------------------------------------------------------------------------
	
		= THIS.WBAlert("Help is not yet implemented.")
	
	ENDPROC
	
	PROCEDURE Error
	* ----------------------------------------------------------------------------
	* Error handler for wizard/builder object (created by wbmain.prg).
	* ----------------------------------------------------------------------------

		PARAMETERS m.wbcNum, m.wbcMethod, m.wbcLine

		PRIVATE m.wbcMsg, m.wbcMsg1, m.wbcProgram, m.wbcAlertMsg, m.wbiAction
		LOCAL lcErrorMsg,lcCodeLineMsg
	
		IF C_DEBUG

			lcErrorMsg=MESSAGE()+CHR(13)+CHR(13)+'Builder:   '+this.Name+CHR(13)
			lcErrorMsg=lcErrorMsg+'Method:    '+m.wbcMethod
			lcCodeLineMsg=MESSAGE(1)
			IF BETWEEN(m.wbcLine,1,10000) AND NOT lcCodeLineMsg='...'
				lcErrorMsg=lcErrorMsg+CHR(13)+'Line:  '+ALLTRIM(STR(m.wbcLine))
				IF NOT EMPTY(lcCodeLineMsg)
					lcErrorMsg=lcErrorMsg+CHR(13)+CHR(13)+lcCodeLineMsg
				ENDIF
			ENDIF
			WAIT CLEAR
			WAIT WINDOW lcErrorMsg NOWAIT

			m.wbcAlertMsg = alltrim(MESSAGE()) + CHR(13) + CHR(13) + ;
				C_PRG_LOC + alltrim(m.wbcMethod) + CHR(13) + ;
				C_MSG1_LOC + "(" + alltrim(str(m.wbcLine)) + ") " + MESSAGE(1) + CHR(13)

			m.wbiAction = THIS.WBAlert(m.wbcAlertMsg, MB_ICONEXCLAMATION + MB_ABORTRETRYIGNORE)
			DO CASE
				CASE m.wbiAction = MB_RET_RETRY
					set step on
					retry
				CASE m.wbiAction = MB_RET_IGNORE
					RETURN
				OTHERWISE
					CLEAR PROG
					RETURN TO MASTER
			ENDCASE
		ELSE
			m.wbcAlertMsg = C_ERRGENERIC_LOC + UPPER(m.wbcMethod)
			= THIS.WBAlert(m.wbcAlertMsg, MB_ICONEXCLAMATION + MB_OK)
			RETURN TO MASTER
		ENDIF

	ENDPROC

	PROCEDURE WBAlert
	* ----------------------------------------------------------------------------
	* Display procedure for error messages. This is called by the error
	* routine, which can also be invoked by wizards and builders.
	* ----------------------------------------------------------------------------

		PARAMETERS m.wbcMessage, m.wbcOpts, m.wbcTitle
		
		PRIVATE m.wbcOpts, m.wbcResponse, m.wbcTitle, m.wbcOldError

		m.wbcOpts=IIF(empty(m.wbcOpts), MB_OK, m.wbcOpts)
		IF NOT EMPTY(m.wbcTitle)
			m.wbcResponse = MessageBox(m.wbcMessage, m.wbcOpts, m.wbcTitle)
		ELSE
			m.wbcResponse = MessageBox(m.wbcMessage, m.wbcOpts, THIS.wbcAlertTitle)
		ENDIF
		
		RETURN m.wbcResponse

	ENDPROC
	
ENDDEFINE
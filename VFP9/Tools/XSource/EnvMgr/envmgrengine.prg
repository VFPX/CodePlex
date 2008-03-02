#include "foxpro.h"
#include "envmgr.h"
#include "..\ffc\registry.h"


DEFINE CLASS EnvMgrEngine AS Session

	EnvMgrDir       = HOME(7)
	EnvMgrTable     = "envmgr.dbf"

	* used to keep track of our environment
	cTalk           = ''
	nLangOpt        = 0
	cEscapeState    = ''
	cSYS3054        = ''
	cSaveUDFParms   = ''
	cSaveLib        = ''
	cExclusive      = ''
	cCompatible     = ''

	lInitError      = .F.

	* collection of available options
	OptionCollection  = .NULL.
	
	* collection of field type mappings
	FieldMapCollection = .NULL.
	DefaultMapCollection = .NULL.
	
	FieldMapOptions = .NULL.
	DefaultFieldMapOptions = .NULL.

	TemplateInfo = .NULL.
	DefaultTemplateInfo = .NULL.



*!*		TemplateFormSet    = ''
*!*		TemplateFormSetLib = ''
*!*		TemplateForm       = ''
*!*		TemplateFormLib    = ''
*!*		
*!*		IncludeCaptions    = .F.
*!*		IncludeComments    = .F.
*!*		IncludeFormat      = .F.
*!*		IncludeInputMask   = .F.
	
	ResourceFile = ''

	UniqueID   = ''
	SetName    = ''
	SetPath    = ''
	DefaultDir = ''
	BeforeCode = ''
	AfterCode  = ''

	ProjectCollection = .NULL.


	PROCEDURE Init(cTable)
		LOCAL nSelect

		THIS.cTalk = SET("TALK")
		SET TALK OFF
		SET DELETED ON
		SET CENTURY ON

		THIS.cCompatible = SET("COMPATIBLE")
		SET COMPATIBLE OFF

		THIS.cExclusive = SET("EXCLUSIVE")
		SET EXCLUSIVE OFF

		THIS.nLangOpt = _VFP.LanguageOptions
		_VFP.LanguageOptions=0

		THIS.cEscapeState = SET("ESCAPE")
		SET ESCAPE OFF

		THIS.cSYS3054 = SYS(3054)
		SYS(3054,0)

		THIS.cSaveLib      = SET("LIBRARY")

		THIS.cSaveUDFParms = SET("UDFPARMS")
		SET UDFPARMS TO VALUE

		SET EXACT OFF
		SET MULTILOCKS ON

		THIS.RestorePrefs()

		IF !DIRECTORY(THIS.EnvMgrDir, 1)
			THIS.EnvMgrDir = HOME()
		ENDIF
			

		IF VARTYPE(m.cTable) == 'C' AND !EMPTY(m.cTable)
			THIS.EnvMgrDir   = ADDBS(FULLPATH(JUSTPATH(m.cTable)))
			THIS.EnvMgrTable = JUSTFNAME(m.cTable)
		ENDIF

		THIS.OptionCollection     = CREATEOBJECT("Collection")
		THIS.FieldMapCollection   = CREATEOBJECT("Collection")
		THIS.DefaultMapCollection = CREATEOBJECT("Collection")
		THIS.ProjectCollection    = CREATEOBJECT("Collection")

		THIS.FieldMapOptions = CREATEOBJECT("Empty")
		THIS.DefaultFieldMapOptions = CREATEOBJECT("Empty")

		THIS.TemplateInfo         = CREATEOBJECT("Empty")
		THIS.DefaultTemplateInfo  = CREATEOBJECT("Empty")

		THIS.LoadFieldMappings(THIS.FieldMapCollection, THIS.FieldMapOptions, THIS.TemplateInfo)
		THIS.LoadFieldMappings(THIS.DefaultMapCollection, THIS.DefaultFieldMapOptions, THIS.DefaultTemplateInfo)

		IF !THIS.OpenEnvMgr()
			THIS.lInitError = .T.
		ELSE
			IF !THIS.DefaultMappingsDefined()
				THIS.CreateDefaultFieldMappings()
			ENDIF

			THIS.UniqueID    = "CURRENT"
			THIS.SetName     = ''
			THIS.SetPath     = SET("PATH")
			THIS.DefaultDir  = SYS(5) + CURDIR()
			THIS.BeforeCode  = ''
			THIS.AfterCode   = ''
			
			THIS.SaveEnv()
		ENDIF
	ENDPROC

	FUNCTION Destroy()
		LOCAL cCompatible

		IF THIS.cEscapeState = "ON"
			SET ESCAPE ON
		ENDIF
		IF THIS.cExclusive = "ON"
			SET EXCLUSIVE ON
		ENDIF
		SYS(3054,INT(VAL(THIS.cSYS3054)))

		_VFP.LanguageOptions = THIS.nLangOpt

		IF THIS.cSaveUDFParms = "REFERENCE"
			SET UDFPARMS TO REFERENCE
		ENDIF

		m.cCompatible = THIS.cCompatible
		SET COMPATIBLE &cCompatible

		IF THIS.cTalk == "ON"
			SET TALK ON
		ENDIF
	ENDFUNC


	FUNCTION GetFieldMapRegPath()
		RETURN "Software\Microsoft\VisualFoxPro\" + TRANSFORM(VERSION(5)/100) + ".0\Options\IntelliDrop\FieldTypes"
	ENDFUNC

	FUNCTION GetIntelliDropRegPath()
		RETURN "Software\Microsoft\VisualFoxPro\" + TRANSFORM(VERSION(5)/100) + ".0\Options\IntelliDrop"
	ENDFUNC

	FUNCTION GetTemplateRegPath()
		RETURN "Software\Microsoft\VisualFoxPro\" + TRANSFORM(VERSION(5)/100) + ".0\Options"
	ENDFUNC


	* Load field mappings and templates from the registry
	FUNCTION LoadFieldMappings(oCollection, oFieldMapOptions, oTemplateInfo)
		LOCAL oReg
		LOCAL oMapping
		LOCAL cRegPath
		LOCAL o
		LOCAL cValue
		LOCAL cClassName
		LOCAL cClassLib
		LOCAL ARRAY aFieldTypes[1]
		

		m.oReg = NEWOBJECT("Registry", HOME() + "ffc\registry.vcx") && from FFC
		IF VARTYPE(oCollection) == 'O'
			m.oCollection.Remove(-1)
			
			m.cRegPath = THIS.GetFieldMapRegPath()
			IF m.oReg.OpenKey(m.cRegPath, HKEY_CURRENT_USER) == ERROR_SUCCESS
				m.oReg.EnumKeys(@aFieldTypes)
				m.oReg.CloseKey()
			ENDIF
			
			* nothing in registry yet, probably because this is a new install
			* and user hasn't gone into Options dialog yet
			IF TYPE("aFieldTypes[1]") <> 'C'
				DIMENSION aFieldTypes[19]
				aFieldTypes[1]  = "Blob"
				aFieldTypes[2]  = "Character"
				aFieldTypes[3]  = "Character (binary)"
				aFieldTypes[4]  = "Currency"
				aFieldTypes[5]  = "Date"
				aFieldTypes[6]  = "DateTime"
				aFieldTypes[7]  = "Double"
				aFieldTypes[8]  = "Float"
				aFieldTypes[9]  = "General"
				aFieldTypes[10] = "Integer"
				aFieldTypes[11] = "Label"
				aFieldTypes[12] = "Logical"
				aFieldTypes[13] = "Memo"
				aFieldTypes[14] = "Memo (binary)"
				aFieldTypes[15] = "Multiple"
				aFieldTypes[16] = "Numeric"
				aFieldTypes[17] = "Varbinary"
				aFieldTypes[18] = "Varchar"
				aFieldTypes[19] = "Varchar (binary)"
			ENDIF



			m.cValue = ''
			m.nCnt = ALEN(aFieldTypes, 1)
			FOR m.i = 1 TO m.nCnt
				m.o = CREATEOBJECT("Empty")
				AddProperty(m.o, "FieldType", aFieldTypes[m.i])
				AddProperty(m.o, "ClassName", '')
				AddProperty(m.o, "ClassLocation", '')
				AddProperty(m.o, "DefaultClassName", '')
				AddProperty(m.o, "DefaultClassLocation", '')
				
				IF oReg.GetRegKey("ClassName", @cValue, m.cRegPath + '\' + aFieldTypes[i], HKEY_CURRENT_USER) == 0
					o.ClassName = m.cValue
					o.DefaultClassName = m.cValue
				ENDIF
				IF oReg.GetRegKey("ClassLocation", @cValue, m.cRegPath + '\' + aFieldTypes[i], HKEY_CURRENT_USER) == 0
					o.ClassLocation = m.cValue
					o.DefaultClassLocation = m.cValue
				ENDIF
				m.oCollection.Add(m.o)
			ENDFOR
		ENDIF

		IF VARTYPE(oFieldMapOptions) == 'O'
			AddProperty(oFieldMapOptions, "IncludeCaptions", .F.)
			AddProperty(oFieldMapOptions, "IncludeComments", .F.)
			AddProperty(oFieldMapOptions, "IncludeFormat", .F.)
			AddProperty(oFieldMapOptions, "IncludeInputMask", .F.)

			m.cRegPath = THIS.GetIntelliDropRegPath()
			IF m.oReg.OpenKey(m.cRegPath, HKEY_CURRENT_USER) == ERROR_SUCCESS
				oFieldMapOptions.IncludeCaptions  = THIS.ReadRegistryDWORD(m.oReg.nCurrentKey, "IncludeCaptions") <> 0
				oFieldMapOptions.IncludeComments  = THIS.ReadRegistryDWORD(m.oReg.nCurrentKey, "IncludeComments") <> 0
				oFieldMapOptions.IncludeFormat    = THIS.ReadRegistryDWORD(m.oReg.nCurrentKey, "IncludeFormat") <> 0
				oFieldMapOptions.IncludeInputMask = THIS.ReadRegistryDWORD(m.oReg.nCurrentKey, "IncludeInputMask") <> 0
				
				m.oReg.CloseKey()
			ENDIF
		ENDIF
		
		* load IntelliDrop options
		IF VARTYPE(oTemplateInfo) == 'O'
			AddProperty(oTemplateInfo, "Form", '')
			AddProperty(oTemplateInfo, "FormLib", '')

			AddProperty(oTemplateInfo, "FormSet", '')
			AddProperty(oTemplateInfo, "FormSetLib", '')

			* load template classes
			m.cRegPath = THIS.GetTemplateRegPath()
			IF m.oReg.OpenKey(m.cRegPath, HKEY_CURRENT_USER) == ERROR_SUCCESS
				m.cClassName = ''
				m.cClassLib = ''
				IF m.oReg.GetKeyValue("FormsClass", @cClassName) == 0 AND m.oReg.GetKeyValue("FormsLib", @cClassLib) == 0
					oTemplateInfo.Form    = m.cClassName
					oTemplateInfo.FormLib = m.cClassLib
				ENDIF

				m.cClassName = ''
				m.cClassLib = ''
				IF m.oReg.GetKeyValue("FormSetClass", @cClassName) == 0 AND m.oReg.GetKeyValue("FormSetLib", @cClassLib) == 0
					oTemplateInfo.FormSet    = m.cClassName
					oTemplateInfo.FormSetLib = m.cClassLib
				ENDIF

				m.oReg.CloseKey()
			ENDIF
			
			
		ENDIF
		
		RETURN .T.
	ENDFUNC
	
	FUNCTION SetFieldMappings(oCollection)
		LOCAL cRegPath
		LOCAL oReg
		LOCAL i
		LOCAL cClassLoc
		LOCAL cClassName

		IF VARTYPE(m.oCollection) <> 'O'
			m.oCollection = THIS.FieldMapCollection
		ENDIF
		
		m.cRegPath = THIS.GetFieldMapRegPath()
		m.oReg = NEWOBJECT("Registry", HOME() + "ffc\registry.vcx") && from FFC
		FOR m.i = 1 TO m.oCollection.Count
			m.cClassLoc  = m.oCollection.Item(m.i).ClassLocation
			m.cClassName = m.oCollection.Item(m.i).ClassName

			oReg.SetRegKey("ClassLocation", m.cClassLoc, m.cRegPath + '\' + m.oCollection.Item(m.i).FieldType, HKEY_CURRENT_USER, .T.)
			oReg.SetRegKey("ClassName", m.cClassName, m.cRegPath + '\' + m.oCollection.Item(m.i).FieldType, HKEY_CURRENT_USER, .T.)
		ENDFOR

		m.cRegPath = THIS.GetIntelliDropRegPath()
		IF m.oReg.OpenKey(m.cRegPath, HKEY_CURRENT_USER) == ERROR_SUCCESS
			THIS.WriteRegistryDWORD(m.oReg.nCurrentKey, "IncludeCaptions", THIS.FieldMapOptions.IncludeCaptions)
			THIS.WriteRegistryDWORD(m.oReg.nCurrentKey, "IncludeComments", THIS.FieldMapOptions.IncludeComments)
			THIS.WriteRegistryDWORD(m.oReg.nCurrentKey, "IncludeFormat", THIS.FieldMapOptions.IncludeFormat)
			THIS.WriteRegistryDWORD(m.oReg.nCurrentKey, "IncludeInputMask", THIS.FieldMapOptions.IncludeInputMask)
			
			m.oReg.CloseKey()
		ENDIF


		THIS.WriteTemplateInfoToRegistry(THIS.TemplateInfo, .F.)
		
		
		IF !EMPTY(THIS.TemplateInfo.Form) OR !EMPTY(THIS.TemplateInfo.FormSet)
			SYS(3056, 1)  && re-read from registry
		ENDIF
		
		* reset back to original values
		THIS.WriteTemplateInfoToRegistry(THIS.DefaultTemplateInfo, .T.)
		
		
		RETURN .T.
	ENDFUNC
	
	FUNCTION WriteTemplateInfoToRegistry(oTemplateInfo, lWriteEmpty)
		LOCAL oRegPath
		LOCAL oReg
		
		* write IntelliDrop options
		m.oReg = NEWOBJECT("Registry", HOME() + "ffc\registry.vcx") && from FFC

	
		* Set template classes
		m.cRegPath = THIS.GetTemplateRegPath()
		IF !EMPTY(oTemplateInfo.Form) OR lWriteEmpty
			oReg.SetRegKey("FormsClass", oTemplateInfo.Form, m.cRegPath, HKEY_CURRENT_USER, .T.)
			oReg.SetRegKey("FormsLib", oTemplateInfo.FormLib, m.cRegPath, HKEY_CURRENT_USER, .T.)
		ENDIF

		IF !EMPTY(oTemplateInfo.FormSet) OR lWriteEmpty
			oReg.SetRegKey("FormSetClass", oTemplateInfo.FormSet, m.cRegPath, HKEY_CURRENT_USER, .T.)
			oReg.SetRegKey("FormSetLib", oTemplateInfo.FormSetLib, m.cRegPath, HKEY_CURRENT_USER, .T.)
		ENDIF
	ENDFUNC

	
	FUNCTION RestorePrefs()
		LOCAL oResource

		m.oResource = NEWOBJECT("FoxResource", "FoxResource.prg")
		m.oResource.Load("ENVMGR")

		THIS.EnvMgrDir = NVL(m.oResource.Get("EnvMgrDir"), THIS.EnvMgrDir)

		m.oResource = .NULL.
	ENDFUNC

	* evaluate and return the path to set
	* [lNoValidation] = TRUE to not check each directory to exist
	FUNCTION GetParsedPath(lNoValidation)
		LOCAL cSetPath
		LOCAL nCnt
		LOCAL i
		LOCAL cEvalPath
		LOCAL oException
		LOCAL ARRAY aParsePath[1]
		
		m.cSetPath = ''
		m.nCnt = ALINES(aParsePath, THIS.SetPath, .T., ';', ',')
		FOR m.i = 1 TO m.nCnt
			* evaluate as expression if surrounded by '(' and ')'
			m.cEvalPath = aParsePath[m.i]
			IF !EMPTY(m.cEvalPath)
				IF LEFT(m.cEvalPath, 1) == '(' AND RIGHT(m.cEvalPath, 1) == ')' 
					TRY
						m.cEvalPath = EVALUATE(m.cEvalPath)
						IF VARTYPE(m.cEvalPath) <> 'C'
							m.cEvalPath = aParsePath[m.i]
						ENDIF
					CATCH TO oException
						m.cEvalPath = aParsePath[m.i]
					ENDTRY
				ENDIF
				IF m.lNoValidation OR DIRECTORY(m.cEvalPath)
					m.cSetPath = m.cSetPath + IIF(EMPTY(m.cSetPath), '', ';') + m.cEvalPath
				ENDIF
			ENDIF
		ENDFOR
		
		RETURN m.cSetPath
	ENDFUNC

	* evaluate and return the default directory
	FUNCTION GetParsedDir()
		LOCAL cDefaultDir
		LOCAL oException

		m.cDefaultDir = THIS.DefaultDir
		IF LEFT(m.cDefaultDir, 1) == '(' AND RIGHT(m.cDefaultDir, 1) == ')' 
			TRY
				m.cDefaultDir = EVALUATE(m.cDefaultDir)
				IF VARTYPE(m.cDefaultDir) <> 'C'
					m.cDefaultDir = THIS.DefaultDir
				ENDIF
			CATCH TO oException
				m.cDefaultDir = THIS.DefaultDir
			ENDTRY
		ENDIF
		
		RETURN m.cDefaultDir	
	ENDFUNC

	FUNCTION OpenEnvMgr(cAlias)
		LOCAL oException
		LOCAL cTableName
		LOCAL lSuccess
		LOCAL nSelect
		LOCAL ARRAY aFileList[1]

		m.nSelect = SELECT()

		m.cTableName = THIS.EnvMgrTable

		IF VARTYPE(m.cAlias) <> 'C' OR EMPTY(m.cAlias)
			m.cAlias = JUSTSTEM(m.cTableName)
		ENDIF
		m.cTableName = FORCEEXT(m.cTableName, "dbf")

		IF USED(m.cAlias)
			m.lSuccess = .T.
		ELSE
			IF ADIR(aFileList, THIS.EnvMgrDir + m.cTableName) <> 0 OR THIS.CreateEnvMgrTable(m.cTableName)
				TRY
					USE (THIS.EnvMgrDir + m.cTableName) ALIAS (m.cAlias) IN 0 SHARED AGAIN
					CURSORSETPROP("Buffering", 5, m.cAlias)
					m.lSuccess = .T.

				CATCH TO oException
					MESSAGEBOX(oException.Message, MB_ICONSTOP, ENVMGR_LOC)
				ENDTRY
			ENDIF
			
			IF m.lSuccess
				* Create collection of options defined in to the EnvMgr table
				THIS.OptionCollection.Remove(-1)
				
				SELECT EnvMgr
				SCAN ALL FOR EnvType == ENVTYPE_OPTION
					oOptionDef = CREATEOBJECT("OptionDef")
					WITH oOptionDef
						.UniqueID     = RTRIM(EnvMgr.UniqueID)
						.OptionName   = RTRIM(EnvMgr.SetName)
						.OptionValues = EnvMgr.SetValues
						.GetCode      = EnvMgr.BeforeCode
						.SetCode      = EnvMgr.AfterCode
					ENDWITH
					THIS.OptionCollection.Add(oOptionDef)
				ENDSCAN
			ENDIF
		ENDIF
		
		SELECT (m.nSelect)

		RETURN m.lSuccess
	ENDFUNC

	
	FUNCTION CreateEnvMgrTable(m.cTableName)
		LOCAL oException
		LOCAL lSuccess
		LOCAL cSafety
		LOCAL ARRAY aFileList[1]

		m.cSafety = SET("SAFETY")
		SET SAFETY OFF
		
		IF VARTYPE(m.cTableName) <> 'C' OR EMPTY(m.cTableName)
			m.cTableName = THIS.EnvMgrTable
		ENDIF
	
		m.lSuccess = .F.
		IF ADIR(aFileList, THIS.EnvMgrDir + m.cTableName) <> 0
			MESSAGEBOX(FILE_EXISTS_LOC, MB_ICONSTOP, ENVMGR_LOC)
		ELSE
			TRY
				USE EnvMgrDefault IN 0 SHARED AGAIN
				SELECT EnvMgrDefault
				COPY TO (THIS.EnvMgrDir + m.cTableName)
				USE IN EnvMgrDefault

				m.lSuccess = .T.

			CATCH TO oException
				MESSAGEBOX(oException.Message, MB_ICONSTOP, ENVMGR_LOC)
			ENDTRY
		ENDIF

		SET SAFETY &cSafety
		
		RETURN m.lSuccess
	ENDFUNC
	
	* Return .T. if the default field mappings have been
	* saved in the EnvMgr table.
	FUNCTION DefaultMappingsDefined()
		LOCAL lDefined
		LOCAL ARRAY aEnv[1]
		
		SELECT UniqueID ;
		 FROM EnvMgr ;
		 WHERE EnvType == ENVTYPE_DEFAULTFIELDMAP ;
		 INTO ARRAY aEnv
		m.lDefined = (_TALLY > 0)
		
		RETURN m.lDefined
	ENDFUNC


	FUNCTION ApplyFieldMappings(cSetValues)
		LOCAL nSelect
		LOCAL nCnt
		LOCAL i
		LOCAL cOptionID
		LOCAL j
		LOCAL oRef
		LOCAL cFldMapping
		LOCAL cClassName
		LOCAL cClassLib
		LOCAL ARRAY aSetList[1]
		
		nSelect = SELECT()
	
		m.nCnt = ALINES(aSetList, STRTRAN(cSetValues, CHR(13), CHR(10)), .T., CHR(10))
		FOR m.i = 1 TO m.nCnt
			m.cOptionID = GETWORDNUM(aSetList[m.i], 1, '=')
			IF !EMPTY(m.cOptionID)
				DO CASE
				CASE LEFT(m.cOptionID, 1) == '*' && field mappings begin with *
					m.cOptionID = SUBSTR(m.cOptionID, 2)
					FOR m.j = 1 TO THIS.FieldMapCollection.Count
						IF THIS.FieldMapCollection.Item(m.j).FieldType == m.cOptionID
							m.oRef = THIS.FieldMapCollection.Item(m.j)

							m.cFldMapping = GETWORDNUM(aSetList[m.i], 2, '=')
							
							IF AT('<', cFldMapping) == 0
								m.oRef.ClassName = cFldMapping
								m.oRef.ClassLocation = ''
							ELSE
								m.oRef.ClassName = LEFT(m.cFldMapping, RAT('<', m.cFldMapping) - 1)
								m.oRef.ClassLocation = SUBSTR(m.cFldMapping, RAT('<', m.cFldMapping) + 1)
								m.oRef.ClassLocation = LEFT(m.oRef.ClassLocation, LEN(m.oRef.ClassLocation) - 1)
							ENDIF
							EXIT
						ENDIF
					ENDFOR

				CASE m.cOptionID == '^ResourceFile'
					THIS.ResourceFile = GETWORDNUM(aSetList[m.i], 2, '=')

				CASE m.cOptionID == '^IncludeCaptions'
					THIS.FieldMapOptions.IncludeCaptions = GETWORDNUM(aSetList[m.i], 2, '=') == '1'

				CASE m.cOptionID == '^IncludeComments'
					THIS.FieldMapOptions.IncludeComments = GETWORDNUM(aSetList[m.i], 2, '=') == '1'

				CASE m.cOptionID == '^IncludeFormat'
					THIS.FieldMapOptions.IncludeFormat = GETWORDNUM(aSetList[m.i], 2, '=') == '1'

				CASE m.cOptionID == '^IncludeInputMask'
					THIS.FieldMapOptions.IncludeInputMask = GETWORDNUM(aSetList[m.i], 2, '=') == '1'

				CASE m.cOptionID == '^FormSetTemplate'
					m.cFldMapping = GETWORDNUM(aSetList[m.i], 2, '=')
					IF AT('<', cFldMapping) <> 0
						m.cClassName = LEFT(m.cFldMapping, RAT('<', m.cFldMapping) - 1)
						m.cClassLib  = STREXTRACT(m.cFldMapping, '<', '>')
						
						IF !EMPTY(m.cClassName) AND !EMPTY(m.cClassLib)
							THIS.TemplateInfo.FormSet = m.cClassName
							THIS.TemplateInfo.FormSetLib = m.cClassLib
						ENDIF
					ENDIF
					
				CASE m.cOptionID == '^FormTemplate'
					m.cFldMapping = GETWORDNUM(aSetList[m.i], 2, '=')
					IF AT('<', cFldMapping) <> 0
						m.cClassName = LEFT(m.cFldMapping, RAT('<', m.cFldMapping) - 1)
						m.cClassLib  = STREXTRACT(m.cFldMapping, '<', '>')
						
						IF !EMPTY(m.cClassName) AND !EMPTY(m.cClassLib)
							THIS.TemplateInfo.Form    = m.cClassName
							THIS.TemplateInfo.FormLib = m.cClassLib
						ENDIF
					ENDIF

				OTHERWISE
					m.cOptionID = UPPER(m.cOptionID)
					FOR m.j = 1 TO THIS.OptionCollection.Count
						IF THIS.OptionCollection.Item(m.j).UniqueID == m.cOptionID
							m.oRef = THIS.OptionCollection.Item(m.j)
							m.oRef.ActualValue = GETWORDNUM(aSetList[m.i], 2, '=')
							EXIT
						ENDIF
					ENDFOR
				ENDCASE
			ENDIF
		ENDFOR
		
		SELECT (nSelect)
	ENDFUNC
		
	* If a default field mappings are set, apply those to the current set
	FUNCTION ApplyDefaultFieldMappings()
		LOCAL nSelect
		LOCAL ARRAY aEnv[1]
		
		nSelect = SELECT()

		SELECT SetValues ;
		 FROM EnvMgr WITH (Buffering = .T.) ;
		 WHERE EnvType == ENVTYPE_DEFAULTFIELDMAP ;
		 INTO ARRAY aEnv
		IF _TALLY > 0
			THIS.ApplyFieldMappings(aEnv[1, 1])
		ENDIF
	
	
		SELECT (nSelect)
	ENDFUNC
	
	* Save our default field mappings to its own
	* record in the EnvMgr table.
	FUNCTION CreateDefaultFieldMappings()
		LOCAL nSelect
		LOCAL lNew
		LOCAL cSetValues
		LOCAL lFound
		LOCAL i
		LOCAL nRecNo

		m.nSelect = SELECT()
		
		SELECT EnvMgr
		m.nRecNo = IIF(EOF() OR BOF(), 0, RECNO())

		m.cSetValues = ''
		FOR m.i = 1 TO THIS.DefaultMapCollection.Count
			m.cSetValues = m.cSetValues + IIF(EMPTY(m.cSetValues), '', CHR(10)) + '*' + THIS.DefaultMapCollection.Item(m.i).FieldType + "=" + THIS.DefaultMapCollection.Item(m.i).ClassName + IIF(EMPTY(THIS.DefaultMapCollection.Item(m.i).ClassLocation), '', '<' + ALLTRIM(THIS.DefaultMapCollection.Item(m.i).ClassLocation) + '>')
		ENDFOR

		m.cSetValues = m.cSetValues + IIF(EMPTY(m.cSetValues), '', CHR(10)) + "^FormSetTemplate=" + THIS.DefaultTemplateInfo.FormSet + IIF(EMPTY(THIS.DefaultTemplateInfo.FormSetLib), '', '<' + THIS.DefaultTemplateInfo.FormSetLib + '>')
		m.cSetValues = m.cSetValues + IIF(EMPTY(m.cSetValues), '', CHR(10)) + "^FormTemplate=" + THIS.DefaultTemplateInfo.Form + IIF(EMPTY(THIS.DefaultTemplateInfo.FormLib), '', '<' + THIS.DefaultTemplateInfo.FormLib + '>')
		m.cSetValues = m.cSetValues + IIF(EMPTY(m.cSetValues), '', CHR(10)) + "^IncludeCaptions=" + IIF(THIS.DefaultFieldMapOptions.IncludeCaptions, '1', '0')
		m.cSetValues = m.cSetValues + IIF(EMPTY(m.cSetValues), '', CHR(10)) + "^IncludeComments=" + IIF(THIS.DefaultFieldMapOptions.IncludeComments, '1', '0')
		m.cSetValues = m.cSetValues + IIF(EMPTY(m.cSetValues), '', CHR(10)) + "^IncludeFormat=" + IIF(THIS.DefaultFieldMapOptions.IncludeFormat, '1', '0')
		m.cSetValues = m.cSetValues + IIF(EMPTY(m.cSetValues), '', CHR(10)) + "^IncludeInputMask=" + IIF(THIS.DefaultFieldMapOptions.IncludeInputMask, '1', '0')

		LOCATE FOR EnvType == ENVTYPE_DEFAULTFIELDMAP
		m.lNew = !FOUND()
		IF m.lNew
			APPEND BLANK IN EnvMgr
			REPLACE ;
			  UniqueID WITH "FIELDMAP", ;
			  EnvType WITH ENVTYPE_DEFAULTFIELDMAP, ;
			  MenuIncl WITH .F., ;
			  ParentID WITH '' ;
			 IN EnvMgr
		ENDIF

		REPLACE ;
		  SetValues WITH m.cSetValues, ;
		  Modified WITH DATETIME() ;
		 IN EnvMgr

	
		IF m.nRecNo <> 0
			GOTO (m.nRecNo) IN EnvMgr
		ENDIF
		
		SELECT (m.nSelect)
	ENDFUNC


	FUNCTION SetEnv(cUniqueID, lQuiet)
		LOCAL oException
		LOCAL lSuccess
		LOCAL cSetPath
		LOCAL cProjName
		LOCAL cProjectFile
		LOCAL nDataSessionID
		LOCAL nCnt
		LOCAL i
		LOCAL nSelect
		LOCAL cDefaultDir
		LOCAL cTalk
		LOCAL lFound
		LOCAL cRegPath
		LOCAL oReg
		LOCAL cClassName
		LOCAL cClassLoc
		LOCAL cResourceFile
		LOCAL aFileList[1]

		m.nSelect = SELECT()


		m.cProjectFile = ''
		IF VARTYPE(m.cUniqueID) == 'C' AND !EMPTY(m.cUniqueID)
			SELECT EnvMgr

			* search by the UniqueID
			LOCATE FOR UniqueID == PADR(m.cUniqueID, LEN(EnvMgr.UniqueID)) AND EnvType == ENVTYPE_PROJECT
			m.lFound = FOUND()
			IF !m.lFound
				* search by name
				LOCATE FOR ALLTRIM(UPPER(SetName)) == ALLTRIM(UPPER(m.cUniqueID)) AND EnvType == ENVTYPE_PROJECT
				m.lFound = FOUND()
			ENDIF
			
			IF m.lFound
				m.cProjectFile = EnvMgr.SetPath
				m.cUniqueID = EnvMgr.ParentID
			ENDIF

			IF RTRIM(THIS.UniqueID) == RTRIM(m.cUniqueID)
				m.lSuccess = .T.
			ELSE
				m.lSuccess = THIS.LoadEnv(m.cUniqueID)
			ENDIF
		ELSE
			m.lSuccess = .T.
		ENDIF
		
		IF m.lSuccess
			m.nDataSessionID = THIS.DataSessionID
			SET DATASESSION TO 1
			SET CONSOLE OFF
			m.cNewTalkSetting = SET("TALK")
			SET CONSOLE ON
			SET TALK OFF

			IF !EMPTY(THIS.BeforeCode)
				TRY
					EXECSCRIPT(THIS.BeforeCode)
				CATCH TO oException
					MESSAGEBOX(ERROR_RUNBEFORECODE_LOC + CHR(10) + CHR(10) + oException.Message, MB_ICONEXCLAMATION, ENVMGR_LOC)
				ENDTRY
			ENDIF

			* set field mappings
			THIS.SetFieldMappings()


			* set the resource file
			IF !EMPTY(THIS.ResourceFile)
				cResourceFile = FULLPATH(THIS.ResourceFile)
				IF ADIR(aFileList, DEFAULTEXT(cResourceFile, "dbf"), "HS") == 0
					IF MESSAGEBOX(cResourceFile + CHR(10) + CHR(10) + ERROR_NORESOURCEFILE_LOC, MB_ICONQUESTION + MB_YESNO, ENVMGR_LOC) == IDYES
						TRY
							CREATE TABLE (cResourceFile) FREE ; 
							 (Type C(12), ;
							  ID C(12), ;
							  Name M, ;
							  ReadOnly L, ;
							  CkVal N(6,0), ;
							  Data M, ;
							  Updated D ;
							 )
							USE

						CATCH TO oException
							cResourceFile = ''
							MESSAGEBOX(oException.Message, MB_ICONSTOP, ENVMGR_LOC)
						ENDTRY
					ELSE
						cResourceFile = ''
					ENDIF
				ENDIF
				IF !EMPTY(cResourceFile)
					TRY
						SET RESOURCE TO (cResourceFile)
					CATCH TO oException
						MESSAGEBOX(oException.Message, MB_ICONSTOP, ENVMGR_LOC)
					ENDTRY
				ENDIF
			ENDIF

		

			* evaluate as expression if surrounded by '(' and ')'
			m.cDefaultDir = THIS.GetParsedDir()
			IF !EMPTY(m.cDefaultDir)
				IF DIRECTORY(m.cDefaultDir)
					TRY
						CD (m.cDefaultDir)
					CATCH TO oException
						MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, ENVMGR_LOC)
					ENDTRY
				ELSE
					MESSAGEBOX(DEFAULTDIR_NOTFOUND_LOC + CHR(10) + CHR(10) + m.cDefaultDir, MB_ICONEXCLAMATION, ENVMGR_LOC)
				ENDIF
			ENDIF


			IF !EMPTY(THIS.SetPath)
				m.cSetPath = THIS.GetParsedPath()

				IF !EMPTY(m.cSetPath)
					TRY
						SET PATH TO &cSetPath
					CATCH TO oException
						MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, ENVMGR_LOC)
					ENDTRY
				ENDIF
			ENDIF


			FOR m.i = 1 TO THIS.OptionCollection.Count
				IF !EMPTY(THIS.OptionCollection.Item(m.i).ActualValue) AND !EMPTY(THIS.OptionCollection.Item(m.i).SetCode)
					TRY
						EXECSCRIPT(THIS.OptionCollection.Item(m.i).SetCode, THIS.OptionCollection.Item(m.i).ActualValue)
						SET CONSOLE OFF
						m.cNewTalkSetting = SET("TALK")
						SET CONSOLE ON
						SET TALK OFF
					CATCH TO oException
						MESSAGEBOX(m.oException.Message + m.oException.Procedure + "(" + TRANSFORM(m.oException.LineNo) + ")" + CHR(10) + m.oException.LineContents, MB_ICONEXCLAMATION, ENVMGR_LOC)
					ENDTRY
				ENDIF
			ENDFOR


			IF !EMPTY(THIS.AfterCode)
				TRY
					EXECSCRIPT(THIS.AfterCode)
					SET CONSOLE OFF
					m.cNewTalkSetting = SET("TALK")
					SET CONSOLE ON
					SET TALK OFF
				CATCH TO oException
					MESSAGEBOX(ERROR_RUNAFTERCODE_LOC + CHR(10) + CHR(10) + oException.Message, MB_ICONEXCLAMATION, ENVMGR_LOC)
				ENDTRY
			ENDIF
			
			IF EMPTY(m.cProjectFile)
				IF !m.lQuiet
					MESSAGEBOX(STRTRAN(STRTRAN(ENVIRONMENT_SET_LOC, "#defaultdir#", SYS(5) + CURDIR()), "#path#", SET("PATH")), MB_ICONINFORMATION, ENVMGR_LOC)
				ENDIF
			ELSE
				TRY
					MODIFY PROJECT (m.cProjectFile) NOWAIT
				CATCH TO oException
					MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, ENVMGR_LOC)
				ENDTRY
			ENDIF

			SET TALK &cNewTalkSetting

			SET DATASESSION TO (m.nDataSessionID)
		ENDIF
		
		SELECT (m.nSelect)
		
		RETURN m.lSuccess
	ENDFUNC

	
	FUNCTION IsDupeSetName(cSetName)
		LOCAL nSelect
		LOCAL lDupe
		
		nSelect = SELECT()
		
		SELECT EnvMgr
		
		* make sure another environment with the same name doesn't already exist
		LOCATE FOR UPPER(ALLTRIM(SetName)) == UPPER(ALLTRIM(cSetName)) AND !(UniqueID == THIS.UniqueID)
		lDupe = FOUND()
		
		SELECT (nSelect)
		
		RETURN lDupe
	ENDFUNC	

	* Save back to the EnvMgr table
	FUNCTION SaveEnv(lFieldMappingsOnly)
		LOCAL nSelect
		LOCAL lNew
		LOCAL cProject
		LOCAL cSetValues
		LOCAL lFound
		LOCAL i

		m.nSelect = SELECT()

		SELECT EnvMgr
		m.lNew = EMPTY(THIS.UniqueID)

		IF !m.lNew
			LOCATE FOR UniqueID == PADR(THIS.UniqueID, LEN(EnvMgr.UniqueID)) AND (EnvType == ENVTYPE_ENVIRONMENT OR EnvType == ENVTYPE_CURRENT OR EnvType == ENVTYPE_DEFAULTFIELDMAP)
			m.lNew = !FOUND()
		ENDIF

		IF m.lNew
			APPEND BLANK IN EnvMgr
			IF EMPTY(THIS.UniqueID)
				THIS.UniqueID = SYS(2015)
			ENDIF

			DO CASE
			CASE RTRIM(THIS.UniqueID) == "CURRENT"
				REPLACE ;
				  UniqueID WITH THIS.UniqueID, ;
				  EnvType WITH ENVTYPE_CURRENT, ;
				  MenuIncl WITH .F. ;
				 IN EnvMgr

			CASE RTRIM(THIS.UniqueID) == "FIELDMAP"
				REPLACE ;
				  UniqueID WITH THIS.UniqueID, ;
				  EnvType WITH ENVTYPE_DEFAULTFIELDMAP, ;
				  MenuIncl WITH .F. ;
				 IN EnvMgr

			OTHERWISE
				REPLACE ;
				  UniqueID WITH THIS.UniqueID, ;
				  EnvType WITH ENVTYPE_ENVIRONMENT, ;
				  MenuIncl WITH .F. ;
				 IN EnvMgr
			ENDCASE
		ENDIF

		m.cSetValues = ''
		FOR m.i = 1 TO THIS.FieldMapCollection.Count
			m.cSetValues = m.cSetValues + IIF(EMPTY(m.cSetValues), '', CHR(10)) + '*' + THIS.FieldMapCollection.Item(m.i).FieldType + "=" + THIS.FieldMapCollection.Item(m.i).ClassName + IIF(EMPTY(THIS.FieldMapCollection.Item(m.i).ClassLocation), '', '<' + ALLTRIM(THIS.FieldMapCollection.Item(m.i).ClassLocation) + '>')
		ENDFOR

		m.cSetValues = m.cSetValues + IIF(EMPTY(m.cSetValues), '', CHR(10)) + "^FormSetTemplate=" + THIS.TemplateInfo.FormSet + '<' + THIS.TemplateInfo.FormSetLib + '>'
		m.cSetValues = m.cSetValues + IIF(EMPTY(m.cSetValues), '', CHR(10)) + "^FormTemplate=" + THIS.TemplateInfo.Form + '<' + THIS.TemplateInfo.FormLib + '>'
		m.cSetValues = m.cSetValues + IIF(EMPTY(m.cSetValues), '', CHR(10)) + "^IncludeCaptions=" + IIF(THIS.FieldMapOptions.IncludeCaptions, '1', '0')
		m.cSetValues = m.cSetValues + IIF(EMPTY(m.cSetValues), '', CHR(10)) + "^IncludeComments=" + IIF(THIS.FieldMapOptions.IncludeComments, '1', '0')
		m.cSetValues = m.cSetValues + IIF(EMPTY(m.cSetValues), '', CHR(10)) + "^IncludeFormat=" + IIF(THIS.FieldMapOptions.IncludeFormat, '1', '0')
		m.cSetValues = m.cSetValues + IIF(EMPTY(m.cSetValues), '', CHR(10)) + "^IncludeInputMask=" + IIF(THIS.FieldMapOptions.IncludeInputMask, '1', '0')

		m.cSetValues = m.cSetValues + IIF(EMPTY(m.cSetValues), '', CHR(10)) + "^ResourceFile=" + THIS.ResourceFile
		
		IF m.lFieldMappingsOnly
			REPLACE ;
			  SetValues WITH m.cSetValues, ;
			  Modified WITH DATETIME() ;
			 IN EnvMgr
		ELSE
			FOR m.i = 1 TO THIS.OptionCollection.Count
				IF !EMPTY(THIS.OptionCollection.Item(m.i).ActualValue)
					m.cSetValues = m.cSetValues + IIF(EMPTY(m.cSetValues), '', CHR(10)) + ALLTRIM(THIS.OptionCollection.Item(m.i).UniqueID) + "=" + ALLTRIM(THIS.OptionCollection.Item(m.i).ActualValue)
				ENDIF
			ENDFOR
			
			
			REPLACE ;
			  SetName WITH THIS.SetName, ;
			  SetPath WITH THIS.SetPath, ;
			  DefaultDir WITH THIS.DefaultDir, ;
			  BeforeCode WITH THIS.BeforeCode, ;
			  AfterCode WITH THIS.AfterCode, ;
			  ParentID WITH '', ;
			  SetValues WITH m.cSetValues, ;
			  Modified WITH DATETIME() ;
			 IN EnvMgr
						
			* update projects
			SELECT EnvMgr
			IF !m.lNew
				REPLACE ALL ParentID WITH '' FOR ParentID == THIS.UniqueID
			ENDIF
			FOR EACH cProject IN THIS.ProjectCollection
				IF m.lNew
					m.lFound = .F.
				ELSE
					LOCATE FOR (ParentID == THIS.UniqueID OR EMPTY(ParentID)) AND EnvType == ENVTYPE_PROJECT AND LOWER(SetPath) == LOWER(m.cProject)
					m.lFound = FOUND()
				ENDIF
				IF !m.lFound
					APPEND BLANK IN EnvMgr
					REPLACE ;
					  UniqueID WITH SYS(2015), ;
					  EnvType WITH ENVTYPE_PROJECT ;
					 IN EnvMgr
				ENDIF
				REPLACE ;
				  SetName WITH JUSTFNAME(m.cProject), ;
				  SetPath WITH m.cProject, ;
				  DefaultDir WITH '', ;
				  BeforeCode WITH '', ;
				  AfterCode WITH '', ;
				  ParentID WITH THIS.UniqueID, ;
				  SetValues WITH '', ;
				  MenuIncl WITH .F., ;
				  Modified WITH DATETIME() ;
				 IN EnvMgr
			ENDFOR
			DELETE ALL FOR EMPTY(ParentID) AND EnvType == ENVTYPE_PROJECT IN EnvMgr
		ENDIF
		
		SELECT (m.nSelect)
	ENDFUNC

	FUNCTION Revert()
		TABLEREVERT(.T., "EnvMgr")
	ENDFUNC

	FUNCTION Save()
		THIS.SaveEnv()
		IF !TABLEUPDATE(2, .F., "EnvMgr")
			TABLEREVERT(.T., "EnvMgr")
		ENDIF
	ENDFUNC

	* Abstract:
	*   Load the designated environment set.
	*
	* Parameters:
	*	<cUniqueID> = environment set to load
	FUNCTION LoadEnv(cUniqueID)
		LOCAL lSuccess
		LOCAL nSelect
		LOCAL i
		LOCAL j
		LOCAL nCnt
		LOCAL oRef
		LOCAL lFound
		LOCAL ARRAY aProjectList[1]

		m.nSelect = SELECT()

		m.lSuccess = .T.


		IF VARTYPE(m.cUniqueID) <> 'C'
			m.cUniqueID = ''
		ENDIF

		THIS.ProjectCollection.Remove(-1)

		* clear out all environment options
		FOR m.i = 1 TO THIS.OptionCollection.Count
			m.oRef = THIS.OptionCollection.Item(m.i)
			m.oRef.ActualValue = ''				
		ENDFOR

		* reset field mappings to defaults
		FOR m.i = 1 TO THIS.FieldMapCollection.Count
			m.oRef = THIS.FieldMapCollection.Item(m.i)
			m.oRef.ClassName = m.oRef.DefaultClassName
			m.oRef.ClassLocation = m.oRef.DefaultClassLocation
		ENDFOR

		WITH THIS.TemplateInfo
			.FormSet    = ''
			.FormSetLib = ''
			.Form       = ''
			.FormLib    = ''
		ENDWITH
		
		THIS.ResourceFile = ''


		SELECT EnvMgr
		IF !EMPTY(m.cUniqueID)
			LOCATE FOR UniqueID == PADR(m.cUniqueID, LEN(EnvMgr.UniqueID))
			m.lFound = FOUND()
			IF !m.lFound
				* search by name
				LOCATE FOR ALLTRIM(UPPER(SetName)) == ALLTRIM(UPPER(m.cUniqueID))
				m.lFound = FOUND()
			ENDIF
			
			IF m.lFound AND EnvMgr.EnvType == ENVTYPE_PROJECT
				m.cUniqueID = EnvMgr.ParentID
				LOCATE FOR UniqueID == m.cUniqueID
				m.lFound = FOUND()
			ENDIF
		ELSE
			m.lFound = .F.
		ENDIF

		IF m.lFound
			m.lSuccess = .T.

			THIS.UniqueID    = EnvMgr.UniqueID
			THIS.SetName     = RTRIM(EnvMgr.SetName)
			THIS.SetPath     = EnvMgr.SetPath
			THIS.DefaultDir  = EnvMgr.DefaultDir
			THIS.BeforeCode  = EnvMgr.BeforeCode
			THIS.AfterCode   = EnvMgr.AfterCode
			
			THIS.ApplyFieldMappings(EnvMgr.SetValues)
			
						
			* load up all associated projects
			SELECT EnvMgr
			SCAN ALL FOR ParentID == THIS.UniqueID AND EnvType == ENVTYPE_PROJECT
				THIS.ProjectCollection.Add(EnvMgr.SetPath)
			ENDSCAN
		ELSE
			THIS.UniqueID    = ''
			THIS.SetName     = ''
			THIS.SetPath     = SET("PATH")
			THIS.DefaultDir  = SYS(5) + CURDIR()
			THIS.BeforeCode  = ''
			THIS.AfterCode   = ''

			WITH THIS.FieldMapOptions
				.IncludeCaptions    = .F.
				.IncludeComments    = .F.
				.IncludeFormat      = .F.
				.IncludeInputMask   = .F.
			ENDWITH
			
			THIS.ResourceFile = ''

			lSuccess = .F.
		ENDIF
		
		SELECT (m.nSelect)

		RETURN m.lSuccess
	ENDFUNC
	
	
	FUNCTION SetOption(cOptionID, cActualValue)
		LOCAL i
		LOCAL oRef

		m.cOptionID = RTRIM(m.cOptionID)		
		FOR m.i = 1 TO THIS.OptionCollection.Count
			IF THIS.OptionCollection.Item(m.i).UniqueID == m.cOptionID
				m.oRef = THIS.OptionCollection.Item(m.i)
				m.oRef.ActualValue = RTRIM(m.cActualValue)
				EXIT
			ENDIF
		ENDFOR
		
		m.oRef = .NULL.
	ENDFUNC

	FUNCTION SetFieldMap(cFieldType, cClassName, cClassLocation)
		LOCAL i
		LOCAL oRef

		m.cFieldType = RTRIM(m.cFieldType)
		FOR m.i = 1 TO THIS.FieldMapCollection.Count
			IF THIS.FieldMapCollection.Item(m.i).FieldType == m.cFieldType
				m.oRef = THIS.FieldMapCollection.Item(m.i)
				m.oRef.ClassName = RTRIM(m.cClassName)
				m.oRef.ClassLocation = RTRIM(m.cClassLocation)
				EXIT
			ENDIF
		ENDFOR
		
		m.oRef = .NULL.
	ENDFUNC

	* remove all project associations
	* and any associated project hooks
	FUNCTION RemoveProjects()
		THIS.ProjectCollection.Remove(-1)
	ENDFUNC

	FUNCTION GetAllSets()
		LOCAL oSetCollection
		LOCAL nSelect
		
		m.nSelect = SELECT()
		
		oSetCollection = CREATEOBJECT("Collection")
		
		SELECT EnvMgr.SetName, EnvMGr.UniqueID, UPPER(EnvMgr.SetName) AS SortName  ;
		 FROM EnvMgr ;
		 WHERE EnvType == ENVTYPE_ENVIRONMENT ;
		 ORDER BY SortName ;
		 INTO CURSOR EnvMgrCursor
		SCAN ALL
			oSetCollection.Add(RTRIM(EnvMgrCursor.SetName), EnvMgrCursor.UniqueID)
		ENDSCAN
		
		IF USED("EnvMgrCursor")
			USE IN EnvMgrCursor
		ENDIF
		
		SELECT (m.nSelect)
		
		RETURN oSetCollection
	ENDFUNC
	
	* delete an environment set
	FUNCTION DeleteEnv(cUniqueID)
		LOCAL nSelect
		
		m.nSelect = SELECT()

		m.cUniqueID = PADR(m.cUniqueID, LEN(EnvMgr.UniqueID))

		SELECT EnvMgr
		DELETE ALL FOR UniqueID == m.cUniqueID AND EnvType == ENVTYPE_ENVIRONMENT
		DELETE ALL FOR ParentID == m.cUniqueID AND EnvType == ENVTYPE_PROJECT
		
		SELECT (m.nSelect)
		
		RETURN .T.
	ENDFUNC
	
	FUNCTION ReadRegistryDWORD(nHandle, cRegKey)
		LOCAL nDataType
		LOCAL nBuffer
		LOCAL nSize
		LOCAL nResult
		
		m.nBuffer = 0
		IF m.nHandle >= 0
			DECLARE INTEGER RegQueryValueEx IN Win32API AS RegQueryDWORD;
	         INTEGER nHKey,;
	         STRING lpszValueName,;
	         INTEGER dwReserved,;
	         Integer @lpdwType,;
	         INTEGER @lpbData,;
	         INTEGER @lpcbData

			nDataType   = 4
			nSize       = 4

			nResult = RegQueryDWORD(nHandle, cRegKey, 0, @nDataType, @nBuffer, @nSize)

			IF m.nResult <> ERROR_SUCCESS
				m.nBuffer = 0
			ENDIF
		ENDIF
		
		RETURN m.nBuffer
	ENDFUNC

	FUNCTION WriteRegistryDWORD(nHandle, cRegKey, nValue)
		LOCAL nBuffer
		LOCAL nSize
		LOCAL nResult
		
		IF m.nHandle >= 0
			DECLARE INTEGER RegSetValueEx IN Win32API AS RegWriteDWORD ;
			 INTEGER nHKey,;
			 STRING lpszEntry,;
			 INTEGER dwReserved,;
			 INTEGER fdwType,;
			 INTEGER @lpbData,;
			 INTEGER cbData
			 
			IF VARTYPE(nValue) == 'L'
				nValue = IIF(nValue, 1, 0)
			ENDIF

			nSize = 4
			nResult = RegWriteDWORD(nHandle, cRegKey, 0, REG_DWORD, @nValue, nSize)
			IF m.nResult <> ERROR_SUCCESS
				m.nBuffer = 0
			ENDIF
		ENDIF
		
		RETURN .T.
	ENDFUNC
ENDDEFINE


DEFINE CLASS EnvMgrHook AS ProjectHook
	PROCEDURE Init()
		LOCAL oEnvMgr
		
		oEnvMgr = CREATEOBJECT("EnvMgrEngine")
		
		oEnvMgr.SetProjectEnv(Application.ActiveProject.Name)
		
		oEnvMgr = .NULL.
	ENDPROC
ENDDEFINE

DEFINE CLASS OptionDef AS Custom
	UniqueID     = ''
	OptionName   = ''
	OptionValues = ''
	GetCode      = ''
	SetCode      = ''
	ActualValue  = ''
ENDDEFINE

* <summary>
*	Abstract Data Management class.  Must inherit
*	from this for any Data providers you have.
* </summary>
#include "DataExplorer.h"
#include "foxpro.h"

DEFINE CLASS DatabaseMgmt AS Session
	ServerName   = ''
	DatabaseName = ''
	UserName     = ''
	UserPassword = ''
	ConnectionString = ''
	
	SortObjects = .T.
	Verbose = .T.

	IgnoreErrors = .F.

	LastError = ''
	QueryResultOutput = ''
	
	
	PROCEDURE Destroy()
		THIS.Disconnect()
	ENDPROC
	
	FUNCTION Connect(cServer, cDatabase, cUserName, cPassword) AS Boolean
	ENDFUNC
	
	FUNCTION Disconnect()
	ENDFUNC

	FUNCTION ClearErrors()
		THIS.LastError = ''
	ENDFUNC
	
	* strip password for a connection string
	FUNCTION StripPassword(cStr as String)
		LOCAL cNewValue
		LOCAL i
		LOCAL cVal
		
		cNewValue = ''
		FOR i = 1 TO GETWORDCOUNT(cStr, ';')
			cVal = GETWORDNUM(cStr, i, ';')
			IF !(UPPER(LEFT(cVal, 8)) = "PASSWORD" OR UPPER(LEFT(cVal, 3)) = "PWD")
				cNewValue = cNewValue + IIF(EMPTY(cNewValue), '', ';') + GETWORDNUM(cStr, i, ';')
			ELSE
				IF AT('=', cVal) > 0
					cNewValue = cNewValue + IIF(EMPTY(cNewValue), '', ';') + LEFT(cVal, AT('=', cVal)) + "***"
				ENDIF
			ENDIF
		ENDFOR
		
		RETURN cNewValue
	ENDFUNC
	
	FUNCTION SetError(cErrorMsg)
		LOCAL i
		LOCAL cErrorMsg
		LOCAL nErrorCnt
		LOCAL ARRAY aErrorList[1]
		
		IF VARTYPE(cErrorMsg) <> 'C' OR EMPTY(cErrorMsg)
			cErrorMsg = ''
			nErrorCnt = AERROR(aErrorList)
			FOR i = 1 TO nErrorCnt
				IF aErrorList[i, 1] == 1526 && ODBC error
					IF ISNULL(aErrorList[i, 3])
						cErrorMsg = cErrorMsg + IIF(EMPTY(cErrorMsg), '', CHR(10)) + "Problem executing query"
					ELSE
						cErrorMsg = cErrorMsg + IIF(EMPTY(cErrorMsg), '', CHR(10)) + SUBSTR(aErrorList[i, 3], RAT(']', aErrorList[i, 3]) + 1)
					ENDIF
				ELSE
					cErrorMsg = cErrorMsg + IIF(EMPTY(cErrorMsg), '', CHR(10)) + aErrorList[i, 2]
				ENDIF
			ENDFOR
		ENDIF

		THIS.LastError = cErrorMsg
	ENDFUNC


	FUNCTION GetAvailableServers()
		LOCAL oObjCollection
		LOCAL oException
		oObjCollection = CREATEOBJECT("ServerCollection")

		TRY
			IF !THIS.OnGetAvailableServers(oObjCollection)
				oObjCollection = .NULL.
			ENDIF
		CATCH TO oException
			oObjCollection = .NULL.
			* ignore error
			IF !THIS.IgnoreErrors
				MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, DATAEXPLORER_LOC)
			ENDIF
		ENDTRY
	
		RETURN oObjCollection
	ENDFUNC

	FUNCTION GetDatabases(cServerName)
		LOCAL oObjCollection

		oObjCollection = CREATEOBJECT("DatabaseCollection")
		THIS.OnGetDatabases(oObjCollection)
		
		RETURN oObjCollection
	ENDFUNC

	FUNCTION GetTables()
		LOCAL oObjCollection
		LOCAL oException
		oObjCollection = CREATEOBJECT("TableCollection")

		TRY
			IF !THIS.OnGetTables(oObjCollection)
				oObjCollection = .NULL.
			ENDIF
		CATCH TO oException
			oObjCollection = .NULL.
			IF !THIS.IgnoreErrors
				MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, DATAEXPLORER_LOC)
			ENDIF
		ENDTRY
		
		RETURN oObjCollection
	ENDFUNC

	FUNCTION GetViews()
		LOCAL oObjCollection
		LOCAL oException
		oObjCollection = CREATEOBJECT("ViewCollection")
		
		TRY
			IF !THIS.OnGetViews(oObjCollection)
				oObjectCollection = .NULL.
			ENDIF
		CATCH TO oException
			IF !THIS.IgnoreErrors
				oObjectCollection = .NULL.
				MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, DATAEXPLORER_LOC)
			ENDIF
		ENDTRY
		
		RETURN oObjCollection
	ENDFUNC

	FUNCTION GetStoredProcedures()
		LOCAL oObjCollection
		LOCAL oException
		oObjCollection = CREATEOBJECT("StoredProcCollection")

		TRY
			IF !THIS.OnGetStoredProcedures(oObjCollection)
				oObjCollection = .NULL.
			ENDIF
		CATCH TO oException
			oObjCollection = .NULL.
			IF !THIS.IgnoreErrors
				MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, DATAEXPLORER_LOC)
			ENDIF
		ENDTRY
		
		RETURN oObjCollection
	ENDFUNC

	FUNCTION GetParameters(cStoredProcName, cOwner)
		LOCAL oObjCollection
		LOCAL oException
		oObjCollection = CREATEOBJECT("ParameterCollection")
		
		TRY
			IF !THIS.OnGetParameters(oObjCollection, cStoredProcName, cOwner)
				oObjCollection = .NULL.
			ENDIF
		CATCH TO oException
			oObjCollection = .NULL.
			IF !THIS.IgnoreErrors
				MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, DATAEXPLORER_LOC)
			ENDIF
		ENDTRY
		
		RETURN oObjCollection
	ENDFUNC

	FUNCTION GetFunctions()
		LOCAL oObjCollection
		LOCAL oException
		oObjCollection = CREATEOBJECT("FunctionCollection")

		TRY
			IF !THIS.OnGetFunctions(oObjCollection)
				oObjCollection = .NULL.
			ENDIF
		CATCH TO oException
			oObjCollection = .NULL.
			IF !THIS.IgnoreErrors
				MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, DATAEXPLORER_LOC)
			ENDIF
		ENDTRY
		
		RETURN oObjCollection
	ENDFUNC

	FUNCTION GetFunctionParameters(cFuncName, cOwner)
		LOCAL oObjCollection
		LOCAL oException
		oObjCollection = CREATEOBJECT("ParameterCollection")
		TRY
			IF !THIS.OnGetFunctionParameters(oObjCollection, cFuncName, cOwner)
				oObjCollection = .NULL.
			ENDIF			
		CATCH TO oException
			oObjCollection = .NULL.
			IF !THIS.IgnoreErrors
				MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, DATAEXPLORER_LOC)
			ENDIF
		ENDTRY
		
		RETURN oObjCollection
	ENDFUNC

	FUNCTION GetSchema(cTableName, cOwner)
		LOCAL oObjCollection
		LOCAL oException
		oObjCollection = CREATEOBJECT("ColumnCollection")
		TRY
			IF !THIS.OnGetSchema(oObjCollection, cTableName, cOwner)
				oObjCollection = .NULL.
			ENDIF

		CATCH TO oException
			oObjCollection = .NULL.
			IF !THIS.IgnoreErrors
				MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, DATAEXPLORER_LOC)
			ENDIF
		ENDTRY
			
		
		RETURN oObjCollection
	ENDFUNC
	
	FUNCTION GetStoredProcedureDefinition(cStoredProcName, cOwner) AS String
		RETURN NVL(THIS.OnGetStoredProcedureDefinition(cStoredProcName, cOwner), '')
	ENDFUNC

	FUNCTION GetFunctionDefinition(cFunctionName, cOwner) AS String
		RETURN NVL(THIS.OnGetFunctionDefinition(cFunctionName, cOwner), '')
	ENDFUNC

	FUNCTION GetViewDefinition(cViewName, cOwner) AS String
		RETURN NVL(THIS.OnGetViewDefinition(cViewName, cOwner), '')
	ENDFUNC
	
	FUNCTION BrowseData(cTableName, cOwner)
		THIS.OnBrowseData(cTableName, cOwner)
	ENDFUNC

	FUNCTION DesignTable(cTableName, cOwner)
		THIS.OnDesignTable(cTableName, cOwner)
	ENDFUNC

	FUNCTION NewTable()
		THIS.OnNewTable()
	ENDFUNC

	FUNCTION DesignView(cViewName, cOwner)
		THIS.OnDesignView(cViewName, cOwner)
	ENDFUNC

	FUNCTION NewView()
		THIS.OnNewView()
	ENDFUNC

	FUNCTION RunStoredProcedure(cStoredProcName, cOwner)
		LOCAL oParamList
		LOCAL lSuccess

		lSuccess = .T.
	
		oParamList = THIS.GetParameters(cStoredProcName, cOwner)

		IF VARTYPE(oParamList) == 'O' AND oParamList.Count > 0
			DO FORM StoredProcParameters WITH oParamList TO lSuccess
		ENDIF
		IF lSuccess
			THIS.OnRunStoredProcedure(cStoredProcName, cOwner, oParamList)
		ENDIF
	ENDFUNC
	
	* ExecuteQuery always runs the query in the current
	* datasession.  Primarily for internal queries -- for example,
	* to retrieve schema information.
*!*		PROTECTED FUNCTION ExecuteQuery(cSQL, cAlias)
*!*			RETURN THIS.RunQuery(cSQL, cAlias, THIS.DataSessionID)
*!*		ENDPROC

	PROCEDURE RunQuery(cSQL)
		THIS.OnRunQuery(cSQL)
	ENDPROC
	
	PROCEDURE OnRunQuery(cSQL)
		DO FORM RunQuery WITH THIS, cSQL
	ENDPROC
	
	* Use RunQuery to execute a query that returns
	* a result in a specified dataset. 
	FUNCTION ExecuteQuery(cSQL, cAlias, nDataSessionID)
		LOCAL nSelect
		LOCAL nSaveDataSessionID
		LOCAL lSuccess
		LOCAL nErrorCnt
		LOCAL oResultCollection
		LOCAL aErrorList[1]
		
	
		nSelect = SELECT()
		
		IF VARTYPE(cAlias) <> 'C' OR EMPTY(cAlias)
			cAlias = "SQLResults"
		ENDIF
		
		cAlias = CHRTRAN(cAlias, ' !<>;:"[]+=-!@#$%^&*()?/.,{}\|', '')


		nSaveDataSessionID = THIS.DataSessionID
		IF VARTYPE(nDataSessionID) <> 'N' OR nDataSessionID < 1
			nDataSessionID = THIS.DataSessionID
		ENDIF
		IF nDataSessionID <> THIS.DataSessionID
			SET DATASESSION TO (nDataSessionID)
		ENDIF


		THIS.ClearErrors()  && clear any existing errors
		THIS.ClearQueryOutput()

		oResultCollection = THIS.OnExecuteQuery(cSQL, cAlias)
		IF VARTYPE(oResultCollection) <> 'O' OR oResultCollection.Count == 0
			oResultCollection = .NULL.
		ENDIF
			
		IF nSaveDataSessionID <> THIS.DataSessionID
			SET DATASESSION TO (nSaveDataSessionID)
		ENDIF

		SELECT (nSelect)
		
		RETURN oResultCollection
	ENDFUNC
	
	FUNCTION ClearQueryOutput()
		THIS.QueryResultOutput = ''
	ENDFUNC
	FUNCTION AddToQueryOutput(cMsg)
		THIS.QueryResultOutput = THIS.QueryResultOutput  + ;
		 IIF(EMPTY(THIS.QueryResultOutput), '', CHR(10) + CHR(10)) + cMsg
	ENDFUNC

	PROCEDURE CloseTable(cAlias)
		IF USED(cAlias)
			USE IN (cAlias)
		ENDIF
	ENDPROC

	** Abstract methods for populating collections
	FUNCTION OnGetAvailableServers(oServerCollection AS ServerCollection)
	ENDFUNC

	FUNCTION OnGetDatabases(oDatabaseCollection AS DatabaseCollection)
	ENDFUNC
	
	FUNCTION OnGetTables(oTableCollection AS TableCollection)
	ENDFUNC

	FUNCTION OnGetViews(oViewCollection AS ViewCollection)
	ENDFUNC

	FUNCTION OnGetStoredProcedures(oStoredProcCollection AS StoredProcCollection)
	ENDFUNC

	FUNCTION OnGetParameters(oParameterCollection AS ParameterCollection, cStoredProcName, cOwner)
	ENDFUNC

	FUNCTION OnGetFunctions(oFunctionCollection AS FunctionCollection)
	ENDFUNC

	FUNCTION OnGetFunctionParameters(oParameterCollection AS ParameterCollection, cFuncName, cOwner)
	ENDFUNC
	
	FUNCTION OnGetSchema(oColumnCollection AS ColumnCollection, cTableName, cOwner)
	ENDFUNC

	FUNCTION OnGetStoredProcedureDefinition(cStoredProcName, cOwner) AS String
		RETURN ''
	ENDFUNC
	
	FUNCTION OnGetFunctionDefinition(cFunctionName, cOwner) AS String
		RETURN ''
	ENDFUNC
	
	FUNCTION OnGetViewDefinition(cViewName, cOwner) AS String
		RETURN ''
	ENDFUNC
	
	FUNCTION OnBrowseData(cTableName, cOwner)
	ENDFUNC

	FUNCTION OnNewTable()
	ENDFUNC

	FUNCTION OnDesignTable(cTableName, cOwner)
	ENDFUNC

	FUNCTION OnNewView()
	ENDFUNC

	FUNCTION OnDesignView(cViewName, cOwner)
	ENDFUNC

	FUNCTION OnRunStoredProcedure(cStoredProcName, cOwner, oParamList)
	ENDFUNC

	FUNCTION OnExecuteQuery(cSQL, cAlias)
	ENDFUNC

ENDDEFINE


* <summary>
*	Collection class which all other DataMgmt classes are
*	derived from.
* </summary>
DEFINE CLASS CCollection AS Collection
	FUNCTION AddEntity(cName)
		RETURN .NULL.
	ENDFUNC

	FUNCTION Add(xItem, cKey, eBefore, eAfter)
		* silently ignore any duplicate keys
		IF THIS.GetKey(cKey) <> 0
			NODEFAULT
			RETURN .F.
		ENDIF
	ENDFUNC

	FUNCTION GetStruct(cObjectType, cName)
		LOCAL oStruct
		
		oStruct = CREATEOBJECT("Empty")
		AddProperty(oStruct, "Type", cObjectType)
		AddProperty(oStruct, "Name", cName)
		
		RETURN oStruct
	ENDFUNC
ENDDEFINE


* <summary>
*	Collection class for servers.
* </summary>
DEFINE CLASS ServerCollection AS CCollection
	FUNCTION AddEntity(cName)
		LOCAL oStruct

		oStruct = THIS.GetStruct("Server", cName)
		THIS.Add(oStruct, cName)
		
		RETURN oStruct
	ENDFUNC
ENDDEFINE

* <summary>
*	Collection class for databases.
* </summary>
DEFINE CLASS DatabaseCollection AS CCollection
	FUNCTION AddEntity(cName, cPhysicalFile, cConnectString, cServer, cDatabaseType, cUser)
		LOCAL oStruct
		
		oStruct = THIS.GetStruct("Database", cName)
		AddProperty(oStruct, "ConnectString", EVL(cConnectString, ''))
		AddProperty(oStruct, "PhysicalFile", EVL(cPhysicalFile, ''))
		AddProperty(oStruct, "Server", EVL(cServer, ''))
		AddProperty(oStruct, "State", 0)
		AddProperty(oStruct, "DatabaseType", EVL(cDatabaseType, ''))
		AddProperty(oStruct, "User", EVL(cUser, ''))
		AddProperty(oStruct, "Owner", '')
		AddProperty(oStruct, "Size", 0)
		THIS.Add(oStruct, cName)
		
		RETURN oStruct
	ENDFUNC
ENDDEFINE

* <summary>
*	Collection class for tables in a database.
* </summary>
DEFINE CLASS TableCollection AS CCollection
	FUNCTION AddEntity(cName, cPhysicalFile, cOwner)
		LOCAL oStruct
		
		oStruct = THIS.GetStruct("Table", cName)
		AddProperty(oStruct, "PhysicalFile", EVL(cPhysicalFile, ''))
		AddProperty(oStruct, "Owner", EVL(NVL(cOwner, ''), ''))
		THIS.Add(oStruct, IIF(EMPTY(cOwner), '', cOwner + '.') + cName)
		
		RETURN oStruct
	ENDFUNC
ENDDEFINE

* <summary>
*	Collection class for views in a database.
* </summary>
DEFINE CLASS ViewCollection AS CCollection
	FUNCTION AddEntity(cName, cOwner)
		LOCAL oStruct
		
		oStruct = THIS.GetStruct("View", cName)
		cOwner = EVL(NVL(cOwner, ''), '')
		AddProperty(oStruct, "Owner", cOwner)
		THIS.Add(oStruct, IIF(EMPTY(cOwner), '', cOwner + '.') + cName)
		
		RETURN oStruct
	ENDFUNC
ENDDEFINE

* <summary>
*	Collection class for stored procs in a database.
* </summary>
DEFINE CLASS StoredProcCollection AS CCollection
	FUNCTION AddEntity(cName, cOwner)
		LOCAL oStruct
		
		oStruct = THIS.GetStruct("StoredProc", cName)

		cOwner = EVL(NVL(cOwner, ''), '')
		AddProperty(oStruct, "Owner", cOwner)
		THIS.Add(oStruct, IIF(EMPTY(cOwner), '', cOwner + '.') + cName)
		
		RETURN oStruct
	ENDFUNC
ENDDEFINE


* <summary>
*	Collection class for functions in a database.
* </summary>
DEFINE CLASS FunctionCollection AS CCollection
	FUNCTION AddEntity(cName, cOwner)
		LOCAL oStruct

		cOwner = EVL(NVL(cOwner, ''), '')
		oStruct = THIS.GetStruct("Function", cName)
		AddProperty(oStruct, "Owner", cOwner)
		THIS.Add(oStruct, IIF(EMPTY(cOwner), '', cOwner + '.') + cName)

		RETURN oStruct
	ENDFUNC
ENDDEFINE


* <summary>
*	Collection class for columns in a table.
* </summary>
DEFINE CLASS ColumnCollection AS CCollection
	FUNCTION AddEntity(cName, cDataType, nLength, nDecimals, lIsNullable, cDefaultValue, lPrimaryKey, lIdentity)
		LOCAL oStruct

		
		oStruct = THIS.GetStruct("Column", cName)
		AddProperty(oStruct, "DataType", cDataType)
		AddProperty(oStruct, "Length", EVL(nLength, 0))
		AddProperty(oStruct, "Decimals", EVL(nDecimals, .NULL.))
		AddProperty(oStruct, "IsNullable", lIsNullable)
		AddProperty(oStruct, "DefaultValue", NVL(EVL(cDefaultValue, ''), ''))
		AddProperty(oStruct, "PrimaryKey", lPrimaryKey)
		AddProperty(oStruct, "Identity", lIdentity)
		THIS.Add(oStruct, cName)

		RETURN oStruct
	ENDFUNC
ENDDEFINE


* <summary>
*	Collection class for parameters in a stored procedure.
* </summary>
DEFINE CLASS ParameterCollection AS CCollection
	FUNCTION AddEntity(cName, cDataType, nLength, nDecimals, cDefaultValue, nDirection, cDefaultValue)
		LOCAL oStruct

		IF VARTYPE(nDirection) <> 'N' OR EMPTY(nDirection)
			nDirection = PARAM_UNKNOWN
		ENDIF
		cName = EVL(cName, RETURN_VALUE_LOC)

		oStruct = THIS.GetStruct("Parameter", cName)
		AddProperty(oStruct, "DataType", cDataType)
		AddProperty(oStruct, "Length", EVL(NVL(nLength, 0), 0))
		AddProperty(oStruct, "Decimals", EVL(nDecimals, .NULL.))
		AddProperty(oStruct, "DefaultValue", EVL(cDefaultValue, ''))
		AddProperty(oStruct, "Direction", nDirection)
		THIS.Add(oStruct, cName)

		RETURN oStruct
	ENDFUNC
ENDDEFINE

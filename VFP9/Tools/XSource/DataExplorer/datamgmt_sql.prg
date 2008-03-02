* <summary>
*	Data Management for Microsoft SQL Server.
* </summary>
#include "DataExplorer.h"
#include "foxpro.h"


* These defines are used by OnGetAvailableServers() method
#define SQL_HANDLE_ENV			1
#define SQL_HANDLE_DBC			2
#define SQL_ATTR_ODBC_VERSION	200
#define SQL_OV_ODBC3			3
#define SQL_SUCCESS				0
#define SQL_NEED_DATA			99
#define DEFAULT_RESULT_SIZE		2048
#define SQL_DRIVER_STR			"DRIVER=SQL SERVER";


DEFINE CLASS SQLDatabaseMgmt AS DatabaseMgmt OF DataMgmt.prg
	TrustedConnection = .T.

	SQLHandle = 0

	ConnectTimeOut   = CONNECT_TIMEOUT_DEFAULT  && 15 seconds
	QueryTimeOut     = QUERY_TIMEOUT_DEFAULT && wait 600 seconds by default for a query before timing out
	AutoTransactions = .T.
	DispWarnings     = .F.


	PROCEDURE Init()
		DODEFAULT()
	ENDPROC
	

	* Return an ODBC Connection string
	FUNCTION GetODBCConnectionString()
		LOCAL cConnString
 
		cConnString = [driver=] + SQL_ODBC_DRIVER + [;]
		IF !EMPTY(THIS.ServerName)
			cConnString = cConnString + [SERVER=] + THIS.ServerName + [;]
		ENDIF
		IF !EMPTY(THIS.DatabaseName)
			cConnString = cConnString + [DATABASE=] + THIS.DatabaseName + [;]
		ENDIF

		* if both are blank, this will be setup as a trusted connection
		IF THIS.TrustedConnection
			cConnString = cConnString + [Trusted_Connection=yes;]
		ELSE
			cConnString = cConnString + [UID=] + THIS.UserName + [;]
			cConnString = cConnString + [PWD=] + THIS.UserPassword + [;]
		ENDIF		

		cConnString = cConnString + [APP=] + APP_NAME + [;]

		RETURN cConnString
	ENDFUNC

	* Return a Connection string for SQL Namespace objects
	FUNCTION GetNamespaceConnectionString()
		LOCAL cConnString
 
		cConnString = ''
		IF !EMPTY(THIS.ServerName)
			cConnString = cConnString + [SERVER=] + THIS.ServerName + [;]
		ENDIF
		IF !EMPTY(THIS.DatabaseName)
			cConnString = cConnString + [DATABASE=] + THIS.DatabaseName + [;]
		ENDIF

		* if both are blank, this will be setup as a trusted connection
		IF EMPTY(THIS.UserName) AND EMPTY(THIS.UserPassword)
			cConnString = cConnString + [Trusted_Connection=yes;]
		ELSE
			cConnString = cConnString + [UID=] + THIS.UserName + [;]
			cConnString = cConnString + [PWD=] + THIS.UserPassword + [;]
		ENDIF		

		RETURN cConnString
	ENDFUNC
	
	PROCEDURE Disconnect()
		IF THIS.SQLHandle > 0
			SQLDisconnect(THIS.SQLHandle)
		ENDIF
	ENDPROC	
	
	FUNCTION Connect(cServer, cDatabase, lTrustedConnection, cUserName, cPassword) AS Boolean
		LOCAL nSuccess
		LOCAL oLoginInfo
		LOCAL oException
		LOCAL cConnString
		LOCAL nDispLogin
		LOCAL lDispWarnings
		LOCAL nConnectTimeout

		IF VARTYPE(cServer) <> 'C'
			cServer = .NULL.
		ENDIF
		
		IF VARTYPE(cUserName) <> 'C'
			cUserName = THIS.UserName
		ENDIF
		IF VARTYPE(cPassword) <> 'C'
			cPassword = THIS.UserPassword
		ENDIF
		
		IF EMPTY(cServer)
			* no server specified, so nothing to connect to
			RETURN .T.
		ENDIF

		IF PCOUNT() < 3 OR VARTYPE(lTrustedConnection) <> 'L'
			lTrustedConnection = EMPTY(cUserName)
		ENDIF

		
		IF THIS.SQLHandle > 0 AND UPPER(THIS.ServerName) == UPPER(cServer) AND UPPER(THIS.DatabaseName) == UPPER(cDatabase) AND ;
		  THIS.TrustedConnection = lTrustedConnection AND UPPER(THIS.UserName) == UPPER(cUserName) AND ;
		  UPPER(THIS.UserPassword) == UPPER(cPassword)
			RETURN .T.
		ENDIF

		
		THIS.Disconnect()


		THIS.ServerName        = cServer
		THIS.DatabaseName      = cDatabase

		nSuccess = 0
		DO WHILE nSuccess = 0
			THIS.TrustedConnection = lTrustedConnection
			THIS.UserName          = cUserName
			THIS.UserPassword      = cPassword		

			nDispLogin      = SQLGETPROP(0, "DispLogin")
			lDispWarnings   = SQLGETPROP(0, "DispWarnings")
			nConnectTimeout = SQLGETPROP(0, "ConnectTimeout")

			cConnString = THIS.GetODBCConnectionString()
			this.connectionstring = cconnstring

			TRY
				SQLSETPROP(0, "DispLogin", DB_PROMPTNEVER)
				SQLSETPROP(0, "DispWarnings", .F.)
				SQLSETPROP(0, "ConnectTimeout", THIS.ConnectTimeout) 

				THIS.SQLHandle = SQLSTRINGCONNECT(cConnString, .T.)
			CATCH TO oException
				* ignore error
			FINALLY
				SQLSETPROP(0, "DispLogin", nDispLogin)
				SQLSETPROP(0, "DispWarnings", lDispWarnings)
				SQLSETPROP(0, "ConnectTimeout", nConnectTimeout)
			ENDTRY
			IF THIS.SQLHandle > 0
				SQLSETPROP(THIS.SQLHandle, "Asynchronous", .F.)
				SQLSETPROP(THIS.SQLHandle, "BatchMode", .T.)
				SQLSETPROP(THIS.SQLHandle, "IdleTimeout", 0) && never time out

				SQLSETPROP(THIS.SQLHandle, "QueryTimeout", THIS.QueryTimeout) 
				SQLSETPROP(THIS.SQLHandle, "Transactions", IIF(THIS.AutoTransactions, DB_TRANSAUTO, DB_TRANSMANUAL))
				SQLSETPROP(THIS.SQLHandle, "DispWarnings", THIS.DispWarnings) 

				nSuccess = 2
			ELSE
				IF nSuccess == 0
					DO FORM SQLConnectAs WITH lTrustedConnection, cUserName, cPassword TO oLoginInfo
					IF VARTYPE(oLoginInfo) == 'O'
						lTrustedConnection = oLoginInfo.TrustedConnection
						cUserName          = oLoginInfo.UserName
						cPassword          = oLoginInfo.Password
					ELSE
						nSuccess = 1
					ENDIF
				ENDIF
			ENDIF
		ENDDO
		
		RETURN (nSuccess == 2)
	ENDFUNC

	
	FUNCTION OnGetTables(oTableCollection AS TableCollection)
		LOCAL cSQL

		TEXT TO cSQL TEXTMERGE NOSHOW PRETEXT 7
			SELECT * FROM [<<THIS.DatabaseName>>].INFORMATION_SCHEMA.TABLES
			 WHERE TABLE_TYPE = 'BASE TABLE'
			 <<IIF(THIS.SortObjects, "ORDER BY [TABLE_NAME]", "")>>
		ENDTEXT

		IF !ISNULL(THIS.ExecuteQuery(cSQL, "SchemaCursor"))
			SELECT SchemaCursor
			SCAN ALL
				oTableCollection.AddEntity(RTRIM(SchemaCursor.Table_Name), '', RTRIM(SchemaCursor.Table_Schema))  && Table_Schema = owner
			ENDSCAN			
		ENDIF
		THIS.CloseTable("SchemaCursor")
	ENDFUNC

	FUNCTION OnGetViews(oViewCollection AS ViewCollection)
		LOCAL cSQL
		
		TEXT TO cSQL TEXTMERGE NOSHOW PRETEXT 7
			SELECT * FROM [<<THIS.DatabaseName>>].INFORMATION_SCHEMA.VIEWS
			 <<IIF(THIS.SortObjects, "ORDER BY [TABLE_NAME]", "")>>
		ENDTEXT

		IF !ISNULL(THIS.ExecuteQuery(cSQL, "SchemaCursor"))
			SELECT SchemaCursor
			SCAN ALL
				oViewCollection.AddEntity(RTRIM(SchemaCursor.Table_Name), RTRIM(SchemaCursor.Table_Schema))
			ENDSCAN			
		ENDIF
		THIS.CloseTable("SchemaCursor")
	ENDFUNC

	FUNCTION OnGetStoredProcedures(oStoredProcCollection AS StoredProcCollection)
		LOCAL cSQL
		
		TEXT TO cSQL TEXTMERGE NOSHOW PRETEXT 7
			SELECT * FROM [<<THIS.DatabaseName>>].INFORMATION_SCHEMA.ROUTINES
			 WHERE ROUTINE_TYPE = 'PROCEDURE'
			 <<IIF(THIS.SortObjects, "ORDER BY [ROUTINE_NAME]", "")>>
		ENDTEXT

		IF !ISNULL(THIS.ExecuteQuery(cSQL, "SchemaCursor"))
			SELECT SchemaCursor
			SCAN ALL
				oStoredProcCollection.AddEntity(RTRIM(SchemaCursor.Routine_Name), RTRIM(SchemaCursor.Routine_Schema))
			ENDSCAN
		ENDIF
		THIS.CloseTable("SchemaCursor")
	ENDFUNC

	FUNCTION MapParameter(cSQLParamType)
		LOCAL nParamType
		
		IF VARTYPE(cSQLParamType) <> 'C'
			nParamType = PARAM_UNKNOWN
		ELSE
			cSQLParamType = UPPER(ALLTRIM(cSQLParamType))
			DO CASE
			CASE cSQLParamType == "IN"
				nParamType = PARAM_INPUT
			CASE cSQLParamType == "OUT"
				nParamType = PARAM_OUTPUT
			CASE cSQLParamType == "INOUT"
				nParamType = PARAM_INPUTOUTPUT
			CASE cSQLParamType == "RETURN"
				nParamType = PARAM_RETURNVALUE
			OTHERWISE
				nParamType = PARAM_UNKNOWN
			ENDCASE
		ENDIF
				
		RETURN nParamType
	ENDFUNC

	FUNCTION OnGetParameters(oParameterCollection AS ParameterCollection, cStoredProcName AS String, cOwner AS String)
		LOCAL cSQL
		
		TEXT TO cSQL TEXTMERGE NOSHOW PRETEXT 7
			SELECT * FROM [<<THIS.DatabaseName>>].INFORMATION_SCHEMA.PARAMETERS
			 WHERE SPECIFIC_NAME = '<<cStoredProcName>>' AND SPECIFIC_SCHEMA = '<<cOwner>>'
			 ORDER BY [ORDINAL_POSITION]
		ENDTEXT

		IF !ISNULL(THIS.ExecuteQuery(cSQL, "SchemaCursor"))
			SELECT SchemaCursor
			SCAN ALL
				oParameterCollection.AddEntity( ;
				  RTRIM(SchemaCursor.Parameter_Name), ;
				  RTRIM(SchemaCursor.Data_Type), ;
				  NVL(SchemaCursor.Character_Maximum_Length, SchemaCursor.Numeric_Precision), ;
				  SchemaCursor.Numeric_Scale, ;
				  '', ;
				  THIS.MapParameter(SchemaCursor.Parameter_Mode) ;
				 )
			ENDSCAN
		ENDIF
		THIS.CloseTable("SchemaCursor")
	ENDFUNC

	FUNCTION OnGetSchema(oColumnCollection AS ColumnCollection, cTableName, cOwner)
		LOCAL cSQL
		
		TEXT TO cSQL TEXTMERGE NOSHOW PRETEXT 7
			SELECT * FROM [<<THIS.DatabaseName>>].INFORMATION_SCHEMA.COLUMNS 
			 WHERE TABLE_NAME = '<<cTableName>>' AND TABLE_SCHEMA = '<<cOwner>>'
			 <<IIF(THIS.SortObjects, "ORDER BY [COLUMN_NAME]", "ORDER BY [ORDINAL_POSITION]")>>
		ENDTEXT

		IF !ISNULL(THIS.ExecuteQuery(cSQL, "SchemaCursor"))
			SELECT SchemaCursor
			SCAN ALL
				oColumnCollection.AddEntity( ;
				  RTRIM(SchemaCursor.Column_Name), ;
				  RTRIM(SchemaCursor.Data_Type), ;
				  NVL(SchemaCursor.Character_Maximum_Length, SchemaCursor.Numeric_Precision), ;
				  SchemaCursor.Numeric_Scale, ;
				  LEFT(SchemaCursor.Is_Nullable, 1) == 'Y', ;
				  SchemaCursor.Column_Default ;
				 )
			ENDSCAN
		ENDIF
		THIS.CloseTable("SchemaCursor")
	ENDFUNC
	
	FUNCTION SPHelpText(cObjName) AS String
		LOCAL nSelect
		LOCAL lUnicode
		LOCAL cResult
		
		cResult = ''
		
		nSelect = SELECT()
		
		TEXT TO cSQL TEXTMERGE NOSHOW PRETEXT 7
			sp_helptext @objname='<<cObjName>>'
		ENDTEXT

		IF !ISNULL(THIS.ExecuteQuery(cSQL, "HelpTextCursor"))
			SELECT HelpTextCursor
			SCAN ALL
				cResult = cResult + HelpTextCursor.Text
			ENDSCAN
			IF !(LEFT(STRCONV(cResult, 6),2) == "??")
				cResult = STRCONV(cResult, 6)
			ENDIF
		ENDIF
		
		THIS.CloseTable("HelpTextCursor")
		
		SELECT (nSelect)
		
		RETURN cResult
	ENDFUNC
	

	FUNCTION OnGetStoredProcedureDefinition(cStoredProcName, cOwner) AS String
		RETURN THIS.SPHelpText(cOwner + '.' + cStoredProcName)
	ENDFUNC
	
	FUNCTION OnGetFunctionDefinition(cFunctionName, cOwner) AS String
		RETURN THIS.SPHelpText(cOwner + '.' + cFunctionName)
	ENDFUNC

	FUNCTION OnGetViewDefinition(cViewName, cOwner) AS String
		RETURN THIS.SPHelpText(cOwner + '.' + cViewName)
	ENDFUNC


	FUNCTION OnGetFunctions(oFunctionCollection AS FunctionCollection)
		LOCAL cSQL
		
		TEXT TO cSQL TEXTMERGE NOSHOW PRETEXT 7
			SELECT * FROM [<<THIS.DatabaseName>>].INFORMATION_SCHEMA.ROUTINES
			 WHERE ROUTINE_TYPE = 'FUNCTION'
			 <<IIF(THIS.SortObjects, "ORDER BY [ROUTINE_NAME]", "")>>
		ENDTEXT

		IF !ISNULL(THIS.ExecuteQuery(cSQL, "SchemaCursor"))
			SELECT SchemaCursor
			SCAN ALL
				oFunctionCollection.AddEntity(RTRIM(SchemaCursor.Routine_Name), RTRIM(SchemaCursor.Routine_Schema))
			ENDSCAN			
		ENDIF
		THIS.CloseTable("SchemaCursor")
	ENDFUNC

	FUNCTION OnGetFunctionParameters(oParameterCollection AS ParameterCollection, cFuncName AS String, cOwner AS String)
		LOCAL cSQL
		
		TEXT TO cSQL TEXTMERGE NOSHOW PRETEXT 7
			SELECT * FROM [<<THIS.DatabaseName>>].INFORMATION_SCHEMA.PARAMETERS
			 WHERE 
			  SPECIFIC_NAME = '<<cFuncName>>' AND 
			  SPECIFIC_SCHEMA = '<<cOwner>>'
			 ORDER BY [ORDINAL_POSITION]
		ENDTEXT

		IF !ISNULL(THIS.ExecuteQuery(cSQL, "SchemaCursor"))
			SELECT SchemaCursor
			SCAN ALL FOR ALLTRIM(Parameter_Mode) = "IN"
				oParameterCollection.AddEntity( ;
				  RTRIM(SchemaCursor.Parameter_Name), ;
				  RTRIM(SchemaCursor.Data_Type), ;
				  NVL(SchemaCursor.Character_Maximum_Length, SchemaCursor.Numeric_Precision), ;
				  SchemaCursor.Numeric_Scale, ;
				  '', ;
				  THIS.MapParameter(SchemaCursor.Parameter_Mode) ;
				 )
			ENDSCAN
			SCAN ALL FOR ALLTRIM(Parameter_Mode) = "OUT"
				oParameterCollection.AddEntity( ;
				  RTRIM(SchemaCursor.Parameter_Name), ;
				  RTRIM(SchemaCursor.Data_Type), ;
				  NVL(SchemaCursor.Character_Maximum_Length, SchemaCursor.Numeric_Precision), ;
				  SchemaCursor.Numeric_Scale, ;
				  '', ;
				  THIS.MapParameter(SchemaCursor.Parameter_Mode) ;
				 )
			ENDSCAN
		ENDIF
		THIS.CloseTable("SchemaCursor")
	ENDFUNC

	
	FUNCTION OnBrowseData(cTableName, cOwner)
		LOCAL nSelect
		LOCAL nDataSessionID
		LOCAL cConnString
		LOCAL oException
		LOCAL lAsync
		LOCAL lBatch
		LOCAL cOwner
		
		nSelect = SELECT()
		
		cAlias = CHRTRAN(cTableName, ' !<>;:"[]+=-!@#$%^&*()?/.,{}\|', '')

		* retrieve data using SQL passthru
		* nDataSessionID = THIS.DataSessionID

		lAsync = SQLGETPROP(THIS.SQLHandle, "asynchronous")
		lBatch = SQLGETPROP(THIS.SQLHandle, "batchmode")

		SQLSETPROP(THIS.SQLHandle, "asynchronous", .F.)
		SQLSETPROP(THIS.SQLHandle, 'BatchMode', .T.)

		*SET DATASESSION TO 1

		TRY
			IF SQLEXEC(THIS.SQLHandle, "SELECT * FROM " + IIF(!EMPTY(cOwner), "[" + cOwner + "].", '') + "[" + cTableName + "]", cAlias) >= 0
				DO FORM BrowseForm WITH .T.
			ENDIF
		CATCH TO oException
			MESSAGEBOX(oException.Message)
		FINALLY
			* SET DATASESSION TO (nDataSessionID)

			SQLSETPROP(THIS.SQLHandle, "asynchronous", lAsync)
			SQLSETPROP(THIS.SQLHandle, 'BatchMode', lBatch)
		
			IF USED(cAlias)
				USE IN (cAlias)
			ENDIF
		ENDTRY

		SELECT (nSelect)
	ENDFUNC

	FUNCTION OnExecuteQuery(cSQL, cAlias)
		LOCAL cConnString
		LOCAL oException
		LOCAL i
		LOCAL j
		LOCAL nErrorCnt
		LOCAL nAliasCnt
		LOCAL nSetNum
		LOCAL nResultCnt
		LOCAL nMoreResults
		LOCAL lError
		LOCAL cErrorMsg
		LOCAL lAsync
		LOCAL lBatch
		LOCAL ARRAY aErrorList[1]
		LOCAL ARRAY aAliasList[1]
		LOCAL ARRAY aCountInfo[1]

		nSelect = SELECT()
		
		lError = .F.

		
		* this will hold collection of aliases created by the query
		oResultCollection = CREATEOBJECT("Collection")

		nSetNum = 0
		nAliasCnt = AUSED(aAliasList)
		FOR i = 1 TO nAliasCnt
			FOR j = 1 TO LEN(aAliasList[i, 1])
				* find first digit and strip off the number
				* for example, "Sqlresult5" -> break into "Sqlresult" and 5
				IF ISDIGIT(SUBSTR(aAliasList[i, 1], j, 1))
					IF UPPER(LEFT(aAliasList[i, 1], j - 1)) == UPPER(cAlias)
						nSetNum = MAX(SUBSTR(aAliasList[i, 1], j), nSetNum)
					ENDIF
					EXIT
				ENDIF
			ENDFOR
		ENDFOR
		

		* retrieve data using SQL passthru
		lAsync = SQLGETPROP(THIS.SQLHandle, "asynchronous")
		lBatch = SQLGETPROP(THIS.SQLHandle, "batchmode")
		
		SQLSETPROP(THIS.SQLHandle, "asynchronous", .F.)
		SQLSETPROP(THIS.SQLHandle, "BatchMode", .F.)
		TRY
			nResultCnt = SQLEXEC(THIS.SQLHandle, cSQL, cAlias + IIF(nSetNum > 0, TRANSFORM(nSetNum), ''), aCountInfo)
			THIS.ParseQueryResults(@aCountInfo)
			IF nResultCnt > 0
				DO WHILE .T.
					IF !EMPTY(aCountInfo[1, 1])
						oResultCollection.Add(cAlias + IIF(nSetNum > 0, TRANSFORM(nSetNum), ''))
					ENDIF

					nSetNum = nSetNum + 1
					nMoreResults = SQLMORERESULTS(THIS.SQLHandle, cAlias + TRANSFORM(nSetNum), aCountInfo) 

					IF nMoreResults == 2
						EXIT
					ENDIF

					THIS.ParseQueryResults(@aCountInfo)
				ENDDO
			ENDIF

			IF nResultCnt < 0
				THIS.SetError()
				lError = .T.
			ENDIF
		CATCH TO oException
			THIS.SetError(oException.Message)
			lError = .T.

		FINALLY
			SQLSETPROP(THIS.SQLHandle, "asynchronous", lAsync)
			SQLSETPROP(THIS.SQLHandle, 'BatchMode', lBatch)
			
		ENDTRY
		
		IF lError
			* oResultCollection = .NULL.
			THIS.AddToQueryOutput(THIS.LastError)
		ENDIF
		
		SELECT (nSelect)
		
		
		RETURN oResultCollection
	ENDFUNC
	
	* Show results to output
	FUNCTION ParseQueryResults(aCountInfo)
		LOCAL cMsg
		LOCAL i

		FOR i = 1 TO ALEN(aCountInfo, 1)
			DO CASE
			CASE EMPTY(aCountInfo[i, 1])
				* no result set (INSERT, UPDATE, or DELETE)
				THIS.AddToQueryOutput(QUERY_NORESULTS_LOC)
			CASE aCountInfo[i, 1] == '0'
				* no records or command failed
			OTHERWISE
				THIS.AddToQueryOutput(aCountInfo[i, 1] + ": " + IIF(aCountInfo[i, 2] = -1, "error", STRTRAN(RETRIEVE_COUNT_LOC, "##", TRANSFORM(aCountInfo[i, 2]))))
			ENDCASE
		ENDFOR
	ENDFUNC

	* Populate collection with available SQL servers
	FUNCTION OnGetAvailableServers(oServerCollection AS ServerCollection)
		LOCAL hEnv
		LOCAL hConn
		LOCAL cInString
		LOCAL cOutString
		LOCAL nLenOutString
		LOCAL ARRAY aServerList[1]

		DECLARE SHORT SQLBrowseConnect IN odbc32 ; 
		    INTEGER   ConnectionHandle, ; 
		    STRING    InConnectionString, ; 
		    INTEGER   StringLength1, ; 
		    STRING  @ OutConnectionString, ; 
		    INTEGER   BufferLength, ; 
		    INTEGER @ StringLength2Ptr
		    
		DECLARE SHORT SQLAllocHandle IN odbc32 ; 
		    INTEGER   HandleType, ; 
		    INTEGER   InputHandle, ; 
		    INTEGER @ OutputHandlePtr 
		    
		DECLARE SHORT SQLFreeHandle IN odbc32 ; 
		    INTEGER HandleType, ; 
		    INTEGER Handle 

		DECLARE SHORT SQLSetEnvAttr IN odbc32 ; 
		    INTEGER EnvironmentHandle, ; 
		    INTEGER Attribute, ; 
		    INTEGER ValuePtr, ; 
		    INTEGER StringLength 


		hEnv = 0
		hConn = 0
		cInString = SQL_DRIVER_STR
		cOutString = SPACE(DEFAULT_RESULT_SIZE)
		nLenOutString = 0

		TRY
			IF SQLAllocHandle(SQL_HANDLE_ENV, hEnv, @hEnv) == SQL_SUCCESS
				IF (SQLSetEnvAttr(hEnv, SQL_ATTR_ODBC_VERSION, SQL_OV_ODBC3, 0)) == SQL_SUCCESS
					IF SQLAllocHandle(SQL_HANDLE_DBC, hEnv, @hConn) == SQL_SUCCESS
						IF (SQLBrowseConnect(hConn, @cInString, LEN(cInString), @cOutString, DEFAULT_RESULT_SIZE, @nLenOutString)) == SQL_NEED_DATA
							nCnt = ALINES(aServerList, STREXTRACT(cOutString, '{', '}'), .T., ',')
							FOR i = 1 TO nCnt
								oServerCollection.AddEntity(aServerList[i])
							ENDFOR
						ENDIF
					ENDIF
				ENDIF
			ENDIF
		CATCH TO oException
			* ignore error, just return an empty collection of servers
		FINALLY
			IF hConn <> 0
				SQLFreeHandle(SQL_HANDLE_DBC, hConn)
			ENDIF
			IF hEnv <> 0
				SQLFreeHandle(SQL_HANDLE_ENV, hConn)
			ENDIF
		ENDTRY
	ENDFUNC

	FUNCTION OnGetDatabases(oDatabaseCollection AS DatabaseCollection)
		LOCAL oException
		LOCAL oDatabase

		TRY
			IF !ISNULL(THIS.ExecuteQuery("sp_helpdb", "SchemaCursor"))
				SELECT SchemaCursor
				SCAN ALL
					oDatabase = oDatabaseCollection.AddEntity(RTRIM(SchemaCursor.Name))
					oDatabase.Owner = RTRIM(SchemaCursor.Owner)
					oDatabase.Size = SchemaCursor.db_size
				ENDSCAN
			ENDIF
		CATCH TO oException
			MESSAGEBOX(oException.Message)
		ENDTRY
		THIS.CloseTable("SchemaCursor")
	
	ENDFUNC


	FUNCTION OnRunStoredProcedure(cStoredProcName, cOwner, oParamList)
		LOCAL cSQL
		LOCAL cValue
		LOCAL cParamList
		
		IF LEFT(cStoredProcName, 1) <> '['
			cStoredProcName = '[' + cStoredProcName + ']'
		ENDIF
		cSQL = "EXECUTE " + IIF(EMPTY(cOwner), '', "[" + cOwner + "].") + cStoredProcName
		cParamList = ''

		FOR i = 1 TO oParamList.Count
			IF INLIST(oParamList.Item(i).Direction, PARAM_INPUT, PARAM_INPUTOUTPUT, PARAM_OUTPUT)
				cValue = RTRIM(TRANSFORM(oParamList.Item(i).DefaultValue))
				IF UPPER(cValue) == "DEFAULT" OR UPPER(cValue) == "NULL"
					cParamList = cParamList + IIF(EMPTY(cParamList), ' ', ',') + oParamList.Item(i).Name + '=' + LOWER(cValue)
				ELSE
					IF INLIST(oParamList.Item(i).DataType, "nvarchar", "varchar", "nchar", "char", "text", "ntext")
						cParamList = cParamList + IIF(EMPTY(cParamList), ' ', ',') + oParamList.Item(i).Name + "='" + cValue + "'"
					ELSE
						IF !EMPTY(cValue)
							cParamList = cParamList + IIF(EMPTY(cParamList), ' ', ',') + oParamList.Item(i).Name + '=' + cValue
						ENDIF
					ENDIF
				ENDIF
			ENDIF
		ENDFOR
		IF !EMPTY(cParamList)
			cSQL = cSQL + ' ' + cParamList
		ENDIF

		DO FORM RunQuery WITH THIS, cSQL, .T.
	ENDFUNC


	FUNCTION GenerateScripts(cTableName)
		IF EMPTY(EVL(cTableName, ''))
			THIS.ShowSQLDialog("Generate Scripts", 'Database')
		ELSE
			THIS.ShowSQLDialog("Generate Scripts", 'Table', cTableName)
		ENDIF
	ENDFUNC


	* Display SQL Enterprise Manager dialog
	* 	<cCmdName> = namespace command to execute (e.g. "Generate Scripts")
	* 	[cObjType] = {"Server", "Database", "Table", "View", "Procedure", "Function"}
	*
	* Examples:
	*	o.ShowSQLDialog("Generate Scripts", 'Table', "EISFAC")
	*	o.ShowSQLDialog("Generate Scripts", 'D')
	*
	FUNCTION ShowSQLDialog(xCmdName, cObjType, cObjName)
		LOCAL oSQLNS
		LOCAL oServer
		LOCAL oDatabases
		LOCAL oDatabase
		LOCAL oTables
		LOCAL oTable
		LOCAL oViews
		LOCAL oView
		LOCAL oStoredProcs
		LOCAL oStoreProc
		LOCAL oNSObject
		LOCAL oRootObject

		cObjType = UPPER(EVL(cObjType, "Server"))
		
		oSQLNS = CREATEOBJECT("SQLNS.SQLNamespace")
		oSQLNS.Initialize(DATAEXPLORER_LOC, SQLNSROOTTYPE_SERVER, THIS.GetNameSpaceConnectionString())

		* drill in until we get to the object we want to operate on		
		oServer = oSQLNS.GetRootItem()

		IF cObjType == 'SERVER'  && server
			oRootObject = oServer
		ELSE
			oDatabases = oSQLNS.GetFirstChildItem(oServer, SQLNSOBJECTTYPE_DATABASES)
			oDatabase  = oSQLNS.GetFirstChildItem(oDatabases, SQLNSOBJECTTYPE_DATABASE, THIS.DatabaseName)
			
			IF cObjType == 'DATABASE' && database
				oRootObject = oDatabase
			ELSE
				DO CASE
				CASE cObjType == 'TABLES'
					oRootObject = oSQLNS.GetFirstChildItem(oDatabase, SQLNSOBJECTTYPE_DATABASE_TABLES)

				CASE cObjType == 'VIEWS' && view
					oRootObject = oSQLNS.GetFirstChildItem(oDatabase, SQLNSOBJECTTYPE_DATABASE_VIEWS)

				CASE cObjType == 'PROCEDURES' && stored procedure
					oRootObject = oSQLNS.GetFirstChildItem(oDatabase, SQLNSOBJECTTYPE_DATABASE_SPS)

				CASE cObjType == 'FUNCTIONS' && function
					oRootObject = oSQLNS.GetFirstChildItem(oDatabase, SQLNSOBJECTTYPE_DATABASE_UDFS)

				CASE cObjType == 'TABLE' && table
					oTables = oSQLNS.GetFirstChildItem(oDatabase, SQLNSOBJECTTYPE_DATABASE_TABLES)
					oTable  = oSQLNS.GetFirstChildItem(oTables, SQLNSOBJECTTYPE_DATABASE_TABLE, cObjName)

					oRootObject = oTable

				CASE cObjType == 'VIEW' && view
					oViews = oSQLNS.GetFirstChildItem(oDatabase, SQLNSOBJECTTYPE_DATABASE_VIEWS)
					oView  = oSQLNS.GetFirstChildItem(oViews, SQLNSOBJECTTYPE_DATABASE_VIEW, cObjName)

					oRootObject = oView

				CASE cObjType == 'PROCEDURE' && stored procedure
					oStoredProcs = oSQLNS.GetFirstChildItem(oDatabase, SQLNSOBJECTTYPE_DATABASE_SPS)
					oStoredProc  = oSQLNS.GetFirstChildItem(oStoredProcs, SQLNSOBJECTTYPE_DATABASE_SP, cObjName)

					oRootObject = oStoredProc

				CASE cObjType == 'FUNCTION' && function
					oFunctions = oSQLNS.GetFirstChildItem(oDatabase, SQLNSOBJECTTYPE_DATABASE_UDFS)
					oFunction  = oSQLNS.GetFirstChildItem(oStoredProcs, SQLNSOBJECTTYPE_DATABASE_UDF, cObjName)

					oRootObject = oStoredProc
				ENDCASE
			ENDIF
		ENDIF
		
		oNSObject = oSQLNS.GetSQLNamespaceObject(oRootObject)
		
		IF VARTYPE(xCmdName) == 'N'
			oNSObject.ExecuteCommandByID(xCmdName, _SCREEN.Hwnd)
		ELSE	
			oNSObject.ExecuteCommandByName(xCmdName, _SCREEN.Hwnd)
		ENDIF
	ENDFUNC	

ENDDEFINE


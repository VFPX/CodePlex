* <summary>
*	Data Management for ADO connections.
* </summary>

#include "DataExplorer.h"
#include "foxpro.h"
#include "adovfp.h"


DEFINE CLASS ADODatabaseMgmt AS DatabaseMgmt OF DataMgmt.prg
	PROTECTED lCriteriaSupported

	oADO = .NULL.  && reference to ADO Connection

	PromptPassword = .T.
	ConnectionString = ''
	CustomPassword = .F.
	CustomConnection = .F.
	
	Owner = ''
	UserID = ''
	UserName = ''

	ConnectTimeOut   = ADOCONNECT_TIMEOUT_DEFAULT 
	QueryTimeOut     = ADOQUERY_TIMEOUT_DEFAULT
	
	DBMSName = ''
	DBMSVersion = ''
	
	nObjectLevel = 1	&& 1-My, 2-User, 3-All (including System)

	lCriteriaSupported = .T.
	
	nEntityCnt = 0
	nEntityMax = 0
	DIMENSION aEntity[1, 2]
	
	PROCEDURE Init()
		THIS.oADO = CREATEOBJECT("ADODB.Connection")
	ENDPROC
	
	PROCEDURE Destroy()
		THIS.ADOClose()
		THIS.oADO = .NULL.
	ENDPROC

	PROCEDURE Disconnect()
		LOCAL oaADO AS ADODB.Connection

		IF VARTYPE(THIS.oADO) == 'O'
			THIS.ADOClose()
		ENDIF
		THIS.oADO = .NULL.
	ENDPROC	
	
	FUNCTION Connect(cConnectionString) AS Boolean
		LOCAL i
		LOCAL cPropName
		LOCAL lSuccess
		LOCAL oException
		
		THIS.ServerName = ''
		THIS.DatabaseName = ''

		THIS.ConnectionString = cConnectionString

		TRY
			THIS.oADO.ConnectionString = cConnectionString
		CATCH TO oException
			MESSAGEBOX(oException.Message)
			THIS.oADO.ConnectionString = ''
		ENDTRY

		IF THIS.ADOOpen()
			FOR i = 0 TO (THIS.oADO.Properties.Count - 1)
				cPropName = UPPER(THIS.oADO.Properties(i).Name)

				DO CASE
				CASE cPropName = "DATA SOURCE"
					IF !ISNULL(THIS.oADO.Properties(i).Value)
						THIS.ServerName = THIS.oADO.Properties(i).Value
					ENDIF

				CASE cPropName = "INITIAL CATALOG"
					IF !ISNULL(THIS.oADO.Properties(i).Value)
						THIS.DatabaseName = THIS.oADO.Properties(i).Value
					ENDIF

				CASE cPropName = "CURRENT CATALOG"
					IF !ISNULL(THIS.oADO.Properties(i).Value)
						THIS.DatabaseName = THIS.oADO.Properties(i).Value
					ENDIF

				CASE cPropName = "DBMS NAME"
					IF !ISNULL(THIS.oADO.Properties(i).Value)
						THIS.DBMSName = THIS.oADO.Properties(i).Value
					ENDIF

				CASE cPropName = "DBMS VERSION"
					IF !ISNULL(THIS.oADO.Properties(i).Value)
						THIS.DBMSVersion = THIS.oADO.Properties(i).Value
					ENDIF

				CASE cPropName = "USER NAME"
					IF !ISNULL(EVL(THIS.oADO.Properties(i).Value, .NULL.))
						THIS.UserName = THIS.oADO.Properties(i).Value
					ENDIF

				CASE cPropName = "USER ID"
					IF !ISNULL(EVL(THIS.oADO.Properties(i).Value, .NULL.))
						THIS.UserID = THIS.oADO.Properties(i).Value
					ENDIF

				CASE cPropName = "PROVIDER NAME"

				ENDCASE
			ENDFOR

			IF ATC("FOXPRO",THIS.DBMSName)#0			
				THIS.lCriteriaSupported = .F.
			ENDIF

			THIS.ADOClose()
			lSuccess = .T.
		ENDIF
		RETURN lSuccess
	ENDFUNC

	FUNCTION SetConnValue(cConnectionString, cKeywords, cValue, lForce)
		LOCAL i
		LOCAL j
		LOCAL nKeyCnt
		LOCAL nCnt
		LOCAL cWord
		LOCAL cNewConnectionString
		LOCAL lFound
		LOCAL ARRAY aConnString[1]
		LOCAL ARRAY aKeyList[1]
		
		nKeyCnt = ALINES(aKeyList, cKeywords, 0, '|')
		
		lFound = .F.
		cNewConnectionString = ''
		nCnt = ALINES(aConnString, cConnectionString, .T., ';')
		FOR i = 1 TO nCnt
			lFound = .F.
			IF nKeyCnt > 0 AND !EMPTY(aConnString[i])
				cWord = ALLTRIM(LOWER(CHRTRAN(aConnString[i], ' ', '')))
				IF ATC('=', cWord) > 0
					cWord = ALLTRIM(LEFT(cWord, ATC('=', cWord) - 1))
				ENDIF
				
				FOR j = 1 TO nKeyCnt
					IF cWord == LOWER(aKeyList[j])
						lFound = .T.
						EXIT
					ENDIF
				ENDFOR
				IF lFound
					cNewConnectionString = cNewConnectionString + IIF(EMPTY(cNewConnectionString), '', ';') + ALLTRIM(LEFT(aConnString[i], ATC('=', aConnString[i]) - 1)) + '=' + cValue
					nKeyCnt = 0
				ENDIF
			ENDIF

			IF !lFound
				cNewConnectionString = cNewConnectionString + IIF(EMPTY(cNewConnectionString), '', ';') + aConnString[i]
			ENDIF
		ENDFOR
		
		IF lForce AND !EMPTY(cValue) AND nKeyCnt > 0
			cNewConnectionString = cNewConnectionString + IIF(EMPTY(cNewConnectionString), '', ';') + aKeyList[1] + '=' + cValue
		ENDIF
		
		RETURN cNewConnectionString
	ENDFUNC


	FUNCTION GetConnValue(cConnectionString, cKeywords)
		LOCAL i
		LOCAL j
		LOCAL nKeyCnt
		LOCAL nCnt
		LOCAL cWord
		LOCAL cValue
		LOCAL ARRAY aConnString[1]
		LOCAL ARRAY aKeyList[1]
		
		nKeyCnt = ALINES(aKeyList, cKeywords, 0, '|')
				
		cValue = ''
		nCnt = ALINES(aConnString, cConnectionString, .T., ';')
		FOR i = 1 TO nCnt
			lFound = .F.
			IF nKeyCnt > 0 AND !EMPTY(aConnString[i])
				cWord = ALLTRIM(LOWER(CHRTRAN(aConnString[i], ' ', '')))
				IF ATC('=', cWord) > 0
					cWord = ALLTRIM(LEFT(cWord, ATC('=', cWord) - 1))
				ENDIF
				
				FOR j = 1 TO nKeyCnt
					IF cWord == LOWER(aKeyList[j])
						cValue = ALLTRIM(SUBSTR(aConnString[i], ATC('=', aConnString[i]) + 1))
						EXIT
					ENDIF
				ENDFOR
			ENDIF

			IF !EMPTY(cValue)
				EXIT
			ENDIF
		ENDFOR
		

		RETURN cValue
	ENDFUNC


	FUNCTION ADOOpen()
		LOCAL oException
		LOCAL lTryAgain
		LOCAL nUserIDTryAgain
		LOCAL cPassword
		LOCAL oRetValue
		LOCAL cUserID
		LOCAL cConnectionString
		LOCAL oDataLink
		LOCAL oADOConn
		LOCAL lShowDialog
		LOCAL lNoUserInConnString
		LOCAL ARRAY aConnString[1]

		cConnectionString = THIS.ConnectionString

		cPassword = THIS.UserPassword
		cUserID = EVL(THIS.UserID, THIS.UserName)

		lTryAgain = .T.
		nUserIDTryAgain=0
		lNoUserInConnString = ATC("user id=",cConnectionString)=0 AND;
			ATC("userid=",cConnectionString)=0 AND;
			ATC("uid=",cConnectionString)=0

		DO WHILE lTryAgain
			lShowDialog = .F.

			IF THIS.CustomPassword
				cConnectionString = THIS.SetConnValue(cConnectionString, "password|pwd", cPassword, .T.)			
								
				* Need to handle scenario where User ID not specified. Each provider uses a different
				* naming convention for user id so let's try common ones without reprompting each time.
				* This is only an issue if user name is not included from original string.
				
				IF lNoUserInConnString
					nUserIDTryAgain = nUserIDTryAgain + 1
				ENDIF

				DO CASE
				CASE nUserIDTryAgain=1
					cConnectionString = THIS.SetConnValue(cConnectionString, "userid", cUserID, .T.)
				CASE nUserIDTryAgain=2
					cConnectionString = THIS.SetConnValue(cConnectionString, "user id", cUserID, .T.)
				CASE nUserIDTryAgain=3
					cConnectionString = THIS.SetConnValue(cConnectionString, "uid", cUserID, .T.)
				OTHERWISE
					cConnectionString = THIS.SetConnValue(cConnectionString, "userid|uid", cUserID, .T.)
				ENDCASE
			ELSE
				cPassword = THIS.GetConnValue(cConnectionString, "password|pwd")
				cUserID = THIS.GetConnValue(cConnectionString, "userid|uid")
			ENDIF

			TRY
				THIS.oADO.ConnectionString = cConnectionString
				THIS.oADO.ConnectionTimeout = THIS.ConnectTimeout
				THIS.oADO.CommandTimeout = THIS.QueryTimeout
				THIS.oADO.Open()
				lTryAgain = .F.
				
				IF THIS.CustomPassword
					THIS.UserPassword = cPassword
					THIS.UserID = cUserID
				ENDIF
				
			CATCH TO oException
				IF THIS.PromptPassword AND nUserIDTryAgain<4 AND;
					(ATC("log",oException.Message)>0 OR;
					 ATC("password",oException.Message)>0 OR;
					 ATC("user",oException.Message)>0)
					
					IF BETWEEN(nUserIDTryAgain,1,2)
						cConnectionString = THIS.ConnectionString
						THIS.CustomPassword = .T.
					ELSE
						DO FORM GetPassword WITH cUserID, IIF(ISNULL(cPassword),"",cPassword) TO oRetValue
						IF VARTYPE(oRetValue) == 'O'
							cUserID = oRetValue.UserName
							cPassword = oRetValue.Password
							THIS.CustomPassword = .T.
							nUserIDTryAgain = 0
						ELSE
							lTryAgain = .F.
						ENDIF
					ENDIF	
				ELSE
					MESSAGEBOX(oException.Message)
					lShowDialog = .T.
				ENDIF
			ENDTRY

			IF lShowDialog
				TRY
					oDataLink = CREATEOBJECT("DataLinks")
					oADOConn = CREATEOBJECT('ADODB.Connection')
					oADOConn.ConnectionString = cConnectionString
					oDataLink.PromptEdit(oADOConn)
					IF VARTYPE(oADOConn) == 'O' AND TYPE("oADOConn.ConnectionString") == 'C' AND !(oADOConn.ConnectionString == cConnectionString)
						THIS.CustomConnection = .T.
						cConnectionString = oADOConn.ConnectionString
						THIS.ConnectionString = cConnectionString
					ELSE
						lTryAgain = .F.
					ENDIF
				CATCH TO oException
					cConnectionString = ''
				ENDTRY
			ENDIF
			
		ENDDO
		
		RETURN THIS.oADO.State == ADSTATEOPEN
	ENDFUNC
	
	FUNCTION ADOClose()
		IF TYPE("THIS.oADO") == 'O' AND !ISNULL(THIS.oADO) AND THIS.oADO.State == ADSTATEOPEN
			THIS.oADO.Close()
		ENDIF
	ENDFUNC
	
	
	* -- we do this intermediate array stuff so we can sort before
	* -- calling AddEntity method on the collections.
	PROCEDURE ClearEntities()
		THIS.nEntityCnt = 0
		THIS.nEntityMax = 0
		DIMENSION THIS.aEntity[1, 3]
	ENDPROC
	PROCEDURE AddEntity(cValue1, cValue2, cValue3)
		THIS.nEntityCnt = THIS.nEntityCnt + 1
		IF THIS.nEntityCnt > THIS.nEntityMax
			THIS.nEntityMax = THIS.nEntityMax + 100
			DIMENSION THIS.aEntity[THIS.nEntityMax, 3]
		ENDIF
		THIS.aEntity[THIS.nEntityCnt, 1] = cValue1
		THIS.aEntity[THIS.nEntityCnt, 2] = NVL(cValue2, '')
		THIS.aEntity[THIS.nEntityCnt, 3] = NVL(cValue3, '')
	ENDPROC

	PROCEDURE LoadEntities(oEntityCollection, nDimensions)
		LOCAL i
		
		IF THIS.nEntityCnt > 0
			DIMENSION THIS.aEntity[THIS.nEntityCnt, 3]
			=ASORT(THIS.aEntity, 1)
			IF VARTYPE(nDimensions) <> 'N' OR nDimensions == 0
				nDimensions = 1
			ENDIF
			DO CASE
			CASE nDimensions == 1
				FOR i = 1 TO THIS.nEntityCnt
					oEntityCollection.AddEntity(THIS.aEntity[i, 1])
				ENDFOR
			CASE nDimensions == 2
				FOR i = 1 TO THIS.nEntityCnt
					oEntityCollection.AddEntity(THIS.aEntity[i, 1], THIS.aEntity[i, 2])
				ENDFOR
			CASE nDimensions == 3
				FOR i = 1 TO THIS.nEntityCnt
					oEntityCollection.AddEntity(THIS.aEntity[i, 1], THIS.aEntity[i, 2], THIS.aEntity[i, 3])
				ENDFOR
			ENDCASE
		ENDIF
		THIS.ClearEntities()
	ENDPROC

	
	FUNCTION OpenSchema(cSchemaType, aCriteria)
		LOCAL oRS
		LOCAL lSuccess
		LOCAL oException
		
		lSuccess = .F.
		IF THIS.lCriteriaSupported AND PCOUNT() > 1
			TRY
				oRS = THIS.oADO.OpenSchema(cSchemaType, @aCriteria)
				lSuccess = .T.
			CATCH TO oException
				* THIS.lCriteriaSupported = .F. && don't try again if we got an error the first time
			ENDTRY
		ENDIF
		
		IF !lSuccess
			* try again without criteria because not all providers support it
			TRY
				oRS = THIS.oADO.OpenSchema(cSchemaType)
				lSuccess = .T.
			CATCH TO oException
				* ignore error because it's probably saying that provider does not support
				* the operation
				* MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION)
			ENDTRY
		ENDIF

		RETURN oRS
	ENDFUNC

	
	FUNCTION OnGetTables(oTableCollection AS TableCollection)
		LOCAL oRS AS ADODB.RecordSet
		LOCAL cOwner
		LOCAL ARRAY aCriteria[4]
		aCriteria[1] = EVL(THIS.DatabaseName, .NULL.)
		aCriteria[2] = .NULL. && EVL(THIS.Owner, .NULL.)
		aCriteria[3] = .NULL.
		aCriteria[4] = "TABLE"
		
		IF THIS.ADOOpen()
			oRS = THIS.OpenSchema(ADSCHEMATABLES, @aCriteria)
			IF VARTYPE(oRS) == 'O'
				IF !THIS.lCriteriaSupported
					oRS.Filter = "TABLE_TYPE = 'TABLE'"
				ENDIF
				DO WHILE !oRS.EOF()
					cOwner = oRS.Fields('TABLE_SCHEMA').Value
					THIS.AddEntity(oRS.Fields('TABLE_NAME').Value,"", cOwner)
					oRS.MoveNext()
				ENDDO
				oRS.Close()
			ENDIF
			THIS.ADOClose()
			THIS.LoadEntities(oTableCollection,3)
		ENDIF

	ENDFUNC

	FUNCTION OnGetViews(oViewCollection AS ViewCollection)
		LOCAL oRS AS ADODB.RecordSet
		LOCAL cOwner
		LOCAL ARRAY aCriteria[4]

		aCriteria[1] = EVL(THIS.DatabaseName, .NULL.)
		aCriteria[2] = EVL(THIS.Owner, .NULL.)
		aCriteria[3] = .NULL.
		aCriteria[4] = "VIEW"

		IF THIS.ADOOpen()
			oRS = THIS.OpenSchema(ADSCHEMATABLES, @aCriteria)
			IF VARTYPE(oRS) == 'O'
				IF !THIS.lCriteriaSupported
					oRS.Filter = "TABLE_TYPE = 'VIEW'"
				ENDIF
				DO WHILE !oRS.EOF()
					cOwner = oRS.Fields('TABLE_SCHEMA').Value
					THIS.AddEntity(oRS.Fields('TABLE_NAME').Value, cOwner)
					oRS.MoveNext()
				ENDDO
				oRS.Close()
			ENDIF
			THIS.ADOClose()
			THIS.LoadEntities(oViewCollection, 2)
		ENDIF

	ENDFUNC

	FUNCTION OnGetStoredProcedures(oStoredProcCollection AS StoredProcCollection)
		LOCAL oRS AS ADODB.RecordSet
		LOCAL cOwner
		LOCAL ARRAY aCriteria[4]

		aCriteria[1] = EVL(THIS.DatabaseName, .NULL.)
		aCriteria[2] = EVL(THIS.Owner, .NULL.)
		aCriteria[3] = .NULL.
		aCriteria[4] = .NULL.
		IF THIS.ADOOpen()
			oRS = THIS.OpenSchema(ADSCHEMAPROCEDURES, @aCriteria)
			IF VARTYPE(oRS) == 'O'
				DO WHILE !oRS.EOF()
					* Available fields:
					* 	PROCEDURE_CATALOG
					*	PROCEDURE_SCHEMA
					*	PROCEDURE_NAME
					*	PROCEDURE_TYPE
					*	PROCEDURE_DEFINITION
					*	DESCRIPTION
					*	DATE_CREATED
					
					* SQL Server returns Procedure names like this: 
					*	ProcNameA;0
					*	ProcNameB;1
					* 
					* so we need to strip off the group at the end
					*
					IF !LOWER(oRS.Fields('PROCEDURE_SCHEMA').Value) == "sys" AND;
					  ATC("Microsoft SQL Server",THIS.dbmsname)#0
						THIS.AddEntity(oRS.Fields('PROCEDURE_NAME').Value, oRS.Fields('PROCEDURE_SCHEMA').Value)
					ENDIF
					oRS.MoveNext()
				ENDDO
				oRS.Close()
			ENDIF
			THIS.ADOClose()

			THIS.LoadEntities(oStoredProcCollection, 2)
		ENDIF
	ENDFUNC
	
	* given an ADO parameter type (in/out, etc) map it to our internal types
	FUNCTION MapParameter(nADOParamType)
		LOCAL nParamType
		
		IF VARTYPE(nADOParamType) <> 'N'
			nParamType = PARAM_UNKNOWN
		ELSE
			DO CASE
			CASE nADOParamType == ADPARAMINPUT
				nParamType = PARAM_INPUT
			CASE nADOParamType == ADPARAMOUTPUT
				nParamType = PARAM_OUTPUT
			CASE nADOParamType == ADPARAMINPUTOUTPUT
				nParamType = PARAM_INPUTOUTPUT
			CASE nADOParamType == ADPARAMRETURNVALUE
				nParamType = PARAM_RETURNVALUE
			OTHERWISE
				nParamType = PARAM_UNKNOWN
			ENDCASE
		ENDIF
				
		RETURN nParamType
	ENDFUNC

	FUNCTION OnGetParameters(oParameterCollection AS ParameterCollection, cStoredProcName AS String, cOwner AS String)
		LOCAL oRS AS ADODB.RecordSet
		LOCAL ARRAY aCriteria[4]
		LOCAL nParamType
		LOCAL lSuccess
		LOCAL nDirection
		
		aCriteria[1] = EVL(THIS.DatabaseName, .NULL.)
		aCriteria[2] = EVL(THIS.Owner, .NULL.)
		aCriteria[3] = cStoredProcName
		aCriteria[4] = .NULL.
		
		lSuccess = .F.
		IF THIS.ADOOpen()
			oRS = THIS.OpenSchema(ADSCHEMAPROCEDUREPARAMETERS, @aCriteria)
			IF VARTYPE(oRS) == 'O'
				lSuccess = .T.
				oRS.Filter = "PROCEDURE_NAME = '" + cStoredProcName + "'"
				DO WHILE !oRS.EOF()
					nDirection = THIS.MapParameter(oRS.Fields("PARAMETER_TYPE").Value)
					IF nDirection <> PARAM_RETURNVALUE
						oParameterCollection.AddEntity( ;
						  oRS.Fields("PARAMETER_NAME").Value, ;
						  THIS.GetDataType(oRS.Fields("DATA_TYPE").Value), ;
						  NVL(oRS.Fields("CHARACTER_MAXIMUM_LENGTH").Value, oRS.Fields("NUMERIC_PRECISION").Value), ;
						  oRS.Fields("NUMERIC_SCALE").Value, ;
						  '', ;
						  nDirection ;
						 )
					ENDIF

					oRS.MoveNext()
				ENDDO
				oRS.Close()
			ENDIF
			THIS.ADOClose()
		ENDIF
		
		RETURN lSuccess
	ENDFUNC

	* Not supported by ADO
	FUNCTION OnGetFunctions(oFunctionCollection AS FunctionCollection)
		RETURN .F.
	ENDFUNC
	FUNCTION OnGetFunctionParameters(oParameterCollection AS ParameterCollection, cFunctionName AS String, cOwner AS String)
		RETURN .F.
	ENDFUNC

	FUNCTION OnGetSchema(oColumnCollection AS ColumnCollection, cTableName, cOwner)
		LOCAL oRS AS ADODB.RecordSet
		LOCAL ARRAY aCriteria[3]
		aCriteria[1] = EVL(THIS.DatabaseName, .NULL.)
		aCriteria[2] = EVL(THIS.Owner, .NULL.)
		aCriteria[3] = cTableName

		IF THIS.ADOOpen()
			oRS = THIS.OpenSchema(ADSCHEMACOLUMNS, @aCriteria)
			IF VARTYPE(oRS) == 'O'
				IF !THIS.lCriteriaSupported
					oRS.Filter = "TABLE_NAME = '" + cTableName + "'"
				ENDIF
				DO WHILE !oRS.EOF()
					oColumnCollection.AddEntity( ;
					  oRS.Fields("COLUMN_NAME").Value, ;  && column name
					  THIS.GetDataType(oRS.Fields("DATA_TYPE").Value), ;  && data type
					  NVL(oRS.Fields("NUMERIC_PRECISION").Value, ;
					  NVL(oRS.Fields("CHARACTER_MAXIMUM_LENGTH").Value, oRS.Fields("DATETIME_PRECISION").Value)), ;  && length
					  NVL(oRS.Fields("NUMERIC_SCALE").Value, 0), ;  && numeric scale
					  .F., ;
					  IIF(oRS.Fields("COLUMN_HASDEFAULT").Value, oRS.Fields("COLUMN_DEFAULT").Value, '') ;
					 )

					oRS.MoveNext()
				ENDDO
				oRS.Close()
			ENDIF
			THIS.ADOClose()
		ENDIF
	ENDFUNC

	FUNCTION OnGetStoredProcedureDefinition(cStoredProcName, cOwner) AS String
		LOCAL oRS
		LOCAL cDefinition
		LOCAL ARRAY aCriteria[4]

		aCriteria[1] = EVL(THIS.DatabaseName, .NULL.)
		aCriteria[2] = EVL(THIS.Owner, .NULL.)
		aCriteria[3] = .NULL.
		aCriteria[4] = .NULL.
		
		cDefinition = ''
		IF THIS.ADOOpen()
			oRS = THIS.OpenSchema(ADSCHEMAPROCEDURES, @aCriteria)
			IF VARTYPE(oRS) == 'O'
				DO WHILE !oRS.EOF()
					IF oRS.Fields('PROCEDURE_NAME').Value == cStoredProcName AND NVL(oRS.Fields('PROCEDURE_SCHEMA').Value, '') == cOwner 
						cDefinition = NVL(oRS.Fields('PROCEDURE_DEFINITION').Value, '')
						EXIT
					ENDIF
					oRS.MoveNext()
				ENDDO
				oRS.Close()
			ENDIF
			THIS.ADOClose()
		ENDIF

		RETURN cDefinition
	ENDFUNC
	
	FUNCTION OnGetFunctionDefinition(cFunctionName, cOwner) AS String
	ENDFUNC

	FUNCTION OnGetViewDefinition(cViewName, cOwner) AS String
	ENDFUNC

	PROTECTED FUNCTION GetDataType(nDataType)
		LOCAL cDataType
		
		DO CASE
		CASE nDataType = ADEMPTY
			cDataType = "Empty"
		CASE nDataType = ADTINYINT
			cDataType = "TinyInt"
		CASE nDataType = ADSMALLINT
			cDataType = "SmallInt"
		CASE nDataType = ADINTEGER
			cDataType = "Integer"
		CASE nDataType = ADBIGINT
			cDataType = "BigInt"
		CASE nDataType = ADUNSIGNEDTINYINT
			cDataType = "UnsignedTinyInt"
		CASE nDataType = ADUNSIGNEDSMALLINT
			cDataType = "UnsignedSmallInt"
		CASE nDataType = ADUNSIGNEDINT
			cDataType = "UnsignedInt"
		CASE nDataType = ADUNSIGNEDBIGINT
			cDataType = "UnsignedBigInt"
		CASE nDataType = ADSINGLE
			cDataType = "Single"
		CASE nDataType = ADDOUBLE
			cDataType = "Double"
		CASE nDataType = ADCURRENCY
			cDataType = "Currency"
		CASE nDataType = ADDECIMAL
			cDataType = "Decimal"
		CASE nDataType = ADNUMERIC
			cDataType = "Numeric"
		CASE nDataType = ADBOOLEAN
			cDataType = "Boolean"
		CASE nDataType = ADERROR
			cDataType = "Error"
		CASE nDataType = ADUSERDEFINED
			cDataType = "UserDefined"
		CASE nDataType = ADVARIANT
			cDataType = "Variant"
		CASE nDataType = ADIDISPATCH
			cDataType = "Dispatch"
		CASE nDataType = ADIUNKNOWN
			cDataType = "IUnknown"
		CASE nDataType = ADGUID
			cDataType = "GUID"
		CASE nDataType = ADDATE
			cDataType = "Date"
		CASE nDataType = ADDBDATE
			cDataType = "Date"
		CASE nDataType = ADDBTIME
			cDataType = "Time"
		CASE nDataType = ADDBTIMESTAMP
			cDataType = "TimeStamp"
		CASE nDataType = ADBSTR
			cDataType = "BStr"
		CASE nDataType = ADCHAR
			cDataType = "Char"
		CASE nDataType = ADVARCHAR
			cDataType = "VarChar"
		CASE nDataType = ADLONGVARCHAR
			cDataType = "LongVarChar"
		CASE nDataType = ADWCHAR
			cDataType = "WChar"
		CASE nDataType = ADVARWCHAR
			cDataType = "VarWChar"
		CASE nDataType = ADLONGVARWCHAR
			cDataType = "LongVarWChar"
		CASE nDataType = ADBINARY
			cDataType = "Binary"
		CASE nDataType = ADVARBINARY
			cDataType = "VarBinary"
		CASE nDataType = ADLONGVARBINARY
			cDataType = "LongVarBinary"
		CASE nDataType = ADCHAPTER
			cDataType = "Chapter"
		OTHERWISE
			cDataType = "Unknown"
		ENDCASE
		
		RETURN cDataType
	ENDFUNC
	
	
	FUNCTION OnBrowseData(cTableName, cOwner)
		LOCAL nSelect
		LOCAL nDataSessionID
		LOCAL oException
		LOCAL oRS AS ADODB.Recordset
		LOCAL oCA

		nSelect = SELECT()	
		cAlias = CHRTRAN(cTableName, ' !<>;:"[]+=-!@#$%^&*()?/.,{}\|', '')
		IF ATC(" ",cTableName)>0
			cTableName = ["] + cTableName + ["]
		ENDIF
		
		TRY
			IF THIS.ADOOpen()
				oRS = CREATEOBJECT("ADODB.RecordSet")
				oRS.Open(cTableName, THIS.oADO, ADOPENKEYSET, ADLOCKREADONLY, ADCMDTABLE)

				oCA = CREATEOBJECT("CursorAdapter")
				oCA.DataSourceType = "ADO"
				oCA.DataSource = oRS
				oCA.Alias = cAlias

				IF oCA.CursorFill(.F., .F., -1, oRS)
					SELECT (cAlias)
					DO FORM BrowseForm WITH .T.
					USE IN (cAlias)
				ENDIF
			ENDIF
		CATCH TO oException
			MESSAGEBOX(oException.Message)
		FINALLY
			THIS.ADOClose()
		ENDTRY

		SELECT (nSelect)
	ENDFUNC
	
	FUNCTION OnGetDatabases(oDatabaseCollection AS DatabaseCollection)
	ENDFUNC

	FUNCTION OnExecuteQuery(cSQL, cAlias)
		LOCAL cConnString
		LOCAL oException
		LOCAL nErrorCnt
		LOCAL lError
		LOCAL cErrorMsg
		LOCAL oRS
		LOCAL oCommand
		LOCAL oCA
		LOCAL ARRAY aErrorInfo[1]
		LOCAL ARRAY aErrorList[1]

		nSelect = SELECT()
		
		lError = .F.

		
		* this will hold collection of aliases created by the query
		oResultCollection = .NULL.

		TRY
			IF THIS.ADOOpen()
				oRS = CREATEOBJECT("ADODB.Command")
				* oRS.Open(cTableName, THIS.oADO, ADOPENKEYSET, ADLOCKREADONLY, ADCMDTABLE)
				
				oCommand = CREATEOBJECT("ADODB.Command")

				oCA = CREATEOBJECT("CursorAdapter")
				oCA.DataSourceType = "ADO"
				oCA.DataSource = CREATEOBJECT("ADODB.RecordSet")
				oCA.DataSource.CursorLocation = ADUSECLIENT
				oCA.DataSource.LockType = ADLOCKOPTIMISTIC
				oCA.DataSource.ActiveConnection = THIS.oADO
				
				oCA.Alias = "ResultCursor"
				oCA.SelectCmd = cSQL


				IF oCA.CursorFill(.F., .F., -1)
					oCA.CursorDetach()
					* this will hold collection of aliases created by the query
					oResultCollection = CREATEOBJECT("Collection")
					oResultCollection.Add(oCA.Alias)

					THIS.AddToQueryOutput(oCA.Alias + ": " + STRTRAN(RETRIEVE_COUNT_LOC, "##", TRANSFORM(RECCOUNT(oCA.Alias))))
				ELSE
					IF AERROR(aErrorInfo) > 0
						THROW aErrorInfo[2]
					ELSE
						THIS.AddToQueryOutput(QUERY_NORESULTS_LOC)
					ENDIF
				ENDIF
			ENDIF
		
		CATCH TO oException
			THIS.SetError(EVL(oException.UserValue, oException.Message))
			lError = .T.

		FINALLY
			THIS.ADOClose()
		ENDTRY
		
		IF lError
			THIS.AddToQueryOutput(THIS.LastError)
		ENDIF
		
		SELECT (nSelect)
		
		
		RETURN oResultCollection
	ENDFUNC
	
	PROCEDURE OnRunStoredProcedure(cStoredProcName, cOwner, oParamList)

		LOCAL cSQL
		LOCAL cValue
		LOCAL cParamList
		
		IF AT(';', cStoredProcName) > 0
			cStoredProcName = ALLTRIM(LEFT(cStoredProcName, AT(';', cStoredProcName) - 1))
		ENDIF

		cSQL = "EXECUTE " + cStoredProcName
		
		IF VARTYPE(oParamList) == 'O'
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
		ENDIF

		DO FORM RunQuery WITH THIS, cSQL, .T.
	ENDPROC

	FUNCTION OnGetRunQuery(oCurrentNode)
		RETURN ''
	ENDFUNC 
ENDDEFINE

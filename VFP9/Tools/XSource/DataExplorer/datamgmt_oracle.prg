* <summary>
*	Data Management for Oracle connections.
* </summary>

#include "DataExplorer.h"
#include "foxpro.h"
#include "adovfp.h"

#DEFINE ORACLE_SYS_OWNERS 'CTXSYS','MDSYS','OLAPSYS','ORDPLUGINS','ORDSYS','OUTLN',;
 'QS','QS_CBADM','QS_CS','QS_ES','QS_OS','QS_WS','SYS','SYSMAN','SYSTEM','WKSYS','WMSYS','XDB'


DEFINE CLASS OracleDatabaseMgmt AS ADODatabaseMgmt OF DataMgmt_ADO.prg
	lCriteriaSupported = .F.

	FUNCTION OnGetTables(oTableCollection AS TableCollection)
		LOCAL oRS AS ADODB.RecordSet
		LOCAL cOwner,cView,cSQLStr

	
		IF THIS.ADOOpen()
			cView=THIS.GetOracleView("TABLES")
			IF EMPTY(cView)
				RETURN
			ENDIF
			cSQLStr = THIS.GetOracleSQL(cView, "TABLE_NAME")
			oRS = THIS.oADO.Execute(cSQLStr)
			DO WHILE !oRS.EOF()
				cOwner = IIF(THIS.nObjectLevel=1, THIS.UserName, oRS.Fields('OWNER').Value)
				THIS.AddEntity(oRS.Fields('TABLE_NAME').Value, "", cOwner)
				oRS.MoveNext()
			ENDDO
			oRS.Close()
			THIS.ADOClose()

			THIS.LoadEntities(oTableCollection,3)
		ENDIF
	ENDFUNC

	FUNCTION OnGetViews(oViewCollection AS ViewCollection)
		LOCAL oRS AS ADODB.RecordSet
		LOCAL cOwner, cView, cSQLStr
				
		IF THIS.ADOOpen()
			cView=THIS.GetOracleView("VIEWS")
			IF EMPTY(cView)
				RETURN
			ENDIF
			cSQLStr = THIS.GetOracleSQL(cView,"VIEW_NAME,TEXT")
			oRS = THIS.oADO.Execute(cSQLStr)
			DO WHILE !oRS.EOF()
				cOwner = IIF(THIS.nObjectLevel=1, THIS.UserName,oRS.Fields('OWNER').Value)
				THIS.AddEntity(oRS.Fields('VIEW_NAME').Value, cOwner)
				oRS.MoveNext()
			ENDDO
			oRS.Close()
			THIS.ADOClose()

			THIS.LoadEntities(oViewCollection, 2)
		ENDIF
	ENDFUNC

	FUNCTION OnGetStoredProcedures(oStoredProcCollection AS StoredProcCollection)
		LOCAL oRS AS ADODB.RecordSet
		LOCAL cOwner,cView,cSQLStrl,cName

		IF THIS.ADOOpen()
			cView=THIS.GetOracleView("OBJECTS")
			IF EMPTY(cView)
				RETURN
			ENDIF
			cSQLStr = THIS.GetOracleSQL(cView,"OBJECT_NAME,OBJECT_TYPE")
			cSQLStr = cSQLStr + IIF(THIS.nObjectLevel=2,[ AND ],[ WHERE ]) + [OBJECT_TYPE = 'PROCEDURE']				
			oRS = THIS.oADO.Execute(cSQLStr)
			DO WHILE !oRS.EOF()
				cName = oRS.Fields('OBJECT_NAME').Value
				cOwner = IIF(THIS.nObjectLevel=1, THIS.UserName, oRS.Fields('OWNER').Value)
				THIS.AddEntity(cName, cOwner)
				oRS.MoveNext()
			ENDDO
			oRS.Close()

			THIS.ADOClose()

			THIS.LoadEntities(oStoredProcCollection, 2)
		ENDIF
	ENDFUNC

	FUNCTION MapParameter(cSQLParamType,nPosition)
		LOCAL nParamType
		
		IF VARTYPE(cSQLParamType) <> 'C'
			nParamType = PARAM_UNKNOWN
		ELSE
			cSQLParamType = UPPER(ALLTRIM(cSQLParamType))
			DO CASE
			CASE nPosition = 0
				nParamType = PARAM_RETURNVALUE			
			CASE cSQLParamType == "IN"
				nParamType = PARAM_INPUT
			CASE cSQLParamType == "OUT"
				nParamType = PARAM_OUTPUT
			CASE cSQLParamType == "IN/OUT"
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
		LOCAL oRS AS ADODB.RecordSet
		LOCAL cView,cSQLStr 

		IF THIS.ADOOpen()
			cView=THIS.GetOracleView("ARGUMENTS")
			IF EMPTY(cView)
				RETURN
			ENDIF
			cSQLStr = [SELECT * FROM ] + cView + [ WHERE OBJECT_NAME = '] + cStoredProcName + [']
			IF THIS.nObjectLevel#1
				cSQLStr = cSQLStr + [ AND OWNER = '] + cOwner + [']
			ENDIF
			oRS = THIS.oADO.Execute(cSQLStr)
			DO WHILE !oRS.EOF()
				oParameterCollection.AddEntity( ;
				  IIF(ISNULL(oRS.Fields("ARGUMENT_NAME").Value),"RETURN_VALUE",oRS.Fields("ARGUMENT_NAME").Value), ;
				  oRS.Fields("DATA_TYPE").Value, ;
				  oRS.Fields("DATA_LENGTH").Value, ;
				  oRS.Fields("DATA_PRECISION").Value, ;
				  oRS.Fields("DEFAULT_VALUE").Value, ;
				  THIS.MapParameter(oRS.Fields("IN_OUT").Value,oRS.Fields("POSITION").Value) ;
				 )
				oRS.MoveNext()
			ENDDO
			oRS.Close()

			THIS.ADOClose()
		ENDIF
	ENDFUNC

	* Not supported by ADO, but is supported by our Oracle code
	FUNCTION OnGetFunctions(oFunctionCollection AS FunctionCollection)
		LOCAL oRS AS ADODB.RecordSet
		LOCAL cView, cSQLStr, cOwner, cName

		IF THIS.ADOOpen()
			cView=THIS.GetOracleView("OBJECTS")
			IF EMPTY(cView)
				RETURN
			ENDIF
			cSQLStr = THIS.GetOracleSQL(cView,"OBJECT_NAME,OBJECT_TYPE")
			cSQLStr = cSQLStr + IIF(THIS.nObjectLevel=2,[ AND ],[ WHERE ]) + [OBJECT_TYPE = 'FUNCTION']
			oRS = THIS.oADO.Execute(cSQLStr)				
			DO WHILE !oRS.EOF()
				cName = oRS.Fields('OBJECT_NAME').Value
				cOwner = IIF(THIS.nObjectLevel=1, THIS.UserName, oRS.Fields('OWNER').Value)
				THIS.AddEntity(cName, cOwner, '')
				oRS.MoveNext()							
			ENDDO
			oRS.Close()
			THIS.ADOClose()
			THIS.LoadEntities(oFunctionCollection, 2)
		ENDIF
	ENDFUNC

	FUNCTION OnGetFunctionParameters(oParameterCollection AS ParameterCollection, cFunctionName AS String, cOwner AS String)
		LOCAL oRS AS ADODB.RecordSet
		LOCAL cView,cSQLStr
		
		IF THIS.ADOOpen()
			cView=THIS.GetOracleView("ARGUMENTS")
			IF EMPTY(cView)
				RETURN
			ENDIF
			cSQLStr = [SELECT * FROM ] + cView + [ WHERE OBJECT_NAME = '] + cFunctionName + [']
			IF THIS.nObjectLevel#1
				cSQLStr = cSQLStr + [ AND OWNER = '] + cOwner + [']
			ENDIF
			oRS = THIS.oADO.Execute(cSQLStr)

			DO WHILE !oRS.EOF()
				oParameterCollection.AddEntity( ;
				  IIF(ISNULL(oRS.Fields("ARGUMENT_NAME").Value),"RETURN_VALUE",oRS.Fields("ARGUMENT_NAME").Value), ;
				  oRS.Fields("DATA_TYPE").Value, ;
				  oRS.Fields("DATA_LENGTH").Value, ;
				  oRS.Fields("DATA_PRECISION").Value, ;
				  oRS.Fields("DEFAULT_VALUE").Value, ;
				  THIS.MapParameter(oRS.Fields("IN_OUT").Value,oRS.Fields("POSITION").Value) ;
				 )
				oRS.MoveNext()
			ENDDO
			oRS.Close()
			THIS.oADO.Close()
		ENDIF
	ENDFUNC

	FUNCTION OnGetSchema(oColumnCollection AS ColumnCollection, cTableName, cOwner)
		LOCAL oRS AS ADODB.RecordSet
		LOCAL cView,cSQLStr
		LOCAL cDType, nDLen, nDDec

		IF THIS.ADOOpen()
			cView=THIS.GetOracleView("TAB_COLUMNS")
			IF EMPTY(cView)
				RETURN
			ENDIF
			cSQLStr = [SELECT COLUMN_NAME, DATA_TYPE, DATA_PRECISION, DATA_LENGTH, DATA_SCALE, NULLABLE, DATA_DEFAULT FROM ] +;
				cView + [ WHERE TABLE_NAME = '] + cTableName + [']
			IF THIS.nObjectLevel#1
				cSQLStr = cSQLStr + [ AND OWNER = '] + cOwner + [']
			ENDIF
			oRS = THIS.oADO.Execute(cSQLStr)

			DO WHILE !oRS.EOF()
				cDType = oRS.Fields("DATA_TYPE").Value
				cDLen = IIF(cDType == "NUMBER", oRS.Fields("DATA_PRECISION").Value, oRS.Fields("DATA_LENGTH").Value)
				cDDec = IIF(cDType == "NUMBER", oRS.Fields("DATA_SCALE").Value, oRS.Fields("DATA_PRECISION").Value)
				oColumnCollection.AddEntity( ;
				  oRS.Fields("COLUMN_NAME").Value, ;  && column name
				  cDType, ;  && data type
				  NVL(cDLen,0), ;  && length
				  NVL(cDDec,0), ;  && numeric scale (decimals)
				  NVL(oRS.Fields("NULLABLE").Value, 'N') == 'Y', ;
				  NVL(oRS.Fields("DATA_DEFAULT").Value, '') ;
				 )
				oRS.MoveNext()
			ENDDO
			
			oRS.Close()
			THIS.ADOClose()
		ENDIF
	ENDFUNC

	FUNCTION OnGetStoredProcedureDefinition(cStoredProcName, cOwner) AS String
		LOCAL cView
		LOCAL cSQLStr
		LOCAL oRS
		LOCAL cDefinition
		
		cDefinition = ''
		IF THIS.ADOOpen()
			* Get Source -- only for users
			cView=THIS.GetOracleView("SOURCE")
			IF EMPTY(cView)
				RETURN ""
			ENDIF
			cSQLStr = [SELECT * FROM ] + cView + ;
				[ WHERE NAME = '] + cStoredProcName + [' AND TYPE = 'PROCEDURE'] + ;
				IIF(THIS.nObjectLevel = 1,"",[ AND OWNER = '] + cOwner + [']) +;
				[ ORDER BY LINE]
			oRS = THIS.oADO.Execute(cSQLStr)
			DO WHILE !oRS.EOF()
				cDefinition = cDefinition + oRS.Fields('TEXT').Value
				oRS.MoveNext()
			ENDDO
			oRS.Close()	

			THIS.ADOClose()
		ENDIF

		RETURN cDefinition
	ENDFUNC
	
	FUNCTION OnGetFunctionDefinition(cFunctionName, cOwner) AS String
		LOCAL cDefinition
		LOCAL cView
		LOCAL oRS
		LOCAL cSQLStr
		
		cDefinition = ''
		IF THIS.ADOOpen()
			* Get Source -- only for users
			cView=THIS.GetOracleView("SOURCE")
			IF EMPTY(cView)
				RETURN ""
			ENDIF
			cSQLStr = [SELECT * FROM ] + cView + ;
				[ WHERE NAME = '] + cFunctionName + [' AND TYPE = 'FUNCTION'] + ;
				IIF(THIS.nObjectLevel = 1,"",[ AND OWNER = '] + cOwner + [']) +;
				[ ORDER BY LINE]
			oRS = THIS.oADO.Execute(cSQLStr)
			DO WHILE !oRS.EOF()
				cDefinition = cDefinition + oRS.Fields('TEXT').Value
				oRS.MoveNext()
			ENDDO
			oRS.Close()
		ENDIF
		THIS.ADOClose()

		RETURN cDefinition
	ENDFUNC

	FUNCTION OnGetViewDefinition(cViewName, cOwner) AS String
		LOCAL cDefinition,cView,oRS
		LOCAL cSQLStr
		cDefinition = ''
		IF THIS.ADOOpen()
			cView=THIS.GetOracleView("VIEWS")
			IF EMPTY(cView)
				RETURN ""
			ENDIF				
			cSQLStr = [SELECT VIEW_NAME,TEXT FROM ] + cView + ;
				[ WHERE VIEW_NAME = '] + cViewName + ['] + ;
				IIF(THIS.nObjectLevel = 1,"",[ AND OWNER = '] + cOwner + ['])
			oRS = THIS.oADO.Execute(cSQLStr)				
			DO WHILE !oRS.EOF()
				cDefinition = oRS.Fields('TEXT').Value
				oRS.MoveNext()
			ENDDO
			oRS.Close()				
		ENDIF
		THIS.ADOClose()

		RETURN cDefinition
	ENDFUNC
	
	FUNCTION OnRunStoredProcedure(cStoredProcName, cOwner, oParamList)

		LOCAL cSQL
		LOCAL cValue
		LOCAL cParamList
		
		IF AT(';', cStoredProcName) > 0
			cStoredProcName = ALLTRIM(LEFT(cStoredProcName, AT(';', cStoredProcName) - 1))
		ENDIF

		cSQL = "CALL " + ["]+cStoredProcName+["]
		IF VARTYPE(oParamList) == 'O'
			cParamList = ''
			FOR i = 1 TO oParamList.Count
				IF INLIST(oParamList.Item(i).Direction, PARAM_INPUT, PARAM_INPUTOUTPUT, PARAM_OUTPUT)
					cValue = RTRIM(TRANSFORM(oParamList.Item(i).DefaultValue))
					IF ATC("text",oParamList.Item(i).DataType)>0 OR ATC("char",oParamList.Item(i).DataType)>0 
						cValue=IIF(UPPER(cValue)=="DEFAULT" OR UPPER(cValue)=="NULL","",cValue)
						cParamList = cParamList + IIF(EMPTY(cParamList), '', ',') + "'" + cValue + "'"
					ELSE
						IF !EMPTY(cValue)
							cValue=IIF(UPPER(cValue)=="DEFAULT" OR UPPER(cValue)=="NULL","null",cValue)
							cParamList = cParamList + IIF(EMPTY(cParamList), '', ',') + cValue
						ENDIF
					ENDIF
				ENDIF
			ENDFOR
			IF !EMPTY(cParamList)
				cSQL = cSQL + '(' + cParamList + ')' 
			ENDIF
		ENDIF

		DO FORM RunQuery WITH THIS, cSQL, .T.
	ENDFUNC
	
	FUNCTION GetOracleView(cView)
		LOCAL oRS, lcView, lcViewExpr, lcSaveExact
		lcViewExpr=""
		lcSaveExact=SET("EXACT")
		SET EXACT ON
		lcView = IIF(THIS.nObjectLevel=1,"USER","ALL") + "_" + cView
		TRY
			* Check to see if view exists...
			oRS = THIS.oADO.Execute("SELECT * FROM ALL_VIEWS WHERE VIEW_NAME = '&lcView'")
			* Check if any views exist that meet criteria
			DO WHILE !oRS.EOF()
				* It must be a system view
				IF INLIST(oRS.Fields('OWNER').Value, ORACLE_SYS_OWNERS)
					lcViewExpr=lcView
					EXIT
				ENDIF
				oRS.MoveNext()
			ENDDO
			oRS.Close()
		CATCH
		ENDTRY		
		SET EXACT &lcSaveExact
		RETURN lcViewExpr
	ENDFUNC

	FUNCTION GetOracleSQL(cView,cFields)
		LOCAL lcSQLStr
		lcSQLStr = "SELECT "
		DO CASE
		CASE cFields="*"
			lcSQLStr = lcSQLStr + "*"
		CASE THIS.nObjectLevel=1
			lcSQLStr = lcSQLStr + cFields
		OTHERWISE
			lcSQLStr = lcSQLStr + cFields + ",OWNER"
		ENDCASE
		lcSQLStr = lcSQLStr + " FROM " + cView
		IF THIS.nObjectLevel=2
			lcSQLStr = lcSQLStr + " WHERE OWNER NOT IN (" + [ORACLE_SYS_OWNERS] + ")"
		ENDIF
		RETURN lcSQLStr
	ENDFUNC

	FUNCTION OnGetRunQuery(oCurrentNode)
		LOCAL cSQL, cStoredProcName, oParamList, cOwner, cParmStr, i

		IF TYPE("oCurrentNode.NodeData") == 'O'
			DO CASE
			CASE oCurrentNode.NodeData.Type == "StoredProc"
				cParmStr = ""

				cStoredProcName = oCurrentNode.NodeData.Name

				cOwner = oCurrentNode.NodeData.Owner

				oParamList = THIS.GetParameters(cStoredProcName, cOwner)
				IF VARTYPE(oParamList) == 'O' AND oParamList.Count > 0
					FOR i = 1 TO oParamList.Count
						cParmStr = cParmStr + IIF(m.i=1, "", ", ") + oParamList.Item[m.i].Name
					ENDFOR
				ENDIF

				IF AT(' ', cStoredProcName) > 0
					cStoredProcName = ["] + cStoredProcName +  ["]
				ENDIF

				RETURN "CALL " + cStoredProcName + "(" + cParmStr + ")"
			ENDCASE
		ENDIF
		
		RETURN ''
	ENDFUNC

	FUNCTION SetObjectLevel(oNode)
		LOCAL nLevel
		IF VARTYPE(oNode)#"O"
			RETURN
		ENDIF
		DO FORM objectlevel WITH oNode
	ENDFUNC

ENDDEFINE

* <summary>
*  Nodes used by ADO connection in Data Explorer.
* </summary>
#include "foxpro.h"
#include "dataexplorer.h"

DEFINE CLASS ADONode AS IConnectionNode OF TreeNodes.prg
	
	DataMgmtClass = "ADODatabaseMgmt"
	DataMgmtClassLibrary = "DataMgmt_ADO.prg"

	ServerName        = ''
	DatabaseName      = ''
	ConnectionString  = ''
	ObjectLevel       = 1


	PROCEDURE OnInit()
		DODEFAULT()
		
		THIS.CreateOption("ConnectionString", '')
		THIS.CreateOption("ServerName", '')
		THIS.CreateOption("DatabaseName", '')
		THIS.CreateOption("Password", '', .T.)
		THIS.CreateOption("ADOUsername", '', .T.)
		THIS.CreateOption("CustomPassword", .F., .T.)
		THIS.CreateOption("ConnectTimeout", ADOCONNECT_TIMEOUT_DEFAULT)
		THIS.CreateOption("QueryTimeout", ADOQUERY_TIMEOUT_DEFAULT)

		THIS.CreateOption("ObjectLevel", 1)

		* Display options
		THIS.CreateOption("ShowSystemObjects", .F.)
	ENDPROC


	FUNCTION ServerName_Access
		RETURN THIS.FindOption("ServerName", '')
	ENDFUNC
	PROCEDURE ServerName_Assign(cValue)
		THIS.SetOption("ServerName", cValue)
	ENDPROC

	FUNCTION DatabaseName_Access
		RETURN THIS.FindOption("DatabaseName", '')
	ENDFUNC
	PROCEDURE DatabaseName_Assign(cValue)
		THIS.SetOption("DatabaseName", cValue)
	ENDPROC

	FUNCTION ConnectionString_Access
		RETURN THIS.FindOption("ConnectionString", '')
	ENDFUNC
	PROCEDURE ConnectionString_Assign(cValue)
		THIS.SetOption("ConnectionString", cValue)
	ENDPROC

	FUNCTION ObjectLevel_Access
		RETURN THIS.FindOption("ObjectLevel", 1)
	ENDFUNC
	PROCEDURE ObjectLevel_Assign(nValue)
		THIS.SetOption("ObjectLevel", nValue)
	ENDPROC

	FUNCTION GetConnection(cConnectionString)
		LOCAL oConn
		LOCAL cConnectionString

		IF VARTYPE(cConnectionString) <> 'C' OR EMPTY(cConnectionString)
			cConnectionString = THIS.FindOption("ConnectionString", '')
		ENDIF
		oConn = THIS.GetDataMgmtObject()
		IF VARTYPE(oConn) == 'O'
			oConn.UserPassword = THIS.FindOption("Password", '')
			oConn.UserName = THIS.FindOption("ADOUserName", '')
			oConn.CustomPassword = THIS.FindOption("CustomPassword", .F.)

			oConn.ConnectTimeout = THIS.FindOption("ConnectTimeout", ADOCONNECT_TIMEOUT_DEFAULT)
			oConn.QueryTimeout = THIS.FindOption("QueryTimeout", ADOQUERY_TIMEOUT_DEFAULT)

			oConn.nObjectLevel = THIS.FindOption("ObjectLevel", 1)

			IF oConn.Connect(cConnectionString)
				THIS.SetOption("Password", oConn.UserPassword)
				THIS.SetOption("ADOUserName", EVL(oConn.UserID, oConn.Username))
				THIS.SetOption("CustomPassword", oConn.CustomPassword)

				IF oConn.CustomConnection
					THIS.SetOption("ConnectionString", oConn.ConnectionString)
				ENDIF
			ELSE
				oConn = .NULL.
			ENDIF
		ENDIF
		
		RETURN oConn
	ENDFUNC


	* Given data type properties, return a displayable version
	FUNCTION DataTypeToString(cDataType, nLength, nDecimals)
		LOCAL cDisplayAs
		
		cDisplayAs = cDataType

		DO CASE
		CASE NVL(nDecimals, 0) > 0
			cDisplayAs = cDisplayAs + " (" + TRANSFORM(nLength) + ", " + TRANSFORM(nDecimals) + ")"
		CASE NVL(nLength, 0) > 0
			cDisplayAs = cDisplayAs + " (" + TRANSFORM(nLength) + ")"
		OTHERWISE
			cDisplayAs = cDisplayAs
		ENDCASE

**** Old code to remove****
*!*			DO CASE
*!*			CASE cDataType == "char"
*!*				cDisplayAs = cDisplayAs + " (" + TRANSFORM(THIS.NodeData.Length) + ")"
*!*			CASE cDataType == "decimal"
*!*				cDisplayAs = cDisplayAs + " (" + TRANSFORM(THIS.NodeData.Length) + ", " + TRANSFORM(THIS.NodeData.Decimals) + ")"
*!*			CASE cDataType == "nchar"
*!*				cDisplayAs = cDisplayAs + " (" + TRANSFORM(THIS.NodeData.Length) + ")"
*!*			CASE cDataType == "numeric"
*!*				cDisplayAs = cDisplayAs + " (" + TRANSFORM(THIS.NodeData.Length) + ", " + TRANSFORM(THIS.NodeData.Decimals) + ")"
*!*			CASE cDataType == "nvarchar"
*!*				cDisplayAs = cDisplayAs + " (" + TRANSFORM(THIS.NodeData.Length) + ")"
*!*			CASE cDataType == "varbinary"
*!*				cDisplayAs = cDisplayAs + " (" + TRANSFORM(THIS.NodeData.Length) + ")"
*!*			CASE cDataType == "varchar"
*!*				cDisplayAs = cDisplayAs + " (" + TRANSFORM(THIS.NodeData.Length) + ")"
*!*			ENDCASE		

		RETURN cDisplayAs
	ENDFUNC

	FUNCTION OnDefaultQuery()
		LOCAL oConn
		
		oConn = THIS.GetConnection(THIS.FindOption("ConnectionString", ''))
		IF VARTYPE(oConn) == 'O'
			RETURN oConn.OnGetRunQuery(THIS)
		ELSE
			RETURN ''
		ENDIF
	ENDFUNC

ENDDEFINE


DEFINE CLASS ADODatabaseNode AS ADONode
	ImageKey = "microsoft.imagedatabase"


	FUNCTION DetailTemplate_ACCESS()
		LOCAL cDetail
		
		TEXT TO cDetail NOSHOW TEXTMERGE
			<row><caption><<DETAILS_DATABASE_LOC>></caption><value><<THIS.DatabaseName>></value></row>
			<row><caption><<DETAILS_CONNECTIONSTRING_LOC>></caption><value><<THIS.StripPassword(THIS.GetOption("ConnectionString", ''))>></value></row>
	 	ENDTEXT
	 	
		RETURN cDetail
	ENDFUNC


	FUNCTION ShowPropertiesOkay()
		RETURN .T.
	ENDFUNC

	FUNCTION NodeText_ACCESS
		IF EMPTY(THIS.NodeText)
			RETURN THIS.GetOption("DatabaseName", '')
		ENDIF
		
		RETURN THIS.NodeText
	ENDFUNC

	FUNCTION OnShowProperties()
		LOCAL lSuccess
		
		DO FORM ADOProperties WITH THIS TO lSuccess
		IF VARTYPE(lSuccess) == 'L' AND lSuccess
			THIS.RefreshNode()
		ENDIF
	ENDFUNC

	FUNCTION ShowPropertiesOkay()
		RETURN THIS.SaveNode
	ENDFUNC

	FUNCTION GetADOProperty(oADOConn, cPropName, xDefault)
		LOCAL xValue

		IF PCOUNT() >= 3
			xValue = xDefault
		ELSE
			xValue = .NULL.
		ENDIF
		TRY
			xValue = oADOConn.Properties(cPropName).Value		
		CATCH
			* ignore error
		ENDTRY
		
		RETURN xValue		
	ENDFUNC
	
	FUNCTION ShowADOProperties(cConnString)
		LOCAL lSuccess
		LOCAL oException
		LOCAL cDatabaseName
		LOCAL cServerName
		LOCAL cPassword
		LOCAL oException
		LOCAL oConn
		LOCAL oDataLink AS DataLinks
		LOCAL oADOConn AS ADODB.Connection
		
		lSuccess = .F.

		TRY		
			oDataLink = CREATEOBJECT('DataLinks')

			IF VARTYPE(cConnString) <> 'C' OR EMPTY(cConnString)
				oADOConn = oDataLink.PromptNew()
			ELSE
				oADOConn = CREATEOBJECT('ADODB.Connection')
				oADOConn.ConnectionString = cConnString
				oDataLink.PromptEdit(oADOConn)
			ENDIF

			IF VARTYPE(oADOConn) == 'O' AND TYPE("oADOConn.ConnectionString") == 'C'
				* set connection string immediately because opening the ADO connection
				* will modify the connection string
				* TODO: handle "password" as well
				* THIS.SetOption("ConnectionString", STRTRAN(oADOConn.ConnectionString, STREXTRACT(oADOConn.ConnectionString + ";", "pwd=", ";", -1, 3), '', -1, -1, 1))
				THIS.SetOption("ConnectionString", oADOConn.ConnectionString)
				

				TRY
					* oADOConn.Open()
					oConn = THIS.GetConnection(oADOConn.ConnectionString)
					IF oConn.ADOOpen()
						oADOConn = oConn.oADO
						lSuccess = .T.
					ENDIF

				CATCH TO oException
					* ignore error
					* MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION)
				ENDTRY

				IF lSuccess
					cDatabaseName = ''
					cServerName   = ''

					TRY
						cDatabaseName = oADOConn.DefaultDatabase
					CATCH TO oException
						MESSAGEBOX(oException.Message, MB_ICONSTOP)
					ENDTRY
					IF EMPTY(cDatabaseName)
						cDatabaseName = THIS.GetADOProperty(oADOConn, "Initial Catalog", '')
					ENDIF
					cServerName = THIS.GetADOProperty(oADOConn, "Data Source", '')
					cPassword = THIS.GetADOProperty(oADOConn, "pwd", '')
					IF ISNULL(cPassword) OR EMPTY(cPassword)
						cPassword = THIS.GetADOProperty(oADOConn, "password", '')
					ENDIF
					
					* RB Added
					IF ISNULL(cPassword) AND !EMPTY(oConn.UserPassword)
						cPassword = oConn.UserPassword
					ENDIF
					
					THIS.SetOption("ServerName", cServerName)
					THIS.SetOption("DatabaseName", cDatabaseName)
					THIS.SetOption("Password", cPassword)
		
					oADOConn.Close()
				ENDIF
			ENDIF
		CATCH TO oException
			MESSAGEBOX(oException.Message, MB_ICONSTOP)
		ENDTRY
		
		RETURN lSuccess
	
	ENDFUNC

	FUNCTION OnFirstConnect()
		LOCAL lSuccess
		LOCAL cServerName
		LOCAL cDatabaseName
		
		DODEFAULT()

		DO FORM ADOProperties WITH THIS TO lSuccess
		IF VARTYPE(lSuccess) == 'L' AND lSuccess
			cServerName = THIS.GetOption("ServerName", '')
			cDatabaseName = THIS.GetOption("DatabaseName", '')
			IF EMPTY(cServerName) AND EMPTY(cDatabaseName)
				THIS.NodeText = STREXTRACT(THIS.GetOption("ConnectionString", '') + ';', "dsn=", ";", 1, 3)
				IF EMPTY(THIS.NodeText)
					THIS.NodeText = STREXTRACT(THIS.GetOption("ConnectionString", '') + ';', "data source=", ";", 1, 3)
				ENDIF
				IF EMPTY(THIS.NodeText)
					THIS.NodeText = ADO_CONN_LOC
				ENDIF
			ELSE
				THIS.NodeText = UPPER(cServerName) + IIF(EMPTY(cServerName) OR EMPTY(cDatabaseName), '', '.') + cDatabaseName
			ENDIF
		ELSE
			lSuccess = .F.
		ENDIF
		
		
		RETURN lSuccess
	ENDFUNC

	FUNCTION OnPopulate()
		LOCAL lSuccess
		LOCAL oConn

		lSuccess = .F.

		* Create the connection that we'll use throughout
		* accessing this database
		oConn = THIS.GetConnection(THIS.FindOption("ConnectionString", ''))
		IF VARTYPE(oConn) == 'O'
			THIS.AddNode(THIS.CreateNode("ADOTablesNode"))
			THIS.AddNode(THIS.CreateNode("ADOViewsNode"))
			THIS.AddNode(THIS.CreateNode("ADOStoredProceduresNode"))
			THIS.AddNode(THIS.CreateNode("ADOFunctionsNode"))

			lSuccess = .T.
		ENDIF

		
		RETURN lSuccess
	ENDFUNC


	FUNCTION ShowFilterOkay()
		RETURN .F.
	ENDFUNC
ENDDEFINE

DEFINE CLASS ADOTablesNode AS ADONode
	ImageKey = "microsoft.imagetables"
	NodeText = NODETEXT_TABLES_LOC

	TableObject = .NULL.

	* populate with all tables in the database
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oConn
		LOCAL oTableList
		LOCAL i
		oConn = THIS.GetConnection(THIS.FindOption("ConnectionString", ''))
		IF VARTYPE(oConn) == 'O'
			oTableList = oConn.GetTables()
			IF VARTYPE(oTableList) <> 'O'
				THIS.AddNode(THIS.CreateNode("NotSupportedNode"))
			ELSE
				FOR i = 1 TO oTableList.Count
					oChildNode = THIS.CreateNode("ADOTableNode", '', oTableList.Item(i).Name, oTableList.Item(i))
					THIS.AddNode(oChildNode)
				ENDFOR
			ENDIF
		ENDIF
	ENDFUNC
	
ENDDEFINE

DEFINE CLASS ADOTableNode AS ADONode
	ImageKey  = "microsoft.imagetable"

	* populate with schema of the table
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oConn
		LOCAL oColumnList
		LOCAL i
		oConn = THIS.GetConnection(THIS.FindOption("ConnectionString", ''))
		IF VARTYPE(oConn) == 'O'
			oColumnList = oConn.GetSchema(THIS.NodeKey,THIS.NodeData.Owner)
			IF VARTYPE(oColumnList) <> 'O'
				THIS.AddNode(THIS.CreateNode("NotSupportedNode"))
			ELSE
				FOR i = 1 TO oColumnList.Count
					oChildNode = THIS.CreateNode("ADOColumnNode", '', oColumnList.Item(i).Name, oColumnList.Item(i))
					THIS.AddNode(oChildNode)
				ENDFOR
			ENDIF
		ENDIF
	ENDFUNC

	FUNCTION DetailTemplate_ACCESS()
		LOCAL cDetail
		
		TEXT TO cDetail NOSHOW TEXTMERGE
			<row><caption><<DETAILS_TABLE_LOC>></caption><value><<THIS.NodeData.Name>></value></row>
			<row><caption><<DETAILS_OWNER_LOC>></caption><value><<THIS.NodeData.Owner>></value></row>
	 	ENDTEXT
	 	
		RETURN cDetail
	ENDFUNC


	FUNCTION BrowseData()
		LOCAL oConn

		oConn = THIS.GetConnection(THIS.FindOption("ConnectionString", ''))
		IF VARTYPE(oConn) == 'O'
			oConn.BrowseData(THIS.NodeData.Name, THIS.NodeData.Owner)
		ENDIF
	ENDFUNC

	FUNCTION OnDefaultQuery()
		RETURN EVL(DODEFAULT(), "SELECT * FROM " + THIS.FixName(THIS.NodeData.Name))
	ENDFUNC
ENDDEFINE


DEFINE CLASS ADOViewsNode AS ADONode
	ImageKey = "microsoft.imageviews"
	NodeText = NODETEXT_VIEWS_LOC
	
	* populate with all views in the database
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oConn
		LOCAL oViewList
		LOCAL i
		
		oConn = THIS.GetConnection(THIS.FindOption("ConnectionString", ''))
		IF VARTYPE(oConn) == 'O'
			oViewList = oConn.GetViews()
			IF VARTYPE(oViewList) <> 'O'
				THIS.AddNode(THIS.CreateNode("NotSupportedNode"))
			ELSE
				FOR i = 1 TO oViewList.Count
					oChildNode = THIS.CreateNode("ADOViewNode", '', oViewList.Item(i).Name, oViewList.Item(i))
					THIS.AddNode(oChildNode)
				ENDFOR
			ENDIF
		ENDIF
	ENDFUNC
	
ENDDEFINE

DEFINE CLASS ADOViewNode AS ADONode
	ImageKey = "microsoft.imageview"
	NodeText = "ADO View"
	EndNode = .F.

	* populate with schema of the table
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oConn
		LOCAL oColumnList
		LOCAL i
		oConn = THIS.GetConnection(THIS.FindOption("ConnectionString", ''))
		IF VARTYPE(oConn) == 'O'
			oColumnList = oConn.GetSchema(THIS.NodeKey,THIS.NodeData.Owner)
			IF VARTYPE(oColumnList) <> 'O'
				THIS.AddNode(THIS.CreateNode("NotSupportedNode"))
			ELSE
				FOR i = 1 TO oColumnList.Count
					oChildNode = THIS.CreateNode("ADOColumnNode", '', oColumnList.Item(i).Name, oColumnList.Item(i))
					THIS.AddNode(oChildNode)
				ENDFOR
			ENDIF
		ENDIF
	ENDFUNC

	FUNCTION GetDefinition()
		LOCAL oConn
		LOCAL cDefinition
		
		cDefinition = ''
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			cDefinition = oConn.GetViewDefinition(THIS.NodeData.Name, THIS.NodeData.Owner)
		ENDIF

		RETURN cDefinition
	ENDFUNC

	FUNCTION ZoomDefinition()
		* DO FORM ViewDef WITH STRCONV(THIS.NodeData.Definition, 6)  && convert from Unicode to DBCS in order to display
		DO FORM ViewDef WITH THIS.GetDefinition()
	ENDFUNC

	FUNCTION DetailTemplate_ACCESS()
		LOCAL cDetail
		
		TEXT TO cDetail NOSHOW TEXTMERGE
			<row><caption><<DETAILS_VIEW_LOC>></caption><value><<THIS.NodeData.Name>></value></row>
			<row><caption><<DETAILS_OWNER_LOC>></caption><value><<THIS.NodeData.Owner>></value></row>
	 	ENDTEXT
	 	
		RETURN cDetail
	ENDFUNC

	FUNCTION BrowseData()
		LOCAL oConn

		oConn = THIS.GetConnection(THIS.FindOption("ConnectionString", ''))
		IF VARTYPE(oConn) == 'O'
			oConn.BrowseData(THIS.NodeData.Name, THIS.NodeData.Owner)
		ENDIF
	ENDFUNC

	FUNCTION OnDefaultQuery()
		RETURN EVL(DODEFAULT(), "SELECT * FROM " + THIS.FixName(THIS.NodeData.Name))
	ENDFUNC
ENDDEFINE

DEFINE CLASS ADOStoredProceduresNode AS ADONode
	ImageKey = "microsoft.imagesprocs"
	NodeText = NODETEXT_STOREDPROCS_LOC

	* populate with all stored procedures in the database
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oConn
		LOCAL oStoredProcedureList
		LOCAL i
		LOCAL cProcName
		
		oConn = THIS.GetConnection(THIS.FindOption("ConnectionString", ''))
		IF VARTYPE(oConn) == 'O'
			oStoredProcedureList = oConn.GetStoredProcedures()
			IF VARTYPE(oStoredProcedureList) <> 'O'
				THIS.AddNode(THIS.CreateNode("NotSupportedNode"))
			ELSE
				FOR i = 1 TO oStoredProcedureList.Count
					cProcName = oStoredProcedureList.Item(i).Name
					IF AT(';', cProcName) > 0
						cProcName = LEFT(cProcName, AT(';', cProcName) - 1)
					ENDIF
				
					oChildNode = THIS.CreateNode("ADOStoredProcedureNode", '', cProcName, oStoredProcedureList.Item(i), oStoredProcedureList.Item(i).Name)
					THIS.AddNode(oChildNode)
				ENDFOR
			ENDIF
		ENDIF
	ENDFUNC


ENDDEFINE

DEFINE CLASS ADOStoredProcedureNode AS ADONode
	ImageKey = "microsoft.imagesproc"
	EndNode  = .F.


	* populate with parameters of the stored procedure
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oConn
		LOCAL oParamList
		LOCAL i
		
		oConn = THIS.GetConnection(THIS.FindOption("ConnectionString", ''))
		IF VARTYPE(oConn) == 'O'
			oParamList = oConn.GetParameters(THIS.NodeKey,THIS.NodeData.Owner)
			IF VARTYPE(oParamList) <> 'O'
				THIS.AddNode(THIS.CreateNode("NotSupportedNode"))
			ELSE
				FOR i = 1 TO oParamList.Count
					oChildNode = THIS.CreateNode("ADOParameterNode", '', oParamList.Item(i).Name, oParamList.Item(i))
					THIS.AddNode(oChildNode)
				ENDFOR
			ENDIF
		ENDIF
	ENDFUNC

	FUNCTION GetDefinition()
		LOCAL oConn
		LOCAL cDefinition
		
		cDefinition = ''
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			cDefinition = oConn.GetStoredProcedureDefinition(THIS.NodeData.Name, THIS.NodeData.Owner)
		ENDIF

		RETURN cDefinition
	ENDFUNC

	FUNCTION ZoomDefinition()
		* DO FORM ViewDef WITH STRCONV(THIS.NodeData.Definition, 6)  && convert from Unicode to DBCS in order to display
		DO FORM ViewDef WITH THIS.GetDefinition()
	ENDFUNC


	FUNCTION DetailTemplate_ACCESS()
		LOCAL cDetail
		
		TEXT TO cDetail NOSHOW TEXTMERGE
			<row><caption><<DETAILS_STOREDPROC_LOC>></caption><value><<THIS.NodeText>></value></row>
			<row><caption><<DETAILS_OWNER_LOC>></caption><value><<THIS.NodeData.Owner>></value></row>
	 	ENDTEXT
	 	
		RETURN cDetail
	ENDFUNC

	FUNCTION RunStoredProcedure()
		LOCAL oConn
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oConn.RunStoredProcedure(THIS.NodeData.Name, THIS.NodeData.Owner)
		ENDIF
	ENDFUNC


	FUNCTION OnDefaultQuery()
		LOCAL cStoredProcName
		cStoredProcName = THIS.NodeData.Name
		IF AT(';', cStoredProcName) > 0
			cStoredProcName = ALLTRIM(LEFT(cStoredProcName, AT(';', cStoredProcName) - 1))
		ENDIF	

		RETURN EVL(DODEFAULT(), "EXEC " + THIS.FixName(cStoredProcName))
	ENDFUNC
ENDDEFINE


DEFINE CLASS ADOParameterNode AS ADONode
	ImageKey = "microsoft.imageparameter"
	NodeText = "Parameter"
	EndNode  = .T.
	DataType = ''

	FUNCTION DataType_ACCESS()
		RETURN THIS.DataTypeToString(THIS.NodeData.DataType, THIS.NodeData.Length, THIS.NodeData.Decimals)
	ENDFUNC

	FUNCTION NodeText_ACCESS()
		IF THIS.FindOption("ShowColumnInfo", .F.)
			* other available values: Length, Decimals, IsPrimaryKey, Identity
			RETURN THIS.NodeData.Name + ", " + THIS.DataType
		ELSE
			RETURN THIS.NodeData.Name
		ENDIF
	ENDFUNC

	FUNCTION DetailTemplate_ACCESS()
		LOCAL cDetail
		
		TEXT TO cDetail NOSHOW TEXTMERGE
			<row><caption><<DETAILS_PARAMETER_LOC>></caption><value><<THIS.NodeData.Name>></value></row>
			<row><caption><<DETAILS_DATATYPE_LOC>></caption><value><<THIS.DataType>></value></row>
	 	ENDTEXT
	 	
		RETURN cDetail
	ENDFUNC


ENDDEFINE

DEFINE CLASS ADOFunctionsNode AS ADONode
	ImageKey = "microsoft.imagefunctions"
	NodeText = NODETEXT_FUNCTIONS_LOC

	* populate with all functions in the database
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oConn
		LOCAL oFunctionList
		LOCAL i
		
		oConn = THIS.GetConnection(THIS.FindOption("ConnectionString", ''))
		IF VARTYPE(oConn) == 'O'
			oFunctionList = oConn.GetFunctions()
			IF VARTYPE(oFunctionList) <> 'O'
				THIS.AddNode(THIS.CreateNode("NotSupportedNode"))
			ELSE
				FOR i = 1 TO oFunctionList.Count
					oChildNode = THIS.CreateNode("ADOFunctionNode", '', oFunctionList.Item(i).Name, oFunctionList.Item(i))
					THIS.AddNode(oChildNode)
				ENDFOR
			ENDIF
		ENDIF
	ENDFUNC

ENDDEFINE

DEFINE CLASS ADOFunctionNode AS ADONode
	ImageKey = "microsoft.imagefunction"

	* populate with parameters of the functions
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oConn
		LOCAL oParamList
		LOCAL i
		
		oConn = THIS.GetConnection(THIS.FindOption("ConnectionString", ''))
		IF VARTYPE(oConn) == 'O'
			oParamList = oConn.GetFunctionParameters(THIS.NodeKey,THIS.NodeData.Owner)
			IF VARTYPE(oParamList) <> 'O'
				THIS.AddNode(THIS.CreateNode("NotSupportedNode"))
			ELSE
				FOR i = 1 TO oParamList.Count
					oChildNode = THIS.CreateNode("ADOParameterNode", '', oParamList.Item(i).Name, oParamList.Item(i))
					THIS.AddNode(oChildNode)
				ENDFOR
			ENDIF
		ENDIF
	ENDFUNC

	FUNCTION GetDefinition()
		LOCAL oConn
		LOCAL cDefinition
		
		cDefinition = ''
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			cDefinition = oConn.GetFunctionDefinition(THIS.NodeData.Name, THIS.NodeData.Owner)
		ENDIF

		RETURN cDefinition
	ENDFUNC

	FUNCTION ZoomDefinition()
		* DO FORM ViewDef WITH STRCONV(THIS.NodeData.Definition, 6)  && convert from Unicode to DBCS in order to display
		DO FORM ViewDef WITH THIS.GetDefinition()
	ENDFUNC


	FUNCTION DetailTemplate_ACCESS()
		LOCAL cDetail
		
		TEXT TO cDetail NOSHOW TEXTMERGE
			<row><caption><<DETAILS_FUNCTION_LOC>></caption><value><<THIS.NodeData.Name>></value></row>
			<row><caption><<DETAILS_OWNER_LOC>></caption><value><<THIS.NodeData.Owner>></value></row>
	 	ENDTEXT

 	
		RETURN cDetail
	ENDFUNC

ENDDEFINE


DEFINE CLASS ADOColumnNode AS ADONode
	ImageKey = "microsoft.imagecolumn"
	NodeText = "ADO Column"
	EndNode  = .T.
	DataType = ''


	FUNCTION DataType_ACCESS()
		RETURN THIS.DataTypeToString(THIS.NodeData.DataType, THIS.NodeData.Length, THIS.NodeData.Decimals)
	ENDFUNC
	
	FUNCTION NodeText_ACCESS()
		IF THIS.FindOption("ShowColumnInfo", .F.)
			* other available values: Length, Decimals, IsPrimaryKey, Identity
			RETURN THIS.NodeData.Name + ", " + THIS.DataType
		ELSE
			RETURN THIS.NodeData.Name
		ENDIF
	ENDFUNC

	FUNCTION DetailTemplate_ACCESS()
		LOCAL cDetail
		
		TEXT TO cDetail NOSHOW TEXTMERGE
			<row><caption><<DETAILS_COLUMN_LOC>></caption><value><<THIS.NodeData.Name>></value></row>
			<row><caption><<DETAILS_DATATYPE_LOC>></caption><value><<THIS.DataType>></value></row>
			<row><caption><<DETAILS_DEFAULT_LOC>></caption><value><<THIS.NodeData.DefaultValue>></value></row>
	 	ENDTEXT
	 	
		RETURN cDetail
	ENDFUNC

	FUNCTION OnDefaultQuery()
		RETURN EVL(DODEFAULT(), "SELECT " + THIS.FixName(THIS.NodeData.Name) + " FROM " + THIS.FixName(THIS.ParentNode.NodeData.Name))
	ENDFUNC
	

ENDDEFINE


* <summary>
*  Nodes used by SQL Server view in Data Explorer.
* </summary>
#include "foxpro.h"
#include "dataexplorer.h"

DEFINE CLASS SQLNode AS IConnectionNode OF TreeNodes.prg

	DataMgmtClass = "SQLDatabaseMgmt"
	DataMgmtClassLibrary = "DataMgmt_SQL.prg"

	*UserPassword = '' && don't create an Option for this because we don't want it persisted
	

	PROCEDURE OnInit()
		DODEFAULT()

		* SQL options
		THIS.CreateOption("TrustedConnection", .T.)
		THIS.CreateOption("UserName", '')
		THIS.CreateOption("ConnectTimeout", CONNECT_TIMEOUT_DEFAULT)
		THIS.CreateOption("QueryTimeout", QUERY_TIMEOUT_DEFAULT)
		THIS.CreateOption("AutoTransactions", .T.)
		THIS.CreateOption("DispWarnings", .F.)
		THIS.CreateOption("SortObjects", .T.)
		THIS.CreateOption("Password", '', .T.)

	ENDPROC		

	FUNCTION GetConnection(cServer, cDatabase)
		LOCAL oConn
		LOCAL oNode
		LOCAL oException
		LOCAL cPassword
		
		oConn = .NULL.

		IF VARTYPE(cServer) <> 'C'
			cServer = THIS.FindOption("ServerName", '')
		ENDIF
		IF VARTYPE(cDatabase) <> 'C'
			cDatabase = THIS.FindOption("DatabaseName", '')
		ENDIF
		lTrustedConnection = THIS.FindOption("TrustedConnection", .T.)
		cUserName = THIS.FindOption("UserName", '')
		cPassword = THIS.FindOption("Password", '')

		oNode = THIS
		DO WHILE !ISNULL(oNode)
			IF TYPE("oNode.oConn") == 'O' AND !ISNULL(oNode.oConn) AND ;
			 ((oNode.oConn.ServerName == cServer AND oNode.oConn.DatabaseName == cDatabase) OR ;
			 (EMPTY(cServer) AND EMPTY(cDatabase)))
				oConn = oNode.oConn
				EXIT
			ENDIF

			oNode = oNode.ParentNode
		ENDDO


		IF VARTYPE(oConn) <> 'O'
			TRY
				oConn = THIS.GetDataMgmtObject()

				oConn.ConnectTimeout = THIS.FindOption("ConnectTimeout", CONNECT_TIMEOUT_DEFAULT)
				oConn.QueryTimeout = THIS.FindOption("QueryTimeout", QUERY_TIMEOUT_DEFAULT)
				IF oConn.Connect(cServer, cDatabase, lTrustedConnection, cUserName, cPassword)
					THIS.SetOption("TrustedConnection", oConn.TrustedConnection)
					THIS.SetOption("UserName", oConn.UserName)
					* THIS.UserPassword = oConn.UserPassword
					THIS.SetOption("Password", oConn.UserPassword)
				ELSE
					oConn = .NULL.
				ENDIF
				
			CATCH TO oException
				* ignore error
				oConn = .NULL.
			ENDTRY
		ENDIF
		
		IF VARTYPE(oConn) == 'O'
			oConn.SortObjects = THIS.GetOption("SortObjects", .T.)
		ENDIF
		
		RETURN oConn
	ENDFUNC
	


	FUNCTION ShowSQLDialog(cCmdName, cObjType, cObjName)
		LOCAL oConn
		
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oConn.ShowSQLDialog(cCmdName, cObjType, cObjName)
		ENDIF
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


ENDDEFINE


DEFINE CLASS SQLServersNode AS SQLNode
	NodeID   = "microsoft.sqlservers"
	NodeText = NODETEXT_SQLSERVERS_LOC
	ImageKey = "microsoft.imageservers"
	SaveNode = .T.

	PROCEDURE OnInit()
		DODEFAULT()
	ENDPROC

	* in SQL Servers node, put in each of the available SQL Servers
	FUNCTION OnPopulate()
		LOCAL oServerList
		LOCAL i
		LOCAL oChildNode
		LOCAL cInstanceName
		LOCAL cServerName

		* create a SQL database management object, which we'll
		* use to get available SQL servers
		oServerList = THIS.GetAvailableServers()
		IF VARTYPE(oServerList) == 'O'
			FOR i = 1 TO oServerList.Count
				cInstanceName = ''
				cServerName = oServerList.Item(i).Name
				
				oChildNode = THIS.CreateNode("SQLServerNode", '', oServerList.Item(i).Name, oServerList.Item(i))
				oChildNode.SetOption("ServerName", UPPER(cServerName + IIF(EMPTY(cInstanceName), '', '\' + cInstanceName)))
				THIS.AddNode(oChildNode)
			ENDFOR
		ENDIF
	ENDFUNC
	

	* Add a new server
	FUNCTION AddServer(cServerName, cInstanceName)
		LOCAL oChildNode

		cInstanceName = EVL(cInstanceName, '')
		
		IF !EMPTY(cServerName)
			oChildNode = THIS.CreateNode("SQLServerNode", '', IIF(cServerName == "(local)", cServerName, UPPER(cServerName)) + IIF(EMPTY(cInstanceName), '', '\' + UPPER(cInstanceName)))
			oChildNode.SetOption("ServerName", UPPER(cServerName + IIF(EMPTY(cInstanceName), '', '\' + cInstanceName)))
			THIS.AddNode(oChildNode)
		ENDIF
			
	ENDFUNC


	PROCEDURE OnShowProperties()
		LOCAL lSuccess

		DO FORM SQLProperties WITH THIS, "DEFAULT" TO lSuccess
		IF VARTYPE(lSuccess) == 'L' AND lSuccess
			THIS.RefreshNode()
		ENDIF
	ENDPROC

	FUNCTION ShowPropertiesOkay()
		RETURN .T.
	ENDFUNC

	FUNCTION ShowFilterOkay()
		RETURN .F.
	ENDFUNC

ENDDEFINE

* Display list of all SQL Servers we can find on the network
DEFINE CLASS SQLServerNode AS SQLNode
	ImageKey = "microsoft.imageserver"
	
	PROCEDURE OnInit()
		DODEFAULT()
		
		* all CreateOption values are persisted between sessions
		THIS.CreateOption("ServerName", '')
	ENDPROC

	FUNCTION NodeText_ACCESS
		IF EMPTY(THIS.NodeText)
			RETURN THIS.GetOption("ServerName", '')
		ELSE
			RETURN THIS.NodeText
		ENDIF
	ENDFUNC

	FUNCTION DetailTemplate_ACCESS()
		LOCAL cDetail
		
		TEXT TO cDetail NOSHOW TEXTMERGE
			<row><caption><<DETAILS_SERVER_LOC>></caption><value><<THIS.GetOption("ServerName", '')>></value></row>
	 	ENDTEXT
	 	
		RETURN cDetail
	ENDFUNC

	PROCEDURE OnShowProperties()
		LOCAL lSuccess

		DO FORM SQLProperties WITH THIS, "SERVER" TO lSuccess
		IF VARTYPE(lSuccess) == 'L' AND lSuccess
			THIS.RefreshNode()
		ENDIF
	ENDPROC

	* Get the server name to connect to
	FUNCTION OnFirstConnect()
		LOCAL lSuccess

		DODEFAULT()

		DO FORM SQLProperties WITH THIS, "SERVER" TO lSuccess

		RETURN lSuccess
	ENDFUNC

	* in SQL Server instance, put in each of the member databases
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oConn
		LOCAL oDatabaseList
		LOCAL i
		LOCAL cServerName
		LOCAL oException

		* create a SQL database management object, which we'll
		* use to get available SQL servers
		TRY
			oConn = THIS.GetConnection(THIS.GetOption("ServerName", ''))
		CATCH TO oException
			IF VARTYPE(oException.UserValue) == 'C'
				MessageBox(oException.UserValue)
			ENDIF
		ENDTRY
			
		IF VARTYPE(oConn) == 'O'
			cServerName = THIS.GetOption("ServerName", '')
			oDatabaseList = oConn.GetDatabases()
			FOR i = 1 TO oDatabaseList.Count
				oChildNode = THIS.CreateNode("SQLDatabaseNode", '', oDatabaseList.Item(i).Name, oDatabaseList.Item(i))
				oChildNode.ShowServerName = .F.
				oChildNode.SetOption("ServerName", cServerName)
				oChildNode.SetOption("DatabaseName", oDatabaseList.Item(i).Name)
				THIS.AddNode(oChildNode)
			ENDFOR
		ENDIF
		
		RETURN VARTYPE(oConn) == 'O'
	ENDFUNC

	FUNCTION ShowFilterOkay()
		RETURN .F.
	ENDFUNC

ENDDEFINE

DEFINE CLASS SQLServerConnectionNode AS SQLServerNode
	SaveNode = .T.

	FUNCTION ShowPropertiesOkay()
		RETURN .T.
	ENDFUNC

	FUNCTION ShowFilterOkay()
		RETURN .F.
	ENDFUNC
ENDDEFINE


DEFINE CLASS SQLDatabaseNode AS SQLNode
	ImageKey = "microsoft.imagedatabase"
	ShowServerName = .T.
	ServerName = ''
	DatabaseName = ''

	PROCEDURE OnInit()
		DODEFAULT()

		THIS.CreateOption("ServerName", '')
		THIS.CreateOption("DatabaseName", '')
	ENDPROC


	FUNCTION DetailTemplate_ACCESS()
		LOCAL cDetail
		
		TEXT TO cDetail NOSHOW TEXTMERGE
			<row><caption><<DETAILS_DATABASE_LOC>></caption><value><<THIS.DatabaseName>></value></row>
	 	ENDTEXT
	 	
		RETURN cDetail
	ENDFUNC

	FUNCTION ServerName_Access
		RETURN THIS.FindOption("ServerName", '')
	ENDFUNC

	FUNCTION DatabaseName_Access
		RETURN THIS.FindOption("DatabaseName", '')
	ENDFUNC



	FUNCTION NodeText_ACCESS
		IF EMPTY(THIS.NodeText)
			IF THIS.ShowServerName
				RETURN UPPER(THIS.FindOption("ServerName", '')) + '.' + THIS.GetOption("DatabaseName", '')
			ELSE
				RETURN THIS.GetOption("DatabaseName", '')
			ENDIF
		ELSE
			RETURN THIS.NodeText
		ENDIF
	ENDFUNC

	FUNCTION ShowPropertiesOkay()
		RETURN THIS.SaveNode
	ENDFUNC

	FUNCTION OnShowProperties()
		LOCAL lSuccess
		
		DO FORM SQLProperties WITH THIS TO lSuccess
		IF VARTYPE(lSuccess) == 'L' AND lSuccess
			THIS.RefreshNode()
		ENDIF
	ENDFUNC



	* Get the database to connect to
	FUNCTION OnFirstConnect()
		LOCAL lSuccess

		DO FORM SQLProperties WITH THIS TO lSuccess
		
		RETURN lSuccess
	ENDFUNC

	FUNCTION OnPopulate()
		LOCAL lSuccess

		lSuccess = .F.
		
		* Create the connection that we'll use throughout
		* accessing this database
		*THIS.oConn = THIS.GetConnection()
		oConn = THIS.GetConnection()

		IF VARTYPE(oConn) == 'O'
			THIS.SetOption("TrustedConnection", oConn.TrustedConnection)
			THIS.SetOption("UserName", oConn.UserName)
			*THIS.UserPassword = oConn.UserPassword

			THIS.AddNode(THIS.CreateNode("SQLTablesNode"))
			THIS.AddNode(THIS.CreateNode("SQLViewsNode"))
			THIS.AddNode(THIS.CreateNode("SQLStoredProceduresNode"))
			THIS.AddNode(THIS.CreateNode("SQLFunctionsNode"))
			
			lSuccess = .T.
		ENDIF
		
		RETURN lSuccess
	ENDFUNC

	FUNCTION ShowFilterOkay()
		RETURN .F.
	ENDFUNC

ENDDEFINE

DEFINE CLASS SQLTablesNode AS SQLNode
	ImageKey = "microsoft.imagetables"
	NodeText = NODETEXT_TABLES_LOC

	TableObject = .NULL.

	* populate with all tables in the database
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oConn
		LOCAL oTableList
		LOCAL i
		
		oConn = THIS.GetConnection()

		IF VARTYPE(oConn) == 'O'
			oTableList = oConn.GetTables()
			FOR i = 1 TO oTableList.Count
				oChildNode = THIS.CreateNode("SQLTableNode", '', oTableList.Item(i).Name, oTableList.Item(i))
				THIS.AddNode(oChildNode)
			ENDFOR
			oTableList = .NULL.
		ENDIF
		oConn = .NULL.
	ENDFUNC
	
	FUNCTION NewTableOkay()
		RETURN .F.
	ENDFUNC

ENDDEFINE

DEFINE CLASS SQLTableNode AS SQLNode
	ImageKey  = "microsoft.imagetable"

	* populate with schema of the table
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oConn
		LOCAL oColumnList
		LOCAL i
		
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oColumnList = oConn.GetSchema(THIS.NodeData.Name, THIS.NodeData.Owner)
			FOR i = 1 TO oColumnList.Count
				oChildNode = THIS.CreateNode("SQLColumnNode", '', oColumnList.Item(i).Name, oColumnList.Item(i))
				THIS.AddNode(oChildNode)
			ENDFOR
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
		
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oConn.BrowseData(THIS.NodeData.Name, THIS.NodeData.Owner)
		ENDIF
	ENDFUNC

	FUNCTION NewTableOkay()
		RETURN .F.
	ENDFUNC


	FUNCTION OnDefaultQuery()
		RETURN "SELECT * FROM [" + THIS.NodeData.Owner + "].[" + THIS.NodeData.Name + ']'
	ENDFUNC

ENDDEFINE


DEFINE CLASS SQLViewsNode AS SQLNode
	ImageKey = "microsoft.imageviews"
	NodeText = NODETEXT_VIEWS_LOC

	* populate with all views in the database
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oConn
		LOCAL oViewList
		LOCAL i
		
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oViewList = oConn.GetViews()
			FOR i = 1 TO oViewList.Count
				oChildNode = THIS.CreateNode("SQLViewNode", '', oViewList.Item(i).Name, oViewList.Item(i))
				THIS.AddNode(oChildNode)
			ENDFOR
		ENDIF
	ENDFUNC



ENDDEFINE

DEFINE CLASS SQLViewNode AS SQLNode
	ImageKey = "microsoft.imageview"
	NodeText = "SQL View"
	EndNode = .F.

	* populate with schema of the view
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oConn
		LOCAL oColumnList
		LOCAL i
		
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oColumnList = oConn.GetSchema(THIS.NodeData.Name, THIS.NodeData.Owner)
			FOR i = 1 TO oColumnList.Count
				oChildNode = THIS.CreateNode("SQLViewColumnNode", '', oColumnList.Item(i).Name, oColumnList.Item(i))
				THIS.AddNode(oChildNode)
			ENDFOR
		ENDIF
	ENDFUNC

	FUNCTION BrowseData()
		LOCAL oConn
		
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oConn.BrowseData(THIS.NodeData.Name, THIS.NodeData.Owner)
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

	FUNCTION OnDefaultQuery()
		RETURN "SELECT * FROM [" + THIS.NodeData.Owner + "].[" + THIS.NodeData.Name + ']'
	ENDFUNC

ENDDEFINE

DEFINE CLASS SQLStoredProceduresNode AS SQLNode
	ImageKey = "microsoft.imagesprocs"
	NodeText = NODETEXT_STOREDPROCS_LOC

	* populate with all stored procedures in the database
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oConn
		LOCAL oStoredProcedureList
		LOCAL i
		
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oStoredProcedureList = oConn.GetStoredProcedures()
			FOR i = 1 TO oStoredProcedureList.Count
				oChildNode = THIS.CreateNode("SQLStoredProcedureNode", '', oStoredProcedureList.Item(i).Name, oStoredProcedureList.Item(i))
				THIS.AddNode(oChildNode)
			ENDFOR
		ENDIF
	ENDFUNC

ENDDEFINE

DEFINE CLASS SQLStoredProcedureNode AS SQLNode
	ImageKey = "microsoft.imagesproc"
	EndNode  = .F.


	* populate with parameters of the stored procedure
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oConn
		LOCAL oParamList
		LOCAL i
		
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oParamList = oConn.GetParameters(THIS.NodeData.Name, THIS.NodeData.Owner)
			FOR i = 1 TO oParamList.Count
				oChildNode = THIS.CreateNode("SQLParameterNode", '', oParamList.Item(i).Name, oParamList.Item(i))
				THIS.AddNode(oChildNode)
			ENDFOR
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
		DO FORM ViewDef WITH THIS.GetDefinition()
	ENDFUNC

	FUNCTION DetailTemplate_ACCESS()
		LOCAL cDetail
		
		TEXT TO cDetail NOSHOW TEXTMERGE
			<row><caption><<DETAILS_STOREDPROC_LOC>></caption><value><<THIS.NodeData.Name>></value></row>
			<row><caption><<DETAILS_OWNER_LOC>></caption><value><<THIS.NodeData.Owner>></value></row>
	 	ENDTEXT
	
		RETURN cDetail
	ENDFUNC
	
	
	FUNCTION OnDefaultQuery()
		RETURN "EXEC [" + THIS.NodeData.Owner + "].[" + THIS.NodeData.Name + ']'
	ENDFUNC

	FUNCTION RunStoredProcedure()
		LOCAL oConn
		
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oConn.RunStoredProcedure(THIS.NodeData.Name, THIS.NodeData.Owner)
		ENDIF
	ENDFUNC

ENDDEFINE


DEFINE CLASS SQLParameterNode AS SQLNode
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

DEFINE CLASS SQLFunctionsNode AS SQLNode
	ImageKey = "microsoft.imagefunctions"
	NodeText = NODETEXT_FUNCTIONS_LOC

	* populate with all functions in the database
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oConn
		LOCAL oFunctionList
		LOCAL i
		
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oFunctionList = oConn.GetFunctions()
			FOR i = 1 TO oFunctionList.Count
				oChildNode = THIS.CreateNode("SQLFunctionNode", '', oFunctionList.Item(i).Name, oFunctionList.Item(i))
				THIS.AddNode(oChildNode)
			ENDFOR
		ENDIF
	ENDFUNC


ENDDEFINE

DEFINE CLASS SQLFunctionNode AS SQLNode
	ImageKey = "microsoft.imagefunction"

	* populate with parameters of the functions
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oConn
		LOCAL oParamList
		LOCAL i
		
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oParamList = oConn.GetFunctionParameters(THIS.NodeData.Name, THIS.NodeData.Owner)
			FOR i = 1 TO oParamList.Count
				oChildNode = THIS.CreateNode("SQLParameterNode", '', oParamList.Item(i).Name, oParamList.Item(i))
				THIS.AddNode(oChildNode)
			ENDFOR
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


DEFINE CLASS SQLColumnNode AS SQLNode
	ImageKey = "microsoft.imagecolumn"
	NodeText = "SQL Column"
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
		RETURN "SELECT [" + THIS.NodeData.Name + "] FROM [" + THIS.ParentNode.NodeData.Owner + "].[" + THIS.ParentNode.NodeData.Name + ']'
	ENDFUNC
ENDDEFINE


DEFINE CLASS SQLViewColumnNode AS SQLNode
	ImageKey = "microsoft.imagecolumn"
	NodeText = "SQL Column"
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
	 	ENDTEXT
	 	
		RETURN cDetail
	ENDFUNC
	
	FUNCTION OnDefaultQuery()
		RETURN "SELECT [" + THIS.NodeData.Name + "] FROM [" + THIS.ParentNode.NodeData.Owner + "].[" + THIS.ParentNode.NodeData.Name + ']'
	ENDFUNC
ENDDEFINE


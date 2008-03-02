* <summary>
*  Nodes used by VFP view in Data Explorer.
* </summary>
#include "foxpro.h"
#include "dataexplorer.h"

DEFINE CLASS VFPNode AS IConnectionNode OF TreeNodes.prg

	DataMgmtClass = "VFPDatabaseMgmt"
	DataMgmtClassLibrary = "DataMgmt_VFP.prg"


	PROCEDURE OnInit()
		DODEFAULT()

		* SQL options
		THIS.CreateOption("SortObjects", .T.)
		THIS.CreateOption("ShowColumnInfo", .F.)
	ENDPROC		

	FUNCTION GetConnection(cDatabase)
		LOCAL oConn
		LOCAL oNode
		
		oConn = .NULL.

		IF VARTYPE(cDatabase) <> 'C'
			cDatabase = THIS.FindOption("DatabaseName", '')
		ENDIF

		oNode = THIS
		DO WHILE !ISNULL(oNode)
			IF TYPE("oNode.oConn") == 'O' AND !ISNULL(oNode.oConn) AND ;
			 ((oNode.oConn.DatabaseFile == cDatabase) OR (EMPTY(cDatabase)))
				oConn = oNode.oConn
				EXIT
			ENDIF
			oNode = oNode.ParentNode
		ENDDO

		IF VARTYPE(oConn) <> 'O'
			oConn = THIS.GetDataMgmtObject()
			oConn.Connect(cDatabase)
		ENDIF

		IF VARTYPE(oConn) == 'O'		
			oConn.SortObjects = THIS.FindOption("SortObjects", .T.)
		ENDIF

		
		RETURN oConn
	ENDFUNC



	FUNCTION RemoveConnectionOkay()
		RETURN THIS.SaveNode
	ENDFUNC

	FUNCTION RemoveConnection()
		THIS.RemoveNode()
	ENDFUNC

	* Given data type properties, return a displayable version
	FUNCTION DataTypeToString(cDataType, nLength, nDecimals)
		LOCAL cDisplayAs
		
		cDisplayAs = cDataType

		
		DO CASE
		CASE INLIST(cDataType, "C", "V", "Q")
			cDisplayAs = cDisplayAs + " (" + TRANSFORM(nLength) + ")"
		CASE INLIST(cDataType, "N", "B", "F")
			IF ISNULL(nDecimals)
				cDisplayAs = cDisplayAs + " (" + TRANSFORM(nLength) + ")"
			ELSE
				cDisplayAs = cDisplayAs + " (" + TRANSFORM(nLength) + ", " + TRANSFORM(nDecimals) + ")"
			ENDIF
		ENDCASE
		
		RETURN cDisplayAs
	ENDFUNC

ENDDEFINE

DEFINE CLASS VFPDatabasesNode AS VFPNode
	ImageKey = "microsoft.imagedatabases"
	NodeText = NODETEXT_VFPDATABASES_LOC

	SourceDirectory = ''

	FUNCTION SourceDirectory_Access
		RETURN THIS.FindOption("SourceDirectory", '')
	ENDFUNC

	PROCEDURE OnInit()
		DODEFAULT()

		* all CreateOption values are persisted between sessions
		THIS.CreateOption("SourceDirectory", '')
	ENDPROC
	
	* Get the source directory before to display all databases for
	FUNCTION OnFirstConnect()
		LOCAL cSourceDir
		LOCAL lSuccess

		DODEFAULT()

		lSuccess = .F.		
		cSourceDir = GETDIR(THIS.GetOption("SourceDirectory", ''), SELECTFOLDER_LOC, '', 64)
		IF VARTYPE(cSourceDir) == 'C' AND !EMPTY(cSourceDir)
			THIS.NodeText = cSourceDir
			THIS.SetOption("SourceDirectory", cSourceDir)
			lSuccess = .T.
		ENDIF
		
		RETURN lSuccess
	ENDFUNC

	* populate with all DBC files in selected directory
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oConn
		LOCAL i
		LOCAL o
		LOCAL nCnt
		LOCAL cSourceDirectory
		LOCAL ARRAY aFileList[1]

		cSourceDirectory = THIS.FindOption("SourceDirectory", '')
		IF !EMPTY(cSourceDirectory) AND DIRECTORY(cSourceDirectory)
			nCnt = ADIR(aFileList, ADDBS(cSourceDirectory)  + "*.dbc")
			FOR i = 1 TO nCnt
				oChildNode = THIS.CreateNode("VFPDatabaseNode", '', oTableList.Item(i).Name, JUSTSTEM(aFileList[i, 1]))
				oChildNode.SetOption("DatabaseName", ADDBS(cSourceDirectory) + aFileList[i, 1])
				THIS.AddNode(oChildNode)
			ENDFOR
		ENDIF
	ENDFUNC

	PROCEDURE OnShowProperties()
		LOCAL lSuccess
		
		DO FORM VFPProperties WITH THIS TO lSuccess
		IF VARTYPE(lSuccess) == 'L' AND lSuccess
			THIS.RefreshNode()
		ENDIF
	ENDPROC

	FUNCTION ShowPropertiesOkay()
		RETURN THIS.SaveNode
	ENDFUNC

	FUNCTION ShowFilterOkay()
		RETURN .F.
	ENDFUNC

ENDDEFINE

DEFINE CLASS VFPDatabaseNode AS VFPNode
	ImageKey = "microsoft.imagedatabase"
	DatabaseName = ''


	FUNCTION DatabaseName_Access
		RETURN THIS.FindOption("DatabaseName", '')
	ENDFUNC

	PROCEDURE OnInit()
		DODEFAULT()

		* all CreateOption values are persisted between sessions
		THIS.CreateOption("DatabaseName", '')
	ENDPROC

	* Get the database to connect to
	FUNCTION OnFirstConnect()
		LOCAL cDatabase 
		LOCAL lSuccess

		DODEFAULT()

		lSuccess = .F.		
		cDatabase = GETFILE("DBC")
		
		IF VARTYPE(cDatabase) == 'C' AND !EMPTY(cDatabase)
			THIS.NodeText = JUSTSTEM(cDatabase)
			THIS.SetOption("DatabaseName", cDatabase)
			lSuccess = .T.
		ENDIF

		RETURN lSuccess
	ENDFUNC
	
	FUNCTION OnPopulate()
		LOCAL oConn
		
		* Create the connection that we'll use throughout
		* accessing this database
		oConn = THIS.GetConnection()

		THIS.AddNode(THIS.CreateNode("VFPTablesNode"))
		THIS.AddNode(THIS.CreateNode("VFPViewsNode"))
		THIS.AddNode(THIS.CreateNode("VFPStoredProceduresNode"))
	ENDFUNC

	FUNCTION DetailTemplate_ACCESS()
		LOCAL cDetail
		
		TEXT TO cDetail NOSHOW TEXTMERGE
			<row><caption><<DETAILS_DATABASE_LOC>></caption><value><<THIS.DatabaseName>></value></row>
	 	ENDTEXT
	 	
		RETURN cDetail
	ENDFUNC

	PROCEDURE OnShowProperties()
		LOCAL lSuccess
		
		DO FORM VFPProperties WITH THIS TO lSuccess
		IF VARTYPE(lSuccess) == 'L' AND lSuccess
			THIS.RefreshNode()
		ENDIF
	ENDPROC

	FUNCTION ShowPropertiesOkay()
		RETURN THIS.SaveNode
	ENDFUNC


	FUNCTION NewTable()
		LOCAL oConn
		
		* oConn = THIS.GetConnection(THIS.GetProperty("_ServerName", ''), THIS.GetProperty("_DatabaseName", ''))
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oConn.NewTable()
		ENDIF
	ENDFUNC

	FUNCTION NewView()
		LOCAL oConn
		
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oConn.NewView()
		ENDIF
	ENDFUNC

	FUNCTION ShowFilterOkay()
		RETURN .F.
	ENDFUNC

ENDDEFINE

DEFINE CLASS VFPTablesNode AS VFPNode
	ImageKey = "microsoft.imagetables"
	NodeText = NODETEXT_TABLES_LOC

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
				oChildNode = THIS.CreateNode("VFPTableNode", '', oTableList.Item(i).Name, oTableList.Item(i))
				oChildNode.SetOption("TableName", oTableList.Item(i).PhysicalFile)

				THIS.AddNode(oChildNode)
			ENDFOR
		ENDIF
	ENDFUNC

	FUNCTION NewTable()
		LOCAL oConn
		
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oConn.NewTable()
			THIS.RefreshNode()
		ENDIF
	ENDFUNC
ENDDEFINE

DEFINE CLASS VFPDirectoryNode AS VFPNode
	ImageKey = "microsoft.imagedatabases"
	NodeText = NODETEXT_VFPDATABASES_LOC

	SourceDirectory = ''

	FUNCTION SourceDirectory_Access
		RETURN THIS.FindOption("SourceDirectory", '')
	ENDFUNC

	PROCEDURE OnInit()
		DODEFAULT()

		* all CreateOption values are persisted between sessions
		THIS.CreateOption("SourceDirectory", '')
	ENDPROC
	
	* Get the source directory before to display all databases for
	FUNCTION OnFirstConnect()
		LOCAL cSourceDir
		LOCAL lSuccess

		DODEFAULT()

		lSuccess = .F.		
		cSourceDir = GETDIR(THIS.GetOption("SourceDirectory", ''), SELECTFOLDER_LOC, '', 64)
		IF VARTYPE(cSourceDir) == 'C' AND !EMPTY(cSourceDir)
			THIS.NodeText = cSourceDir
			THIS.SetOption("SourceDirectory", cSourceDir)
			lSuccess = .T.
		ENDIF
		
		RETURN lSuccess
	ENDFUNC

	* populate with all DBC files in selected directory
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oConn
		LOCAL i
		LOCAL o
		LOCAL nCnt
		LOCAL cSourceDirectory
		LOCAL ARRAY aFileList[1]

		cSourceDirectory = THIS.FindOption("SourceDirectory", '')
		IF !EMPTY(cSourceDirectory) AND DIRECTORY(cSourceDirectory)
			nCnt = ADIR(aFileList, ADDBS(cSourceDirectory)  + "*.dbc")
			FOR i = 1 TO nCnt
				oChildNode = THIS.CreateNode("VFPDatabaseNode", '', ADDBS(cSourceDirectory) + aFileList[i, 1], JUSTSTEM(aFileList[i, 1]))
				oChildNode.SetOption("DatabaseName", ADDBS(cSourceDirectory) + aFileList[i, 1])
				THIS.AddNode(oChildNode)
			ENDFOR
		ENDIF
	ENDFUNC

	PROCEDURE OnShowProperties()
		LOCAL lSuccess
		
		DO FORM VFPProperties WITH THIS TO lSuccess
		IF VARTYPE(lSuccess) == 'L' AND lSuccess
			THIS.RefreshNode()
		ENDIF
	ENDPROC

	FUNCTION ShowPropertiesOkay()
		RETURN THIS.SaveNode
	ENDFUNC

ENDDEFINE



DEFINE CLASS VFPTableNode AS VFPNode
	ImageKey = "microsoft.imagetable"
	TableName = ''

	PROCEDURE OnInit()
		DODEFAULT()

		* all CreateOption values are persisted between sessions
		THIS.CreateOption("TableName", '')
	ENDPROC

	FUNCTION TableName_Access
		RETURN THIS.FindOption("TableName", '')
	ENDFUNC

	* Get the table to connect to
	FUNCTION OnFirstConnect()
		LOCAL cTable
		LOCAL lSuccess

		DODEFAULT()

		lSuccess = .F.		
		cTable = GETFILE("DBF")
		IF VARTYPE(cTable) == 'C' AND !EMPTY(cTable)
			THIS.NodeText = JUSTSTEM(cTable)
			THIS.SetOption("TableName", cTable)
			lSuccess = .T.
		ENDIF
		
		RETURN lSuccess
	ENDFUNC
	
	* populate with schema of the table
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oConn
		LOCAL oColumnList
		LOCAL i
		
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oColumnList = oConn.GetSchema(THIS.TableName)
			FOR i = 1 TO oColumnList.Count
				oChildNode = THIS.CreateNode("VFPColumnNode", '', oColumnList.Item(i).Name, oColumnList.Item(i))
				THIS.AddNode(oChildNode)
			ENDFOR
		ENDIF
	ENDFUNC

	FUNCTION DetailTemplate_ACCESS()
		LOCAL cDetail

		TEXT TO cDetail NOSHOW TEXTMERGE
			<row><caption><<DETAILS_TABLE_LOC>></caption><value><<JUSTSTEM(THIS.TableName)>></value></row>
			<row><caption>DBF:</caption><value><<THIS.TableName>></value></row>
	 	ENDTEXT

	 	
		RETURN cDetail
	ENDFUNC

	* Browse VFP Data	
	FUNCTION BrowseData()
		LOCAL oConn
		LOCAL cDatabase
		
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oConn.BrowseData(THIS.TableName)
		ENDIF
	ENDFUNC

	FUNCTION Design()
		LOCAL oConn

		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oConn.DesignTable(THIS.TableName)
		ENDIF
	ENDFUNC

	FUNCTION OnDefaultQuery()
		RETURN "SELECT * FROM " + THIS.FixName(THIS.NodeData.Name)
	ENDFUNC

ENDDEFINE


DEFINE CLASS VFPViewsNode AS VFPNode
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
				oChildNode = THIS.CreateNode("VFPViewNode", '', oViewList.Item(i).Name, oViewList.Item(i))
				THIS.AddNode(oChildNode)
			ENDFOR
		ENDIF
	ENDFUNC

	FUNCTION NewView()
		LOCAL oConn
		
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oConn.NewView()
			THIS.RefreshNode()
		ENDIF
	ENDFUNC
ENDDEFINE

DEFINE CLASS VFPViewNode AS VFPNode
	ImageKey = "microsoft.imageview"
	NodeText = "VFP View"
	EndNode  = .T.

	FUNCTION GetDefinition()
		LOCAL oConn
		LOCAL cDefinition

		cDefinition = ''
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			cDefinition = oConn.GetViewDefinition(THIS.NodeData.Name)
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
	 	ENDTEXT

		IF THIS.GetConfigValue("ShowDefinition")
			TEXT TO cDetail NOSHOW TEXTMERGE ADDITIVE
		 		<row><caption><<DETAILS_DEFINITION_LOC>></caption><value><pre><<THIS.NodeData.Definition>></pre></value></row>
		 	ENDTEXT
		ENDIF
	 	
		RETURN cDetail
	ENDFUNC

	* Browse VFP Data	
	FUNCTION BrowseData()
		LOCAL oConn
		LOCAL cDatabase
		
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oConn.BrowseData(THIS.NodeData.Name)
		ENDIF
	ENDFUNC

	FUNCTION Design()
		LOCAL oConn

		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oConn.DesignView(THIS.NodeData.Name)
		ENDIF
	ENDFUNC

	FUNCTION OnDefaultQuery()
		RETURN "SELECT * FROM " + THIS.FixName(THIS.NodeData.Name)
	ENDFUNC

ENDDEFINE

DEFINE CLASS VFPStoredProceduresNode AS VFPNode
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
				oChildNode = THIS.CreateNode("VFPStoredProcedureNode", '', oStoredProcedureList.Item(i).Name, oStoredProcedureList.Item(i))
				THIS.AddNode(oChildNode)
			ENDFOR
		ENDIF
	ENDFUNC

	FUNCTION EditStoredProc()
		LOCAL oConn

		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oConn.OnEditStoredProc()
		ENDIF
	ENDFUNC

ENDDEFINE

DEFINE CLASS VFPStoredProcedureNode AS VFPNode
	ImageKey = "microsoft.imagesproc"
	EndNode = .T.

	FUNCTION GetDefinition()
		LOCAL oConn
		LOCAL cDefinition

		cDefinition = ''
		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			cDefinition = oConn.GetStoredProcedureDefinition(THIS.NodeData.Name)
		ENDIF

		RETURN cDefinition
	ENDFUNC


	FUNCTION ZoomDefinition()
		DO FORM ViewDef WITH THIS.GetDefinition()
	ENDFUNC

	FUNCTION EditStoredProc()
		LOCAL oConn

		oConn = THIS.GetConnection()
		IF VARTYPE(oConn) == 'O'
			oConn.OnEditStoredProc(THIS.NodeData.Name)
		ENDIF
	ENDFUNC


	FUNCTION DetailTemplate_ACCESS()
		LOCAL cDetail
		
		TEXT TO cDetail NOSHOW TEXTMERGE
			<row><caption><<DETAILS_STOREDPROC_LOC>></caption><value><<THIS.NodeData.Name>></value></row>
	 	ENDTEXT

		IF THIS.GetConfigValue("ShowDefinition")
			TEXT TO cDetail NOSHOW TEXTMERGE ADDITIVE
		 		<row><caption><<DETAILS_DEFINITION_LOC>></caption><value><pre><<THIS.NodeData.Definition>></pre></value></row>
		 	ENDTEXT
		ENDIF
	 	
		RETURN cDetail
	ENDFUNC

	FUNCTION OnDefaultQuery()
		RETURN THIS.NodeData.Name +  "()"
	ENDFUNC

ENDDEFINE


DEFINE CLASS VFPColumnNode AS VFPNode
	ImageKey = "microsoft.imagecolumn"
	NodeText = "SQL Column"
	EndNode = .T.
	
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
		IF TYPE("THIS.ParentNode.NodeData.Name") == 'C'
			RETURN "SELECT " + THIS.NodeData.Name + " FROM " + THIS.FixName(THIS.ParentNode.NodeData.Name)
		ELSE
			* parent node is a Table Connection, so must evaluate differently
			RETURN "SELECT " + THIS.NodeData.Name + " FROM " + THIS.FixName(FORCEEXT(THIS.FindOption("TableName", ''), ''))
		ENDIF
	ENDFUNC
	
ENDDEFINE


DEFINE CLASS VFPTableConnectionNode AS VFPTableNode

	PROCEDURE OnShowProperties()
		LOCAL lSuccess
		
		DO FORM VFPProperties WITH THIS TO lSuccess
		IF VARTYPE(lSuccess) == 'L' AND lSuccess
			THIS.RefreshNode()
		ENDIF
	ENDPROC

	FUNCTION ShowPropertiesOkay()
		RETURN THIS.SaveNode
	ENDFUNC

	FUNCTION OnDefaultQuery()
		RETURN "SELECT * FROM " + THIS.FixName(FORCEEXT(THIS.GetOption("TableName"), ''))
	ENDFUNC
ENDDEFINE


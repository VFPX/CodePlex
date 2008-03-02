#include "foxpro.h"
#include "DataExplorer.h"
#include "..\ffc\registry.h"

DEFINE CLASS DataExplorerEngine AS Session
	Name = "DataExplorerEngine"
	
	* Note: this is just the default -- it's not hardcoded here
	DataTable       = ADDBS(HOME(7)) + "DataExplorer.dbf"

	oRegExpr = .NULL.

	cFontName  = "Tahoma"
	nFontSize  = 8
	cFontStyle = 'N'
	

	* These options can be set in Data Explorer Options
	FontString      = FONT_DEFAULT
	ShowDescription = .T. && Controls whether or not to show description pane
	ShowColumnInfo  = .F. && TRUE to show column info with node

	PROCEDURE Init(lDefaultOptions)
		SET TALK OFF
		SET DELETED ON
		SET CENTURY ON
		
		IF !lDefaultOptions
			THIS.RestorePrefs()
		ENDIF
	ENDPROC
	
	PROCEDURE RunAddInMgr()
		DO FORM AddInMgr
	ENDPROC
	
	FUNCTION GetFoxResource()
		RETURN NEWOBJECT("FoxResource", "FoxResource.prg")
	ENDFUNC

	FUNCTION SavePrefs()
		LOCAL oResource
		LOCAL i

		m.oResource = THIS.GetFoxResource()

		m.oResource.Load("DATAEXPLORER")
		m.oResource.Set("DataTable", FORCEEXT(THIS.DataTable, "dbf"))
		m.oResource.Set("FontString", THIS.FontString)
		m.oResource.Set("ShowDescription", THIS.ShowDescription)
		m.oResource.Set("ShowColumnInfo", THIS.ShowColumnInfo)
		

		m.oResource.Save("DATAEXPLORER")
	
		m.oResource = .NULL.
	ENDFUNC

	
	FUNCTION RestorePrefs()
		LOCAL oResource
		LOCAL i
		LOCAL nCnt
		LOCAL cUniqueID
		LOCAL cTopToolID
		LOCAL ARRAY aTopTool[1]

		m.oResource = THIS.GetFoxResource()
		m.oResource.Load("DATAEXPLORER")
		
		THIS.DataTable     	  = NVL(m.oResource.Get("DataTable"), '')
		THIS.FontString       = NVL(m.oResource.Get("FontString"), THIS.FontString)
		THIS.ShowDescription  = NVL(m.oResource.Get("ShowDescription"), THIS.ShowDescription)
		THIS.ShowColumnInfo   = NVL(m.oResource.Get("ShowColumnInfo"), THIS.ShowColumnInfo)

		IF EMPTY(THIS.DataTable)
			THIS.DataTable = ADDBS(HOME(7)) + "DataExplorer.dbf"
		ENDIF
		THIS.DataTable = FORCEEXT(THIS.DataTable, "dbf")
		
		THIS.ParseFontString()

		m.oResource = .NULL.
	ENDFUNC

	PROCEDURE FontString_Access
		IF EMPTY(THIS.FontString)
			RETURN FONT_DEFAULT
		ELSE
			RETURN THIS.FontString
		ENDIF
	ENDPROC

	PROCEDURE FontString_Assign(cFontString)
		IF EMPTY(m.cFontString)
			THIS.FontString = FONT_DEFAULT
		ELSE
			THIS.FontString = m.cFontString
		ENDIF
		THIS.ParseFontString()
	ENDPROC
	
	PROCEDURE ParseFontString()
		LOCAL cFontString
		LOCAL nFontSize
		
		IF EMPTY(THIS.FontString)
			m.cFontString = FONT_DEFAULT
		ELSE
			m.cFontString = THIS.FontString
		ENDIF
		
		THIS.cFontName  = LEFT(m.cFontString, AT(",", m.cFontString) - 1)
		m.nFontSize  = SUBSTR(m.cFontString, AT(",", m.cFontString) + 1)
		THIS.nFontSize  = VAL(LEFT(m.nFontSize, AT(",", m.nFontSize) - 1))
		THIS.cFontStyle = SUBSTR(m.cFontString, AT("," , m.cFontString, 2) + 1)
	ENDPROC


	FUNCTION GenerateUniqueID()
		RETURN "user." + SYS(2015)
	ENDFUNC
	
	* Reset to default values
	*  [lSaveCustom] = true to save additions by you or third-party to the Data Explorer
	*  [@cBackupTable] = name of the backup file that is created (pass by reference)
	FUNCTION RestoreToDefault(lSaveCustom, cBackupTable)
		LOCAL nSelect
		LOCAL lSuccess
		LOCAL cBackupTable
		LOCAL oException
		LOCAL cSafety
		LOCAL lNoBackup
		LOCAL nFileCnt
		LOCAL oRec
		
		
		m.nSelect = SELECT()
		
		m.lSuccess = .T.
		IF USED("DataExplorer")
			USE IN DataExplorer
		ENDIF
		IF USED("DataExplorerCursor")
			USE IN DataExplorerCursor
		ENDIF
		
		IF VARTYPE(m.cBackupTable) <> 'C' OR EMPTY(m.cBackupTable)
			m.nFileCnt = 0
			m.cBackupTable = ADDBS(JUSTPATH(THIS.DataTable)) + JUSTSTEM(THIS.DataTable) + "Backup.dbf"
			DO WHILE FILE(m.cBackupTable)
				m.nFileCnt = m.nFileCnt + 1
				m.cBackupTable = ADDBS(JUSTPATH(THIS.DataTable)) + JUSTSTEM(THIS.DataTable) + "Backup_" + TRANSFORM(m.nFileCnt) + ".dbf"
			ENDDO

		ENDIF

		m.cSafety = SET("SAFETY")
		SET SAFETY OFF
		
		m.lNoBackup = .F.
		TRY
			USE (THIS.DataTable) ALIAS DataExplorer IN 0 SHARED AGAIN
			SELECT DataExplorer
			COPY TO (m.cBackupTable) WITH PRODUCTION

		CATCH
			m.cBackupTable = ''
			m.lNoBackup = .T.
		ENDTRY
		IF USED("DataExplorer")
			USE IN DataExplorer
		ENDIF
		
		IF !m.lNoBackup OR MESSAGEBOX(ERROR_NOBACKUP_LOC, MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2, DATAEXPLORER_LOC) == IDYES
			TRY
				USE DataExplorerDefault IN 0 SHARED AGAIN
				SELECT DataExplorerDefault
				COPY TO (THIS.DataTable) WITH PRODUCTION

				* keep vendor and user data explorer customizations
				IF m.lSaveCustom
					USE (THIS.DataTable) IN 0 SHARED AGAIN ALIAS NewDataExplorer
					USE (m.cBackupTable) IN 0 SHARED AGAIN ALIAS OldDataExplorer
					SELECT OldDataExplorer
					SCAN ALL
						SELECT NewDataExplorer
						LOCATE FOR UniqueID == OldDataExplorer.UniqueID
						IF !FOUND()
							SELECT OldDataExplorer
							SCATTER MEMO NAME m.oRec
							INSERT INTO NewDataExplorer FROM NAME m.oRec
						ENDIF
					ENDSCAN
				ENDIF				
			CATCH TO oException
				m.lSuccess = .F.
				MESSAGEBOX(ERROR_RESTORETODEFAULT_LOC + CHR(10) + CHR(10) + m.oException.Message, MB_ICONEXCLAMATION, DATAEXPLORER_LOC)
			FINALLY
				IF USED("DataExplorerDefault")
					USE IN DataExplorerDefault
				ENDIF
				IF USED("OldDataExplorer")
					USE IN OldDataExplorer
				ENDIF
				IF USED("NewDataExplorer")
					USE IN NewDataExplorer
				ENDIF
			ENDTRY
		ELSE
			m.lSuccess = .F.
		ENDIF

		SET SAFETY &cSafety

		SELECT (m.nSelect)
		
		RETURN m.lSuccess
		
	ENDFUNC

	* open the table associated with the Data Explorer
	FUNCTION OpenDataTable(cAlias, lSecondTry)
		LOCAL oException
		LOCAL nCnt
		LOCAL cHomeDir
		LOCAL cTableName
		LOCAL nSelect
		LOCAL ARRAY aFileExists[1]
		
		m.oException = .NULL.
		
		m.cTableName = THIS.DataTable
		
		IF VARTYPE(m.cAlias) <> 'C' OR EMPTY(m.cAlias)
			m.cAlias = "DataExplorerCursor" && JUSTSTEM(m.cTableName) + "Cursor"
		ENDIF
		IF !USED(m.cAlias)
			TRY
				nCnt = ADIR(aFileExists, m.cTableName)
			CATCH TO oException
				* MESSAGEBOX(ERROR_INVALIDFILE_LOC, MB_ICONEXCLAMATION, APPNAME_LOC)
			ENDTRY

			IF ISNULL(m.oException) AND nCnt == 0
				* try to create the table
				IF FILE(JUSTSTEM(m.cTableName) + "Default.dbf")
					TRY
						USE (JUSTSTEM(m.cTableName) + "Default") IN 0 SHARED AGAIN ALIAS CopyCursor
						SELECT CopyCursor
						COPY TO (m.cTableName) WITH PRODUCTION
					CATCH TO oException
					ENDTRY
				ENDIF
			ENDIF
			IF USED("CopyCursor")
				USE IN CopyCursor
			ENDIF
			
			IF ISNULL(oException)
				TRY
					USE (m.cTableName) ALIAS (m.cAlias) IN 0 SHARED AGAIN
					
					* the first VFP9 public beta didn't have these fields, so
					* we're adding them if we don't find them rather than
					* giving an error and making them restore to default
					IF TYPE(m.cAlias + ".AddInImage") <> 'W' OR TYPE(m.cAlias + ".DataClass") <> 'M' OR TYPE(m.cAlias + ".DataLib") <> 'M' OR ;
					 TYPE(m.cAlias + ".WhenCode") <> 'M' OR TYPE(m.cAlias + ".WhenNodes") <> 'M'
						nSelect = SELECT()
						USE IN (m.cAlias)
						THIS.RestoreToDefault(.T.)
						USE (m.cTableName) ALIAS (m.cAlias) IN 0 SHARED AGAIN
					ENDIF
				CATCH TO oException
				ENDTRY
			ENDIF
		ENDIF
		
		IF VARTYPE(oException) == 'O' AND oException.ErrorNo <> 3 && 3 = file is in use
			IF !m.lSecondTry
				IF MESSAGEBOX(ERROR_OPENTABLE_LOC + CHR(10) + CHR(10) + oException.Message + CHR(10) + CHR(10) + ERROR_RESTORE_LOC, MB_ICONEXCLAMATION + MB_YESNO, DATAEXPLORER_LOC) == IDYES
					IF DIRECTORY(HOME(7), 1)
						THIS.DataTable = FORCEPATH(JUSTFNAME(THIS.DataTable), HOME(7))
					ELSE
						THIS.DataTable = FORCEPATH(JUSTFNAME(THIS.DataTable), HOME())
					ENDIF

					IF THIS.OpenDataTable(m.cAlias, .T.)
						m.oException = .NULL.
					ENDIF
				ENDIF
			ENDIF
		ENDIF

		RETURN ISNULL(m.oException)
	ENDFUNC
	
	
	FUNCTION CloseDataTable()
		IF USED("DataExplorerCursor")
			USE IN DataExplorerCursor
		ENDIF
	ENDFUNC
	
	FUNCTION SaveNode(oNode)
		LOCAL i
		LOCAL nCnt
		LOCAL lFound
		LOCAL ARRAY aPropList[1]

		IF oNode.SaveNode
			SELECT DataExplorerCursor
			LOCATE FOR ALLTRIM(UniqueID) == ALLTRIM(oNode.NodeID) && AND DefType == DEFTYPE_CONNECTION
			lFound = FOUND()
			IF lFound
				SCATTER FIELDS ;
				  UniqueID, ;
				  DefType, ;
				  ConnName, ;
				  ConnType, ;
				  ConnInfo, ;
				  OptionData, ;
				  DisplayOrd, ;
				  DataClass, ;
				  DataLib, ;
				  Inactive, ;
				  User, ;
				  Modified ;
				 MEMO NAME oRec
			ELSE
				SCATTER FIELDS ;
				  UniqueID, ;
				  DefType, ;
				  ConnName, ;
				  ConnType, ;
				  ConnInfo, ;
				  OptionData, ;
				  DisplayOrd, ;
				  DataClass, ;
				  DataLib, ;
				  Inactive, ;
				  User, ;
				  Modified ;
				 MEMO BLANK NAME oRec
					
				oRec.UniqueID   = oNode.NodeID
				oRec.DefType    = EVL(oNode.DefType, DEFTYPE_CONNECTION)
			ENDIF	
			oRec.ConnName   = oNode.NodeText
			oRec.ConnType   = oNode.NodeType
			oRec.OptionData = oNode.OptionData
			oRec.DisplayOrd = oNode.NodeOrder
			IF TYPE("oNode.CustomDataMgmtClass") == 'L' AND oNode.CustomDataMgmtClass
				IF TYPE("oNode.DataMgmtClass") == 'C'
					oRec.DataClass  = oNode.DataMgmtClass
				ENDIF
				IF TYPE("oNode.DataMgmtClassLibrary") == 'C'
					oRec.DataLib    = oNode.DataMgmtClassLibrary
				ENDIF
				*IF TYPE("oNode.ProviderName") == 'C'
					*oRec.ConnInfo = oNode.ProviderName
				*ENDIF
			ENDIF
	
			IF TYPE("oNode.ProviderName") == 'C'
				oRec.ConnInfo = oNode.ProviderName
			ENDIF

			oRec.Inactive   = oNode.Inactive
			oRec.Modified   = DATETIME()
			
			* serialize any properties that begin with an underscore
			* (e.g. _DatabaseName, _TableName)
*!*				nCnt = AMEMBERS(aPropList, oNode, 0, "G+U")
*!*				oRec.ConnInfo = ''
*!*				FOR i = 1 TO nCnt
*!*					IF LEFT(aPropList[i], 1) == '_'
*!*						oRec.ConnInfo = oRec.ConnInfo + IIF(EMPTY(oRec.ConnInfo), '', CHR(10)) + aPropList[i] + '=' + TRANSFORM(EVALUATE("oNode." + aPropList[i]))
*!*					ENDIF
*!*				ENDFOR
			

			* assume DataExplorerCursor is open
			SELECT DataExplorerCursor
			IF lFound
				GATHER MEMO NAME oRec
				IF oRec.Inactive
					DELETE IN DataExplorerCursor
				ENDIF
			ELSE
				IF !oRec.Inactive
					INSERT INTO DataExplorerCursor FROM NAME oRec
				ENDIF
			ENDIF
		ENDIF
		IF TYPE("oNode.oNodeList") == 'O' AND !ISNULL(oNode.oNodeList)
			FOR i = 1 TO oNode.oNodeList.Count
				THIS.SaveNode(oNode.oNodeList.Item(i))
			ENDFOR
		ENDIF
	ENDFUNC
	
	* Traverse tree to build a string of which nodes
	* should be expanded
	FUNCTION GetExpandedInfoString(oNode, cParent)
		LOCAL i
		LOCAL cString
		LOCAL cNodeInfo
		LOCAL cChildInfo
		
		IF VARTYPE(cParent) <> 'C'
			cParent = ''
		ELSE
			cParent = cParent + '\'
		ENDIF
		
		IF oNode.Expanded
			cString = cParent + oNode.GetNodeInfo()

			FOR i = 1 TO oNode.oNodeList.Count
				cChildInfo = THIS.GetExpandedInfoString(oNode.oNodeList.Item(i), cString)
				IF !EMPTY(cChildInfo)
					cString = cString  + CHR(13) + CHR(10) + cChildInfo
				ENDIF
			ENDFOR
		ELSE
			cString = ''
		ENDIF

		
		RETURN cString
	ENDFUNC
	
	FUNCTION SaveExpandedInfo(oRootNode)
		LOCAL nSelect
		LOCAL lFound
		LOCAL cExpandedInfo
		
		nSelect = SELECT()
		
		* create a string representing which nodes should
		* be expanded

		cExpandedInfo = THIS.GetExpandedInfoString(oRootNode)
		
		* save expanded info
		SELECT DataExplorerCursor
		LOCATE FOR DefType == DEFTYPE_EXPANDEDINFO AND !Inactive
		IF FOUND()
			REPLACE ;
			  OptionData WITH cExpandedInfo, ;
			  Modified WITH DATETIME() ;
			 IN DataExplorerCursor
		ELSE
			INSERT INTO DataExplorerCursor ( ;
			  UniqueID, ;
			  DefType, ;
			  OptionData, ;
			  Inactive, ;
			  Modified ;
			 ) VALUES ( ;
			  THIS.GenerateUniqueID(), ;
			  DEFTYPE_EXPANDEDINFO, ;
			  cExpandedInfo, ;
			  .F., ;
			  DATETIME() ;
			 )
		ENDIF

		SELECT (nSelect)
	ENDFUNC



	* return collection of nodes to expand
	FUNCTION GetExpandedInfo() AS Collection
		LOCAL nSelect
		LOCAL nCnt
		LOCAL ARRAY aExpandedInfo[1]
		
		nSelect = SELECT()

		oExpandInfo = CREATEOBJECT("Collection")
		IF THIS.OpenDataTable()
			SELECT DataExplorerCursor
			LOCATE FOR DefType == DEFTYPE_EXPANDEDINFO AND !Inactive
			IF FOUND()
				nCnt = ALINES(aExpandedInfo, DataExplorerCursor.OptionData)
				FOR i = 1 TO nCnt
					oExpandInfo.Add(aExpandedInfo[i])
				ENDFOR
			ENDIF
		
			THIS.CloseDataTable()
		ENDIF
		
		SELECT (nSelect)
		
		RETURN oExpandInfo
	ENDFUNC

	
	
	* write current connection info to the DataExplorer.dbf table
	FUNCTION Save(oRootNode)
		LOCAL nSelect
		LOCAL oRec
		
		nSelect = SELECT()
		IF THIS.OpenDataTable()
			THIS.SaveNode(oRootNode)
			
			* feature not implemented
			* THIS.SaveExpandedInfo(oRootNode)
	
		
			THIS.CloseDataTable()
		ENDIF
		
		SELECT (nSelect)
	ENDFUNC


	PROTECTED FUNCTION AddinNodeInclude(cNodeList, cNodeName)
		LOCAL i
		LOCAL nCnt
		LOCAL lInclude
		LOCAL cTestNode
		
		IF EMPTY(cNodeList)
			RETURN .T.
		ENDIF
		
		lInclude = .F.
		cNodeName = LOWER(cNodeName)
		nCnt = GETWORDCOUNT(cNodeList, ",;")
		FOR i = 1 TO nCnt
			cTestNode = LOWER(ALLTRIM(GETWORDNUM(cNodeList, i, ",;")))
			IF '*' $ cTestNode
				* wildcards currently only supported at end of node name e.g. "ADONode*"
				cTestNode = CHRTRAN(cTestNode, '*', '')
				IF  cTestNode == LEFT(cNodeName, LEN(cTestNode))
					lInclude = .T.
					EXIT
				ENDIF
			ELSE
				IF cTestNode == cNodeName
					lInclude = .T.
					EXIT
				ENDIF
			ENDIF
		ENDFOR
		
		RETURN lInclude
	ENDFUNC
	
	* return a collection of menu items for the designated node
	*	<oNode> = pass the node object so that we can check to see
	*			  if the node object has a method matching the
	*			  method specified to call for the menu.
	*	[lSetup] = TRUE to return all items
	FUNCTION GetMenuItems(oNode, lSetup) AS Collection
		LOCAL oCollection
		LOCAL nSelect
		LOCAL i
		LOCAL nCnt
		LOCAL o
		LOCAL cScriptCode
		LOCAL cMethodName
		LOCAL lAddMenuItem
		LOCAL oException
		LOCAL ARRAY aMenuList[1]

		oCollection = CREATEOBJECT("Collection")
		
		IF THIS.OpenDataTable()
			nSelect = SELECT()
				
			SELECT ;
			  UniqueID, ;
			  ConnName, ;
			  ScriptCode, ;
			  ConnType, ; 
			  WhenNodes, ;
			  WhenCode, ;
			  Template ;
			 FROM DataExplorerCursor ;
			 WHERE ;
			  DefType == DEFTYPE_MENU AND ;
			  !Inactive ;
			 ORDER BY DisplayOrd, ConnName ;
			 INTO ARRAY aMenuList
			nCnt = _TALLY
			FOR i = 1 TO nCnt
				cScriptCode = aMenuList[i, 3]
				lAddMenuItem = .F.

				IF lSetup
					lAddMenuItem = .T.
				ELSE
					IF THIS.AddinNodeInclude(aMenuList[i, 5], oNode.Name)
						IF EMPTY(aMenuList[i, 6])
							lAddMenuItem = .T.
						ELSE
							IF UPPER(LEFT(aMenuList[i, 6], 15)) == "* METHOD CHECK:" && special check to speed up menu evaulation
								* if MethodName + "Okay" method exists on node then call that
								* to see if this menu item should actually be added.  For example,
								* if the script code is: AddConnection("microsoft.sqlserver")
								* Then we'll first check to make sure AddConnection() is a method
								* of the node.  If it is, then see if AddConnectionOkay() is
								* also a method of the node.  If it is, call it and only add
								* the menu item if it returns TRUE.
								lAddMenuItem = .T.
								cMethodName = ALLTRIM(SUBSTR(aMenuList[i, 6], 16))
								IF !EMPTY(cMethodName) AND PEMSTATUS(oNode, cMethodName, 5)
									IF PEMSTATUS(oNode, cMethodName + "Okay", 5)
										lAddMenuItem = EVALUATE("oNode." + cMethodName + "Okay()")
									ENDIF
								ELSE
									lAddMenuItem = .F.
								ENDIF
							ELSE
								TRY
									lAddMenuItem = NVL(THIS.RunScript(aMenuList[i, 1], oNode, aMenuList[i, 6]), .F.)
								CATCH TO oException
									MESSAGEBOX("Error running code to determine whether to display custom menu option." + CHR(10) + CHR(10) + ;
									 "UniqueID: " + aMenuList[i, 1] + CHR(10) + ;
									 "ConnName: " + aMenuList[i, 2] + CHR(10) + ;
									 CHR(10) +;
									 "Error: " + oException.Message, MB_ICONSTOP, DATAEXPLORER_LOC)
								ENDTRY
							ENDIF
						ENDIF
					ENDIF
				ENDIF
					
				IF lAddMenuItem
					o = CREATEOBJECT("Empty")
					ADDPROPERTY(o, "UniqueID", aMenuList[i, 1])
					ADDPROPERTY(o, "Caption", RTRIM(aMenuList[i, 2]))
					ADDPROPERTY(o, "Nodes", RTRIM(aMenuList[i, 5]))
					ADDPROPERTY(o, "DisplayIf", RTRIM(aMenuList[i, 6]))
					ADDPROPERTY(o, "ScriptCode", cScriptCode)
					ADDPROPERTY(o, "ShortCaption", RTRIM(aMenuList[i, 4]))
					ADDPROPERTY(o, "Template", RTRIM(aMenuList[i, 7]))
					
					oCollection.Add(o, RTRIM(aMenuList[i, 1]))
				ENDIF
			ENDFOR
			THIS.CloseDataTable()

			SELECT (nSelect)
		ENDIF

		RETURN oCollection
	ENDFUNC	

	* return a collection of drag/drop items for the designated node
	*	<oNode> = pass the node object so that we can check to see
	*			  if the node object has a method matching the
	*			  method specified to call for the menu.
	*	[lSetup] = TRUE to return all items
	FUNCTION GetDragDropAddins(oNode, lSetup, cDefType) AS Collection
		LOCAL oCollection
		LOCAL nSelect
		LOCAL i
		LOCAL nCnt
		LOCAL o
		LOCAL cScriptCode
		LOCAL cMethodName
		LOCAL lAddItem
		LOCAL oException
		LOCAL ARRAY aMenuList[1]
		
		IF VARTYPE(cDefType) <> 'C' OR EMPTY(cDefType)
			cDefType = DEFTYPE_DROP_CODEWINDOW
		ENDIF

		oCollection = CREATEOBJECT("Collection")
		
		IF THIS.OpenDataTable()
			nSelect = SELECT()
				
			SELECT ;
			  UniqueID, ;
			  ConnName, ;
			  ScriptCode, ;
			  ConnType, ; 
			  WhenNodes, ;
			  WhenCode, ;
			  Template ;
			 FROM DataExplorerCursor ;
			 WHERE ;
			  DefType == cDefType AND ;
			  !Inactive ;
			 ORDER BY DisplayOrd, ConnName ;
			 INTO ARRAY aMenuList
			nCnt = _TALLY
			FOR i = 1 TO nCnt
				cScriptCode = aMenuList[i, 3]
				lAddItem = .F.

				IF lSetup
					lAddItem = .T.
				ELSE
					IF EMPTY(aMenuList[i, 5]) OR THIS.AddinNodeInclude(aMenuList[i, 5], oNode.Name)
						lAddItem = .T.
					ENDIF
				ENDIF
					
				IF lAddItem
					o = CREATEOBJECT("Empty")
					ADDPROPERTY(o, "UniqueID", aMenuList[i, 1])
					ADDPROPERTY(o, "Caption", RTRIM(aMenuList[i, 2]))
					ADDPROPERTY(o, "Nodes", RTRIM(aMenuList[i, 5]))
					ADDPROPERTY(o, "DisplayIf", RTRIM(aMenuList[i, 6]))
					ADDPROPERTY(o, "ScriptCode", cScriptCode)
					ADDPROPERTY(o, "ShortCaption", RTRIM(aMenuList[i, 4]))
					ADDPROPERTY(o, "Template", RTRIM(aMenuList[i, 7]))
					
					oCollection.Add(o, RTRIM(aMenuList[i, 1]))
				ENDIF
			ENDFOR
			THIS.CloseDataTable()

			SELECT (nSelect)
		ENDIF

		RETURN oCollection
	ENDFUNC	

	
	* return all active connections defined in DataExplorer.dbf
	FUNCTION GetActiveConnections() AS Collection
		LOCAL nSelect
		LOCAL cClassName
		LOCAL cClassLib
		LOCAL i
		LOCAL nCnt
		LOCAL oCollection
		LOCAL oConn
		LOCAL ARRAY aConnDef[1]
		LOCAL ARRAY aConn[1]

		oCollection = CREATEOBJECT("Collection")

		IF THIS.OpenDataTable()
			nSelect = SELECT()
			
			SELECT ;
			  UniqueID, ;
			  ConnName, ;
			  DefType, ;
			  ConnType, ;
			  ConnInfo, ;
			  OptionData, ;
			  DataClass, ;
			  DataLib ;
			 FROM DataExplorerCursor ;
			 WHERE ;
			  DefType == DEFTYPE_CONNECTION AND ;
			  !Inactive ;
			 ORDER BY DisplayOrd, ConnName ;
			 INTO ARRAY aConn
			nCnt = _TALLY
			FOR i = 1 TO nCnt
				oConn = THIS.CreateConnection(aConn[i, 4])
				IF VARTYPE(oConn) == 'O'
					oConn.UniqueID = RTRIM(aConn[i, 1])
					oConn.ConnName = RTRIM(aConn[i, 2])
					oConn.ProviderName = aConn[i, 5]
					oConn.OptionData = aConn[i, 6]
					oConn.DataMgmtClass = EVL(aConn[i, 7], oConn.DataMgmtClass)
					oConn.DataMgmtClassLibrary = EVL(aConn[i, 8], oConn.DataMgmtClassLibrary)
					oCollection.Add(oConn, RTRIM(aConn[i, 1]))
				ENDIF
			ENDFOR
			
			IF USED("ConnCursor")
				USE IN ConnCursor
			ENDIF
		
			THIS.CloseDataTable()
			SELECT (nSelect)
		ENDIF
		
		RETURN oCollection
	ENDFUNC

	* Create a connection object.	
	*	<cConnTypeUniqueID> = connection type to create
	FUNCTION CreateConnection(cConnTypeUniqueID)
		LOCAL oConn
		LOCAL ARRAY aConnTypeList[1]
		
		oConn = .NULL.
		IF THIS.OpenDataTable()
			SELECT ;
			  UniqueID, ;
			  ConnName, ;
			  ConnType, ;
			  ClassName, ;
			  ClassLib, ;
			  Options, ;
			  OptionData, ;
			  DataClass, ;
			  DataLib, ;
			  ScriptCode, ;
			  ConnInfo ;  
			 FROM ;
			  DataExplorerCursor ;
			 WHERE ;
			  UniqueID == cConnTypeUniqueID AND ;
			  DefType == DEFTYPE_DATASOURCE ;
			 ORDER BY DisplayOrd, ConnName ;
			 INTO ARRAY aConnTypeList

			IF _TALLY > 0
				oConn = CREATEOBJECT("Empty")

				ADDPROPERTY(oConn , "UniqueID", THIS.GenerateUniqueID())
				ADDPROPERTY(oConn , "ConnName", '')
				ADDPROPERTY(oConn , "ConnType", aConnTypeList[1, 1])  && hold reference to UniqueID of connection definition
				ADDPROPERTY(oConn , "ClassName", aConnTypeList[1, 4])
				ADDPROPERTY(oConn , "ClassLib", aConnTypeList[1, 5])
				ADDPROPERTY(oConn, "Options", aConnTypeList[1, 6])
				ADDPROPERTY(oConn, "OptionData", aConnTypeList[1, 7])
				IF !EMPTY(aConnTypeList[1, 8]) AND !EMPTY(aConnTypeList[1, 9])
					ADDPROPERTY(oConn , "DataMgmtClass", aConnTypeList[1, 8])
					ADDPROPERTY(oConn , "DataMgmtClassLibrary", aConnTypeList[1, 9])
					ADDPROPERTY(oConn , "ProviderName", ALLTRIM(aConnTypeList[1, 11]))
				ELSE
					ADDPROPERTY(oConn , "DataMgmtClass", '')
					ADDPROPERTY(oConn , "DataMgmtClassLibrary", '')
					ADDPROPERTY(oConn , "ProviderName", '')
				ENDIF
				ADDPROPERTY(oConn , "ScriptCode", aConnTypeList[1, 10])
				
			ENDIF
		
		ENDIF
		
		RETURN oConn
	ENDFUNC
	
	* return collection of available connection types
	FUNCTION GetConnectionTypes() AS Collection
		LOCAL oConnTypeCollection
		LOCAL i
		LOCAL nCnt
		LOCAL o
		
		oConnTypeCollection = CREATEOBJECT("Collection")

		IF THIS.OpenDataTable()
			SELECT ;
			  UniqueID, ;
			  ConnName, ;
			  ConnType, ;
			  ClassName, ;
			  ClassLib, ;
			  Options, ;
			  OptionData ;
			 FROM ;
			  DataExplorerCursor ;
			 WHERE DefType == DEFTYPE_DATASOURCE AND !Inactive ;
			 ORDER BY DisplayOrd, ConnName ;
			 INTO ARRAY aConnTypeList

			nCnt = _TALLY
			FOR i = 1 TO nCnt
				o = CREATEOBJECT("Empty")
				ADDPROPERTY(o, "UniqueID", aConnTypeList[i, 1])
				ADDPROPERTY(o, "ConnName", RTRIM(aConnTypeList[i, 2]))
				ADDPROPERTY(o, "ConnType", aConnTypeList[i, 3])
				ADDPROPERTY(o, "ClassName", aConnTypeList[i, 4])
				ADDPROPERTY(o, "ClassLibName", aConnTypeList[i, 5])
				ADDPROPERTY(o, "Options", aConnTypeList[i, 6])
				ADDPROPERTY(o, "OptionData", aConnTypeList[i, 7])
				
				oConnTypeCollection.Add(o, ALLTRIM(aConnTypeList[i, 1]))
			ENDFOR
		
			THIS.CloseDataTable()
		ENDIF
		
		RETURN oConnTypeCollection 
	ENDFUNC




	* return collection of Root nodes
	FUNCTION GetRootNodes()
		LOCAL nSelect
		LOCAL i
		LOCAL nCnt
		LOCAL oCollection
		LOCAL o
		LOCAL ARRAY aConn[1]

		oCollection = CREATEOBJECT("Collection")

		IF THIS.OpenDataTable()
			nSelect = SELECT()

			SELECT ;
			  UniqueID, ;
			  ConnName, ;
			  ConnInfo, ;
			  ClassName, ;
			  ClassLib, ;
			  Options, ;
			  OptionData ;
			 FROM DataExplorerCursor ;
			 WHERE ;
			  DefType == DEFTYPE_ROOT AND !Inactive ;
			 ORDER BY DisplayOrd, ConnName ;
			 INTO ARRAY aConn
			nCnt = _TALLY
			FOR i = 1 TO nCnt
				o = CREATEOBJECT("Empty")
				ADDPROPERTY(o, "UniqueID", aConn[i, 1])
				ADDPROPERTY(o, "ConnName", RTRIM(aConn[i, 2]))
				ADDPROPERTY(o, "ConnInfo", aConn[i, 3])
				ADDPROPERTY(o, "ClassName", aConn[i, 4])
				ADDPROPERTY(o, "ClassLib", aConn[i, 5])
				ADDPROPERTY(o, "Options", aConn[i, 6])
				ADDPROPERTY(o, "OptionData", aConn[i, 7])
				
				oCollection.Add(o, ALLTRIM(aConn[i, 1]))
			ENDFOR
			
			THIS.CloseDataTable()

			SELECT (nSelect)
		ENDIF
		
		RETURN oCollection
	ENDFUNC

	* return collection of all images that could potentially
	* be used and are defined in DataExplorer.dbf
	FUNCTION GetImageList()
		LOCAL nSelect
		LOCAL i
		LOCAL nCnt
		LOCAL oCollection
		LOCAL o
		LOCAL ARRAY aImageList[1]

		oCollection = CREATEOBJECT("Collection")

		IF THIS.OpenDataTable()
			nSelect = SELECT()

			SELECT ;
			  UniqueID, ;
			  ConnInfo ;
			 FROM DataExplorerCursor ;
			 WHERE ;
			  DefType == DEFTYPE_PICTURE AND ;
			  !Inactive AND ;
			  !EMPTY(ConnInfo) ;
			 ORDER BY DisplayOrd, ConnName ;
			 INTO ARRAY aImageList
			nCnt = _TALLY
			FOR i = 1 TO nCnt
				o = CREATEOBJECT("Empty")
				ADDPROPERTY(o, "UniqueID", aImageList[i, 1])
				ADDPROPERTY(o, "Filename", aImageList[i, 2])
				
				IF EMPTY(JUSTEXT(o.Filename))
					o.Filename = FORCEEXT(o.Filename, "bmp")
				ENDIF

				oCollection.Add(o, ALLTRIM(aImageList[i, 1]))
			ENDFOR
			
			THIS.CloseDataTable()

			SELECT (nSelect)
		ENDIF
		
		RETURN oCollection
	ENDFUNC

	* Load up imagelist with unique images specified in DataExplorer table
	* 	<oImageList> = reference to ActiveX ImageList control
	FUNCTION LoadImages(oImageList)
		LOCAL nSelect
		LOCAL cImageFile
		LOCAL oException
		
		IF THIS.OpenDataTable()
			nSelect = SELECT()
			
			SELECT UniqueID, ConnInfo ;
			 FROM DataExplorerCursor ;
			 WHERE ;
			  DefType == DEFTYPE_PICTURE ;
			 INTO CURSOR ImageCursor
			SCAN ALL
				cImageFile = ALLTRIM(ConnInfo)
				IF EMPTY(JUSTEXT(cImageFile))
					cImageFile = FORCEEXT(ImageFile, "bmp")
				ENDIF
				
				IF FILE(cImageFile)
					TRY
						oImageList.ListImages.Add(, ALLTRIM(UniqueID), LOADPICTURE(THIS.EvalText(cImageFile)))
					CATCH TO oException
						* ignore error -- probably a duplicate or does not exist
						* MESSAGEBOX(oException.Message + ": " + cImageFile)
					ENDTRY
				ENDIF
			ENDSCAN
			
			IF USED("ImageCursor")
				USE IN ImageCursor
			ENDIF
		
			THIS.CloseDataTable()
			SELECT (nSelect)
		ENDIF
	ENDFUNC
	
	FUNCTION RunScript(cUniqueID, oNode, cScriptCode, oParam)
		LOCAL nSelect
		LOCAL oParam
		LOCAL xRetValue
		LOCAL ARRAY aScriptCode[1]
		
		xRetValue = .NULL.
		IF THIS.OpenDataTable()
			nSelect = SELECT()
			IF VARTYPE(oParam) <> 'O'
				SELECT DataExplorerCursor
				LOCATE FOR UniqueID == cUniqueID 
				IF FOUND()
				 	SCATTER MEMO NAME oParam
				ENDIF
				IF VARTYPE(cScriptCode) <> 'C' OR EMPTY(cScriptCode)
					cScriptCode = DataExplorerCursor.ScriptCode
				ENDIF
				SELECT (nSelect)
			ENDIF
			
		 	ADDPROPERTY(oParam, "CurrentNode", .NULL.)
		 	IF VARTYPE(oNode) == 'O'
		 		oParam.CurrentNode = oNode
		 	ENDIF
		 	ADDPROPERTY(oParam, "oDataExplorerEngine", THIS)

		 	xRetValue = EXECSCRIPT(cScriptCode, oParam)
		 	oParam = .NULL.
			
			SELECT (nSelect)
		ENDIF
		RETURN xRetValue
	ENDFUNC


	FUNCTION EvalText(cScript)
		LOCAL cEvalScript
		LOCAL oException
		
		cEvalScript = cScript
		IF LEFT(cScript, 1) == '(' AND RIGHT(cScript, 1) == ')'
			TRY
				cEvalScript = EVALUATE(cScript)
			CATCH TO oException
				MESSAGEBOX(oException.Message)
			ENDTRY
		ENDIF
		RETURN cEvalScript
	ENDFUNC



	* return a collection of query addins for the designated
	* data management type
	FUNCTION GetAddIns(cDefType, cConnType) AS Collection
		LOCAL oCollection
		LOCAL nSelect
		LOCAL i
		LOCAL nCnt
		LOCAL o
		LOCAL cScriptCode
		LOCAL ARRAY aMenuList[1]

		oCollection = CREATEOBJECT("Collection")
		
		IF VARTYPE(cDefType) <> 'C' OR EMPTY(cDefType)
			cDefType = DEFTYPE_QUERYADDIN
		ENDIF
		IF VARTYPE(cConnType) <> 'C'
			cConnType = ''
		ELSE
			cConnType = RTRIM(cConnType)
		ENDIF
		
		IF THIS.OpenDataTable()
			nSelect = SELECT()
				
			SELECT ;
			  UniqueID, ;
			  ConnName, ;
			  ScriptCode, ;
			  ClassName, ;
			  ClassLib, ;
			  ConnInfo, ;
			  AddInImage ;
			 FROM DataExplorerCursor ;
			 WHERE ;
			  DefType == cDefType AND ;
			  (EMPTY(ConnType) OR RTRIM(ConnType) == cConnType) AND ;
			  !Inactive ;
			 ORDER BY DisplayOrd, ConnName ;
			 INTO ARRAY aMenuList
			nCnt = _TALLY
			FOR i = 1 TO nCnt
				cScriptCode = aMenuList[i, 3]
				IF EMPTY(cScriptCode) AND !EMPTY(aMenuList[i, 4])
					IF EMPTY(aMenuList[i, 5])
						cScriptCode = "oAddIn = CREATEOBJECT(" + ALLTRIM(aMenuList[i, 4]) + ")" + CRLF
					ELSE
						cScriptCode = "oAddIn = NEWOBJECT(" + ALLTRIM(aMenuList[i, 4]) + ", " + ALLTRIM(aMenuList[i, 5]) + ")" + CRLF
					ENDIF
					cScriptCode = cScriptCode + "oAddIn.Execute(oParameter)"
				ENDIF
				
				o = CREATEOBJECT("Empty")
				ADDPROPERTY(o, "UniqueID", aMenuList[i, 1])
				ADDPROPERTY(o, "Caption", RTRIM(EVL(aMenuList[i, 6], aMenuList[i, 2])))
				ADDPROPERTY(o, "ScriptCode", cScriptCode)
				ADDPROPERTY(o, "ShortCaption", RTRIM(aMenuList[i, 2]))
				ADDPROPERTY(o, "AddInImage", RTRIM(aMenuList[i, 7]))
					
				oCollection.Add(o, RTRIM(aMenuList[i, 1]))
			ENDFOR
			
			THIS.CloseDataTable()

			SELECT (nSelect)
		ENDIF

		RETURN oCollection
	ENDFUNC	

	FUNCTION SaveAddIns(cDefType, oCollection) AS Boolean
		LOCAL nSelect
		LOCAL i
		LOCAL nCnt
		LOCAL oAddIn
		LOCAL lSuccess
		LOCAL ARRAY aMenuList[1]

		nSelect = SELECT()

		lSuccess = .F.	
		IF THIS.OpenDataTable()
			UPDATE DataExplorerCursor ;
			 SET Inactive = .T., Modified = DATETIME() ;
			 WHERE DefType == cDefType
			
			
			FOR i = 1 TO oCollection.Count
				oAddin = oCollection.Item(i)
				UPDATE DataExplorerCursor ;
				 SET ;
				  ConnName = oAddin.ShortCaption, ;
				  ScriptCode = oAddin.ScriptCode, ;
				  ConnInfo = oAddin.Caption, ;
				  AddInImage = oAddin.AddInImage, ;
				  DisplayOrd = i, ;
				  Inactive = .F., ;
				  Modified = DATETIME() ;
				 WHERE DefType == cDefType AND ALLTRIM(UniqueID) == ALLTRIM(oAddin.UniqueID)
				IF _TALLY == 0
					INSERT INTO DataExplorerCursor ( ;
					 UniqueID, ;
					 DefType, ;
					 ConnName, ;
					 ConnInfo, ;
					 ScriptCode, ;
					 AddInImage, ;
					 DisplayOrd, ;
					 Inactive, ;
					 Modified ;
					 ) VALUES ( ;
					 oAddin.UniqueID, ;
					 cDefType, ;
					 oAddin.ShortCaption, ;
					 oAddin.Caption, ;
					 oAddin.ScriptCode, ;
					 oAddin.AddInImage, ;
					 i, ;
					 .F., ;
					 DATETIME() ;
					)
				ENDIF
			ENDFOR
			
			THIS.CloseDataTable()
			lSuccess = .T.

		ENDIF

		SELECT (nSelect)

		RETURN lSuccess
	ENDFUNC	

	FUNCTION SaveDragDrop(oCollection, cDefType) AS Boolean
		RETURN THIS.SaveMenus(oCollection, cDefType)
	ENDFUNC

	FUNCTION SaveMenus(oCollection, cDefType) AS Boolean
		LOCAL nSelect
		LOCAL i
		LOCAL nCnt
		LOCAL oMenu
		LOCAL lSuccess
		LOCAL ARRAY aMenuList[1]

		nSelect = SELECT()
		
		IF VARTYPE(cDefType) <> 'C' OR EMPTY(cDefType)
			cDefType = DEFTYPE_MENU
		ENDIF

		lSuccess = .F.	
		IF THIS.OpenDataTable()
			UPDATE DataExplorerCursor ;
			 SET Inactive = .T., Modified = DATETIME() ;
			 WHERE DefType == cDefType
			
			
			FOR i = 1 TO oCollection.Count
				oMenu = oCollection.Item(i)
				UPDATE DataExplorerCursor ;
				 SET ;
				  ConnName = oMenu.Caption, ;
				  ConnType = oMenu.ShortCaption, ;
				  WhenNodes = oMenu.Nodes, ;
				  WhenCode = oMenu.DisplayIf, ;
				  ScriptCode = oMenu.ScriptCode, ;
				  Template = oMenu.Template, ;
				  DisplayOrd = i, ;
				  Inactive = .F., ;
				  Modified = DATETIME() ;
				 WHERE DefType == cDefType AND ALLTRIM(UniqueID) == ALLTRIM(oMenu.UniqueID)
				IF _TALLY == 0
					INSERT INTO DataExplorerCursor ( ;
					 UniqueID, ;
					 DefType, ;
					 ConnType, ;
					 ConnName, ;
					 WhenNodes, ;
					 WhenCode, ;
					 ScriptCode, ;
					 Template, ;
					 DisplayOrd, ;
					 Inactive, ;
					 Modified ;
					 ) VALUES ( ;
					 oMenu.UniqueID, ;
					 cDefType, ;
					 oMenu.ShortCaption, ;
					 oMenu.Caption, ;
					 oMenu.Nodes, ;
					 oMenu.DisplayIf, ;
					 oMenu.ScriptCode, ;
					 oMenu.Template, ;
					 i, ;
					 .F., ;
					 DATETIME() ;
					)
				ENDIF
			ENDFOR
			
			THIS.CloseDataTable()
			lSuccess = .T.

		ENDIF

		SELECT (nSelect)

		RETURN lSuccess
	ENDFUNC	

ENDDEFINE


DEFINE CLASS PropertyCollection AS Collection
	FUNCTION PropertyExists(cPropName)
		RETURN !ISNULL(THIS.GetProperty(m.cPropName))
	ENDFUNC
	
	FUNCTION GetProperty(cPropName)
		LOCAL i
		LOCAL oPropObject
		
		m.oPropObject = .NULL.
		m.cPropName = UPPER(m.cPropName)
		FOR m.i = 1 TO THIS.Count
			IF UPPER(THIS.Item(m.i).Name) == m.cPropName
				m.oPropObject = THIS.Item(m.i)
				EXIT
			ENDIF
		ENDFOR
		
		RETURN m.oPropObject
	ENDFUNC
	
	PROCEDURE AddPropertyValue(cName, cValue)
		LOCAL oPropObject
		
		m.oPropObject = CREATEOBJECT("Empty")
		ADDPROPERTY(m.oPropObject, "Name", m.cName)
		ADDPROPERTY(m.oPropObject, "Value", m.cValue)
	
		THIS.Add(m.oPropObject)
	ENDPROC
	
ENDDEFINE


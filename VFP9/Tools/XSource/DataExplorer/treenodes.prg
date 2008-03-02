* <summary>
* 	Default node for populating tree.  All view nodes
*	should be derived from INode.
*
*	For each created node, override the OnPopulate() method
*	to load child nodes.
* </summary>
#include "foxpro.h"
#include "DataExplorer.h"


DEFINE CLASS INode AS Custom
	PROTECTED lRetrieved
	
	oNodeList = .NULL.

	lRetrieved = .F.  && set to true when sub nodes have been retrieved

	NodeText  = ''
	NodeID    = ''
	NodeType  = ''  && contains UniqueID of connection type
	NodeData  = .NULL.
	NodeKey   = ''
	ImageKey  = ''  && uniqueID of image to display next to node
	ExpandOnInit = .F.

	* populated automatically
	NodeLevel  = 0
	NodeOrder  = 0
	ParentID   = ''
	ParentNode = .NULL.
	SaveNode   = .F.  && set to TRUE if this node can be persisted
	
	EndNode   = .F.
	Expanded  = .F.

	Inactive  = .F.
	
	Options = ''
	OptionData = ''
	oOptionCollection  = .NULL.
	
	DefType = ''
	
	
	* set this in DetailTemplate_Access
	DetailTemplate = '' && ex: "<row><caption>#NodeText#</caption><value></value></row>"

	Filtered = .F.	


	* Return .T. if given method name exists on node
	* Used by menus
	FUNCTION IsOkay(cMethodName)
		LOCAL lOkay
		
		lOkay = .F.
		IF PEMSTATUS(THIS, cMethodName, 5)
			IF PEMSTATUS(THIS, cMethodName + "Okay", 5)
				lOkay = EVALUATE("THIS." + cMethodName + "Okay()")
			ENDIF
		ENDIF
		
		RETURN lOkay
	ENDFUNC

	* retrieve a DataExplorerEngine configuration value
	FUNCTION GetConfigValue(cProperty, xDefault)
		LOCAL xValue
		LOCAL oDataExplorerEngine

		xValue = .NULL.
		
		oDataExplorerEngine = NEWOBJECT("DataExplorerEngine", "DataExplorerEngine.prg")
		oDataExplorerEngine.RestorePrefs()
		IF PEMSTATUS(oDataExplorerEngine, cProperty, 5)
			xValue = EVALUATE("oDataExplorerEngine." + cProperty)
		ELSE
			IF PCOUNT() > 1
				xValue = xDefault
			ENDIF
		ENDIF
		oDataExplorerEngine = .NULL.

		RETURN xValue
	ENDFUNC


	PROCEDURE Init(cNodeText, xNodeData, cNodeKey)
		IF EMPTY(THIS.NodeID)
			THIS.NodeID = "user." + SYS(2015)
		ENDIF

		IF VARTYPE(cNodeText) == 'C'
			THIS.NodeText = cNodeText
		ENDIF
		IF PCOUNT() > 1
			THIS.NodeData = xNodeData
		ENDIF

		THIS.NodeKey = EVL(NVL(cNodeKey, ''), '')

		THIS.oNodeList = CREATEOBJECT("Collection")
		THIS.oOptionCollection = CREATEOBJECT("Collection")

		* regular expression filter that gets applied to all objects
		THIS.CreateOption("FilterInclude", '')
		THIS.CreateOption("FilterExclude", '')

		THIS.OnInit()
	ENDFUNC

	FUNCTION Filtered_ACCESS()
		RETURN !EMPTY(THIS.GetOption("FilterInclude", '')) OR !EMPTY(THIS.GetOption("FilterExclude", ''))
	ENDFUNC

	PROCEDURE OnInit()
	ENDPROC
	
	PROCEDURE Destroy()
		THIS.ReleaseNodes()
	ENDPROC

	* -- Override either one of these to customize
	* -- the node text to return
	FUNCTION NodeText_ACCESS
		RETURN THIS.OnGetNodeText()
	ENDFUNC
	FUNCTION OnGetNodeText()
		RETURN THIS.NodeText
	ENDFUNC

	FUNCTION NodeKey_ACCESS
		RETURN EVL(THIS.NodeKey, THIS.OnGetNodeText())
	ENDFUNC


	FUNCTION DetailTemplate_ACCESS
		RETURN '' && THIS.DetailTemplate
	ENDFUNC
	
	FUNCTION ImageKey_ACCESS
		RETURN THIS.ImageKey
	ENDFUNC

	* Populate node with children
	FUNCTION OnPopulate()
		RETURN .T.
	ENDFUNC

	PROTECTED PROCEDURE CopyIntoNodeData(oDestination, oSource)
		LOCAL i
		LOCAL nCnt
		LOCAL aPropList[1]
		
		oDestination.NodeData = CREATEOBJECT("Empty")
		
		IF VARTYPE(oSource) == 'O'
			nCnt = AMEMBERS(aPropList, oSource, 0, 'G')
			FOR i = 1 TO nCnt
				ADDPROPERTY(oDestination.NodeData, aPropList[i], EVALUATE("oSource." + aPropList[i]))
			ENDFOR
		ENDIF
	ENDPROC
	
	* create an instance of a node, and assign any options
	* that have the same name in the parent to have the
	* same value.
	FUNCTION CreateNode(cClassName, cClassLib, cNodeText, xNodeData, cNodeKey)
		LOCAL oNode
		LOCAL i
		LOCAL cFullClassLib

		IF EMPTY(cClassLib)
			oNode = CREATEOBJECT(cClassName)
		ELSE
			* if classlib is not in the path, then look for it
			cFullClassLib = cClassLib
			IF EMPTY(JUSTEXT(cFullClassLib))
				cFullClassLib = FORCEEXT(cFullClassLib, "prg")
			ENDIF
			IF !FILE(cFullClassLib)
				cFullClassLib = FORCEPATH(cFullClassLib, HOME(7))
				IF !FILE(cFullClassLib)
					cFullClassLib = FORCEPATH(cFullClassLib, HOME())
				ENDIF
			ENDIF
			oNode = NEWOBJECT(cClassName, cFullClassLib)
		ENDIF
		IF PCOUNT() > 2 AND VARTYPE(cNodeText) == 'C'
			oNode.NodeText = cNodeText
		ENDIF
		IF PCOUNT() > 3
			* copy all properties from xNodeData.
			* don't assign the reference directly because causes
			* problem with leaving the data session open that
			* the original node data was created in
			THIS.CopyIntoNodeData(oNode, xNodeData)
		ENDIF
		oNode.NodeKey = EVL(NVL(cNodeKey, ''), '')

		IF TYPE("THIS.DataMgmtClass") == 'C' AND TYPE("oNode.DataMgmtClass") == 'C'
			oNode.DataMgmtClass = THIS.DataMgmtClass
			oNode.DataMgmtClassLibrary = THIS.DataMgmtClassLibrary
		ENDIF
		IF TYPE("THIS.ProviderName") == 'C' AND TYPE("oNode.ProviderName") == 'C'
			oNode.ProviderName = THIS.ProviderName
		ENDIF
		
		FOR i = 1 TO THIS.oOptionCollection.Count
			IF !INLIST(THIS.oOptionCollection.Item(i).OptionName, "FilterInclude", "FilterExclude")
				oNode.SetOption(THIS.oOptionCollection.Item(i).OptionName, THIS.oOptionCollection.Item(i).OptionValue)
			ENDIF
		ENDFOR

		RETURN oNode
	ENDFUNC



	* Called to retrieve information on node to
	* display in Details area
	FUNCTION OnGetDetails() AS String
		LOCAL i
		LOCAL nCnt
		LOCAL cDetails
		LOCAL cValue
		LOCAL ARRAY aNodeInfo[1]

		cDetails = THIS.DetailTemplate
		IF !EMPTY(cDetails)
			IF VARTYPE(THIS.NodeData) == 'O'
				nCnt = AMEMBERS(aNodeInfo, THIS.NodeData, 0, 'U')
				FOR i = 1 TO nCnt
					cValue = TRANSFORM(NVL(EVALUATE("THIS.NodeData." + aNodeInfo[i]), ''))
					cDetails = STRTRAN(cDetails, "#Node." + aNodeInfo[i] + '#', cValue, -1, -1, 1)
					cDetails = STRTRAN(cDetails, "#" + aNodeInfo[i] + '#', cValue, -1, -1, 1)
				ENDFOR
			ENDIF

			nCnt = AMEMBERS(aNodeInfo, THIS, 0, 'U')
			FOR i = 1 TO nCnt
				cValue = TRANSFORM(NVL(EVALUATE("THIS." + aNodeInfo[i]), ''))
				cDetails = STRTRAN(cDetails, "#Node." + aNodeInfo[i] + '#', cValue, -1, -1, 1)
				cDetails = STRTRAN(cDetails, "#" + aNodeInfo[i] + '#', cValue, -1, -1, 1)
			ENDFOR

			* cDetails = TEXTMERGE(cDetails, .F., "<<", ">>")
		ENDIF
		
		RETURN cDetails
		
	ENDFUNC

	FUNCTION GetDetails() AS String
		RETURN THIS.OnGetDetails()
	ENDFUNC

	* -- Show Properties code
	PROCEDURE OnShowProperties()
		DO FORM NodeProperties WITH THIS
	ENDPROC

	* override this in a subclass to display custom
	* property dialog
	PROCEDURE ShowProperties()
		THIS.OnShowProperties()
	ENDPROC
	
	FUNCTION ShowPropertiesOkay()
		RETURN !EMPTY(THIS.Options)
	ENDFUNC

	* -- Rename code
	PROCEDURE OnRenameNode()
		LOCAL lSuccess
		DO FORM NodeRename WITH THIS TO lSuccess
		IF VARTYPE(lSuccess) == 'L' AND lSuccess
			THIS.RefreshNode()
		ENDIF
	ENDPROC
	PROCEDURE RenameNode()
		THIS.OnRenameNode()
	ENDPROC
	

	* -- Filter code
	PROCEDURE OnShowFilter()
		DO FORM NodeFilter WITH THIS TO lSuccess
		IF VARTYPE(lSuccess) == 'L' AND lSuccess
			THIS.RefreshNode()
		ENDIF
	ENDPROC

	PROCEDURE ShowFilter()
		THIS.OnShowFilter()
	ENDPROC
	
	FUNCTION ShowFilterOkay()
		RETURN !THIS.EndNode
	ENDFUNC


	FUNCTION HookAddNode(oNode)
	ENDFUNC

	FUNCTION HookRemoveNode(oNode, lRemoveAll)
	ENDFUNC

	FUNCTION HookGotoNode(oNode)
	ENDFUNC

	FUNCTION HookRefreshCaption(oNode)
	ENDFUNC

	FUNCTION HookExpandNode(oNode)
	ENDFUNC


	* traverse through the tree to find the specific
	* node to expand
	FUNCTION ExpandNode(cNodeID)
		LOCAL i
		LOCAL lFound
		
		IF VARTYPE(cNodeID) <> 'C' OR EMPTY(cNodeID)
			cNodeID = THIS.NodeID
		ENDIF

		IF THIS.NodeID == cNodeID
			lFound = .T.
			THIS.Expanded = .T.
		ELSE
			FOR i = 1 TO THIS.oNodeList.Count
				IF THIS.oNodeList.Item(i).ExpandNode(cNodeID)
					EXIT
				ENDIF
			ENDFOR
		ENDIF
		
		RETURN lFound
	ENDFUNC

	* traverse through the tree to find the specific
	* node to collapse
	FUNCTION CollapseNode(cNodeID)
		LOCAL i
		LOCAL lFound
		
		IF VARTYPE(cNodeID) <> 'C' OR EMPTY(cNodeID)
			cNodeID = THIS.NodeID
		ENDIF

		IF THIS.NodeID == cNodeID
			lFound = .T.
			THIS.Expanded = .F.
		ELSE
			FOR i = 1 TO THIS.oNodeList.Count
				IF THIS.oNodeList.Item(i).CollapseNode(cNodeID)
					EXIT
				ENDIF
			ENDFOR
		ENDIF
		
		RETURN lFound
	ENDFUNC
	
	* Populate node with children
	*	[cNodeID] - node to populate
	FUNCTION Populate(cNodeID)
		LOCAL oNode
		LOCAL oRootNode
		LOCAL lSuccess
		
		lSuccess = .F.
		
		IF VARTYPE(cNodeID) == 'C' AND !EMPTY(cNodeID)
			oNode = THIS.GetNode(cNodeID)
		ELSE
			oNode = THIS
		ENDIF

		IF VARTYPE(oNode) == 'O'
			* BINDEVENT is at the root node only, so call
			* the hook event from there
			oRootNode = THIS.GetRootNode()
			IF oNode.oNodeList.Count > 0
				oRootNode.HookRemoveNode(oNode, .T.)
			ENDIF
			
			oNode.oNodeList.Remove(-1)

			lSuccess = oNode.OnPopulate()
			
			IF lSuccess
				IF !oNode.EndNode AND oNode.oNodeList.Count == 0
					THIS.AddNoChildrenNode()
				ENDIF
			ENDIF
		ENDIF
		
		RETURN lSuccess
	ENDFUNC

	PROCEDURE Expanded_ASSIGN(lExpanded)

		IF lExpanded AND !THIS.Expanded
			lExpanded = THIS.Populate()
		ENDIF

		THIS.Expanded = lExpanded

	ENDPROC

	* this is hooked by the TreeView control so that
	* we can tell it which node to position on
	FUNCTION GotoNode(oNode)
		LOCAL oRootNode
		
		oRootNode = THIS.GetRootNode()
		oRootNode.HookGotoNode(oNode)
	ENDFUNC

	* return TRUE if object name passes the filter test
	FUNCTION FilterCheck(oNode)
		LOCAL cExact
		LOCAL lFilterPass
		LOCAL oRegExpr
		LOCAL cFilterInclude
		LOCAL cFilterExclude
		
		cFilterInclude = THIS.GetOption("FilterInclude", '')
		cFilterExclude = THIS.GetOption("FilterExclude", '')
		
		IF EMPTY(cFilterInclude) AND EMPTY(cFilterExclude)
			RETURN .T.
		ENDIF

		cObjectName = oNode.NodeText

		lFilterPass = .T.
		cExact = SET("EXACT")
		SET EXACT OFF
		
		lFilterPass = (UPPER(cObjectName) = UPPER(cFilterInclude))
		IF lFilterPass AND !EMPTY(cFilterExclude)
			lFilterPass = !(UPPER(cObjectName) = UPPER(cFilterExclude))
		ENDIF
		
		SET EXACT &cExact
		
		RETURN lFilterPass
	ENDFUNC


	* add a new child node to the current node	
	*	<oNode> = new node to add to the child node list
	FUNCTION AddNode(oNode)
		LOCAL oRootNode

		IF THIS.FilterCheck(oNode)
			IF THIS.oNodeList.Count > 0 AND THIS.oNodeList.Item(1).NodeID = "msg."
				THIS.oNodeList.Item(1).RemoveNode()
			ENDIF
		
			IF EMPTY(oNode.NodeID)
				oNode.NodeID = "user." + SYS(2015)
			ENDIF
			
			oNode.ParentID   = THIS.NodeID
			oNode.ParentNode = THIS
			oNode.NodeOrder  = THIS.oNodeList.Count
			oNode.NodeLevel  = THIS.NodeLevel + 1
			
			THIS.oNodeList.Add(oNode, oNode.NodeID)

			oRootNode = THIS.GetRootNode()
			oRootNode.HookAddNode(oNode)
		ENDIF		
	ENDFUNC

	* return the root node
	FUNCTION GetRootNode()
		LOCAL oRootNode
		
		oRootNode = THIS
		DO WHILE !ISNULL(oRootNode.ParentNode)
			oRootNode = oRootNode.ParentNode
		ENDDO
		
		RETURN oRootNode
	ENDFUNC

	* remove current node
	FUNCTION RemoveNode()
		LOCAL oRootNode
		
		THIS.Inactive = .T.


		* BINDEVENT is at the root node only, so call
		* the hook event from there
		oRootNode = THIS.GetRootNode()
		oRootNode.HookRemoveNode(THIS)
	ENDFUNC

	PROCEDURE ReleaseNodes()
		LOCAL i
		
		THIS.ParentNode = .NULL.
		IF TYPE("THIS.oNodeList") == 'O' AND !ISNULL(THIS.oNodeList)
			FOR i = THIS.oNodeList.Count TO 1 STEP -1
				THIS.oNodeList.Item(i).ReleaseNodes()
			ENDFOR
			THIS.oNodeList.Remove(-1)
		ENDIF
	ENDPROC


	* Return description of node that we can use
	* to identify node later (NodeID doesn't work
	* because that can change between sessions)
	FUNCTION GetNodeInfo()
		LOCAL cNodeInfo

		IF VARTYPE(THIS.NodeData) == 'O'
			cNodeInfo = THIS.NodeData.Type + '.' + RTRIM(THIS.NodeData.Name)
		ELSE
			cNodeInfo = RTRIM(THIS.NodeText)
		ENDIF
		RETURN cNodeInfo
	ENDFUNC
	
	FUNCTION RefreshNode()
		LOCAL i
		LOCAL oRootNode
	
		oRootNode = THIS.GetRootNode()
		oRootNode.Save()
	
		THIS.lRetrieved = .F.

		IF THIS.Expanded
			THIS.Populate()
		ENDIF

		oRootNode.HookRefreshCaption(THIS)
	ENDFUNC
	

	FUNCTION ExpandAll()
		LOCAL i
		
		THIS.Expanded = .T.
		FOR i = 1 TO THIS.oNodeList.Count
			THIS.oNodeList.Item(i).ExpandAll()
		ENDFOR
	ENDFUNC

	* Search for node by its NodeID
	FUNCTION GetNode(cNodeID)
		LOCAL i
		LOCAL oNode
		
		oNode = .NULL.
		
		IF THIS.NodeID == cNodeID
			oNode = THIS
		ELSE
			FOR i = 1 TO THIS.oNodeList.Count
				oNode = THIS.oNodeList.Item(i).GetNode(cNodeID)
				IF VARTYPE(oNode) == 'O'
					EXIT
				ENDIF
			ENDFOR
		ENDIF
		
		RETURN oNode
	ENDFUNC

	FUNCTION OnBeforeCreateMenu(oContextMenu)
	ENDFUNC
	FUNCTION OnAfterCreateMenu(oContextMenu)
	ENDFUNC



	FUNCTION RunScript(cUniqueID)
		LOCAL oDataExplorerEngine
		
		oDataExplorerEngine = NEWOBJECT("DataExplorerEngine", "DataExplorerEngine.prg")
		oDataExplorerEngine.RunScript(cUniqueID, THIS)
		oDataExplorerEngine = .NULL.
	ENDFUNC

	* Called by right-click to create a context menu
	* for this node.
	FUNCTION CreateContextMenu()
		LOCAL oContextMenu
		LOCAL nSelect
		LOCAL oCollection
		LOCAL i
		LOCAL j
		LOCAL nCnt
		LOCAL oDataExplorerEngine
		LOCAL nMenuCnt
		LOCAL ARRAY aScriptCode[1]
		
		oContextMenu = NEWOBJECT("ContextMenu", "foxmenu.prg")
		IF THIS.OnBeforeCreateMenu(oContextMenu)
		
			nMenuCnt = 0
			oDataExplorerEngine = NEWOBJECT("DataExplorerEngine", "DataExplorerEngine.prg")
			oCollection = oDataExplorerEngine.GetMenuItems(THIS)
			oDataExplorerEngine = .NULL.
			FOR i = 1 TO oCollection.Count
				IF !(oCollection.Item(i).Caption == "\-" AND (i == oCollection.Count OR i == 1))
					nMenuCnt = nMenuCnt + 1
					oContextMenu.AddMenu(RTRIM(oCollection.Item(i).Caption), "oCurrentNode.RunScript([" + oCollection.Item(i).UniqueID + "])")
				ENDIF
			ENDFOR

			IF !THIS.EndNode
				IF nMenuCnt > 0
					oContextMenu.AddMenu("\-")
				ENDIF
				* add in Refresh item
				oContextMenu.AddMenu(MENU_REFRESH_LOC, "oCurrentNode.RefreshNode()")
			ENDIF
			
			THIS.OnAfterCreateMenu(oContextMenu)
		ENDIF

		RETURN oContextMenu
	ENDFUNC
	

	FUNCTION EvalText(cScript)
		LOCAL cEvalScript
		LOCAL oException
		
		cEvalScript = cScript
		IF LEFT(cScript, 1) == '(' AND RIGHT(cScript, 1) == ')'
			TRY
				cEvalScript = EVALUATE(cScript)
			CATCH TO oException
				MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, DATAEXPLORER_LOC)
			ENDTRY
		ENDIF
		RETURN cEvalScript
	ENDFUNC

	* -- OPTION METHODS ---
	PROCEDURE Options_Assign(cOptions)
		THIS.ParseOptionString(m.cOptions)
		THIS.Options = m.cOptions
	ENDPROC

	PROCEDURE OptionData_Assign(cOptionData)
		THIS.ParseOptionDataString(m.cOptionData)
		THIS.OptionData = m.cOptionData
	ENDPROC
	
	FUNCTION OptionData_Access
		LOCAL cOptionData
		LOCAL i
		
		cOptionData = ''
		FOR i = 1 TO THIS.oOptionCollection.Count
			IF !THIS.oOptionCollection.Item(i).OptionTemporary
				cOptionData = cOptionData + IIF(EMPTY(cOptionData), '', CHR(13) + CHR(10)) + THIS.oOptionCollection.Item(i).OptionName + '=' + TRANSFORM(THIS.oOptionCollection.Item(i).OptionValue)
			ENDIF
		ENDFOR
		
		RETURN cOptionData
	ENDFUNC	

	* parse string in DataExplorer.Options, adding each option to the collection
	* (note: format is similar to an .INI file)
	FUNCTION ParseOptionString(cOptions)
		LOCAL i
		LOCAL nCnt
		LOCAL cValue
		LOCAL cAttrib
		LOCAL nPos
		LOCAL oOption
		LOCAL ARRAY aOptions[1]


		m.oOption = .NULL.
		m.nCnt = ALINES(m.aOptions, STRTRAN(m.cOptions, CHR(13), ''), .T., CHR(10))
		FOR m.i = 1 TO m.nCnt
			IF !EMPTY(m.aOptions[m.i])
				IF LEFT(m.aOptions[m.i], 1) = '[' AND RIGHT(m.aOptions[m.i], 1) == ']'
					m.oOption = CREATEOBJECT("Option")
					m.oOption.OptionName = STREXTRACT(m.aOptions[m.i], '[', ']')

					THIS.AddOption(m.oOption)
				ELSE
					IF !ISNULL(m.oOption)
						m.nPos = AT('=', m.aOptions[m.i])
						IF m.nPos > 1
							m.cAttrib = ALLTRIM(LOWER(LEFT(m.aOptions[m.i], m.nPos - 1)))
							m.cValue  = ALLTRIM(SUBSTR(m.aOptions[m.i], m.nPos + 1))
							
							DO CASE
							CASE m.cAttrib = "value"
								m.oOption.OptionValue = m.cValue

							CASE m.cAttrib = "classlib"
								m.oOption.OptionClassLib = m.cValue

							CASE m.cAttrib = "classname"
								m.oOption.OptionClassName = m.cValue

							CASE m.cAttrib = "caption"
								m.oOption.OptionCaption = m.cValue

							CASE m.cAttrib = "valueproperty"
								m.oOption.ValueProperty = m.cValue

							OTHERWISE
								TRY
									m.oOption.oPropertyCollection.Add(m.cValue, m.cAttrib)
								CATCH
								ENDTRY
							ENDCASE
						ENDIF
					ENDIF
				ENDIF
			ENDIF
		ENDFOR
	ENDFUNC

	* Parse option data as it is stored in OptionData
	* Look for options in the following format:
	*	ZipCode=33458
	*	Name=Ryan
	*	<cOptions> = string of options
	FUNCTION ParseOptionDataString(cOptions)
		LOCAL i
		LOCAL nCnt
		LOCAL nPos
		LOCAL ARRAY aOptions[1]

		m.nCnt = ALINES(aOptions, STRTRAN(cOptions, CHR(13), ''), .T., CHR(10))
		FOR m.i = 1 TO m.nCnt
			m.nPos = AT('=', aOptions[i])
			IF m.nPos > 1
				THIS.SetOption(LEFT(aOptions[m.i], m.nPos - 1), SUBSTR(aOptions[m.i], m.nPos + 1))
			ENDIF
		ENDFOR
	ENDFUNC	
	
	* Add an option to the option collection
	FUNCTION AddOption(oOption AS Option)
		IF VARTYPE(m.oOption) == 'O' AND !EMPTY(m.oOption.OptionName)
			TRY
				THIS.oOptionCollection.Add(m.oOption, m.oOption.OptionName)
			CATCH
			ENDTRY		
		ENDIF
	ENDFUNC

	* Add an option to the option collection
	FUNCTION CreateOption(cOptionName, xDefaultValue, lTemporary)
		LOCAL oOption
		
		m.oOption = CREATEOBJECT("Option")
		m.oOption.OptionName  = cOptionName
		m.oOption.OptionValue = TRANSFORM(xDefaultValue)
		m.oOption.OptionTemporary = lTemporary
		TRY
			THIS.oOptionCollection.Add(m.oOption, m.oOption.OptionName)
		CATCH
		ENDTRY		
	ENDFUNC

	FUNCTION GetOptionByName(cOptionName)
		LOCAL oOption
		LOCAL i
		
		m.cOptionName = LOWER(m.cOptionName)
		
		m.oOption = .NULL.
		FOR m.i = 1 TO THIS.oOptionCollection.Count
			IF LOWER(THIS.oOptionCollection.Item(m.i).OptionName) == m.cOptionName
				m.oOption = THIS.oOptionCollection.Item(m.i)
				EXIT
			ENDIF
		ENDFOR
		
		RETURN m.oOption
	ENDFUNC

	* Set an option value
	* 	<cOptionName> = option name to set
	* 	<cOptionValue> = option value
	FUNCTION SetOption(cOptionName, cOptionValue)
		LOCAL oOption
		LOCAL lSuccess
		
		m.oOption = THIS.GetOptionByName(m.cOptionName)
		m.lSuccess = VARTYPE(m.oOption) == 'O'
		IF m.lSuccess
			m.oOption.OptionValue = m.cOptionValue
		ENDIF
		
		RETURN m.lSuccess
	ENDFUNC

	* Return an option value
	* 	<cOptionName> = option name to return
	* 	[xDefault] = default to return if option not found
	*   [lSearch] = search up the nodes for option
	FUNCTION GetOption(cOptionName, xDefault, lSearch)
		LOCAL oOption
		LOCAL cOptionValue
		LOCAL cDataType
		LOCAL oNode

		IF PCOUNT() > 1
			m.cDataType = VARTYPE(xDefault)
		ELSE
			m.cDataType = 'C'
		ENDIF

		IF m.lSearch
			* search all parent nodes for a matching option
			oNode = THIS
			DO WHILE !ISNULL(oNode)
				m.oOption = oNode.GetOptionByName(m.cOptionName)
				IF !ISNULL(m.oOption)
					EXIT
				ENDIF
				oNode = oNode.ParentNode
			ENDDO
		ELSE
			m.oOption = THIS.GetOptionByName(m.cOptionName)
		ENDIF

		IF VARTYPE(m.oOption) == 'O'
			m.cOptionValue = TRANSFORM(m.oOption.OptionValue)
		ELSE
			IF PCOUNT() > 1
				m.cOptionValue = TRANSFORM(m.xDefault)
			ELSE
				m.cOptionValue = ''
			ENDIF
		ENDIF
		
		DO CASE
		CASE m.cDataType == 'N'
			RETURN VAL(m.cOptionValue)
		CASE m.cDataType == 'L'
			RETURN (UPPER(m.cOptionValue) == ".T." OR m.cOptionValue == '1')
		OTHERWISE		
			RETURN m.cOptionValue
		ENDCASE
		
		RETURN xDefault
	ENDFUNC
	


	* Traverse up the tree looking for first node 
	* that has the specified option.
	FUNCTION FindOption(cOptionName, xDefaultValue)
		RETURN THIS.GetOption(cOptionName, xDefaultValue, .T.)
	ENDFUNC

	FUNCTION RemoveConnection()
		THIS.RemoveNode()
	ENDFUNC

	FUNCTION AddErrorNode(cErrorMsg)
		LOCAL oChildNode

		oChildNode = THIS.CreateNode("ErrorNode", '', cErrorMsg)
		THIS.AddNode(oChildNode)
	ENDFUNC

	FUNCTION AddNoChildrenNode()
		LOCAL oChildNode

		oChildNode = THIS.CreateNode("NoChildrenNode")
		THIS.AddNode(oChildNode)
	ENDFUNC

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


ENDDEFINE

* <summary>
* 	Root node.
* </summary>
DEFINE CLASS RootNode AS INode
	NodeID   = "root"
	NodeText = NODETEXT_ROOT_LOC
	ExpandOnInit = .T.
	
	* Load in all active root nodes, etc
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oDataExplorerEngine
		LOCAL oCollection
		LOCAL nIndex
		
		oDataExplorerEngine = NEWOBJECT("DataExplorerEngine", "DataExplorerEngine.prg")

		oCollection = oDataExplorerEngine.GetRootNodes()
		FOR nIndex = 1 TO oCollection.Count
			oChildNode = THIS.CreateNode(oCollection.Item(nIndex).ClassName, oCollection.Item(nIndex).ClassLib)
			oChildNode.Options    = oCollection.Item(nIndex).Options
			oChildNode.OptionData = oCollection.Item(nIndex).OptionData

			THIS.AddNode(oChildNode)
		ENDFOR
		
		oDataExplorerEngine = .NULL.
		
		RETURN .T.
	ENDFUNC

	* Persist all user-added connections in the tree
	FUNCTION Save()
		LOCAL oDataExplorerEngine 

		oDataExplorerEngine = NEWOBJECT("DataExplorerEngine", "DataExplorerEngine.prg")
		oDataExplorerEngine.Save(THIS)
		oDataExplorerEngine = .NULL.
	ENDFUNC

	FUNCTION ShowFilterOkay()
		RETURN .F.
	ENDFUNC

ENDDEFINE


* <summary>
* 	Connections node.
* </summary>
DEFINE CLASS ConnectionsNode AS INode
	ImageKey = "microsoft.imageconns"
	NodeID   = "connections"
	NodeText = NODETEXT_CONNECTIONS_LOC
	
	ExpandOnInit = .T.
	
	* Load in all active connections, etc
	FUNCTION OnPopulate()
		LOCAL oChildNode
		LOCAL oDataExplorerEngine
		LOCAL oCollection
		LOCAL i
		
		
		oDataExplorerEngine = NEWOBJECT("DataExplorerEngine", "DataExplorerEngine.prg")
		oCollection = oDataExplorerEngine.GetActiveConnections()
		FOR i = 1 TO oCollection.Count
			THIS.AddConnectionNode(oCollection.Item(i))
		ENDFOR
		oDataExplorerEngine = .NULL.
		
		RETURN .T.
	ENDFUNC




	* check to see if connection is is a duplicate and
	* if so ask to rename it.
	FUNCTION CheckDuplicateName(oNode)
		LOCAL i
		LOCAL oConnCollection
		LOCAL oDataExplorerEngine
		LOCAL lSuccess
		LOCAL oRootNode
		
		lSuccess = .T.

		oRootNode = THIS.GetRootNode()
		oRootNode.Save()
		
		* if this is a duplicate, then automatically display rename dialog
		oDataExplorerEngine = NEWOBJECT("DataExplorerEngine", "DataExplorerEngine.prg")
		oConnCollection = oDataExplorerEngine.GetActiveConnections()
		FOR i = 1 TO oConnCollection.Count
			IF UPPER(oConnCollection.Item(i).ConnName) == UPPER(oNode.NodeText)
				DO FORM NodeRename WITH oNode, .T. TO lSuccess
				EXIT
			ENDIF
		ENDFOR
		oDataExplorerEngine = .NULL.
		
		RETURN lSuccess
	ENDFUNC
	
	FUNCTION AddConnectionNode(oConn, lUserAdded)
		LOCAL nCnt
		LOCAL nPropIndex
		LOCAL cPropertyName
		LOCAL oNode
		LOCAL oException

		TRY
			oNode = THIS.CreateNode(oConn.ClassName, oConn.ClassLib)

			oNode.NodeID     = oConn.UniqueID
			oNode.DefType    = DEFTYPE_CONNECTION
			oNode.Options    = oConn.Options
			oNode.OptionData = oConn.OptionData

			IF !EMPTY(oConn.DataMgmtClass) AND !EMPTY(oConn.DataMgmtClassLibrary)
				oNode.DataMgmtClass = oConn.DataMgmtClass
				oNode.DataMgmtClassLibrary = oConn.DataMgmtClassLibrary
			ENDIF
			oNode.ProviderName = oConn.ProviderName

			* if this connection is being added for the first time, then
			* ask the user for connection info in the OnFirstConnect() method
			IF !lUserAdded OR oNode.FirstConnect(oConn)
				oNode.NodeText = EVL(oConn.ConnName, oNode.NodeText)
				oNode.NodeType = oConn.ConnType
				*oNode.NodeInfo = oConn.ConnInfo
				
				oNode.SaveNode = .T.

				IF !lUserAdded OR THIS.CheckDuplicateName(oNode)
					oConn.ConnName = oNode.NodeText
					THIS.AddNode(oNode)
					IF lUserAdded
						THIS.GotoNode(oNode)
					ENDIF
				ENDIF
			ENDIF
		CATCH TO oException
			MESSAGEBOX(ERROR_CREATECONNECTION_LOC + CHR(10) + CHR(10) + oException.Message, MB_ICONEXCLAMATION, DATAEXPLORER_LOC)
		ENDTRY

	ENDFUNC
	

	* Add a new connection	
	FUNCTION AddConnection(cConnTypeUniqueID)
		LOCAL oConn
		LOCAL oDataExplorerEngine
		
		oConn = .NULL.

		IF VARTYPE(cConnTypeUniqueID) == 'C' AND !EMPTY(cConnTypeUniqueID)
			oDataExplorerEngine = NEWOBJECT("DataExplorerEngine", "DataExplorerEngine.prg")
			oConn = oDataExplorerEngine.CreateConnection(cConnTypeUniqueID)
			oDataExplorerEngine = .NULL.
		ENDIF
		
		IF VARTYPE(oConn) <> 'O'
			DO FORM AddConnection TO oConn
		ENDIF
		
		IF VARTYPE(oConn) == 'O'
			* we now have the type of connection we want to add
			* (VFP Database, VFP Table, SQL Server, SQL Database, etc),
			* so now get additional info depending on the
			* connection type
			THIS.AddConnectionNode(oConn, .T.)
		ENDIF
		
	ENDFUNC

	FUNCTION ShowFilterOkay()
		RETURN .F.
	ENDFUNC

ENDDEFINE


* Interface for connection nodes
DEFINE CLASS IConnectionNode AS INode
	* Data managament class library and class to use
	DataMgmtClassLibrary = ''
	DataMgmtClass        = ''
	ProviderName         = ''

	* if we run the Script Code when we first create the connection and our
	* Data Mgmt Class changes, then set this to TRUE
	CustomDataMgmtClass = .F. 

	PROCEDURE OnInit()
		DODEFAULT()

		THIS.CreateOption("ShowColumnInfo", .F.)
		THIS.CreateOption("TrustedConnection", .T.)
		THIS.CreateOption("UserName", '')
	ENDPROC

	PROCEDURE FirstConnect(oConn)
		LOCAL lSuccess
		LOCAL oException
		LOCAL cDataMgmtClassLibrary
		LOCAL cDataMgmtClass
		LOCAL oTHIS
		
		lSuccess = THIS.OnFirstConnect()
		IF lSuccess
			* if connection object has ScriptCode defined, then
			* we execute that now so properties can be changed, etc
			* based upon the connection created
			IF !EMPTY(oConn.ScriptCode)
				TRY 
					cDataMgmtClassLibrary = UPPER(THIS.DataMgmtClassLibrary)
					cDataMgmtClass = UPPER(THIS.DataMgmtClass)

					oTHIS = THIS
					lSuccess = EXECSCRIPT(oConn.ScriptCode, oTHIS, THIS.GetConnection())
					IF VARTYPE(lSuccess) <> 'L'  && if script returns anything but T/F, then assume true
						lSuccess = .T.
					ENDIF
						
					THIS.CustomDataMgmtClass = !(UPPER(THIS.DataMgmtClassLibrary) == cDataMgmtClassLibrary) OR !(UPPER(THIS.DataMgmtClass) == cDataMgmtClass)
				CATCH TO oException
					MESSAGEBOX(ERROR_CREATECONNSCRIPT_LOC + CHR(10) + CHR(10) + oException.Message + CHR(10) + oException.LineContents, MB_ICONEXCLAMATION, DATAEXPLORER_LOC)
				ENDTRY
			ENDIF
		ENDIF
		
		RETURN lSuccess
	ENDPROC
	
	* called the first time a node of this type is created
	* (not instantiated -- but created.  For example, the user
	* right-clicks on Connections and selects "Create New Connection"
	FUNCTION OnFirstConnect()
		THIS.SetOption("ShowColumnInfo", THIS.GetConfigValue("ShowColumnInfo", .F.))
		RETURN .T.
	ENDFUNC

	FUNCTION GetConnection(cServerName, cDatabaseName)
		RETURN .NULL.
	ENDFUNC

	
	FUNCTION GetDataMgmtObject()
		LOCAL oException
		LOCAL oDataMgmt
		
		oDataMgmt = .NULL.
		TRY
			oDataMgmt = NEWOBJECT(THIS.DataMgmtClass, THIS.DataMgmtClassLibrary)
		CATCH TO oException
			MESSAGEBOX(ERROR_CREATEDATAMGMT_LOC + CHR(10) + CHR(10) + oException.Message + CHR(10) + CHR(10) + "(" + THIS.DataMgmtClass + "," + THIS.DataMgmtClassLibrary + ")", MB_ICONSTOP, DATAEXPLORER_LOC)
		ENDTRY
		RETURN oDataMgmt
	ENDFUNC

	* return a list of available SQL servers
	FUNCTION GetAvailableServers()
		LOCAL oConn
		LOCAL oServerList

		* create a SQL database management object, which we'll
		* use to get available SQL servers
		oConn = THIS.GetConnection()
		oServerList = oConn.GetAvailableServers()
		
		RETURN oServerList		
	ENDFUNC

	* return a list of available database for given server	
	FUNCTION GetAvailableDatabases(cServerName)
		LOCAL oConn
		LOCAL oDatabaseList
		LOCAL i
		LOCAL oException
		
		oDatabaseList = .NULL.		
		TRY
			oConn = THIS.GetDataMgmtObject()
			IF oConn.Connect(cServerName)
				oDatabaseList = oConn.GetDatabases()
			ENDIF
		CATCH TO oException
			MessageBox(IIF(VARTYPE(oException.UserValue) == 'C' AND !EMPTY(oException.UserValue), oException.UserValue, oException.Message), MB_ICONEXCLAMATION, DATAEXPLORER_LOC)
		ENDTRY
		
		RETURN oDatabaseList
	ENDFUNC


	FUNCTION DataTypeToString(cDataType, nLength, nDecimals)
		LOCAL cDisplayAs
		
		cDisplayAs = cDataType
		IF VARTYPE(nLength) == 'N' AND nLength > 0
			cDisplayAs = cDisplayAs + " (" + TRANSFORM(nLength) + IIF(VARTYPE(nDecimals) == 'N', ", " + TRANSFORM(nDecimals), '') + ")"
		ENDIF
		
		RETURN cDisplayAs
	ENDFUNC

	FUNCTION ExecuteQuery(cSQL, cAlias) AS String
		LOCAL oConn
		LOCAL cResult

		* hand off to the connection object
		oConn = THIS.GetConnection()
		oConn.ExecuteQuery(cSQL, cAlias)

		cResult = oConn.QueryResultOutput
		
		oConn = .NULL.
		
		RETURN cResult
	ENDFUNC


	FUNCTION RunQuery(cSQL)
		LOCAL oConn

		* hand off to the connection object
		IF VARTYPE(cSQL) <> 'C'
			cSQL = THIS.OnDefaultQuery()
		ENDIF

		IF VARTYPE(cSQL) == 'C'
			oConn = THIS.GetConnection()
			oConn.RunQuery(cSQL)
		ENDIF
	ENDFUNC


	* return default query for Run Query statement for this specific node type
	FUNCTION OnDefaultQuery()
		RETURN ''
	ENDFUNC


	* delimit passed object name if spaces found
	FUNCTION FixName(cObjName)
		IF ' ' $ cObjName
			RETURN '"' + cObjName + '"'
		ELSE
			RETURN cObjName
		ENDIF
	ENDFUNC

ENDDEFINE


DEFINE CLASS ErrorNode AS INode OF TreeNodes.prg
	ImageKey = "microsoft.imageerror"
	EndNode = .T.

	PROCEDURE Init(cNodeText, xNodeData)
		THIS.NodeID = "msg." + SYS(2015)

		DODEFAULT(cNodeText, xNodeData)
	ENDPROC

ENDDEFINE

DEFINE CLASS NotSupportedNode AS INode OF TreeNodes.prg
	ImageKey = "microsoft.imageerror"
	EndNode = .T.

	NodeText = NOT_SUPPORTED_LOC
	
	PROCEDURE Init(cNodeText, xNodeData)
		THIS.NodeID = "msg." + SYS(2015)

		DODEFAULT(cNodeText, xNodeData)
	ENDPROC

ENDDEFINE

DEFINE CLASS NoChildrenNode AS INode OF TreeNodes.prg
	ImageKey = ""
	EndNode = .T.
	
	NodeText = NO_CHILDREN_LOC
	
	PROCEDURE Init(cNodeText, xNodeData)
		THIS.NodeID = "msg." + SYS(2015)

		DODEFAULT(cNodeText, xNodeData)
	ENDPROC
ENDDEFINE


DEFINE CLASS Option AS Custom
	ADD OBJECT oPropertyCollection AS Collection

	OptionName        = ''
	OptionValue       = ''
	OptionTemporary   = .F.
	OptionCaption     = ''
	OptionClassName   = "cfoxtextbox"
	OptionClassLib    = ''
	ValueProperty     = "value"
ENDDEFINE



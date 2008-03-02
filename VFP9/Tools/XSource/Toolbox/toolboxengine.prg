* Program....: ToolboxEngine.prg
* Notice.....: Copyright (c) 2002 Microsoft Corp.
* Compiler...: Visual FoxPro 8.0
* Abstract...:
*	This is the engine for Toolbox functionality.
* Changes....:
#include "foxpro.h"
#include "toolbox.h"


DEFINE CLASS ToolboxEngine AS Custom
	Name = "ToolboxEngine"
	
	ToolboxTable     = ADDBS(HOME(7)) + "Toolbox.dbf"
	SystemDirectory  = ADDBS(HOME()) + "Toolbox\"
	ToolTypeTable    = "ToolType.dbf"

	DefaultClassLib  = ''

	RedrawToolbox = .T.

	lDeferLoad = .F.
	
	lCustomizeMode = .F.  && true if instantiated for customizing the toolbox

	CurrentCategory = .NULL.
	oCategoryCollection = .NULL.
	
	FilterID = '' && current category filter ID
	FilterName = ''
	
	Category = '' && current category

	ScrollSpeed      = SCROLLSPEED_DEFAULT  && scroll speed within a category (in milliseconds)
	FontString       = FONT_DEFAULT
	BuilderLock      = .F.  && run builder on drop
	ShowHelpText     = .T.  && show help text
	ShowAlwaysOnTop  = .T.  && show toolbox as Always On Top
	DblClickToOpen   = .F.  && require double-click to open hyperlink items
	ShowToolTips     = .T.  && show toolbox tooltips
	NamingConvention = 1    && how to name class items added to toolbox
	DropText         = ''   && template to use when drop a class on a code window
	CtrlDropText     = ''   && template to use when a ctrl+drop is done on a code window
	ColumnSetCurrentControl = .F. && set CurrentControl property when dropping control on a column
	ColumnRemoveText1       = .T. && prompt to remove Text1 property when new control dropped on column
	AllowMinimize    = .F.   && allow toolbox to be minimized

	LastCategoryID  = ''   && last displayed CategoryID

	lInitError = .F.
	
	nNewFilterNum = 0

	cFontName  = "Tahoma"
	nFontSize  = 8
	cFontStyle = 'N'
	
	cTopToolString = ''

	ADD OBJECT PROTECTED tmrBuilder AS BuilderDelay 

	PROCEDURE Init(lCustomizeMode, lNoOpen)
		LOCAL ARRAY aFileList[1]

		THIS.RestorePrefs()

		THIS.oCategoryCollection = CREATEOBJECT("Collection")

		THIS.DefaultClassLib = FULLPATH(DEFAULT_CLASSLIB)
		IF !FILE(THIS.DefaultClassLib)
			THIS.DefaultClassLib = THIS.SystemDirectory + DEFAULT_CLASSLIB
			IF !FILE(THIS.DefaultClassLib)
				* we didn't find the version on disk at HOME() + "Toolbox", 
				* so use version that's bound into the APP
				THIS.DefaultClassLib = INTERNAL_CLASSLIB
			ENDIF
		ENDIF	

		THIS.lCustomizeMode = lCustomizeMode

		IF !m.lNoOpen
			THIS.lInitError = !THIS.LoadToolbox(.T.)
		ENDIF
		
	ENDPROC


	PROCEDURE Destroy()
		IF USED("ToolboxCursor")
			USE IN ToolboxCursor
		ENDIF
		IF USED("Toolbox")
			USE IN Toolbox
		ENDIF
		IF USED("ToolType")
			USE IN ToolType
		ENDIF
		IF USED("VirtualCursor")
			USE IN VirtualCursor
		ENDIF
	ENDPROC

	* we use BINDEVENT() in Toolbox form to bind to this in order to
	* refresh toolbox as necessary -- DO NOT REMOVE (even though it's empty)!!!
	PROCEDURE RefreshUI()
		*** do not remove!!!
	ENDPROC


	PROCEDURE ScrollSpeed_Access
		RETURN MAX(THIS.ScrollSpeed, 5)  && make sure it's a reasonable value
	ENDPROC



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

	
	PROCEDURE FilterName_Access
		LOCAL cFilterName
		
		m.cFilterName = ''
		IF !EMPTY(THIS.FilterID)
			IF SEEK(THIS.FilterID, "ToolboxCursor", "UniqueID")
				m.cFilterName = RTRIM(ToolboxCursor.ToolName)
			ENDIF
		ENDIF

		RETURN m.cFilterName
	ENDPROC


	PROCEDURE Category_Access
		LOCAL cCategory
		
		m.cCategory = ''
		IF VARTYPE(THIS.CurrentCategory) == 'O'
			IF SEEK(THIS.CurrentCategory.UniqueID, "ToolboxCursor", "UniqueID")
				m.cCategory = RTRIM(ToolboxCursor.ToolName)
			ENDIF
		ENDIF

		RETURN m.cCategory
	ENDPROC



	* set category by name
	PROCEDURE Category_Assign(cCategory)
		LOCAL nSelect

		IF VARTYPE(m.cCategory) == 'C' AND !EMPTY(m.cCategory)
			* find the category by name
			nSelect = SELECT()

			m.cCategory = ALLTRIM(UPPER(m.cCategory))
			SELECT ToolboxCursor
			LOCATE FOR ShowType == SHOWTYPE_CATEGORY AND UPPER(ALLTRIM(ToolName)) == m.cCategory
			IF FOUND()
				THIS.SetCategory(ToolboxCursor.UniqueID)
				THIS.RefreshUI()
			ENDIF

			SELECT (nSelect)
		ENDIF
	ENDPROC

	
	FUNCTION SavePrefs()
		LOCAL oResource AS FoxResource, cTopTool, i

		m.oResource = NEWOBJECT("FoxResource", "FoxResource.prg")

		m.oResource.Load("TOOLBOX")
		m.oResource.Set("ToolboxTable", FORCEEXT(THIS.ToolboxTable, "dbf"))
		m.oResource.Set("FilterID", THIS.FilterID)
		m.oResource.Set("ScrollSpeed", THIS.ScrollSpeed)
		m.oResource.Set("FontString", THIS.FontString)
		m.oResource.Set("BuilderLock", THIS.BuilderLock)
		m.oResource.Set("ShowHelpText", THIS.ShowHelpText)
		m.oResource.Set("ShowToolTips", THIS.ShowToolTips)
		m.oResource.Set("ShowAlwaysOnTop", THIS.ShowAlwaysOnTop)
		m.oResource.Set("DblClickToOpen", THIS.DblClickToOpen)
		m.oResource.Set("LastCategoryID", THIS.LastCategoryID)

		m.oResource.Set("NamingConvention", THIS.NamingConvention)
		m.oResource.Set("DropText", THIS.DropText)
		m.oResource.Set("CtrlDropText", THIS.CtrlDropText)
		m.oResource.Set("ColumnSetCurrentControl", THIS.ColumnSetCurrentControl)
		m.oResource.Set("ColumnRemoveText1", THIS.ColumnRemoveText1)
		m.oResource.Set("AllowMinimize", THIS.AllowMinimize)

		* save the first displayed tool button in each category as a comma-delimited list
		m.cTopTool = ''
		IF TYPE("THIS.oCategoryCollection") == 'O' AND !ISNULL(THIS.oCategoryCollection)
			FOR m.i = 1 TO THIS.oCategoryCollection.Count
				m.cTopTool = m.cTopTool + IIF(EMPTY(m.cTopTool), '', ',') + THIS.oCategoryCollection(m.i).UniqueID + '=' + THIS.oCategoryCollection(m.i).TopToolID
			ENDFOR
			m.oResource.Set("TopTool", m.cTopTool)
		ENDIF

		m.oResource.Save("TOOLBOX")
	
		m.oResource = .NULL.
		
	ENDFUNC

	
	FUNCTION RestorePrefs()
		LOCAL oResource
		LOCAL i
		LOCAL nCnt
		LOCAL cUniqueID
		LOCAL cTopToolID
		LOCAL ARRAY aTopTool[1]

		m.oResource = NEWOBJECT("FoxResource", "FoxResource.prg")
		m.oResource.Load("TOOLBOX")
		
		THIS.ToolboxTable     = NVL(m.oResource.Get("ToolboxTable"), '')
		THIS.FilterID         = NVL(m.oResource.Get("FilterID"), '')
		THIS.ScrollSpeed      = NVL(m.oResource.Get("ScrollSpeed"), THIS.ScrollSpeed)
		THIS.FontString       = NVL(m.oResource.Get("FontString"), THIS.FontString)
		THIS.BuilderLock      = NVL(m.oResource.Get("BuilderLock"), THIS.BuilderLock)
		THIS.ShowHelpText     = NVL(m.oResource.Get("ShowHelpText"), THIS.ShowHelpText)
		THIS.ShowToolTips     = NVL(m.oResource.Get("ShowToolTips"), THIS.ShowToolTips)
		THIS.ShowAlwaysOnTop  = NVL(m.oResource.Get("ShowAlwaysOnTop"), THIS.ShowAlwaysOnTop)
		THIS.DblClickToOpen   = NVL(m.oResource.Get("DblClickToOpen"), THIS.DblClickToOpen)
		THIS.LastCategoryID   = NVL(m.oResource.Get("LastCategoryID"), '')

		THIS.NamingConvention = NVL(m.oResource.Get("NamingConvention"), THIS.NamingConvention)
		THIS.DropText         = NVL(m.oResource.Get("DropText"), THIS.DropText)
		THIS.CtrlDropText     = NVL(m.oResource.Get("CtrlDropText"), THIS.CtrlDropText)
		THIS.ColumnSetCurrentControl = NVL(m.oResource.Get("ColumnSetCurrentControl"), THIS.ColumnSetCurrentControl)
		THIS.ColumnRemoveText1       = NVL(m.oResource.Get("ColumnRemoveText1"), THIS.ColumnRemoveText1)

		THIS.AllowMinimize = NVL(m.oResource.Get("AllowMinimize"), THIS.AllowMinimize)
		
		IF VARTYPE(THIS.NamingConvention) <> 'N'
			THIS.NamingConvention = 1
		ENDIF
		IF VARTYPE(THIS.DropText) <> 'C'
			THIS.DropText = ''
		ENDIF
		IF VARTYPE(THIS.CtrlDropText) <> 'C'
			THIS.CtrlDropText = ''
		ENDIF

		IF EMPTY(THIS.ToolboxTable)
			THIS.ToolboxTable = ADDBS(HOME(7)) + "Toolbox.dbf"
		ENDIF
		THIS.ToolboxTable = FORCEEXT(THIS.ToolboxTable, "dbf")
		
		THIS.ParseFontString()

		* retrieve the first tool to display in each category
		THIS.cTopToolString = NVL(m.oResource.Get("TopTool"), '')
		
		m.oResource = .NULL.
	ENDFUNC


	* create toolbox
	FUNCTION CreateToolbox(m.cTableName)
		LOCAL oException
		LOCAL lSuccess
		LOCAL nSelect
		
		m.nSelect = SELECT()

		m.lSuccess = .T.

		IF VARTYPE(m.cTableName) <> 'C' OR EMPTY(m.cTableName)
			m.cTableName = THIS.ToolboxTable
		ENDIF

		TRY
			USE ToolboxDefault IN 0 SHARED AGAIN
			SELECT ToolboxDefault
			COPY TO (m.cTableName) WITH PRODUCTION

		CATCH TO oException
			MESSAGEBOX(oException.Message, MB_ICONSTOP, TOOLBOX_LOC)
			m.lSuccess = .F.
		FINALLY
			IF USED("ToolboxDefault")
				USE IN ToolboxDefault
			ENDIF
		ENDTRY
		
		
		IF m.lSuccess
			THIS.ToolboxTable = m.cTableName
		ENDIF
		
		SELECT (m.nSelect)

		RETURN m.lSuccess		
	ENDFUNC

	* return TRUE if specified alias or DBF is a valid toolbox table
	FUNCTION IsToolboxTable(cTable, lQuiet)
		LOCAL cAlias
		LOCAL lOkay
		LOCAL oException
		LOCAL lCloseTable
		
		m.lOkay = .F.

		IF USED(m.cTable) && already open
			m.cAlias = m.cTable
			m.lCloseTable = .F.
		ELSE
			m.lCloseTable = .T.
			m.cAlias = "TB" + SYS(2015)
			m.cTable = FORCEEXT(m.cTable, "dbf")
			IF FILE(m.cTable)
				TRY
					USE (m.cTable) ALIAS (m.cAlias) IN 0 SHARED AGAIN
				CATCH TO oException
					m.lOkay = .F.
					IF !m.lQuiet
						MESSAGEBOX(m.oException.Message, MB_ICONEXCLAMATION, TOOLBOX_LOC)
					ENDIF
				ENDTRY
			ENDIF
		ENDIF

		IF USED(m.cAlias)
			m.lOkay = TYPE(m.cAlias + ".ToolTypeID") == 'C'

			IF m.lCloseTable
				USE IN (m.cAlias)
			ENDIF
			
			IF !m.lOkay
				IF !m.lQuiet
					MESSAGEBOX(ERROR_BADTABLE_LOC + CHR(10) + CHR(10) + m.cTable, MB_ICONEXCLAMATION, TOOLBOX_LOC)
				ENDIF
			ENDIF
		ENDIF
		
		RETURN m.lOkay
	ENDFUNC

	* open the tables associated with the toolbox
	FUNCTION OpenToolbox(lCustomizeMode, cAlias)
		LOCAL oException
		LOCAL lSuccess
		LOCAL cTableName
		LOCAL ARRAY aFindFile[1]

		m.oException = .NULL.

		IF PCOUNT() == 0
			m.lCustomizeMode = THIS.lCustomizeMode
		ENDIF

		IF VARTYPE(m.cAlias) <> 'C' OR EMPTY(m.cAlias)
			m.cAlias = "ToolboxCursor"
		ENDIF

		IF !USED(m.cAlias)
			* first, look for the table in the path specified
			m.cTableName = THIS.ToolboxTable
			TRY
				m.lSuccess = ADIR(aFindFile, FORCEEXT(m.cTableName, "dbf")) > 0
			CATCH TO oException
				m.lSuccess = .F.
				MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, TOOLBOX_LOC)
			ENDTRY
			IF !m.lSuccess
				m.cTableName = ''
				* loop until we find a valid toolbox table or they Cancel out of the Locate dialog
				m.lSuccess = .F.
				DO WHILE !m.lSuccess
					IF !EMPTY(m.cTableName)
						IF THIS.IsToolboxTable(m.cTableName)
							m.lSuccess = .T.
						ELSE
							m.cTableName = ''
						ENDIF
					ENDIF

					IF !m.lSuccess
						DO FORM ToolboxLocate WITH THIS TO m.cTableName
						IF EMPTY(m.cTableName)
							EXIT
						ENDIF
					ENDIF
				ENDDO
			ENDIF
						
			IF m.lSuccess
				THIS.ToolboxTable = m.cTableName
				TRY
					IF m.lCustomizeMode
						SELECT ;
						  Toolbox.* ;
						 ORDER BY Toolbox.DisplayOrd ;
						 FROM (m.cTableName) Toolbox ;
						 INTO CURSOR (m.cAlias) READWRITE
						
						IF USED(JUSTSTEM(m.cTableName))
							USE IN (JUSTSTEM(m.cTableName))
						ENDIF
						
						IF USED("Toolbox")
							USE IN Toolbox
						ENDIF

						SELECT (m.cAlias)
						INDEX ON UniqueID TAG UniqueID
						INDEX ON DisplayOrd TAG DisplayOrd
						* INDEX ON UPPER(ToolName) TAG ToolName
						* INDEX ON UPPER(ToolType) TAG ToolType
						SET ORDER TO 
					ELSE
						USE (m.cTableName) ALIAS (m.cAlias) IN 0 SHARED AGAIN
						SET ORDER TO DisplayOrd IN (m.cAlias)
					ENDIF
					
				CATCH TO oException
					MESSAGEBOX(oException.Message, MB_ICONSTOP, TOOLBOX_LOC)
					IF USED(m.cAlias)
						USE IN (m.cAlias)
					ENDIF
				ENDTRY
			ENDIF
		ENDIF
		
		RETURN USED(m.cAlias)
	ENDFUNC

	* open the ToolType table
	FUNCTION OpenToolType(cAlias)
		LOCAL lSuccess
		LOCAL nSelect
		LOCAL oException
		LOCAL nCnt
		LOCAL ARRAY aFileFind[1]

		m.nSelect = SELECT()

		IF VARTYPE(m.cAlias) <> 'C' OR EMPTY(m.cAlias)
			m.cAlias = "ToolType"
		ENDIF

		m.lSuccess = .F.		
		IF USED(m.cAlias)
			m.lSuccess = .T.
		ELSE
			m.cTableName = FORCEPATH(THIS.ToolTypeTable, THIS.SystemDirectory)
			
			TRY
				m.nCnt = ADIR(aFileFind, FORCEEXT(m.cTableName, "dbf"))
			CATCH TO oException
				m.nCnt = 0
				MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, TOOLBOX_LOC)
			ENDTRY
			IF m.nCnt == 0
				* create the ToolType table
				TRY
					USE ToolTypeDefault IN 0 SHARED AGAIN
					SELECT ToolTypeDefault
					COPY TO (m.cTableName) WITH PRODUCTION
				CATCH TO oException
					* unsuccessful in copying the table, so just use the internal version
					m.cTableName = ''
				FINALLY
					IF USED("ToolTypeDefault")
						USE IN ToolTypeDefault
					ENDIF
				ENDTRY
			ENDIF

			IF !EMPTY(m.cTableName)
				TRY
					USE (m.cTableName) ALIAS (m.cAlias) IN 0 SHARED AGAIN
				CATCH
					m.cTableName = ''
				ENDTRY
				IF USED(m.cAlias) AND TYPE(m.cAlias + ".ToolType") <> 'C'
					USE IN (m.cAlias)
					m.cTableName = ''
				ENDIF
			ENDIF
			
			* use our internal version
			IF EMPTY(m.cTableName)
				TRY
					SELECT * FROM ToolTypeDefault INTO CURSOR (m.cAlias)
					USE ToolTypeDefault ALIAS (m.cAlias) IN 0 SHARED AGAIN
				CATCH
				ENDTRY
			ENDIF
			
			m.lSuccess = USED("ToolType")
		ENDIF

		SELECT (m.nSelect)

		RETURN m.lSuccess
	ENDFUNC


	FUNCTION GenerateUniqueID()
		RETURN "user." + SYS(2015)
	ENDFUNC

	* --- START OF TOOLBOX METHODS ---
	FUNCTION LoadToolbox(lFirstLoad)
		LOCAL nSelect
		LOCAL lSuccess
		LOCAL oCategory
		LOCAL oRec
		LOCAL nFilterCnt
		LOCAL ARRAY aTopTool[1]
		LOCAL nCnt
		LOCAL i
		LOCAL cTopToolID
		LOCAL ARRAY aFilter[1]

		IF THIS.lDeferLoad
			RETURN
		ENDIF
		
		IF !m.lFirstLoad AND THIS.lCustomizeMode
			RETURN
		ENDIF

		m.nSelect = SELECT()
		
		IF USED("ToolboxCursor")
			USE IN ToolboxCursor
		ENDIF

		THIS.oCategoryCollection.Remove(-1)

		IF m.lFirstLoad
			THIS.CurrentCategory = .NULL.
		ENDIF

		m.lSuccess = THIS.OpenToolbox()
		IF m.lSuccess
			m.nFilterCnt = -1
			IF !THIS.lCustomizeMode AND !EMPTY(THIS.FilterID)
				IF SEEK(THIS.FilterID, "ToolboxCursor", "UniqueID")
					SELECT ToolName ;
					 FROM ToolboxCursor ;
					 WHERE ;
					  ParentID == THIS.FilterID AND !Inactive ;
					 INTO ARRAY aFilter
					m.nFilterCnt = _TALLY
				ELSE
					THIS.FilterID = ''
				ENDIF
			ENDIF

			* convert the string of first tool to display within categories to an array
			m.nCnt = ALINES(aTopTool, THIS.cTopToolString, ',')

			* add in normal category tabs
			SELECT ToolboxCursor
			SCAN ALL FOR (ShowType == SHOWTYPE_CATEGORY OR ShowType == SHOWTYPE_FAVORITES)
				IF !Inactive OR THIS.lCustomizeMode
					* if we have a filter set, then make sure this category
					* is in that filter
					IF m.nFilterCnt < 0 OR ASCAN(aFilter, PADR(ToolboxCursor.UniqueID, LEN(ToolboxCursor.ToolName))) > 0
						oCategory = CREATEOBJECT("ToolboxCategory")
						oCategory.UniqueID = RTRIM(ToolboxCursor.UniqueID)
						oCategory.ToolTypeID = ToolboxCursor.ToolTypeID
						oCategory.ToolType   = ToolboxCursor.ToolType
						oCategory.ToolName   = RTRIM(ToolboxCursor.ToolName)
						oCategory.ParentID   = ToolboxCursor.ParentID
						oCategory.ClassType  = ToolboxCursor.ClassType
						oCategory.SetID      = ToolboxCursor.SetID
						oCategory.ClassName  = ToolboxCursor.ClassName
						oCategory.ClassLib   = ToolboxCursor.ClassLib
						oCategory.ToolTip    = ToolboxCursor.ToolTip
						oCategory.HelpFile   = ToolboxCursor.HelpFile
						oCategory.HelpID     = ToolboxCursor.HelpID
						oCategory.User       = ToolboxCursor.User

						* determine the topmost tool to display in this category
						FOR m.i = 1 TO m.nCnt
							IF oCategory.UniqueID == GETWORDNUM(aTopTool[m.i], 1, '=')
								m.cTopToolID = GETWORDNUM(aTopTool[m.i], 2, '=')
								
								IF !EMPTY(m.cTopToolID)
									oCategory.TopToolID = m.cTopToolID
								ENDIF
								EXIT
							ENDIF
						ENDFOR


						THIS.oCategoryCollection.Add(oCategory, oCategory.UniqueID)

					ENDIF
				ENDIF
			ENDSCAN

			IF m.lFirstLoad AND THIS.oCategoryCollection.Count > 0
				THIS.CurrentCategory = THIS.oCategoryCollection.Item(1)
			ENDIF

			IF USED("ToolboxItemCursor")
				USE IN ToolboxItemCursor
			ENDIF

			THIS.RefreshUI()
		ELSE
			* To-Do: error message goes here
		ENDIF

		THIS.RedrawToolbox = .T.

		SELECT (m.nSelect)

		RETURN m.lSuccess
	ENDFUNC

	* return a collection of UniqueID's for all tools in a given category
	FUNCTION GetToolsInCategory(m.cCategoryID)
		LOCAL nSelect
		LOCAL oToolCollection
		LOCAL i
		LOCAL nCnt
		LOCAL ARRAY aToolItems[1]
		
		m.nSelect = SELECT()
		
		m.oToolCollection = CREATEOBJECT("Collection")
		SELECT UniqueID ;
		 FROM ToolboxCursor ;
		 WHERE ParentID == m.cCategoryID AND ShowType == SHOWTYPE_TOOL AND !Inactive ;
		 ORDER BY DisplayOrd ;
		 INTO ARRAY aToolItems
		m.nCnt = _TALLY
		FOR m.i = 1 TO m.nCnt
			m.oToolCollection.Add(aToolItems[m.i, 1])
		ENDFOR

		SELECT (m.nSelect)
		
		RETURN m.oToolCollection
	ENDFUNC
	
	FUNCTION GetRecord(cUniqueID)
		LOCAL oRec
		LOCAL nSelect
		
		m.nSelect = SELECT()
		
		m.oRec = .NULL.
		m.cUniqueID = PADR(m.cUniqueID, LEN(ToolboxCursor.UniqueID))

		IF SEEK(m.cUniqueID, "ToolboxCursor", "UniqueID")
			SELECT ToolboxCursor
			SCATTER MEMO NAME oRec
		ENDIF
		
		SELECT (m.nSelect)
		
		RETURN m.oRec
	ENDFUNC


	* set the current toolbox category
	FUNCTION SetCategory(cUniqueID)
		LOCAL oCurrentCategory
		LOCAL oCategoryRec

		oCategoryRec = .NULL.
		oCurrentCategory = THIS.GetCategory(m.cUniqueID)
		IF !ISNULL(oCurrentCategory)
			THIS.LastCategoryID = m.cUniqueID
			oCategoryRec = THIS.GetRecord(m.cUniqueID)
			IF !ISNULL(oCategoryRec)
				THIS.CurrentCategory = oCurrentCategory

				THIS.RunAddIns(oCategoryRec.UniqueID, "ONLOAD")
			ENDIF
		ELSE
			THIS.LastCategoryID = ''
		ENDIF

		RETURN oCategoryRec
	ENDFUNC

	* return a toolbox category by it's UniqueID
	FUNCTION GetCategory(cUniqueID)
		LOCAL oCategory

		TRY
			oCategory = THIS.oCategoryCollection.Item(RTRIM(m.cUniqueID))
		CATCH
			oCategory = .NULL.
		ENDTRY

		RETURN oCategory
	ENDFUNC


	FUNCTION GetCategoryByName(cCategory)
		LOCAL nSelect
		LOCAL oRec

		m.nSelect = SELECT()
		
		m.oRec = .NULL.

		SELECT ToolboxCursor
		LOCATE FOR UPPER(ALLTRIM(ToolName)) == UPPER(ALLTRIM(m.cCategory)) AND (ShowType == SHOWTYPE_CATEGORY OR ShowType == SHOWTYPE_FAVORITES)
		IF FOUND()
			SELECT ToolboxCursor
			SCATTER MEMO NAME oRec
		ENDIF
		
		SELECT (m.nSelect)
		
		RETURN m.oRec
	ENDFUNC

	FUNCTION GetFilterByName(cFilter)
		LOCAL nSelect
		LOCAL oRec
		
		m.nSelect = SELECT()
		
		m.oRec = .NULL.

		SELECT ToolboxCursor
		LOCATE FOR UPPER(ALLTRIM(ToolName)) == UPPER(ALLTRIM(m.cFilter)) AND ShowType == SHOWTYPE_FILTER
		IF FOUND()
			SELECT ToolboxCursor
			SCATTER MEMO NAME oRec
		ENDIF
		
		SELECT (m.nSelect)
		
		RETURN m.oRec
	ENDFUNC


	* Customize the toolbox
	* [cUniqueID] = initial category to position on
	FUNCTION Customize(cCategoryID)
		LOCAL lSuccess

		IF VARTYPE(m.cCategoryID) <> 'C'
			m.cCategoryID = THIS.CurrentCategory.UniqueID
		ENDIF

		THIS.SavePrefs()
		
		IF USED("Toolbox")
			USE IN Toolbox
		ENDIF
		IF USED("ToolboxCursor")
			USE IN ToolboxCursor
		ENDIF
		
		DO FORM ToolboxCustomize WITH m.cCategoryID TO lSuccess

		IF VARTYPE(m.lSuccess) <> 'L'
			m.lSuccess = .F.
		ENDIF
		
		IF THIS.OpenToolbox()
			IF m.lSuccess
				THIS.RestorePrefs()
				THIS.LoadToolbox()
			ENDIF
		ELSE
			RETURN TO MASTER
		ENDIF
			
		
		RETURN m.lSuccess
	ENDFUNC

	* Show the tool properties
	* [cUniqueID] = tool to show properties for
	FUNCTION ShowProperties(oToolItem, lNoAutoSave)
		LOCAL lSuccess

		m.lSuccess = .F.
		IF VARTYPE(m.oToolItem) == 'O'
			m.lSuccess = m.oToolItem.OnShowProperties()

			IF VARTYPE(m.lSuccess) <> 'L'
				m.lSuccess = .F.
			ENDIF
			
			IF m.lSuccess AND !m.lNoAutoSave
				THIS.SaveToolItem(m.oToolItem, .F.)
				THIS.LoadToolbox()
			ENDIF
		ENDIF
				
		RETURN m.lSuccess
	ENDFUNC

	FUNCTION ShowPropertiesForm(oToolItem)
		LOCAL lSuccess

		DO FORM ToolboxProperties WITH m.oToolItem TO m.lSuccess
		
		IF VARTYPE(m.lSuccess) <> 'L'
			m.lSuccess = .F.
		ENDIF
		
		RETURN m.lSuccess
	ENDFUNC

	FUNCTION ShowCategoryPropertiesForm(oToolItem)
		LOCAL lSuccess

		DO FORM ToolboxCategoryProperties WITH m.oToolItem TO m.lSuccess
		
		IF VARTYPE(m.lSuccess) <> 'L'
			m.lSuccess = .F.
		ENDIF
		
		RETURN m.lSuccess
	ENDFUNC


	* add toolbox item to favorites
	FUNCTION AddToFavorites(cToolID)
		LOCAL nSelect
	
		m.nSelect = SELECT()

		* add in favorites
		SELECT ToolboxCursor
		LOCATE FOR ShowType == SHOWTYPE_FAVORITES AND !Inactive
		IF FOUND()
			THIS.CopyTool(m.cToolID, ToolboxCursor.UniqueID)
		ENDIF


		SELECT (m.nSelect)
	ENDFUNC



	* <cToolID> = UniqueID of tool to move/copy
	* <oRec>    = target to move to -- can be category or tool
	* [lCopy]   = make a copy of the tool rather than just moving it
	FUNCTION MoveTool(cToolID, cTargetID, lCopy)
		LOCAL oToolRec
		LOCAL i
		LOCAL nCnt
		LOCAL nDisplayOrd
		LOCAL oTargetRec
		LOCAL ARRAY aDisplayOrd[1]


		m.oToolRec   = THIS.GetToolObject(m.cToolID)
		m.oTargetRec = THIS.GetToolObject(m.cTargetID)

		IF !ISNULL(m.oToolRec)
			IF INLIST(m.oTargetRec.ShowType, SHOWTYPE_CATEGORY, SHOWTYPE_FAVORITES) && we're moving to a new category
				m.oToolRec.ParentID = m.oTargetRec.UniqueID
			ELSE
				m.oToolRec.ParentID = m.oTargetRec.ParentID  && get the category of the item we dropped on
			ENDIF
			
			SELECT UniqueID ;
			 FROM ToolboxCursor ;
			 WHERE ;
			  ParentID == m.oToolRec.ParentID AND ;
			  ShowType == SHOWTYPE_TOOL ;
			 ORDER BY DisplayOrd ;
			 INTO ARRAY aDisplayOrd
			m.nCnt = _TALLY
			m.nDisplayOrd = 0
			FOR m.i = 1 TO m.nCnt
				IF SEEK(aDisplayOrd[m.i], "ToolboxCursor", "UniqueID")
					m.nDisplayOrd = m.nDisplayOrd + 1
					IF aDisplayOrd[m.i] == m.oTargetRec.UniqueID
						m.nDisplayOrd = m.nDisplayOrd + 1
					ENDIF
					REPLACE ;
					  DisplayOrd WITH m.nDisplayOrd ;
					 IN ToolboxCursor
				ENDIF
			ENDFOR
			
			
			IF m.oTargetRec.ShowType == SHOWTYPE_CATEGORY && we're moving to a new category
				m.oToolRec.DisplayOrd = m.nDisplayOrd + 1 && always add to end when moving between categories
			ELSE
				m.oToolRec.DisplayOrd = m.oTargetRec.DisplayOrd
			ENDIF

			IF m.lCopy
				m.oToolRec.LockAdd    = .F.
				m.oToolRec.LockDelete = .F.
				m.oToolRec.LockRename = .F.

				THIS.NewItem(m.oToolRec)
			ELSE
				THIS.SaveItem(m.oToolRec)
				THIS.LoadToolbox()
			ENDIF
		ENDIF
	ENDFUNC

	FUNCTION CopyTool(cToolID, cTargetID)
		RETURN THIS.MoveTool(cToolID, cTargetID, .T.)
	ENDFUNC

	* return ToolType record object given its uniqueid
	FUNCTION GetToolTypeRec(cUniqueID)
		LOCAL nSelect
		LOCAL oToolType
		
		m.nSelect = SELECT()

		m.oToolType = .NULL.
		IF THIS.OpenToolType()
			m.cUniqueID = PADR(m.cUniqueID, LEN(ToolType.UniqueID))
			SELECT ToolType
			LOCATE FOR UniqueID == m.cUniqueID
			IF FOUND()
				SCATTER MEMO NAME m.oToolType
			ENDIF
		ENDIF

		SELECT (m.nSelect)
		
		RETURN m.oToolType
	ENDFUNC
	
	* Find the tool in Toolbox.dbf and create 
	* the object specified in ClassLib/ClassName field.
	* Pass this new object back
	FUNCTION GetToolObject(cUniqueID)
		LOCAL oToolObject
		LOCAL cClassName
		LOCAL cClassLib
		LOCAL oException
		LOCAL cAlias
		LOCAL nSelect
		LOCAL lVirtual
		LOCAL ARRAY aFileList[1]

		IF VARTYPE(m.cUniqueID) <> 'C' OR EMPTY(m.cUniqueID)
			RETURN .NULL.
		ENDIF
				
		m.oToolObject = .NULL.

		m.lVirtual = (LEFT(m.cUniqueID, 8) == "virtual.")
		IF m.lVirtual AND USED("VirtualCursor")
			m.cAlias = "VirtualCursor"
		ELSE
			m.cAlias = "ToolboxCursor"
		ENDIF

		IF SEEK(m.cUniqueID, m.cAlias, "UniqueID")
			m.nSelect = SELECT()
			SELECT (m.cAlias)

			m.cClassLib  = ALLTRIM(ClassLib)
			m.cClassName = ALLTRIM(ClassName)


			IF EMPTY(ClassLib) OR !FILE(ClassLib)
				m.cClassLib = THIS.DefaultClassLib
			ENDIF

			IF EMPTY(ClassName)
				DO CASE
				CASE ShowType == SHOWTYPE_CATEGORY 
					m.cClassName = CATEGORYCLASS_GENERAL

				CASE ShowType == SHOWTYPE_FAVORITES
					m.cClassName = CATEGORYCLASS_FAVORITES

				CASE ShowType == SHOWTYPE_TOOL
					m.cClassName = ITEMCLASS_TOOL

				OTHERWISE
					m.cClassName = ITEMCLASS_ROOT
				ENDCASE
			ENDIF

			
			TRY
				m.oToolObject = NEWOBJECT(m.cClassName, m.cClassLib)
			CATCH TO oException
				MESSAGEBOX(oException.Message + "(" + oException.Procedure + ")", MB_ICONSTOP, TOOLBOX_LOC)
			ENDTRY

			* we couldn't find the specified class, so revert to the _root class
			IF ISNULL(m.oToolObject)
				TRY
					m.oToolObject = NEWOBJECT(ITEMCLASS_ROOT, THIS.DefaultClassLib)
				CATCH
				ENDTRY
			ENDIF

			IF !ISNULL(m.oToolObject)
				m.oToolObject.oEngine    = THIS
				m.oToolObject.UniqueID   = UniqueID
				m.oToolObject.ShowType   = ShowType
				m.oToolObject.ToolTypeID = ToolTypeID
				m.oToolObject.ToolType   = RTRIM(ToolType)
				m.oToolObject.ParentID   = ParentID
				m.oToolObject.ToolName   = RTRIM(ToolName)
				m.oToolObject.ClassName  = ClassName
				m.oToolObject.ClassLib   = ClassLib
				m.oToolObject.ToolData   = ToolData
				m.oToolObject.ToolTip    = ToolTip
				m.oToolObject.ImageFile  = THIS.EvalText(IIF(EMPTY(ImageFile), m.oToolObject.ImageFile, ImageFile))
				m.oToolObject.SetID      = SetID
				m.oToolObject.LockAdd    = LockAdd && TRUE indicates it can't be added to (for categories)
				m.oToolObject.LockDelete = LockDelete && TRUE indicates it can't be deleted
				m.oToolObject.LockRename = LockRename && TRUE indicates it can't be renamed
				
				m.oToolObject.User       = User
				m.oToolObject.DisplayOrd = DisplayOrd
				m.oToolObject.HelpFile   = HelpFile
				m.oToolObject.HelpID     = HelpID


				m.oToolObject.Inactive   = Inactive
				m.oToolObject.IsVirtual  = m.lVirtual
			ENDIF
			

			SELECT (m.nSelect)
		ENDIF
		
		RETURN m.oToolObject
	ENDFUNC

	* given a ToolType.UniqueID, return a Tool Object
	* based upon its definition.  This is used
	* by the virtual categories to create
	* the virual tool items.
	FUNCTION GetVirtualToolObject(cToolTypeID, cToolName, cToolTip)
		LOCAL oToolItem
		LOCAL cClassName
		LOCAL cClassLib
		LOCAL cToolType
		LOCAL oException
		LOCAL nSelect
		LOCAL lSuccess
		LOCAL oToolTypeRec

		IF VARTYPE(m.cToolTypeID) <> 'C'
			m.cToolTypeID = ''
		ENDIF
		
		m.nSelect = SELECT()
				
		m.oToolItem = .NULL.
		m.oToolType = THIS.GetToolTypeRec(m.cToolTypeID)
		IF !ISNULL(m.oToolType)
			m.cClassLib  = ALLTRIM(oToolType.ClassLib)
			m.cClassName = ALLTRIM(oToolType.ClassName)

			IF EMPTY(m.cClassLib) OR !FILE(m.cClassLib)
				m.cClassLib = THIS.DefaultClassLib
			ENDIF
			IF EMPTY(m.cClassName)
				m.cClassLib = THIS.DefaultClassLib
				m.cClassName = ITEMCLASS_TOOL
			ENDIF

			TRY
				m.oToolItem = NEWOBJECT(m.cClassName, m.cClassLib)
			CATCH TO oException
				m.oToolItem = .NULL.
				MESSAGEBOX(oException.Message + "(" + oException.Procedure + ")", MB_ICONEXCLAMATION, TOOLBOX_LOC)
			ENDTRY

			IF !ISNULL(m.oToolItem)
				m.oToolItem.oEngine    = THIS
				m.oToolItem.UniqueID   = "virtual." + SYS(2015) && unique name
				m.oToolItem.ShowType   = SHOWTYPE_TOOL
				m.oToolItem.ToolTypeID = m.cToolTypeID
				m.oToolItem.ToolType   = RTRIM(m.oToolType.ToolType)
				m.oToolItem.ParentID   = ''
				IF VARTYPE(m.cToolname) == 'C'
					m.oToolItem.ToolName = m.cToolName
				ENDIF
				m.oToolItem.ClassName  = m.cClassName
				m.oToolItem.ClassLib   = m.cClassLib
				m.oToolItem.ToolData   = ''
				m.oToolItem.ToolTip    = IIF(VARTYPE(m.cToolTip) <> 'C', m.cToolName, m.cToolTip)
				m.oToolItem.ImageFile  = THIS.EvalText(m.oToolItem.ImageFile)
				m.oToolItem.SetID      = ''
				m.oToolItem.LockAdd    = .T. && TRUE indicates it can't be added to (for categories)
				m.oToolItem.LockDelete = .T. && TRUE indicates it can't be deleted
				m.oToolItem.LockRename = .T. && TRUE indicates it can't be renamed
				
				m.oToolItem.User       = ''
				m.oToolItem.DisplayOrd = 0
				m.oToolItem.HelpFile   = ''
				m.oToolItem.HelpID     = 0

				m.oToolItem.Inactive   = .F.
				m.oToolItem.IsVirtual  = .T.
			ENDIF
		ENDIF
		
		SELECT (m.nSelect)
		
		RETURN m.oToolItem
	ENDFUNC

	* Save a copy of a virtual object to a cursor
	* that we can subsequentyly look up the
	* properties on in case the user copies it to
	* another category
	FUNCTION SaveVirtual(oToolItem)
		LOCAL nSelect
		LOCAL ARRAY aFieldList[1]
		
		
		IF VARTYPE(m.oToolItem) == 'O'
			m.nSelect = SELECT()

			* Create a cursor to hold our virtual objects
			* in case we need to look it up again
			IF !USED("VirtualCursor")
				=AFIELDS(aFieldList, "ToolboxCursor")
				CREATE CURSOR VirtualCursor FROM ARRAY aFieldList
				SELECT VirtualCursor
				INDEX ON UniqueID TAG UniqueID
			ENDIF

			INSERT INTO VirtualCursor FROM NAME m.oToolItem

			SELECT (m.nSelect)
		ENDIF
	ENDFUNC	

	* -- Standard Events
	FUNCTION OnRightClick(cUniqueID)
		LOCAL oToolObject
		LOCAL oContextMenu

		m.oToolObject  = .NULL.
		m.oContextMenu = .NULL.
		
		IF VARTYPE(m.cUniqueID) == 'C' AND !EMPTY(m.cUniqueID)
			m.oToolObject = THIS.GetToolObject(m.cUniqueID)
		ENDIF
		IF VARTYPE(m.oToolObject) == 'O'
			m.oContextMenu = m.oToolObject.OnRightClick()
		ELSE
			m.oContextMenu = NEWOBJECT("ContextMenu", "foxmenu.prg")
*!*				IF TYPE("_oToolbox") == 'O' AND !ISNULL(_oToolbox)
*!*					m.oContextMenu.ShowInScreen = (_oToolbox.Dockable == 0)
*!*				ENDIF
		ENDIF
		
		RETURN m.oContextMenu
	ENDFUNC

	FUNCTION OnClick(cUniqueID)
		LOCAL oToolObject

		m.oToolObject = THIS.GetToolObject(m.cUniqueID)
		IF !ISNULL(m.oToolObject)
			m.oToolObject.OnClick()
		ENDIF
		
		RETURN
	ENDFUNC

	
	* Create a new category
	FUNCTION AddCategory(cCategoryName, cToolTip, cToolTypeID)
		LOCAL nSelect
		LOCAL oCategory
		LOCAL nDisplayOrd
		LOCAL oFilterItem
		LOCAL oException
		LOCAL oToolType
		
		m.nSelect = SELECT()
		m.oCategory = .NULL.

		IF VARTYPE(m.cCategoryName) <> 'C' OR EMPTY(m.cCategoryName)
			DO FORM ToolboxNewCategory TO m.oCategory
		ELSE
			IF VARTYPE(m.cToolTypeID) <> 'C' OR EMPTY(m.cToolTypeID)
				m.cToolTypeID = "CATEGORY.GENERAL"
			ENDIF

			m.oToolType = THIS.GetToolTypeRec(m.cToolTypeID)

			IF !ISNULL(m.oToolType)
				m.cClassName = ALLTRIM(m.oToolType.ClassName)
				m.cClassLib  = ALLTRIM(m.oToolType.ClassLib)

				IF VARTYPE(m.cToolTip) <> 'C'
					m.cToolTip = m.oToolType.ToolTip
				ENDIF


				IF VARTYPE(m.cClassName) <> 'C'
					m.cClassName = CATEGORYCLASS_GENERAL
				ENDIF
				IF VARTYPE(m.cClassLib) <> 'C' OR EMPTY(m.cClassLib)
					m.cClassLib = THIS.DefaultClassLib
				ENDIF

				TRY
					m.oCategory = NEWOBJECT(m.cClassName, m.cClassLib)
				CATCH TO oException
					m.oCategory = .NULL.
					MESSAGEBOX(oException.Message + CHR(10) + CHR(10) + m.cClassName + "(" + m.cClassLib + ")", MB_ICONEXCLAMATION, TOOLBOX_LOC)
				ENDTRY
				
				IF VARTYPE(m.oCategory) == 'O'
					WITH m.oCategory
						.ToolName   = m.cCategoryName
						.ToolTip    = m.cToolTip
						.ClassName  = m.cClassName
						.ClassLib   = IIF(m.cClassLib == THIS.DefaultClassLib, '', m.cClassLib)
						.ToolTypeID = m.oToolType.UniqueID
						.ToolType   = RTRIM(m.oToolType.ToolType)
					ENDWITH
				ENDIF
			ENDIF
		ENDIF		
		
		IF VARTYPE(m.oCategory) == 'O'
			* find the max
			SELECT MAX(DisplayOrd) ;
			 FROM ToolboxCursor ;
			 WHERE EMPTY(ParentID) ;
			 INTO ARRAY aDisplayOrd
			IF _TALLY > 0 AND !ISNULL(aDisplayOrd[1])
				m.nDisplayOrd = aDisplayOrd[1] + 1
			ELSE
				m.nDisplayOrd = 0
			ENDIF

			
			WITH m.oCategory
				.UniqueID       = THIS.GenerateUniqueID()
				.ParentID       = ''
				.ImageFile      = ''
				.DisplayOrd     = m.nDisplayOrd
				.SetID          = ''
				.User           = ''
			ENDWITH

			IF THIS.NewItem(m.oCategory)
				IF !EMPTY(THIS.FilterID)
					* if we're currently filtered, then
					* add this category to the current filter
					m.oFilterItem = NEWOBJECT(FILTERCLASS_ITEM, THIS.DefaultClassLib)
					WITH m.oFilterItem
						.UniqueID       = THIS.GenerateUniqueID()
						.ParentID       = THIS.FilterID
						.ToolTypeID     = ''
						.ToolType       = ''
						.ToolName       = m.oCategory.UniqueID
						.ToolTip        = ''
						.ImageFile      = ''
						.User           = ''
					ENDWITH

					THIS.NewItem(m.oFilterItem)
				ENDIF
			ELSE
				m.oCategory = .NULL.
			ENDIF
		ENDIF

		SELECT (m.nSelect)	
		
		RETURN m.oCategory
	ENDFUNC

	* Add a class library, optionally creating a new category as required
	FUNCTION AddClassLib(m.cClassLib)
		LOCAL oRetValue
		LOCAL oCategory

		IF VARTYPE(m.cClassLib) == 'C' AND !EMPTY(m.cClassLib)
			IF VARTYPE(THIS.CurrentCategory) == 'O'
				m.oCategory = THIS.CurrentCategory
				THIS.CreateToolsFromFile(m.oCategory.UniqueID, m.cClassLib, .F., .T.)
			ENDIF
		ELSE
			DO FORM ToolboxAddClassLib WITH THIS TO m.oRetValue
			IF VARTYPE(m.oRetValue) == 'O'
				* create the category if necessary, or locate existing
				IF EMPTY(m.oRetValue.UniqueID)
					m.oCategory = THIS.AddCategory(m.oRetValue.CategoryName)
				ELSE
					m.oCategory = THIS.GetToolObject(m.oRetValue.UniqueID)
				ENDIF
				
				* if we have a valid category, add in the class library
				IF VARTYPE(m.oCategory) == 'O'
					THIS.CreateToolsFromFile(m.oCategory.UniqueID, m.oRetValue.Filename, .F., .T.)

					THIS.SetCategory(m.oCategory.UniqueID)
				ENDIF
			ENDIF
		ENDIF
				
		RETURN m.oCategory
	ENDFUNC


	* Create a new filter
	FUNCTION AddFilter(cFilterName, cClassName, cClassLib)
		LOCAL nSelect
		LOCAL oFilter
		
		
		m.nSelect = SELECT()

		IF VARTYPE(m.cFilterName) <> 'C' OR EMPTY(m.cFilterName)
			THIS.nNewFilterNum = THIS.nNewFilterNum + 1
			m.cFilterName = STRTRAN(NEWFILTER_LOC, '#', TRANSFORM(THIS.nNewFilterNum))
		ENDIF

		IF VARTYPE(m.cClassName) <> 'C'
			m.cClassName = FILTERCLASS_NAME
		ENDIF
		IF VARTYPE(m.cClassLib) <> 'C' OR EMPTY(m.cClassLib)
			m.cClassLib = THIS.DefaultClassLib
		ENDIF

		m.oFilter = NEWOBJECT(m.cClassName, m.cClassLib)
		
		WITH m.oFilter
			.UniqueID       = THIS.GenerateUniqueID()
			.ParentID       = ''
			.ToolTypeID     = ''
			.ToolType       = ''
			.ToolName       = m.cFilterName
			.ToolTip        = ''
			.ImageFile      = ''
			.User           = ''
		ENDWITH

		IF !THIS.NewItem(m.oFilter)
			m.oFilter = .NULL.
		ENDIF
		
		SELECT (m.nSelect)	
		
		RETURN m.oFilter
	ENDFUNC
	
	
	* Given a collection of toolbox item UniqueIDs,
	* update ToolboxCursor
	FUNCTION UpdateFilter(cFilterID, oItemCollection)
		LOCAL nSelect
		LOCAL cCategoryID
		LOCAL oFilterItem

		m.nSelect = SELECT()
		
		SELECT ToolboxCursor
		REPLACE ALL Inactive WITH .T. FOR ParentID == m.cFilterID
		
		FOR EACH cCategoryID IN oItemCollection
			m.cCategoryID = PADR(m.cCategoryID, LEN(ToolboxCursor.ToolName))

			SELECT ToolboxCursor
			LOCATE FOR ParentID == m.cFilterID AND ToolName == m.cCategoryID
			IF FOUND()
				REPLACE Inactive WITH .F. IN ToolboxCursor
			ELSE
				m.oFilterItem = NEWOBJECT(FILTERCLASS_ITEM, THIS.DefaultClassLib)
				WITH m.oFilterItem
					.UniqueID       = THIS.GenerateUniqueID()
					.ParentID       = m.cFilterID
					.ToolTypeID     = ''
					.ToolType       = ''
					.ToolName       = m.cCategoryID
					.ToolTip        = ''
					.ImageFile      = ''
					.User           = ''
				ENDWITH

				THIS.NewItem(m.oFilterItem)
			ENDIF
		ENDFOR
		
		SELECT (m.nSelect)
	ENDFUNC


	* set filter by uniqueID
	FUNCTION ApplyFilter(cFilterID)
		LOCAL oRec
		
		IF PCOUNT() == 0
			m.cFilterID = ''
		ENDIF

		IF VARTYPE(m.cFilterID) == 'C'
			IF EMPTY(m.cFilterID)
				THIS.FilterID = ''
			ELSE
				m.oRec = THIS.GetRecord(m.cFilterID)
				IF VARTYPE(m.oRec) == 'O' AND m.oRec.ShowType == SHOWTYPE_FILTER
					THIS.FilterID = m.cFilterID
				ELSE
					* filter not found, so reset to none
					THIS.FilterID = ''
				ENDIF
			ENDIF

			THIS.LoadToolbox(!EMPTY(THIS.FilterID))
		ENDIF
	ENDFUNC
	
	* set filter by the filter name
	FUNCTION SetFilter(cFilterName)
		LOCAL nSelect
		LOCAL lSuccess
		
		m.lSuccess = .F.

		IF VARTYPE(m.cFilterName) == 'C' AND !EMPTY(m.cFilterName)
			* find the filter by name
			nSelect = SELECT()

			m.cFilterName = ALLTRIM(UPPER(m.cFilterName))
			SELECT ToolboxCursor
			LOCATE FOR ShowType == SHOWTYPE_FILTER AND UPPER(ALLTRIM(ToolName)) == m.cFilterName
			IF FOUND()
				THIS.ApplyFilter(ToolboxCursor.UniqueID)
				m.lSuccess = .T.
			ENDIF

			SELECT (nSelect)
		ELSE
			THIS.ApplyFilter('')
			m.lSuccess = .T.
		ENDIF
		
		RETURN m.lSuccess
	ENDFUNC
	
	FUNCTION SetToolboxTable(cTableName)
		LOCAL lSuccess
		LOCAL cOldTableName
		
		m.cOldTableName = THIS.ToolboxTable

		
		m.lSuccess = .F.
		IF VARTYPE(m.cTableName) == 'C' AND !EMPTY(m.cTableName)
			IF EMPTY(JUSTPATH(m.cTableName))
				* use path of current toolbox if no path specified
				m.cTableName = FORCEPATH(m.cTableName, JUSTPATH(THIS.ToolboxTable))
			ENDIF
		
			m.cTableName = FULLPATH(FORCEEXT(m.cTableName, "DBF"))
			IF FILE(m.cTableName) 
				m.lSuccess = THIS.IsToolboxTable(m.cTableName)
			ELSE
				IF MESSAGEBOX(CUSTOMIZE_NOEXISTCREATE_LOC, MB_ICONQUESTION + MB_YESNO, TOOLBOX_LOC) == IDYES
					m.lSuccess = THIS.CreateToolbox(m.cTableName)
					IF m.lSuccess
						THIS.ApplyFilter('')
					ENDIF
				ENDIF
			ENDIF

			IF m.lSuccess
				THIS.ToolboxTable = m.cTableName
				IF !THIS.LoadToolbox(.T.)
					m.lSuccess = .F.
					THIS.ToolboxTable = m.cOldTableName
				ENDIF
			ENDIF
		ENDIF

		RETURN m.lSuccess
	ENDFUNC

	FUNCTION SaveToolItem(oToolItem, lCheckForDuplicate)
		LOCAL lCheckForDuplicate
		LOCAL nSelect
		LOCAL lDoUpdate
		LOCAL cToolData

		IF VARTYPE(m.oToolItem) <> 'O'
			RETURN .F.
		ENDIF
		
		nSelect = SELECT()

		* m.oToolItem.ToolData = m.cToolData

		m.lDoUpdate = .F.
		IF !EMPTY(m.oToolItem.UniqueID) AND SEEK(m.oToolItem.UniqueID, "ToolboxCursor", "UniqueID")
			m.lDoUpdate = .T.
		ELSE
			IF lCheckForDuplicate
				SELECT ToolboxCursor
				LOCATE FOR ParentID == m.oToolItem.ParentID AND SetID == m.oToolItem.SetID AND ToolData == m.oToolItem.ToolData
				m.lDoUpdate = FOUND()
			ENDIF
		ENDIF
		
		IF m.lDoUpdate
			THIS.SaveItem(m.oToolItem)
		ELSE
			THIS.NewItem(m.oToolItem)
		ENDIF

		SELECT (nSelect)
		
		RETURN .T.
	ENDFUNC

	* add an item to the Toolbox cursor
	FUNCTION CreateToolItem(cCategoryID, cToolName, cToolTip, cToolTypeID, cImageFile, cSetID, cUser)
		LOCAL oRec
		LOCAL nSelect
		LOCAL nDisplayOrd
		LOCAL cHomeDir
		LOCAL lDoUpdate
		LOCAL oToolItem
		LOCAL oDataValue
		LOCAL cToolData
		LOCAL cClassLib
		LOCAL cClassName
		LOCAL oToolType
		LOCAL ARRAY aDisplayOrd[1]

		IF VARTYPE(cCategoryID) <> 'C'
			RETURN .F.
		ENDIF

		IF VARTYPE(cToolTip) <> 'C'
			cToolTip = ''
		ENDIF
		IF VARTYPE(cImageFile) <> 'C'
			cImageFile = ''
		ENDIF
		IF VARTYPE(cToolTypeID) <> 'C'
			cToolTypeID = ''
		ENDIF
		IF VARTYPE(cSetID) <> 'C'
			cSetID = ''
		ENDIF
		IF VARTYPE(cUser) <> 'C'
			cUser = ''
		ENDIF


		m.nSelect = SELECT()

		m.oToolItem = .NULL.

		* make sure the category exists
		m.oRec = THIS.GetRecord(RTRIM(m.cCategoryID))
		IF !ISNULL(m.oRec)
			* Find the type in ToolType table and get the class library and name from that
			m.oToolType = THIS.GetToolTypeRec(m.cToolTypeID)
			IF !ISNULL(m.oToolType)
				m.cClassLib = m.oToolType.ClassLib
				m.cClassName = m.oToolType.ClassName

				IF EMPTY(m.cClassName)
					m.cClassName = ITEMCLASS_ROOT
					m.cClassLib  = THIS.DefaultClassLib
				ENDIF
				IF EMPTY(m.cClassLib)
					m.cClassLib = THIS.DefaultClassLib
				ENDIF

				* create an instance of the class
				TRY
					m.oToolItem = NEWOBJECT(m.cClassName, m.cClassLib)
				CATCH TO oException
					m.oToolItem = .NULL.
					MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, TOOLBOX_LOC)
				ENDTRY

				IF VARTYPE(m.oToolItem) == 'O'
					m.cCategoryID = PADR(m.cCategoryID, LEN(ToolboxCursor.ParentID))

					* find the max
					SELECT MAX(DisplayOrd) ;
					 FROM ToolboxCursor ;
					 WHERE ParentID == m.cCategoryID ;
					 INTO ARRAY aDisplayOrd
					IF _TALLY > 0 AND !ISNULL(aDisplayOrd[1])
						m.nDisplayOrd = aDisplayOrd[1] + 1
					ELSE
						m.nDisplayOrd = 0
					ENDIF

					WITH m.oToolItem
						.UniqueID       = THIS.GenerateUniqueID()
						.ParentID       = m.cCategoryID
						.ToolTypeID     = m.oToolType.UniqueID
						.ToolType       = RTRIM(m.oToolType.ToolType)
						.ToolName       = m.cToolName
						.ToolTip        = m.cToolTip
						.ImageFile      = IIF(EMPTY(m.cImageFile), .ImageFile, THIS.RelativeToHome(m.cImageFile))
						.ClassName      = m.cClassName
						.ClassLib       = IIF(m.cClassLib == THIS.DefaultClassLib, '', m.cClassLib)
						.DisplayOrd     = m.nDisplayOrd
						.SetID          = RTRIM(m.cSetID)
						.User           = m.cUser
					ENDWITH
				ENDIF
			ENDIF
		ENDIF

		SELECT (m.nSelect)

		RETURN m.oToolItem
	ENDFUNC

	* create a toolbox item of scrap text
	FUNCTION CreateToolItemScrap(cCategoryID, cText)
		LOCAL i
		LOCAL nCnt
		LOCAL cCaption
		LOCAL oToolItem
		LOCAL cImageFile
		LOCAL aText[1]

		m.cUniqueID = ''
		IF VARTYPE(cText) == 'C' AND !EMPTY(m.cText)
			m.cCaption = m.cText
			m.nCnt = ALINES(aText, m.cText)
			FOR m.i = 1 TO m.nCnt
				IF !EMPTY(aText[i])
					m.cCaption = aText[i]
					EXIT
				ENDIF
			ENDFOR
			m.cImageFile = ''
			m.oToolItem = THIS.CreateToolItem(m.cCategoryID, TOOL_TEXTPREFIX_LOC + m.cCaption, m.cText, "TEXTSCRAP", m.cImageFile, '', '')
			IF VARTYPE(m.oToolItem) == 'O'
				oToolItem.SetDataValue("textscrap", m.cText)
				THIS.SaveToolItem(m.oToolItem)
			ENDIF
	
		ENDIF
	ENDFUNC

	* generate a toolname for a class based upon the selected naming convention
	FUNCTION GenerateToolName(cClassLib, cClassName)
		DO CASe
		CASE THIS.NamingConvention == 2  && ClassName
			RETURN m.cClassName
			
		CASE THIS.NamingConvention == 3  && Library.ClassName
			RETURN IIF(EMPTY(m.cClassLib), '', m.cClassLib + '.') + m.cClassName

		OTHERWISE  && ClassName (Library)
			RETURN m.cClassName + IIF(EMPTY(m.cClassLib), '', " (" + m.cClassLib + ")")

		ENDCASE
		
	ENDFUNC

	PROCEDURE CreateToolsFromVCX(cCategoryID, cFilename, lShowProgress)
		LOCAL lDeferLoad
		LOCAL oException
		LOCAL cToolTip
		LOCAL cImageFile
		LOCAL oToolItem
		LOCAL cHomeDir
		LOCAL i
		LOCAL nCnt
		LOCAL cSetID
		LOCAL lDupe
		LOCAL lFound
		LOCAL cClassName
		LOCAL cClassLib
		LOCAL lUpdated
		LOCAL oProgressForm
		LOCAL lAutoYield
		LOCAL ARRAY aVCXInfo[1]

		* defer re-loading the toolbox until we're
		* done adding all of the new toolbox items
		m.lDeferLoad = THIS.lDeferLoad
		THIS.lDeferLoad = .T.

		m.lUpdated = .F.


		* If cFilename is in a subfolder of the HOME() directory,
		* then save it as an expression.  For example:
		*	(HOME() + "ffc\_agent.vcx")
		m.cClassLib = THIS.RelativeToHome(m.cFilename)
		m.cSetID = LOWER(m.cClassLib)

		IF FILE(m.cFilename)
			TRY
				m.nCnt = AVCXCLASSES(aVCXInfo, m.cFilename)

				IF m.lShowProgress
					oProgressForm = NEWOBJECT("CProgressForm", "FoxToolbox.vcx")
					oProgressForm.lShowCancel = .F.
					oProgressForm.lShowThermometer = .T.
					oProgressForm.SetDescription(m.cFilename)
					oProgressForm.SetMax(m.nCnt)

					oProgressForm.Show()
				ENDIF

				FOR m.i = 1 TO m.nCnt
					IF m.lShowProgress
						oProgressForm.SetProgress(m.i, aVCXInfo[m.i, 1])
						DOEVENTS
					ENDIF

					m.lDupe = .F.
					SELECT ToolboxCursor
					SCAN ALL FOR ParentID == m.cCategoryID AND SetID == m.cSetID
						m.oToolItem = THIS.GetToolObject(ToolboxCursor.UniqueID)
						IF VARTYPE(m.oToolItem) == 'O'
							* it's a duplicate, so ignore
							m.cClassName = LOWER(THIS.EvalText(NVL(oToolItem.GetDataValue("classname"), '')))
							IF m.cClassName == LOWER(aVCXInfo[m.i, 1])
								m.lDupe = .T.
								EXIT
							ENDIF
						ENDIF
					ENDSCAN

					IF !m.lDupe
						m.cImageFile = THIS.GetImageForClass(aVCXInfo[m.i, 2], aVCXInfo[m.i, 5])

						m.cToolTip = aVCXInfo[m.i, 8]  && class description
						m.oToolItem = THIS.CreateToolItem(m.cCategoryID, THIS.GenerateToolName(JUSTSTEM(m.cFilename), aVCXInfo[m.i, 1]), m.cToolTip, "CLASS", m.cImageFile, m.cSetID, '')

						IF VARTYPE(m.oToolItem) == 'O'
							oToolItem.SetDataValue("classlib", m.cClassLib)
							oToolItem.SetDataValue("classname", aVCXInfo[m.i, 1])
							oToolItem.SetDataValue("objectname", aVCXInfo[m.i, 1])
							oToolItem.SetDataValue("parentclass", aVCXInfo[m.i, 3])
							oToolItem.SetDataValue("baseclass", aVCXInfo[m.i, 2])

							m.lUpdated = THIS.SaveToolItem(m.oToolItem, .T.)
						ENDIF
					ENDIF
				ENDFOR

				* now remove any that don't still exist in the class library
				SELECT ToolboxCursor
				SCAN ALL FOR ParentID == m.cCategoryID AND SetID == m.cSetID
					m.oToolItem = THIS.GetToolObject(ToolboxCursor.UniqueID)
					IF VARTYPE(m.oToolItem) == 'O'
						m.cClassName = LOWER(THIS.EvalText(NVL(oToolItem.GetDataValue("classname"), '')))
						m.lFound = .F.
						FOR m.i = 1 TO m.nCnt
							IF LOWER(aVCXInfo[m.i, 1]) == m.cClassName
								m.lFound = .T.
								EXIT
							ENDIF
						ENDFOR
						IF !m.lFound
							DELETE IN ToolboxCursor
							m.lUpdated = .T.
						ENDIF
					ENDIF
				ENDSCAN

				IF m.lShowProgress
					oProgressForm.SetProgress(m.nCnt)
					DOEVENTS

					oProgressForm.Release()
					oProgressForm = .NULL.
				ENDIF
				
				
			CATCH TO oException
				MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, TOOLBOX_LOC)
			ENDTRY

			THIS.lDeferLoad = m.lDeferLoad
			THIS.LoadToolbox()
		ENDIF
		
		
		RETURN m.lUpdated
	ENDFUNC


	* Grab all classes from a PRG file and create toolbox items
	* for them.  However, don't add duplicates, and remove
	* any classes that were previously in the toolbox but
	* no longer exist.
	FUNCTION CreateToolsFromPRG(cCategoryID, cFilename)
		LOCAL lDeferLoad
		LOCAL oException
		LOCAL cToolTip
		LOCAL cImageFile
		LOCAL nCnt
		LOCAL i
		LOCAL oToolItem
		LOCAL cHomeDir
		LOCAL lDupe
		LOCAL nBaseIndex
		LOCAL lUpdated
		LOCAL ARRAY aClassInfo[1]
		LOCAL ARRAY aFileStr[1]
		LOCAL ARRAY aBaseInfo[1]

		m.lUpdated = .F.

		* defer re-loading the toolbox until we're
		* done adding all of the new toolbox items
		m.lDeferLoad = THIS.lDeferLoad
		THIS.lDeferLoad = .T.
	
		* If cFilename is in a subfolder of the HOME() directory,
		* then save it as an expression.  For example:
		*	(HOME() + "ffc\_agent.vcx")
		* If cFilename is in a subfolder of the HOME() directory,
		* then save it as an expression.  For example:
		*	(HOME() + "ffc\_agent.vcx")
		m.cClassLib = THIS.RelativeToHome(m.cFilename)
		m.cSetID = LOWER(m.cClassLib)


		* create array of base classes
		ALANGUAGE(aBaseInfo, 3)

		TRY
			m.nCnt = APROCINFO(aClassInfo, m.cFilename, 1)
			FOR m.i = 1 TO m.nCnt
				m.lDupe = .F.
				SELECT ToolboxCursor
				SCAN ALL FOR ParentID == m.cCategoryID AND SetID == m.cSetID
					m.oToolItem = THIS.GetToolObject(ToolboxCursor.UniqueID)
					IF VARTYPE(m.oToolItem) == 'O'
						* it's a duplicate, so ignore
						IF LOWER(oToolItem.GetDataValue("classname")) == LOWER(aClassInfo[m.i, 1])
							m.lDupe = .T.
							EXIT
						ENDIF
					ENDIF
				ENDSCAN

				IF !m.lDupe
					IF ALINES(aFileStr, FILETOSTR(m.cFilename), .T.) > 0
						m.cToolTip = aFileStr[aClassInfo[m.i, 2]]
					ELSE
						m.cToolTip = ''
					ENDIF
					m.cImageFile = THIS.GetImageForClass(aClassInfo[m.i, 3])
					oToolItem = THIS.CreateToolItem(m.cCategoryID, THIS.GenerateToolName(JUSTSTEM(m.cFilename), aClassInfo[m.i, 1]), m.cToolTip, "CLASS", m.cImageFile, LOWER(m.cFilename), '')
					IF VARTYPE(m.oToolItem) == 'O'
						oToolItem.SetDataValue("objectname", aClassInfo[m.i, 1])
						m.lUpdated = .T.
					ENDIF
				ENDIF

				IF VARTYPE(m.oToolItem) == 'O'
					oToolItem.SetDataValue("classlib", m.cClassLib)
					oToolItem.SetDataValue("classname", aClassInfo[m.i, 1])
					oToolItem.SetDataValue("parentclass", aClassInfo[m.i, 3])

					* see if we can determine the base class
					m.nBaseIndex = ASCAN(aBaseInfo, aClassInfo[m.i, 3], -1, -1, 0, 1)
					IF m.nBaseIndex > 0
						oToolItem.SetDataValue("baseclass", aBaseInfo[m.nBaseIndex])
					ENDIF


					THIS.SaveToolItem(m.oToolItem, .T.)
					m.lUpdated = .T.
				ENDIF
			ENDFOR

			* now remove any that don't still exist in the class library
			SELECT ToolboxCursor
			SCAN ALL FOR ParentID == m.cCategoryID AND SetID == m.cSetID
				oToolItem = THIS.GetToolObject(ToolboxCursor.UniqueID)
				IF VARTYPE(m.oToolItem) == 'O'
					cClassName = LOWER(oToolItem.GetDataValue("classname"))
					m.lFound = .F.
					FOR m.i = 1 TO m.nCnt
						IF LOWER(aClassInfo[m.i, 1]) == m.cClassName
							m.lFound = .T.
							EXIT
						ENDIF
					ENDFOR
					IF !m.lFound
						DELETE IN ToolboxCursor
						m.lUpdated = .T.
					ENDIF
				ENDIF
			ENDSCAN

		CATCH TO oException
			MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, TOOLBOX_LOC)
		ENDTRY

		THIS.lDeferLoad = m.lDeferLoad
		THIS.LoadToolbox()
		
		RETURN m.lUpdated
	ENDFUNC

	* given a file extension, return the ToolType.UniqueID
	* for that file tooltype
	FUNCTION FindToolTypeByExtension(cExtension)
		LOCAL cToolTypeID
		LOCAL oToolType
		LOCAL nSelect
		
		m.nSelect = SELECT()

		m.oToolType = .NULL.
		m.cExtension = UPPER(m.cExtension)
		IF THIS.OpenToolType()
			SELECT ToolType 
			LOCATE FOR (',' + m.cExtension + ',') $ (',' + FileType + ',') AND !Inactive
			IF FOUND()
				SCATTER MEMO NAME oToolType
			ELSE
				* we didn't find a type for this extension, so
				* use the generic "FILE" type
				LOCATE FOR UniqueID == PADR("FILE", LEN(ToolType.UniqueID)) AND !Inactive
				IF FOUND()
					SCATTER MEMO NAME oToolType
				ENDIF
			ENDIF
		ENDIF
		
		SELECT (m.nSelect)

		RETURN m.oToolType
	ENDFUNC


	* create toolbox items from a file
	* Support types: VCX, PRG, DBC
	* [lFileOnly] = TRUE to not handle VCX and PRG as class libraries
	* [lShowProgress] = .T. to show progress thermometer
	FUNCTION CreateToolsFromFile(cCategoryID, cFilename, lFileOnly, lShowProgress)
		LOCAL cExt
		LOCAL oToolItem
		LOCAL oToolType
		LOCAL lUpdated
		
		m.lUpdated = .F.

		* defer re-loading the toolbox until we're
		* done adding all of the new toolbox items
		THIS.lDeferLoad = .T.

		m.cExt = UPPER(JUSTEXT(m.cFilename))


		m.oToolItem = .NULL.
		DO CASE
		CASE m.cExt == "VCX" AND !m.lFileOnly
			m.lUpdated = THIS.CreateToolsFromVCX(m.cCategoryID, m.cFilename, m.lShowProgress)

		CASE m.cExt == "PRG" AND !m.lFileOnly
			m.lUpdated = THIS.CreateToolsFromPRG(m.cCategoryID, m.cFilename)

		OTHERWISE
			m.oToolType = THIS.FindToolTypeByExtension(m.cExt)
			IF !ISNULL(m.oToolType)
				m.oToolItem = THIS.CreateToolItem(m.cCategoryID, JUSTFNAME(m.cFilename), m.cFilename, m.oToolType.UniqueID, '', '', '')
			ENDIF
		ENDCASE

		IF VARTYPE(oToolItem) == 'O'
			m.cFilename = THIS.RelativeToHome(m.cFilename)

			m.oToolItem.SetDataValue("filename", m.cFilename)
			THIS.SaveToolItem(m.oToolItem)
			m.lUpdated = .T.
		ENDIF
		
		THIS.lDeferLoad = .F.
		THIS.LoadToolbox()
		
		RETURN m.lUpdated
	ENDFUNC


	* given a base class, return the appropriate image name
	FUNCTION GetImageForClass(cBaseClass, cToolbarImage)
		LOCAL cImageFile

		IF VARTYPE(m.cToolbarImage) == 'C' AND !EMPTY(m.cToolbarImage)
			RETURN THIS.RelativeToHome(FULLPATH(m.cToolbarImage))
		ELSE
			m.cImageFile = LOWER(m.cBaseClass) + ".bmp"
			IF FILE(m.cImageFile)
				RETURN m.cImageFile
			ELSE
				RETURN ''
			ENDIF
		ENDIF
	ENDFUNC

	* refresh all files in the toolbox
	FUNCTION RefreshToolbox(cCategoryID)
		LOCAL nSelect
		LOCAL cWhere
		LOCAL i
		LOCAL nCnt
		LOCAL oToolItem
		LOCAL cFilename
		LOCAL cClassType
		LOCAL oProgressForm
		LOCAL lAutoYield
		LOCAL cFileLib
		LOCAL lUpdated
		LOCAL ARRAY aSetList[1]
		

		m.nSelect = SELECT()
		
		m.lUpdated = .F.

		IF USED("VirtualCursor")
			USE IN VirtualCursor
		ENDIF
		
		m.lAutoYield = _VFP.AutoYield
		_VFP.AutoYield = .T.

		oProgressForm = NEWOBJECT("CProgressForm", "FoxToolbox.vcx")
		oProgressForm.lShowCancel = .F.
		oProgressForm.lShowThermometer = .F.
		
		IF VARTYPE(m.cCategoryID) <> 'C'
			m.cCategoryID = ''
		ENDIF

		m.cClassType = PADR("CLASS", LEN(ToolboxCursor.ClassType))
		m.cWhere = "!EMPTY(ToolboxCursor.SetID) AND ToolboxCursor.ClassType == [" + m.cClassType +  "] AND !Inactive"
		IF !EMPTY(m.cCategoryID)
			m.cWhere = m.cWhere + IIF(EMPTY(m.cWhere), '', " AND ") + "ToolboxCursor.ParentID == [" + m.cCategoryID + "]"
		ENDIF

		SELECT DISTINCT LEFT(SetID, 254) AS ShortSetID ;
		 FROM ToolboxCursor ;
		 WHERE &cWhere ;
		 INTO ARRAY aSetList
		m.nCnt = _TALLY

		IF EMPTY(m.cCategoryID)
			oProgressForm.SetDescription(REFRESHING_TOOLBOX_LOC)
			oProgressForm.SetMax(m.nCnt)
		ELSE
			oProgressForm.SetDescription(REFRESHING_CATEGORY_LOC)
		ENDIF
		oProgressForm.Show()


		FOR m.i = 1 TO m.nCnt
			m.cFileLib = THIS.EvalText(RTRIM(aSetList[m.i]))
			IF !EMPTY(JUSTPATH(m.cFileLib))
				m.cFileLib = DISPLAYPATH(m.cFileLib, 50)
			ENDIF

			oProgressForm.SetProgress(m.i - 1, m.cFileLib)

			SELECT ToolboxCursor
			LOCATE FOR SetID == RTRIM(aSetList[m.i])
			IF FOUND()
				m.oToolItem = THIS.GetToolObject(ToolboxCursor.UniqueID)
				IF VARTYPE(m.oToolItem) == 'O'
					m.cFilename = NVL(m.oToolItem.GetDataValue("classlib"), '')
					IF !EMPTY(m.cFilename)
						IF THIS.CreateToolsFromFile(ToolboxCursor.ParentID, m.cFilename)
							m.lUpdated = .T.
						ENDIF
					ENDIF
				ENDIF
			ENDIF
		ENDFOR
		oProgressForm.SetProgress(m.nCnt)

		oProgressForm.Release()
		oProgressForm = .NULL.

		_VFP.AutoYield = m.lAutoYield

		SELECT (m.nSelect)
		
		RETURN m.lUpdated
	ENDFUNC

	* refresh the current category
	FUNCTION RefreshCategory()
		IF VARTYPE(THIS.CurrentCategory) == 'O'
			THIS.RefreshToolbox(THIS.CurrentCategory.UniqueID)
		ENDIF
	ENDFUNC

	* delete a toolbox category, item, or filter
	FUNCTION DeleteItem(cUniqueID, lPrompt)
		LOCAL oCategory
		LOCAL oRec
		LOCAL cMsg
		LOCAL nIndex

		m.oRec = THIS.GetRecord(m.cUniqueID)
		IF VARTYPE(m.oRec) <> 'O'
			RETURN .F.
		ENDIF
		
		IF m.lPrompt
			DO CASE
			CASE m.oRec.ShowType == SHOWTYPE_CATEGORY OR m.oRec.ShowType == SHOWTYPE_FAVORITES
				m.cMsg = TOOL_DELETECATEGORY_LOC
			CASE m.oRec.ShowType == SHOWTYPE_FILTER
				m.cMsg = TOOL_DELETEFILTER_LOC
			OTHERWISE
				m.cMsg = TOOL_DELETE_LOC
			ENDCASE
			
			IF ISNULL(m.oRec) OR MESSAGEBOX(m.cMsg + CHR(10) + CHR(10) + RTRIM(m.oRec.ToolName), MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2, TOOLBOX_LOC) == IDNO
				RETURN .F.
			ENDIF
		ENDIF

	
		IF SEEK(m.cUniqueID, "ToolboxCursor", "UniqueID")
			* if this is a category, then we'll need to delete all of those as well
			DELETE FROM ToolboxCursor WHERE UniqueID == m.cUniqueID OR ParentID == m.cUniqueID
		ENDIF

		* find the toolbox in our categories
		DO CASE
		CASE m.oRec.ShowType == SHOWTYPE_CATEGORY
			* remove the category and all of it's tools
			DELETE FROM ToolboxCursor WHERE ParentID == m.cUniqueID AND ShowType == SHOWTYPE_TOOL
			
			* remove category from existing filters
			m.cUniqueID = PADR(m.cUniqueID, LEN(ToolboxCursor.ToolName))
			DELETE FROM ToolboxCursor WHERE ToolName == m.cUniqueID AND ShowType == SHOWTYPE_FILTERITEM


			IF !ISNULL(THIS.CurrentCategory) AND RTRIM(m.cUniqueID) == THIS.CurrentCategory.UniqueID
				THIS.CurrentCategory = .NULL.
			ENDIF
			
			
			* from from current collection of categories
			m.nIndex = THIS.oCategoryCollection.GetKey(RTRIM(m.cUniqueID))
			TRY
				THIS.oCategoryCollection.Remove(RTRIM(m.cUniqueID))
			CATCH
			ENDTRY
			
			m.nIndex = MIN(m.nIndex, THIS.oCategoryCollection.Count)
			IF BETWEEN(m.nIndex, 1, THIS.oCategoryCollection.Count)
				THIS.SetCategory(THIS.oCategoryCollection.Item(m.nIndex).UniqueID)
			ENDIF

		CASE m.oRec.ShowType == SHOWTYPE_FILTER
			* remove filter and its subitems
			DELETE FROM ToolboxCursor WHERE ParentID == m.cUniqueID AND ShowType == SHOWTYPE_FILTERITEM
			
		CASE m.oRec.ShowType == SHOWTYPE_TOOL
			* nothing extra to do for a tool item
		ENDCASE

		THIS.RefreshUI()

		RETURN .T.
	ENDFUNC

	FUNCTION RenameItem(cUniqueID, cNewName)
		LOCAL lSuccess
		LOCAL oToolItem
		LOCAL cToolName

		m.lSuccess = .F.

		m.oToolItem = THIS.GetToolObject(m.cUniqueID)
		IF VARTYPE(m.oToolItem) == 'O'
			m.cToolName = RTRIM(m.oToolItem.ToolName)

			IF VARTYPE(m.cNewName) <> 'C' OR EMPTY(m.cNewName)
				DO FORM ToolboxRename WITH m.cToolName TO m.cNewName
				* m.cNewName = INPUTBOX(TOOLITEM_RENAMEPROMPT_LOC, TOOL_RENAME_LOC, m.cToolName)
			ENDIF
			IF !(m.cNewName == m.cToolName) AND !EMPTY(m.cNewName)
				m.oToolItem.ToolName = m.cNewName
				IF THIS.SaveItem(m.oToolItem)
					m.lSuccess = .T.

					THIS.RefreshUI()
				ENDIF
			ENDIF
		ENDIF
		
		RETURN m.lSuccess
	ENDFUNC

	* create a new record from the toolitem object
	* in ToolboxCursor
	FUNCTION NewItem(oToolItem)
		LOCAL lSuccess
		LOCAL nSelect
		LOCAL ARRAY aDisplayOrd[1]

		IF VARTYPE(m.oToolItem) <> 'O'
			RETURN .F.
		ENDIF
		
		m.nSelect = SELECT()

		m.lSuccess = .F.

		m.oToolItem.UniqueID = THIS.GenerateUniqueID()
		DO CASE
		CASE m.oToolItem.ShowType == SHOWTYPE_CATEGORY
			* add new category
			* oToolItem.ShowType = SHOWTYPE_CATEGORY

			SELECT MAX(DisplayOrd) ;
			 FROM ToolboxCursor ;
			 WHERE ShowType == SHOWTYPE_CATEGORY ;
			 INTO ARRAY aDisplayOrd
			IF _TALLY > 0 AND !ISNULL(aDisplayOrd[1])
				oToolItem.DisplayOrd = aDisplayOrd[1] + 1
			ELSE
				oToolItem.DisplayOrd = 1
			ENDIF

		CASE m.oToolItem.ShowType == SHOWTYPE_TOOL
			* add new tool
			IF m.oToolItem.DisplayOrd == 0
				SELECT MAX(DisplayOrd) ;
				 FROM ToolboxCursor ;
				 WHERE ;
				  ParentID == oToolItem.ParentID AND ;
				  ShowType == SHOWTYPE_TOOL ;
				 INTO ARRAY aDisplayOrd
				IF _TALLY > 0 AND !ISNULL(aDisplayOrd[1])
					oToolItem.DisplayOrd = aDisplayOrd[1] + 1
				ELSE
					oToolItem.DisplayOrd = 1
				ENDIF
			ENDIF
		ENDCASE


		SELECT ToolboxCursor
		INSERT INTO ToolboxCursor FROM NAME m.oToolItem

		m.oToolItem.ParseToolData()
		REPLACE ;
		  ToolData WITH m.oToolItem.EncodeToolData(), ;
		  Inactive WITH .F., ;
		  Modified WITH DATETIME() ;
		 IN ToolboxCursor

		IF !THIS.lCustomizeMode
			THIS.LoadToolbox()
		ENDIF

		m.lSuccess = .T.

		SELECT (m.nSelect)

		RETURN m.lSuccess
	ENDFUNC


	FUNCTION SaveItem(oToolItem)
		LOCAL lSuccess
		LOCAL nSelect
		
		IF VARTYPE(m.oToolItem) <> 'O'
			RETURN .F.
		ENDIF

		m.nSelect = SELECT()

		m.lSuccess = .F.
		IF SEEK(m.oToolItem.UniqueID, "ToolboxCursor", "UniqueID")
			m.oToolItem.ParseToolData()

			SELECT ToolboxCursor
			GATHER MEMO NAME m.oToolItem
			REPLACE ;
			  ToolData WITH m.oToolItem.EncodeToolData(), ;
			  Modified WITH DATETIME() ;
			 IN ToolboxCursor

			m.lSuccess = .T.
		ENDIF
		
		SELECT (m.nSelect)

		RETURN m.lSuccess
	ENDFUNC


	* Evaluate passed string.
	* If it is surrounded by parens, then
	* evaluate it, otherwise return the original text.
	FUNCTION EvalText(cText)
		IF LEFT(m.cText, 1) == '(' AND RIGHT(m.cText, 1) == ')'
			TRY
				m.cText = EVALUATE(m.cText)
			CATCH
			ENDTRY
		ENDIF

		RETURN m.cText
	ENDFUNC

	* Save customization
	* This must have been opened in customized mode to work
	* (pass .T. to Init)
	FUNCTION SaveCustomization()
		LOCAL nSelect
		LOCAL cDeleted
		LOCAL oRec
		
		m.nSelect = SELECT()

		IF THIS.lCustomizeMode
			IF THIS.OpenToolbox(.F., "Toolbox")
				
				cDeleted = SET("DELETED")
				SET DELETED OFF
				
				SELECT ToolboxCursor
				SCAN ALL
					IF SEEK(ToolboxCursor.UniqueID, "Toolbox", "UniqueID")
						IF DELETED("ToolboxCursor")
							DELETE IN Toolbox
						ELSE
							SELECT ToolboxCursor
							SCATTER MEMO NAME oRec

							SELECT Toolbox
							GATHER MEMO NAME oRec
						ENDIF
					ELSE
						IF !DELETED("ToolboxCursor")
							SELECT ToolboxCursor
							SCATTER MEMO NAME oRec
							* oRec.Inactive = !oRec.Checked

							SELECT Toolbox
							INSERT INTO Toolbox FROM NAME m.oRec
						ENDIF
					ENDIF
				ENDSCAN
				
				
				SET DELETED &cDeleted
				
				IF USED("Toolbox")
					USE IN Toolbox
				ENDIF
			ENDIF
		ENDIF
		THIS.SavePrefs()
		
		SELECT (m.nSelect)
	ENDFUNC

	* Customization Mode Only
	* allows us to remove tool given its UniqueID
	FUNCTION RemoveTool(cUniqueID)
		LOCAL nSelect

		m.nSelect = SELECT()

		IF SEEK(m.cUniqueID, "ToolboxCursor", "UniqueID")
			DELETE IN ToolboxCursor
		ENDIF
		
		SELECT (m.nSelect)
	ENDFUNC
	
	
	* Customization Mode Only
	* allows us to remove all tools for a given SetID & Category 
	* (for example, all classes in the same VCX share a SetID value)
	FUNCTION RemoveSet(cSetID, cCategoryID)
		LOCAL nSelect
		LOCAL cWhere
		LOCAL nCnt
		LOCAL i
		LOCAL ARRAY aToolList[1]
		
		m.nSelect = SELECT()

		m.cWhere = ''
		IF VARTYPE(cCategoryID) == 'C' AND !EMPTY(cCategoryID)
			m.cWhere = m.cWhere + IIF(EMPTY(m.cWhere), '', " AND ") + "ToolboxCursor.ParentID == [" + m.cCategoryID + "]"
		ENDIF
		IF VARTYPE(cSetID) == 'C' AND !EMPTY(cSetID)
			m.cWhere = m.cWhere + IIF(EMPTY(m.cWhere), '', " AND ") + "ToolboxCursor.SetID == [" + m.cSetID + "]"
		ENDIF
		
		IF THIS.lCustomizeMode AND !EMPTY(m.cWhere)
			SELECT UniqueID ;
			  FROM ToolboxCursor ;
			  WHERE &cWhere ;
			  INTO ARRAY aToolList
			m.nCnt = _TALLY
			FOR m.i = 1 TO m.nCnt
				THIS.RemoveTool(aToolList[m.i])
			ENDFOR
		ENDIF
		
		SELECT (m.nSelect)
	ENDFUNC


	* return a collection of the defined filters
	FUNCTION GetFilters()
		LOCAL oFilterCollection
		LOCAL oFilter
		LOCAL nSelect
		
		m.nSelect = SELECT()
		oFilterCollection = CREATEOBJECT("Collection")
		
		SELECT ToolboxCursor
		SCAN ALL FOR ShowType == SHOWTYPE_FILTER AND !Inactive
			oFilter = CREATEOBJECT("ToolboxFilter")
			oFilter.UniqueID   = ToolboxCursor.UniqueID
			oFilter.FilterName = RTRIM(ToolboxCursor.ToolName)
			oFilterCollection.Add(oFilter)
		ENDSCAN
		
		SELECT (m.nSelect)
		
		RETURN oFilterCollection
	ENDFUNC	

	* return a collection of the add-ins for specified ToolTypeID
	* <cToolTypeID> = Tool type to return addins for
	* [cShowType]   = add-in type to retrieve, default to SHOWTYPE_ADDIN
	FUNCTION GetAddIns(cToolTypeID, cParentID, cClassType)
		LOCAL oAddInCollection
		LOCAL oAddIn
		LOCAL nSelect
		
		m.nSelect = SELECT()
		m.oAddInCollection = CREATEOBJECT("Collection")

		IF VARTYPE(m.cToolTypeID) <> 'C'
			m.cToolTypeID = ''
		ENDIF

		IF VARTYPE(m.cParentID) <> 'C'
			m.cParentID = ''
		ENDIF

		IF VARTYPE(m.cClassType) <> 'C'
			m.cClassType = ''
		ENDIF


		m.cToolTypeID = PADR(m.cToolTypeID, LEN(ToolboxCursor.ToolTypeID))
		m.cParentID   = PADR(m.cParentID, LEN(ToolboxCursor.ParentID))
		m.cClassType  = PADR(m.cClassType, LEN(ToolboxCursor.ClassType))
		
		SELECT ToolboxCursor
		SCAN ALL FOR ;
		 (ShowType == SHOWTYPE_ADDIN OR ShowType == SHOWTYPE_ADDINMENU) AND ;
		 ToolTypeID == m.cToolTypeID AND ;
		 ParentID == m.cParentID AND ;
		 ClassType == m.cClassType AND ;
		 !Inactive
			oAddIn = CREATEOBJECT("ToolboxAddIn")
			oAddIn.UniqueID   = ToolboxCursor.UniqueID
			oAddIn.AddInName  = RTRIM(ToolboxCursor.ToolName)
			IF ToolboxCursor.ShowType == SHOWTYPE_ADDINMENU
				oAddIn.IsMenu   = .T.
				oAddIn.MenuCode = ToolboxCursor.ToolData
			ELSE
				oAddIn.IsMenu = EMPTY(ToolboxCursor.ToolData) AND EMPTY(ToolboxCursor.ClassName)
			ENDIF
			oAddInCollection.Add(oAddIn)
		ENDSCAN
		
		SELECT (m.nSelect)
		
		RETURN m.oAddInCollection
	ENDFUNC	


	* run all Add-ins with matching ParentID and Classtype
	* Mainly for the Classtype = "ONLOAD" to run an addin when
	* the toolbox is loaded or a category is opened
	FUNCTION RunAddIns(cParentID, cClassType)
		LOCAL nSelect
		LOCAL lSuccess

		m.nSelect = SELECT()

		IF VARTYPE(m.cParentID) <> 'C'
			m.cParentID = ''
		ENDIF
		IF VARTYPE(m.cClassType) <> 'C' OR EMPTY(m.cClassType)
			m.cClassType = "ONLOAD"
		ENDIF

		m.cParentID = PADR(m.cParentID, LEN(ToolboxCursor.ParentID))
		m.cClassType  = PADR(m.cClassType, LEN(ToolboxCursor.ClassType))

		m.lSuccess = .F.
		SELECT ToolboxCursor
		SCAN ALL FOR ShowType == SHOWTYPE_ADDIN AND ParentID == m.cParentID AND ClassType == m.cClassType AND !Inactive
			IF THIS.InvokeAddIn(ToolboxCursor.UniqueID, THIS)
				m.lSuccess = .T.
			ENDIF
		ENDSCAN


		SELECT (m.nSelect)
		
		RETURN m.lSuccess
	ENDFUNC


	FUNCTION InvokeAddIn(cUniqueID, oToolItem, p1, p2, p3, p4)
		LOCAL oAddInRec
		LOCAL oException
		LOCAL oAddIn
		LOCAL lSuccess

		IF VARTYPE(m.oToolItem) <> 'O'
			m.oToolItem = .NULL.
		ENDIF
		
		m.lSuccess = .F.
		oAddInRec = THIS.GetRecord(m.cUniqueID)
		IF VARTYPE(oAddInRec) == 'O'
			IF EMPTY(m.oAddInRec.ClassName)
				* no classname specified, so assume ToolData contains script to run
				IF !EMPTY(m.oAddInRec.ToolData)
					TRY
						DO CASE
						CASE PCOUNT() == 6
							EXECSCRIPT(m.oAddInRec.ToolData, m.oToolItem, m.p1, m.p2, m.p3, m.p4)
						CASE PCOUNT() == 5
							EXECSCRIPT(m.oAddInRec.ToolData, m.oToolItem, m.p1, m.p2, m.p3)
						CASE PCOUNT() == 4
							EXECSCRIPT(m.oAddInRec.ToolData, m.oToolItem, m.p1, m.p2)
						CASE PCOUNT() == 3
							EXECSCRIPT(m.oAddInRec.ToolData, m.oToolItem, m.p1)
						OTHERWISE
							EXECSCRIPT(m.oAddInRec.ToolData, m.oToolItem)
						ENDCASE
						m.lSuccess = .T.
					CATCH TO oException
						MESSAGEBOX(m.oException.Message, MB_ICONEXCLAMATION, TOOLBOX_LOC)
					ENDTRY
				ENDIF
			ELSE
				* a class is specified, so create an instance of it and
				* invoke the Execute() method with a reference to
				* the tool item. 
				TRY
					oAddIn = NEWOBJECT(m.oAddInRec.ClassName, m.oAddInRec.ClassLib)
					oAddIn.Execute(m.oToolItem)
					m.lSuccess = .T.

				CATCH TO oException
					MESSAGEBOX(m.oException.Message, MB_ICONEXCLAMATION, TOOLBOX_LOC)
				ENDTRY
			ENDIF
		ENDIF
		
		RETURN m.lSuccess
	ENDFUNC


	* If cFilename is in a subfolder of the HOME() directory,
	* then return it as an expression.  For example:
	*	(HOME() + "ffc\_agent.vcx")
	FUNCTION RelativeToHome(m.cFilename)
		LOCAL cHomeDir

		IF !EMPTY(m.cFilename)
			m.cHomeDir = UPPER(HOME())
			IF m.cHomeDir == LEFT(UPPER(ADDBS(JUSTPATH(m.cFilename))), LEN(m.cHomeDir))
				m.cFilename = [(HOME() + "] + SUBSTR(m.cFilename, LEN(m.cHomeDir) + 1) + [")]
			ENDIF
		ENDIF
		
		RETURN m.cFilename
	ENDFUNC


	* -- Cleanup tables used by Toolbox (pack)
	* -- First creates a backup (ToolboxBackup) in HOME(7)
	* [@cBackupTable] = pass by reference to return the name of the backup file created
	FUNCTION Cleanup(cBackupTable)
		LOCAL nSelect
		LOCAL lSuccess
		LOCAL cBackupTable
		LOCAL oException
		LOCAL cSafety
		LOCAL nFileCnt
		
		
		m.nSelect = SELECT()
		
		m.lSuccess = .T.
		IF USED("Toolbox")
			USE IN Toolbox
		ENDIF
		IF USED("ToolboxCursor")
			USE IN ToolboxCursor
		ENDIF
		
		IF VARTYPE(m.cBackupTable) <> 'C' OR EMPTY(m.cBackupTable)
			m.nFileCnt = 0
			m.cBackupTable = ADDBS(JUSTPATH(THIS.ToolboxTable)) + JUSTSTEM(THIS.ToolboxTable) + "Backup.dbf"
			DO WHILE FILE(m.cBackupTable)
				m.nFileCnt = m.nFileCnt + 1
				m.cBackupTable = ADDBS(JUSTPATH(THIS.ToolboxTable)) + JUSTSTEM(THIS.ToolboxTable) + "Backup_" + TRANSFORM(m.nFileCnt) + ".dbf"
			ENDDO
		ENDIF

		m.cSafety = SET("SAFETY")
		SET SAFETY OFF
		TRY
			USE (THIS.ToolboxTable) ALIAS Toolbox IN 0 EXCLUSIVE
			SELECT Toolbox
			
			IF THIS.IsToolboxTable("Toolbox")
				COPY TO (m.cBackupTable) WITH PRODUCTION
				SELECT Toolbox
				ZAP IN Toolbox
				APPEND FROM (m.cBackupTable)
			ENDIF

		CATCH TO oException
			m.lSuccess = .F.
			MESSAGEBOX(ERROR_CLEANUP_LOC + CHR(10) + CHR(10) + m.oException.Message, MB_ICONEXCLAMATION, TOOLBOX_LOC)
		ENDTRY

		SET SAFETY &cSafety

		IF USED("Toolbox")
			USE IN Toolbox
		ENDIF

		THIS.OpenToolbox()

		SELECT (m.nSelect)
		
		RETURN m.lSuccess
	ENDFUNC

	* restore the original toolbox table
	* <lSaveCustom> = true to save additions by you or third-party to the toolbox
	* <@cBackupTable> = name of the backup file that is created (pass by reference)
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
		IF USED("Toolbox")
			USE IN Toolbox
		ENDIF
		IF USED("ToolboxCursor")
			USE IN ToolboxCursor
		ENDIF
		
		IF VARTYPE(m.cBackupTable) <> 'C' OR EMPTY(m.cBackupTable)
			m.nFileCnt = 0
			m.cBackupTable = ADDBS(JUSTPATH(THIS.ToolboxTable)) + JUSTSTEM(THIS.ToolboxTable) + "Backup.dbf"
			DO WHILE FILE(m.cBackupTable)
				m.nFileCnt = m.nFileCnt + 1
				m.cBackupTable = ADDBS(JUSTPATH(THIS.ToolboxTable)) + JUSTSTEM(THIS.ToolboxTable) + "Backup_" + TRANSFORM(m.nFileCnt) + ".dbf"
			ENDDO

		ENDIF

		m.cSafety = SET("SAFETY")
		SET SAFETY OFF
		
		m.lNoBackup = .F.
		TRY
			USE (THIS.ToolboxTable) ALIAS Toolbox IN 0 SHARED AGAIN
			SELECT Toolbox
			COPY TO (m.cBackupTable) WITH PRODUCTION

		CATCH
			m.cBackupTable = ''
			m.lNoBackup = .T.
		ENDTRY
		IF USED("Toolbox")
			USE IN Toolbox
		ENDIF
		
		IF !m.lNoBackup OR MESSAGEBOX(ERROR_NOBACKUP_LOC, MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2, TOOLBOX_LOC) == IDYES
			TRY
				USE ToolboxDefault IN 0 SHARED AGAIN
				SELECT ToolboxDefault
				COPY TO (THIS.ToolboxTable) WITH PRODUCTION

				* keep vendor and user toolbox customizations
				IF m.lSaveCustom
					USE (THIS.ToolboxTable) IN 0 SHARED AGAIN ALIAS NewToolbox
					USE (m.cBackupTable) IN 0 SHARED AGAIN ALIAS OldToolbox
					SELECT OldToolbox
					SCAN ALL FOR EMPTY(ParentID) && do the categories first
						IF !SEEK(OldToolbox.UniqueID, "NewToolbox", "UniqueID")
							SELECT OldToolbox
							SCATTER MEMO NAME m.oRec
							INSERT INTO NewToolbox FROM NAME m.oRec
						ENDIF
					ENDSCAN

					SELECT OldToolbox
					SCAN ALL FOR !EMPTY(ParentID)
						IF !SEEK(OldToolbox.UniqueID, "NewToolbox", "UniqueID") AND SEEK(OldToolbox.ParentID, "Newtoolbox", "UniqueID")
							SELECT OldToolbox
							SCATTER MEMO NAME m.oRec
							INSERT INTO NewToolbox FROM NAME m.oRec
						ENDIF
					ENDSCAN
				ENDIF				
			CATCH TO oException
				m.lSuccess = .F.
				MESSAGEBOX(ERROR_RESTORETODEFAULT_LOC + CHR(10) + CHR(10) + m.oException.Message, MB_ICONEXCLAMATION, TOOLBOX_LOC)
			FINALLY
				IF USED("ToolboxDefault")
					USE IN ToolboxDefault
				ENDIF
				IF USED("OldToolbox")
					USE IN OldToolbox
				ENDIF
				IF USED("NewToolbox")
					USE IN NewToolbox
				ENDIF
			ENDTRY
		ELSE
			m.lSuccess = .F.
		ENDIF

		SET SAFETY &cSafety

		THIS.LoadToolbox(.T.)

		SELECT (m.nSelect)
		
		RETURN m.lSuccess
	ENDFUNC

	* see note below on BuilderDelay class
	FUNCTION Builder()
		THIS.tmrBuilder.Enabled = .T.
	ENDFUNC	

ENDDEFINE

* This class is used to delay running of the builder
* when class is drag/dropped.  The problem is that
* some ActiveX controls and such don't cooperate very
* well when called from OleCompleteDrag() event ...
* so we have to setup a timer to call the builder
DEFINE CLASS BuilderDelay AS Timer
	Enabled = .F.
	Interval = 200
	
	PROCEDURE Timer()
		THIS.Enabled = .F.
		THIS.Reset()
		
		LOCAL nDataSession
		LOCAL ARRAY aCtrlObj[1]

		=ASELOBJ(aCtrlObj)
		IF TYPE("aCtrlObj[1]") == 'O'
			m.nDataSession = SET("DATASESSION")
			SET DATASESSION TO 1
			DO (_Builder) WITH aCtrlObj[1], "TOOLBOX"
			SET DATASESSION TO (m.nDataSession)
		ENDIF
	ENDPROC
ENDDEFINE

DEFINE CLASS ToolboxCategory AS Custom
	Name       = "ToolboxCategory"
	UniqueID   = ''
	TopToolID  = ''
	ToolTypeID = ''
	ToolType   = ''
	ToolName   = ''
	ParentID   = ''
	ClassType  = ''
	SetID      = ''
	ClassName  = ''
	ClassLib   = ''
	ToolTip    = ''
	HelpFile   = ''
	HelpID     = 0
	User       = ''

	oToolCollection = .NULL.
	
	PROCEDURE Init()
		THIS.oToolCollection = CREATEOBJECT("Collection")
	ENDPROC

	* -- Add content record to the pane
	FUNCTION AddTool(cUniqueID)
		THIS.oToolCollection.Add(RTRIM(m.cUniqueID))

		RETURN .T.
	ENDFUNC
ENDDEFINE

DEFINE CLASS ToolboxFilter AS Custom
	Name = "ToolboxFilter"

	UniqueID   = ''
	FilterName = ''
ENDDEFINE

DEFINE CLASS ToolboxAddIn AS Custom
	Name = "AddInFilter"

	UniqueID    = ''
	AddInName   = ''
	IsMenu      = .F. && true if this is simply a parent menu for add-ins (no associated code)
	MenuCode    = ''
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

	FUNCTION GetPropertyValue(cPropName)
		LOCAL oPropObject
		LOCAL cRetValue

		m.oPropObject = THIS.GetProperty(m.cPropName)
		IF VARTYPE(m.oPropObject) == 'O'
			m.cRetValue = m.oPropObject.Value
		ELSE
			m.cRetValue = .NULL.
		ENDIF
		
		RETURN m.cRetValue
	ENDFUNC
	
	PROCEDURE AddPropertyValue(cName, cValue)
		LOCAL oPropObject
		
		m.oPropObject = CREATEOBJECT("Empty")
		ADDPROPERTY(m.oPropObject, "Name", m.cName)
		ADDPROPERTY(m.oPropObject, "Value", m.cValue)
	
		THIS.Add(m.oPropObject)
	ENDPROC
	
ENDDEFINE
*--     Program: TaskList.prg
*-- Description: Class definitions for VFP TaskList
*--      Author: Daryl Moore
*--        Date: 7/20/99
*--   Copyright: (c) 1999, Microsoft Corporation

#include "tasklist.h"

Define Class Task As Line
	
	Hidden BaseClass, BorderColor, BorderStyle, BorderWidth, Class, ClassLibrary
	Hidden ColorSource, Comment, DragIcon, DragMode, DrawMode, Enabled, Height 
	Hidden HelpContextID, Left, LineSlant, MouseIcon, MousePointer, Name, oleDragMode
	Hidden oleDragPicture, oleDropEffects, oleDropHasData, oleDropMode, Parent
	Hidden ParentClass, Tag, Top, Visible, WhatsThisHelpID, Width

	taskList = .Null.			&& the task list object that owns this task
	errorState = ERROR_UNKNOWN	&& Special state of the object prior to an error
	xml = .F.		 			&& Property used to get an XML version of this task
	
	*-- Standard fields will be added at runtime
	*-- with a prefix of _

	*-- UDF fields will be added at runtime with
	*-- a prefix of _

*!*	Function error
*!*	LParameters tnError, tcMethod, tnLine

*!*		Private All Except g*

*!*		Do Case
*!*		Case this.errorState = ERROR_IGNORE
*!*			*-- Error risk was known, but not fatal. Ignore it.
*!*		Otherwise
*!*			MessageBox(	ERROR_OCCURRED_LOC + Chr(13) + Chr(13) + ;
*!*						ERROR_ERROR_LOC + "  " + Alltrim(Str(tnError)) + Chr(13) + ;
*!*						ERROR_METHOD_LOC + "  " + tcMethod + Chr(13) + ;
*!*						ERROR_LINE_LOC + "  " + Alltrim(Str(tnLine)) )
*!*			Cancel
*!*		EndCase
*!*	EndFunc

*-- Destroy all pointers
Function destroy
	
	Private All Except g*

	this.taskList = .F.	

EndFunc

*-- Receives the tasklist object
Function init
LParameters toTaskList

	Private All Except g*

	*-- Add user defined fields
	If Type("toTaskList") = "O" And Lower(toTaskList.Class) = "tasklist"
	
		this.TaskList = toTaskList

		*-- Load the fields into the task
		IF !this.LoadFields()
			=MESSAGEBOX(ERROR_NOINIT_LOC, MB_ICONSTOP + MB_OK)
			RETURN .F.
		ENDIF

	EndIf		
EndFunc

*-- Loads the fields from the table(s) into the task object
Function loadFields

	Private All Except g*

	Local lnCols, i, lcProperty
	Dimension laCols[1,2]

	*-- Returns all standard fields
	lnCols = this.TaskList.GetStandardFields(@laCols)
	IF lnCols = 0
		*- error -- cdn't use the task table
		RETURN .F.
	ENDIF
	For i = 1 To lnCols
		*-- PEM_DEFINED returns whether the property has been defined
		*-- or not
		lcProperty = "_" + laCols[i,1]
		If !PemStatus(this, lcProperty, PEM_DEFINED)
			this.AddProperty(lcProperty)
			this.&lcProperty = laCols[i,2]
		EndIf
	EndFor

	*-- Return all user defined fields
	lnCols = this.TaskList.GetUDFFields(@laCols)
	For i = 1 To lnCols
		*-- PEM_DEFINED returns whether the property has been defined
		*-- or not.
		lcProperty = "_" + laCols[i,1]
		If !PemStatus(this, lcProperty, PEM_DEFINED)
			this.AddProperty(lcProperty)
			this.&lcProperty = laCols[i,2]
		EndIf
	EndFor

	RETURN .T.
EndFunc

*-- Retrieves the data type of the passed property
*-- Since properties are variant, and table fields are
*-- strongly typed, we have to make sure the types are
*-- appropriate when updating, etc.
Function getPropertyType
LParameters tcProperty

	Local lcType
	lcType = "U"

	*-- Open the main table and look for the field
	If this.taskList.openDBF(OPEN_MAIN)
		lcType = Type("tskMain." - SUBSTR(tcProperty,2))
		*-- If it's not there, check the udf table
		If lcType = "U"
			If this.taskList.openDBF(OPEN_CHILD)
				lcType = Type("tskChild." - SUBSTR(tcProperty,2))	&& remove "_"
			Endif
		Endif
	EndIf

	Return lcType

EndFunc

*-- Retrieves the len of the data type of the passed property
*-- Only works for C values (use for setting mask property for editing)
Function getPropertyLen
LParameters tcProperty

	Local lcType
	lcType = "U"

	*-- Open the main table and look for the field
	If this.taskList.openDBF(OPEN_MAIN)
		lcType = Type("tskMain." - SUBSTR(tcProperty,2))
		IF lcType = 'C'
			RETURN FSIZE(SUBSTR(tcProperty,2),"tskMain")
		ENDIF
		*-- If it's not there, check the udf table
		If lcType = "U"
			If this.taskList.openDBF(OPEN_CHILD)
				lcType = Type("tskChild." - SUBSTR(tcProperty,2))	&& remove "_"
				IF lcType = 'C'
					RETURN FSIZE(SUBSTR(tcProperty,2), "tskChild")
				ENDIF
			Endif
		Endif
	EndIf

	Return 0

EndFunc

*-- Returns the value of the passed property
*-- If the property does not exist, .Null. is returned
Function getProperty
LParameters tcProperty

	Private All Except g*

	*-- VS Whidbey 10184
	*-- Custom props don't have underscore, so add it
	IF SUBSTR(tcProperty, 1, 1) <> "_"
		tcProperty = "_" + tcProperty
	ENDIF
	
	*-- Need to account for the underscore
	If PemStatus(this, tcProperty, PEM_DEFINED)

	*--If PemStatus(this, "_" + tcProperty, PEM_DEFINED)
		*-- tcProperty = "_" + tcProperty
		tcProperty = tcProperty
		Return this.&tcProperty.
	Endif
	
	Return .Null.

EndFunc

*-- Sets a property or returns .F. if the property
*-- does not exist
Function setProperty
LParameters tcProperty, tuValue

	Private All Except g*

	If PemStatus(this, tcProperty, PEM_DEFINED)
		this.&tcProperty. = tuValue
		Return .T.
	Endif
	
	Return .F.

EndFunc

Function xml_access

	Private All Except g*

	Local lcXML, lnPropCount, i, lcProperty
	Local laProps[1]

	lcXML = ""
	
	lcXML = lcXML + " <task>" + CR_LF

	*-- Get a list of all the properties of this
	lnPropCount = AMembers(laProps, this)
	For i = 1 To lnPropCount
		lcProperty = Alltrim(Lower(laProps[i]))
		If Left(lcProperty, 1) == "_"
			lcProperty = SubStr(lcProperty, 2)
			lcXML = lcXML + "  <" + lcProperty + ">"
			lcXML = lcXML + Transform(this._&lcProperty.)
			lcXML = lcXML + "</" + lcProperty + ">" + CR_LF
		EndIf
	EndFor

	lcXML = lcXML + " </task>" + CR_LF
	
	Release lnPropCount, i, lcProperty, laProps

	Return lcXML

EndFunc

Function xml_assign
LParameters tcXML


EndFunc

EndDefine


*-- TaskList class
*-- This is the management class for the tasklist
*-- Its purpose is to take care of data-dependent routines, like
*-- updating, adding, querying, etc.

Define Class TaskList As Session

	Hidden baseClass, classLibrary, comment, dataSession
	Hidden dataSessionID, name, parent, parentClass, tag

	dimension tasks[1]			&& will contain an array of task objects
	taskCount = 0				&& will contain the length of the above list
	taskUI = .Null.				&& will contain a pointer to the user interface
	orderBy = "duedate"			&& contains the order by field
	orderAscDesc = 1			&& 1 - Ascending, -1 - Descending
	orderByField = "duedate"	&& contains the unmodified field name for orderby clause
	showTasks = "SCOU"			&& S-Shortcuts, [C-Compiler], O-Other, U-User-defined
	lastUpdateCRC = -1			&& Contains CRC value of last update
	lastChildUpdateCRC = -1		&& Contains CRC value of last child update
	errorState = ERROR_UNKNOWN	&& Contains the state of the object prior to an error

	*-- Putting data in HOME() won't work if user is not in Admin/Power Users
	*-- group.  Use HOME(7) instead.
	dataSource = Home(7) + "foxtask.dbf"
	childDataSource = ""
	
	xml = .F.					&& access method will return all tasks in XML
	deleting = .F.              && Are we currently deleting a record in this.removetask?

Function lastUpdateCRC_access

	this.lastUpdateCRC = Val(SYS(2007, FileToStr(this.dataSource)))

	Return this.lastUpdateCRC 
	
EndFunc
 
Function lastChildUpdateCRC_access

	If File(this.childDataSource) 
		this.lastChildUpdateCRC = Val(SYS(2007, FileToStr(this.childDataSource)))
	Endif

	Return this.lastChildUpdateCRC
	
EndFunc

*-- If the datasource changes, we need to requery the data
Function dataSource_assign
LParameters tcNewVal

	Private All Except g*

	*-- If the data source changes, we need to requery the data
	If File(tcNewVal)
		this.dataSource = tcNewVal
		this.requeryData()
	Endif
	
EndFunc

*-- If the child Data Source (UDF) changes we need to requery
Function childDataSource_assign
LParameters tcNewVal

	Private All Except g*
	Local lcOldDataSource

	If Empty(tcNewVal)
		this.childDataSource = ""
		this.requeryData()
		Return
	Endif

	*-- if the child data source changes, we need to requery
  	If Type("tcNewVal") = "C"
    	If File(tcNewVal)
    		lcOldDataSource = this.childDataSource
    		this.childDataSource = tcNewVal
    		If this.openDBF(OPEN_CHILD)
	    		this.requeryData()
	    	Else
				=MessageBox(BAD_CHILD_DATA_LOC, MB_ICONSTOP, APP_TITLE)
	    		this.childDataSource = lcOldDataSource
	    	Endif
    	EndIf
  	Endif
EndFunc

*-- When created, we load saved information and load the tasks
*-- Public variable _otasklist is created, too
Function init

	Private All Except g*

	Public _oTaskList
	_oTaskList = this

	this.loadState()

	IF EMPTY(_FOXTASK) OR !FILE(_FOXTASK)

		*-- Setup apparently quit putting foxtask.dbf in HOME(),
		*-- so create one if necessary.
		
		*-- Putting data in HOME() won't work if user is not in Admin/Power Users
		*-- group.  Use HOME(7) instead.
		IF !FILE(Home(7) + "foxtask.dbf")
			CREATE TABLE HOME(7) + "foxtask" (uniqueid c(10), ;
    	                  timestamp n(10.0), ;
        	              filename m, ;
            	          class m, ;
                	      method m, ;
                    	  line n(6.0), ;
	                      contents m, ;
    	                  type c(1), ;
        	              duedate d, ;
            	          priority n(1.0), ;
                	      status n(1.0))
			APPEND BLANK
			REPLACE uniqueid WITH '_VersionID', contents WITH '1', type WITH 'V'
		ENDIF
		Use
		THIS.dataSource = Home(7) + "foxtask.dbf"
	ELSE
		THIS.dataSource = _FOXTASK	
	ENDIF

#IF 0
	this.lastUpdateCRC = Val(Sys(2007, FileToStr(this.dataSource)))
	If File(this.childDataSource)
		this.lastChildUpdateCRC = Val(Sys(2007, FileToStr(this.childDataSource)))
	Endif
#ENDIF

	IF This.DataSession = 2 && Private data session

		*-- Go dig in the registry to grab the 
		*-- SET DATE setting.  New
		*-- data sessions default to system settings.
		lsDateSetting = This.GetRegSZKey(HKEY_CURRENT_USER, ;
                                         "Software\Microsoft\VisualFoxPro\7.0\Options\", ;
                                         "DATE")
		IF LEN(ALLTRIM(lsDateSetting)) > 0
			SET Date &lsDateSetting
		Endif
	Endif

	*-- Load the tasks
	RETURN this.requeryData()

EndFunc

*-- Prepare the task list to shut down
Function shutDown

	*-- Save the state of the engine
	this.saveState()

	*-- Remove memory variables
	this.taskUI = .Null.

	Dimension this.tasks[1]
	this.tasks[1] = .F.
	
	*-- Kill this object
	_oTaskList = .NULL.
	Release this
	
EndFunc

*-- Load the engine state from FoxUser
Function loadState

	If this.getPref( PREF_ORDERBY, "g_save_orderAscDesc, g_save_orderBy, g_save_showTasks, g_save_childDataSource, g_save_orderByField" )
		this.orderBy = g_save_orderBy
		this.orderAscDesc = g_save_orderAscDesc
		this.orderByField = g_save_orderByField
		this.showTasks = g_save_showTasks
  		this.childDataSource = g_save_childDataSource
		Release g_save_orderAscDesc, g_save_orderBy, g_save_showTasks, g_save_childDataSource, g_save_orderByField
	Endif

EndFunc

*-- Save the engine state to foxuser
Function saveState

	Public g_save_orderBy, g_save_orderAscDesc, g_save_showTasks, g_save_childDataSource, g_save_orderByField
	g_save_orderBy = this.orderBy
	g_save_orderAscDesc = this.orderAscDesc
	g_save_orderByField= this.orderByField
	g_save_showTasks = this.showTasks
    g_save_childDataSource = this.childDataSource
	
	this.savePref( PREF_ORDERBY )
	
	Release g_save_orderBy, g_save_orderAscDesc, g_save_showTasks, g_save_childDataSource, g_save_orderByField

EndFunc

*-- Event called when a run-time error occurs
*!*	Function error
*!*	LParameters tnError, tcMethod, tnLine

*!*		Private All Except g*

*!*		Do Case
*!*		Case this.errorState = ERROR_IGNORE
*!*		Case this.errorState = ERROR_DEBUG
*!*			Set Step On
*!*		Case this.errorState = ERROR_QUERY
*!*			If tnError = 1832
*!*				MessageBox( ERROR_DUPFIELD_LOC, MB_ICONSTOP)
*!*			Else
*!*				MessageBox( ERROR_QUERY_LOC, MB_ICONSTOP )
*!*			Endif
*!*			
*!*			*-- The most likely cause for the Error is the child data source being bad
*!*			*-- To make sure it isn't stuck forever, clear the child data source property
*!*			this.childDataSource = ""
*!*			this.saveState()
*!*			Release this
*!*			Release _oTaskList
*!*			Cancel
*!*		Otherwise
*!*			MessageBox(	ERROR_OCCURRED_LOC + Chr(13) + Chr(13) + ;
*!*						ERROR_ERROR_LOC + "  " + Alltrim(Str(tnError)) + Chr(13) + ;
*!*						ERROR_METHOD_LOC + "  " + tcMethod + Chr(13) + ;
*!*						ERROR_LINE_LOC + "  " + Alltrim(Str(tnLine)) )
*!*			
*!*			Release this
*!*			Release _oTaskList

*!*			Cancel
*!*		EndCase

*!*	EndFunc

*--
*-- Shows the UI for the task list
Function showUI
	
	Private All Except g*

	*-- If the UI doesn't already exist, we will create it
	If Type("this.taskUI.class") <> "C"
		this.taskUI = NewObject("TaskListUI", "tasklistui.vcx", "", this)
	EndIf
	
	*-- Show it
	this.taskUI.Show()

EndFunc

*-- Hides the UI without killing it
Function hideUI

	Private All Except g*

	*-- If it exists, hide it. If it doesn't exist, 
	*-- there's no need to hide it!
	If Type("this.taskUI.class") = "C"
		this.taskUI.Hide()
	EndiF
	
EndFunc

*--
*-- Requeries the tasks array against the data source	
Function requeryData

	Private All Except g*

	Local lcSql, loTask, llRetVal
	
	llRetVal = .T.

	*-- Call build query to get the fields and tables
	lcSql = this.buildQuery()

	this.errorState = ERROR_QUERY
	*-- If text came back, we have at least the main table
	If !Empty(lcSql)
		lcSql = lcSql + 'Where !Deleted() And Type $ "' + this.showTasks + '" Into Cursor csrTasks '

		*-- Execute the sql statement		
		&lcSql

		this.taskCount = _Tally
		
		*-- If we returned at least 1 record and the table was opened
		If _Tally > 0 And Used("csrTasks")
			Dimension this.tasks[_tally]
			Select csrTasks
			Scan
				*-- Grab a data object from the table
				Scatter Memo Name loTask
				
				*-- Convert the data object to a task object and store it in the tasks collection
				this.tasks[RecNo()] = this.dataObjToTask(loTask)
				
			ENDSCAN
		ELSE
			*- llRetVal = .F.
		ENDIF
	ELSE
		llRetVal = .F.
	Endif

  	this.closeDBF(CLOSE_ALL)

	IF llRetVal
		this.lastUpdateCRC = Val(Sys(2007, FileToStr(this.dataSource)))
		If File(this.childDataSource)
			this.lastChildUpdateCRC = Val(Sys(2007, FileToStr(this.childDataSource)))
		Endif
	ENDIF
		
	RETURN llRetVal
	
EndFunc

*-- buildQuery creates a SQL statement
*-- based on the available tables
Function buildQuery

	Private All Except g*

	Local lcSql, llHaveOrderBy
	lcSql = ""

	*-- Open the main table
	If this.openDBF(OPEN_MAIN)

		*-- Add the field we will be ordering by
		*-- This is necessary since we can't specify
		*-- an orderby if it isn't in the query, or if
		*-- the field is memo.
		lcSql = "Select *"
		If !Empty(this.orderBy)
			DO CASE
				CASE TYPE(this.orderby) == 'M'
					*- if memo field, construct a usable orderby field
					lcSql = lcSql + ", PADR(UPPER(" + this.orderBy + "),100) As orderField "
					llHaveOrderBy = .T.
				CASE TYPE(this.orderby) == 'U'
					*- if memo field, construct a usable orderby field
					llHaveOrderBy = .F.
				OTHERWISE
					lcField = this.orderby
					IF VARTYPE(&lcField) = "C"
						lcSql = lcSql + ", UPPER(" + this.orderBy + ") As orderField "
					ELSE
						lcSql = lcSql + ", " + this.orderBy + " As orderField "
					Endif
					llHaveOrderBy = .T.
			ENDCASE
		EndIf
		
		*-- If we can open the child table, join the tables together
		If this.openDBF(OPEN_CHILD)
			IF !Empty(this.orderBy) AND !llHaveOrderBy
				*- order by field must be in child table
				DO CASE
					CASE TYPE(this.orderby) == 'M'
						*- if memo field, construct a usable orderby field
						lcSql = lcSql + ", PADR(UPPER(" + this.orderBy + "),100) As orderField "
						llHaveOrderBy = .T.
					CASE TYPE(this.orderby) == 'U'
						*- if memo field, construct a usable orderby field
						lcSql = lcSql + ", [] As orderField "
						llHaveOrderBy = .F.
					OTHERWISE
						lcSql = lcSql + ", UPPER(" + this.orderBy + ") As orderField "
						llHaveOrderBy = .T.
				ENDCASE
			ENDIF				
			lcSql = lcSql + "From tskMain "
			lcSql = lcSql + "Left Outer Join tskChild On tskMain.uniqueid = tskChild.uniqueid "
		ELSE
			lcSql = lcSql + "From tskMain "
		EndIf

		*-- If there's an orderby field, add the orderby clause
		If !Empty(this.orderBy) AND llHaveOrderBy
			lcSql = lcSql + "Order By orderField " + IIF(this.orderAscDesc = 1,"ASC","DESC") + " "
		EndIf

	EndIf

	Return lcSql

EndFunc

*-- Sets the orderby clause
Function setOrderBy
LParameters tcField, tcType

	*-- If tcField is empty, clear out the orderby
	If Empty(tcField)
		this.orderBy = ""
		this.orderByField = ""
	Else
		this.orderByField = tcField
		Do Case
		*-- Since UDF fields can be used to order,
		*-- we have to chop memo fields to 100 chars
		Case tcType = "C" or tcType = "M"
			this.orderBy = "Upper(LeftC(" + tcField + ", 100)) "
		*-- Can't order by general fields
		Case tcType = "G"
			this.orderBy = ""
		*-- Any other field is fine as-is
		Otherwise
			this.orderBy = "Upper(" + tcField + ")"
		EndCase
	Endif

EndFunc

*-- Adds a task to the task list
Function addTask
LParameters toTaskObj

	Private All Except g*

	Local lcID, lnFields, i, lcField
	lcID = ""
	
	*-- Open the main table
	If this.openDBF(OPEN_MAIN)
		Dimension laFields[1]

		*-- set the uniqueid
		lcID = Sys(2015)
		toTaskObj._UniqueID = lcID
		toTaskObj._TimeStamp = this.getTimeStamp()
	
		*-- Get a list of fields from the task table
		lnFields = AFields(laFields)
		Append Blank
		
		*-- Before adding, let's make sure the Priority is 
		*-- valid.  This often zero, so let's at least 
		*-- set it to a valid value before saving.
		IF totaskobj._Priority < 1 Or totaskobj._Priority > 3
			totaskobj._Priority = 1
		ENDIF
		
		*-- Blank dates show up in Open Task as 1899, due to 
		*-- how ActiveX control handles blank dates.  Give
		*-- a default of today's date.
*!*			IF ISBLANK(totaskobj._duedate)
*!*				totaskobj._duedate = DATE()
*!*			Endif
		
		*-- since the fields can change any time, we have to 
		*-- dynamically figure out where to put our data
		For i = 1 To lnFields
			lcField = laFields[i,1]

			*-- If a property exists prefaced with an underscore and matching field
			*-- name, and it's the same type, stuff it into the table
			If PemStatus(toTaskObj, "_" + lcField, PEM_DEFINED)
				If this.typesAreCompatible(Type("tskMain." + lcField), Type("toTaskObj._" + lcField))
					Replace tskMain.&lcField. With toTaskObj._&lcField.
				ELSE
					Replace tskMain.&lcField. With this.forceType(toTaskObj._&lcfield., Type("tskMain." + lcField))
				Endif
			EndIf
		EndFor

		*-- Open/select the child table if it exists
		If this.openDBF(OPEN_CHILD)
			Dimension laFields[1]

			lnFields = AFields(laFields)
			Append Blank
			
			*-- since the fields can change any time, we have to 
			*-- dynamically figure out where to put our data
			For i = 1 To lnFields
				lcField = laFields[i,1]

				*-- If a property exists prefaced with an underscore and matching field
				*-- name, and it's the same type, stuff it into the table
				If PemStatus(toTaskObj, "_" + lcField, PEM_DEFINED)
					If this.typesAreCompatible(Type("tskChild." + lcField), Type("toTaskObj._" + lcField))
						Replace tskChild.&lcField. With toTaskObj._&lcField.
					Else
						Replace tskChild.&lcField. With this.forceType(toTaskObj._&lcfield., Type("tskChild." + lcField))
					Endif
				EndIf
			EndFor
		Endif
	Endif
	
	this.requeryData()

	this.closeDBF(CLOSE_ALL)
	
	Return lcID
	
EndFunc

*-- Returns a timestamp
Function getTimeStamp
Lparameters tdDate, ttTime

	Private All Except g*
	DECLARE GetSystemTime IN Win32API String @ lsSystemTime
	DECLARE integer SystemTimeToFileTime IN Win32API string @ lsSystemTime, string @ lsFileTime
	DECLARE integer FileTimeToLocalFileTime IN Win32API string @ lsFileTime, string @ lsLocalFileTime
	DECLARE integer FileTimeToDosDateTime IN Win32API string @ lsLocalFileTime, string @ lsDate, string @ lsTime
	
	*-- Create the structures
	lsSystemTime = SPACE(16)
	lsFileTime = SPACE(8)
	lsLocalFileTime = SPACE(8)
	lsDate = SPACE(2)
	lsTime = SPACE(2)
	GetSystemTime(@lsSystemTime)
	liRet = SystemTimeToFileTime(@lsSystemTime, @lsFileTime)
	liRet = FileTimeToLocalFileTime(@lsFileTime, @lsLocalFileTime)
	liRet = FileTimeToDosDateTime(@lsLocalFileTime, @lsDate, @lsTime)
	
	*-- Unpack the structures
	liDate = This.StrToWord(lsDate)
	liTime = This.StrToWord(lsTime)
	
	RETURN BITLSHIFT(liDate, 16) + liTime
		
*--		tdDate = Iif(Empty(tdDate), Date(), tdDate)
*--		ttTime = Iif(Empty(ttTime), Time(), ttTime)

*--		Return ;
*--			((Year(tdDate) -1990)  * 2 ** 25) + ;
*--			 (Month(tdDate)        * 2 ** 21) + ;
*--			 (Day(tdDate)          * 2 ** 16) + ;
*--			 (Val(Left(ttTime, 2)) * 2 ** 11) + ;
*--			 (Val(SubStr(ttTime, 4, 2)) * 2 **  5) + ;
*--			 Val(Right(ttTime, 2))
		 
EndFunc

*-- Removes a task from the task list
Function removeTask
LParameters tcUniqueID

	Private All Except g*

	*-- open/select the main table
	If this.openDBF(OPEN_MAIN)
	
		*-- Delete the record from the main table
		Delete For tskMain.UniqueID = tcUniqueID

		*-- open/select the child table
		If this.openDBF(OPEN_CHILD)
		
			*-- Delete from the child table
			Delete For tskChild.UniqueID = tcUniqueID
		Endif
	Endif

	this.closeDBF(CLOSE_ALL)

	this.requeryData()
	This.TaskUI.liLastRow = this.TaskUI.oleGrid.Row - 1
	this.taskUI.requeryData()
	
EndFunc

*-- Updates a task
Function updateTask
LParameters toTaskObj

	Private All Except g*

	Local lnFields, i, lcField
	
	*-- open/select the main table
	If this.openDBF(OPEN_MAIN)
		Dimension laFields[1]  
  	
		*-- find a matching task
		Locate For tskMain.UniqueID = toTaskObj._uniqueID
		If Found()
			lnFields = AFields(laFields)

			*-- since the fields can change, dynamically update the data
			For i = 1 To lnFields
				lcField = laFields[i,1]
				If PemStatus(toTaskObj, "_" + lcField, PEM_DEFINED)
					If this.typesAreCompatible(Type("tskMain." + lcField), Type("toTaskObj._" + lcField))
						Replace tskMain.&lcField. With toTaskObj._&lcField.
					Else
						Replace tskMain.&lcField. With this.forceType(toTaskObj._&lcfield., Type("tskMain." + lcField))
					Endif
				EndIf
			EndFor
		Endif

		*-- open/select the child table
		If this.openDBF(OPEN_CHILD)
			Dimension laFields[1]

			*-- Find the matching record
			Locate For tskChild.UniqueID = toTaskObj._uniqueID
			IF !FOUND()
				*- ? Maybe added the column after the task was added
				INSERT INTO tskChild (uniqueID) VALUES (toTaskObj._uniqueID)
			ENDIF
			lnFields = AFields(laFields)
			
			For i = 1 To lnFields
				lcField = laFields[i,1]
				If PemStatus(toTaskObj, "_" + lcField, PEM_DEFINED)
					If !ISNULL(toTaskObj._&lcField.) AND this.typesAreCompatible(Type("tskChild." + lcField), Type("toTaskObj._" + lcField))
						Replace tskChild.&lcField. With toTaskObj._&lcField.
					Else
						Replace tskChild.&lcField. With this.forceType(toTaskObj._&lcfield., Type("tskChild." + lcField))
					Endif
				EndIf
			EndFor
		Endif
	Endif

	this.requeryData()

	this.closeDBF(CLOSE_ALL)
	
EndFunc

*-- Returns a pointer to an empty Task object
Function getTaskObject

	Private All Except g*

	Return CreateObject("Task", This)

EndFunc

*-- Returns a pointer to a task object retrieved
*-- from the database
Function getTask
LParameters tcUniqueID

	Private All Except g*

	Local lcSql, loTask, loRetVal

	lcSql = this.buildQuery()
	If !Empty(lcSql)
		
		lcSql = lcSql + 'Where !Deleted() And tskMain.uniqueID == "' + tcUniqueID + '" Into Cursor csrTask'
		
		&lcSql
		
		If _Tally > 0 And Used("csrTask")
			Scatter Memo Name loTask
			Use In csrTask
			
			loRetVal = this.dataObjToTask(loTask)
		EndIf
	EndIf
	
	Return loRetVal
	
EndFunc

*-- Returns an array with field information from _TASKDBF
*-- Returns name and an empty typed value for the field
Function getStandardFields
LParameters taFieldArray

	Private All Except g*

	Local Array laFields[1]
	Local lnFields, i, lcField, loRecord

	If this.openDBF(OPEN_MAIN)
		Scatter Memo Name loRecord Blank
		lnFields = AFields(laFields)
		Dimension taFieldArray[lnFields,2]
		For i = 1 To lnFields
			If laFields[i, 2] <> "G"
				lcField = laFields[i, 1]
				taFieldArray[i,1] = lcField
				taFieldArray[i,2] = loRecord.&lcField.
			Else
				ADel(laFields, i)
				ADel(taFieldArray, i)
				lnFields = lnFields -1
			Endif
		EndFor			
	Else
		lnFields = 0
	EndIf

	Return lnFields

EndFunc

*-- Returns a field names from the child table
*-- Also returns an empty typed value for each field
Function getUDFFields
LParameters taFieldArray

	Private All Except g*

	Local Array laFields[1]
	Local lnFields, i, lcField, loRecord

	If this.openDBF(OPEN_CHILD)
		Scatter Memo Name loRecord Blank
		lnFields = AFields(laFields)
		Dimension taFieldArray[lnFields,2]
		For i = 1 To lnFields
			If laFields[i, 2] <> "G"
				lcField = laFields[i, 1]
				taFieldArray[i,1] = lcField
				taFieldArray[i,2] = loRecord.&lcField.
			Else
				ADel(laFields, i)
				ADel(taFieldArray, i)
				lnFields = lnFields -1
			ENDIF
			IF i >= lnFields
				EXIT
			ENDIF
		EndFor	
	Else
		lnFields = 0		
	EndIf

	Return lnFields
	
EndFunc

*-- openDBF
*-- Opens the main or child table, or if the table is already open
*-- it sets the workarea to the workarea of the open table
*-- Returns False if the table cannot be opened
*--
Function openDBF
LParameters tnType

	Private All Except g*

	Local llRetVal, lErr
	LOCAL lcOldError
	
	lErr = .F.
	llRetVal = .F.
	lcOldError = ON("ERROR")

	Do Case
	Case tnType = OPEN_MAIN
		If !Used("tskMain")
			If File(this.dataSource)
				ON ERROR lErr = .T.				
				Use (this.dataSource) Again Alias "tskMain" Shared In Select(1)
				IF lErr OR !USED("tskMain")
					llRetVal = .F.
				ELSE
					Select tskMain
	  				llRetVal = .T.
	  			ENDIF
			Else
				llRetVal = .F.
			Endif
		Else
			Select tskMain
  			llRetVal = .T.
		EndIf
	Case tnType = OPEN_CHILD
  		this.errorState = ERROR_IGNORE
		If !Used("tskChild")
			If File(this.childDataSource)
				ON ERROR lErr = .T.				
				Use (this.childDataSource) Again Alias "tskChild" Shared In Select(1)
				IF lErr OR !USED("tskChild")
					llRetVal = .F.
				ELSE
					Select tskChild
					*-- The child table must have a "uniqueid" character field or bad
					*-- things will happen
	  				llRetVal = (Type("tskChild.uniqueID") == "C")
	  				If !llRetVal And Used("tskChild")
	  					Use In tskChild
	  				ENDIF
	  			ENDIF
			Else	
				llRetVal = .F.
			EndIf
		Else
			Select tskChild
			llRetVal = .T.
		EndIf
  		this.errorState = ERROR_UNKNOWN
	ENDCASE
	
	ON ERROR &lcOldError

	Return llRetVal
	
EndFunc

Function closeDBF
LParameters tnType

	Do Case
	Case tnType = CLOSE_ALL
		If Used("tskMain")
			Use In tskMain
		Endif
		If Used("tskChild")
			Use In tskChild
		Endif
	Case tnType = CLOSE_MAIN
		If Used("tskMain")
			Use In tskMain
		Endif
	Case tnType = CLOSE_CHILD
		If Used("tskChild")
			Use In tskChild
		Endif
	EndCase

EndFunc

*-- Converts a data object created by SCATTER NAME to a
*-- task object
Function dataObjToTask
LParameters toDataObj

	Private All Except g*

	Local Array laStruct[1]
	Local loTaskObj, lnCnt, lcProperty

	loTaskObj = CreateObject("Task", This)

	*-- Get all properties from toDataObj

	lnCnt = AMembers(laStruct, toDataObj)
	For Each lcProperty In laStruct
		If PemStatus(loTaskObj, "_" + lcProperty, PEM_DEFINED)
			loTaskObj._&lcProperty. = toDataObj.&lcProperty.
		EndIf
	EndFor

	*-- Before adding, let's make sure the Priority is 
	*-- valid.  This often zero, so let's at least 
	*-- set it to a valid value before saving.
	IF lotaskobj._Priority < 1 Or lotaskobj._Priority > 3
		lotaskobj._Priority = 1
	ENDIF
		
	*-- Blank dates show up in Open Task as 1899, due to 
	*-- how ActiveX control handles blank dates.  Give
	*-- a default of today's date.
*!*		IF ISBLANK(lotaskobj._duedate)
*!*			lotaskobj._duedate = DATE()
*!*		Endif

	*-- UniqueID and Timestamp must exist
	*-- If we joined on the child table, uniqueid and timestamp
	*-- will be duped, i.e., have _a and _b fields
	If PemStatus(toDataObj, "uniqueID_a", PEM_DEFINED)
		loTaskObj._uniqueID = toDataObj.uniqueID_a
	Endif
	If PemStatus(toDataObj, "timestamp_a", PEM_DEFINED)
		loTaskObj._timestamp = toDataObj.timestamp_a
	EndIf
	
	Return loTaskObj
	
EndFunc

*-- Since properties are variant, we have to make
*-- sure its value is compatible with the table's field type
Function typesAreCompatible
LParameters tcType1, tcType2

	Private All Except g*

	Do Case
		CASE ISNULL(tcType2)
			*- use ForceType to translate .NULL. into an empty value
			RETURN .F.

		*-- If they are equal, it's a no-brainer
		Case tcType1 = tcType2
			Return .T.

		*-- Memo and character are interchangable in this case
		Case tcType2 = "C"
			Return tcType1 = "M"
		
		*-- Numeric and currency are interchangable in this case
		Case tcType2 = "N"
			Return  tcType1 = "Y" 
		
	EndCase
	
	Return .F.
EndFunc

*-- This forces a character expression into the passed type
Function forceType
LParameters tcValue, tcType

	*-- tcValue will always be character type, unless tcType = 'C', in which case convert to char
	Do Case
	Case tcType = "N"
		Return IIF(ISNULL(tcValue), 0, Val(tcValue))
	Case tcType = "D"
		Return  IIF(ISNULL(tcValue), {}, CToD(tcValue))
	Case tcType = "T"
		Return  IIF(ISNULL(tcValue), TTOC({}), TToC(tcValue))
	Case tcType = "I"
		Return IIF(ISNULL(tcValue), 0, Val(tcValue))
	Case tcType = "L"
		Return IIF(ISNULL(tcValue), .F.,(AtCC("Y",tcValue) > 0) Or (AtCC("T", tcValue) > 0))
	Case tcType = "Y"
		Return IIF(ISNULL(tcValue), 0, Val(tcValue))
	CASE tcType = 'C'
		*- convert whatever to char
		DO CASE
			CASE ISNULL(tcValue)
				RETURN ""
			CASE VARTYPE(tcValue) $ 'NIBFY'
				RETURN STR(tcValue, 20,2)
			CASE VARTYPE(tcValue) $ 'D'
				RETURN DTOC(tcValue)
			CASE VARTYPE(tcValue) $ 'T'
				RETURN TTOC(tcValue)
			CASE VARTYPE(tcValue) $ 'L'
				RETURN IIF(tcValue, ".T.", ".F")
			CASE VARTYPE(tcValue) $ 'D'
				RETURN DTOC(tcValue)
			CASE VARTYPE(tcValue) $ 'CM'
				RETURN tcValue
			OTHERWISE
				RETURN ""
		ENDCASE
	EndCase

EndFunc

*-- Read preferences from resource file
*-- Restore only respects the scope of Local variables,
*-- and does not restore a variable as Public even if
*-- it was declared public prior to Save To
Function getPref
LParameters tcID, tcPubList

	Private All Except g*

	*-- cPubList contains a comma-delimited list of 
	*-- memory variables that should be restored as public

	If !Empty(tcPubList)
		Public &tcPubList.
	Endif

	Local lnSaveArea, lnMemwidth, i, llRetVal

	llRetVal = .T.

	lnSaveArea = Select()
	lnMemwidth = Set('MEMOWIDTH')

	Set MemoWidth To 255

	If this.openResFile()
		Locate For Upper(AllTrim(type)) == "PREFW" ;
			And Upper(Alltrim(id)) == tcID ;
			And !Deleted()

		If Found() And !Empty(data) And ;
			ckVal = Val(Sys(2007, data))
			Restore From Memo data Additive

			If Type("g_save_cRestoredCorrectly") = "C"
				llRetVal = .T.
				Release g_save_cRestoredCorrectly
			EndIf
		Else
			llRetVal = .F.
		EndIf
		
		Use
	Else
		llRetVal =  .F.
	EndIf

	Select (lnSaveArea)
	Set MemoWidth To lnMemWidth	

	Release tcPublist, tcID, lnSaveArea, lnMemWidth, i

	Return llRetVal

EndFunc

* Record user preferences in the resource file
Function savePref
LParameters tcID

	Private All Except g*

	Local laFileArray, llRetVal
	Local lnFilePos, lcFileAttr, lnSaveArea, i, lnLen

	llRetVal = .T.

	lnSaveArea = SELECT()

	If File(Sys(2005))
		lcFileAttr = ""
		Dimension laFileArray[1]
		If ADir(laFileArray, Sys(2005))> 0
			lnFilePos = AScan(laFileArray, JustFName(Sys(2005)))
			If lnFilePos > 0
				lcFileAttr = laFileArray[lnFilePos, 5]
			EndIf
		EndIf
		If AtCC("R", lcFileAttr) = 0
			If this.openResFile()
				If !IsReadOnly()
					Locate For Upper(AllTrim(type)) == "PREFW" ;
						And Upper(AllTrim(id)) == tcID ;
						And !Deleted()

					If !Found()
					   Append Blank
					EndIf
					Public g_save_cRestoredCorrectly
					g_save_cRestoredCorrectly = "YES"
					Save To Memo data All Like g_save_*
					REPLACE type     WITH "PREFW",;
				           id       WITH tcID,;
				           ckval    WITH VAL(SYS(2007,data)),;
				           updated  WITH DATE(),;
				           readonly WITH .F.
					Release g_save_cRestoredCorrectly
				Else
					llRetVal = .F.
				Endif
			Else
				llRetVal = .F.
			EndIf
		Else	
			llRetVal = .F.
		EndIf
	Else
		llRetVal = .F.
	Endif

	Use
	Select (lnSaveArea)
	Return llRetVal

EndFunc

*-- Opens the resource file for use
Function openResFile
Private All Except g*

	Local lnSaveArea, lcOldError, lErr
	lErr = .F.

	lnSaveArea=SELECT()

	If !File(Sys(2005))
		Return .F.
	Endif

	Select 0

	*-- Trap File Access Is Denied message
	this.errorState = ERROR_IGNORE
	lcOldError = ON("ERROR")
	ON ERROR lErr = .T.				
	Use (Sys(2005)) Again Shared
	this.errorState = ERROR_UNKNOWN

	ON ERROR &lcOldError
	
	If lErr OR Empty(Alias())
		Select (lnSaveArea)
	ENDIF
	
	RETURN !lErr
EndFunc

*-- Returns the tasks as an XML string
Function xml_access
	Local lcXML, i
	
	lcXML = '<?xml version="1.0"?>' + CR_LF
	lcXML = "<tasklist>" + CR_LF
	
	For i = 1 To this.taskCount
		lcXML = lcXML + this.tasks[i].xml
	EndFor
	
	lcXML = lcXML + "</tasklist>" + CR_LF
	
	Return lcXML

EndFunc

Function shellExecute
	* WinApi :: ShellExecute
	**  Function: Opens a file in the application that it's
	**            associated with.
	**      Pass: lcFileName -  Name of the file to open
	**   
	**  Return:   -1  - No Filename Passed
	**			   2  - Bad Association (e.g., invalid URL)
	**            31 - No application association
	**            29 - Failure to load application
	**            30 - Application is busy 
	**
	**            Values over 32 indicate success
	**            and return an instance handle for
	**            the application started (the browser) 
	LParameters tcFilename, tcWorkDir, tcOperation
	Local lcFileName,lcWorkDir,lcOperation

	If Empty(tcFilename)
		Return -1
	Endif
	
	lcFileName = AllTrim(tcFilename)
	lcWorkDir = Iif(Type("tcWorkDir") = "C", AllTrim(tcWorkDir), "")
	lcOperation = Iif(Type("tcOperation")="C" And Not Empty(tcOperation), AllTrim(tcOperation), "Open")

	*-* HINSTANCE ShellExecute(hwnd, lpszOp, lpszFile, lpszParams, lpszDir, wShowCmd)
	*-* 
	*-* HWND hwnd - handle of parent window
	*-* LPCTSTR lpszOp - address of string for operation to perform
	*-* LPCTSTR lpszFile - address of string for filename
	*-* LPTSTR lpszParams - address of string for executable-file parameters
	*-* LPCTSTR lpszDir - address of string for default directory
	*-* INT wShowCmd - whether file is shown when opened
	Declare Integer ShellExecute In Shell32.dll ;
		Integer nWinHandle, String cOperation, String cFilename, ;
		String cParameters, String cDirectory, Integer nShowWindow

	lnRetVal = ShellExecute(0,lcOperation,lcFilename,"",lcWorkDir,1)

	*-- TODO: add when support in vfp7 added
	*-- Clear Dlls "ShellExecute"

	Return lnRetVal

EndFunc

FUNCTION GetDateFormat
	*- determine the current VFP date format, and return in a form the DateTime picker can use
	LOCAL lcDateFormat
	
	lcDateFormat = CHRTRAN(CHRTRAN(CHRTRAN(DTOC({^ 3333-1-2}),"3","y"),"1","M"),"2","d")
	lcDateFormat = ;
		STRTRAN(STRTRAN(STRTRAN(lcDateFormat, "yyyy", "yyy"), "0d", "dd"), "0M", "MM")
	RETURN lcDateFormat
ENDFUNC

FUNCTION GetRegSZKey

*-- Reads a REG_SZ from the registry.  Currently used to get
*-- VFP regional date setting when data session changes.
*--
*-- Parameters:
*--	nKey - The root key to open. It can be any of the constants defined below.
*--	#DEFINE HKEY_CLASSES_ROOT -2147483648
*--	#DEFINE HKEY_CURRENT_USER -2147483647
*--	#DEFINE HKEY_LOCAL_MACHINE -2147483646
*--	#DEFINE HKEY_USERS -2147483645
*--	cSubKey - The SubKey to open.
*--	cValue - The value that is going to be read.

*--	Constants that are needed for Registry functions

PARAMETERS nKey, cSubKey, cValue

LOCAL nErrCode && Error Code returned from Registry functions
LOCAL nKeyHandle && Handle to Key that is opened in the Registry
LOCAL lpdwValueType && Type of Value that we are looking for
LOCAL lpbValue && The data stored in the value
LOCAL lpcbValueSize && Size of the variable
LOCAL lpdwReserved && Reserved Must be 0

*-- Win32 functions
DECLARE Integer RegOpenKey IN Win32API ;
Integer nHKey, String @cSubKey, Integer @nResult
DECLARE Integer RegQueryValueEx IN Win32API ;
Integer nHKey, String lpszValueName, Integer dwReserved,;
Integer @lpdwType, String @lpbData, Integer @lpcbData
DECLARE Integer RegCloseKey IN Win32API Integer nHKey

*-- Initialize the variables
nKeyHandle = 0
lpdwReserved = 0 
lpdwValueType = REG_SZ
lpbValue = ""

nErrCode = RegOpenKey(nKey, cSubKey, @nKeyHandle)

*-- If the error code isn't 0, then the key doesn't exist or can't be opened.
IF (nErrCode # 0) THEN
	RETURN ""
ENDIF

lpcbValueSize = 1 

*-- Get the size of the data in the value
nErrCode=RegQueryValueEx(nKeyHandle, cValue, lpdwReserved, @lpdwValueType, @lpbValue, @lpcbValueSize)

*-- Make the buffer big enough
lpbValue = SPACE(lpcbValueSize) 
nErrCode=RegQueryValueEx(nKeyHandle, cValue, lpdwReserved, @lpdwValueType, @lpbValue, @lpcbValueSize)

=RegCloseKey(nKeyHandle)
IF (nErrCode # 0) THEN
RETURN ""
ENDIF

lpbValue = LEFT(lpbValue, lpcbValueSize - 1)

RETURN lpbValue
ENDFUNC

* Function str2word - Converts low-high format string representation
* to a 16-bit integer (word) value. Useful for unrolling structure
* members containg WORD types.
*
* Passed: Low-high string representation of 16-bit integer
* Returns: numeric value
FUNCTION StrToWord

PARAMETERS m.wordstr

PRIVATE i, m.retval

m.retval = 0
FOR i = 0 TO 8 STEP 8
m.retval = m.retval + (ASC(m.wordstr) * (2^i))
m.wordstr = RIGHT(m.wordstr, LEN(m.wordstr) - 1)
NEXT
RETURN m.retval
ENDFUNC

EndDefine


*-- Context Menu handler class
*-- When the context menu is popped up, we need something global
*-- to handle the response
Define Class ContextMenuHandler As Line

	Hidden BaseClass, BorderColor, BorderStyle, BorderWidth, Class, ClassLibrary
	Hidden ColorSource, Comment, DragIcon, DragMode, DrawMode, Enabled, Height 
	Hidden HelpContextID, Left, LineSlant, MouseIcon, MousePointer, Name, oleDragMode
	Hidden oleDragPicture, oleDropEffects, oleDropHasData, oleDropMode, Parent
	Hidden ParentClass, Tag, Top, Visible, WhatsThisHelpID, Width

	UI = .F.    	&& will contain a pointer to the user interface that popped this
	Task = .F.		&& will contain a task object, or .f. that we are acting upon
	
*-- We will receive a pointer to the UI and a pointer to a task object
Function Init
LParameters toUI, toTask
 
	Private All Except g*

	This.UI = toUI
	This.Task = toTask

EndFunc

*-- Calls the task editor to edit a single task and all of its fields
Function OpenTask

	Private All Except g*

	Local loTaskEdit, liFontSize, lcFontName

	loTaskEdit = NewObject("taskedit","tasklistui.vcx", "", this.Task)
	WITH loTaskEdit.pgfPanes.Page1
		liFontSize = ._line.FontSize
		lcFontName = ._line.FontName
		
#IF 0		
		._duedate.Object.Font.Size = liFontSize
		._duedate.Object.Font.Name = lcFontName
		._priority.Object.Font.Size = liFontSize
		._priority.Object.Font.Name = lcFontName
#ENDIF		
	ENDWITH
	
	IF Empty(loTaskEdit.Task._duedate)
		loTaskEdit.pgfPanes.Page1._dueDATE.oBJECT.Day = DAY(DATE())
		loTaskEdit.pgfPanes.Page1._duedate.Object.Month = MONTH(DATE())
		loTaskEdit.pgfPanes.Page1._duedate.Object.Year = YEAR(DATE())
	Endif
	loTaskEdit.Show(SHOW_MODAL)
	
	Release loTaskEdit

EndFunc

*-- Prints a task and all of its data to a standard report form
Function PrintTask

	Private All Except g*

EndFunc

*-- Opens the file associated with the task. This is important for
*-- shortcuts, and nice for other files
Function OpenFile

	Private All Except g*
	LOCAL lcExt
	
	Do Case
	Case this.Task._type = TASK_TYPE_SHORTCUT
  		If File(this.task._filename)
  			LOCAL lsMethodName as String
  			
  			*-- VFP is sticking class.method in the DBF,
  			*-- when only the procname is needed for SCX
  			IF UPPER(JUSTEXT(this.task._filename)) = 'VCX'
				lsMethodName = SUBSTR(this.task._method, ATC('.', this.task._method)+1,LEN(this.task._method))
				EditSource(this.task._filename, this.task._line, this.task._class, lsMethodName)
			ELSE
				EditSource(this.task._filename, this.task._line, this.task._class, this.task._method)
			ENDIF
			RELEASE lsMethodName
  		Else
  			If MessageBox(FILE_NOT_EXIST_LOC, MB_YESNO + MB_ICONEXCLAMATION) == IDYES
  				this.task.taskList.removeTask(this.task._uniqueID)
  			Endif
  		Endif
	Otherwise
		Local lnRetVal

		*- see if it is a file type that VFP can handle
		lcExt = UPPER(JUSTEXT(this.task._filename))
		DO CASE
			CASE INLIST(lcExt, "H", "TXT", "INI", "LOG", "PRG", "QPR", "LBX", "FRX", "SCX", "VCX", "MNX", "DBC")
		  		If File(this.task._filename)
					EditSource(this.task._filename, this.task._line, this.task._class, this.task._method)
		  		Else
		  			If MessageBox(FILE_NOT_EXIST_LOC, MB_YESNO + MB_ICONEXCLAMATION) == IDYES
		  				this.task.taskList.removeTask(this.task._uniqueID)
		  			Endif
		  		Endif
			OTHERWISE
				lnRetVal = this.task.tasklist.shellExecute(this.task._filename)
				Do Case
				Case lnRetVal = SHELL_EX_NO_FILENAME
					=MessageBox(ERROR_NO_FILENAME_LOC, MB_OK, APP_TITLE_LOC)
				Case lnRetVal = SHELL_EX_BAD_ASSOC
					=MessageBox(ERROR_BAD_ASSOC_LOC, MB_OK, APP_TITLE_LOC)
				Case lnRetVal = SHELL_EX_NO_APP
					=MessageBox(ERROR_NO_APP_LOC, MB_OK, APP_TITLE_LOC)
				Case lnRetVal = SHELL_EX_APP_BUSY
					=MessageBox(ERROR_APP_BUSY_LOC, MB_OK, APP_TITLE_LOC)
				Case lnRetVal = SHELL_EX_FAIL_LOAD
					=MessageBox(ERROR_FAIL_LOAD_LOC, MB_OK, APP_TITLE_LOC)
				EndCase
			EndCase
		ENDCASE
EndFunc

*-- Calls the import selection dialog
Function Import

	Private All Except g*

	*-- TODO: write the import interface

EndFunc

*-- Calls the export selection dialog
Function Export

	Private All Except g*

	*-- TODO: write the export interface

EndFunc

*-- Sets the status of a task. This can be
*-- completed, read, flagged, etc.
Function Status
LParameters tnSetStatus

	Private All Except g*

	this.task._status = BITXOR(tnSetStatus, this.task._status)
	this.ui.tasklist.updateTask(this.task)

EndFunc

*-- Deletes a task from the database
Function DeleteTask

	Private All Except g*

	If MessageBox(DELETE_TASK_LOC, MB_ICONQUESTION + MB_YESNO) == IDYES
		this.ui.tasklist.removeTask(this.task._uniqueID)
	Endif

EndFunc

*-- Determines which tasks the engine loads.
Function ShowTasks
LParameters tnBar, tlState

	Private All Except g*

	Do Case
	Case tnBar = _MTM_SHOW_SHORTCUTS
		If TASK_TYPE_SHORTCUT $ this.task.taskList.showTasks
			this.task.taskList.showTasks = ChrTranC(this.task.taskList.showTasks, TASK_TYPE_SHORTCUT, "")
		Else
			this.task.taskList.showTasks = this.task.taskList.showTasks + TASK_TYPE_SHORTCUT
		Endif
	Case tnBar = _MTM_SHOW_OTHER
		If TASK_TYPE_OTHER $ this.task.taskList.showTasks
			this.task.taskList.showTasks = ChrTranC(this.task.taskList.showTasks, TASK_TYPE_OTHER, "")
		Else
			this.task.taskList.showTasks = this.task.taskList.showTasks + TASK_TYPE_OTHER
		Endif
	Case tnBar = _MTM_SHOW_USERDEFINED
		If TASK_TYPE_USERDEFINED $ this.task.taskList.showTasks
			this.task.taskList.showTasks = ChrTranC(this.task.taskList.showTasks, TASK_TYPE_USERDEFINED, "")
		Else
			this.task.taskList.showTasks = this.task.taskList.showTasks + TASK_TYPE_USERDEFINED
		Endif
	EndCase

	this.task.taskList.requeryData()
	this.task.tasklist.taskui.requeryData()

EndFunc

*-- Launches the column chooser dialog
Function ColumnChooser

	Private All Except g*

	If Type("goColumns.name") = "C"
		goColumns.Show()
	Else
		Public goColumns
		goColumns = NewObject("columnlist","tasklistui","",this.ui)
		goColumns.Show()
	Endif
	
EndFunc

*-- Removes a column from the ui
Function RemoveColumn

	Private All Except g*
	
	Local lnCol

	lnCol = this.ui.oleGrid.col +1
	this.ui.removeColumn(this.ui.columns[lnCol, COL_FIELD])
	this.ui.requeryData()
	
	If Type("goColumns.class") = "C"
		goColumns.requeryData()
	Endif

EndFunc

Function Options 

  Local loOptions
  
  loOptions = NewObject("taskoptions","tasklistui","",this.ui.taskList)
  loOptions.Show()
  
  Release loOptions

ENDFUNC

*-- Cleans up the tasklist table
FUNCTION CleanUp
	LOCAL lsFileName As String
	lsFileName = _foxtask
	_foxtask = ""
	
	TRY 
		USE (lsFileName) EXCLUSIVE IN 0
		PACK
	CATCH TO oException
		MESSAGEBOX(ERROR_PACKDBF,48)
	FINALLY
		USE
		_foxtask = lsFileName
	EndTry
EndFunc

EndDefine

* <summary>
*	Data Management for Visual FoxPro.
* </summary>
#include "DataExplorer.h"
#include "foxpro.h"

DEFINE CLASS VFPDatabaseMgmt AS DatabaseMgmt OF DataMgmt.prg
	DatabaseFile = ''
	
	FUNCTION DatabaseFile_ACCESS
		RETURN THIS.DatabaseFile
	ENDFUNC


	FUNCTION Connect(cDatabase, cUserName, cPassword) AS Boolean
		LOCAL lSuccess
		
		lSuccess = .F.

		IF VARTYPE(cUserName) <> 'C'
			cUserName = ''
		ENDIF
		IF VARTYPE(cPassword) <> 'C'
			cPassword = ''
		ENDIF
		
		
		* make sure we can get it open
		lSuccess = THIS.OpenDBC(cDatabase)
		
		* no need to leave it open once we've
		* determined we can open it
		IF lSuccess	
			THIS.CloseDBC()
		ENDIF
		
		RETURN lSuccess
	ENDFUNC
	
	FUNCTION OnGetTables(oTableCollection AS TableCollection)
		LOCAL i
		LOCAL nCnt
		LOCAL ARRAY aObjList[1]

		IF THIS.OpenDBC()
			nCnt = ADBOBJECTS(aObjList, "TABLE")

			IF nCnt > 0 AND THIS.SortObjects
				ASORT(aObjList)
			ENDIF
			
			FOR i = 1 TO nCnt
				oTableCollection.AddEntity(aObjList[i], ADDBS(JUSTPATH(DBC())) + DBGETPROP(aObjList[i], "TABLE", "Path"))
			ENDFOR
		
			THIS.CloseDBC()
		ENDIF
	ENDFUNC

	FUNCTION OnGetViews(oViewCollection AS ViewCollection)
		LOCAL i
		LOCAL nCnt
		LOCAL cViewDef
		LOCAL ARRAY aObjList[1]

		IF THIS.OpenDBC()
			nCnt = ADBOBJECTS(aObjList, "VIEW")

			IF nCnt > 0 AND THIS.SortObjects
				ASORT(aObjList)
			ENDIF
			
			FOR i = 1 TO nCnt
				* cViewDef = DBGETPROP(aObjList[i], "VIEW", "SQL")
				oViewCollection.AddEntity(aObjList[i], '')
			ENDFOR

			THIS.CloseDBC()
		ENDIF
	ENDFUNC

	FUNCTION OnGetStoredProcedures(oStoredProcCollection AS StoredProcCollection)
		LOCAL i
		LOCAL nCnt
		LOCAL nSelect
		LOCAL oException
		LOCAL cTempFile
		LOCAL cSafety
		LOCAL nLineCnt
		LOCAL j
		LOCAL cProcDef
		LOCAL ARRAY aObjList[1]
		LOCAL ARRAY aProcCode[1]

		IF THIS.OpenDBC()
			nSelect = SELECT()
			
			SELECT 0
			
			TRY
				USE (DBC()) ALIAS DBCCursor SHARED AGAIN
				LOCATE FOR Objectname = "StoredProceduresSource"
				IF FOUND()
					cTempFile = ADDBS(SYS(2023)) + SYS(2015) + ".tmp"
					STRTOFILE(DBCCursor.code, cTempFile)
					
					nCnt = APROCINFO(aObjList, cTempFile)
					IF nCnt > 0 AND THIS.SortObjects
						ASORT(aObjList)
					ENDIF
					
					FOR i = 1 TO nCnt
						IF aObjList[i, 3] == 'Procedure'  && type
							oStoredProcCollection.AddEntity(aObjList[i, 1], '')
						ENDIF
					ENDFOR
					
					cSafety = SET("SAFETY")
					SET SAFETY OFF
					ERASE (cTempFile)
					SET SAFETY &cSafety
				ENDIF

			CATCH TO oException
				MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, DATAEXPLORER_LOC)
			FINALLY
				IF USED("DBCCursor")
					USE IN DBCCursor
				ENDIF
				SELECT (nSelect)
			ENDTRY

			THIS.CloseDBC()
		ENDIF
	ENDFUNC

	FUNCTION OnGetFunctions(oFunctionCollection AS FunctionCollection)
	ENDFUNC
	
	FUNCTION OnGetStoredProcedureDefinition(cStoredProcName, cOwner) AS String
		LOCAL i
		LOCAL nCnt
		LOCAL nSelect
		LOCAL oException
		LOCAL cTempFile
		LOCAL cSafety
		LOCAL nLineCnt
		LOCAL j
		LOCAL cProcDef
		LOCAL ARRAY aObjList[1]
		LOCAL ARRAY aProcCode[1]

		cProcDef = ''
		IF THIS.OpenDBC()
			nSelect = SELECT()
			
			SELECT 0
			
			TRY
				USE (DBC()) ALIAS DBCCursor SHARED AGAIN
				LOCATE FOR Objectname = "StoredProceduresSource"
				IF FOUND()
					cTempFile = ADDBS(SYS(2023)) + SYS(2015) + ".tmp"
					STRTOFILE(DBCCursor.code, cTempFile)
					
					nCnt = APROCINFO(aObjList, cTempFile)
					FOR i = 1 TO nCnt
						IF aObjList[i, 3] == 'Procedure' AND aObjList[i, 1] == cStoredProcName 
							* put code into array so we can extract the definition
							nLineCnt = ALINES(aProcCode, DBCCursor.code)

							* extract the definition
							cProcDef = ''
							FOR j = aObjList[i, 2] TO IIF(i == nCnt, nLineCnt, aObjList[i + 1, 2] - 1)
								cProcDef = cProcDef + IIF(j == 1, '', CHR(13) + CHR(10)) + aProcCode[j]
								IF INLIST(UPPER(ALLTRIM(aProcCode[j])), [** "END], "ENDPROC", "ENDFUNC")
									EXIT
								ENDIF
							ENDFOR
							EXIT
						ENDIF
					ENDFOR
					
					cSafety = SET("SAFETY")
					SET SAFETY OFF
					ERASE (cTempFile)
					SET SAFETY &cSafety
				ENDIF

			CATCH TO oException
				MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, DATAEXPLORER_LOC)
			FINALLY
				IF USED("DBCCursor")
					USE IN DBCCursor
				ENDIF
				SELECT (nSelect)
			ENDTRY

			THIS.CloseDBC()
		ENDIF

		RETURN cProcDef
	ENDFUNC
	
	FUNCTION OnGetFunctionDefinition(cFunctionName, cOwner) AS String
		* no function definitions in VFP
		RETURN ''
	ENDFUNC

	FUNCTION OnGetViewDefinition(cViewName, cOwner) AS String
		LOCAL i
		LOCAL nCnt
		LOCAL cViewDef
		LOCAL ARRAY aObjList[1]

		cViewDef = ''
		IF THIS.OpenDBC()
			nCnt = ADBOBJECTS(aObjList, "VIEW")

			
			FOR i = 1 TO nCnt
				IF aObjList[i] == cViewName
					cViewDef = DBGETPROP(aObjList[i], "VIEW", "SQL")
					EXIT
				ENDIF
			ENDFOR

			THIS.CloseDBC()
		ENDIF
		
		RETURN cViewDef
	ENDFUNC
	

	FUNCTION OnGetSchema(oColumnCollection AS ColumnCollection, cTableName, cOwner)
		LOCAL i
		LOCAL nCnt
		LOCAL nSelect
		LOCAL ARRAY aObjList[1]

		nSelect = SELECT()

		IF THIS.OpenTable(cTableName, "TableCursor")
			nCnt = AFIELDS(aObjList, "TableCursor")

			IF nCnt > 0 AND THIS.SortObjects
				ASORT(aObjList)
			ENDIF
			FOR i = 1 TO nCnt
				oColumnCollection.AddEntity(aObjList[i, 1], aObjList[i, 2], aObjList[i, 3], aObjList[i, 4], , aObjList[i, 5], aObjList[i, 9])
			ENDFOR
			
			IF USED("TableCursor")
				USE IN TableCursor
			ENDIF

			THIS.CloseDBC()
		ENDIF

		SELECT (nSelect)
			
	ENDFUNC

	
	FUNCTION OnBrowseData(cTableName, cOwner)
		LOCAL nSelect
		LOCAL oBrowseForm
		
		nSelect = SELECT()

		IF THIS.OpenTable(cTableName, JUSTSTEM(cTableName))
			DO FORM BrowseForm
			THIS.CloseDBC()
		ENDIF

		SELECT (nSelect)
	ENDFUNC

	FUNCTION OnExecuteQuery(cSQL, cAlias)
		LOCAL oException
		LOCAL i
		LOCAL nErrorCnt
		LOCAL lError
		LOCAL cErrorMsg
		LOCAL cSQLNew
		LOCAL nCnt
		LOCAL ARRAY aSQLInfo[1]
		
		LOCAL ARRAY aErrorList[1]
		LOCAL ARRAY aAliasList[1]

		nSelect = SELECT()
		
		lError = .F.
		

		oResultCollection = .NULL.
		
		IF ATC("INTO CURSOR", cSQL) == 0 
			cSQL = cSQL + " INTO CURSOR ResultCursor"
		ENDIF
		
		cSQLNew = ''
		nCnt = ALINES(aSQLInfo, cSQL, .T.)
		FOR i = 1 TO nCnt
			cSQLNew = cSQLNew + ' ' + aSQLInfo[i]
		ENDFOR

		IF EMPTY(THIS.DatabaseFile) OR THIS.OpenDBC()

			TRY
				* this will hold collection of aliases created by the query
				oResultCollection = CREATEOBJECT("Collection")

 				&cSQLNew
				oResultCollection.Add(ALIAS())
			CATCH TO oException
				THIS.SetError(oException.Message)
				lError = .T.

			FINALLY
			ENDTRY
			
			IF lError
				oResultCollection = .NULL.
				THIS.CloseDBC()
			ENDIF

			* THIS.CloseDBC()
		ENDIF
				
		SELECT (nSelect)
		
		
		RETURN oResultCollection
	ENDFUNC

	* Close all open tables in this session
	FUNCTION CloseAll()
		LOCAL i
		LOCAL nCnt
		LOCAL ARRAY aAliasList[1]
		
		nCnt = AUSED(aAliasList)
		FOR i = 1 TO nCnt
			USE IN (aAliasList[i, 2])
		ENDFOR
	ENDFUNC

	* Open the specified table in a new work area.
	* Upon leaving this method, the new work area
	* is selected
	FUNCTION OpenTable(cTableName, cAlias, lExclusive)
		LOCAL nSelect
		LOCAL oException
		LOCAL lSuccess
		LOCAL i
		LOCAL nCnt
		
		lSuccess = .F.

		nSelect = SELECT()

		cAlias = CHRTRAN(UPPER(EVL(cAlias, "TableCursor")), ' ', '_')
		cTableName = UPPER(cTableName)
		

		* determine if table is already open
		nCnt = AUSED(aTablesInUse)
		FOR i = 1 TO nCnt
			IF aTablesInUse[i, 1] == cAlias AND ;
			 (UPPER(DBF(aTablesInUse[i, 1])) == cTableName OR ;
			  (CURSORGETPROP("Database", aTablesInUse[i, 1]) == THIS.DatabaseFile AND !EMPTY(THIS.DatabaseFile)))
				IF !lExclusive OR ISEXCLUSIVE(cAlias)
					SELECT (cAlias)
					lSuccess = .T.
				ENDIF
			ENDIF
		ENDFOR

		IF !lSuccess
			SELECT 0
			
			IF EMPTY(THIS.DatabaseFile)
				* determine if table is part of a DBC
				TRY
					IF lExclusive
						USE (cTableName) ALIAS (cAlias) EXCLUSIVE
					ELSE
						USE (cTableName) ALIAS (cAlias) SHARED
					ENDIF
					THIS.DatabaseFile = CURSORGETPROP("Database")
				CATCH TO oException
					* ignore error - it'll be caught below
					* MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, DATAEXPLORER_LOC)
				ENDTRY
			ENDIF
			
			IF EMPTY(THIS.DatabaseFile) OR THIS.OpenDBC()
				* if table is part of a database, then
				* prepend the database name to the table name
				IF EMPTY(JUSTPATH(cTableName)) AND !EMPTY(THIS.DatabaseFile)
					cTableName = JUSTSTEM(THIS.DatabaseFile) + '!' + cTableName
				ENDIF
			
				TRY
					IF lExclusive
						USE (cTableName) ALIAS (cAlias) EXCLUSIVE
					ELSE
						USE (cTableName) ALIAS (cAlias) SHARED
					ENDIF
					lSuccess = .T.
				CATCH TO oException
					* MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, DATAEXPLORER_LOC)
					* SELECT (nSelect)
				ENDTRY
			ENDIF
		ENDIF
		
		IF !lSuccess
			SELECT (nSelect)
		ENDIF
		
		RETURN lSuccess
	ENDFUNC
	
	* -- Methods specific to this Data Management provider
	PROTECTED FUNCTION OpenDBC(cDatabase)
		LOCAL lFirstOpen
		LOCAL lSuccess
		LOCAL oException
		
		lSuccess = .F.
		
		lFirstOpen = !EMPTY(cDatabase)
		IF lFirstOpen
			IF EMPTY(JUSTEXT(cDatabase))
				cDatabase = FORCEEXT(cDatabase, "DBC")
			ENDIF
		ELSE
			cDatabase = THIS.DatabaseFile
		ENDIF

		
		TRY
			IF FILE(cDatabase)
				OPEN DATABASE (cDatabase) SHARED
				SET DATABASE TO (JUSTSTEM(cDatabase))
				
				IF lFirstOpen
					THIS.DatabaseFile = DBC()
				ENDIF
				
				lSuccess = .T.
			ENDIF
		CATCH TO oException
			MESSAGEBOX(oException.Message, MB_ICONEXCLAMATION, DATAEXPLORER_LOC)
			* ignore error -- we just know we couldn't get it open
		ENDTRY

		THIS.DatabaseName = THIS.DatabaseFile
	
		RETURN lSuccess
	ENDFUNC

	FUNCTION OnNewTable()
		LOCAL lSuccess

		lSuccess = .F.
		IF !EMPTY(THIS.DatabaseFile)
			IF THIS.OpenDBC()
				SET DATABASE TO (JUSTSTEM(THIS.DatabaseFile))
				lSuccess = .T.
			ENDIF
		ELSE
			lSuccess = .T.
		ENDIF
		IF lSuccess
			CREATE
		ENDIF

		THIS.CloseDBC()
	ENDFUNC

	FUNCTION OnDesignTable(cTableName, cOwner)
		LOCAL nSelect
		
		nSelect = SELECT()

		IF THIS.OpenTable(cTableName, JUSTSTEM(cTableName), .T.)
			MODIFY STRUCTURE
			THIS.CloseAll()
		ELSE
			IF THIS.OpenTable(cTableName, JUSTSTEM(cTableName), .F.)  && try again not exclusive
				MODIFY STRUCTURE
				THIS.CloseAll()
			ENDIF
		ENDIF
		SELECT (nSelect)
		
		THIS.CloseDBC()
	ENDFUNC

	FUNCTION OnNewView()
		LOCAL lSuccess

		lSuccess = .F.
		IF !EMPTY(THIS.DatabaseFile)
			IF THIS.OpenDBC()
				SET DATABASE TO (JUSTSTEM(THIS.DatabaseFile))
				lSuccess = .T.
			ENDIF
		ELSE
			lSuccess = .T.
		ENDIF
		
		IF lSuccess
			CREATE VIEW
		ENDIF

		THIS.CloseDBC()
	ENDFUNC

	FUNCTION OnDesignView(cViewName, cOwner)
		LOCAL nSelect
		
		nSelect = SELECT()

		IF THIS.OpenDBC()
			MODIFY VIEW (cViewName)
		ENDIF
		SELECT (nSelect)
		
		THIS.CloseDBC()
	ENDFUNC
	
	FUNCTION OnEditStoredProc(cProcName)
		* No way in VFP to edit a single stored proc
		LOCAL nSelect
		
		nSelect = SELECT()

		IF THIS.OpenDBC()
			MODIFY PROCEDURE
		ENDIF
		SELECT (nSelect)
		
		THIS.CloseDBC()
	ENDFUNC
	
	PROTECTED FUNCTION CloseDBC()
		THIS.CloseAll()

		CLOSE DATABASES
	ENDFUNC
	
	
ENDDEFINE


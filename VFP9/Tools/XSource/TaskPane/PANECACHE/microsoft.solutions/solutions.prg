*** Support classes for the Solutions pane
#define SOLUTIONADDIN_LOC 		"Solution Add-In"
#define ERROR_BADMANIFEST_LOC 	"Not a valid Solution Add-In manifest file."
#define TITLE_LOC 				"Results of Query"
#define TITLE2_LOC 				"Results of View"
#define ONESOLUTION_LOC			"1 solution found:"
#define MANYSOLUTIONS_LOC		"solutions found:"
#define NOSOLUTIONS_LOC			"No solutions were found that match your search string."
#define SUCCESS_LOC				"Solutions have been successfully updated!"
#define SOLUTIONS_ADDED_LOC		"Number of new solutions:"
#define SOLUTIONS_UPDATED_LOC	"Number of updated solutions:"
#define ERROR_CLEARADDINS_LOC	"Unable to clear Add-Ins due to the following error:"
#define CLEAR_CONFIRM_LOC		"Are you sure you want to clear all add-ins?"
#define ERROR_HOMEDIR_LOC		"The specified home directory for the sample is not valid."
#define REMOVE_CONFIRM_LOC		"Are you sure you want to remove this add-in?"
#define ERROR_OPENING_LOC		"Problem encountered opening the the TaskPaneSolution table:"

DEFINE CLASS Solutions AS Session
	PROCEDURE Init
		SET DELETED ON
	ENDPROC

	FUNCTION Handler(cAction, oParameters, oBrowser, oContent)
		LOCAL oAddIn
		LOCAL cType
		LOCAL cFilename
		LOCAL cMethod
		LOCAL cKey
		LOCAL cParent
		LOCAL cSearchString
		LOCAL lSuccess

		m.lSuccess = .T.		

		DO CASE
		CASE m.cAction == "addin"
			m.lSuccess = .F.
			TRY
				* oAddIn = NEWOBJECT("SolutionsAddIn", oContent.CacheDir + "solutions.prg")
				oAddIn = CREATEOBJECT("SolutionsAddIn")
				IF oAddIn.ProcessManifest(oContent.CacheDir)
					m.lSuccess = .T.
					MessageBox(SUCCESS_LOC + CHR(10) + CHR(10) + ;
					 SOLUTIONS_ADDED_LOC + " " + TRANSFORM(oAddIn.SolutionsAdded) + ;
					 IIF(oAddIn.SolutionsUpdated > 0, CHR(10) + SOLUTIONS_UPDATED_LOC + " " + TRANSFORM(oAddIn.SolutionsUpdated), ''), 64, SOLUTIONADDIN_LOC)
				ENDIF
			CATCH TO oException
				MessageBox(oException.Message, 48, SOLUTIONADDIN_LOC)
			ENDTRY

		CASE m.cAction == "clearaddins"
			m.lSuccess = .F.
			IF MESSAGEBOX(CLEAR_CONFIRM_LOC, 32 + 4 + 256, SOLUTIONADDIN_LOC) == 6
				TRY
					oAddIn = CREATEOBJECT("SolutionsAddIn")
					oAddIn.ClearAddIns(oContent.CacheDir)
					m.lSuccess = .T.
				CATCH TO oException
					MessageBox(oException.Message, 48, SOLUTIONADDIN_LOC)
				ENDTRY
			ENDIF

		CASE m.cAction == "removeaddin"
			m.cKey = oParameters.GetParam("id")
			m.cParent = oParameters.GetParam("parent")
			IF VARTYPE(m.cKey) == 'C' AND !EMPTY(m.cKey)
				IF LEFT(m.cKey, 5) == "msft_"
					m.cKey = SUBSTR(m.cKey, 6)
				ENDIF
				IF VARTYPE(m.cParent) <> 'C'
					m.cParentID = ''
				ENDIF
			
				m.lSuccess = .F.
				TRY
					oAddIn = CREATEOBJECT("SolutionsAddIn")
					m.lSuccess = oAddIn.RemoveAddIn(oContent.CacheDir, m.cKey, m.cParent)
				CATCH TO oException
					MessageBox(oException.Message, 48, SOLUTIONADDIN_LOC)
				ENDTRY
			ENDIF

		OTHERWISE
			m.cType     = oParameters.GetParam("type")
			m.cFilename = oParameters.GetParam("filename")
			m.cHomeDir  = oParameters.GetParam("homedir")

			DO CASE
			CASE m.cAction == "runsolution"
				THIS.RunSolution(m.cType, m.cFilename, m.cHomeDir)

			CASE m.cAction == "viewsolution"
				m.cMethod = oParameters.GetParam("method")
				THIS.ViewSolution(m.cType, m.cFilename, m.cHomeDir, m.cMethod)

			CASE m.cAction == "search"
				m.cSearchString = oParameters.GetParam("searchstring")
				THIS.SearchSolutions(m.cSearchString, oContent.CacheDir, oBrowser)

			CASE m.cAction == "reset"
				THIS.SearchSolutions('', oContent.CacheDir, oBrowser)

			ENDCASE
		ENDCASE

		RETURN m.lSuccess
	ENDFUNC

	* This function is used to generate an XML
	* string of the combined solution sources:
	* 	- Solution.dbf from the HOME(2) + "Samples\Solution" directory
	*	- TaskPaneSolution.dbf from the cache directory (for add-in solutions)
	FUNCTION GetXML(oContent)
		LOCAL oRec
		LOCAL cSolutionPath
		LOCAL oException
		LOCAL cXML

		CREATE CURSOR PaneSolution ( ;
		 Key C(25), ;
		 Parent C(25), ;
		 Vendor C(25), ;
		 SetName C(25), ;
		 Text C(254), ;
		 Image C(12), ;
		 File C(254), ;
		 Type C(1), ;
		 HomeDir M, ;
		 Method C(254), ;
		 Descript M, ;
		 VFPVer N(3, 0), ;
		 IsAddIn C(1);
		 )

		* grab the standard solutions and put into our cursor
		TRY
			IF FILE(HOME(2) + "Solution\Solution.dbf")
				USE (HOME(2) + "Solution\Solution.dbf") IN 0 SHARED AGAIN ALIAS SolutionStandard
				SELECT * FROM SolutionStandard ORDER BY Text INTO CURSOR TempCursor
				SCAN ALL 
					*****
					IF !("Samples" $ TempCursor.Path)
						m.cSolutionPath = HOME(2) + "Solution\" + ALLTRIM(TempCursor.Path)
					ELSE
						m.cSolutionPath = ALLTRIM(TempCursor.Path)
					ENDIF
					*****	
					SCATTER MEMO NAME oRec
					INSERT INTO PaneSolution FROM NAME oRec
				  
					REPLACE ;
					  File WITH ALLTRIM(oRec.File), ;
					  HomeDir WITH m.cSolutionPath, ;
					  Vendor WITH "Microsoft", ;
					  IsAddIn WITH "N" ;
					 IN PaneSolution
				ENDSCAN
			ENDIF
		CATCH TO oException
			MessageBox(oException.Message, 48, SOLUTIONADDIN_LOC)
		ENDTRY

		* grab third-party/added solutions and put into our cursor
		TRY
			IF FILE(ADDBS(m.oContent.CacheDir) + "TaskPaneSolution.dbf")
				USE (ADDBS(m.oContent.CacheDir) + "TaskPaneSolution.dbf") IN 0 SHARED AGAIN ALIAS SolutionAddIn

				SELECT * FROM SolutionAddIn WHERE Type <> 'X' ORDER BY Text INTO CURSOR TempCursor
				SCAN ALL
					SCATTER MEMO NAME oRec

					IF EMPTY(oRec.Parent)
						oRec.Parent = "0_"
					ENDIF
					IF EMPTY(oRec.Image)
						oRec.Image = "dot"
					ENDIF
					INSERT INTO PaneSolution FROM NAME oRec
					REPLACE IsAddIn WITH "Y" IN PaneSolution
				ENDSCAN
			ENDIF
		CATCH TO oException
			MessageBox(oException.Message, 48, SOLUTIONADDIN_LOC)
		ENDTRY

		TRY
			CURSORTOXML("PaneSolution", "cXML", 1, 8)
			m.cXML = oContent.XMLTransform(m.cXML, FILETOSTR(oContent.CacheDir + "solutionTransform.xsl"))
		CATCH TO oException
			MessageBox(oException.Message, 48, SOLUTIONADDIN_LOC)
			m.cXML = .NULL.
		ENDTRY

		RETURN m.cXML
	ENDFUNC
	

	* This function is used to generate an XML
	* string of the combined solution sources:
	* 	- Solution.dbf from the HOME(2) + "Samples\Solution" directory
	*	- TaskPaneSolution.dbf from the cache directory (for add-in solutions)
	FUNCTION GetAddInsXML(oContent)
		LOCAL oRec
		LOCAL oException
		LOCAL cXML

		CREATE CURSOR AddIn ( ;
		 Key C(25), ;
		 Vendor C(25), ;
		 SetName C(25), ;
		 Text C(254), ;
		 Image C(12), ;
		 Link M, ;
		 Descript M ;
		 )

		* grab third-party/added solutions and put into our cursor
		TRY
			IF FILE(ADDBS(m.oContent.CacheDir) + "TaskPaneSolution.dbf")
				USE (ADDBS(m.oContent.CacheDir) + "TaskPaneSolution.dbf") IN 0 SHARED AGAIN ALIAS SolutionAddIn

				SELECT * FROM SolutionAddIn WHERE TYPE == 'X' ORDER BY Text INTO CURSOR TempCursor
				SCAN ALL
					INSERT INTO AddIn ( ;
					  Key, ;
					  Vendor, ;
					  SetName, ;
					  Text, ;
					  Image, ;
					  Link, ;
					  Descript ;
					 ) VALUES ( ;
					  TempCursor.Key, ;
					  TempCursor.Vendor, ;
					  TempCursor.SetName, ;
					  TempCursor.Text, ;
					  TempCursor.Image, ;
					  TempCursor.HomeDir, ;
					  TempCursor.Descript ;
					 )
				ENDSCAN
			ENDIF
		CATCH TO oException
			MessageBox(oException.Message, 48, SOLUTIONADDIN_LOC)
		ENDTRY

		TRY
			CURSORTOXML("AddIn", "cXML", 1, 8)
		CATCH TO oException
			MessageBox(oException.Message, 48, SOLUTIONADDIN_LOC)
			m.cXML = .NULL.
		ENDTRY

		RETURN m.cXML
	ENDFUNC


	FUNCTION SearchSolutions(cSearchString, cCacheDir, oBrowser)
		LOCAL nResultsCnt
		LOCAL cXML
		LOCAL cXMLResults
		LOCAL oException
		LOCAL cExpr
		LOCAL lOrExpr
		LOCAL i
		LOCAL nCnt
		LOCAL cText
		LOCAL cSolutionPath
		LOCAL cRunLink

		oBrowser.document.all("SearchResults").style.display = "none"
		oBrowser.document.all("ResultsHeader").style.display = "none"

		CREATE CURSOR SolutionCursor( ;
		 Image M, ;
		 Title M, ;
		 Description M, ;
		 Type M, ;
		 RunLink M, ;
		 ViewLink M, ;
		 HomeDir M ;
		 )

		m.nResultsCnt = 0
		IF !EMPTY(m.cSearchString)
			* build the search expression
			m.cExpr = ''
			m.lOrExpr = .F.
			m.nCnt = GetWordCount(m.cSearchString)
			FOR m.i = 1 TO m.nCnt
				DO CASE
				CASE UPPER(GETWORDNUM(m.cSearchString, m.i)) == "OR"
					m.lOrExpr = .T.
				CASE UPPER(GETWORDNUM(m.cSearchString, m.i)) == "AND"
					m.lOrExpr = .F.
				OTHERWISE
					m.cExpr = m.cExpr + IIF(EMPTY(m.cExpr), '', IIF(m.lOrExpr, " OR ", " AND ")) + [ATC("] + GETWORDNUM(m.cSearchString, m.i) + [", m.cText) > 0]
					m.lOrExpr = .F.
				ENDCASE
			ENDFOR


			* process standard solutions
			TRY
				IF FILE(HOME(2) + "Solution\Solution.dbf")
					USE (HOME(2) + "Solution\Solution.dbf") IN 0 SHARED AGAIN ALIAS SolutionStandard
					SELECT * FROM SolutionStandard WHERE Type <> 'N' ORDER BY Text INTO CURSOR TempCursor
					SCAN ALL 
						IF !("Samples" $ TempCursor.Path)
							m.cSolutionPath = HOME(2) + "Solution\" + ALLTRIM(TempCursor.Path)
						ELSE
							m.cSolutionPath = ALLTRIM(TempCursor.Path)
						ENDIF

						m.cText = TempCursor.Text + CHR(10) + TempCursor.Descript
						IF EVALUATE(m.cExpr)
							* MODIFIED 11/18/2003 BY RMK - so solution doesn't get added twice if listed under 2 different categories
							m.cRunLink = [vfps:runsolution?filename=] + ALLTRIM(TempCursor.path) + '\' + ALLTRIM(TempCursor.file) + [&type=] + TempCursor.type + [&homedir=] + m.cSolutionPath
							SELECT SolutionCursor
							LOCATE FOR Title == ALLTRIM(TempCursor.Text) AND RunLink == m.cRunLink
							IF !FOUND()
								INSERT INTO SolutionCursor ( ;
								 Image, ;
								 Title, ;
								 Description, ;
								 Type, ;
								 RunLink, ;
								 ViewLink ;
								 ) VALUES ( ;
								 ALLTRIM(TempCursor.Image), ;
								 ALLTRIM(TempCursor.Text), ;
								 TempCursor.Descript, ;
								 TempCursor.Type, ;
								 m.cRunLink, ;
								 [vfps:viewsolution?filename=] + ALLTRIM(TempCursor.path) + '\' + ALLTRIM(TempCursor.file) + [&type=] + TempCursor.type + [&homedir=] + m.cSolutionPath ;
								)
							ENDIF
						ENDIF
					ENDSCAN
				ENDIF
			CATCH TO oException
				* no error message by design
			ENDTRY

			* process add-in solutions
			TRY
				IF FILE(m.cCacheDir + "TaskPaneSolution.dbf")
					USE (m.cCacheDir + "TaskPaneSolution.dbf") IN 0 SHARED AGAIN ALIAS SolutionAddIn

					SELECT * FROM SolutionAddIn WHERE Type <> 'N' ORDER BY Text INTO CURSOR TempCursor
					SCAN ALL
						m.cText = TempCursor.Text + CHR(10) + TempCursor.Descript
						IF EVALUATE(m.cExpr)
							INSERT INTO SolutionCursor ( ;
							 Image, ;
							 Title, ;
							 Description, ;
							 Type, ;
							 RunLink, ;
							 ViewLink ;
							 ) VALUES ( ;
							 ALLTRIM(TempCursor.Image), ;
							 ALLTRIM(TempCursor.Text), ;
							 TempCursor.Descript, ;
							 TempCursor.Type, ;
							 [vfps:runsolution?filename=] + ALLTRIM(TempCursor.file) + [&type=] + TempCursor.type + [&homedir=] + TempCursor.homedir, ;
							 [vfps:viewsolution?filename=] + ALLTRIM(TempCursor.file) + [&type=] + TempCursor.type + [&homedir=] + TempCursor.homedir ;
							)
						ENDIF
					ENDSCAN
				ENDIF
			CATCH TO oException
				* no error message by design
			ENDTRY
			

			IF USED("TempCursor")
				USE IN TempCursor
			ENDIF

			m.nResultsCnt = RECCOUNT("SolutionCursor") 
			IF m.nResultsCnt > 0
				CURSORTOXML("SolutionCursor", "cXML", 1, 8)
				IF m.nResultsCnt  = 1
					cXMLResults = "<resultsdata><results>" + ONESOLUTION_LOC + "</results></resultsdata>"
				ELSE
					cXMLResults = "<resultsdata><results>" + ALLTRIM(STR(nResultsCnt )) + " " + MANYSOLUTIONS_LOC + "</results></resultsdata>"
				ENDIF
				
				oBrowser.document.all("ResultsXML").loadXML(m.cXML)
				oBrowser.document.all("ResultsHeaderXML").loadXML(m.cXMLResults)
				oBrowser.document.all("ResultsHeader").style.display = ""
				oBrowser.document.all("SearchResults").style.display = ""
			ELSE
				* display no results found
				cXMLResults = "<resultsdata><results>" + NOSOLUTIONS_LOC + "</results></resultsdata>"
				oBrowser.document.all("ResultsHeaderXML").loadXML(m.cXMLResults)
				oBrowser.document.all("ResultsHeader").style.display = ""
			ENDIF
		ENDIF

		RETURN
	ENDFUNC


	FUNCTION RunSolution(cType, cFilename, cHomeDir)
		LOCAL cDirectory
		LOCAL cSavePath
		LOCAL oException
		LOCAL cViewName
		LOCAL oEnv

		m.cDirectory = SET("DEFAULT") + CURDIR()

		IF EMPTY(m.cHomeDir)
			m.cHomeDir = HOME(2) + "Solution"
		ELSE
			IF LEFT(m.cHomeDir, 1) == '(' AND RIGHT(m.cHomeDir, 1) == ')'
				TRY
				
					m.cHomeDir = EVALUATE(m.cHomeDir)

				CATCH
					m.cHomeDir = .NULL.
				ENDTRY
			ENDIF
		ENDIF
		
		IF ISNULL(m.cHomeDir) OR (!EMPTY(m.cHomeDir) AND !DIRECTORY(m.cHomeDir))
			MESSAGEBOX(ERROR_HOMEDIR_LOC, 48, SOLUTIONADDIN_LOC)
			RETURN
		ENDIF

		m.cSavePath = SET("PATH")
		IF m.cType <> 'V'
			THIS.AddToPath(JUSTPATH(m.cFilename))
		ENDIF
		m.cFilename = JUSTFNAME(m.cFilename)

		IF ATCC("FFC", SET("PATH")) == 0
			THIS.AddToPath(HOME() + "FFC\")
		ENDIF

		IF !EMPTY(m.cHomeDir)
			SET DEFAULT TO (m.cHomeDir)
			THIS.AddToPath(m.cHomeDir)
		ENDIF

		TRY
			DO CASE
			CASE m.cType == 'F'  && form
				DO FORM (m.cFilename)
				
			CASE m.cType == 'R'  && report
				REPORT FORM (m.cFilename) PREVIEW NOCONSOLE

			CASE m.cType == 'Q'  && query
				DEFINE WINDOW brow_wind FROM 1,1 TO 30, 100 TITLE TITLE_LOC + ' ' + UPPER(m.cFilename)+ ".QPR " FLOAT GROW MINIMIZE ZOOM CLOSE FONT "Arial",10
				ACTIVATE WINDOW brow_wind NOSHOW
				DO (m.cFilename + ".QPR")
				RELEASE WINDOW brow_wind

			CASE m.cType == 'V'  && view
				DEFINE WINDOW brow_wind FROM 1,1 TO 30, 100 TITLE TITLE2_LOC + ' ' + UPPER(m.cFilename) FLOAT GROW MINIMIZE ZOOM CLOSE FONT "Arial",10
				ACTIVATE WINDOW brow_wind NOSHOW

				IF AT('!', m.cFilename) > 0
					m.cViewName = SUBSTR(m.cFilename, AT('!', m.cFilename) + 1)
					m.cFilename = LEFT(m.cFilename, AT('!', m.cFilename) - 1)
				ELSE
					m.cViewName = m.cFilename
					m.cFilename = "testdata"
				ENDIF
				IF !DBUSED(m.cFilename)
					OPEN DATABASE (m.cFilename)
				ENDIF

				SET DATABASE TO (m.cFilename)
				SELECT 0
				TRY
					USE (m.cViewName) ALIAS _VIEW
				CATCH
				ENDTRY
				IF !EMPTY(ALIAS())
					* We had no error opening table
					BROWSE
					RELEASE WINDOW brow_wind
					USE
				ENDIF

			CASE m.cType == 'A'  && run application
				DO (m.cFilename)
				
			CASE m.cType == 'C'  && run code in a PRG
				DO (m.cFilename)	
				
			CASE m.cType == 'P'  && open project
				MODIFY PROJECT (m.cFilename) NOWAIT

			CASE m.cType == 'M'  && modify file
				MODIFY FILE (m.cFilename) NOEDIT NOWAIT

			CASE m.cType == 'S'  && shell to
				oEnv = NEWOBJECT("_shellexecute", HOME() + "FFC\_environ.vcx")
				oEnv.ShellExecute(m.cFilename)
				
			CASE m.cType == 'D'  && modify database
				MODIFY DATABASE (m.cFilename) NOWAIT

			ENDCASE
		CATCH TO oException
			MessageBox(oException.Message, 48, SOLUTIONADDIN_LOC)
		ENDTRY

*!*			IF EMPTY(m.cSavePath)
*!*				SET PATH TO
*!*			ELSE
*!*				SET PATH TO (m.cSavePath)
*!*			ENDIF

		IF !EMPTY(m.cDirectory)
			SET DEFAULT TO (m.cDirectory)
		ENDIF

		RETURN
	ENDFUNC

	FUNCTION ViewSolution(cType, cFilename, cHomeDir, cMethod)
		LOCAL cDirectory
		LOCAL cSavePath
		LOCAL oException
		LOCAL cViewName

		m.cDirectory = SET("DEFAULT") + CURDIR()

		m.cSavePath = SET("PATH")

		IF m.cType <> 'V'
			THIS.AddToPath(JUSTPATH(m.cFilename))
		ENDIF
		m.cFilename = JUSTFNAME(m.cFilename)
		
		IF ATCC("FFC", SET("PATH")) == 0
			THIS.AddToPath(HOME() + "FFC\")
		ENDIF
	
		IF EMPTY(m.cHomeDir)
			m.cHomeDir = HOME(2) + "Solution"
		ENDIF
		IF DIRECTORY(m.cHomeDir)
			SET DEFAULT TO (m.cHomeDir)
		ENDIF
	
		TRY
			DO CASE
			CASE m.cType == 'F'  && form
				IF EMPTY(m.cMethod)
					MODIFY FORM (m.cFilename) NOWAIT
				ELSE		
					MODIFY FORM (m.cFilename) NOWAIT METHOD &cMethod
				ENDIF

			CASE m.cType == 'R'  && report
				MODIFY REPORT (m.cFilename) NOWAIT

			CASE m.cType == 'Q'  && query
				MODIFY QUERY (m.cFilename) NOWAIT

			CASE m.cType == 'V'  && view
				IF AT('!', m.cFilename) > 0
					m.cViewName = SUBSTR(m.cFilename, AT('!', m.cFilename) + 1)
					m.cFilename = LEFT(m.cFilename, AT('!', m.cFilename) - 1)
				ELSE
					m.cViewName = m.cFilename
					m.cFilename = "testdata"
				ENDIF
				IF !DBUSED(m.cFilename)
					OPEN DATABASE (m.cFilename)
				ENDIF
				SET DATABASE TO (m.cFilename)
				MODIFY VIEW (m.cViewName) NOWAIT
			
			CASE m.cType == 'C'  && code in a PRG
				MODIFY COMMAND (m.cFilename) NOWAIT
				
			CASE (m.cType == 'A' OR  m.cType == 'P' OR  m.cType == 'M' OR  m.cType == 'S' OR m.cType == 'D') 
				This.RunSolution(m.cType, m.cFilename, m.cHomeDir)
				
			ENDCASE
		CATCH TO oException
			MessageBox(oException.Message, 48, SOLUTIONADDIN_LOC)
		ENDTRY

*!*			IF EMPTY(m.cSavePath)
*!*				SET PATH TO
*!*			ELSE
*!*				SET PATH TO (m.cSavePath)
*!*			ENDIF

		IF !EMPTY(m.cDirectory)
			SET DEFAULT TO (m.cDirectory)
		ENDIF
	ENDFUNC

	FUNCTION AddToPath(cPath)
		LOCAL nCnt
		LOCAL i
		LOCAL cFullPath
		LOCAL lFound
		LOCAL ARRAY aParsedPath[1]
		
		RETURN
		
		IF !EMPTY(m.cPath)
			m.lFound = .F.
			m.cFullPath = UPPER(FULLPATH(m.cPath))
			m.nCnt = ALINES(aParsedPath, SET("PATH"), .T., ';')
			FOR m.i = 1 TO m.nCnt
				IF UPPER(FULLPATH(aParsedPath[m.i])) == m.cFullPath
					m.lFound = .T.
					EXIT
				ENDIF
			ENDFOR
			
			IF !m.lFound
				SET PATH TO (SET("PATH") + ';' + m.cPath)
			ENDIF
		ENDIF		
	ENDFUNC

ENDDEFINE

* This class is used to process a solution add-in manifest file.
DEFINE CLASS SolutionsAddIn AS Session
	Vendor  = ''
	SetName = ''
	
	SolutionsAdded   = 0
	SolutionsUpdated = 0
	
	HomeDir = ''

	PROCEDURE Init
		SET DELETED ON
	ENDPROC

	* <cDirectory> = cache directory where TaskPaneSolution.dbf can be found or should be created
	* [cFilename] = name of manifest xml file; if not specified, user is prompted for it
	FUNCTION ProcessManifest(cDirectory, cFilename)
		LOCAL xmldoc
		LOCAL oXMLRoot
		LOCAL lSuccess
		LOCAL oException
		LOCAL lSuccess
		LOCAL cDir
		LOCAL ARRAY aFileList[1]

		THIS.SolutionsAdded   = 0
		THIS.SolutionsUpdated = 0

		IF VARTYPE(m.cFilename) <> 'C' OR !FILE(m.cFilename)
			m.cDir = SET("DIRECTORY")
			IF DIRECTORY(HOME(2) + "Solution")
				SET DIRECTORY TO (HOME(2) + "Solution")
			ENDIF
			m.cFilename = GETFILE("xml")
			SET DIRECTORY TO (m.cDir)

			IF EMPTY(m.cFilename)
				RETURN .F.
			ENDIF
		ENDIF
		
		THIS.HomeDir = JUSTPATH(m.cFilename)
		
		m.lSuccess = .T.
		IF FILE(HOME(2) + "Solution\Solution.dbf")
			TRY
				USE (HOME(2) + "Solution\Solution") IN 0 SHARED AGAIN ALIAS Solution
			CATCH
			ENDTRY
		ENDIF

		m.cDirectory = ADDBS(m.cDirectory)
		IF ADIR(aFileList, m.cDirectory + "TaskPaneSolution.dbf") > 0
			TRY
				USE (m.cDirectory + "TaskPaneSolution") IN 0 SHARED AGAIN ALIAS TaskPaneSolution
			CATCH TO oException
				m.lSuccess = .F.
				MESSAGEBOX(oException.Message, 48, SOLUTIONADDIN_LOC)
			ENDTRY
		ELSE
			TRY
				CREATE TABLE (m.cDirectory + "TaskPaneSolution") ( ;
				  Key C(25), ;
				  Parent C(25), ;
				  Vendor C(25), ;
				  SetName C(25), ;
				  Text C(65), ;
				  Image C(254), ;
				  File C(254), ;
				  Type C(1), ;
				  HomeDir M, ;
				  Method C(130), ;
				  Descript M, ;
				  VFPVer N(3, 0), ;
				  Internal L, ;
				  Modified T ;
				 )
			CATCH TO oException
				m.lSuccess = .F.
				MESSAGEBOX(oException.Message, 48, SOLUTIONADDIN_LOC)
			ENDTRY
		ENDIF

		IF m.lSuccess
			TRY
				m.xmldoc = CREATEOBJECT("Microsoft.XMLDOM")
			CATCH TO oException
				MESSAGEBOX(oException.Message, 48, SOLUTIONADDIN_LOC)
			ENDTRY

			IF VARTYPE(m.xmldoc) == 'O'
				m.xmldoc.async = .F.
				IF m.xmldoc.Load(m.cFilename)
					oXMLRoot = m.xmldoc.DocumentElement
					THIS.Vendor = THIS.GetXMLAttrib(oXMLRoot, "vendor")
					THIS.SetName = THIS.GetXMLAttrib(oXMLRoot, "name")
					
					IF EMPTY(THIS.Vendor) OR EMPTY(THIS.SetName)
						m.lSuccess = .F.
					ELSE
						THIS.ProcessSolutions(oXMLRoot)
						THIS.ProcessCategories(oXMLRoot)
					ENDIF
				ELSE
					m.lSuccess = .F.
				ENDIF

				IF !m.lSuccess
					MESSAGEBOX(ERROR_BADMANIFEST_LOC, 48, SOLUTIONADDIN_LOC)
				ENDIF
			ENDIF
		ENDIF
		
		RETURN m.lSuccess
	ENDFUNC


	FUNCTION ProcessCategories(oRoot, cCategoryID)
		LOCAL oCategoryList
		LOCAL nCategoryIndex
		LOCAL oCategory
		LOCAL cCategoryKey
		LOCAL cID
		LOCAL cText
		
		IF VARTYPE(m.cCategoryID) <> 'C'
			m.cCategoryID = ''
		ENDIF
		
		oCategoryList = oRoot.SelectNodes("category")
		FOR nCategoryIndex = 1 TO oCategoryList.length
			oCategory = oCategoryList.item(nCategoryIndex - 1)

			m.cID = THIS.GetXMLAttrib(oCategory, "key")
			IF EMPTY(m.cID)
				m.cID = SYS(2015)
			ENDIF
			
			IF EMPTY(m.cCategoryID)
				m.cCategoryID = "0_"
			ENDIF

			* create or update an existing category
			SELECT TaskPaneSolution
			SCATTER MEMO NAME oRec BLANK
			oRec.Key      = PADR(m.cID, LEN(TaskPaneSolution.Key))
			oRec.Parent   = PADR(m.cCategoryID, LEN(TaskPaneSolution.Parent))
			oRec.Vendor   = THIS.Vendor
			oRec.SetName  = THIS.SetName
			oRec.Text     = THIS.GetXMLValue(oCategory, "text")
			oRec.Type     = 'N'
			oRec.Image    = THIS.GetXMLValue(oCategory, "image")
			oRec.File     = ''
			oRec.HomeDir  = ''
			oRec.Method   = ''
			oRec.Descript = ''
			oRec.Modified = DATETIME()
			oRec.Internal = .F.

			LOCATE FOR Key == oRec.Key AND Parent == oRec.Parent
			IF FOUND()
				GATHER MEMO NAME oRec
			ELSE
				INSERT INTO TaskPaneSolution FROM NAME oRec
			ENDIF

			THIS.ProcessSolutions(oCategory, m.cID)
			THIS.ProcessCategories(oCategory, m.cID)
			
		ENDFOR
	ENDFUNC


	FUNCTION ProcessSolutions(oRoot, cCategoryID)
		LOCAL cText
		LOCAL oSolutionList
		LOCAL nSolutionIndex
		LOCAL oSolution
		LOCAL cID
		LOCAL oRec
		LOCAL lFoundCategory

		IF VARTYPE(m.cCategoryID) <> 'C' OR EMPTY(m.cCategoryID)
			m.cCategoryID = ''
		ENDIF

		oSolutionList = oRoot.SelectNodes("solution")
		FOR nSolutionIndex = 1 TO oSolutionList.length
			oSolution = oSolutionList.item(nSolutionIndex - 1)

			IF EMPTY(m.cCategoryID)
				m.cCategoryID = THIS.GetXMLAttrib(oSolution, "parent")
			ENDIF
			
			* make sure the category exists
			SELECT TaskPaneSolution
			LOCATE FOR Key == PADR(m.cCategoryID, LEN(TaskPaneSolution.Key))
			m.lFoundCategory = FOUND()
			IF !m.lFoundCategory AND USED("Solution")
				SELECT Solution
				LOCATE FOR Key == PADR(m.cCategoryID, LEN(Solution.Key))
				m.lFoundCategory = FOUND()
			ENDIF
			
			IF m.lFoundCategory
				m.cID = THIS.GetXMLAttrib(oSolution, "key")
				IF EMPTY(m.cID)
					m.cID = SYS(2015)
				ENDIF

				* create or update existing solution
				SELECT TaskPaneSolution
				SCATTER MEMO NAME oRec BLANK
				oRec.Key      = PADR(m.cID, LEN(TaskPaneSolution.Key))
				oRec.Parent   = PADR(m.cCategoryID, LEN(TaskPaneSolution.Parent))
				oRec.Vendor   = THIS.Vendor
				oRec.SetName  = THIS.SetName
				oRec.Text     = THIS.GetXMLValue(oSolution, "text")
				oRec.Type     = THIS.GetXMLValue(oSolution, "type")
				oRec.Image    = THIS.GetXMLValue(oSolution, "image")
				oRec.File     = THIS.GetXMLValue(oSolution, "file")
				oRec.HomeDir  = THIS.GetXMLValue(oSolution, "homedir")
				oRec.Method   = THIS.GetXMLValue(oSolution, "method")
				oRec.Descript = THIS.GetXMLValue(oSolution, "description")
				oRec.VFPVer   = VAL(THIS.GetXMLValue(oSolution, "version"))
				oRec.Modified = DATETIME()
				oRec.Internal = .F.

				IF EMPTY(oRec.HomeDir)
					oRec.HomeDir = THIS.HomeDir
				ENDIF

				LOCATE FOR Key == oRec.Key AND Parent == oRec.Parent
				IF FOUND()
					GATHER MEMO NAME oRec
					THIS.SolutionsUpdated = THIS.SolutionsUpdated + 1

				ELSE
					INSERT INTO TaskPaneSolution FROM NAME oRec
					THIS.SolutionsAdded = THIS.SolutionsAdded + 1
				ENDIF
			ENDIF
		ENDFOR
	ENDFUNC


	FUNCTION GetXMLAttrib(oNode, cAttrib)
		LOCAL cValue
		
		TRY
			m.cValue = oNode.Attributes.GetNamedItem(m.cAttrib).Text
		CATCH
			m.cValue = ''
		ENDTRY
		
		RETURN m.cValue
	ENDFUNC

	FUNCTION GetXMLValue(oNode, cElement)
		LOCAL cValue

		TRY
			m.cValue = oNode.selectSingleNode(m.cElement).text
		CATCH
			m.cValue = ''
		ENDTRY
		
		RETURN m.cValue
		
	ENDFUNC


	* Remove a single add-in
	FUNCTION RemoveAddIn(cDirectory, cKey, cParent)
		LOCAL oException
		LOCAL nCnt
		LOCAL lSuccess

		m.lSuccess = .F.
		TRY
			USE (m.cDirectory + "TaskPaneSolution") IN 0 SHARED AGAIN ALIAS TaskPaneSolution
		CATCH TO oException
			MESSAGEBOX(ERROR_OPENING_LOC + CHR(10) + CHR(10) + m.oException.Message, MB_ICONEXCLAMATION, SOLUTIONADD_LOC)
		ENDTRY

		IF USED("TaskPaneSolution")
			m.cKey    = PADR(m.cKey, LEN(TaskPaneSolution.Key))
			m.cParent = PADR(m.cParent, LEN(TaskPaneSolution.Parent))

			SELECT TaskPaneSolution
			LOCATE FOR Key == m.cKey AND Parent == m.cParent AND Type <> 'N'
			IF FOUND()
				IF MESSAGEBOX(REMOVE_CONFIRM_LOC + CHR(10) + CHR(10) + RTRIM(TaskPaneSolution.Text), 32 + 4 + 256, SOLUTIONADDIN_LOC) == 6
					DELETE IN TaskPaneSolution
					
					* if this is the last solution in the category, then remove the category as well
					COUNT FOR Parent == m.cParent AND Type <> 'N' TO m.nCnt
					IF m.nCnt == 0
						LOCATE FOR Key == m.cParent AND Type == 'N'
						IF FOUND()
							DELETE IN TaskPaneSolution
						ENDIF
					ENDIF
						
					m.lSuccess = .T.
				ENDIF
			ENDIF
			
			IF USED("TaskPaneSolution")
				USE IN TaskPaneSolution
			ENDIF
		ENDIF
		
		RETURN m.lSuccess
	ENDFUNC


	* Clear out all add-ins
	FUNCTION ClearAddIns(m.cDirectory)
		LOCAL oException
		LOCAL cBackupTable
		LOCAL nFileCnt
		LOCAL cSafety

		TRY
			USE (m.cDirectory + "TaskPaneSolution") IN 0 EXCLUSIVE ALIAS TaskPaneSolution
		CATCH TO oException
			m.lSuccess = .F.
			MESSAGEBOX(ERROR_CLEARADDINS_LOC + CHR(10) + CHR(10) + m.oException.Message, MB_ICONEXCLAMATION, SOLUTIONADDIN_LOC)
		ENDTRY

		IF USED("TaskPaneSolution")		
			m.nFileCnt = 0
			m.cBackupTable = m.cDirectory + JUSTSTEM("TaskPaneSolution") + "Backup.dbf"
			DO WHILE FILE(m.cBackupTable)
				m.nFileCnt = m.nFileCnt + 1
				m.cBackupTable = m.cDirectory + JUSTSTEM("TaskPaneSolution") + "Backup_" + TRANSFORM(m.nFileCnt) + ".dbf"
			ENDDO

			m.cSafety = SET("SAFETY")
			SET SAFETY OFF
			TRY
				SELECT TaskPaneSolution
				COPY TO (m.cBackupTable) WITH PRODUCTION

				SELECT TaskPaneSolution
				ZAP IN TaskPaneSolution
				APPEND FROM (m.cBackupTable) FOR Internal

			CATCH TO oException
				MESSAGEBOX(ERROR_CLEARADDINS_LOC + CHR(10) + CHR(10) + m.oException.Message, MB_ICONEXCLAMATION, SOLUTIONADDIN_LOC)
			ENDTRY

			SET SAFETY &cSafety
			
			IF USED("TaskPaneSolution")
				USE IN TaskPaneSolution
			ENDIF
		ENDIF
		
	ENDFUNC
ENDDEFINE


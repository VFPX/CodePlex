* -- This updates TaskPaneDefault.dbf with
* -- the contents of PaneCache as it exists
* -- beneath the TaskPane project
#include "foxpane.h"

o = CREATEOBJECT("CPublish")
o.PublishAll()


DEFINE CLASS CPublish AS Session
	PROCEDURE Init
		SET DELETED ON
	ENDPROC

	FUNCTION PublishAll(cRoot)
		LOCAL cDirectory
		LOCAL nSelect
		LOCAL i
		LOCAL nCnt
		LOCAL ARRAY aDirList[1]
		
		IF VARTYPE(m.cRoot) <> 'C'
			m.cRoot = ''
		ENDIF
		m.cRoot = ADDBS(m.cRoot) 
		
		m.nSelect = SELECT()

		IF USED("PaneContentDefault")
			USE IN PaneContentDefault
		ENDIF
		USE (m.cRoot+"PaneContentDefault") IN 0 EXCLUSIVE

		SELECT PaneContentDefault
		DELETE ALL FOR InfoType == INFOTYPE_FILE IN PaneContentDefault
		
		m.cDirectory = m.cRoot + "PaneCache"

		* process subdirectories
		THIS.PublishFiles(m.cDirectory)
		m.nCnt = ADIR(aDirList, ADDBS(m.cDirectory) + "*.*", 'D', 1)
		FOR m.i = 1 TO m.nCnt
			IF 'D' $ aDirList[m.i, 5] AND !INLIST(aDirList[m.i, 1], '.', "..")
				THIS.PublishFiles(ADDBS(m.cDirectory) + aDirList[m.i, 1], LOWER(aDirList[m.i, 1]))
			ENDIF
		ENDFOR

		REPLACE ALL ;
		  CacheTime WITH {}, ;
		  Modified WITH DATETIME(), ;
		  DebugMode WITH .F., ;
		  User WITH '', ;
		  OptionData WITH '' ;
		 IN PaneContentDefault
		PACK IN PaneContentDefault


		USE IN PaneContentDefault

		SELECT (m.nSelect)

		RETURN
	ENDFUNC

	FUNCTION PublishFiles(cDirectory, cUniqueID)
		LOCAL nSelect
		LOCAL cFilename
		LOCAL cExt
		LOCAL i
		LOCAL nCnt
		
		IF VARTYPE(m.cUniqueID) <> 'C'
			m.cUniqueID = ''
		ENDIF

		SELECT PaneContentDefault
		m.cUniqueID = PADR(m.cUniqueID, LEN(PaneContentDefault.TaskPaneID))

		m.cDirectory = ADDBS(m.cDirectory)
		
		m.nCnt = ADIR(aFileList, m.cDirectory + "*.*")
		FOR m.i = 1 TO m.nCnt
			m.cFilename = LOWER(aFileList[m.i, 1])
			m.cExt = JUSTEXT(m.cFilename)
			IF !(m.cFilename == "pane.htm") AND !(m.cFileName == "pane.xml") AND !INLIST(m.cExt, "bak", "tbk", "tmp", "scc", "fxp") AND !(LEFT(m.cFilename, 6) == "cache.")
				SELECT PaneContentDefault
				LOCATE FOR TaskPaneID == m.cUniqueID AND InfoType == INFOTYPE_FILE AND RTRIM(Content) == m.cFilename
				IF !FOUND()
					INSERT INTO PaneContentDefault ( ;
					  UniqueID, ;
					  InfoType, ;
					  TaskPaneID, ;
					  Content, ;
					  LocalData, ;
					  Modified, ;
					  DebugMode, ;
					  Inactive ;
					 ) VALUES ( ;
					  "microsoft." + SYS(2015), ;
					  INFOTYPE_FILE, ;
					  m.cUniqueID, ;
					  m.cFilename, ;
					  .T., ;
					  DATETIME(), ;
					  .F., ;
					  .F. ;
					 )
				ENDIF
				APPEND MEMO filedata FROM (m.cDirectory + m.cFilename) OVERWRITE
				REPLACE Modified WITH DATETIME()
			ENDIF
		ENDFOR

	ENDFUNC
ENDDEFINE
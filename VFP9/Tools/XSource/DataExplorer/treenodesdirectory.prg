* <summary>
*  Nodes used by Directory view in Data Explorer.
*  This is primarily used as a sample so that
*  we can demonstrate how to program the tree view.
* </summary>
#include "foxpro.h"
#include "dataexplorer.h"

DEFINE CLASS FileSystemNode AS INode OF TreeNodes.prg
	ImageKey = "microsoft.imagefolder"
	SaveNode = .T.

	DirName  = ''
	
	PROCEDURE OnInit()
		DODEFAULT()
		
		THIS.CreateOption("directory", '')
	ENDPROC

	FUNCTION NodeText_Access
		IF EMPTY(THIS.NodeText)
			RETURN THIS.GetOption("directory") + THIS.DirName
		ENDIF
		
		RETURN THIS.NodeText
	ENDFUNC

	FUNCTION OnFirstConnect()
		cDir = GETDIR(THIS.GetOption("directory"))
		IF !EMPTY(cDir)
			THIS.SetOption("directory", cDir)
		ENDIF

		RETURN !EMPTY(cDir)
	ENDFUNC

	* put in each subdirectory and file
	FUNCTION OnPopulate()
		LOCAL i
		LOCAL nCnt
		LOCAL oChildNode
		LOCAL cDirectory
		LOCAL aDirList[1]
		
		lVerbose = THIS.GetOption("verbose", .F.)

		cDirectory = ADDBS(THIS.GetOption("directory")) + ADDBS(THIS.DirName)
		nCnt = ADIR(aDirList, cDirectory + "*.*", "D", 1)
		FOR i = 1 TO nCnt
			IF !(aDirList[i, 1] == '.' OR aDirList[i, 1] == "..") AND 'D' $ aDirList[i, 5]
				oChildNode = CREATEOBJECT("DirectoryNode")
				oChildNode.DirName = cDirectory + aDirList[i, 1]
				THIS.AddNode(oChildNode)
			ENDIF
		ENDFOR

		FOR i = 1 TO nCnt
			IF !(aDirList[i, 1] == '.' OR aDirList[i, 1] == "..") AND !('D' $ aDirList[i, 5])
				oChildNode = CREATEOBJECT("FileNode")
				oChildNode.Filename= cDirectory + aDirList[i, 1]
				oChildNode.Verbose = lVerbose
				THIS.AddNode(oChildNode)
			ENDIF
		ENDFOR

	ENDFUNC

ENDDEFINE

DEFINE CLASS DirectoryNode AS FileSystemNode
	ImageKey = "microsoft.imagefolder"
	SaveNode = .F.

ENDDEFINE

DEFINE CLASS FileNode AS FileSystemNode
	ImageKey = "microsoft.imagefile"
	SaveNode = .F.
	EndNode  = .T.

	Filename = ''
	Verbose = .F.

	FUNCTION NodeText_Access
		IF THIS.Verbose
			RETURN THIS.Filename
		ELSE
			RETURN JUSTFNAME(THIS.Filename)
		ENDIF
	ENDFUNC
	
ENDDEFINE

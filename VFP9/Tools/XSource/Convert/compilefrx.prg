*- CompileFrx.PRG
*-
*- Copyright Microsoft Corporation 1996
*-
*- Simple PRG to compile the code in the DataEnvironment record, as there is no 
*-	"COMPILE REPORT" command
*- Take code from TAG field of DataEnvironment record, and copy to a .PRG file.
*- Compile it as an FXP, then append it into the TAG2 field
*-

LOCAL cTmpFile, cFrxFile, lHadError
PRIVATE cOldTalk, cOldSafe, cOldError, iSelect

#DEFINE N_BUFFSZ			1024				&& amount to read at one time from compiled FRX code
#DEFINE C_SELECTFRX_LOC		"Select a file:"
#DEFINE C_ERRMSG			"An error occurred. Compilation cancelled."
#DEFINE N_FRX_DATAENV		25

cOldSafe = SET("SAFE")
cOldTalk = SET("TALK")
cOldError = ON("ERROR")

iSelect = SELECT()

SET TALK OFF
SET SAFE OFF
SELECT 0

ON ERROR DO ErrorHandler

*- get the report file
cFrxFile = GETFILE("FRX;LBX", C_SELECTFRX_LOC)
IF EMPTY(cFrxFile)
	RETURN
ENDIF

USE (cFrxFile)

cTmpFile = SYS(3) + ".PRG"
DO WHILE FILE(cTmpFile)
	cTmpFile = SYS(3) + ".PRG"
ENDDO

SCAN FOR objtype = N_FRX_DATAENV AND !EMPTY(tag)
	COPY MEMO tag TO (cTmpFile)
	COMPILE (cTmpFile)
	IF !_mac
		APPEND MEMO tag2 FROM (FORCEEXT(cTmpFile,"FXP"))
	ELSE
		LOCAL iFH, iBuffer
		iFH = FOPEN(FORCEEXT(cTmpFile,"FXP"))
		IF iFH # -1
			DO WHILE !FEOF(iFH)
				iBuffer = FREAD(iFH, N_BUFFSZ)
				REPLACE tag2 WITH iBuffer ADDITIVE
			ENDDO
			=FCLOSE(iFH)
		ELSE
			*- some kind of error
		ENDIF
	ENDIF
	ERASE (cTmpFile)
	ERASE (FORCEEXT(cTmpFile,"FXP"))
ENDSCAN
USE

=PrgClose()

RETURN



*****************************************************************************
PROCEDURE ErrorHandler
*****************************************************************************
	=MESSAGEBOX(C_ERRMSG)
	USE
	=PrgClose()
ENDPROC

*****************************************************************************
FUNCTION PrgClose
*****************************************************************************
	SELECT (iSelect)
	SET TALK &cOldTalk
	SET SAFE &cOldSafe
	ON ERROR &cOldError
	CANCEL
ENDFUNC

*****************************************************************************
FUNCTION forceext
*****************************************************************************
*)
*) FORCEEXT - Force filename to have a particular extension.
*)
PARAMETERS m.filname,m.ext
PRIVATE m.ext
IF SUBSTR(m.ext,1,1) = "."
   m.ext = SUBSTR(m.ext,2,3)
ENDIF

m.pname = justpath(m.filname)
m.filname = justfname(UPPER(ALLTRIM(m.filname)))
IF AT('.',m.filname) > 0
   m.filname = SUBSTR(m.filname,1,AT('.',m.filname)-1) + '.' + m.ext
ELSE
   m.filname = m.filname + '.' + m.ext
ENDIF
RETURN addbs(m.pname) + m.filname


*****************************************************************************
FUNCTION justpath
*****************************************************************************
*)
*) JUSTPATH - Returns just the pathname.
*)
PARAMETERS m.filname
m.filname = ALLTRIM(UPPER(m.filname))
*- use platform specific path (10/28/95 jd)
LOCAL clocalfname, cdirsep
clocalfname = SYS(2027,m.filname)
cdirsep = IIF(_mac,':','\')
IF m.cdirsep $ m.clocalfname 
   m.clocalfname = SUBSTR(m.clocalfname,1,RAT(m.cdirsep,m.clocalfname ))
   IF RIGHT(m.filname,1) = m.cdirsep AND LEN(m.filname) > 1 ;
            AND SUBSTR(m.clocalfname,LEN(m.clocalfname)-1,1) <> ':'
         clocalfname= SUBSTR(m.clocalfname,1,LEN(m.clocalfname)-1)
   ENDIF
   RETURN m.clocalfname
ELSE
   RETURN ''
ENDIF

*****************************************************************************
FUNCTION justfname
*****************************************************************************
*)
*) JUSTFNAME - Return just the filename (i.e., no path) from "filname"
*)
PARAMETERS m.filname

*- use platform specific path (10/28/95 jd)
LOCAL clocalfname, cdirsep
clocalfname = SYS(2027,m.filname)
cdirsep = IIF(_mac,':','\')
IF RAT(m.cdirsep ,m.clocalfname) > 0
   m.clocalfname = SUBSTR(m.clocalfname,RAT(m.cdirsep,m.clocalfname)+1,255)
ENDIF
IF AT(':',m.clocalfname) > 0
   m.clocalfname = SUBSTR(m.clocalfname,AT(':',m.clocalfname)+1,255)
ENDIF
RETURN ALLTRIM(m.clocalfname)

*****************************************************************************
FUNCTION addbs
*****************************************************************************
*)
*) ADDBS - Add a backslash unless there is one already there.
*)
PARAMETER m.pathname
PRIVATE m.separator
m.separator = IIF(_MAC,":","\")
m.pathname = ALLTRIM(UPPER(m.pathname))
IF !(RIGHT(m.pathname,1) $ '\:') AND !EMPTY(m.pathname)
   m.pathname = m.pathname + m.separator
ENDIF
RETURN m.pathname


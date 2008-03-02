* COVERAGE WRAPPER PRG

#INCLUDE COVERAGE.H

LPARAMETERS tcFile, tlUnattended, tcAddIn

LOCAL  oTemp,cAlias, lSuccess, lSetTalkBackOn, cAppFile, ;
      cLibs, cUnattendedMessage, ;
      cSavedTarget, cSavedSkippedFiles, cSavedStackXML

IF (SET("TALK") = "ON")
   SET TALK OFF
   lSetTalkBackOn = .T.
ENDIF

#IF COV_COMPILED_IN_VFP5
   cLibs = SET("CLASSLIB")
   cAlias = "C_"+SYS(2015)
#ENDIF   
 
cAppFile = FindAppFile()

#IF COV_COMPILED_IN_VFP5
   IF FILE(COV_CLASS_CLASSLIB) OR EMPTY(cAppFile)
      SET CLASSLIB TO (COV_CLASS_CLASSLIB) ALIAS (cAlias) ADDITIVE
   ELSE
      SET CLASSLIB TO (COV_CLASS_CLASSLIB) IN (cAppFile) ALIAS (cAlias) ADDITIVE
   ENDIF
   oTemp = CREATEOBJECT(cAlias+"."+COV_CLASS_TO_INSTANCE, ;
                        tcFile, tlUnattended, tcAddIn)
#ELSE
   oTemp = NEWOBJECT(COV_CLASS_TO_INSTANCE,COV_CLASS_CLASSLIB, cAppFile, ;
                     tcFile, tlUnattended, tcAddIn)
#ENDIF
                                             
* NB: the actual public reference variable
* is not the responsibility of the wrapper program;
* it's set up (and released when necessary)
* by the object itself.
* Absolutely nothing in this 
* wrapper program is required.
* An APP or EXE of some sort *is*
* required, to make sure that the engine
* can find its bits and pieces as necessary
* when it's ready to instantiate them,
* but it will take care of making sure
* these bits and pieces are available itself.

lSuccess = (TYPE("oTemp.BaseClass") = "C")

IF lSuccess
   IF tlUnattended
      * oTemp.cSavedTargetDBF will have the
      * marked code results file,
      * and another table with the same
      * name + numeric extension as your
      * passed coverage log (in the same
      * directory as the log)
      * will show you what records were skipped
      * if some source files were not found:
      cSavedTarget = oTemp.cSavedTargetDBF
      cSavedSkippedFiles = oTemp.cSavedSkipFiles
      cSavedStackXML = oTemp.cSavedStackXML
      lSuccess = (NOT EMPTY(cSavedTarget))
      IF lSuccess
         cUnattendedMessage = COV_SAVEDTARGET_AS_LOC+C_CR+ ;
            cSavedTarget+"." 
         IF NOT EMPTY(cSavedSkippedFiles)
            cUnattendedMessage = cUnattendedMessage + ;
                                 C_DOUBLE_CR+;
                                 COV_SAVEDSKIPFILES_AS_LOC+C_CR+;
                                 "("+cSavedSkippedFiles+")."
         ENDIF
         IF NOT EMPTY(cSavedStackXML)
            cUnattendedMessage = cUnattendedMessage + ;
                                 C_DOUBLE_CR+;
                                 COV_SAVEDSTACKXML_AS_LOC+C_CR+;
                                 cSavedStackXML+"."
         ENDIF
         MESSAGEBOX(cUnattendedMessage, COV_APPLICATION_NAME_LOC)
      ENDIF
      oTemp.Release()
   ELSE
      oTemp.Show()
   ENDIF
ELSE
   CLEAR CLASS COV_CLASS_TO_INSTANCE
ENDIF

#IF COV_COMPILED_IN_VFP5
   SET CLASSLIB TO &cLibs
#ENDIF   

IF lSetTalkBackOn
   SET TALK ON
ENDIF

IF NOT EMPTY(cSavedStackXML)
   DECLARE long ShellExecuteA IN SHELL32 ;
           long, string, string, string, string, long
   ShellExecuteA( 0, "open", cSavedStackXML, "","", 1 )
ENDIF

IF NOT EMPTY(cSavedSkippedFiles)
   SELECT 0
   USE (cSavedSkippedFiles)
   BROWSE NOWAIT WIDTH 30
   MOVE WINDOW (WONTOP()) TO 0,0
ENDIF

IF NOT EMPTY(cSavedTarget)
   SELECT 0
   USE (cSavedTarget)
   BROWSE NOWAIT WIDTH 30
   MOVE WINDOW (WONTOP()) TO 5,5   
ENDIF

RETURN lSuccess


PROCEDURE FindAppFile
LOCAL cFileName, cSys16, iLevel
* get the name of the module (app or exe) that
* owns this particular object, for SET CLASSLIB ... IN...
* or NEWOBJECT() filename parameter

* Finding this appfilename is most significant
* in cases where this wrapper program
* and its app get embedded in a temporary
* program, such as when you highlight several
* lines of code and interactively Execute them...

cFileName = ""
FOR iLevel = 256 TO 1 STEP -1 && 256 = twice the nested programs currently allowed!
  cSys16 = UPPER(SYS(16,iLevel))
  IF INLIST(RIGHT(cSys16,3),"APP","EXE","VFD","DLL")
     cFileName = cSys16
     EXIT
  ENDIF
ENDFOR

IF "PROCEDURE" $ cFileName
   cFileName = SUBSTR(cFileName,11)
   cFileName = SUBSTR(cFileName,AT(" ",cFileName)+1)
ENDIF

RETURN cFileName


* COM_Attrib flag settings for Type Library attributes support
*-------------------------------------------------------------------
*!*  #DEFINE COMATTRIB_RESTRICTED    0x1      && The property/method should not be accessible from macro languages.
*!*  #DEFINE COMATTRIB_HIDDEN        0x40     && The property/method should not be displayed to the user, although it exists and is bindable.
*!*  #DEFINE COMATTRIB_NONBROWSABLE  0x400    && The property/method appears in an object browser, but not in a properties browser.
#DEFINE COMATTRIB_READONLY      0x100000 && The property is read-only (applies only to Properties).
*!*  #DEFINE COMATTRIB_WRITEONLY     0x200000 && The property is write-only (applies only to Properties).
*!*  #DEFINE COMATTRIB_READWRITE     0x0      && .F.

#DEFINE CRLF CHR(13) + CHR(10)

DEFINE CLASS VfpProjectBuilder AS SESSION OLEPUBLIC

  PROTECTED oVfp AS VisualFoxpro.APPLICATION
  oVfp = ""

  PROTECTED cProject AS STRING
  cProject = ""

  cErrorMessage = ""

  DIMENSION cErrorMessage_COMATTRIB[4]
  cErrorMessage_COMATTRIB[1] = COMATTRIB_READONLY
  cErrorMessage_COMATTRIB[2] = "Build Errors"
  cErrorMessage_COMATTRIB[3] = "cErrorMessage"
  cErrorMessage_COMATTRIB[4] = "String"

  cWarningMessage = ""

  DIMENSION cWarningMessage_COMATTRIB[4]
  cWarningMessage_COMATTRIB[1] = COMATTRIB_READONLY
  cWarningMessage_COMATTRIB[2] = "Build Warnings"
  cWarningMessage_COMATTRIB[3] = "cWarningMessage"
  cWarningMessage_COMATTRIB[4] = "String"


  FUNCTION BuildProject(cProjectFile AS STRING, cOutputName AS STRING, nBuildAction AS INTEGER, cVsProjectFile AS STRING, cBuildTime AS STRING, cBuildPath AS STRING) AS Boolean

    LOCAL cProjectPath AS STRING, ;
      cOutputPath AS STRING, ;
      lReturn AS Boolean, ;
      lKilled AS Boolean, ;
      cMissingFiles AS STRING, ;
      cFile AS STRING

    cProjectPath  = JUSTPATH(m.cVSProjectFile) + "\"
    THIS.cProject      = m.cProjectPath + m.cProjectFile
    cOutputPath   = ALLTRIM(m.cBuildPath)
    lReturn       = .T.
    lKilled       = .F.
    cMissingFiles = ""

    * First we test to see if the project file exists
    *------------------------------------------------
    IF NOT FILE(THIS.cProject)

      THIS.cErrorMessage = "Project " + THIS.cProject + " does not exist"

      RETURN .F.

    ENDIF

    * Next we make sure it isn't locked by another user
    *--------------------------------------------------
    nHandle = FOPEN(THIS.cProject, 12)

    FCLOSE(m.nHandle)

    IF m.nHandle < 0

      THIS.cErrorMessage = "Project " + THIS.cProject + " is in use"

      RETURN .F.

    ENDIF

    * Check the project to see if all the files in the project exist
    *---------------------------------------------------------------
    USE (THIS.cProject) IN 0 ALIAS MyProject

    SELECT MyProject

    IF EMPTY(MyProject.NAME) OR EMPTY(MyProject.HOMEDIR)

      REPLACE MyProject.NAME WITH m.cProjectFile + CHR(0), ;
        MyProject.HOMEDIR WITH m.cProjectPath + CHR(0)

    ENDIF

    CD (m.cProjectPath)    && Most paths are relative (ex. "..\..\test.prg")

    * Delete records have been removed.  This will still cause
    * problems when the project hasn't been rebuilt in a long time.
    *--------------------------------------------------------------
    SCAN FOR NOT DELETED()

      cFile = ALLTRIM(CHRTRAN(MyProject.NAME, CHR(0), ""))

      IF NOT FILE(m.cFile)

        cMissingFiles = IIF(EMPTY(m.cMissingFiles), m.cFile, m.cMissingFiles + ", " + m.cFile)

      ENDIF

    ENDSCAN

    USE IN MyProject

    IF NOT EMPTY(m.cMissingFiles)

      THIS.cErrorMessage = "Project files were missing: " + m.cMissingFiles

      RETURN .F.

    ENDIF

    THIS.oVFP = CREATEOBJECT("VisualFoxpro.Application")

    * This app will kill the vfp9.exe process if it hangs up
    * on a user dialog that we can't possibly respond to.
    *---------------------------------------------------------
    DECLARE INTEGER ShellExecute IN SHELL32.DLL ;
      INTEGER nWinHandle, ;
      STRING  cOperation, ;
      STRING  cFileName, ;
      STRING  cParameters, ;
      STRING  cDirectory, ;
      INTEGER nShowWindow

    SHELLEXECUTE(_SCREEN.HWND, "OPEN", _VFP.SERVERNAME, TRANSFORM(THIS.oVfp.APPLICATION.PROCESSID) + " " + m.cBuildTime, SYS(2023), .F.)

    * Open the project
    *
    * The only time this call should error is when opening the project
    * causes a dialog box, hangs and is killed by KillProcess.exe.
    * Therefore, we don't need to call This.CloseVFP() in the CATCH.
    *-----------------------------------------------------------------
    TRY

      THIS.oVFP.DOCMD('MODIFY PROJECT "' + THIS.cProject + '" NOSHOW NOWAIT')

    CATCH

      THIS.cErrorMessage = "Failed to open project " + THIS.cProject + " (KILLED)"

      lKilled = .T.

    ENDTRY

    IF m.lKilled = .T.

      RETURN .F.

    ENDIF

    TRY

      cType = VARTYPE(THIS.oVFP.ACTIVEPROJECT.NAME)

    CATCH

    ENDTRY

    IF m.cType <> "C"

      THIS.cErrorMessage = "Failed to open project " + THIS.cProject

      THIS.CloseVFP()

      RETURN .F.

    ENDIF

    * Check for the output folder and create if necessary
    *----------------------------------------------------
    IF NOT DIRECTORY(m.cOutputPath)

      MD (m.cOutputPath)

    ENDIF

    * Test the project to see if it will build
    *
    * Since we'll be working from local files in all cases
    * we should "rebuild all" every time.
    *
    * The only time this call should error is when the build hangs
    * on a Locate File dialog and is killed by KillProcess.exe.
    * Therefore, we don't need to call This.CloseVFP() in the CATCH.
    *-----------------------------------------------------------------
    TRY

      lReturn = THIS.oVFP.ACTIVEPROJECT.BUILD(m.cOutputPath + THIS.cOutputName, THIS.nBuildAction, .T., .F.)

    CATCH

      THIS.cErrorMessage = "Failed to build project "  + THIS.cProject + " (KILLED)"

      lKilled = .T.

    ENDTRY

    IF m.lKilled = .T.

      RETURN .F.

    ENDIF

    cErrorFile = FORCEEXT(THIS.cProject, "err")

    IF FILE(m.cErrorFile)

      * If we built then the errors are just warnings
      *----------------------------------------------
      IF m.lReturn

        THIS.cWarningMessage = FILETOSTR(m.cErrorFile)

      ELSE

        THIS.cErrorMessage = FILETOSTR(m.cErrorFile)

      ENDIF

    ELSE

      IF m.lReturn = .F.

        THIS.cErrorMessage = "Error building VFP project " + THIS.cProject

      ENDIF

    ENDIF

    THIS.CloseVFP()

    RETURN m.lReturn

  ENDPROC


  PROTECTED PROCEDURE CloseVfp()

    * Manually close VFP here
    *------------------------
    THIS.oVFP.QUIT()

    THIS.oVFP = NULL

  ENDPROC


  FUNCTION INIT()

    * See "Commands that Scope to a Data Session" in help for more info.
    *----------------------------------------------------------------------
    SET EXCLUSIVE OFF
    SET SAFETY OFF
    SET TALK OFF
    SET MULTILOCKS ON
    SET EXACT OFF
    SET DELETED ON
    SET CPDIALOG OFF
    SET REPROCESS TO 2 SECONDS
    SET CENTURY ON
    SET BELL OFF
    SET LOGERRORS OFF

  ENDFUNC


  PROTECTED FUNCTION ERROR(nError, cMethod, nLine) AS VOID

    SET TEXTMERGE TO (JUSTPATH(_VFP.SERVERNAME) + "\ProjectBuilderErrors-" + CHRTRAN(TRANSFORM(DATE()), "/", "-") + ".log") ADDITIVE NOSHOW

    SET TEXTMERGE ON

      \DateTime     : <<TRANSFORM(DATETIME())>>
      \Error Number : <<TRANSFORM(m.nError)>>
      \Method       : <<ALLTRIM(m.cMethod)>>
      \Line Number  : <<TRANSFORM(nLine)>>
      \Project      : <<THIS.cProject>>
      \Message      : <<MESSAGE()>>
      \ErrorParam   : <<SYS(2018)>>
      \Current Line : <<IIF(VARTYPE(m.nLine) <> "N", 0, m.nLine)>>
      \Stack Level  : <<MAX(1, ASTACKINFO(aCurStack) - 1)>>
      \Line Contents: <aCurStack[THIS.nLevel, 6]>>
      \

    SET TEXTMERGE OFF

    SET TEXTMERGE TO

  ENDPROC

ENDDEFINE

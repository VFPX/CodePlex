***********************************************************************
*  FoxUnit is Copyright (c) 2004 - 2005, Visionpace
*  All rights reserved.
*
*  Redistribution and use in source and binary forms, with or
*  without modification, are permitted provided that the following
*  conditions are met:
*
*    *  Redistributions of source code must retain the above
*      copyright notice, this list of conditions and the
*      following disclaimer.
*
*    *  Redistributions in binary form must reproduce the above
*      copyright notice, this list of conditions and the
*      following disclaimer in the documentation and/or other
*      materials provided with the distribution.
*
*    *  The names Visionpace and Vision Data Solutions, Inc.
*      (including similar derivations thereof) as well as
*      the names of any FoxUnit contributors may not be used
*      to endorse or promote products which were developed
*      utilizing the FoxUnit software unless specific, prior,
*      written permission has been obtained.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
*  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
*  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
*  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
*  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
*  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
*  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
*  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
*  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
*  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
*  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
*  POSSIBILITY OF SUCH DAMAGE.
***********************************************************************

RETURN CREATEOBJECT("FxuResultData")

**********************************************************************
DEFINE CLASS FxuResultData AS FxuCustom OF FxuCustom.prg
  **********************************************************************

  #IF .F.
    LOCAL THIS AS FxuResultData OF FxuResultData.prg
  #ENDIF

  ioDataMaintenance = .NULL.
  icDataPath = CURDIR()
  icResultsTable = 'FXUResults'
  ioFileIO = .NULL.

  ********************************************************************
  FUNCTION INIT(tcDataPath, tcResultsTable)
    ********************************************************************

    THIS.icResultsTable = EVL(tcResultsTable,THIS.icResultsTable)
    THIS.icResultsTable = JUSTSTEM(THIS.icResultsTable)

    IF !EMPTY(tcDataPath)
      IF DIRECTORY(tcDataPath)
        THIS.icDataPath = ADDBS(tcDataPath)
      ENDIF
    ENDIF

    SET DELETED ON
    THIS.ioDataMaintenance = FxuNewObject("FxuDataMaintenance", ;
      THIS.icResultsTable)
    THIS.OpenDataInit()

    THIS.ioFileIO = FxuNewObject("FXUFileIO")

    ********************************************************************
  ENDFUNC
  ********************************************************************

  ********************************************************************
  FUNCTION OpenDataInit
    ********************************************************************

    LOCAL loDataMaintenance AS FxuDataMaintenance OF FxuDataMaintenance.prg

    loDataMaintenance = THIS.ioDataMaintenance

    IF !FILE(THIS.icDataPath + FORCEEXT(THIS.icResultsTable,"DBF"))
      loDataMaintenance.CreateNewTestResultTable(THIS.icDataPath, ;
        THIS.icResultsTable)
    ELSE
      loDataMaintenance.ReIndexResultsTable(.T.)
    ENDIF

    loDataMaintenance.OpenResultsTable(.F.)

    RETURN


    ********************************************************************
  ENDFUNC
  ********************************************************************

  ********************************************************************
  FUNCTION LogResult(toTestResult AS FxuTestResult OF FxuTestResult.prg)
    ********************************************************************

    LOCAL lcPkExpression, lnSecondsElapsed
    LOCAL lcFailureErrorDetails, lcMessages, lcErrorDetails

    lnSecondsElapsed = THIS.CalculateElapsed(toTestResult.inCurrentStartSeconds,toTestResult.inCurrentEndSeconds)
    lcFailureErrorDetails = toTestResult.icFailureErrorDetails
    lcMessages = toTestResult.icMessages


    lcErrorDetails = SPACE(0)
    lcPKExpression = PADR(UPPER(toTestResult.icCurrentTestClass),LENC(EVALUATE(THIS.icResultsTable+".TClass"))) + ;
      PADR(UPPER(toTestResult.icCurrentTestName),LENC(EVALUATE(THIS.icResultsTable+".TName")))

    UPDATE (THIS.icResultsTable) ;
      SET ;
      Success = toTestResult.ilCurrentResult, ;
      TLastRun = DATETIME(), ;
      TElapsed = m.lnSecondsElapsed,  ;
      Fail_Error = lcFailureErrorDetails,;
      MESSAGES = m.lcMessages, ;
      TRUN = .T. ;
      WHERE UPPER(TClass) + UPPER(TName) == m.lcPKExpression


    ********************************************************************
  ENDFUNC
  ********************************************************************

  ********************************************************************
  FUNCTION OpenResults
    ********************************************************************

    IF !USED(THIS.icResultsTable)
      USE (THIS.icDataPath + THIS.icResultsTable) IN 0 SHARED ORDER tclname
    ENDIF


    ********************************************************************
  ENDFUNC
  ********************************************************************

  ********************************************************************
  FUNCTION LoadTestCaseClass(tcTestClassFile)
    ********************************************************************
    * EHW/02/27/2005
    IF EMPTY(tcTestClassFile)
      LOCAL loFrmLoadClass AS fxuFrmLoadClass OF fxu.vcx
      LOCAL i
      loFrmLoadClass=NEWOBJECT('fxuFrmLoadClass','fxu.vcx')
      loFrmLoadClass.SHOW
      IF loFrmLoadClass.ilCancel = .F.
        WITH loFrmLoadClass.lstFiles
          FOR i = 1 TO .LISTCOUNT
            IF loFrmLoadClass.lstFiles.SELECTED[i]
              THIS.LoadTestCaseClassStep2(ADDBS(loFrmLoadClass.icfxuselectedtestdirectory) + .LISTITEM[i], .T.) && Added path to file name. HAS
            ENDIF
          NEXT
        ENDWITH
      ENDIF
      RELEASE loFrmLoadClass
    ELSE
      THIS.LoadTestCaseClassStep2(tcTestClassFile)
    ENDIF
    RETURN
  ENDFUNC

  ********************************************************************
  FUNCTION LoadTestCaseClassStep2(tcTestClassFile, tlNew)
    ********************************************************************

    LOCAL loEnumerator AS FxuTestCaseEnumerator OF FxuTestCaseEnumerator.prg

    LOCAL lcTestClassFile, lcCurdir, lcTestDirectory, ;
      lcTag, lnTClass, lnTName, lnLocation, llNew, lcTestName

    ************
    * EHW/02/27/2005
    llNew = tlNew
    ************
    lcTag = ORDER(THIS.icResultsTable)
    SET ORDER TO 0 IN (THIS.icResultsTable)
    lnTClass = LENC(EVALUATE(THIS.icResultsTable+".TCLass"))
    lnTName = LENC(EVALUATE(THIS.icResultsTable+".TName"))

    loEnumerator = FxuNewObject("FxuTestCaseEnumerator")

    IF EMPTY(m.tcTestClassFile)

      LOCAL lcTestsFolder

      IF USED(THIS.icResultsTable)

        lcTestsFolder = ADDBS(JUSTPATH(DBF(THIS.icResultsTable)))

      ELSE

        lcTestsFolder = GetTestsDir() && HAS

      ENDIF

      lcCurDir = FULLPATH(CURDIR())

      CD (m.lcTestsFolder)
      lcTestClassFile = GETFILE("PRG", ;
        "Test Class .PRG", ;
        "", ;
        0, ;
        "Select the Test Class .PRG whose tests (methods) you want to load into the list.")
      CD (m.lcCurDir)

      llNew = .T.  &&& as opposed to re-loading an existing .PRG
      
    ELSE

      m.tcTestClassFile = FULLPATH(tcTestClassFile)

      IF FILE(m.tcTestClassFile)
        lcTestClassFile = m.tcTestClassFile
      ENDIF

    ENDIF

    IF NOT EMPTY(lcTestClassFile)

      lcTestClassFile = THIS.ioFileIO.GetCaseSensitiveFileName(lcTestClassFile,.T.)

      lcTestClass = JUSTSTEM(lcTestClassFile)

      lcTestCases = loEnumerator.ReadTestNames(lcTestClassFile, lcTestClass)

      lnTestCases = ALINES(laTestCases, lcTestCases, .T.)
      
      cTestClassPath = JUSTPATH(m.lcTestClassFile) && HAS

      *TODO store the class path in the cursor.
      IF THIS.LoadUpTestCasesToCursor(m.lcTestClass, m.lcTestCases)

        SELECT TestCase_Curs
        GO TOP
        lnLocation = 0
        SCAN
          lnLocation = lnLocation + 1
          lcTestName = TestCase_Curs.tname

          IF SEEK(PADR(UPPER(m.lcTestClass),m.lnTClass) + PADR(UPPER(m.lcTestName),m.lnTName), ;
              THIS.icResultsTable, ;
              "TCLName")
            REPLACE Location WITH m.lnLocation ;
              IN (THIS.icResultsTable)
          ELSE

            INSERT INTO (THIS.icResultsTable) ;
              (TClass, TName, TRUN, Location, TPath) ;
              VALUES ;
              (m.lcTestClass, m.lcTestName, .F., m.lnLocation, m.cTestClassPath) && Added path value. HAS

          ENDIF

          SELECT TestCase_Curs

        ENDSCAN

        *  delete the records for the TestClass.PRG
        *  that are no longer contained in that
        *  TestClass.PRG (the developer deleted those
        *  tests)
        DELETE FROM (THIS.icResultsTable) ;
          WHERE UPPER(ALLTRIM(TClass)) == UPPER(ALLTRIM(lcTestClass)) ;
          AND UPPER(TName) NOT IN ;
          (SELECT UPPER(TName) AS CurrentTests;
          FROM TestCase_Curs WHERE UPPER(ALLTRIM(TClass)) == UPPER(ALLTRIM(m.lcTestClass)))


      ENDIF

    ENDIF

    USE IN SELECT("TestCase_Curs")
    USE IN SELECT("TheCrit")
    IF NOT EMPTY(m.lcTag)
      SET ORDER TO TAG (m.lcTag) IN (THIS.icResultsTable)
    ENDIF

    IF m.llNew AND NOT EMPTY(m.lcTestClassFile)
      *
      *  position the record pointer on the first
      *  test in the newly-added .PRG (if any)
      *
      SELECT (THIS.icResultsTable)
      LOCATE FOR UPPER(ALLTRIM(TCLass)) == UPPER(ALLTRIM(m.lcTestClass))
      IF EOF()
        LOCATE
      ENDIF
    ELSE
      *
      *  most likely this method was called from
      *  THIS.ReLoadTestCaseClass(), which has
      *  its own record-pointer-repositioning logic
      *
    ENDIF


    ********************************************************************
  ENDFUNC
  ********************************************************************


  ********************************************************************
  FUNCTION LoadUpTestCasesToCursor
    ********************************************************************

    LPARAMETERS lcTestClass, lcTestCases

    LOCAL ARRAY laTestCases[1]

    LOCAL lnTestCases

    lnTestCases = ALINES(laTestCases,lcTestCases)

    IF lnTestCases < 1
      RETURN .F.
    ENDIF

	*-- FDBOZZO. 01/10/2011. Field length expansion.
	*-- 	Expanded TClass C(80) to C(110) ==> So the Unit Test file name can be 'ut_libraryName__className__methodName.prg'
	*-- 	Expanded TName C(100) to C(130) ==> So the method name can be 'SHOULD_DoSomething__WHEN_SomeConditions'
    CREATE CURSOR TestCase_Curs (resultid c(32),tclass c(110), tname c(130))

    FOR lnX = 1 TO lnTestCases

      INSERT INTO TestCase_Curs (tclass, tname) ;
        VALUES (lcTestClass,laTestCases(lnX))

    ENDFOR

    RETURN .T.


    ********************************************************************
  ENDFUNC
  ********************************************************************

  ********************************************************************
  FUNCTION ReloadTestCaseClasses
    ********************************************************************

    LOCAL lnTestClasses, lnX
    LOCAL ARRAY laTestClasses[1]
    laTestClasses[1] = .F.

    SELECT DISTINCT tclass, tpath FROM (THIS.icResultsTable) ;
      INTO ARRAY laTestClasses && Added TPath to query. HAS

    IF VARTYPE(laTestClasses[1]) == 'C'

      *lnTestClasses = ALEN(laTestClasses) HAS
      lnTestClasses = _TALLY
      
      FOR lnX = 1 TO lnTestClasses

        THIS.ReloadTestCaseClass(ALLTRIM(laTestClasses[lnX,1]), ALLTRIM(laTestClasses[lnX,2])) && Added path to call. HAS

      ENDFOR

    ENDIF

    RETURN


    ********************************************************************
  ENDFUNC
  ********************************************************************

  ********************************************************************
  FUNCTION ReloadTestCaseClass(tcTestClass, tcDirectory) && Added directory parameter. HAS
    ********************************************************************

    IF EMPTY(m.tcTestClass)
      *  this can happen in some strange scenarios
      RETURN
    ENDIF

    LOCAL lcTestClassFile, lcFullPath

    lcTestClassFile = ALLTRIM(tcTestClass) + ".prg"

    lcFullPath = LOCFILE(ADDBS(m.tcDirectory) + lcTestClassFile, "prg", ;
      "Could Not Locate " + lcTestClassFile) && Added directory. HAS

    LOCAL lcTestClass, lcTestName

    lnSelect = SELECT(0)
    SELECT (THIS.icResultsTable)
    lcTestClass = TClass
    lcTestName = TName

    THIS.loadTestCaseClass(THIS.ioFileIO.GetCaseSensitiveFileName(lcFullPath))

    SELECT (THIS.icResultsTable)
    LOCATE FOR TClass == m.lcTestClass AND TName == m.lcTestName
    IF EOF()
      LOCATE FOR TClass == m.lcTestClass
      IF EOF()
        LOCATE
      ENDIF
    ENDIF
    SELECT (m.lnSelect)


    ********************************************************************
  ENDFUNC
  ********************************************************************

  ********************************************************************
  FUNCTION CreateNewTestCaseClass(tcTestsPath,tcTestClassPRG)
    *
    *  pass tcTestClassPRG BY REFERENCE if you want
    *  it populated with the .PRG filename
    *
    ********************************************************************

    LOCAL loTestClassCreator AS NewTestClass OF NewTestClass.prg
    LOCAL lcNewTestClassName, llClassCreated, lcCurDir
    LOCAL loTestClassNamer AS FrmFxuNewTestClass OF fxu.vcx


    llClassCreated = .F.
    tcTestClassPRG = SPACE(0)

    PUBLIC pcNewTestClass
    pcNewTestClass = ""

    loTestClassNamer = NEWOBJECT("frmFxuNewTestClass","Fxu.vcx",.NULL.,m.tcTestsPath)
    loTestClassNamer.SHOW()
    m.lcNewTestClassName = m.pcNewTestClass

    RELEASE pcNewTestClass

    *     JDE 08/09/2004
    *    Replaced getfile() with frmFxuNewTestClass (see above code) in order
    *    to preserve case sensitivity of test class names both
    *    for the grid in the test runner and the file names themselves
    *
    *      lcCurDir = FULLPATH(CURDIR())
    *      CD (m.tcTestsPath)
    *          lcNewTestClassName = GETFILE("PRG", ;
    *                                       "Test Class .PRG", ;
    *                                       "", ;
    *                                       0, ;
    *                                       "Specify the filename for new Test Class .PRG")
    *          CD (m.lcCurDir)


    DO CASE
        ************************************************
      CASE EMPTY(m.lcNewTestClassName)
        ************************************************
        MESSAGEBOX("No new Test Class .PRG has been created", ;
          48, ;
          "Please Note")
        RETURN .F.
        ************************************************
      CASE NOT UPPER(JUSTEXT(m.lcNewTestClassName)) == "PRG"
        ************************************************
        MESSAGEBOX("Test Class must be a .PRG program filename.", ;
          16, ;
          "Please Note")
        RETURN .F.
        ************************************************
      CASE FILE(m.lcNewTestClassName)
        ************************************************
        IF MESSAGEBOX(m.lcNewTestClassName + ;
            " already exists -- overwrite it?", ;
            4+48,"Overwrite?") = 7   &&& No
          RETURN .F.
        ENDIF
    ENDCASE

    SET PATH TO (["] + JUSTPATH(m.lcNewTestClassName) + ["]) ADDITIVE && Add new location to path. HAS

    loTestClassCreator = FxuNewObject("FxuNewTestClass")
    *
    *  MODIFY COMMAND FXUNewTestClass
    *    XXDTES("FXUNEWTESTCLASS.PRG","FUNCTION CreateNewTestClass(tcClassName)")
    *
    llClassCreated = loTestClassCreator.CreateNewTestClass(m.lcNewTestClassName)

    DO CASE
      CASE NOT m.llClassCreated AND EMPTY(loTestClassCreator.icLastErrorMessage)
        *  nothing to do
      CASE NOT m.llClassCreated
        MESSAGEBOX("Class not created:" + CHR(13) + ;
          loTestClassCreator.icLastErrorMessage, ;
          16, ;
          "Class Not Created")
      OTHERWISE
        *lcFullPath = LOCFILE(JUSTSTEM(m.lcNewTestClassName) + ".prg")

        MODIFY COMMAND (m.lcNewTestClassName)

        THIS.ioFileIO.RenameFile(lcNewTestClassName,lcNewTestClassName)

        COMPILE (m.lcNewTestClassName)
        LOCAL lnTestMethods
        lnTestMethods = THIS.LoadTestCaseClass(m.lcNewTestClassName)
    ENDCASE

    tcTestClassPRG = m.lcNewTestClassName
    RETURN m.llClassCreated


    ********************************************************************
  ENDFUNC
  ********************************************************************

  ********************************************************************
  FUNCTION RemoveTestCaseClass(tcTestClass)
    ********************************************************************

    DELETE FROM (THIS.icResultsTable) WHERE UPPER(ALLTRIM(tclass)) == UPPER(ALLTRIM(tcTestClass))

    GO TOP IN (THIS.icResultsTable)

    RETURN

    ********************************************************************
  ENDFUNC
  ********************************************************************

  ********************************************************************
  FUNCTION RemoveAllTestCaseClasses()
    ********************************************************************

    DELETE FROM (THIS.icResultsTable)

    GO TOP IN (THIS.icResultsTable)

    RETURN

    ********************************************************************
  ENDFUNC
  ********************************************************************


  ********************************************************************
  PROCEDURE AddNewTest(tcTestClass, toFXUForm, tcPath) && Added Path parameter. HAS
    ********************************************************************
    *
    *  add this new custom test Method at the bottom,
    *  just before the ENDDEFINE, and open the program
    *  editor with the cursor positioned on this new Method
    *
    LOCAL lcTestClass
    lcTestClass = ADDBS(m.tcPath) + FORCEEXT(m.tcTestClass,"PRG") && Added Path. HAS
    IF NOT FILE(m.lcTestClass)
      MESSAGEBOX("Unable to locate " + CHR(13) + ;
        m.tcTestClass + CHR(13) + ;
        "typically because it is not in the VFP " + ;
        "path at the moment -- you should include " + ;
        "the folder containing FoxUnit test classes (.PRGs) " + ;
        "in your VFP path before starting FoxUnit.", ;
        16, ;
        "Please Note")
      RETURN .F.
    ELSE

      lcTestClass = THIS.ioFileIO.GetCaseSensitiveFileName(FULLPATH(m.lcTestClass),.T.)

    ENDIF
    IF THIS.IsFileReadOnly(m.lcTestClass)
      MESSAGEBOX(m.lcTestClass + " is marked ReadOnly, " + ;
        "typically because it is currently not " + ;
        "checked out of your Source Control provider.", ;
        48,"Please Note")
      RETURN .F.
    ENDIF
    LOCAL laLines[1], lnInsertLine, lnLines, xx, lcLine, ;
      lnNewMethodLine, lcText, laNewLines[1]
    lnLines = ALINES(laLines,FILETOSTR(m.lcTestClass))
    lnInsertLine = -1
    FOR xx = 1 TO m.lnLines
      lcLine = UPPER(ALLTRIM(m.laLines[m.xx]))
      IF UPPER(ALLTRIM(CHRTRAN(m.lcLine,CHR(9),SPACE(0)))) == "ENDDEFINE"
        lnInsertLine = m.xx
        EXIT
      ENDIF
    ENDFOR
    IF m.lnInsertLine < 0
      MESSAGEBOX("Unable to insert new test method " + ;
        "into " + m.tcTestClass + "." + ;
        CHR(13) + CHR(13) + ;
        m.tcTestClass + " will simply be opened " + ;
        "in the program editor.", ;
        48,"Please Note")
      lnNewMethodLine = 1
    ELSE
      * insert these 8 lines:
      TEXT TO lcText NOSHOW && Removed the annoying asterisks. HAS


  FUNCTION NewTestMethod

  *  your code here...

  ENDFUNC

      ENDTEXT

      *BUG This line puts the function in the wrong place for me. HAS
      *lnInsertLine = m.lnInsertLine - 2
      lnInsertLine = m.lnInsertLine - 1

      lcText = CHR(13) + CHR(10) + m.lcText + CHR(13) + CHR(10)
      ALINES(laNewLines,m.lcText)
      FOR EACH lcLine IN laNewLines
        DIMENSION laLines[ALEN(laLines,1)+1]
        AINS(laLines,m.lnInsertLine)
        laLines[m.lnInsertLine] = m.lcLine
        IF UPPER(ALLTRIM(CHRTRAN(m.lcLine,CHR(9),SPACE(0)))) = "FUNCTION"
          lnNewMethodLine = m.lnInsertLine
        ENDIF
        lnInsertLine = lnInsertLine + 1
      ENDFOR

      *
      *  turn laLines into the new m.tcTestClass .PRG
      *
      ERASE (m.lcTestClass)
      FOR EACH lcLine IN laLines
        STRTOFILE(m.lcLine+CHR(13)+CHR(10),m.lcTestClass,.T.)
      ENDFOR

    ENDIF

    RELEASE laLines, laNewLines

    IF VARTYPE(m.toFXUForm) = "O" ;
        AND UPPER(toFXUForm.BASECLASS) == "FORM"
      LOCAL llFoxUnitForm, laClasses[1]
      ACLASS(laClasses,m.toFXUForm)
      llFoxUnitForm = ASCAN(laClasses,"frmFoxUnit",1,-1,1,15)>0
      IF m.llFoxUnitForm
        *
        *  set a flag so that FoxUnit.SCX/Activate
        *  will reload this .PRG when it activates
        *  after you are done in m.lcTestClass
        *    MODIFY CLASS frmFoxUnit OF FXU.VCX METHOD Activate
        *
        toFXUForm.ADDPROPERTY("ilReloadCurrentClassOnActivate",.T.)
      ENDIF
    ENDIF

    *
    *  start the program editor on the indicated line,
    *  at the spot where the developer needs to specify
    *  the method name
    *
    EDITSOURCE(m.lcTestClass,m.lnNewMethodLine)

    KEYBOARD "{HOME}{RightArrow}{RightArrow}{RightArrow}{RightArrow}{RightArrow}{RightArrow}{RightArrow}{RightArrow}{RightArrow}{RightArrow}{SHIFT+END}" PLAIN CLEAR

    ********************************************************************
  ENDPROC
  ********************************************************************


  ********************************************************************
  PROCEDURE ModifyExistingTest(tcTestClass, tcTestName, toFXUForm, tcPath) && Added Path parameter. HAS
    ********************************************************************
    *
    *  do a MODIFY COMMAND with the cursor positioned
    *  on the indicated tcTestName method in tcTestClass
    *
    LOCAL lcTestClass
    lcTestClass = ADDBS(m.tcPath) + FORCEEXT(m.tcTestClass,"PRG") && Added Path. HAS
    IF NOT FILE(m.lcTestClass)
      MESSAGEBOX("Unable to locate " + CHR(13) + ;
        m.tcTestClass + CHR(13) + ;
        "typically because it is not in the VFP " + ;
        "path at the moment -- you should include " + ;
        "the folder containing FoxUnit test classes (.PRGs) " + ;
        "in your VFP path before starting FoxUnit.", ;
        16, ;
        "Please Note")
      RETURN .F.
    ELSE
      lcTestClass = THIS.ioFileIO.GetCaseSensitiveFileName(FULLPATH(m.lcTestClass), .T.)

    ENDIF
    IF THIS.IsFileReadOnly(m.lcTestClass)
      MESSAGEBOX(m.lcTestClass + " is marked ReadOnly, " + ;
        "typically because it is currently not " + ;
        "checked out of your Source Control provider." + ;
        CHR(13) + CHR(13) + ;
        m.lcTestClass + " will be opened in the VFP " + ;
        "program editor, but it is ReadOnly, and you " + ;
        "will not be able to make any changes.", ;
        48,"Please Note")
    ENDIF
    *
    *  find the FUNCTION/PROCEDURE <m.tcTestName> line
    *
    LOCAL laLines[1], lnCursorLine, lnLines, xx, lcLine, ;
      lcTestName
    lcTestName = UPPER(ALLTRIM(m.tcTestName))
    lnLines = ALINES(laLines,FILETOSTR(m.lcTestClass))
    lnCursorLine = -1
    FOR xx = 1 TO m.lnLines
      lcLine = UPPER(ALLTRIM(m.laLines[m.xx]))
      lcLine = CHRTRAN(m.lcLine,CHR(9),SPACE(0))
      lcLine = CHRTRAN(m.lcline,"()",SPACE(0))
      IF m.lcLine == "FUNCTION " + m.lcTestName ;
          OR ;
          m.lcLine == "PROCEDURE " + m.lcTestName
        lnCursorLine = m.xx
        EXIT
      ENDIF
    ENDFOR
    RELEASE laLines
    IF m.lnCursorLine < 0
      MESSAGEBOX("Unable to locate the " + m.lcTestName + ;
        "method -- " + m.lcTestClass + " will be " + ;
        "opened in the program editor with the " + ;
        "cursor positioned whereever it was last " + ;
        "time.", ;
        48,"Please Note")
      lnCursorLine = 0
    ENDIF

    IF VARTYPE(m.toFXUForm) = "O" ;
        AND UPPER(toFXUForm.BASECLASS) == "FORM"
      LOCAL llFoxUnitForm, laClasses[1]
      ACLASS(laClasses,m.toFXUForm)
      llFoxUnitForm = ASCAN(laClasses,"frmFoxUnit",1,-1,1,15)>0
      IF m.llFoxUnitForm
        *
        *  set a flag so that FoxUnit.SCX/Activate
        *  will reload this .PRG when it activates
        *  after you are done in m.lcTestClass
        *    MODIFY CLASS frmFoxUnit OF FXU.VCX METHOD Activate
        *
        toFXUForm.ADDPROPERTY("ilReloadCurrentClassOnActivate",.T.)
      ENDIF
    ENDIF

    *
    *  start the program editor on the indicated line
    *
    EDITSOURCE(m.lcTestClass,m.lnCursorLine)
    *KEYBOARD "{HOME}{RightArrow}{RightArrow}{RightArrow}{RightArrow}{RightArrow}{RightArrow}{RightArrow}{RightArrow}{RightArrow}{RightArrow}{SHIFT+END}" PLAIN CLEAR


    ********************************************************************
  ENDPROC
  ********************************************************************


  ********************************************************************
  FUNCTION SetAllTestsNotRun
    ********************************************************************

    UPDATE (THIS.icResultsTable) SET TRUN = .F.

    ********************************************************************
  ENDFUNC
  ********************************************************************

  ********************************************************************
  FUNCTION CalculateElapsed(tnStartSeconds, tnEndSeconds)
    ********************************************************************

    IF tnEndSeconds <tnStartSeconds
      tnEndSeconds = tnEndSeconds + 126000
    ENDIF

    lnElapsedSeconds = tnEndSeconds - tnStartSeconds

    RETURN lnElapsedSeconds

    ********************************************************************
  ENDFUNC
  ********************************************************************

  ********************************************************************
  FUNCTION DESTROY
    ********************************************************************

    USE IN SELECT(THIS.icResultsTable)
    THIS.ioDataMaintenance = .NULL.

    ********************************************************************
  ENDFUNC
  ********************************************************************

  ********************************************************************
  FUNCTION ReceiveResultsNotification(toTestResult AS TestResult OF TestResult.prg)
    ********************************************************************

    THIS.LogResult(toTestResult)

    ********************************************************************
  ENDFUNC
  ********************************************************************


  ********************************************************************
  FUNCTION IsFileReadOnly(tcFileName)
    ********************************************************************
    *
    *  pass tcFileName with a fully-qualified path
    *

    LOCAL lcDir
    lcDir = JUSTPATH(m.tcFileName)
    IF NOT DIRECTORY(m.lcDir)
      *
      *  either the full path has not been passed, or the
      *  indicated directory does not exist
      *
      RETURN .F.
    ENDIF

    LOCAL lcCurDir, lcJustFile, llReadOnly, laFiles[1]
    lcCurDir = FULLPATH(CURDIR())
    lcJustFile = JUSTFNAME(m.tcFileName)

    CD (m.lcDir)

    *
    *  since we know the full name of the file, we can
    *  pass that as the 2nd cFileSkeleton parameter to
    *  ADIR(), so that that file will be the only one
    *  found by ADIR()
    *
    IF ADIR(laFiles,lcJustFile) = 0
      llReadOnly = .F.
    ELSE
      llReadOnly = "R" $ laFiles[1,5]
    ENDIF
    *
    *  ...making this routine faster than if we used a
    *  more traditional loop thru all the files

    CD (m.lcCurDir)
    RETURN m.llReadOnly

    ********************************************************************
  ENDFUNC
  ********************************************************************

  ********************************************************************
  FUNCTION GetCaseSensitiveFileName(tcFullPathToFile, tlReturnFullPath)
    ********************************************************************

    IF !EMPTY(tlReturnFullPath)
      tlReturnFullPath = .T.
    ELSE
      tlReturnFullPath = .F.
    ENDIF


    LOCAL loFs AS Scripting.FileSystemObject
    LOCAL loFile AS Scripting.FILE
    LOCAL lcCaseSensitiveFileName

    loFs = CREATEOBJECT("Scripting.FileSystemObject")
    loFile = oFs.GETFILE(tcFullPathToFile)

    IF tlReturnFullPath
      lcCaseSensitiveFileName = oFile.PATH
    ELSE
      lcCaseSensitiveFileName = oFile.NAME
    ENDIF

    RELEASE loFile
    RELEASE loFs

    RETURN lcCaseSensitiveFileName

    ********************************************************************
  ENDFUNC
  ********************************************************************

  ********************************************************************
  FUNCTION RenameFile(tcOldFileName, tcNewFileName)
    ********************************************************************
    * Note that the file name parameters require the full path

    LOCAL loFs AS Scripting.FileSystemObject

    loFs.MoveFile(tcOldFileName,tcNewFileName)

    RELEASE loFs

    ********************************************************************
  ENDFUNC
  ********************************************************************

  **********************************************************************
ENDDEFINE && CLASS
**********************************************************************
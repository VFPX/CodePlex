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


#DEFINE C_Version "1.10.00 (VFPX)"

LOCAL loFXUForm

loFXUForm = GetFoxUnitForm()
IF VARTYPE(m.loFXUForm) = "O"
  *!*    IF MESSAGEBOX("The FoxUnit interface is already running, make it the active form?", ;
  *!*                  4+48, ;
  *!*                  "FoxUnit is already running!") = 6
  *!*      *
  *!*      *  MODIFY COMMAND FXUShowForm
  *!*      *
  *!*      FXUShowForm()
  *!*    ENDIF
  *!*    RETURN
  FXUShowForm()
  RETURN
ENDIF

CheckPath()

* FXU/JDE 08/21/2004
* Now adding call to ManageFxuClassFactory

DO ManageFxuClassFactory

* FXU/JDE 07/01/2004
* Included goFoxUnitTestBroker as public in
* order to de-couple the any UI tested in
* a unit test from being a child of the
* top-level FoxUnit form.

*DO FORM FoxUnit
RELEASE goFoxUnitForm, goFoxUnitTestBroker
PUBLIC goFoxUnitForm, goFoxUnitTestBroker
goFoxUnitTestBroker = FXUNewObject("FxuTestBroker")
goFoxUnitForm = FXUNewObject("FoxUnitForm")
IF VARTYPE(m.goFoxUnitForm) = "O"
  goFoxUnitForm.ioTestBroker = goFoxUnitTestBroker
  goFoxUnitForm.SHOW()
ENDIF

RETURN



*************************************************
PROCEDURE GetFoxUnitForm
  *************************************************
  *
  *  RETURN an object reference to the FoxUnit form
  *  (form inheriting from FXU.VCX/frmFoxUnit)
  *     MODIFY CLASS frmFoxUnit OF FXU.VCX
  *
  LOCAL loFXUForm, loForm, lcFormID, laClasses[1]
  loFXUForm = .NULL.
  FOR EACH loForm IN _SCREEN.FORMS
    DIMENSION laClasses[1]
    ACLASS(laClasses,m.loForm)
    IF ASCAN(laClasses,"frmFoxUnit",1,-1,1,15) > 0
      loFXUForm = m.loForm
      EXIT
    ENDIF
  ENDFOR
  RETURN m.loFXUForm



  *************************************************
PROCEDURE GetFoxUnitVersion
  *************************************************
  *
  *  pass the tcVersion parameter by REFERENCE like this:
  *    DO GetFoxUnitVersion WITH SomeVar
  *  and it gets populated here, as we've done here toward
  *  the end of this method:
  *    MODIFY CLASS frmFoxUnit OF FXU.VCX METHOD Load
  *
  *  or, you can SET PROCEDURE TO FXU, and:
  *    SomeVar = GetFoxUnitVersion()
  *
  LPARAMETERS tcVersion
  tcVersion = C_Version
  RETURN C_Version


  ********************************************************************
PROCEDURE ManageFxuClassFactory
  ********************************************************************

  LOCAL lcFxuClassFactoryLocation, lcFxuClassFactoryFolder, nLevel, cSys16 

  TRY
    USE FxuClassFactoryBase IN 0 SHARED
  CATCH TO loEx

  ENDTRY

  * If FoxUnit is launched from a method, this line doesn't work.  HAS
  *lcFxuClassFactoryFolder = ADDBS(JUSTPATH(SYS(16,1)))

  * We'll use this prg, or a binary if we can find one. HAS
  *---------------------------------------------------------
  LOCAL ARRAY aProgChain[1,1]
  nLevels = ASTACKINFO(aProgChain)
  
  IF INLIST(JUSTEXT(aProgChain[m.nlevels, 3]), "APP", "EXE")

    lcFxuClassFactoryFolder = ADDBS(JUSTPATH(aProgChain[m.nlevels, 3]))

  ELSE

    lcFxuClassFactoryFolder = ADDBS(JUSTPATH(aProgChain[m.nlevels - 1, 2]))

  ENDIF
  
  ASSERT DIRECTORY(m.lcFxuClassFactoryFolder) MESSAGE "Specified Class Factory folder does not exist!"
  *----------------------------------------------------------

  SET PATH TO (["] + m.lcFxuClassFactoryFolder + ["]) ADDITIVE && HAS
  
  lcFxuClassFactoryLocation = lcFxuClassFactoryFolder + "FxuClassFactory.dbf"

  IF !FILE(lcFxuClassFactoryLocation)
    SELECT FxuClassFactoryBase
    COPY TO (lcFxuClassFactoryLocation )
  ELSE
    USE FxuClassFactory IN 0 EXCLUSIVE
    INSERT INTO FxuClassFactory ;
      SELECT * FROM FxuClassFactoryBase WHERE UPPER(ClassID) NOT IN ;
      (SELECT UPPER(ClassID) FROM FxuClassFactory)
  ENDIF

  USE IN SELECT('FxuClassFactory')
  USE IN SELECT('FxuClassFactoryBase')

  RETURN


  ********************************************************************
ENDPROC
********************************************************************


********************************************************************
* EHW/02/27/2005
********************************************************************
FUNCTION getArrayOfNewTestCases(taNewTests AS ARRAY, taOldTests AS ARRAY, tcDirectory AS STRING)
  ********************************************************************
  *
  * Returns the number of testcases in the passed directory that are not already in taOldTest.
  * Updates the passed array with a list of valid test case programs.
  *
  * A test case is only valid if it can be instantiated in the current
  * test environment. It is possible that a file will be a valid test
  * case but not be able to run under the current enviornment. This
  * function is designed to remove those program files from the list.
  *
  LOCAL lnFileCount, lnx, lnLoopCount, lcAsserts
  lnFileCount = 0
  lnFileCount = getArrayOfNewProgramFiles(@taNewTests, @taOldTests, tcDirectory)
  IF lnFileCount > 0
    lnLoopCount = lnFileCount
    lcAsserts = SET("Asserts")
    SET ASSERTS OFF
    FOR lnx = lnLoopCount TO 1 STEP - 1
      IF fxuInheritsFromFxuTestCase(JUSTSTEM(taNewTests[lnx,1]), ADDBS(m.tcDirectory) + taNewTests[lnx,1]) = .F.
        *
        * Not a test case, delete it
        *
        ADEL(taNewTests,lnx)
        lnFileCount = lnFileCount - 1
      ENDIF
    NEXT
    IF lcAsserts = "ON"
      SET ASSERTS ON
    ENDIF
    IF lnFileCount <> lnLoopCount
      IF VARTYPE(taNewTests[1]) = 'C'
        *
        * Deleteing rows from the array with ADEL
        * leaves the array the same size. Resize the
        * array and Remove the empty rows (the deleted ones)
        * from the bottom of the array.
        *
        DIMENSION taNewTests[lnFileCount,ALEN(taNewTests,2)]
      ELSE
        *
        * All files were deleted
        *
        DIMENSION  taNewTests[1]
      ENDIF
    ELSE
      *
      * nothing was deleted, taNewTests has the files
      *
    ENDIF
  ENDIF
  RETURN lnFileCount
  ********************************************************************
ENDFUNC
********************************************************************

********************************************************************
FUNCTION getArrayOfTestCases(taTestCases AS ARRAY, tcDirectory AS STRING)
  ********************************************************************
  *
  * Returns the number of testcases in the passed directory.
  * Updates the passed array with a list of valid test case programs.
  *
  * A test case is only valid if it can be instantiated in the current
  * test environment. It is possible that a file will be a valid test
  * case but not be able to run under the current enviornment. This
  * function is designed to remove those program files from the list.
  *
  LOCAL lnFileCount, lnx, lnLoopCount, lcAsserts
  lnFileCount = 0
  lnFileCount = getArrayOfProgramFiles(@taTestCases, tcDirectory)
  IF lnFileCount > 0
    lnLoopCount = lnFileCount
    lcAsserts = SET("Asserts")
    SET ASSERTS OFF
    FOR lnx = lnLoopCount TO 1 STEP - 1
      IF fxuInheritsFromFxuTestCase(JUSTSTEM(taTestCases[lnx,1]), ;
        ADDBS(m.tcDirectory) + taTestCases[lnx,1]) = .F. && Added directory to file name parameter. HAS
        
        ADEL(taTestCases,lnx)
        lnFileCount = lnFileCount - 1
      
      ENDIF
    NEXT
    IF lcAsserts = "ON"
      SET ASSERTS ON
    ENDIF
    IF lnFileCount <> lnLoopCount
      IF VARTYPE(taTestCases[1]) = 'C'
        *
        * Deleteing rows from the array with ADEL
        * leaves the array the same size. Resize the
        * array and Remove the empty rows (the deleted ones)
        * from the bottom of the array.
        *
        DIMENSION taTestCases[lnFileCount,ALEN(taTestCases,2)]
      ELSE
        *
        * All files were deleted
        *
        DIMENSION taTestCases[1]
      ENDIF
    ELSE
      *
      * nothing was deleted, taTestCases has the files
      *
    ENDIF

  ENDIF
  RETURN lnFileCount
  ********************************************************************
ENDFUNC
********************************************************************


********************************************************************
FUNCTION getArrayOfNewProgramFiles(taNewFiles AS ARRAY, taOldFiles AS ARRAY, tcDirectory AS STRING)
  ********************************************************************
  LOCAL lnFileCount, lnLoopCount, lnX, lnOldIndex, lnOldFileCount
  lnFileCount = getArrayOfProgramFiles(@taNewFiles, tcDirectory)
  IF lnFileCount > 0
    lnOldFileCount = ALEN(taOldFiles,1)
    lnLoopCount = lnFileCount
    IF lnOldFileCount > 0
      FOR lnX = lnLoopCount TO 1 STEP -1
        IF ASCAN(taOldFiles,JUSTSTEM(taNewFiles[lnx,1]),1,lnOldFileCount,1,15) > 0
          *
          * This file is already in the list.
          * Delete the file name.
          *
          ADEL(taNewFiles,lnx)
          lnFileCount = lnFileCount - 1
        ENDIF
      NEXT
      IF lnFileCount <> lnLoopCount
        IF VARTYPE(taNewFiles[1]) = 'C'
          *
          * Deleteing rows from the array with ADEL
          * leaves the array the same size. Resize the
          * array and Remove the empty rows (the deleted ones)
          * from the bottom of the array.
          *
          DIMENSION taNewFiles[lnFileCount,ALEN(taNewFiles,2)]
        ELSE
          *
          * All files were deleted
          *
          DIMENSION  taNewFiles[1]
        ENDIF
      ELSE
        *
        * nothing was deleted, taNewFiles has the files
        *
      ENDIF

    ENDIF
  ENDIF
  RETURN lnFileCount
  ********************************************************************
ENDFUNC
********************************************************************


********************************************************************
FUNCTION getArrayOfProgramFiles(taFiles AS ARRAY, tcDirectory AS STRING)
  ********************************************************************
  *
  * Returns the number of programs in the passed directory.
  * Updates the passed array with a list of programs.
  *
  LOCAL lnFileCount, lcDirectory
  lnFileCount = 0
  lcDirectory = ''
  *
  * Validate the directory
  *
  DO CASE
    CASE EMPTY(tcDirectory)
      lcDirectory = FULLPATH('.')
    CASE NOT DIRECTORY(tcDirectory)
      lnFileCount = -1
    OTHERWISE
      lcDirectory = tcDirectory
  ENDCASE
  IF lnFileCount = 0
    lcDirectory = ADDBS(lcDirectory)
    lnFileCount = ADIR(taFiles,lcDirectory+'\*.prg','',1)
  ENDIF
  RETURN lnFileCount
  ********************************************************************
ENDFUNC
********************************************************************
* EHW/02/27/2005 END
********************************************************************


FUNCTION CHECKPATH()

  LOCAL lcScxPath AS STRING

  * Get the current path of this program
  lcScxPath = STRTRAN(SYS(16),'PROCEDURE CHECKPATH')
  lcScxPath = JUSTPATH(m.lcScxPath)

  * If there is a path then check it
  IF LEN(ALLTRIM(m.lcScxPath)) > 0 AND DIRECTORY(m.lcScxPath)

    IF OCCURS(m.lcScxPath,SYS(2001,'PATH')) = 0

      * If the path does not exist in the set path then add it
      SET PATH TO SYS(2001,'PATH') + '; ' + m.lcScxPath

    ENDIF
  ENDIF

ENDFUNC


* Function GetTestsDir added by HAS
FUNCTION GetTestsDir() AS STRING

  LOCAL cTestDir AS STRING

  * Default to <HomeDir>\Tests HAS
  *-------------------------------
  TRY

    cTestDir  = ADDBS(_VFP.ACTIVEPROJECT.HOMEDIR) + "Tests"

  CATCH
  
*!*      cTestDir  = ADDBS(SET("Default"))

*!*        cTestDir  = GETDIR(FULLPATH(CURDIR()), ;
*!*          "Specify the folder for your unit tests.", ;
*!*          "Specify the folder for your unit tests", ;
*!*          1+2+8+16+32+64)

  ENDTRY

  IF EMPTY(m.cTestDir)

    cTestDir  = ADDBS(SET("DIRECTORY")) + "Tests"

  ENDIF

  IF NOT DIRECTORY(m.cTestDir )

    MD (m.cTestDir )

  ENDIF

  SET PATH TO (["] + m.cTestDir + ["]) ADDITIVE

  RETURN m.cTestDir

ENDFUNC


DEFINE CLASS sesTextBlockReport AS SESSION

  *
  *  MODIFY CLASS frmShowInfo OF FXU METHOD PrintInfo
  *

  NAME = "sesTextBlockReport"


  ***************************************************
  PROCEDURE CreateTextBlockFRX
    ***************************************************
    *
    *  XXFWUTIL.VCX/frmTextblockReport::CreateTextblockFRX()
    *
    *
    *  create the temporary .FRX for the report, same
    *  as XXTBLOCK.FRX, just a header, detail, and
    *  DATETIME() in the footer
    *
    *  this method eliminates the need for an XXTBLOCK.FRX
    *  by creating it on the fly
    *
    *  CURSORTOXML("TempCursor","Junk.XML",1,0+2+8+512,0,"1")
    *
    LOCAL lcFileName, lcText
    lcFileName = ADDBS(SYS(2023)) + SYS(2015)+".XML"
    TEXT TO lcText NOSHOW
<?xml version = "1.0" encoding="Windows-1252" standalone="yes"?>
<VFPData>
  <xsd:schema id="VFPData" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">
    <xsd:element name="VFPData" msdata:IsDataSet="true">
      <xsd:complexType>
        <xsd:choice maxOccurs="unbounded">
          <xsd:element name="tempcursor" minOccurs="0" maxOccurs="unbounded">
            <xsd:complexType>
              <xsd:sequence>
                <xsd:element name="platform">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="8"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="uniqueid">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="10"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="timestamp">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="10"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="objtype">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="2"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="objcode">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="3"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="name">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="expr">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="vpos">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="8"></xsd:totalDigits>
                      <xsd:fractionDigits value="3"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="hpos">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="8"></xsd:totalDigits>
                      <xsd:fractionDigits value="3"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="height">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="8"></xsd:totalDigits>
                      <xsd:fractionDigits value="3"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="width">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="8"></xsd:totalDigits>
                      <xsd:fractionDigits value="3"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="style">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="picture">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="order">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:base64Binary">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="unique" type="xsd:boolean"></xsd:element>
                <xsd:element name="comment">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="environ" type="xsd:boolean"></xsd:element>
                <xsd:element name="boxchar">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="1"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="fillchar">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="1"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="tag">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="tag2">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:base64Binary">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="penred">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="5"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="pengreen">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="5"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="penblue">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="5"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="fillred">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="5"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="fillgreen">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="5"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="fillblue">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="5"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="pensize">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="5"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="penpat">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="5"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="fillpat">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="5"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="fontface">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="fontstyle">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="3"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="fontsize">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="3"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="mode">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="3"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="ruler">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="1"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="rulerlines">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="1"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="grid" type="xsd:boolean"></xsd:element>
                <xsd:element name="gridv">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="2"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="gridh">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="2"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="float" type="xsd:boolean"></xsd:element>
                <xsd:element name="stretch" type="xsd:boolean"></xsd:element>
                <xsd:element name="stretchtop" type="xsd:boolean"></xsd:element>
                <xsd:element name="top" type="xsd:boolean"></xsd:element>
                <xsd:element name="bottom" type="xsd:boolean"></xsd:element>
                <xsd:element name="suptype">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="1"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="suprest">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="1"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="norepeat" type="xsd:boolean"></xsd:element>
                <xsd:element name="resetrpt">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="2"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="pagebreak" type="xsd:boolean"></xsd:element>
                <xsd:element name="colbreak" type="xsd:boolean"></xsd:element>
                <xsd:element name="resetpage" type="xsd:boolean"></xsd:element>
                <xsd:element name="general">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="3"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="spacing">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="3"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="double" type="xsd:boolean"></xsd:element>
                <xsd:element name="swapheader" type="xsd:boolean"></xsd:element>
                <xsd:element name="swapfooter" type="xsd:boolean"></xsd:element>
                <xsd:element name="ejectbefor" type="xsd:boolean"></xsd:element>
                <xsd:element name="ejectafter" type="xsd:boolean"></xsd:element>
                <xsd:element name="plain" type="xsd:boolean"></xsd:element>
                <xsd:element name="summary" type="xsd:boolean"></xsd:element>
                <xsd:element name="addalias" type="xsd:boolean"></xsd:element>
                <xsd:element name="offset">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="3"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="topmargin">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="3"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="botmargin">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="3"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="totaltype">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="2"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="resettotal">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="2"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="resoid">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="3"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="curpos" type="xsd:boolean"></xsd:element>
                <xsd:element name="supalways" type="xsd:boolean"></xsd:element>
                <xsd:element name="supovflow" type="xsd:boolean"></xsd:element>
                <xsd:element name="suprpcol">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="1"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="supgroup">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:decimal">
                      <xsd:totalDigits value="2"></xsd:totalDigits>
                      <xsd:fractionDigits value="0"></xsd:fractionDigits>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="supvalchng" type="xsd:boolean"></xsd:element>
                <xsd:element name="supexpr">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
                <xsd:element name="user">
                  <xsd:simpleType>
                    <xsd:restriction base="xsd:string">
                      <xsd:maxLength value="2147483647"></xsd:maxLength>
                    </xsd:restriction>
                  </xsd:simpleType>
                </xsd:element>
              </xsd:sequence>
            </xsd:complexType>
          </xsd:element>
        </xsd:choice>
        <xsd:anyAttribute namespace="http://www.w3.org/XML/1998/namespace" processContents="lax"></xsd:anyAttribute>
      </xsd:complexType>
    </xsd:element>
  </xsd:schema>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid>_RU901GIQ7</uniqueid>
    <timestamp>614008089</timestamp>
    <objtype>1</objtype>
    <objcode>53</objcode>
    <name></name>
    <expr><![CDATA[ORIENTATION=0
PAPERSIZE=1
COPIES=1
DEFAULTSOURCE=1
YRESOLUTION=600
TTOPTION=1
]]></expr>
    <vpos>1.000</vpos>
    <hpos>0.000</hpos>
    <height>0.000</height>
    <width>-1.000</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar></fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>0</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>0</fillred>
    <fillgreen>0</fillgreen>
    <fillblue>0</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface><![CDATA[Courier New]]></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>10</fontsize>
    <mode>0</mode>
    <ruler>1</ruler>
    <rulerlines>0</rulerlines>
    <grid>true</grid>
    <gridv>4</gridv>
    <gridh>4</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>false</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>true</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>0</resettotal>
    <resoid>0</resoid>
    <curpos>true</curpos>
    <supalways>false</supalways>
    <supovflow>false</supovflow>
    <suprpcol>0</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid>_RU901GIQ9</uniqueid>
    <timestamp>0</timestamp>
    <objtype>9</objtype>
    <objcode>1</objcode>
    <name></name>
    <expr></expr>
    <vpos>0</vpos>
    <hpos>0</hpos>
    <height>5313.000</height>
    <width>0.000</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar></fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>0</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>0</fillred>
    <fillgreen>0</fillgreen>
    <fillblue>0</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>0</fontsize>
    <mode>0</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>false</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>0</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>false</supalways>
    <supovflow>false</supovflow>
    <suprpcol>0</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid>_RU901GIQA</uniqueid>
    <timestamp>0</timestamp>
    <objtype>9</objtype>
    <objcode>4</objcode>
    <name></name>
    <expr></expr>
    <vpos>0</vpos>
    <hpos>0</hpos>
    <height>3334.000</height>
    <width>0.000</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar></fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>0</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>0</fillred>
    <fillgreen>0</fillgreen>
    <fillblue>0</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>0</fontsize>
    <mode>0</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>false</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>0</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>false</supalways>
    <supovflow>false</supovflow>
    <suprpcol>0</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid>_RU901GIQB</uniqueid>
    <timestamp>0</timestamp>
    <objtype>9</objtype>
    <objcode>7</objcode>
    <name></name>
    <expr></expr>
    <vpos>0</vpos>
    <hpos>0</hpos>
    <height>6355.000</height>
    <width>0.000</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar></fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>0</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>0</fillred>
    <fillgreen>0</fillgreen>
    <fillblue>0</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>0</fontsize>
    <mode>0</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>false</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>0</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>false</supalways>
    <supovflow>false</supovflow>
    <suprpcol>0</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid>_RU901HXTS</uniqueid>
    <timestamp>697138784</timestamp>
    <objtype>8</objtype>
    <objcode>0</objcode>
    <name></name>
    <expr><![CDATA[DateTime()]]></expr>
    <vpos>13854.167</vpos>
    <hpos>5000.000</hpos>
    <height>1875.000</height>
    <width>16770.833</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment><![CDATA[ ]]></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar>C</fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>0</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>-1</fillred>
    <fillgreen>-1</fillgreen>
    <fillblue>-1</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface><![CDATA[Arial]]></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>10</fontsize>
    <mode>1</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>true</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>2</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>1</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>true</supalways>
    <supovflow>false</supovflow>
    <suprpcol>3</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid>_RU902ASYP</uniqueid>
    <timestamp>697138775</timestamp>
    <objtype>8</objtype>
    <objcode>0</objcode>
    <name></name>
    <expr><![CDATA[TheHeader]]></expr>
    <vpos>2291.667</vpos>
    <hpos>5000.000</hpos>
    <height>1875.000</height>
    <width>70000.000</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment><![CDATA[TheHeader (header)]]></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar>C</fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>0</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>-1</fillred>
    <fillgreen>-1</fillgreen>
    <fillblue>-1</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface><![CDATA[Arial]]></fontface>
    <fontstyle>1</fontstyle>
    <fontsize>10</fontsize>
    <mode>1</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>true</stretch>
    <stretchtop>false</stretchtop>
    <top>true</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>2</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>1</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>true</supalways>
    <supovflow>false</supovflow>
    <suprpcol>3</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid>_RU902BXJ1</uniqueid>
    <timestamp>697138780</timestamp>
    <objtype>8</objtype>
    <objcode>0</objcode>
    <name></name>
    <expr><![CDATA[TheText]]></expr>
    <vpos>7708.333</vpos>
    <hpos>5000.000</hpos>
    <height>1875.000</height>
    <width>70000.000</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment><![CDATA[ ]]></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar>C</fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>0</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>-1</fillred>
    <fillgreen>-1</fillgreen>
    <fillblue>-1</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface><![CDATA[Arial]]></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>10</fontsize>
    <mode>1</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>true</float>
    <stretch>true</stretch>
    <stretchtop>false</stretchtop>
    <top>false</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>2</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>1</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>true</supalways>
    <supovflow>false</supovflow>
    <suprpcol>3</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid>_RU903HYT2</uniqueid>
    <timestamp>614010044</timestamp>
    <objtype>6</objtype>
    <objcode>0</objcode>
    <name></name>
    <expr></expr>
    <vpos>4583.333</vpos>
    <hpos>5000.000</hpos>
    <height>104.167</height>
    <width>70104.167</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar></fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>-1</penred>
    <pengreen>-1</pengreen>
    <penblue>-1</penblue>
    <fillred>-1</fillred>
    <fillgreen>-1</fillgreen>
    <fillblue>-1</fillblue>
    <pensize>1</pensize>
    <penpat>8</penpat>
    <fillpat>0</fillpat>
    <fontface></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>0</fontsize>
    <mode>0</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>true</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>true</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>1</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>0</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>true</supalways>
    <supovflow>false</supovflow>
    <suprpcol>3</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid>_RU903ICYO</uniqueid>
    <timestamp>614010055</timestamp>
    <objtype>6</objtype>
    <objcode>0</objcode>
    <name></name>
    <expr></expr>
    <vpos>13437.500</vpos>
    <hpos>5000.000</hpos>
    <height>104.167</height>
    <width>70104.167</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar></fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>-1</penred>
    <pengreen>-1</pengreen>
    <penblue>-1</penblue>
    <fillred>-1</fillred>
    <fillgreen>-1</fillgreen>
    <fillblue>-1</fillblue>
    <pensize>1</pensize>
    <penpat>8</penpat>
    <fillpat>0</fillpat>
    <fontface></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>0</fontsize>
    <mode>0</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>true</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>1</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>0</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>true</supalways>
    <supovflow>false</supovflow>
    <suprpcol>3</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid>_09O0XZLM4</uniqueid>
    <timestamp>753231709</timestamp>
    <objtype>8</objtype>
    <objcode>0</objcode>
    <name></name>
    <expr><![CDATA[x3i('Page') + " " + Transform(_PageNo)]]></expr>
    <vpos>13854.167</vpos>
    <hpos>65416.667</hpos>
    <height>1875.000</height>
    <width>9687.500</width>
    <style><![CDATA[J]]></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment><![CDATA[ ]]></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar>C</fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>0</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>255</fillred>
    <fillgreen>255</fillgreen>
    <fillblue>255</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface><![CDATA[Arial]]></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>10</fontsize>
    <mode>0</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>true</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>1</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>true</supalways>
    <supovflow>false</supovflow>
    <suprpcol>3</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid></uniqueid>
    <timestamp>0</timestamp>
    <objtype>23</objtype>
    <objcode>0</objcode>
    <name></name>
    <expr></expr>
    <vpos>16.000</vpos>
    <hpos>8.000</hpos>
    <height>12.000</height>
    <width>9.000</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar></fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>4</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>0</fillred>
    <fillgreen>0</fillgreen>
    <fillblue>0</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface><![CDATA[Courier New]]></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>10</fontsize>
    <mode>0</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>false</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>0</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>false</supalways>
    <supovflow>false</supovflow>
    <suprpcol>0</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid></uniqueid>
    <timestamp>0</timestamp>
    <objtype>23</objtype>
    <objcode>0</objcode>
    <name></name>
    <expr></expr>
    <vpos>16.000</vpos>
    <hpos>6.000</hpos>
    <height>13.000</height>
    <width>35.000</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar></fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>3</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>0</fillred>
    <fillgreen>0</fillgreen>
    <fillblue>0</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface><![CDATA[Arial]]></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>10</fontsize>
    <mode>0</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>false</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>0</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>false</supalways>
    <supovflow>false</supovflow>
    <suprpcol>0</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid></uniqueid>
    <timestamp>0</timestamp>
    <objtype>23</objtype>
    <objcode>0</objcode>
    <name></name>
    <expr></expr>
    <vpos>16.000</vpos>
    <hpos>6.000</hpos>
    <height>13.000</height>
    <width>35.000</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar></fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>3</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>0</fillred>
    <fillgreen>0</fillgreen>
    <fillblue>0</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface><![CDATA[Arial]]></fontface>
    <fontstyle>1</fontstyle>
    <fontsize>10</fontsize>
    <mode>0</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>false</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>0</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>false</supalways>
    <supovflow>false</supovflow>
    <suprpcol>0</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
  <tempcursor>
    <platform>WINDOWS</platform>
    <uniqueid></uniqueid>
    <timestamp>0</timestamp>
    <objtype>25</objtype>
    <objcode>0</objcode>
    <name><![CDATA[dataenvironment]]></name>
    <expr><![CDATA[Top = 0
Left = 0
Width = 0
Height = 0
DataSource = .NULL.
Name = "Dataenvironment"
]]></expr>
    <vpos>0</vpos>
    <hpos>0</hpos>
    <height>0</height>
    <width>0</width>
    <style></style>
    <picture></picture>
    <order></order>
    <unique>false</unique>
    <comment></comment>
    <environ>false</environ>
    <boxchar></boxchar>
    <fillchar></fillchar>
    <tag></tag>
    <tag2></tag2>
    <penred>0</penred>
    <pengreen>0</pengreen>
    <penblue>0</penblue>
    <fillred>0</fillred>
    <fillgreen>0</fillgreen>
    <fillblue>0</fillblue>
    <pensize>0</pensize>
    <penpat>0</penpat>
    <fillpat>0</fillpat>
    <fontface></fontface>
    <fontstyle>0</fontstyle>
    <fontsize>0</fontsize>
    <mode>0</mode>
    <ruler>0</ruler>
    <rulerlines>0</rulerlines>
    <grid>false</grid>
    <gridv>0</gridv>
    <gridh>0</gridh>
    <float>false</float>
    <stretch>false</stretch>
    <stretchtop>false</stretchtop>
    <top>false</top>
    <bottom>false</bottom>
    <suptype>0</suptype>
    <suprest>0</suprest>
    <norepeat>false</norepeat>
    <resetrpt>0</resetrpt>
    <pagebreak>false</pagebreak>
    <colbreak>false</colbreak>
    <resetpage>false</resetpage>
    <general>0</general>
    <spacing>0</spacing>
    <double>false</double>
    <swapheader>false</swapheader>
    <swapfooter>false</swapfooter>
    <ejectbefor>false</ejectbefor>
    <ejectafter>false</ejectafter>
    <plain>false</plain>
    <summary>false</summary>
    <addalias>false</addalias>
    <offset>0</offset>
    <topmargin>0</topmargin>
    <botmargin>0</botmargin>
    <totaltype>0</totaltype>
    <resettotal>0</resettotal>
    <resoid>0</resoid>
    <curpos>false</curpos>
    <supalways>false</supalways>
    <supovflow>false</supovflow>
    <suprpcol>0</suprpcol>
    <supgroup>0</supgroup>
    <supvalchng>false</supvalchng>
    <supexpr></supexpr>
    <user></user>
  </tempcursor>
</VFPData>
    ENDTEXT
    lcText = ALLTRIM(lcText)
    STRTOFILE(lcText,lcFileName,0)
    RETURN lcFileName
    ***************************************************
  ENDPROC
  ***************************************************


  ***************************************************
  PROCEDURE INIT
    ***************************************************
    LPARAMETERS tcText AS STRING, ;
      tcHeader AS STRING, ;
      tcFontName AS STRING, ;
      tnFontSize AS INTEGER, ;
      tlFontBold AS Boolean, ;
      tlFontItalic AS Boolean

    SET CENTURY ON
    SET CENTURY TO
    SET CPDIALOG OFF
    SET DELETED ON
    SET EXCLUSIVE OFF
    SET HOURS TO 24
    SET MULTILOCKS ON
    SET NOTIFY OFF
    SET SAFETY OFF
    SET TALK OFF

    *
    *  create the cursor for the report
    *
    CREATE CURSOR C_TextBlock (TheText M, TheHeader C(254))
    SELECT C_TextBlock
    APPEND BLANK

    *
    *  populate the Detail band
    *
    REPLACE TheText WITH tcText

    *
    *  populate the Header band
    *
    IF VARTYPE(tcHeader) = "C" AND NOT EMPTY(tcHeader)
      REPLACE TheHeader WITH tcHeader
    ELSE
      REPLACE TheHeader WITH SPACE(0)
    ENDIF

    LOCAL lcFRXFile, llError, laError[1], lcSetDatabase, ;
      lnSelect, lcTempFile
    lcSetDatabase = SET("DATABASE")
    lnSelect = SELECT(0)
    lcTempFile = ADDBS(SYS(2023)) + "TempReportTextBlock"
    THIS.ADDPROPERTY("icTempFile",lcTempFile)
    *
    *  generate the .FRX file as an .XML file
    *
    lcFRXFile = THIS.CreateTextBlockFRX()
    XMLTOCURSOR(lcFRXFile,"Temp",512)
    SELECT Temp
    SET DATABASE TO
    *
    *  turn the .XML file/cursor into a temporary table
    *
    COPY TO (lcTempFile+".DBF")
    USE IN Temp
    ERASE (lcFRXFile)
    ERASE (lcTempFile+".FRX")   &&& just in case
    ERASE (lcTempFile+".FRT")   &&& just in case
    *
    *  turn the temporary table into an .FRX
    *
    RENAME (lcTempFile+".DBF") TO (lcTempFile+".FRX")
    RENAME (lcTempFile+".FPT") TO (lcTempFile+".FRT")
    ERASE (lcTempFile+".DBF")   &&& just in case
    ERASE (lcTempFile+".FPT")   &&& just in case
    *
    *  open the .FRX as a table so we can update fields
    *
    USE (lcTempFile+".FRX") IN 0 ALIAS TempReport
    SELECT TempReport

    *
    *  update the FontName attribute for all objects
    *
    IF VARTYPE(tcFontName) = "C" AND NOT EMPTY(tcFontName)
      REPLACE ALL FontFace WITH tcFontName FOR NOT EMPTY(FontFace)
    ENDIF

    *
    *  update the other font attributes of the Detail
    *  Band object in the report form, if passed
    *
    LOCATE FOR "THETEXT" $ UPPER(EXPR)
    IF VARTYPE(tnFontSize) = "N" AND tnFontSize > 3
      REPLACE FONTSIZE WITH tnFontSize
    ENDIF
    REPLACE FontStyle WITH 0
    DO CASE
      CASE VARTYPE(tlFontBold) = "L" AND tlFontBold ;
          AND VARTYPE(tlFontItalic) = "L" AND tlFontItalic
        REPLACE FontStyle WITH 3
      CASE VARTYPE(tlFontItalic) = "L" AND tlFontItalic
        REPLACE FontStyle WITH 2
      CASE VARTYPE(tlFontBold) = "L" AND tlFontBold
        REPLACE FontStyle WITH 1
    ENDCASE
    *
    *  close it so we can run the report from the .FRX
    *
    USE IN TempReport

    SELECT C_TextBlock

    llError = .F.
    TRY
      REPORT FORM (lcTempFile+".FRX") NOCONSOLE TO PRINTER PROMPT
    CATCH
      llError = .T.
    ENDTRY
    IF llError
      AERROR(laError)
      MESSAGEBOX("Unable to print " + ;
        IIF(VARTYPE(tcHeader)="C" AND NOT EMPTY(tcHeader),ALLTRIM(tcHeader),SPACE(0)) + ;
        " because of this VFP error:" + ;
        CHR(13) + ;
        laError[2], ;
        48, ;
        "Unable to print")
    ENDIF

    USE IN C_TextBlock

    ERASE (lcTempFile+".FRX")
    ERASE (lcTempFile+".FRT")

    SET DATABASE TO &lcSetDatabase
    SELECT (lnSelect)
    ***************************************************
  ENDPROC
  ***************************************************


  ***************************************************
  PROCEDURE DESTROY
    ***************************************************
    USE IN SELECT("C_TextBlock")
    ERASE (THIS.icTempFile+".FRX")
    ERASE (THIS.icTempFile+".FRT")
    DODEFAULT()
  ENDPROC


ENDDEFINE
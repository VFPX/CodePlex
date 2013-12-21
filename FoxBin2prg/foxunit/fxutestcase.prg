***********************************************************************
*	FoxUnit is Copyright (c) 2004 - 2005, Visionpace
*	All rights reserved.
*
*	Redistribution and use in source and binary forms, with or 
*	without modification, are permitted provided that the following 
*	conditions are met:
*
*		*	Redistributions of source code must retain the above
*			copyright notice, this list of conditions and the 
*			following disclaimer.
*
*		*	Redistributions in binary form must reproduce the above 
*			copyright notice, this list of conditions and the 
*			following disclaimer in the documentation and/or other 
*			materials provided with the distribution. 
*			
*		*	The names Visionpace and Vision Data Solutions, Inc. 
*			(including similar derivations thereof) as well as
*			the names of any FoxUnit contributors may not be used 
*			to endorse or promote products which were developed
*			utilizing the FoxUnit software unless specific, prior, 
*			written permission has been obtained.
*
*	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
*	"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
*	LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
*	FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
*	COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
*	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
*	BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
*	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
*	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
*	LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
*	ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
*	POSSIBILITY OF SUCH DAMAGE.  
***********************************************************************
LPARAMETERS toTestResult as FxuTestResult of FxuTestResult.prg

RETURN CREATEOBJECT("FxuTestCase",toTestResult)

**********************************************************************
DEFINE CLASS FxuTestCase As FxuTest OF FxuTest.Prg
**********************************************************************

	#IF .f.
		LOCAL this as FxuTestCase OF FxuTestCase.prg
	#ENDIF

	icCurrentTest = ""
	ioTestResult = .NULL.
	ilAllowDebug = .f.
	ilQueryTests = .f.
	ilSuccess = .t.
	inReturnCode = 0
	ioAssert = .f.
	icTestPrefix = "TEST"
	HIDDEN ilTestingModalForm 

	********************************************************************
	FUNCTION INIT(toTestResult)
	********************************************************************
		
		ilTestingModalForm = .f.
		
		IF VERSION(5) < 900
			LOCAL laStackInfo[1]
			IF ASTACKINFO(laStackInfo) > 0
				IF ASCAN(laStackInfo,"FXUInheritsFromFXUTestCase",1,-1,3,15)>0
				*
				*  don't proceed with this method if this 
				*  object is being instantiated from 
				*  FXUInheritsFromFXUTestCase.PRG, to test
				*  its inheritance
				*
				*  MODIFY COMMAND FXUInheritsFromFXUTestCase
				*
				RETURN .t.
				ENDIF
				RELEASE laStackInfo
			ENDIF
		ENDIF

	
		IF VARTYPE(toTestResult) != "O"
			this.ilQueryTests = .t.
		ELSE
			IF UPPER(toTestResult.Class) == "FXUTESTRESULT"
				this.ioTestResult = toTestResult
			ELSE
				RETURN .f.
			ENDIF
		ENDIF
		
		this.icCurrentTest = this.ioTestResult.icCurrentTestName
			
		RETURN .t.
	
	********************************************************************
	ENDFUNC
	********************************************************************

	********************************************************************
	FUNCTION Run()
	********************************************************************
		LOCAL loEx as Exception
		
		this.ioAssert = .f.
		this.ioAssert = FxuNewObject("FxuAssertions")
		this.ioAssert.ioTestResult = this.ioTestResult
		
*		this.ioTestResult.icCurrentStartTime = timestamp()
		this.ioTestResult.inCurrentStartSeconds = SECONDS()
		
		IF this.ilAllowDebug
			this.RunWithSetupTeardownDebugging()
		ELSE
		
			

			TRY
				
				this.SetUp()
				this.RunTest()
				*this.TearDown()
			
			CATCH TO loEx
			
				LOCAL ARRAY laStackInfo[1,1]
				=ASTACKINFO(laStackInfo)
				this.HandleException(loEx,@laStackInfo,.f.)
				
			FINALLY
			
				TRY
				
					this.TearDown()
				
				CATCH TO loEx
				
					LOCAL ARRAY laStackInfo[1,1]
					=ASTACKINFO(laStackInfo)
					this.HandleException(loEx,@laStackInfo,.t.)
				
				ENDTRY 
			
			ENDTRY

		ENDIF
		
		
		this.ioTestResult.inCurrentEndSeconds = SECONDS()
		this.ioTestResult.LogResult()
		this.PostTearDown()
	
	********************************************************************
	ENDFUNC
	********************************************************************

	********************************************************************
	PROTECTED FUNCTION RunWithSetupTeardownDebugging
	********************************************************************
	
		LOCAL loEx as Exception
	
		this.Setup()
	
		TRY
		
			this.RunTest()	
		
		CATCH TO loEx
		
			LOCAL ARRAY laStackInfo[1,1]
			=ASTACKINFO(laStackInfo)
			this.HandleException(loEx,@laStackInfo)
		
		ENDTRY
		
		this.TearDown()
		
		RETURN 
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	
	********************************************************************
	FUNCTION SetForModalFormTest()
	********************************************************************

		
		IF VARTYPE(goFoxUnitForm) == "O" AND goFoxUnitForm.Visible
		
			this.ilTestingModalForm = .t.
			goFoxUnitForm.Visible = .f.
		
		ENDIF 
		

	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	
	********************************************************************
	HIDDEN FUNCTION PostTearDown()
	********************************************************************
	
		IF this.ilTestingModalForm
		
			IF VARTYPE(goFoxUnitForm) == "O" AND !goFoxUnitForm.Visible
			
				goFoxUnitForm.Visible = .t.
			
			ENDIF 
		
		ENDIF 
	
	********************************************************************
	ENDFUNC
	********************************************************************

	********************************************************************
	FUNCTION SetUp() && Abstract Method
	********************************************************************
	
	
	
	********************************************************************
	ENDFUNC
	********************************************************************

	********************************************************************
	FUNCTION RunTest()
	********************************************************************
	
		LOCAL lcCurrentTest
		lcCurrentTest = "this." + this.icCurrentTest + "()"
		
		&lcCurrentTest
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION TearDown() && Abstract Method
	********************************************************************
	
	
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION ilSuccess_Assign(tlSuccess)
	********************************************************************
	
		this.ioTestResult.ilCurrentResult = tlSuccess
		this.ilSuccess = tlSuccess
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
  * Swapped message and expression parameter order. HAS
	FUNCTION AssertEquals(tuExpectedValue, tuExpression, tcMessage, tuNonCaseSensitiveStringComparison)
	********************************************************************

		LOCAL llNonCaseSensitiveStringComparison
		llNonCaseSensitiveStringComparison = .f. 
		
		IF VARTYPE( tuNonCaseSensitiveStringComparison ) == "L"
			llNonCaseSensitiveStringComparison = tuNonCaseSensitiveStringComparison  
		ENDIF  

		this.ioAssert.AssertEquals(tcMessage, tuExpectedValue, tuExpression, llNonCaseSensitiveStringComparison)

	********************************************************************
	ENDFUNC
	********************************************************************

	********************************************************************
  * Swapped message and expression parameter order. HAS
	FUNCTION AssertTrue(tuExpression, tcMessage)
	********************************************************************
	
		this.ioAssert.AssertTrue(tcMessage, tuExpression)
	
	********************************************************************
	ENDFUNC
	********************************************************************

  ********************************************************************
  * Swapped message and expression parameter order. HAS
  FUNCTION AssertFalse(tuExpression, tcMessage)  && Added by HAS
  ********************************************************************
  
    this.ioAssert.AssertFalse(tcMessage, tuExpression)
  
  ********************************************************************
  ENDFUNC
  ********************************************************************

	********************************************************************
  * Swapped message and expression parameter order. HAS
	FUNCTION AssertNotNull(tuExpression, tcMessage)
	********************************************************************
	
		this.ioAssert.AssertNotNull(tcMessage, tuExpression)
	
	********************************************************************
	ENDFUNC
	********************************************************************

  ********************************************************************
  * Swapped message and expression parameter order. HAS
  FUNCTION AssertNotEmpty(tuExpression, tcMessage)
  ********************************************************************
  
    this.ioAssert.AssertNotEmpty(tcMessage, tuExpression)
  
  ********************************************************************
  ENDFUNC
  ********************************************************************


  ********************************************************************
  * Swapped message and expression parameter order. HAS
  FUNCTION AssertNotNullOrEmpty(tuExpression, tcMessage) && Added by HAS
  ********************************************************************
  
    this.ioAssert.AssertNotNullOrEmpty(tcMessage, tuExpression)
  
  ********************************************************************
  ENDFUNC
  ********************************************************************
	

	********************************************************************
	FUNCTION MessageOut(tcMessage)
	********************************************************************
		IF PCOUNT() = 0
			tcMessage = CHR(10)
		ENDIF 
		this.ioTestResult.LogMessage(tcMessage)
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION HandleException(toEx as Exception, taStackInfo, tlTearDownException)
	********************************************************************
	
		LOCAL loExceptionInfo as FxuResultExceptionInfo OF FxuResultExceptionInfo.prg
		loExceptionInfo = FxuNewObject('FxuResultExceptionInfo')
		loExceptionInfo.SetExceptionInfo(toEx,@taStackInfo)
		*this.ioTestResult.ioException = toEx
		*this.ioTestResult.LogException(toEx)
		this.ioTestResult.LogException(loExceptionInfo, tlTearDownException)
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
**********************************************************************
ENDDEFINE && CLASS
**********************************************************************
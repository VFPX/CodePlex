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


RETURN CREATEOBJECT("FxuAssertions")

**********************************************************************
DEFINE CLASS FxuAssertions As FxuCustom OF FxuCustom.prg
**********************************************************************

	#IF .f.
		LOCAL this as FxuAssertions OF FxuAssertions.prg
	#ENDIF
	
	ioTestResult = .NULL.
	icFailureMessage = ''
	ilNotifyListener = .f.
	ilSuccess = .t.
	
	
	********************************************************************
	FUNCTION ilSuccess_Assign(tlSuccess)
	********************************************************************
	
		IF this.ilSuccess
			this.ilSuccess = tlSuccess
		ENDIF
		
		IF this.ilNotifyListener
			this.ioTestResult.ilCurrentResult = this.ilSuccess
		ENDIF
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION ioTestResult_Assign(tuResult)
	********************************************************************
	
		LOCAL llNotifyListener
		llNotifyListener = .f.
		
		IF VARTYPE(tuResult) == "O"
			IF UPPER(tuResult.Class) == "FXUTESTRESULT"
				llNotifyListener = .t.
			ENDIF
		ENDIF
	
		this.ilNotifyListener = llNotifyListener
		
		this.ioTestResult = tuResult
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION AssertEquals(tcMessage, tuItem1, tuItem2, tuNonCaseSensitiveStringCompare)
	********************************************************************
		
		LOCAL llAssertEquals, llNonCaseSensitiveStringCompare
		* Assume we do not equal unless otherwise determined
		llAssertEquals = .f.
		llNonCaseSensitiveStringCompare = .f. 
		
		* Trap for non case-sensitive string compare
    
    *BUG This is bogus, because the pcount() will always equal 4. HAS
    * Commented as useless. HAS    
*!*  		IF PCOUNT() = 4
*!*  			IF VARTYPE( tuNonCaseSensitiveStringCompare ) == "L"
*!*  				llNonCaseSensitiveStringCompare = tuNonCaseSensitiveStringCompare 
*!*  			ENDIF 
*!*  		ENDIF
		
		* Trap for no message passed
		IF PCOUNT() = 2
			tuItem2 = tuItem1
			tuItem1 = tcMessage
			tcMessage = ""
		ENDIF
		
		* Determine if we are comparing objects or value types
		IF this.IsObject(tuItem1) AND this.IsObject(tuItem2)
			llAssertEquals = this.AssertEqualsObjects(tcMessage,tuItem1,tuItem2)
		ELSE
			llAssertEquals = this.AssertEqualsValues(tcMessage, tuItem1, tuItem2, llNonCaseSensitiveStringCompare)
		ENDIF
		
		this.ilSuccess = llAssertEquals
		RETURN llAssertEquals
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION AssertEqualsValues(tcMessage, tuItem1, tuItem2, tuNonCaseSensitiveStringCompare)
	********************************************************************
	
		LOCAL llAssertEqualsValues, llTypesMatch, lcItem1Type, lcItem2Type
		llAssertEqualsValues = .f.
		
		lcItem1Type = VARTYPE(tuItem1)
		lcItem2type = VARTYPE(tuItem2)
		
		IF lcItem1Type != lcItem2Type
			this.ReportTypeMismatch(tcMessage, tuItem1, tuItem2)
			RETURN llAssertEqualsValues
		ENDIF
		
		 
		IF tuNonCaseSensitiveStringCompare AND lcItem1Type == "C"
			
			IF !UPPER(tuItem1) == UPPER(tuItem2)
				this.ReportValuesNotEqual(tcMessage + " (Non Case Sensitive String Comparison) ", tuItem1, tuItem2)
				RETURN llAssertEqualsValues 
			ENDIF
			
		ELSE
		
			IF !tuItem1 == tuItem2
				this.ReportValuesNotEqual(tcMessage, tuItem1, tuItem2)
				RETURN llAssertEqualsValues
			ENDIF
		
		ENDIF 
		
		llAssertEqualsValues = .t.
		
		RETURN llAssertEqualsValues
		
		
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION AssertEqualsObjects(tcMessage, tuItem1, tuItem2)
	********************************************************************
	
		LOCAL llAssertEqualsObjects
		llAssertEqualsObjects = .f.
		
		IF !COMPOBJ(tuItem1, tuItem2)
			this.ReportObjectsNotSame(tcMessage)
		ELSE
			llAssertEqualsObjects = .t.
		ENDIF
		
		RETURN llAssertEqualsObjects
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION AssertTrue(tcMessage, tuItem)
	********************************************************************
	
		LOCAL llAssertTrue
		llAssertTrue = .f.
		
		* Trap for no message passed
    *BUG Commented as useless. HAS
*!*  		IF PCOUNT() = 1
*!*  			tuItem = tcMessage
*!*  			tcMessage = ""
*!*  		ENDIF

		IF !tuItem
			this.ReportAssertionFalse(tcMessage)
		ELSE
			llAssertTrue = .t.
		ENDIF
		
		this.ilSuccess = llAssertTrue
		RETURN llAssertTrue
	
	********************************************************************
	ENDFUNC
	********************************************************************
  
  ********************************************************************
  FUNCTION AssertFalse(tcMessage, tuItem) && Added by HAS
  ********************************************************************
  
    LOCAL llAssertFalse
    llAssertFalse = .f.

    IF tuItem
      this.ReportAssertionTrue(tcMessage)
    ELSE
      llAssertFalse = .t.
    ENDIF
    
    this.ilSuccess = llAssertFalse
    RETURN llAssertFalse
  
  ********************************************************************
  ENDFUNC
  ********************************************************************
	
	********************************************************************
	FUNCTION AssertNotNull(tcMessage, tuItem)
	********************************************************************
	
		LOCAL llAssertNotNull
		llAssertNotNull = .f.
	
		* Trap for no message passed
    *BUG Commented as useless. HAS
*!*  		IF PCOUNT() = 1
*!*  			tuItem = tcMessage
*!*  			tcMessage = ""
*!*  		ENDIF
		
		IF ISNULL(tuItem)
			this.ReportIsNull(tcMessage)
		ELSE
			llAssertNotNull = .t.
		ENDIF
		
		this.ilSuccess = llAssertNotNull
		
		RETURN llAssertNotNull
	
	********************************************************************
	ENDFUNC
	********************************************************************
  
  ********************************************************************
  FUNCTION AssertNotEmpty(tcMessage, tuItem) && Added by HAS
  ********************************************************************
  
    LOCAL llAssertNotEmpty  
    llAssertNotEmpty  = .f.
      
    IF EMPTY(tuItem)
      this.ReportIsEmpty(tcMessage)
    ELSE
      llAssertNotEmpty  = .t.
    ENDIF
    
    this.ilSuccess = llAssertNotEmpty  
    
    RETURN llAssertNotEmpty  
  
  ********************************************************************
  ENDFUNC
  ********************************************************************
  
  ********************************************************************
  FUNCTION AssertNotNullOrEmpty(tcMessage, tuItem) && Added by HAS
  ********************************************************************
  
    LOCAL llAssertNotNullOrEmpty 
    llAssertNotNullOrEmpty = .f.
    
    IF this.IsObject(tuItem) OR ISNULL(tuItem)
    
      llAssertNotNullOrEmpty = this.AssertNotNull(tcMessage, tuItem)

    ELSE
    
      llAssertNotNullOrEmpty = this.AssertNotEmpty(tcMessage, tuItem)

    ENDIF
    
    RETURN llAssertNotNullOrEmpty 
  
  ********************************************************************
  ENDFUNC
  ********************************************************************
	
	********************************************************************
	PROTECTED FUNCTION IsObject(tuObject)
	********************************************************************
	
		LOCAL llIsObject
		llIsObject = .f.
	
		IF VARTYPE(tuObject) = "O"
			llIsObject = .t.
		ENDIF
		
		RETURN llIsObject
		
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	PROTECTED FUNCTION EnumerateVarType(tcVarType)
	********************************************************************
	
		lcReturnType = "Unknown"
		
		lcVarType = UPPER(ALLTRIM(tcVarType))
		
		DO case
		
			CASE lcVarType == "C" 
				lcReturnType = "Character"
			CASE lcVarType == "N"
				lcReturnType =	"Numeric"
			CASE lcVarType == "Y"
				lcReturnType = "Currency"
			CASE lcVarType == "L"
				lcReturnType = "Logical"
			CASE lcVarType == "O"
				lcReturnType = "Object"
			CASE lcVarType == "G"
				lcReturnType = "General"
			CASE lcVarType == "D"
				lcReturnType = "Date"
			CASE lcVarType == "T"
				lcReturnType = "DateTime "
			CASE lcVarType == "X"
				lcReturnType = "Null"
				
		ENDCASE
		
		RETURN lcReturnType
	
	********************************************************************
	ENDFUNC
	********************************************************************

	********************************************************************
	FUNCTION ClearAssert
	********************************************************************
	
		this.icFailureMessage = ''
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION ReportIsNull(tcMessage)
	********************************************************************
	
		this.NewMessageDivider(.t.)
		this.AddMessage(tcMessage)
		this.AddMessage("Item is Null")
	
	********************************************************************
	ENDFUNC
	********************************************************************
  
  ********************************************************************
  FUNCTION ReportIsEmpty(tcMessage) && Added by HAS
  ********************************************************************
  
    this.NewMessageDivider(.t.)
    this.AddMessage(tcMessage)
    this.AddMessage("Item is Empty")
  
  ********************************************************************
  ENDFUNC
  ********************************************************************
	
	********************************************************************
	FUNCTION ReportObjectsNotSame(tcMessage)
	********************************************************************
	
		this.NewMessageDivider(.t.)
		this.AddMessage(tcMessage)
		this.AddMessage("Objects are not the same")
		
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION ReportTypeMismatch(tcMessage, tuItem1, tuItem2)
	********************************************************************
	
		LOCAL lcReportType1, lcReportType2, lcValue1, lcValue2
		lcReportType1 = this.EnumerateVarType(VARTYPE(tuItem1))
		lcReportType2 = this.EnumerateVarType(VARTYPE(tuItem2))
		
		lcValue1 = TRANSFORM(tuItem1)
		lcValue2 = TRANSFORM(tuItem2)
		
		this.NewMessageDivider(.t.)
		this.AddMessage(tcMessage)
		this.AddMessage("Value Type Mismatch")
		this.AddMessage("Expected Type:" + lcReportType1 + " Expected Value:" + lcValue1)
		this.AddMessage("Actual Type:" + lcReportType2 + " Actual Value:" + lcValue2)
		
		RETURN
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION ReportValuesNotEqual(tcMessage, tuItem1, tuItem2)
	********************************************************************
	
		LOCAL lcValue1, lcValue2
		this.NewMessageDivider(.t.)
		this.AddMessage(tcMessage)
		this.AddMessage("Values Not Equal")
		this.AddMessage("Expected Value: " + TRANSFORM(tuItem1))
		this.AddMessage("Actual Value: " + TRANSFORM(tuItem2))
		
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION ReportAssertionFalse(tcMessage)
	********************************************************************
	
		this.NewMessageDivider(.t.)
		this.AddMessage(tcMessage)
		this.AddMessage("AssertTrue Returned False")
	
	********************************************************************
	ENDFUNC
	********************************************************************
  
  ********************************************************************
  FUNCTION ReportAssertionTrue(tcMessage) && Added by HAS
  ********************************************************************
  
    this.NewMessageDivider(.t.)
    this.AddMessage(tcMessage)
    this.AddMessage("AssertFalse Returned True")
  
  ********************************************************************
  ENDFUNC
  ********************************************************************
	

	********************************************************************
	FUNCTION AddMessage(tcMessage)
	********************************************************************
	
		IF EMPTY(tcMessage)
			RETURN
		ENDIF
		
		IF !EMPTY(this.icFailureMessage)
			this.icFailureMessage = this.icFailureMessage + CHR(10)
		ENDIF
		
		this.icFailureMessage = this.icFailureMessage + tcMessage
		
		IF this.ilNotifyListener
			this.ioTestResult.icFailureErrorDetails = this.icFailureMessage
		ENDIF
		
		RETURN
	
	********************************************************************
	ENDFUNC
	********************************************************************
	
	********************************************************************
	FUNCTION NewMessageDivider(tlAssertionFailure)
	********************************************************************
	
		IF !EMPTY(tlAssertionFailure)
			tlAssertionFailure = .t.
		ELSE
			tlAssertionFailure = .f.
		ENDIF
		
		this.AddMessage("-------------------------------")
		IF tlAssertionFailure
			this.AddMessage("------Assertion Failure")
			this.AddMessage("-------------------------------")
		ENDIF
		
		RETURN
	
	********************************************************************
	ENDFUNC
	********************************************************************

**********************************************************************
ENDDEFINE && CLASS
**********************************************************************
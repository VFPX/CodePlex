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

RETURN CREATEOBJECT("FxuNewTestClass")

**********************************************************************
DEFINE CLASS FxuNewTestClass as FxuCustom OF FxuCustom.prg
**********************************************************************

	#IF .f.
		LOCAL this as FxuNewTestClass OF FxuNewTestClass.prg
	#ENDIF
	
	icTemplateContents = SPACE(0)
	ilTabs = .t.
	ilFunction = .t.
	
	********************************************************************
	FUNCTION CreateNewTestClass(tcClassName)
	********************************************************************
	    *
	    *  called from FXUResultData.PRG/FXUResultData::CreateNewTestCaseClass()
	    *    XXDTES("FXURESULTDATA.PRG","loTestClassCreator.CreateNewTestClass(")
	    *
		tcClassName = ALLTRIM(m.tcClassName)
	
        LOCAL lcFullPathToClass, lcJustClassName
	    IF UPPER(JUSTFNAME(m.tcClassName)) == UPPER(m.tcClassName)
	      *
	      *  only filename was passed, no path 
	      *
	      *  note that this code is never called at the moment,
	      *  because when FoxUnit.SCX/cmdCreateNewTestClass.Click()
	      *  calls FXUResultsData/ResultsData::CreateNewTestCaseClass()
	      *  and it calls here, it always passes the filename
	      *  including the full path
	      *
  		  LOCAL lcJustClassName
		  lcJustClassName = JUSTSTEM(m.tcClassName)
		  lcFullPathToClass = CURDIR() + m.tcClassName + ".PRG"
  		  IF FILE(lcFullPathToClass)
			THIS.icLastErrorMessage = "Program File " + lcFullPathToClass + " already exists."
			RETURN .f.
		  ENDIF
		 ELSE
		  lcFullPathToClass = m.tcClassName
		  lcJustClassName = JUSTSTEM(m.lcFullPathToClass)
		ENDIF 

		*
		*  tcClassName is the name of the new file we're
		*  supposed to create -- now figure out what 
		*  template/.PRG to base the new test class on
		*

		PRIVATE pcTemplate
		pcTemplate = SPACE(0)
		LOCAL loDialog
		
*!*			loDialog = NEWOBJECT("frmGetTestClassTemplate", ;
*!*	        		             "FXU.VCX", ;
*!*	                		     "", ;
*!*			                     m.lcFullpathToClass, ;
*!*	        		             "pcTemplate")         
		loDialog = FXUNEWOBJECT("fxuGetTestClassTemplateDialog", ;
   		                        m.lcFullpathToClass, ;
        		                "pcTemplate")         
		loDialog.Show()

		IF ISNULL(m.pcTemplate)
		  RETURN .f.
		ENDIF

		pcTemplate = UPPER(ALLTRIM(m.pcTemplate))
		LOCAL lcTabs, lcFunction
		lcFunction = ALLTRIM(GETWORDNUM(m.pcTemplate,2,","))
		lcTabs = ALLTRIM(GETWORDNUM(m.pcTemplate,3,","))
		DO CASE
		  CASE m.lcFunction = "FUNCTION"
		    THIS.ilFunction = .t.
		  CASE m.lcFunction = "PROCEDURE"
		    THIS.ilFunction = .f.
		  OTHERWISE
		    THIS.ilFunction = .NULL.
		ENDCASE
		DO CASE
		  CASE m.lcTabs = "TABS"
		    THIS.ilTabs = .t.
		  CASE m.lcTabs = "NOTABS"
		    THIS.ilTabs = .f.
		  OTHERWISE
		    THIS.ilTabs = .NULL.
		ENDCASE

		IF UPPER(JUSTEXT(m.pcTemplate)) = "TXT"
		  *
          *  user selected an existing test case class
          *  .TXT template to copy as the starting point
          *
		  pcTemplate = GETWORDNUM(m.pcTemplate,1,",")
		  IF THIS.LoadNewTestClassTemplate(m.pcTemplate)
			THIS.MergeClassName(m.lcJustClassName)
			STRTOFILE(THIS.icTemplateContents,m.lcFullPathToClass)
		  ENDIF
          THIS.ProcessTabsAndFunction(m.lcFullPathToClass)
		 ELSE		
		  *
          *  user selected an existing test case class
          *  .PRG to copy as the starting point
          *
		  pcTemplate = GETWORDNUM(m.pcTemplate,1,",")
		  IF THIS.LoadExistingClassProgram(m.pcTemplate)
			THIS.MergeClassName(m.lcJustClassName)
			STRTOFILE(THIS.icTemplateContents,m.lcFullPathToClass)
		  ENDIF
		ENDIF

		RELEASE pcTemplate

		RETURN .t.
	
	********************************************************************
	ENDFUNC
	********************************************************************

	
	********************************************************************
	FUNCTION MergeClassName(tcJustClassName)
	********************************************************************
	
		THIS.icTemplateContents = STRTRAN(THIS.icTemplateContents,"<<testclass>>",tcJustClassName)
	
	********************************************************************
	ENDFUNC
	********************************************************************

	
	********************************************************************
	FUNCTION LoadNewTestClassTemplate(m.tcClassTemplate)
	********************************************************************
	
		LOCAL lcClassTemplate, lcClassTemplateFullPath, llTemplateLoaded
		
		llTemplateLoaded = .f.
        IF VARTYPE(m.tcClassTemplate) = "C" ;
             AND NOT EMPTY(m.tcClassTemplate)
          lcClassTemplate = UPPER(ALLTRIM(m.tcClassTemplate))
         ELSE
		  lcClassTemplate = UPPER(FULLPATH("FxuTestCaseTemplate.TXT"))
		ENDIF
		
		lcClassTemplateFullPath = LOCFILE(m.lcClassTemplate,".txt","Find " + m.lcClassTemplate)
		
		IF NOT EMPTY(m.lcClassTemplateFullPath) ;
		     AND FILE(lcClassTemplateFullPath) 
				
				THIS.icTemplateContents = FILETOSTR(m.lcClassTemplateFullPath)
				llTemplateLoaded = .t.
						
		ENDIF
		
		RETURN m.llTemplateLoaded
	
	********************************************************************
	ENDFUNC
	********************************************************************


	********************************************************************
	FUNCTION LoadExistingClassProgram(m.tcClassPRG)
	********************************************************************
	
		LOCAL lcClassPRG, lcClassPRGFullPath, llLoaded
		
		llLoaded = .f.

        lcClassPRG = UPPER(ALLTRIM(m.tcClassPRG))
		
		lcClassPRGFullPath = LOCFILE(m.lcClassPRG,".PRG","Find " + m.lcClassPRG)
		
		IF NOT EMPTY(m.lcClassPRGFullPath) AND FILE(m.lcClassPRGFullPath) 
				
			THIS.icTemplateContents = FILETOSTR(m.lcClassPRGFullPath)
			llLoaded = .t.
						
		ENDIF

		IF m.llLoaded
			*
			*  update the DEFINE CLASS line to replace the
			*  replace the class name with <<test class>>
			*
			LOCAL lcLine, laLines[1], lcClassName, xx
			ALINES(laLines,THIS.icTemplateContents)
			FOR xx = 1 TO ALEN(laLines,1)
			  lcLine = laLines[m.xx]
			  IF UPPER(ALLTRIM(m.lcLine)) = "DEFINE CLASS "
			    lcClassName = GETWORDNUM(ALLTRIM(m.lcLine),3)
			    EXIT 
			  ENDIF
			ENDFOR
            IF EMPTY(m.lcClassName)
              m.llLoaded = .f.
             ELSE
  			  THIS.icTemplateContents = STRTRAN(THIS.icTemplateContents, ;
			                                    SPACE(1) + m.lcClassName + SPACE(1), ;
			                                    " <<testclass>> ", ;
			                                    -1, ;
			                                    -1, ;
			                                    1)
  			  THIS.icTemplateContents = STRTRAN(THIS.icTemplateContents, ;
			                                    SPACE(1) + m.lcClassName + ".PRG", ;
			                                    " <<testclass>>.PRG", ;
			                                    -1, ;
			                                    -1, ;
			                                    1)
			ENDIF			
		ENDIF

		RETURN m.llLoaded
	
	********************************************************************
	ENDFUNC
	********************************************************************


	********************************************************************
	FUNCTION ProcessTabsAndFunction(m.tcClassPRG)
	********************************************************************
      IF ISNULL(THIS.ilTabs) AND ISNULL(THIS.ilFunction) 
        RETURN
      ENDIF
      
      IF THIS.ilTabs AND THIS.ilFunction
        *  the FXU templates use TABs and FUNCTION, 
        *  so there's nothing to do
      ENDIF
      
      LOCAL laLines[1], xx, lcLine
      ALINES(laLines,FILETOSTR(m.tcClassPRG))

      IF NOT THIS.ilTabs
        *  remove the {TAB} indentation
        FOR xx = 1 TO ALEN(laLines,1)
          lcLine = laLines[m.xx]
          IF LEFTC(m.lcLine,1) = CHR(9)
            laLines[m.xx] = SUBSTRC(m.lcLine,2)
          ENDIF
        ENDFOR
      ENDIF

      IF NOT THIS.ilFunction
        *  replace FUNCTION with PROCEDURE
        FOR xx = 1 TO ALEN(laLines,1)
          lcLine = ALLTRIM(laLines[m.xx])
		  DO CASE
		    CASE m.lcLine = "FUNCTION "
              lcLine = STRTRAN(m.lcLine,"FUNCTION ","PROCEDURE ",1,1,1)
            CASE UPPER(ALLTRIM(m.lcLine)) = "ENDFUNC"
              lcLine = "ENDPROC"
		    CASE m.lcLine = "*!*" AND CHR(9)+"FUNCTION " $ UPPER(m.lcLine)
              lcLine = STRTRAN(m.lcLine,"FUNCTION ","PROCEDURE ",1,1,1)
		    CASE m.lcLine = "*!*" AND CHR(9)+"ENDFUNC" $ UPPER(m.lcLine)
              lcLine = STRTRAN(m.lcLine,"ENDFUNC","ENDPROC",1,1,1)
		  ENDCASE
		  laLines[m.xx] = m.lcLine          
        ENDFOR
      ENDIF

      ERASE (m.tcClassPRG)
      FOR EACH lcLine IN laLines
        STRTOFILE(m.lcLine + CHR(13) + CHR(10),m.tcClassPRG,.t.)
      ENDFOR

	********************************************************************
	ENDFUNC
	********************************************************************


**********************************************************************
ENDDEFINE && CLASS
**********************************************************************

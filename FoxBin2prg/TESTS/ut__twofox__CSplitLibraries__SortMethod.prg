DEFINE CLASS ut__twofox__CSplitLibraries__SortMethod as FxuTestCase OF FxuTestCase.prg

	#IF .F.
		LOCAL THIS AS ut__twofox__CSplitLibraries__SortMethod OF ut__twofox__CSplitLibraries__SortMethod.PRG
	#ENDIF
	
	#DEFINE C_PROC		'PROCEDURE'
	#DEFINE C_ENDPROC	'ENDPROC'
	#DEFINE C_TEXT		'TEXT'
	#DEFINE C_ENDTEXT	'ENDTEXT'
	icObj = NULL
	
	*******************************************************************************************************************************************
	FUNCTION Setup
		THIS.icObj = NEWOBJECT("CSplitLibraries", "TWOFOX.PRG")

	ENDFUNC

	
	*******************************************************************************************************************************************
	FUNCTION TearDown
		THIS.icObj = NULL
	ENDFUNC


	*******************************************************************************************************************************************
	FUNCTION Evaluate_results
		LPARAMETERS tcExpected_Method, tcResult_Method
		IF PCOUNT() = 0
			THIS.messageout( "* Support method, not a valid test." )
			RETURN .T.
		ENDIF
		
		*-- Some adjusts before comparing
		IF EMPTY(tcExpected_Method)
			tcExpected_Method	= '[' + tcExpected_Method + ']'
		ELSE
			tcExpected_Method	= '[' + tcExpected_Method + CHR(13) + CHR(10) + ']'
		ENDIF
		tcResult_Method		= '[' + tcResult_Method + ']'
		
		THIS.messageout( "Ordered method returned:" + CHR(13) + CHR(10) + tcResult_Method )
		THIS.assertequals( tcExpected_Method, tcResult_Method, "Ordered method" )
	ENDFUNC


	*******************************************************************************************************************************************
	FUNCTION Should_SortMethods_When_SimpleMethodIsGiven
		LOCAL lcMethod, lcExpected_Method, lcResult_Method
		LOCAL loObj AS CSplitLibraries OF "TWOFOX.PRG"
		loObj	= THIS.icObj
		
		*-- Input and expected params
		STORE '' TO lcMethod, lcExpected_Method, lcResult_Method

		TEXT TO lcMethod NOSHOW TEXTMERGE FLAGS 1+0 PRETEXT 1+2+4
			<<C_PROC>> myMethod_B
				*-- myMethod_B
			<<C_ENDPROC>>
			<<C_PROC>> myMethod_A
				*-- myMethod_A
			<<C_ENDPROC>>
		ENDTEXT

		TEXT TO lcExpected_Method NOSHOW TEXTMERGE FLAGS 1+0 PRETEXT 1+2+4
			<<C_PROC>> myMethod_A
				*-- myMethod_A
			<<C_ENDPROC>>
			<<C_PROC>> myMethod_B
				*-- myMethod_B
			<<C_ENDPROC>>
		ENDTEXT
		
		*-- Test
		lcResult_Method	= loObj.sortmethod( lcMethod )
		
		THIS.Evaluate_results( lcExpected_Method, lcResult_Method )
		
	ENDFUNC


	*******************************************************************************************************************************************
	FUNCTION Should_SortMethods_When_ComplexMethodIsGiven
		LOCAL lcMethod, lcExpected_Method, lcResult_Method
		LOCAL loObj AS CSplitLibraries OF "TWOFOX.PRG"
		loObj	= THIS.icObj
		
		*-- Input and expected params
		STORE '' TO lcMethod, lcExpected_Method, lcResult_Method

		TEXT TO lcMethod NOSHOW TEXTMERGE FLAGS 1+0 PRETEXT 1+2+4
			<<C_PROC>> myMethod_B
				*-- myMethod_B
				<<C_TEXT>>
					<<C_PROC>> Simulated_Method_B
					*-- This simulates a Code Generator that wraps a PROC/ENDPROC inside a TEXT/ENDTEXT
					<<C_ENDPROC>>
				<<C_ENDTEXT>>
			<<C_ENDPROC>>
			<<C_PROC>> myMethod_A
				*-- myMethod_A
			<<C_ENDPROC>>
		ENDTEXT

		TEXT TO lcExpected_Method NOSHOW TEXTMERGE FLAGS 1+0 PRETEXT 1+2+4
			<<C_PROC>> myMethod_A
				*-- myMethod_A
			<<C_ENDPROC>>
			<<C_PROC>> myMethod_B
				*-- myMethod_B
				<<C_TEXT>>
					<<C_PROC>> Simulated_Method_B
					*-- This simulates a Code Generator that wraps a PROC/ENDPROC inside a TEXT/ENDTEXT
					<<C_ENDPROC>>
				<<C_ENDTEXT>>
			<<C_ENDPROC>>
		ENDTEXT
		
		*-- Test
		lcResult_Method	= loObj.sortmethod( lcMethod )
		
		THIS.Evaluate_results( lcExpected_Method, lcResult_Method )
		
	ENDFUNC


	*******************************************************************************************************************************************
	FUNCTION Should_Not_SortMethods_When_EmptyMethodIsGiven
		LOCAL lcMethod, lcExpected_Method, lcResult_Method
		LOCAL loObj AS CSplitLibraries OF "TWOFOX.PRG"
		loObj	= THIS.icObj
		
		*-- Input and expected params
		STORE '' TO lcMethod, lcExpected_Method, lcResult_Method
		
		*-- Test
		lcResult_Method	= loObj.sortmethod( lcMethod )
		
		THIS.Evaluate_results( lcExpected_Method, lcResult_Method )
		
	ENDFUNC


ENDDEFINE

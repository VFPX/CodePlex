DEFINE CLASS ut__twofox__CSplitLibraries__SortNames as FxuTestCase OF FxuTestCase.prg

	#IF .F.
		LOCAL THIS AS ut__twofox__CSplitLibraries__SortNames OF ut__twofox__CSplitLibraries__SortNames.PRG
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
		LPARAMETERS tcExpected_Memo, tcResult_Memo

		IF PCOUNT() = 0
			THIS.messageout( "* Support method, not a valid test." )
			RETURN .T.
		ENDIF
		
		*-- Some adjusts before comparing
		IF EMPTY(tcExpected_Memo)
			tcExpected_Memo	= '[' + tcExpected_Memo + ']'
		ELSE
			tcExpected_Memo	= '[' + tcExpected_Memo + CHR(13) + CHR(10) + ']'
		ENDIF
		tcResult_Memo		= '[' + tcResult_Memo + ']'
		
		THIS.messageout( "Ordered Memo returned:" + CHR(13) + CHR(10) + tcResult_Memo )
		THIS.assertequals( tcExpected_Memo, tcResult_Memo, "Ordered Memo" )
	ENDFUNC


	*******************************************************************************************************************************************
	FUNCTION Should_SortNames_When_Reserved3_Memo_IsGiven
		LOCAL lcMemo, lcExpected_Memo, lcResult_Memo
		LOCAL loObj AS CSplitLibraries OF "TWOFOX.PRG"
		loObj	= THIS.icObj
		
		*-- Input and expected params
		STORE '' TO lcMemo, lcExpected_Memo, lcResult_Memo

		TEXT TO lcMemo NOSHOW TEXTMERGE FLAGS 1+0 PRETEXT 1+2+4
			aaa_frm_a
			zzz_frm_a
			prop_protegida
			prop_hidden
			*aa_frm_a 
			*a0_frm_a 
		ENDTEXT

		TEXT TO lcExpected_Memo NOSHOW TEXTMERGE FLAGS 1+0 PRETEXT 1+2+4
			aaa_frm_a
			prop_hidden
			prop_protegida
			zzz_frm_a
			*a0_frm_a 
			*aa_frm_a 
		ENDTEXT
		
		*-- Test
		lcResult_Memo	= loObj.sortNames( lcMemo )
		
		THIS.Evaluate_results( lcExpected_Memo, lcResult_Memo )
		
	ENDFUNC


	*******************************************************************************************************************************************
	FUNCTION Should_SortNames_When_Protected_Memo_IsGiven
		LOCAL lcMemo, lcExpected_Memo, lcResult_Memo
		LOCAL loObj AS CSplitLibraries OF "TWOFOX.PRG"
		loObj	= THIS.icObj
		
		*-- Input and expected params
		STORE '' TO lcMemo, lcExpected_Memo, lcResult_Memo

		TEXT TO lcMemo NOSHOW TEXTMERGE FLAGS 1+0 PRETEXT 1+2+4
			zzz_frm_a^
			a0_frm_a
			prop_protegida
			prop_hidden^
		ENDTEXT

		TEXT TO lcExpected_Memo NOSHOW TEXTMERGE FLAGS 1+0 PRETEXT 1+2+4
			a0_frm_a
			prop_hidden^
			prop_protegida
			zzz_frm_a^
		ENDTEXT
		
		*-- Test
		lcResult_Memo	= loObj.sortNames( lcMemo )
		
		THIS.Evaluate_results( lcExpected_Memo, lcResult_Memo )
		
	ENDFUNC


	*******************************************************************************************************************************************
	FUNCTION Should_SortNames_When_Properties_Memo_IsGiven
		LOCAL lcMemo, lcExpected_Memo, lcResult_Memo
		LOCAL loObj AS CSplitLibraries OF "TWOFOX.PRG"
		loObj	= THIS.icObj
		
		*-- Input and expected params
		STORE '' TO lcMemo, lcExpected_Memo, lcResult_Memo

		TEXT TO lcMemo NOSHOW TEXTMERGE FLAGS 1+0 PRETEXT 1+2+4
			DoCreate = .T.
			Caption = "Form"
			aaa_frm_a = .F.
			zzz_frm_a = .F.
			prop_protegida = .F.
			prop_hidden = .F.
			Name = "frm_a"
		ENDTEXT

		TEXT TO lcExpected_Memo NOSHOW TEXTMERGE FLAGS 1+0 PRETEXT 1+2+4
			aaa_frm_a = .F.
			Caption = "Form"
			DoCreate = .T.
			Name = "frm_a"
			prop_hidden = .F.
			prop_protegida = .F.
			zzz_frm_a = .F.
		ENDTEXT
		
		*-- Test
		lcResult_Memo	= loObj.sortNames( lcMemo )
		
		THIS.Evaluate_results( lcExpected_Memo, lcResult_Memo )
		
	ENDFUNC


	*******************************************************************************************************************************************
	FUNCTION Should_Not_SortNames_When_Empty_Memo_IsGiven
		LOCAL lcMemo, lcExpected_Memo, lcResult_Memo
		LOCAL loObj AS CSplitLibraries OF "TWOFOX.PRG"
		loObj	= THIS.icObj
		
		*-- Input and expected params
		STORE '' TO lcMemo, lcExpected_Memo, lcResult_Memo

		*-- Test
		lcResult_Memo	= loObj.sortNames( lcMemo )
		
		THIS.Evaluate_results( lcExpected_Memo, lcResult_Memo )
		
	ENDFUNC


ENDDEFINE

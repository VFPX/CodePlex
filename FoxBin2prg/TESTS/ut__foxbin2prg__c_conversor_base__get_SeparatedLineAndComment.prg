DEFINE CLASS ut__foxbin2prg__c_conversor_base__get_SeparatedLineAndComment AS FxuTestCase OF FxuTestCase.prg

	#IF .F.
		LOCAL THIS AS ut__foxbin2prg__c_conversor_base__get_SeparatedLineAndComment OF ut__foxbin2prg__c_conversor_base__get_SeparatedLineAndComment.PRG
	#ENDIF

	#DEFINE C_FB2P_VALUE_I		'<fb2p_value>'
	#DEFINE C_FB2P_VALUE_F		'</fb2p_value>'
	#DEFINE CR_LF				CHR(13) + CHR(10)
	#DEFINE C_CR				CHR(13)
	#DEFINE C_LF				CHR(10)
	#DEFINE C_TAB				CHR(9)
	#DEFINE C_PROC				'PROCEDURE'
	#DEFINE C_ENDPROC			'ENDPROC'
	#DEFINE C_TEXT				'TEXT'
	#DEFINE C_ENDTEXT			'ENDTEXT'
	#DEFINE C_IF_F				'#IF .F.'
	#DEFINE C_ENDIF				'#ENDIF'
	#DEFINE C_DEFINE_CLASS		'DEFINE CLASS'
	#DEFINE C_ENDDEFINE_CLASS	'ENDDEFINE'
	icObj = NULL


	*******************************************************************************************************************************************
	FUNCTION SETUP
		PUBLIC oFXU_LIB AS CL_FXU_CONFIG OF 'TESTS\fxu_lib_objetos_y_funciones_de_soporte.PRG'
		LOCAL loObj AS c_conversor_base OF "FOXBIN2PRG.PRG"
		SET PROCEDURE TO 'TESTS\fxu_lib_objetos_y_funciones_de_soporte.PRG'
		oFXU_LIB = CREATEOBJECT('CL_FXU_CONFIG')
		oFXU_LIB.setup_comun()

		THIS.icObj 	= NEWOBJECT("c_conversor_base", "FOXBIN2PRG.PRG")
		loObj			= THIS.icObj
		loObj.l_Test	= .T.

	ENDFUNC


	*******************************************************************************************************************************************
	FUNCTION TearDown
		#IF .F.
			PUBLIC oFXU_LIB AS CL_FXU_CONFIG OF 'TESTS\fxu_lib_objetos_y_funciones_de_soporte.PRG'
		#ENDIF
		THIS.icObj = NULL
		
		IF VARTYPE(oFXU_LIB) = "O"
			oFXU_LIB.teardown_comun()
			oFXU_LIB = NULL
		ENDIF
		RELEASE PROCEDURE 'TESTS\fxu_lib_objetos_y_funciones_de_soporte.PRG'

	ENDFUNC


	*******************************************************************************************************************************************
	FUNCTION Evaluate_results
		LPARAMETERS toEx AS EXCEPTION, tnCodError_Esperado ;
			, tcLinea, tcComentario, tcLinea_Esperada, tcComentario_Esperado

		#IF .F.
			PUBLIC oFXU_LIB AS CL_FXU_CONFIG OF 'TESTS\fxu_lib_objetos_y_funciones_de_soporte.PRG'
		#ENDIF
		LOCAL loObj AS c_conversor_base OF "FOXBIN2PRG.PRG"
		loObj		= THIS.icObj

		IF PCOUNT() = 0
			THIS.messageout( "* Support method, not a valid test." )
			RETURN .T.
		ENDIF

		IF ISNULL(toEx)
			*-- Algunos ajustes para mejor visualizaci�n de caracteres especiales
			tcLinea					= oFXU_LIB.mejorarPresentacionCaracteresEspeciales( tcLinea )
			tcLinea_Esperada		= oFXU_LIB.mejorarPresentacionCaracteresEspeciales( tcLinea_Esperada )
			tcComentario			= oFXU_LIB.mejorarPresentacionCaracteresEspeciales( tcComentario )
			tcComentario_Esperado	= oFXU_LIB.mejorarPresentacionCaracteresEspeciales( tcComentario_Esperado )
		
			
			*-- Visualizaci�n de valores
			THIS.messageout( ' Linea = [' + TRANSFORM(tcLinea_Esperada) + ']' )
			THIS.messageout( ' Comentario = [' + TRANSFORM(tcComentario_Esperado) + ']' )

			
			*-- Evaluaci�n de valores
			THIS.assertequals( tcLinea_Esperada, tcLinea, "L�nea de c�digo" )
			THIS.assertequals( tcComentario_Esperado, tcComentario, "Comentario" )

		ELSE
			*-- Evaluaci�n de errores
			THIS.messageout( "Error " + TRANSFORM(toEx.ERRORNO) + ', ' + TRANSFORM(toEx.MESSAGE) )
			THIS.messageout( toEx.PROCEDURE + ', ' + TRANSFORM(toEx.LINENO) )
			THIS.messageout( TRANSFORM(toEx.LINECONTENTS) )

			THIS.assertequals( tnCodError_Esperado, toEx.ERRORNO, 'Error' )
		ENDIF
	ENDFUNC


	*******************************************************************************************************************************************
	FUNCTION Deberia_DevolverSeparados_LineaDeCodigo_y_Valor
		LOCAL lnCodError, lcMenError, lnCodError_Esperado  ;
			, lcLinea, lcLineaOriginal, lcComentario, lcLinea_Esperada, lcComentario_Esperado ;
			, loEx AS EXCEPTION
		LOCAL loObj AS c_conversor_base OF "FOXBIN2PRG.PRG"
		loObj		= THIS.icObj
		loEx		= NULL

		*-- DATOS DE ENTRADA
		STORE 0 TO lnCodError
		lcLinea					= '	' + CHR(9) + CHR(9) + '   esta es una linea de c�digo   ' + CHR(9) + ' '
		lcComentario			= '    ' + CHR(9) + CHR(9) + 'con algunos comentarios  	'
		lcLineaOriginal			= lcLinea + '&' + '&' + lcComentario

		*-- DATOS ESPERADOS
		STORE 0 TO lnCodError_Esperado
		lcLinea_Esperada		= lcLinea
		lcComentario_Esperado	= LTRIM(lcComentario)

		*-- TEST
		loObj.get_SeparatedLineAndComment( @lcLineaOriginal, @lcComentario )

		THIS.Evaluate_results( loEx, lnCodError_Esperado, @lcLinea, @lcComentario, @lcLinea_Esperada, @lcComentario_Esperado )

	ENDFUNC


ENDDEFINE

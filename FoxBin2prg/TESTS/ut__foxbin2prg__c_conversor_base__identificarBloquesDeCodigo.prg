DEFINE CLASS ut__foxbin2prg__c_conversor_base__identificarBloquesDeCodigo AS FxuTestCase OF FxuTestCase.prg

	#IF .F.
		LOCAL THIS AS ut__foxbin2prg__c_conversor_base__identificarBloquesDeCodigo OF ut__foxbin2prg__c_conversor_base__identificarBloquesDeCodigo.prg
	#ENDIF

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
		THIS.icObj = NEWOBJECT("c_conversor_base", "FOXBIN2PRG.PRG")

	ENDFUNC


	*******************************************************************************************************************************************
	FUNCTION TearDown
		THIS.icObj = NULL
	ENDFUNC


	*******************************************************************************************************************************************
	FUNCTION Evaluate_results
		LPARAMETERS toEx AS EXCEPTION, tnCodError_Esperado, toModulo_Esperado, toModulo

		LOCAL loObj AS c_conversor_base OF "FOXBIN2PRG.PRG"
		loObj	= THIS.icObj

		IF PCOUNT() = 0
			THIS.messageout( "* Support method, not a valid test." )
			RETURN .T.
		ENDIF

		IF ISNULL(toEx)
			*-- Evaluación de valores
			FOR I = 1 TO toModulo.Clases_count
				THIS.messageout( "nombre: " + TRANSFORM(toModulo.Clases(I).nombre) )
				THIS.messageout( "comentario: " + TRANSFORM(toModulo.Clases(I).comentario) )
				THIS.messageout( "inicio: " + TRANSFORM(toModulo.Clases(I).inicio) )
				THIS.messageout( "fin: " + TRANSFORM(toModulo.Clases(I).fin) )
				THIS.messageout( "definicion: " + TRANSFORM(toModulo.Clases(I).definicion) )
				THIS.messageout( "ini_cab: " + TRANSFORM(toModulo.Clases(I).ini_cab) )
				THIS.messageout( "fin_cab: " + TRANSFORM(toModulo.Clases(I).fin_cab) )
				THIS.messageout( "ini_cuerpo: " + TRANSFORM(toModulo.Clases(I).ini_cuerpo) )
				THIS.messageout( "fin_cuerpo: " + TRANSFORM(toModulo.Clases(I).fin_cuerpo) )
			ENDFOR

			THIS.assertequals( ALEN(toModulo_Esperado.Clases,1), ALEN(toModulo.Clases,1), "Start/End position" )

			FOR I = 1 TO ALEN(toModulo.Clases)
				THIS.assertequals( toModulo_Esperado.Clases(I).nombre, toModulo.Clases(I).nombre, 'Nombre bloque' )
				THIS.assertequals( toModulo_Esperado.Clases(I).comentario, toModulo.Clases(I).comentario, 'Comentario' )
				THIS.assertequals( toModulo_Esperado.Clases(I).inicio, toModulo.Clases(I).inicio, 'Pos Inicio' )
				THIS.assertequals( toModulo_Esperado.Clases(I).fin, toModulo.Clases(I).fin, 'Pos Fin' )
				THIS.assertequals( toModulo_Esperado.Clases(I).definicion, toModulo.Clases(I).definicion, 'Definición' )
				THIS.assertequals( toModulo_Esperado.Clases(I).ini_cab, toModulo.Clases(I).ini_cab, 'Pos Ini Cab' )
				THIS.assertequals( toModulo_Esperado.Clases(I).fin_cab, toModulo.Clases(I).fin_cab, 'Pos Fin Cab' )
				THIS.assertequals( toModulo_Esperado.Clases(I).ini_cuerpo, toModulo.Clases(I).ini_cuerpo, 'Pos Ini Cuerpo' )
				THIS.assertequals( toModulo_Esperado.Clases(I).fin_cuerpo, toModulo.Clases(I).fin_cuerpo, 'Pos Fin Cuerpo' )
			ENDFOR
		ELSE
			*-- Evaluación de errores
			THIS.messageout( "Error " + TRANSFORM(toEx.ERRORNO) + ', ' + TRANSFORM(toEx.MESSAGE) )
			THIS.messageout( toEx.PROCEDURE + ', ' + TRANSFORM(toEx.LINENO) )
			THIS.messageout( TRANSFORM(toEx.LINECONTENTS) )

			THIS.assertequals( tnCodError_Esperado, toEx.ERRORNO, 'Error' )
		ENDIF
	ENDFUNC


	*******************************************************************************************************************************************
	FUNCTION Deberia_obtenerLaUbicacionDelBloque_DEFINE_CLASS_CuandoUnBloqueCon_DEFINE_CLASS_ENDDEFINE_esEvaluado
		LOCAL lnCodError, lcMenError, lnCodError_Esperado, lcMethod, laLineas(1), laIDBloques(1,2), loModulo ;
			, loModulo_Esperado, laPosBloquesDeExclusion(1,2), lnOle_Count, loEx AS EXCEPTION
		LOCAL loObj AS c_conversor_base OF "FOXBIN2PRG.PRG"
		loObj		= THIS.icObj
		loEx		= NULL
		loModulo	= NULL
		STORE 0 TO lnBloques, lnOle_Count

		*-- Input and expected params
		STORE 0 TO lnCodError, lnCodError_Esperado
		lnBloques	= lnBloques + 1

		*-- MODULO
		toModulo	= CREATEOBJECT('EMPTY')
		ADDPROPERTY( toModulo, 'version', 0 )
		ADDPROPERTY( toModulo, 'SourceFile', '' )
		ADDPROPERTY( toModulo, 'ole_objs[1]')
		ADDPROPERTY( toModulo, 'ole_obj_count', 0)
		ADDPROPERTY( toModulo, 'clases[1]', 0 )
		ADDPROPERTY( toModulo, 'clases_count', 0 )

		*-- OLE OBJS
		loOLEObj						= NULL
		loOLEObj						= CREATEOBJECT('EMPTY')
		lnOle_Count						= lnOle_Count + 1
		toModulo.ole_obj_count			= lnOle_Count
		DIMENSION toModulo.ole_objs(lnOle_Count)
		toModulo.ole_objs(lnOle_Count)	= loOLEObj
		ADDPROPERTY( loOLEObj, 'nombre',	ALLTRIM( STREXTRACT( lcLine, 'nombre = "', '"', 1, 1 ) ) )
		ADDPROPERTY( loOLEObj, 'parent',	ALLTRIM( STREXTRACT( lcLine, 'parent = "', '"', 1, 1 ) ) )
		ADDPROPERTY( loOLEObj, 'objname',	ALLTRIM( STREXTRACT( lcLine, 'objname = "', '"', 1, 1 ) ) )
		ADDPROPERTY( loOLEObj, 'checksum',	ALLTRIM( STREXTRACT( lcLine, 'checksum = "', '"', 1, 1 ) ) )
		ADDPROPERTY( loOLEObj, 'value',		ALLTRIM( STREXTRACT( lcLine, 'value = "', '"', 1, 1 ) ) )

		*-- CLASES
		lnBloques					= lnBloques + 1
		toModulo.clases_count		= lnBloques
		loClase						= CREATEOBJECT('EMPTY')
		DIMENSION toModulo.clases(lnBloques)
		toModulo.clases(lnBloques)	= loClase
		ADDPROPERTY( loClase, 'nombre', ALLTRIM( STREXTRACT( lcLine, 'DEFINE CLASS ', ' AS ', 1, 1 ) ) )
		ADDPROPERTY( loClase, 'objname', JUSTEXT( loClase.nombre ) )
		ADDPROPERTY( loClase, 'parent', JUSTSTEM( loClase.nombre ) )
		ADDPROPERTY( loClase, 'definicion', ALLTRIM( lcLine ) )
		ADDPROPERTY( loClase, 'class', ALLTRIM( STREXTRACT( lcLine + ' OF ', ' AS ', ' OF ', 1, 1 ) ) )
		ADDPROPERTY( loClase, 'classloc', ALLTRIM( STREXTRACT( lcLine + ' OLEPUBLIC', ' OF ', ' OLEPUBLIC', 1, 1 ) ) )
		ADDPROPERTY( loClase, 'olepublic', ' OLEPUBLIC' $ UPPER(lcLine) )
		ADDPROPERTY( loClase, 'ole', '' )
		ADDPROPERTY( loClase, 'ole2', '' )
		ADDPROPERTY( loClase, 'uniqueid', '' )
		ADDPROPERTY( loClase, 'comentario', lc_Comentario )
		ADDPROPERTY( loClase, 'classicon', '' )
		ADDPROPERTY( loClase, 'projectclassicon', '' )
		ADDPROPERTY( loClase, 'inicio', I )
		ADDPROPERTY( loClase, 'fin', 0)
		ADDPROPERTY( loClase, 'ini_cab', I + 1)
		ADDPROPERTY( loClase, 'fin_cab', 0)
		ADDPROPERTY( loClase, 'ini_cuerpo', 0)
		ADDPROPERTY( loClase, 'fin_cuerpo', 0)
		ADDPROPERTY( loClase, 'props[1,2]', '')
		ADDPROPERTY( loClase, 'prop_count', 0)
		ADDPROPERTY( loClase, 'hiddenprops', '')
		ADDPROPERTY( loClase, 'protectedprops', '')
		ADDPROPERTY( loClase, 'metadata', '')
		ADDPROPERTY( loClase, 'baseclass', '')
		ADDPROPERTY( loClase, 'timestamp', '')
		ADDPROPERTY( loClase, 'scale', '')
		ADDPROPERTY( loClase, 'defined_pem', '')
		ADDPROPERTY( loClase, 'include', '')
		ADDPROPERTY( loClase, 'addobjects[1]')
		ADDPROPERTY( loClase, 'addobject_count', 0)
		ADDPROPERTY( loClase, 'procedures[1]')
		ADDPROPERTY( loClase, 'procedure_count', 0)


		*-- OLE Objects (ADD OBJECT)
		loAddObj	= NULL
		loAddObj	= CREATEOBJECT('EMPTY')
		lnObjects	= lnObjects + 1
		loClase.addobject_count	= lnObjects
		DIMENSION loClase.addobjects(lnObjects)
		loClase.addobjects(lnObjects)	= loAddObj
		ADDPROPERTY( loAddObj, 'nombre', ALLTRIM( CHRTRAN( STREXTRACT(lcLine, 'ADD OBJECT ', ' AS ', 1, 1), ['"], [] ) ) )
		ADDPROPERTY( loAddObj, 'objname', JUSTEXT( loAddObj.nombre ) )
		ADDPROPERTY( loAddObj, 'parent', JUSTSTEM( loAddObj.nombre ) )
		ADDPROPERTY( loAddObj, 'clase', ALLTRIM( STREXTRACT(lcLine + ' WITH', ' AS ', ' WITH', 1, 1) ) )
		ADDPROPERTY( loAddObj, 'classlib', '' )
		ADDPROPERTY( loAddObj, 'baseclass', '' )
		ADDPROPERTY( loAddObj, 'uniqueid', '' )
		ADDPROPERTY( loAddObj, 'ole', '' )
		ADDPROPERTY( loAddObj, 'ole2', '' )
		ADDPROPERTY( loAddObj, 'props_count', 0 )
		ADDPROPERTY( loAddObj, 'props[1]', '' )





		*---- VIEJO
		loModulo_Esperado.Clases(lnBloques)	= CREATEOBJECT('EMPTY')
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'nombre', 'miClase' )
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'comentario', '&' + '&' + ' Mis comentarios de la clase' )
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'inicio', 1 )
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'fin', 12)
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'definicion', 'AS CUSTOM OF MASCLASES.VCX' )
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'ini_cab', 2)
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'fin_cab', 4)
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'ini_cuerpo', 5)
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'fin_cuerpo', 11)
		*--

		STORE '' TO lcMethod, lcMenError
		laIDBloques(1,1)	= C_DEFINE_CLASS
		laIDBloques(1,2)	= C_ENDDEFINE_CLASS

		TEXT TO lcMethod NOSHOW TEXTMERGE FLAGS 1 PRETEXT 1+2
			<<C_DEFINE_CLASS>> miClase AS CUSTOM OF MASCLASES.VCX && Mis comentarios de la clase
				propiedad1 = 'A'
				propiedad2 = 2

				<<C_PROC>> myProc1	&& Mi procedimiento 1
					*-- Code Block
				<<C_ENDPROC>>

				<<C_PROC>> myProc2	&& Mi procedimiento 2
					*-- Code Block
				<<C_ENDPROC>>
			<<C_ENDDEFINE_CLASS>>
		ENDTEXT

		ALINES( laLineas, lcMethod )

		*-- Test
		loObj.identificarBloquesDeCodigo( @laLineas, @laIDBloques, .F., .F., @loModulo )

		THIS.Evaluate_results( loEx, lnCodError_Esperado, @loModulo_Esperado, @loModulo )

	ENDFUNC


	*******************************************************************************************************************************************
	FUNCTION Should_getUbicationDataOf_2_DEFINE_CLASS_Blocks_When_BlockCodeWith_DEFINE_CLASS_ENDDEFINE_areEvaluated
		LOCAL lnCodError, lcMenError, lnCodError_Esperado, lcMethod, laLineas(1), laIDBloques(1,2), loModulo ;
			, loModulo_Esperado, laPosBloquesDeExclusion(1,2), lnOle_Count, loEx AS EXCEPTION
		LOCAL loObj AS c_conversor_base OF "FOXBIN2PRG.PRG"
		loObj		= THIS.icObj
		loEx		= NULL
		loModulo	= NULL
		STORE 0 TO lnBloques, lnOle_Count

		*-- Input and expected params
		STORE 0 TO lnCodError, lnCodError_Esperado
		lnBloques	= lnBloques + 1
		loModulo_Esperado.Clases(lnBloques)	= CREATEOBJECT('EMPTY')
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'nombre', 'miClase1' )
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'comentario', '&' + '&' + ' Mis comentarios de la clase' )
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'inicio', 1 )
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'fin', 12)
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'definicion', 'AS CUSTOM OF MASCLASES.VCX' )
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'ini_cab', 2)
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'fin_cab', 4)
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'ini_cuerpo', 5)
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'fin_cuerpo', 11)
		*--
		lnBloques	= lnBloques + 1
		loModulo_Esperado.Clases(lnBloques)	= CREATEOBJECT('EMPTY')
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'nombre', 'miClase2' )
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'comentario', '&' + '&' + ' Mis comentarios de la clase' )
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'inicio', 13 )
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'fin', 24)
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'definicion', 'AS CUSTOM OF MASCLASES.VCX' )
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'ini_cab', 14)
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'fin_cab', 16)
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'ini_cuerpo', 17)
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'fin_cuerpo', 23)
		*--

		STORE '' TO lcMethod, lcMenError
		laIDBloques(1,1)	= C_DEFINE_CLASS
		laIDBloques(1,2)	= C_ENDDEFINE_CLASS

		TEXT TO lcMethod NOSHOW TEXTMERGE FLAGS 1 PRETEXT 1+2
			<<C_DEFINE_CLASS>> miClase1 AS CUSTOM OF MASCLASES.VCX && Mis comentarios de la clase
				propiedad1 = 'A'
				propiedad2 = 2

				<<C_PROC>> myProc1	&& Mi procedimiento 1
					*-- Code Block
				<<C_ENDPROC>>

				<<C_PROC>> myProc2	&& Mi procedimiento 2
					*-- Code Block
				<<C_ENDPROC>>
			<<C_ENDDEFINE_CLASS>>
			<<C_DEFINE_CLASS>> miClase2 AS CUSTOM OF MASCLASES.VCX && Mis comentarios de la clase
				propiedad1 = 'A'
				propiedad2 = 2

				<<C_PROC>> myProc1	&& Mi procedimiento 1
					*-- Code Block
				<<C_ENDPROC>>

				<<C_PROC>> myProc2	&& Mi procedimiento 2
					*-- Code Block
				<<C_ENDPROC>>
			<<C_ENDDEFINE_CLASS>>
		ENDTEXT

		ALINES( laLineas, lcMethod )

		*-- Test
		loObj.identificarBloquesDeCodigo( @laLineas, @laIDBloques, .F., .F., @loModulo )

		THIS.Evaluate_results( loEx, lnCodError_Esperado, @loModulo_Esperado, @loModulo )

	ENDFUNC


	*******************************************************************************************************************************************
	FUNCTION Should_getUbicationDataOf_DEFINE_CLASS_Block_When_BlockCodeWith_DEFINE_CLASS_IF_DEFINECLASS_ENDIF_ENDDEFINE_isEvaluated
		LOCAL lnCodError, lcMenError, lnCodError_Esperado, lcMethod, laLineas(1), laIDBloques(1,2), loModulo ;
			, loModulo_Esperado, laPosBloquesDeExclusion(1,2), loEx AS EXCEPTION
		LOCAL loObj AS c_conversor_base OF "FOXBIN2PRG.PRG"
		loObj		= THIS.icObj
		loEx		= NULL
		loModulo	= NULL
		lnBloques	= 0

		*-- Input and expected params
		STORE 0 TO lnCodError, lnCodError_Esperado
		lnBloques	= lnBloques + 1
		loModulo_Esperado.Clases(lnBloques)	= CREATEOBJECT('EMPTY')
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'nombre', 'miClase' )
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'comentario', '&' + '&' + ' Mis comentarios de la clase' )
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'inicio', 1 )
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'fin', 18)
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'definicion', 'AS CUSTOM OF MASCLASES.VCX' )
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'ini_cab', 2)
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'fin_cab', 4)
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'ini_cuerpo', 5)
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'fin_cuerpo', 17)
		*--

		STORE '' TO lcMethod, lcMenError
		laIDBloques(1,1)	= C_DEFINE_CLASS
		laIDBloques(1,2)	= C_ENDDEFINE_CLASS

		TEXT TO lcMethod NOSHOW TEXTMERGE FLAGS 1 PRETEXT 1+2
			<<C_DEFINE_CLASS>> miClase AS CUSTOM OF MASCLASES.VCX && Mis comentarios de la clase
				propiedad1 = 'A'
				propiedad2 = 2

				<<C_PROC>> myProc1	&& Mi procedimiento 1
					*-- Code Block
					<<C_IF_F>>
						<<C_DEFINE_CLASS>>
					<<C_ENDIF>>
				<<C_ENDPROC>>

				<<C_PROC>> myProc2	&& Mi procedimiento 2
					*-- Code Block
					<<C_IF_F>>
						<<C_ENDDEFINE_CLASS>>
					<<C_ENDIF>>
				<<C_ENDPROC>>
			<<C_ENDDEFINE_CLASS>>
		ENDTEXT

		ALINES( laLineas, lcMethod )

		*-- Test
		loObj.identificarBloquesDeExclusion( @laLineas, , @laPosBloquesDeExclusion )
		loObj.identificarBloquesDeCodigo( @laLineas, @laIDBloques, @laPosBloquesDeExclusion, .F., @loModulo )

		THIS.Evaluate_results( loEx, lnCodError_Esperado, @loModulo_Esperado, @loModulo )

	ENDFUNC


	*******************************************************************************************************************************************
	FUNCTION Should_getUbicationDataOf_DEFINE_CLASS_Block_When_BlockCodeWith_DEFINE_CLASS_IF_DEFINECLASS_ENDIF_ENDDEFINE_isEvaluated
		LOCAL lnCodError, lcMenError, lnCodError_Esperado, lcMethod, laLineas(1), laIDBloques(1,2), loModulo ;
			, loModulo_Esperado, laPosBloquesDeExclusion(1,2), loEx AS EXCEPTION
		LOCAL loObj AS c_conversor_base OF "FOXBIN2PRG.PRG"
		loObj		= THIS.icObj
		loEx		= NULL
		loModulo	= NULL
		lnBloques	= 0

		*-- Input and expected params
		STORE 0 TO lnCodError, lnCodError_Esperado
		lnBloques	= lnBloques + 1
		loModulo_Esperado.Clases(lnBloques)	= CREATEOBJECT('EMPTY')
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'nombre', 'miClase' )
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'comentario', '&' + '&' + ' Mis comentarios de la clase' )
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'inicio', 1 )
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'fin', 18)
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'definicion', 'AS CUSTOM OF MASCLASES.VCX' )
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'ini_cab', 2)
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'fin_cab', 4)
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'ini_cuerpo', 5)
		ADDPROPERTY( loModulo_Esperado.Clases(lnBloques), 'fin_cuerpo', 17)
		*--

		STORE '' TO lcMethod, lcMenError
		laIDBloques(1,1)	= C_DEFINE_CLASS
		laIDBloques(1,2)	= C_ENDDEFINE_CLASS

		TEXT TO lcMethod NOSHOW TEXTMERGE FLAGS 1 PRETEXT 1+2
			<<C_DEFINE_CLASS>> miClase AS CUSTOM OF MASCLASES.VCX && Mis comentarios de la clase
				propiedad1 = 'A'
				propiedad2 = 2

				<<C_PROC>> myProc1	&& Mi procedimiento 1
					*-- Code Block
					<<C_TEXT>>
						<<C_DEFINE_CLASS>>
					<<C_ENDTEXT>>
				<<C_ENDPROC>>

				<<C_PROC>> myProc2	&& Mi procedimiento 2
					*-- Code Block
					<<C_TEXT>>
						<<C_ENDDEFINE_CLASS>>
					<<C_ENDTEXT>>
				<<C_ENDPROC>>
			<<C_ENDDEFINE_CLASS>>
		ENDTEXT

		ALINES( laLineas, lcMethod )

		*-- Test
		loObj.identificarBloquesDeExclusion( @laLineas, , @laPosBloquesDeExclusion )
		loObj.identificarBloquesDeCodigo( @laLineas, @laIDBloques, @laPosBloquesDeExclusion, .F., @loModulo )

		THIS.Evaluate_results( loEx, lnCodError_Esperado, @loModulo_Esperado, @loModulo )

	ENDFUNC


ENDDEFINE

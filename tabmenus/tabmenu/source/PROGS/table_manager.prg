**************************************************************
* Table Designer X - Engine
* Prototype
* Author (Up to now) Djordjevic Srdjan
* From Now&on is your baby :))
*************************************************************
DEFINE CLASS TableDesignerX AS SESSION
	x_designerform ='.\forms\TableDesignerX.scx'

	x_database=''
	x_table=''

	x_alias=''

	x_database_name=''
	x_table_name=''

	x_reccount=0
	x_recsize=0
	x_cpdbf=0
	x_fcount =0

	**** Object References to UI Forms
	oFrontForm=.F.
	oEditForm=.F.
	***********************************

	PROCEDURE INIT
		=tm_set_sys_env()


	PROCEDURE modify_structure
		LPARAMETERS cTable
		THIS.x_table = PROPER(cTable)
		THIS.x_table_name=JUSTFNAME(cTable)

		THIS.open_selected_table()
		THIS.create_cursors()
		THIS.read_table_properties()
		THIS.read_index_properties()

		SELECT xcurrent  &&Single record cursor
		GO TOP
		REPLACE xcurrent.xdbc   WITH THIS.x_database
		REPLACE xcurrent.xtable WITH THIS.x_table


		DO FORM (THIS.x_designerform) WITH THIS


	PROCEDURE open_selected_table
		LOCAL ok, oErr AS EXCEPTION
		ok=.T.


		*!*			*** BYN 23/08/2007 set datasession and closed the table
		*!*			SET DATASESSION TO 1

		*!*			lcx_Table = JUSTSTEM(JUSTFNAME(THIS.x_table))

		*!*			IF USED(lcx_Table)
		*!*				SELECT (lcx_Table)
		*!*				USE
		*!*			ENDIF


		**You need try catch here
		*** BYN 25/08/2007 try-catch yet a previously opened table
		***                in exclusive mode raises an error at endtry
		***                we need readonly access to table when
		***                previsouly used elsewhere
		TRY
			USE (THIS.x_table) IN 0 EXCLUSIVE

		CATCH TO oErr
			IF oErr.ERRORNO = 3
				USE (THIS.x_table) AGAIN shared IN 0
			ELSE
				THROW
			ENDIF
		ENDTRY

		SELECT ( JUSTSTEM(THIS.x_table)  )


		THIS.x_alias =ALLT(ALIAS())
		THIS.x_database =  PROPER( CURSORGETPROP("Database") )  && Displays database name
		IF LEN(ALLT(THIS.x_database)) > 0
			THIS.x_database_name=JUSTFNAME(THIS.x_database)
			OPEN DATABASE (THIS.x_database) SHARED
			SET DATABASE TO (THIS.x_database)
		ELSE
			WAIT WIND 'Free Table' NOWAIT
		ENDIF

		THIS.x_reccount=RECCOUNT()
		THIS.x_recsize =RECSIZE()
		THIS.x_cpdbf   =CPDBF()
		THIS.x_fcount  =FCOUNT()
		RETURN ok


	PROCEDURE create_cursors
		CREATE CURSOR table_fields  (  ;
			FIELD_NO    C(3)  , ;
			FIELD_NAME  C(20), ;
			FIELD_TYPE  C(1),   ;
			FIELD_LEN   N(3,0), ;
			FIELD_DEC   N(3,0), ;
			FIELD_NULL       L, ;
			FIELD_NOCP       L, ;
			FIELD_DEFAULT C(254), ;
			FIELD_RULE   C(254), ;
			FIELD_ERR   C(254), ;
			FIELD_CAPTION C(254), ;
			FIELD_COMMENT C(254),  ;
			FIELD_FORMAT  C(254), ;
			FIELD_INPUTMASK C(254) , ;
			FIELD_CLASSLIB  C(254) , ;
			FIELD_CLASS    C(254) , ;
			TABLE_NAME   C(128), ;
			TABLE_RULE   C(254), ;
			TABLE_ERROR   C(254), ;
			TABLE_INS   C(254), ;
			TABLE_UPD   C(254), ;
			TABLE_DEL   C(254), ;
			TABLE_COMMENT C(254))


		CREATE CURSOR table_self (  ;
			TABLE_NAME   C(128), ;
			TABLE_RULE   C(254), ;
			TABLE_ERROR   C(254), ;
			TABLE_INS   C(254), ;
			TABLE_UPD   C(254), ;
			TABLE_DEL   C(254), ;
			TABLE_COMMENT C(254))



		CREATE CURSOR table_indexes  (  ;
			xtagno       C(3)   , ;
			xtagname     C(20)  , ;
			xtagexp      C(254) , ;
			xtagtype     C(10)  , ;
			xtagasc      C(1)  , ;
			xtagfilter   C(254))
		INDEX ON xtagno TAG xkey




		CREATE CURSOR xcurrent (  ;
			xdbc   C(100) , ;
			xtable C(100) , ;
			xstart T  , ;
			xcommit T  )

		SELECT xcurrent
		SCATTER MEMVAR BLANK
		m.xstart = DATETIME()
		INSERT INTO xcurrent FROM MEMVAR
		GO TOP
		*        set relation to xdbc + xtable + xowner + xkeyfield into xproperties_field
		*        set relation to xdbc + xtable + xowner + xkeyfield into xproperties_index additive
		*        set relation to xdbc + xtable + xowner + xkeyfield into xproperties_table additive





	PROCEDURE close_selected_table
		IF LEN(ALLT(THIS.x_database)) > 0
			SET DATABASE TO (THIS.x_database)
			CLOSE DATABASE
		ENDIF

		WITH THIS
			.x_table=''
			.x_alias=''
			.x_database=''
			.x_database_name=''
			.x_table_name=''
		ENDWITH

	PROCEDURE close_cursors
		SELECT xcurrent
		USE

		SELECT table_fields
		USE

		SELECT table_indexes
		USE

		SELECT table_self
		USE



	PROCEDURE m_field_core
		LPARAMETERS cfield,cXproperty
		LOCAL cfield,cXproperty,ok_pressed
		SELECT table_fields
		GO TOP
		DO FORM .\FORMS\property_sheet.scx WITH THIS,cfield,cXproperty TO ok_pressed





	PROCEDURE read_index_properties
		LOCAL i
		SELECT table_indexes
		SCATTER MEMVAR BLANK
		SELECT (THIS.x_alias)
		FOR i = 1 TO 254
			IF !EMPTY(TAG(i))  && Checks for tags in the index
				m.xtagname=UPPER(TAG(i))
				*    set order to (m.xtagname)
				m.xtagexp =KEY(i)
				m.xtagno  =TAGNO(m.xtagname)
				DO CASE

					CASE PRIMARY(m.xtagno)
						m.xtagtype='PRIMARY'

					CASE CANDIDATE(m.xtagno)
						m.xtagtype='CANDIDATE'

					OTHERWISE
						m.xtagtype='REGULAR'

				ENDCASE
				m.xtagfilter=SYS(2021,m.xtagno)
				m.xtagasc  =IIF(DESCENDING(m.xtagno),'D','A')
				m.xtagno=STR(m.xtagno,3,0)
				INSERT INTO table_indexes FROM MEMVAR
			ENDIF
		NEXT
		SELECT table_indexes
		GO TOP




	PROCEDURE read_table_properties
		LPARAMETERS cTable
		LOCAL cTable
		LOCAL aa,bb,i
		SELECT (THIS.x_alias)
		COPY STRUCTURE EXTENDED TO temp
		USE temp IN 0 EXCLUSIVE
		SELECT temp
		GO TOP
		i=0
		SCAN
			i=i+1
			SCATTER MEMVAR MEMO
			m.FIELD_NO = STR(i,3,0)
			m.FIELD_NAME = temp.FIELD_NAME
			m.FIELD_TYPE = temp.FIELD_TYPE
			m.FIELD_LEN = temp.FIELD_LEN
			m.FIELD_DEC = temp.FIELD_DEC
			m.FIELD_NULL = temp.FIELD_NULL
			m.FIELD_NOCP = temp.FIELD_NOCP
			m.FIELD_DEFAULT = temp.FIELD_DEFA
			m.FIELD_RULE = temp.FIELD_RULE
			m.FIELD_ERR = temp.FIELD_ERR
			m.TABLE_RULE = temp.TABLE_RULE
			m.TABLE_ERROR = temp.TABLE_ERR
			m.TABLE_NAME = UPPER(temp.TABLE_NAME)
			m.TABLE_INS   = temp.INS_TRIG
			m.TABLE_UPD   = temp.UPD_TRIG
			m.TABLE_DEL = temp.DEL_TRIG
			m.TABLE_COMMENT = temp.TABLE_CMT
			SELECT (THIS.x_alias)
			aa=THIS.x_alias + '.' + ALLT(m.FIELD_NAME)

			IF LEN(THIS.x_database) > 0   &&Belongs to database

				m.FIELD_CAPTION=DBGETPROP(aa, "Field", "Caption")
				m.FIELD_INPUTMASK=DBGETPROP(aa, "Field", "Inputmask")
				m.FIELD_FORMAT=DBGETPROP(aa, "Field", "Format")
				m.FIELD_COMMENT=DBGETPROP(aa, "Field", "Comment")
				m.FIELD_CLASSLIB=DBGETPROP(aa, "Field", "DisplayClassLibrary")
				m.FIELD_CLASS=DBGETPROP(aa, "Field", "DisplayClass")

			ENDIF

			INSERT INTO table_fields FROM MEMVAR
			IF i=1
				INSERT INTO table_self   FROM MEMVAR
			ENDIF
			SELECT temp
		ENDSCAN
		SELECT temp
		USE
		ERASE temp.*
		SELECT table_fields
		GO TOP

	PROCEDURE save_all
		THIS.save_core_properties_field()
		THIS.save_core_properties_index()
		THIS.close_selected_table()
		SELECT xcurrent
		*browse normal
		SCATTER NAME oLogRec
		oLogRec.xcommit=DATETIME()

		IF TYPE('oTDXLOG.NAME') = 'C'
			oTDXLOG.Dump2LogTable(oLogRec)
			*oTDXLOG.browse_log()
		ENDIF

		THIS.close_cursors()
		THIS.oFrontForm=.F.


	PROCEDURE revert_all
		THIS.close_selected_table()
		THIS.close_cursors()
		THIS.oFrontForm=.F.







	PROCEDURE save_core_properties_index

	PROCEDURE save_core_properties_field
		LOCAL aa
		SELECT (THIS.x_alias)
		USE

		SELECT table_fields
		GO TOP

		*** for speed purposes this could be done bu comparing
		*** current state of records in tmp tables and state saved
		*** at begin of the session
		*** Right now it compares it to property valu in dabase itself extracted by dbgetprop()
		*** and then saves it with DBSetProp()

		SCAN
			aa=THIS.x_alias + '.' + ALLT(table_fields.FIELD_NAME)

			IF ALLTR(DBGETPROP(aa, "Field", "Caption")) <> ALLT(table_fields.FIELD_CAPTION)
				=DBSETPROP(aa, "Field", "Caption",ALLT(table_fields.FIELD_CAPTION))
			ENDIF

			IF ALLT(DBGETPROP(aa, "Field", "Inputmask")) <> ALLT(table_fields.FIELD_INPUTMASK)
				=DBSETPROP(aa, "Field", "Inputmask",ALLT(table_fields.FIELD_INPUTMASK))
			ENDIF

			IF ALLT(DBGETPROP(aa, "Field", "Format"))<>ALLT(table_fields.FIELD_FORMAT)
				=DBSETPROP(aa, "Field", "Format",ALLT(table_fields.FIELD_FORMAT))
			ENDIF

			IF ALLT(DBGETPROP(aa, "Field", "Comment")) <> ALLT(table_fields.FIELD_COMMENT)
				=DBSETPROP(aa, "Field", "Comment",ALLT(table_fields.FIELD_COMMENT))
			ENDIF


			IF EMPTY(ALLT(table_fields.FIELD_CLASSLIB)) OR EMPTY(ALLT(table_fields.FIELD_CLASS))
				LOOP
			ENDIF

			IF ALLT(DBGETPROP(aa, "Field", "DisplayClassLibrary")) <> ALLT(table_fields.FIELD_CLASSLIB)
				=DBSETPROP(aa, "Field", "DisplayClassLibrary",table_fields.FIELD_CLASSLIB)
			ENDIF

			IF ALLT(DBGETPROP(aa, "Field", "DisplayClass")) <> ALLT(table_fields.FIELD_CLASS)
				=DBSETPROP(aa, "Field", "DisplayClass",table_fields.FIELD_CLASS)
			ENDIF

		ENDSCAN





	PROCEDURE return_dbgp_table_field
		LPARAMETERS cProperty
		LOCAL cProperty
		DO CASE

			CASE LOWER(cProperty)='fieldname'
				RETURN table_fields.FIELD_NAME

			CASE LOWER(cProperty)='fieldtype'
				RETURN table_fields.FIELD_TYPE

			CASE LOWER(cProperty)='fieldlen'
				RETURN table_fields.FIELD_LEN

			CASE LOWER(cProperty)='fielddec'
				RETURN table_fields.FIELD_DEC

			CASE LOWER(cProperty)='fieldnull'
				RETURN table_fields.FIELD_NULL

			CASE LOWER(cProperty)='fieldnocp'
				RETURN table_fields.FIELD_NOCP

			CASE LOWER(cProperty)='caption'
				RETURN table_fields.FIELD_CAPTION

			CASE LOWER(cProperty)='comment'
				RETURN table_fields.FIELD_COMMENT

			CASE LOWER(cProperty)='defaultvalue'
				RETURN table_fields.FIELD_DEFAULT

			CASE LOWER(cProperty)='displayclass'
				RETURN table_fields.FIELD_CLASS

			CASE LOWER(cProperty)='displayclasslibrary'
				RETURN table_fields.FIELD_CLASSLIB


			CASE LOWER(cProperty)='format'
				RETURN table_fields.FIELD_FORMAT

			CASE LOWER(cProperty)='inputmask'
				RETURN table_fields.FIELD_INPUTMASK

			CASE LOWER(cProperty)='ruleexpression'
				RETURN table_fields.FIELD_RULE

			CASE LOWER(cProperty)='ruletext'
				RETURN table_fields.FIELD_ERR

		ENDCASE



		******************************************************
		* Utilities
		******************************************************

	PROCEDURE string_to_array
		LPARAMETERS pstring,pdlm,myarray
		DECLARE myarray(OCCURS(pdlm,pstring)+1)
		FOR i = 1 TO ALEN(myarray)
			IF ATC(pdlm,pstring)>0
				myarray(i)=LEFT(pstring,ATC(pdlm,pstring)-1)
				pstring=RIGHT(pstring,LEN(pstring)-ATC(pdlm,pstring))
			ELSE
				myarray(i)=pstring
			ENDIF
		NEXT
		RETURN ALEN(myarray)


		************************************************************
		*  THE END
		************************************************************
ENDDEFINE




DEFINE CLASS tdx_log AS SESSION
	x_logtable=''


	PROCEDURE INIT
		=tm_set_sys_env()
		THIS.open_tables()


	PROCEDURE open_tables()
		USE tdxlog IN 0 SHARED
		SELECT tdxlog


	PROCEDURE Dump2LogTable
		LPARAMETERS oRec
		SELECT tdxlog
		APPEND BLANK
		GATHER NAME oRec


	PROCEDURE browse_log
		SELECT tdxlog
		BROWSE NORMAL


ENDDEFINE



******************Application Interface****************
*                                                     *
*******************************************************


FUNCTION char_to_val
	LPARAMETERS cValue,cType
	LOCAL cValue,cType
	DO CASE
		CASE TYPE('cType')='L'
			WAIT WINDOW 'Value Type has to be specified as second parameter! ' TIMEOUT 1
			RETURN .F.

		CASE cType='C'
			RETURN cValue

		CASE cType='N'
			RETURN VAL(cValue)

		CASE cType='I'
			RETURN VAL(cValue)

		CASE cType='D'
			RETURN CTOD(ALLT(cValue))

		CASE cType='T'
			RETURN CTOT(ALLT(cValue))

		CASE cType='L'
			RETURN ctol(cValue)


	ENDCASE


FUNCTION val_to_char
	LPARAMETERS uValue

	DO CASE
		CASE TYPE('uValue')='L'
			RETURN IIF(uValue,'.T.','.F.')

		CASE TYPE('uValue')='C'
			RETURN uValue

		CASE TYPE('uValue')='N'
			RETURN STR(uValue)

		CASE TYPE('uValue')='I'
			RETURN STR(uValue)

		CASE TYPE('uValue')='D'
			RETURN DTOC(uValue)

		CASE TYPE('uValue')='T'
			RETURN TTOC(uValue)

		CASE TYPE('uValue')='M'
			RETURN uValue

		OTHERWISE
			RETURN .F.

	ENDCASE





FUNCTION ctol
	LPARAMETERS cValue
	DO CASE

		CASE INLIST(UPPER(ALLT(cValue)),'T','.T.')
			RETURN .T.

		CASE INLIST(UPPER(ALLT(cValue)),'F','.F.')
			RETURN .F.

		CASE EMPTY(cValue)
			RETURN .F.

		OTHERWISE
			WAIT WINDOW 'Logical value cannot be exstracted from given string' TIMEOUT 1
			RETURN .F.

	ENDCASE

FUNCTION ltoc
	LPARAMETERS lValue

	DO CASE

		CASE TYPE('lValue') <> 'L'
			RETURN ''

		CASE lValue=.T.
			RETURN '.T.'

		CASE lValue=.F.
			RETURN '.F.'

		OTHERWISE
			RETURN ''

	ENDCASE


FUNCTION in_brackets
	LPARAMETERS cString
	IF TYPE('cString')='C'
		RETURN '[' + cString + ']'
	ENDIF

FUNCTION tm_set_sys_env
	******************Default Environment Settings
	SET TALK OFF
	SET CONSOLE OFF
	SET CENTURY ON
	SET DELETED ON
	SET EXCLUSIVE OFF
	SET SAFETY ON
	SET MULTILOCKS ON
	SET DELETED ON
	SET CENTURY ON
	SET DATE TO british
	SET NEAR OFF
	SET UNIQUE OFF
	*******************
	RETURN .T.


FUNCTION question
	PARAMETERS cMessageText
	cMessageTitle = 'Question:'
	nDialogType = 4 + 32 + 256
	*  4 = Yes and No buttons
	*  32 = Question mark icon
	*  256 = Second button is default
	nAnswer = MESSAGEBOX(cMessageText, nDialogType, cMessageTitle)
	DO CASE
		CASE nAnswer = 6
			RETURN .T.

		CASE nAnswer = 7
			RETURN .F.

		OTHERWISE
			WAIT WINDOW STR(nAnswer)
			RETURN .F.

	ENDCASE




=tdxSetup( JUSTPATH(JUSTPATH( SYS(16) )))
DO FORM run_tdx.scx  &&Run Control Panel Form


*************************************************************
* Table Designer X - Engine
* Prototype
*************************************************************
DEFINE CLASS TableDesignerX AS SESSION
	x_designerform ='.\forms\TableDesignerX.scx'

	x_table=''
	x_table_name=''

	x_database=''
	x_database_name=''

	x_alias=''

	x_BelongsToDatabase=.F.

	x_tdx_id = 0  &&Counter for session unique field ID


	****************
	x_reccount=0
	x_recsize=0
	x_cpdbf=0
	x_fcount =0
	****************


	**** Object References to UI Forms
	oFrontForm=.F.

	nSubFormCount=0
	DECLARE aSubForms(100)
	***********************************

	PROCEDURE INIT
		LPARAMETERS cTable
		=tdx_set_sys_env()
		THIS.x_table = PROPER(cTable)
		THIS.x_table_name=JUSTFNAME(cTable)

		IF !THIS.open_selected_table()
			MESSAGEBOX('Could not Open table - Exclusive access needed!')
			RETURN .F.
		ENDIF

		SELECT ( JUSTSTEM(THIS.x_table)  )
		THIS.x_alias = ALIAS()
		THIS.x_database =  PROPER( CURSORGETPROP("Database") )  && Displays database name

		IF LEN(ALLT(THIS.x_database)) > 0
			THIS.x_database_name=JUSTFNAME(THIS.x_database)
			THIS.x_BelongsToDatabase=.T.
			OPEN DATABASE (THIS.x_database) SHARED
		ELSE
			THIS.x_database = 'Free Table'
			THIS.x_BelongsToDatabase=.F.
		ENDIF


		RETURN .T.



	PROCEDURE open_selected_table
		LOCAL ok, oErr AS EXCEPTION
		ok=.T.
		TRY
			USE (THIS.x_table) IN 0 EXCLUSIVE

		CATCH TO oErr
			IF oErr.ERRORNO > 0
				ok=.F.
			ENDIF
		ENDTRY
		RETURN ok



	PROCEDURE LoadTableStructure
		*************************
		THIS.CreateCursors()
		THIS.ReadFieldProperties()
		THIS.ReadIndexProperties()
		THIS.ReadTableProperties()
		**************************



	PROCEDURE modify_structure
		THIS.LoadTableStructure()
		THIS.ShowInterface()


	PROCEDURE  ShowInterface
		SELECT table_fields
		GO TOP
		THIS.CheckForFieldChanges()
		DO FORM (THIS.x_designerform) WITH THIS



	PROCEDURE CreateCursors
		**Structure compatible with temp. table created by
		**copy structure extended + set of fields necessary
		**to hold other field properties + few utility fields
		** Djordjevic Srdjan 03 Oct 2007
		CREATE CURSOR table_fields  (  ;
			TDX_ID      I(4)  , ;
			TDX_STAT    C(1)  , ;
			FIELD_NO    C(3)  , ;
			FIELD_NAME  C(20) , ;
			FIELD_TYPE  C(1)  , ;
			FIELD_UNTY  C(2)  , ;
			FIELD_TYDS  C(20) , ;
			FIELD_LEN   N(3,0), ;
			FIELD_DEC   N(3,0), ;
			FIELD_NULL  L, ;
			FIELD_NOCP  L, ;
			FIELD_DEFA C(254), ;
			FIELD_RULE   C(254), ;
			FIELD_ERR   C(254), ;
			FIELD_CAPT C(254), ;
			FIELD_COMM C(254),  ;
			FIELD_FMT  C(254), ;
			FIELD_IMSK C(254) , ;
			FIELD_CLLB  C(254) , ;
			FIELD_CLSS   C(254) , ;
			TABLE_NAME   C(128), ;
			TABLE_RULE   C(254), ;
			TABLE_ERR   C(254), ;
			TABLE_CMT   C(254), ;
			INS_TRIG   C(254), ;
			UPD_TRIG   C(254), ;
			DEL_TRIG   C(254),;
			FIELD_NEXT  I(4), ;
			FIELD_STEP  I(4) )
		***Added last two fields

		LOCAL aStru1(1)
		AFIELDS(aStru1)
		CREATE CURSOR origfields FROM ARRAY aStru1
		INDEX ON TDX_ID TAG fldid
		SET ORDER TO fldid



		CREATE CURSOR table_self (  ;
			TABLE_NAME   C(128), ;
			TABLE_PATH   C(254), ;
			TABLE_RULE   C(254), ;
			TABLE_RUTX   C(254), ;
			TABLE_ERR   C(254), ;
			TABLE_INS   C(254), ;
			TABLE_UPD   C(254), ;
			TABLE_DEL   C(254), ;
			TABLE_CMT C(254))

		LOCAL aStru2(1)
		AFIELDS(aStru2)
		CREATE CURSOR origtable FROM ARRAY aStru2



		CREATE CURSOR table_indexes  (  ;
			xtagno       C(3)   , ;
			xtagname     C(20)  , ;
			xtagexp      C(254) , ;
			xtagtype     C(10)  , ;
			xtagasc      C(1)  , ;
			xtagfilter   C(254))
		INDEX ON xtagno TAG xkey


		LOCAL aStru3(1)
		AFIELDS(aStru3)
		CREATE CURSOR origkeys FROM ARRAY aStru3



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


		CREATE CURSOR FieldTypes  (  ;
			FIELD_TYDS  C(20),   ;
			FIELD_UNTY   C(2))

		m.FIELD_TYDS='Blob'
		m.FIELD_UNTY='W'
		INSERT INTO FieldTypes FROM MEMVAR

		m.FIELD_TYDS='Character'
		m.FIELD_UNTY='C'
		INSERT INTO FieldTypes FROM MEMVAR

		m.FIELD_TYDS='Character(Binary)'
		m.FIELD_UNTY='CB'
		INSERT INTO FieldTypes FROM MEMVAR

		m.FIELD_TYDS='Currency'
		m.FIELD_UNTY='Y'
		INSERT INTO FieldTypes FROM MEMVAR

		m.FIELD_TYDS='Date'
		m.FIELD_UNTY='D'
		INSERT INTO FieldTypes FROM MEMVAR

		m.FIELD_TYDS='DateTime'
		m.FIELD_UNTY='T'
		INSERT INTO FieldTypes FROM MEMVAR

		m.FIELD_TYDS='Double'
		m.FIELD_UNTY='B'
		INSERT INTO FieldTypes FROM MEMVAR

		m.FIELD_TYDS='Float'
		m.FIELD_UNTY='F'
		INSERT INTO FieldTypes FROM MEMVAR

		m.FIELD_TYDS='General'
		m.FIELD_UNTY='G'
		INSERT INTO FieldTypes FROM MEMVAR

		m.FIELD_TYDS='Integer'
		m.FIELD_UNTY='I'
		INSERT INTO FieldTypes FROM MEMVAR

		m.FIELD_TYDS='Integer(AutoInc)'
		m.FIELD_UNTY='IA'
		INSERT INTO FieldTypes FROM MEMVAR

		m.FIELD_TYDS='Logical'
		m.FIELD_UNTY='L'
		INSERT INTO FieldTypes FROM MEMVAR

		m.FIELD_TYDS='Memo'
		m.FIELD_UNTY='M'
		INSERT INTO FieldTypes FROM MEMVAR

		m.FIELD_TYDS='Memo(Binary)'
		m.FIELD_UNTY='MB'
		INSERT INTO FieldTypes FROM MEMVAR

		m.FIELD_TYDS='Numeric'
		m.FIELD_UNTY='N'
		INSERT INTO FieldTypes FROM MEMVAR

		m.FIELD_TYDS='Varbinary'
		m.FIELD_UNTY='Q'
		INSERT INTO FieldTypes FROM MEMVAR


		m.FIELD_TYDS='Varchar'
		m.FIELD_UNTY='V'
		INSERT INTO FieldTypes FROM MEMVAR

		m.FIELD_TYDS='Varchar(Binary)'
		m.FIELD_UNTY='VB'
		INSERT INTO FieldTypes FROM MEMVAR

		*        browse normal
		*        copy to FieldTypes


		*** Might be redundant all together
		*** Or kept and used for multidetailed structure report maybe
		***********************************************************
		SELECT xcurrent                                          &&
		GO TOP                                                   &&
		REPLACE xcurrent.xdbc   WITH THIS.x_database             &&
		REPLACE xcurrent.xtable WITH THIS.x_table                &&
		***********************************************************






	PROCEDURE close_cursors

		SELECT xcurrent
		USE

		SELECT table_fields
		USE

		SELECT table_indexes
		USE

		SELECT table_self
		USE

		****************************
		SELECT origfields
		USE

		SELECT origkeys
		USE

		SELECT origtable
		USE

		SELECT FieldTypes
		USE



	PROCEDURE set_property_all
		LPARAMETERS cfield,cXproperty
		LOCAL cfield,cXproperty,ok_pressed
		SELECT table_fields
		GO TOP
		DO FORM .\FORMS\property_sheet.scx WITH THIS,cfield,cXproperty

	PROCEDURE register_edit_form
		LPARAMETERS oEditForm
		THIS.nSubFormCount=THIS.nSubFormCount+1
		THIS.aSubForms(THIS.nSubFormCount)=oEditForm



	PROCEDURE new_id
		THIS.x_tdx_id = THIS.x_tdx_id+1
		RETURN THIS.x_tdx_id



	PROCEDURE ReadIndexProperties
		LOCAL I
		SELECT table_indexes
		SCATTER MEMVAR BLANK
		SELECT (THIS.x_alias)
		FOR I = 1 TO 254
			IF !EMPTY(TAG(I))  && Checks for tags in the index
				m.xtagname=UPPER(TAG(I))
				*    set order to (m.xtagname)
				m.xtagexp =KEY(I)
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
				INSERT INTO origkeys FROM MEMVAR

			ENDIF
		NEXT
		SELECT table_indexes
		GO TOP



	PROCEDURE ReadFieldProperties
		LPARAMETERS cTable
		LOCAL cTable,cFieldName,I


		IF THIS.x_BelongsToDatabase
			SET DATABASE TO (THIS.x_database)
		ENDIF

		SELECT (THIS.x_alias)
		COPY STRUCTURE EXTENDED TO temp

		USE temp IN 0 EXCLUSIVE
		SELECT temp

		GO TOP
		I=0
		SCAN
			I=I+1
			SCATTER MEMVAR MEMO
			m.TDX_ID = THIS.new_id()
			m.FIELD_NO   = PADL(ALLTRIM(STR(I)),3,'0')
			m.FIELD_UNTY  = '  '  &&Unique Type Code - Gets value in below method call
			m.FIELD_TYDS = THIS.field_type2name(temp.FIELD_TYPE , temp.FIELD_NOCP , temp.FIELD_STEP )
			SELECT (THIS.x_alias)
			cFieldName=THIS.x_alias + '.' + ALLT(m.FIELD_NAME)

			IF THIS.x_BelongsToDatabase

				m.FIELD_CAPT = DBGETPROP(cFieldName, "Field", "Caption")
				m.FIELD_INPM = DBGETPROP(cFieldName, "Field", "Inputmask")
				m.FIELD_FMT  = DBGETPROP(cFieldName, "Field", "Format")
				m.FIELD_COMM = DBGETPROP(cFieldName, "Field", "Comment")
				m.FIELD_CLLB = DBGETPROP(cFieldName, "Field", "DisplayClassLibrary")
				m.FIELD_CLSS = DBGETPROP(cFieldName, "Field", "DisplayClass")

			ENDIF

			INSERT INTO table_fields FROM MEMVAR
			INSERT INTO origfields     FROM MEMVAR

			IF I=1
				INSERT INTO table_self   FROM MEMVAR
			ENDIF

			SELECT temp
		ENDSCAN
		SELECT temp
		USE
		ERASE temp.*
		SELECT table_fields
		*       browse normal
		GO TOP

	PROCEDURE ReadTableProperties
		SELECT (THIS.x_alias)
		THIS.x_reccount=RECCOUNT()
		THIS.x_recsize =RECSIZE()
		THIS.x_cpdbf   =CPDBF()
		THIS.x_fcount  =FCOUNT()

		IF THIS.x_BelongsToDatabase

			m.TABLE_PATH  = DBGETPROP( THIS.x_alias , "Table", "Path")

			m.TABLE_RULE  = DBGETPROP( THIS.x_alias , "Table", "RuleExpression")
			m.TABLE_ERR   = DBGETPROP( THIS.x_alias , "Table", "RuleExpression")

			m.TABLE_INS   = DBGETPROP( THIS.x_alias , "Table", "InsertTrigger")
			m.TABLE_UPD   = DBGETPROP( THIS.x_alias , "Table", "UpdateTrigger")
			m.TABLE_DEL   = DBGETPROP( THIS.x_alias , "Table", "DeleteTrigger")

			m.TABLE_CMT   = DBGETPROP( THIS.x_alias , "Table", "Comment")

		ENDIF

		SELECT table_self
		GATHER MEMVAR  &&Record is already added and table name written

		SCATTER MEMVAR
		INSERT INTO origtable FROM MEMVAR



	PROCEDURE save_changes
		THIS.ReleaseSubForms()
		***We would need exclusive acces only at this point
		THIS.SaveCorePropertiesField()
		THIS.SaveCorePropertiesIndex()
		THIS.SaveTableProperties()


		SELECT xcurrent
		*browse normal
		SCATTER NAME oLogRec
		oLogRec.xcommit=DATETIME()

		IF TYPE('oTDXLOG.NAME') = 'C'
			oTDXLOG.Dump2LogTable(oLogRec)
			*oTDXLOG.browse_log()
		ENDIF

		THIS.oFrontForm=.F.
		THIS.LoadTableStructure()



	PROCEDURE revert_changes
		THIS.ReleaseSubForms()
		THIS.oFrontForm=.F.
		THIS.LoadTableStructure()




	PROCEDURE CheckForFieldChanges
		SELECT table_fields
		LOCAL sv_rec
		sv_rec=RECNO()
		GO TOP
		SCAN
			THIS.UpdateChangeStatus()
		ENDSCAN
		SELECT table_fields
		GO sv_rec



	PROCEDURE UpdateChangeStatus
		SELECT table_fields
		LOCAL oFR,oBR
		REPLACE table_fields.TDX_STAT WITH  ' '  &&Reset back tdx_stat
		SCATTER NAME oFR
		IF SEEK(table_fields.TDX_ID,'origfields','fldid')
			SELECT origfields
			SCATTER NAME oBR
			SELECT table_fields
			IF COMPOBJ(oBR,oFR)
				REPLACE table_fields.TDX_STAT WITH  ' '  &&No Changes
			ELSE
				REPLACE table_fields.TDX_STAT WITH 'C'  &&Changed
			ENDIF
			RETURN
		ENDIF
		**It is New Field
		REPLACE table_fields.TDX_STAT WITH 'N'  &&New





	PROCEDURE SaveCorePropertiesField
		LOCAL aa
		SELECT (THIS.x_alias)


		SELECT table_fields
		GO TOP



		SCAN

			****Primitive saving for dbc held properties via DBSetProp
			****Major aproach/procedure will be needed here

			IF !THIS.x_BelongsToDatabase  &&Skip for free tables
				LOOP
			ENDIF

			aa = THIS.x_alias + '.' + ALLT(table_fields.FIELD_NAME)

			*** BYN 01/11/2007 PADR() instead of ALLTRIM() because
			***                DBGETPROP() returns trimmed values
			IF PADR(DBGETPROP(aa, "Field", "Caption"), 254) <> table_fields.FIELD_CAPT
				DBSETPROP(aa, "Field", "Caption",ALLT(table_fields.FIELD_CAPT))
			ENDIF

			IF PADR(DBGETPROP(aa, "Field", "Inputmask"), 254) <> table_fields.FIELD_IMSK
				DBSETPROP(aa, "Field", "Inputmask",ALLT(table_fields.FIELD_IMSK))
			ENDIF

			IF PADR(DBGETPROP(aa, "Field", "Format"), 254) <> table_fields.FIELD_FMT
				DBSETPROP(aa, "Field", "Format",ALLT(table_fields.FIELD_FMT))
			ENDIF

			IF PADR(DBGETPROP(aa, "Field", "Comment"), 254) <> table_fields.FIELD_COMM
				DBSETPROP(aa, "Field", "Comment",ALLT(table_fields.FIELD_COMM))
			ENDIF


			*** BYN 01/11/2007 if either are empty ythe other should be empty too
			IF EMPTY(ALLT(table_fields.FIELD_CLLB)) OR EMPTY(ALLT(table_fields.FIELD_CLSS))
				REPLACE table_fields.FIELD_CLLB WITH "", ;
					table_fields.FIELD_CLSS WITH ""
			ENDIF

			IF PADR(DBGETPROP(aa, "Field", "DisplayClassLibrary"), 254) <> table_fields.FIELD_CLLB
				DBSETPROP(aa, "Field", "DisplayClassLibrary",table_fields.FIELD_CLLB)
			ENDIF

			IF PADR(DBGETPROP(aa, "Field", "DisplayClass"), 254) <> table_fields.FIELD_CLSS
				DBSETPROP(aa, "Field", "DisplayClass",table_fields.FIELD_CLSS)
			ENDIF
		ENDSCAN


	PROCEDURE SaveTableProperties
		**To be developed


	PROCEDURE SaveCorePropertiesIndex
		**To be developed





	PROCEDURE ReleaseOpenForms
		***** 04 OCT 2007 Djordjevic Srdjan

		THIS.ReleaseSubForms()

		IF TYPE('this.oFrontForm.name') = 'C'
			THIS.oFrontForm.RELEASE
		ENDIF


	PROCEDURE ReleaseSubForms
		***** 04 OCT 2007 Djordjevic Srdjan
		LOCAL I,oSubForm
		FOR I=1 TO 100
			oSubForm=THIS.aSubForms(I)
			IF TYPE('oSubForm.name') ='C'
				oSubForm.RELEASE
				THIS.aSubForms(I)=.F.
			ENDIF
		NEXT
		THIS.nSubFormCount=0




		******************************************************
		* Utilities
		******************************************************


	PROCEDURE field_type2name
		LPARAMETERS cType,lNoCp,nStep
		m.FIELD_UNTY = cType
		DO CASE

			CASE cType='W'
				RETURN 'Blob'

			CASE cType='C'
				IF lNoCp
					m.FIELD_UNTY='CB'
					RETURN 'Character(Binary)'
				ELSE
					RETURN 'Character'
				ENDIF


			CASE cType='N'
				RETURN 'Numeric'


			CASE cType='D'
				RETURN 'Date'

			CASE cType='T'
				RETURN 'DateTime'


			CASE cType='I'
				IF nStep > 0
					m.FIELD_UNTY='IA'
					RETURN 'Integer(AutoInc)'
				ELSE
					RETURN 'Integer'
				ENDIF

			CASE cType='L'
				RETURN 'Logical'

			CASE cType='Y'
				RETURN 'Currency'


			CASE cType='M'
				IF lNoCp
					m.FIELD_UNTY='MB'
					RETURN 'Memo(Binary)'
				ELSE
					RETURN 'Memo'
				ENDIF



			CASE cType='G'
				RETURN 'General'


			CASE cType='V'
				IF lNoCp
					m.FIELD_UNTY='VB'
					RETURN 'Varchar(Binary)'
				ELSE
					RETURN 'Varchar'
				ENDIF

			CASE cType='B'
				RETURN 'Double'

			CASE cType='F'
				RETURN 'Float'

			CASE cType='Q'
				RETURN 'Varbinary'

			OTHERWISE
				RETURN cType + '- Unknown Type'

		ENDCASE






		************************************************************
		*  THE END
		************************************************************
ENDDEFINE




DEFINE CLASS tdx_log AS SESSION
	x_logtable='tdxlog.dbf'
	x_last_edited=''




	PROCEDURE INIT
		=tdx_set_sys_env()
		THIS.open_tables()


	PROCEDURE open_tables
		IF !FILE(THIS.x_logtable) &&
			THIS.create_log_dbf()
		ENDIF
		USE (THIS.x_logtable) IN 0 SHARED ALIAS tdxlog
		SELECT tdxlog
		GO BOTTOM
		THIS.x_last_edited = tdxlog.xtable
		GO TOP




	PROCEDURE create_log_dbf
		LOCAL cLogTable
		cLogTable = JUSTSTEM(THIS.x_logtable)
		CREATE TABLE &cLogTable  FREE ;
			(xdbc        C(100) , ;
			xtable      C(100) , ;
			xstart       T  , ;
			xcommit      T  )

		SELECT  (  cLogTable )
		USE


	PROCEDURE Dump2LogTable
		LPARAMETERS oRec
		SELECT tdxlog
		APPEND BLANK
		GATHER NAME oRec

	PROCEDURE populate_combo_recent
		LPARAMETERS oList
		SELECT tdxlog
		GO BOTTOM
		IF EOF()
			oList.ENABLED=.F.
			RETURN
		ENDIF

		oList.VALUE=tdxlog.xtable

		SELECT DISTINCT tdxlog.xtable FROM tdxlog INTO CURSOR RECENTLYUSED
		LOCAL I
		SCAN
			IF !FILE(RECENTLYUSED.xtable)
				LOOP
			ENDIF
			IF oList.LISTCOUNT < 50
				oList.ADDITEM(RECENTLYUSED.xtable)
			ELSE
				EXIT
			ENDIF
		ENDSCAN
		SELECT RECENTLYUSED
		USE

	PROCEDURE browse_log
		SELECT tdxlog
		BROWSE NORMAL


ENDDEFINE



FUNCTION tdxSetup
	LPARAMETERS cRoot

	SET DEFAULT TO (cRoot)
	SET PATH TO (cRoot)
	SET PATH TO ;DATA;INCLUDE;FORMS;BITMAPS;HELP;LIBS;MENUS;PROGS;TEMPLATES;REPORTS ADDITIVE

	LOCAL cProc
	cProc=SET('PROCEDURE')
	IF !'TABLE_MANAGER'$cProc
		SET PROCEDURE TO ( cRoot + '\progs\table_manager.prg' )  ADDITIVE
	ENDIF

	IF TYPE('oTDXLOG.NAME') <> 'C'
		PUBLIC oTDXLOG
		oTDXLOG=CREATEOBJECT('tdx_log')
	ENDIF




	****************** Utility Functions*******************
	*                                                     *
	*******************************************************

FUNCTION tdx_set_sys_env
	******************Default Environment Settings
	SET TALK OFF
	SET CONSOLE OFF
	SET CENTURY ON
	SET DELETED ON
	SET EXCLUSIVE OFF
	SET SAFETY ON
	SET DELETED ON
	SET CENTURY ON
	SET DATE TO british
	SET NEAR OFF
	*******************

	***************************
	* Simple Messagebox Wrapper
	***************************
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

	ENDCASE


	*Unused yet by tdx but might come handy later
FUNCTION StringToArray
	LPARAMETERS pstring,pdlm,myarray
	*******************************************************
	* String to array conversion
	*******************************************************
	** receives Delimited String, Dlm.Char and array passed
	** by reference
	** Fills up that array with delimited values
	** Returns number of those values (array size)
	*******************************************************
	DECLARE myarray(OCCURS(pdlm,pstring)+1)
	FOR I = 1 TO ALEN(myarray)
		IF ATC(pdlm,pstring)>0
			myarray(I)=LEFT(pstring,ATC(pdlm,pstring)-1)
			pstring=RIGHT(pstring,LEN(pstring)-ATC(pdlm,pstring))
		ELSE
			myarray(I)=pstring
		ENDIF
	NEXT
	RETURN ALEN(myarray)


FUNCTION in_brackets
	LPARAMETERS cString
	RETURN '[' + cString + ']'

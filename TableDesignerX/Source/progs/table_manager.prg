=tdxSetup( justpath(justpath( sys(16) )))
do form run_tdx.scx  &&Run Control Panel Form


*************************************************************
* Table Designer X - Engine
* Prototype
*************************************************************
define class TableDesignerX as session
    x_designerform ='.\forms\TableDesignerX.scx'

    x_table=''
    x_table_name=''

    x_database=''
    x_database_name=''

    x_alias=''

    x_BelongsToDatabase=.f.

    x_tdx_id = 0  &&Counter for session unique field ID


    ****************
    x_reccount=0
    x_recsize=0
    x_cpdbf=0
    x_fcount =0
    ****************


    **** Object References to UI Forms
    oFrontForm=.f.

    nSubFormCount=0
    declare aSubForms(100)
    ***********************************

    procedure init
        lparameters cTable
        =tdx_set_sys_env()
        this.x_table = proper(cTable)
        this.x_table_name=justfname(cTable)

        if !this.open_selected_table()
            messagebox('Could not Open table - Exclusive access needed!')
            return .f.
        endif

        select ( juststem(this.x_table)  )
        this.x_alias = alias()
        this.x_database =  proper( cursorgetprop("Database") )  && Displays database name

        if len(allt(this.x_database)) > 0
            this.x_database_name=justfname(this.x_database)
            this.x_BelongsToDatabase=.t.
            open database (this.x_database) shared
        else
            this.x_database = 'Free Table'
            this.x_BelongsToDatabase=.f.
        endif


        return .t.



    procedure open_selected_table
        local ok, oErr as exception
        ok=.t.
        try
            use (this.x_table) in 0 exclusive

        catch to oErr
            if oErr.errorno > 0
                ok=.f.
            endif
        endtry
        return ok



    procedure LoadTableStructure
        *************************
        this.CreateCursors()
        this.ReadFieldProperties()
        this.ReadIndexProperties()
        this.ReadTableProperties()
        **************************



    procedure modify_structure
        this.LoadTableStructure()
        this.ShowInterface()


    procedure  ShowInterface
        select table_fields
        go top
        this.CheckForFieldChanges()
        do form (this.x_designerform) with this



    procedure CreateCursors
        **Structure compatible with temp. table created by
        **copy structure extended + set of fields necessary
        **to hold other field properties + few utility fields
        ** Djordjevic Srdjan 03 Oct 2007
        create cursor table_fields  (  ;
            TDX_ID      I(4)  , ;
            TDX_STAT    C(1)  , ;
            FIELD_NO    C(3)  , ;
            FIELD_NAME  C(20) , ;
            FIELD_TYPE  C(1)  , ;
            FIELD_UNTY  C(2)  , ;
            FIELD_TYDS  C(20) , ;
            FIELD_LEN   n(3,0), ;
            FIELD_DEC   n(3,0), ;
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

        local aStru1(1)
        afields(aStru1)
        create cursor origfields from array aStru1
        index on TDX_ID tag fldid
        set order to fldid




        create cursor table_self (  ;
            TABLE_NAME   C(128), ;
            TABLE_PATH   C(254), ;
            TABLE_RULE   C(254), ;
            TABLE_RUTX   C(254), ;
            TABLE_ERR   C(254), ;
            TABLE_INS   C(254), ;
            TABLE_UPD   C(254), ;
            TABLE_DEL   C(254), ;
            TABLE_CMT C(254))

        local aStru2(1)
        afields(aStru2)
        create cursor origtable from array aStru2



        create cursor table_indexes  (  ;
            xtagno       C(3)   , ;
            xtagname     C(20)  , ;
            xtagexp      C(254) , ;
            xtagtype     C(10)  , ;
            xtagasc      C(1)  , ;
            xtagfilter   C(254))
        index on xtagno tag xkey


        local aStru3(1)
        afields(aStru3)
        create cursor origkeys from array aStru3



        create cursor xcurrent (  ;
            xdbc   C(100) , ;
            xtable C(100) , ;
            xstart t  , ;
            xcommit t  )

        select xcurrent
        scatter memvar blank
        m.xstart = datetime()
        insert into xcurrent from memvar
        go top


        create cursor FieldTypes  (  ;
            FIELD_TYDS  C(20),   ;
            FIELD_UNTY   C(2))

        m.FIELD_TYDS='Blob'
        m.FIELD_UNTY='W'
        insert into FieldTypes from memvar

        m.FIELD_TYDS='Character'
        m.FIELD_UNTY='C'
        insert into FieldTypes from memvar

        m.FIELD_TYDS='Character(Binary)'
        m.FIELD_UNTY='CB'
        insert into FieldTypes from memvar

        m.FIELD_TYDS='Currency'
        m.FIELD_UNTY='Y'
        insert into FieldTypes from memvar

        m.FIELD_TYDS='Date'
        m.FIELD_UNTY='D'
        insert into FieldTypes from memvar

        m.FIELD_TYDS='DateTime'
        m.FIELD_UNTY='T'
        insert into FieldTypes from memvar

        m.FIELD_TYDS='Double'
        m.FIELD_UNTY='B'
        insert into FieldTypes from memvar

        m.FIELD_TYDS='Float'
        m.FIELD_UNTY='F'
        insert into FieldTypes from memvar

        m.FIELD_TYDS='General'
        m.FIELD_UNTY='G'
        insert into FieldTypes from memvar

        m.FIELD_TYDS='Integer'
        m.FIELD_UNTY='I'
        insert into FieldTypes from memvar

        m.FIELD_TYDS='Integer(AutoInc)'
        m.FIELD_UNTY='IA'
        insert into FieldTypes from memvar

        m.FIELD_TYDS='Logical'
        m.FIELD_UNTY='L'
        insert into FieldTypes from memvar

        m.FIELD_TYDS='Memo'
        m.FIELD_UNTY='M'
        insert into FieldTypes from memvar

        m.FIELD_TYDS='Memo(Binary)'
        m.FIELD_UNTY='MB'
        insert into FieldTypes from memvar

        m.FIELD_TYDS='Numeric'
        m.FIELD_UNTY='N'
        insert into FieldTypes from memvar

        m.FIELD_TYDS='Varbinary'
        m.FIELD_UNTY='Q'
        insert into FieldTypes from memvar


        m.FIELD_TYDS='Varchar'
        m.FIELD_UNTY='V'
        insert into FieldTypes from memvar

        m.FIELD_TYDS='Varchar(Binary)'
        m.FIELD_UNTY='VB'
        insert into FieldTypes from memvar

        *        browse normal
        *        copy to FieldTypes


        *** Might be redundant all together
        *** Or kept and used for multidetailed structure report maybe
        ***********************************************************
        select xcurrent                                          &&
        go top                                                   &&
        replace xcurrent.xdbc   with this.x_database             &&
        replace xcurrent.xtable with this.x_table                &&
        ***********************************************************






    procedure close_cursors

        select xcurrent
        use

        select table_fields
        use

        select table_indexes
        use

        select table_self
        use

        ****************************
        select origfields

        use

        select origkeys
        use

        select origtable

        use

        select FieldTypes
        use



    procedure set_property_all
        lparameters cfield,cXproperty
        local cfield,cXproperty,ok_pressed
        select table_fields
        go top
        do form .\forms\property_sheet.scx with this,cfield,cXproperty

    procedure register_edit_form
        lparameters oEditForm
        this.nSubFormCount=this.nSubFormCount+1
        this.aSubForms(this.nSubFormCount)=oEditForm



    procedure new_id
        this.x_tdx_id = this.x_tdx_id+1
        return this.x_tdx_id



    procedure ReadIndexProperties
        local I
        select table_indexes
        scatter memvar blank
        select (this.x_alias)
        for I = 1 to 254
            if !empty(tag(I))  && Checks for tags in the index
                m.xtagname=upper(tag(I))
                *    set order to (m.xtagname)
                m.xtagexp =key(I)
                m.xtagno  =tagno(m.xtagname)
                do case

                    case primary(m.xtagno)
                        m.xtagtype='PRIMARY'

                    case candidate(m.xtagno)
                        m.xtagtype='CANDIDATE'

                    otherwise
                        m.xtagtype='REGULAR'

                endcase
                m.xtagfilter=sys(2021,m.xtagno)
                m.xtagasc  =iif(descending(m.xtagno),'D','A')
                m.xtagno=str(m.xtagno,3,0)
                insert into table_indexes from memvar
                insert into origkeys from memvar

            endif
        next
        select table_indexes
        go top



    procedure ReadFieldProperties
        lparameters cTable
        local cTable,cFieldName,I


        if this.x_BelongsToDatabase
            set database to (this.x_database)
        endif

        select (this.x_alias)
        copy structure extended to temp



        use temp in 0 exclusive
        select temp
        go top
        I=0
        scan
            I=I+1
            scatter memvar memo
            m.TDX_ID = this.new_id()
            m.FIELD_NO   = padl(alltrim(str(I)),3,'0')
            m.FIELD_UNTY  = '  '  &&Unique Type Code - Gets value in below method call
            m.FIELD_TYDS = this.field_type2name(temp.FIELD_TYPE , temp.FIELD_NOCP , temp.FIELD_STEP )
            select (this.x_alias)
            cFieldName=this.x_alias + '.' + allt(m.FIELD_NAME)

            if this.x_BelongsToDatabase

                m.FIELD_CAPT = dbgetprop(cFieldName, "Field", "Caption")
                m.FIELD_IMSK = dbgetprop(cFieldName, "Field", "Inputmask")
                m.FIELD_FMT  = dbgetprop(cFieldName, "Field", "Format")
                m.FIELD_COMM = dbgetprop(cFieldName, "Field", "Comment")
                m.FIELD_CLLB = dbgetprop(cFieldName, "Field", "DisplayClassLibrary")
                m.FIELD_CLSS = dbgetprop(cFieldName, "Field", "DisplayClass")

            endif

            insert into table_fields from memvar
            insert into origfields     from memvar

            if I=1
                insert into table_self   from memvar
            endif

            select temp
        endscan
        select temp
        use
        erase temp.*
        select table_fields
        *       browse normal
        go top

    procedure ReadTableProperties
        select (this.x_alias)
        this.x_reccount=reccount()
        this.x_recsize =recsize()
        this.x_cpdbf   =cpdbf()
        this.x_fcount  =fcount()

        if this.x_BelongsToDatabase

            m.TABLE_PATH  = dbgetprop( this.x_alias , "Table", "Path")

            m.TABLE_RULE  = dbgetprop( this.x_alias , "Table", "RuleExpression")
            m.TABLE_ERR   = dbgetprop( this.x_alias , "Table", "RuleExpression")

            m.TABLE_INS   = dbgetprop( this.x_alias , "Table", "InsertTrigger")
            m.TABLE_UPD   = dbgetprop( this.x_alias , "Table", "UpdateTrigger")
            m.TABLE_DEL   = dbgetprop( this.x_alias , "Table", "DeleteTrigger")

            m.TABLE_CMT   = dbgetprop( this.x_alias , "Table", "Comment")

        endif

        select table_self
        gather memvar  &&Record is already added and table name written

        scatter memvar
        insert into origtable from memvar



    procedure save_changes
        this.ReleaseSubForms()
        ***We would need exclusive acces only at this point
        this.SaveCorePropertiesField()
        this.SaveCorePropertiesIndex()
        this.SaveTableProperties()


        select xcurrent
        *browse normal
        scatter name oLogRec
        oLogRec.xcommit=datetime()

        if type('oTDXLOG.NAME') = 'C'
            oTDXLOG.Dump2LogTable(oLogRec)
            *oTDXLOG.browse_log()
        endif

        this.oFrontForm=.f.
        this.LoadTableStructure()



    procedure revert_changes
        this.ReleaseSubForms()
        this.oFrontForm=.f.
        this.LoadTableStructure()




    procedure CheckForFieldChanges
        select table_fields
        local sv_rec
        sv_rec=recno()
        go top
        scan
            this.UpdateChangeStatus()
        endscan
        select table_fields
        go sv_rec




    procedure UpdateChangeStatus
        select table_fields
        local oFR,oBR
        replace table_fields.TDX_STAT with  ' '  &&Reset back tdx_stat
        scatter name oFR
        if seek(table_fields.TDX_ID,'origfields','fldid')
            select origfields
            scatter name oBR
            select table_fields
            if compobj(oBR,oFR)
                replace table_fields.TDX_STAT with  ' '  &&No Changes
            else
                replace table_fields.TDX_STAT with 'C'  &&Changed
            endif
            return
        endif
        **It is New Field
        replace table_fields.TDX_STAT with 'N'  &&New





    procedure SaveCorePropertiesField
        local aa
        select (this.x_alias)


        select table_fields
        go top



        scan

            ****Primitive saving for dbc held properties via DBSetProp
            ****Major aproach/procedure will be needed here

            if !this.x_BelongsToDatabase  &&Skip for free tables
                loop
            endif

            aa=this.x_alias + '.' + allt(table_fields.FIELD_NAME)

            if alltr(dbgetprop(aa, "Field", "Caption")) <> allt(table_fields.FIELD_CAPT)
                =dbsetprop(aa, "Field", "Caption",allt(table_fields.FIELD_CAPT))
            endif

            if allt(dbgetprop(aa, "Field", "Inputmask")) <> allt(table_fields.FIELD_IMSK)
                =dbsetprop(aa, "Field", "Inputmask",allt(table_fields.FIELD_IMSK))
            endif

            if allt(dbgetprop(aa, "Field", "Format"))<>allt(table_fields.FIELD_FMT)
                =dbsetprop(aa, "Field", "Format",allt(table_fields.FIELD_FMT))
            endif

            if allt(dbgetprop(aa, "Field", "Comment")) <> allt(table_fields.FIELD_COMM)
                =dbsetprop(aa, "Field", "Comment",allt(table_fields.FIELD_COMM))
            endif


            if empty(allt(table_fields.FIELD_CLLB)) or empty(allt(table_fields.FIELD_CLSS))
                loop
            endif

            if allt(dbgetprop(aa, "Field", "DisplayClassLibrary")) <> allt(table_fields.FIELD_CLLB)
                =dbsetprop(aa, "Field", "DisplayClassLibrary",table_fields.FIELD_CLLB)
            endif

            if allt(dbgetprop(aa, "Field", "DisplayClass")) <> allt(table_fields.FIELD_CLSS)
                =dbsetprop(aa, "Field", "DisplayClass",table_fields.FIELD_CLSS)
            endif

        endscan

    procedure SaveTableProperties
        **To be developed

    procedure SaveCorePropertiesIndex
        **To be developed





    procedure ReleaseOpenForms
        ***** 04 OCT 2007 Djordjevic Srdjan
        this.ReleaseSubForms()

        if type('this.oFrontForm.name') = 'C'
            this.oFrontForm.release
        endif


    procedure ReleaseSubForms
        ***** 04 OCT 2007 Djordjevic Srdjan
        local I,oSubForm
        for I=1 to 100
            oSubForm=this.aSubForms(I)
            if type('oSubForm.name') ='C'
                oSubForm.release
                this.aSubForms(I)=.f.
            endif
        next
        this.nSubFormCount=0




        ******************************************************
        * Utilities
        ******************************************************


    procedure field_type2name
        lparameters cType,lNoCp,nStep
        m.FIELD_UNTY = cType
        do case

            case cType='W'
                return 'Blob'

            case cType='C'
                if lNoCp
                    m.FIELD_UNTY='CB'
                    return 'Character(Binary)'
                else
                    return 'Character'
                endif


            case cType='N'
                return 'Numeric'


            case cType='D'
                return 'Date'

            case cType='T'
                return 'DateTime'


            case cType='I'
                if nStep > 0
                    m.FIELD_UNTY='IA'
                    return 'Integer(AutoInc)'
                else
                    return 'Integer'
                endif

            case cType='L'
                return 'Logical'

            case cType='Y'
                return 'Currency'


            case cType='M'
                if lNoCp
                    m.FIELD_UNTY='MB'
                    return 'Memo(Binary)'
                else
                    return 'Memo'
                endif



            case cType='G'
                return 'General'


            case cType='V'
                if lNoCp
                    m.FIELD_UNTY='VB'
                    return 'Varchar(Binary)'
                else
                    return 'Varchar'
                endif

            case cType='B'
                return 'Double'

            case cType='F'
                return 'Float'

            case cType='Q'
                return 'Varbinary'

            otherwise
                return cType + '- Unknown Type'

        endcase






        ************************************************************
        *  THE END
        ************************************************************
enddefine




define class tdx_log as session
    x_logtable='tdxlog.dbf'
    x_last_edited=''




    procedure init
        =tdx_set_sys_env()
        this.open_tables()


    procedure open_tables
        if !file(this.x_logtable) &&
            this.create_log_dbf()
        endif
        use (this.x_logtable) in 0 shared alias tdxlog
        select tdxlog
        go bottom
        this.x_last_edited = tdxlog.xtable
        go top




    procedure create_log_dbf
        local cLogTable
        cLogTable = juststem(this.x_logtable)
        create table &cLogTable  free ;
            (xdbc        C(100) , ;
            xtable      C(100) , ;
            xstart       t  , ;
            xcommit      t  )

        select  (  cLogTable )
        use


    procedure Dump2LogTable
        lparameters oRec
        select tdxlog
        append blank
        gather name oRec

    procedure populate_combo_recent
        lparameters oList
        select tdxlog
        go bottom
        if eof()
            oList.enabled=.f.
            return
        endif

        oList.value=tdxlog.xtable

        select distinct tdxlog.xtable from tdxlog into cursor recentlyused
        local I
        scan
            if !file(recentlyused.xtable)
                loop
            endif
            if oList.listcount < 50
                oList.additem(recentlyused.xtable)
            else
                exit
            endif
        endscan
        select recentlyused
        use

    procedure browse_log
        select tdxlog
        browse normal







enddefine



function dynamicgridcontrol
    lparameters oColumn
    do case

        case oColumn.name='Column3'
            if inlist(table_fields.FIELD_UNTY,'C ','CB','N ','V ','VB','F ','Q ')
                return 'FldLenSpinner'
            else
                return 'NoLenTextBox'
            endif



        case oColumn.name='Column4'
            if inlist(table_fields.FIELD_UNTY,'B ','F ','N ')
                return 'FldDecSpinner'
            else
                return 'NoDecTextBox'
            endif


    endcase










function tdxSetup
    lparameters cRoot

    set default to (cRoot)
    set path to (cRoot)
    set path to ;data;include;forms;BITMAPS;help;LIBS;menus;PROGS;TEMPLATES;REPORTS additive

    local cProc
    cProc=set('PROCEDURE')
    if !'TABLE_MANAGER'$cProc
        set procedure to ( cRoot + '\progs\table_manager.prg' )  additive
    endif

    if type('oTDXLOG.NAME') <> 'C'
        public oTDXLOG
        oTDXLOG=createobject('tdx_log')
    endif




    ****************** Utility Functions*******************
    *                                                     *
    *******************************************************

function tdx_set_sys_env
    ******************Default Environment Settings
    set talk off
    set console off
    set century on
    set deleted on
    set exclusive off
    set safety on
    set deleted on
    set century on
    set date to british
    set near off
    *******************

    ***************************
    * Simple Messagebox Wrapper
    ***************************
function question
    parameters cMessageText
    cMessageTitle = 'Question:'
    nDialogType = 4 + 32 + 256
    *  4 = Yes and No buttons
    *  32 = Question mark icon
    *  256 = Second button is default
    nAnswer = messagebox(cMessageText, nDialogType, cMessageTitle)
    do case

        case nAnswer = 6
            return .t.

        case nAnswer = 7
            return .f.

    endcase


    *Unused yet by tdx but might come handy later
function StringToArray
    lparameters pstring,pdlm,myarray
    *******************************************************
    * String to array conversion
    *******************************************************
    ** receives Delimited String, Dlm.Char and array passed
    ** by reference
    ** Fills up that array with delimited values
    ** Returns number of those values (array size)
    *******************************************************
    declare myarray(occurs(pdlm,pstring)+1)
    for I = 1 to alen(myarray)
        if atc(pdlm,pstring)>0
            myarray(I)=left(pstring,atc(pdlm,pstring)-1)
            pstring=right(pstring,len(pstring)-atc(pdlm,pstring))
        else
            myarray(I)=pstring
        endif
    next
    return alen(myarray)


function in_brackets
    lparameters cString
    return '[' + cString + ']'

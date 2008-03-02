#include wzquery.h

* This is the stub which you should copy (place the modified version in
* your Wizard's directory), rename, and modify to call your wizard.

parameters cOutFileVarName, p2, p3, p4, p5, p6, p7, p8, p9

*- p2:	'R'		remote query
*-		'V'		local view
*-		'Q'		query

LOCAL cWizardToRun
cWizardToRun = ""

private cClassLib
m.cClassLib = set('classlib')

* Modify here to reference your wizard's .vcx.
set classlib to wzquery

public oWizard

PUBLIC wzaQDD[1,6]
PUBLIC wzaQFlds[1]
PUBLIC wzaQSort[1]
PUBLIC wziQSortA	&&1 for ASCEND, 2 for desc
if .f.
	public achoices[1]
endif
wziQsortA=1
PUBLIC wzaQFilt[1,6]
PUBLIC wzaQGrp[1,2]
PUBLIC wzaParent,wzaChild
PUBLIC cOriginalDBC
wzaQDD=""
wzaQFlds=""
wzaQSort=""
wzaQFilt=""
wzaQGrp=""
PUBLIC QWizType	&& Remote,Local,Query
QWizType=IIF(type("p2")='L','Q',UPPER(LEFT(p2,1)))	&&Remote,Local,Query
IF !m.qWizType$"RVQ"
	RELEASE qWizType
	return .f.
ENDIF

*save the current DBC
cOriginalDBC = SET("DATA")

* The name "oWizard" is used in automated testing and should *NOT* be changed.

oWizard = createobj(IIF(m.qWizType='R','wzrquery','wzbquery'), m.cOutFileVarName, m.p2, m.p3, m.p4, ;
	m.p5, m.p6, m.p7, m.p8, m.p9)

if type('oWizard') = 'O' .and. .not. isnull(oWizard)
	oEngine.aEnvironment[17,1] = m.cClassLib
	if type("starttime")#'U'
		*do not localize:
		wait window nowait "time = "+str(seconds()-starttime,10,4)
	endif
	if type("fp")#'U'
		=fclose(fp)
	endif
	oWizard.Show
ELSE
endif
if type('oWizard') = 'O' .and. .not. isnull(oWizard)
	* It must be modeless, so leave it alone
else
	release oWizard
	RELEASE wzaQDD,wzaQFlds,wzaQSort,wzaQGrp,wzaQFilt,wzaParent,wzaChild,wziQSorta, cOriginalDBC
	cWizardToRun = IIF(IIF(type("p2")='L','Q',UPPER(LEFT(p2,1))) = 'R','wzrquery','wzbquery')
	CLEAR CLASS &cWizardToRun
	CLEAR CLASS wiztemplate
endif

return


*******************************************
#define MAXPATH 50

DEFINE CLASS wzQueryEng as WizEngineAll
	mdev=iif(file("\calvinh.txt") AND left(getenv("computername"),6)="CALVIN",.t.,.f.)
	mSaveDeleted=Set("deleted")
	mSaveExact=Set("exact")
	mSaveTrbe=set("trbetween")	
	
	cServer=""

	cWzDBC=""
	cConnect=""
	cDriver=""
	nConnectHandle=0
	cOuterJoin=0
	cWizFiltExpr=""	&& filled in by SearchClass
	lIsPreview=.f.
	nSaveOptions=1
	wzsFilename=""
	wzsViewname=""
	
	nJoinOption = 1	&& inner join (1), left outer (2), right outer (3), full (4)
	nAmount = -1	&& all records (-1) n records (n)
	nPortion = 1	&& percentage (1), number (2)
	lOdbcJoin = .T.	&& Odbc join escape sequence
	UserInput = ""
	UserName = ""	&&user name return by the connection to Oracle server	

*Filter page:
	cValue="c:\fox30\samples\data\nwind.dbc"
	
	DIMENSION aODBCDSNs[1,2]
	aODBCDSNs = ""
	
	proc error
		para nError,cMethod,nLine
		IF nError=1523
			RETURN
		ENDIF
		IF UPPER(m.cMethod)='PREVIEWQ'
			m.error=m.nError
			RETURN
		ENDIF
		IF UPPER(m.cMethod)='PROCESSOUTPUT'
			m.error=m.nError
			RETURN
		ENDIF
		wizengineall::error(m.nError,m.cMethod,m.nLine)
	proc init2
		set safe off
		set dele on
		set exact off
		if m.qwiztype='Q'
			set exclusive off
		ELSE
			set exclusive on
		endif
		if this.mdev
			on key label f2 do showdd
			set esca on
			set trbetween off
		endif
	endproc
	proc destroy
		wizengineall::destroy()
		if this.mdev
			on key label f2
		endif
		if this.nConnectHandle>0
			=SQLDisconnect(this.nConnectHandle)
		endif
		local mt
		mt=this.mSaveDeleted
		set dele &mt
		mt=this.mSaveExact
		set exact &mt
		if this.msavetrbe="ON"
			set trbe on
		endif
		RELEASE wzaQDD,qwiztype,wzaQflds,wzaQGrp,wzaQSort,wzaParent,wzachild,wzaQFilt,wziQSorta,aWizFList, cOriginalDBC
	PROCEDURE insaitem
		* Inserts an array element into an array.
		* For 1-D or 2D array
		* returns the row #that was inserted.
		LPARAMETER aArray,sContents,wziRow
		if alen(aArray,2)=0 &&it's a 1-D array
			IF ALEN(aArray) = 1 AND EMPTY(aArray[1])
				aArray[1]=m.sContents
				wziRow=1
			ELSE
				DIMENSION aArray[ALEN(aArray)+1]
				IF PARAM()=2
					wziRow=ALEN(aArray)
					aArray[m.wziRow]=m.sContents
				ELSE
					=AINS(aArray,m.wziRow)
					aArray[m.wziRow]=m.sContents
				ENDIF	
			ENDIF
		else	&&it's a 2D array
			if ALEN(aArray,1)=1
				wziRow=1
				if !empty(aArray[1,1])
					dime aArray[2,alen(aArray,2)]
					=ains(aArray,1)
				endif
			else
				if type("wziRow")#'N'
					wziRow=ALEN(aArray,1)
				endif
				if m.wziRow>ALEN(aArray,1)
					wziRow=ALEN(aArray,1)
				endif
				dime aArray[ALEN(aArray,1)+1,ALEN(aArray,2)]
				=ains(aArray,m.wziRow)
			endif
			aArray[m.wziRow,1]=m.sContents
		endif
		return m.wziRow
	ENDPROC

	PROCEDURE delaitem
		* Generic routine to delete an array element.
		* works with 1 or 2 D array
		LPARAMETERS aArray,wziRow
		IF ALEN(aArray,1)>=m.wziRow
			IF ALEN(aArray,1)=1
				aArray=''
			ELSE
				=ADEL(aArray,m.wziRow)
				if ALEN(aArray,2)=0
					DIMENSION aArray[ALEN(aArray)-1]
				else
					DIMENSION aArray[ALEN(aArray,1)-1,ALEN(aArray,2)]
				endif
			ENDIF
		ENDIF
	ENDPROC
	proc thealias
		para m.name
	return LEFTC(m.name,AT_C('.',m.name)-1)

	PROCEDURE TheField
		PARAMETERS strng
		PRIVATE m.t
		m.t=SUBSTRC(m.strng,AT_C(".",m.strng)+1)
	RETURN IIF(m.t='(',m.t,ALLTRIM(LEFTC(m.t,LENC(m.t)-3)))

	proc ProcessOutput
		PRIVATE m.wzsFileName,m.wzsViewName,m.error
		Local SaveArea
		LOCAL m.lHasNoTask
		
		m.lHasNoTask = IIF(TYPE('THIS.lNoTask')='L',THIS.lNoTask,.F.)
		m.error=0
		SaveArea=select()
		m.wzsFileName=oEngine.wzsFileName
		m.wzsViewName=oEngine.wzsViewName
		m.wzsVersion=".001"
		m.wzsQWiz=IIF(this.nConnectHandle=0,"SQ","CS")
		m.wzlTesting=.t.
		m.wzsFileName=STRTRAN(SYS(2023)+"\PREVIEWQ.tmp","\\","\")
		IF m.qwiztype='Q' AND !this.lIsPreview
			m.wzsFileName=oEngine.wzsFileName
		ENDIF
		IF m.qWizType$"RV" AND DBC()#oWizard.cOrigDBC
			SET DATA TO (oWizard.cOrigDBC)
		ENDIF


		IF EMPTY(m.wzsFileName)
			RETURN .f.
		ENDIF

		SET MESSAGE TO PREVIEW_LOC 
		do emit
		SELECT (m.SaveArea)
		IF !this.lIsPreview
			if oEngine.Mdev
			endif

			IF m.qWizType#'Q'
				Compile (m.wzsFileName)
				DO (m.wzsFileName)	&& create the view
				if oengine.mdev
					* set step on
				endif
				IF this.nSaveOptions = 1 && save
					erase (m.wzsFilename)
					erase (LEFT(m.wzsFileName,RAT('.',m.wzsFilename))+"fxp")
				ENDIF
				IF m.error>0
					oEngine.Alert(message())
				ENDIF
			ELSE
				oEngine.cOutFile=m.wzsFileName
			ENDIF
			DO CASE
			CASE this.nSaveOptions=2	&&save & run
				IF m.qWizType#'Q'
					USE (m.wzsViewName)
					owizard.form1.visible=.f.
					oEngine.AddAliasToPreservedList(ALIAS())
					ACTI WIND SCREEN
					BROW NOWAIT normal
				ELSE
					_Shell="DO " + '"' + m.wzsFileName + '"'
				ENDIF
				oWizard.lRunOnReturn	= .t.
			CASE this.nSaveOptions=3	&&save & Modify
				DO CASE
				CASE m.qWizType$"VR"
					_SHELL="MODIFY VIEW "+'"'+m.wzsViewName+'"'
					OEngine.aEnvironment[33,1] = DBC()
				CASE m.qWizType='Q'
					_SHELL="MODIFY QUERY " + '"'+m.wzsFileName+ '"'
				ENDCASE
				oWizard.lModifyOnReturn	= .t.
			ENDCASE

			* clean-up
			IF m.qWizType # 'Q'
				erase (m.wzsFilename)
				erase (LEFT(m.wzsFileName,RAT('.',m.wzsFilename))+"fxp")
				IF m.error > 0
					oEngine.Alert(message())
				ENDIF
			ENDIF
		ENDIF

	*----------------------------------
	PROCEDURE GetODBCDrvrs
	*----------------------------------
		*- get a list of the ODBC data sources

		PARAMETER aODBCDrvrs

		LOCAL oReg, i
		LOCAL nPos,cSaveExact, retval, cValue

		IF !_mac
			*- supported only on Macintosh
			RETURN
		ENDIF

	 	DIMENSION aODBCDrvrs[1,2]

	 	LOCAL aODBCSects, cODBCFile

		*- look in ODBC preferences file
		*- There;s an ODBC Preferences, and an ODBC Preferences PPC file
		cODBCFile = IIF(THIS.GetMacCPU() == "PPC", ODBC_FILE_MACPPC, ODBC_FILE_MAC)

		DIMENSION aODBCSects[1]			&& reset for new file
		aODBCSects = ""
		retval = THIS.GetINISection(@aODBCSects,ODBC_SOURCE,cODBCFile)
		DO CASE
			CASE m.retval = ERROR_NOINIFILE
				THIS.Alert(E_ODBC1_LOC)
				LOOP
			CASE m.retval = ERROR_NOINIENTRY
				* do nothing
			CASE m.retval = ERROR_FAILINI
				* do nothing
			OTHERWISE
				FOR i = 1 TO ALEN(aODBCSects)
					cValue = ""
					cValue = THIS.GetPref(ODBC_SOURCE,aODBCSects[m.i],cODBCFile)
					IF ATC(SQLODBC_ANY,cValue) # 0
						IF !EMPTY(aODBCDrvrs[1])
							DIMENSION aODBCDrvrs[ALEN(aODBCDrvrs,1)+1,2]
						ENDIF
						aODBCDrvrs[ALEN(aODBCDrvrs,1),1] = aODBCSects[m.i]
						aODBCDrvrs[ALEN(aODBCDrvrs,1),2] = m.cValue			
					ENDIF
				ENDFOR
		ENDCASE

		RETURN .T.

	ENDPROC
	
	PROCEDURE OverWriteOK
		PARAMETERS lcMessageText
		LOCAL aButtonNames
		
		DIMENSION aButtonNames[3]
		aButtonNames[1]=BTN_CREATE_LOC
		aButtonNames[2]=BTN_OPEN_LOC
		aButtonNames[3]=BTN_CANCEL_LOC
		MyMessageBox=CREATEOBJECT('MessageBox2',lcMessageText, @aButtonNames)
		MyMessageBox.show

	ENDPROC

	PROCEDURE AScanner2
		PARAMETERS aArray,cSearch,nCol
		external array aArray
		LOCAL i
		FOR i=1 TO ALEN(aArray,1)
			IF TYPE("aArray[m.i,1]")='C' AND UPPER(aArray[m.i,1])==UPPER(cSearch)
				RETURN m.i
			ENDIF
		ENDFOR
	RETURN 0
	
ENDDEFINE



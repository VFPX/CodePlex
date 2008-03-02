#include "wzfoxdoc.h"
*# document ArrayBrackets ON


parameters cOutFileVarName, p2, p3, p4, p5, p6, p7, p8, p9
private cClassLib

m.cClassLib = set('classlib')


public oWizard

* The name "oWizard" is used in automated testing and should *NOT* be changed.

IF !EMPTY(p4)
	set proc to wzengine additive
	oEngine=CREATE("wzformateng")
	oEngine.cSourceFile=p4
	oEngine.lNoInterface=.t.
	oEngine.nXrefKeywords=IIF(ATC("XREFKEYWORD",p5)>0,1,0)
	oEngine.nExpandKeywords=IIF(ATC("EXPANDKEYWORDS",p5)>0,1,0)
	oEngine.nRep_Source_Code=ATC(REPORTSOURCE_LIST_LOC,p5)
	oEngine.nRep_Action_Diag=ATC(REPORTACTION_DIAG_LOC,p5)
	oEngine.nRep_XREF=ATC(REPORTXREF_LOC,p5)
	oEngine.nRep_File_List=ATC(REPORTFILE_LIST_LOC,p5)
	oEngine.nRep_Tree_Diag=ATC(REPORTTREE_DIAG_LOC,p5)
	IF AT("INDENT",p5) > 0
		oEngine.nIndentation = VAL(SUBSTR(m.p5,AT("INDENT",m.p5)+6))
		IF oEngine.nIndentation > 0
			oEngine.nIndentSpaces = oEngine.nIndentation
		ENDIF
	ENDIF
	IF ATC(KEYWORDCASE,p5)>0
		oEngine.nKeywordcase= VAL(SUBSTR(p5,ATC(KEYWORDCASE,p5)+LEN(KEYWORDCASE)))
	ENDIF
	IF ATC(USERCASE,p5)>0
		oEngine.nVariableCase= VAL(SUBSTR(p5,ATC(USERCASE,p5)+LEN(USERCASE)))
	ENDIF
	oEngine.ProcessOutput
	
ELSE
	set classlib to wzformat

	oWizard = createobj("wzformat", m.cOutFileVarName, m.p2, m.p3, m.p4, ;
		m.p5, m.p6, m.p7, m.p8, m.p9)
	if type('oWizard') = 'O' .and. .not. isnull(oWizard)
		oEngine.aEnvironment[17,1] = m.cClassLib
		if type("starttime")#'U'
			*Not to be localized
			wait window nowait "time = "+str(seconds()-starttime,10,4)
		endif
		if type("m.fp")#'U'	&&log
			=fclose(fp)
		endif

		oWizard.Show
	endif
	if type('oWizard') = 'O' .and. .not. isnull(oWizard)
		* It must be modeless, so leave it alone
	else
		release oWizard
	endif



ENDIF
return

do case
* look for reasons not to reset environment
case type('m.p3') = 'C' .and. ' modeless ' $ ' ' + lower(m.p3) + ' '
	* WizTemplate will have set the oEngine.cReturnToProc to the name
	* of this procedure. Since we're about to return out of here, set this
	* value to MASTER.
	if type('oWizard') = 'O' .and. type('oWizard.cReturnToProc') = 'C'
		oWizard.cReturnToProc = 'MASTER'
	endif
otherwise
	if type('oWizard') = 'O' .and. .not. isnull(oWizard)
		oWizard.Cleanup
	endif
	release oWizard
	set classlib to &cClassLib
endcase

return
*******************************************
#define MAXPATH 161

DEFINE CLASS wzFormatEng as WizEngineAll
	cOnEscape=ON("escape")
	cSetExact=SET("Exact")
	mdev=iif(file("\calvinh.txt"),.t.,.f.)
	mdev=iif(file("\calvinh.txt") AND left(getenv("computername"),6)="CALVIN",.t.,.f.)
	lNoInterface=.f.
	cSourceFile=""
	nKeywordCase=3
	nVariableCase=3
	nIndentComments=1
	nIndentControl=1
	nIndentContinuation=1	
	nIndentation=0	&&0=no change, <0 = tab,>0 =spaces
	nIndentSpaces=8
	nFileHeadings=1
	nProcHeadings=1
	nClassHeadings=1
	nMethodHeadings=1
	cActionChars=IIF(VAL(VERSION(3)) = 0," Ä³ÚÀÃ"," -|+++")
	iHelpContextID = 1895825411
	lAbort=.f.

	nLookupInOutput=2	&& for dynamic searches in input(0) or output(1)
	nSingleFile=1	&& Suck in referenced files?
	mout=""

	DIMENSION aReport[5,1]
	aReport[1,1]=REPORTSOURCE_LIST_LOC
	aReport[2,1]=REPORTACTION_DIAG_LOC
	aReport[3,1]=REPORTXREF_LOC
	aReport[4,1]=REPORTFILE_LIST_LOC
	aReport[5,1]=REPORTTREE_DIAG_LOC
	DIMENSION aReportSel[ALEN(this.aReport,1),1]
	aReportSel=""

	nRep_Source_Code=0
	nRep_Action_Diag=0
	nRep_XREF=0
	nRep_File_List=0
	nRep_Tree_Diag=0
	nTreeIndentLength=4
	nDoCaseExtraIndent=0


	nOutput=2	&&1 Overwrite, 2 All in a single dir, 3= All in a new dir tree(warn if mult vol)
	nPrint=0
	nExpandKeywords=0
	nXrefKeywords=0
	nSaveDefault=0
	cSetLibr="fd3.fll"
	mSaveDeleted=Set("deleted")
	ThermRef=""
	iPctComplete=0
	cDevInfo=""	&& from PJX
	DIMENSION aaa[3,4]
	aaa[2,2]=3
	cCollate = "machine"
	cDBC = ""
	lRunAnalyzer = .F.		&& run ANALYZER.APP on completion
	
	proc error3
		para nerror,cmethod,nline
		if nerror=214	&&window has not been defined
			return
		endif
		wizengineall::error(nerror,cmethod,nline)
	proc init2
		LOCAL mtry,mMain,i
		SET EXACT OFF
		this.cCollate= SET("collate")
		SET COLLATE TO "machine"
		mMain= "Screen"
		*Get the name of the active PJX if it's in the current dir
		mtry=WCHILD(m.mMain,0)
		DO WHILE .t.
			IF EMPTY(m.mtry)
				exit
			ENDIF
			IF LEFT(mtry,15)= "PROJECT MANAGER"
				mtry=FULLPATH(SUBSTR(mtry,19)+".pjx")
				IF FILE(mtry)
					this.cSourceFile=mtry
					EXIT
				ENDIF
			ENDIF
			mtry=WCHILD(m.mMain,1)
		ENDDO
		this.cDBC= DBC()
		close data
		set safe off
		set dele on
	endproc
	proc destroy
		local mt
		wizengineall::destroy()
		mt=this.mSaveDeleted
		set dele &mt
		IF this.cSetExact="ON"
			SET EXACT ON
		ELSE
			SET EXACT OFF
		ENDIF
		IF !EMPTY(this.cDBC)
			this.SetErrorOff=.t.
			OPEN DATA (this.cDBC)
			this.SetErrorOff = .f.
		ENDIF
		SET COLLATE TO this.cCollate
		mt=this.cOnEscape
		ON ESCAPE &mt
	proc esc_proc
		CLEAR TYPEAHEAD
		RETURN TO ProcessOutput
		IF this.Alert(C_ESCAPECONTINUE_LOC,36)="YES"
			RETURN
		ELSE
			RETURN TO ProcessOutput
		ENDIF
	proc ProcessOutput
		LOCAL oref,aAins
		DIMENSION aAins[1]
		=AINSTANCE(aAins,'wzformateng')
		oRef = aAins[1]+".esc_proc()"
		ON ESCAPE &oRef
		IF oEngine.nIndentation = 2 && spaces
			oEngine.nIndentation = oEngine.nIndentSpaces
		ELSE
			IF oEngine.nIndentation = 3
				oEngine.nIndentation = 0	&& no change
			ELSE
				oEngine.nIndentation = -1	&&tabs
			ENDIF
		ENDIF
		* Call main program
		THIS.DoFoxdoc()
	protected proc whereis
		para mfile
		LOCAL mtemp
		IF oEngine.mDev AND m.mfile="fd3.fll" AND FILE("fd3fll\fd3.fll")
			RETURN "fd3fll\fd3.fll"
		ENDIF
		IF FILE(m.mfile)
			RETURN m.mfile
		ENDIF
		RETURN oEngine.wizlocfile(m.mfile,WHEREIS_LOC + m.mfile)
	proc DoFoxdoc
		private classname,baseclass,mout
		classname=""
		baseclass=""
	
		private mFile,mtemp,OutputMode,temp
		temp=""
		mtemp = ""
		SET EXACT OFF
		
		this.cSetLibr = this.whereis("fd3.fll")
		IF EMPTY(this.cSetLibr)
			RETURN .f.
		ENDIF

		IF oEngine.lNoInterface
			IF ADIR(myjunkarray,"OUT","D")=0
				MD out
			ENDIF
			RELE myjunkarray
			oEngine.mout=sys(2003)+"\out"
		ENDIF
		mout=this.mout

		FPOutFile=0	&&set by FLL
		OutputMode=this.nOutput && 1= overwrite, 2= single new dir,3=new dir tree


		IF EMPTY(m.mout) and this.nOutput#1
			RETURN
		ENDIF
		IF RIGHT(m.mout,1)#'\'
			mout=m.mout+'\' &&assume always has a '\'
		ENDIF
*		OutputMode=0  && 0 to a single dir named outdir
*					  && 1 to multiple dirs called outdir which are subdirs of orig PJX dirs			  
*					  && 2 to replace input. Input moved to outdir
*					  && 3 to a single root dir, with same dir structure
		if m.outputmode=1
			m.mout = this.justpath(this.cSourcefile)+'\'
			IF m.mout == '\'
				m.mout=sys(2003)+'\'
			ENDIF
		endif
		IF !this.lNoInterface
			this.nRep_Source_Code=ASCAN(this.aReportSel,REPORTSOURCE_LIST_LOC)
			this.nRep_Action_Diag=ASCAN(this.aReportSel,REPORTACTION_DIAG_LOC)
			this.nRep_XREF=ASCAN(this.aReportSel,REPORTXREF_LOC)
			this.nRep_File_List=ASCAN(this.aReportSel,REPORTFILE_LIST_LOC)
			this.nRep_Tree_Diag=ASCAN(this.aReportSel,REPORTTREE_DIAG_LOC)
		ENDIF
		IF this.nRep_Source_Code>0
			this.nRep_Source_Code=fcreate(m.mout+this.JUSTSTEM(this.cSourceFile)+".LST")
		ENDIF
		IF this.nRep_Action_Diag>0
			this.nRep_Action_Diag=fcreate(m.mout+this.JUSTSTEM(this.cSourceFile)+".ACT")
		ENDIF

		CREATE TABLE (IIF(EMPTY(m.mout),"",m.mout)+"fdxref") (;
			Symbol c(65),;
			ProcName c(40),;
			Flag c(1),;
			lineno n(5),;
			SnipRecNo n(5),;
			SnipFld c(10),;
			SnipLineNo n(5),;
			adjust n(5),;
			Filename c(MAXPATH);
			)
		INDEX ON flag TAG flag && for rushmore
		index on UPPER(symbol)+flag tag symbol
		SCATTER MEMVAR BLANK
		CREATE TABLE (IIF(EMPTY(m.mout),"",m.mout+"\")+"files") (;
			FileType c(1),;
			Flags c(1),;
			File c(MAXPATH),;
			Done c(1);
			)
		SCATTER MEMVAR BLANK

		mfile = this.whereis("fdkeywrd.dbf")
		IF EMPTY(m.mfile)
			RETURN .f.
		ENDIF

		USE (m.mfile) ORDER 1 SHARED IN 0 ALIAS fdkeywrd
		SELECT fdkeywrd
		SEEK "ENDCASE"
		this.nDoCaseExtraIndent=OCCURS('U',code)
		set libr to (this.cSetLibr) addi
		this.AddLibraryToReleaseList(FULLPATH(this.cSetLibr))
		mFile=ALLTRIM(fullpath(this.cSourceFile))
		starttime= seconds ()
		totallines=0
		this.Addtherm(C_WIZNAME_LOC, 100)
		
		this.ThermRef.Visible = .t.
		this.thermref.top=this.thermref.top-100
		mfile=fullpath(m.mfile)
		mout=fullpath(m.mout)
		=fdfoxdoc(mFile,mout,"1","0")
		this.ThermRef.Complete
		this.ThermRef.visible=.f.
		this.ThermRef=.null.
		rele libr (this.cSetLibr)
		IF this.nRep_Source_Code>0
			=fclose(this.nRep_Source_Code)
		ENDIF
		IF this.nRep_Action_Diag>0
			=fclose(this.nRep_Action_Diag)
		ENDIF
		IF this.labort
			return
		ENDIF
		this.doreports
		IF this.mdev
			wait clear
			wait wind nowait "Total Lines processed="+str(totallines,8)+chr(13)+;
			  'Seconds='+str(seconds()-StartTime,8)+'  Avg='+str(Totallines/(seconds()-Starttime),8,2)+" lines/second"
		ELSE
			USE IN fdkeywrd
			USE IN files
		ENDIF
		
		IF THIS.lRunAnalyzer
			cAnalyzer = oEngine.WhereIs(C_ANALYZER_LOC)
			IF !EMPTY(cAnalyzer)
				_shell = "DO [" + cAnalyzer + "]" + IIF(EMPTY(m.mout),""," WITH [" + m.mout + "]")
			ENDIF
		ENDIF
		
		rele wind tt
	proc doreports
		IF this.nRep_File_List>0
			this.AddTherm(C_WIZNAME_LOC, 100)
			this.ThermRef.lblTitle.caption=REPORTFILE_LIST_LOC
			this.ThermRef.Visible = .t.
			*this.ThermRef.Update(this.iPctComplete,'%s')
			DO filelist
			this.ThermRef.Complete
			this.ThermRef.visible=.f.
			this.ThermRef=.null.
		ENDIF
		IF this.nRep_XREF>0
			this.AddTherm(C_WIZNAME_LOC, 100)
			this.ThermRef.lblTitle.caption=REPORTXREF_LOC
			this.ThermRef.Visible = .t.
			DO xreflist
			this.ThermRef.Complete
			this.ThermRef.visible=.f.
			this.ThermRef=.null.
		ENDIF
		IF this.nRep_Tree_Diag>0 && or oengine.mdev
			this.AddTherm(C_WIZNAME_LOC, 100)
			this.ThermRef.lblTitle.caption=REPORTTREE_DIAG_LOC
			this.ThermRef.Visible = .t.
			DO treediag
			this.ThermRef.Update(50,CLASS_HIERARCHY_LOC)
			DO ClassDiag
			this.ThermRef.Complete
			this.ThermRef.visible=.f.
			this.ThermRef=.null.
		ENDIF
ENDDEFINE

PROC sExtract (str)
	LOCAL m.mat
	m.mat = AT(CHR(0),m.str)
	RETURN LEFT(m.str,m.mat -1)

PROC IsProj
	oEngine.SetErrorOff = .t.
	oEngine.HadError = .f.
	use (m.mFile) AGAIN ALIAS foxdocpjx1 IN 0
	oEngine.SetErrorOff = .f.
	IF oEngine.HadError
		oEngine.HadError = .f.
		oEngine.Alert(ACCESS_DENIED)
		RETURN .f.
	ENDIF
	select foxdocpjx1

	LOCA FOR type='H'
	IF !EMPTY(devinfo)
		oEngine.cDevInfo= ;
			ALLTRIM("*:	"+sExtract(LEFT  (devinfo, 46   )))+CHR(13)+CHR(10)+;
			ALLTRIM("*:	"+sExtract(SUBSTR(devinfo, 47,46)))+CHR(13)+CHR(10)+;
			ALLTRIM("*:	"+sExtract(SUBSTR(devinfo, 93,46)))+CHR(13)+CHR(10)+;
			ALLTRIM("*:	"+sExtract(SUBSTR(devinfo,139,21)))+CHR(13)+CHR(10)+;
			ALLTRIM("*:	"+sExtract(SUBSTR(devinfo,160, 6)))+CHR(13)+CHR(10)+;
			ALLTRIM("*:	"+sExtract(SUBSTR(devinfo,166,11)))+CHR(13)+CHR(10)+;
			ALLTRIM("*:	"+sExtract(SUBSTR(devinfo,177,46)))+CHR(13)+CHR(10)+;
			ALLTRIM("*:	"+sExtract(SUBSTR(devinfo,223,255)))+CHR(13)+CHR(10)+;
			ALLTRIM("*:	"+sExtract(SUBSTR(devinfo,478,255)))+CHR(13)+CHR(10)+;
			ALLTRIM("*:	"+sExtract(SUBSTR(devinfo,733,255)))+CHR(13)+CHR(10)+;
			ALLTRIM("*:	"+sExtract(SUBSTR(devinfo,988,255)))+CHR(13)+CHR(10)+;
			ALLTRIM("*:	"+sExtract(SUBSTR(devinfo,1243,255)))+CHR(13)+CHR(10)+;
			ALLTRIM("*:	"+sExtract(SUBSTR(devinfo,1498,255)))
	ENDIF

	if OutputMode=3	&& to a diff tree
		set exac off
		loca for type#'H' AND (padr(name,10)='.' OR subs(padr(name,2),2)=':')
		if found()
			oEngine.Alert(BAD_PROJ_LOC)
			RETURN .f.
		endif
	ENDIF
	SELECT *,IIF(mainprog,'0','1')+PADR(name,100) AS ord;
 	 FROM foxdocpjx1 ORDER BY ord INTO CURSOR foxdocpjx 
	SCAN FOR !DELETED() and type$"SPRMVxTsKd"
		* K is a VFP SCX
		INSERT INTO files (file,filetype,flags) VALUES ;
			(UPPER(STRTRAN(IIF(!EMPTY(foxdocpjx.outfile) AND !foxdocpjx.type$'M',;
			foxdocpjx.outfile,foxdocpjx.name),CHR(0),"")),;
				IIF(foxdocpjx.type='M','m',foxdocpjx.type),;
			IIF(foxdocpjx.mainprog,"0","1"))


		*MPR is 'M', MNX is 'm'
		if foxdocpjx.type='M'
			INSERT INTO files (file,filetype,flags) VALUES ;
				(UPPER(STRTRAN(foxdocpjx.outfile,CHR(0),"")),;
				foxdocpjx.type,;
				"0");
		
		endif
	ENDSCAN
	USE
	USE IN foxdocpjx1
	SELECT files
RETURN .t.

PROC ScanRef
*Pass1: will scan symtab & suck in referenced files 
	priv mfilt
	SET ESCAPE OFF
	loca
	if !EOF()
		return
	endif
	LOCATE
	SET ESCAPE ON
RETURN



proc chkstat
	?recno("files")
RETURN

proc setlibraa
	if "2.6"$vers(9)
	else
		set libr to (IIF(file("fd3.fll"),"fd3.fll","c:\dev\fd3\fd3.fll"))
	endif
return

proc fileins
	priv mrecno
	mrecno=recno("files")
	insert into files from memvar
	go mrecno in files

proc Putout(str) 
	=fputs(fpoutfile,str)
	IF oEngine.nRep_Source_Code>0
		=fputs(oEngine.nRep_Source_Code,str)
	ENDIF
	IF oEngine.nRep_Action_Diag>0
		=fputs(oEngine.nRep_Action_Diag,str)
	ENDIF
return
	
proc HeaderProc
	*Pass2: add a header for each proc
	priv mc
	LOCAL morder
	SELECT fdxref
	morder = ORDER()
	SET ORDER TO symbol
	IF SEEK(UPPER(m.symbol),"fdxref","symbol")
		=putout("*!"+repl('*',78))
		=putout("*!")
#define PROCEDURE_LOC "Procedure"		
		=putout("*! " + PROCEDURE_LOC + " "+alltrim(m.symbol))
		m.adjust=3
		m.symbol=m.symbol+' '	&&for exact match
		*find procs called by this proc
		select dist procname from fdxref;
			where upper(symbol)+flag=m.symbol+'F';
			order by 1;
			into cursor fdxref3
		if _tally>0
			=putout("*!")
			=putout("*!   "+CALLED_BY_LOC+"   ")
			m.adjust=m.adjust+2
			scan
				=putout("*!              "+alltrim(procname))
				mc=procname
				m.adjust=m.adjust+1
			endscan
		endif

		*position to right recno in fdxref for adj
		select fdxref
		seek m.symbol
		loca while upper(symbol)=m.symbol for filename=m.filename and lineno=m.lineno 
		if !found()
			if oEngine.mdev
				*do not localize
				wait wind "can't find proc rec: "+m.symbol
			ENDIF
		endif
		
		select distinct symbol from fdxref;
			where flag='F' and procname=m.procname;
			order by 1;
			into curs fdxref3
		if _tally>0
			=putout("*!")
#define CALLS_LOC  	"*!  Calls"		
			=putout(CALLS_LOC)
			m.adjust=m.adjust+2
			scan
				=putout("*!      "+alltrim(symbol))
				m.adjust=m.adjust+1
				mc=symbol
			endscan
		endif
		use in fdxref3

		=putout("*!")
		=putout("*!"+repl('*',78))
		m.adjust=m.adjust+2
	ENDIF
	select fdxref	&& so not at eof
	repl fdxref.adjust with fdxref.adjust+m.adjust
	SET ORDER TO (m.morder)
	select fdkeywrd
retu

proc HeaderFile
	adjust=6
	=putout("*:"+repl('*',78))
	=putout("*:")
#define PROCFILE_LOC "*: Procedure File "
	=putout(PROCFILE_LOC+Alltrim(m.filename))
	=putout("*:")
	IF !EMPTY(oEngine.cDevInfo)
		=putout(oEngine.cDevInfo)
		adjust=m.adjust+occurs(CHR(13),oEngine.cDevInfo)+2
		=putout("*:")
	ENDIF	
	=putout("*: "+DOC_VER_LOC+" "+foxdocver())
	=putout("*:"+repl('*',78))
	set orde to file in fdxref
	=seek(m.filename,"fdxref")
	if Seek(m.filename,"xreffile")
		select xreffile
		GO RECNO("xreffile") IN fdxref
		scan whil filename=m.filename for flag='D'
			=putout("*:   "+trim(symbol))
			m.adjust=m.adjust+1
		endscan
	endif
	selec fdxref
	IF EOF()
	ELSE
		repl fdxref.adjust with m.adjust
	ENDIF
return

proc HeaderClass
	select fdxref
	set orde to symbol
	=seek(padr(upper(classname),len(symbol))+'C')
	IF !EOF()	&&VCX class won't have header
		=putout("*:"+repl('*',78))
		=putout("*:")
#define CLASS_LOC "Class:"
#define BASECLASS_LOC "BaseClass:"
		=putout("*: "+CLASS_LOC +Alltrim(classname)+"  "+BASECLASS_LOC + " "+BaseClass)
		=putout("*:")
		=putout("*:"+repl('*',78))
		adjust=5
		repl adjust with m.adjust
	ENDIF
	sele fdkeywrd
return

proc adjust
	priv mc
	rele wind trace
	select fdxref
	set orde to
	loca
	do while !eof()
		mc=filename
		m.adjust=0
		scan while mc=filename
			m.adjust=m.adjust+adjust
			repl lineno with lineno+m.adjust
		endscan
	enddo
	
proc debugdisp
	set esca off
	set esca on
	if recc("fdxref")=174 and mglob=.f.
		wait wind  "aa"
	endif

proc filelist
	LOCAL mfile
	SET print TO (m.mout+"files.lst")
	SET print ON
	SET CONS off
	?"*:	"+FILE_LIST_LOC
	?
	?oEngine.cDevInfo
	SELECT files
	LIST OFF field file
	SELECT FILES
	SET FILTER TO
	LOCATE FOR filetype='d'	&& DBCs
	SCAN WHILE filetype='d'
		mfile=oEngine.justpath(fullpath(oEngine.cSourceFile))+'\'+ALLTRIM(files.file)
		Do DoDBC with mfile
	ENDSCAN
	?
	?TOTAL_LINES_PROC_LOC+'='+str(totallines/2,8)
	?
	set cons on
	set print off
	set print to
RETURN


proc xreflist
	LOCAL m.num,m.cnt
	SET print TO (m.mout+"xref.lst")
	SET print ON
	set cons off
	?"*:	"+REPORTXREF_LOC
	?
	?oEngine.cDevInfo
	SELECT fdxref
	SELECT DISTINCT symbol FROM fdxref INTO CURSOR symbol ORDER BY 1
	USE DBF("fdxref") AGAIN IN 0 ORDER symbol ALIAS xref2
	SET RELATION TO UPPER(symbol) INTO xref2
	m.cnt=0
	SCAN
		m.cnt=m.cnt+1
		IF RECCOUNT()>10 AND MOD(m.cnt,int(reccount()/10))=0
			oEngine.ThermRef.Update(m.cnt*100/RECCOUNT(),"")
		ENDIF
		?symbol
		SELECT xref2
		m.num=0
		SCAN WHILE symbol=symbol->symbol
			?chr(9)+flag+chr(9)+str(lineno,5)+chr(9)+oEngine.JUSTFNAME(filename)
			m.num=m.num+1
			IF m.num>10
				m.num=0
			ENDIF
		ENDSCAN
	ENDSCAN
	?
	?TOTAL_LINES_PROC_LOC+'='+str(totallines/2,8)
	?
	USE IN xref2
	USE IN symbol
	set cons on
	set print off
	SET print TO
RETURN

#define NSPACES 2

proc dodbc
	para mfile
	PRIVATE mpath
	SET DELE ON
	mtmp1=sys(2023)+"\dbctemp"
	use (m.mfile) AGAIN IN 0 ALIAS thedbc
	SELECT thedbc
	mpath=FULLPATH(DBF())
	mpath=LEFT(m.mpath,RAT('\',m.mpath))
	COPY TO (mtmp1)
	USE (mtmp1) ALIAS dbcparent
	INDEX ON parentid TAG parentid
	m.lvl=0
	DO dodbc1 WITH objectid
	GO 3
	IF !EMPTY(code) AND objectName="StoredProceduresSource"
#DEFINE STORED_PROC_LOC "** Stored Procedures"
		?STORED_PROC_LOC
		FOR i=1 to memlines(code)
			?mline(code,m.i)
		ENDFOR
	ENDIF
	USE IN dbcparent
	erase (mtmp1+".dbf")
	erase (mtmp1+".fpt")
	erase (mtmp1+".cdx")
retur

PROC dodbc1
	para mobjectid
	LOCAL mrec
	m.lvl=m.lvl+1
	SELECT dbcparent
	SEEK m.mobjectid
	SCAN WHILE parentid=m.mobjectid
		?space(m.lvl*NSPACES)
		??padr(objecttype,8)+' '
		??padr(objectname,30)
		??space(5-m.lvl*NSPACES)
		xpath=""
		DO showprop	with .f. &&get xpath
		DO CASE
		CASE objecttype="Table"
			fcount=0
			USE (mpath+xpath) IN 0 ALIAS thetable
			=AFIELDS(mfields,"thetable")
			USE IN thetable
		CASE objecttype="View"
			fcount=-1
		CASE objecttype="Field" and fcount>=0
			fcount=fcount+1
			??PADR(mfields[fcount,1],11)
			??' '+mfields[fcount,2]
			??mfields[fcount,3]
			??mfields[fcount,4]
			IF mfields[fcount,5]
#DEFINE NULLABLE_LOC "Nullable"
				??" " + NULLABLE_LOC
			ENDIF
			IF mfields[fcount,6]
#DEFINE NOCPTRANS_LOC "NoCPTrans"
				??" "+NOCPTRANS_LOC
			ENDIF
		ENDCASE
		DO Showprop WITH .t.
		IF objectid#parentid
			mrec=RECNO()
			DO dodbc1 WITH objectid
			GO m.mrec
		ENDIF
	ENDSCAN	
	m.lvl=m.lvl-1
return

proc showprop
	PARA mshow
	mp=property	

	if len(m.mp)=0
		return
	endif
	i = 0
	DO WHILE i < LEN(m.mp)-1
		propsize=((((ASC(SUBS(m.mp,4 + m.i,1)) * 256 + ;
				ASC(SUBS(m.mp,3 + m.i,1))) * 256 + ;
				ASC(SUBS(m.mp,2 + m.i,1))) * 256 + ;
				ASC(SUBS(m.mp,1 + m.i,1)))  )
		m.keylen=ASC(SUBS(m.mp,6 + m.i,1)) * 256 + ;
 				 ASC(SUBS(m.mp,5 + m.i,1))
		if m.keylen=1
			m.key=(ASC(SUBS(m.mp,7 + m.i,1))  )
			m.keytype='S'
			IF m.key#2
				IF mshow
					? SPACE(30)+PADR(keyl(m.key),15)+' '
				ENDIF
				DO CASE
				CASE m.keytype='S'
					prop=SUBS(m.mp,8+m.i,m.propsize-8)	&& 1 for terminating null
					IF m.key=1
						xpath=prop
					ENDIF
					IF mshow
						??prop
					ENDIF
				CASE m.keytype='C'
					IF mshow
						??PADR(CHR(48+ASC(SUBS(m.mp,8+m.i,m.propsize-7))),11)
					ENDIF
				CASE m.keytype='N'
					IF mshow
						LOCAL mnum
						mnum=((((ASC(SUBS(m.mp,8 + m.i,1)) * 256 + ;
							ASC(SUBS(m.mp,9 + m.i,1))) * 256 + ;
							ASC(SUBS(m.mp,10 + m.i,1))) * 256 + ;
							ASC(SUBS(m.mp,11 + m.i,1)))  )
						IF m.mnum=4294967295
							mnum=-1
						ENDIF
						??PADR(m.mnum,11)
					ENDIF
				ENDCASE
			ENDIF
		endif
		i=i+propsize
	ENDDO
RETURN

PROC KEYL
	PARA mkey
	DO CASE
	CASE m.mkey=1
		RETURN "Path"
	CASE m.mkey=2
		m.keytype='C'
		RETURN "System Key"
	CASE m.mkey=7
		RETURN "Comment"
	CASE m.mkey=9
		RETURN "RuleExpression"
	CASE m.mkey=10
		RETURN "RuleText"
	CASE m.mkey=11
		RETURN "DefaultValue"
	CASE m.mkey=12
		RETURN "ParameterList"
	CASE m.mkey=13
		RETURN "RelatedChild"
	CASE m.mkey=14
		RETURN "InsertTrigger"
	CASE m.mkey=15
		RETURN "UpdateTrigger"
	CASE m.mkey=16
		RETURN "DeleteTrigger"
	CASE m.mkey=17
		m.keytype='C'
		RETURN "Unique"
	CASE m.mkey=18
		RETURN "RelatedTable"
	CASE m.mkey=19
		RETURN "RelatedTag"
	CASE m.mkey=20
		RETURN "PrimaryKey"
	CASE m.mkey=23
		RETURN "RelatedTable"
	CASE m.mkey=24
		m.keytype='N'
		RETURN "Version"
	CASE m.mkey=28
		m.keytype='N'
		RETURN "BatchUpdateCount"
	CASE m.mkey=29
		RETURN "Datasource"
	CASE m.mkey=32
		RETURN "ConnectName"
	CASE m.mkey=35
		RETURN "UpdateNameList"
	CASE m.mkey=36
		m.keytype='C'
		RETURN "FetchMemo"
	CASE m.mkey=37
		m.keytype='N'
		RETURN "FetchSize"
	CASE m.mkey=38
		RETURN "KeyField"
	CASE m.mkey=39
		m.keytype='N'
		RETURN "CrsMaxRows"
	CASE m.mkey=40
		m.keytype='C'
		RETURN "CrsShareConnection"
	CASE m.mkey=41
		m.keytype='C'
		RETURN "SourceType"
	CASE m.mkey=42
		RETURN "SQL"
	CASE m.mkey=43
		RETURN "Tables"
	CASE m.mkey=44
		m.keytype='C'
		RETURN "SendUpdates"
	CASE m.mkey=45
		m.keytype='C'
		RETURN "Updatable"
	CASE m.mkey=46
		m.keytype='C'
		RETURN "UpdateType"
	CASE m.mkey=47
		m.keytype='N'
		RETURN "UseMemoSize"
	CASE m.mkey=48
		m.keytype='C'
		RETURN "WhereType"
	CASE m.mkey=56
		RETURN "Caption"
	CASE m.mkey=64
		m.keytype='C'
		RETURN "Asynchronous"
	CASE m.mkey=65
		m.keytype='C'
		RETURN "BatchMode"
	CASE m.mkey=66
		RETURN "ConnectString"
	CASE m.mkey=67
		m.keytype='N'
		RETURN "ConnectTimeOut"
	CASE m.mkey=68
		m.keytype='C'
		RETURN "DispLogin"
	CASE m.mkey=69
		m.keytype='C'
		RETURN "DispWarnings"
	CASE m.mkey=70
		m.keytype='N'
		RETURN "IdleTimeOut"
	CASE m.mkey=71
		m.keytype='N'
		RETURN "QueryTimeOut"
	CASE m.mkey=72
		RETURN "Password"
	CASE m.mkey=73
		m.keytype='C'
		RETURN "Transactions"
	CASE m.mkey=74
		RETURN "UserId"
	CASE m.mkey=75
		m.keytype='N'
		RETURN "WaitTime"
	CASE m.mkey=77
		RETURN "DataType"
	ENDCASE
RETURN ""



#define MAXDEPTH 120

#if .f.
#include "wzfoxdoc.h"
proc testtreediag
clear
close data
set proc to wzengine
set proc to wzformt addi
set clas to therm
oengine=createobj("wzformateng")
use out\files in 1
use out\fdxref in 2
mout="out\"
do treediag
do classdiag
modi comm out\tree.lst nowait
#Endif


PROC ClassDiag
	LOCAL mr,cCollate
	PRIVATE lvl
	PRIVATE mindent
	PRIVATE cActionChars
	cCollate=SET("collate")
	SET COLLATE TO "machine"
	cActionChars=oEngine.cActionChars
	mindent=oEngine.nTreeIndentLength-1
	DIME alev[MAXDEPTH]	&&graphic lines
	SET print TO (m.mout+"tree.lst") ADDITIVE
	set print on
	SET CONSOLE OFF
	?
	?REPL("*",30)
	?CLASS_HIERARCHY_LOC

	SELECT symbol,procname,flag,filename,' ' AS done;
		FROM  fdxref ;
		WHERE flag$"CB" AND;
			UPPER(symbol) # UPPER(procname);
		INTO CURSOR classd1
	USE DBF("classd1") AGAIN IN 0 ALIAS classd
	SELECT classd
	USE IN classd1
	INDEX ON done+flag+UPPER(procname) TAG dprocname
	INDEX ON UPPER(procname) TAG procname
	INDEX ON UPPER(symbol)  TAG symbol

	DO WHILE SEEK(' ',"classd","dprocname")
		mr=RECNO()
		DO WHILE SEEK(UPPER(procname)),"classd","symbol")
			mr=RECNO()
		ENDDO
		GO mr
		m.lvl=1
		?procname
		?
		DO showclas WITH UPPER(ALLTRIM(procname))
		SET ORDER TO symbol
	ENDDO
	set print off
	set print to
	USE IN classd
	SET COLLATE TO (m.cCollate)
RETURN
	
PROC showclas
	PARA m.procname
	LOCAL mr
	m.lvl=m.lvl+1
	IF SEEK(' C'+m.procname+' ',"classd","dprocname")
		SET ORDER TO procname
		SCAN WHILE UPPER(ALLTRIM(procname))+' ' = m.procname+' '
			REPLACE done WITH 'Y'
			IF m.lvl>1
				FOR i=2 TO m.lvl-1
					??IIF(aLev[m.i],' ',SUBSTR(m.cActionChars,3,1))+SPACE(mindent)
				ENDFOR
				mr=recno()
				mparent=UPPER(procname)
				SKIP

				IF m.mparent==UPPER(procname)
					??SUBSTR(m.cActionChars,6,1)
					alev[m.lvl]=.f.
				ELSE
					??SUBSTR(m.cActionChars,5,1)
					alev[m.lvl]=.t.
				ENDIF
				GO m.mr
				??REPLICATE(SUBSTR(m.cActionChars,2,1),m.mindent)
			ENDIF

			IF m.lvl>1
				??padr(symbol,26)
				IF m.lvl<6
					??REPLICATE(' ',(mindent+1) * (6-m.lvl))
				ENDIF
				??oEngine.justfname(alltrim(filename))
			ELSE
				??alltrim(symbol)
			ENDIF
			?
			mr=recno()
			DO showclas WITH UPPER(ALLTRIM(symbol))
			GO m.mr
			SET ORDER TO procname
		ENDSCAN
	ENDIF
	m.lvl=m.lvl-1
RETURN


proc treediag
	PRIVATE lvl,cnt,err
	PRIVATE aLev
	PRIVATE mindent,mparent
	PRIVATE cActionChars
	PRIVATE track
	PRIVATE mtop
	local msetexact,mr
	msetexact=set("exact")
	set exact on
	CREATE CURSOR did (proc c(len(fdxref.symbol)))
	INDEX ON upper(proc) TAG proc
	select files
	LOCA
	IF EOF()
		RETURN .f.
	ENDIF
	cActionChars=oEngine.cActionChars
	mindent=oEngine.nTreeIndentLength-1
	DIME alev[MAXDEPTH]	&&graphic lines
	m.cnt=0
	SET print TO (m.mout+"tree.lst")
	SET print ON
	set cons off
	?"*:	"+REPORTTREE_DIAG_LOC
	?
	?oEngine.cDevInfo	&&bugbug
	?
	go 1
	mtop=PADR(oEngine.JustStem(file),LEN(fdxref.procname))
	select fdxref
	lvl=1
	m.cnt=1
	m.err=.t.
	DO WHILE !EMPTY(TAG(m.cnt))
		IF tag(m.cnt)="PROCEDURE"
			m.err=.f.
			EXIT
		ENDIF
		m.cnt=m.cnt+1
	ENDDO
	IF m.err
		index on upper(procname) for flag$'DF' tag procedure
	ELSE
		SET ORDER TO procedure
	ENDIF
	m.cnt=0
	DIMENSION track[MAXDEPTH]
	track=""
	?ALLTRIM(m.mtop)
	?
	DO showit WITH mtop
*now find all missing subtrees
	SELECT fdxref
	SCAN for flag='D'
		MR=recno()
		*find top of subtree
		m.mtop=fdxref.symbol
		DO WHILE SEEK(UPPER(m.mtop)+'F',"fdxref","symbol") AND !"."$fdxref.procname AND ;
				UPPER(ALLTRIM(fdxref.symbol)) # UPPER(ALLTRIM(fdxref.procname))
			m.mtop=PADR(fdxref.procname,LEN(fdxref.symbol))
		ENDDO
		m.mtop=PADR(m.mtop,len(fdxref.procname))
		IF !SEEK(UPPER(m.mtop),"did")
			m.lvl=1
			m.cnt=1
			?ALLTRIM(m.mtop)
			?
			DO showit WITH PADR(fdxref.symbol,LEN(fdxref.procname))
		ENDIF
		GO m.MR
	ENDSCAN
	IF !oengine.mdev
		USE IN did
	ENDIF
	set cons on
	set print off
	set print to
	SET ORDER TO
	set exact &msetexact
RETURN



PROC showit
	Para prg
	priv mr,i
	INSERT INTO did VALUES (UPPER(m. prg))
	seek UPPER(m.prg)
	IF !FOUND() OR m.lvl>=MAXDEPTH
		RETURN
	ENDIF
	lvl=m.lvl+1
	scan while upper(procname) = UPPER(m.prg)
		if flag #'D'

			IF m.lvl>1
				FOR i=2 TO m.lvl-1
					??IIF(aLev[m.i],' ',SUBSTR(m.cActionChars,3,1))+SPACE(mindent)
				ENDFOR
				mr=recno()
				mparent=UPPER(procname)
				SKIP

				IF mparent==UPPER(procname)
					??SUBSTR(m.cActionChars,6,1)
					alev[m.lvl]=.f.
				ELSE
					??SUBSTR(m.cActionChars,5,1)
					alev[m.lvl]=.t.
				ENDIF
				GO m.mr
				??REPLICATE(SUBSTR(m.cActionChars,2,1),mindent)
			ENDIF
			m.cnt=m.cnt+1
			??ALLTRIM(symbol)
			I = ASCAN(track,UPPER(TRIM(symbol)))
			IF m.i>0
#define RECURSION_LOC "Recursion"
				??"   " + RECURSION_LOC
				?
			ELSE
				?
				mr=recno()
				track[m.lvl]=UPPER(trim(symbol))
				do showit with PADR(symbol,LEN(fdxref.procname))
				track[m.lvl]=""
				go mr
			ENDIF
		endif
	ENDsc
	lvl=m.lvl-1
RETURN

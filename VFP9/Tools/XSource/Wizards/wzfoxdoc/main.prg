* THIS FILE SHOULD NOT BE LOCALIZED!!!
#include wzfoxdoc.h
para mmode
clear
set path to ..\wzcommon
if !file("..\wzcommon\wzengine.fxp")
	comp wzengine
endif

if file("tr.prg")
	do tr
	retu
endif
IF FILE("try.prg")
	opts=""
	* -1 = Tab, 0 = nochange, >0 = # spaces
	opts=opts+"INDENT0"
	*1 All caps, 2 All small 3 mixed as in fdkeywrd 4 nochange
	opts=opts+"KEYWORDCASE2"
	*1 All caps, 2 All small 3 mixed as in fdxref   4 nochange
	opts=opts+"USERCASE1"
	do wzformt with "","","SNOQUALMIE::FLEW","try.prg",opts
	IF !EMPTY(DBF())
		LOCA
	ENDIF
	modi comm out\try nowait
ELSE
	do wzformt with "","","SNOQUALMIE::FLEW","",""
ENDIF


return

public m.symbol
if type("mmode")#'L'
	if !used("fdxref")
		use fdxref
	else
		select fdxref
	endif
	brow last nowai
	scan rest
		do tex in main with "G"
		wait wind  allt(symbol)+' '+str(lineno,5)
	endscan
	
	retu
endif
?"a"
clear
set head off
set talk off
set safe off
close data
clear
public m.symbol,m.lineno,m.filename,m.mode,m.file,m.totallines
public classname,baseclass
public mydebug
public mglob
mydebug=0

rele wind outfile.prg
rele wind view
rele wind t.prg
if set("dire")="C:\DEV"
	DIMENSION mf[19]
	mf[1]="t.prg"
	mf[2]="genscrn.prg"
	mf[3]="t.scx"
	mf[4]="d:\dw\com\slist.prg"
	mf[5]="f:\qw\wz_bquer.prg"
	mf[6]="f:\qw\wz_bquer.pjx"
	mf[7]="d:\dw\qw\action.prg"
	mf[8]="j:\tro\tro.pjx"
	mf[9]="d:\dw\cmls\main.pjx"
	mf[10]="d:\dw\ff\programs\ffisdupe.prg"
	mf[11]="d:\dw\cmls\licn.prg"
	mf[12]="j:\fox30\samples\orders\orders.prg"
	mf[13]="d:\d\acct\main.prg"
	mf[14]="d:\dw\ff\foxfire.pjx"
	mf[15]="d:\d\atlas\main.pjx"
	mf[16]="tiny.prg"
	mf[17]=_genscrn
	mf[18]=_Transport
	mf[19]="j:\fox30\convert\tazform.prg"
	define popup pp from 10,10
	FOR i=1 TO ALEN(mf)
		define bar i of  pp prompt mf[i]
	ENDFOR
	on selection popup pp deact popup pp
	acti popup pp
	mfile=prompt()
	mout="c:\dev\out"
	if mfile="t.prg"
		_Cliptext="modi comm "+mout+"\t.prg"
	endif

ELSE
	mfile=getfile("prg;pjx","Pjx or Prg")
	mout="out"
	mout=getdir("","Output DIR:")
ENDIF

if empty(mfile)
	return
endif


erase outfile.prg
#define MAXPATH 50
SET LIBR TO
FPOutFile=0	&&set by FLL
UserCaseMode   =2  && 0 upper, 1 lower, 2 unchanged, 3 as first occur
KeyWordCaseMode=2  && 0 upper, 1 lower, 2 unchanged, 3 as in fdkeywrd 
OutputMode=0  && 0 to a single dir named outdir
			  && 1 to multiple dirs called outdir which are subdirs of orig PJX dirs			  
			  && 2 to replace input. Input moved to outdir
			  && 3 to a single root dir, with same dir structure
LookupInOutput=1	&& for dynamic searches in input(0) or output(1)
SingleFile=0	&& Suck in referenced files?
CREATE TABLE fdxref (;
	Symbol c(65),;
	ProcName c(40),;
	Flag c(1),;
	lineno n(5),;
	adjust n(5),;
	Filename c(MAXPATH);
	)
INDEX ON flag TAG flag && for rushmore
index on UPPER(symbol)+flag tag symbol
SCATTER MEMVAR BLANK
CREATE TABLE files (;
	FileType c(1),;
	Flags c(1),;
	File c(MAXPATH),;
	Done c(1);
	)
SCATTER MEMVAR BLANK
USE fdkeywrd order 1 SHARED in 0

do setlibr
?"foxdocver=",foxdocver()
?sys(1016)
?
set udfparms to value
starttime= seconds ()
#if .f.
	=beautify("d:\dw\qw\action.prg","out\outfile.prg","")
	modi comm out\outfile nowait
	return
#endif

*3rd parm is 0 for 1 pass, 1 for 2 passes
mdele=set("dele")
set dele on
=fdfoxdoc(mfile,mout,"1","")
set dele &mdele
set libr to
SELECT files
SET FILTER TO
LOCATE
BROW LAST NOWAIT
SELECT fdxref
set order to
loca
BROW LAST NOWAIT

SET TALK ON
set
do setview
set esca off
wait wind  'Total lines processed='+str(totallines,8)+chr(13)+;
  'Seconds='+str(seconds()-StartTime,8)+'  Avg='+str(Totallines/(seconds()-Starttime),8,2)
set esca on
return

PROC IsProj
	SELECT *,IIF(mainprog,'0','1')+PADR(filename,100) AS ord;
 	 FROM foxdocpjx1 ORDER BY ord INTO CURSOR foxdocpjx 
	SCAN FOR !DELETED() AND type$"SPRMxs"
		INSERT INTO files (file,filetype,flags) VALUES ;
			(UPPER(STRTRAN(foxdocpjx.name,CHR(0),"")),;
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
RETURN

PROC ScanRef
*Pass1: will scan symtab & suck in referenced files 
	priv mfilt
	SET ESCAPE OFF
	loca
	if !EOF()
		return
	endif
	*First, find all function calls: type 'F'
	SELECT DISTINCT symbol ;
		FROM fdxref ;
		WHERE flag='F';
		INTO CURSOR t1
	*of those, find the ones that don't have a Def
	SELECT t1.symbol ;
		FROM t1 ;
		WHERE t1.symbol NOT IN ;
		(SELECT symbol FROM fdxref WHERE flag='D');
		INTO CURSOR t2
	SELECT files
	mfilt=set("filt")
	SET FILTER TO
	SELECT t2
	*add the results into the files table if not there already
	SCAN
		m.file=ALLTRIM(t2.symbol)+".PRG"
		IF EMPTY(LOOKUP(files.file,m.file,files.file))
			INSERT INTO files (filetype,flags,file,done) VALUES ;
				('P',"",m.file,"")
			?"Adding ",LEFT(files.file,15)
		ENDIF
	ENDSCAN
	USE IN t1
	USE IN t2
	SELECT files
	SET ORDER TO
	SET FILTER TO &mfilt
	LOCATE
	SET ESCAPE ON
RETURN


PROC Setview
	on key label ctrl+d do tex in main with "D"
	on key label ctrl+r do tex in main with "R"
	on key label ctrl+n do tex in main with "N"
	on key label ctrl+b do tex in main with "B"
	on key label ctrl+g do tex in main with "G"
	on key label f7 do tex in main with "T"

	m.symbol=""
	RETURN

PROC tex
	para mm && Definition Reference Next Back Goto
	publ mwinname,mwinpos,seekmode,m.symbol
	SELECT fdxref
	set order to symbol
	seekmode=m.mm
	do setlibr
	if m.seekmode='G'
		IF EMPTY(filename)
			RETURN
		ENDIF
		IF RIGHT(UPPER(ALLTRIM(filename)),4)$".VCX.SCX"
			IF USED("snipfile")
				USE IN snipfile
			ENDIF
			USE (fdxref.filename) AGAIN IN 0 ALIAS snipfile
			GO (fdxref.sniprecno) IN snipfile
			IF !EMPTY(fdxref.snipfld)
				MODI MEMO (fdxref.snipfld) nowait noedit
				=Gotorec()
			ENDIF
		ELSE
			modi comm (filename) nowait noedit
			=Gotorec()
		ENDIF
		SET LIBR TO
		return
	endif
	IF type("fdstack[1]")='U'
		PUBLIC fdstack[1,1],FDSP
		fdsp=0
	ENDIF
	IF m.seekmode='B'
		IF m.fdsp>0
			mwinname=fdstack[fdsp,1]
			mwinpos=fdstack[fdsp,2]
			=CurPos("S")
			fdsp=m.fdsp-1
			IF m.fdsp>0
				DIMENSION fdstack[fdsp,2]
			ENDIF
			WAIT WINDOW NOWAIT " SP="+str(fdsp,2)
		ELSE
			WAIT WINDOW NOWAIT "Top"
		ENDIF
		set libr to
		RETURN
	ENDIF
	IF m.seekmode$"DR"
		IF TYPE("_screen.activeform.caption")#'C'
			=CurPos("G")
		ELSE
			=MessageBox("Activate an edit window first",16)
			RETURN
		ENDIF
	ENDIF
	if m.seekmode$"DR"
		=examine(seekmode)	&&see what's under cursor
	endif
	do exam	&&get cursor word into m.symbol
	set libr to
RETURN

PROC exam
	*called by examine()... m.symbol ="" if not found
	PRIVATE str
	SELECT fdxref
	if m.seekmode='T'
		set orde to
		skip
		IF eof()
			GO BOTT
		ENDIF
	else
		if empty(set("order"))
			SET ORDER TO symbol
		ENDIF
		str=PADR(UPPER(m.symbol),LEN(symbol))
		IF m.seekmode$"DR"
			SEEK str+m.seekmode
			IF m.seekmode='D' AND !FOUND()
				SEEK str+'V'
			ENDIF
			IF m.seekmode='R' AND !FOUND()
				SEEK str
			ENDIF
		ELSE
			IF !EOF()
				SKIP
			ENDIF
		ENDIF
	ENDIF
	IF m.seekmode#'T' and (EMPTY(m.symbol) OR UPPER(symbol)#UPPER(m.symbol) OR EOF())
		WAIT WINDOW NOWAIT m.seekmode+' '+m.symbol+" not found"
		m.symbol=""
	ELSE
		IF RIGHT(UPPER(ALLTRIM(filename)),4)$".VCX.SCX"
			IF USED("snipfile")
				USE IN snipfile
			ENDIF
			USE (fdxref.filename) AGAIN IN 0 ALIAS snipfile
			GO (fdxref.sniprecno) IN snipfile
			IF !EMPTY(fdxref.snipfld)
				MODI MEMO (fdxref.snipfld) nowait noedit
			ENDIF
		ELSE
			modi comm (filename) nowait noedit
		ENDIF

		IF RIGHT(TRIM(filename),3)$"PRG MPR SPR"
			SCATTER MEMVAR
			m.lineno=INT(m.lineno)
			if m.seekmode$"DR"
				fdsp=m.fdsp+1
				DIMENSION fdstack[fdsp,2]
				fdstack[fdsp,1]=mwinname
				fdstack[fdsp,2]=mwinpos
			ENDIF
		ELSE
			m.symbol=""
		ENDIF
		=Gotorec()
		WAIT WINDOW NOWAIT ALLTRIM(m.symbol)+" "+flag+" found in "+ALLTRIM(fdxref.Filename)+' '+STR(lineno,5)+" SP="+str(fdsp,2)
	ENDIF
RETURN

proc chkstat
	?recno("files")
RETURN

proc setlibr
	set libr to (IIF(file("fd3fll\fd3.fll"),;
			"fd3fll\fd3.fll",;
			sys(2004)+"wizards\fd3.fll"))
return

proc fileins
	priv mrecno
	mrecno=recno("files")
	insert into files from memvar
	go mrecno in files
	
proc HeaderProc
	*Pass2: add a header for each proc
	priv mc
	=fputs(fpoutfile,"*!"+repl('*',78))
	=fputs(fpoutfile,"*!")
	=fputs(fpoutfile,"*! Procedure "+alltrim(m.symbol))
	m.adjust=3
	m.symbol=m.symbol+' '	&&for exact match
	*find procs called by this proc
	select dist procname from fdxref;
		where upper(symbol)+flag=m.symbol+'F';
		order by 1;
		into cursor fdxref3
	if _tally>0
		=fputs(fpoutfile,"*!")
		=fputs(fpoutfile,"*!   Called by   ")
		m.adjust=m.adjust+2
		scan
			=fputs(fpoutfile,"*!              "+alltrim(procname))
			mc=procname
			m.adjust=m.adjust+1
		endscan
	endif

	*position to right recno in fdxref for adj
	select fdxref
	seek m.symbol
	loca while upper(symbol)=m.symbol for filename=m.filename and lineno=m.lineno 
	if !found()
		wait wind "can't find proc rec"
	endif
	
	select distinct symbol from fdxref;
		where flag='F' and procname=m.procname;
		order by 1;
		into curs fdxref3
	if _tally>0
		=fputs(fpoutfile,"*!")
		=fputs(fpoutfile,"*!  Calls")
		m.adjust=m.adjust+2
		scan
			=fputs(fpoutfile,"*!      "+alltrim(symbol))
			m.adjust=m.adjust+1
			mc=symbol
		endscan
	endif
	use in fdxref3

	=fputs(fpoutfile,"*!")
	=fputs(fpoutfile,"*!"+repl('*',78))
	m.adjust=m.adjust+2
	sele fdxref	&& so not at eof
	repl fdxref.adjust with fdxref.adjust+m.adjust
	select fdkeywrd
retu

proc HeaderFile
	=fputs(fpoutfile,"*:"+repl('*',78))
	=fputs(fpoutfile,"*:")
	=fputs(fpoutfile,"*: Procedure File "+Alltrim(m.filename))
	=fputs(fpoutfile,"*:")
	=fputs(fpoutfile,"*: Documented           FoxDoc version 1")	
	=fputs(fpoutfile,"*:"+repl('*',78))
	adjust=6
	if Seek(m.filename,"xreffile")
		select xreffile
		GO RECNO("xreffile") IN fdxref
		scan whil filename=m.filename for flag='D'
			=fputs(fpoutfile,"*:   "+trim(symbol))
			m.adjust=m.adjust+1
		endscan
	endif
	selec fdxref
	repl fdxref.adjust with m.adjust
return

proc HeaderClass
	=fputs(fpoutfile,"*:"+repl('*',78))
	=fputs(fpoutfile,"*:")
	=fputs(fpoutfile,"*: Class: "+Alltrim(classname)+"  BaseClass: "+BaseClass)
	=fputs(fpoutfile,"*:")
	=fputs(fpoutfile,"*:"+repl('*',78))
	adjust=5
	select fdxref
	=seek(padr(upper(classname),len(symbol))+'C')
	repl adjust with m.adjust
	sele fdkeywrd
return

proc adjust
	priv mc
	set step on
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
	
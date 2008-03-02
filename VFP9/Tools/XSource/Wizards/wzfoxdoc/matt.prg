PARAMETER nmode,ol
PRIVATE lvl,cnt,err,i
ol.style=5
ol.clear
use (mdir+"files") in 0
select files
go 1
mtop=JustStem(file)
use
select fdxref
lvl=0
m.cnt=0
m.err=.f.
on error m.err=.t.
DO CASE
CASE nMode=1	&&calling tree
	SET ORDER TO procedure
	IF m.err
		index on upper(procname) for flag$'DF' tag procedure
	ENDIF
	ON ERROR
	DO showit WITH upper(mtop)
CASE nMode=3	&&Class Hierarchy
	SET ORDER TO classes
	IF m.err
		index on upper(procname) for flag$"BC" tag classes
	ENDIF
	ON ERROR
	SCAN FOR flag='C'
		myrec=recno()
		MTOP=UPPER(ALLTRIM(Procname))
		DO showit WITH mtop
		go myrec
	ENDSCAN
ENDCASE
FOR i=0 TO ol.listcount-1
	IF ol.hassubitems[i]
		ol.picturetype[i]=0
	ELSE
		ol.picturetype[i]=2
	ENDIF
ENDFOR


PROC showit
	Para prg
	priv mr
	IF m.lvl>20
		RETURN
	ENDIF
	lvl=m.lvl+1
	seek prg+' '
	scan while upper(procname)+' '=prg+' '
		if Upper(ALLTRIM(procname))#Upper(ALLTRIM(symbol))
			m.cnt=m.cnt+1
			ol.additem(ALLTRIM(symbol))
			ol.indent[m.cnt]=m.lvl
			mr=recno()
			do showit with UPPER(trim(symbol))
			go mr
		endif
	ENDsc
	lvl=m.lvl-1
RETURN

PROCEDURE JustStem
	PARAMETERS mfile
	IF AT('\',m.mfile)>0
		mfile=SUBSTR(m.mfile,RAT('\',m.mfile)+1)
	ENDIF && AT('/',m.mfile)>0
	IF AT(".",m.mfile)>0
		mfile=LEFT(m.mfile,AT(".",m.mfile)-1)
	ENDIF && AT(".",m.mfile)>0
RETURN m.mfile
*EOP JustStem


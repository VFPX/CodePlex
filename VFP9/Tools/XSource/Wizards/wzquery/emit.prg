#include "wzquery.h"
PROCEDURE emit
local noldmaxrecords

external array wzabqtxt
external array tafields

	PRIVATE m.i,m.j,m.wzsTemp,m.wzsTag,m.wzsFldLst,m.wzsDBFs,m.wzsFilt
	EXTERNAL ARRAY wzaQSort,wzaQFlds
	PRIVATE wzdatestamp,wztimestamp,wz_timestamp,m.error
	m.error=0

	CleanNames(@wzaQSort)
	CleanNames(@wzaQFlds)
	* CleanNames(@wzaQGrp)
	
	IF wzlTesting
		* wzaQDD[2,5]='1'
	ENDIF
	CLEAR PROGRAM	&&clear out program cache
	SET TEXTMERGE TO (m.wzsFileName)
	SET TEXTMERGE on NOSHOW

	m.wzsDBFs=""
	m.wzsFldLst=""
	FOR m.i=1 TO ALEN(wzaQFlds,1)
		m.wzsFldLst=m.wzsFldLst+wzaQFlds[m.i]+','
	ENDFOR
	m.wzsFldLst=LEFT(m.wzsFldLst,LEN(m.wzsFldLst)-1)

	m.wzsFilt=CleanFilter(oEngine.cWizFiltExpr)

	DO EmitSql with "*"
	SET TEXTMERGE TO
	IF oEngine.mDev
		MODI COMM (m.wzsFileName)
	ENDIF
	IF m.qWizType #'R'
		FOR m.i = 1 TO ALEN(wzaQDD,1)
			IF CursorGetProp("sourcetype",wzaQDD[m.i,1]) # 3
				oEngine.SetErrorOff = .t.
				=ReQuery(wzaQDD[m.i,1])
				oEngine.SetErrorOff = .f.
			ENDIF
		ENDFOR
	ENDIF

	IF oEngine.lIsPreview
		owizard.form1.visible=.f.
		IF m.qWizType='R'
			LOCAL fp,m.mstr
			fp=FOPEN(m.wzsFileName,0)
			mstr=FREAD(m.fp,5000)
			=fclose(m.fp)
			SELECT wzacsDD_
			m.mstr=STRTRAN(m.mstr,';'+CHR(13)+CHR(10),'')
			noldmaxrecords=CursorgetProp("maxrecords",0)
			=CursorSetProp("maxrecords",100,0)
			=SQLEXEC(oEngine.nConnectHandle,m.mstr,PREVIEW_LOC)
			=CursorSetProp("maxrecords",m.noldmaxrecords,0)
		ELSE
			msaveerr=ON("ERROR")
			ON ERROR m.error=error()
			DO (m.wzsFileName)
			IF m.error>0
				oEngine.Alert(message())
			ENDIF
			ON ERROR &msaveerr
		ENDIF
		erase (m.wzsFilename)
		erase (LEFT(m.wzsFileName,RAT('.',m.wzsFilename))+"fxp")
		IF m.qWizType='R' and ALIAS()="WZACSDD_"
			oEngine.Alert(C_NO_RECORDS_FOUND_LOC,64)
			m.error=1
		ELSE
			IF m.error=0
				acti screen
				SET SKIP OF MENU _MSYSMENU .T.
				brow last nomenu
				USE
				SET SKIP OF MENU _MSYSMENU .F.
			ENDIF
		ENDIF
		owizard.form1.visible=.t.
		
#if .f.
		LOCAL ox
		ox=CREATE("formprev")
		ox.windowtype=1	&&modal
		ox.autocenter=.t.
		ox.grid1.recordsource=alias()
		ox.show
		release ox
#endif
		oWizard.form1.refresh	&&force a repaint
	ENDIF
RETURN

PROCEDURE CleanFilter(tcWizFiltExpr)
	LOCAL lcFilt,lnPos,lcStr,lnPos2,lcStr2
	IF EMPTY(ALLTRIM(tcWizFiltExpr))
		RETURN ""
	ENDIF
	lnPos = ATCC(".",tcWizFiltExpr)
	IF lnPos#0
		lcStr = LEFTC(tcWizFiltExpr,lnPos-1)
	ENDIF
	lcFilt=tcWizFiltExpr
	IF ATCC(" ",lcStr)#0
		lcStr = CHRTRAN(EVAL(lcStr)," ","_")
		lcFilt = lcStr+SUBSTR(tcWizFiltExpr,lnPos)	
	ENDIF
	
	lnPos2 = ATCC(" AND ",lcFilt)
	IF lnPos2 = 0
		lnPos2 = ATCC(" OR ",lcFilt)
		IF lnPos2 = 0
			RETURN lcFilt
		ELSE
			lcStr = ALLTRIM(SUBSTR(lcFilt,lnPos2+4))
		ENDIF
	ELSE
		lcStr = ALLTRIM(SUBSTR(lcFilt,lnPos2+5))
	ENDIF
	lnPos = ATCC(".",lcStr)
	lcStr2 = LEFTC(lcStr,lnPos-1)
	IF ATCC(" ",lcStr2)#0
		lcStr2 = CHRTRANC(EVAL(lcStr2)," ","_") 
	ENDIF
	lcStr2 = lcStr2 + SUBSTR(lcStr,lnPos)
	lcFilt = LEFTC(lcFilt,lnPos2+3) +" "+ lcStr2
	RETURN lcFilt
ENDPROC

PROCEDURE CleanNames()
	LPARAMETER taFields
	LOCAL i,lcStr,lnPos
	FOR i = 1 TO ALEN(taFields,1)
		lnPos = ATCC(".",taFields[m.i])
		IF lnPos=0
			LOOP
		ENDIF
		lcStr = LEFTC(taFields[m.i],lnPos-1)
		IF ATCC(" ",lcStr)=0
			LOOP
		ENDIF
		lcStr = CHRTRANC(EVAL(lcStr)," ","_")
		taFields[m.i] = lcStr+SUBSTR(taFields[m.i],lnPos)
	ENDFOR
ENDPROC

PROCEDURE EmitSql
	PARAMETERS prefix	&&'*' for parm block, '!' for CKSQL, '' for normal FPSQL
	PRIVATE m.i,m.wzsSort,m.wzsJoin,m.wzsGrp,m.prefix,m.wzsTemp
	*- added var for cursor name, take from filename
	PRIVATE m.wzlOuter, m.wzscursnam
	LOCAL mtemp,mdbf, aTables[1]
	m.wzscursnam = "Query"
	m.wzsJoin=""
	IF !EMPTY(wzaQGrp[1,1])
		m.wzsGrp=""
		FOR m.i=1 TO ALEN(wzaQGrp,1)
			IF !EMPTY(wzaQGrp[m.i,1])
				IF VAL(wzaQGrp[m.i,2])>1
					DO CASE
					CASE SUBSTR(wzaQGrp[m.i,2],2)='D'
						DO CASE
						CASE VAL(wzaQGrp[m.i,2])=2	&&Year
							m.wzsTemp="YEAR("+wzaQGrp[m.i,1]+")"
						CASE VAL(wzaQGrp[m.i,2])=3	&&Month
							m.wzsTemp="MONTH("+wzaQGrp[m.i,1]+")"
						CASE VAL(wzaQGrp[m.i,2])=4	&&Dow
							m.wzsTemp="DOW("+wzaQGrp[m.i,1]+")"
						CASE VAL(wzaQGrp[m.i,2])=5	&&Yr/mn
							m.wzsTemp="STR(YEAR("+wzaQGrp[m.i,1]+"),4)+'/'+"+;
								"STR(MONTH("+wzaQGrp[m.i,1]+"),2)"
						CASE VAL(wzaQGrp[m.i,2])=6	&&Quarter
							m.wzsTemp="'Q'+STR(INT((MONTH("+wzaQGrp[m.i,1]+")-1)/3)+1,1)"
						CASE VAL(wzaQGrp[m.i,2])=7	&&Year/Quarter
							m.wzsTemp="STR(YEAR("+wzaQGrp[m.i,1]+"),4)"+;
								"+'-Q'+STR(INT((MONTH("+wzaQGrp[m.i,1]+")-1)/3)+1,1)"
						ENDCASE
					CASE SUBSTR(wzaQGrp[m.i,2],2)='N'
						m.wzsTemp=VAL(wzaQGrp[m.i,2])-1
						m.wzsTemp=ALLTRIM(STR(10^m.wzsTemp))
						m.wzsTemp="INT("+wzaQGrp[m.i,1]+"/"+m.wzsTemp+;
							") * "+m.wzsTemp
					OTHERWISE	&&must be Char
						m.wzsTemp="LEFT("+wzaQGrp[m.i,1]+","+;
							STR(VAL(wzaQGrp[m.i,2])-1,1)+')'
					ENDCASE
					*- put CR & LF together
					m.wzsFldLst=m.wzsFldLst+",;"+;
						CHR(13)+CHR(10)+m.prefix+CHR(9)+CHR(9)+;
						m.wzsTemp+" AS GRP"+CHR(m.i+ASC('0'))
					m.wzsGrp=m.wzsGrp+",GRP"+CHR(m.i+ASC('0'))
				ELSE
					m.wzsGrp=m.wzsGrp+","+wzaQGrp[m.i,1]
				ENDIF && wzaQGrp[m.i,2]>1
			ENDIF && !EMPTY(wzaQGrp[m.i,1])
		ENDFOR &&* m.i=1 TO ALEN(wzaQGrp,1)
		m.wzsGrp=SUBSTR(m.wzsGrp,2)
	ENDIF && !EMPTY(wzaQGrp[1,1])	
	
	* create FROM clause, no joins
	DIMENSION aTables[ALEN(wzaQDD,1)]
	m.wzsDBFs = ""
	FOR m.i=1 TO ALEN(wzaQDD,1)
		aTables[m.i] = ""
		DO CASE
		CASE m.prefix='!'
			m.wzsDBFs=m.wzsDBFs+wzaQDD[m.i,6]	&&Just CS name
		CASE m.prefix='*'
			IF m.qwiztype='R'
				m.wzsDBFs=m.wzsDBFs+wzaQDD[m.i,1]
				IF ATCC(" ",wzaQDD[m.i,1])#0
					m.wzsDBFs=m.wzsDBFs+" "+CHRTRANC(EVAL(wzaQDD[m.i,1])," ","_")
				ENDIF
			ELSE
				mtemp=CURSORGETPROP("database",wzaQDD[m.i,1])
				m.mdbf=""
				IF !EMPTY(m.mtemp)  &&free table
					m.mdbf=m.mdbf + oEngine.JustStem(m.mtemp)+'!'
				ENDIF
				m.mdbf=m.mdbf + CURSORGETPROP("sourcename",wzaQDD[m.i,1])
				IF at(' ',m.mdbf)>0
					m.mdbf='"'+m.mdbf+'"'
				ENDIF
				m.wzsDBFs=m.wzsDBFs + m.mdbf

				* save table name for JOIN condition
				aTables[m.i] = m.mdbf
			ENDIF
		OTHERWISE
			m.wzsDBFs=m.wzsDBFs+wzaQDD[m.i,1]
		ENDCASE
		IF m.qwiztype#'R'
			m.wzsDBFs=m.wzsDBFs+' '+wzaQDD[m.i,1]	&&local alias
		ENDIF
		m.wzsDBFs=m.wzsDBFs+','
	ENDFOR
	m.wzsDBFs = LEFT(m.wzsDBFs,LEN(m.wzsDBFs)-1)

	* create FROM clause with join clause
	m.wzlOuter = ALEN(wzaQDD,1) = 2 AND ;
				 (VAL(wzaQDD[2,5]) > 0 OR OEngine.nJoinOption > 1)		&&Outer Join for 2 tables

	IF m.wzlOuter
		* Join is part of the FROM clause
		m.joinOper = IIF(OEngine.nJoinOption = 2, "LEFT OUTER JOIN", ;
					 IIF(OEngine.nJoinOption = 3, "RIGHT OUTER JOIN", "FULL OUTER JOIN"))
		 
		m.wzsJoin = aTables[1] + " " + wzaQDD[1,1] + ;
					IIF(ATCC(" ",wzaQDD[1,1])#0," "+CHRTRANC(EVAL(wzaQDD[1,1])," ","_"),"") + ;
					" " + m.joinOper + " " + aTables[2] + " " + wzaQDD[2,1] + ;
					IIF(ATCC(" ",wzaQDD[2,1])#0," "+CHRTRANC(EVAL(wzaQDD[2,1])," ","_"),"") + ;
					" ON " + JoinCond(wzaQDD[2,3], wzaQDD[2,4]) + " = " + JoinCond(wzaQDD[2,1], wzaQDD[2,2])

		* handle remote views with ODBC syntax
		IF m.qWizType='R' AND OEngine.lOdbcJoin
			* for RIGHT JOIN comute to LEFT JOIN to match ODBC syntax
			IF OEngine.nJoinOption = 3 
				m.wzsJoin = aTables[2] + " " + wzaQDD[2,1] + ;
				IIF(ATCC(" ",wzaQDD[2,1])#0," "+CHRTRANC(EVAL(wzaQDD[2,1])," ","_"),"") + ;
				" LEFT OUTER JOIN " + aTables[1] + " " + wzaQDD[1,1] + ;
				IIF(ATCC(" ",wzaQDD[1,1])#0," "+CHRTRANC(EVAL(wzaQDD[1,1])," ","_"),"") + ;	
				" ON " + JoinCond(wzaQDD[2,1], wzaQDD[2,2]) + " = " + JoinCond(wzaQDD[2,3], wzaQDD[2,4])
			ENDIF
			IF ATCC("FoxPro",oEngine.cDriver)=0
				m.wzsJoin = "{oj " + m.wzsJoin + " }"
			ENDIF
		ENDIF
	ELSE
		* INNER Join is added to the FROM clause, except remote view wizard where is added to WHERE clause- AT 04/23/96
		IF ALEN(wzaQDD,1)<2
			m.wzajoin = ''
		ELSE	
			IF m.qWizType = 'R' 
				FOR m.i = 2 TO ALEN(wzaQDD, 1)
					m.wzsJoin = m.wzsJoin + IIF(m.i=2, "", " AND ")+ ;
					JoinCond(wzaQDD[m.i,3],wzaQDD[m.i,4])+' = '+ ;
					JoinCond(wzaQDD[m.i,1],wzaQDD[m.i,2])
				ENDFOR
			ELSE
				m.wzsJoin = BuildInnerJoin(@wzaQDD, @aTables, 2)
			ENDIF
		ENDIF
	ENDIF
	
	* create the Sql query
	DO CASE
	CASE m.QWizType='R' AND !oEngine.lIsPreview
		\CREATE SQL VIEW '<<m.wzsViewName>>' REMOTE CONNECTION '<<oEngine.cConnect>>' AS SELECT 
	CASE m.QWizType='V' AND !oEngine.lIsPreview
		\CREATE SQL VIEW '<<m.wzsViewName>>'  AS SELECT 
	CASE m.QWizType='Q' OR oEngine.lIsPreview
		\SELECT 
	ENDCASE

	IF !EMPTY(wzaQSort[1])
		IF OEngine.nAmount != -1
			\\TOP <<TRIM(STR(OEngine.nAmount, 3))>> 
			IF OEngine.nPortion = 1
				\\PERCENT 
			ENDIF
		ENDIF
	ENDIF

	DO OutStr WITH m.Prefix+CHR(9)+CHR(9),m.wzsFldLst,0,1,','
	
	* INNER JOIN is included in FROM for query and local view
	* wzsJoin holds the join conditions. For an ODBC OJ, it's ""
	IF !EMPTY(m.wzsJoin)
		IF m.qwiztype#'R'OR m.wzlOuter
			\    FROM <<m.wzsJoin>>
			m.wzsJoin = ""
		ELSE	&&inner join for remote view
			\    FROM <<m.wzsDBFs>>
		ENDIF
	ELSE
			\    FROM <<m.wzsDBFs>>
	ENDIF

	IF !EMPTY(m.wzsJoin)
		\\;
		\    WHERE <<m.wzsJoin>>
	ENDIF && !EMPTY(m.wzsJoin)
	IF !EMPTY(m.wzsFilt)
		\\;
		\    <<IIF(EMPTY(m.wzsJoin),"WHERE "," AND ")>>
		\\(<<m.wzsFilt>>)
	ENDIF && !EMPTY(wzaQFilt[1,1])

	IF !EMPTY(wzaQSort[1])
		m.wzsSort=""

		FOR m.i=1 TO ALEN(wzaQSort,1)
			m.wzsSort = IIF(m.i > 1,m.wzsSort+',',"")+wzaQSort[m.i]
			IF m.i = 1 AND m.wziQSortA=2
				m.wzsSort = m.wzsSort + " DESC "
			ENDIF
		ENDFOR &&* m.i=1 TO ALEN(wzaQSort,1)
		\\;
		\    ORDER BY <<m.wzsSort>>

		*copy file (m.wzsFileName) to 'fao.prg'

	ENDIF && !EMPTY(wzaQSort[1])
	IF !EMPTY(wzaQGrp[1,1])
		\\;
		\    GROUP BY 
		\\<<m.wzsGrp>>
	ENDIF
	IF oEngine.lIsPreview AND m.QWizType#'R'
		\\;
		\    INTO CURSOR PREVIEW_LOC
	ENDIF
	RETURN
ENDPROC

PROCEDURE JoinCond
	PARAMETERS m.wzsArea,m.wzsFld
	IF ATCC(" ",m.wzsArea)#0
		m.wzsArea=CHRTRAN(EVAL(m.wzsArea)," ","_")
	ENDIF
	IF m.wzsFld='('
		RETURN SUBSTR(m.wzsFld,2,LEN(m.wzsFld)-2)
	ELSE
		RETURN m.wzsArea+"."+m.wzsFld
	ENDIF && m.wzsFld='('
	RETURN
ENDPROC


PROCEDURE BuildInnerJoin
	PARAMETERS aJoinInfo, aTables, index
	DIMENSION aJoinInfo[ALEN(aJoinInfo,1),ALEN(aJoinInfo,2)]
	
	IF ALEN(aJoinInfo,1) == index
		* end of recursion, build join string for <index> level
		m.lcJoinStr = aTables[index-1] + " " + aJoinInfo[index-1,1] + " INNER JOIN " + ;
					  aTables[index] + " " + aJoinInfo[index,1]
	ELSE
		* build join string from <index> level down
		m.lcJoinStr = aTables[index-1] + " " + aJoinInfo[index-1,1] + " INNER JOIN " + ;
					  "(" + BuildInnerJoin(@aJoinInfo, @aTables, index+1) + ")"
	ENDIF
	
	* build join condition
	m.lcJoinStr = m.lcJoinStr + " ON " + ;
				  JoinCond(aJoinInfo[index,3], aJoinInfo[index,4]) + " = " + ;
				  JoinCond(aJoinInfo[index,1], aJoinInfo[index,2])
				  
	RETURN m.lcJoinStr
ENDPROC


PROCEDURE OutStr
	*OutStr watching for Quotes
	PARAMETERS m.wzsPref,m.wzsStr,m.wzii,m.wzsMode,m.wzsSep
	private m.wzii,m.wziLen

	DO WHILE LENC(m.wzsStr)>0
		m.wziLen=IIF(m.wzlTesting,70,70)
		IF TYPE("m.wzsMode")='N'
			DO CASE
			CASE m.wzsMode=0	&& sequential "* FIELDS =" or "SET FIELDS TO "
				\<<m.wzsPref>>
			CASE m.wzsMode=1	&& line continuation, with ';' at the end
				IF m.wzii>0
					* The following line and others have 4 spaces on it... For 3.0a they had a Tab char
					* which causes some back ends to break
					\    
				ENDIF
			ENDCASE
			IF LENC(m.wzsStr)>m.wziLen AND AT_C(m.wzsSep,m.wzsStr)>0
				m.wziLen=RATC(m.wzsSep,LEFTC(m.wzsStr,m.wziLen))
				IF m.wziLen=0
					m.wziLen=ATC(m.wzsSep,m.wzsStr)
				ENDIF
				\\<<LEFTC(m.wzsStr,m.wziLen-(1-m.wzsMode))>>
			ELSE
				\\<<m.wzsStr>>
			ENDIF
			IF m.wzsMode=1	&&trailing ; for line continuation
				\\;
			ENDIF
		ELSE
			\<<m.wzsPref>>=
			IF m.wzii>0
				\\m.<<m.wzsPref>>+
			ENDIF
			IF "'"$LEFTC(m.wzsStr,m.wziLen)
				IF '"'$LEFTC(m.wzsStr,AT_C("'",m.wzsStr)-1)
					m.wziLen=AT_C('"',m.wzsStr)
					\\'<<LEFTC(m.wzsStr,m.wziLen)>>'
				ELSE
					m.wziLen=ATC("'",m.wzsStr)
					\\"<<LEFTC(m.wzsStr,m.wziLen)>>"
				ENDIF
			ELSE
				\\'<<LEFTC(m.wzsStr,m.wziLen)>>'
			ENDIF
		ENDIF
		m.wzsStr=SUBSTRC(m.wzsStr,m.wziLen+1)
		m.wzii=m.wzii+1
	ENDDO
RETURN

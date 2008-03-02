PROCEDURE spreadit
	para mobj
	LOCAL i,cTable,j,k
	IF type("mobj")='O'
		DIMENSION wzaQFlds[ALEN(mobj.aselections,1)]
		FOR i=1 TO mobj.lstright.listcount
			k=mobj.lstRight.IndexToItemId(m.i)
			FOR j=1 TO ALEN(mobj.aselections,1)
				IF mobj.aselections[m.j,2] = m.k
					wzaQFlds[m.i] = ALLTRIM(mobj.aselections[m.j,1])
					EXIT
				ENDIF
			ENDFOR
		ENDFOR
	ENDIF
	IF m.QWizType='R'
		SET DELETED OFF
		SELECT wzaCSDD_
		DELETE ALL
	ENDIF
	IF !EMPTY(wzaQFlds[1])
		FOR i=1 TO ALEN(wzaQflds)
			wzaQFlds[m.i]=TRIM(wzaQFlds[m.i])
			cTable=wzaQFlds[m.i]
			cTable = LEFTC(m.cTable,AT_C('.',m.cTable)-1)
			IF ASCANNER(@wzaQDD,m.cTable,1)=0
				IF m.QWizType='R'
					RECALL FOR table==PADR(m.cTable,LEN(table))
				ENDIF
				IF !EMPTY(wzaQDD[1,1])
					DIMENSION wzaQDD[ALEN(wzaQDD,1)+1,6]
				ENDIF
				wzaQDD[ALEN(wzaQDD,1),1]=ALLTRIM(m.cTable)
				wzaQDD[ALEN(wzaQDD,1),2]=""		&&Child expr for relation
				wzaQDD[ALEN(wzaQDD,1),3]=""		&& parent alias
				wzaQDD[ALEN(wzaQDD,1),4]=""		&& parent expr for relation
				wzaQDD[ALEN(wzaQDD,1),5]=IIF(oEngine.cOuterjoin=0,'0','1')		&& outer join
				wzaQDD[ALEN(wzaQDD,1),6]=IIF(oEngine.nConnectHandle#0,m.cTable,DBF(ALIAS(ALLTRIM(m.cTable))))
			ENDIF
		ENDFOR
	ENDIF
	IF m.QWizType='R'
		SET DELETED ON
	ENDIF
RETURN

PROC ASCANNER
	PARAMETERS aArray,cSearch,nCol
	external array aArray
	LOCAL i
	FOR i=1 TO ALEN(aArray,1)
		IF TYPE("aArray[m.i,1]")='C' AND UPPER(aArray[m.i,1])==UPPER(cSearch)
			RETURN m.i
		ENDIF
	ENDFOR
RETURN 0
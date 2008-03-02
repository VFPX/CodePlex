PROCEDURE ShowDD
	PRIVATE m.i,m.j
	RELEASE WINDOW t.txt
	ERASE \t.txt
	SET TEXTMERGE TO \t.txt
	SET TEXTMERGE ON
	SET CONSOLE OFF
	LOCAL mo
	mo=IIF(m.qWiztype='R',owizard.form1.pageframe1.page1.pageframe1.page2.mvrfld,;
		owizard.form1.pageframe1.page1.pageframe1.page2.tblmover1)
	FOR m.i=1 TO ALEN(mo.aselections,1)
		\<<m.i>> <<mo.lstright.indextoitemid[m.i]>> <<mo.aselections[m.i,2]>> <<mo.aselections[m.i,1]>>
	ENDFOR
	\
	FOR m.i=1 TO ALEN(wzaQDD,1)
		\
		IF !EMPTY(wzaQDD[m.i,1])
			FOR m.j=1 TO 6
				\\<<padr(wzaQdd[m.i,m.j],15)>>
			ENDFOR &&* m.j=1 TO m.wziMaxAttr
		ENDIF && !EMPTY(wzaQDD[m.i,1])
	ENDFOR &&* m.i=1 TO ALEN(wzaQDD,1)
	\Fields
	FOR m.i=1 TO ALEN(wzaQFlds,1)
		\<<m.i>>	<<wzaQFlds[m.i]>>
	ENDFOR
	\Sorting
	\<<m.wziQSorta>>
	FOR m.i=1 TO ALEN(wzaQSort,1)
		\<<m.i>>	<<wzaQSort[m.i]>>
	ENDFOR
	SET TEXTMERGE TO
	SET CONSOLE ON
	DEFINE WINDOW TT AT 34,7 SIZE 27,87 CLOSE FLOAT GROW
	MODI COMM \t.txt nowait save noedit WINDOW tt
	RELEASE WINDOW tt
RETURN
*EOP ShowDD

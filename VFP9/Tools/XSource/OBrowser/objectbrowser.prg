LPARAMETERS lnTop, lnLeft

SET TALK OFF
LOCAL lcRef
lcRef="__oBrowser"+SYS(2015)
PUBLIC &lcRef
&lcRef = NEWOBJECT("cObjectBrowserInterface","ObjectBrowser.vcx")
&lcRef..cVarName = lcRef
IF NOT VarType(&lcRef) = "O"
	RETURN
ENDIF
IF VARTYPE(lnTop)="N"
	&lcRef..Top = lnTop
ENDIF
IF VARTYPE(lnLeft) = "N"
	&lcRef..Left = lnLeft
ENDIF
&lcRef..Show

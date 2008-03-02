LPARAMETER p1, p2, p3, p4, p5, p6, p7, p8, p9

#INCLUDE "ffc\_ws3.h"

IF TYPE("m.p4")#"C"
	m.p4 = ""
ENDIF

LOCAL lISenseOnly, loConfig, loWS, loTest, lcVFPWSDBF
lISenseOnly = ATC("INTELLISENSE",m.p4)#0

* Check that MSSoap is installed.
loTest = CREATEOBJECT("TestSoap")
IF !loTest.IsSoapSDK()
	MESSAGEBOX(NOSOAP_LOC)
	RETURN
ENDIF

* Check if IIS is installed (first time only).
lcVFPWSDBF = ADDBS(JUSTPATH(_FOXCODE)) + FOXWSDBF
IF !FILE(lcVFPWSDBF) AND !loTest.IsIISInstalled()
	MESSAGEBOX(NOIIS_LOC)
ENDIF

IF lISenseOnly
	* Handle web service IntelliSense subscriptions only
	loWS = NEWOBJECT("wsreg",HOME()+"ffc\_ws3utils")
ELSE
	* Handle full web service publications
	loWS = NEWOBJECT("wspub",HOME()+"ffc\_ws3utils")
ENDIF

IF VARTYPE(loWS)#"O"
	RETURN
ENDIF
loWS.Show()

* Sample class used to test for IIS and MS Soap Toolkit installed.
DEFINE CLASS TestSoap AS custom
	lHadError = .F.
	FUNCTION IsIISInstalled
		LOCAL loIIS
		loIIS = GetObject("IIS://localhost")
		RELEASE loIIS
		RETURN !THIS.lHadError
	ENDFUNC
	FUNCTION IsSoapSDK
		LOCAL loSOAP
		loSOAP = CREATEOBJECT("MSSOAP.SoapClient30")
		RELEASE loSoap
		RETURN !THIS.lHadError
	ENDFUNC
	PROCEDURE Error(nError, cMethod, nLine)
		THIS.lHadError=.T.
	ENDPROC
ENDDEFINE

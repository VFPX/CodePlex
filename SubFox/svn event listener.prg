*-- SVN Event Listener --*

DEFINE CLASS PushOkSvn_SVNClient_Events AS session OLEPUBLIC
	IMPLEMENTS _ISVNClientEvents IN "C:\Program Files\Pushok Software\SVN Proxy\svn\SVNCOM.DLL"
**********************************************************************************
	PROCEDURE _ISVNClientEvents_Idle(oClient AS PushOkSvn.SVNClient) AS VOID;
 				HELPSTRING "Iddle, allos to do some UI checks, like cancellation"
		this.Idle( oClient )
	ENDPROC
**********************************************************************************
	PROCEDURE _ISVNClientEvents_WcNotify(oNotify AS PushOkSvn.SVNWcNotify) AS VOID;
 				HELPSTRING "Some changes in working copy"
		this.WcNotify(oNotify)
	ENDPROC
**********************************************************************************
	PROCEDURE _ISVNClientEvents_WcProgress(progress AS Number, total AS Number) AS VOID;
 				HELPSTRING "Opearion progress, works only for DAVcurrently"
		WcProgress(nProg, nTotal)
	ENDPROC
**********************************************************************************
	FUNCTION Idle(oClient)
		* oClient.RequestCancelation()
	ENDFUNC && Idle
**********************************************************************************
	FUNCTION WcNotify(oNotify)
	ENDFUNC && WcNotify
**********************************************************************************
	FUNCTION WcProgress(nProg, nTotal)
	ENDFUNC && WcProgress
ENDDEFINE
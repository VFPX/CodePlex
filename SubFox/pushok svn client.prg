*-- PushOk SVN Client --*

DEFINE CLASS PushOK_Client_Model AS session && OLEPUBLIC
IMPLEMENTS ISVNClient IN "PushOkSvn.SVNClient"

	PROCEDURE ISVNClient_GetStatus(sPath AS STRING, bRecurse AS LOGICAL, sRev AS STRING, bGetAll AS LOGICAL, bUpdate AS LOGICAL, bNoIgnore AS LOGICAL, bIgnoreExternals AS LOGICAL) AS VARIANT;
 				HELPSTRING "svn status"
	PROCEDURE ISVNClient_AddFiles(arPathsToAdd AS VARIANT, bRecurse AS LOGICAL, bForce AS LOGICAL, bNoIgnore AS LOGICAL) AS VARIANT;
 				HELPSTRING "svn add"
	PROCEDURE ISVNClient_GetFiles(arPathsToUpdate AS VARIANT, sRev AS STRING, bRecurse AS LOGICAL, bIgnoreExternals AS LOGICAL) AS VARIANT;
 				HELPSTRING "svn update"
	PROCEDURE ISVNClient_List(sPath AS STRING, sPegRevision AS STRING, sRevision AS STRING, bRecurse AS LOGICAL) AS VARIANT;
 				HELPSTRING "svn ls"
	PROCEDURE ISVNClient_LockFiles(arPathsToLock AS VARIANT, sComment AS STRING, bStealLock AS LOGICAL) AS VOID;
 				HELPSTRING "svn lock"
	PROCEDURE ISVNClient_UnLockFiles(arPathToUnlock AS VARIANT, bStealLock AS LOGICAL) AS VOID;
 				HELPSTRING "svn unlock"
	PROCEDURE ISVNClient_Revert(arPathsToRevert AS VARIANT, bRecursive AS LOGICAL) AS VOID;
 				HELPSTRING "svn revert"
	PROCEDURE ISVNClient_Delete(arPathsToDelete AS VARIANT, sComment AS STRING, bForce AS LOGICAL) AS VOID;
 				HELPSTRING "svn delete"
	PROCEDURE ISVNClient_MkDir(arPathsToCreate AS VARIANT, sComment AS STRING) AS VOID;
 				HELPSTRING "svn mkdir"
	PROCEDURE ISVNClient_CleanUp(arPathsToClean AS VARIANT) AS VOID;
 				HELPSTRING "svn cleanup"
	PROCEDURE ISVNClient_Move(arPathsSrc AS VARIANT, arPathsDst AS VARIANT, bForce AS LOGICAL, sComment AS STRING) AS VOID;
 				HELPSTRING "svn move"
	PROCEDURE ISVNClient_Resolved(arPathsToResolve AS VARIANT, bRecursive AS LOGICAL) AS VOID;
 				HELPSTRING "svn resolved"
	PROCEDURE ISVNClient_Commit(arPathsToCommit AS VARIANT, sComment AS STRING, bRecursive AS LOGICAL, bKeepLock AS LOGICAL) AS VOID;
 				HELPSTRING "svn commit"
	PROCEDURE ISVNClient_Copy(arPathsSrc AS VARIANT, arPathsDst AS VARIANT, sComment AS STRING, sStartRevision AS STRING) AS VOID;
 				HELPSTRING "svn copy"
	PROCEDURE ISVNClient_CheckOut(arPaths AS VARIANT, sPegRevision AS STRING, sStartRevision AS STRING, bRecursive AS LOGICAL, bIgnoreExternals AS LOGICAL) AS VOID;
 				HELPSTRING "svn checkout"
	PROCEDURE ISVNClient_Log(arStrings AS VARIANT, sStartRev AS STRING, sEndRev AS STRING, lLimit AS Number, bVerbose AS LOGICAL, bStopOnCopy AS LOGICAL) AS VARIANT;
 				HELPSTRING "svn log"
	PROCEDURE ISVNClient_Info(arPathsForInfo AS VARIANT, sPegRev AS STRING, sStartRev AS STRING, bRecursive AS LOGICAL) AS VARIANT;
 				HELPSTRING "svn info"
	PROCEDURE ISVNClient_PropGet(sFile AS STRING, sPropName AS STRING, sPegRev AS STRING, sStartRev AS STRING, bRecursive AS LOGICAL) AS STRING;
 				HELPSTRING "svn propget"
	PROCEDURE ISVNClient_PropSet(sFile AS STRING, sPropName AS STRING, sVal AS STRING, bRecursive AS LOGICAL, bForce AS LOGICAL) AS VOID;
 				HELPSTRING "svn propset"
	PROCEDURE ISVNClient_PropDel(sFile AS STRING, sPropName AS STRING, bRecursive AS LOGICAL) AS VOID;
 				HELPSTRING "svn propdel"
	PROCEDURE ISVNClient_PropList(sFile AS STRING, sPegRev AS STRING, sStartRev AS STRING, bRecursive AS LOGICAL) AS VARIANT;
 				HELPSTRING "svn proplist"
	PROCEDURE ISVNClient_Annotate(sFile AS STRING, sPegRev AS STRING, sStartRev AS STRING, sEndRev AS STRING) AS VARIANT;
 				HELPSTRING "svn annotate"
	PROCEDURE ISVNClient_Cat(sFile AS STRING, sPegRev AS STRING, sStartRev AS STRING) AS STRING;
 				HELPSTRING "svn cat"
	PROCEDURE ISVNClient_ExportFiles(arFilesSrc AS VARIANT, arFilesDst AS VARIANT, sPegRevision AS STRING, sRevision AS STRING, bRecurse AS LOGICAL, bOverwrite AS LOGICAL, bIgnoreExternals AS LOGICAL) AS VOID;
 				HELPSTRING "svn export"
	PROCEDURE ISVNClient_ImportFiles(arFilesSrc AS VARIANT, arFilesDst AS VARIANT, sComment AS STRING, bNonRecursive AS LOGICAL, bNoIgnore AS LOGICAL) AS VOID;
 				HELPSTRING "svn import"
	PROCEDURE ISVNClient_Relocate(sPath AS STRING, sFrom AS STRING, sTo AS STRING, bRecursive AS LOGICAL) AS VOID;
 				HELPSTRING "svn relocate"
	PROCEDURE ISVNClient_Diff(sOptions AS STRING, sPath1 AS STRING, sRevision1 AS STRING, sPath2 AS STRING, sRevision2 AS STRING, sOutFile AS STRING, sErrFile AS STRING, sHeaderEncoding AS STRING, bRecursive AS LOGICAL, bIgnoreAncestry AS LOGICAL, bNoDiffDeleted AS LOGICAL, bIgnoreContentType AS LOGICAL) AS VOID;
 				HELPSTRING "svn diff"
	PROCEDURE ISVNClient_DiffPeg(sOptions AS STRING, sPath AS STRING, sPegRevision AS STRING, sStartRevision AS STRING, sEndRevision AS STRING, sOutFile AS STRING, sErrFile AS STRING, sHeaderEncoding AS STRING, bRecursive AS LOGICAL, bIgnoreAncestry AS LOGICAL, bNoDiffDeleted AS LOGICAL, bIgnoreContentType AS LOGICAL) AS VOID;
 				HELPSTRING "svn diffpeg"
	PROCEDURE ISVNClient_Merge(sSource1 AS STRING, sRevision1 AS STRING, sSource2 AS STRING, sRevision2 AS STRING, sTargetWCPath AS STRING, bRecursive AS LOGICAL, bIgnoreAncestry AS LOGICAL, bForce AS LOGICAL, bDryRun AS LOGICAL) AS VOID;
 				HELPSTRING "svn merge"
	PROCEDURE ISVNClient_MergePeg(sSource AS STRING, sPegRevision AS STRING, sStartRevision AS STRING, sEndRevision AS STRING, sTargetWCPath AS STRING, bRecursive AS LOGICAL, bIgnoreAncestry AS LOGICAL, bForce AS LOGICAL, bDryRun AS LOGICAL) AS VOID;
 				HELPSTRING "svn mergepeg"
	PROCEDURE ISVNClient_RevPropGet(sUrl AS STRING, sPropName AS STRING, sRev AS STRING) AS STRING;
 				HELPSTRING "svn propget --revprop"
	PROCEDURE ISVNClient_RevPropSet(sUrl AS STRING, sPropName AS STRING, sVal AS STRING, sRev AS STRING, bForce AS LOGICAL) AS VOID;
 				HELPSTRING "svn propset --revprop"
	PROCEDURE ISVNClient_RevPropDel(sUrl AS STRING, sPropName AS STRING, sRev AS STRING) AS VOID;
 				HELPSTRING "svn propdel --revprop"
	PROCEDURE ISVNClient_RevPropList(sUrl AS STRING, sRev AS STRING) AS VARIANT;
 				HELPSTRING "svn proplist --revprop"
	PROCEDURE ISVNClient_Version(nComSvnVersion AS Number, nSvnVersion AS Number) AS STRING;
 				HELPSTRING "Version of binding and svn"
	PROCEDURE ISVNClient_InitClient() AS VOID;
 				HELPSTRING "InitClient, may be called or not. It will be called automaticaly on any call."
	PROCEDURE ISVNClient_SetupAuth(nCookie AS Number) AS Number;
 				HELPSTRING "Setup auth to access server, nCookie is NULL for new call or eralier used Cookie"
	PROCEDURE ISVNClient_RequestCancelation() AS VOID;
 				HELPSTRING "Request cancelation of operation, if possible"
	PROCEDURE ISVNClient_SetOption(eOption AS VARIANT, vVal AS VARIANT) AS VOID;
 				HELPSTRING "Set option."
	PROCEDURE ISVNClient_GetOption(eOption AS VARIANT) AS VARIANT;
 				HELPSTRING "Get option."
	PROCEDURE ISVNClient_RaCheckUrlValid(sUrl AS STRING, sRev AS STRING) AS VOID;
 				HELPSTRING "Check is URL exist in repository"
	PROCEDURE ISVNClient_WcRestoreFiles(arStrings AS VARIANT, bUseCommitTimes AS LOGICAL) AS VOID;
 				HELPSTRING "Restore files in woking copy fast from the text_base"

	PROCEDURE ISVNClient_WcNotify(obj)
	ENDPROC && obj_WcNotify

ENDDEFINE && PushOK_Client_Model

*-- PushOk SVN Admin --*

DEFINE CLASS Admin_Model AS session && OLEPUBLIC

	IMPLEMENTS ISVNAdmin IN "PushOkSvn.SVNAdmin"

	PROCEDURE ISVNAdmin_CreateRepository(sReposPath AS STRING, nReposType AS STRING) AS VOID;
 				HELPSTRING "method CreateRepository"
	* add user code here
	ENDPROC

ENDDEFINE

DEFINE CLASS AuthManager_Model AS session && OLEPUBLIC

	IMPLEMENTS ISVNAuthManager IN "PushOkSvn.SVNAuthManager"

	PROCEDURE ISVNAuthManager_CreateAuthProvider(pProvider AS VARIANT) AS Number;
 				HELPSTRING "Creates new auth provider and returing its cookie"
	* add user code here
	ENDPROC

	PROCEDURE ISVNAuthManager_RetrieveAuthProvider(dwCookie AS Number) AS VARIANT;
 				HELPSTRING "Retrieve auth provider entity if it is registered"
	* add user code here
	ENDPROC

	PROCEDURE ISVNAuthManager_AddRefAuthProvider(dwCookie AS Number) AS VOID;
 				HELPSTRING "Add reference to auth entity"
	* add user code here
	ENDPROC

	PROCEDURE ISVNAuthManager_ReleaseAuthProvider(dwCookie AS Number) AS VOID;
 				HELPSTRING "Mark that entity no longe used"
	* add user code here
	ENDPROC

	PROCEDURE ISVNAuthManager_RevokeAuthProvider(dwCookie AS Number) AS VOID;
 				HELPSTRING "Revoke auth entity regardless its usage"
	* add user code here
	ENDPROC

ENDDEFINE && AuthManager_Model

DEFINE CLASS Lock_Model AS session && OLEPUBLIC

	IMPLEMENTS ISVNLock IN "PushOkSvn.SVNLock"

	PROCEDURE ISVNLock_put_Path(eValue AS STRING @);
 				HELPSTRING "property Path"
	* add user code here
	ENDPROC

	PROCEDURE ISVNLock_get_Path() AS STRING;
 				HELPSTRING "property Path"
	* add user code here
	ENDPROC

	PROCEDURE ISVNLock_put_Token(eValue AS STRING @);
 				HELPSTRING "property Token"
	* add user code here
	ENDPROC

	PROCEDURE ISVNLock_get_Token() AS STRING;
 				HELPSTRING "property Token"
	* add user code here
	ENDPROC

	PROCEDURE ISVNLock_put_Owner(eValue AS STRING @);
 				HELPSTRING "property Owner"
	* add user code here
	ENDPROC

	PROCEDURE ISVNLock_get_Owner() AS STRING;
 				HELPSTRING "property Owner"
	* add user code here
	ENDPROC

	PROCEDURE ISVNLock_put_Comment(eValue AS STRING @);
 				HELPSTRING "property Comment"
	* add user code here
	ENDPROC

	PROCEDURE ISVNLock_get_Comment() AS STRING;
 				HELPSTRING "property Comment"
	* add user code here
	ENDPROC

	PROCEDURE ISVNLock_put_IsDavComment(eValue AS Number @);
 				HELPSTRING "property IsDavComment"
	* add user code here
	ENDPROC

	PROCEDURE ISVNLock_get_IsDavComment() AS Number;
 				HELPSTRING "property IsDavComment"
	* add user code here
	ENDPROC

	PROCEDURE ISVNLock_put_CreationDate(eValue AS Currency @);
 				HELPSTRING "property CreationDate"
	* add user code here
	ENDPROC

	PROCEDURE ISVNLock_get_CreationDate() AS Currency;
 				HELPSTRING "property CreationDate"
	* add user code here
	ENDPROC

	PROCEDURE ISVNLock_put_ExpirationDate(eValue AS Currency @);
 				HELPSTRING "property ExpirationDate"
	* add user code here
	ENDPROC

	PROCEDURE ISVNLock_get_ExpirationDate() AS Currency;
 				HELPSTRING "property ExpirationDate"
	* add user code here
	ENDPROC

ENDDEFINE

DEFINE CLASS WcAnn_Model AS session && OLEPUBLIC

	IMPLEMENTS ISVNWcAnn IN "PushOkSvn.SVNWcAnnVector"

	PROCEDURE ISVNWcAnn_put_Rev(eValue AS Number @);
 				HELPSTRING "property Rev"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcAnn_get_Rev() AS Number;
 				HELPSTRING "property Rev"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcAnn_put_Author(eValue AS STRING @);
 				HELPSTRING "property Author"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcAnn_get_Author() AS STRING;
 				HELPSTRING "property Author"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcAnn_put_Date(eValue AS STRING @);
 				HELPSTRING "property Date"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcAnn_get_Date() AS STRING;
 				HELPSTRING "property Date"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcAnn_put_Line(eValue AS STRING @);
 				HELPSTRING "property Line"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcAnn_get_Line() AS STRING;
 				HELPSTRING "property Line"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcAnn_put_LineNo(eValue AS Currency @);
 				HELPSTRING "property LineNo"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcAnn_get_LineNo() AS Currency;
 				HELPSTRING "property LineNo"
	* add user code here
	ENDPROC

ENDDEFINE && WcAnn_Model

DEFINE CLASS WcAnnVector_Model AS session && OLEPUBLIC

	IMPLEMENTS ISVNWcAnnVector IN "PushOkSvn.SVNWcAnnVector"

	PROCEDURE ISVNWcAnnVector_get__NewEnum() AS VARIANT
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcAnnVector_get_Item(Index AS Number) AS VARIANT
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcAnnVector_get_Count() AS Number
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcAnnVector_Add(pVal AS VARIANT) AS VOID
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcAnnVector_Remove(Index AS Number) AS VOID
	* add user code here
	ENDPROC

ENDDEFINE && WcAnnVector_Model

DEFINE CLASS WcEntry_Model AS session && OLEPUBLIC

	IMPLEMENTS ISVNWcEntry IN "PushOkSvn.SVNWcEntry"

	PROCEDURE ISVNWcEntry_put_Name(eValue AS STRING @);
 				HELPSTRING "property Name"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_Name() AS STRING;
 				HELPSTRING "property Name"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_Revision(eValue AS Number @);
 				HELPSTRING "property Revision"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_Revision() AS Number;
 				HELPSTRING "property Revision"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_Url(eValue AS STRING @);
 				HELPSTRING "property Url"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_Url() AS STRING;
 				HELPSTRING "property Url"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_Repos(eValue AS STRING @);
 				HELPSTRING "property Repos"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_Repos() AS STRING;
 				HELPSTRING "property Repos"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_Uuid(eValue AS STRING @);
 				HELPSTRING "property Uuid"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_Uuid() AS STRING;
 				HELPSTRING "property Uuid"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_Kind(eValue AS VARIANT @);
 				HELPSTRING "property Kind"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_Kind() AS VARIANT;
 				HELPSTRING "property Kind"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_Schedule(eValue AS VARIANT @);
 				HELPSTRING "property Schedule"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_Schedule() AS VARIANT;
 				HELPSTRING "property Schedule"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_Copied(eValue AS Number @);
 				HELPSTRING "property Copied"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_Copied() AS Number;
 				HELPSTRING "property Copied"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_Deleted(eValue AS Number @);
 				HELPSTRING "property Deleted"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_Deleted() AS Number;
 				HELPSTRING "property Deleted"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_Absent(eValue AS Number @);
 				HELPSTRING "property Absent"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_Absent() AS Number;
 				HELPSTRING "property Absent"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_Incomplete(eValue AS Number @);
 				HELPSTRING "property Incomplete"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_Incomplete() AS Number;
 				HELPSTRING "property Incomplete"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_CopyFromUrl(eValue AS STRING @);
 				HELPSTRING "property CopyFromUrl"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_CopyFromUrl() AS STRING;
 				HELPSTRING "property CopyFromUrl"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_CopyFromRev(eValue AS Number @);
 				HELPSTRING "property CopyFromRev"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_CopyFromRev() AS Number;
 				HELPSTRING "property CopyFromRev"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_ConflictOld(eValue AS STRING @);
 				HELPSTRING "property ConflictOld"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_ConflictOld() AS STRING;
 				HELPSTRING "property ConflictOld"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_ConflictNew(eValue AS STRING @);
 				HELPSTRING "property ConflictNew"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_ConflictNew() AS STRING;
 				HELPSTRING "property ConflictNew"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_ConflictWrk(eValue AS STRING @);
 				HELPSTRING "property ConflictWrk"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_ConflictWrk() AS STRING;
 				HELPSTRING "property ConflictWrk"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_Prejfile(eValue AS STRING @);
 				HELPSTRING "property Prejfile"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_Prejfile() AS STRING;
 				HELPSTRING "property Prejfile"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_TextTime(eValue AS Currency @);
 				HELPSTRING "property TextTime"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_TextTime() AS Currency;
 				HELPSTRING "property TextTime"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_PropTime(eValue AS Currency @);
 				HELPSTRING "property PropTime"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_PropTime() AS Currency;
 				HELPSTRING "property PropTime"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_Checksum(eValue AS STRING @);
 				HELPSTRING "property Checksum"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_Checksum() AS STRING;
 				HELPSTRING "property Checksum"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_CmtRev(eValue AS Number @);
 				HELPSTRING "property CmtRev"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_CmtRev() AS Number;
 				HELPSTRING "property CmtRev"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_CmtDate(eValue AS Currency @);
 				HELPSTRING "property CmtDate"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_CmtDate() AS Currency;
 				HELPSTRING "property CmtDate"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_CmtAuthor(eValue AS STRING @);
 				HELPSTRING "property CmtAuthor"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_CmtAuthor() AS STRING;
 				HELPSTRING "property CmtAuthor"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_LockToken(eValue AS STRING @);
 				HELPSTRING "property LockToken"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_LockToken() AS STRING;
 				HELPSTRING "property LockToken"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_LockOwner(eValue AS STRING @);
 				HELPSTRING "property LockOwner"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_LockOwner() AS STRING;
 				HELPSTRING "property LockOwner"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_LockComment(eValue AS STRING @);
 				HELPSTRING "property LockComment"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_LockComment() AS STRING;
 				HELPSTRING "property LockComment"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_put_LockCreationDate(eValue AS Currency @);
 				HELPSTRING "property LockCreationDate"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcEntry_get_LockCreationDate() AS Currency;
 				HELPSTRING "property LockCreationDate"
	* add user code here
	ENDPROC

ENDDEFINE && WcEntry_Model

DEFINE CLASS WcInfo_Model AS session && OLEPUBLIC

	IMPLEMENTS ISVNWcInfo IN "PushOkSvn.SVNWcInfoVector"

	PROCEDURE ISVNWcInfo_put_Url(eValue AS STRING @);
 				HELPSTRING "property Url"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_get_Url() AS STRING;
 				HELPSTRING "property Url"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_put_ReposRootUrl(eValue AS STRING @);
 				HELPSTRING "property ReposRootURL"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_get_ReposRootUrl() AS STRING;
 				HELPSTRING "property ReposRootURL"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_put_ReposUUID(eValue AS STRING @);
 				HELPSTRING "property ReposUUID"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_get_ReposUUID() AS STRING;
 				HELPSTRING "property ReposUUID"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_put_LastChangedAuthor(eValue AS STRING @);
 				HELPSTRING "property LastChangedAuthor"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_get_LastChangedAuthor() AS STRING;
 				HELPSTRING "property LastChangedAuthor"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_put_CopyFromUrl(eValue AS STRING @);
 				HELPSTRING "property CopyFromUrl"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_get_CopyFromUrl() AS STRING;
 				HELPSTRING "property CopyFromUrl"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_put_Checksum(eValue AS STRING @);
 				HELPSTRING "property Checksum"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_get_Checksum() AS STRING;
 				HELPSTRING "property Checksum"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_put_ConflictOld(eValue AS STRING @);
 				HELPSTRING "property ConflictOld"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_get_ConflictOld() AS STRING;
 				HELPSTRING "property ConflictOld"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_put_ConflictNew(eValue AS STRING @);
 				HELPSTRING "property ConflictNew"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_get_ConflictNew() AS STRING;
 				HELPSTRING "property ConflictNew"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_put_ConflictWrk(eValue AS STRING @);
 				HELPSTRING "property ConflictWrk"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_get_ConflictWrk() AS STRING;
 				HELPSTRING "property ConflictWrk"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_put_Prejfile(eValue AS STRING @);
 				HELPSTRING "property PrejFile"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_get_Prejfile() AS STRING;
 				HELPSTRING "property PrejFile"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_put_Revision(eValue AS Number @);
 				HELPSTRING "property Revision"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_get_Revision() AS Number;
 				HELPSTRING "property Revision"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_put_LastChangedRev(eValue AS Number @);
 				HELPSTRING "property LastChangedRev"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_get_LastChangedRev() AS Number;
 				HELPSTRING "property LastChangedRev"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_put_CopyFromRev(eValue AS Number @);
 				HELPSTRING "property CopyFromRev"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_get_CopyFromRev() AS Number;
 				HELPSTRING "property CopyFromRev"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_put_HasWcInfo(eValue AS Number @);
 				HELPSTRING "property HasWcInfo"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_get_HasWcInfo() AS Number;
 				HELPSTRING "property HasWcInfo"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_put_LastChangedDate(eValue AS Currency @);
 				HELPSTRING "property LastChangedDate"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_get_LastChangedDate() AS Currency;
 				HELPSTRING "property LastChangedDate"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_put_TextTime(eValue AS Currency @);
 				HELPSTRING "property TextTime"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_get_TextTime() AS Currency;
 				HELPSTRING "property TextTime"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_put_PropTime(eValue AS Currency @);
 				HELPSTRING "property PropTime"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_get_PropTime() AS Currency;
 				HELPSTRING "property PropTime"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_put_Kind(eValue AS VARIANT @);
 				HELPSTRING "property Kind"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_get_Kind() AS VARIANT;
 				HELPSTRING "property Kind"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_put_Schedule(eValue AS VARIANT @);
 				HELPSTRING "property Schedule"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_get_Schedule() AS VARIANT;
 				HELPSTRING "property Schedule"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_put_Path(eValue AS STRING @);
 				HELPSTRING "property Path"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_get_Path() AS STRING;
 				HELPSTRING "property Path"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_put_Lock(eValue AS VARIANT @);
 				HELPSTRING "property Lock"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfo_get_Lock() AS VARIANT;
 				HELPSTRING "property Lock"
	* add user code here
	ENDPROC

ENDDEFINE

DEFINE CLASS WcInfoVector_Model AS session && OLEPUBLIC

	IMPLEMENTS ISVNWcInfoVector IN "PushOkSvn.SVNWcInfoVector"

	PROCEDURE ISVNWcInfoVector_get__NewEnum() AS VARIANT
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfoVector_get_Item(Index AS Number) AS VARIANT
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfoVector_get_Count() AS Number
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfoVector_Add(pVal AS VARIANT) AS VOID
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfoVector_Remove(Index AS Number) AS VOID
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcInfoVector_Clear() AS VOID
	* add user code here
	ENDPROC

ENDDEFINE && WcInfoVector_Model

DEFINE CLASS Log_Model AS session && OLEPUBLIC
	IMPLEMENTS ISVNWcLog IN "PushOkSvn.SVNWcLogVector"

	PROCEDURE ISVNWcLog_put_Revision(eValue AS Number @);
 				HELPSTRING "property Revision"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcLog_get_Revision() AS Number;
 				HELPSTRING "property Revision"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcLog_put_Author(eValue AS STRING @);
 				HELPSTRING "property Author"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcLog_get_Author() AS STRING;
 				HELPSTRING "property Author"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcLog_put_Date(eValue AS STRING @);
 				HELPSTRING "property Date"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcLog_get_Date() AS STRING;
 				HELPSTRING "property Date"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcLog_put_Message(eValue AS STRING @);
 				HELPSTRING "property Message"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcLog_get_Message() AS STRING;
 				HELPSTRING "property Message"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcLog_get_CountChangedPaths() AS Number
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcLog_AddChangedPath(sPath AS STRING, cAction AS STRING, sCopyFrom AS STRING, nCopyRev AS Number) AS VOID
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcLog_GetChangedPath(iIndex AS Number, sPath AS STRING, cAction AS STRING, sCopyFrom AS STRING, nCopyRev AS Number) AS VOID
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcLog_Clear() AS VOID
	* add user code here
	ENDPROC

ENDDEFINE

DEFINE CLASS WcLogVector_Model AS session && OLEPUBLIC

	IMPLEMENTS ISVNWcLogVector IN "PushOkSvn.SVNWcLogVector"

	PROCEDURE ISVNWcLogVector_get__NewEnum() AS VARIANT
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcLogVector_get_Item(Index AS Number) AS VARIANT
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcLogVector_get_Count() AS Number
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcLogVector_Add(pVal AS VARIANT) AS VOID
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcLogVector_Remove(Index AS Number) AS VOID
	* add user code here
	ENDPROC

ENDDEFINE && WcLogVector_Model

DEFINE CLASS WcNotify_Model AS session && OLEPUBLIC

	IMPLEMENTS ISVNWcNotify IN "PushOkSvn.SVNWcNotifyVector"

	PROCEDURE ISVNWcNotify_put_Path(eValue AS STRING @);
 				HELPSTRING "property Path"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotify_get_Path() AS STRING;
 				HELPSTRING "property Path"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotify_put_Action(eValue AS VARIANT @);
 				HELPSTRING "property Action"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotify_get_Action() AS VARIANT;
 				HELPSTRING "property Action"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotify_put_Kind(eValue AS VARIANT @);
 				HELPSTRING "property Kind"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotify_get_Kind() AS VARIANT;
 				HELPSTRING "property Kind"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotify_put_Lock(eValue AS VARIANT @);
 				HELPSTRING "property Lock"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotify_get_Lock() AS VARIANT;
 				HELPSTRING "property Lock"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotify_put_CodeError(eValue AS Number @);
 				HELPSTRING "property CodeError"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotify_get_CodeError() AS Number;
 				HELPSTRING "property CodeError"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotify_put_StrError(eValue AS STRING @);
 				HELPSTRING "property StrError"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotify_get_StrError() AS STRING;
 				HELPSTRING "property StrError"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotify_put_ContState(eValue AS VARIANT @);
 				HELPSTRING "property ContState"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotify_get_ContState() AS VARIANT;
 				HELPSTRING "property ContState"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotify_put_PropState(eValue AS VARIANT @);
 				HELPSTRING "property PropState"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotify_get_PropState() AS VARIANT;
 				HELPSTRING "property PropState"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotify_put_LockState(eValue AS VARIANT @);
 				HELPSTRING "property LockState"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotify_get_LockState() AS VARIANT;
 				HELPSTRING "property LockState"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotify_put_Revision(eValue AS Number @);
 				HELPSTRING "property Revision"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotify_get_Revision() AS Number;
 				HELPSTRING "property Revision"
	* add user code here
	ENDPROC

ENDDEFINE && WcNotify_Model

DEFINE CLASS WcNotifyVector_Model AS session && OLEPUBLIC

	IMPLEMENTS ISVNWcNotifyVector IN "PushOkSvn.SVNWcNotifyVector"

	PROCEDURE ISVNWcNotifyVector_get__NewEnum() AS VARIANT
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotifyVector_get_Item(Index AS Number) AS VARIANT
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotifyVector_get_Count() AS Number
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotifyVector_Add(pVal AS VARIANT) AS VOID
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotifyVector_Remove(Index AS Number) AS VOID
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcNotifyVector_Clear() AS VOID
	* add user code here
	ENDPROC

ENDDEFINE && WcNotifyVector_Model

DEFINE CLASS WcPropList_Model AS session && OLEPUBLIC

	IMPLEMENTS ISVNWcPropList IN "PushOkSvn.SVNWcPropListVector"

	PROCEDURE ISVNWcPropList_put_Path(eValue AS STRING @);
 				HELPSTRING "property Path"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcPropList_get_Path() AS STRING;
 				HELPSTRING "property Path"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcPropList_get_CountProp() AS Number
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcPropList_AddProp(sPropName AS STRING, sPropVal AS STRING) AS VOID
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcPropList_GetProp(sPropName AS STRING) AS STRING
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcPropList_GetPropFirst(sPropName AS STRING, sPropVal AS STRING) AS VOID
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcPropList_GetPropNext(sPropName AS STRING, sPropVal AS STRING) AS VOID
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcPropList_Clear() AS VOID
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcPropList_GetPropFirst2() AS VARIANT
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcPropList_GetPropNext2() AS VARIANT
	* add user code here
	ENDPROC

ENDDEFINE && WcPropList_Model

DEFINE CLASS WcPropListVector_Model AS session && OLEPUBLIC

	IMPLEMENTS ISVNWcPropListVector IN "PushOkSvn.SVNWcPropListVector"

	PROCEDURE ISVNWcPropListVector_get__NewEnum() AS VARIANT
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcPropListVector_get_Item(Index AS Number) AS VARIANT
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcPropListVector_get_Count() AS Number
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcPropListVector_Add(pVal AS VARIANT) AS VOID
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcPropListVector_Remove(Index AS Number) AS VOID
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcPropListVector_Clear() AS VOID
	* add user code here
	ENDPROC

ENDDEFINE && WcPropListVector_Model

DEFINE CLASS WcStatus_Model AS session && OLEPUBLIC

	IMPLEMENTS ISVNWcStatus IN "PushOkSvn.SVNWcStatusInfo"

	PROCEDURE ISVNWcStatus_put_Entry(eValue AS VARIANT @);
 				HELPSTRING "property Entry"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatus_get_Entry() AS VARIANT;
 				HELPSTRING "property Entry"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatus_put_TextStatus(eValue AS VARIANT @);
 				HELPSTRING "property TextStatus"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatus_get_TextStatus() AS VARIANT;
 				HELPSTRING "property TextStatus"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatus_put_PropStatus(eValue AS VARIANT @);
 				HELPSTRING "property PropStatus"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatus_get_PropStatus() AS VARIANT;
 				HELPSTRING "property PropStatus"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatus_put_Locked(eValue AS Number @);
 				HELPSTRING "property Locked"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatus_get_Locked() AS Number;
 				HELPSTRING "property Locked"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatus_put_Copied(eValue AS Number @);
 				HELPSTRING "property Copied"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatus_get_Copied() AS Number;
 				HELPSTRING "property Copied"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatus_put_Switched(eValue AS Number @);
 				HELPSTRING "property Switched"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatus_get_Switched() AS Number;
 				HELPSTRING "property Switched"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatus_put_ReposTextStatus(eValue AS VARIANT @);
 				HELPSTRING "property ReposTextStatus"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatus_get_ReposTextStatus() AS VARIANT;
 				HELPSTRING "property ReposTextStatus"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatus_put_ReposPropStatus(eValue AS VARIANT @);
 				HELPSTRING "property ReposPropStatus"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatus_get_ReposPropStatus() AS VARIANT;
 				HELPSTRING "property ReposPropStatus"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatus_put_ReposLock(eValue AS VARIANT @);
 				HELPSTRING "property ReposLock"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatus_get_ReposLock() AS VARIANT;
 				HELPSTRING "property ReposLock"
	* add user code here
	ENDPROC

ENDDEFINE && WcStatus_Model

DEFINE CLASS WcStatusCollection_Model AS session && OLEPUBLIC

	IMPLEMENTS ISVNWcStatusCollection IN "PushOkSvn.SVNWcStatusCollection"

	PROCEDURE ISVNWcStatusCollection_get__NewEnum() AS VARIANT
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatusCollection_get_Item(nIndex AS STRING) AS VARIANT
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatusCollection_get_Count() AS Number
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatusCollection_Add(pKey AS STRING, pVal AS VARIANT) AS VOID
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatusCollection_Remove(pKey AS STRING) AS VOID
	* add user code here
	ENDPROC

ENDDEFINE && WcStatusCollection_Model

DEFINE CLASS WcStatusInfo_Model AS session && OLEPUBLIC

	IMPLEMENTS ISVNWcStatusInfo IN "PushOkSvn.SVNWcStatusInfo"

	PROCEDURE ISVNWcStatusInfo_put_Files(eValue AS VARIANT @);
 				HELPSTRING "property Files"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatusInfo_get_Files() AS VARIANT;
 				HELPSTRING "property Files"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatusInfo_put_Textual(eValue AS VARIANT @);
 				HELPSTRING "property Textual"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatusInfo_get_Textual() AS VARIANT;
 				HELPSTRING "property Textual"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatusInfo_put_Binary(eValue AS VARIANT @);
 				HELPSTRING "property Binary"
	* add user code here
	ENDPROC

	PROCEDURE ISVNWcStatusInfo_get_Binary() AS VARIANT;
 				HELPSTRING "property Binary"
	* add user code here
	ENDPROC

ENDDEFINE && WcStatusInfo_Model


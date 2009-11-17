* PushOK.h *

#DEFINE SVNAuthProviderAskUser	1	
#DEFINE SVNAuthProviderAskPassword	2	
#DEFINE SVNAuthProviderAskUserAndPassword	3	
#DEFINE SVNAuthProviderAskSslServerTrust	4	
#DEFINE SVNAuthProviderAskSslClientCert	5	
#DEFINE SVNAuthProviderAskSslClientCertPw	6	

#DEFINE SvnNodeKindNone	0	
#DEFINE SvnNodeKindFile	1	
#DEFINE SvnNodeKindDir	2	
#DEFINE SvnNodeKindUnknown	3	

#DEFINE SvnWcScheduleNormal	0	
#DEFINE SvnWcScheduleAdd	1	
#DEFINE SvnWcScheduleDelete	2	
#DEFINE SvnWcScheduleReplace	3	

#DEFINE SvnWcNotifyActionAdd	0	
#DEFINE SvnWcNotifyActionCopy	1	
#DEFINE SvnWcNotifyActionDelete	2	
#DEFINE SvnWcNotifyActionRestore	3	
#DEFINE SvnWcNotifyActionRevert	4	
#DEFINE SvnWcNotifyActionFailedRevert	5	
#DEFINE SvnWcNotifyActionResolved	6	
#DEFINE SvnWcNotifyActionSkip	7	
#DEFINE SvnWcNotifyActionUpdateDelete	8	
#DEFINE SvnWcNotifyActionUpdateAdd	9	
#DEFINE SvnWcNotifyActionUpdateUpdate	10	
#DEFINE SvnWcNotifyActionUpdateCompleted	11	
#DEFINE SvnWcNotifyActionUpdateExternal	12	
#DEFINE SvnWcNotifyActionStatusCompleted	13	
#DEFINE SvnWcNotifyActionstatus_external	14	
#DEFINE SvnWcNotifyActionCommitModified	15	
#DEFINE SvnWcNotifyActionCommitAdded	16	
#DEFINE SvnWcNotifyActionCommitDeleted	17	
#DEFINE SvnWcNotifyActionCommitReplaced	18	
#DEFINE SvnWcNotifyActionCommitPostfixTxdelta	19	
#DEFINE SvnWcNotifyActionBlameRevision	20	
#DEFINE SvnWcNotifyActionLocked	21	
#DEFINE SvnWcNotifyActionUnlocked	22	
#DEFINE SvnWcNotifyActionFailedLock	23	
#DEFINE SvnWcNotifyActionFailedUnlock	24	

#DEFINE SvnWcNotifyStateInapplicable	0	
#DEFINE SvnWcNotifyStateUnknown	1	
#DEFINE SvnWcNotifyStateUnchanged	2	
#DEFINE SvnWcNotifyStateMissing	3	
#DEFINE SvnWcNotifyStateObstructed	4	
#DEFINE SvnWcNotifyStateChanged	5	
#DEFINE SvnWcNotifyStateMerged	6	
#DEFINE SvnWcNotifyStateConflicted	7	

#DEFINE SvnWcNotifyLockStateInapplicable	0	
#DEFINE SvnWcNotifyLockStateUnknown	1	
#DEFINE SvnWcNotifyLockStateUnchanged	2	
#DEFINE SvnWcNotifyLockStateLocked	3	
#DEFINE SvnWcNotifyLockStateUnlocked	4	

#DEFINE SvnWcStatusKindNone	1	
#DEFINE SvnWcStatusKindUnversioned	2	
#DEFINE SvnWcStatusKindNormal	3	
#DEFINE SvnWcStatusKindAdded	4	
#DEFINE SvnWcStatusKindMissing	5	
#DEFINE SvnWcStatusKindDeleted	6	
#DEFINE SvnWcStatusKindReplaced	7	
#DEFINE SvnWcStatusKindModified	8	
#DEFINE SvnWcStatusKindMerged	9	
#DEFINE SvnWcStatusKindConflicted	10	
#DEFINE SvnWcStatusKindIgnored	11	
#DEFINE SvnWcStatusKindObstructed	12	
#DEFINE SvnWcStatusKindExternal	13	
#DEFINE SvnWcStatusKindIncomplete	14	

#DEFINE SvnClientOptionAdmDir	0	
#DEFINE SvnClientOptionAppartReentrantEvents	1	
#DEFINE SvnClientOptionDefUserName	2	
#DEFINE SvnClientOptionDefPassword	3	
#DEFINE SvnClientOptionConfigDir	4	
#DEFINE SvnClientOptionAuthInteractiveOnly	5	
#DEFINE SvnClientOptionAuthNonInteractive	6	

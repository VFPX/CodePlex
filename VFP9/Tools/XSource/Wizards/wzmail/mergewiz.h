*- mergewiz.h

*- help context ID
#DEFINE	N_HELPCONTEXT_ID	1895825418

*- localize these
#DEFINE ALERTTITLE_LOC		"Microsoft Visual FoxPro Wizards"

#DEFINE E_NOMAILMERGE_LOC	"Failed to create MailMerge Object."

*- if these are changed, also change in MAILMRGE.H
*- supported word procs/merge types
#DEFINE		N_WORD60		1
#DEFINE		N_WORD20		3		&& not supported in 5.0
#DEFINE		N_COMMADELIM	2

*- new/old doc
#DEFINE		N_NEW_DOC		1
#DEFINE		N_EXISTING_DOC	2

*- template types
#DEFINE		N_FORMLETTER	1
#DEFINE		N_LABEL			2
#DEFINE		N_ENVELOPE		3
#DEFINE		N_CATALOG		4

******************************************************************************
* Used by GetOS and other methods
******************************************************************************
* Operating System codes
#DEFINE	OS_W32S				1
#DEFINE	OS_NT				2
#DEFINE	OS_WIN95			3
#DEFINE	OS_MAC				4
#DEFINE	OS_DOS				5
#DEFINE	OS_UNIX				6


*- eof MERGEWIZ.H
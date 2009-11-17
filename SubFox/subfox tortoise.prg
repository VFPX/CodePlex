*-- SubFox Tortoise Installer --*
*-- (c) 2008 Holden Data Systems

*--		Examines the active project and then installs Tortoise-hook-scripts
*--		to translate subfox-encoded files regarding this project.

#include SubFox.h
#include WinRegProcs.h

#define COL_TYPE	1
#define COL_PATH	2
#define COL_CMD		3
#define COL_WAIT	4
#define COL_SHOW	5
#define COL_COUNT	5

#define HOOK_BEFORE_COMMIT	"start_commit_hook"
#define HOOK_BEFORE_UPDATE	"start_update_hook"
#define HOOK_AFTER_UPDATE	"post_update_hook"

#define WAIT_YES	"true"
#define WAIT_NO		"false"
#define SHOW_YES	"show"
#define SHOW_NO		"hide"

*-- quick test --*
LOCAL o
* o = NEWOBJECT( "SubFoxTortoiseTools", "SubFox Tortoise.prg" )
o = CREATEOBJECT( "SubFoxTortoiseTools" )
o.InstallHooks()


*******************************************************************************
DEFINE CLASS SubFoxTortoiseTools AS session && OLEPUBLIC
*-- Properties --*
	s_PjxName = "" && file name to "normal" VFP project file "MyProject.pjx"
	s_RootPath = ""
	l_PurgeExtinct = .F.
	o_Util = NULL

*-- Methods --*
FUNCTION Init(sFName AS String) AS Boolean
	SET EXCLUSIVE OFF
	SET DELETED ON
	SET TALK OFF
	SET CENTURY ON
	SET EXACT OFF
	this.o_Util = NEWOBJECT( "SubFoxUtilities", "SubFox Utility Class.prg" )
	Create Cursor Errors (error int, file c(250), message c(250), message1 c(250), program c(250), lineno int)
	Select 0
	IF VARTYPE( sFName ) == 'O'
		LOCAL o
		o = sFName && it's really an object... is a PROJECT object?
		sFName = ""
		IF !ISNULL( o ) AND PEMSTATUS( o, "Name", 5 ) AND FILE( o.Name )
			this.s_PjxName = LOWER( o.Name )
		ENDIF
	ELSE
		IF !EMPTY( sFName ) AND FILE( sFName )
			this.s_PjxName = LOWER( sFName )
		ENDIF
	ENDIF
ENDFUNC && Init
*************************************************************************************
FUNCTION Destroy()
	IF USED( 'Errors' )
		If Reccount("Errors") > 0
			Do form Subfox_Errors
		EndIf
		Use in Errors
	ENDIF
ENDFUNC && Destroy
*************************************************************************************
FUNCTION Error(nError, sMethod, nLine)
	Insert into errors (error, message, message1, program, lineno) ;
				values (nError, Message(), Message(1), sMethod, nLine)
ENDFUNC && Error
*************************************************************************************
*-- Encode happens BEFORE SENDING files to the server AND BEFORE DOWNLOADING UPDATES from the server.
*-- Here we should re-encode updated source files plus deleting ".subfox" files where the source file 
*-- is missing.  We cannot do ADDs here because we don't know which .PJX file to key off of, and because 
*-- Tortoise has a completely separate function to ADD files to the repository.
*******************************************************************************
FUNCTION Encode(sListFName AS String) AS Boolean
	LOCAL sIn, sOut, oTranslator AS SubFoxTranslator OF "SubFox Translation Classes.prg"
	oTranslator = NEWOBJECT( "SubFoxTranslator", "SubFox Translation Classes.prg" )
	IF !this.LoadFileList( sListFName, .T. ) && include subfox files where the original source file is missing
		RETURN .F.
	ENDIF
	SELECT cFile
	SCAN FOR !l_Conflicted
		Try
			sIn = RTRIM( cFile.s_FName )
			IF JUSTEXT( sIn ) == SUBFOX_PRIVATE_EXT
				ERASE (sIn) RECYCLE
			ELSE
				sOut = sIn + "." + SUBFOX_PRIVATE_EXT
				oTranslator.ConvertToText( sIn, sOut )
			EndIf
		Catch to ex
			Insert into errors (error, file, message, message1, program, lineno) values (ex.ErrorNo, sIn, ex.Message, ex.LineContents, ex.Procedure, ex.LineNo)
		EndTry
	ENDSCAN
	USE IN cFile
ENDFUNC && Encode
*************************************************************************************
*--	Decode happens AFTER RECEIVING files from the server.
*--	Here we re-create the original VFP table-based source
*--	files, or the actual DBF tables.
*******************************************************************************
FUNCTION Decode(sListFName AS String) AS Boolean
	LOCAL sIn, sOut, sPath, oTranslator AS SubFoxTranslator OF "SubFox Translation Classes.prg"
	oTranslator = NEWOBJECT( "SubFoxTranslator", "SubFox Translation Classes.prg" )
	IF !this.LoadFileList( sListFName )
		RETURN .F.
	ENDIF
	SELECT cFile
	SCAN FOR !l_Conflicted AND !l_SDT
		try
			sOut = RTRIM( cFile.s_FName )
			sIn = sOut + "." + SUBFOX_PRIVATE_EXT
			oTranslator.RestoreToTable( sIn, sOut )
		Catch to ex
			Insert into errors (error, file, message, message1, program, lineno) values (ex.ErrorNo, sIn, ex.Message, ex.LineContents, ex.Procedure, ex.LineNo)
		EndTry
	ENDSCAN
	*-- now we do the DBCs and SDT files, one folder at a time, calling SDT Up
	SELECT cFile
	LOCATE FOR l_SDT
	DO WHILE !EOF( 'cFile' ) && control break loop
		Try
			s = LOWER( cFile.s_FName)
			SELECT cFile
			i = RECNO('cFile')
			LOCATE FOR cFile.l_Conflicted AND cFile.l_SDT REST WHILE LOWER( cFile.s_FName ) == s
			IF FOUND() && one or more is conflicted
				LOCATE FOR l_SDT AND NOT LOWER( cFile.s_FName ) == s REST
				LOOP
			ENDIF
			GOTO i IN cFile
			SCAN FOR cFile.l_SDT REST WHILE LOWER( cFile.s_FName ) == s
				sOut = RTRIM( cFile.s_FName )
				sIn = sOut + "." + SUBFOX_PRIVATE_EXT
				oTranslator.RestoreToTable( sIn, sOut )
			ENDSCAN
			this.ApplySDTUpdates( s )
		Catch to ex
			Insert into errors (error, file, message, message1, program, lineno) values (ex.ErrorNo, sIn, ex.Message, ex.LineContents, ex.Procedure, ex.LineNo)
		EndTry
	ENDDO
	USE IN cFile
ENDFUNC && Decode
*************************************************************************************
FUNCTION LoadFileList(sListFName AS String, bIncludeMissingFiles AS Boolean) AS Boolean
	LOCAL i,s,a[1], sPath, aPathStack[1], nStackLen
	IF USED( 'cFile' )
		USE IN cFile
	ENDIF
	CREATE CURSOR cFile (s_FName C(MAX_VFP_FLD_LEN), l_Conflicted L, l_SDT L)
		INDEX ON PADR( s_FName, MAX_VFP_IDX_LEN ) TAG s_FName
		SET ORDER TO s_FName
	nStackLen = 0
	ALINES( a, LOWER( FILETOSTR( sListFName ) ) )
	IF _VFP.StartMode == 0 && only testing
		DELETE FILE (sListFName)
	ENDIF
	FOR i = 1 TO ALEN( a )
		IF DIRECTORY( a[i] )
			nStackLen = nStackLen + 1
			DIMENSION aPathStack[nStackLen]
			aPathStack[nStackLen] = a[i]
		ELSE
			this.AddFileToList( a[i], bIncludeMissingFiles )
		ENDIF
	ENDFOR
	DO WHILE nStackLen > 0
		sPath = ADDBS( aPathStack[1] )
		nStackLen = nStackLen - 1
		IF nStackLen == 0
			aPathStack = ""
		ELSE
			ADEL( aPathStack, 1 )
			DIMENSION aPathStack[nStackLen]
		ENDIF
		FOR i = 1 TO ADIR( a, sPath + "*.*", "RHSD" )
			s = sPath + LOWER( a[i,1] )
			IF "D" $ a[i,5]
				IF !INLIST( a[i,1], ".", "..", ".SVN" )
					nStackLen = nStackLen + 1
					DIMENSION aPathStack[nStackLen]
					aPathStack[nStackLen] = s
				ENDIF
			ELSE
				this.AddFileToList( s, bIncludeMissingFiles )
			ENDIF
		ENDFOR
	ENDDO
	IF !this.DiscoverConflicts()
		RETURN .F.
	ENDIF
ENDFUNC && LoadFileList
*************************************************************************************
FUNCTION AddFileToList(sFName AS String, bIncludeMissingFiles AS Boolean) AS VOID
	LOCAL s
	IF JUSTEXT( sFName ) == SUBFOX_PRIVATE_EXT
		s = LEFT( sFName, RAT( ".", sFName ) - 1 )
		IF PADR( JUSTEXT( s ), 4 ) == "vcx-"
			s = FORCEEXT( s, "vcx" )
		ENDIF
		IF FILE(s)
			sFName = s
		ELSE
			IF bIncludeMissingFiles
				INSERT INTO cFile (s_FName) VALUES (sFName)
			ENDIF
			RETURN
		ENDIF
	ENDIF
	IF FILE( sFName ) AND ("," + JUSTEXT( sFName ) + ",") $ ("," + SUBFOX_ENCODEABLE_EXTS + ",")
*--			SEEK( PADR( sFName, MAX_VFP_IDX_LEN ) )
*--			LOCATE FOR s_FName == PADR( sFName, MAX_VFP_FLD_LEN ) ;
*--				REST WHILE PADR( sFName, MAX_VFP_IDX_LEN ) == PADR( s_FName, MAX_VFP_IDX_LEN )
*--			IF !FOUND()
		IF !this.SeekInCFile( sFName )
			s = sFName + "." + SUBFOX_PRIVATE_EXT
			IF !FILE(s) OR this.FDateTime(s) != this.FDateTime(sFName)
				INSERT INTO cFile (s_FName) VALUES (sFName)
			ENDIF
		ENDIF
	ENDIF
ENDFUNC && AddFileToList
*************************************************************************************
FUNCTION ApplySDTUpdates(sPath AS String) AS Boolean
	LOCAL i,s, oDBCX, oSDT, oErr, bResult, sCWD
	*--	sCWD = CURDIR()
	*--	CHDIR (sPath)
*!*		TRY
		oDBCX = NEWOBJECT( "DBCXMgr", "DBCXMgr.vcx", "", .F., sPath )
		IF oDBCX.oSDTMgr.NeedUpdate()
			oDBCX.oSDTMgr.Update()
		ENDIF
		bResult = .T.
*!*		CATCH TO oErr
*!*			bResult = .F.
*!*			MESSAGEBOX( "Error occured within Stonefield Database Toolkit UPDATE function:" + CR ;
*!*					  + TRANSFORM( oErr.ErrorNo ) + ": " + oErr.Message, 16, "Unexpected Error" )
*!*		ENDTRY
	*--	CHDIR (sCWD)
	RETURN bResult
ENDFUNC && ApplySDTUpdates
*************************************************************************************
FUNCTION SeekInCFile(sFName AS String) AS Boolean
	LOCAL bResult
	SELECT cFile
	SET ORDER TO s_FName
	bResult = SEEK( PADR( sFName, MAX_VFP_IDX_LEN ) )
	IF bResult
		LOCATE FOR s_FName == PADR( sFName, MAX_VFP_FLD_LEN ) ;
			REST WHILE PADR( sFName, MAX_VFP_IDX_LEN ) == PADR( s_FName, MAX_VFP_IDX_LEN )
		bResult = FOUND()
		IF !bResult AND !EOF()
			GO BOTTOM
			SKIP
		ENDIF
	ENDIF
	RETURN bResult
ENDFUNC && SeekInCFile
*************************************************************************************
FUNCTION FDateTime(sFName AS String, tDTStamp AS DateTime) AS DateTime
	IF PCOUNT() == 1
		tDTStamp = CTOT( IIF( !FILE( sFName ), "", DTOC( FDATE(sFName) ) + " " + FTIME(sFName) ) )
	ELSE
		this.o_Util.SetDTStamp( sFName, tDTStamp )
	ENDIF
	RETURN tDTStamp
ENDFUNC && FDateTime
*************************************************************************************
FUNCTION DiscoverConflicts() AS Boolean
	LOCAL i,s,o, oErr, sPath, oEvents, oStatus, oClient AS PushOkSvn.SVNClient
	*-- find the root path
	SET TALK OFF
	SELECT cFile
	CALCULATE MIN( JUSTPATH( RTRIM( s_FName ) ) ) TO sPath

	oClient = CreateObject("PushOkSvn.SVNClient" )
*	oEvents = NEWOBJECT( "PushOkSvn_SVNClient_Events", "SVN Event Listener.prg" )
*	EVENTHANDLER( oClient, oEvents )
*	BINDEVENT( oEvents, "WcNotify", this, "onNotify" )
	oClient.InitClient()
	TRY
		oStatus = oClient.GetStatus( sPath, .T., "HEAD", .F. )
		oErr = NULL
	CATCH TO oErr
		LOCAL aErrInfo[1]
		AERROR( aErrInfo )
	ENDTRY
	WAIT CLEAR
*	UNBINDEVENTS( oEvents )
	IF !ISNULL( oErr )
		MESSAGEBOX( "Error accessing local Subversion tracking data:" + CR ;
				  + TRANSFORM( aErrInfo[7] ) + " - " + aErrInfo[3], 16, "Subversion Error" )
		RETURN .F.
	ENDIF
	*-- process results --*
	SELECT cFile
	FOR EACH s IN oStatus.Files
		o = oStatus.Binary.Item(s)
		IF o.TextStatus != SvnWcStatusKindConflicted
			LOOP
		ENDIF
		s = LOWER( STRTRAN( s, "/", "\" ) )
		IF SeekInCFile( s )
			REPLACE l_Conflicted WITH .T. IN cFile && DELETE IN cFile && DO NOT ERASE this file
			LOOP
		ENDIF
		IF JUSTEXT( s ) == SUBFOX_PRIVATE_EXT
			s = LEFT( s, RAT( ".", s ) - 1 )
			IF SeekInCFile( s )
				REPLACE l_Conflicted WITH .T. IN cFile && DELETE IN cFile && DO NOT TOUCH, either to encode or decode
			ENDIF
		ENDIF
	ENDFOR
ENDFUNC && DiscoverConflicts
*******************************************************************************
FUNCTION InstallHooks(sFName AS String) AS Boolean
	LOCAL i,s,o, nCnt, aHooks[1], lAnyChg, cSubfoxTortoiseDir, sAppFName
	IF VARTYPE( sFName ) == 'O'
		o = sFName && it's really an object... is a PROJECT object?
		sFName = ""
		IF !ISNULL( o ) AND PEMSTATUS( o, "Name", 5 ) AND FILE( o.Name )
			this.s_PjxName = LOWER( o.Name )
		ENDIF
	ELSE
		IF !EMPTY( sFName ) AND FILE( sFName )
			this.s_PjxName = LOWER( sFName )
		ENDIF
	ENDIF
	o = NEWOBJECT( "SubFoxProject", "SubFox Project Class.prg" )
	IF !o.Open( this.s_PjxName )
		RETURN .F.
	ENDIF
	this.s_PjxName = o.s_PjxName
	this.s_RootPath = o.s_RootPath
	o = NULL && discard object
	*-- extract list of folders with at least one encoded file
	SELECT s_Path FROM cFile ;
		GROUP BY 1 ORDER BY 1 ;
		WHERE l_Versioned AND l_Encoded ;
		INTO CURSOR cPath
	USE IN cFile
	IF _TALLY == 0 AND !this.l_PurgeExtinct && no hooks need to be installed or un-installed
		USE IN cPath
		RETURN
	ENDIF
	*-- get the "current" list of Tortoise hooks
	SET PROCEDURE TO WinRegProcs ADDITIVE
	s = ReadRegistry( HKEY_CURRENT_USER, "Software\TortoiseSVN", "hooks", "" )
	IF EMPTY( s )
		nCnt = 0
	ELSE
		i = ALINES( aHooks, s, 0, LF )
		nCnt = ROUND( i / COL_COUNT, 0 )
		DIMENSION aHooks[nCnt,COL_COUNT] && restructure as 4 columns
	ENDIF
	CREATE CURSOR cHook (s_Type C(20), s_Path C(MAX_VFP_FLD_LEN), s_Cmd C(MAX_VFP_FLD_LEN), ;
						 l_Wait L, l_Show L)
	FOR i = 1 TO nCnt
		INSERT INTO cHook  (s_Type, s_Path, s_Cmd, l_Wait, l_Show) ;
					VALUES (aHooks[i,COL_TYPE], aHooks[i,COL_PATH], aHooks[i,COL_CMD], ;
							aHooks[i,COL_WAIT] == WAIT_YES, aHooks[i,COL_SHOW] == SHOW_YES)

	ENDFOR
	lAnyChg = .F.
	*Run Subfox from VFP directory to keep system clean
	*** MDH 11/16/09 && cSubfoxTortoiseDir = AddBs(Home(1))
	sAppFName = LOWER( SYS( 16, PROGRAM(-1)-1 ) )
	SELECT cPath
	SCAN ALL
		SELECT cHook
		LOCATE FOR RTRIM( s_Type ) == HOOK_BEFORE_COMMIT AND LOWER( s_Path ) == cPath.s_Path
		IF !FOUND()
			lAnyChg = .T.
			INSERT INTO cHook  (s_Type, s_Path, s_Cmd, l_Wait, l_Show) ;
						VALUES (HOOK_BEFORE_COMMIT, cPath.s_Path, sAppFName + " encode", .T., .F.)
		ENDIF
		LOCATE FOR RTRIM( s_Type ) == HOOK_BEFORE_UPDATE AND LOWER( s_Path ) == cPath.s_Path
		IF !FOUND()
			lAnyChg = .T.
			INSERT INTO cHook  (s_Type, s_Path, s_Cmd, l_Wait, l_Show) ;
						VALUES (HOOK_BEFORE_UPDATE, cPath.s_Path, sAppFName + " encode", .T., .F.)
		ENDIF
		LOCATE FOR RTRIM( s_Type ) == HOOK_AFTER_UPDATE AND LOWER( s_Path ) == cPath.s_Path
		IF !FOUND()
			lAnyChg = .T.
			INSERT INTO cHook  (s_Type, s_Path, s_Cmd, l_Wait, l_Show) ;
						VALUES (HOOK_AFTER_UPDATE, cPath.s_Path, sAppFName + " decode", .T., .F.)
		ENDIF
	ENDSCAN
	IF this.l_PurgeExtinct
		SELECT cHook
		SCAN FOR ADDBS( LOWER( RTRIM( s_Path ) ) ) == ADDBS( LOWER( this.s_RootPath ) )
			SELECT cPath
			LOCATE FOR LOWER( s_Path ) == LOWER( cHook.s_Path )
			IF !FOUND()
				lAnyChg = .T.
				DELETE IN cHook
			ENDIF
		ENDSCAN
	ENDIF
	IF lAnyChg
		SELECT cHook
		INDEX ON PADR( RTRIM( s_Type ) + " " + s_Path, MAX_VFP_IDX_LEN ) TAG s_Type COLLATE "general"
		SET ORDER TO s_Type
		s = ""
		SCAN FOR !DELETED('cHook')
			s = s + RTRIM( s_Type ) + LF + RTRIM( s_Path ) ;
			  + LF + RTRIM( s_Cmd ) + LF + IIF( l_Wait, WAIT_YES, WAIT_NO ) ;
			  + LF + IIF( l_Show, SHOW_YES, SHOW_NO ) + LF
		ENDSCAN
		WriteRegistry( HKEY_CURRENT_USER, "Software\TortoiseSVN", "hooks", s )
	ENDIF
	USE IN cHook
	USE IN cPath
ENDFUNC && InstallHooks
*******************************************************************************
ENDDEFINE && SubFoxTortoiseTools

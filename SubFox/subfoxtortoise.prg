*-- SubFoxTortoise (main) --*

#include SubFox.h
#define COMMAND_ENCODE	"encode"
#define COMMAND_DECODE	"decode"

LPARAMETERS sCmd, sListFName, ;
			z3,z4,z5,z6,z7,z8,z9,z10 && extra params are unused, but if missing generates an error
InstallErrorTrap()
IF _VFP.StartMode == 0 && testing
	If Vartype(sCmd) != "C"
		sCmd = COMMAND_ENCODE
	EndIf
	
	sListFName = ADDBS( SYS(2023) ) + FORCEEXT( SYS(2015), "tmp" )
	STRTOFILE( "C:\temp\trunk" + CRLF, sListFName )
	DEBUG
	SUSPEND
ENDIF
PUBLIC oUtil

oUtil = NEWOBJECT( "SubFoxUtilities", "SubFox Utility Class.prg" )

sCmd = LOWER( ALLTRIM( TRANSFORM( IIF( EMPTY( sCmd ), "", sCmd ) ) ) )
DO CASE
CASE sCmd == COMMAND_ENCODE
	TortoiseEncode( sListFName )
CASE sCmd == COMMAND_DECODE
	TortoiseDecode( sListFName )
OTHERWISE
	MESSAGEBOX( "Invalid command line operation parameter", 16, "Invalid Parameter" )
ENDCASE
IF USED( 'cFile' )
	USE IN cFile
ENDIF

If Reccount("Errors") > 0
	Do form Subfox_Errors
EndIf
Use in Errors
RELEASE oUtil

*************************************************************************************
FUNCTION InstallErrorTrap()
	Create Cursor Errors (error int, file c(250), message c(250), message1 c(250), program c(250), lineno int)
	IF _VFP.StartMode != 0
*		ON ERROR DO ErrorTrap WITH ERROR( ), MESSAGE( ), MESSAGE(1), PROGRAM( ), LINENO( )
		On error Insert into errors (error, message, message1, program, lineno) ;
							 values (Error(), Message(), Message(1), Program(), Lineno())
	EndIf
	Select 0
ENDFUNC && InstallErrorTrap

*************************************************************************************
FUNCTION ErrorTrap(nErrNo, sErrMsg, sCode, sPgm, nLineNo)
	LOCAL oErr, sMsg
	TRY
		TEXT TO m.sMsg TEXTMERGE NOSHOW PRETEXT 2
			An unexpected error has occurred.  Select <Ok> to terminate the program.
			
			ERROR #: <<TRANSFORM(m.nErrNo)>> <<m.sErrMsg>>
			AT LINE <<m.nLineNo>> OF "<<m.sPgm>>"
			COMMAND: <<m.sCode>>
		ENDTEXT
		MESSAGEBOX( m.sMsg, 16, "SubFox Translator Aborted" )
	CATCH TO oErr
		ASSERT .F. MESSAGE PROGRAM()
	ENDTRY
	IF USED( 'cFile' )
		USE IN cFile
	ENDIF
	CANCEL
ENDFUNC && ErrorTrap

*************************************************************************************
*-- Encode happens BEFORE SENDING files to the server AND BEFORE DOWNLOADING UPDATES from the server.
*-- Here we should re-encode updated source files plus deleting ".subfox" files where the source file 
*-- is missing.  We cannot do ADDs here because we don't know which .PJX file to key off of, and because 
*-- Tortoise has a completely separate function to ADD files to the repository.
FUNCTION TortoiseEncode(sListFName AS String)
	LOCAL sIn, sOut, oTranslator AS SubFoxTranslator OF "SubFox Translation Classes.prg"
	oTranslator = NEWOBJECT( "SubFoxTranslator", "SubFox Translation Classes.prg" )

	IF !LoadFileList( sListFName, .T. ) && include subfox files where the original source file is missing
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
ENDFUNC && TortoiseEncode

*************************************************************************************
*--	Decode happens AFTER RECEIVING files from the server.  Here we re-create the original VFP table-based source
*--	files, or the actual DBF tables.
FUNCTION TortoiseDecode(sListFName AS String)
	LOCAL sIn, sOut, sPath, oTranslator AS SubFoxTranslator OF "SubFox Translation Classes.prg"
	oTranslator = NEWOBJECT( "SubFoxTranslator", "SubFox Translation Classes.prg" )
	IF !LoadFileList( sListFName )
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
			ApplySDTUpdates( s )
		Catch to ex
			Insert into errors (error, file, message, message1, program, lineno) values (ex.ErrorNo, sIn, ex.Message, ex.LineContents, ex.Procedure, ex.LineNo)
		EndTry
	ENDDO
	USE IN cFile
ENDFUNC && TortoiseDecode

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
ENDFUNC && 

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
			AddFileToList( a[i], bIncludeMissingFiles )
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
				AddFileToList( s, bIncludeMissingFiles )
			ENDIF
		ENDFOR
	ENDDO
	IF !DiscoverConflicts()
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
		IF !SeekInCFile( sFName )
			s = sFName + "." + SUBFOX_PRIVATE_EXT
			IF !FILE(s) OR FDateTime(s) != FDateTime(sFName)
				INSERT INTO cFile (s_FName) VALUES (sFName)
			ENDIF
		ENDIF
	ENDIF
ENDFUNC && AddFileToList
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
		oUtil.SetDTStamp( sFName, tDTStamp )
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

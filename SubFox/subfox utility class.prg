*-- SubFox Utility Class --*

#include SubFox.h

*-- SetDTStamp declarations
#define OPEN_EXISTING		3
#define FILE_SHARE_READ		0x1
#define FILE_SHARE_WRITE	0x2
#define GENERIC_WRITE		0x40000000

DEFINE CLASS SubFoxUtilities AS custom
	*-- properties --*

*******************************************************************************
FUNCTION SeekInCFile(sFName AS String) AS Boolean
	LOCAL i,b,s,ss
	s = LOWER( JUSTFNAME( sFName ) )
	b = SEEK( PADR(s,MAX_VFP_IDX_LEN), 'cFile', 's_FName' )
	IF b
		i = SELECT(0)
		SELECT cFile
		LOCATE FOR RTRIM( s_Path ) == LOWER( JUSTPATH( sFName ) ) REST WHILE RTRIM( sFName ) == s
		b = FOUND()
		IF !b AND !EOF()
			GO BOTTOM
			IF !EOF()
				SKIP
			ENDIF
		ENDIF
		SELECT (i)
	ENDIF
	RETURN b
ENDFUNC && SeekInCFile
*******************************************************************************
FUNCTION FullPath(sFName AS String, sBasePath AS String) AS String
	LOCAL i, sDrive, sSubPath
	IF (LEN(sFName) >= 3 AND SUBSTR( sFName, 2, 2 ) == ":\") ;
	OR (OCCURS( "\", sFName ) >= 3 AND PADR( sFName, 2 ) == "\\") ;
	OR EMPTY( sBasePath )
		RETURN LOWER( sFName )
	ENDIF
	sBasePath = LOWER( ADDBS( sBasePath ) )
	IF LEN(sBasePath) >= 3 AND SUBSTR( sBasePath, 2, 2 ) == ":\"
		sDrive = LEFT( sBasePath, 3 )
		sSubPath = SUBSTR( sBasePath, 4 )
	ELSE
		IF OCCURS( "\", sBasePath ) >= 4 AND PADR( sBasePath, 2 ) == "\\"
			i = AT( "\", sBasePath, 4 )
			sDrive = LEFT( sBasePath, i )
			sSubPath = SUBSTR( sBasePath, i+1 )
		ELSE
			RETURN LOWER( sFName )
		ENDIF
	ENDIF
	DO WHILE .T.
		IF PADR( sFName, 3 ) == "..\"
			sFName = SUBSTR( sFName, 4 )
			i = RAT( "\", sSubPath, 2 )
			sSubPath = IIF( i == 0, "", LEFT( sSubPath, i ) )
		ELSE
			EXIT
		ENDIF
	ENDDO
	sFName = LOWER( sDrive + sSubPath + sFName )
	sFName = STRTRAN( sFName, "\.\", "\" )
	RETURN sFName
ENDFUNC && FullPath

*******************************************************************************
FUNCTION SetDTStamp(sFName AS String, tDateTime AS Datetime) AS Boolean
	LOCAL hFile, lRet, typFileTime, typLocalTime, typSystemTime
	DECLARE INTEGER CreateFile IN WIN32API ;
		STRING lpFileName, LONG dwDesiredAccess, LONG dwShareMode, LONG lpSecurityAttributes, ;
		LONG dwCreationDisposition, LONG dwFlagsAndAttributes, LONG hTemplateFile
	DECLARE INTEGER LocalFileTimeToFileTime IN WIN32API ;
			STRING lpLocalFileTime, STRING @lpFileTime
	DECLARE INTEGER SetFileTime IN WIN32API ;
		INTEGER hFile, INTEGER NullP, INTEGER NullP2, STRING lpLastWriteTime
	DECLARE INTEGER SystemTimeToFileTime IN WIN32API ;
		STRING lpSystemTime, STRING @lpFileTime
	DECLARE INTEGER CloseHandle IN WIN32API ;
		INTEGER hObject
	typFileTime = this.New_FILETIME()
	typLocalTime = this.New_FILETIME()
	typSystemTime = this.New_SYSTEMTIME( ;
		YEAR(tDateTime), MONTH(tDateTime), DOW(tDateTime) - 1, DAY(tDateTime), ;
		HOUR(tDateTime), MINUTE(tDateTime), SEC(tDateTime) )
	lRet = SystemTimeToFileTime( typSystemTime, @typLocalTime )
	lRet = LocalFileTimeToFileTime( typLocalTime, @typFileTime )
	hFile = CreateFile( sFName, GENERIC_WRITE, BITOR( FILE_SHARE_READ, FILE_SHARE_WRITE ), ;
						0, OPEN_EXISTING, 0, 0 )
	lRet = SetFileTime( hFile, 0, 0, typFileTime )
	CloseHandle( hFile )
	RETURN (lRet > 0)
ENDFUNC && SetDTStamp

*******************************************************************************
HIDDEN FUNCTION New_FILETIME(dwLowDate As Long, dwHighDate As Long) AS String
	RETURN this.LongToStr( dwLowDate ) ;
		 + this.LongToStr( dwHighDate )
ENDFUNC && New_FILETIME

*******************************************************************************
HIDDEN FUNCTION New_SYSTEMTIME(wYear As Integer, wMonth As Integer, wDayOfWeek As Integer, ;
		wDay As Integer, wHour As Integer, wMinute As Integer, wSecond As Integer, ;
		wMillisecs As Integer) AS String
	RETURN this.ShortToStr( wYear ) ;
		 + this.ShortToStr( wMonth ) ;
		 + this.ShortToStr( wDayOfWeek ) ;
		 + this.ShortToStr( wDay ) ;
		 + this.ShortToStr( wHour ) ;
		 + this.ShortToStr( wMinute ) ;
		 + this.ShortToStr( wSecond ) ;
		 + this.ShortToStr( wMillisecs )
ENDFUNC && New_SYSTEMTIME

*******************************************************************************
	* The following function converts a long integer to an ASCII
	* character representation of the passed value in low-high format.
	* Passed: 32-bit non-negative numeric value (nValue)
	* Returns: ascii character representation of passed value in low-high format
HIDDEN FUNCTION LongToStr(nValue AS Number) AS String
	LOCAL i, sResult
	sResult = ""
	nValue = IIF( EMPTY( nValue ), 0, nValue )
	FOR i = 24 TO 0 STEP -8
		sResult = CHR(INT(nValue / (2 ^ i))) + sResult
		nValue = MOD(nValue, (2 ^ i))
	ENDFOR
	RETURN sResult
ENDFUNC && LongToStr

*******************************************************************************
	* The following function converts a long integer to an ASCII
	* character representation of the passed value in low-high format.
	* Passed: 16-bit non-negative numeric value (nValue)
	* Returns: ascii character representation of passed value in low-high format
HIDDEN FUNCTION ShortToStr(nValue AS Number) AS String
	LOCAL i, sResult
	sResult = ""
	nValue = IIF( EMPTY( nValue ), 0, nValue )
	FOR i = 8 TO 0 STEP -8
		sResult = CHR(INT(nValue / (2 ^ i))) + sResult
		nValue = MOD(nValue, (2 ^ i))
	ENDFOR
	RETURN sResult
ENDFUNC && ShortToStr
*******************************************************************************
ENDDEFINE && SubFoxUtilities

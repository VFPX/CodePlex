* WinRegProcs.prg *

#include WinRegProcs.h

LOCAL o,b
SET STEP ON
o = ReadRegistryObject( HKEY_LOCAL_MACHINE, "SOFTWARE\RepliFox" )
b = WriteRegistryObject( HKEY_LOCAL_MACHINE, "SOFTWARE\RepliFox 2", o )
o = null

*--	LOCAL i,a[1]
*--	SET STEP ON
*--	i = GetRegistrySubKeys( HKEY_CURRENT_USER, "Software", @a )
*--	i = i + 0


FUNCTION GetRegistrySubKeys(nHKey, sPath, aResults)
************************************************************************
	LOCAL i,s, nResult, oResult, nRegHandle
	DECLARE INTEGER RegOpenKey IN WIN32API INTEGER nHKey, STRING sPath, INTEGER @nHandle
	DECLARE INTEGER RegCloseKey IN WIN32API INTEGER nHKey
	DECLARE INTEGER RegEnumKey IN WIN32API INTEGER nHKey, INTEGER nSub, STRING @sOutBuffer, INTEGER nLen
	IF TYPE( "ALEN(aResults)" ) == "N"
		oResult = NULL
	ELSE
		RELEASE aResults
		LOCAL aResults[1]
		oResult = CREATEOBJECT( "collection" )
	ENDIF
	nResult = 0
	nHKey = IIF( TYPE( "nHKey" ) == "N", nHKey, HKEY_DEFAULT )
	nRegHandle = 0
	nResult = RegOpenKey( nHKey, sPath, @nRegHandle )
	IF nResult != 0 && Not Found
		RETURN IIF( ISNULL( oResult ), nResult, oResult )
	ENDIF
	FOR i = 0 TO 9999
		s = REPLICATE( CHR(0), 1024 )
		IF RegEnumKey( nRegHandle, i, @s, LEN(s) ) != 0
			EXIT
		ENDIF
		nResult = nResult + 1
		DIMENSION aResults[nResult]
		aResults[nResult] = STRTRAN( s, CHR(0), "" )
	ENDFOR
	RegCloseKey( nRegHandle )
	IF nResult > 1
		ASORT( aResults, 1, nResult, 0, 1 )
	ENDIF
	IF !ISNULL( oResult )
		FOR i = 1 TO nResult
			oResult.Add( aResults[i] )
		ENDFOR
		RETURN oResult
	ENDIF
	RETURN nResult
ENDFUNC && GetRegistrySubKeys

FUNCTION ReadRegistryObject(nHKey, sPath)
************************************************************************
	LOCAL i,s,o, oResult, nRegHandle, nIndex, iNameSize, sName, iValueSize, sValue, eType
	DECLARE INTEGER RegOpenKey IN WIN32API INTEGER nHKey, STRING sPath, INTEGER @nHandle
	DECLARE INTEGER RegCloseKey IN WIN32API INTEGER nHKey
	DECLARE INTEGER RegEnumKey IN WIN32API INTEGER nHKey, INTEGER nSub, STRING @sOutBuffer, INTEGER nLen
	DECLARE INTEGER RegEnumValue IN WIN32API ;
		integer hKey, integer dwIndex, string @lpValueName, integer @lpcValueName, ;
		integer lpReserved, integer @lpType, string @lpData, integer @lpcbData
	nHKey = IIF( TYPE( "nHKey" ) == "N", nHKey, HKEY_DEFAULT )
	nRegHandle = 0
	nResult = RegOpenKey( nHKey, sPath, @nRegHandle )
	IF nResult != 0 && Not Found
		RETURN NULL
	ENDIF
	oResult = CREATEOBJECT( "empty" )
	FOR nIndex = 0 TO 99999
		iNameSize = 1024
		sName = REPLICATE( CHR(0), iNameSize )
		iValueSize = 32 * 1024
		sValue = REPLICATE( CHR(0), iValueSize )
		eType = 0
		i = RegEnumValue( nRegHandle, nIndex, @sName, @iNameSize, 0, @eType, @sValue, @iValueSize )
		IF i == 259 && ERROR_NO_MORE_ITEMS
			EXIT
		ENDIF
		IF i != 0
			oResult = NULL
			s = WinErrNoToText(i)
			ERROR s
			EXIT && RETURN NULL
		ENDIF
		sName = LEFT( sName, MAX(0,iNameSize) )
		DO CASE
		CASE eType == REG_SZ
			sValue = STRTRAN( LEFT( sValue, iValueSize ), CHR(0), "" )
		CASE eType == REG_BINARY
			sValue = LEFT( sValue, iValueSize )
		CASE eType == REG_DWORD
			sValue = LEFT( sValue, iValueSize )
			sValue = BITXOR( CTOBIN( sValue, "4R" ), 0x80000000 ) && reverse switches from LITTLE-ENDIAN
		OTHERWISE
			sName = ""
		ENDCASE
		sName = STRTRAN( ALLTRIM( sName ), " ", "_" )
		IF !EMPTY( sName ) AND !PEMSTATUS( oResult, sName, 5 )
			ADDPROPERTY( oResult, sName, sValue )
		ENDIF
	ENDFOR
	FOR i = 0 TO 9999
		s = REPLICATE( CHR(0), 1024 )
		IF RegEnumKey( nRegHandle, i, @s, LEN(s) ) != 0
			EXIT
		ENDIF
		s = STRTRAN( s, CHR(0), "" )
		o = ReadRegistryObject( nHKey, ADDBS(sPath) + s )
		ADDPROPERTY( oResult, STRTRAN( STRTRAN( s, " ", "_" ), ".", "_" ), o )
	ENDFOR
	RegCloseKey( nRegHandle )
	RETURN oResult
ENDFUNC && ReadRegistryObject


FUNCTION ReadRegistry(nHKey, sPath, sEntry, xDefault)
************************************************************************
	LOCAL pCnt, nRegHandle, nResult, nSize, sBuffer, nType, cResultType, nIntBuffer
	pCnt = PARAMETERS()
	DECLARE INTEGER RegOpenKey IN WIN32API INTEGER nHKey, STRING sPath, INTEGER @nHandle
	DECLARE Integer RegCloseKey IN WIN32API INTEGER nHKey
	nHKey = IIF( TYPE( "nHKey" ) == "N", nHKey, HKEY_DEFAULT )
	xDefault = IIF( pCnt == 4, xDefault, "" )
	cResultType = VARTYPE( xDefault )
	nRegHandle = 0
	nResult = RegOpenKey( nHKey, sPath, @nRegHandle )
	IF nResult != 0 && Not Found
		RETURN xDefault
	ENDIF
	IF cResultType $ "NI" OR (cResultType == "L" AND TYPE('WinReg_CastLogicalAsDWORD') != "U")
		DECLARE INTEGER RegQueryValueEx IN Win32API AS RegQueryInt;
				INTEGER nHKey, STRING sEntry, INTEGER nReserved, ;
				INTEGER @nType, INTEGER @nBuffer, INTEGER @nBufferSize
		nIntBuffer = 0
		nSize = 4 && 32 bits
		lnType = REG_DWORD
		nResult = RegQueryInt( nRegHandle, sEntry, 0, @lnType, @nIntBuffer, @nSize )
		IF nResult == 0 && successful
			RegCloseKey( nRegHandle )
			RETURN IIF( cResultType == "L", (cResultType != 0), nIntBuffer )
		ENDIF
	ENDIF
	DECLARE INTEGER RegQueryValueEx IN Win32API ;
			INTEGER nHKey, STRING sEntry, INTEGER nReserved, ;
			INTEGER @nType, STRING @sBuffer, INTEGER @nBufferSize
	sBuffer = SPACE(512)
	nSize = LEN( sBuffer )
	nType = REG_DWORD
	nResult = RegQueryValueEx( nRegHandle, sEntry, 0, @nType, @sBuffer, @nSize )
	RegCloseKey( nRegHandle )
	IF nResult != 0
	   RETURN xDefault
	ENDIF
	sBuffer = IIF( nSize < 2, "", LEFT( sBuffer, nSize - 1 ) )
	DO CASE
	CASE cResultType $ "CM"
		RETURN sBuffer
	CASE cResultType == "L"
		RETURN IIF( EMPTY( sBuffer ) OR "Y" $ UPPER( sBuffer ) OR "F" $ UPPER( sBuffer ), .F., .T. )
	CASE cResultType == "D"
		RETURN CTOD( sBuffer )
	CASE cResultType == "T"
		RETURN CTOT( sBuffer )
	CASE cResultType $ "NIFY"
		RETURN VAL( sBuffer )
	ENDCASE
	RETURN xDefault
ENDFUNC && ReadRegistryString


FUNCTION DeleteRegistryObject(nHKey, sPath)
************************************************************************
	LOCAL i, nRegHandle, aSubKeys[1]
	DECLARE INTEGER RegOpenKey IN Win32API ;
			INTEGER nHKey, STRING cSubKey, INTEGER @nHandle
	DECLARE Integer RegCloseKey IN Win32API ;
			INTEGER nHKey
	DECLARE Integer RegDeleteKey IN Win32API ;
		INTEGER nHKey, STRING cSubKey
	nHKey = IIF( TYPE( "nHKey" ) == "N", nHKey, HKEY_DEFAULT )
	IF RegOpenKey( nHKey, sPath, @nRegHandle ) != 0
		RETURN && already missing
	ENDIF
	RegCloseKey( nRegHandle )
	FOR i = 1 TO GetRegistrySubKeys( nHKey, sPath, @aSubKeys )
		IF !DeleteRegistryObject( nHKey, ADDBS(sPath) + aSubKeys[i] )
			RETURN .F.
		ENDIF
	ENDFOR
	IF NOT "\" $ sPath
		i = RegDeleteKey( nHKey, sPath ) && just kill it
	ELSE
		i = RegOpenKey( nHKey, JUSTPATH( sPath ), @nRegHandle )
		IF i == 0
			i = RegDeleteKey( nRegHandle, JUSTFNAME( sPath ) )
			RegCloseKey( nRegHandle )
		ENDIF
	ENDIF
	RETURN (i==0)
ENDFUNC && DeleteRegistryObject


FUNCTION WriteRegistryObject(nHKey, sPath, oValues, sProperties, bNoDelete)
************************************************************************
	LOCAL i,ii,s,ss,b,a[1], nRegHandle, nResult, nSize, sBuffer, nType, cResultType, nIntBuffer
	LOCAL aProps[1], nPropCnt, bIgnoreNamedProps
	DECLARE INTEGER RegOpenKey IN Win32API ;
			INTEGER nHKey, STRING cSubKey, INTEGER @nHandle
	DECLARE Integer RegCreateKey IN Win32API ;
			INTEGER nHKey, STRING cSubKey, INTEGER @nHandle
	DECLARE Integer RegCloseKey IN Win32API ;
			INTEGER nHKey
	nHKey = IIF( TYPE( "nHKey" ) == "N", nHKey, HKEY_DEFAULT )
	IF !bNoDelete
		IF !DeleteRegistryObject( nHKey, sPath )
			RETURN .F.
		ENDIF
	ENDIF
	IF EMPTY( sProperties )
		nPropCnt = 0
		bIgnoreNamedProps = .T.
	ELSE
		bIgnoreNamedProps = (PADR( ALLTRIM( sProperties ), 1 ) == "!")
		IF bIgnoreNamedProps
			sProperties = ALLTRIM( STRTRAN( sProperties, "!", "" ) )
		ELSE
			bIgnoreNamedProps = (PADR( UPPER( ALLTRIM( sProperties ) ), 4 ) == "NOT ")
			IF bIgnoreNamedProps
				sProperties = ALLTRIM( STRTRAN( sProperties, "NOT", "", 1, 1, 1 ) )
			ENDIF
		ENDIF
		nPropCnt = ALINES( aProps, sProperties, 5, "," )
	ENDIF
	nResult = RegOpenKey( nHKey, sPath, @nRegHandle )
	IF nResult != 0
		nResult = RegCreateKey( nHKey, sPath, @nRegHandle )
		IF nResult != 0
			RETURN .F.
		ENDIF
	ENDIF
	RegCloseKey( nRegHandle )
	IF AMEMBERS( a, oValues ) == 0
		IF TYPE( "oValues._Properties" ) != "C"
			RETURN
		ENDIF
		ALINES( a, oValues._Properties, .T., "," )
	ENDIF
	FOR i = 1 TO ALEN( a )
		s = a[i]
		IF LOWER(s) == "_properties"
			LOOP
		ENDIF
		ii = IIF( nPropCnt == 0, 0, ASCAN( aProps, s, 1, nPropCnt, 1, 7 ) )
		IF ii > 0 AND !bIgnoreNamedProps
			s = aProps[ii] && use the hand-coded mixed-case
		ENDIF
		IF ii == 0 AND !bIgnoreNamedProps AND nPropCnt > 0 AND TYPE( "oValues." + s ) == "O"
			ii = ASCAN( aProps, s + ".", 1, nPropCnt, 1, 1 ) && search for "SubObj.PropName" disregarding the prop name
		ENDIF
		IF nPropCnt == 0 OR IIF( bIgnoreNamedProps, ii == 0, ii > 0 )
			IF TYPE( "oValues." + s ) != "O"
				WriteRegistry( nHKey, sPath, s, oValues.&s )
			ELSE
				*-- build a targeted property list
				ss = ""
				FOR ii = 1 TO nPropCnt
					IF UPPER( aProps[ii] ) = UPPER(s) + "."
						ss = IIF( EMPTY( ss ), "", ss + "," ) + SUBSTR( aProps[ii], AT( ".", aProps[ii] ) + 1 )
					ENDIF
				ENDFOR
				IF nPropCnt > 0
					ss = IIF( bIgnoreNamedProps, "!", "" ) + ss
				ENDIF
				WriteRegistryObject( nHKey, ADDBS(sPath) + s, oValues.&s, ss, .T. )
			ENDIF
		ENDIF
	ENDFOR
ENDFUNC && WriteRegistryObject


FUNCTION WriteRegistry(nHKey, sPath, sEntry, xValue)
************************************************************************
	LOCAL pCnt, nRegHandle, nResult, nSize, nType, nValue, bDoDelete
	pCnt = PARAMETERS()
	DECLARE INTEGER RegOpenKey IN Win32API ;
			INTEGER nHKey, STRING cSubKey, INTEGER @nHandle
	DECLARE Integer RegCreateKey IN Win32API ;
			INTEGER nHKey, STRING cSubKey, INTEGER @nHandle
	DECLARE Integer RegCloseKey IN Win32API ;
			INTEGER nHKey
	nHKey = IIF( TYPE( "nHKey" ) == "N", nHKey, HKEY_DEFAULT )
	bDoDelete = (pCnt < 4 OR ISNULL( xValue ))
	nRegHandle = 0
	nResult = RegOpenKey( nHKey, sPath, @nRegHandle )
	IF nResult != 0
		IF bDoDelete
			RETURN
		ENDIF
		nResult = RegCreateKey( nHKey, sPath, @nRegHandle )
		IF nResult != 0
			RETURN .F.
		ENDIF
	ENDIF
	IF bDoDelete && indicates the "value" should be DELETED (not the same as storing an empty string)
		DECLARE INTEGER RegDeleteValue IN WIN32API INTEGER nHKEY, STRING sEntry
		nResult = RegDeleteValue( nRegHandle, sEntry )
		RegCloseKey( nRegHandle )
		RETURN
	ENDIF
	IF VARTYPE( xValue ) $ 'NI' OR (VARTYPE( xValue ) == "L" AND TYPE( 'WinReg_CastLogicalAsDWORD' ) != "U")
		DECLARE INTEGER RegSetValueEx IN Win32API ;
			INTEGER nHKey, STRING lpszEntry, INTEGER dwReserved, ;
			INTEGER fdwType, INTEGER @lpbData, INTEGER cbData
		nSize = 4
		nValue = IIF( VARTYPE( xValue ) == "L", IIF( xValue, 1, 0 ), ROUND( xValue, 0 ) ) && force into integer format
		nResult = RegSetValueEx( nRegHandle, sEntry, 0, REG_DWORD, @nValue, nSize )
	ELSE
		DECLARE INTEGER RegSetValueEx IN Win32API ;
			INTEGER nHKey, STRING sEntry, INTEGER nReserved, ;
			INTEGER nType, STRING sBuffer, INTEGER nBufferSize
		DO CASE
		CASE VARTYPE( xValue ) == "L"
			xValue = IIF( xValue, "Y", "N" )
		CASE VARTYPE( xValue ) != "C"
			xValue = TRANSFORM( xValue )
		ENDCASE
		nSize = LEN( xValue )
		IF nSize == 0
			xValue = CHR(0)
		ENDIF
		nResult = RegSetValueEx( nRegHandle, sEntry, 0, REG_SZ, xValue, nSize )
	ENDIF
	RegCloseKey( nRegHandle )
	RETURN (nResult == 0)
ENDPROC && WriteRegistryString


FUNCTION WinErrNoToText(nWindowsErrorNo AS Integer) AS String
************************************************************************
	DECLARE integer FormatMessage IN WIN32API integer, integer, integer, integer, integer @, integer, integer
	DECLARE RtlMoveMemory IN WIN32API string @, integer, integer
	LOCAL i,s,x
	x = 0
	i = FormatMessage( 0x1300, 0, nWindowsErrorNo, 0, @x, 0, 0 )
	IF i <= 0
		RETURN "Unknown Error #" + TRANSFORM( nWindowsErrorNo ) + " (" + TRANSFORM( nWindowsErrorNo, "@0" ) + ")"
	ENDIF
	s = REPLICATE( CHR(0), i )
	RtlMoveMemory( @s, xBuff, i )
	s = STRTRAN( LEFT( s, i ), CHR(13) + CHR(10), " " )
	RETURN ALLTRIM( s )
ENDFUNC && WinErrNoToText

FUNCTION LongToStr(n)
	RETURN BINTOC( BITXOR( 0x80000000, n ), "4R" ) && reverse switches to LITTLE-ENDIAN
ENDFUNC && LongToStr

FUNCTION StrToLong(s)
	RETURN BITXOR( CTOBIN( s, "4R" ), 0x80000000 ) && reverse switches from LITTLE-ENDIAN
ENDFUNC && StrToLong

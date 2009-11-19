*-- SubFox Translation Classes --*
*-- (c) 2008 Holden Data Systems

*--		Translate VFP binary files to/from text format
*--		Parms are two file names, first INPUT, second OUTPUT
*--		Only one filename, either in or out, should be a VFP file

#include SubFox.h
#include WinRegProcs.h

*******************************************************************************
DEFINE CLASS SubFoxTranslator AS ErrorHandler && OLEPUBLIC
	*-- Properties --*
	o_Util = NULL

FUNCTION Init()
	this.o_Util = NEWOBJECT( "SubFoxUtilities", "SubFox Utility Class.prg" )
ENDFUNC && Init
*******************************************************************************
FUNCTION ConvertFile(sInFName AS STRING, sOutFName AS STRING) AS VOID
	LOCAL i,sExt, sVFPExts
	sVFPExts = "DBC,DBF,FRX,LBX,MNX,PJX,SCX,VCX"
	sVFPExts = "," + UPPER( STRTRAN( sVFPExts, " ", "" ) ) + ","
	i = RAT( ".", sInFName )
	sExt = IIF( i == 0, "", UPPER( ALLTRIM( SUBSTR( sInFName, i+1 ) ) ) )
	IF (","+sExt+",") $ sVFPExts
		this.ConvertToText( sInFName, sOutFName )
	ELSE
		i = RAT( ".", sOutFName )
		sExt = IIF( i == 0, "", UPPER( ALLTRIM( SUBSTR( sOutFName, i+1 ) ) ) )
		IF (","+sExt+",") $ sVFPExts
			this.RestoreToTable( sInFName, sOutFName )
		ELSE
			IF FILE( sOutFName )
				DELETE FILE (sOutFName)
			ENDIF
			IF FILE( sInFName )
				COPY FILE (sInFName) TO (sOutFName)
			ENDIF
		ENDIF
	ENDIF
ENDFUNC && ConvertFile
*******************************************************************************
FUNCTION ConvertToText(sInFName AS STRING, sOutFName AS STRING) AS VOID
	LOCAL o
	o = this.CreateConverter( sInFName )
	o.ConvertToText( sInFName, sOutFName )
ENDFUNC
*******************************************************************************
FUNCTION RestoreToTable(sInFName AS STRING, sOutFName AS STRING) AS VOID
	LOCAL o
	o = this.CreateConverter( sOutFName )
	o.RestoreToTable( sInFName, sOutFName )
ENDFUNC && RestoreToTable
*******************************************************************************
FUNCTION CreateConverter(sFName AS STRING) AS Object
	LOCAL i,o, sExt, sClass
	i = RAT( ".", sFName )
	sExt = IIF( i == 0, "", UPPER( ALLTRIM( SUBSTR( sFName, i+1 ) ) ) )
	DO CASE
	CASE sExt == "SCX"
		sClass = "FormConverter"
	CASE sExt == "VCX"
		sClass = "ClasslibConverter"
	CASE sExt == "PJX"
		sClass = "ProjectConverter"
	CASE sExt == "FRX"
		sClass = "ReportConverter"
	CASE sExt == "LBX"
		sClass = "LabelConverter"
	CASE sExt == "MNX"
		sClass = "MenuConverter"
	CASE sExt == "DBC"
		sClass = "DBContainerConverter"
	CASE sExt == "DBF"
		sClass = "DBF_Converter"
	OTHERWISE
		sClass = "TableConverter"
	ENDCASE
	RETURN CREATEOBJECT( sClass )
ENDFUNC && CreateConverter
*******************************************************************************
FUNCTION FDateTime(sFName AS String, tDTStamp AS DateTime) AS DateTime
	IF PCOUNT() == 1
		tDTStamp = CTOT( IIF( !FILE( sFName ), "", DTOC( FDATE(sFName) ) + " " + FTIME(sFName) ) )
	ELSE
		this.o_Util.SetDTStamp( sFName, tDTStamp )
	ENDIF
	RETURN tDTStamp
ENDFUNC && FDateTime
ENDDEFINE && SubFoxTranslator


*******************************************************************************
DEFINE CLASS TableConverter AS ErrorHandler
*-- generic converter BASE-CLASS
	* properties *
	o_Util = NULL
	s_Output = ""
	s_BinToNullMatrix = ""
	s_Input = ""
	s_InFName = ""
	s_OutFName = ""
	t_InputDTStamp = CTOT("")

*******************************************************************************
FUNCTION Init()
	LOCAL i,s, byte
	DODEFAULT()
	this.o_Util = NEWOBJECT( "SubFoxUtilities", "SubFox Utility Class.prg" )
	s = ""
	FOR i = 1 TO 255
		s = s + CHR(i)
	ENDFOR
	byte = CHR(255)
	s = STUFF( s, 1, 8, REPLICATE( byte, 8 ) )
	s = STUFF( s, 11, 2, REPLICATE( byte, 2 ) )
	s = STUFF( s, 14, 18, REPLICATE( byte, 18 ) )
	s = STUFF( s, 128, 129, REPLICATE( byte, 129 ) )
	this.s_BinToNullMatrix = s
ENDFUNC && Init
*******************************************************************************
FUNCTION ConvertToText(sInFName AS STRING, sOutFName AS STRING) AS VOID
	LOCAL i,s,ss, oRec, oBlank, aIsMemo[1]
	this.s_InFName = sInFName
	this.s_OutFName = sOutFName
	this.t_InputDTStamp = this.FDateTime( sInFName )
	IF USED( 'cInput' )
		USE IN cInput
	ENDIF

	USE (sInFName) AGAIN In 0 SHARED ALIAS cInput NOUPDATE
	
	IF !USED( 'cInput' )
		*ERROR "Unable to open input file"
		RETURN
	ENDIF
	this.s_Output = "SubFox" + CRLF
	this.CaptureTableFormat()
	this.SortInputCursor()
	SELECT cInput
	SCATTER NAME oBlank MEMO BLANK
	this.SetDefaultValues( oBlank )

	DIMENSION aIsMemo[FCOUNT('cInput')]
	FOR i = 1 TO FCOUNT('cInput')
		aIsMemo[i] = (TYPE( 'cInput.' + FIELD(i,'cInput') ) == "M")
	ENDFOR

	SELECT cInput
	SET DELETED ON
	SCAN
		this.s_Output = this.s_Output + "*rec*" + CRLF
		SCATTER NAME oRec MEMO
		this.CleanObjAfterRead( oRec )
		FOR i = 1 TO FCOUNT('cInput')
			s = FIELD(i,'cInput')
			DO CASE
			CASE this.IgnoreField(s)
				* LOOP
			CASE TYPE( 'cInput.' + s ) == "G" && general fields are weird
*--					IF !EMPTY( cInput.&s )
*--						ss = ADDBS( SYS(2023) ) + SYS(2015)
*--						SELECT cInput
*--						COPY MEMO &s TO (ss)
*--						IF FILE(ss)
*--							this.s_Output = this.s_Output + s + "-BASE64=" ;
*--								+ STRCONV( FILETOSTR(ss), 13 ) + CRLF
*--							DELETE FILE (ss)
*--						ENDIF
*--					ENDIF
			CASE TYPE( 'cInput.' + s ) != "G" AND oRec.&s == oBlank.&s
				* LOOP
			CASE aIsMemo[i] AND this.IsBinary( s, oRec.&s )
				this.s_Output = this.s_Output + s + "-BASE64=" + STRCONV( oRec.&s, 13 ) + CRLF
			CASE aIsMemo[i] AND AT( CHR(13), oRec.&s ) == 0
				*-- sometimes an initial but meaningless NULL byte is in pos #1
				oRec.&s = this.CleanupMemo( s, oRec.&s )
				this.s_Output = this.s_Output + s + "=" + RTRIM( oRec.&s ) + CRLF
			CASE aIsMemo[i]
				oRec.&s = this.CleanupMemo( s, oRec.&s )
				this.s_Output = this.s_Output + s + "-FREETEXT=" + CRLF + CHR(9) + STRTRAN( oRec.&s, CRLF, CRLF + CHR(9) ) + CRLF
			OTHERWISE
				this.s_Output = this.s_Output + s + "=" + RTRIM( STRTRAN( TRANSFORM( oRec.&s ), CHR(0), "" ) ) + CRLF
			ENDCASE
		ENDFOR
	ENDSCAN
	USE IN cInput
	IF !FILE( sOutFName ) OR NOT FILETOSTR( sOutFName ) == this.s_Output
		IF FILE( sOutFName )
			DELETE FILE (sOutFName)
		ENDIF
		STRTOFILE( this.s_Output, sOutFName )
	ENDIF
	this.FDateTime( sOutFName, this.t_InputDTStamp )
ENDFUNC && ConvertToText
*******************************************************************************
FUNCTION CaptureTableFormat()
	LOCAL i,s,ss,a[1]
	s = CURSORGETPROP( "Database", "cInput" )
	IF !EMPTY( s )
		SET DATABASE TO (s)
		s = DBC()
		s = SYS( 2014, s, JUSTPATH( DBF( "cInput" ) ) )
		this.s_Output = this.s_Output + "Database: " + LOWER( s ) + CRLF
	ENDIF
	FOR i = 1 TO AFIELDS( a, 'cInput' )
		s = IIF( i == 1, "", s + ", " ) + a[i,1] + " " + a[i,2] ;
		  + IIF( a[i,2] == "C", "(" + TRANSFORM( a[i,3] ) + ")", ;
				 IIF( a[i,2] != "N", "", "(" + TRANSFORM( a[i,3] ) ;
					+ IIF( a[i,4] == 0, "", "," + TRANSFORM( a[i,4] ) ) + ")" ) )
	ENDFOR
	this.s_Output = this.s_Output + "Format: " + s + CRLF
	*-- capture INDEXES too
	IF JUSTEXT( DBF( 'cInput' ) ) != "PJX" && projects don't have indexes (but they do??)
		FOR i = 1 TO ATAGINFO( a, "", 'cInput' )
			this.s_Output = this.s_Output + "Index on " + a[i,3] + " TAG " + a[i,1] ;
				+ IIF( a[i,6] == "MACHINE", "", " COLLATE '" + a[i,6] + "'" ) ;
				+ IIF( a[i,5] == "ASCENDING", "", " " + a[i,5] ) ;
				+ IIF( EMPTY( a[i,4] ), "", " FOR " + a[i,4] ) ;
				+ IIF( a[i,2] == "REGULAR", "", " " + a[i,2] ) ;
				+ " ADDITIVE" + CRLF
		ENDFOR
	ENDIF
ENDFUNC && CaptureTableFormat
*-- Hooks --*
*******************************************************************************
	FUNCTION SortInputCursor()
	ENDFUNC && SortInputCursor
	*******************************************************************************
	FUNCTION CleanObjAfterRead(oRec)
	ENDFUNC && CleanObjAfterRead
	*******************************************************************************
	FUNCTION SetDefaultValues(oRec AS Object)
	ENDFUNC && SetDefaultValues
	*******************************************************************************
	FUNCTION IgnoreField(sName)
		RETURN .F. && hook
	ENDFUNC && IgnoreField
	*******************************************************************************
	FUNCTION CleanupMemo(sName,sValue)
		DO WHILE .T.
			IF (" " + CRLF) $ sValue
				sValue = STRTRAN( sValue, " " + CRLF, CRLF )
			ELSE
				IF (CHR(9) + CRLF) $ sValue
					sValue = STRTRAN( sValue, CHR(9) + CRLF, CRLF )
				ELSE
					EXIT
				ENDIF
			ENDIF
		ENDDO
		RETURN sValue && hooks should call sValue = DODEFAULT(sName,sValue)
	ENDFUNC && CleanupMemo
	*******************************************************************************
	FUNCTION IsBinary(sName,sValue)
		IF ATC( CHR(0), sValue, 1 ) == 1 AND ATC( CHR(0), sValue, 2 ) == 0
			RETURN .F.
		ENDIF
		IF ATC( CHR(0), sValue ) == 0 AND ATC( CHR(255), sValue ) == 0 ;
		AND ATC( CHR(255), SYS( 15, this.s_BinToNullMatrix, sValue ) ) == 0
			RETURN .F.
		ENDIF
		RETURN .T.
	ENDFUNC && IsBinary

*******************************************************************************
FUNCTION RestoreToTable(sInFName AS STRING, sOutFName AS STRING) AS VOID
	this.s_InFName = sInFName
	this.s_OutFName = sOutFName
	this.t_InputDTStamp = this.FDateTime( sInFName )
	IF !FILE( sInFName )
		ERROR 'Non-Existent input file "' + sInFName + '"'
		RETURN
	ENDIF
	this.s_Input = FILETOSTR( sInFName )
	IF !this.ReadHeader( sOutFName )
		RETURN
	ENDIF
	DO WHILE LEN( this.s_Input ) > 0
		IF !this.WriteOneTableRecord()
			USE IN cOutput
			this.DeleteBeforeOverwrite( sOutFName ) && discard output thus far
			EXIT
		ENDIF
	ENDDO
	USE IN cOutput
	DO CASE
	CASE UPPER( JUSTEXT( sOutFName ) ) == "SCX"
		COMPILE FORM (sOutFName)
	CASE UPPER( JUSTEXT( sOutFName ) ) == "VCX"
		COMPILE CLASSLIB (sOutFName)
	CASE UPPER( JUSTEXT( sOutFName ) ) == "FRX"
		COMPILE REPORT (sOutFName)
	CASE UPPER( JUSTEXT( sOutFName ) ) == "LBX"
		COMPILE LABEL (sOutFName)
	CASE UPPER( JUSTEXT( sOutFName ) ) == "DBC"
		COMPILE DATABASE (sOutFName)
	ENDCASE
	this.SetTableDTStamps()
ENDFUNC && RestoreToTable
*******************************************************************************
FUNCTION SetTableDTStamps()
	LOCAL i,s,a[1]
	FOR i = 1 TO ALINES( a, this.GetTableExts(), .T., "," )
		s = FORCEEXT( this.s_OutFName, a[i] )
		IF FILE( s )
			this.FDateTime( s, this.t_InputDTStamp )
		ENDIF
	ENDFOR
ENDFUNC && SetTableDTStamps
*******************************************************************************
FUNCTION GetTableExts() AS String
	LOCAL s
	s = LOWER( JUSTEXT( this.s_OutFName ) )
	DO CASE
	CASE s == "dbc"
		RETURN "dbc,dcx,dct"
	CASE s == "dbf"
		RETURN "dbf,cdx,fpt"
	ENDCASE
	RETURN s + "," + STUFF( s, 3, 1, "t" )
ENDFUNC && GetTableExts
*******************************************************************************
FUNCTION ReadHeader(sOutFName)
	LOCAL i,s, a[1], sDBC
	s = this.NextInputRecordset()
	IF ALINES( a, s, 4, CRLF ) < 2 OR NOT a[1] == "SubFox"
		ERROR "Input file is not a properly formatted SubFox file"
		RETURN
	ENDIF
	IF PADR( a[2], 10 ) != "Database: "
		sDBC = ""
	ELSE
		sDBC = ALLTRIM( SUBSTR( a[2], 10 ) )
		ADEL( a, 2 )
		DIMENSION a[ALEN(a)-1]
	ENDIF
	IF NOT PADR( a[2], 8 ) == "Format: "
		ERROR "Input file is not a properly formatted SubFox file"
		RETURN
	ENDIF
	this.DeleteBeforeOverwrite( sOutFName )
	SELECT 0
	s = ALLTRIM( SUBSTR( a[2], AT( ":", a[2] ) + 1 ) )
	IF ALEN( a ) == 2
		IF !this.CreateOutputTable( sOutFName, s, sDBC )
			RETURN .F.
		ENDIF
	ELSE
		ADEL(a,1)
		ADEL(a,1)
		DIMENSION a[ALEN(a)-2]
		IF !this.CreateOutputTable( sOutFName, s, sDBC, @a )
			RETURN .F.
		ENDIF
	ENDIF
	USE (sOutFName) IN 0 EXCLUSIVE ALIAS cOutput
ENDFUNC && ReadHeader
*******************************************************************************
FUNCTION CreateOutputTable(sFName,sFormat,sDBC, aIdxs)
	IF EMPTY( sDBC )
		CREATE TABLE (sFName) FREE (&sFormat)
	ELSE
		sDBC = this.FullPath( sDBC, JUSTPATH( sFName ) )
		IF !DBUSED( sDBC )
			OPEN DATABASE (sDBC) SHARED
			IF !DBUSED( sDBC )
				RETURN .F.
			ENDIF
		ENDIF
		SET DATABASE TO (sDBC)
		CREATE TABLE (sFName) (&sFormat)
	ENDIF
	IF PCOUNT() == 4
		EXTERNAL ARRAY aIdxs
		FOR i = 1 TO ALEN(aIdxs) && create indexes
			EXECSCRIPT( aIdxs[i] )
		ENDFOR
	ENDIF
	USE && close unknown alias
ENDFUNC && CreateOutputTable
*******************************************************************************
FUNCTION DeleteBeforeOverwrite(sOutFName)
	LOCAL s
	IF FILE( sOutFName )
		DELETE FILE (sOutFName)
	ENDIF
	s = LOWER( JUSTEXT(sOutFName) )
	DO CASE
	CASE s == "dbf"
		IF FILE( FORCEEXT( sOutFName, "FPT" ) )
			DELETE FILE (FORCEEXT( sOutFName, "FPT" ))
		ENDIF
		IF FILE( FORCEEXT( sOutFName, "CDX" ) )
			DELETE FILE (FORCEEXT( sOutFName, "CDX" ))
		ENDIF
	CASE s == "dbc"
		IF FILE( FORCEEXT( sOutFName, "DCX" ) )
			DELETE FILE (FORCEEXT( sOutFName, "DCX" ))
		ENDIF
		IF FILE( FORCEEXT( sOutFName, "DCT" ) )
			DELETE FILE (FORCEEXT( sOutFName, "DCT" ))
		ENDIF
	OTHERWISE
		s = STUFF( s, 3, 1, "t" )
		IF FILE( FORCEEXT( sOutFName, s ) )
			DELETE FILE (FORCEEXT( sOutFName, s ))
		ENDIF
	ENDCASE
ENDFUNC && DeleteBeforeOverwrite
*******************************************************************************
FUNCTION WriteOneTableRecord()
	LOCAL i,s,o, sRecSet, sPropName, sFormat
	SELECT cOutput
	SCATTER MEMO BLANK NAME o
	this.SetDefaultValues( o )
	sRecSet = this.NextInputRecordset()
	DO WHILE LEN( sRecSet ) > 0
		i = AT( CRLF, sRecSet )
		s = IIF( i == 0, sRecSet, LEFT( sRecSet, i-1 ) )
		sRecSet = IIF( i == 0, "", SUBSTR( sRecSet, i+2 ) )
		i = AT( "=", s )
		IF i == 0
			ERROR "Property/Value pair missing equal sign.  Conversion aborted"
			RETURN .F.
		ENDIF
		sPropName = LEFT( s, i-1 )
		s = SUBSTR( s, i+1 )
		i = AT( "-", sPropName )
		sFormat = IIF( i == 0, "", UPPER( SUBSTR( sPropName, i+1 ) ) )
		sPropName = IIF( i == 0, sPropName, LEFT( sPropName, i-1 ) )
		IF !PEMSTATUS( o, sPropName, 5 )
			ERROR "Property for unknown data field.  Conversion aborted."
			RETURN .F.
		ENDIF
		DO CASE
		CASE EMPTY( sFormat )
			o.&sPropName = this.ConvToType( s, TYPE( "cOutput." + sPropName ) )
		CASE sFormat == "BASE64"
			IF PEMSTATUS( o, sPropName, 5 )
				o.&sPropName = STRCONV( s, 14 )
			ELSE
				*-- general fields are weird
			ENDIF
		CASE sFormat == "FREETEXT"
			s = ""
			DO WHILE LEN( sRecSet ) > 0 AND LEFT( sRecSet, 1 ) == CHR(9)
				i = AT( CRLF, sRecSet )
				s = s + IIF( i == 0, SUBSTR( sRecSet, 2 ), SUBSTR( sRecSet, 2, i ) )
				sRecSet = IIF( i == 0, "", SUBSTR( sRecSet, i+2 ) )
			ENDDO
			IF LEN(s) >= 4 AND RIGHT(s,4) == CRLF + CRLF
				s = LEFT( s, LEN(s) - 2 )
			ENDIF
			IF sPropName == "PROPERTIES"
				s = STRTRAN( s, "=" + CRLF, "= " + CRLF )
			ENDIF
			o.&sPropName = s
		ENDCASE
	ENDDO
	this.DirtyUpObjBeforeWrite( o )
	INSERT INTO cOutput FROM NAME o
ENDFUNC && WriteOneTableRecord
*******************************************************************************
FUNCTION NextInputRecordset()
	LOCAL i,s
	i = AT( CRLF + "*rec*" + CRLF, CRLF + this.s_Input )
	s = IIF( i == 0, this.s_Input, LEFT( this.s_Input, i-1 ) )
	this.s_Input = IIF( i == 0, "", SUBSTR( this.s_Input, i + 7 ) )
	RETURN s
ENDFUNC && NextInputRecordset
*******************************************************************************
FUNCTION ConvToType(sText,eType)
	DO CASE
	CASE eType $ "CMG"
		RETURN sText
	CASE eType == "D"
		RETURN CTOD(sText)
	CASE eType == "T"
		RETURN CTOT(sText)
	OTHERWISE && CASE eType $ "LNIYF"
		RETURN &sText
	ENDCASE
ENDFUNC && ConvToType
*******************************************************************************
FUNCTION FullPath(sFName AS String, sBasePath AS String) AS String
	RETURN this.o_Util.FullPath( sFName, sBasePath )
ENDFUNC && FullPath
*-- Hooks --*
*******************************************************************************
	FUNCTION DirtyUpObjBeforeWrite(oRec)
	ENDFUNC && DirtyUpObjBeforeWrite

*-- Utility Procs --*
*******************************************************************************
* SortProcsInMemo: general resource available to sub-classed derivitives
* accepts input MEMO of generic PRG logic in FUNCTION foo or PROCEDURE foo format
* returns same value but SORTED by func and/or proc name order. INLINE logic before
* first proc is retained.  Case insensitive sort.  
*
* NOTE: Proc and Func declaration MUST NOT BE INDENTED!!!
FUNCTION SortProcsInMemo(sValue)
	LOCAL i,ii, sPrefix, sName, sBody, lNextIsFunc
	CREATE CURSOR cProcSort (s_Name C(100), m_Code M)
	INDEX ON s_Name TAG s_Name COLLATE "General"
	i = ATC( CRLF + "PROCEDURE ", CRLF + sValue )
	ii = ATC( CRLF + "FUNCTION ", CRLF + sValue )
	IF i == 0 AND ii == 0 && Nothing to sort
		RETURN sValue
	ENDIF
	IF i == 0
		lNextIsFunc = .T.
		i = ii
	ELSE
		IF ii == 0
			lNextIsFunc = .F.
		ELSE
			lNextIsFunc = (ii < i)
			i = MIN(i,ii)
		ENDIF
	ENDIF
	sPrefix = LEFT( sValue, i-1 )
	sValue = SUBSTR( sValue, i )
	DO WHILE LEN(sValue) > 0
		i = ATC( CRLF + "PROCEDURE ", CRLF + sValue, IIF( lNextIsFunc, 1, 2 ) )
		ii = ATC( CRLF + "FUNCTION ", CRLF + sValue, IIF( lNextIsFunc, 2, 1 ) )
		IF i == 0
			lNextIsFunc = .T.
			i = ii
		ELSE
			IF ii == 0
				lNextIsFunc = .F.
			ELSE
				lNextIsFunc = (ii < i)
				i = MIN(i,ii)
			ENDIF
		ENDIF
		sBody = IIF( i == 0, sValue, LEFT( sValue, i-1 ) )
		sValue = IIF( i == 0, "", SUBSTR( sValue, i ) )
		i = AT( CRLF, sBody )
		sName = IIF( i == 0, sBody, LEFT( sBody, i-1 ) )
		sName = ALLTRIM( SUBSTR( sName + " ", AT( " ", sName ) + 1 ) )
		INSERT INTO cProcSort (s_Name,m_Code) VALUES (PADR(sName,100),sBody)
	ENDDO
	SELECT cProcSort
	SET ORDER TO s_Name
	sValue = sPrefix
	SCAN
		sValue = sValue + cProcSort.m_Code
	ENDSCAN
	USE IN cProcSort
	RETURN sValue
ENDFUNC && SortProcsInMemo
*******************************************************************************
* SortPropertiesInMemo: general resource available to sub-classed derivitives
* accepts input MEMO of single-line declaratives like NAME="FOO"
* Returns same value but SORTED. Text appearing after the final CRLF is retained.
* Case insensitive sort.
* (BTW... discovered this BREAKS forms.  Not in use)
FUNCTION SortPropertiesInMemo(sValue)
	LOCAL i,ii,s, nSub, sTail
	IF !BETWEEN( ATC( CRLF, sValue ), 1, LEN(sValue) - 1 )
		RETURN sValue
	ENDIF
	CREATE CURSOR cPropSort (s_Sample C(100), m_Code M)
	INDEX ON s_Sample TAG s_Sample COLLATE "General"
	i = RAT( CRLF, sValue )
	sTail = IIF( i == LEN(sValue)-1, "", SUBSTR( sValue, i+2 ) )
	i = 1
	FOR nSub = 1 TO OCCURS( CRLF, sValue )
		ii = AT( CRLF, sValue, nSub )
		s = SUBSTR( sValue, i, ii-i )
		i = ii+2
		INSERT INTO cPropSort (s_Sample, m_Code) VALUES (PADR(s,100),s)
	ENDFOR
	sValue = ""
	SELECT cPropSort
	SCAN
		sValue = sValue + cPropSort.m_Code + CRLF
	ENDSCAN
	sValue = sValue + sTail
	USE IN cPropSort
	RETURN sValue
ENDFUNC && SortPropertiesInMemo
*******************************************************************************
FUNCTION FDateTime(sFName AS String, tDTStamp AS DateTime) AS DateTime
	IF PCOUNT() == 1
		tDTStamp = CTOT( IIF( !FILE( sFName ), "", DTOC( FDATE(sFName) ) + " " + FTIME(sFName) ) )
	ELSE
		this.o_Util.SetDTStamp( sFName, tDTStamp )
	ENDIF
	RETURN tDTStamp
ENDFUNC && FDateTime
*******************************************************************************
ENDDEFINE && TableConverter

*******************************************************************************
* Sub Classes - installs distinct logic for each table type via HOOKS
*******************************************************************************

DEFINE CLASS DBF_Converter AS TableConverter
FUNCTION DeleteBeforeOverwrite(sOutFName)
	LOCAL s,i,h, sDBC, lPreUsed
	*-- if contained within a DBC, must notify the DBC that it is going bye-bye
	IF !FILE( sOutFName )
		RETURN DODEFAULT(sOutFName)
	ENDIF
	*-- determine if the table is in a DBC
	h = FOPEN( sOutFName, 10 ) && open as a low-level file
	IF h < 0 && could not be opened in read-only mode!!!
		RETURN DODEFAULT(sOutFName)
	ENDIF
	IF FSEEK( h, 28, 0 ) != 28 && not a real DBF
		FCLOSE(h)
		RETURN DODEFAULT(sOutFName)
	ENDIF
	i = ASC( FREAD(h,1) )
	IF !BITTEST( i, 2 ) && table is NOT in a DBC
		FCLOSE(h)
		RETURN DODEFAULT(sOutFName)
	ENDIF
	*-- loop thru field info until an end-of-list indicator is found
	sDBC = ""
	FOR i = 1 TO 256
		FSEEK( h, i * 32, 0 )
		IF ASC( FREAD( h, 1 ) ) == 13
			s = FREAD( h, 263 )
			i = AT( CHR(0), s + CHR(0) )
			s = LEFT( s, i-1 )
			sDBC = IIF( EMPTY( s ), "", this.FullPath( s, JUSTPATH( sFName ) ) )
			EXIT
		ENDIF
	ENDFOR
	FCLOSE(h)
	IF !EMPTY( sDBC ) AND !FILE( sDBC )
		FREE TABLE TABLE (sFName)
		sDBC = ""
	ENDIF
	IF EMPTY( sDBC )
		RETURN DODEFAULT(sOutFName)
	ENDIF
	*-- This table is part of a database - sDBC
	lPreUsed = DBUSED( sDBC )
	IF !lPreUsed
		OPEN DATABASE (sDBC) SHARED
	ENDIF
	SET DATABASE TO (sDBC)
	DROP TABLE (sFName) RECYCLE
	IF !lPreUsed
		CLOSE DATABASES && just this one
	ENDIF
ENDFUNC && DeleteBeforeOverwrite
*******************************************************************************
FUNCTION CreateOutputTable(sFName,sFormat,sDBC,aIdxs)
	LOCAL lPreUsed
	IF EMPTY( sDBC )
		CREATE TABLE (sFName) FREE (&sFormat)
	ELSE
		sDBC = this.FullPath( sDBC, JUSTPATH( sFName ) )
		lPreUsed = DBUSED( sDBC )
		IF !lPreUsed
			OPEN DATABASE (sDBC) SHARED
			IF !DBUSED( sDBC )
				RETURN .F.
			ENDIF
		ENDIF
		SET DATABASE TO (sDBC)
		CREATE TABLE (sFName) (&sFormat)
	ENDIF
	IF PCOUNT() == 4
		EXTERNAL ARRAY aIdxs
		FOR i = 1 TO ALEN(aIdxs) && create indexes
			EXECSCRIPT( aIdxs[i] )
		ENDFOR
	ENDIF
	USE && close unknown alias
	IF !EMPTY( sDBC ) AND !lPreUsed
		SET DATABASE TO (sDBC)
		CLOSE DATABASES && just this one
	ENDIF
ENDFUNC && CreateOutputTable
ENDDEFINE && DBF_Converter
*******************************************************************************
DEFINE CLASS DBContainerConverter AS TableConverter
	FUNCTION IgnoreField(sName)
		RETURN (sName == "CODE" AND cInput.ObjectName = "StoredProceduresObject")
	ENDFUNC && IgnoreField
	FUNCTION CleanupMemo(sName,sValue)
		sValue = DODEFAULT(sName,sValue)
		IF sName == "CODE" AND RTRIM( cInput.ObjectName ) == "StoredProceduresSource"
			sValue = this.SortProcsInMemo( sValue )
		ENDIF
		RETURN sValue
	ENDFUNC && CleanupMemo
	FUNCTION CreateOutputTable(sFName,sFormat,sDBC,aIdxs)
		LOCAL sHoldSafety, nHoldCWA
		nHoldCWA = SELECT(0)
		SELECT 0
		CREATE DATABASE (sFName)
		IF DBUSED( sFName )
			SET DATABASE TO (sFName)
			CLOSE DATABASES && just this one
		ENDIF
		USE (sFName) EXCLUSIVE
		sHoldSafety = SET("SAFETY")
		SET SAFETY OFF
		ZAP && get rid of the 5 recs in an empty DBC
		SET SAFETY &sHoldSafety
		USE && close 
		SELECT (nHoldCWA)
	ENDFUNC && CreateOutputTable
	*******************************************************************************
	FUNCTION ConvertToText(sInFName AS STRING, sOutFName AS STRING) AS VOID
		LOCAL sSDT
		SET PROCEDURE TO WinRegProcs ADDITIVE
		sSDT = ReadRegistry( HKEY_LOCAL_MACHINE, "Software\SubFox", "SDT", "n/a" )
		IF !EMPTY( sSDT ) AND sSDT != "n/a" AND FILE( sSDT )
			this.UpdateStonefieldTables( sSDT, sInFName )
		ENDIF
		DODEFAULT( sInFName, sOutFName )
	ENDFUNC && CreateOutputTable
	*******************************************************************************
	FUNCTION UpdateStonefieldTables(sSDT AS String, sDBC AS STRING) AS Boolean
		LOCAL i,s,ss, kDBC, aSDT[1], sPath, oMeta, oErr, oRec, nHoldArea, sHoldOrder, nHoldRecNo
		nHoldArea = SELECT(0)
		nHoldRecNo = IIF( EOF(), 0, RECNO() )
		sHoldOrder = SET("Order")
		sHoldOrder = STREXTRACT( sHoldOrder, "TAG ", " OF " )
		sPath = JUSTPATH( sDBC )
		*-- DBCX updates a date-time stamp every time, which ruins our test for "any changes?"
		IF !FILE( FORCEPATH( "_coremeta.dbf", sPath ) )
			*-- make a back copy of the "coremeta" table
			s = FORCEPATH( "coremeta.dbf", sPath )
			IF FILE( s )
				USE (s) AGAIN IN 0 SHARED ALIAS cCoreMeta NOUPDATE
				SELECT cCoreMeta
				COPY TO (FORCEPATH( "_coremeta.dbf", sPath )) WITH CDX
				USE IN cCoreMeta
			ENDIF
		ENDIF
		TRY
			s = "accessing Stonefield Database Toolkit"
			* oMeta = NEWOBJECT( 'DBCXMgr', 'DBCXMgr.vcx', sSDT, .F., sPath, .T. )
			* oMeta = NEWOBJECT( 'SdtDbcxMgr', 'SdtManagers.vcx', sSDT, .F., sPath, .T. )
			ss = [NEWOBJECT( 'SdtDbcxMgr', 'SdtManagers.vcx', '] + sSDT + [', .F., sPath, .T. )]
			oMeta = &ss
			IF ISNULL( oMeta )
				ERROR 'Unable to create "SdtDbcxMgr" object'
			ENDIF
			oMeta.lShowStatus = .T.
			oMeta.lDebugMode  = .F.
			* If the SDT Manager isn't registered, do it now.
			IF !oMeta.IsManagerRegistered( 'oSDTMgr' )
				oMeta.RegisterManager( 'Stonefield Database Toolkit', JUSTPATH( sSDT ), 'SDT.vcx', 'SDTMgr' )
			ENDIF
			s = 'accessing database "' + sDBC + '"'
			IF !DBUSED( sDBC )
				OPEN DATABASE (sDBC) SHARED NOUPDATE
			ENDIF
			SET DATABASE TO (sDBC)
			s = 'building SDT meta-data for "' + sDBC + '"'
			WAIT WINDOW NOWAIT 'Generating Stonefield data for database' + CHR(13) + sDBC
			IF !oMeta.Validate( sDBC, "Database" )
				ERROR "SDT Validation Error"
			ENDIF
			oErr = NULL
		CATCH TO oErr
		ENDTRY
		oMeta = NULL
		WAIT CLEAR
		IF !ISNULL( oErr )
			IF USED( sDBC )
				SET DATABASE TO (sDBC)
				CLOSE DATABASES && just this one
			ENDIF
			i = MESSAGEBOX( "Error encountered " + s + CHR(13) ;
						  + TRANSFORM( oErr.ErrorNo ) + ": " + oErr.Message + CHR(13) + CHR(13) ;
						  + "Do you want to continue without using SDT?", 4 + 32 + 256 )
			IF i == 7 && no
				IF nHoldRecNo > 0
					GO nHoldRecNo
				ELSE
					GO BOTTOM
					IF !EOF()
						SKIP
					ENDIF
				ENDIF
				SET ORDER TO &sHoldOrder
				SELECT (nHoldArea)
				RETURN .F.
			ENDIF
			EXIT && don't bother scanning for other DBCs
		ENDIF
		*-- fixup datetime stamps in coremeta
		s = FORCEPATH( "coremeta.dbf", sPath )
		ss = FORCEPATH( "_coremeta.dbf", sPath )
		IF FILE( s ) AND FILE( ss )
			USE (s) IN 0 SHARED ALIAS cNewCoreMeta
			USE (ss) IN 0 SHARED ALIAS cOldCoreMeta
			SELECT iid FROM cOldCoreMeta INTO CURSOR cExtinctCoreMeta READWRITE
			SELECT cExtinctCoreMeta
			INDEX ON iid TAG iid
			SET ORDER TO iid IN  cExtinctCoreMeta
			SET ORDER TO iid IN  cOldCoreMeta
			SELECT cNewCoreMeta
			SET RELATION TO iid INTO cOldCoreMeta, iid INTO cExtinctCoreMeta
			SCAN && FOR !EOF( 'cOldCoreMeta' )
				IF EOF( 'cOldCoreMeta' )
					SCATTER MEMO NAME oRec
					INSERT INTO cOldCoreMeta FROM NAME oRec
				ELSE
					DELETE IN cExtinctCoreMeta
					s = SYS( 2017, "tLastMod", 3 )
					SELECT cOldCoreMeta
					ss = SYS( 2017, "tLastMod", 3 )
					SELECT cNewCoreMeta
					IF s == ss && nothing else has changed
						REPLACE tLastMod WITH cOldCoreMeta.tLastMod && restore the time stamp
					ELSE
						SCATTER MEMO NAME oRec
						SELECT cOldCoreMeta
						GATHER MEMO NAME oRec
						SELECT cNewCoreMeta
					ENDIF
				ENDIF
			ENDSCAN
			SET RELATION TO && sever
			SELECT cOldCoreMeta
			SET RELATION TO iid INTO cExtinctCoreMeta
			GO TOP && install relation
			DELETE FOR !EOF( 'cExtinctCoreMeta' ) IN cOldCoreMeta
			SET RELATION TO && sever
			USE IN cNewCoreMeta
			USE IN cOldCoreMeta
			USE IN cExtinctCoreMeta
		ENDIF
		IF USED( 'cFile' ) && add the new tables (if any) to cFile
			kDBC = cFile.k_RecKey
			FOR i = 1 TO ALINES( aSDT, SDT_META_TABLES, .T., "," )
				s = ADDBS( sPath ) + FORCEEXT( aSDT[i], "dbf" )
				IF FILE( s ) AND !this.SeekFName( s )
					INSERT INTO cFile  (k_Parent, s_FName, s_Path, e_Type, l_Versioned, l_Encoded) ;
								VALUES (kDBC, JUSTFNAME(s), JUSTPATH(s), FILETYPE_FREETABLE, .T., .T.)
				ENDIF
			ENDFOR
		ENDIF
		SELECT (nHoldArea)
		IF nHoldRecNo != 0
			GO nHoldRecNo
		ELSE
			GO BOTTOM
			IF !EOF()
				SKIP
			ENDIF
		ENDIF
		SET ORDER TO &sHoldOrder
	ENDFUNC && UpdateStonefieldTables
	*******************************************************************************
	FUNCTION SeekFName(sFName AS String) AS Boolean
		LOCAL i,b,s
		s = LOWER( JUSTFNAME( sFName ) )
		IF !SEEK( PADR(s,MAX_VFP_IDX_LEN), 'cFile', 's_FName' )
			RETURN .F.
		ENDIF
		i = SELECT(0)
		SELECT cFile
		SET ORDER TO s_FName
		LOCATE FOR RTRIM( s_Path ) == LOWER( JUSTPATH( sFName ) ) REST WHILE RTRIM( s_FName ) == s
		SELECT (i)
		RETURN FOUND('cFile')
	ENDFUNC && SeekFName
ENDDEFINE && DBContainerConverter
*******************************************************************************
DEFINE CLASS FormConverter AS TableConverter
	FUNCTION SetDefaultValues(oRec)
		oRec.Platform = PADR( "WINDOWS", LEN( oRec.Platform ) )
	ENDFUNC && SetDefaultValues
	FUNCTION IsBinary(sName,sValue)
		RETURN (sName == "OLE")
	ENDFUNC && IsBinary
	FUNCTION IgnoreField(sName)
		* Fields that match condition (sName == "RESERVED1" and Platform == "COMMENT"
		* and Uniqueid == "RESERVED") change without other changes to the file
		RETURN (sName == "OBJCODE" OR sName == "TIMESTAMP") or;
			(sName == "RESERVED1" and cInput.Platform = "COMMENT" and cInput.Uniqueid = "RESERVED")
	ENDFUNC && IgnoreField
	FUNCTION CleanupMemo(sName,sValue)
		sValue = DODEFAULT(sName,sValue)
		IF sName == "METHODS"
			sValue = this.SortProcsInMemo( sValue )
		ENDIF
*--	This doesn't work!  VFP wants it's properties in a certain order, I guess!
*!*			IF sName == "PROPERTIES" OR sName == "RELEASE3"
*!*				sValue = this.SortPropertiesInMemo( sValue )
*!*			ENDIF
		RETURN sValue
	ENDFUNC && CleanupMemo
ENDDEFINE && FormConverter
*******************************************************************************
DEFINE CLASS ReportConverter AS TableConverter
	FUNCTION IgnoreField(sName)
		RETURN (RECNO('cInput') == 1 AND (sName == "TAG" OR sName == "TAG2")) ;
			OR (sName == "TAG2" AND INLIST( cInput.ObjType, 25, 26 ))


*--		Blank FIELDS Tag, Tag2 for Recno() == 1
*--		Blank FIELDS Tag2 for InList(OBJTYPE,25,26)

	ENDFUNC && IgnoreField
	FUNCTION CleanupMemo(sName,sValue)
		sValue = DODEFAULT(sName,sValue)
		IF sName == "EXPR"
			sValue = STRTRAN( sValue, CHR(0), "" )
		ENDIF
		RETURN sValue
	ENDFUNC && CleanupMemo
	FUNCTION CreateOutputTable(sFName,sFormat,aIdxs)
		*-- the field named "UNIQUE" causes the CREATE TABLE to fail
		LOCAL i,a[1]
		sFormat = STRTRAN( sFormat, "UNIQUE L", "_Unique L", 1, 1 )
		CREATE CURSOR cDummy (&sFormat)
		AFIELDS( a, 'cDummy' )
		USE IN cDummy
		i = ASCAN( a, "_Unique", 1, ALEN( a,1 ), 1, 15 )
		a[i,1] = "UNIQUE"
		SELECT 0
		CREATE TABLE (sFName) FROM ARRAY a
		USE
	ENDFUNC && CreateOutputTable
ENDDEFINE && ReportConverter
*******************************************************************************
DEFINE CLASS LabelConverter AS ReportConverter
ENDDEFINE && LabelConverter
*******************************************************************************
DEFINE CLASS ProjectConverter AS TableConverter
FUNCTION ConvertToText(sInFName AS STRING, sOutFName AS STRING) AS VOID

*	RETURN DODEFAULT( sInFName, sOutFName )

	LOCAL i,s,ss, sMain, sIcon
	this.s_InFName = sInFName
	this.s_OutFName = sOutFName
	this.t_InputDTStamp = this.FDateTime( sInFName )
	IF USED( 'cInput' )
		USE IN cInput
	ENDIF

	USE (sInFName) AGAIN In 0 SHARED ALIAS cInput NOUPDATE

	IF !USED( 'cInput' )
		*ERROR "Unable to open input file"
		RETURN
	ENDIF
	SELECT cInput
	LOCATE FOR MainProg
	sMain = IIF( !FOUND(), "", LOWER( STRTRAN( Name, CHR(0) ) ) )
	LOCATE FOR Type == FILETYPE_ICON
	sIcon = IIF( !FOUND(), "", LOWER( STRTRAN( Name, CHR(0) ) ) )

	*-- inspect the binary header PACKED fields
	GO TOP IN cInput
	ALINES( aCellLen, "46,46,46,21,6,11,46,510,255,255,255,255,5,5,5,20,8", .T., "," )
	DIMENSION a[ALEN(aCellLen)]
	ii = 1
	FOR i = 1 TO ALEN(a)
		a[i] = STRTRAN( SUBSTR( DevInfo, ii, VAL(aCellLen[i]) ), CHR(0), "" )
		ii = ii + VAL(aCellLen[i])
	ENDFOR

*!*		a[1] = PADR( "David Holden", 46 )
*!*		a[2] = PADR( "Holden Data Systems", 46 )
*!*		a[3] = PADR( "11421 Marion", 46 )
*!*		a[4] = PADR( "Redford", 21 )
*!*		a[5] = PADR( "MI", 6 )
*!*		a[6] = PADR( "48239", 11 )
*!*		a[7] = PADR( "USA", 46 )
*!*		a[8] = PADR( "comment", 510 )
*!*		a[9] = PADR( "company", 255 )
*!*		a[10] = PADR( "copyright", 255 )
*!*		a[11] = PADR( "trademark", 255 )
*!*		a[12] = PADR( "product", 255 )
*!*		a[13] = PADR( "1", 5 )
*!*		a[14] = PADR( "2", 5 )
*!*		a[15] = PADR( "3", 5 )
*!*		a[16] = PADR( "language", 20 )
*!*		a[17] = PADR( CHR(1), 8 ) && autoIncVsn

	*-- write the header here
	this.s_Output = this.s_Output + "SubFox Project (vsn " + TRANSFORM( SUBFOX_VERSION ) + ")" + CRLF ;
		+ CHR(9) + "Main = " + sMain + CRLF ;
		+ CHR(9) + "Icon = " + sIcon + CRLF ;
		+ CHR(9) + "Version = " + a[13] + "." + a[14] + "." + a[15] + CRLF ;
		+ CHR(9) + "AutoInc = " + IIF( PADR(a[17],1) == CHR(1), "Y", "N" ) + CRLF ;
		+ CHR(9) + "Comments = " + a[8] + CRLF ;
		+ CHR(9) + "Company = " + a[2] + CRLF ;
		+ CHR(9) + "Copyright = " + a[10] + CRLF ;
		+ CHR(9) + "Lang = " + a[16] + CRLF ;
		+ CHR(9) + "Product = " + a[12] + CRLF ;
		+ CHR(9) + "Tradmarks = " + a[11] + CRLF

	*-- write file list here
	SELECT PADR( LOWER( STRTRAN( Name, CHR(0), "" ) ), MAX_VFP_FLD_LEN ) AS s_FName, * ;
		FROM cInput ;
		WHERE !EMPTY( ID ) AND NOT Type $ FILETYPE_APILIB + FILETYPE_APPLICATION +  FILETYPE_DBTABLE ;
			AND ( (Type == FILETYPE_DATABASE AND ATC( "unversioned", User ) == 0) ;
			   OR (Type != FILETYPE_DATABASE AND (!Exclude OR ATC( "versioned", User ) > 0)) ) ;
		ORDER BY Type, s_FName ;
		INTO CURSOR cInput2
	eType = SPACE(1)
	SELECT cInput2
	SCAN REST 
		IF cInput2.Type != eType
			eType = cInput2.Type
			this.s_Output = this.s_Output + CRLF + this.TypeToLabel( cInput2.Type ) + CRLF
		ENDIF
		s = IIF( Type != FILETYPE_DATABASE, "", STREXTRACT( User, "Versioned=[", "]" ) )
		s = IIF( EMPTY( s ), "", " (" + s + ")" )
		this.s_Output = this.s_Output + CHR(9) + IIF( !Exclude, "", "(!) " ) + RTRIM( s_FName ) + s + CRLF
		IF !EMPTY( STRTRAN( Comments, CHR(0) ) )
			this.s_Output = this.s_Output + CHR(9) + CHR(9) + this.EncodeComments( Comments ) + CRLF
		ENDIF
	ENDSCAN
	USE IN cInput2
	USE IN cInput
	IF !FILE( sOutFName ) OR NOT FILETOSTR( sOutFName ) == this.s_Output
		IF FILE( sOutFName )
			DELETE FILE (sOutFName)
		ENDIF
		STRTOFILE( this.s_Output, sOutFName )
		this.FDateTime( sOutFName, this.t_InputDTStamp )
	ENDIF
ENDFUNC && ConvertToText
*******************************************************************************
FUNCTION TypeToLabel(eType) AS String
	DO CASE
	CASE eType == FILETYPE_DATABASE
		RETURN "Databases"
	CASE eType == FILETYPE_FREETABLE
		RETURN "Free Tables"
	CASE eType == FILETYPE_QUERY
		RETURN "Queries"
	CASE eType == FILETYPE_FORM
		RETURN "Forms"
	CASE eType == FILETYPE_REPORT
		RETURN "Reports"
	CASE eType == FILETYPE_LABEL
		RETURN "Labels"
	CASE eType == FILETYPE_CLASSLIB
		RETURN "Libraries"
	CASE eType == FILETYPE_PROGRAM
		RETURN "Programs"
	CASE eType == FILETYPE_MENU
		RETURN "Menu"
	CASE eType == FILETYPE_TEXT
		RETURN "Text Files"
	ENDCASE
	RETURN "Other Files"
ENDFUNC && TypeToLabel
*******************************************************************************
FUNCTION RestoreToTable(sInFName AS STRING, sOutFName AS STRING) AS VOID

*	RETURN DODEFAULT( sInFName, sOutFName )

	LOCAL i,ii,iii,s,o,e,a[1], aByType[1], oHdr, oErr, lPreOpened, sComment, lExc, sPath
	LOCAL oPjx, oTranslator
*	set step on
	oTranslator = NULL
	sPath = JUSTPATH( sOutFName )
	TRY
		IF !FILE( sOutFName )
			CREATE PROJECT (sOutFName) NOWAIT SAVE NOSHOW
		ELSE
			IF TYPE( "_VFP.Projects.Item(sOutFName)" ) == "O"
				lPreOpened = _VFP.Projects.Item(sOutFName).Visible
			ELSE
				MODIFY PROJECT (sOutFName) NOWAIT NOSHOW
			ENDIF
		ENDIF
		oPjx = _VFP.Projects.Item( sOutFName )
		oErr = NULL
	CATCH TO oErr
	ENDTRY
	IF !ISNULL( oErr )
		THROW oErr
		RETURN
	ENDIF
	oPjx.HomeDir = JUSTPATH( sOutFName )
	this.s_Input = FILETOSTR( sInFName )
	ALINES( aByType, this.s_Input, .T., CRLF + CRLF )
	oHdr = this.ParseHdr( aByType[1] )
	FOR i = 2 TO ALEN( aByType )
		s = ALLTRIM( LEFT( aByType[i], AT( CRLF, aByType[i] ) - 1 ) )
		e = this.LabelToType( s )
*!*			IF EMPTY( e )
*!*				LOOP
*!*			ENDIF
		s = STRTRAN( aByType[i], CRLF + CHR(9) + CHR(9), "<comments>" )
		FOR ii = 2 TO ALINES( a, s, .T., CRLF + CHR(9) )
			iii = AT( "<comments>", a[ii] )
			sComment = IIF( iii == 0, "", SUBSTR( a[ii], iii + LEN("<comments>")) )
			s = IIF( iii == 0, a[ii], LEFT( a[ii], iii - 1 ) )
			lExc = (PADR( s, 4 ) == "(!) ")
			s = IIF( !lExc, s, SUBSTR( s, 5 ) )
			s = this.FullPath( s, sPath )
			IF !FILE(s) && do a just-in-time conversion
				IF !FILE( s + "." + SUBFOX_PRIVATE_EXT )
					LOOP && no encoded version of the file
				ENDIF
				IF ISNULL( oTranslator )
					oTranslator = NEWOBJECT( "SubFoxTranslator", "SubFox Translation Classes.prg" )
				ENDIF
				IF !oTranslator.ConvertFile( s + "." + SUBFOX_PRIVATE_EXT, s )
					LOOP
				ENDIF
			ENDIF
			o = this.FindFileInPjx( s, oPjx )
			IF ISNULL( o )
				o = oPjx.Files.Add(s)
			ENDIF
			IF !ISNULL( o )
				o.Type = e
				o.Description = sComment
				o.Exclude = lExc
			ENDIF
		ENDFOR
	ENDFOR
	IF !EMPTY( oHdr.Main )
		oPjx.SetMain( oHdr.Main )
	ENDIF
	IF !EMPTY( oHdr.Icon )
		oPjx.Icon = oHdr.Icon
	ENDIF
	oPjx.CleanUp()
	oPjx.Close()
	oPjx = NULL
	*-- here we open the PJX as a table and insert the other header values
	IF USED( 'cOutput' )
		USE IN cOutput
	ENDIF
	TRY
		USE (sOutFName) AGAIN IN 0 SHARED ALIAS cOutput
	CATCH
	ENDTRY
	IF USED( 'cOutput' )
		GO TOP IN cOutput
		s = this.GenBinHeader( oHdr )
		REPLACE DevInfo WITH s IN cOutput
		USE IN cOutput
	ENDIF
	this.FDateTime( sOutFName, this.FDateTime(sInFName) )
	this.FDateTime( FORCEEXT(sOutFName,"pjt"), this.FDateTime(sInFName) )
	IF lPreOpened
		MODIFY PROJECT (sOutFName) NOWAIT
	ENDIF
ENDFUNC && RestoreToTable
*******************************************************************************
FUNCTION GenBinHeader(oHdr AS Object) AS String
	LOCAL i,s,a[1],aa[1], sVsn1, sVsn2, sVsn3
	s = oHdr.Version
	i = AT( ".", s )
	sVsn1 = LEFT( s, i-1 )
	s = SUBSTR( s, i+1 )
	i = AT( ".", s )
	sVsn2 = LEFT( s, i-1 )
	sVsn3 = SUBSTR( s, i+1 )
	ALINES( aa, "46,46,46,21,6,11,46,510,255,255,255,255,5,5,5,20,8", .T., "," )
	DIMENSION a[ALEN(aa),2]
	FOR i = 1 TO ALEN(aa,1)
		a[i,1] = IIF( i == 1, 1, a[i-1,1] + a[i-1,2] )
		a[i,2] = VAL( aa[i] )
	ENDFOR
	s = cOutput.DevInfo
	s = STUFF( s, a[13,1], a[13,2], PADR( sVsn1, a[13,2], CHR(0) ) )
	s = STUFF( s, a[14,1], a[14,2], PADR( sVsn2, a[14,2], CHR(0) ) )
	s = STUFF( s, a[15,1], a[15,2], PADR( sVsn3, a[15,2], CHR(0) ) )
	s = STUFF( s, a[17,1], 1, IIF( oHdr.AutoInc == "Y", CHR(1), CHR(0) ) )
	s = STUFF( s, a[8,1], a[8,2], PADR( oHdr.Comments, a[8,2], CHR(0) ) )
	s = STUFF( s, a[2,1], a[2,2], PADR( oHdr.Company, a[2,2], CHR(0) ) )
	s = STUFF( s, a[10,1], a[10,2], PADR( oHdr.Copyright, a[10,2], CHR(0) ) )
	s = STUFF( s, a[16,1], a[16,2], PADR( oHdr.Lang, a[16,2], CHR(0) ) )
	s = STUFF( s, a[12,1], a[12,2], PADR( oHdr.Product, a[12,2], CHR(0) ) )
	s = STUFF( s, a[11,1], a[11,2], PADR( oHdr.Tradmarks, a[11,2], CHR(0) ) )
	RETURN s
ENDFUNC && GenBinHeader
*******************************************************************************
FUNCTION FindFileInPjx(sFName AS String, oPjx AS Object) AS Object
	LOCAL o
	sFName = LOWER( this.FullPath( sFName, oPjx.HomeDir ) )
	FOR EACH o IN oPjx.Files
		IF LOWER( o.Name ) == sFName
			RETURN o
		ENDIF
	ENDFOR
	RETURN NULL
ENDFUNC && FindFileInPjx
*******************************************************************************
FUNCTION ParseHdr(sText AS String) AS Object
	LOCAL i,ii,s,a[1],o
	o = CREATEOBJECT( "empty" )
	FOR i = 2 TO ALINES( a, sText, .T., CRLF + CHR(9) )
		ii = AT( "=", a[i] )
		IF ii > 0
			ADDPROPERTY( o, STRTRAN( LEFT( a[i], ii-1 ), " ", "" ), ;
						 ALLTRIM( SUBSTR( a[i] + " ", ii+1 ) ) )
		ENDIF
	ENDFOR
	RETURN o
ENDFUNC && ParseHdr
*******************************************************************************
FUNCTION LabelToType(sText AS String) AS String
	DO CASE
	CASE sText == "Databases"
		RETURN FILETYPE_DATABASE
	CASE sText == "Free Tables"
		RETURN FILETYPE_FREETABLE
	CASE sText == "Queries"
		RETURN FILETYPE_QUERY
	CASE sText == "Forms"
		RETURN FILETYPE_FORM
	CASE sText == "Reports"
		RETURN FILETYPE_REPORT
	CASE sText == "Labels"
		RETURN FILETYPE_LABEL
	CASE sText == "Libraries"
		RETURN FILETYPE_CLASSLIB
	CASE sText == "Programs"
		RETURN FILETYPE_PROGRAM
	CASE sText == "Menu"
		RETURN FILETYPE_MENU
	CASE sText == "Text Files"
		RETURN FILETYPE_TEXT
	ENDCASE
	RETURN FILETYPE_OTHER
ENDFUNC && LabelToType
*******************************************************************************
FUNCTION EncodeComments(sText AS String) AS String
	sText = STRTRAN( sText, CHR(0), "" )
	sText = STRTRAN( sText, "\", "\\" )
	sText = STRTRAN( sText, CHR(9), "\t" )
	sText = STRTRAN( sText, CR, "\r" )
	sText = STRTRAN( sText, LF, "\n" )
	RETURN sText
ENDFUNC && EncodeComments
*******************************************************************************
FUNCTION DecodeComments(sText AS String) AS String
	sText = STRTRAN( sText, "\n", LF )
	sText = STRTRAN( sText, "\r", CR )
	sText = STRTRAN( sText, "\t", CHR(9) )
	sText = STRTRAN( sText, "\\", "\" )
	RETURN sText + CHR(0)
ENDFUNC && DecodeComments
*******************************************************************************
	FUNCTION IgnoreField(sName)
		IF RECNO() == 1
			IF INLIST( sName, "NAME" )
				RETURN .T.
			ENDIF
		ELSE
			IF INLIST( sName, "OBJECT", "DEVINFO" )
				RETURN .T.
			ENDIF
		ENDIF
		RETURN INLIST( sName, "TIMESTAMP", "SYMBOLS" )
	ENDFUNC && IgnoreField
	FUNCTION CleanObjAfterRead(oRec)
		oRec.Name = STRTRAN( oRec.Name, CHR(0), "", 1,1 )
		IF RECNO('cInput') == 1
			LOCAL i,s, a[1]
			*-- purge the NULL bytes
			STORE "" TO oRec.Object, oRec.Reserved1
			FOR i = 1 TO ALINES( a, "OutFile,HomeDir", .T., "," )
				s = a[i]
				oRec.&s = STRTRAN( oRec.&s, CHR(0), "", 1,1 )
			ENDFOR
			*-- switch HomeDir to "relative" basis... usually just one dot
			IF UPPER( JUSTPATH(DBF('cInput')) ) == UPPER( oRec.HomeDir )
				oRec.HomeDir = "."
			ELSE
				LOCAL sHoldPath
				sHoldPath = SYS(5) + SYS(2003)
				CD (JUSTPATH(DBF('cInput')))
				s = SYS( 2014, oRec.HomeDir, JUSTPATH(DBF('cInput')) )
				oRec.HomeDir = LOWER( s )
				Cd (sHoldPath)
			ENDIF
		ENDIF
	ENDFUNC && CleanObjAfterRead
	FUNCTION DirtyUpObjBeforeWrite(oRec)
		oRec.Name = oRec.Name + CHR(0)
		IF RECCOUNT('cOutput') == 0
			LOCAL i,s, a[1]
			*-- append the NULL bytes
			FOR i = 1 TO ALINES( a, "OutFile,Object", .T., "," )
				s = a[i]
				oRec.&s = oRec.&s + CHR(0)
			ENDFOR
			*-- switch HomeDir to "absolute" basis
			LOCAL sHoldPath
			sHoldPath = SYS(5) + SYS(2003)
			CD (JUSTPATH(DBF('cOutput')))
			s = FULLPATH( IIF( DIRECTORY( oRec.HomeDir ), oRec.HomeDir, "." ) ) 
			oRec.HomeDir = LOWER( s ) + CHR(0)
			CD (sHoldPath)
			oRec.Reserved1 = DBF('cOutput') + CHR(0)
			oRec.Object = LOWER( JUSTPATH(DBF('cOutput')) ) + CHR(0)
			oRec.Name = UPPER( DBF('cOutput') ) + CHR(0)
		ENDIF
	ENDFUNC && DirtyUpObjBeforeWrite
ENDDEFINE && ProjectConverter
*******************************************************************************
DEFINE CLASS MenuConverter AS TableConverter
ENDDEFINE && MenuConverter
*******************************************************************************

DEFINE CLASS ClasslibConverter AS FormConverter
*******************************************************************************
*-- Classlib conversion is unique.  Encoding generates MULTIPLE output files, 
*-- and decoding merges them back together.
FUNCTION ConvertToText(sInFName AS STRING, sOutFName AS STRING) AS VOID
	LOCAL i,s, oRec, oBlank, aIsMemo[1], sClass, sForExpr
	this.s_InFName = sInFName
	this.s_OutFName = sOutFName
	this.t_InputDTStamp = this.FDateTime( sInFName )
	IF USED( 'cInput' )
		USE IN cInput
	ENDIF
	
	USE (sInFName) AGAIN IN 0 SHARED ALIAS cInput NOUPDATE
	
	SELECT cInput
	SELECT LOWER( PADR( ObjName, 128 ) ) AS Name, RECNO() AS FromRecNo, RECNO() + VAL(Reserved2) AS ThruRecNo ;
		FROM cInput ORDER BY 1 INTO CURSOR cClassList ;
		WHERE EMPTY( Parent ) AND Platform = "WINDOWS" and Reserved1 == "Class"
	SELECT cClassList
	INDEX ON PADR( Name, MAX_VFP_IDX_LEN ) TAG Name COLLATE "GENERAL"
	this.PurgeExtinctSubFiles()
	this.s_Output = "SubFox" + CRLF
	this.CaptureTableFormat()
	SELECT cClassList
	s = ""
	SCAN
		s = s + CHR(9) + RTRIM( cClassList.Name ) + CRLF
	ENDSCAN
	this.s_Output = this.s_Output + "Classes-FREETEXT=" + CRLF + s
	SELECT cInput
	SCATTER NAME oBlank MEMO BLANK
	this.SetDefaultValues( oBlank )
	DIMENSION aIsMemo[FCOUNT('cInput')]
	FOR i = 1 TO FCOUNT('cInput')
		aIsMemo[i] = (TYPE( 'cInput.' + FIELD(i,'cInput') ) == "M")
	ENDFOR
	sClass = ""
	DO WHILE .T. && in lieu of SELECT cClassList and SCAN
		SELECT cInput
		SET DELETED ON
		GO TOP
		sForExpr = IIF( EMPTY( sClass ), "NEXT 1", "FOR BETWEEN( RECNO('cInput'), cClassList.FromRecNo, cClassList.ThruRecNo )" )
		SCAN &sForExpr
			this.s_Output = this.s_Output + "*rec*" + CRLF
			SCATTER NAME oRec MEMO
			this.CleanObjAfterRead( oRec )
			FOR i = 1 TO FCOUNT('cInput')
				s = FIELD(i,'cInput')
				DO CASE
				CASE this.IgnoreField(s) OR oRec.&s == oBlank.&s
					* LOOP
				CASE aIsMemo[i] AND this.IsBinary( s, oRec.&s )
					this.s_Output = this.s_Output + s + "-BASE64=" + STRCONV( oRec.&s, 13 ) + CRLF
				CASE aIsMemo[i] AND AT( CHR(13), oRec.&s ) == 0
					*-- sometimes an initial but meaningless NULL byte is in pos #1
					oRec.&s = this.CleanupMemo( s, oRec.&s )
					this.s_Output = this.s_Output + s + "=" + RTRIM( oRec.&s ) + CRLF
				CASE aIsMemo[i]
					oRec.&s = this.CleanupMemo( s, oRec.&s )
					this.s_Output = this.s_Output + s + "-FREETEXT=" + CRLF + CHR(9) + STRTRAN( oRec.&s, CRLF, CRLF + CHR(9) ) + CRLF
				OTHERWISE
					this.s_Output = this.s_Output + s + "=" + RTRIM( STRTRAN( TRANSFORM( oRec.&s ), CHR(0), "" ) ) + CRLF
				ENDCASE
			ENDFOR
		ENDSCAN
		IF !FILE( sOutFName ) OR NOT FILETOSTR( sOutFName ) == this.s_Output
			IF FILE( sOutFName )
				DELETE FILE (sOutFName)
			ENDIF
			STRTOFILE( this.s_Output, sOutFName )
		ENDIF
		this.FDateTime( sOutFName, this.t_InputDTStamp )
		this.s_Output = "SubFox" + CRLF
		IF EMPTY( sClass )
			GO TOP IN cClassList
		ELSE
			SKIP IN cClassList
		ENDIF
		IF EOF( 'cClassList' )
			EXIT
		ENDIF
		sClass = RTRIM( cClassList.Name )
		sOutFName = FORCEEXT( sInFName, "vcx-" + sClass ) + "." + SUBFOX_PRIVATE_EXT
	ENDDO && ENDSCAN
	USE IN cInput
	USE IN cClassList
ENDFUNC && ConvertToText
*******************************************************************************
FUNCTION PurgeExtinctSubFiles()
	*-- exporting to a "text" file in this case means multiple text files.
	*-- Unlike normal "replace" operations, there is no guarantee that ALL files
	*-- will be replaced.  Must DELETE the remanants that are not going to be replaced.
	LOCAL i,s,a[1], sPre, sPost, sPath
	sPre = FORCEEXT( this.s_InFName, "" ) + ".vcx-"
	sPost =  "." + SUBFOX_PRIVATE_EXT
	sPath = ADDBS( JUSTPATH( this.s_InFName ) )
	FOR i = 1 TO ADIR( a, FORCEEXT( this.s_InFName, "vcx-*." + SUBFOX_PRIVATE_EXT ) )
		s = STREXTRACT( a[i,1], sPre, sPost, 1 ) && change "MyLib.vcx-MyClass.SubFox" into "MyClass"
		IF !SEEK( PADR( s, 12 ), "cClassList", "Name" )
			DELETE FILE (sPath + a[i,1])
		ENDIF
	ENDFOR
ENDFUNC && PurgeExtinctSubFiles
*******************************************************************************
FUNCTION ReadHeader(sOutFName)
	LOCAL i,ii,s,ss, a[1], nCnt, sMissing
	*-- extract the class list from the header
	i = AT( CRLF + "*rec*" + CRLF, CRLF + this.s_Input )
	s = IIF( i == 0, this.s_Input, LEFT( this.s_Input, i-1 ) )
	i = ATC( CRLF + "Classes=", CRLF + s )
	IF i > 0
		ii = AT( CRLF, SUBSTR( s, i ) )
		IF ii == 0
			ERROR 'Error Generating Class-Library "' + this.s_OutFName + '"' + CR ;
			    + "Header record has no sub-class list"
			RETURN .F. && failure!!
		ENDIF
		s = SUBSTR( s, i, ii-1 )
		s = SUBSTR( s, AT( "=", s ) + 1 )
		*-- modify header in place to ERASE the class list entirely
		this.s_Input = STUFF( this.s_Input, i, ii+1, "" )
	ELSE
		* Classes-FREETEXT=
		i = ATC( CRLF + "Classes-FREETEXT=", CRLF + s )
		IF i == 0
			ERROR 'Error Generating Class-Library "' + this.s_OutFName + '"' + CR ;
			    + "Header record has no sub-class list"
			RETURN .F. && failure!!
		ENDIF
		LOCAL nCRSub, nCROff
		s = SUBSTR( s, i )
		FOR nCRSub = 1 TO OCCURS( CRLF, s ) + 2
			nCROff = AT( CRLF, s + CRLF, nCRSub )
			IF nCROff == 0 OR SUBSTR( s, nCROff+2, 1 ) != CHR(9)
				EXIT
			ENDIF
		ENDFOR
		IF nCROff == 0
			ERROR 'Error Generating Class-Library "' + this.s_OutFName + '"' + CR ;
			    + "Header record has no sub-class list"
			RETURN .F. && failure!!
		ENDIF
		*-- modify header in place to ERASE the class list entirely
		this.s_Input = STUFF( this.s_Input, i, nCROff+1, "" )
		s = LEFT( s, nCROff - 1 )
		s = SUBSTR( s, AT( CRLF, s ) + 2 )
		*-- replace CRLF+TAB separators with commas (older stype format)
		s = STRTRAN( s, CRLF, "," )
		s = STRTRAN( s, CHR(9), "" )
	ENDIF
	*-- bring append text files to in memory buffer
	nCnt = ALINES( a, s, 5, "," )
	sMissing = ""
	FOR i = 1 TO nCnt
		s = FORCEEXT( this.s_OutFName, "vcx-" + a[i] ) + "." + SUBFOX_PRIVATE_EXT
		IF !FILE( s )
			sMissing = IIF( EMPTY( sMissing ), "", sMissing + ", " ) + a[i]
		ENDIF
	ENDFOR
	IF !EMPTY( sMissing )
		ERROR 'Error Generating Class-Library "' + this.s_OutFName + '"' + CR ;
		    + "The following class sub-files are missing:" + CR + CR + sMissing
		RETURN .F.
	ENDIF
	FOR i = 1 TO nCnt
		s = FILETOSTR( FORCEEXT( this.s_OutFName, "vcx-" + a[i] ) + "." + SUBFOX_PRIVATE_EXT )
		IF PADR( s, 8 ) != "SubFox" + CRLF
			ERROR 'Error Generating Class-Library "' + this.s_OutFName + '"' + CR ;
			    + 'Invalid class sub-file "' + a[i] + '"'
			RETURN .F.
		ENDIF
		this.s_Input = this.s_Input + SUBSTR( s, AT( CRLF, s ) + 2 )
	ENDFOR
	RETURN DODEFAULT( sOutFName )
ENDFUNC && ReadHeader

ENDDEFINE && ClasslibConverter


*******************************************************************************
* Error Handler *
* As a base class, this handler applies to ALL object classes used in the APP.
*******************************************************************************
*DEFINE CLASS ErrorHandler AS session
DEFINE CLASS ErrorHandler as Custom
	FUNCTION Init()
		SET EXCLUSIVE OFF
		SET DELETED ON
		SET TALK OFF
		SET CENTURY ON
		SET EXACT OFF
*--			IF _VFP.StartMode != 0
*--				BINDEVENT( this, "Error", this, "OnError" )
*--			ENDIF
	ENDFUNC && Init
*--		FUNCTION OnError(nError, sMethod, nLineNo)
*--			LOCAL sErrMsg, sMsg, oErr
*--			TRY	
*--				m.sErrMsg = MESSAGE()
*--				TEXT TO m.sMsg TEXTMERGE NOSHOW PRETEXT 2
*--					An unexpected error has occurred.  Select <Ok> to terminate the program.
*--					
*--					ERROR #: <<TRANSFORM(m.nError)>> <<m.sErrMsg>>
*--					AT LINE <<m.nLineNo>> OF "<<m.Method>>"
*--				ENDTEXT
*--				MESSAGEBOX( m.sMsg, 16, "SubFox Encoder" )
*--			CATCH TO oErr
*--				ASSERT .F. MESSAGE PROGRAM()
*--			ENDTRY
*--			CANCEL
*--		ENDFUNC && OnError
ENDDEFINE && ErrorHandler

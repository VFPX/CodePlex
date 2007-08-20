#INCLUDE System.h

#DEFINE USECLASS_XFCENUM
#DEFINE USECLASS_XFCEVENTHANDLER
#DEFINE USECLASS_XFCGUID
#DEFINE USECLASS_XFCIO
#DEFINE USECLASS_XFCMEMORYSTREAM
#DEFINE USECLASS_XFCOBJECT
#DEFINE USECLASS_XFCSINGLE
#DEFINE USECLASS_XFCSTREAM

LPARAMETER toObject

IF PCOUNT() = 0
	m.toObject = _SCREEN
ENDIF

IF VARTYPE(m.toObject) = "O"
	IF VARTYPE(m.toObject.System) <> "O"
		ADDPROPERTY(m.toObject,"System",CREATEOBJECT("xfcSystem"))
	ENDIF
ENDIF

*************************************************************************
*************************************************************************
*************************************************************************
DEFINE CLASS xfcSystem AS xfcObject
*************************************************************************
*************************************************************************
*************************************************************************
	
	*********************************************************************
	** Namespace Definitions:
	*********************************************************************
	
	*********************************************************************
	Drawing = .NULL.
	*********************************************************************
	FUNCTION Drawing_ACCESS
	*********************************************************************
		IF VARTYPE(This.Drawing) <> "O"
			DO (ADDBS(JUSTPATH(This.ClassLibrary))+"System.Drawing.PRG") WITH This
		ENDIF
		RETURN THIS.Drawing
	ENDFUNC


	*********************************************************************
	** Class Definitions:
	*********************************************************************
	
	*********************************************************************
	Enum = .NULL.
	*********************************************************************
	FUNCTION Enum_ACCESS
	*********************************************************************
		IF VARTYPE(This.Enum) <> "O"
			This.Enum = CREATEOBJECT("xfcEnum")
		ENDIF
		
		RETURN This.Enum
	ENDFUNC


	*********************************************************************
	EventHandler = .NULL.
	*********************************************************************
	FUNCTION EventHandler_ACCESS
	*********************************************************************
		IF VARTYPE(This.EventHandler) <> "O"
			This.EventHandler = CREATEOBJECT("xfcEventHandler")
		ENDIF
		
		RETURN THIS.EventHandler
	ENDFUNC


	*********************************************************************
	Guid = .NULL.
	*********************************************************************
	FUNCTION Guid_ACCESS
	*********************************************************************
		IF VARTYPE(This.Guid) <> "O"
			This.Guid = CREATEOBJECT("xfcGuid")
		ENDIF
		
		RETURN THIS.Guid
	ENDFUNC


	*********************************************************************
	IO = .NULL.
	*********************************************************************
	FUNCTION IO_ACCESS
	*********************************************************************
		IF VARTYPE(This.IO) <> "O"
			This.IO = CREATEOBJECT("xfcIO")
		ENDIF
		
		RETURN This.IO
	ENDFUNC


	*********************************************************************
	Single = .NULL.
	*********************************************************************
	FUNCTION Single_ACCESS
	*********************************************************************
		IF VARTYPE(This.Single) <> "O"
			This.Single = CREATEOBJECT("xfcSingle")
		ENDIF
		
		RETURN This.Single
	ENDFUNC


	*********************************************************************
	#IFDEF USE_MEMBERDATA
	PROTECTED _memberdata
	_memberdata = [<VFPData>]+;
		[<memberdata name="drawing" type="Property" display="Drawing"/>]+;
		[<memberdata name="guid" type="property" display="Guid"/>]+;
		[<memberdata name="eventhandler" type="property" display="EventHandler"/>]+;
		[<memberdata name="enum" type="property" display="Enum"/>]+;
		[<memberdata name="io" type="property" display="IO"/>]+;
		[<memberdata name="checkclasslib" type="method" display="CheckClasslib"/>]+;
		[</VFPData>]		
	#ENDIF
ENDDEFINE
*************************************************************************
*************************************************************************


*************************************************************************
*************************************************************************
*************************************************************************
#IFDEF USECLASS_XFCENUM
DEFINE CLASS xfcenum AS xfcObject
*************************************************************************
*************************************************************************
*************************************************************************
	DIMENSION _amembers[1]

 
	*********************************************************************
	FUNCTION New
	*********************************************************************
		RETURN THIS.CreateNew(THIS.CLASS)
	ENDFUNC


	*********************************************************************
	FUNCTION GetName
	*********************************************************************
	LPARAMETERS toEnum, tnIndex
		LOCAL loExc AS EXCEPTION, lvReturn
		TRY
			m.lvReturn = NULL
			=AMEMBERS(aryMembers, m.toEnum, 0)
			This._DeleteHidden(@m.aryMembers)
			m.lvReturn = GETPEM(m.toEnum, m.aryMembers(tnIndex))
		CATCH TO loExc
			THROW m.loExc
		ENDTRY
		RETURN m.lvReturn
	ENDFUNC


	*********************************************************************
	FUNCTION GetNameByValue
	*********************************************************************
	LPARAMETERS toEnum, tvValue
		LOCAL lcVarType, lnCounter, lnMax, lcReturn, lvValue, lcProperty
		LOCAL loExc AS EXCEPTION
		DIMENSION aryMembers(1)
		TRY
			m.lcReturn = ""
			m.lcVarType = VARTYPE(m.tvValue)
			m.lnMax = AMEMBERS(m.aryMembers, m.toEnum, 0)
			FOR m.lnCounter = 1 TO m.lnMax
				m.lcProperty = m.aryMembers(m.lnCounter)
				m.lvValue = GETPEM(m.toEnum,m.lcProperty)
				IF VARTYPE(m.lvValue) == m.lcVarType
					IF m.lvValue == m.tvValue
						m.lcReturn = m.aryMembers(m.lnCounter)
						EXIT
					ENDIF
				ENDIF
			ENDFOR
		CATCH TO loExc
			THROW m.loExc
		ENDTRY
		RETURN m.lcReturn
	ENDFUNC


	*********************************************************************
	FUNCTION GetNames
	*********************************************************************
	LPARAMETERS toEnum
		LOCAL lnTotal, lnCounter, lnDimension, loExc AS EXCEPTION
		DIMENSION This._amembers(1)
		This._amembers(1) = EMPTY_VFPARRAY
		TRY
			=AMEMBERS(this._amembers, m.toEnum, 0)
			=This._DeleteHidden()
		CATCH TO loExc
			THROW m.loExc
		ENDTRY
		RETURN @this._amembers
	ENDFUNC


	*********************************************************************
	FUNCTION GetValues
	*********************************************************************
	LPARAMETERS toEnum
		LOCAL lnMax, lnCounter, loExc AS EXCEPTION
		DIMENSION aryMembers(1)
		DIMENSION This._amembers(1)
		This._amembers(1) = .F.
		TRY
			m.lnMax = AMEMBERS(aryMembers, m.toEnum, 0)
			m.lnMax = This._DeleteHidden(@m.aryMembers)
			DIMENSION This._amembers(m.lnMax)
			FOR m.lnCounter = 1 TO m.lnMax
				This._amembers(m.lnCounter) = GETPEM(m.toEnum, m.aryMembers(lnCounter))
			ENDFOR
		CATCH TO loExc
			THROW m.loExc
		ENDTRY
		RETURN @This._amembers
	ENDFUNC


	*********************************************************************
	FUNCTION IsDefined
	*********************************************************************
	LPARAMETERS toEnum, tvValue
		LOCAL llReturn, loExc AS EXCEPTION
		TRY
			m.llReturn = !EMPTY(This.GetNameByValue(m.toEnum, m.tvValue))
		CATCH TO loExc
			THROW m.loExc
		ENDTRY
		RETURN
	ENDFUNC


	*********************************************************************
	FUNCTION Parse
	*********************************************************************
	LPARAMETERS toEnum, tcMemberName
		LOCAL loExc AS EXCEPTION
		TRY
			m.lvReturn = GETPEM(m.toEnum, tcMemberName)
		CATCH TO loExc
			THROW m.loExc
		ENDTRY
		RETURN m.lvReturn
	ENDFUNC


	*********************************************************************
	FUNCTION _DeleteHidden
	*********************************************************************
	LPARAMETERS taMembers
		LOCAL lnCounter, lnDimension
		
			m.lnDimension = 0
		IF PCOUNT() = 0
			FOR m.lnCounter = 1 TO ALEN(This._amembers)
				IF this._IsHiddenProp(This._amembers(m.lnCounter))
					=ADEL(This._amembers,m.lnCounter)
				ELSE
					m.lnDimension = m.lnDimension + 1
				ENDIF
			ENDFOR
			DIMENSION This._amembers(m.lnDimension)
		ELSE
			FOR m.lnCounter = 1 TO ALEN(m.taMembers)
				IF this._IsHiddenProp(m.taMembers(m.lnCounter))
					=ADEL(m.taMembers,m.lnCounter)
				ELSE
					m.lnDimension = m.lnDimension + 1
				ENDIF
			ENDFOR
			DIMENSION taMembers(m.lnDimension)
		ENDIF
		
		RETURN m.lnDimension
	ENDFUNC


	*********************************************************************
	FUNCTION _IsHiddenProp
	*********************************************************************
	LPARAMETERS tcPropName
		RETURN (LEFT(m.tcPropName,1) == "_")
	ENDFUNC


	*********************************************************************
	#IFDEF USE_MEMBERDATA
	PROTECTED _memberdata
	_memberdata = [<VFPData>]+;
		[<memberdata name="createnew" type="method" display="CreateNew"/>]+;
		[<memberdata name="new" type="method" display="New"/>]+;
		[<memberdata name="getname" type="method" display="GetName"/>]+;
		[<memberdata name="getnames" type="method" display="GetNames"/>]+;
		[<memberdata name="getvalues" type="method" display="GetValues"/>]+;
		[<memberdata name="isdefined" type="method" display="IsDefined"/>]+;
		[<memberdata name="parse" type="method" display="Parse"/>]+;
		[<memberdata name="memberwiseclone" type="method" display="MemberwiseClone"/>]+;
		[<memberdata name="getnamebyvalue" type="method" display="GetNameByValue"/>]+;
		[<memberdata name="_ishiddenprop" type="method" display="_IsHiddenProp"/>]+;
		[<memberdata name="_deletehidden" type="method" display="_DeleteHidden"/>]+;
		[</VFPData>]		
	#ENDIF
ENDDEFINE
#ENDIF
*************************************************************************
*************************************************************************


*************************************************************************
*************************************************************************
*************************************************************************
#IFDEF USECLASS_XFCEVENTHANDLER
DEFINE CLASS xfceventhandler AS xfcObject
*************************************************************************
*************************************************************************
*************************************************************************
	PROTECTED _delegate
	_delegate = (NULL)
	PROTECTED _method
	_method = (NULL)
 
	*********************************************************************
	FUNCTION Init
	*********************************************************************
	LPARAMETERS toDelegate, tcMethod
		
		This._delegate = m.toDelegate
		This._method = m.tcMethod
		
		RETURN
	ENDFUNC


	*********************************************************************
	FUNCTION New
	*********************************************************************
	LPARAMETERS toDelegate, tcMethod
		
		RETURN CREATEOBJECT(This.Class, m.toDelegate, m.tcMethod)
	ENDFUNC


	*********************************************************************
	FUNCTION bind
	*********************************************************************
	LPARAMETERS toBindObject, tcBindMethod, tnFlags
		
		LOCAL loReturnValue
		m.loReturnValue = NULL
		m.tnFlags = EVL(m.tnFlags, 0)
		
		DO CASE
		CASE VARTYPE(This._delegate) = "O"
			BINDEVENT(m.toBindObject, m.tcBindMethod, This._delegate, This._method, tnFlags)
		
		CASE VARTYPE(This._delegate) = "C"
			BINDEVENT(m.toBindObject, m.tcBindMethod, This, "Fire", tnFlags)
			m.loReturnValue = This
		ENDCASE
	ENDFUNC


	*********************************************************************
	FUNCTION fire
	*********************************************************************
	LPARAMETERS toSource AS Object, toEventArgs AS Object
		
		IF VARTYPE(This._delegate) = "C"
			EXECSCRIPT(This._delegate, @toSource, @toEventArgs)
		ENDIF
	ENDFUNC

ENDDEFINE
#ENDIF
*************************************************************************
*************************************************************************


*************************************************************************
*************************************************************************
*************************************************************************
#IFDEF USECLASS_XFCGUID
DEFINE CLASS xfcGuid AS xfcObject
*************************************************************************
*************************************************************************
*************************************************************************
	BaseName = "Guid"
	empty = .NULL.
	PROTECTED _guid
	_guid = EMPTY_GUID
 
	*********************************************************************
	FUNCTION Init
	*********************************************************************
	LPARAMETERS tcGuid
		
		DODEFAULT()
		
		DO CASE
		CASE INLIST(VARTYPE(tcGuid),"C","Q") AND LEN(tcGuid)=16
			This._guid = tcGuid
		CASE INLIST(VARTYPE(tcGuid),"C","Q") AND LEN(CHRTRAN(tcGuid,"{-}",""))=32
			LOCAL lqGuid
			IF NOT LIKE([{????????-????-????-????-????????????}], tcGuid)
				tcGuid = TRANSFORM(CHRTRAN(tcGuid,"{-}",""), [@r {!!!!!!!!-!!!!-!!!!-!!!!-!!!!!!!!!!!!}])
			ENDIF
			DECLARE Long CLSIDFromString IN ole32 String olestr, String @clsid
			lqGuid = EMPTY_GUID
			*!ToDo: Check this for errors
			CLSIDFromString(STRCONV(tcGuid+CHR(0),5), @lqGuid)
			This._guid = lqGuid
		OTHERWISE
		*!ToDo: Error handling here?
		ENDCASE
	ENDFUNC


	*********************************************************************
	FUNCTION New
	*********************************************************************
	LPARAMETERS tcGuid
		RETURN CREATEOBJECT(This.Class, tcGuid)
	ENDFUNC


	*********************************************************************
	FUNCTION NewGuid
	*********************************************************************
		LOCAL lqGuid
		
		DECLARE Long CoCreateGuid IN ole32 String @clsid
		
		lqGuid = EMPTY_GUID
		CoCreateGuid(@lqGuid)
		
		RETURN CREATEOBJECT(This.Class, lqGuid)
	ENDFUNC


	*********************************************************************
	FUNCTION Empty_ACCESS
	*********************************************************************
		RETURN CREATEOBJECT(This.Class, EMPTY_GUID)
	ENDFUNC


	*********************************************************************
	FUNCTION Equals
	*********************************************************************
	LPARAMETERS loGuid AS xfcGuid
		
		RETURN (This._guid == loGuid.ToByteArray())
	ENDFUNC


	*********************************************************************
	FUNCTION ToByteArray
	*********************************************************************
		RETURN 0h+This._guid
	ENDFUNC


	*********************************************************************
	FUNCTION ToString
	*********************************************************************
		LOCAL lcString
		
		DECLARE Long StringFromGUID2 IN ole32 String clsid, String @olestr, Integer length
		
		lcString = REPLICATE(0h00, 80)
		StringFromGUID2(This._guid, @lcString, LEN(lcString))
		
		RETURN LEFT(STRCONV(lcString,6),38)
	ENDFUNC


	*********************************************************************
	FUNCTION ToVarbinary
	*********************************************************************
		RETURN This.ToByteArray()
	ENDFUNC


ENDDEFINE
#ENDIF
*************************************************************************
*************************************************************************


*************************************************************************
*************************************************************************
*************************************************************************
#IFDEF USECLASS_XFCIO
DEFINE CLASS xfcio AS xfcObject
*************************************************************************
*************************************************************************
*************************************************************************
	MemoryStream = .NULL.
	Stream = .NULL.
 
	*********************************************************************
	FUNCTION MemoryStream_ACCESS
	*********************************************************************
		IF VARTYPE(This.MemoryStream) <> "O"
			This.MemoryStream = CREATEOBJECT("xfcMemoryStream")
		ENDIF
		
		RETURN This.MemoryStream
	ENDFUNC


	*********************************************************************
	FUNCTION Stream_ACCESS
	*********************************************************************
		IF VARTYPE(This.Stream) <> "O"
			This.Stream = CREATEOBJECT("xfcStream")
		ENDIF
		
		RETURN THIS.Stream
	ENDFUNC


	*********************************************************************
	#IFDEF USE_MEMBERDATA
	PROTECTED _memberdata
	_memberdata = [<VFPData>]+;
		[<memberdata name="createnew" type="method" display="CreateNew"/>]+;
		[<memberdata name="new" type="method" display="New"/>]+;
		[<memberdata name="memberwiseclone" type="method" display="MemberwiseClone"/>]+;
		[<memberdata name="gethashcode" type="method" display="GetHashCode"/>]+;
		[<memberdata name="equals" type="method" display="Equals"/>]+;
		[<memberdata name="referenceequals" type="method" display="ReferenceEquals"/>]+;
		[<memberdata name="basename" type="property" display="BaseName"/>]+;
		[<memberdata name="stream" type="property" display="Stream"/>]+;
		[<memberdata name="stream_access" type="property" display="Stream_Access"/>]+;
		[<memberdata name="memorystream" type="property" display="MemoryStream"/>]+;
		[<memberdata name="memorystream_access" type="property" display="MemoryStream_Access"/>]+;
		[</VFPData>]		
	#ENDIF
ENDDEFINE
#ENDIF
*************************************************************************
*************************************************************************

*************************************************************************
*************************************************************************
*************************************************************************
#IFDEF USECLASS_XFCMEMORYSTREAM
DEFINE CLASS xfcmemorystream AS xfcStream
*************************************************************************
*************************************************************************
*************************************************************************

 
	*********************************************************************
	FUNCTION GetBuffer
	*********************************************************************
	** Method: xfcmemorystream.GetBuffer
	** http://msdn2.microsoft.com/en-us/library/system.io.memorystream.getbuffer.aspx
	**
	** Returns the array of unsigned bytes from which this stream was created.
	**
	** History:
	**  2007/04/17: CChalom - Coded
	*********************************************************************
		
	LPARAMETERS tiStart, tiCount
		
		*!ToDo: Test this function
		
		LOCAL loExc AS Exception
		
		TRY
			LOCAL lqBinary
			m.lqBinary = This.Read(0, This.Length)
		
		CATCH TO loExc
			THROW m.loExc
		ENDTRY
		
		RETURN m.lqBinary
	ENDFUNC


	*********************************************************************
	#IFDEF USE_MEMBERDATA
	PROTECTED _memberdata
	_memberdata = [<VFPData>]+;
		[<memberdata name="setlenght" type="method" display="SetLenght"/>]+;
		[<memberdata name="streamptr" type="property" display="StreamPtr"/>]+;
		[<memberdata name="toarray" type="method" display="ToArray"/>]+;
		[<memberdata name="getbuffer" type="method" display="GetBuffer"/>]+;
		[</VFPData>]		
	#ENDIF
ENDDEFINE
#ENDIF
*************************************************************************
*************************************************************************


*************************************************************************
*************************************************************************
*************************************************************************
#IFDEF USECLASS_XFCOBJECT
DEFINE CLASS xfcObject AS custom
*************************************************************************
*************************************************************************
*************************************************************************
	BaseName = "Object"
 
	*********************************************************************
	FUNCTION New
	*********************************************************************
		RETURN NEWOBJECT(This.Class,This.ClassLibrary)
	ENDFUNC


	*********************************************************************
	FUNCTION Equals
	*********************************************************************
	LPARAMETERS toObject1, toObject2
		LOCAL lnPcount, llReturn
		m.lnPcount = PCOUNT()
		DO CASE
		CASE m.lnPcount = 1 AND VARTYPE(m.toObject1) = "O"
			m.llReturn = (THIS == m.toObject1)
		CASE m.lnPcount = 2
			m.llReturn = (m.toObject1 == m.toObject2)
		OTHERWISE
			m.llReturn = .F.
		ENDCASE
		RETURN m.llReturn
	ENDFUNC


	*********************************************************************
	FUNCTION GetHashCode
	*********************************************************************
	LPARAMETERS toObject
		#DEFINE MEMBERDELIMITER "|"
		LOCAL lnMax, lnCounter, lcMemberName, lcType, lcCombined, lcValueToHash, lcHashCode
		
		IF VARTYPE(m.toObject) != "O"
			m.toObject = THIS
		ENDIF
		
		STORE "" TO m.lcValueToHash, m.lcHashCode
		m.lnMax = AMEMBERS(aryMembers,m.toObject,1)
		
		FOR m.lnCounter = 1 TO m.lnMax
			m.lcMemberName = aryMembers(m.lnCounter,1)
			m.lcType = aryMembers(m.lnCounter,2)
			m.lcCombined = m.lcMemberName + MEMBERDELIMITER + m.lcType
			DO CASE
				CASE m.lcType == "Property"
					*!* Need a better way to handle these...
					IF !INLIST(UPPER(m.lcMemberName), "CONTROLS", "OBJECTS", "PARENT", "BUTTONS", "PAGES")
						m.lcValueToHash = m.lcValueToHash + MEMBERDELIMITER + m.lcCombined + MEMBERDELIMITER + TRANSFORM(GETPEM(m.toObject, aryMembers(m.lnCounter,1)))
					ELSE
						m.lcValueToHash = m.lcValueToHash + MEMBERDELIMITER + m.lcCombined
					ENDIF
				CASE m.lcType == "Object"
					m.lcValueToHash = m.lcValueToHash + MEMBERDELIMITER + m.lcCombined + MEMBERDELIMITER + THIS.GetHashCode(GETPEM(m.toObject, aryMembers(m.lnCounter,1)))
				OTHERWISE && "Event" or "Method"
					m.lcValueToHash = m.lcValueToHash + MEMBERDELIMITER + m.lcCombined
			ENDCASE
		ENDFOR
		m.lcHashCode = SYS(2007, m.lcValueToHash, 0, 1)
		
		RETURN m.lcHashCode
	ENDFUNC


	*********************************************************************
	FUNCTION MemberwiseClone
	*********************************************************************
		LOCAL loClone, lnTotal, lnCounter, lcMember
		LOCAL ARRAY _aMembers(1)
		LOCAL ARRAY _aEvents(1)
		
		*!* Something needs to be figured out for objects that receive init parameters
		IF VARTYPE(This.Class) = "C" AND VARTYPE(This.CLASSLIBRARY)= "C"
			m.loClone = NEWOBJECT(This.CLASS, This.CLASSLIBRARY)
		ELSE
			m.loClone = CREATEOBJECT("EMPTY")
		ENDIF
		
		m.lnTotal = AMEMBERS(_aMembers, This, 0, "G#")
		FOR m.lnCounter = 1 TO m.lnTotal
			IF !("R" $ m._aMembers(m.lnCounter, 2))
				m.lcMember = m._aMembers(m.lnCounter, 1)
				ADDPROPERTY(m.loClone, m.lcMember, GETPEM(THIS, m.lcMember))
			ENDIF
		ENDFOR
		
		m.lnTotal = AEVENTS(_aEvents, THIS)
		FOR lnCounter = 1 TO m.lnTotal
			IF _aEvents(m.lnCounter,1) && Is this the event Source?
				BINDEVENT(_aEvents(m.lnCounter,2), _aEvents(m.lnCounter,3), m.loClone, _aEvents(m.lnCounter,4), _aEvents(m.lnCounter,5))
			ELSE
				BINDEVENT(m.loClone, _aEvents(m.lnCounter,3), _aEvents(m.lnCounter,2), _aEvents(m.lnCounter,4), _aEvents(m.lnCounter,5))
			ENDIF
		ENDFOR
		
		RETURN m.loClone
	ENDFUNC


	*********************************************************************
	FUNCTION ReferenceEquals
	*********************************************************************
	LPARAMETERS toObject1, toObject2
		LOCAL lnPcount, llReturn
		m.lnPcount = PCOUNT()
		DO CASE
			CASE m.lnPcount = 1 AND VARTYPE(m.toObject1) = "O"
				m.llReturn = (THIS == m.toObject1)
			CASE m.lnPcount = 2 AND VARTYPE(m.toObject1) = "O" AND VARTYPE(m.toObject2) = "O"
				m.llReturn = (m.toObject1 == m.toObject2)
			OTHERWISE
				m.llReturn = .F.
		ENDCASE
		RETURN m.llReturn
	ENDFUNC


	*********************************************************************
	#IFDEF USE_MEMBERDATA
	PROTECTED _memberdata
	_memberdata = [<VFPData>]+;
		[<memberdata name="createnew" type="method" display="CreateNew"/>]+;
		[<memberdata name="new" type="method" display="New"/>]+;
		[<memberdata name="memberwiseclone" type="method" display="MemberwiseClone"/>]+;
		[<memberdata name="gethashcode" type="method" display="GetHashCode"/>]+;
		[<memberdata name="equals" type="method" display="Equals"/>]+;
		[<memberdata name="referenceequals" type="method" display="ReferenceEquals"/>]+;
		[<memberdata name="basename" type="property" display="BaseName"/>]+;
		[</VFPData>]		
	#ENDIF
ENDDEFINE
#ENDIF
*************************************************************************
*************************************************************************

*************************************************************************
*************************************************************************
*************************************************************************
#IFDEF USECLASS_XFCSINGLE
DEFINE CLASS xfcsingle AS xfcObject
*************************************************************************
*************************************************************************
*************************************************************************

 
	*********************************************************************
	FUNCTION NewArray
	*********************************************************************
	LPARAMETERS teP1, teP2, teP3, tep4, teP5, teP6, teP7, ;
					teP8, teP9, teP10, teP11, teP12, teP13, teP14, ;
					teP15, teP16, teP17, teP18, teP19, teP20, teP21, ;
					teP22, teP23, teP24, teP25, teP26, teP27, teP28
		
		LOCAL lnValue, lnLoop, lqBinary, laValue[1]
		
		m.lqBinary = 0h
		
		DO CASE
		CASE VARTYPE(m.teP1)="N"
			FOR m.lnLoop = 1 TO PCOUNT()
				m.lnValue = EVALUATE("m.teP"+PADR(m.lnLoop,2))
				IF VARTYPE(m.lnValue)="N"
					m.lqBinary = m.lqBinary + BINTOC(m.lnValue,"F")
				ELSE
					EXIT
				ENDIF
			ENDFOR
			
		CASE VARTYPE(m.teP1)="C" AND USED(m.teP1)
			*! ToDo: Handle a cursor here
			
		CASE VARTYPE(m.teP1)="C"
			FOR lnLoop = 1 TO ALINES(laValue, m.teP1, 1, ",")
				m.lnValue = EVALUATE(laValue[m.lnLoop])
				IF VARTYPE(m.lnValue)="N"
					m.lqBinary = m.lqBinary + BINTOC(m.lnValue,"F")
				ELSE
					EXIT
				ENDIF
			ENDFOR
		ENDCASE
		
		RETURN m.lqBinary
	ENDFUNC

ENDDEFINE
#ENDIF
*************************************************************************
*************************************************************************

*************************************************************************
*************************************************************************
*************************************************************************
#IFDEF USECLASS_XFCSTREAM
DEFINE CLASS xfcStream AS xfcObject
*************************************************************************
*************************************************************************
*************************************************************************
	BaseName = "Stream"
	CanRead = .T.
	CanSeek = .T.
	CanTimeout = .T.
	CanWrite = .T.
	Handle = 0
	Height = 16
	hGlobalPtr = 0
	Length = 0
	Position = 0
	ReadTimeout = ""	&& Specifies how long the FormSet remains active with no user input.
	Width = 100
	WriteTimeout = ""
 
	*********************************************************************
	FUNCTION Init
	*********************************************************************
	** Method: xfcStream.Init
	**
	** http://msdn2.microsoft.com/en-us/library/system.io.stream.aspx
	**
	** History:
	**  2007/04/15: CChalom - Coded
	*********************************************************************
		
		*!ToDo: Test this function
		
		LOCAL loExc AS Exception
		
		TRY
			LOCAL lHStream, lHGlobal
			m.lHStream = 0
			m.lHGlobal = xfcGlobalAlloc(0x2022, 0)
		
			xfcCreateStreamOnHGlobal(m.lHGlobal, 1, @lHStream)
			This.Handle = m.lHStream
		
		CATCH TO loExc
			THROW m.loExc
		ENDTRY
		
		RETURN
	ENDFUNC


	*********************************************************************
	FUNCTION Destroy
	*********************************************************************
	** Method: xfcStream.Destroy
	**
	** History:
	**  2007/04/15: CChalom - Coded
	*********************************************************************
		
		*!ToDo: Test this function
		
		LOCAL loExc AS Exception
		
		TRY
			LOCAL lHGlobal, lHPtr
		
			m.lHStream = This.Handle
		
			IF This.hGlobalPtr = 0
				m.lHGlobal = 0
				xfcGetHGlobalFromStream(m.lHStream, @lHGlobal)
			ELSE
				m.lHGlobal = This.hGlobalPtr
			ENDIF
		
			*	m.lHPtr = xfcGlobalLock(m.lHGlobal)
			*	xfcGlobalUnlock(m.lHGlobal)
		
			xfcGlobalFree (m.lhGlobal)
		
		CATCH TO loExc
			THROW m.loExc
		ENDTRY
		RETURN
	ENDFUNC


	*********************************************************************
	FUNCTION New
	*********************************************************************
	** Property: New
	**
	** History:
	**  2007/04/15: CChalom - Coded
	*********************************************************************
		
		RETURN CREATEOBJECT(This.Class)
	ENDFUNC


	*********************************************************************
	FUNCTION BeginRead
	*********************************************************************
		*!*	<HostProtection(SecurityAction.LinkDemand, ExternalThreading:=True)> _
		*!*	Public Overridable Function BeginRead(ByVal buffer As Byte(), ByVal offset As Integer, ByVal count As Integer, ByVal callback As AsyncCallback, ByVal state As Object) As IAsyncResult
		*!*	    If Not Me.CanRead Then
		*!*	        __Error.ReadNotSupported
		*!*	    End If
		*!*	    Interlocked.Increment((Me._asyncActiveCount))
		*!*	    Dim delegate2 As ReadDelegate = New ReadDelegate(AddressOf Me.Read)
		*!*	    If (Me._asyncActiveEvent Is Nothing) Then
		*!*	        SyncLock Me
		*!*	            If (Me._asyncActiveEvent Is Nothing) Then
		*!*	                Me._asyncActiveEvent = New AutoResetEvent(True)
		*!*	            End If
		*!*	        End SyncLock
		*!*	    End If
		*!*	    Me._asyncActiveEvent.WaitOne
		*!*	    Me._readDelegate = delegate2
		*!*	    Return delegate2.BeginInvoke(buffer, offset, count, callback, state)
		*!*	End Function
	ENDFUNC


	*********************************************************************
	FUNCTION BeginWrite
	*********************************************************************
		*!*	<HostProtection(SecurityAction.LinkDemand, ExternalThreading:=True)> _
		*!*	Public Overridable Function BeginWrite(ByVal buffer As Byte(), ByVal offset As Integer, ByVal count As Integer, ByVal callback As AsyncCallback, ByVal state As Object) As IAsyncResult
		*!*	    If Not Me.CanWrite Then
		*!*	        __Error.WriteNotSupported
		*!*	    End If
		*!*	    Interlocked.Increment((Me._asyncActiveCount))
		*!*	    Dim delegate2 As WriteDelegate = New WriteDelegate(AddressOf Me.Write)
		*!*	    If (Me._asyncActiveEvent Is Nothing) Then
		*!*	        SyncLock Me
		*!*	            If (Me._asyncActiveEvent Is Nothing) Then
		*!*	                Me._asyncActiveEvent = New AutoResetEvent(True)
		*!*	            End If
		*!*	        End SyncLock
		*!*	    End If
		*!*	    Me._asyncActiveEvent.WaitOne
		*!*	    Me._writeDelegate = delegate2
		*!*	    Return delegate2.BeginInvoke(buffer, offset, count, callback, state)
		*!*	End Function
		
		
		
		
	ENDFUNC


	*********************************************************************
	FUNCTION CanRead_ACCESS
	*********************************************************************
		*To do: Modify this routine for the Access method
		RETURN THIS.CanRead
	ENDFUNC


	*********************************************************************
	FUNCTION CanSeek_ACCESS
	*********************************************************************
		*To do: Modify this routine for the Access method
		RETURN THIS.CanSeek
	ENDFUNC


	*********************************************************************
	FUNCTION CanTimeout_ACCESS
	*********************************************************************
		*To do: Modify this routine for the Access method
		RETURN THIS.CanTimeout
	ENDFUNC


	*********************************************************************
	FUNCTION CanWrite_ACCESS
	*********************************************************************
		*To do: Modify this routine for the Access method
		RETURN THIS.CanWrite
	ENDFUNC


	*********************************************************************
	FUNCTION Dispose
	*********************************************************************
		RELEASE This
	ENDFUNC


	*********************************************************************
	FUNCTION EndRead
	*********************************************************************
		*!*	Public Overridable Function EndRead(ByVal asyncResult As IAsyncResult) As Integer
		*!*	    If (asyncResult Is Nothing) Then
		*!*	        Throw New ArgumentNullException("asyncResult")
		*!*	    End If
		*!*	    If (Me._readDelegate Is Nothing) Then
		*!*	        Throw New ArgumentException(Environment.GetResourceString("InvalidOperation_WrongAsyncResultOrEndReadCalledMultiple"))
		*!*	    End If
		*!*	    Dim num As Integer = -1
		*!*	    Try
		*!*	        num = Me._readDelegate.EndInvoke(asyncResult)
		*!*	    Finally
		*!*	        Me._readDelegate = Nothing
		*!*	        Me._asyncActiveEvent.Set
		*!*	        Me._CloseAsyncActiveEvent(Interlocked.Decrement((Me._asyncActiveCount)))
		*!*	    End Try
		*!*	    Return num
		*!*	End Function
	ENDFUNC


	*********************************************************************
	FUNCTION EndWrite
	*********************************************************************
		*!*	Public Overridable Sub EndWrite(ByVal asyncResult As IAsyncResult)
		*!*	    If (asyncResult Is Nothing) Then
		*!*	        Throw New ArgumentNullException("asyncResult")
		*!*	    End If
		*!*	    If (Me._writeDelegate Is Nothing) Then
		*!*	        Throw New ArgumentException(Environment.GetResourceString("InvalidOperation_WrongAsyncResultOrEndWriteCalledMultiple"))
		*!*	    End If
		*!*	    Try
		*!*	        Me._writeDelegate.EndInvoke(asyncResult)
		*!*	    Finally
		*!*	        Me._writeDelegate = Nothing
		*!*	        Me._asyncActiveEvent.Set
		*!*	        Me._CloseAsyncActiveEvent(Interlocked.Decrement((Me._asyncActiveCount)))
		*!*	    End Try
		*!*	End Sub
	ENDFUNC


	*********************************************************************
	FUNCTION Flush
	*********************************************************************
		*!*	Public MustOverride Sub Flush()
		
		
		
		
	ENDFUNC


	*********************************************************************
	FUNCTION hGlobalPtr_ACCESS
	*********************************************************************
	** Property: hGlobalPtr
	**
	** Gets the hGlobal adress from the Stream.
	**
	** History:
	**  2007/04/15: CChalom - Coded
	*********************************************************************
		
		*!ToDo: Test this function
		
		LOCAL loExc AS Exception
		TRY
			IF This.hGlobalPtr = 0
				LOCAL lHStream, lHGlobal
				m.lHGlobal = 0
				m.lhStream = This.Handle
				xfcGetHGlobalFromStream(m.lHStream, @lHGlobal)
				This.hGlobalPtr = m.lhGlobal
			ENDIF
		
		CATCH TO loExc
			THROW m.loExc
		ENDTRY
		
		RETURN This.hGlobalPtr
	ENDFUNC


	*********************************************************************
	FUNCTION Length_ACCESS
	*********************************************************************
	** Property: Length
	** http://msdn2.microsoft.com/en-us/library/system.io.stream.length.aspx
	**
	** Gets the length in bytes of the stream.
	**
	** History:
	**  2007/04/15: CChalom - Coded
	*********************************************************************
		
		*!ToDo: Test this function
		
		LOCAL loExc AS Exception
		TRY
			IF This.Length = 0
				LOCAL lhGlobal, liSize
				m.lhGlobal = This.hGlobalPtr
				m.liSize = xfcGlobalSize(m.lHGlobal)
				This.Length = m.liSize
			ENDIF
		
		CATCH TO loExc
			THROW m.loExc
		ENDTRY
		
		RETURN THIS.Length
	ENDFUNC


	*********************************************************************
	FUNCTION Read
	*********************************************************************
	** Method: xfcStream.Read
	** http://msdn2.microsoft.com/en-us/library/system.io.stream.read.aspx
	**
	** Reads a sequence of bytes from the current stream
	**    and advances the position within the stream by the number of bytes read.
	**
	** History:
	**  2007/04/15: CChalom - Coded
	*********************************************************************
		
	LPARAMETERS tiStart, tiCount
		
		*!ToDo: Test this function
		
		LOCAL loExc AS Exception
		
		TRY
		
			IF This.CanRead
				LOCAL lhGlobal, lhPtr, lcBuffer
				m.lhGlobal = This.hGlobalPtr
				m.lHPtr = xfcGlobalLock(m.lHGlobal)
				m.lcBuffer = SYS(2600, m.lHPtr + m.tiStart, m.tiCount)
				xfcGlobalUnlock(m.lhGlobal)
			
				LOCAL lnPos
				lnPos = m.tiStart + m.tiCount
				This.Position = IIF(m.lnPos >= This.Length, 0, m.lnPos)
			ENDIF
		
		CATCH TO loExc
			THROW m.loExc
		ENDTRY
		
		RETURN m.lcBuffer
	ENDFUNC


	*********************************************************************
	FUNCTION ReadByte
	*********************************************************************
	** Method: xfcStream.ReadByte
	** http://msdn2.microsoft.com/en-us/library/system.io.stream.readbyte.aspx
	**
	** Reads a byte from the stream and advances the position within the stream by one byte,
	**    or returns -1 if at the end of the stream.
	**
	** History:
	**  2007/04/15: CChalom - Coded
	*********************************************************************
		
	LPARAMETERS tiPos
		
		*!ToDo: Test this function
		
		LOCAL loExc AS Exception
		TRY
		
			IF This.CanRead
				IF VARTYPE(tiPos) <> "N"
					m.tiPos = This.Position
				ENDIF
		
				IF(m.tiPos <= This.Length)
					m.tiByte = ASC(This.Read(m.tiPos, 1))
				ELSE
					m.tiByte = -1
				ENDIF
			ENDIF
			
		CATCH TO loExc
			THROW m.loExc
		ENDTRY
		
		RETURN m.tiByte
	ENDFUNC


	*********************************************************************
	FUNCTION ReadTimeout_ACCESS
	*********************************************************************
		*To do: Modify this routine for the Access method
		RETURN THIS.ReadTimeout
	ENDFUNC


	*********************************************************************
	FUNCTION ReadTimeout_ASSIGN
	*********************************************************************
	LPARAMETERS vNewVal
		*To do: Modify this routine for the Assign method
		THIS.ReadTimeout = m.vNewVal
	ENDFUNC


	*********************************************************************
	FUNCTION Seek
	*********************************************************************
		* Public MustOverride Function Seek(ByVal offset As Long, ByVal origin As SeekOrigin) As Long
	ENDFUNC


	*********************************************************************
	FUNCTION SetLength
	*********************************************************************
		* Public MustOverride Sub SetLength(ByVal value As Long)
	ENDFUNC


	*********************************************************************
	FUNCTION Synchronized
	*********************************************************************
		*!*	<HostProtection(SecurityAction.LinkDemand, Synchronization:=True)> _
		*!*	Public Shared Function Synchronized(ByVal stream As Stream) As Stream
		*!*	    If (stream Is Nothing) Then
		*!*	        Throw New ArgumentNullException("stream")
		*!*	    End If
		*!*	    If TypeOf stream Is SyncStream Then
		*!*	        Return stream
		*!*	    End If
		*!*	    Return New SyncStream(stream)
		*!*	End Function
	ENDFUNC


	*********************************************************************
	FUNCTION Write
	*********************************************************************
	** Method: xfcStream.Write
	** http://msdn2.microsoft.com/en-us/library/system.io.stream.write.aspx
	**
	** Writes a sequence of bytes to the current stream
	**    and advances the current position within this stream by the number of bytes written.
	**
	** History:
	**  2007/04/17: CChalom - Coded
	*********************************************************************
		
	LPARAMETERS tqBuffer, tiStart, tiCount
		
		*!ToDo: Test this function
		
		LOCAL loExc AS Exception
		
		TRY
		
			IF This.CanWrite
			
				IF VARTYPE(tiStart) <> "N"
					m.tiStart = 0
				ENDIF
			
				IF VARTYPE(tiCount) <> "N"
					m.tiCount = LEN(m.tqBuffer)
				ENDIF
				m.tiCount = MIN(This.Length, m.tiCount)
		
				LOCAL lhGlobal, lhPtr, lnLength
				m.lhGlobal = This.hGlobalPtr
				m.lHPtr = xfcGlobalLock(m.lHGlobal)
				= SYS(2600, m.lHPtr + m.tiStart, m.tiCount, m.tqBuffer)
				xfcGlobalUnlock(m.lhGlobal)
		
				This.Position = m.tiCount
			ENDIF
			
		CATCH TO loExc
			THROW m.loExc
		ENDTRY
		
		RETURN
	ENDFUNC


	*********************************************************************
	FUNCTION WriteByte
	*********************************************************************
	** Method: xfcStream.WriteByte
	** http://msdn2.microsoft.com/en-us/library/system.io.stream.writebyte.aspx
	**
	** Writes a byte to the current position in the stream
	**    and advances the position within the stream by one byte.
	**
	** History:
	**  2007/04/17: CChalom - Coded
	*********************************************************************
		
	LPARAMETERS tiByte
		
		*!ToDo: Test this function
		
		LOCAL loExc AS Exception
		
		TRY
		
			IF This.CanWrite
				This.Write(CHR(m.tiByte), This.Position, 1)
				This.Position = This.Position + 1
			ENDIF
			
		CATCH TO loExc
			THROW m.loExc
		ENDTRY
		
		RETURN
	ENDFUNC


	*********************************************************************
	FUNCTION WriteTimeout_ACCESS
	*********************************************************************
		*To do: Modify this routine for the Access method
		RETURN THIS.WriteTimeout
	ENDFUNC


	*********************************************************************
	FUNCTION WriteTimeout_ASSIGN
	*********************************************************************
	LPARAMETERS vNewVal
		*To do: Modify this routine for the Assign method
		THIS.WriteTimeout = m.vNewVal
	ENDFUNC



	*********************************************************************
	#IFDEF USE_MEMBERDATA
	PROTECTED _memberdata
	_memberdata = [<VFPData>]+;
		[<memberdata name="createnew" type="method" display="CreateNew"/>]+;
		[<memberdata name="new" type="method" display="New"/>]+;
		[<memberdata name="memberwiseclone" type="method" display="MemberwiseClone"/>]+;
		[<memberdata name="gethashcode" type="method" display="GetHashCode"/>]+;
		[<memberdata name="equals" type="method" display="Equals"/>]+;
		[<memberdata name="referenceequals" type="method" display="ReferenceEquals"/>]+;
		[<memberdata name="basename" type="property" display="BaseName"/>]+;
		[<memberdata name="beginread" type="method" display="BeginRead"/>]+;
		[<memberdata name="beginwrite" type="method" display="BeginWrite"/>]+;
		[<memberdata name="close" type="method" display="Close"/>]+;
		[<memberdata name="createwaithandle" type="method" display="CreateWaitHandle"/>]+;
		[<memberdata name="dispose" type="method" display="Dispose"/>]+;
		[<memberdata name="endread" type="method" display="EndRead"/>]+;
		[<memberdata name="endwrite" type="method" display="EndWrite"/>]+;
		[<memberdata name="flush" type="method" display="Flush"/>]+;
		[<memberdata name="read" type="method" display="Read"/>]+;
		[<memberdata name="readbyte" type="method" display="ReadByte"/>]+;
		[<memberdata name="seek" type="method" display="Seek"/>]+;
		[<memberdata name="setlenght" type="method" display="SetLenght"/>]+;
		[<memberdata name="synchronized" type="method" display="Synchronized"/>]+;
		[<memberdata name="write" type="method" display="Write"/>]+;
		[<memberdata name="writebyte" type="method" display="WriteByte"/>]+;
		[<memberdata name="canread" type="property" display="CanRead"/>]+;
		[<memberdata name="canseek" type="property" display="CanSeek"/>]+;
		[<memberdata name="cantimeout" type="property" display="CanTimeout"/>]+;
		[<memberdata name="canwrite" type="property" display="CanWrite"/>]+;
		[<memberdata name="length" type="property" display="Length"/>]+;
		[<memberdata name="position" type="property" display="Position"/>]+;
		[<memberdata name="readtimeout" type="property" display="ReadTimeout"/>]+;
		[<memberdata name="writetimeout" type="property" display="WriteTimeout"/>]+;
		[<memberdata name="declaredll" type="method" display="DeclareDll"/>]+;
		[<memberdata name="streamptr" type="property" display="StreamPtr"/>]+;
		[<memberdata name="hglobalptr" type="property" display="hGlobalPtr"/>]+;
		[<memberdata name="toarray" type="method" display="ToArray"/>]+;
		[<memberdata name="setlength" type="method" display="SetLength"/>]+;
		[<memberdata name="handle" type="property" display="Handle"/>]+;
		[</VFPData>]		
	#ENDIF
ENDDEFINE
#ENDIF
*************************************************************************
*************************************************************************



#IFDEF USECLASS_XFCSTREAM
*********************************************************************
FUNCTION xfcGlobalAlloc(nFlags, nSize)
*********************************************************************
	DECLARE Long GlobalAlloc IN WIN32API AS xfcGlobalAlloc Long nFlags, Long nSize
	RETURN xfcGlobalAlloc(m.nFlags, m.nSize)
ENDFUNC

*********************************************************************
FUNCTION xfcGlobalFree(nHandle)
*********************************************************************
	DECLARE Long GlobalFree IN WIN32API AS xfcGlobalFree Long nHandle
	RETURN xfcGlobalFree(m.nHandle)
ENDFUNC

*********************************************************************
FUNCTION xfcGlobalLock(hMem)
*********************************************************************
	DECLARE Long GlobalLock IN WIN32API AS xfcGlobalLock Long hMem
	RETURN xfcGlobalLock(m.hMem)
ENDFUNC

*********************************************************************
FUNCTION xfcGlobalSize(hMem)
*********************************************************************
	DECLARE Long GlobalSize IN WIN32API AS xfcGlobalSize Long hMem
	RETURN xfcGlobalSize(m.hMem)
ENDFUNC

*********************************************************************
FUNCTION xfcGlobalUnlock(hMem)
*********************************************************************
	DECLARE Long GlobalUnlock IN WIN32API AS xfcGlobalUnlock Long hMem
	RETURN xfcGlobalUnlock(m.hMem)
ENDFUNC

*********************************************************************
FUNCTION xfcCreateStreamOnHGlobal(hGlobal, fDeleteOnRelease, ppstm)
*********************************************************************
	DECLARE Long CreateStreamOnHGlobal IN ole32 AS xfcCreateStreamOnHGlobal Long hGlobal, Long fDeleteOnRelease, Long @ppstm
	RETURN xfcCreateStreamOnHGlobal(m.hGlobal, m.fDeleteOnRelease, @m.ppstm)
ENDFUNC

*********************************************************************
FUNCTION xfcGetHGlobalFromStream(pstm, phglobal)
*********************************************************************
	DECLARE Long GetHGlobalFromStream IN ole32 AS xfcGetHGlobalFromStream Long pstm, Long @phglobal
	RETURN xfcGetHGlobalFromStream(m.pstm, @m.phglobal)
ENDFUNC


#ENDIF


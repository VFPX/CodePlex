#INCLUDE System.h

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
			This.IO = NEWOBJECT("xfcIO",XFCCLASS_IO)
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
	Byte = .NULL.
	*********************************************************************
	FUNCTION Byte_ACCESS
	*********************************************************************
		IF VARTYPE(This.Byte) <> "O"
			This.Byte = CREATEOBJECT("xfcByte")
		ENDIF
		
		RETURN This.Byte
	ENDFUNC

	*********************************************************************
	FUNCTION Init
	*********************************************************************

		IF _Vfp.StartMode = 0 && development version of Visual FoxPro was started in an interactive session.
			SET PROCEDURE TO (This.ClassLibrary) ADDITIVE
			SET PROCEDURE TO (ADDBS(JUSTPATH(This.ClassLibrary))+"System.Drawing.PRG") ADDITIVE
			SET PROCEDURE TO (ADDBS(JUSTPATH(This.ClassLibrary))+"System.Drawing.Drawing2D.PRG") ADDITIVE
			SET PROCEDURE TO (ADDBS(JUSTPATH(This.ClassLibrary))+"System.Drawing.Imaging.PRG") ADDITIVE
			SET PROCEDURE TO (ADDBS(JUSTPATH(This.ClassLibrary))+"System.Drawing.Text.PRG") ADDITIVE
			SET PROCEDURE TO (ADDBS(JUSTPATH(This.ClassLibrary))+"System.IO.PRG") ADDITIVE
		ENDIF
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
		[<memberdata name="byte" type="property" display="Byte"/>]+;
		[<memberdata name="single" type="property" display="Single"/>]+;
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
#IFDEF USECLASS_XFCOBJECT
DEFINE CLASS xfcObject AS Custom
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
#IFDEF USECLASS_XFCBYTE
DEFINE CLASS xfcByte AS xfcObject
*************************************************************************
*************************************************************************
*************************************************************************

	DIMENSION _InternalArray[1]
 
 	*********************************************************************
	FUNCTION NewArray
	*********************************************************************
	LPARAMETERS tiByte
	
		IF VARTYPE(m.tiByte) = "Q"
			LOCAL lqBinary, lqStruct, lnStep, lnSize
			m.lqBinary = m.tiByte
			m.lnSize = LEN(lqBinary)
			DIMENSION This._InternalArray[m.lnSize]
			FOR m.lnStep = 1 TO m.lnSize
				This._InternalArray[m.lnStep] = ASC(SUBSTR(m.lqBinary, m.lnStep, 1))
			ENDFOR
			RETURN @This._InternalArray
		ELSE
			RETURN tiByte
		ENDIF
	ENDFUNC


	*********************************************************************
	FUNCTION NewVarBinary
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
					m.lqBinary = m.lqBinary + CHR(m.lnValue)
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
					m.lqBinary = m.lqBinary + CHR(m.lnValue)
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





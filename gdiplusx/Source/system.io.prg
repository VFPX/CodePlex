#INCLUDE System.h

LPARAMETER toObject

IF PCOUNT() = 0
	m.toObject = _SCREEN
ENDIF

IF VARTYPE(m.toObject) = "O"
	ADDPROPERTY(m.toObject,"IO",CREATEOBJECT("xfcIO"))
ENDIF



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
		[<memberdata name="stream" type="property" display="Stream"/>]+;
		[<memberdata name="memorystream" type="property" display="MemoryStream"/>]+;
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
DEFINE CLASS xfcMemoryStream AS xfcStream
*************************************************************************
*************************************************************************
*************************************************************************
	BaseName = "MemoryStream"
	CanRead = .T.
	CanSeek = .T.
	CanTimeout = .T.
	CanWrite = .T.
	Handle = 0
	hGlobalPtr = 0
	Length = 0
	Position = 0
	ReadTimeout = ""	&& Specifies how long the FormSet remains active with no user input.
	WriteTimeout = ""
	
	_capacity = 0
	_expandable = 0
	_exposable = 0
	_isOpen = .F.
	_writable = .F.
	
	PROTECTED _capacity
	PROTECTED _expandable
	PROTECTED _exposable
	PROTECTED _isOpen
	PROTECTED _writable
 
	*********************************************************************
	FUNCTION Init
	*********************************************************************
	** Method: xfcMemoryStream.Init
	**
	** http://msdn2.microsoft.com/en-us/library/system.io.memorystream.aspx
	**
	** History:
	**  2007/04/15: CChalom - Coded
	*********************************************************************
	LPARAMETERS tqBuffer, tiIndex, tiCount, tlWritable, tlPubliclyVisible
		
		*!ToDo: Test this function
		
		LOCAL loExc AS Exception
		
		TRY
			LOCAL lHStream, lHGlobal
			m.lHStream = 0
			m.lHGlobal = xfcGlobalAlloc(0x2022, 0)
		
			xfcCreateStreamOnHGlobal(m.lHGlobal, 1, @m.lHStream)
			This.Handle = m.lHStream
		CATCH TO loExc
			THROW m.loExc
		ENDTRY
		
		RETURN
	ENDFUNC


	*********************************************************************
	FUNCTION Destroy
	*********************************************************************
	** Method: xfcMemoryStream.Destroy
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
			xfcGlobalFree(m.lhGlobal)
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
	LPARAMETERS 
		RETURN CREATEOBJECT(This.Class)
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
	FUNCTION CanWrite_ACCESS
	*********************************************************************
		*To do: Modify this routine for the Access method
		RETURN THIS.CanWrite
	ENDFUNC


	*********************************************************************
	FUNCTION GetBuffer
	*********************************************************************
	** Method: xfcMemoryStream.GetBuffer
	** http://msdn2.microsoft.com/en-us/library/system.io.memorystream.getbuffer.aspx
	**
	** Returns the array of unsigned bytes from which this stream was created.
	**
	** History:
	**  2007/04/17: CChalom - Coded
	*********************************************************************
		
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
	** Method: xfcMemoryStream.Read
	** http://msdn2.microsoft.com/en-us/library/system.io.memorystream.read.aspx
	**
	** Reads a sequence of bytes from the current stream
	**    and advances the position within the stream by the number of bytes read.
	**
	** History:
	**  2007/04/15: CChalom - Coded
	*********************************************************************
	LPARAMETERS tiStart, tiCount
		
		*!ToDo: Test this function
		LOCAL lhGlobal, lhPtr, lcBuffer
		LOCAL lnPos
		
		LOCAL loExc AS Exception
		TRY
			IF This.CanRead
				m.lhGlobal = This.hGlobalPtr
				m.lHPtr = xfcGlobalLock(m.lHGlobal)
				m.lcBuffer = SYS(2600, m.lHPtr + m.tiStart, m.tiCount)
				xfcGlobalUnlock(m.lhGlobal)
				m.lnPos = m.tiStart + m.tiCount
				This.Position = IIF(m.lnPos >= This.Length, 0, m.lnPos)
			ENDIF
		
		CATCH TO loExc
			THROW m.loExc
		ENDTRY
		
		RETURN m.lcBuffer
	ENDFUNC


	*********************************************************************
	FUNCTION Seek
	*********************************************************************
		*! ToDo: Code this
		* Public MustOverride Function Seek(ByVal offset As Long, ByVal origin As SeekOrigin) As Long
	ENDFUNC


	*********************************************************************
	FUNCTION SetLength
	*********************************************************************
		*! ToDo: Code this
		* Public MustOverride Sub SetLength(ByVal value As Long)
	ENDFUNC


	*********************************************************************
	FUNCTION Write
	*********************************************************************
	** Method: xfcMemoryStream.Write
	** http://msdn2.microsoft.com/en-us/library/system.io.stream.write.aspx
	**
	** Writes a sequence of bytes to the current stream
	**    and advances the current position within this stream by the number of bytes written.
	**
	** History:
	**  2007/04/17: CChalom - Coded
	*********************************************************************
	LPARAMETERS tqBuffer, tiOffset, tiCount
		
		*!ToDo: Test this function
		LOCAL lhGlobal, lhPtr, lnLength
		
		LOCAL loExc AS Exception
		TRY
			IF This.CanWrite
				IF VARTYPE(m.tiOffset) <> "N"
					m.tiOffset = 0
				ENDIF
			
				IF VARTYPE(m.tiCount) <> "N"
					m.tiCount = LEN(m.tqBuffer)
				ENDIF
				m.tiCount = MIN(This.Length, m.tiCount)
				m.lhGlobal = This.hGlobalPtr
				m.lHPtr = xfcGlobalLock(m.lhGlobal)
				= SYS(2600, m.lHPtr + m.tiOffset, m.tiCount, m.tqBuffer)
				xfcGlobalUnlock(m.lhGlobal)
		
				This.Position = m.tiOffset+m.tiCount
			ENDIF
			
		CATCH TO loExc
			THROW m.loExc
		ENDTRY
		
		RETURN
	ENDFUNC



	*********************************************************************
	#IFDEF USE_MEMBERDATA
	PROTECTED _memberdata
	_memberdata = [<VFPData>]+;
		[<memberdata name="createnew" type="method" display="CreateNew"/>]+;
		[<memberdata name="new" type="method" display="New"/>]+;
		[<memberdata name="memberwiseclone" type="method" display="MemberwiseClone"/>]+;
		[<memberdata name="gethashcode" type="method" display="GetHashCode"/>]+;
		[<memberdata name="getbuffer" type="method" display="GetBuffer"/>]+;
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
	hGlobalPtr = 0
	Length = 0
	Position = 0
	ReadTimeout = ""	&& Specifies how long the FormSet remains active with no user input.
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
		
			xfcCreateStreamOnHGlobal(m.lHGlobal, 1, @m.lHStream)
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
			xfcGlobalFree(m.lhGlobal)
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
		* Public MustOverride
		ERROR "This Method Must Be Overwritten"
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
					This.Position = m.tiPos+1
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
	FUNCTION ReadTimeout_ASSIGN
	*********************************************************************
	LPARAMETERS vNewVal
		*To do: Modify this routine for the Assign method
		THIS.ReadTimeout = INT(m.vNewVal)
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
	LPARAMETERS tqBuffer, tiOffset, tiCount
		* Public MustOverride
		ERROR "This Method Must Be Overwritten"
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
			This.Write(CHR(m.tiByte), This.Position, 1)
		CATCH TO loExc
			THROW m.loExc
		ENDTRY
		
		RETURN
	ENDFUNC


	*********************************************************************
	FUNCTION WriteTimeout_ASSIGN
	*********************************************************************
	LPARAMETERS vNewVal
		*To do: Modify this routine for the Assign method
		THIS.WriteTimeout = INT(m.vNewVal)
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
		[<memberdata name="streamptr" type="property" display="StreamPtr"/>]+;
		[<memberdata name="toarray" type="method" display="ToArray"/>]+;
		[<memberdata name="setlength" type="method" display="SetLength"/>]+;
		[<memberdata name="handle" type="property" display="Handle"/>]+;
		[</VFPData>]		
	#ENDIF
ENDDEFINE
#ENDIF
*************************************************************************
*************************************************************************




#IFDEF USECLASS_XFCMEMORYSTREAM
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


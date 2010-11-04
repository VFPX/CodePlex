#INCLUDE vfp2c.h

DEFINE CLASS CArray AS Relation

	Address = 0
	ArrayOffset = 0
	bContained = .F.
	Elements = 0
	ElementSize = 0
	DIMENSION Element[1]

	FUNCTION Init(nRows)
		IF PCOUNT() = 1
			RETURN THIS.Dimension(nRows)
		ENDIF
	ENDFUNC

	FUNCTION Destroy
		THIS.FreeArray()
	ENDFUNC
	
	FUNCTION FreeArray
		IF !THIS.bContained AND THIS.Address != 0
			FreeMem(THIS.Address)
		ENDIF
		THIS.bContained = .F.
		THIS.Address = 0
	ENDFUNC
	
	FUNCTION AttachArray(nBaseAdress,nElements)
		ASSERT(PCOUNT()=2) MESSAGE 'Not enough parameters to attach array!'

		THIS.FreeArray()
		
		THIS.Address = nBaseAdress
		THIS.bContained = .T.
				
		THIS.Elements = nElements
		THIS.ArrayOffset = THIS.Address - THIS.ElementSize && eases access to the array in Element_Access (for 1 based addressing)
	ENDFUNC
	
	FUNCTION Dimension(nElements)
		ASSERT (!THIS.bContained) MESSAGE 'Dimensioning a contained array is a bad idea!'
		LOCAL lnAddress
		THIS.Elements = nElements
		lnAddress = ReAllocMem(THIS.Address,nElements*THIS.ElementSize)
		IF lnAddress != 0
			THIS.Address = lnAddress
			THIS.ArrayOffset = THIS.Address - THIS.ElementSize
			RETURN .T.
		ELSE
			RETURN .F.
		ENDIF
	ENDFUNC
	
	FUNCTION AddressOf(nElement)
		RETURN THIS.ArrayOffSet + nElement * THIS.ElementSize
	ENDFUNC
	
	FUNCTION MarshalArray(laSource)
		EXTERNAL ARRAY laSource
		IF THIS.Dimension(ALEN(laSource))
			&& RETURN MarshalArrayDataType(THIS.Address,@laSource)
		ELSE
			ERROR(INSUFMEMORY)
		ENDIF
	ENDFUNC
	
	FUNCTION UnMarshalArray(laDestination)
		EXTERNAL ARRAY laDestination
		DIMENSION laDestination[THIS.Elements]
		&& RETURN UnMarshalArrayDataType(THIS.Address,@laDestination)
	ENDFUNC
	
	FUNCTION MarshalCursor(lcFieldName)
		LOCAL lcAlias, lcField
		lcAlias = JUSTSTEM(lcFieldName)
		lcField = JUSTEXT(lcFieldName)
		IF THIS.Dimension(RECCOUNT(lcAlias))
			&&RETURN MarshalCursorDataType(THIS.Address,lcField,SELECT(lcAlias))
		ELSE
			ERROR(INSUFMEMORY)
		ENDIF
	ENDFUNC
	
	FUNCTION UnMarshalCursor(lcFieldName)
		LOCAL lcAlias, lcField
		lcAlias = JUSTSTEM(lcFieldName)
		lcField = JUSTEXT(lcFieldName)
		&& RETURN UnMarshalCursor(THIS.Address,lcField,SELECT(lcAlias),THIS.Elements)	
	ENDFUNC

ENDDEFINE

DEFINE CLASS CMultiDimArray AS Relation

	Address = 0
	bContained = .F.
	Elements = 0
	ElementSize = 0
	RowSize = 0
	Rows = 0
	Dimensions = 0
	DIMENSION DimensionOffSets[1] = 0
	DIMENSION Element[1]

	FUNCTION Init(nBaseAddress,nRows,nDimensions)
		DO CASE
			CASE PCOUNT() = 0
			CASE PCOUNT() = 1
				THIS.Dimension(nRows,1)
			CASE PCOUNT() = 2
				THIS.Dimesion(nRows,nDimensions)
			CASE PCOUNT() = 3
				THIS.Address = nBaseAddress
				THIS.CalculateOffsets(nRows,nDimension)
				THIS.bContained = .T.
		ENDCASE
	ENDFUNC

	FUNCTION Destroy
		THIS.FreeArray()
	ENDFUNC
	
	FUNCTION FreeArray
		IF !THIS.bContained AND THIS.Address != 0
			FreeMem(THIS.Address)
		ENDIF
	ENDFUNC
	
	FUNCTION Dimension(nRows,nDimensions)
		IF THIS.Address = 0
			THIS.Address = ReAllocMem(nRows*nDimensions*THIS.ElementSize)
			THIS.CalculateOffsets(nRows,nDimensions)
		ENDIF
	ENDFUNC
	
	PROTECTED FUNCTION CalculateOffSets(nRows, nDimensions)
		LOCAL xj
		THIS.Rows = nRows
		THIS.Dimensions = nDimensions
		THIS.Elements = nRows * nDimensions
		THIS.RowSize = nRows * THIS.ElementSize
		DIMENSION THIS.DimensionOffSets[nDimensions]
		FOR xj = 0 TO nDimensions - 1
			THIS.DimensionOffSets[xj+1] = THIS.Address + xj * THIS.RowSize - THIS.ElementSize
		ENDFOR
	ENDFUNC
	
ENDDEFINE

DEFINE CLASS CShortArray AS CArray

	ElementSize = SIZEOFSHORT

	FUNCTION Element_Access(nElement)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'
		ASSERT (nElement <= THIS.Elements) MESSAGE 'Arrayindex out of bounds!'
		IF VARTYPE(nElement) = 'N'
			RETURN ReadShort(THIS.ArrayOffset+nElement*SIZEOFSHORT)
		ELSE
			RETURN ReadShort(THIS.Address)
		ENDIF
	ENDFUNC
	
	FUNCTION Element_Assign(nNewVal,nElement)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'
		ASSERT (nElement <= THIS.Elements) MESSAGE 'Arrayindex out of bounds!'
		ASSERT (VARTYPE(nNewVal) = 'N' AND BETWEEN(nNewVal,MIN_SHORT,MAX_SHORT)) ;
		MESSAGE 'Value out of Range'
		WriteShort(THIS.ArrayOffset+nElement*SIZEOFSHORT,nNewVal)
	ENDFUNC
	
	FUNCTION MarshalArray(laSource)
		EXTERNAL ARRAY laSource
		IF THIS.Dimension(ALEN(laSource))
			RETURN MarshalArrayShort(THIS.Address,@laSource)
		ELSE
			ERROR(INSUFMEMORY)
		ENDIF
	ENDFUNC
	
	FUNCTION UnMarshalArray(laDestination)
		EXTERNAL ARRAY laDestination
		DIMENSION laDestination[MIN(THIS.Elements,MAXARRAYLEN)]
		RETURN UnMarshalArrayShort(THIS.Address,@laDestination)
	ENDFUNC
	
ENDDEFINE

DEFINE CLASS CUShortArray AS CArray

	ElementSize = SIZEOFSHORT

	FUNCTION Element_Access(nElement)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'
		ASSERT (nElement <= THIS.Elements) MESSAGE 'Arrayindex out of bounds!'
		IF VARTYPE(nElement) = 'N'
			RETURN ReadUShort(THIS.ArrayOffset+nElement*SIZEOFSHORT)
		ELSE
			RETURN ReadUShort(THIS.Address)
		ENDIF
	ENDFUNC
	
	FUNCTION Element_Assign(nNewVal,nElement)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'
		ASSERT (nElement <= THIS.Elements) MESSAGE 'Arrayindex out of bounds!'
		ASSERT (VARTYPE(nNewVal) = 'N' AND BETWEEN(nNewVal,MIN_USHORT,MAX_USHORT)) ;
		MESSAGE 'Value out of Range'
		WriteUShort(THIS.ArrayOffset+nElement*SIZEOFSHORT,nNewVal)
	ENDFUNC

	FUNCTION MarshalArray(laSource)
		EXTERNAL ARRAY laSource
		IF THIS.Dimension(ALEN(laSource))
			RETURN MarshalArrayUShort(THIS.Address,@laSource)
		ELSE
			ERROR(INSUFMEMORY)
		ENDIF
	ENDFUNC
	
	FUNCTION UnMarshalArray(laDestination)
		EXTERNAL ARRAY laDestination
		DIMENSION laDestination[MIN(THIS.Elements,MAXARRAYLEN)]
		RETURN UnMarshalArrayUShort(THIS.Address,@laDestination)
	ENDFUNC
	
ENDDEFINE

DEFINE CLASS CIntArray AS CArray

	ElementSize = SIZEOFINT

	FUNCTION Element_Access(nElement)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'
		ASSERT (nElement <= THIS.Elements) MESSAGE 'Arrayindex out of bounds!'
		IF VARTYPE(nElement) = 'N'
			RETURN ReadInt(THIS.ArrayOffset+nElement*SIZEOFINT)
		ELSE
			RETURN ReadInt(THIS.Address)
		ENDIF
	ENDFUNC

	FUNCTION Element_Assign(nNewVal,nElement)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'
		ASSERT (nElement <= THIS.Elements) MESSAGE 'Arrayindex out of bounds!'
		ASSERT (VARTYPE(nNewVal) = 'N' AND BETWEEN(nNewVal,MIN_INT,MAX_INT)) ;
		MESSAGE 'Value out of Range'
		WriteInt(THIS.ArrayOffset+nElement*SIZEOFINT,nNewVal)
	ENDFUNC

	FUNCTION MarshalArray(laSource)
		EXTERNAL ARRAY laSource
		IF THIS.Dimension(ALEN(laSource))
			RETURN MarshalArrayInt(THIS.Address,@laSource)
		ELSE
			ERROR(INSUFMEMORY)
		ENDIF
	ENDFUNC
	
	FUNCTION UnMarshalArray(laDestination)
		EXTERNAL ARRAY laDestination
		DIMENSION laDestination[MIN(THIS.Elements,MAXARRAYLEN)]
		RETURN UnMarshalArrayInt(THIS.Address,@laDestination)
	ENDFUNC
	
ENDDEFINE

DEFINE CLASS CMultiDimLongArray AS CMultiDimArray

	ElementSize = SIZEOFINT
	
	FUNCTION Element_Access(nRow,nDimension)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'
		ASSERT (nRow <= THIS.RowSize AND nDimension <= THIS.Dimensions) MESSAGE 'Arrayindex out of bounds!'
		RETURN ReadInt(THIS.DimensionOffSets[nDimension]+nRow*SIZEOFINT)
	ENDFUNC

	FUNCTION Element_Assign(nNewVal,nRow,nDimension)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'
		ASSERT (nRow <= THIS.RowSize AND nDimension <= THIS.Dimensions) MESSAGE 'Arrayindex out of bounds!'
		ASSERT (VARTYPE(nNewVal) = 'N' AND BETWEEN(nNewVal,MIN_INT,MAX_INT)) ;
		MESSAGE 'Value out of Range'
		WriteInt(THIS.DimensionOffSets[nDimension]+nRow*SIZEOFINT,nNewVal)
	ENDFUNC
	
	FUNCTION MarshalArray(laSource)
		EXTERNAL ARRAY laSource
		THIS.Dimension(ALEN(laSource,1))
		RETURN MarshalArrayInt(THIS.Address,@laSource)
	ENDFUNC
	
	FUNCTION UnMarshalArray(laDestination)
		EXTERNAL ARRAY laDestination
		DIMENSION laDestination[MIN(THIS.Elements,MAXARRAYLEN)]
		RETURN UnMarshalArrayInt(THIS.Address,@laDestination)
	ENDFUNC

ENDDEFINE
	
DEFINE CLASS CUIntArray AS CArray

	ElementSize = SIZEOFINT

	FUNCTION Element_Access(nElement)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'
		ASSERT (nElement <= THIS.Elements) MESSAGE 'Arrayindex out of bounds!'		
		IF VARTYPE(nElement) = 'N'
			RETURN ReadUInt(THIS.ArrayOffset+nElement*SIZEOFINT)
		ELSE
			RETURN ReadUInt(THIS.Address)
		ENDIF
	ENDFUNC
	
	FUNCTION Element_Assign(nNewVal,nElement)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'
		ASSERT (nElement <= THIS.Elements) MESSAGE 'Arrayindex out of bounds!'		
		ASSERT (VARTYPE(nNewVal) = 'N' AND BETWEEN(nNewVal,MIN_UINT,MAX_UINT)) ;
		MESSAGE 'Value out of Range'
		WriteUInt(THIS.ArrayOffset+nElement*SIZEOFINT,nNewVal)
	ENDFUNC

	FUNCTION MarshalArray(laSource)
		EXTERNAL ARRAY laSource
		IF THIS.Dimension(ALEN(laSource))
			RETURN MarshalArrayUInt(THIS.Address,@laSource)
		ELSE
			ERROR(INSUFMEMORY)
		ENDIF
	ENDFUNC
	
	FUNCTION UnMarshalArray(laDestination)
		EXTERNAL ARRAY laDestination
		DIMENSION laDestination[MIN(THIS.Elements,MAXARRAYLEN)]
		RETURN UnMarshalArrayUInt(THIS.Address,@laDestination)
	ENDFUNC

ENDDEFINE
	
DEFINE CLASS CDoubleArray AS CArray

	ElementSize = SIZEOFDOUBLE

	FUNCTION Element_Access(nElement)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'
		ASSERT (nElement <= THIS.Elements) MESSAGE 'Arrayindex out of bounds!'		
		IF VARTYPE(nElement) = 'N'
			RETURN ReadDouble(THIS.ArrayOffset+nElement*SIZEOFDOUBLE)
		ELSE
			RETURN ReadDouble(THIS.Address)
		ENDIF
	ENDFUNC
	
	FUNCTION Element_Assign(nNewVal,nElement)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'
		ASSERT (nElement <= THIS.Elements) MESSAGE 'Arrayindex out of bounds!'		
		WriteDouble(THIS.ArrayOffset+nElement*SIZEOFDOUBLE,nNewVal)
	ENDFUNC
	
	FUNCTION MarshalArray(laSource)
		EXTERNAL ARRAY laSource
		IF THIS.Dimension(ALEN(laSource))
			RETURN MarshalArrayDouble(THIS.Address,@laSource)
		ELSE
			ERROR(INSUFMEMORY)
		ENDIF
	ENDFUNC
	
	FUNCTION UnMarshalArray(laDestination)
		EXTERNAL ARRAY laDestination
		DIMENSION laDestination[MIN(THIS.Elements,MAXARRAYLEN)]
		RETURN UnMarshalArrayDouble(THIS.Address,@laDestination)
	ENDFUNC
	
ENDDEFINE

DEFINE CLASS CFloatArray AS CArray

	ElementSize = SIZEOFFLOAT

	FUNCTION Element_Access(nElement)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'
		ASSERT (nElement <= THIS.Elements) MESSAGE 'Arrayindex out of bounds!'		
		IF VARTYPE(nElement) = 'N'
			RETURN ReadFloat(THIS.ArrayOffset+nElement*SIZEOFFLOAT)
		ELSE
			RETURN ReadFloat(THIS.Address)
		ENDIF
	ENDFUNC
	
	FUNCTION Element_Assign(nNewVal,nElement)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'
		ASSERT (nElement <= THIS.Elements) MESSAGE 'Arrayindex out of bounds!'		
		WriteFloat(THIS.ArrayOffset+nElement*SIZEOFFLOAT,nNewVal)
	ENDFUNC
	
	FUNCTION MarshalArray(laSource)
		EXTERNAL ARRAY laSource
		IF THIS.Dimension(ALEN(laSource))
			RETURN MarshalArrayFloat(THIS.Address,@laSource)
		ELSE
			ERROR(INSUFMEMORY)
		ENDIF
	ENDFUNC
	
	FUNCTION UnMarshalArray(laDestination)
		EXTERNAL ARRAY laDestination
		DIMENSION laDestination[MIN(THIS.Elements,MAXARRAYLEN)]
		RETURN UnMarshalArrayFloat(THIS.Address,@laDestination)
	ENDFUNC

ENDDEFINE

DEFINE CLASS CStringArray AS CArray

	ElementSize = SIZEOFPOINTER
	
	FUNCTION FreeArray
		IF !THIS.bContained AND THIS.Address != 0
			FreeRefArray(THIS.Address,0,THIS.Elements)
			FreeMem(THIS.Address)
		ENDIF
		THIS.bContained = .F.
		THIS.Address = 0
	ENDFUNC

	FUNCTION Element_Access(nElement)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'
		ASSERT (nElement <= THIS.Elements) MESSAGE 'Arrayindex out of bounds!'		
		IF VARTYPE(nElement) = 'N'
			RETURN ReadPCString(THIS.ArrayOffset+nElement*SIZEOFPOINTER)
		ELSE
			RETURN ''
		ENDIF
	ENDFUNC
	
	FUNCTION Element_Assign(nNewVal,nElement)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'
		ASSERT (nElement <= THIS.Elements) MESSAGE 'Arrayindex out of bounds!'		
		WritePCString(THIS.ArrayOffset+nElement*SIZEOFPOINTER,nNewVal)
	ENDFUNC
	
	FUNCTION MarshalArray(laSource)
		EXTERNAL ARRAY laSource
		IF THIS.Dimension(ALEN(laSource))
			RETURN MarshalArrayCString(THIS.Address,@laSource)
		ELSE
			ERROR(INSUFMEMORY)
		ENDIF
	ENDFUNC
	
	FUNCTION UnMarshalArray(laDestination)
		EXTERNAL ARRAY laDestination
		DIMENSION laDestination[MIN(THIS.Elements,MAXARRAYLEN)]
		RETURN UnMarshalArrayCString(THIS.Address,@laDestination)
	ENDFUNC

ENDDEFINE


DEFINE CLASS CWStringArray AS CArray

	ElementSize = SIZEOFPOINTER
	
	FUNCTION FreeArray
		IF !THIS.bContained AND THIS.Address != 0
			FreeRefArray(THIS.Address,0,THIS.Elements)
			FreeMem(THIS.Address)
		ENDIF
		THIS.bContained = .F.
		THIS.Address = 0
	ENDFUNC

	FUNCTION Element_Access(nElement)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'	
		ASSERT (nElement <= THIS.Elements) MESSAGE 'Arrayindex out of bounds!'		
		IF VARTYPE(nElement) = 'N'
			RETURN ReadPWString(THIS.ArrayOffset+nElement*SIZEOFPOINTER)
		ELSE
			RETURN ''
		ENDIF
	ENDFUNC
	
	FUNCTION Element_Assign(nNewVal,nElement)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'
		ASSERT (nElement <= THIS.Elements) MESSAGE 'Arrayindex out of bounds!'		
		WritePWString(THIS.ArrayOffset+nElement*SIZEOFPOINTER,nNewVal)
	ENDFUNC

	FUNCTION MarshalArray(laSource)
		EXTERNAL ARRAY laSource
		IF THIS.Dimension(ALEN(laSource))
			RETURN MarshalArrayWString(THIS.Address,@laSource)
		ELSE
			ERROR(INSUFMEMORY)
		ENDIF
	ENDFUNC
	
	FUNCTION UnMarshalArray(laDestination)
		EXTERNAL ARRAY laDestination
		DIMENSION laDestination[MIN(THIS.Elements,MAXARRAYLEN)]
		RETURN UnMarshalArrayWString(THIS.Address,@laDestination)
	ENDFUNC

ENDDEFINE

DEFINE CLASS CCharArray AS CArray

	ElementSize = 0
	
	FUNCTION AttachArray(nBaseAdress,nElements,nLength)
		ASSERT (PCOUNT()=3) MESSAGE 'Not enough parameters to attach array'

		THIS.FreeArray()
		
		THIS.Address = nBaseAdress
		THIS.bContained = .T.
		THIS.Elements = nElements
		THIS.ElementSize = nLength
		THIS.ArrayOffset = THIS.Address - THIS.ElementSize && eases access to the array in Element_Access (for 1 based addressing)

	ENDFUNC
	
	FUNCTION Dimension(nElements, nLength)
		LOCAL lnAddress
		THIS.Elements = nElements
		THIS.ElementSize = nLength
		lnAddress = ReAllocMem(THIS.Address,nElements*nLength)
		IF lnAddress != 0
			THIS.Address = lnAddress
			THIS.ArrayOffset = THIS.Address - THIS.ElementSize
			RETURN .T.
		ELSE
			RETURN .F.
		ENDIF
	ENDFUNC
	
	FUNCTION Element_Access(nElement)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'	
		ASSERT (nElement <= THIS.Elements) MESSAGE 'Arrayindex out of bounds!'		
		IF VARTYPE(nElement) = 'N'
			RETURN ReadCString(THIS.ArrayOffset+nElement*THIS.ElementSize)
		ELSE
			RETURN ''
		ENDIF
	ENDFUNC
	
	FUNCTION Element_Assign(nNewVal,nElement)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'
		ASSERT (nElement <= THIS.Elements) MESSAGE 'Arrayindex out of bounds!'		
		WriteCharArray(THIS.ArrayOffset+nElement*THIS.ElementSize,nNewVal,THIS.ElementSize)
	ENDFUNC

	FUNCTION MarshalArray(laSource, lnLength)
		EXTERNAL ARRAY laSource
		IF THIS.Dimension(ALEN(laSource),lnLength)
			RETURN MarshalArrayCharArray(THIS.Address,@laSource,lnLength)
		ELSE
			ERROR(INSUFMEMORY)
		ENDIF
	ENDFUNC
	
	FUNCTION UnMarshalArray(laDestination)
		EXTERNAL ARRAY laDestination
		DIMENSION laDestination[MIN(THIS.Elements,MAXARRAYLEN)]
		RETURN UnMarshalArrayCharArray(THIS.Address,@laDestination,THIS.ElementSize)
	ENDFUNC

ENDDEFINE

DEFINE CLASS CWCharArray AS CArray

	ElementSize = 0
	
	FUNCTION AttachArray(nBaseAdress,nElements,nLength)
		ASSERT (PCOUNT()=3) MESSAGE 'Not enough parameters to attach array'

		THIS.FreeArray()
		
		THIS.Address = nBaseAdress
		THIS.bContained = .T.
		THIS.Elements = nElements
		THIS.ElementSize = nLength * SIZEOFWCHAR
		THIS.ArrayOffset = THIS.Address - THIS.ElementSize && eases access to the array in Element_Access (for 1 based addressing)

	ENDFUNC
	
	FUNCTION Dimension(nElements, nLength)
		LOCAL lnAddress
		THIS.Elements = nElements
		THIS.ElementSize = nLength * SIZEOFWCHAR
		lnAddress = ReAllocMem(THIS.Address,nElements*THIS.ElementSize)
		IF lnAddress != 0
			THIS.Address = lnAddress
			THIS.ArrayOffset = THIS.Address - THIS.ElementSize
			RETURN .T.
		ELSE
			RETURN .F.
		ENDIF
	ENDFUNC
	
	FUNCTION Element_Access(nElement)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'	
		ASSERT (nElement <= THIS.Elements) MESSAGE 'Arrayindex out of bounds!'		
		IF VARTYPE(nElement) = 'N'
			RETURN ReadWString(THIS.ArrayOffset+nElement*THIS.ElementSize)
		ELSE
			RETURN ''
		ENDIF
	ENDFUNC
	
	FUNCTION Element_Assign(nNewVal,nElement)
		ASSERT (THIS.Address != 0) MESSAGE 'Dimension the array first!'
		ASSERT (nElement <= THIS.Elements) MESSAGE 'Arrayindex out of bounds!'
		WriteWCharArray(THIS.ArrayOffset+nElement*THIS.ElementSize,nNewVal,THIS.ElementSize)
	ENDFUNC

	FUNCTION MarshalArray(laSource, nLength, nCodePage)
		EXTERNAL ARRAY laSource
		IF THIS.Dimesion(ALEN(laSource),nLength)
			IF PCOUNT() = 2
				RETURN MarshalArrayWCharArray(THIS.Address,@laSource,nLength)
			ELSE
				RETURN MarshalArrayWCharArray(THIS.Address,@laSource,nLength,nCodePage)
			ENDIF
		ELSE
			ERROR(INSUFMEMORY)
		ENDIF
	ENDFUNC
	
	FUNCTION UnMarshalArray(laDestination)
		EXTERNAL ARRAY laDestination
		DIMENSION laDestination[MIN(THIS.Elements,MAXARRAYLEN)]
		RETURN UnMarshalArrayWCharArray(THIS.Address,@laDestination,THIS.ElementSize)
	ENDFUNC

ENDDEFINE

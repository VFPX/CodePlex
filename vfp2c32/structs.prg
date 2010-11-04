DEFINE CLASS SYSTEMTIME AS Relation

	Address = 0
	SizeOf = 16
	PROTECTED Embedded	
	Embedded = .F.
	&& structure fields
	wYear = .F.
	wMonth = .F.
	wDayOfWeek = .F.
	wDay = .F.
	wHour = .F.
	wMinute = .F.
	wSecond = .F.
	wMilliseconds = .F.
	&& additional properties to convert the systemtime structure to/from a VFP datetime 
	mDate = .F.
	mUTCDate = .F.
	
	PROCEDURE Init(lnAddress)
		IF PCOUNT() = 0
			THIS.Address = AllocMem(THIS.SizeOf)
			IF THIS.Address = 0
				ERROR(43)
				RETURN .F.
			ENDIF
		ELSE
			ASSERT VARTYPE(lnAddress) = 'N' AND lnAddress != 0 MESSAGE 'Address of structure must be specified!'
			THIS.Address = lnAddress
			THIS.Embedded = .T.
		ENDIF
	ENDPROC
	
	PROCEDURE Destroy()
		IF !THIS.Embedded
			FreeMem(THIS.Address)
		ENDIF
	ENDPROC

	PROCEDURE wYear_Access()
		RETURN ReadUShort(THIS.Address)
	ENDPROC

	PROCEDURE wYear_Assign(lnNewVal)
		WriteUShort(THIS.Address,lnNewVal)
	ENDPROC

	PROCEDURE wMonth_Access()
		RETURN ReadUShort(THIS.Address+2)
	ENDPROC

	PROCEDURE wMonth_Assign(lnNewVal)
		WriteUShort(THIS.Address+2,lnNewVal)
	ENDPROC

	PROCEDURE wDayOfWeek_Access()
		RETURN ReadUShort(THIS.Address+4)
	ENDPROC

	PROCEDURE wDayOfWeek_Assign(lnNewVal)
		WriteUShort(THIS.Address+4,lnNewVal)
	ENDPROC

	PROCEDURE wDay_Access()
		RETURN ReadUShort(THIS.Address+6)
	ENDPROC

	PROCEDURE wDay_Assign(lnNewVal)
		WriteUShort(THIS.Address+6,lnNewVal)
	ENDPROC

	PROCEDURE wHour_Access()
		RETURN ReadUShort(THIS.Address+8)
	ENDPROC

	PROCEDURE wHour_Assign(lnNewVal)
		WriteUShort(THIS.Address+8,lnNewVal)
	ENDPROC

	PROCEDURE wMinute_Access()
		RETURN ReadUShort(THIS.Address+10)
	ENDPROC

	PROCEDURE wMinute_Assign(lnNewVal)
		WriteUShort(THIS.Address+10,lnNewVal)
	ENDPROC

	PROCEDURE wSecond_Access()
		RETURN ReadUShort(THIS.Address+12)
	ENDPROC

	PROCEDURE wSecond_Assign(lnNewVal)
		WriteUShort(THIS.Address+12,lnNewVal)
	ENDPROC

	PROCEDURE wMilliseconds_Access()
		RETURN ReadUShort(THIS.Address+14)
	ENDPROC

	PROCEDURE wMilliseconds_Assign(lnNewVal)
		WriteUShort(THIS.Address+14,lnNewVal)
	ENDPROC
	
	PROCEDURE mDate_Access()
		RETURN ST2DT(THIS.Address)
	ENDPROC

	PROCEDURE mDate_Assign(lnNewVal)
		DT2ST(lnNewVal,THIS.Address)
	ENDPROC

	PROCEDURE mUTCDate_Access()
		RETURN ST2DT(THIS.Address,.T.)
	ENDPROC

	PROCEDURE mUTCDate_Assign(lnNewVal)
		DT2ST(lnNewVal,THIS.Address,.T.)
	ENDPROC
	
ENDDEFINE

DEFINE CLASS FILETIME AS Relation

	Address = 0
	SizeOf = 8
	PROTECTED Embedded	
	Embedded = .F.
	&& structure fields
	dwLowDateTime = .F.
	dwHighDateTime = .F.
	&& additional properties to convert the filetime structure to/from a VFP datetime 
	mDate = .F.
	mUTCDate = .F.
	
	PROCEDURE Init(lnAddress)
		IF PCOUNT() = 0
			THIS.Address = AllocMem(THIS.SizeOf)
			IF THIS.Address = 0
				ERROR(43)
				RETURN .F.
			ENDIF
		ELSE
			ASSERT VARTYPE(lnAddress) = 'N' AND lnAddress != 0 MESSAGE 'Address of structure must be specified!'
			THIS.Address = lnAddress
			THIS.Embedded = .T.
		ENDIF
	ENDPROC
	
	PROCEDURE Destroy()
		IF !THIS.Embedded
			FreeMem(THIS.Address)
		ENDIF
	ENDPROC

	PROCEDURE dwLowDateTime_Access()
		RETURN ReadUInt(THIS.Address)
	ENDPROC

	PROCEDURE dwLowDateTime_Assign(lnNewVal)
		WriteUInt(THIS.Address,lnNewVal)
	ENDPROC

	PROCEDURE dwHighDateTime_Access()
		RETURN ReadUInt(THIS.Address+4)
	ENDPROC

	PROCEDURE dwHighDateTime_Assign(lnNewVal)
		WriteUInt(THIS.Address+4,lnNewVal)
	ENDPROC
	
	PROCEDURE mDate_Access()
		RETURN FT2DT(THIS.Address)
	ENDPROC

	PROCEDURE mDate_Assign(lnNewVal)
		DT2FT(lnNewVal,THIS.Address)
	ENDPROC

	PROCEDURE mUTCDate_Access()
		RETURN FT2DT(THIS.Address,.T.)
	ENDPROC

	PROCEDURE mUTCDate_Assign(lnNewVal)
		DT2FT(lnNewVal,THIS.Address,.T.)
	ENDPROC

ENDDEFINE

DEFINE CLASS POINT AS Relation

	Address = 0
	SizeOf = 8
	PROTECTED Embedded
	Embedded = .F.
	&& structure fields
	x = .F.
	y = .F.

	PROCEDURE Init(lnAddress)
		IF PCOUNT() = 0
			THIS.Address = AllocMem(THIS.SizeOf)
			IF THIS.Address = 0
				ERROR(43)
				RETURN .F.
			ENDIF
		ELSE
			ASSERT TYPE('lnAddress') = 'N' AND lnAddress != 0 MESSAGE 'Address of structure must be specified!'
			THIS.Address = lnAddress
			THIS.Embedded = .T.
		ENDIF
	ENDPROC
	
	PROCEDURE Destroy()
		IF !THIS.Embedded
			FreeMem(THIS.Address)
		ENDIF
	ENDPROC

	PROCEDURE x_Access()
		RETURN ReadInt(THIS.Address)
	ENDPROC

	PROCEDURE x_Assign(lnNewVal)
		WriteInt(THIS.Address,lnNewVal)
	ENDPROC

	PROCEDURE y_Access()
		RETURN ReadInt(THIS.Address+4)
	ENDPROC

	PROCEDURE y_Assign(lnNewVal)
		WriteInt(THIS.Address+4,lnNewVal)
	ENDPROC

ENDDEFINE

DEFINE CLASS SIZE AS Relation

	Address = 0
	SIZEOf = 8
	PROTECTED Embedded
	Embedded = .F.
	&& structure fields
	cx = .F.
	cy = .F.

	PROCEDURE Init(lnAddress)
		IF PCOUNT() = 0
			THIS.Address = AllocMem(THIS.SizeOf)
			IF THIS.Address = 0
				ERROR(43)
				RETURN .F.
			ENDIF
		ELSE
			ASSERT TYPE('lnAddress') = 'N' AND lnAddress != 0 MESSAGE 'Address of structure must be specified!'
			THIS.Address = lnAddress
			THIS.Embedded = .T.
		ENDIF
	ENDPROC
	
	PROCEDURE Destroy()
		IF !THIS.Embedded
			FreeMem(THIS.Address)
		ENDIF
	ENDPROC

	PROCEDURE cx_Access()
		RETURN ReadInt(THIS.Address)
	ENDPROC

	PROCEDURE cx_Assign(lnNewVal)
		WriteInt(THIS.Address,lnNewVal)
	ENDPROC

	PROCEDURE cy_Access()
		RETURN ReadInt(THIS.Address+4)
	ENDPROC

	PROCEDURE cy_Assign(lnNewVal)
		WriteInt(THIS.Address+4,lnNewVal)
	ENDPROC

ENDDEFINE

DEFINE CLASS RECT AS Relation
	
	Address = 0 
	SizeOf = 16
	PROTECTED Embedded	
	Embedded = .F.
	mLeft = 0
	mTop = 0
	mRigth = 0
	mBottom = 0
	
	PROCEDURE Init(lnAddress)
		IF PCOUNT() = 0
			THIS.Address = AllocMem(THIS.SizeOf)
			IF THIS.Address = 0
				ERROR(43)
				RETURN .F.
			ENDIF
		ELSE
			ASSERT TYPE('lnAddress') = 'N' AND lnAddress != 0 MESSAGE 'Address of structure must be specified!'
			THIS.Address = lnAddress
			THIS.Embedded = .T.
		ENDIF
	ENDFUNC
	
	PROCEDURE Destroy
		IF !THIS.Embedded
			FreeMem(THIS.Address)
		ENDIF
	ENDPROC
	
	PROCEDURE mLeft_Access
		RETURN ReadInt(THIS.Address)
	ENDPROC
	
	PROCEDURE mLeft_Assign(lnNewVal)
		WriteInt(THIS.Address,lnNewVal)
	ENDPROC
	
	PROCEDURE mTop_Access
		RETURN ReadInt(THIS.Address+4)
	ENDPROC
	
	PROCEDURE mTop_Assign(lnNewVal)
		WriteInt(THIS.Address+4,lnNewVal)
	ENDPROC

	PROCEDURE mRigth_Access
		RETURN ReadInt(THIS.Address+8)
	ENDPROC
	
	PROCEDURE mRigth_Assign(lnNewVal)
		WriteInt(THIS.Address+8,lnNewVal)			
	ENDPROC

	PROCEDURE mBottom_Access
		RETURN ReadInt(THIS.Address+12)
	ENDPROC
	
	PROCEDURE mBottom_Assign(lnNewVal)
		WriteInt(THIS.Address+12,lnNewVal)						
	ENDPROC

ENDDEFINE

DEFINE CLASS WINDOWPLACEMENT AS Relation

	Address = 0
	SizeOf = 44
	&& structure fields
	length = .F.
	flags = .F.
	showCmd = .F.
	ptMinPosition = .NULL.
	ptMaxPosition = .NULL.
	rcNormalPosition = .NULL.

	PROCEDURE Init()
		THIS.Address = AllocMem(THIS.SizeOf)
		IF THIS.Address = 0
			ERROR(43)
			RETURN .F.
		ENDIF
		THIS.ptMinPosition = CREATEOBJECT('POINT',THIS.Address+12)
		THIS.ptMaxPosition = CREATEOBJECT('POINT',THIS.Address+20)
		THIS.rcNormalPosition = CREATEOBJECT('RECT',THIS.Address+28)
		THIS.length = THIS.SizeOf && manually added .. size of structure ..
	ENDPROC

	PROCEDURE Destroy()
		THIS.ptMinPosition = .NULL.
		THIS.ptMaxPosition = .NULL.
		THIS.rcNormalPosition = .NULL.
		FreeMem(THIS.Address)
	ENDPROC

	PROCEDURE Address_Assign(lnAddress)
		DO CASE
			CASE THIS.Address = 0
				THIS.Address = lnAddress
			CASE THIS.Address = lnAddress
			OTHERWISE
				THIS.Address = lnAddress
				THIS.ptMinPosition.Address = lnAddress+12
				THIS.ptMaxPosition.Address = lnAddress+20
				THIS.rcNormalPosition.Address = lnAddress+28
		ENDCASE
	ENDPROC

	PROCEDURE length_Access()
		RETURN ReadUInt(THIS.Address)
	ENDPROC

	PROCEDURE length_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WriteUInt(THIS.Address,lnNewVal)
	ENDPROC

	PROCEDURE flags_Access()
		RETURN ReadUInt(THIS.Address+4)
	ENDPROC

	PROCEDURE flags_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WriteUInt(THIS.Address+4,lnNewVal)
	ENDPROC

	PROCEDURE showCmd_Access()
		RETURN ReadUInt(THIS.Address+8)
	ENDPROC

	PROCEDURE showCmd_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WriteUInt(THIS.Address+8,lnNewVal)
	ENDPROC

ENDDEFINE


DEFINE CLASS MEMORYSTATUS AS Relation

	Address = 0
	SizeOf = 32
	&& structure fields
	dwLength = .F.
	dwMemoryLoad = .F.
	dwTotalPhys = .F.
	dwAvailPhys = .F.
	dwTotalPageFile = .F.
	dwAvailPageFile = .F.
	dwTotalVirtual = .F.
	dwAvailVirtual = .F.

	PROCEDURE Init()
		THIS.Address = AllocMem(THIS.SizeOf)
		IF THIS.Address = 0
			ERROR(43)
			RETURN .F.
		ENDIF
	ENDPROC

	PROCEDURE Destroy()
		FreeMem(THIS.Address)
	ENDPROC

	PROCEDURE dwLength_Access()
		RETURN ReadUInt(THIS.Address)
	ENDPROC

	PROCEDURE dwLength_Assign(lnNewVal)
		WriteUInt(THIS.Address,lnNewVal)
	ENDPROC

	PROCEDURE dwMemoryLoad_Access()
		RETURN ReadUInt(THIS.Address+4)
	ENDPROC

	PROCEDURE dwTotalPhys_Access()
		RETURN ReadUInt(THIS.Address+8)
	ENDPROC

	PROCEDURE dwAvailPhys_Access()
		RETURN ReadUInt(THIS.Address+12)
	ENDPROC

	PROCEDURE dwTotalPageFile_Access()
		RETURN ReadUInt(THIS.Address+16)
	ENDPROC

	PROCEDURE dwAvailPageFile_Access()
		RETURN ReadUInt(THIS.Address+20)
	ENDPROC

	PROCEDURE dwTotalVirtual_Access()
		RETURN ReadUInt(THIS.Address+24)
	ENDPROC

	PROCEDURE dwAvailVirtual_Access()
		RETURN ReadUInt(THIS.Address+28)
	ENDPROC

ENDDEFINE

DEFINE CLASS MEMORYSTATUSEX AS Relation

	Address = 0
	SizeOf = 64
	&& structure fields
	dwLength = .F.
	dwMemoryLoad = .F.
	ullTotalPhys = .F.
	ullAvailPhys = .F.
	ullTotalPageFile = .F.
	ullAvailPageFile = .F.
	ullTotalVirtual = .F.
	ullAvailVirtual = .F.
	ullAvailExtendedVirtual = .F.

	PROCEDURE Init()
		THIS.Address = AllocMem(THIS.SizeOf)
		IF THIS.Address = 0
			ERROR(43)
			RETURN .F.
		ENDIF
		THIS.dwLength = THIS.SizeOf
	ENDPROC

	PROCEDURE Destroy()
		FreeMem(THIS.Address)
	ENDPROC

	PROCEDURE dwLength_Access()
		RETURN ReadUInt(THIS.Address)
	ENDPROC

	PROCEDURE dwLength_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WriteUInt(THIS.Address,lnNewVal)
	ENDPROC

	PROCEDURE dwMemoryLoad_Access()
		RETURN ReadUInt(THIS.Address+4)
	ENDPROC

	PROCEDURE ullTotalPhys_Access()
		RETURN ReadUInt64AsDouble(THIS.Address+8)
	ENDPROC

	PROCEDURE ullAvailPhys_Access()
		RETURN ReadUInt64AsDouble(THIS.Address+16)
	ENDPROC

	PROCEDURE ullTotalPageFile_Access()
		RETURN ReadUInt64AsDouble(THIS.Address+24)
	ENDPROC

	PROCEDURE ullAvailPageFile_Access()
		RETURN ReadUInt64AsDouble(THIS.Address+32)
	ENDPROC

	PROCEDURE ullTotalVirtual_Access()
		RETURN ReadUInt64AsDouble(THIS.Address+40)
	ENDPROC

	PROCEDURE ullAvailVirtual_Access()
		RETURN ReadUInt64AsDouble(THIS.Address+48)
	ENDPROC

	PROCEDURE ullAvailExtendedVirtual_Access()
		RETURN ReadUInt64AsDouble(THIS.Address+56)
	ENDPROC

ENDDEFINE

DEFINE CLASS SYSTEM_INFO AS Relation

	Address = 0
	SizeOf = 36
	&& structure fields
	dwOemId = .F.
	wProcessorArchitecture = .F.
	wReserved = .F.
	dwPageSize = .F.
	lpMinimumApplicationAddress = .F.
	lpMaximumApplicationAddress = .F.
	dwActiveProcessorMask = .F.
	dwNumberOfProcessors = .F.
	dwProcessorType = .F.
	dwAllocationGranularity = .F.
	wProcessorLevel = .F.
	wProcessorRevision = .F.

	PROCEDURE Init()
		THIS.Address = AllocMem(THIS.SizeOf)
		IF THIS.Address = 0
			ERROR(43)
			RETURN .F.
		ENDIF
	ENDPROC

	PROCEDURE Destroy()
		FreeMem(THIS.Address)
	ENDPROC

	PROCEDURE dwOemId_Access()
		RETURN ReadUInt(THIS.Address)
	ENDPROC

	PROCEDURE dwOemId_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WriteUInt(THIS.Address,lnNewVal)
	ENDPROC

	PROCEDURE wProcessorArchitecture_Access()
		RETURN ReadUShort(THIS.Address)
	ENDPROC

	PROCEDURE wProcessorArchitecture_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,65535) MESSAGE 'Wrong datatype or value out of range!'
		WriteUShort(THIS.Address,lnNewVal)
	ENDPROC

	PROCEDURE wReserved_Access()
		RETURN ReadUShort(THIS.Address+2)
	ENDPROC

	PROCEDURE wReserved_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,65535) MESSAGE 'Wrong datatype or value out of range!'
		WriteUShort(THIS.Address+2,lnNewVal)
	ENDPROC

	PROCEDURE dwPageSize_Access()
		RETURN ReadUInt(THIS.Address+4)
	ENDPROC

	PROCEDURE dwPageSize_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WriteUInt(THIS.Address+4,lnNewVal)
	ENDPROC

	PROCEDURE lpMinimumApplicationAddress_Access()
		RETURN ReadPointer(THIS.Address+8)
	ENDPROC

	PROCEDURE lpMinimumApplicationAddress_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WritePointer(THIS.Address+8,lnNewVal)
	ENDPROC

	PROCEDURE lpMaximumApplicationAddress_Access()
		RETURN ReadPointer(THIS.Address+12)
	ENDPROC

	PROCEDURE lpMaximumApplicationAddress_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WritePointer(THIS.Address+12,lnNewVal)
	ENDPROC

	PROCEDURE dwActiveProcessorMask_Access()
		RETURN ReadUInt(THIS.Address+16)
	ENDPROC

	PROCEDURE dwActiveProcessorMask_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WriteUInt(THIS.Address+16,lnNewVal)
	ENDPROC

	PROCEDURE dwNumberOfProcessors_Access()
		RETURN ReadUInt(THIS.Address+20)
	ENDPROC

	PROCEDURE dwNumberOfProcessors_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WriteUInt(THIS.Address+20,lnNewVal)
	ENDPROC

	PROCEDURE dwProcessorType_Access()
		RETURN ReadUInt(THIS.Address+24)
	ENDPROC

	PROCEDURE dwProcessorType_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WriteUInt(THIS.Address+24,lnNewVal)
	ENDPROC

	PROCEDURE dwAllocationGranularity_Access()
		RETURN ReadUInt(THIS.Address+28)
	ENDPROC

	PROCEDURE dwAllocationGranularity_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WriteUInt(THIS.Address+28,lnNewVal)
	ENDPROC

	PROCEDURE wProcessorLevel_Access()
		RETURN ReadUShort(THIS.Address+32)
	ENDPROC

	PROCEDURE wProcessorLevel_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,65535) MESSAGE 'Wrong datatype or value out of range!'
		WriteUShort(THIS.Address+32,lnNewVal)
	ENDPROC

	PROCEDURE wProcessorRevision_Access()
		RETURN ReadUShort(THIS.Address+34)
	ENDPROC

	PROCEDURE wProcessorRevision_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,65535) MESSAGE 'Wrong datatype or value out of range!'
		WriteUShort(THIS.Address+34,lnNewVal)
	ENDPROC

ENDDEFINE

DEFINE CLASS OSVERSIONINFO AS Relation

	Address = 0
	SizeOf = 148
	&& structure fields
	dwOSVersionInfoSize = .F.
	dwMajorVersion = .F.
	dwMinorVersion = .F.
	dwBuildNumber = .F.
	dwPlatformId = .F.
	szCSDVersion = .F.

	PROCEDURE Init()
		THIS.Address = AllocMem(THIS.SizeOf)
		IF THIS.Address = 0
			ERROR(43)
			RETURN .F.
		ENDIF
		THIS.dwOSVersionInfoSize = THIS.SizeOf
	ENDPROC

	PROCEDURE Destroy()
		FreeMem(THIS.Address)
	ENDPROC

	PROCEDURE dwOSVersionInfoSize_Access()
		RETURN ReadUInt(THIS.Address)
	ENDPROC

	PROCEDURE dwOSVersionInfoSize_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WriteUInt(THIS.Address,lnNewVal)
	ENDPROC

	PROCEDURE dwMajorVersion_Access()
		RETURN ReadUInt(THIS.Address+4)
	ENDPROC

	PROCEDURE dwMajorVersion_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WriteUInt(THIS.Address+4,lnNewVal)
	ENDPROC

	PROCEDURE dwMinorVersion_Access()
		RETURN ReadUInt(THIS.Address+8)
	ENDPROC

	PROCEDURE dwMinorVersion_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WriteUInt(THIS.Address+8,lnNewVal)
	ENDPROC

	PROCEDURE dwBuildNumber_Access()
		RETURN ReadUInt(THIS.Address+12)
	ENDPROC

	PROCEDURE dwBuildNumber_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WriteUInt(THIS.Address+12,lnNewVal)
	ENDPROC

	PROCEDURE dwPlatformId_Access()
		RETURN ReadUInt(THIS.Address+16)
	ENDPROC

	PROCEDURE dwPlatformId_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WriteUInt(THIS.Address+16,lnNewVal)
	ENDPROC

	PROCEDURE szCSDVersion_Access()
		RETURN ReadCharArray(THIS.Address+20,128)
	ENDPROC

	PROCEDURE szCSDVersion_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'C' MESSAGE 'Wrong datatype or value out of range!'
		WriteCharArray(THIS.Address+20,lnNewVal,128)
	ENDPROC

ENDDEFINE

DEFINE CLASS OSVERSIONINFOEX AS Relation

	Address = 0
	SizeOf = 156
	&& structure fields
	dwOSVersionInfoSize = .F.
	dwMajorVersion = .F.
	dwMinorVersion = .F.
	dwBuildNumber = .F.
	dwPlatformId = .F.
	szCSDVersion = .F.
	wServicePackMajor = .F.
	wServicePackMinor = .F.
	wSuiteMask = .F.
	wProductType = .F.
	wReserved = .F.

	PROCEDURE Init()
		THIS.Address = AllocMem(THIS.SizeOf)
		IF THIS.Address = 0
			ERROR(43)
			RETURN .F.
		ENDIF
		THIS.dwOSVersionInfoSize = THIS.SizeOf
	ENDPROC

	PROCEDURE Destroy()
		FreeMem(THIS.Address)
	ENDPROC

	PROCEDURE dwOSVersionInfoSize_Access()
		RETURN ReadUInt(THIS.Address)
	ENDPROC

	PROCEDURE dwOSVersionInfoSize_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WriteUInt(THIS.Address,lnNewVal)
	ENDPROC

	PROCEDURE dwMajorVersion_Access()
		RETURN ReadUInt(THIS.Address+4)
	ENDPROC

	PROCEDURE dwMajorVersion_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WriteUInt(THIS.Address+4,lnNewVal)
	ENDPROC

	PROCEDURE dwMinorVersion_Access()
		RETURN ReadUInt(THIS.Address+8)
	ENDPROC

	PROCEDURE dwMinorVersion_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WriteUInt(THIS.Address+8,lnNewVal)
	ENDPROC

	PROCEDURE dwBuildNumber_Access()
		RETURN ReadUInt(THIS.Address+12)
	ENDPROC

	PROCEDURE dwBuildNumber_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WriteUInt(THIS.Address+12,lnNewVal)
	ENDPROC

	PROCEDURE dwPlatformId_Access()
		RETURN ReadUInt(THIS.Address+16)
	ENDPROC

	PROCEDURE dwPlatformId_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,4294967295) MESSAGE 'Wrong datatype or value out of range!'
		WriteUInt(THIS.Address+16,lnNewVal)
	ENDPROC

	PROCEDURE szCSDVersion_Access()
		RETURN ReadCharArray(THIS.Address+20,128)
	ENDPROC

	PROCEDURE szCSDVersion_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'C' MESSAGE 'Wrong datatype or value out of range!'
		WriteCharArray(THIS.Address+20,lnNewVal,128)
	ENDPROC

	PROCEDURE wServicePackMajor_Access()
		RETURN ReadUShort(THIS.Address+148)
	ENDPROC

	PROCEDURE wServicePackMajor_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,65535) MESSAGE 'Wrong datatype or value out of range!'
		WriteUShort(THIS.Address+148,lnNewVal)
	ENDPROC

	PROCEDURE wServicePackMinor_Access()
		RETURN ReadUShort(THIS.Address+150)
	ENDPROC

	PROCEDURE wServicePackMinor_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,65535) MESSAGE 'Wrong datatype or value out of range!'
		WriteUShort(THIS.Address+150,lnNewVal)
	ENDPROC

	PROCEDURE wSuiteMask_Access()
		RETURN ReadUShort(THIS.Address+152)
	ENDPROC

	PROCEDURE wSuiteMask_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'N' AND BETWEEN(lnNewVal,0,65535) MESSAGE 'Wrong datatype or value out of range!'
		WriteUShort(THIS.Address+152,lnNewVal)
	ENDPROC

	PROCEDURE wProductType_Access()
		RETURN ReadChar(THIS.Address+154)
	ENDPROC

	PROCEDURE wProductType_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'C' MESSAGE 'Wrong datatype or value out of range!'
		WriteChar(THIS.Address+154,lnNewVal)
	ENDPROC

	PROCEDURE wReserved_Access()
		RETURN ReadChar(THIS.Address+155)
	ENDPROC

	PROCEDURE wReserved_Assign(lnNewVal)
		ASSERT TYPE('lnNewVal') = 'C' MESSAGE 'Wrong datatype or value out of range!'
		WriteChar(THIS.Address+155,lnNewVal)
	ENDPROC

ENDDEFINE

DEFINE CLASS GUITHREADINFO AS Relation

	Address = 0
	SizeOf = 48
	Name = "GUITHREADINFO"
	&& structure fields
	cbSize = .F.
	flags = .F.
	hwndActive = .F.
	hwndFocus = .F.
	hwndCapture = .F.
	hwndMenuOwner = .F.
	hwndMoveSize = .F.
	hwndCaret = .F.
	rcCaret = .NULL.

	PROCEDURE Init()
		THIS.Address = AllocMem(THIS.SizeOf)
		IF THIS.Address = 0
			ERROR(43)
			RETURN .F.
		ENDIF
		THIS.rcCaret = CREATEOBJECT('RECT',THIS.Address+32)
		THIS.cbSize = THIS.SizeOf
	ENDPROC

	PROCEDURE Destroy()
		FreeMem(THIS.Address)
	ENDPROC

	PROCEDURE Address_Assign(lnAddress)
		DO CASE
			CASE THIS.Address = 0
				THIS.Address = lnAddress
			CASE THIS.Address = lnAddress
			OTHERWISE
				THIS.Address = lnAddress
				THIS.rcCaret.Address = lnAddress+32
		ENDCASE
	ENDPROC

	PROCEDURE cbSize_Access()
		RETURN ReadUInt(THIS.Address)
	ENDPROC

	PROCEDURE cbSize_Assign(lnNewVal)
		WriteUInt(THIS.Address,lnNewVal)
	ENDPROC

	PROCEDURE flags_Access()
		RETURN ReadUInt(THIS.Address+4)
	ENDPROC

	PROCEDURE hwndActive_Access()
		RETURN ReadInt(THIS.Address+8)
	ENDPROC

	PROCEDURE hwndFocus_Access()
		RETURN ReadInt(THIS.Address+12)
	ENDPROC

	PROCEDURE hwndCapture_Access()
		RETURN ReadInt(THIS.Address+16)
	ENDPROC

	PROCEDURE hwndMenuOwner_Access()
		RETURN ReadInt(THIS.Address+20)
	ENDPROC

	PROCEDURE hwndMoveSize_Access()
		RETURN ReadInt(THIS.Address+24)
	ENDPROC

	PROCEDURE hwndCaret_Access()
		RETURN ReadInt(THIS.Address+28)
	ENDPROC

ENDDEFINE

DEFINE CLASS STARTUPINFO AS Relation

	Address = 0
	SizeOf = 68
	Name = "STARTUPINFO"
	&& structure fields
	cb = .F.
	&& lpReserved = .F.
	lpDesktop = .F.
	lpTitle = .F.
	dwX = .F.
	dwY = .F.
	dwXSize = .F.
	dwYSize = .F.
	dwXCountChars = .F.
	dwYCountChars = .F.
	dwFillAttribute = .F.
	dwFlags = .F.
	wShowWindow = .F.
	&& cbReserved2 = .F.
	&& lpReserved2 = .F.
	hStdInput = .F.
	hStdOutput = .F.
	hStdError = .F.

	PROCEDURE Init()
		THIS.Address = AllocMem(THIS.SizeOf)
		IF THIS.Address = 0
			ERROR(43)
			RETURN .F.
		ENDIF
		THIS.cb = THIS.SizeOf
	ENDPROC

	PROCEDURE Destroy()
		THIS.FreeMembers()
		FreeMem(THIS.Address)
	ENDPROC

	PROCEDURE FreeMembers()
		FreePMem(THIS.Address+4)
		FreePMem(THIS.Address+8)
		FreePMem(THIS.Address+12)
		FreePMem(THIS.Address+52)
	ENDPROC

	PROCEDURE cb_Access()
		RETURN ReadUInt(THIS.Address)
	ENDPROC

	PROCEDURE cb_Assign(lnNewVal)
		WriteUInt(THIS.Address,lnNewVal)
	ENDPROC

	PROCEDURE lpDesktop_Access()
		RETURN ReadPCString(THIS.Address+8)
	ENDPROC

	PROCEDURE lpDesktop_Assign(lnNewVal)
		WritePCString(THIS.Address+8,lnNewVal)
	ENDPROC

	PROCEDURE lpTitle_Access()
		RETURN ReadPCString(THIS.Address+12)
	ENDPROC

	PROCEDURE lpTitle_Assign(lnNewVal)
		WritePCString(THIS.Address+12,lnNewVal)
	ENDPROC

	PROCEDURE dwX_Access()
		RETURN ReadUInt(THIS.Address+16)
	ENDPROC

	PROCEDURE dwX_Assign(lnNewVal)
		WriteUInt(THIS.Address+16,lnNewVal)
	ENDPROC

	PROCEDURE dwY_Access()
		RETURN ReadUInt(THIS.Address+20)
	ENDPROC

	PROCEDURE dwY_Assign(lnNewVal)
		WriteUInt(THIS.Address+20,lnNewVal)
	ENDPROC

	PROCEDURE dwXSize_Access()
		RETURN ReadUInt(THIS.Address+24)
	ENDPROC

	PROCEDURE dwXSize_Assign(lnNewVal)
		WriteUInt(THIS.Address+24,lnNewVal)
	ENDPROC

	PROCEDURE dwYSize_Access()
		RETURN ReadUInt(THIS.Address+28)
	ENDPROC

	PROCEDURE dwYSize_Assign(lnNewVal)
		WriteUInt(THIS.Address+28,lnNewVal)
	ENDPROC

	PROCEDURE dwXCountChars_Access()
		RETURN ReadUInt(THIS.Address+32)
	ENDPROC

	PROCEDURE dwXCountChars_Assign(lnNewVal)
		WriteUInt(THIS.Address+32,lnNewVal)
	ENDPROC

	PROCEDURE dwYCountChars_Access()
		RETURN ReadUInt(THIS.Address+36)
	ENDPROC

	PROCEDURE dwYCountChars_Assign(lnNewVal)
		WriteUInt(THIS.Address+36,lnNewVal)
	ENDPROC

	PROCEDURE dwFillAttribute_Access()
		RETURN ReadUInt(THIS.Address+40)
	ENDPROC

	PROCEDURE dwFillAttribute_Assign(lnNewVal)
		WriteUInt(THIS.Address+40,lnNewVal)
	ENDPROC

	PROCEDURE dwFlags_Access()
		RETURN ReadUInt(THIS.Address+44)
	ENDPROC

	PROCEDURE dwFlags_Assign(lnNewVal)
		WriteUInt(THIS.Address+44,lnNewVal)
	ENDPROC

	PROCEDURE wShowWindow_Access()
		RETURN ReadUShort(THIS.Address+48)
	ENDPROC

	PROCEDURE wShowWindow_Assign(lnNewVal)
		WriteUShort(THIS.Address+48,lnNewVal)
	ENDPROC

	PROCEDURE hStdInput_Access()
		RETURN ReadPointer(THIS.Address+56)
	ENDPROC

	PROCEDURE hStdInput_Assign(lnNewVal)
		WritePointer(THIS.Address+56,lnNewVal)
	ENDPROC

	PROCEDURE hStdOutput_Access()
		RETURN ReadPointer(THIS.Address+60)
	ENDPROC

	PROCEDURE hStdOutput_Assign(lnNewVal)
		WritePointer(THIS.Address+60,lnNewVal)
	ENDPROC

	PROCEDURE hStdError_Access()
		RETURN ReadPointer(THIS.Address+64)
	ENDPROC

	PROCEDURE hStdError_Assign(lnNewVal)
		WritePointer(THIS.Address+64,lnNewVal)
	ENDPROC

ENDDEFINE

DEFINE CLASS PROCESS_INFORMATION AS Relation

	Address = 0
	SizeOf = 16
	Name = "PROCESS_INFORMATION"
	&& structure fields
	hProcess = .F.
	hThread = .F.
	dwProcessId = .F.
	dwThreadId = .F.

	PROCEDURE Init()
		THIS.Address = AllocMem(THIS.SizeOf)
		IF THIS.Address = 0
			ERROR(43)
			RETURN .F.
		ENDIF
	ENDPROC

	PROCEDURE Destroy()
		FreeMem(THIS.Address)
	ENDPROC

	PROCEDURE hProcess_Access()
		RETURN ReadPointer(THIS.Address)
	ENDPROC

	PROCEDURE hProcess_Assign(lnNewVal)
		WritePointer(THIS.Address,lnNewVal)
	ENDPROC

	PROCEDURE hThread_Access()
		RETURN ReadPointer(THIS.Address+4)
	ENDPROC

	PROCEDURE hThread_Assign(lnNewVal)
		WritePointer(THIS.Address+4,lnNewVal)
	ENDPROC

	PROCEDURE dwProcessId_Access()
		RETURN ReadUInt(THIS.Address+8)
	ENDPROC

	PROCEDURE dwProcessId_Assign(lnNewVal)
		WriteUInt(THIS.Address+8,lnNewVal)
	ENDPROC

	PROCEDURE dwThreadId_Access()
		RETURN ReadUInt(THIS.Address+12)
	ENDPROC

	PROCEDURE dwThreadId_Assign(lnNewVal)
		WriteUInt(THIS.Address+12,lnNewVal)
	ENDPROC

ENDDEFINE


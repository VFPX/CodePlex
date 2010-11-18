#ifndef _VFP2CMARSHAL_H__
#define _VFP2CMARSHAL_H__

// additional heap defines
#define HEAP_INITIAL_SIZE	1048576	// 1 MB
#define HEAP_ZE_FLAG		HEAP_ZERO_MEMORY|HEAP_GENERATE_EXCEPTIONS
#define HEAP_E_FLAG			HEAP_GENERATE_EXCEPTIONS
#define HEAP_FLAG			0

#define SAVEHEAPEXCEPTION()	Win32HeapExceptionHandler(GetExceptionCode())

// debugging macros and types
#ifdef _DEBUG
#define ADDDEBUGALLOC(pPointer,nSize) AddDebugAlloc((void*)pPointer,nSize)
#define REMOVEDEBUGALLOC(pPointer) RemoveDebugAlloc((void*)pPointer)
#define REPLACEDEBUGALLOC(pOrig,pNew,nSize) ReplaceDebugAlloc((void*)pOrig,(void*)pNew,nSize)

typedef struct _DBGALLOCINFO {
	void* pPointer;
	char* pProgInfo;
	int nSize;
	struct _DBGALLOCINFO *next;
} DBGALLOCINFO, *LPDBGALLOCINFO;
#else

#define ADDDEBUGALLOC(pPointer,nSize)
#define REMOVEDEBUGALLOC(pPointer)
#define REPLACEDEBUGALLOC(pOrig,pNew,nSize)

#endif

// some common code snippets for the marshaling routines
#define ARRAYLOCALS(pType) \
	pType pAddress; \
	int nRetVal; \
	unsigned short nRows, nDimensions; \
	pAddress = (pType)p1.ev_long; \
	nRows = (unsigned short)_ALen(r2.l_NTI, 1); \
	nDimensions = (unsigned short)_ALen(r2.l_NTI, 2); \
	nDimensions = nDimensions ? nDimensions : 1; \
	ResetArrayLocator(r2, nDimensions);

#define BEGIN_ARRAYGET() \
	while(++r2.l_sub2 <= nDimensions) \
	{ \
		r2.l_sub1 = 0; \
		while(++r2.l_sub1 <= nRows) \
		{

#define END_ARRAYGET(nIter) \
			if ((nRetVal = _Store(&r2, &tmpValue)) == 0) \
				pAddress##nIter; \
			else \
				RaiseError(nRetVal); \
		} \
	}

#define BEGIN_ARRAYSET() BEGIN_ARRAYGET() \
			if ((nRetVal = _Load(&r2, &tmpValue)) == 0) \
			{ 

#define END_ARRAYSET(nIter) \
				pAddress##nIter; \
			} \
			else \
				RaiseError(nRetVal); \
		} \
	}

#define COLUMNGETLOCALS(pType) \
	pType pAddress; \
	int nErrorNo, nRetVal; \
	char *pColumn; \
	Locator sFieldLoc; \
	pAddress = (pType)p1.ev_long; \
	if (!NullTerminateValue(p2)) \
		RaiseError(E_INSUFMEMORY); \
	pColumn = HandleToPtr(p2); \
	if (nErrorNo = FindFoxField(pColumn,&sFieldLoc,p3.ev_long)) \
		RaiseError(nErrorNo); \
	if ((nRetVal = RecCount(sFieldLoc)) < p3.ev_long) \
	{ \
		if (nErrorNo = AppendRecords(p3.ev_long-nRetVal, sFieldLoc)) \
			RaiseError(nErrorNo); \
	} \
	GoTop(sFieldLoc);
	
#define BEGIN_COLUMNGET() \
	while(p3.ev_long--) \
	{

#define END_COLUMNGET(nIter) \
		if ((nRetVal = _DBReplace(&sFieldLoc, &tmpValue)) == 0) \
		{ \
			pAddress##nIter; \
			Skip(1, sFieldLoc); \
		} \
		else \
			RaiseError(nRetVal); \
	}

#define COLUMNSETLOCALS(pType) \
	pType pAddress; \
	int nRetVal, nErrorNo; \
	char *pColumn; \
	Locator sFieldLoc; \
	Value tmpValue; \
	pAddress = (pType)p1.ev_long; \
	if (!NullTerminateValue(p2)) \
		RaiseError(E_INSUFMEMORY); \
	pColumn = HandleToPtr(p2); \
	if (nErrorNo = FindFoxField(pColumn,&sFieldLoc,p3.ev_long)) \
		RaiseError(nErrorNo);

#define BEGIN_COLUMNSET() \
	while(!Eof(sFieldLoc)) \
	{ \
		if ((nRetVal = _Load(&sFieldLoc, &tmpValue)) == 0) \
		{
			
#define END_COLUMNSET(nIter) \
			Skip(1, sFieldLoc); \
			pAddress##nIter; \
		} \
		else \
			RaiseError(nRetVal); \
	}

// typedefs for dynamic linking to heap functions
typedef BOOL (_stdcall *PHEAPSETINFO)(HANDLE, HEAP_INFORMATION_CLASS, PVOID, SIZE_T); // HeapSetInformation
typedef SIZE_T (_stdcall *PHEAPCOMPACT)(HANDLE, DWORD); // HeapCompact
typedef BOOL (_stdcall *PHEAPVALIDATE)(HANDLE, DWORD, LPCVOID); // HeapValidate
typedef BOOL (_stdcall *PHEAPWALK)(HANDLE, LPPROCESS_HEAP_ENTRY); // HeapWalk

#ifdef __cplusplus
extern "C" {
#endif

// function forward definitions
bool _stdcall VFP2C_Init_Marshal();
void _stdcall VFP2C_Destroy_Marshal();

int _stdcall Win32HeapExceptionHandler(int nExceptionCode);

#ifdef _DEBUG
void _stdcall AddDebugAlloc(void* pPointer, int nSize);
void _stdcall RemoveDebugAlloc(void* pPointer);
void _stdcall ReplaceDebugAlloc(void* pOrig, void *pNew, int nSize);
void _stdcall FreeDebugAlloc();
void _fastcall TrackMem(ParamBlk *parm);
void _fastcall AMemLeaks(ParamBlk *parm);
#endif

void _fastcall AllocMem(ParamBlk *parm);
void _fastcall AllocMemTo(ParamBlk *parm);
void _fastcall ReAllocMem(ParamBlk *parm);
void _fastcall FreeMem(ParamBlk *parm);
void _fastcall FreePMem(ParamBlk *parm);
void _fastcall FreeRefArray(ParamBlk *parm);
void _fastcall SizeOfMem(ParamBlk *parm);
void _fastcall ValidateMem(ParamBlk *parm);
void _fastcall CompactMem(ParamBlk *parm);
void _fastcall AMemBlocks(ParamBlk *parm);

void _fastcall AllocHGlobal(ParamBlk *parm);
void _fastcall FreeHGlobal(ParamBlk *parm);
void _fastcall ReAllocHGlobal(ParamBlk *parm);
void _fastcall LockHGlobal(ParamBlk *parm);
void _fastcall UnlockHGlobal(ParamBlk *parm);

void _stdcall WriteChar(char *pAddress, char* nNewVal);
void _stdcall WritePChar(char **pAddress, char* nNewVal);
void _fastcall WriteWChar(ParamBlk *parm);
void _fastcall WritePWChar(ParamBlk *parm);
void _stdcall WriteInt8(__int8 *pAddress, int nNewVal);
void _stdcall WritePInt8(__int8 **pAddress, int nNewVal);
void _stdcall WriteUInt8(unsigned __int8 *pAddress, unsigned int nNewVal);
void _stdcall WritePUInt8(unsigned __int8 **pAddress, unsigned int nNewVal);
void _stdcall WriteShort(short *pAddress, short nNewVal);
void _stdcall WritePShort(short **pAddress, short nNewVal);
void _stdcall WriteUShort(unsigned short *pAddress, unsigned short nNewVal);
void _stdcall WritePUShort(unsigned short **pAddress, unsigned short nNewVal);
void _stdcall WriteInt(int *pAddress, int nNewVal);
void _stdcall WritePInt(int **pAddress, int nNewVal);
void _stdcall WriteUInt(unsigned int *pAddress, unsigned int nNewVal);
void _stdcall WritePUInt(unsigned int **pAddress, unsigned int nNewVal);
void _stdcall WritePointer(void **pAddress, void *nNewVal);
void _stdcall WritePPointer(void ***pAddress, void *nNewVal);
void _stdcall WriteFloat(float *pAddress, float nNewVal);
void _stdcall WritePFloat(float **pAddress, float nNewVal);
void _stdcall WriteDouble(double *pAddress, double nNewVal);
void _stdcall WritePDouble(double **pAddress, double nNewVal);
void _fastcall WriteInt64(ParamBlk *parm);
void _fastcall WritePInt64(ParamBlk *parm);
void _fastcall WriteUInt64(ParamBlk *parm);
void _fastcall WritePUInt64(ParamBlk *parm);
void _fastcall WriteCString(ParamBlk *parm);
void _fastcall WritePCString(ParamBlk *parm);
void _fastcall WriteWString(ParamBlk *parm);
void _fastcall WritePWString(ParamBlk *parm);
void _fastcall WriteCharArray(ParamBlk *parm);
void _fastcall WriteWCharArray(ParamBlk *parm);
void _fastcall WriteBytes(ParamBlk *parm);
void _fastcall WriteLogical(ParamBlk *parm);
void _fastcall WritePLogical(ParamBlk *parm);

void _fastcall ReadChar(ParamBlk *parm);
void _fastcall ReadPChar(ParamBlk *parm);
short _stdcall ReadInt8(__int8 *pAddress);
short _stdcall ReadPInt8(__int8 **pAddress);
unsigned short _stdcall ReadUInt8(unsigned __int8 *pAddress);
unsigned short _stdcall ReadPUInt8(unsigned __int8 **pAddress);
short _stdcall ReadShort(short *pAddress);
short _stdcall ReadPShort(short **pAddress);
unsigned int _stdcall ReadUShort(unsigned short *pAddress);
unsigned int _stdcall ReadPUShort(unsigned short **pAddress);
int _stdcall ReadInt(int *pAddress);
int _stdcall ReadPInt(int **pAddress);
void _fastcall ReadUInt(ParamBlk *parm);
void _fastcall ReadPUInt(ParamBlk *parm);
void _fastcall ReadInt64AsDouble(ParamBlk *parm);
void _fastcall ReadPInt64AsDouble(ParamBlk *parm);
void _fastcall ReadUInt64AsDouble(ParamBlk *parm);
void _fastcall ReadPUInt64AsDouble(ParamBlk *parm);
float _stdcall ReadFloat(float *pAddress);
float _stdcall ReadPFloat(float **pAddress);
double _stdcall ReadDouble(double *pAddress);
double _stdcall ReadPDouble(double **pAddress);
void _fastcall ReadCString(ParamBlk *parm);
void _fastcall ReadCharArray(ParamBlk *parm);
void _fastcall ReadPCString(ParamBlk *parm);
void _fastcall ReadWString(ParamBlk *parm);
void _fastcall ReadPWString(ParamBlk *parm);
void _fastcall ReadWCharArray(ParamBlk *parm);
void _fastcall ReadLogical(ParamBlk *parm);
void _fastcall ReadPLogical(ParamBlk *parm);
void _fastcall ReadBytes(ParamBlk *parm);

void _fastcall UnMarshalArrayShort(ParamBlk *parm);
void _fastcall UnMarshalArrayUShort(ParamBlk *parm);
void _fastcall UnMarshalArrayInt(ParamBlk *parm);
void _fastcall UnMarshalArrayUInt(ParamBlk *parm);
void _fastcall UnMarshalArrayFloat(ParamBlk *parm);
void _fastcall UnMarshalArrayDouble(ParamBlk *parm);
void _fastcall UnMarshalArrayLogical(ParamBlk *parm);
void _fastcall UnMarshalArrayCString(ParamBlk *parm);
void _fastcall UnMarshalArrayWString(ParamBlk *parm);
void _fastcall UnMarshalArrayCharArray(ParamBlk *parm);
void _fastcall UnMarshalArrayWCharArray(ParamBlk *parm);
void _fastcall MarshalArrayShort(ParamBlk *parm);
void _fastcall MarshalArrayUShort(ParamBlk *parm);
void _fastcall MarshalArrayInt(ParamBlk *parm);
void _fastcall MarshalArrayUInt(ParamBlk *parm);
void _fastcall MarshalArrayFloat(ParamBlk *parm);
void _fastcall MarshalArrayDouble(ParamBlk *parm);
void _fastcall MarshalArrayLogical(ParamBlk *parm);
void _fastcall MarshalArrayCString(ParamBlk *parm);
void _fastcall MarshalArrayWString(ParamBlk *parm);
void _fastcall MarshalArrayCharArray(ParamBlk *parm);
void _fastcall MarshalArrayWCharArray(ParamBlk *parm);

void _fastcall UnMarshalCursorShort(ParamBlk *parm);
void _fastcall UnMarshalCursorUShort(ParamBlk *parm);
void _fastcall UnMarshalCursorInt(ParamBlk *parm);
void _fastcall UnMarshalCursorUInt(ParamBlk *parm);
void _fastcall UnMarshalCursorFloat(ParamBlk *parm);
void _fastcall UnMarshalCursorDouble(ParamBlk *parm);
void _fastcall UnMarshalCursorLogical(ParamBlk *parm);
void _fastcall UnMarshalCursorCString(ParamBlk *parm);
void _fastcall UnMarshalCursorWString(ParamBlk *parm);
void _fastcall UnMarshalCursorCharArray(ParamBlk *parm);
void _fastcall UnMarshalCursorWCharArray(ParamBlk *parm);
void _fastcall MarshalCursorShort(ParamBlk *parm);
void _fastcall MarshalCursorUShort(ParamBlk *parm);
void _fastcall MarshalCursorInt(ParamBlk *parm);
void _fastcall MarshalCursorUInt(ParamBlk *parm);
void _fastcall MarshalCursorFloat(ParamBlk *parm);
void _fastcall MarshalCursorDouble(ParamBlk *parm);
void _fastcall MarshalCursorLogical(ParamBlk *parm);
void _fastcall MarshalCursorCString(ParamBlk *parm);
void _fastcall MarshalCursorWString(ParamBlk *parm);
void _fastcall MarshalCursorCharArray(ParamBlk *parm);
void _fastcall MarshalCursorWCharArray(ParamBlk *parm);

void _fastcall Str2Short(ParamBlk *parm);
void _fastcall Short2Str(ParamBlk *parm);
void _fastcall Str2UShort(ParamBlk *parm);
void _fastcall UShort2Str(ParamBlk *parm);
void _fastcall Str2Long(ParamBlk *parm);
void _fastcall Long2Str(ParamBlk *parm);
void _fastcall Str2ULong(ParamBlk *parm);
void _fastcall ULong2Str(ParamBlk *parm);
void _fastcall Str2Double(ParamBlk *parm);
void _fastcall Double2Str(ParamBlk *parm);
void _fastcall Str2Float(ParamBlk *parm);
void _fastcall Float2Str(ParamBlk *parm);

// extern definitions for shared variables
extern HANDLE ghHeap;
extern UINT gnConvCP;

#ifdef __cplusplus
}
#endif // end of extern "C"

#endif // _VFP2CMARSHAL_H__
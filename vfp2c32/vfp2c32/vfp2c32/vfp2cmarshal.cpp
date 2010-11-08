#define _WIN32_WINNT 0x0400

#include <windows.h>
#include <stdio.h> // sprintf, memcpy and other common C library routines

#include "pro_ext.h" // general FoxPro library header
#include "vfp2c32.h"
#include "vfp2cutil.h"
#include "vfp2cmarshal.h"
#include "vfpmacros.h"
#include "vfp2ccppapi.h"

// handle to our default heap which is created at load time
HANDLE ghHeap = 0;

// codepage for Unicode character conversion
UINT gnConvCP = CP_ACP;

// dynamic function pointers
static PHEAPCOMPACT fpHeapCompact = 0;
static PHEAPVALIDATE fpHeapValidate = 0;
static PHEAPWALK fpHeapWalk = 0;

#ifdef _DEBUG
static LPDBGALLOCINFO gpDbgInfo = 0;
static BOOL gbTrackAlloc = FALSE;
#endif

bool _stdcall VFP2C_Init_Marshal()
{
	HMODULE hDll;
	// vars for changing the heap allocation algorithm
	PHEAPSETINFO fpHeapSetInformation;
	HEAP_INFORMATION_CLASS pInfo = HeapCompatibilityInformation;
	ULONG nLFHFlag = 2;

	// create default Heap
	if (ghHeap == 0)
	{
		if (!(ghHeap = HeapCreate(0,HEAP_INITIAL_SIZE,0)))
		{
			ADDWIN32ERROR(HeapCreate,GetLastError());
			return false;
		}
	}

	// we can use GetModuleHandle instead of LoadLibrary since kernel32.dll is loaded already by VFP for sure
	if (fpHeapCompact == 0)
	{
		hDll = GetModuleHandle("kernel32.dll");
		if (hDll)
		{
			fpHeapSetInformation = (PHEAPSETINFO)GetProcAddress(hDll,"HeapSetInformation");
			// if HeapSetInformation is supported (only on WinXP), call it to make our heap a low-fragmentation heap.
			if (fpHeapSetInformation)
				fpHeapSetInformation(ghHeap,pInfo,&nLFHFlag,sizeof(ULONG));

			fpHeapCompact = (PHEAPCOMPACT)GetProcAddress(hDll,"HeapCompact");
			fpHeapValidate = (PHEAPVALIDATE)GetProcAddress(hDll,"HeapValidate");
			fpHeapWalk = (PHEAPWALK)GetProcAddress(hDll,"HeapWalk");
		}
		else
		{
			ADDWIN32ERROR(GetModuleHandle,GetLastError());
			return false;
		}
	}

try
{
	FoxVariable pTempVar("__VFP2C_FLL_FILENAME", false);
	FoxString pFllFileName(MAX_PATH);

	pFllFileName.Len(GetModuleFileName(ghModule, pFllFileName, MAX_PATH));
	if (!pFllFileName.Len())
	{
		ADDWIN32ERROR(GetModuleFileName,GetLastError());
		return false;
	}

	pTempVar = pFllFileName;

	// declare additional functions not nativly exported by the FLL
	Execute("DECLARE WriteChar IN (m.__VFP2C_FLL_FILENAME) INTEGER, STRING");
	Execute("DECLARE WritePChar IN (m.__VFP2C_FLL_FILENAME) INTEGER, STRING");
    Execute("DECLARE WriteInt8 IN (m.__VFP2C_FLL_FILENAME) INTEGER, INTEGER");
	Execute("DECLARE WritePInt8 IN (m.__VFP2C_FLL_FILENAME) INTEGER, INTEGER");
	Execute("DECLARE WriteUInt8 IN (m.__VFP2C_FLL_FILENAME) INTEGER, INTEGER");
	Execute("DECLARE WritePUInt8 IN (m.__VFP2C_FLL_FILENAME) INTEGER, INTEGER");
	Execute("DECLARE WriteShort IN (m.__VFP2C_FLL_FILENAME) INTEGER, SHORT");
	Execute("DECLARE WritePShort IN (m.__VFP2C_FLL_FILENAME) INTEGER, SHORT");
	Execute("DECLARE WriteUShort IN (m.__VFP2C_FLL_FILENAME) INTEGER, SHORT");
	Execute("DECLARE WritePUShort IN (m.__VFP2C_FLL_FILENAME) INTEGER, SHORT");
	Execute("DECLARE WriteInt IN (m.__VFP2C_FLL_FILENAME) INTEGER, INTEGER");
    Execute("DECLARE WritePInt IN (m.__VFP2C_FLL_FILENAME) INTEGER, INTEGER");
	Execute("DECLARE WriteUInt IN (m.__VFP2C_FLL_FILENAME) INTEGER, INTEGER");
	Execute("DECLARE WritePUInt IN (m.__VFP2C_FLL_FILENAME) INTEGER, INTEGER");
	Execute("DECLARE WritePointer IN (m.__VFP2C_FLL_FILENAME) INTEGER, INTEGER");
	Execute("DECLARE WritePPointer IN (m.__VFP2C_FLL_FILENAME) INTEGER, INTEGER");
	Execute("DECLARE WriteFloat IN (m.__VFP2C_FLL_FILENAME) INTEGER, SINGLE");
	Execute("DECLARE WritePFloat IN (m.__VFP2C_FLL_FILENAME) INTEGER, SINGLE");
	Execute("DECLARE WriteDouble IN (m.__VFP2C_FLL_FILENAME) INTEGER, DOUBLE");
	Execute("DECLARE WritePDouble IN (m.__VFP2C_FLL_FILENAME) INTEGER, DOUBLE");
	Execute("DECLARE SHORT ReadInt8 IN (m.__VFP2C_FLL_FILENAME) INTEGER");
	Execute("DECLARE SHORT ReadPInt8 IN (m.__VFP2C_FLL_FILENAME) INTEGER");
	Execute("DECLARE SHORT ReadUInt8 IN (m.__VFP2C_FLL_FILENAME) INTEGER");
	Execute("DECLARE SHORT ReadPUInt8 IN (m.__VFP2C_FLL_FILENAME) INTEGER");
	Execute("DECLARE SHORT ReadShort IN (m.__VFP2C_FLL_FILENAME) INTEGER");
	Execute("DECLARE SHORT ReadPShort IN (m.__VFP2C_FLL_FILENAME) INTEGER");
	Execute("DECLARE INTEGER ReadUShort IN (m.__VFP2C_FLL_FILENAME) INTEGER");
	Execute("DECLARE INTEGER ReadPUShort IN (m.__VFP2C_FLL_FILENAME) INTEGER");
	Execute("DECLARE INTEGER ReadInt IN (m.__VFP2C_FLL_FILENAME) INTEGER");
    Execute("DECLARE INTEGER ReadPInt IN (m.__VFP2C_FLL_FILENAME) INTEGER");
    Execute("DECLARE SINGLE ReadFloat IN (m.__VFP2C_FLL_FILENAME) INTEGER");
    Execute("DECLARE SINGLE ReadPFloat IN (m.__VFP2C_FLL_FILENAME) INTEGER");
	Execute("DECLARE DOUBLE ReadDouble IN (m.__VFP2C_FLL_FILENAME) INTEGER");
	Execute("DECLARE DOUBLE ReadPDouble IN (m.__VFP2C_FLL_FILENAME) INTEGER");
}
catch(int nErrorNo)
{
	ADDCUSTOMERROREX("_Execute","Failed to DECLARE function. Error %I",nErrorNo);
	return false;
}
	return true;
}

void _stdcall VFP2C_Destroy_Marshal()
{
	if (ghHeap)
		HeapDestroy(ghHeap);

#ifdef _DEBUG
	FreeDebugAlloc();
#endif

	_Execute("CLEAR DLLS 'WriteChar','WritePChar','WriteInt8','WritePInt8','WriteUInt8','WritePUInt8','WriteShort',"
	"'WritePShort','WriteUShort','WritePUShort','WriteInt','WritePInt','WriteUInt','WritePUInt','WritePointer','WritePPointer',"
	"'WriteFloat','WritePFloat','WriteDouble','WritePDouble',"
	"'ReadInt8','ReadPInt8','ReadUInt8','ReadPUInt8','ReadShort','ReadPShort','ReadUShort','ReadPUShort','ReadInt','ReadPInt',"
	"'ReadFloat','ReadPFloat','ReadDouble','ReadPDouble'");
}

int _stdcall Win32HeapExceptionHandler(int nExceptionCode)
{
	gnErrorCount = 0;
	gaErrorInfo[0].nErrorType = VFP2C_ERRORTYPE_WIN32;
	gaErrorInfo[0].nErrorNo = nExceptionCode;
	strcpy(gaErrorInfo[0].aErrorFunction,"HeapAlloc/HeapReAlloc");

	if (nExceptionCode == STATUS_NO_MEMORY)
		strcpy(gaErrorInfo[0].aErrorMessage,"The allocation attempt failed because of a lack of available memory or heap corruption.");
	else if (nExceptionCode == STATUS_ACCESS_VIOLATION)
		strcpy(gaErrorInfo[0].aErrorMessage,"The allocation attempt failed because of heap corruption or improper function parameters.");
	else
		strcpy(gaErrorInfo[0].aErrorMessage,"Unknown exception code.");

	return EXCEPTION_EXECUTE_HANDLER;
}


#ifdef _DEBUG

void _stdcall AddDebugAlloc(void* pPointer, int nSize)
{
	Value vProgInfo;
	vProgInfo.ev_type = '0';
	LPDBGALLOCINFO pDbg;	
	char *pProgInfo = 0;

	if (pPointer && gbTrackAlloc)
	{
		pDbg = (LPDBGALLOCINFO)malloc(sizeof(DBGALLOCINFO));
		if (!pDbg)
			return;

		_Evaluate(&vProgInfo, "ALLTRIM(STR(LINENO())) + ':' + PROGRAM() + CHR(0)");
		if (Vartype(vProgInfo) == 'C')
		{
			pProgInfo = strdup(HandleToPtr(vProgInfo));
			FreeHandle(vProgInfo);
		}

		pDbg->pPointer = pPointer;
		pDbg->pProgInfo = pProgInfo;
		pDbg->nSize = nSize;
		pDbg->next = gpDbgInfo;
		gpDbgInfo = pDbg;
	}
}

void _stdcall RemoveDebugAlloc(void* pPointer)
{
	LPDBGALLOCINFO pDbg = gpDbgInfo, pDbgPrev = 0;
    
	if (pPointer && gbTrackAlloc)
	{
		while (pDbg && pDbg->pPointer != pPointer)
		{
			pDbgPrev = pDbg;
			pDbg = pDbg->next;
		}

		if (pDbg)
		{
			if (pDbgPrev)
				pDbgPrev->next = pDbg->next;
			else
				gpDbgInfo = pDbg->next;

			if (pDbg->pProgInfo)
				free(pDbg->pProgInfo);
			free(pDbg);
		}
	}
}

void _stdcall ReplaceDebugAlloc(void* pOrig, void* pNew, int nSize)
{
	LPDBGALLOCINFO pDbg = gpDbgInfo;
	Value vProgInfo;
	vProgInfo.ev_type = '0';
	char* pProgInfo = 0;

	if (!pNew || !gbTrackAlloc)
		return;
    
	while (pDbg && pDbg->pPointer != pOrig)
		pDbg = pDbg->next;

    if (pDbg)
	{
		_Evaluate(&vProgInfo, "ALLTRIM(STR(LINENO())) + ':' + PROGRAM() + CHR(0)");
		if (Vartype(vProgInfo) == 'C')
		{
			pProgInfo = strdup(HandleToPtr(vProgInfo));
			FreeHandle(vProgInfo);
		}

		if (pDbg->pProgInfo)
			free(pDbg->pProgInfo);

		pDbg->pPointer = pNew;
		pDbg->pProgInfo = pProgInfo;
		pDbg->nSize = nSize;
	}
}

void _stdcall FreeDebugAlloc()
{
	LPDBGALLOCINFO pDbg = gpDbgInfo, pDbgEx;
	while (pDbg)
	{
		pDbgEx = pDbg->next;
		if (pDbg->pProgInfo)
			free(pDbg->pProgInfo);
		free(pDbg);
		pDbg = pDbgEx;
	}
	gpDbgInfo = 0;
}

void _fastcall AMemLeaks(ParamBlk *parm)
{
try
{
	LPDBGALLOCINFO pDbg = gpDbgInfo;
	if (!pDbg)
	{
		Return(0);
		return;
	}

	FoxArray aMemLeaks(p1);
	FoxString vMemInfo(VFP2C_ERROR_MESSAGE_LEN);
	int nRows = 0;

	aMemLeaks.Dimension(1,4);

	while (pDbg)
	{
		nRows++;
		aMemLeaks.Dimension(nRows, 4);

		aMemLeaks(nRows, 1) = (int)pDbg->pPointer;
		aMemLeaks(nRows, 2) = pDbg->nSize;
		aMemLeaks(nRows, 3) = vMemInfo = pDbg->pProgInfo;

		vMemInfo.Len(min(pDbg->nSize,VFP2C_ERROR_MESSAGE_LEN));
		memcpy(vMemInfo, pDbg->pPointer, vMemInfo.Len());
		aMemLeaks(nRows, 4) = vMemInfo;

		pDbg = pDbg->next;
	}

	aMemLeaks.ReturnRows();
	return;
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}	
}

void _fastcall TrackMem(ParamBlk *parm)
{
	gbTrackAlloc = (BOOL)p1.ev_length;
	if (PCOUNT() == 2 && p2.ev_length)
		FreeDebugAlloc();
}

#endif // DEBUG

// FLL memory allocation functions using FLL's standard heap
void _fastcall AllocMem(ParamBlk *parm)
{
	void *pAlloc = 0;
	__try
	{
		pAlloc = HeapAlloc(ghHeap,HEAP_ZE_FLAG,p1.ev_long);
	}
	__except(SAVEHEAPEXCEPTION()) { }

	ADDDEBUGALLOC(pAlloc,p1.ev_long);

	Return(pAlloc);
}

void _fastcall AllocMemTo(ParamBlk *parm)
{
	void *pAlloc = 0;

	if (!p1.ev_long)
		RaiseError(E_INVALIDPARAMS);

	__try
	{
		pAlloc = HeapAlloc(ghHeap,HEAP_ZE_FLAG,p2.ev_long);
	}
	__except(SAVEHEAPEXCEPTION()) { }
	
	if (pAlloc)
		*(void**)p1.ev_long = pAlloc;

	ADDDEBUGALLOC(pAlloc,p2.ev_long);

	Return(pAlloc);
}

void _fastcall ReAllocMem(ParamBlk *parm)
{
	void *pAlloc = 0;
	__try
	{
		if (p1.ev_long)
		{
			pAlloc = HeapReAlloc(ghHeap,HEAP_ZE_FLAG,(void*)p1.ev_long,p2.ev_long);
			REPLACEDEBUGALLOC(p1.ev_long,pAlloc,p2.ev_long);
		}
		else
		{
			pAlloc = HeapAlloc(ghHeap,HEAP_ZE_FLAG,p2.ev_long);
			ADDDEBUGALLOC(pAlloc,p2.ev_long);
		}
    }
	__except(SAVEHEAPEXCEPTION()) { }

	Return(pAlloc);
}

void _fastcall FreeMem(ParamBlk *parm)
{
	if (p1.ev_long)
	{
		if (HeapFree(ghHeap,0,(void*)p1.ev_long))
		{
			REMOVEDEBUGALLOC(p1.ev_long);
		}
		else
		{
			SAVEWIN32ERROR(HeapFree,GetLastError());
			RaiseError(E_APIERROR);
		}
	}
}

void _fastcall FreePMem(ParamBlk *parm)
{
	void* pAlloc;
	if (p1.ev_long)
	{
		if ((pAlloc = *(void**)p1.ev_long))
		{
			if (HeapFree(ghHeap,0,pAlloc))
			{
				REMOVEDEBUGALLOC(pAlloc);
			}
			else
			{
				SAVEWIN32ERROR(HeapFree,GetLastError());
				RaiseError(E_APIERROR);
			}
		}
	}
}

void _fastcall FreeRefArray(ParamBlk *parm)
{
	void **pAddress;
	int nStartElement, nElements;
	BOOL bApiRet = TRUE;

	if (p2.ev_long < 1 || p2.ev_long > p3.ev_long)
		RaiseError(E_INVALIDPARAMS);

	pAddress = (void**)p1.ev_long;
	nStartElement = --p2.ev_long;
	nElements = p3.ev_long;
	pAddress += nStartElement;
	nElements -= nStartElement;
	
	RESETWIN32ERRORS();

	while(nElements--)
	{
		if (*pAddress)
		{
			if (!HeapFree(ghHeap,0,*pAddress))
			{
				ADDWIN32ERROR(HeapFree,GetLastError());
				bApiRet = FALSE;
			}
		}
		pAddress++;
	}
	Return(bApiRet == TRUE);
}

void _fastcall SizeOfMem(ParamBlk *parm)
{
	if (p1.ev_long)
		Return((int)HeapSize(ghHeap,0,(void*)p1.ev_long));
	else
		Return(0);
}

void _fastcall ValidateMem(ParamBlk *parm)
{
	if (fpHeapValidate)
		Return(fpHeapValidate(ghHeap,0,(void*)p1.ev_long) > 0);
	else
		Return(false);
}

void _fastcall CompactMem(ParamBlk *parm)
{
	if (fpHeapCompact)
		Return((int)fpHeapCompact(ghHeap,0));
	else
		Return(0);
}

// wrappers around GlobalAlloc, GlobalFree etc .. for movable memory objects ..
void _fastcall AllocHGlobal(ParamBlk *parm)
{
	HGLOBAL hMem;
	hMem = GlobalAlloc(GMEM_MOVEABLE|GMEM_ZEROINIT,(SIZE_T)p1.ev_long);
	if (hMem)
	{
		ADDDEBUGALLOC(hMem,p1.ev_long);
		Return(hMem);
	}
	else
	{
		SAVEWIN32ERROR(GlobalAlloc,GetLastError());
		RaiseError(E_APIERROR);
	}
}

void _fastcall FreeHGlobal(ParamBlk *parm)
{
	if (!GlobalFree((HGLOBAL)p1.ev_long)) /* returns NULL on success */
	{
		REMOVEDEBUGALLOC(p1.ev_long);
	}
	else
	{
		SAVEWIN32ERROR(GlobalFree,GetLastError());
		RaiseError(E_APIERROR);
	}
}

void _fastcall ReAllocHGlobal(ParamBlk *parm)
{
	HGLOBAL hMem;
	hMem = GlobalReAlloc((HGLOBAL)p1.ev_long,(SIZE_T)p2.ev_long,GMEM_MOVEABLE|GMEM_ZEROINIT);
	if (hMem)
	{
		REPLACEDEBUGALLOC(p1.ev_long,hMem,p2.ev_long);		
		Return(hMem);
	}
	else
	{
		SAVEWIN32ERROR(GlobalReAlloc,GetLastError());
		RaiseError(E_APIERROR);
	}
}

void _fastcall LockHGlobal(ParamBlk *parm)
{
	LPVOID pMem;
	pMem = GlobalLock((HGLOBAL)p1.ev_long);
	if (pMem)
		Return(pMem);
	else
	{
		SAVEWIN32ERROR(GlobalLock,GetLastError());
		RaiseError(E_APIERROR);
	}
}

void _fastcall UnlockHGlobal(ParamBlk *parm)
{
	BOOL bRet;
	DWORD nLastError;
	
	bRet = GlobalUnlock((HGLOBAL)p1.ev_long);

	if (!bRet)
	{
		nLastError = GetLastError();
		if (nLastError == NO_ERROR)
			Return(1);
		else
		{
			SAVEWIN32ERROR(GlobalUnlock,nLastError);
			RaiseError(E_APIERROR);
		}
	}
	else
		Return(2);
}

void _fastcall AMemBlocks(ParamBlk *parm)
{
try
{
	if (!fpHeapWalk)
		throw E_NOENTRYPOINT;

	FoxArray pArray(p1,1,3);
	PROCESS_HEAP_ENTRY pEntry;
	DWORD nLastError;

	pEntry.lpData = NULL;

	if (!fpHeapWalk(ghHeap,&pEntry))
	{
		nLastError = GetLastError();
		if (nLastError == ERROR_NO_MORE_ITEMS)
			Return(0);
		else
		{
			SAVEWIN32ERROR(HeapWalk,nLastError);
			throw E_APIERROR;
		}
		return;
	}

	unsigned int nRow;
	do 
	{
		nRow = pArray.Grow();
		pArray(nRow,1) = (int)pEntry.lpData;
		pArray(nRow,2) = (int)pEntry.cbData;
		pArray(nRow,3) = (int)pEntry.cbOverhead;
	} while (fpHeapWalk(ghHeap,&pEntry));
	
	nLastError = GetLastError();
    if (nLastError != ERROR_NO_MORE_ITEMS)
	{
		SAVEWIN32ERROR(HeapWalk,nLastError);
		throw E_APIERROR;
	}
	else
		pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _stdcall WriteChar(char *pAddress, char* nNewVal)
{
	*pAddress = *nNewVal;
}

void _stdcall WritePChar(char **pAddress, char* nNewVal)
{
	**pAddress = *nNewVal;
}

void _fastcall WriteWChar(ParamBlk *parm)
{
	if (p2.ev_length)
	{
		MultiByteToWideChar(PCOUNT() == 2 ? gnConvCP : (UINT)p3.ev_long,0,HandleToPtr(p2),1,(wchar_t*)p1.ev_long,1);
	}
	else
		*(wchar_t*)p1.ev_long = L'\0';
}

void _fastcall WritePWChar(ParamBlk *parm)
{
	if (p2.ev_length)
	{
		MultiByteToWideChar(PCOUNT() == 2 ? gnConvCP : (UINT)p3.ev_long,0,HandleToPtr(p2),1,*(wchar_t**)p1.ev_long,1);
	}
	else
		**(wchar_t**)p1.ev_long = L'\0';
}

void _stdcall WriteInt8(__int8 *pAddress, int nNewVal)
{
	*pAddress = (__int8)nNewVal;
}

void _stdcall WritePInt8(__int8 **pAddress, int nNewVal)
{
	**pAddress = (__int8)nNewVal;
}

void _stdcall WriteUInt8(unsigned __int8 *pAddress, unsigned int nNewVal)
{
	*pAddress = (unsigned __int8)nNewVal;
}

void _stdcall WritePUInt8(unsigned __int8 **pAddress, unsigned int nNewVal)
{
	**pAddress = (unsigned __int8)nNewVal;
}

void _stdcall WriteShort(short *pAddress, short nNewVal)
{
	*pAddress = nNewVal;
}

void _stdcall WritePShort(short **pAddress, short nNewVal)
{
	**pAddress = nNewVal;
}

void _stdcall WriteUShort(unsigned short *pAddress, unsigned short nNewVal)
{
	*pAddress = nNewVal;
}

void _stdcall WritePUShort(unsigned short **pAddress, unsigned short nNewVal)
{
	**pAddress = nNewVal;
}

void _stdcall WriteInt(int *pAddress, int nNewVal)
{
	*pAddress = nNewVal;
}

void _stdcall WritePInt(int **pAddress, int nNewVal)
{
	**pAddress = nNewVal;
}

void _stdcall WriteUInt(unsigned int *pAddress, unsigned int nNewVal)
{
	*pAddress = nNewVal;
}

void _stdcall WritePUInt(unsigned int **pAddress, unsigned int nNewVal)
{
	**pAddress = nNewVal;
}

void _stdcall WritePointer(void **pAddress, void *nNewVal)
{
	*pAddress = nNewVal;
}

void _stdcall WritePPointer(void ***pAddress, void *nNewVal)
{
	**pAddress = nNewVal;
}

void _stdcall WriteFloat(float *pAddress, float nNewVal)
{
	*pAddress = nNewVal;
}

void _stdcall WritePFloat(float **pAddress, float nNewVal)
{
	**pAddress = nNewVal;
}

void _stdcall WriteDouble(double *pAddress, double nNewVal)
{
	*pAddress = nNewVal;
}

void _stdcall WritePDouble(double **pAddress, double nNewVal)
{
	**pAddress = nNewVal;
}

void _fastcall WriteInt64(ParamBlk *parm)
{
	__int64 *pAddress = (__int64*)p1.ev_long;

	if (Vartype(p1) == 'C')
	{
		if (!NullTerminateValue(p2))
			RaiseError(E_INSUFMEMORY);
		*pAddress = StringToInt64(HandleToPtr(p2));
	}
	else if (Vartype(p2) == 'I')
		*pAddress = (__int64)p2.ev_long;
	else if (Vartype(p1) == 'N')
		*pAddress = (__int64)p2.ev_real;
	else 
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WritePInt64(ParamBlk *parm)
{
	__int64 **pAddress = (__int64**)p1.ev_long;

	if (Vartype(p1) == 'C')
	{
		if (!NullTerminateValue(p2))
			RaiseError(E_INSUFMEMORY);
		**pAddress = StringToInt64(HandleToPtr(p2));
	}
	else if (Vartype(p2) == 'I')
		**pAddress = (__int64)p2.ev_long;
	else if (Vartype(p1) == 'N')
		**pAddress = (__int64)p2.ev_real;
	else 
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WriteUInt64(ParamBlk *parm)
{
	unsigned __int64 *pAddress = (unsigned __int64*)p1.ev_long;

	if (Vartype(p1) == 'C')
	{
		if (!NullTerminateValue(p2))
			RaiseError(E_INSUFMEMORY);
		*pAddress = StringToUInt64(HandleToPtr(p2));
	}
	else if (Vartype(p2) == 'I')
		*pAddress = (unsigned __int64)p2.ev_long;
	else if (Vartype(p1) == 'N')
		*pAddress = (unsigned __int64)p2.ev_real;
	else 
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WritePUInt64(ParamBlk *parm)
{
	unsigned __int64 **pAddress = (unsigned __int64**)p1.ev_long;

	if (Vartype(p1) == 'C')
	{
		if (!NullTerminateValue(p2))
			RaiseError(E_INSUFMEMORY);
		**pAddress = StringToUInt64(HandleToPtr(p2));
	}
	else if (Vartype(p2) == 'I')
		**pAddress = (unsigned __int64)p2.ev_long;
	else if (Vartype(p1) == 'N')
		**pAddress = (unsigned __int64)p2.ev_real;
	else 
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WriteCString(ParamBlk *parm)
{
	char *pNewAddress = 0;

	__try
	{
		if (p1.ev_long)
		{
			pNewAddress = (char*)HeapReAlloc(ghHeap,HEAP_E_FLAG,(void*)p1.ev_long,p2.ev_length+1);
			REPLACEDEBUGALLOC(p1.ev_long,pNewAddress,p2.ev_length+1);
		}
		else
		{
			pNewAddress = (char*)HeapAlloc(ghHeap,HEAP_E_FLAG,p2.ev_length+1);
			ADDDEBUGALLOC(pNewAddress,p2.ev_length+1);
		}
	}
	__except(SAVEHEAPEXCEPTION()) { }

	if (pNewAddress)
	{
		memcpy(pNewAddress,HandleToPtr(p2),p2.ev_length);
		pNewAddress[p2.ev_length] = '\0';
		Return((void*)pNewAddress);
	}
	else
		RaiseError(E_APIERROR);
}

/*
void _fastcall WriteGCString(ParamBlk *parm)
{
	HGLOBAL hHandle;
	char *pAddress, *pString;

	if (!EXPANDHAND(p2,1))
		RaiseError(E_E_INSUFMEMORY);

	if (p1.ev_long)
		hHandle = GlobalAlloc(GMEM_MOVEABLE,p2.ev_length+1);
	else
		hHandle = GlobalReAlloc((HGLOBAL)p1.ev_long,p2.ev_length+1,GMEM_MOVEABLE); 

	if (hHandle)
	{
		pAddress = GlobalLock(hHandle);
		memcpy(pAddress,HandleToPtr(p2),p2.ev_length);
		pAddress[p2.ev_length] = '\0';
		GlobalUnlock(hHandle);
		RET_POINTER(hHandle);
	}
	else 
		RAISEWIN32ERROR(p1.ev_long ? "GlobalAlloc" : "GlobalReAlloc");
}
*/

void _fastcall WritePCString(ParamBlk *parm)
{
	char *pNewAddress = 0;
	char **pOldAddress = (char**)p1.ev_long;

	if (Vartype(p2) == 'C' && pOldAddress)
	{
		__try
		{
			if ((*pOldAddress))
			{
				pNewAddress = (char*)HeapReAlloc(ghHeap,HEAP_E_FLAG,(*pOldAddress),p2.ev_length+1);
				REPLACEDEBUGALLOC(*pOldAddress,pNewAddress,p2.ev_length);
			}
			else
			{
				pNewAddress = (char*)HeapAlloc(ghHeap,HEAP_E_FLAG,p2.ev_length+1);
				ADDDEBUGALLOC(pNewAddress,p2.ev_length);
			}
		}
		__except(SAVEHEAPEXCEPTION()) { }

		if (pNewAddress)
		{
			*pOldAddress = pNewAddress;
			memcpy(pNewAddress,HandleToPtr(p2),p2.ev_length);
			pNewAddress[p2.ev_length] = '\0';		
			Return((void*)pNewAddress);
			return;
		}
		else
			RaiseError(E_APIERROR);
	}
	else if (Vartype(p2) == '0' && pOldAddress)
	{
		if ((*pOldAddress))
		{
			if (HeapFree(ghHeap,0,*pOldAddress))
			{
				REMOVEDEBUGALLOC(*pOldAddress);
				*pOldAddress = 0;
				Return(1);
			}
			else
			{
				SAVEWIN32ERROR(HeapFree,GetLastError());
				RaiseError(E_APIERROR);
			}
		}
		else
			Return(1);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WriteWString(ParamBlk *parm)
{
	int nStringLen, nBytesNeeded, nBytesWritten;
    wchar_t *pDest = 0;
	
	nStringLen = (int)p2.ev_length;
	nBytesNeeded = nStringLen * sizeof(wchar_t) + sizeof(wchar_t);

	__try
	{
		if (p1.ev_long)
		{
			pDest = (wchar_t*)HeapReAlloc(ghHeap,HEAP_E_FLAG,(wchar_t*)p1.ev_long,nBytesNeeded);
			REPLACEDEBUGALLOC(p1.ev_long,pDest,nBytesNeeded);
		}
		else
		{
			pDest = (wchar_t*)HeapAlloc(ghHeap,HEAP_E_FLAG,nBytesNeeded);
			ADDDEBUGALLOC(pDest,nBytesNeeded);
		}
	}
	__except(SAVEHEAPEXCEPTION()) { }

	if (pDest)
	{
		if (nStringLen)
		{
			nBytesWritten = MultiByteToWideChar(PCOUNT() == 2 ? gnConvCP : (UINT)p3.ev_long,0,HandleToPtr(p2),nStringLen,pDest,nBytesNeeded);
			if (nBytesWritten)
				pDest[nBytesWritten] = L'\0';
			else
				RAISEWIN32ERROR(MultiByteToWideChar,GetLastError());
		}
		else
			pDest[0] = L'\0';
		Return((void*)pDest);
	}
	else
		RaiseError(E_APIERROR);
}

void _fastcall WritePWString(ParamBlk *parm)
{
	int nStringLen, nBytesNeeded, nBytesWritten;
	wchar_t *pDest = 0;
	wchar_t **pOld = (wchar_t**)p1.ev_long;

	if (Vartype(p2) == 'C' && pOld)
	{
		nStringLen = (int)p2.ev_length;
		nBytesNeeded = nStringLen * sizeof(wchar_t) + sizeof(wchar_t);

		__try
		{
			if ((*pOld))
			{
				pDest = (wchar_t*)HeapReAlloc(ghHeap,HEAP_ZE_FLAG,*pOld,nBytesNeeded);
				REPLACEDEBUGALLOC(*pOld,pDest,nBytesNeeded);
			}
			else
			{
				pDest = (wchar_t*)HeapAlloc(ghHeap,HEAP_ZE_FLAG,nBytesNeeded);
				ADDDEBUGALLOC(pDest,nBytesNeeded);
			}
		}
		__except(SAVEHEAPEXCEPTION()) { }

		if (pDest)
		{
			nBytesWritten = MultiByteToWideChar(PCOUNT() == 2 ? gnConvCP : (UINT)p3.ev_long,0,HandleToPtr(p2),nStringLen,pDest,nBytesNeeded);
			if (nBytesWritten)
			{
				pDest[nBytesWritten] = L'\0';
				*pOld = pDest;
			}
			else
				RAISEWIN32ERROR(MultiByteToWideChar,GetLastError());
		}
		else
			RaiseError(E_APIERROR);
	}
	else if (Vartype(p2) == '0' && pOld)
	{
		if ((*pOld))
		{
			if (HeapFree(ghHeap,0,*pOld))
			{
				REMOVEDEBUGALLOC(*pOld);
				*pOld = 0;
				Return(0);
			}
			else
			{
				SAVEWIN32ERROR(HeapFree,GetLastError());
				RaiseError(E_APIERROR);
			}
		}
		else
			Return(0);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WriteCharArray(ParamBlk *parm)
{
	char *pDest = (char*)p1.ev_long;

	if (PCOUNT() == 2 || (long)p2.ev_length < p3.ev_long)
	{
		memcpy(pDest,HandleToPtr(p2),p2.ev_length);
		pDest[p2.ev_length] = '\0';
	}
	else
	{
		memcpy(pDest,HandleToPtr(p2),p3.ev_long);
		pDest[p3.ev_long-1] = '\0';
	}
}

void _fastcall WriteWCharArray(ParamBlk *parm)
{
	int nBytesWritten, nArrayWidth, nStringLen;
	wchar_t *pDest = (wchar_t*)p1.ev_long;
	nArrayWidth = p3.ev_long - 1; // -1 for null terminator
	nStringLen = (int)p2.ev_length;

	if (nStringLen)
	{
		nBytesWritten = MultiByteToWideChar(PCOUNT() == 3 ? gnConvCP : (UINT)p4.ev_long,0,HandleToPtr(p2),min(nStringLen,nArrayWidth),pDest,nArrayWidth);
		if (nBytesWritten)
			pDest[nBytesWritten] = L'\0';
		else
			RAISEWIN32ERROR(MultiByteToWideChar,GetLastError());
	}
	else
		*pDest = L'\0';
}

void _fastcall WriteBytes(ParamBlk *parm)
{
	memcpy((void*)p1.ev_long,HandleToPtr(p2),PCOUNT() == 3 ? min(p2.ev_length,(UINT)p3.ev_long) : p2.ev_length);
}

void _fastcall WriteLogical(ParamBlk *parm)
{
	*(unsigned int*)p1.ev_long = p2.ev_length;
}

void _fastcall WritePLogical(ParamBlk *parm)
{
	**(unsigned int**)p1.ev_long = p2.ev_length;
}

void _fastcall ReadChar(ParamBlk *parm)
{
	char *pChar;
	V_STRINGN(cChar,1);
	if (AllocHandleEx(cChar,1))
	{
		pChar = HandleToPtr(cChar);
		if (p1.ev_long)
			*pChar = *(char*)p1.ev_long;
		else
			*pChar = '\0';
		
		Return(cChar);
		return;
	}
	else
		RaiseError(E_INSUFMEMORY);
}

void _fastcall ReadPChar(ParamBlk *parm)
{
	char *pChar;
	V_STRINGN(cChar,1);

	if (AllocHandleEx(cChar,1))
	{
		pChar = HandleToPtr(cChar);
		if (p1.ev_long && *(char**)p1.ev_long)
			*pChar = **(char**)p1.ev_long;
		else
			*pChar = '\0';

		Return(cChar);
		return;
	}
	else
		RaiseError(E_INSUFMEMORY);
}

short _stdcall ReadInt8(__int8 *pAddress)
{
	return (short)*pAddress;
}

short _stdcall ReadPInt8(__int8 **pAddress)
{
	return (short)**pAddress;
}

unsigned short _stdcall ReadUInt8(unsigned __int8 *pAddress)
{
	return (unsigned short)*pAddress;
}

unsigned short _stdcall ReadPUInt8(unsigned __int8 **pAddress)
{
	return (unsigned short)**pAddress;
}

short _stdcall ReadShort(short *pAddress)
{
	return *pAddress;
}

short _stdcall ReadPShort(short **pAddress)
{
	return **pAddress;
}

// Cast unsigned short's to next bigger type cause "DECLARE SHORT .." in VFP is limited to signed short's
// this problem only occurs when returning unsigned values from C to VFP not when they are passed
// e.g "DECLARE WriteUShort INTERGER, SHORT" works nicely cause VFP converts the value correctly to an
// unsigned short. But when returning values back to VFP it always assumes them to be signed, which
// makes this workaround neccessary. (the same is true for INTEGER/LONG) 
unsigned int _stdcall ReadUShort(unsigned short *pAddress)
{
	return (unsigned int)*pAddress;
}

unsigned int _stdcall ReadPUShort(unsigned short **pAddress)
{
	return (unsigned int)**pAddress;
}

int _stdcall ReadInt(int *pAddress)
{
	return *pAddress;
}

int _stdcall ReadPInt(int **pAddress)
{
	return **pAddress;
}

// Cast to double (float is not big enough to hold an unsigned long)
// cause of sign problem (see ReadUShort for an explanation)
void _fastcall ReadUInt(ParamBlk *parm)
{
	if (*(int*)p1.ev_long >= 0)
		Return(*(int*)p1.ev_long);
	else
		Return(*(unsigned int*)p1.ev_long);
}

void _fastcall ReadPUInt(ParamBlk *parm)
{
	if (**(int**)p1.ev_long >= 0)
		Return(**(int**)p1.ev_long);
	else
		Return(**(unsigned int**)p1.ev_long);
}

void _fastcall ReadInt64AsDouble(ParamBlk *parm)
{
	Return(*(__int64*)p1.ev_long);
}

void _fastcall ReadPInt64AsDouble(ParamBlk *parm)
{
	Return(**(__int64**)p1.ev_long);
}

void _fastcall ReadUInt64AsDouble(ParamBlk *parm)
{
	Return(*(unsigned __int64*)p1.ev_long);
}

void _fastcall ReadPUInt64AsDouble(ParamBlk *parm)
{
	Return(**(unsigned __int64**)p1.ev_long);
}

float _stdcall ReadFloat(float *pAddress)
{
	return *pAddress;
}

float _stdcall ReadPFloat(float **pAddress)
{
	return **pAddress;
}

double _stdcall ReadDouble(double *pAddress)
{
	return *pAddress;
}

double _stdcall ReadPDouble(double **pAddress)
{
	return **pAddress;
}

void _fastcall ReadCString(ParamBlk *parm)
{
	char aNothing[1];
	if (p1.ev_long)
	{
		Return((char*)p1.ev_long);
		return;
	}
	else
	{
		aNothing[0] = '\0';
		Return((char*)aNothing);
	}
}

void _fastcall ReadCharArray(ParamBlk *parm)
{
	V_STRING(cBuffer);
	char* pDest;

	if (AllocHandleEx(cBuffer,p2.ev_long))
	{
		pDest = HandleToPtr(cBuffer);
		cBuffer.ev_length = strncpyex(pDest,(const char*)p1.ev_long,p2.ev_long);
		Return(cBuffer);
	}
	else
		RaiseError(E_INSUFMEMORY);
}

void _fastcall ReadPCString(ParamBlk *parm)
{
	char aNothing[1];
	if (*(char**)p1.ev_long)
		_RetChar(*(char**)p1.ev_long);
	else
	{
		aNothing[0] = '\0';
		_RetChar((char*)aNothing);
	}
}

void _fastcall ReadWString(ParamBlk *parm)
{
	V_STRING(cBuffer);
	int nStringLen, nBufferLen;

	nStringLen = lstrlenW((wchar_t*)p1.ev_long);
	if (nStringLen)
	{
		nBufferLen = nStringLen * sizeof(wchar_t);
		if (AllocHandleEx(cBuffer,nBufferLen))
		{
			nBufferLen = WideCharToMultiByte(PCOUNT() == 1 ? gnConvCP : (UINT)p2.ev_long,0,(wchar_t*)p1.ev_long,nStringLen,HandleToPtr(cBuffer),nBufferLen,0,0);
			if (nBufferLen)
			{
				cBuffer.ev_length = (unsigned int)nBufferLen;
				Return(cBuffer);
				return;
			}
			else
				RAISEWIN32ERROR(WideCharToMultiByte,GetLastError());
		}
		else
			RaiseError(E_INSUFMEMORY);
	}
	cBuffer.ev_length = 0;
	Return(cBuffer);
}

void _fastcall ReadPWString(ParamBlk *parm)
{
	V_STRING(cBuffer);
	int nStringLen, nBufferLen;

	if (*(wchar_t**)p1.ev_long)
	{
		nStringLen = lstrlenW(*(wchar_t**)p1.ev_long);
		if (nStringLen)
		{
			nBufferLen = nStringLen * sizeof(wchar_t);
			if (AllocHandleEx(cBuffer,nBufferLen))
			{
				nBufferLen = WideCharToMultiByte(PCOUNT() == 1 ? gnConvCP : (UINT)p2.ev_long,0,*(wchar_t**)p1.ev_long,nStringLen,HandleToPtr(cBuffer),nBufferLen,0,0);
				if (nBufferLen)
				{
					cBuffer.ev_length = (unsigned int)nBufferLen;
					Return(cBuffer);
					return;
				}
				else
					RAISEWIN32ERROR(WideCharToMultiByte,GetLastError());
			}
			else
				RaiseError(E_INSUFMEMORY);
		}
	}
	cBuffer.ev_length = 0;
	Return(cBuffer);
}

void _fastcall ReadWCharArray(ParamBlk *parm)
{
	V_STRING(cBuffer);
	int nBufferLen, nStringLen;
	nBufferLen = p2.ev_long * sizeof(wchar_t);

	if (AllocHandleEx(cBuffer,nBufferLen))
	{
		nStringLen = wstrnlen((wchar_t*)p1.ev_long,p2.ev_long);
		if (nStringLen)
		{
			nBufferLen = WideCharToMultiByte(PCOUNT() == 2 ? gnConvCP : (UINT)p3.ev_long,0,(wchar_t*)p1.ev_long,nStringLen,HandleToPtr(cBuffer),nBufferLen,0,0);
			if (nBufferLen)
			{
				cBuffer.ev_length = (unsigned int)nBufferLen;
				Return(cBuffer);
				return;
			}
			else
				RAISEWIN32ERROR(WideCharToMultiByte,GetLastError());
		}
		else
		{
			cBuffer.ev_length = 0;
			Return(cBuffer);
			return;
		}
	}
	else
		RaiseError(E_INSUFMEMORY);
}

void _fastcall ReadLogical(ParamBlk *parm)
{
	_RetLogical(*(int*)p1.ev_long);
}

void _fastcall ReadPLogical(ParamBlk *parm)
{
	_RetLogical(**(int**)p1.ev_long);
}

void _fastcall ReadBytes(ParamBlk *parm)
{
	V_STRINGN(cBuffer,p2.ev_long);
	if (AllocHandleEx(cBuffer,p2.ev_long))
	{
		memcpy(HandleToPtr(cBuffer),(void*)p1.ev_long,p2.ev_long);
		Return(cBuffer);
		return;
	}
	else
		RaiseError(E_INSUFMEMORY);
}

void _fastcall UnMarshalArrayShort(ParamBlk *parm)
{
	Value tmpValue;
	tmpValue.ev_type = 'I';
	tmpValue.ev_width = 6;
	ARRAYLOCALS(short*)

	BEGIN_ARRAYGET()
		tmpValue.ev_long = (long)*pAddress;
	END_ARRAYGET(++)
}

void _fastcall UnMarshalArrayUShort(ParamBlk *parm)
{
	Value tmpValue;
	tmpValue.ev_type = 'I';
	tmpValue.ev_width = 6;
	ARRAYLOCALS(unsigned short*)

	BEGIN_ARRAYGET()
		tmpValue.ev_long = (long)*pAddress;
	END_ARRAYGET(++)
}

void _fastcall UnMarshalArrayInt(ParamBlk *parm)
{
	V_INTEGER(tmpValue);
	ARRAYLOCALS(long*)

	BEGIN_ARRAYGET()
		tmpValue.ev_long = *pAddress;
	END_ARRAYGET(++)
}

void _fastcall UnMarshalArrayUInt(ParamBlk *parm)
{
	V_UINTEGER(tmpValue);
	ARRAYLOCALS(unsigned long*)
	
	BEGIN_ARRAYGET()
		tmpValue.ev_real = (double)*pAddress;
	END_ARRAYGET(++)
}

void _fastcall UnMarshalArrayFloat(ParamBlk *parm)
{
	V_FLOAT(tmpValue);
	ARRAYLOCALS(float*)
	
	BEGIN_ARRAYGET()
		tmpValue.ev_real = (double)*pAddress;
	END_ARRAYGET(++)
}

void _fastcall UnMarshalArrayDouble(ParamBlk *parm)
{
	V_DOUBLE(tmpValue);
	ARRAYLOCALS(double*)

	BEGIN_ARRAYGET()
		tmpValue.ev_real = *pAddress;
	END_ARRAYGET(++)
}

void _fastcall UnMarshalArrayLogical(ParamBlk *parm)
{
	Value tmpValue;
	tmpValue.ev_type = 'L';
	ARRAYLOCALS(BOOL*)

	BEGIN_ARRAYGET()
		tmpValue.ev_length = *pAddress;
	END_ARRAYGET(++)
}

void _fastcall UnMarshalArrayCString(ParamBlk *parm)
{
	void* pDest;
	int nStringLen, nBufferLen = 256;
	V_STRING(tmpValue);
	ARRAYLOCALS(char**)

	if (!AllocHandleEx(tmpValue,nBufferLen))
		RaiseError(E_INSUFMEMORY);

	pDest = HandleToPtr(tmpValue);

	BEGIN_ARRAYGET()
		if (*pAddress)
		{
			nStringLen = lstrlen(*pAddress);
			if (nStringLen > nBufferLen)
			{
				if (!SetHandleSize(tmpValue,nStringLen))
				{
					FreeHandle(tmpValue);
					RaiseError(E_INSUFMEMORY);
				}
				else
				{
					pDest = HandleToPtr(tmpValue);
					nBufferLen = nStringLen;
				}
			}
			if (nStringLen)
			{
				tmpValue.ev_length = nStringLen;
				memcpy(pDest,*pAddress,nStringLen);
			}
			else
				tmpValue.ev_length = 0;
		}
		else
			tmpValue.ev_length = 0;
	END_ARRAYGET(++)

	FreeHandle(tmpValue);
}

void _fastcall UnMarshalArrayWString(ParamBlk *parm)
{
	char* pDest;
	int nByteCount, nWCharCount, nCharsWritten, nBufferLen = 256;
	UINT nCodePage;
	V_STRING(tmpValue);
	ARRAYLOCALS(wchar_t**)
	
	nCodePage = PCOUNT() == 2 ? gnConvCP : (UINT)p4.ev_long;

	if (!AllocHandleEx(tmpValue,nBufferLen))
		RaiseError(E_INSUFMEMORY);

	pDest = HandleToPtr(tmpValue);

	BEGIN_ARRAYGET()
		if (*pAddress)
		{
			nWCharCount = lstrlenW(*pAddress);
			nByteCount = nWCharCount * sizeof(wchar_t);
			if (nByteCount > nBufferLen)
			{
				if (!SetHandleSize(tmpValue,nByteCount))
				{
					FreeHandle(tmpValue);
					RaiseError(E_INSUFMEMORY); // "Insufficient memory"
				}
				else
				{
					pDest = (char*)HandleToPtr(tmpValue);
					nBufferLen = nByteCount;
				}
			}
            if (nByteCount)
			{
				nCharsWritten = WideCharToMultiByte(nCodePage,0,*pAddress,nWCharCount,pDest,nBufferLen,0,0);
				if (nCharsWritten)
					tmpValue.ev_length = nCharsWritten;
				else
				{
					FreeHandle(tmpValue);
					RAISEWIN32ERROR(WideCharToMultiByte,GetLastError());
				}
			}
			else
				tmpValue.ev_length = 0;
		}
		else
			tmpValue.ev_length = 0;
	END_ARRAYGET(++)

	FreeHandle(tmpValue);
}

void _fastcall UnMarshalArrayCharArray(ParamBlk *parm)
{
	char* pDest;
	V_STRING(tmpValue);
	ARRAYLOCALS(char*)

	if (!AllocHandleEx(tmpValue,p3.ev_long))
		RaiseError(E_INSUFMEMORY);

	pDest = HandleToPtr(tmpValue);

	BEGIN_ARRAYGET()
		tmpValue.ev_length = strncpyex(pDest,pAddress,p3.ev_long);
	END_ARRAYGET(+= p3.ev_long)

	FreeHandle(tmpValue);
}

void _fastcall UnMarshalArrayWCharArray(ParamBlk *parm)
{
	char* pDest;
	int nCharCount, nLength;
	UINT nCodePage;
	V_STRING(tmpValue);
	ARRAYLOCALS(wchar_t*)
	nLength = (unsigned int)p3.ev_long / sizeof(wchar_t);
	
	nCodePage = PCOUNT() == 3 ? gnConvCP : (UINT)p4.ev_long;

	if (!AllocHandleEx(tmpValue,p3.ev_long))
		RaiseError(E_INSUFMEMORY);

	pDest = HandleToPtr(tmpValue);

	BEGIN_ARRAYGET()
		nCharCount = WideCharToMultiByte(nCodePage,0,pAddress,-1,pDest,p3.ev_long,0,0);
		if (nCharCount)
    		tmpValue.ev_length = nCharCount;
		else
		{
			FreeHandle(tmpValue);
			RAISEWIN32ERROR(WideCharToMultiByte,GetLastError());
		}
	END_ARRAYGET(+= nLength)

	FreeHandle(tmpValue);
}

void _fastcall MarshalArrayShort(ParamBlk *parm)
{
	Value tmpValue = {'0'};
	ARRAYLOCALS(short*)

	BEGIN_ARRAYSET()
		if (Vartype(tmpValue) == 'I')
			*pAddress = (short)tmpValue.ev_long;
		else
			ReleaseValue(tmpValue);
	END_ARRAYSET(++)
}

void _fastcall MarshalArrayUShort(ParamBlk *parm)
{
	Value tmpValue = {'0'};
	ARRAYLOCALS(unsigned short*)

	BEGIN_ARRAYSET()
		if (Vartype(tmpValue) == 'N')
			*pAddress = (unsigned short)tmpValue.ev_long;
		else
			ReleaseValue(tmpValue);
	END_ARRAYSET(++)
}
void _fastcall MarshalArrayInt(ParamBlk *parm)
{
	Value tmpValue = {'0'};
	ARRAYLOCALS(long*)

	BEGIN_ARRAYSET()
		if (Vartype(tmpValue) == 'N')
			*pAddress = tmpValue.ev_long;
		else 
			ReleaseValue(tmpValue);
	END_ARRAYSET(++)
}
void _fastcall MarshalArrayUInt(ParamBlk *parm)
{
	Value tmpValue = {'0'};
	ARRAYLOCALS(unsigned long*)

	BEGIN_ARRAYSET()
		if (Vartype(tmpValue) == 'N')
			*pAddress = (unsigned long)tmpValue.ev_real;
		else
			ReleaseValue(tmpValue);
	END_ARRAYSET(++)
}

void _fastcall MarshalArrayFloat(ParamBlk *parm)
{
	Value tmpValue = {'0'};
	ARRAYLOCALS(float*)

	BEGIN_ARRAYSET()
		if (Vartype(tmpValue) == 'N')
			*pAddress = (float)tmpValue.ev_real;
		else
			ReleaseValue(tmpValue);
	END_ARRAYSET(++)
}

void _fastcall MarshalArrayDouble(ParamBlk *parm)
{
	Value tmpValue = {'0'};
	ARRAYLOCALS(double*)

	BEGIN_ARRAYSET()
		if (Vartype(tmpValue) == 'N')
			*pAddress = tmpValue.ev_real;
		else
			ReleaseValue(tmpValue);
	END_ARRAYSET(++)
}

void _fastcall MarshalArrayLogical(ParamBlk *parm)
{
	Value tmpValue = {'0'};
	ARRAYLOCALS(BOOL*)

	BEGIN_ARRAYSET()
		if (Vartype(tmpValue) == 'L')
			*pAddress = (BOOL)tmpValue.ev_length;
		else
			ReleaseValue(tmpValue);
	END_ARRAYSET(++)
}

void _fastcall MarshalArrayCString(ParamBlk *parm)
{
	Value tmpValue = {'0'};
	ARRAYLOCALS(char**)

	BEGIN_ARRAYSET()
		if (VALID_STRING(tmpValue))
		{
			if (*pAddress)
				*pAddress = (char*)HeapReAlloc(ghHeap,HEAP_FLAG,*pAddress,tmpValue.ev_length+sizeof(char));
			else
				*pAddress = (char*)HeapAlloc(ghHeap,HEAP_FLAG,tmpValue.ev_length+sizeof(char));

			if (*pAddress)
			{
				memcpy(*pAddress,HandleToPtr(tmpValue),tmpValue.ev_length);
				(*pAddress)[tmpValue.ev_length] = '\0';
			}
			else
			{
				FreeHandle(tmpValue);
				RaiseError(E_INSUFMEMORY);
			}
		}
		else if (*pAddress)
		{
			HeapFree(ghHeap,HEAP_FLAG,*pAddress);
			*pAddress = 0;
		}

		ReleaseValue(tmpValue);
	END_ARRAYSET(++)
}

void _fastcall MarshalArrayWString(ParamBlk *parm)
{
	Value tmpValue = {'0'};
	int nCharsWritten;
	UINT nCodePage;
	ARRAYLOCALS(wchar_t**)

	nCodePage = PCOUNT() == 2 ? gnConvCP : (UINT)p3.ev_long;

	BEGIN_ARRAYSET()
		if (VALID_STRING(tmpValue))
		{
			if (*pAddress)
                *pAddress = (wchar_t*)HeapReAlloc(ghHeap,HEAP_FLAG,*pAddress,
				tmpValue.ev_length*sizeof(wchar_t)+sizeof(wchar_t));
			else
				*pAddress = (wchar_t*)HeapAlloc(ghHeap,HEAP_FLAG,tmpValue.ev_length*sizeof(wchar_t)+sizeof(wchar_t));

			if (*pAddress)
			{
				nCharsWritten = MultiByteToWideChar(nCodePage,0,HandleToPtr(tmpValue),tmpValue.ev_length,*pAddress,tmpValue.ev_length);
				if (nCharsWritten)
				{
					(*pAddress)[nCharsWritten] = L'\0';
				}
				else
				{
					FreeHandle(tmpValue);
					RAISEWIN32ERROR(MultiByteToWideChar,GetLastError());
				}
			}
			else
			{
				FreeHandle(tmpValue);
				RaiseError(E_INSUFMEMORY);
			}
		}
		else if (*pAddress)
		{
			HeapFree(ghHeap,HEAP_FLAG,*pAddress);
			*pAddress = 0;
		}

		ReleaseValue(tmpValue);
	END_ARRAYSET(++)
}

void _fastcall MarshalArrayCharArray(ParamBlk *parm)
{
	Value tmpValue = {'0'};
	SIZE_T nLength, nCharCount;
	ARRAYLOCALS(char*)
	nLength = (unsigned int)p3.ev_long - 1;

	BEGIN_ARRAYSET()
		if (VALID_STRING(tmpValue))
		{
			nCharCount = min(tmpValue.ev_length,nLength);
			if (nCharCount)
			{
				memcpy(pAddress,HandleToPtr(tmpValue),nCharCount);
			}
			pAddress[nCharCount] = '\0';
		}
		else
			*pAddress = '\0';

		ReleaseValue(tmpValue);
	END_ARRAYSET(+= nLength)
}

void _fastcall MarshalArrayWCharArray(ParamBlk *parm)
{
	Value tmpValue = {'0'};
	int nCharsWritten;
	UINT nCodePage;
	ARRAYLOCALS(wchar_t*)

	nCodePage = PCOUNT() == 3 ? gnConvCP : (UINT)p4.ev_long;
	
	BEGIN_ARRAYSET()
		if (VALID_STRING(tmpValue))
		{
			nCharsWritten = MultiByteToWideChar(nCodePage,0,HandleToPtr(tmpValue),min((int)tmpValue.ev_length,p3.ev_long),pAddress,p3.ev_long);
			if (nCharsWritten)
			{
				pAddress[nCharsWritten] = L'\0';
			}
			else
			{
				FreeHandle(tmpValue);
				RAISEWIN32ERROR(MultiByteToWideChar,GetLastError());
			}
		}
		else
			*pAddress = L'\0';

		ReleaseValue(tmpValue);
	END_ARRAYSET(+= p3.ev_long)
}

void _fastcall UnMarshalCursorShort(ParamBlk *parm)
{
	Value tmpValue = {'I', '\0', 6};
	COLUMNGETLOCALS(short*)

	BEGIN_COLUMNGET()
		tmpValue.ev_long = (long)*pAddress;
	END_COLUMNGET(++)
}

void _fastcall UnMarshalCursorUShort(ParamBlk *parm)
{
	Value tmpValue;
	tmpValue.ev_type = 'I';
	tmpValue.ev_length = 6;

	COLUMNGETLOCALS(unsigned short*)

	BEGIN_COLUMNGET()
		tmpValue.ev_long = (long)*pAddress;
	END_COLUMNGET(++)
}

void _fastcall UnMarshalCursorInt(ParamBlk *parm)
{
	V_INTEGER(tmpValue);
	COLUMNGETLOCALS(long*)

	BEGIN_COLUMNGET()
		tmpValue.ev_long = *pAddress;
	END_COLUMNGET(++)
}

void _fastcall UnMarshalCursorUInt(ParamBlk *parm)
{
	V_UINTEGER(tmpValue);
	COLUMNGETLOCALS(unsigned long*)

	BEGIN_COLUMNGET()
		tmpValue.ev_real = (double)*pAddress;
	END_COLUMNGET(++)
}

void _fastcall UnMarshalCursorFloat(ParamBlk *parm)
{
	V_FLOAT(tmpValue);
	COLUMNGETLOCALS(float*)
	
	BEGIN_COLUMNGET()
		tmpValue.ev_real = (double)*pAddress;
	END_COLUMNGET(++)
}

void _fastcall UnMarshalCursorDouble(ParamBlk *parm)
{
	V_DOUBLE(tmpValue);
	COLUMNGETLOCALS(double*)

	BEGIN_COLUMNGET()
		tmpValue.ev_real = *pAddress;
	END_COLUMNGET(++)
}

void _fastcall UnMarshalCursorLogical(ParamBlk *parm)
{
	Value tmpValue;
	tmpValue.ev_type = 'L';
	COLUMNGETLOCALS(BOOL*)

	BEGIN_COLUMNGET()
		tmpValue.ev_length = *pAddress;
	END_COLUMNGET(++)
}

void _fastcall UnMarshalCursorCString(ParamBlk *parm)
{
	V_STRING(tmpValue);
	COLUMNGETLOCALS(char**)

	BEGIN_COLUMNGET()
		
	END_COLUMNGET(++)
}

void _fastcall UnMarshalCursorWString(ParamBlk *parm)
{
	V_STRING(tmpValue);
	COLUMNGETLOCALS(wchar_t**)

	BEGIN_COLUMNGET()
		
	END_COLUMNGET(++)
}

void _fastcall UnMarshalCursorCharArray(ParamBlk *parm)
{
	V_STRING(tmpValue);
	COLUMNGETLOCALS(char*)

	BEGIN_COLUMNGET()

	END_COLUMNGET(++)
}

void _fastcall UnMarshalCursorWCharArray(ParamBlk *parm)
{
	char *pDest;
	int nCharCount, nLength;
	UINT nCodePage;
	V_STRING(tmpValue);
	COLUMNGETLOCALS(wchar_t*)
	
	nLength = (UINT)p4.ev_long / sizeof(wchar_t);
	nCodePage = PCOUNT() == 4 ? gnConvCP : (UINT)p5.ev_long;

	if (!AllocHandleEx(tmpValue,p3.ev_long))
		RaiseError(E_INSUFMEMORY);

	pDest = HandleToPtr(tmpValue);

	BEGIN_COLUMNGET()
		nCharCount = wstrnlen(pAddress,nLength);
		if (nCharCount)
		{
			nCharCount = WideCharToMultiByte(nCodePage,0,pAddress,-1,pDest,p3.ev_long,0,0);
			if (nCharCount)
    			tmpValue.ev_length = nCharCount;
			else
			{
				FreeHandle(tmpValue);
				RAISEWIN32ERROR(WideCharToMultiByte,GetLastError());
			}
		}
		else
			tmpValue.ev_length = 0;
	END_COLUMNGET(+= nLength)

	FreeHandle(tmpValue);
}

void _fastcall MarshalCursorShort(ParamBlk *parm)
{
	COLUMNSETLOCALS(short*)

	BEGIN_COLUMNSET()
		if (Vartype(tmpValue) == 'N')
			*pAddress = (short)tmpValue.ev_real;
	END_COLUMNSET(++)
}

void _fastcall MarshalCursorUShort(ParamBlk *parm)
{
	COLUMNSETLOCALS(unsigned short*)

	BEGIN_COLUMNSET()
		if (Vartype(tmpValue) == 'N')
			*pAddress = (unsigned short)tmpValue.ev_real;
	END_COLUMNSET(++)
}

void _fastcall MarshalCursorInt(ParamBlk *parm)
{
	COLUMNSETLOCALS(long*)

	BEGIN_COLUMNSET()
		if (Vartype(tmpValue) == 'N')
			*pAddress = (long)tmpValue.ev_real;
	END_COLUMNSET(++)
}

void _fastcall MarshalCursorUInt(ParamBlk *parm)
{
	COLUMNSETLOCALS(unsigned long*)
	BEGIN_COLUMNSET()
		if (Vartype(tmpValue) == 'N')
			*pAddress = (unsigned long)tmpValue.ev_real;
	END_COLUMNSET(++)
}

void _fastcall MarshalCursorFloat(ParamBlk *parm)
{
	COLUMNSETLOCALS(float*)
	BEGIN_COLUMNSET()
		if (Vartype(tmpValue) == 'N')
			*pAddress = (float)tmpValue.ev_real;
	END_COLUMNSET(++)
}

void _fastcall MarshalCursorDouble(ParamBlk *parm)
{
	COLUMNSETLOCALS(double*)
	BEGIN_COLUMNSET()
		if (Vartype(tmpValue) == 'N')
			*pAddress = tmpValue.ev_real;
	END_COLUMNSET(++)
}

void _fastcall MarshalCursorLogical(ParamBlk *parm)
{
	COLUMNSETLOCALS(BOOL*)
	BEGIN_COLUMNSET()
		if (Vartype(tmpValue) == 'L')
			*pAddress = (BOOL)tmpValue.ev_length;
		else if (Vartype(tmpValue) == 'N')
			*pAddress = (BOOL)tmpValue.ev_real;
		else if (Vartype(tmpValue) == 'I')
			*pAddress = (BOOL)tmpValue.ev_long;
	END_COLUMNSET(++)
}

void _fastcall MarshalCursorCString(ParamBlk *parm)
{
	char *pNewAddress;
	COLUMNSETLOCALS(char**)
	BEGIN_COLUMNSET()
		if (VALID_STRING(tmpValue))
		{
			if (*pAddress)
			{
				pNewAddress = (char*)HeapReAlloc(ghHeap,HEAP_FLAG,*pAddress,tmpValue.ev_length+sizeof(char));
				if (pNewAddress)
				{
					REPLACEDEBUGALLOC(*pAddress,pNewAddress,tmpValue.ev_length);
					*pAddress = pNewAddress;
				}
				else
				{
					nErrorNo = E_INSUFMEMORY;
					goto ErrorOut;
				}
			}
			else
			{
				pNewAddress = (char*)HeapAlloc(ghHeap,HEAP_FLAG,tmpValue.ev_length+sizeof(char));
				if (pNewAddress)
				{
					ADDDEBUGALLOC(*pAddress,tmpValue.ev_length);
					*pAddress = pNewAddress;
				}
				else
				{
					nErrorNo = E_INSUFMEMORY;
					goto ErrorOut;
				}
			}

			memcpy(pNewAddress,HandleToPtr(tmpValue),tmpValue.ev_length);
			pNewAddress[tmpValue.ev_length] = '\0';
		}
		else if (*pAddress)
		{
			HeapFree(ghHeap,HEAP_FLAG,*pAddress);
			*pAddress = 0;
		}
		if (Vartype(tmpValue) == 'C')
			FreeHandle(tmpValue);
	END_COLUMNSET(++)
	Return(true);
	return;

	ErrorOut:
		if (Vartype(tmpValue) == 'C')
			FreeHandle(tmpValue);
		RaiseError(nErrorNo);
}

void _fastcall MarshalCursorWString(ParamBlk *parm)
{
	int nCharsWritten;
	UINT nCodePage;
	COLUMNSETLOCALS(wchar_t**)

	nCodePage = PCOUNT() == 3 ? gnConvCP : (UINT)p4.ev_long;

	BEGIN_COLUMNSET()
		if (VALID_STRING(tmpValue))
		{
			if (*pAddress)
				*pAddress = (wchar_t*)HeapReAlloc(ghHeap,HEAP_FLAG,*pAddress,
				tmpValue.ev_length+sizeof(wchar_t)+sizeof(wchar_t));
			else
				*pAddress = (wchar_t*)HeapAlloc(ghHeap,HEAP_FLAG,tmpValue.ev_length*sizeof(wchar_t)+sizeof(wchar_t));

			if (*pAddress)
			{
				nCharsWritten = MultiByteToWideChar(nCodePage,0,HandleToPtr(tmpValue),tmpValue.ev_length,*pAddress,tmpValue.ev_length);
				if (nCharsWritten)
				{
					(*pAddress)[tmpValue.ev_length] = L'\0';
				}
				else
				{
					FreeHandle(tmpValue);
					RAISEWIN32ERROR(MultiByteToWideChar,GetLastError());
				}
			}
			else
			{
				FreeHandle(tmpValue);
				RaiseError(E_INSUFMEMORY);
			}
		}
		else
		{
			if (Vartype(tmpValue) == 'C')
				FreeHandle(tmpValue);
			HeapFree(ghHeap,HEAP_FLAG,*pAddress);
			*pAddress = 0;
		}
	END_COLUMNSET(++)
}

void _fastcall MarshalCursorCharArray(ParamBlk *parm)
{
	unsigned int nLength, nCharCount;
	COLUMNSETLOCALS(char*)
	nLength = (unsigned int)p4.ev_long - 1;
	BEGIN_COLUMNSET()
		if (VALID_STRING(tmpValue))
		{
			nCharCount = min(tmpValue.ev_length,nLength);
			if (nCharCount)
				memcpy(pAddress,HandleToPtr(tmpValue),nCharCount);
			pAddress[nCharCount] = '\0';
		}
		else
			*pAddress = '\0';
		if (Vartype(tmpValue) == 'C')
			FreeHandle(tmpValue);
	END_COLUMNSET(++)
}

void _fastcall MarshalCursorWCharArray(ParamBlk *parm)
{
	COLUMNSETLOCALS(wchar_t*)
	BEGIN_COLUMNSET()

	END_COLUMNSET(++)
}

void _fastcall Str2Short(ParamBlk *parm)
{
	short *pString;
	pString = (short*)HandleToPtr(p1);
	Return(*pString);
}

void _fastcall Short2Str(ParamBlk *parm)
{
	V_STRINGN(vRetVal,sizeof(short));
	short *pRetVal;
	
	if (!AllocHandleEx(vRetVal,sizeof(short)))
		RaiseError(E_INSUFMEMORY);

	pRetVal = (short*)HandleToPtr(vRetVal);
	*pRetVal = (short)p1.ev_long;

	Return(vRetVal);
}

void _fastcall Str2UShort(ParamBlk *parm)
{
	unsigned short *pString;
	pString = (unsigned short*)HandleToPtr(p1);
	Return(*pString);
}

void _fastcall UShort2Str(ParamBlk *parm)
{
	V_STRINGN(vRetVal,sizeof(unsigned short));
	unsigned short *pRetVal;
	
	if (!AllocHandleEx(vRetVal,sizeof(unsigned short)))
		RaiseError(E_INSUFMEMORY);

	pRetVal = (unsigned short*)HandleToPtr(vRetVal);
	*pRetVal = (unsigned short)p1.ev_long;

	Return(vRetVal);
}

void _fastcall Str2Long(ParamBlk *parm)
{
	long *pString;
	pString = (long*)HandleToPtr(p1);
	Return(*pString);
}

void _fastcall Long2Str(ParamBlk *parm)
{
	V_STRINGN(vRetVal,sizeof(long));
	long *pRetVal;
	
	if (!AllocHandleEx(vRetVal,sizeof(long)))
		RaiseError(E_INSUFMEMORY);

	pRetVal = (long*)HandleToPtr(vRetVal);
	*pRetVal = p1.ev_long;

	Return(vRetVal);
}

void _fastcall Str2ULong(ParamBlk *parm)
{
	unsigned long *pString;
	pString = (unsigned long*)HandleToPtr(p1);
	Return(*pString);
}

void _fastcall ULong2Str(ParamBlk *parm)
{
	V_STRINGN(vRetVal,sizeof(unsigned long));
	unsigned long *pRetVal;
	
	if (!AllocHandleEx(vRetVal,sizeof(unsigned long)))
		RaiseError(E_INSUFMEMORY);

	pRetVal = (unsigned long*)HandleToPtr(vRetVal);
	
	if (Vartype(p1) == 'I')
		*pRetVal = p1.ev_long;
	else if (Vartype(p1) == 'N')
		*pRetVal = (unsigned long)p1.ev_real;
	else
	{
		FreeHandle(vRetVal);
		RaiseError(E_INVALIDPARAMS);
	}

	Return(vRetVal);
}

void _fastcall Str2Double(ParamBlk *parm)
{
	double *pDouble;
	pDouble = (double*)HandleToPtr(p1);
	Return(*pDouble);
}

void _fastcall Double2Str(ParamBlk *parm)
{
	V_STRINGN(vRetVal,sizeof(double));
	double *pRetVal;
	
	if (!AllocHandleEx(vRetVal,sizeof(double)))
		RaiseError(E_INSUFMEMORY);

	pRetVal = (double*)HandleToPtr(vRetVal);
	*pRetVal = p1.ev_real;

	Return(vRetVal);	
}

void _fastcall Str2Float(ParamBlk *parm)
{
	float *pFloat;
	pFloat = (float*)HandleToPtr(p1);
	Return(*pFloat);
}

void _fastcall Float2Str(ParamBlk *parm)
{
	V_STRINGN(vRetVal,sizeof(float));
	float *pRetVal;
	
	if (!AllocHandleEx(vRetVal,sizeof(float)))
		RaiseError(E_INSUFMEMORY);

	pRetVal = (float*)HandleToPtr(vRetVal);
	*pRetVal = (float)p1.ev_real;

	Return(vRetVal);	
}
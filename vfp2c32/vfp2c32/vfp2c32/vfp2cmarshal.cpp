#define _WIN32_WINNT 0x0400

#include <windows.h>
#include <stdio.h> // sprintf, memcpy and other common C library routines

#include "pro_ext.h" // general FoxPro library header
#include "vfp2c32.h"
#include "vfp2cutil.h"
#include "vfp2cmarshal.h"
#include "vfp2ccppapi.h"
#include "vfpmacros.h"

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
			AddWin32Error("HeapCreate", GetLastError());
			return false;
		}
	}

	// we can use GetModuleHandle instead of LoadLibrary since kernel32.dll is loaded already by VFP
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
			AddWin32Error("GetModuleHandle", GetLastError());
			return false;
		}
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
	FoxValue vProgInfo;
	LPDBGALLOCINFO pDbg;	
	char *pProgInfo = 0;

	if (pPointer && gbTrackAlloc)
	{
		pDbg = (LPDBGALLOCINFO)malloc(sizeof(DBGALLOCINFO));
		if (!pDbg)
			return;

		_Evaluate(vProgInfo, "ALLTRIM(STR(LINENO())) + ':' + PROGRAM() + CHR(0)");
		if (vProgInfo.Vartype() == 'C')
			pProgInfo = strdup(vProgInfo.HandleToPtr());

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
	FoxValue vProgInfo;
	char* pProgInfo = 0;

	if (!pNew || !gbTrackAlloc)
		return;
    
	while (pDbg && pDbg->pPointer != pOrig)
		pDbg = pDbg->next;

    if (pDbg)
	{
		_Evaluate(vProgInfo, "ALLTRIM(STR(LINENO())) + ':' + PROGRAM() + CHR(0)");
		if (vProgInfo.Vartype() == 'C')
			pProgInfo = strdup(vProgInfo.HandleToPtr());

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

		aMemLeaks(nRows, 1) = pDbg->pPointer;
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
	gbTrackAlloc = static_cast<BOOL>(p1.ev_length);
	if (PCount() == 2 && p2.ev_length)
		FreeDebugAlloc();
}

#endif // DEBUG

// FLL memory allocation functions using FLL's standard heap
void _fastcall AllocMem(ParamBlk *parm)
{
	void *pAlloc = 0;
	__try
	{
		pAlloc = HeapAlloc(ghHeap, HEAP_ZERO_MEMORY | HEAP_GENERATE_EXCEPTIONS, p1.ev_long);
	}
	__except(SAVEHEAPEXCEPTION()) { }

	if (pAlloc)
	{
		ADDDEBUGALLOC(pAlloc, p1.ev_long);
		Return(pAlloc);
	}
	else
		RaiseError(E_APIERROR);
}

void _fastcall AllocMemTo(ParamBlk *parm)
{
	void **pPointer = reinterpret_cast<void**>(p1.ev_long);
	void *pAlloc = 0;

	if (pPointer)
	{
		__try
		{
			pAlloc = HeapAlloc(ghHeap, HEAP_ZERO_MEMORY | HEAP_GENERATE_EXCEPTIONS, p2.ev_long);
		}
		__except(SAVEHEAPEXCEPTION()) { }
	
		if (pAlloc)
		{
			*pPointer = pAlloc;
			ADDDEBUGALLOC(pAlloc,p2.ev_long);
			Return(pAlloc);
		}
		else
			RaiseError(E_APIERROR);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReAllocMem(ParamBlk *parm)
{
	void *pPointer = reinterpret_cast<void*>(p1.ev_long);
	void *pAlloc = 0;
	__try
	{
		if (pPointer)
		{
			pAlloc = HeapReAlloc(ghHeap, HEAP_ZERO_MEMORY | HEAP_GENERATE_EXCEPTIONS, pPointer, p2.ev_long);
			REPLACEDEBUGALLOC(pPointer, pAlloc, p2.ev_long);
		}
		else
		{
			pAlloc = HeapAlloc(ghHeap, HEAP_ZERO_MEMORY | HEAP_GENERATE_EXCEPTIONS, p2.ev_long);
			ADDDEBUGALLOC(pAlloc, p2.ev_long);
		}
    }
	__except(SAVEHEAPEXCEPTION()) { }

	if (pAlloc)
		Return(pAlloc);
	else
		RaiseError(E_APIERROR);
}

void _fastcall FreeMem(ParamBlk *parm)
{
	void *pPointer = reinterpret_cast<void*>(p1.ev_long);
	if (pPointer)
	{
		if (HeapFree(ghHeap,0, pPointer))
		{
			REMOVEDEBUGALLOC(pPointer);
		}
		else
		{
			SaveWin32Error("HeapFree", GetLastError());
			RaiseError(E_APIERROR);
		}
	}
}

void _fastcall FreePMem(ParamBlk *parm)
{
	void* pAlloc;
	if (p1.ev_long)
	{
		if ((pAlloc = *reinterpret_cast<void**>(p1.ev_long)))
		{
			if (HeapFree(ghHeap,0,pAlloc))
			{
				REMOVEDEBUGALLOC(pAlloc);
			}
			else
			{
				SaveWin32Error("HeapFree", GetLastError());
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

	pAddress = reinterpret_cast<void**>(p1.ev_long);
	nStartElement = --p2.ev_long;
	nElements = p3.ev_long;
	pAddress += nStartElement;
	nElements -= nStartElement;
	
	ResetWin32Errors();

	while(nElements--)
	{
		if (*pAddress)
		{
			if (!HeapFree(ghHeap,0,*pAddress))
			{
				AddWin32Error("HeapFree", GetLastError());
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
		Return((int)HeapSize(ghHeap, 0, reinterpret_cast<void*>(p1.ev_long)));
	else
		Return(0);
}

void _fastcall ValidateMem(ParamBlk *parm)
{
	if (fpHeapValidate)
		Return(fpHeapValidate(ghHeap, 0, reinterpret_cast<void*>(p1.ev_long)) > 0);
	else
		RaiseError(E_NOENTRYPOINT);
}

void _fastcall CompactMem(ParamBlk *parm)
{
	if (fpHeapCompact)
		Return(fpHeapCompact(ghHeap,0));
	else
		RaiseError(E_NOENTRYPOINT);
}

// wrappers around GlobalAlloc, GlobalFree etc .. for movable memory objects ..
void _fastcall AllocHGlobal(ParamBlk *parm)
{
	HGLOBAL hMem;
	UINT nFlags = PCount() == 2 ? p2.ev_long : GMEM_MOVEABLE | GMEM_ZEROINIT;
	hMem = GlobalAlloc(nFlags, p1.ev_long);
	if (hMem)
	{
		ADDDEBUGALLOC(hMem, p1.ev_long);
		Return(hMem);
	}
	else
	{
		SaveWin32Error("GlobalAlloc", GetLastError());
		RaiseError(E_APIERROR);
	}
}

void _fastcall FreeHGlobal(ParamBlk *parm)
{
	HGLOBAL hHandle = reinterpret_cast<HGLOBAL>(p1.ev_long);
	if (hHandle)
	{
		if (GlobalFree(hHandle) == 0)
		{
			REMOVEDEBUGALLOC(hHandle);
		}
		else
		{
			SaveWin32Error("GlobalFree", GetLastError());
			RaiseError(E_APIERROR);
		}
	}
}

void _fastcall ReAllocHGlobal(ParamBlk *parm)
{
	HGLOBAL hHandle = reinterpret_cast<HGLOBAL>(p1.ev_long);
	UINT nFlags = PCount() == 2 ? GMEM_ZEROINIT : p3.ev_long;
	HGLOBAL hMem;
	hMem = GlobalReAlloc(hHandle, p2.ev_long, nFlags);
	if (hMem)
	{
		REPLACEDEBUGALLOC(p1.ev_long, hMem, p2.ev_long);
		Return(hMem);
	}
	else
	{
		SaveWin32Error("GlobalReAlloc", GetLastError());
		RaiseError(E_APIERROR);
	}
}

void _fastcall LockHGlobal(ParamBlk *parm)
{
	HGLOBAL hHandle = reinterpret_cast<HGLOBAL>(p1.ev_long);
	LPVOID pMem;
	pMem = GlobalLock(hHandle);
	if (pMem)
		Return(pMem);
	else
	{
		SaveWin32Error("GlobalLock", GetLastError());
		RaiseError(E_APIERROR);
	}
}

void _fastcall UnlockHGlobal(ParamBlk *parm)
{
	HGLOBAL hHandle = reinterpret_cast<HGLOBAL>(p1.ev_long);
	BOOL bRet;
	DWORD nLastError;
	
	bRet = GlobalUnlock(hHandle);
	if (!bRet)
	{
		nLastError = GetLastError();
		if (nLastError == NO_ERROR)
			Return(1);
		else
		{
			SaveWin32Error("GlobalUnlock", nLastError);
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
			SaveWin32Error("HeapWalk", nLastError);
			throw E_APIERROR;
		}
		return;
	}

	pArray.AutoGrow(16);
	unsigned int nRow;
	do 
	{
		nRow = pArray.Grow();
		pArray(nRow,1) = pEntry.lpData;
		pArray(nRow,2) = pEntry.cbData;
		pArray(nRow,3) = pEntry.cbOverhead;
	} while (fpHeapWalk(ghHeap,&pEntry));
	
	nLastError = GetLastError();
    if (nLastError != ERROR_NO_MORE_ITEMS)
	{
		SaveWin32Error("HeapWalk", nLastError);
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

void _fastcall WriteInt8(ParamBlk *parm)
{
	__int8 *pPointer = reinterpret_cast<__int8*>(p1.ev_long);
	if (pPointer)
		*pPointer = static_cast<__int8>(p2.ev_long);
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WritePInt8(ParamBlk *parm)
{
	__int8 **pPointer = reinterpret_cast<__int8**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
            **pPointer = static_cast<__int8>(p2.ev_long);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WriteUInt8(ParamBlk *parm)
{
	unsigned __int8 *pPointer = reinterpret_cast<unsigned __int8*>(p1.ev_long);
	if (pPointer)
		*pPointer = static_cast<unsigned __int8>(p2.ev_long);
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WritePUInt8(ParamBlk *parm)
{
	unsigned __int8 **pPointer = reinterpret_cast<unsigned __int8**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
            **pPointer = static_cast<unsigned __int8>(p2.ev_long);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WriteShort(ParamBlk *parm)
{
	short *pPointer = reinterpret_cast<short*>(p1.ev_long);
	if (pPointer)
		*pPointer = static_cast<short>(p2.ev_long);
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WritePShort(ParamBlk *parm)
{
	short **pPointer = reinterpret_cast<short**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
            **pPointer = static_cast<short>(p2.ev_long);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WriteUShort(ParamBlk *parm)
{
	unsigned short *pPointer = reinterpret_cast<unsigned short*>(p1.ev_long);
	if (pPointer)
		*pPointer = static_cast<unsigned short>(p2.ev_long);
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WritePUShort(ParamBlk *parm)
{
	unsigned short **pPointer = reinterpret_cast<unsigned short**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
            **pPointer = static_cast<unsigned short>(p2.ev_long);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WriteInt(ParamBlk *parm)
{
	int *pPointer = reinterpret_cast<int*>(p1.ev_long);
	if (pPointer)
		*pPointer = p2.ev_long;
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WritePInt(ParamBlk *parm)
{
	int **pPointer = reinterpret_cast<int**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
            **pPointer = p2.ev_long;
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WriteUInt(ParamBlk *parm)
{
	unsigned int *pPointer = reinterpret_cast<unsigned int*>(p1.ev_long);
	if (pPointer)
		*pPointer = static_cast<unsigned int>(p2.ev_real);
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WritePUInt(ParamBlk *parm)
{
	unsigned int **pPointer = reinterpret_cast<unsigned int**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
            **pPointer = static_cast<unsigned int>(p2.ev_real);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WriteInt64(ParamBlk *parm)
{
try
{
	__int64 *pPointer = reinterpret_cast<__int64*>(p1.ev_long);
	if (pPointer)
		*pPointer = Value2Int64(p2);
	else
		throw E_INVALIDPARAMS;
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall WritePInt64(ParamBlk *parm)
{
try
{
	__int64 **pPointer = reinterpret_cast<__int64**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
            **pPointer = Value2Int64(p2);
	}
	else
		throw E_INVALIDPARAMS;
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall WriteUInt64(ParamBlk *parm)
{
try
{
	unsigned __int64 *pPointer = reinterpret_cast<unsigned __int64*>(p1.ev_long);
	if (pPointer)
		*pPointer = Value2UInt64(p2);
	else
		throw E_INVALIDPARAMS;
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall WritePUInt64(ParamBlk *parm)
{
try
{
	unsigned __int64 **pPointer = reinterpret_cast<unsigned __int64**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
            **pPointer = Value2UInt64(p2);
	}
	else
		throw E_INVALIDPARAMS;
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall WriteFloat(ParamBlk *parm)
{
	float *pPointer = reinterpret_cast<float*>(p1.ev_long);
	if (pPointer)
		*pPointer = static_cast<float>(p2.ev_real);
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WritePFloat(ParamBlk *parm)
{
	float **pPointer = reinterpret_cast<float**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
            **pPointer = static_cast<float>(p2.ev_real);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WriteDouble(ParamBlk *parm)
{
	double *pPointer = reinterpret_cast<double*>(p1.ev_long);
	if (pPointer)
		*pPointer = p2.ev_real;
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WritePDouble(ParamBlk *parm)
{
	double **pPointer = reinterpret_cast<double**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
            **pPointer = p2.ev_real;
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WriteLogical(ParamBlk *parm)
{
	unsigned int *pPointer = reinterpret_cast<unsigned int*>(p1.ev_long);
	if (pPointer)
        *pPointer = p2.ev_length;
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WritePLogical(ParamBlk *parm)
{
	unsigned int **pPointer = reinterpret_cast<unsigned int**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
            **pPointer = p2.ev_length;
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WritePointer(ParamBlk *parm)
{
	void **pPointer = reinterpret_cast<void**>(p1.ev_long);
	unsigned int nPointer = static_cast<unsigned int>(p2.ev_real);
	if (pPointer)
		*pPointer = reinterpret_cast<void*>(nPointer);
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WritePPointer(ParamBlk *parm)
{
	void ***pPointer = reinterpret_cast<void***>(p1.ev_long);
	unsigned int nPointer = static_cast<unsigned int>(p2.ev_real);
	if (pPointer)
	{
		if ((*pPointer))
            **pPointer = reinterpret_cast<void*>(nPointer);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WriteChar(ParamBlk *parm)
{
	char *pChar = reinterpret_cast<char*>(p1.ev_long);
	if (pChar)
		*pChar = *HandleToPtr(p2);
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WritePChar(ParamBlk *parm)
{
	char **pChar = reinterpret_cast<char**>(p1.ev_long);
	if (pChar)
	{
		if ((*pChar))
            **pChar = *HandleToPtr(p2);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WriteWChar(ParamBlk *parm)
{
	wchar_t *pString = reinterpret_cast<wchar_t*>(p1.ev_long);
	unsigned int nCodePage = PCount() == 2 ? gnConvCP : p3.ev_long;
	if (pString)
	{
		if (p2.ev_length)
			MultiByteToWideChar(nCodePage, 0, HandleToPtr(p2), 1, pString, 1);
		else
			*pString = L'\0';
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WritePWChar(ParamBlk *parm)
{
	wchar_t **pString = reinterpret_cast<wchar_t**>(p1.ev_long);
	unsigned int nCodePage = PCount() == 2 ? gnConvCP : p3.ev_long;
	if (pString)
	{
		if ((*pString))
		{
			if (p2.ev_length)
				MultiByteToWideChar(nCodePage, 0, HandleToPtr(p2), 1, *pString, 1);
			else
				**pString = L'\0';
		}
	}
}

void _fastcall WriteCString(ParamBlk *parm)
{
	char *pPointer = reinterpret_cast<char*>(p1.ev_long);
	char *pNewAddress = 0;

	__try
	{
		if (pPointer)
		{
			pNewAddress = (char*)HeapReAlloc(ghHeap, HEAP_GENERATE_EXCEPTIONS, pPointer, p2.ev_length+1);
			REPLACEDEBUGALLOC(pPointer, pNewAddress, p2.ev_length+1);
		}
		else
		{
			pNewAddress = (char*)HeapAlloc(ghHeap, HEAP_GENERATE_EXCEPTIONS, p2.ev_length+1);
			ADDDEBUGALLOC(pNewAddress, p2.ev_length+1);
		}
	}
	__except(SAVEHEAPEXCEPTION()) { }

	if (pNewAddress)
	{
		memcpy(pNewAddress, HandleToPtr(p2), p2.ev_length);
		pNewAddress[p2.ev_length] = '\0';
		Return((void*)pNewAddress);
	}
	else
		RaiseError(E_APIERROR);
}

void _fastcall WriteGPCString(ParamBlk *parm)
{
	char *pNewAddress = 0;
	HGLOBAL *pOldAddress = reinterpret_cast<HGLOBAL*>(p1.ev_long);
	SIZE_T dwLen = p2.ev_length + 1;

	if (Vartype(p2) == 'C' && pOldAddress)
	{
		if ((*pOldAddress))
		{
			pNewAddress = (char*)GlobalReAlloc(*pOldAddress, dwLen, GMEM_FIXED);
			if (pNewAddress == 0)
			{
				SaveWin32Error("GlobalReAlloc", GetLastError());
				RaiseError(E_APIERROR);
			}
			REPLACEDEBUGALLOC(pOldAddress, pNewAddress, dwLen);
		}
		else
		{
			pNewAddress = (char*)GlobalAlloc(GMEM_FIXED, dwLen);
			if (pNewAddress == 0)
			{
				SaveWin32Error("GlobalAlloc", GetLastError());
				RaiseError(E_APIERROR);
			}
			ADDDEBUGALLOC(pNewAddress, dwLen);
		}

		*pOldAddress = pNewAddress;
		memcpy(pNewAddress, HandleToPtr(p2),p2.ev_length);
		pNewAddress[p2.ev_length] = '\0';		
		Return((void*)pNewAddress);
	}
	else if (Vartype(p2) == '0' && pOldAddress)
	{
		if ((*pOldAddress))
		{
			if (GlobalFree(*pOldAddress) == 0)
			{
				REMOVEDEBUGALLOC(*pOldAddress);
				*pOldAddress = 0;
				Return(0);
			}
			else
			{
				SaveWin32Error("GlobalFree", GetLastError());
				RaiseError(E_APIERROR);
			}
		}
		else
			Return(0);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WritePCString(ParamBlk *parm)
{
	char *pNewAddress = 0;
	char **pOldAddress = reinterpret_cast<char**>(p1.ev_long);

	if (Vartype(p2) == 'C' && pOldAddress)
	{
		__try
		{
			if ((*pOldAddress))
			{
				pNewAddress = (char*)HeapReAlloc(ghHeap, HEAP_GENERATE_EXCEPTIONS, (*pOldAddress), p2.ev_length+1);
				REPLACEDEBUGALLOC(*pOldAddress, pNewAddress, p2.ev_length);
			}
			else
			{
				pNewAddress = (char*)HeapAlloc(ghHeap, HEAP_GENERATE_EXCEPTIONS, p2.ev_length+1);
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
				Return(0);
			}
			else
			{
				SaveWin32Error("HeapFree", GetLastError());
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
	char *pPointer = reinterpret_cast<char*>(p1.ev_long);
	if (pPointer)
	{
		if (PCount() == 2 || (long)p2.ev_length < p3.ev_long)
		{
			memcpy(pPointer, HandleToPtr(p2),p2.ev_length);
			pPointer[p2.ev_length] = '\0';
		}
		else
		{
			memcpy(pPointer, HandleToPtr(p2), p3.ev_long);
			pPointer[p3.ev_long-1] = '\0';
		}
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WriteWString(ParamBlk *parm)
{
	wchar_t *pString = reinterpret_cast<wchar_t*>(p1.ev_long);
	unsigned int nCodePage = PCount() == 2 ? gnConvCP : p3.ev_long;
	wchar_t *pDest = 0;
	int nStringLen, nBytesNeeded, nBytesWritten;	
	nStringLen = p2.ev_length;
	nBytesNeeded = nStringLen * sizeof(wchar_t) + sizeof(wchar_t);

	__try
	{
		if (pString)
		{
			pDest = (wchar_t*)HeapReAlloc(ghHeap, HEAP_GENERATE_EXCEPTIONS, pString, nBytesNeeded);
			REPLACEDEBUGALLOC(pString, pDest, nBytesNeeded);
		}
		else
		{
			pDest = (wchar_t*)HeapAlloc(ghHeap, HEAP_GENERATE_EXCEPTIONS, nBytesNeeded);
			ADDDEBUGALLOC(pDest, nBytesNeeded);
		}
	}
	__except(SAVEHEAPEXCEPTION()) { }

	if (pDest)
	{
		if (nStringLen)
		{
			nBytesWritten = MultiByteToWideChar(nCodePage, 0, HandleToPtr(p2), nStringLen, pDest, nBytesNeeded);
			if (nBytesWritten)
				pDest[nBytesWritten] = L'\0';
			else
				RaiseWin32Error("MultiByteToWideChar", GetLastError());
		}
		else
			*pDest = L'\0';

		Return((void*)pDest);
	}
	else
		RaiseError(E_APIERROR);
}

void _fastcall WritePWString(ParamBlk *parm)
{
	wchar_t **pOld = reinterpret_cast<wchar_t**>(p1.ev_long);
	wchar_t *pDest = 0;
	unsigned int nCodePage = PCount() == 2 ? gnConvCP : p3.ev_long;
	int nStringLen, nBytesNeeded, nBytesWritten;

	if (Vartype(p2) == 'C' && pOld)
	{
		nStringLen = p2.ev_length;
		nBytesNeeded = nStringLen * sizeof(wchar_t) + sizeof(wchar_t);

		__try
		{
			if ((*pOld))
			{
				pDest = (wchar_t*)HeapReAlloc(ghHeap,HEAP_ZERO_MEMORY | HEAP_GENERATE_EXCEPTIONS,*pOld,nBytesNeeded);
				REPLACEDEBUGALLOC(*pOld,pDest,nBytesNeeded);
			}
			else
			{
				pDest = (wchar_t*)HeapAlloc(ghHeap,HEAP_ZERO_MEMORY | HEAP_GENERATE_EXCEPTIONS,nBytesNeeded);
				ADDDEBUGALLOC(pDest,nBytesNeeded);
			}
		}
		__except(SAVEHEAPEXCEPTION()) { }

		if (pDest)
		{
			nBytesWritten = MultiByteToWideChar(nCodePage, 0, HandleToPtr(p2), nStringLen, pDest, nBytesNeeded);
			if (nBytesWritten)
			{
				pDest[nBytesWritten] = L'\0';
				*pOld = pDest;
			}
			else
				RaiseWin32Error("MultiByteToWideChar", GetLastError());
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
				SaveWin32Error("HeapFree", GetLastError());
				RaiseError(E_APIERROR);
			}
		}
		else
			Return(0);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WriteWCharArray(ParamBlk *parm)
{
	wchar_t *pString = reinterpret_cast<wchar_t*>(p1.ev_long);
	unsigned int nCodePage = PCount() == 3 ? gnConvCP : p4.ev_long;
	int nBytesWritten, nArrayWidth, nStringLen;
	nArrayWidth = p3.ev_long - 1; // -1 for null terminator
	nStringLen = p2.ev_length;

	if (pString)
	{
		if (nStringLen)
		{
			nBytesWritten = MultiByteToWideChar(nCodePage, 0, HandleToPtr(p2), min(nStringLen,nArrayWidth), pString, nArrayWidth);
			if (nBytesWritten)
				pString[nBytesWritten] = L'\0';
			else
				RaiseWin32Error("MultiByteToWideChar", GetLastError());
		}
		else
			*pString = L'\0';
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall WriteBytes(ParamBlk *parm)
{
	void *pPointer = reinterpret_cast<void*>(p1.ev_long);
	if (pPointer)
		memcpy(pPointer, HandleToPtr(p2), PCount() == 3 ? min(p2.ev_length, (UINT)p3.ev_long) : p2.ev_length);
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadInt8(ParamBlk *parm)
{
	__int8 *pPointer = reinterpret_cast<__int8*>(p1.ev_long);
	if (pPointer)
		Return(*pPointer);
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadPInt8(ParamBlk *parm)
{
	__int8 **pPointer = reinterpret_cast<__int8**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
            Return(**pPointer);
		else
			ReturnNull();
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadUInt8(ParamBlk *parm)
{
	unsigned __int8 *pPointer = reinterpret_cast<unsigned __int8*>(p1.ev_long);
	if (pPointer)
		Return(*pPointer);
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadPUInt8(ParamBlk *parm)
{
	unsigned __int8 **pPointer = reinterpret_cast<unsigned __int8**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
            Return(**pPointer);
		else
			ReturnNull();
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadShort(ParamBlk *parm)
{
	short *pPointer = reinterpret_cast<short*>(p1.ev_long);
	if (pPointer)
		Return(*pPointer);
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadPShort(ParamBlk *parm)
{
	short **pPointer = reinterpret_cast<short**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
            Return(**pPointer);
		else
			ReturnNull();
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadUShort(ParamBlk *parm)
{
	unsigned short *pPointer = reinterpret_cast<unsigned short*>(p1.ev_long);
	if (pPointer)
		Return(*pPointer);
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadPUShort(ParamBlk *parm)
{
	unsigned short **pPointer = reinterpret_cast<unsigned short**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
            Return(**pPointer);
		else
			ReturnNull();
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadInt(ParamBlk *parm)
{
	int *pPointer = reinterpret_cast<int*>(p1.ev_long);
	if (pPointer)
		Return(*pPointer);
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadPInt(ParamBlk *parm)
{
	int **pPointer = reinterpret_cast<int**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
            Return(**pPointer);
		else
			ReturnNull();
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadUInt(ParamBlk *parm)
{
	unsigned int *pPointer = reinterpret_cast<unsigned int*>(p1.ev_long);
	if (pPointer)
		Return(*pPointer);
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadPUInt(ParamBlk *parm)
{
	unsigned int **pPointer = reinterpret_cast<unsigned int**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
            Return(**pPointer);
		else
			ReturnNull();
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadInt64(ParamBlk *parm)
{
	__int64 *pPointer = reinterpret_cast<__int64*>(p1.ev_long);
	if (pPointer)
	{
		if (PCount() == 1 || p2.ev_long == 1)
			ReturnInt64AsBinary(*pPointer);
		else if (p2.ev_long == 2)
			ReturnInt64AsString(*pPointer);
		else
			ReturnInt64AsDouble(*pPointer);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadPInt64(ParamBlk *parm)
{
	__int64 **pPointer = reinterpret_cast<__int64**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
		{
			if (PCount() == 1 || p2.ev_long == 1)
				ReturnInt64AsBinary(**pPointer);
			else if (p2.ev_long == 2)
				ReturnInt64AsString(**pPointer);
			else
				ReturnInt64AsDouble(**pPointer);
		}
		else
			ReturnNull();
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadUInt64(ParamBlk *parm)
{
	unsigned __int64 *pPointer = reinterpret_cast<unsigned __int64*>(p1.ev_long);
	if (pPointer)
	{
		if (PCount() == 1 || p2.ev_long == 1)
			ReturnInt64AsBinary(*pPointer);
		else if (p2.ev_long == 2)
			ReturnInt64AsString(*pPointer);
		else
			ReturnInt64AsDouble(*pPointer);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadPUInt64(ParamBlk *parm)
{
	unsigned __int64 **pPointer = reinterpret_cast<unsigned __int64**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
		{
			if (PCount() == 1 || p2.ev_long == 1)
				ReturnInt64AsBinary(**pPointer);
			else if (p2.ev_long == 2)
				ReturnInt64AsString(**pPointer);
			else
				ReturnInt64AsDouble(**pPointer);
		}
		else
			ReturnNull();
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadFloat(ParamBlk *parm)
{
	float *pPointer = reinterpret_cast<float*>(p1.ev_long);
	if (pPointer)
		Return(*pPointer);
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadPFloat(ParamBlk *parm)
{
	float **pPointer = reinterpret_cast<float**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
            Return(**pPointer);
		else
			ReturnNull();
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadDouble(ParamBlk *parm)
{
	double *pPointer = reinterpret_cast<double*>(p1.ev_long);
	if (pPointer)
		Return(*pPointer);
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadPDouble(ParamBlk *parm)
{
	double **pPointer = reinterpret_cast<double**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
            Return(**pPointer);
		else
			ReturnNull();
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadLogical(ParamBlk *parm)
{
	BOOL *pPointer = reinterpret_cast<BOOL*>(p1.ev_long);
	if (pPointer)
		_RetLogical(*pPointer);
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadPLogical(ParamBlk *parm)
{
	BOOL **pPointer = reinterpret_cast<BOOL**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
            _RetLogical(**pPointer);
		else
			ReturnNull();
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadPointer(ParamBlk *parm)
{
	void **pPointer = reinterpret_cast<void**>(p1.ev_long);
	if (pPointer)
		Return(*pPointer);
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadPPointer(ParamBlk *parm)
{
	void ***pPointer = reinterpret_cast<void***>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
			Return(**pPointer);
		else
			ReturnNull();
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadChar(ParamBlk *parm)
{
	StringValue cChar(1);
	char *pPointer = reinterpret_cast<char*>(p1.ev_long);
	char *pChar;
	if (pPointer)
	{
		if (AllocHandleEx(cChar,1))
		{
			pChar = HandleToPtr(cChar);
			*pChar = *pPointer;
			Return(cChar);
		}
		else
			RaiseError(E_INSUFMEMORY);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadPChar(ParamBlk *parm)
{
	StringValue cChar(1);
	char **pPointer = reinterpret_cast<char**>(p1.ev_long);
	char *pChar;

	if (pPointer)
	{
		if ((*pPointer))
		{
			if (AllocHandleEx(cChar,1))
			{
				pChar = HandleToPtr(cChar);
				*pChar = **pPointer;
				Return(cChar);
			}
			else
				RaiseError(E_INSUFMEMORY);
		}
		else if (PCount() == 1)
			ReturnNull();
		else
			Return(p2);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadCString(ParamBlk *parm)
{
	char *pPointer = reinterpret_cast<char*>(p1.ev_long);
	if (pPointer)
		Return(pPointer);
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadPCString(ParamBlk *parm)
{
	char **pPointer = reinterpret_cast<char**>(p1.ev_long);
	if (pPointer)
	{
		if ((*pPointer))
            Return(*pPointer);
		else if (PCount() == 1)
		{
			char aNothing[1] = {'\0'};
			Return(aNothing);
		}
		else
			Return(p2);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadCharArray(ParamBlk *parm)
{
	StringValue vBuffer;
	const char *pPointer = reinterpret_cast<const char*>(p1.ev_long);

	if (pPointer)
	{
		if (AllocHandleEx(vBuffer, p2.ev_long))
		{
			vBuffer.ev_length = strncpyex(HandleToPtr(vBuffer), pPointer, p2.ev_long);
			Return(vBuffer);
		}
		else
			RaiseError(E_INSUFMEMORY);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}



void _fastcall ReadWString(ParamBlk *parm)
{
	StringValue vBuffer;
	int nStringLen, nBufferLen;
	wchar_t* pString = reinterpret_cast<wchar_t*>(p1.ev_long);
	unsigned int nCodePage = PCount() == 1 ? gnConvCP : p2.ev_long;

	if (pString)
	{
		nStringLen = lstrlenW(pString);
		if (nStringLen)
		{
			nBufferLen = nStringLen * sizeof(wchar_t) + sizeof(wchar_t);
			if (AllocHandleEx(vBuffer, nBufferLen))
			{
				nBufferLen = WideCharToMultiByte(nCodePage, 0, pString, nStringLen, HandleToPtr(vBuffer), nBufferLen, 0, 0);
				if (nBufferLen)
				{
					vBuffer.ev_length = (unsigned int)nBufferLen;
					Return(vBuffer);
					return;
				}
				else
					RaiseWin32Error("WideCharToMultiByte", GetLastError());
			}
			else
				RaiseError(E_INSUFMEMORY);
		}
		vBuffer.ev_length = 0;
		Return(vBuffer);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadPWString(ParamBlk *parm)
{
	StringValue vBuffer;
	wchar_t **pString = reinterpret_cast<wchar_t**>(p1.ev_long);
	unsigned int nCodePage = PCount() > 1 && p2.ev_long ? p2.ev_long : gnConvCP;
	int nStringLen, nBufferLen;

	if (pString)
	{
		if ((*pString))
		{
			nStringLen = lstrlenW(*pString);
			if (nStringLen)
			{
				nBufferLen = nStringLen * sizeof(wchar_t);
				if (AllocHandleEx(vBuffer, nBufferLen))
				{
					nBufferLen = WideCharToMultiByte(nCodePage, 0, *pString, nStringLen, HandleToPtr(vBuffer), nBufferLen, 0, 0);
					if (nBufferLen)
						vBuffer.ev_length = nBufferLen;
					else
						RaiseWin32Error("WideCharToMultiByte", GetLastError());
				}
				else
					RaiseError(E_INSUFMEMORY);
			}
			Return(vBuffer);
		}
		else if (PCount() < 3)
			Return(vBuffer);
		else
			Return(p3);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

void _fastcall ReadWCharArray(ParamBlk *parm)
{
	StringValue vBuffer;
	wchar_t *pString = reinterpret_cast<wchar_t*>(p1.ev_long);
	unsigned int nCodePage = PCount() == 2 ? gnConvCP : p3.ev_long;
	int nBufferLen, nStringLen;

	if (pString)
	{
		nStringLen = wstrnlen(pString, p2.ev_long);
		if (nStringLen)
		{
			nBufferLen = nStringLen * sizeof(wchar_t);
			if (AllocHandleEx(vBuffer, nBufferLen))
			{
				nBufferLen = WideCharToMultiByte(nCodePage, 0, pString, nStringLen, HandleToPtr(vBuffer), nBufferLen, 0, 0);
				if (nBufferLen)
					vBuffer.ev_length = nBufferLen;
				else
					RaiseWin32Error("WideCharToMultiByte", GetLastError());
			}
			else
				RaiseError(E_INSUFMEMORY);
		}
		Return(vBuffer);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}



void _fastcall ReadBytes(ParamBlk *parm)
{
	StringValue vBuffer(p2.ev_long);
	void *pPointer = reinterpret_cast<void*>(p1.ev_long);
	if (pPointer)
	{
		if (AllocHandleEx(vBuffer,p2.ev_long))
		{
			memcpy(HandleToPtr(vBuffer), pPointer, p2.ev_long);
			Return(vBuffer);
			return;
		}
		else
			RaiseError(E_INSUFMEMORY);
	}
	else
		RaiseError(E_INVALIDPARAMS);
}

#define BEGIN_ARRAYLOOP() \
	while(++vfpArray.CurrentDim() <= vfpArray.ADims()) \
	{ \
		vfpArray.CurrentRow() = 0; \
		while(++vfpArray.CurrentRow() <= vfpArray.ARows()) \
		{ 

#define END_ARRAYLOOP() \
		} \
	}

void _fastcall MarshalFoxArray2CArray(ParamBlk *parm)
{
try
{
	FoxArray vfpArray(r2);
	MarshalType Type = static_cast<MarshalType>(p3.ev_long);
	FoxValue pValue;

	switch(Type)
	{
		case CTYPE_SHORT:
			{
				short *CArray = reinterpret_cast<short*>(p1.ev_long);
				BEGIN_ARRAYLOOP()
					pValue = vfpArray;
					if (pValue.Vartype() == 'N')
						*CArray = static_cast<short>(pValue->ev_long);
					else if (pValue.Vartype() != '0')
						throw E_INVALIDPARAMS;
					CArray++;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_USHORT:
			{
				unsigned short *CArray = reinterpret_cast<unsigned short*>(p1.ev_long);
				BEGIN_ARRAYLOOP()
					pValue = vfpArray;
					if (pValue.Vartype() == 'N')
						*CArray = static_cast<unsigned short>(pValue->ev_long);
					else if (pValue.Vartype() != '0')
						throw E_INVALIDPARAMS;
					CArray++;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_INT:
			{
				int *CArray = reinterpret_cast<int*>(p1.ev_long);
				BEGIN_ARRAYLOOP()
					pValue = vfpArray;
					if (pValue.Vartype() == 'N')
						*CArray = pValue->ev_long;
					else if (pValue.Vartype() != '0')
						throw E_INVALIDPARAMS;
					CArray++;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_UINT:
			{
				unsigned int *CArray = reinterpret_cast<unsigned int*>(p1.ev_long);
				BEGIN_ARRAYLOOP()
					pValue = vfpArray;
					if (pValue.Vartype() == 'N')
						*CArray = static_cast<unsigned int>(pValue->ev_long);
					else if (pValue.Vartype() != '0')
						throw E_INVALIDPARAMS;
					CArray++;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_FLOAT:
			{
				float *CArray = reinterpret_cast<float*>(p1.ev_long);
				BEGIN_ARRAYLOOP()
					pValue = vfpArray;
					if (pValue.Vartype() == 'N')
						*CArray = static_cast<float>(pValue->ev_long);
					else if (pValue.Vartype() != '0')
						throw E_INVALIDPARAMS;
					CArray++;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_DOUBLE:
			{
				double *CArray = reinterpret_cast<double*>(p1.ev_long);
				BEGIN_ARRAYLOOP()
					pValue = vfpArray;
					if (pValue.Vartype() == 'N')
						*CArray = pValue->ev_real;
					else if (pValue.Vartype() != '0')
						throw E_INVALIDPARAMS;
					CArray++;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_BOOL:
			{
				BOOL *CArray = reinterpret_cast<BOOL*>(p1.ev_long);
				BEGIN_ARRAYLOOP()
					pValue = vfpArray;
					if (pValue.Vartype() == 'L')
						*CArray = pValue->ev_length;
					else if (pValue.Vartype() != '0')
						throw E_INVALIDPARAMS;
					CArray++;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_CSTRING:
			{
				char **CArray = reinterpret_cast<char**>(p1.ev_long);
				BEGIN_ARRAYLOOP()
					pValue = vfpArray;
					if (pValue.Vartype() == 'C')
					{
						if (*CArray)
							*CArray = (char*)HeapReAlloc(ghHeap, 0, *CArray, pValue->ev_length + sizeof(char));
						else
							*CArray = (char*)HeapAlloc(ghHeap, 0, pValue->ev_length + sizeof(char));
			
						if (*CArray)
						{
							memcpy(*CArray, pValue.HandleToPtr(), pValue->ev_length);
							(*CArray)[pValue->ev_length] = '\0';
						}
						else
							throw E_INSUFMEMORY;
					}
					else if (pValue.Vartype() == '0')
					{
						if (*CArray)
						{
							HeapFree(ghHeap, 0, *CArray);
							*CArray = 0;
						}
					}
					else 
						throw E_INVALIDPARAMS;

					CArray++;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_WSTRING:
			{
				wchar_t **CArray = reinterpret_cast<wchar_t**>(p1.ev_long);
				int nCharsWritten;
				unsigned int nCodePage = PCount() == 3 ? gnConvCP : p4.ev_long;
				BEGIN_ARRAYLOOP()
					pValue = vfpArray;
					if (pValue.Vartype() == 'C')
					{
						if (*CArray)
							*CArray = (wchar_t*)HeapReAlloc(ghHeap, 0, *CArray, pValue->ev_length * sizeof(wchar_t) + sizeof(wchar_t));
						else
							*CArray = (wchar_t*)HeapAlloc(ghHeap, 0, pValue->ev_length * sizeof(wchar_t) + sizeof(wchar_t));

						if (*CArray)
						{
							nCharsWritten = MultiByteToWideChar(nCodePage, 0, pValue.HandleToPtr(), pValue->ev_length, *CArray, pValue->ev_length);
							if (nCharsWritten)
							{
								(*CArray)[nCharsWritten] = L'\0';
							}
							else
							{
								SaveWin32Error("MultiByteToWideChar", GetLastError());
								throw E_APIERROR;
							}
						}
						else
							throw E_INSUFMEMORY;
					}
					else if (pValue.Vartype() == '0')
					{
						if (*CArray)
						{
							HeapFree(ghHeap, 0, *CArray);
							*CArray = 0;
						}
					}
					else
						throw E_INVALIDPARAMS;

					CArray++;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_CHARARRAY:
			{
				if (PCount() < 4)
					throw E_INVALIDPARAMS;

				char *CArray = reinterpret_cast<char*>(p1.ev_long);
				unsigned int nCharCount, nLength = p4.ev_long;
				BEGIN_ARRAYLOOP()
					pValue = vfpArray;
                	if (pValue.Vartype() == 'C')
					{
						nCharCount = min(pValue->ev_length, nLength);
						if (nCharCount)
							memcpy(CArray, pValue.HandleToPtr(), nCharCount);
						if (nCharCount < nLength)
							CArray[nCharCount] = '\0';
					}
					else if (pValue.Vartype() == '0')
						memset(CArray, 0, nLength);
					else
						throw E_INVALIDPARAMS;

					CArray += nLength;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_WCHARARRAY:
			{
				if (PCount() < 4)
					throw E_INVALIDPARAMS;

				wchar_t *CArray = reinterpret_cast<wchar_t*>(p1.ev_long);
				unsigned int nCodePage, nCharsWritten, nLength = p4.ev_long;
				nCodePage = PCount() == 4 ? gnConvCP : p5.ev_long;
				BEGIN_ARRAYLOOP()
					pValue = vfpArray;
					if (pValue.Vartype() == 'C')
					{
						nCharsWritten = MultiByteToWideChar(nCodePage, 0, pValue.HandleToPtr(), min(pValue->ev_length, nLength), CArray, nLength);
						if (nCharsWritten)
						{
							if (nCharsWritten < nLength)
								CArray[nCharsWritten] = L'\0';
						}
						else
						{
							SaveWin32Error("MultiByteToWideChar", GetLastError());
							throw E_APIERROR;
						}
					}
					else if (pValue.Vartype() == '0')
						memset(CArray, 0, nLength * 2);
					else
						throw E_INVALIDPARAMS;

					CArray += nLength;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_INT64:
			{
				__int64 *CArray = reinterpret_cast<__int64*>(p1.ev_long);
				BEGIN_ARRAYLOOP()
					pValue = vfpArray;
					if (pValue.Vartype() == 'Y')
						*CArray = pValue->ev_currency.QuadPart;
					else if (pValue.Vartype() == 'C' && pValue->ev_length == 8)
						*CArray = *reinterpret_cast<__int64*>(pValue.HandleToPtr());
					if (pValue.Vartype() == 'N')
						*CArray = static_cast<__int64>(pValue->ev_real);
					else if (pValue.Vartype() != '0')
						throw E_INVALIDPARAMS;
					CArray++;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_UINT64:
			{
				unsigned __int64 *CArray = reinterpret_cast<unsigned __int64*>(p1.ev_long);
				BEGIN_ARRAYLOOP()
					pValue = vfpArray;
					if (pValue.Vartype() == 'Y')
						*CArray = static_cast<unsigned __int64>(pValue->ev_currency.QuadPart);
					else if (pValue.Vartype() == 'C' && pValue->ev_length == 8)
						*CArray = *reinterpret_cast<unsigned __int64*>(pValue.HandleToPtr());
					if (pValue.Vartype() == 'N')
						*CArray = static_cast<unsigned __int64>(pValue->ev_real);
					else if (pValue.Vartype() != '0')
						throw E_INVALIDPARAMS;
					CArray++;
				END_ARRAYLOOP()
			}
			break;

		default:
			throw E_INVALIDPARAMS;
	}
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall MarshalCArray2FoxArray(ParamBlk *parm)
{
try
{
	FoxArray vfpArray(r2);
	MarshalType Type = static_cast<MarshalType>(p3.ev_long);

	switch(Type)
	{
		case CTYPE_SHORT:
			{
				short *CArray = reinterpret_cast<short*>(p1.ev_long);
				FoxShort pValue;
				BEGIN_ARRAYLOOP()
					vfpArray = pValue = *CArray++;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_USHORT:
			{
				unsigned short *CArray = reinterpret_cast<unsigned short*>(p1.ev_long);
				FoxUShort pValue;
				BEGIN_ARRAYLOOP()
					vfpArray = pValue = *CArray++;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_INT:
			{
				int *CArray = reinterpret_cast<int*>(p1.ev_long);
				FoxInt pValue;
				BEGIN_ARRAYLOOP()
					vfpArray = pValue = *CArray++;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_UINT:
			{
				unsigned int *CArray = reinterpret_cast<unsigned int*>(p1.ev_long);
				FoxUInt pValue;
				BEGIN_ARRAYLOOP()
					vfpArray = pValue = *CArray++;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_FLOAT:
			{
				float *CArray = reinterpret_cast<float*>(p1.ev_long);
				FoxFloat pValue;
				BEGIN_ARRAYLOOP()
					vfpArray = pValue = *CArray++;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_DOUBLE:
			{
				double *CArray = reinterpret_cast<double*>(p1.ev_long);
				FoxDouble pValue;
				BEGIN_ARRAYLOOP()
					vfpArray = pValue = *CArray++;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_BOOL:
			{
				BOOL *CArray = reinterpret_cast<BOOL*>(p1.ev_long);
				FoxLogical pValue;
				BEGIN_ARRAYLOOP()
					vfpArray = pValue = *CArray++;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_CSTRING:
			{
				char **CArray = reinterpret_cast<char**>(p1.ev_long);
				unsigned int nStringLen;
				FoxString pValue(256);
				FoxValue pNull;

				BEGIN_ARRAYLOOP()
					if (*CArray)
					{
						nStringLen = lstrlen(*CArray);
						if (nStringLen > pValue.Size())
							pValue.Size(nStringLen);
						if (nStringLen)
							memcpy(pValue, *CArray, nStringLen);
						pValue.Len(nStringLen);
						vfpArray = pValue;
					}
					else
						vfpArray = pNull;
					
					CArray++;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_WSTRING:
			{
				wchar_t **CArray = reinterpret_cast<wchar_t**>(p1.ev_long);
				unsigned int nByteCount, nWCharCount, nCharsWritten;
				unsigned int nCodePage = PCount() == 3 ? gnConvCP : p4.ev_long;;
				FoxString pValue(512);
				FoxValue pNull;

				BEGIN_ARRAYLOOP()
					if (*CArray)
					{
						nWCharCount = lstrlenW(*CArray);
						nByteCount = nWCharCount * sizeof(wchar_t);
						if (nByteCount > pValue.Size())
							pValue.Size(nByteCount);
						if (nByteCount)
						{
							nCharsWritten = WideCharToMultiByte(nCodePage, 0, *CArray, nWCharCount, pValue, pValue.Size(), 0, 0);
							if (nCharsWritten)
								pValue.Len(nCharsWritten);
							else
							{
								SaveWin32Error("WideCharToMultiByte", GetLastError());
								throw E_APIERROR;
							}
						}
						else
							pValue.Len(0);

						vfpArray = pValue;
					}
					else
						vfpArray = pNull;
				
					CArray++;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_CHARARRAY:
			{
				if (PCount() != 4)
					throw E_INVALIDPARAMS;
				
				char *CArray = reinterpret_cast<char*>(p1.ev_long);
				unsigned int nLen = p4.ev_long;
				FoxString pValue(nLen);
				BEGIN_ARRAYLOOP()
					vfpArray = pValue.StrnCpy(CArray, nLen);
					CArray += nLen;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_WCHARARRAY:
			{
				if (PCount() < 4)
					throw E_INVALIDPARAMS;

				wchar_t *CArray = reinterpret_cast<wchar_t*>(p1.ev_long);
				int nCharCount, nLen = p4.ev_long;
				unsigned int nCodePage = PCount() == 4 ? gnConvCP : p5.ev_long;
				FoxString pValue(nLen);
				
				BEGIN_ARRAYLOOP()
					nCharCount = WideCharToMultiByte(nCodePage, 0, CArray, nLen, pValue, pValue.Size(), 0, 0);
					if (nCharCount)
						pValue.Len(nCharCount);
					else
					{
						SaveWin32Error("WideCharToMultiByte", GetLastError());
						throw E_APIERROR;
					}
					vfpArray = pValue;
					CArray += nLen;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_INT64:
			{
				__int64 *CArray = reinterpret_cast<__int64*>(p1.ev_long);
				FoxCurrency pValue;
				BEGIN_ARRAYLOOP()
					vfpArray = pValue = *CArray++;
				END_ARRAYLOOP()
			}
			break;

		case CTYPE_UINT64:
			{
				unsigned __int64 *CArray = reinterpret_cast<unsigned __int64*>(p1.ev_long);
				FoxCurrency pValue;
				BEGIN_ARRAYLOOP()
					vfpArray = pValue = *CArray++;
				END_ARRAYLOOP()
			}
			break;

		default:
			throw E_INVALIDPARAMS;
	}
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

#undef BEGIN_ARRAYLOOP
#undef END_ARRAYLOOP

#define BEGIN_CURSORLOOP() \
	for (int nRecNo = 0; nRecNo < nRecCount; nRecNo++) \
	{

#define END_CURSORLOOP() \
		pCursor.Skip(); \
	}

#define BEGIN_FIELDLOOP() \
	for (unsigned int nFieldNo = 0; nFieldNo < nFieldCount; nFieldNo++) \
	{

#define END_FIELDLOOP() \
	}

void _fastcall MarshalCursor2CArray(ParamBlk *parm)
{
try
{
	FoxValue pValue;
	FoxString pCursorAndFields(p2);
	MarshalType Type = static_cast<MarshalType>(p3.ev_long);
	FoxCursor pCursor;

	char CursorName[VFP_MAX_CURSOR_NAME];
	char *pFieldNames = pCursorAndFields;
	pFieldNames += GetWordNumN(CursorName, pCursorAndFields, '.', 1, VFP_MAX_CURSOR_NAME) + 1;
	pCursor.Attach(CursorName, pFieldNames);
	pCursor.GoTop();
	int nRecCount = pCursor.RecCount();
	unsigned int nFieldCount = pCursor.FCount();
	
	switch(Type)
	{
		case CTYPE_SHORT:
			{
				short *CArray = reinterpret_cast<short*>(p1.ev_long);
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pValue = pCursor(nFieldNo);
						if (pValue.Vartype() == 'N')
							CArray[nRecNo + (nRecCount * nFieldNo)] = static_cast<short>(pValue->ev_real);
						else if (pValue.Vartype() != '0')
							throw E_INVALIDPARAMS;
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_USHORT:
			{
				unsigned short *CArray = reinterpret_cast<unsigned short*>(p1.ev_long);
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pValue = pCursor(nFieldNo);
						if (pValue.Vartype() == 'N')
							CArray[nRecNo + (nRecCount * nFieldNo)] = static_cast<unsigned short>(pValue->ev_real);
						else if (pValue.Vartype() != '0')
							throw E_INVALIDPARAMS;
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_INT:
			{
				int *CArray = reinterpret_cast<int*>(p1.ev_long);
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pValue = pCursor(nFieldNo);
						if (pValue.Vartype() == 'N')
							CArray[nRecNo + (nRecCount * nFieldNo)] = static_cast<int>(pValue->ev_real);
						else if (pValue.Vartype() != '0')
							throw E_INVALIDPARAMS;
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_UINT:
			{
				unsigned int *CArray = reinterpret_cast<unsigned int*>(p1.ev_long);
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pValue = pCursor(nFieldNo);
						if (pValue.Vartype() == 'N')
							CArray[nRecNo + (nRecCount * nFieldNo)] = static_cast<unsigned int>(pValue->ev_real);
						else if (pValue.Vartype() != '0')
							throw E_INVALIDPARAMS;
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_FLOAT:
			{
				float *CArray = reinterpret_cast<float*>(p1.ev_long);
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pValue = pCursor(nFieldNo);
						if (pValue.Vartype() == 'N')
							CArray[nRecNo + (nRecCount * nFieldNo)] = static_cast<float>(pValue->ev_real);
						else if (pValue.Vartype() != '0')
							throw E_INVALIDPARAMS;
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_DOUBLE:
			{
				double *CArray = reinterpret_cast<double*>(p1.ev_long);
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pValue = pCursor(nFieldNo);
						if (pValue.Vartype() == 'N')
							CArray[nRecNo + (nRecCount * nFieldNo)] = pValue->ev_real;
						else if (pValue.Vartype() != '0')
							throw E_INVALIDPARAMS;
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_BOOL:
			{
				BOOL *CArray = reinterpret_cast<BOOL*>(p1.ev_long);
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()										
						pValue = pCursor(nFieldNo);
						if (pValue.Vartype() == 'L')
							CArray[nRecNo + (nRecCount * nFieldNo)] = pValue->ev_length;
						else if (pValue.Vartype() != '0')
							throw E_INVALIDPARAMS;
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_CSTRING:
			{
				char **CArray = reinterpret_cast<char**>(p1.ev_long);
				char **pString;
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pValue = pCursor(nFieldNo);
						pString = &CArray[nRecNo + (nRecCount * nFieldNo)];
						if (pValue.Vartype() == 'C')
						{
							if (*pString)
								*pString = (char*)HeapReAlloc(ghHeap, 0, *pString, pValue->ev_length + sizeof(char));
							else
								*pString = (char*)HeapAlloc(ghHeap, 0, pValue->ev_length + sizeof(char));
				
							if (*pString)
							{
								memcpy(*pString, pValue.HandleToPtr(), pValue->ev_length);
								(*pString)[pValue->ev_length] = '\0';
							}
							else
								throw E_INSUFMEMORY;
						}
						else if (pValue.Vartype() == '0')
						{
							if (*pString)
							{
								HeapFree(ghHeap, 0, *CArray);
								*pString = 0;
							}
						}
						else 
							throw E_INVALIDPARAMS;
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_WSTRING:
			{
				wchar_t **CArray = reinterpret_cast<wchar_t**>(p1.ev_long);
				wchar_t **pString;
				int nCharsWritten;
				unsigned int nCodePage = PCount() == 3 ? gnConvCP : p4.ev_long;
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pValue = pCursor(nFieldNo);
						pString = &CArray[nRecNo + (nRecCount * nFieldNo)];
						if (pValue.Vartype() == 'C')
						{
							if (*pString)
								*pString = (wchar_t*)HeapReAlloc(ghHeap, 0, *pString, pValue->ev_length * sizeof(wchar_t) + sizeof(wchar_t));
							else
								*pString = (wchar_t*)HeapAlloc(ghHeap, 0, pValue->ev_length * sizeof(wchar_t) + sizeof(wchar_t));

							if (*pString)
							{
								nCharsWritten = MultiByteToWideChar(nCodePage, 0, pValue.HandleToPtr(), pValue->ev_length, *pString, pValue->ev_length);
								if (nCharsWritten)
								{
									(*pString)[nCharsWritten] = L'\0';
								}
								else
								{
									SaveWin32Error("MultiByteToWideChar", GetLastError());
									throw E_APIERROR;
								}
							}
							else
								throw E_INSUFMEMORY;
						}
						else if (pValue.Vartype() == '0')
						{
							if (*pString)
							{
								HeapFree(ghHeap, 0, *pString);
								*pString = 0;
							}
						}
						else
							throw E_INVALIDPARAMS;
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_CHARARRAY:
			{
				char *CArray = reinterpret_cast<char*>(p1.ev_long);
				char *pString;
				unsigned int nCharCount, nDimensionSize, nLength = p4.ev_long;
				nDimensionSize = nRecCount * nLength;
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pValue = pCursor(nFieldNo);
						pString = CArray + (nFieldNo * nDimensionSize);
                		if (pValue.Vartype() == 'C')
						{
							nCharCount = min(pValue->ev_length, nLength);
							if (nCharCount)
								memcpy(pString, pValue.HandleToPtr(), nCharCount);
							if (nCharCount < nLength)
								pString[nCharCount] = '\0';
						}
						else if (pValue.Vartype() == '0')
							memset(CArray, 0, nLength);
						else
							throw E_INVALIDPARAMS;

						CArray += nLength;
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_WCHARARRAY:
			{
				if (PCount() < 4)
					throw E_INVALIDPARAMS;

				wchar_t *CArray = reinterpret_cast<wchar_t*>(p1.ev_long);
				wchar_t *pString;
				unsigned int nByteLen, nCharsWritten, nDimensionSize, nLen = p4.ev_long;
				unsigned int nCodePage = PCount() == 4 ? gnConvCP : p5.ev_long;
				nByteLen = nLen * sizeof(wchar_t);
				nDimensionSize = nRecCount * nByteLen;
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pValue = pCursor(nFieldNo);
						pString = CArray + (nFieldNo * nDimensionSize);
						if (pValue.Vartype() == 'C')
						{
							nCharsWritten = MultiByteToWideChar(nCodePage, 0, pValue.HandleToPtr(), min(pValue->ev_length, nLen), pString, nLen);
							if (nCharsWritten)
							{
								if (nCharsWritten < nLen)
									pString[nCharsWritten] = L'\0';
							}
							else
							{
								SaveWin32Error("MultiByteToWideChar", GetLastError());
								throw E_APIERROR;
							}
						}
						else if (pValue.Vartype() == '0')
							memset(pString, 0, nByteLen);
						else
							throw E_INVALIDPARAMS;

						CArray += nLen;
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_INT64:
			{
				__int64 *CArray = reinterpret_cast<__int64*>(p1.ev_long);
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pValue = pCursor(nFieldNo);
						if (pValue.Vartype() == 'Y')
							CArray[nRecNo + (nRecCount * nFieldNo)] = pValue->ev_currency.QuadPart;
						else if (pValue.Vartype() == 'C' && pValue->ev_length == 8)
							CArray[nRecNo + (nRecCount * nFieldNo)] = *reinterpret_cast<__int64*>(pValue.HandleToPtr());
						if (pValue.Vartype() == 'N')
							CArray[nRecNo + (nRecCount * nFieldNo)] = static_cast<__int64>(pValue->ev_real);
						else if (pValue.Vartype() != '0')
							throw E_INVALIDPARAMS;
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_UINT64:
			{
				unsigned __int64 *CArray = reinterpret_cast<unsigned __int64*>(p1.ev_long);
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pValue = pCursor(nFieldNo);
						if (pValue.Vartype() == 'Y')
							CArray[nRecNo + (nRecCount * nFieldNo)] = static_cast<unsigned __int64>(pValue->ev_currency.QuadPart);
						else if (pValue.Vartype() == 'C' && pValue->ev_length == 8)
							CArray[nRecNo + (nRecCount * nFieldNo)] = *reinterpret_cast<unsigned __int64*>(pValue.HandleToPtr());
						if (pValue.Vartype() == 'N')
							CArray[nRecNo + (nRecCount * nFieldNo)] = static_cast<unsigned __int64>(pValue->ev_real);
						else if (pValue.Vartype() != '0')
							throw E_INVALIDPARAMS;
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		default:
			throw E_INVALIDPARAMS;
	}
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

#undef BEGIN_CURSORLOOP
#undef END_CURSORLOOP
#undef BEGIN_FIELDLOOP
#undef BEGIN_FIELDLOOP

#define BEGIN_CURSORLOOP() \
	for(unsigned int nRow = 0; nRow < nRowCount; nRow++) \
	{ \
		if (pCursor.Eof()) \
			pCursor.AppendBlank(); 

#define END_CURSORLOOP() \
		pCursor.Skip(); \
	}

#define BEGIN_FIELDLOOP() \
	for(unsigned int nFieldNo = 0; nFieldNo < nFieldCount; nFieldNo++) \
	{

#define END_FIELDLOOP() \
	}

void _fastcall MarshalCArray2Cursor(ParamBlk *parm)
{
try
{
	FoxString pCursorAndFields(p2);
	MarshalType Type = static_cast<MarshalType>(p3.ev_long);
	FoxCursor pCursor;
	unsigned int nFieldCount;
	unsigned int nRowCount = p4.ev_long;
	char CursorName[VFP_MAX_CURSOR_NAME];
	char *pFieldNames = pCursorAndFields;
	pFieldNames += GetWordNumN(CursorName, pCursorAndFields, '.', 1, VFP_MAX_CURSOR_NAME) + 1;
	pCursor.Attach(CursorName, pFieldNames);
	pCursor.GoTop();
	nFieldCount = pCursor.FCount();

	switch(Type)
	{
		case CTYPE_SHORT:
			{
				short *CArray = reinterpret_cast<short*>(p1.ev_long);
				FoxShort pValue;
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pCursor(nFieldNo) = pValue = CArray[nRow + (nRowCount * nFieldNo)];
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_USHORT:
			{
				unsigned short *CArray = reinterpret_cast<unsigned short*>(p1.ev_long);
				FoxUShort pValue;
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pCursor(nFieldNo) = pValue = CArray[nRow + (nRowCount * nFieldNo)];
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_INT:
			{
				int *CArray = reinterpret_cast<int*>(p1.ev_long);
				FoxInt pValue;
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pCursor(nFieldNo) = pValue = CArray[nRow + (nRowCount * nFieldNo)];
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_UINT:
			{
				unsigned int *CArray = reinterpret_cast<unsigned int*>(p1.ev_long);
				FoxUInt pValue;
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pCursor(nFieldNo) = pValue = CArray[nRow + (nRowCount * nFieldNo)];
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_FLOAT:
			{
				float *CArray = reinterpret_cast<float*>(p1.ev_long);
				FoxFloat pValue;
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pCursor(nFieldNo) = pValue = CArray[nRow + (nRowCount * nFieldNo)];
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_DOUBLE:
			{
				double *CArray = reinterpret_cast<double*>(p1.ev_long);
				FoxDouble pValue;
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pCursor(nFieldNo) = pValue = CArray[nRow + (nRowCount * nFieldNo)];
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_BOOL:
			{
				BOOL *CArray = reinterpret_cast<BOOL*>(p1.ev_long);
				FoxLogical pValue;
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pCursor(nFieldNo) = pValue = CArray[nRow + (nRowCount * nFieldNo)];
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_CSTRING:
			{
				char **CArray = reinterpret_cast<char**>(p1.ev_long);
				char *pString;
				unsigned int nStringLen;
				FoxString pValue(256);
				FoxValue pNull;

				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pString = CArray[nRow + (nRowCount * nFieldNo)];
						if (pString)
						{
							nStringLen = lstrlen(pString);
							if (nStringLen > pValue.Size())
								pValue.Size(nStringLen);
							if (nStringLen)
								memcpy(pValue, pString, nStringLen);
							pCursor(nFieldNo) = pValue.Len(nStringLen);
						}
						else
							pCursor(nFieldNo) = pNull;
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_WSTRING:
			{
				wchar_t **CArray = reinterpret_cast<wchar_t**>(p1.ev_long);
				wchar_t *pString;
				unsigned int nByteCount, nWCharCount, nCharsWritten;
				UINT nCodePage = PCount() == 4 ? gnConvCP : p5.ev_long;;
				FoxString pValue(512);
				FoxValue pNull;

				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pString = CArray[nRow + (nRowCount * nFieldNo)];
						if (pString)
						{
							nWCharCount = lstrlenW(pString);
							nByteCount = nWCharCount * sizeof(wchar_t);
							if (nByteCount > pValue.Size())
								pValue.Size(nByteCount);
							if (nByteCount)
							{
								nCharsWritten = WideCharToMultiByte(nCodePage, 0, pString, nWCharCount, pValue, pValue.Size(), 0, 0);
								if (nCharsWritten)
									pValue.Len(nCharsWritten);
								else
								{
									SaveWin32Error("WideCharToMultiByte", GetLastError());
									throw E_APIERROR;
								}
							}
							else
								pValue.Len(0);
							pCursor(nFieldNo) = pValue;
						}
						else
							pCursor(nFieldNo) = pNull;
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_CHARARRAY:
			{
				if (PCount() != 5)
					throw E_INVALIDPARAMS;
				
				char *CArray = reinterpret_cast<char*>(p1.ev_long);
				char *pString;
				unsigned int nLen = p5.ev_long;
				unsigned int nDimensionSize = nLen * nRowCount;
				FoxString pValue(nLen);
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pString = CArray + (nFieldNo * nDimensionSize);
						pCursor(nFieldNo) = pValue.StrnCpy(pString, nLen);
						CArray += nLen;
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_WCHARARRAY:
			{
				if (PCount() < 5)
					throw E_INVALIDPARAMS;

				wchar_t *CArray = reinterpret_cast<wchar_t*>(p1.ev_long);
				wchar_t *pString;
				int nCharCount, nByteLen;
				unsigned int nLen = p5.ev_long;
				nByteLen = nLen * sizeof(wchar_t);
				unsigned int nDimensionSize = nByteLen * nRowCount;
				UINT nCodePage = PCount() == 5 ? gnConvCP : p6.ev_long;
				FoxString pValue(nByteLen);
				
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pString = CArray + (nFieldNo * nDimensionSize);
						nCharCount = WideCharToMultiByte(nCodePage,0, pString, -1, pValue, pValue.Size(), 0, 0);
						if (nCharCount)
							pValue.Len(nCharCount);
						else
						{
							SaveWin32Error("WideCharToMultiByte", GetLastError());
							throw E_APIERROR;
						}
						pCursor(nFieldNo) = pValue;
						CArray += nLen;
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_INT64:
			{
				__int64 *CArray = reinterpret_cast<__int64*>(p1.ev_long);
				FoxCurrency pValue;
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pCursor(nFieldNo) = pValue = CArray[nRow + (nRowCount * nFieldNo)];
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		case CTYPE_UINT64:
			{
				unsigned __int64 *CArray = reinterpret_cast<unsigned __int64*>(p1.ev_long);
				FoxCurrency pValue;
				BEGIN_CURSORLOOP()
					BEGIN_FIELDLOOP()
						pCursor(nFieldNo) = pValue = CArray[nRow + (nRowCount * nFieldNo)];
					END_FIELDLOOP()
				END_CURSORLOOP()
			}
			break;

		default:
			throw E_INVALIDPARAMS;
	}
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

#undef BEGIN_CURSORLOOP
#undef END_CURSORLOOP
#undef BEGIN_FIELDLOOP
#undef BEGIN_FIELDLOOP
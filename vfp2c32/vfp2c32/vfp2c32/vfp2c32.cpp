#define _WIN32_WINNT 0x0400

#include <windows.h> /* no comment .. */
#include <stdio.h>

#include "pro_ext.h" /* general FoxPro library header */

/* VFP2C specific includes */
#include "vfp2c32.h"  /* VFP2C32 specific types & defines */
#include "vfp2carray.h" /* array functions */
#include "vfp2casync.h" /* asynchronous functions */
#include "vfp2cconv.h" /* misc data conversion functions */
#include "vfp2cenum.h" /* window, process, thread, module enumeration functions */
#include "vfp2cfile.h" /* filesystem related functions */
#include "vfp2cmarshal.h" /* marshaling & memory allocation/read/write routines */
#include "vfp2cnetapi.h" /* NetApi32 wrappers (network user,group,resource enumeration etc.) */
#include "vfp2cnetapiex.h" /* NetApi32 wrappers for Win95,98,Me */
#include "vfp2codbc.h" /* ODBC related functions (datasource enumeration,creation,deletion etc., SQLSetPropEx ..) */
#include "vfp2cprint.h" /* Printer related functions (printjob enumeration etc.) */
#include "vfp2cregistry.h" /* registry functions */
#include "vfp2ctime.h" /* time conversion functions */
#include "vfp2ccom.h" /* COM functions */
#include "vfp2ccominterop.h" /* Dynamic COM Wrapper object */
#include "vfp2curlmon.h" /* wrappers around urlmon.dll functions */
#include "vfp2cwininet.h" /* wrappers around wininet.dll functions */
#include "vfp2ccallback.h" /* C Callback function emulation */
#include "vfp2cwinsock.h" /* winsock initialization */
#include "vfp2csntp.h"	/* SNTP (RFC 1769) implementation */
#include "vfp2cservices.h" /* win service functions */
#include "vfp2cwindows.h" /* some window functions */
#include "vfp2cras.h" /* RAS (dialup management) wrappers (rasapi32.dll) */
#include "vfp2ciphelper.h" /* IP Helper (iphlpapi.dll) wrappers */
#include "vfp2cfont.h" /* Font functions  */
#include "vfp2cutil.h" /* common utility functions */
#include "vfp2ccppapi.h" /* C++ class library over LCK */
#include "vfpmacros.h"

/* Global variables:
module handle for this DLL */
HMODULE ghModule = 0;
/* array of VFP2CERROR structs for storing Win32, custom & ODBC errors */
VFP2CERROR gaErrorInfo[VFP2C_MAX_ERRORS] = {0};
/* No. of error messages in gaErrorInfo */
DWORD gnErrorCount = -1; 
/* holds OS version information */
OSVERSIONINFOEX gsOSVerInfo;
/* holds version of FoxPro */
DWORD gnFoxVersion;
/* Initialization status */
static DWORD gnInitStatus = 0;

/* error handling routine to store the last error occurred in a Win32 API call 
 called through the macros SAVEWIN32ERROR, ADDWIN32ERROR or RAISEWIN32ERROR */
void _stdcall Win32ErrorHandler(char *pFunction, DWORD nErrorNo, BOOL bAddError, BOOL bRaise)
{
	if (bAddError)
	{
		if (gnErrorCount == VFP2C_MAX_ERRORS)
			return;
		gnErrorCount++;
	}
	else
		gnErrorCount = 0;

	gaErrorInfo[gnErrorCount].nErrorType = VFP2C_ERRORTYPE_WIN32;
	gaErrorInfo[gnErrorCount].nErrorNo = nErrorNo;
	strncpy(gaErrorInfo[gnErrorCount].aErrorFunction,pFunction,VFP2C_ERROR_FUNCTION_LEN);
	FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,0,nErrorNo,0,gaErrorInfo[gnErrorCount].aErrorMessage,VFP2C_ERROR_MESSAGE_LEN,0);
	if (bRaise)
		_UserError(gaErrorInfo[gnErrorCount].aErrorMessage);
}
/* error handling routine to store a custom error description
   called through the macros SAVECUSTOMERROR, ADDCUSTOMERROR or RAISECUSTOMERROR */
void _stdcall Win32ErrorHandlerEx(char *pFunction, char* pErrorMessage, BOOL bAddError, BOOL bRaise)
{
	if (bAddError)
	{
		if (gnErrorCount == VFP2C_MAX_ERRORS)
			return;
		gnErrorCount++;
	}
	else
		gnErrorCount = 0;

	gaErrorInfo[gnErrorCount].nErrorType = VFP2C_ERRORTYPE_WIN32;
	gaErrorInfo[gnErrorCount].nErrorNo = E_CUSTOMERROR;
	strncpy(gaErrorInfo[gnErrorCount].aErrorFunction,pFunction,VFP2C_ERROR_FUNCTION_LEN);
    strncpy(gaErrorInfo[gnErrorCount].aErrorMessage,pErrorMessage,VFP2C_ERROR_MESSAGE_LEN);
	if (bRaise)
		_UserError(gaErrorInfo[gnErrorCount].aErrorMessage);
}

/* error handling routine to store a custom error description with a parameter (passed to sprintfex)
   called through the macros SAVECUSTOMERROREX, ADDCUSTOMERROREX or RAISECUSTOMERROREX */
void _stdcall Win32ErrorHandlerExEx(char *pFunction, char *pErrorMessage, DWORD nErrorNo, BOOL bAddError, BOOL bRaise)
{
	if (bAddError)
	{
		if (gnErrorCount == VFP2C_MAX_ERRORS)
			return;
		gnErrorCount++;
	}
	else
		gnErrorCount = 0;

	gaErrorInfo[gnErrorCount].nErrorType = VFP2C_ERRORTYPE_WIN32;
	gaErrorInfo[gnErrorCount].nErrorNo = nErrorNo;
	strncpy(gaErrorInfo[gnErrorCount].aErrorFunction,pFunction,VFP2C_ERROR_FUNCTION_LEN);
	sprintfex(gaErrorInfo[gnErrorCount].aErrorMessage,pErrorMessage,nErrorNo);
	if (bRaise)
		_UserError(gaErrorInfo[gnErrorCount].aErrorMessage);
}

void _stdcall Win32ErrorhandlerExEx2(char *pFunction, char *pErrorMessage, void *nParm1, void *nParm2)
{
	if (gnErrorCount == VFP2C_MAX_ERRORS)
		return;
	gnErrorCount++;

	gaErrorInfo[gnErrorCount].nErrorType = VFP2C_ERRORTYPE_WIN32;
	gaErrorInfo[gnErrorCount].nErrorNo = 0;
	strncpy(gaErrorInfo[gnErrorCount].aErrorFunction,pFunction,VFP2C_ERROR_FUNCTION_LEN);
	sprintfex(gaErrorInfo[gnErrorCount].aErrorMessage,pErrorMessage,nParm1,nParm2);
}

void _stdcall RaiseError(int nErrorNo)
{
	if (nErrorNo == E_APIERROR)
		_UserError(gaErrorInfo[gnErrorCount].aErrorMessage);

	_Error(nErrorNo);
}

void _fastcall InitVFP2C32(ParamBlk *parm)
{
	DWORD dwFlags = p1.ev_long;
	dwFlags &= ~gnInitStatus;

	RESETWIN32ERRORS();

	if (dwFlags & VFP2C_INIT_MARSHAL)
	{
		VFP2C_Init_Marshal();
		// dont set gnInitStatus so marshaling functions are re DECLARE'd after a call to CLEAR ALL 
	}

	if (dwFlags & VFP2C_INIT_ASYNC)
	{
		if (VFP2C_Init_Async())
			gnInitStatus |= VFP2C_INIT_ASYNC;
	}

	if (dwFlags & VFP2C_INIT_ENUM)
	{
		if (VFP2C_Init_Enum())
			gnInitStatus |= VFP2C_INIT_ENUM;
	}

	if (dwFlags & VFP2C_INIT_FILE)
	{
		if (VFP2C_Init_File())
			gnInitStatus |= VFP2C_INIT_FILE;
	}

	if (dwFlags & VFP2C_INIT_WINSOCK)
	{
		if (VFP2C_Init_Winsock())
			gnInitStatus |= VFP2C_INIT_WINSOCK;
	}

	if (dwFlags & VFP2C_INIT_ODBC)
	{
		if (VFP2C_Init_Odbc())
			gnInitStatus |= VFP2C_INIT_ODBC;
	}
	
	if (dwFlags & VFP2C_INIT_PRINT)
	{
		if (VFP2C_Init_Print())
			gnInitStatus |= VFP2C_INIT_PRINT;
	}

	if (dwFlags & VFP2C_INIT_NETAPI)
	{
		if (IS_WIN9X())
		{
			if (VFP2C_Init_Netapiex())
				gnInitStatus |= VFP2C_INIT_NETAPI;
		}
		else
		{
			if (VFP2C_Init_Netapi())
				gnInitStatus |= VFP2C_INIT_NETAPI;
		}
	}

	if (dwFlags & VFP2C_INIT_CALLBACK)
	{
		if (VFP2C_Init_Callback())
			gnInitStatus |= VFP2C_INIT_CALLBACK;
	}

	if (dwFlags & VFP2C_INIT_SERVICES)
	{
		if (VFP2C_Init_Services())
			gnInitStatus |= VFP2C_INIT_SERVICES;
	}

	if (dwFlags & VFP2C_INIT_WINDOWS)
	{
		if (VFP2C_Init_Windows())
			gnInitStatus |= VFP2C_INIT_WINDOWS;
	}

	if (dwFlags & VFP2C_INIT_RAS)
	{
		if (VFP2C_Init_Ras())
			gnInitStatus |= VFP2C_INIT_RAS;
	}

	if (dwFlags & VFP2C_INIT_IPHELPER)
	{
		if (VFP2C_Init_IpHelper())
			gnInitStatus |= VFP2C_INIT_IPHELPER;
	}

	if (dwFlags & VFP2C_INIT_URLMON)
	{
		if (VFP2C_Init_Urlmon())
			gnInitStatus |= VFP2C_INIT_URLMON;
	}
	
	if (dwFlags & VFP2C_INIT_COM)
	{
		VFP2C_Init_Com();
			// gnInitStatus |= VFP2C_INIT_COM; -> commented for the same reason as VFP2C_Init_Marshal
	}
/*
	if (dwFlags & VFP2C_INIT_WININET)
	{
		if (VFP2C_Init_WinInet())
			gnInitStatus |= VFP2C_INIT_WININET;
	}
*/

	Return(gnErrorCount == -1);
}

void _fastcall OnLoad()
{
	/* get module handle - _GetAPIHandle() doesn't work (unresolved external error from linker) */
	ghModule = GetModuleHandle(FLLFILENAME);
	/* get OS information, first try to get EX info, it that fails get normal version */
	gsOSVerInfo.dwOSVersionInfoSize = sizeof(OSVERSIONINFOEX);
	if (!GetVersionEx((LPOSVERSIONINFO)&gsOSVerInfo))
	{
		gsOSVerInfo.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
		GetVersionEx((LPOSVERSIONINFO)&gsOSVerInfo);
	}

	FoxValue vFoxVer;
	_Evaluate(vFoxVer, "INT(VERSION(5))");
	gnFoxVersion = vFoxVer->ev_long;
}

void _fastcall OnUnload()
{
	VFP2C_Destroy_Marshal();
	VFP2C_Destroy_Async();
	VFP2C_Destroy_Enum();
	VFP2C_Destroy_Callback();
	VFP2C_Destroy_Winsock();
	VFP2C_Destroy_File();
	if (IS_WIN9X())
		VFP2C_Destroy_Netapiex();
	else
		VFP2C_Destroy_Netapi();
	VFP2C_Destroy_Ras();
	VFP2C_Destroy_IpHelper();
	VFP2C_Destroy_Urlmon();
	VFP2C_Destroy_Com();
	// VFP2C_Destroy_WinInet();
}

void _fastcall VFP2CSys(ParamBlk *parm)
{
try
{
	switch (p1.ev_long)
	{
		case 1: /* library's HINSTANCE/HMODULE */
			if (PCOUNT() == 2)
				throw E_INVALIDPARAMS;
			Return(ghModule);
			break;
		case 2: /* library heap HANDLE */
			if (PCOUNT() == 2)
				throw E_INVALIDPARAMS;
			Return(ghHeap);
			break;
		case 3: /* set or return Unicode conversion codepage */
			if (PCOUNT() == 2)
			{
				if (Vartype(p2) == 'I' || Vartype(p2) == 'N')
				{
					if (IsValidCodePage((UINT)p2.ev_long))
					{
						gnConvCP = (UINT)p2.ev_long;
						Return(true);
					}
					else
						Return(false);
				}
				else
					throw E_INVALIDPARAMS;
			}
			else
				Return(gnConvCP);
			break;

		default: /* else wrong parameter */
			throw E_INVALIDPARAMS;
	}
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall FormatMessageEx(ParamBlk *parm)
{
try
{
	DWORD nLanguage = 0;
	DWORD nFlags = FORMAT_MESSAGE_FROM_SYSTEM;
	LPCVOID lpModule = 0;
	FoxString pMessage(VFP2C_ERROR_MESSAGE_LEN);
	
	if (PCOUNT() == 2)
		nLanguage = p2.ev_long;
	else if (PCOUNT() == 3)
	{
		nLanguage = p2.ev_long;
		lpModule = reinterpret_cast<LPCVOID>(p3.ev_long);
		nFlags |= FORMAT_MESSAGE_FROM_HMODULE;
	}

	pMessage.Len(FormatMessage(nFlags, lpModule, p1.ev_long, nLanguage, pMessage, pMessage.Size(), 0));

	if (pMessage.Len())
		pMessage.Return();
	else
	{
		SAVEWIN32ERROR(FormatMessage, GetLastError());
		throw E_APIERROR;
	}
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall AErrorEx(ParamBlk *parm)
{
try
{
	if (gnErrorCount == -1)
	{
		Return(0);
		return;
	}

	FoxArray pArray(p1, gnErrorCount+1, 4);
	FoxString pErrorInfo(VFP2C_ERROR_MESSAGE_LEN);
	FoxValue vNullValue;

	unsigned int nRow = 0;
	for (unsigned int xj = 0; xj <= gnErrorCount; xj++)
	{
		nRow++;
		pArray(nRow,1) = gaErrorInfo[xj].nErrorNo;
		pArray(nRow,2) = pErrorInfo = gaErrorInfo[xj].aErrorFunction;
		pArray(nRow,3) = pErrorInfo = gaErrorInfo[xj].aErrorMessage;
		if (gaErrorInfo[xj].nErrorType == VFP2C_ERRORTYPE_ODBC)
			pArray(nRow,4) = pErrorInfo = gaErrorInfo[xj].aSqlState;
		else
			pArray(nRow,4) = vNullValue;
	}

	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}
/*
void _fastcall InternalError(ParamBlk *parm)
{
	char *pMes;
	Value vMes, vNumber;

	vNumber.ev_type = 'I';
	vMes.ev_type = 'C';

	vMes.ev_handle = _AllocHand(4096);
	pMes = _HandToPtr(vMes.ev_handle);

	vNumber.ev_long = _ErrorInfo(p1.ev_long,pMes);
	vMes.ev_length = lstrlen(pMes);

	_Store(&r2,&vMes);
	_FreeHand(vMes.ev_handle);
	_Store(&r3,&vNumber);
}

void _fastcall ErrorTest(ParamBlk *parm)
{
	_Error(p1.ev_long);
}
*/

#ifdef __cplusplus
extern "C" {
#endif

FoxInfo VFP2CFuncs[] = 
{
	/* common library routines (startup, cleanup & internal settings) */
	{"OnLoad", (FPFI) OnLoad, CALLONLOAD, ""},
	{"OnUnload", (FPFI) OnUnload, CALLONUNLOAD, ""},
	{"InitVFP2C32", (FPFI) InitVFP2C32, 1, "I"},
	{"VFP2CSys", (FPFI) VFP2CSys, 2, "I.?"},

	/* memory management routines */
	{"AllocMem", (FPFI) AllocMem, 1, "I"},
	{"AllocMemTo", (FPFI) AllocMemTo, 2, "II"},
	{"ReAllocMem", (FPFI) ReAllocMem, 2, "II"},
	{"FreeMem", (FPFI) FreeMem, 1, "I"},
	{"FreePMem", (FPFI) FreePMem, 1, "I"},
	{"FreeRefArray", (FPFI) FreeRefArray, 3, "III"},
	{"SizeOfMem", (FPFI) SizeOfMem, 1, "I"},
	{"ValidateMem", (FPFI) ValidateMem, 1, "I"},
	{"CompactMem", (FPFI) CompactMem, 0, ""},
	{"AMemBlocks", (FPFI) AMemBlocks, 1, "C"},

	/* wrappers around Global memory functions */
	{"AllocHGlobal", (FPFI) AllocHGlobal, 1, "I"},
	{"FreeHGlobal", (FPFI) FreeHGlobal, 1, "I"},
	{"ReAllocHGlobal", (FPFI) ReAllocHGlobal, 2, "II"},
	{"LockHGlobal", (FPFI) LockHGlobal, 1, "I"},
	{"UnlockHGlobal", (FPFI) UnlockHGlobal, 1, "I"},

	/* memory read/write & array/cursor marshaling routines */
	{"WriteCString", (FPFI) WriteCString, 2, "IC"},
	{"WritePCString", (FPFI) WritePCString, 2, "I?"},
	{"WriteCharArray", (FPFI) WriteCharArray, 3, "IC.I"},
	{"WriteWString", (FPFI) WriteWString, 3, "IC.I"},
	{"WritePWString", (FPFI) WritePWString, 3, "I?.I"},
	{"WriteWCharArray", (FPFI) WriteWCharArray, 4, "ICI.I"},
	{"WriteWChar", (FPFI) WriteWChar, 3, "IC.I"},
	{"WritePWChar", (FPFI) WritePWChar, 3, "IC.I"},
	{"WriteBytes", (FPFI) WriteBytes, 3, "IC.I"},
	{"WriteLogical", (FPFI) WriteLogical, 2, "IL"},
	{"WritePLogical", (FPFI) WritePLogical, 2, "IL"},
	{"WriteInt64", (FPFI) WriteInt64, 2, "I?"},
	{"WritePInt64", (FPFI) WritePInt64, 2, "I?"},
	{"WriteUInt64", (FPFI) WriteUInt64, 2, "I?"},
	{"WritePUInt64", (FPFI) WritePUInt64, 2, "I?"},
	{"ReadChar", (FPFI) ReadChar, 1, "I"},
	{"ReadPChar", (FPFI) ReadPChar, 1, "I"},
	{"ReadUInt", (FPFI) ReadUInt, 1, "I"},
	{"ReadPUInt", (FPFI) ReadPUInt, 1, "I"},
	{"ReadPointer",(FPFI) ReadUInt, 1, "I"},
	{"ReadPPointer",(FPFI) ReadPUInt, 1, "I"},
	{"ReadInt64AsDouble", (FPFI) ReadInt64AsDouble, 1, "I"},
	{"ReadPInt64AsDouble", (FPFI) ReadPInt64AsDouble, 1, "I"},
	{"ReadUInt64AsDouble", (FPFI) ReadUInt64AsDouble, 1, "I"},
	{"ReadPUInt64AsDouble", (FPFI) ReadPUInt64AsDouble, 1, "I"},
	{"ReadCString", (FPFI) ReadCString, 1, "I"},
	{"ReadPCString", (FPFI) ReadPCString, 1, "I"},
	{"ReadCharArray", (FPFI) ReadCharArray, 2, "II"},
	{"ReadWString", (FPFI) ReadWString, 2, "I.I"},
	{"ReadPWString", (FPFI) ReadPWString, 2, "I.I"},
	{"ReadWCharArray", (FPFI) ReadWCharArray, 3, "II.I"},
	{"ReadBytes", (FPFI) ReadBytes, 2, "II"},
	{"ReadLogical", (FPFI) ReadLogical, 1, "I"},
	{"ReadPLogical", (FPFI) ReadPLogical, 1, "I"},
	{"MarshalArrayShort", (FPFI) MarshalArrayShort, 2 ,"IR"},
	{"MarshalArrayUShort", (FPFI) MarshalArrayUShort, 2 ,"IR"},
	{"MarshalArrayInt", (FPFI) MarshalArrayInt, 2,"IR"},
	{"MarshalArrayUInt", (FPFI) MarshalArrayUInt, 2,"IR"},
	{"MarshalArrayFloat", (FPFI) MarshalArrayFloat, 2,"IR"},
	{"MarshalArrayDouble", (FPFI) MarshalArrayDouble, 2,"IR"},
	{"MarshalArrayLogical", (FPFI) MarshalArrayLogical, 2, "IR"},
	{"MarshalArrayCString", (FPFI) MarshalArrayCString, 2,"IR"},
	{"MarshalArrayWString", (FPFI) MarshalArrayWString, 3,"IR.I"},
	{"MarshalArrayCharArray", (FPFI) MarshalArrayCharArray, 3,"IRI"},
	{"MarshalArrayWCharArray", (FPFI) MarshalArrayWCharArray, 4,"IRI.I"},
	{"UnMarshalArrayShort", (FPFI) UnMarshalArrayShort, 2 ,"IR"},
	{"UnMarshalArrayUShort", (FPFI) UnMarshalArrayUShort, 2 ,"IR"},
	{"UnMarshalArrayInt", (FPFI) UnMarshalArrayInt, 2,"IR"},
	{"UnMarshalArrayUInt", (FPFI) UnMarshalArrayUInt, 2,"IR"},
	{"UnMarshalArrayFloat", (FPFI) UnMarshalArrayFloat, 2,"IR"},
	{"UnMarshalArrayDouble", (FPFI) UnMarshalArrayDouble, 2,"IR"},
	{"UnMarshalArrayLogical", (FPFI) UnMarshalArrayLogical, 2, "IR"},
	{"UnMarshalArrayCString", (FPFI) UnMarshalArrayCString, 2,"IR"},
	{"UnMarshalArrayWString", (FPFI) UnMarshalArrayWString, 3,"IR.I"},
	{"UnMarshalArrayCharArray", (FPFI) UnMarshalArrayCharArray, 3, "IRI"},
	{"UnMarshalArrayWCharArray", (FPFI) UnMarshalArrayWCharArray, 4, "IRI.I"},
	{"MarshalCursorShort", (FPFI) MarshalCursorShort, 3,"ICI"},
	{"MarshalCursorUShort", (FPFI) MarshalCursorUShort, 3,"ICI"},
	{"MarshalCursorInt", (FPFI) MarshalCursorInt, 3,"ICI"},
	{"MarshalCursorUInt", (FPFI) MarshalCursorUInt, 3,"ICI"},
	{"MarshalCursorFloat", (FPFI) MarshalCursorFloat, 3,"ICI"},
	{"MarshalCursorDouble", (FPFI) MarshalCursorDouble, 3,"ICI"},
	{"MarshalCursorLogical", (FPFI) MarshalCursorLogical, 3, "ICI"},
	{"MarshalCursorCString", (FPFI) MarshalCursorCString, 3,"ICI"},
	{"MarshalCursorWString", (FPFI) MarshalCursorWString, 4,"ICI.I"},
	{"MarshalCursorCharArray", (FPFI) MarshalCursorCharArray, 4,"ICII"},
	{"MarshalCursorWCharArray", (FPFI) MarshalCursorWCharArray, 5,"ICII.I"},
	{"UnMarshalCursorShort", (FPFI) UnMarshalCursorShort, 4,"ICII"},
	{"UnMarshalCursorUShort", (FPFI) UnMarshalCursorUShort, 4,"ICII"},
	{"UnMarshalCursorInt", (FPFI) UnMarshalCursorInt, 4,"ICII"},
	{"UnMarshalCursorUInt", (FPFI) UnMarshalCursorUInt, 4,"ICII"},
	{"UnMarshalCursorFloat", (FPFI) UnMarshalCursorFloat, 4,"ICII"},
	{"UnMarshalCursorDouble", (FPFI) UnMarshalCursorDouble, 4,"ICII"},
	{"UnMarshalCursorLogical", (FPFI) UnMarshalCursorLogical, 4, "ICII"},
	{"UnMarshalCursorCString", (FPFI) UnMarshalCursorCString, 4,"ICII"},
	{"UnMarshalCursorWString", (FPFI) UnMarshalCursorWString, 5,"ICII.I"},
	{"UnMarshalCursorCharArray", (FPFI) UnMarshalCursorCharArray, 5, "ICIII"},
	{"UnMarshalCursorWCharArray", (FPFI) UnMarshalCursorWCharArray, 6, "ICIII.I"},

	/* numeric to binary & vice versa conversion routines */
	{"Str2Short", (FPFI) Str2Short, 1, "C"},
	{"Short2Str", (FPFI) Short2Str, 1, "I"},
	{"Str2UShort", (FPFI) Str2UShort, 1, "C"},
	{"UShort2Str", (FPFI) UShort2Str, 1, "I"},
	{"Str2Long", (FPFI) Str2Long, 1, "C"},
	{"Long2Str", (FPFI) Long2Str, 1, "I"},
	{"Str2ULong", (FPFI) Str2ULong, 1, "C"},
	{"ULong2Str", (FPFI) ULong2Str, 1, "?"},
	{"Str2Double", (FPFI) Str2Double, 1, "C"},
	{"Double2Str", (FPFI) Double2Str, 1, "N"},
	{"Str2Float", (FPFI) Str2Float, 1, "C"},
	{"Float2Str", (FPFI) Float2Str, 1, "N"},

	/* toolhelp32 api wrappers */
	{"AProcesses", (FPFI) AProcesses, 1, "C"},
	{"AProcessThreads", (FPFI) AProcessThreads, 2, "CI"},
	{"AProcessModules", (FPFI) AProcessModules, 2, "CI"},
	{"AProcessHeaps", (FPFI) AProcessHeaps, 2, "CI"},
	{"AHeapBlocks", (FPFI) AHeapBlocks, 3, "CII"},
	{"ReadProcessMemoryEx", (FPFI) ReadProcessMemoryEx, 3, "III"},
	
	/* enumeration routines */
	{"AWindowStations", (FPFI) AWindowStations, 1, "C"},
	{"ADesktops", (FPFI) ADesktops, 2, "C.I"},
	{"AWindows", (FPFI) AWindows, 3, "CI.I"},
	{"AWindowsEx", (FPFI) AWindowsEx, 4, "CCI.I"},
	{"AWindowProps", (FPFI) AWindowProps, 2, "CI"},
	{"AResourceTypes", (FPFI) AResourceTypes, 2, "CI"},
	{"AResourceNames", (FPFI) AResourceNames, 3, "CIC"},
	{"AResourceLanguages", (FPFI) AResourceLanguages, 4, "CI??"},
	{"AResolutions", (FPFI) AResolutions, 2, "C.C"},
	{"ADisplayDevices", (FPFI) ADisplayDevices, 2, "C.C"},

	/* ODBC functions */
	{"CreateSQLDataSource", (FPFI) CreateSQLDataSource, 3, "CC.I"},
	{"DeleteSQLDataSource", (FPFI) DeleteSQLDataSource, 3, "CC.I"},
	{"ChangeSQLDataSource", (FPFI) ChangeSQLDataSource, 3, "CC.I"},
	{"ASQLDataSources", (FPFI) ASQLDataSources, 2, "C.I"},
	{"ASQLDrivers", (FPFI) ASQLDrivers, 1, "C"},
	{"SQLGetPropEx", (FPFI) SQLGetPropEx, 3, "?CR"},
	{"SQLSetPropEx", (FPFI) SQLSetPropEx, 3, "?C.?"},
	{"SQLExecEx", (FPFI) SQLExecEx, 9, "I.C.C.C.I.C.C.C.I"},
	//{"SQLPrepareEx", (FPFI) SQLPrepareEx, 7,  "IC.C.I.C.C.I"},
	//{"TableUpdateEx", (FPFI) TableUpdateEx, 6, "IICCC.C"},

	/* printer functions */
	{"APrintersEx", (FPFI) APrintersEx, 5, "C.?.I.I.I"},
	{"APrintJobs", (FPFI) APrintJobs, 3, "CC.I"},
	{"APrinterForms", (FPFI) APrinterForms, 2, "C.C"},
	{"APaperSizes", (FPFI) APaperSizes, 4, "CCC.I"},
	{"APrinterTrays", (FPFI) APrinterTrays, 3, "CCC"},

	/* registry functions */
	{"CreateRegistryKey", (FPFI) CreateRegistryKey, 5, "IC.I.I.C"},
	{"DeleteRegistryKey", (FPFI) DeleteRegistryKey, 3, "IC.I"},
	{"OpenRegistryKey", (FPFI) OpenRegistryKey, 3, "IC.I"},
	{"CloseRegistryKey", (FPFI) CloseRegistryKey, 1, "I"},
	{"ReadRegistryKey", (FPFI) ReadRegistryKey, 4, "I.C.C.I"},
	{"WriteRegistryKey", (FPFI) WriteRegistryKey, 5, "I?.C.C.I"},
	{"ARegistryKeys", (FPFI) ARegistryKeys, 4, "CIC.I"},
	{"ARegistryValues", (FPFI) ARegistryValues, 4, "CIC.I"},
	{"RegistryValuesToObject", (FPFI) RegistryValuesToObject, 3, "ICO"},
	{"RegistryHiveToObject", (FPFI) RegistryHiveToObject, 3, "ICO"},

	/* file system functions */
	{"ADirEx",(FPFI) ADirEx, 4, "CC.I.I"},
	{"AFileAttributes", (FPFI) AFileAttributes, 3, "CC.L"},
	{"AFileAttributesEx", (FPFI) AFileAttributesEx, 3, "CC.L"},
	{"ADirectoryInfo", (FPFI) ADirectoryInfo, 2, "CC"},
	{"GetFileTimes", (FPFI) GetFileTimes, 5, "C?.?.?.L"},
	{"SetFileTimes", (FPFI) SetFileTimes, 5, "C?.?.?.L"},
	{"GetFileSize", (FPFI) GetFileSizeLib, 1, "C"},
	{"GetFileAttributes", (FPFI) GetFileAttributesLib, 1, "C"},
	{"SetFileAttributes", (FPFI) SetFileAttributesLib, 2, "CI"},
	{"GetFileOwner", (FPFI) GetFileOwner, 4, "CR.R.R"},
	{"GetLongPathName", (FPFI) GetLongPathNameLib, 1, "C"},
	{"GetShortPathName", (FPFI) GetShortPathNameLib, 1, "C"},
	{"DeleteDirectory", (FPFI) DeleteDirectory, 1, "C"},
	{"GetWindowsDirectory", (FPFI) GetWindowsDirectoryLib, 0, ""},
	{"GetSystemDirectory", (FPFI) GetSystemDirectoryLib, 0, ""},
	{"ExpandEnvironmentStrings", (FPFI) ExpandEnvironmentStringsLib, 1, "C"},
	{"GetOpenFileName", (FPFI) GetOpenFileNameLib, 8, ".I.C.C.C.C.I.C.C"},
	{"GetSaveFileName", (FPFI) GetSaveFileNameLib, 7, ".I.C.C.C.C.I.C"},
	{"ADriveInfo", (FPFI) ADriveInfo, 1, "C"},
	//{"AVolumeInformation", (FPFI) AVolumeInformation, 1, "C"},

	{"CopyFileEx", (FPFI) CopyFileExLib, 5, "CC.C.I.I"},
	{"MoveFileEx", (FPFI) MoveFileExLib, 5, "CC.C.I.I"},
	{"CompareFileTimes", (FPFI) CompareFileTimes, 2, "CC"},
	{"DeleteFileEx", (FPFI) DeleteFileEx, 1, "C"},
	
	/* extended VFP like file functions */
	{"FCreateEx", (FPFI) FCreateEx, 4, "C.I.I.I"},
	{"FOpenEx", (FPFI) FOpenEx, 4, "C.I.I.I"},
	{"FCloseEx", (FPFI) FCloseEx, 1, "I"},
	{"FReadEx", (FPFI) FReadEx, 2, "II"},
	{"FWriteEx", (FPFI) FWriteEx, 3, "IC.I"},
	{"FGetsEx", (FPFI) FGetsEx, 2, "I.I"},
	{"FPutsEx", (FPFI) FPutsEx, 3, "I.C.I"},
	{"FSeekEx", (FPFI) FSeekEx, 3, "IN.I"},
	{"FEoFEx", (FPFI) FEoFEx, 1, "I"},
	{"FChSizeEx", (FPFI) FChSizeEx, 2, "IN"},
	{"FFlushEx", (FPFI) FFlushEx, 1, "I"},
	{"FLockFile", (FPFI) FLockFile, 3, "I??"},
	{"FUnlockFile", (FPFI) FUnlockFile, 3, "I??"},
	{"FLockFileEx", (FPFI) FLockFileEx, 4, "I??.I"},
	{"FUnlockFileEx", (FPFI) FUnlockFileEx, 3, "I??"},
	{"AFHandlesEx", (FPFI) AFHandlesEx, 1, "C"},

	/* some shell32.dll wrappers */
	{"SHSpecialFolder", (FPFI) SHSpecialFolder, 3, "IR.L"},
	{"SHMoveFiles", (FPFI) SHMoveFiles, 4, "CCI.C"},
	{"SHCopyFiles", (FPFI) SHCopyFiles, 4, "CC.I.C"},
	{"SHDeleteFiles", (FPFI) SHDeleteFiles, 3, "C.I.C"},
	{"SHRenameFiles", (FPFI) SHRenameFiles, 3, "CC.I"},
	{"SHBrowseFolder", (FPFI) SHBrowseFolder, 5, "CIR.C.C"},

	/* windows message hooks */
	{"BindEventsEx", (FPFI) BindEventsEx, 6, "II?C.?.I"},
	{"UnbindEventsEx", (FPFI) UnbindEventsEx, 3, "I.I.L"},
	/* C callback function emulation */
	{"CreateCallbackFunc", (FPFI) CreateCallbackFunc, 5, "CCC.O.I"},
	{"DestroyCallbackFunc", (FPFI) DestroyCallbackFunc, 1, "I"},

	// some window functions
	{"GetWindowTextEx", (FPFI) GetWindowTextEx, 2, "I.L"},
	{"GetWindowRectEx", (FPFI) GetWindowRectEx, 2, "IC"},
	{"CenterWindowEx", (FPFI) CenterWindowEx, 2, "I.I"},
	{"ADesktopArea", (FPFI) ADesktopArea, 1, "C"},

	/* asynchronous notification functions */
	{"FindFileChange", (FPFI) FindFileChange, 4, "CLIC"},
	{"CancelFileChange", (FPFI) CancelFileChange, 1, "I"},
	{"FindRegistryChange", (FPFI) FindRegistryChange, 5, "ICLIC"},
	{"CancelRegistryChange", (FPFI) CancelRegistryChange, 1, "I"},
	{"AsyncWaitForObject", (FPFI) AsyncWaitForObject, 2, "IC"},
	{"CancelWaitForObject", (FPFI) CancelWaitForObject, 1, "I"},

	/* time conversion routines */
	{"DT2FT", (FPFI) DT2FT, 3, "TI.L"},
	{"FT2DT", (FPFI) FT2DT, 2, "I.L"},
	{"DT2ST", (FPFI) DT2ST, 3, "TI.L"},
	{"ST2DT", (FPFI) ST2DT, 2, "I.L"},
	{"DT2UTC", (FPFI) DT2UTC, 1, "T"},
	{"UTC2DT", (FPFI) UTC2DT, 1, "T"},
	{"DT2Timet", (FPFI) DT2Timet, 2, "T.L"},
	{"Timet2DT", (FPFI) Timet2DT, 2, "I.L" },
	{"DT2Double", (FPFI) DT2Double, 1, "T"},
	{"Double2DT", (FPFI) Double2DT, 1, "N"},
	{"SetSystemTime", (FPFI) SetSystemTimeEx, 2, "T.L"},
	{"GetSystemTime", (FPFI) GetSystemTimeEx, 1, ".L"},
	{"SetSystemTimeEx", (FPFI) SetSystemTimeEx, 1, "T"},
	{"ATimeZones", (FPFI) ATimeZones, 1, "C"},

	/* netapi32 wrappers */
	{"ANetFiles", (FPFI) ANetFiles, 4, "C.C.C.C"},
	{"ANetServers", (FPFI) ANetServers, 4, "C.I.I.C"},
	{"GetServerTime", (FPFI) GetServerTime, 2, "C.L"},
	{"SyncToServerTime", (FPFI) SyncToServerTime, 2, "C.L"},
	{"SyncToSNTPServer", (FPFI) SyncToSNTPServer, 4, "C.I.I.I"},

	/* COM routines */
	{"GetIUnknown", (FPFI) GetIUnknown, 1, "C"},
	{"CLSIDFromProgID", (FPFI) CLSIDFromProgIDLib, 1, "C"},
	{"ProgIDFromCLSID", (FPFI) ProgIDFromCLSIDLib, 1, "?"},
	{"CLSIDFromString", (FPFI) CLSIDFromStringLib, 1, "C"},
	{"StringFromCLSID", (FPFI) StringFromCLSIDLib, 1, "?"},
	{"IsEqualGuid", (FPFI) IsEqualGUIDLib, 2, "??"},
	{"CreateGuid", (FPFI) CreateGuid, 1, ".I"},
	{"RegisterActiveObject", (FPFI) RegisterActiveObjectLib, 2, "CC"},
	{"RegisterObjectAsFileMoniker", (FPFI) RegisterObjectAsFileMoniker, 3, "CCC"},
	{"RevokeActiveObject", (FPFI) RevokeActiveObjectLib, 1, "I"},
	//{"IsObjectActive", (FPFI) IsObjectActive, 2, "CC"},
	//{"CoCreateInstanceEx", (FPFI) CoCreateInstanceExLib, 2, "C.C"},
	//{"CoRegisterComDll", (FPFI) CoRegisterComDll, 1, "C"},
	//{"CoUnregisterComDll", (FPFI) CoUnregisterComDll, 1, "C"},
	{"IDispatch_Invoke", (FPFI) IDispatch_Invoke, 26, "?C.?.?.?.?.?.?.?.?.?.?.?.?.?.?.?.?.?.?.?.?.?.?.?.?"},
	{"IDispatch_AsyncInvoke", (FPFI) IDispatch_AsyncInvoke, 7, "CC?CC.I.I"},
	//{"CoCreateComProxy", (FPFI) CoCreateComProxy, 3, "CCC"},

	/* urlmon wrappers */
	{"UrlDownloadToFileEx", (FPFI) UrlDownloadToFileEx, 5, "CC.C.L.L"},
	{"AbortUrlDownloadToFileEx", (FPFI) AbortUrlDownloadToFileEx, 1, "I"},
	/* winsock functions */
	{"AIPAddresses", (FPFI) AIPAddresses, 1, "C"},
	{"ResolveHostToIp", (FPFI) ResolveHostToIp, 2, "C.C"},
	/* IP Helper */
	{"Ip2MacAddress", (FPFI) Ip2MacAddress, 1, "C"},
	{"IcmpPing", (FPFI)IcmpPing, 8, "CC.I.I.I.I.L.I"},

	/* WinInet wrappers */
	/*
	{"InitWinInet", (FPFI) InitWinInet, 5, ".C.I.C.C.I"},
	{"FTPConnect", (FPFI) FTPConnect, 5, "CCC.I.I"}, 
	{"FTPDisconnect", (FPFI) FTPDisconnect, 1, "I"},
	{"FTPGetFile", (FPFI) FTPGetFileLib, 2, "IC"},
	{"FTPPutFile", (FPFI) FTPPutFileLib, 2, "IC"},
	{"FTPGetDirectory", (FPFI) FTPGetDirectory, 1, "I"},
	{"FTPSetDirectory", (FPFI) FTPSetDirectory, 2, "IC"},
	{"AFTPFiles", (FPFI) AFTPFiles, 3, "C"},
	{"HTTPGetFile", (FPFI) HTTPGetFile, 4, "C.C.C.L"},
	*/

	/* service functions */
	{"OpenService", (FPFI) OpenServiceLib, 4, "C.I.C.C"},
	{"CloseServiceHandle", (FPFI) CloseServiceHandleLib, 1, "I"},
	{"StartService", (FPFI) StartServiceLib, 5, "?.?.?.C.C"},
	{"StopService", (FPFI) StopServiceLib, 5, "?.?.L.C.C"},
	{"PauseService", (FPFI) PauseService, 4, "?.?.C.C"},
	{"ContinueService", (FPFI) ContinueService, 4, "?.?.C.C"},
	{"ControlService", (FPFI) ControlService, 4, "?.I.C.C"},
	{"AServiceStatus", (FPFI) AServiceStatus, 4, "C?.C.C"},
	{"AServiceConfig", (FPFI) AServiceConfig, 4, "C?.C.C"},
	{"AServices", (FPFI) AServices, 5, "C.C.C.I.I"},
	{"ADependentServices", (FPFI) ADependentServices, 4, "C?.C.C"},
	{"WaitForServiceStatus", (FPFI) WaitForServiceStatus, 5, "?I.I.C.C"},

	/* misc data conversion/string functions */
	{"PG_ByteA2Str", (FPFI) PG_ByteA2Str, 1, "?"},
	{"PG_Str2ByteA", (FPFI) PG_Str2ByteA, 2, "?.L"},
	{"RGB2Colors", (FPFI) RGB2Colors, 4, "IRRR"},
	{"Colors2RGB", (FPFI) Colors2RGB, 3, "III"},
	{"GetCursorPosEx", (FPFI) GetCursorPosEx, 4, "RR.L.?"},
	//{"ColorOfPoint", (FPFI) ColorOfPoint, 3, "II.I"},
	{"Int64_Add", (FPFI) Int64_Add, 2, "??"},
	{"Int64_Sub", (FPFI) Int64_Sub, 2, "??"},
	{"Int64_Mul", (FPFI) Int64_Mul, 2, "??"},
	{"Int64_Div", (FPFI) Int64_Div, 2, "??"},
	{"Int64_Mod", (FPFI) Int64_Mod, 2, "??"},
	{"Value2Variant", (FPFI) Value2Variant, 1, "?"},
	{"Variant2Value", (FPFI) Variant2Value, 1, "?"},
	{"Decimals", (FPFI) Decimals, 1, "N"},
	{"Num2Binary", (FPFI) Num2Binary, 1, "I"},
	{"CreatePublicShadowObjReference", (FPFI) CreatePublicShadowObjReference, 2, "CO"},
	{"ReleasePublicShadowObjReference", (FPFI) ReleasePublicShadowObjReference, 1, "C"},
	{"GetLocaleInfoEx", (FPFI) GetLocaleInfoExLib, 2, "I.I"},

	/* array routines */
	{"ASum", (FPFI) ASum, 2, "R.I"},
	{"AAverage", (FPFI) AAverage, 2, "R.I"},
	{"AMax", (FPFI) AMax, 2, "R.I"},
	{"AMin", (FPFI) AMin, 2, "R.I"},
	{"ASplitStr", (FPFI) ASplitStr, 3, "CCI"},

	/* RAS wrappers */
	{"ARasConnections", (FPFI) ARasConnections, 1, "C"},
	{"ARasDevices", (FPFI) ARasDevices, 1, "C"},
	{"ARasPhonebookEntries", (FPFI)ARasPhonebookEntries, 2, "C.C"},
	{"RasPhonebookDlgEx", (FPFI) RasPhonebookDlgEx, 4, ".?.?.?.I"},
	{"RasDialEx",(FPFI) RasDialEx, 5, ".?.C.C.I.I"},
	{"RasHangUpEx", (FPFI) RasHangUpEx, 1, "I"},
	{"RasGetConnectStatusEx", (FPFI) RasGetConnectStatusEx, 2, "IC"},
	{"RasDialDlgEx", (FPFI) RasDialDlgEx, 3, ".C.C.C"},
	{"RasConnectionNotificationEx", (FPFI) RasConnectionNotificationEx, 3, "IIC"},
	{"AbortRasConnectionNotificationEx", (FPFI) AbortRasConnectionNotificationEx, 1, "I"},
	{"RasClearConnectionStatisticsEx", (FPFI) RasClearConnectionStatisticsEx, 1, "I"},

	/* Font routines */
	{"AFontInfo", (FPFI) AFontInfo, 3, "C.I.I"},

	/* error handling routines */
	{"FormatMessageEx", (FPFI) FormatMessageEx, 3, "I.I.I"},
	{"AErrorEx", (FPFI) AErrorEx, 1, "C"}

#ifdef _DEBUG
	,{"AMemLeaks", (FPFI) AMemLeaks, 1, "C"}
	,{"TrackMem", (FPFI) TrackMem, 2, "L.L"}
#endif
};

FoxTable _FoxTable = {
(FoxTable *)0, sizeof(VFP2CFuncs)/sizeof(FoxInfo), VFP2CFuncs
};

#ifdef __cplusplus
}
#endif

#include <windows.h>
#include <stdio.h>

#include "pro_ext.h"
#include "vfp2c32.h"
#include "vfp2cutil.h"
#include "vfpmacros.h"
#include "vfp2cenum.h"
#include "vfp2ccppapi.h"
#include "vfp2chelpers.h"

// PSAPI data
static HMODULE ghPsApi = 0;

static PENUMPROCESSES fpEnumProcesses = 0;
static PENUMPROCESSMODULES fpEnumProcessModules = 0;
static PGETMODULEBASENAME fpGetModuleBaseName = 0;
static PNTQUERYINFORMATIONPROCESS fpNtQueryInformationProcess = 0;

static bool gbPSAPIFuncs = false;

// Toolhelp functions pointers
static PGETPROCESSWINDOWSTATION fpGetProcessWindowStation = 0;
static PENUMWINDOWSTATIONS fpEnumWindowStations = 0;
static PENUMDESKTOPWINDOWS fpEnumDesktopWindows = 0;
static PENUMDESKTOPS fpEnumDesktops = 0;

static PCREATESNAPSHOT fpCreateToolhelp32Snapshot = 0;
static PPROCESSENUM fpProcess32First = 0;
static PPROCESSENUM fpProcess32Next = 0;
static PTHREADENUM fpThread32First = 0;
static PTHREADENUM fpThread32Next = 0;
static PMODULEENUM fpModule32First = 0;
static PMODULEENUM fpModule32Next = 0;
static PHEAPENUM fpHeap32ListFirst = 0;
static PHEAPENUM fpHeap32ListNext = 0;
static PHEAP32FIRST fpHeap32First = 0;
static PHEAP32NEXT fpHeap32Next = 0;
static PREADPROCESSMEMORY fpToolhelp32ReadProcessMemory = 0;

static PENUMDISPLAYSETTINGS fpEnumDisplaySettings = 0;
static PENUMDISPLAYDEVICES fpEnumDisplayDevices = 0;

// flags if the dynamic functions are loaded succesfully
static bool gbProcessEnumFuncs = false;
static bool gbThreadEnumFuncs = false;
static bool gbModuleEnumFuncs = false;
static bool gbHeapEnumFuncs = false;
static bool gbHeapBlockEnumFuncs = false;

// link needed functions
bool _stdcall VFP2C_Init_Enum()
{
	HMODULE hDll;
	bool bRetVal = true;

	if (IS_WINNT())
	{
		ghPsApi = LoadLibrary("psapi.dll");
		if (ghPsApi)
		{
			fpEnumProcesses = (PENUMPROCESSES)GetProcAddress(ghPsApi,"EnumProcesses");
            fpEnumProcessModules = (PENUMPROCESSMODULES)GetProcAddress(ghPsApi,"EnumProcessModules");
			fpGetModuleBaseName = (PGETMODULEBASENAME)GetProcAddress(ghPsApi,"GetModuleBaseNameA");
		}

		hDll = GetModuleHandle("ntdll.dll");
		if (hDll)
			fpNtQueryInformationProcess = 
			(PNTQUERYINFORMATIONPROCESS)GetProcAddress(hDll,"NtQueryInformationProcess");
	
		gbPSAPIFuncs = (fpEnumProcesses && fpEnumProcessModules && fpGetModuleBaseName &&
						fpNtQueryInformationProcess);
	}


	// we can use GetModuleHandle instead of LoadLibrary since kernel32.dll is loaded already by VFP for sure
	hDll = GetModuleHandle("kernel32.dll");
	if (hDll)
	{
		fpCreateToolhelp32Snapshot = (PCREATESNAPSHOT)GetProcAddress(hDll,"CreateToolhelp32Snapshot"); 
		fpProcess32First = (PPROCESSENUM)GetProcAddress(hDll,"Process32First");
		fpProcess32Next = (PPROCESSENUM)GetProcAddress(hDll,"Process32Next");
		fpThread32First = (PTHREADENUM)GetProcAddress(hDll,"Thread32First");
		fpThread32Next =  (PTHREADENUM)GetProcAddress(hDll,"Thread32Next");
		fpModule32First = (PMODULEENUM)GetProcAddress(hDll,"Module32First");        
		fpModule32Next = (PMODULEENUM)GetProcAddress(hDll,"Module32Next");
		fpHeap32ListFirst = (PHEAPENUM)GetProcAddress(hDll,"Heap32ListFirst");
		fpHeap32ListNext = (PHEAPENUM)GetProcAddress(hDll,"Heap32ListNext");
		fpHeap32First = (PHEAP32FIRST)GetProcAddress(hDll,"Heap32First");
		fpHeap32Next = (PHEAP32NEXT)GetProcAddress(hDll,"Heap32Next");
		fpToolhelp32ReadProcessMemory = (PREADPROCESSMEMORY)GetProcAddress(hDll,"Toolhelp32ReadProcessMemory");

		gbProcessEnumFuncs = (fpCreateToolhelp32Snapshot && fpProcess32First && fpProcess32Next); 
		gbThreadEnumFuncs = (fpCreateToolhelp32Snapshot && fpThread32First && fpThread32Next);
		gbModuleEnumFuncs = (fpCreateToolhelp32Snapshot && fpModule32First && fpModule32Next);
		gbHeapEnumFuncs = (fpCreateToolhelp32Snapshot && fpHeap32ListFirst && fpHeap32ListNext);
		gbHeapBlockEnumFuncs = (fpHeap32First && fpHeap32Next);
	}
	else
	{
		ADDWIN32ERROR(GetModuleHandle,GetLastError());
		bRetVal = false;
	}

	// user32.dll is also loaded by VFP ..
	hDll = GetModuleHandle("user32.dll");
	if (hDll)
	{
		fpGetProcessWindowStation = (PGETPROCESSWINDOWSTATION)GetProcAddress(hDll,"GetProcessWindowStation");
		fpEnumWindowStations = (PENUMWINDOWSTATIONS)GetProcAddress(hDll,"EnumWindowStationsA");
		fpEnumDesktops = (PENUMDESKTOPS)GetProcAddress(hDll,"EnumDesktopsA");
		fpEnumDesktopWindows = (PENUMDESKTOPWINDOWS)GetProcAddress(hDll,"EnumDesktopWindows");
		fpEnumDisplaySettings = (PENUMDISPLAYSETTINGS)GetProcAddress(hDll,"EnumDisplaySettingsA");
		fpEnumDisplayDevices = (PENUMDISPLAYDEVICES)GetProcAddress(hDll,"EnumDisplayDevicesA");
	}
	else
	{
		ADDWIN32ERROR(GetModuleHandle,GetLastError());
		bRetVal = false;
	}

	return bRetVal;
}

void _stdcall VFP2C_Destroy_Enum()
{
	if (ghPsApi)
		FreeLibrary(ghPsApi);
}

void _fastcall AWindowStations(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	// entry point to EnumWindowStations valid?
	if (!fpEnumWindowStations)
		throw E_NOENTRYPOINT;

	WINDOWSTATIONENUMPARAM sEnum;

	// initialize array
	sEnum.pArray.Dimension(p1,1);
	// allocate temporary memory in a Value structure 
	// which is used to store the enumerated values into the array
	sEnum.pWinStaName.Size(WINDOWSTATION_ENUM_LEN);

	if (!fpEnumWindowStations(WindowStationEnumCallback,(LPARAM)&sEnum))
	{
		SAVEWIN32ERROR(EnumWindowStations,GetLastError());
		throw E_APIERROR;
	}

	sEnum.pArray.ReturnRows();
}
catch (int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

BOOL _stdcall WindowStationEnumCallback(LPSTR lpszWinSta, LPARAM nParam)
{
	LPWINDOWSTATIONENUMPARAM pEnum = (LPWINDOWSTATIONENUMPARAM)nParam;
	pEnum->pArray.Grow();
	pEnum->pArray = pEnum->pWinStaName = lpszWinSta;
	return TRUE;
} 

void _fastcall ADesktops(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpEnumDesktops)
		throw E_NOENTRYPOINT;

	DESKTOPENUMPARAM sEnum;
	HWINSTA hWinSta;

	sEnum.pArray.Dimension(p1,1);
	sEnum.pDesktopName.Size(DESKTOP_ENUM_LEN);

	hWinSta = PCOUNT() == 1 ? fpGetProcessWindowStation() : (HWINSTA)p2.ev_long;
	
	if (!fpEnumDesktops(hWinSta,(DESKTOPENUMPROC)DesktopEnumCallback,(LPARAM)&sEnum))
	{
		SAVEWIN32ERROR(EnumDesktops,GetLastError());
		throw E_APIERROR;
	}

	sEnum.pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

BOOL _stdcall DesktopEnumCallback(LPCSTR lpszDesktop, LPARAM nParam)
{
	LPDESKTOPENUMPARAM pEnum = (LPDESKTOPENUMPARAM)nParam;
	pEnum->pArray.Grow();
	pEnum->pArray = pEnum->pDesktopName = lpszDesktop;
	return TRUE;  
}

void _fastcall AWindows(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	WINDOWENUMPARAM sEnum;
	DWORD nEnumFlag = (DWORD)p2.ev_long;
	DWORD nLastError = ERROR_SUCCESS;

	// are parameters valid?
	if (PCOUNT() == 2 && !(nEnumFlag & WINDOW_ENUM_TOPLEVEL))
		throw E_INVALIDPARAMS;
	else if (!(nEnumFlag & (WINDOW_ENUM_TOPLEVEL|WINDOW_ENUM_CHILD|WINDOW_ENUM_THREAD|WINDOW_ENUM_DESKTOP)))
		throw E_INVALIDPARAMS;

	if (nEnumFlag & WINDOW_ENUM_CALLBACK && p1.ev_length > VFP2C_MAX_CALLBACKFUNCTION)
		throw E_INVALIDPARAMS;
	
	if (nEnumFlag & WINDOW_ENUM_CALLBACK)
	{
		sEnum.pBuffer = p1;
		sEnum.pBuffer += "(%U)";
		sEnum.pCallback.Size(VFP2C_MAX_CALLBACKBUFFER);
	}
	else
		sEnum.pArray.Dimension(p1,1);

	if (nEnumFlag & WINDOW_ENUM_TOPLEVEL)
	{
		if (!EnumWindows(nEnumFlag & WINDOW_ENUM_CALLBACK ? WindowEnumCallbackCall : WindowEnumCallback,
			(LPARAM)&sEnum))
			nLastError = GetLastError();
	}
	else if (nEnumFlag & WINDOW_ENUM_CHILD)
	{
		if (!EnumChildWindows((HWND)p3.ev_long,
			nEnumFlag & WINDOW_ENUM_CALLBACK ? WindowEnumCallbackCall : WindowEnumCallback,
			(LPARAM)&sEnum))
			nLastError = GetLastError();
	}
	else if (nEnumFlag & WINDOW_ENUM_THREAD)
	{
		if (!EnumThreadWindows((DWORD)p3.ev_long,
			nEnumFlag & WINDOW_ENUM_CALLBACK ? WindowEnumCallbackCall : WindowEnumCallback,
			(LPARAM)&sEnum))
			nLastError = GetLastError();
	}
	else if (nEnumFlag & WINDOW_ENUM_DESKTOP)
	{
		if (!fpEnumDesktopWindows)
			throw E_NOENTRYPOINT;

		if (!fpEnumDesktopWindows((HDESK)p3.ev_long,
			nEnumFlag & WINDOW_ENUM_CALLBACK ? WindowEnumCallbackCall : WindowEnumCallback,
			(LPARAM)&sEnum))
			nLastError = GetLastError();
	}

	if (nLastError != ERROR_SUCCESS)
	{
		SAVEWIN32ERROR(EnumWindowsX,nLastError);
		throw E_APIERROR;
	}

	if (nEnumFlag & WINDOW_ENUM_CALLBACK)
		Return(1);
	else
		sEnum.pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

BOOL _stdcall WindowEnumCallback(HWND nHwnd, LPARAM nParam)
{
	LPWINDOWENUMPARAM pEnum = (LPWINDOWENUMPARAM)nParam;
	pEnum->pArray.Grow();
	pEnum->pArray = (int)nHwnd;
	return TRUE;		
}

BOOL _stdcall WindowEnumCallbackCall(HWND nHwnd, LPARAM nParam) throw(int)
{
	LPWINDOWENUMPARAM pEnum = (LPWINDOWENUMPARAM)nParam;
	FoxValue vRetVal;
	sprintfex(pEnum->pCallback, pEnum->pBuffer, nHwnd);
	Evaluate(vRetVal, pEnum->pCallback);
	if (vRetVal.Vartype() == 'L')
        return vRetVal->ev_length;
	else
		return 0;
}

void _fastcall AWindowsEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	FoxString pFlags(p2);
	WINDOWENUMPARAMEX sEnum;
	
	// are parameters valid?
	if (PCOUNT() == 3 && p3.ev_long != WINDOW_ENUM_TOPLEVEL)
		throw E_INVALIDPARAMS;
	else if (p3.ev_long < WINDOW_ENUM_TOPLEVEL || p3.ev_long > WINDOW_ENUM_DESKTOP)
		throw E_INVALIDPARAMS;

	sEnum.pBuffer.Size(WINDOW_ENUM_CLASSLEN);

	sEnum.aFlags[0] = pFlags.At('W',1,WINDOW_ENUM_FLAGS); // HWND
	sEnum.aFlags[1] = pFlags.At('C',1,WINDOW_ENUM_FLAGS); // WindowClass
	sEnum.aFlags[2] = pFlags.At('T',1,WINDOW_ENUM_FLAGS); // WindowText
	sEnum.aFlags[3] = pFlags.At('S',1,WINDOW_ENUM_FLAGS); // Style
	sEnum.aFlags[4] = pFlags.At('E',1,WINDOW_ENUM_FLAGS); // ExStyle
	sEnum.aFlags[5] = pFlags.At('H',1,WINDOW_ENUM_FLAGS); // HInstance
	sEnum.aFlags[6] = pFlags.At('P',1,WINDOW_ENUM_FLAGS); // ParentHwnd
	sEnum.aFlags[7] = pFlags.At('D',1,WINDOW_ENUM_FLAGS); // UserData
	sEnum.aFlags[8] = pFlags.At('I',1,WINDOW_ENUM_FLAGS); // ID
	sEnum.aFlags[9] = pFlags.At('R',1,WINDOW_ENUM_FLAGS); // ThreadID
	sEnum.aFlags[10] = pFlags.At('O',1,WINDOW_ENUM_FLAGS); // ProcessID
	sEnum.aFlags[11] = pFlags.At('V',1,WINDOW_ENUM_FLAGS); // Visible
	sEnum.aFlags[12] = pFlags.At('N',1,WINDOW_ENUM_FLAGS); // Iconic
	sEnum.aFlags[13] = pFlags.At('M',1,WINDOW_ENUM_FLAGS); // Maximized
	sEnum.aFlags[14] = pFlags.At('U',1,WINDOW_ENUM_FLAGS); // Unicode

	short nMaxDim = 0;
	for (unsigned int nFlag = 0; nFlag < WINDOW_ENUM_FLAGS; nFlag++)
		nMaxDim = max(nMaxDim,sEnum.aFlags[nFlag]);

	if (nMaxDim == 0)
		throw E_INVALIDPARAMS;

	sEnum.pArray.Dimension(p1,1,nMaxDim);

	DWORD nLastError = ERROR_SUCCESS;
	switch(p3.ev_long)
	{
		case WINDOW_ENUM_TOPLEVEL:
			if (!EnumWindows(WindowEnumCallbackEx,(LPARAM)&sEnum))
				nLastError = GetLastError();
			break;

		case WINDOW_ENUM_CHILD:
            if (!EnumChildWindows((HWND)p4.ev_long,WindowEnumCallbackEx,(LPARAM)&sEnum))
				nLastError = GetLastError();
			break;

		case WINDOW_ENUM_THREAD:
            if (!EnumThreadWindows((DWORD)p4.ev_long,WindowEnumCallbackEx,(LPARAM)&sEnum))
				nLastError = GetLastError();
			break;

		case WINDOW_ENUM_DESKTOP:
            if (!fpEnumDesktopWindows)
				throw E_NOENTRYPOINT;

			if (!fpEnumDesktopWindows((HDESK)p4.ev_long,WindowEnumCallbackEx,(LPARAM)&sEnum))
				nLastError = GetLastError();
	}

	if (nLastError != ERROR_SUCCESS)
	{
		SAVEWIN32ERROR(EnumXWindows,nLastError);
		throw E_APIERROR;
	}

	sEnum.pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

BOOL _stdcall WindowEnumCallbackEx(HWND nHwnd, LPARAM nParam)
{
	DWORD nProcessID, nThreadID;
	LPWINDOWENUMPARAMEX pEnum = (LPWINDOWENUMPARAMEX)nParam;

	unsigned int nRow = pEnum->pArray.Grow();

	if (pEnum->aFlags[0])
		pEnum->pArray(nRow,pEnum->aFlags[0]) = (int)nHwnd;
	
	if(pEnum->aFlags[1])
		pEnum->pArray(nRow,pEnum->aFlags[1]) = pEnum->pBuffer.Len(GetClassName(nHwnd,pEnum->pBuffer,WINDOW_ENUM_CLASSLEN));
		
	if (pEnum->aFlags[2])
		pEnum->pArray(nRow,pEnum->aFlags[2]) = pEnum->pBuffer.Len(GetWindowText(nHwnd,pEnum->pBuffer,WINDOW_ENUM_TEXTLEN));

	if (pEnum->aFlags[3])
		pEnum->pArray(nRow,pEnum->aFlags[3]) = GetWindowLong(nHwnd,GWL_STYLE);

	if (pEnum->aFlags[4])
		pEnum->pArray(nRow,pEnum->aFlags[4]) = GetWindowLong(nHwnd,GWL_EXSTYLE);

	if (pEnum->aFlags[5])
		pEnum->pArray(nRow,pEnum->aFlags[5]) = GetWindowLong(nHwnd,GWL_HINSTANCE);

	if (pEnum->aFlags[6])
		pEnum->pArray(nRow,pEnum->aFlags[6]) = (int)GetParent(nHwnd);

	if (pEnum->aFlags[7])
		pEnum->pArray(nRow,pEnum->aFlags[7]) = GetWindowLong(nHwnd,GWL_USERDATA);

	if (pEnum->aFlags[8])
		pEnum->pArray(nRow,pEnum->aFlags[8]) = GetWindowLong(nHwnd,GWL_ID);
	
	if (pEnum->aFlags[9] || pEnum->aFlags[10])
	{
		nThreadID = GetWindowThreadProcessId(nHwnd,&nProcessID);
		if (pEnum->aFlags[9])
			pEnum->pArray(nRow,pEnum->aFlags[9]) = nThreadID;
		if (pEnum->aFlags[10])
			pEnum->pArray(nRow,pEnum->aFlags[10]) = nProcessID;
	}

	if (pEnum->aFlags[11])
		pEnum->pArray(nRow,pEnum->aFlags[11]) = IsWindowVisible(nHwnd) > 0;

	if (pEnum->aFlags[12])
		pEnum->pArray(nRow,pEnum->aFlags[12]) = IsIconic(nHwnd) > 0;

	if (pEnum->aFlags[13])
		pEnum->pArray(nRow,pEnum->aFlags[13]) = IsZoomed(nHwnd) > 0; 

	if (pEnum->aFlags[14])
		pEnum->pArray(nRow,pEnum->aFlags[14]) = IsWindowUnicode(nHwnd) > 0;

	return TRUE;
}

void _fastcall AWindowProps(ParamBlk *parm)
{
try
{
	WPROPENUMPARAM sEnum;
	int nApiRet;

	sEnum.pArray.Dimension(p1,1,2);
	sEnum.pProperty.Size(WINDOWPROP_ENUM_LEN);
	
	nApiRet = EnumPropsEx((HWND)p2.ev_long,(PROPENUMPROCEX)WindowPropEnumCallback,(LPARAM)&sEnum);

	if (nApiRet != -1)
		sEnum.pArray.ReturnRows();
	else
		Return(0);
}
catch (int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

BOOL _stdcall WindowPropEnumCallback(HWND nHwnd, LPCSTR pPropName, HANDLE hData, DWORD nParam)
{
	LPWPROPENUMPARAM pEnum = (LPWPROPENUMPARAM)nParam;
	if (IsBadReadPtr(pPropName,1))
		return TRUE;
	unsigned int nRow = pEnum->pArray.Grow();
	pEnum->pArray(nRow,1) = pEnum->pProperty = pPropName;
	pEnum->pArray(nRow,2) = (int)hData;
	return TRUE;		
}

void _fastcall AProcesses(ParamBlk *parm)
{
	RESETWIN32ERRORS();

	if (IS_WINNT())
	{
		AProcessesPSAPI(parm);
		return;
	}
try
{
	if (!gbProcessEnumFuncs)
		throw E_NOENTRYPOINT;

	ApiHandle hProcSnap;
	FoxString pExeName(MAX_PATH+1);
	FoxArray pArray(p1,1,5);
	PROCESSENTRY32 pProcs;
	DWORD nLastError;

	hProcSnap = fpCreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0);
	if(!hProcSnap)
	{
		SAVEWIN32ERROR(CreateToolhelp32Snapshot,GetLastError());
		throw E_APIERROR;
	}
	
	pProcs.dwSize = sizeof(PROCESSENTRY32);

	if(!fpProcess32First(hProcSnap,&pProcs))
	{
		nLastError = GetLastError();
		if (nLastError == ERROR_NO_MORE_FILES)
		{
			Return(0);
			return;
		}
		else
		{
			SAVEWIN32ERROR(Process32First,nLastError);
			throw E_APIERROR;
		}
	}

	unsigned int nRow;
	do
	{
		nRow = pArray.Grow();		
		pArray(nRow,1) = pExeName = pProcs.szExeFile;
		pArray(nRow,2) = pProcs.th32ProcessID;
		pArray(nRow,3) = pProcs.th32ParentProcessID;
		// impossible to be greater than MAX_LONG so we can just use int instead of casting to double
		pArray(nRow,4) = (int)pProcs.cntThreads;
		pArray(nRow,5) = pProcs.pcPriClassBase;
	} while(fpProcess32Next(hProcSnap,&pProcs));

	nLastError = GetLastError();
	if (nLastError != ERROR_NO_MORE_FILES)
	{
		SAVEWIN32ERROR(Process32Next,nLastError);
		throw E_APIERROR;
	}

	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall AProcessesPSAPI(ParamBlk *parm)
{
try
{
	FoxArray pArray(p1);
	FoxString pExeName(MAX_PATH+1);
	CBuffer pBuffer;
	ApiHandle hProcess;
	LPDWORD lpProcIds;
	DWORD dwProcesses = 256, dwBytes;
	HMODULE hModule;
	PROCESS_BASIC_INFORMATION_EX sProcInfo;

	if (!gbPSAPIFuncs)
		throw E_NOENTRYPOINT;

	while (1)
	{
		pBuffer.Size(dwProcesses*sizeof(DWORD));
		lpProcIds = (LPDWORD)pBuffer.Address();

		if (!fpEnumProcesses(lpProcIds,dwProcesses*sizeof(DWORD),&dwBytes))
		{
			SAVEWIN32ERROR(EnumProcesses,GetLastError());
			throw E_APIERROR;
		}

		// there are probably more processes available, so realloc and retry
		if(dwBytes / sizeof(DWORD) == dwProcesses)
			dwProcesses += 128;
		else
			break;
	}

	dwProcesses = dwBytes / sizeof(DWORD);
	
	pArray.Dimension(dwProcesses,5);

	for (unsigned int xj = 1; xj <= dwProcesses; xj++)
	{
		hProcess = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ,FALSE,lpProcIds[xj]);
        if(hProcess)
        {
            if(!fpEnumProcessModules(hProcess,&hModule,sizeof(HMODULE),&dwBytes))
            {
				SAVEWIN32ERROR(EnumProcessModules,GetLastError());
				throw E_APIERROR;
			}
	
			pExeName.Len(fpGetModuleBaseName(hProcess,hModule,pExeName,MAX_PATH+1));
			if (!pExeName.Len())
			{
				SAVEWIN32ERROR(GetModuleBaseName,GetLastError());
				throw E_APIERROR;
			}
			pArray(xj,1) = pExeName;
			pArray(xj,2) = lpProcIds[xj];

            if (!fpNtQueryInformationProcess(hProcess,0,(void*)&sProcInfo,
				sizeof(PROCESS_BASIC_INFORMATION_EX),&dwBytes))
			{
				pArray(xj,3) = sProcInfo.InheritedFromUniqueProcessId;
				pArray(xj,5) = sProcInfo.BasePriority;
			}
			else
			{
				pArray(xj,3) = 0;
				pArray(xj,5) = 0;
			}
			pArray(xj,4) = 0;
		}
		else
		{
			pExeName.Len(0);
			pArray(xj,1) = pExeName;
			pArray(xj,2) = lpProcIds[xj];
			pArray(xj,3) = 0;
			pArray(xj,4) = 0;
			pArray(xj,5) = 0;
		}
	}
	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall AProcessThreads(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	FoxArray pArray(p1,1,3);
	ApiHandle hThreadSnap;
	THREADENTRY32 pThreads; 
   	DWORD nProcId = (DWORD)p2.ev_long;
	DWORD nLastError;

	if (!gbThreadEnumFuncs)
		throw E_NOENTRYPOINT;

	// Take a snapshot of all running threads  
	hThreadSnap = fpCreateToolhelp32Snapshot(TH32CS_SNAPTHREAD,0); 
	if(!hThreadSnap)
	{
        SAVEWIN32ERROR(CreateToolhelp32SnapShot,GetLastError());
		throw E_APIERROR;
	}
     
	pThreads.dwSize = sizeof(THREADENTRY32); 
	if(!fpThread32First(hThreadSnap,&pThreads)) 
	{
		nLastError = GetLastError();
		if (nLastError == ERROR_NO_MORE_FILES)
		{
			Return(0);
			return;
		}
		else
		{
			SAVEWIN32ERROR(Thread32First,nLastError);
			throw E_APIERROR;
		}
	}

	unsigned int nRow;
	do 
	{ 
		if(nProcId == 0 || nProcId == pThreads.th32OwnerProcessID)
		{
			nRow = pArray.Grow();
			pArray(nRow,1) = pThreads.th32ThreadID;
			pArray(nRow,2) = pThreads.th32OwnerProcessID;
			pArray(nRow,3) = pThreads.tpBasePri;
		}
	} while(fpThread32Next(hThreadSnap,&pThreads)); 

	nLastError = GetLastError();
	if (nLastError != ERROR_NO_MORE_FILES)
	{
		SAVEWIN32ERROR(Thread32Next,nLastError);
		throw E_APIERROR;
	}

	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall AProcessModules(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	FoxArray pArray(p1,1,5);
	FoxString pBuffer(MAX_PATH+1);
	ApiHandle hModuleSnap; 
	MODULEENTRY32 pModules;
  	DWORD nProcId = (DWORD)p2.ev_long;
	DWORD nLastError;
	
	if (!gbModuleEnumFuncs)
		throw E_NOENTRYPOINT;

	pModules.dwSize = sizeof(MODULEENTRY32);
	// Take a snapshot of all running threads
	hModuleSnap = fpCreateToolhelp32Snapshot(TH32CS_SNAPMODULE,nProcId); 
	if(!hModuleSnap)
	{
		SAVEWIN32ERROR(CreateToolhelp32SnapShot,GetLastError());
		throw E_APIERROR;
	}

	if(!fpModule32First(hModuleSnap,&pModules))
	{
		nLastError = GetLastError();
		if (nLastError == ERROR_NO_MORE_FILES)
		{
			Return(0);
			return;
		}
		else
		{
			SAVEWIN32ERROR(Module32First,nLastError);
			throw E_APIERROR;
		}
	}

	unsigned int nRow;
	do 
	{ 
		nRow = pArray.Grow();
		pArray(nRow,1) = pBuffer = pModules.szModule;
		pArray(nRow,2) = pBuffer = pModules.szExePath;
		pArray(nRow,3) = (int)pModules.hModule;
		pArray(nRow,4) = pModules.modBaseSize;
		pArray(nRow,5) = (int)pModules.modBaseAddr;
	} while(fpModule32Next(hModuleSnap,&pModules)); 

	nLastError = GetLastError();
	if (nLastError != ERROR_NO_MORE_FILES)
	{
		SAVEWIN32ERROR(Module32Next,nLastError);
		throw E_APIERROR;
	}

	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall AProcessHeaps(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!gbHeapEnumFuncs)
		throw E_NOENTRYPOINT;

	FoxArray pArray(p1,1,2);
	ApiHandle hHeapSnap;
  	DWORD nProcId = (DWORD)p2.ev_long;
	DWORD nLastError;
	HEAPLIST32 pHeaps; 

	pHeaps.dwSize = sizeof(HEAPLIST32);

	// Take a snapshot of all running threads
	hHeapSnap = fpCreateToolhelp32Snapshot(TH32CS_SNAPHEAPLIST,nProcId); 
	if(!hHeapSnap)
	{
		SAVEWIN32ERROR(CreateToolhelp32SnapShot,GetLastError());
		throw E_APIERROR;
	}

	if(!fpHeap32ListFirst(hHeapSnap,&pHeaps))
	{
		nLastError = GetLastError();
		if (nLastError == ERROR_NO_MORE_FILES)
		{
			Return(0);
			return;
		}
		else
		{
			SAVEWIN32ERROR(HeapList32First,nLastError);
			throw E_APIERROR;
		}
	}

	unsigned int nRow;
	do 
	{ 
		nRow = pArray.Grow();
		pArray(nRow,1) = pHeaps.th32HeapID;
		pArray(nRow,2) = pHeaps.dwFlags;
	} while(fpHeap32ListNext(hHeapSnap,&pHeaps)); 

	nLastError = GetLastError();
	if (nLastError != ERROR_NO_MORE_FILES)
	{
		SAVEWIN32ERROR(Heap32ListNext,nLastError);
		throw E_APIERROR;
	}

	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall AHeapBlocks(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!gbHeapBlockEnumFuncs)
		throw E_NOENTRYPOINT;

	FoxArray pArray(p1,1,6);
	HEAPENTRY32 pHeapEntry;
	DWORD nLastError;

	pHeapEntry.dwSize = sizeof(HEAPENTRY32);

	if (!fpHeap32First(&pHeapEntry,(DWORD)p2.ev_long,(DWORD)p3.ev_long))
	{
		nLastError = GetLastError();
		if (nLastError == ERROR_NO_MORE_FILES)
		{
			Return(0);
			return;
		}
		else
		{
            SAVEWIN32ERROR(Heap32First,nLastError);
			throw E_APIERROR;
		}
	}

	unsigned int nRow;
	do
	{
		nRow = pArray.Grow();
		pArray(nRow,1) = (int)pHeapEntry.dwSize;
		pArray(nRow,2) = (int)pHeapEntry.hHandle;
		pArray(nRow,3) = (int)pHeapEntry.dwAddress;
		pArray(nRow,4) = (int)pHeapEntry.dwBlockSize;
		pArray(nRow,5) = (int)pHeapEntry.dwFlags;
		pArray(nRow,6) = (int)pHeapEntry.dwLockCount;
	} while(fpHeap32Next(&pHeapEntry));

	nLastError = GetLastError();
	if (nLastError != ERROR_NO_MORE_FILES)
	{
		SAVEWIN32ERROR(Heap32Next,nLastError);
		throw E_APIERROR;
	}
	
	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall ReadProcessMemoryEx(ParamBlk *parm)
{
try
{
	if (!fpToolhelp32ReadProcessMemory)
		throw E_NOENTRYPOINT;

	FoxString vRetVal(p3.ev_long);
	SIZE_T dwRead;

	if (fpToolhelp32ReadProcessMemory((DWORD)p1.ev_long,(LPCVOID)p2.ev_long,
		vRetVal,(SIZE_T)p3.ev_long,&dwRead))
		vRetVal.Len(dwRead);
	else
		vRetVal.Len(0);
	
	vRetVal.Return();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
} 

void _fastcall AResourceTypes(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	RESOURCEENUMPARAM sEnum;

	sEnum.pArray.Dimension(p1,1);
	sEnum.pBuffer.Size(RESOURCE_ENUM_TYPELEN);

	if (!EnumResourceTypes((HMODULE)p2.ev_long,(ENUMRESTYPEPROC)ResourceTypesEnumCallback,(LONG)&sEnum))
	{
		SAVEWIN32ERROR(EnumResourceTypes,GetLastError());
		throw E_APIERROR;
	}

	sEnum.pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

BOOL _stdcall ResourceTypesEnumCallback(HANDLE hModule, LPSTR lpszType, LONG nParam)  
{
	LPRESOURCEENUMPARAM pEnum = (LPRESOURCEENUMPARAM)nParam;
	pEnum->pArray.Grow();
	if ((ULONG)lpszType & 0xFFFF0000) 
		pEnum->pArray = pEnum->pBuffer = lpszType;
	else
		pEnum->pArray = (int)(unsigned short)lpszType;
	return TRUE;		
}

void _fastcall AResourceNames(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	RESOURCEENUMPARAM sEnum;
	FoxString pType(parm,3);
	char *pResourceType;

	sEnum.pArray.Dimension(p1,1);
	sEnum.pBuffer.Size(RESOURCE_ENUM_NAMELEN);

	if (Vartype(p3) == 'C')
		pResourceType = pType;
	else if (Vartype(p3) == 'I')
        pResourceType = (char*)p3.ev_long; 
	else if (Vartype(p3) == 'N')
		pResourceType = (char*)(int)p3.ev_real;
	else
		throw E_INVALIDPARAMS;

	if (!EnumResourceNames((HMODULE)p2.ev_long,pResourceType,
		(ENUMRESNAMEPROC)ResourceNamesEnumCallback,(LONG_PTR)&sEnum))
	{
		SAVEWIN32ERROR(EnumResourceNames,GetLastError());
		throw E_APIERROR;
	}

	sEnum.pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

BOOL _stdcall ResourceNamesEnumCallback(HANDLE hModule, LPCSTR lpszType, LPSTR lpszName, LONG_PTR nParam)
{
	LPRESOURCEENUMPARAM pEnum = (LPRESOURCEENUMPARAM)nParam;
	pEnum->pArray.Grow();
	if ((ULONG)lpszName & 0xFFFF0000)
		pEnum->pArray = pEnum->pBuffer = lpszName;
	else
		pEnum->pArray = (int)lpszName;
	return TRUE;
}

void _fastcall AResourceLanguages(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	RESOURCEENUMPARAM sEnum;
	FoxString pType(parm,3);
	FoxString pName(parm,4);
	char *pResourceType;
	char *pResourceName;

	sEnum.pArray.Dimension(p1,1);
	
	if (Vartype(p3) == 'C')
		pResourceType = pType;
	else if (Vartype(p3) == 'I')
		pResourceType = (char*)p3.ev_long;
	else if (Vartype(p3) == 'N')
		pResourceType = (char*)(int)p3.ev_real;
	else
		throw E_INVALIDPARAMS;

	if (Vartype(p4) == 'C')
        pResourceName = pName;
	else if (Vartype(p4) == 'I')
		pResourceName = (char*)p4.ev_long;
	else if (Vartype(p4) == 'N')
		pResourceName = (char*)(int)p4.ev_real;
	else
		throw E_INVALIDPARAMS;

	if (!EnumResourceLanguages((HMODULE)p2.ev_long,pResourceType,pResourceName,
		(ENUMRESLANGPROC)ResourceLangEnumCallback,(LONG)&sEnum))
	{
		SAVEWIN32ERROR(EnumResourceLanguages,GetLastError());
		throw E_APIERROR;
	}

	sEnum.pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

BOOL _stdcall ResourceLangEnumCallback(HANDLE hModule, LPCSTR lpszType, LPCSTR lpszName,
									   WORD wIDLanguage, LONG nParam)
{
	LPRESOURCEENUMPARAM pEnum = (LPRESOURCEENUMPARAM)nParam;
	pEnum->pArray.Grow();
	pEnum->pArray = (int)wIDLanguage;
	return TRUE;
}

void _fastcall AResolutions(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();
	FoxArray pArray(p1,1,4);
	FoxString pDevice(parm,2);
	DWORD nLastError = ERROR_SUCCESS;
	DEVMODE sDevMode;

	if (!fpEnumDisplaySettings)
		throw E_NOENTRYPOINT;

	sDevMode.dmDriverExtra = 0;
	sDevMode.dmSize = sizeof(DEVMODE);

	DWORD dwRes = 0;
	while (fpEnumDisplaySettings(pDevice,dwRes++,&sDevMode))
	{
		unsigned int nRow;
		nRow = pArray.Grow();
		pArray(nRow,1) = (int)sDevMode.dmPelsWidth;
		pArray(nRow,2) = (int)sDevMode.dmPelsHeight;
		pArray(nRow,3) = (int)sDevMode.dmBitsPerPel;
		pArray(nRow,4) = (int)sDevMode.dmDisplayFrequency;
	}

	if (IS_WIN2KXP())
		nLastError = GetLastError();

	if (nLastError != ERROR_SUCCESS)
	{
		SAVEWIN32ERROR(EnumDisplaySettings,nLastError);
		throw E_APIERROR;
	}

	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall ADisplayDevices(ParamBlk *parm)
{
try
{
	if (!fpEnumDisplayDevices)
		throw E_NOENTRYPOINT;

	FoxArray pArray(p1,1,5);
	FoxString pDevice(parm,2);
	FoxString pBuffer(DISPLAYDEVICE_ENUM_LEN);
	DISPLAY_DEVICE sDevice;	

	sDevice.cb = sizeof(DISPLAY_DEVICE);
	DWORD dwDev = 0;
	unsigned int nRow;
	while (fpEnumDisplayDevices(pDevice,dwDev++,&sDevice,0))
	{
		nRow = pArray.Grow();
		pArray(nRow,1) = pBuffer = sDevice.DeviceString;
		pArray(nRow,2) = pBuffer = sDevice.DeviceName;
		pArray(nRow,3) = pBuffer = sDevice.DeviceID;
		pArray(nRow,4) = pBuffer = sDevice.DeviceKey;
		pArray(nRow,5) = (int)sDevice.StateFlags;
	}

	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}
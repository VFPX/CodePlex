#ifndef _VFP2CENUM_H__
#define _VFP2CENUM_H__

#include <tlhelp32.h>
#include <vdmdbg.h>

#include "vfp2ccppapi.h"
#include "vfp2chelpers.h"

// custom class windowstation and desktop enumeration functions
class EnumParameter
{
public:
	EnumParameter() { pName.Size(1024); }
	FoxArray pArray;
	FoxString pName;
};

// custom types and defines for window enumeration & window property enumeration functions 
#define WINDOW_ENUM_CLASSLEN	128
#define WINDOW_ENUM_TEXTLEN		4096
#define WINDOW_ENUM_TOPLEVEL	1
#define WINDOW_ENUM_CHILD		2
#define WINDOW_ENUM_THREAD		4
#define WINDOW_ENUM_DESKTOP		8
#define WINDOW_ENUM_CALLBACK	16
#define WINDOW_ENUM_FLAGS		15
#define WINDOWPROP_ENUM_LEN	1024

class WindowEnumParam
{
public:
	FoxArray pArray;
	CStr pBuffer;
	CStr pCallback;
};

class WindowEnumParamEx
{
public:
	WindowEnumParamEx() { pBuffer.Size(WINDOW_ENUM_CLASSLEN); }
	FoxArray pArray;
	FoxString pBuffer;
	unsigned short aFlags[WINDOW_ENUM_FLAGS];
};

// custom types and defines for resource enumeration functions
#define RESOURCE_ENUM_TYPELEN 512
#define RESOURCE_ENUM_NAMELEN 2048

typedef struct _RESOURCEENUMPARAM {
	FoxArray pArray;
	FoxString pBuffer;
} RESOURCEENUMPARAM, *LPRESOURCEENUMPARAM;

typedef struct _PROCESS_BASIC_INFORMATION_EX {
    int ExitStatus;
    void* PebBaseAddress;
    unsigned int AffinityMask;
    int BasePriority;
    ULONG UniqueProcessId;
    ULONG InheritedFromUniqueProcessId;
} PROCESS_BASIC_INFORMATION_EX, *LPPROCESS_BASIC_INFORMATION_EX;

#define DISPLAYDEVICE_ENUM_LEN	128

// typedef's for runtime dynamic linking to some functions that might not be available on all Windows platforms

// windowstation & desktop functions
typedef HWINSTA (_stdcall *PGETPROCESSWINDOWSTATION)(VOID); // GetProcessWindowStation
typedef BOOL (_stdcall *PENUMWINDOWSTATIONS)(WINSTAENUMPROC, LPARAM); // EnumWindowStations
typedef BOOL (_stdcall *PENUMDESKTOPS)(HWINSTA, DESKTOPENUMPROC, LPARAM); // EnumDesktops
typedef BOOL (_stdcall *PENUMDESKTOPWINDOWS)(HDESK, WNDENUMPROC, LPARAM); // EnumDesktopWindows

// process/thread/module enum functions (Toolhelp32 api)
typedef HANDLE (_stdcall *PCREATESNAPSHOT)(DWORD, DWORD); // CreateToolhelp32Snapshot
typedef BOOL (_stdcall *PPROCESSENUM)(HANDLE, LPPROCESSENTRY32); // Process32First, Process32Next
typedef BOOL (_stdcall *PTHREADENUM)(HANDLE, LPTHREADENTRY32); // Thread32First, Thread32Next
typedef BOOL (_stdcall *PMODULEENUM)(HANDLE, LPMODULEENTRY32); // Module32First, Module32Next 
typedef BOOL (_stdcall *PHEAPENUM)(HANDLE, LPHEAPLIST32); // HeapList32First, HeapList32Next 
typedef BOOL (_stdcall *PHEAP32FIRST)(LPHEAPENTRY32, DWORD, DWORD); // Heap32First
typedef BOOL (_stdcall *PHEAP32NEXT)(LPHEAPENTRY32); // Heap32Next
typedef BOOL (_stdcall *PREADPROCESSMEMORY)(DWORD,LPCVOID,LPVOID,SIZE_T,SIZE_T*); // Toolhelp32ReadProcessMemory

// process enumeration on WinNT4 functions
typedef BOOL (_stdcall *PENUMPROCESSES)(LPDWORD, DWORD, LPDWORD); // EnumProcesses
typedef BOOL (_stdcall *PENUMPROCESSMODULES)(HANDLE, HMODULE*, DWORD, LPDWORD); // EnumProcessModules
typedef DWORD (_stdcall *PGETMODULEBASENAME)(HANDLE, HMODULE, LPTSTR, DWORD); // GetModuleBaseName
typedef LONG (_stdcall *PNTQUERYINFORMATIONPROCESS)(HANDLE, int, void*, ULONG, PULONG); // NtQueryInformationProcess

typedef BOOL (_stdcall *PENUMDISPLAYSETTINGS)(LPCTSTR,DWORD,LPDEVMODE); // EnumDisplaySettings
typedef BOOL (_stdcall *PENUMDISPLAYDEVICES)(LPCTSTR,DWORD,PDISPLAY_DEVICE,DWORD); // EnumDisplayDevices

#ifdef __cplusplus
extern "C" {
#endif

// function prototypes of vfp2cenum.c
bool _stdcall VFP2C_Init_Enum();
void _stdcall VFP2C_Destroy_Enum();

void _fastcall AWindowStations(ParamBlk *parm);
BOOL _stdcall WindowStationEnumCallback(LPSTR lpszWinSta, LPARAM nParam);
void _fastcall ADesktops(ParamBlk *parm);
BOOL _stdcall DesktopEnumCallback(LPCSTR lpszDesktop, LPARAM nParam);
void _fastcall AWindows(ParamBlk *parm);
BOOL _stdcall WindowEnumCallback(HWND nHwnd, LPARAM nParam);
#pragma warning(disable : 4290) // disable warning 4290 - VC++ doesn't implement throw ...
BOOL _stdcall WindowEnumCallbackCall(HWND nHwnd, LPARAM nParam) throw(int);
void _fastcall AWindowsEx(ParamBlk *parm);
BOOL _stdcall WindowEnumCallbackEx(HWND nHwnd, LPARAM nParam);
void _fastcall AWindowProps(ParamBlk *parm);
BOOL _stdcall WindowPropEnumCallback(HWND nHwnd, LPCSTR pPropName, HANDLE hData, DWORD nParam);
void _fastcall AProcesses(ParamBlk *parm);
void _fastcall AProcessesPSAPI(ParamBlk *parm);
void _fastcall AProcessThreads(ParamBlk *parm);
void _fastcall AProcessModules(ParamBlk *parm);
void _fastcall AProcessHeaps(ParamBlk *parm);
void _fastcall AHeapBlocks(ParamBlk *parm);
void _fastcall ReadProcessMemoryEx(ParamBlk *parm);
void _fastcall AResourceTypes(ParamBlk *parm);
BOOL _stdcall ResourceTypesEnumCallback(HANDLE hModule, LPSTR lpszType, LONG nParam);
void _fastcall AResourceNames(ParamBlk *parm);
BOOL _stdcall ResourceNamesEnumCallback(HANDLE hModule, LPCSTR lpszType, LPSTR lpszName, LONG_PTR nParam);
void _fastcall AResourceLanguages(ParamBlk *parm);
BOOL _stdcall ResourceLangEnumCallback(HANDLE hModule, LPCSTR lpszType, LPCSTR lpszName,
									   WORD wIDLanguage, LONG nParam);
void _fastcall AResolutions(ParamBlk *parm);
void _fastcall ADisplayDevices(ParamBlk *parm);

#ifdef __cplusplus
}
#endif // end of extern "C"

#endif // _VFP2CENUM_H__
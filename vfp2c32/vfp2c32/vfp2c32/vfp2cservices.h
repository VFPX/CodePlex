#ifndef _VFP2CSERVICES_H__
#define _VFP2CSERVICES_H__

#include "vfp2chelpers.h"

typedef BOOL (_stdcall *PENUMSERVICESSTATUS)(SC_HANDLE,DWORD,DWORD,LPENUM_SERVICE_STATUS,DWORD,LPDWORD,
											 LPDWORD,LPDWORD); // EnumServicesStatus
typedef BOOL (_stdcall *PENUMSERVICESSTATUSEX)(SC_HANDLE,SC_ENUM_TYPE,DWORD,DWORD,LPBYTE,DWORD,LPDWORD,
											   LPDWORD,LPDWORD,LPCTSTR); // EnumServicesStatusEx
typedef SC_HANDLE (_stdcall *POPENSCMANAGER)(LPCTSTR,LPCTSTR,DWORD); // OpenSCManager
typedef BOOL (_stdcall *PCLOSESERVICEHANDLE)(SC_HANDLE); // CloseServiceHandle
typedef BOOL (_stdcall *PSTARTSERVICE)(SC_HANDLE,DWORD,LPCTSTR*); // StartService
typedef SC_HANDLE (_stdcall *POPENSERVICE)(SC_HANDLE,LPCTSTR,DWORD); // OpenService
typedef BOOL (_stdcall *PCLOSESERVICEHANDLE)(SC_HANDLE); // CloseServiceHandle
typedef BOOL (_stdcall *PCONTROLSERVICE)(SC_HANDLE,DWORD,LPSERVICE_STATUS); // ControlService
typedef BOOL (_stdcall *PQUERYSERVICESTATUS)(SC_HANDLE,LPSERVICE_STATUS); // QueryServiceStatus
typedef BOOL (_stdcall *PQUERYSERVICECONFIG)(SC_HANDLE,LPQUERY_SERVICE_CONFIG,DWORD,LPDWORD); // QueryServiceConfig
typedef BOOL (_stdcall *PENUMDEPENDENTSERVICES)(SC_HANDLE,DWORD,LPENUM_SERVICE_STATUS,DWORD,LPDWORD,LPDWORD);

// EnumDependentServices

#define SERVICE_ENUM_BUFFER 8192 
#define SERVICE_MAX_ENUM_BUFFER 32768 
#define SERVICE_INFINITE_TIMEOUT -1
#define SERVICE_DEFAULT_TIMEOUT -2

class ServiceManager
{
public:
	ServiceManager() : m_Handle(NULL) {}
	ServiceManager(const char *pMachine, const char *pDatabase, DWORD dwAccess = 0);
	~ServiceManager();

	void Open(const char *pMachine, const char *pDatabase, DWORD dwAccess = 0);

	operator SC_HANDLE() { return m_Handle; }
	operator LPSC_HANDLE() { return &m_Handle; }

private:
	SC_HANDLE m_Handle;
};

class Service
{
public:
	Service() : m_Handle(NULL), m_Owner(true) {}
	Service(int hHandle) { m_Handle = reinterpret_cast<SC_HANDLE>(hHandle); m_Owner = false; }
	Service(SC_HANDLE hSCM, const char* pServiceName, DWORD dwAccess);
	~Service();

	void Open(SC_HANDLE hSCM, const char* pServiceName, DWORD dwAccess = 0);
	int Stop(bool bStopDependencies, int nTimeout, SC_HANDLE hSCM);
	int Start(DWORD nNumberOfArgs, LPCSTR *pArgs, int nTimeout);
	int Pause(int nTimeout);
	int Continue(int nTimeout);
	int Control(DWORD nControlCode);
	void QueryStatus(LPSERVICE_STATUS pStatus);
	void QueryConfig(CBuffer &pBuffer);
	void StopDependantServices(SC_HANDLE hSCM);
	SC_HANDLE Detach() { m_Owner = false; return m_Handle; }

	operator SC_HANDLE() { return m_Handle; }
	operator LPSC_HANDLE() { return &m_Handle; }
	bool operator!() { return m_Handle == NULL; }
	operator bool() { return m_Handle != NULL; }
	Service& operator=(SC_HANDLE hHandle);
	Service& operator=(int hHandle);
	int WaitForServiceStatus(DWORD dwState, int nTimeout);

private:
	SC_HANDLE m_Handle;
	bool m_Owner;
	SERVICE_STATUS m_Status;
};

#ifdef __cplusplus
extern "C" {
#endif

bool _stdcall VFP2C_Init_Services();

void _fastcall OpenServiceLib(ParamBlk *parm);
void _fastcall CloseServiceHandleLib(ParamBlk *parm);
void _fastcall StartServiceLib(ParamBlk *parm);
void _fastcall StopServiceLib(ParamBlk *parm);
void _fastcall PauseService(ParamBlk *parm);
void _fastcall ContinueService(ParamBlk *parm);
void _fastcall AServices(ParamBlk *parm);
void _fastcall AServiceStatus(ParamBlk *parm);
void _fastcall AServiceConfig(ParamBlk *parm);
void _fastcall ADependentServices(ParamBlk *parm);
void _fastcall WaitForServiceStatus(ParamBlk *parm);

#ifdef __cplusplus
}
#endif

#endif _VFP2CSERVICES_H__
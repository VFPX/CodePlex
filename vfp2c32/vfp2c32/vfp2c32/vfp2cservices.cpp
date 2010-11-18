#include <windows.h>

#include "pro_ext.h"
#include "vfp2c32.h"
#include "vfp2cutil.h"
#include "vfp2cservices.h"
#include "vfp2ccppapi.h"
#include "vfp2chelpers.h"
#include "vfpmacros.h"

// dynamic function pointers
static POPENSCMANAGER fpOpenSCManager = 0;
static PCLOSESERVICEHANDLE fpCloseServiceHandle = 0;
static PENUMSERVICESSTATUS fpEnumServicesStatus = 0;
static PENUMSERVICESSTATUSEX fpEnumServicesStatusEx = 0;
static PSTARTSERVICE fpStartService = 0;
static POPENSERVICE fpOpenService = 0;
static PCONTROLSERVICE fpControlService = 0;
static PQUERYSERVICESTATUS fpQueryServiceStatus = 0;
static PQUERYSERVICECONFIG fpQueryServiceConfig = 0;
static PENUMDEPENDENTSERVICES fpEnumDependentServices = 0;

ServiceManager::ServiceManager(const char *pMachine, const char *pDatabase, DWORD dwAccess)
{
	Open(pMachine,pDatabase,dwAccess);
}

ServiceManager::~ServiceManager()
{
	if (m_Handle)
		fpCloseServiceHandle(m_Handle);
}

void ServiceManager::Open(const char *pMachine, const char *pDatabase, DWORD dwAccess)
{
	m_Handle = fpOpenSCManager(pMachine,pDatabase,dwAccess);
	if (m_Handle == NULL)
	{
		SAVEWIN32ERROR(OpenSCManager,GetLastError());
		throw E_APIERROR;
	}
}

Service::Service(SC_HANDLE hSCM, const char* pServiceName, DWORD dwAccess)
{
	Open(hSCM,pServiceName,dwAccess);
}

Service::~Service()
{
	if (m_Handle && m_Owner)
		fpCloseServiceHandle(m_Handle);
}

void Service::Open(SC_HANDLE hSCM, const char* pServiceName, DWORD dwAccess)
{
	if (m_Handle && m_Owner)
		fpCloseServiceHandle(m_Handle);

	m_Handle = fpOpenService(hSCM,pServiceName,dwAccess);
	if (m_Handle == NULL)
	{
		SAVEWIN32ERROR(OpenService,GetLastError());
		throw E_APIERROR;
	}
	m_Owner = true;
}

int Service::Start(DWORD nNumberOfArgs, LPCSTR *pArgs, int nTimeout)
{
	// Check if the service is already running
	QueryStatus(&m_Status);

	if (m_Status.dwCurrentState == SERVICE_RUNNING)
		return 1;

	if (m_Status.dwCurrentState != SERVICE_START_PENDING)
	{
		if (!fpStartService(m_Handle, nNumberOfArgs, pArgs))
		{
			SAVEWIN32ERROR(StartService,GetLastError());
			throw E_APIERROR;
		}

		QueryStatus(&m_Status);
	}

	// Check the status until the service is no longer start pending. 
    // Save the tick count and initial checkpoint.
	DWORD dwOldCheckPoint, dwStartTime, dwTimeout;
	bool bCustomTimeout = false;

	dwOldCheckPoint = m_Status.dwCheckPoint;
	dwStartTime = GetTickCount();

	if (nTimeout == 0)
		return 0;
	else if (nTimeout == SERVICE_DEFAULT_TIMEOUT)
		dwTimeout = m_Status.dwWaitHint;
	else
	{
		dwTimeout = nTimeout * 1000;
		bCustomTimeout = true;
	}

	while (m_Status.dwCurrentState != SERVICE_RUNNING) 
	{ 
		// Check the status again. 
		QueryStatus(&m_Status);

		if(m_Status.dwCheckPoint > dwOldCheckPoint)
		{
			// The service is making progress.
			if (!bCustomTimeout)
			{
				dwStartTime = GetTickCount();
				dwOldCheckPoint = m_Status.dwCheckPoint;
				dwTimeout = m_Status.dwWaitHint;
			}
		}
		else if(GetTickCount() - dwStartTime > dwTimeout)
			break;

		Sleep(333);
	} 

	return m_Status.dwCurrentState == SERVICE_RUNNING ? 1 : 0;
}

int Service::Stop(bool bStopDependencies, int nTimeout, SC_HANDLE hSCM)
{
	// Make sure the service is not already stopped
	QueryStatus(&m_Status);

	if (m_Status.dwCurrentState == SERVICE_STOPPED)
		return 1;

	if (m_Status.dwCurrentState == SERVICE_STOP_PENDING)
		return WaitForServiceStatus(SERVICE_STOPPED,nTimeout);

	if (bStopDependencies)
		StopDependantServices(hSCM);

	// Send a stop code to the main service
	if (!fpControlService(m_Handle,SERVICE_CONTROL_STOP,&m_Status))
	{
		SAVEWIN32ERROR(ControlService,GetLastError());
		throw E_APIERROR;
	}

	return WaitForServiceStatus(SERVICE_STOPPED,nTimeout);
}

int Service::Pause(int nTimeout)
{
	// make sure the service is not already paused
	QueryStatus(&m_Status);

	if (m_Status.dwCurrentState == SERVICE_PAUSED)
		return 1;

	if (m_Status.dwCurrentState == SERVICE_PAUSE_PENDING)
		return WaitForServiceStatus(SERVICE_PAUSED, nTimeout);

	// Send pause command to the service
	if (!fpControlService(m_Handle,SERVICE_CONTROL_PAUSE,&m_Status))
	{
		SAVEWIN32ERROR(ControlService,GetLastError());
		throw E_APIERROR;
	}

	return WaitForServiceStatus(SERVICE_PAUSED, nTimeout);
}

int Service::Continue(int nTimeout)
{
	// make sure the service is not already paused
	QueryStatus(&m_Status);

	if (m_Status.dwCurrentState == SERVICE_RUNNING)
		return 1;

	// If continue is pending, just wait for it
	if (m_Status.dwCurrentState == SERVICE_CONTINUE_PENDING)
		return WaitForServiceStatus(SERVICE_RUNNING, nTimeout);

	// Send pause command to the service
	if (!fpControlService(m_Handle, SERVICE_CONTROL_CONTINUE, &m_Status))
	{
		SAVEWIN32ERROR(ControlService,GetLastError());
		throw E_APIERROR;
	}

	return WaitForServiceStatus(SERVICE_RUNNING,nTimeout);
}

int Service::Control(DWORD nControlCode)
{
	// Send a stop code to the main service
	if (!fpControlService(m_Handle, nControlCode, &m_Status))
	{
		SAVEWIN32ERROR(ControlService,GetLastError());
		throw E_APIERROR;
	}
	return 1;
}

void Service::QueryStatus(LPSERVICE_STATUS pStatus)
{
	if (!fpQueryServiceStatus(m_Handle, pStatus))
	{
		SAVEWIN32ERROR(QueryServiceStatus,GetLastError());
		throw E_APIERROR;
	}
}

void Service::QueryConfig(CBuffer &pBuffer)
{
	DWORD nBytesNeeded = 0;
	pBuffer.Size(8192);
	if(!fpQueryServiceConfig(m_Handle, reinterpret_cast<LPQUERY_SERVICE_CONFIG>(pBuffer.Address()), pBuffer.Size(), &nBytesNeeded))
	{
		SAVEWIN32ERROR(QueryServiceConfig,GetLastError());
		throw E_APIERROR;
	}
}

int Service::WaitForServiceStatus(DWORD dwState, int nTimeout)
{
	DWORD nStartTime = GetTickCount();
	DWORD dwTimeout;

	if (nTimeout == SERVICE_DEFAULT_TIMEOUT)
		dwTimeout = m_Status.dwWaitHint;
	else if (nTimeout == SERVICE_INFINITE_TIMEOUT)
		dwTimeout = INFINITE;
	else
		dwTimeout = nTimeout * 1000;

	if (dwTimeout == 0)
		return 0;

	while (m_Status.dwCurrentState != dwState) 
	{
		QueryStatus(&m_Status);

		if (m_Status.dwCurrentState == dwState)
			break;
		if (dwTimeout != INFINITE && GetTickCount() - nStartTime > dwTimeout)
			break;

		Sleep(250);
	}
	return m_Status.dwCurrentState == dwState ? 1 : 0;
}

void Service::StopDependantServices(SC_HANDLE hSCM)
{
	Service hDepService;
	CBuffer pBuffer;
	DWORD nApiRet, nBytesNeeded, nCount;
    LPENUM_SERVICE_STATUS pDepStatus;

	// this will always fail, called to determine the required buffersize
	fpEnumDependentServices(m_Handle, SERVICE_ACTIVE, 0, 0, &nBytesNeeded, &nCount);
	nApiRet = GetLastError();
	if (nApiRet != ERROR_MORE_DATA)
	{
		SAVEWIN32ERROR(EnumDependentServices,nApiRet);
		throw E_APIERROR;
	}
	
	pBuffer.Size(nBytesNeeded);
	pDepStatus = reinterpret_cast<LPENUM_SERVICE_STATUS>(pBuffer.Address());

	if (!fpEnumDependentServices(m_Handle,SERVICE_ACTIVE, pDepStatus, nBytesNeeded, &nBytesNeeded, &nCount))
	{
		SAVEWIN32ERROR(EnumDependentServices,GetLastError());
		throw E_APIERROR;
	}
	
	for (unsigned int xj = 0; xj < nCount; xj++) 
	{
		hDepService.Open(hSCM,pDepStatus->lpServiceName, SERVICE_STOP|SERVICE_QUERY_STATUS|SERVICE_ENUMERATE_DEPENDENTS);
		hDepService.Stop(true,INFINITE,hSCM);
		pDepStatus++;
	}
}

Service& Service::Attach(Value &pVal)
{
	if (m_Handle && m_Owner)
	{
		fpCloseServiceHandle(m_Handle);
		m_Handle = NULL;
	}

	if (Vartype(pVal) == 'I')
		m_Handle = reinterpret_cast<SC_HANDLE>(pVal.ev_long);
	else if (Vartype(pVal) == 'N')
		m_Handle = reinterpret_cast<SC_HANDLE>(static_cast<long>(pVal.ev_real));

	m_Owner = false;
	return *this;
}

bool _stdcall VFP2C_Init_Services()
{
	HMODULE hDll;

	hDll = GetModuleHandle("advapi32.dll");
	if (hDll)
	{
		fpOpenSCManager = (POPENSCMANAGER)GetProcAddress(hDll,"OpenSCManagerA");
		fpCloseServiceHandle = (PCLOSESERVICEHANDLE)GetProcAddress(hDll,"CloseServiceHandle");
		fpEnumServicesStatus = (PENUMSERVICESSTATUS)GetProcAddress(hDll,"EnumServicesStatusA");
		fpEnumServicesStatusEx = (PENUMSERVICESSTATUSEX)GetProcAddress(hDll,"EnumServicesStatusExA");
		fpStartService = (PSTARTSERVICE)GetProcAddress(hDll,"StartServiceA");
		fpOpenService = (POPENSERVICE)GetProcAddress(hDll,"OpenServiceA");
		fpControlService = (PCONTROLSERVICE)GetProcAddress(hDll,"ControlService");
		fpQueryServiceStatus = (PQUERYSERVICESTATUS)GetProcAddress(hDll,"QueryServiceStatus");
		fpQueryServiceConfig = (PQUERYSERVICECONFIG)GetProcAddress(hDll,"QueryServiceConfigA");
		fpEnumDependentServices = (PENUMDEPENDENTSERVICES)GetProcAddress(hDll,"EnumDependentServicesA");
	}
	else
	{
		ADDWIN32ERROR(GetModuleHandle,GetLastError());
		return false;
	}
	return true;
}

void _fastcall OpenServiceLib(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpOpenSCManager)
		throw E_NOENTRYPOINT;

	DWORD dwAccess = PCOUNT() >= 2 && p2.ev_long ? p2.ev_long : SERVICE_ALL_ACCESS;
	FoxString pServiceName(parm,1);
	FoxString pMachine(parm,3);
	FoxString pDatabase(parm,4);

	ServiceManager hSCM;
	Service hService;

	hSCM.Open(pMachine,pDatabase);
	hService.Open(hSCM,pServiceName,dwAccess);

	Return(hService.Detach());
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall CloseServiceHandleLib(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpCloseServiceHandle)
		throw E_NOENTRYPOINT;

	if (!fpCloseServiceHandle(reinterpret_cast<SC_HANDLE>(p1.ev_long)))
	{
		SAVEWIN32ERROR(CloseServiceHandle,GetLastError());
		throw E_APIERROR;
	}
	Return(true);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall StartServiceLib(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpOpenSCManager)
		throw E_NOENTRYPOINT;

	if (PCOUNT() >= 2 && Vartype(p2) != 'R' && Vartype(p2) != '0')
		throw E_INVALIDPARAMS;

	if (PCOUNT() >= 3 && Vartype(p3) != 'I' && Vartype(p3) != 'N' && Vartype(p3) != '0')
		throw E_INVALIDPARAMS;

	FoxString pService(parm,1);
	FoxArray pArgs(parm, 2);
	FoxString pMachine(parm,4);
	FoxString pDatabase(parm,5);
	FoxCStringArray pArguments;
	ServiceManager hSCM;
	Service hService;

	if (Vartype(p1) == 'I' || Vartype(p1) == 'N')
	{
		if (PCOUNT() >= 4)
			throw E_INVALIDPARAMS;
		hService.Attach(p1);
	}
	else if (Vartype(p1) == 'C')
	{
		hSCM.Open(pMachine,pDatabase);
		hService.Open(hSCM,pService, SERVICE_START|SERVICE_QUERY_STATUS);
	}
	else
		throw E_INVALIDPARAMS;

	pArguments = pArgs;

	if (PCOUNT() < 3 || Vartype(p3) == '0')
		p3.ev_long = SERVICE_DEFAULT_TIMEOUT;

	Return (hService.Start(pArguments.ARows(), pArguments, p3.ev_long));
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall StopServiceLib(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpOpenSCManager)
		throw E_NOENTRYPOINT;

	if (PCOUNT() >= 2 && Vartype(p2) != 'I' && Vartype(p2) != 'N' && Vartype(p2) != '0')
		throw E_INVALIDPARAMS;

	if (PCOUNT() < 2 || Vartype(p2) == '0')
		p2.ev_long = SERVICE_DEFAULT_TIMEOUT;

	bool bStopDependencies = PCOUNT() >= 3 && p3.ev_length;

	FoxString pServiceName(parm,1);
	FoxString pMachine(parm,4);
	FoxString pDatabase(parm,5);

	ServiceManager hSCM;
	Service hService;

	if (Vartype(p1) == 'C' || bStopDependencies)
        hSCM.Open(pMachine,pDatabase);

	if (Vartype(p1) == 'I' || Vartype(p1) == 'N')
	{
		hService.Attach(p1);
	}
	else if (Vartype(p1) == 'C')
	{
		hService.Open(hSCM,pServiceName,bStopDependencies ? (SERVICE_STOP|SERVICE_QUERY_STATUS|SERVICE_ENUMERATE_DEPENDENTS) : (SERVICE_STOP|SERVICE_QUERY_STATUS));
	}
	else
		throw E_INVALIDPARAMS;

	Return(hService.Stop(bStopDependencies,p2.ev_long,hSCM));
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall PauseService(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpOpenSCManager)
		throw E_NOENTRYPOINT;

	if (PCOUNT() >= 2 && Vartype(p2) != 'I' && Vartype(p2) != 'N' && Vartype(p2) != '0')
		throw E_INVALIDPARAMS;

	if (PCOUNT() < 2 || Vartype(p2) == '0')
		p2.ev_long = SERVICE_DEFAULT_TIMEOUT;

	FoxString pServiceName(parm,1);
	FoxString pMachine(parm,3);
	FoxString pDatabase(parm,4);
	ServiceManager hSCM;
	Service hService;

	if (Vartype(p1) == 'I' || Vartype(p1) == 'N')
	{
		hService.Attach(p1);
	}
	else if (Vartype(p1) == 'C')
	{
		hSCM.Open(pMachine,pDatabase);
		hService.Open(hSCM,pServiceName,SERVICE_PAUSE_CONTINUE|SERVICE_QUERY_STATUS);
	}
	else
		throw E_INVALIDPARAMS;

	Return(hService.Pause(p2.ev_long));
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);	
}
}

void _fastcall ContinueService(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpOpenSCManager)
		throw E_NOENTRYPOINT;

	if (PCOUNT() >= 2 && Vartype(p2) != 'I' && Vartype(p2) != 'N' && Vartype(p2) != '0')
		throw E_INVALIDPARAMS;

	if (PCOUNT() < 2 || Vartype(p2) == '0')
		p2.ev_long = SERVICE_DEFAULT_TIMEOUT;

	FoxString pServiceName(parm,1);
	FoxString pMachine(parm,3);
	FoxString pDatabase(parm,4);
	ServiceManager hSCM;
	Service hService;

	if (Vartype(p1) == 'I' || Vartype(p1) == 'N')
	{
		hService.Attach(p1);
	}
	else if (Vartype(p1) == 'C')
	{
		hSCM.Open(pMachine,pDatabase);
		hService.Open(hSCM,pServiceName,SERVICE_PAUSE_CONTINUE|SERVICE_QUERY_STATUS);
	}
	else
		throw E_INVALIDPARAMS;

	Return (hService.Continue(p2.ev_long));
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall ControlServiceLib(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpOpenSCManager)
		throw E_NOENTRYPOINT;

	FoxString pServiceName(parm,1);
	FoxString pMachine(parm,3);
	FoxString pDatabase(parm,4);
	ServiceManager hSCM;
	Service hService;

	if (Vartype(p1) == 'I' || Vartype(p1) == 'N')
	{
		hService.Attach(p1);
	}
	else if (Vartype(p1) == 'C')
	{
		hSCM.Open(pMachine,pDatabase);
		hService.Open(hSCM,pServiceName,SERVICE_USER_DEFINED_CONTROL);
	}
	else
		throw E_INVALIDPARAMS;

	Return(hService.Control(p2.ev_long));
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall AServices(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpOpenSCManager)
		throw E_NOENTRYPOINT;

	FoxArray pArray(p1,1,10);
	FoxString pMachine(parm,2);
	FoxString pDatabase(parm,3);
	FoxString pStringBuffer(MAX_PATH+1);
	ServiceManager hSCM;
	CBuffer pBuffer;

	DWORD dwState, dwType, dwBytes = SERVICE_ENUM_BUFFER, hResume = 0;
	DWORD nServices, nLastError;
	unsigned int nRow;
	LPENUM_SERVICE_STATUS pServiceStatus;
	LPENUM_SERVICE_STATUS_PROCESS pServiceStatusEx;
	
	dwState = PCOUNT() >= 4 && p4.ev_long ? p4.ev_long : SERVICE_STATE_ALL;
	dwType = PCOUNT() >= 5 && p5.ev_long ? p5.ev_long : SERVICE_WIN32;

	hSCM.Open(pMachine,pDatabase,SC_MANAGER_ENUMERATE_SERVICE);

	pBuffer.Size(dwBytes);
	pArray.AutoGrow(32);

	if (fpEnumServicesStatusEx)
	{
		while (1)
		{
			if (!fpEnumServicesStatusEx(hSCM,SC_ENUM_PROCESS_INFO, dwType, dwState, pBuffer, dwBytes, &dwBytes, &nServices, &hResume,0))
				nLastError = GetLastError();
			else
				nLastError = ERROR_SUCCESS;
	
			if (nLastError != ERROR_SUCCESS && nLastError != ERROR_MORE_DATA)
			{
				SAVEWIN32ERROR(EnumServicesStatusEx,nLastError);
				throw E_APIERROR;
			}

			pServiceStatusEx = reinterpret_cast<LPENUM_SERVICE_STATUS_PROCESS>(pBuffer.Address());
			while (nServices--)
			{
				nRow = pArray.Grow();
				pArray(nRow,1) = pStringBuffer = pServiceStatusEx->lpServiceName;
				pArray(nRow,2) = pStringBuffer = pServiceStatusEx->lpDisplayName;
				pArray(nRow,3) = pServiceStatusEx->ServiceStatusProcess.dwServiceType;
				pArray(nRow,4) = pServiceStatusEx->ServiceStatusProcess.dwCurrentState;
				pArray(nRow,5) = pServiceStatusEx->ServiceStatusProcess.dwWin32ExitCode;
				pArray(nRow,6) = pServiceStatusEx->ServiceStatusProcess.dwServiceSpecificExitCode;
				pArray(nRow,7) = pServiceStatusEx->ServiceStatusProcess.dwCheckPoint;
				pArray(nRow,8) = pServiceStatusEx->ServiceStatusProcess.dwControlsAccepted;
				pArray(nRow,9) = pServiceStatusEx->ServiceStatusProcess.dwServiceFlags;
				pArray(nRow,10) = pServiceStatusEx->ServiceStatusProcess.dwProcessId;
				pServiceStatusEx++;
			}
			
			if (nLastError == ERROR_MORE_DATA)
			{
				if (dwBytes < SERVICE_ENUM_BUFFER)
					continue;

				dwBytes = max(dwBytes, SERVICE_MAX_ENUM_BUFFER);
				pBuffer.Size(dwBytes);
			}
			else
				break;
		}
	}
	else if (fpEnumServicesStatus)
	{
		while (1)
		{
			pServiceStatus = reinterpret_cast<LPENUM_SERVICE_STATUS>(pBuffer.Address());

			if (!fpEnumServicesStatus(hSCM, dwType, dwState, pServiceStatus, dwBytes, &dwBytes, &nServices, &hResume))
				nLastError = GetLastError();
			else
				nLastError = ERROR_SUCCESS;

			if (nLastError != ERROR_SUCCESS && nLastError != ERROR_MORE_DATA)
			{
				SAVEWIN32ERROR(EnumServicesStatus,nLastError);
				throw E_APIERROR;
			}

			while (nServices--)
			{
				nRow = pArray.Grow();
				pArray(nRow,1) = pStringBuffer = pServiceStatus->lpServiceName;
				pArray(nRow,2) = pStringBuffer = pServiceStatus->lpDisplayName;
				pArray(nRow,3) = pServiceStatus->ServiceStatus.dwServiceType;
				pArray(nRow,4) = pServiceStatus->ServiceStatus.dwCurrentState;
				pArray(nRow,5) = pServiceStatus->ServiceStatus.dwWin32ExitCode;
				pArray(nRow,6) = pServiceStatus->ServiceStatus.dwServiceSpecificExitCode;
				pArray(nRow,7) = pServiceStatus->ServiceStatus.dwCheckPoint;
				pArray(nRow,8) = pServiceStatus->ServiceStatus.dwControlsAccepted;
				pArray(nRow,9) = 0;
				pArray(nRow,10) = 0;
				pServiceStatus++;
			}

			if (nLastError == ERROR_MORE_DATA)
			{
				if (dwBytes < SERVICE_ENUM_BUFFER)
					continue;

				dwBytes = max(dwBytes,SERVICE_MAX_ENUM_BUFFER);
				pBuffer.Size(dwBytes);
			}
			else
				break;
		}
	}
	else
		throw E_NOENTRYPOINT;

	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall AServiceStatus(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpOpenSCManager)
		throw E_NOENTRYPOINT;

	FoxArray pArray(p1,7,1);
	FoxString pServiceName(parm,2);
	FoxString pMachine(parm,3);
	FoxString pDatabase(parm,4);
	ServiceManager hSCM;
	Service hService;
	SERVICE_STATUS sStatus;

	if (Vartype(p2) == 'I' || Vartype(p2) == 'N')
	{
		if (PCOUNT() > 2)
			throw E_INVALIDPARAMS;
		hService.Attach(p2);
	}
	else if (Vartype(p2) == 'C')
	{
		hSCM.Open(pMachine,pDatabase);
		hService.Open(hSCM,pServiceName,SERVICE_START|SERVICE_QUERY_STATUS);
	}
	else
		throw E_INVALIDPARAMS;

	hService.QueryStatus(&sStatus);

	pArray(1) = sStatus.dwCheckPoint;
	pArray(2) = sStatus.dwControlsAccepted;
	pArray(3) = sStatus.dwCurrentState;
	pArray(4) = sStatus.dwServiceSpecificExitCode;
	pArray(5) = sStatus.dwServiceType;
	pArray(6) = sStatus.dwWaitHint;
	pArray(7) = sStatus.dwWin32ExitCode;

	Return(1);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall AServiceConfig(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpOpenSCManager)
		throw E_NOENTRYPOINT;

	FoxArray pArray(p1,9,1);
	FoxString pServiceName(parm,2);
	FoxString pMachine(parm,3);
	FoxString pDatabase(parm,4);
	FoxString pStringBuffer(4096);
	ServiceManager hSCM;
	Service hService;
	CBuffer pBuffer;
	LPQUERY_SERVICE_CONFIG pServiceConfig;

	if (Vartype(p2) == 'I' || Vartype(p2) == 'N')
	{
		if (PCOUNT() > 2)
			throw E_INVALIDPARAMS;
		hService.Attach(p2);
	}
	else if (Vartype(p2) == 'C')
	{
		hSCM.Open(pMachine,pDatabase);
		hService.Open(hSCM,pServiceName,SERVICE_START|SERVICE_QUERY_STATUS);
	}
	else
		throw E_INVALIDPARAMS;

	hService.QueryConfig(pBuffer);

	pServiceConfig = (LPQUERY_SERVICE_CONFIG)pBuffer.Address();

	pArray(1) = pServiceConfig->dwServiceType;
	pArray(2) = pServiceConfig->dwStartType;
	pArray(3) = pServiceConfig->dwErrorControl;
	pArray(4) = pStringBuffer = pServiceConfig->lpBinaryPathName;
	pArray(5) = pStringBuffer = pServiceConfig->lpLoadOrderGroup;
	pArray(6) = pServiceConfig->dwTagId;

	pArray(7) = pStringBuffer.CopyDblString(pServiceConfig->lpDependencies);
	pArray(8) = pStringBuffer = pServiceConfig->lpServiceStartName;
	pArray(9) = pStringBuffer = pServiceConfig->lpDisplayName;

	Return(1);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall ADependentServices(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpOpenSCManager)
		throw E_NOENTRYPOINT;

	FoxArray pArray(p1,1,8);
	FoxString pServiceName(parm,2);
	FoxString pMachine(parm,3);
	FoxString pDatabase(parm,4);
	FoxString pStringBuffer(MAX_PATH+1);

	ServiceManager hSCM;
	Service hService;

	CBuffer pBuffer;
	LPENUM_SERVICE_STATUS pServiceStatus;
	DWORD dwBytesNeeded = 0, dwServiceCount = 0, nLastError;
	unsigned int nRow;

	if (Vartype(p2) == 'I' || Vartype(p2) == 'N')
	{
		if (PCOUNT() > 2)
			throw E_INVALIDPARAMS;
		hService.Attach(p2);
	}
	else if (Vartype(p2) == 'C')
	{
		hSCM.Open(pMachine,pDatabase);
		hService.Open(hSCM,pServiceName,SERVICE_START|SERVICE_QUERY_STATUS);
	}
	else
		throw E_INVALIDPARAMS;

	if (!fpEnumDependentServices(hService, SERVICE_STATE_ALL, 0, 0, &dwBytesNeeded, &dwServiceCount))
	{
		nLastError = GetLastError();
		if (nLastError != ERROR_MORE_DATA)
		{
			SAVEWIN32ERROR(EnumDependentServices, nLastError);
			throw E_APIERROR;
		}
	}
	else if (dwServiceCount == 0)
	{
		Return(0);
		return;
	}

	pBuffer.Size(dwBytesNeeded);
	pServiceStatus = reinterpret_cast<LPENUM_SERVICE_STATUS>(pBuffer.Address());

	if (!fpEnumDependentServices(hService, SERVICE_STATE_ALL, pServiceStatus, pBuffer.Size(), &dwBytesNeeded, &dwServiceCount))
	{
		SAVEWIN32ERROR(EnumDependentServices, nLastError);
		throw E_APIERROR;
	}
    
	pArray.Dimension(dwServiceCount, 8);
	while (dwServiceCount--)
	{
		nRow = pArray.Grow();
		pArray(nRow,1) = pStringBuffer = pServiceStatus->lpServiceName;
		pArray(nRow,2) = pStringBuffer = pServiceStatus->lpDisplayName;
		pArray(nRow,3) = pServiceStatus->ServiceStatus.dwServiceType;
		pArray(nRow,4) = pServiceStatus->ServiceStatus.dwCurrentState;
		pArray(nRow,5) = pServiceStatus->ServiceStatus.dwWin32ExitCode;
		pArray(nRow,6) = pServiceStatus->ServiceStatus.dwServiceSpecificExitCode;
		pArray(nRow,7) = pServiceStatus->ServiceStatus.dwCheckPoint;
		pArray(nRow,8) = pServiceStatus->ServiceStatus.dwControlsAccepted;
		pServiceStatus++;
	}

	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall WaitForServiceStatus(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpOpenSCManager)
		throw E_NOENTRYPOINT;

	FoxString pServiceName(parm,1);
	FoxString pMachine(parm,4);
	FoxString pDatabase(parm,5);

	ServiceManager hSCM;
	Service hService;
	int nTimeout;

	if (Vartype(p1) == 'I' || Vartype(p1) == 'N')
	{
		hService.Attach(p1);
	}
	else if (Vartype(p1) == 'C')
	{
		hSCM.Open(pMachine, pDatabase);
		hService.Open(hSCM, pServiceName, SERVICE_QUERY_STATUS);
	}
	else
		throw E_INVALIDPARAMS;

	nTimeout = PCOUNT() < 3 ? SERVICE_INFINITE_TIMEOUT : p3.ev_long;
	
	Return(hService.WaitForServiceStatus(p2.ev_long, nTimeout));
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}
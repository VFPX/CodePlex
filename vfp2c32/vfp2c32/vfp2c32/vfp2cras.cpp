#include <windows.h>

#include "pro_ext.h" // general FoxPro library header
#include "vfp2c32.h"
#include "vfp2cutil.h"
#include "vfp2cras.h"
#include "vfpmacros.h"
#include "vfp2ccppapi.h"

static HMODULE hRasApi32 = 0;
static HMODULE hRasDlg = 0;

static PRASGETERRORSTRING fpRasGetErrorString = 0;
static PRASENUMCONNECTIONS fpRasEnumConnections = 0;
static PRASGETPROJECTIONINFO fpRasGetProjectionInfo = 0;
static PRASENUMENTRIES fpRasEnumEntries = 0;
static PRASENUMDEVICES fpRasEnumDevices = 0;
static PRASPHONEBOOKDLG fpRasPhonebookDlg = 0;
static PRASDIAL fpRasDial = 0;
static PRASHANGUP fpRasHangUp = 0;
static PRASGETENTRYDIALPARAMS fpRasGetEntryDialParams = 0;
static PRASGETEAPUSERIDENTITY fpRasGetEapUserIdentity = 0;
static PRASFREEEAPUSERIDENTITY fpRasFreeEapUserIdentity = 0;

static PRASCONNECTIONNOTIFICATION fpRasConnectionNotification = 0;
static PRASGETCONNECTSTATUS fpRasGetConnectStatus = 0;
static PRASDIALDLG fpRasDialDlg = 0;
static PRASCLEARCONNECTIONSTATISTICS fpRasClearConnectionStatistics = 0;

static RasDialCallback goRasDialCallback;

// RAS error handler
void _stdcall Ras32ErrorHandler(char *pFunction, DWORD nErrorNo)
{
	if (gnErrorCount == VFP2C_MAX_ERRORS)
		return;
	gnErrorCount++;

	gaErrorInfo[gnErrorCount].nErrorType = VFP2C_ERRORTYPE_WIN32;
	gaErrorInfo[gnErrorCount].nErrorNo = nErrorNo;
	strncpy(gaErrorInfo[gnErrorCount].aErrorFunction,pFunction,VFP2C_ERROR_FUNCTION_LEN);
	fpRasGetErrorString(nErrorNo,gaErrorInfo[gnErrorCount].aErrorMessage,VFP2C_ERROR_MESSAGE_LEN);
}

// initialisation 
bool _stdcall VFP2C_Init_Ras()
{
	hRasApi32 = LoadLibrary("rasapi32.dll");
	if (hRasApi32)
	{
		fpRasGetErrorString = (PRASGETERRORSTRING)GetProcAddress(hRasApi32,"RasGetErrorStringA");
		fpRasEnumConnections = (PRASENUMCONNECTIONS)GetProcAddress(hRasApi32,"RasEnumConnectionsA");
		fpRasGetProjectionInfo = (PRASGETPROJECTIONINFO)GetProcAddress(hRasApi32,"RasGetProjectionInfoA");
		fpRasEnumDevices = (PRASENUMDEVICES)GetProcAddress(hRasApi32,"RasEnumDevicesA");
		fpRasEnumEntries = (PRASENUMENTRIES)GetProcAddress(hRasApi32,"RasEnumEntriesA");
		fpRasDial = (PRASDIAL)GetProcAddress(hRasApi32,"RasDialA");
		fpRasHangUp = (PRASHANGUP)GetProcAddress(hRasApi32,"RasHangUp");
		fpRasGetEntryDialParams = (PRASGETENTRYDIALPARAMS)GetProcAddress(hRasApi32,"RasGetEntryDialParamsA");
		fpRasGetEapUserIdentity = (PRASGETEAPUSERIDENTITY)GetProcAddress(hRasApi32,"RasGetEapUserIdentityA");
		fpRasFreeEapUserIdentity = (PRASFREEEAPUSERIDENTITY)GetProcAddress(hRasApi32,"RasFreeEapUserIdentityA");
		fpRasConnectionNotification = (PRASCONNECTIONNOTIFICATION)GetProcAddress(hRasApi32,"RasConnectionNotificationA");
		fpRasGetConnectStatus = (PRASGETCONNECTSTATUS)GetProcAddress(hRasApi32,"RasGetConnectStatusA");
		fpRasDialDlg = (PRASDIALDLG)GetProcAddress(hRasApi32,"RasDialDlgA");
		fpRasClearConnectionStatistics = (PRASCLEARCONNECTIONSTATISTICS)
			GetProcAddress(hRasApi32,"RasClearConnectionStatistics");
	}

	hRasDlg = LoadLibrary("rasdlg.dll");
	if (hRasDlg)
		fpRasPhonebookDlg = (PRASPHONEBOOKDLG)GetProcAddress(hRasDlg,"RasPhonebookDlgA");

	return true;
}

// cleanup
void _stdcall VFP2C_Destroy_Ras()
{
	if (hRasApi32)
		FreeLibrary(hRasApi32);
	if (hRasDlg)
		FreeLibrary(hRasDlg);
}

// enumerate active dialup connections into an array
void _fastcall ARasConnections(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpRasEnumConnections || !fpRasGetProjectionInfo)
		throw E_NOENTRYPOINT;

	FoxArray pArray(p1);
	FoxString pEntry(RAS_MaxEntryName);
	RASCONN *lpRas;
	RASPPPIP sRasIp;
	DWORD dwBytes = sizeof(RASCONN) * 32;
	DWORD dwConns, nApiRet;

	CBuffer pBuffer(dwBytes);
	lpRas = reinterpret_cast<LPRASCONN>(pBuffer.Address());
	lpRas->dwSize = sizeof(RASCONN);

	nApiRet = fpRasEnumConnections(lpRas, &dwBytes, &dwConns);
	if (nApiRet == ERROR_SUCCESS)
	{
		if (dwConns == 0)
		{
			Return(0);
			return;
		}

		pArray.Dimension(dwConns, 5);

		for (unsigned int xj = 1; xj <= dwConns; xj++)
		{
			pArray(xj,1) = pEntry = lpRas->szEntryName;
			pArray(xj,2) = pEntry = lpRas->szDeviceName;
			pArray(xj,3) = pEntry = lpRas->szDeviceType;			

			sRasIp.dwSize = sizeof(DWORD) + sizeof(DWORD) + RAS_MaxIpAddress + 1;
			dwBytes = sizeof(RASPPPIP);
			nApiRet = fpRasGetProjectionInfo(lpRas->hrasconn,RASP_PppIp,&sRasIp,&dwBytes);
			if (nApiRet != ERROR_SUCCESS)
			{
				SAVERAS32ERROR(RasGetProjectionInfo,nApiRet);
				throw E_APIERROR;
			}
			pArray(xj,4) = pEntry = sRasIp.szIpAddress;
			pArray(xj,5) = reinterpret_cast<int>(lpRas->hrasconn);
			lpRas++;
		}
	}
	else
	{
		if (nApiRet == ERROR_NOT_ENOUGH_MEMORY)
			SAVEWIN32ERROR(RasEnumConnections,nApiRet);
		else
			SAVERAS32ERROR(RasEnumConnections,nApiRet);
		
		throw E_APIERROR;
	}

	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall ARasDevices(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpRasEnumDevices)
		throw E_NOENTRYPOINT;

	FoxArray pArray(p1);
	FoxString pEntry(RAS_MaxDeviceName+1);

	DWORD dwSize = 1024, dwEntries, nApiRet;
	CBuffer pBuffer(dwSize);
	LPRASDEVINFO lpRasDev = reinterpret_cast<LPRASDEVINFO>(pBuffer.Address());
	lpRasDev->dwSize = sizeof(RASDEVINFO);

	nApiRet = fpRasEnumDevices(lpRasDev,&dwSize,&dwEntries);
	if (nApiRet == ERROR_BUFFER_TOO_SMALL)
	{
		pBuffer.Size(dwSize);
		lpRasDev = reinterpret_cast<LPRASDEVINFO>(pBuffer.Address());
		lpRasDev->dwSize = sizeof(RASDEVINFO);
		nApiRet = fpRasEnumDevices(lpRasDev,&dwSize,&dwEntries);
	}

	if (nApiRet != ERROR_SUCCESS)
	{
		if (nApiRet == ERROR_NOT_ENOUGH_MEMORY)
			SAVEWIN32ERROR(RasEnumDevices,nApiRet);
		else
			SAVERAS32ERROR(RasEnumDevices,nApiRet);

		throw E_APIERROR;
	}

	if (dwEntries == 0)
	{
		Return(0);
		return;
	}

	pArray.Dimension(dwEntries,2);
	for (unsigned int xj = 1; xj <= dwEntries; xj++)
	{
		pArray(xj,1) = pEntry = lpRasDev->szDeviceType;
		pArray(xj,2) = pEntry = lpRasDev->szDeviceName;
		lpRasDev++;
	}

	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}


void _fastcall ARasPhonebookEntries(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpRasEnumEntries)
		throw E_NOENTRYPOINT;

	FoxArray pArray(p1);
	FoxString pPhonebookFile(parm,2);
	FoxString pEntryName(RAS_MaxEntryName+1);

	DWORD dwSize = 2048, dwEntries, nApiRet;
	CBuffer pBuffer(dwSize);
	LPRASENTRYNAME lpRasEntry = (LPRASENTRYNAME)pBuffer.Address();
	lpRasEntry->dwSize = sizeof(RASENTRYNAME);

	nApiRet = fpRasEnumEntries(0,pPhonebookFile,lpRasEntry,&dwSize,&dwEntries);
	if (nApiRet == ERROR_BUFFER_TOO_SMALL)
	{
		pBuffer.Size(dwSize);
		lpRasEntry = (LPRASENTRYNAME)pBuffer.Address();
		lpRasEntry->dwSize = sizeof(RASENTRYNAME);
		nApiRet = fpRasEnumEntries(0,pPhonebookFile,lpRasEntry,&dwSize,&dwEntries);
	}

	if (nApiRet != ERROR_SUCCESS)
	{
		if (nApiRet == ERROR_NOT_ENOUGH_MEMORY)
			SAVEWIN32ERROR(RasEnumEntries,nApiRet);
		else
			SAVERAS32ERROR(RasEnumEntries,nApiRet);

		throw E_APIERROR;
	}

	if (dwEntries == 0)
	{
		Return(0);
		return;
	}

	pArray.Dimension(dwEntries,2);
	for (unsigned int xj = 0; xj < dwEntries; xj++)
	{
		pArray(xj,1) = pEntryName = lpRasEntry->szEntryName;
		if (IS_WIN9X())
			pArray(xj,2) = 0;
		else
            pArray(xj,2) = lpRasEntry->dwFlags;
		
		lpRasEntry++;
	}

	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

// implementation of RasDlgCallback - for callbacks from the RasDlgPhonebook function
// SetCallback to setup the callback function
void RasPhonebookDlgCallback::SetCallback(char *pCallback)
{
	// setup two format strings - one for callback reasons with and one without a valid text parameter
	m_Callback = pCallback;
	m_Callback += "(%I,'',%I)";
	m_CallbackTxt = pCallback;
	m_CallbackTxt += "(%I,ReadCString(%I),0)";
	// setup buffer into which the callback command is saved
	m_Buffer.Size(VFP2C_MAX_CALLBACKBUFFER);
}

// the actual callback function
void _stdcall RasPhonebookDlgCallback::RasPhonebookDlgCallbackFunc(DWORD dwCallbackId, DWORD dwEvent,
														 LPTSTR pszText, LPVOID pData)
{
	RasPhonebookDlgCallback *pCallback = reinterpret_cast<RasPhonebookDlgCallback*>(dwCallbackId);
	switch(dwEvent)
	{
		case RASPBDEVENT_AddEntry:
		case RASPBDEVENT_EditEntry:
		case RASPBDEVENT_RemoveEntry:
		case RASPBDEVENT_DialEntry:
		case RASPBDEVENT_EditGlobals:
			pCallback->CallbackTxt(dwEvent,pszText);
			break;
		case RASPBDEVENT_NoUser:
		case RASPBDEVENT_NoUserEdit:
			pCallback->Callback(dwEvent,pData);
	}
}

void RasPhonebookDlgCallback::CallbackTxt(DWORD dwEvent, LPTSTR pszText)
{
	// format the command and execute it
	m_Buffer.Format(m_CallbackTxt, dwEvent, pszText);
	_Execute(m_Buffer);
}

void RasPhonebookDlgCallback::Callback(DWORD dwEvent, LPVOID pData)
{
	// format the command and execute it
	m_Buffer.Format(m_Callback, dwEvent, pData);
	_Execute(m_Buffer);
}

void _fastcall RasPhonebookDlgEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpRasPhonebookDlg)
		throw E_NOENTRYPOINT;

	FoxString pEntry(parm,1);
	FoxString pPhonebookFile(parm,2);
	FoxString pCallback(parm,3);

	if (pCallback.Len() > VFP2C_MAX_CALLBACKFUNCTION)
		throw E_INVALIDPARAMS;

	RASPBDLG sDialog = {0};
	sDialog.dwSize = sizeof(RASPBDLG);
	sDialog.hwndOwner = WTopHwnd();
	sDialog.dwFlags = PCOUNT() >= 4 ? static_cast<DWORD>(p4.ev_long) : 0;

	RasPhonebookDlgCallback sCallback;

	// if callback is used setup callback struct and set necessary RASPBDLG members
	if (pCallback.Len())
	{
		sCallback.SetCallback(pCallback);
		sDialog.pCallback = RasPhonebookDlgCallback::RasPhonebookDlgCallbackFunc;
		sDialog.dwCallbackId = reinterpret_cast<DWORD>(&sCallback);
	}

	BOOL bRetVal = fpRasPhonebookDlg(pPhonebookFile,pEntry,&sDialog);
	if (!bRetVal)
	{
		// an error occured?
		if (sDialog.dwError)
		{
			SAVERAS32ERROR(RasEnumConnections, sDialog.dwError);
			throw E_APIERROR;
		}
		Return(false); // else no connection was established
	}
	else
		Return(true); // connection established

}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void RasDialCallback::SetCallback(char *pCallback)
{
	m_Callback = pCallback;
	m_Callback += "(%U,%U,%U,%I,%U,%U)";
	m_Buffer.Size(VFP2C_MAX_CALLBACKBUFFER);
}

void RasDialCallback::Callback1(HRASCONN hrasconn, UINT unMsg, RASCONNSTATE rascs,
													DWORD dwError, DWORD dwExtendedError)
{
	m_Buffer.Format(m_Callback, 0, hrasconn, unMsg, rascs, dwError, dwExtendedError);
	_Execute(m_Buffer);
}

DWORD RasDialCallback::Callback2(DWORD dwSubEntry, HRASCONN hrasconn,
								UINT unMsg,	RASCONNSTATE rascs, DWORD dwError, DWORD dwExtendedError)
{
	Value vRetVal;
	vRetVal.ev_type = '0';
	m_Buffer.Format(m_Callback, dwSubEntry, hrasconn, unMsg, rascs, dwError, dwExtendedError);
	if (_Evaluate(&vRetVal,m_Buffer) == 0)
	{
		if (Vartype(vRetVal) == 'I')
			return vRetVal.ev_long;
		else if (Vartype(vRetVal) == 'N')
			return (DWORD)vRetVal.ev_real;
		else if (Vartype(vRetVal) == 'L')
			return vRetVal.ev_length;
		else
			ReleaseValue(vRetVal);
	}
	return 1;
}

void _stdcall RasDialCallback::RasDialCallbackFunc1(HRASCONN hrasconn, UINT unMsg, RASCONNSTATE rascs,
													DWORD dwError, DWORD dwExtendedError)
{
	if (dwError)
		fpRasHangUp(hrasconn);

	goRasDialCallback.Callback1(hrasconn,unMsg,rascs,dwError,dwExtendedError);
}

DWORD _stdcall RasDialCallback::RasDialCallbackFunc2(DWORD dwCallbackId, DWORD dwSubEntry, HRASCONN hrasconn,
										UINT unMsg,	RASCONNSTATE rascs, DWORD dwError, DWORD dwExtendedError)
{

	RasDialCallback *pCall = reinterpret_cast<RasDialCallback*>(dwCallbackId);
	DWORD dwRet = pCall->Callback2(dwSubEntry,hrasconn,unMsg,rascs,dwError,dwExtendedError);
	
	if (dwError)
		fpRasHangUp(hrasconn);

	if (dwRet == 0 || unMsg == RASCS_Connected)
		delete pCall;

	return dwRet;
}

void _fastcall RasDialEx(ParamBlk *parm)
{
	RASEAPUSERIDENTITY *pUserIdentity = 0;
try
{
	RESETWIN32ERRORS();

	if (!fpRasDial || !fpRasGetEntryDialParams)
		throw E_NOENTRYPOINT;

	// parameter validation
	if (Vartype(p1) != 'C' && Vartype(p1) != 'N')
		throw E_INVALIDPARAMS;
	if (Vartype(p2) != 'C' && Vartype(p2) != '0')
		throw E_INVALIDPARAMS;
	if (Vartype(p3) != 'C' && Vartype(p3) != '0')
		throw E_INVALIDPARAMS;

	FoxString pEntry(parm,1);
	FoxString pPhonebookFile(parm,2);
	FoxString pCallback(parm,3);
	HRASCONN hConn = PCOUNT() >= 5 ? reinterpret_cast<HRASCONN>(p5.ev_long) : 0;

	if (pCallback.Len() > VFP2C_MAX_CALLBACKFUNCTION)
		throw E_INVALIDPARAMS;

	// local variables
	DWORD nApiRet;

	char *pPhonebook = 0;
	if (!IS_WIN95())
		pPhonebook = pPhonebookFile;

	RASDIALPARAMS sDialParams = {0};
	sDialParams.dwSize = sizeof(RASDIALPARAMS);
	LPRASDIALPARAMS pDialParamsPtr = &sDialParams;

	RASDIALEXTENSIONS sDialExtensions = {0};
	sDialExtensions.dwSize = sizeof(RASDIALEXTENSIONS);
	sDialExtensions.dwfOptions = PCOUNT() >= 4 ? static_cast<DWORD>(p4.ev_long) : 0;

	if (pEntry.Len())
	{
		// get RASDIAL parameters
		BOOL bPassword;
		nApiRet = fpRasGetEntryDialParams(pEntry,&sDialParams,&bPassword);
		if (nApiRet != ERROR_SUCCESS)
		{
			SAVERAS32ERROR(RasGetEntryDialParams,nApiRet);
			throw E_APIERROR;
		}

		if (fpRasGetEapUserIdentity && fpRasFreeEapUserIdentity)
		{
			nApiRet = fpRasGetEapUserIdentity(pPhonebook,pEntry,0,0,&pUserIdentity);
			if (nApiRet == ERROR_SUCCESS)
			{
				strcpy(sDialParams.szUserName,pUserIdentity->szUserName);
				sDialExtensions.RasEapInfo.dwSizeofEapInfo = pUserIdentity->dwSizeofEapInfo;
				sDialExtensions.RasEapInfo.pbEapInfo = pUserIdentity->pbEapInfo;
				fpRasFreeEapUserIdentity(pUserIdentity);
			}
			else if (nApiRet == ERROR_INVALID_FUNCTION_FOR_ENTRY);
			else
			{
				SAVERAS32ERROR(RasGetEapUserIdentity,nApiRet);
				throw E_APIERROR;
			}
		}
	}
	else
		pDialParamsPtr = (LPRASDIALPARAMS)p1.ev_long;

	// setup callback parameters
	DWORD dwNotifier = 0; LPVOID lpNotifier = 0;
	if (pCallback.Len())
	{
		if (IS_WIN9X())
		{
			dwNotifier = 1;
			lpNotifier = reinterpret_cast<LPVOID>(RasDialCallback::RasDialCallbackFunc1);
			goRasDialCallback.SetCallback(pCallback);
		}
		else
		{
			dwNotifier = 2;
			lpNotifier = reinterpret_cast<LPVOID>(RasDialCallback::RasDialCallbackFunc2);
            
			RasDialCallback *pRasCallback = new RasDialCallback;
			if (!pRasCallback)
				throw E_INSUFMEMORY;
			
			try
			{
				pRasCallback->SetCallback(pCallback);
				pDialParamsPtr->dwCallbackId = reinterpret_cast<DWORD>(pRasCallback);
			}
			catch(int nErrorNo)
			{
				delete pRasCallback;
				throw nErrorNo;
			}
		}
	}

	nApiRet = fpRasDial(&sDialExtensions,pPhonebook,&sDialParams,dwNotifier,lpNotifier,&hConn);
	if (nApiRet != ERROR_SUCCESS)
	{
		SAVERAS32ERROR(RasDial,nApiRet);
		
		// call RasHangUp to cleanup the RAS handle
		if (hConn && !pCallback.Len())
		{
			RASCONNSTATUS sStatus;
			sStatus.dwSize = sizeof(RASCONNSTATUS);
			nApiRet = fpRasGetConnectStatus(hConn,&sStatus);
			if (nApiRet != ERROR_INVALID_HANDLE)
			{
				fpRasHangUp(hConn);
			
				while(true)
				{
					Sleep(50);
					nApiRet = fpRasGetConnectStatus(hConn,&sStatus);
					if (nApiRet == ERROR_INVALID_HANDLE)
						break;
					else if (nApiRet == ERROR_SUCCESS);
					else
						break;
				}
			}
		}
		throw E_APIERROR;
	}

	if (pUserIdentity)
		fpRasFreeEapUserIdentity(pUserIdentity);

	Return(hConn);
}
catch(int nErrorNo)
{
	if (pUserIdentity)
		fpRasFreeEapUserIdentity(pUserIdentity);

	RaiseError(nErrorNo);
}
}

void _fastcall RasDialDlgEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpRasDialDlg)
		throw E_NOENTRYPOINT;

	FoxString pPhonebook(parm,1);
	FoxString pEntry(parm,2);
	FoxString pPhonenumber(parm,3);

	RASDIALDLG sDialog = {0};
	sDialog.dwSize = sizeof(RASDIALDLG);

	BOOL bRetVal = fpRasDialDlg(pPhonebook,pEntry,pPhonenumber,&sDialog);
	if (!bRetVal)
	{
		if (sDialog.dwError)
		{
			SAVERAS32ERROR(RasDialDlg, sDialog.dwError);
			throw E_APIERROR;
		}
		Return(false);
	}
	else
		Return(true);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall RasHangUpEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpRasHangUp || !fpRasGetConnectStatus)
		throw E_NOENTRYPOINT;

	HRASCONN hConn = reinterpret_cast<HRASCONN>(p1.ev_long);
	
	DWORD nApiRet = fpRasHangUp(hConn);
	if (nApiRet != ERROR_SUCCESS)
	{
		SAVERAS32ERROR(RasHangUp,nApiRet);
		throw E_APIERROR;
	}

	RASCONNSTATUS sStatus;
	sStatus.dwSize = sizeof(RASCONNSTATUS);
	while(true)
	{
        nApiRet = fpRasGetConnectStatus(hConn,&sStatus);
		if (nApiRet == ERROR_INVALID_HANDLE)
			break;
		else if (nApiRet != ERROR_SUCCESS)
		{
			if (nApiRet == ERROR_BUFFER_TOO_SMALL || nApiRet == ERROR_NOT_ENOUGH_MEMORY)
				SAVEWIN32ERROR(RasGetConnectStatus,nApiRet);
			else
		    	SAVERAS32ERROR(RasGetConnectStatus,nApiRet);
			throw E_APIERROR;
		}
		else
			Sleep(50);
	}
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall RasGetConnectStatusEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpRasGetConnectStatus)
		throw E_NOENTRYPOINT;

	HRASCONN hConn = reinterpret_cast<HRASCONN>(p1.ev_long);
	FoxArray pArray(p2,5,1);

	FoxString pValue(RAS_MaxPhoneNumber+1);
	RASCONNSTATUS sStatus = {0};
	sStatus.dwSize = sizeof(RASCONNSTATUS);

	DWORD nApiRet = fpRasGetConnectStatus(hConn,&sStatus);
	if (nApiRet != ERROR_SUCCESS)
	{
		if (nApiRet == ERROR_BUFFER_TOO_SMALL || nApiRet == ERROR_NOT_ENOUGH_MEMORY)
			SAVEWIN32ERROR(RasGetConnectStatus,nApiRet);
		else
        	SAVERAS32ERROR(RasGetConnectStatus,nApiRet);
		throw E_APIERROR;
	}

	pArray(1) = (int)sStatus.rasconnstate;
	pArray(2) = sStatus.dwError;
	pArray(3) = pValue = sStatus.szDeviceType;
	pArray(4) = pValue = sStatus.szDeviceName;
	pArray(5) = pValue = sStatus.szPhoneNumber;

}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void RasNotifyThread::SignalThreadAbort()
{
	m_AbortEvent.Signal();
}

bool RasNotifyThread::Setup(HRASCONN hConn, DWORD dwFlags, char *pCallback)
{
	m_Conn = hConn;
	m_Flags = dwFlags;
	m_Callback = pCallback;
	m_Callback += "(%I,%I)";
	m_Buffer.Size(VFP2C_MAX_CALLBACKBUFFER);

	if (!m_RasEvent.Create(false))
		return false;

	if (!m_AbortEvent.Create())
		return false;

	return true;
}

DWORD RasNotifyThread::Run()
{
	DWORD nApiRet;
	char *pCommand;

	HANDLE hEvents[2];
	hEvents[0] = m_RasEvent;
	hEvents[1] = m_AbortEvent;

	while (true)
	{
		nApiRet = fpRasConnectionNotification(m_Conn, m_RasEvent, m_Flags);
		if (nApiRet)
		{
			m_Buffer.Format(m_Callback, m_Conn, nApiRet);
			pCommand = m_Buffer.Strdup();
			if (pCommand)
				PostMessage(ghAsyncHwnd, WM_CALLBACK, reinterpret_cast<WPARAM>(pCommand), 0);
			return 0;
		}

        nApiRet = WaitForMultipleObjects(2, hEvents, FALSE, INFINITE);
		switch(nApiRet)
		{
			case WAIT_OBJECT_0:
				m_Buffer.Format(m_Callback, m_Conn, 0);
				pCommand = m_Buffer.Strdup();
				if (pCommand)
					PostMessage(ghAsyncHwnd, WM_CALLBACK, reinterpret_cast<WPARAM>(pCommand), 0);
				if (m_Conn != INVALID_HANDLE_VALUE)
					return 0;
				else
					break;
			
			case WAIT_OBJECT_0 + 1:
				return 0;
			
			default:
				m_Buffer.Format(m_Callback, m_Conn, nApiRet);
				char *pCommand = m_Buffer.Strdup();
				if (pCommand)
					PostMessage(ghAsyncHwnd, WM_CALLBACK, reinterpret_cast<WPARAM>(pCommand), 0);
				return 0;
		}
	}
}

void _fastcall RasConnectionNotificationEx(ParamBlk *parm)
{
	RasNotifyThread *pNotifyThread = 0;
try
{
	RESETWIN32ERRORS();

	if (!fpRasConnectionNotification)
		throw E_NOENTRYPOINT;

	HRASCONN hConn = reinterpret_cast<HRASCONN>(p1.ev_long);
	DWORD dwFlags = static_cast<DWORD>(p2.ev_long);
	FoxString pCallback(p3);

	if (!goThreadManager.Initialized())
	{
		SAVECUSTOMERROR("RasConnectionNotificationEx","Library not initialized.");
		throw E_APIERROR;
	}

	if (pCallback.Len() > VFP2C_MAX_CALLBACKBUFFER || pCallback.Len() == 0)
		throw E_INVALIDPARAMS;

	RasNotifyThread *pNotifyThread = new RasNotifyThread(goThreadManager);
	if (!pNotifyThread)
		throw E_INSUFMEMORY;

	if (!pNotifyThread->Setup(hConn,dwFlags,pCallback))
		throw E_APIERROR;
	
	pNotifyThread->StartThread();
    
	Return(pNotifyThread);
}
catch(int nErrorNo)
{
	if (pNotifyThread)
		delete pNotifyThread;

	RaiseError(nErrorNo);
}
}

void _fastcall AbortRasConnectionNotificationEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!goThreadManager.Initialized())
	{
		SAVECUSTOMERROR("AbortRasConnectionNotificationEx","Library not initialized.");
		throw E_APIERROR;
	}

	CThread *pThread = reinterpret_cast<CThread*>(p1.ev_long);
	Return(goThreadManager.AbortThread(pThread));
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall RasClearConnectionStatisticsEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpRasClearConnectionStatistics)
		throw E_NOENTRYPOINT;

	HRASCONN hConn = reinterpret_cast<HRASCONN>(p1.ev_long);
	DWORD nApiRet = fpRasClearConnectionStatistics(hConn);
	if (nApiRet != ERROR_SUCCESS)
	{
		SAVEWIN32ERROR(RasClearConnectionStatistics,nApiRet);
		throw E_APIERROR;
	}
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}
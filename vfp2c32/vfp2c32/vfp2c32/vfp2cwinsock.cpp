#include <winsock2.h>

#include "pro_ext.h"
#include "vfp2c32.h"
#include "vfpmacros.h"
#include "vfp2cwinsock.h"
#include "vfp2cutil.h"
#include "vfp2ccppapi.h"

static bool gbWinsockInited = false;
DWORD gnDefaultWinsockTimeOut = 4000; // 4 seconds default timeout

void _stdcall SaveWinsockError(char *pFunction)
{
	int nError;
	nError = WSAGetLastError();
	gnErrorCount = 0;

	strcpy(gaErrorInfo[0].aErrorFunction,pFunction);
	gaErrorInfo[0].nErrorNo = nError;
	gaErrorInfo[0].nErrorType = VFP2C_ERRORTYPE_WIN32;

	switch(nError)
	{
		case WSANOTINITIALISED:
			strcpy(gaErrorInfo[0].aErrorMessage,"WSANOTINITIALIZED: Winsock library is not initialized.");
			break;
		case WSAENETDOWN:
			strcpy(gaErrorInfo[0].aErrorMessage,"WSANETDOWN: Network is down.");
			break;
		case WSAEINPROGRESS:
			strcpy(gaErrorInfo[0].aErrorMessage,"WSAINPROGRESS: Another blocking socket operation is in progress.");
			break;
		default:
			gaErrorInfo[0].aErrorMessage[0] = '\0';
	}
}

bool _stdcall VFP2C_Init_Winsock()
{
	WORD wWinsockVer;
	WSADATA wsaData;
	int nError;
 
	wWinsockVer = MAKEWORD(1,1);
 	nError = WSAStartup(wWinsockVer,&wsaData);
	if (nError != ERROR_SUCCESS)
	{
		ADDWIN32ERROR(WSAStartup,nError);
		return false;
	}
	gbWinsockInited = true;
	return true;
}

void _stdcall VFP2C_Destroy_Winsock()
{
	if (gbWinsockInited)
		WSACleanup();
}

void _fastcall AIPAddresses(ParamBlk *parm)
{
try
{
	FoxArray pArray(p1);
	FoxString pIp(VFP2C_MAX_IP_LEN);

	LPHOSTENT lpHost;
	struct in_addr sInetAdr;
	int nApiRet;
	char aHostname[MAX_PATH];
	
	nApiRet = gethostname(aHostname,MAX_PATH);
	if (nApiRet == SOCKET_ERROR)
	{
		SAVEWINSOCKERROR(gethostname);
		throw E_APIERROR;
	}

	lpHost = gethostbyname(aHostname);
	if (!lpHost)
	{
		SAVEWINSOCKERROR(gethostbyname);
		throw E_APIERROR;
	}

	// count number of valid IP's
	unsigned int nCount;
	for (nCount = 0; (lpHost->h_addr_list[nCount]); nCount++);

	if (nCount == 0)
	{
		Return(0);
		return;
	}

	pArray.Dimension(nCount);

	unsigned int nRow = 1;
	for (unsigned int xj = 0; xj < nCount; xj++)
	{
		memcpy(&sInetAdr,lpHost->h_addr_list[xj],sizeof(int)); 
		pArray(nRow++) = pIp = inet_ntoa(sInetAdr);
	}

	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall ResolveHostToIp(ParamBlk *parm)
{
try
{
	FoxString pIp(p1);
	FoxArray pArray;
	FoxString pBuffer(VFP2C_MAX_IP_LEN);
	LPHOSTENT lpHost = 0;
	struct in_addr sInetAdr;

	lpHost = gethostbyname(pIp);
	// host not found?
	if (!lpHost)
	{
		SAVEWINSOCKERROR(gethostbyname);
		if (PCOUNT() == 1)
			Return("");
		else
			Return(0);
		return;
	}

	if (PCOUNT() == 1)
	{
		memcpy(&sInetAdr,lpHost->h_addr_list[0],4); 
		pBuffer = inet_ntoa(sInetAdr);
		pBuffer.Return();
	}
	else
	{
		unsigned int nCount;
		for (nCount = 0; (lpHost->h_addr_list[nCount]); nCount++);

		pArray.Dimension(p2,nCount);

		unsigned int nRow = 1;
		for (unsigned int xj = 0; xj < nCount; xj++)
		{
			memcpy(&sInetAdr,lpHost->h_addr_list[xj],sizeof(int)); 
			pArray(nRow++) = pBuffer = inet_ntoa(sInetAdr);
		}
		pArray.ReturnRows();
	}
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

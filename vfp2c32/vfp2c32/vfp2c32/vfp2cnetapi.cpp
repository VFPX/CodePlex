#include <windows.h>

#include "pro_ext.h"
#include "vfp2c32.h"
#include "vfp2cutil.h"
#include "vfp2cnetapi.h"
#include "vfp2cnetapiex.h"
#include "vfpmacros.h"
#include "vfp2ccppapi.h"

static HMODULE hNetApi32 = 0;

static PNETAPIBUFFERALLOCATE fpNetApiBufferAllocate = 0;
static PNETAPIBUFFERFREE fpNetApiBufferFree = 0;
static PNETAPIBUFFERREALLOCATE fpNetApiBufferReallocate = 0;
static PNETAPIBUFFERSIZE fpNetApiBufferSize = 0;
static PNETFILEENUM fpNetFileEnum = 0;
static PNETREMOTETOD fpNetRemoteTOD = 0;
static PNETSERVERENUM fpNetServerEnum = 0;

NetApiBuffer::~NetApiBuffer()
{
	if (m_Buffer)
		fpNetApiBufferFree(m_Buffer);
}

bool _stdcall VFP2C_Init_Netapi()
{
	HMODULE hDll;

	hDll = GetModuleHandle("netapi32.dll");
	if (!hDll)
	{
		hDll = LoadLibrary("netapi32.dll");
		if (!hDll)
		{
			ADDWIN32ERROR(LoadLibrary,GetLastError());
			return false;			
		}
		hNetApi32 = hDll;
	}

	fpNetApiBufferAllocate = (PNETAPIBUFFERALLOCATE)GetProcAddress(hDll,"NetApiBufferAllocate");
	fpNetApiBufferFree = (PNETAPIBUFFERFREE)GetProcAddress(hDll,"NetApiBufferFree");
	fpNetApiBufferReallocate = (PNETAPIBUFFERREALLOCATE)GetProcAddress(hDll,"NetApiBufferReallocate");
	fpNetApiBufferSize = (PNETAPIBUFFERSIZE)GetProcAddress(hDll,"NetApiBufferSize");
	fpNetRemoteTOD = (PNETREMOTETOD)GetProcAddress(hDll,"NetRemoteTOD");
	fpNetFileEnum = (PNETFILEENUM)GetProcAddress(hDll,"NetFileEnum");
	fpNetServerEnum = (PNETSERVERENUM)GetProcAddress(hDll,"NetServerEnum");

	return true;
}

void _stdcall VFP2C_Destroy_Netapi()
{
	if (hNetApi32)
		FreeLibrary(hNetApi32);
}

void _fastcall ANetFiles(ParamBlk *parm)
{
	RESETWIN32ERRORS();
	if (IS_WIN9X())
	{
		ANetFilesEx(parm);
		return;
	}
try
{
	// entry point valid?
	if (!fpNetFileEnum)
		throw E_NOENTRYPOINT;

	FoxArray pArray(p1,1,5);
	FoxWString pServerName(parm,2);
	FoxWString pBasePath(parm,3);
	FoxWString pUserName(parm,4);
	FoxString pNetInfo(NETAPI_INFO_SIZE);
	NetApiBuffer pBuffer;

	DWORD nRow = 1, hResume = 0, dwTotal = 0, dwEntries = 0, dwRows = 0;
	LPFILE_INFO_3 pFileInfo3;
	NET_API_STATUS nApiRet;

	do 
	{
		nApiRet = fpNetFileEnum(pServerName,pBasePath,pUserName,3,
			pBuffer,NETAPI_BUFFER_SIZE,&dwEntries,&dwTotal,&hResume);
		
		if (nApiRet == NERR_Success || nApiRet == ERROR_MORE_DATA)
		{
			if (dwEntries == 0)
			{
				Return((int)dwRows);
				return;
			}

			dwRows += dwEntries;
			pArray.ReDimension(dwRows,5);
			pFileInfo3 = (LPFILE_INFO_3)(LPBYTE)pBuffer;

			while (dwEntries--)
			{
				pArray(nRow,1) = pNetInfo = pFileInfo3->fi3_pathname;
				pArray(nRow,2) = pNetInfo = pFileInfo3->fi3_username;
				pArray(nRow,3) = (int)pFileInfo3->fi3_id;		
				pArray(nRow,4) = (int)pFileInfo3->fi3_permissions;
				pArray(nRow,5) = (int)pFileInfo3->fi3_num_locks;
				pFileInfo3++;
				nRow++;
			}
		}
		else
		{
			SAVEWIN32ERROR(NetFileEnum,nApiRet);
			throw E_APIERROR;
		}
	} while (nApiRet == ERROR_MORE_DATA);

	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall ANetServers(ParamBlk *parm)
{

try
{
	RESETWIN32ERRORS();

	if (!fpNetServerEnum)
		throw E_NOENTRYPOINT;

	FoxArray pArray(p1);
	DWORD dwServerType = PCOUNT() >= 2 && p2.ev_long ? (DWORD)p2.ev_long : SV_TYPE_SERVER;
	DWORD dwLevel;
	FoxWString pDomain(parm,4);

	NetApiBuffer pBuffer;
	FoxString pData(NETAPI_INFO_SIZE);

	DWORD nRow = 1, hResume = 0, dwTotal = 0, dwEntries = 0, dwRows = 0;	
    NET_API_STATUS nApiRet;
	LPSERVER_INFO_101 pInfo101;
	LPSERVER_INFO_100 pInfo100;

	if (PCOUNT() >= 3 && p3.ev_long)
		dwLevel = p3.ev_long == 1 ? 101 : 100;
	else
		dwLevel = 101;

	pArray.Dimension(1,dwLevel == 101 ? 6 : 2);

	do
	{
		nApiRet = fpNetServerEnum(0,dwLevel,pBuffer,MAX_PREFERRED_LENGTH,&dwEntries,&dwTotal,dwServerType,
			pDomain,&hResume);
		if (nApiRet == NERR_Success || nApiRet == ERROR_MORE_DATA)
		{
			if (dwEntries == 0)
			{
				Return((int)dwRows);
				return;
			}

			dwRows += dwEntries;

			if (dwLevel == 101)
			{
				pArray.ReDimension(dwRows,6);
				pInfo101 = (LPSERVER_INFO_101)(LPBYTE)pBuffer;
				while(dwEntries--)
				{
					pArray(nRow,1) = pInfo101->sv101_platform_id;
					pArray(nRow,2) = pData = pInfo101->sv101_name;
					pArray(nRow,3) = pInfo101->sv101_version_major;
					pArray(nRow,4) = pInfo101->sv101_version_minor;
					pArray(nRow,5) = pInfo101->sv101_type;
					pArray(nRow,6) = pData = pInfo101->sv101_comment;
					nRow++;
				}
			}
			else
			{
				pArray.ReDimension(dwRows,2);
				pInfo100 = (LPSERVER_INFO_100)(LPBYTE)pBuffer;
				while(dwEntries--)
				{
					pArray(nRow,1) = pInfo100->sv100_platform_id;
					pArray(nRow,2) = pData = pInfo100->sv100_name;
					nRow++;
				}
			}
		}
		else
		{
			SAVEWIN32ERROR(NetServerEnum,nApiRet);
			throw E_APIERROR;
		}
	}
	while(nApiRet == ERROR_MORE_DATA);

	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall GetServerTime(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpNetRemoteTOD)
		throw E_NOENTRYPOINT;

	FoxWString pServerName(p1);
	FoxDateTime pTime;
	bool bToLocalTime = PCOUNT() == 2 && p2.ev_length;

	NetApiBuffer pBuffer;
	LPTIME_OF_DAY_INFO pServTime;
	SYSTEMTIME sSysTime;
	NET_API_STATUS nApiRet;

	nApiRet = fpNetRemoteTOD(pServerName,pBuffer);
	if (nApiRet == NERR_Success)
	{
		pServTime = pBuffer;
		sSysTime.wYear = (WORD)pServTime->tod_year;
		sSysTime.wMonth = (WORD)pServTime->tod_month;
		sSysTime.wDay = (WORD)pServTime->tod_day;
		sSysTime.wHour = (WORD)pServTime->tod_hours;
		sSysTime.wMinute = (WORD)pServTime->tod_mins;
		sSysTime.wSecond = (WORD)pServTime->tod_secs;
		//sSysTime.wMilliseconds = (WORD)pServTime->tod_hunds; get's truncated anyway in conversion to datetime.
	
		pTime = sSysTime;
		if (bToLocalTime)
			pTime.ToLocal();

		pTime.Return();
	}
	else
	{
		SAVEWIN32ERROR(NetRemoteTOD,nApiRet);
		throw E_APIERROR;
	}
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall SyncToServerTime(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpNetRemoteTOD)
		throw E_NOENTRYPOINT;

	FoxWString pServer(p1);
	NetApiBuffer pBuffer;

	LPTIME_OF_DAY_INFO pServTime;
	SYSTEMTIME sSysTime;
	bool bToLocalTime = PCOUNT() == 2 && p2.ev_length;
	NET_API_STATUS nApiRet;

	nApiRet = fpNetRemoteTOD(pServer,pBuffer);

	if (nApiRet == NERR_Success)
	{
		pServTime = pBuffer;
		sSysTime.wYear = (WORD)pServTime->tod_year;
		sSysTime.wMonth = (WORD)pServTime->tod_month;
		sSysTime.wDay = (WORD)pServTime->tod_day;
		sSysTime.wHour = (WORD)pServTime->tod_hours;
		sSysTime.wMinute = (WORD)pServTime->tod_mins;
		sSysTime.wSecond = (WORD)pServTime->tod_secs;
		sSysTime.wMilliseconds = (WORD)pServTime->tod_hunds;

		if (bToLocalTime)
		{
			if (!SetLocalTime(&sSysTime))
			{
				SAVEWIN32ERROR(SetLocalTime,GetLastError());
				throw E_APIERROR;
			}
		}
		else
		{
			if (!SetSystemTime(&sSysTime))
			{
				SAVEWIN32ERROR(SetSystemTime,GetLastError());
				throw E_APIERROR;
			}
		}
	}
	else
	{
		SAVEWIN32ERROR(NetRemoteTOD,nApiRet);
		throw E_APIERROR;
	}
	Return(1);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}
#include <windows.h>

#include "pro_ext.h"
#include "vfp2c32.h"
#include "vfp2cutil.h"
#include "vfp2cnetapiex.h"
#include "vfp2ccppapi.h"
#include "vfp2chelpers.h"
#include "vfpmacros.h"

static HMODULE hNetApi32 = 0;
static PNETFILEENUMEX fpNetFileEnum = 0;

bool _stdcall VFP2C_Init_Netapiex()
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

	fpNetFileEnum = (PNETFILEENUMEX)GetProcAddress(hDll,"NetFileEnum");
	return true;
}

void _stdcall VFP2C_Destroy_Netapiex()
{
	if (hNetApi32)
		FreeLibrary(hNetApi32);
}

void _fastcall ANetFilesEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();
	// entry point valid?
	if (!fpNetFileEnum)
		throw E_NOENTRYPOINT;

	FoxArray pArray(p1);
	FoxString pServerName(parm,2);
	FoxString pBasePath(parm,3);
	FoxString pNetInfo(NETAPI_INFO_SIZE_EX);
	CBuffer pBuffer(MAX_USHORT);

	unsigned short dwTotal = 0, dwEntries = 0;
	struct file_info_50 *pFileInfo50;
	NET_API_STATUS nApiRet;

	nApiRet = fpNetFileEnum(pServerName,pBasePath,50,pBuffer,MAX_USHORT,&dwEntries,&dwTotal);
	if (nApiRet == NERR_Success || nApiRet == ERROR_MORE_DATA)
	{
		if (dwEntries == 0)
		{
			Return(0);
			return;
		}

		pArray.Dimension(dwEntries,5);

		pFileInfo50 = reinterpret_cast<struct file_info_50*>(pBuffer.Address());
		unsigned int nRow = 1;	
		while (dwEntries--)
		{
			pArray(nRow,1) = pNetInfo = pFileInfo50->fi50_pathname;
			pArray(nRow,2) = pNetInfo = pFileInfo50->fi50_username;
			pArray(nRow,3) = pFileInfo50->fi50_id;
			pArray(nRow,4) = pFileInfo50->fi50_permissions;
			pArray(nRow,5) = pFileInfo50->fi50_num_locks;
			pFileInfo50++;
			nRow++;
		}
	}
	else
	{
		SAVEWIN32ERROR(NetFileEnum,nApiRet);
		throw E_APIERROR;
	}

	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}
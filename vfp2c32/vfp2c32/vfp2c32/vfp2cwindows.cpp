#include <windows.h>

#include "pro_ext.h"
#include "vfp2c32.h"
#include "vfp2cutil.h"
#include "vfp2cwindows.h"
#include "vfpmacros.h"
#include "vfp2ccppapi.h"

static PMONITORFROMWINDOW fpMonitorFromWindow = 0;
static PMONITORFROMPOINT fpMonitorFromPoint = 0;
static PGETMONITORINFO fpGetMonitorInfo = 0;

bool _stdcall VFP2C_Init_Windows()
{
	HMODULE hDll;
	
	hDll = GetModuleHandle("user32.dll");
	if (hDll)
	{
		fpMonitorFromWindow = (PMONITORFROMWINDOW)GetProcAddress(hDll,"MonitorFromWindow");
		fpMonitorFromPoint = (PMONITORFROMPOINT)GetProcAddress(hDll,"MonitorFromPoint");
		fpGetMonitorInfo = (PGETMONITORINFO)GetProcAddress(hDll,"GetMonitorInfoA");
	}
	else
	{
		ADDWIN32ERROR(GetModuleHandle,GetLastError());
		return false;
	}
	return true;
}

void _fastcall GetWindowTextEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	FoxString pRetVal;
	HWND hHwnd = (HWND)p1.ev_long;
	DWORD nLen, nApiRet, nLastError;

	nApiRet = SendMessageTimeout(hHwnd,WM_GETTEXTLENGTH,0,0,SMTO_BLOCK,1000,&nLen);
	if (!nApiRet)
	{
		nLastError = GetLastError();
		if (nLastError == NO_ERROR)
		{
			pRetVal.Return();
			return;
		}
		SAVEWIN32ERROR(SendMessageTimeout,nLastError);
		throw E_APIERROR;
	}

	nLen += 2;
	pRetVal.Size(nLen);
	nApiRet = SendMessageTimeout(hHwnd,WM_GETTEXT,(WPARAM)nLen,(LPARAM)(char*)pRetVal,SMTO_BLOCK,1000,&nLen);
	if (!nApiRet)
	{
		nLastError = GetLastError();
		if (nLastError != NO_ERROR)
		{
			SAVEWIN32ERROR(SendMessageTimeout,nLastError);
			throw E_APIERROR;
		}
	}
	pRetVal.Len(nLen).Return();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall GetWindowRectEx(ParamBlk *parm)
{
try
{
	FoxArray pCoords(p2, 4, 1);
	RECT sRect;

	if (!GetWindowRect(reinterpret_cast<HWND>(p1.ev_long), &sRect))
	{
		SAVEWIN32ERROR(GetWindowRect,GetLastError());
		throw E_APIERROR;
	}

	pCoords(1) = sRect.left;
	pCoords(2) = sRect.right;
	pCoords(3) = sRect.top;
	pCoords(4) = sRect.bottom;

	Return(1);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall CenterWindowEx(ParamBlk *parm)
{
try
{
	HWND hSource, hParent;
	HMONITOR hMon;
	RECT sSourceRect, sParentRect;
	MONITORINFO sMonInfo;
	int nMonitors, nX, nY;

	hSource = reinterpret_cast<HWND>(p1.ev_long);
	hParent = PCOUNT() == 2 ? reinterpret_cast<HWND>(p2.ev_long) : 0;

	if (hParent)
	{
		if (!GetWindowRect(hParent, &sParentRect))
		{
			SAVEWIN32ERROR(GetWindowRect,GetLastError());
			throw E_APIERROR;
		}
	}
	else
	{
		hParent = GetParent(hSource);
		if (hParent)
		{
			if (!GetWindowRect(hParent, &sParentRect))
			{
				SAVEWIN32ERROR(GetWindowRect,GetLastError());
				throw E_APIERROR;
			}
		}
		else
		{
			nMonitors = GetSystemMetrics(SM_CMONITORS);
			if (nMonitors <= 1)
			{
				if (!SystemParametersInfo(SPI_GETWORKAREA,0,reinterpret_cast<void*>(&sParentRect),0))
				{
					SAVEWIN32ERROR(SystemParametersInfo,GetLastError());
					throw E_APIERROR;
				}
			}
			else
			{
				if (!fpMonitorFromWindow)
					throw E_NOENTRYPOINT;

				hMon = fpMonitorFromWindow(hSource, MONITOR_DEFAULTTONEAREST);
				sMonInfo.cbSize = sizeof(MONITORINFO);
				
				if (!fpGetMonitorInfo(hMon, &sMonInfo))
				{
					if (IS_WINNT() || IS_WIN2KXP())
						SAVEWIN32ERROR(GetMonitorInfo,GetLastError());
					else
						SAVECUSTOMERROR("GetMonitorInfo","Function failed.");
					throw E_APIERROR;
				}
				
				sParentRect.left = sMonInfo.rcWork.left;
				sParentRect.right = sMonInfo.rcWork.right;
				sParentRect.top = sMonInfo.rcWork.top;
				sParentRect.bottom = sMonInfo.rcWork.bottom;
			}
		}
	}

	if (!GetWindowRect(hSource, &sSourceRect))
	{
		SAVEWIN32ERROR(GetWindowRect,GetLastError());
		throw E_APIERROR;
	}

	nX = (sParentRect.left + sParentRect.right) / 2 - (sSourceRect.right - sSourceRect.left) / 2;
	nY = (sParentRect.top + sParentRect.bottom) / 2 - (sSourceRect.bottom - sSourceRect.top) / 2;

	if (!SetWindowPos(hSource,0,nX,nY,0,0,SWP_NOSIZE|SWP_NOZORDER|SWP_NOACTIVATE))
	{
		SAVEWIN32ERROR(SetWindowPos,GetLastError());
		throw E_APIERROR;
	}
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall ADesktopArea(ParamBlk *parm)
{
try
{
	FoxArray pCoords(p1,4,1);
	RECT sRect;
	
	if (!SystemParametersInfo(SPI_GETWORKAREA,0,(PVOID)&sRect,0))
	{
		SAVEWIN32ERROR(SystemParametersInfo,GetLastError());
		throw E_APIERROR;
	}

	pCoords(1) = sRect.left;
	pCoords(2) = sRect.right;
	pCoords(3) = sRect.top;
	pCoords(4) = sRect.bottom;
	
	Return(1);
}
catch (int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall ColorOfPoint(ParamBlk *parm)
{
	COLORREF nColor = 0;
	POINT sPoint;
	HWND hWindow;
	HDC hContext;

	sPoint.x = p1.ev_long;
	sPoint.y = p2.ev_long;

	if (PCOUNT() == 2)
		hWindow = 0;
	else
		hWindow = reinterpret_cast<HWND>(p3.ev_long);
		
	hContext = GetDC(hWindow);
	if (hContext)
	{
		nColor = GetPixel(hContext, sPoint.x, sPoint.y);
		if (hWindow)
			ReleaseDC(hWindow,hContext);
	}
	Return(nColor);
}
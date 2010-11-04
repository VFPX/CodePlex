#ifndef _VFP2CASYNC_H__
#define _VFP2CASYNC_H__

#include "vfp2chelpers.h"

// stack size of created threads
#define VFP2C_STACKSIZE		8192

// custom defines and types for file/directory, registry & printer monitoring functions
#define ASYNC_WINDOW_CLASS		"__VFP2C_ASWC"
#define WM_CALLBACK				(WM_USER+1)

class FindFileChangeThread : public CThread
{
public:
	FindFileChangeThread(CThreadManager &pManager);
	~FindFileChangeThread();

	virtual void SignalThreadAbort();
	virtual DWORD Run();

	bool Setup(char *pPath, bool bWatchSubtree, DWORD nFilter, char *pCallback);

private:
	CStr m_Callback;
	CStr m_Buffer;
	CStr m_Path;
	CEvent m_AbortEvent;
	HANDLE m_FileEvent;
};

class FindRegistryChangeThread : public CThread
{
public:
	FindRegistryChangeThread(CThreadManager &pManager);
	~FindRegistryChangeThread();

	virtual void SignalThreadAbort();
	virtual DWORD Run();

	bool Setup(HKEY hRoot, char *pKey, bool bWatchSubtree, DWORD dwFilter, char *pCallback);

private:
	CStr m_Callback;
	CStr m_Buffer;
	CEvent m_RegistryEvent;
	CEvent m_AbortEvent;
	HKEY m_RegKey;
	bool m_WatchSubtree;
	DWORD m_Filter;
};

class WaitForObjectThread : public CThread
{
public:
	WaitForObjectThread(CThreadManager &pManager) : CThread(pManager) { }
	~WaitForObjectThread() { };

	virtual void SignalThreadAbort();
	virtual DWORD Run();

	bool Setup(HANDLE hObject, char *pCallback);

private:
	CStr m_Callback;
	CStr m_Buffer;
	CEvent m_AbortEvent;
	HANDLE m_Object;
};

#ifdef __cplusplus
extern "C" {
#endif

// function forward definitions of vfp2casync.c
bool _stdcall VFP2C_Init_Async();
void _stdcall VFP2C_Destroy_Async();

void _fastcall FindFileChange(ParamBlk *parm);
void _fastcall CancelFileChange(ParamBlk *parm);

void _fastcall FindRegistryChange(ParamBlk *parm);
void _fastcall CancelRegistryChange(ParamBlk *parm);

void _fastcall AsyncWaitForObject(ParamBlk *parm);
void _fastcall CancelWaitForObject(ParamBlk *parm);

LRESULT _stdcall FindChangeWindowProc(HWND nHwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

extern HWND ghAsyncHwnd;
extern CThreadManager goThreadManager;

#ifdef __cplusplus
}
#endif // extern "C"

#endif // _VFP2CASYNC_H__
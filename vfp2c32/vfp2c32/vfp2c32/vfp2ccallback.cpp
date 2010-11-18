#include <windows.h>
#include <stddef.h>
#include <malloc.h>

#include "pro_ext.h"
#include "vfp2c32.h"
#include "vfp2cutil.h"
#include "vfp2ccallback.h"
#include "vfp2cassembly.h"
#include "vfp2ccppapi.h"
#include "vfpmacros.h"

static HANDLE ghThunkHeap = 0;
static LPWINDOWSUBCLASS gpWMSubclasses = 0;
static LPCALLBACKFUNC gpCallbackFuncs = 0;

static HWND ghCallbackHwnd = 0;
static ATOM gnCallbackAtom = 0;

bool _stdcall VFP2C_Init_Callback()
{
	WNDCLASSEX wndClass = {0}; /* MO - message only */

	if (!(ghThunkHeap = HeapCreate(0,MAX_USHORT,0)))
	{
		ADDWIN32ERROR(HeapCreate,GetLastError());
		return false;
	}

	gnCallbackAtom = (ATOM)GetClassInfoEx(ghModule, CALLBACK_WINDOW_CLASS, &wndClass);
	if (!gnCallbackAtom)
	{
		wndClass.cbSize = sizeof(WNDCLASSEX);
		wndClass.hInstance = ghModule;
		wndClass.lpfnWndProc = AsyncCallbackWindowProc;
		wndClass.lpszClassName = CALLBACK_WINDOW_CLASS;
		gnCallbackAtom = RegisterClassEx(&wndClass);
	}

	if (gnCallbackAtom)
	{
		// message only windows are only available on Win2000 or WinXP
		if (IS_WIN2KXP())
			ghCallbackHwnd = CreateWindowEx(0,(LPCSTR)gnCallbackAtom,0,0,0,0,0,0,HWND_MESSAGE,0,ghModule,0);
		else
			ghCallbackHwnd = CreateWindowEx(0,(LPCSTR)gnCallbackAtom,0,WS_POPUP,0,0,0,0,0,0,ghModule,0);

		if (!ghCallbackHwnd)
		{
			ADDWIN32ERROR(CreateWindowEx,GetLastError());
			return false;
		}
	}
	else
	{
		ADDWIN32ERROR(RegisterClassEx,GetLastError());
		return false;
	}

	return true;
}

void _stdcall VFP2C_Destroy_Callback()
{
	ReleaseCallbackFuncs();
	ReleaseWindowSubclasses();

	if (ghThunkHeap)
		HeapDestroy(ghThunkHeap);

	/* destroy window  */
	if (ghCallbackHwnd)
		DestroyWindow(ghCallbackHwnd);
	/* unregister windowclass */
	if (gnCallbackAtom)
		UnregisterClass((LPCSTR)gnCallbackAtom,ghModule);
}

/* 	BINDEVENT(_VFP.hWnd, WM_USER_SHNOTIFY,this,"HandleMsg") */
void _fastcall BindEventsEx(ParamBlk *parm)
{
	LPWINDOWSUBCLASS lpSubclass = 0;
	LPMSGCALLBACK lpMsg = 0;
	UINT uMsg = (UINT)p2.ev_long;
try
{
	RESETWIN32ERRORS();

	HWND hHwnd = reinterpret_cast<HWND>(p1.ev_long);
	FoxString pCallback(p4);
	FoxString pParameters(parm,5);

	DWORD nFlags;
	bool bClassProc;
	char aObjectName[VFP2C_MAX_FUNCTIONBUFFER];

	if (uMsg < WM_NULL)
		throw E_INVALIDPARAMS;

	if (pCallback.Len() > VFP2C_MAX_CALLBACK_FUNCTION)
		throw E_INVALIDPARAMS;

	if (Vartype(p3) != 'O' && Vartype(p3) != '0')
		throw E_INVALIDPARAMS;

	if (!pParameters.Len() && Vartype(p5) != '0')
		throw E_INVALIDPARAMS;

	if (PCOUNT() >= 6 && p6.ev_long)
	{
		nFlags = p6.ev_long;
		if (!(nFlags & (BINDEVENTSEX_CALL_BEFORE | BINDEVENTSEX_CALL_AFTER | BINDEVENTSEX_RETURN_VALUE)))
			nFlags |= BINDEVENTSEX_CALL_BEFORE;
		// check nFlags for invalid combinations
		if (nFlags & BINDEVENTSEX_CALL_BEFORE && nFlags & (BINDEVENTSEX_CALL_AFTER | BINDEVENTSEX_RETURN_VALUE))
			throw E_INVALIDPARAMS;
		else if (nFlags & BINDEVENTSEX_CALL_AFTER && nFlags & (BINDEVENTSEX_CALL_BEFORE | BINDEVENTSEX_RETURN_VALUE))
			throw E_INVALIDPARAMS;
		else if (nFlags & BINDEVENTSEX_RETURN_VALUE && nFlags & (BINDEVENTSEX_CALL_AFTER | BINDEVENTSEX_CALL_BEFORE))
			throw E_INVALIDPARAMS;
	}
	else
		nFlags = BINDEVENTSEX_CALL_BEFORE;

	bClassProc = (nFlags & BINDEVENTSEX_CLASSPROC) > 0;

	// creates either a new struct or returns an existing struct for the passed hWnd
	lpSubclass = NewWindowSubclass(hHwnd,bClassProc);
	SubclassWindow(lpSubclass);

	// get existing struct for uMsg or create a new one
	lpMsg = AddMsgCallback(lpSubclass,uMsg);

	CreateSubclassMsgThunkProc(lpSubclass,lpMsg,pCallback,pParameters,nFlags,Vartype(p3) == 'O');
	
	// if callback on object, store object reference to public variable
	if (Vartype(p3) == 'O')
	{
		sprintfex(aObjectName,BINDEVENTSEX_OBJECT_SCHEME,bClassProc,hHwnd,uMsg);
        StoreObjectRef(aObjectName,lpMsg->nObject,p3);
	}
	Return(reinterpret_cast<void*>(lpSubclass->pDefaultWndProc));
}
catch(int nErrorNo)
{
	if (lpMsg)
		RemoveMsgCallback(lpSubclass,uMsg);
	if (lpSubclass && !lpSubclass->pBoundMessages)
	{
		UnsubclassWindow(lpSubclass);
		RemoveWindowSubclass(lpSubclass);
	}
	RaiseError(nErrorNo);
}
}

void _fastcall UnbindEventsEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	HWND hHwnd = reinterpret_cast<HWND>(p1.ev_long);
	UINT uMsg = static_cast<UINT>(p2.ev_long);
	LPWINDOWSUBCLASS lpSubclass;
	LPMSGCALLBACK lpMsg = 0;
	bool bClassProc = PCOUNT() == 3 && p3.ev_length;

	// get reference to struct for the hWnd, if none is found - the window was not subclassed
	lpSubclass = FindWindowSubclass(hHwnd, bClassProc);
	if (!lpSubclass)
	{
		SAVECUSTOMERROREX("UnbindEventsEx","There are no message bindings for window %I",hHwnd);
		throw E_APIERROR;
	}

	// remove a message hook
	if (PCOUNT() >= 2 && uMsg)
	{
		if (!RemoveMsgCallback(lpSubclass,uMsg))
		{
			SAVECUSTOMERROREX("UnbindEventsEx","There is no message binding for message no. %I",uMsg);
			throw E_APIERROR;
		}
		// if no more hooks are present, unsubclass window
		if (!lpSubclass->pBoundMessages)
		{
			UnsubclassWindow(lpSubclass);
			RemoveWindowSubclass(lpSubclass);
		}
	}
	else // unsubclass window and free all hooks
	{
		UnsubclassWindow(lpSubclass);
		RemoveWindowSubclass(lpSubclass);
	}

	Return(1);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

LPWINDOWSUBCLASS _stdcall NewWindowSubclass(HWND hHwnd, bool bClassProc) throw(int)
{
	LPWINDOWSUBCLASS lpSubclass = FindWindowSubclass(hHwnd,bClassProc);
	if (lpSubclass)
		return lpSubclass;

	lpSubclass = (LPWINDOWSUBCLASS)malloc(sizeof(WINDOWSUBCLASS));
	if (lpSubclass)
	{
		ZeroMemory(lpSubclass,sizeof(WINDOWSUBCLASS));
		lpSubclass->hHwnd = hHwnd;
		lpSubclass->bClassProc = bClassProc;
		lpSubclass->next = gpWMSubclasses;
		gpWMSubclasses = lpSubclass;
	}
	else
		throw E_INSUFMEMORY;

	return lpSubclass;
}

void _stdcall FreeWindowSubclass(LPWINDOWSUBCLASS lpSubclass)
{
	LPMSGCALLBACK lpMsg = lpSubclass->pBoundMessages, lpNext;
	while (lpMsg)
	{
		lpNext = lpMsg->next;
		FreeMsgCallback(lpSubclass,lpMsg);
		lpMsg = lpNext;
	}

	if (lpSubclass->pWindowThunk)
		FreeThunk(lpSubclass->pWindowThunk);
	free(lpSubclass);
}

void _stdcall RemoveWindowSubclass(LPWINDOWSUBCLASS lpSubclass)
{
	LPWINDOWSUBCLASS lpClass = gpWMSubclasses, lpNext;
	LPWINDOWSUBCLASS *lpPrev = &gpWMSubclasses;

	while (lpClass)
	{
		lpNext = lpClass->next;
		if (lpClass == lpSubclass)
		{
			FreeWindowSubclass(lpClass);
			*lpPrev = lpNext;
			return;
		}
		else
		{
			lpPrev = &lpClass->next;
			lpClass = lpNext;
		}
	}
}

LPWINDOWSUBCLASS _stdcall FindWindowSubclass(HWND hHwnd, bool bClassProc)
{
	LPWINDOWSUBCLASS lpSubclass = gpWMSubclasses;
	while (lpSubclass)
	{
		if (lpSubclass->hHwnd == hHwnd && lpSubclass->bClassProc == bClassProc)
			break;
		lpSubclass = lpSubclass->next;
	}
	return lpSubclass;
}

LPMSGCALLBACK NewMsgCallback(UINT uMsg)
{
	LPMSGCALLBACK lpMsg;

	lpMsg = (LPMSGCALLBACK)malloc(sizeof(MSGCALLBACK));
	if (!lpMsg)
		throw E_INSUFMEMORY;

	lpMsg->uMsg = uMsg;
	lpMsg->nObject = 0;
	lpMsg->next = 0;
	lpMsg->pCallbackThunk = 0;

	lpMsg->pCallbackFunction = (char*)malloc(VFP2C_MAX_CALLBACKBUFFER);
	if (!lpMsg->pCallbackFunction)
	{
		free(lpMsg);
		throw E_INSUFMEMORY;
	}
	return lpMsg;
}

void _stdcall FreeMsgCallback(LPWINDOWSUBCLASS pSubclass, LPMSGCALLBACK lpMsg)
{
	char aObjectName[VFP2C_MAX_FUNCTIONBUFFER];

	if (lpMsg->pCallbackThunk)
		FreeThunk(lpMsg->pCallbackThunk);
	if (lpMsg->pCallbackFunction)
		free(lpMsg->pCallbackFunction);

	sprintfex(aObjectName,BINDEVENTSEX_OBJECT_SCHEME,pSubclass->bClassProc,pSubclass->hHwnd,lpMsg->uMsg);
	ReleaseObjectRef(aObjectName,lpMsg->nObject);
	free(lpMsg);
}

LPMSGCALLBACK AddMsgCallback(LPWINDOWSUBCLASS pSubclass, UINT uMsg)
{
	LPMSGCALLBACK lpMsg = pSubclass->pBoundMessages, lpNewMsg;

	if (!lpMsg)
	{
		lpNewMsg = NewMsgCallback(uMsg);
		pSubclass->pBoundMessages = lpNewMsg;
		return lpNewMsg;
	}

	while (1)
	{
		if (lpMsg->uMsg == uMsg)
			return lpMsg;
		else if (lpMsg->next)
			lpMsg = lpMsg->next;
		else
		{
			lpNewMsg = NewMsgCallback(uMsg);
			lpMsg->next = lpNewMsg;
			return lpNewMsg;
		}
	}
}

BOOL _stdcall RemoveMsgCallback(LPWINDOWSUBCLASS pSubclass, UINT uMsg)
{
	LPMSGCALLBACK lpMsg = pSubclass->pBoundMessages, lpNext;
	LPMSGCALLBACK *lpPrev = &pSubclass->pBoundMessages;

	while (lpMsg)
	{
		lpNext = lpMsg->next;
		if (lpMsg->uMsg == uMsg)
		{
			FreeMsgCallback(pSubclass,lpMsg);
			*lpPrev = lpNext;
			return TRUE;
		}
		else
		{
			lpPrev = &lpMsg->next;
			lpMsg = lpNext;
		}
	}
	return FALSE;
}

void* _stdcall FindMsgCallbackThunk(LPWINDOWSUBCLASS pSubclass, UINT uMsg)
{
	LPMSGCALLBACK lpMsg = pSubclass->pBoundMessages;
	while (lpMsg)
	{
		if (lpMsg->uMsg == uMsg)
			return lpMsg->pCallbackThunk;
		lpMsg = lpMsg->next;
	}
	return 0;
}

void _stdcall SubclassWindow(LPWINDOWSUBCLASS lpSubclass) throw(int)
{
	// window/class already subclassed?
	if (lpSubclass->pDefaultWndProc)
		return;

	if (!lpSubclass->bClassProc)
	{
		lpSubclass->pDefaultWndProc = (WNDPROC)GetWindowLong(lpSubclass->hHwnd,GWL_WNDPROC);
		if (!lpSubclass->pDefaultWndProc)
		{
			SAVEWIN32ERROR(GetWindowLong,GetLastError());
			throw E_APIERROR;
		}
		
		CreateSubclassThunkProc(lpSubclass);

		if (!SetWindowLong(lpSubclass->hHwnd,GWL_WNDPROC,(LONG)lpSubclass->pWindowThunk))
		{
			SAVEWIN32ERROR(SetWindowLong,GetLastError());
			throw E_APIERROR;
		}
	}
	else
	{
		lpSubclass->pDefaultWndProc = (WNDPROC)GetClassLong(lpSubclass->hHwnd,GCL_WNDPROC);
		if (!lpSubclass->pDefaultWndProc)
		{
			SAVEWIN32ERROR(GetClassLong,GetLastError());
			throw E_APIERROR;
		}
		
		CreateSubclassThunkProc(lpSubclass);

		if (!SetClassLong(lpSubclass->hHwnd,GCL_WNDPROC,(LONG)lpSubclass->pWindowThunk))
		{
			SAVEWIN32ERROR(SetClassLong,GetLastError());
			throw E_APIERROR;
		}
	}
}

void _stdcall UnsubclassWindow(LPWINDOWSUBCLASS lpSubclass)
{
	if (!lpSubclass->bClassProc)
	{
		if (!SetWindowLong(lpSubclass->hHwnd,GWL_WNDPROC,(LONG)lpSubclass->pDefaultWndProc))
		{
			SAVEWIN32ERROR(SetWindowLong,GetLastError());
			throw E_APIERROR;
		}
	}
	else
	{
		if (!SetClassLong(lpSubclass->hHwnd,GCL_WNDPROC,(LONG)lpSubclass->pDefaultWndProc))
		{
			SAVEWIN32ERROR(SetClassLong,GetLastError());
			throw E_APIERROR;
		}
		UnsubclassWindowEx(lpSubclass);
	}
}

void _stdcall UnsubclassWindowEx(LPWINDOWSUBCLASS lpSubclass)
{
	EnumThreadWindows(GetCurrentThreadId(),(WNDENUMPROC)UnsubclassWindowExCallback,(LPARAM)lpSubclass);
}

void _stdcall UnsubclassWindowExCallback(HWND hHwnd, LPARAM lParam)
{
	LPWINDOWSUBCLASS lpSubclass = (LPWINDOWSUBCLASS)lParam;
	void* nProc;
	
	nProc = (void*)GetWindowLong(hHwnd,GWL_WNDPROC);
	if (nProc == lpSubclass->pWindowThunk)
	{
		if (!SetWindowLong(hHwnd,GWL_WNDPROC,(LONG)lpSubclass->pDefaultWndProc))
		{
			SAVEWIN32ERROR(SetWindowLong,GetLastError());
			throw E_APIERROR;
		}
	}

	if (!EnumChildWindows(hHwnd,(WNDENUMPROC)UnsubclassWindowExCallbackChild,(LPARAM)lpSubclass))
	{
		if (GetLastError() != NO_ERROR)
		{
			SAVEWIN32ERROR(EnumChildWindows,GetLastError());
			throw E_APIERROR;
		}
	}
}

void _stdcall UnsubclassWindowExCallbackChild(HWND hHwnd, LPARAM lParam)
{
	LPWINDOWSUBCLASS lpSubclass = (LPWINDOWSUBCLASS)lParam;
	void* nProc;
	
	nProc = (void*)GetWindowLong(hHwnd,GWL_WNDPROC);
	if (nProc == lpSubclass->pWindowThunk)
	{
		if (!SetWindowLong(hHwnd,GWL_WNDPROC,(LONG)lpSubclass->pDefaultWndProc))
		{
			SAVEWIN32ERROR(SetWindowLong,GetLastError());
			throw E_APIERROR;
		}
	}
}

void _stdcall CreateSubclassThunkProc(LPWINDOWSUBCLASS lpSubclass)
{
	Emit_Init();

	Emit_Parameter("hWnd",T_INT);
	Emit_Parameter("uMsg",T_UINT);
    Emit_Parameter("wParam",T_UINT);
    Emit_Parameter("lParam",T_INT);

	Emit_LocalVar("vRetVal",sizeof(Value),__alignof(Value));
	Emit_LocalVar("vAutoYield",sizeof(Value),__alignof(Value));

	// Function Prolog
	Emit_Prolog();
	// save common registers
	Push(EBX);
	Push(ECX);
	Push(EDX);

	Push("uMsg");
	Push((AVALUE)lpSubclass);
	Call((FUNCPTR)FindMsgCallbackThunk);

	Cmp(EAX,0); // msg was subclassed?
	Je("CallWindowProc");
	
	Jmp(EAX); // jump to thunk
	
	Emit_Label("CallWindowProc");
	//  return CallWindowProc(lpSubclass->pDefaultWndProc,hHwnd,uMsg,wParam,lParam);
	Push("lParam");
	Push("wParam");
	Push("uMsg");
	Push("hWnd");
	Push((AVALUE)lpSubclass->pDefaultWndProc);
	Call((FUNCPTR)CallWindowProc);

	Emit_Label("End");

	// restore registers
	Pop(EDX);
	Pop(ECX);
	Pop(EBX);
	// Function Epilog
	Emit_Epilog();
	
	// backpatch jump instructions
	Emit_Patch();
	
	lpSubclass->pWindowThunk = AllocThunk(Emit_CodeSize());
	Emit_Write(lpSubclass->pWindowThunk);

	lpSubclass->pHookWndRetCall = Emit_LabelAddress("CallWindowProc");
	lpSubclass->pHookWndRetEax = Emit_LabelAddress("End");
}

void _stdcall CreateSubclassMsgThunkProc(LPWINDOWSUBCLASS lpSubclass, LPMSGCALLBACK lpMsg, char *pCallback, char *pParmDef, DWORD nFlags, BOOL bObjectCall)
{
	int nParmCount = 6, xj;
	char aParmValue[VFP2C_MAX_TYPE_LEN];
	char aConvertFlags[VFP2C_MAX_TYPE_LEN] = {0};
	char *pConvertFlags = aConvertFlags;
	char *pCallbackTmp;
	REGISTER nReg = EAX;

	Emit_Init();

	Emit_Parameter("hWnd",T_INT);
	Emit_Parameter("uMsg",T_UINT);
    Emit_Parameter("wParam",T_UINT);
	Emit_Parameter("lParam",T_UINT);

	Emit_LocalVar("vRetVal",sizeof(Value),__alignof(Value));
	Emit_LocalVar("vAutoYield",sizeof(Value),__alignof(Value));

	if (bObjectCall)
		sprintfex(lpMsg->pCallbackFunction,BINDEVENTSEX_OBJECT_SCHEME".",
		lpSubclass->bClassProc,lpSubclass->hHwnd,lpMsg->uMsg);
	else
		*lpMsg->pCallbackFunction = '\0';

	strcat(lpMsg->pCallbackFunction,pCallback);

	if (nFlags & BINDEVENTSEX_CALL_AFTER)
	{
		Push("lParam");
		Push("wParam");
		Push("uMsg");
		Push("hWnd");
		Push((AVALUE)lpSubclass->pDefaultWndProc);
		Call((FUNCPTR)CallWindowProc);	
	}

	if (nFlags & BINDEVENTSEX_NO_RECURSION)
	{
		// _Evaluate(&vAutoYield,"_VFP.AutoYield");
		Lea(ECX,"vAutoYield",0);
		Mov(EDX,(AVALUE)"_VFP.AutoYield");
		Call((FUNCPTR)_Evaluate);

		// if (vAutoYield.ev_length)
		//  _Execute("_VFP.AutoYield = .F.")
		Mov(EAX,"vAutoYield",T_UINT,offsetof(Value,ev_length));
		Cmp(EAX,0);
		Je("AutoYieldFalse");
		Mov(ECX,(AVALUE)"_VFP.AutoYield = .F.");
		Call((FUNCPTR)_Execute);
		Emit_Label("AutoYieldFalse");
	}

	if (!pParmDef)
	{
		strcat(lpMsg->pCallbackFunction,"(%U,%U,%I,%I)");
		Push("lParam");
		Push("wParam");
		Push("uMsg");
		Push("hWnd");
	}
	else
	{
		nParmCount = GetWordCount(pParmDef,',');
		
		if (nParmCount > VFP2C_MAX_TYPE_LEN)
			throw E_INVALIDPARAMS;

		for (xj = nParmCount; xj; xj--)
		{
			GetWordNumN(aParmValue,pParmDef,',',xj,VFP2C_MAX_TYPE_LEN);
           	Alltrim(aParmValue);

			if (STRIEQUAL("wParam",aParmValue))
			{
				*pConvertFlags++ = 'I';
				Push("wParam");
			}
			else if (STRIEQUAL("lParam",aParmValue))
			{
				*pConvertFlags++ = 'I';
				Push("lParam");
			}
			else if (STRIEQUAL("uMsg",aParmValue))
			{
				*pConvertFlags++ = 'U';
				Push("uMsg");
			}
			else if (STRIEQUAL("hWnd",aParmValue))
			{
				*pConvertFlags++ = 'U';
				Push("hWnd");
			}
			else if (STRIEQUAL("UNSIGNED(wParam)",aParmValue))
			{
				*pConvertFlags++ = 'U';
				Push("wParam");
			}
			else if (STRIEQUAL("UNSIGNED(lParam)",aParmValue))
			{
				*pConvertFlags++ = 'U';
				Push("lParam");
			}
			else if (STRIEQUAL("HIWORD(wParam)",aParmValue))
			{
				*pConvertFlags++ = 'i';
				Mov(nReg,"wParam");
				Shr(nReg,16);
				Push(nReg);
			}
			else if (STRIEQUAL("LOWORD(wParam)",aParmValue))
			{
				*pConvertFlags++ = 'i';
				Mov(nReg,"wParam");
				And(nReg,MAX_USHORT);
				Push(nReg);
			}
			else if (STRIEQUAL("HIWORD(lParam)",aParmValue))
			{
				*pConvertFlags++ = 'i';
				Mov(nReg,"lParam");
				Shr(nReg,16);
				Push(nReg);
			}
			else if (STRIEQUAL("LOWORD(lParam)",aParmValue))
			{
				*pConvertFlags++ = 'i';
				Mov(nReg,"lParam");
				And(nReg,MAX_USHORT);
				Push(nReg);
			}
			else if (STRIEQUAL("UNSIGNED(HIWORD(wParam))",aParmValue))
			{
				*pConvertFlags++ = 'u';
				Mov(nReg,"wParam");
				Shr(nReg,16);
				Push(nReg);
			}
			else if (STRIEQUAL("UNSIGNED(LOWORD(wParam))",aParmValue))
			{
				*pConvertFlags++ = 'u';
				Mov(nReg,"wParam");
				And(nReg,MAX_USHORT);
				Push(nReg);
			}
			else if (STRIEQUAL("UNSIGNED(HIWORD(lParam))",aParmValue))
			{
				*pConvertFlags++ = 'u';
				Mov(nReg,"lParam");
				Shr(nReg,16);
				Push(nReg);
			}
			else if (STRIEQUAL("UNSIGNED(LOWORD(lParam))",aParmValue))
			{
				*pConvertFlags++ = 'u';
				Mov(nReg,"lParam");
				And(nReg,MAX_USHORT);
				Push(nReg);
			}
			else if (STRIEQUAL("BOOL(wParam)",aParmValue))
			{
				*pConvertFlags++ = 'L';
				Push("wParam");
			}
			else if (STRIEQUAL("BOOL(lParam)",aParmValue))
			{
				*pConvertFlags++ = 'L';
				Push("lParam");
			}
			else
				throw E_INVALIDPARAMS;

			if (nReg == EAX)
				nReg = EBX;
			else if (nReg == EBX)
				nReg = ECX;
			else if (nReg == ECX)
				nReg = EDX;
			else
				nReg = EAX;
		}

		// build format string
		pCallbackTmp = strend(lpMsg->pCallbackFunction);
		*pCallbackTmp++ = '(';
		for (xj = nParmCount; xj; xj--)
		{
			*pCallbackTmp++ = '%';
			*pCallbackTmp++ = aConvertFlags[xj-1];
			if (xj > 1)
				*pCallbackTmp++ = ',';
		}
		*pCallbackTmp++ = ')';
		*pCallbackTmp = '\0';

		// two parameters are always passed to sprintfex ..
		nParmCount += 2;
	}

	// if any parameters should be passed we need to call sprintfex
	if (nParmCount > 2)
	{
		Push((AVALUE)lpMsg->pCallbackFunction);
		Push((AVALUE)lpSubclass->aCallbackBuffer);
		Call((FUNCPTR)sprintfex);
		Add(ESP,nParmCount*sizeof(int));	// add esp, no of parameters * sizeof stack increment
	}

	if (nFlags & BINDEVENTSEX_CALL_BEFORE)
	{
		if (nParmCount > 2)
			Mov(ECX,(AVALUE)lpSubclass->aCallbackBuffer);
		else
			Mov(ECX,(AVALUE)lpMsg->pCallbackFunction);

		Call((FUNCPTR)_Execute);
		
		if (nFlags & BINDEVENTSEX_NO_RECURSION)
		{
			Mov(EAX,"vAutoYield",T_UINT,offsetof(Value,ev_length));
			Cmp(EAX,0);
			Je("AutoYieldBack");
			// set autoyield to .T. again 
			Mov(ECX,(AVALUE)"_VFP.AutoYield = .T.");
			Call((FUNCPTR)_Execute);
			Emit_Label("AutoYieldBack");
		}
		Jmp(EBX,(AVALUE)lpSubclass->pHookWndRetCall); // jump back
	}
	else if (nFlags & (BINDEVENTSEX_CALL_AFTER | BINDEVENTSEX_RETURN_VALUE))
	{
		Lea(ECX,"vRetVal");
		if (nParmCount > 2)
			Mov(EDX,(AVALUE)lpSubclass->aCallbackBuffer);
		else
			Mov(EDX,(AVALUE)lpMsg->pCallbackFunction);

		Call((FUNCPTR)_Evaluate);

		if (nFlags & BINDEVENTSEX_NO_RECURSION)
		{
			Mov(EAX,"vAutoYield",T_UINT,offsetof(Value,ev_length));
			// if autoyield was .F. before we don't need to set it
			Cmp(EAX,0);
			Je("AutoYieldBack");
			// set autoyield to .T. again 
			Mov(ECX,(AVALUE)"_VFP.AutoYield = .T.");
			Call((FUNCPTR)_Execute);
			Emit_Label("AutoYieldBack");
		}
		Mov(EAX,"vRetVal",T_INT,offsetof(Value,ev_long));
		Jmp(EBX,(AVALUE)lpSubclass->pHookWndRetEax); // jump back
	}

	if (lpMsg->pCallbackThunk)
	{
		FreeThunk(lpMsg->pCallbackThunk);
		lpMsg->pCallbackThunk = 0;
	}

	Emit_Patch();
	lpMsg->pCallbackThunk = AllocThunk(Emit_CodeSize());
	Emit_Write(lpMsg->pCallbackThunk);
}

void _stdcall ReleaseWindowSubclasses()
{
	LPWINDOWSUBCLASS lpSubclass = gpWMSubclasses, lpNext;

	while (lpSubclass)
	{
		lpNext = lpSubclass->next;
		try
		{
			UnsubclassWindow(lpSubclass);
		}
		catch(int) {}
		try
		{
			FreeWindowSubclass(lpSubclass);
		}
		catch(int) {}
		lpSubclass = lpNext;
	}
}

LPCALLBACKFUNC NewCallbackFunc() throw(int)
{
	LPCALLBACKFUNC pFunc = (LPCALLBACKFUNC)malloc(sizeof(CALLBACKFUNC));
	if (pFunc)
	{
		ZeroMemory(pFunc,sizeof(CALLBACKFUNC));
		pFunc->next = gpCallbackFuncs;
		gpCallbackFuncs = pFunc;
		return pFunc;
	}
	else
		throw E_INSUFMEMORY;
}

bool DeleteCallbackFunc(void *pFuncAddress)
{
	LPCALLBACKFUNC pFunc = gpCallbackFuncs, pFuncPrev = 0;
    char aObjectName[VFP2C_MAX_FUNCTIONBUFFER];

	while (pFunc && pFunc->pFuncAddress != pFuncAddress)
	{
		pFuncPrev = pFunc;
		pFunc = pFunc->next;
	}

	if (pFunc)
	{
		if (pFuncPrev)
			pFuncPrev->next = pFunc->next;
		else
			gpCallbackFuncs = pFunc->next;

		sprintfex(aObjectName,CALLBACKFUNC_OBJECT_SCHEME,pFunc);
		ReleaseObjectRef(aObjectName,pFunc->nObject);
		
		FreeThunk(pFuncAddress);
		free(pFunc);
		return true;
	}
	return false;
}

void _stdcall ReleaseCallbackFuncs()
{
	LPCALLBACKFUNC pFunc = gpCallbackFuncs, pFuncNext;
    char aObjectName[VFP2C_MAX_FUNCTIONBUFFER];
  
	while (pFunc)
	{
		pFuncNext = pFunc->next;
		sprintfex(aObjectName,CALLBACKFUNC_OBJECT_SCHEME,pFunc);
		ReleaseObjectRef(aObjectName,pFunc->nObject);
		FreeThunk(pFunc->pFuncAddress);
		free(pFunc);
		pFunc = pFuncNext;
	}
}

void _fastcall CreateCallbackFunc(ParamBlk *parm)
{
	LPCALLBACKFUNC pFunc = 0;
try
{
	FoxString pCallback(p1);
	FoxString pRetVal(p2);
	FoxString pParams(p3);
	
	DWORD nSyncFlag = PCOUNT() == 5 ? p5.ev_long : CALLBACK_SYNCRONOUS;
	bool bCDeclCallConv = (nSyncFlag | CALLBACK_CDECL) > 0; // is CALLBACK_CDECL set?
	nSyncFlag &= ~CALLBACK_CDECL; // remove CALLBACK_CDECL from nSyncFlag
	nSyncFlag = nSyncFlag ? nSyncFlag : CALLBACK_SYNCRONOUS; // set nSyncFlag to default CALLBACK_SYNCRONOUS if is 0

	int nParmCount, nParmLen, nPrecision, nParmNo;
	
	char aParmFormat[128] = {0};
	char aParmType[VFP2C_MAX_TYPE_LEN];
	char aParmPrec[VFP2C_MAX_TYPE_LEN];
	char aObjectName[VFP2C_MAX_FUNCTIONBUFFER];

	if (pCallback.Len() > VFP2C_MAX_CALLBACK_FUNCTION)
		throw E_INVALIDPARAMS;

	if (nSyncFlag != CALLBACK_SYNCRONOUS && 
		nSyncFlag != CALLBACK_ASYNCRONOUS_POST && 
		nSyncFlag != CALLBACK_ASYNCRONOUS_SEND)
		throw E_INVALIDPARAMS;

	pFunc = NewCallbackFunc();

	if (PCOUNT() >= 4 && Vartype(p4) == 'O')
	{
		sprintfex(aObjectName,CALLBACKFUNC_OBJECT_SCHEME,pFunc);
		StoreObjectRef(aObjectName,pFunc->nObject,p4);
		strcpy(pFunc->aCallbackBuffer,aObjectName);
		strcat(pFunc->aCallbackBuffer,".");
	}
 
	nParmCount = pParams.GetWordCount(',');
	if (nParmCount > VFP2C_MAX_CALLBACK_PARAMETERS)
		throw E_INVALIDPARAMS;

	Emit_Init();
	
	// return value needed?
	if (pRetVal.Len() > 0 && !pRetVal.ICompare("void"))
		Emit_LocalVar("vRetVal",sizeof(Value),__alignof(Value));
	// local buffer variable needed
	if (nSyncFlag & (CALLBACK_ASYNCRONOUS_POST|CALLBACK_ASYNCRONOUS_SEND))
		Emit_LocalVar("pBuffer",T_UINT);

	Emit_Prolog();
	Push(EBX);
	//Push(ECX);
	//Push(EDX);

	if (nSyncFlag & (CALLBACK_ASYNCRONOUS_POST|CALLBACK_ASYNCRONOUS_SEND))
	{
		Push(VFP2C_MAX_CALLBACK_BUFFER);
		Call((FUNCPTR)malloc);
		Add(ESP,sizeof(int));

		Cmp(EAX,0);
		Je("ErrorOut");
		Mov("pBuffer",EAX);
	}

	if (nParmCount)
	{
		// fill static part of buffer
		strcat(pFunc->aCallbackBuffer,pCallback);
		strcat(pFunc->aCallbackBuffer,"(");
		if (nSyncFlag & (CALLBACK_ASYNCRONOUS_POST|CALLBACK_ASYNCRONOUS_SEND))
		{
			/* memcpy(pBuffer,pFunc->aCallbackBuffer,strlen(pFunc->aCallbackBuffer)
			memcpy uses the cdecl calling convention, thus parameters are pushed from right to left and
			we have to adjust the stack pointer (ESP) after the call */
			Push(strlen(pFunc->aCallbackBuffer));
			Push((AVALUE)pFunc->aCallbackBuffer);
			Push("pBuffer");
			Call((FUNCPTR)memcpy);
			Add(ESP,3*sizeof(int));

			Mov(EAX,"pBuffer");
			Add(EAX,strlen(pFunc->aCallbackBuffer));
		}
		else
			Mov(EAX,(AVALUE)(pFunc->aCallbackBuffer+strlen(pFunc->aCallbackBuffer)));
	}
	else
	{
		strcat(pFunc->aCallbackBuffer,pCallback);
		strcat(pFunc->aCallbackBuffer,"()");
		if (nSyncFlag & (CALLBACK_ASYNCRONOUS_POST|CALLBACK_ASYNCRONOUS_SEND))
		{
			Push(strlen(pFunc->aCallbackBuffer)+1);
			Push((AVALUE)pFunc->aCallbackBuffer);
			Push("pBuffer");
			Call((FUNCPTR)memcpy);
			Add(ESP,3*sizeof(int));
		}
	}
	
	for (nParmNo = 1; nParmNo <= nParmCount; nParmNo++)
	{
		GetWordNumN(aParmType,pParams,',',nParmNo,VFP2C_MAX_TYPE_LEN);
		Alltrim(aParmType);

		nParmLen = GetWordCount(aParmType,' ');
		if (nParmLen == 2)
		{
			GetWordNumN(aParmPrec,aParmType,' ',2,VFP2C_MAX_TYPE_LEN);
			GetWordNumN(aParmType,aParmType,' ',1,VFP2C_MAX_TYPE_LEN);
		}
		else if (nParmLen > 2)
			throw E_INVALIDPARAMS;

		if (nParmNo > 1)
		{
			Mov(REAX,sizeof(char),',');
			Add(EAX,1);
		}

		if (STRIEQUAL(aParmType,"INTEGER") || STRIEQUAL(aParmType,"LONG"))
		{
			Emit_Parameter(T_INT);
			Push((PARAMNO)nParmNo);
			Push(EAX);
			Call(EBX,(FUNCPTR)IntToStr);
		}
		else if (STRIEQUAL(aParmType,"UINTEGER") || STRIEQUAL(aParmType,"ULONG") || STRIEQUAL(aParmType,"STRING"))
		{
			Emit_Parameter(T_UINT);
			Push((PARAMNO)nParmNo);
			Push(EAX);
			Call(EBX,(FUNCPTR)UIntToStr);
		}
		else if (STRIEQUAL(aParmType,"SHORT"))
		{
			Emit_Parameter(T_SHORT);
			Push((PARAMNO)nParmNo);
			Push(EAX);
			Call(EBX,(FUNCPTR)IntToStr);
		}
		else if (STRIEQUAL(aParmType,"USHORT"))
		{
			Emit_Parameter(T_USHORT);
			Push((PARAMNO)nParmNo);
			Push(EAX);
			Call(EBX,(FUNCPTR)UIntToStr);
		}
		else if (STRIEQUAL(aParmType,"BOOL"))
		{
			Emit_Parameter(T_INT);
			Push((PARAMNO)nParmNo);
			Push(EAX);
			Call(EBX,(FUNCPTR)BoolToStr);
		}
		else if (STRIEQUAL(aParmType,"SINGLE"))
		{
			Emit_Parameter(T_FLOAT);

			if (nParmLen == 2)
			{
				nPrecision = atoi(aParmPrec);
				if (nPrecision < 0 || nPrecision > 6)
					throw E_INVALIDPARAMS;
			}
			else
				nPrecision = 6;

			Push(nPrecision);
			Push((PARAMNO)nParmNo);
			Push(EAX);
			Call(EBX,(FUNCPTR)FloatToStr);
		}
		else if (STRIEQUAL(aParmType,"DOUBLE"))
		{
			Emit_Parameter(T_DOUBLE);

			if (nParmLen == 2)
			{
				nPrecision = atoi(aParmPrec);
				if (nPrecision < 0 || nPrecision > 16)
					throw E_INVALIDPARAMS;
			}
			else
				nPrecision = 6;

			Push(nPrecision);
			Push((PARAMNO)nParmNo);			
			Push(EAX);
			Call(EBX,(FUNCPTR)DoubleToStr);
		}
		else if (STRIEQUAL(aParmType,"INT64"))
		{
			Emit_Parameter(T_INT64);
			Push((PARAMNO)nParmNo);			
			Push(EAX);
			Call(EBX,(FUNCPTR)Int64ToStr);
		}
		else if (STRIEQUAL(aParmType,"UINT64"))
		{
			Emit_Parameter(T_UINT64);
			Push((PARAMNO)nParmNo);			
			Push(EAX);
			Call(EBX,(FUNCPTR)UInt64ToStr);
		}
		else
			throw E_INVALIDPARAMS;
	}

	// nullterminate
	if (nParmCount)
	{
		Mov(REAX,sizeof(char),')');
		Add(EAX,1);
		Mov(REAX,sizeof(char),'\0');
	}

	if (nSyncFlag & (CALLBACK_ASYNCRONOUS_POST|CALLBACK_ASYNCRONOUS_SEND))
	{
		/* PostMessage(ghCallbackHwnd,WM_ASYNCCALLBACK,pBuffer,0); */
		Push(0);
		Push("pBuffer");
		Push(WM_ASYNCCALLBACK);
		Push(ghCallbackHwnd);
		if (nSyncFlag & CALLBACK_ASYNCRONOUS_POST)
			Call((FUNCPTR)PostMessage);
		else
			Call((FUNCPTR)SendMessage);
	}
	else if (pRetVal.Len() == 0 || pRetVal.ICompare("void"))
	{
		/* EXECUTE(pFunc->aCallbackBuffer); */
		Mov(ECX,(AVALUE)pFunc->aCallbackBuffer);
		Call((FUNCPTR)_Execute);
	}
	else
	{
		/* EVALUATE(vRetVal,pFunc->aCallbackBuffer) */
		Lea(ECX,"vRetVal");
		Mov(EDX,(AVALUE)pFunc->aCallbackBuffer);
		Call((FUNCPTR)_Evaluate);

		// return value
		if (STRIEQUAL(pRetVal,"INTEGER") || STRIEQUAL(pRetVal,"LONG"))
			Mov(EAX,"vRetVal",T_INT,offsetof(Value,ev_long));
		else if (STRIEQUAL(pRetVal,"UINTEGER") || STRIEQUAL(pRetVal,"ULONG"))
		{
			Mov(AL,"vRetVal",T_CHAR,offsetof(Value,ev_type));
			Cmp(AL,'N');
			Je("DConv");
			Mov(EAX,"vRetVal",T_UINT,offsetof(Value,ev_long));
			Jmp("End");
			Emit_Label("DConv");
			Push("vRetVal",T_DOUBLE,offsetof(Value,ev_real));
			Call((FUNCPTR)DoubleToUInt);
			Emit_Label("End");
		}
		else if (STRIEQUAL(pRetVal,"SHORT"))
			Mov(AX,"vRetVal",T_INT,offsetof(Value,ev_long));
		else if (STRIEQUAL(pRetVal,"USHORT"))
			Mov(AX,"vRetVal",T_UINT,offsetof(Value,ev_long));
		else if (STRIEQUAL(pRetVal,"SINGLE") || STRIEQUAL(pRetVal,"DOUBLE"))
			Fld("vRetVal",T_DOUBLE,offsetof(Value,ev_real));
		else if (STRIEQUAL(pRetVal,"BOOL"))
			Mov(EAX,"vRetVal",T_UINT,offsetof(Value,ev_length));
		else if (STRIEQUAL(pRetVal,"INT64"))
		{
			Mov(AL,"vRetVal",T_CHAR,offsetof(Value,ev_type));
			Cmp(AL,'N');
			Je("DConv");
			Mov(EAX,"vRetVal",T_INT,offsetof(Value,ev_long));
			Cdq();
			Jmp("End");
			Emit_Label("DConv");
			Push("vRetVal",T_DOUBLE,offsetof(Value,ev_real));
			Call((FUNCPTR)DoubleToInt64);
			Emit_Label("End");
		}
		else if (STRIEQUAL(pRetVal,"UINT64"))
		{
			Mov(AL,"vRetVal",T_CHAR,offsetof(Value,ev_type));
			Cmp(AL,'N');
			Je("DConv");
			Mov(EAX,"vRetVal",T_UINT,offsetof(Value,ev_long));
			Xor(EDX,EDX);
			Jmp("End");
			Emit_Label("DConv");
			Push("vRetVal",T_DOUBLE,offsetof(Value,ev_real));
			Call((FUNCPTR)DoubleToUInt64);
			Emit_Label("End");
		}
		else
			throw E_INVALIDPARAMS;
	}

	Emit_Label("ErrorOut");
	//Pop(EDX);
	//Pop(ECX);
	Pop(EBX);
	Emit_Epilog(bCDeclCallConv);

	Emit_Patch();

	pFunc->pFuncAddress = AllocThunk(Emit_CodeSize());
	Emit_Write(pFunc->pFuncAddress);

	Return(pFunc->pFuncAddress);
}
catch(int nErrorNo)
{
	if (pFunc)
		DeleteCallbackFunc(pFunc);
	RaiseError(nErrorNo);
}
}

void _fastcall DestroyCallbackFunc(ParamBlk *parm)
{
	Return(DeleteCallbackFunc(reinterpret_cast<void*>(p1.ev_long)));
}

LRESULT _stdcall AsyncCallbackWindowProc(HWND nHwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	int nErrorNo;
	if (uMsg == WM_ASYNCCALLBACK)
	{
		__try
		{
			char* pCommand = reinterpret_cast<char*>(wParam);
			if (pCommand)
			{
				if (_msize(pCommand) > 0)
				{
					nErrorNo = _Execute(pCommand);
					free(reinterpret_cast<void*>(wParam));
					if (nErrorNo)
						RaiseError(nErrorNo);
					return 0;
				}
			}
		}
		__except (EXCEPTION_EXECUTE_HANDLER) {}
	}
	return DefWindowProc(nHwnd,uMsg,wParam,lParam);
}

void* _stdcall AllocThunk(int nSize) throw(int)
{
	void *pThunk;
	DWORD dwProtect;

	pThunk = HeapAlloc(ghThunkHeap,0,nSize);
	if (pThunk)
	{
		if (VirtualProtect(pThunk,nSize,PAGE_EXECUTE_READWRITE,&dwProtect))
			return pThunk;
		else
		{
			SAVEWIN32ERROR(VirtualProtect,GetLastError());
			HeapFree(ghThunkHeap,0,pThunk);
			throw E_APIERROR;
		}
	}
	else
		throw E_INSUFMEMORY;
}

BOOL _stdcall FreeThunk(void *lpAddress)
{
	return HeapFree(ghThunkHeap,0,lpAddress);
}
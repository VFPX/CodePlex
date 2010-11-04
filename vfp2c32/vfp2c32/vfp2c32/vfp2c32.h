#ifndef _VFP2C32_H__
#define _VFP2C32_H__

// filename of FLL
#ifndef _DEBUG
	#define FLLFILENAME "vfp2c32.fll"
#else
	#define FLLFILENAME "vfp2c32d.fll"
#endif

#define VFP2C_INIT_MARSHAL	0x00000001
#define VFP2C_INIT_ENUM		0x00000002
#define VFP2C_INIT_ASYNC	0x00000004
#define VFP2C_INIT_FILE		0x00000008
#define VFP2C_INIT_WINSOCK	0x00000010
#define VFP2C_INIT_ODBC		0x00000020
#define VFP2C_INIT_PRINT	0x00000040
#define VFP2C_INIT_NETAPI	0x00000080
#define VFP2C_INIT_CALLBACK	0x00000100
#define VFP2C_INIT_SERVICES 0x00000200
#define VFP2C_INIT_WINDOWS	0x00000400
#define VFP2C_INIT_RAS		0x00000800
#define VFP2C_INIT_IPHELPER	0x00001000
#define VFP2C_INIT_URLMON	0x00002000
#define VFP2C_INIT_WININET	0x00004000
#define VFP2C_INIT_COM		0x00008000

#define VFP2C_MAX_CALLBACKFUNCTION	1024
#define VFP2C_MAX_CALLBACKBUFFER	2048
#define VFP2C_MAX_FUNCTIONBUFFER	256

// defines for error handling
#define VFP2C_MAX_ERRORS			24
#define VFP2C_ERROR_MESSAGE_LEN		4096
#define VFP2C_ERROR_FUNCTION_LEN	128

#define VFP2C_ERRORTYPE_WIN32	1
#define VFP2C_ERRORTYPE_ODBC	2
#define VFP2C_ODBC_STATE_LEN	6

#define RESETWIN32ERRORS()					gnErrorCount = -1
#define SAVEWIN32ERROR(cFunc,nErrorNo)		Win32ErrorHandler(#cFunc,nErrorNo,FALSE,FALSE)
#define ADDWIN32ERROR(cFunc,nErrorNo)		Win32ErrorHandler(#cFunc,nErrorNo,TRUE,FALSE)
#define RAISEWIN32ERROR(cFunc,nErrorNo)		Win32ErrorHandler(#cFunc,nErrorNo,FALSE,TRUE)
#define SAVECUSTOMERROR(cFunc,cMessage)		Win32ErrorHandlerEx(cFunc,cMessage,FALSE,FALSE)
#define ADDCUSTOMERROR(cFunc,cMessage)		Win32ErrorHandlerEx(cFunc,cMessage,TRUE,FALSE)
#define RAISECUSTOMERROR(cFunc,cMessage)	Win32ErrorHandlerEx(cFunc,cMessage,FALSE,TRUE)
#define SAVECUSTOMERROREX(cFunc,cMessage,nErrorNo)	Win32ErrorHandlerExEx(cFunc,cMessage,(DWORD)nErrorNo,FALSE,FALSE)
#define ADDCUSTOMERROREX(cFunc,cMessage,nErrorNo)	Win32ErrorHandlerExEx(cFunc,cMessage,(DWORD)nErrorNo,TRUE,FALSE)
#define RAISECUSTOMERROREX(cFunc,cMessage,nErrorNo) Win32ErrorHandlerExEx(cFunc,cMessage,(DWORD)nErrorNo,FALSE,TRUE)
#define SAVECUSTOMERROREX2(cFunc,cMessage,nParm1,nParm2) Win32ErrorhandlerExEx2(cFunc,cMessage,(void*)nParm1,(void*)nParm2)

typedef struct _VFP2CERROR {
	unsigned long nErrorType; // one of VFP2C_ERRORTYPE_ defines
	unsigned long nErrorNo;
	char aErrorFunction[VFP2C_ERROR_FUNCTION_LEN];
	char aErrorMessage[VFP2C_ERROR_MESSAGE_LEN];
	char aSqlState[VFP2C_ODBC_STATE_LEN];
} VFP2CERROR, *LPVFP2CERROR;

#ifdef __cplusplus
extern "C" {
#endif

void _fastcall OnLoad();
void _fastcall OnUnload();

void _fastcall VFP2CSys(ParamBlk *parm);
void _fastcall AErrorEx(ParamBlk *parm);
void _fastcall FormatMessageEx(ParamBlk *parm);

// function forward definitions
void _stdcall Win32ErrorHandler(char *pFunction, DWORD nErrorNo, BOOL bAddError, BOOL bRaise);
void _stdcall Win32ErrorHandlerEx(char *pFunction, char *pErrorMessage, BOOL bAddError, BOOL bRaise);
void _stdcall Win32ErrorHandlerExEx(char *pFunction, char *pErrorMessage, DWORD nErrorNo, BOOL bAddError, BOOL bRaise);
void _stdcall Win32ErrorhandlerExEx2(char *pFunction, char *pErrorMessage, void *nParm1, void *nParm2);
void _stdcall RaiseError(int nErrorNo);

// extern definitions
extern HMODULE ghModule;
extern OSVERSIONINFOEX gsOSVerInfo;
extern VFP2CERROR gaErrorInfo[VFP2C_MAX_ERRORS];
extern DWORD gnErrorCount;
extern DWORD gnFoxVersion;

#ifdef __cplusplus
}
#endif

#endif // _VFP2C32_H__

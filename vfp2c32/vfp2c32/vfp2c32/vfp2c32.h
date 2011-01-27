#ifndef _VFP2C32_H__
#define _VFP2C32_H__

// filename of FLL
#ifndef _DEBUG
	#define FLLFILENAME "vfp2c32.fll"
#else
	#define FLLFILENAME "vfp2c32d.fll"
#endif

const unsigned int VFP2C_INIT_MARSHAL	= 0x00000001;
const unsigned int VFP2C_INIT_ENUM		= 0x00000002;
const unsigned int VFP2C_INIT_ASYNC		= 0x00000004;
const unsigned int VFP2C_INIT_FILE		= 0x00000008;
const unsigned int VFP2C_INIT_WINSOCK	= 0x00000010;
const unsigned int VFP2C_INIT_ODBC		= 0x00000020;
const unsigned int VFP2C_INIT_PRINT		= 0x00000040;
const unsigned int VFP2C_INIT_NETAPI	= 0x00000080;
const unsigned int VFP2C_INIT_CALLBACK	= 0x00000100;
const unsigned int VFP2C_INIT_SERVICES	= 0x00000200;
const unsigned int VFP2C_INIT_WINDOWS	= 0x00000400;
const unsigned int VFP2C_INIT_RAS		= 0x00000800;
const unsigned int VFP2C_INIT_IPHELPER	= 0x00001000;
const unsigned int VFP2C_INIT_URLMON	= 0x00002000;
const unsigned int VFP2C_INIT_WININET	= 0x00004000;
const unsigned int VFP2C_INIT_COM		= 0x00008000;

const unsigned int VFP2C_MAX_CALLBACKFUNCTION	= 1024;
const unsigned int VFP2C_MAX_CALLBACKBUFFER		= 2048;
const unsigned int VFP2C_MAX_FUNCTIONBUFFER		= 256;

const int VFP2C_MAX_ERRORS					= 24;
const unsigned int VFP2C_ERROR_MESSAGE_LEN	= 4096;
const unsigned int VFP2C_ERROR_FUNCTION_LEN	= 128;

const unsigned int VFP2C_ERRORTYPE_WIN32	= 1;
const unsigned int VFP2C_ERRORTYPE_ODBC		= 2;
const int VFP2C_ODBC_STATE_LEN				= 6;

const int E_APIERROR	= 12345678;

typedef struct _VFP2CERROR {
	unsigned int nErrorType; // one of VFP2C_ERRORTYPE_ constants
	unsigned long nErrorNo;
	char aErrorFunction[VFP2C_ERROR_FUNCTION_LEN];
	char aErrorMessage[VFP2C_ERROR_MESSAGE_LEN];
	char aSqlState[VFP2C_ODBC_STATE_LEN];
} VFP2CERROR, *LPVFP2CERROR;

// defines for error handling
// #define SAVEWIN32ERROR(cFunc,nErrorNo)		Win32ErrorHandler(#cFunc,nErrorNo,FALSE,FALSE)
// #define ADDWIN32ERROR(cFunc,nErrorNo)		Win32ErrorHandler(#cFunc,nErrorNo,TRUE,FALSE)
// #define RAISEWIN32ERROR(cFunc,nErrorNo)		Win32ErrorHandler(#cFunc,nErrorNo,FALSE,TRUE)
// #define SAVECUSTOMERROR(cFunc,cMessage)		Win32ErrorHandlerEx(cFunc,cMessage,FALSE,FALSE)
// #define ADDCUSTOMERROR(cFunc,cMessage)		Win32ErrorHandlerEx(cFunc,cMessage,TRUE,FALSE)
// #define RAISECUSTOMERROR(cFunc,cMessage)	Win32ErrorHandlerEx(cFunc,cMessage,FALSE,TRUE)
// #define SAVECUSTOMERROREX(cFunc,cMessage,nErrorNo)	Win32ErrorHandlerExEx(cFunc,cMessage,(DWORD)nErrorNo,FALSE,FALSE)
// #define ADDCUSTOMERROREX(cFunc,cMessage,nErrorNo)	Win32ErrorHandlerExEx(cFunc,cMessage,(DWORD)nErrorNo,TRUE,FALSE)
// #define RAISECUSTOMERROREX(cFunc,cMessage,nErrorNo) Win32ErrorHandlerExEx(cFunc,cMessage,(DWORD)nErrorNo,FALSE,TRUE)
// #define SAVECUSTOMERROREX2(cFunc,cMessage,nParm1,nParm2) Win32ErrorhandlerExEx2(cFunc,cMessage,(void*)nParm1,(void*)nParm2)

#ifdef __cplusplus
extern "C" {
#endif

void _fastcall OnLoad();
void _fastcall OnUnload();

void _fastcall VFP2CSys(ParamBlk *parm);
void _fastcall AErrorEx(ParamBlk *parm);
void _fastcall FormatMessageEx(ParamBlk *parm);

// function forward definitions
void _stdcall Win32ErrorHandler(char *pFunction, DWORD nErrorNo, bool bAddError, bool bRaise);
void _stdcall CustomErrorHandler(char *pFunction, char *pErrorMessage, bool bAddError, bool bRaise, va_list lpArgs);
void _stdcall CustomErrorHandlerEx(char *pFunction, char *pErrorMessage, int nErrorNo, bool bAddError, bool bRaise, va_list lpArgs);

void _cdecl SaveCustomError(char *pFunction, char *pMessage, ...); 
void _cdecl AddCustomError(char *pFunction, char *pMessage, ...);  
void _cdecl RaiseCustomError(char *pFunction, char *pMessage, ...);

void _cdecl SaveCustomErrorEx(char *pFunction, char *pMessage, int nErrorNo, ...);
void _cdecl AddCustomErrorEx(char *pFunction, char *pMessage, int nErrorNo, ...);
void _cdecl RaiseCustomErrorEx(char *pFunction, char *pMessage, int nErrorNo, ...);

// extern definitions
extern HMODULE ghModule;
extern VFP2CERROR gaErrorInfo[VFP2C_MAX_ERRORS];
extern int gnErrorCount;

#ifdef __cplusplus
}
#endif

inline void _stdcall RaiseError(int nErrorNo)
{
	if (nErrorNo == E_APIERROR)
		_UserError(gaErrorInfo[gnErrorCount].aErrorMessage);
	_Error(nErrorNo);
}

inline void ResetWin32Errors() { gnErrorCount = -1; }

inline void SaveWin32Error(char *pFunction, unsigned long nErrorNo) { Win32ErrorHandler(pFunction, nErrorNo, false, false); }
inline void AddWin32Error(char *pFunction, unsigned long nErrorNo) { Win32ErrorHandler(pFunction, nErrorNo, true, false); }
inline void RaiseWin32Error(char *pFunction, unsigned long nErrorNo) { Win32ErrorHandler(pFunction, nErrorNo, false, true); }

#endif // _VFP2C32_H__

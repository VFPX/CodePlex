#ifndef _VFP2CNETAPIEX_H__
#define _VFP2CNETAPIEX_H__

#ifndef _VFP2CNETAPI_H__
	#include <svrapi.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

// typedef's for runtime dynamic linking
typedef NET_API_STATUS (_stdcall *PNETFILEENUMEX)(const char*,const char*,short,char*,unsigned short,unsigned short*,unsigned short*); // NetFileEnum
#define NETAPI_INFO_SIZE_EX		1024

// function forward definitions
bool _stdcall VFP2C_Init_Netapiex();
void _stdcall VFP2C_Destroy_Netapiex();

void _fastcall ANetFilesEx(ParamBlk *parm);

#ifdef __cplusplus
}
#endif // end of extern "C"

#endif // _VFP2CNETAPI_H__
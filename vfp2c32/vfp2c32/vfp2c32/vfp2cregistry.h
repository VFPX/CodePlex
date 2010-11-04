#ifndef _VFP2CREGISTRY_H__
#define _VFP2CREGISTRY_H__

#include "vfp2ccppapi.h"

#ifdef __cplusplus
extern "C" {
#endif

// custom defines for Registry key/value enumeration
#define REG_ENUMCLASSNAME	1
#define REG_ENUMWRITETIME	2
#define REG_ENUMTYPE		1
#define REG_ENUMVALUE		2

#define REG_DELETE_NORMAL	1
#define REG_DELETE_SHELL	2

#define REG_INTEGER			12
#define REG_DOUBLE			13
#define REG_DATE			14
#define REG_DATETIME		15
#define REG_LOGICAL			16

#define REG_KEY_PREDEFINDED(hKey) (hKey == HKEY_CLASSES_ROOT || hKey == HKEY_CURRENT_CONFIG || \
					hKey == HKEY_CURRENT_USER || hKey == HKEY_LOCAL_MACHINE || \
				    hKey == HKEY_USERS || hKey == HKEY_DYN_DATA)

#define REG_KEY_STRING(hKeyType) (hKeyType == REG_SZ || hKeyType == REG_MULTI_SZ || hKeyType == REG_EXPAND_SZ)
#define REG_KEY_CHARACTER(hKeyType) (hKeyType == REG_SZ || hKeyType == REG_MULTI_SZ || hKeyType == REG_EXPAND_SZ || hKeyType == REG_BINARY)
#define REG_KEY_NUMERIC(hKeyType) (hKeyType == REG_DWORD || hKeyType == REG_QWORD || hKeyType == REG_INTEGER || hKeyType == REG_DOUBLE)

void _fastcall CreateRegistryKey(ParamBlk *parm);
void _fastcall DeleteRegistryKey(ParamBlk *parm);
void _fastcall OpenRegistryKey(ParamBlk *parm);
void _fastcall CloseRegistryKey(ParamBlk *parm);
void _fastcall ReadRegistryKey(ParamBlk *parm);
void _fastcall WriteRegistryKey(ParamBlk *parm);
void _fastcall ARegistryKeys(ParamBlk *parm);
void _fastcall ARegistryValues(ParamBlk *parm);
void _fastcall RegistryValuesToObject(ParamBlk *parm);
void _fastcall RegistryHiveToObject(ParamBlk *parm);
#pragma warning(disable : 4290) // disable warning 4290 - VC++ doesn't implement throw ...
void _stdcall RegistryHiveSubroutine(HKEY hKey, char *pKey, FoxObject& pObject) throw(int);

#ifdef __cplusplus
}
#endif // end of extern "C"

#endif // _VFP2CREGISTRY_H__
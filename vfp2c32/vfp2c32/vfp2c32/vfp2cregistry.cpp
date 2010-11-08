#include <windows.h>

#include "pro_ext.h"
#include "vfp2c32.h"
#include "vfpmacros.h"
#include "vfp2cutil.h"
#include "vfp2cregistry.h"
#include "vfp2ccppapi.h"
#include "vfp2chelpers.h"

void _fastcall CreateRegistryKey(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();
	
	HKEY hRoot = (HKEY)p1.ev_long;
	FoxString pKey(p2);
	REGSAM nKeyRights = (PCOUNT() < 3) ? KEY_ALL_ACCESS : p3.ev_long;
	DWORD nOptions = (PCOUNT() < 4) ? REG_OPTION_NON_VOLATILE : p4.ev_long;
	FoxString pClass(parm,5);
	
	RegistryKey hKey;

	hKey.Create(hRoot,pKey,pClass,nOptions,nKeyRights);
	Return((int)hKey.Detach());
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall DeleteRegistryKey(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	HKEY hRoot = (HKEY)p1.ev_long;
	FoxString pKey(p2);
	bool bShell = PCOUNT() == 2 || p3.ev_long != REG_DELETE_NORMAL;
	RegistryKey hKey;

	Return(hKey.Delete(hRoot,pKey,bShell));
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall OpenRegistryKey(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	HKEY hRoot = (HKEY)p1.ev_long;
	FoxString pKeyName(p2);
	REGSAM nKeyRights = (PCOUNT() == 2) ? KEY_ALL_ACCESS : (REGSAM)p3.ev_long;

	RegistryKey hKey;

	hKey.Open(hRoot,pKeyName,nKeyRights);
	Return((int)hKey.Detach());
}
catch(int nErrorNo)
{
		RaiseError(nErrorNo);
}
}

void _fastcall CloseRegistryKey(ParamBlk *parm)
{
	LONG nApiRet;

	RESETWIN32ERRORS();

	if ((nApiRet = RegCloseKey((HKEY)p1.ev_long)) != ERROR_SUCCESS)
	{
		SAVEWIN32ERROR(RegCloseKey,nApiRet);
		RaiseError(E_APIERROR);
	}
}

void _fastcall ReadRegistryKey(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();
	
	HKEY hRoot = (HKEY)p1.ev_long;
	FoxString pValue(parm,2);
	FoxString pKeyName(parm,3);

	FoxString pBuffer;
	RegistryKey hKey;

	DWORD nValueType, nValueTypeRet;
	char *pRegValue;

	hKey.Open(hRoot,pKeyName,KEY_QUERY_VALUE);
	pBuffer.Size(hKey.QueryValueInfo(pValue,nValueType));
	pRegValue = pBuffer;

	DWORD dwLen = pBuffer.Size();
	hKey.QueryValue(pValue,pBuffer,&dwLen);
	pBuffer.Len(dwLen);

	if (PCOUNT() == 4 && p4.ev_long)
		nValueTypeRet = p4.ev_long;
	else
		nValueTypeRet = nValueType;

	if (nValueTypeRet == REG_DWORD)
		Return(*(DWORD*)pRegValue);
	else if (nValueTypeRet == REG_QWORD)
		Return(*(unsigned __int64*)pRegValue);
	else if (nValueTypeRet == REG_INTEGER)
		Return(*(int*)pRegValue);
	else if (nValueTypeRet == REG_DOUBLE)
		Return(*(double*)pRegValue);
	else if (nValueTypeRet == REG_DATE)
	{
		FoxDate pDate;
		pDate = *(double*)pRegValue;
		pDate.Return();
	}
	else if (nValueTypeRet == REG_DATETIME)
	{
		FoxDateTime pDateTime;
		pDateTime = *(double*)pRegValue;
		pDateTime.Return();
	}
	else if (nValueTypeRet == REG_LOGICAL)
		Return((*(DWORD*)pRegValue) > 0);
	else
		pBuffer.Return();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall WriteRegistryKey(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	HKEY hRoot = (HKEY)p1.ev_long;
	
	FoxString pData(parm,2,0);
	FoxString pValueName(parm,3);
	FoxString pKeyName(parm,4);

	RegistryKey hKey;

	BYTE *pValueData;
	DWORD nValueSize, nValueType;
	DWORD nDWord;
	unsigned __int64 nQWord;

	if (PCOUNT() < 5 || p5.ev_long == 0)
	{
		if (Vartype(p2) == 'C')
			nValueType = REG_SZ;
		else if (Vartype(p2) == 'I')
			nValueType = REG_INTEGER;
		else if (Vartype(p2) == 'N')
			nValueType = REG_DOUBLE;
		else if (Vartype(p2) == 'D')
			nValueType = REG_DATE;
		else if (Vartype(p2) == 'T')
			nValueType = REG_DATETIME;
		else if (Vartype(p2) == 'L')
			nValueType = REG_LOGICAL;
		else
			throw E_INVALIDPARAMS;
	}
	else
		nValueType = (DWORD)p5.ev_long;

	if (Vartype(p2) == 'C')
	{
		if (REG_KEY_STRING(nValueType))
		{
			pData.Expand();
			pData.Len(pData.Len()+1);
		}
		pValueData = pData;
		nValueSize = pData.Len();
	}
	else if (Vartype(p2) == 'N')
	{
		if (nValueType == REG_DWORD)
		{
			nDWord = (DWORD)p2.ev_real;
			pValueData = (BYTE*)&nDWord;
			nValueSize = sizeof(DWORD);
		}
		else if (nValueType == REG_QWORD)
		{
			nQWord = (unsigned __int64)p2.ev_real;
            pValueData = (BYTE*)&nQWord;
			nValueSize = sizeof(unsigned __int64);
		}
		else if (nValueType == REG_DOUBLE)
		{
			pValueData = (BYTE*)&p2.ev_real;
			nValueSize = sizeof(double);
		}
		else if (nValueType == REG_INTEGER)
		{
			p2.ev_long = (int)p2.ev_real;
			pValueData = (BYTE*)&p2.ev_long;
			nValueSize = sizeof(int);
		}
	}
	else if (Vartype(p2) == 'I')
	{
		if (nValueType == REG_DWORD)
		{
			nDWord = (DWORD)p2.ev_long;
			pValueData = (BYTE*)&nDWord;
			nValueSize = sizeof(DWORD);
		}
		else if (nValueType == REG_QWORD)
		{
			nQWord = (unsigned __int64)p2.ev_long;
            pValueData = (BYTE*)&nQWord;
			nValueSize = sizeof(unsigned __int64);
		}
		else if (nValueType == REG_INTEGER)
		{
			pValueData = (BYTE*)&p2.ev_long;
			nValueSize = sizeof(int);
		}
		else if (nValueType == REG_DOUBLE)
		{
			p2.ev_real = (double)p2.ev_long;
			pValueData = (BYTE*)&p2.ev_real;
			nValueSize = sizeof(double);
		}
	}
	else if (Vartype(p2) == 'D')
	{
        pValueData = (BYTE*)&p2.ev_real;
		nValueSize = sizeof(double);
	}
	else if (Vartype(p2) == 'T')
	{
		pValueData = (BYTE*)&p2.ev_real;
		nValueSize = sizeof(double);
	}
	else if (Vartype(p2) == 'L')
	{
		pValueData = (BYTE*)&p2.ev_length;
		nValueSize = sizeof(DWORD);
	}
	else	
		throw E_INVALIDPARAMS;

	hKey.Open(hRoot,pKeyName,KEY_SET_VALUE);
	hKey.SetValue(pValueName,pValueData,nValueSize,nValueType);

	Return(1);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall ARegistryKeys(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	FoxArray pArray(p1);
	HKEY hRoot = (HKEY)p2.ev_long;
	FoxString pKeyName(p3);
	DWORD dwFlags = PCOUNT() == 4 ? (DWORD)p4.ev_long : 0;

	RegistryKey hKey;

	FoxString pKeyBuffer;
	FoxString pClassBuffer;
	FoxDateTime pTime;

	DWORD nSubKeys, nSubKeyMaxLen, nClassMaxLen, dwKeyLen, dwClassLen;;
	FILETIME sLastWrite;
	int nDimensions = 1, nWriteTimeDim;
	bool bEnumClassName, bEnumWriteTime, bRet;

	bEnumClassName = (dwFlags & REG_ENUMCLASSNAME) > 0;
	bEnumWriteTime = (dwFlags & REG_ENUMWRITETIME) > 0;
	
	if (bEnumClassName)
		nDimensions++;
	if (bEnumWriteTime)
	{
		nDimensions++;
		nWriteTimeDim = bEnumClassName ? 3 : 2;
	}

	hKey.Open(hRoot,pKeyName,KEY_QUERY_VALUE | KEY_ENUMERATE_SUB_KEYS);

	hKey.QueryInfo(0,0,&nSubKeys,&nSubKeyMaxLen,&nClassMaxLen);

	if (nSubKeys == 0)
	{
		Return(0);
		return;
	}

	pKeyBuffer.Size(nSubKeyMaxLen);
	pClassBuffer.Size(nClassMaxLen);

	dwKeyLen = pKeyBuffer.Size();
	dwClassLen = pClassBuffer.Size();

	pArray.Dimension(nSubKeys,nDimensions);

	bRet = hKey.EnumFirstKey(pKeyBuffer,&dwKeyLen,pClassBuffer,&dwClassLen,&sLastWrite);

	unsigned int nRow = 0;
	while (bRet)
	{
		pKeyBuffer.Len(dwKeyLen);
		pClassBuffer.Len(dwClassLen);

		nRow++;
		pArray(nRow,1) = pKeyBuffer;
		if (bEnumClassName)
			pArray(nRow,2) = pClassBuffer;
		if (bEnumWriteTime)
		{
			pArray(nRow,nWriteTimeDim) = pTime = sLastWrite;
		}

		dwKeyLen = pKeyBuffer.Size();
		dwClassLen = pClassBuffer.Size();
		
		bRet = hKey.EnumNextKey(pKeyBuffer,&dwKeyLen,pClassBuffer,&dwClassLen,&sLastWrite);
	}

	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall ARegistryValues(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	FoxArray pArray(p1);
	HKEY hRoot = (HKEY)p2.ev_long;
	FoxString pKeyName(p3);
	DWORD dwFlags = PCOUNT() == 4 ? (DWORD)p4.ev_long : 0;

	RegistryKey hKey;
	FoxString pValueName;
	FoxString pValue;
	FoxDate pDate;
	FoxDateTime pDateTime;
	LPBYTE pRegValue;
	DWORD nValues, nNameLen, nValueLen, nValueType;
	int nValueDim = 2, nDimensions = 1;
	bool bRegType, bRegValue, bRet;

	bRegType = (dwFlags & REG_ENUMTYPE) > 0;
	bRegValue = (dwFlags & REG_ENUMVALUE) > 0;
	if (bRegType)
	{
		nValueDim++;
		nDimensions++;
	}
	if (bRegValue)
		nDimensions++;

	hKey.Open(hRoot,pKeyName,KEY_QUERY_VALUE);
	hKey.QueryInfo(0,0,0,0,0,&nValues,&nNameLen,&nValueLen);

	if (nValues == 0)
	{
		Return(0);
		return;
	}

	pValueName.Size(nNameLen);
	if (bRegValue)
		pValue.Size(nValueLen);

	pRegValue = pValue;
	nValueLen = pValue.Size();

    pArray.Dimension(nValues,nDimensions);
	
	bRet = hKey.EnumFirstValue(pValueName,&nNameLen,pRegValue,&nValueLen,&nValueType);

	unsigned int nRow = 0;
	while (bRet)
	{
		nRow++;

		pValueName.Len(nNameLen);
		pArray(nRow,1) = pValueName;

		if (bRegType)
			pArray(nRow,2) = nValueType;

		if (bRegValue)
		{
			switch (nValueType)
			{
				case REG_SZ:
				case REG_MULTI_SZ:
				case REG_EXPAND_SZ:
				case REG_BINARY:
					pValue.Binary(nValueType == REG_BINARY);
					pValue.Len(nValueLen);
					pArray(nRow,nValueDim) = pValue;
					break;

				case REG_DWORD:
					pArray(nRow,nValueDim) = *(DWORD*)pRegValue;
					break;

				case REG_QWORD:
					pArray(nRow,nValueDim) = *(__int64*)pRegValue;
					break;

				case REG_INTEGER:
					pArray(nRow,nValueDim) = *(int*)pRegValue;
					break;
				
				case REG_DOUBLE:
					pArray(nRow,nValueDim) = *(double*)pRegValue;
					break;

				case REG_DATE:
					pArray(nRow,nValueDim) = pDate = *(double*)pRegValue;
					break;

				case REG_DATETIME:
					pArray(nRow,nValueDim) = pDateTime = *(double*)pRegValue;
					break;

				case REG_LOGICAL:
					pArray(nRow,nValueDim) = (*(DWORD*)pRegValue > 0);
					break;
			}
		}


		nNameLen = pValueName.Size();
		nValueLen = pValue.Size();

		bRet = hKey.EnumNextValue(pValueName,&nNameLen,pValue,&nValueLen,&nValueType);
	}

	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall RegistryValuesToObject(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	HKEY hRoot = (HKEY)p1.ev_long;
	FoxString pKeyName(p2);
	FoxObject pObject(p3);

	RegistryKey hKey;
	FoxString pValue;
	CStr pValueName;
	FoxDate pDate;
	FoxDateTime pDateTime;
	LPBYTE pRegValue;
	DWORD nValues, nValueNameLen, nValueLen, nValueType;
	bool bRet;

	// open key and query value information
	hKey.Open(hRoot,pKeyName,KEY_QUERY_VALUE);
	hKey.QueryInfo(0,0,0,0,0,&nValues,&nValueNameLen,&nValueLen);

	if (nValues == 0)
	{
		Return(0);
		return;
	}

	// allocate needed temporary buffers
	pValue.Size(nValueLen);
	pRegValue = pValue;
	pValueName.Size(nValueNameLen);
	nValueNameLen = pValueName.Size();

	// start enumeration
	bRet = hKey.EnumFirstValue(pValueName,&nValueNameLen,pValue,&nValueLen,&nValueType);

	while (bRet)
	{
		// convert value name to a valid VFP property name
		pValueName.RegValueToPropertyName();

		// store value into the object property
		switch(nValueType)
		{
			case REG_SZ:
			case REG_MULTI_SZ:
			case REG_EXPAND_SZ:
			case REG_BINARY:
				pValue.Binary(nValueType == REG_BINARY);
				pValue.Len(nValueLen);
				pObject(pValueName) = pValue;
				break;

			case REG_DWORD:
				pObject(pValueName) = *(DWORD*)pRegValue;
				break;

			case REG_QWORD:
				pObject(pValueName) = *(__int64*)pRegValue;
				break;

			case REG_INTEGER:
				pObject(pValueName) = *(int*)pRegValue;
				break;

			case REG_DOUBLE:
				pObject(pValueName) = *(double*)pRegValue;
				break;

			case REG_DATE:
				pObject(pValueName) = pDate = *(double*)pRegValue;
				break;

			case REG_DATETIME:
				pObject(pValueName) = pDateTime = *(double*)pRegValue;
				break;

			case REG_LOGICAL:
				pObject(pValueName) = (*(DWORD*)pRegValue) > 0;
				break;
		}

		// reassign max value(name) len to variables for the next enumeration
		nValueNameLen = pValueName.Size();
		nValueLen = pValue.Size();

		bRet = hKey.EnumNextValue(pValueName,&nValueNameLen,pValue,&nValueLen,&nValueType);
	}

	Return((int)nValues);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall RegistryHiveToObject(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();
	
	HKEY hRoot = (HKEY)p1.ev_long;
	FoxString pKeyName(p2);
	FoxObject pObject(p3);
	RegistryHiveSubroutine(hRoot,pKeyName,pObject);
	Return(1);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _stdcall RegistryHiveSubroutine(HKEY hRoot, char* pKey, FoxObject& pObject)
{
	RegistryKey hKey;
	FoxString pValue;
	FoxObject pObjectEx;
	FoxDate pDate;
	FoxDateTime pDateTime;
	CStr pName, pProperty, pSubKey;
	DWORD nValues, nValueNameLen, nValueLen, nValueType, nSubKeys, nSubKeyLen;
	LPBYTE pRegValue;
	bool bRet;

	hKey.Open(hRoot,pKey,KEY_QUERY_VALUE | KEY_ENUMERATE_SUB_KEYS);
	hKey.QueryInfo(0,0,&nSubKeys,&nSubKeyLen,0,&nValues,&nValueNameLen,&nValueLen);

	if (nValues > 0)
		pValue.Size(nValueLen);
	pRegValue = pValue;

	pName.Size(max(nSubKeyLen,nValueNameLen));
	if (nSubKeys > 0)
		pSubKey.Size(nSubKeyLen + strlen(pKey) + 1);
	
	pProperty.Size(pName.Size());
	
	if (nValues > 0)
	{
		bRet = hKey.EnumFirstValue(pName,&nValueNameLen,pValue,&nValueLen,&nValueType);

		while (bRet)
		{
			pProperty = pName.Len(nValueNameLen);
			pProperty.RegValueToPropertyName();

			switch(nValueType)
			{
				case REG_SZ:
				case REG_MULTI_SZ:
				case REG_EXPAND_SZ:
				case REG_BINARY:
					pValue.Binary(nValueType == REG_BINARY);
					pValue.Len(nValueLen);
					pObject(pProperty) = pValue;
					break;

				case REG_DWORD:
					pObject(pProperty) = *(DWORD*)pRegValue;
					break;

				case REG_QWORD:
					pObject(pProperty) = *(__int64*)pRegValue;
					break;

				case REG_INTEGER:
					pObject(pProperty) = *(int*)pRegValue;
					break;

				case REG_DOUBLE:
					pObject(pProperty) = *(double*)pRegValue;
					break;

				case REG_DATE:
					pObject(pProperty) = pDate = *(double*)pRegValue;
					break;

				case REG_DATETIME:
					pObject(pProperty) = pDateTime = *(double*)pRegValue;
					break;

				case REG_LOGICAL:
					pObject(pProperty) = (*(DWORD*)pRegValue) > 0;
					break;
			}

			nValueNameLen = pName.Size();
			nValueLen = pValue.Size();
			bRet = hKey.EnumNextValue(pName,&nValueNameLen,pValue,&nValueLen,&nValueType);
		}
	}

	if (nSubKeys > 0)
	{
		bRet = hKey.EnumFirstKey(pName,&nSubKeyLen);
		while (bRet)
		{
			pProperty = pName.Len(nSubKeyLen);
			pProperty.RegValueToPropertyName();
			pObjectEx.EmptyObject();
			pObject(pProperty) = pObjectEx;

			pSubKey = pKey;
			pSubKey += "\\";
			pSubKey += pName;

			RegistryHiveSubroutine(hRoot,pSubKey,pObjectEx);
			
			nSubKeyLen = pName.Size();
			bRet = hKey.EnumNextKey(pName,&nSubKeyLen);
		}
	}
}
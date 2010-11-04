#include "pro_ext.h"
#include "vfp2c32.h"
#include "vfp2cconv.h"
#include "vfp2cutil.h"
#include "vfpmacros.h"
#include "vfp2ccppapi.h"

void _fastcall PG_ByteA2Str(ParamBlk *parm)
{
	V_STRING(vRetVal);
	unsigned char *pInput = 0, *pInputOrig = 0, *pInputEnd, *pRetVal, *pRetValStart;
	int nErrorNo = 0, nMemoLen;

	if (Vartype(p1) == 'C')
	{
		if (!AllocHandleEx(vRetVal,p1.ev_length))
			RaiseError(E_INSUFMEMORY);

		pRetValStart = pRetVal = (unsigned char*)HandleToPtr(vRetVal);
		pInput = (unsigned char*)HandleToPtr(p1);
		pInputEnd = pInput + p1.ev_length;
	}
	else if (IsMemoRef(r1))
	{
		nMemoLen = GetMemoContentEx(&r1,(char**)&pInputOrig,&nErrorNo);
		if (nMemoLen == -1)
			goto ErrorOut;
		else if (nMemoLen == 0)
		{
			Return(vRetVal);
			return;
		}
		pInput = pInputOrig;
		pInputEnd = pInput + nMemoLen;

		if (!AllocHandleEx(vRetVal,nMemoLen))
		{
			nErrorNo = E_INSUFMEMORY;
			goto ErrorOut;
		}
		pRetValStart = pRetVal = (unsigned char*)HandleToPtr(vRetVal);
	}
	else
		RaiseError(E_INVALIDPARAMS);

	while (pInput < pInputEnd)
	{
		if (*pInput == '\\')
		{
			if	(pInput[1] >= '0' && pInput[1] <= '7' && 
				pInput[2] >= '0' && pInput[2] <= '7' &&
				pInput[3] >= '0' && pInput[3] <= '7')
			{
				*pRetVal++ = (pInput[1] - '0') * 64	+ (pInput[2] - '0') * 8 + (pInput[3] - '0');
				pInput += 4;
				continue;
			}
			else if (pInput[1] == '\\')
			{
				*pRetVal++ = '\\';
				pInput += 2;
			}
			else // unrecognized sequence after '\', just output as is ..
				*pRetVal++ = *pInput++;
		}
		else
			*pRetVal++ = *pInput++;
	}

	if (Vartype(p1) != 'C')
		free(pInputOrig);

	vRetVal.ev_length = pRetVal - pRetValStart;
	Return(vRetVal);
	return;

	ErrorOut:
		FreeHandle(vRetVal);
		if (pInputOrig)
			free(pInputOrig);
		RaiseError(nErrorNo);
}

void _fastcall PG_Str2ByteA(ParamBlk *parm)
{
	V_STRING(vRetVal);
	unsigned char *pInput = 0, *pInputOrig = 0, *pInputEnd, *pRetVal, *pRetValStart;
	int nErrorNo = 0, nMemoLen;
	BOOL bDouble = PCOUNT() == 2 ? p2.ev_length : FALSE;
	int nMemMulti = bDouble == FALSE ? 4 : 5;

	if (Vartype(p1) == 'C')
	{
		// allocate 4/5 times the space of the original which is the maximum size
		// the data can grow if all characters have to be translated to octal reprensentation
		if (!AllocHandleEx(vRetVal,p1.ev_length * nMemMulti))
			RaiseError(E_INSUFMEMORY);

		pRetValStart = pRetVal = (unsigned char*)HandleToPtr(vRetVal);
		pInput = (unsigned char*)HandleToPtr(p1);
		pInputEnd = pInput + p1.ev_length;
	}
	else if (IsMemoRef(r1))
	{
		nMemoLen = GetMemoContentEx(&r1,(char**)&pInputOrig,&nErrorNo);
		if (nMemoLen == -1)
			goto ErrorOut;
		else if (nMemoLen == 0)
		{
			Return(vRetVal);
			return;
		}
		pInput = pInputOrig;
		pInputEnd = pInput + nMemoLen;

		// 4/5 times .. see comment above ..
		if (!AllocHandleEx(vRetVal,nMemoLen * nMemMulti))
		{
			nErrorNo = E_INSUFMEMORY;
			goto ErrorOut;
		}
		pRetValStart = pRetVal = (unsigned char*)HandleToPtr(vRetVal);
	}
	else
		RaiseError(E_INVALIDPARAMS);

	while (pInput < pInputEnd)
	{
		if (*pInput < 32 || *pInput > 126 || *pInput == '\\' || *pInput == '\'')
		{
			if (bDouble)
				*pRetVal++ = '\\';

			*pRetVal++ = '\\';
			*pRetVal++ = '0' + (*pInput / 64) % 8;
			*pRetVal++ = '0' + (*pInput / 8) % 8;
			*pRetVal++ = '0' + *pInput % 8;
			pInput++;
		}
		else
			*pRetVal++ = *pInput++;
	}

	if (Vartype(p1) != 'C')
		free(pInputOrig);

	vRetVal.ev_length = pRetVal - pRetValStart;
	Return(vRetVal);
	return;

	ErrorOut:
		FreeHandle(vRetVal);
		if (pInputOrig)
			free(pInputOrig);
		RaiseError(nErrorNo);
}

void _fastcall RGB2Colors(ParamBlk *parm)
{
try
{
	FoxReference rRed(r2);
	FoxReference rGreen(r3);
	FoxReference rBlue(r4);

	rRed = (p1.ev_long & 0xFF);
	rGreen = (p1.ev_long >> 8 & 0xFF);
	rBlue = (p1.ev_long >> 16 & 0xFF);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall Colors2RGB(ParamBlk *parm)
{
	int nRGB;
	nRGB = p1.ev_long;
	nRGB += p2.ev_long << 8;
	nRGB += p3.ev_long << 16;
	Return(nRGB);
}

void _fastcall GetCursorPosEx(ParamBlk *parm)
{
try
{
	FoxReference rX(r1);
	FoxReference rY(r2);
	bool bRelative = PCOUNT() >= 3 && p3.ev_length;
	FoxString pWindow(parm,4);

	HWND hHwnd;
	POINT sPoint;

	if (!GetCursorPos(&sPoint))
	{
		SAVEWIN32ERROR(GetCursorPos,GetLastError());
		throw E_APIERROR;
	}

	if (bRelative)
	{
		if (PCOUNT() == 4)
		{
			if (Vartype(p4) == 'I' || Vartype(p4) == 'N')
				hHwnd = Vartype(p4) == 'I' ? (HWND)p4.ev_long : (HWND)(DWORD)p4.ev_real;
			else if (pWindow.Len())
				hHwnd = WHwndByTitle(pWindow);
			else
				throw E_INVALIDPARAMS;

			if (!ScreenToClient(hHwnd,&sPoint))
			{
				SAVEWIN32ERROR(ScreenToClient,GetLastError());
				throw E_APIERROR;
			}
		}
		else
		{
			if (!ScreenToClient(WTopHwnd(),&sPoint))
			{
				SAVEWIN32ERROR(ScreenToClient,GetLastError());
				throw E_APIERROR;
			}
		}
	}

	rX = sPoint.x;
	rY = sPoint.y;
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall Int64_Add(ParamBlk *parm)
{
	__int64 nOp1, nOp2;
	char aResult[VFP2C_MAX_BIGINT_LITERAL+1];

	if (Vartype(p1) == 'C')
	{
		if (!NullTerminateValue(p1))
			RaiseError(E_INSUFMEMORY);
		nOp1 = StringToInt64(HandleToPtr(p1));
	}
	else if (Vartype(p1) == 'I')
		nOp1 = (__int64)p1.ev_long;
	else if (Vartype(p1) == 'N')
		nOp1 = (__int64)p1.ev_real;
	else 
		RaiseError(E_INVALIDPARAMS);

	if (Vartype(p2) == 'C')
	{
		if (!NullTerminateValue(p2))
			RaiseError(E_INSUFMEMORY);
		nOp2 = StringToInt64(HandleToPtr(p2));
	}
	else if (Vartype(p2) == 'I')
		nOp2 = (__int64)p2.ev_long;
	else if (Vartype(p1) == 'N')
		nOp2 = (__int64)p2.ev_real;
	else 
		RaiseError(E_INVALIDPARAMS);

	Int64ToString(aResult,nOp1 + nOp2);
	_RetChar(aResult);
}

void _fastcall Int64_Sub(ParamBlk *parm)
{
	__int64 nOp1, nOp2;
	char aResult[VFP2C_MAX_BIGINT_LITERAL+1];

	if (Vartype(p1) == 'C')
	{
		if (!NullTerminateValue(p1))
			RaiseError(E_INSUFMEMORY);
		nOp1 = StringToInt64(HandleToPtr(p1));
	}
	else if (Vartype(p1) == 'I')
		nOp1 = (__int64)p1.ev_long;
	else if (Vartype(p1) == 'N')
		nOp1 = (__int64)p1.ev_real;
	else 
		RaiseError(E_INVALIDPARAMS);

	if (Vartype(p2) == 'C')
	{
		if (!NullTerminateValue(p2))
			RaiseError(E_INSUFMEMORY);
		nOp2 = StringToInt64(HandleToPtr(p2));
	}
	else if (Vartype(p2) == 'I')
		nOp2 = (__int64)p2.ev_long;
	else if (Vartype(p1) == 'N')
		nOp2 = (__int64)p2.ev_real;
	else 
		RaiseError(E_INVALIDPARAMS);

	Int64ToString(aResult,nOp1 - nOp2);
	_RetChar(aResult);
}

void _fastcall Int64_Mul(ParamBlk *parm)
{
	__int64 nOp1, nOp2;
	char aResult[VFP2C_MAX_BIGINT_LITERAL+1];

	if (Vartype(p1) == 'C')
	{
		if (!NullTerminateValue(p1))
			RaiseError(E_INSUFMEMORY);
		nOp1 = StringToInt64(HandleToPtr(p1));
	}
	else if (Vartype(p1) == 'I')
		nOp1 = (__int64)p1.ev_long;
	else if (Vartype(p1) == 'N')
		nOp1 = (__int64)p1.ev_real;
	else 
		RaiseError(E_INVALIDPARAMS);

	if (Vartype(p2) == 'C')
	{
		if (!NullTerminateValue(p2))
			RaiseError(E_INSUFMEMORY);
		nOp2 = StringToInt64(HandleToPtr(p2));
	}
	else if (Vartype(p2) == 'I')
		nOp2 = (__int64)p2.ev_long;
	else if (Vartype(p1) == 'N')
		nOp2 = (__int64)p2.ev_real;
	else 
		RaiseError(E_INVALIDPARAMS);

	Int64ToString(aResult,nOp1 * nOp2);
	_RetChar(aResult);
}

void _fastcall Int64_Div(ParamBlk *parm)
{
	__int64 nOp1, nOp2;
	char aResult[VFP2C_MAX_BIGINT_LITERAL+1];

	if (Vartype(p1) == 'C')
	{
		if (!NullTerminateValue(p1))
			RaiseError(E_INSUFMEMORY);
		nOp1 = StringToInt64(HandleToPtr(p1));
	}
	else if (Vartype(p1) == 'I')
		nOp1 = (__int64)p1.ev_long;
	else if (Vartype(p1) == 'N')
		nOp1 = (__int64)p1.ev_real;
	else 
		RaiseError(E_INVALIDPARAMS);

	if (Vartype(p2) == 'C')
	{
		if (!NullTerminateValue(p2))
			RaiseError(E_INSUFMEMORY);
		nOp2 = StringToInt64(HandleToPtr(p2));
	}
	else if (Vartype(p2) == 'I')
		nOp2 = (__int64)p2.ev_long;
	else if (Vartype(p1) == 'N')
		nOp2 = (__int64)p2.ev_real;
	else 
		RaiseError(E_INVALIDPARAMS);

	Int64ToString(aResult,nOp1 / nOp2);
	_RetChar(aResult);
}

void _fastcall Int64_Mod(ParamBlk *parm)
{
	__int64 nOp1, nOp2;
	char aResult[VFP2C_MAX_BIGINT_LITERAL+1];

	if (Vartype(p1) == 'C')
	{
		if (!NullTerminateValue(p1))
			RaiseError(E_INSUFMEMORY);
		nOp1 = StringToInt64(HandleToPtr(p1));
	}
	else if (Vartype(p1) == 'I')
		nOp1 = (__int64)p1.ev_long;
	else if (Vartype(p1) == 'N')
		nOp1 = (__int64)p1.ev_real;
	else 
		RaiseError(E_INVALIDPARAMS);

	if (Vartype(p2) == 'C')
	{
		if (!NullTerminateValue(p2))
			RaiseError(E_INSUFMEMORY);
		nOp2 = StringToInt64(HandleToPtr(p2));
	}
	else if (Vartype(p2) == 'I')
		nOp2 = (__int64)p2.ev_long;
	else if (Vartype(p1) == 'N')
		nOp2 = (__int64)p2.ev_real;
	else 
		RaiseError(E_INVALIDPARAMS);

	Int64ToString(aResult,nOp1 % nOp2);
	_RetChar(aResult);
}

void _fastcall Value2Variant(ParamBlk *parm)
{
	V_STRINGN(vVariant,sizeof(VALUEEX));
	VALUEEX vData = {0};
	char *pVariant;
	int nSize = 0;

	vData.ev_type = p1.ev_type;

	switch(p1.ev_type)
	{
		case 'I':
			vData.ev_long = p1.ev_long;
			vData.ev_width = (unsigned char)p1.ev_width;
			break;

		case 'N':
			vData.ev_real = p1.ev_real;
			vData.ev_width = (unsigned char)p1.ev_width;
			vData.ev_decimals = (unsigned char)p1.ev_length;
			break;

		case 'C':
			vVariant.ev_length += nSize = vData.ev_length = p1.ev_length;
			break;

		case 'L':
			vData.ev_length = p1.ev_length;
			break;

		case 'T':
		case 'D':
			vData.ev_real = p1.ev_real;
			break;

		case 'Y':
			vData.ev_currency.QuadPart = p1.ev_currency.QuadPart;
			break;
		
		case '0':
			break;

		default:
			RaiseError(E_INVALIDPARAMS);
	}

	if (!AllocHandleEx(vVariant,vVariant.ev_length))
		RaiseError(E_INSUFMEMORY);

	pVariant = HandleToPtr(vVariant);

	memcpy(pVariant,&vData,sizeof(VALUEEX));
	if (nSize)
	{
		memcpy(pVariant+sizeof(VALUEEX),HandleToPtr(p1),nSize);
	}

	Return(vVariant);
}

void _fastcall Variant2Value(ParamBlk *parm)
{
	V_VALUE(vVariant);
	LPVALUEEX pData;
	char *pContent = 0;
	int nErrorNo;

	if (IsMemoRef(r1))
	{
		if (GetMemoContentEx(&r1,&pContent,&nErrorNo) == -1)
			RaiseError(nErrorNo);
		pData = (LPVALUEEX)pContent;
	}
	else if (Vartype(p1) == 'C')
	{
		pData = (LPVALUEEX)HandleToPtr(p1);
	}
	else
		RaiseError(E_INVALIDPARAMS);

	vVariant.ev_type = pData->ev_type;

	switch(pData->ev_type)
	{
		case 'I':
			vVariant.ev_long = pData->ev_long;
			vVariant.ev_width = pData->ev_width;
			break;

		case 'N':
			vVariant.ev_real = pData->ev_real;
			vVariant.ev_width = pData->ev_width;
			vVariant.ev_length = pData->ev_decimals;
			break;

		case 'C':
			vVariant.ev_length = pData->ev_length; // len of data
			vVariant.ev_width = pData->ev_width;   // binary or character?
			
			if (!AllocHandleEx(vVariant,vVariant.ev_length))
				RaiseError(E_INSUFMEMORY);

			if (p1.ev_type == 'C')
				memcpy(HandleToPtr(vVariant),++pData,vVariant.ev_length);
			else
				memcpy(HandleToPtr(vVariant),pContent+sizeof(VALUEEX),vVariant.ev_length);
			break;

		case 'L':
			vVariant.ev_length = pData->ev_length;
			break;

		case 'T':
		case 'D':
			vVariant.ev_real = pData->ev_real;
			break;

		case 'Y':
			vVariant.ev_currency.QuadPart = pData->ev_currency.QuadPart;
			break;
		
		case '0':
			break;

		default:
			if (IsMemoRef(r1))
				free(pContent);
			RaiseError(E_INVALIDPARAMS);
	}

	if (IsMemoRef(r1))
	{
		if (pContent)
			free(pContent);
	}

	Return(vVariant);

}

/* its as simple as that :) */
void _fastcall Decimals(ParamBlk *parm)
{
	Return((int)p1.ev_length);
}

void _fastcall Num2Binary(ParamBlk *parm)
{
try
{
	int nNum = p1.ev_long;
	FoxString vBin(32);
	char *pBin;

	vBin.Len(32);
	pBin = vBin;
	pBin += 31;

	for (int xj = 0; xj <= 31; xj++)
	{
		*pBin = (nNum & 1) ? '1' : '0';
		pBin--;
		nNum >>= 1;
	}

	vBin.Return();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall CreatePublicShadowObjReference(ParamBlk *parm)
{
try
{
	FoxString pVarname(p1);
	Locator sVar;
	NewVar(pVarname,sVar,true);
	Store(sVar,p2);
	ObjectRelease(p2);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall ReleasePublicShadowObjReference(ParamBlk *parm)
{
try
{
    V_VALUE(vObject);
    FoxString pVarname(p1);
    Evaluate(vObject, pVarname);
    ReleaseVar(pVarname);
}
catch(int nErrorNo)
{
    RaiseError(nErrorNo);
}
} 

void _fastcall GetLocaleInfoExLib(ParamBlk *parm)
{
try
{
	int nApiRet;
	FoxString pLocaleInfo(256);
	
	LCTYPE nType = (LCTYPE)p1.ev_long;
	LCID nLocale = PCOUNT() >= 2 ? (LCID)p2.ev_long : LOCALE_USER_DEFAULT;

	nApiRet = GetLocaleInfo(nLocale, nType, pLocaleInfo, pLocaleInfo.Size());
	if (nApiRet == 0)
	{
		SAVEWIN32ERROR(GetLocaleInfo,GetLastError());
		throw E_APIERROR;
	}

	pLocaleInfo.Len(nApiRet-1);
	pLocaleInfo.Return();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall StrtranEx(ParamBlk *parm)
{
try
{
	FoxString sSearchIn(p1);
	FoxString sSearchFor(p2);
	FoxString sReplacement(p3);

	sSearchIn.Strtran(sSearchFor,sReplacement);
	sSearchIn.Return();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}
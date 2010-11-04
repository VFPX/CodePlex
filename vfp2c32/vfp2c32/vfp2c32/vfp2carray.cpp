#include "pro_ext.h"
#include "vfp2c32.h"
#include "vfp2carray.h"
#include "vfp2cutil.h"
#include "vfpmacros.h"
#include "vfp2ccppapi.h"

void _fastcall ASplitStr(ParamBlk *parm)
{
try
{
	unsigned char *pSubString;
	int nRows, nRemain, nSubStrLen = p3.ev_long;

	if (nSubStrLen <= 0)
		throw E_INVALIDPARAMS;

	if (!p2.ev_length)
	{
		Return(0);
		return;
	}

	FoxArray pArray(p1);
	FoxString pString(p2,0);
	FoxString pBuffer(nSubStrLen);
	pBuffer.Len(nSubStrLen);

	pSubString = pString;
	nRows = pString.Len() / nSubStrLen;
	nRemain = pString.Len() % nSubStrLen;

	pArray.Dimension(nRows + (nRemain ? 1 : 0), 1);

	for (int xj = 1; xj <= nRows; xj++)
	{
		pArray(xj) = pBuffer.CopyBytes(pSubString,nSubStrLen);
		pSubString += nSubStrLen;
	}

	if (nRemain)
	{
		pBuffer.Len(nRemain);
		pArray(++xj) = pBuffer.CopyBytes(pSubString,nRemain);
	}

	pArray.ReturnRows();
}
catch (int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall ASum(ParamBlk *parm)
{
	double nSum;
	CCY nSumCur;
	int nRows, nDims, nErrorNo;
	unsigned short *pRowPtr;
	char cType;
	V_VALUE(vValue);

	if (nErrorNo = ASubscripts(&r1,&nRows,&nDims))
		goto ErrorOut;

	if (PCOUNT() == 1)
        p2.ev_long = 1;
	else if (p2.ev_long < 0)
		RaiseError(E_INVALIDPARAMS);

	if (PCOUNT() == 2 && !VALID_ADIM(nDims,p2.ev_long))
		RaiseError(E_INVALIDSUBSCRIPT);

	if (PCOUNT() == 1 || p2.ev_long || !nDims)
	{
		RESETARRAY(r1,nDims);
		ADIM(r1) = (USHORT)p2.ev_long;
		pRowPtr = &AROW(r1);
	}
	else
	{
		RESETARRAY(r1,2);
		AROW(r1) = 1;
		nRows *= nDims;
		pRowPtr = &ADIM(r1);
	}

    while (++(*pRowPtr) <= nRows)
	{
		if (nErrorNo = _Load(&r1, &vValue))
			goto ErrorOut;

		if (Vartype(vValue) == 'N' || Vartype(vValue) == 'Y')
		{
			cType = Vartype(vValue);
			if (Vartype(vValue) == 'N')
				nSum = vValue.ev_real;
			else
				nSumCur.QuadPart = vValue.ev_currency.QuadPart;
			break;
		}
		else if (Vartype(vValue) == '0');
		else
		{
			nErrorNo = E_INVALIDPARAMS;
			goto ErrorOut;
		}
	}

	if (*pRowPtr > nRows)
	{
		Return(vValue);
		return;
	}

	for (++(*pRowPtr); *pRowPtr <= nRows; (*pRowPtr)++)
	{
		if (nErrorNo = _Load(&r1, &vValue))
			goto ErrorOut;

		if (Vartype(vValue) == cType)
		{
			if (cType == 'N')
				nSum += vValue.ev_real;
			else
				nSumCur.QuadPart += vValue.ev_currency.QuadPart;
		}
		else if (Vartype(vValue) == '0');
		else
		{
			nErrorNo = E_INVALIDPARAMS;
			goto ErrorOut;
		}
	}

	if (cType == 'N')
		Return(nSum);
	else
		Return(nSumCur);
	return;

	ErrorOut:
		ReleaseValue(vValue);
		RaiseError(nErrorNo);
}

void _fastcall AAverage(ParamBlk *parm)
{
	double nSum;
	CCY nSumCur;
	int nRows, nDims, nErrorNo;
	unsigned short *pRowPtr;
	char cType;
	V_VALUE(vValue);

	if (nErrorNo = ASubscripts(&r1,&nRows,&nDims))
		goto ErrorOut;

	if (PCOUNT() == 1)
        p2.ev_long = 1;
	else if (p2.ev_long < 0)
		RaiseError(E_INVALIDPARAMS);

	if (PCOUNT() == 2 && !VALID_ADIM(nDims,p2.ev_long))
		RaiseError(E_INVALIDSUBSCRIPT);

	if (PCOUNT() == 1 || p2.ev_long || !nDims)
	{
		RESETARRAY(r1,nDims);
		ADIM(r1) = (USHORT)p2.ev_long;
		pRowPtr = &AROW(r1);
	}
	else
	{
		RESETARRAY(r1,2);
		AROW(r1) = 1;
		nRows *= nDims;
		pRowPtr = &ADIM(r1);
	}

    while (++(*pRowPtr) <= nRows)
	{
		if (nErrorNo = _Load(&r1, &vValue))
			goto ErrorOut;

		if (Vartype(vValue) == 'N' || Vartype(vValue) == 'Y')
		{
			cType = Vartype(vValue);
			if (Vartype(vValue) == 'N')
				nSum = vValue.ev_real;
			else
				nSumCur.QuadPart = vValue.ev_currency.QuadPart;
			break;
		}
		else if (Vartype(vValue) == '0');
		else
		{
			nErrorNo = E_INVALIDPARAMS;
			goto ErrorOut;
		}
	}

	if (*pRowPtr > nRows)
	{
		Return(vValue);
		return;
	}

    for (++(*pRowPtr); *pRowPtr <= nRows; (*pRowPtr)++)
	{
		if (nErrorNo = _Load(&r1, &vValue))
				goto ErrorOut;

		if (Vartype(vValue) == cType)
		{
			if (cType == 'N')
				nSum += vValue.ev_real;
			else
				nSumCur.QuadPart += vValue.ev_currency.QuadPart;
		}
		else if (Vartype(vValue) == '0');
		else
		{
			nErrorNo = E_INVALIDPARAMS;
			goto ErrorOut;
		}
	}

	if (cType == 'N')
		Return(nSum / (double)nRows);
	else
	{
		nSumCur.QuadPart /= nRows;
		Return(nSumCur);
	}
	return;

	ErrorOut:
		ReleaseValue(vValue);
		RaiseError(nErrorNo);
}

void _fastcall AMax(ParamBlk *parm)
{
	double nMax;
	CCY nMaxCur;
	int nRows, nDims, nErrorNo;
	unsigned short *pRowPtr;
	char cType;
	V_VALUE(vValue);

	if (nErrorNo = ASubscripts(&r1,&nRows,&nDims))
		goto ErrorOut;

	if (PCOUNT() == 1)
        p2.ev_long = 1;
	else if (p2.ev_long < 0)
		RaiseError(E_INVALIDPARAMS);

	if (PCOUNT() == 2 && !VALID_ADIM(nDims,p2.ev_long))
		RaiseError(E_INVALIDSUBSCRIPT);

	if (PCOUNT() == 1 || p2.ev_long || !nDims)
	{
		RESETARRAY(r1,nDims);
		ADIM(r1) = (USHORT)p2.ev_long;
		pRowPtr = &AROW(r1);
	}
	else
	{
		RESETARRAY(r1,2);
		AROW(r1) = 1;
		nRows *= nDims;
		pRowPtr = &ADIM(r1);
	}

	while (++(*pRowPtr) <= nRows)
	{
		if (nErrorNo = _Load(&r1, &vValue))
			goto ErrorOut;

		if (Vartype(vValue) == 'N' || Vartype(vValue) == 'D' || Vartype(vValue) == 'T' || Vartype(vValue) == 'Y')
		{
			if (Vartype(vValue) == 'Y')
				nMaxCur.QuadPart = vValue.ev_currency.QuadPart;
			else
				nMax = vValue.ev_real;
			cType = Vartype(vValue);
			break;
		}
		else if (Vartype(vValue) == '0');
		else
		{
			nErrorNo = E_INVALIDPARAMS;
			goto ErrorOut;
		}
	}
		
	// all rows were .NULL.
	if (*pRowPtr > nRows)
	{
		Return(vValue);
		return;
	}

	for (++(*pRowPtr); *pRowPtr <= nRows; (*pRowPtr)++)
	{
		if (nErrorNo = _Load(&r1, &vValue))
			goto ErrorOut;

		if (Vartype(vValue) == cType)
		{
			if (cType != 'Y')
			{
				if (nMax < vValue.ev_real)
					nMax = vValue.ev_real;
			}
			else
			{
				if (nMaxCur.QuadPart < vValue.ev_currency.QuadPart)
					nMaxCur.QuadPart = vValue.ev_currency.QuadPart;
			}
		}
		else if (Vartype(vValue) == '0');
		else
		{
			nErrorNo = E_INVALIDPARAMS;
			goto ErrorOut;
		}
	}
	
	if (cType == 'N')
		Return(nMax);
	else 
	{
		vValue.ev_type = cType;
		if (cType != 'Y')
			vValue.ev_real = nMax;
		else
			vValue.ev_currency.QuadPart = nMaxCur.QuadPart;
		
		Return(vValue);
	}
	
	return;

	ErrorOut:
		ReleaseValue(vValue);
		RaiseError(nErrorNo);
}

void _fastcall AMin(ParamBlk *parm)
{
	double nMin;
	CCY nMinCur;
	int nRows, nDims, nErrorNo;
	unsigned short *pRowPtr;
	char cType;
	V_VALUE(vValue);

	if (nErrorNo = ASubscripts(&r1,&nRows,&nDims))
		goto ErrorOut;

	if (PCOUNT() == 1)
        p2.ev_long = 1;
	else if (p2.ev_long < 0)
		RaiseError(E_INVALIDPARAMS);

	if (PCOUNT() == 2 && !VALID_ADIM(nDims,p2.ev_long))
		RaiseError(E_INVALIDSUBSCRIPT);

	if (PCOUNT() == 1 || p2.ev_long || !nDims)
	{
		RESETARRAY(r1,nDims);
		ADIM(r1) = (USHORT)p2.ev_long;
		pRowPtr = &AROW(r1);
	}
	else
	{
		RESETARRAY(r1,2);
		AROW(r1) = 1;
		nRows *= nDims;
		pRowPtr = &ADIM(r1);
	}

	while (++(*pRowPtr) <= nRows)
	{
		if (nErrorNo = _Load(&r1, &vValue))
			goto ErrorOut;

		if (Vartype(vValue) == 'N' || Vartype(vValue) == 'D' || Vartype(vValue) == 'T' || Vartype(vValue) == 'Y')
		{
			if (Vartype(vValue) == 'Y')
				nMinCur.QuadPart = vValue.ev_currency.QuadPart;
			else
				nMin = vValue.ev_real;
			cType = Vartype(vValue);
			break;
		}
		else if (Vartype(vValue) == '0');
		else
		{
			nErrorNo = E_INVALIDPARAMS;
			goto ErrorOut;
		}
	}
		
	// all rows were .NULL.
	if (*pRowPtr > nRows)
	{
		Return(vValue);
		return;
	}

	for (++(*pRowPtr); *pRowPtr <= nRows; (*pRowPtr)++)
	{
		if (nErrorNo = _Load(&r1, &vValue))
			goto ErrorOut;

		if (Vartype(vValue) == cType)
		{
			if (cType != 'Y')
			{
				if (nMin > vValue.ev_real)
					nMin = vValue.ev_real;
			}
			else
			{
				if (nMinCur.QuadPart > vValue.ev_currency.QuadPart)
					nMinCur.QuadPart = vValue.ev_currency.QuadPart;
			}
		}
		else if (Vartype(vValue) == '0');
		else
		{
			nErrorNo = E_INVALIDPARAMS;
			goto ErrorOut;
		}
	}

	if (cType == 'N')
		Return(nMin);
	else if (cType == 'Y')
	{
		vValue.ev_type = cType;
		vValue.ev_currency.QuadPart = nMinCur.QuadPart;
		Return(vValue);
	}
	else
	{
		vValue.ev_type = cType;
		vValue.ev_real = nMin;
		Return(vValue);
	}
	return;

	ErrorOut:
		ReleaseValue(vValue);
		RaiseError(nErrorNo);
}
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
		pArray(xj) = pBuffer.CopyBytes(pSubString, nSubStrLen);
		pSubString += nSubStrLen;
	}

	if (nRemain)
		pArray(++xj) = pBuffer.CopyBytes(pSubString, nRemain);

	pArray.ReturnRows();
}
catch (int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall ASum(ParamBlk *parm)
{
try
{
	double nSum;
	CCY nSumCur;
	int nRows, nDims, nErrorNo;
	unsigned short *pRowPtr;
	char cType;
	FoxValue vValue;

	if (nErrorNo = ASubscripts(&r1,&nRows,&nDims))
		throw nErrorNo;

	if (PCOUNT() == 1)
        p2.ev_long = 1;
	else if (p2.ev_long < 0)
		throw E_INVALIDPARAMS;

	if (PCOUNT() == 2 && !VALID_ADIM(nDims,p2.ev_long))
		throw E_INVALIDSUBSCRIPT;

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
		vValue.Load(r1);

		if (vValue.Vartype() == 'N' || vValue.Vartype() == 'Y')
		{
			cType = vValue.Vartype();
			if (cType == 'N')
				nSum = vValue->ev_real;
			else
				nSumCur.QuadPart = vValue->ev_currency.QuadPart;
			break;
		}
		else if (vValue.Vartype() == '0');
		else
			throw E_INVALIDPARAMS;
	}

	if (*pRowPtr > nRows)
	{
		vValue.Return();
		return;
	}

	for (++(*pRowPtr); *pRowPtr <= nRows; (*pRowPtr)++)
	{
		vValue.Load(r1);

		if (vValue.Vartype() == cType)
		{
			if (cType == 'N')
				nSum += vValue->ev_real;
			else
				nSumCur.QuadPart += vValue->ev_currency.QuadPart;
		}
		else if (vValue.Vartype() == '0');
		else
			throw E_INVALIDPARAMS;
	}

	if (cType == 'N')
		Return(nSum);
	else
		Return(nSumCur);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall AAverage(ParamBlk *parm)
{
try
{
	double nSum;
	CCY nSumCur;
	int nRows, nDims, nErrorNo;
	unsigned short *pRowPtr;
	char cType;
	FoxValue vValue;

	if (nErrorNo = ASubscripts(&r1,&nRows,&nDims))
		throw nErrorNo;

	if (PCOUNT() == 1)
        p2.ev_long = 1;
	else if (p2.ev_long < 0)
		throw E_INVALIDPARAMS;

	if (PCOUNT() == 2 && !VALID_ADIM(nDims,p2.ev_long))
		throw E_INVALIDSUBSCRIPT;

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
		vValue.Load(r1);

		if (vValue.Vartype() == 'N' || vValue.Vartype() == 'Y')
		{
			cType = vValue.Vartype();
			if (cType == 'N')
				nSum = vValue->ev_real;
			else
				nSumCur.QuadPart = vValue->ev_currency.QuadPart;
			break;
		}
		else if (vValue.Vartype() == '0');
		else
			throw E_INVALIDPARAMS;
	}

	if (*pRowPtr > nRows)
	{
		vValue.Return();
		return;
	}

    for (++(*pRowPtr); *pRowPtr <= nRows; (*pRowPtr)++)
	{
		vValue.Load(r1);

		if (vValue.Vartype() == cType)
		{
			if (cType == 'N')
				nSum += vValue->ev_real;
			else
				nSumCur.QuadPart += vValue->ev_currency.QuadPart;
		}
		else if (vValue.Vartype() == '0');
		else
			throw E_INVALIDPARAMS;
	}

	if (cType == 'N')
		Return(nSum / (double)nRows);
	else
	{
		nSumCur.QuadPart /= nRows;
		Return(nSumCur);
	}
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall AMax(ParamBlk *parm)
{
try
{
	double nMax;
	CCY nMaxCur;
	int nRows, nDims, nErrorNo;
	unsigned short *pRowPtr;
	char cType;
	FoxValue vValue;

	if (nErrorNo = ASubscripts(&r1,&nRows,&nDims))
		throw nErrorNo;

	if (PCOUNT() == 1)
        p2.ev_long = 1;
	else if (p2.ev_long < 0)
		throw E_INVALIDPARAMS;

	if (PCOUNT() == 2 && !VALID_ADIM(nDims,p2.ev_long))
		throw E_INVALIDSUBSCRIPT;

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
		vValue.Load(r1);

		if (vValue.Vartype() == 'N' || vValue.Vartype() == 'D' || vValue.Vartype() == 'T' || vValue.Vartype() == 'Y')
		{
			cType = vValue.Vartype();
			if (cType == 'Y')
				nMaxCur.QuadPart = vValue->ev_currency.QuadPart;
			else
				nMax = vValue->ev_real;
			break;
		}
		else if (vValue.Vartype() == '0');
		else
			throw E_INVALIDPARAMS;
	}
		
	// all rows were .NULL.
	if (*pRowPtr > nRows)
	{
		vValue.Return();
		return;
	}

	for (++(*pRowPtr); *pRowPtr <= nRows; (*pRowPtr)++)
	{
		vValue.Load(r1);

		if (vValue.Vartype() == cType)
		{
			if (cType != 'Y')
			{
				if (nMax < vValue->ev_real)
					nMax = vValue->ev_real;
			}
			else
			{
				if (nMaxCur.QuadPart < vValue->ev_currency.QuadPart)
					nMaxCur.QuadPart = vValue->ev_currency.QuadPart;
			}
		}
		else if (vValue.Vartype() == '0');
		else
			throw E_INVALIDPARAMS;
	}
	
	if (cType == 'N')
		Return(nMax);
	else 
	{
		vValue->ev_type = cType;
		if (cType != 'Y')
			vValue->ev_real = nMax;
		else
			vValue->ev_currency.QuadPart = nMaxCur.QuadPart;
		vValue.Return();
	}
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall AMin(ParamBlk *parm)
{
try
{
	double nMin;
	CCY nMinCur;
	int nRows, nDims, nErrorNo;
	unsigned short *pRowPtr;
	char cType;
	FoxValue vValue;

	if (nErrorNo = ASubscripts(&r1,&nRows,&nDims))
		throw nErrorNo;

	if (PCOUNT() == 1)
        p2.ev_long = 1;
	else if (p2.ev_long < 0)
		throw E_INVALIDPARAMS;

	if (PCOUNT() == 2 && !VALID_ADIM(nDims,p2.ev_long))
		throw E_INVALIDSUBSCRIPT;

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
		vValue.Load(r1);

		if (vValue.Vartype() == 'N' || vValue.Vartype() == 'D' || vValue.Vartype() == 'T' || vValue.Vartype() == 'Y')
		{
			cType = vValue.Vartype();
			if (cType == 'Y')
				nMinCur.QuadPart = vValue->ev_currency.QuadPart;
			else
				nMin = vValue->ev_real;
			break;
		}
		else if (vValue.Vartype() == '0');
		else
			throw E_INVALIDPARAMS;
	}
		
	// all rows were .NULL.
	if (*pRowPtr > nRows)
	{
		vValue.Return();
		return;
	}

	for (++(*pRowPtr); *pRowPtr <= nRows; (*pRowPtr)++)
	{
		vValue.Load(r1);

		if (vValue.Vartype() == cType)
		{
			if (cType != 'Y')
			{
				if (nMin > vValue->ev_real)
					nMin = vValue->ev_real;
			}
			else
			{
				if (nMinCur.QuadPart > vValue->ev_currency.QuadPart)
					nMinCur.QuadPart = vValue->ev_currency.QuadPart;
			}
		}
		else if (vValue.Vartype() == '0');
		else
			throw E_INVALIDPARAMS;
	}

	if (cType == 'N')
		Return(nMin);
	else if (cType == 'Y')
	{
		vValue->ev_type = cType;
		vValue->ev_currency.QuadPart = nMinCur.QuadPart;
		vValue.Return();
	}
	else
	{
		vValue->ev_type = cType;
		vValue->ev_real = nMin;
		vValue.Return();
	}
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}
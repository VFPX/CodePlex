#include "pro_ext.h"
#include "vfp2c32.h"
#include "vfp2carray.h"
#include "vfp2cutil.h"
#include "vfp2ccppapi.h"
#include "vfpmacros.h"

void _fastcall ASplitStr(ParamBlk *parm)
{
try
{
	unsigned char *pSubString;
	int nRows, nRemain, xj, nSubStrLen = p3.ev_long;

	if (nSubStrLen <= 0)
		throw E_INVALIDPARAMS;

	FoxArray pArray(p1);
	FoxString pString(p2, 0);

	nRows = pString.Len() / nSubStrLen;
	nRemain = pString.Len() % nSubStrLen;

	if (nRows == 0)
	{
		pArray.Dimension(1);
		pArray(1) = pString;
		pArray.ReturnRows();
		return;
	}

	FoxString pBuffer(nSubStrLen);
	pArray.Dimension(nRows + (nRemain ? 1 : 0));

	pSubString = pString;
	for (xj = 1; xj <= nRows; xj++)
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
	FoxArray vArray(r1);
	FoxValue vValue;
	double Sum;
	CCY SumCur;
	unsigned int Rows, Dims, TargetDim, StartDim, StopDim;
	char Type = '0';

	if (PCOUNT() == 1)
        TargetDim = 1;
	else if (p2.ev_long < 0)
		throw E_INVALIDPARAMS;
	else
		TargetDim = static_cast<unsigned int>(p2.ev_long);

	vArray.ValidateDimension(TargetDim);
	Rows = vArray.ALen(Dims);

	if (TargetDim == 0)
	{
		StartDim = 1;
		StopDim = Dims;
	}
	else
	{
		StartDim = TargetDim;
		StopDim = TargetDim;
	}

	unsigned int CurrentRow, CurrentDim;
	for (CurrentDim = StartDim; CurrentDim <= StopDim; CurrentDim++)
	{
	    for (CurrentRow = 1; CurrentRow <= Rows; CurrentRow++)
		{
			vValue = vArray(CurrentRow, CurrentDim);
			if (Type == '0')
			{
				if (vValue.Vartype() == 'N' || vValue.Vartype() == 'Y')
				{
					Type = vValue.Vartype();
					if (Type == 'N')
						Sum = vValue->ev_real;
					else
						SumCur.QuadPart = vValue->ev_currency.QuadPart;
				}
				else if (vValue.Vartype() == '0');
				else
					throw E_INVALIDPARAMS;
			}
			else
			{
				if (vValue.Vartype() == Type)
				{
					if (Type == 'N')
						Sum += vValue->ev_real;
					else
						SumCur.QuadPart += vValue->ev_currency.QuadPart;
				}
				else if (vValue.Vartype() == '0');
				else
					throw E_INVALIDPARAMS;
			}
		}
	}

	if (Type == '0')
		vValue.Return();
	else if (Type == 'N')
		Return(Sum);
	else
		Return(SumCur);
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
	FoxArray vArray(r1);
	FoxValue vValue;
	double Sum;
	CCY SumCur;
	unsigned int Rows, Dims, TargetDim, StartDim, StopDim, ValueCount = 0;
	char Type = '0';

	if (PCOUNT() == 1)
        TargetDim = 1;
	else if (p2.ev_long < 0)
		throw E_INVALIDPARAMS;
	else
		TargetDim = static_cast<unsigned int>(p2.ev_long);

	vArray.ValidateDimension(TargetDim);
	Rows = vArray.ALen(Dims);

	if (TargetDim == 0)
	{
		StartDim = 1;
		StopDim = Dims;
	}
	else
	{
		StartDim = TargetDim;
		StopDim = TargetDim;
	}

	unsigned int CurrentRow, CurrentDim;
	for (CurrentDim = StartDim; CurrentDim <= StopDim; CurrentDim++)
	{
	    for (CurrentRow = 1; CurrentRow <= Rows; CurrentRow++)
		{
			vValue = vArray(CurrentRow, CurrentDim);
			if (Type == '0')
			{
				if (vValue.Vartype() == 'N' || vValue.Vartype() == 'Y')
				{
					Type = vValue.Vartype();
					if (Type == 'N')
						Sum = vValue->ev_real;
					else
						SumCur.QuadPart = vValue->ev_currency.QuadPart;
					ValueCount++;
				}
				else if (vValue.Vartype() == '0');
				else
					throw E_INVALIDPARAMS;
			}
			else
			{
				if (vValue.Vartype() == Type)
				{
					if (Type == 'N')
						Sum += vValue->ev_real;
					else
						SumCur.QuadPart += vValue->ev_currency.QuadPart;
					ValueCount++;
				}
				else if (vValue.Vartype() == '0');
				else
					throw E_INVALIDPARAMS;
			}
		}
	}

	if (Type == '0')
		vValue.Return();
	else if (Type == 'N')
		Return(Sum / ValueCount);
	else
	{
		SumCur.QuadPart /= ValueCount;
		Return(SumCur);
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
	FoxArray vArray(r1);
	FoxValue vValue;
	double Max;
	CCY MaxCur;
	unsigned int Rows, Dims, TargetDim, StartDim, StopDim;
	char Type = '0';

	if (PCOUNT() == 1)
        TargetDim = 1;
	else if (p2.ev_long < 0)
		throw E_INVALIDPARAMS;
	else
		TargetDim = static_cast<unsigned int>(p2.ev_long);

	vArray.ValidateDimension(TargetDim);
	Rows = vArray.ALen(Dims);

	if (TargetDim == 0)
	{
		StartDim = 1;
		StopDim = Dims;
	}
	else
	{
		StartDim = TargetDim;
		StopDim = TargetDim;
	}

	unsigned int CurrentRow, CurrentDim;
	for (CurrentDim = StartDim; CurrentDim <= StopDim; CurrentDim++)
	{
		for (CurrentRow = 1; CurrentRow <= Rows; CurrentRow++)
		{
			vValue = vArray(CurrentRow, CurrentDim);
			if (Type == '0')
			{
				if (vValue.Vartype() == 'N' || vValue.Vartype() == 'D' || vValue.Vartype() == 'T' || vValue.Vartype() == 'Y')
				{
					Type = vValue.Vartype();
					if (Type == 'Y')
						MaxCur.QuadPart = vValue->ev_currency.QuadPart;
					else
						Max = vValue->ev_real;
				}
				else if (vValue.Vartype() == '0');
				else
					throw E_INVALIDPARAMS;
			}
			else
			{
				if (vValue.Vartype() == Type)
				{
					if (Type != 'Y')
					{
						if (Max < vValue->ev_real)
							Max = vValue->ev_real;
					}
					else
					{
						if (MaxCur.QuadPart < vValue->ev_currency.QuadPart)
							MaxCur.QuadPart = vValue->ev_currency.QuadPart;
					}
				}
				else if (vValue.Vartype() == '0');
				else
					throw E_INVALIDPARAMS;
			}
		}

	}

	if (Type == '0')
		vValue.Return();
	else if (Type == 'N')
		Return(Max);
	else 
	{
		vValue->ev_type = Type;
		if (Type != 'Y')
			vValue->ev_real = Max;
		else
			vValue->ev_currency.QuadPart = MaxCur.QuadPart;
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
	FoxArray vArray(r1);
	FoxValue vValue;
	double Min;
	CCY MinCur;
	unsigned int Rows, Dims, TargetDim, StartDim, StopDim;
	char Type = '0';

	if (PCOUNT() == 1)
        TargetDim = 1;
	else if (p2.ev_long < 0)
		throw E_INVALIDPARAMS;
	else
		TargetDim = static_cast<unsigned int>(p2.ev_long);

	vArray.ValidateDimension(TargetDim);
	Rows = vArray.ALen(Dims);

	if (TargetDim == 0 && Dims > 1)
	{
		StartDim = 1;
		StopDim = Dims;
	}
	else
	{
		StartDim = TargetDim;
		StopDim = TargetDim;
	}

	unsigned int CurrentRow, CurrentDim;
	for (CurrentDim = StartDim; CurrentDim <= StopDim; CurrentDim++)
	{
	    for (CurrentRow = 1; CurrentRow <= Rows; CurrentRow++)
		{
			vValue = vArray(CurrentRow, CurrentDim);
			if (Type == '0')
			{
				if (vValue.Vartype() == 'N' || vValue.Vartype() == 'D' || vValue.Vartype() == 'T' || vValue.Vartype() == 'Y')
				{
					Type = vValue.Vartype();
					if (Type == 'Y')
						MinCur.QuadPart = vValue->ev_currency.QuadPart;
					else
						Min = vValue->ev_real;
				}
				else if (vValue.Vartype() == '0');
				else
					throw E_INVALIDPARAMS;
			}
			else
			{
				if (vValue.Vartype() == Type)
				{
					if (Type != 'Y')
					{
						if (Min > vValue->ev_real)
							Min = vValue->ev_real;
					}
					else
					{
						if (MinCur.QuadPart > vValue->ev_currency.QuadPart)
							MinCur.QuadPart = vValue->ev_currency.QuadPart;
					}
				}
				else if (vValue.Vartype() == '0');
				else
					throw E_INVALIDPARAMS;
			}
		}
	}
		
	if (Type == '0')
		vValue.Return();
	else if (Type == 'N')
		Return(Min);
	else if (Type == 'Y')
	{
		vValue->ev_type = Type;
		vValue->ev_currency.QuadPart = MinCur.QuadPart;
		vValue.Return();
	}
	else
	{
		vValue->ev_type = Type;
		vValue->ev_real = Min;
		vValue.Return();
	}
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}
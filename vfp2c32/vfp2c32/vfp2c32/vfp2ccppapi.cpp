#include "pro_ext.h"
#include "vfp2c32.h"
#include "vfp2cutil.h"
#include "vfpmacros.h"
#include "vfp2ccppapi.h"

#include <assert.h>
#include <math.h>
#include <new>
#include <stdio.h>

static TimeZoneInfo gsTimeZone;

NTI _stdcall NewVar(char *pVarname, Locator &sVar, bool bPublic) throw(int)
{
	NTI nVarNti;
	sVar.l_subs = 0;
	nVarNti = _NewVar(pVarname, &sVar, bPublic ? NV_PUBLIC : NV_PRIVATE);
	if (nVarNti < 0)
	{
		int nErrorNo = (int)-nVarNti;
		throw nErrorNo;
	}
	return nVarNti;
}

 NTI _stdcall FindVar(char *pVarname) throw(int)
 {
	NTI nVarNti;
	nVarNti = _NameTableIndex(pVarname);
	if (nVarNti == -1)
		throw E_VARIABLENOTFOUND;

	return nVarNti;
 }

void _stdcall FindVar(NTI nVarNti, Locator &sVar) throw(int)
{
	if (!_FindVar(nVarNti, -1, &sVar))
		throw E_VARIABLENOTFOUND;
}

void _stdcall FindVar(char *pVarname, Locator &sVar) throw(int)
{
	NTI nVarNti;
	nVarNti = FindVar(pVarname);
	FindVar(nVarNti, sVar);
}

/* implementation of C++ wrapper classes over FoxPro datatypes */
FoxValue::~FoxValue()
{
	if (Vartype() == 'C')
	{
		UnlockHandle();
		FreeHandle();
	}
	else if (Vartype() == 'O')
	{
		UnlockObject();
		FreeObject();
	}
}

FoxValue& FoxValue::Load(Locator& pLoc)
{
	int nErrorNo;
	if (nErrorNo = _Load(&pLoc,&m_Value))
		throw nErrorNo;
	return *this;
}

FoxValue& FoxValue::Store(Locator& pLoc)
{
	int nErrorNo;
	if (nErrorNo = _Store(&pLoc, &m_Value))
		throw nErrorNo;
	return *this;
}

FoxValue& FoxValue::AllocHandle(int nBytes)
{
	assert(m_Value.ev_handle == 0);
	m_Value.ev_handle = _AllocHand(nBytes);
	if (m_Value.ev_handle == 0)
		throw E_INSUFMEMORY;
	return *this;
}

FoxValue& FoxValue::FreeHandle()
{
	if (m_Value.ev_handle)
	{
		_FreeHand(m_Value.ev_handle);
		m_Value.ev_handle = 0;
	}
	return *this;
}

char* FoxValue::HandleToPtr()
{
	assert(Vartype() == 'C' && m_Value.ev_handle);
	return reinterpret_cast<char*>(_HandToPtr(m_Value.ev_handle));
}

FoxValue& FoxValue::LockHandle()
{
	if (m_Locked == false)
	{
		assert(Vartype() == 'C' && m_Value.ev_handle);
		_HLock(m_Value.ev_handle);
		m_Locked = true;
	}
	return *this;
}

FoxValue& FoxValue::UnlockHandle()
{
	if (m_Locked)
	{
		assert(Vartype() == 'C' && m_Value.ev_handle);
		_HUnLock(m_Value.ev_handle);
		m_Locked = false;
	}
	return *this;
}

FoxValue& FoxValue::SetHandleSize(unsigned long nSize)
{
	assert(Vartype() == 'C' && m_Value.ev_handle);
	if (_SetHandSize(m_Value.ev_handle, nSize) == 0)
		throw E_INSUFMEMORY;
	return *this;
}

FoxValue& FoxValue::ExpandHandle(int nBytes)
{
	assert(Vartype() == 'C' && m_Value.ev_handle);
	if (_SetHandSize(m_Value.ev_handle, m_Value.ev_length + nBytes) == 0)
		throw E_INSUFMEMORY;
	return *this;
}

FoxValue& FoxValue::LockObject()
{
	assert(Vartype() == 'O' && m_Value.ev_object);
	if (m_Locked == false)
	{
		int nErrorNo = _ObjectReference(&m_Value);
		if (nErrorNo)
			throw nErrorNo;
		m_Locked = true;
	}
	return *this;
}

FoxValue& FoxValue::UnlockObject()
{
	if (m_Locked)
	{
		assert(Vartype() == 'O' && m_Value.ev_object);
		int nErrorNo = _ObjectRelease(&m_Value);
		if (nErrorNo)
			throw nErrorNo;
		m_Locked = false;
	}
	return *this;
}

FoxValue& FoxValue::FreeObject()
{
	if (m_Value.ev_object)
	{
		assert(Vartype() == 'O');
		_FreeObject(&m_Value);
		m_Value.ev_object = 0;
	}
	return *this;
}

void FoxValue::Return()
{
	assert(m_Locked == false);
	_RetVal(&m_Value);
	 m_Value.ev_type = '0';
}

void FoxValue::Release()
{
	if (Vartype() == 'C')
	{
		UnlockHandle();
		FreeHandle();
	}
	else if (Vartype() == 'O')
	{
		UnlockObject();
		FreeObject();
	}
	m_Value.ev_type = '0';
}

/* FoxReference */
FoxReference::FoxReference(Locator &pLoc)
{
	m_pLoc = &pLoc;
}

FoxReference& FoxReference::operator=(const Value &pVal)
{
	int nErrorNo;
	if (m_pLoc->l_where == -1)
	{
		if (nErrorNo = _Store(m_pLoc,const_cast<Value*>(&pVal)))
			throw nErrorNo;
	}
	else
	{
		if (nErrorNo = _DBReplace(m_pLoc,const_cast<Value*>(&pVal)))
			throw nErrorNo;
	}
	return *this;
}

FoxReference& FoxReference::operator=(FoxString &pString)
{
	int nErrorNo;
	if (m_pLoc->l_where == -1)
	{
		if (nErrorNo = _Store(m_pLoc,pString))
			throw nErrorNo;
	}
	else
	{
		if (nErrorNo = _DBReplace(m_pLoc,pString))
			throw nErrorNo;
	}
	return *this;
}

FoxReference& FoxReference::operator=(int nValue)
{
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'I';
	vTmp.ev_width = 11;
	vTmp.ev_long = nValue;
	if (m_pLoc->l_where == -1)
	{
		if (nErrorNo = _Store(m_pLoc,&vTmp))
			throw nErrorNo;
	}
	else
	{
		if (nErrorNo = _DBReplace(m_pLoc,&vTmp))
			throw nErrorNo;
	}
	return *this;
}

FoxReference& FoxReference::operator=(unsigned long nValue)
{
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'N';
	vTmp.ev_width = 10;
	vTmp.ev_length = 0;
	vTmp.ev_real = static_cast<double>(nValue);
	if (m_pLoc->l_where == -1)
	{
		if (nErrorNo = _Store(m_pLoc,&vTmp))
			throw nErrorNo;
	}
	else
	{
		if (nErrorNo = _DBReplace(m_pLoc,&vTmp))
			throw nErrorNo;
	}
	return *this;
}

FoxReference& FoxReference::operator=(double nValue)
{
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'N';
	vTmp.ev_width = 20;
	vTmp.ev_length = 16;
	vTmp.ev_real = nValue;
	if (m_pLoc->l_where == -1)
	{
		if (nErrorNo = _Store(m_pLoc,&vTmp))
			throw nErrorNo;
	}
	else
	{
		if (nErrorNo = _DBReplace(m_pLoc,&vTmp))
			throw nErrorNo;
	}
	return *this;
}

FoxReference& FoxReference::operator=(bool bValue)
{
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'L';
	vTmp.ev_length = (int)bValue;
	if (m_pLoc->l_where == -1)
	{
		if (nErrorNo = _Store(m_pLoc,&vTmp))
			throw nErrorNo;
	}
	else
	{
		if (nErrorNo = _DBReplace(m_pLoc,&vTmp))
			throw nErrorNo;
	}
	return *this;
}

FoxReference& FoxReference::Load(Value &pVal)
{
	int nErrorNo;
	if (nErrorNo = _Load(m_pLoc, &pVal))
		throw nErrorNo;
	return *this;
}

/* FoxVariable */
FoxVariable::FoxVariable()
{
	m_Nti = 0;
}

FoxVariable::FoxVariable(char *pName)
{
	m_Nti = 0;
	Attach(pName);
}

FoxVariable::FoxVariable(char *pName, bool bPublic)
{
	m_Nti = 0;
	New(pName, bPublic);
}

FoxVariable::~FoxVariable()
{
	Release();
}

void FoxVariable::New(char *pName, bool bPublic)
{
	this->Release();
	m_Loc.l_subs = 0;
    m_Nti = _NewVar(pName, &m_Loc, bPublic ? NV_PUBLIC : NV_PRIVATE);
	if (m_Nti < 0)
		throw -m_Nti;
}

void FoxVariable::Attach(char *pName)
{
	this->Release();
	m_Nti = _NameTableIndex(pName);
	if (m_Nti == -1)
		throw E_VARIABLENOTFOUND;

	if (!_FindVar(m_Nti,-1, &m_Loc))
		throw E_VARIABLENOTFOUND;
}

void FoxVariable::Detach()
{
	m_Nti = 0;
}

void FoxVariable::Release()
{
	if (m_Nti)
	{
		_Release(m_Nti);
		m_Nti = 0;
	}
}

FoxVariable& FoxVariable::operator=(const Value &pVal)
{
	int nErrorNo;
	if (nErrorNo = _Store(&m_Loc,const_cast<Value*>(&pVal)))
		throw nErrorNo;
	return *this;
}

FoxVariable& FoxVariable::operator=(FoxString &pString)
{
	int nErrorNo;
	if (nErrorNo = _Store(&m_Loc,pString))
		throw nErrorNo;
	return *this;
}

FoxVariable& FoxVariable::operator=(int nValue)
{
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'I';
	vTmp.ev_width = 11;
	vTmp.ev_long = nValue;
	if (nErrorNo = _Store(&m_Loc,&vTmp))
		throw nErrorNo;
	return *this;
}

FoxVariable& FoxVariable::operator=(unsigned long nValue)
{
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'N';
	vTmp.ev_width = 10;
	vTmp.ev_length = 0;
	vTmp.ev_real = static_cast<double>(nValue);
	if (nErrorNo = _Store(&m_Loc,&vTmp))
		throw nErrorNo;
	return *this;
}

FoxVariable& FoxVariable::operator=(double nValue)
{
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'N';
	vTmp.ev_width = 20;
	vTmp.ev_length = 16;
	vTmp.ev_real = nValue;
	if (nErrorNo = _Store(&m_Loc,&vTmp))
		throw nErrorNo;
	return *this;
}

FoxVariable& FoxVariable::operator=(bool bValue)
{
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'L';
	vTmp.ev_length = (int)bValue;
	if (nErrorNo = _Store(&m_Loc,&vTmp))
		throw nErrorNo;
	return *this;
}

/* FoxString */
FoxString::FoxString()
{
	m_ParameterRef = false;
	m_Value.ev_type = 'C';
	m_Value.ev_handle = m_BufferSize = m_Value.ev_length = 0;
	m_String = 0;
}

FoxString::FoxString(FoxString &pString)
{
	m_ParameterRef = false;
	m_Value.ev_type = 'C';
	m_BufferSize = pString.Size();

	if (m_BufferSize)
	{
		AllocHandle(m_BufferSize);
		m_Value.ev_length = pString.Len();
		m_Value.ev_width = pString.Binary() ? 0 : 1;
		m_String = HandleToPtr();
		memcpy(m_String,pString,m_Value.ev_length);
	}
	else
	{
		m_String = 0;
		m_Value.ev_length = 0;
		m_Value.ev_handle = 0;
	}
}

FoxString::FoxString(Value &pVal)
{
	// nullterminate
	if (!NullTerminateValue(pVal))
		throw E_INSUFMEMORY;

	m_Value.ev_type = 'C';
	m_Value.ev_length = pVal.ev_length;
	m_Value.ev_width = pVal.ev_width;
	m_Value.ev_handle = pVal.ev_handle;
	m_BufferSize = pVal.ev_length + 1;
	LockHandle();
	m_String = HandleToPtr();
	m_ParameterRef = true;
}

FoxString::FoxString(Value &pVal, unsigned int nExpand)
{
	if (nExpand > 0)
	{
		if (!ExpandValue(pVal, nExpand))
			throw E_INSUFMEMORY;
	}
	m_Value.ev_type = 'C';
	m_Value.ev_length = pVal.ev_length;
	m_Value.ev_width = pVal.ev_width;
	m_Value.ev_handle = pVal.ev_handle;
	m_BufferSize = pVal.ev_length + nExpand;
	LockHandle();
	m_String = HandleToPtr();
	m_ParameterRef = true;
}

FoxString::FoxString(ParamBlk *pParms, int nParmNo)
{
	m_Value.ev_type = 'C';
	// if parameter count is equal or greater than the parameter we want
	if (pParms->pCount >= nParmNo)
	{
    	Value *pVal = &pParms->p[nParmNo-1].val;
		if (pVal->ev_type == 'C' && pVal->ev_length > 0)
		{
			// nullterminate
			if (!NullTerminateValue(pVal))
				throw E_INSUFMEMORY;
	
			m_Value.ev_handle = pVal->ev_handle;
			m_Value.ev_length = pVal->ev_length;
			m_Value.ev_width = pVal->ev_width;
			m_BufferSize = pVal->ev_length + 1;
			m_ParameterRef = true;
			LockHandle();
			m_String = HandleToPtr();
			return;
		}
	}
	// else
	m_ParameterRef = false;
	m_Value.ev_handle = m_Value.ev_length = m_Value.ev_width = m_BufferSize = 0;
	m_String = 0;
}

FoxString::FoxString(ParamBlk *pParms, int nParmNo, unsigned int nExpand)
{
	m_Value.ev_type = 'C';
	// if parameter count is equal or greater than the parameter we want
	if (pParms->pCount >= nParmNo)
	{
    	Value *pVal = &pParms->p[nParmNo-1].val;
		if (pVal->ev_type == 'C' && pVal->ev_length > 0)
		{
			if (nExpand > 0)
			{
				if (!ExpandValue(pVal, nExpand))
					throw E_INSUFMEMORY;
			}
			m_Value.ev_handle = pVal->ev_handle;
			m_Value.ev_length = pVal->ev_length;
			m_Value.ev_width = pVal->ev_width;
			m_BufferSize = pVal->ev_length + nExpand;
			m_ParameterRef = true;
			LockHandle();
			m_String = HandleToPtr();
			return;
		}
	}
	// else
	m_ParameterRef = false;
	m_Value.ev_handle = m_Value.ev_length = m_Value.ev_width = m_BufferSize = 0;
	m_String = 0;
}

FoxString::FoxString(const char *pString)
{
	m_ParameterRef = false;
	if (pString)
	{
		unsigned int nStrLen = strlen(pString);
		m_BufferSize = nStrLen + 1;
		AllocHandle(m_BufferSize);
		LockHandle();
		m_String = HandleToPtr();
		memcpy(m_String,pString,nStrLen);
		m_String[nStrLen] = '\0';
		m_Value.ev_length = nStrLen;
		m_Value.ev_width = 0;
	}
	else
	{
		m_Value.ev_handle = m_Value.ev_length = m_Value.ev_width = m_BufferSize = 0;
		m_String = 0;
	}
}

FoxString::FoxString(unsigned int nBufferSize)
{
	assert(nBufferSize > 0);
	m_ParameterRef = false;
	m_Value.ev_type = 'C';
	m_Value.ev_length = 0;
	AllocHandle(nBufferSize);
	LockHandle();
	m_String = HandleToPtr();
	m_BufferSize = nBufferSize;
	*m_String = '\0';
}

FoxString::FoxString(BSTR pString, UINT nCodePage)
{
	m_ParameterRef = false;
	m_Value.ev_type = 'C';
	if (pString)
	{
		unsigned int nLen = SysStringLen(pString);
		m_Value.ev_length = nLen;
		m_BufferSize = nLen + 1;
		AllocHandle(m_BufferSize);
		LockHandle();
		m_String = HandleToPtr();
		int nChars;
		nChars = WideCharToMultiByte(nCodePage, 0, pString, nLen, m_String, nLen, 0, 0);
		if (!nChars)
		{
			SAVEWIN32ERROR(WideCharToMultiByte,GetLastError());
			throw E_APIERROR;
		}
		m_String[nLen] = '\0';
	}
	else
	{
		m_BufferSize = m_Value.ev_handle = m_Value.ev_length = 0;
		m_String = 0;
	}
}

FoxString::FoxString(SAFEARRAY *pArray)
{
	HRESULT hr;
	VARTYPE vt;
	if (pArray)
	{
        if (pArray->fFeatures & FADF_HAVEVARTYPE)
		{
			hr = SafeArrayGetVartype(pArray, &vt);
			if (FAILED(hr))
			{
				SAVEWIN32ERROR(SafeArrayGetVartype,hr);
				throw E_APIERROR;
			}
			if (vt != VT_UI1)
				throw E_TYPECONFLICT;
		}

		m_ParameterRef = false;
		m_Value.ev_type = 'C';

		unsigned long nLen;
		nLen = pArray->rgsabound[0].cElements;
		m_Value.ev_length = nLen;
		m_Value.ev_width = 1;
		m_BufferSize = nLen;
		AllocHandle(m_BufferSize);
		LockHandle();
		m_String = HandleToPtr();

		void *pData;
		hr = SafeArrayAccessData(pArray, &pData);
		if (FAILED(hr))
		{
			SAVEWIN32ERROR(SafeArrayAccessData,hr);
			throw E_APIERROR;
		}

		memcpy(m_String, pData, nLen);

		hr = SafeArrayUnaccessData(pArray);
		if (FAILED(hr))
		{
			SAVEWIN32ERROR(SafeArrayUnaccessData,hr);
			throw E_APIERROR;
		}
	}
	else
	{
		m_BufferSize = m_Value.ev_handle = m_Value.ev_length = 0;
		m_String = 0;
	}
}

FoxString::~FoxString()
{
	if (m_Value.ev_handle)
	{
		UnlockHandle();
		if (!m_ParameterRef)
			FreeHandle();
	}
	m_Value.ev_type = '0';
}

void FoxString::Release()
{
	if (m_Value.ev_handle)
	{
		UnlockHandle();
		if (!m_ParameterRef)
			FreeHandle();
		else
			m_Value.ev_handle = 0;
	}
	m_ParameterRef = false;
	m_Value.ev_length = 0;
	m_BufferSize = 0;
}

FoxString& FoxString::Size(unsigned int nSize)
{
	if (m_Value.ev_handle)
	{
		UnlockHandle();
		SetHandleSize(nSize);
	}
	else
		AllocHandle(nSize);

	LockHandle();
	m_String = HandleToPtr();
	m_BufferSize = nSize;
	return *this;
}

bool FoxString::Binary() const
{
	return m_Value.ev_width == 1;
}

FoxString& FoxString::Binary(bool bBinary)
{
	m_Value.ev_width = bBinary ? 1 : 0;
	return *this;
}

bool FoxString::Empty() const
{
	if (m_Value.ev_length && m_String)
	{
		char *pString = m_String;
		do
		{
			if (*pString == ' ' || *pString == '\t' || *pString == '\n' || *pString == '\r')
				pString++;
			else
				return false;
		} while (*pString);
	}
	return true;
}

FoxString& FoxString::StrnCpy(const char *pString, unsigned int nMaxLen)
{
	assert(nMaxLen < m_BufferSize);
	m_Value.ev_length = strncpyex(m_String, pString, nMaxLen);
	return *this;
}

FoxString& FoxString::CopyBytes(const unsigned char *pBytes, unsigned int nLen)
{
	assert(nLen <= m_BufferSize);
	memcpy(m_String, pBytes, nLen);
	m_Value.ev_length = nLen;
	return *this;
}

FoxString& FoxString::CopyDblString(const char *pDblString, unsigned int nMaxLen)
{
	if (pDblString)
	{
		unsigned int nLen = strdblnlen(pDblString, nMaxLen);
		ExtendBuffer(nLen);
		CopyBytes(reinterpret_cast<const unsigned char*>(pDblString), nLen);
	}
	else
		Len(0);
	return *this;
}

FoxString& FoxString::StringLen()
{
	m_Value.ev_length = strnlen(m_String,m_BufferSize);
	return *this;
}

unsigned int FoxString::StringDblLen()
{
	const char *pString = m_String;
	unsigned int nMaxLen = m_BufferSize;

	while (1)
	{
		while (*pString != '\0' && nMaxLen--) ++pString;
	
		if (nMaxLen == 0)
			return m_BufferSize;

		pString++;
		if (*pString == '\0')
			return pString - m_String - 1;
		else
			nMaxLen--;
	}
}

unsigned int FoxString::StringDblCount()
{
	const char *pString = m_String;
	unsigned int nMaxLen = m_BufferSize, nStringCnt = 0;

	while (1)
	{
		while (*pString != '\0' && nMaxLen--) ++pString;
		nStringCnt++;
		pString++;		
		if (!nMaxLen || *pString == '\0')
			break;
		nMaxLen--;
	}
	return nStringCnt;
}

void FoxString::Return()
{
	assert(m_Value.ev_handle);
	UnlockHandle();
	_RetVal(&m_Value);
	m_Value.ev_handle = 0;
	m_String = 0;
}

FoxString& FoxString::Alltrim()
{
	 /* nonvalid or empty string */
	if (!m_String || m_Value.ev_length == 0)
		return *this;

	char *pStart, *pEnd;
	pStart = m_String;
	pEnd = m_String + m_Value.ev_length; /* compute end of string */

	while (*pStart == ' ') pStart++; /* skip over spaces at beginning of string */

	if (pStart == pEnd) /* entire string consisted of spaces */
	{
		*m_String = '\0';
		m_Value.ev_length = 0;
		return *this;
	}

	while (*--pEnd == ' '); /* find end of valid characters */
	m_Value.ev_length = pEnd - pStart + 1; // set new length
	if (pStart != m_String) /* need to move string back */
	{
		char *pString = m_String;
		while (pString != pEnd)
			*pString++ = *pStart++;
		*pString = '\0';
	}
	else
		*++pEnd = '\0';	/* just set nullterminator */

	return *this;
}

/* to be done */
FoxString& FoxString::LTrim()
{
	if (!m_String || m_Value.ev_length == 0)
		return *this;

	char *pStart = m_String;
	while (*pStart == ' ') pStart++; /* skip over spaces at beginning of string */

	if (pStart != m_String) /* there were spaces on the left side */
	{
		unsigned int nBytes = pStart - m_String;
		m_Value.ev_length -= nBytes;
		memmove(m_String,pStart,m_Value.ev_length+1);
	}
	return *this;
}

FoxString& FoxString::RTrim()
{
	if (!m_String || m_Value.ev_length == 0)
		return *this;

	char *pEnd = m_String + m_Value.ev_length;
	while (*--pEnd == ' '); /* skip back over spaces at end of string */

	m_Value.ev_length = pEnd - m_String + 1;
	m_String[m_Value.ev_length] = '\0';
	return *this;
}

FoxString& FoxString::Lower()
{
	if (m_String)
		_strlwr(m_String);
	return *this;
}

FoxString& FoxString::Upper()
{
	if (m_String)
		_strupr(m_String);
	return *this;
}

FoxString& FoxString::Prepend(const char *pString)
{
	unsigned int nLen;
	nLen = strlen(pString);
	Size(nLen + m_BufferSize);
	memmove(m_String+nLen, m_String, m_Value.ev_length);
	memcpy(m_String, pString, nLen);
	m_Value.ev_length += nLen;
	return *this;
}

/* to be done */
/*
FoxString& FoxString::ChrTran(char *pSearch, char *pReplacement)
{

	return *this;
}
*/

FoxString& FoxString::Strtran(FoxString &sSearchFor, FoxString &sReplacement)
{
	if (sSearchFor.Len() > Len())
		return *this;

	if (sSearchFor.Len() >= sReplacement.Len())
	{
		//strstr(
	}
	else if (sSearchFor.Len() < sReplacement.Len())
	{
		char *pSearchIn = m_String, *pSearchFor = sSearchFor;
		int nCount = 0;

		while ((pSearchIn = strstr(pSearchIn,pSearchFor)))
		{
			nCount++;
			pSearchIn += sSearchFor.Len();
		}

		if (nCount == 0)
			return *this;

		FoxString sBuffer(Len() + nCount * (sReplacement.Len() - sSearchFor.Len()));
		char *pBuffer = sBuffer;
	}

	return *this;
}


FoxString& FoxString::Replicate(char *pString, unsigned int nCount)
{
	int nStrLen = strlen(pString);
	Size((nStrLen * nCount) + 1);
	char *pPtr = m_String;
	for(unsigned int xj = 1; xj <= nCount; xj++)
	{
		memcpy(pPtr,pString,nStrLen);
		pPtr += nStrLen;
	}
	*++pPtr = '\0';
	return *this;
}

unsigned int FoxString::At(char cSearchFor, unsigned int nOccurence, unsigned int nMax) const
{
	assert(m_String);
	char *pSearch = m_String;
	nMax = max(nMax,m_BufferSize);

	for (unsigned int nPos = 1; nPos <= nMax; nPos++)
	{
		if (*pSearch == cSearchFor)
		{
			if (--nOccurence == 0)
				return nPos;
		}
		pSearch++;
	}
	return 0;
}

/* to be done */
/*
unsigned int FoxString::RAt(char cSearchFor, unsigned int nOccurence = 1, unsigned int nMax = 0) const
{
	return 0;
}
*/

unsigned int FoxString::GetWordCount(const char pSeperator) const
{
	assert(m_String);
	unsigned int nTokens = 1;
	const char *pString = m_String;
	while (*pString)
	{
		if (*pString++ == pSeperator)
			nTokens++;
	}
	if (pString != m_String)
        return nTokens;
	else
		return 0;
}

unsigned int FoxString::Expand(int nSize)
{
	m_BufferSize += nSize;
	if (m_Value.ev_handle)
	{
		UnlockHandle();
		SetHandleSize(m_BufferSize);
	}
	else
		AllocHandle(m_BufferSize);

	LockHandle();
	m_String = HandleToPtr();
	return m_BufferSize;
}

FoxString& FoxString::ExtendBuffer(unsigned int nNewMinBufferSize)
{
	if (m_BufferSize >= nNewMinBufferSize)
		return *this;

	m_BufferSize = nNewMinBufferSize;
	if (m_Value.ev_handle)
	{
		UnlockHandle();
		SetHandleSize(m_BufferSize);
	}
	else
		AllocHandle(m_BufferSize);

	LockHandle();
	m_String = HandleToPtr();
	return *this;
}

FoxString& FoxString::Fullpath()
{
	assert(m_String);

	Value vFullpath = {'0'};
	char aBuffer[VFP2C_MAX_CALLBACKFUNCTION];

	_snprintf(aBuffer,VFP2C_MAX_CALLBACKFUNCTION,"FULLPATH('%s')+CHR(0)",m_String);
	Evaluate(vFullpath,aBuffer);

	UnlockHandle();
	if (!m_ParameterRef)
		FreeHandle();

	m_ParameterRef = false;
	m_Value.ev_handle = vFullpath.ev_handle;
	m_BufferSize = m_Value.ev_length = vFullpath.ev_length - 1;
	LockHandle();
	m_String = HandleToPtr();
	return *this;
}

bool FoxString::ICompare(char *pString) const
{
	assert(m_String && pString);
	return stricmp(m_String,pString) == 0;
}

BSTR FoxString::ToBSTR() const
{
	DWORD dwLen = Len();
	BSTR pBstr = SysAllocStringByteLen(0,dwLen * 2);

	if (pBstr == 0)
		throw E_INSUFMEMORY;

	int nChars = MultiByteToWideChar(CP_ACP,MB_PRECOMPOSED,m_String,dwLen,pBstr,dwLen);
	if (!nChars)
	{
		SAVEWIN32ERROR(MultiByteToWideChar,GetLastError());
		SysFreeString(pBstr);
		throw E_APIERROR;
	}
	return pBstr;
}

SAFEARRAY* FoxString::ToU1SafeArray() const
{
	HRESULT hr;
	SAFEARRAY *pArray;
	unsigned char *pData;
	pArray = SafeArrayCreateVector(VT_UI1,0,Len());
	if (pArray == 0)
		throw E_INSUFMEMORY;
    if (hr = SafeArrayAccessData(pArray,(void**)&pData) != S_OK)
	{
		SAVEWIN32ERROR(SafeArrayAccessData, hr);
		SafeArrayDestroy(pArray);
		throw E_APIERROR;
	}
	memcpy(pData,m_String,Len());
	if (hr = SafeArrayUnaccessData(pArray) != S_OK)
	{
		SAVEWIN32ERROR(SafeArrayUnaccessData, hr);
		SafeArrayDestroy(pArray);
		throw E_APIERROR;
	}
	return pArray;
}

void FoxString::Attach(Value &pValue, unsigned int nExpand)
{
	assert(pValue.ev_type == 'C');

	if (nExpand > 0)
	{
		if (!ExpandValue(pValue, nExpand))
		{
			::FreeHandle(pValue);
			throw E_INSUFMEMORY;
		}
	}

	m_Value.ev_handle = pValue.ev_handle;
	m_Value.ev_width = pValue.ev_width;
	LockHandle();
	m_String = HandleToPtr();
	m_Value.ev_length = pValue.ev_length;
	m_BufferSize = pValue.ev_length + nExpand;
}

void FoxString::Detach()
{
	if (m_Value.ev_handle)
		UnlockHandle();
	m_BufferSize = m_Value.ev_length = m_Value.ev_handle = 0;
	m_String = 0;
}

void FoxString::Detach(Value &pValue)
{
	pValue.ev_type = 'C';
	pValue.ev_handle = m_Value.ev_handle;
	pValue.ev_length = m_Value.ev_length;
	pValue.ev_width = m_Value.ev_width;
	if (m_Value.ev_handle)
		UnlockHandle();
	m_BufferSize = m_Value.ev_length = m_Value.ev_handle = 0;
	m_String = 0;
}

/* Operator overloading */
FoxString& FoxString::operator=(FoxString &pString)
{
	assert(&pString != this);
	if (m_BufferSize < pString.Size())
		Size(pString.Size());

	memcpy(m_String,pString,pString.Len()+1);
	return *this;
}

FoxString& FoxString::operator=(const char *pString)
{
	if (pString)
	{
		unsigned int nLen = strlen(pString) + 1;
		if (m_BufferSize < nLen)
			Expand(nLen - m_BufferSize);
		memcpy(m_String,pString,nLen);
		m_Value.ev_length = nLen - 1;
	}
	else
	{
		m_Value.ev_length = 0;
		if (m_String)
			*m_String = '\0';
	}
	return *this;
}

FoxString& FoxString::operator=(const Value &pVal)
{
	assert(pVal.ev_type == 'C');

	Release();

	m_Value.ev_handle = pVal.ev_handle;
	m_BufferSize = m_Value.ev_length = pVal.ev_length;
	m_Value.ev_width = pVal.ev_width;
	
	if (!NullTerminateValue(m_Value))
	{
		FreeHandle();
		throw E_INSUFMEMORY;
	}
	LockHandle();
    m_String = HandleToPtr();
	return *this;
}


FoxString& FoxString::operator=(const wchar_t *pWString)
{
	unsigned int nLen;
	int nChars;

	if (pWString)
	{
		nLen = wcslen(pWString) + 1;

		if (m_BufferSize < nLen)
			Size(nLen);

		if (nLen == 0)
			m_Value.ev_length = 0;
		else
		{
			nChars = WideCharToMultiByte(CP_ACP, 0, pWString, nLen-1, m_String, m_BufferSize, 0, 0);
			if (!nChars)
			{
				SAVEWIN32ERROR(MultiByteToWideChar,GetLastError());
				throw E_APIERROR;
			}
			m_Value.ev_length = nChars;
			m_String[nChars] = '\0';
		}
	}
	else
	{
		m_Value.ev_length = 0;
		if (m_String)
			*m_String = '\0';
	}
	return *this;
}

FoxString& FoxString::operator+=(const char *pString)
{
	unsigned int nLen = strlen(pString) + 1;
	int nDiff = m_BufferSize - (m_Value.ev_length + nLen);
	if (nDiff < 0)
		Expand(m_BufferSize + (-nDiff));
	memcpy(m_String + m_Value.ev_length,pString,nLen);
	m_Value.ev_length += (nLen - 1);
	return *this;
}

FoxString& FoxString::operator+=(FoxString &pString)
{
	unsigned int nLen = pString.Len() + 1;
	int nDiff = m_BufferSize - (m_Value.ev_length + nLen);
	if (nDiff < 0)
		Expand(m_BufferSize + (-nDiff));
	memcpy(m_String + m_Value.ev_length,pString,nLen);
	m_Value.ev_length += (nLen - 1);
	return *this;
}

FoxString& FoxString::operator+=(const char pChar)
{
	if ((m_Value.ev_length + 1) > m_BufferSize)
		Expand(1);
	char *pTmp = m_String + m_Value.ev_length;
	*pTmp++ = pChar;
	*pTmp = '\0';
	m_Value.ev_length++;
	return *this;
} 

bool FoxString::operator==(const char *pString) const
{
	assert(m_String && pString);
	return strcmp(m_String,pString) == 0;
}

bool FoxString::operator==(FoxString &pString) const
{
	if (&pString == this)
		return true;
	else if (m_Value.ev_length != pString.Len())
		return false;
	else
		return memcmp(m_String,pString,m_Value.ev_length) == 0;
}

/* FoxWString */
FoxWString::FoxWString(Value &pVal)
{
	if (pVal.ev_length > 0)
	{
		DWORD dwLength = pVal.ev_length + 1;
		DWORD nWChars;

		m_String = new wchar_t[dwLength];
		if (m_String == 0)
			throw E_INSUFMEMORY;
		
		char *pString = ::HandleToPtr(pVal);
		nWChars = MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED,pString,pVal.ev_length,m_String,dwLength);
		if (!nWChars)
		{
			SAVEWIN32ERROR(MultiByteToWideChar,GetLastError());
			::UnlockHandle(pVal);
			throw E_APIERROR;
		}
		m_String[pVal.ev_length] = L'\0'; // nullterminate
	}
	else
		m_String = 0;
}

FoxWString::FoxWString(ParamBlk *pParms, int nParmNo)
{
	// if parameter count is equal or greater than the parameter we want
	if (pParms->pCount >= nParmNo)
	{
    	Value *pVal = &pParms->p[nParmNo-1].val;
		if (pVal->ev_type == 'C' && pVal->ev_length > 0)
		{
			DWORD dwLength = pVal->ev_length + 1;
			DWORD nWChars;

			m_String = new wchar_t[dwLength];
			if (m_String == 0)
				throw E_INSUFMEMORY;

			char *pString = ::HandleToPtr(pVal);
			nWChars = MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, pString, pVal->ev_length, m_String, dwLength);
			if (!nWChars)
			{
				SAVEWIN32ERROR(MultiByteToWideChar,GetLastError());
				throw E_APIERROR;
			}
			m_String[pVal->ev_length] = L'\0'; // nullterminate
			return;
		}
	}
	// else
	m_String = 0;
}

FoxWString::FoxWString(ParamBlk *pParms, int nParmNo, char cTypeCheck)
{
	// if parameter count is equal or greater than the parameter we want
	if (pParms->pCount >= nParmNo)
	{
    	Value *pVal = &pParms->p[nParmNo-1].val;
		if (pVal->ev_type == 'C' && pVal->ev_length > 0)
		{
			DWORD dwLength = pVal->ev_length + 1;
			DWORD nWChars;

			m_String = new wchar_t[dwLength];
			if (m_String == 0)
				throw E_INSUFMEMORY;

			char *pString = ::HandleToPtr(pVal);
			nWChars = MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, pString, pVal->ev_length, m_String, dwLength);
			if (!nWChars)
			{
				SAVEWIN32ERROR(MultiByteToWideChar,GetLastError());
				throw E_APIERROR;
			}
			m_String[pVal->ev_length] = L'\0'; // nullterminate
			return;
		}
		else if (pVal->ev_type != cTypeCheck)
			throw E_INVALIDPARAMS;
	}
	// else
	m_String = 0;
}

FoxWString::FoxWString(FoxString& pString)
{
	DWORD dwLength = pString.Len();
	if (dwLength > 0)
	{
		DWORD nWChars;
		m_String = new wchar_t[dwLength+1];
		if (m_String == 0)
			throw E_INSUFMEMORY;
		
		nWChars = MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, pString, dwLength, m_String, dwLength);
		if (!nWChars)
		{
			SAVEWIN32ERROR(MultiByteToWideChar,GetLastError());
			throw E_APIERROR;
		}
		m_String[dwLength] = L'\0'; // nullterminate
	}
	else
		m_String = 0;
}

FoxWString::~FoxWString()
{
	if (m_String)
		delete[] m_String;
}

wchar_t* FoxWString::Duplicate()
{
	DWORD dwLen = wcslen(m_String) + 1;

	wchar_t* pNewString = new wchar_t[dwLen];
	if (pNewString == 0)
		throw E_INSUFMEMORY;

	memcpy(pNewString,m_String,dwLen*2);
	return pNewString;
}

wchar_t* FoxWString::Detach()
{
	wchar_t* pWStr = m_String;
	m_String = 0;
	return pWStr;
}

FoxWString& FoxWString::operator=(char *pString)
{
	DWORD dwLength = strlen(pString);

	if (m_String != 0)
		delete[] m_String;

	// nullterminate
	m_String = new wchar_t[dwLength+1];
	if (m_String == 0)
		throw E_INSUFMEMORY;

	int nChars = MultiByteToWideChar(CP_ACP,MB_PRECOMPOSED,pString,dwLength,m_String,dwLength);
	if (!nChars)
	{
		SAVEWIN32ERROR(MultiByteToWideChar,GetLastError());
		throw E_APIERROR;
	}
	m_String[dwLength] = L'\0'; // nullterminate
	return *this;
}

FoxWString& FoxWString::operator=(FoxString& pString)
{
	DWORD dwLength = pString.Len();

	if (m_String != 0)
		delete[] m_String;

	m_String = new wchar_t[dwLength+1];
	if (m_String == 0)
		throw E_INSUFMEMORY;

	int nChars = MultiByteToWideChar(CP_ACP,MB_PRECOMPOSED,pString,dwLength,m_String,dwLength);
	if (!nChars)
	{
		SAVEWIN32ERROR(MultiByteToWideChar,GetLastError());
		throw E_APIERROR;
	}
	m_String[dwLength] = L'\0'; // nullterminate
	return *this;
}

/* FoxDate */
FoxDate::FoxDate(Value &pVal)
{
	m_Value.ev_type = 'D';
	m_Value.ev_real = pVal.ev_real;
}

FoxDate::FoxDate(SYSTEMTIME &sTime)
{
	SystemTimeToDate(sTime);
}

FoxDate::FoxDate(FILETIME &sTime)
{
	FileTimeToDate(sTime);
}

FoxDate& FoxDate::operator=(double nDate)
{
	m_Value.ev_real = nDate;
	return *this;
}

FoxDate& FoxDate::operator=(const SYSTEMTIME &sTime)
{
	SystemTimeToDate(sTime);
	return *this;
}

FoxDate& FoxDate::operator=(const FILETIME &sTime)
{
	FileTimeToDate(sTime);
	return *this;
}

FoxDate::operator SYSTEMTIME()
{
	SYSTEMTIME sTime;
	DateToSystemTime(sTime);
	return sTime;
}

FoxDate::operator FILETIME()
{
	FILETIME sTime;
	DateToFileTime(sTime);
	return sTime;
}

void FoxDate::SystemTimeToDate(const SYSTEMTIME &sTime)
{
	int lnA, lnY, lnM, lnJDay;
	lnA = (14 - sTime.wMonth) / 12;
	lnY = sTime.wYear + 4800 - lnA;
	lnM = sTime.wMonth + 12 * lnA - 3;
	lnJDay = sTime.wDay + (153 * lnM + 2) / 5 + lnY * 365 + lnY / 4 - lnY / 100 + lnY / 400 - 32045;
	m_Value.ev_real = ((double)lnJDay);
}

void FoxDate::FileTimeToDate(const FILETIME &sTime)
{
	// FILETIME base: Januar 1 1601 | C = 0 | FoxPro = 2305814.0
	// 86400 secs a day, 10000000 "100 nanosecond intervals" in one second
    LARGE_INTEGER pTime;
	pTime.LowPart = sTime.dwLowDateTime;
	pTime.HighPart = sTime.dwHighDateTime;

	if (pTime.QuadPart > MAXVFPFILETIME) //if bigger than max DATETIME - 9999/12/12 23:59:59
		pTime.QuadPart = MAXVFPFILETIME; //set to max date ..
	else if (pTime.QuadPart == 0) // empty Filetime?
		m_Value.ev_real = 0.0;
	else
	{
		// gives us seconds since 1601/01/01
		pTime.QuadPart /= NANOINTERVALSPERSECOND;
		// 1601/01/01 + number of seconds / 86400 (= number of days)
		m_Value.ev_real = VFPFILETIMEBASE + (double)(pTime.QuadPart / SECONDSPERDAY);
	}
}

void FoxDate::DateToSystemTime(SYSTEMTIME &sTime)
{
	int lnA, lnB, lnC, lnD, lnE, lnM;
	DWORD lnDays;

	lnDays = (DWORD)floor(m_Value.ev_real);

	lnA = lnDays + 32044;
	lnB = (4 * lnA + 3) / 146097;
	lnC = lnA - (lnB * 146097) / 4;

	lnD = (4 * lnC + 3) / 1461;
	lnE = lnC - (1461 * lnD) / 4;
	lnM = (5 * lnE + 2) / 153;
	
	sTime.wDay = (WORD) lnE - (153 * lnM + 2) / 5 + 1;
	sTime.wMonth = (WORD) lnM + 3 - 12 * (lnM / 10);
	sTime.wYear = (WORD) lnB * 100 + lnD - 4800 + lnM / 10;

	sTime.wHour = 0;
	sTime.wMinute = 0;
	sTime.wSecond = 0;
	sTime.wMilliseconds = 0;
}

void FoxDate::DateToFileTime(FILETIME &sTime)
{
	LARGE_INTEGER nFileTime;
	double dDateTime;

	if (m_Value.ev_real >= VFPFILETIMEBASE)
		dDateTime = floor(m_Value.ev_real); // get absolute value
	else if (m_Value.ev_real == 0.0) // if empty date .. set filetime to zero
	{
		sTime.dwLowDateTime = 0;
		sTime.dwHighDateTime = 0;
		return;
	}
	else
		dDateTime = VFPFILETIMEBASE; // if before 1601/01/01 00:00:00 set to 1601/01/01 ..

	nFileTime.QuadPart = ((LONGLONG)(dDateTime - VFPFILETIMEBASE)) * NANOINTERVALSPERDAY;
	sTime.dwLowDateTime = nFileTime.LowPart;
	sTime.dwHighDateTime = nFileTime.HighPart;	
}


/* FoxDateTime */
FoxDateTime::FoxDateTime(Value &pVal)
{
	m_Value.ev_type = 'T';
	m_Value.ev_real = pVal.ev_real;
}

FoxDateTime::FoxDateTime(SYSTEMTIME &sTime)
{
	m_Value.ev_type = 'T';
	SystemTimeToDateTime(sTime);
}

FoxDateTime::FoxDateTime(FILETIME &sTime)
{
	m_Value.ev_type = 'T';
	FileTimeToDateTime(sTime);
}

FoxDateTime::FoxDateTime(double dTime)
{
	m_Value.ev_type = 'T';
	m_Value.ev_real = dTime;
}

FoxDateTime& FoxDateTime::operator=(double nDateTime)
{
	m_Value.ev_real = nDateTime;
	return *this;
}

FoxDateTime& FoxDateTime::operator=(const SYSTEMTIME &sTime)
{
	SystemTimeToDateTime(sTime);
	return *this;
}

FoxDateTime& FoxDateTime::operator=(const FILETIME &sTime)
{
	FileTimeToDateTime(sTime);
	return *this;
}

FoxDateTime::operator SYSTEMTIME()
{
	SYSTEMTIME sTime;
	DateTimeToSystemTime(sTime);
	return sTime;
}
FoxDateTime::operator FILETIME()
{
	FILETIME sTime;
	DateTimeToFileTime(sTime);
	return sTime;
}

FoxDateTime& FoxDateTime::ToUTC()
{
	m_Value.ev_real += gsTimeZone.Bias();
	return *this;
}

FoxDateTime& FoxDateTime::ToLocal()
{
	m_Value.ev_real -= gsTimeZone.Bias();
	return *this;
}

void FoxDateTime::SystemTimeToDateTime(const SYSTEMTIME &sTime)
{
	int lnA, lnY, lnM, lnJDay, lnMinutes;
	lnA = (14 - sTime.wMonth) / 12;
	lnY = sTime.wYear + 4800 - lnA;
	lnM = sTime.wMonth + 12 * lnA - 3;
	lnJDay = sTime.wDay + (153 * lnM + 2) / 5 + lnY * 365 + lnY / 4 - lnY / 100 + lnY / 400 - 32045;

	lnMinutes = sTime.wHour * 3600 + sTime.wMinute * 60 + sTime.wSecond;
	m_Value.ev_real = ((double)lnJDay) + ((double)lnMinutes / SECONDSPERDAY);
}

void FoxDateTime::FileTimeToDateTime(const FILETIME &sTime)
{
	// FILETIME base: Januar 1 1601 | C = 0 | FoxPro = 2305814.0
	// 86400 secs a day, 10000000 "100 nanosecond intervals" in one second
    LARGE_INTEGER pTime;
	pTime.LowPart = sTime.dwLowDateTime;
	pTime.HighPart = sTime.dwHighDateTime;

	if (pTime.QuadPart > MAXVFPFILETIME) //if bigger than max DATETIME - 9999/12/12 23:59:59
		pTime.QuadPart = MAXVFPFILETIME; //set to max date ..
	else if (pTime.QuadPart == 0) // empty Filetime?
		m_Value.ev_real = 0.0;
	else
	{
		// gives us seconds since 1601/01/01
		pTime.QuadPart /= NANOINTERVALSPERSECOND;
		m_Value.ev_real = VFPFILETIMEBASE + (double)(pTime.QuadPart / SECONDSPERDAY);
		m_Value.ev_real += ((double)(pTime.QuadPart % SECONDSPERDAY)) / SECONDSPERDAY; 
	}
}

void FoxDateTime::DateTimeToSystemTime(SYSTEMTIME &sTime)
{
	int lnA, lnB, lnC, lnD, lnE, lnM;
	DWORD lnDays, lnSecs;
	double dDays, dSecs;

	dSecs = modf(m_Value.ev_real,&dDays);
	lnDays = (DWORD)dDays;

	lnA = lnDays + 32044;
	lnB = (4 * lnA + 3) / 146097;
	lnC = lnA - (lnB * 146097) / 4;

	lnD = (4 * lnC + 3) / 1461;
	lnE = lnC - (1461 * lnD) / 4;
	lnM = (5 * lnE + 2) / 153;
	
	sTime.wDay = (WORD) lnE - (153 * lnM + 2) / 5 + 1;
	sTime.wMonth = (WORD) lnM + 3 - 12 * (lnM / 10);
	sTime.wYear = (WORD) lnB * 100 + lnD - 4800 + lnM / 10;

	lnSecs = (int)floor(dSecs * 86400.0 + 0.1);
	sTime.wHour = static_cast<WORD>(lnSecs / 3600);
	lnSecs %= 3600;
	sTime.wMinute = (WORD)(lnSecs / 60);
	lnSecs %= 60;
	sTime.wSecond = (WORD)lnSecs;

	sTime.wDayOfWeek = (WORD)((lnDays + 1) % 7);
	sTime.wMilliseconds = 0; // FoxPro's datetime doesn't have milliseconds .. so just set to zero
}

void FoxDateTime::DateTimeToFileTime(FILETIME &sTime)
{
	LARGE_INTEGER nFileTime;
	double dDays, dSecs, dDateTime;

	if (m_Value.ev_real >= VFPFILETIMEBASE)
		dDateTime = m_Value.ev_real;
	else if (m_Value.ev_real == 0.0) // if empty date .. set filetime to zero
	{
		sTime.dwLowDateTime = 0;
		sTime.dwHighDateTime = 0;
		return;
	}
	else
		dDateTime = VFPFILETIMEBASE; // if before 1601/01/01 00:00:00 set to 1601/01/01 ..

	dSecs = modf(dDateTime,&dDays); // get absolute value and fractional part
	// cause double arithmetic isn't 100% accurate we have to round down to the nearest integer value
	dSecs = floor(dSecs * SECONDSPERDAY + 0.1);
	// + 0.1 cause we may get for example 34.9999899 after 0.xxxx * SECONDSPERDAY,
	// which really stands for 35 seconds after midnigth
	nFileTime.QuadPart = ((LONGLONG)(dDays - VFPFILETIMEBASE)) * NANOINTERVALSPERDAY +
						((LONGLONG)dSecs) * NANOINTERVALSPERSECOND;
	sTime.dwLowDateTime = nFileTime.LowPart;
	sTime.dwHighDateTime = nFileTime.HighPart;	
}

/* FoxDateTimeLiteral */
void FoxDateTimeLiteral::Convert(SYSTEMTIME &sTime, bool bToLocal)
{
	FILETIME sFileTime, sLocalFTime;
	SYSTEMTIME sSysTime;

	if (bToLocal)
	{
		if (!SystemTimeToFileTime(&sTime,&sFileTime))
		{
			SAVEWIN32ERROR(SystemTimeToFileTime,GetLastError());
			throw E_APIERROR;
		}
		if (!FileTimeToLocalFileTime(&sFileTime,&sLocalFTime))
		{
			SAVEWIN32ERROR(FileTimeToLocalFileTime,GetLastError());
			throw E_APIERROR;
		}
		if (!FileTimeToSystemTime(&sLocalFTime,&sSysTime))
		{
			SAVEWIN32ERROR(FileTimeToSystemTime,GetLastError());
			throw E_APIERROR;
		}

		if (sSysTime.wYear > 0 && sSysTime.wYear < 10000)
		{
			sprintf(m_Literal,"{^%04hu-%02hu-%02hu %02hu:%02hu:%02hu}",
			sSysTime.wYear,sSysTime.wMonth,sSysTime.wDay,sSysTime.wHour,sSysTime.wMinute,sSysTime.wSecond);
		}
		else
			strcpy(m_Literal,"{ ::}");

	}
	else
	{
		if (sTime.wYear > 0 && sTime.wYear < 10000)
		{
			sprintf(m_Literal,"{^%04hu-%02hu-%02hu %02hu:%02hu:%02hu}",
			sTime.wYear,sTime.wMonth,sTime.wDay,sTime.wHour,sTime.wMinute,sTime.wSecond);
		}
		else
			strcpy(m_Literal,"{ ::}");
	}
}

void FoxDateTimeLiteral::Convert(FILETIME &sTime, bool bToLocal)
{
	SYSTEMTIME sSysTime;
	FILETIME sFileTime;

	if (bToLocal)
	{
		if (!FileTimeToLocalFileTime(&sTime,&sFileTime))
		{
			SAVEWIN32ERROR(FileTimeToLocalFileTime,GetLastError());
			throw E_APIERROR;
		}
		if (!FileTimeToSystemTime(&sFileTime,&sSysTime))
		{
			SAVEWIN32ERROR(FileTimeToSystemTime,GetLastError());
			throw E_APIERROR;
		}
	}
	else if (!FileTimeToSystemTime(&sTime,&sSysTime))
	{
		SAVEWIN32ERROR(FileTimeToSystemTime,GetLastError());
		throw E_APIERROR;
	}

	if (sSysTime.wYear > 0 && sSysTime.wYear < 10000)
	{
		sprintf(m_Literal,"{^%04hu-%02hu-%02hu %02hu:%02hu:%02hu}",
		sSysTime.wYear,sSysTime.wMonth,sSysTime.wDay,sSysTime.wHour,sSysTime.wMinute,sSysTime.wSecond);
	}
	else
		strcpy(m_Literal,"{ ::}");
}

/* FoxObject */
FoxObject::FoxObject() : m_Property(0), m_ParameterRef(false) 
{
	m_Value.ev_type = 'O';
	m_Value.ev_object = 0;
}

FoxObject::FoxObject(Value &pVal) : m_Property(0), m_ParameterRef(true)
{
	assert(::Vartype(pVal) == 'O');
	m_Value.ev_type = 'O';
	m_Value.ev_object = pVal.ev_object;
}

FoxObject::FoxObject(ParamBlk *parm, int nParmNo) : m_Property(0)
{

	if (parm->pCount >= nParmNo && parm->p[nParmNo-1].val.ev_type == 'O')
	{
		m_Value.ev_type = 'O';
		m_Value.ev_object = parm->p[nParmNo-1].val.ev_object;
		m_ParameterRef = true;
	}
	else
	{
		m_Value.ev_type = '0';
		m_ParameterRef = false;
	}
}

FoxObject::FoxObject(char *pExpression) : m_Property(0), m_ParameterRef(false)
{
	m_Value.ev_type = '0';
	Evaluate(m_Value,pExpression);
}

FoxObject::~FoxObject()
{
	if (m_Value.ev_object)
	{
		UnlockObject();
		if (!m_ParameterRef)
			FreeObject();
	}
	m_Value.ev_type = '0';
}

void FoxObject::Release()
{
	if (m_Value.ev_object)
	{
		UnlockObject();
		if (!m_ParameterRef)
			FreeObject();
		else
			m_Value.ev_object = 0;
	}
	m_ParameterRef = false;
	m_Value.ev_type = '0';
}

FoxObject& FoxObject::NewObject(char *pClass)
{
	char aCommand[VFP2C_MAX_CALLBACKFUNCTION];

	/* free existing object */
	if (!m_ParameterRef)
		FreeObject();
	
	m_ParameterRef = false;
	// set to 0 (NULL), so when Evaluate fails the destructor doesn't free the object twice
	m_Value.ev_type = '0';
	sprintfex(aCommand,"CREATEOBJECT('%S')",pClass);
	Evaluate(m_Value,aCommand);
	return *this;
}

FoxObject& FoxObject::EmptyObject()
{
	/* free existing object */
	if (!m_ParameterRef)
		FreeObject();

	m_ParameterRef = false;

	m_Value.ev_type = '0'; // set to 0 (NULL)
	if (IS_FOX8ORHIGHER())
		Evaluate(m_Value,"CREATEOBJECT('Empty')");
	else
		Evaluate(m_Value,"CREATEOBJECT('Relation')");
	return *this;
}

FoxObject& FoxObject::operator()(char *pProperty)
{
	assert(pProperty);
	m_Property = pProperty;
	return *this;
}

FoxObject& FoxObject::operator=(FoxString &pString)
{
	assert(m_Property && m_Value.ev_object);
	int nErrorNo;
	if (nErrorNo = _SetObjectProperty(&m_Value,m_Property,pString,TRUE))
		throw nErrorNo;
	return *this;
}

FoxObject& FoxObject::operator=(FoxObject &pObject)
{
	assert(m_Property && m_Value.ev_object);
	int nErrorNo;
	if (nErrorNo = _SetObjectProperty(&m_Value,m_Property,pObject,TRUE))
		throw nErrorNo;
	return *this;
}

FoxObject& FoxObject::operator=(const Value &pVal)
{
	assert(m_Property && m_Value.ev_object);
	int nErrorNo;
	if (nErrorNo = _SetObjectProperty(&m_Value,m_Property,const_cast<Value*>(&pVal),TRUE))
		throw nErrorNo;
	return *this;
}

FoxObject& FoxObject::operator=(short nValue)
{
	assert(m_Property && m_Value.ev_object);
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'I';
	vTmp.ev_length = 6;
	vTmp.ev_long = nValue;
	if (nErrorNo = _SetObjectProperty(&m_Value,m_Property,&vTmp,TRUE))
		throw nErrorNo;
	return *this;
}

FoxObject& FoxObject::operator=(unsigned short nValue)
{
	assert(m_Property && m_Value.ev_object);
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'I';
	vTmp.ev_length = 6;
	vTmp.ev_long = nValue;
	if (nErrorNo = _SetObjectProperty(&m_Value,m_Property,&vTmp,TRUE))
		throw nErrorNo;
	return *this;
}
	
FoxObject& FoxObject::operator=(int nValue)
{
	assert(m_Property && m_Value.ev_object);
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'I';
	vTmp.ev_length = 11;
	vTmp.ev_long = nValue;
	if (nErrorNo = _SetObjectProperty(&m_Value,m_Property,&vTmp,TRUE))
		throw nErrorNo;
	return *this;
}

FoxObject& FoxObject::operator=(unsigned long nValue)
{
	assert(m_Property && m_Value.ev_object);
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'N';
	vTmp.ev_width = 10;
	vTmp.ev_length = 0;
	vTmp.ev_real = static_cast<double>(nValue);
	if (nErrorNo = _SetObjectProperty(&m_Value,m_Property,&vTmp,TRUE))
		throw nErrorNo;
	return *this;
}

FoxObject& FoxObject::operator=(bool bValue)
{
	assert(m_Property && m_Value.ev_object);
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'L';
	vTmp.ev_length = (int)bValue;
	if (nErrorNo = _SetObjectProperty(&m_Value,m_Property,&vTmp,TRUE))
		throw nErrorNo;
	return *this;
}

FoxObject& FoxObject::operator=(double nValue)
{
	assert(m_Property && m_Value.ev_object);
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'N';
	vTmp.ev_width = 20;
	vTmp.ev_length = 16;
	vTmp.ev_real = nValue;
	if (nErrorNo = _SetObjectProperty(&m_Value,m_Property,&vTmp,TRUE))
		throw nErrorNo;
	return *this;
}

FoxObject& FoxObject::operator=(__int64 nValue)
{
	assert(m_Property && m_Value.ev_object);
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'N';
	vTmp.ev_width = 20;
	vTmp.ev_length = 0;
	vTmp.ev_real = static_cast<double>(nValue);
	if (nErrorNo = _SetObjectProperty(&m_Value,m_Property,&vTmp,TRUE))
		throw nErrorNo;
	return *this;
}

/* FoxMemo */
FoxMemo::FoxMemo() : m_File(0), m_Location(0), m_pContent(0)
{
	memset(&m_Loc,0,sizeof(Locator));
}

FoxMemo::FoxMemo(ParamBlk *parm, int nParmNo) : m_pContent(0)
{
	if (parm->pCount >= nParmNo && IsMemoRef(parm->p[nParmNo-1].loc))
	{
		memcpy(&m_Loc, &parm->p[nParmNo-1].loc, sizeof(Locator));

		m_Location = _FindMemo(&m_Loc);
		if (m_Location < 0)
			throw E_FIELDNOTFOUND;

		m_File = _MemoChan(m_Loc.l_where);
		if (m_File == -1)
		{
			SAVECUSTOMERROREX("_MemoChan","Function failed for workarea %I.",m_Loc.l_where);
			throw E_APIERROR;
		}

		m_Size = _MemoSize(&m_Loc);
		if (m_Size < 0)
			throw m_Size;
	}
	else
	{
		m_File = 0;
		m_Location = 0;
		memset(&m_Loc,0,sizeof(Locator));
	}
}

FoxMemo::FoxMemo(Locator &pLoc) : m_pContent(0)
{
	memcpy(&m_Loc,&pLoc,sizeof(Locator));

	m_Location = _FindMemo(&m_Loc);
	if (m_Location < 0)
		throw E_FIELDNOTFOUND;

	m_File = _MemoChan(m_Loc.l_where);
	if (m_File == -1)
	{
		SAVECUSTOMERROREX("_MemoChan","Function failed for workarea %I.",m_Loc.l_where);
		throw E_APIERROR;
	}

	m_Size = _MemoSize(&m_Loc);
	if (m_Size < 0)
		throw m_Size;
}

FoxMemo::~FoxMemo()
{
	if (m_pContent)
		delete[] m_pContent;
}

void FoxMemo::Alloc(unsigned int nSize)
{
	m_Location = _AllocMemo(&m_Loc,nSize);
	if (m_Location == -1)
	{
		SAVECUSTOMERROR("_AllocMemo","Function failed.");
		throw E_APIERROR;
	}
}

void FoxMemo::Append(char *pData, unsigned int nLen)
{
	_FSeek(m_File,m_Location,FS_FROMBOF);
	if (_FWrite(m_File,pData,nLen) != nLen)
		throw _FError();
	m_Location += nLen;
}

char* FoxMemo::Read(unsigned int &nLen)
{
	unsigned int nBytes = nLen == 0 ? m_Size : nLen;

	if (m_pContent)
		delete[] m_pContent;

	m_pContent = new char[nBytes];
	if (m_pContent == 0)
		throw E_INSUFMEMORY;

	_FSeek(m_File, m_Location, FS_FROMBOF);
	nLen = _FRead(m_File, m_pContent, nBytes);
	return m_pContent;
}

FoxMemo& FoxMemo::operator=(FoxString &pString)
{
	/* if data is smaller or equal to 65000, we can use _DBReplace */
	if (pString.Len() <= 65000)
	{
		int nErrorNo;
		if (nErrorNo = _DBReplace(&m_Loc,pString))
			throw nErrorNo;
	}
	else
	{
		Alloc(pString.Len());
		_FSeek(m_File,m_Location,FS_FROMBOF);
		if (_FWrite(m_File,pString,pString.Len()) != pString.Len())
			throw _FError();
	}
	return *this;
}

/* FoxArray */
FoxArray::FoxArray(Value &pVal, bool bParamRef)
{
	assert(pVal.ev_type == 'C' && pVal.ev_length <= VFP_MAX_VARIABLE_NAME);
	m_ParameterRef = bParamRef;	
	if (!NullTerminateValue(pVal))
		throw E_INSUFMEMORY;
	LockHandle(pVal);
	m_Name = HandleToPtr(pVal);
	m_pValue = &pVal;
	m_Loc.l_NTI = 0;
}

FoxArray::FoxArray(Value &pVal, unsigned int nRows, unsigned int nDims)
{
	assert(pVal.ev_type == 'C' && pVal.ev_length <= VFP_MAX_VARIABLE_NAME);
	m_ParameterRef = true;
	if (!NullTerminateValue(pVal))
		throw E_INSUFMEMORY;
	LockHandle(pVal);
	m_Name = HandleToPtr(pVal);
	m_pValue = &pVal;
	Dimension(nRows,nDims);
}

FoxArray::FoxArray(Locator &pLoc)
{
	m_ParameterRef = false;
	m_pValue = 0;
	m_Loc.l_type = pLoc.l_type;
	m_Loc.l_NTI = pLoc.l_NTI;
	m_Loc.l_offset = pLoc.l_offset;
	m_Loc.l_where = pLoc.l_where;
	m_Loc.l_subs = pLoc.l_subs;
	m_Loc.l_sub1 = m_Loc.l_sub2 = 0;
	m_Rows = ALen(m_Dims);
}

FoxArray::FoxArray(ParamBlk *parm, int nParmNo)
{
	if (parm->pCount >= nParmNo)
	{
		Value *pVal = &parm->p[nParmNo-1].val;
		if (pVal->ev_type == 'C' && pVal->ev_length > 0)
		{
			m_ParameterRef = true;
			if (!NullTerminateValue(pVal))
				throw E_INSUFMEMORY;
			LockHandle(pVal);
			m_Name = HandleToPtr(pVal);
			m_pValue = pVal;
			m_Loc.l_NTI = 0;
			return;
		}
	}
	// else
	m_pValue = 0;
	m_ParameterRef = false;
	m_Name = 0;
}

FoxArray::FoxArray(ParamBlk *parm, int nParmNo, char cTypeCheck)
{
	if (parm->pCount >= nParmNo)
	{
		Value *pVal = &parm->p[nParmNo-1].val;
		if (Vartype(pVal) == 'C' && pVal->ev_length > 0)
		{
			m_ParameterRef = true;
			if (!NullTerminateValue(pVal))
				throw E_INSUFMEMORY;
			LockHandle(pVal);
			m_Name = HandleToPtr(pVal);
			m_pValue = pVal;
			m_Loc.l_NTI = 0;
			return;
		}
		else if (pVal->ev_type != cTypeCheck)
			throw E_INVALIDPARAMS;
	}
	// else
	m_pValue = 0;
	m_ParameterRef = false;
	m_Name = 0;
}

FoxArray::~FoxArray()
{
	if (m_pValue && m_pValue->ev_handle)
	{
		UnlockHandle(m_pValue);
		if (!m_ParameterRef)
			FreeHandle(m_pValue);
	}
}

void FoxArray::Dimension(unsigned int nRows, unsigned int nDims)
{
	int nErrorNo;
	if (!FindArray())
	{
		ReDimension(nRows,nDims);
		if (!FindArray())
			throw E_VARIABLENOTFOUND;
	}
	else
	{
		Value vFalse;
		vFalse.ev_type = 'L';
		vFalse.ev_length = 0;
		ReDimension(nRows,nDims);
		m_Loc.l_subs = 0;
		if (nErrorNo = _Store(&m_Loc,&vFalse))
			throw nErrorNo;
	}
	m_Loc.l_subs = nDims > 1 ? 2 : 1;
	m_Loc.l_sub1 = 0;
	m_Loc.l_sub2 = 0;
}

void FoxArray::Dimension(Value &pVal, unsigned int nRows, unsigned int nDims)
{
	if (!NullTerminateValue(pVal))
		throw E_INSUFMEMORY;
	LockHandle(pVal);
	m_Name = HandleToPtr(pVal);
	m_pValue = &pVal;
	Dimension(nRows,nDims);
}

void FoxArray::Dimension(char *pName, unsigned int nRows, unsigned int nDims)
{
	m_Name = pName;
	Dimension(nRows,nDims);
}

bool FoxArray::FindArray()
{
	NTI nVarNti;
	nVarNti = _NameTableIndex(const_cast<char*>(m_Name));
	if (nVarNti == -1)
		return false;
	return _FindVar(nVarNti,-1,&m_Loc) > 0;
}

void FoxArray::ReDimension(unsigned int nRows, unsigned int nDims)
{
	char aExeBuffer[256];
	if (nDims > 1)
		sprintfex(aExeBuffer,"DIMENSION %S[%U,%U]",m_Name,nRows,nDims);
	else
		sprintfex(aExeBuffer,"DIMENSION %S[%U]",m_Name,nRows);
	Execute(aExeBuffer);
	m_Rows = nRows;
	m_Dims = nDims;
}

unsigned int FoxArray::Grow(unsigned int nRows)
{
	m_Loc.l_sub1 += static_cast<unsigned short>(nRows);
	assert(m_Loc.l_sub1 <= 65000); // LCK only supports array's up to 65000 rows
	if (m_Loc.l_sub1 > m_Rows)
		ReDimension(m_Loc.l_sub1,m_Dims);
	return m_Loc.l_sub1;
}

unsigned int FoxArray::ALen(unsigned int &nDims)
{
	assert(m_Name);
	unsigned int nRows;
	if (m_Loc.l_NTI == 0 && !FindArray())
		throw E_VARIABLENOTFOUND;

	nRows = ARows(m_Loc);
	nDims = ADims(m_Loc);

	nDims = nDims > 0 ? nDims : 1;
	m_Loc.l_subs = nDims > 1 ? 2 : 1;
	m_Loc.l_sub1 = 0;
	m_Loc.l_sub2 = 0;
	return nRows;
}

void FoxArray::ReturnRows() const
{
	_RetInt(m_Loc.l_sub1,5);
}

void FoxArray::Load(Value &pValue)
{
	int nErrorNo;
	if (nErrorNo = _Load(&m_Loc,&pValue))
		throw nErrorNo;
}

void FoxArray::Load(FoxString &pString)
{
	Value vTmp;
	vTmp.ev_type = '0';
	int nErrorNo;
	if (nErrorNo = _Load(&m_Loc,&vTmp))
		throw nErrorNo;
	pString.Attach(vTmp);
}

void FoxArray::Load(FoxDateTime &pDateTime)
{
	int nErrorNo;
	if (nErrorNo = _Load(&m_Loc,pDateTime))
		throw nErrorNo;
}

void FoxArray::Load(int &nValue)
{
	Value vTmp;
	vTmp.ev_type = '0';
	int nErrorNo;
	if (nErrorNo = _Load(&m_Loc,&vTmp))
		throw nErrorNo;
	nValue = vTmp.ev_long;
}

void FoxArray::Load(float &nValue)
{
	Value vTmp;
	vTmp.ev_type = '0';
	int nErrorNo;
	if (nErrorNo = _Load(&m_Loc,&vTmp))
		throw nErrorNo;
	nValue = (float)vTmp.ev_real;
}

void FoxArray::Load(double &nValue)
{
	Value vTmp;
	vTmp.ev_type = '0';
	int nErrorNo;
	if (nErrorNo = _Load(&m_Loc,&vTmp))
		throw nErrorNo;
	nValue = vTmp.ev_real;
}

FoxArray& FoxArray::operator()(unsigned int nRow)
{
	m_Loc.l_sub1 = nRow;
	return *this;
}

FoxArray& FoxArray::operator()(unsigned int nRow, unsigned int nDim)
{
	m_Loc.l_sub1 = nRow;
	m_Loc.l_sub2 = nDim;
	return *this;
}

FoxArray& FoxArray::operator=(FoxString &pString)
{
	int nErrorNo;
	nErrorNo = _Store(&m_Loc,pString);
	if (nErrorNo)
		throw nErrorNo;
	return *this;
}

FoxArray& FoxArray::operator=(FoxObject &pObject)
{
	int nErrorNo;
	nErrorNo = _Store(&m_Loc,pObject);
	if (nErrorNo)
		throw nErrorNo;
	return *this;
}

FoxArray& FoxArray::operator=(FoxInt64 &pInt64)
{
	int nErrorNo;
	nErrorNo = _Store(&m_Loc, pInt64);
	if (nErrorNo)
		throw nErrorNo;
	return *this;
}

FoxArray& FoxArray::operator=(const Value &pVal)
{
	int nErrorNo;
	nErrorNo = _Store(&m_Loc,const_cast<Value*>(&pVal));
	if (nErrorNo)
		throw nErrorNo;
	return *this;
}

FoxArray& FoxArray::operator=(int nValue)
{
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'I';
	vTmp.ev_length = 11;
	vTmp.ev_long = nValue;
	if (nErrorNo = _Store(&m_Loc,&vTmp))
		throw nErrorNo;
	return *this;
}

FoxArray& FoxArray::operator=(unsigned long nValue)
{
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'N';
	vTmp.ev_width = 10;
	vTmp.ev_length = 0;
	vTmp.ev_real = static_cast<double>(nValue);
	if (nErrorNo = _Store(&m_Loc,&vTmp))
		throw nErrorNo;
	return *this;
}

FoxArray& FoxArray::operator=(bool bValue)
{
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'L';
	vTmp.ev_length = (int)bValue;
	if (nErrorNo = _Store(&m_Loc,&vTmp))
		throw nErrorNo;
	return *this;
}

FoxArray& FoxArray::operator=(double nValue)
{
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'N';
	vTmp.ev_width = 20;
	vTmp.ev_length = 16;
	vTmp.ev_real = nValue;
	if (nErrorNo = _Store(&m_Loc,&vTmp))
		throw nErrorNo;
	return *this;
}

FoxArray& FoxArray::operator=(__int64 nValue)
{
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'N';
	vTmp.ev_width = 20;
	vTmp.ev_length = 0;
	vTmp.ev_real = static_cast<double>(nValue);
	if (nErrorNo = _Store(&m_Loc,&vTmp))
		throw nErrorNo;
	return *this;
}

FoxArray::operator Value&()
{
	int nErrorNo;
	if (nErrorNo = _Load(&m_Loc,&m_Value))
		throw nErrorNo;
	return m_Value;
}

FoxCursor::~FoxCursor()
{
	if (m_pFieldLocs)
		delete[] m_pFieldLocs;
}

void FoxCursor::Create(char *pCursorName, char *pFields)
{
	FoxValue vValue;
	char aExeBuffer[8192];

	sprintfex(aExeBuffer, "SELECT('%S')", pCursorName);
	Evaluate(vValue, aExeBuffer);

	// if workarea == 0 the cursor does not exist
	if(vValue->ev_long == 0)
	{
		// create the cursor
		sprintfex(aExeBuffer,"CREATE CURSOR %S (%S)",pCursorName,pFields);
		Execute(aExeBuffer);

		// get the workarea
		Evaluate(vValue, "SELECT(0)");
	}
	
	m_WorkArea = vValue->ev_long;

	// get fieldcount
	sprintfex(aExeBuffer, "FCOUNT(%I)", m_WorkArea);
	Evaluate(vValue, aExeBuffer);
	m_FieldCnt = vValue->ev_long;

	m_pFieldLocs = new Locator[m_FieldCnt];
	if (m_pFieldLocs == 0)
		throw E_INSUFMEMORY;

	// get locators to each field
	NTI nVarNti;
	for (unsigned int nFieldNo = 1; nFieldNo <= m_FieldCnt; nFieldNo++)
	{
		sprintfex(aExeBuffer, "FIELD(%I,%I)+CHR(0)", nFieldNo, m_WorkArea);
		Evaluate(vValue, aExeBuffer);
	
        nVarNti = _NameTableIndex(vValue.HandleToPtr());
		vValue.Release();

		if (nVarNti == -1)
			throw E_FIELDNOTFOUND;

		if (!_FindVar(nVarNti, m_WorkArea, m_pFieldLocs + (nFieldNo-1)))
			throw E_FIELDNOTFOUND;
	}
}

void FoxCursor::AppendBlank()
{
	int nErrorNo;
	if (nErrorNo = _DBAppend(m_WorkArea, 0))
		throw nErrorNo;
}

FoxCursor& FoxCursor::operator()(unsigned int nFieldNo)
{
	m_pCurrentLoc = m_pFieldLocs + (nFieldNo-1);
	return *this;
}

FoxCursor& FoxCursor::operator=(const Value &pVal)
{
	int nErrorNo;
	if (nErrorNo = _DBReplace(m_pCurrentLoc,const_cast<Value*>(&pVal)))
		throw nErrorNo;
	return *this;
}

FoxCursor& FoxCursor::operator=(int nValue)
{
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'I';
	vTmp.ev_length = 11;
	vTmp.ev_long = nValue;
	if (nErrorNo = _DBReplace(m_pCurrentLoc,&vTmp))
		throw nErrorNo;
	return *this;
}

FoxCursor& FoxCursor::operator=(DWORD nValue)
{
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'N';
	vTmp.ev_width = 10;
	vTmp.ev_length = 0;
	vTmp.ev_real = static_cast<double>(nValue);
	if (nErrorNo = _DBReplace(m_pCurrentLoc,&vTmp))
		throw nErrorNo;
	return *this;
}

/* FoxCStringArray */
FoxCStringArray::~FoxCStringArray()
{
	if (m_pStrings)
		delete[] m_pStrings;
	if (m_pHandles)
	{
		for (unsigned int xj = 0; xj < m_Rows; xj++)
			FreeHandleEx(m_pHandles[xj]);
		delete[] m_pHandles;
	}
}

void FoxCStringArray::Dimension(unsigned int nRows)
{
	assert(!m_pStrings);

	m_pStrings = new char*[nRows];
	if (m_pStrings == 0)
		throw E_INSUFMEMORY;
    ZeroMemory(m_pStrings,sizeof(char*)*nRows);

    m_pHandles = new MHANDLE[nRows];
	if (m_pHandles == 0)
	{
		delete[] m_pStrings;
		m_pStrings = 0;
		throw E_INSUFMEMORY;
	}
	ZeroMemory(m_pHandles,sizeof(MHANDLE)*nRows);

	m_Rows = nRows;
}

unsigned int FoxCStringArray::operator=(FoxArray &pArray)
{
	unsigned int nRows, nDims;
	nRows = pArray.ALen(nDims);
	if (nRows)
	{
		Dimension(nRows);
		Value vString;
		for (unsigned int xj = 0; xj < nRows; xj++)
		{
			vString = pArray(xj+1);
			if (Vartype(vString) != 'C')
				throw E_INVALIDPARAMS;

			if (!NullTerminateValue(vString))
				throw E_INSUFMEMORY;

			LockHandle(vString);
			m_pStrings[xj] = HandleToPtr(vString);
			m_pHandles[xj] = vString.ev_handle;
		}
	}
	return nRows;
}


/* TimeZoneInfo class */
TimeZoneInfo::TimeZoneInfo() : m_Hwnd(0), m_Atom(0)
{
	WNDCLASSEX wndClass = {0};
	char *lpClass = "__VFP2C_TZWC";

	m_Atom = (ATOM)GetClassInfoEx(ghModule,lpClass,&wndClass);
	if (!m_Atom)
	{
		wndClass.cbSize = sizeof(WNDCLASSEX);
		wndClass.hInstance = ghModule;
		wndClass.lpfnWndProc = TimeChangeWindowProc;
		wndClass.lpszClassName = lpClass;
		m_Atom = RegisterClassEx(&wndClass);
	}

	if (m_Atom)
	{
		m_Hwnd = CreateWindowEx(0,(LPCSTR)m_Atom,0,WS_POPUP,0,0,0,0,0,0,ghModule,0);
		if (m_Hwnd)
			SetWindowLong(m_Hwnd,GWL_USERDATA,(LONG)this);
		else
			ADDWIN32ERROR(CreateWindowEx,GetLastError());
	}
	else
		ADDWIN32ERROR(RegisterClassEx,GetLastError());

	Refresh();
}

TimeZoneInfo::~TimeZoneInfo()
{
	if (m_Hwnd)
		DestroyWindow(m_Hwnd);
	if (m_Atom)
		UnregisterClass((LPCSTR)m_Atom,ghModule);
}

void TimeZoneInfo::Refresh()
{
	m_CurrentZone = GetTimeZoneInformation(&m_ZoneInfo);
	if (m_CurrentZone == TIME_ZONE_ID_STANDARD || m_CurrentZone == TIME_ZONE_ID_UNKNOWN)
		m_Bias = ((double)m_ZoneInfo.Bias * 60) / SECONDSPERDAY;
	else if (m_CurrentZone == TIME_ZONE_ID_DAYLIGHT)
		m_Bias = ((double)m_ZoneInfo.Bias * 60 + m_ZoneInfo.DaylightBias * 60) / SECONDSPERDAY;
	else
		m_Bias = 0;
}

LRESULT _stdcall TimeZoneInfo::TimeChangeWindowProc(HWND nHwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	if (uMsg == WM_TIMECHANGE)
	{
		TimeZoneInfo *lpTimeZone = (TimeZoneInfo*)GetWindowLong(nHwnd,GWL_USERDATA);
		lpTimeZone->Refresh();
	}
	return DefWindowProc(nHwnd,uMsg,wParam,lParam);
}

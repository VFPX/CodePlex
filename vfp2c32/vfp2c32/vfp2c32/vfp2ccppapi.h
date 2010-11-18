#ifndef _VFP2CCPPAPI_H__
#define _VFP2CCPPAPI_H__

#include <assert.h>

#define VFP_MAX_ARRAY_ROWS		65000
#define VFP_MAX_PROPERTY_NAME	253
#define VFP_MAX_VARIABLE_NAME	128
#define VFP_MAX_COLUMN_NAME		128
#define VFP_MAX_CURSOR_NAME		128
#define VFP_MAX_CHARCOLUMN		254
#define VFP_MAX_COLUMNS			255
// max fieldname = max cursorname + "." + max columnname
#define VFP_MAX_FIELDNAME		(VFP_MAX_CURSOR_NAME + 1 + VFP_MAX_COLUMN_NAME)

#define VFP_MAX_DATE_LITERAL	32

// some VFP internal error numbers
#define E_INSUFMEMORY		182
#define E_TYPECONFLICT		532
#define E_FIELDNOTFOUND		806
#define E_ARRAYNOTFOUND		176
#define E_VARIABLENOTFOUND	170
#define E_INVALIDPARAMS		901
#define E_NOENTRYPOINT		754
#define E_INVALIDSUBSCRIPT	224
#define E_NOTANARRAY		176  //232
#define E_LOCKFAILED		503
#define E_CUSTOMERROR		7777
#define E_APIERROR			12345678

#pragma warning(disable : 4290) // disable warning 4290 - VC++ doesn't implement throw ...

/* thin wrappers around LCK functions which throw an exception on error */
NTI _stdcall NewVar(char *pVarname, Locator &sVar, bool bPublic) throw(int);
NTI _stdcall FindVar(char *pVarname) throw(int);
void _stdcall FindVar(NTI nVarNti, Locator &sVar) throw(int);
void _stdcall FindVar(char *pVarname, Locator &sVar) throw(int);
void _stdcall StoreObjectRef(char *pName, NTI &nVarNti, Value &sObject);
void _stdcall ReleaseObjectRef(char *pName, NTI nVarNti);

inline void Evaluate(Value &pVal, char *pExpression)
{
	int nErrorNo;
	if (nErrorNo = _Evaluate(&pVal, pExpression))
		throw nErrorNo;
}

inline void Execute(char *pExpression)
{
	int nErrorNo;
	if (nErrorNo = _Execute(pExpression))
		throw nErrorNo;
}

inline void Store(Locator &sVar, const Value &sValue)
{
	int nErrorNo;
	if (nErrorNo = _Store(&sVar, const_cast<Value*>(&sValue)))
		throw nErrorNo;
}

inline void Load(Locator &sVar, Value &sValue)
{
	int nErrorNo;
	if (nErrorNo = _Load(&sVar, &sValue))
		throw nErrorNo;
}

inline void ReleaseVar(NTI nVarNti)
{
	int nErrorNo;
	if (nErrorNo = _Release(nVarNti))
		throw nErrorNo;
}

inline void ReleaseVar(char *pVarname)
{
	NTI nVarNti = FindVar(pVarname);
	ReleaseVar(nVarNti);
}

inline void ObjectRelease(const Value &sValue)
{
	int nErrorNo;
	if (nErrorNo = _ObjectRelease(const_cast<Value*>(&sValue)))
		throw nErrorNo;
}

inline long ALen(Locator &pLoc, int mode)
{
	int nSubscript;
	if (nSubscript = _ALen(pLoc.l_NTI, mode) == -1)
		throw E_NOTANARRAY;
	return nSubscript;
}

inline long AElements(Locator &pLoc)
{
	long nSubscript;
	nSubscript = _ALen(pLoc.l_NTI, AL_ELEMENTS);
	if (nSubscript == -1)
		throw E_NOTANARRAY;
	return nSubscript;
}

inline long ARows(Locator &pLoc)
{
	long nSubscript;
	nSubscript = _ALen(pLoc.l_NTI, AL_SUBSCRIPT1);
	if (nSubscript == -1)
		throw E_NOTANARRAY;
	return nSubscript;
}

inline long ADims(Locator &pLoc)
{
	int nSubscript;
	nSubscript = _ALen(pLoc.l_NTI, AL_SUBSCRIPT2);
	if (nSubscript == -1)
		throw E_NOTANARRAY;
	return nSubscript;
}

inline unsigned int Len(Value &pVal)
{
	return pVal.ev_length;
}

inline bool CheckOptionalParameterLen(ParamBlk *parm, int nParmNo)
{
	return parm->pCount >= nParmNo && parm->p[nParmNo-1].val.ev_length;
}

inline void ResetArrayLocator(Locator &pLoc, int nColumns = 1)
{
	pLoc.l_subs = nColumns > 1 ? 2 : 1;
	pLoc.l_sub1 = 0;
	pLoc.l_sub2 = 0;
}

/* overloaded Return function to return values to FoxPro without thinking about type issues */
inline void Return(char *pString) { _RetChar(pString); }
inline void Return(void *pPointer){ _RetInt(reinterpret_cast<int>(pPointer), 11); }
inline void Return(short nValue) { _RetInt(nValue, 6); }
inline void Return(unsigned short nValue) { _RetInt(nValue, 5); }
inline void Return(int nValue) { _RetInt(nValue, 11); }
inline void Return(unsigned int nValue) { _RetFloat(nValue, 10, 0); }
inline void Return(long nValue) { _RetInt(nValue, 11); }
inline void Return(unsigned long nValue) { _RetFloat(nValue, 10, 0); }
inline void Return(double nValue) { _RetFloat(nValue, 20, 16); }
inline void Return(double nValue, int nDecimals) { _RetFloat(nValue, 20, nDecimals); }
inline void Return(float nValue) { _RetFloat(nValue, 20, 7); }
inline void Return(float nValue, int nDecimals) { _RetFloat(nValue, 20, nDecimals); }
inline void Return(__int64 nValue) { _RetFloat(static_cast<double>(nValue), 20, 0); }
inline void Return(unsigned __int64 nValue) { _RetFloat(static_cast<double>(nValue), 20, 0); }
inline void Return(bool bValue) { _RetLogical(bValue); }
inline void Return(CCY nValue) { _RetCurrency(nValue, 21); }
inline void Return(CCY nValue, int nWidth) { _RetCurrency(nValue, nWidth); }
inline void Return(Value &pVal) { _RetVal(&pVal); }
inline void ReturnARows(Locator &pLoc) { _RetInt(pLoc.l_sub1, 5); }

/* Foxpro like Vartype function */
inline char Vartype(const Value &pVal) { return pVal.ev_type; }
inline char Vartype(Value *pVal) { return pVal->ev_type; }
inline char Vartype(Locator &pLoc) { return pLoc.l_type; }
inline char Vartype(Locator *pLoc) { return pLoc->l_type; }
inline char Vartype(Parameter &pParm) { return pParm.val.ev_type; }
inline char Vartype(Parameter *pParm) { return pParm->val.ev_type; }

/* Reference identification functions */
inline bool IsVariableRef(Locator &pLoc) { return pLoc.l_type == 'R' && pLoc.l_where == -1; }
inline bool IsMemoRef(Locator &pLoc) { return pLoc.l_type == 'R' && pLoc.l_where != -1; }

/* Memory Handle management */
inline char* HandleToPtr(MHandle pHandle) { return reinterpret_cast<char*>(_HandToPtr(pHandle)); }
inline char* HandleToPtr(const Value &pVal) { return reinterpret_cast<char*>(_HandToPtr(pVal.ev_handle)); }
inline char* HandleToPtr(Value *pVal) { return reinterpret_cast<char*>(_HandToPtr(pVal->ev_handle)); }

inline bool AllocHandleEx(Value &pVal, int nBytes) { pVal.ev_handle = _AllocHand(nBytes); return pVal.ev_handle != 0; }

inline void FreeHandle(MHandle pHandle) { if (pHandle) _FreeHand(pHandle); }
inline void FreeHandle(const Value &pVal) { if (pVal.ev_handle) _FreeHand(pVal.ev_handle); }
inline void FreeHandle(Value *pVal) { if (pVal->ev_handle) _FreeHand(pVal->ev_handle); }

inline void UnlockFreeHandle(MHandle pHandle) { if (pHandle) { _HUnLock(pHandle); _FreeHand(pHandle); } }
inline void UnlockFreeHandle(Value &pVal) { if (pVal.ev_handle) { _HUnLock(pVal.ev_handle); _FreeHand(pVal.ev_handle); } }

inline bool ValidHandle(Value &pVal) { return pVal.ev_handle > 0; }

inline void LockHandle(MHandle pHandle) { _HLock(pHandle); }
inline void LockHandle(const Value &pVal) { _HLock(pVal.ev_handle); }
inline void LockHandle(Value *pVal) { _HLock(pVal->ev_handle); }

inline void UnlockHandle(MHandle pHandle) { _HUnLock(pHandle); }
inline void UnlockHandle(const Value &pVal) { _HUnLock(pVal.ev_handle); }
inline void UnlockHandle(Value *pVal) { _HUnLock(pVal->ev_handle); }

inline unsigned long GetHandleSize(MHandle pHandle) { return _GetHandSize(pHandle); }
inline unsigned long GetHandleSize(const Value &pVal) { return _GetHandSize(pVal.ev_handle); }
inline unsigned long GetHandleSize(Value *pVal) { return _GetHandSize(pVal->ev_handle); }

inline bool SetHandleSize(MHandle pHandle, unsigned long nSize) { return _SetHandSize(pHandle, nSize) > 0; }
inline bool SetHandleSize(Value &pVal, unsigned long nSize) { return _SetHandSize(pVal.ev_handle, nSize) > 0; }
inline bool SetHandleSize(Value *pVal, unsigned long nSize) { return _SetHandSize(pVal->ev_handle, nSize) > 0; }

inline bool ExpandValue(Value &pVal, int nBytes) { return _SetHandSize(pVal.ev_handle, pVal.ev_length + nBytes) > 0; }
inline bool ExpandValue(Value *pVal, int nBytes) { return _SetHandSize(pVal->ev_handle, pVal->ev_length + nBytes) > 0; }

inline bool NullTerminateValue(Value &pVal) { return _SetHandSize(pVal.ev_handle, pVal.ev_length + 1) > 0; }
inline bool NullTerminateValue(Value *pVal) { return _SetHandSize(pVal->ev_handle, pVal->ev_length + 1) > 0; }

/* release resources of a Value if necessary */
inline void ReleaseValue(Value &pVal)
{ 
	if (pVal.ev_type == 'C' && pVal.ev_handle)
		_FreeHand(pVal.ev_handle);
	else if (pVal.ev_type == 'O' && pVal.ev_object)
		_FreeObject(&pVal);
}

/* table function wrappers */
inline int AppendBlank(int nWorkarea = -1) { return _DBAppend(nWorkarea, 0); }
inline int AppendBlank(Locator &pLoc) { return _DBAppend(pLoc.l_where, 0); }
inline int AppendCarry(int nWorkarea = -1) { return _DBAppend(nWorkarea, 1); }
inline int AppendCarry(Locator &pLoc) { return _DBAppend(pLoc.l_where, 1); }
inline int Append(int nWorkarea = -1) { return _DBAppend(nWorkarea, -1); }
inline int Append(Locator &pLoc) { return _DBAppend(pLoc.l_where, -1); }
inline long GoTop(int nWorkarea = -1) { return _DBRewind(nWorkarea); }
inline long GoTop(Locator &pLoc) { return _DBRewind(pLoc.l_where); }
inline long GoBottom(int nWorkarea = -1) { return _DBUnwind(nWorkarea); }
inline long GoBottom(Locator &pLoc) { return _DBUnwind(pLoc.l_where); }
inline long Skip(int nRecords, int nWorkarea = -1) { return _DBSkip(nWorkarea, nRecords); }
inline long Skip(int nRecords, Locator &pLoc) { return _DBSkip(pLoc.l_where, nRecords); }
inline long RecNo(int nWorkarea = -1) { return _DBRecNo(nWorkarea); }
inline long RecNo(Locator &pLoc) { return _DBRecNo(pLoc.l_where); }
inline long RecCount(int nWorkarea = -1) { return _DBRecCount(nWorkarea); }
inline long RecCount(Locator &pLoc) { return _DBRecCount(pLoc.l_where); }
inline int Go(long nRecord, int nWorkarea = -1) { return _DBRead(nWorkarea, nRecord); }
inline int Go(long nRecord, Locator &pLoc) { return _DBRead(pLoc.l_where, nRecord); }
inline int RLock(int nWorkarea = -1) { return _DBLock(nWorkarea,DBL_RECORD); }
inline int RLock(Locator &pLoc) { return _DBLock(pLoc.l_where,DBL_RECORD); }
inline int FLock(int nWorkarea = -1) { return _DBLock(nWorkarea,DBL_FILE); }
inline int FLock(Locator &pLoc) { return _DBLock(pLoc.l_where,DBL_FILE); }
inline void Unlock(int nWorkarea = -1) { return _DBUnLock(nWorkarea); }
inline void Unlock(Locator &pLoc) { return _DBUnLock(pLoc.l_where); }
inline bool Bof(int nWorkarea = -1) { return (_DBStatus(nWorkarea) & DB_BOF) > 0; }
inline bool Bof(Locator &pLoc) { return (_DBStatus(pLoc.l_where) & DB_BOF) > 0; }
inline bool Eof(int nWorkarea = -1) { return (_DBStatus(nWorkarea) & DB_EOF) > 0; }
inline bool Eof(Locator &pLoc) { return (_DBStatus(pLoc.l_where) & DB_EOF) > 0; }
inline bool RLocked(int nWorkarea = -1) { return (_DBStatus(nWorkarea) & DB_RLOCKED) > 0; }
inline bool RLocked(Locator &pLoc) { return (_DBStatus(pLoc.l_where) & DB_RLOCKED) > 0; }
inline bool FLocked(int nWorkarea = -1) { return (_DBStatus(nWorkarea) & DB_FLOCKED) > 0; }
inline bool FLocked(Locator &pLoc) { return (_DBStatus(pLoc.l_where) & DB_FLOCKED) > 0; }
inline bool Exclusiv(int nWorkarea = -1) { return (_DBStatus(nWorkarea) & DB_EXCLUSIVE) > 0; }
inline bool Exclusiv(Locator &pLoc) { return (_DBStatus(pLoc.l_where) & DB_EXCLUSIVE) > 0; }
inline bool Readonly(int nWorkarea = -1) { return (_DBStatus(nWorkarea) & DB_READONLY) > 0; }
inline bool Readonly(Locator &pLoc) { return (_DBStatus(pLoc.l_where) & DB_READONLY) > 0; }
inline int DBStatus(int nWorkarea = -1) { return _DBStatus(nWorkarea); }
inline int DBStatus(Locator &pLoc) { return _DBStatus(pLoc.l_where); }

inline int AppendRecords(unsigned int nRecords, int nWorkArea = -1)
{
	int nErrorNo = 0;
	if (!FLock(nWorkArea))
		return E_LOCKFAILED;
	while (nRecords--)
	{
		if (nErrorNo = AppendBlank(nWorkArea)) // append blank records
			break;
	}
	Unlock(nWorkArea);
	return nErrorNo;
}

inline int AppendRecords(unsigned int nRecords, Locator &pLoc)
{
	return AppendRecords(nRecords, pLoc.l_where);
}

/* access to common window handles */
inline HWND WMainHwnd() { return _WhToHwnd(_WMainWindow()); }
inline HWND WTopHwnd() { return _WhToHwnd(_WOnTop()); }
inline HWND WHwndByTitle(char *lcWindow) { return _WhToHwnd(_WFindTitle(lcWindow)); };

// misc helper functions
// transform 2 integers (a 64 Bit Integer) to a double 
inline double Ints2Double(int nLowInt, int nHighInt) { return ((double)nHighInt) * 4294967296.0 + nLowInt; }
inline __int64 Ints2Int64(int nLowInt, int nHighInt) { return ((__int64)nHighInt) * 4294967296 + nLowInt; }

// forward declaration 
class FoxObject;

/* base class for variable types*/
class FoxValue
{
public:
	FoxValue();
	FoxValue(char cType);
	FoxValue(char cType, int nWidth);
	FoxValue(char cType, int nWidth, unsigned long nPrec);
	FoxValue(Locator &pLoc);
	~FoxValue();
	
	FoxValue& Evaluate(char *pExpression);
	char Vartype() const;
	void Release();
	void Return();

	// handle manipulation
	FoxValue& AllocHandle(int nBytes);
	FoxValue& FreeHandle();
	char* HandleToPtr();
	FoxValue& LockHandle();
	FoxValue& UnlockHandle();
	unsigned int GetHandleSize();
	FoxValue& SetHandleSize(unsigned long nSize);
	FoxValue& ExpandHandle(int nBytes);
	FoxValue& NullTerminate();

	// object manipulation
	FoxValue& LockObject();
	FoxValue& UnlockObject();
	FoxValue& FreeObject();

	// operators
	FoxValue& operator=(Locator &pLoc);
	FoxValue& operator<<(FoxObject &pObject);
	operator Value&() { return m_Value; }
	operator Value*() { return &m_Value; }
	Value* operator->() { return &m_Value; }

protected:
	Value m_Value;
	bool m_Locked;
};

class FoxLogical : public FoxValue
{
public:
	FoxLogical() : FoxValue('L') {}
	~FoxLogical() {}

	FoxLogical& operator=(bool bValue) { m_Value.ev_length = bValue ? 1 : 0; return *this; }
	FoxLogical& operator=(BOOL bValue) { m_Value.ev_length = bValue; return *this; }
	operator bool() { return m_Value.ev_length > 0; }
	operator BOOL() { return m_Value.ev_length; }
};

class FoxShort : public FoxValue
{
public:
	FoxShort() : FoxValue('I', 6, 0) {}
	~FoxShort() {}

	FoxShort& operator=(short nValue) { m_Value.ev_long = nValue; return *this; }
	operator short() { return static_cast<short>(m_Value.ev_long); }
};

class FoxUShort : public FoxValue
{
public:
	FoxUShort() : FoxValue('I', 5, 0) {}
	~FoxUShort() {}

	FoxUShort& operator=(unsigned short nValue) { m_Value.ev_long = nValue; return *this; }
	operator unsigned short() { return static_cast<unsigned short>(m_Value.ev_long); }
};

class FoxInt : public FoxValue
{
public:
	FoxInt() : FoxValue('I', 11, 0) {}
	~FoxInt() {}

	FoxInt& operator=(int nValue) { m_Value.ev_long = nValue; return *this; }
	operator int() { return m_Value.ev_long; }
};

class FoxUInt : public FoxValue
{
public:
	FoxUInt() : FoxValue('N', 10, 0) {}
	~FoxUInt() {}

	FoxUInt& operator=(unsigned int nValue) { m_Value.ev_real = static_cast<double>(nValue); return *this; }
	operator unsigned int() { return static_cast<unsigned int>(m_Value.ev_real); }
};

class FoxFloat : public FoxValue
{
public:
	FoxFloat() : FoxValue('N', 20, 6) {}
	~FoxFloat() {}

	FoxFloat& operator=(float nValue) { m_Value.ev_real = static_cast<double>(nValue); return *this; }
	operator float() { return static_cast<float>(m_Value.ev_real); }
};

class FoxDouble : public FoxValue
{
public: 
	FoxDouble() : FoxValue('N', 20, 16) {}
	~FoxDouble() {}

	FoxDouble& operator=(double nValue) { m_Value.ev_real = nValue; return *this; }
	operator double() { return m_Value.ev_real; }
};

class FoxInt64 : public FoxValue
{
public:
	FoxInt64() : FoxValue('N', 20, 0) {}
	~FoxInt64() {}

	FoxInt64& operator=(double nValue) { m_Value.ev_real = nValue; return *this; }
	FoxInt64& operator=(__int64 nValue) { m_Value.ev_real = static_cast<double>(nValue); return *this; }
	FoxInt64& operator=(unsigned __int64 nValue) { m_Value.ev_real = static_cast<double>(nValue); return *this; }

	operator __int64() { return static_cast<__int64>(m_Value.ev_real); }
};

/* FoxString - wraps a FoxPro character/binary string */
class FoxString : public FoxValue
{
public:
	/* Constructors/Destructor */
	FoxString();
	FoxString(FoxString &pString);
	FoxString(Value &pVal);
	FoxString(Value &pVal, unsigned int nExpand);
	FoxString(ParamBlk *pParms, int nParmNo);
	FoxString(ParamBlk *pParms, int nParmNo, unsigned int nExpand);
	FoxString(const char *pString);
	FoxString(unsigned int nSize);
	FoxString(BSTR pString, UINT nCodePage = CP_ACP);
	FoxString(SAFEARRAY *pArray);
	~FoxString();

	unsigned int Size() const { return m_BufferSize; }
	FoxString& Size(unsigned int nSize);
	unsigned int Len() const { return m_Value.ev_length; }
	FoxString& Len(unsigned int nLen) { m_Value.ev_length = nLen; return *this; }
	bool Binary() const { return m_Value.ev_width == 1; }
	FoxString& FoxString::Binary(bool bBinary) { m_Value.ev_width = bBinary ? 1 : 0; return *this; }
	bool Empty() const;
	bool ICompare(char *pString) const;
	FoxString& Evaluate(char *pExpression);
	FoxString& Fullpath();
	FoxString& Alltrim();
	FoxString& LTrim();
	FoxString& RTrim();
	FoxString& Lower();
	FoxString& Upper();
	FoxString& Prepend(const char *pString);
	FoxString& Strtran(FoxString &sSearchFor, FoxString &sReplacement);
	FoxString& Replicate(char *pString, unsigned int nCount);
	unsigned int At(char cSearchFor, unsigned int nOccurence = 1, unsigned int nMax = 0) const;
	unsigned int GetWordCount(const char pSeperator) const;
	FoxString& StringLen();
	FoxString& StrnCpy(const char *pString, unsigned int nMaxLen);
	FoxString& CopyBytes(const unsigned char *pBytes, unsigned int nLen);
	FoxString& CopyDblString(const char *pDblString, unsigned int nMaxLen = 4096);
	unsigned int StringDblLen();
	unsigned int StringDblCount();
	unsigned int Expand(int nSize = 1);
	FoxString& ExtendBuffer(unsigned int nNewMinBufferSize);
	BSTR ToBSTR() const ;
	SAFEARRAY* ToU1SafeArray() const;
	FoxString& Attach(Value &pValue, unsigned int nExpand = 0);
	void Detach();
	void Detach(Value &pValue);
	void Return();
	void Release();

	/* operator overloads */
	FoxString& operator=(Locator &pLoc);
	FoxString& operator=(FoxValue &pValue);
	FoxString& operator<<(FoxObject &pObject);
	FoxString& operator=(FoxString &pString);
	FoxString& operator=(const char *pString);
	FoxString& operator=(const wchar_t *pWString);
	FoxString& operator+=(const char *pString);
	FoxString& operator+=(FoxString &pString);
	FoxString& operator+=(const char pChar);

	bool operator==(const char *pString) const;
	bool operator==(FoxString &pString) const;
	char& operator[](int nIndex) { return m_String[nIndex]; }
	char& operator[](unsigned long nIndex) { return m_String[nIndex]; }
	
	/* cast operators */
	operator char*() const { return m_String; }
	operator const char*() const { return m_String; }
	operator unsigned char*() const { return reinterpret_cast<unsigned char*>(m_String); }
	operator const unsigned char*() const { return reinterpret_cast<const unsigned char*>(m_String); }
	operator void*() const { return reinterpret_cast<void*>(m_String); }
	operator const void*() const { return reinterpret_cast<const void*>(m_String); }
	operator wchar_t*() const { return reinterpret_cast<wchar_t*>(m_String); }
	operator const wchar_t*() const { return reinterpret_cast<const wchar_t*>(m_String); }
	operator const Value&() { return m_Value; }

private:
	char *m_String;
	unsigned int m_BufferSize;
	bool m_ParameterRef;
};

/* FoxWString - wraps a unicode string */
class FoxWString : public FoxValue
{
public:
	/* Constructors/Destructor */
	FoxWString() : FoxValue('C'), m_String(0) {}
	FoxWString(Value &pVal);
	FoxWString(ParamBlk *pParms, int nParmNo);
	FoxWString(ParamBlk *pParms, int nParmNo, char cTypeCheck);
	FoxWString(FoxString& pString);
	~FoxWString();

	wchar_t* Duplicate();
	wchar_t* Detach();

	/* operator overloads */
	FoxWString& operator=(char *pString);
	FoxWString& operator=(FoxString& pString);
	operator wchar_t*() { return m_String; }
	operator const wchar_t*() { return m_String; }
	bool operator!() { return m_String == 0; }
	operator bool() { return m_String != 0; }

private:
	wchar_t *m_String;
};

/* FoxDate - wraps a FoxPro date */
class FoxDate : public FoxValue
{
public:
	FoxDate() : FoxValue ('D') { m_Value.ev_real = 0; }
	FoxDate(Value &pVal);
	FoxDate(SYSTEMTIME &sTime);
	FoxDate(FILETIME &sTime);
	~FoxDate() {};

	FoxDate& operator=(double nDate) { m_Value.ev_real = nDate; return *this; }
	FoxDate& operator=(const SYSTEMTIME &sTime);
	FoxDate& operator=(const FILETIME &sTime);
	operator SYSTEMTIME();
	operator FILETIME();

private:
	void SystemTimeToDate(const SYSTEMTIME &sTime);
	void FileTimeToDate(const FILETIME &sTime);
	void DateToSystemTime(SYSTEMTIME &sTime);
	void DateToFileTime(FILETIME &sTime);
};

/* FoxDateTime - wraps a FoxPro datetime */
class FoxDateTime : public FoxValue
{
public:
	FoxDateTime() : FoxValue('T') { m_Value.ev_real = 0; }
	FoxDateTime(Value &pVal);
	FoxDateTime(SYSTEMTIME &sTime);
	FoxDateTime(FILETIME &sTime);
	FoxDateTime(double dTime);
	~FoxDateTime() {}

	FoxDateTime& operator=(double nDateTime) { m_Value.ev_real = nDateTime; return *this; }
	FoxDateTime& operator=(const SYSTEMTIME &sTime);
	FoxDateTime& operator=(const FILETIME &sTime);
	operator SYSTEMTIME();
	operator FILETIME();
	FoxDateTime& ToUTC();
	FoxDateTime& ToLocal();

private:
	void SystemTimeToDateTime(const SYSTEMTIME &sTime);
	void FileTimeToDateTime(const FILETIME &sTime);
	void DateTimeToSystemTime(SYSTEMTIME &sTime);
	void DateTimeToFileTime(FILETIME &sTime);
};

/* FoxObject */
class FoxObject : public FoxValue
{
public:
	FoxObject() : m_Property(0), m_ParameterRef(false), FoxValue('O') { }
	FoxObject(Value &pVal);
	FoxObject(ParamBlk *parm, int nParmNo);
	FoxObject(char* pExpression);
	~FoxObject();

	FoxObject& NewObject(char *pClass);
	FoxObject& EmptyObject();
	FoxObject& Evaluate(char *pExpression);
	void Release(); 

	FoxObject& operator<<(FoxValue &pValue);
	FoxObject& operator<<(Locator &pLoc);
	FoxObject& operator<<(short nValue);
	FoxObject& operator<<(unsigned short nValue);
	FoxObject& operator<<(int nValue);
	FoxObject& operator<<(unsigned long nValue);
	FoxObject& operator<<(bool bValue);
	FoxObject& operator<<(double nValue);
	FoxObject& operator<<(__int64 nValue);

	FoxObject& operator()(char* pProperty);
	char * Property();
	bool operator!();
	operator bool();

private:
	bool m_ParameterRef;
	char *m_Property;
};

class FoxDateTimeLiteral
{
public:
	FoxDateTimeLiteral() { m_Literal[0] = '\0'; }
	~FoxDateTimeLiteral() {}

    void Convert(SYSTEMTIME &sTime, bool bToLocal = false);
	void Convert(FILETIME &sTime, bool bToLocal = false);
	operator char*() { return m_Literal; }

private:
	char m_Literal[VFP_MAX_DATE_LITERAL];
};

/* FoxReference */
class FoxReference
{
public:
	FoxReference() { m_Loc.l_NTI = 0; }
	FoxReference(Locator &pLoc) { m_Loc = pLoc; }
	~FoxReference() {}

	FoxReference& operator=(FoxValue &pValue);
	FoxReference& operator=(Locator &pLoc);
	FoxReference& operator<<(FoxObject &pObject);
	FoxReference& operator=(int nValue);
	FoxReference& operator=(unsigned long nValue);
	FoxReference& operator=(double nValue);
	FoxReference& operator=(bool bValue);
	
	operator Locator&() { return m_Loc; }

private:
	Locator m_Loc;
};

/* FoxVariable */
class FoxVariable
{
public:
	FoxVariable() : m_Nti(0) { m_Loc.l_NTI = 0; }
	FoxVariable(char *pName) : m_Nti(0) { Attach(pName); }
	FoxVariable(char *pName, bool bPublic) : m_Nti(0) { New(pName, bPublic); }
	~FoxVariable() { Release(); }

	FoxVariable& New(char *pName, bool bPublic);
	FoxVariable& Release();
	FoxVariable& Attach(char *pName);
	FoxVariable& Detach();

	FoxVariable& operator=(FoxValue &pValue);
	FoxVariable& operator=(Locator &pLoc);
	FoxVariable& operator<<(FoxObject &pObject);
	FoxVariable& operator=(int nValue);
	FoxVariable& operator=(unsigned long nValue);
	FoxVariable& operator=(double nValue);
	FoxVariable& operator=(bool bValue);
	operator Locator&();

private:
	NTI m_Nti;
	Locator m_Loc;
};

/* FoxMemo */
class FoxMemo
{
public:
	FoxMemo();
	FoxMemo(ParamBlk *parm, int nParmNo);
	FoxMemo(Locator &pLoc);
	~FoxMemo();

	void Alloc(unsigned int nSize);
	void Append(char *pData, unsigned int nLen);
	char* Read(unsigned int &nLen);

	FoxMemo& operator=(FoxString &pString);
	
private:
	Locator m_Loc;
	FCHAN m_File;
	long m_Location;
	long m_Size;
	char *m_pContent;
};

/* FoxArray */
class FoxArray
{
public:
	FoxArray();
	FoxArray(Value &pVal, unsigned int nRows = 0, unsigned int nDims = 0);
	FoxArray(Locator &pLoc);
	FoxArray(ParamBlk *parm, int nParmNo);
	FoxArray(ParamBlk *parm, int nParmNo, char cTypeCheck);
	~FoxArray() {};

	FoxArray& Dimension(unsigned int nRows, unsigned int nDims = 0);
	FoxArray& Dimension(Value &pVal, unsigned int nRows, unsigned int nDims = 0);
	FoxArray& Dimension(char *pName, unsigned int nRows, unsigned int nDims = 0);
	FoxArray& AutoGrow(unsigned int nRows);
	FoxArray& ValidateDimension(unsigned int nDim);
	unsigned int Grow(unsigned int nRows = 1);
	unsigned int ALen(unsigned int &nDims);
	unsigned int ARows() { return m_Rows; }
	unsigned int ADims() { return m_Dims; }
	unsigned short& CurrentRow();
	unsigned short& CurrentDim();
	void ReturnRows();

	FoxArray& operator()(unsigned int nRow);
	FoxArray& operator()(unsigned int nRow, unsigned int nDim);

	FoxArray& operator=(FoxValue &pValue);
	FoxArray& operator=(Locator &pLoc);
	FoxArray& operator<<(FoxObject &pObject);
	FoxArray& operator=(unsigned char nValue);
	FoxArray& operator=(void *pPointer);
	FoxArray& operator=(int nValue);
	FoxArray& operator=(unsigned int nValue);
	FoxArray& operator=(unsigned long nValue);
	FoxArray& operator=(bool bBool);
	FoxArray& operator=(double nValue);
	FoxArray& operator=(__int64 nValue);

	bool operator!();
	operator bool();
	operator Locator&();

private:
	void Init();
	void Init(Locator &pLoc);
	void Init(Value &pVal, unsigned int nRows = 0, unsigned int nDims = 0);
	void InitArray();
	void ReDimension(unsigned int nRows, unsigned int nDims = 0);
	bool FindArray();

	Locator m_Loc;
	char m_Name[VFP_MAX_VARIABLE_NAME+1];
	unsigned int m_Rows;
	unsigned int m_Dims;
	unsigned int m_AutoGrow;
};

/* FoxCursor */
class FoxCursor
{
public:
	FoxCursor() : m_FieldCnt(0), m_WorkArea(0), m_pFieldLocs(0), m_pCurrentLoc(0) {}
	~FoxCursor();

	FoxCursor& Create(char *pCursorName, char *pFields);
	FoxCursor& AppendBlank();
	FoxCursor& AppendCarry();
	FoxCursor& Append();
	int GoTop();
	int GoBottom();
	int Skip(int nRecords = 1);
	int RecNo();
	int RecCount();
	FoxCursor& Go(long nRecord);
	bool RLock();
	bool FLock();
	FoxCursor& Unlock();
	bool Bof();
	bool Eof();
	bool RLocked();
	bool FLocked();
	bool Exclusiv();
	bool Readonly();
	int DBStatus();

	FoxCursor& operator()(unsigned int nField);
	FoxCursor& operator=(FoxValue &pValue);
	FoxCursor& operator=(Locator &pLoc);
	FoxCursor& operator<<(FoxObject &pObject);
	FoxCursor& operator=(int nValue);
	FoxCursor& operator=(unsigned long nValue);
	
	operator Locator&() { return *m_pCurrentLoc; }

private:
	unsigned int m_FieldCnt;
	int m_WorkArea;
	Locator *m_pFieldLocs;
	Locator *m_pCurrentLoc;
};

class FoxCStringArray
{
public:
	FoxCStringArray() : m_Rows(0), m_pStrings(0), m_pValues(0) { }
	~FoxCStringArray();

	unsigned int ARows() { return m_Rows; }
	FoxCStringArray& FoxCStringArray::operator=(FoxArray &pArray);
	operator char**() { return m_pStrings; }
	operator LPCSTR*() { return (LPCSTR*)m_pStrings; }


private:
	void Dimension(unsigned int nRows);
	unsigned int m_Rows;
	char **m_pStrings;
	FoxValue *m_pValues;
};

// helper class which holds the current timezone information (static singleton in vfp2ccppapi.cpp)
class TimeZoneInfo
{
public:
	TimeZoneInfo();
	~TimeZoneInfo();

	static double Bias;
	void Refresh();
	static LRESULT _stdcall TimeChangeWindowProc(HWND nHwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

private:
	DWORD m_CurrentZone;
	TIME_ZONE_INFORMATION m_ZoneInfo;
	HWND m_Hwnd;
	ATOM m_Atom;
};

/* inline function implementations for the above classes */
/* FoxValue */
inline FoxValue::FoxValue() : m_Locked(false)
{
	m_Value.ev_type = '0';
	m_Value.ev_handle = 0;
	m_Value.ev_object = 0;
}

inline FoxValue::FoxValue(char cType) : m_Locked(false)
 {
 	m_Value.ev_type = cType;
	m_Value.ev_width = 0;
	m_Value.ev_length = 0;
 	m_Value.ev_object = 0;
 	m_Value.ev_handle = 0;
}

inline FoxValue::FoxValue(char cType, int nWidth) : m_Locked(false)
{
	m_Value.ev_type = cType;
	m_Value.ev_width = nWidth;
	m_Value.ev_real = 0.0;
}

inline FoxValue::FoxValue(char cType, int nWidth, unsigned long nPrec) : m_Locked(false)
{
	m_Value.ev_type = cType;
	m_Value.ev_width = nWidth; 
	m_Value.ev_length = nPrec;
	m_Value.ev_real = 0.0;
}

inline FoxValue::FoxValue(Locator &pLoc) : m_Locked(false)
{
	int nErrorNo;
	m_Value.ev_type = '0';
	if (nErrorNo = _Load(&pLoc, &m_Value))
		throw nErrorNo;
}

inline FoxValue::~FoxValue()
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

inline FoxValue& FoxValue::Evaluate(char *pExpression)
{
	Release();
	int nErrorNo;
	if (nErrorNo = _Evaluate(&m_Value, pExpression))
		throw nErrorNo;
	return *this;
}

inline char FoxValue::Vartype() const
{
	return m_Value.ev_type;
}

inline void FoxValue::Release()
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

inline void FoxValue::Return()
{
	assert(m_Locked == false);
	_RetVal(&m_Value);
	 m_Value.ev_type = '0';
}

inline FoxValue& FoxValue::AllocHandle(int nBytes)
{
	assert(m_Value.ev_handle == 0);
	m_Value.ev_handle = _AllocHand(nBytes);
	if (m_Value.ev_handle == 0)
		throw E_INSUFMEMORY;
	return *this;
}

inline FoxValue& FoxValue::FreeHandle()
{
	if (m_Value.ev_handle)
	{
		_FreeHand(m_Value.ev_handle);
		m_Value.ev_handle = 0;
	}
	return *this;
}

inline char* FoxValue::HandleToPtr()
{
	assert(Vartype() == 'C' && m_Value.ev_handle);
	return reinterpret_cast<char*>(_HandToPtr(m_Value.ev_handle));
}

inline FoxValue& FoxValue::LockHandle()
{
	if (m_Locked == false)
	{
		assert(Vartype() == 'C' && m_Value.ev_handle);
		_HLock(m_Value.ev_handle);
		m_Locked = true;
	}
	return *this;
}

inline FoxValue& FoxValue::UnlockHandle()
{
	if (m_Locked)
	{
		assert(Vartype() == 'C' && m_Value.ev_handle);
		_HUnLock(m_Value.ev_handle);
		m_Locked = false;
	}
	return *this;
}

inline unsigned int FoxValue::GetHandleSize()
{
	assert(Vartype() == 'C' && m_Value.ev_handle);
	return _GetHandSize(m_Value.ev_handle);
}

inline FoxValue& FoxValue::SetHandleSize(unsigned long nSize)
{
	assert(Vartype() == 'C' && m_Value.ev_handle && m_Locked == false);
	if (_SetHandSize(m_Value.ev_handle, nSize) == 0)
		throw E_INSUFMEMORY;
	return *this;
}

inline FoxValue& FoxValue::ExpandHandle(int nBytes)
{
	assert(Vartype() == 'C' && m_Value.ev_handle && m_Locked == false);
	if (_SetHandSize(m_Value.ev_handle, m_Value.ev_length + nBytes) == 0)
		throw E_INSUFMEMORY;
	return *this;
}

inline FoxValue& FoxValue::NullTerminate()
{
	assert(Vartype() == 'C' && m_Value.ev_handle && m_Locked == false);
	if (_SetHandSize(m_Value.ev_handle, m_Value.ev_length + 1) == 0)
		throw E_INSUFMEMORY;
	return *this;
}

inline FoxValue& FoxValue::LockObject()
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

inline FoxValue& FoxValue::UnlockObject()
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

inline FoxValue& FoxValue::FreeObject()
{
	if (m_Value.ev_object)
	{
		assert(Vartype() == 'O');
		_FreeObject(&m_Value);
		m_Value.ev_object = 0;
	}
	return *this;
}

inline FoxValue& FoxValue::operator=(Locator &pLoc)
{
	Release();
	int nErrorNo;
	if (nErrorNo = _Load(&pLoc, &m_Value))
		throw nErrorNo;
	return *this;
}

inline FoxValue& FoxValue::operator<<(FoxObject &pObject)
{
	Release();
	int nErrorNo;
	if (nErrorNo = _GetObjectProperty(&m_Value, pObject, pObject.Property()))
		throw nErrorNo;
}

/* FoxString */
inline FoxString& FoxString::Evaluate(char *pExpression)
{
	Release();
	int nErrorNo;
	if (nErrorNo = _Evaluate(&m_Value, pExpression))
		throw nErrorNo;
	return *this;
}

/* FoxObject */
inline FoxObject& FoxObject::Evaluate(char *pExpression)
{
	Release();
	int nErrorNo;
	if (nErrorNo = _Evaluate(&m_Value, pExpression))
		throw nErrorNo;
	return *this;
}

inline FoxObject& FoxObject::operator<<(FoxValue &pValue)
{
	assert(m_Property && m_Value.ev_object);
	int nErrorNo;
	if (nErrorNo = _SetObjectProperty(&m_Value, m_Property, pValue, TRUE))
		throw nErrorNo;
	return *this;
}

inline FoxObject& FoxObject::operator<<(Locator &pLoc)
{
	assert(m_Property && m_Value.ev_object);
	int nErrorNo;
	FoxValue pValue(pLoc);
	if (nErrorNo = _SetObjectProperty(&m_Value, m_Property, pValue, TRUE))
		throw nErrorNo;
	return *this;	
}

inline FoxObject& FoxObject::operator<<(short nValue)
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

inline FoxObject& FoxObject::operator<<(unsigned short nValue)
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
	
inline FoxObject& FoxObject::operator<<(int nValue)
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

inline FoxObject& FoxObject::operator<<(unsigned long nValue)
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

inline FoxObject& FoxObject::operator<<(bool bValue)
{
	assert(m_Property && m_Value.ev_object);
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'L';
	vTmp.ev_length = bValue ? 1 : 0;
	if (nErrorNo = _SetObjectProperty(&m_Value, m_Property, &vTmp, TRUE))
		throw nErrorNo;
	return *this;
}

inline FoxObject& FoxObject::operator<<(double nValue)
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

inline FoxObject& FoxObject::operator<<(__int64 nValue)
{
	assert(m_Property && m_Value.ev_object);
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'N';
	vTmp.ev_width = 20;
	vTmp.ev_length = 0;
	vTmp.ev_real = static_cast<double>(nValue);
	if (nErrorNo = _SetObjectProperty(&m_Value,m_Property, &vTmp, TRUE))
		throw nErrorNo;
	return *this;
}

inline FoxObject& FoxObject::operator()(char* pProperty)
{ 
	m_Property = pProperty;
	return *this;
}

inline char* FoxObject::Property()
{
	return m_Property;
}

inline bool FoxObject::operator!()
{
	return !(m_Value.ev_type == 'O' && m_Value.ev_object);
}

inline FoxObject::operator bool()
{
	return m_Value.ev_type == 'O' && m_Value.ev_object;
}

/* FoxVariable */
inline FoxVariable& FoxVariable::New(char *pName, bool bPublic)
{
	Release();
	m_Loc.l_subs = 0;
    m_Nti = _NewVar(pName, &m_Loc, bPublic ? NV_PUBLIC : NV_PRIVATE);
	if (m_Nti < 0)
		throw -m_Nti;
	return *this;
}

inline FoxVariable& FoxVariable::Attach(char *pName)
{
	Release();
	m_Nti = _NameTableIndex(pName);
	if (m_Nti == -1)
		throw E_VARIABLENOTFOUND;
	if (!_FindVar(m_Nti,-1, &m_Loc))
		throw E_VARIABLENOTFOUND;
	return *this;
}

inline FoxVariable& FoxVariable::Detach()
{
	m_Nti = 0;
	m_Loc.l_NTI = 0;
	return *this;
}

inline FoxVariable& FoxVariable::Release()
{
	if (m_Nti)
	{
		_Release(m_Nti);
		m_Nti = 0;
		m_Loc.l_NTI = 0;
	}
	return *this;
}

inline FoxVariable& FoxVariable::operator=(FoxValue &pValue)
{
	int nErrorNo;
	if (nErrorNo = _Store(&m_Loc, pValue))
		throw nErrorNo;
	return *this;
}

inline FoxVariable& FoxVariable::operator=(Locator &pLoc)
{
	int nErrorNo;
	FoxValue pValue(pLoc);
	if (nErrorNo = _Store(&m_Loc, pValue))
		throw nErrorNo;
	return *this;
}

inline FoxVariable& FoxVariable::operator<<(FoxObject &pObject)
{
	int nErrorNo;
	FoxValue pValue;
	pValue << pObject;
	if (nErrorNo = _Store(&m_Loc, pValue))
		throw nErrorNo;
}

inline FoxVariable& FoxVariable::operator=(int nValue)
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

inline FoxVariable& FoxVariable::operator=(unsigned long nValue)
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

inline FoxVariable& FoxVariable::operator=(double nValue)
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

inline FoxVariable& FoxVariable::operator=(bool bValue)
{
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'L';
	vTmp.ev_length = bValue ? 1 : 0;
	if (nErrorNo = _Store(&m_Loc,&vTmp))
		throw nErrorNo;
	return *this;
}

inline FoxVariable::operator Locator&()
{ 
	return m_Loc;
}

/* FoxArray */
inline FoxArray& FoxArray::AutoGrow(unsigned int nRows)
{ 
	m_AutoGrow = nRows;
	return *this;
}

inline FoxArray& FoxArray::ValidateDimension(unsigned int nDim)
{ 
	if (nDim > m_Dims) 
		throw E_INVALIDSUBSCRIPT;
	return *this;
}

inline unsigned int FoxArray::Grow(unsigned int nRows)
{
	assert(nRows + m_Loc.l_sub1 <= 65000); // LCK only supports array's up to 65000 rows
	m_Loc.l_sub1 += nRows;
	if (m_Loc.l_sub1 > m_Rows)
		ReDimension(min(m_Loc.l_sub1 + m_AutoGrow, 65000), m_Dims);
	return m_Loc.l_sub1;
}

inline void FoxArray::ReturnRows()
{
	if (m_AutoGrow && m_Loc.l_sub1 && m_Loc.l_sub1 < m_Rows)
		ReDimension(m_Loc.l_sub1, m_Dims);
	_RetInt(m_Loc.l_sub1,5);
}

inline FoxArray& FoxArray::operator()(unsigned int nRow)
{
	m_Loc.l_sub1 = nRow;
	return *this;
}

inline FoxArray& FoxArray::operator()(unsigned int nRow, unsigned int nDim)
{
	m_Loc.l_sub1 = nRow;
	m_Loc.l_sub2 = nDim;
	return *this;
}

inline unsigned short& FoxArray::CurrentRow()
{ 
	return m_Loc.l_sub1;
}

inline unsigned short& FoxArray::CurrentDim()
{ 
	return m_Loc.l_sub2;
}

inline FoxArray& FoxArray::operator=(FoxValue &pValue)
{
	assert(m_Loc.l_NTI);
	int nErrorNo;
	nErrorNo = _Store(&m_Loc, pValue);
	if (nErrorNo)
		throw nErrorNo;
	return *this;
}

inline FoxArray& FoxArray::operator=(Locator &pLoc)
{
	assert(m_Loc.l_NTI);
	FoxValue pValue(pLoc);
	int nErrorNo;
	nErrorNo = _Store(&m_Loc, pValue);
	if (nErrorNo)
		throw nErrorNo;
	return *this;
}

inline FoxArray& FoxArray::operator<<(FoxObject &pObject)
{
	int nErrorNo;
	FoxValue pValue;
	pValue << pObject;
	if (nErrorNo = _Store(&m_Loc, pValue))
		throw nErrorNo;
}

inline FoxArray& FoxArray::operator=(void *pPointer)
{
	assert(m_Loc.l_NTI);
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'I';
	vTmp.ev_length = 11;
	vTmp.ev_long = reinterpret_cast<int>(pPointer);
	if (nErrorNo = _Store(&m_Loc,&vTmp))
		throw nErrorNo;
	return *this;
}

inline FoxArray& FoxArray::operator=(unsigned char nValue)
{
	assert(m_Loc.l_NTI);
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'I';
	vTmp.ev_length = 3;
	vTmp.ev_long = static_cast<int>(nValue);
	if (nErrorNo = _Store(&m_Loc,&vTmp))
		throw nErrorNo;
	return *this;
}

inline FoxArray& FoxArray::operator=(int nValue)
{
	assert(m_Loc.l_NTI);
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'I';
	vTmp.ev_length = 11;
	vTmp.ev_long = nValue;
	if (nErrorNo = _Store(&m_Loc,&vTmp))
		throw nErrorNo;
	return *this;
}

inline FoxArray& FoxArray::operator=(unsigned int nValue)
{
	assert(m_Loc.l_NTI);
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

inline FoxArray& FoxArray::operator=(unsigned long nValue)
{
	assert(m_Loc.l_NTI);
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

inline FoxArray& FoxArray::operator=(bool bValue)
{
	assert(m_Loc.l_NTI);
	int nErrorNo;
	Value vTmp;
	vTmp.ev_type = 'L';
	vTmp.ev_length = bValue ? 1 : 0;
	if (nErrorNo = _Store(&m_Loc,&vTmp))
		throw nErrorNo;
	return *this;
}

inline FoxArray& FoxArray::operator=(double nValue)
{
	assert(m_Loc.l_NTI);
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

inline FoxArray& FoxArray::operator=(__int64 nValue)
{
	assert(m_Loc.l_NTI);
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

inline bool FoxArray::operator!()
{ 
	return m_Name[0] == '\0';
}

inline FoxArray::operator bool()
{ 
	return m_Name[0] != '\0';
}

inline FoxArray::operator Locator&()
{ 
	return m_Loc;
}

/* FoxCursor */
inline FoxCursor& FoxCursor::AppendBlank()
{
	int nErrorNo;
	if (nErrorNo = _DBAppend(m_WorkArea, 0) != 0)
		throw -nErrorNo;
	return *this;
}

inline FoxCursor& FoxCursor::AppendCarry()
{
	int nErrorNo;
	if (nErrorNo = _DBAppend(m_WorkArea, 1) != 0)
		throw -nErrorNo;
	return *this;
}

inline FoxCursor& FoxCursor::Append()
{
	int nErrorNo;
	if (nErrorNo = _DBAppend(m_WorkArea, -1) != 0)
		throw -nErrorNo;
	return *this;
}

inline int FoxCursor::GoTop()
{ 
	int recno;
	recno = _DBRewind(m_WorkArea);
	if (recno < 0)
		throw -recno;
	return recno;
}

inline int FoxCursor::GoBottom()
{
	int recno;
	recno = _DBUnwind(m_WorkArea);
	if (recno < 0)
		throw -recno;
	return recno;
}

inline int FoxCursor::Skip(int nRecords)
{
	int recno;
	recno = _DBSkip(m_WorkArea, nRecords);
	if (recno < 0)
		throw -recno;
	return recno;
}

inline int FoxCursor::RecNo()
{
	int recno;
	recno = _DBRecNo(m_WorkArea);
	if (recno < 0)
		throw -recno;
	return recno;
}

inline int FoxCursor::RecCount()
{
	int reccount;
	reccount = _DBRecCount(m_WorkArea);
	if (reccount < 0)
		throw -reccount;
	return reccount;
}

inline FoxCursor& FoxCursor::Go(long nRecord)
{ 
	int nErrorNo;
	if (nErrorNo = _DBRead(m_WorkArea, nRecord) < 0)
		throw -nErrorNo;
	return *this;
}

inline bool FoxCursor::RLock()
{ 
	return _DBLock(m_WorkArea, DBL_RECORD) > 0;
}

inline bool FoxCursor::FLock()
{ 
	return _DBLock(m_WorkArea,DBL_FILE) > 0;
}

inline FoxCursor& FoxCursor::Unlock()
{ 
	_DBUnLock(m_WorkArea);
	return *this;
}

inline bool FoxCursor::Bof()
{
	int status;
	status = _DBStatus(m_WorkArea);
	if (status < 0)
		throw -status;
	return (status & DB_BOF) > 0;
}

inline bool FoxCursor::Eof()
{
	int status;
	status = _DBStatus(m_WorkArea);
	if (status < 0)
		throw -status;
	return (status & DB_EOF) > 0;
}

inline bool FoxCursor::RLocked()
{
	int status;
	status = _DBStatus(m_WorkArea);
	if (status < 0)
		throw -status;
	return (status & DB_RLOCKED) > 0;
}

inline bool FoxCursor::FLocked()
{
	int status;
	status = _DBStatus(m_WorkArea);
	if (status < 0)
		throw -status;
	return (status & DB_FLOCKED) > 0;
}

inline bool FoxCursor::Exclusiv()
{
	int status;
	status = _DBStatus(m_WorkArea);
	if (status < 0)
		throw -status;
	return (status & DB_EXCLUSIVE) > 0;
}

inline bool FoxCursor::Readonly()
{
	int status;
	status = _DBStatus(m_WorkArea);
	if (status < 0)
		throw -status;
	return (status & DB_READONLY) > 0;
}

inline int FoxCursor::DBStatus()
{
	int status;
	status = _DBStatus(m_WorkArea);
	if (status < 0)
		throw -status;
	return status;
}

inline FoxCursor& FoxCursor::operator()(unsigned int nField)
{ 
	assert(nField <= m_FieldCnt);
	m_pCurrentLoc = m_pFieldLocs + (nField-1); 
	return *this;
}

inline FoxCursor& FoxCursor::operator=(FoxValue &pValue)
{
	int nErrorNo;
	if (nErrorNo = _DBReplace(m_pCurrentLoc,pValue))
		throw nErrorNo;
	return *this;
}

inline FoxCursor& FoxCursor::operator=(Locator &pLoc)
{
	int nErrorNo;
	FoxValue pValue(pLoc);
	if (nErrorNo = _DBReplace(m_pCurrentLoc, pValue))
		throw nErrorNo;
	return *this;
}

inline FoxCursor& FoxCursor::operator<<(FoxObject &pObject)
{
	int nErrorNo;
	FoxValue pValue;
	pValue << pObject;
	if (nErrorNo = _DBReplace(m_pCurrentLoc, pValue))
		throw nErrorNo;
}

inline FoxCursor& FoxCursor::operator=(int nValue)
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

inline FoxCursor& FoxCursor::operator=(unsigned long nValue)
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

#endif // _VFP2CCPPAPI_H__
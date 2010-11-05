#ifndef _VFP2CCPPAPI_H__
#define _VFP2CCPPAPI_H__

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

inline void  Evaluate(Value &pVal, char *pExpression)
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

inline void Store(Locator &sVar, Value &sValue)
{
	int nErrorNo;
	if (nErrorNo = _Store(&sVar, &sValue))
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

inline void ObjectRelease(Value &sValue)
{
	int nErrorNo;
	if (nErrorNo = _ObjectRelease(&sValue))
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
	int nSubscript;
	if (nSubscript = _ALen(pLoc.l_NTI, AL_ELEMENTS) == -1)
		throw E_NOTANARRAY;
	return nSubscript;
}

inline long ARows(Locator &pLoc)
{
	int nSubscript;
	if (nSubscript = _ALen(pLoc.l_NTI, AL_SUBSCRIPT1) == -1)
		throw E_NOTANARRAY;
	return nSubscript;
}

inline long ADims(Locator &pLoc)
{
	int nSubscript;
	if (nSubscript = _ALen(pLoc.l_NTI, AL_SUBSCRIPT2) == -1)
		throw E_NOTANARRAY;
	return nSubscript;
}

/* overloaded Return function to return values to FoxPro without thinking about type issues */
inline void Return(char *pString) { _RetChar(pString); }
inline void Return(void *pPointer){ _RetInt((int)pPointer,11); }
inline void Return(int nValue) { _RetInt(nValue,11); }
inline void Return(unsigned int nValue) { _RetFloat(static_cast<double>(nValue),10,0); }
inline void Return(long nValue) { _RetInt(nValue,11); }
inline void Return(unsigned long nValue) { _RetFloat(static_cast<double>(nValue),10,0); }
inline void Return(double nValue) { _RetFloat(nValue,20,16); }
inline void Return(double nValue, int nDecimals) { _RetFloat(nValue,20,nDecimals); }
inline void Return(float nValue) { _RetFloat(nValue,20,7); }
inline void Return(float nValue, int nDecimals) { _RetFloat(nValue,20,nDecimals); }
inline void Return(__int64 nValue) { _RetFloat(static_cast<double>(nValue),20,0); }
inline void Return(unsigned __int64 nValue) { _RetFloat(static_cast<double>(nValue),20,0); }
inline void Return(bool bValue) { _RetLogical((int)bValue); }
inline void Return(CCY nValue) { _RetCurrency(nValue,21); }
inline void Return(CCY nValue, int nWidth) { _RetCurrency(nValue,nWidth); }
inline void Return(Value &pVal) { _RetVal(&pVal); }
inline void ReturnARows(Locator &pLoc) { _RetInt(pLoc.l_sub1, 5); }

/* Foxpro like Vartype function */
inline char Vartype(Value &pVal) { return pVal.ev_type; }
inline char Vartype(Value *pVal) { return pVal->ev_type; }
inline char Vartype(Locator &pLoc) { return pLoc.l_type; }
inline char Vartype(Locator *pLoc) { return pLoc->l_type; }
inline char Vartype(Parameter &pParm) { return pParm.val.ev_type; }
inline char Vartype(Parameter *pParm) { return pParm->val.ev_type; }

/* Reference identification functions */
inline bool IsVariableRef(Locator &pLoc) { return pLoc.l_type == 'R' && pLoc.l_where == -1; }
inline bool IsMemoRef(Locator &pLoc) { return pLoc.l_type == 'R' && pLoc.l_where != -1; }

/* Memory Handle management */
inline char* HandleToPtr(MHandle pHandle) { return static_cast<char*>(_HandToPtr(pHandle)); }
inline char* HandleToPtr(const Value &pVal) { return static_cast<char*>(_HandToPtr(pVal.ev_handle)); }
inline char* HandleToPtr(Value *pVal) { return static_cast<char*>(_HandToPtr(pVal->ev_handle)); }

inline bool AllocHandleEx(Value &pVal, int nBytes) { pVal.ev_handle = _AllocHand(nBytes); return pVal.ev_handle != 0; }

inline void FreeHandle(MHandle pHandle) { if (pHandle) _FreeHand(pHandle); }
inline void FreeHandle(const Value &pVal) { if (pVal.ev_handle) _FreeHand(pVal.ev_handle); }
inline void FreeHandle(Value *pVal) { if (pVal->ev_handle) _FreeHand(pVal->ev_handle); }

inline void FreeHandleEx(MHandle pHandle) { if (pHandle) { _HUnLock(pHandle); _FreeHand(pHandle); } }
inline void FreeHandleEx(Value &pVal) { if (pVal.ev_handle) { _HUnLock(pVal.ev_handle); _FreeHand(pVal.ev_handle); } }

inline bool ValidHandle(Value &pVal) { return pVal.ev_handle != 0; }

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

inline bool NullTerminateValue(const Value &pVal) { return _SetHandSize(pVal.ev_handle, pVal.ev_length + 1) > 0; }
inline bool NullTerminateValue(Value *pVal) { return _SetHandSize(pVal->ev_handle, pVal->ev_length + 1) > 0; }

/* release resources of  a Value if necessary */
inline void FreeObject(Value &pVal) { if (Vartype(pVal) == 'O' && pVal.ev_object) _FreeObject(&pVal); }
inline void ReleaseValue(Value &pVal) { if (Vartype(pVal) == 'C') FreeHandle(pVal); else FreeObject(pVal); }

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

/*
class FoxValueC : public Value
{
	FoxValueC() : ev_type = 'C';
};
*/

/* base class for variable types*/
class FoxValue
{
public:
	FoxValue() { m_Value.ev_type = '0'; }
	FoxValue(char cType) { m_Value.ev_type = cType; m_Value.ev_long = 0; m_Value.ev_width = 0; m_Value.ev_length = 0; m_Value.ev_handle = 0; m_Value.ev_real = 0.0; }
	FoxValue(char cType, int nWidth) { m_Value.ev_type = cType; m_Value.ev_width = nWidth; m_Value.ev_real = 0.0; }
	FoxValue(char cType, int nWidth, unsigned long nPrec) { m_Value.ev_type = cType; m_Value.ev_width = nWidth; m_Value.ev_length = nPrec; m_Value.ev_real = 0.0; }
	~FoxValue();
	
	FoxValue& Load(Locator& pLoc);

	void Release();
	Value& GetReference() { return m_Value; }
	void Return() { _RetVal(&m_Value); }
	operator const Value&() const { return m_Value; }
	operator Value*() { return &m_Value; }


protected:
	Value m_Value;
};

class FoxInt64 : public FoxValue
{
public:
	FoxInt64() { m_Value.ev_type = 'N'; m_Value.ev_width = 20; m_Value.ev_length = 0; }
	~FoxInt64() {}

	FoxInt64& operator=(double nValue);
	FoxInt64& operator=(__int64 nValue);
	FoxInt64& operator=(unsigned __int64 nValue);
};

class FoxFormatParam;

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
	bool Binary() const;
	FoxString& Binary(bool bBinary);
	bool Empty() const;
	bool ICompare(char *pString) const;
	FoxString& Fullpath();
	FoxString& Alltrim();
	FoxString& LTrim();
	FoxString& RTrim();
	FoxString& Lower();
	FoxString& Upper();
	FoxString& Prepend(const char *pString);
	FoxString& Chrtran(char *pSearch, char *pReplacement);
	FoxString& Strtran(FoxString &sSearchFor, FoxString &sReplacement);
	FoxString& Replicate(char *pString, unsigned int nCount);
	unsigned int At(char cSearchFor, unsigned int nOccurence = 1, unsigned int nMax = 0) const;
	unsigned int RAt(char cSearchFor, unsigned int nOccurence = 1, unsigned int nMax = 0) const;
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
	void Attach(Value &pValue, unsigned int nExpand = 0);
	void Detach();
	void Detach(Value &pValue);
	void Return();
	FoxString& Format(const char *pFormat, FoxFormatParam fp1);
	FoxString& Format(const char *pFormat, FoxFormatParam fp1, FoxFormatParam fp2);

	/* operator overloads */
	FoxString& operator=(FoxString &pString);
	FoxString& operator=(const char *pString);
	FoxString& operator=(const Value &pVal);
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

private:
	void ReleaseValue();
	char *m_String;
	unsigned int m_BufferSize;
	bool m_ParameterRef;
};

/* FoxWString - wraps a unicode string */
class FoxWString : public FoxValue
{
public:
	/* Constructors/Destructor */
	FoxWString() : m_String(0) {}
	FoxWString(Value &pVal);
	FoxWString(ParamBlk *pParms, int nParmNo);
	FoxWString(ParamBlk *pParms, int nParmNo, char cTypeCheck);
	FoxWString(FoxString& pString);
	~FoxWString();

	wchar_t* Duplicate();
	wchar_t* Detach();

	/* operator overloads */
	FoxWString& FoxWString::operator=(char *pString);
	FoxWString& FoxWString::operator=(FoxString& pString);
	operator wchar_t*() { return m_String; }
	operator const wchar_t*() { return m_String; }
	bool operator!() { return m_String == 0; }
	operator bool() { return m_String != 0; }

private:
	wchar_t * m_String;
};

/* FoxDate - wraps a FoxPro date */
class FoxDate : public FoxValue
{
public:
	FoxDate() {	m_Value.ev_type = 'D'; m_Value.ev_real = 0; }
	FoxDate(Value &pVal);
	FoxDate(SYSTEMTIME &sTime);
	FoxDate(FILETIME &sTime);
	~FoxDate() {};

	FoxDate& operator=(double nDate);
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
	FoxDateTime() { m_Value.ev_type = 'T'; m_Value.ev_real = 0; }
	FoxDateTime(Value &pVal);
	FoxDateTime(SYSTEMTIME &sTime);
	FoxDateTime(FILETIME &sTime);
	FoxDateTime(double dTime);
	~FoxDateTime() {}

	FoxDateTime& operator=(double nDateTime);
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
	FoxObject();
	FoxObject(Value &pVal);
	FoxObject(ParamBlk *parm, int nParmNo);
	FoxObject(char* pExpression);
	~FoxObject();

	FoxObject& NewObject(char *pClass);
	FoxObject& EmptyObject();
	FoxObject& Lock();
	FoxObject& Unlock();

	FoxObject& operator=(FoxString &pString);
	FoxObject& operator=(FoxObject &pObject);
	FoxObject& operator=(const Value &pVal);
	FoxObject& operator=(short nValue);
	FoxObject& operator=(unsigned short nValue);
	FoxObject& operator=(int nValue);
	FoxObject& operator=(unsigned long nValue);
	FoxObject& operator=(bool bValue);
	FoxObject& operator=(double nValue);
	FoxObject& operator=(__int64 nValue);

	FoxObject& operator()(char* pProperty);

	bool operator!() { return !(m_Value.ev_type == 'O' && m_Value.ev_object); }
	operator bool() { return m_Value.ev_type == 'O' && m_Value.ev_object; }

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
	FoxReference() : m_pLoc(0) {}
	FoxReference(Locator &pLoc);
	~FoxReference() {}

	FoxReference& operator=(const Value &pVal);
	FoxReference& operator=(FoxString &pString);
	FoxReference& operator=(int nValue);
	FoxReference& operator=(unsigned long nValue);
	FoxReference& operator=(double nValue);
	FoxReference& operator=(bool bValue);
	
	FoxReference& Load(Value &pVal);

private:
	Locator *m_pLoc;
};

/* FoxVariable */
class FoxVariable
{
public:
	FoxVariable();
	FoxVariable(char *pName);
	FoxVariable(char *pName, bool bPublic);
	~FoxVariable();

	void New(char *pName, bool bPublic);
	void Release();
	void Attach(char *pName);
	void Detach();

	FoxVariable& operator=(const Value &pVal);
	FoxVariable& operator=(FoxString &pString);
	FoxVariable& operator=(int nValue);
	FoxVariable& operator=(unsigned long nValue);
	FoxVariable& operator=(double nValue);
	FoxVariable& operator=(bool bValue);
	operator Locator&() { return m_Loc; };
	operator NTI() { return m_Nti; };

private:
	NTI m_Nti;
	Locator m_Loc;
};



/* FoxMemo - guess what :) */
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

/* FoxArray - wraps a FoxPro array */
class FoxArray
{
public:
	FoxArray() : m_pValue(0), m_Name(0), m_Rows(0), m_Dims(0) {}
	FoxArray(Value &pVal, bool bParamRef = true);
	FoxArray(Value &pVal, unsigned int nRows, unsigned int nDims);
	FoxArray(Locator &pLoc);
	FoxArray(ParamBlk *parm, int nParmNo);
	FoxArray(ParamBlk *parm, int nParmNo, char cTypeCheck);
	~FoxArray();

	void Dimension(unsigned int nRows, unsigned int nDims = 0);
	void Dimension(Value &pVal, unsigned int nRows, unsigned int nDims = 0);
	void Dimension(char *pName, unsigned int nRows, unsigned int nDims = 0);
	void ReDimension(unsigned int nRows, unsigned int nDims = 0);
	unsigned int Grow(unsigned int nRows = 1);
	unsigned int ALen(unsigned int &nDims);
	void ReturnRows() const;
	void Load(Value &pValue);
	void Load(FoxString &pString);
	void Load(FoxDateTime &pDateTime);
	void Load(int &nValue);
	void Load(float &nValue);
	void Load(double &nValue);

	FoxArray& operator()(unsigned int nRow);
	FoxArray& operator()(unsigned int nRow, unsigned int nDim);
	FoxArray& operator=(FoxString &pString);
	FoxArray& operator=(FoxObject &pObject);
	FoxArray& operator=(const Value &pVal);
	FoxArray& operator=(int nValue);
	FoxArray& operator=(unsigned long nValue);
	FoxArray& operator=(bool bBool);
	FoxArray& operator=(double nValue);
	FoxArray& operator=(__int64 nValue);
	operator Value&();
	bool operator!() { return m_Name == 0; }
	operator bool() { return m_Name != 0; }
	
private:
	bool FindArray();
	Locator m_Loc;
	Value *m_pValue;
	Value m_Value;
	const char *m_Name;
	unsigned int m_Rows;
	unsigned int m_Dims;
	bool m_ParameterRef;
};

/* FoxCursor */
class FoxCursor
{
public:
	FoxCursor() : m_FieldCnt(0), m_WorkArea(0), m_pFieldLocs(0), m_pCurrentLoc(0) {}
	~FoxCursor();

	void Create(char *pCursorName, char *pFields);
	void AppendBlank();
	FoxCursor& operator()(unsigned int nField);
	FoxCursor& operator=(const Value &pVal);
	FoxCursor& operator=(int nValue);
	FoxCursor& operator=(DWORD nValue);

private:
	unsigned int m_FieldCnt;
	int m_WorkArea;
	Locator *m_pFieldLocs;
	Locator *m_pCurrentLoc;
};

class FoxCStringArray
{
public:
	FoxCStringArray() : m_Rows(0), m_pStrings(0), m_pHandles(0) { }
	~FoxCStringArray();

	unsigned int FoxCStringArray::operator=(FoxArray &pArray);
	operator char**() { return m_pStrings; }
	operator LPCSTR*() { return (LPCSTR*)m_pStrings; }

private:
	void Dimension(unsigned int nRows);
	unsigned int m_Rows;
	char **m_pStrings;
	MHANDLE *m_pHandles;
};

// helper class which holds the current timezone information (static singleton in vfp2ccppapi.cpp)
class TimeZoneInfo
{
public:
	TimeZoneInfo();
	~TimeZoneInfo();

	double Bias() { return m_Bias; }
	void Refresh();
	static LRESULT _stdcall TimeChangeWindowProc(HWND nHwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

private:
	DWORD m_CurrentZone;
	TIME_ZONE_INFORMATION m_ZoneInfo;
	HWND m_Hwnd;
	ATOM m_Atom;
	double m_Bias;
};

#endif // _VFP2CCPPAPI_H__
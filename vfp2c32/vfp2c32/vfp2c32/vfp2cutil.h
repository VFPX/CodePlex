#ifndef _VFP2CUTIL_H__
#define _VFP2CUTIL_H__

#ifdef __cplusplus
extern "C" {
#endif

#define SECONDSPERDAY 86400
#define MAXVFPFILETIME 2650467743990000000
#define VFPFILETIMEBASE 2305814.0
#define VFPOLETIMEBASE	2415019.0
#define NANOINTERVALSPERSECOND 10000000
#define NANOINTERVALSPERDAY 864000000000

#define VFP2C_MAX_DATE_LITERAL 32
#define VFP2C_MAX_DOUBLE_LITERAL 66
#define VFP2C_MAX_SHORT_LITERAL 6
#define VFP2C_MAX_INT_LITERAL 11
#define VFP2C_MAX_BIGINT_LITERAL 20

#define MIN_CHAR	-128
#define MAX_CHAR	127
#define MIN_UCHAR	0
#define MAX_UCHAR	255
#define MIN_SHORT	-32768
#define MAX_SHORT	32767
#define MIN_USHORT	0
#define MAX_USHORT	65535
#define MIN_INT		-2147483648
#define MAX_INT		2147483647
#define MIN_UINT 	0
#define MAX_UINT 	4294967295

#define STREQUAL(pString,pString2) (strcmp(pString,pString2) == 0)
#define STRIEQUAL(pString,pString2) (stricmp(pString,pString2) == 0)

#define IS_DIGIT(pChar) ((pChar) >= '0' && (pChar) <= '9')
#define IS_CHARACTER(pChar) (((pChar) >= 'a' && (pChar) <= 'z') || ((pChar) >= 'A' && (pChar) <= 'Z'))

#define	TO_UPPER(pChar)   (((pChar) >= 97 && (pChar) <= 122) ? (pChar) - 32 : (pChar))
#define	TO_LOWER(pChar)   (((pChar) >= 65 && (pChar) <= 90) ? (pChar) + 32 : (pChar))

// macros to test operation system platform
#define IS_WIN2KXP()		(gsOSVerInfo.dwPlatformId == VER_PLATFORM_WIN32_NT && gsOSVerInfo.dwMajorVersion == 5 \
							&& (gsOSVerInfo.dwMinorVersion == 0 || gsOSVerInfo.dwMinorVersion == 1))
#define IS_WINNT2KXP()		(gsOSVerInfo.dwPlatformId == VER_PLATFORM_WIN32_NT && (gsOSVerInfo.dwMajorVersion <= 4 \
							|| (gsOSVerInfo.dwMajorVersion == 5 && (gsOSVerInfo.dwMinorVersion == 0 \
							|| gsOSVerInfo.dwMinorVersion == 1))))
#define IS_WINNT()			(gsOSVerInfo.dwPlatformId == VER_PLATFORM_WIN32_NT && gsOSVerInfo.dwMajorVersion <= 4)
#define IS_WINNT4()			(gsOSVerInfo.dwPlatformId == VER_PLATFORM_WIN32_NT && gsOSVerInfo.dwMajorVersion == 4)
#define IS_WIN9X()			(gsOSVerInfo.dwPlatformId == VER_PLATFORM_WIN32_WINDOWS)
#define IS_WIN95()			(gsOSVerInfo.dwPlatformId == VER_PLATFORM_WIN32_WINDOWS && gsOSVerInfo.dwMajorVersion == 4 \
							&& gsOSVerInfo.dwMinorVersion == 0)
#define IS_WIN98()			(gsOSVerInfo.dwPlatformId == VER_PLATFORM_WIN32_WINDOWS && gsOSVerInfo.dwMajorVersion == 4 \
							&& gsOSVerInfo.dwMinorVersion == 10)
#define IS_WINME()			(gsOSVerInfo.dwPlatformId == VER_PLATFORM_WIN32_WINDOWS && gsOSVerInfo.dwMajorVersion == 4 \
							&& gsOSVerInfo.dwMinorVersion == 90)

#define IS_FOX8ORHIGHER() (gnFoxVersion >= 800)
#define IS_FOX9ORHIGHER() (gnFoxVersion >= 900)

#define VFP2C_VFP_MAX_ARRAY_ROWS		65000
#define VFP2C_VFP_MAX_PROPERTY_NAME		253
#define VFP2C_VFP_MAX_COLUMN_NAME		128
#define VFP2C_VFP_MAX_CURSOR_NAME		128
#define VFP2C_VFP_MAX_CHARCOLUMN		254
#define VFP2C_VFP_MAX_COLUMNS			255
// max fieldname = max cursorname + "." + max columnname
#define VFP2C_VFP_MAX_FIELDNAME			(VFP2C_VFP_MAX_CURSOR_NAME + 1 + VFP2C_VFP_MAX_COLUMN_NAME)

// misc VFP related helper/conversion functions
int _stdcall Dimension(char *pArrayName, unsigned long nRows, unsigned long nDims);
int _stdcall DimensionEx(char *pArrayName, Locator *lArrayLoc, unsigned long nRows, unsigned long nDims);
int _stdcall ASubscripts(Locator *pLoc, int *nRows, int *nDims);
int _stdcall CreateFoxVar(char *pName, Locator *pLoc, int nScope);
int _stdcall FindFoxVar(char *pName, Locator *pLoc);
int _stdcall FindFoxField(char *pName, Locator *pLoc, int nWorkarea);
int _stdcall FindFoxFieldEx(int nFieldNo, Locator *pLoc, int nWorkarea);
int _stdcall FindFoxFieldC(char *pName, Locator *pLoc, char *pCursor);
int _stdcall FindFoxVarOrField(char *pName, Locator *pLoc);
int _stdcall FindFoxVarOrFieldEx(char *pName, Locator *pLoc);
int _stdcall StoreEx(Locator *pLoc, Value *pValue);
int _stdcall AllocMemo(Locator *pLoc, int nSize, long *nLoc);
int _stdcall GetMemoContent(Value *pValue, char *pData);
int _stdcall GetMemoContentN(Value *pValue, char *pData, int nLen, int nOffset);
int _stdcall GetMemoContentEx(Locator *pLoc, char **pData, int *nErrorNo);
int _stdcall ReplaceMemo(Locator *pLoc, char *pData, int nLen);
int _stdcall ReplaceMemoEx(Locator *pLoc, char *pData, int nLen, FCHAN hFile);
int _stdcall AppendMemo(char *pData, int nLen, FCHAN hFile, long *nLoc);
int _stdcall MemoChan(int nWorkarea, FCHAN *nChan);
int _stdcall DBAppendRecords(int nWorkArea, unsigned int nRecords);
int _stdcall EmptyObject(Value *vObject);
int _stdcall Zap(char *pCursor);

void _stdcall FileTimeToDateTime(LPFILETIME pFileTime, Value *pDateTime);
void _stdcall DateTimeToFileTime(Value *pDateTime, LPFILETIME pFileTime);
BOOL _stdcall FileTimeToDateTimeEx(LPFILETIME pFileTime, Value *pDateTime, BOOL bToLocal);
BOOL _stdcall DateTimeToFileTimeEx(Value *pDateTime, LPFILETIME pFileTime, BOOL bToUTC);
BOOL _stdcall SystemTimeToDateTime(LPSYSTEMTIME pSysTime, Value *pDateTime, BOOL bToLocal);
void _stdcall SystemTimeToDateTimeEx(LPSYSTEMTIME pSysTime, Value *pDateTime);
BOOL _stdcall DateTimeToSystemTime(Value *pDateTime, LPSYSTEMTIME pSysTime, BOOL bToLocal);
void _stdcall DateTimeToSystemTimeEx(Value *pDateTime, LPSYSTEMTIME pSysTime);
void _stdcall DateTimeToLocalDateTime(Value *pDateTime);
void _stdcall LocalDateTimeToDateTime(Value *pDateTime);

BOOL _stdcall FileTimeToDateLiteral(LPFILETIME pFileTime, char *pBuffer, BOOL bToLocal);
BOOL _stdcall SystemTimeToDateLiteral(LPSYSTEMTIME pSysTime, char *pBuffer, BOOL bToLocal);

long _stdcall CalcJulianDay(WORD Year, WORD Month, WORD Day);
void _stdcall GetGregorianDate(long JulianDay, LPWORD Year, LPWORD Month, LPWORD Day);

BOOL _stdcall AnsiToUnicodePtr(char *pString, DWORD nStrLen, LPWSTR *pUnicodePtr, int *nErrorNo);
BOOL _stdcall AnsiToUnicodeBuf(char *pString, DWORD nStrLen, LPWSTR pUnicodeBuf, DWORD nBufferLen);
BOOL _stdcall UnicodeToAnsiBuf(LPWSTR pWString, DWORD nStrLen, char *pBuffer, DWORD nBufferLen, int *nConverted);

// misc C utility functions
unsigned short _stdcall CharPosN(const char *pString, const char pSearched, unsigned short nMaxPos);
unsigned int _stdcall strnlen(const char *s, unsigned long count);
unsigned int _stdcall strdblnlen(const char *s, unsigned long count);
unsigned int _stdcall strdblcount(const char *pString, unsigned long nMaxLen);
unsigned int _stdcall wstrnlen(const wchar_t *pString, unsigned int nMaxLen);
unsigned int _stdcall strcpyex(char *pBuffer, const char *pSource);
unsigned int _stdcall strncpyex(char *pBuffer, const char *pSource, unsigned int nMaxLen);
unsigned int _stdcall DoubleToUInt(double nValue);
int _stdcall DoubleToInt(double nValue);
unsigned __int64 _stdcall DoubleToUInt64(double nValue);
__int64 _stdcall DoubleToInt64(double nValue);
unsigned int _cdecl sprintfex(char *lpBuffer, const char *lpFormat, ...);
static char* _stdcall cvt(double arg, int ndigits, int *decpt, int *sign, char *buf, int eflag);
char* _stdcall strend(char *pString);
int _stdcall skip_atoi(const char **s);

// number to string conversion functions for parameter marshaling
char* _stdcall IntToStr(char *pString, int nNumber);
char* _stdcall IntToHex(char *pString, int nNumber);
char* _stdcall UIntToStr(char *pString, unsigned int nNumber);
char* _stdcall UIntToHex(char *pString, unsigned int nNumber);
char* _stdcall Int64ToStr(char *pString, __int64 nNumber);
char* _stdcall UInt64ToStr(char *pString, unsigned __int64 nNumber);
char* _stdcall BoolToStr(char *pString, int nBool);
char* _stdcall FloatToStr(char *pString, float nValue, int nPrecision);
char* _stdcall DoubleToStr(char *pString, double nValue, int nPrecision);

// number conversin functions for arithmetic & struct marshaling
void _stdcall Int64ToString(char *pString, __int64 nNumber);
__int64 _stdcall StringToInt64(char *pString);
void _stdcall UInt64ToString(char *pString, unsigned __int64 nNumber);
unsigned __int64 _stdcall StringToUInt64(char *pString);

// misc VFP like string functions
unsigned int _stdcall GetWordCount(char *pString, const char pSeperator);
unsigned int _stdcall GetWordNumN(char *pBuffer, char *pString, const char pSeperator, unsigned int nToken, unsigned int nMaxLen);
void _stdcall Alltrim(char *pString);
char * _stdcall AtEx(char *pString, char pSearch, int nOccurence);
char * _stdcall ReplicateEx(char *pBuffer, char pExpr, int nCount);

// misc string parsing functions
void _stdcall skip_ws(char **pString);
BOOL _stdcall match_identifier(char **pString, char *pBuffer, int nMaxLen);
BOOL _stdcall match_dotted_identifier(char **pString, char *pBuffer, int nMaxLen);
BOOL _stdcall match_quoted_identifier(char **pString, char *pBuffer, int nMaxLen);
BOOL _stdcall match_quoted_identifier_ex(char **pString, char *pBuffer, int nMaxLen);
BOOL _stdcall match_str(char **pString, char *pSearch);
BOOL _stdcall match_istr(char **pString, char *pSearch);
BOOL _stdcall match_chr(char **pString, char pChar);
BOOL _stdcall match_one_chr(char **pString, char *pChars, char *pFound);
BOOL _stdcall match_int(char **pString, int *nInt);
BOOL _stdcall match_short(char **pString, short *nShort);

char* _stdcall str_append(char *pBuffer, char *pString);
int _stdcall str_charcount(char *pString, char pChar);

#ifdef __cplusplus
}
#endif

#endif // _VFP2CUTIL_H__

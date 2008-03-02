#include <windows.h>
#include "pro_ext.h"
#include <string.h>
#include <ctype.h>
#include <direct.h>
#include <errno.h>
#include <stdio.h>
#include <winbase.h>	//has copyfile
#include "resource.h"
#ifndef NOPROFILE
	//#include <mprof.h>
#endif
//#undef FAR
//#undef HWND
#include "cstringz.hpp"

#ifndef BOOL 
	#define BOOL int
#endif
#ifndef UINT                                                                    
	#define UINT unsigned int
#endif
#define MAXLINECHARS 2048
#define MAXSTMTCHARS 4096
#define MAXTOKENCHARS 4096
#define MAXPATH 255	//max length of path plus filename

#define eqs(a,b) (!strcmp(a,b))
#define eqsn(a,b,n) (!strncmp(a,b,n))
#define isalpha_(p) (IsCharAlpha(p) || p=='_')
#define isalnum_(p) (IsCharAlphaNumeric(p) || p=='_')
#define SHOW(a,b) {_PutStr(a);_PutStr(b);}
#define MAX(a,b) (a>b? a:b)
#define MIN(a,b) (a<b? a:b)
typedef char PATHSTR[MAXPATH+1];

// BreakString1 is white space, BreakString2 delineates words
//#define PASS1BK    " ,\t\n\r"
//#define BKSTR1     " !@#$*()%{}+-^:;,<>?/=[]\t\n\r"
//#define CAPBKSTR   " !@#$*()%{}+-^:;,<>?/=\t\n\r"
//#define BKSTR2     " .!@#$*()%{}+-^:;,<>?'/=[]\t\"\n\r"
//#define UDF_BREAK  " .!@#$*()%{}+-^:;,<>?'/=&[]\t\"\n\r"
#define LEFTQUOTECHARS "\"'["
//#define TABPLUSSPACE " \t"     // space and a tab char
#if MAC_OS
	#define PATH_SEP_CHR     ':'
	#define PATH_SEP_CHR_ALT '\\'
#else
	#define PATH_SEP_CHR     '\\'
	#define PATH_SEP_CHR_ALT ':'
#endif



//Function Prototypes
void _PutLong(const long num);
unsigned str2bin(char *strg);
void Initialize(void);
void UnInitialize(void);
void DoError(const int ErrNum);
UINT PlayNice(void);
BOOL SeekToken(void);
char *ToUpper(char *p);
char *ToLower(char *p);
char *ToTrim(char *p);
char *ToLTrim(char *p);
char *ToDelete(char *instrg, const unsigned num);
char *strcatchr(char *outstr , const char chr);
char *ToRemoveQuotes(char *buff);
char *ParmToStr(const ParamBlk *ParmBlk,const int pnum,char *target);
void PutFPVar(char *FPVar,void *source,const char type);
int GetFPExpr(char *FPVar,void *target,const char type);
void FoxDocVer(ParamBlk *p);
void _cdecl	Error(int nErrNo, ...);
void _cdecl	_UserErrorf(char *control, ...);
BOOL _cdecl _Executef(char *control, ...);
void _cdecl _PutStrf(char *control, ...);
void _cdecl	StatMsg(char *control, ...);
char * GetString(int stringno);


//Filename utils
char *AddBS    (const char *const filname, char *target);
char *ForceExt (const char *filname, const char *ext,char *target);
char *JustFName(const char *filname, char *target);
char *JustStem (const char *filname, char *target);
char *JustExt  (const char *filname, char *target);
char *JustPath (const char *filname, char *target);
char *JustDrive(const char *filname, char *target);


// Globals


extern short Pass1; //0 for pass1, 1 for pass2
extern char MainInPath[MAXPATH];		//Path to input, including trailing backslash
extern char OutPath[MAXPATH];			//Path to output, including trailing backslash
extern char CurFile[];
extern char OutFile[];
extern long LineNo;
extern long SnipLineNo;		//line no in snippet
extern char ThisLine[];
extern int  ThisLineLen;
extern char ThisStmt[];
extern int  ThisStmtLen;
extern char ThisToken[];
extern char ThatToken[];
extern char UpperToken[];
extern char ThisTokenCode[];
extern short ThisTokenLen;
extern char CurProcName[];
extern char CurClassName[];
extern char *NextTokenPtr;
extern char *ReadBuf;
extern char ActionChars[]; 
extern char StopTokenChars[]; 
extern char WhiteSpaceChars[]; 
extern int DebugFlags;
extern FCHAN FPCurFile,FPOutFile;
extern int CurIndentLvl;
extern int PIndent;
extern char Version[];
extern BOOL DoAllKeyWords;
extern long TotalLines;

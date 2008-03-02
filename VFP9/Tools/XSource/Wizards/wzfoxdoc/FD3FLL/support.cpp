#include "fd3.h"
MHANDLE HReadBuf;
char *ReadBuf;

int DebugFlags;
FCHAN FPCurFile,FPOutFile;
Value TokenVal,TokenCodeVal;

short Pass1;
char MainInPath[MAXPATH];		//Path to input, including trailing backslash
char OutPath[MAXPATH];			//Path to output, including trailing backslash
char CurFile[MAXPATH];		//file currently being examined
char OutFile[MAXPATH];		//main output file name
char ThisLine[MAXLINECHARS];	//holds the current physical line
int ThisLineLen;
long LineNo;
long SnipLineNo;
char ThisStmt[MAXSTMTCHARS];	//holds the current FP statement (can span multiple lines)
int ThisStmtLen;
char ThisToken[MAXTOKENCHARS];	// as found in user's PRG
short ThisTokenLen;
char ThatToken[MAXTOKENCHARS];	// as found in DBF
char UpperToken[MAXTOKENCHARS];	// as found in either, UPPERed
char ThisTokenCode[10];			//when valid, will be same as this and that
char CurProcName[MAXTOKENCHARS];	//name of proc that we're in currently
char CurClassName[MAXTOKENCHARS];	//name of DEFINE CLASS we're in
char *NextTokenPtr;		//pts to next token
int CurIndentLvl;
char WhiteSpaceChars[]=" \r\n\t";
char StopTokenChars[]=" \r\n\t!@#$%^&*()-=+/*[]";
//Action diagram symbols:
extern BOOL nXrefKeywords;
extern BOOL fBeautifyMode;

/*
// These words are used in determining indentation levels and figuring
// out whether control structures are in balance.
char balancewords[] = " BEGIN DO IF FOR REPEAT TEXT SCAN CASE OTHERWISE ELSE \
 ELSEIF END ENDIF ENDDO ENDCASE ENDTEXT UNTIL NEXT ENDFOR ENDSCAN PRINTJOB \
 ENDPRINTJOB PROCEDURE FUNCTION STATIC RETURN WHILE ";

// These words are used to determine how to construct action diagrams
char actionwords[] = " DO IF CASE FOR REPEAT SCAN TEXT BEGIN OTHERWISE \
 ELSE ELSEIF QUIT CANCEL END ENDIF ENDDO ENDCASE ENDTEXT UNTIL \
 NEXT ENDFOR RETURN LOOP EXIT BREAK ENDSCAN ROLLBACK PRINTJOB ENDPRINTJOB \
 PROCEDURE FUNCTION STATIC DEACTIVATE WHILE ";

// These words begin interesting commands that pass1 processes.  Pass1 also
// looks for lines that contain a left parenthesis.
char pass1words[] = " SET DO USE INDEX REPORT SAVE RESTORE CHAIN SWITCH CLOSE \
 DELETE COPY CREATE TEXT PROCEDURE FUNCTION LABEL SELECT EXTERNAL APPEND \
 CALL LOAD DIMENSION DECLARE ERASE TYPE SORT PARAMETERS PUBLIC PRIVATE \
 #DEFINE #INCLUDE INSERT STATIC ON ";

// These are the SET commands were are interested in in Pass1.
char setwordstring[] = "INDEX PROCEDURE UDF FORMAT KEY ALTERNATE RESOURCE \
 HELP PRINTER LIBRARY DEFAULT PATH";

// These are the ON commands were are interested in in Pass1.
char onwords[] = "ERROR ESCAPE KEY PAD PAGE READERROR SELECTION";

// These words have multiple possible expansions, so don't expand or compress
// them
char dontcompresswords[] = " CENT COMM COMP DATA DELI ERRO EXTE FIEL FILE FORM GETE \
 HEAD HELP LAST LINE MACR MEMO MENU MESS NEXT NOCL NODE NOMO NOSH PRIN \
 PROC RAND READ RELA REST REPL SELE TEXT TIME TITL TRAN USER _TAL";

// These words begin commands with significance for xref usage flags.
char usagewords[] = " RELEASE MENU STORE REPLACE WAIT PRIVATE PUBLIC \
 USE INPUT ACCEPT DECLARE DIMENSION PROCEDURE FUNCTION READ \
 PARAMETERS ";

// These words mark the end of a control structure.
char endctrlstrucwords[] = " END ENDDO ENDIF ENDCASE NEXT ENDFOR ENDTEXT ENDSCAN";

*/



void Initialize(void) {
	if ((HReadBuf=_AllocHand(MAXLINECHARS)) == 0) _Error(182);
	_HLock(HReadBuf);
	ReadBuf=(char *)_HandToPtr(HReadBuf);
}

void UnInitialize(void) {
	_HUnLock(HReadBuf);
	_FreeHand(HReadBuf);
}

void _PutLong(const long num) {
	Value val;
	val.ev_type='I';
	val.ev_long=num;
	val.ev_width=10;
	_PutValue(&val);
}

#include <stdio.h>

void _cdecl	_UserErrorf(char *control, ...) {
   va_list args;
   char  buff[300];

   va_start(args, control);     			/* get variable arg pointer 	*/
   vsprintf(buff,control,args);       	/* format with variable args 	*/
   va_end(args);                			/* finish the arglist 			*/
	_FClose(FPCurFile);
	if (!Pass1) {
		_FClose(FPOutFile);
	}

	PutFPVar("TotalLines",&TotalLines,'I');
   _UserError(buff);
}

void _cdecl Error(int nErrNo, ...) {
	va_list		vaArgPtr;
	char		szMsg[160];
	Value Result;
	va_start(vaArgPtr, nErrNo);
	vsprintf(szMsg, GetString(nErrNo), vaArgPtr);
	va_end(vaArgPtr);
	_FClose(FPCurFile);
	if (!Pass1) {
		_FClose(FPOutFile);
	}
	PutFPVar("TotalLines",&TotalLines,'I');
	_Execute("this.lAbort=.t.");
	_Evaluate(&Result,"IIF(oEngine.mdev,1,0)");
	if (!Result.ev_long) {
		_UserError(szMsg);
	} else {
		_Executef("suspend");
	}
}

char stringbuf[100]; //global string buffer

char * GetString(int stringno) {
	if (LoadString((HINSTANCE)_GetAPIHandle(),stringno, stringbuf, sizeof(stringbuf)) == 0) {
		_Error(98);
	}
	return stringbuf;
}



void _cdecl	StatMsg(char *control, ...) {
   va_list args;
   char  buff[300];

	if (fBeautifyMode)
		return;

   va_start(args, control);     			/* get variable arg pointer 	*/
   vsprintf(buff,control,args);       	/* format with variable args 	*/
   va_end(args);                			/* finish the arglist 			*/
   if (DebugFlags & 1)  {
   	 _PutStrf("\n%s",buff);
   } else {
//		_Executef("wait window nowait '%s'",buff);
		if (!fBeautifyMode)
			_Executef("this.ThermRef.Update(this.iPctComplete,'%s')",buff);
   }
}


// --------------------------------------------------------------------------
BOOL _cdecl _Executef(char *control, ...) {
//
// printf control shell around _Execute function.
//
// --------------------------------------------------------------------------
   va_list args;
   char  buff[300];
   BOOL ret;

   va_start(args, control);     			/* get variable arg pointer 	*/
   vsprintf(buff,control,args);       	/* format with variable args 	*/
   va_end(args);                			/* finish the arglist 			*/
	ret = _Execute(buff);
	if (ret) {
		char buff2[400];
		sprintf(buff2,"%s Error # %d",buff,ret);
		throw(buff2);
	}
   return ret;
}

void _cdecl _PutStrf(char *control, ...) {
   va_list args;
   char  buff[300];

   va_start(args, control);     			/* get variable arg pointer 	*/
   vsprintf(buff,control,args);       	/* format with variable args 	*/
   va_end(args);                			/* finish the arglist 			*/
   _PutStr(buff);
}



void MemTest(void) {
#define NC 100
	MHANDLE mh[NC];
	int i,max;

	for (i=0 ; i<NC ; i++) {
		if ((mh[i]=_AllocHand(10000)) ==0 ) {
			_PutStr("anope");
			_PutLong(i);
			break;
		}
		if (i%100==0) {_PutLong(i);		_PutStr("\n");}

	}
	max=i;
	for (i=0 ; i<max ; i++) {
		_FreeHand(mh[i]);
	}
	_Execute("?sys(1016");
}

//--------------------------------------------------------------------------
UINT PlayNice(void) {
//
// Yield control to other processes if necessary.  This function makes
// FoxDoc share timeslices congenially with other Windows apps. 
//
// This is also how FoxDoc detects that the escape key has been pressed.
//
// Author:  Walter J. Kennamer
// History: Initially written March 30, 1993
//
//--------------------------------------------------------------------------

	MSG msg;
	UINT retcode = 0;
	while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
		TranslateMessage(&msg);
		if (msg.message == WM_CHAR && msg.wParam == VK_ESCAPE) retcode = VK_ESCAPE;
		DispatchMessage(&msg);
	}
	return retcode;
}

//put the value in source into FPVar. FPVar must be a FP var that already exists
void PutFPVar(char *FPVar,void * source,const char type) {
	NTI nti;
	Locator loc;
	Value val;
	if ((nti=_NameTableIndex(FPVar))==-1) {_UserErrorf("can't find %s",FPVar);}
	_FindVar(nti,-1,&loc);
	val.ev_type=type;
	switch (type) {
	case 'C':
		val.ev_handle=_AllocHand(strlen((char *)source));
		val.ev_length=strlen((char *)source);
		_HLock(val.ev_handle);
		_MemMove(_HandToPtr(val.ev_handle),(char *)source,val.ev_length);
		_HUnLock(val.ev_handle);
		break;
	case 'I':
		val.ev_long=*(int *)source;
		break;
	}
	_Store(&loc,&val);
	if (type == 'C') {
		_FreeHand(val.ev_handle);
	}
}

int GetFPExpr(char *expr,void *target,const char type) {
	Value val;
	if (_Evaluate(&val,expr)) {
		_UserErrorf("GetFPExpr %s",expr);
	}
	switch (val.ev_type) {
	case 'C':
		_HLock(val.ev_handle);
		_MemMove(target,_HandToPtr(val.ev_handle),val.ev_length);
		_HUnLock(val.ev_handle);
		*((char *)target+val.ev_length)='\0';
		_FreeHand(val.ev_handle);
		ToTrim((char *)target);
		break;
	case 'I':
		*(long *)target=(long) val.ev_long;
		return val.ev_long;
		break;
	case 'N':
		*(long *)target=(long)val.ev_real;
		break;
//		_PutStr("\nGetFP ");_PutLong(val.ev_long);_PutStr("  ");_PutChr(val.ev_type);
	}
	return 0;
}


BOOL SeekToken(void) {
	char *sym;
	Value val;
	BOOL RetVal;
	MHANDLE mh;
//	if (*(UpperToken+1)<'M') return TRUE;	//timing test
//	return FALSE;
	val.ev_length=ThisTokenLen+1;
	val.ev_handle=mh=_AllocHand(val.ev_length);
	_HLock(mh);
	_MemMove((sym=(char *)_HandToPtr(mh)),UpperToken,ThisTokenLen);
	sym[ThisTokenLen]=' ';
	_HUnLock(mh);

	val.ev_type='C';
	RetVal=(BOOL)_DBSeek(&val);	//DBSeek() automatically null-terminates

	if (RetVal < 0)
		_Error(RetVal);
	else if (RetVal == 0) {	//not found... see if it was an abbreviation
		if (ThisTokenLen>=4) {
			_SetHandSize(mh,ThisTokenLen);
			val.ev_length=ThisTokenLen;
			RetVal=(BOOL)_DBSeek(&val);
		}
	}

	if (RetVal){
		GetFPExpr("Token",ThatToken,'C');
		ToUpper(strcpy(UpperToken,ThatToken));
		GetFPExpr("Code",ThisTokenCode,'C');
	} else {
		ThisTokenCode[0]='\0';
	}
	_FreeHand(mh);
	return nXrefKeywords ? FALSE : RetVal;
}


void FoxDocVer(ParamBlk *p) {
	Value val;
	char *ptr;
	if (p->pCount>0) {
		val=p->p[0].val;
	}
	val.ev_type='C';
	val.ev_handle=_AllocHand(val.ev_length=strlen(Version));
	_HLock(val.ev_handle);
	_MemMove(ptr=(char *)_HandToPtr(val.ev_handle),Version,val.ev_length);
	_HUnLock(val.ev_handle);
	_RetVal(&val);
}



/*
ToDo: Prgs with no PROC statement. Where to Jump?
With/endwith

PROC foo(parm1,parm2)		done

CREATE VIEW  ... AS SELECT

Action diagrams

//#include <foxpro.h>		done

include all keywords in xref!  done



MACROS:
*# document  ACTIONCHars " -|+++"
*# document ActionIndentLength 3 (min 2) defa 8
*# document TreeIndentLength 3 (min 2) defa 8
*# document XREF on/off/suspend
*# document EXPANDKEYWORDS on/off/suspend
*# document XREFKEYWORDS on/off/thisfile
*# document ArrayBrackets ON/Off

*/

/*
#DEFINE words should be user config upper case
 4. FP doesn't have a way of outputing the intermediate code with the defined
values plugged in. Most other languages have this so I again imagine the FP3
will also. In this case it isn't a problem but when you get radical with the
use of the defines it can be a bit difficult to figure out what the compiler
did with you code during preprocessing.

Make UDFs same case as Definition

extra indent under DO CASE
if preceded by "m." user defined symbol even if is keyword

m.comp=4   --> m.COMPACT=4


REPL()--> REPLICATE()  REPLACE
TRANS()--> TRANSFORM().   TRANSACT()

Sample 2.0 SCX:D:\D\GWYN\DAILYFEE.SCX
Sample 2.5 SCX	J:\FOX26\SAMPLE\SCREENS\FAMILY.SCX

Don't pass2 "&&" comments

Should code in textmerge be touched? no. Check behavior of textmerged continued lines.

Should trailing whitespace be trimmed from *every* line, including Text, \\, etc.

Automatically put RETURN and/or ENDPROC ?

indent comments too?

Resolve 'L' for Library, Labels


What should be put in the symbol table for a Method name:   Proc mybtn.click

FoxDoc uses default templates to generate printed documentation. These
templates are embedded into the FoxDoc.app file.  In order to modify the
format of these templates you need to use the Original template files. These
files are included in FDRPT.EXE file which is available in FoxForum Library
3(FP Win-Platform). Download the file and run it to extract the Template
Files.  You may want to look up Article # Q102083 in the Microsoft Knowledge
Basse(MSKB). This article contains information about how to modify FoxDoc
Templates.  To access MSKB type "GO MSKB" at the Compuserve System Prompt.

Feel free to post if you have any further questions or concerns.

SET POINT TO "&mdecpoint"



I'm beginning to think that actual code documentation isn't what's needed, but
I'm interested in variable, procedure and function cross-referencing, program
tree diagramming etc., and the ability to include/exclude certain stuff from
the process (e.g. don't tell me that MENUHIT() is called from all 37 menu bars
thank you <g>).  I think that FoxDoc (and SNAP! before it) are too
detail-oriented - we need something to give us "big picture" information, and
details only when needed, and to do so in a manner consistent with the types
of development tools we're using.

One thing that I'd like to see in addition to the TREE is a dependency
relationship.  In this you would have, say, boxes represeting each module
(only once on the document). Then there would be lines drawn from one box to
the other, showing what calls what.




To brow a 2.x pjx:
brow last fiel nam=padr(name,20),type,out=padr(outfile,20),home=padr(homedir,15),mainprog

For a 3.0 SCX:
brow fiel baseclass=padr(baseclass,15),class=padr(class,15),objname=padr(objname,15),parent=padr(parent,15),prop=padr(properties,15),meth=padr(methods,15),methods,properties




*/





/* 
Possible values for FLAG in ref:

 C Class Name
 B Base Class
 P Property of an Object
 O Object
 M Method definition
 D Defined PROC or FUNC (not method)
 F Function call: myproc() or DO myproc or myobj.click
 V Variable definition(PARA,PRIV,PUBL,DIME)
 R Variable Reference
 N Name of file, like a DBF
 K Keyword

Values for CODE in FDKeyWrd.DBF:

  I Indent
  U Undent
  R Reset indentation to 0 (or 1 if InDefineClass)
  F Proc or function
  D While or Case: DO clause
  O Object (Spinner,CommandButton)
  P Property (Scalemode,DecimalPoints)
  M Method (Init,KeyPress)
  C Clause  Used only as a Clause: can't start a statement
*/

/*
	pass1
		FDXREF order symbol    upper(symbol)+flag
		Files order  IsPjx ? none : (none, index tag on done for rushmore)

		FDKeyWrd order 1
	pass2
		FDXref order symbol  Upper(symbol)+flag
			AGAIN ALIAS xreffile  filename
			AGAIN ALIAS xrefproc  procname
		files order none
		xref2
*/

#include "fd3.h"
#include <assert.h>
#include <stdlib.h>

char Version[]=".05";
BOOL IsTazSCXVCX=FALSE;	//Multiple methods per snippet!
BOOL IsTazVCX=FALSE;
char Parent[MAXTOKENCHARS];
char ObjName[MAXTOKENCHARS];
char Class[MAXTOKENCHARS];
char BaseClass[MAXTOKENCHARS];
long TotalLines;
#define MAXRECURDEPTH 128
char ActionIndentStr[MAXRECURDEPTH]="";
char ActionIndentArray[MAXRECURDEPTH];
//char ActionChars[] = " Ä³ÚÀÃÍºÉÈ^vÍ³ÕÔÆÄºÖÓ<Í     ";
char ActionChars[] = " Ä³ÚÀÃÍºÉÈ^vÍ³ÕÔÆÄºÖÓ<Í     ";  //only first 6 used
int nActionIndentLength = 8;
char UDFChars[]="([";

int nDoCaseExtraIndent=1;	//# of indentations to do After a DO CASE. Usually 1 or 2
int KeyWordCaseMode=0;  //1 All caps, 2 All small 3 mixed as in fdkeywrd 4 nochange
int UserCaseMode=0;		//1 All caps, 2 All small 3 mixed as in fdxref   4 nochange
int OutputMode=0;		//&& 1= overwrite, 2= single new dir,3=new dir tree

int PIndent=0; 	// if positive, # of spaces per indent lev. 0 = no change, <0 = Tabs


BOOL LookupInOutput=1;		//for dynamic searches in input or output
BOOL SingleFile=FALSE;		//suck in referenced files
BOOL	nFileHeadings=0;
BOOL	nProcHeadings=1;
BOOL	nClassHeadings=0;
BOOL	nMethodHeadings=1;
BOOL CanBeUDF=0;		//CREATE TABLE mytable (name c(10))    mytable is not a UDF

BOOL IndentComments;	// only "*" type comments
BOOL IndentControl;		// Autoindent or leave indent scheme alone
BOOL IndentProc;		// Extra indent under PROCEDURE/FUNCTION?
BOOL IndentContinuation;	//continuation lines indented twice?
BOOL DoXref=1;		// optionally turn on/off addusersymbol
BOOL DoXrefSusp=0;	// SUSPEND xref for current file
BOOL ExpandKeywords=0;	//4 letters or expanded in pass 2.
BOOL ExpandKeywordsSusp=0;
BOOL nXrefKeywords=0;	//add keywords to symbol table
BOOL nXrefKeywordsSusp=0;


// Beautify Options structure--must match structure in _EDITOR.H
typedef struct _BEAUTIFY_OPTIONS
{
	int nUserCaseMode;
	int nKeyWordCaseMode;
	int nIndentSpaces;
	int nTabOrSpace;
	int fExpandKeywords;
	int fIndentComments;
	int fIndentContinuation;
	int fIndentProc;
	int fIndentDoCaseExtra;
} BEAUTIFYSTRUCT;

BOOL fBeautifyMode = 0;	// Are we running in Beautify mode?

//*reports
int	nRep_Source_Code=0;
int nRep_Action_Diag=0;

/*
#include <stdio.h>
typedef int  (*myintchartype) (char *, char *);
typedef void (*myvoidtype) (void);
typedef int  (*myintvoidtype) (void);
int func1(char *, char *);
void func2(void);
void main(void)
{
   myintvoidtype ptr;
   ptr = (myintvoidtype) func1;
   ((myintchartype) ptr)("one", "two");
   ptr = (myintvoidtype) func2;
   ((myvoidtype) ptr)();
}
int func1(char *a, char *b)
{
   return printf("func1 took two parameters: %s and %s\n", a, b);
*/

char *nullp(char *s) {return s;}

char * (*UpLoUser)(char *s);
char * (*UpLoKeyWord)(char *s);

char * UpLoUserMix(char *s) {
	Value Val;
	char Temp[MAXTOKENCHARS];//can't use UpperToken, cuz it might be myproc.method
	strcpy(Temp,s);
	ToUpper(Temp);
	PutFPVar("symbol",Temp,'C');
//		_Executef("symbol=padr(symbol,len(fdxref.symbol)");
//		_Executef("wait wind 'symbol='+m.symbol");
	_Evaluate(&Val,"seek(m.symbol+' ','fdxref','symbol')");
	if (Val.ev_length) {
		_Executef("symbol=trim(fdxref.symbol)");
		GetFPExpr("m.symbol",s,'C');
	}
	return s;
}

char *UpLoKeyWordUnchanged(char *s) {
	return ThisToken;
}

char *ToLowerKwd(char *s) {
	if (!ExpandKeywords) {
		s[strlen(ThisToken)]='\0';
	}
	return ToLower(s);
}

char *ToUpperKwd(char *s) {
	if (!ExpandKeywords) {
		s[strlen(ThisToken)]='\0';
	}
	return ToUpper(s);
}

char *UpLoKeyWordTable(char *s) {
	if (*s=='.') 
		return s;
	if (!ExpandKeywords) {
		s[strlen(ThisToken)]='\0';
	}
	return s;
}

int occurrences(char *p,char c) {
	register int cnt=0;
	for ( ; *p != '\0' ; p++) {
		if (*p == c) cnt++;
	}
	return cnt;
}


// return TRUE if szToken is the next token in szString.
BOOL NextTokenInString(char *szToken,char *szString) {
	while (!isalpha(*szString))
		szString++;
	return !strnicmp(szToken,szString,strlen(szToken));
}

/*
1	Can't create outfile
2	Insuff mem
3	Can't open file
*/
/*
int FileOpen(char *file,int mode) {
	Curfile=_FOpen(file,mode);
}
*/

void CurPos(ParamBlk *ParmBlk) {
	char Mode[2];	//'S' for Set, 'G' for Get
	EDENV EdEnv;
	EDPOS EdPos;
	HWND hwnd;
	WHANDLE wh = _WOnTop();
	ParmToStr(ParmBlk,0,Mode);
	if (*Mode=='S') {
		GetFPExpr("m.mwinname",&wh,'I');
		GetFPExpr("m.mwinpos",&EdPos,'I');
//		if ((wh=_EdOpenFile(CurFile,FO_READWRITE))<=0) _UserError("open file");
		hwnd=_WhToHwnd(wh);
		_WSelect(wh);
		_EdSetPos(wh,EdPos);
		_EdScrollToPos(wh,EdPos,TRUE);
	} else {
		_EdGetEnv(wh,&EdEnv);
		EdPos=_EdGetPos(wh);
//		PutFPVar("mwinname",EdEnv.filename,'C');

		PutFPVar("mwinname",&wh,'I');
		PutFPVar("mwinpos",&EdPos,'I');
	}
}

void GotoRec(ParamBlk *ParmBlk) {
	WHANDLE wh;
	int i,j,chr;
	long Adjust;
	char temp[MAXTOKENCHARS+2];
	EDPOS EdPos;
	_Executef("m.filename=TRIM(filename)");
	_Executef("m.symbol=TRIM(symbol)");
	_Executef("m.lineno=int(IIF(SnipLineNo>0,SnipLineNo,lineno))");
	_Executef("m.adjust=int(adjust)");
	GetFPExpr("m.Filename",CurFile,'C');
	GetFPExpr("m.symbol",temp,'C');
	GetFPExpr("m.Lineno",&LineNo,'I');
	GetFPExpr("m.Adjust",&Adjust,'I');
//	_Executef("wait wind 'lineno='+str(m.lineno,5)");
	wh=_WOnTop();
//	if ((wh=_EdOpenFile(CurFile,FO_READWRITE))<=0) _UserErrorf("err opening file %s",CurFile);
//		StatMsg(" ");StatMsg(CurFile);StatMsg("  ");_PutLong(LineNo);
	if (LineNo==0 || LineNo==Adjust) {//  PRG without init PROC
		EdPos=1;
		_EdSetPos(wh,EdPos);
	} else {
		EdPos=_EdGetLinePos(wh,LineNo-1);
		_EdSetPos(wh,EdPos);

#define MAXLOOP 100000
		for (i=0 ; i< MAXLOOP ; i++) {
			for (j=0 ; (unsigned int) j<strlen(temp) ; j++) {
				if ((chr=toupper(_EdGetChar(wh,EdPos+i+j))) != 
						toupper(temp[j])) {
					if (chr=='\n') {
						j=-1;
					}
					break;
				}
				if (j==0 && i>0 && isalnum_(_EdGetChar(wh,EdPos+i-1))) 
					break; //not part of a word
			}
			if (j==-1) {
				i=0;
				break;
			}
			if ((unsigned)j==strlen(temp)) 
				break;
		}
		if (i == MAXLOOP) {
			Value vv;
			vv.ev_type='L';
			vv.ev_long=0;
			_RetVal(&vv);
		}
		_EdSetPos(wh,EdPos);
		EdPos+=i;
		_EdSelect(wh,EdPos,EdPos+strlen(temp));
	}
	_EdScrollToPos(wh,EdPos,TRUE);  //true means center
}

#define LOOKPARM 15 // #of chars surrounding cursorpos to look

//get string under cursor
void Examine(ParamBlk *ParmBlk) {
	WHANDLE wh = _WOnTop();
	EDENV env;
	Point Pt;
	char temp[MAXTOKENCHARS+2];
	char *Startp,*Endp;
	EDPOS EdPos=_EdGetPos(wh);
	_EdGetEnv(wh,&env);
	_MousePos(&Pt);
	_GlobalToLocal(&Pt,wh);
	_EdGetStr(wh,MAX(EdPos-LOOKPARM,0),MIN(EdPos+LOOKPARM,env.length),temp);
	Startp=Endp=temp+LOOKPARM;
	if (!isalpha_(*Startp)) {
		if (isalpha_(Startp[1])) 
			Startp++;
		else {
			if (isalnum_(Startp[-1])) 
				Startp--;
		}
	}
	for ( ; Startp>=temp && isalnum_(*Startp) ; Startp--) 
		; //look backwards
	Startp++;
	for ( ; Endp<temp+2*LOOKPARM && isalnum_(*Endp) ; Endp++) 
		;
	*Endp='\0';
	_MemMove(temp,Startp,Endp-Startp+1);
//		StatMsg("Symbol=");StatMsg(temp);
	PutFPVar("symbol",temp,'C');
}



//	_RetInt(_mkdir(dir.pstring()),10);


BOOL IsPJX;
BOOL ThisIsContinued;	//current line has a ';' at the end
BOOL LastWasContinued;	//Last line had a ';'
BOOL LastWasComment;	//last line was a * or had a '&&' comment
BOOL InText;			//within Text or EndText
int InDefineClass;		//within a class def (Not VCX). Pass2, it's 0,1,2 for none,classname,baseclass
int InProperties;		//within a VCX or SCX properties
int InMethods;			//within a VCX or SCX methods
char * (*IsDeclareDLL)(char *s);		//can't change upper/lower for user symbols on this statement. Only care on pass 2
										//will be either NULL or the old UpLoUser for temp storage
char InQuote='\0'; //contains the actual char used in quote ",' or ]. Can span continuation lines
char OutputLine[1024],chr;
char FileType[1];		//'P' for program, 'S' for screen, Library, ...
char *StrPtr=ThisLine;	//ptr to current char
char *LastStrPtr;		// to determine if last is '.' for func call
int LookAhead=0;	//cnts how many lines we need to look ahead to get to next token
					//because there could be many continuation lines

BOOL IsSnippet=FALSE;	//indicates input source from file or memo
BOOL SnippetIsExpr=FALSE;	//indicates if the snip is a proc or an expr (2.5)
long MemoSize;			//
long MemoPlace;	//FSeek
long BytesRead;

void  FixDBCHeader(char * filename)
{
	FCHAN	fh;
	char	buffer;

	buffer = 7;			// what we need to put in file
	fh = _FOpen(filename, FO_WRITEONLY);
	if (fh == -1)
		_Error(5);		// access denied
	_FSeek(fh, (long)28, 0);	// go to byte 28
	if (_FWrite(fh, &buffer, 1) != 1)
		_Error(5);
	_FClose(fh);

}

int GetNextLine(void) {
	char buf[4];
	if (IsSnippet) {
		_FSeek(FPCurFile,MemoPlace+BytesRead,0);
		if (SnippetIsExpr && Pass1) {
			ThisLineLen=_FGets(FPCurFile,ThisLine+1,MAXLINECHARS)+1;
			ThisLine[0]='=';	//will force parser to make it an expr
		} else {
			ThisLineLen=_FGets(FPCurFile,ThisLine,MAXLINECHARS);
		}
		//have to find if CR/LF or just CR
		_FSeek(FPCurFile,MemoPlace+BytesRead+ThisLineLen,0);
		_FRead(FPCurFile,buf,2);
		if (buf[1]=='\n')	{
			BytesRead++;
		}

		BytesRead+=(ThisLineLen+1);
	} else {
		ThisLineLen=_FGets(FPCurFile,ThisLine,MAXLINECHARS);
	}
	if (ThisLineLen==0) {
		*ThisLine='\0';
	} else {
		while (ThisLineLen>0 && strchr(WhiteSpaceChars,ThisLine[ThisLineLen-1])) { //TRIM trailing white space (in case of ';' at eol
			ThisLine[ThisLineLen-1]='\0';
			ThisLineLen--;
		}
	}
	TotalLines++;
	LineNo++;
	if (IsSnippet) 
		SnipLineNo++;
	StrPtr=ThisLine;
	if (!InText || Pass1) {
		while (strchr(WhiteSpaceChars,*StrPtr) && *StrPtr) 
			StrPtr++;	//skip over init whitespace
	}
	NextTokenPtr="\0";
	LastWasContinued=ThisIsContinued; //from prev line
	ThisIsContinued=ThisLine[ThisLineLen-1]==';';
	if (Pass1) {// look for textmerge
		char *p=StrPtr;
		if (*p=='\\') {
			BOOL InLit=FALSE;
			ThisIsContinued=FALSE;// textmerge lines can't be continued
			while (*p) {
				switch(*p) {//the '=' will make itlook like a statement
				case '\\':
					*p='=';
					break;
				case '<':
					if (p[1]=='<') {
						InLit=TRUE;
						*p=p[1]='=';
					}
					break;
				case '>':
					if (p[1]=='>') {
						InLit=FALSE;
						*p=p[1]='=';
					}
					break;
				default:
					if (!InLit) 
						*p='=';
				}
				p++;
			}
//			StatMsg("\\\\:");
//			StatMsg(ThisLine);
		}
	} 
	return ThisLineLen;
}

/*BOOL IsStack;
char StackedToken[MAXTOKENCHARS];

void StackToken(void) {
	strcpy(StackedToken,ThisToken);
	IsStack=TRUE;
}*/

char LastChar() {
	char *p=StrPtr-1;
	while (strchr(WhiteSpaceChars,*p)) 
		*p--;
	return *p;
}

/*return char * next char

if it encounters a ';' line continuation char, it must 
read the next line in and return
the token. Also sets NextTokenPtr (only used in pass 1) to point to the next valid token (not ';') or NULL
Thus, must be called recursively
In pass1, will never return the single ";" that marks line continuation


Quoted strings are not needed in pass 1, and pass 2 handles them manually
*/

int GetNextToken(void) {
	char *ptr=ThisToken+(InQuote? strlen(ThisToken) : 0);//only from recursive call
	LookAhead=0;
	if (!StrPtr) {
//		_UserError("report this to calvin");
		return FALSE;
	}
	LastStrPtr=StrPtr;
	if (!InQuote) {
		if (Pass1 && *NextTokenPtr) {
			StrPtr=NextTokenPtr;
		} else {
			for ( ; *StrPtr && strchr(WhiteSpaceChars,*StrPtr) ; StrPtr++)  {	//skip over whitespace
				if (IsDBCSLeadByte(*StrPtr)) 
					StrPtr++;
			}
		}
	}
	if (*StrPtr=='\0') 
		return FALSE;
	if (!InQuote && (isalpha_(*StrPtr) || IsDBCSLeadByte(*StrPtr))) { //normal alphanum token
		while (*StrPtr && (isalnum_(*StrPtr) || IsDBCSLeadByte(*StrPtr))) {
			if (IsDBCSLeadByte(*StrPtr)) {
				*ptr++=*StrPtr++;
			}
			*ptr++=*StrPtr++;
		}
	} else { //it's not a word token, so must be non-alpha char
		if (InQuote) {
			while (*StrPtr && *StrPtr!=InQuote && !(*StrPtr==';' && StrPtr[1]=='\0')) {
				if (IsDBCSLeadByte(*StrPtr)) {
					*ptr++=*StrPtr++;
				}
				*ptr++=*StrPtr++;
			}
			if (*StrPtr==InQuote || !*StrPtr) {//close quote or user didn't match quotes
				*ptr++=InQuote;//force close quote
				InQuote='\0';
				if (*StrPtr) 
					StrPtr++;
			} else {//must be continued quote line
				GetNextLine();
				*ptr='\0';
				return GetNextToken();	//recur
			}
		} else {
			if (strchr(LEFTQUOTECHARS,*StrPtr) &&         //if it's a quote char, send the whole thing as a single token
				!(*StrPtr=='[' && isalnum_(LastChar()))) { //watch for subscripts
				InQuote=*StrPtr=='['?']':*StrPtr;
				*ptr++=*StrPtr++;	//add the opening quote
				*ptr='\0';
				return GetNextToken();	//recur

			}
			if (Pass1 && *StrPtr==';' && StrPtr[1]=='\0') {//continuation char. read next line. Trailing whitespace trimmed
				GetNextLine();
				*ptr='\0';
				return GetNextToken();	//recur
			}
		}
		//must be plain old non alpha char
		*ptr++=*StrPtr++;
	}
	*ptr++='\0'; //terminate the token we just parsed
	ThisTokenLen=strlen(ThisToken);
	ToUpper(strcpy(UpperToken,ThisToken));
	if (!Pass1) return TRUE;
	//now let's peek at the next char to see if '('
	while (TRUE) {
		for (ptr=StrPtr ; *ptr && strchr(WhiteSpaceChars,*ptr) ; ptr++) { //skip whitespace
			if (IsDBCSLeadByte(*ptr)) 
				ptr ++;
		}
//		if (*ptr) {StatMsg("p=");_PutChr(*ptr);}
		if (*ptr==';' && *(ptr+1)=='\0') {
			LookAhead++;
			GetNextLine();
		} else {
			break;
		}
	}
	NextTokenPtr=(*ptr? ptr : "\0");
	return TRUE;	
}


BOOL EatTheMDot() {
	if (*UpperToken=='M' && *(UpperToken+1)=='\0' && *NextTokenPtr=='.') {
		GetNextToken();//eat the .
		GetNextToken();// get the var name
		return TRUE;
	}
	return FALSE;
}

void AddFile(char *File,char *FileType,char *Done,char* Flags) {
	if (fBeautifyMode)
		return;

	if (IsPJX && *FileType!='D') 
		return;
	PutFPVar("file",File,'C');
	PutFPVar("filetype",FileType,'C');	//P, M, or S
	PutFPVar("done",Done,'C');
	PutFPVar("flags",Flags,'C');
//	_Executef("INSERT INTO files FROM memvar");
	_Executef("DO FileIns");	//must save and restor recno("files");
}

void AddUserSymbol(int flag) {
	int ThisLineNo=LineNo-LookAhead;
	char temp[2]="A";
	if (!(isalpha_(*ThisToken) || IsDBCSLeadByte(*ThisToken)) || !DoXref) 
		return;
	if (*UpperToken=='M' && UpperToken[1]=='\0' && *NextTokenPtr=='.') {//should be eaten already
		EatTheMDot();
//		_UserErrorf("adduser special......%s",ThisLine);
	}
//	if (UpperToken[1]=='\0') return;	//don't add single char vars
	PutFPVar("Symbol",UpLoUser(ThisToken),'C');
	PutFPVar("LineNo",&ThisLineNo,'I');
	if (IsSnippet) {
		ThisLineNo=SnipLineNo-LookAhead;
		PutFPVar("SnipLineNo",&ThisLineNo,'I');
	}
	*temp=flag;
	PutFPVar("Flag",temp,'C');
	_Executef("INSERT INTO fdxref FROM memvar");
//	_Executef("wait wind 'symbol='+m.symbol");
}

void AddIndentAction(int Lvl) {
	int i,j;
	char c=' ';
	ActionIndentArray[Lvl]=0;
	if (strchr(ThisTokenCode,'I')) {
		ActionIndentArray[Lvl]=(strchr(ThisTokenCode,'U')) ? 'B':'I';
	} else {
		if (strchr(ThisTokenCode,'U')) {
			ActionIndentArray[Lvl]='U';
		}
	}
	for (i=0 ; i<=Lvl ; i++) {	//one more indent level than lvl
		switch(ActionIndentArray[i]) {
		case 'I':
//			strcat(ActionIndentStr,i==Lvl?"ÚÄ": "³ ");
			if (i==Lvl) {
				strcatchr(ActionIndentStr,ActionChars[3]);
				strcatchr(ActionIndentStr,ActionChars[1]);
			} else {
				strcatchr(ActionIndentStr,ActionChars[2]);
				strcatchr(ActionIndentStr,ActionChars[0]);
			}
			break;
		case 'U':
//			strcat(ActionIndentStr,i==Lvl?"ÀÄ":"³ ");
			if (i==Lvl) {
				strcatchr(ActionIndentStr,ActionChars[4]);
				strcatchr(ActionIndentStr,ActionChars[1]);
			} else {
				strcatchr(ActionIndentStr,ActionChars[2]);
				strcatchr(ActionIndentStr,ActionChars[0]);
			}
			break;
		case 'B':
//			strcat(ActionIndentStr,i==Lvl?"ÃÄ": "³ ");
			if (i==Lvl) {
				strcatchr(ActionIndentStr,ActionChars[5]);
				strcatchr(ActionIndentStr,ActionChars[1]);
			} else {
				strcatchr(ActionIndentStr,ActionChars[2]);
				strcatchr(ActionIndentStr,ActionChars[0]);
			}
			break;
		default:
//			strcat(ActionIndentStr,"  ");
				strcatchr(ActionIndentStr,ActionChars[0]);
				strcatchr(ActionIndentStr,ActionChars[0]);
			break;
		}
		c=ActionIndentStr[strlen(ActionIndentStr)-1];
		for (j=2 ; j<nActionIndentLength ; j++) {
			strcatchr(ActionIndentStr,c);
		}
	}
}


void AddIndent(int Lvl) {
	int i,j;
	if ( PIndent && IndentControl && (!IsSnippet || !SnippetIsExpr)){
		for (i=0 ; i<Lvl ; i++) {
			if (PIndent<0) {	//User indent parm 0 for tab
				strcat(OutputLine,"\t");
			} else {
				for (j=0 ; j<PIndent ; j++) 
					strcat(OutputLine," ");
			}
		}
	} else {
		//preserve original indentation
		char *p=ThisLine;
		while ( (i=*p++) ==' ' || i=='\t') {
			strcatchr(OutputLine,i);
		}	
	}
	if (nRep_Action_Diag) {
		AddIndentAction(Lvl);
	}
}


void TryFileName(char *ext,char *type) {
//	parse a filename like SET PROC TO filename
	char temp[MAXPATH];
	if (*UpperToken=='(' || *UpperToken=='&' || *NextTokenPtr=='(') 
		return; //name expression or macro or func
	AddUserSymbol('N');
	strcpy(temp,UpperToken);  //start forming filename
	while (*NextTokenPtr==PATH_SEP_CHR || *NextTokenPtr==PATH_SEP_CHR_ALT) {// "/" or ":"
		GetNextToken();	//get the "\"
		strcat(temp,UpperToken);	//add it
		if (*NextTokenPtr==PATH_SEP_CHR || *NextTokenPtr==PATH_SEP_CHR_ALT) {
			continue; // f:\file    2 tokens in a row
		}
		if (GetNextToken()) { //get the next after the '\'
			strcat(temp,UpperToken);
		}
	}
	if (*StrPtr=='.') {//file extension 
		GetNextToken();	//get the "."
		strcatchr(temp,'.');
		if (isalnum_(*StrPtr) && GetNextToken()) { //get the rest after the '.'
			strcat(temp,UpperToken);
		}
		AddFile(temp,type,"","");
	} else {
		AddFile(ForceExt(temp,ext,temp),type,"","");
		if (*type=='I') {
			AddFile(ForceExt(temp,"CDX",temp),type,"","");
			AddFile(ForceExt(temp,"IDX",temp),type,"","");
		} else if (*type=='L') {
			AddFile(ForceExt(temp,"MLB",temp),type,"","");
			AddFile(ForceExt(temp,"PLB",temp),type,"","");
			AddFile(ForceExt(temp,"PRG",temp),"P","","");
		}
	}
}


int AddCommaList(char *ext,char *type) {
	BOOL WasComma=FALSE;
	while (1) {
		TryFileName(ext,type);
		if (*NextTokenPtr != ';' && *NextTokenPtr!=',') { //if there's a comma
//		if (*NextTokenPtr!=',') { //if there's a comma
			break;
		}
		if (*NextTokenPtr==',') 
			WasComma=TRUE;
		GetNextToken();	//skip over comma (and whitespace)
		if (!WasComma) {//must have been line continuation
			if (*UpperToken!=',') 
				break;	//not comma, so end of list
		}
		if (!GetNextToken()) 
			return 0;
	}
	return 1;
}

void SetCommand(char *LastToken) {
	/*char setwordstring[] = "INDEX PROCEDURE UDF FORMAT KEY ALTERNATE RESOURCE \
		 HELP PRINTER LIBRARY DEFAULT PATH";

	set proc to aproc
	set proc to (nameexpr) &macro && additive
	set proc to
	set proc to ("quotestr")
	set proc to &macro
	report form areport
	set index to aindex
	set libr to alibr
	set format to aformat*/
	strcpy(LastToken,UpperToken); //save 2nd word PROC, FORMAT, etc.
	if (!GetNextToken()) 
		return; //Get 3rd word. If none, return
	if (eqs(UpperToken,"TO")) { //3rd word isn't TO. Could be macro
		if (!GetNextToken()) 
			return; // SET FORMAT TO with no filename. OK
		if (eqs(LastToken,"PROCEDURE")) {	//SET PROC TO
			StatMsg(GetString(IDS_PROCEDURE));
			TryFileName("PRG","P");
		} else if (eqs(LastToken,"FORMAT")) {
			StatMsg(GetString(IDS_FORMAT));
			TryFileName("FMT","F");
		} else if (eqs(LastToken,"LIBRARY")) {
			StatMsg(GetString(IDS_LIBRARY));
			TryFileName("FLL","L");
		} else if (eqs(LastToken,"HELP")) {
			StatMsg(GetString(IDS_HELP));
			TryFileName("HLP","F");
		} else if (eqs(LastToken,"RESOURCE")) {
			StatMsg(GetString(IDS_RESOURCE));
			TryFileName("DBF","D");
		} else if (eqs(LastToken,"PRINTER")) {
			StatMsg(GetString(IDS_PRINTER));
			TryFileName("TXT","T");
		} else if (eqs(LastToken,"ALTERNATE")) {
			StatMsg(GetString(IDS_ALTERNATE));
			TryFileName("TXT","T");
		} else if (eqs(LastToken,"INDEX")) {
			StatMsg(GetString(IDS_INDEX));
			AddCommaList("NDX","I");
		} else if (eqs(LastToken,"CLASSLIB")) {
			StatMsg(GetString(IDS_CLASSLIBRARY));
			AddCommaList("VCX","I");
		} else {
			if (EatTheMDot()) {
				AddUserSymbol('R');
			} else {
				if (!SeekToken()) {
					AddUserSymbol('V');
				}
			}
		}
	}			//End of processing for SET commands
}

//optimization:
#define eqsf(str,ch,lit) (*(str)==ch && eqs((str)+1,lit))


void Outit(char *OutputLine) {
	_FPuts(FPOutFile,OutputLine);
	if (nRep_Source_Code) {
		_FPuts(nRep_Source_Code,OutputLine);
	}
	if (nRep_Action_Diag) {
		char *p=OutputLine;
		if (!*p) {
			*ThisTokenCode='\0';
			AddIndentAction(CurIndentLvl);
		}
		if (!InText) {
			_FWrite(nRep_Action_Diag,ActionIndentStr,strlen(ActionIndentStr));
			while (*p && strchr(" \t",*p)) 
				*p++;
		}
		_FPuts(nRep_Action_Diag,p);
	}
}



// called to process a physical line. 
// For Pass1, will not be a continuation line: GetNextToken returns tokens
// For Pass2, can be a continuation line
// can be called recursively if Pass1 and something like: ON ERROR DO myproc
void DoLine(void) {
	BOOL found,LastWasDo,LastWasDefine,IsSelect;
	int extra;
	static char flag[1]="";
	char *SaveStrPtr; //temp to hold beginning of token
	char chr;
	char LastToken[MAXTOKENCHARS];
	char temp[MAXTOKENCHARS];

	static int LastLine=0;
	if (LineNo<LastLine) {
//		StatMsg(ThisLine);
	}
	LastLine=LineNo;
	ActionIndentStr[0]='\0';
	OutputLine[0]='\0';
	IsSelect=FALSE;
//	if (!LastWasContinued) LastWasDo=FALSE;
	if (!GetNextToken()) 
		return;	//Get the first word in the line
	if (InText) {
		if (eqsf(UpperToken,'E',"NDTEXT")) {
			InText=FALSE;
			if (!Pass1) 
				strcat(strcat(OutputLine,UpperToken),StrPtr);
			return;
		}
		if (!Pass1) 
			strcat(OutputLine,ThisLine);
		return;
	}
	if (*ThisToken=='\\') { //textmerge
		if (!Pass1) {
			*ThisTokenCode='\0';
			strcat(OutputLine,ThisLine);// pass 2 ouputs verbatim
			ThisIsContinued=FALSE;
			return;
		}
		//pass 1: GetNextLine has already stripped line
		if (!GetNextToken()) 
			return;
	}
	if (*ThisToken=='*' || (eqs(ThisToken,"&") && *StrPtr=='&') || 
			eqsf(ThisToken,'N',"OTE") ||
			(LastWasContinued && LastWasComment)) {// it's a comment
		if (!Pass1) {
			if (*ThisToken=='*' && IndentComments) {
				*ThisTokenCode='\0';
				AddIndent(CurIndentLvl);
			}
			strcat(OutputLine,ToLTrim(ThisLine));	//add the entire line
		}
		LastWasComment=TRUE;	//comments can continue to next line
		return;	//done with this line
	}
	LastWasComment=FALSE;
	if (*ThisToken=='#') {	// foxpro directive
		if (!GetNextToken()) 
			return;	//Get the next word in the line (could be line continuation)
		_MemMove(ThisToken+1,ThisToken,ThisTokenLen+1);
		ThisToken[0]='#';
		ThisTokenLen++;
		strcpy(UpperToken,ThisToken);
		ToUpper(UpperToken);
//		StatMsg("## ");StatMsg(ThisToken);
	}

	found=SeekToken();	//See if 1st token in line is in table. fills ThisTokenCode if found
	if (found && Pass1 && nXrefKeywords) {
		AddUserSymbol('K');
	}
	if (Pass1) {//*******************************************************
		CanBeUDF=TRUE;
		*flag=InProperties?'P':'R';	//default value Property or Reference
		if (*ThisToken=='#') {	//directive
			if (eqs(UpperToken,"#DEFINE")) {
				*flag='V';
			} else if (eqs(UpperToken,"#INCLUDE")) {
				if (!GetNextToken()) 
					return;	//Get the next word in the line
//				StatMsg("Adding INCLUDE file %s",ThisToken);
				TryFileName("H","P");
			}
		}
		if (found && (!InDefineClass || *NextTokenPtr != '=')) { //first token in line and not an assignment stmt
// User might have SET=4 where SET is a user defined symbol
//  Assign ok in DEFINE CLASS. TOP=4
			if (eqsf(UpperToken,'T',"EXT")) {
				InText=TRUE;
				return;
			}
			if (InDefineClass && eqsf(UpperToken,'E',"NDDEFINE")) {
				InDefineClass=FALSE;
				return;
			}
			strcpy(LastToken,UpperToken);
			if (!GetNextToken()) 
				return;	//Get the next word in the line
			if (*UpperToken=='&' && *NextTokenPtr=='&') 
				return;
			found=SeekToken(); //properize it
			if (eqsf(LastToken,'U',"SE")) {//***********Case first token
				if (!eqs(UpperToken,"IN")) 
					TryFileName("DBF","D");
				if (!GetNextToken()) 
					return;	//Get the next word in the line
			} else if (eqsf(LastToken,'S',"ELECT")) {
				IsSelect=TRUE;
				if (!found) {//could have been SELECT DISTINCT
					EatTheMDot();
					AddUserSymbol(*flag);
				}
			} else if (InDefineClass && eqsf(LastToken,'A',"DD") && eqsf(UpperToken,'O',"BJECT")) {
				*flag='O';
			} else if (eqsf(LastToken,'P',"ROCEDURE") || eqsf(LastToken,'F',"UNCTION") || 
					eqsf(LastToken,'P',"ROTECTED") || eqsf(LastToken,'H',"IDDEN")) {
				if (LastToken[3]=='T' || LastToken[0] == 'H') { //PROTECTED or HIDDEN. Could be for PROC or for vars
					if (!eqs(UpperToken,"PROCEDURE") && !eqs(UpperToken,"FUNCTION")) {
						*flag='V';
						EatTheMDot();
						AddUserSymbol(*flag);
					} else {
						if (!GetNextToken()) 	//Get the next word in the line
							return;
					}
				}
				if (*flag != 'V') {//must be proc or func
					if (InDefineClass || IsTazSCXVCX) {// it's a method
						//concatenate to form meth name: cmd1.click
						if (IsTazSCXVCX) {
							strcat(strcat(strcpy(CurProcName,ObjName),"."),ThisToken);
							LineNo=0;
						} else {
							strcat(strcat(strcpy(CurProcName,CurClassName),"."),ThisToken);
						}
						*flag='M';
					} else {//just a normal proc
						strcpy(CurProcName,ThisToken);
						*flag='D';
					}
					PutFPVar("Procname",UpLoUser(CurProcName),'C');
					AddUserSymbol(*flag);
					*flag='V';	//for parms defined on same line

					if (!fBeautifyMode) {
						if (LineNo) {
							StatMsg(GetString(IDS_LINE_TOKEN),LineNo,UpperToken);
						} else {
							StatMsg("%s",UpperToken);
						}
					}
				}
			} else if (*LastToken=='P' && (eqsf(LastToken+1,'R',"IVATE") || 
					eqsf(LastToken+1,'U',"BLIC") || 
					eqsf(LastToken+1,'A',"RAMETERS")) || 
					eqsf(LastToken,'L',"PARAMETER") ||	//LPARAMETER
					eqsf(LastToken,'D',"IMENSION")) {
				if (!(eqsf(LastToken,'P',"RIVATE") && eqsf(UpperToken,'A',"LL"))) {
					*flag='V';
					EatTheMDot();
					AddUserSymbol(*flag);
				}
			} else if (eqsf(LastToken,'C',"REATE")) {
				CanBeUDF=FALSE;
			} else if (eqsf(LastToken,'S',"ET")) {
				SetCommand(LastToken);
			} else if (*LastToken=='O' && LastToken[1]=='N' && LastToken[2]==0) { // ON ERROR ESCAPE KEY PAD PAGE READERROR SELECTION
				if (eqsf(UpperToken,'E',"RROR") || eqsf(UpperToken,'E',"SCAPE")) { //ON ERROR
					_MemMove(ThisLine,StrPtr,strlen(StrPtr));
					ThisLine[strlen(StrPtr)]='\0';
					StrPtr=ThisLine;
					NextTokenPtr="\0";
					DoLine();		   //recur
				} else if (eqsf(UpperToken,'K',"EY")) { //ON KEY
					SaveStrPtr=StrPtr;
					if (!GetNextToken()) 
						return;
					if (eqsf(UpperToken,'L',"ABEL")) {
						//eat up key label name 
						while (*StrPtr && strchr(WhiteSpaceChars,*StrPtr)) 
							StrPtr++;
						while (*StrPtr && !strchr(WhiteSpaceChars,*StrPtr)) 
							StrPtr++;
					} else {
						StrPtr=SaveStrPtr;
					}
					_MemMove(ThisLine,StrPtr,strlen(StrPtr));
					ThisLine[strlen(StrPtr)]='\0';
					NextTokenPtr="\0";	//force new line processing
					DoLine();	//recur
				} else {
				}
			} else if (eqsf(LastToken,'D',"EFINE")) {
				if (eqsf(UpperToken,'C',"LASS") || eqsf(UpperToken,'S',"UBCLASS")) {
					InDefineClass=TRUE;
					if (!GetNextToken()) 
						return;
					strcpy(CurClassName,ThisToken);
					strcpy(CurProcName,UpLoUser(ThisToken));
					PutFPVar("Procname",CurProcName,'C');
					StatMsg("DEFINE CLASS %s",ThisToken);
					if (!GetNextToken()) 
						return; //get the "AS"
					if (!GetNextToken()) 
						return; //get the base class
					PutFPVar("Procname",UpLoUser(ThisToken),'C');
					strcpy(ThisToken,CurClassName);
					AddUserSymbol('C');	//Symbol is class name, Procname is base class
					PutFPVar("Procname",CurProcName,'C');	//restore Procname as the class name
				}
			} else if (*LastToken=='D' && LastToken[1]=='O' && LastToken[2]==0) { //"DO"
				if (!(eqs(UpperToken,"CASE") || eqs(UpperToken,"WHILE") || eqs(UpperToken,"FORM"))) {
					if (EatTheMDot()) {
						AddUserSymbol('R');
					} else {
						AddUserSymbol('F');
					}
				} else if (*UpperToken=='F') {//DO FORM
					if (!GetNextToken()) 
						return;
					TryFileName("SCX","s");
					*flag='O';
				}

			} else if (!IsPJX && eqsf(LastToken,'E',"XTERNAL")) {
				if (eqs(UpperToken,"SCREEN")) {
					*flag='S'; strcpy(temp,"SCX");
				} else if (eqs(UpperToken,"ARRAY")) {
				} else if (eqs(UpperToken,"LABEL")) {
					*flag='L'; strcpy(temp,"LBX");
				} else if (eqs(UpperToken,"LIBRARY")) {
				} else if (eqs(UpperToken,"MENU")) {
					*flag='M'; strcpy(temp,"MNX");
				} else if (eqs(UpperToken,"PROCEDURE")) {
					*flag='P'; strcpy(temp,"PRG");
				} else if (eqs(UpperToken,"REPORT")) {
					*flag='R'; strcpy(temp,"FRX");
				}
				if (!eqs(UpperToken,"ARRAY")) {
					StatMsg(GetString(IDS_EXTERNALS),UpperToken);
					if (!GetNextToken()) 
						return; //get the first external object
					StatMsg(ThisToken);
					while (1) {
						TryFileName(temp,flag);
						if (*NextTokenPtr!=',') 
							break;
						if (!GetNextToken()) 
							return; //get the ','
						if (!GetNextToken()) 
							return; //get the ','
					}
				}
			} else { //1st token is kwd, 2nd isn't special
				if (EatTheMDot()) {
					AddUserSymbol(*flag); //force addition to symbol table
				} else {
					if (!SeekToken())	{
						AddUserSymbol(*NextTokenPtr=='('?'F':*flag);
					}
				}
			}//********endcase first token
		} else { // !found. 1st token not a FP keyword
			if (EatTheMDot()) {//m.var=val
				AddUserSymbol(*flag);
			} else {
				//could have been TOP=4 within a class definition
				//gotta watch for "_CUROBJ=4"
				if (!(InDefineClass && found && *NextTokenPtr=='=')) {//don't add base properties
					AddUserSymbol(*flag);
/*				} else {
					if (found && Pass1 && nXrefKeywords) {
						AddUserSymbol('K');
					}*/
				}
			}
		}
		//now proc rest of line
		while (GetNextToken()) {
			if (*ThisToken=='&' && *NextTokenPtr=='&') 
					break;   //skip "&&" style comments
			if (isalpha_(*UpperToken)) {
				if (*UpperToken=='M' && EatTheMDot()) {//m.var
					AddUserSymbol(*flag);
				} else {
					if (!SeekToken()) {
						AddUserSymbol(*NextTokenPtr && strchr(UDFChars,*NextTokenPtr) && LastStrPtr[-1] != '.' && CanBeUDF ? 'F':*flag);
					} else {
						if (IsSelect && eqs(UpperToken,"FROM")) {
							GetNextToken();
							AddCommaList("DBF","D");
	//						IsSelect=FALSE;
						}
					}
				}
			}
		}
	} else { //pass 2**************************************************
		BOOL NeedsProcHeaders=FALSE;
		if (CurIndentLvl<0) 
				CurIndentLvl=0; //in case of user syntax errors
		if (!LastWasContinued) {
			if (eqs(UpperToken,"TEXT")) {
				InText=TRUE;
				strcat(strcat(OutputLine,UpLoKeyWord(UpperToken)),StrPtr);
				return;
			}
			if (eqs(UpperToken,"DEFINE")) {
				InDefineClass=TRUE;
				CurIndentLvl=0;
			}
			if (eqs(UpperToken,"ENDDEFINE")) {
				InDefineClass=FALSE;
				CurIndentLvl=0;
			}
			if (eqs(UpperToken,"PROTECTED") || eqs(UpperToken,"HIDDEN") || 
					strchr(ThisTokenCode,'F')) {	//FUNCTION or PROCEDURE definition
				if (!InDefineClass && !InMethods && nProcHeadings) 
					NeedsProcHeaders=TRUE;
				if (eqs(UpperToken,"PROTECTED") || eqs(UpperToken,"HIDDEN") || 
						strchr(ThisTokenCode,'R')) {
					CurIndentLvl = InDefineClass ? 1 : 0;	//Reset indent level
					if (!strchr(ThisTokenCode,'F'))	{//if it's a Prot/Hidden Prop, and not proc
						if (!NextTokenInString("PROC",StrPtr) && 
								!NextTokenInString("FUNC",StrPtr)) {
							*ThisTokenCode = 0;	//don't extra indent on next line
						}
					}
				}
			} else {
				CurIndentLvl-=occurrences(ThisTokenCode,'U');
				if (CurIndentLvl<0) 
					CurIndentLvl=0;
			}
			LastWasDo=eqs(UpperToken,"DO");
			LastWasDefine=eqs(UpperToken,"DEFINE"); //look for DEFINE CLASS (not #DEFINE)
			if (eqs(UpperToken,"DECLARE")) {	//check if Declare DLL
				if ( !strchr(StrPtr,'(') && !strchr(StrPtr,'[') ) {	//won't work if continuation line
					IsDeclareDLL = UpLoUser;
					UpLoUser = &nullp;	//do nothing if declare dll
				} else {
					IsDeclareDLL = (char*( *)(char *))NULL;
				}
			}
			if (LastWasDefine) {	//have to check if it's DEFINE CLASS
				char *ptr;
				ptr=StrPtr;
				while (strchr( WhiteSpaceChars,*ptr) ) 
					ptr++;
				if (!strnicmp(ptr,"class",4)) {
					strcatchr(ThisTokenCode,'I');	//force an indent
				}
			}

			if (fBeautifyMode && nDoCaseExtraIndent > 1 && eqs(UpperToken, "ENDCASE"))
				CurIndentLvl -= (nDoCaseExtraIndent - 1);

			AddIndent(CurIndentLvl);

			extra = occurrences(ThisTokenCode,'I');	// extra indentation levels
			if (fBeautifyMode && (eqs(UpperToken, "PROCEDURE") || eqs(UpperToken, "FUNCTION"))) {
				if (IndentProc && extra == 0) {
					extra = 1;
				}
				else if (!IndentProc)
					extra = 0;
			}
				
			CurIndentLvl+=extra;
			if (*UpperToken=='M' && UpperToken[1]=='\0' && *StrPtr=='.') {//first token is "m."
				StrPtr++;	//skip over "."
				if (!GetNextToken()) 
						return;
				strcat(strcat(OutputLine,UpLoUser("m.")),UpLoUser(ThisToken));	//don't expand "m.variable", like "m.REPL='a'"
			} else {
				strcat(OutputLine,found?UpLoKeyWord(ThatToken):UpLoUser(ThisToken));
			}
		} else {
			strcpy(ThisTokenCode,"");	//no indent codes
			AddIndent(IndentContinuation? CurIndentLvl+1:CurIndentLvl);
			if (!LastWasContinued) {	//the previous line ends in a ';'
				strcat(OutputLine,found ? UpLoKeyWord(ThatToken):UpLoUser(ThisToken));
			} else {
				if (*ThisToken == '"' || *ThisToken == '\'')  {
					strcat(OutputLine, ThisToken);
				} else {
					strcat(OutputLine,found ? UpLoKeyWord(ThisToken):UpLoUser(ThisToken));
				}
			}
		}
		//done with indent and first token of statement. Now proc rest of line
		while ((chr=*StrPtr)) {
			if (InQuote) {//Last line could have been a continued line without close quote
				strcatchr(OutputLine,chr);
				StrPtr++;
				if (chr==';' && *StrPtr=='\0') {//trailing whitespace removed
					Outit(OutputLine);	//output this line, start over
					*OutputLine='\0';
					GetNextLine();
					continue;//don't indent continued Quote lines
				}
				if (chr==InQuote) 
					InQuote='\0';//endquote
				continue;
			}
			if (chr=='&' && StrPtr[1]=='&') { // '&&' style comments
				strcat(OutputLine,StrPtr);
				return;
			}
			if (toupper(chr)=='M' && StrPtr[1]=='.') { //var starting with M.
				chr=(UserCaseMode ? (UserCaseMode==1? 'm':chr) : 'M');
				strcatchr(OutputLine,chr);
				strcatchr(OutputLine,'.');
				StrPtr+=2;
				if (!GetNextToken()) 
					return; //get next thingy
				strcat(OutputLine,UpLoUser(ThisToken));//don't expand token cuz "m."
				continue;
			}
			if (!isalpha_(chr) && !IsDBCSLeadByte(chr)) {//if not alpha, just add it to the output verbatim
				if (chr!='.' ) {//could be a logical, like .AND.
					strcatchr(OutputLine,chr);
					if (strchr(LEFTQUOTECHARS,chr)) 
						InQuote=chr=='['?']':chr;
				} else {
					strncpy(temp,StrPtr,5); //get next few chars for closer exam
					ToUpper(temp);
					if (eqsn(temp,"T.",2)) {
						strncat(ThisToken,StrPtr,2);
						StrPtr+=2;
					} else if (eqsn(temp,"F.",2)) {
						strncat(ThisToken,StrPtr,2);						
						StrPtr+=2;
					} else if (eqsn(temp,"AND.",4)) {
						strncat(ThisToken,StrPtr,4);
						StrPtr+=4;
					} else if (eqsn(temp,"OR.",3)) {
						strncat(ThisToken,StrPtr,3);
						StrPtr+=3;
					} else if (eqsn(temp,"NOT.",4)) {
						strncat(ThisToken,StrPtr,4);
						StrPtr+=4;
					} else { //not any special token with '.'
						*ThisToken='.';
						ThisToken[1]='\0';
					}
//					strcpy(UpperToken,ThisToken);
					UpLoKeyWord(ThisToken);
					strcat(OutputLine,ThisToken);
				}
				StrPtr++;
				// if we're at the end of a line and it's a properties assignment and the last char was an '=', add a ' ' to the end: see bug 6016
				if (!*StrPtr && InProperties && OutputLine[strlen(OutputLine)-1] == '=') {
					strcat(OutputLine," ");
				}
			} else { //must be alpha
				if (!GetNextToken()) 
					return;
				if (NeedsProcHeaders) {
					NeedsProcHeaders=FALSE;
					PutFPVar("symbol",UpperToken,'C');
					PutFPVar("filename",LookupInOutput && OutputMode!=1 ?OutFile:CurFile,'C');
					PutFPVar("lineno",&LineNo,'I');	//could be more than 1 proc w/ same name in file
					if (!IsSnippet) 	
						_Executef("do HeaderProc");
				}
				if (InDefineClass) {
					switch(InDefineClass) {
					case 1:
						PutFPVar("ClassName",UpLoUser(ThisToken),'C');
						InDefineClass++;
						break;
					case 2:
						if (eqs(UpperToken,"AS")) {
							InDefineClass++;
						}
						break;
					case 3: 
						if (!eqs(UpperToken,"AS")) {
							if (SeekToken()) {
								UpLoKeyWord(ThisToken);
							} else {
								UpLoUser(ThisToken);
							}
							PutFPVar("BaseClass",ThisToken,'C');
							if (nClassHeadings) 
								_Executef("Do HeaderClass");
						}
						InDefineClass++;
						break;
					}
				}
				if ((found =SeekToken()) || (nXrefKeywords && LastWasDo && strchr(ThisTokenCode,'D')) ) {
					if (LastWasDo && strchr(ThisTokenCode,'D')) {	//DO WHILE or DO CASE
						char *p,DO[4];
						int i,NewIndent;
						NewIndent= eqs(UpperToken,"CASE") ? nDoCaseExtraIndent: 1;
						ThisTokenCode[0]='\0';
						for (i=0 ; i<NewIndent ; i++) {
							strcatchr(ThisTokenCode,'I');
						}
						p=OutputLine;
						while (*p && !isalpha(*p)) 
							p++;
						DO[0]=*p++;
						DO[1]=*p++;
						DO[2]=' ';
						DO[3]='\0';
						*OutputLine='\0';
						*ActionIndentStr='\0';
						AddIndent(CurIndentLvl);
						strcat(OutputLine,DO);
						CurIndentLvl+= NewIndent;
						LastWasDo=FALSE;

					}
					if (LastWasDefine && 
							(eqs(UpperToken,"CLASS") || 
							eqs(UpperToken,"SUBCLASS"))) {
						ToLTrim(OutputLine);
						CurIndentLvl=1;
						InDefineClass=1;
						LastWasDefine=FALSE;
					}
					strcat(OutputLine,UpLoKeyWord(found ? ThatToken : ThisToken));	//pretty version
				} else {
					strcat(OutputLine,UpLoUser(ThisToken));
				}
				LastWasDo=FALSE;
			}
		}
	}
}

void DoMacro() {
	if (!strcmp(UpperToken,"DOCUMENT")) {
		GetNextToken();
		if (!strcmp(UpperToken,"ACTIONCHARS")) {
			while (*StrPtr && !strchr(LEFTQUOTECHARS,*StrPtr)) 
				StrPtr++;
			strncpy(ActionChars,StrPtr+1,6);
			ActionChars[7]='\0';
			PutFPVar("mtemp",ActionChars,'C');
			_Executef("this.cActionChars=mtemp");
		} else if (!strcmp(UpperToken,"XREF")) {
			GetNextToken();
			if (!strcmp(UpperToken,"ON")) {
				DoXref=1;
			} else if (!strcmp(UpperToken,"OFF")) {
				DoXref=0;
			} else if (!strcmp(UpperToken,"SUSPEND")) {
				DoXrefSusp=1;
				DoXref=0;
			}
		} else if (!strcmp(UpperToken,"EXPANDKEYWORDS")) {
			GetNextToken();
			if (!strcmp(UpperToken,"ON")) {
				ExpandKeywords=1;
			} else if (!strcmp(UpperToken,"OFF")) {
				ExpandKeywords=0;
			} else if (!strcmp(UpperToken,"THISFILE")) {
				ExpandKeywordsSusp=1;
				ExpandKeywords=1;
			}
		} else if (!strcmp(UpperToken,"XREFKEYWORDS")) {
			GetNextToken();
			if (!strcmp(UpperToken,"ON")) {
				nXrefKeywords=1;
			} else if (!strcmp(UpperToken,"OFF")) {
				nXrefKeywords=0;
			} else if (!strcmp(UpperToken,"THISFILE")) {
				nXrefKeywordsSusp=1;
				nXrefKeywords=1;
			}
		} else if (!strcmp(UpperToken,"ARRAYBRACKETS")) {
			GetNextToken();
			if (!strcmp(UpperToken,"ON")) {
				strcpy(UDFChars,"(");
			} else if (!strcmp(UpperToken,"OFF")) {
				strcpy(UDFChars,"([");
			}
		} else if (!strcmp(UpperToken,"ACTIONINDENTLENGTH")) {
			GetNextToken();
			int trylen;
			trylen=atoi(ThisToken);
			if (trylen >=2 && trylen <10) {
				nActionIndentLength=trylen;
			}
		} else if (!strcmp(UpperToken,"TREEINDENTLENGTH")) {
			GetNextToken();
			int trylen;
			trylen=atoi(ThisToken);
			if (trylen >=2 && trylen <10) {
				PutFPVar("temp",ThisToken,'C');
				_Executef("oEngine.nTreeIndentLength=VAL(temp)");
			}
		}
	}
}


void ProcCode() {
	if ((LineNo & 0x3f)==0) {
		if (PlayNice() == VK_ESCAPE) 
			Error(IDS_ABORT);
	}
	GetNextLine();
	if (LookupInOutput && *ThisLine=='*' && 
			strchr("!:#",ThisLine[1])) {//Prev foxdoc hdr
		//ignore previous foxdoc header
		if (ThisLine[1]=='#') {	//foxdoc macro
			if (!Pass1) 
				Outit(ThisLine);
			StrPtr+=2;
			GetNextToken();
			DoMacro();
		} else {
			LineNo--;
		}
		return;
	}
	if (!Pass1 && !fBeautifyMode) {
		if (!(LineNo%500)) {
			StatMsg(GetString(IDS_PASSLINE),2-Pass1,LineNo);
		}
	}
	DoLine();

	InQuote = 0;	// reset the InQuote flag

	if (!Pass1) {
		Outit(OutputLine);
		if (IsDeclareDLL && !ThisIsContinued) {
			UpLoUser = IsDeclareDLL;
		}
	}
}

//ProcessFile called for SPR, MPR, PRG

BOOL ProcessFile(char *InFileName,char *OutFile) {
	char thisbuf[300];
	if (Pass1) {
		char thisbuf[300];
		StatMsg(GetString(IDS_PASSSTR),2-Pass1,JustFName(InFileName,thisbuf));
	} else {
		if (OutputMode==1) {
			StatMsg(GetString(IDS_PASSSTR),2-Pass1,JustFName(InFileName,thisbuf));
		} else {
			StatMsg(GetString(IDS_PASSSTR),2-Pass1,JustFName(OutFile,thisbuf));
		}
	}
	PutFPVar("filename",LookupInOutput && OutputMode!=1 ? OutFile:InFileName,'C');
	PutFPVar("SnipLineNo","\0",'I');
	PutFPVar("SnipRecNo","\0",'I');
	PutFPVar("SnipFld","",'C');		
	if ((FPCurFile=_FOpen(InFileName,FO_READONLY)) == -1) {	//can't open file
//		_Error(101);
//		StatMsg("Can't open file");
		return 0;
	}
	if (!Pass1 ) {
		if ((FPOutFile=_FCreate(OutFile,FC_NORMAL)) == -1) {
			_Error(102);
		}	//can't create outfile
		PutFPVar("FPOutFile",&FPOutFile,'I');// send file handle
		PutFPVar("filename",OutputMode==1? CurFile:OutFile,'C');
		if (nFileHeadings) 
			_Executef("do HeaderFile");
	}
	_Executef("SELECT fdkeywrd"); //get to workarea of keywords
	LineNo=SnipLineNo=0;
	UpLoUser(JustStem(InFileName,CurProcName));
	strcpy(ThisToken,CurProcName);	  //init for PRG files with no PROC statement
	PutFPVar("Procname",CurProcName,'C');
	if (Pass1) 
		AddUserSymbol('D');	
	InQuote = '\0';
	CurIndentLvl=0;
	ThisIsContinued=FALSE;		//current line has a ';' at the end
	LastWasContinued=FALSE;		//Last line had a ';'
	LastWasComment=FALSE;		//last line was a * or had a '&&' comment
	NextTokenPtr="\0";
	InText=FALSE;				//within Text or EndText
	InDefineClass=FALSE;		//within a class def
	IsDeclareDLL=FALSE;
	while (!_FEOF(FPCurFile)) {
//break;    for fast processing!
		ProcCode();
	}
	_FClose(FPCurFile);
	if (!Pass1) {
		if (_FClose(FPOutFile)==-1) 
			_Error(105);
	}
	return 1;
}


int WorkArea;	//in which the SCX is used

int ProcessSnippet(char *MemoFld,BOOL IsExpression) {
	Locator loc;
	NTI nti;
	nti=_NameTableIndex(MemoFld);
	SnippetIsExpr=IsExpression;
	if (nti<1) 
		_Error(603); //illegal memo fld
	if (!_FindVar(nti,WorkArea,&loc)) {
		_Error(603); //"can't find memo fld %s",MemoFld);
	}
	// Test for an empty snippet.  Use a value like 3 bytes to 
	// weed out memos that might contain only a CR/FR or possibly 
	// a NULL byte.
	if ((MemoSize=_MemoSize(&loc)) <3) 
		return 0;

	_Executef("m.SnipRecNo=recno('snipfile')");
	PutFPVar("SnipFld",MemoFld,'C');


	BytesRead=0;
//	StatMsg("\t\t\t");	StatMsg(MemoFld);
	if ((FPCurFile=_MemoChan(-1)) == -1) {	//can't open file
		_Error(603);
//		StatMsg("Can't open memo");
		return 0;
	}
	if ((MemoPlace=_FindMemo(&loc)) < 0) 
		_Error(603);
	if (!Pass1 ) {
		Value val;
		if (_Evaluate(&val,"fcreate(fdtemp)") || val.ev_long==-1) {
			_Error(102);//"can't create temp file");
		}
		FPOutFile=val.ev_long;
		PutFPVar("FPOutFile",&FPOutFile,'I');// send file handle
	}
//	_Executef("?name");

	_Executef("SELECT fdkeywrd"); //get to workarea of keywords
	ToUpper(strcpy(CurProcName,MemoFld));
	if (!IsTazSCXVCX) 
		PutFPVar("Procname",CurProcName,'C');
	CurIndentLvl=0;
	InQuote = '\0';
	LineNo=SnipLineNo=0;
	ThisIsContinued=FALSE;		//current line has a ';' at the end
	LastWasContinued=FALSE;		//Last line had a ';'
	LastWasComment=FALSE;		//last line was a * or had a '&&' comment
	NextTokenPtr="\0";
	InText=FALSE;				//within Text or EndText
	InDefineClass=FALSE;		//within a class def
	IsDeclareDLL=FALSE;
	while (BytesRead<MemoSize) {
		ProcCode();
	}
	_Executef("select SnipFile");
	if (!Pass1) {
		if (_FClose(FPOutFile)==-1) 
			_Error(105);
//		_Executef("type (fdtemp)");

		_Executef("APPEND MEMO %s FROM (m.fdtemp) OVERWRITE",MemoFld);

		_Executef("erase (m.fdtemp)");
	}
	return 1;
}

BOOL IsExpr(char *MemoFldName) {
//checks the fields like "Validtype". if it's a 0, it's an expr, 1 = procedure
	Value val;
	_Evaluate(&val,MemoFldName);
	return val.ev_long==0? TRUE:FALSE;
}

void SCX30(void) {
	int m1=-1;
	int ClassRecCount=0;
	_Executef("set filt to !empty(objname)");
	_Executef("locate");
	if (CurFile[strlen(CurFile)-3]=='V') IsTazVCX=TRUE;	 //flag to DoLine()
	IsTazSCXVCX=TRUE;
	while (!(_DBStatus(-1) & DB_EOF)) {
		if (PlayNice() == VK_ESCAPE) 
			Error(IDS_ABORT);
		if (Pass1) {
			_Executef("SCATTER MEMVAR MEMO");
			if (IsTazVCX)	{//skip orphaned records
				if (ClassRecCount==0) {
					GetFPExpr("IIF(UPPER(ALLTRIM(m.reserved1))='CLASS',VAL(Reserved2),0)",&ClassRecCount,'I');
					if (!ClassRecCount) {
	//					_Executef("Wait window 'orphan'+str(recno())");
						_DBSkip(-1,1);
						continue;
					}
				}
				ClassRecCount--;	//legal record, so count it
			}
			_Executef("SnipRecNo=recno('snipfile')");
			PutFPVar("SnipFld","",'C');
			PutFPVar("SnipLineNo",&m1,'I');

			GetFPExpr("m.objname",ObjName,'C');
			GetFPExpr("m.parent",Parent,'C');
			GetFPExpr("m.Class",Class,'C');
			GetFPExpr("m.BaseClass",BaseClass,'C');
			PutFPVar("procname",ObjName,'C'); //set procname to UDC name
			if (IsTazVCX) {	//Symbol is class name, Procname is base class
				int dummy;
				PutFPVar("ProcName",Class,'C');
				strcpy(ThisToken,ObjName);		
				strcpy(UpperToken,ThisToken);
				ToUpper(UpperToken);
				AddUserSymbol('C');
				if (GetFPExpr("IIF(UPPER(ALLTRIM(m.BaseClass))=UPPER(ALLTRIM(m.class)),1,0)",&dummy,'I')) {
					strcpy(ThisToken,BaseClass);
					AddUserSymbol('B');
				}
				PutFPVar("ProcName",ObjName,'C');
			} else {	//it's a Taz SCX: Symbol is the objname, procname is the Class
				PutFPVar("ProcName",Class,'C');
				strcpy(ThisToken,ObjName);		strcpy(UpperToken,ThisToken);
				ToUpper(UpperToken);
				AddUserSymbol('C');
			}
		}
		InProperties=TRUE;
		ProcessSnippet("Properties",FALSE);
		InProperties=FALSE;
		InMethods=TRUE;
		ProcessSnippet("Methods",FALSE);
		InMethods=FALSE;
		_DBSkip(-1,1);
	}
	IsTazSCXVCX=FALSE;
	IsTazVCX=FALSE;
	InDefineClass=FALSE;
}

void SCX25(void) {
/*
	Setup		Setuptype	Setupcode
	Cleanup		proctype	proccode
	When		whentype	when
	Valid		validtype	valid
	Activate	activtype	activate
	Deactivate	deacttype	deactivate
	Show		Showtype	show

	message		messtype	message
	error		errortype	error
	comment

	When Valid Message Error Comment

*/
	while (!(_DBStatus(-1) & DB_EOF)) {
		if (PlayNice() == VK_ESCAPE) 
			Error(IDS_ABORT);
		ProcessSnippet("Name",TRUE);
		ProcessSnippet("expr",TRUE);
		ProcessSnippet("picture",TRUE);
		ProcessSnippet("Setupcode",FALSE);
		ProcessSnippet("proccode",FALSE);
		ProcessSnippet("when",IsExpr("whentype"));
		ProcessSnippet("valid",IsExpr("validtype"));
		ProcessSnippet("Activate",IsExpr("ActivType"));
		ProcessSnippet("Deactivate",IsExpr("Deacttype"));
		ProcessSnippet("Show",IsExpr("Showtype"));
		ProcessSnippet("Error",IsExpr("Errortype"));
		ProcessSnippet("Message",IsExpr("Messtype"));
		_Executef("select SnipFile");
		_DBSkip(-1,1);
	}
}



void SCX(void) {
	Value Result;
	_Evaluate(&Result,"IIF(TYPE('SnipFile.objname')!='U',1,0)");
	if (Result.ev_long) {// objname exists, so must be SCX 3.0
		SCX30();
		if (!Pass1) {
			_Executef("USE IN snipfile");
//			if (OutputMode==1) { //overwrite	// LP00QSA
				try {
					_Executef("compile form %s",CurFile);
				} catch (...) {
					int i=5;
					i++;		//just so we can set a breakpoint here
				}
				_Executef("set message to ''");	// hide compile errors
//			}
		}
	} else { //must be SCX 2.0 or 2.5
		_Evaluate(&Result,"IIF(TYPE('SnipFile.platform')!='U',1,0)");
		if (Result.ev_long) {// 'platform' exists, so must be SCX 2.5
			SCX25();
		} else {
			Error(IDS_ERROR_SCX,CurFile);
//			_UserError("FP 2.x and 3.0 SCX files only");
		}
	}
}

void MNX(void) {
	while (!(_DBStatus(-1) & DB_EOF)) {
		if (PlayNice() == VK_ESCAPE) 
			Error(IDS_ABORT);
		ProcessSnippet("Setup",FALSE);
		ProcessSnippet("procedure",FALSE);
		ProcessSnippet("command",FALSE);
		ProcessSnippet("cleanup",FALSE);
		_Executef("select SnipFile");
		_DBSkip(-1,1);
	}
}

void DBC(void) {
	_Executef("locate for objectname='StoredProceduresSource'");
	if (!(_DBStatus(-1) & DB_EOF)) {	//found some stored procs
		ProcessSnippet("Code",FALSE);
	}
	if (!Pass1) {
		_Executef("USE IN snipfile");
		if (OutputMode==1) {	//overwrite mode.
			_Executef("compile database %s",CurFile);
			_Executef("set message to ''");	// hide compile errors
		}
	}
}

void FRX(void) {
	while (!(_DBStatus(-1) & DB_EOF)) {
		if (PlayNice() == VK_ESCAPE) 
			Error(IDS_ABORT);
		ProcessSnippet("name",TRUE);
		ProcessSnippet("Expr",TRUE);
		ProcessSnippet("picture",TRUE);
		_Executef("select SnipFile");
		_DBSkip(-1,1);
	}
}


void MapCapOptions(void)
{
	switch(KeyWordCaseMode) {
	default:
	case 1:
		UpLoKeyWord=&ToUpperKwd;
		break;
	case 2:
		UpLoKeyWord=&ToLowerKwd;
		break;
	case 3:
		UpLoKeyWord=&UpLoKeyWordTable;  // as in kywrd table
		break;
	case 4:
		UpLoKeyWord=&UpLoKeyWordUnchanged;
		break;

	}
	switch(UserCaseMode) {
	case 1:
		UpLoUser=&ToUpper;
		break;
	case 2:
		UpLoUser=&ToLower;
		break;
	case 3:
	default:
		UpLoUser=&UpLoUserMix;
		break;
	case 4:
		UpLoUser=&nullp;
		break;
	}
}


void InitOptions(ParamBlk *ParmBlk) {
	ParmToStr(ParmBlk,0,CurFile);
	ParmToStr(ParmBlk,1,OutPath);
	if (ParmBlk->pCount == 4) {
		ParmToStr(ParmBlk,3,ThisToken);
		DebugFlags = str2bin(ThisToken); 
	}
	GetFPExpr("m.OutputMode",&OutputMode,'I');
//	AddBS(OutPath,OutPath);	//assume always has a '\'
	PutFPVar("mout",OutPath,'C');
	GetFPExpr("this.nLookupInOutput",&LookupInOutput,'I');
	GetFPExpr("this.nSingleFile",&SingleFile,'I');
	GetFPExpr("this.nVariableCase",&UserCaseMode,'I');
	GetFPExpr("this.nKeyWordCase",&KeyWordCaseMode,'I');
	GetFPExpr("this.nFileHeadings",&nFileHeadings,'I');
	GetFPExpr("this.nProcHeadings",&nProcHeadings,'I');
	GetFPExpr("this.nClassHeadings",&nClassHeadings,'I');
	GetFPExpr("this.nMethodHeadings",&nMethodHeadings,'I');
	GetFPExpr("this.nIndentation",&PIndent,'I');
	GetFPExpr("this.nExpandKeywords",&ExpandKeywords,'I');
	GetFPExpr("this.nXrefKeywords",&nXrefKeywords,'I');
	GetFPExpr("this.nIndentComments",&IndentComments,'I');
	GetFPExpr("this.nIndentControl",&IndentControl,'I');
	GetFPExpr("this.nIndentContinuation",&IndentContinuation,'I');
	GetFPExpr("this.nRep_Source_Code",&nRep_Source_Code,'I');
	GetFPExpr("this.nRep_Action_Diag",&nRep_Action_Diag,'I');
	GetFPExpr("this.cActionChars",ActionChars,'C');
	GetFPExpr("this.nDoCaseExtraIndent",&nDoCaseExtraIndent,'I');
	MapCapOptions();
}

void Beautify(ParamBlk *ParmBlk) {
	Value 	val;
	BOOL	fSuccess;
	BEAUTIFYSTRUCT	beautify;

	ParmToStr(ParmBlk,0,CurFile);
	ParmToStr(ParmBlk,1,OutFile);

	_HLock(ParmBlk->p[2].val.ev_handle);
	_MemMove(&beautify,_HandToPtr(ParmBlk->p[2].val.ev_handle),ParmBlk->p[2].val.ev_length);

	fBeautifyMode  = TRUE;

	// Set beautify options
	LookupInOutput = 0;
	SingleFile = 1;
	UserCaseMode = beautify.nUserCaseMode;
	KeyWordCaseMode = beautify.nKeyWordCaseMode;
	nFileHeadings = nProcHeadings = nClassHeadings = nMethodHeadings = 0;
	switch(beautify.nTabOrSpace) {
	case 1:
		PIndent = -1;	//tabs
		break;
	case 2:				//spaces
		PIndent = beautify.nIndentSpaces;
		break;
	case 3:
		PIndent = 0;	//no change
		break;
	}

	
	ExpandKeywords = beautify.fExpandKeywords;
	nXrefKeywords = 0;
	IndentComments = beautify.fIndentComments;
	IndentControl = 1;
	IndentContinuation = beautify.fIndentContinuation;
	IndentProc = beautify.fIndentProc;
	nRep_Source_Code = nRep_Action_Diag = 0;
	nDoCaseExtraIndent = (beautify.fIndentDoCaseExtra ? 2 : 1);

	MapCapOptions();

	Pass1 = (UserCaseMode == 3);	//only do pass1 if we need first-use-case user symbols

	fSuccess = ProcessFile(CurFile,OutFile);

	if (fSuccess && Pass1)
	{
		Pass1 = 0;
		fSuccess = ProcessFile(CurFile,OutFile);
	}

	val.ev_type='L';
	val.ev_long=fSuccess;

	_RetVal(&val);
}


void DoMakePath(char *inpath) {
	char *p,temp2[MAXPATH];
	if (!strchr(inpath,'\\')) {
		strcat(strcpy(OutFile,OutPath),inpath);
		return;
	}
	JustPath(inpath,temp2);//now temp2 has additional rel path
	strcpy(inpath,OutPath);
	while (p=strchr(temp2,'\\')) {
		*p='\0';
		strcat(inpath,temp2);
		if (!Pass1) _mkdir(inpath);
		strcatchr(inpath,'\\');
		strcpy(temp2,p+1);
	}
	strcpy(OutFile,inpath);
	if (OutFile[strlen(OutFile)-1] != '\\') {
		strcatchr(OutFile,'\\');
	}
	JustFName(CurFile,inpath);
	strcat(OutFile,inpath);
}




void fdDoIt(ParamBlk *ParmBlk) {
	PATHSTR temp;
	int iPass,MaxPass;
	Value Retval;

	MaxPass=2;
#ifndef NOPROFILE
//	char *meafile="hello.mea";
//	_FEnableMeas(meafile,opTimingSwap);	
#endif

#ifdef _DEBUG
	CStringz mystr,mystr2;
	mystr="alkjl";
	mystr.Upper();
//	mystr.Show();

	mystr2="test";
	mystr=mystr2+(CStringz) CurFile;
	mystr.Upper();
//	mystr.Show();
	mystr=mystr.Lower()+(CStringz)" lower"+(CStringz)"UpMixEd";
//	mystr.Show();
	mystr=mystr2;
//	if (mystr==mystr2) StatMsg("EQ");
#endif

	InitOptions(ParmBlk);
	ParmToStr(ParmBlk,2,temp);
	MaxPass=str2bin(temp)+1;
	JustPath(CurFile,MainInPath);	//store the main input path
/*
	if (!strcmp(MainInPath,OutPath)) {
		_Executef("wait window 'Output dir must be different'");
		_RetInt(0,10);
		return;
	}
*/
	if (eqs("PJX",JustExt(CurFile,temp))) {
		IsPJX=TRUE;

		// put the PJX files into a table, Currec is MainProg, in first rec
		JustFName(CurFile,temp);
		strcat(strcpy(OutFile,OutPath),temp);
		PutFPVar("mtemp",OutFile,'C');
//		_Executef("use (m.mfile) ALIAS foxdocPJX1 IN 0");
//		_Executef("select foxdocpjx1");
//		JustFName(CurFile,temp);
//		strcpy(OutFile,OutPath);
//		strcat(OutFile,CurFile);
//		_Executef("copy to %s",OutFile);
//		_Executef("do IsProj");

		_Evaluate(&Retval,"IsProj()");
		if (!Retval.ev_length) {
			_RetInt(0,10);
			return;
		}
		_Executef("SET FILTER TO filetype$'PSRLMmsxVKd'"); //PRG,SPR,MNX,scx,FRX,LBX
	} else {
		IsPJX=FALSE;
		JustExt(CurFile,temp);
		if (!(eqs(temp,"PRG") || eqs(temp,"MNX") || eqs(temp,"SCX"))) {
			_UserError(GetString(IDS_ILLEGAL_TOP));
		}
		if (*temp=='S') {//spr or scx
			if (temp[1]=='C') {
				*temp='s';	//lowercase
			}
		}
		temp[1]='\0';
		AddFile(CurFile,temp,"","");
		_Executef("SELECT files");
		_Executef("INDEX ON done TAG name");
		_Executef("set order to");
	}
	TotalLines=0;
	_Executef("TotalLines=0");
	for (iPass=1 ; iPass<=MaxPass ; iPass++) {
//		if (DebugFlags>0) 
		Pass1=iPass==1? 1:0;
//		StatMsg(iPass==1?"\nPass1\n":"\nPass2\n");
		if (!IsPJX) {
			_Executef(iPass==1?
				"SET FILTER TO done=' ' AND filetype$'PSRLMmsVKd'" :  //prg, spr from screen set, scx
				"SET FILTER TO done='Y'");
		}
		if (!Pass1) {
			_Executef("sele fdxref");
			//wait wind nowait 'indexing symbol table '+str(recc(),6)
			_Executef(GetString(IDS_INDEXING));
			_Executef("INDEX ON LEFT(filename,120) TAG file");	//tag must be less than 120 chars RED00KH3
			_Executef("INDEX ON procname TAG proc");
			_Executef("set order to symbol");
			_Executef("use dbf('fdxref') again in 0 alias xreffile order file");
			_Executef("use dbf('fdxref') again in 0 alias xrefproc order proc");
			_Executef("select files");
			_Executef("wait clear");
			_Executef("fdtemp=sys(2023)+'\\'+sys(3)+'.tmp'");	//temp file name for snippets
//			_Executef("acti wind trace");
		}
		_Executef("LOCATE");
//_Executef("goto 59");
		//loop thru all files
		while (!(_DBStatus(-1) & DB_EOF)) {
			if (DoXrefSusp) {
				DoXrefSusp=0;
				DoXref=1;
			}
			if (ExpandKeywordsSusp) {
				ExpandKeywordsSusp=0;
				ExpandKeywords=0;
			}
			if (nXrefKeywordsSusp) {
				nXrefKeywordsSusp=0;
				nXrefKeywords=0;
			}
			if (PlayNice() == VK_ESCAPE) 
				Error(IDS_ABORT);
			_Executef("SCATTER MEMVAR");
			GetFPExpr("m.file",temp,'C');
/*			if (eqs(temp,"PROGRAMS\\FFISDUPE.PRG")) {
				//_BreakPoint();
				IsPJX=TRUE;//noop for breakpt
			}*/
			GetFPExpr("m.filetype",FileType,'C');
			if (temp[1]!=':') {//not full path provided
				strcat(strcpy(CurFile,MainInPath),temp);
			} else {
				strcpy(CurFile,temp);
			}
			PutFPVar("file",CurFile,'C');
			_Executef("m.file=FULLPATH(m.file)");
			GetFPExpr("m.file",CurFile,'C');
			if (GetFPExpr("IIF(FILE(m.file),1,0)",&Retval,'I')) {	//see if file exists
				if (!fBeautifyMode)
					_Executef("this.ThermRef.lblTitle.caption=this.Justfname('%s')",CurFile);
				if (!Pass1 && nRep_Source_Code) {
					sprintf(OutputLine,"****** * %s",CurFile);
					_FPuts(nRep_Source_Code,OutputLine);
				}
				if (strchr("PSM",*FileType)) {//prg or spr or mpr
	//				StatMsg(CurFile);
					switch(OutputMode) {
					case 1:	//overwrite existing files. Output to .BAK, rename later
						ForceExt(CurFile,"bak",OutFile);
						if (!Pass1) 
							remove (OutFile);
						break;
					case 2://all output to a single dir
						JustFName(CurFile,temp);
						strcat(strcpy(OutFile,OutPath),temp);
						break;
					case 3://all output to another tree
						if (IsPJX) {
							DoMakePath(temp);
						} else {
							JustFName(CurFile,temp);
							strcat(strcpy(OutFile,OutPath),temp);
						}
						break;
					}
					if (ProcessFile(CurFile,OutFile)) {
						_Executef("Select files");
						if (Pass1 && _Executef("REPLACE done WITH 'Y'")) {
							_UserError("REPL");
						} //mark this file as done
					} else {
						_Executef("Select files");
						if (Pass1) 
							_Executef("REPLACE done WITH 'U'");
					}
					if (!Pass1) {
						switch(OutputMode) {
						case 1:	//overwrite
							remove(CurFile);
							rename(OutFile,CurFile);
							break;
						case 2:
							break;
						case 3:
							break;
						}
					}
				} else if (strchr("smRLVKd",*FileType)) {//Snippet file: screen,menu,report,label,vcx
					//(K is a SCX)
					char thisbuf[600];
					StatMsg("%s",JustFName(CurFile,thisbuf));
					if (_Executef("USE '%s' AGAIN IN 0 ALIAS SnipFile SHARED",CurFile)) {
	//					StatMsg("Err: can't open %s",CurFile);
					} else {
						if (Pass1 && _Executef("REPLACE done WITH 'Y'")) 
							_UserError(GetString(IDS_DONE));
						_Executef("SELECT SnipFile");
						Value Result;
						_Evaluate(&Result,"select()");
						WorkArea=Result.ev_long;
						//gotta put filename in sym table during pass1
						if (!LookupInOutput) 
							PutFPVar("filename",CurFile,'C');
						switch(OutputMode) {
						case 1:	//overwrite existing
							break;
						case 2:	//all in a single dir
							JustFName(CurFile,temp);
							strcat(strcpy(CurFile,OutPath),temp);
							if (!Pass1) {
								_Executef("set deleted off");
								_Executef("copy to '%s'",CurFile);
								if (*FileType == 'd')
									// is DBC, so fix header
									FixDBCHeader(CurFile);
								_Executef("set deleted on");
								_Executef("use '%s' alias SnipFile again shared",CurFile);
							}
							break;
						case 3:	//Must be IsPJX
							DoMakePath(temp);
							strcpy(CurFile,OutFile);
							if (!Pass1) {
								_Executef("copy to '%s'",CurFile);
								if (*FileType == 'd')
									// is DBC, so fix header
									FixDBCHeader(CurFile);
								_Executef("use '%s' alias SnipFile",CurFile);
							}
							break;
						}
						if (LookupInOutput) 
							PutFPVar("filename",CurFile,'C');
	//					StatMsg(" Snipfile %s",CurFile);
						IsSnippet=TRUE;
						switch(*FileType) {
						case 'K'://taz scx
						case 'V'://taz class lib
						case 's':
							SCX();
							break;
						case 'M':
							MNX();
							break;
						case 'L':
						case 'R':
//							FRX();	//RED00KGZ
							break;
						case 'd':
							DBC();
						}
						IsSnippet=FALSE;
						_Executef("USE");
					}
				} else if (*FileType=='x') {//BMP or TXT or something else
					if (!Pass1 && OutputMode==3) {
						PATHSTR temp2;
						strcpy(temp2,temp);
						DoMakePath(temp);
						CopyFile(temp2,OutFile,FALSE);	//always overwrite
					}
				}
			}	//file exists

			_Executef("SELECT files");
			if (IsPJX) {
				_DBSkip(-1,1);
				_Executef("this.iPctComplete=this.iPctComplete+50/Reccount()");
//				_Executef("wait window 'asdf'+str(this.iPctComplete,10)+chr(13)+str(recno(),4)+str(reccount(),4)");
			} else {
				if (!fBeautifyMode)
				{
					_Executef("this.iPctComplete=50");
					_Executef(GetString(IDS_THERMUP)); //"this.ThermRef.Update(50,'Pass 2')");
				}
				if (iPass==1) {
					if (SingleFile) 
						break;
					_Executef("DO ScanRef");	//suck in more files
				} else {
					_DBSkip(-1,1);
				}
			}
		} //each file
		if (!fBeautifyMode)
		{
			_Executef("this.iPctComplete=50");
			_Executef(GetString(IDS_THERMUP)); //"this.ThermRef.Update(50,'Pass 2')");
		}
	} //each pass
	_Executef("USE IN xreffile");
	_Executef("USE IN xrefproc");
	if (LookupInOutput) 
		_Executef("do adjust");	//adjust line numbers
	PutFPVar("TotalLines",&TotalLines,'I');
#ifndef NOPROFILE
//	_FDisableMeas();
#endif
	_RetInt(1,10);
}

void fdFoxDoc(ParamBlk *ParmBlk) {
	try {
		fdDoIt(ParmBlk);
	} catch (char *buff) {
		Value Result;
		char buff2[400];
		_Evaluate(&Result,"IIF(oEngine.mdev,1,0)");
		sprintf(buff2,"=MessageBox('%s',64)",buff);
		_Execute(buff2);
		if (Result.ev_long) {
			_Execute("suspend");
		} else {
//			_Error(ret);
		}
	}
}

/*Timing test:
	int i;
	_Executef("start=seconds()");
	for (i=0 ; i<10000 ; i++) {
		_Executef("j='asdf'");
	}
	_Executef("?seconds()-start");
*/

#ifdef _DEBUG


void  Example(ParamBlk FAR *parm)
{
#define p0 (parm->p[0].val)
#define p1 (parm->p[1].val)

	if (!_SetHandSize(p0.ev_handle, p0.ev_length + p1.ev_length +1))
		_Error(182); // "Insufficient Memory"
	_HLock(p0.ev_handle);
	_HLock(p1.ev_handle);
	((char FAR *) _HandToPtr(p0.ev_handle))[p0.ev_length ] = '\0';
	((char FAR *) _HandToPtr(p1.ev_handle))[p1.ev_length ] = '\0';


     _StrCpy((char FAR *) _HandToPtr(p0.ev_handle) + p0.ev_length,
     	(char *)_HandToPtr(p1.ev_handle));
     	
     _RetChar((char *)_HandToPtr(p0.ev_handle));
     _HUnLock(p0.ev_handle);
     _HUnLock(p1.ev_handle);

}



/*
#include <stdio.h>
#include <wtypes.h>

int getver(char *fname)
{
	DWORD handle;
	LPVOID buf;
	char version[20];
	VS_FIXEDFILEINFO  *data;
	unsigned int datasize, versize,langcode;
	
	
	if (versize=GetFileVersionInfoSize(fname, &handle)) {
		buf = malloc(versize);
		if (GetFileVersionInfo(fname,handle,versize,buf)) {
			if (VerQueryValue(buf,"\\",(void **)&data,&datasize)) {
				sprintf(version,"%d.%d.%d.%d",
					HIWORD(data->dwFileVersionMS),
					LOWORD(data->dwFileVersionMS),
					HIWORD(data->dwFileVersionLS),
					LOWORD(data->dwFileVersionLS));
			printf("File Version = %s\n",version);
			_PutStr(version);
			if (VerQueryValue(buf,"\\VarFileInfo\\Translation",(void **)&data,&datasize)) {
				langcode = *(DWORD*)data;
			}
			free(buf);
			return 0;
			}
		}
	}

	printf("No Version Info\n");
	return -1;
}
*/

void Test(ParamBlk *p) {
	Value v;
	char *ptr;
	v=p->p[0].val;
	_HLock(v.ev_handle);
	ptr=(char *)_HandToPtr(v.ev_handle);
	_HUnLock(v.ev_handle);
return;
}



void putLong(long n)
{
		Value val;

	val.ev_type = 'I';
	val.ev_long = n;
	val.ev_width = 10;

	_PutValue(&val);
}

void FAR dialogEx(ParamBlk FAR *parm)
{
	int selection;

    selection = _Dialog(DIALOG_SCHEME, "Example dialog with 3 buttons.",
		"First", "Second", "Third", 2, 3);

	_PutStr("\nItem selected ="); putLong(selection);

	selection = _Dialog(DIALOG_SCHEME, "Example dialog with 2 buttons.",
		"First", "Second", 0, 2, 2);

	_PutStr("\nItem selected ="); putLong(selection);

	selection = _Dialog(DIALOG_SCHEME, "Example dialog with 1 button.",
		"First", (char *) 0, (char *) 0, 1, 1);

	_PutStr("\nItem selected ="); putLong(selection);

	selection = _Dialog(DIALOG_SCHEME, "Example dialog no buttons.",
		(char *) 0, (char *) 0, (char *) 0, 1, 2);

	_PutStr("\nItem selected ="); putLong(selection);
}



#endif




FoxInfo myFoxInfo[] = {
	{"INITIALIZE" , (FPFI) Initialize,  CALLONLOAD,   ""},


	{"UNINITALIZE", (FPFI) UnInitialize,CALLONUNLOAD, ""},
	{"BEAUTIFY"   , (FPFI) Beautify,3,"C,C,C"},
	{"EXAMINE"    , (FPFI) Examine,1,"C"},
	{"GOTOREC"    , (FPFI) GotoRec,0,""},
	{"CURPOS"     , (FPFI) CurPos,1,"C"},
	{"FOXDOCVER"  , (FPFI) FoxDocVer,3,".C.C.C"},
#ifdef _DEBUG
	{"STRCAT", (FPFI)Example, 2, "C,C"},
	{"TEST"  	  , (FPFI) Test,3,"?.C.C"},
	{"DIALOGEX", (FPFI) dialogEx,0, ""},
#endif
	{"FDFOXDOC"   , (FPFI) fdFoxDoc,4,"C,C,C,.C"}
};

extern "C" FoxTable _FoxTable = {
	(FoxTable FAR *)0, sizeof(myFoxInfo)/ sizeof(FoxInfo), myFoxInfo
};


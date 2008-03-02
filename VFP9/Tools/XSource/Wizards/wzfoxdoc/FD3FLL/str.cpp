#include "fd3.h"

char *ToTrim(char *p) {
// 
// This routine trims the string pointed to by p
//
//--------------------------------------------------------------------------
	char *endp;
	if (p != NULL) {
		endp=strlen(p)+p-1;
		while (strchr(WhiteSpaceChars,*endp)) endp--;
	}
	*++endp='\0';
	return(p);
}

char *ToLTrim(char *p) {
// 
// This routine ltrims the string pointed to by p
//
//--------------------------------------------------------------------------	
	char *q=p;
	while (strchr(WhiteSpaceChars,*q)) q++;
	_MemMove(p,q,strlen(q)+1);
	return(p);
}

char *ToUpper(char *s) {
// 
// This routine converts the string pointed to by p to upper case.  
//
//--------------------------------------------------------------------------
	return AnsiUpper(s);
}

char *ToLower(char *s) {
	return AnsiLower(s);
}


//--------------------------------------------------------------------------
char *ToDelete(char *instrg, const unsigned num) {
//
// This routine deletes the first num bytes from the string pointed to
// by instrg, changing instrg directly.
//
//--------------------------------------------------------------------------
	if (strlen(instrg) <= num) *instrg = '\0';   // zap string if it is shorter than num
	else {
		if (num > 0) _MemMove(instrg,instrg+num,strlen(instrg+num)+1);
	}
	return instrg;
}

//--------------------------------------------------------------------------
char *strcatchr(char *outstr ,const char chr) {
//
// Append chr onto end of outstr.
//
//--------------------------------------------------------------------------
	char *p = (outstr + strlen(outstr));
	*p      = chr;
	*(p+1)  = '\0';
	return outstr;
}

//--------------------------------------------------------------------------
char *ToRemoveQuotes(char *buff) {
//
// Removes quotes if they begin and end buff.
//
//--------------------------------------------------------------------------
	// Does it start with a quote?  If not, then leave now.
	if (strchr("\"'[", *buff) == NULL) return buff;
	ToTrim(buff);
	if ((*buff == '\'' && *(buff + strlen(buff)-1) == '\'') 
			|| (*buff == '\"' && *(buff + strlen(buff)-1) == '\"') 
			|| (*buff == '[' && *(buff + strlen(buff)-1) == ']')) {
		ToDelete(buff,1);
		buff[strlen(buff)]='\0';
	}
	return buff;
}

//--------------------------------------------------------------------------
char *JustFName(const char *filname, char *target) {
//
// This routine returns the filename portion of "filname".  The filename
// contains the stem and the extension, but excludes the path, if any.
//
//--------------------------------------------------------------------------
	char *p,*q;
	if (filname == NULL) {
		*target = '\0';
	} else {
		_MemMove(target,filname,strlen(filname)+1);
		ToRemoveQuotes(ToTrim(target));
		// Find the rightmost backslash and take everything after it.
		q = target;
		if ((p= strrchr(q,'\\'))) q = p+1;
		// Find the rightmost remaining colon and take everything after it.
		if((p=strrchr(q,':'))) q = p+1;
		_MemMove(target,q,strlen(q)+1);
	}
	return target;
}


//--------------------------------------------------------------------------
char *JustStem(const char *filname, char *target) {
//
// This routine returns the stem portion of "filname".  The stem
// excludes the extension and the pathname, if any.
//
//--------------------------------------------------------------------------
	char *p;
	JustFName(filname,target);
	if (p=strrchr(target,'.')) *p='\0';
	// the path/file name could have
	// periods in it, like:  "..\FOO"
	// limiting the stem to 8 characters breaks the code that records
	// procedure names, since they can be longer than 8 characters.
	// strncpy(stem,buff,8);   
	// *(stem+8) = '\0';
	return target;
}

//--------------------------------------------------------------------------
char *JustExt(const char *filname, char *target) {
//
// This routine returns the file extension portion of "filname".
//
//--------------------------------------------------------------------------
	char *p;
	JustFName(filname,target);
	if (p=strrchr(target,'.')) {
		_MemMove(target,p+1,strlen(p)+1);
		if (strlen(target) > 3) *(target+3) = '\0';
	} else target[0]='\0';
	return target;
}
//--------------------------------------------------------------------------
char *JustPath(const char *filname, char *target) {
//
// This routine returns the path name portion of "filname".  The
// pathname contains the drive designation, if any.  It *does* include
// a trailing backslash, even if the path is for the root, in which
// case justpath returns a single backslash character (plus drive, if
// any). This way, you can just add fname to the path to get a valid pathfile
// If there's no backslash (i.e. just a filename), return Nullstring.
//--------------------------------------------------------------------------
	char *p;
	if (filname == NULL) {
		*target = '\0';
	} else {
		_MemMove(target,filname,strlen(filname)+1);
		ToRemoveQuotes(ToTrim(target));
		// Find the rightmost backslash and take everything before it.
		if (p=strrchr(target,'\\')) {
			*(p+1) = '\0';
			// special case of single backslash as path (e.g., \FOXPRO2)
			// special case of drive name followed by root (e.g., C:\COMMAND.COM)
//			#if WIN386
				if((strlen(target) == 2) && (*(filname+1) == ':')) strcat(target,"\\");
/*			#elif MAC_OS
				if ((strchr(target, ':')) == (target+strlen(target)-1)) strcat(target, "\\");
			#endif*/
		} else {
/*			#if MAC_OS
				p = strrchr(target,':');
			#endif*/
			//  No backslashes in the file name.  This looks like an ordinary 
			//  file name, such as "COMMAND.COM".  Return an empty string.
			*target = '\0';
		}
	}
	return target;
}

//--------------------------------------------------------------------------
char *JustDrive(const char *filname, char *target) {
//
// This routine returns the drive name portion of "filname" including
// the colon.  
//
//--------------------------------------------------------------------------
   char *p;
   if (filname == NULL) {
      *target = '\0';
   } else {
		_MemMove(target,filname,strlen(filname)+1);
		ToRemoveQuotes(target);
		if (p = strchr(target,':')) *(++p) = '\0';
		else *target = '\0';
      
//   #if WIN386
	// invalid drive string if the name plus the colon isn't exactly
	// two characters long.
		if (strlen(target) != 2) *target = '\0';
//   #endif
	}
	return target;
}


//--------------------------------------------------------------------------
char *ForceExt(const char *fname, const char *ext,char *target) {
//
// This routine takes a file/path name and forces its extension to be
// 'ext', changing fname itself.
//
//--------------------------------------------------------------------------
	PATHSTR temp, stem;
	if (fname==NULL) {
		*target='\0';
	} else {
		JustStem(fname,stem);                   // capture the stem
		if (*stem) {
			JustPath(fname,temp);
			AddBS(temp,target);                 // put the path into outstr
			strcat(target,stem);
			strcat(target,".");
			strcat(target,ext);                  // add the stem and the new ext
		} else {
			strcpy(target,fname);
		}
	}
	return target;
}

//--------------------------------------------------------------------------
char *AddBS(const char *const filname, char *target) {
//
// This routine returns "filname" with a backslash added, unless filname
// is empty or already ends with a backslash, in which case it simply
// returns filname unchanged.  Newfname must be large enough to hold
// the path and the extra backslash.
// 2 args can be the same
//--------------------------------------------------------------------------
	if (filname == NULL) {
		*target = '\0';
	} else {
		_MemMove(target,filname,strlen(filname)+1);
		ToRemoveQuotes(ToTrim(target));
		// If the last character in the string is not already a backslash or colon,
		// and if the string is not empty, add a backslash to it.
		if( *(target + strlen(target) - 1 ) != PATH_SEP_CHR 
	/*			#if MAC_OS
				&& *(target + strlen(target) - 1 ) != PATH_SEP_CHR_ALT
				#endif*/
				&& strlen(target) > 0 ) {
			strcatchr(target,PATH_SEP_CHR);
		}
	}
	return target;
}


//--------------------------------------------------------------------------
unsigned str2bin(char *strg) {
//
// Converts a string of 1's and 0's into an unsigned int.
//
//--------------------------------------------------------------------------
	unsigned output = 0,mask = 1;
	int i;
    for (i = strlen(strg) - 1; i >= 0; i--) {
		if (strg[i] != '0')  output = output | mask;
		mask = mask << 1;
	}
	return output;
}
char *HandleToStr(MHANDLE mh) {
	//Converts handle to a char * pointer. Also locks the pointer. Does not null-terminate
	_HLock(mh);
	return (char *)_HandToPtr(mh);
}

char *ParmToStr(const ParamBlk *ParmBlk,const int pnum,char *target) {
	_HLock(ParmBlk->p[pnum].val.ev_handle);
	_MemMove(target,_HandToPtr(ParmBlk->p[pnum].val.ev_handle),ParmBlk->p[pnum].val.ev_length);
	target[ParmBlk->p[pnum].val.ev_length]='\0';
	return ToUpper(target);
}


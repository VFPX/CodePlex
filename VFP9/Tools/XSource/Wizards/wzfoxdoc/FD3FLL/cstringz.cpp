#include <iostream.h>
#include <string.h>
#include <ctype.h>
#include <windows.h>
#include <stdlib.h>
#include <pro_ext.h>
#include "CStringz.hpp"

CStringz::CStringz () { //default constructor
	str='\0';
	mh=0;
	IsLocked=FALSE;
}

CStringz::CStringz (char *s) { //constructor
	mh=_AllocHand(strlen(s)+1);
	_HLock(mh);
	str=(char *)_HandToPtr(mh);
	strcpy(str,s);
	_HUnLock(mh);
	IsLocked=FALSE;
}
	

void CStringz::Create(Value *Val) {
	if (Val->ev_type != 'C') { //null
		mh=0;
		str = '\0';
	} else {
		mh=_AllocHand(Val->ev_length+1);
		if (mh==NULL) _Error(182);
		_HLock(mh);
		str=(char *)_HandToPtr(mh);
		_HLock(Val->ev_handle);
		_MemMove(str,_HandToPtr(Val->ev_handle),Val->ev_length);
		str[Val->ev_length]='\0';
		_HUnLock(Val->ev_handle);
		_HUnLock(mh);
	}
	IsLocked=FALSE;
}

CStringz::CStringz (ParamBlk *parm,int pnum) {//Constructor
	Value val;
	if (pnum<parm->pCount) {
		if (parm->p[pnum].val.ev_type=='R') {
			_Load(&parm->p[pnum].loc,&val);
			Create(&val);
			_FreeHand(val.ev_handle);
		} else {
			Create(&parm->p[pnum].val);
		}
	} else {
		CStringz();
	}
}

CStringz::CStringz (Value *Val) {//constructor
	Create(Val);
}

CStringz::CStringz(CStringz &s) {//copy cons
	mh=_AllocHand(strlen(s.str)+1);
	_HLock(mh);
	str=(char *)_HandToPtr(mh);
	s.Refresh();
	strcpy(str,s.str);
	_HUnLock(mh);
	IsLocked=FALSE;
}

CStringz::~CStringz() {	//destructor
	UnLock();
	if (mh)	{
		_FreeHand(mh);
	}
}

int CStringz::len() {
	Refresh();
	return strlen(str);
}

char * CStringz::pstring() {
	Refresh();
	return str;
}
void CStringz::Lock() {
	if (!IsLocked) {
		_HLock(mh);
		str=(char *)_HandToPtr(mh);
/*
		if (!str) {
			_UserError("5");
		}
*/
		IsLocked=TRUE;
	}
}

void CStringz::UnLock() {
	if (IsLocked) {
		_HUnLock(mh);
		IsLocked=FALSE;
	}
}

void CStringz::Refresh() {
	if (mh) {
		Lock();
		UnLock();
	}
}

int CStringz::val() {
	Refresh();
	return *str? atoi(str): 0;
}

CStringz & CStringz::Upper(void) {
//	char *p=str;
	Refresh();
    AnsiUpper(str);
//	for ( ; *p ; p++) *p=toupper(*p);
	return *this;
}

CStringz & CStringz::Lower(void) {
//	char *p=str;
	Refresh();
    AnsiLower(str);
//	for ( ; *p ; p++) *p=tolower(*p);
	return *this;
}

void CStringz::Show() {
	if (str==NULL) _UserError("CStringz Show: Null string");
	Refresh();
	_PutStr(str);
}

CStringz operator +(CStringz&p1,CStringz &p2){	//add
	CStringz temp;
	temp.mh=_AllocHand(strlen(p1.str)+strlen(p2.str)+1);
	if (temp.mh==0) _Error(182);
	_HLock(temp.mh);
	temp.str=(char *)_HandToPtr(temp.mh);
	p1.Refresh();
	strcpy(temp.str,p1.str);
	p2.Refresh();
	strcat(temp.str,p2.str);
	_HUnLock(temp.mh);
	return temp;
}

char CStringz::Char(int i) {
	char c;
	if (!mh || i>= len()) return NULL;//len() does a refresh()
	c=str[i];
	return c;
}


int CStringz::operator ==(CStringz & s) { //equality
	if (this==&s) return 1;
	Refresh();
	s.Refresh();
	if (strlen(s.str) != strlen(str)) return 0;
	if (strlen(s.str)!= strlen(str)) return 1;
	return !strcmp(str,s.str);
}

CStringz & CStringz::operator =(CStringz & s) { //assignment
	if (this==&s) return *this;
	UnLock(); //so can realloc
	s.Refresh();
	if (!mh) {
		mh=_AllocHand(strlen(s.str)+1);
	} else {
		_SetHandSize(mh,strlen(s.str)+1);
	}
	Lock();
	s.Lock();
	strcpy(str,s.str);
	UnLock();
	s.UnLock();
	return *this;
}


CStringz & CStringz::operator =(Value * v) { //assignment
	if (v->ev_type!='C') _UserError("Value: Wrong type");
	UnLock();
	if (!mh) {
		mh=_AllocHand(v->ev_length+1);
	} else {
		_SetHandSize(mh,v->ev_length+1);
	}
	if (!mh) _Error(182);
	Lock();
	_HLock(v->ev_handle);
	_MemMove(str,(char *)_HandToPtr(v->ev_handle),v->ev_length);
	str[v->ev_length]='\0';
	_HUnLock(v->ev_handle);
	UnLock();
	return *this;
}


CStringz & CStringz::operator =(char * s) { //assignment
	int len;
	UnLock();
	len=strlen(s);
	if (!mh) {
		mh=_AllocHand(len+1);
	} else {
		_SetHandSize(mh,len+1);
	}
	if (!mh) _Error(182);
	Lock();
	_MemMove(str,s,len);
	str[len]='\0';
	UnLock();
	return *this;
}



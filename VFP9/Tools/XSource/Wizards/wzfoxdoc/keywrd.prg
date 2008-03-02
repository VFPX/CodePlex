* THIS FILE SHOULD NOT BE LOCALIZED!!!

*- author: calvinh
*- This program creates the keyword table for foxdoc
*- it requires fdindent.dbf
*- 
*-   I Indent
*-   U Undent
*-   R Reset indentation to 0 (or 1 if InDefineClass)
*-   F Proc or function
*-   D While or Case: DO clause
*-   O Object (Spinner,CommandButton)
*-   P Property (Scalemode,DecimalPoints)
*-   M Method (Init,KeyPress)
*-   C Clause  Used only as a Clause: can't start a statement
*-
set dele on
set exac off
close data
create curs tokenp (token c(100),code c(5))
appe from \fox30\source\property.src sdf
repl all token with strtran(token,chr(9),"")
dele all for !(token="PROPERTY" or token="CLASSLIST")
repl all code with 'O' for token="CLASSLIST"
repl all code with 'P' for token="PROPERTY"
repl all code with 'M' for "TYPEEVENT"$token OR "TYPEMETHOD"$token
repl all token with subs(token,at('"',token)+1)
repl all token with left(token,at('"',token)-1) FOR at('"',token)>0
repl all token with left(token,at('(',token)-1) FOR at('(',token)>0
dele all for token=' '
dele all for ' '$alltrim(token)
copy to keyp

create curs tokenk (token c(100),code c(5))
appe from \fox30\source\nonloc.src sdf
*Delete the color schemes
dele all while token#"#HEADER KEYWORD.H"

dele all for occurs('"',token)#2
repl all token with strtran(token,chr(9),"")
repl all code with 'C' for token="OVK"	&& clause
dele all for token# 'OV'
repl all token with subs(token,at('"',token)+1)
repl all token with left(token,at('"',token)-1) FOR at('"',token)>0
dele all for token=' '
dele all for val(token)>0
dele all for token='\'
dele all for token="'"
repl all token with left(token,at('(',token)-1) FOR at('(',token)>0
dele all for ' '$alltrim(token)
DELE ALL FOR UPPER(token)="PARAMETERLIST"
copy to keyk for !EMPTY(token)
sele 0
use fdkeywrd
sele 0
create table keywrd1 (token c(22),code c(5))
appe from keyp
appe from keyk
inde on upper(token) tag token uniq
copy to keywrd
use keywrd
erase keywrd1.dbf
inde on upper(token) tag token

if file ("fdindent.dbf")

	wait window nowait "now updating indent codes"
	sele 0
	use fdindent
	scan
		select keywrd
		seek upper(fdindent.token)
		if found()
			repl code with fdindent.code
		else
			insert into keywrd (token,code) values ;
				(fdindent.token,fdindent.code)
		endif
	endscan
	SELECT fdkeywrd
	zap
	appe from keywrd
	set orde to 1
endif

brow last nowait
wait clear

retu



sele upper(token) from fdkeywrd where Upper(token) not in;
	(select upper(token) from keywrd)


*American,this,thisform,thisformset

* In nonloc, sysmenu(s),disable(d)


* strings.src
* STRINGS STROVL_MISC, BYITEM


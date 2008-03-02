* VFPScrpt.prg
*
*-- ASCII codes
#DEFINE	EOB		CHR(0)
#DEFINE	MARKER	CHR(1)
#DEFINE	TAB		CHR(9)
#DEFINE	LF		CHR(10)
#DEFINE	CR		CHR(13)
#DEFINE CR_LF	CR+LF

*-- Strings
#DEFINE	VFPS_SCRIPT_START	'<SCRIPT LANGUAGE="VFPS">'
#DEFINE	VFPS_SCRIPT_START2	'<SCRIPT LANGUAGE="VFPScript">'
#DEFINE	VFPS_SCRIPT_START3	'<SCRIPT LANGUAGE=VFPS>'
#DEFINE	VFPS_SCRIPT_START4	'<SCRIPT LANGUAGE=VFPScript>'
#DEFINE	VBS_SCRIPT_START	'<SCRIPT LANGUAGE="VBS">'
#DEFINE SCRIPT_END			"</SCRIPT>"
#DEFINE	VFPS_FUNCTION_START	"FUNCTION"
#DEFINE	VFPS_FUNCTION_END	"ENDFUNC"
#DEFINE	VBS_FUNCTION_START	"Sub"
#DEFINE	VBS_FUNCTION_END	"End Sub"



LPARAMETERS toWebBrowser

RETURN HTMLX(toWebBrowser)



FUNCTION HTMLX(toWebBrowser)
PRIVATE pcSourceText,pcNewSourceText,pcAppendSourceText,pcRefreshData,pcRefreshSource
LOCAL lcVFPScript,lcFilePath,lcFileName,lnLastSelect
LOCAL lcMainScriptCode,lcScriptCode,lcScript,llBusy
LOCAL lcMemLine,lnCount,lnAtPos,lnAtPos1,lnAtPos2

IF TYPE("toWebBrowser")#"O" OR ISNULL(toWebBrowser)
	RETURN .F.
ENDIF
WITH toWebBrowser
	llBusy=.lBusy
	.SetBusyState(.T.)
	.OpenVFPScript
	.RunScript("OnUnLoad")
	.nScriptCount=0
	DIMENSION .aScripts[1,3]
	.aScripts=""
ENDWITH
lnLastSelect=SELECT()
CREATE CURSOR tempHTMLfile (Source M)
APPEND BLANK
APPEND MEMO Source FROM (toWebBrowser.cSourceFileName) OVERWRITE
pcSourceText=ALLTRIM(Source)
USE
IF NOT LEFT(pcSourceText,1)=="CR"
	pcSourceText=CR+pcSourceText
ENDIF
IF NOT RIGHT(pcSourceText,1)=="CR"
	pcSourceText=pcSourceText+CR_LF
ENDIF
pcNewSourceText=pcSourceText
pcAppendSourceText=""
pcRefreshData=""
pcRefreshSource=""
DO WHILE .T.
	IF toWebBrowser.lRelease
		EXIT
	ENDIF
	lcVFPScript=""
	pcNewSourceText=StrTranC(pcNewSourceText,VFPS_SCRIPT_START2, ;
			VFPS_SCRIPT_START)
	pcNewSourceText=StrTranC(pcNewSourceText,VFPS_SCRIPT_START3, ;
			VFPS_SCRIPT_START)
	pcNewSourceText=StrTranC(pcNewSourceText,VFPS_SCRIPT_START4, ;
			VFPS_SCRIPT_START)
	lnAtPos1=ATC(VFPS_SCRIPT_START,pcNewSourceText)
	IF lnAtPos1=0
		pcNewSourceText=EvlTxt(pcNewSourceText)
		IF NOT EMPTY(pcAppendSourceText)
			IF toWebBrowser.lDebug
				pcAppendSourceText=toWebBrowser.EditString(pcAppendSourceText)
			ENDIF
			pcNewSourceText=pcNewSourceText+pcAppendSourceText
			pcAppendSourceText=""
			LOOP
		ENDIF
		EXIT
	ENDIF
	lnAtPos2=ATC(SCRIPT_END,SUBSTR(pcNewSourceText,lnAtPos1))
	IF lnAtPos2=0
		EXIT
	ENDIF
	lcVFPScript=SUBSTR(pcNewSourceText,lnAtPos1+LEN(VFPS_SCRIPT_START), ;
			lnAtPos2-LEN(VFPS_SCRIPT_START)-1)
	IF NOT EMPTY(pcAppendSourceText)
		IF toWebBrowser.lDebug
			pcAppendSourceText=toWebBrowser.EditString(pcAppendSourceText)
		ENDIF
		lcVFPScript=lcVFPScript+pcAppendSourceText
		pcAppendSourceText=""
	ENDIF
	IF NOT EMPTY(pcRefreshData)
		pcRefreshData=VFPS_SCRIPT_START+CR_LF+ ;
				VFPS_FUNCTION_START+[ RefreshData]+CR_LF+ ;
				[IF TYPE("oTHIS.document.script")#"O"]+CR_LF+ ;
				[	RETURN]+CR_LF+ ;
				[ENDIF]+CR_LF+ ;
				[SET DATASESSION TO (oTHIS.nDataSessionID)]+CR_LF+ ;
				EvlTxt(pcRefreshData)+CR_LF+;
				[SET DATASESSION TO (oTHIS.oHost.DataSessionID)]+CR_LF+ ;
				VFPS_FUNCTION_END+CR_LF+CR_LF+ ;
				VFPS_FUNCTION_START+[ RefreshSource]+CR_LF+ ;
				[IF TYPE("oTHIS.document.script")#"O"]+CR_LF+ ;
				[	RETURN]+CR_LF+ ;
				[ENDIF]+CR_LF+ ;
				[SET DATASESSION TO (oTHIS.nDataSessionID)]+CR_LF+ ;
				EvlTxt(pcRefreshSource)+CR_LF+;
				[SET DATASESSION TO (oTHIS.oHost.DataSessionID)]+CR_LF+ ;
				VFPS_FUNCTION_END+CR_LF+ ;
				SCRIPT_END+CR_LF
		IF toWebBrowser.lDebug
			pcRefreshData=toWebBrowser.EditString(pcRefreshData)
		ENDIF
		pcNewSourceText=pcNewSourceText+pcRefreshData
		pcRefreshData=""
	ENDIF
	pcNewSourceText=LEFT(pcNewSourceText,lnAtPos1-1)+ ;
			SUBSTR(pcNewSourceText,lnAtPos1+lnAtPos2+LEN(SCRIPT_END))
	IF EMPTY(lcVFPScript)
		LOOP
	ENDIF
	lcMainScriptCode=""
	lcScriptCode=""
	lcScript=""
	_mline=0
	FOR lnCount = 1 TO MEMLINES(lcVFPScript)
		lcMemLine=MLINE(lcVFPScript,1,_mline)
		IF UPPER(LEFT(lcMemLine,LEN(VFPS_FUNCTION_START)))==VFPS_FUNCTION_START
			IF EMPTY(lcMainScriptCode)
				lcMainScriptCode=lcScriptCode
			ENDIF
			lcScriptCode=""
			lnAtPos=AT(" ",lcMemLine)
			lcScript=IIF(lnAtPos=0,LOWER(SYS(2015)),ALLTRIM(SUBSTR(lcMemLine,lnAtPos+1)))
			LOOP
		ENDIF
		IF UPPER(LEFT(lcMemLine,LEN(VFPS_FUNCTION_END)))==VFPS_FUNCTION_END
			WITH toWebBrowser
				.nScriptCount=.nScriptCount+1
				DIMENSION .aScripts[.nScriptCount,3]
				.aScripts[.nScriptCount,1]=lcScript
				.aScripts[.nScriptCount,2]=EvlTxt(lcScriptCode)
				.aScripts[.nScriptCount,3]=lcScriptCode
			ENDWITH
			lcScript=""
			lcScriptCode=""
			LOOP
		ENDIF
		lcScriptCode=lcScriptCode+lcMemLine+CR_LF
	ENDFOR
	IF EMPTY(lcMainScriptCode) AND EMPTY(lcScript)
		lcMainScriptCode=EvlTxt(lcScriptCode)
	ENDIF
	IF NOT EMPTY(lcMainScriptCode)
		toWebBrowser.RunCode(lcMainScriptCode)
	ENDIF
	lcVFPScript=""
ENDDO
pcNewSourceText=EvlTxt(pcNewSourceText)
IF NOT EMPTY(pcAppendSourceText)
	IF toWebBrowser.lDebug
		pcAppendSourceText=toWebBrowser.EditString(pcAppendSourceText)
	ENDIF
	pcNewSourceText=pcNewSourceText+pcAppendSourceText
	pcAppendSourceText=""
ENDIF
IF toWebBrowser.lRelease OR pcNewSourceText==pcSourceText
	SELECT (lnLastSelect)
	toWebBrowser.SetBusyState(llBusy)
	RETURN .F.
ENDIF
CREATE CURSOR (toWebBrowser.cTempFilePrefix+LOWER(SYS(2015))) (Text M)
INSERT BLANK
REPLACE Text WITH pcNewSourceText
IF NOT toWebBrowser.lRefreshMode
	toWebBrowser.EraseTempFile
	lcFilePath=LOWER(toWebBrowser.TrimFile(toWebBrowser.cSourceFileName))
	lnAtPos1=RAT(":",lcFilePath)
	IF lnAtPos1>2
		lcFilePath=ALLTRIM(SUBSTR(lcFilePath,lnAtPos1-1))
	ENDIF
	lcFileName=lcFilePath+toWebBrowser.cTempFilePrefix+LOWER(SYS(2015))+".htm"
	toWebBrowser.cTempFileName=lcFileName
ENDIF
COPY MEMO Text TO (toWebBrowser.cTempFileName)
USE
SELECT (lnLastSelect)
toWebBrowser.SetBusyState(llBusy)
RETURN



FUNCTION EvlTxt(tcText)
LOCAL lcNewText,lcEvalStr,lcEvalStr1,lcEvalStr2,lcVarType
LOCAL lnAtPos,lnAtPos2,lnAtPos3,lnAtPos4,lnAtPos5,lnAtLine
LOCAL lnCount,lnCount2,llEvlMode,lcMethod,lcOldStr,lcNewStr
LOCAL lcName,lcFunction,lcClauses,lcControlName,lcControlSource
LOCAL lcDataValue,lcLabel,lnLastRecNo,lnRecNo,lcRecNo,llAddSize,lcSize
LOCAL lcEvent,lcHTMLControlSource,llInputTag,llCheckBox,lcAlias
LOCAL lnAtPos,lnAtPos2,lcInputTag,lcVFPCode,lcCode,lcMemVar

IF oTHIS.lRelease
	RETURN ""
ENDIF
SET DATASESSION TO (oTHIS.nDataSessionID)
m.lcNewText=m.tcText
m.lnAtPos3=1
DO WHILE .T.
	m.lnAtPos=AT("{{",SUBSTR(m.tcText,m.lnAtPos3))
	IF m.lnAtPos=0
		EXIT
	ENDIF
	m.lnAtPos2=AT("}}",SUBSTR(m.tcText,m.lnAtPos+m.lnAtPos3-1))
	IF m.lnAtPos2=0
		EXIT
	ENDIF
	m.lnAtPos4=AT("{{",SUBSTR(m.tcText,m.lnAtPos+m.lnAtPos3+1))
	IF m.lnAtPos4>0 AND m.lnAtPos4<m.lnAtPos2
		m.lnAtPos4=OCCURS("{{",SUBSTR(m.tcText,m.lnAtPos+m.lnAtPos3-1,;
				m.lnAtPos2-m.lnAtPos4))
		m.lnAtPos4=AT("{{",SUBSTR(m.tcText,m.lnAtPos+m.lnAtPos3-1),m.lnAtPos4)
		m.lcOldStr=SUBSTR(m.tcText,m.lnAtPos+m.lnAtPos3-1,m.lnAtPos2+1)
		m.lcEvalStr=SUBSTR(m.lcOldStr,3,LEN(m.lcOldStr)-2)
		m.lcOldStr=EvlTxt(m.lcEvalStr)
		m.tcText=STRTRAN(m.tcText,m.lcEvalStr,m.lcOldStr)
		m.lcNewText=STRTRAN(m.lcNewText,m.lcEvalStr,m.lcOldStr)
		LOOP
	ENDIF
	m.lcOldStr=SUBSTR(m.tcText,m.lnAtPos+m.lnAtPos3-1,m.lnAtPos2+1)
	m.lcEvalStr=ALLTRIM(SUBSTR(m.lcOldStr,3,LEN(m.lcOldStr)-4))
	m.llEvlMode=.F.
	DO CASE
		CASE EMPTY(m.lcEvalStr)
			m.lcEvalStr=""
		CASE LEFT(m.lcEvalStr,2)=="&."
			m.lcEvalStr=SUBSTR(m.lcEvalStr,3)
			&lcEvalStr &&;
			Error occured during macro substitution of {{&. <expC> }}.
			m.lcEvalStr=""
		CASE LEFT(m.lcEvalStr,2)=="*:"
			m.lcEvalStr=UPPER(ALLTRIM(SUBSTR(m.lcEvalStr,3)))
			DO CASE
				CASE m.lcEvalStr=="DEBUG"
					oTHIS.lDebug=.T.
				CASE m.lcEvalStr=="NODEBUG"
					oTHIS.lDebug=.F.
				CASE m.lcEvalStr=="DESIGN"
					oTHIS.lDesign=.T.
				CASE m.lcEvalStr=="NODESIGN"
					oTHIS.lDesign=.F.
			ENDCASE
			RETURN ""
		CASE LEFT(m.lcEvalStr,2)=="<:"
			lcName=SUBSTR(m.lcEvalStr,3)
			lcAlias=""
			lnAtPos=AT("::",lcName)
			IF lnAtPos>0
				lcAlias=ALLTRIM(LEFT(lcName,lnAtPos-1))
				lcName=ALLTRIM(SUBSTR(lcName,lnAtPos+2))
			ENDIF
			m.lcEvalStr=oTHIS.GetHTML(lcName,lcAlias) &&;
			Error occured during evaluation of {{<: <expC> }}.
		CASE LEFT(m.lcEvalStr,1)=="<"
			m.lcEvalStr=InsFile(SUBSTR(m.lcEvalStr,2)) &&;
			Error occured during evaluation of {{< <file> }}.
		CASE LEFT(m.lcEvalStr,1)==">"
			lcName=SUBSTR(m.lcEvalStr,2)
			oTHIS.uReturn=""
			oTHIS.VFPS(oTHIS.cVFPSProtocol+"RunScript?"+lcName) &&;
			Error occured during RunScript of {{> <expC> }}.
			m.lcEvalStr=oTHIS.uReturn
		CASE LEFT(m.lcEvalStr,1)=="@"
			m.lcEvalStr=SUBSTR(m.lcEvalStr,2)
			lnAtPos=AT(",",m.lcEvalStr)
			IF lnAtPos=0
				RETURN ""
			ENDIF
			lcLabel=SUBSTR(m.lcEvalStr,lnAtPos+1)
			lcClauses=ALLTRIM(LEFT(m.lcEvalStr,lnAtPos-1))
			llInputTag=(UPPER(LEFT(lcClauses,5))=="INPUT")
			lcControlSource=""
			lcEvent=""
			lcCode=""
			lnAtPos=AT(",",lcLabel)
			IF lnAtPos>0
				lcControlSource=ALLTRIM(SUBSTR(lcLabel,lnAtPos+1))
				lcLabel=ALLTRIM(LEFT(lcLabel,lnAtPos-1))
				lnAtPos=AT(",",lcControlSource)
				IF lnAtPos>0
					lnAtPos2=AT("]",lcControlSource)
					IF lnAtPos2=0
						lnAtPos2=AT(")",lcControlSource)
					ENDIF
					IF BETWEEN(lnAtPos,1,lnAtPos2)
						lnAtPos=AT(",",lcControlSource,2)
					ENDIF
				ENDIF
				IF lnAtPos>0
					lcEvent=ALLTRIM(SUBSTR(lcControlSource,lnAtPos+1))
					lcControlSource=ALLTRIM(LEFT(lcControlSource,lnAtPos-1))
					lnAtPos=AT(",",lcEvent)
					IF lnAtPos>0
						lcCode=ALLTRIM(SUBSTR(lcEvent,lnAtPos+1))
						lcEvent=ALLTRIM(LEFT(lcEvent,lnAtPos-1))
					 ENDIF
				 ENDIF
			ENDIF
			IF EMPTY(lcControlSource)
				RETURN ""
			ENDIF
			lcMemVar=""
			lnAtPos=AT("=",lcControlSource)
			IF lnAtPos>0
				lcMemVar=ALLTRIM(LEFT(lcControlSource,lnAtPos-1))
				lcControlSource=ALLTRIM(SUBSTR(lcControlSource,lnAtPos+1))
				IF EMPTY(lcMemVar)
					lcMemVar="pu"+LOWER(LOWER(SYS(2015)))
				ENDIF
			ENDIF
			lcRecNo=""
			lnAtPos=AT("@",lcControlSource)
			IF lnAtPos>0
				lcRecNo=ALLTRIM(SUBSTR(lcControlSource,lnAtPos+1))
				lcControlSource=ALLTRIM(LEFT(lcControlSource,lnAtPos-1))
			ENDIF
			lcAlias=""
			lnAtPos=AT("->",lcControlSource)
			IF lnAtPos>0
				lcAlias=ALLTRIM(LEFT(lcControlSource,lnAtPos-1))
				lcControlSource=ALLTRIM(SUBSTR(lcControlSource,lnAtPos+2))
			ELSE
				lnAtPos=AT(".",lcControlSource)
				IF lnAtPos>0
					lcAlias=ALLTRIM(LEFT(lcControlSource,lnAtPos-1))
				ENDIF
			ENDIF
			IF EMPTY(lcAlias) OR VAL(lcRecNo)=0
				lcRecNo=""
			ENDIF
			IF NOT EMPTY(lcAlias) AND USED(lcAlias)
				IF EOF(lcAlias)
					GO BOTTOM IN (lcAlias)
				ENDIF
				IF EMPTY(lcRecNo)
					oTHIS.nRecNo=RECNO(lcAlias)
					lcRecNo=[IIF(oTHIS.nRecNo>0,oTHIS.nRecNo,RECNO("]+lcAlias+["))]
				ENDIF
			ELSE
				lcRecNo=""
			ENDIF
			IF NOT EMPTY(lcRecNo)
				lnLastRecNo=RECNO(lcAlias)
				lnRecNo=EVALUATE(lcRecNo)
				GO lnRecNo IN (lcAlias)
			ELSE
				lnLastRecNo=0
			ENDIF
			m.lcEvalStr=lcControlSource
			m.lcEvalStr=EVALUATE(m.lcEvalStr) &&;
			Error occured during evaluation of {{ <expC> }}.
			IF lnLastRecNo>0
				GO lnLastRecNo IN (lcAlias)
			ENDIF
			m.lcVarType=TYPE("m.lcEvalStr")
			lcControlName=""
			lnAtPos=ATC("NAME=",lcClauses)
			IF lnAtPos>0
				lcControlName=ALLTRIM(SUBSTR(lcClauses,lnAtPos+6))
			ELSE
				lnAtPos=ATC("NAME =",lcClauses)
				IF lnAtPos>0
					lcControlName=ALLTRIM(SUBSTR(lcClauses,lnAtPos+7))
				ENDIF
			ENDIF
			IF EMPTY(lcControlName)
				lcControlName="ctl"+LOWER(SYS(2015))
			 	lcClauses=lcClauses+[ NAME="]+lcControlName+["]
			ELSE
				IF INLIST(LEFT(lcControlName,1),["],['],[ ],[,])
					lcControlName=ALLTRIM(SUBSTR(lcControlName,2))
				ENDIF
				lnAtPos=AT(["],lcControlName)
				lnAtPos2=AT(['],lcControlName)
				lnAtPos=IIF(lnAtPos2=0 OR BETWEEN(lnAtPos,1,lnAtPos2),lnAtPos,lnAtPos2)
				lnAtPos2=AT([ ],lcControlName)
				lnAtPos=IIF(lnAtPos2=0 OR BETWEEN(lnAtPos,1,lnAtPos2),lnAtPos,lnAtPos2)
				lnAtPos2=AT([,],lcControlName)
				lnAtPos=IIF(lnAtPos2=0 OR BETWEEN(lnAtPos,1,lnAtPos2),lnAtPos,lnAtPos2)
				IF lnAtPos>0
					lcControlName=ALLTRIM(LEFT(lcControlName,lnAtPos-1))
				ENDIF
			ENDIF
			IF llInputTag AND ATC("TYPE=",lcClauses)=0 AND ATC("TYPE =",lcClauses)=0
				lcClauses=lcClauses+[ TYPE="]+IIF(m.lcVarType=="L",[CHECKBOX],[TEXT])+["]
			ENDIF
			lcSize=""
			llAddSize=(llInputTag AND ATC("SIZE=",lcClauses)=0 AND ATC("SIZE =",lcClauses)=0)
			llCheckBox=(m.lcVarType=="L")
			lcHTMLControlSource=[oTHIS.document.script.]+lcControlName+IIF(llCheckBox,[.Checked],[.Value])
			IF EMPTY(lcEvent)
				lcEvent=IIF(llCheckBox,"OnClick","OnChange")
			ENDIF
			lcFunction=""
			IF NOT lcEvent=="-"
				lcFunction=lcControlName+"_"+lcEvent
				pcAppendSourceText=pcAppendSourceText+CR_LF+VBS_SCRIPT_START+CR_LF+ ;
						VBS_FUNCTION_START+" "+lcFunction+CR_LF
				pcAppendSourceText=pcAppendSourceText+[Navigate "vfps:RunScript?]+ ;
						lcFunction+["]+CR_LF
			ENDIF
			DO CASE
				CASE llCheckBox
					=.F.
				CASE m.lcVarType=="C" OR m.lcVarType=="M"
					IF llAddSize
						lcSize=ALLTRIM(STR(LEN(m.lcEvalStr)))
					ENDIF
				CASE m.lcVarType=="N"
					IF llAddSize
						lcSize=ALLTRIM(STR(LEN(ALLTRIM(STR(m.lcEvalStr)))))
					ENDIF
				CASE m.lcVarType=="D"
					IF llAddSize
						lcSize=ALLTRIM(STR(LEN(DTOC(m.lcEvalStr))))
					ENDIF
				CASE m.lcVarType=="T"
					IF llAddSize
						lcSize=ALLTRIM(STR(LEN(TTOC(m.lcEvalStr))))
					ENDIF
			ENDCASE
			IF NOT EMPTY(lcFunction)
				pcAppendSourceText=pcAppendSourceText+VBS_FUNCTION_END+CR_LF+ ;
						SCRIPT_END+CR_LF+CR_LF
			ENDIF
			pcAppendSourceText=pcAppendSourceText+VFPS_SCRIPT_START+CR_LF+ ;
					VFPS_FUNCTION_START+" "+lcFunction+CR_LF
			DO CASE
				CASE m.lcVarType=="C" OR m.lcVarType=="L"
					lcDataValue=lcHTMLControlSource
				CASE m.lcVarType=="N"
					lcDataValue=[VAL(]+lcHTMLControlSource+[)]
				CASE m.lcVarType=="D"
					lcDataValue=[CTOD(]+lcHTMLControlSource+[)]
				CASE m.lcVarType=="T"
					lcDataValue=[CTOT(]+lcHTMLControlSource+[)]
				OTHERWISE
					lcDataValue=lcHTMLControlSource
			ENDCASE
			lcVFPCode=""
			IF NOT EMPTY(lcCode)
				IF NOT RIGHT(lcCode,2)==CR_LF
					lcCode=lcCode+CR_LF
				ENDIF
				lcVFPCode=lcCode
			ENDIF
			IF NOT EMPTY(lcAlias) AND USED(lcAlias)
				IF EMPTY(lcMemVar)
					lcVFPCode=[REPLACE ]+lcControlSource+[ WITH ]+lcDataValue+CR_LF+lcVFPCode
				ELSE
					lcVFPCode=lcMemVar+[=]+lcDataValue+CR_LF+lcVFPCode
				ENDIF
				lcVFPCode=[SET DATASESSION TO (oTHIS.nDataSessionID)]+CR_LF+ ;
						[pnLastSelectTmp0=SELECT()]+CR_LF+ ;
						[SELECT ]+lcAlias+CR_LF+ ;
						[GO ]+lcRecNo+CR_LF+lcVFPCode+ ;
						[SELECT (pnLastSelectTmp0)]+CR_LF+ ;
						[SET DATASESSION TO (oTHIS.oHost.DataSessionID)]+CR_LF
			ELSE
				lcVFPCode=IIF(EMPTY(lcMemVar),lcControlSource,lcMemVar)+[=]+lcDataValue+CR_LF+lcVFPCode
			ENDIF
			pcAppendSourceText=pcAppendSourceText+lcVFPCode
			IF NOT EMPTY(lcRecNo)
				pcRefreshData=pcRefreshData+[GO ]+lcRecNo+[ IN ]+lcAlias+CR_LF
			ENDIF
			pcRefreshData=pcRefreshData+lcHTMLControlSource+[=]+lcControlSource+CR_LF
			IF NOT EMPTY(lcFunction)
				pcRefreshSource=pcRefreshSource+[oTHIS.RunScript("]+lcFunction+[")]+CR_LF
			ENDIF
			pcAppendSourceText=pcAppendSourceText+VFPS_FUNCTION_END+CR_LF+ ;
					SCRIPT_END+CR_LF
			DO CASE
				CASE NOT llInputTag
					=.F.
				CASE m.lcVarType=="C"
					m.lcEvalStr=[VALUE="]+m.lcEvalStr+["]
				CASE m.lcVarType=="N"
					m.lcEvalStr=ALLTRIM(STR(m.lcEvalStr,24,12))
					DO WHILE RIGHT(m.lcEvalStr,1)=="0"
						m.lcEvalStr=LEFT(m.lcEvalStr,LEN(m.lcEvalStr)-1)
						IF RIGHT(m.lcEvalStr,1)=="."
							m.lcEvalStr=LEFT(m.lcEvalStr,LEN(m.lcEvalStr)-1)
							EXIT
						ENDIF
					ENDDO
					m.lcEvalStr=[VALUE=]+m.lcEvalStr
				CASE m.lcVarType=="D"
					m.lcEvalStr=[VALUE="]+DTOC(m.lcEvalStr)+["]
				CASE m.lcVarType=="T"
					m.lcEvalStr=[VALUE="]+TTOC(m.lcEvalStr)+["]
				CASE m.lcVarType=="L"
					m.lcEvalStr=IIF(m.lcEvalStr,"CHECKED","")
				OTHERWISE
					m.lcEvalStr=""
			ENDCASE
			IF llAddSize AND NOT EMPTY(lcSize)
				lcClauses=lcClauses+[ SIZE=]+lcSize
			ENDIF
			lcInputTag=[<]+ALLTRIM(lcClauses+[ ]+m.lcEvalStr)+[>]
			IF m.lcVarType=="L"
				lcInputTag=lcInputTag+lcLabel
			ELSE
				lcInputTag=lcLabel+lcInputTag
			ENDIF
			m.lcEvalStr=lcInputTag
		OTHERWISE
			m.lcEvalStr=EVALUATE(m.lcEvalStr) &&;
			Error occured during evaluation of {{ <expC> }}.
	ENDCASE
	m.lcVarType=TYPE("m.lcEvalStr")
	DO CASE
		CASE m.lcVarType=="C"
			m.lcNewStr=m.lcEvalStr
		CASE m.lcVarType=="N"
			m.lcNewStr=ALLTRIM(STR(m.lcEvalStr,24,12))
			DO WHILE RIGHT(m.lcNewStr,1)=="0"
				m.lcNewStr=LEFT(m.lcNewStr,LEN(m.lcNewStr)-1)
				IF RIGHT(m.lcNewStr,1)=="."
					m.lcNewStr=LEFT(m.lcNewStr,LEN(m.lcNewStr)-1)
					EXIT
				ENDIF
			ENDDO
		CASE m.lcVarType=="D"
			m.lcNewStr=DTOC(m.lcEvalStr)
		CASE m.lcVarType=="T"
			m.lcNewStr=TTOC(m.lcEvalStr)
		CASE m.lcVarType=="L"
			m.lcNewStr=IIF(m.lcEvalStr,".T.",".F.")
		OTHERWISE
			m.lcNewStr=m.lcOldStr
	ENDCASE
	m.lcNewText=STRTRAN(m.lcNewText,m.lcOldStr,m.lcNewStr)
	m.lnAtPos2=m.lnAtPos+LEN(m.lcNewStr)
	IF m.lnAtPos2<=0
		EXIT
	ENDIF
	m.lnAtPos3=m.lnAtPos3+m.lnAtPos2
ENDDO
lnCount2=0
DO WHILE "{{"$m.lcNewText AND "}}"$m.lcNewText
	lnCount=LEN(m.lcNewText)
	m.lcNewText=EvlTxt(m.lcNewText)
	IF lnCount=LEN(m.lcNewText)
		IF lnCount2>=2
			EXIT
		ENDIF
		lnCount2=lnCount2+1
	ENDIF
ENDDO
RETURN m.lcNewText



FUNCTION InsFile(tcFileName)
LOCAL lcFileStr,lnLastSelect,lcAlias

IF TYPE("m.tcFileName")#"C" OR NOT FILE(m.tcFileName)
	RETURN ""
ENDIF
m.lnLastSelect=SELECT()
m.lcAlias=LOWER(SYS(2015))
IF USED(m.lcAlias)
	SELECT (m.lcAlias)
	LOCATE
ELSE
	CREATE CURSOR (m.lcAlias) (FILEINFO M)
	SELECT (m.lcAlias)
	INSERT BLANK
ENDIF
APPEND MEMO FILEINFO FROM (m.tcFileName) OVERWRITE
lcFileStr=FILEINFO
USE IN (m.lcAlias)
SELECT (m.lnLastSelect)
RETURN lcFileStr



FUNCTION StrTranC(ExpC1,ExpC2,ExpC3,ExpN1,ExpN2)
LOCAL lcExpr,lnAtPos,lnAtPos2,lnCount,lnCount2

IF EMPTY(m.ExpC1) OR EMPTY(m.ExpC2)
	RETURN m.ExpC1
ENDIF
lcExpr=m.ExpC1
IF TYPE("m.ExpN1")#"N"
	m.ExpN1=1
ENDIF
IF TYPE("m.ExpN2")#"N"
	m.ExpN2=LEN(m.ExpC1)
ENDIF
IF m.ExpN1<1 OR m.ExpN2<1
	RETURN m.ExpC1
ENDIF
m.lnCount=0
m.lnCount2=0
m.lnAtPos2=1
DO WHILE .T.
	m.lnAtPos=ATC(m.ExpC2,SUBSTR(lcExpr,m.lnAtPos2))
	IF m.lnAtPos=0
		EXIT
	ENDIF
	m.lnCount=m.lnCount+1
	IF m.lnCount<m.ExpN1
		m.lnAtPos2=m.lnAtPos+m.lnAtPos2+LEN(m.ExpC2)-1
		LOOP
	ENDIF
	lcExpr=LEFT(lcExpr,m.lnAtPos+m.lnAtPos2-2)+m.ExpC3+;
			SUBSTR(lcExpr,m.lnAtPos+m.lnAtPos2+LEN(m.ExpC2)-1)
	m.lnCount2=m.lnCount2+1
	IF m.lnCount2>=m.ExpN2
		EXIT
	ENDIF
	m.lnAtPos2=m.lnAtPos+m.lnAtPos2+LEN(m.ExpC3)-1
	IF m.lnAtPos2>LEN(lcExpr)
		EXIT
	ENDIF
ENDDO
RETURN lcExpr



FUNCTION VTOC(tcEvalStr)
LOCAL lcNewStr,lcVarType

IF PARAMETERS()=0
	RETURN ""
ENDIF
IF ISNULL(tcEvalStr)
	RETURN ".NULL."
ENDIF
lcVarType=TYPE("tcEvalStr")
DO CASE
	CASE INLIST(lcVarType,"U","O")
		RETURN ""
	CASE lcVarType=="C"
		lcNewStr=tcEvalStr
	CASE lcVarType=="N"
		lcNewStr=ALLTRIM(STR(tcEvalStr,24,12))
		DO WHILE RIGHT(lcNewStr,1)=="0"
			lcNewStr=LEFT(lcNewStr,LEN(lcNewStr)-1)
			IF RIGHT(lcNewStr,1)=="."
				lcNewStr=LEFT(lcNewStr,LEN(lcNewStr)-1)
			EXIT
			ENDIF
		ENDDO
	CASE lcVarType=="D"
		lcNewStr=DTOC(tcEvalStr)
	CASE lcVarType=="T"
		lcNewStr=TTOC(tcEvalStr)
	CASE lcVarType=="L"
		lcNewStr=IIF(tcEvalStr,".T.",".F.")
	OTHERWISE
		lcNewStr=""
ENDCASE
RETURN lcNewStr

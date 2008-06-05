* BROWSER.PRG - Class Browser.
*
* Copyright (c) 1995-2003 Microsoft Corp.
* 1 Microsoft Way
* Redmond, WA 98052
*
* Description:
* Class Browser for VCX/SCX files.
*

#INCLUDE "browser.h"

PARAMETERS tcFileName,tcDefaultClass,tlListBox,tcClassType,tnWindowState,tlGallery,tlNoShow
LOCAL oLastBrowser,lcLastSetTalk
PRIVATE lcProgramName

lcLastSetTalk=SET("TALK")
SET TALK OFF
IF _VFP.LanguageOptions=1
	MESSAGEBOX(M_LANGOPT_LOC) 
	_VFP.LanguageOptions=0
ENDIF
SYS(2333,0)
oLastBrowser=.NULL.
IF TYPE("_oBrowser")=="O" AND NOT ISNULL(_oBrowser)
	oLastBrowser=_oBrowser
ENDIF
RELEASE _oBrowser
PUBLIC _oBrowser
_oBrowser=.NULL.
lcProgramName=LOWER(SYS(16))
IF TYPE("tcFileName")=="N" AND tcFileName=0
	IF lcLastSetTalk=="ON"
		SET TALK ON
	ELSE
		SET TALK OFF
	ENDIF
	RETURN
ENDIF
IF tlListBox AND tlGallery
	MESSAGEBOX(M_LISTBOX_MODE_ERROR_LOC+".",48,M_COMPONENT_GALLERY_LOC)
	IF lcLastSetTalk=="ON"
		SET TALK ON
	ELSE
		SET TALK OFF
	ENDIF
	RETURN
ENDIF
tlBrowser=(NOT tlGallery)
IF tlNoShow
	DO FORM (FULLPATH("browser",lcProgramName)) ;
			WITH (tcFileName),(tcDefaultClass),(tlListBox),(tcClassType), ;
			(tnWindowState),(tlGallery) NAME _oBrowser NOSHOW
	IF VARTYPE(_oBrowser)=="O"
		_oBrowser.Activate
	ENDIF
ELSE
	DO FORM (FULLPATH("browser",lcProgramName)) ;
			WITH (tcFileName),(tcDefaultClass),(tlListBox),(tcClassType), ;
			(tnWindowState),(tlGallery) NAME _oBrowser
ENDIF
IF TYPE("_oBrowser")#"O" OR ISNULL(_oBrowser)
	_oBrowser=oLastBrowser
ENDIF
oLastBrowser=.NULL.
IF lcLastSetTalk=="ON"
	SET TALK ON
ELSE
	SET TALK OFF
ENDIF
RETURN



*-- Dummy lines for adding files to project.
DO c:\dev\browser\RunCode.prg
DO c:\dev\browser\VFPScrpt.prg

DO activdoc.ico
DO addclslb.bmp
DO addclslb.msk
DO addsbcls.bmp
DO addsbcls.msk
DO addins.bmp
DO addins.msk
DO apilibra.ico
DO apps.ico
DO back.bmp
DO back.msk
DO browser.bmp
DO browser.ico
DO browser.msk
DO catalog.ico
DO catalog2.ico
DO checkbx.ico
DO cfldr.ico
DO cfldr2.ico
DO classlib.ico
DO clibrary.ico
DO cleanup.bmp
DO cleanup.msk
DO collection.ico
DO collection.msk
DO cmdgroup.ico
DO code.ico
DO combo.ico
DO cofldr.ico
DO cofldr2.ico
DO containr.ico
DO control.ico
DO cursor.ico
DO cursor.msk
DO cursoradapter.ico
DO cursoradapter.msk
DO custom.ico
DO data.ico
DO dataenvironment.ico
DO database.ico
DO datagrid.ico
DO detlview.bmp
DO dfldr.ico
DO dfldr2.ico
DO docs.ico
DO dofldr.ico
DO dofldr2.ico
DO editbox.ico
DO explorer.ico
DO export.bmp
DO export.msk
DO find.bmp
DO find.msk
DO ffldr.ico
DO ffldr2.ico
DO fofldr.ico
DO fofldr2.ico
DO folder.ico
DO folder2.ico
DO c:\dev\browser\forms.ico
DO frm.ico
DO forward.bmp
DO forward.msk
DO gallery.bmp
DO gallery.ico
DO gallery.msk
DO help.bmp
DO help.msk
DO hyprlink.ico
DO image.ico
DO instance.ico
DO item.ico
DO labels.ico
DO lbl.ico
DO leaf.bmp
DO lgicview.bmp
DO line.ico
DO listbox.ico
DO listview.bmp
DO menus.ico
DO method.ico
DO methodc.ico
DO methodh.ico
DO oclosed.bmp
DO ole.ico
DO olebound.ico
DO oopen.bmp
DO open.bmp
DO open.msk
DO openfldr.ico
DO openfld2.ico
DO openctlg.ico
DO openctl2.ico
DO optionb.ico
DO optiong.ico
DO options.bmp
DO options.msk
DO othrfile.ico
DO page.ico
DO page.msk
DO pagefrm.ico
DO pclsbrw.bmp
DO pclsbrw.msk
DO pfldr.ico
DO pfldr2.ico
DO pofldr.ico
DO pofldr2.ico
DO programs.ico
DO projhook.ico
DO prop.ico
DO propc.ico
DO proph.ico
DO pushb.ico
DO queries.ico
DO redefine.bmp
DO redefine.msk
DO refresh.bmp
DO refresh.msk
DO relation.ico
DO relation.msk
DO reportlistener.ico
DO reportlistener.msk
DO rename.bmp
DO rename.msk
DO reports.ico
DO sep.ico
DO shape.ico
DO smicview.bmp
DO spinner.ico
DO stop.bmp
DO stop.msk
DO table.ico
DO text.ico
DO textbox.ico
DO timer.ico
DO toolbar.ico
DO toolbox.ico
DO uplevel.bmp
DO uplevel.msk
DO web_doc.ico
DO web_file.ico
DO web_site.ico
DO xmladapter.ico
DO xmladapter.msk
DO xmlfield.ico
DO xmlfield.msk
DO xmltable.ico
DO xmltable.msk
SET PROCEDURE TO formset.ico
SET PROCEDURE TO formpg.ico
DO control.cur
DO dragcopy.cur
DO nodrop.cur
DO dragmove.cur
DO dragit.cur
DO control.crm
DO dragcopy.crm
DO nodrop.crm
DO dragmove.crm
RETURN



FUNCTION brwGetDataType(lnType)
DO CASE
	CASE TYPE("lnType")#"N"
		RETURN "UNKNOWN"
	CASE lnType=1
		RETURN "VT_NULL"
	CASE lnType=2
		RETURN "INTEGER"
	CASE lnType=3
		RETURN "INTEGER"
	CASE lnType=4
		RETURN "VT_R4"
	CASE lnType=5
		RETURN "VT_R8"
	CASE lnType=6
		RETURN "VT_CY"
	CASE lnType=7
		RETURN "DATE"
	CASE lnType=8
		RETURN "STRING"
	CASE lnType=9
		RETURN "VT_DISPATCH"
	CASE lnType=10
		RETURN "VT_ERROR"
	CASE lnType=11
		RETURN "BOOLEAN"
	CASE lnType=12
		RETURN "VARIANT"
	CASE lnType=13
		RETURN "VT_UNKNOWN"
	CASE lnType=16
		RETURN "VT_I1"
	CASE lnType=17
		RETURN "VT_UI1"
	CASE lnType=18
		RETURN "VT_UI2"
	CASE lnType=19
		RETURN "VT_UI4"
	CASE lnType=20
		RETURN "VT_I8"
	CASE lnType=21
		RETURN "VT_UI8"
	CASE lnType=22
		RETURN "VT_INT"
	CASE lnType=23
		RETURN "VT_UINT"
	CASE lnType=24
		RETURN "VT_VOID"
	CASE lnType=25
		RETURN "VT_HRESULT"
	CASE lnType=26
		RETURN "VT_PTR"
	CASE lnType=27
		RETURN "VT_SAFEARRAY"
	CASE lnType=28
		RETURN "VT_CARRAY"
	CASE lnType=29
		RETURN "VT_USERDEFINED"
	CASE lnType=30
		RETURN "VT_LPSTR"
	CASE lnType=31
		RETURN "VT_LPWSTR"
	CASE lnType=64
		RETURN "VT_FILETIME"
	CASE lnType=65
		RETURN "VT_BLOB"
	CASE lnType=66
		RETURN "VT_STREAM"
	CASE lnType=67
		RETURN "VT_STORAGE"
	CASE lnType=68
		RETURN "VT_STREAMED_OBJECT"
	CASE lnType=69
		RETURN "VT_STORED_OBJECT"
	CASE lnType=70
		RETURN "VT_BLOB_OBJECT"
	CASE lnType=71
		RETURN "VT_CF"
	CASE lnType=72
		RETURN "VT_CLSOD"
ENDCASE
RETURN "UNKNOWN"	
ENDFUNC



FUNCTION brwDisplayFileMenu(toBrowser,tlAddFile)
LOCAL lnMenuCount,lnBar,lcFileName,lcAlias,lcDesc,lcJustFileName,lnAtPos
LOCAL laMenu[1],laFiles[1]

IF toBrowser.lRelease
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
SET DATASESSION TO (toBrowser.DataSessionID)
lcAlias=LOWER(SYS(2015))
IF USED(lcAlias)
	USE IN (lcAlias)
ENDIF
IF toBrowser.lBrowser
	SELECT Name,Desc FROM browser ;
			WHERE NOT DELETED() AND NOT Global AND ;
					UPPER(ALLTRIM(Platform))==toBrowser.cPlatform AND ;
					NOT LOWER(RIGHT(Name,4))==".dbf" AND ;
					UPPER(ALLTRIM(Type))=="PREFW" AND ;
					UPPER(ALLTRIM(ID))=="FORMINFO" AND NOT EMPTY(Name) ;
			ORDER BY Updated DESC ;
			INTO CURSOR (lcAlias)
ELSE
	SELECT Name,Desc FROM browser ;
			WHERE NOT DELETED() AND NOT Global AND ;
					UPPER(ALLTRIM(Platform))==toBrowser.cPlatform AND ;
					LOWER(RIGHT(Name,4))==".dbf" AND ;
					UPPER(ALLTRIM(Type))=="PREFW" AND ;
					UPPER(ALLTRIM(ID))=="FORMINFO" AND NOT EMPTY(Name) ;
			ORDER BY Updated DESC ;
			INTO CURSOR (lcAlias)
ENDIF
lnMenuCount=0
SCAN REST
	IF ":"$Name OR "\\"$Name
		lcFileName=LOWER(ALLTRIM(Name))
	ELSE
		lcFileName=LOWER(FULLPATH(ALLTRIM(Name)))
	ENDIF
	IF toBrowser.lBrowser
		IF tlAddFile AND ASCAN(toBrowser.aFiles,lcFileName)>0
			LOOP
		ENDIF
	ENDIF
	lcDesc=ALLTRIM(MLINE(Desc,1))
	IF EMPTY(lcDesc)
		lcDesc=lcFileName
	ENDIF
	IF LEN(lcDesc)>64
		lnAtPos=RAT("\",lcDesc)
		IF lnAtPos<=3
			lcDesc=ALLTRIM(LEFT(lcDesc,61))
		ELSE
			lcJustFileName=JUSTFNAME(lcDesc)
			lnAtPos=RAT("\",LEFT(lcDesc,61-LEN(lcJustFileName)))
			IF lnAtPos>0
				lcDesc=ALLTRIM(LEFT(lcDesc,lnAtPos))+"\...\"+lcJustFileName
			ELSE
				lcDesc=lcJustFileName
			ENDIF
		ENDIF
	ENDIF
	lnMenuCount=lnMenuCount+1
	DIMENSION laMenu[lnMenuCount],laFiles[lnMenuCount]
	laMenu[lnMenuCount]=lcDesc
	laFiles[lnMenuCount]=lcFileName
	IF lnMenuCount>=toBrowser.nHistoryMaxLength
		EXIT
	ENDIF
ENDSCAN
USE
SELECT 0
SET MESSAGE TO
IF lnMenuCount=0
	RETURN
ENDIF
toBrowser.lModalDialog=.T.
toBrowser.ShowMenu(@laMenu)
lnBar=BAR()
toBrowser.DeactivateMenu
toBrowser.lModalDialog=.F.
IF lnBar=0
	RETURN
ENDIF
lcFileName=laFiles[lnBar]
IF tlAddFile
	toBrowser.AddFile(lcFileName)
ELSE
	IF toBrowser.lBrowser
		toBrowser.OpenFile(lcFileName)
	ELSE
		toBrowser.OpenFile(lcFileName,toBrowser.lAddFileDefault)
	ENDIF
ENDIF
ENDFUNC



FUNCTION brwDisplayHistoryMenu(toBrowser)
LOCAL lnBar,lcPrompt,lcItem,lcFileName,lcMember,llBrowser,llFound
LOCAL lnAtPos,lcAlias,lnCount,lcCount
LOCAL laMenu[1]

IF toBrowser.lRelease OR toBrowser.nHistoryCount<1
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
SET DATASESSION TO (toBrowser.DataSessionID)
FOR lnCount= 1 TO toBrowser.nHistoryCount
	IF lnCount>toBrowser.nHistoryMaxLength
		EXIT
	ENDIF
	lcItem=toBrowser.aHistory[lnCount,1]
	DIMENSION laMenu[lnCount]
	laMenu[lnCount]=toBrowser.aHistory[lnCount,1]
ENDFOR
SET MESSAGE TO
toBrowser.lModalDialog=.T.
toBrowser.ShowMenu(@laMenu)
lnBar=BAR()
toBrowser.DeactivateMenu
toBrowser.lModalDialog=.F.
IF lnBar=0
	RETURN
ENDIF
lcItem=toBrowser.aHistory[lnBar,2]
lcFileName=toBrowser.aHistory[lnBar,3]
llBrowser=toBrowser.aHistory[lnBar,4]
IF toBrowser.lBrowser#llBrowser
	toBrowser.SwitchBrowser
ENDIF
llFound=.T.
IF llBrowser
	IF NOT EMPTY(lcFileName) AND FILE(lcFileName) AND ASCAN(toBrowser.aFiles,lcFileName)=0
		llFound=toBrowser.AddFile(lcFileName)
	ENDIF
	IF llFound
		lnAtPos=AT("::",lcItem)
		IF lnAtPos=0
			lcMember=""
		ELSE
			lcMember=ALLTRIM(SUBSTR(lcItem,lnAtPos+2))
			lcItem=ALLTRIM(LEFT(lcItem,lnAtPos-1))
		ENDIF
		llFound=toBrowser.SeekClass(lcItem)
		IF llFound
			IF EMPTY(lcMember)
				toBrowser.oleClassList.SetFocus
			ELSE
				llFound=toBrowser.SeekMember(lcMember)
				IF llFound
					toBrowser.oleMembers.SetFocus
				ENDIF
			ENDIF
		ENDIF
	ENDIF
ELSE
	IF NOT EMPTY(lcFileName) AND FILE(lcFileName)
		llFound=.F.
		FOR lnCount = 1 TO 256
			lcCount=ALLTRIM(STR(lnCount))
			lcAlias="catalog"+lcCount
			IF USED(lcAlias) AND LOWER(DBF(lcAlias))==lcFileName
				llFound=.T.
				EXIT
			ENDIF
		ENDFOR
		IF NOT llFound
			llFound=toBrowser.AddFile(lcFileName)
			IF llFound
				toBrowser.oleFolderList.SetFocus
			ENDIF
		ENDIF
	ENDIF
	IF llFound
		llFound=toBrowser.SelectItem(lcItem,.T.)
	ENDIF
ENDIF
IF NOT llFound
	WITH toBrowser
		ADEL(.aHistory,lnBar)
		.nHistoryCount=.nHistoryCount-1
		DIMENSION .aHistory[.nHistoryCount,4]
	ENDWITH
	WAIT CLEAR
	WAIT WINDOW M_MATCH_NOT_FOUND_LOC NOWAIT
ENDIF
toBrowser.vResult=llFound
RETURN toBrowser.vResult
ENDFUNC



FUNCTION brwDisplayMenu(toBrowser,tnMenuMode)
LOCAL lnMenuMode,lnMenuCount,lnMenuEndCount,lnMenuOffset,lnBar,lcMarker
LOCAL lcMemberType,lcMember,lcToMember
LOCAL laMenu[1]

IF toBrowser.lRelease
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
toBrowser.DeactivateMenu
lnMenuMode=IIF(TYPE("tnMenuMode")=="N",tnMenuMode,0)
lnMenuEndCount=5
lnMenuOffset=0
DO CASE
	CASE NOT toBrowser.lBrowser
		lnMenuMode=3
		lnMenuCount=10+lnMenuEndCount
		lnMenuOffset=5
	CASE lnMenuMode=1
		lnMenuCount=15+lnMenuEndCount
	CASE lnMenuMode=2
		lnMenuCount=11+lnMenuEndCount
	OTHERWISE
		lnMenuMode=0
		lnMenuCount=15+lnMenuEndCount
ENDCASE
DIMENSION laMenu[lnMenuCount]
laMenu=""
lcMarker="^"
laMenu[1]=B_DESCRIPTIONS1_LOC
IF toBrowser.lDescriptions
	laMenu[1]=lcMarker+laMenu[1]
ENDIF
laMenu[2]=B_ALWAYSONTOP1_LOC
IF toBrowser.AlwaysOnTop
	laMenu[2]=lcMarker+laMenu[2]
ENDIF
laMenu[3]=B_AUTOEXPAND1_LOC
IF toBrowser.lAutoExpand
	laMenu[3]=lcMarker+laMenu[3]
ENDIF
laMenu[4]=B_PARENTCLASSTB1_LOC
IF toBrowser.lParentClassBrowser
	laMenu[4]=lcMarker+laMenu[4]
ENDIF
laMenu[5]=B_RESTOREDEFAULTS1_LOC
IF lnMenuMode<3
	laMenu[6]="\-"
	laMenu[7]=B_HIERARCHICAL1_LOC
	IF toBrowser.nDisplayMode=1
		laMenu[7]=lcMarker+laMenu[7]
	ENDIF
	laMenu[8]=B_PROTECTED1_LOC
	IF toBrowser.lProtectedFilter
		laMenu[8]=lcMarker+laMenu[8]
	ENDIF
	laMenu[9]=B_HIDDEN1_LOC
	IF toBrowser.lHiddenFilter
		laMenu[9]=lcMarker+laMenu[9]
	ENDIF
	laMenu[10]=B_EMPTY1_LOC
	IF toBrowser.lEmptyFilter
		laMenu[10]=lcMarker+laMenu[10]
	ENDIF
ENDIF
DO CASE
	CASE lnMenuMode=0 OR lnMenuMode=3
		laMenu[11-lnMenuOffset]="\-"
		laMenu[12-lnMenuOffset]=B_FONT1_LOC
		IF (toBrowser.lBrowser AND toBrowser.lVCXSCXMode) OR ;
				(NOT toBrowser.lBrowser AND toBrowser.nFolderCount>0)
			laMenu[13-lnMenuOffset]=B_EXPORT1_LOC
		ELSE
			laMenu[13-lnMenuOffset]=B_EXPORT2_LOC
		ENDIF
		laMenu[14-lnMenuOffset]=B_ADDINS1_LOC
	CASE lnMenuMode=1
		laMenu[11]="\-"
		IF NOT toBrowser.lSCXMode
			laMenu[12]=B_MODIFY1_LOC
		ELSE
			laMenu[12]=B_MODIFY2_LOC
		ENDIF

		IF !toBrowser.lPRGMode
			IF NOT toBrowser.lReadOnly AND NOT toBrowser.lSCXMode
				laMenu[13]=B_CONTAINERICON1_LOC
			ELSE
				laMenu[13]=B_CONTAINERICON2_LOC
			ENDIF
		ELSE
			laMenu[13]=B_CONTAINERICON2_LOC
		ENDIF
		
		IF !toBrowser.lPRGMode
			IF NOT toBrowser.lReadOnly AND NOT toBrowser.lSCXMode
				laMenu[14]=B_REMOVE1_LOC
			ELSE
				laMenu[14]=B_REMOVE2_LOC
			ENDIF
		ELSE
			laMenu[14]=B_REMOVE2_LOC
		ENDIF

		IF !toBrowser.lPRGMode
			IF NOT "."$toBrowser.cClass
				lnMenuCount=lnMenuCount+4
				DIMENSION laMenu[lnMenuCount]
				IF NOT toBrowser.lReadOnly AND NOT toBrowser.lSCXMode
					laMenu[15]=B_RENAME1_LOC
				ELSE
					laMenu[15]=B_RENAME2_LOC
				ENDIF
				IF NOT toBrowser.lReadOnly
					laMenu[16]=B_REDEFINE1_LOC
				ELSE
					laMenu[16]=B_REDEFINE2_LOC
				ENDIF
				IF NOT EMPTY(toBrowser.aClassList[toBrowser.nClassListIndex+1,5]) AND ;
						NOT toBrowser.aClassList[toBrowser.nClassListIndex+1,5]== ;
						toBrowser.aClassList[toBrowser.nClassListIndex+1,8]
					laMenu[lnMenuCount-lnMenuEndCount-2]=B_SELECTPARENTCLASS1_LOC
				ELSE
					laMenu[lnMenuCount-lnMenuEndCount-2]=B_SELECTPARENTCLASS2_LOC
				ENDIF
				IF NOT toBrowser.lReadOnly AND NOT toBrowser.lSCXMode
					laMenu[lnMenuCount-lnMenuEndCount-1]=B_OLEPUBLIC1_LOC
				ELSE
					laMenu[lnMenuCount-lnMenuEndCount-1]=B_OLEPUBLIC2_LOC
				ENDIF
				IF toBrowser.aClassList[toBrowser.nClassListIndex+1,9]
					laMenu[lnMenuCount-lnMenuEndCount-1]=lcMarker+ ;
							laMenu[lnMenuCount-lnMenuEndCount-1]
				ENDIF
			ENDIF
		ELSE
			laMenu[15]=B_RENAME2_LOC
			laMenu[16]=B_REDEFINE2_LOC
		ENDIF
		
	CASE lnMenuMode=2
		WITH toBrowser
			lcMember=.aMemberList[.nMemberListIndex,1]
			lcMemberType=.aMemberList[.nMemberListIndex,2]
		ENDWITH
		DO CASE
			CASE lcMemberType=="o"
				lnMenuCount=lnMenuCount+2
				DIMENSION laMenu[lnMenuCount]
				laMenu[11]="\-"
				IF EMPTY(toBrowser.cLastValue) OR NOT ","$toBrowser.cLastValue
					laMenu[12]=B_SELECTCLASS2_LOC
				ELSE
					laMenu[12]=B_SELECTCLASS1_LOC
				ENDIF
			CASE lcMemberType=="m" OR lcMemberType=="p"
				lnMenuCount=lnMenuCount+3
				DIMENSION laMenu[lnMenuCount]
				laMenu[11]="\-"
				IF lcMemberType=="m"
					laMenu[12]=B_MODIFY1_LOC
				ELSE
					laMenu[12]=B_VIEW1_LOC
				ENDIF
				IF !toBrowser.lPRGMode
					IF NOT toBrowser.lReadOnly AND NOT toBrowser.lSCXMode
						laMenu[13]=B_RENAME1_LOC
					ELSE
						laMenu[13]=B_RENAME2_LOC
					ENDIF
				ENDIF
		ENDCASE
ENDCASE
laMenu[lnMenuCount-5]="\-"
laMenu[lnMenuCount-4]=B_NEWWINDOW1_LOC
IF toBrowser.lBrowser
	laMenu[lnMenuCount-3]=B_NEWCG1_LOC
ELSE
	laMenu[lnMenuCount-3]=B_NEWCB1_LOC
ENDIF
laMenu[lnMenuCount-2]=B_REFRESH1_LOC
laMenu[lnMenuCount-1]="\-"
laMenu[lnMenuCount]=B_HELP1_LOC
toBrowser.lModalDialog=.T.
toBrowser.ShowMenu(@laMenu)
lnBar=BAR()
toBrowser.DeactivateMenu
toBrowser.lModalDialog=.F.
IF lnBar=0
	RETURN
ENDIF
IF lnMenuMode=3 AND (lnBar+lnMenuOffset)>=12
	lnBar=lnBar+lnMenuOffset
	lnMenuCount=lnMenuCount+lnMenuOffset
ENDIF
DO CASE
	CASE lnBar=lnMenuCount
		IF lnMenuMode=2 AND NOT toBrowser.lVCXSCXMode AND toBrowser.nMemberListIndex>=1
			toBrowser.nMouseButton=1
			IF toBrowser.lOutlineOCX
				toBrowser.oleMembers.DblClick
			ELSE
				toBrowser.lstMembers.DblClick
			ENDIF
		ELSE
			toBrowser.Help
		ENDIF
	CASE lnBar=(lnMenuCount-2)
		toBrowser.RefreshBrowser
	CASE lnBar=(lnMenuCount-3)
		toBrowser.StartNewWindow(toBrowser.lBrowser)
	CASE lnBar=(lnMenuCount-4)
		toBrowser.StartNewWindow(NOT toBrowser.lBrowser)
	CASE lnBar=1
		toBrowser.lDescriptions=(NOT toBrowser.lDescriptions)
		toBrowser.RefreshDescriptions
		toBrowser.SavePreferences
	CASE lnBar=2
		toBrowser.AlwaysOnTop=(NOT toBrowser.AlwaysOnTop)
		toBrowser.SavePreferences
	CASE lnBar=3
		toBrowser.lAutoExpand=(NOT toBrowser.lAutoExpand)
		toBrowser.RefreshBrowser
		toBrowser.SavePreferences
	CASE lnBar=4
		toBrowser.lParentClassBrowser=(NOT toBrowser.lParentClassBrowser)
		toBrowser.RefreshParentClassBrowser
		toBrowser.SavePreferences
	CASE lnBar=5
		toBrowser.ResetDefaults
	CASE lnBar=7
		toBrowser.DisplayMode(IIF(toBrowser.nDisplayMode=1,2,1))
		toBrowser.SavePreferences
	CASE lnBar=8
		toBrowser.lProtectedFilter=(NOT toBrowser.lProtectedFilter)
		toBrowser.RefreshMembers
		toBrowser.SavePreferences
	CASE lnBar=9
		toBrowser.lHiddenFilter=(NOT toBrowser.lHiddenFilter)
		toBrowser.RefreshMembers
		toBrowser.SavePreferences
	CASE lnBar=10
		toBrowser.lEmptyFilter=(NOT toBrowser.lEmptyFilter)
		toBrowser.RefreshMembers
		toBrowser.SavePreferences
	CASE lnBar=12
		DO CASE
			CASE lnMenuMode=0 OR lnMenuMode=3
				toBrowser.SetFont
			CASE lnMenuMode=1
				toBrowser.ModifyClass
			CASE lnMenuMode=2
				DO CASE
					CASE lcMemberType=="o"
						toBrowser.nMouseButton=1
						IF toBrowser.lOutlineOCX
							toBrowser.oleMembers.DblClick
						ELSE
							toBrowser.lstMembers.DblClick
						ENDIF
					CASE lcMemberType=="p"
						toBrowser.ViewProperty(lcMember)
					CASE lcMemberType=="m"
						toBrowser.ModifyClass(lcMember)
				ENDCASE
		ENDCASE
	CASE lnBar=13
		DO CASE
			CASE lnMenuMode=0 OR lnMenuMode=3
				IF toBrowser.lBrowser
	 				toBrowser.ExportClass(.T.,"")
	 			ELSE
	 				toBrowser.ExportView
 				ENDIF
			CASE lnMenuMode=1
				toBrowser.cmdClassIcon.RightClick
			CASE lnMenuMode=2
				toBrowser.RenameMember
		ENDCASE
	CASE lnBar=14
		DO CASE
			CASE lnMenuMode=0 OR lnMenuMode=3
				toBrowser.AddInMenu
			CASE lnMenuMode=1
				toBrowser.RemoveClass(.T.)
		ENDCASE
	CASE lnBar=15
		DO CASE
			CASE lnMenuMode=1
				toBrowser.RenameClass
		ENDCASE
	CASE lnBar=16
		DO CASE
			CASE lnMenuMode=1
				toBrowser.RedefineClass
		ENDCASE
	CASE lnBar=(lnMenuCount-lnMenuEndCount-2)
		DO CASE
			CASE lnMenuMode=1
				toBrowser.SeekParentClass
		ENDCASE
	CASE lnBar=(lnMenuCount-lnMenuEndCount-1)
		DO CASE
			CASE lnMenuMode=1
				SET MESSAGE TO M_UPDATING_OLEPUBLIC_LOC+" ..."
				SELECT (toBrowser.cAlias)
				LOCATE FOR UPPER(ALLTRIM(Platform))=="COMMENT" AND ;
						LOWER(ALLTRIM(ObjName))==toBrowser.cClass
				IF NOT EOF()
					IF toBrowser.aClassList[toBrowser.nClassListIndex+1,9]
						REPLACE Reserved2 WITH ""
					ELSE
						REPLACE Reserved2 WITH "OLEPublic"
					ENDIF
					toBrowser.RefreshBrowser
				ENDIF
				SELECT 0
				SET MESSAGE TO
		ENDCASE
	OTHERWISE
		RETURN
ENDCASE
ENDFUNC



FUNCTION brwRefreshCaption(toBrowser)
LOCAL lcCaption,lcMember,lcHistoryItem

IF toBrowser.lRelease
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
lcCaption=""
DO CASE
	CASE toBrowser.lBrowser AND toBrowser.nClassListIndex<0
		lcCaption=T_CLASS_BROWSER_LOC
	CASE NOT toBrowser.lBrowser AND toBrowser.nFolderCount<1
		lcCaption=T_COMPONENT_GALLERY_LOC
	CASE toBrowser.lBrowser
		WITH toBrowser
			lcHistoryItem=.cClass
			IF NOT EMPTY(.cFileName)
				lcCaption=JUSTFNAME(.cFileName)
			ENDIF
			IF .nMemberListIndex>=1
				lcMember=.aMemberList[.nMemberListIndex,1]
				lcHistoryItem=lcHistoryItem+"::"+lcMember
				IF .lFileMode
					lcCaption=lcCaption+" ("+lcMember+")"
				ELSE
					lcCaption=lcCaption+" ("+.cClass
					IF NOT EMPTY(lcMember)
						lcCaption=lcCaption+"::"+lcMember
					ENDIF
					lcCaption=lcCaption+")"
				ENDIF
			ELSE
				IF .lFileMode
					lcCaption=lcCaption+" ("+.cFileName+")"
				ELSE
					lcCaption=lcCaption+" ("+.cClass+")"
				ENDIF
			ENDIF
			lcCaption=lcCaption+" - "+T_CLASS_BROWSER_LOC
			IF .lReadOnly
				lcCaption=lcCaption+" ["+M_READ_ONLY_LOC+"]"
			ENDIF
			.AddHistoryItem(lcHistoryItem,lcHistoryItem,.cFileName)
		ENDWITH
	OTHERWISE
		WITH toBrowser
			IF NOT ISNULL(.oCatalogSource)
				lcCaption=.oCatalogSource.cText
				IF NOT ISNULL(.oFolderSource) AND NOT .oItemSource.cID==.oCatalogSource.cID
					lcCaption=lcCaption+" ("+ALLTRIM(.oFolderSource.cText)
					IF NOT ISNULL(.oItemSource) AND NOT .oItemSource.cID==.oFolderSource.cID
						lcCaption=lcCaption+"::"+ALLTRIM(.oItemSource.cText)
					ENDIF
					lcCaption=lcCaption+")"
				ENDIF
			ENDIF
			.AddHistoryItem(.oItem.cText,.oItem.cID,IIF(.nViewType=1,.oItem.cCatalog,""))
		ENDWITH
		lcCaption=lcCaption+" - "+T_COMPONENT_GALLERY_LOC
ENDCASE
IF toBrowser.Caption==lcCaption
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
toBrowser.Caption=lcCaption
IF toBrowser.AddInMethod("REFRESHCAPTION")
	RETURN
ENDIF
ENDFUNC



FUNCTION brwOpenCatalog(toBrowser,tcFileDesc,tlAddMode)

toBrowser.vResult=toBrowser.OpenFile(tcFileDesc,tlAddMode)
RETURN toBrowser.vResult
ENDFUNC



FUNCTION brwOpenFile(toBrowser,tcFileName,tlAddMode,tlIgnoreRefresh)
LOCAL lcFileName,lcFileName2,llAddMode,lcFilter,lcClass,lcName,lnFileNo
LOCAL llRefreshClassList,lnCount,lcCount,lcAlias,lcAlias2,lcKeywordsDBF
LOCAL lnFileCount,lnFileOpenCount,oOpenCatalogForm,llIgnoreErrors
LOCAL lcSelectFileName,oFolder,oFolder2
LOCAL oPRGToVcx
LOCAL laFiles[1],laFilesOpen[1]

IF toBrowser.lRelease
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
SET DATASESSION TO toBrowser.DataSessionID
llAddMode=tlAddMode
llRefreshClassList=.F.
IF toBrowser.lInitialized
	toBrowser.SavePreferences(,NOT toBrowser.lBrowser)
ENDIF
DO WHILE .T.
	IF EMPTY(tcFileName) OR TYPE("tcFileName")#"C"
		SELECT 0
		SET MESSAGE TO
		IF toBrowser.lBrowser
			lcFileName=toBrowser.GetFile()
		ELSE
			toBrowser.lModalDialog=.T.
			DO FORM cgopncat NAME oOpenCatalogForm ;
					WITH toBrowser TO lcFileName
			SET DATASESSION TO toBrowser.DataSessionID
			IF LEFT(lcFileName,1)=="+"
				lcFileName=LOWER(ALLTRIM(SUBSTR(lcFileName,2)))
				llAddMode=.T.
			ENDIF
		ENDIF
	ELSE
		lcFileName=LOWER(ALLTRIM(tcFileName))
		IF EMPTY(JUSTEXT(lcFileName))
			lcFileName=FORCEEXT(lcFileName,IIF(toBrowser.lBrowser,"vcx","dbf"))
		ENDIF
	ENDIF
	IF EMPTY(lcFileName)
		toBrowser.vResult=.F.
		RETURN toBrowser.vResult
	ENDIF
	lcSelectFileName=lcFileName
	IF NOT toBrowser.lBrowser
		IF EMPTY(JUSTEXT(lcFileName))
			lcFileName=FORCEEXT(lcFileName,"dbf")
		ENDIF
		IF NOT ":"$lcFileName AND NOT "\\"$lcFileName
			lcFileName=LOWER(FULLPATH(lcFileName))
		ENDIF
		IF NOT FILE(lcFileName)
			lcFileName=LOWER(FORCEPATH(lcFileName,toBrowser.cProgramPath+"gallery\"))
			IF NOT FILE(lcFileName)
				toBrowser.cCatalog=""
				SELECT 0
				SET MESSAGE TO
				toBrowser.MsgBox(M_FILE_LOC+[ "]+lcFileName+[" ]+M_DOES_NOT_EXIST_LOC+[.],16)
				toBrowser.vResult=.F.
				RETURN toBrowser.vResult
			ENDIF
		ENDIF
		IF llAddMode
			lcAlias2="catalog"
			FOR lnCount = 1 TO 256
				lcCount=ALLTRIM(STR(lnCount))
				lcAlias=lcAlias2+lcCount
				IF NOT USED(lcAlias)
					EXIT
				ENDIF
				IF LOWER(DBF(lcAlias))==lcFileName
					SELECT 0
					RETURN
				ENDIF
			ENDFOR
		ENDIF
		toBrowser.CloseViews(.T.)
		lcAlias2="catalog"
		FOR lnCount = 1 TO 256
			lcCount=ALLTRIM(STR(lnCount))
			lcAlias=lcAlias2+lcCount
			IF NOT USED(lcAlias)
				EXIT
			ENDIF
			IF NOT llAddMode
				toBrowser.UpdateFormCount(-1,DBF(lcAlias))
				USE IN (lcAlias)
			ENDIF
		ENDFOR
		IF NOT llAddMode
			lnFileCount=0
			laFiles=""
			lnFileOpenCount=0
			laFilesOpen=""
			SELECT browser
			SCAN ALL FOR Global AND;
					UPPER(ALLTRIM(Platform))==toBrowser.cPlatform AND ;
					UPPER(ALLTRIM(Type))=="PREFW" AND ;
					UPPER(ALLTRIM(ID))=="FORMINFO" AND NOT EMPTY(Name)
				lcName=LOWER(ALLTRIM(MLINE(Name,1)))
				IF NOT (".dbf"$lcName)
					LOOP
				ENDIF
				IF NOT FILE(lcName)
					DELETE
					LOOP
				ENDIF
				lnFileCount=lnFileCount+1
				DIMENSION laFiles[lnFileCount]
				laFiles[lnFileCount]=IIF(Default," ","_")+TTOC(Updated)+lcName
			ENDSCAN
			SELECT 0
			FOR lnCount = 1 TO lnFileCount
				lcName=SUBSTR(laFiles[lnCount],22)
				IF lcName==lcFileName OR (lnFileOpenCount>0 AND ASCAN(laFilesOpen,lcName)>0)
					LOOP
				ENDIF
				lnFileOpenCount=lnFileOpenCount+1
				DIMENSION laFilesOpen[lnFileOpenCount]
				laFilesOpen[lnFileOpenCount]=lcName
				IF toBrowser.AddFile(lcName,.T.)
					llAddMode=.T.
				ENDIF
			ENDFOR
			SELECT 0
		ENDIF
		SET MESSAGE TO M_OPENING_FILE_LOC+[ "]+lcFileName+[" ...]
		IF toBrowser.lInitialized AND NOT llAddMode
			toBrowser.CloseViews(.T.)
			toBrowser.ClearBrowser
		ENDIF
		lcAlias2="catalog"
		lnCount=1
		DO WHILE .T.
			lcCount=ALLTRIM(STR(lnCount))
			lnCount=lnCount+1
			lcAlias=lcAlias2+lcCount
			IF NOT USED(lcAlias)
				EXIT
			ENDIF
		ENDDO
		IF NOT llAddMode
			lcCount="1"
			lcAlias=lcAlias2+lcCount
		ENDIF
		IF EMPTY(toBrowser.cGallery)
			toBrowser.cGallery=lcAlias
		ENDIF
		IF USED(lcAlias)
			toBrowser.UpdateFormCount(-1,DBF(lcAlias))
			USE IN (lcAlias)
		ENDIF
		SELECT 0
		llIgnoreErrors=toBrowser.lIgnoreErrors
		toBrowser.lIgnoreErrors=.T.
		SELECT 0
		USE (lcFileName) EXCLUSIVE ALIAS (lcAlias)
		IF USED()
			PACK MEMO
		ENDIF
		USE (lcFileName) AGAIN SHARED ALIAS (lcAlias)
		toBrowser.lIgnoreErrors=llIgnoreErrors
		IF NOT USED()
			toBrowser.MsgBox(M_UNABLE_TO_OPEN_LOC+[ "]+lcFileName+[".],16)
			toBrowser.cCatalog=""
			SELECT 0
			SET MESSAGE TO
			toBrowser.vResult=.F.
			RETURN toBrowser.vResult
		ENDIF
		toBrowser.cCatalog=lcFileName
		IF NOT toBrowser.VersionCheck(.T.)
			IF USED(lcAlias)
				USE IN (lcAlias)
			ENDIF
			toBrowser.cCatalog=""
			SELECT 0
			SET MESSAGE TO
			toBrowser.vResult=.F.
			RETURN toBrowser.vResult
		ENDIF
		SET FILTER TO NOT DELETED()
		LOCATE
		IF EMPTY(toBrowser.cDefaultCatalog)
			toBrowser.cDefaultCatalog=lcFileName
			toBrowser.cDefaultCatalogPath=IIF(EMPTY(lcFileName),"",JUSTPATH(lcFileName)+"\")
		ENDIF
		REPLACE ALL SrcAlias WITH LOWER(ALIAS()), SrcRecNo WITH RECNO()
		toBrowser.UpdateFormCount(1,lcFileName)
		WITH toBrowser
			.cGallery=lcAlias
			lcAlias2="view_default"
			.ClearProperties
			IF USED("catalog1")
				SELECT catalog1
				lcFileName=LOWER(DBF())
				.RefreshPrefRecNo
			ENDIF
		ENDWITH
		IF NOT USED("keywords")
			lcKeywordsDBF=toBrowser.cDefaultCatalogPath+"keywords.dbf"
			SELECT 0
			IF NOT FILE(lcKeywordsDBF)
				CREATE TABLE (lcKeywordsDBF) (Keyword C(30))
			ENDIF
			USE (lcKeywordsDBF) AGAIN SHARED ALIAS keywords
			IF NOT LOWER(KEY(1))=="keyword"
				USE (lcKeywordsDBF) AGAIN EXCLUSIVE ALIAS keywords
				INDEX ON Keyword TAG Keyword
				USE (lcKeywordsDBF) AGAIN SHARED ALIAS keywords
			ENDIF
			SET ORDER TO Keyword
			LOCATE
			SELECT 0
		ENDIF
		SELECT 0
		WITH toBrowser
			IF .lInitialized AND NOT tlIgnoreRefresh
				.RefreshBrowser
				oFolder=.NULL.
				IF NOT EMPTY(lcSelectFileName)
					FOR lnCount = 1 TO .nFolderCount
						oFolder2=.aFolderList[lnCount]
						IF ISNULL(oFolder2) OR NOT oFolder2.lFolder
							LOOP
						ENDIF
						WITH oFolder2
							IF LOWER(ALLTRIM(.cCatalog))==lcSelectFileName
								oFolder=oFolder2
								IF oFolder.lDeleted
									oFolder=.NULL.
								ENDIF
								EXIT
							ENDIF
						ENDWITH
					ENDFOR
					oFolder2=.NULL.
					IF NOT ISNULL(oFolder)
						.SelectFolder(oFolder)
					ENDIF
				ENDIF
				SET MESSAGE TO
			ENDIF
		ENDWITH
		RETURN
	ENDIF
	IF EMPTY(lcFileName)
		toBrowser.vResult=.F.
		RETURN toBrowser.vResult
	ENDIF
	IF lcFileName==toBrowser.cFileName AND toBrowser.nFileCount=1
		toBrowser.SeekClass("("+lcFileName+")")
		RETURN
	ENDIF
	IF FILE(lcFileName) OR toBrowser.NewFile(lcFileName)
		EXIT
	ENDIF
	IF NOT ":"$lcFileName AND NOT "\\"$lcFileName
		lcFileName=LOWER(FULLPATH(lcFileName))
	ENDIF
	IF NOT FILE(lcFileName)
		SELECT 0
		SET MESSAGE TO
		toBrowser.MsgBox(M_FILE_LOC+[ "]+lcFileName+[" ]+M_DOES_NOT_EXIST_LOC+[.],16)
		toBrowser.cFileName=""
		toBrowser.vResult=.F.
		RETURN toBrowser.vResult
	ENDIF
ENDDO
IF RIGHT(lcFileName,4)==".pjx"
	IF USED("_tempproject")
		USE IN _tempproject
	ENDIF
	USE (lcFileName) AGAIN SHARED ALIAS _tempproject
	IF NOT USED()
		toBrowser.cFileName=""
		toBrowser.MsgBox(M_UNABLE_TO_OPEN_LOC+[ "]+lcFileName+[".],16)
		SELECT 0
		SET MESSAGE TO
		toBrowser.vResult=.F.
		RETURN toBrowser.vResult
	ENDIF
	SET FILTER TO NOT DELETED()
	LOCATE
	SCAN ALL FOR Type=="V" OR Type=="K" OR Type == "P"
		llRefreshClassList=.T.
		lcFileName2=LOWER(ALLTRIM(STRTRAN(MLINE(Name,1),CHR(0),"")))
		IF NOT ":"$lcFileName2 AND NOT "\\"$lcFileName2
			lcFileName2=LOWER(FULLPATH(lcFileName2,lcFileName))
		ENDIF
		IF llAddMode
			toBrowser.AddFile(lcFileName2,.T.)
		ELSE
			toBrowser.OpenFile(lcFileName2,.T.,.T.)
			llAddMode=.T.
		ENDIF
	ENDSCAN
	USE
	IF toBrowser.lInitialized AND llRefreshClassList
		toBrowser.RefreshBrowser
	ENDIF
	SELECT 0
	IF toBrowser.lInitialized 
		SET MESSAGE TO
	ENDIF
	RETURN
ENDIF
SET MESSAGE TO M_OPENING_FILE_LOC+[ "]+lcFileName+[" ...]
WITH toBrowser
	FOR lnFileNo = 1 TO .nFileCount
		lcFileName2=.aFiles[lnFileNo]
		IF EMPTY(lcFileName2)
			LOOP
		ENDIF
		lcAlias="metadata"+ALLTRIM(STR(ASCAN(.aFiles,lcFileName2)))
		IF USED(lcAlias)
			toBrowser.UpdateFormCount(-1,lcFileName2)
			USE IN (lcAlias)
		ENDIF
	ENDFOR
	IF NOT EMPTY(.cAlias) AND USED(.cAlias)
		USE IN (.cAlias)
	ENDIF
	IF .lInitialized
		.ClearBrowser
	ENDIF
	.nFileCount=1
	DIMENSION .aFiles[1]
	.aFiles[1]=lcFileName
	.cAlias="metadata1"
	lcClass=.cClass
	SELECT 0
	.cFileName=lcFileName
	.cFileNamePath=IIF(EMPTY(lcFileName),"",JUSTPATH(lcFileName)+"\")
	.nClassTimeStamp=0
	.cClass=""
	.lFileMode=.T.
	.RefreshFileAttrib
	.lSCXMode=(RIGHT(.cFileName,4)==".scx")
	.lPRGMode=(RIGHT(.cFileName,4)==".prg")
	.lVCXSCXMode=(.lSCXMode OR .lPRGMode OR RIGHT(.cFileName,4)==".vcx")
ENDWITH
IF toBrowser.lVCXSCXMode
	*** Changed by RMK 
	IF toBrowser.lPRGMode
		* for PRG mode we need to convert the PRG file to a VCX cursor
		oPRGToVcx = NEWOBJECT("VCXWrapper", "VCXWrapper.prg")
		IF oPRGToVcx.ParsePRG(toBrowser.cFileName)
			oPRGToVcx.CreateVCXCursor(toBrowser.cAlias, .T.)
		ENDIF
	ELSE
		USE (toBrowser.cFileName) AGAIN SHARED ALIAS (toBrowser.cAlias)
	ENDIF
	
	IF NOT USED()
		toBrowser.MsgBox(M_UNABLE_TO_OPEN_LOC+[ "]+toBrowser.cFileName+[".],16)
		toBrowser.cFileName=""
		SELECT 0
		SET MESSAGE TO
		toBrowser.vResult=.F.
		RETURN toBrowser.vResult
	ENDIF
	IF NOT toBrowser.VersionCheck(.T.)
		toBrowser.cFileName=""
		IF USED(toBrowser.cAlias)
			USE IN (toBrowser.cAlias)
		ENDIF
		SELECT 0
		SET MESSAGE TO
		toBrowser.vResult=.F.
		RETURN toBrowser.vResult
	ENDIF
	CURSORSETPROP("Buffering",1)
	lcFilter=toBrowser.cFilter
	SET FILTER TO &lcFilter
	LOCATE
	SELECT 0
ENDIF
SELECT 0
IF toBrowser.lInitialized AND NOT tlIgnoreRefresh
	toBrowser.cClass="("+toBrowser.cFileName+")"
	toBrowser.RefreshBrowser
	SET MESSAGE TO
ENDIF
toBrowser.UpdateFormCount(1,toBrowser.cFileName)
ENDFUNC



FUNCTION brwAddFile(toBrowser,tcFileName,tlIgnoreRefresh)
LOCAL lcFileName,lcFilter,lcLastFileName,lcLastAlias
LOCAL lnFileCount,lnCount,llMatch,lnFileNo
LOCAL oPRGToVcx

IF toBrowser.lRelease
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
SET DATASESSION TO toBrowser.DataSessionID
IF NOT toBrowser.lBrowser
	RETURN toBrowser.OpenFile(tcFileName,.T.,tlIgnoreRefresh)
ENDIF
IF EMPTY(tcFileName)
	SELECT 0
	SET MESSAGE TO
	lcFileName=toBrowser.GetFile()
ELSE
	lcFileName=LOWER(tcFileName)
ENDIF
IF EMPTY(lcFileName)
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
lcFileName=ALLTRIM(lcFileName)
IF EMPTY(JUSTEXT(lcFileName))
	lcFileName=FORCEEXT(lcFileName,"vcx")
ENDIF
IF NOT ":"$lcFileName AND NOT "\\"$lcFileName
	lcFileName=LOWER(FULLPATH(lcFileName))
ENDIF
IF NOT FILE(lcFileName) AND NOT toBrowser.NewFile(lcFileName)
	SELECT 0
	SET MESSAGE TO
	toBrowser.MsgBox(M_FILE_LOC+[ "]+LOWER(FULLPATH(lcFileName,toBrowser.cProgramPath))+ ;
			[" ]+M_DOES_NOT_EXIST_LOC+[.],16)
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
IF ASCAN(toBrowser.aFiles,lcFileName)>0
	toBrowser.SeekClass("("+lcFileName+")")
	RETURN
ENDIF
IF RIGHT(lcFileName,4)==".pjx"
	toBrowser.OpenFile(lcFileName,.T.)
	RETURN
ENDIF
SET MESSAGE TO M_ADDING_FILE_LOC+[ "]+lcFileName+[" ...]
lnFileCount=toBrowser.nFileCount
lcLastFileName=toBrowser.cFileName
lcLastAlias=toBrowser.cAlias
FOR lnCount = 1 TO lnFileCount
	IF EMPTY(toBrowser.aFiles[lnCount])
		lnFileNo=lnCount
		llMatch=.T.
		EXIT
	ENDIF
ENDFOR
WITH toBrowser
	IF NOT llMatch
		.nFileCount=.nFileCount+1
		DIMENSION .aFiles[.nFileCount]
		lnFileNo=.nFileCount
	ENDIF
	.aFiles[lnFileNo]=lcFileName
	.cAlias="metadata"+ALLTRIM(STR(lnFileNo))
	IF NOT EMPTY(.cAlias) AND USED(.cAlias)
		USE IN (.cAlias)
	ENDIF
	SELECT 0
	.cFileName=lcFileName
	.cFileNamePath=IIF(EMPTY(lcFileName),"",JUSTPATH(lcFileName)+"\")
	.RefreshFileAttrib
	.lSCXMode=(RIGHT(lcFileName,4)==".scx")
	.lPRGMode=(RIGHT(lcFileName,4)==".prg")
	.lVCXSCXMode=(.lSCXMode OR .lPRGMode OR RIGHT(lcFileName,4)==".vcx")
ENDWITH
IF toBrowser.lVCXSCXMode
	*** Changed by RMK 
	IF toBrowser.lPRGMode
		* for PRG mode we need to convert the PRG file to a VCX cursor
		oPRGToVcx = NEWOBJECT("VCXWrapper", "VCXWrapper.prg")
		IF oPRGToVcx.ParsePRG(toBrowser.cFileName)
			oPRGToVcx.CreateVCXCursor(toBrowser.cAlias, .T.)
		ENDIF
	ELSE
		USE (toBrowser.cFileName) AGAIN SHARED ALIAS (toBrowser.cAlias)
	ENDIF

	IF NOT USED()
		WITH toBrowser
			.nFileCount=lnFileCount
			DIMENSION .aFiles[lnFileCount]
			.cFileName=lcLastFileName
			.cFileNamePath=IIF(EMPTY(lcLastFileName),"",JUSTPATH(lcLastFileName)+"\")
			.cAlias=lcLastAlias
			.RefreshFileAttrib
			.lSCXMode=(RIGHT(lcFileName,4)==".scx")
			.lPRGMode=(RIGHT(lcFileName,4)==".prg")
			.lVCXSCXMode=(.lSCXMode OR .lPRGMode OR RIGHT(lcFileName,4)==".vcx")
		ENDWITH
		toBrowser.vResult=.F.
		RETURN toBrowser.vResult
	ENDIF
	IF NOT toBrowser.VersionCheck(.T.)
		WITH toBrowser
			.nFileCount=lnFileCount
			DIMENSION .aFiles[lnFileCount]
			.cFileName=lcLastFileName
			.cFileNamePath=IIF(EMPTY(lcLastFileName),"",JUSTPATH(lcLastFileName)+"\")
			.cAlias=lcLastAlias
			.RefreshFileAttrib
			.lSCXMode=(RIGHT(.cFileName,4)==".scx")
			.lPRGMode=(RIGHT(.cFileName,4)==".prg")
			.lVCXSCXMode=(.lSCXMode OR .lPRGMode OR RIGHT(.cFileName,4)==".vcx")
		ENDWITH
		toBrowser.vResult=.F.
		RETURN toBrowser.vResult
	ENDIF
	CURSORSETPROP("Buffering",1)
	lcFilter=toBrowser.cFilter
	SET FILTER TO &lcFilter
	LOCATE
ELSE
	toBrowser.cClass="("+lcFileName+")"
ENDIF
IF NOT tlIgnoreRefresh
	IF toBrowser.lBrowser
		toBrowser.cClass="("+lcFileName+")"
	ENDIF
	toBrowser.RefreshBrowser
ENDIF
SELECT 0
IF toBrowser.lInitialized 
	SET MESSAGE TO
ENDIF
toBrowser.UpdateFormCount(1,lcFileName)
ENDFUNC



FUNCTION brwRefreshFolderList(toBrowser)
LOCAL oItem,lcCatalog,lnCount,llActive,lcClassLibrary,llLockScreen

IF toBrowser.lRelease OR toBrowser.lBrowser
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
SET DATASESSION TO toBrowser.DataSessionID
SELECT 0
SET MESSAGE TO M_REFRESH_FOLDER_LIST_LOC+" ("+toBrowser.cViewType+") ..."
WITH toBrowser
	IF USED(.cGallery)
		.cCatalog=LOWER(DBF(.cGallery))
	ENDIF
	lcCatalog=.cCatalog
	IF .lInitialized
		.ClearNodes(.oleFolderList)
		.nFolderCount=0
		.RefreshCaption
		.RefreshItemList
	ENDIF
ENDWITH
IF EMPTY(lcCatalog)
	SELECT 0
	SET MESSAGE TO
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
lcCatalog=toBrowser.cCatalog
IF EMPTY(lcCatalog)
	SELECT 0
	SET MESSAGE TO
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
SET MESSAGE TO M_REFRESH_FOLDER_LIST_LOC+" ("+toBrowser.cViewType+") ..."
lcClassLibrary=LOWER(ALLTRIM(toBrowser.cDefaultCatalogClassLibrary))
IF EMPTY(lcClassLibrary)
	toBrowser.cCatalog=""
	SELECT 0
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
IF NOT FILE(lcClassLibrary)
	lcClassLibrary=LOWER(FORCEPATH(lcClassLibrary,toBrowser.cProgramPath+"gallery\"))
	IF NOT FILE(lcClassLibrary)
		toBrowser.cCatalog=""
		IF USED(toBrowser.cGallery)
			USE IN (toBrowser.cGallery)
		ENDIF
		SELECT 0
		SET MESSAGE TO
		toBrowser.MsgBox(M_FILE_LOC+[ "]+lcClassLibrary+[" ]+M_DOES_NOT_EXIST_LOC+[.],16)
		toBrowser.vResult=.F.
		RETURN toBrowser.vResult
	ENDIF
	toBrowser.cDefaultCatalogClassLibrary=lcClassLibrary
ENDIF
WITH toBrowser
	.lError=.F.
	llActive=.lActive
	.lActive=.T.
	llLockScreen=.LockScreen
	.LockScreen=.T.
	IF NOT .lRefreshBrowserMode
		.oleFolderList.Enabled=.F.
		.oleFolderList.Visible=.F.
	ENDIF
	.RefreshObjects
ENDWITH
IF toBrowser.lRelease
	toBrowser.LockScreen=llLockScreen
	SELECT 0
	SET MESSAGE TO
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
IF TYPE("toBrowser.oleFolderList.object.Nodes[1].Selected")#"L"
	toBrowser.nFolderCount=0
ENDIF
IF toBrowser.nFolderListIndex<1 AND toBrowser.nFolderCount>0
	WITH toBrowser
		.nFolderListIndex=1
		.nLastFolderListIndex=-1
		.oleFolderList.object.Nodes[1].Selected=.T.
		.oCatalogSource=.aFolderList[1]
		.oCatalog=.oCatalogSource.oLink
		.oFolderSource=.oCatalogSource
		.oFolder=.oCatalog
		.oItemSource=.oFolderSource
		.oItem=.oFolder
		.cCatalog=.oItem.cSourceCatalog
	ENDWITH
ENDIF
WITH toBrowser
	.lError=.F.
	IF NOT .lRefreshBrowserMode
		.oleFolderList.Enabled=.T.
		.oleFolderList.Visible=.T.
	ENDIF
	.lActive=llActive
	.LockScreen=llLockScreen
ENDWITH
SELECT 0
SET MESSAGE TO
ENDFUNC



FUNCTION brwRefreshObjects(toBrowser,toFolder)
PRIVATE oTHIS
LOCAL llRefreshFolders,oNode,lcText,lcClass,lcItemClass,lcClassLibrary,lcItemType
LOCAL oParent,oFolder,oItem,lcItem,oObject,oView,lcCatalog,lcLastCatalog,lcCatalogPath
LOCAL lnType,lnIndex,lnImageIndex,lcKey,lcAlias,lcAlias2,lcDBF,lcID,lcID2,lcPicture
LOCAL lcFolderID,llIgnoreErrors,lnCount,lcCount,lnCount2,lnAtPos,lnAtPos2,llVisible
LOCAL lnViewType,lcViewType,lcViews,lcViewItem,lcViewAlias,lcViewCatalog,lcSourceAlias
LOCAL lnCatalogRecNo,lcCatalogID,lcProperties,lcLabel,lcProperty,lcWidth,lcValidExpr
LOCAL lcDesc,lcClassLib,lcItemClass,lcItemTypes,llReadOnly,llViewMode,llMenuItem
LOCAL lcGetFileExt,lcRowSource,lcScript,lnFolderCount,llMatch,oRecord
LOCAL lcMemLine,lnRecNo,llMaxFolderCountErrorMsg,lcType,lcLink
LOCAL laFolderID[1],laFolderText[1]

IF toBrowser.lRelease OR toBrowser.lBrowser
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
SET DATASESSION TO toBrowser.DataSessionID
llMaxFolderCountErrorMsg=.F.
lcCatalog=""
lcLastCatalog=" "
lnCatalogRecNo=0
lcCatalogID=""
oTHIS=.NULL.
oParent=.NULL.
oFolder=.NULL.
oNode=.NULL.
oItem=.NULL.
oRecord=.NULL.
oView=.NULL.
llRefreshFolders=(TYPE("toFolder")#"O" OR ISNULL(toFolder))
IF llRefreshFolders
	IF toBrowser.nFolderCount>0
		toBrowser.vResult=.F.
		RETURN toBrowser.vResult
	ENDIF
	lcFolderID=""
	lcViewCatalog=""
ELSE
	oFolder=toFolder
	toFolder=.NULL.
	oFolder.nItemCount=0
	IF toBrowser.nFolderCount<=0 
		toBrowser.vResult=.F.
		RETURN toBrowser.vResult
	ENDIF
	lcFolderID=oFolder.cID
	oParent=oFolder
	DO WHILE NOT oParent.cID==oParent.oFolder.cID
		oParent=oParent.oFolder
	ENDDO
	lcViewCatalog=LOWER(oParent.cCatalog)
	oParent=.NULL.
ENDIF
lcClassLibrary=toBrowser.cClassLibrary
IF NOT brwSetClassLibrary(toBrowser,toBrowser.cDefaultCatalogClassLibrary)
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
IF EMPTY(toBrowser.cGallery)
	toBrowser.cGallery="view_default"
ENDIF
lnViewType=toBrowser.nViewType
lcViewType=LOWER(ALLTRIM(toBrowser.cViewType))
IF llRefreshFolders
	lcAlias="view_default"
	IF USED(lcAlias)
		SELECT (lcAlias)
		ZAP
	ELSE
		toBrowser.CreateCatalog(lcAlias)
		IF NOT USED(lcAlias)
			toBrowser.vResult=.F.
			RETURN toBrowser.vResult
		ENDIF
	ENDIF
	SELECT (lcAlias)
	SET ORDER TO
	LOCATE
	lcAlias2="catalog"
	FOR lnCount = 1 TO 256
		lcCount=ALLTRIM(STR(lnCount))
		lcViewAlias=lcAlias2+lcCount
		IF NOT USED(lcViewAlias)
			LOOP
		ENDIF
		SELECT (lcAlias)
		APPEND FROM (DBF(lcViewAlias)) FOR NOT DELETED()
	ENDFOR
	INDEX ON UPPER(Type) TAG Type
ENDIF
lcAlias=LOWER(toBrowser.cGallery)
llViewMode=(llRefreshFolders AND lnViewType>1 AND LEFT(lcAlias,5)=="view_")
oView=toBrowser.oView
toBrowser.oView=.NULL.
IF llViewMode AND VARTYPE(oView)=="O" AND toBrowser.RefreshView(oView)=0
	oView.Release
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
IF llViewMode AND ISNULL(oView)
	SELECT (lcAlias)
	ZAP
	lnFolderCount=0
	DIMENSION laFolderID[1],laFolderText[1]
	laFolderID=""
	laFolderText=""
	lcCatalog=LOWER(SYS(2015))
	oNode=toBrowser.CreateNode(lcAlias,"FOLDER")
	WITH oNode
		.cID=lcCatalog
		.cText=toBrowser.cViewType
		.WriteProperties
	ENDWITH
	SELECT view_default
	SCAN ALL
		lcType=UPPER(ALLTRIM(Type))
		IF lcType=="OBJECT"
			oRecord=.NULL.
			SCATTER MEMO NAME oRecord
			SELECT (lcAlias)
			APPEND BLANK
			GATHER MEMO NAME oRecord
			oRecord=.NULL.
			SELECT view_default
			LOOP
		ENDIF
		IF lcType=="VIEW"
			oRecord=.NULL.
			SCATTER MEMO NAME oRecord
			SELECT (lcAlias)
			APPEND BLANK
			oRecord.Parent=lcCatalog
			GATHER MEMO NAME oRecord
			oRecord=.NULL.
			SELECT view_default
			LOOP
		ENDIF
		IF EMPTY(Views) OR NOT lcType=="ITEM"
			LOOP
		ENDIF
		lcViews=ALLTRIM(Views)
		lcID=LOWER(SYS(2015))
		_mline=0
		FOR lnCount = 1 TO MEMLINES(lcViews)
			lcMemLine=ALLTRIM(MLINE(lcViews,1,_mline))
			IF EMPTY(lcMemLine)
				LOOP
			ENDIF
			lnAtPos=AT("=",lcMemLine)
			IF lnAtPos=0
				LOOP
			ENDIF
			lcViewAlias=PROPER(ALLTRIM(LEFT(lcMemLine,lnAtPos-1)))
			IF EMPTY(lcViewAlias)
				LOOP
			ENDIF
			lcViewAlias="view_"+STRTRAN(lcViewAlias," ","_")
			IF NOT LOWER(lcViewAlias)==lcAlias
				LOOP
			ENDIF
			lcViewItem=ALLTRIM(SUBSTR(lcMemLine,lnAtPos+1))
			oRecord=.NULL.
			SCATTER MEMO NAME oRecord
			lcParent=LOWER(ALLTRIM(oRecord.Parent))
			IF EMPTY(lcViewItem)
				oRecord.Parent=lcCatalog
			ELSE
				lnIndex=ASCAN(laFolderText,LOWER(lcViewItem)+" ")
				IF lnIndex=0
					IF VARTYPE(oNode)=="O"
						oNode.Release
					ENDIF
					oNode=toBrowser.CreateNode(lcAlias,"FOLDER")
					WITH oNode
						.cParent=lcCatalog
						.cText=lcViewItem
						.WriteProperties
						lnFolderCount=lnFolderCount+1
						DIMENSION laFolderID[lnFolderCount],laFolderText[lnFolderCount]
						laFolderID[lnFolderCount]=.cID
						laFolderText[lnFolderCount]=LOWER(lcViewItem)+" "
						oRecord.Parent=.cID
					ENDWITH
					IF VARTYPE(oNode)=="O"
						oNode.Release
					ENDIF
					oNode=.NULL.
				ELSE
					oRecord.Parent=laFolderID[lnIndex]
				ENDIF
			ENDIF
			lnRecNo=RECNO()
			DO WHILE NOT EMPTY(lcParent)
				LOCATE FOR LOWER(ALLTRIM(ID))==lcParent
				IF EOF()
					EXIT
				ENDIF
				lcParent=LOWER(ALLTRIM(Parent))
				WITH oRecord
					IF EMPTY(.ClassLib) AND NOT EMPTY(ClassLib)
						.ClassLib=ClassLib
					ENDIF
					IF EMPTY(.ItemClass) AND NOT EMPTY(ItemClass)
						.ItemClass=ItemClass
					ENDIF
					IF lcType=="ITEM" AND EMPTY(.ClassName) AND NOT EMPTY(ItemClass)
						.ClassName=ItemClass
					ENDIF
					IF EMPTY(.ItemTpDesc) AND NOT EMPTY(ItemTpDesc)
						.ItemTpDesc=ItemTpDesc
					ENDIF
					IF EMPTY(.Picture) AND NOT EMPTY(Picture)
						.Picture=Picture
					ENDIF
				ENDWITH
			ENDDO
			lcID=LOWER(ALLTRIM(oRecord.ID))
			GO lnRecNo
			SELECT (lcAlias)
			LOCATE FOR LOWER(ALLTRIM(ID))==lcID
			IF EOF()
				APPEND BLANK
				GATHER MEMO NAME oRecord
			ENDIF
			oRecord=.NULL.
		ENDFOR
	ENDSCAN
	IF VARTYPE(oNode)=="O"
		oNode.Release
	ENDIF
	oNode=.NULL.
ENDIF
IF VARTYPE(oView)=="O"
	oView.Release
	oView=.NULL.
ENDIF
SELECT 0
IF llRefreshFolders AND lnViewType=1
	IF USED("itemtypes")
		SELECT itemtypes
		ZAP
	ELSE
		CREATE CURSOR itemtypes (Class C(64), Text C(32), Label C(32), Property C(64), ;
				Width N(4), ValidExpr M, Visible L, MenuItem L, ReadOnly L, Desc M, ClassLib M, ;
				ItemClass M, ItemTypes M, GetFileExt M, RowSource M, Script M)
		SELECT itemtypes
		INDEX ON Class TAG Class FOR NOT MenuItem
		INDEX ON UPPER(Text) TAG Text FOR MenuItem UNIQUE ADDITIVE
		SET ORDER TO Class
		LOCATE
	ENDIF
	SELECT 0
ENDIF
SELECT (lcAlias)
IF llRefreshFolders
	LOCATE
ELSE
	SEEK "FOLDER "
ENDIF
SCAN REST
	lnRecNo=RECNO()
	lcType=UPPER(ALLTRIM(Type))
	IF llRefreshFolders
		IF lcType=="CLASS"
			IF lnViewType#1
				LOOP
			ENDIF
			lcID=LOWER(ALLTRIM(ID))
			lcText=ALLTRIM(Text)
			lcDesc=ALLTRIM(Desc)
			lcClassLib=ALLTRIM(ClassLib)
			lcClass=LOWER(ALLTRIM(ClassName))
			lcItemClass=ALLTRIM(ItemClass)
			IF EMPTY(ItemTpDesc)
				lcItemTypes=""
			ELSE
				lcItemTypes=CR+LOWER(STRTRAN(STRTRAN(STRTRAN(STRTRAN(STRTRAN(ALLTRIM(ItemTpDesc), ;
					CR_LF,CR),LF,CR),";",CR)," ",""),TAB,""))+CR
			ENDIF
			IF EMPTY(Views)
				lcGetFileExt=""
			ELSE
				lcGetFileExt=LOWER(STRTRAN(STRTRAN(STRTRAN(ALLTRIM(Views), ;
						CR_LF,";"),LF,";"),CR,";"))
			ENDIF
			lcScript=ALLTRIM(Script)
			lcProperties=ALLTRIM(Properties)
			lcProperty=ALLTRIM(TypeDesc)
			llMenuItem=.T.
			llVisible=.F.
			IF NOT EMPTY(lcText)
				IF LEFT(lcText,1)=="!"
					lcText=ALLTRIM(SUBSTR(lcText,2))
				ELSE
					llVisible=.T.
				ENDIF
			ENDIF
			INSERT INTO itemtypes (Class, Text, Property, Visible, MenuItem, Desc, ClassLib, ;
							ItemClass, ItemTypes, GetFileExt, Script) ;
					VALUES (lcClass, lcText, lcProperty, llVisible, llMenuItem, lcDesc, ;
							lcClassLib, lcItemClass, lcItemTypes, lcGetFileExt, lcScript)
			SELECT itemtypes
			_mline=0
			FOR lnCount = 1 TO MEMLINES(lcProperties)
				lcLabel=""
				lcProperty=""
				lcWidth=""
				lcValidExpr=""
				lcGetFileExt=""
				lcLabel=ALLTRIM(MLINE(lcProperties,1,_mline))
				lnAtPos=AT(":=",lcLabel)
				IF lnAtPos>0
					lcValidExpr=ALLTRIM(SUBSTR(lcLabel,lnAtPos+2))
					lcLabel=ALLTRIM(LEFT(lcLabel,lnAtPos-1))
				ENDIF
				lnAtPos=AT("{",lcLabel)
				IF lnAtPos>0
					lnAtPos2=AT("}",lcLabel)
					IF lnAtPos2>lnAtPos
						lcGetFileExt=SUBSTR(lcLabel,lnAtPos+1,lnAtPos2-lnAtPos-1)
						IF EMPTY(lcGetFileExt)
							lcGetFileExt="*"
						ELSE
							lcGetFileExt=LOWER(ALLTRIM(lcGetFileExt))
						ENDIF
						lcLabel=LEFT(lcLabel,lnAtPos-1)+SUBSTR(lcLabel,lnAtPos2+1)
					ENDIF
				ENDIF
				lnAtPos=AT(",",lcLabel)
				IF lnAtPos=0
					LOOP
				ENDIF
				lcProperty=ALLTRIM(SUBSTR(lcLabel,lnAtPos+1))
				lcLabel=ALLTRIM(LEFT(lcLabel,lnAtPos-1))
				lnAtPos=AT("[",lcProperty)
				lnAtPos2=AT("]",lcProperty)
				IF lnAtPos=0 OR lnAtPos2=0 OR lnAtPos>lnAtPos2
					lcRowSource=""
				ELSE
					lcRowSource=ALLTRIM(SUBSTR(lcProperty,lnAtPos+1,lnAtPos2-lnAtPos-1))
					lcProperty=ALLTRIM(LEFT(lcProperty,lnAtPos-1))+ ;
							ALLTRIM(SUBSTR(lcProperty,lnAtPos2+1))
				ENDIF
				lcWidth="50"
				lnAtPos=AT(",",lcProperty)
				IF lnAtPos>0
					lnAtPos2=AT("]",lcProperty)
					IF lnAtPos2=0
						lnAtPos2=AT(")",lcProperty)
					ENDIF
					IF BETWEEN(lnAtPos,1,lnAtPos2)
						lnAtPos=AT(",",lcProperty,2)
					ENDIF
				ENDIF
				IF lnAtPos>0
					lcWidth=ALLTRIM(SUBSTR(lcProperty,lnAtPos+1))
					lcProperty=ALLTRIM(LEFT(lcProperty,lnAtPos-1))
				ENDIF
				llReadOnly=.F.
				llVisible=.F.
				IF NOT EMPTY(lcLabel)
					IF LEFT(lcLabel,1)=="!"
						lcLabel=ALLTRIM(SUBSTR(lcLabel,2))
					ELSE
						llVisible=.T.
						IF LEFT(lcLabel,1)=="*"
							lcLabel=ALLTRIM(SUBSTR(lcLabel,2))
							llReadOnly=.T.
						ENDIF
					ENDIF
				ENDIF
				INSERT INTO itemtypes (Class, Label, Property, Width, ValidExpr, Visible, ;
								ReadOnly, ItemTypes, GetFileExt, RowSource) ;
						VALUES (lcClass, lcLabel, lcProperty, EVALUATE(lcWidth), ;
								lcValidExpr, llVisible, llReadOnly, lcItemTypes, ;
								lcGetFileExt, lcRowSource)
			ENDFOR
			SELECT browser
			LOOP
		ENDIF
		IF lnViewType=1 AND lnCatalogRecNo>0 AND NOT EMPTY(Views) AND lcType=="ITEM"
			lcViews=ALLTRIM(Views)
			_mline=0
			FOR lnCount = 1 TO MEMLINES(lcViews)
				lcMemLine=ALLTRIM(MLINE(lcViews,1,_mline))
				IF EMPTY(lcMemLine)
					LOOP
				ENDIF
				lnAtPos=AT("=",lcMemLine)
				IF lnAtPos=0
					LOOP
				ENDIF
				lcViewAlias=PROPER(ALLTRIM(LEFT(lcMemLine,lnAtPos-1)))
				IF EMPTY(lcViewAlias)
					LOOP
				ENDIF
				lcViewAlias="view_"+STRTRAN(lcViewAlias," ","_")
				IF USED(lcViewAlias)
					LOOP
				ENDIF
				lcViewAlias=toBrowser.CreateView(lcViewAlias)
			ENDFOR
			oRecord=.NULL.
		ENDIF
	ENDIF
	DO CASE
		CASE lcType=="FOLDER"
			IF llRefreshFolders
				IF toBrowser.nFolderCount>toBrowser.nMaxFolderCount
					IF NOT llMaxFolderCountErrorMsg
						llMaxFolderCountErrorMsg=.T.
						toBrowser.MsgBox(M_FOLDERS_PAST_LIMIT_LOC+" "+ ;
								TRANSFORM(toBrowser.nMaxFolderCount)+"."+CR+CR+ ;
								M_FOLDERS_NOT_VISIBLE_LOC+".",16)
					ENDIF
					LOOP
				ENDIF
				lnType=IIF(EMPTY(Parent),1,2)
			ELSE
				IF EMPTY(Parent)
					LOOP
				ENDIF
				lnType=4
			ENDIF
		CASE lcType=="ITEM"
			IF llRefreshFolders
				LOOP
			ENDIF
			IF EMPTY(Parent)
				LOOP
			ENDIF
			lnType=5
		CASE NOT llRefreshFolders
			EXIT
		CASE lcType=="OBJECT"
			lnType=3
		CASE lcType=="VIEW"
			IF EMPTY(Parent)
				REPLACE Parent WITH lcCatalogID
			ENDIF
			lnType=6
		OTHERWISE
			LOOP
	ENDCASE
	IF toBrowser.lRelease
		SELECT 0
		toBrowser.vResult=.F.
		RETURN toBrowser.vResult
	ENDIF
	lcID=LOWER(ALLTRIM(ID))
	lcSourceAlias=LOWER(ALLTRIM(SrcAlias))
	IF EMPTY(lcID)
		lcSourceAlias=LOWER(ALIAS())
		lcDBF=IIF(USED(lcSourceAlias),LOWER(DBF(lcSourceAlias)),"")
	ELSE
		DO CASE
			CASE EMPTY(lcSourceAlias)
				lcSourceAlias=LOWER(ALIAS())
			CASE NOT USED(lcSourceAlias)
				LOOP
		ENDCASE
		IF lnViewType=1 OR lnType=1
			lcDBF=IIF(USED(lcSourceAlias),LOWER(DBF(lcSourceAlias)),"")
		ELSE
			IF EMPTY(lcViewCatalog)
				LOOP
			ENDIF
			lcDBF=lcViewCatalog
		ENDIF
	ENDIF
	lcID2=STRTRAN(JUSTSTEM(lcDBF)," ","_")
	lcCatalog=IIF(USED(lcSourceAlias),LOWER(DBF(lcSourceAlias)),"")
	IF lnType=1 AND lnViewType=1
		IF lcCatalog==lcLastCatalog
			LOOP
		ENDIF
		lcLastCatalog=lcCatalog
	ENDIF
	lcCatalogPath=IIF(EMPTY(lcDBF),"",JUSTPATH(lcDBF)+"\")
	toBrowser.oNodeObject.cCatalogPath=lcCatalogPath
	oParent=.NULL.
	IF NOT EMPTY(lcID)
		lcID=lcID2+"!"+lcID
	ENDIF
	IF INLIST(lnType,1,3)
		lcParent=""
	ELSE
		lcParent=LOWER(ALLTRIM(Parent))
		IF NOT EMPTY(lcParent) AND NOT "!"$lcParent
			lcParent=lcID2+"!"+lcParent
		ENDIF
	ENDIF
	lcLink=LOWER(ALLTRIM(Link))
	IF NOT EMPTY(lcLink) AND NOT "!"$lcLink
		lcLink=lcID2+"!"+lcLink
	ENDIF
	IF llRefreshFolders
		IF NOT EMPTY(lcParent)
			FOR lnType2 = 1 TO toBrowser.nFolderCount
				IF toBrowser.aFolderList[lnType2].cID==lcParent
					oParent=toBrowser.aFolderList[lnType2]
					EXIT
				ENDIF
			ENDFOR
			IF ISNULL(oParent)
				LOOP
			ENDIF
		ENDIF
	ELSE
		IF NOT lcParent==lcFolderID
			LOOP
		ENDIF
		oParent=oFolder
	ENDIF
	lcText=ALLTRIM(MLINE(Text,1))
	IF EMPTY(lcText)
		lcText=ALLTRIM(MLINE(ID,1))
	ENDIF
	lcKey=lcID
	IF lnType=1
		brwReleaseClassLibraries(toBrowser)
		IF NOT brwSetClassLibrary(toBrowser,toBrowser.cDefaultCatalogClassLibrary)
			toBrowser.MsgBox(M_NODE_LOC+" ("+IIF(EMPTY(lcText),lcID,lcText)+") "+ ;
					M_COULD_NOT_BE_CREATED_LOC+[.],16)
			toBrowser.vResult=.F.
			RETURN toBrowser.vResult
		ENDIF
	ENDIF
	lcClassLibrary=toBrowser.oNodeObject.FullPath(LOWER(ALLTRIM(MLINE(ClassLib,1))))
	IF NOT EMPTY(lcClassLibrary) AND NOT EMPTY(lcCatalogPath) AND ;
			EMPTY(SYS(2000,lcClassLibrary))
		lcClassLibrary=LOWER(FORCEPATH(lcClassLibrary,lcCatalogPath))
	ENDIF
	IF NOT EMPTY(lcID) AND NOT EMPTY(lcClassLibrary) AND ;
			NOT brwSetClassLibrary(toBrowser,lcClassLibrary)
		toBrowser.MsgBox(M_NODE_LOC+" ("+IIF(EMPTY(lcText),lcID,lcText)+") "+ ;
				M_COULD_NOT_BE_CREATED_LOC+[.],16)
		oParent=.NULL.
		oItem=.NULL.
		LOOP
	ENDIF
	lcClass=LOWER(ALLTRIM(MLINE(ClassName,1)))
	IF EMPTY(lcID)
		lcProperties=STRTRAN(ALLTRIM(Properties),";",CR)
		lcItem=lcText+CR+ ;
				ALLTRIM(Picture)+CR+ ;
				lcClass+CR+ ;
				lcClassLibrary+CR+ ;
				ALLTRIM(FileName)+CR+ ;
				ALLTRIM(Class)+CR+ ;
				CHR(0)+lcProperties
		toBrowser.nItemCount=toBrowser.nItemCount+1
		lnIndex=toBrowser.nItemCount
		DIMENSION toBrowser.aItemList[lnIndex]
		oFolder.nItemCount=oFolder.nItemCount+1
		IF oFolder.nItemCount=1
			oFolder.nItemIndex=lnIndex
		ENDIF
		DIMENSION oFolder.aItemIndexes[oFolder.nItemCount]
		oFolder.aItemIndexes[oFolder.nItemCount]=lnIndex
		toBrowser.aItemList[lnIndex]=lcItem
		LOOP
	ENDIF
	IF EMPTY(lcClass)
		DO CASE
			CASE lnType=1
				IF lnCatalogRecNo=0
					lcViewCatalog=lcCatalog
				ENDIF
				lnCatalogRecNo=RECNO()
				lcCatalogID=lcID
				lcClass=toBrowser.cFolderClass
			CASE lnType=2
				lcClass=oParent.Class
				IF NOT brwSetClassLibrary(toBrowser,oParent.ClassLibrary)
					toBrowser.MsgBox(M_NODE_LOC+" ("+IIF(EMPTY(lcText),lcID,lcText)+") "+ ;
							M_COULD_NOT_BE_CREATED_LOC+[.],16)
					oParent=.NULL.
					oItem=.NULL.
					LOOP
				ENDIF
			CASE lnType=3
				IF NOT ISNULL(oParent) AND NOT EMPTY(oParent.cItemClass)
					lcClass=oParent.cItemClass
					IF NOT brwSetClassLibrary(toBrowser,oParent.cItemClassLibrary)
						toBrowser.MsgBox(M_NODE_LOC+" ("+IIF(EMPTY(lcText),lcID,lcText)+") "+ ;
								M_COULD_NOT_BE_CREATED_LOC+[.],16)
						oParent=.NULL.
						oItem=.NULL.
						LOOP
					ENDIF
				ELSE
					lcClass=toBrowser.cObjectClass
				ENDIF
			CASE lnType=4
				lcClass=oParent.Class
				IF NOT brwSetClassLibrary(toBrowser,oParent.ClassLibrary)
					toBrowser.MsgBox(M_NODE_LOC+" ("+IIF(EMPTY(lcText),lcID,lcText)+") "+ ;
							M_COULD_NOT_BE_CREATED_LOC+[.],16)
					oParent=.NULL.
					oItem=.NULL.
					LOOP
				ENDIF
			CASE lnType=5
				IF NOT ISNULL(oParent) AND NOT EMPTY(oParent.cItemClass)
					lcClass=oParent.cItemClass
					IF NOT brwSetClassLibrary(toBrowser,oParent.cItemClassLibrary)
						toBrowser.MsgBox(M_NODE_LOC+" ("+IIF(EMPTY(lcText),lcID,lcText)+") "+ ;
								M_COULD_NOT_BE_CREATED_LOC+[.],16)
						oParent=.NULL.
						oItem=.NULL.
						LOOP
					ENDIF
				ELSE
					lcClass=toBrowser.cItemClass
				ENDIF
			CASE lnType=6
				lcClass=toBrowser.cViewClass
		ENDCASE
	ENDIF
	IF EMPTY(lcClass)
		oParent=.NULL.
		oItem=.NULL.
		LOOP
	ENDIF
	oItem=CREATEOBJECT(lcClass)
	GO lnRecNo
	IF VARTYPE(oItem)#"O"
		oParent=.NULL.
		oItem=.NULL.
		LOOP
	ENDIF
	IF NOT oItem.Visible OR oItem.lDeleted
		oParent=.NULL.
		oItem.Release
		oItem=.NULL.
		LOOP
	ENDIF
	oTHIS=oItem
	oRecord=.NULL.
	SCATTER MEMO NAME oRecord
	WITH oItem
		.oHost=toBrowser
		.oRecord=oRecord
		IF NOT ISNULL(oParent)
			.oParent=oParent
			IF .oParent.lDynamic
				.lDynamic=.T.
			ENDIF
			IF lnType=4
				oParent=toBrowser.GetFolder(lcID2+"!"+ALLTRIM(ID),.T.)
				IF ISNULL(oParent)
					.oFolder=oItem
				ELSE
					.oFolder=oParent
				ENDIF
			ELSE
				.oFolder=oParent
			ENDIF
		ELSE
			.oParent=oItem
			.oFolder=oItem
			IF .oParent.lDynamic
				.lDynamic=.T.
			ENDIF
		ENDIF
		oParent=.NULL.
		IF lnType=2 AND .oParent.nIndex=0
			oTHIS=.NULL.
			oParent=.NULL.
			oItem.Release
			oItem=.NULL.
			LOOP
		ENDIF
		SET DATASESSION TO toBrowser.DataSessionID
		SELECT (toBrowser.cGallery)
		DO CASE
			CASE lnType=1
				.lCatalog=.T.
				.lFolder=.T.
			CASE lnType=2
				.lFolder=.T.
			CASE lnType=3
				.lObject=.T.
			CASE lnType=4
				.lFolderItem=.T.
			CASE lnType=6
				.lView=.T.
		ENDCASE
		.cType=lcType
		.cID=lcID
		.cID2=lcID2
		.cParent=lcParent
		IF NOT EMPTY(lcLink)
			.cLink=lcLink
		ENDIF
		.oLink=oItem
		.oAction=oItem
		.oShortCutMenu=.oHost.oShortCutMenu
		.oShortCutMenu.oHost=oItem
		.cCatalog=lcCatalog
		.cCatalogPath=lcCatalogPath
		.cAlias=lcAlias
		.cSourceAlias=lcSourceAlias
		.cSourceCatalog=lcCatalog
		.cSourceCatalogPath=lcCatalogPath
		.nSourceRecNo=SrcRecNo
		.nRecNo=RECNO()
		IF EMPTY(.cViews)
			.cViews=ALLTRIM(Views)
		ENDIF
		IF lnType=3
			lcItemClass=LOWER(ALLTRIM(MLINE(ItemClass,1)))
			IF NOT EMPTY(lcItemClass)
				oObject=CREATEOBJECT(lcItemClass)
				SET DATASESSION TO toBrowser.DataSessionID
				SELECT (toBrowser.cGallery)
				IF TYPE("oObject")#"O" OR ISNULL(oObject)
					oObject=.NULL.
					toBrowser.MsgBox(M_CLASS_LOC+" ("+lcItemClass+") "+ ;
							M_COULD_NOT_BE_CREATED_LOC+[.],16)
				ELSE
					oItem.oObject=oObject
					oObject=.NULL.
				ENDIF
			ENDIF
		ENDIF
		IF NOT EMPTY(Properties)
			.cProperties=ALLTRIM(Properties)
		ENDIF
		IF NOT EMPTY(Script)
			.cScript=ALLTRIM(Script)
		ENDIF
		IF NOT EMPTY(ClassLib)
			.cClassLib=MLINE(ClassLib,1)
		ENDIF
		.cClassLib=LOWER(.FullPath(.cClassLib))
		IF NOT EMPTY(ClassName)
			.cClassName=ALLTRIM(MLINE(ClassName,1))
		ENDIF
		IF NOT EMPTY(ItemTpDesc)
			.cItemTpDesc=ALLTRIM(ItemTpDesc)
		ENDIF
		IF NOT EMPTY(Keywords)
			.cKeywords=ALLTRIM(Keywords)
		ENDIF
		.tUpdated=Updated
		IF NOT EMPTY(Comment)
			.cComment=ALLTRIM(Comment)
		ENDIF
		IF NOT EMPTY(User)
			.cUser=ALLTRIM(User)
		ENDIF
		.SetProperties(.cProperties)
		IF toBrowser.lRelease
			GO lnRecNo
			oTHIS=.NULL.
			oParent=.NULL.
			oItem.Release
			oItem=.NULL.
			LOOP
		ENDIF
		GO .nRecNo
		SET DATASESSION TO toBrowser.DataSessionID
		SELECT (toBrowser.cGallery)
		IF NOT .Visible OR .lDeleted
			GO lnRecNo
			oTHIS=.NULL.
			oParent=.NULL.
			oItem.Release
			oItem=.NULL.
			LOOP
		ENDIF
		GO .nRecNo
		SET DATASESSION TO toBrowser.DataSessionID
		SELECT (toBrowser.cGallery)
		IF NOT .Visible OR .lDeleted
			oTHIS=.NULL.
			oParent=.NULL.
			oItem.Release
			oItem=.NULL.
			LOOP
		ENDIF
		IF NOT EMPTY(lcText)
			.cText=lcText
		ENDIF
		IF NOT EMPTY(Desc)
			.cDesc=ALLTRIM(Desc)
		ENDIF
		IF EMPTY(.cDesc)
			.cDesc=lcText
		ENDIF
		IF NOT EMPTY(TypeDesc)
			.cTypeDesc=ALLTRIM(TypeDesc)
		ENDIF
		IF EMPTY(.cTypeDesc) AND lnType#5
			.cTypeDesc=.oParent.cTypeDesc
		ENDIF
		IF NOT EMPTY(FileName)
			.cFileName=MLINE(FileName,1)
		ENDIF

*** 06/29/2004 - fix to preserve case of URL for Component Gallery web site items
*!*			.cFileName=LOWER(.FullPath(.cFileName))
		IF TYPE(".cItemType")="C" AND UPPER(.cItemType)="URL"
			.cFileName=ALLTRIM(.cFileName)
		ELSE
			.cFileName=LOWER(.FullPath(.cFileName))
		ENDIF               


		IF NOT EMPTY(Class)
			.cClass=LOWER(ALLTRIM(MLINE(Class,1)))
		ENDIF
		IF NOT EMPTY(Picture)
			.cPicture=MLINE(Picture,1)
		ENDIF
		IF .lDynamic AND "\dev\browser\"$.cPicture
			.cPicture=LOWER(brwImagePictureFile(toBrowser,JUSTFNAME(.cPicture)))
		ELSE
			.cPicture=LOWER(brwImagePictureFile(toBrowser,.FullPath(.cPicture)))
		ENDIF
		IF NOT EMPTY(FolderPict)
			.cFolderPicture=MLINE(FolderPict,1)
		ENDIF
		IF .lDynamic AND "\dev\browser\"$.cFolderPicture
			.cFolderPicture=LOWER(brwImagePictureFile(toBrowser,JUSTFNAME(.cFolderPicture)))
		ELSE
			.cFolderPicture=LOWER(brwImagePictureFile(toBrowser,.FullPath(.cFolderPicture)))
		ENDIF
		IF NOT INLIST(lnType,3,5,6)
			IF NOT EMPTY(ItemClass)
				.cItemClass=LOWER(ALLTRIM(MLINE(ItemClass,1)))
			ENDIF
			IF NOT EMPTY(.cItemClass)
				.cItemClass=.cItemClass
				IF EMPTY(.cItemClassLibrary)
					.cItemClassLibrary=lcClassLibrary
				ENDIF
			ELSE
				IF NOT ISNULL(.oParent) AND NOT EMPTY(.oParent.cItemClass)
					.cItemClass=.oParent.cItemClass
					IF EMPTY(.cItemClassLibrary)
						.cItemClassLibrary=.oParent.cItemClassLibrary
					ENDIF
				ENDIF
			ENDIF
			IF NOT EMPTY(ItemTpDesc)
				.cItemTypeDesc=LOWER(ALLTRIM(ItemTpDesc))
			ENDIF
		ENDIF
		.cItemType=ALLTRIM(.cItemType)
		IF NOT .InitProperties()
			oTHIS=.NULL.
			oParent=.NULL.
			oItem.Release
			oItem=.NULL.
			LOOP
		ENDIF
		oNode=.NULL.
		DO CASE
			CASE lnType=1
				lcPicture="catalog.ico"
				oNode=toBrowser.oleFolderList.object.Nodes.Add(,4,lcKey,lcText)
				IF ISNULL(oNode)
					toBrowser.MsgBox(M_CATALOG_LOC+" ("+.cID+") "+ ;
							M_COULD_NOT_BE_CREATED_LOC+".",16)
					oTHIS=.NULL.
					oParent=.NULL.
					oItem.Release
					oItem=.NULL.
					LOOP
				ENDIF
				.nNodeIndex=oNode.Index
				IF toBrowser.lAutoExpand
					oNode.Expanded=.T.
				ENDIF
			CASE lnType=2
				IF .lWebView
					lcPicture=toBrowser.GetWebIcon(.cFileName)
				ELSE
					lcPicture="folder.ico"
				ENDIF
				oNode=toBrowser.oleFolderList.object.Nodes.Add(lcParent, ;
						4,lcKey,lcText,,)
				IF ISNULL(oNode)
					toBrowser.MsgBox(M_FOLDER_LOC+" ("+.cID+") "+ ;
							M_COULD_NOT_BE_CREATED_LOC+".",16)
					oTHIS=.NULL.
					oParent=.NULL.
					oItem.Release
					oItem=.NULL.
					LOOP
				ENDIF
				.nNodeIndex=oNode.Index
			CASE lnType=4
				DO CASE
					CASE .lFolderItem
						lcPicture=.oFolder.cFolderPicture
						.cPicture=lcPicture
						.cFolderPicture=lcPicture
					CASE NOT EMPTY(.cPicture)
						lcPicture=.cPicture
						.cPicture=lcPicture
					CASE .lWebView
						lcPicture=toBrowser.GetWebIcon(.cFileName)
						lcPicture="folder.ico"
						.cPicture=lcPicture
				ENDCASE
			CASE lnType=6
				IF EMPTY(.cText)
					LOOP
				ENDIF
				.cViewAlias=toBrowser.CreateView("view_"+LOWER(.cText))
		ENDCASE
		IF NOT ISNULL(oNode)
			llIgnoreErrors=toBrowser.lIgnoreErrors
			toBrowser.lIgnoreErrors=.T.
			IF .lFolderItem AND NOT EMPTY(.cPicture)
				oNode.Image=lcPicture
			ELSE
				IF NOT EMPTY(.cFolderPicture)
					lnImageIndex=toBrowser.GetImageIndex(.T.,.cFolderPicture)
					IF lnImageIndex=0
						.cFolderPicture=lcPicture
					ENDIF
				ELSE
					IF NOT .oFolder.lFolder AND NOT EMPTY(.oFolder.cFolderPicture)
						.cFolderPicture=.oFolder.cFolderPicture
					ELSE
						.cFolderPicture=lcPicture
					ENDIF
				ENDIF
				oNode.Image=.cFolderPicture
			ENDIF
			toBrowser.lIgnoreErrors=llIgnoreErrors
		ENDIF
		IF EMPTY(.cToolTipText)
			lcItemType=PROPER(IIF(EMPTY(.cItemType),.cType,.cItemType))
			IF lnType=1
				.cToolTipText=.cText+" ("+lcItemType+"):"+"  "+lcCatalog
			ELSE
				.cToolTipText=.cText+" ("+lcItemType+")"
			ENDIF
		ENDIF
		IF EMPTY(.cStatusBarText)
			.cStatusBarText=.cToolTipText
		ENDIF
	ENDWITH
	oNode=.NULL.
	IF lnType=4 OR lnType=5
		IF oItem.oParent.nIndex<1
			oTHIS=.NULL.
			oParent=.NULL.
			oItem.Release
			oItem=.NULL.
			LOOP
		ENDIF
		llMatch=.F.
		FOR lnCount = 1 TO toBrowser.nItemCount
			IF VARTYPE(toBrowser.aItemList[lnCount])#"O"
				LOOP
			ENDIF
			WITH toBrowser.aItemList[lnCount]
				IF NOT .cID==oItem.cID
					LOOP
				ENDIF
				llMatch=.T.
				lnIndex=lnCount
				.oObject=.NULL.
				.oSource=.NULL.
				.oTarget=.NULL.
				.oControl=.NULL.
				.oHost=.NULL.
				.oAction=.NULL.
				.oShortCutMenu=.NULL.
				.oLink=.NULL.
				.oFolder=.NULL.
				.oParent=.NULL.
				toBrowser.aItemList[lnCount]=.NULL.
				EXIT
			ENDWITH
		ENDFOR
		IF NOT llMatch
			toBrowser.nItemCount=toBrowser.nItemCount+1
			lnIndex=toBrowser.nItemCount
			DIMENSION toBrowser.aItemList[lnIndex]
		ENDIF
		oFolder.nItemCount=oFolder.nItemCount+1
		IF oFolder.nItemCount=1
			oFolder.nItemIndex=lnIndex
		ENDIF
		DIMENSION oFolder.aItemIndexes[oFolder.nItemCount]
		oFolder.aItemIndexes[oFolder.nItemCount]=lnIndex
		oItem.nIndex=lnIndex
		oItem.nItemIndex=oFolder.nItemCount
		oItem.oControl=toBrowser.oleItems
		toBrowser.aItemList[lnIndex]=oItem
	ELSE
		toBrowser.nFolderCount=toBrowser.nFolderCount+1
		DIMENSION toBrowser.aFolderList[toBrowser.nFolderCount]
		oItem.nIndex=toBrowser.nFolderCount
		oItem.oControl=toBrowser.oleFolderList
		toBrowser.aFolderList[toBrowser.nFolderCount]=oItem
	ENDIF
	IF TYPE("oItem.oAction")=="O" AND NOT ISNULL(oItem.oAction) AND NOT oItem.lRefreshed
		oItem.lRefreshed=.T.
		oItem.oAction.Refreshed
	ENDIF
	oTHIS=.NULL.
	oParent=.NULL.
	oItem=.NULL.
ENDSCAN
oNode=.NULL.
oTHIS=.NULL.
oParent=.NULL.
oItem=.NULL.
oFolder=.NULL.
toBrowser.RefreshLinks(llRefreshFolders)
brwReleaseClassLibraries(toBrowser)
SELECT 0
ENDFUNC



FUNCTION brwRefreshItemList(toBrowser)
LOCAL oNode,oParent,oFolder,oItem,lcItem,lnItemCount
LOCAL lcPicture,lcCatalog,lcID,lcText,lcClassName,lcClassLibrary
LOCAL lcObjName,llLockScreen,lcItemType,lcURL,lcFileName,lcFileExt
LOCAL lnImageIndex,lnIndex,lnLastIndex,lnCount,lnFileItemCount
LOCAL lcItemTypes,lcProperties,lnAtPos,lnLastSelect,llIgnoreErrors
LOCAL laFileItems[1,2]

IF toBrowser.lRelease OR toBrowser.lBrowser
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
SET DATASESSION TO toBrowser.DataSessionID
IF NOT USED(toBrowser.cGallery)
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
lnFileItemCount=0
WITH toBrowser
	.oItem=.NULL.
	.oItemSource=.NULL.
	.nItemListIndex=-1
	.imgClassIcon.Visible=.F.
	.cmdClassIcon.Visible=.F.
	.edtItemDesc.Value=""
	IF .nFolderCount<=0
		.oFolder=.NULL.
		.oFolderSource=.NULL.
		.oCatalog=.NULL.
		.oCatalogSource=.NULL.
		.nFolderListIndex=-1
		.nLastFolderListIndex=-1
		RETURN
	ENDIF
	lnLastIndex=.nLastFolderListIndex
	IF lnLastIndex>0
		lcPicture=.oleFolderList.object.Nodes[lnLastIndex].Image
		DO CASE
			CASE lcPicture=="openctlg.ico"
				lcPicture="catalog.ico"
			CASE lcPicture=="openfldr.ico"
				lcPicture="folder.ico"
			CASE lcPicture=="cofldr.ico"
				lcPicture="cfldr.ico"
			CASE lcPicture=="dofldr.ico"
				lcPicture="dfldr.ico"
			CASE lcPicture=="fofldr.ico"
				lcPicture="ffldr.ico"
			CASE lcPicture=="pofldr.ico"
				lcPicture="pfldr.ico"
			OTHERWISE
				lcPicture=""
		ENDCASE
		IF NOT EMPTY(lcPicture)
			.oleFolderList.object.Nodes[lnLastIndex].Image=lcPicture
		ENDIF
	ENDIF
ENDWITH
IF toBrowser.nFolderListIndex<1
	WITH toBrowser
		.nFolderListIndex=1
		.nLastFolderListIndex=-1
		.oleFolderList.object.Nodes[1].Selected=.T.
		.oCatalogSource=.aFolderList[1]
		.oCatalog=.oCatalogSource.oLink
		.oFolderSource=oCatalogSource
		.oFolder=.oCatalog
		.oItemSource=.oFolderSource
		.oItem=.oFolder
		.cCatalog=.oItem.cSourceCatalog
	ENDWITH
ENDIF
WITH toBrowser
	.nFolderListIndex=.oleFolderList.object.SelectedItem.Index
	oFolder=.aFolderList[.nFolderListIndex]
	.oFolderSource=oFolder
	oFolder=oFolder.oLink
	.oFolder=oFolder
	IF oFolder.lWebView
		SET MESSAGE TO M_REFRESH_WEB_VIEW_LOC+" ..."
	ELSE
		SET MESSAGE TO M_REFRESH_ITEM_LIST_LOC+" ..."
	ENDIF
	lnItemCount=oFolder.nItemCount
	IF lnItemCount<=0 OR .nItemListIndex<1
		.oItemSource=.oFolderSource
		.oItem=.oFolder
		.cCatalog=.oItem.cSourceCatalog
	ENDIF
	oParent=.oFolderSource
	DO WHILE NOT oParent.cID==oParent.oFolder.cID
		oParent=oParent.oFolder
	ENDDO
	.oCatalogSource=oParent
	.oCatalog=oParent.oLink
	lnIndex=oFolder.nIndex
	IF lnIndex>0
		lcPicture=.oleFolderList.object.Nodes[lnIndex].Image
		DO CASE
			CASE lcPicture=="catalog.ico"
				lcPicture="openctlg.ico"
			CASE lcPicture=="folder.ico"
				lcPicture="openfldr.ico"
			CASE lcPicture=="cfldr.ico"
				lcPicture="cofldr.ico"
			CASE lcPicture=="dfldr.ico"
				lcPicture="dofldr.ico"
			CASE lcPicture=="ffldr.ico"
				lcPicture="fofldr.ico"
			CASE lcPicture=="pfldr.ico"
				lcPicture="pofldr.ico"
			OTHERWISE
				lcPicture=""
		ENDCASE
		IF NOT EMPTY(lcPicture)
			.oleFolderList.object.Nodes[lnIndex].Image=lcPicture
		ENDIF
	ENDIF
	.oleItems.object.ListItems.Clear
	IF oFolder.lWebView AND NOT .lWebBrowser
		.SetWebBrowser
	ENDIF
	IF .lWebBrowser
		.lWebView=oFolder.lWebView
		IF .lWebView
			.oleItems.Visible=.F.
			.oleWebBrowser.Visible=.T.
		ELSE
			IF NOT LOWER(ALLTRIM(.oleWebBrowser.LocationURL))==LOWER(ALLTRIM(.cBlankHTMLFile))
				.oleWebBrowser.Navigate(.cBlankHTMLFile)
			ENDIF
			IF NOT .lRefreshBrowserMode
				.oleWebBrowser.Visible=.F.
				.oleItems.Visible=.T.
			ENDIF
		ENDIF
	ELSE
		.lWebView=.F.
		IF NOT .lRefreshBrowserMode
			.oleItems.Visible=.T.
		ENDIF
	ENDIF
	llLockScreen=.LockScreen
	.Draw
	.LockScreen=.T.
ENDWITH
IF oFolder.nItemCount=-1
	toBrowser.RefreshObjects(oFolder)
ENDIF
FOR lnCount = 1 TO IIF(toBrowser.lWebView,0,oFolder.nItemCount)
	IF toBrowser.lRelease
		toBrowser.LockScreen=llLockScreen
		SELECT 0
		SET MESSAGE TO
		toBrowser.vResult=.F.
		RETURN toBrowser.vResult
	ENDIF
	lnIndex=oFolder.aItemIndexes[lnCount]
	oItem=toBrowser.aItemList[lnIndex]
	lcPicture=""
	DO CASE
		CASE VARTYPE(oItem)=="O"
			IF NOT oItem.Visible OR oItem.lDeleted
				oItem=.NULL.
				LOOP
			ENDIF
			lcPicture=oItem.cPicture
			IF oItem.lFolderItem
				lcPicture=oItem.cFolderPicture
				lcItemType="Folder"
			ELSE
				lcItemType=oItem.cItemType
				IF EMPTY(lcItemType)
					oParent=oItem
					DO WHILE NOT oParent.cID==oParent.oFolder.oLink.cID
						oParent=oParent.oFolder.oLink
						IF NOT EMPTY(oParent.cItemType)
							lcItemType=oParent.cItemType
							EXIT
						ENDIF
					ENDDO
					oParent=.NULL.
					IF EMPTY(lcItemType)
						lcItemType="Item"
					ENDIF
				ENDIF
			ENDIF
			IF oItem.cType=="ITEM"
				lcPicture=oItem.cPicture
				IF EMPTY(lcPicture) AND NOT oItem.lFolderItem
					oParent=oItem
					DO WHILE NOT oParent.cID==oParent.oFolder.oLink.cID
						oParent=oParent.oFolder.oLink
						IF oParent.lCatalog
							EXIT
						ENDIF
						IF NOT EMPTY(oParent.cPicture)
							lcPicture=oParent.cPicture
							EXIT
						ENDIF
					ENDDO
					oParent=.NULL.
				ENDIF
			ENDIF
			lcCatalog=oItem.cCatalog
			lcID=oItem.cID
			lcText=oItem.cText
		CASE VARTYPE(oItem)=="C"
			lcItem=oItem
			lcClassName=LOWER(MLINE(lcItem,3))
			IF EMPTY(lcClassName)
				lcClassName=LOWER(oFolder.cItemClass)
				IF EMPTY(lcClassName)
					LOOP
				ENDIF
			ENDIF
			lcClassLibrary=LOWER(MLINE(lcItem,4))
			lcFileName=LOWER(MLINE(lcItem,5))
			lcFileExt=JUSTEXT(lcFileName)
			IF NOT EMPTY(lcFileExt)
				lnAtPos=ASCAN(laFileItems,lcFileExt)
				IF lnAtPos>0
					lcClassName=laFileItems[lnAtPos+1]
				ELSE
					lnLastSelect=SELECT()
					SELECT itemtypes
					SET ORDER TO Class
					SEEK lcClassName
					IF NOT EOF()
						lcItemTypes=ALLTRIM(ItemTypes)
						lnAtPos=ATC(CR+lcFileExt+"=",lcItemTypes)
						IF lnAtPos>0
							lcClassName=LOWER(MLINE(SUBSTR(lcItemTypes,lnAtPos+LEN(lcFileExt)+2),1))
							lnFileItemCount=lnFileItemCount+1
							DIMENSION laFileItems[lnFileItemCount,2]
							laFileItems[lnFileItemCount,1]=lcFileExt
							laFileItems[lnFileItemCount,2]=lcClassName
						ENDIF
					ENDIF
				ENDIF
				SELECT (lnLastSelect)
			ENDIF
			lcObjName="o"+lcClassName
			WITH toBrowser.oNodes
				IF TYPE("toBrowser.oNodes."+lcObjName)#"O"
					.NewObject(lcObjName,lcClassName,lcClassLibrary)
					IF TYPE("toBrowser.oNodes."+lcObjName)#"O"
						LOOP
					ENDIF
				ENDIF
				oItem=.&lcObjName
			ENDWITH
			IF VARTYPE(oItem)#"O"
				LOOP
			ENDIF
			oItem.oParent=oParent
			oItem.oFolder=oFolder
			lnAtPos=AT(CHR(0),lcItem)
			lcProperties=IIF(lnAtPos>0,SUBSTR(lcItem,lnAtPos+1),"")
			oItem.SetProperties(lcProperties)
			lcItemType=oItem.cItemType
			lcID=LOWER(SYS(2015))
			lcText=MLINE(lcItem,1)
			lcPicture=LOWER(MLINE(lcItem,2))
			IF EMPTY(lcPicture)
				lcPicture=oItem.cPicture
			ENDIF
			IF NOT EMPTY(lcPicture) AND EMPTY(JUSTFNAME(lcPicture))
				lcPicture=oItem.cPicture
			ENDIF
			IF EMPTY(lcPicture)
				IF NOT EMPTY(oItem.cPicture)
					lcPicture=LOWER(FULLPATH(oItem.cPicture,lcClassLibrary))
				ENDIF
				IF EMPTY(lcPicture)
					oParent=oFolder
					DO WHILE NOT oParent.cID==oParent.oFolder.oLink.cID
						IF NOT EMPTY(oParent.cPicture)
							lcPicture=oParent.cPicture
							EXIT
						ENDIF
						oParent=oParent.oFolder.oLink
						IF oParent.lCatalog
							EXIT
						ENDIF
					ENDDO
				ENDIF
				IF NOT EMPTY(lcPicture)
					lcItem=STRTRAN(lcItem,CR+CR,CR+lcPicture+CR,1,1)
					toBrowser.aItemList[lnIndex]=lcItem
				ENDIF
			ENDIF
			IF EMPTY(lcPicture)
				IF TYPE([GETPEM(lcClassName,"cPicture")])=="U"
					NEWOBJECT(lcClassName,lcClassLibrary)
				ENDIF
				IF TYPE([GETPEM(lcClassName,"cPicture")])=="C"
					lcPicture=GETPEM(lcClassName,"cPicture")
				ENDIF
			ENDIF
			IF NOT EMPTY(lcPicture) AND NOT ":"$lcPicture AND NOT "\\"$lcPicture
				lcPicture=toBrowser.cDefaultCatalogPath+lcPicture
			ENDIF
			oItem.cPicture=lcPicture
			lcCatalog=oFolder.cCatalog
		OTHERWISE
			LOOP
	ENDCASE
	oNode=toBrowser.oleItems.object.ListItems.Add(,lcCatalog+"_"+lcID,lcText)
	IF ISNULL(oNode)
		toBrowser.MsgBox(M_ITEM_LOC+" ("+lcID+") "+M_COULD_NOT_BE_CREATED_LOC+".",16)
		oItem=.NULL.
		LOOP
	ENDIF
	llIgnoreErrors=toBrowser.lIgnoreErrors
	toBrowser.lIgnoreErrors=.T.
	lnImageIndex=IIF(EMPTY(lcPicture),0,toBrowser.GetImageIndex(,lcPicture))
	IF lnImageIndex=0
		lcPicture="item.ico"
		IF VARTYPE(oItem)=="O"
			oItem.nNodeIndex=oNode.Index
			IF oItem.cType=="FOLDER" OR oItem.lFolderItem
				DO CASE
					CASE oItem.lCatalog
						lcPicture="catalog.ico"
					CASE oItem.lWebView
						lcPicture=toBrowser.GetWebIcon(oItem.cFileName)
					OTHERWISE
						lcPicture="folder.ico"
				ENDCASE
			ENDIF
			IF NOT oItem.Enabled
				oNode.Ghosted=.T.
			ENDIF
		ENDIF
		lnImageIndex=toBrowser.GetImageIndex(,lcPicture)
	ENDIF
	oNode.Icon=lnImageIndex
	oNode.SmallIcon=lnImageIndex
	oNode.SubItems[1]=lcItemType
	oItem.nNodeIndex=oNode.Index
	toBrowser.lIgnoreErrors=llIgnoreErrors
	oItem=.NULL.
ENDFOR
WITH toBrowser
	.RefreshItem
	IF .oleItems.object.View#.nImageView
		.oleItems.object.View=.nImageView
	ENDIF
	IF .lWebView
		IF EMPTY(oFolder.cFileName)
			.oleWebBrowser.Navigate(.cBlankHTMLFile)
		ELSE
			.oleWebBrowser.Navigate(ALLTRIM(oFolder.cFileName))
		ENDIF
	ENDIF
	.RefreshButtons
	.LockScreen=.F.
	.Draw
	SELECT 0
	SET MESSAGE TO
	IF TYPE("oFolder.oAction")=="O" AND NOT ISNULL(oFolder.oAction)
		oFolder.oAction.Selected
	ENDIF
	oFolder=.NULL.
	.LockScreen=llLockScreen
ENDWITH
ENDFUNC



FUNCTION brwRefreshItem(toBrowser)
LOCAL oFolder,oItem,lcItem,lcID,lcText,lcPicture,lcFileName,lcClass
LOCAL lnItemIndex,lcVarType,lnIndex,lnCount,lcClassName,lcClassLibrary
LOCAL lcItemTypes,lcFileExt,lcProperties,lnAtPos,lnLastSelect

IF toBrowser.lRelease OR toBrowser.lBrowser
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
WITH toBrowser
	.oItem=.NULL.
	.oItemSource=.NULL.
	oItem=.NULL.
	oFolder=.oFolder
ENDWITH
SET DATASESSION TO toBrowser.DataSessionID
IF NOT USED(toBrowser.cGallery)
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
IF NOT ISNULL(oFolder)
	lnIndex=toBrowser.nItemListIndex
	IF lnIndex>0
		FOR lnCount = 1 TO oFolder.nItemCount
			lnItemIndex=oFolder.aItemIndexes[lnCount]
			oItem=toBrowser.aItemList[lnItemIndex]
			IF lnItemIndex>oFolder.aItemIndexes[lnIndex]
				EXIT
			ENDIF
			IF VARTYPE(oItem)=="O" AND (NOT oItem.Visible OR oItem.lDeleted)
				lnIndex=lnIndex+1
			ENDIF
		ENDFOR
	ELSE
		IF TYPE("toBrowser.oleItems.SelectedItem.Selected")=="L" AND ;
				toBrowser.oleItems.SelectedItem.Selected
			toBrowser.oleItems.SelectedItem.Selected=.F.
		ENDIF
	ENDIF
	WITH toBrowser
		IF ISNULL(oItem)
			oItem=toBrowser.oFolderSource
		ELSE
			oItem=.aItemList[oFolder.aItemIndexes[lnIndex]]
		ENDIF
		lcVarType=VARTYPE(oItem)
		IF lcVarType=="C"
			lcItem=oItem
			oItem=.NULL.
			lcClassName=LOWER(MLINE(lcItem,3))
			IF EMPTY(lcClassName)
				lcClassName=.cItemClass
			ENDIF
			lcClassLibrary=LOWER(MLINE(lcItem,4))
			IF EMPTY(lcClassLibrary)
				lcClassLibrary=.cDefaultCatalogClassLibrary
			ENDIF
			lcText=MLINE(lcItem,1)
			lcPicture=MLINE(lcItem,2)
			IF NOT EMPTY(lcPicture) AND NOT ":"$lcPicture AND NOT "\\"$lcPicture
				lcPicture=toBrowser.cDefaultCatalogPath+lcPicture
			ENDIF
			lcFileName=MLINE(lcItem,5)
			lcClass=MLINE(lcItem,6)
			lnAtPos=AT(CHR(0),lcItem)
			lcProperties=IIF(lnAtPos>0,SUBSTR(lcItem,lnAtPos+1),"")
			lcFileExt=JUSTEXT(lcFileName)
			IF NOT EMPTY(lcFileExt)
				lnLastSelect=SELECT()
				SELECT itemtypes
				SET ORDER TO Class
				SEEK lcClassName
				IF NOT EOF()
					lcItemTypes=ALLTRIM(ItemTypes)
					lnAtPos=ATC(CR+lcFileExt+"=",lcItemTypes)
					IF lnAtPos>0
						lcClassName=LOWER(MLINE(SUBSTR(lcItemTypes,lnAtPos+LEN(lcFileExt)+2),1))
					ENDIF
				ENDIF
				SELECT (lnLastSelect)
			ENDIF
			oItem=NEWOBJECT(lcClassName,lcClassLibrary)
			IF VARTYPE(oItem)=="O"
				WITH oItem
					.oHost=toBrowser
					.cID2=STRTRAN(JUSTSTEM(oFolder.cCatalog)," ","_")
					.cID=.cID2+"!"+LOWER(SYS(2015))
					.oParent=oFolder
					.oFolder=oFolder
					.cParent=oFolder.cID
					IF .oParent.lDynamic
						.lDynamic=.T.
					ENDIF
					.cProperties=lcProperties
					IF NOT EMPTY(lcText)
						.cText=lcText
					ENDIF
					IF EMPTY(lcPicture)
						lcPicture=.cPicture
					ENDIF
					IF NOT EMPTY(lcPicture) AND NOT ":"$lcPicture AND NOT "\\"$lcPicture
						lcPicture=toBrowser.cDefaultCatalogPath+lcPicture
					ENDIF
					.cPicture=lcPicture
					.RefreshPicture
					IF NOT EMPTY(lcFileName)
						.cFileName=lcFileName
					ENDIF
					IF NOT EMPTY(lcClass)
						.cClass=lcClass
					ENDIF
					IF NOT EMPTY(lcClassName)
						.cClassName=lcClassName
					ENDIF
					IF NOT EMPTY(lcClassLibrary)
						.cClassLib=lcClassLibrary
					ENDIF
					.oParent=oFolder
					.cParent=.oParent.cID
					IF .oParent.lDynamic
						.lDynamic=.T.
					ENDIF
					.oLink=oItem
					.oAction=oItem
					.oShortCutMenu=.oHost.oShortCutMenu
					.oShortCutMenu.oHost=oItem
					.cCatalog=oFolder.cCatalog
					.cCatalogPath=oFolder.cCatalogPath
					.cAlias=oFolder.cAlias
					.cSourceAlias=oFolder.cSourceAlias
					.cSourceCatalog=oFolder.cSourceCatalog
					.cSourceCatalogPath=oFolder.cSourceCatalogPath
					.nSourceRecNo=-1
					.nRecNo=-1
					.SetProperties(.cProperties)
					.cItemType=ALLTRIM(.cItemType)
					.InitProperties
					IF EMPTY(.cDesc)
						.cDesc=.cText
					ENDIF
				ENDWITH
			ENDIF
		ENDIF
		.oItemSource=oItem
		.oItem=.oItemSource.oLink
		.cCatalog=.oItem.cSourceCatalog
	ENDWITH
ENDIF
IF USED(oItem.cAlias) AND BETWEEN(oItem.nRecNo,1,RECCOUNT(oItem.cAlias))
	GO oItem.nRecNo IN (oItem.cAlias)
ENDIF
WITH toBrowser
	IF NOT .lRefreshBrowserMode
		.RefreshCaption
	ENDIF
	.cmdClassIcon.Refresh
	.edtItemDesc.Refresh
ENDWITH
WAIT CLEAR
IF TYPE("oItem.oAction")=="O" AND NOT ISNULL(oItem.oAction) AND NOT oItem.lFolder
	oItem.oAction.Selected
ENDIF
oItem=.NULL.
oFolder=.NULL.
ENDFUNC



FUNCTION brwRefreshLinks(toBrowser,tlRefreshFolders)
LOCAL oFolder,oItem,oItem2,oLink,lcLink,lcType,lcID,lnCount,lnCount2

IF toBrowser.lBrowser
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
IF tlRefreshFolders
	FOR lnCount = 1 TO toBrowser.nFolderCount
		oFolder=toBrowser.aFolderList[lnCount]
		IF ISNULL(oFolder)
			LOOP
		ENDIF
		lcLink=oFolder.cLink
		oFolder.oLink=oFolder
		IF EMPTY(lcLink)
			LOOP
		ENDIF
		lcType=oFolder.cType
		oLink=.NULL.
		FOR lnCount2 = 1 TO toBrowser.nFolderCount
			IF toBrowser.aFolderList[lnCount2].cID==lcLink
				oLink=toBrowser.aFolderList[lnCount2].oLink
				EXIT
			ENDIF
		ENDFOR
		IF NOT ISNULL(oLink)
			oFolder.oLink=oLink
			oLink=.NULL.
		ENDIF
	ENDFOR
ELSE
	FOR lnCount = 1 TO toBrowser.nItemCount
		oItem=toBrowser.aItemList[lnCount]
		IF VARTYPE(oItem)#"O" OR NOT oItem.Visible OR oItem.lDeleted
			LOOP
		ENDIF
		oItem.oLink=oItem
		lcLink=oItem.cLink
		IF EMPTY(lcLink)
			LOOP
		ENDIF
		lcType=oItem.cType
		lcID=oItem.cID
		oLink=.NULL.
		FOR lnCount2 = 1 TO toBrowser.nItemCount
			oItem2=toBrowser.aItemList[lnCount2]
			IF VARTYPE(oItem2)#"O"
				LOOP
			ENDIF
			IF oItem2.cID==lcLink
				oLink=oItem2.oLink
				EXIT
			ENDIF
		ENDFOR
		IF ISNULL(oLink)
			oLink=toBrowser.GetItem(lcLink)
		ENDIF
		IF NOT ISNULL(oLink)
			oItem.oLink=oLink.oLink
			oLink=.NULL.
		ENDIF
	ENDFOR
ENDIF
oItem=.NULL.
oFolder=.NULL.
ENDFUNC



FUNCTION brwClearProperties(toBrowser,tlItemsOnly)
LOCAL lcAlias,lcDBF,lcClass,lnClassCount,llRefreshBrowserMode
LOCAL lnCount,lcFileName,lnFileNo,oItem,llBrowser,llBrowserUsed
LOCAL laClasses[1]

IF TYPE("_screen._oCGClipBoard")=="O"
	_screen._oCGClipBoard.ReleaseObjects
ENDIF
WITH toBrowser
	llRefreshBrowserMode=.lRefreshBrowserMode
	.lRefreshBrowserMode=.T.
	llBrowser=.lBrowser
	llBrowserUsed=USED("browser")
	IF .lRelease
		IF VARTYPE(.oView)=="O"
			.oView.Release
		ENDIF
		.oView=.NULL.
	ENDIF
ENDWITH
IF toBrowser.lBrowser OR toBrowser.lRelease
	toBrowser.lBrowser=.T.
	WITH toBrowser
		FOR lnFileNo = 1 TO .nFileCount
			lcFileName=.aFiles[lnFileNo]
			IF EMPTY(lcFileName)
				LOOP
			ENDIF
			lcAlias="metadata"+ALLTRIM(STR(ASCAN(.aFiles,lcFileName)))
			IF USED(lcAlias)
				toBrowser.UpdateFormCount(-1,lcFileName)
				USE IN (lcAlias)
			ENDIF
		ENDFOR
		IF NOT EMPTY(.cAlias) AND USED(.cAlias)
			USE IN (.cAlias)
		ENDIF
		DIMENSION .aFiles[1]
		.aFiles=.F.
		.nFileCount=1
		.cFileName=""
		.cFileNamePath=""
		.lFileMode=.T.
		.lVCXSCXMode=.F.
		.lSCXMode=.F.
		.cAlias=""
		.nClassCount=0
		.nClassListIndex=-1
		.nMemberListIndex=-1
		.nClassTimeStamp=0
		.cClass=""
		.cParentClass=""
		.cClassLibrary=""
		.cBaseClass=""
		.lBrowser=llBrowser
	ENDWITH
	IF toBrowser.lRelease
		IF toBrowser.nFolderCount>0
			oItem=toBrowser.GetFolder("VFPGlry!VFPCats")
			IF VARTYPE(oItem)=="O" AND oItem.lCatalog
				oItem.oHost=toBrowser
				oItem.Cleanup(.T.)
				oItem.Release
				oItem=.NULL.
			ENDIF
		ENDIF
	ELSE
		IF toBrowser.lInitialized
			toBrowser.SavePreferences
		ENDIF
		toBrowser.lRefreshBrowserMode=llRefreshBrowserMode
		RETURN
	ENDIF
ENDIF
IF NOT tlItemsOnly
	WITH toBrowser
		IF NOT .lSwitchViewMode
			IF VARTYPE(.oView)=="O"
				.oView.Release
			ENDIF
			.oView=.NULL.
			.CloseViews(.T.)
			.cboViewType.ListIndex=1
			DO WHILE .cboViewType.ListCount>1
				.cboViewType.RemoveItem(2)
			ENDDO
			.cGallery="view_default"
			.CreateCatalog(.cGallery)
			.cCatalog=IIF(USED("catalog1"),LOWER(DBF("catalog1")),"")
		ENDIF
		.lBrowser=.F.
		.oItem=.NULL.
		.oItemSource=.NULL.
		.oFolder=.NULL.
		.oFolderSource=.NULL.
		.oCatalog=.NULL.
		.oCatalogSource=.NULL.
	ENDWITH
ENDIF
brwReleaseClassLibraries(toBrowser)
lnClassCount=0
FOR lnCount = toBrowser.nItemCount TO 1 STEP -1
	oItem=toBrowser.aItemList[lnCount]
	IF VARTYPE(oItem)#"O"
		LOOP
	ENDIF
	lcClass=LOWER(oItem.Class)+" "
	IF ASCAN(laClasses,lcClass)=0
		lnClassCount=lnClassCount+1
		DIMENSION laClasses[lnClassCount]
		laClasses[lnClassCount]=lcClass
	ENDIF
	oItem.Release
	oItem=.NULL.
ENDFOR
IF NOT tlItemsOnly
	FOR lnCount = toBrowser.nFolderCount TO 1 STEP -1
		oItem=toBrowser.aFolderList[lnCount]
		IF VARTYPE(oItem)#"O"
			LOOP
		ENDIF
		lcClass=LOWER(oItem.Class)+" "
		IF ASCAN(laClasses,lcClass)=0
			lnClassCount=lnClassCount+1
			DIMENSION laClasses[lnClassCount]
			laClasses[lnClassCount]=lcClass
		ENDIF
		oItem.Release
		oItem=.NULL.
	ENDFOR
	WITH toBrowser
		IF .lWebView
			.SetWebBrowser
		ENDIF
		.lWebView=.F.
		DIMENSION .aFolderList[1]
		.aFolderList=.NULL.
		.nFolderCount=0
		.nFolderListIndex=-1
		.nLastFolderListIndex=-1
	ENDWITH
ENDIF
WITH toBrowser
	DIMENSION .aItemList[1]
	.aItemList=.NULL.
	.nItemCount=0
ENDWITH
FOR lnCount = 1 TO lnClassCount
	lcClass=ALLTRIM(laClasses[lnCount])
	CLEAR CLASS (lcClass)
ENDFOR
IF NOT tlItemsOnly
	CLEAR CLASS (toBrowser.cFolderClass)
	CLEAR CLASS (toBrowser.cItemClass)
	CLEAR CLASS (toBrowser.cObjectClass)
	CLEAR CLASS (toBrowser.cViewClass)
	CLEAR CLASS (toBrowser.cNodeClass)
ENDIF
toBrowser.lBrowser=llBrowser
toBrowser.lRefreshBrowserMode=llRefreshBrowserMode
ENDFUNC



FUNCTION brwClearBrowser(toBrowser,tlSaveProperties)
LOCAL llLockScreen

llLockScreen=toBrowser.LockScreen
toBrowser.Lockscreen=.T.
IF NOT tlSaveProperties
	toBrowser.ClearProperties
ENDIF
WAIT CLEAR
WITH toBrowser
	.RefreshButtons
	.imgClassIcon.Visible=.F.
	.cmdClassIcon.Visible=.F.
ENDWITH
IF toBrowser.lBrowser
	WITH toBrowser
		.edtClassDesc.Value=""
		.edtClassDesc.ReadOnly=.T.
		.edtClassDesc.ScrollBars=0
		.edtMemberDesc.Value=""
		.edtMemberDesc.ReadOnly=.T.
		.edtMemberDesc.ScrollBars=0
		IF .lOutlineOCX
			.ClearNodes(.oleClassList)
			.ClearNodes(.oleMembers)
		ELSE
			.lstClassList.Clear
			.lstMembers.Clear
		ENDIF
	ENDWITH
ELSE
	WITH toBrowser
		.edtItemDesc.Value=""
		.edtItemDesc.ReadOnly=.T.
		.edtItemDesc.ScrollBars=0
		.ClearNodes(.oleFolderList)
		.oleItems.object.ListItems.Clear
	ENDWITH
ENDIF
WITH toBrowser
	.RefreshCaption
	.LockScreen=.F.
	.Draw
	.LockScreen=llLockScreen
ENDWITH
ENDFUNC



FUNCTION brwRefreshBrowser(toBrowser)
LOCAL lcMember,llLockScreen,lcFolderID,lcItemID,llRefreshItemList

IF toBrowser.lRelease OR toBrowser.lRefreshBrowserMode
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
WITH toBrowser
	IF NOT .lOutlineOCX
		.lBrowser=.T.
		.lLastBrowser=.T.
	ENDIF
	IF .lBrowser#.lLastBrowser
		.lRefreshBrowserMode=.F.
		.SwitchBrowser
	ENDIF
	.lRefreshBrowserMode=.T.
	IF .lOutlineOCX
		IF .lBrowser
			.oleClassList.Enabled=.F.
			.oleClassList.Visible=.F.
			.oleMembers.Enabled=.F.
			.oleMembers.Visible=.F.
		ELSE
			.oleFolderList.Enabled=.F.
			.oleFolderList.Visible=.F.
			.oleItems.Visible=.F.
			IF .lWebBrowser
				.oleWebBrowser.Visible=.F.
			ENDIF
		ENDIF
	ELSE
	ENDIF
	llLockScreen=.LockScreen
	.LockScreen=.T.
ENDWITH
IF toBrowser.lInitialized
	SET MESSAGE TO M_REFRESHING_LOC+[ ]+ ;
			IIF(toBrowser.lBrowser,M_CLASS_BROWSER_LOC,M_COMPONENT_GALLERY_LOC)+" ..."
	toBrowser.SetBusyState(.T.)
ENDIF
IF toBrowser.lBrowser
	WITH toBrowser
		lcMember=IIF(.nMemberListIndex>0,.aMemberList[.nMemberListIndex,1],"")
		.ClearBrowser(.T.)
		.RefreshClassList(.cClass)
		.RefreshMembers(lcMember)
	ENDWITH
ELSE
	WITH toBrowser
		IF ISNULL(.oItemSource)
			lcFolderID=""
			lcItemID=""
		ELSE
			lcFolderID=.oFolderSource.cID
			lcItemID=.oItemSource.cID
		ENDIF
		.ClearBrowser
		.RefreshFolderList
		llRefreshItemList=.lWebView
		IF NOT llRefreshItemList
			IF EMPTY(lcFolderID)
				llRefreshItemList=.T.
				.RefreshItemList
			ELSE
				llRefreshItemList=.SelectFolder(lcFolderID)
				IF NOT llRefreshItemList
					llRefreshItemList=.T.
					.RefreshItemList
				ENDIF
			ENDIF
			IF NOT EMPTY(lcItemID)
				.SelectItem(lcItemID)
			ENDIF
		ENDIF
	ENDWITH
ENDIF
WITH toBrowser
	IF .lInitialized
		.SavePreferences
	ENDIF
	IF .lOutlineOCX
		IF .lBrowser
			.oleClassList.Enabled=.T.
			.oleClassList.Visible=.T.
			.oleMembers.Enabled=.T.
			.oleMembers.Visible=.T.
		ELSE
			.oleFolderList.Enabled=.T.
			.oleFolderList.Visible=.T.
			.oleItems.Visible=(NOT .lWebView)
			IF .lWebBrowser
				.oleWebBrowser.Visible=.lWebView
			ENDIF
		ENDIF
	ELSE
	ENDIF
	.SetBusyState(.F.)
	.LockScreen=llLockScreen
	.lRefreshBrowserMode=.F.
	.RefreshCaption
ENDWITH
SELECT 0
IF NOT toBrowser.lBrowser AND NOT toBrowser.lWebView
	SET MESSAGE TO
ENDIF
ENDFUNC



FUNCTION brwSwitchBrowser(toBrowser)
LOCAL llBrowser,llGallery,llLockScreen,oColumnHeader

IF toBrowser.lRelease OR NOT toBrowser.lOutlineOCX
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
SET DATASESSION TO toBrowser.DataSessionID
llGallery=toBrowser.lBrowser
llBrowser=(NOT llGallery)
IF toBrowser.lInitialized
	toBrowser.SavePreferences
ENDIF
toBrowser.lBrowser=llBrowser
toBrowser.lLastBrowser=llBrowser
IF toBrowser.lInitialized
	SET MESSAGE TO M_SWITCHING_TO_LOC+ ;
			IIF(llBrowser,M_CLASS_BROWSER_LOC,M_COMPONENT_GALLERY_LOC)+" ..."
ENDIF
WITH toBrowser
	llLockScreen=.Lockscreen
	.LockScreen=.T.
	.cboClassType.Visible=llBrowser
	.cboViewType.Visible=llGallery
	.cmdAdd.Visible=llBrowser
	.cmdExport.Visible=llBrowser
	.cmdFind.Left=.cmdExport.Left+IIF(llBrowser,24,0)
	.cmdSubclass.Visible=llBrowser
	.cmdRename.Visible=llBrowser
	.cmdRedefine.Visible=llBrowser
	.cmdCleanup.Visible=llBrowser
	.cmdUpOneLevel.Visible=llGallery
	.cmdOptions.Visible=llGallery
	.RefreshButtons
	.edtClassDesc.Visible=(llBrowser AND .lDescriptions)
	.edtMemberDesc.Visible=(llBrowser AND .lDescriptions)
	.edtItemDesc.Visible=(llGallery AND .lDescriptions)
ENDWITH
IF toBrowser.lInitialized
	toBrowser.RefreshDescriptions
	toBrowser.cmdOpen.Refresh
ENDIF
IF llGallery AND toBrowser.oleItems.object.ColumnHeaders.Count<=1
	WITH toBrowser
		.oleItems.object.ColumnHeaders.Clear
		oColumnHeader=.oleItems.object.ColumnHeaders.Add(,"_object","Object",96)
		oColumnHeader=.oleItems.object.ColumnHeaders.Add(,"_type","Type",64)
		oColumnHeader=.NULL.
	ENDWITH
ENDIF
WITH toBrowser
	IF .lInitialized
		.SavePreferences
	ENDIF
	.cmdClassIcon.Refresh
	.oleClassList.Visible=llBrowser
	.oleMembers.Visible=llBrowser
	.oleFolderList.Visible=llGallery
	.oleItems.Visible=(NOT llBrowser AND NOT .lWebView)
	.Icon="c:\dev\browser\"+IIF(llBrowser,"browser.ico","gallery.ico")
	.RefreshCaption
	WITH .cmdBrowser
		.Picture=IIF(llBrowser,"c:\dev\browser\gallery.bmp","c:\dev\browser\browser.bmp")
		.Refresh
	ENDWITH
	IF NOT .lRelease AND .lActive
		.cmdOpen.SetFocus
	ENDIF
	IF llBrowser
		.HelpContextID=95825501
		.cmdBrowser.HelpContextID=0
		.cmdOpen.HelpContextID=0
		.cmdFind.HelpContextID=0
		.txtClassList3D.Height=.oleClassList.Height
		.txtClassList3D.Width=.oleClassList.Width
		.txtMembers3D.Height=.oleMembers.Height
		.txtMembers3D.Left=.oleMembers.Left
		.txtMembers3D.Width=.oleMembers.Width
		.shpSplitterH.Top=.edtClassDesc.Top-4
	ELSE
		.HelpContextID=189582651
		.cmdBrowser.HelpContextID=189582651
		.cmdOpen.HelpContextID=189582651
		.cmdFind.HelpContextID=189582651
		.txtClassList3D.Height=.oleFolderList.Height
		.txtClassList3D.Width=.oleFolderList.Width
		.txtMembers3D.Height=.oleItems.Height-2
		.txtMembers3D.Left=.oleItems.Left
		.txtMembers3D.Width=.oleItems.Width
		.shpSplitterH.Top=.edtItemDesc.Top-4
	ENDIF
	.shpSplitterV.Left=.txtMembers3D.Left-4
ENDWITH
IF llGallery AND toBrowser.lInitialized AND EMPTY(toBrowser.cCatalog)
	toBrowser.RefreshBrowser
ENDIF
IF toBrowser.lWebBrowser
	toBrowser.oleWebBrowser.Visible=(NOT llBrowser AND toBrowser.lWebView)
ENDIF
toBrowser.LockScreen=llLockScreen
ENDFUNC



FUNCTION brwRefreshItemDesc(toBrowser)
LOCAL oItem,oParent,lcTypeDesc,lcDesc,lcToolTipText

IF toBrowser.lRelease OR toBrowser.lBrowser
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
IF toBrowser.nFolderCount<1 OR toBrowser.lBrowser
	WITH toBrowser.edtItemDesc
		.SelLength=0
		.SelStart=0
		.ReadOnly=.T.
		.MaxLength=0
		.StatusBarText=""
		.ToolTipText=""
		.Value=""
		.ScrollBars=0
	ENDWITH
	RETURN
ENDIF
lcToolTipText=""
lcTypeDesc=""
IF toBrowser.nItemListIndex>0
	oItem=toBrowser.oItem
	DO CASE
		CASE VARTYPE(oItem)=="O"
			lcTypeDesc=oItem.cTypeDesc
			IF EMPTY(lcTypeDesc)
				oParent=oItem
				DO WHILE NOT oParent.cID==oParent.oFolder.oLink.cID
					oParent=oParent.oFolder.oLink
					IF NOT EMPTY(oParent.cItemTypeDesc)
						lcTypeDesc=oParent.cItemTypeDesc
						EXIT
					ENDIF
				ENDDO
				oParent=.NULL.
			ENDIF
	ENDCASE
ELSE
	oItem=toBrowser.oFolder
	DO CASE
		CASE VARTYPE(oItem)=="O"
			lcTypeDesc=oItem.cTypeDesc
			IF EMPTY(lcTypeDesc) AND VARTYPE(oItem)=="O"
				oParent=oItem
				DO WHILE NOT oParent.cID==oParent.oFolder.oLink.cID
					oParent=oParent.oFolder.oLink
					IF NOT EMPTY(oParent.cTypeDesc)
						lcTypeDesc=oParent.cTypeDesc
						EXIT
					ENDIF
				ENDDO
				oParent=.NULL.
			ENDIF
	ENDCASE
ENDIF
lcDesc=""
IF VARTYPE(oItem)=="O"
	lcToolTipText=LEFT(oItem.cFileName,127)
	IF EMPTY(lcToolTipText)
		IF oItem.lCatalog
			lcToolTipText=LEFT(oItem.cCatalog,127)
		ELSE
			lcToolTipText=LEFT(oItem.cText,127)
		ENDIF
	ENDIF
	lcDesc=oItem.cDesc
ENDIF
DO WHILE LEFT(lcDesc,1)==CR OR LEFT(lcDesc,1)==LF
	lcDesc=ALLTRIM(SUBSTR(lcDesc,2))
ENDDO
DO WHILE RIGHT(lcDesc,1)==CR OR RIGHT(lcDesc,1)==LF
	lcDesc=TRIM(LEFT(lcDesc,LEN(lcDesc)-1))
ENDDO
IF VARTYPE(oItem)=="O" AND oItem.lFolder AND NOT oItem.cFolderType=="web"
	IF NOT EMPTY(lcDesc)
		lcDesc=lcDesc+CR
	ENDIF
	lcDesc=lcDesc+TRANSFORM(MAX(oItem.nItemCount,0))+" "+M_ITEMS_LOC
ENDIF
IF NOT EMPTY(lcTypeDesc)
	DO WHILE LEFT(lcTypeDesc,1)==CR OR LEFT(lcTypeDesc,1)==LF
		lcTypeDesc=ALLTRIM(SUBSTR(lcTypeDesc,2))
	ENDDO
	DO WHILE RIGHT(lcTypeDesc,1)==CR OR RIGHT(lcTypeDesc,1)==LF
		lcTypeDesc=TRIM(LEFT(lcTypeDesc,LEN(lcTypeDesc)-1))
	ENDDO
	IF EMPTY(lcDesc)
		lcDesc=lcTypeDesc
	ELSE
		lcDesc=lcDesc+CR+CR+lcTypeDesc
	ENDIF
ENDIF
WITH toBrowser.edtItemDesc
	.SelLength=0
	.SelStart=0
	.ReadOnly=.T.
	.MaxLength=0
	.StatusBarText=M_ITEM_LOC+" ("+.Class+") "+M_DESCRIPTION_LOC
	.ToolTipText=lcToolTipText
	.Value=lcDesc
	.ScrollBars=IIF(EMPTY(lcDesc),0,2)
ENDWITH
oItem=.NULL.
ENDFUNC 



FUNCTION brwStartNewWindow(toBrowser,tlGallery)
LOCAL llGallery,lcFileName,lcFileName2,lcDefaultClass,llListBox,lcClassType
LOCAL lnCount,lcCount,lnWindowState,lcAlias,lcAlias2,lcFolderID,lcItemID

WITH toBrowser
	.SavePreferences
	IF tlGallery
		lcFileName=""
		lcAlias2="catalog"
		FOR lnCount = 1 TO 256
			lcCount=ALLTRIM(STR(lnCount))
			lcAlias=lcAlias2+lcCount
			IF NOT USED(lcAlias)
				EXIT
			ENDIF
			lcFileName2=LOWER(DBF(lcAlias))
			IF lcFileName2==toBrowser.cDefaultCatalog
				LOOP
			ENDIF
			IF NOT EMPTY(lcFileName)
				lcFileName=lcFileName+","
			ENDIF
			lcFileName=lcFileName+lcFileName2
		ENDFOR
		lcFolderID=IIF(ISNULL(.oFolderSource),"",.oFolderSource.cID)
		lcItemID=IIF(ISNULL(.oItemSource),"",.oItemSource.cID)
		lcDefaultClass=lcItemID
		llListBox=.F.
		lcClassType=.cViewType
	ELSE
		lcFileName=.cFileName
		FOR lnCount = 1 TO .nFileCount
			lcFileName2=.aFiles[lnCount]
			IF EMPTY(lcFileName2) OR lcFileName2==.cFileName
				LOOP
			ENDIF
			IF NOT EMPTY(lcFileName)
				lcFileName=lcFileName+","
			ENDIF
			lcFileName=lcFileName+lcFileName2
		ENDFOR
		lcFolderID=""
		lcItemID=""
		lcDefaultClass=IIF(.nMemberListIndex>0,.aMemberList[.nMemberListIndex,1],"")
		lcDefaultClass=IIF(EMPTY(lcDefaultClass),.cClass,.cClass+"."+lcDefaultClass)
		llListBox=(NOT .lOutlineOCX)
		lcClassType=.cClassType
	ENDIF
	lnWindowState=.WindowState
	DO (.cProgramName) WITH (lcFileName),(lcDefaultClass),(llListBox),(lcClassType), ;
			(lnWindowState),(tlGallery)
	IF _oBrowser=toBrowser
		RETURN .F.
	ENDIF
	WITH _oBrowser
		IF NOT EMPTY(lcFolderID)
			.SelectFolder(lcFolderID,.T.)
		ENDIF
		IF NOT EMPTY(lcItemID)
			.SelectItem(lcItemID,.T.)
		ENDIF
	ENDWITH
ENDWITH
ENDFUNC 



FUNCTION brwSetClassLibrary(toBrowser,tcClassLibraryList)
LOCAL lcClassLibraryList,lcClassLibrary,lcClassLibraryAlias,lnClassLibraryCount,lnMemLine

IF EMPTY(tcClassLibraryList)
	RETURN
ENDIF
lcClassLibraryList=LOWER(ALLTRIM(STRTRAN(STRTRAN(tcClassLibraryList,",",CR),LF,CR)))
_mline=0
FOR lnMemLine = 1 TO MEMLINES(lcClassLibraryList)
	lcClassLibrary=LOWER(ALLTRIM(MLINE(lcClassLibraryList,1,_mline)))
	IF EMPTY(lcClassLibrary) OR LEFT(lcClassLibrary,1)=="*"
		LOOP
	ENDIF
	IF EMPTY(JUSTEXT(lcClassLibrary))
		lcClassLibrary=FORCEEXT(lcClassLibrary,"vcx")
	ENDIF
	IF (NOT ":"$lcClassLibrary AND NOT "\\"$lcClassLibrary)
		lcClassLibrary=LOWER(FORCEPATH(lcClassLibrary,toBrowser.cDefaultCatalogPath))
	ENDIF
	IF EMPTY(SYS(2000,lcClassLibrary))
		toBrowser.MsgBox(M_FILE_LOC+[ "]+lcClassLibrary+[" ]+ ;
				M_DOES_NOT_EXIST_LOC+[.],16)
		SET DATASESSION TO toBrowser.DataSessionID
		toBrowser.vResult=.F.
		RETURN toBrowser.vResult
	ENDIF
	IF toBrowser.nClassLibraryCount>0 AND ASCAN(toBrowser.aClassLibrary,lcClassLibrary)>0
		RETURN
	ENDIF
	lcClassLibraryAlias=LOWER(SYS(2015))
	toBrowser.nClassLibraryCount=toBrowser.nClassLibraryCount+1
	lnClassLibraryCount=toBrowser.nClassLibraryCount
	DIMENSION toBrowser.aClassLibrary[lnClassLibraryCount,2]
	toBrowser.aClassLibrary[lnClassLibraryCount,1]=lcClassLibrary
	toBrowser.aClassLibrary[lnClassLibraryCount,2]=lcClassLibraryAlias
	IF RIGHT(lcClassLibrary,4)==".prg"
		SET PROCEDURE TO (lcClassLibrary) ADDITIVE
	ELSE
		SET CLASSLIB TO (lcClassLibrary) ALIAS (lcClassLibraryAlias) ADDITIVE
	ENDIF
ENDFOR
ENDFUNC



FUNCTION brwReleaseClassLibraries(toBrowser)
LOCAL lcClassLibrary,lcClassLibraryAlias,lcSetClassLib,lnCount

FOR lnCount = 1 TO toBrowser.nClassLibraryCount
	lcClassLibrary=toBrowser.aClassLibrary[lnCount,1]
	lcClassLibraryAlias=toBrowser.aClassLibrary[lnCount,2]
	IF RIGHT(lcClassLibrary,4)==".prg"
		IF ATC(lcClassLibrary,SET("PROCEDURE"))>0
			RELEASE PROCEDURE (lcClassLibrary)
		ENDIF
	ELSE
		lcSetClassLib=SET("CLASSLIB")
		IF ATC(lcClassLibrary,lcSetClassLib)>0 AND ;
				ATC(" ALIAS "+lcClassLibraryAlias+",",lcSetClassLib+",")>0
			RELEASE CLASSLIB ALIAS (lcClassLibraryAlias)
		ENDIF
	ENDIF
ENDFOR
toBrowser.nClassLibraryCount=0
DIMENSION toBrowser.aClassLibrary[1,2]
toBrowser.aClassLibrary=""
ENDFUNC



FUNCTION brwCopy(toBrowser,toObject,tlCut)
LOCAL oObject

toBrowser.ClearClipBoard
oObject=IIF(VARTYPE(toObject)#"O",toBrowser.oItemSource,toObject)
IF TYPE("oObject")#"O" OR ISNULL(oObject)
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
WITH _screen._oCGClipBoard
	.cHostName=toBrowser.Name
	.oItem=oObject
	.lCut=tlCut
ENDWITH
ENDFUNC



FUNCTION brwPaste(toBrowser,toTarget,tlLink,tlNoRefresh)
LOCAL oTarget,oItem,oItem2,oLastItem,oRecord,oNode,llCut,lcAppendText,lcID,lnCount,lcHost

oTarget=IIF(TYPE("toTarget")#"O" OR ISNULL(toTarget),toBrowser.oFolder,toTarget)
WITH _screen._oCGClipBoard
	oItem=.oItem
	IF VARTYPE(oItem)#"O" OR oItem=oTarget OR VARTYPE(oItem.oRecord)#"O"
		toBrowser.vResult=.F.
		RETURN toBrowser.vResult
	ENDIF
	oRecord=oItem.oRecord
	llCut=.lCut
	IF VARTYPE(oItem.oHost)#"O"
		oItem.oHost=toBrowser
	ENDIF
	lcHost=oItem.oHost.Name
	IF llCut
		IF tlLink
			toBrowser.vResult=.F.
			RETURN toBrowser.vResult
		ENDIF
		.lCut=.F.
		.oItem.Remove(.F.,.T.)
		.oItem.oHost.ClearClipBoard
	ENDIF
	oLastItem=.oItem
ENDWITH
oNode=toBrowser.CreateNode(oTarget.cAlias,oRecord)
IF ISNULL(oNode)
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
lcID=LOWER(SYS(2015))
WITH oNode
	lcAppendText=""
	.cID=lcID
	.cType=oItem.cType
	IF NOT llCut
		IF tlLink
			.cLink=oItem.cID
			lcAppendText="Link to "
		ELSE
			lcAppendText="Copy of "
		ENDIF
	ENDIF
	IF tlLink
		.cProperties=""
	ENDIF
	IF NOT EMPTY(lcAppendText)
		.cText=lcAppendText+oItem.cText
	ENDIF
	.cParent=oTarget.cID
	.oParent=oTarget
	IF .oParent.lDynamic
		.lDynamic=.T.
	ENDIF
	.cFolderPicture=oItem.cFolderPicture
	.cPicture=oItem.cPicture
	.cClassLib=oItem.ClassLibrary
	.cClassName=oItem.Class
	.cCatalog=oTarget.cCatalog
	.cAlias=oTarget.cAlias
	.cSourceCatalog=oTarget.cSourceCatalog
	.cSourceCatalogPath=oTarget.cSourceCatalogPath
	.cSourceAlias=oTarget.cSourceAlias
	.nSourceRecNo=0
	.cID2=STRTRAN(JUSTSTEM(.cCatalog)," ","_")
	.cID=.cID2+"!"+.cID
	.nIndex=0
	.WriteProperties(.T.,.T.)
ENDWITH
IF oItem.lFolder AND NOT tlLink AND NOT ISNULL(oLastItem)
	FOR lnCount = 1 TO oItem.nItemCount
		EXIT
		oItem2=toBrowser.aItemList[oItem.aItemIndexes[lnCount]]
		IF VARTYPE(oItem2)#"O"
			LOOP
		ENDIF
		_screen._oCGClipBoard.oItem=oItem2
		toBrowser.Paste(oNode,tlLink,.T.)
	ENDFOR
ENDIF
IF NOT tlNoRefresh
	oNode.Refresh(.T.)
	toBrowser.SelectItem(lcID,.T.)
ENDIF
IF NOT ISNULL(oLastItem)
	IF toBrowser.Name==lcHost
		lcID=oLastItem.cID
		oItem=IIF(oLastItem.lFolder,toBrowser.GetFolder(lcID),toBrowser.GetItem(lcID))
	ELSE
		oItem=oLastItem
	ENDIF
	_screen._oCGClipBoard.oItem=oItem
ENDIF
IF VARTYPE(oNode)=="O"
	oNode.Release
ENDIF
ENDFUNC



FUNCTION brwCreateLink(toBrowser,toObject)
LOCAL oObject,oItem,oRecord,llCut

oObject=IIF(VARTYPE(toObject)#"O",toBrowser.oItem,toObject)
IF VARTYPE(oObject)#"O" OR oObject.lCatalog
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
WITH _screen._oCGClipBoard
	oItem=.oItem
	llCut=.lCut
	.oItem=toObject
	.lCut=.F.
	IF NOT toBrowser.Copy(oObject) OR NOT toBrowser.Paste(oObject.oFolder,.T.)
		toBrowser.vResult=.F.
		RETURN toBrowser.vResult
	ENDIF
	.oItem=oItem
	.lCut=llCut
ENDWITH
ENDFUNC



FUNCTION brwGetRecordObject(toBrowser,toNode)
LOCAL oNode,oRecord,lcAlias,lnRecNo,lnLastSelect

oNode=IIF(VARTYPE(toNode)#"O",toBrowser.oItemSource,toNode)
IF TYPE("oNode")#"O" OR ISNULL(oNode)
	toBrowser.vResult=.NULL.
	RETURN .NULL.
ENDIF
lcAlias=oNode.cAlias
IF EMPTY(lcAlias) OR NOT USED(lcAlias)
	toBrowser.vResult=.NULL.
	RETURN .NULL.
ENDIF
lnLastSelect=SELECT()
SELECT (lcAlias)
lnRecNo=IIF(EOF() OR RECNO()>RECCOUNT(),0,RECNO())
GO oNode.nRecNo
oRecord=.NULL.
SCATTER MEMO NAME oRecord
IF SELECT()=lnLastSelect
	GO lnRecNo
ELSE
	SELECT (lnLastSelect)
ENDIF
toBrowser.vResult=oRecord
RETURN oRecord
ENDFUNC



FUNCTION brwCheckGalleryTableStructure(toBrowser)
LOCAL lcCatalog,lcCatalogPath,lcAlias,lcTempTable,lcStructureTable

IF TYPE("ID")#"C" OR TYPE("Properties")#"M" OR TYPE("Script")#"M"
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
lcCatalog=LOWER(DBF())
lcCatalogPath=IIF(EMPTY(lcCatalog),"",JUSTPATH(lcCatalog)+"\")
lcAlias=LOWER(ALIAS())
DO WHILE NOT toBrowser.lRelease AND TYPE("FileName")#"M"
	USE (lcCatalog) EXCLUSIVE ALIAS (lcAlias)
	IF NOT USED()
		toBrowser.cCatalog=""
		IF USED(lcAlias)
			USE IN (lcAlias)
		ENDIF
		SELECT 0
		SET MESSAGE TO
		toBrowser.MsgBox(M_FILE_LOC+[ "]+lcCatalog+[" ]+M_COULD_NOT_OPENED_EXCL_LOC,16)
		toBrowser.vResult=.F.
		RETURN toBrowser.vResult
	ENDIF
	SET FILTER TO NOT DELETED()
	LOCATE
	lcTempTable=LOWER(FULLPATH("_1"+SYS(2015),lcCatalogPath))
	lcStructureTable=LOWER(FULLPATH("_2"+SYS(2015),lcCatalogPath))
	USE (lcCatalog) EXCLUSIVE ALIAS _TempTable
	COPY TO (lcTempTable)
	COPY TO (lcStructureTable) STRUCTURE EXTENDED
	USE
	USE (lcStructureTable) EXCLUSIVE ALIAS _TempTable
	SET FILTER TO NOT DELETED()
	LOCATE
	LOCATE FOR UPPER(ALLTRIM(Field_Name))=="PARENT"
	IF NOT EOF() AND NOT Field_Type=="M"
		REPLACE Field_Type WITH "M", Field_Len WITH 4
	ENDIF
	LOCATE FOR UPPER(ALLTRIM(Field_Name))=="LINK"
	IF NOT EOF() AND NOT Field_Type=="M"
		REPLACE Field_Type WITH "M", Field_Len WITH 4
	ENDIF
	LOCATE FOR UPPER(ALLTRIM(Field_Name))=="TYPEDESC"
	IF EOF()
		LOCATE FOR UPPER(ALLTRIM(FIELD_NAME))=="DESC"
		INSERT BLANK BEFORE
		REPLACE Field_Name WITH "TYPEDESC", Field_Type WITH "M", Field_Len WITH 4
	ENDIF
	LOCATE FOR UPPER(ALLTRIM(Field_Name))=="FILENAME"
	IF EOF()
		LOCATE FOR UPPER(ALLTRIM(FIELD_NAME))=="PROPERTIES"
		INSERT BLANK
		REPLACE Field_Name WITH "FILENAME", Field_Type WITH "M", Field_Len WITH 4
	ENDIF
	LOCATE FOR UPPER(ALLTRIM(Field_Name))=="CLASS"
	IF EOF()
		LOCATE FOR UPPER(ALLTRIM(FIELD_NAME))=="SCRIPT"
		INSERT BLANK BEFORE
		REPLACE Field_Name WITH "CLASS", Field_Type WITH "M", Field_Len WITH 4
	ENDIF
	LOCATE FOR UPPER(ALLTRIM(Field_Name))=="PICTURE"
	IF EOF()
		LOCATE FOR UPPER(ALLTRIM(FIELD_NAME))=="SCRIPT"
		INSERT BLANK BEFORE
		REPLACE Field_Name WITH "PICTURE", Field_Type WITH "M", Field_Len WITH 4
	ENDIF
	LOCATE FOR UPPER(ALLTRIM(Field_Name))=="FOLDERPICT"
	IF EOF()
		LOCATE FOR UPPER(ALLTRIM(FIELD_NAME))=="SCRIPT"
		INSERT BLANK BEFORE
		REPLACE Field_Name WITH "FOLDERPICT", Field_Type WITH "M", Field_Len WITH 4
	ENDIF
	LOCATE FOR UPPER(ALLTRIM(Field_Name))=="ITEMTPDESC"
	IF EOF()
		LOCATE FOR UPPER(ALLTRIM(FIELD_NAME))=="UPDATED"
		INSERT BLANK BEFORE
		REPLACE Field_Name WITH "ITEMTPDESC", Field_Type WITH "M", Field_Len WITH 4
	ENDIF
	LOCATE FOR UPPER(ALLTRIM(Field_Name))=="VIEWS"
	IF EOF()
		LOCATE FOR UPPER(ALLTRIM(FIELD_NAME))=="UPDATED"
		INSERT BLANK BEFORE
		REPLACE Field_Name WITH "VIEWS", Field_Type WITH "M", Field_Len WITH 4
	ENDIF
	LOCATE FOR UPPER(ALLTRIM(Field_Name))=="KEYWORDS"
	IF EOF()
		LOCATE FOR UPPER(ALLTRIM(FIELD_NAME))=="VIEWS"
		INSERT BLANK
		REPLACE Field_Name WITH "KEYWORDS", Field_Type WITH "M", Field_Len WITH 4
	ENDIF
	LOCATE FOR UPPER(ALLTRIM(Field_Name))=="SRCALIAS"
	IF EOF()
		LOCATE FOR UPPER(ALLTRIM(FIELD_NAME))=="UPDATED"
		INSERT BLANK BEFORE
		REPLACE Field_Name WITH "SRCALIAS", Field_Type WITH "M", Field_Len WITH 4
	ENDIF
	LOCATE FOR UPPER(ALLTRIM(Field_Name))=="SRCRECNO"
	IF EOF()
		LOCATE FOR UPPER(ALLTRIM(FIELD_NAME))=="UPDATED"
		INSERT BLANK BEFORE
		REPLACE Field_Name WITH "SRCRECNO", Field_Type WITH "N", Field_Len WITH 6
	ENDIF
	USE
	CREATE (lcCatalog) FROM (lcStructureTable)
	USE (lcCatalog) EXCLUSIVE ALIAS (lcAlias)
	ZAP
	APPEND FROM (lcTempTable)
	REPLACE ALL Parent WITH ALLTRIM(Parent), Link WITH ALLTRIM(Link)
	brwReMapCatalogProperties(toBrowser)
	USE
	ERASE (lcTempTable+".dbf")
	ERASE (lcTempTable+".fpt")
	ERASE (lcStructureTable+".dbf")
	ERASE (lcStructureTable+".fpt")
	SELECT 0
	USE (lcCatalog) AGAIN SHARED ALIAS (lcAlias)
	SET FILTER TO NOT DELETED()
	LOCATE
ENDDO
ENDFUNC



FUNCTION brwReMapCatalogProperties(toBrowser)
LOCAL lcProperties,lcNewProperties,lcProperty,lnProperty
LOCAL lnMemLine,lcMemLine,lnCount,lnAtPos,lcValue
LOCAL laProperites[4]

laProperites[1]="cfilename"
laProperites[2]="cclass"
laProperites[3]="cpicture"
laProperites[4]="cfolderpicture"
SCAN ALL FOR NOT EMPTY(Properties)
	IF toBrowser.lRelease
		RETURN .F.
	ENDIF
	lcProperties=Properties
	lcProperties=STRTRAN(STRTRAN(lcProperties,CR+CR,CR),CR_LF+CR_LF,CR_LF)
	DO WHILE LEFT(lcProperties,1)==CR OR LEFT(lcProperties,1)==LF
		lcProperties=ALLTRIM(SUBSTR(lcProperties,2))
	ENDDO
	DO WHILE RIGHT(lcProperties,1)==CR OR RIGHT(lcProperties,1)==LF
		lcProperties=TRIM(LEFT(lcProperties,LEN(lcProperties)-1))
	ENDDO
	lcNewProperties=lcProperties
	FOR lnMemLine = 1 TO MEMLINES(lcProperties)
		lcMemLine=MLINE(lcProperties,lnMemLine)
		lnAtPos=AT("=",lcMemLine)
		IF lnAtPos=0
			LOOP
		ENDIF
		lcProperty=LOWER(ALLTRIM(LEFT(lcMemLine,lnAtPos-1)))
		IF EMPTY(lcProperty)
			LOOP
		ENDIF
		lnProperty=ASCAN(laProperites,lcProperty)
		IF lnProperty=0
			LOOP
		ENDIF
		lcValue=ALLTRIM(SUBSTR(lcMemLine,lnAtPos+1))
		lcNewProperties=STRTRAN(lcNewProperties,lcMemLine,"")
		lcNewProperties=STRTRAN(STRTRAN(lcNewProperties,CR+CR,CR),CR_LF+CR_LF,CR_LF)
		DO CASE
			CASE lnProperty=1
				REPLACE FileName WITH lcValue
			CASE lnProperty=2
				REPLACE Class WITH lcValue
			CASE lnProperty=3
				REPLACE Picture WITH lcValue
			CASE lnProperty=4
				REPLACE FolderPict WITH lcValue
		ENDCASE
	ENDFOR
	lcNewProperties=STRTRAN(STRTRAN(lcNewProperties,CR+CR,CR),CR_LF+CR_LF,CR_LF)
	DO WHILE LEFT(lcNewProperties,1)==CR OR LEFT(lcNewProperties,1)==LF
		lcNewProperties=ALLTRIM(SUBSTR(lcNewProperties,2))
	ENDDO
	DO WHILE RIGHT(lcNewProperties,1)==CR OR RIGHT(lcNewProperties,1)==LF
		lcNewProperties=TRIM(LEFT(lcNewProperties,LEN(lcNewProperties)-1))
	ENDDO
	lcNewProperties=STRTRAN(lcNewProperties,CR_LF,CR)
	IF NOT Properties==lcNewProperties
		REPLACE Properties WITH lcNewProperties
	ENDIF
ENDSCAN
ENDFUNC



FUNCTION brwRefreshView(toBrowser,toView,tcSearchAlias)
LOCAL oView,lcSearchAlias,oRecord,lcViewAlias,lcCatalog
LOCAL lcContaining,lcLookIn,lcLookInAlias,lcKeywordList,llItemName,llDescription
LOCAL llFileName,llClassName,llProperties,lcItemTypes,llMatch,llKeywordMatch
LOCAL lcText,lcContaining,lcKeyword1,lcKeyword2,lcType,lcParent,oCatalog
LOCAL lnCount,lnCount2,lnLastSelect,lnLastRecNo,lnRecNolnMatchCount
DIMENSION laKeywords1[1],laKeywords2[1]

SET DATASESSION TO (toBrowser.DataSessionID)
lcSearchAlias=IIF(TYPE("tcSearchAlias")=="C",LOWER(ALLTRIM(tcSearchAlias)),"view_default")
lcText=toView.cText
IF VARTYPE(toView)#"O" OR NOT USED(lcSearchAlias) OR ;
		EMPTY(toView.cID) OR EMPTY(lcText) OR EMPTY(toView.cViewAlias)
	toBrowser.vResult=0
	RETURN 0
ENDIF
lnLastSelect=SELECT()
lnLastRecNo=IIF(USED() AND NOT EOF(),RECNO(),0)
lcViewAlias=LOWER(toView.cViewAlias)
IF lcViewAlias=="view_default"
	toBrowser.vResult=IIF(USED(lcViewAlias),RECCOUNT(lcViewAlias),0)
	RETURN toBrowser.vResult
ENDIF
IF EMPTY(lcViewAlias) OR NOT USED(lcViewAlias)
	IF EMPTY(lcText)
		toBrowser.vResult=0
		RETURN 0
	ENDIF
	lcViewAlias="view_"+LOWER(STRTRAN(lcText," ","_"))
	lcViewAlias=toBrowser.CreateView(lcViewAlias)
ENDIF
IF NOT USED(lcViewAlias)
	toBrowser.vResult=0
	RETURN 0
ENDIF
IF lcViewAlias==lcSearchAlias
	lcSearchAlias="view_default"
ENDIF
lnMatchCount=0
WITH toView
	lcContaining=LOWER(ALLTRIM(.cContaining))
	DO CASE
		CASE EMPTY(lcContaining)
			lcContaining="*"
		CASE NOT "*"$lcContaining AND NOT "?"$lcContaining AND NOT "%"$lcContaining
			lcContaining="%"+lcContaining+"%"
	ENDCASE
	lcLookIn=LOWER(ALLTRIM(.cLookIn))
	lcLookInAlias=LOWER(ALLTRIM(.cLookInAlias))
	lcKeywordList=.cKeywordList
	llItemName=.lItemName
	llDescription=.lDescription
	llFileName=.lFileName
	llClassName=.lClassName
	llProperties=.lProperties
	lcItemTypes=LOWER(ALLTRIM(.cItemTypes))
ENDWITH
DIMENSION laKeywords1[1]
laKeywords1=""
IF NOT EMPTY(lcKeywordList)
	brwKeywordListToArray(lcKeywordList,@laKeywords1)
ENDIF
SELECT (lcViewAlias)
ZAP
lcCatalog=LOWER(SYS(2015))
APPEND BLANK
REPLACE TYPE WITH "FOLDER", ID WITH lcCatalog, Text WITH lcText
SELECT (lcSearchAlias)
WITH toBrowser
	SCAN ALL FOR NOT EMPTY(SrcAlias)
		lcType=UPPER(ALLTRIM(Type))
		IF INLIST(lcType+" ","OBJECT ","VIEW ")
			oRecord=.NULL.
			SCATTER MEMO NAME oRecord
			SELECT (lcViewAlias)
			APPEND BLANK
			IF lcType=="VIEW"
				oRecord.Parent=lcCatalog
			ENDIF
			GATHER MEMO NAME oRecord
			oRecord=.NULL.
			SELECT (lcSearchAlias)
			LOOP
		ENDIF
		IF NOT lcType=="ITEM" OR (NOT EMPTY(lcLookInAlias) AND ;
				NOT LOWER(SrcAlias)==lcLookInAlias) AND ;
				(lcType=="ITEM" OR NOT LOWER(SrcAlias)=="catalog1")
				
			LOOP
		ENDIF
		llMatch=(EMPTY(lcContaining) OR lcContaining=="*")
		IF NOT llMatch
			llMatch=((llItemName AND .WildCardMatch(lcContaining,Text)) OR ;
					(llDescription AND .WildCardMatch(lcContaining,Desc)) OR ;
					(llFileName AND .WildCardMatch(lcContaining,FileName)) OR ;
					(llClassName AND .WildCardMatch(lcContaining,Class)) OR ;
					(llProperties AND .WildCardMatch(lcContaining,Properties)))
			IF NOT llMatch
				LOOP
			ENDIF
		ENDIF
		llKeywordMatch=(EMPTY(Keywords) AND EMPTY(lcKeywordList))
		IF NOT llKeywordMatch
			DIMENSION laKeywords2[1]
			laKeywords2=""
			brwKeywordListToArray(Keywords,@laKeywords2)
			FOR lnCount = 1 TO ALEN(laKeywords1)
				lcKeyword1=laKeywords1[lnCount]
				FOR lnCount2 = 1 TO ALEN(laKeywords2)
					lcKeyword2=laKeywords2[lnCount2]
					IF .WildCardMatch(lcKeyword1,lcKeyword2)
						llKeywordMatch=.T.
						EXIT
					ENDIF
				ENDFOR
				IF llKeywordMatch
					EXIT
				ENDIF
			ENDFOR
		ENDIF
		IF NOT llKeywordMatch
			LOOP
		ENDIF
		oRecord=.NULL.
		SCATTER MEMO NAME oRecord
		IF EMPTY(ClassName) AND NOT EMPTY(Parent)
			lnRecNo=RECNO()
			DO WHILE .T.
				lcParent=LOWER(ALLTRIM(Parent))
				IF EMPTY(lcParent)
					EXIT
				ENDIF
				LOCATE FOR LOWER(ALLTRIM(ID))==lcParent
				IF EOF()
					EXIT
				ENDIF
				IF NOT EMPTY(ItemClass)
					oRecord.ClassName=LOWER(ALLTRIM(ItemClass))
					IF EMPTY(oRecord.ClassLib) AND NOT EMPTY(ClassLib)
						oRecord.ClassLib=LOWER(ALLTRIM(ClassLib))
					ENDIF
					EXIT
				ENDIF
			ENDDO
			GO lnRecNo
		ENDIF
		SELECT (lcViewAlias)
		APPEND BLANK
		oRecord.Parent=lcCatalog
		GATHER MEMO NAME oRecord
		oRecord=.NULL.
		SELECT (lcSearchAlias)
		lnMatchCount=lnMatchCount+1
	ENDSCAN
ENDWITH
SELECT (lnLastSelect)
IF USED() AND BETWEEN(lnLastRecNo,1,RECCOUNT())
	GO lnLastRecNo
ENDIF
toBrowser.vResult=lnMatchCount
RETURN lnMatchCount
ENDFUNC



FUNCTION brwKeywordListToArray(tcKeywordList,taKeywords)
LOCAL lcKeywordList,lnKeywordCount,lcList,lcKeyword

lcKeywordList=LOWER(ALLTRIM(CHRTRAN(tcKeywordList,TAB+CR+LF+",;","     ")))
DIMENSION taKeywords[1]
taKeywords=""
lnKeywordCount=0
IF EMPTY(lcKeywordList)
	RETURN lnKeywordCount
ENDIF
lcList=lcKeywordList
DO WHILE NOT EMPTY(lcList)
	lnKeywordCount=lnKeywordCount+1
	lnAtPos=AT(" ",lcList)
	IF lnAtPos=0
		lcKeyword=ALLTRIM(lcList)
		lcList=""
	ELSE
		lcKeyword=ALLTRIM(LEFT(lcList,lnAtPos-1))
		lcList=ALLTRIM(SUBSTR(lcList,lnAtPos+1))
	ENDIF
	IF EMPTY(lcKeyword)
		LOOP
	ENDIF
	DIMENSION taKeywords[lnKeywordCount]
	taKeywords[lnKeywordCount]=lcKeyword
ENDDO
RETURN lnKeywordCount
ENDFUNC



FUNCTION brwCreateView(toBrowser,tcAlias,tcFileName)
LOCAL lcAlias,lcFileName,lcViewName,lcViewItem,oRecord
LOCAL llMatch,lnCount,lnLastSelect

lcAlias=IIF(EMPTY(tcAlias),LOWER(SYS(2015)),STRTRAN(LOWER(ALLTRIM(tcAlias))," ","_"))
lcFileName=IIF(EMPTY(tcFileName),"",ALLTRIM(tcFileName))
IF lcAlias=="view_" OR lcAlias==toBrowser.cGallery OR ;
		NOT toBrowser.CreateCatalog(lcAlias,lcFileName)
	toBrowser.vResult=""
	RETURN ""
ENDIF
lnLastSelect=SELECT()
SELECT (lcAlias)
*INDEX ON UPPER(Type)+IIF(EMPTY(Parent)," ",UPPER(PADR(Text,50))) TAG Type
*Bug 607192: make fixed length index key
INDEX ON UPPER(Type+PADR(IIF(EMPTY(Parent),"",Text),50)) TAG Type

SELECT (lnLastSelect)
IF NOT LEFT(lcAlias,5)=="view_"
	toBrowser.vResult=lcAlias
	RETURN lcAlias
ENDIF
lcViewName=STRTRAN(SUBSTR(lcAlias,6),"_"," ")
llMatch=.F.
WITH toBrowser.cboViewType
	FOR lnCount = 1 TO .ListCount
		lcViewItem=.List[lnCount]
		IF NOT llMatch AND LOWER(lcViewItem)==LOWER(lcViewName)
			llMatch=.T.
			EXIT
		ENDIF
	ENDFOR
	IF NOT llMatch
		.AddItem(PROPER(lcViewName))
	ENDIF
ENDWITH
toBrowser.vResult=lcAlias
RETURN lcAlias
ENDFUNC



FUNCTION brwCreateCatalog(toBrowser,tcAlias,tcFileName)
LOCAL lcFileName,lcAlias,lnLastSelect,lnLastRecNo,lcID
LOCAL laFields[1]

lcAlias=IIF(EMPTY(tcAlias),"",STRTRAN(LOWER(ALLTRIM(tcAlias))," ","_"))
lcFileName=IIF(EMPTY(tcFileName),"",ALLTRIM(tcFileName))
IF (EMPTY(lcAlias) AND EMPTY(lcFileName)) OR NOT USED("catalog1")
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
lnLastSelect=SELECT()
lnLastRecNo=IIF(USED() AND NOT EOF(),RECNO(),0)
IF NOT EMPTY(lcAlias) AND USED(lcAlias)
	IF EMPTY(lcFileName)
		SELECT (lcAlias)
		ZAP
		SELECT (lnLastSelect)
		RETURN
	ENDIF
	USE IN (lcAlias)
ENDIF
AFIELDS(laFields,"catalog1")
SELECT 0
IF EMPTY(lcFileName)
	CREATE CURSOR (lcAlias) FROM ARRAY laFields
ELSE
	CREATE TABLE (lcFileName) FROM ARRAY laFields
	IF NOT USED()
		SELECT (lnLastSelect)
		IF USED() AND BETWEEN(lnLastRecNo,1,RECCOUNT())
			GO lnLastRecNo
		ENDIF
		toBrowser.vResult=.F.
		RETURN toBrowser.vResult
	ENDIF	
	IF EMPTY(lcAlias)
		lcID=LOWER(SYS(2015))
		APPEND BLANK
		REPLACE Type WITH "FOLDER", ;
				ID WITH lcID, ;
				Text WITH FORCEEXT(JUSTFNAME(lcFileName),"")
		SELECT (lnLastSelect)
		IF USED() AND BETWEEN(lnLastRecNo,1,RECCOUNT())
			GO lnLastRecNo
		ENDIF
		RETURN
	ENDIF
	USE (lcFileName) EXCLUSIVE ALIAS (lcAlias)
	SET FILTER TO NOT DELETED()
	LOCATE
ENDIF
IF NOT USED(lcAlias)
	SELECT (lnLastSelect)
	IF USED() AND BETWEEN(lnLastRecNo,1,RECCOUNT())
		GO lnLastRecNo
	ENDIF
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF	
CURSORSETPROP("Buffering",1)
SET FILTER TO NOT DELETED()
LOCATE
SELECT (lnLastSelect)
IF USED() AND BETWEEN(lnLastRecNo,1,RECCOUNT())
	GO lnLastRecNo
ENDIF
ENDFUNC



FUNCTION brwCreateNode(toBrowser,tvAlias,tvType,tcFileName,tlRefresh,tlNoWriteProperties)
LOCAL lcAlias,lcType,oRecord,oNode,oFolder,lcClassLibrary,lcClassLibraryAlias,oItem
LOCAL llCopyNode,lcID,lcScriptCode,lcText,lcText2,lnDuplicateCount,lcClass,lcNewClass
LOCAL lcItemTypes,lcGetFileExt,lcFileName,lcFileExt,lnRecNo,lnLastRecNo,lnLastSelect
LOCAL lnCount,lnAtPos,lnMaxCount,llAddFile,lcSourceAlias,lcSourceCatalog

oFolder=.NULL.
lnRecNo=0
llAddFile=.F.
lcNewClass=""
lcClass=""
lcClassLibrary=""
lcFileName=IIF(EMPTY(tcFileName),"",LOWER(ALLTRIM(tcFileName)))
DO CASE
	CASE TYPE("tvAlias")=="C"
		lcAlias=LOWER(ALLTRIM(tvAlias))
	CASE TYPE("tvAlias")=="O"
		lcAlias="itemtypes"
		IF NOT EMPTY(tvType) AND TYPE("tvType")=="N"
			lnRecNo=tvType
		ENDIF
		DO CASE
			CASE NOT EMPTY(lcFileName)
				llAddFile=.T.
				oFolder=tvAlias
				lcClass=tvType
			CASE lnRecNo=0 OR NOT BETWEEN(lnRecNo,1,RECCOUNT("itemtypes"))
				lnRecNo=0
				oFolder=tvAlias
				lcAlias=oFolder.cSourceAlias
			OTHERWISE
				oFolder=tvAlias
		ENDCASE
	OTHERWISE
		lcAlias=""
ENDCASE
IF EMPTY(lcAlias) OR TYPE("lcAlias")#"C" OR NOT USED(lcAlias)
	toBrowser.MsgBox(M_NODE_LOC+[ ]+M_COULD_NOT_BE_CREATED_LOC+[.  ]+ ;
			M_NODE_LOC+[ ]+M_ERROR_LOC+[ 1],16)
	toBrowser.vResult=.NULL.
	RETURN .NULL.
ENDIF
lnLastSelect=SELECT()
lnLastRecNo=IIF(USED() AND NOT EOF(),RECNO(),0)
IF NOT ISNULL(oFolder)
	SELECT itemtypes
	SET ORDER TO
	IF NOT llAddFile
		GO lnRecNo
		lcType=UPPER(ALLTRIM(MLINE(Property,1)))
		lcClass=LOWER(ALLTRIM(MLINE(Class,1)))
	ELSE
		lnRecNo=0
		IF EMPTY(tvType)
			toBrowser.MsgBox(M_NODE_LOC+[ ]+M_COULD_NOT_BE_CREATED_LOC+[.  ]+ ;
					M_NODE_LOC+[ ]+M_ERROR_LOC+[ 2],16)
			SELECT (lnLastSelect)
			toBrowser.vResult=.NULL.
			RETURN .NULL.
		ENDIF
		lcType=ALLTRIM(tvType)
		DO CASE
			CASE lcType=="FOLDER"
				lcClass=toBrowser.cFolderClass
			CASE lcType=="ITEM"
				lcClass=toBrowser.cItemClass
			CASE lcType=="OBJECT"
				lcClass=toBrowser.cObjectClass
			CASE lcType=="VIEW"
				lcClass=toBrowser.cViewClass
			CASE lcType=="NODE"
				lcClass=toBrowser.cNodeClass
			OTHERWISE
				LOCATE FOR LOWER(ALLTRIM(Class))==LOWER(ALLTRIM(lcType))
				IF EOF()
					SELECT (lnLastSelect)
					toBrowser.MsgBox(M_NODE_LOC+[ ]+M_COULD_NOT_BE_CREATED_LOC+[.  ]+ ;
							M_NODE_LOC+[ ]+M_ERROR_LOC+[ 3],16)
					toBrowser.vResult=.NULL.
					RETURN .NULL.
				ENDIF
				lnRecNo=RECNO()
				lcType=UPPER(ALLTRIM(MLINE(Property,1)))
				lcClass=LOWER(ALLTRIM(MLINE(Class,1)))
		ENDCASE
	ENDIF
	IF EMPTY(lcType)
		SELECT (lnLastSelect)
		toBrowser.MsgBox(M_NODE_LOC+[ ]+M_COULD_NOT_BE_CREATED_LOC+[.  ]+ ;
				M_NODE_LOC+[ ]+M_ERROR_LOC+[ 4],16)
		toBrowser.vResult=.NULL.
		RETURN .NULL.
	ENDIF
	IF NOT llAddFile
		lcGetFileExt=LOWER(ALLTRIM(GetFileExt))
		IF NOT EMPTY(lcGetFileExt)
			IF ATC("htm",lcGetFileExt)>0
				lcFileName=toBrowser.oFolder.GetFileAddress(.T.,lcGetFileExt)
			ELSE
				DO WHILE .T.
					lcFileName=toBrowser.GetFile(lcGetFileExt,.T.)
					IF EMPTY(lcFileName) OR "/"$lcFileName OR ","$lcFileName OR ;
							FILE(lcFileName)
						EXIT
					ENDIF
					MESSAGEBOX(M_FILE_LOC+[ "]+lcFileName+[" ]+M_NOT_FOUND_LOC+[.],16, ;
							toBrowser.Caption)
				ENDDO
			ENDIF
			lnAtPos=AT(",",lcFileName)
			IF lnAtPos>0
				lcNewClass=ALLTRIM(SUBSTR(lcFileName,lnAtPos+1))
				lcFileName=ALLTRIM(LEFT(lcFileName,lnAtPos-1))
			ENDIF
			IF EMPTY(lcFileName)
				SELECT (lnLastSelect)
				toBrowser.vResult=.NULL.
				RETURN .NULL.
			ENDIF
		ENDIF
	ENDIF
	lcFileExt=JUSTEXT(lcFileName)
	IF NOT EMPTY(lcFileExt)
		lcItemTypes=ALLTRIM(ItemTypes)
		lnAtPos=ATC(CR+lcFileExt+"=",lcItemTypes)
		IF lnAtPos>0
			lcClass=LOWER(MLINE(SUBSTR(lcItemTypes,lnAtPos+LEN(lcFileExt)+2),1))
		ENDIF
	ENDIF
	IF NOT EMPTY(ClassLib)
		lcClassLibrary=LOWER(ALLTRIM(MLINE(ClassLib,1)))
		lcClass=lcClassLibrary+","+lcClass
	ENDIF
	oNode=toBrowser.CreateNode(oFolder.cSourceAlias,lcClass)
	IF ISNULL(oNode)
		SELECT (lnLastSelect)
		toBrowser.vResult=.NULL.
		RETURN .NULL.
	ENDIF
	lcAlias=tvAlias.cAlias
	WITH oNode
		.cAlias=lcAlias
		.oFolder=oFolder
		.oParent=.oFolder
		.cParent=.oParent.cID
		IF .oParent.lDynamic
			.lDynamic=.T.
		ENDIF
		IF EMPTY(lcFileName)
			lcText=M_NEW_LOC+" "+CHRTRAN(ALLTRIM(Text),"*~\<>","")
		ELSE
			lcText=IIF(NOT EMPTY(lcNewClass),lcNewClass,JUSTFNAME(lcFileName))
		ENDIF
		lcClassLibrary=LOWER(.FullPath(lcClassLibrary))
		lnDuplicateCount=0
		FOR lnCount = 1 TO toBrowser.nItemCount
			oItem=toBrowser.aItemList[lnCount]
			IF VARTYPE(oItem)#"O" OR NOT oItem.cParent==.cParent OR ;
					NOT oItem.Visible OR oItem.lDeleted
				LOOP
			ENDIF
			lcText2=ALLTRIM(LOWER(oItem.cText))
			lnAtPos=RAT("(",lcText2)
			IF lnAtPos>0
				lnMaxCount=VAL(SUBSTR(lcText2,lnAtPos+1))
				lcText2=ALLTRIM(LEFT(lcText2,lnAtPos-1))
			ELSE
				lnMaxCount=0
			ENDIF
			IF lcText2==LOWER(lcText)
				lnDuplicateCount=MAX(lnDuplicateCount+1,lnMaxCount)
			ENDIF
		ENDFOR
		oItem=.NULL.
		IF lnDuplicateCount>0
			lcText=lcText+" ("+ALLTRIM(STR(lnDuplicateCount+1))+")"
		ENDIF
		IF EMPTY(.cText)
			.cText=lcText
		ENDIF
		IF NOT EMPTY(Desc)
			.cDesc=ALLTRIM(Desc)
		ENDIF
		IF NOT EMPTY(lcClassLibrary)
			.cClassLib=lcClassLibrary
		ENDIF
		IF NOT EMPTY(ItemClass)
			.cItemClass=ALLTRIM(MLINE(ItemClass,1))
		ENDIF
		IF NOT EMPTY(lcFileName)
			.cFileName=lcFileName
		ENDIF
		IF NOT EMPTY(lcNewClass)
			.cClass=lcNewClass
		ENDIF
		IF NOT EMPTY(.cPicture)
			.cPicture=LOWER(brwImagePictureFile(toBrowser,.FullPath(.cPicture)))
		ENDIF
		IF NOT EMPTY(.cFolderPicture)
			.cFolderPicture=LOWER(brwImagePictureFile(toBrowser,.FullPath(.cFolderPicture)))
		ENDIF
		lcScriptCode=ALLTRIM(Script)
		SELECT 0
		.SetProperties(.cProperties)
		IF NOT EMPTY(lcScriptCode)
			.RunCode(lcScriptCode)
		ENDIF
		IF NOT tlNoWriteProperties
			.WriteProperties(.T.,.T.)
		ENDIF
		IF tlRefresh
			lcID=.cID
			toBrowser.RefreshBrowser
			toBrowser.SelectItem(lcID,.T.)
		ENDIF
	ENDWITH
	SELECT 0
	toBrowser.vResult=oNode
	RETURN oNode
ENDIF
llCopyNode=.F.
oRecord=.NULL.
DO CASE
	CASE TYPE("tvType")=="C"
		lcType=UPPER(ALLTRIM(tvType))
	CASE TYPE("tvType")=="O"
		oRecord=tvType
		IF PEMSTATUS(tvType,"ParentClass",5)
			IF NOT PEMSTATUS(oRecord,"cType",5) OR NOT PEMSTATUS(oRecord,"cAlias",5) OR ;
					NOT PEMSTATUS(oRecord,"nRecNo",5) OR NOT USED(oRecord.cAlias) OR ;
					oRecord.nRecNo<=0
				toBrowser.MsgBox(M_NODE_LOC+[ ]+M_COULD_NOT_BE_CREATED_LOC+[.  ]+ ;
						M_NODE_LOC+[ ]+M_ERROR_LOC+[ 5],16)
				toBrowser.vResult=.NULL.
				RETURN .NULL.
			ENDIF
			llCopyNode=.T.
			oRecord=tvType.oRecord
			IF ISNULL(oRecord)
				toBrowser.MsgBox(M_NODE_LOC+[ ]+M_COULD_NOT_BE_CREATED_LOC+[.  ]+ ;
						M_NODE_LOC+[ ]+M_ERROR_LOC+[ 6],16)
				toBrowser.vResult=.NULL.
				RETURN .NULL.
			ENDIF
		ENDIF
		IF NOT PEMSTATUS(oRecord,"Type",5)
			toBrowser.MsgBox(M_NODE_LOC+[ ]+M_COULD_NOT_BE_CREATED_LOC+[.  ]+ ;
					M_NODE_LOC+[ ]+M_ERROR_LOC+[ 7],16)
			toBrowser.vResult=.NULL.
			RETURN .NULL.
		ENDIF
		lcType=UPPER(ALLTRIM(oRecord.Type))
	OTHERWISE
			toBrowser.MsgBox(M_NODE_LOC+[ ]+M_COULD_NOT_BE_CREATED_LOC+[.  ]+ ;
					M_NODE_LOC+[ ]+M_ERROR_LOC+[ 8],16)
		toBrowser.vResult=.NULL.
		RETURN .NULL.
ENDCASE
IF EMPTY(lcClass)
	DO CASE
		CASE lcType=="FOLDER"
			lcClass=toBrowser.cFolderClass
		CASE lcType=="ITEM"
			lcClass=toBrowser.cItemClass
		CASE lcType=="OBJECT"
			lcClass=toBrowser.cObjectClass
		CASE lcType=="VIEW"
			lcClass=toBrowser.cViewClass
		CASE lcType=="NODE"
			lcClass=toBrowser.cNodeClass
		OTHERWISE
			lcClass=LOWER(lcType)
			lcType=""
			lnAtPos=AT(",",lcClass)
			IF lnAtPos>0
				lcClassLibrary=LOWER(ALLTRIM(MLINE(LEFT(lcClass,lnAtPos-1),1)))
				lcClass=LOWER(ALLTRIM(SUBSTR(lcClass,lnAtPos+1)))
			ENDIF
			IF EMPTY(lcClass)
				lcClass=toBrowser.cItemClass
			ENDIF
	ENDCASE
ENDIF
lcSourceAlias=lcAlias
lcSourceCatalog=LOWER(DBF(lcSourceAlias))
lcID=LOWER(SYS(2015))
lcClassLibraryAlias=LOWER(SYS(2015))
IF EMPTY(lcClassLibrary)
	lcClassLibrary=toBrowser.cDefaultCatalogClassLibrary
ELSE
	IF EMPTY(JUSTEXT(lcClassLibrary))
		lcClassLibrary=FORCEEXT(lcClassLibrary,"vcx")
	ENDIF
	lcClassLibrary=LOWER(FORCEPATH(lcClassLibrary,toBrowser.cDefaultCatalogPath))
	IF EMPTY(SYS(2000,lcClassLibrary))
		lcClassLibrary=LOWER(FORCEPATH(lcClassLibrary,JUSTPATH(lcSourceCatalog)))
	ENDIF
ENDIF
oNode=NEWOBJECT(lcClass,lcClassLibrary)
IF TYPE("oNode")#"O" OR ISNULL(oNode)
	SELECT (lnLastSelect)
	IF USED() AND BETWEEN(lnLastRecNo,1,RECCOUNT())
		GO lnLastRecNo
	ENDIF
	toBrowser.MsgBox(M_NODE_LOC+[ ]+M_COULD_NOT_BE_CREATED_LOC+[.  ]+ ;
			M_NODE_LOC+[ ]+M_ERROR_LOC+[ 9],16)
	toBrowser.vResult=.NULL.
	RETURN .NULL.
ENDIF
WITH oNode
	SELECT (lcAlias)
	.oHost=toBrowser
	.oRecord=oRecord
	IF NOT EMPTY(lcType)
		.cType=lcType
	ELSE
		.cType=IIF(.lFolder,"FOLDER","ITEM")
		.cClassName=LOWER(.Class)
		.cClassLib=LOWER(.ClassLibrary)
	ENDIF
	.cSourceAlias=lcSourceAlias
	.cSourceCatalog=lcSourceCatalog
	.cSourceCatalogPath=IIF(EMPTY(.cSourceCatalog),"",JUSTPATH(.cSourceCatalog)+"\")
	.oLink=oNode
	.oAction=oNode
	.oShortCutMenu=.oHost.oShortCutMenu
	.oShortCutMenu.oHost=oNode
	.cAlias=lcAlias
	IF NOT ISNULL(oRecord)
		IF llCopyNode
			WITH oRecord
				.ID=lcID
				.SrcAlias=tvType.cSourceAlias
				.SrcRecNo=0
				.Updated={:}
			ENDWITH
		ENDIF
		APPEND BLANK
		GATHER MEMO NAME oRecord
		.nRecNo=RECNO()
		.ReadProperties
		.SetProperties(.cProperties)
		IF llCopyNode
			.cSourceAlias=oRecord.SrcAlias
			.nSourceRecNo=oRecord.SrcRecNo
		ELSE
			.nSourceRecNo=-1
		ENDIF
	ENDIF
	IF EMPTY(.cID)
		.cID=lcID
	ENDIF
	IF EMPTY(.cType)
		.cType=lcType
	ENDIF
ENDWITH
SELECT (lnLastSelect)
IF USED() AND BETWEEN(lnLastRecNo,1,RECCOUNT())
	GO lnLastRecNo
ENDIF
IF tlRefresh
	lcID=oNode.cID
	toBrowser.RefreshBrowser
	toBrowser.SelectItem(lcID,.T.)
ENDIF
toBrowser.vResult=oNode
RETURN oNode
ENDFUNC



FUNCTION brwReadProperties(toNode)
LOCAL toBrowser,lnLastSelect

toBrowser=toNode.oHost
SET DATASESSION TO (toBrowser.DataSessionID)
IF toNode.nRecNo<=0 OR EMPTY(toNode.cAlias) OR NOT USED(toNode.cAlias)
	toNode.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
WITH toNode
	lnLastSelect=SELECT()
	SELECT (.cAlias)
	GO .nRecNo
	.cType=ALLTRIM(Type)
	.cID=ALLTRIM(ID)
	.cParent=ALLTRIM(Parent)
	.cLink=ALLTRIM(Link)
	IF NOT EMPTY(Text)
		.cText=ALLTRIM(Text)
	ENDIF
	IF NOT EMPTY(TypeDesc)
		.cTypeDesc=ALLTRIM(TypeDesc)
	ENDIF
	IF NOT EMPTY(Desc)
		.cDesc=ALLTRIM(Desc)
	ENDIF
	IF NOT EMPTY(Properties)
		.cProperties=ALLTRIM(Properties)
	ENDIF
	IF NOT EMPTY(FileName)
		.cFileName=MLINE(FileName,1)
	ENDIF
	IF NOT EMPTY(.cFileName)
		.cFileName=LOWER(.FullPath(.cFileName))
	ENDIF
	IF NOT EMPTY(Class)
		.cClass=LOWER(ALLTRIM(MLINE(Class,1)))
	ENDIF
	IF NOT EMPTY(Picture)
		.cPicture=MLINE(Picture,1)
	ENDIF
	IF NOT EMPTY(.cPicture)
		.cPicture=LOWER(brwImagePictureFile(toBrowser,.FullPath(.cPicture)))
	ENDIF
	IF NOT EMPTY(FolderPict)
		.cFolderPicture=MLINE(FolderPict,1)
	ENDIF
	IF NOT EMPTY(.cFolderPicture)
		.cFolderPicture=LOWER(brwImagePictureFile(toBrowser,.FullPath(.cFolderPicture)))
	ENDIF
	IF NOT EMPTY(Script)
		.cScript=ALLTRIM(Script)
	ENDIF
	IF NOT EMPTY(ClassLib)
		.cClassLib=MLINE(ClassLib,1)
	ENDIF
	IF NOT EMPTY(.cClassLib)
		.cClassLib=LOWER(.FullPath(.cClassLib))
	ENDIF
	IF NOT EMPTY(ClassName)
		.cClassName=LOWER(ALLTRIM(MLINE(ClassName,1)))
	ENDIF
	IF NOT EMPTY(ItemClass)
		.cItemClass=LOWER(ALLTRIM(MLINE(ItemClass,1)))
	ENDIF
	IF NOT EMPTY(ItemTpDesc)
		.cItemTpDesc=ALLTRIM(ItemTpDesc)
	ENDIF
	IF NOT EMPTY(Views)
		.cViews=ALLTRIM(Views)
	ENDIF
	IF NOT EMPTY(Keywords)
		.cKeywords=ALLTRIM(Keywords)
	ENDIF
	.tUpdated=Updated
	.cComment=ALLTRIM(Comment)
	.cUser=ALLTRIM(User)
	.SetProperties(.cProperties)
ENDWITH
SELECT (lnLastSelect)
ENDFUNC



FUNCTION brwWriteProperties(toNode,tlUpdateSource,tlAutoAdd)
LOCAL toBrowser,lnLastSelect,lcType,oRecord,lcProperties,oRecord,lcClauses,lcClass
LOCAL oParent,lcFileName,lcPicture,lcFolderPicture,lcClassLib,lnLastMLine
LOCAL lnAtPos,lcProperty,lcProperty2,lcValue,lvValue,lvDefaultValue,lcDesc
LOCAL lcAlias,lcSourceCatalog,lcSourceCatalogPath,lcSourceAlias,lcPictureFile

toBrowser=toNode.oHost
SET DATASESSION TO (toBrowser.DataSessionID)
lcAlias=LOWER(toNode.cAlias)
IF EMPTY(lcAlias) OR NOT USED(lcAlias)
	toNode.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
lnLastMLine=_mline
SET DATASESSION TO toBrowser.DataSessionID
lnLastSelect=SELECT()
SELECT (lcAlias)
WITH toNode
	lcType=UPPER(ALLTRIM(.cType))
	lcClass=LOWER(ALLTRIM(.cClassName))
	IF EMPTY(lcClass)
		oParent=.oParent
		IF ISNULL(oParent) AND NOT EMPTY(.cParent)
			oParent=toBrowser.GetFolder(.cParent,.T.)
		ENDIF
		IF NOT ISNULL(oParent)
			DO WHILE .T.
				lcClass=LOWER(ALLTRIM(oParent.cItemClass))
				IF NOT EMPTY(lcClass) OR oParent.cID==oParent.oFolder.cID
					EXIT
				ENDIF
				oParent=oParent.oFolder
			ENDDO
		ENDIF
		oParent=.NULL.
	ENDIF
	IF EMPTY(lcClass)
		lcClass=LOWER(ALLTRIM(.Class))
	ENDIF
	IF .nRecNo<=0
		APPEND BLANK
		.nRecNo=RECNO()
	ELSE
		IF NOT BETWEEN(.nRecNo,1,RECCOUNT())
			SELECT (lnLastSelect)
			toNode.vResult=.F.
			RETURN toBrowser.vResult
		ENDIF
		GO .nRecNo
	ENDIF
	lcProperties=.cProperties
	IF ATC("lFullPath=",lcProperties)>0
		brwPropertyStuff(@lcProperties,"lFullPath",IIF(.lFullPath,".T.",".F."), ;
				IIF(GETPEM(.Class,"lFullPath"),".T.",".F."),tlAutoAdd)
	ENDIF
	IF .lView
		brwPropertyStuff(@lcProperties,"cContaining",.cContaining, ;
					GETPEM(.Class,"cContaining"),.T.)
		brwPropertyStuff(@lcProperties,"cLookIn",.cLookIn, ;
					GETPEM(.Class,"cLookIn"),.T.)
		brwPropertyStuff(@lcProperties,"cKeywordList",.cKeywordList, ;
					GETPEM(.Class,"cKeywordList"),.T.)
		brwPropertyStuff(@lcProperties,"lItemName",IIF(.lItemName,".T.",".F."), ;
				IIF(GETPEM(.Class,"lItemName"),".T.",".F."),.T.)
		brwPropertyStuff(@lcProperties,"lDescription",IIF(.lDescription,".T.",".F."), ;
				IIF(GETPEM(.Class,"lDescription"),".T.",".F."),.T.)
		brwPropertyStuff(@lcProperties,"lFileName",IIF(.lFileName,".T.",".F."), ;
				IIF(GETPEM(.Class,"lFileName"),".T.",".F."),.T.)
		brwPropertyStuff(@lcProperties,"lClassName",IIF(.lClassName,".T.",".F."), ;
				IIF(GETPEM(.Class,"lClassName"),".T.",".F."),.T.)
		brwPropertyStuff(@lcProperties,"lProperties",IIF(.lProperties,".T.",".F."), ;
				IIF(GETPEM(.Class,"lProperties"),".T.",".F."),.T.)
		brwPropertyStuff(@lcProperties,"cItemTypes",.cItemTypes, ;
					GETPEM(.Class,"cItemTypes"),.T.)
	ENDIF
	SELECT itemtypes
	SET ORDER TO Class
	LOCATE
	SEEK lcClass
	IF EOF()
		LOCATE
		lcClauses=[ALL FOR ATC("="+lcClass+CR,ItemTypes)>0]
	ELSE
		lcClauses=[REST WHILE ALLTRIM(Class)==lcClass]
	ENDIF
	SCAN &lcClauses 
		lcProperty=LOWER(ALLTRIM(Property))
		lnAtPos=AT("[",lcProperty)
		IF lnAtPos=0
			lnAtPos=AT("(",lcProperty)
			IF lnAtPos>0
				lcProperty=STRTRAN(STRTRAN(lcProperty,"(","["),")","]")
			ENDIF
		ENDIF
		lcProperty2=IIF(lnAtPos=0,lcProperty,ALLTRIM(LEFT(lcProperty,lnAtPos-1)))
		IF EMPTY(lcProperty) OR INLIST(lcProperty+" ","cfilename ","cclass ","cpicture ", ;
				"cfolderpicture ","classlib ","classname ","itemclass ","cfoldertype ") OR ;
				NOT PEMSTATUS(toNode,lcProperty2,5)
			LOOP
		ENDIF
		lvValue=EVALUATE("toNode."+lcProperty)
		IF TYPE("lvValue")=="U"
			LOOP
		ENDIF
		IF TYPE("lvValue")#"C"
			lvValue=TRANSFORM(lvValue)
		ENDIF
		lvDefaultValue=IIF(lcProperty==lcProperty2,TRANSFORM(GETPEM(.Class,lcProperty)),"")
		brwPropertyStuff(@lcProperties,lcProperty,lvValue,lvDefaultValue,.T.)
	ENDSCAN
	SELECT (lcAlias)
	.tUpdated=DATETIME()
	.cProperties=lcProperties
	IF tlUpdateSource
		lnAtPos=AT("!",.cParent)
		IF lnAtPos>0
			.cParent=ALLTRIM(SUBSTR(.cParent,lnAtPos+1))
		ENDIF
	ENDIF
	REPLACE Type WITH lcType, ID WITH toBrowser.ValidID(.cID), ;
				Link WITH .cLink, Parent WITH .cParent
	lcSourceCatalog=.cSourceCatalog
	IF EMPTY(lcSourceCatalog)
		lcSourceCatalog=LOWER(DBF(lcAlias))
	ENDIF
	lcSourceCatalogPath=IIF(EMPTY(lcSourceCatalog),"",JUSTPATH(lcSourceCatalog)+"\")
	lcSourceAlias=.cSourceAlias
	lcFileName=ALLTRIM(.cFileName)
	IF NOT EMPTY(lcFileName)

*** 06/29/2004 - fix to preserve case of URL for Component Gallery web site items
*!*			IF LEFT(lcFileName,2)=="\\" OR NOT SUBSTR(lcFileName,2,1)==":" OR ;
*!*					LEFT(lcFileName,4)=="www."
*!*				IF LEFT(lcFileName,2)=="\\" AND NOT "."$lcFileName AND ;
*!*						NOT RIGHT(lcFileName,1)=="\"
*!*					lcFileName=lcFileName+"\"
*!*				ENDIF
*!*				lcFileName=LOWER(ALLTRIM(lcFileName))
*!*			ELSE
*!*				lcFileName=LOWER(SYS(2014,lcFileName,lcSourceCatalogPath))
*!*			ENDIF
		DO CASE
		CASE TYPE("toNode.cItemType")="C" AND UPPER(toNode.cItemType)= "URL"
			* Leave case alone for URLs
		CASE LEFT(lcFileName,2)=="\\" OR NOT SUBSTR(lcFileName,2,1)==":" OR LEFT(lcFileName,4)=="www."
			IF LEFT(lcFileName,2)=="\\" AND NOT "."$lcFileName AND NOT RIGHT(lcFileName,1)=="\"
				lcFileName=lcFileName+"\"
			ENDIF
			lcFileName=LOWER(ALLTRIM(lcFileName))
		OTHERWISE
			lcFileName=LOWER(SYS(2014,lcFileName,lcSourceCatalogPath))
		ENDCASE
	ENDIF
	lcPicture=brwImagePictureFile(toBrowser,.cPicture,lcSourceCatalogPath)
	IF NOT EMPTY(.cFolderPicture) AND INLIST(LOWER(JUSTFNAME(.cFolderPicture)), ;
			"catalog.ico","openctlg.ico","folder.ico","openfldr.ico", ;
			"web_file.ico","web_site.ico","web_doc.ico","explorer.ico")
		lcFolderPicture=""
	ELSE
		lcFolderPicture=brwImagePictureFile(toBrowser,.cFolderPicture,lcSourceCatalogPath)
	ENDIF
	lcClassLib=.cClassLib
	IF NOT EMPTY(lcClassLib)
		lcClassLib=LOWER(SYS(2014,lcClassLib,lcSourceCatalogPath))
	ENDIF
	IF TYPE(".oRecord")=="O"
		lcValue=.oRecord.FileName
		IF LEFT(lcValue,1)=="(" AND RIGHT(lcValue,1)==")"
			lvValue=EVALUATE(SUBSTR(lcValue,2,LEN(lcValue)-2))
			IF LOWER(JUSTFNAME(lvValue))==LOWER(JUSTFNAME(lcFileName))
				lcFileName=.oRecord.FileName
			ENDIF
		ENDIF
		lcValue=.oRecord.Picture
		IF LEFT(lcValue,1)=="(" AND RIGHT(lcValue,1)==")"
			lvValue=EVALUATE(SUBSTR(lcValue,2,LEN(lcValue)-2))
			IF LOWER(JUSTFNAME(lvValue))==LOWER(JUSTFNAME(lcPicture))
				lcPicture=.oRecord.Picture
			ENDIF
		ENDIF
		lcValue=.oRecord.FolderPict
		IF LEFT(lcValue,1)=="(" AND RIGHT(lcValue,1)==")"
			lvValue=EVALUATE(SUBSTR(lcValue,2,LEN(lcValue)-2))
			IF LOWER(JUSTFNAME(lvValue))==LOWER(JUSTFNAME(lcFolderPicture))
				lcFolderPicture=.oRecord.FolderPict
			ENDIF
		ENDIF
		lcValue=.oRecord.ClassLib
		IF LEFT(lcValue,1)=="(" AND RIGHT(lcValue,1)==")"
			lvValue=EVALUATE(SUBSTR(lcValue,2,LEN(lcValue)-2))
			IF LOWER(JUSTFNAME(lvValue))==LOWER(JUSTFNAME(lcClassLib))
				lcClassLib=.oRecord.ClassLib
			ENDIF
		ENDIF
	ENDIF
	lcDesc=.cDesc
	IF lcDesc==.cText OR lcDesc==Text
		lcDesc=""
	ENDIF
	REPLACE Text WITH .cText, TypeDesc WITH .cTypeDesc, Desc WITH lcDesc, ;
			Class WITH .cClass, Properties WITH lcProperties, Script WITH .cScript, ;
			ClassName WITH .cClassName, ItemClass WITH .cItemClass, ;
			ItemTpDesc WITH .cItemTpDesc, Views WITH .cViews, Keywords WITH .cKeywords, ;
			Comment WITH .cComment, User WITH .cUser, FileName WITH lcFileName, ;
			Picture WITH lcPicture, FolderPict WITH lcFolderPicture, ;
			ClassLib WITH lcClassLib, Updated WITH .tUpdated
	oRecord=.NULL.
	SCATTER MEMO NAME oRecord
	.oRecord=oRecord
	IF tlUpdateSource AND NOT EMPTY(.cSourceAlias) AND USED(.cSourceAlias) AND ;
			.nSourceRecNo>=0
		IF LOWER(.cSourceAlias)==lcAlias
			.nSourceRecNo=RECNO()
			.cSourceAlias=lcSourceAlias
			.cSourceCatalog=LOWER(DBF(lcSourceAlias))
			.cSourceCatalogPath=IIF(EMPTY(.cCatalog),"",JUSTPATH(.cCatalog)+"\")
			REPLACE SrcAlias WITH .cSourceAlias, SrcRecNo WITH .nSourceRecNo
		ELSE
			IF .nSourceRecNo=0
				SELECT (.cSourceAlias)
				APPEND BLANK
				.nSourceRecNo=RECNO()
				REPLACE SrcRecNo WITH .nSourceRecNo
				SELECT (lcAlias)
				REPLACE SrcRecNo WITH .nSourceRecNo
			ENDIF
			oRecord=.NULL.
			SCATTER MEMO NAME oRecord
			SELECT (.cSourceAlias)
			GO .nSourceRecNo
			IF .oHost.nViewType>1 AND NOT EMPTY(ID)
				oRecord.ID=ID
				oRecord.Parent=Parent
				oRecord.Link=Parent
			ENDIF
			GATHER MEMO NAME oRecord
			IF EMPTY(SrcAlias)
				.cSourceAlias=lcSourceAlias
				.cSourceCatalog=lcSourceCatalog
				.cSourceCatalogPath=IIF(EMPTY(.cSourceCatalog),"",JUSTPATH(.cSourceCatalog)+"\")
				.nSourceRecNo=RECNO()
			ENDIF
			REPLACE SrcAlias WITH .cSourceAlias, SrcRecNo WITH .nSourceRecNo
			SELECT (lcAlias)
			REPLACE SrcAlias WITH .cSourceAlias, SrcRecNo WITH .nSourceRecNo
			oRecord=.NULL.
		ENDIF
	ELSE
		IF EMPTY(SrcAlias)
			.cSourceAlias=lcSourceAlias
			.cSourceCatalog=LOWER(DBF(lcSourceAlias))
			.cSourceCatalogPath=IIF(EMPTY(.cCatalog),"",JUSTPATH(.cCatalog)+"\")
			REPLACE SrcAlias WITH .cSourceAlias, SrcRecNo WITH .nSourceRecNo
		ENDIF
	ENDIF
ENDWITH
SELECT (lnLastSelect)
_mline=lnLastMLine
ENDFUNC



FUNCTION brwImagePictureFile(toBrowser,tcFileName,tcCatalogPath)
LOCAL lcFileName,lcPictureFile

IF EMPTY(tcFileName)
	RETURN ""
ENDIF
lcFileName=LOWER(ALLTRIM(tcFileName))
lcPictureFile=JUSTFNAME(lcFileName)
IF ASCAN(toBrowser.aImageList,lcPictureFile)>0 AND ;
		ASCAN(toBrowser.aSmallImages,lcPictureFile)>0
	lcFileName=lcPictureFile
ELSE
	IF NOT EMPTY(tcCatalogPath) AND NOT "\\"$lcFileName
		lcFileName=LOWER(SYS(2014,lcFileName,tcCatalogPath))
	ENDIF
ENDIF
RETURN lcFileName
ENDFUNC



FUNCTION brwScaleResize(toBrowser)
LOCAL lnHeight,lnWidth,lnMaxHeight,lnMaxWidth,llWebBrowserVisible
WITH toBrowser
	lnHeight=.Height-.nLastHeight
	lnWidth=.Width-.nLastWidth
	lnMaxHeight=toBrowser.Height-2
	lnMaxWidth=toBrowser.Width-1
	IF (lnHeight=0 AND lnWidth=0) OR TYPE("toBrowser.cmdOpen")#"O" OR ;
			(.lOutlineOCX AND TYPE("toBrowser.oleClassList")#"O")
		.nLastHeight=.Height
		.nLastWidth=.Width
		.vResult=.F.
		RETURN .vResult
	ENDIF
	.LockScreen=.T.
	IF .lInitialized AND NOT .lRefreshBrowserMode
		IF .lOutlineOCX
			IF .lBrowser
				.oleClassList.Enabled=.F.
				.oleClassList.Visible=.F.
				.oleMembers.Enabled=.F.
				.oleMembers.Visible=.F.
			ELSE
				.oleFolderList.Enabled=.F.
				.oleFolderList.Visible=.F.
				.oleItems.Visible=.F.
				IF .lWebBrowser
					llWebBrowserVisible=.oleWebBrowser.Visible
					.oleWebBrowser.Stop
					.oleWebBrowser.Visible=.F.
				ENDIF
			ENDIF
		ENDIF
	ENDIF

	IF lnHeight#0
		.txtClassList3D.Height=MAX(.txtClassList3D.Height+lnHeight,0)
		.txtMembers3D.Height=.txtClassList3D.Height
		IF .lOutlineOCX
			.oleClassList.Height=MAX(.oleClassList.Height+lnHeight,0)
			.oleMembers.Height=.oleClassList.Height
			.oleFolderList.Height=MAX(.oleFolderList.Height+lnHeight,0)
			.oleItems.Height=.oleFolderList.Height+2
			IF .lWebBrowser
				.oleWebBrowser.Height=.oleFolderList.Height
			ENDIF
			.edtItemDesc.Top=MAX(.edtItemDesc.Top+lnHeight,0)
			.edtItemDesc.Height=MAX(lnMaxHeight-.edtItemDesc.Top,0)
		ELSE
			.lstClassList.Height=.txtClassList3D.Height
			.lstMembers.Height=.txtMembers3D.Height
		ENDIF
		.edtClassDesc.Top=MAX(.edtClassDesc.Top+lnHeight,0)
		.edtClassDesc.Height=MAX(lnMaxHeight-.edtClassDesc.Top,0)
		.edtMemberDesc.Top=.edtClassDesc.Top
		.edtMemberDesc.Height=.edtClassDesc.Height
		.MinHeight=IIF(.lBrowser,.edtClassDesc.Height,.edtItemDesc.Height)+.nMinHeightOffset
		IF .lBrowser
			.shpSplitterV.Height=MAX(lnMaxHeight-.shpSplitterV.Top,0)
			.shpSplitterH.Top=.edtClassDesc.Top-4
		ELSE
			.shpSplitterV.Height=.oleFolderList.Height
			.shpSplitterH.Top=.edtItemDesc.Top-4
		ENDIF
	ENDIF
	IF lnWidth#0
		.txtMembers3D.Width=MAX(lnMaxWidth-.txtMembers3D.Left,0)
		IF .lOutlineOCX
			.oleMembers.Width=MAX(lnMaxWidth-.oleMembers.Left,0)
			.oleItems.Width=MAX(lnMaxWidth-.oleItems.Left,0)
			IF .lWebBrowser
				.oleWebBrowser.Width=.oleItems.Width
			ENDIF
			.edtMemberDesc.Width=.oleMembers.Width
			.edtItemDesc.Width=MAX(lnMaxWidth-.edtItemDesc.Left,0)
			.shpSplitterV.Left=IIF(.lBrowser,.oleMembers.Left,.oleItems.Left)-4
		ELSE
			.lstMembers.Width=MAX(lnMaxWidth-.lstMembers.Left,0)
			.edtMemberDesc.Width=.lstMembers.Width
			.shpSplitterV.Left=.lstMembers.Left-4
		ENDIF
		.shpSplitterH.Width=MAX(lnMaxWidth-.shpSplitterH.Left,0)
	ENDIF
	.Cls
	.LockScreen=.F.
	IF .lInitialized AND NOT .lRefreshBrowserMode
		IF .lOutlineOCX
			.oleClassList.Enabled=.T.
			.oleClassList.Visible=.lBrowser
			.oleMembers.Enabled=.T.
			.oleMembers.Visible=.lBrowser
			.oleFolderList.Enabled=.T.
			.oleFolderList.Visible=(NOT .lBrowser)
			.oleItems.Visible=(NOT .lBrowser AND NOT .lWebView)
			IF .lWebBrowser
				.oleWebBrowser.Visible=llWebBrowserVisible
			ENDIF
		ENDIF
	ENDIF
	.nLastHeight=.Height
	.nLastWidth=.Width
	IF .lInitialized
		.SavePreferences
	ENDIF
ENDWITH
ENDFUNC



FUNCTION brwFind(toBrowser,tcFind)
LOCAL llCancel,oFind2Form,llEditMode,lcViewType,oLastView,lnLastSelect

IF toBrowser.lBrowser
	toBrowser.vResult=toBrowser.FindClass(tcFind)
	RETURN toBrowser.vResult
ENDIF
IF toBrowser.AddInMethod("FIND")
	RETURN
ENDIF
IF toBrowser.nFolderCount=0
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
SET MESSAGE TO M_LOADING_LOC+" "+M_FIND_LOC+" ..."
oLastView=toBrowser.oView
llEditMode=(NOT ISNULL(toBrowser.oView) AND toBrowser.oView.lEditMode)
lnLastSelect=SELECT()
toBrowser.lModalDialog=.T.
DO FORM brwfind2 NAME oFind2Form WITH (toBrowser) TO llCancel
SET DATASESSION TO toBrowser.DataSessionID
SELECT (lnLastSelect)
SET MESSAGE TO

IF llEditMode
	IF VARTYPE(llCancel) == 'L'
		toBrowser.vResult = !llCancel
	ENDIF
	RETURN
ENDIF

WITH toBrowser
	IF llCancel OR VARTYPE(.oView)#"O" OR EMPTY(.oView.cText)
		IF VARTYPE(oLastView)=="O"
			IF VARTYPE(.oView)=="O" AND .oView#oLastView
				.oView.Release
			ENDIF
			.oView=oLastView
		ENDIF
		.vResult=.F.
		RETURN .vResult
	ENDIF
	lcViewType=PROPER(.oView.cText)
	.nViewType=-1
	.lSwitchViewMode=.T.
	.lRefreshBrowserMode=.T.
	.cboViewType.DisplayValue=lcViewType
	.lRefreshBrowserMode=.F.
	.RefreshBrowser
	.lSwitchViewMode=.F.
	IF VARTYPE(.oView)=="O"
		.oView.Release
	ENDIF
	.oView=.GetView(lcViewType)
ENDWITH
ENDFUNC



FUNCTION brwOptions(toBrowser)
LOCAL oOptionsForm,oNewCatalogs,llApply,lnLastSelect,lnCount

IF toBrowser.lBrowser
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
IF toBrowser.AddInMethod("OPTIONS")
	RETURN
ENDIF
SET MESSAGE TO M_LOADING_LOC+" "+M_OPTIONS_LOC+" ..."
lnLastSelect=SELECT()
oNewCatalogs=CREATEOBJECT("Custom")
oNewCatalogs.AddProperty("nNewCatalogCount",0)
oNewCatalogs.AddProperty("aNewCatalogs[1]","")
toBrowser.lModalDialog=.T.
DO FORM brwoptns NAME oOptionsForm WITH (toBrowser),(oNewCatalogs) TO llApply
SET DATASESSION TO toBrowser.DataSessionID
SELECT (lnLastSelect)
SET MESSAGE TO
IF ISNULL(llApply) AND oNewCatalogs.nNewCatalogCount=0
	RETURN
ENDIF
toBrowser.SavePreferences(,.T.)
IF oNewCatalogs.nNewCatalogCount>0
	llApply=.T.
	FOR lnCount = 1 TO oNewCatalogs.nNewCatalogCount
		toBrowser.AddFile(oNewCatalogs.aNewCatalogs[lnCount],.T.)
	ENDFOR
ENDIF
IF llApply
	toBrowser.RefreshBrowser
ENDIF
ENDFUNC



FUNCTION brwProperties(toBrowser,tvNode)
LOCAL oNode,oPropertiesForm,llApply,lnLastSelect

IF toBrowser.lBrowser
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
IF toBrowser.AddInMethod("PROPERTIES")
	RETURN
ENDIF
oNode=IIF(TYPE("tvNode")#"O" OR ISNULL(tvNode),toBrowser.oItemSource,tvNode)
IF TYPE("oNode")#"O" OR ISNULL(oNode)
	oNode=.NULL.
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
SET MESSAGE TO M_LOADING_LOC+" "+M_PROPERTIES_LOC+" ..."
lnLastSelect=SELECT()
toBrowser.lModalDialog=.T.
DO FORM brwprops NAME oPropertiesForm WITH (toBrowser),(oNode) TO llApply
SET DATASESSION TO toBrowser.DataSessionID
SELECT (lnLastSelect)
SET MESSAGE TO
IF ISNULL(llApply)
	RETURN
ENDIF
IF llApply
	oNode.WriteProperties(.T.,.T.)
ENDIF
oNode.Refresh
ENDFUNC



FUNCTION brwKeywords(toBrowser)
LOCAL oKeywordsForm,lcKeywords,lnLastSelect

IF toBrowser.lBrowser
	toBrowser.vResult=""
	RETURN toBrowser.vResult
ENDIF
IF toBrowser.AddInMethod("KEYWORDS")
	toBrowser.vResult=""
	RETURN toBrowser.vResult
ENDIF
SET MESSAGE TO M_LOADING_LOC+" "+M_KEYWORDS_LOC+" ..."
lnLastSelect=SELECT()
toBrowser.lModalDialog=.T.
DO FORM brwkywrd NAME oKeywordsForm WITH (toBrowser) TO lcKeywords
SET DATASESSION TO toBrowser.DataSessionID
SELECT (lnLastSelect)
SET MESSAGE TO
IF ISNULL(lcKeywords) OR EMPTY(lcKeywords)
	toBrowser.vResult=""
	RETURN toBrowser.vResult
ENDIF
toBrowser.vResult=lcKeywords
RETURN toBrowser.vResult
ENDFUNC



FUNCTION brwGetFileAddress(toBrowser,tlShellExecute,tcFileExt)
LOCAL oGetAddressForm,lcAddress,lcFileName

IF toBrowser.AddInMethod("GETADDRESS")
	toBrowser.vResult=""
	RETURN toBrowser.vResult
ENDIF
lcFileName=LOWER(HOME()+"ffc\openadlg.scx")
IF NOT FILE(lcFileName)
	SET MESSAGE TO
	toBrowser.MsgBox(M_FILE_LOC+[ "]+lcFileName+[" ]+M_DOES_NOT_EXIST_LOC+[.],16)
	toBrowser.vResult=""
	RETURN toBrowser.vResult
ENDIF
SET MESSAGE TO M_LOADING_LOC+" "+M_ADDRESSES_LOC+" ..."
toBrowser.lModalDialog=.T.
DO FORM (lcFileName) NAME oAddressForm WITH (tlShellExecute),(tcFileExt) TO lcAddress
SET DATASESSION TO toBrowser.DataSessionID
SET MESSAGE TO
IF ISNULL(lcAddress)
	RETURN
ENDIF
toBrowser.vResult=lcAddress
RETURN toBrowser.vResult
ENDFUNC



FUNCTION brwHelp(toBrowser)
LOCAL lcFileName

IF toBrowser.AddInMethod("HELP")
	RETURN
ENDIF
SET MESSAGE TO M_LOADING_LOC+" "+M_HELP_LOC+" ..."
HELP ID (toBrowser.HelpContextID) NOWAIT
SET MESSAGE TO
ENDFUNC



FUNCTION brwCleanupCatalog(toNode,tlNoRefresh,tlIgnoreErrors)
LOCAL toBrowser,lcCatalog,lcAlias,lnRecNo,lcFilter,lnLastSelect,llMatch
LOCAL lcSortTable,lcSortTable2,lcID,lcParent,lcText,llIgnoreErrors

toBrowser=toNode.oHost
IF VARTYPE(toBrowser)#"O"
	RETURN .F.
ENDIF
SET DATASESSION TO (toBrowser.DataSessionID)
IF NOT toNode.lCatalog
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
lcCatalog=toNode.cSourceCatalog
lcAlias=toNode.cSourceAlias
IF EMPTY(lcCatalog) OR EMPTY(lcAlias) OR ;
		NOT LOWER(JUSTEXT(lcCatalog))=="dbf" OR NOT FILE(lcCatalog)
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
lnLastSelect=SELECT()
SELECT (lcAlias)
lcFilter=SET("FILTER")
llIgnoreErrors=toBrowser.lIgnoreErrors
toBrowser.lIgnoreErrors=.T.
USE (lcCatalog) EXCLUSIVE ALIAS (lcAlias)
toBrowser.lIgnoreErrors=llIgnoreErrors
IF NOT USED()
	USE (lcCatalog) AGAIN SHARED ALIAS (lcAlias)
	IF NOT EMPTY(lcFilter)
		SET FILTER TO &lcFilter
	ENDIF
	LOCATE
	SELECT (lnLastSelect)
	IF NOT tlIgnoreErrors AND NOT toBrowser.lRelease
		toBrowser.MsgBox(M_UNABLE_TO_OPEN_LOC+[ "]+lcCatalog+[" ]+ ;
				M_EXCLUSIVELY_LOC+[.],16)
	ENDIF
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
SCAN ALL FOR NOT EMPTY(Type) AND NOT EMPTY(Parent) AND NOT "!"$Parent
	lnRecNo=RECNO()
	lcParent=LOWER(ALLTRIM(Parent))
	LOCATE FOR LOWER(ALLTRIM(ID))==lcParent OR ;
			LOWER(ALLTRIM(ID))==LOWER(ALLTRIM(Parent))
	IF EOF()
		GO lnRecNo
		DELETE
		LOOP
	ENDIF
	GO lnRecNo
ENDSCAN
IF NOT tlNoRefresh
	SET MESSAGE TO M_PACKING_FILE_LOC+[ "]+toNode.cCatalog+[" ...]
ENDIF
PACK
IF toNode.cCatalog==toBrowser.cDefaultCatalog OR NOT toNode.lSortOnCleanup
	USE (lcCatalog) AGAIN SHARED ALIAS (lcAlias)
	IF NOT EMPTY(lcFilter)
		SET FILTER TO &lcFilter
	ENDIF
ELSE
	lcSortTable=LOWER(SYS(2023)+"\"+SYS(2015))
	lcSortTable2=LOWER(SYS(2023)+"\"+SYS(2015))
	SORT TO (lcSortTable) ON Type
	USE (lcSortTable) EXCLUSIVE ALIAS (lcAlias)
	INDEX ON LOWER(Type+PADR(Text,50)) TAG Type
	SET FILTER TO NOT UPPER(ALLTRIM(Type))=="FOLDER" OR ;
			EMPTY(ID) OR "!"$Parent
	COPY TO (lcCatalog)
	DELETE ALL
	PACK
	SET FILTER TO NOT DELETED()
	LOCATE
	DO WHILE .T.
		llMatch=.F.
		SCAN ALL
			lcText=LOWER(Text)
			IF EMPTY(lcText)
				LOOP
			ENDIF
			lnRecNo=RECNO()
			lcID=LOWER(ALLTRIM(ID))
			SET ORDER TO
			LOCATE FOR LOWER(ALLTRIM(Parent))==lcID AND LOWER(Text)<lcText
			IF NOT EOF()
				SCAN ALL FOR LOWER(ALLTRIM(Parent))==lcID
					llMatch=.T.
					REPLACE Text WITH CHR(255)+Text
				ENDSCAN
			ENDIF
			SET ORDER TO Type
			GO lnRecNo
		ENDSCAN
		IF NOT llMatch
			EXIT
		ENDIF
	ENDDO
	COPY TO (lcSortTable2)
	USE (lcCatalog) AGAIN SHARED ALIAS (lcAlias)
	APPEND FROM (lcSortTable2)
	REPLACE ALL Text WITH STRTRAN(Text,CHR(255),"") FOR CHR(255)$Text
	IF NOT EMPTY(lcFilter)
		SET FILTER TO &lcFilter
	ENDIF
	ERASE (lcSortTable+".dbf")
	ERASE (lcSortTable+".fpt")
	ERASE (lcSortTable+".cdx")
	ERASE (lcSortTable2+".dbf")
	ERASE (lcSortTable2+".fpt")
	ERASE (lcSortTable2+".cdx")
ENDIF
REPLACE ALL SrcAlias WITH LOWER(ALIAS()), SrcRecNo WITH RECNO()
LOCATE
SELECT (lnLastSelect)
IF NOT tlNoRefresh
	SET MESSAGE TO
	toNode.Refresh
ENDIF
ENDFUNC



FUNCTION brwBackupCatalog(toNode,tlRestore,tcFileName)
LOCAL toBrowser,lcFileName,lcPath,lcCatalog,lcAlias,lcFilter,lnLastSelect

toBrowser=toNode.oHost
IF VARTYPE(toBrowser)#"O"
	RETURN .F.
ENDIF
SET DATASESSION TO (toBrowser.DataSessionID)
IF NOT toNode.lCatalog
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
lcCatalog=toNode.cSourceCatalog
lcAlias=toNode.cSourceAlias
IF EMPTY(lcCatalog) OR EMPTY(lcAlias) OR ;
		NOT LOWER(JUSTEXT(lcCatalog))=="dbf" OR NOT FILE(lcCatalog)
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
IF EMPTY(tcFileName)
	lcPath=JUSTPATH(lcCatalog)+"\backup\"
	lcFileName=lcPath+JUSTFNAME(lcCatalog)
ELSE
	lcFileName=LOWER(FULLPATH(ALLTRIM(tcFileName)))
	lcPath=JUSTPATH(lcFileName)+"\"
ENDIF
IF toBrowser.MsgBox(IIF(tlRestore,M_RESTORE_LOC,M_BACKUP_LOC)+ ;
		[ ]+LOWER(M_CATALOG_LOC)+[ "]+lcFileName+["?],292)#6
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
IF NOT FILE(lcFileName)
	llIgnoreErrors=toBrowser.lIgnoreErrors
	toBrowser.lIgnoreErrors=.T.
	MD (lcPath)
	toBrowser.lIgnoreErrors=llIgnoreErrors
ENDIF
IF tlRestore AND NOT FILE(lcFileName)
	toBrowser.MsgBox(M_FILE_LOC+[ "]+lcFileName+[" ]+M_NOT_FOUND_LOC+[.],16)
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
lnLastSelect=SELECT()
SELECT (lcAlias)
lcFilter=SET("FILTER")
SET FILTER TO
IF NOT tlRestore
	SET MESSAGE TO M_RESTORING_FILE_LOC+[ "]+toNode.cCatalog+[" ...]
	COPY TO (lcFileName)
	IF NOT EMPTY(lcFilter)
		SET FILTER TO &lcFilter
	ENDIF
	LOCATE
	SELECT (lnLastSelect)
	SET MESSAGE TO
	toBrowser.MsgBox(["]+lcFileName+[" ]+M_SUCCESSFULLY_CREATED_LOC+[.])
	RETURN
ENDIF
llIgnoreErrors=toBrowser.lIgnoreErrors
toBrowser.lIgnoreErrors=.T.
USE (lcCatalog) EXCLUSIVE ALIAS (lcAlias)
toBrowser.lIgnoreErrors=llIgnoreErrors
IF NOT USED()
	USE (lcCatalog) AGAIN SHARED ALIAS (lcAlias)
	IF NOT EMPTY(lcFilter)
		SET FILTER TO &lcFilter
	ENDIF
	LOCATE
	SELECT (lnLastSelect)
	IF NOT toBrowser.lRelease
		toBrowser.MsgBox(M_UNABLE_TO_OPEN_LOC+[ "]+lcCatalog+[" ]+ ;
				M_EXCLUSIVELY_LOC+[.],16)
	ENDIF
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
SET MESSAGE TO M_BACKING_UP_FILE_LOC+[ "]+toNode.cCatalog+[" ...]
ZAP
APPEND FROM (lcFileName)
USE (lcCatalog) AGAIN SHARED ALIAS (lcAlias)
IF NOT EMPTY(lcFilter)
	SET FILTER TO &lcFilter
ENDIF
LOCATE
SELECT (lnLastSelect)
SET MESSAGE TO
toNode.Refresh
ENDFUNC



FUNCTION brwPropertyStuff(tcProperties,tcProperty,tcValue,tcDefaultValue,tlAutoAdd)
LOCAL lcProperty,lcValue,lcDefaultValue,lcProperty2,lcOldProperties,lcNewProperties
LOCAL lcMemLine,lnCount,lnAtPos,llMatch

IF EMPTY(tcProperty)
	RETURN .F.
ENDIF
lcProperty=ALLTRIM(tcProperty)
lcValue=IIF(EMPTY(tcValue),"",ALLTRIM(tcValue))
lcDefaultValue=IIF(EMPTY(tcDefaultValue),"",ALLTRIM(tcDefaultValue))
lcNewProperties=""
llMatch=.F.
_mline=0
FOR lnCount = 1 TO MEMLINES(tcProperties)
	lcMemLine=MLINE(tcProperties,1,_mline)
	IF EMPTY(lcMemLine)
		LOOP
	ENDIF
	lnAtPos=AT("=",lcMemLine)
	IF lnAtPos>0
		lcProperty2=ALLTRIM(LEFT(lcMemLine,lnAtPos-1))
		IF LOWER(lcProperty)==LOWER(lcProperty2)
			IF llMatch
				LOOP
			ENDIF
			llMatch=.T.
			IF EMPTY(lcValue) OR lcValue==lcDefaultValue
				LOOP
			ENDIF
			lcMemLine=lcProperty2+"="+lcValue
		ENDIF
	ENDIF
	lcNewProperties=lcNewProperties+lcMemLine+CR_LF
ENDFOR
IF tlAutoAdd AND NOT llMatch AND NOT EMPTY(lcValue) AND NOT lcValue==lcDefaultValue
	lcNewProperties=lcNewProperties+lcProperty+"="+lcValue
ENDIF
IF RIGHT(lcNewProperties,2)==CR_LF
	lcNewProperties=ALLTRIM(LEFT(lcNewProperties,LEN(lcNewProperties)-2))
ENDIF
tcProperties=lcNewProperties
RETURN tcProperties
ENDFUNC



FUNCTION brwHitTest(toBrowser,oControl,x,y)
LOCAL oNode,oItem,llFolder,lnXFactor,lnYFactor

llFolder=(LOWER(oControl.Name)=="olefolderlist")
lnXFactor=1440/96*(13/FONTMETRIC(1,"MS Sans Serif",8,""))
lnYFactor=1440/96*(11/FONTMETRIC(7,"MS Sans Serif",8,""))
oNode=oControl.HitTest(x*lnXFactor,y*lnYFactor)
IF TYPE("oNode")#"O" OR ISNULL(oNode)
	oNode=.NULL.
	IF NOT llFolder
		oNode=toBrowser.oFolder
	ENDIF
	toBrowser.vResult=oNode
	RETURN oNode
ENDIF
oItem=toBrowser.GetItem(oNode)
toBrowser.vResult=oItem
RETURN oItem
ENDFUNC



FUNCTION brwExportClass(toBrowser,tlShow,tcExportToFile)
LOCAL lcExportToFile,lcCode,lcInsertCode,lcAppendCode,lcDefineClass,llHTML
LOCAL lcClass,lcParentClass,lcBaseClass,lcObjectClass,lcObjectBaseClass,lcParent
LOCAL lcClassLoc,lcProperties,lcAddObject,lcInsertDefineCode,lcAppendDefineCode,llSCXMode
LOCAL lcFileName,lcFileName2,lnClassCount,lnListIndex,lcFilter,lcViewCodeFileName
LOCAL llFileMode,lnClassLibCount,laClassLib,lnRecNo,lcCRLF3,lcCRLF4,lcMemberType
LOCAL lcMember,lcMember2,lcMemberDesc,lnMemberCount,laMembers,laMemberDesc,lcTimeStamp
LOCAL lnProtectedCount,laProtected,lnAtPos,lnElement,lcComment,lnLastSelect
LOCAL lcVarName,lcArrayInfo,lcBorder,lnCount,llHidden,lcMethods,lcMethods2,lcSearchStr
LOCAL lcFullParent

IF NOT toBrowser.lVCXSCXMode 
	toBrowser.vResult=""
	RETURN toBrowser.vResult
ENDIF
IF toBrowser.AddInMethod("EXPORTCLASS")
	toBrowser.vResult=""
	RETURN toBrowser.vResult
ENDIF
llHTML=.F.
DO CASE
	CASE TYPE("tcExportToFile")#"C"
		lcExportToFile=""
	CASE UPPER(ALLTRIM(tcExportToFile))=="HTML"
		lcExportToFile=""
		llHTML=.T.
	CASE NOT EMPTY(tcExportToFile)
		lcExportToFile=ALLTRIM(tcExportToFile)
	OTHERWISE
		lcExportToFile=LOWER(PUTFILE(M_SAVE_LOC,"","prg|txt|htm|html"))
		IF EMPTY(lcExportToFile)
			toBrowser.vResult=""
			RETURN toBrowser.vResult
		ENDIF
ENDCASE
IF NOT EMPTY(lcExportToFile)
	IF NOT ":"$lcExportToFile AND NOT "\\"$lcExportToFile
		lcExportToFile=LOWER(FULLPATH(lcExportToFile))
	ENDIF
	IF FILE(lcExportToFile)
		IF tlShow AND toBrowser.MsgBox(lcExportToFile+M_ALREADY_EXISTS_OVER_LOC,35)#6
			toBrowser.vResult=""
			RETURN toBrowser.vResult
		ENDIF
	ENDIF
	llHTML=INLIST(LOWER(JUSTEXT(lcExportToFile)),"htm","html")
ENDIF
SET MESSAGE TO M_GEN_CLASS_DEF_LOC+[ ...]
lcCRLF3=REPLICATE(CR_LF,3)
lcCRLF4=REPLICATE(CR_LF,4)
lnLastSelect=SELECT()
toBrowser.SetBusyState(.T.)
lcBorder=REPLICATE("*",50)
lcComment="*-- "
lcCode=""
lcInsertCode=""
lcAppendCode=""
lcInsertDefineCode=""
lcAppendDefineCode=""
lcDefineClass=""
lnClassLibCount=0
DIMENSION laClassLib[1]
llFileMode=toBrowser.lFileMode
lcFileName=toBrowser.cFileName
llSCXMode=toBrowser.lSCXMode
lnClassCount=0


SELECT (toBrowser.cAlias)
LOCATE
DO WHILE .T.
	IF toBrowser.lRelease
		SELECT (lnLastSelect)
		toBrowser.vResult=""
		RETURN toBrowser.vResult
	ENDIF
	IF lnClassCount>0
		IF EOF()
			EXIT
		ENDIF
		SKIP
	ENDIF
	lcParent=LOWER(ALLTRIM(Parent))
	IF lnClassCount<=0 OR EMPTY(lcParent)
		lnClassCount=lnClassCount+1
		IF lnClassCount>toBrowser.nClassCount OR ;
				(NOT llFileMode AND lnClassCount>=2)
			EXIT
		ENDIF
		IF llFileMode
			lnListIndex=lnClassCount
		ELSE
			lnListIndex=toBrowser.nClassListIndex+1
		ENDIF
		lcClass=toBrowser.aClassList[lnListIndex,1]
		lcFileName2=toBrowser.aClassList[lnListIndex,6]
		IF "."$lcClass OR NOT lcFileName==lcFileName2
			LOCATE
			LOOP
		ENDIF
		GO toBrowser.aClassList[lnListIndex,2]
		lcParent=LOWER(ALLTRIM(Parent))
		lcParentClass=LOWER(ALLTRIM(Class))
		SET MESSAGE TO M_GEN_CLASS_DEF_LOC+[ (]+lcClass+[) ...]
	ELSE
		lcClass=LOWER(ALLTRIM(ObjName))
		lcParentClass=LOWER(ALLTRIM(Class))
		SET MESSAGE TO M_GEN_CLASS_DEF_LOC+[ (]+lcDefineClass+[.]+lcClass+[) ...]
	ENDIF
	lcBaseClass=LOWER(ALLTRIM(BaseClass))
	lcClassLoc=IIF(EMPTY(ClassLoc),"",LOWER(FULLPATH(ALLTRIM(ClassLoc),lcFileName)))
	IF llHTML
		lcProperties=brwValidHTMLText(ALLTRIM(Properties))
		lcMethods=brwValidHTMLText(ALLTRIM(Methods))
	ELSE
		lcProperties=ALLTRIM(Properties)
		lcMethods=ALLTRIM(Methods)
	ENDIF
	lnMemberCount=0
	DIMENSION laMembers[1]
	DIMENSION laMemberDesc[1]
	_mline=0

	FOR lnCount = 1 TO MEMLINE(Reserved3)
		lcMember=ALLTRIM(MLINE(Reserved3,1,_mline))
		lcArrayInfo=""
		IF EMPTY(lcMember)
			LOOP
		ENDIF
		IF LEFT(lcMember,1)=="*"
			lcMember=ALLTRIM(SUBSTR(lcMember,2))
			lnAtPos=AT(" ",lcMember)
			IF lnAtPos=0
				lcMemberDesc=""
				lcMember=LOWER(lcMember)
			ELSE
				lcMemberDesc=ALLTRIM(SUBSTR(lcMember,lnAtPos+1))
				lcMember=LOWER(ALLTRIM(LEFT(lcMember,lnAtPos-1)))
			ENDIF
			lnAtPos=ATC(CR_LF+"PROCEDURE "+lcMember+CR_LF,CR_LF+lcMethods+CR_LF)
			IF NOT EMPTY(lcMethods)
				lcMethods=lcMethods+CR_LF
			ENDIF
			IF lnAtPos>0
				IF EMPTY(lcMemberDesc)
					lcMemberDesc=CR_LF+CR_LF
				ELSE
					lcMemberDesc=toBrowser.IndentText(lcComment+lcMemberDesc)
				ENDIF
				lcMethods=LEFT(lcMethods,lnAtPos-1)+CR_LF+CR_LF+ ;
						MARKER+IIF(llHTML,[<font color="green">],[])+ ;
						+lcMemberDesc+IIF(llHTML,[</font><font color="black">],[])+CR_LF+ ;
						SUBSTR(lcMethods,lnAtPos)
				LOOP
			ENDIF
			IF NOT EMPTY(lcMethods)
				lcMethods=lcMethods+CR_LF
			ENDIF
			IF NOT EMPTY(lcMemberDesc)
				lcMethods=lcMethods+MARKER+toBrowser.IndentText(lcComment+lcMemberDesc)
			ENDIF
			IF NOT EMPTY(lcMethods)
				lcMethods=lcMethods+CR_LF
			ENDIF
			lcMethods=lcMethods+"PROCEDURE "+lcMember+CR_LF+"ENDPROC"+CR_LF+CR_LF
			LOOP
		ENDIF
		IF LEFT(lcMember,1)=="^"
			lcMember=STRTRAN(STRTRAN(STRTRAN(ALLTRIM(SUBSTR(lcMember,2)), ;
					"(","["),")","]"),",0]","]")
			lnAtPos=AT("[",lcMember)
			IF lnAtPos>0
				lcArrayInfo=ALLTRIM(SUBSTR(lcMember,lnAtPos))
				lcMember=ALLTRIM(LEFT(lcMember,lnAtPos-1))
			ENDIF
			IF EMPTY(lcMember)
				LOOP
			ENDIF
			lnMemberCount=lnMemberCount+1
			DIMENSION laMembers[lnMemberCount]
			DIMENSION laMemberDesc[lnMemberCount]
			laMembers[lnMemberCount]=LOWER(lcMember)+" "
			lnAtPos=AT(" ",lcArrayInfo)
			IF lnAtPos=0
				laMemberDesc[lnMemberCount]=MARKER+lcArrayInfo
			ELSE
				laMemberDesc[lnMemberCount]=ALLTRIM(SUBSTR(lcArrayInfo,lnAtPos+1))+ ;
						MARKER+ALLTRIM(LEFT(lcArrayInfo,lnAtPos-1))
			ENDIF
			LOOP
		ENDIF
		lnMemberCount=lnMemberCount+1
		DIMENSION laMembers[lnMemberCount]
		DIMENSION laMemberDesc[lnMemberCount]
		lnAtPos=AT(" ",lcMember)
		IF lnAtPos=0
			laMembers[lnMemberCount]=LOWER(lcMember)+" "
			laMemberDesc[lnMemberCount]=""
		ELSE
			laMembers[lnMemberCount]=LOWER(ALLTRIM(LEFT(lcMember,lnAtPos-1)))+" "
			laMemberDesc[lnMemberCount]=ALLTRIM(SUBSTR(lcMember,lnAtPos+1))
		ENDIF
	ENDFOR
	lnProtectedCount=0
	DIMENSION laProtected[1]
	_mline=0
	FOR lnCount = 1 TO MEMLINE(Protected)
		lcMember=LOWER(ALLTRIM(MLINE(Protected,1,_mline)))
		IF EMPTY(lcMember)
			LOOP
		ENDIF
		llHidden=("^"$lcMember)
		lcMember2=ALLTRIM(STRTRAN(lcMember,"^",""))
		lcMemberType=IIF(PEMSTATUS(lcBaseClass,lcMember2,5), ;
				LOWER(PEMSTATUS(lcBaseClass,lcMember2,3)),"")
		IF ASCAN(laMembers,lcMember2+" ")=0 AND NOT lcMemberType=="property"
			lcMethods2=CR_LF+lcMethods
			lcSearchStr=CR_LF+"PROCEDURE "+lcMember2+CR_LF
			lnAtPos=ATC(lcSearchStr,lcMethods2)
			IF lnAtPos>0
				lcMethods=SUBSTR(LEFT(lcMethods2,lnAtPos),3)+TAB+ ;
						IIF(llHidden,"HIDDEN ","PROTECTED ")+ ;
						SUBSTR(lcMethods2,lnAtPos+2)
				lcMethods2=""
				LOOP
			ENDIF
			lcMethods2=""
		ENDIF
		lnProtectedCount=lnProtectedCount+1
		DIMENSION laProtected[lnProtectedCount]
		laProtected[lnProtectedCount]=lcMember+" "
	ENDFOR
	IF llFileMode AND llSCXMode AND NOT EMPTY(lcClassLoc) AND ;
			ASCAN(laClassLib,lcClassLoc)=0
		lnClassLibCount=lnClassLibCount+1
		DIMENSION laClassLib[lnClassLibCount]
		laClassLib[lnClassLibCount]=lcClassLoc
	ENDIF
	DO CASE
		CASE EMPTY(lcParent)
			IF NOT EMPTY(lcDefineClass)
				IF NOT EMPTY(lcInsertDefineCode)
					lcInsertDefineCode=lcInsertDefineCode+CR_LF+CR_LF
				ENDIF
				lcCode=lcCode+lcInsertDefineCode+lcAppendDefineCode
				DO WHILE RIGHT(lcCode,2)==CR_LF
					lcCode=LEFT(lcCode,LEN(lcCode)-2)
				ENDDO
				lcCode=lcCode+lcCRLF3+ ;
						IIF(llHTML,[<font color="navy">]+CR_LF,[])+"ENDDEFINE"+CR_LF+ ;
						+IIF(llHTML,CR_LF+[</font><font color="green">]+CR_LF,[])+"*"+CR_LF+ ;
						lcComment+"EndDefine: "+lcDefineClass+CR_LF+lcBorder+ ;
						IIF(llHTML,CR_LF+[</font><font color="black">]+CR_LF,[])+CR_LF+CR_LF
			ENDIF
			lcInsertDefineCode=""
			lcAppendDefineCode=""
			IF NOT EMPTY(lcDefineClass)
				lcCode=lcCode+CR_LF+IIF(llHTML,[<hr>],CR_LF+CR_LF)+CR_LF+CR_LF
			ENDIF
			lcDefineClass=lcClass
			IF llHTML
				lcCode=lcCode+IIF(llHTML,CR_LF+[<font color="green">]+CR_LF,[])
			ENDIF
			IF llFileMode AND NOT llSCXMode AND EMPTY(lcCode)
				lnRecNo=RECNO()
				LOCATE
				lcCode=lcCode+lcBorder+CR_LF+ ;
						lcComment+"Class Library:  "+lcFileName+CR_LF
				IF NOT EMPTY(Reserved7)
					lcCode=lcCode+toBrowser.IndentText(lcComment+ALLTRIM(Reserved7))+CR_LF
				ENDIF
				lcCode=lcCode+lcBorder+lcCRLF3
				GO lnRecNo
			ENDIF
			lcCode=lcCode+lcBorder+CR_LF+lcComment+PADR(IIF(llSCXMode, ;
					PROPER(lcBaseClass)+":","Class:"),14)+ ;
					IIF(llHTML,[<font color="blue">],[])+lcClass+ ;
					IIF(llHTML,[</font><font color="green">],[])+" ("+lcFileName+")"+CR_LF+ ;
					lcComment+"ParentClass:  "
			DO CASE
				CASE NOT llHTML
					lcCode=lcCode+lcParentClass
				CASE lcParentClass==lcBaseClass OR NOT toBrowser.lFileMode OR ;
						EMPTY(lcClassLoc) OR NOT toBrowser.cFileName==lcClassLoc
					lcCode=lcCode+IIF(llHTML,[</font><font color="blue">],[])+lcParentClass
				OTHERWISE
					lcCode=lcCode+IIF(llHTML,[<a href="#]+lcParentClass+[">],[])+lcParentClass+ ;
							IIF(llHTML,[</a>],[])
			ENDCASE
			lcCode=lcCode+IIF(llHTML,[</font><font color="green">],[])+IIF(EMPTY(lcClassLoc),""," ("+lcClassLoc+")")+CR_LF+ ;
					lcComment+"BaseClass:    "+IIF(llHTML,[</font><font color="blue">],[])+ ;
					lcBaseClass+IIF(llHTML,[</font><font color="green">	],[])+CR_LF
			lcTimeStamp=toBrowser.GetTimeStamp(TIMESTAMP)
			IF NOT EMPTY(lcTimeStamp)
				lcCode=lcCode+lcComment+M_TIMESTAMP_LOC+" "+lcTimeStamp+CR_LF
			ENDIF
			IF NOT EMPTY(OLE2)
				lcCode=lcCode+lcComment+MLINE(OLE2,1)+CR_LF
			ENDIF
			IF NOT EMPTY(Reserved7)
				lcCode=lcCode+lcComment+Reserved7+CR_LF
			ENDIF
			lcCode=toBrowser.IndentText(lcCode)
			IF llSCXMode
				lnRecNo=RECNO()
				LOCATE
			ENDIF
			IF NOT EMPTY(Reserved8)
				lcCode=lcCode+"*"+CR_LF+[#INCLUDE ]+CHR(34)+ ;
						LOWER(FULLPATH(ALLTRIM(MLINE(Reserved8,1)),lcFileName))+ ;
						CHR(34)+CR_LF
			ENDIF
			IF llSCXMode
				GO lnRecNo
			ENDIF
			lcCode=lcCode+"*"+CR_LF+IIF(llHTML,[<font color="navy">]+CR_LF+ ;
					[<a name="]+lcClass+[">]+CR_LF,[])+ ;
					"DEFINE CLASS "+IIF(llHTML,[</a></font><font color="blue">],[])+lcClass+ ;
					IIF(llHTML,[</font><font color="navy">],[])+" AS "
			DO CASE
				CASE NOT llHTML
					lcCode=lcCode+lcParentClass
				CASE lcParentClass==lcBaseClass OR NOT toBrowser.lFileMode OR ;
						EMPTY(lcClassLoc) OR NOT toBrowser.cFileName==lcClassLoc
					lcCode=lcCode+IIF(llHTML,[</font><font color="blue">],[])+lcParentClass
				OTHERWISE
					lcCode=lcCode+IIF(llHTML,[<a href="#]+lcParentClass+[">],[])+lcParentClass+ ;
							IIF(llHTML,[</a>],[])
			ENDCASE
			IF NOT llSCXMode
				lnRecNo=RECNO()
				LOCATE FOR UPPER(ALLTRIM(Platform))=="COMMENT" AND ;
						LOWER(ALLTRIM(ObjName))==lcClass
				IF NOT EOF() AND UPPER(ALLTRIM(MLINE(Reserved2,1)))=="OLEPUBLIC"
					lcCode=lcCode+IIF(llHTML,[<font color="navy">],[])+" OLEPUBLIC"
				ENDIF
				GO lnRecNo
			ENDIF
			lcCode=lcCode+CR_LF+IIF(llHTML,[</font><font color="black">]+CR_LF,[])+CR_LF
			IF NOT EMPTY(lcProperties)
				lcInsertDefineCode=lcInsertDefineCode+CR_LF+ ;
						toBrowser.FormatProperties(lcProperties)
			ENDIF
			DO WHILE RIGHT(lcInsertDefineCode,2)==CR_LF
				lcInsertDefineCode=LEFT(lcInsertDefineCode,LEN(lcInsertDefineCode)-2)
			ENDDO

			lcInsertDefineCode=lcInsertDefineCode+CR_LF
			FOR lnCount = 1 TO lnMemberCount
				lcMember=ALLTRIM(laMembers[lnCount])
				llHidden=("^"$lcMember)
				lcMember2=ALLTRIM(STRTRAN(lcMember,"^",""))
				lcMemberDesc=laMemberDesc[lnCount]
				lnAtPos=AT(MARKER,lcMemberDesc)
				IF lnAtPos=0
					lcArrayInfo=""
				ELSE
					lcArrayInfo=SUBSTR(lcMemberDesc,lnAtPos+1)
					lcMemberDesc=LEFT(lcMemberDesc,lnAtPos-1)
				ENDIF
				IF NOT EMPTY(lcMemberDesc)
					lnAtPos=ATC(TAB+lcMember2+" = ",lcInsertDefineCode)
					IF lnAtPos=0
						lcInsertDefineCode=lcInsertDefineCode+CR_LF+ ;
								IIF(llHTML,[<font color="green">],[])+ ;
								toBrowser.IndentText(toBrowser.IndentText(lcComment+ ;
								lcMemberDesc),1)+IIF(llHTML,[</font><font color="black">],[])+CR_LF
					ELSE
						lcInsertDefineCode=LEFT(lcInsertDefineCode,lnAtPos-1)+ ;
								IIF(llHTML,[<font color="green">],[])+ ;
								toBrowser.IndentText(toBrowser.IndentText(lcComment+ ;
								lcMemberDesc),1)+IIF(llHTML,[</font><font color="black">],[])+CR_LF+ ;
								SUBSTR(lcInsertDefineCode,lnAtPos)
					ENDIF
				ENDIF
				lnElement=ASCAN(laProtected,lcMember+" ")
				IF lnElement=0
					lnElement=ASCAN(laProtected,lcMember+"^ ")
					IF lnElement>0
						llHidden=.T.
					ENDIF
				ENDIF
				IF lnElement>0
					laProtected[lnElement]=""
				ENDIF
				IF EMPTY(lcArrayInfo)
					lnAtPos=ATC(TAB+lcMember2+" ",lcInsertDefineCode)
					IF lnElement>0
						IF lnAtPos=0
							lcInsertDefineCode=lcInsertDefineCode+TAB+ ;
									IIF(llHidden,"HIDDEN ","PROTECTED ")+lcMember2+CR_LF
							LOOP
						ELSE
							lcInsertDefineCode=LEFT(lcInsertDefineCode,lnAtPos-1)+ ;
									TAB+IIF(llHidden,"HIDDEN ","PROTECTED ")+lcMember2+CR_LF+ ;
									SUBSTR(lcInsertDefineCode,lnAtPos)
						ENDIF
					ENDIF
					IF lnAtPos>0
						LOOP
					ENDIF
				ELSE
					lcInsertDefineCode=lcInsertDefineCode+TAB+ ;
							IIF(lnElement>0,IIF(llHidden,"HIDDEN ","PROTECTED "), ;
							"DIMENSION ")+lcMember2+lcArrayInfo+CR_LF
				ENDIF
				IF EMPTY(lcArrayInfo)
					lcInsertDefineCode=lcInsertDefineCode+TAB+lcMember2+" = .F."+CR_LF
				ENDIF
			ENDFOR
			FOR lnCount = 1 TO lnProtectedCount
				lcMember=ALLTRIM(laProtected[lnCount])
				IF EMPTY(lcMember)
					LOOP
				ENDIF
				llHidden=("^"$lcMember)
				lcMember2=ALLTRIM(STRTRAN(lcMember,"^",""))
				lcInsertDefineCode=lcInsertDefineCode+TAB+ ;
						IIF(llHidden,"HIDDEN ","PROTECTED ")+lcMember2+CR_LF
				laProtected[lnCount]=""
			ENDFOR
			IF NOT EMPTY(lcMethods)
				lcAppendDefineCode=lcAppendDefineCode+toBrowser.FormatMethods(lcMethods)
			ENDIF
		CASE NOT EMPTY(lcClass) AND NOT EMPTY(lcParent)
			lcObjectClass=IIF(lcParent==lcDefineClass,"",lcParent+".")+lcClass
			lcObjectBaseClass=LOWER(ALLTRIM(BaseClass))
			lcAddObject=IIF(llHTML,[<font color="navy">]+CR_LF,[])+ ;
					"ADD OBJECT "+IIF(llHTML,[</font><font color="blue">],[])+ ;
					lcObjectClass+IIF(llHTML,[</font><font color="navy">],[])+" AS "
			DO CASE
				CASE NOT llHTML
					lcAddObject=lcAddObject+lcParentClass
				CASE lcParentClass==lcObjectBaseClass OR NOT toBrowser.lFileMode OR ;
						EMPTY(lcClassLoc) OR NOT toBrowser.cFileName==lcClassLoc
					lcAddObject=lcAddObject+IIF(llHTML,[<font color="blue">],[])+lcParentClass
				OTHERWISE
					lcAddObject=lcAddObject+IIF(llHTML,[<a href="#]+lcParentClass+[">],[])+lcParentClass+ ;
							IIF(llHTML,[</a>],[])
			ENDCASE
			lcAddObject=lcAddObject+IIF(llHTML,[</font><font color="navy">],[])
			IF UPPER(ALLTRIM(Reserved8))=="NOINIT"
				lcAddObject=lcAddObject+" NOINIT"
			ENDIF
			IF EMPTY(lcProperties)
				lcAddObject=toBrowser.IndentText(lcAddObject)+ ;
						IIF(llHTML,[<font color="black">],[])
			ELSE
				lcProperties=toBrowser.FormatProperties(lcProperties,.T.)
				lcAddObject=lcAddObject+" WITH "+IIF(llHTML,[<font color="black">],[])+";"+ ;
						CR_LF+toBrowser.IndentText(lcProperties,1)
			ENDIF
			lcAddObject=toBrowser.IndentText(lcAddObject)
			IF NOT EMPTY(lcMethods)


				lcMethods=toBrowser.FormatMethods(lcMethods)

				* RMK - 2004/05/11 - per ID 233847, added code to put in full object hierarchy here
				*lcFullParent = parent + '.' + ObjName
				*lcMethods=STRTRAN(lcMethods,"PROCEDURE ","PROCEDURE "+ lcFullParent + ".")
				
				lcMethods=STRTRAN(lcMethods,"PROCEDURE ","PROCEDURE "+lcClass+".")

				IF NOT EMPTY(lcAppendDefineCode)
					lcAppendDefineCode=lcAppendDefineCode+CR_LF
				ENDIF
				lcAppendDefineCode=lcAppendDefineCode+lcMethods
			ENDIF
			lcInsertDefineCode=lcInsertDefineCode+CR_LF+CR_LF+lcAddObject+CR_LF
	ENDCASE
	IF NOT EMPTY(lcMethods)
		DO WHILE LEFT(lcAppendDefineCode,2)==CR_LF
			lcAppendDefineCode=SUBSTR(lcAppendDefineCode,3)
		ENDDO
		DO WHILE RIGHT(lcAppendDefineCode,2)==CR_LF
			lcAppendDefineCode=LEFT(lcAppendDefineCode, ;
					LEN(lcAppendDefineCode)-2)
		ENDDO
		lcAppendDefineCode=lcAppendDefineCode+lcCRLF3
	ENDIF
ENDDO
SET MESSAGE TO ""
IF NOT EMPTY(lcDefineClass)
	IF NOT EMPTY(lcInsertDefineCode)
		lcInsertDefineCode=lcInsertDefineCode+CR_LF+CR_LF
	ENDIF
	lcCode=lcCode+lcInsertDefineCode+lcAppendDefineCode
	DO WHILE RIGHT(lcCode,2)==CR_LF
		lcCode=LEFT(lcCode,LEN(lcCode)-2)
	ENDDO
	lcCode=lcCode+lcCRLF3+ ;
			IIF(llHTML,[<font color="navy">]+CR_LF,[])+"ENDDEFINE"+CR_LF+ ;
			+IIF(llHTML,CR_LF+[</font><font color="green">]+CR_LF,[])+"*"+CR_LF+ ;
			lcComment+"EndDefine: "+lcDefineClass+CR_LF+lcBorder+ ;
			IIF(llHTML,CR_LF+[</font><font color="black">]+CR_LF,[])+CR_LF
ENDIF	
IF llFileMode AND llSCXMode AND NOT EMPTY(lcCode)
	FOR lnCount = 1 TO lnClassLibCount
		lcInsertCode=lcInsertCode+"SET CLASSLIB TO "+laClassLib[lnCount]+ ;
				" ADDITIVE"+CR_LF
	ENDFOR
	IF NOT EMPTY(lcInsertCode)
		lcInsertCode=lcInsertCode+CR_LF
	ENDIF
	lcVarName="o"+lcDefineClass
	lcInsertCode=[PUBLIC ]+lcVarName+CR_LF+CR_LF+lcInsertCode+ ;
			lcVarName+[=NEWOBJECT("]+lcDefineClass+[")]+CR_LF+ ;
			lcVarName+[.Show]+CR_LF+ ;
			[RETURN]+lcCRLF3
ENDIF
IF NOT EMPTY(lcInsertCode)
	lcCode=lcInsertCode+lcCode
ENDIF
IF NOT EMPTY(lcAppendCode)
	lcCode=lcCode+lcAppendCode
ENDIF
lcCode=STRTRAN(STRTRAN(lcCode,MARKER,""),CR_LF+TAB+CR_LF)
DO WHILE LEFT(lcCode,1)==TAB
	lcCode=ALLTRIM(SUBSTR(lcCode,2))
ENDDO
IF llHTML
	lcCode=[<html>]+CR_LF+ ;
			[<head>]+CR_LF+ ;
			[<title>]+IIF(toBrowser.lFileMode,M_CLASS_LIBRARY_LOC+" "+toBrowser.cClass, ;
			M_CLASS_LOC+" ("+toBrowser.cClass+")")+ ;
			[</title>]+CR_LF+ ;
			[</head>]+CR_LF+ ;
			[<body>]+CR_LF+CR_LF+ ;
			[<pre><b>]+CR_LF+ ;
			lcCode+CR_LF+ ;
			[</b></pre>]+CR_LF+CR_LF+ ;
			[</body>]+CR_LF+ ;
			[</html>]+CR_LF
ENDIF
lcCode=STRTRAN(STRTRAN(STRTRAN(lcCode,LF+TAB+CR,""),LF+LF,LF),CR+CR,CR)
DO WHILE lcCRLF4$lcCode
	lcCode=STRTRAN(lcCode,lcCRLF4,lcCRLF3)
ENDDO
IF NOT EMPTY(lcExportToFile)
	IF WEXIST(JUSTFNAME(lcExportToFile))
		RELEASE WINDOW (JUSTFNAME(lcExportToFile))
	ENDIF
	STRTOFILE(lcCode,lcExportToFile)
ENDIF
IF tlShow
	IF NOT EMPTY(lcExportToFile)
		IF llHTML
			toBrowser.ShellExecute(lcExportToFile)
		ELSE
			IF LOWER(JUSTEXT(lcExportToFile))=="prg"
				MODIFY COMM (lcExportToFile) RANGE 1,1 IN SCREEN NOWAIT
			ELSE
				MODIFY FILE (lcExportToFile) RANGE 1,1 IN SCREEN NOWAIT
			ENDIF
		ENDIF
	ELSE
		lcViewCodeFileName=LOWER(toBrowser.cViewCodeFileName)
		IF EMPTY(lcViewCodeFileName)
			lcViewCodeFileName=LOWER(toBrowser.cProgramPath+SYS(2015)+".prg")
		ENDIF
		IF WEXIST(JUSTFNAME(lcViewCodeFileName))
			RELEASE WINDOW (JUSTFNAME(lcViewCodeFileName))
		ENDIF
		STRTOFILE(lcCode,lcViewCodeFileName)
		IF LOWER(JUSTEXT(lcViewCodeFileName))=="prg"
			MODIFY COMM (lcViewCodeFileName) RANGE 1,1 IN SCREEN NOWAIT
		ELSE
			MODIFY FILE (lcViewCodeFileName) RANGE 1,1 IN SCREEN NOWAIT
		ENDIF
	ENDIF
ENDIF
toBrowser.SetBusyState(.F.)
SELECT (lnLastSelect)
SET MESSAGE TO
toBrowser.vResult=lcCode
RETURN toBrowser.vResult
ENDFUNC



FUNCTION brwExportView(toBrowser,tcAlias,tcExportToFile)
LOCAL lcExportToFile,lcAlias,lnLastSelect

IF toBrowser.AddInMethod("EXPORTVIEW")
	RETURN
ENDIF
lcAlias=IIF(EMPTY(tcAlias),toBrowser.cGallery,LOWER(ALLTRIM(tcAlias)))
IF NOT USED(lcAlias)
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
IF VARTYPE(tcExportToFile)=="C" AND NOT EMPTY(tcExportToFile)
	lcExportToFile=ALLTRIM(tcExportToFile)
ELSE
	lcExportToFile=LOWER(PUTFILE(M_SAVE_LOC,"","dbf"))
ENDIF
IF EMPTY(lcExportToFile)
	toBrowser.vResult=.F.
	RETURN toBrowser.vResult
ENDIF
IF NOT ":"$lcExportToFile AND NOT "\\"$lcExportToFile
	lcExportToFile=LOWER(FULLPATH(lcExportToFile))
ENDIF
IF FILE(lcExportToFile)
	IF toBrowser.MsgBox(lcExportToFile+M_ALREADY_EXISTS_OVER_LOC,35)#6
		toBrowser.vResult=.F.
		RETURN toBrowser.vResult
	ENDIF
	ERASE (lcExportToFile)
	IF FILE(lcExportToFile)
		toBrowser.vResult=.F.
		RETURN toBrowser.vResult
	ENDIF
ENDIF
lnLastSelect=SELECT()
SELECT (lcAlias)
COPY TO (lcExportToFile)
SELECT (lnLastSelect)
ENDFUNC



FUNCTION brwValidHTMLText(tcText)

IF VARTYPE(tcText)#"C"
	RETURN ""
ENDIF
RETURN STRTRAN(STRTRAN(STRTRAN(STRTRAN(tcText,[&],[&amp;]),[-],[&ndash;]),[<],[&lt;]),[>],[&gt;])
ENDFUNC



*-- end BROWSER.PRG

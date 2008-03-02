*- DBC wizard engine

#INCLUDE wzdbc.h
#define d_KEY_CHILDTAG		13	&& For RELATION objects: name of child (from) index tag ascii char
#define d_KEY_RELTABLE		18	&& For RELATION objects: name of related table  ascii char
#define d_KEY_RELTAG		19	&& For RELATION objects: name of related index tag  ascii char

DEFINE CLASS DBCEngine AS WizEngineAll

	lInitValue = .t.
	iHelpContextID = 1895825424
	lPopulate = .F.				&& populate tables with sample data - set on Finish page of Wizard
	iModify = 1					&& 2 = modify after done

	PROCEDURE ProcessOutput
		*- this is where the real work is done

		PRIVATE cRIInfo,cParTable,cParTag,cChiTable,cChiTag
		
		LOCAL lnStart,lnSize,lcKey,lcValue,lnRec,lnObjID
		LOCAL cOldSafety, cNewPath, cThisfld, cTagname, iMaxKeyLen, iCurTable, cTableName, cTablePath
		LOCAL cTableFriendlyName, lHaveRels, i, j, k, cOldDatabase, iDBCCount, iRelsCount
		LOCAL cKey, cRefTable, cRefPrimaryKey, cNewTableRef, cShortname, iMaxFields
		LOCAL cNewTagName,lcNewDBCStem,lcOldDBCStem,lnViewCount
		LOCAL lcOldSQL,lcNewSQL,lcViewName

		LOCAL ARRAY aContents[1]
		LOCAL ARRAY aViews[1]
		LOCAL ARRAY aOpenDBCs[1,2]
		LOCAL ARRAY aStru[1,1]
		LOCAL ARRAY aNewFields[1,1]
		LOCAL ARRAY aTempFlds[1,1]

		*- create new database
		cOldSafety = SET("SAFETY")
		
		SET SAFETY ON
		THIS.cOutFile = PUTFILE(C_DESTDBC_LOC, THIS.JustFName(oWizard.cTemplateDBC), "DBC")

		IF EMPTY(THIS.cOutFile)
			RETURN .F.
		ENDIF

		IF LOWER(THIS.cOutFile) == LOWER(oWizard.cTemplateDBC)
			THIS.Alert(E_SAMEDBC_LOC)
			RETURN .F.
		ENDIF
		
		WAIT WINDOW C_BUSYDBC_LOC NOWAIT
		
		SET SAFETY OFF

		*- make sure the DBC isn't already open somehow
		cOldDatabase = SET("DATABASE")
		iDBCCount = ADATABASES(aOpenDBCs)
		FOR i = 1 TO iDBCCount
			IF LOWER(aOpenDBCs[i,2]) = LOWER(THIS.cOutFile)
				SET DATABASE TO (THIS.cOutFile)
				CLOSE DATABASE
				EXIT
			ENDIF
		NEXT

		*- and make sure it's not open as a table either
		iDBCCount = AUSED(aOpenDBCs)
		FOR i = 1 TO iDBCCount
			IF DBF(aOpenDBCs[i,1]) = UPPER(THIS.cOutFile)
				USE IN (aOpenDBCs[i,1])
				EXIT
			ENDIF
		NEXT
				
		CREATE DATABASE (THIS.cOutFile)
		IF !FILE(THIS.cOutFile)
			*- error -- failed to create the database
			THIS.Alert(E_CREATEDBCERR_LOC)
			RETURN .F.
		ENDIF
		
		WAIT WINDOW C_BUSYSTR_LOC NOWAIT
		
		SET DATABASE TO (THIS.cOutFile)
		CLOSE DATABASE
		
		cNewPath = oEngine.AddBS(THIS.JustPath(oEngine.cOutFile))
		
		*- open new DBC
		IF USED("_newDBC")
			USE IN _newDBC
		ENDIF
		SELECT 0
		USE (THIS.cOutFile) ALIAS _newDBC
		IF !USED()
			THIS.Alert(E_OPENDBCERR_LOC)
			RETURN .F.
		ENDIF
		ZAP
		PACK

		IF !USED("_templateDBC")
			SELECT 0
			USE (oWizard.cTemplateDBC) SHARED AGAIN ALIAS _templateDBC
			IF !USED()
				THIS.Alert(E_OPENDBCTEMPERR_LOC)
				RETURN .F.
			ENDIF
		ENDIF
		
		SELECT _templateDBC
		SCAN FOR ALLTRIM(objecttype) = "Database" AND !DELETED()
			SCATTER MEMO TO aContents
			INSERT INTO _newDBC FROM ARRAY aContents
		ENDSCAN
		
		*- add views
		WAIT WINDOW C_BUSYVUE_LOC NOWAIT

		SELECT crsTables
		SCAN FOR lInclude AND LOWER(ALLT(crsTables.objectType)) == "view"
			SELECT _templateDBC
			LOCATE FOR TRIM(objectType) == "View" AND LOWER(TRIM(objectName)) == LOWER(TRIM(crsTables.objectName))
			IF !FOUND()
				LOOP
			ENDIF
			
			iParentID = _templateDBC.objectID
			
			INSERT INTO _newDBC ;
				VALUES (;
					RECNO("_newDBC") + 1, ;
					1, ;
					_templateDBC.objectType, ;
					_templateDBC.objectName, ;
					_templateDBC.property, ;
					_templateDBC.code, ;
					_templateDBC.riinfo, ;
					_templateDBC.user)
			
			iNewParentID = _newDBC.objectID
			
			*- now do fields
			SELECT * FROM _templateDBC ;
				WHERE LOWER(TRIM(_templateDBC.objectType)) = "field"  AND ;
					_templateDBC.parentID = m.iParentID ;
				INTO ARRAY aContents
				
			*- update parentID for these records
			FOR i = 1 TO ALEN(aContents,1)
				aContents[i, 2] = iNewParentID
				aContents[i, 1] = iNewParentID + i
			NEXT
			
			INSERT INTO _newDBC FROM ARRAY aContents

			SELECT crsTables
			
		ENDSCAN		&& doing views
		
		USE IN _newDBC

		WAIT WINDOW C_BUSYDBF_LOC NOWAIT
		
		OPEN DATABASE (THIS.cOutFile)
		SET DATABASE TO (THIS.cOutFile)
		SELECT crsTables
		this.HadError = .f.
		this.SetErrorOff = .t.

		SCAN FOR lInclude AND LOWER(ALLT(crsTables.objectType)) == "table"
			IF USED("_oldDBF")
				USE IN _oldDBF
			ENDIF
			SELECT 0
			USE (TRIM(crsTables.tablePath)) AGAIN SHARED ALIAS _oldDBF
			AFIELDS(aStru)
			cName = ALLTRIM(crsTables.objectName)
			cTablePath = m.cNewpath + ALLT(crsTables.tableName)
			IF FILE(m.cTablePath)
				ERASE (m.cTablePath)
			ENDIF
			IF THIS.HadError					
				EXIT
			ENDIF

			* Added 4/9 by to handle change in behavior from VFP6->VFP7
			* CREATE TABLE with a long name containing spaces in NAME value
			* no longer replaces content with "_" chars.
			cName = CHRTRAN(cName," ","_")
			CREATE TABLE (m.cNewpath + ALLT(crsTables.tableName)) ;
				NAME "&cName" ;
				FROM ARRAY aStru
									
			USE IN _oldDBF
			
			IF THIS.HadError
				EXIT
			ENDIF
			
			IF THIS.lPopulate
				APPEND FROM (TRIM(crsTables.tablePath))
			ENDIF
			
			USE

			cNewTableRef = STRTRAN(ALLT(crsTables.objectName)," ","_")

			*- THIS.SetErrorOff = .F.
			*- set captions, masks and format
			*- CREATE CURSOR crsFields (tablename C(128), fname C(128), fieldname C(50), ftype C(1), flen N(3,0), ;
			*-		fdec N(2,0), fnull L, makeTag L, fpos N(3,0), lnocptrans L, fmask C(128), fformat C(2), tagname C(10), comment c(254))
			SELECT * FROM crsFields ;
				WHERE LOWER(ALLTRIM(tablename)) == LOWER(ALLTRIM(crsTables.tablename));
				INTO ARRAY aTempFlds
				
			FOR i = 1 TO ALEN(aTempFlds,1)
				IF !EMPTY(aTempFlds[i,3])
					DBSETPROP(cNewTableRef + "." + ALLTRIM(aTempFlds[i,2]),"FIELD","CAPTION",ALLTRIM(aTempFlds[i,3]))
				ENDIF
				IF !EMPTY(aTempFlds[i,11])
					DBSETPROP(cNewTableRef + "." + ALLTRIM(aTempFlds[i,2]),"FIELD","INPUTMASK",ALLTRIM(aTempFlds[i,11]))
				ENDIF
				IF !EMPTY(aTempFlds[i,12])
					DBSETPROP(cNewTableRef + "." + ALLTRIM(aTempFlds[i,2]),"FIELD","FORMAT",ALLTRIM(aTempFlds[i,12]))
				ENDIF
				IF !EMPTY(aTempFlds[i,14])
					DBSETPROP(cNewTableRef + "." + ALLTRIM(aTempFlds[i,2]),"FIELD","COMMENT",ALLTRIM(aTempFlds[i,14]))
				ENDIF
				NEXT
		ENDSCAN
		
		IF THIS.HadError
			THIS.Alert(STRTRAN(E_CREATETBLERR_LOC,"@1",m.cTablePath))
			THIS.HadError = .F.
			RETURN .F.
		ENDIF
		
		*- build indexes and update DBC captions

*-	CURSOR crsTables (lInclude L, objectname C(128), objecttype C(10), ;
*-	tablename C(128), tablepath M, objectid I, parentid I, property M, code M, ;
*-	riinfo C(6), user M)

*- 	CURSOR crsFields (tablename C(128), fname C(128), fieldname C(50), ftype C(1), flen N(3,0), ;
*-	fdec N(2,0), fnull L, makeTag L, fpos N(3,0), lnocptrans L, fmask C(128), fformat C(2))

		WAIT WINDOW C_BUSYIDX_LOC NOWAIT
		SELECT crsTables
		*- iCurTable = 1
		*- pass #1 -- indexes
		SCAN FOR crsTables.lInclude AND LOWER(ALLT(crsTables.objectType)) == "table"
			iCurTable = RECNO()
			cTableName = ALLT(crsTables.tablename)
			cShortName = ALLT(crsTables.objectName)
			cNewTableRef = STRTRAN(ALLT(crsTables.objectName)," ","_")
			IF USED("_newTable")
				USE IN _newTable
			ENDIF
			USE (m.cNewpath + ALLT(crsTables.tableName)) ALIAS _newTable IN 0
			
			SELECT * FROM crsFields ;
				WHERE LOWER(ALLTRIM(crsFields.tablename)) == LOWER(ALLTRIM(crsTables.tablename)) ;
				INTO ARRAY aNewFields
			iMaxFields = _TALLY
			
			FOR k = 1 TO iMaxFields
				m.cThisfld = ALLTRIM(aNewFields[k,2])
				m.cTagname = IIF(EMPTY(aNewFields[k,13]),m.cThisFld,ALLTRIM(aNewFields[k,13]))
				m.cTagname = IIF(LEN(m.cTagname) > 10, LEFT(m.cTagname,10), m.cTagname)
				IF aNewFields[k,8]
	  				m.iMaxKeyLen = IIF(SET("collate") == "MACHINE",240,120) - IIF(aNewFields[k,7],1,0)
  					IF aNewFields[k,4] = "C" AND aNewFields[k,5] > m.iMaxKeyLen
  						cIndexExpr = "LEFT(" + m.cThisfld + "," + ALLTRIM(STR(m.iMaxKeyLen)) + ")"
  					ELSE
						cIndexExpr = m.cThisfld
					ENDIF
					DO CASE
					CASE LOWER(ALLT(aNewFields[k,2]))=LOWER(oWizard.aKeyfield[iCurTable])
			  			ALTER TABLE _newtable ADD PRIMARY KEY &cIndexExpr TAG &cTagname
					CASE aNewFields[k,15]
			  			ALTER TABLE _newtable ADD UNIQUE &cIndexExpr TAG &cTagname
	  				OTHERWISE
						*- create the index the old way
						SELECT _newTable
						INDEX ON &cIndexExpr TAG &cTagname
					ENDCASE
				ENDIF
			NEXT
		ENDSCAN
		
*- col 1: description that shows in combobox
*- col 2: name of other table in DBC 
*- col 3: type of relation (1 = none; 2 = 1-many; 3 = many-1
*- col 4: field in other table
*- col 5: tag in linked-to table
*- col 6: key expression in linked to table
*- col 7: possible new key field to add
*- col 8: this table
*- col 9: record #
*- col 10: active? (L -- if table is removed, set to .F. and don't show)
*- col 11: name of tag in this (parent) table
*- CREATE CURSOR crsRels (cDesc C(200), cRelTable C(128), iType I, cRelField C(128), cTag C(10), ;
*-	cKey C(240), cNewKey C(128), cTable C(128), irec I, lActive L, cThisTag C(10))
		*- pass #2 -- relations
		SCAN FOR crsTables.lInclude AND LOWER(ALLT(crsTables.objectType)) == "table"
			iCurTable = RECNO()
			cTableName = ALLT(crsTables.tablename)
			cShortName = ALLT(crsTables.objectName)
			cNewTableRef = STRTRAN(ALLT(crsTables.objectName)," ","_")
			IF USED("_newTable")
				USE IN _newTable
			ENDIF
			USE (m.cNewpath + ALLT(crsTables.tableName)) ALIAS _newTable IN 0

			SELECT * FROM crsRels ;
				WHERE LOWER(TRIM(crsRels.ctable)) == LOWER(TRIM(crsTables.objectname)) AND crsRels.iType > 1 AND crsRels.lActive ;
				INTO ARRAY wzat_rels
			iRelsCount = _TALLY

			SELECT * FROM crsFields ;
				WHERE LOWER(ALLTRIM(crsFields.tablename)) == LOWER(ALLTRIM(crsTables.tablename)) ;
				INTO ARRAY aNewFields
			iMaxFields = _TALLY
						
			FOR k = 1 TO iMaxFields
				m.cThisfld = ALLTRIM(aNewFields[k,2])
				m.cTagname = IIF(EMPTY(aNewFields[k,13]),m.cThisFld,ALLTRIM(aNewFields[k,13]))
				m.cTagname = IIF(LEN(m.cTagname) > 10, LEFT(m.cTagname,10), m.cTagname)

				IF m.iRelsCount > 0
					FOR m.i = 1 TO iRelsCount
						DO CASE
							CASE wzat_rels[m.i, 3] = 2
								*- need to create a 1-many link on this field from primary key
								*- of link-to table
								*- can either be primary or candidate key
								IF LOWER(m.cThisfld)=LOWER(oWizard.aKeyfield[iCurTable]) OR;
									aNewFields[k,15] AND LOWER(m.cThisfld)=LOWER(wzat_rels[m.i,11])
									IF USED("_child")
										USE IN _child
									ENDIF
									cTagname = IIF(!EMPTY(ALLTRIM(wzat_rels[m.i,11])),"TAG " + ALLTRIM(wzat_rels[m.i,11]),"")
									cRefTable = m.cNewPath + JustFName(wzat_rels[m.i, 2])
									USE (cRefTable) ALIAS _child IN 0 AGAIN
									cOtherField = ALLT(wzat_rels[m.i,4])
									cNewTagName = IIF(!EMPTY(ALLT(wzat_rels[m.i,5])),wzat_rels[m.i,5],cOtherField)
									cNewTagName = LOWER(LEFT(ALLT(cNewTagName),10))
									ALTER TABLE _child ;
										ADD FOREIGN KEY &cOtherField  ;
										TAG &cNewTagName ;
										REFERENCES &cNewTableRef ;
										&cTagname
									USE IN _child
								ENDIF
							CASE wzat_rels[m.i, 3] = 3
								*- need to create a many-1 link on this field from primary key
								*- of link-to table
								IF LOWER(wzat_rels[m.i,5]) == LOWER(cTagname)
									cRefTable = STRTRAN(THIS.JustStem(wzat_rels[m.i, 2])," ","_")
									cKey = LOWER(ALLTRIM(aNewFields[k,2]))
									cNewTagName = LEFT(m.cKey,10)
									ALTER TABLE _newtable ;
										ADD FOREIGN KEY &cKey ;
										TAG &cNewTagName ;
										REFERENCES &cRefTable;
										TAG &cTagname
								ENDIF
						ENDCASE
					NEXT
				ENDIF
				
				IF THIS.HadError
					EXIT
				ENDIF
			NEXT	&& going through fields
			
			*- see if user wants to add any new link fields
			IF iRelsCount > 0
				FOR m.i = 1 TO iRelsCount
					IF wzat_rels[i,5] == C_NEWTAG_LOC AND !EMPTY(wzat_rels[i,7])
						*- user wants to add a new field to the child table
						IF USED("_child")
							USE IN _child
						ENDIF
						cTagname = wzat_rels[m.i,7]
						cRefTable = wzat_rels[m.i, 2]
						IF USED(cRefTable)
							USE IN (cRefTable)
						ENDIF
						USE (cRefTable) ALIAS _child IN 0
						DO CASE
							CASE wzat_rels[m.i, 3] == 2
								*- other table is child
								*- figure out the type and length of the new table primary key
								j = oEngine.AColScan(@aNewField, oWizard.aKeyfield[iCurTable],1,.T.)
								IF j == 0
									*- error -- unable to locate the primary key
									EXIT
								ENDIF
								m.cRefPrimaryKey = DBGETPROP(m.cShortname,"Table","PrimaryKey")
								IF EMPTY(m.cRefPrimaryKey)
									*- error -- unable to locate the primary key
									EXIT
								ENDIF
								cKey = wzat_rels[m.i,7]
								ALTER TABLE (m.cRefTable) ;
									ADD FOREIGN KEY ;
									TAG &cKey ;
									REFERENCES &cNewTableRef ;
									TAG &cRefPrimaryKey		
							CASE wzat_rels[m.i, 3] == 3
								*- new table is child
								*- figure out the type and length of the linking table primary key
								m.cRefPrimaryKey = DBGETPROP(m.cRefTable,"Table","PrimaryKey")
								IF EMPTY(m.cRefPrimaryKey)
									*- error -- unable to locate the primary key
									EXIT
								ENDIF
								DIMENSION aChild(1,1)
								iAChildLen = AFIELDS(aChild,"_child")
								j = THIS.AColScan(@aChild, UPPER(m.cRefPrimaryKey),1,.T.)
								IF m.j == 0
									*- error -- unable to locate the primary key
									EXIT
								ENDIF
								cKey = wzat_rels[m.i,7]
								ALTER TABLE (m.cTablename) ;
									ADD FOREIGN KEY ;
									TAG &cKey ;
									REFERENCES &cRefTable;
									TAG &cRefPrimaryKey

						ENDCASE
						USE IN _child
					ENDIF
				NEXT
			ENDIF

		ENDSCAN

		lcNewDBCStem = LOWER(JUSTSTEM(THIS.cOutfile))
		lcOldDBCStem = LOWER(JUSTSTEM(oWizard.cTemplateDBC))
		IF  !(lcNewDBCStem == lcOldDBCStem)
			* Handle updating of local views
			lnViewCount = aDBObject(aViews,"view")
			FOR i = 1 TO lnViewCount
				IF DBGETPROP(aViews[m.i],'view','sourcetype')=1	&&local views
					lcOldSQL = DBGETPROP(aViews[m.i],'view','sql')
					IF ATC("!",lcOldSQL)#0  &&has old DBC references
						lcNewSQL = STRTRAN(lcOldSQL,lcOldDBCStem+"!","")
						lcViewName = aViews[m.i]
						CREATE SQL VIEW (lcViewName) AS &lcNewSQL.
					ENDIF
				ENDIF	
			ENDFOR
		ENDIF
		
		SET SAFETY &cOldSafety
		
		CLOSE DATABASE

		* Manually update any RI Rules if they exist

		CREATE CURSOR csrRIRULES (ParTable m,ChiTable m,ParTag m,ChiTag m,RIEXPR c(6))
		SELECT _templateDBC
		GO TOP
		SCAN FOR ATC(ALLTRIM(objecttype),"Relation")#0 AND !DELETED() AND !EMPTY(ALLTRIM(riinfo))
			STORE "" TO cParTable,cParTag,cChiTable,cChiTag,cRIInfo
			THIS.GetRIInfo(@cParTable,@cParTag,@cChiTable,@cChiTag,@cRIInfo)
			INSERT INTO csrRIRULES VALUES(cParTable,cChiTable,cParTag,cChiTag,cRIInfo)
		ENDSCAN

		IF RECCOUNT("csrRIRULES") > 0 
			SELECT 0
			USE (THIS.cOutFile) ALIAS _newDBC
			IF USED()
				SCAN FOR ATC(ALLTRIM(objecttype),"Relation")#0 AND !DELETED()
					STORE "" TO cParTable,cParTag,cChiTable,cChiTag,cRIInfo
					THIS.GetRIInfo(@cParTable,@cParTag,@cChiTable,@cChiTag,@cRIInfo)
					SELECT csrRIRULES
					LOCATE FOR UPPER(ALLTRIM(ParTable)) == UPPER(ALLTRIM(m.cParTable)) AND;
						UPPER(ALLTRIM(ChiTable)) == UPPER(ALLTRIM(m.cChiTable))
					IF FOUND() AND UPPER(ALLTRIM(ParTag)) == UPPER(ALLTRIM(m.cParTag)) AND;
						UPPER(ALLTRIM(ChiTag)) == UPPER(ALLTRIM(m.cChiTag))
						REPLACE _newDBC.riinfo WITH RIExpr
					ENDIF
					SELECT _newDBC
				ENDSCAN
			ENDIF
		ENDIF
		USE
		SET DATABASE TO (oWizard.cTemplateDBC)
		CLOSE DATABASE
		
		WAIT CLEAR
		
		IF THIS.HadError
			THIS.Alert(C_IDXERR_LOC)
		ELSE
			IF THIS.iModify = 2
				_SHELL = "MODIFY DATABASE [" + THIS.cOutFile + "]"
			ENDIF
		ENDIF
		THIS.SetErrorOff = .F.
		THIS.HadError = .F.

	ENDPROC

	PROCEDURE GetRIInfo
		LPARAMETERS tcParTable, tcParTag, tcChiTable, tcChiTag, tcRIInfo
		
		LOCAL lnStart,lnSize,lcKey,lcValue,lnRec,lnObjID
		tcRIInfo = ALLTRIM(riinfo)
		lnObjID = parentid
		lnStart=1
		do while lnStart<=len(property)
		    lnSize=asc(substr(property,lnStart,1))+;
		           (asc(substr(property,lnStart+1,1))*256)+;
		           (asc(substr(property,lnStart+2,1))*256^2)+;
		           (asc(substr(property,lnStart+3,1))*256^3)
		    lcKey=substr(property,lnStart+6,1)
		    lcValue=substr(property,lnStart+7,lnSize-8)
		    do case
		       case lcKey==chr(d_key_childtag)
		         tcChiTag=lcValue
		       case lcKey==chr(d_key_reltable)
			    IF LEFT(m.lcValue,1) = '"' 
			    	m.lcValue = SUBSTR(m.lcValue,2, LEN(m.lcvalue)-2)	&& bytes, not chars
			    ENDIF
		         tcParTable=lcValue
		       case lcKey==chr(d_key_reltag)
		         tcParTag=lcValue
			endcase
		    lnStart=lnStart+lnSize
		enddo
		lnRec = RECNO()
		LOCATE FOR objectid==lnObjID 
		tcChiTable = ALLTRIM(objectname)
		GO lnRec
	ENDPROC

ENDDEFINE

* Table wizard engine

#INCLUDE wztable.h

DEFINE CLASS TableEngine AS WizEngineAll
	lInitValue = .t.
	iHelpContextID = 1895825424

	PROCEDURE ProcessOutput

		* ---------------------------------------------------------------------------------
		* Create the table and index here. 
		* ---------------------------------------------------------------------------------

		private wzserrorig, fldcount, fpos, wzi, tagname, tagexpr, wzlOKcreate, m.wzsTablename, m.wzalias, ;
			m.lHaveDBC
		LOCAL MaxKeyLen, IndexExpr, cTableFriendlyName, lHaveRels, i, j
		LOCAL cKey, cRefTable, cRefPrimaryKey, cNewTableRef
		LOCAL cNewFldType, cNewFldLen, cNewFldDec, cNewFldNull, cFldChar
		LOCAL cNewAutoInc

		IF oWizard.lCreateDBC
			*- create DBC, add table to it
			CREATE DATABASE (oWizard.cDBCName)
		ENDIF
		
		m.lHaveDBC = oWizard.HaveDBC			&& okay to add to shared DBC
		m.cNewDBC = ""
		
		lHaveRels = !EMPTY(wzat_rels[1,1])
		
		SELECT crsFields
		COUNT FOR NOT DELETED() TO m.fldcount
		
		* rmk - 01/06/2004 - added field to support AutoInc
		DIMENSION wzaStruct[m.fldcount,18]
		DIMENSION wzaExtra[m.fldcount,5]		&& 1 - actual field name
												&& 2 - long field name (caption)
												&& 3 - .T. if indexed
												&& 4 - input mask
												&& 5 - format
		m.wzi = 0
		m.fldstr = ""

		SCAN FOR NOT DELETED()
			m.wzi = m.wzi + 1
			wzaStruct[m.wzi,1] = alltrim(fname)
			wzaStruct[m.wzi,2] = alltrim(ftype)
			wzaStruct[m.wzi,3] = flen
			wzaStruct[m.wzi,4] = fdec
			wzaStruct[m.wzi,5] = fnull
			wzaStruct[m.wzi,6] = lNoCPTrans

			wzaStruct[m.wzi,7] = ''
			wzaStruct[m.wzi,8] = ''
			wzaStruct[m.wzi,9] = ''
			wzaStruct[m.wzi,10] = ''
			wzaStruct[m.wzi,11] = ''
			wzaStruct[m.wzi,12] = ''
			wzaStruct[m.wzi,13] = ''
			wzaStruct[m.wzi,14] = ''
			wzaStruct[m.wzi,15] = ''
			wzaStruct[m.wzi,16] = ''
			IF lAutoInc
				wzaStruct[m.wzi,17] = 1
				wzaStruct[m.wzi,18] = 1
			ELSE
				wzaStruct[m.wzi,17] = 0
				wzaStruct[m.wzi,18] = 0
			ENDIF
			
			* Truncate to 10 if necessary, if a DBC is not involved. Check for duplicate field names and 
			* automatically rename this field to a unique name, using numbers at the end, e.g. "CUSTOMERNAME"
			* shortens to "CUSTOMERNA", and if this is not unique, it gets renamed to "CUSTOMERN1", "CUSTOMERN2"...
			* "CUSTOM9999", until a unique name is found.
			
			IF NOT m.lHaveDBC AND LEN(wzaStruct[m.wzi,1]) > 10
				wzaStruct[m.wzi,1] = LEFT(wzaStruct[m.wzi,1], 10)
				IF " " + wzaStruct[m.wzi,1] + " " $ m.fldstr
					FOR m.wzi2 = 1 TO 10000
						m.dupestr = LTRIM(STR(m.wzi2))
						wzaStruct[m.wzi,1] = LEFT(wzaStruct[m.wzi,1],10-LEN(m.dupestr)) + m.dupestr
						IF NOT " " + wzaStruct[m.wzi,1] + " " $ m.fldstr
							EXIT
						ENDIF
					ENDFOR
				ENDIF
			ENDIF
			
			m.fldstr = " " + wzaStruct[m.wzi,1] + " "
			wzaExtra[m.wzi,1] = wzaStruct[m.wzi,1]
			wzaExtra[m.wzi,2] = ALLTRIM(fieldname)
			wzaExtra[m.wzi,4] = ALLTRIM(fmask)
			wzaExtra[m.wzi,5] = ALLTRIM(fformat)
			IF MakeTag
				wzaExtra[m.wzi,3] = .t.
			ENDIF
		ENDSCAN

		m.cShortname = IIF("\" $ oWizard.cTableName, SUBSTR(oWizard.cTableName,RATC("\",oWizard.cTableName)+1), ;
 							oWizard.cTableName)
		m.cShortname = UPPER(IIF("." $ m.cShortname, LEFT(m.cShortname, AT(".",m.cShortname)-1), m.cShortname))

		IF oWizard.DBCFlag = 2								&& table exists in dbc, user wants to overwrite it
			IF ADBOBJ(wzatemp,"TABLE") > 0 AND ASCAN(wzatemp, m.cShortname) > 0
				REMOVE TABLE (m.cShortname)
			ENDIF
		ENDIF
					
		m.wzserrorig = on("error")
		on error do THISFORMSET.ALERT(C_TBLERR_LOC)

		m.wzsTablename = oWizard.cTableName
		m.cTableFriendlyName = LEFT(ALLTRIM(oWizard.cTableFriendlyName),128)
		DO CASE
			CASE !m.lHaveDBC
				CREATE TABLE (m.wzsTablename) FREE FROM ARRAY wzaStruct 
			CASE !EMPTY(oWizard.cTableFriendlyName)
				CREATE TABLE (m.wzsTablename) NAME "&cTableFriendlyName" FROM ARRAY wzaStruct
			OTHERWISE
				CREATE TABLE (m.wzsTablename) FROM ARRAY wzaStruct
		ENDCASE
		cNewTableRef = IIF(!EMPTY(m.cTableFriendlyName),STRTRAN(m.cTableFriendlyName," ","_"),m.cShortname)
		
		*- reopen table, and give it a safe alias
		IF USED("_newtable")
			USE IN _newtable
		ENDIF
		USE (m.wzsTablename) ALIAS _newtable
		
		on error &wzserrorig

		m.wzlOKcreate = (DBF() = oWizard.cTableName)
		m.wzalias = ALIAS()

		IF m.wzlOKcreate

			oEngine.cOutfile = oWizard.cTableName
			m.cOutputFilename = oWizard.cTableName

			*- build indexes and update DBC captions
			this.HadError = .f.
			this.SetErrorOff = .t.
			SELECT (m.wzalias)
	  		FOR m.wzi = 1 TO m.fldcount
	  			m.thisfld = wzaExtra[m.wzi,1]
				m.tagname = IIF(LEN(m.thisfld) > 10, LEFT(m.thisfld,10), m.thisfld)
	  			IF wzaExtra[m.wzi,3]
	  				*- create an index
	  				m.MaxKeyLen = IIF(SET("collate") == "MACHINE",240,120) - IIF(wzaStruct[m.wzi,5],1,0)
  					IF wzaStruct[m.wzi,2] = "C" AND wzaStruct[m.wzi,3] > m.MaxKeyLen
  						IndexExpr = "LEFT(" + thisfld + "," + ALLTRIM(STR(m.MaxKeyLen)) + ")"
  					ELSE
						IndexExpr = thisfld
					ENDIF
		  			IF wzaExtra[m.wzi,1] = oWizard.Keyfield
			  			ALTER TABLE (m.wzsTablename) ADD PRIMARY KEY &indexexpr TAG &tagname
	  				ELSE
						*- create the index the old way
						INDEX ON &indexexpr TAG &tagname
					ENDIF					
				ENDIF
				IF m.lHaveDBC
  					*- check to see if we need to create a relation on this field
					*- wzat_rels[n,7]:
					*- col 1: description that shows in combobox
					*- col 2: name of other table in DBC 
					*- col 3: type of relation (1 = none; 2 = 1-many; 3 = many-1
					*- col 4: the primary key in the parent table
					*- col 5: tag in child table
					*- col 6: key expression in child table
					*- col 7: possible new key field to add
					IF m.lHaveRels
						FOR m.i = 1 TO ALEN(wzat_rels,1)
							IF wzat_rels[i,5] == C_NEWTAG_LOC
								LOOP
							ENDIF
							DO CASE
								CASE wzat_rels[m.i, 3] == 2
									*- need to create a 1-many link on this field from primary key
									*- of link-to table
									IF wzaExtra[m.wzi,1] = oWizard.Keyfield	&& LOWER(wzat_rels[m.i,6]) == LOWER(indexexpr)
										IF USED("_child")
											USE IN _child
										ENDIF
										tagname = wzat_rels[m.i,4]
										cRefTable = wzat_rels[m.i, 2]
										USE (cRefTable) ALIAS _child IN 0 AGAIN
										cKey = UPPER(wzat_rels[m.i,6])
										ALTER TABLE _child ;
											ADD FOREIGN KEY &cKey ;
											TAG &cKey ;
											REFERENCES &cNewTableRef ;
											TAG &tagname
										USE IN _child
									ENDIF
								CASE wzat_rels[m.i, 3] == 3
									*- need to create a 1-many link on this field from primary key
									*- of link-to table
									IF LOWER(wzat_rels[m.i,5]) == LOWER(tagname)
										cRefTable = wzat_rels[m.i, 2]
										cKey = wzaStruct[m.wzi,1]
										ALTER TABLE (m.wzsTablename) ;
											ADD FOREIGN KEY &cKey ;
											TAG &cKey ;
											REFERENCES &cRefTable;
											TAG &tagname
									ENDIF
							ENDCASE
						NEXT
					ENDIF		&& m.lHaveRels
					=DBSETPROP(m.cNewTableRef + "." + wzaExtra[m.wzi,1],"FIELD","CAPTION",wzaExtra[m.wzi,2])
					=DBSETPROP(m.cNewTableRef + "." + wzaExtra[m.wzi,1],"FIELD","INPUTMASK",wzaExtra[m.wzi,4])
					=DBSETPROP(m.cNewTableRef + "." + wzaExtra[m.wzi,1],"FIELD","FORMAT",wzaExtra[m.wzi,5])
				ENDIF
				IF THIS.HadError
					EXIT
				ENDIF
			ENDFOR
			*- see if user wants to add any new link fields
			IF m.lHaveDBC AND m.lHaveRels
				FOR m.i = 1 TO ALEN(wzat_rels,1)
					IF wzat_rels[i,5] == C_NEWTAG_LOC AND !EMPTY(wzat_rels[i,7])
						*- user wants to add a new field to the child table
						IF USED("_child")
							USE IN _child
						ENDIF
						tagname = wzat_rels[m.i,7]
						cRefTable = wzat_rels[m.i, 2]
						IF USED(cRefTable)
							USE IN (cRefTable)
						ENDIF
						USE (cRefTable) ALIAS _child IN 0
						DO CASE
							CASE wzat_rels[m.i, 3] == 2
								*- other table is child
								*- figure out the type and length of the new table primary key
								j = oEngine.AColScan(@wzaExtra, oWizard.Keyfield,1,.T.)
								IF j == 0
									*- error -- unable to locate the primary key
									EXIT
								ELSE
									cNewFldType = wzaStruct[j, 2]
									cNewFldLen = wzaStruct[j, 3]
									cNewFldDec = wzaStruct[j, 4]
									cNewFldNull = IIF(wzaStruct[j, 5], "NULL", "NOT NULL")
									cNewCPTrans = IIF(wzaStruct[j, 6], "NOCPTRANS", "")
									cNewAutoInc = IIF(wzaStruct[j, 6], "AUTOINC", "")
									cFldChar = cNewFldType + " (" + LTRIM(STR(cNewFldLen)) + "," + LTRIM(STR(cNewFldDec)) + ") " + ;
										cNewFldNull + cNewAutoInc + cNewCPTrans
								ENDIF
								m.cRefPrimaryKey = DBGETPROP(m.cShortname,"Table","PrimaryKey")
								IF EMPTY(m.cRefPrimaryKey)
									*- error -- unable to locate the primary key
									EXIT
								ENDIF
								cKey = wzat_rels[m.i,7]
								ALTER TABLE (m.cRefTable) ;
									ADD COLUMN &cKey &cFldChar ;
									REFERENCES &cNewTableRef ;
									TAG &cRefPrimaryKey
									
								#IF 0
									ADD FOREIGN KEY
									TAG &cKey
								#ENDIF
								
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
								j = oEngine.AColScan(@aChild, UPPER(m.cRefPrimaryKey),1,.T.)
								IF m.j == 0
									*- error -- unable to locate the primary key
									EXIT
								ELSE
									cNewFldType = aChild[j, 2]
									cNewFldLen = aChild[j, 3]
									cNewFldDec = aChild[j, 4]
									cNewFldNull = IIF(aChild[j, 5], "NULL", "NOT NULL")
									cNewCPTrans = IIF(aChild[j, 6], "NOCPTRANS", "")
									cNewAutoInc = IIF(aChild[j, 7], "AUTOINC", "")
									cFldChar = cNewFldType + " (" + LTRIM(STR(cNewFldLen)) + "," + LTRIM(STR(cNewFldDec)) + ") " + ;
										cNewFldNull + cNewAutoInc + cNewCPTrans
								ENDIF
								cKey = wzat_rels[m.i,7]
								ALTER TABLE (m.wzsTablename) ;
									ADD COLUMN &cKey &cFldChar ;
									REFERENCES &cRefTable;
									TAG &cRefPrimaryKey
									
								*-	ADD FOREIGN KEY
								*-	TAG &cKey
						ENDCASE
						USE IN _child
					ENDIF
				NEXT
			ENDIF
			
			
			USE IN (m.wzalias)
		  	SELECT crsFields
		  	
			IF THIS.HadError
				THIS.Alert(C_IDXERR_LOC)
				THIS.SetErrorOff = .F.
				THIS.HadError = .F.
			ENDIF
			
		ENDIF
		
	ENDPROC

ENDDEFINE

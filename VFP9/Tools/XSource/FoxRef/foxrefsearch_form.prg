* Abstract...:
*	Search / Replace functionality for a Form or Class Libary (SCX, VCX).
*
* Changes....:
*
#include "foxref.h"
#include "foxpro.h"

DEFINE CLASS RefSearchForm AS RefSearch OF FoxRefSearch.prg
	Name = "RefSearchForm"

	NoRefresh        = .F.
	BackupExtensions = "SCX,SCT"

	FUNCTION OpenFile(lReadWrite)
		LOCAL oError

		m.oError = .NULL.

		IF USED(TABLEFIND_ALIAS)
			USE IN (TABLEFIND_ALIAS)
		ENDIF
		
		TRY
			IF m.lReadWrite
				USE (THIS.Filename) ALIAS TABLEFIND_ALIAS IN 0 SHARED AGAIN
			ELSE
				USE (THIS.Filename) ALIAS TABLEFIND_ALIAS IN 0 SHARED AGAIN NOUPDATE
			ENDIF

		CATCH TO oError
		ENDTRY

		IF ISNULL(m.oError) AND USED(TABLEFIND_ALIAS)
			TRY
				IF ;
				 TYPE(TABLEFIND_ALIAS + ".Methods") == 'M' AND ;
				 TYPE(TABLEFIND_ALIAS + ".Platform") == 'C' AND ;
				 TYPE(TABLEFIND_ALIAS + ".UniqueID") == 'C'
					SELECT TABLEFIND_ALIAS
				ELSE
					USE IN (TABLEFIND_ALIAS)
					THROW ERROR_NOTFORM_LOC
				ENDIF

			CATCH TO oError WHEN oError.ErrorNo == 2071
			CATCH TO oError
			ENDTRY
		ENDIF

		RETURN m.oError
	ENDFUNC
	
	FUNCTION CloseFile()
		IF USED(TABLEFIND_ALIAS)
			USE IN (TABLEFIND_ALIAS)
		ENDIF
		
		RETURN .T.
	ENDFUNC

	FUNCTION DoDefinitions()
		LOCAL nSelect
		LOCAL cObjName
		LOCAL cClassName
		LOCAL cRootClass
	
		nSelect = SELECT()
		
		cRootClass = .NULL.

		SELECT TABLEFIND_ALIAS

		SCAN ALL FOR PlatForm = "WINDOWS" AND !EMPTY(Methods)
			IF Reserved1 == "Class"
				cRootClass = ObjName
			ENDIF

			IF EMPTY(Parent)
				IF BaseClass == "dataenvironment"
					cObjName = ObjName
				ELSE
					cObjName = ''
				ENDIF
				cClassName = Class
			ELSE
				IF AT_C('.', Parent) == 0
					cClassName = Parent
					cObjName = ObjName
				ELSE
					cClassName = LEFTC(Parent, AT_C('.', Parent) - 1)
					cObjName = SUBSTRC(Parent, AT_C('.', Parent) + 1) + '.' + ObjName
				ENDIF
			ENDIF
			THIS.FindDefinitions(Methods, NVL(cRootClass, cClassName), cObjName, SEARCHTYPE_NORMAL)
		ENDSCAN

		SELECT (nSelect)
	ENDFUNC

	FUNCTION DoSearch()
		LOCAL nSelect
		LOCAL cObjName
		LOCAL cClassName
		LOCAL cRootClass
		LOCAL lSuccess

		nSelect = SELECT()

		cRootClass = .NULL.

		m.lSuccess = .T.

		SELECT TABLEFIND_ALIAS
		
		IF RECCOUNT() > 0 AND !EMPTY(Reserved8)
			&& this is where global include file is stored for a form
			THIS.AddFileToProcess( ;
			  DEFTYPE_INCLUDEFILE, ;
			  Reserved8, ;
			  '', ;
			  '', ;
			  1, ;
			  1, ;
			  Reserved8 ;
			 )
			m.lSuccess = THIS.FindInText(Reserved8, FINDTYPE_TEXT, '', '', SEARCHTYPE_NORMAL, UniqueID, "RESERVED8")
		ENDIF
		
		SCAN ALL FOR PlatForm = "WINDOWS"
			IF Reserved1 == "Class"
				cRootClass = ObjName
				
				IF !EMPTY(Reserved8) && this is where global include file is stored for a class
					THIS.AddFileToProcess( ;
					  DEFTYPE_INCLUDEFILE, ;
					  Reserved8, ;
					  NVL(cRootClass, cClassName), ;
					  '', ;
					  1, ;
					  1, ;
					  Reserved8 ;
					 )

					m.lSuccess = THIS.FindInText(Reserved8, FINDTYPE_TEXT, NVL(cRootClass, cClassName), cObjName, SEARCHTYPE_NORMAL, UniqueID, "RESERVED8")
				ENDIF
			ENDIF


			IF EMPTY(Parent)
				IF BaseClass == "dataenvironment"
					cObjName = ObjName
				ELSE
					cObjName = ''
				ENDIF
				cClassName = Class
			ELSE
				IF AT_C('.', Parent) == 0
					cClassName = Parent
					cObjName = ObjName
				ELSE
					cClassName = LEFTC(Parent, AT_C('.', Parent) - 1)
					cObjName = SUBSTRC(Parent, AT_C('.', Parent) + 1) + '.' + ObjName
				ENDIF
			ENDIF

			* defined properties and methods
*!*				IF !EMPTY(Reserved3)
*!*					m.lSuccess = THIS.FindDefinedPEMS(Reserved3, NVL(cRootClass, cClassName), cObjName, SEARCHTYPE_EXPR, UniqueID)
*!*				ENDIF

			IF !EMPTY(Reserved3)
				m.lSuccess = THIS.FindDefinedMethods(Reserved3, NVL(cRootClass, cClassName), cObjName, SEARCHTYPE_EXPR, UniqueID)
			ENDIF

			IF !EMPTY(Methods)
				m.lSuccess = THIS.FindInCode(Methods, FINDTYPE_CODE, NVL(cRootClass, cClassName), cObjName, SEARCHTYPE_METHOD, UniqueID, "METHODS")
			ENDIF
			IF !THIS.CodeOnly
				IF !EMPTY(ObjName)
					m.lSuccess = THIS.FindInText(ObjName, FINDTYPE_NAME, NVL(cRootClass, cClassName), cObjName, SEARCHTYPE_EXPR, UniqueID, "OBJNAME", .T.)
				ENDIF
			ENDIF

			IF THIS.FormProperties AND !EMPTY(Properties)
				m.lSuccess = THIS.FindInProperties(Properties, Reserved3, NVL(cRootClass, cClassName), cObjName, SEARCHTYPE_EXPR, UniqueID)
			ENDIF
		ENDSCAN
		SELECT (nSelect)
		
		RETURN m.lSuccess
	ENDFUNC


	FUNCTION DoReplace(cReplaceText AS String, oReplaceCollection)
		LOCAL nSelect
		LOCAL cObjCode
		LOCAL oFoxRefRecord
		LOCAL cRefCode
		LOCAL cColumn
		LOCAL cTable
		LOCAL cUpdField
		LOCAL cRecordID
		LOCAL cNewText
		LOCAL oError
		LOCAL i
		LOCAL oMethodCollection
		
		m.oError = .NULL.

		nSelect = SELECT()

		oFoxRefRecord = oReplaceCollection.Item(1)
		cRefCode  = oFoxRefRecord.Abstract
		cColumn   = RTRIM(oFoxRefRecord.ClassName)
		cTable    = JUSTSTEM(THIS.Filename)
		cUpdField = RTRIM(oFoxRefRecord.UpdField)
		cRecordID = oFoxRefRecord.RecordID
		cNewText  = cRefCode

		SELECT TABLEFIND_ALIAS
		LOCATE FOR UniqueID == cRecordID
		IF FOUND()
			TRY
				DO CASE
				CASE cUpdField = "METHODS"
					cNewText = Methods
					FOR m.i = oReplaceCollection.Count TO 1 STEP -1
						oFoxRefRecord = oReplaceCollection.Item(m.i)
						m.cNewText = THIS.ReplaceText(m.cNewText, oFoxRefRecord.LineNo, oFoxRefRecord.ColPos, oFoxRefRecord.MatchLen, m.cReplaceText, oFoxRefRecord.Abstract)
					ENDFOR

*!*						FOR EACH oFoxRefRecord IN oReplaceCollection
*!*							cNewText = THIS.ReplaceText(cNewText, oFoxRefRecord.LineNo, oFoxRefRecord.ColPos, oFoxRefRecord.MatchLen, cReplaceText, oFoxRefRecord.Abstract)
*!*						ENDFOR
					
					IF ISNULL(cNewText)
						THROW ERROR_REPLACE_LOC
					ELSE
						cObjCode = THIS.CompileCode(cNewText)
						IF !ISNULL(cObjCode)
							* update reserved3 and protected field which correspeonds to our list of properties and methods
							REPLACE ;
							  Methods WITH cNewText, ;
							  ObjCode WITH cObjCode ;
							 IN TABLEFIND_ALIAS

							IF !EMPTY(TimeStamp)
								REPLACE TimeStamp WITH THIS.RowTimeStamp() IN TABLEFIND_ALIAS
							ENDIF
						ENDIF
					ENDIF

				CASE cUpdField = "RESERVED8"
					cNewText = Reserved8
					FOR m.i = oReplaceCollection.Count TO 1 STEP -1
						oFoxRefRecord = oReplaceCollection.Item(m.i)
						m.cNewText = THIS.ReplaceText(m.cNewText, oFoxRefRecord.LineNo, oFoxRefRecord.ColPos, oFoxRefRecord.MatchLen, m.cReplaceText, oFoxRefRecord.Abstract)
					ENDFOR
*!*						FOR EACH oFoxRefRecord IN oReplaceCollection
*!*							m.cNewText = THIS.ReplaceText(m.cNewText, oFoxRefRecord.LineNo, oFoxRefRecord.ColPos, oFoxRefRecord.MatchLen, m.cReplaceText, m.oFoxRefRecord.Abstract)
*!*						ENDFOR
					IF ISNULL(cNewText)
						THROW ERROR_REPLACE_LOC
					ELSE
						REPLACE ;
						  Reserved8 WITH cNewText ;
						 IN TABLEFIND_ALIAS

						IF !EMPTY(TimeStamp)
							REPLACE TimeStamp WITH THIS.RowTimeStamp() IN TABLEFIND_ALIAS
						ENDIF
					ENDIF

				CASE cUpdField = "METHODNAME"
					* replacement not supported

				CASE cUpdField = "PROPERTYNAME"
					* replacement not supported
*!*						cNewText = Properties
*!*						FOR EACH oFoxRefRecord IN oReplaceCollection
*!*							cNewText = THIS.ReplaceText(cNewText, oFoxRefRecord.LineNo, oFoxRefRecord.ColPos, oFoxRefRecord.MatchLen, cReplaceText, oFoxRefRecord.Abstract)
*!*						ENDFOR

				CASE cUpdField = "PROPERTYVALUE"
					* replacement not supported
*!*						cNewText = Properties
*!*						FOR EACH oFoxRefRecord IN oReplaceCollection
*!*							cNewText = THIS.ReplaceText(cNewText, oFoxRefRecord.LineNo, oFoxRefRecord.ColPos, oFoxRefRecord.MatchLen, cReplaceText, oFoxRefRecord.Abstract)
*!*						ENDFOR

				CASE cUpdField = "OBJNAME"
				ENDCASE

			CATCH TO oError WHEN oError.ErrorNo == 2071
			CATCH TO oError WHEN oError.ErrorNo == 111  && read-only
				THROW REPLACE_READONLY_LOC
			CATCH TO oError
				THROW oError.Message
			ENDTRY
		ENDIF
	
		SELECT (nSelect)
		
		RETURN m.oError
	ENDFUNC


	FUNCTION DoReplaceLog(cReplaceText, oReplaceCollection AS Collection)
		LOCAL cRefCode
		LOCAL cNewText
		LOCAL cColumn
		LOCAL cTable
		LOCAL cRuleExpr
		LOCAL cUpdField
		LOCAL cLog
		LOCAL oError
		LOCAL oFoxRefRecord
		LOCAL cDatabase

		m.cLog = ''
		m.oError = .NULL.

		oFoxRefRecord = oReplaceCollection.Item(1)
		cRefCode  = oFoxRefRecord.Abstract
		cColumn   = RTRIM(oFoxRefRecord.ClassName)
		cTable    = JUSTSTEM(THIS.Filename)
		cUpdField = RTRIM(oFoxRefRecord.UpdField)
		cNewText  = cRefCode

		FOR EACH oFoxRefRecord IN oReplaceCollection
			cNewText  = LEFTC(cNewText, oFoxRefRecord.ColPos - 1) + cReplaceText + SUBSTRC(cNewText, oFoxRefRecord.ColPos + oFoxRefRecord.MatchLen)
		ENDFOR

		TRY
			DO CASE
			CASE cUpdField = "PROPERTYNAME"
				m.cLog = LOG_PREFIX + REPLACE_NOTSUPPORTED_LOC

			CASE cUpdField = "PROPERTYVALUE"
				m.cLog = LOG_PREFIX + REPLACE_NOTSUPPORTED_LOC

			CASE cUpdField = "OBJNAME"
				m.cLog = LOG_PREFIX + REPLACE_NOTSUPPORTED_LOC

			CASE cUpdField = "METHODNAME"
				m.cLog = LOG_PREFIX + REPLACE_NOTSUPPORTED_LOC

			ENDCASE

		CATCH TO oError
		ENDTRY
	
		RETURN m.cLog
	ENDFUNC
ENDDEFINE

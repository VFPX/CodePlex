* <summary>
*	Create VCX from PRG file.
*
* <remarks>
*	First created 06/13/03 by RMK
#define PROCINFO_CONTENT	1
#define PROCINFO_LINENO		2
#define PROCINFO_TYPE		3
#define PROCINFO_INDENT		4

* Definition Types used in RefDef.dbf
#define DEFTYPE_NONE			' '
#define DEFTYPE_PARAMETER		'P'
#define DEFTYPE_LOCAL			'L'
#define DEFTYPE_PRIVATE			'V'
#define DEFTYPE_PUBLIC			'G'
#define DEFTYPE_PROCEDURE		'F'
#define DEFTYPE_CLASS			'C'
#define DEFTYPE_PROPERTY		'='
#define DEFTYPE_INCLUDEFILE		'I'
#define DEFTYPE_SETCLASSPROC	'S'

#define VISIBILITY_PUBLIC		'G'
#define VISIBILITY_HIDDEN		'H'
#define VISIBILITY_PROTECTED	'P'

#define MAX_TOKENS			100

#define EMPTYVCX_FILENAME	"emptyvcx.vcx"

#define NEWLINE				CHR(13) + CHR(10)
#define TAB					CHR(9)

#define VCX_VERSION			"VERSION =   3.00"


* <summary>
* 	Wrapper around a VCX file.  Add objects	and then call methods 
*	to write to a VCX file or cursor.  Also has support for
*	parsing a PRG file into wrapper objects.
DEFINE CLASS VCXWrapper AS Custom
	PRGFile = ''
	
	ADD OBJECT oClassCollection AS Collection
	

	* <summary>
	*	Add a new class to the Class Library.
	*
	* <returns>	
	*	References to class object.
	*
	* <parameters>
	* 	cClassName - name of class (ObjName in VCX)
	*	cParentClass - name of parent class
	*	[cClassLoc] - location of prg/vcx where parent class can be found
	*	[lOlePublic] - TRUE if this class should be marked OlePublic
	*	[nLineNo] - line # class can be found on
	FUNCTION AddClass(cClassName, cParentClass, cClassLoc, lOlePublic, nLineNo)
		LOCAL oClass
		
		m.oClass = CREATEOBJECT("VCXClass", THIS.PRGFile, m.cClassName, m.cParentClass, m.cClassLoc, m.lOlePublic, m.nLineNo)
		THIS.oClassCollection.Add(m.oClass)
		
		RETURN m.oClass
	ENDFUNC


	* <summary>
	*	Create VCX file on disk based upon currently
	*	defined classes in this VCX wrapper.
	*
	* <returns>	
	*	TRUE on success.
	*
	* <parameters>
	* 	cFilename - name of VCX file
	*	[lNoCompile] - true to not compile VCX (so ObjCode will not be up-to-date)
	FUNCTION CreateVCX(cFilename, lNoCompile)
		LOCAL nSelect
		LOCAL cSafety
		
		nSelect = SELECT()

		IF THIS.CreateVCXCursor("TempCursor", .F.)
			IF EMPTY(JUSTEXT(m.cFilename))
				m.cFilename = FORCEEXT(cFilename, "vcx")
			ENDIF
			
			m.cSafety = SET("SAFETY")
			SET SAFETY OFF
			COPY TO (m.cFilename)
			
			IF !m.lNoCompile
				COMPILE CLASSLIB (m.cFilename)
			ENDIF
			
			SET SAFETY &cSafety
		ENDIF
		IF USED("TempCursor")
			USE IN TempCursor
		ENDIF
		
		SELECT (nSelect)
		
		RETURN .T.
	ENDFUNC
	
	* <summary>
	*	Create a cursor representing the VCX.
	*
	* <returns>	
	*	TRUE on success
	*
	* <parameters>
	* 	cAlias - alias name of cursor to create
	*	[lIncludeLineNo] - TRUE to include Line # fields in VCX
	*		NOTE: this is used for Class Browser support
	FUNCTION CreateVCXCursor(cAlias, lIncludeLineNo)
		LOCAL i
		LOCAL j
		
		IF USED(m.cAlias)
			USE IN (m.cAlias)
		ENDIF
		
		IF m.lIncludeLineNo
			CREATE CURSOR (m.cAlias) ( ;
			 Platform C(8), ;
			 UniqueID C(10), ;
			 Timestamp N(10, 0), ;
			 Class M, ;
			 ClassLoc M, ;
			 BaseClass M, ;
			 ObjName M, ;
			 Parent M, ;
			 Properties M, ;
			 Protected M, ;
			 Methods M, ;
			 ObjCode M, ;
			 Ole M, ;
			 Ole2 M, ;
			 Reserved1 M, ;
			 Reserved2 M, ;
			 Reserved3 M, ;
			 Reserved4 M, ;
			 Reserved5 M, ;
			 Reserved6 M, ;
			 Reserved7 M, ;
			 Reserved8 M, ;
			 User M, ;
			 LineNo I, ;
			 PEMLineNo M ;
 			)
		ELSE
			CREATE CURSOR (m.cAlias) ( ;
			 Platform C(8), ;
			 UniqueID C(10), ;
			 Timestamp N(10, 0), ;
			 Class M, ;
			 ClassLoc M, ;
			 BaseClass M, ;
			 ObjName M, ;
			 Parent M, ;
			 Properties M, ;
			 Protected M, ;
			 Methods M, ;
			 ObjCode M, ;
			 Ole M, ;
			 Ole2 M, ;
			 Reserved1 M, ;
			 Reserved2 M, ;
			 Reserved3 M, ;
			 Reserved4 M, ;
			 Reserved5 M, ;
			 Reserved6 M, ;
			 Reserved7 M, ;
			 Reserved8 M, ;
			 User M ;
			)
		ENDIF
		
		* Header written as first record of every VCX
		INSERT INTO (cAlias) ( ;
		 Platform, ;
		 UniqueID, ;
		 Reserved1 ;
		) VALUES ( ;
		 "COMMENT", ;
		 "Class", ;
		 VCX_VERSION ;
		)

		FOR m.i = 1 TO THIS.oClassCollection.Count
			* each class is made up of at least a header
			* and a footer
			WITH THIS.oClassCollection.Item(i)
				THIS.InsertClassRecord(m.cAlias, THIS.oClassCollection.Item(i), '', m.lIncludeLineNo)

				* add in each of the contained objects
				FOR m.j = 1 TO .oObjectCollection.Count
					THIS.InsertClassRecord(m.cAlias, .oObjectCollection.Item(j), THIS.oClassCollection.Item(i).cClassName, m.lIncludeLineNo)
				ENDFOR


				* footer
				INSERT INTO (m.cAlias) ( ;
				 Platform, ;
				 UniqueID, ;
				 ObjName, ;
				 Properties, ;
				 Reserved2 ;
				) VALUES ( ;
				 "COMMENT", ;
				 "RESERVED", ;
				 .cClassName, ;
				 "Arial, 0, 9, 5, 15, 12, 32, 3, 0", ;
				 IIF(.lOlePublic, "OLEPublic", '') ;
				)
			ENDWITH	
		ENDFOR
		
		GOTO TOP IN (m.cAlias)
		
		RETURN .T.
	ENDFUNC
	
	
	* <summary>
	*	Insert a new record representing a class into
	*	the VCX file/cursor.
	*
	* <returns>	
	*	TRUE on success
	*
	* <parameters>
	* 	cAlias - name of cursor to insert into
	*	oClassInfo - object representing class to insert
	*	[cParent] - name of parent if this is a contained class
	*	[lIncludeLineNo] - TRUE if line #s are included in output
	PROTECTED FUNCTION InsertClassRecord(cAlias, oClassInfo, cParent, lIncludeLineNo)
		LOCAL i
		LOCAL cProperties
		LOCAL cMethods
		LOCAL cReserved3
		LOCAL cProtected
		LOCAL cPEMLineNo

		IF VARTYPE(m.cParent) <> 'C'
			m.cParent = ''
		ENDIF

		m.cProperties = ''
		m.cMethods    = ''
		m.cReserved3  = ''
		m.cProtected  = ''
		m.cPEMLineNo  = ''

		* properties
		FOR m.i = 1 TO oClassInfo.oPropertyCollection.Count
			WITH oClassInfo.oPropertyCollection.Item(m.i)
				m.cProperties = m.cProperties + ;
				  .cPropertyName + " = " + .cValue + NEWLINE

				m.cReserved3 = m.cReserved3 + ;
				  .cPropertyName + NEWLINE

				IF m.lIncludeLineNo
					m.cPEMLineNo = m.cPEMLineNo + ;
					  .cPropertyName + '=' + TRANSFORM(.nLineNo) + NEWLINE
				ENDIF

				DO CASE
				CASE .cVisibility == VISIBILITY_PROTECTED
					m.cProtected = m.cProtected + ;
					  .cPropertyName + NEWLINE

				CASE .cVisibility == VISIBILITY_HIDDEN
					m.cProtected = m.cProtected + ;
					  .cPropertyName + '^' + NEWLINE
				ENDCASE
			ENDWITH
		ENDFOR

		* methods
		FOR m.i = 1 TO oClassInfo.oMethodCollection.Count
			WITH oClassInfo.oMethodCollection.Item(i)
				m.cMethods = m.cMethods + ;
				  "PROCEDURE " + .cMethodName + NEWLINE + ;
				  IIF(EMPTY(.cCode), '', .cCode + NEWLINE) + ;
				  "ENDPROC" + NEWLINE

				m.cReserved3 = m.cReserved3 + ;
				  "*" + .cMethodName + ' ' + NEWLINE

				IF m.lIncludeLineNo
					m.cPEMLineNo = m.cPEMLineNo + ;
					  .cMethodName + '=' + TRANSFORM(.nLineNo) + NEWLINE
				ENDIF

				DO CASE
				CASE .cVisibility == VISIBILITY_PROTECTED
					m.cProtected = m.cProtected + ;
					  .cMethodName + NEWLINE

				CASE .cVisibility == VISIBILITY_HIDDEN
					m.cProtected = m.cProtected + ;
					  .cMethodName + '^' + NEWLINE
				ENDCASE
			ENDWITH
			
		ENDFOR

	
		WITH m.oClassInfo
			INSERT INTO (m.cAlias) ( ;
			 Platform, ;
			 UniqueID, ;
			 Timestamp, ;
			 Class, ;
			 ClassLoc, ;
			 BaseClass, ;
			 ObjName, ;
			 Parent, ;
			 Properties, ;
			 Methods, ;
			 Protected, ;
			 Reserved1, ;
			 Reserved2, ;
			 Reserved3, ;
			 Reserved6 ;
			) VALUES ( ;
			 "WINDOWS", ;
			 SYS(2015), ;
			 THIS.RowTimeStamp(), ;
			 .cParentClass, ;
			 .cClassLoc, ;
			 EVL(.cBaseClass, .cParentClass), ;
			 .cClassName, ;
			 m.cParent, ;
			 m.cProperties, ;
			 m.cMethods, ;
			 m.cProtected, ;
			 IIF(EMPTY(m.cParent), "Class", ''), ;  && don't put anything in here for contained objects
			 TRANSFORM(1 + .oObjectCollection.Count), ;
			 m.cReserved3, ;
			 "Pixels" ;
			)

			IF m.lIncludeLineNo		
				REPLACE ;
				  LineNo WITH .nLineNo, ;
				  PEMLineNo WITH m.cPEMLineNo ;
				 IN (m.cAlias)
			ENDIF
		ENDWITH
		
		RETURN .T.
	ENDFUNC
	
	* Generate a FoxPro 3.0-style row timestamp
	PROTECTED FUNCTION RowTimeStamp(tDateTime)
		LOCAL cTimeValue

		IF VARTYPE(m.tDateTime) <> 'T'
			m.tDateTime = DATETIME()
			m.cTimeValue = TIME()
		ELSe
			m.cTimeValue = TTOC(m.tDateTime, 2)
		ENDIF

		RETURN ((YEAR(m.tDateTime) - 1980) * 2 ** 25);
			+ (MONTH(m.tDateTime) * 2 ** 21);
			+ (DAY(m.tDateTime) * 2 ** 16);
			+ (VAL(LEFTC(m.cTimeValue, 2)) * 2 ** 11);
			+ (VAL(SUBSTRC(m.cTimeValue, 4, 2)) * 2 ** 5);
			+  VAL(RIGHTC(m.cTimeValue, 2))
	ENDFUNC


	* <summary>
	*	Parse a PRG file into VCX Wrapper objects.
	*
	* <returns>	
	*	TRUE on success.
	*
	* <parameters>
	* 	cFilename - name of PRG file to parse.
	FUNCTION ParsePRG(cFilename)
		THIS.PRGFile = cFilename
		
		RETURN THIS.ParseCode(FILETOSTR(m.cFilename))
	ENDFUNC
	

	FUNCTION GetPropertyValue(cCodeLine)
		LOCAL cPropertyValue
		LOCAL i

		cPropertyValue = cCodeLine
		IF AT("&" + "&", cPropertyValue) > 0
			cPropertyValue = LEFT(cPropertyValue, AT("&" + "&", cPropertyValue) - 1)
		ENDIF
			
		
		RETURN ALLTRIM(cPropertyValue)
	ENDFUNC

	* <summary>
	*	Evaluate a block of code, parsing each line
	*	and creating collection of properties and
	*	methods for all classes defined in the code
	*	block.
	*
	* <returns>	
	*	TRUE on success
	*
	* <parameters>
	* 	cTextBlock - block of text to evaluate
	FUNCTION ParseCode(cTextBlock)
		LOCAL i, j
		LOCAL nLineCnt
		LOCAL cProcName
		LOCAL nOffset
		LOCAL cDefinition
		LOCAL cUpperDefinition
		LOCAL lContinuation
		LOCAL oClass
		LOCAL nTokenCnt
		LOCAL nToken
		LOCAL lUseMemLines
		LOCAL nMemoWidth
		LOCAL cCodeLine
		LOCAL cValue
		LOCAL cVisibility
		LOCAL cObjectName
		LOCAL nTokenEval
		LOCAL cObjectClassName
		LOCAL cProperties
		LOCAL lInClassDef
		LOCAL lInText
		LOCAL lDefineArray
		LOCAL ARRAY aCodeList[1]
		LOCAL ARRAY aTokens[MAX_TOKENS]
		


		m.nOffset = 0

		* this is the UNIQUEID field from a form or class library
		m.lContinuation = .F.  && continuation line?
		m.nTokenCnt     = 0

		m.cProcName   = ''   && name of procedure/function we're in
		m.lInClassDef = .F.  && in a class definition?
		
		* ALINES should be faster, but we can't use that if
		* there are more than 65k lines in the code block
		m.lUseMemLines = .F.
		TRY
			m.nLineCnt = ALINES(aCodeList, m.cTextBlock, .F.)
		CATCH
			m.lUseMemLines = .T.
		ENDTRY
		
		IF m.lUseMemLines
			m.nMemoWidth = SET("MEMOWIDTH")
			SET MEMOWIDTH TO 8192
			m.nLineCnt = MEMLINES(m.cTextBlock)
			_MLINE = 0
		ENDIF

		
		FOR m.i = 1 TO m.nLineCnt
			m.lDefineArray = .F.
					
			IF m.lUseMemLines
				m.cCodeLine = MLINE(m.cTextBlock, 1, _MLINE)
			ELSE
				m.cCodeLine = aCodeList[m.i]
			ENDIF
		
			m.nTokenCnt = THIS.ParseLine(m.cCodeLine, @aTokens, m.nTokenCnt)
			IF m.nTokenCnt > 0 AND aTokens[m.nTokenCnt] == ';'
				m.nTokenCnt = m.nTokenCnt - 1
				LOOP
			ENDIF

			IF m.lInText 
				IF m.nTokenCnt == 0 OR LEN(aTokens[1]) < 4 OR "ENDTEXT" <> UPPER(aTokens[1])
					m.nTokenCnt = 0
					LOOP
				ENDIF
				m.lInText = .F.
			ENDIF


			m.cVisibility = VISIBILITY_PUBLIC
			m.nToken = 0
			DO CASE 
			CASE m.nTokenCnt > 1
				IF LEN(aTokens[1]) >= 4
					m.nStopToken = m.nTokenCnt
					m.cWord1 = UPPER(aTokens[1])
					m.cWord2 = UPPER(aTokens[2])
					

					DO CASE
					CASE "DEFINE" = m.cWord1
						IF LEN(m.cWord2) >= 4 AND "CLASS" = m.cWord2 AND m.nTokenCnt > 2
							m.oClass = THIS.AddClass(aTokens[3])
							m.oClass.nLineNo = m.i

							IF m.nTokenCnt >= 5 AND UPPER(aTokens[4]) == "AS"
								m.oClass.cParentClass = aTokens[5]
							ENDIF
							
							* if this is a "DEFINE CLASS <classname> AS <parentclass> OF <classlibrary>"
							* then add the class library to files to process
							IF m.nTokenCnt >= 7 AND UPPER(aTokens[6]) == "OF"
								m.oClass.cClassLoc = aTokens[7]
							ENDIF

							IF LEN(aTokens[m.nTokenCnt]) >= 4 AND "OLEPUBLIC" = UPPER(aTokens[m.nTokenCnt])
								m.oClass.lOlePublic = .T.
							ENDIF

							m.lInClassDef = .T.

						ENDIF

			
					CASE m.nTokenCnt > 2 AND ("PROTECTED" = m.cWord1 OR "HIDDEN" = m.cWord1) AND (LEN(m.cWord2) >= 4 AND ("PROCEDURE" = m.cWord2 OR "FUNCTION" = m.cWord2))
						m.cProcName   = aTokens[3]

						m.lInClassDef = .F.

						IF VARTYPE(m.oClass) == 'O'
							DO CASE
							CASE "PROTECTED" = m.cWord1 
								oClass.AddMethod(m.cProcName, '', VISIBILITY_PROTECTED, m.i)
							CASE "HIDDEN" = m.cWord1
								oClass.AddMethod(m.cProcName, '', VISIBILITY_HIDDEN, m.i)
							OTHERWISE
								oClass.AddMethod(m.cProcName, '', VISIBILITY_PUBLIC, m.i)
							ENDCASE
						ENDIF

					CASE "PROCEDURE" = m.cWord1 OR "FUNCTION" = m.cWord1
						m.cProcName   = aTokens[2]
						m.lInClassDef = .F.
						
						IF VARTYPE(m.oClass) == 'O'
							oClass.AddMethod(m.cProcName, '', VISIBILITY_PUBLIC, m.i)
						ENDIF

					CASE "ENDDEFINE" = m.cWord1
						m.cProcName   = ''
						m.oClass      = .NULL.
						m.lInClassDef = .F.

					CASE "ENDFUNC" = m.cWord1
						m.cProcName = ''
						m.lInClassDef = .F.

					CASE "ENDPROC" = m.cWord1
						m.cProcName   = ''
						m.lInClassDef = .F.

					CASE m.lInClassDef AND ("DIMENSION" = m.cWord1 OR "DECLARE" = m.cWord1)
						m.nToken = 2
						m.lDefineArray = .T.

					CASE m.lInClassDef AND "PROTECTED" = cWord1
						m.nToken = 2
						m.cVisibility = VISIBILITY_PROTECTED

					CASE m.lInClassDef AND "HIDDEN" = cWord1
						m.nToken = 2
						m.cVisibility = VISIBILITY_HIDDEN

					CASE m.lInClassDef AND aTokens[2] == '=' AND nTokenCnt > 2
						* if we're in a class definition and we have an
						* assignment statement, then that's a Property definition
						IF VARTYPE(m.oClass) == 'O'
							oClass.AddCustomProperty(aTokens[1], THIS.GetPropertyValue(SUBSTR(m.cCodeLine, AT('=', m.cCodeLine) + 1)), VISIBILITY_PUBLIC, m.i)
						ENDIF

					CASE "TEXT" == cWord1
						m.lInText = .T.

					ENDCASE
				ELSE
					DO CASE
					
					* ADD OBJECT [PROTECTED] <ObjectName> AS <ClassName2> [NOINIT] [WITH cPropertylist]]
					CASE m.lInClassDef AND m.nTokenCnt > 2 AND (UPPER(aTokens[1]) == "ADD" AND LEN(aTokens[2]) >= 4 AND "OBJECT" = UPPER(aTokens[2]))
						m.cObjectClassName = ''	
						m.cObjectName = aTokens[3]
						m.cProperties = ''

						IF m.nTokenCnt > 3 AND LEN(aTokens[3]) >= 4 AND "PROTECTED" = UPPER(aTokens[3])
							m.cObjectName = aTokens[4]
							m.cVisibility = VISIBILITY_PROTECTED

							m.nTokenEval = 6  && token where object's classname should be found
						ELSE
							m.cObjectName = aTokens[3]
							m.nTokenEval = 5  && token where object's classname should be found
						ENDIF
						
						IF m.nTokenCnt >= m.nTokenEval
							m.cObjectClassName = aTokens[m.nTokenEval]
							m.nTokenEval = m.nTokenEval + 1
							
							* skip past NOINIT clause
							IF m.nTokenCnt >= m.nTokenEval AND LEN(aTokens[m.nTokenEval]) >= 4 AND "NOINIT" == UPPER(aTokens[m.nTokenEval])
								m.nTokenEval = m.nTokenEval + 1
							ENDIF

							IF m.nTokenCnt > m.nTokenEval AND UPPER(aTokens[m.nTokenEval]) == "WITH"
								* we could evaluate property list here, but not supported for what we need
							ENDIF
						ENDIF
						m.oClass.AddContainedObject(m.cObjectName, m.cObjectClassName, m.cVisibility, m.cProperties, m.i)

					CASE UPPER(aTokens[1]) == "SET"
						m.cWord2 = UPPER(aTokens[2])
						* SET PROCEDURE TO <program> or SET CLASSLIB TO <classlibrary>
						IF LEN(m.cWord2) >= 4 AND m.nTokenCnt >= 4 AND UPPER(aTokens[3]) == "TO"
							DO CASE
							CASE "CLASSLIB" = m.cWord2 

							CASE "PROCEDURE" = m.cWord2
								* SET PROCEDURE TO supports a comma-delimited list of filenames
								FOR m.j = 4 TO m.nTokenCnt
									IF LEN(aTokens[m.j]) >= 4 AND "ADDI" = UPPER(aTokens[m.j])
										EXIT
									ENDIF
								ENDFOR
							ENDCASE
						ENDIF

					CASE m.lInClassDef AND aTokens[2] == '=' AND nTokenCnt > 2
						* if we're in a class definition and we have an
						* assignment statement then that's a Property definition
						m.oClass.AddCustomProperty(aTokens[1], THIS.GetPropertyValue(SUBSTR(m.cCodeLine, AT('=', m.cCodeLine) + 1)), VISIBILITY_PUBLIC, m.i)
					ENDCASE
				ENDIF
			
			CASE m.nTokenCnt > 0
				m.cWord1 = UPPER(aTokens[1])
				DO CASE
				CASE "ENDDEFINE" = m.cWord1
					m.cProcName   = ''
					m.lInClassDef = .F.
					m.oClass = .NULL.

				CASE "ENDFUNC" = m.cWord1
					m.cProcName = ''
					m.lInClassDef = .F.

				CASE "ENDPROC" = m.cWord1
					m.cProcName   = ''
					m.lInClassDef = .F.

				ENDCASE
			
			ENDCASE

			* Grab all definitions from this line
			IF m.nToken > 0 AND m.lInClassDef
				DO WHILE m.nToken <= m.nStopToken
					m.cDefinition = aTokens[m.nToken]
					IF m.nStopToken >= m.nToken + 2 AND aTokens[m.nToken + 1] == '='
						m.cValue = aTokens[m.nToken + 2]
					ELSE
						m.cValue = ''
					ENDIF

					IF ISALPHA(m.cDefinition) OR m.cDefinition = '_'
						m.cUpperDefinition = UPPER(m.cDefinition)
						
						DO CASE
						CASE m.cUpperDefinition == "ARRAY" OR m.cUpperDefinition == "ARRA"
							m.nToken = m.nToken + 1
							LOOP

						CASE m.cUpperDefinition == "AS" OR m.cUpperDefinition == "OF" OR (LEN(m.cUpperDefinition) >= 4 AND m.cUpperDefinition = "OLEPUBLIC")
							m.nToken = m.nToken + 2
							LOOP

						ENDCASE

						IF m.lDefineArray AND m.nToken < m.nStopToken AND aTokens[m.nToken + 1] = '['
							m.cDefinition = m.cDefinition + aTokens[m.nToken + 1]
							m.nToken = m.nToken + 1
						ENDIF
						
					
						IF m.lInClassDef
							m.oClass.AddCustomProperty(m.cDefinition, m.cValue, m.cVisibility, m.i)
						ENDIF
					ENDIF
					m.nToken = m.nToken + 1
				ENDDO
			ENDIF


			m.nTokenCnt = 0
		ENDFOR

		IF m.lUseMemLines
			SET MEMOWIDTH TO (m.nMemoWidth)
		ENDIF
		
		RETURN .T.
	ENDFUNC

	* <summary>
	*	Parse a single line of code, creating
	*	an array of tokens.
	*
	* <returns>	
	*	Number of resulting tokens.
	*
	* <parameters>
	* 	cLine - line of code to parse
	*	@aTokens - array to fill
	*	@nTokenCnt - number of resulting tokens
	PROTECTED FUNCTION ParseLine(cLine, aTokens, nTokenCnt)
		LOCAL cEndQuote
		LOCAL cWord
		LOCAL cLastCh
		LOCAL ch
		LOCAL nTerminal
		LOCAL lInQuote
		LOCAL lInSymbol
		LOCAL nLen
		LOCAL i


		nTerminal = 0
		cWord     = ''
		nLen      = LEN(cLine)
		cLastCh   = ''
		FOR i = 1 TO nLen
			ch = SUBSTRC(cLine, i, 1)

			IF lInQuote
				IF ch == cEndQuote
					nTerminal = 1
					cEndQuote = ''
					cWord = cWord + ch
					ch = ''
					lInQuote = .F.
				ELSE
					nTerminal = 0
				ENDIF
			ELSE
				IF ch == '_' OR IsAlpha(ch) OR ch == '.' OR ch $ "0123456789"
					IF lInSymbol
						nTerminal = 0
					ELSE
						lInSymbol = .T.
						nTerminal = 1
					ENDIF
				ELSE
					lInSymbol = .F.

					DO CASE
					CASE ch == ' ' OR ch == TAB
						nTerminal = 2

					CASE ch == '"' OR ch == '[' OR ch == "'"
						nTerminal = 1
						cEndQuote = IIF(ch == '[', ']', ch)
						lInQuote  = .T.

					CASE ch == '&' AND cLastCh == '&'
						nTerminal = 2
						EXIT

					CASE ch == ';'
						nTerminal = 1

					OTHERWISE
						nTerminal = 1

					ENDCASE
				ENDIF
			ENDIF
				
			IF nTerminal <> 0
				IF !EMPTY(cWord) AND nTokenCnt < MAX_TOKENS
					nTokenCnt = nTokenCnt + 1
					aTokens[nTokenCnt] = cWord
				ENDIF
				IF nTerminal <> 2
					cWord = ch
				ELSE
					cWord = ''
				ENDIF
				nTerminal = 0
			ELSE
				cWord = cWord + ch
			ENDIF
			cLastCh = ch
		ENDFOR

		IF nTerminal <> 2 AND !EMPTY(cWord) AND nTokenCnt < MAX_TOKENS
			nTokenCnt = nTokenCnt + 1
			aTokens[nTokenCnt] = cWord
		ENDIF
		
		RETURN nTokenCnt
	ENDFUNC
	
ENDDEFINE


* <summary>
* 	Class object used by VCXWrapper to represent a class.
*	Each class object contains methods, properties, and
*	contained objects collections.
DEFINE CLASS VCXClass AS Custom
	cClassName   = ''
	cParentClass = ''
	cClassLoc    = ''
	cBaseClass   = ''
	lOlePublic   = .F.
	cVisibility  = VISIBILITY_PUBLIC
	nLineNo      = 0
	
	ADD OBJECT oMethodCollection AS Collection
	ADD OBJECT oPropertyCollection AS Collection
	ADD OBJECT oObjectCollection AS Collection

	PROCEDURE Init(cPRGFile, cClassName, cParentClass, cParentClassLoc, lOlePublic, nLineNo)
		LOCAL oTempRef
		LOCAL cBaseClass

		m.cBaseClass = ''
		TRY
			oTempRef = NEWOBJECT(cClassName, cPRGFile, 0)
			m.cClassName      = oTempRef.Class
			m.cParentClass    = oTempRef.ParentClass
			m.cParentClassLoc = IIF(oTempRef.ParentClass == oTempRef.BaseClass, '', cPRGFile) && oTempRef.ClassLibrary
			m.cBaseClass      = oTempRef.BaseClass
		CATCH
		ENDTRY
		
		WITH THIS
			.cClassName   = EVL(m.cClassName, '')
			.cParentClass = EVL(m.cParentClass, '')
			.cClassLoc    = EVL(m.cParentClassLoc, '')
			.cBaseClass   = m.cBaseClass
			.lOlePublic   = m.lOlePublic
			.nLineNo      = EVL(m.nLineNo, 0)
		ENDWITH
		
		RELEASE oTempRef
	ENDPROC
	
	* <summary>
	*	Add a method to the class object collection of methods.
	*
	* <returns>	
	*	Reference to method object.
	*
	* <parameters>
	* 	cMethodName- name of method
	*	[cCode] - method code
	*	[cVisibility] - Public, Protected, or Hidden
	*	[nLineNo] - line number object occurs on
	FUNCTION AddMethod(cMethodName, cCode, cVisibility, nLineNo)
		LOCAL oMethod

		oMethod = .NULL.
		IF !EMPTY(cMethodName) AND AT('.', cMethodName) == 0
			oMethod = CREATEOBJECT("Empty")

			ADDPROPERTY(oMethod, "cMethodName", cMethodName)
			ADDPROPERTY(oMethod, "cVisibility", EVL(cVisibility, VISIBILITY_PUBLIC))
			ADDPROPERTY(oMethod, "cCode", EVL(cCode, ''))
			ADDPROPERTY(oMethod, "nLineNo", EVL(nLineNo, 0))

			TRY
				THIS.oMethodCollection.Add(oMethod)
			CATCH
				* ignore error
				oMethod = .NULL.
			ENDTRY
		ENDIF

		RETURN oMethod		
	ENDFUNC

	* <summary>
	*	Add a custom property to the class object collection of properties.
	*	If property already exists in the collection, update the value.
	*
	* <returns>	
	*	Reference to property object.
	*
	* <parameters>
	* 	cPropertyName - name of property
	*	[cValue] - property value
	*	[cVisibility] - Public, Protected, or Hidden
	*	[nLineNo] - line number object occurs on
	FUNCTION AddCustomProperty(cPropertyName, cValue, cVisibility, nLineNo)
		LOCAL i
		LOCAL oProperty
		LOCAL lAdd
		
		m.oProperty = .NULL.
		IF !EMPTY(m.cPropertyName)
			m.lAdd = .T.
			
			* see if property was already added
			FOR m.i = 1 TO THIS.oPropertyCollection.Count
				IF UPPER(THIS.oPropertyCollection.Item(m.i).cPropertyName) == UPPER(m.cPropertyName)
					* property already defined in class definition, so simply set the value
					m.oProperty = THIS.oPropertyCollection.Item(m.i)
					m.oProperty.cValue = m.cValue
					m.lAdd = .F.
					EXIT
				ENDIF
			ENDFOR
			
			IF m.lAdd
				m.oProperty = CREATEOBJECT("Empty")
				ADDPROPERTY(m.oProperty, "cPropertyName", m.cPropertyName)
				ADDPROPERTY(m.oProperty, "cVisibility", EVL(m.cVisibility, VISIBILITY_PUBLIC))
				ADDPROPERTY(m.oProperty, "cValue", m.cValue)
				ADDPROPERTY(m.oProperty, "nLineNo", EVL(m.nLineNo, 0))
				
				THIS.oPropertyCollection.Add(m.oProperty)
			ENDIF
		ENDIF
	ENDFUNC	

	* <summary>
	*	Add a contained object to the class object collection of contained objects.
	*
	* <returns>	
	*	Reference to contained object object.
	*
	* <parameters>
	* 	cObjName - name of contained object
	*	cClassName - class
	*	[cVisibility] - Public, Protected, or Hidden
	*	[nLineNo] - line number object occurs on
	FUNCTION AddContainedObject(cObjName, cClassName, cVisibility, cProperties, nLineNo)
		LOCAL oClass
		LOCAL i
		LOCAL lExists

		m.oClass = CREATEOBJECT("VCXClass", '', m.cObjName, m.cClassName, '', .F., m.nLineNo)
		m.oClass.cVisibility = EVL(m.cVisibility, VISIBILITY_PUBLIC)

		* make sure we don't already have an object
		* with this name in the collection
		m.lExists = .F.
		FOR m.i = 1 TO THIS.oObjectCollection.Count
			IF UPPER(THIS.oObjectCollection.Item(m.i).cClassName) == UPPER(m.cObjName)
				m.lExists = .T.
				EXIT
			ENDIF
		ENDFOR
		IF !m.lExists
			THIS.oObjectCollection.Add(m.oClass)
		ENDIF

		RETURN m.oClass
	ENDFUNC

ENDDEFINE

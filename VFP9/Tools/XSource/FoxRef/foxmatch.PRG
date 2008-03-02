#include "foxref.h"
#include "foxpro.h"

* object we use to populate our collection of Matches
DEFINE CLASS Match AS Custom
	Name = "Match"
	
	MatchPos       = 0
	MatchLineNo    = 0
	MatchLen       = 0
ENDDEFINE

* Abtract Match Engine Class
DEFINE CLASS MatchEngine AS Custom
	Name = "MatchEngine"
	
	Pattern        = ''
	PatternLen     = 0
	MatchCase      = .T.
	WholeWordsOnly = .F.

	oMatches = .NULL.
	nMatchCnt = 0
	
	FUNCTION InitEngine()
		RETURN .T.
	ENDFUNC
	
	FUNCTION Execute(cText AS String) AS Number
		RETURN 0
	ENDFUNC
	
	FUNCTION CreateMatch()
		LOCAL oMatch
		
		m.oMatch = CREATEOBJECT("Empty")
		ADDPROPERTY(m.oMatch, "MatchOffset", 0)
		ADDPROPERTY(m.oMatch, "MatchPos", 0)
		ADDPROPERTY(m.oMatch, "MatchLineNo", 0)
		ADDPROPERTY(m.oMatch, "MatchLen", 0)
		
		RETURN m.oMatch
	ENDFUNC

	* utility function for dermining if Whole Word
	FUNCTION IsAlphaNumeric(ch)
		RETURN ISALPHA(ch) OR BETWEEN(ch, '0', '9') OR ch == '_'
	ENDFUNC

	FUNCTION SetPattern(cPattern)
		IF VARTYPE(cPattern) <> 'C'
			RETURN .F.
		ENDIF
		
		THIS.PatternLen = LENC(m.cPattern)
		THIS.Pattern = cPattern

		RETURN .T.
	ENDFUNC
	

ENDDEFINE


* Standard Match Engine
DEFINE CLASS MatchDefault AS MatchEngine
	Name = "MatchDefault"

	FUNCTION Execute(cText AS String)
		LOCAL nPos
		LOCAL nOccurrence
		LOCAL i
		LOCAL oMatch
		
		nOccurrence = 1
		i = 0


		THIS.oMatches = CREATEOBJECT("Collection")
		IF THIS.MatchCase
			nPos = AT_C(THIS.Pattern, cText, nOccurrence)
		ELSE
			nPos = ATCC(THIS.Pattern, cText, nOccurrence)
		ENDIF

		* don't bother converting CR/LF to LF only unless there are matches
		IF nPos > 0
			cText = STRTRAN(cText, CHR(13) + CHR(10), CHR(10))
			cText = STRTRAN(cText, CHR(13), CHR(10))

			IF THIS.MatchCase
				nPos = AT_C(THIS.Pattern, cText, nOccurrence)
			ELSE
				nPos = ATCC(THIS.Pattern, cText, nOccurrence)
			ENDIF
		ENDIF

		DO WHILE nPos <> 0
			* if Whole Word Only is selected, then we must
			* make sure the word we found comprises a whole word
			IF (!THIS.WholeWordsOnly OR (m.nPos > 1 AND !THIS.IsAlphaNumeric(SUBSTRC(m.cText, m.nPos - 1, 1)) AND (m.nPos == LENC(m.cText) OR !THIS.IsAlphaNumeric(SUBSTRC(m.cText, m.nPos + THIS.PatternLen, 1)))))
				i = i + 1
				oMatch = THIS.CreateMatch()
				oMatch.MatchLen = THIS.PatternLen
				
				oMatch.MatchPos = nPos - RATC(CHR(10), LEFTC(cText, nPos))
				oMatch.MatchLineNo    = OCCURS(CHR(10), LEFTC(cText, nPos)) + 1

				THIS.oMatches.Add(oMatch)
			ENDIF
			
			nOccurrence = nOccurrence + 1
			IF THIS.MatchCase
				nPos = AT_C(THIS.Pattern, cText, nOccurrence)
			ELSE
				nPos = ATCC(THIS.Pattern, cText, nOccurrence)
			ENDIF
		ENDDO

		THIS.nMatchCnt = i
		
		RETURN THIS.nMatchCnt
	ENDFUNC
	

ENDDEFINE


* Regular Expression search engine (relies on VBScript)
DEFINE CLASS MatchWildcard AS MatchEngine
	Name = "MatchWildcard"

	oRegExpr = .NULL.

	FUNCTION InitEngine()
		LOCAL lSuccess
		
		m.lSuccess = .T.
		TRY
			THIS.oRegExpr = CreateObject("VBScript.RegExp")
			THIS.oRegExpr.Global = .T.
		CATCH
			m.lSuccess = .F.
			THIS.oRegExpr = .NULL.
			MessageBox(WSH_REQUIRED_LOC, MB_ICONEXCLAMATION, APPNAME_LOC)
		ENDTRY
		
		RETURN m.lSuccess
	ENDFUNC

	FUNCTION SetPattern(cPattern)
		LOCAL lSuccess
		LOCAL oException

		IF VARTYPE(cPattern) <> 'C'
			RETURN .F.
		ENDIF
		IF EMPTY(cPattern)
			RETURN .T.
		ENDIF

		lSuccess = .T.
		
		IF THIS.WholeWordsOnly
			cPattern = "\b" + cPattern + "\b"
		ENDIF
		
		TRY		
			THIS.oRegExpr.Pattern = cPattern
		CATCH TO oException
			m.lSuccess = .F.
		ENDTRY

		* now check the pattern
		TRY
			THIS.oRegExpr.Test("abcdefg")
		CATCH TO oException
			m.lSuccess = .F.
		ENDTRY
		
		IF lSuccess
			THIS.PatternLen = LENC(m.cPattern)
			THIS.Pattern = cPattern
		ENDIF
		
		RETURN lSuccess
	ENDFUNC


	FUNCTION Execute(cText AS String)
		LOCAL oMatches
		LOCAL oMatch
		LOCAL oRegExprMatch
		LOCAL nPos
		LOCAL lSuccess
		LOCAL oException
		LOCAL nOccurs
		LOCAL cFindChar
		
		THIS.oMatches = CREATEOBJECT("Collection")

	
		THIS.nMatchCnt = 0
		
		lSuccess = .T.
		TRY
			THIS.oRegExpr.IgnoreCase = !THIS.MatchCase
			THIS.oRegExpr.MultiLine = .T.
			oMatches = THIS.oRegExpr.Execute(cText)
		CATCH TO oException
			lSuccess = .F.
		ENDTRY


		IF m.lSuccess
			THIS.nMatchCnt = oMatches.Count
			FOR EACH oRegExprMatch IN oMatches
				nPos = oRegExprMatch.FirstIndex + 1
				
				oMatch = THIS.CreateMatch()
				oMatch.MatchLen       = LENC(oRegExprMatch.Value)


				cFindChar = CHR(10)
				nOccurs = OCCURS(cFindChar, LEFTC(cText, nPos))
				IF nOccurs == 0
					cFindChar = CHR(13)
					nOccurs = OCCURS(cFindChar, LEFTC(cText, nPos))
				ENDIF
				oMatch.MatchLineNo    = nOccurs + 1
				oMatch.MatchPos       = nPos - RATC(cFindChar, LEFTC(cText, nPos))

				THIS.oMatches.Add(oMatch)
			ENDFOR
		ELSE
			RETURN -1  && error
		ENDIF

		RETURN THIS.nMatchCnt
	ENDFUNC

ENDDEFINE


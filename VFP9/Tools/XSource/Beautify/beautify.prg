#include "beautify.h"
* Main entry point for Beautify.APP.  The purpose of Beautify.app is
* to wrap FD3.FLL in a private data session so that its table
* manipulation routines don't disturb the user's environment.

* Revisions:
*	12-27-2001: Added support to beautify a selection (RK)
*
LPARAMETERS m.inFile, m.options

PRIVATE symbol, winname, winpos, FILE, filetype, done, flags, sniplineno, ;
	classname, BaseClass, mtemp, temp, fpoutfile, mout, totallines

LOCAL ox, retVal, mdatasess,m.oldtalk,m.oldtrbet, nLangOpt

IF VAL(_VFP.Version) >= 7
	nLangOpt = _VFP.LanguageOptions
	_VFP.LanguageOptions = 0
ENDIF

IF SET("TALK") = "ON"
*oldtalk = SET("talk")...can't do this because it echoes
	SET TALK OFF
	m.oldtalk = "ON"
ELSE
	m.oldtalk = "OFF"
ENDIF
m.oldtrbet=SET("TRBETWEEN")
SET TRBETWEEN OFF
m.mdatasess = SET("DATASESSION")

m.retVal = ""

* These variables are needed by the FD3.FLL library
m.symbol = ""
m.winname = 0
m.winpos = 0
m.file = ""
m.filetype = ""
m.done = 0
m.flags = ""
m.sniplineno = 0
m.classname = ""
m.baseclass = ""
m.mtemp = ""
m.temp = ""
m.fpoutfile = -1
m.mout = ""
m.totallines = 0

ox = CREATEOBJECT("CBeautify", m.inFile, @options)


IF TYPE("OX") = "O"
	m.retVal = ox.outfile
	* ox.Release
	ox = .NULL.
ENDIF
SET TALK &oldtalk
SET DataSession TO (m.mdatasess)
SET TRBETWEEN &oldTRBet
IF VAL(_VFP.Version) >= 7
	_VFP.LanguageOptions = nLangOpt
ENDIF
RETURN (m.retVal)	&& output file name


DEFINE Class CBeautify AS Session
	DataSession = 2		&&private
	Visible = .F.
	Name = "Beautify"
	outfile = ""

	PROTECTED PROC whereis(mfile)
		LOCAL mtemp
		IF FILE(m.mfile)
			RETURN m.mfile
		ENDIF
		mtemp = "fd3fll\" + m.mfile
		IF FILE(m.mtemp)
			RETURN m.mtemp
		ENDIF
		mtemp = SYS(2004)+m.mfile
		IF FILE(m.mtemp)
			RETURN m.mtemp
		ENDIF
		mtemp = SYS(2004)+"wizards\" + m.mfile
		IF FILE(m.mtemp)
			RETURN m.mtemp
		ENDIF
		RETURN ""
	ENDPROC

	PROCEDURE Init( m.inFile, m.options)
		LOCAL fSuccess, outfile, libname, xrefname,mdbf
		LOCAL m.errLogFile, mOldLogErrors

		LOCAL nWindowHandle
		LOCAL nStartPos
		LOCAL nEndPos
		LOCAL nStartLine
		LOCAL nEndLine
		LOCAL nRetCode
		LOCAL nPos
		LOCAL cCodeBlock
		LOCAL cTempInFile
		LOCAL cIndentText
		LOCAL i, nCnt
		LOCAL lSelection
		LOCAL nNewLen
		LOCAL cFoxToolsLibrary
		LOCAL ARRAY aEdEnv[25]
		LOCAL ARRAY aCodeLines[1]

		SET TALK OFF
		SET SAFETY OFF		&& scoped to datasession


#IFDEF COMPILEBEFORE		
		mOldLogErrors = SET("LOGERRORS")
		SET LOGERRORS ON
		m.errLogFile = LEFTC(m.inFile,RATC(".",m.inFile)) + "err"
		ERASE (m.errLogFile)
		compile (m.inFile)
		SET LOGERRORS &mOldLogErrors
		IF FILE(m.ErrLogFile)
			MODIFY COMMAND (m.errLogFile) nowait
			RETURN .f.
		ENDIF
#ENDIF
		mdbf = this.whereis("FDKEYWRD.DBF")
		IF FILE(m.mdbf)
			USE (m.mdbf) ;
				Order token ;
				Alias fdkeywrd IN 0
			SET Message TO ""
			SELECT fdkeywrd

			m.libname = this.whereis("fd3.fll")
			IF FILE(m.libname)
				SET LIBRARY TO (m.libname) ADDITIVE

				* Generate a temp file in the temp file directory
				m.outfile = SYS(2023) + "\" + SUBSTR(SYS(2015), 3, 10) + ".TMP"

				* If usercase mode, create xref table for user symbols
				IF (SUBSTR(options, 1, 1) = CHR(3))
					m.xrefname = "FDXREF"
					CREATE Cursor (m.xrefname) (;
						symbol c(65),;
						ProcName c(40),;
						Flag c(1),;
						LINENO N(5),;
						SnipRecNo N(5),;
						SnipFld c(10),;
						sniplineno N(5),;
						adjust N(5),;
						Filename c(161);
						)
					INDEX ON Flag Tag Flag 						&& for rushmore
					INDEX ON UPPER(symbol)+Flag Tag symbol
				ENDIF


				* if it's a selection, then beautify
				* the selection only, otherwise
				* beautify the entire file
				m.lSelection = .F.
				m.cFoxToolsLibrary = ''
				TRY
					IF ATC("FOXTOOLS.FLL", SET("LIBRARY")) == 0
						m.cFoxToolsLibrary = SYS(2004)+"FOXTOOLS.FLL"
						IF !FILE(m.cFoxtoolsLibrary)
							RETURN .F.
						ENDIF
						SET LIBRARY TO (m.cFoxToolsLibrary) ADDITIVE
					ENDIF

					m.nWindowHandle = _wontop()
					IF m.nWindowHandle > 0
						m.nRetCode = _edgetenv(m.nWindowHandle, @aEdEnv)

						IF m.nRetCode == 1 AND (aEdEnv[EDENV_LENGTH] > 0)
							m.lSelection = aEdEnv[EDENV_SELEND] > aEdEnv[EDENV_SELSTART]
						ENDIF
					ENDIF
				CATCH
				ENDTRY
								
				IF m.lSelection
					* we have a window handle, now grab the text

					* Check environment of window
					* get the length of the window

					m.nStartLine = _EdGetLNum(m.nWindowHandle, aEdEnv[EDENV_SELSTART])
					m.nEndLine   = _EdGetLNum(m.nWindowHandle, aEdEnv[EDENV_SELEND])
					IF _EdGetLPos(m.nWindowHandle, m.nEndLine) == aEdEnv[EDENV_SELEND]
						m.nEndLine = m.nEndLine - 1
					ENDIF

					m.nStartPos = _EdGetLPos(nWindowHandle, m.nStartLine)
					m.nEndPos   = _EdGetLPos(nWindowHandle, m.nEndLine)

					* find beginning of the first line
					FOR m.nPos = m.nStartPos TO 1 STEP -1
						IF INLIST(_EdGetChar(m.nWindowHandle, m.nPos), CHR(13), CHR(10))
							m.nPos = m.nPos + 1
							EXIT
						ENDIF
					ENDFOR
					m.nStartPos = m.nPos

					* find end of the last line
					FOR m.nPos = m.nEndPos TO (aEdEnv[EDENV_LENGTH] - 1)
						IF INLIST(_EdGetChar(nWindowHandle, m.nPos), CHR(13), CHR(10))
							m.nPos = m.nPos - 1
							EXIT
						ENDIF
					ENDFOR
					m.nEndPos = m.nPos


					IF m.nStartPos < m.nEndPos  
						* grab the selection and we'll write this into a file to be processed
						m.cCodeBlock = _EdGetStr(m.nWindowHandle, m.nStartPos, m.nEndPos)

						* find the initial indentation on the first line
						m.cIndentText = ''
						

						IF !(aEdEnv[EDENV_SELSTART] == 0 AND aEdEnv[EDENV_SELEND] == aEdEnv[EDENV_LENGTH])  && if all text is not selected, then grab indentation
							m.nCnt = ALINES(aCodeLines, m.cCodeBlock)
							FOR m.i = 1 TO m.nCnt
								IF !EMPTY(aCodeLines[i])
									m.nPos = 1
									DO WHILE m.nPos <= LEN(aCodeLines[m.i]) AND INLIST(SUBSTR(aCodeLines[m.i], m.nPos, 1), ' ', TAB)
										m.cIndentText = m.cIndentText + SUBSTR(aCodeLines[m.i], m.nPos, 1)
										m.nPos = m.nPos + 1
									ENDDO
									EXIT
								ENDIF
							ENDFOR
						ENDIF

						m.cTempInFile = ADDBS(SYS(2023)) + SUBSTR(SYS(2015), 3, 10) + ".TMP"

						IF STRTOFILE(m.cCodeBlock, m.cTempInFile) > 0
							m.OutFile = ADDBS(SYS(2023)) + SUBSTR(SYS(2015), 3, 10) + ".TMP"

							m.fSuccess = Beautify((m.cTempInfile), (m.OutFile), (m.Options))
							IF m.fSuccess
								* read back from the file that the Beautify function created
								m.cCodeBlock = FILETOSTR(m.OutFile)
								IF RIGHT(m.cCodeBlock, 1) == CHR(10)
									m.cCodeBlock = LEFT(m.cCodeBlock, LEN(m.cCodeBlock) - 1)
								ENDIF
								IF RIGHT(m.cCodeBlock, 1) == CHR(13)
									m.cCodeBlock = LEFT(m.cCodeBlock, LEN(m.cCodeBlock) - 1)
								ENDIF
								
								* add original indentation back in
								IF LEN(m.cIndentText) > 0
									m.nCnt = ALINES(aCodeLines, m.cCodeBlock)
									m.cCodeBlock = ''
									FOR m.i = 1 TO m.nCnt
										m.cCodeBlock = m.cCodeBlock + IIF(EMPTY(m.cCodeBlock), '', CHR(10)) + IIF(EMPTY(aCodeLines[m.i]), '', m.cIndentText) + aCodeLines[i]
									ENDFOR
								ENDIF

								
								m.nNewLen = LEN(m.cCodeBlock)
								
								* add in the text that surrounded the selection and
								* save it back to our outfile
								IF m.nStartPos > 0
									m.cCodeBlock = _EdGetStr(m.nWindowHandle, 0, m.nStartPos - 1) + m.cCodeBlock
								ENDIF
								IF m.nEndPos < (aEdEnv[EDENV_LENGTH] - 1)
									m.cCodeBlock = m.cCodeBlock + _EdGetStr(m.nWindowHandle, m.nEndPos + 1, aEdEnv[EDENV_LENGTH] - 1)
								ENDIF
								STRTOFILE(m.cCodeBlock, m.OutFile)
								
								PUBLIC _goBeautifyForm
								_goBeautifyForm = CREATEOBJECT("CBeautifyTimer")
								WITH _goBeautifyForm
									.nWindowHandle = m.nWindowHandle
									.nStartPos     = m.nStartPos
									.nEndPos       = m.nStartPos + m.nNewLen
									.StartTimer()
								ENDWITH
							ENDIF
						ENDIF

						IF FILE(m.cTempInFile)
							ERASE (m.cTempInFile)
						ENDIF	
					ENDIF
					
				ELSE
					m.fSuccess = Beautify((m.inFile), (m.outfile), (m.options))
				ENDIF

				RELEASE LIBRARY (m.libname)
				
				IF !EMPTY(m.cFoxToolsLibrary) AND ATCC(m.cFoxToolsLibrary, SET("LIBRARY")) > 0
					RELEASE LIBRARY (m.cFoxToolsLibrary)
				ENDIF

				IF (SUBSTR(options, 1, 1) = CHR(3))
					SELECT fdxref
					USE
*					Delete FILE (m.xrefname)
				ENDIF

				this.outfile = m.outfile
			ELSE
				=MESSAGEBOX(E_STRING2_LOC, 0)
				RETURN .F.
			ENDIF
		ELSE
			=MESSAGEBOX(E_STRING1_LOC, 0)
			RETURN .F.
		ENDIF
	ENDPROC &&Init
	
ENDDEFINE

* We use this timer to set our new selection range when
* a selection is beautified.
* We have to use a timer because the product (VFP) is responsible 
* for updating the window text, so we have to wait until it's updated before we
* can set our new selection range.
* We embed the timer in a form because we can release the form within
* itself but we can't release a timer within itself (prevents timer
* reference from hanging around after we're done with it)
DEFINE CLASS CBeautifyTimer AS Form

	nStartPos = 0
	nEndPos   = 0
	nWindowHandle = -1

	ADD OBJECT oTimer AS Timer WITH ;
	  Enabled = .F., ;
	  Interval = 0
	  
	PROCEDURE StartTimer()
		THIS.oTimer.Interval = 10
		THIS.oTimer.Enabled = .T.
	ENDPROC
	
	
	PROCEDURE oTimer.Timer
		LOCAL nWindowHandle
		LOCAL lError
		LOCAL cFoxToolsLibrary
		LOCAL ARRAY aEdEnv[25]

		THIS.Enabled = .F.
		THIS.Reset()

		m.lError = .F.
		* make sure the window on top is still the window we need to update
		TRY
			IF ATC("FOXTOOLS.FLL", SET("LIBRARY")) == 0
				m.cFoxToolsLibrary = SYS(2004)+"FOXTOOLS.FLL"
				IF FILE(m.cFoxtoolsLibrary)
					SET LIBRARY TO (m.cFoxToolsLibrary) ADDITIVE
				ELSE
					m.lError = .T.
				ENDIF
			ENDIF
		CATCH
			m.lError = .T.
		ENDTRY

		IF !m.lError
			m.nWindowHandle = _wontop()
			IF m.nWindowHandle > 0 AND m.nWindowHandle == THISFORM.nWindowHandle
				IF  _edgetenv(m.nWindowHandle, @aEdEnv) == 1
					_edselect(m.nWindowHandle, THISFORM.nStartPos, THISFORM.nEndPos)
				ENDIF
			ENDIF
		ENDIF

		IF !EMPTY(m.cFoxToolsLibrary) AND ATCC(m.cFoxToolsLibrary, SET("LIBRARY")) > 0
			TRY
				RELEASE LIBRARY (m.cFoxToolsLibrary)
			CATCH
			ENDTRY
		ENDIF
				
		RELEASE _goBeautifyForm		
		THISFORM.Release()
	ENDPROC
ENDDEFINE

PROCEDURE _wontop
PROCEDURE _edgetenv
PROCEDURE _edsetenv
PROCEDURE _edgetchar
PROCEDURE _edselect
PROCEDURE _edgetstr
PROCEDURE _eddelete
PROCEDURE _edinsert
PROCEDURE _edsetpos
PROCEDURE _edgetpos
PROCEDURE _edgetlnum
PROCEDURE _edgetlpos


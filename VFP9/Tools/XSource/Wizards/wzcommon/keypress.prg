#define C_DEBUG .t.

* The following string is used to form a message when 
* _LOGFILE cannot be created or opened. The message will
* look like one of these two examples:
*
*	FCREATE("test1.log") failed. Event logging disabled.
*	FOPEN("test1.log", 2) failed. Event logging disabled.

#define LOGFILEERROR_LOC	" failed. Event logging disabled."

#IF C_DEBUG
	if type('_logfile') = 'C' .and. !empty(_logfile)
		private iHandle, oObjRef, cName, cKeyboard
		
		oObjRef = this
		cName = this.Name
		do while type('oObjRef.Parent') = 'O'
			cName = oObjRef.Parent.Name + '.' + cName
			oObjRef = oObjRef.Parent
			if !type('oObjRef.Parent') = 'O'
				* We're at the top--use the oWizard variable instead
				* of the Name and exit
				m.cName = 'oWizard.'+m.cName
				exit
			endif
		enddo

		m.cKeyboard = ""
		
		if between(m.nKeyCode, 0, 255) .and. ;
			(m.nShiftAltCtrl = 0 .or. m.nShiftAltCtrl = 1)
			do case
			case (isalpha(chr(m.nKeyCode)) .or. isdigit(chr(m.nKeyCode)))
				* Alphabetic and Numeric characters
				m.cKeyboard = '"' + chr(m.nKeyCode) + '"'
			case inlist(chr(m.nKeyCode), '.', ':', '\', '_')
				* Characters used in file and path names
				m.cKeyboard = '"' + chr(m.nKeyCode) + '"'
			endcase
		endif
		do case
		case !empty(m.cKeyboard)
			* The keystroke was handled above
		case m.nKeyCode = 32
			m.cKeyboard = '"{SPACEBAR}"'
		case m.nKeyCode = 13 .and. nShiftAltCtrl = 0
			m.cKeyboard = '"{ENTER}"'
		case m.nKeyCode = 9 .and. nShiftAltCtrl = 0
			m.cKeyboard = '"{TAB}"'
		case m.nKeyCode = 8 .and. nShiftAltCtrl = 0
			m.cKeyboard = '"{BACKSPACE}"'
		case m.nKeyCode = 331 .and. nShiftAltCtrl = 0
			m.cKeyboard = '"{LEFTARROW}"'
		case m.nKeyCode = 333 .and. nShiftAltCtrl = 0
			m.cKeyboard = '"{RIGHTARROW}"'
		case m.nKeyCode = 328 .and. nShiftAltCtrl = 0
			m.cKeyboard = '"{UPARROW}"'
		case m.nKeyCode = 336 .and. nShiftAltCtrl = 0
			m.cKeyboard = '"{DNARROW}"'
		endcase

		if !file(_logfile)
			m.iHandle = fcreate(_logfile)
		else
			m.iHandle = fopen(_logfile, 2)
		endif

		if m.iHandle = -1
			=MessageBox(iif(!file(_logfile), 'FCREATE("', 'FOPEN("') + ;
				_logfile + iif(!file(_logfile), '") ', '", 2)') + ;
				LOGFILEERROR_LOC)
			release _logfile
		else
			=fseek(m.iHandle, 0, 2) && go to EOF
			if !empty(m.cKeyboard)
				=fputs(m.iHandle, "KEYBOARD " + m.cKeyboard)
			else
				=fputs(m.iHandle, "* Keypress not handled: nKeyCode = " + ;
					alltrim(str(m.nKeyCode)) + ", nShiftAltCtrl = " + ;
					alltrim(str(m.nShiftAltCtrl)))
			endif
			=fclose(m.iHandle)
		endif
	endif
#ENDIF

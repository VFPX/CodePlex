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
		private iHandle, oObjRef, cName
		
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
			=fputs(m.iHandle, ;
				'DO COMMCLIK WITH "' + m.cName + '", "' + thisform.Name + '"')
			=fclose(m.iHandle)
		endif
	endif
#ENDIF

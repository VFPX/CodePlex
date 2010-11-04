#INCLUDE "vfp2c.h"

IF _VFP.StartMode = 0
	CD (_VFP.ActiveProject.HomeDir)
ENDIF

_SCREEN.FontName = 'Tahoma'
_SCREEN.FontSize = 9

SET CONFIRM ON
SET DELETED ON
SET NOTIFY OFF
SET NOTIFY CURSOR OFF
SET NULLDISPLAY TO ''
SET MULTILOCKS ON
SET OPTIMIZE ON
SET SAFETY OFF
SET TALK OFF
SET UDFPARMS TO VALUE

SET PROCEDURE TO cparser, codegen, cparsetypes ADDITIVE
SET LIBRARY TO vfp2c32.fll ADDITIVE

ON ERROR ErrorHandler(ERROR(),MESSAGE(),LINENO(),PROGRAM())

IF !InitVFP2C32(VFP2C_INIT_MARSHAL)
	LOCAL laError[1]
	AErrorEx('laError')
	MESSAGEBOX('VFP2C32 Library initialization failed:' + CRLF + ;
				'Error No: ' + TRANSFORM(laError[1]) + CRLF + ;
				'Function: ' + laError[2] + CRLF + ;
				"Message: '" + laError[3] + '"',48,'Error')
	RETURN
ENDIF

DO FORM frmvfp2c

IF _VFP.StartMode != 0
	READ EVENTS
	CLEAR ALL
ENDIF

FUNCTION ErrorHandler(nErrorNo,cMessage,nLineNo,cProgram)
	LOCAL lcMessage, lnRetVal
	lcMessage = 'An Error occurred: ' + CRLF + ;
				'Error No.: ' + ALLTRIM(STR(nErrorNo)) + CRLF + ;
				'Message: "' + cMessage + '"' + CRLF + ;
				'Procedure: "' + cProgram + '"' + CRLF + ;
				'LineNo: ' + ALLTRIM(STR(nLineNo)) + CRLF
				
	lnRetVal = MESSAGEBOX(lcMessage,48+2,'Error')

	DO CASE
		CASE lnRetVal = 3 && abort
			RETURN TO main
		CASE lnRetVal = 4 && retry
			RETRY
		CASE lnRetVal = 5 && ignore
	ENDCASE

ENDFUNC
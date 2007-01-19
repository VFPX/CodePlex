** This program is from http://www.news2news.com/vfp
** If you don't have a subscription to this 
** fantastic resource --- GET ONE!!!

FUNCTION VFPFindWindow
	LOCAL hParent, hWindow, cTitle, cRect 
	hParent = GetDesktopWindow() 
	hWindow = 0 

	CREATE CURSOR cs (winhandle I, x0 I, y0 I, x1 I, y1 I, wintitle C(200)) 
	INDEX ON UPPER(ALLTRIM(wintitle)) TAG wintitle    

	DO WHILE .T. 
	    STORE REPLICATE(CHR(0),255) TO cClass, cTitle 
	    hWindow = FindWindowEx(hParent, hWindow, Null, Null) 
	    
	    IF hWindow = 0 
 	        EXIT 
	    ELSE 
    	    cTitle = GetWinText(hWindow) 
	        cRect = GetWinRect(hWindow) 
	        INSERT INTO cs VALUES (hWindow,; 
	            buf2dword(SUBSTR(cRect, 1,4)),; 
	            buf2dword(SUBSTR(cRect, 5,4)),; 
	            buf2dword(SUBSTR(cRect, 9,4)),; 
	            buf2dword(SUBSTR(cRect, 13,4)),; 
	            cTitle) 
	    ENDIF 
	ENDDO 

	** Note: We are looking for Windows which have a caption of "DESKALERT"
	SELECT * FROM cs WHERE UPPER(ALLTRIM(wintitle)) == "DESKALERT" INTO ARRAY laTemp
	
	IF _TALLY > 0
		USE IN SELECT("cs")
		RETURN ALEN(laTemp,1)
	ELSE
		USE IN SELECT("cs")
		RETURN 0
	ENDIF	
ENDFUNC	
* end of main 

FUNCTION GetWinText(hWindow) 
    LOCAL cBuffer 
    cBuffer = REPLICATE(CHR(0), 255) 
    = GetWindowText(hWindow, @cBuffer, LEN(cBuffer)) 
RETURN STRTRAN(cBuffer, CHR(0), "") 

FUNCTION GetWinRect(hWindow) 
    LOCAL cBuffer 
    cBuffer = REPLICATE(CHR(0), 16) 
    = GetWindowRect(hWindow, @cBuffer) 
RETURN cBuffer 

FUNCTION buf2dword(lcBuffer) 
RETURN Asc(SUBSTR(lcBuffer, 1,1)) + ; 
    BitLShift(Asc(SUBSTR(lcBuffer, 2,1)),  8) +; 
    BitLShift(Asc(SUBSTR(lcBuffer, 3,1)), 16) +; 
    BitLShift(Asc(SUBSTR(lcBuffer, 4,1)), 2)
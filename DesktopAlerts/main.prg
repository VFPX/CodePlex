**********************************************************************
** Program...........: MAIN.PRG
** Author............: Kevin Ragsdale                     
** Project...........: VFPAlert                           
** Description.......: Main control program for the VFP Desktop
**					   Alert system.
** Calling Samples...: oObj = CreateObject("VFPAlert.AlertManager")
** Parameter List....: 
**********************************************************************

** Constants used within the Desktop Alerts System
#INCLUDE vfpalert.h

** 'Find' existing alerts (for placement of new alerts)
** This program can be found at Anatoliy Mogylevets'
** FoxPro WinAPI Online Reference web site:
** http://www.news2news.com/vfp
SET PROCEDURE TO vfpfindwindow.prg ADDITIVE

** Class library for all UI elements of Desktop Alerts
SET CLASSLIB TO deskalert.vcx

**********************************************************************
** Class.............: AlertManager
** Author............: Kevin Ragsdale                     
** Project...........: VFPAlert                           
** Description.......: Primary class for the application.
**********************************************************************
DEFINE CLASS AlertManager AS Session OLEPUBLIC
	Name = "VFPAlertManager"
	
	** Alerts is a collection used by the class to keep
	** track of open alerts.
	Alerts = .NULL.
	
	DIMENSION Alerts_COMATTRIB[5]
	Alerts_COMATTRIB[1] = 0
	Alerts_COMATTRIB[2] = "Collection object holding references to all active alerts"
	Alerts_COMATTRIB[3] = "Alerts"
	Alerts_COMATTRIB[4] = "Variant"
	Alerts_COMATTRIB[5] = 0	

	** How long will the alert remain onscreen?
	nWait = DA_WAIT
	
	DIMENSION nWait_COMATTRIB[5]
	nWait_COMATTRIB[1] = COMATTRIB_HIDDEN
	nWait_COMATTRIB[2] = "Number of seconds the alert will remain onscreen"
	nWait_COMATTRIB[3] = "nWait"
	nWait_COMATTRIB[4] = "Integer"
	nWait_COMATTRIB[5] = 0	

	** What percentage of "opaqueness" do we want?
	nPercent = DA_FADEPERCENT
	
	DIMENSION nPercent_COMATTRIB[5]
	nPercent_COMATTRIB[1] = COMATTRIB_HIDDEN
	nPercent_COMATTRIB[2] = "Percentage of opaqueness for the alert form"
	nPercent_COMATTRIB[3] = "nPercent"
	nPercent_COMATTRIB[4] = "Integer"
	nPercent_COMATTRIB[5] = 0	
	
	** Should we play a sound?
	lSound = .T.
	
	DIMENSION lSound_COMATTRIB[5]
	lSound_COMATTRIB[1] = COMATTRIB_HIDDEN
	lSound_COMATTRIB[2] = "Play a sound when the alert form appears"
	lSound_COMATTRIB[3] = "lSound"
	lSound_COMATTRIB[4] = "Boolean"
	lSound_COMATTRIB[5] = 0	

	** Do we need to WRITE the settings?
	lWriteSettings = .F.
	
	DIMENSION lWriteSettings_COMATTRIB[5]
	lWriteSettings_COMATTRIB[1] = COMATTRIB_WRITEONLY
	lWriteSettings_COMATTRIB[2] = "True if Settings form sets"
	lWriteSettings_COMATTRIB[3] = "lWriteSettings"
	lWriteSettings_COMATTRIB[4] = "Boolean"
	lWriteSettings_COMATTRIB[5] = 0	


	** What sound do we want to play?
	cSound = DA_DEFAULTSOUND
	
	DIMENSION cSound_COMATTRIB[5]
	cSound_COMATTRIB[1] = COMATTRIB_HIDDEN
	cSound_COMATTRIB[2] = "Sound file to play when the alert appears"
	cSound_COMATTRIB[3] = "cSound"
	cSound_COMATTRIB[4] = "String"
	cSound_COMATTRIB[5] = 0	
	
	PROCEDURE Init
		This.Setup()
	ENDPROC
	
	PROTECTED PROCEDURE Setup AS VOID
		WITH THIS
			** DECLARE our API Functions
			.APIDeclare()	
	
			** Read in any customized settings
			.ReadSettings()
					
			** Create the Alerts collection					
			.Alerts = CREATEOBJECT("Alerts")
		ENDWITH
	ENDPROC

	************************************************************
	*  PROCEDURE APIDeclare()
	************************************************************
	** Author............: Kevin Ragsdale                     
	** Project...........: VFPAlert                           
	** Description.......: We'll go ahead and do the API 
	**					   DECLARES now, since this object will 
	**					   "own" all of the child objects that 
	**					   use them. This way, we'll just 
	**                     DECLARE them all one time.
	************************************************************
	PROTECTED PROCEDURE APIDeclare AS VOID
		
		** Used within the Alert Form to get the Screen 
		** Height & Width, taking into account the TaskBar.
		** Thanks to Mike Lewis' article in FoxPro Advisor.
		DECLARE INTEGER SystemParametersInfo IN WIN32API ;
			AS _SystemParametersInfo ;
		    INTEGER   uiAction,;
		    INTEGER   uiParam,;
		    STRING    @pvParam,;
		    INTEGER   fWinIni

		** Since the Desktop Alerts "fade-in/out", we need to 
		** make sure we are running Win2K or higher.
		IF VAL(OS(3)) >= 5	&& Win2K or higher
			DECLARE SetWindowLong IN WIN32API AS _SetWindowLong;
				INTEGER, INTEGER, INTEGER
	
			DECLARE SetLayeredWindowAttributes IN WIN32API ;
				AS _SetLayeredWindowAttributes ;
				INTEGER, STRING, INTEGER, INTEGER
		ENDIF
		
		** API Functions for FindWindow
		DECLARE INTEGER GetLastError IN kernel32 
	
	    DECLARE INTEGER GetDesktopWindow IN user32 

	    DECLARE INTEGER FindWindowEx IN user32; 
	        INTEGER hwndParent, INTEGER hwndChildAfter,; 
	        STRING @lpszClass, STRING @lpszWindow 

    	DECLARE INTEGER GetWindowText IN user32; 
	        INTEGER hWnd, STRING @lpString, INTEGER nMaxCount 

    	DECLARE INTEGER GetWindowRect IN user32; 
	        INTEGER hWnd, STRING lpRect 
		
	   	** API Functions for "moving" the Alert form
	    DECLARE INTEGER ReleaseCapture IN user32 
    
    	DECLARE INTEGER GetFocus IN user32 
	
	    DECLARE INTEGER SendMessage IN user32; 
    	    INTEGER hWnd, INTEGER Msg, INTEGER wParam, INTEGER lParam 
	ENDPROC		
	
	************************************************************
	*  PROCEDURE ReadSettings()
	************************************************************
	** Author............: Kevin Ragsdale                     
	** Project...........: VFPAlert                           
	** Description.......: Read in the User-Configurable options
	**					   (if they exist) and set the 
	**					   AlertManager's properties.
	**   
    ** 		The CONFIG file is a 'homemade' XML-like file:
	** 		<DACONFIG>
	**			<WAIT>
	**			<PERCENT>
	**			<PLAYSOUND>
	**		</DACONFIG>
	************************************************************
	PROTECTED PROCEDURE ReadSettings
		LOCAL lcConfig AS String, lcWait AS String, ;
			  lcPercent AS String, lcPlaySound AS String, ;
			  lcPath AS String
		
		lcPath = GetAppStartPath()
		
		IF FILE(lcPath + DA_CONFIGFILE)
			lcConfig = FILETOSTR(lcPath + DA_CONFIGFILE)
			
			lcWait = STREXTRACT(lcConfig,"<WAIT>","</",1)
			IF !EMPTY(ALLTRIM(lcWait))
				IF ISDIGIT(lcWait)
					This.nWait = INT(VAL(lcWait))
				ENDIF	
			ENDIF	
			
			lcPercent = STREXTRACT(lcConfig,"<PERCENT>","</",1)
			IF !EMPTY(lcPercent)
				IF ISDIGIT(lcPercent)
					This.nPercent = INT(VAL(lcPercent))
				ENDIF
			ENDIF
			
			lcPlaySound = STREXTRACT(lcConfig,"<PLAY>","</",1)
			IF !EMPTY(lcPlaySound)
				This.lSound = (VAL(lcPlaySound) = 1)
			ENDIF
		ENDIF
	ENDPROC
	
	************************************************************
	*  PROCEDURE WriteSettings()
	************************************************************
	** Author............: Kevin Ragsdale                     
	** Project...........: VFPAlert                           
	** Description.......: Write the User-Configurable options
	**					   to a file.
	**   
    ** 		The CONFIG file is a 'homemade' XML-like file:
	** 		<DACONFIG>
	**			<WAIT>
	**			<PERCENT>
	**			<PLAYSOUND>
	**		</DACONFIG>
	************************************************************
	PROCEDURE WriteSettings AS VOID
		LOCAL lcSettings AS String, lcPath AS String
		
		lcSettings = "<DACONFIG>" + CRLF + ;
					 "<WAIT>" + TRANSFORM(This.nWait) + "</WAIT>" + CRLF + ;
					 "<PERCENT>" + TRANSFORM(This.nPercent) + "</PERCENT>" + CRLF + ;
					 "<PLAY>" + IIF(This.lSound,"1","0") + "</PLAY>" + CRLF + ;
					 "</DACONFIG>" + CRLF
		
		lcPath = GetAppStartPath()
		
		STRTOFILE(lcSettings,lcPath + DA_CONFIGFILE,0)
	ENDPROC
	
	************************************************************
	*  PROCEDURE NewAlert()
	************************************************************
	** Author............: Kevin Ragsdale                     
	** Project...........: VFPAlert                           
	** Description.......: Creates an instance of the Alert 
	**                     class, adds it to the Alerts 
	**                     collection, and returns an object
	**                     reference to the calling object.
	************************************************************
	PROCEDURE NewAlert AS Object
		LOCAL loObject AS Object, lcName AS String
		lcName = SYS(2015)
		loObject = CREATEOBJECT("Alert",THIS,lcName)
		This.Alerts.Add(loObject,lcName)
		RETURN loObject
	ENDPROC
	
	************************************************************
	*  PROCEDURE lWriteSettings_Assign()
	************************************************************
	** Author............: Kevin Ragsdale                     
	** Project...........: VFPAlert                           
	** Description.......: If .T., WriteSettings()
	************************************************************
	PROCEDURE lWriteSettings_Assign
		LPARAMETERS vNewValue
		This.lWriteSettings = m.vNewValue
		
		IF This.lWriteSettings
			This.WriteSettings()
			This.lWriteSettings = .F.
		ENDIF
	ENDPROC
			
	************************************************************
	*  PROCEDURE Release()
	************************************************************
	** Author............: Kevin Ragsdale                     
	** Project...........: VFPAlert                           
	** Description.......: Release the AlertManager
	************************************************************
	PROCEDURE Release
		This.Alerts = .NULL.
		RELEASE THIS
	ENDPROC	
	
	************************************************************
	*  PROCEDURE Error()
	************************************************************
	** Author............: Kevin Ragsdale                     
	** Project...........: VFPAlert                           
	** Description.......: Error handler
	************************************************************
	FUNCTION Error (nError, cMethod, nLine)
		COMRETURNERROR("Desktop Alert Error","ErrNo: " + TRANSFORM(nError) + " - Method: " + ALLTRIM(cMethod) + " - LineNo: " + TRANSFORM(nLine))
	ENDFUNC
	
	************************************************************
	*  PROCEDURE ShowSettings()
	************************************************************
	** Author............: Kevin Ragsdale                     
	** Project...........: VFPAlert                           
	** Description.......: Launches the Settings form
	** Parameters........: tlForm (was called by the settings
	**                             button on the Alert form)
	**                     toForm (object reference for the
	**                             Alert form)
	** NOTE: You could call this from a menu with 
	**       AlertManager.ShowSettings()
	************************************************************
	FUNCTION ShowSettings (tlForm AS Boolean, toForm AS Object)
		DO FORM frmSettings WITH THIS,tlForm,IIF(VARTYPE(toForm)=="O",toForm,.NULL.)
	ENDFUNC
ENDDEFINE

**********************************************************************
** Class.............: ALERTS
** Author............: Kevin Ragsdale                     
** Project...........: VFPAlert                           
** Description.......: Collection class used by AlertManager to keep
**                     track of 'open' alerts.
**********************************************************************
DEFINE CLASS Alerts AS Collection
	PROCEDURE Count_Access
		RETURN This.Count
	ENDPROC
ENDDEFINE

**********************************************************************
** Class.............: ALERT
** Author............: Kevin Ragsdale                     
** Project...........: VFPAlert                           
** Description.......: Receives parameters for an Alert, parses the
**                     parameters, and launches the Alert form. Also
**                     contains the SetCallback() method, which tells
**                     the Alert 'who' should receive the AlertResult.
**********************************************************************
DEFINE CLASS Alert AS Session 

	** Object reference to the AlertManager
	oMgr = .NULL.
	
	DIMENSION oMgr_COMATTRIB[5]
	oMgr_COMATTRIB[1] = COMATTRIB_HIDDEN
	oMgr_COMATTRIB[2] = "Reference to the AlertManager class"
	oMgr_COMATTRIB[3] = "oMgr"
	oMgr_COMATTRIB[4] = "Variant"
	oMgr_COMATTRIB[5] = 0	
		
	** Object reference to the calling object (event handler object)
	oCallback = .NULL.
	
	DIMENSION oCallback_COMATTRIB[5]
	oCallback_COMATTRIB[1] = COMATTRIB_HIDDEN
	oCallback_COMATTRIB[2] = "Reference to the Alert client"
	oCallback_COMATTRIB[3] = "oCallback"
	oCallback_COMATTRIB[4] = "Variant"
	oCallback_COMATTRIB[5] = 0	
	
	** Object reference to this alert's Alert form
	oAlertForm = .NULL.
	
	DIMENSION oAlertForm_COMATTRIB[5]
	oAlertForm_COMATTRIB[1] = COMATTRIB_HIDDEN
	oAlertForm_COMATTRIB[2] = "Reference to the Alert form"
	oAlertForm_COMATTRIB[3] = "oAlertForm"
	oAlertForm_COMATTRIB[4] = "Variant"
	oAlertForm_COMATTRIB[5] = 0
	
	** The Alert Result. Returned to us by the
	** Alert form. Default is 0.
	nResult = 0
	
	DIMENSION nResult_COMATTRIB[5]
	nResult_COMATTRIB[1] = 0
	nResult_COMATTRIB[2] = "The result of the Alert"
	nResult_COMATTRIB[3] = "nResult"
	nResult_COMATTRIB[4] = "Integer"
	nResult_COMATTRIB[5] = 0		
	
	** The number of seconds the alert form will appear onscreen
	nWait = DA_WAIT
	
	DIMENSION nWait_COMATTRIB[5]
	nWait_COMATTRIB[1] = COMATTRIB_HIDDEN
	nWait_COMATTRIB[2] = "Number of seconds the alert will remain onscreen"
	nWait_COMATTRIB[3] = "nWait"
	nWait_COMATTRIB[4] = "Integer"
	nWait_COMATTRIB[5] = 0		
	
	** The percentage of 'opaqueness' for the Alert form
	nPercent = DA_FADEPERCENT
	
	DIMENSION nPercent_COMATTRIB[5]
	nPercent_COMATTRIB[1] = COMATTRIB_HIDDEN
	nPercent_COMATTRIB[2] = "Percentage of opaqueness for the alert form"
	nPercent_COMATTRIB[3] = "nPercent"
	nPercent_COMATTRIB[4] = "Integer"
	nPercent_COMATTRIB[5] = 0	
	
	** Play a sound when the Alert form appears?
	lSound = .F.
	
	DIMENSION lSound_COMATTRIB[5]
	lSound_COMATTRIB[1] = COMATTRIB_HIDDEN
	lSound_COMATTRIB[2] = "Play a sound when the alert form appears"
	lSound_COMATTRIB[3] = "lSound"
	lSound_COMATTRIB[4] = "Boolean"
	lSound_COMATTRIB[5] = 0	
	
	** Sound file to play when the alert form appears
	** (if lSound = .T.)
	cSound = DA_DEFAULTSOUND
	
	DIMENSION cSound_COMATTRIB[5]
	cSound_COMATTRIB[1] = COMATTRIB_HIDDEN
	cSound_COMATTRIB[2] = "Sound file to play when the alert appears"
	cSound_COMATTRIB[3] = "cSound"
	cSound_COMATTRIB[4] = "String"
	cSound_COMATTRIB[5] = 0				
	
	************************************************************
	*  PROCEDURE Init()
	************************************************************
	** Author............: Kevin Ragsdale                     
	** Project...........: VFPAlert                           
	** Description.......: initialization code
	************************************************************
	PROCEDURE Init (toAlertMgr AS Object, tcName AS String)
		WITH THIS
			.oMgr = toAlertMgr
			.Name = tcName
			.Setup()
		ENDWITH	
	ENDPROC

	************************************************************
	*  PROCEDURE Setup()
	************************************************************
	** Author............: Kevin Ragsdale                     
	** Project...........: VFPAlert                           
	** Description.......: Initialize property values
	************************************************************
	PROTECTED PROCEDURE Setup
		WITH THIS
			.nWait    = .oMgr.nWait
			.nPercent = .oMgr.nPercent
			.lSound   = .oMgr.lSound
			
			** Call SetCallback with a NULL parameter
			.SetCallback(.NULL.)
		ENDWITH	
	ENDPROC

	************************************************************
	*  PROCEDURE SetCallback()
	************************************************************
	** Author............: Kevin Ragsdale                     
	** Project...........: VFPAlert                           
	** Description.......: Sets an object reference to the 
	**                     event handler object for this Alert.
	************************************************************
	PROCEDURE SetCallback (toCallBack AS Variant) AS VOID ;
				HELPSTRING "Gets/Sets a reference to the client event handler"
				
		LOCAL loException AS Exception
		loException = .NULL.
				
		IF ISNULL(toCallback)
			** Dummy instance that does nothing: virtual function
			This.oCallback = CREATEOBJECT("AlertEvents")
		ELSE
			IF VARTYPE(toCallback) # "O"
				COMRETURNERROR("Function SetCallback()","Callback object must be an Object")
			ENDIF
			
			** We'll TRY to see if the client event handler is implementing
			** the IAlertEvents interface,
			TRY
				This.oCallback = GETINTERFACE(toCallback,"Ialertevents","vfpalert.AlertManager")
			CATCH TO loException
			ENDTRY
			
			IF !ISNULL(loException)
				** An exception was created on the GETINTERFACE line.
				** Reference the object that came in, and hope for the best.
				This.oCallback = toCallback
			ENDIF			
		ENDIF
	ENDPROC	
	
	************************************************************
	*  PROCEDURE Alert()
	************************************************************
	** Author............: Kevin Ragsdale                     
	** Project...........: VFPAlert                           
	** Description.......: Parses the parameters, and creates an
	**                     instance of frmAlert (the actual 
	**                     form which appears on the screen).
	************************************************************
	PROCEDURE Alert (cAlertText AS String, ;
					 nAlertType AS Integer, ;
					 cAlertTitle, ;
					 cAlertSubject, ;
	  				 cIconfile, ;
					 cTask1, ;
					 cTask1Icon, ;
					 cTask2, ;
					 cTask2Icon) AS VOID ;
						 HELPSTRING "Create the Alert Form based on parameters passed in"

		LOCAL lcName AS String, loParams AS Object, ;
			  lnType AS Integer, lnIcon AS Integer, ;
			  llHideSettings AS Boolean, llHideClose AS Boolean, ;
			  llHidePin AS Boolean, lcPath AS Sting
		
		** Set the default values
		lcName 		   = This.Name			&& Will be the 'name' of the alert
		loParams 	   = .NULL.				&& Parameter Object
		lnType	 	   = 0					&& Type of alert to create
		lnIcon 		   = 0					&& Icon to use for alert
		llHideSettings = .F.				&& Show the settings button by default	
		llHideClose    = .F.				&& Show the close button by default	
		llHidePin      = .F.				&& Show the push-pin button by default	
		lcPath         = ""					&& AppStartPath
		
		** Get the number of parameters passed in
		lnParams = PCOUNT()			
		
		IF PCOUNT() < 1
			COMRETURNERROR("Function NewALERT()","NewAlert requires at least " + ;
						   "one parameter [cAlertText].")
		ENDIF
		
		** If we made it this far, then we have at least 1 parameter passed in.
		** The first one MUST be the "detail" text for the alert.
		** If the first parameter is not a string, TRANSFORM() it.
		
		** NOTE: If you pass object references, then the string "(Object)" 
		** will appear on the form, thanks to the TRANSFORM function.
		
		IF VARTYPE(cAlertText) # "C"
			cAlertText = TRANSFORM(cAlertText)
		ENDIF
		
		** The second (optional) parameter must be an integer,  
		** which defines the type of alert. 
		IF VARTYPE(nAlertType) # "N"
			nAlertType = 0
		ENDIF		
		
		** Make sure it's an INTEGER value
		IF MOD(nAlertType,1) # 0
			nAlertType = INT(nAlertType)
		ENDIF	
			
		** Do a series of BITTEST() calls to determine the Alert Type 
		** and Alert Icon to be used.
		
		** We'll start at the "outer-most" bit, which currently is
		** 16384 (bit 14).
		
		** Do we want to hide the close button?
		llHideClose = BITTEST(nAlertType,14)
		
		** Do we want to hide the push=pin button?
		llHidePin = BITTEST(nAlertType,13)
		
		** Do we want to hide the settings button?
		llHideSettings = BITTEST(nAlertType,12)

		** What kind of ICON do we want to appear on the alert?
		FOR i = 7 TO 3 STEP -1
			IF BITTEST(nAlertType,i)
				IF i = 5	
					** Bit 5 is 32 (ICONQUESTION). We need to
					** check to see if the next bit is "on".
					** This will mean 48 was passed in, which
					** is the value of ICONEXCLAMTION.
					IF BITTEST(nAlertType,i-1)
						** Yes, bit 4 = 16. Add it to the 32.
						lnIcon = (2^i) + (2^(i-1))
						EXIT
					ELSE
						** Nope, a 32 was passed in.
						lnIcon = 2^i
						EXIT
					ENDIF
				ELSE
					lnIcon = 2^i		
					EXIT
				ENDIF	
			ENDIF
		ENDFOR
		
		** If we don't have a 'built-in' icon to use, 
		** just use the 'default' icon.
		IF lnIcon = 0
			lnIcon = DA_ICONDEFAULT
		ENDIF	
		
		** Now, check the Alert Type, which 
		** will be in either BIT 2, 1 or 0.
		DO CASE
			CASE BITTEST(nAlertType,2)
				** MultiTask (two tasks are 
				** associated with this alert).
				** We need to see if there is
				** also a "link" in addition to 
				** the 2 tasks.
				IF BITTEST(nAlertType,0)
					** We also need a "link"
					lnType = DA_TYPEMULTI + DA_TYPELINK
				ELSE
					** No link	
					lnType = DA_TYPEMULTI
				ENDIF			
				
			CASE BITTEST(nAlertType,1)	
				** Task (one task is associated).
				** We need to see if there is
				** also a "link" in addition to 
				** the task.
				IF BITTEST(nAlertType,0)
					** We also need a "link"
					lnType = DA_TYPETASK + DA_TYPELINK
				ELSE
					lnType = DA_TYPETASK
				ENDIF	
			CASE BITTEST(nAlertType,0)
				** Link (No tasks, but the details
				** should appear as a hyperlink)
				lnType = DA_TYPELINK
			OTHERWISE
				** PLAIN (No tasks, no link)
				lnType = DA_TYPEPLAIN
		ENDCASE					
				
		** We have the TYPE, and the ICON. Create a 
		** parameter Object to pass to the alert form.
		** We'll use the EMPTY class for the parameter
		** object, using ADDPROPERTY() to, you know, 
		** add the properties.
		
		LOCAL loParams AS Object
		loParams = CREATEOBJECT("Empty")
		
		ADDPROPERTY(loParams,"Name",lcName)
		ADDPROPERTY(loParams,"Type",lnType)
		ADDPROPERTY(loParams,"Icon",lnIcon)
		ADDPROPERTY(loParams,"IconFile","")
		ADDPROPERTY(loParams,"Title","")
		ADDPROPERTY(loParams,"Subject","")
		ADDPROPERTY(loParams,"AlertText",cAlertText)
		ADDPROPERTY(loParams,"HideSettings",llHideSettings)
		ADDPROPERTY(loParams,"HideClose",llHideClose)
		ADDPROPERTY(loParams,"HidePin",llHidePin)
		
		** If the 'type' includes tasks, add the 
		** Task properties.
		IF lnType > DA_TYPELINK
			ADDPROPERTY(loParams,"Task1","")
			ADDPROPERTY(loParams,"Task1Icon","")
			IF lnType > DA_TYPETASK
				ADDPROPERTY(loParams,"Task2","")
				ADDPROPERTY(loParams,"Task2Icon","")
			ENDIF
		ENDIF
	
		** We need to "walk" through the rest of the parameters
		IF VARTYPE(cAlertTitle) # "C"
			IF VARTYPE(cAlertTitle) = "L"
				loParams.Title = DA_DEFAULTTITLE
			ELSE
				loParams.Title = SUBSTR(TRANSFORM(cAlertTitle),1,30)
			ENDIF
		ELSE
			loParams.Title = SUBSTR(cAlertTitle,1,30)
		ENDIF	
			
		IF VARTYPE(cAlertSubject) # "C"
			IF VARTYPE(cAlertSubject) = "L"
				loParams.Subject = ""
			ELSE
				loParams.Subject = SUBSTR(TRANSFORM(cAlertSubject),1,50)
			ENDIF
		ELSE
			loParams.Subject = SUBSTR(cAlertSubject,1,50)
		ENDIF	
		
		IF VARTYPE(cIconFile) # "C"
			loParams.IconFile = DA_DEFAULTICONFILE
		ELSE
			IF FILE(cIconFile)
				loParams.IconFile = cIconFile
			ELSE
				loParams.IconFile = DA_DEFAULTICONFILE					
			ENDIF
		ENDIF

		** Check for Tasks and Task Icons
		IF lnType > DA_TYPELINK
			** The next param should be the Task1
			IF VARTYPE(cTask1) # "C"
				IF VARTYPE(cTask1) = "L"
					loParams.Task1 = ""
				ELSE
					loParams.Task1 = TRANSFORM(cTask1)
				ENDIF
			ELSE
				loParams.Task1 = ALLTRIM(cTask1)
			ENDIF
	
			** The next param should be the Task1Icon
			IF !EMPTY(ALLTRIM(loParams.Task1))
				IF VARTYPE(cTask1Icon) # "C"
					loParams.Task1Icon = DA_DEFAULTTASKFILE
				ELSE
					IF FILE(cTask1Icon)
						loParams.Task1Icon = cTask1Icon
					ELSE
						loParams.Task1Icon = DA_DEFAULTTASKFILE	
					ENDIF
				ENDIF				
			ENDIF
				
			** If a Multi Task, the next param
			** should be Task2
			IF lnType >= DA_TYPEMULTI
				IF VARTYPE(cTask2) # "C"
					IF VARTYPE(cTask2) = "L"
						loParams.Task2 = ""
					ELSE
						loParams.Task2 = TRANSFORM(cTask2)
					ENDIF
				ELSE
					loParams.Task2 = ALLTRIM(cTask2)
				ENDIF
					
				IF !EMPTY(ALLTRIM(loParams.Task2))
					IF VARTYPE(cTask2Icon) # "C"
						loParams.Task2Icon = DA_DEFAULTTASKFILE
					ELSE
						IF FILE(cTask2Icon)
							loParams.Task2Icon = cTask2Icon
						ELSE
							loParams.Task2Icon = DA_DEFAULTTASKFILE
						ENDIF
					ENDIF
				ENDIF				
			ENDIF				
		ENDIF	
		
		** We have a file, ALERTWAV.TXT which is 'built-in' to the
		** executable. We can use STRTOFILE() to write it out 
		** 'on-the-fly'.
		lcPath = GetAppStartPath()
		IF !FILE(ADDBS(lcPath) + DA_DEFAULTSOUND)
			STRTOFILE(FILETOSTR(FORCEEXT(STRTRAN(DA_DEFAULTSOUND,".",""),"TXT")),ADDBS(lcPath) + DA_DEFAULTSOUND)
        ENDIF
        
		** Create an instance of the alert form, passing in the loParams
		** object, and THIS Alert object.
		This.oAlertForm = CREATEOBJECT("frmAlert",loParams,THIS)
	ENDPROC	
		
	************************************************************
	*  PROCEDURE nResult_Assign()
	************************************************************
	** Author............: Kevin Ragsdale                     
	** Project...........: VFPAlert                           
	** Description.......: Assign method for the Alert result
	************************************************************
	PROCEDURE nResult_Assign
		LPARAMETERS vNewValue
		This.nResult = m.vNewValue
		
		LOCAL loException AS Exception
		loException = .NULL.
		
		IF This.nResult # 0
			
			** We're going to TRY to call the event handler's
			** AlertResult method. If it doesn't work, then 
			** nothing happens.
			TRY
				This.oCallBack.AlertResult(This.nResult)
			CATCH TO loException
			ENDTRY
		ENDIF
		
		** Release this instance
		This.Release()
	ENDPROC		
		
	************************************************************
	*  PROCEDURE Release()
	************************************************************
	** Author............: Kevin Ragsdale                     
	** Project...........: VFPAlert                           
	** Description.......: Release the Alert
	************************************************************
	PROCEDURE Release
		** Get rid of the form - this line causes the Alert form
		** to just disappear, instead of fading out.
		This.oAlertForm = .NULL.
		
		** Remove this Alert from the AlertManager's Alerts
		** collection.
		This.oMgr.Alerts.Remove(This.Name)
		
		RELEASE THIS
	ENDPROC	
ENDDEFINE

**********************************************************************
** Class.............: AlertEvents
** Author............: Kevin Ragsdale                     
** Project...........: VFPAlert                           
** Description.......: This is the INTERFACE for the Desktop Alerts
**                     system. It can be IMPLEMENTed by the calling
**                     object's event handler.
**********************************************************************
DEFINE CLASS AlertEvents AS Session OLEPUBLIC
	************************************************************
	*  PROCEDURE AlertResult()
	************************************************************
	** Author............: Kevin Ragsdale                     
	** Project...........: VFPAlert                           
	** Description.......: This is the Method which is 'fired'
	**                     when an Alert's nresult is Assigned.
	** Parameters........: The 'result' of the Alert.
	************************************************************
	PROCEDURE AlertResult (tnResult AS Integer) AS Integer
	ENDPROC
ENDDEFINE



FUNCTION GetAppStartPath AS String
	** Stole code from Rick Strahl to determine where
	** the EXE is located. We'll use this path for the
	** DACONFIG.XML configuration file.
	LOCAL lcFileName AS String, lnBytes AS Integer
	
	DECLARE INTEGER GetModuleFileName IN Win32API ;
		INTEGER hinst, String @lpszFilename, INTEGER @cbFileName
   
    lcFileName=SPACE(256)
    lnBytes=255   
    GetModuleFileName(0,@lcFileName,@lnBytes)

    lnBytes=AT(CHR(0),lcFileName)
    IF lnBytes > 1
	   	lcFileName=SUBSTR(lcFileName,1,lnBytes-1)
    ELSE
       	lcFileName=""
    ENDIF       
       
    lcPath = ADDBS(JUSTPATH(lcFileName))
	RETURN lcPath
ENDFUNC
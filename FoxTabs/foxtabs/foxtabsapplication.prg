If Directory("c:\documents and settings\cb\my documents\visual foxpro projects\foxtabs\foxtabs\" )
	Set Default To "c:\documents and settings\cb\my documents\visual foxpro projects\foxtabs\foxtabs\" 
EndIf

* FoxTabs Application
Public oFoxTabs As FoxTabsApplication

* Create an instance of our FoxTabs application class
oFoxTabs = NewObject("FoxTabsApplication")

* Call the main method to process windows and user events
oFoxTabs.Main()
Set Datasession To (oFoxTabs.PrevDataSession)

* All done
Return

Define Class FoxTabsApplication As Custom

	Version		= "0.7.0 Beta"
	ConfigFile 	= ""
	LogFile		= ""
	PrevDataSession = .f.
	DataSession = .f.
	
	Function Main()

		Local lcConfigFile As String, lcWonTop
		
		* Create Private DataSession so we can SET TALK OFF
		* Otherwise, TALK is very noisy
		This.PrevDataSession = Set("Datasession")		
		This.DataSession = CreateObject("Session")
		This.DataSession.Name = "FoxTabs"
		Set Datasession To (This.DataSession.DataSessionID)
		Set Talk Off
		Set Exclusive Off
		Set Deleted On		
		
		* Determine the name and path of the configuration and log file
		*	This will be the full path and name of the calling application
		*	with the "config" | "log" extension.
		This.ConfigFile = ForceExt(Sys(16, Program(-1) - 1), "config")
		This.LogFile	= ForceExt(Sys(16, Program(-1) - 1), "log")
		
		* Add the configuration block
		This.NewObject("Configuration", "foxtabsconfig", "foxtabs.vcx")
		This.Configuration.AppSettingsVersion = This.Version
		This.Configuration.LoadConfig(This.ConfigFile)

		* Create an instance of the FoxTabs user interface
		This.NewObject("FoxTabsToolbar", "foxtabstoolbar", "foxtabs.vcx")
		
		* Add the FoxTabs manager class
		This.NewObject("FoxTabsManager", "foxtabsmanager", "foxtabsmanager.prg")

		* Setup event bindings
		This.SetBindings()

		* Load the existing IDE windows
		This.FoxTabsManager.LoadWindows(Application.hWnd)

		* Show the toolbar
		This.FoxTabsToolbar.Visible = .T.

		* Reactivate top window and make sure tab highlighted
		Activate Window screen
		lcWontop = Wontop()
		If !Empty(lcWontop)
			Hide Window (lcWonTop)
			Activate Window (lcWonTop) TOP
		EndIf 
	
	EndFunc 
	
	Function SetBindings()
	
		* Setup bindings for our FoxTabs manager class
		This.FoxTabsManager.SetBindings()
	
		* Setup bindings between the FoxTabs Manager and FoxTabs UI
		BindEvent(This.FoxTabsManager, "AddFoxTabEvent", 	This.FoxTabsToolbar, "AddFoxTab")
		BindEvent(This.FoxTabsManager, "RemoveFoxTabEvent",	This.FoxTabsToolbar, "RemoveFoxTab")
		BindEvent(This.FoxTabsManager, "GotFocusEvent", 	This.FoxTabsToolbar, "GotFocus")
		BindEvent(This.FoxTabsManager, "OnChangeEvent", 	This.FoxTabsToolbar, "OnChange")

	EndFunc 
	
	* Define logging event delgates
	Function LogError(oException As Exception, lpcUserDetails As String)

		Local lcLogEntry As String, lnDepth As Integer 

		lcLogEntry	= ""
		lnDepth 	= 1

		Try
			* Walk down exception hierachy until the originating exception is processed
			Do While .T.
				* Check for first exception
				If lnDepth = 1
					* Format error details message including datetime
					Text To lcLogEntry Additive TextMerge NoShow PreText 2
						<<Replicate("_", 80)>>
						
						Time:    <<Transform(Datetime())>>
						Error:   <<Transform(oException.ErrorNo)>>
						Program: <<Transform(oException.Procedure)>>
						Line no: <<Transform(oException.LineNo)>>
						Line:  	 <<Transform(oException.LineContents)>>
						Message: <<Transform(oException.Message)>>
						Details:  	 
						<<Nvl(oException.Details, "")>>
						User details:
						<<Iif(VarType(oException.UserValue) = "C", Transform(oException.UserValue), Transform(lpcUserDetails))>>
						
					EndText 
				Else
					* Format error details message excluding datetime and with depth indent
					Text To lcLogEntry Additive TextMerge NoShow PreText 2 
						<<Replicate(Space(3), lnDepth)>><<Replicate("- ", 40)>>
						<<Replicate(Space(3), lnDepth)>>Error:   <<Transform(oException.ErrorNo)>>
						<<Replicate(Space(3), lnDepth)>>Program: <<Transform(oException.Procedure)>>
						<<Replicate(Space(3), lnDepth)>>Line no: <<Transform(oException.LineNo)>>
						<<Replicate(Space(3), lnDepth)>>Line:  	 <<Transform(oException.LineContents)>>
						<<Replicate(Space(3), lnDepth)>>Message: <<Transform(oException.Message)>>
						<<Replicate(Space(3), lnDepth)>>Details:  	 
						<<Replicate(Space(3), lnDepth)>><<Nvl(oException.Details, "")>>
						<<Replicate(Space(3), lnDepth)>>User details:
						<<Replicate(Space(3), lnDepth)>><<Iif(VarType(oException.UserValue) = "C", Transform(oException.UserValue), "")>>
						
					EndText		
				EndIf
				
				* Move to next exception in hierachy
				If VarType(oException.UserValue) = "O"
					oException = oException.UserValue
					lnDepth = lnDepth + 1
				Else
					Exit
				EndIf 

			EndDo
			
			* Write to log 
			StrToFile(lcLogEntry, This.LogFile, 1)

		Catch
			* I give up. You win!
		EndTry

	EndFunc 
	
	Function LogEvent(lpcEvent As String, lpcUserDetails As String)
	
	EndFunc 
	
EndDefine 




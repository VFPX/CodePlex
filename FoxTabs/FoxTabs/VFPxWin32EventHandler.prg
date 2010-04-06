*-***********************************************************************************************
*-*  Written by:  Gregory A. Green
*-*  Initial Development: 6 May 2009
*-* 
*-*  Change History
*-*  6 May 2009    Added check in UnBindEvent to execute UNBINDEVENTS() if no longer requested
*-*                Renamed method UnBindEvent to UnBindEvents to match VFP name
*-*
*-***********************************************************************************************
*-*  Class for managing the BINDEVENT() Command for a common foundation for Win32 Events
*-*
*-*  && Sample for implementation and use
*-*  && Check if class is loaded
*-*  IF !PEMSTATUS(_SCREEN,"oEventHandler",5)
*-*  	_SCREEN.NewObject("oEventHandler","VFPxWin32EventHandler","VFPxWin32EventHandler.prg")
*-*  ENDIF
*-*  
*-*  && To bind to a Win32 Event
*-*  _SCREEN.oEventHandler.BindEvent(0, WM_CREATE, this, "MyEventHandler", lnFlags)
*-*  
*-* && To unbind to a Win32 Event
*-*  lhWnd     = 0
*-*  lnMessage = WM_CREATE
*-*  _SCREEN.oEventHandler.UnBindEvent(TRANFORM(lhWnd)+TRANSFORM(lnMessage)+this.Class)
*-*
*-***********************************************************************************************
DEFINE CLASS VFPxWin32EventHandler AS Collection 
	bDebug   = .F.
	hdlDebug = -1

	PROCEDURE BindEvent
		LPARAMETERS thWnd, tnMessage, toEventHandler, tcDelegate, tnFlags
		LOCAL loBind as WinEvent of VFPxWin32EventHandler.prg, lnNum, lnNdx, lbEventNotBinded, lcKey, lnReturn
		LOCAL ARRAY laEvents[1,4]
*-*		Add the requested Event Binding to the collection
*JAL*			loBind = NEWOBJECT("Empty")
*JAL*			ADDPROPERTY(loBind, "hWnd", thWnd)                      && Window handle
*JAL*			ADDPROPERTY(loBind, "nMessage", tnMessage)              && Event
*JAL*			ADDPROPERTY(loBind, "oEventHandler", toEventHandler)    && Event handler object
*JAL*			ADDPROPERTY(loBind, "cDelegate", tcDelegate)            && Event handler method
*JAL*			lcKey = SYS(2015)
		loBind = NewObject("WinEvent", "VFPxWin32EventHandler.prg")
		loBind.hWnd = thWnd
		loBind.nMessage = tnMessage
		lcKey = Transform(thWnd) + "~" + Transform(tnMessage)
		If this.GetKey(lcKey) = 0
			this.Add(loBind,lcKey) 
		EndIf 
		* Bind Win event to collection
		BindEvent(thWnd, tnMessage, loBind, "EventFired")
		* Bind collection object to event handler/delegate
		IF PCOUNT() = 4
			lnReturn = BindEvent(loBind, "EventFired", toEventHandler, tcDelegate)
		ELSE
			lnReturn = BindEvent(loBind, "EventFired", toEventHandler, tcDelegate, tnFlags)
		EndIf
		
		*This.CleanupEvents()
		
		Return lnReturn 
*JAL*	*-*		Check if the requested event has already been binded to by this class
*JAL*			lnNum = AEVENTS(laEvents,1)
*JAL*			lbEventNotBinded = .T.
*JAL*			FOR lnNdx=1 TO lnNum
*JAL*				IF laEvents[lnNdx,1] = thWnd .AND. laEvents[lnNdx,2] = tnMessage
*JAL*					lbEventNotBinded = .F.
*JAL*					EXIT
*JAL*				ENDIF
*JAL*			ENDFOR
*JAL*			IF this.bDebug
*JAL*				=FPUTS(this.hdlDebug,"Bind Registered - hWnd: "+TRANSFORM(thWnd) + " nMsg: "+TRANSFORM(tnMessage))
*JAL*			ENDIF
*JAL*			IF lbEventNotBinded
*JAL*				IF this.bDebug
*JAL*					=FPUTS(this.hdlDebug,"Bind Start - hWnd: "+TRANSFORM(thWnd) + " nMsg: "+TRANSFORM(tnMessage))
*JAL*				ENDIF
*JAL*				IF PCOUNT() = 4
*JAL*					BINDEVENT(thWnd,tnMessage,this,"OnEventHandler")
*JAL*				ELSE
*JAL*					BINDEVENT(thWnd,tnMessage,this,"OnEventHandler",tnFlags)
*JAL*				ENDIF
*JAL*			ENDIF
*JAL*			RETURN lcKey
	ENDPROC

	
	PROCEDURE Init
		IF this.bDebug
			this.hdlDebug = FCREATE("GKKWin32EventHandler.log",0)
		ENDIF
	ENDPROC


	PROCEDURE Destroy
		IF this.bDebug
			=FCLOSE(this.hdlDebug)
			this.hdlDebug = -1
		ENDIF
	ENDPROC


	* Unbind Win events. Supports all UnBindEvents interfaces
	Procedure UnBindEvents
		LPARAMETERS thWnd, tnMessage, toEventHandler, tcDelegate
		Local lcKey, loWinEvent as WinEvent of VFPxWin32EventHandler.prg, lnItem
		DO CASE
		CASE Pcount() = 1
			* UNBINDEVENTS(oEventObject) 
			* Unbinds all events associated with this object. This includes events that are bound 
			*	to it as an event source and its delegate methods that serve as event handlers.
			UnBindEvents(thWnd)
		CASE Pcount() = 4
			If !Empty(tnMessage)
				* Unbind specific event/message
				lcKey = Transform(thWnd) + "~" + Transform(tnMessage)
				If This.GetKey(lcKey) <> 0
					loWinEvent = This.Item(lcKey)
					UnBindEvents(loWinEvent, "EventFired", toEventHandler, tcDelegate)
				EndIf 
			Else
				* Unbind all messages for hWnd and delegate
				FOR lnItem = 1 to This.Count
					loWinEvent = This.Item(lnItem)
					If loWinEvent.hWnd = thWnd
						UnBindEvents(loWinEvent, "EventFired", toEventHandler, tcDelegate)
					EndIf 
				ENDFOR
			EndIf 
		Otherwise
			Assert .f. Message "UnBindEvents requires 1 or 4 parameters. Syntax: " + Chr(13) + Chr(13) + ;
				"UnBindEvents(oEventObject)" + Chr(13) + "UnBindEvents(thWnd, tnMessage, toEventHandler, tcDelegate)"
		ENDCASE

		This.CleanupEvents()

	EndProc 

	* Check all events and remove any objects that are no longer used
	Procedure CleanupEvents
		Local array laObjEvents[1,5], laWinEvents[1,4]
		Local lnItem, loWinEvent as WinEvent of VFPxWin32EventHandler.prg, lnRow, llEventFound
		
		* Array of current Win event bindings
		AEvents(laWinEvents, 1)

		* For loops don't work well when removing items from collection
		lnItem = 1
		Do While lnItem <= This.Count

			llEventFound = .f.
			loWinEvent = This.Item(lnItem)
			
			* Check if there are any bindings for this Win event
			For lnRow = 1 to Alen(laWinEvents, 1)
				If laWinEvents[lnRow,1] = loWinEvent.hWnd and laWinEvents[lnRow,2] = loWinEvent.nMessage
					llEventFound = .t.
					Exit 
				EndIf 
			EndFor 
			* No Win events for this object, so remove
			If !llEventFound
				This.Remove(lnItem)
				Loop
			EndIf 
			
			* If no bindings to this object, remove
			If AEvents(laObjEvents, This.Item(lnItem)) = 0
				This.Remove(lnItem)
				Loop
			EndIf 
			
			lnItem = lnItem + 1 
			
		EndDo 

	EndProc 
	
*JAL*		PROCEDURE UnBindEvents
*JAL*			LPARAMETERS pcKey
*JAL*			LOCAL lnNdx, lbRemove
*JAL*			lnNdx = this.GetKey(pcKey)
*JAL*			IF lnNdx > 0
*JAL*	*-*			Remove this handler from the collection
*JAL*				lhWnd     = this.Item[lnNdx].hWnd
*JAL*				lnMessage = this.Item[lnNdx].nMessage
*JAL*				this.Remove(lnNdx)
*JAL*	*-*			Check to see if any other handler still requesting binding to event; unbind if not
*JAL*				lbRemove = .T.
*JAL*				FOR lnNdx=1 TO this.Count
*JAL*					IF this.Item[lnNdx].hWnd = lhWnd .AND. this.Item[lnNdx].nMessage = lnMessage
*JAL*						lbRemove = .F.
*JAL*						EXIT
*JAL*					ENDIF
*JAL*				ENDFOR
*JAL*				IF lbRemove
*JAL*					UNBINDEVENTS(lhWnd,lnMessage)
*JAL*				ENDIF
*JAL*			ENDIF
*JAL*		ENDPROC


*JAL*		PROCEDURE OnEventHandler
*JAL*			LPARAMETERS thWnd, tnMessage, twParam, tnParam
*JAL*			LOCAL loHandler, lnNdx, lcMethod
*JAL*			IF this.bDebug
*JAL*				=FPUTS(this.hdlDebug,"OnEventHandler - hWnd: "+TRANSFORM(thWnd) + " nMsg: "+TRANSFORM(tnMessage))
*JAL*			ENDIF
*JAL*			FOR lnNdx=this.Count TO 1 STEP -1
*JAL*				loHandler = this.Item[lnNdx]
*JAL*				IF INLIST(loHandler.hWnd,0,thWnd) .AND. loHandler.nMessage = tnMessage
*JAL*					IF VARTYPE(loHandler.oEventHandler) = "O" .AND. !ISNULL(loHandler.oEventHandler)
*JAL*						IF this.bDebug
*JAL*							=FPUTS(this.hdlDebug,"EventPassed - hWnd: "+TRANSFORM(thWnd) + " nMsg: "+TRANSFORM(tnMessage))
*JAL*						ENDIF
*JAL*						lcMethod = loHandler.cDelegate
*JAL*						loHandler.oEventHandler.&lcMethod(thWnd, tnMessage, twParam, tnParam)
*JAL*					ELSE
*JAL*						this.Remove(lnNdx)
*JAL*					ENDIF
*JAL*				ENDIF
*JAL*			ENDFOR
*JAL*		ENDPROC
EndDefine

DEFINE CLASS WinEvent AS Custom

	hWnd = 0
	nMessage = 0

	PROCEDURE EventFired
		LPARAMETERS thWnd, tnMessage, twParam, tnParam
		* Bind events to this method
	ENDPROC

ENDDEFINE

#INCLUDE vfpalert.h

LOCAL oMgr, loAlert

** Create the AlertManager
oMgr = CREATEOBJECT("vfpalert.AlertManager")

** Create an event handler for the alert
x=CREATEOBJECT("MyCallback")

** Create a new alert
loAlert = oMgr.NewAlert()

** SetCallback() 
loAlert.SetCallback(x)

** Launch the first alert form
loAlert.Alert("This is a test of the alert system.",64,"First Alert")

ACTIVATE SCREEN

** Just for demonstration purposes, 'hang' the system 
** long enough to see the results.
WAIT WINDOW "" TIMEOUT 20

DEFINE CLASS MyCallback AS Custom
	PROCEDURE AlertResult(tnResult) 
		?("You selected: " + TRANSFORM(tnresult) + " using AlertResult() in a normal Custom class")
	ENDPROC
ENDDEFINE


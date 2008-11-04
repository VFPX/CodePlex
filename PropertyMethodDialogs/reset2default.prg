********************************************************************
*** Name.....: Reset2Default
*** Author...: Marcia G. Akins
*** Date.....: 05/13/2007
*** Notice...: Copyright (c) 2007 Tightline Computers, Inc
*** Compiler.: Visual FoxPro 09.00.0000.3504 for Windows 
*** Function.: Call the resetToDefault method of all the selected objects
*** Returns..: Logical
********************************************************************
LPARAMETERS toObject, tcPEM
LOCAL lnSelected, laSelected[ 1 ], lnI

*** Issue a resetToDefault() for all the selected objects
lnSelected = ASELOBJ( laSelected )
IF lnSelected > 0
  FOR lnI = 1 TO lnSelected 
    laSelected[ lnI ].ResetToDefault( tcPEM )
  ENDFOR 
ELSE 
  toObject.ResetToDefault( tcPEM )  
ENDIF 

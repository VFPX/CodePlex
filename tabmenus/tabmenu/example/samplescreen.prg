SET PATH TO u:\devsource\tabmenu\images\;u:\devsource\tabmenu\example\
SET CLASSLIB TO "tabmenu.vcx", "example.vcx"

_SCREEN.Caption = "Visual FoxPro User Interface Test"

DO screen.mpr

READ EVENTS

CLEAR ALL

RETURN
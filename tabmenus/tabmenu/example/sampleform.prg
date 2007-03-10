SET PATH TO u:\devsource\tabmenu\images\;u:\devsource\tabmenu\example\
SET CLASSLIB TO "tabmenu.vcx", "example.vcx"

RELEASE goForm
PUBLIC goForm AS Form 

DO FORM mainform NAME goForm
goForm.Caption = "Visual FoxPro User Interface Test"

DO menuform.mpr

READ EVENTS

RELEASE goForm
CLEAR ALL

RETURN
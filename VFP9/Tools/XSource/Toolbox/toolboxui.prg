#include "foxpro.h"

* used to define custom grid columns & headers
* for the Toolbox components
DEFINE CLASS ComponentColumn AS Column
	FontName = "Tahoma"
	FontSize = 8
	CurrentControl = "ColumnTextBox"
	
	HeaderClass = "ComponentHeader"
	HeaderClassLibrary = "ToolboxUI.prg"
	
	ADD OBJECT ColumnTextBox AS Textbox WITH ;
	  FontName = "Tahoma", ;
	  FontSize = 8, ;
	  BorderStyle = BORDER_NONE
	
	PROCEDURE ColumnTextbox.RightClick
		THISFORM.ShowGridMenu()	
	ENDPROC
ENDDEFINE

DEFINE CLASS ComponentHeader AS Header
	FontName = "Tahoma"
	FontSize = 8
ENDDEFINE

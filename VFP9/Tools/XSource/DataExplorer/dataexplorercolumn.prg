* Defines the column class to use in for the
* grid in the RunQuery form
DEFINE CLASS CQueryColumn AS Column

	PROCEDURE Init()
		THIS.FontName   = THIS.Parent.FontName
		THIS.FontSize   = THIS.Parent.FontSize
		THIS.FontBold   = THIS.Parent.FontBold
		THIS.FontItalic = THIS.Parent.FontItalic
		THIS.ReadOnly   = THIS.Parent.ReadOnly
	ENDPROC
	

	ADD OBJECT CQueryTextbox AS CQueryTextBox WITH ;
	 Name = "QueryTextbox", ;
	 FontName = THIS.FontName, ;
	 FontSize = THIS.FontSize, ;
	 FontBold = THIS.FontBold, ;
	 FontItalic = THIS.FontItalic
	
	CurrentControl = "QueryTextbox"
ENDDEFINE

DEFINE CLASS CQueryTextbox AS TextBox
	PROTECTED PROCEDURE ShowBrowseWindow()
		IF THIS.Parent.ReadOnly
			MODIFY MEMO (THIS.ControlSource) IN MACDESKTOP NOEDIT
		ELSE
			MODIFY MEMO (THIS.ControlSource) IN WINDOW (THISFORM.Name)
		ENDIF
	ENDPROC

	PROCEDURE DblClick()
		IF INLIST(TYPE(THIS.ControlSource), 'M', 'G', 'W')
			THIS.ShowBrowseWindow()
			NODEFAULT
		ENDIF
	ENDPROC

	PROCEDURE KeyPress(nKeyCode, nShiftAltCtrl)
		* ctrl+pgdn or ctrl+home
		IF ((nKeyCode == 30 AND nShiftAltCtrl == 2) OR (nKeyCode == 29 AND nShiftAltCtrl == 2)) AND ;
		 INLIST(TYPE(THIS.ControlSource), 'M', 'G', 'W')
			THIS.ShowBrowseWindow()
			NODEFAULT
		ENDIF
	ENDPROC

ENDDEFINE

* Class definition for columns added to grids in builders. This gives columns
* added via the AddColumn method a common set of methods, e.g. to trap resizing.

#DEFINE C_SANSSERIF_LOC		"MS Sans Serif"

DEFINE CLASS wbGrid AS GRID
	Name = "Grid1"
	Height = 135
	Width = 412
	RecordMark = .f.
	DeleteMark = .f.
	Highlight = .f.
	Gridlines = 2
	Scrollbars = 3
	*- Backcolor = RGB(192,192,192)
	HeaderHeight = 19
	BuilderSource = ""
	
	
	PROCEDURE INIT
		PARAMETERS DSType, DS, BldrSource, numcols

		* THIS.RecordSourcetype = DSType
		THIS.RecordSource = DS
		THIS.BuilderSource = IIF(TYPE("BldrSource") = "C", UPPER(BldrSource), "")
		numcols = IIF(TYPE("numcols") = "N", numcols, 0)
		
		THIS.ColumnCount = 0
		PRIVATE m.wbi, m.thiscol
		
		FOR m.wbi = 1 TO numcols
			m.thiscol = "Column" + LTRIM(STR(m.wbi))
			THIS.AddObject(m.thiscol,"wbCol")				&& add the column
			
			THIS.&thiscol..Text1.FontBold = .f.
			
			* wbaCols[,5] and [,6] record current control name and type - add it if other than textbox and if it's one
			* of our supported control types. Page 3 activate will set CurrentControl to this object.
			
			IF THIS.BuilderSource = "GRID" AND TYPE("wbaCols[m.wbi,5]") = "C" AND TYPE("wbaCols[m.wbi,6]") = "C"
				IF "." + LOWER(wbaCols[m.wbi,6]) + "." $ ".editbox.spinner.checkbox.oleboundcontrol."
					THIS.&thiscol..AddObject(wbaCols[m.wbi,5],wbaCols[m.wbi,6])
				ENDIF
			ENDIF
		ENDFOR
				
	ENDPROC

	PROCEDURE SetListWidths
		PRIVATE m.cWidths, m.iWidth, m.widthnum, m.ipad, m.wbi
		
		m.cWidths = ""
		m.iWidth = 0

		FOR m.wbi = 1 TO THISFORMSET.wbiColumns
			m.widthnum = wbaCols[m.wbi, 1] / THISFORMSET.GridMetric			&& number of chars of data in p.3 grid
			m.cWidths = m.cWidths + LTRIM(STR(m.widthnum)) + ","
			m.iWidth = m.iWidth + m.widthnum
		ENDFOR
		IF RIGHT(m.cWidths, 1) = ","
			m.cWidths = LEFT(m.cWidths, LEN(m.cWidths) - 1)
		ENDIF

		THISFORMSET.SetWidthString(m.cWidths)
		IF THIS.PARENT.wizcheckbox1.Value = 1
			THISFORMSET.SetControlWidth(m.iWidth)
		ENDIF
	ENDPROC
	

	PROCEDURE SetGridWidths
		PRIVATE m.thiscol, m.iWidth, m.wbi

		FOR m.wbi = 1 TO ALEN(wbaCols,1)
			m.thiscol = wbaCols[m.wbi,7]		&& control's real column name
			m.bldrchars = wbaCols[m.wbi, 1] / THISFORMSET.BldrMetric
			m.widthnum = THISFORMSET.SetColWidth(m.bldrchars,wbaControl[1].&thiscol)
			wbaControl[1].&thiscol..Width = m.widthnum
		ENDFOR
	ENDPROC
	

	PROCEDURE AfterRowcolChange
		PARAMETER ColIndex

		IF THIS.BuilderSource = "GRID" AND NOT THISFORMSET.KeepColumn
		
			THISFORMSET.ActiveCol = ALLTRIM(THIS.Columns[m.ColIndex].Name)
			THISFORMSET.ActiveColNum = m.ColIndex
			m.currctrl = THIS.Columns[m.ColIndex].CurrentControl
			IF NOT EMPTY(m.currctrl)
				m.currtype = THIS.Columns[m.ColIndex].&currctrl..baseclass
			ELSE
				m.currtype = "textbox"
			ENDIF
			
			THIS.PARENT.Wiztextbox1.Value = wbaCols[m.ColIndex,3]
			THIS.PARENT.Wiztextbox1.Refresh
			
			* Make combobox of control types appropriate for this column 
			m.setctrl = IIF(LOWER(m.currctrl) = wbaCols[m.ColIndex,10], wbaCols[m.ColIndex,11], m.currctrl)
			m.fldtype = wbaCols[m.ColIndex,4]
			m.newindex = THISFORMSET.SetControls(m.fldtype, m.setctrl)
			m.newrows = ""
			m.nCtrls = ALEN(THISFORMSET.wbaCtrlShow,1)
			FOR m.wbi = 1 TO m.nCtrls
				m.newrows = m.newrows + THISFORMSET.wbaCtrlShow[m.wbi,1] + ","
			ENDFOR
			IF RIGHT(m.newrows,1) = ","
				m.newrows = LEFT(m.newrows,LEN(m.newrows)-1)
			ENDIF
			WITH THIS.PARENT.Wizcombobox1
				.RowSource = LEFT(m.newrows,240)
				.NumberOfElements = m.nCtrls
				.Listindex = m.newindex
			ENDWITH
		ENDIF		

	ENDPROC
	
	PROCEDURE ERROR

		PARAMETERS nError, cMethod, nLine

		PRIVATE oTopmost, m.msg

		m.msg = MESSAGE()

		m.oTopmost = THIS

		DO WHILE TYPE('m.oTopmost.Parent') = 'O'
			m.oTopmost = m.oTopmost.Parent
		ENDDO

		oTopmost.Error(m.nError, m.cMethod, m.nLine, m.msg)

		IF THISFORMSET.lRetry
			RETRY
		ENDIF
	
	ENDPROC

ENDDEFINE


DEFINE CLASS wbCol AS COLUMN
	Width = m.wbiDefWidth
	FontName = C_SANSSERIF_LOC
	FontSize = 8
	FontBold = .f.
	Movable = .f.
	
	ADD OBJECT HEADER1 AS wbHeader
	
	PROCEDURE WHEN
		RETURN .f.
	ENDPROC

	PROCEDURE Resize
		* Column number involved maps into THISFORMSET.wbFieldmap, a bitmap of fields used to 
		* construct column-width string. wbaCols[] array reflects all fields in widths string.

		PRIVATE m.wbcThiscol, m.wbiColnum

		m.wbiColnum = THIS.ColumnOrder
		
		IF m.wbiColnum > 0
			wbaCols[m.wbiColnum,1] = THIS.Width
			IF UPPER(ALLTRIM(wbaControl[1].BaseClass)) $ "LISTBOX.COMBOBOX"
				THIS.Parent.SetListWidths
			ENDIF
			IF UPPER(ALLTRIM(wbaControl[1].BaseClass)) == "GRID"
				THIS.Parent.SetGridWidths
			ENDIF
		ENDIF
	ENDPROC
	
	PROCEDURE ERROR

		PARAMETERS nError, cMethod, nLine

		PRIVATE oTopmost, m.msg

		m.msg = MESSAGE()

		m.oTopmost = THIS

		DO WHILE TYPE('m.oTopmost.Parent') = 'O'
			m.oTopmost = m.oTopmost.Parent
		ENDDO

		oTopmost.Error(m.nError, m.cMethod, m.nLine, m.msg)

		IF THISFORMSET.lRetry
			RETRY
		ENDIF
	
	ENDPROC

ENDDEFINE
		
DEFINE CLASS wbHeader AS HEADER
	FontName = C_SANSSERIF_LOC
	FontSize = 8
	Caption = " "
	Alignment = 2

	PROCEDURE Click
	* Click event for header, for grid builder

		oPRef = THIS.PARENT.PARENT
		IF oPRef.BuilderSource = "GRID"
			m.newcol = ALLTRIM(THIS.PARENT.Name)
			m.newcolnum = VAL(STRTRAN(UPPER(m.newcol),"COLUMN"))
			m.currentrow = oPRef.ActiveRow
			oPRef.ActivateCell(m.currentrow,m.newcolnum)	&& triggers grid's AfterRowColChange method
		ENDIF
	
	ENDPROC
	
	PROCEDURE ERROR

		PARAMETERS nError, cMethod, nLine

		PRIVATE oTopmost, m.msg

		m.msg = MESSAGE()

		m.oTopmost = THIS

		DO WHILE TYPE('m.oTopmost.Parent') = 'O'
			m.oTopmost = m.oTopmost.Parent
		ENDDO

		oTopmost.Error(m.nError, m.cMethod, m.nLine, m.msg)

		IF THISFORMSET.lRetry
			RETRY
		ENDIF
	
	ENDPROC

	PROCEDURE DBLCLICK
		IF THIS.PARENT.PARENT.BuilderSource = "LIST"
			PRIVATE m.wbiVisCount, m.wbi, m.wbithiscol, m.wbiColnum
			IF THISFORMSET.wbiColumns = 1					&& don't allow hide of only column
				RETURN
			ENDIF
			m.wbiVisCount = 0
			FOR m.wbi = 1 TO THISFORMSET.wbiColumns
				IF wbaCols[m.wbi, 1] > 0
					m.wbiVisCount = m.wbiVisCount + 1
				ENDIF
			ENDFOR
			
			* Column number clicked on maps into THISFORMSET.wbFieldmap, a bitmap of fields used to 
			* construct column-width string. wbaCols[] array reflects all fields in widths string.
			
			m.wbcThiscol = THIS.Parent.Name			
			m.wbiColnum = THIS.PARENT.ColumnOrder
			m.wblHideAction = wbaCols[m.wbiColnum,1] > 0	&& .T. if hiding, .F. if unhiding
			
			IF m.wbiVisCount = 1 AND m.wblHideAction				&& don't allow hide of only remaining visible column
				RETURN
			ENDIF

			* OK to hide this column	
			WITH THIS.PARENT	
				wbaCols[m.wbiColnum,1] = IIF(m.wblHideAction, 0, .Width)
				IF .PARENT.BuilderSource = "GRID"
					.Parent.SetGridWidths
				ELSE
					.Parent.SetListWidths
				ENDIF
				IF wbaCols[m.wbiColnum,1] = 0
					.Backcolor = RGB(192,192,192)
				ELSE
					IF NOT EMPTY(THISFORMSET.wbaFonts[1,5])
						.BackColor = THISFORMSET.wbaFonts[1,5]
					ELSE
						.BackColor = RGB(255,255,255)
					ENDIF
				ENDIF
			ENDWITH
		ENDIF
		THIS.PARENT.Enabled = THIS.PARENT.Enabled
		
	ENDPROC
	
ENDDEFINE
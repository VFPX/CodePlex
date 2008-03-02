#define NROWS 15		&&  # of cell rows,cols. The Windows version limits to 24 X 30
#define NCOLS 15		&&	Try (50 X 50, .1) to see interesting paint patterns
#define NMINESFRACT .15	&& Fraction of minefield that has mines (between 0  and 1)
#define NCELLHEIGHT 16
#define NCELLWIDTH  16
#define BCOLOR RGB(255,255,192)
#define BOMB -1
#define GRIDOFFSET	75

PUBLIC oMine
oMine=NEWOBJECT("mines")
DEFINE CLASS mines AS PaneContainer OF FoxPane
	nTotMines = 0		&& total # of actual mines
	nTotRevealed = 0	&& Total # of cells revealed
	nBombsLeft = 0		&& nTotMines - # marked as bombs by user
	nTime = 0			&& elapsed time
	nGameStat = 0		&& 0 means play, 1 means lost, 2 means won
	ShowTips = .T.
	nTotalRows = 0
	nTotalCols = 0
	nCellRows = 15
	nCellCols = 15
	cPath = '' && ALLTRIM(ADDBS(JUSTPATH(SYS(16))))

	Showwindow = 2		&& TopLevel form. 
	DIMENSION amines[1]	&& the mine array
	ADD OBJECT mytimer AS timer WITH interval = 1000
	ADD OBJECT cmdReplay AS CommandButton WITH height=25,width=70,left=15,ToolTipText="Replay Game",caption="\<Replay"
	ADD OBJECT cmdRules as Commandbutton WITH Left=90,Caption="R\<ules",Height=25,width=50
	ADD OBJECT lblTime as label WITH left=90,backcolor=BCOLOR,caption="0",ToolTipText="Elapsed Time",Top=70,FontBold=.T.
	ADD OBJECT lblBombs as label WITH left=190,backcolor=BCOLOR,caption="0",ToolTipText="Number of Mines",Top=70,FontBold=.T.
	ADD OBJECT shpWhite as Shape WITH Top=0,Left=-1,backcolor=RGB(255,255,255),Height=65,BorderColor=RGB(128,128,128)
	ADD OBJECT shpHeader as Shape WITH Top=0,Left=1,backcolor=RGB(128,128,128),Height=26,BorderStyle=0
	ADD OBJECT imgHeader as Image WITH Top=0,Height=26
	ADD OBJECT lblMines as label WITH Top=1,Left=2,Caption="Minesweeper Game",FontName="Verdana",FontBold=.T.,FontSize=14,BackStyle=0,AutoSize=.T.,ForeColor=RGB(255,255,255)
	ADD OBJECT lblTimeCap as label WITH left=15,backstyle=0,caption="Time (s):",Top=70,AutoSize=.T.
	ADD OBJECT lblBombsCap as label WITH left=140,backstyle=0,caption="Mines:",Top=70,AutoSize=.T.
	ADD OBJECT lblHelp as label WITH Top=28,Left=2,Height=20,Caption="This is a Visual FoxPro version of the classic Minesweeper game.",FontName="Verdana",FontSize=10,BackStyle=0,AutoSize=.T.,wordwrap=.T.
	
	PROCEDURE Init
		RAND(1)	&& Uncomment this for static random sequence
		this.BackColor= BCOLOR
		this.Top = (SYSMETRIC(2) - this.Height)/2
		this.Left = (SYSMETRIC(1) - this.Width)/2
	
		*THIS.cPath = SET("DEFAULT") + CURDIR()
	ENDPROC
	

	
	PROCEDURE OnRender(oPane, oContent)
		this.nCellRows = oContent.GetOption("size", NROWS)
		this.nCellCols = this.nCellRows		
		THIS.cPath = oPane.CacheDir 

		This.imgHeader.Picture=this.cPath+"mineend.bmp"
		This.ResizeHeader()
		
		This.cmdReplay.picture=this.cPath+"miner.bmp"
		This.cmdReplay.picturePosition=0
				
		this.Shuffle()
		
		This.cmdReplay.Top = GRIDOFFSET + (This.nCellRows * NCELLHEIGHT) + 20
		This.cmdRules.Top = GRIDOFFSET + (This.nCellRows * NCELLHEIGHT) + 20
	ENDPROC
	
	PROCEDURE OnResize()
		This.ResizeHeader()		
	ENDPROC

	PROCEDURE ResizeHeader()
		This.Width = MAX(This.Width,315)
		This.lblHelp.Width = This.Width-5
		This.shpWhite.Width=This.Width+5
		This.shpHeader.Width=This.Width-This.imgHeader.Width+5
		This.imgHeader.Width=92
		This.imgHeader.Left=This.Width-This.imgHeader.Width-1
	ENDPROC

	PROCEDURE InitMines(nTotalRows, nTotalCols)
		FOR m.i = THIS.ControlCount TO 1 STEP -1
			IF THIS.Controls(m.i).Tag == '!'
				cObjName = THIS.Controls(m.i).name
				THIS.RemoveObject(cObjName)
			ENDIF
		ENDFOR

		THIS.nTotalRows = nTotalRows
		THIS.nTotalCols = nTotalCols
	
		* this.Width = 40 + THIS.nTotalCols * NCELLWIDTH
		* this.height = 50 + THIS.nTotalRows * NCELLHEIGHT

		DIMENSION this.aMines[nTotalRows,nTotalCols]
		
		
		FOR iRow = 1 TO nTotalRows
			FOR jCol =  1 to nTotalCols
				this.AddObject("this.aMines["+TRANSFORM(iRow)+","+TRANSFORM(jCol)+"]","Cell",iRow,jCol)
				oCell = this.aMines[iRow,jCol]
				oCell.Left = jCol * NCELLWIDTH
				oCell.Top = GRIDOFFSET + iRow * NCELLHEIGHT
				oCell.visible=1
				oCell.Tag = '!'
			ENDFOR
		ENDFOR
	ENDPROC

	PROCEDURE Shuffle
		LOCAL iRow,jCol,oCell

		THISFORM.LockScreen = .T.

		THIS.InitMines(THIS.nCellRows, THIS.nCellCols)

		this.nGameStat = 0
		this.nTotMines = 0
		this.nTotRevealed = 0
		FOR EACH oCell IN this.aMines
			IF RAND() < NMINESFRACT
				oCell.nNeighbors = BOMB
				this.nTotMines = this.nTotMines+1
			ELSE
				oCell.nNeighbors = 0
			ENDIF
			oCell.nRevealed = 0
			oCell.Picture=this.cPath+"minex.bmp"	&& unrevealed square
		ENDFOR
		this.nBombsLeft = this.nTotMines
		this.lblBombs.caption =  TRANSFORM(this.nBombsLeft)
		FOR EACH oCell IN this.aMines
			IF oCell.nNeighbors != BOMB		&& if we are not a bomb, count neighboring bombs
				oCell.CalcCount
			ENDIF
		ENDFOR	
		DO WHILE .t.	&& this loop just gives the user a starting hint
			nRand =1 + INT(RAND() * THIS.nCellRows * THIS.nCellCols)
			IF this.aMines[nrand].nNeighbors = 0	&& if not a bomb & not surrounded	
				this.aMines[nrand].Click			&& reveal it
				EXIT
			ENDIF
		ENDDO 
		this.nTime = 0
		this.lblTime.caption="0"
		THIS.myTimer.Enabled = .T.

		THISFORM.LockScreen = .F.

	PROCEDURE click	&& The form click, just reset the game if it's over
		IF this.nGameStat != 0
			this.Shuffle()
		ENDIF
	PROCEDURE cmdReplay.click
		this.parent.Shuffle()	
	PROCEDURE cmdRules.click
		MODIFY FILE this.parent.cPath+"rules.txt" NOEDIT NOWAIT	
	PROCEDURE ShowAll()	&& at end of game
		LOCAL oCell

		THIS.myTimer.Enabled = .F.
		FOR EACH oCell IN this.aMines
			oCell.Click
		ENDFOR 
	

	#define ROWBASE 10000
	PROCEDURE BlankClick(iRow,jCol)	&& User clicked on a blank cell. Let's area fill
		LOCAL iRow, jCol,num, dRow,dCol,oCell, oCollect as Collection
		oCollect=NEWOBJECT("collection")	&& Let's use collection to avoid deep recursion levels
		oCollect.Add(iRow * ROWBASE + jCol)	&& row 23, col 34 --> 230034
		DO WHILE oCollect.Count > 0
			num = oCollect.Item(1)		&& get the first number in the collection
			oCollect.Remove(1)			&& remove it
			iRow = INT(num/ROWBASE)
			jCol = MOD(num,ROWBASE)
			oCell = this.aMines[iRow,jCol]
			IF oCell.nRevealed != 0	&& if it's already revealed, do nothing
				LOOP
			ENDIF 
			IF oCell.nNeighbors = 0	&& this is an empty cell
				oCell.nRevealed = 1
				oCell.picture = this.cPath+"mine0.bmp"	&& revealed sq with 0 bombs around it
				this.nTotRevealed = this.nTotRevealed+1
				FOR dRow = -1 TO 1		&& now examine the neighbors
					FOR dCol =  -1 to 1
						IF (dCol != 0 OR dRow != 0)
							IF BETWEEN(iRow + dRow,1,THIS.nCellRows) AND ;
								BETWEEN(jCol + dCol,1,THIS.nCellCols)
								oCollect.Add((iRow+dRow) * ROWBASE + jCol+dCol)
							ENDIF
						ENDIF
					ENDFOR
				ENDFOR
			ELSE
				oCell.Click	&& non-empty cell. Just click it
			ENDIF 
		ENDDO 
	PROCEDURE mytimer.timer
		IF this.parent.nGameStat = 0	&& game still going?
			this.parent.nTime = this.parent.nTime+1
			this.parent.lblTime.Caption = TRANSFORM(this.parent.nTime)
		ENDIF
ENDDEFINE

DEFINE CLASS cell as Image
	nRevealed = 0	&& 0 = not shown, 1 = shown, 2 =user thinks bomb, 3 = user thinks ?
	nNeighbors = 0	&& # of neighbors that are mines. If -1, then i am a mine
	iRow = 0	&& where am i
	jCol = 0
	PROCEDURE init(iRow,jCol)
		this.iRow = iRow
		this.jCol = jCol
	PROCEDURE RightClick
		DO case
		CASE this.nRevealed = 0	&& if it hasn't been revealed, change to a Bomb
			this.Picture=this.parent.cPath+"mineflag.bmp"
			this.nRevealed = 2	&& set to "user thinks it's a bomb"
			this.parent.nBombsLeft = this.parent.nBombsLeft-1
			this.parent.lblBombs.caption =  TRANSFORM(this.parent.nBombsLeft)
		CASE this.nRevealed = 2	&& if it was a bomb, change to a "?"
			this.nRevealed = 3
			this.Picture=this.parent.cPath+"mineq.bmp"
			this.parent.nBombsLeft = this.parent.nBombsLeft+1
			this.parent.lblBombs.caption =  TRANSFORM(this.parent.nBombsLeft)
		CASE this.nRevealed = 3	&& user marked as a "?"
			this.nRevealed = 0
			this.Picture=this.parent.cPath+"minex.bmp"
		ENDCASE
	PROCEDURE Click
		IF this.nRevealed = 0
			IF this.nNeighbors = 0	&&AND this.parent.nGameStat = 0 && clicked on a blank spot. Lets do an area fill
				this.parent.BlankClick(this.iRow, this.jCol)
				return
			ENDIF
			this.nRevealed = 1
			DO CASE 
			CASE this.nNeighbors = BOMB	&&it's a Bomb: end game
				DO CASE 
				CASE this.parent.nGameStat = 0	&& game was in progress
					this.Picture=this.parent.cPath+"mineboom.bmp"
					this.parent.nGameStat = 1	&& lost
					this.parent.ShowAll
				CASE this.parent.nGameStat = 1	&& lost
					this.Picture=this.parent.cPath+"mineb.bmp"
				CASE this.parent.nGameStat = 2	&& won
					this.Picture=this.parent.cPath+"mineflag.bmp"
				ENDCASE
			OTHERWISE
				this.parent.nTotRevealed = this.parent.nTotRevealed+1
				this.Picture=this.parent.cPath+"mine"+TRANSFORM(this.nNeighbors)+".bmp"				
				IF this.parent.nGameStat = 0
					IF this.parent.nTotRevealed = THIS.Parent.nTotalRows * THIS.Parent.nTotalCols - this.parent.nTotMines
						this.parent.nGameStat = 2	&& won
						this.parent.ShowAll
						MESSAGEBOX("Winner")
					ENDIF
				ENDIF
			ENDCASE
		ENDIF
	PROCEDURE CalcCount	&& Calculate how many neighbors are bombs
		LOCAL iRow, jCol,dRow,dCol	&& now examine the neighbors
		FOR dRow = -1 TO 1
			FOR dCol =  -1 to 1
				IF (dCol != 0 OR dRow != 0)
					iRow = this.iRow + dRow
					jCol = this.jCol + dCol
					IF BETWEEN(iRow,1,THIS.parent.nTotalRows) AND BETWEEN(jCol,1,THIS.parent.nTotalCols) AND ;
							 this.parent.aMines[iRow,jCol].nNeighbors = BOMB
						this.nNeighbors = this.nNeighbors + 1
					ENDIF
				ENDIF 
			ENDFOR
		ENDFOR
ENDDEFINE

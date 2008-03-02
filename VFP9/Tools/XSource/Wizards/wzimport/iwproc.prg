#include "foxpro.h" && v-darylm
*#include "c:\vfp\foxpro.h"
#include "import.h"

define class ImportEngine as WizEngineAll
	iHelpContextID = 1996825410	&& 1895825415
	* Page 1 controls
	* cSourceFile is the file to import
	cSourceFile = ''
	* aFileTypes are the choices in the dropdown list
	* The second column is the TYPE keyword for the IMPORT command
	* The third column is the extension to offer in the GetFile() dialog (i.e.,
	* the actual default extension of the filename)
	dimension aFileTypes[11, 3]
	aFileTypes[1, 1] = FTTEXT_LOC
	aFileTypes[1, 2] = 'txt'
	aFileTypes[1, 3] = 'txt'
	aFileTypes[2, 1] = FTEXCEL5_LOC
	aFileTypes[2, 2] = 'xl8'
	aFileTypes[2, 3] = 'xls'
	aFileTypes[3, 1] = FTEXCEL_LOC
	aFileTypes[3, 2] = 'xls'
	aFileTypes[3, 3] = 'xls'
	aFileTypes[4, 1] = FTLOTUS3_LOC
	aFileTypes[4, 2] = 'wk3'
	aFileTypes[4, 3] = 'wk3'
	aFileTypes[5, 1] = FTLOTUS2_LOC
	aFileTypes[5, 2] = 'wk1'
	aFileTypes[5, 3] = 'wk1'
	aFileTypes[6, 1] = FTLOTUS1_LOC
	aFileTypes[6, 2] = 'wks'
	aFileTypes[6, 3] = 'wks'
	aFileTypes[7, 1] = FTPARADOX_LOC
	aFileTypes[7, 2] = 'pdox'
	aFileTypes[7, 3] = 'db'
	aFileTypes[8, 1] = FTSYMPHONY110_LOC
	aFileTypes[8, 2] = 'wr1'
	aFileTypes[8, 3] = 'wr1'
	aFileTypes[9, 1] = FTSYMPHONY101_LOC
	aFileTypes[9, 2] = 'wrk'
	aFileTypes[9, 3] = 'wrk'
	aFileTypes[10, 1] = FTMULTIPLAN_LOC
	aFileTypes[10, 2] = 'mod'
	aFileTypes[10, 3] = 'mod'
	aFileTypes[11, 1] = FTRAPIDFILE_LOC
	aFileTypes[11, 2] = 'rpd'
	aFileTypes[11, 3] = 'rpd'
	
	* iFileType is the selected file type in the dropdown list
	iFileType = 1
	iOldFileType = 0

	* iOutputMode is either Create a new table or Append to existing file
	iOutputMode = 1 && Create a new table
	* cOutputFile is the name of the file to create
	cOutputFile = ''
	* cAppendFile is the name of the (existing) file to append to
	cAppendFile = ''

	* These properties are used for fixed-length text files
	
	* aRecord is an array of records from the sample cursor--these records
	* are displayed in the fixed width scrolling region
	dimension aRecord[5]
	aRecord = ''
	* iRecord is the recno() corresponding to the record stored in aRecord[1]
	iRecord = 0
	* iRulerNotch is the ruler notch currently displayed
	iRulerNotch = 0
	* iValue is the column currently positioned in column 1
	iValue = 0
	iShapeCount = 1
	
	* Page 3 controls
	dimension aStruct[1, 7]
	
	*** NOTE *** NOTE *** NOTE ************************************************
	* The field type descriptions are enabled/disabled in PROC EnableFieldTypes
	* Changes made here need to be made there, too.
	***************************************************************************
	dimension aFieldTypes[12, 7]
	aFieldTypes[1,1] = FTCHARACTER_LOC
	aFieldTypes[1,2] = 1		&& minimum column width
	aFieldTypes[1,3] = 254		&& maximum column width
	aFieldTypes[1,4] = 0		&& minimum decimals width
	aFieldTypes[1,5] = 0		&& maximum decimals width
	aFieldTypes[1,6] = 'C'
	aFieldTypes[1,7] = .F.		&& codepage translation?
	aFieldTypes[2,1] = FTCURRENCY_LOC
	aFieldTypes[2,2] = 8
	aFieldTypes[2,3] = 8
	aFieldTypes[2,4] = 0
	aFieldTypes[2,5] = 0
	aFieldTypes[2,6] = 'Y'
	aFieldTypes[2,7] = .F.
	aFieldTypes[3,1] = FTNUMERIC_LOC
	aFieldTypes[3,2] = 1
	aFieldTypes[3,3] = 20
	aFieldTypes[3,4] = 0
	aFieldTypes[3,5] = 19
	aFieldTypes[3,6] = 'N'
	aFieldTypes[3,7] = .F.
	aFieldTypes[4,1] = FTFLOAT_LOC
	aFieldTypes[4,2] = 1
	aFieldTypes[4,3] = 20
	aFieldTypes[4,4] = 0
	aFieldTypes[4,5] = 19
	aFieldTypes[4,6] = 'F'
	aFieldTypes[4,7] = .F.
	aFieldTypes[5,1] = FTDATE_LOC
	aFieldTypes[5,2] = 8
	aFieldTypes[5,3] = 8
	aFieldTypes[5,4] = 0
	aFieldTypes[5,5] = 0
	aFieldTypes[5,6] = 'D'
	aFieldTypes[5,7] = .F.
	aFieldTypes[6,1] = FTDATETIME_LOC
	aFieldTypes[6,2] = 14
	aFieldTypes[6,3] = 14
	aFieldTypes[6,4] = 0
	aFieldTypes[6,5] = 0
	aFieldTypes[6,6] = 'T'	
	aFieldTypes[6,7] = .F.
	aFieldTypes[7,1] = FTDOUBLE_LOC
	aFieldTypes[7,2] = 8
	aFieldTypes[7,3] = 8
	aFieldTypes[7,4] = 0
	aFieldTypes[7,5] = 18
	aFieldTypes[7,6] = 'B'
	aFieldTypes[7,7] = .F.
	aFieldTypes[8,1] = FTINTEGER_LOC
	aFieldTypes[8,2] = 4
	aFieldTypes[8,3] = 4
	aFieldTypes[8,4] = 0
	aFieldTypes[8,5] = 0
	aFieldTypes[8,6] = 'I'	
	aFieldTypes[8,7] = .F.
	aFieldTypes[9,1] = FTLOGICAL_LOC
	aFieldTypes[9,2] = 1
	aFieldTypes[9,3] = 1
	aFieldTypes[9,4] = 0
	aFieldTypes[9,5] = 0
	aFieldTypes[9,6] = 'L'
	aFieldTypes[9,7] = .F.
	aFieldTypes[10,1] = FTMEMO_LOC
	aFieldTypes[10,2] = 10
	aFieldTypes[10,3] = 10
	aFieldTypes[10,4] = 0
	aFieldTypes[10,5] = 0
	aFieldTypes[10,6] = 'M'
	aFieldTypes[10,7] = .F.
	aFieldTypes[11,1] = FTCHARACTERBIN_LOC
	aFieldTypes[11,2] = 1		&& minimum column width
	aFieldTypes[11,3] = 254		&& maximum column width
	aFieldTypes[11,4] = 0		&& minimum decimals width
	aFieldTypes[11,5] = 0		&& maximum decimals width
	aFieldTypes[11,6] = 'C'
	aFieldTypes[11,7] = .T.		&& codepage translation?
	aFieldTypes[12,1] = FTMEMOBIN_LOC
	aFieldTypes[12,2] = 10
	aFieldTypes[12,3] = 10
	aFieldTypes[12,4] = 0
	aFieldTypes[12,5] = 0
	aFieldTypes[12,6] = 'M'
	aFieldTypes[12,7] = .T.
	
	iStructGridColumn = 0
	
	* Options... controls
	iDelimiterMode = 2
	dimension aDelimiterTypes[5, 2]
	aDelimiterTypes[1, 1] = DT_TABS_LOC
	aDelimiterTypes[1, 2] = chr(9)
	aDelimiterTypes[2, 1] = DT_COMMAS_LOC
	aDelimiterTypes[2, 2] = ','
	aDelimiterTypes[3, 1] = DT_OTHER_LOC
	aDelimiterTypes[3, 2] = '*'
	aDelimiterTypes[4, 1] = DT_SEMICOLONS_LOC
	aDelimiterTypes[4, 2] = ';'
	aDelimiterTypes[5, 1] = DT_SPACE_LOC
	aDelimiterTypes[5, 2] = ' '

	iDelimiterType = 0
	
	cDelimiterChar = ''

	dimension aTextQualifiers[3,2]
	aTextQualifiers[1,1] = TQDOUBLE_LOC
	aTextQualifiers[1,2] = '"'
	aTextQualifiers[2,1] = TQSINGLE_LOC
	aTextQualifiers[2,2] = "'"
	aTextQualifiers[3,1] = TQNONE_LOC
	aTextQualifiers[3,2] = ''
	iTextQualifier = 1
	cTextQualifier = '"'
	lConsecutiveDelimitersAsOne = .f.
	cPoint = set('point')
	cSeparator = set('separator')
	cCurrency = set('currency',1)
	
	* These are temporary flags used by the Import Options dialog
	lDirtySample = .f.
	lDirtyTestCursor = .f.
	lDirtyFileTypeAnalysis = .f.
	lDirtyStructureAnalysis = .f.
	
	* This flag is set by the Import Options dialog and causes all
	* records in a text file to be analyzed for field count/widths
	lScanAllRecords = .f.
	
	* This flag is set (in the Options dialog) when the user 
	* specifically overrides the file type. It's used in the Options 
	* dialog to prevent analyzing the file type on subsequent trips 
	* to the Options dialog. This flag is reset in ImportWizard.ResetFlags
	lUserOverride = .f.
	
	iCodePage = cpcurrent(1)

	dimension aDateFormats[7,2]
	aDateFormats[1,1] = DF_FORMAT1_LOC
	aDateFormats[1,2] = DF_KEYWORD1_LOC
	aDateFormats[2,1] = DF_FORMAT2_LOC
	aDateFormats[2,2] = DF_KEYWORD2_LOC
	aDateFormats[3,1] = DF_FORMAT3_LOC
	aDateFormats[3,2] = DF_KEYWORD3_LOC
	aDateFormats[4,1] = DF_FORMAT4_LOC
	aDateFormats[4,2] = DF_KEYWORD4_LOC
	aDateFormats[5,1] = DF_FORMAT5_LOC
	aDateFormats[5,2] = DF_KEYWORD5_LOC
	aDateFormats[6,1] = DF_FORMAT6_LOC
	aDateFormats[6,2] = DF_KEYWORD6_LOC
	aDateFormats[7,1] = DF_FORMAT7_LOC
	aDateFormats[7,2] = DF_KEYWORD7_LOC
	iDateFormat = 1
	
	* Properties used internally by the ImportEngine
	
	cSampleFileName = ''
	cSampleCursorName = ''
	cSampleCursorName2 = ''

	* option for non-text files
	iBeginningRow = 1
	iFieldNameRow = 0
	cWorkSheet = ''

	* iSampleSize is the number of records sampled to determine file type
	iSampleSize = 50
	* cSampleFileType is "Fixed-length" or "Delimited"
	cSampleFileType = ''
	* cSampleDelimiter is "," or chr(9) or ";"
	cSampleDelimiter = ''
	* cSampleTextQualifier is double-quote ("), single-quote('), or none
	cSampleTextQualifier = ''
	* iSampleRecordLength holds the record length for Fixed-length files
	iSampleRecordLength = 0
	* iSampleFieldCount is the number of fields in a delimited record
	iSampleFieldCount = 0
	dimension aSampleColumns[1,6]
	aSampleColumns = 0
	dimension aSampleWidths[1,1]
	aSampleWidths = 0
	cTestCursor = ''
	
	* Handle to text file opened with LLFF. The file is opened when the
	* user selects it in Step 1 and closed in ImportEngine.Destroy.
	iTextHandle = .NULL.
	
	* aSDFColumns is used to keep track of the columns in which
	* SDF records break into fields (this is relative to the HScroll.Value)
	* and the shapes which are used
	* to represent those columns. The 3rd column in the array keeps
	* track of the actual column in the record.
	
	* iSDFColumn is used to keep track
	* of the row number of the column which is currently being 
	* dragged about.
	
	dimension aSDFColumns[1,3]
	aSDFColumns[1,1] = 0
	aSDFColumns[1,2] = .NULL.
	aSDFColumns[1,3] = 0
	iSDFColumn = 0
	
	* iOutputFileWorkarea is used to store the workarea in which the output
	* file (new or append) is opened so it can be closed in Destroy
	iOutputFileWorkarea = 0
	
	* delays executions of InitSteps in OWizard.Init
	lInitSteps = .F.
	
	***********************************************************************************
	* These members are used when copying data from atext file to the
	* destination table (either a new table or an existing table)
	
	* aColumnData contains the column number of the data in the source text file 
	* and the data type of the target column in the output file. If the file
	* being imported is SDF, columns 3 and 4 contain the substr() values to 
	* get the column from the record. Column 5 contains the field number in the
	* target table where this field will be inserted.
	dimension aColumnData[1, 5]
	
	* aTargetColumns contains the converted fields to be copied to the output file
	dimension aTargetColumns[1]
	***********************************************************************************

	procedure Init2
		local cWizardFll, i, cPoint

		* Set options to current system values
		for m.i = 1 to alen(this.aDateFormats, 1)
			if set('date') $ this.aDateFormats[m.i, 2]
				this.iDateFormat = m.i
				exit
			endif
		endfor

		* Load Wizard.fll
		m.cPoint = set('point')
		set point to '.'
		if ! '\wizard.fll' $ lower(set('library'))
			m.cWizardFll = this.WizLocFile(sys(2004) + 'wizards\wizard.fll')
			if .not. empty(m.cWizardFll)
				set library to (m.cWizardFll) additive
				if val(WizardVer()) <> WIZARD_FLL_VERSION
					this.Alert(WIZARDVERERROR_LOC)
					set point to m.cPoint
					return .f.
				endif
			else
				this.Alert(FLLREQUIRED_LOC)
				return .f.
			endif
			this.AddLibraryToReleaseList(m.cWizardFll)
		else
			* Check the version number
				if val(WizardVer()) <> WIZARD_FLL_VERSION
					this.Alert(WIZARDVERERROR_LOC)
					set point to m.cPoint
					return .f.
				endif
		endif
		set point to m.cPoint
		
		this.SetCodePage(this.iCodePage)
		
#IF 0					
		if ! '\wizard.fll' $ lower(set('library'))
			if file(sys(2004) + 'wizards\wizard.fll')
				set library to (sys(2004) + 'wizards\wizard.fll') additive
			else
				clear typeahead
				this.SetErrorOff = .t.
				set library to locfile('wizard.fll', 'fll', 'Wizard.fll:') additive
				this.SetErrorOff = .f.
				this.haderror = .f.
			endif
		endif
#ENDIF
	endproc
	
	procedure CreateSample
		parameters m.cFileName
		local iSelect, cSafety, lConvert, iCPCurrent
		
		* Reset Sampling Variables
	
		this.cSampleFileName = m.cFileName
		
		* Create/Reset Sampling Cursor

		m.iSelect = select()
		if empty(this.cSampleCursorName)
			this.cTestCursor = '_'+sys(3)
			do while used(this.cTestCursor)
				this.cTestCursor = '_'+sys(3)
			enddo
			create cursor (this.cTestCursor) (placeholder c(10))
			
			this.cSampleCursorName = '_'+sys(3)
			do while used(this.cSampleCursorName)
				this.cSampleCursorName = '_'+sys(3)
			enddo
			create cursor (this.cSampleCursorName) ;
				(offset n(10), record m, recno i)
		else
			m.cSafety = set('safety')
			set safety off
			select (this.cTestCursor)
			zap
			select (this.cSampleCursorName)
			zap
			set safety &cSafety
		endif

		m.iCPCurrent = cpcurrent(1)
		m.lConvert = (m.iCPCurrent <> this.iCodePage)
		
		* Create Sampling Records
		=fseek(this.iTextHandle, 0, 0) && position pointer at bof
		do while !feof(this.iTextHandle)

			insert into (this.cSampleCursorName) ;
				values ;
				( ;
					fseek(this.iTextHandle, 0, 1), ;
					iif(m.lConvert, ;
						cpconvert(this.iCodePage, m.iCPCurrent, fgets(this.iTextHandle, C_MAXTEXTLENGTH)), ;
						fgets(this.iTextHandle, C_MAXTEXTLENGTH) ;
					), ;
					recno() ;
				)
				
			* do we have enough records?
			if reccount(this.cSampleCursorName) = ;
				this.iSampleSize + this.iBeginningRow - 1
				exit
			endif
		enddo
		
		if this.iBeginningRow <> 1 .and. reccount(this.cSampleCursorName) < ;
			this.iBeginningRow
			
			this.Alert(RESETBEGINNINGROW_LOC)
			this.iBeginningRow = 1
		endif

		select (m.iSelect)
	endproc

	procedure CreateSample2
	LOCAL cTestCursor, cBaseCursor, lIsTextFile

	m.lIsTextFile = (lower(this.aFileTypes[oEngine.iFileType, 2]) = 'txt')

	IF m.lIsTextFile
		if empty(this.cSampleCursorName2)
			cTestCursor = '_'+sys(3)
			do while used(cTestCursor)
				cTestCursor = '_'+sys(3)
			enddo
			this.cSampleCursorName2 = cTestCursor
		endif
		cBaseCursor = this.cSampleCursorName

		select recno() AS Row, ;
				LEFT(&cBaseCursor..record, 254) AS Data ;
				from &cBaseCursor into cursor (this.cSampleCursorName2)

	ELSE
		this.cSampleCursorName2 = this.cTestCursor	
	ENDIF

	endproc

	procedure AnalyzeFileType
		local iSelect
		
		* Reset Sampling Variables
		this.cSampleFileType = ''
		this.cSampleTextQualifier = ''
		this.cSampleDelimiter = ''
		this.iSampleRecordLength = 0

		* iSampleFieldCount is the number of fields in a delimited record--it's
		* value is set in IsDelimited
		this.iSampleFieldCount = 0

		m.iSelect = select()
		select (this.cSampleCursorName)
		do case
		case this.IsSDF()
			this.iDelimiterMode = 2 && Fixed-length
		case this.IsDelimited(',')
			this.iDelimiterMode = 1 && Delimited
			this.iDelimiterType = 2 && Comma
			this.cDelimiterChar = ','
		case this.IsDelimited(chr(9))
			this.iDelimiterMode = 1 && Delimited
			this.iDelimiterType = 1 && Tab
			this.cDelimiterChar = chr(9)
		case this.IsDelimited(';')
			this.iDelimiterMode = 1 && Delimited
			this.iDelimiterType = 4 && Semicolon
			this.cDelimiterChar = ';'
		otherwise
			this.iDelimiterMode = 2 && Fixed-length
			* Call this.IsSDF to set variables about Fixed-length files
			this.IsSDF(.t.)
		endcase
		select (m.iSelect)
	endproc
	
	procedure AnalyzeStructure
		local iSelect
		
		* Reset Sampling Variables
		dimension this.aSampleColumns[1, alen(this.aSampleColumns, 2)]
		this.aSampleColumns = 0
		dimension this.aSampleWidths[1, alen(this.aSampleWidths, 2)]
		this.aSampleWidths = 0

		m.iSelect = select()
		select (this.cSampleCursorName)
		
		if this.iDelimiterMode = 2
			* Fixed-length
			this.AnalyzeColumns
		else
			* Delimited
			this.FieldWidths
		endif
		
		select (m.iSelect)
	endproc
	
	procedure AnalyzeColumns
		local cRecord, cTransition, iRecLen, cShort, iShort, i, ;
			iRow, cRow, iRecordsAnalyzed
		
		m.iRecLen = 0
		m.cTransition = ''
		m.iRecordsAnalyzed = 0
				
		if .not. this.lScanAllRecords
			go this.iBeginningRow
			scan rest
				m.cRecord = record
				if m.iRecLen < len(m.cRecord)
					m.iRecLen = len(m.cRecord)
					m.cTransition = padr(m.cTransition, m.iRecLen * 2, chr(0))
				endif
				=AnalyzeSDF(@cRecord, @cTransition)
				m.iRecordsAnalyzed = m.iRecordsAnalyzed + 1
			endscan
		else
			* Sample the entire file
			=fseek(this.iTextHandle, 0, 0) && position pointer at bof

			* Skip to the beginning row
			m.iRecno = 1
			do while !feof(this.iTextHandle) .and. m.iRecno < this.iBeginningRow
				=fgets(this.iTextHandle, C_MAXTEXTLENGTH)
				m.iRecno = m.iRecno + 1
			enddo
			
			* Sample records
			do while !feof(this.iTextHandle)
				m.cRecord = fgets(this.iTextHandle, C_MAXTEXTLENGTH)
				if m.iRecLen < len(m.cRecord)
					m.iRecLen = len(m.cRecord)
					m.cTransition = padr(m.cTransition, m.iRecLen * 2, chr(0))
				endif
				=AnalyzeSDF(@cRecord, @cTransition)
				m.iRecordsAnalyzed = m.iRecordsAnalyzed + 1
			enddo
		endif
		
		* Reset iSampleRecordLength--this is necessary in the case that the
		* user overrides the analysis and sets the file type as fixed
		this.iSampleRecordLength = int(len(m.cTransition) / 2)
		
		* Can we assume that aSDFColumns has been cleared?
		if !empty(this.aSDFColumns[1, 1])
			oWizard.ClearSDFColumns
		endif
		
		for m.i = 1 to int(len(m.cTransition) / 2)
			m.cShort = substr(m.cTransition, ((m.i - 1) * 2 + 1), 2)
			if _MAC
				m.iShort = asc(substr(m.cShort, 1, 1)) * 256 + ;
					asc(substr(m.cShort, 2, 1))
			else
				m.iShort = asc(substr(m.cShort, 1, 1)) + ;
					asc(substr(m.cShort, 2, 1)) * 256
			endif
			
			if m.iShort >= .75 * m.iRecordsAnalyzed
				if empty(this.aSDFColumns[1, 3])
					m.iRow = 1
				else
					m.iRow = alen(this.aSDFColumns, 1) + 1
				endif
				dimension this.aSDFColumns[m.iRow, 3]
				this.iShapeCount = this.iShapeCount + 1
				m.cRow = alltrim(str(m.iRow))
				aPageRef[2].pgfStep1a.Page2.AddObject( ;
					'shpDelimiter&cRow', 'shpDelimiter')
				this.aSDFColumns[m.iRow, 2] = ;
					aPageRef[2].pgfStep1a.Page2.shpDelimiter&cRow
				oEngine.aSDFColumns[m.iRow, 2].Top = ;
					aPageRef[2].pgfStep1a.Page2.shpClick.Top
				oEngine.aSDFColumns[m.iRow, 2].Height = 75
				oEngine.aSDFColumns[m.iRow, 2].Width = 1
				this.aSDFColumns[m.iRow, 3] = m.i - 1
			endif
		endfor
		this.lScanAllRecords = .f.
	endproc
	
	procedure IsDelimited
		parameters m.cDelimiter
		local iFieldCount
		go (this.iBeginningRow)
		scan while m.cDelimiter $ record
		endscan
		if !eof()
			return .f.
		endif
		
		go (this.iBeginningRow)
		m.iFieldCount = this.FieldCount(record, m.cDelimiter, '"')
		scan while this.FieldCount(record, m.cDelimiter, '"') = m.iFieldCount
		endscan
		if eof()
			* 'Delimited' is internal and needn't be localized
			this.cSampleFileType = 'Delimited'
			this.cSampleTextQualifier = '"'
			this.cTextQualifier = '"'
			this.cSampleDelimiter = m.cDelimiter
			this.cDelimiterChar = m.cDelimiter
			this.iSampleFieldCount = m.iFieldCount
		endif
		return eof()
	endproc
	
	procedure FieldCount
		parameters m.cRecord, m.cDelimiter, m.cTextQualifier
		local iFieldCount, lInText, cChar, i

		*- make sure we don't count consecutive field delimiters as separate fields 
		*- if the user doesn't want them
		if this.lConsecutiveDelimitersAsOne
			do while replicate(this.cDelimiterChar, 2) $ m.cRecord
				m.cRecord = strtran(m.cRecord, replicate(this.cDelimiterChar, 2),this.cDelimiterChar)
			enddo
		endif
		
		do case
		case empty(m.cRecord)
			return 0
		case empty(m.cTextQualifier) .or. .not. m.cTextQualifier $ m.cRecord
			return 1 + occurs(m.cDelimiter,m.cRecord)
		otherwise
			return CountDelimitedFields(@cRecord, @cDelimiter, @cTextQualifier)
		endcase
	endproc
	
	procedure FieldWidths
		* This procedure looks at delimited records and determines number and
		* maximum widths of the fields. If the lScanAllRecords member is .T., the
		* entire text file is scanned, otherwise the sample cursor is used. The
		* beginning row is respected in either case.
		
		local cFieldWidths, cRecord, cDelimiter, cQualifier, i, iShort, cShort, ;
			iFieldCount, iRecno
		
		m.cFieldWidths = replicate(chr(0), 2 * C_MAXFIELDS) && shorts stored here
		m.cDelimiter = this.cSampleDelimiter
		m.cQualifier = this.cSampleTextQualifier
		
		* It's necessary to re-establish the iSampleFieldCount value in the
		* event the user toggled the delimiter in the Options dialog
		m.iFieldCount = 0
		
		if .not. this.lScanAllRecords
			* Use the sample cursor
			go this.iBeginningRow
		
			scan rest
				m.cRecord = record
				m.iFieldCount = max(m.iFieldCount, ;
					DelimitedFieldWidths(@cRecord, @cDelimiter, ;
					@cQualifier, @cFieldWidths))
			endscan
		else
			* Sample the entire text file
			
			=fseek(this.iTextHandle, 0, 0) && position pointer at bof

			* Skip to the beginning row
			m.iRecno = 1
			do while !feof(this.iTextHandle) .and. m.iRecno < this.iBeginningRow
				=fgets(this.iTextHandle, C_MAXTEXTLENGTH)
				m.iRecno = m.iRecno + 1
			enddo
			
			* Sample records
			do while !feof(this.iTextHandle)
				m.cRecord = fgets(this.iTextHandle, C_MAXTEXTLENGTH)
				m.iFieldCount = max(m.iFieldCount, ;
					DelimitedFieldWidths(@cRecord, @cDelimiter, ;
					@cQualifier, @cFieldWidths))
				m.iRecno = m.iRecno + 1
			enddo
			
			this.lScanAllRecords = .f.
		endif
			
		* Put the field widths into this.aSampleWidths
		dimension this.aSampleWidths[m.iFieldCount, alen(this.aSampleWidths, 2)]
		this.aSampleWidths = 0
		
		for m.i = 1 to m.iFieldCount
			m.cShort = substr(m.cFieldWidths, ((m.i - 1) * 2 + 1), 2)
			if _MAC
				m.iShort = asc(substr(m.cShort, 1, 1)) * 256 + ;
					asc(substr(m.cShort, 2, 1))
			else
				m.iShort = asc(substr(m.cShort, 1, 1)) + ;
					asc(substr(m.cShort, 2, 1)) * 256
			endif
			this.aSampleWidths[m.i, 1] = m.iShort
		endfor
		
		this.iSampleFieldCount = m.iFieldCount
		
	endproc
	
	procedure IsSDF
		* The lDefaultToSDF parameter is true when this procedure is called
		* because the file is not delimited and the record lengths are
		* variable. This routine is called to keep the setting of engine
		* variables related to fixed-length file in one place.
		
		parameters lDefaultToSDF
		
		local iRecordLength
		go (this.iBeginningRow)
		m.iRecordLength = len(record)
		if .not. m.lDefaultToSDF
			* See if this file is Fixed-length
			scan while len(record) = m.iRecordLength
			endscan
			if eof()
				this.cSampleFileType = 'Fixed-length'
				this.iSampleRecordLength = m.iRecordLength
			endif
			return eof()
		else
			* We'll use fixed-length by default--calculate the maximum
			* length of a record in the sampling and use it as the record
			* length
			scan rest
				m.iRecordLength = max(m.iRecordLength, len(record))
			endscan
			this.cSampleFileType = 'Fixed-length'
			this.iSampleRecordLength = m.iRecordLength
		endif
	endproc
	
	procedure CreateTestCursor
		local aStruct, i, iCPCurrent, lConvert
		local array aColumns[1], aRecords[1], aStruct1[1]

		* "Delimited" is internal and needn't be localized
		if this.cSampleFileType <> "Delimited" .or. this.cSampleDelimiter <> ";"
			* Close the text file--append from's error out otherwise
			this.CloseTextFile
		endif
				
		m.iCPCurrent = cpcurrent(1)
		m.lConvert = (m.iCPCurrent <> this.iCodePage)

		* "Delimited" is internal and needn't be localized
		if this.cSampleFileType = "Delimited"
			dimension aStruct[this.iSampleFieldCount, 4]
			for m.i = 1 to alen(aStruct, 1)
				aStruct[m.i, 1] = COLUMN_LOC + alltrim(str(m.i))
				aStruct[m.i, 2] = 'C'
				if this.aSampleWidths[m.i, 1] = 0
					aStruct[m.i, 3] = 10 && default field width
				else
					aStruct[m.i, 3] = min(this.aSampleWidths[m.i, 1], 254)
				endif
				aStruct[m.i, 4] = 0
			endfor
			create cursor (this.cTestCursor) from array aStruct
			
			do case
				case this.cSampleDelimiter = ','
					if m.lConvert
						append from (this.cSampleFileName) type delimited ;
							for recno() <= (this.iBeginningRow - 1) + this.iSampleSize ;
							as this.iCodePage
					else
						append from (this.cSampleFileName) type delimited ;
							for recno() <= (this.iBeginningRow - 1) + this.iSampleSize
					endif
				case this.cSampleDelimiter = chr(9)
					if m.lConvert
						append from (this.cSampleFileName) type delimited with tab ;
							for recno() <= (this.iBeginningRow - 1) + this.iSampleSize ;
							as this.iCodePage
					else
						append from (this.cSampleFileName) type delimited with tab ;
							for recno() <= (this.iBeginningRow - 1) + this.iSampleSize
					endif
  				otherwise
*				case this.cSampleDelimiter = ';'
					this.openTextFile(this.cSourceFile)  && v-darylm
					dimension aSourceColumns[alen(aStruct, 1)]
					=fseek(this.iTextHandle, 0, 0) && position pointer at bof
					for m.i = 1 to (this.iBeginningRow - 1)
						* Toss out records
						=fgets(this.iTextHandle, C_MAXTEXTLENGTH)
						if feof(this.iTextHandle)
							exit
						endif
					endfor
					for m.i = 1 to this.iSampleSize
						if feof(this.iTextHandle)
							exit
						endif
						this.ScatterText(iif(m.lConvert, ;
							cpconvert(this.iCodePage, m.iCPCurrent, fgets(this.iTextHandle, C_MAXTEXTLENGTH)), ;
							fgets(this.iTextHandle, C_MAXTEXTLENGTH)), this.cDelimiterChar, this.cTextQualifier)
						insert into (this.cTestCursor) from array aSourceColumns
					endfor
  				this.closeTextFile()  && v-darylm
			endcase
			go top
		else && Fixed-length
			if alen(this.aSDFColumns, 1) = 1 .and. empty(this.aSDFColumns[1, 3])
				* No columns have been delimited--create a structure with
				* one column the width of the fixed length record
				dimension aStruct[1, 4]
				aStruct[1, 1] = COLUMN_LOC + "1"
				if this.iSampleRecordLength > 254
					aStruct[1, 2] = 'M'
					aStruct[1, 3] = 10
				else
					aStruct[1, 2] = 'C'
					aStruct[1, 3] = MAX(this.iSampleRecordLength,1)
				endif
				aStruct[1, 4] = 0
			else
				dimension aColumns[alen(this.aSDFColumns, 1)]
				for m.i = 1 to alen(aColumns)
					aColumns[m.i] = this.aSDFColumns[m.i, 3]
				endfor
				asort(aColumns)
				dimension aStruct[alen(aColumns) + 1, 4]
				for m.i = 1 to alen(aColumns)
					aStruct[m.i, 1] = COLUMN_LOC + alltrim(str(m.i))
					aStruct[m.i, 2] = 'C'
					if m.i = 1
						aStruct[m.i, 3] = aColumns[m.i]
					else
						aStruct[m.i, 3] = aColumns[m.i] - aColumns[m.i - 1]
					endif
					aStruct[m.i, 4] = 0
					if aStruct[m.i, 3] > 254
						aStruct[m.i, 2] = 'M'
						aStruct[m.i, 3] = 10
					endif
					aStruct[m.i,3] = MAX(aStruct[m.i,3],1)	
				endfor
				m.i = alen(aStruct, 1) && the final column in the structure
				aStruct[m.i, 1] = COLUMN_LOC + alltrim(str(m.i))
				aStruct[m.i, 2] = 'C'
				aStruct[m.i, 3] = this.iSampleRecordLength - aColumns[m.i - 1]
				aStruct[m.i, 4] = 0
				if aStruct[m.i, 3] > 254
					aStruct[m.i, 2] = 'M'
					aStruct[m.i, 3] = 10
				endif
				aStruct[m.i,3] = MAX(aStruct[m.i,3],1)	
			endif
			create cursor (this.cTestCursor) from array aStruct
			if alen(aStruct, 1) = 1 .and. aStruct[1, 2] = 'M'

				m.iCPCurrent = cpcurrent(1)
				m.lConvert = (m.iCPCurrent <> this.iCodePage)
		
				this.OpenTextFile(this.cSourceFile)
				do while !feof(this.iTextHandle)
					insert into (this.cTestCursor) ;
						values ;
						( ;
							iif(m.lConvert, ;
								cpconvert(this.iCodePage, m.iCPCurrent, fgets(this.iTextHandle, C_MAXTEXTLENGTH)), ;
								fgets(this.iTextHandle, C_MAXTEXTLENGTH) ;
								) ;
						)
				enddo
			else
				append from (this.cSampleFileName) type sdf ;
					for recno() <= (this.iBeginningRow - 1) + this.iSampleSize ;
					as this.iCodePage
			endif
			go top
		endif
		
		* rename columns
		IF  this.iFieldNameRow > 0 AND ;
			this.iFieldNameRow >= 1 AND this.iFieldNameRow <= RECCOUNT()
			go this.iFieldNameRow
			scatter memo to aRecord
			=AFIELDS(aStruct1)
			for m.i = 1 to alen(aRecord, 1)
				IF this.MakeFieldName(@aRecord, m.i)
					ALTER TABLE ALIAS() RENAME COLUMN (aStruct1[m.i, 1]) TO (aRecord(m.i))
				ENDIF
			ENDFOR
			go top
		ENDIF

		* Re-open text file
		this.OpenTextFile(this.cSourceFile)
   	endproc
	
	procedure ProcessOutput
		local i, j, cTargetFieldList, cColumn, cColumnName, iRecno, ;
			lConvert, iCPCurrent, lIsTextFile, cFileName, ;
			iLastThermUpdate, cEscape, iSeconds, iSelect, lHaveDBC, cTableFriendlyName
		local array aTempStruct[1]
		
		* lEscapePressed is PRIVATE on purpose
		private lEscapePressed
		
		* Public the arrays used for converting text records
		public array aSourceColumns[1], aTargetColumns[1], aColumnData[1]
		
		m.lIsTextFile = (lower(this.aFileTypes[this.iFileType, 2]) = 'txt')

		m.iSelect = select()
		
		if this.iOutputMode = 1
			* Construct an array to create the output file. Build
			* an array of the originating column number and destination
			* data type of the columns to write to the new file.
			
			dimension aTempStruct[alen(this.aStruct, 1), 6]
			for m.i = 1 to alen(aTempStruct, 1)
				aTempStruct[m.i, 1] = this.aStruct[m.i, 1]
				aTempStruct[m.i, 2] = this.aStruct[m.i, 2]
				aTempStruct[m.i, 3] = this.aStruct[m.i, 3]
				aTempStruct[m.i, 4] = this.aStruct[m.i, 4]
				aTempStruct[m.i, 6] = this.aStruct[m.i, 6]		&& NOCPTRANS
			endfor

			dimension aColumnData[1, 5]
			aColumnData = ''
			for m.i = alen(aTempStruct, 1) to 1 step -1
				if empty(aTempStruct[m.i, 1])
					* Drop columns which aren't defined
					=adel(aTempStruct, m.i)
					dimension aTempStruct[alen(aTempStruct, 1) - 1, ;
						alen(aTempStruct, 2)]
				else
					* Accumlate columns to include
					if !empty(aColumnData[1, 1])
						dimension aColumnData[alen(aColumnData, 1) + 1, 5]
					endif
					aColumnData[alen(aColumnData, 1), 1] = m.i
					aColumnData[alen(aColumnData, 1), 2] = ;
						aTempStruct[m.i, 1]
					aColumnData[alen(aColumnData, 1), 5] = m.i
				endif
			endfor
			=asort(aColumnData, 1)
			
			* Number off column 5 for target array
			for m.i = 1 to alen(aColumnData, 1)
				aColumnData[m.i, 5] = m.i
			endfor
			
			* Create the new table
			this.HadError = .f.
			this.SetErrorOff = .t.

			IF oWizard.lCreateDBC
				*- create DBC, add table to it
				CREATE DATABASE (oWizard.cDBCName)
			ENDIF
			
			m.lHaveDBC = oWizard.HaveDBC			&& okay to add to shared DBC

			m.cTableFriendlyName = LEFT(ALLTRIM(oWizard.cTableFriendlyName),128)
			
			DO CASE
				CASE !m.lHaveDBC
					CREATE TABLE (this.cOutputFile) FREE FROM ARRAY aTempStruct
				CASE !EMPTY(oWizard.cTableFriendlyName)
					CREATE TABLE (this.cOutputFile) NAME "&cTableFriendlyName" FROM ARRAY aTempStruct
				OTHERWISE
					CREATE TABLE (this.cOutputFile) FROM ARRAY aTempStruct
			ENDCASE

			this.SetErrorOff = .f.
			if this.HadError
				this.HadError = .f.
				this.Alert(E_CREATETABLE_LOC)
				select (m.iSelect)
				return .f.
			endif
			this.iOutputFileWorkarea = select()
			
		else

			* Open the append table
			select 0
			this.HadError = .f.
			this.SetErrorOff = .t.
			use (this.cAppendFile) exclusive
			this.SetErrorOff = .f.
			if this.HadError
				this.HadError = .f.
				this.Alert(E_OPENAPPEND_LOC)
				select (m.iSelect)
				return .f.
			endif
			
			this.iOutputFileWorkarea = select()
			
			* Construct an array of the originating column number and 
			* destination data type of the columns to write to the append 
			* file. Construct a list of the columns in the append file 
			* which receive the data.
			dimension aColumnData[1, 5]
			aColumnData = ''
			m.cTargetFieldList = ''
			for m.i = 1 to aPageRef[3].pgfStep2.Page2.Grid1.ColumnCount
				m.cColumn = alltrim(str(m.i))
				m.cColumnName = ;
					aPageRef[3].pgfStep2.Page2.Grid1.Column&cColumn..Header1.Caption
				if !empty(m.cColumnName)
					if !empty(aColumnData[1, 1])
						dimension aColumnData[alen(aColumnData, 1) + 1, 5]
					endif
					aColumnData[alen(aColumnData, 1), 1] = m.i
					aColumnData[alen(aColumnData, 1), 2] = m.cColumnName

					for m.j = 1 to fcount(this.iOutputFileWorkarea)
						if upper(m.cColumnName) == field(m.j, this.iOutputFileWorkarea)
							aColumnData[alen(aColumnData, 1), 5] = m.j
							exit
						endif
					endfor
					
					if empty(aColumnData[alen(aColumnData, 1), 5])
						error BADVALUE_LOC
					endif
					
					m.cTargetFieldList = m.cTargetFieldList + ;
						iif(empty(m.cTargetFieldList), '', ', ') + ;
						m.cColumnName
				endif
			endfor
		endif
		
		if m.lIsTextFile .and. this.iDelimiterMode = 2
			* Fixed-length text file--put the substr() values into columns
			* 3 and 4 of aColumnData

			for m.i = 1 to alen(aColumnData, 1)
				do case
				case aColumnData[m.i, 1] = 1
					* the first column
					aColumnData[m.i, 3] = 1
					if empty(this.aSDFColumns[1, 3])
						* No delimiters--there's one big column
						aColumnData[m.i, 4] = C_MAXTEXTLENGTH
					else
						aColumnData[m.i, 4] = this.aSDFColumns[1, 3]
					endif
				case aColumnData[m.i, 1] = alen(this.aSDFColumns, 1) + 1
					* The last column
					aColumnData[m.i, 3] = ;
						this.aSDFColumns[alen(this.aSDFColumns, 1), 3] + 1
					aColumnData[m.i, 4] = C_MAXTEXTLENGTH
				otherwise
					aColumnData[m.i, 3] = ;
						this.aSDFColumns[aColumnData[m.i, 1] - 1, 3] + 1
					aColumnData[m.i, 4] = ;
						this.aSDFColumns[aColumnData[m.i, 1], 3] + 1 - ;
						aColumnData[m.i, 3]
				endcase
			endfor
		endif
			
		* Use TYPE() to determine the destination type of each field
		select (this.iOutputFileWorkarea)
		for m.i = 1 to alen(aColumnData, 1)
			aColumnData[m.i, 2] = type(aColumnData[m.i, 2])
		endfor

		* Dimension and initialize the source and target field arrays
		dimension aSourceColumns[fcount(this.cTestCursor)]
		aSourceColumns = ''
		
		* The target field array is the same length as the number of fields
		* in the target table. Initialize the fields with empty() values.
		dimension aTargetColumns[fcount(this.iOutputFileWorkarea)]
		
		scatter memo blank to aTargetColumns
		
		* Set the SET DATE format used for converting dates
		if space(1) $ this.aDateFormats[this.iDateFormat, 2]
			set date to (left(this.aDateFormats[this.iDateFormat, 2], ;
				at(space(1), this.aDateFormats[this.iDateFormat, 2]) - 1))
		else
			set date to (this.aDateFormats[this.iDateFormat,2])			
		endif
			
		if m.lIsTextFile
			=fseek(this.iTextHandle, 0, 0) && position pointer at bof
		
			* Set up variables for code page conversion
			* (this will have happened during IMPORT for non-text files)
			m.iCPCurrent = cpcurrent(1)
			m.lConvert = (m.iCPCurrent <> this.iCodePage)
		endif
		
		* Set up thermometer
		set class to therm additive
		if m.lIsTextFile
			* Use bytes read from text file
			this.AddTherm(THERMMSG_LOC, fseek(this.iTextHandle, 0, 2))
			=fseek(this.iTextHandle, 0, 0) && go back to the beginning of the file
		else
			* Use test cursor record count, adjusting for beginning row
			this.AddTherm(THERMMSG_LOC, reccount(this.cTestCursor) - this.iBeginningRow - 1)
		endif
		this.ThermRef.Visible = .t.
		
		m.iRecno = 1
		
		if this.iBeginningRow <> 1
			* Toss out records up to the beginning row
			if m.lIsTextFile
				do while m.iRecno < this.iBeginningRow
					* Skip records
					=fgets(this.iTextHandle, C_MAXTEXTLENGTH)
					m.iRecno = m.iRecno + 1
				enddo
				* Update the thermometer basis so we see progress of actual
				* import
				this.ThermRef.iBasis = this.ThermRef.iBasis - fseek(this.iTextHandle, 0, 1)
			else
				select (this.cTestCursor)
				go (this.iBeginningRow)
			endif
		else
			if .not. m.lIsTextFile
				select (this.cTestCursor)
				go top
			endif
		endif

		m.iRecno = 0
		m.iLastThermUpdate = 0
		
		this.ThermRef.lblEscapeMessage.Caption = C_ESCAPEMESSAGE_LOC
		m.lEscapePressed = .f.
		on escape m.lEscapePressed = .t.
		m.cEscape = set('escape')
		set escape on
		do while (m.lIsTextFile .and. !feof(this.iTextHandle)) .or. ;
			(.not. m.lIsTextFile .and. !eof(this.cTestCursor))
			* Move the record into aSourceColumns
			
			if m.lEscapePressed
				if this.Alert(C_CANCELVERIFY_LOC, MB_YESNO) = 'YES'
					exit
				else
					m.lEscapePressed = .f.
				endif
			endif
			
			if m.lIsTextFile
				this.ScatterText(iif(m.lConvert, ;
					cpconvert(this.iCodePage, m.iCPCurrent, fgets(this.iTextHandle, C_MAXTEXTLENGTH)), ;
					fgets(this.iTextHandle, C_MAXTEXTLENGTH)), this.cDelimiterChar, this.cTextQualifier)
			else
				scatter memo to aSourceColumns
				skip
			endif
			m.iRecno = m.iRecno + 1
			* Convert the record into aTargetColumns
			this.ConvertText
			IF THIS.HadError
				EXIT
			ENDIF
			
			* Insert into the target table (new or append)
			this.HadError = .f.
			this.SetErrorOff = .t.
			do while .t.
				insert into (dbf(this.iOutputFileWorkarea)) ;
					from array aTargetColumns
				this.SetErrorOff = .f.
				if this.HadError
					this.HadError = .f.
					if inlist(this.iError, 1582, 1583, 1539) && field or data validation rule violated, or trigger failed
						if this.Alert(DATAVALIDATIONERROR_LOC, MB_YESNO) = 'NO'
							&& Ask whether to ignore error and continue appending records
							error APPENDABORT_LOC
						endif
					else
						loop && causing the error to occur again with error handling enabled
					endif
				endif
				exit
			enddo
			
			* Update the thermometer
			if seconds() - m.iLastThermUpdate > .7
				if m.lIsTextFile
					this.ThermRef.Update(fseek(this.iTextHandle, 0, 1), THERMPROGRESS_LOC)
				else
					this.ThermRef.Update(m.iRecno, THERMPROGRESS_LOC)
				endif
				m.iLastThermUpdate = seconds()
			endif
		enddo
		
		on escape
		set escape &cEscape
		if m.lEscapePressed
			this.ThermRef.lblTask.Caption = C_CANCELLED_LOC
			m.iSeconds = seconds() + 1
			do while seconds() < m.iSeconds
				&& wait a sec
			enddo
		else
			this.ThermRef.Complete
		endif
			
		this.ThermRef.Visible = .f.
		this.ThermRef.AlwaysOnTop = .f.
	endproc
	
	procedure ScatterText
		* This procedure breaks a text file record into fields, placing them
		* in the aSourceColumns member array.
		parameters cRecord, cDelimiterChar, cTextQualifier
		local lInText, cChar, i, iFieldCount
		
		* Clear the array
		aSourceColumns = ''
		
		if this.iDelimiterMode = 2 && Fixed-length
			for m.i = 1 to alen(aColumnData, 1)
				aSourceColumns[aColumnData[m.i, 1]] = ;
					substr(m.cRecord, aColumnData[m.i, 3], ;
					aColumnData[m.i, 4])
			endfor
		else && Delimited
			if this.lConsecutiveDelimitersAsOne
				do while replicate(this.cDelimiterChar, 2) $ m.cRecord
					m.cRecord = strtran(m.cRecord, replicate(this.cDelimiterChar, 2),this.cDelimiterChar)
				enddo
			endif
			
			=ScatterRec(@cRecord, @cDelimiterChar, @cTextQualifier, ;
				@aSourceColumns)

			return
			
			m.iFieldCount = 1
			m.lInText = .f.
			for m.i = 1 to len(m.cRecord)
				m.cChar = substr(m.cRecord, m.i, 1)
				if m.cChar $ this.cDelimiterChar + this.cTextQualifier
					if m.cChar = this.cDelimiterChar
						if .not. m.lInText
							m.iFieldCount = m.iFieldCount + 1
						endif
					else
						m.lInText = !m.lInText
					endif
				else
					if m.iFieldCount > alen(aSourceColumns)
						error BADVALUE_LOC
					else
						aSourceColumns[m.iFieldCount] = ;
							aSourceColumns[m.iFieldCount] + m.cChar
					endif
				endif
			endfor
		endif
	endproc
	
	procedure ConvertText
		* This procedure converts text file fields for insertion into the
		* target columns in the output file
		local i, cSourceType
		
		for m.i = 1 to alen(aColumnData, 1)
			m.cSourceType = type('aSourceColumns[aColumnData[m.i, 1]]')
			do case
				case m.cSourceType = aColumnData[m.i, 2] .or. ;
					(m.cSourceType $ 'NYFBI' .and. aColumnData[m.i, 2] $ 'NYFBI') .or. ;
					(m.cSourceType = 'C' .and. aColumnData[m.i, 2] = 'M') .or. ;
					(m.cSourceType = 'D' .and. aColumnData[m.i, 2] = 'T')
					* Source and target are the same type, or a numeric to numeric, 
					* or a character to a memo, or a date to a datetime
					* No conversion needed--move the field over unchanged
					aTargetColumns[aColumnData[m.i, 5]] = ;
						aSourceColumns[aColumnData[m.i, 1]]
				case m.cSourceType = 'C'
					do case
						case inlist(aColumnData[m.i, 2], 'N', 'Y', 'F', 'B', 'I')
							* convert to numeric
							aTargetColumns[aColumnData[m.i, 5]] = ;
								val(strtran(strtran(strtran( ;
								aSourceColumns[aColumnData[m.i, 1]], ;
								this.cSeparator), this.cCurrency), this.cPoint, '.'))
						case aColumnData[m.i, 2] = 'D'
							* convert to date
							* The SET DATE command was issued before beginning to import
							aTargetColumns[aColumnData[m.i, 5]] = ;
								ctod(aSourceColumns[aColumnData[m.i, 1]])
							if empty(aTargetColumns[aColumnData[m.i, 5]])
								if len(aSourceColumns[aColumnData[m.i, 1]]) = 8 .and. ;
									this.IsAllDigits(aSourceColumns[aColumnData[m.i, 1]])
									aTargetColumns[aColumnData[m.i, 5]] = ;
										ctod(substr(aSourceColumns[aColumnData[m.i, 1]], 5, 2) + '/' + ;
										substr(aSourceColumns[aColumnData[m.i, 1]], 7, 2) + '/' + ;
										left(aSourceColumns[aColumnData[m.i, 1]], 4))
								endif
							endif
						case aColumnData[m.i, 2] = 'T'
							* convert to a datetime
							aTargetColumns[aColumnData[m.i, 5]] = ;
								ctot(aSourceColumns[aColumnData[m.i, 1]])
							if empty(aTargetColumns[aColumnData[m.i, 5]])
								if len(aSourceColumns[aColumnData[m.i, 1]]) = 14 .and. ;
									this.IsAllDigits(aSourceColumns[aColumnData[m.i, 1]])
									aTargetColumns[aColumnData[m.i, 5]] = ;
										ctot(substr(aSourceColumns[aColumnData[m.i, 1]], 5, 2) + '/' + ;
										substr(aSourceColumns[aColumnData[m.i, 1]], 7, 2) + '/' + ;
										left(aSourceColumns[aColumnData[m.i, 1]], 4) + ' ' + ;
										substr(aSourceColumns[aColumnData[m.i, 1]], 9, 2) + ':' + ;
										substr(aSourceColumns[aColumnData[m.i, 1]], 11, 2) + ':' + ;
										right(aSourceColumns[aColumnData[m.i, 1]], 2))
								endif
							endif
						case aColumnData[m.i, 2] = 'L'
							* convert to a logical
							if upper(alltrim(aSourceColumns[aColumnData[m.i, 1]])) $ TRUEVALUES_LOC
								aTargetColumns[aColumnData[m.i, 5]] = .T.
							else
								aTargetColumns[aColumnData[m.i, 5]] = .F.
							endif
					endcase
				CASE aColumnData[m.i, 2] = 'L' AND TYPE("EMPTY(aSourceColumns[aColumnData[m.i, 1]])") == 'L'
					*- try to convert any value to logical: if empty, .F., otherwise, .T.
					aTargetColumns[aColumnData[m.i, 5]] = !EMPTY(aSourceColumns[aColumnData[m.i, 1]])
				otherwise
					* This shouldn't happen...
					THIS.cReturnToProc = ""
					THIS.Alert(C_UNSUPPORTEDCONVERSION_LOC)
					THIS.HadError = .T.
			endcase
		endfor
	endproc

	procedure IsAllDigits
		parameters cString
		for m.i = 1 to len(m.cString)
			if .not. isdigit(substr(m.cString, m.i, 1))
				return .f.
			endif
		endfor
		return .t.
	endproc

	procedure Destroy
		if type('this.ThermRef') = 'O'
			this.ThermRef = .NULL.
		endif
		
		release aColumnData, aSourceColumns, aTargetColumns
		
		WizEngineAll::Destroy
		
		if file(this.cOutputFile) .and. .not. this.lCancelled
			select 0
			use (this.cOutputFile)
		endif
	endproc
	
	procedure MakeFieldName
	parameters aRecord, i
	LOCAL j, idx, delta, poz, cIdx

		IF TYPE('aRecord(m.i)') <> 'C' OR EMPTY(aRecord(m.i))
			RETURN .f.
		ENDIF
		
		* allow only alpha and '_'
		aRecord(m.i) = LEFT(ALLTRIM(aRecord(m.i)), 10)
		IF !EMPTY(OS(2))	&& handle for DBCS
			IF ISLEADBYTE(RIGHT(aRecord(m.i),1))
				aRecord(m.i) = LEFT(aRecord(m.i),LEN(aRecord(m.i))-1)
			ENDIF
		ENDIF
		FOR m.j = 1 TO LENC(aRecord(m.i))
			cChar = SUBSTRC(aRecord(m.i), m.j, 1)
			if !(ISALPHA(cChar) OR (m.j > 1 AND (ISDIGIT(cChar) OR cChar == '_' )))
				aRecord(m.i) = STUFFC(aRecord(m.i), m.j, 1, IIF(m.j = 1, 'a', '_'))
			ENDIF
		ENDFOR
		
		idx = 1
		FOR m.j = 1 TO m.i - 1
			*- make sure that types are the same before we compare them
			IF TYPE("aRecord[m.j]") # TYPE("aRecord[m.i]")
				LOOP
			ENDIF
			if aRecord(m.j) = aRecord(m.i)
				cIdx = ALLTRIM(STR(idx))
				delta = LENC(cIdx)
				poz = min(LENC(aRecord(m.i)), 10 - delta) + 1
				aRecord(m.i) = STUFFC(aRecord(m.i), poz, delta, cIdx)
				idx = idx + 1
			ENDIF
		ENDFOR
		
		RETURN .t.
		
	endproc

	procedure ImportFile
		local cTempFile, i, cFieldList, iSelect, cType,  ;
			 lFieldName, cWorkSheet
		local array aTemp[1], aStruct[1]
		if empty(this.cTestCursor)
			this.cTestCursor = '_'+sys(3)
			do while used(this.cTestCursor)
				this.cTestCursor = '_'+sys(3)
			enddo
			create cursor (this.cTestCursor) (placeholder c(10))
		endif
		
		select 0
		
		m.cTempFile = '_' + left(sys(3),7) + ".*"
		do while .not. empty(adir(aTemp, m.cTempFile))
			m.cTempFile = '_' + left(sys(3),7) + ".*"
		enddo
				
		m.cType = upper((this.aFileTypes[this.iFileType, 2])) && IMPORT command TYPE keyword
		
		this.HadError = .f.
		this.SetErrorOff = .t.
		copy file (this.cSourceFile) to (this.forceext(m.cTempFile, ;
			this.aFileTypes[this.iFileType, 3]))
			
		if m.cType == 'PDOX' .and. file(this.forceext(this.cSourceFile, '.MB'))
			copy file (this.forceext(this.cSourceFile, '.MB')) to ;
				(this.forceext(m.cTempFile, '.MB'))
		endif
		
		this.SetErrorOff = .f.
		if this.HadError
			this.Alert(COPYFILEERROR_LOC, .f., .f., this.cSourceFile)
			return .f.
		endif

		* Numbers are rounded when SET POINT is not decimal
		* This occurs with Excel and Lotus sheets.
		local cPoint
		m.cPoint = set('point')
		set point to '.'
		
		* add worksheet clause for Excel
		cWorksheet = IIF(!EMPTY(this.cWorkSheet), 'SHEET "' + TRIM(this.cWorkSheet) + '"', '')

		this.HadError = .f.
		this.SetErrorOff = .t.
		import from ;
			(this.forceext(m.cTempFile, this.aFileTypes[this.iFileType, 3])) ;
			type &cType &cWorkSheet

		set point to (m.cPoint)
		
		this.SetErrorOff = .f.
		if this.HadError
			this.Alert(message())
			return .f.
		endif
		
		erase (this.forceext(m.cTempFile, this.aFileTypes[this.iFileType, 3]))

		if m.cType == 'PDOX' .and. file(this.forceext(this.cSourceFile, '.MB'))
			erase (this.forceext(m.cTempFile, '.MB'))
		endif
		
		=afields(aTemp)
		dimension aStruct[alen(aTemp, 1), 4]
		for m.i = 1 to alen(aTemp, 1)
			aStruct[m.i, 1] = aTemp[m.i, 1]
			aStruct[m.i, 2] = aTemp[m.i, 2]
			aStruct[m.i, 3] = aTemp[m.i, 3]
			aStruct[m.i, 4] = aTemp[m.i, 4]
		endfor
		
		* save field names from FieldNameRow
		IF this.iFieldNameRow >= 1 AND this.iFieldNameRow <= RECCOUNT()
			lFieldName = .t.
			go this.iFieldNameRow
			scatter memo to aRecord
		ELSE
			lFieldName = .f.
		ENDIF

		for m.i = 1 to alen(aStruct, 1)
			* Construct a list of fields with the fieldnames assigned by
			* the import command.
			* m.cFieldList = m.cFieldList + iif(empty(m.cFieldList), '', ', ') + ;
			*	aStruct[m.i, 1]
			* Change the name for consistency in the ImportWizard
			IF lFieldName AND this.MakeFieldName(@aRecord, m.i)
				aStruct[m.i, 1] = aRecord(m.i)
			ELSE
				aStruct[m.i, 1] = COLUMN_LOC + alltrim(str(m.i))
			ENDIF
		endfor

		m.iSelect = select()
		create cursor (this.cTestCursor) from array aStruct
		select (m.iSelect)

		scan
			scatter memo to aRecord
			insert into (this.cTestCursor) from array aRecord
		endscan
		use
		select (this.cTestCursor)
		go top
		
		* 
		erase (this.forceext(m.cTempFile, 'dbf'))
		erase (this.forceext(m.cTempFile, 'fpt'))
	endproc

	procedure CloseTextFile
		if .not. isnull(this.iTextHandle)
			* Close the file that was open previously
			=fclose(this.iTextHandle)
			this.iTextHandle = .NULL.
		endif
	endproc
				
	procedure OpenTextFile
		parameters cTextFileName
		local cFileName
		
		if .not. isnull(this.iTextHandle)
			* Close the file that was open previously
			=fclose(this.iTextHandle)
			this.iTextHandle = .NULL.
		endif
		
		* Open the source file
		this.iTextHandle = fopen(m.cTextFileName)
		if this.iTextHandle = -1
			this.iTextHandle = .NULL.
			m.cFileName = m.cTextFileName && FOPENERROR_LOC uses cFileName
			this.Alert(FOPENERROR_LOC)
		else
			this.AddHandleToCloseList(this.iTextHandle)
		endif					
	return (.not. isnull(this.iTextHandle))

	procedure EnableFieldTypes
		* This function enables or disables the fieldtype choices in the combobox in step 2
		* based on the type of field. These map to the conversions supported in ConvertText
		parameters cType
		do case
		case m.cType = 'C'
			* All types are supported
			this.aFieldTypes[1,1] = FTCHARACTER_LOC
			this.aFieldTypes[2,1] = FTCURRENCY_LOC
			this.aFieldTypes[3,1] = FTNUMERIC_LOC
			this.aFieldTypes[4,1] = FTFLOAT_LOC
			this.aFieldTypes[5,1] = FTDATE_LOC
			this.aFieldTypes[6,1] = FTDATETIME_LOC
			this.aFieldTypes[7,1] = FTDOUBLE_LOC
			this.aFieldTypes[8,1] = FTINTEGER_LOC
			this.aFieldTypes[9,1] = FTLOGICAL_LOC
			this.aFieldTypes[10,1] = FTMEMO_LOC
			this.aFieldTypes[11,1] = FTCHARACTERBIN_LOC
			this.aFieldTypes[12,1] = FTMEMOBIN_LOC
		case m.cType $ 'NYFBI'
			* Numeric to Numeric is supported
			this.aFieldTypes[1,1] = '\' + FTCHARACTER_LOC
			this.aFieldTypes[2,1] = FTCURRENCY_LOC
			this.aFieldTypes[3,1] = FTNUMERIC_LOC
			this.aFieldTypes[4,1] = FTFLOAT_LOC
			this.aFieldTypes[5,1] = '\' + FTDATE_LOC
			this.aFieldTypes[6,1] = '\' + FTDATETIME_LOC
			this.aFieldTypes[7,1] = FTDOUBLE_LOC
			this.aFieldTypes[8,1] = FTINTEGER_LOC
			this.aFieldTypes[9,1] = '\' + FTLOGICAL_LOC
			this.aFieldTypes[10,1] = '\' + FTMEMO_LOC
			this.aFieldTypes[11,1] = '\' + FTCHARACTERBIN_LOC
			this.aFieldTypes[12,1] = '\' + FTMEMOBIN_LOC
		case m.cType $ 'D'
			* date to date and date to datetime supported
			this.aFieldTypes[1,1] = '\' + FTCHARACTER_LOC
			this.aFieldTypes[2,1] = '\' + FTCURRENCY_LOC
			this.aFieldTypes[3,1] = '\' + FTNUMERIC_LOC
			this.aFieldTypes[4,1] = '\' + FTFLOAT_LOC
			this.aFieldTypes[5,1] = FTDATE_LOC
			this.aFieldTypes[6,1] = FTDATETIME_LOC
			this.aFieldTypes[7,1] = '\' + FTDOUBLE_LOC
			this.aFieldTypes[8,1] = '\' + FTINTEGER_LOC
			this.aFieldTypes[9,1] = '\' + FTLOGICAL_LOC
			this.aFieldTypes[10,1] = '\' + FTMEMO_LOC
			this.aFieldTypes[11,1] = '\' + FTCHARACTERBIN_LOC
			this.aFieldTypes[12,1] = '\' + FTMEMOBIN_LOC
		otherwise
			* no conversion supported
			this.aFieldTypes[1,1] = '\' + FTCHARACTER_LOC
			this.aFieldTypes[2,1] = '\' + FTCURRENCY_LOC
			this.aFieldTypes[3,1] = '\' + FTNUMERIC_LOC
			this.aFieldTypes[4,1] = '\' + FTFLOAT_LOC
			this.aFieldTypes[5,1] = '\' + FTDATE_LOC
			if m.cType = 'T'
				this.aFieldTypes[6,1] = FTDATETIME_LOC
			else
				this.aFieldTypes[6,1] = '\' + FTDATETIME_LOC
			endif
			this.aFieldTypes[7,1] = '\' + FTDOUBLE_LOC
			this.aFieldTypes[8,1] = '\' + FTINTEGER_LOC
			if m.cType = 'L'
				this.aFieldTypes[9,1] = FTLOGICAL_LOC
			else
				this.aFieldTypes[9,1] = '\' + FTLOGICAL_LOC
			endif
			if m.cType = 'M'
				this.aFieldTypes[10,1] = FTMEMO_LOC
				this.aFieldTypes[12,1] = FTMEMOBIN_LOC
			else
				this.aFieldTypes[10,1] = '\' + FTMEMO_LOC
				this.aFieldTypes[12,1] = '\' + FTMEMOBIN_LOC
			endif					
			this.aFieldTypes[11,1] = '\' + FTCHARACTERBIN_LOC
		endcase
	endproc
	
	procedure SetCodePage
	parameters iCodePage
		=SetWizardCodePage(m.iCodePage)
		this.iCodePage = m.iCodePage
	endproc
enddefine

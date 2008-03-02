******************************************************************************
* Used in ImportWizard (IMPORT.VCX)
******************************************************************************

#define C_DEBUG .F.

#define WIZARD_FLL_VERSION	3.01

#define STEP1_LOC		"Step 1 - Identify Data"
#DEFINE STEP1a_LOC		"Step 1a - Select a Database"
#define STEP2_LOC		"Step 2 - Determine Data Format"
#define STEP2A_LOC		"Step 2a - Describe Data"
#define STEP2A_ALT_LOC	"Step 2a - Set Columns"
#define STEP3_LOC		"Step 3 - Define Imported Fields"
#define STEP3_ALT_LOC	"Step 3 - Define Imported Fields"
#define STEP3a_LOC		"Step 3a - Specify International Options"
#define STEP4_LOC		"Step 4 - Finish"

#define DESC1_LOC ;
	"Where is the data you want to import. "+;
	"You can import data to a new table or append " + ;
	"it to an existing table." + ;
	chr(13)+chr(13)+ ;
	"Select a file type, and then use the Locate buttons to specify files."
	
#DEFINE DESC1A_LOC	"You can select a database in which to add your new table." +CHR(13)+CHR(13)+;
					"Also you can optionally choose a friendly name for your table. "

#define DESC2_LOC ;
	"What format is your data in?" +;
	chr(13)+chr(13)+;
	"Click Delimited if your fields are separated by a character, or click " + ;
	"Fixed Width if your fields are aligned in columns."
	
#define DESC2A_LOC ;
	"Which delimiter separates your fields?" + ;
	chr(13) + chr(13) + ;
	"Select the appropiate delimiter to see how your text is affected." + ;
	chr(13) + chr(13) + ;
	"You can also ignore consecutive delimiters, or specify how your text " + ;
	"strings are separated."
	

#define DESC2A_ALT_LOC ;
	"The wizard has set columns as shown. Click below the displayed data to add a column break. " + ;
	"Click and drag the column break to adjust it. To delete a column " + ;
	"break, drag it above the ruler."

*** NOTE *** NOTE *** NOTE *** NOTE ***
* The extra space before "heading;" is necessary--without it, word wrap orphans
* the semicolon at the beginning of the next line.
#define DESC3_LOC ;
	"How do you want to define the imported fields?" + ;
	chr(13)+chr(13)+ ;
	"Select a column by clicking below the heading, then specify " + ;
	"the field settings."

#define DESC3_ALT_LOC ;
	"The fields will be mapped as shown." + ;
	chr(13) + chr(13) + ;
	"To change the way a field is mapped, click " + ;
	"the desired column below the heading, and " + ;
	"select Unassigned Field or an available " + ;
	"field from the Name box."
	
#define DESC3A_LOC ;
	"Does your data contain international information? " + ;
	chr(13) + chr(13) + ;
	"Specify alternate settings below."


#define BITMAP1			"BMPS\IMPORT1.BMP"
#DEFINE BMPFILE1a		"BMPS\IMPORT1B.BMP"
#define BITMAP2			"BMPS\IMPORT1.BMP"
#define BITMAP2A		"BMPS\IMPORT1.BMP"
#define BITMAP2A_ALT	"BMPS\IMPORT1A.BMP"
#define BITMAP3			"BMPS\IMPORT2N.BMP"
#define BITMAP3A		"BMPS\IMPORT2N.BMP"

#DEFINE HELP_wizTable_Wizard_Step_1a	1999935400

#define FLLREQUIRED_LOC ;
	"The Import Wizard requires WIZARD.FLL. Place WIZARD.FLL in your " + ;
	sys(2004) + "WIZARDS directory and try again."
	
#define UNASSIGNED_LOC	"Unassigned Field"

#define SOURCEFILE_LOC	"Select file to import:"

#define SAVEAS_LOC	"Save new table as:"

#define APPENDTO_LOC	"Table to append to:"

#define ILLEGALCHAR_LOC	"Field names must begin with a letter and may " + ;
	"contain A-Z, 0-9, and _."

#define KP_BACKSPACE	127
#define KP_TAB			9
#define KP_ENTER		13
#define KP_ESCAPE		27
#define KP_LEFTARROW	19
#define KP_RIGHTARROW	4
#define KP_UPARROW		5
#define KP_DOWNARROW	24
#define KP_DELETE		7
#define KP_HOME			1
#define KP_END			6
#define KP_INSERT		22

#define KP_SHIFT_HOME	55
#define KP_SHIFT_END	49
#define KP_SHIFT_TAB	15

#define FIELDNAMEINUSE_LOC ;
	"Fieldname " + '"' + alltrim(this.Value) + '"' + " is already in use. Enter a different name."

******************************************************************************
* Used in ImportWizardOptions (IMPORT.VCX)
******************************************************************************

#define ERRORTITLE_LOC		"Microsoft Visual FoxPro Wizards"

#define ERRORMESSAGE_LOC ;
	"Error #" + alltrim(str(m.nError)) + " in " + m.cMethod + ;
	" (" + alltrim(str(m.nLine)) + "): " + m.cMessage

* The result of the above message will look like this:
*
*		Error #1 in WIZTEMPLATE.INIT (14): File does not exist.

#ifndef MB_ICONEXCLAMATION
	#define MB_ICONEXCLAMATION		48
#endif
#ifndef MB_ABORTRETRYIGNORE
	#define MB_ABORTRETRYIGNORE		2
#endif
#ifndef MB_OK
	#define MB_OK					0
#endif
#ifndef MB_YESNO
	#DEFINE MB_YESNO                4
#endif

#define DEFAULTTITLE_LOC	"Microsoft Visual FoxPro Wizards"

#define CPMESSAGE_LOC	"In what code page was the text file created?"
#define CPTITLE_LOC		"Import Wizard"

#define LOGFILEERROR_LOC	" failed. Event logging disabled."

******************************************************************************
* Used in ImportEngine (IWPROC.PRG)
******************************************************************************

* The following strings are used in the Type combobox in the
* Import Wizard. They need to match the #define's found in the
* Import Wizard's WizTemplate.Load snippet.
#define FTCHARACTER_LOC		"Character"
#define FTDATE_LOC			"Date"
#define FTLOGICAL_LOC		"Logical"
#define FTMEMO_LOC			"Memo"
#define FTNUMERIC_LOC		"Numeric"
#define FTFLOAT_LOC			"Float"
#define FTCURRENCY_LOC		"Currency"
#define FTDOUBLE_LOC		"Double"
#define FTDATETIME_LOC		"DateTime"
#define FTINTEGER_LOC		"Integer"
#define FTSKIP_LOC			"Skip Field"
#define FTCHARACTERBIN_LOC	"Character (binary)"
#define FTMEMOBIN_LOC		"Memo (binary)"

* The following strings are used in the File Type combobox in the
* Import Wizard.
#define FTTEXT_LOC			"Text File"
#define FTEXCEL_LOC			"Microsoft Excel 2.0, 3.0, 4.0 (XLS)"
#define FTEXCEL5_LOC		"Microsoft Excel 5.0 and 97 (XLS)"
#define FTMULTIPLAN_LOC		"Multiplan 4.1 (MOD)"
#define FTLOTUS2_LOC		"Lotus 1-2-3 2.x (WK1)"
#define FTLOTUS3_LOC		"Lotus 1-2-3 3.x (WK3)"
#define FTLOTUS1_LOC		"Lotus 1-2-3 1-A (WKS)"
#define FTSYMPHONY110_LOC	"Symphony 1.10 (WR1)"
#define FTSYMPHONY101_LOC	"Symphony 1.01 (WRK)"
#define FTPARADOX_LOC		"Paradox 3.5, 4.0 (DB)"
#define FTRAPIDFILE_LOC		"RapidFile (RPD)"

* These strings are used in the Text Qualifier combobox in the
* Import Wizard Options dialog.
#define TQDOUBLE_LOC	"Double Quotation Marks"
#define TQSINGLE_LOC	"Single Quotation Marks"
#define TQNONE_LOC		"<None>"

* Error messages used in ImportWizard.SampleInput
#define FOPENERROR_LOC		"An error occurred opening &cFileName.."
#define NOFIELDS_LOC		"No fields were defined for importing."

* Messages used by import progress thermometer
#define THERMPROGRESS_LOC	"Record #" + alltrim(str(m.iRecno))
#define THERMMSG_LOC		"Importing file " + lower(this.cSourceFile)

* Message used in AnalyzeFileType method
#define UNRECOGNIZEDFILETYPE_LOC ;
	"The records in this file do not appear to be delimited by commas " + ;
	"or tabs and the record-lengths are variable. Fixed-length format " + ;
	"will be used by default."

* Miscellaneous Error Messages
#define RESETBEGINNINGROW_LOC ;
	"The beginning row you specified is larger than the number of records found " + ;
	"in the text file. The beginning row has been reset to one."
	
#define C_MAXFIELDS 255	&& maximum number of fields allowed in a table

#define C_MAXTEXTLENGTH 8192 && maximum length of a record in a text file
* old value of 32750 changed due to FGETS SP3 limit

#define WIZARDFLL_LOC	"Wizard.fll?"

#define FILENOTFOUND_LOC "File &cParameter1 not found."

#define COPYFILEERROR_LOC "An error occurred making a temporary copy of &cParameter1.."

#define BADOUTPUTNAME_LOC "The output file cannot overwrite the source file."

#define BADAPPENDNAME_LOC "The append file and source file cannot be the same."

#define TOOMANYFIELDS_LOC ;
	"You have specified the maximum number of fields allowed in a table."

* This string is used to convert CHARACTER to LOGICAL. The string is 
* upper-cased and trimmed before comparison.
#define TRUEVALUES_LOC ".T. T TRUE Y YES"

#define CANNOTDBCCHECK_LOC ;
	"An error occurred attempting to open the file to verify " + ;
	"that it is not associated with a database. Overwrite not " + ;
	"permitted."
	
#define DBFINDBC_LOC ;
	"&cParameter1 is associated with a database. Overwrite not " + ;
	"permitted."

#define C_ESCAPEMESSAGE_LOC "Press <ESC> to cancel."

#define C_CANCELVERIFY_LOC "Cancel import?"

#define C_CANCELLED_LOC "Import cancelled."

#define BADVALUE_LOC "Invalid value encountered."

* This error should never occur...
#define C_UNSUPPORTEDCONVERSION_LOC "An unsupported conversion was attempted."	

#define E_NOSUPPORTEDFIELDS_LOC ;
	"The Import Wizard cannot import records into this table--all of the " + ;
	"fields have unsupported field types."

#define COLUMN_LOC "Column"

#define BEYONDENDOFRECORD_LOC ;
	"You have clicked beyond the last column of characters--column delimiters may " + ;
	"only be defined between the columns of characters read from the text file."

#define E_OPENAPPEND_LOC ;
	"Error " + alltrim(str(error())) + " (" + message() + ") occurred opening " + ;
	oEngine.cAppendFile + "."
#define E_CREATETABLE_LOC ;
	"Error " + alltrim(str(error())) + " (" + message() + ") occurred creating " + ;
	oEngine.cOutputFile + "."

#DEFINE C_DBCNAME_LOC		"DBC name:"
#DEFINE C_DEFDBCNAME_LOC	"Untitled.DBC"
#DEFINE C_DBEXCL_LOC		"The current database must be opened EXCLUSIVE for the new table to be added to it. " 
							"A free table will be created instead. Do you want to continue?"
#DEFINE C_DBEXCL2_LOC		" must be opened EXCLUSIVE before new tables can be added to it. " 
#DEFINE C_NEWTABLENAME_LOC	"The table name has been changed due to a duplicate name in the database. The new name will be "
#DEFINE C_CHECKINGEXCEL_LOC	"Checking Excel file for multiple worksheets..."							
					
#DEFINE C_OTHERTBL1_LOC		"The current database already has a table named "
#DEFINE C_OTHERTBL2_LOC		"Please use another name."

* These strings are used in the delimiter types dropdown in the Options dialog
#define DT_COMMAS_LOC "Commas"
#define DT_TABS_LOC "Tabs"
#define DT_SEMICOLONS_LOC "Semicolons"
#define DT_SPACE_LOC "Space"
#define DT_OTHER_LOC "Other"

* These strings are used in the aDataFormats array, which is used in the Date Format
* dropdown in the Options dialog. These strings are localized so that the ordering
* of the date formats in the dropdown may be changed. The pairing of these strings
* must be maintained. The content of the strings should not need to change.
#define DF_FORMAT1_LOC		"mm/dd/yy"
#define DF_KEYWORD1_LOC		"AMERICAN MDY"
#define DF_FORMAT2_LOC		"mm-dd-yy"
#define DF_KEYWORD2_LOC		"USA"
#define DF_FORMAT3_LOC		"dd/mm/yy"
#define DF_KEYWORD3_LOC		"BRITISH FRENCH DMY"
#define DF_FORMAT4_LOC		"dd-mm-yy"
#define DF_KEYWORD4_LOC		"ITALIAN"
#define DF_FORMAT5_LOC		"dd.mm.yy"
#define DF_KEYWORD5_LOC		"GERMAN"
#define DF_FORMAT6_LOC		"yy/mm/dd"
#define DF_KEYWORD6_LOC		"JAPAN YMD"
#define DF_FORMAT7_LOC		"yy.mm.dd"
#define DF_KEYWORD7_LOC		"ANSI"

#define DATAVALIDATIONERROR_LOC ;
	"Error: " + this.cMessage + " Do you want to ignore this error " + ;
	"and continue appending records?"

#define APPENDABORT_LOC "Append aborted."

#define EMPTYFILE_LOC "The import file you selected is empty."

#define WIZARDVERERROR_LOC "WIZARD.FLL is wrong version."

#define FIELDNAMETOOLONG_LOC "Field names cannot exceed 10 characters in length."
#define CANNOTRETRIVEXLS_LOC	"Unable to retrieve information from Excel."


*- Excel worksheet formats
#DEFINE	xlExcel2			16 
#DEFINE	xlExcel2FarEast		27 
#DEFINE	xlExcel3			29 
#DEFINE	xlExcel4			33 
#DEFINE	xlExcel4Workbook	35 
#DEFINE	xlExcel5			39 
#DEFINE	xlExcel7			39 
#DEFINE	xlExcel9795			43 
#DEFINE xlWorkbookNormal	-4143 

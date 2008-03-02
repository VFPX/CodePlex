*
* Directives for RPTWIZ.PRG and ReportWizard UI
*

* Operating Systems as defined in WZENGINE.PRG
#DEFINE	OS_W32S				1
#DEFINE	OS_NT				2
#DEFINE	OS_WIN95			3
#DEFINE	OS_MAC				4
#DEFINE	OS_DOS				5
#DEFINE	OS_UNIX				6


** Output Actions
* Preview, Save & Exit, Modify, Run
#define  GO_PREVIEW  0         
#define  GO_SAVE     1         
#define  GO_MODIFY   2         
#define  GO_RUN      3         

** Index into aWizGroups array
#define  GRP_FIELD   1
#define  GRP_MODDESC 2
#define  GRP_MODCODE 3
#define  GRP_LENGTH  4

** Index into aWizGrpExpr array
#define  MOD_GRPEXPR 1
#define  MOD_RPTEXPR 2
#define  MOD_CDXEXPR 3
#define  MOD_TXTWID  4

** Layout: horizontal or vertical
#define  RPT_LAYHORZ 1
#define  RPT_LAYVERT 2

** Offsets into AFIELDS() array
#define FLD_NAME     1
#define FLD_TYPE     2
#define FLD_LEN      3
#define FLD_DEC      4


** Report FRX objtypes
#define OT_HEADER    1
#define OT_DBF       2
#define OT_INDEX     3
#define OT_RELATION  4
#define OT_LABEL     5
#define OT_LINE      6
#define OT_BOX       7
#define OT_GET       8
#define OT_BAND      9
#define OT_GROUP     10
#define OT_PICTURE   17
#define OT_VAR       18
#define OT_FONT      23
#define OT_DATAENV   25
#define OT_DERECORD  26


** Report FRX band objcodes (objtype=9)
#define OC_TITLE     0
#define OC_PGHEAD    1
#define OC_COLHEAD   2
#define OC_GRPHEAD   3
#define OC_DETAIL    4
#define OC_GRPFOOT   5
#define OC_COLFOOT   6
#define OC_PGFOOT    7
#define OC_SUMMARY   8


** FRX field numbers for arrays
#define A_PLATFORM   1
#define A_ID         2
#define A_TSTAMP     3
#define A_OBJTYPE    4
#define A_OBJCODE    5
#define A_NAME       6
#define A_EXPR       7
#define A_VPOS       8
#define A_HPOS       9
#define A_HEIGHT     10
#define A_WIDTH      11
#define A_PICTURE    13
#define A_UNIQUE     15
#define A_COMMENT    16
#define A_ENVIRONS   17
#define A_FILLCHAR   19
#define A_TAG        20
#define A_TAG2       21
#define A_FONTFACE   31
#define A_FONTSTYLE  32
#define A_FONTSIZE   33
#define A_STRETCH    41
#define A_TOP        43
#define A_BOTTOM     44
#define A_NOREPEAT   47
#define A_PLAIN      59
#define A_OFFSET     62
#define A_TOTALTYPE  65
#define A_RESETTOTAL 66
#define A_SUPALWAYS  69
#define A_SUPRPCOL   71
#define A_SUPGROUP   72
#define A_SUPVALCHNG 73
#define A_SUPEXPR    74


* Miscellaneous constants

*- Total Types
#DEFINE I_TOTAL_NONE		0	&& no total
#DEFINE I_TOTAL_COUNT		1
#DEFINE I_TOTAL_SUM			2
#DEFINE I_TOTAL_AVG			3
#DEFINE I_TOTAL_MIN			4
#DEFINE I_TOTAL_MAX			5
#DEFINE	I_TOTAL_PCT			6

* max field length before we make it a memo field
#define RPT_MAXCHAR   60           

* Number of printer points per pixel
#define RPT_PTPERPIX		104.16666    
#define RPT_PTPERPIX_MAC	138.88888		&& different value for Mac

* Additional width for field to display
#define RPT_KLUDGE    1000         

* Adjustment for width on multiple column reports  
#define RPT_WIDTHADJ  1500         

* Space between columns
#define RPT_COLSEP    1000         

* Offset taken up by band dividers
#define WZ_BASEBAND   2083.333     

* When we look for elements within bands
* give us a cushion so we don't _barely_ miss any
#define RPT_CUSHION   20           
                                   
#define NEWLINE  CHR(13)+CHR(10)
#DEFINE C_TAB	CHR(9)

* Data types
#define DT_NUM    'N'
#define DT_FLOAT  'F'
#define DT_LOGIC  'L'
#define DT_MEMO   'M'
#define DT_GEN    'G'
#define DT_CHAR   'C'
#define DT_DATE   'D'
#define DT_MONEY  'Y'
#define DT_TIME   'T'
#define DT_DOUBLE 'B'
#define DT_INT    'I'

#define DT_INTEGER		'I'
#define DT_CURRENCY		'Y'
#define DT_DATETIME		'T'

#define DT_BLOB     	'W'
#define DT_VARCHAR		'V'
#define DT_VARBINARY	'Q'


* Label Engine constants
#IFNDEF LBL_DELIMITER
	#DEFINE LBL_DELIMITER    IIF("00"$VERSION(3),CHR(0),'+')
#ENDIF
#IFNDEF LBL_TEXT
	#DEFINE LBL_TEXT         IIF("00"$VERSION(3),CHR(1),'=')
#ENDIF

** Style comment triggers -- don't localize
#define C_TITLE     ["TITLE"]
#define C_FLD       'WIZ_FIELD'
#define C_1MFLD     'WIZ_1MANY'
#define C_LBL       'WIZ_LABEL'
#define C_1MLBL     'WIZ_PARENT'
#define C_MEMO      'WIZ_MEMO'
#define C_GEN       'WIZ_GEN'
#define C_GRP       'WIZ_GROUP'
#define C_HSTRETCH  'WIZ_HSTRETCH'
#define C_HDIVIDER  'WIZ_HDIVIDER'
#define C_VDIVIDER  'WIZ_VDIVIDER'
#define C_1MANY     'WIZ_1MANY'
#define C_UPPER     'WIZ_UPPER'
#define C_LOWER     'WIZ_LOWER'
#define C_PROPER    'WIZ_PROPER'
#define C_GRPBAND   'GROUP'
#define C_1MANYBAND 'MANY'
#define C_PAGE      'WIZ_PAGE'

* The following are used to find style properties.
#define SKIP_EXPR      [WIZ_MEMO WIZ_FIELD WIZ_GROUP WIZ_1MANY "WIZ_LBL" "WIZ_1MLBL"]
#define SKIP_COMMENT   [WIZ_VDIVIDER WIZ_HDIVIDER]
#define SKIP_NAME      [WIZ_GENERAL]

#DEFINE WIZ_PREFIX  'WIZ_'

*** LOCALIZATION STRINGS FOLLOW ***
*** --------------------------- ***

#define SUBTOT_LOC      "Subtotal for "
#define GRANDTOT_LOC    "Total:"
#define TOTAL_LOC       "Total:"

#define SUBPCT_LOC      "Pct of subtotal:"
#define GRANDPCT_LOC    "Pct of total:"
#define PCT_LOC			"Pct of total:"

#define SUBCNT_LOC      "Count for "
#define GRANDCNT_LOC    "Total Count:"
#define COUNT_LOC       "Count:"

#define SUBAVG_LOC      "Average for "
#define GRANDAVG_LOC    "Average:"
#define AVG_LOC       	"Average:"

#define SUBMIN_LOC      "Lowest for "
#define GRANDMIN_LOC    "Lowest:"
#define MIN_LOC       	"Lowest:"

#define SUBMAX_LOC      "Highest for "
#define GRANDMAX_LOC    "Highest:"
#define MAX_LOC       	"Highest:"

#define PAGEDESC_LOC    "Page"
#define BADPARMS_LOC    "Invalid parameters passed."

#define KEYTOOLONG_LOC  "Index key value is too long."
#define FILEINUSE_LOC   "File is in use."

#DEFINE C_RESETCOL_LOC	"With grouping, only one column is allowed and the report must be in column format. These options have been reset."

#DEFINE C_DEFAULTREPORT_LOC		"MyReport.FRX"
#DEFINE C_DEFAULTLABEL_LOC		"MyLabel.LBX"

#define ERR_NOFILE_LOC    "Style file not found:"
#define ERR_NOSTYLE_LOC   "No style file specified."
#define ERR_NOHEADER_LOC  "Invalid report style: Missing header record."
#define ERR_NOENVIRON_LOC "Invalid report style: Missing environment record."
#define ERR_NODETAIL_LOC  "Invalid report style: Missing detail line."
#define ERR_NOMEMO_LOC    "Invalid report style: Missing memo field template."
#define ERR_NOGENERAL_LOC "Invalid report style: Missing general field template."
#define ERR_NOFIELD_LOC   "Invalid report style: Missing field template."
#define ERR_NOLABEL_LOC   "Invalid report style: Missing label template."
#define ERR_NEGATIVE_LOC  "Invalid report style: Negative offset in style."
#define ERR_NOLBL_LOC     "Label data not specified."

#define ERR_EXCLUSIVE_LOC "Unable to open table exclusive."


* Valid paper sizes - TO-DO: get these programmatically 
#define PAPER_LTR_LOC  "Letter"     
#define PAPER_LGL_LOC  "Legal"      
#define PAPER_LGR_LOC  "Ledger"     
#define PAPER_A4_LOC   "A4"         


#define PORTRAIT_LOC      "Portrait"
#define LANDSCAPE_LOC     "Landscape"


#define SAVEAS_LOC        "Save report as:"
#define SAVELBL_LOC       "Save label as:"



* Messages used by report progress thermometer
#define THERM_MSG_LOC       "Creating report file"
#define THERM_PROGRESS_LOC  ""
#DEFINE THERM_STYLE_LOC	 	"Reading style data..."
#DEFINE THERM_CREATE_LOC    "Creating report..."
#DEFINE THERM_INDEX_LOC		"Adding data environment..."
#DEFINE THERM_DETAIL_LOC	"Adding fields to report..."
#DEFINE THERM_FORMAT_LOC	"Formatting report..."

#define THERM_LBLMSG_LOC    "Creating label file"
#DEFINE THERM_LBLCREATE_LOC "Creating label..."
#DEFINE THERM_LBLDETAIL_LOC	"Adding fields to label..."
#DEFINE THERM_LBLFORMAT_LOC	"Formatting label..."

#DEFINE THERM_RPTTITLE_LOC  "Report Wizard"
#DEFINE THERM_GRPTITLE_LOC  "Group/Total Report Wizard"
#DEFINE THERM_1MTITLE_LOC   "One-To-Many Report Wizard"

#DEFINE C_EXCLUSIVE_LOC		"EXCLUSIVE"

#DEFINE N_MINLEFTMARGINENG		2500.00
#DEFINE N_MINLEFTMARGINMET		2500.00

*- labels for grouping intervals
#DEFINE I_ARR_CHAR_SZ		6
#DEFINE C_CHAR_1_LOC			"Entire Field"
#DEFINE C_CHAR_2_LOC			"1st Letter"
#DEFINE C_CHAR_3_LOC			"2 Initial Letters"
#DEFINE C_CHAR_4_LOC			"3 Initial Letters"
#DEFINE C_CHAR_5_LOC			"4 Initial Letters"
#DEFINE C_CHAR_6_LOC			"5 Initial Letters"

#DEFINE I_ARR_DATE_SZ		6
#DEFINE C_DATE_1_LOC			"Date"
#DEFINE C_DATE_2_LOC			"Day of Week"
#DEFINE C_DATE_3_LOC			"Week"
#DEFINE C_DATE_4_LOC			"Month"
#DEFINE C_DATE_5_LOC			"Quarter"
#DEFINE C_DATE_6_LOC			"Year"

#DEFINE I_ARR_NUM_SZ		7
#DEFINE C_NUM_1_LOC			"Exact Number"
#DEFINE C_NUM_2_LOC			"10s"
#DEFINE C_NUM_3_LOC			"100s"
#DEFINE C_NUM_4_LOC			"1000s"
#DEFINE C_NUM_5_LOC			"10,000s"
#DEFINE C_NUM_6_LOC			"100,000s"
#DEFINE C_NUM_7_LOC			"1,000,000s"

#DEFINE I_ARR_TIME_SZ		10
#DEFINE C_TIME_1_LOC			"Date and Time"
#DEFINE C_TIME_2_LOC			"Date"
#DEFINE C_TIME_3_LOC			"Time"
#DEFINE C_TIME_4_LOC			"Day of week"
#DEFINE C_TIME_5_LOC			"Week"
#DEFINE C_TIME_6_LOC			"Month"
#DEFINE C_TIME_7_LOC			"Quarter"
#DEFINE C_TIME_8_LOC			"Year"
#DEFINE C_TIME_9_LOC			"Hour"
#DEFINE C_TIME_10_LOC			"Minute"

#DEFINE I_ARR_LOGIC_SZ		1
#DEFINE C_LOGIC_1			"Normal"

*- code that is inserted into DataEnvironment for supporting percent of total
*- do not localize
#DEFINE C_PROCSTART			"PROCEDURE @1" + NEWLINE
#DEFINE C_DECODE_A1			"LOCAL cOldTalk, cSaveDBC, nSaveData, cDBCName, nTotDBCs" + NEWLINE + ;
							"LOCAL ARRAY aDBCs[1,1]" + NEWLINE + ;
							NEWLINE
#DEFINE C_DECODE_A1A		"RELEASE _wztotals" + NEWLINE			
#DEFINE C_DECODE_A2			"PUBLIC ARRAY _wztotals[%1]" + NEWLINE
#DEFINE C_DECODE_A3			"cOldTalk = SET([TALK])" + NEWLINE + ;
							"SET TALK OFF" + NEWLINE + ;
							"nSaveData = SELECT()" + NEWLINE + ;
							"SELECT 0" + NEWLINE + ;
							"cSaveDBC = SET([DATABASE])" + NEWLINE + ;
							"nTotDBCs = ADATA(aDBCs)" + NEWLINE + ;
							"cDBCName = UPPER(THIS.Cursor1.Database)" + NEWLINE + ;
							"IF !EMPTY(m.cDBCName)" + NEWLINE + ;
							C_TAB + "OPEN DATABASE (m.cDBCName)" + NEWLINE + ;
							"ENDIF" + NEWLINE + ;
							"USE (THIS.Cursor1.CursorSource) AGAIN" + NEWLINE
#DEFINE C_DECODE_A4			"SUM %1 TO ARRAY _wztotals" + NEWLINE
#DEFINE C_DECODE_A5			"USE" + NEWLINE + ;
							"SELECT (m.nSaveData)" + NEWLINE + ;
							"IF !EMPTY(m.cDBCName) AND (nTotDBCs=0 OR ASCAN(aDBCs,m.cDBCname)=0)" + NEWLINE + ;
							C_TAB + "CLOSE DATA" + NEWLINE + ;
							"ENDIF" + NEWLINE + ;
							"IF !EMPTY(m.cSaveDBC)" + NEWLINE + ;
							C_TAB + "SET DATABASE TO (m.cSaveDBC)" + NEWLINE + ;
							"ELSE" + NEWLINE + ;
							C_TAB + "SET DATABASE TO" + NEWLINE + ;
							"ENDIF" + NEWLINE + ;
							NEWLINE + ;
							"SET TALK &cOldTalk" + NEWLINE
#DEFINE C_PROCEND			"ENDPROC" + NEWLINE


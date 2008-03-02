
*
* Directives for ReportWizard UI
*

* Help topic ID
*- help codes
#define HELP_wizLabel_Wizard_Step_5  95825531
#define HELP_wizLabel_Wizard_Step_4  95825530
#define HELP_wizLabel_Wizard_Step_3  95825529
#define HELP_wizLabel_Wizard_Step_2  95825528
#define HELP_wizLabel_Wizard_Step_1  95825527
#define HELP_wizLabel_Wizard		 95825526

#define  HELP_ID  HELP_wizLabel_Wizard	&& 1895825416

* Localization strings for the Report Wizard UI
*
#define STEP1_LOC 'Step 1 - Select Tables'
#define STEP2_LOC 'Step 2 - Choose Label Type'
#define STEP3_LOC 'Step 3 - Define Layout'
#define STEP4_LOC 'Step 4 - Sort Records'
#define STEP5_LOC 'Step 5 - Finish'

#define HINT1_LOC ""
#define HINT2_LOC ""
#define HINT3_LOC ""
#define HINT4_LOC ""
#define HINT5_LOC ""


#define RPT_BMP1 'BMPS\OPENTABL.BMP'
#define RPT_BMP2 'BMPS\LBL_TYPE.BMP'
#define RPT_BMP3 'BMPS\BLANK.BMP'
#define RPT_BMP4 'BMPS\NEWSORT.BMP'
#define RPT_BMP5 'BMPS\FLAG.BMP'



#define DESC1_LOC "Which table do you want to use?" + CHR(13)+CHR(13)+ ;
				  "Select a database or Free Tables item, and then select the table or view you want."


#define DESC2_LOC "Which type of label would you like?"

#define DESC3_LOC "How do you want your labels to look?" + CHR(13) + CHR(13) + ;
                  "Select the fields, and use buttons to add " + ;
                  "punctuation and line breaks. To add text, use the text box."


#define DESC4_LOC "How do you want to sort your records?"+CHR(13)+CHR(13)+ ;
                  "Select up to three fields or select one index tag to sort the records by."

#define DESC5_LOC ""


#define SAVE_LOC "Save label as:"

#DEFINE LBLREGKEY 	"Software\Microsoft\VisualFoxPro\9.0\Labels"
#DEFINE LBLREGKEY1  "Software\Microsoft\VisualFoxPro\"
#DEFINE LBLREGKEY2  "\Labels"

#DEFINE HKEY_CURRENT_USER  -2147483647  && BITSET(0,31)+1
#DEFINE NOLABELS_LOC	"There was a problem getting labels from Registry. Run the ADDLABEL program to register them."

* References into our pages
#define PAGE_DATA     1
#define PAGE_LABEL    2
#define PAGE_LAYOUT   3
#define PAGE_SORT     4
#define PAGE_FINISH   5


#DEFINE DT_NUMERIC  	'N'
#DEFINE DT_FLOAT 	 	'F'
#DEFINE DT_LOGIC 		'L'
#DEFINE DT_MEMO  		'M'
#DEFINE DT_GENERAL  	'G'
#DEFINE DT_CHAR  		'C'
#DEFINE DT_DATE  		'D'

#DEFINE LBL_MAXLINES    20          && max lines per label
#DEFINE LBL_RATIO       4           && ratio of actual height to what we're displaying
                                    && ie RealValue/LBL_RATIO

#DEFINE PIX_VLBL        50          && default vpos for label
#DEFINE PIX_HLBL        55          && default hpos for label
#DEFINE PIX_PERINCH     100         && Pixels per inch
#DEFINE PIX_BKHOFFSET   1           && Horizontal drop shadow offset
#DEFINE PIX_BKVOFFSET   1           && Vertical drop shadow offset

#DEFINE PIX_RATIO       PIX_PERINCH/LBL_RATIO


#DEFINE LBL_NEWLINE      REPLICATE(IIF("00"$VERSION(3),CHR(249),'-'),50)
#DEFINE LBL_COMMA        "," 
#DEFINE LBL_DOT          "."
#DEFINE LBL_COLON        ":"
#DEFINE LBL_DASH         "-"
#DEFINE LBL_SHOWNEW      REPLICATE(".",50)
#DEFINE LBL_WINSPACE     IIF("00"$VERSION(3),CHR(183),'-')
#DEFINE LBL_MACSPACE     CHR(250)
#DEFINE LBL_DOSSPACE     CHR(161)


#DEFINE LBL_DELIMITER    IIF("00"$VERSION(3),CHR(0),'+')
#DEFINE LBL_TEXT         IIF("00"$VERSION(3),CHR(1),'=')

#define LBL_MAXWIDTH     260

* If you change the following, make sure you change the style file as well!
#DEFINE LBL_FONTFACE     "ARIAL"
#DEFINE LBL_FONTSIZE     8
#DEFINE LBL_FONTSTYLE    "N"

#DEFINE LBL_OBJHEIGHT    16.0
#DEFINE LBL_OBJKLUDGE    .05


#DEFINE SHOW_EMPTY 1
#DEFINE SHOW_TEXT  2
#DEFINE SHOW_FIELD 3


#define ERR_MAXLINES_LOC "The maximum number of lines per label is 20."
#define ERR_NOTDONE_LOC  "Feature not implemented."
#define ERR_MAXWIDTH_LOC "No more fields may be added to this label line."

* Maximum length of a string in the free-form entry text box of lblbuilder
#define N_TEXTLEN	100

#define C_DBCEXCL_LOC     "The DBC containing the selected table was previously opened " + ;
                          "non-exclusively and the field(s) you chose for sorting are not in " + ;
                          "an existing index tag. Please select field(s) which already have " + ;
                          "an existing index tag or exit the wizard and reopen the DBC exclusively."


*- Maybe need to be localized
#DEFINE C_ADDLABELPATH		"TOOLS\ADDLABEL\"				&& install location of ADDLABEL.APP (off of HOME())
#DEFINE C_ADDLABELAPPNAME	"AddLabel.APP"					&& name of AddLabel app
#DEFINE C_APPEXT_LOC			"Applications:APP;Programs:PRG"	&& extensions for GETFILE()
#DEFINE C_ADDLABELPROMPT_LOC	"Where is AddLabel.App?"		&& prompt for GETFILE()
#DEFINE C_MISSINGLBLS_LOC		"The Label Wizard needs to install default label definitions. This operation is only performed the first time you run the wizard."
#DEFINE C_MISSINGLBLS2_LOC		"Some or all of your default label definitions are missing from the Registry. The Label Wizard will install these for you."
#DEFINE C_NOLABELSREF_LOC		"The Label Wizard could not locate the TOOLS\ADDLABEL\LABELS.REG file "+;
								"to install the default label definitions. You need to locate it manually "+;
								"and double-click on it in the Windows Explorer."
#DEFINE	FILE_LABELSREG			"TOOLS\ADDLABEL\LABELS.REG"

*- OLE Drag-Drop constants (from FOXPRO.H)
#DEFINE DRAG_ENTER				0
#DEFINE DRAG_LEAVE				1
#DEFINE DRAG_OVER				2

#DEFINE DROPHASDATA_USEFUL		1

#DEFINE DROPEFFECT_COPY			1
#DEFINE DROPEFFECT_MOVE			2

#DEFINE	CFSTR_OLEVARIANTARRAY	"OLE Variant Array"

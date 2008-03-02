*
* Directives for Group Report Wizard UI
*

* Help Topic ID


*- new help codes
#define HELP_wizGroupSlTotal_Report_Wizard_Step_5    95825525
#define HELP_wizGroupSlTotal_Report_Wizard_Step_4    95825524
#define HELP_wizGroupSlTotal_Report_Wizard_Step_3    95825523
#define HELP_wizGroupSlTotal_Report_Wizard_Step_2    95825522
#define HELP_wizGroupSlTotal_Report_Wizard_Step_1    95825521
#define HELP_wizGroupSlTotal_Report_Wizard			 95825520

#define  HELP_ID  HELP_wizGroupSlTotal_Report_Wizard  && 1895825414

* Localization strings for the Report Wizard UI
*
#define STEP1_LOC 'Step 1 - Select Fields'
#define STEP2_LOC 'Step 2 - Group Records'
#define STEP3_LOC 'Step 3 - Sort Records'
#define STEP4_LOC 'Step 4 - Choose Report Style'
#define STEP5_LOC 'Step 5 - Finish'

#define HINT1_LOC ""
#define HINT2_LOC ""
#define HINT3_LOC ""
#define HINT4_LOC ""
#define HINT5_LOC ""

#define ERR_NOTDONE_LOC "Feature not implemented."

#define RPT_BMP1 'BMPS\OPENTABL.BMP'
#define RPT_BMP2 'BMPS\GRPRPT2.BMP'
#define RPT_BMP3 'BMPS\NEWSORT.BMP'
#define RPT_BMP4 'BMPS\EXECRPT.BMP'
#define RPT_BMP5 'BMPS\FLAG.BMP'



#define DESC1_LOC "Which fields do you want in your report?"+ CHR(13)+CHR(13)+ ;
				  "Select a database or Free Tables item, select a table or view, and then select the fields you want."

#define DESC2_LOC "How do you want to group your records? " +;
                  "You can select up to three levels of groupings." + CHR(13) + CHR(13) + ;
                  "To specify a broader criteria for the grouping, click Modify."

#define DESC3_LOC "How do you want to sort the records within each group?"+CHR(13)+CHR(13)+ ;
                  "You may select up to three fields."

#define DESC4_LOC "How do you want your report to look?"+CHR(13)+CHR(13)+ ;
                  "You can choose the page orientation as well as a predefined style."


#define DESC5_LOC ""

#define SAVE_LOC "Save report as:"
#define GRP_NOSEL_LOC "<none>"

#define STYLE1_NAME_LOC  "Executive"
#define STYLE2_NAME_LOC  "Ledger"
#define STYLE3_NAME_LOC  "Presentation"
#define STYLE_CUSTOM_LOC "Custom"

* Localizer: In the following string, -xx- is replaced with a number (ie "First 5 characters")
*            Put the "-xx-" wherever you want that number to appear in your localed string.
*            For example, "-xx- blah blah" would yield: "5 blah blah"
#define C_FIRSTXCHARS_LOC  "First -xx- characters"
#define C_FIRSTCHAR_LOC    "First character"


#define STYLE1H_BMP "BMPS\EXECRPT.BMP"
#define STYLE1V_BMP "BMPS\EXECRPT.BMP"
#define STYLE2H_BMP "BMPS\LEDGERPT.BMP"
#define STYLE2V_BMP "BMPS\LEDGERPT.BMP"
#define STYLE3H_BMP "BMPS\PRESNRPT.BMP"
#define STYLE3V_BMP "BMPS\PRESNRPT.BMP"

#define STYLE1H_FILE "STYLES\STYLE1H.FRX"
#define STYLE1V_FILE "STYLES\STYLE1V.FRX"
#define STYLE2H_FILE "STYLES\STYLE2H.FRX"
#define STYLE2V_FILE "STYLES\STYLE2V.FRX"
#define STYLE3H_FILE "STYLES\STYLE3H.FRX"
#define STYLE3V_FILE "STYLES\STYLE3V.FRX"

* References into our pages
#define PAGE_FIELDS   1
#define PAGE_GROUPS   2
#define PAGE_SORT     3
#define PAGE_STYLE    4
#define PAGE_FINISH   5

#define C_DBCEXCL_LOC     "The DBC containing the selected table was previously opened " + ;
                          "non-exclusively and the field(s) you chose for sorting and grouping are not in " + ;
                          "an existing index tag. Please select field(s) which already have " + ;
                          "an existing index tag or exit the wizard and reopen the DBC exclusively."

#DEFINE C_VIEWSORT_LOC	"You have selected a View as a the source of data for your Group Report. " + ;
						"If your view is not sorted already, your group total report may not be useful."
						
#DEFINE	C_WRAPWARN_LOC	"Columns may not appear correctly in the ledger style report if fields wrap."
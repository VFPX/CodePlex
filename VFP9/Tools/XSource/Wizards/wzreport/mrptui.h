*
* Directives for One to Many Report Wizard UI
*
* Help Topic ID

#define HELP_wizOne_To_Many_Report_Wizard_Step_6     95825415
#define HELP_wizOne_To_Many_Report_Wizard_Step_5     95825414
#define HELP_wizOne_To_Many_Report_Wizard_Step_4     95825413
#define HELP_wizOne_To_Many_Report_Wizard_Step_3     95825412
#define HELP_wizOne_To_Many_Report_Wizard_Step_2     95825411
#define HELP_wizOne_To_Many_Report_Wizard_Step_1     95825410
#define HELP_wizOne_To_Many_Report_Wizard			 95825409

#define  HELP_ID  HELP_wizOne_To_Many_Report_Wizard		&& 1895825409

* Localization strings for the UI
*
#define STEP1_LOC 'Step 1 - Select Parent Table Fields'
#define STEP2_LOC 'Step 2 - Select Child Table Fields'
#define STEP3_LOC 'Step 3 - Relate Tables'
#define STEP4_LOC 'Step 4 - Sort Records'
#define STEP5_LOC 'Step 5 - Choose Report Style'
#define STEP6_LOC 'Step 6 - Finish'

#define HINT1_LOC ""
#define HINT2_LOC ""
#define HINT3_LOC ""
#define HINT4_LOC ""
#define HINT5_LOC ""
#define HINT6_LOC ""

#define ERR_NOTDONE_LOC "Feature not implemented."

#define RPT_BMP1 'BMPS\1MRPT1.BMP'
#define RPT_BMP2 'BMPS\1MRPT2.BMP'
#define RPT_BMP3 'BMPS\1MRPT3.BMP'
#define RPT_BMP4 'BMPS\1MRPT4.BMP'
#define RPT_BMP5 'BMPS\EXECRPT.BMP'
#define RPT_BMP6 'BMPS\FLAG.BMP'



#define DESC1_LOC 'Which fields do you want from the parent' + CHR(13) +;
                  'table? These are the "one" side of the relationship' +CHR(13)+;
                  'and will appear in the top half of the report.' + CHR(13)+CHR(13)+ ;
				  'Select a database or Free Tables item, select a table or view, and then select the fields you want.'

#define DESC2_LOC 'Which fields do you want from the child' + CHR(13) +;
                  'table? These make up the "many" side of the relationship' +CHR(13)+;
                  'and will appear below the parent fields.' + CHR(13)+CHR(13)+ ;
				  'Select a database or Free Tables item, select a table, and then select the fields you want.'

#define DESC3_LOC "How do you want to relate the two tables?" + CHR(13) + CHR(13) + ;
                  "Select a matching field in each table."

#define DESC4_LOC "How do you want to sort the records?"+CHR(13)+CHR(13)+ ;
                  "You may select up to three fields or indexes."

#define DESC5_LOC "How do you want your report to look?"+CHR(13)+CHR(13)+ ;
                  "You may also specify options for summarizing detail information."

#define DESC6_LOC ""

#define SAVE_LOC  "Save report as:"

#define STYLE1_NAME_LOC  "Executive"
#define STYLE2_NAME_LOC  "Ledger"
#define STYLE3_NAME_LOC  "Presentation"
#define STYLE_CUSTOM_LOC "Custom"

#define STYLE1H_BMP "BMPS\EXECRPT.BMP"
#define STYLE1V_BMP "BMPS\EXECRPT.BMP"
#define STYLE2H_BMP "BMPS\LEDGERPT.BMP"
#define STYLE2V_BMP "BMPS\LEDGERPT.BMP"
#define STYLE3H_BMP "BMPS\PRESNRPT.BMP"
#define STYLE3V_BMP "BMPS\PRESNRPT.BMP"

#define STYLE1H_FILE "STYLES\STYLE1M.FRX"
#define STYLE1V_FILE "STYLES\STYLE1V.FRX"
#define STYLE2H_FILE "STYLES\STYLE2M.FRX"
#define STYLE2V_FILE "STYLES\STYLE2V.FRX"
#define STYLE3H_FILE "STYLES\STYLE3M.FRX"
#define STYLE3V_FILE "STYLES\STYLE3V.FRX"

* References into our pages
#define PAGE_FIELDS   1
#define PAGE_RELATED  2
#define PAGE_KEY      3
#define PAGE_SORT     4
#define PAGE_STYLE    5
#define PAGE_FINISH   6


#DEFINE C_BADKEYTYPE_LOC "You have selected mismatched data types for fields relating your two tables. "+; 
	"Please select a combination with matching data types."

#DEFINE C_DBCEXCL_LOC "You have selected a child table from a DBC opened non-exclusively. "+;
	"In order to create the key relation you have selected, an index must be created which requires exclusive use of the DBC. "+;
	"Please select a key field which already has an index or exit the wizard and reopen the DBC exclusively."

#DEFINE	C_WRAPWARN_LOC	"Columns may not appear correctly in the ledger style report if fields wrap."
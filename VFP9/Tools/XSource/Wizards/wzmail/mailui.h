*
* Directives for Mail Merge Wizard UI
*

* Localization strings for the Mail Merge Wizard UI
*
#define STEP1_LOC 'Step 1 - Select Fields'
#define STEP2_LOC 'Step 2 - Choose Word Processor'
#define STEP3_LOC 'Step 3 - Select Document Type'
#define STEP4_LOC 'Step 4 - Choose Document Style'
#define STEP5_LOC 'Step 5 - Finish'

#define HINT1_LOC ""
#define HINT2_LOC ""
#define HINT3_LOC ""
#define HINT4_LOC ""
#define HINT5_LOC ""

#define ERR_NOTDONE_LOC "Feature not implemented."
#define c_OPENDOC_LOC "Choose a Document for your mail merge:"
#define c_OPEN_LOC "Open:"

#define RPT_BMP1 'OPENTABL.BMP'
#define RPT_BMP2 'MAILM2.BMP'
#define RPT_BMP3 'MAILM3A.BMP'
#define RPT_BMP4 'MAILM3B.BMP'
#define RPT_BMP5 'MAILM4.BMP'
#define RPT_BMP6 'FLAG.BMP'




#define DESC1_LOC "Which fields do you want in your mail merge?" + CHR(13)+CHR(13)+ ;
				  "Select a database or the Free Tables, select a table or view, and then select the fields you want."


#define DESC2_LOC "Which word processor do you want to use?" +CHR(13)+CHR(13)+ ;
                  "To use Microsoft Word, select that option. To use another " +;
                  "word processor, select the text file option to create a file " +;
                  "you can use for the mail merge."

#define DESC3_LOC "Do you want to create a new document to merge the information " +;
                  "into, or do you already have an existing document." +CHR(13)+CHR(13)+ ;
				  "To select an existing document, enter the name or click File."
				  
#define DESC4_LOC "Which type of main document do you want to create?"

#define DESC5_LOC "You are ready to start the mail merge." +CHR(13)+CHR(13)+ ;
                  "To begin merging, click Finish."

* References into our pages
#define PAGE_FIELDS   1
#define PAGE_WORD     2
#define PAGE_DOCUMENT 3
#define PAGE_LAYOUT   4
#define PAGE_FINISH   5


#define FINISH_WORD_LOC "You are ready to start the mail merge." +CHR(13)+CHR(13)+ ;
                  "To begin merging, click Finish."
#define FINISH_TEXT_LOC "You are ready to start the mail merge." +CHR(13)+CHR(13)+ ;
                  "To begin merging, click Finish."
	
* #define FINISH_WORD_LOC "You are now ready to start the mail merge."+CHR(13) + CHR(13) + ;
*                        "Click Finish to launch Word and open your main document."
* #define FINISH_TEXT_LOC "Click Finish to save your text file." + CHR(13) + CHR(13) + ;
*                        "You can use this data in a mail merge."

#DEFINE ERR_NORECORDS_LOC		"Warning: The table you have selected is empty."

#DEFINE ERR_DBCEXCL_LOC		"Your database is opened exclusively. Word cannot perform a mail merge unless the database is opened shared. Please select another database or quit the Wizard and reopen your database shared."

#define WORDPROC_WORD	1
#define WORDPROC_TEXT	2

*- help codes
#define HELP_wizMail_Merge_Wizard_Step_5     95825536
#define HELP_wizMail_Merge_Wizard_Step_4     95825535
#define HELP_wizMail_Merge_Wizard_Step_3     95825534
#define HELP_wizMail_Merge_Wizard_Step_2     95825533
#define HELP_wizMail_Merge_Wizard_Step_1     95825532
#define HELP_wizMail_Merge_Wizard			 95825531


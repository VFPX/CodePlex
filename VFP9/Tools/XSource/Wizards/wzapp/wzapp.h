* APPWIZ.H - Header file for Application Wizard files.
*

***** Dropdown list selector
#define STEP1_LOC	"Step 1 - Choose Project Location"
#define STEP2_LOC	"Step 2 - Choose Database"
#define STEP3_LOC	"Step 3 - Choose Documents"
#define STEP4_LOC	"Step 4 - Configure Menu"
#define STEP5_LOC	"Step 5 - Finish"

***** Screen directions
#define DESC1		"How would you like to set up your project?"+CHR(13)+CHR(13)+ ;
		"You can create a complete application or just a framework, which you can add components to later."+ ;
		"  To have the wizard create all the directories for you, click the Create project directory structure option."

#define DESC2		"Which database would you like to use in this application?"+CHR(13)+CHR(13)+ ;
		"You can use an existing database, or you can create a new one from a template."

#define DESC3		"Which documents would you like to include in your application?"+CHR(13)+CHR(13)+ ;
					"Documents contained in the list will be added to the new project.  To include additional documents, click Add.  To remove a document from the list, select it, then click Remove."

#define DESC4		"What menu system would you like to have in your application?"+CHR(13)+CHR(13)+ ;
		"If you don't want a particular menu item, highlight it and click Exclude."

#define DESC5		"You are ready to create your application."+CHR(13)+CHR(13)+ ;
		"Select an option and click Finish."

***** Screen BMP files
#define BMPFILE1	"app1.bmp"
#define BMPFILE2	"app2.bmp"
#define BMPFILE3	"app3.bmp"
#define BMPFILE4	"app4.bmp"
#define BMPFILE5	""			&&empty -- finish screen

#DEFINE	E_BADPARMS_LOC	"Invalid parameters passed."
#DEFINE	E_NOGRID_LOC	"No grid available in style."

** Data types
#DEFINE DT_NUMERIC  'N'
#DEFINE DT_FLOAT 	'F'
#DEFINE DT_LOGIC 	'L'
#DEFINE DT_MEMO  	'M'
#DEFINE DT_GENERAL  'G'
#DEFINE DT_CHAR  	'C'
#DEFINE DT_DATE  	'D'
#DEFINE DT_DOUBLE  	'B'
#DEFINE DT_TIME  	'T'
#DEFINE DT_MONEY  	'Y'

** Miscellaneous
#DEFINE NUM_AFIELDS		11	&&linear dimension of AFIELDS
#DEFINE C_SEP			" = "			&&property separator
#DEFINE C_VERSTAMP		"VERSION =  0.001"
#DEFINE C_DOS     		"DOS"
#DEFINE C_WINDOWS 		"WINDOWS"
#DEFINE C_MAC     		"MAC"
#DEFINE C_UNIX    		"UNIX"
#DEFINE	C_CRLF			CHR(13)+CHR(10)	&&return/linefeed
#DEFINE	C_CR			CHR(13)			&&return
#DEFINE	C_LF			CHR(10)			&&linefeed
#DEFINE	C_TAB			CHR(9)			&&tab
#DEFINE	C_SCXEXT		"SCX"			&&2.x screen extension
#DEFINE C_DEFSET		"Formset1"
#DEFINE C_DEFFORM		"Form1"
#DEFINE C_MAXCHAR		60
#DEFINE C_WINFONT		"MS Sans Serif"
#DEFINE C_WINFSIZE		8
#DEFINE C_WINFSTYLE		"B"
#DEFINE C_WINFBOLD		.T.
#DEFINE C_WINFITALIC	.F.
#DEFINE C_WINFUNDER		.F.
#DEFINE CRET			CHR(13)
#DEFINE CRLF			CHR(13)+CHR(10)


*-- Titles
#DEFINE T_APPLICATION_WIZARD_LOC	"Application Wizard"

*-- Captions
#DEFINE C_SAVE_PROJECT_LOC			"\<Save project"
#DEFINE C_SAVE_PROJECT_MODIFY_LOC	"Save project and \<modify it"
#DEFINE C_SAVE_APP_RUN_LOC			"Save application and \<run it"

*-- Messages
#DEFINE M_APPLICATION_WIZARD_LOC	"Application Wizard"
#DEFINE M_STARTUP_LOC				"Startup"
#DEFINE M_STARTUP_MARKER_LOC		"  (startup)"
#DEFINE M_TEMPLATE_MARKER_LOC		"  (template)"

*-- Fonts
#DEFINE F_ARIAL_LOC					"Arial"
#DEFINE F_MS_SANS_SERIF_LOC			"MS Sans Serif"

*-- Wait windows
#DEFINE W_MATCH_NOT_FOUND_LOC		"Match not found"

*-- ASCII codes
#DEFINE EOL		CHR(0)
#DEFINE	MARKER	CHR(1)
#DEFINE	TAB		CHR(9)
#DEFINE	LF		CHR(10)
#DEFINE	CR		CHR(13)
#DEFINE CR_LF	CR+LF

*-- Help
#DEFINE wizApplication_Wizard	95825502
#DEFINE wizApplication_Wizard_Step_1	95825503
#DEFINE wizApplication_Wizard_Step_2	95825504
#DEFINE wizApplication_Wizard_Step_3	95825505
#DEFINE wizApplication_Wizard_Step_4	95825506
#DEFINE wizApplication_Wizard_Step_5	95825507

*-- VFP98 framework
#DEFINE APP_BUILDER_FILE_SUFFIX   "_app"
#DEFINE APP_BUILDER_CLASS_PREFIX  "app"

#DEFINE APP_BUILDER_MAINMENU_SUFFIX   "_main"
#DEFINE APP_BUILDER_TOPMENU_SUFFIX    "_top"		
#DEFINE APP_BUILDER_APPENDMENU_SUFFIX "_append"		
#DEFINE APP_BUILDER_GOMENU_SUFFIX     "_go"
* #DEFINE APP_BUILDER_TOPGOMENU_SUFFIX  "_top_go"
#DEFINE REPORTS_CLASSLIB	"FFC\_REPORTS.VCX"

#DEFINE INCLUDECAPTION_LOC	"\<Include"
#DEFINE EXCLUDECAPTION_LOC	"\<Exclude"
#DEFINE LOADTEMPLATE_LOC	"Loading template "
#DEFINE CREATEPJX_LOC "Create project directory structure automatically enabled."
#DEFINE EXCLUDE2_LOC	"  (excluded)"

#DEFINE APPGENERATING_LOC	"Please be patient while application is being generated..."
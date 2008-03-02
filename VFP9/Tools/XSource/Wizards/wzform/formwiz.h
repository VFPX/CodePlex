***** Dropdown list selector
#define FORM_HELP_ID	  		95825512
#define FORM_HELP_ID1	  		95825513
#define FORM_HELP_ID2	  		95825514
#define FORM_HELP_ID3	  		95825515
#define FORM_HELP_ID4	  		95825516

#define MANYFORM_HELP_ID		95825537
#define MANYFORM_HELP_ID1		95825538
#define MANYFORM_HELP_ID2		95825539
#define MANYFORM_HELP_ID3		95825540
#define MANYFORM_HELP_ID4		95825541
#define MANYFORM_HELP_ID5		95825542
#define MANYFORM_HELP_ID6		95825543

#define STEP1_LOC	"Step 1 - Select Fields"
#define STEP2_LOC	"Step 2 - Choose Form Style"
#define STEP3_LOC	"Step 3 - Sort Records"
#define STEP4_LOC	"Step 4 - Finish"

#define STEP1M_LOC	"Step 1 - Select Parent Table Fields"
#define STEP2M_LOC	"Step 2 - Select Child Table Fields"
#define STEP3M_LOC	"Step 3 - Relate Tables"
#define STEP4M_LOC	"Step 4 - Choose Form Style"
#define STEP5M_LOC	"Step 5 - Sort Records"
#define STEP6M_LOC	"Step 6 - Finish"

#define STEP7M_LOC	"Step ??? - Labels"  &&not used now

***** Screen directions
#define DESC1a_LOC	'Which fields do you want to use on your form?'
#define DESC1b_LOC	'Which fields do you want from the parent table? These are the "one" side of the relationship and will appear in the top half of the form.'
#define DESC1c_LOC	'Which fields do you want from the child table? These make up the "many" side of the relationship and will appear in a grid below the parent fields.'
#define DESC1d_LOC	'Select a database or the Free Tables, select a table or view, and then select the fields you want.'
#define DESC1		DESC1a_LOC+CRET+CRET+DESC1d_LOC
#define DESC1M		DESC1b_LOC+CRET+CRET+DESC1d_LOC
#define DESC1R		DESC1c_LOC+CRET+CRET+DESC1d_LOC

#define DESC2a_LOC	"Which style do you want for your form?"
#define DESC2b_LOC	"You can also choose a set of standard navigation buttons."
#define DESC2		DESC2a_LOC+CRET+CRET+DESC2b_LOC

#define DESC3a_LOC	"How do you want to sort your records?"
#define DESC3b_LOC  "Select up to three fields or select one index tag to sort the records by."
#define DESC3c_LOC	"How do you want to sort the parent table?"
#define DESC3		DESC3a_LOC+CRET+CRET+DESC3b_LOC
#define DESC3M		DESC3c_LOC+CRET+CRET+DESC3b_LOC

#define DESC4		""	&&empty--finish screen

#define DESC5a_LOC	"How do you want to relate the two tables?"
#define DESC5b_LOC	"Select a matching field in each table."
#define DESC5		DESC5a_LOC+CRET+CRET+DESC5b_LOC

***** Screen hint button text
#define HINT1_LOC	"Friends don't let friends use dBASE."
#define HINT2_LOC	"Eat more Buffalo Chicken Wings."
#define HINT3_LOC	"A Taz session every day keeps the doctor away."
#define HINT4_LOC	"See you at Devcon..."
#define HINT1M_LOC	"Boy, it rains a lot in Seattle."
#define HINT1R_LOC	"Do you know OOP yet?"
#define HINT5_LOC	"The Key to this is in the fields."

***** Screen BMP files
#define BMPFILE1	"opentabl.bmp"
#define BMPFILE2	"embossed.bmp"
#define BMPFILE3	"newsort.bmp"
#define BMPFILE4	""			&&empty -- finish screen
#define BMPFILE1M	"1mform1.bmp"
#define BMPFILE1R	"1mform2.bmp"
#define BMPFILE1K	"1mform3.bmp"

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
#DEFINE NUM_AFIELDS		18	&&linear dimension of AFIELDS
#DEFINE C_SEP			" = "			&&property separator
#DEFINE C_VERSTAMP		"VERSION =  0.007"
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


* Error messages used to check for valid styles.

#DEFINE ERR_STY1_LOC	"Missing layout reference property in style."
#DEFINE ERR_STY2_LOC	"Missing field reference property in style."
#DEFINE ERR_STY3_LOC	"Missing memo reference property in style."
#DEFINE ERR_STY4_LOC	"Missing OLE reference property in style."
#DEFINE ERR_STY5_LOC	"Missing layout object in style."
#DEFINE ERR_STY6_LOC	"Missing one of the layout reference properties in style."
#DEFINE ERR_STY7_LOC	"Missing one of the layout objects in style."
#DEFINE ERR_STY8_LOC	"Missing label in field object in style."
#DEFINE ERR_STY9_LOC	"Missing field in field object in style."
#DEFINE ERR_BADSTYLE_LOC "Invalid style supplied: "

#DEFINE ERR_NODIR_LOC	"The wizard cannot create a directory for picture button files. You must select text buttons."
#DEFINE ERR_NOSTYLE_LOC	"No style has been referenced in the styles table."
#DEFINE ERR_NOSTYLEVCX_LOC	"No style VCX file has been referenced in the styles table."
#DEFINE C_LOCSTY1_LOC	"The following styles class could not be found:"
#DEFINE C_LOCSTY2_LOC	"Would you like to locate it?"
#DEFINE C_BADGENFLD_LOC	"You have a corrupt OLE object in a General field."

#DEFINE ERR_NOCONTROL_LOC	"Control type classes are not allowed in styles."

#DEFINE WZ_DIRNAME	'WIZARDS\WIZBMPS'		&&dirname for bmps
#DEFINE WIZ_DIR		'WIZARDS\'				&&default wizard directory --relative to SYS(2004)
#DEFINE WIZ_STYDBF	'FRMSTYL2.DBF'			&&wizard style dbf
#DEFINE WIZ_STYVCX	'WIZBTNS.VCX'			&&wizard style class lib
#DEFINE C_LOCATE_LOC	'Locate: '			&&GetFile prompt -- note keep it small so file fits

#DEFINE ERR_FORMSET_LOC	"Formsets are not supported as styles in the Form Wizard."

* Registry constants
#DEFINE ERROR_SUCCESS	0			&& all is fine
#DEFINE C_RESWIDTH		"ResWidth"	&& Options dialog setting
#DEFINE C_RESHEIGHT		"ResHeight"	&& Options dialog setting

#DEFINE HKEY_CURRENT_USER           -2147483647  && BITSET(0,31)+1
#DEFINE VFP_INTELLIDROP_KEY			"Software\Microsoft\VisualFoxPro\6.0\Options\Intellidrop\FieldTypes\"

#DEFINE	C_XSFIELDS_LOC		"The form wizard could not fit all the fields. "+;
							"Depending on the style selected, you might try one of the following:"+CHR(13)+CHR(13)+;
							"1. Click the Add Pages checkbox."+CHR(13)+;
							"2. Remove some of your selected fields."+CHR(13)+;
							"3. Increase the Maximum Design Area setting in the Options dialog."

#DEFINE	C_XSFIELDSBLDR_LOC		"The form builder could not fit all the fields. "+;
							"You might try one of the following:"+CHR(13)+CHR(13)+;
							"1. Remove some of your selected fields."+CHR(13)+;
							"2. Increase the Maximum Design Area setting in the Options dialog."

#DEFINE	C_XSFIELDS2_LOC		"The form wizard\builder could not fit all the fields. "+;
							"You might try one of the following:"+CHR(13)+CHR(13)+;
							"1. Remove some of your selected fields."+CHR(13)+;
							"2. Select a different style."+CHR(13)+;
							"3. Increase the Maximum Design Area setting in the Options dialog."

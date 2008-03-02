*:******************************************************************************
*:
*: WZFOXDOC.H
*:
*:******************************************************************************
*:   WZFOXDOC
#DEFINE STEP1_LOC "Step 1 - Choose Source File"
#DEFINE STEP2_LOC "Step 2 - Set Capitalization"
#DEFINE STEP3_LOC "Step 3 - Set Indentation"
#DEFINE STEP4_LOC "Step 4 - Add Headings"
#DEFINE STEP5_LOC "Step 5 - Select Reports"
#DEFINE STEP6_LOC "Step 6 - Finish"

* Help IDs
#DEFINE wizDocumenting_Wizard_Step6	1995825416
#DEFINE wizDocumenting_Wizard_Step5	1995825415
#DEFINE wizDocumenting_Wizard_Step4	1995825414
#DEFINE wizDocumenting_Wizard_Step3	1995825413
#DEFINE wizDocumenting_Wizard_Step2	1995825412
#DEFINE wizDocumenting_Wizard_Step1	1995825411
#DEFINE wizDocumenting_Wizard	1995825410

#DEFINE DESC1_LOC "Which program or project file do you want to document?"+CHR(13)+CHR(13)+;
	"The wizard will not change your original files."
#DEFINE DESC2_LOC "How do you want to capitalize the code?"
#DEFINE DESC3_LOC "How do you want to indent the code?"
#DEFINE DESC4_LOC "Do you want headings added to your files or blocks of code"
#DEFINE DESC5_LOC "Do you want to create reports about your code?"+CHR(13)+CHR(13)+;
		"The reports are text files that are created from tables that the "+;
		"wizard builds from your code."


#DEFINE NOT_FOUND_LOC "not found"

#DEFINE REPORTSOURCE_LIST_LOC "Source Code Listing"
#DEFINE REPORTACTION_DIAG_LOC "Action Diagram"
#DEFINE REPORTXREF_LOC "Cross-Reference"
#DEFINE REPORTFILE_LIST_LOC "File Listing"
#DEFINE REPORTTREE_DIAG_LOC "Tree Diagram"

#define KEYWORDCASE "KEYWORDCASE"
#define USERCASE "USERCASE"

#define OUTPUTTODIR_LOC "Choose the single directory:"
#define OUTPUTTODIRTREE_LOC "Output to directory tree:"
#define C_ESCAPECONTINUE_LOC "Do you want to abort?"
#define C_WIZNAME_LOC "Documenting Wizard"
#define e_notproversion_loc "The Documenting Wizard requires the Professional version of Visual FoxPro."
#define DIFF_DIR_NEEDED_LOC "Cannot output to the same directory"
#define WHEREIS_LOC "Where is "

#define BAD_PROJ_LOC "Project must contain files in project home dir or subdirs for output option 3"
#define ACCESS_DENIED "Access to the project is denied"

#define CALLED_BY_LOC "Called by"
#define DOC_VER_LOC "Documented using Visual FoxPro Formatting wizard version "
#define FILE_LIST_LOC "File List"
#define TOTAL_LINES_PROC_LOC "Total Code Lines Processed"
#define CLASS_HIERARCHY_LOC "Class Hierarchy"
#define SOURCE_FILE_LOC "Source File"

#define C_TABS_LOC "Tabs"
#define C_SPACES_LOC "Spaces"
#define C_NOCHANGE_LOC "No change"

#DEFINE C_ANALYZER_LOC		HOME() + "Tools\Analyzer\Analyzer.App"


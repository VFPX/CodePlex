#define STEP_LOC "Step"
#define STEP1_LOC " - Choose Data Source"
#define STEP2_LOC " - Select Fields"
#define STEP2a_LOC " - Include Records"
#define STEP3_LOC " - Relate Tables"
#define STEP4_LOC " - Group Records"
#define STEP4a_LOC " - Limit Records"
#define STEP5_LOC " - Sort Records"
#define STEP6_LOC " - Filter Records"
#define STEP7_LOC " - Finish"

#DEFINE MB_ICONEXCLAMATION      48      && Warning message


#define DESC1_LOC "To which data source do you want to " +;
	"connect to create your remote view?"+chr(13)+chr(13)+;
	"Specify either a data source or an existing "+;
	"connection to a data source."

#define DESC2r_LOC "Which fields do you want in the view results? "+;
	"You may select fields from one or more tables or views." +chr(13)+chr(13)+;
	"Select a database or Free Tables, select a table or view, and then select the fields you want."
#define DESC2v_LOC "Which fields do you want in the view results? "+;
	"You may select fields from one or more tables or views." +chr(13)+chr(13)+;
	"Select a database or Free Tables, select a table or view, and then select the fields you want."
#define DESC2q_LOC "Which fields do you want in the query results? "+;
	"You may select fields from one or more tables or views." +chr(13)+chr(13)+;
	"Select a database or Free Tables, select a table or view, and then select the fields you want."

#define DESC3r_LOC "How do you want to relate the tables your remote view is based on?" +chr(13)+chr(13)+;
	"Select matching fields to create table relationships, and add each relationship to the list box."
	
#define DESC3v_LOC "How do you want to relate the tables your local view is based on?" +chr(13)+chr(13)+;
	"Select matching fields to create table relationships, and add each relationship to the list box."

#define DESC3q_LOC "How do you want to relate the tables your query is based on?"+chr(13)+chr(13)+;
	"Select matching fields to create table relationships, and add each relationship to the list box."

#define DESC4_LOC "Do you want to summarize your data by"+chr(13)+;
	"creating groupings?"

#define DESC5_LOC "How do you want to sort your records?"+chr(13)+chr(13)+;
	"Records will be sorted according to the order of the "+;
	"selected fields. You may select up to three fields or indexes."
	
	
#define DESC6r_LOC "Do you want to display only certain records?"+chr(13)+chr(13)+;
	"Create an expression that describes the records you want to see by using the "+;
	"Field, Operator, and Value boxes."+chr(13)+chr(13)+;
	"To see the results of your filter expression, click Preview."
#define DESC6v_LOC "Do you want to display only certain records?"+chr(13)+chr(13)+;
	"Create an expression that describes the records you want to see by using the "+;
	"Field, Operator, and Value boxes."+chr(13)+chr(13)+;
	"To see the results of your filter expression, click Preview."
#define DESC6q_LOC "Do you want to display only certain records?"+chr(13)+chr(13)+;
	"Create an expression that describes the records you want to see by using the "+;
	"Field, Operator, and Value boxes."+chr(13)+chr(13)+;
	"To see the results of your filter expression, click Preview."

#define DESC7_LOC "Do you want to include all records from either table "+;
	"or just the records that match?"+chr(13)+chr(13)+;
	"Select the appropriate option below."

#define DESC8_LOC "Do you want to limit your query to just the "+;
	"first or last records?"+chr(13)+chr(13)+;
	"Select the type and value of the portion you want to display."+chr(13)+chr(13)+;
	"The results depend on the sort order you choose in Step 4. "+;
	"Click Preview  to verify your sort order and selection."

*Note : PREVIEW_LOC is used as the name of a cursor.
#define PREVIEW_LOC "Preview"
#define ERROR_CONNECT_LOC "Error connecting "
#define ERROR_DISCONNECT_LOC "Error disconnecting "

#define WIZCAPTIONQUERY_LOC "Query Wizard"
#define WIZCAPTIONVIEW_LOC "Local View Wizard"
#define WIZCAPTIONREMOTE_LOC "Remote View Wizard"

* for Remote query wiz,2nd screen
#define TABLES_LOC "Tables:"
#define C_FREETABLE_LOC "Free Tables"
#define C_NODBCOPEN_LOC "Views must be stored in a database.  Please create or open one now."
#define C_NO_RECORDS_FOUND_LOC "No records found"

#define C_FINISH_TEXTr_LOC "You are ready to create your remote view." + CHR(13)+;
						"To check your view results, click Preview."
#define C_FINISH_TEXTv_LOC "You are ready to create your local view." + CHR(13)+;
						"To check your view results, click Preview."
#define C_FINISH_TEXTq_LOC "You are ready to create your query." + CHR(13)+;
						"To check your query results, click Preview."

#define C_SAVER1_LOC "\<Save remote view"
#define C_SAVER2_LOC "Save remote view and b\<rowse"
#define C_SAVER3_LOC "Save remote view and \<modify it in the View Designer"

#define C_SAVEV1_LOC "\<Save local view"
#define C_SAVEV2_LOC "Save local view and b\<rowse"
#define C_SAVEV3_LOC "Save local view and \<modify it in the View Designer"

#define C_SAVEQ1_LOC "\<Save query"
#define C_SAVEQ2_LOC "Save query and \<run it"
#define C_SAVEQ3_LOC "Save query and \<modify it in the Query Designer"

#define C_SAVERB_LOC "in the View Designer"
#define C_SAVERC_LOC "in the Query Designer"

#define C_NAMEL_LOC "Name for view"
#define C_NAMER_LOC "Name for remote view"

#DEFINE ODBC_ERROR_LOC "An ODBC error occurred."
#define VIEW_EXISTS_LOC "already exists. Do you want to overwrite it?"
#define ALREADY_EXISTS_LOC "already exists."

#define ODBC_DRIVER_ERROR_LOC "ODBC Driver Error"
#define NO_TABLES_LOC "No tables found"
#define C_EXIST_CONNECTIONS_LOC "Existing Connections:"
#define C_AVAIL_DATASOURCES_LOC "Available Data Sources:"
#define C_VIEW_LOC "View "
 

#DEFINE FOXODBC_OLD			"FoxPro Files (*.dbf) Microsoft FoxPro Driver (*.dbf) FoxPro Driver (*.dbf)"
#DEFINE FOXODBC_30			"Microsoft FoxPro 3.0 Driver (*.dbf)"

#DEFINE DBC_EXCL_LOC	"Exclusive use of the DBC is required to save your view"

#DEFINE C_OPERATORS_LOC	"equals\;not equals\;more than\;less than\;is blank\;is NULL\;contains\;in\;between\;less than or equal\;greater than or equal"
#DEFINE C_OPERATORSR_LOC	"equals\;not equals\;more than\;less than"

#DEFINE ODBC_NOOWNER_LOC "The Remote View Wizard was unable to obtain column information for this remote table."+chr(13)+;
						"This may be the result of an ODBC error, or the remote table may not be owned by the current user, "+;
						"or the table doesn't have columns."

#DEFINE FOX26DRIVER_WARNING_LOC "You have chosen a driver for an older version of Foxpro "+chr(13)+;
		"It does not recognize Visual Foxpro 3.0 files."+chr(13)+;
		"Please make sure your ODBC data source points to a directory which contains only 2.x files."+chr(13)+;
		"Do you wish to continue?"
		
*warning for an incorrect 3 table join
#DEFINE SAMECHILD_LOC	"The same table cannot be child for two parent tables."
#DEFINE SAMEPARENT_LOC	"The same table cannot be the parent for two child tables."

*- used for Macintosh
#DEFINE		ODBC_SOURCE			"ODBC Data Sources"
#DEFINE		ODBC_FILE_MAC 		"ODBC Preferences"
#DEFINE		ODBC_FILE_MACPPC 	"ODBC Preferences PPC"

#DEFINE		SQLODBC_ANY			"SQL"

#DEFINE		E_ODBC1_LOC			"Could not check ODBC Preferences file. Check to see if ODBC is properly installed."
#DEFINE		E_ODBC2_LOC			"Could not find any SQL ODBC driver. Check to see if it is installed."
#DEFINE		E_ODBCDLL_LOC		"Could not check for properly installed ODBC files."

#DEFINE 	ERROR_SUCCESS		0
#DEFINE		ERROR_NOINIFILE		-108	&& no DLL file used to check ODBC
#DEFINE		ERROR_NOINIENTRY	-109	&& no entry found in INI file (section)
#DEFINE		ERROR_FAILINI		-110	&& no entry found in INI file

#DEFINE BTN_CREATE_LOC	'\<Create'
#DEFINE BTN_OPEN_LOC	'\<Open'
#DEFINE BTN_CANCEL_LOC	'Cancel'

#DEFINE C_GATHERDATA_LOC	"Gathering data..."
#DEFINE C_RUNNINGQUERY_LOC "Running query"
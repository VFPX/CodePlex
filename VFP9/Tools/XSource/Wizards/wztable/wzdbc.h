*- #INCLUDE file for the database wizard.

#define MESSAGE_LOC "Microsoft Visual FoxPro Wizards"
#DEFINE STEP1_LOC	"Step 1 - Select a Database"
#DEFINE STEP2_LOC	"Step 2 - Select Tables and Views"
#DEFINE STEP3_LOC	"Step 3 - Index the Tables"
#DEFINE STEP4_LOC	"Step 4 - Set up relationships"
#DEFINE FINISH_LOC	"Step 5 - Finish"

#DEFINE DESC1_LOC	"Select a database from the list below that you want to create." +CHR(13)+CHR(13)+;
					"You may also select a Microsoft Access database by clicking the Select button."

#DEFINE DESC2_LOC	"Select which tables and views you want to include in your database."
					
#DEFINE DESC3_LOC	"How do you want to index your table?" +CHR(13)+CHR(13)+;
					"You may select one field as the primary index key." +CHR(13)+CHR(13)+;
					"Select check boxes to create additional indexes."

#DEFINE DESC4_LOC	"You can set up relationships between the tables in the database." 

#DEFINE FINISH1_LOC	"You are ready to create your database." 
#DEFINE FINISH2_LOC	"Select an option below, and click Finish to create the database."

#DEFINE BMPFILE1	"TABLE1.BMP"
#DEFINE BMPFILE2	"TABLE2.BMP"
#DEFINE BMPFILE3	"TABLE3.BMP"
#DEFINE BMPFILE4	"REL2.BMP"
#DEFINE BMPFILE5	"FLAG.BMP"

#DEFINE REL1_BMP	"rel1.bmp"
#DEFINE REL2_BMP	"rel2.bmp"
#DEFINE REL3_BMP	"rel3.bmp"

*- help codes
*- #DEFINE HELP_wizDBC_Wizard_Step_4		1999935414
*- #DEFINE HELP_wizDBC_Wizard_Step_3		1999935413
*- #DEFINE HELP_wizDBC_Wizard_Step_2		1999935412
*- #DEFINE HELP_wizDBC_Wizard_Step_1		1999935411
*- #DEFINE HELP_wizDBC_Wizard 1999935410

#DEFINE HELP_wizDBC_Wizard_Step_1	1895825555
#DEFINE HELP_wizDBC_Wizard_Step_2	1895825556
#DEFINE HELP_wizDBC_Wizard_Step_3	1895825557
#DEFINE HELP_wizDBC_Wizard_Step_4	1895825558
#DEFINE HELP_wizDBC_Wizard_Step_5	1895825559

						
#DEFINE C_TBLERR_LOC			"Unable to create this table:"
#DEFINE C_IDXERR_LOC			"Unable to create tables and indexes."

#DEFINE C_RESETINDEXKEY_LOC		"Memo, General, and Blob fields cannot be index keys. " + ;
								"This field will not be used as an index key"
				
#DEFINE C_TABLEUSEDINVIEW_LOC	"The @1 @3 is used in the @2 view. Removing this @3 will also remove the @2 view. Continue?"
#DEFINE C_VIEWNEEDSTABLE_LOC	"The @1 view uses the @2 @3, which is not selected. Do you want to restore the @2 @3?"
#DEFINE	C_VIEW_LOC				"view"
#DEFINE C_TABLE_LOC				"table"
#DEFINE C_ISREL_LOC				"Is related to "
#DEFINE C_ISNOTREL_LOC			"Is not related to "
#DEFINE C_NEWTAG_LOC			"<New field>"
#DEFINE C_MYNEWTABLE_LOC		"\<My new @1 table..."

#DEFINE C_NONE_LOC				"(None)"

#DEFINE C_BUSYDBC_LOC			"Creating database..."
#DEFINE C_BUSYDBF_LOC			"Adding tables..."
#DEFINE C_BUSYVUE_LOC			"Adding views..."
#DEFINE C_BUSYIDX_LOC			"Creating indexes and relations..."
#DEFINE C_BUSYSTR_LOC			"Adding stored procedures..."

#DEFINE C_NOODBC_LOC			"Unable to get list of ODBC drivers."
#DEFINE C_NOACCESSODBC_LOC		"No Access data source is defined."
#DEFINE C_NOCREATETEMPDIR_LOC	"Unable to create temporary directory for database template."
#DEFINE C_NOCONNECT_LOC			"Unable to connect to the Access database."
#DEFINE C_NORETRIEVEDATA_LOC	"Error retrieving data."
#DEFINE E_NOREGISTRY_LOC		"Unable to load REGISTRY class."
#DEFINE E_NOTTABLE_LOC			"The file you selected is not a table."
#DEFINE E_NOTDBC_LOC			"The file you selected is not a Microsoft Visual Foxpro database file."
#DEFINE E_NOOPENTABLE_LOC		"Unable to open the file you selected."
#DEFINE E_CREATETBLERR_LOC		"Unable to create table @1."
#DEFINE E_CREATEDBCERR_LOC		"Unable to create database."
#DEFINE E_OPENDBCERR_LOC		"Unable to open new database."
#DEFINE E_OPENDBCTEMPERR_LOC	"Unable to open database template."
#DEFINE E_SAMEDBC_LOC			"The new database cannot be the same file as the database template."
#DEFINE E_ACCNOTABLES_LOC		"Unable to obtain list of tables from Access database."
#DEFINE E_ACCNOCOLS_LOC			"Unable to obtain list of columns from Access tables."
#DEFINE E_DBCOPEN_LOC			"The template database you selected is already open. Close it and continue?"

#DEFINE	C_LOADINGTEMPLATE_LOC	"Loading template "
#DEFINE C_CREATINGTEMPLATE_LOC	"Creating template from "
#DEFINE C_NODBC_LOC				"No database was found in the selected template."
#DEFINE C_DESTDBC_LOC			"Select new database:"
#DEFINE C_SELECTDBC_LOC			"Select database:"
#DEFINE C_VALIDDATABASE_LOC		"Database:DBC;Microsoft Access Database:MDB"
#DEFINE C_PROCESSING_LOC		"Processing "

#DEFINE C_MSACCESSODBC_LOC		"Microsoft Access Driver (*.mdb)"		&& ODBC driver -- localize?
#DEFINE C_IGNORETABLES_LOC		"switchboard items"						&& tables in MDB to ignore -- localize?
#DEFINE C_TEMPLATELOC			"wizards\template\"						&& location of templates, off of HOME() -- localize?

#DEFINE MB_OK					0
#DEFINE MB_YESNO	    		4
#DEFINE MB_ICONQUESTION	    	32
#DEFINE MB_ICONEXCLAMATION  	48
#DEFINE MB_RET_YES				6
#DEFINE MB_DEFBUTTON2           256     && Second button is default

#DEFINE I_DBCFCOUNT				8
*- #INCLUDE file for the table wizard.

#define MESSAGE_LOC "Microsoft Visual FoxPro Wizards"
#DEFINE STEP1_LOC	"Step 1 - Select Fields"
#DEFINE STEP1a_LOC	"Step 1a - Select a Database"
#DEFINE STEP2_LOC	"Step 2 - Modify Field Settings"
#DEFINE STEP3_LOC	"Step 3 - Index the Table"
#DEFINE STEP3a_LOC	"Step 3a - Set up relationships"
#DEFINE FINISH_LOC	"Step 4 - Finish"

#DEFINE DESC1_LOC	"Which fields do you want in your new table? You can choose any " +;
					"combination of fields from the sample tables." +CHR(13)+CHR(13)+;
					"Select a table to see available fields, and then select the fields. "+;
					"If you want to use a different sample table, click Add."

#DEFINE DESC1A_LOC	"You can select a database in which to add your new table." +CHR(13)+CHR(13)+;
					"Also you can optionally choose a friendly name for your table. "

#DEFINE DESC2_LOC	"Do you want to change any field settings?" +CHR(13)+CHR(13)+;
					"Select each field to verify or change its setting. You can "+;
					"change a field caption only if a database is open."
					
#DEFINE DESC3_LOC	"How do you want to index your table?" +CHR(13)+CHR(13)+;
					"If a database is open, you may select one "+;
					"field as the primary index key." +CHR(13)+CHR(13)+;
					"Select check boxes to create additional indexes."

#DEFINE DESC3a_LOC	"You can set up relationships between your new table and existing ones in the database." 

#DEFINE FINISH1_LOC	"You are ready to create your table." 
#DEFINE FINISH2_LOC	"Select an option below, and click Finish to create the table."

#DEFINE BMPFILE1	"TABLE1.BMP"
#DEFINE BMPFILE1a	"TABLE1a.BMP"
#DEFINE BMPFILE2	"TABLE2.BMP"
#DEFINE BMPFILE3	"TABLE3.BMP"
#DEFINE BMPFILE3a	"REL1.BMP"
#DEFINE BMPFILE4	"FLAG.BMP"

#DEFINE REL1_BMP	"rel1.bmp"
#DEFINE REL2_BMP	"rel2.bmp"
#DEFINE REL3_BMP	"rel3.bmp"

*- help codes
#DEFINE HELP_wizTable_Wizard_Step_1		1999935411
#DEFINE HELP_wizTable_Wizard_Step_1a	1999935415
#DEFINE HELP_wizTable_Wizard_Step_2		1999935412
#DEFINE HELP_wizTable_Wizard_Step_3		1999935413
#DEFINE HELP_wizTable_Wizard_Step_3a	1999935416
#DEFINE HELP_wizTable_Wizard_Step_4		1999935414
#DEFINE HELP_wizTable_Wizard			1999935410

#DEFINE DTYPE1_LOC	"Character"
#DEFINE DTYPE2_LOC	"Currency"
#DEFINE DTYPE3_LOC	"Numeric"
#DEFINE DTYPE4_LOC	"Float"
#DEFINE DTYPE5_LOC	"Date"
#DEFINE DTYPE6_LOC	"DateTime"
#DEFINE DTYPE7_LOC	"Double"
#DEFINE DTYPE8_LOC	"Integer"
#DEFINE DTYPE9_LOC	"Logical"
#DEFINE DTYPE10_LOC	"Memo"
#DEFINE DTYPE11_LOC	"General"
#DEFINE DTYPE12_LOC	"Integer (AutoInc)"
#DEFINE DTYPE13_LOC	"Varchar"
#DEFINE DTYPE14_LOC	"Varbinary"
#DEFINE DTYPE15_LOC	"Blob"
#DEFINE DTYPE16_LOC	"Character (binary)"
#DEFINE DTYPE17_LOC	"Memo (binary)"
#DEFINE DTYPE18_LOC	"Varchar (binary)"

#DEFINE C_TBLEXT			"DBF"

#DEFINE C_MAXFIELDS			255
#DEFINE C_TOOMANYFLDS_LOC	"Tables may have up to " + LTRIM(STR(C_MAXFIELDS)) + " fields. Your table currently has: "
#DEFINE C_TBLERR_LOC		"Unable to create this table:"
#DEFINE C_IDXERR_LOC		"Unable to create the table and indexes."

#DEFINE C_BADCHARS_LOC		"The filename that you entered contains the following invalid character(s):"
#DEFINE C_TABLENAME_LOC		"Enter Table Name:"
#DEFINE C_TBLOVER_LOC		"already exists. Do you want to overwrite it?"
#DEFINE C_BADOPEN_LOC		"is in use or is read-only. Enter a different name."
#DEFINE C_BADFLD_LOC		"Field names must begin with a letter and can include A-Z, 0-9, and _. The name entered " + ;
							"contains the following invalid character(s):"
#DEFINE C_RESETINDEXKEY_LOC	"Memo, General, and Blob fields cannot be index keys. " + ;
							"This field will not be used as an index key"
				
#DEFINE C_ADDTOLIST_LOC		"Add to list"				&& prompt for GetFile() dialog for adding tables to list
#DEFINE C_ADDBUTTON_LOC		"Add"						&& text of button on GetFile() dialog for adding tables to list
#DEFINE C_CREATEDBC_LOC		"No database is open. Would you like to create a new database, and add the table to it? Captions can only be changed if the table belongs to a database."
#DEFINE C_DBCNAME_LOC		"DBC name:"
#DEFINE C_DEFDBCNAME_LOC	"Untitled.DBC"
#DEFINE C_TOOMANYSAME_LOC	"Too many fields have a similar name. Field will be skipped."
#DEFINE C_DUPENAME_LOC 		"Duplicate field name."
#DEFINE C_BLANKNAME_LOC 	"Please provide a field name."
#DEFINE C_NEWTABLENAME_LOC	"The table name has been changed due to a duplicate name in the database. The new name will be "


#DEFINE C_NEWTAG_LOC		"<New field>"

#DEFINE C_ISREL_LOC			"Is related to "
#DEFINE C_ISNOTREL_LOC		"Is not related to "

#DEFINE C_NOACTION_LOC		"The Wizard won't create a relationship."
#DEFINE C_1MANYRELATION_LOC	"The Wizard will create a relationship between the @1 field in your new @2 table and the field you choose in the list to the right."
#DEFINE C_MANY1RELATION_LOC	"The Wizard will create a relationship between the @1 field in the @2 table and the field you choose in the list to the right."	


#DEFINE ILLEGALCHAR_LOC		"Field names may contain alpha-numeric characters, and _, and must begin with a letter."

#DEFINE C_DUPEMSG_LOC		"A field with this name has already been selected."

#DEFINE MB_OK					0
#DEFINE MB_YESNO	    		4
#DEFINE MB_ICONQUESTION	    	32
#DEFINE MB_ICONEXCLAMATION  	48
#DEFINE MB_RET_YES				6

#DEFINE C_TBLINDBC1_LOC		" is a member of the currently open database ("
#DEFINE C_TBLINDBC2_LOC		"). If you overwrite it, any associated database information (such as persistent " + ;
							"relations, field captions, or rules) will be lost."
#DEFINE C_TBLINDBC3_LOC		"Do you want to overwrite it?"

#DEFINE C_OTHERDBC1_LOC		" is a member of this database: "
#DEFINE C_OTHERDBC2_LOC		". You must open this database before you can overwrite any tables in it."

#DEFINE C_NOWRITE_LOC		"), which is open SHARED. The database must be opened EXCLUSIVE before you can " + ;
							"overwrite any tables in it."

#DEFINE C_DBEXCL_LOC		"The current database must be opened EXCLUSIVE for the new table to be added to it. " 
							"A free table will be created instead. Do you want to continue?"
#DEFINE C_DBEXCL2_LOC		" must be opened EXCLUSIVE before new tables can be added to it. " 
							
							
#DEFINE C_OTHERTBL1_LOC		"The current database already has a table named "
#DEFINE C_OTHERTBL2_LOC		"Please use another name."

#DEFINE C_ADDING_LOC		"Adding "

#DEFINE C_TOOMANYCHARS_LOC  "This fieldname has too many characters. The maximum length is 10 Bytes. (128 bytes for a DBC)"

#DEFINE E_NOOPENFILE_LOC	"Unable to open the table "
#DEFINE E_TOOMANYCOL_LOC	"The maximum number of fields if null values are allowed is 254. Please remove a column if you would like to use null values."

#DEFINE I_MAXFILENAME_LEN	259
#DEFINE C_BADFILENAMELEN_LOC	"The filename is too long. The maximum total filename length is 259 characters."
* PIVOT WIZARD #INCLUDE file

* Help IDs
#DEFINE wizPivotTable_Wizard_Step3	95825422
#DEFINE wizPivotTable_Wizard_Step2	95825421
#DEFINE wizPivotTable_Wizard_Step1	95825420
#DEFINE wizPivotTable_Wizard		95825419

#DEFINE N_HELPCONTEXT_ID			1895825419

* Misc Error messages and prompts
#DEFINE		OS_W32S				1
#DEFINE		OS_NT				2
#DEFINE		OS_WIN95			3

#DEFINE MAX_RECORDS		500
#DEFINE MAX_PIVROWS		300
#DEFINE MAX_PIVCOLS		100
#DEFINE MAX_PIVPAGES	100
#DEFINE MAX_PIVCELLS	10000

#DEFINE		ODBC_FILE 			"ODBC.INI"
#DEFINE		ODBC_SOURCE			"ODBC Data Sources"
#DEFINE		ODBC_32SOURCE		"ODBC 32 bit Data Sources"
#DEFINE		ODBC_FTYPE			"filetype"
#DEFINE		ODBC_FOX_DSN		"FoxPro Files"
#DEFINE		ODBC_FOX_FIL		"FoxPro 2.6"
#DEFINE		ODBC_FOX_FIL3		"FoxPro 3.0"
#DEFINE 	FOXODBC_25			"FoxPro Files (*.dbf)"
#DEFINE 	FOXODBC_26			"Microsoft FoxPro Driver (*.dbf)"
#DEFINE 	FOXODBC_26FIX		"Microsoft FoxPro 2.6 Driver (*.dbf)"
#DEFINE 	FOXODBC_30			"Visual FoxPro"
#DEFINE 	FOXODBC_30a			"Visual FoxPro Database"
#DEFINE 	FOXODBC_30b			"Visual FoxPro Tables"
#DEFINE		C_DRIVEID			"DriverID"
#DEFINE		FOX_DRIVEID			24
#DEFINE 	ODBC_DATA_KEY		"Software\ODBC\ODBC.INI\"	&&ODBC Registry key
#DEFINE		C_FIL				"FIL"
#DEFINE		C_FOX2				"FoxPro 2.0"
#DEFINE 	HKEY_CLASSES_ROOT   -2147483648  && BITSET(0,31)
#DEFINE 	HKEY_CURRENT_USER   -2147483647  && BITSET(0,31)+1
#DEFINE 	HKEY_LOCAL_MACHINE  -2147483646  && (( HKEY ) 0x80000002 )
#DEFINE 	QUERY_ROOT			"Software\Microsoft\Shared Tools\MSQuery"

#DEFINE		DBFTYPE_30			48							&& SYS(2029) value for new 30 DBF
#DEFINE		OLE_XLAPP			"excel.application"			

#DEFINE 	DLLPATH_32S			"\SYSTEM\WIN32S\"
#DEFINE 	DLLPATH_NT			"\SYSTEM32\"
#DEFINE 	DLLPATH_WIN95		"\SYSTEM\"

#DEFINE		DLL_KERNEL_W32S		"W32SCOMB.DLL"
#DEFINE		DLL_KERNEL_NT		"KERNEL32.DLL"
#DEFINE		DLL_KERNEL_WIN95	"KERNEL32.DLL"

#DEFINE 	ERROR_SUCCESS		0
#DEFINE		ERROR_NOINIFILE		-108	&&no DLL file used to check ODBC
#DEFINE		ERROR_NOINIENTRY	-109	&&no entry found in INI file (section)
#DEFINE		ERROR_FAILINI		-110	&&no entry found in INI file

#DEFINE 	XL_EXT				"xls"
#DEFINE 	XL_CLASS			"Excel.Sheet"
#DEFINE 	XLPATH_KEY			"\Shell\Open\Command"

#DEFINE		E_NOPIVOTTBL_LOC	"Failed to create PivotTable Object."

#DEFINE		ALERTTITLE_LOC		"Microsoft Visual FoxPro Wizards"

#DEFINE		E_BADMSQUERY_LOC	"Microsoft Query has not been installed properly and is needed in order to create an Excel pivot table. Note: MS Query is an optional component that is not installed by default with newer versions of Office/Excel."
#DEFINE		E_ODBCDLL_LOC		"Could not check for proper ODBC installed files."
#DEFINE		E_XLBADSTATE_LOC	"Microsoft Excel is not in the right state to create a pivot table. Make sure that Excel isn't displaying any dialog boxes."
#DEFINE		E_ODBC1_LOC			"Could not check ODBC.INI file. Check to see if ODBC is properly installed."
#DEFINE		E_ODBC2_LOC			"Could not find FoxPro Files ODBC driver. Check to see if it is installed."
#DEFINE		E_ODBC3_LOC			"Invalid FoxPro Files entry in ODBC.INI file."
#DEFINE		E_NODBC_LOC			"The new Visual FoxPro 3.0 .DBF file format is not yet supported by the current ODBC drivers. You must use a FoxPro 2.x .DBF file."
#DEFINE		E_FAILXL_LOC		"Failed to get Excel OLE Object."
#DEFINE 	E_NOXLFILE_LOC		"Could not locate Microsoft Excel."
#DEFINE 	E_NOPIVTABLE_LOC	"An error occurred in Microsoft Excel during generation of the pivot table."
#DEFINE		E_OLDXLVER_LOC		"The wizard does not support your version of Microsoft Excel. You must have version 5.0 or later installed."
#DEFINE 	E_NOREG_LOC			"Microsoft Excel is not properly registered in the Windows registration table for use with OLE."
#DEFINE 	E_NOVIEWS_LOC		"Views are not supported by this wizard."
#DEFINE 	C_SAVEPROMPT_LOC	"Save form as:"
#DEFINE 	C_LOCATEDLL_LOC		"The wizard could not verify that you have ODBC installed. "+;
								"Do you want to continue with the assumption that it is?"
#DEFINE 	C_LOCATEXL_LOC		"The wizard could not verify that you have Microsoft Excel 5.0 or later installed. "+;
								"Do you want to continue with the assumption that it is?"
#DEFINE 	C_COPYFOX2_LOC		"You do not have ODBC drivers for Visual FoxPro 3.0 tables/views. "+;
								"Would you like to copy the selected table to a FoxPro 2.5 "+;
								"format so that a pivot table can be generated from it?"
#DEFINE 	C_COPYPROMPT_LOC	"Copy table to:"
#DEFINE 	C_LARGEPIVOT_LOC	"You have selected a potentially large pivot table result set. "+;
								"Do you want to continue?"
#DEFINE		C_LONGFNAME_LOC		"You have an old FoxPro ODBC Data Source installed which does not support FoxPro tables with long or illegal DOS path and file names. "+;
								"We suggest that you install the VFP ODBC Driver to prevent this message in the future. "+;
								"If you choose to continue, you must either rename or copy the selected table to one with a standard DOS file name. Would you like to copy the file now?"
#DEFINE		C_ODBCOLDVER_LOC	"The Version setting in your FoxPro Files ODBC Data Source is set for FoxPro 2.0 files. "+;
								"The PivotTable Wizard may not properly handle international characters or General fields. "+;
								"You can change this setting to FoxPro 2.6 using the ODBC Control Panel."
#DEFINE 	C_NORECORDS_LOC		"The table selected contains no records. An Excel pivot table will not be created."
#DEFINE		C_VFPDRVONLY_LOC	"The PivotTable Wizard has detected the presence of the VFP ODBC Driver, however, "+;
								"no VFP ODBC Data Source exists. You can create a new VFP ODBC Data Source from the ODBC Control Panel. "+;
								"The Wizard will try to use an older ODBC driver this time."
#DEFINE ERR_DBCEXCL_LOC		"Your database is opened exclusively. Excel cannot create a Pivot table unless the database is opened shared. Please select another database or quit the Wizard and reopen your database shared."

***** Dropdown list selector
#define CRET		CHR(13)
#define STEP1_LOC	"Step 1 - Select Fields"
#define STEP2_LOC	"Step 2 - Define Layout"
#define STEP3_LOC	"Step 3 - Finish"

***** Screen directions
#define DESC1a_LOC	"Which fields do you want in your pivot table?"
#define DESC1c_LOC	"Select a database or Free Tables item, select a table or view, and then select the fields you want."
#define DESC1		DESC1a_LOC+CRET+CRET+DESC1c_LOC


#define DESC2a_LOC	"How do you want to lay out your pivot table?"
#define DESC2b_LOC	"Drag available fields to the pivot table locations."
#define DESC2		DESC2a_LOC+CRET+CRET+DESC2b_LOC

***** Screen hint button text
#define HINT1_LOC	""
#define HINT2_LOC	""
#define HINT3_LOC	""

***** Screen BMP files
#define BMPFILE1	"opentabl.bmp"
#define BMPFILE2	"pivot2.bmp"

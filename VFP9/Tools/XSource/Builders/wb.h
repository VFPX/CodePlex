* Filename:		WB.H
* Description:	Header file for WB.PRG.
* -----------------------------------------------------------------------------------------

* Localizable directives (roughly alphabetical)

#DEFINE C_BADWIZPLATFORM_LOC	"Wizards will run only under the Windows version of Visual FoxPro 5.0 or higher."
#DEFINE C_BADBDRPLATFORM_LOC	"Builders will run only under the Windows version of Visual FoxPro 5.0 or higher."
#DEFINE C_BADREGOPEN_LOC		"Error opening the registration table: "
#DEFINE C_BADREGTABLE_LOC		" has an incorrect structure. Would you like to recreate the registration table?"
#DEFINE C_BADWIZVERSION_LOC		"Wizards will run only in Visual FoxPro 5.0 or higher."
#DEFINE C_BADBDRVERSION_LOC		"Builders will run only in Visual FoxPro 5.0 or higher."
#DEFINE C_FINDWIZREG_LOC		"The Wizard registration table is missing."
#DEFINE C_FINDBDRREG_LOC		"The Builder registration table is missing."
#DEFINE C_LOCORMAKE_LOC			"Do you want to locate it, or create a new one?"
#DEFINE C_LOCATE_LOC			"Locate "
#DEFINE C_MAKEREGERROR_LOC		"An error occurred when creating the registration table. Try again?"
#DEFINE C_MSG1_LOC				"Line: "
#DEFINE C_NOWIZARDS_LOC			"No wizards were found. Would you like to create a new registration table?"
#DEFINE C_NOBUILDERS_LOC		"No builders were found. Would you like to create a new registration table?"
#DEFINE C_NOWIZNAME_LOC			"The specified wizard was not found."
#DEFINE C_NOBDRNAME_LOC			"The specified builder was not found."
#DEFINE C_NOWIZLIB_LOC			"There are no registered wizards of this type."
#DEFINE C_NOBDRLIB_LOC			"There are no registered builders of this type."
#DEFINE C_NOWIZREG_LOC			"There are no registered wizards of this type."
#DEFINE C_NOBDRREG_LOC			"There are no registered builders of this type."
#DEFINE C_NOLIB2_LOC			"Please locate the class library which contains this definition."
#DEFINE C_NOWIZDESC_LOC			"There is no description for this wizard."
#DEFINE C_NOBDRDESC_LOC			"There is no description for this builder."
#DEFINE C_PRG_LOC				"Program:    "
#DEFINE C_RSCERROR_LOC			"Error opening resource file:"
#DEFINE C_RUNTIMEWIZ_LOC		"Wizards will run only under the development version"
#DEFINE C_RUNTIMEBDR_LOC		"Builders will run only under the development version"
#DEFINE C_SELDIR_LOC			"Select directory:"
#DEFINE C_STATMSGWIZ_LOC		"Microsoft Visual FoxPro Wizards"
#DEFINE C_STATMSGBDR_LOC		"Microsoft Visual FoxPro Builders"
#DEFINE C_UNSUPPORTED_LOC		"Your control is set to a property that the builder does not support: "
#DEFINE C_PICKWIZ_LOC			"Select the wizard you would like to use:"
#DEFINE C_PICKBDR_LOC			"Select the builder you would like to use:"
#DEFINE C_BADOPEN_LOC			"is in use or is read-only."
#DEFINE C_REGTBLSTRING_LOC		"Registration Table"
#DEFINE C_WIZSELECT_LOC			"Wizard Selection"
#DEFINE C_BDRSELECT_LOC			"Builder Selection"

#DEFINE MB_MSGBOXWIZTITLE_LOC	"FoxPro Wizards"
#DEFINE MB_MSGBOXBDRTITLE_LOC	"FoxPro Builders"
#DEFINE C_ERRGENERIC_LOC		"An error has occurred in: "


* Other directives

#DEFINE C_DEBUG					.t.
#DEFINE N_MINFOXVERSION			5							&& Minimum Foxversion
#DEFINE C_FOXVERSION			"FOXPRO 06.00"				&& FoxPro version
#DEFINE C_DIRWIZ				"WIZARDS\"
#DEFINE C_DIRBDR				"WIZARDS\"					&& may be BUILDER\ later
#DEFINE C_LIBWIZ				"WIZARD.VCX"				&& default wizard class library
#DEFINE C_LIBBDR				"BUILDER.VCX"				&& default wizard class library
#DEFINE C_MODIFY				"MODIFY"					&& modify option keyword
#DEFINE C_NOSCRN				"NOSCRN"					&& no screens option keyword
#DEFINE C_REGDBFWIZ				"WIZARD.DBF"				&& names for default tables
#DEFINE C_REGFPTWIZ				"WIZARD.FPT"
#DEFINE C_REGDBFBDR				"BUILDER.DBF"
#DEFINE C_REGFPTBDR				"BUILDER.FPT"
#DEFINE C_TPLDBFWIZ				"WREGTBL"					&& template reg tables, burned into app
#DEFINE C_TPLDBFBDR				"BREGTBL"
#DEFINE C_WINLIBRARY			"FT3.DLL"					&& latest version of foxtools.fll
#DEFINE C_ALL					"ALL"
#DEFINE C_WIZAPP				"WIZARD.APP"
#DEFINE C_BDRAPP				"BUILDER.APP"

#DEFINE MB_OK		    		0							&& MessageBox codes
#DEFINE MB_OKCANCEL	    		1
#DEFINE MB_ABORTRETRYIGNORE 	2
#DEFINE MB_YESNOCANCEL	    	3
#DEFINE MB_YESNO	    		4
#DEFINE MB_RETRYCANCEL	    	5
#DEFINE MB_TYPEMASK	    		5

#DEFINE MB_ICONHAND	    		16
#DEFINE MB_ICONQUESTION	    	32
#DEFINE MB_ICONEXCLAMATION  	48
#DEFINE MB_ICONASTERISK     	64
#DEFINE MB_ICONMASK	    		240

#DEFINE MB_ICONINFORMATION  	64
#DEFINE MB_ICONSTOP         	16

#DEFINE MB_DEFBUTTON1	    	0
#DEFINE MB_DEFBUTTON2	    	256
#DEFINE MB_DEFBUTTON3	    	512
#DEFINE MB_DEFMASK	    		3840

#DEFINE MB_APPLMODAL	    	0
#DEFINE MB_SYSTEMMODAL	    	4096
#DEFINE MB_TASKMODAL	    	8192

#DEFINE MB_NOFOCUS	    		32768

#DEFINE MB_RET_OK				1							&& MessageBox return values
#DEFINE MB_RET_CANCEL			2
#DEFINE MB_RET_ABORT			3
#DEFINE MB_RET_RETRY			4
#DEFINE MB_RET_IGNORE			5
#DEFINE MB_RET_YES				6
#DEFINE MB_RET_NO				7

* -----------------------------------------------------------------------------------------
* EOF() - WB.H

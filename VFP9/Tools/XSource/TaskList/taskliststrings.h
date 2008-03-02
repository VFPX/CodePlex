#ifndef __TASKLISTSTRINGS_H
#define __TASKLISTSTRINGS_H

*-- TaskListStrings header file
#define APP_TITLE_LOC			"Task List"
#define APP_CAPTION_LOC			"Tasks"

*-- Context Menu Strings
*-- \< Indicates hot key

#define CTM_SPACER			"\-"

#define CTM_OPEN_TASK_LOC 		"Open \<Task"
#define CTM_PRINT_LOC			"\Print"
#define CTM_OPEN_FILE_LOC		"Open \<File "
#define CTM_IMPORT_LOC			"\Import Tasks..."
#define CTM_EXPORT_LOC			"\Export Task..."
#define CTM_COMPLETE_LOC		"\<Mark as Complete"
#define CTM_UNREAD_LOC			"Mar\<k as Unread"
#define CTM_READ_LOC			"Mar\<k as Read"
#define CTM_DELETE_LOC			"\<Delete Task"
#define CTM_SHOWTASKS_LOC		"\<Show Tasks"
#define CTM_COLUMNCHOOSER_LOC	"\<Column Chooser..."
#define CTM_REMOVECOLUMN_LOC	"\<Remove This Column"
#define CTM_OPTIONS_LOC			"\<Options"

#define CTM_SHORTCUTS_LOC		"Shortcuts"
#define CTM_USERDEFINED_LOC		"User Defined Tasks"
#define CTM_OTHER_LOC			"Other Tasks"

#define CLICK_HERE_LOC		"Click here to add a new task"

*-- Other products
#define OP_MS_OUTLOOK_LOC	"MS Outlook"
#define OP_MS_PROJECT_LOC	"MS Project"
#define OP_MS_EXCEL_LOC		"MS Excel"
#define OP_MS_VID_LOC		"MS Visual InterDev"
#define OP_MS_VS_LOC		"MS Visual Studio 7.0"

#define ERROR_OCCURRED_LOC	"A run-time error occurred."
#define ERROR_ERROR_LOC		"Error:"
#define ERROR_METHOD_LOC	"Method:"
#define ERROR_LINE_LOC		"Line:"
#define ERROR_QUERY_LOC		"An error occurred during the requery. The tasklist will be closed."
#define ERROR_DUPFIELD_LOC	"A field was duplicated in the main and UDF tables. The UDF table has been removed."
#define ERROR_PACKDBF		"Cannot get exclusive access to Task List table for cleanup.  It may be open in another session of Visual FoxPro."
#DEFINE ERROR_NOINIT_LOC	"Unable to initialize the Task List. Make sure the task table is available."

#define DELETE_TASK_LOC		"Are you sure you want to delete this task?"

#define PRIORITY_HIGH_LOC	"High"
#define PRIORITY_NORMAL_LOC	"Normal"
#define PRIORITY_LOW_LOC	"Low"

#define DEFCOL_ID_LOC		"ID"
#define DEFCOL_CONTENTS_LOC	"Contents"
#define DEFCOL_FILENAME_LOC	"File Name"
#define DEFCOL_DUEDATE_LOC	"Due Date"
#define DEFCOL_PRIORITY_LOC	"!"

*-- Custom formats for the Microsoft Date Time Picker control
#define DATE_FORMAT_LOC			"M/d/yyy"
#define DATETIME_FORMAT_LOC		"M/d/yyy hh:mm:ss"
#define TIME_FORMAT_LOC			" hh:mm:ss"

#define TASK_TYPE_SHORTCUT_LOC		"Shortcut"
#define TASK_TYPE_OTHER_LOC			"Other Task"
#define TASK_TYPE_USERDEFINED_LOC	"User-Defined Task"

#define TASKPROPERTIES_LOC		"Task Properties"
#define TASK_LOC				"Task"      		&& to-do
#define FIELDS_LOC				"Fields"    		&& table columns
#define CONTENTS_LOC			"Contents"  		&& what's inside
#define FILENAME_LOC			"File Name"
#define CLASS_LOC				"Class"     		&& object definition
#define METHOD_LOC				"Method"			&& function
#define LINE_LOC				"Line"				&& line number
#define DUEDATE_LOC				"Due Date"
#define PRIORITY_LOC			"Priority"
#define READ_LOC				"Read"				&& Read/Unread
#define COMPLETE_LOC			"Complete"

#define APP_TITLE				"Tasks"
#define BROWSE_LOC				"\<Browse"
#define OK_LOC					"OK"
#define CANCEL_LOC				"Cancel"
#DEFINE CLOSE_LOC				"Close"
#define APPLY_LOC				"\<Apply"
#define ELIPSES_LOC				"..."
#define OPTIONS_LOC				"Tasklist Options"
#define CLEAR_LOC				"\<Clear"
#define NEW_LOC					"\<New"
#define MODI_LOC				"\<Edit Structure"
#define UDF_COLUMN_LOC			"\<User-defined column table"
#define FILE_LOC				"File"
#define CLEANUP_LOC 			"Clean Up \<FoxTask"

#define MSGBOX_CLEANUP			"This option cleans up your FoxTask table. Proceed?"

#define FILE_NOT_EXIST_LOC		"The file associated with this shortcut does not exist." + ;
								Chr(13) +  "Would you like to delete this shortcut?"

#define BAD_CHILD_DATA_LOC		"The table chosen is either not accessible or " + Chr(13) + ;
								"does not meet the requirements for Tasklist data sources." + Chr(13) + Chr(13) + ;
								"Please review the documentation for more" + Chr(13) + ;
  								"information about user-defined data sources."

#define ERROR_NO_FILENAME_LOC	"No association could be determined for the filename passed."
#define ERROR_BAD_ASSOC_LOC		"The application associated with this task could not open the task."
#define ERROR_NO_APP_LOC		"There is no application associated with this task."
#define ERROR_APP_BUSY_LOC		"The application associated with this task is busy."
#define ERROR_FAIL_LOAD_LOC		"The application associated with this task failed to load."

#DEFINE ERROR_NOCREATEFILE_LOC	"The table @@ could not be created."
	
#endif
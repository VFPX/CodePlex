#ifndef __TASKLIST_H
#define __TASKLIST_H

#include "TaskListStrings.h"
#include "FoxPro.h"
#include "xml.h"
#include "twips.h"
#include "outlook.h"

*-- TaskList Header File
*--

#define PREF_COLUMNS	"TASKCOLS"
#define PREF_FORMINFO	"TASKFORM"
#define PREF_EDITINFO 	"TASKEDIT"
#define PREF_ORDERBY	"TASKORD"
#define PREF_STATE		"TASKSTAT"
#DEFINE PREF_CELLINFO	"TASKCELL"

*-- Context Menu
#define _MTM_OPEN_TASK		10
#define _MTM_PRINT 			20
#define _MTM_SPACER100 		30
#define _MTM_OPEN_FILE		40
#define _MTM_SPACER200		50
#define _MTM_IMPORT			70
#define _MTM_EXPORT			80
#define _MTM_SPACER400		130
#define _MTM_COMPLETE		140
#define _MTM_READ			150
#define _MTM_UNREAD			160
#define _MTM_SPACER500		170
#define _MTM_DELETE			180
#define _MTM_SPACER600		190
#define _MTM_REMOVECOLUMN	200
#define _MTM_COLUMNCHOOSER	210
#define _MTM_SHOWTASKS		220
#define _MTM_SPACER700		230
#define _MTM_OPTIONS		240

#define _MTM_SHOW_SHORTCUTS		10
#define _MTM_SHOW_USERDEFINED	20
#define _MTM_SHOW_OTHER			30

#define TASK_TYPE_USERDEFINED	"U"
#define TASK_TYPE_OTHER			"O"
#define TASK_TYPE_SHORTCUT		"S"
*-- Add support for OLE Drag/Drop of files
#define TASK_TYPE_OLEDRAGDROP   "D"

#define EDIT_OFF		0
#define EDIT_TEXT		1
#define EDIT_COMBO		2
#define EDIT_DATE		4
#define EDIT_DATETIME	8
#define EDIT_NEW		32
#DEFINE EDIT_MOVE		128		&& not editing, just moving
#define EDIT_CANCEL		256

#define COL_FIELD		1
#define COL_CAPTION		2
#define COL_WIDTH		3
#define COL_ORDER		4

#define ORDER_NONE		0
#define ORDER_ASC		1
#define ORDER_DESC		2

#define PEM_CHANGED 	0
#define PEM_READONLY	1
#define PEM_PROTECTED	2
#define PEM_TYPE		3
#define PEM_UDF			4
#define PEM_DEFINED		5
#define PEM_INHERITED	6

#define OPEN_MAIN		1
#define OPEN_CHILD		2

#define CLOSE_ALL		0
#define CLOSE_MAIN		1
#define CLOSE_CHILD		2

#define CRYPT_TEXT		"VFP7Rocks!"

#define flexAlignLeftTop 		0 
#define flexAlignLeftCenter 	1 
#define flexAlignLeftBottom 	2 
#define flexAlignCenterTop 		3 
#define flexAlignCenterCenter 	4 
#define flexAlignCenterBottom 	5 
#define flexAlignRightTop 		6 
#define flexAlignRightCenter 	7 
#define flexAlignRightBottom 	8 

#define IMAGE_NM_PRILOW		1
#define IMAGE_NM_PRINORMAL	2
#define IMAGE_NM_PRIHIGH	3
#define IMAGE_NM_COMPILE	4
#define IMAGE_NM_SHORTCUT	5
#define IMAGE_NM_TASK		6
#define IMAGE_NM_CHECKO		7
#define IMAGE_NM_CHECKX		8

#define STATUS_FLAGGED		1
#define STATUS_READ			2
#define STATUS_COMPLETE		4
#define STATUS_DELETED		8

#define PRIORITY_LOW		0
#define PRIORITY_NORMAL		1
#define PRIORITY_HIGH		2

#define ASCII_ESC			27
#define ASCII_ENTER			13
#define ASCII_TAB			9
#define ASCII_BACKTAB		15
#define ASCII_DNARROW		24
#define ASCII_UPARROW		5

#define SELECT_CELLS		0
#define SELECT_ROWS			1
#define SELECT_COLUMNS		2

#define DEFAULT_COLUMN_WIDTH	1500
#define DEFAULT_DATE_WIDTH		1520

#DEFINE C_COL_DRAG_PREFIX	";;;@@@"	&& some prefix to indicate this is a column

#define UNREMOVABLE_COLUMNS "_uniqueid","_priority","_status","_type","_contents"

#define dtpLongDate		0
#define dtpShortDate 	1
#define dtpTime 		2
#define dtpCustom 		3

#define SHOW_MODAL		1

#define ERROR_UNKNOWN	0
#define ERROR_IGNORE	1
#define ERROR_DEBUG		3		&& Remove this after development
#define ERROR_QUERY		2

#define S_NO_EDIT_COLUMNS "_filename","_class","_method","_line","_contents"
#define DEFAULT_FIELDS	"_contents","_filename","_class","_method","_line","_duedate","_priority","_status","_timestamp","_type","_uniqueid"

#define LAUNCH_CONTEXT			0
#define LAUNCH_TASK				1
#define LAUNCH_ADD_COLUMN		2
#DEFINE LAUNCH_ADD_TASK			3
#DEFINE LAUNCH_NOTHING			-1

#define LAUNCH_BY_MOUSE			0
#define LAUNCH_BY_KEYBOARD		1

#define EDITSOURCE_NOWAIT	"W"
#define EDITSOURCE_NOEDIT	"E"
#define EDITSOURCE_NOMENU	"M"
#define EDITSOURCE_SAVE		"S"

#define SHELL_EX_NO_FILENAME	-1
#define SHELL_EX_BAD_ASSOC		2
#define SHELL_EX_NO_APP			31
#define SHELL_EX_APP_BUSY		30
#define SHELL_EX_FAIL_LOAD		29

#endif

*-- Registry constants
#DEFINE HKEY_CLASSES_ROOT -2147483648
#DEFINE HKEY_CURRENT_USER -2147483647
#DEFINE HKEY_LOCAL_MACHINE -2147483646
#DEFINE HKEY_USERS -2147483645
#DEFINE REG_SZ 1
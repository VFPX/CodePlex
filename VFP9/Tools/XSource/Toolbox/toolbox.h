#define TOOLBOX_LOC						"Toolbox"


* used by ToolBox.ShowType field
#define SHOWTYPE_CATEGORY	'C'
#define SHOWTYPE_TOOL		'T'
#define SHOWTYPE_FAVORITES	'F'
#define SHOWTYPE_FILTER		'S'
#define SHOWTYPE_FILTERITEM	'I'

* add-ins that shows on the menu
#define SHOWTYPE_ADDIN		'A'
#define SHOWTYPE_ADDINMENU	'M'  && menu option only

* -- Default classes and class library

* this is the vcx that should be found in HOME() + "Toolbox"
#define DEFAULT_CLASSLIB		"_toolbox.vcx"

* if we don't find the above, we maintain a copy internal to the APP
#define INTERNAL_CLASSLIB		"_toolboxdefault.vcx"

#define FILTERCLASS_NAME		"_filter"
#define FILTERCLASS_ITEM		"_filteritem"

#define CATEGORYCLASS_GENERAL	"_generalcategory"
#define CATEGORYCLASS_FAVORITES	"_favoritescategory"

#define ITEMCLASS_ROOT			"_root"
#define ITEMCLASS_TOOL			"_tool"
#define ITEMCLASS_CLASS			"_classtool"
#define ITEMCLASS_ACTIVEX		"_activextool"
#define ITEMCLASS_TEXTSCRAP		"_textscraptool"

#define SCROLLSPEED_DEFAULT		30
#define FONT_DEFAULT			"Tahoma,8,N"

#define DRAGSTATE_START		1
#define DRAGSTATE_COMPLETE	2

#define NEWLINE				CHR(13) + CHR(10)

#define tvwFirst	0
#define tvwLast		1
#define tvwNext		2
#define tvwPrevious	3
#define tvwChild	4


#define WIN_PJX_DESIGN_LOC			"PROJECT MANAGER -"
#define WIN_SCX_DESIGN_LOC			"FORM DESIGNER -"
#define WIN_VCX_DESIGN_LOC			"CLASS DESIGNER -"
#define WIN_FRX_DESIGN_LOC			"REPORT DESIGNER -"
#define WIN_MNX1_DESIGN_LOC			"MENU DESIGNER -"
#define WIN_MNX2_DESIGN_LOC			"SHORTCUT DESIGNER -"
#define WIN_DBC_DESIGN_LOC			"DATABASE DESIGNER -"


#define VFP_OPTIONS_KEY				"Software\Microsoft\VisualFoxPro\"
#define VFP_OPTIONS_KEY2			"\Options\OLEList"
#define HKEY_CLASSES_ROOT			-2147483648  && BITSET(0,31)
#define HKEY_CURRENT_USER			-2147483647  && BITSET(0,31)+1
#define CLSID_KEY					"CLSID"
#define PROGID_KEY					"\ProgID"
#define CONTROL_KEY					"Control"
#define SERVER_KEY					"Programmable"
#define SHELL_KEY					"\Shell\"
#define INPROC_KEY					"InProcServer32"
#define LOCALSVR_KEY				"LocalServer32"

#define INTELLIDROP_KEY				"Software\Microsoft\VisualFoxPro\" + _VFP.Version + "\Options\IntelliDrop\FieldTypes\"

#define TOOLBOX_HELPID				1231116

* The following are invalid in object name so we strip them out if we find them in a filename
#define INVALID_OBJNAME_CHARS	" -!@#$%^&*()+={}[]:;?/<>,\|~`'" + ["]


* -- Toolbox localizations
#define TOOL_TEXTPREFIX_LOC				"Text: "

#define TOOLMENU_RENAME_LOC				"\<Rename"
#define TOOLMENU_DELETE_LOC				"\<Delete"
#define TOOLMENU_MODIFY_LOC				"\<Modify"
#define TOOLMENU_OPEN_LOC				"\<Open"
#define TOOLMENU_RUN_LOC				"R\<un"
#define TOOLMENU_BROWSE_LOC				"Bro\<wse"
#define TOOLMENU_CREATEFORM_LOC			"\<Create Form"
#define TOOLMENU_ADDTO_LOC				"Add \<to"
#define TOOLMENU_CREATESUBCLASS_LOC		"Create \<Subclass"
#define TOOLMENU_ADDCATEGORY_LOC		"Add Cate\<gory"
#define TOOLMENU_ADDCLASSLIB_LOC		"Add Class Librar\<y"
#define TOOLMENU_REFRESHCATEGORY_LOC	"Re\<fresh Category"
#define TOOLMENU_CUSTOMIZE_LOC			"Customize Toolbo\<x"
#define TOOLMENU_REFRESH_LOC			"R\<efresh Toolbox"
#define TOOLMENU_HELPTEXT_LOC			"Display \<Help Text"
#define TOOLMENU_ALWAYSONTOP_LOC		"\<Always on Top"
#define TOOLMENU_BUILDERLOCK_LOC		"\<Builder Lock"

#define TOOLMENU_PROPERTIES_LOC			"\<Properties"
#define TOOLMENU_FILTERS_LOC			"F\<ilter"
#define TOOLMENU_NOFILTER_LOC			"none"
#define TOOLMENU_COPYTOCLIPBOARD_LOC	"C\<opy to Clipboard"
#define TOOLMENU_ADDTOFAVORITES_LOC		"Add to Fa\<vorites"
#define TOOLMENU_ITEMHELP_LOC			"He\<lp"
#define TOOLMENU_DOCKED_LOC				"D\<ocked"
#define TOOLMENU_OPENOBJECTBROWSER_LOC	"\<Open in Object Browser"

#define TOOL_NEW_LOC					"New"

#define TOOL_DELETE_LOC					"Are you sure you want to remove the following item from the toolbox?"
#define TOOL_DELETECATEGORY_LOC			"Are you sure you want to delete this category from the toolbox?"
#define TOOL_DELETEFILTER_LOC			"Are you sure you want to delete this filter?"
#define TOOL_REMOVEFAVORITES_LOC		"Remove from favorites?"

#define TOOL_CREATECATEGORYMSG_LOC		"Name of new category:"
#define TOOL_NEWCATEGORY_LOC			"New Category"
#define TOOL_DUPLICATECATEGORY_LOC		"Category name is already defined."
#define TOOL_DUPLICATEFILTER_LOC		"Filter name is already defined."

#define LOCATE_FOLDERNOEXIST_LOC		"The specified folder does not exist." + CHR(10) + CHR(10) + "Create it now?"
#define LOCATE_NOCREATE_LOC				"Unable to create toolbox table in specified folder."
#define LOCATE_NOTFOUND_LOC				"The specified Toolbox table could not be found."

#define ADDCLASSLIB_NOCLASSLIB_LOC		"You must specify the name of the class library to add."
#define ADDCLASSLIB_NOEXIST_LOC			"The specified class library does not exist."

* default new filter name - the '#' is replaced with an actual number
#define NEWFILTER_LOC					"Filter #"

#define REFRESHING_TOOLBOX_LOC			"Refreshing Toolbox:"
#define REFRESHING_CATEGORY_LOC			"Refreshing Category:"

* for the Customize Toolbox form
#define CUSTOMIZE_ALL_LOC	            "<all>"
#define CUSTOMIZE_CLASSLIBRARIES_LOC	"Visual FoxPro Class Libraries"
#define CUSTOMIZE_ACTIVEX_LOC	        "ActiveX Controls"
#define CUSTOMIZE_FILES_LOC	            "Files"

#define CUSTOMIZE_REMOVELIBRARY_LOC		"Would you like to remove this library's classes from the Toolbox?"
#define CUSTOMIZE_REMOVELIBRTITLE_LOC	"Remove Library"
#define CUSTOMIZE_ADDLIBRARY_LOC		"Add Library"
#define CUSTOMIZE_REMOVE_LOC			"Remove"

#define CUSTOMIZE_REMOVEALL_LOC			"Are you sure you want to remove all tools from this category?"

#define CUSTOMIZE_ADDBASECLASSES_LOC	"Add all Visual FoxPro base classes to this category?"
#define CUSTOMIZE_GENERAL_LOC			"General"
#define CUSTOMIZE_OPTIONS_LOC			"Options"
#define CUSTOMIZE_CLASSOPTIONS_LOC		"Class Items"
#define CUSTOMIZE_FILTERS_LOC			"Filters"
#define CUSTOMIZE_CATEGORIES_LOC		"Categories"

#define CUSTOMIZE_TODEFINENEWFILTER_LOC "To define a new filter, click the New Filter button on the toolbar."
#define CUSTOMIZE_NOCURRENTFILTER_LOC	"(none - all categories are visible)"
#define CUSTOMIZE_FILTERNAMEREQUIRED_LOC "You must specify the name of this filter."

#define CUSTOMIZE_DISCARDCHANGES_LOC	"Discard your changes to the Toolbox?"
#define CUSTOMIZE_NOEXIST_LOC			"The specified toolbox table does not exist."

#define CUSTOMIZE_REFRESHTOOLBOX_LOC	"Do you want to refresh all categories in the toolbox?"
#define CUSTOMIZE_CLEANUP_LOC			"Are you sure you want to cleanup your Toolbox table?"
#define CUSTOMIZE_CLEANUPDONE_LOC		"The Toolbox table has been successfully cleaned up." + CHR(10) + "A backup of the original Toolbox table was saved to:"
#define CUSTOMIZE_RESTORE_LOC			"Do you want to maintain new categories and toolbox items that were added" + CHR(10) + "by you or a third-party vendor?"
#define CUSTOMIZE_RESTOREDONE_LOC		"The Toolbox table has been restored to the original." + CHR(10) + "A backup of the original Toolbox table was saved to:"

#define CUSTOMIZE_NOEXISTCREATE_LOC		"The specified Toolbox table does not exist." + CHR(10) + CHR(10) + "Do you want to create it?"
#define CUSTOMIZE_NOSAVEOPTIONS_LOC		"Unable to save the current toolbox options."

* displayed in place of backed up file if a backup could not be done
#define CUSTOMIZE_NONE_LOC				"<none>"

#define CUSTOMIZE_DYNAMICCATEGORY_LOC	"Dynamic Category - click on Category Properties to modify"


#define CATEGORYREQUIRED_LOC   			"You must specify the name of the category."

#define UNABLETOOPEN_LOC				"Unable to open toolbox."

#define ERROR_BADTABLE_LOC				"Toolbox table has the wrong table structure:"
#define ERROR_CREATEOBJECT_LOC			"Unable to create object:"
#define ERROR_CLEANUP_LOC				"Unable to cleanup Toolbox table due to the following error:"
#define ERROR_RESTORETODEFAULT_LOC		"Unable to restore to the original Toolbox table due to the following error:"
#define ERROR_NOBACKUP_LOC				"Unable to create a backup of the current Toolbox." + CHR(10) + CHR(10) + "Do you still want to proceed?"


#define ERROR_INVALIDCONTAINER_LOC		"Container is not valid for this object."
#define ERROR_MEMBERCLASS_LOC			"Unable to set the member class for this object."
#define ERROR_NONCONTAINER_LOC			"Cannot add objects to non-container classes."
#define ERROR_NONVISUALDROP_LOC			"This class has no visual representation and therefore cannot be dropped onto this container."

#define ERROR_DROPHOOK_LOC				"Error encountered executing _DropHook code:"

#define SCAN_REGISTRY_LOC "Scanning Registry for Components..."

#define DATAVALUE_CLASSLIBRARY_LOC				"Class library"
#define DATAVALUE_CLASSNAME_LOC					"Class name"
#define DATAVALUE_CONTAINERCLASSLIBRARY_LOC		"Parent class"
#define DATAVALUE_CONTAINERCLASSNAME_LOC		"Parent class name"

#define DATAVALUE_OBJECTNAME_LOC				"Object name"
#define DATAVALUE_PARENTCLASS_LOC				"Parent class"
#define DATAVALUE_BASECLASS_LOC					"Base class"
#define DATAVALUE_FILENAME_LOC					"File name"
#define DATAVALUE_TABLENAME_LOC					"Table"
#define DATAVALUE_FIELDNAME_LOC					"Field"
#define DATAVALUE_PROPERTIES_LOC				"Properties"
#define DATAVALUE_COMCOMPONENT_LOC				"COM Component"
#define DATAVALUE_REFRESHCATEGORY_LOC			"Refresh category after running application"
#define DATAVALUE_BUILDER_LOC					"Builder"

#define DATAVALUE_TEXTSCRAP_LOC					"Text scrap"
#define DATAVALUE_SCRIPT_LOC					"Script"
#define DATAVALUE_COMPLETESCRIPT_LOC			"Complete drag script"
#define DATAVALUE_TEXTMERGE_LOC					"Evaluate using text merge"

* used by _WebServiceCategory behavior class
#define DATAVALUE_TEMPLATE_LOC					"Template"

* used by _WebService behavior class
#define DATAVALUE_WSDL_LOC						"WSDL"
#define DATAVALUE_URI_LOC						"URI"
#define DATAVALUE_PORT_LOC						"Port"
#define DATAVALUE_SERVICE_LOC					"Service"
#define DATAVALUE_WSML_LOC						"WSML"
#define DATAVALUE_CLASS_LOC						"Class"


* used in _foldercategory
#define DATAVALUE_FOLDER_LOC					"Folder"
#define DATAVALUE_FILETYPES_LOC					"File type"


* -- Used in the ToolboxProperties form
#define PROPERTIES_NONAME_LOC					"The name is required."
#define PROPERTIES_NOTOOLNAME_LOC				"You must specify the name of the item."
#define PROPERTIES_NOCATEGORYNAME_LOC			"You must specify the name of the category."

* displayed in help while loading
#define LOADING_LOC								"Loading Toolbox..."

#define YES_LOC									"Yes"
#define NO_LOC									"No"

#define MENU_RENAMEITEM_LOC						"Rename Item"
#define MENU_DELETEITEM_LOC						"Delete Item"
#define MENU_MODIFYITEM_LOC						"Modify Item"
#define MENU_ADDCATEGORY_LOC					"Add Category"
#define MENU_SELECTALL_LOC						"Select \<All"
#define MENU_DESELECTALL_LOC					"\<Clear All"
#define MENU_SORTALPHA_LOC						"\<Sort Alphabetically"
#define MENU_REMOVE_LOC							"\<Remove"
#define MENU_REMOVEALL_LOC						"R\<emove All"
#define MENU_PROPERTIES_LOC						"Item \<Properties"


* used by CFoxFileTypesCombo class
#define FILETYPE_ALL_LOC						"All Files (*.*)"
#define FILETYPE_COMMON_LOC						"Common (*.scx;*.vcx;*.prg;*.frx;*.lbx;*.mnx;*.dbc;*.qpr;*.h)"
#define FILETYPE_SOURCE_LOC						"All Source (*.scx;*.vcx;*.prg;*.frx;*.lbx;*.mnx;*.dbc;*.dbf;*.cdx;*.qpr;*.h)"
#define FILETYPE_FORMS_LOC						"Forms and Classes (*.scx;*.vcx;*.prg)"
#define FILETYPE_REPORTS_LOC					"Reports and Labels (*.frx;*.lbx)"
#define FILETYPE_MENUS_LOC						"Menus (*.mnx)"	
#define FILETYPE_PROGRAMS_LOC					"Programs (*.prg;*.h;*.qpr;*.mpr)"				
#define FILETYPE_DATA_LOC						"Data Structures (*.dbc;*.dbf;*.cdx)"
#define FILETYPE_PROJECTS_LOC					"Projects (*.pjx)"
#define FILETYPE_TEXT_LOC						"Text (*.txt;*.xml;*.xsl;*.htm;*.html;*.log;*.asp;*.aspx)"
#define FILETYPE_IMAGES_LOC						"Images (*.ani;*.bmp;*.cur;*.dib;*.gif;*.ico;*.jpg)"


* used by the CBaseClassCombo class
#define UNKNOWN_LOC								"<unknown>"

* message to display before changing the Member Class properties of an object
#define MEMBERCLASS_WARNING_LOC					"Dropping this class will result in destroying the existing member classes" + CHR(10) + "and recreating new ones based on new values." + CHR(10) + CHR(10) + "This will result in loss of property settings, new, added, and/or modified" + CHR(10) + "method code, and added objects." + CHR(10) + CHR(10) + "Do you want to continue?"
#define HEADERCLASS_WARNING_LOC					"Dropping this class will result in destroying the existing header class" + CHR(10) + "and recreating a new one based on new values." + CHR(10) + CHR(10) + "This will result in loss of property settings, new, added, and/or modified" + CHR(10) + "method code, and added objects." + CHR(10) + CHR(10) + "Do you want to continue?"

#define DROPOBJECT_CREATECOLUMN_LOC				"Do you want to add a column to the grid to contain this control?"
#define DROPOBJECT_REMOVETEXT1_LOC				"Do you want to replace the default Text1 control with the control you are adding to this column?"


#define EDITDROPTEXT_CAPTION_LOC				"Drag and Drop Text Template"
#define EDITCTRLDROPTEXT_CAPTION_LOC			"Ctrl+Drag and Drop Text Template"

* used in CFoxBuilderCombo class
#define BUILDER_DEFAULT_LOC						"Use Builder Lock setting"
#define BUILDER_ALWAYSRUN_LOC					"Always invoke Builder"
#define BUILDER_NEVERRUN_LOC					"Never invoke Builder"

#define PROPERTY_REMOVE_LOC						"Are you sure you want to remove this property setting?"
#define PROPERTY_REMOVECAPTION_LOC				"Remove"

#define CLASS_SETDEFAULT_LOC					"Are you sure you want to clear out the selected class?"
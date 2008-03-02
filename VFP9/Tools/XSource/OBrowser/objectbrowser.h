** New warning messages
#DEFINE UNIDENTIFIED_LIBRARY_LOC "Unidentified Library"
#DEFINE HISTORY_EMPTY_LOC "History empty..."

** Node Text
#DEFINE LOAD_TEXT_LOC "Loading, please wait..."

** Status text
#DEFINE TXT_READY_LOC "Ready."
#DEFINE TXT_LOAD_TYPELIB_LOC "Loading Type Library..."
#DEFINE TXT_CLOSE_TYPELIB_LOC "Closing Type Library..."
#DEFINE TXT_LOAD_COCLASSES_LOC "Exploring Component Classes..."
#DEFINE TXT_LOAD_CONSTANTS_LOC "Exploring Constants..."
#DEFINE TXT_LOAD_ENUMS_LOC "Exploring Enums..."
#DEFINE TXT_LOAD_INTERFACES_LOC "Exploring Interfaces..."
#DEFINE TXT_LOAD_EVENTS_LOC "Exploring Events..."
#DEFINE TXT_LOAD_METHODS_LOC "Exploring Methods..."
#DEFINE TXT_LOAD_PROPERTIES_LOC "Exploring Properties..."
#DEFINE TXT_LOAD_DETAILS_LOC "Loading Details..."

** Tool Tips
#DEFINE TTT_OPEN_LOC "Open Type Library"
#DEFINE TTT_GO_BACK_LOC "Back"
#DEFINE TTT_GO_BACK2_LOC "Back to "
#DEFINE TTT_GO_FORWARD_LOC "Forward"
#DEFINE TTT_GO_FORWARD2_LOC "Forward to "
#DEFINE TTT_REFRESH_LOC "Refresh"
#DEFINE TTT_FIND_LOC "Find"
#DEFINE TTT_COPY_LOC "Copy"
#DEFINE TTT_HELP_LOC "Object Browser Help"
#DEFINE TTT_OPTIONS_LOC "Object Browser Options"
#DEFINE TTT_TOGGLE_INTERFACES_LOC "Toggle VTable Interface Display"
#DEFINE TTT_TOGGLE_HIDDEN_LOC "Toggle Hidden Item Display"
#DEFINE TTT_TOGGLE_EVENTS_LOC "Highlight all Potential Sources of Events"
#DEFINE TTT_TOGGLE_DEFAULTS_LOC "Highlight Default Items"
#DEFINE TTT_TOGGLE_EXPANDDETAILS_LOC "Toggle Auto Expand Detail"
#DEFINE TTT_TOGGLE_DRILLDOWNDETAILS_LOC "Toggle Drill Down Detail"
#DEFINE TTT_TOGGLE_INHERITEDINTERFACE_LOC "Toggle Inherited Interfaces"

** Detail pane descriptions
#DEFINE DESC_CLASS_LOC "Class"
#DEFINE DESC_MEMBER_OF_LOC "Member of "
#DEFINE DESC_CONSTANT_LOC "Constant"
#DEFINE DESC_HEX_LOC "Hex:"
#DEFINE DESC_ENUM_LOC "Enum"
#DEFINE DESC_PROPERTY_LOC "Property"

** Other text
#DEFINE SCAN_REG_LOC "Scanning Registry for Components..."
#DEFINE DISP_COMP_LOC "Updating Component List..."
#DEFINE ERR_COMP_POOL_ACCESS_LOC "Unable to access component pool."
#DEFINE CLEAR_BROWSER_HISTORY_LOC "Are you sure you want to clear the browser history?"
#DEFINE CLEAR_HISTORY_LOC "Clear History"
#DEFINE MEMBERS_OF_LOC "Members of "
#DEFINE ITEMS_CONTAINING_LOC "Items containing '"
#DEFINE INSTANTIATING_ADDINS_LOC "Unable to instantiate AddIn " 
#DEFINE OPEN_FIRST_LOC "You need to open a library first."
#DEFINE REMOVE_ADDIN_LOC "Are you sure you want to remove AddIn "
#DEFINE CONSISTENCY_ERROR_LOC "Internal consistency error!"
#DEFINE OPERATION_ABORTED_LOC "Operation aborted!"

** Menu captions
#DEFINE MNU_REMOVE_SEARCH_LOC "Remove Search"
#DEFINE MNU_CLOSE_TYPELIB_LOC "Close TypeLib"
#DEFINE MNU_CLEAR_CACHE_LOC "Clear Cache"
#DEFINE MNU_CLOSE_LOC "Open"
#DEFINE MNU_FIND_LOC "Find"
#DEFINE MNU_NEW_WINDOW_LOC "New Window"
#DEFINE MNU_GO_BACK_LOC "Go Back"
#DEFINE MNU_GO_FORWARD_LOC "Go Forward"
#DEFINE MNU_REFRESH_LOC "Refresh"
#DEFINE MNU_FONT_LOC "Font"
#DEFINE MNU_ADDINS_LOC "Add-Ins..."
#DEFINE MNU_OPTIONS_LOC "Options"
#DEFINE MNU_MANUAL_INSTALL_LOC "Manual Install"


** Options
#DEFINE OPT_VTABLE_LOC "Display VTable Interfaces"
#DEFINE OPT_HIDDEN_LOC "Display Hidden Items"
#DEFINE OPT_EVENTS_LOC "Highlight Potential Sources of Events"
#DEFINE OPT_DEFAULTS_LOC "Highlight Default Items"
#DEFINE OPT_EXPANDDETAILS_LOC "Auto Expand Detail"
#DEFINE OPT_DRILLDOWNDETAILS_LOC "Auto Drill Down Detail"
#DEFINE OPT_INHERITEDINTERFACE_LOC "Show Interface Inheritance Structure"
#DEFINE OPT_IMPLEMENTINGINTERFACES_LOC "List all interfaces defining a method, event or property in detail."
#DEFINE OPT_UNDERSCORE_LOC "Display Properties that start with an underscore (_)"
#DEFINE OPT_SYSTEM_LOC "Display members that are defined on IUnknown or IDispatch"
#DEFINE OPT_SHOWINTERFACESINDETAILS_LOC "List interfaces in class detail"
#DEFINE OPT_METHODPARAMETERS_LOC "List method parameters in detail"

** Option descriptions
#DEFINE OPT_EVENTS_DESC_LOC "Specifies whether a potential source of events (interface or method) shall be highlighted as such."
#DEFINE OPT_DEFAULTS_DESC_LOC "Specifies whether or not default items shall be highlighted using a bold font style."
#DEFINE OPT_HIDDEN_DESC_LOC "Specifies whether hidden items shall be displayed (such as hidden interface and hidden methods and properties)."
#DEFINE OPT_EXPANDDETAILS_DESC_LOC "Specifies whether top level items in the detail pane shall be automatically expanded."
#DEFINE OPT_DRILLDOWNDETAILS_DESC_LOC "Specifies whether complex hierarchies in the detail pane (such as methods and properties for each interface) shall be expanded automatically."
#DEFINE OPT_VTABLE_DESC_LOC "Specifies whether VTable based interfaces and all their members shall be displayed or not (usually, VTable interfaces are not very important in Visual FoxPro)." 
#DEFINE OPT_INHERITEDINTERFACE_DESC_LOC "Specifies whether inherited interfaces shall be displayed in the detail pane."
#DEFINE OPT_IMPLEMENTINGINTERFACES_DESC_LOC "Specifies whether all interfaces defining a method or property shall be listed in the description pane."
#DEFINE OPT_UNDERSCORE_DESC_LOC "Properties that start with an underscore are usually placeholders for enums. For this reason, they are not displayed by default."
#DEFINE OPT_SYSTEM_DESC_LOC "All COM objects have methods that are defined in the IDispatch and IUnknown interfaces. These methods need to be there in order to work in a COM environment, however, they are usually not useful directly to the VFP developer."
#DEFINE OPT_SHOWINTERFACESINDETAILS_DESC_LOC "All creatable classes are based on one or more interfaces. Often, interfaces listed in the detail simply show the same information as the entire class, but sometimes they provide more insight."
#DEFINE OPT_METHODPARAMETERS_DESC_LOC "Method parameters can be listed directly in the detail display. However, note that the parameters are listed in more detail in the description pane."

**********************************************
** Internal (non-localized) settings...
**********************************************

#DEFINE HKEY_CLASSES_ROOT		-2147483648  && BITSET(0,31)
#DEFINE HKEY_CURRENT_USER		-2147483647  && BITSET(0,31)+1
#DEFINE VFP_OPTIONS_KEY1		"Software\Microsoft\VisualFoxPro\"
#DEFINE VFP_OPTIONS_KEY2		"\Options\OLEList"
#DEFINE CLSID_KEY					"CLSID"
#DEFINE PROGID_KEY				"\ProgID"
#DEFINE CONTROL_KEY				"Control"
#DEFINE SERVER_KEY				"Programmable"
#DEFINE SHELL_KEY					"\Shell\"
#DEFINE INPROC_KEY				"InProcServer32"
#DEFINE LOCALSVR_KEY				"LocalServer32"

* DLL files used to read registry
#DEFINE	DLL_ADVAPI_NT		"ADVAPI32.DLL"
#DEFINE	DLL_ADVAPI_WIN95	"ADVAPI32.DLL"

* DLL files used to read ODBC info
#DEFINE DLL_ODBC_NT			"ODBC32.DLL"
#DEFINE DLL_ODBC_WIN95		"ODBC32.DLL"

* Registry roots
#DEFINE HKEY_CURRENT_USER           -2147483647  && BITSET(0,31)+1
#DEFINE HKEY_LOCAL_MACHINE          -2147483646  && BITSET(0,31)+2
#DEFINE HKEY_USERS                  -2147483645  && BITSET(0,31)+3
#DEFINE CLSID_KEY				"CLSID"
#DEFINE TYPELIB_KEY				"TYPELIB"
#DEFINE HKEY_CLASSES_ROOT		-2147483648  && BITSET(0,31)

* Misc
#DEFINE APP_PATH_KEY		"\Shell\Open\Command"
#DEFINE OLE_PATH_KEY		"\Protocol\StdFileEditing\Server"
#DEFINE VFP_OPTIONS_KEY1	"Software\Microsoft\VisualFoxPro\"
#DEFINE VFP_OPTIONS_KEY2	"\Options"
#DEFINE CURVER_KEY			"\CurVer"

* Error Codes
#DEFINE ERROR_SUCCESS		0	&& OK
#DEFINE ERROR_EOF 			259 && no more entries in key

* Data types for keys
#DEFINE REG_SZ 				1	&& Data string
#DEFINE REG_EXPAND_SZ 		2	&& Unicode string
#DEFINE REG_BINARY 			3	&& Binary data in any form.
#DEFINE REG_DWORD 			4	&& A 32-bit number.

* Data types labels
#DEFINE REG_BINARY_LOC		"*Binary*"			&& Binary data in any form.
#DEFINE REG_DWORD_LOC 		"*Dword*"			&& A 32-bit number.
#DEFINE REG_UNKNOWN_LOC		"*Unknown type*"	&& unknown type

#DEFINE APPHOOK_FILE	"APPHOOK.VCX"
#DEFINE APPHOOK_CLASS	"APPHOOK"

* Operating System codes
#DEFINE	OS_W32S				1
#DEFINE	OS_NT				2
#DEFINE	OS_WIN95			3
#DEFINE	OS_MAC				4
#DEFINE	OS_DOS				5
#DEFINE	OS_UNIX				6

* DLL Paths for various operating systems
#DEFINE DLLPATH_NT			"\SYSTEM32\"
#DEFINE DLLPATH_WIN95		"\SYSTEM\"

* DLL files used to read INI files
#DEFINE	DLL_KERNEL_NT		"KERNEL32.DLL"
#DEFINE	DLL_KERNEL_WIN95	"KERNEL32.DLL"

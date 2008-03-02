#define NEWLINE				CHR(13) + CHR(10)

* update this if we change how the Panes are published
#define PUBLISH_VERSION		1.0

#define FOXPANE_HELPID			1231117
#define OPTIONS_HELPID			1231125
#define CUSTOMIZE_HELPID		1231126

* MSXML DOM parser
#define MSXML_PARSER		"MSXML2.DOMDocument.4.0"

* these can be used in the Data section of a content section
* 	<!-- CONTENT --> = inserts all subcontent at specified position
*   <!-- WRAPPANE --> = wrap the sub-content in XML tags
#define VFP_CONTENT			"<!-- CONTENT -->"
#define VFP_XMLCONTENT		"<!-- XMLCONTENT -->"

#define PANETYPE_XML		'X'
#define PANETYPE_HTML		'H'
#define PANETYPE_FOX		'F'
#define PANETYPE_WEBPAGE	'W'
#define PANETYPE_UNDEFINED	' '

#define RENDERTYPE_XML		'X'
#define RENDERTYPE_HTML		'H'
#define RENDERTYPE_FOX		'F'
#define RENDERTYPE_WEBPAGE	'W'
#define RENDERTYPE_NONE		' '

* Source of XML, XSL, CSS
#define SRC_MEMO			'M'
#define SRC_FILE			'F'
#define SRC_URL				'U'
#define SRC_SCRIPT			'S'
#define SRC_WEBSERVICE		'W'
#define SRC_XML				'X'
#define SRC_NONE			' '


#define XFORM_TYPE_XSL		'X'
#define XFORM_TYPE_SCRIPT	'S'
#define XFORM_TYPE_NONE		' '

#define INFOTYPE_CONTENT	'C'
#define INFOTYPE_FILE		'F'

#define REFRESHFREQ_PANELOAD	0
#define REFRESHFREQ_DEFAULT		-1
#define REFRESHFREQ_TASKLOAD	-2
#define REFRESHFREQ_NEVER		-99

* used by the ShellTo method
#define SW_HIDE             0
#define SW_SHOWNORMAL       1
#define SW_NORMAL           1
#define SW_SHOWMINIMIZED    2
#define SW_SHOWMAXIMIZED    3
#define SW_MAXIMIZE         3
#define SW_SHOWNOACTIVATE   4
#define SW_SHOW             5
#define SW_MINIMIZE         6
#define SW_SHOWMINNOACTIVE  7
#define SW_SHOWNA           8
#define SW_RESTORE          9
#define SW_SHOWDEFAULT      10
#define SW_FORCEMINIMIZE    11
#define SW_MAX              11
#define SE_ERR_NOASSOC 		31

#DEFINE INTERNET_OPEN_TYPE_PRECONFIG	0
#DEFINE INTERNET_OPEN_TYPE_DIRECT 		1
#DEFINE INTERNET_OPEN_TYPE_PROXY		3
#DEFINE INTERNET_SYNCHRONOUS			0
#DEFINE INTERNET_FLAG_RELOAD			2147483648
* #define INTERNET_FLAG_KEEP_CONNECTION	

#define tvwFirst	0
#define tvwLast		1
#define tvwNext		2
#define tvwPrevious	3
#define tvwChild	4


* when found in the XML/XSL, will load external file
* rather than using the text here
#define LOADFILE_MACRO			"FILE="


* used to encode fields when publishing
#define PUBLISH_ENCODE_START		"!!ENC!!"
#define PUBLISH_ENCODE_END			"??ENC??"


#define APPNAME_LOC						"Task Pane Manager"
#define RENDER_NOCONTENT_LOC			"-no content defined-"

#define MENU_OPTIONS_LOC				"\<Options..."
#define MENU_PUBLISH_LOC				"\<Publish"
#define MENU_RELOAD_LOC					"\<Reload"

#define	OPTIONS_LASTOPENPANE_LOC		"<last open pane>"


#define PROXY_NONE			1
#define PROXY_IE			2
#define PROXY_CUSTOM		3


#define OPTIONS_TASKPANE_LOC			"Task Pane Manager"
#define OPTIONS_GENERAL_LOC				"General"
#define OPTIONS_CUSTOMIZE_LOC			"Customize"
#define OPTIONS_PROXY_LOC				"Proxy Server"


* don't localize the #description# macro
#define CONNECTING_LOC					"Connecting to #description#..."

#define PANEDIRECTORY_NOEXIST_LOC	"The specified folder for the Task Pane Manager tables does not exist." + CHR(10) + CHR(10) + "Do you want to create it?"
#define CACHEDIRECTORY_NOEXIST_LOC	"The specified folder for the cached files does not exist." + CHR(10) + CHR(10) + "Do you want to create it?"

#define ASK_RESTORETODEFAULT_LOC	"Are you sure you want to restore your Task Pane Manager tables to their defaults?" + CHR(10) + "(all of your current customization will be lost)"
#define RESTORETODEFAULT_LOC		"The Task Pane Manager has been restored to the original."

#define ASK_CLEANUP_LOC				"Are you sure you want to cleanup your Task Pane Manager tables?"

#define ERROR_RESTORETODEFAULT_LOC	"Unable to restore to the original Task Pane Manager tables due to the following error:"
#define ERROR_OPENTASKPANE_LOC		"Unable to open or create the Task Pane table (taskpane)."
#define ERROR_OPENCONTENT_LOC		"Unable to open or create the Pane Content table (panecontent)."
#define ERROR_OPENTABLE_LOC			"Unable to load the Task Pane Manager due to the following error:"
#define ERROR_RESTORE_LOC			"Do you want to restore to the default location?"
#define ERROR_BADDIR_LOC			"Directory name is not valid."
#define ERROR_CREATETABLES_LOC		"Error encountered creating tables:"

#define ERROR_CLEANUP_LOC			"Unable to cleanup Task Manager tables due to the following error:"
#define ERROR_NOBACKUP_LOC			"Unable to create a backup of the current Task Pane Manager tables." + CHR(10) + CHR(10) + "Do you still want to proceed?"


#define ERROR_INITERROR_LOC			"Error initializing the Task Pane Manager."
#define ERROR_SCRIPT_LOC			"Error executing script to generate content."
#define ERROR_WSCONNECT_LOC			"Unable to connect to Web Service: "
#define ERROR_WSMETHOD_LOC			"Error executing method on Web Service: "

#define LINK_CONFIGURE_LOC			"Configure"

#define WORKING_OFFLINE_LOC			"[Working Offline]"

* use by FoxPaneLocate form
#define LOCATE_FOLDERNOEXIST_LOC	"The specified folder does not exist."
#define LOCATE_NOCREATE_LOC			"Unable to create Task Pane Manager tables in specified folder."
#define LOCATE_FOLDEREXISTS_LOC		"The TaskPane folder already exists beneath the specified folder."

* set startup messages
#define STARTUP_MSG1_LOC			"Startup application is currently set to:"
#define STARTUP_MSG2_LOC			"Do you want to set it to the Task Pane Manager?"

#define SETUP_DELETEPANE_LOC		"Are you sure you want to delete the following pane?"
#define SETUP_DELETECONTENT_LOC		"Are you sure you want to delete the following content?"
#define SETUP_COMMONFILES_LOC		"<common files>"
#define SETUP_REMOVEFILE_LOC		"Are you sure you want to remove this file?"
#define SETUP_FILENAME_LOC			"File name (do not include a folder):"
#define SETUP_CREATEFILE_LOC		"Create File"
#define SETUP_PANEERROR_LOC			"All of the requested information is required."
#define SETUP_NEWPROPERTY_LOC		"Property name:"
#define SETUP_NEWOPTION_LOC			"Option name:"
#define SETUP_DELETEPROPERTY_LOC	"Are you sure you want to delete the following option property?"
#define SETUP_DELETEOPTION_LOC		"Are you sure you want to delete the following option?"
#define SETUP_OPTIONREQUIRED_LOC	"The name of the option is required."
#define SETUP_DIRNOEXIST_LOC		"The pane directory cache folder does not exist and could not be created."
#define SETUP_COPYERROR_LOC			"Unable to copy file to the cache folder due to the following error:"

#define SETUP_DUPLICATEID_LOC		"The Unique ID you specified is already in use." + CHR(10) + CHR(10) + "The value you will reset to the original."
#define SETUP_NOTUNIQUE_LOC			"The Unique ID you specified is already in use."
#define SETUP_SPECIFYFILE_LOC		"You must first specify the file."

#define INSTALL_BADFILE_LOC			"The pane installation file is invalid."
#define INSTALL_BADVERSION_LOC		"The pane installation file is not the correct version."
#define INSTALL_UNABLETOOPEN_LOC	"Unable to open the Task Pane Manager files."


#define PANETYPE_WEBPAGE_LOC		"Web Page"
#define PANETYPE_XML_LOC			"XML"
#define PANETYPE_HTML_LOC			"HTML"
#define PANETYPE_FOX_LOC			"VFP Controls"



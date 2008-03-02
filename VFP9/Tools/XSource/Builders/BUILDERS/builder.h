* Include file for buildertemplate

#DEFINE C_DEBUG					.f.

#DEFINE C_TIMERLIMIT			9
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

#DEFINE ERRORTITLE_LOC		"Microsoft Visual FoxPro Builders"

#DEFINE ERRORMESSAGE_LOC ;
	"Error #" + alltrim(str(m.nError)) + " in " + ;
	PROPER(m.cMethod) + " (" + alltrim(str(m.nLine)) + "): " + m.Bldrmsg

#DEFINE C_UNSUPPORTED_LOC	"Your control is set to a property that the builder does not support: "
#DEFINE C_NOGRIDBLDRS_LOC	"Your control is in a grid column, and this is not supported by the registered builder."
#DEFINE C_NOSELOBJ_LOC		"The container object is being edited and no control is currently selected."
#DEFINE C_WRONGCLASS_LOC	"This builder cannot find a selected control with an appropriate base class."
#DEFINE C_NOFORM_LOC		"No form found for selected control."
#DEFINE C_FILEWORD_LOC		"File '"
#DEFINE C_NOFINDWORD_LOC	"' not found."
#DEFINE C_SELBLDR_LOC		"Select Builder program:"
#DEFINE C_OPEN_LOC			"Open"
#DEFINE C_MSGNAME_LOC		"Name:  "
#DEFINE C_MSGTYPE_LOC		"Type:  "
#DEFINE C_MSGCLASS_LOC		"Class:  "
#DEFINE C_MSGPARENT_LOC		"Parent Class:  "
#DEFINE C_MSGBASE_LOC		"Base Class:  "
#DEFINE C_BADPROP_LOC		"One or more properties affected by this builder are unavailable, and may be protected. " + ;
							"Do you want to continue?"
							
#DEFINE MB_YESNO	    	4

#define C_VERS5_LOC     	"The Builders require Visual FoxPro 5.0 or higher."
#define C_BUILD5			290			&&minimum 5.0 build to check for
#define C_VERSION			"5.0"		&&Version use use by PSS -- hold mouse down for 1 second on Help button

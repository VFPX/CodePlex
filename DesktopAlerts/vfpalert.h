** VFP Desktop Alert Parameters
** Types of Alert (Major Form Properties)
#DEFINE DA_TYPEPLAIN	0	&& No Links, No Tasks
#DEFINE DA_TYPELINK		1	&& One Link, No Tasks
#DEFINE DA_TYPETASK		2	&& One Task
#DEFINE DA_TYPEMULTI	4	&& Two Tasks

** A Type of 3 or 5 will add a "link" to the "task" alert.
** Otherwise, the task alert will not include a link.

** Alert Icons
#DEFINE DA_ICONDEFAULT	      8	&& Default Alert Icon 
#DEFINE DA_ICONSTOP          16	&& Critical message
#DEFINE DA_ICONQUESTION	     32 && Question Mark
#DEFINE DA_ICONEXCLAMATION   48 && Warning message
#DEFINE DA_ICONINFORMATION   64 && Information message
#DEFINE DA_ICONCUSTOM	    128	&& User-defined custom graphic

** Left some room in here to "build-in" some other
** 'default' icons.

#DEFINE DA_TASKICONDEFAULT 2048 && Default Task Icon
	
** Alert Options
#DEFINE DA_NOSETTINGS	   4096	&& Do not show the settings button
#DEFINE DA_NOPIN		   8192	&& Do not show the push-pin button
#DEFINE DA_NOCLOSE		  16384 && Do not show the close button

** Alert Return Values
#DEFINE DA_NOACTION		-1	&& Alert closed with no user interaction (timeout)
#DEFINE DA_CLOSED		 1	&& User closed the alert
#DEFINE DA_LINK			 2	&& User clicked the link
#DEFINE DA_TASKONE		 3	&& User chose Task 1
#DEFINE DA_TASKTWO		 4	&& User chose Task 2

** Files
#DEFINE DA_DEFAULTICONFILE	"default_icon.bmp"
#DEFINE DA_DEFAULTTASKFILE	"default_task.png"
#DEFINE DA_DEFAULTSOUND		"alert.wav"
#DEFINE DA_CONFIGFILE		"daconfig.xml"

** Settings
#DEFINE DA_FADETIMER		 20	&& tmrFade Interval (Milliseconds)
#DEFINE DA_WAIT 		  	 10	&& Show the alert for ten seconds by default
#DEFINE DA_FADEPERCENT	 	 10	&& By default, make it 10% Transparent
#DEFINE DA_TRANSPARENCY 	255 * (DA_FADEPERCENT/100)

** Strings
#DEFINE DA_DEFAULTTITLE	"Desktop Alert Message"

** Default 'CAPTIONS' for the settings screen
** Special thanks to Emerson Stanton Reed for
** his suggestion!
#DEFINE DA_SETTINGS				"Desktop Alerts Settings"
#DEFINE	DA_LBLHOWLONG			"How long should the Desktop Alert appear on-screen?"
#DEFINE DA_LBLSECONDS			"seconds"
#DEFINE	DA_LBLHOWTRANSPARENT	"How transparent should the Desktop Alert be?"
#DEFINE DA_LBLPERCENT			"percent"
#DEFINE DA_CHKSOUND				"Play a sound when the Alert appears"
#DEFINE DA_CMDOK				"\<OK"
#DEFINE DA_CMDCANCEL			"Cancel"
	
** The following are used by the API functions in the form's MouseMove.
#DEFINE WM_NULL        0 
#DEFINE WM_SYSCOMMAND  0x112 
#DEFINE WM_LBUTTONUP   0x202 
#DEFINE MOUSE_MOVE     0xf012 

** COM_Attrib flag settings for Type Library attributes support
#DEFINE COMATTRIB_RESTRICTED	0x1			&& The property/method should not be accessible from macro languages.
#DEFINE COMATTRIB_HIDDEN		0x40		&& The property/method should not be displayed to the user, although it exists and is bindable.
#DEFINE COMATTRIB_NONBROWSABLE	0x400		&& The property/method appears in an object browser, but not in a properties browser.
#DEFINE COMATTRIB_READONLY		0x100000	&& The property is read-only (applies only to Properties).
#DEFINE COMATTRIB_WRITEONLY		0x200000	&& The property is write-only (applies only to Properties).
 
#DEFINE CRLF	CHR(13) + CHR(10)
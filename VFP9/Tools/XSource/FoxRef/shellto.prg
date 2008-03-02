* Abstract:
*   This program will call shell out to specified file,
*	which can be a URL (e.g. http://www.microsoft.com),
*	a filename, etc
*
* Parameters:
*	<cFile>
*	[cParameters]

*-- These constants will be used with the
*-- ShellExecute function.
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
#define SE_ERR_NOASSOC 31

LPARAMETERS cFile, cParameters
LOCAL cRun
LOCAL cSysDir
LOCAL nRetValue


*-- GetDesktopWindow gives us a window handle to
*-- pass to ShellExecute.
DECLARE INTEGER GetDesktopWindow IN user32.dll
DECLARE INTEGER GetSystemDirectory IN kernel32.dll ;
	STRING @cBuffer, ;
	INTEGER liSize

DECLARE INTEGER ShellExecute IN shell32.dll ;
	INTEGER, ;
	STRING @cOperation, ;
	STRING @cFile, ;
	STRING @cParameters, ;
	STRING @cDirectory, ;
	INTEGER nShowCmd

IF VARTYPE(m.cParameters) <> 'C'
	m.cParameters = ''
ENDIF

m.cOperation = "open"
m.nRetValue = ShellExecute(GetDesktopWindow(), @m.cOperation, @m.cFile, @m.cParameters, '', SW_SHOWNORMAL)
IF m.nRetValue = SE_ERR_NOASSOC && No association exists
	m.cSysDir = SPACE(260)  && MAX_PATH, the maximum path length

	*-- Get the system directory so that we know where Rundll32.exe resides.
	m.nRetValue = GetSystemDirectory(@m.cSysDir, LEN(m.cSysDir))
	m.cSysDir = SUBSTR(m.cSysDir, 1, m.nRetValue)
	m.cRun = "RUNDLL32.EXE"
	cParameters = "shell32.dll,OpenAs_RunDLL "
	m.nRetValue = ShellExecute(GetDesktopWindow(), "open", m.cRun, m.cParameters + m.cFile, m.cSysDir, SW_SHOWNORMAL)
ENDIF


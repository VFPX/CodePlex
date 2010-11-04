#INCLUDE vfp2c.h

SET LIBRARY TO vfp2c32.fll ADDITIVE
INITVFP2C32(VFP2C_INIT_ALL)

SET PROCEDURE TO structs.prg ADDITIVE

#DEFINE STARTF_USESHOWWINDOW	0x01
#DEFINE SW_HIDE					0
#DEFINE SW_SHOWNOACTIVATE		4
#DEFINE SW_SHOWMINNOACTIVE		7
#DEFINE SW_SHOWNA				8
#DEFINE LSFW_LOCK				1
#DEFINE LSFW_UNLOCK				2

DECLARE INTEGER CreateProcess IN kernel32.dll STRING cApplication, STRING cCommandLine, ;
INTEGER pProcessAtrributes, INTEGER pThreadAttributes, INTEGER bInheritHandles, ;
INTEGER dwCreationFlags, INTEGER lpEnvironment, STRING cCurrentDirectory, ;
INTEGER pStartupInfo, INTEGER pProcessInformation

DECLARE INTEGER CloseHandle IN kernel32.dll INTEGER
DECLARE INTEGER GetModuleFileName IN kernel32.dll INTEGER, STRING @, INTEGER

LOCAL loStartup, loProcessInfo, lcApplication, lnRet, lnHwnd

loStartup = CREATEOBJECT('STARTUPINFO')
loProcessInfo = CREATEOBJECT('PROCESS_INFORMATION')

loStartup.dwFlags = STARTF_USESHOWWINDOW
loStartup.wShowWindow = SW_HIDE

lcApplication = "C:\WinNt\explorer.exe"

lnRet = CreateProcess(lcApplication,0,0,0,0,0,0,0,loStartup.Address,loProcessInfo.Address)

CloseHandle(loProcessInfo.hProcess)
CloseHandle(loProcessInfo.hThread)


FUNCTION GetExeFileName()

#DEFINE MAX_PATH 260
DECLARE INTEGER GetModuleFileName IN kernel32.dll INTEGER hModule, ;
STRING @lpFilename, INTEGER nSize

LOCAL lcPath, lnRet, lnSize
m.lnSize = MAX_PATH
m.lcPath = REPLICATE(CHR(0),m.lnSize)
m.lnRet = GetModuleFileName(0,@m.lcPath,m.lnSize)
IF lnRet > 0
 RETURN LEFT(m.lcPath,m.lnRet)
ELSE
 RETURN '' && handle error
ENDIF

ENDFUNC

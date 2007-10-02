
LPARAMETERS m.cProcessID, m.cSeconds

DECLARE INTEGER OpenProcess IN Win32API ;
  INTEGER dwDesiredAccess, INTEGER bInheritHandle, INTEGER dwProcessID

DECLARE INTEGER TerminateProcess IN Win32API ;
  INTEGER hProcess, INTEGER uExitCode

DECLARE Sleep IN Win32API ;
  INTEGER nMilliseconds

LOCAL m.nSeconds AS DOUBLE, ;
  nHandle AS INTEGER, ;
  nProcessID as Integer

m.nSeconds = EVL(VAL(m.cSeconds), 30)

nProcessID = VAL(m.cProcessID)

Sleep(m.nSeconds * 1000)

nHandle = OpenProcess(1, 1, m.nProcessID)

RETURN TerminateProcess(m.nHandle, 0) > 0

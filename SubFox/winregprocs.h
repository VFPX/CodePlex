* WinRegProcs.h *

*** Registry Value types
#DEFINE REG_NONE					0    && Undefined Type (default)
#DEFINE REG_SZ						1	 && Regular Null Terminated String
#DEFINE REG_BINARY					3    && ??? (unimplemented)
#DEFINE REG_DWORD					4    && Long Integer value
#DEFINE MULTI_SZ					7	 && Multiple Null Term Strings (not implemented)

*** Registry roots
#DEFINE HKEY_CLASSES_ROOT           -2147483648  && (( HKEY ) 0x80000000 )
#DEFINE HKEY_CURRENT_USER           -2147483647  && (( HKEY ) 0x80000001 )
#DEFINE HKEY_LOCAL_MACHINE          -2147483646  && (( HKEY ) 0x80000002 )
#DEFINE HKEY_USERS                  -2147483645  && (( HKEY ) 0x80000003 )
#DEFINE HKEY_DEFAULT				HKEY_LOCAL_MACHINE

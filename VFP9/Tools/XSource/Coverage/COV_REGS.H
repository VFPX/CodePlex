* COV_REGS.H
* constants for Coverage Standard UI app registry object
* constant list and procs excerpted from REGISTRY.PRG
* Copyright (c) 1995,1996 Sierra Systems, Microsoft Corporation
* Written by Randy Brown
* Contributions from Matt Oshry, Calvin Hsia
* Delivered as a PRG sample in VFP 5
*
* Randy's Registry class provides a complete library of API
* calls to access the Windows Registry. Support is provided
* for Windows 32S, Windows NT amd Windows 95. Included for
* backward compatibility with older applications which still
* use INI files are several routines which access INI sections
* and details. Finally, several valuable routines are included
* for accessing ODBC drivers and data sources.

* The Coverage registry object is a lighterweight
* version that subsets Randy's Registry functionality
* and adds some VFP6- and Coverage- specific items.

* Operating System codes
#DEFINE   OS_NT            2
#DEFINE   OS_WIN95         3

* DLL Paths for various operating systems
#DEFINE DLLPATH_NT         "\SYSTEM32\"
#DEFINE DLLPATH_WIN95      "\SYSTEM\"

* DLL files used to read registry
#DEFINE   DLL_ADVAPI_NT      "ADVAPI32.DLL"
#DEFINE   DLL_ADVAPI_WIN95   "ADVAPI32.DLL"

* Registry roots
#DEFINE HKEY_CLASSES_ROOT           -2147483648  && BITSET(0,31)
#DEFINE HKEY_CURRENT_USER           -2147483647  && BITSET(0,31)+1
#DEFINE HKEY_LOCAL_MACHINE          -2147483646  && BITSET(0,31)+2
#DEFINE HKEY_USERS                  -2147483645  && BITSET(0,31)+3

* Misc
#DEFINE APP_PATH_KEY                "\Shell\Open\Command"
#DEFINE OLE_PATH_KEY                "\Protocol\StdFileEditing\Server"
* #DEFINE VFP5_KEYPATH                "Software\Microsoft\VisualFoxPro\5.0"
* #DEFINE VFP6_KEYPATH                "Software\Microsoft\VisualFoxPro\6.0"

* the above #DEFINEs are replaced by a version-independent
* expression, at least for the current known keys:
#DEFINE VFP_KEYVERSION              TRANS(VAL(SUBSTR(SUBSTR(VERS(),AT(" ",VERS(),2)+1),;
                                         1,AT(".",SUBSTR(VERS(),AT(" ",VERS(),2)+1),1)-1)))+ ;
                                    ".0"
* if desired for future versions that don't fit the
* current pattern,
* the above expression can be explictly here
* overridden for these versions, for example:
* #IF "7.3" $ VERS()
*    #UNDEF VFP_KEYVERSION
*    #DEFINE VFP_KEYVERSION   "7.3"
* #ENDIF
   
#DEFINE VFP_KEYPATH                 "Software\Microsoft\VisualFoxPro\"+VFP_KEYVERSION
#DEFINE VFP_COVERAGE_KEY            "\Coverage"
#DEFINE VFP_OPTIONS_KEY             "\Options"
#DEFINE CURVER_KEY                  "\CurVer"

* Error Codes
#DEFINE ERROR_SUCCESS      0   && OK
#DEFINE ERROR_EOF          259 && no more entries in key

* Note these next error codes are specific to this Class, not DLL
#DEFINE ERROR_NOAPIFILE      -101   && DLL file to check registry not found
#DEFINE ERROR_KEYNOREG       -102   && key not registered
#DEFINE ERROR_BADPARM        -103   && bad parameter passed
#DEFINE ERROR_NOENTRY        -104   && entry not found
#DEFINE ERROR_BADKEY         -105   && bad key passed
#DEFINE ERROR_NONSTR_DATA    -106   && data type for value is not a data string
#DEFINE ERROR_BADPLAT        -107   && platform not supported
#DEFINE ERROR_NOINIFILE      -108   && DLL file to check INI not found
#DEFINE ERROR_NOINIENTRY     -109   && No entry in INI file
#DEFINE ERROR_FAILINI        -110   && failed to get INI entry
#DEFINE ERROR_NOPLAT         -111   && call not supported on this platform
#DEFINE ERROR_NOODBCFILE     -112   && DLL file to check ODBC not found
#DEFINE ERROR_ODBCFAIL       -113   && failed to get ODBC environment

* Data types for keys
#DEFINE REG_SZ             1   && Data string
#DEFINE REG_BINARY         3   && Binary data in any form.
#DEFINE REG_DWORD          4   && A 32-bit number.

* Data types labels
#DEFINE REG_BINARY_LOC      "*Binary*"         && Binary data in any form.
#DEFINE REG_DWORD_LOC       "*Dword*"         && A 32-bit number.
#DEFINE REG_UNKNOWN_LOC      "*Unknown type*"   && unknown type



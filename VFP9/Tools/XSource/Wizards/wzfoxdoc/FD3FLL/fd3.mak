# Microsoft Developer Studio Generated NMAKE File, Format Version 40001
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Dynamic-Link Library" 0x0102

!IF "$(CFG)" == ""
CFG=fd3 - Win32 Debug
!MESSAGE No configuration specified.  Defaulting to fd3 - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "fd3 - Win32 Release" && "$(CFG)" != "fd3 - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE on this makefile
!MESSAGE by defining the macro CFG on the command line.  For example:
!MESSAGE 
!MESSAGE NMAKE /f "fd3.mak" CFG="fd3 - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "fd3 - Win32 Release" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE "fd3 - Win32 Debug" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE 
!ERROR An invalid configuration is specified.
!ENDIF 

!IF "$(OS)" == "Windows_NT"
NULL=
!ELSE 
NULL=nul
!ENDIF 
################################################################################
# Begin Project
# PROP Target_Last_Scanned "fd3 - Win32 Debug"
CPP=cl.exe
RSC=rc.exe
MTL=mktyplib.exe

!IF  "$(CFG)" == "fd3 - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Target_Dir ""
OUTDIR=.\Release
INTDIR=.\Release

ALL : "$(OUTDIR)\fd3.fll"

CLEAN : 
	-@erase ".\fd3.fll"
	-@erase ".\Release\cstringz.obj"
	-@erase ".\Release\FD3.OBJ"
	-@erase ".\Release\str.obj"
	-@erase ".\Release\support.obj"
	-@erase ".\Release\fd3.res"
	-@erase ".\Release\fd3.lib"
	-@erase ".\Release\fd3.exp"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /MT /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /Gr /Zp1 /MD /W3 /GX /Zd /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
CPP_PROJ=/nologo /Gr /Zp1 /MD /W3 /GX /Zd /O2 /D "WIN32" /D "NDEBUG" /D\
 "_WINDOWS" /Fp"$(INTDIR)/fd3.pch" /YX /Fo"$(INTDIR)/" /c 
CPP_OBJS=.\Release/
CPP_SBRS=
# ADD BASE MTL /nologo /D "NDEBUG" /win32
# ADD MTL /nologo /D "NDEBUG" /win32
MTL_PROJ=/nologo /D "NDEBUG" /win32 
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
RSC_PROJ=/l 0x409 /fo"$(INTDIR)/fd3.res" /d "NDEBUG" 
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/fd3.bsc" 
BSC32_SBRS=
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /dll /machine:I386
# ADD LINK32 winapims.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /version:3.50 /subsystem:windows /dll /machine:I386 /out:"fd3.fll"
LINK32_FLAGS=winapims.lib kernel32.lib user32.lib gdi32.lib winspool.lib\
 comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib\
 odbc32.lib odbccp32.lib /nologo /version:3.50 /subsystem:windows /dll\
 /incremental:no /pdb:"$(OUTDIR)/fd3.pdb" /machine:I386 /out:"fd3.fll"\
 /implib:"$(OUTDIR)/fd3.lib" 
LINK32_OBJS= \
	"$(INTDIR)/cstringz.obj" \
	"$(INTDIR)/FD3.OBJ" \
	"$(INTDIR)/str.obj" \
	"$(INTDIR)/support.obj" \
	"$(INTDIR)/fd3.res"

"$(OUTDIR)\fd3.fll" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ELSEIF  "$(CFG)" == "fd3 - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir ""
# PROP Intermediate_Dir ""
# PROP Target_Dir ""
OUTDIR=.
INTDIR=.

ALL : "$(OUTDIR)\fd3.fll"

CLEAN : 
	-@erase ".\fd3.fll"
	-@erase ".\FD3.OBJ"
	-@erase ".\str.obj"
	-@erase ".\support.obj"
	-@erase ".\cstringz.obj"
	-@erase ".\fd3.res"
	-@erase ".\fd3.lib"
	-@erase ".\fd3.exp"
	-@erase ".\fd3.map"

# ADD BASE CPP /nologo /MTd /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /Gr /Zp1 /MDd /W3 /GX /Zd /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
CPP_PROJ=/nologo /Gr /Zp1 /MDd /W3 /GX /Zd /Od /D "WIN32" /D "_DEBUG" /D\
 "_WINDOWS" /Fp"$(INTDIR)/fd3.pch" /YX /c 
CPP_OBJS=
CPP_SBRS=
# ADD BASE MTL /nologo /D "_DEBUG" /win32
# ADD MTL /nologo /D "_DEBUG" /win32
MTL_PROJ=/nologo /D "_DEBUG" /win32 
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
RSC_PROJ=/l 0x409 /fo"$(INTDIR)/fd3.res" /d "_DEBUG" 
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/fd3.bsc" 
BSC32_SBRS=
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /dll /debug /machine:I386
# ADD LINK32 winapims.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /version:3.50 /subsystem:windows /dll /profile /map /debug /machine:I386 /nodefaultlib:"MSVCRT" /out:"fd3.fll"
# SUBTRACT LINK32 /verbose
LINK32_FLAGS=winapims.lib kernel32.lib user32.lib gdi32.lib winspool.lib\
 comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib\
 odbc32.lib odbccp32.lib /nologo /version:3.50 /subsystem:windows /dll /profile\
 /map:"$(INTDIR)/fd3.map" /debug /machine:I386 /nodefaultlib:"MSVCRT"\
 /out:"$(OUTDIR)/fd3.fll" /implib:"$(OUTDIR)/fd3.lib" 
LINK32_OBJS= \
	"$(INTDIR)/FD3.OBJ" \
	"$(INTDIR)/str.obj" \
	"$(INTDIR)/support.obj" \
	"$(INTDIR)/cstringz.obj" \
	"$(INTDIR)/fd3.res"

"$(OUTDIR)\fd3.fll" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ENDIF 

.c{$(CPP_OBJS)}.obj:
   $(CPP) $(CPP_PROJ) $<  

.cpp{$(CPP_OBJS)}.obj:
   $(CPP) $(CPP_PROJ) $<  

.cxx{$(CPP_OBJS)}.obj:
   $(CPP) $(CPP_PROJ) $<  

.c{$(CPP_SBRS)}.sbr:
   $(CPP) $(CPP_PROJ) $<  

.cpp{$(CPP_SBRS)}.sbr:
   $(CPP) $(CPP_PROJ) $<  

.cxx{$(CPP_SBRS)}.sbr:
   $(CPP) $(CPP_PROJ) $<  

################################################################################
# Begin Target

# Name "fd3 - Win32 Release"
# Name "fd3 - Win32 Debug"

!IF  "$(CFG)" == "fd3 - Win32 Release"

!ELSEIF  "$(CFG)" == "fd3 - Win32 Debug"

!ENDIF 

################################################################################
# Begin Source File

SOURCE=.\support.cpp
DEP_CPP_SUPPO=\
	".\fd3.h"\
	{$(INCLUDE)}"\pro_ext.h"\
	".\cstringz.hpp"\
	

"$(INTDIR)\support.obj" : $(SOURCE) $(DEP_CPP_SUPPO) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\str.cpp
DEP_CPP_STR_C=\
	".\fd3.h"\
	{$(INCLUDE)}"\pro_ext.h"\
	".\cstringz.hpp"\
	

"$(INTDIR)\str.obj" : $(SOURCE) $(DEP_CPP_STR_C) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\fd3.rc

"$(INTDIR)\fd3.res" : $(SOURCE) "$(INTDIR)"
   $(RSC) $(RSC_PROJ) \
!IFDEF LAB_BUILD
		-d"LAB_BUILD" \
!ENDIF
!IFDEF RTM_BUILD
		-d"RTM_BUILD" \
!ENDIF
   $(SOURCE)


# End Source File
################################################################################
# Begin Source File

SOURCE=.\FD3.CPP
DEP_CPP_FD3_C=\
	".\fd3.h"\
	{$(INCLUDE)}"\pro_ext.h"\
	".\cstringz.hpp"\
	

"$(INTDIR)\FD3.OBJ" : $(SOURCE) $(DEP_CPP_FD3_C) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\cstringz.cpp
DEP_CPP_CSTRI=\
	{$(INCLUDE)}"\pro_ext.h"\
	".\cstringz.hpp"\
	

"$(INTDIR)\cstringz.obj" : $(SOURCE) $(DEP_CPP_CSTRI) "$(INTDIR)"


# End Source File
# End Target
# End Project
################################################################################

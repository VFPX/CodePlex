all :	clean fd3.fll

fd3.fll	:
	@set INCLUDE=$(INCLUDE);$(MSVCDIR)\INCLUDE;$(MSVCDIR)\ATL\INCLUDE;$(MSVCDIR)\MFC\INCLUDE;$(PRODLOC)\include;$(PRODLOC)\import\x86\include;$(PATH_H);$(PATH_GENH);$(PRODLOC)\import\include\w32
	@set LIB=$(LIB);$(MSVCDIR)\LIB;$(MSVCDIR)\MFC\LIB;$(PRODLOC);$(PRODLOC)\import\lib\w32;$(MSVCDIR)\ATLMFC\lib
	$(MAKE) /nologo /f fd3.mak "CFG=fd3 - Win32 Release"

clean :
	$(MAKE) /nologo /f fd3.mak clean "CFG=fd3 - Win32 Release"

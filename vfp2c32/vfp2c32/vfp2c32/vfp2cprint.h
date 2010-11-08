#ifndef _VFP2CPRINT_H__
#define _VFP2CPRINT_H__

#ifdef __cplusplus
extern "C" {
#endif

#define APRINT_DEST_ARRAY 1
#define APRINT_DEST_OBJECTARRAY 2

#define PRINT_ENUM_BUFFER 2048
#define PRINT_TRAY_BUFFER 24

#define PAPERSIZE_UNIT_MM		1
#define PAPERSIZE_UNIT_INCH		2
#define PAPERSIZE_UNIT_POINT	3

#define POINTS_PER_MM 0.2834645669
#define INCH_PER_MM 0.039370079

typedef BOOL (_stdcall *PENUMFORMS)(HANDLE,DWORD,LPBYTE,DWORD,LPDWORD,LPDWORD); // EnumForms

bool _stdcall VFP2C_Init_Print();
void _fastcall APrintersEx(ParamBlk *parm);
void _fastcall APrintJobs(ParamBlk *parm);
void _fastcall APrinterForms(ParamBlk *parm);
void _fastcall APaperSizes(ParamBlk *parm);
void _fastcall APrinterTrays(ParamBlk *parm);

#ifdef __cplusplus
}
#endif // end of extern "C"

#endif // _VFP2CPRINT_H__
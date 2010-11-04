#ifndef _VFP2CWINDOWS_H__
#define _VFP2CWINDOWS_H__

typedef HMONITOR (_stdcall *PMONITORFROMWINDOW)(HWND, DWORD); // MonitorFromWindow
typedef HMONITOR (_stdcall *PMONITORFROMPOINT)(POINT, DWORD); // MonitorFromPoint
typedef BOOL (_stdcall *PGETMONITORINFO)(HMONITOR, LPMONITORINFO); // GetMonitorInfo

#ifdef __cplusplus
extern "C" {
#endif

bool _stdcall VFP2C_Init_Windows();
void _fastcall GetWindowTextEx(ParamBlk *parm);
void _fastcall GetWindowRectEx(ParamBlk *parm);
void _fastcall CenterWindowEx(ParamBlk *parm);
void _fastcall ADesktopArea(ParamBlk *parm);
void _fastcall ColorOfPoint(ParamBlk *parm);

#ifdef __cplusplus
}
#endif

#endif // _VFP2CWINDOWS_H__
*=======================================================
* Report Preview compile constants
*=======================================================

#include foxpro_reporting.h
#include frxpreview_loc.h

#define PREVIEW_VERSION		"2316"

*-------------------------------------------------------
* Debug compile switches:
*  - double-check these before each release build:
*-------------------------------------------------------

#define PREVIEW_WILL_HAVE_TOOLBAR	.T.

#define DEBUG_LARGE_FONT_SUPPORT    .F.
#define DEBUG_SUSPEND_ON_ERROR      .T.
#define DEBUG_MENU_INFO_OPTION      .F.
#define DEBUG_METHOD_LOGGING        .F.

*-------------------------------------------------------
* File names and locations:
*-------------------------------------------------------

#define FRXCOMMON_PRG_CLASSLIB  "frxcommon.prg"

*-------------------------------------------------------
* Resource Keys
*-------------------------------------------------------

#define REPORTPREVIEW_RESOURCE_ID		"9REPPREVIEW"   

*-------------------------------------------------------
* Magic Numbers
*-------------------------------------------------------

#define ZOOM_LEVEL_PROMPT	1
#define ZOOM_LEVEL_PERCENT  2
#define ZOOM_LEVEL_CANVAS   3

#define CANVAS_LEFT			1
#define CANVAS_TOP			2

#define SHOW_TOOLBAR_ENABLED	.T.
#define SHOW_TOOLBAR_DISABLED	.F.

#define SHOWWINDOW_IN_SCREEN	0
#define SHOWWINDOW_IN_TOPFORM 	1
#define SHOWWINDOW_AS_TOPFORM	2

#define WINDOWTYPE_MODELESS		0
#define WINDOWTYPE_MODAL		1

*-------------------------------------------------------
* Canvas Offsets
*-------------------------------------------------------

#define CANVAS_TOP_OFFSET_PIXELS          15		
#define CANVAS_LEFT_OFFSET_PIXELS         15
#define CANVAS_VERTICAL_GAP_PIXELS        10
#define CANVAS_HORIZONTAL_GAP_PIXELS      10

*-------------------------------------------------------
* Page Layout:
*-------------------------------------------------------

#define ORIENTATION_PORTRAIT	0
#define ORIENTATION_LANDSCAPE	1


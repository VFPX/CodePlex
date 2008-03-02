* GALLERY.PRG - Component Gallery.
*
* Copyright (c) 1996 Microsoft Corp.
* 1 Microsoft Way
* Redmond, WA 98052
*
* Description:
* Component Gallery.
*

#INCLUDE "browser.h"

PARAMETERS tcFileName,tcDefaultClass,tlListBox,tcClassType,tnWindowState,tlGallery,tlNoShow
LOCAL lcLastSetTalk,lcBrowser

lcLastSetTalk=SET("TALK")
SET TALK OFF
lcBrowser=LOWER(FULLPATH("browser.app",SYS(16)))
IF NOT FILE(lcBrowser)
	lcBrowser=_browser
ENDIF
DO (lcBrowser) WITH (tcFileName),(tcDefaultClass),(tlListBox),(tcClassType), ;
		(tnWindowState),.T.,(tlNoShow)
IF lcLastSetTalk=="ON"
	SET TALK ON
ELSE
	SET TALK OFF
ENDIF
RETURN



*-- end GALLERY.PRG

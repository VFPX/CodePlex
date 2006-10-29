_SCREEN.ADDPROPERTY("System", NEWOBJECT("xfcSystem", LOCFILE("system.vcx","vcx")))
LOCAL loReportListener, i
loReportListener = CREATEOBJECT("MyReportListener")
loReportListener.LISTENERTYPE = 1
CREATE CURSOR Dummy (campo1 c(20), field2 c(15))
FOR i=1 TO 200
	INSERT INTO Dummy VALUES ("Testing ReportListener with GdiPlus-X", "Visit CodePlex")
ENDFOR
SELECT dummy
GO TOP

REPORT FORM (LOCFILE("Teste","frx")) OBJECT loReportListener
USE IN dummy
RETURN

DEFINE CLASS MyReportListener AS _ReportListener OF ADDBS(HOME()) + "FFC\" + "_ReportListener.VCX"
	NewPage = .T.
	oGDIGraphics = NULL

	FUNCTION BEFOREREPORT
		DODEFAULT()
		This.oGDIGraphics = _SCREEN.SYSTEM.Drawing.Graphics.New() &&  CREATEOBJECT('GPGraphics')
	ENDFUNC

	FUNCTION BEFOREBAND(nBandObjCode, nFRXRecNo)
		#DEFINE FRX_OBJCOD_PAGEHEADER 1
		IF nBandObjCode==FRX_OBJCOD_PAGEHEADER
			This.NewPage = .T.
			IF NOT This.IsSuccessor
				This.SharedGDIPlusGraphics = This.GDIPLUSGRAPHICS
			ENDIF
			This.oGDIGraphics.Handle = This.SharedGDIPlusGraphics
		ENDIF
		DODEFAULT(nBandObjCode, nFRXRecNo)
	ENDFUNC

	PROCEDURE RENDER(nFRXRecNo,;
		nLeft,nTop,nWidth,nHeight,;
		nObjectContinuationType, ;
		cContentsToBeRendered, GDIPlusImage)
		WITH _SCREEN.SYSTEM.Drawing
			IF This.NewPage
				* Create a SolidBrush with Grey Color
				LOCAL loBrush AS xfcBrush
				loBrush = .SolidBrush.New(.COLOR.FromRgb(192,96,96))

				* Create a Rectangle in which the rotated text will be drawn
				LOCAL loRect AS xfcRectangle
				loRect = .Rectangle.New(0, 0, This.sharedPageWidth, This.sharedPageHeight)

				* Get a basic string format object, then set properties
				LOCAL loStringFormat AS xfcStringFormat
				loStringFormat = .StringFormat.New()
				loStringFormat.ALIGNMENT = .StringAlignment.CENTER
				loStringFormat.LineAlignment = .StringAlignment.CENTER

				* Create a Font object
				LOCAL loFont AS xfcFont
				loFont = .FONT.New("Verdana",48, 0, .GraphicsUnit.POINT)

				* Translate and Rotate
				This.oGDIGraphics.TranslateTransform(This.sharedPageWidth/2,This.sharedPageHeight/2)
				This.oGDIGraphics.RotateTransform(-45)
				This.oGDIGraphics.TranslateTransform(-This.sharedPageWidth/2,-This.sharedPageHeight/2)
				This.oGDIGraphics.DrawString("Rotated Text" + CHR(13) + CHR(10) + "GDIPlus-X is COOL !!!", ;
					loFont, loBrush, loRect, loStringFormat)

				* Reset Rotation
				This.oGDIGraphics.ResetTransform()

				This.NewPage = .F.
			ENDIF
		ENDWITH
		DODEFAULT(nFRXRecNo,;
			nLeft,nTop,nWidth,nHeight,;
			nObjectContinuationType, ;
			cContentsToBeRendered, GDIPlusImage)
	ENDPROC
ENDDEFINE
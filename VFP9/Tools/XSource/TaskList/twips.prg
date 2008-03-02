#include "include\twips.h"

Function TwipsToPixels
LParameters tnTwips, tnAxis

	*-- Declare API functions we need to use
	Declare Integer GetDC In User32.dll Integer
	Declare Integer ReleaseDC In User32.dll Integer, Integer
	Declare Integer GetDeviceCaps In gdi32.dll Integer, Integer

	Local hDC, nPixelsPerInch

	*-- Get the device context
	hDC = GetDC(0)
	
	*-- If axis is 0, we're dealing with X
	If tnAxis = AXIS_X
		
		*-- Get the number of horizontal pixels per inch
		nPixelsPerInch = GetDeviceCaps(hDC, WU_LOGPIXELSX)
	Else
		nPixelsPerInch = GetDeviceCaps(hDC, WU_LOGPIXELSY)
	Endif

	*-- Release the device context
	hDC = ReleaseDC(0, hDC)

	*-- There are 1440 twips in an inch; do the math to compute the pixel pos
	Return (tnTwips / TWIPS_PER_INCH) * nPixelsPerInch

EndFunc

Function PixelsToTwips
LParameters tnPixels, tnAxis

	*-- Declare API functions we need
	Declare Integer GetDC In User32.dll Integer
	Declare Integer ReleaseDC In User32.dll Integer, Integer
	Declare Integer GetDeviceCaps In gdi32.dll Integer, Integer

	Local hDC, nPixelsPerInch
	
	*-- Get the device context
	hDC = GetDC(0)
	
	*-- If tnAxis = 0 we are dealing with horiz. Otherwise vert.
	If tnAxis = AXIS_X
	
		*-- Get the pixels per inch on this monitor
		nPixelsPerInch = GetDeviceCaps(hDC, WU_LOGPIXELSX)
	Else
	
		nPixelsPerInch = GetDeviceCaps(hDC, WU_LOGPIXELSY)
	EndIf
	
	*-- Release the device context
	hDC = ReleaseDC(0, hDC)
	
	*-- Simple math to compute twips
	Return (tnPixels / nPixelsPerInch) * TWIPS_PER_INCH
	
EndFunc
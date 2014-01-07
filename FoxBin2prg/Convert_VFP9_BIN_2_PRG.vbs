'---------------------------------------------------------------------------------------------------
'	Convert_VFP9_BIN_2_PRG.vbs - 03/01/2014 - Fernando D. Bozzo (fdbozzo@gmail.com)
'---------------------------------------------------------------------------------------------------
'	ENGLISH:
'		- Copy this file in the same directory of FoxBin2prg and create a shortcut
'		on user's "SendTo" folder
'		- Now you can select files or directories, right click and "SendTo" FoxBin2prg for batch conversion
'
'	ESPA�OL:
'		- Copie este archivo en el mismo directorio que FoxBin2prg y cree un acceso directo
'		en la carpeta "SendTo" del usuario
'		- Ahora puede seleccionar archivos o directorios, pulsar click derecho y "Enviar a" FoxBin2prg para conversiones batch
'---------------------------------------------------------------------------------------------------
Const ForReading = 1 
Dim WSHShell, FileSystemObject
Dim oVFP9, nExitCode, cEXETool, cCMD, nDebug, cConvertType, aExtensions(8), foxbin2prg_cfg
Dim i, x, str_cfg, aConf, cErrMsg, cFlagGenerateLog, cFlagDontShowErrMsg, cFlagJustShowCall
Set WSHShell = WScript.CreateObject("WScript.Shell")
Set FileSystemObject = WScript.CreateObject("Scripting.FileSystemObject")
Set oVFP9 = CreateObject("VisualFoxPro.Application.9")
foxbin2prg_cfg	= Replace(WScript.ScriptFullName, WScript.ScriptName, "foxbin2prg.cfg")
nExitCode = 0
cConvertType	= "BIN2PRG"		'<<< This is the only difference between the 2 scripts
'---------------------------------------------------------------------------------------------------
nDebug = 5		'Cumulative Flags: 0=OFF, 1=Create FoxBin2prg LOG, 2=Only show script calls, 4=Don't show FoxBin2prg error modal messages
'---------------------------------------------------------------------------------------------------

If cConvertType	= "BIN2PRG" Then
	aExtensions(1)	= "PJX"
	aExtensions(2)	= "VCX"
	aExtensions(3)	= "SCX"
	aExtensions(4)	= "FRX"
	aExtensions(5)	= "LBX"
	aExtensions(6)	= "DBF"
	aExtensions(7)	= "DBC"
	aExtensions(8)	= "MNX"
Else
	'-- Extensiones TXT por defecto
	aExtensions(1)	= "PJ2"
	aExtensions(2)	= "VC2"
	aExtensions(3)	= "SC2"
	aExtensions(4)	= "FR2"
	aExtensions(5)	= "LB2"
	aExtensions(6)	= "DB2"
	aExtensions(7)	= "DC2"
	aExtensions(8)	= "MN2"

	If FileSystemObject.FileExists( foxbin2prg_cfg ) Then
		'-- Existe el archivo de configuraci�n foxbin2prg.cgf
		Set objTextFile = FileSystemObject.OpenTextFile( foxbin2prg_cfg, ForReading ) 

		Do Until objTextFile.AtEndOfStream 
			strNextLine = objTextFile.Readline 
			arrFb2p_CFG = Split(strNextLine , ",") 
			For i = 0 to Ubound(arrFb2p_CFG) 
			    If Left( arrFb2p_CFG(i), 10 ) = "extension:" Then
					aConf = Split( arrFb2p_CFG(i), ":" )		'Obtengo la separaci�n de "extensi�n:" y "ext:equiv"
					str_cfg = UCase( Trim( aConf(1) ) )
					aConf = Split( str_cfg, "=" )				'Obtengo la separaci�n de extensi�n y equivalencia (vc2=vca)
					
					For x = 1 TO 8
						If aExtensions(x) = aConf(0) Then
							aExtensions(x) = UCase( aConf(1) )
							Exit For
						End If
					Next
				Else
					'Wscript.Echo "Saltear: " & arrFb2p_CFG(i)
				End If
			Next 
		Loop 
	End If
End if

If WScript.Arguments.Count = 0 Then
	nExitCode = 1
	cErrMsg = "nDebug = " & nDebug
	If GetBit(nDebug, 1) Then
		cErrMsg	= cErrMsg & Chr(13) & "Bit 0 ON: (1) Create FoxBin2prg LOG"
	End If
	If GetBit(nDebug, 2) Then
		cErrMsg	= cErrMsg & Chr(13) & "Bit 1 ON: (2) Only show script calls"
	End If
	If GetBit(nDebug, 3) Then
		cErrMsg	= cErrMsg & Chr(13) & "Bit 2 ON: (4) Don't show FoxBin2prg error modal messages"
	End If
	MsgBox cErrMsg, 64, "No parameters - Debug Status"
Else
	cEXETool	= Replace(WScript.ScriptFullName, WScript.ScriptName, "foxbin2prg.exe")
	
	For i = 0 To WScript.Arguments.Count-1
		scanDirs( WScript.Arguments(i) )
	Next
End If

WScript.Quit(nExitCode)


Private Sub scanDirs( tcArgument )
	Dim omFolder, oFolder
	If FileSystemObject.FolderExists( tcArgument ) Then
		'-- Es un directorio
		Set omFolder = FileSystemObject.GetFolder( tcArgument )
		For Each oFile IN omFolder.Files
			evaluateFile( oFile.Path )
		Next
		For Each oFolder IN omFolder.SubFolders
			scanDirs( oFolder.Path )
		Next
	Else
		'-- Es un archivo
		evaluateFile( tcArgument )
	End If
End Sub


Private Sub evaluateFile( tcFile )
	For x = 1 TO 8
		If aExtensions(x) = UCase( FileSystemObject.GetExtensionName( tcFile ) ) Then
			cFlagGenerateLog	= "'0'"
			cFlagDontShowErrMsg	= "'0'"
			cFlagShowCall		= "'0'"
			If GetBit(nDebug,1) Then
				cFlagGenerateLog	= "'1'"
			End If
			If GetBit(nDebug,2) Then
				cFlagJustShowCall	= "1"
			End If
			If GetBit(nDebug,3) Then
				cFlagDontShowErrMsg	= "'1'"
			End If
			
			If nDebug = 0 Or nDebug = 2 Then
				cCMD	= "DO " & chr(34) & cEXETool & chr(34) & " WITH " & chr(34) & tcFile & chr(34)
			Else
				cCMD	= "DO " & chr(34) & cEXETool & chr(34) & " WITH '" & tcFile & "','0','0','0'," & cFlagDontShowErrMsg & "," & cFlagGenerateLog 
			End If
			If cFlagJustShowCall = "1" Then
				MsgBox cCMD, 0, "PARAMETROS ENVIADOS"
			Else
				oVFP9.DoCmd( cCMD )
				nExitCode = oVFP9.Eval("_SCREEN.ExitCode")
			End If
			Exit For
		End If
	Next
End Sub


Function GetBit(lngValue, BitNum)
     Dim BitMask
     If BitNum < 32 Then BitMask = 2 ^ (BitNum - 1) Else BitMask = "&H80000000"
     GetBit = CBool(lngValue AND BitMask)
End Function

*-- SubFox Main --*
*-- Mainline entry point program for SubFox.APP or .EXE

#define APP_CLASS	"SubFox_Application"
#define APP_LIB		"SubFox Application Class.prg"

LPARAMETERS sOption, p1,p2,p3,p4,p5,p6,p7,p8,p9

sOption = PROPER( ALLTRIM( EVL( sOption, "Install" ) ) )
DO CASE
CASE sOption == "Tortoise"
	LOCAL o
	o = NEWOBJECT( "SubFoxTortoiseTools", "SubFox Tortoise.prg" )
	o.InstallHooks()
CASE sOption == "Encode" && Tortoise command
	LOCAL o
	o = NEWOBJECT( "SubFoxTortoiseTools", "SubFox Tortoise.prg" )
	o.Encode( p1 )
CASE sOption == "Decode" && Tortoise command
	LOCAL o
	o = NEWOBJECT( "SubFoxTortoiseTools", "SubFox Tortoise.prg" )
	o.Decode( p1 )
CASE sOption == "Setup"
	MESSAGEBOX( "Setup...", 64 )
	DO FORM SubFox_Includes
CASE sOption == "Translate"
	DO FORM SubFox_Translator
CASE sOption == "Help"
	LOCAL oApp
	oApp = NEWOBJECT( APP_CLASS, APP_LIB )
	oApp.ShowHelp()
CASE sOption == "Download"
	DO FORM SubFox_Download
CASE sOption == "Resolve"
	DO FORM SubFox_ConflictEditor
CASE sOption == "Upload"
	DO FORM SubFox_Upload
OTHERWISE && CASE sOption == "Install"
	LOCAL oApp, oTB
	oApp = NEWOBJECT( APP_CLASS, APP_LIB )
	oApp.CreateMenu()
	IF oApp.UseToolbar
		oTB = oApp.Toolbar && NEWOBJECT( "sfToolbar", "SubFox.vcx" )
	ENDIF
ENDCASE

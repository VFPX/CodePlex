Lparameters Direction, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8

Local cSubfoxProject, cDirection, iCount, iCur, sFName, o_Encoder, cArg
Local array afiles(1,1)
Local Array afiles2(1,1)

cDirection = "Decode"
cSubfoxProject = Curdir()
*cSubfoxProject = "C:\temp\trunk"

Activate Screen 

If Pcount() >= 1
	If Vartype(Direction) != "C" or not InList(Upper(Direction), "ENCODE", "DECODE")
		MessageBox( "Invalid Direction, Please use Decode or Encode")
		Return
	EndIf
	cDirection = Direction
EndIf


If Pcount() >= 2
	cArg = "Arg" + Transform(Pcount())
	cDirectory = &cArg
	
	If Vartype(cDirectory) != "C" 
		messagebox( "Invalid Directory")
		Return
	EndIf
	cSubfoxProject = cDirectory
EndIf
#include subfox.h

Set Exact On

o_Encoder = NEWOBJECT( "SubFoxTranslator", "SubFox Translation Classes.prg" )

*o_Encoder.ConvertFile(cSubfoxProject , "subfox.pjx")
cSubfoxProject = Addbs(cSubfoxProject)


iCount = ADir(aFiles, cSubfoxProject + "*")
*MessageBox(csubfoxproject + " : " + Transform(icount))
If Lower(cDirection) == "decode"
	For iCur = 1 to iCount
		sFName = aFiles(iCur, 1)
			*MessageBox(sfname)
		If LEN(sFName) > LEN(SUBFOX_PRIVATE_EXT) ;
			AND UPPER( RIGHT( sFName, LEN(SUBFOX_PRIVATE_EXT)+1 ) ) == ("." + Upper(SUBFOX_PRIVATE_EXT)) ;
			AND ForceExt(Upper(sfname), "") != "FOXUSER"
			sFName = RTRIM( LEFT( sFName, RAT( ".", sFName ) - 1 ) )
			If InList(Upper(JustExt(sFName)), "SCX", "VCX", "PJX", "FRX", "LBX", "MNX", "DBC", "DBF")
				o_Encoder.ConvertFile(cSubfoxProject + aFiles(icur, 1), cSubfoxProject + sFName)
			EndIf
			
		EndIf
	EndFor
Else
	For iCur = 1 to iCount
		sFName = aFiles(iCur, 1)
		*MessageBox(cDirection + " : " + sfname)
		If InList(Upper(JustExt(sFName)), "SCX", "VCX", "PJX", "FRX", "LBX", "MNX", "DBC", "DBF");
			AND ForceExt(Upper(sfname), "") != "FOXUSER"
			? sFName
			sFName = sFName + "." + SUBFOX_PRIVATE_EXT

			o_Encoder.ConvertFile(cSubfoxProject + aFiles(icur, 1),cSubfoxProject +  sFName)
			*Delete File aFiles(icur, 1)
		EndIf

	EndFor
*!*		For iCur = 1 to iCount
*!*			sFName = aFiles(iCur, 1)
*!*			If InList(Upper(JustExt(sFName)), "SCT", "VCT", "PJT", "FRT", "LBT", "MNT", "DBT", "BAK")&&, "CDX")
*!*				Delete File aFiles(icur, 1)
*!*			EndIf
*!*		EndFor
EndIf

iCount = ADir(aFiles2, cSubfoxProject + "*", "D")
For iCur = 1 to iCount
	If "D" $ aFiles2(iCur, 5)
		sFName = aFiles2(iCur, 1)
		If !Empty(Strtran(sfname, ".", ""))
			Do bootstrap.prg with cDirection, cSubfoxProject + sFName
		EndIf
	EndIf
EndFor

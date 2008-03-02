#DEFINE ERROR_SUCCESS 0 

************* Registry Samples *********************

SET PROCEDURE TO registry ADDITIVE

oReg=create('registry')
LOCAL cExtn,cAppKey,cAppName,nErrNum
LOCAL cOptionValue,cOptionName,aFoxOptions


**** Sample A
* This sample shows how to check the location of an application
* such as Word or Excel by looking up an associated extension 
* (e.g., DOC,OLE) in the Registry.

cExtn = "xls"
cAppKey = ""
cAppName = ""

* Get Application
nErrNum = oReg.GetAppPath(m.cExtn,@cAppKey,@cAppName)
IF m.nErrNum # ERROR_SUCCESS
	RETURN
ENDIF


*-- Misc things to check for:

* Remove switch here (e.g., C:\EXCEL\EXCEL.EXE /e)
IF AT(" ",m.cAppName) #0
	m.cAppName= ALLTRIM(SUBSTR(m.cAppName,1,AT(" ",m.cAppName)))
ENDIF

? m.cAppKey
? m.cAppName

* Is this the right version of application?
? "Version: "+RIGHT(m.cAppKey,1)  && check for valid version

* Does file exist?
? "File exists: "+IIF(FILE(m.cAppName),"Yes","No")
?

**** Sample B
* This sample shows how to lookup a Visual FoxPro option
* that is saved to the Registry via the Options dialog.

cOptionValue = ""
cOptionName = "ResWidth"
m.nErrNum = oReg.GetFoxOption(m.cOptionName,@cOptionValue)  
? m.cOptionName+" :"+m.cOptionValue

cOptionName = "ResHeight"
cOptionValue = ""
m.nErrNum = oReg.GetFoxOption(m.cOptionName,@cOptionValue)  
? m.cOptionName+" :"+m.cOptionValue

**** Sample C
* This sample sets a Fox Option

cOptionName = "ResWidth"
cOptionValue = "640"
m.nErrNum = oReg.SetFoxOption(m.cOptionName,m.cOptionValue)  
cOptionName = "ResHeight"
cOptionValue = "480"
m.nErrNum = oReg.SetFoxOption(m.cOptionName,m.cOptionValue)  
?
WAIT WINDOW

**** Sample D
* This sample enumerates throught Options key to populates array
DIMENSION aFoxOptions[1,2]
m.nErrNum = oReg.EnumFoxOptions(@aFoxOptions)  
LIST MEMO LIKE aFoxOptions

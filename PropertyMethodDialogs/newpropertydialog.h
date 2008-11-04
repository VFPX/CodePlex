#include NewPropertyDialogEnglish.H
#include FoxPro.H

#define cnMAX_MEMBER_DATA_SIZE			8192
	* maximum size of member data
#define ccMEMBER_DATA_XML_ELEMENT		'memberdata'
	* the member data element in the member data XML
#define ccXML_TRUE						'True'
	* the value for true in the member data XML
#define ccXML_ROOT_NODE					'VFPData'
	* the root node for the member data XML
#define ccXML_DOM_CLASS					'MSXML2.DOMDocument.4.0'
	* the class to use for the XML DOM object
#define ccACCESS_CODE					'return This.<Insert1>'
	* the code to put into the Access method
#define ccASSIGN_CODE					'lparameters tuNewValue' + chr(13) + 'This.<Insert1> = tuNewValue'
	* the code to put into the Assign method
#define ccCR							chr(13)
	* carriage return
#define ccLF							chr(10)
	* linefeed
#define ccCRLF							chr(13) + chr(10)
	* carriage return + linefeed
#define ccTAB							chr(9)
	* tab

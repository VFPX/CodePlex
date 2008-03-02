* -- Classes for returning content
* -- to be displayed in Panes
#include "foxpro.h"
#include "foxpane.h"


DEFINE CLASS Content AS Custom
	Name = "Content"
	
	CacheDir        = ''

	UniqueID        = ''
	InfoType        = ''
	TaskPaneID      = ''
	ParentID        = ''
	ContentTitle    = ''
	PaneType      = ''
	DataSrc         = ''
	Data            = ''
	XFormType       = ''
	XFormSrc        = ''
	XFormData       = ''
	LocalData       = .T.
	FileData        = '' && default to use if we could not retrieve content
	DebugMode       = .F.
	Options         = ''
	OptionData      = ''
	OptionPage      = ''
	User            = ''
	DefaultRefreshFreq = REFRESHFREQ_PANELOAD
	RefreshFreq     = REFRESHFREQ_PANELOAD
	Handler         = ''
	CacheTime       = .NULL.
	HelpURL         = ''
	HelpFile        = ''
	HelpID          = 0
	Inactive        = .F.


	CacheUpdated    = .F.

	* Web Services proxy info
	ProxyOption    = PROXY_NONE
	ProxyServer    = ''
	ProxyPort      = 0
	ProxyUser      = ''
	ProxyPassword  = ''
	ConnectTimeout = 0

	oEngine            = .NULL.
	oPane              = .NULL.

	oContentCollection = .NULL.
	oOptionCollection  = .NULL.

	* automatically set by the OptionPage property	
	OptionsClassName = ''
	OptionsClassLib  = ''

	Action 		= ''
	oParameters = .NULL.
	
	
	nTryCnt = 0  && how many times we've done retrieval

	PROCEDURE Init()
		THIS.oOptionCollection     = CREATEOBJECT("Collection")
		THIS.oContentCollection    = CREATEOBJECT("Collection")
	ENDPROC
	
	PROCEDURE Destroy()
		THIS.oEngine = .NULL.
		THIS.oPane   = .NULL.
	ENDPROC
	
	FUNCTION HandleAction(cAction, oParameters, oBrowser)
		LOCAL oException
		LOCAL lHandled
		LOCAL oContent
		LOCAL oTHIS
		
		m.lHandled = .F.

		FOR EACH oContent IN THIS.oContentCollection
			IF !m.oContent.Inactive
				m.lHandled = m.oContent.HandleAction(m.cAction, m.oParameters, m.oBrowser) OR m.lHandled
				IF VARTYPE(m.lHandled) <> 'L'
					m.lHandled = .T.
				ENDIF
			ENDIF
		ENDFOR

		IF !EMPTY(THIS.Handler)
			TRY
				oTHIS = THIS
				m.lHandled = EXECSCRIPT(THIS.Handler, m.cAction, m.oParameters, m.oBrowser, oTHIS)
				IF VARTYPE(m.lHandled) <> 'L'
					m.lHandled = .T.
				ENDIF
			CATCH TO oException
			ENDTRY
		ENDIF
		
		RETURN m.lHandled
	ENDFUNC
	

	PROCEDURE Options_Assign(cOptions)
		THIS.ParseOptionString(m.cOptions)
		THIS.Options = m.cOptions
	ENDPROC

	PROCEDURE OptionData_Assign(cOptionData)
		THIS.ParseOptionDataString(m.cOptionData)
		THIS.OptionData = m.cOptionData
	ENDPROC
	
	PROCEDURE OptionPage_Assign(cOptionPage)
		IF EMPTY(m.cOptionPage)
			THIS.OptionsClassName = ''
			THIS.OptionsClassLib  = ''
		ELSE
			IF '!' $ m.cOptionPage
				THIS.OptionsClassName = SUBSTR(m.cOptionPage, AT('!', m.cOptionPage) + 1)
				THIS.OptionsClassLib  = LEFT(m.cOptionPage, AT('!', m.cOptionPage) - 1)
			ELSE
				THIS.OptionsClassName = ALLTRIM(m.cOptionPage)
				THIS.OptionsClassLib  = "foxpaneoptions.vcx"
			ENDIF
			IF EMPTY(JUSTEXT(THIS.OptionsClassLib))
				THIS.OptionsClassLib = FORCEEXT(THIS.OptionsClassLib, "vcx")
			ENDIF
		ENDIF
		
		THIS.OptionPage = m.cOptionPage
	ENDPROC
	
	FUNCTION LogError(m.cErrorTitle, m.cErrorMsg, m.cOptionMsg, m.cOptionLink, m.oException)
		IF VARTYPE(m.cErrorTitle) <> 'C'
			m.cErrorTitle = THIS.ContentTitle
		ENDIF
	
		IF VARTYPE(m.cErrorMsg) <> 'C'
			m.cErrorMsg = ''
		ENDIF

		IF THIS.DebugMode
			IF VARTYPE(m.oException) == 'O'
				m.cErrorMsg = m.cErrorMsg + IIF(EMPTY(m.cErrorMsg), '', CHR(10)) + CHR(10) + m.oException.Message + m.oException.Procedure + "(" + TRANSFORM(m.oException.LineNo) + ")" + CHR(10) + m.oException.LineContents
			ELSE
				m.cErrorMsg = m.cErrorMsg + CHR(10) + PROGRAM(PROGRAM(-1) - 1)
			ENDIF
		ENDIF
		
		IF VARTYPE(m.cOptionMsg) <> 'C' AND !EMPTY(THIS.Options)
			m.cOptionMsg  = LINK_CONFIGURE_LOC
			IF VARTYPE(m.cOptionLink) <> 'C' OR EMPTY(m.cOptionLink)
				m.cOptionLink = "vfps:options?uniqueid=" + RTRIM(THIS.UniqueID)
			ENDIF
		ENDIF

		IF VARTYPE(THIS.oPane) == 'O'
			THIS.oPane.LogError(m.cErrorTitle, m.cErrorMsg, m.cOptionMsg, m.cOptionLink)
		ENDIF
	ENDFUNC

	FUNCTION GetParam(cParameter, m.cDefault)
		LOCAL m.cValue

		m.cValue = IIF(PCOUNT() > 1, m.cDefault, '')
		IF TYPE("THIS.oParameters") == 'O' AND !ISNULL(THIS.oParameters)
			m.cValue = THIS.oParameters.GetParam(m.cParameter)
		ELSE
			m.cValue = ''
		ENDIF
		
		RETURN m.cValue
	ENDFUNC
	
	* write out debug info
	FUNCTION WriteDebugInfo(cText, cFilename)
		IF THIS.DebugMode
			IF ISNULL(m.cText)
				m.cText = "null"
			ENDIF
			STRTOFILE(m.cText, ADDBS(THIS.CacheDir) + "Debug_" + m.cFilename)
		ENDIF
	ENDFUNC

	FUNCTION AddContent(oContent)
		THIS.oContentCollection.Add(oContent)
	ENDFUNC
	
	* return collection object of this content object
	* and any sub-content defined
	FUNCTION GetAllContent(oCollection)
		LOCAL oContent
		LOCAL i

		IF VARTYPE(m.oCollection) <> 'O'
			m.oCollection = CREATEOBJECT("Collection")
		ENDIF

		IF THIS.oContentCollection.Count > 0
			FOR i = 1 TO THIS.oContentCollection.Count
				oContent = THIS.oContentCollection.Item(i)
				IF m.oContent.InfoType == INFOTYPE_CONTENT
					m.oContent.GetAllContent(m.oCollection)
				ENDIF
			ENDFOR
		ELSE
			m.oCollection.Add(THIS)
		ENDIF
	
		RETURN m.oCollection
	ENDFUNC
	

	* <cDataSrc> = src of data (file, straight text, URL, script, webservice)
	* <cData>    = actual data to process
	FUNCTION RetrieveData(cDataSrc, cData)
		LOCAL cNewData
		LOCAL oException
		LOCAL nCnt
		LOCAL cScript
		LOCAL cMethod
		LOCAL cURI
		LOCAL cWSML
		LOCAL cPort
		LOCAL oXML
		LOCAL cFilename
		LOCAL oTHIS
		LOCAL ARRAY aInfo[1]

		m.cNewData = .NULL.

		DO CASE
		CASE m.cDataSrc == SRC_MEMO
			m.cNewData = m.cData

		CASE m.cDataSrc == SRC_FILE
			m.cFilename = m.cData
			IF EMPTY(JUSTPATH(m.cFilename))
				m.cFilename = ADDBS(THIS.CacheDir) + m.cFilename
			ENDIF
			IF FILE(m.cFilename)
				TRY
					m.cNewData = FILETOSTR(m.cFilename)
				CATCH TO oException
				ENDTRY
			ENDIF

		CASE m.cDataSrc == SRC_XML
			* load XML from specified URL or file
			m.nCnt = ALINES(aInfo, m.cData)
			IF m.nCnt > 0
				TRY
					m.oXML = CREATEOBJECT(MSXML_PARSER)
					m.oXML.async = .F.
					IF !m.oXML.Load(aInfo[1])
						m.cNewData = m.oXML.xml
					ENDIF
				CATCH
					m.cNewData = .NULL.
				FINALLY
					m.oXML = .NULL.
				ENDTRY
			ENDIF

		CASE cDataSrc == SRC_URL
			m.nCnt = ALINES(aInfo, m.cData)
			IF m.nCnt > 0
				m.cNewData = THIS.RetrieveFromURL(aInfo[1])
			ENDIF

		CASE cDataSrc == SRC_SCRIPT
			TRY 
				oTHIS = THIS
				m.cScript = THIS.ApplyOptions(m.cData)
				m.cNewData = EXECSCRIPT(m.cScript, oTHIS)
				
			CATCH TO oException
				THIS.LogError(.NULL., ERROR_SCRIPT_LOC, '', '', m.oException)
			ENDTRY

		CASE cDataSrc == SRC_WEBSERVICE
			* first line is the URI, second is the method
			m.nCnt = ALINES(aInfo, m.cData)
			IF m.nCnt > 1
				m.cURI     = THIS.ApplyOptions(aInfo[1])
				m.cMethod  = THIS.ApplyOptions(aInfo[2])
				IF m.nCnt > 2
					m.cServiceName = THIS.ApplyOptions(aInfo[3])
				ELSE
					m.cServiceName = ''
				ENDIF
				IF m.nCnt > 3
					m.cPort = THIS.ApplyOptions(aInfo[4])
				ELSE
					m.cPort = ''
				ENDIF
				IF m.nCnt > 4
					m.cWSML = THIS.ApplyOptions(aInfo[5])
				ELSE
					m.cWSML = ''
				ENDIF
				m.cNewData = THIS.CallWebService(m.cURI, m.cServiceName, m.cPort, m.cWSML, m.cMethod)
			ENDIF
			
		ENDCASE

		IF !ISNULL(m.cNewData) AND !EMPTY(m.cNewData)
			m.cNewData = THIS.ApplyOptions(m.cNewData)
		ENDIF
		
		RETURN m.cNewData
	ENDFUNC


	* retrieve data from a URL
	FUNCTION RetrieveFromURL(cURL)
		LOCAL cText
		LOCAL nResult
		LOCAL xmldoc
		LOCAL cFilename
		LOCAL cSafety
		LOCAL oException
		LOCAL tStartTime
		
		m.cText = .NULL.

		IF LOWER(RIGHT(m.cURL, 4)) == ".xml"
			TRY
				CLEAR TYPEAHEAD
				m.xmldoc = CreateObject(MSXML_PARSER)
				m.xmldoc.async = .T.

				m.xmldoc.Load(m.cURL)
				
				m.tStartTime = DATETIME()
				DO WHILE INKEY('H') <> 27 AND xmldoc.readystate <> 4 
					DOEVENTS
					IF THIS.ConnectTimeOut > 0 AND (DATETIME() - m.tStartTime) > THIS.ConnectTimeout
						EXIT
					ENDIF
				ENDDO

				IF xmldoc.readystate <> 4
					xmldoc.Abort()
				ELSE
					IF xmldoc.parseError.errorCode == 0
						m.cText = m.xmldoc.xml
					ENDIF
				ENDIF
			CATCH TO oException
				m.cText = .NULL.
			FINALLY
				m.xmldoc = .NULL.
			ENDTRY
			
		ELSE
			* retrieve web page that is not XML
			TRY
				DECLARE LONG URLDownloadToFile IN URLMON.DLL LONG, STRING, STRING, LONG, LONG
				
				m.cFilename = ADDBS(SYS(2023)) + SYS(2015) + ".tmp"
				
				m.nResult = URLDownloadToFile(0, m.cURL, m.cFilename, 0, 0)
				IF m.nResult == 0
					m.cText = FILETOSTR(m.cFilename)
				ENDIF

			CATCH TO oException
				m.cText = .NULL.
			FINALLY
				CLEAR DLLS "URLDownloadToFile"
			ENDTRY

			m.cSafety = SET("SAFETY")
			SET SAFETY OFF
			ERASE (m.cFilename)
			SET SAFETY &cSafety
		ENDIF
		
		RETURN m.cText
	ENDFUNC

	* Return .T. if content or any of the subcontent
	* comes from an online source
	FUNCTION OnlineData(lRefresh)
		LOCAL nRefreshFreq
		LOCAL cCacheFile
		LOCAL oContent
		LOCAL lOnlineData
		
		m.lOnlineData = .F.

		m.cCacheFile = ADDBS(THIS.CacheDir) + "cache." + RTRIM(THIS.UniqueID)
		DO CASE
		CASE THIS.PaneType == PANETYPE_HTML
			m.cCacheFile = m.cCacheFile + ".htm"
		CASE THIS.PaneType == PANETYPE_XML
			m.cCacheFile = m.cCacheFile + ".xml"
		OTHERWISE
			m.cCacheFile = m.cCacheFile + ".txt"
		ENDCASE

		IF !THIS.LocalData
			IF THIS.RefreshFreq == REFRESHFREQ_DEFAULT
				m.nRefreshFreq = THIS.DefaultRefreshFreq
			ELSE
				m.nRefreshFreq = THIS.RefreshFreq
			ENDIF

			IF m.nRefreshFreq == REFRESHFREQ_PANELOAD OR (m.nRefreshFreq == REFRESHFREQ_TASKLOAD AND THIS.nTryCnt == 0) OR (THIS.nTryCnt == 0 AND EMPTY(NVL(THIS.CacheTime, {}))) OR (m.nRefreshFreq > 0 AND !ISNULL(THIS.CacheTime) AND (DATE() - TTOD(THIS.CacheTime)) >= m.nRefreshFreq) OR m.lRefresh
				m.lOnlineData = .T.
			ELSE
				TRY
					IF ADIR(aFileExists, m.cCacheFile) == 0
						m.lOnlineData = .T.
					ENDIF
				CATCH
				ENDTRY
			ENDIF
		ENDIF
		
		IF !m.lOnlineData
			FOR EACH oContent IN THIS.oContentCollection
				IF !oContent.Inactive
					m.lOnlineData = oContent.OnlineData(m.lRefresh)
					IF m.lOnlineData
						EXIT
					ENDIF
				ENDIF
			ENDFOR
			m.oContent = .NULL.
		ENDIF

		RETURN m.lOnlineData
	ENDFUNC

	* this is called by the Pane itself, which in turn
	* calls RenderContent()
	FUNCTION GetContent(oEngine, oPane, lForceRefresh)
		LOCAL cContent
		LOCAL cSubContent
		LOCAL oError
		LOCAL cXFormData
		LOCAL oContent
		LOCAL nRefreshFreq
		LOCAL oException
		LOCAL cCacheFile
		LOCAL lRetrieveData
		LOCAL lUpdateCache
		LOCAL lWrapPaneInXML
		LOCAL oTHIS
		LOCAL ARRAY aFileExists[1]

		THIS.oEngine = m.oEngine
		THIS.oPane   = m.oPane

		m.lWrapPaneInXML = VFP_XMLCONTENT $ THIS.Data
		* process all sub-content
		m.cSubContent = ''
		FOR EACH oContent IN THIS.oContentCollection
			IF !oContent.Inactive
				IF !oContent.LocalData
					THIS.OnShowProgress(STRTRAN(CONNECTING_LOC, "#description#", oContent.ContentTitle))
				ENDIF


				oContent.Action = THIS.Action
				oContent.oParameters = THIS.oParameters

				m.cContent = THIS.RemoveEncoding(NVL(m.oContent.GetContent(m.oEngine, m.oPane, m.lForceRefresh), ''))
				
				IF m.lWrapPaneInXML
					m.cContent = ;
					  [<PaneContent id="] + RTRIM(oContent.UniqueID) + [">] + NEWLINE + ;
					  [<PaneTitle>] + oContent.ContentTitle + [</PaneTitle>] + NEWLINE + ;
					  [<HTMLText>] + NEWLINE + ;
						  "<![CDATA[" + m.cContent + "]]>" + NEWLINE + ;
					  [</HTMLText>] + NEWLINE + ; 
					  [</PaneContent>] + NEWLINE
				ENDIF

				m.cSubContent = m.cSubContent + m.cContent

			ENDIF
		ENDFOR

		m.cContent = .NULL.

		m.lRetrieveData = .T.

		m.cCacheFile = ADDBS(THIS.CacheDir) + "cache." + RTRIM(THIS.UniqueID)
		DO CASE
		CASE THIS.PaneType == PANETYPE_HTML
			m.cCacheFile = m.cCacheFile + ".htm"
		CASE THIS.PaneType == PANETYPE_XML
			m.cCacheFile = m.cCacheFile + ".xml"
		OTHERWISE
			m.cCacheFile = m.cCacheFile + ".txt"
		ENDCASE

		IF !m.lForceRefresh
			IF THIS.RefreshFreq == REFRESHFREQ_DEFAULT
				m.nRefreshFreq = THIS.DefaultRefreshFreq
			ELSE
				m.nRefreshFreq = THIS.RefreshFreq
			ENDIF

			* determine whether to retrieve data from specified sources or to use the cached version
			IF !THIS.LocalData 
				IF m.nRefreshFreq == REFRESHFREQ_PANELOAD OR (m.nRefreshFreq == REFRESHFREQ_TASKLOAD AND THIS.nTryCnt == 0) OR (THIS.nTryCnt == 0 AND EMPTY(NVL(THIS.CacheTime, {}))) OR (THIS.nTryCnt == 0 AND m.nRefreshFreq > 0 AND (DATE() - TTOD(THIS.CacheTime)) >= m.nRefreshFreq) OR m.lForceRefresh
					m.lRetrieveData = .T.
				ELSE
					TRY
						IF ADIR(aFileExists, m.cCacheFile) > 0
							m.cContent = FILETOSTR(m.cCacheFile)
							m.lRetrieveData = .F.
						ENDIF
					CATCH
					ENDTRY
				ENDIF
			ENDIF			
		ENDIF

		IF m.lRetrieveData
			THIS.nTryCnt = THIS.nTryCnt + 1

			m.cContent = THIS.RetrieveData(THIS.DataSrc, THIS.Data)
			IF ISNULL(m.cContent) AND !EMPTY(THIS.FileData)
				m.cContent = THIS.FileData
			ENDIF

			IF !ISNULL(m.cContent)
				IF !EMPTY(m.cSubContent)
					* insert subcontent where the placeholder is
					IF m.lWrapPaneInXML
						m.cContent = STRTRAN(m.cContent, VFP_XMLCONTENT, m.cSubContent)
					ELSE
						m.cContent = STRTRAN(m.cContent, VFP_CONTENT, m.cSubContent)
					ENDIF
				ENDIF

				* transform the content using either a script
				* or an XSL file
				m.cXFormData = THIS.RetrieveData(THIS.XFormSrc, THIS.XFormData)
				IF !EMPTY(NVL(m.cXFormData, ''))
					DO CASE
					CASE THIS.XFormType == XFORM_TYPE_XSL
						IF !EMPTY(NVL(m.cXFormData, ''))
							m.cContent = THIS.XMLTransform(THIS.ApplyOptions(m.cContent), THIS.ApplyOptions(m.cXFormData))
						ENDIF
						
						IF ADIR(aFileExists, ADDBS(THIS.CacheDir) + "pane.xsl") > 0
							m.cContent = ;
							 [<?xml version = "1.0" encoding="Windows-1252" standalone="yes"?>] + ;
							 [<?xml:stylesheet type="text/xsl" href="pane.xsl"?>] + ;
							 m.cContent
						ENDIF
						
					CASE THIS.XFormType == XFORM_TYPE_SCRIPT
						TRY
							oTHIS = THIS
							m.cContent = EXECSCRIPT(m.cXFormData, oTHIS)
						CATCH TO oException
							m.cContent = .NULL.
							THIS.LogError(ERROR_SCRIPT_LOC, '', '', '', oException)
						ENDTRY
					ENDCASE
				ENDIF
			ENDIF

			IF !THIS.LocalData
				IF ISNULL(m.cContent)
					IF ADIR(aFileExists, m.cCacheFile) > 0
						m.cContent = FILETOSTR(m.cCacheFile)
					ENDIF
				ELSE
					TRY
						STRTOFILE(m.cContent, m.cCacheFile, 0)
						THIS.CacheTime = DATETIME()
						THIS.CacheUpdated = .T.
					CATCH
					ENDTRY
				ENDIF
			ENDIF
		ENDIF

		THIS.oEngine = .NULL.
		THIS.oPane   = .NULL.

		RETURN m.cContent
	ENDFUNC


	
	* entry point for rendering content
	FUNCTION RenderContent(oEngine, oPane, cAction, oParameters, m.lForceRefresh)
		IF VARTYPE(m.cAction) == 'C'
			THIS.Action = m.cAction
		ENDIF
		IF VARTYPE(m.oParameters) == 'O'
			THIS.oParameters = oParameters
		ENDIF
		
		RETURN THIS.GetContent(m.oEngine, m.oPane, m.lForceRefresh)
	ENDFUNC

	FUNCTION RemoveEncoding(cXML)
		LOCAL cEncodeStr

		IF VARTYPE(m.cXML) == 'C'
			cEncodeStr = STREXTRACT(m.cXML, "<?xml", "?>")
			IF !EMPTY(cEncodeStr)
				m.cXML = STRTRAN(m.cXML, "<?xml" + cEncodeStr + "?>", '')
			ENDIF
		ENDIF
		
		RETURN m.cXML
	ENDFUNC
	
	* apply XSL transformation to XML string to
	* get resulting HTML text
	FUNCTION XMLTransform(cXML, cXSL)
		LOCAL cContent
		LOCAL xmldoc
		LOCAL xsldoc
		LOCAL oException

		IF EMPTY(m.cXSL)
			m.cContent = m.cXML
		ELSE
			m.cContent = ''
			TRY
				m.xmldoc = CreateObject(MSXML_PARSER)
				m.xmldoc.async = .F.
				m.xsldoc = CreateObject(MSXML_PARSER)
				m.xsldoc.async = .F.

				m.xmldoc.LoadXML(m.cXML)
				IF m.xmldoc.parseerror.errorcode == 0
					IF !EMPTY(m.cXSL)
						IF !m.xsldoc.LoadXML(m.cXSL)
							MESSAGEBOX("Problem loading XSL:" + CHR(10) + CHR(10) + m.xsldoc.parseError.Reason + CHR(10) + ;
							 "Source: " + m.xsldoc.parseError.Reason + " (" + TRANSFORM(m.xsldoc.parseError.line) + ")")
						ENDIF
						m.cContent = m.xmldoc.TransformNode(m.xsldoc)
					ENDIF
				ELSE
					IF THIS.DebugMode
						MESSAGEBOX("Problem transforming content: " + THIS.ContentTitle + "(" + THIS.UniqueID + ")")
					ENDIF
				ENDIF

			CATCH TO oException
				m.cContent = TRANSFORM(m.oException.LineNo) + ": " + m.oException.Message
			FINALLY
				m.xsldoc = .NULL.
				m.xmldoc = .NULL.
			ENDTRY
		ENDIF

		RETURN m.cContent
	ENDFUNC
	
	* execute a web service
	* Use the WSClient class from the FFC directory
	* if it's available.  If not, simply create
	* a SOAP object directly.
	FUNCTION CallWebService(cURI, cServiceName, cPort, cWSML, cMethodCall)
		LOCAL cContent
		LOCAL oProxy
		LOCAL oWS
		LOCAL oException

		IF VARTYPE(m.cServiceName) <> 'C'
			m.cServiceName = ''
		ENDIF
		IF VARTYPE(m.cPort) <> 'C'
			m.cPort = ''
		ENDIF

		m.cContent = .NULL.	
		m.oProxy   = .NULL.

		IF TYPE("ProxyDebug") == 'L' AND ProxyDebug
			? "CallWebService: " + EVL(cURI, '') + ", " + EVL(cMethodCall, '')
		ENDIF
		
		TRY
			m.oWS = NEWOBJECT("CTaskPaneWSHandler", "FoxPane.vcx")
			THIS.SetWebServiceProxyInfo(m.oWS)
			
			m.oProxy = m.oWS.SetupClient(m.cURI, m.cServiceName, m.cPort)

		CATCH TO oException
			m.oWS = .NULL.
			m.oProxy = .NULL.
		ENDTRY

		IF VARTYPE(m.oProxy) == 'O'
			TRY
				m.cContent = m.oProxy.&cMethodCall

			CATCH TO oException
				m.cContent = .NULL.
				THIS.LogError(.NULL., ERROR_WSMETHOD_LOC + m.cURI + " - " + m.cMethodCall, '', '', m.oException)
			ENDTRY
		ELSE
			THIS.LogError(.NULL., ERROR_WSCONNECT_LOC + m.cURI, '', '')
		ENDIF
		
		m.oProxy = .NULL.
		m.oWS = .NULL.
		
		RETURN m.cContent
	ENDFUNC
	
	
	FUNCTION GetWebServiceProxy(cURI, cServiceName, cPort)
		LOCAL oWS
		LOCAL oProxy
		
		m.oProxy = .NULL.

		IF TYPE("ProxyDebug") == 'L' AND ProxyDebug
			? "GetWebServiceProxy: " + EVL(cURI, '')
		ENDIF

		TRY
			m.oWS = NEWOBJECT("CTaskPaneWSHandler", "foxpane.vcx")
			THIS.SetWebServiceProxyInfo(m.oWS)
			
			m.oProxy = m.oWS.SetupClient(m.cURI, m.cServiceName, m.cPort)

		CATCH TO oException
			m.oWS = .NULL.
			m.oProxy = .NULL.
		ENDTRY

		
		RETURN m.oProxy
	ENDFUNC
	
	* Setup Web Service proxy object with Proxy connector properties
	FUNCTION SetWebServiceProxyInfo(oWS)
		oWS.ConnectTimeout = THIS.ConnectTimeout
		oWS.ProxyOption    = THIS.ProxyOption
		oWS.ProxyServer    = THIS.ProxyServer
		oWS.ProxyPort      = THIS.ProxyPort
		oWS.ProxyUser      = THIS.ProxyUser
		oWS.ProxyPassword  = THIS.ProxyPassword
	ENDFUNC	

	* parse string in PaneContents.Options, adding each option to the collection
	* (note: format is similar to an .INI file)
	FUNCTION ParseOptionString(cOptions)
		LOCAL i
		LOCAL nCnt
		LOCAL cValue
		LOCAL cAttrib
		LOCAL nPos
		LOCAL oOption
		LOCAL ARRAY aOptions[1]


		m.oOption = .NULL.
		m.nCnt = ALINES(m.aOptions, STRTRAN(m.cOptions, CHR(13), ''), .T., CHR(10))
		FOR m.i = 1 TO m.nCnt
			IF !EMPTY(m.aOptions[m.i])
				IF LEFT(m.aOptions[m.i], 1) = '[' AND RIGHT(m.aOptions[m.i], 1) == ']'
					m.oOption = CREATEOBJECT("Option")
					m.oOption.OptionName = STREXTRACT(m.aOptions[m.i], '[', ']')

					THIS.AddOption(m.oOption)
				ELSE
					IF !ISNULL(m.oOption)
						m.nPos = AT('=', m.aOptions[m.i])
						IF m.nPos > 1
							m.cAttrib = ALLTRIM(LOWER(LEFT(m.aOptions[m.i], m.nPos - 1)))
							m.cValue  = ALLTRIM(SUBSTR(m.aOptions[m.i], m.nPos + 1))
							
							DO CASE
							CASE m.cAttrib = "value"
								m.oOption.OptionValue = m.cValue

							CASE m.cAttrib = "classlib"
								m.oOption.OptionClassLib = m.cValue

							CASE m.cAttrib = "classname"
								m.oOption.OptionClassName = m.cValue

							CASE m.cAttrib = "caption"
								m.oOption.OptionCaption = m.cValue

							CASE m.cAttrib = "valueproperty"
								m.oOption.ValueProperty = m.cValue

							OTHERWISE
								TRY
									m.oOption.oPropertyCollection.Add(m.cValue, m.cAttrib)
								CATCH
								ENDTRY
							ENDCASE
						ENDIF
					ENDIF
				ENDIF
			ENDIF
		ENDFOR
	ENDFUNC

	* Parse option data as it is stored in OptionData
	* Look for options in the following format:
	*	ZipCode=33458
	*	Name=Ryan
	*	<cOptions> = string of options
	FUNCTION ParseOptionDataString(cOptions)
		LOCAL i
		LOCAL nCnt
		LOCAL nPos
		LOCAL ARRAY aOptions[1]

		m.nCnt = ALINES(aOptions, STRTRAN(cOptions, CHR(13), ''), .T., CHR(10))
		FOR m.i = 1 TO m.nCnt
			m.nPos = AT('=', aOptions[i])
			IF m.nPos > 1
				THIS.SetOption(LEFT(aOptions[m.i], m.nPos - 1), SUBSTR(aOptions[m.i], m.nPos + 1))
			ENDIF
		ENDFOR
	ENDFUNC	
	
	* Add an option to the option collection
	FUNCTION AddOption(oOption AS Option)
		IF VARTYPE(m.oOption) == 'O' AND !EMPTY(m.oOption.OptionName)
			TRY
				THIS.oOptionCollection.Add(m.oOption, m.oOption.OptionName)
			CATCH
			ENDTRY		
		ENDIF
	ENDFUNC

	FUNCTION GetOptionByName(cOptionName)
		LOCAL oOption
		LOCAL i
		
		m.cOptionName = LOWER(m.cOptionName)
		
		m.oOption = .NULL.
		FOR m.i = 1 TO THIS.oOptionCollection.Count
			IF LOWER(THIS.oOptionCollection.Item(m.i).OptionName) == m.cOptionName
				m.oOption = THIS.oOptionCollection.Item(m.i)
				EXIT
			ENDIF
		ENDFOR
		
		RETURN m.oOption
	ENDFUNC

	* Set an option value
	* 	<cOptionName> = option name to set
	* 	<cOptionValue> = option value
	FUNCTION SetOption(cOptionName, cOptionValue)
		LOCAL oOption
		LOCAL lSuccess
		
		m.oOption = THIS.GetOptionByName(m.cOptionName)
		m.lSuccess = VARTYPE(m.oOption) == 'O'
		IF m.lSuccess
			m.oOption.OptionValue = m.cOptionValue
		ENDIF
		
		RETURN m.lSuccess
	ENDFUNC

	* Return an option value
	* 	<cOptionName> = option name to return
	* 	[xDefault] = default to return if option not found
	FUNCTION GetOption(cOptionName, xDefault)
		LOCAL oOption
		LOCAL cOptionValue
		LOCAL cDataType
		
		IF PCOUNT() > 1
			m.cDataType = VARTYPE(xDefault)
			m.cOptionValue = TRANSFORM(m.xDefault)
		ELSE
			m.cDataType = 'C'
			m.cOptionValue = ''
		ENDIF

		m.oOption = THIS.GetOptionByName(m.cOptionName)

		IF VARTYPE(m.oOption) == 'O'
			m.cOptionValue = m.oOption.OptionValue
		ENDIF
		
		DO CASE
		CASE m.cDataType == 'N'
			RETURN VAL(m.cOptionValue)
		CASE m.cDataType == 'L'
			RETURN (UPPER(m.cOptionValue) == ".T." OR m.cOptionValue == '1')
		OTHERWISE		
			RETURN m.cOptionValue
		ENDCASE
	ENDFUNC
	
	* apply options to string
	* For exampe, if we have an option called ZipCode
	* and we find #ZipCode# in the passed text, 
	* then replace #ZipCode# with the actual option value
	*  <cText> = text to perform replacement on
	FUNCTION ApplyOptions(cText)
		LOCAL cText
		LOCAL oOption
		LOCAL cEvalExpr
		LOCAL cValue
		LOCAL cUniqueID
		
		FOR EACH oOption IN THIS.oOptionCollection
			m.cText = STRTRAN(m.cText, "##" + m.oOption.OptionName + "##", m.oOption.OptionValue, -1, -1, 1)
		ENDFOR

		* find and replace any UniqueID's insertions
		DO WHILE .T.
			m.cEvalExpr = STREXTRACT(m.cText, "##uniqueid=", "##", 1)
			IF LEN(m.cEvalExpr) == 0
				EXIT
			ENDIF

			* To-Do: use FoxPaneEngine to open this table and return the record
			IF THIS.oEngine.OpenTable(THIS.oEngine.PaneContentTable, "PaneContent")
				m.cUniqueID = PADR(m.cEvalExpr, LEN(PaneContent.UniqueID))
				IF SEEK(m.cUniqueID, "PaneContent", "UniqueID")
					m.cValue = NVL(THIS.RetrieveData(PaneContent.DataSrc, PaneContent.Data), '')
				ELSE
					m.cValue = ''
				ENDIF
				
				USE IN PaneContent

				m.cText = STRTRAN(m.cText, "##uniqueid=" + m.cEvalExpr + "##", m.cValue, -1, -1, 1)
			ENDIF
		ENDDO

		* we did all of the option replacements, now find and replace
		* any expressions
		DO WHILE .T.
			m.cEvalExpr = STREXTRACT(m.cText, "<<", ">>", 1)
			IF LEN(m.cEvalExpr) == 0
				EXIT
			ENDIF

			TRY
				m.cValue = TRANSFORM(EVALUATE(m.cEvalExpr))
			CATCH
				m.cValue = ''
			ENDTRY

			m.cText = STRTRAN(m.cText, "<<" + m.cEvalExpr + ">>", m.cValue)
		ENDDO
		
		RETURN m.cText	
	ENDFUNC
	

	* we use BINDEVENT() in FoxPaneEngine to bind to this in order to
	* show status messages as content is retrieved
	PROCEDURE OnShowProgress(cMsg)
		*** do not remove!!!
	ENDPROC

ENDDEFINE


DEFINE CLASS Option AS Custom
	ADD OBJECT oPropertyCollection AS Collection

	OptionName        = ''
	OptionValue       = ''
	OptionCaption     = ''
	OptionClassName   = "cfoxtextbox"
	OptionClassLib    = ''
	ValueProperty     = "value"
ENDDEFINE

* this is used by the FoxPaneSetup to parse all options
DEFINE CLASS OptionMgr AS Collection

	FUNCTION AddOption(cOptionName, cOptionCaption, cOptionValue, cOptionClassName)
		LOCAL oOption

		TRY
			m.oOption = THIS.Item(m.cOptionName)
		CATCH
			m.oOption = .NULL.
		ENDTRY

		IF VARTYPE(m.oOption) <> 'O'
			m.oOption = CREATEOBJECT("Option")
			m.oOption.OptionName = m.cOptionName
			TRY
				THIS.Add(m.oOption, m.cOptionName)
				
			CATCH
				m.oOption = .NULL.
			ENDTRY
		ENDIF
		
		IF VARTYPE(m.oOption) == 'O'
			m.oOption.oPropertyCollection.Remove(-1)

			IF VARTYPE(m.cOptionCaption) == 'C'
				m.oOption.OptionCaption = m.cOptionCaption
			ENDIF
			IF VARTYPE(m.cOptionValue) == 'C'
				m.oOption.OptionValue = m.cOptionValue
			ENDIF
			IF VARTYPE(m.cOptionClassName) == 'C'
				m.oOption.OptionClassName = m.cOptionClassName
			ENDIF
		ENDIF

		RETURN m.oOption		
	ENDFUNC
	
	FUNCTION SetOptionString(cOptions)
		LOCAL i
		LOCAL nCnt
		LOCAL cValue
		LOCAL cAttrib
		LOCAL nPos
		LOCAL oOption
		LOCAL ARRAY aOptions[1]

		THIS.Remove(-1)

		m.oOption = .NULL.
		m.nCnt = ALINES(m.aOptions, STRTRAN(m.cOptions, CHR(13), ''), .T., CHR(10))
		FOR m.i = 1 TO m.nCnt
			IF !EMPTY(m.aOptions[m.i])
				IF LEFT(m.aOptions[m.i], 1) = '[' AND RIGHT(m.aOptions[m.i], 1) == ']'
					m.oOption = CREATEOBJECT("Option")
					m.oOption.OptionName = STREXTRACT(m.aOptions[m.i], '[', ']')

					TRY
						THIS.Add(m.oOption, m.oOption.OptionName)
					CATCH
					ENDTRY
				ELSE
					IF !ISNULL(m.oOption)
						m.nPos = AT('=', m.aOptions[m.i])
						IF m.nPos > 1
							m.cAttrib = ALLTRIM(LEFT(m.aOptions[m.i], m.nPos - 1))
							m.cValue  = ALLTRIM(SUBSTR(m.aOptions[m.i], m.nPos + 1))
							
							TRY
								m.oOption.oPropertyCollection.Add(m.cValue, m.cAttrib)
							CATCH
							ENDTRY
						ENDIF
					ENDIF
				ENDIF
			ENDIF
		ENDFOR
	ENDFUNC

	FUNCTION GetOptionString
		LOCAL cOptions
		LOCAL i
		LOCAL j

		m.cOptions = ''
		FOR m.i = 1 TO THIS.Count
			m.cOptions = m.cOptions + IIF(EMPTY(m.cOptions), '', CHR(13) + CHR(10))
			m.cOptions = m.cOptions + '[' + THIS.Item(m.i).OptionName + ']' + CHR(13) + CHR(10)
			FOR m.j = 1 TO THIS.Item(m.i).oPropertyCollection.Count
				m.cOptions = m.cOptions + THIS.Item(m.i).oPropertyCollection.GetKey(m.j) + "=" + THIS.Item(m.i).oPropertyCollection(m.j) + CHR(13) + CHR(10)
			ENDFOR
		ENDFOR
		
		RETURN m.cOptions
	ENDFUNC	
	

ENDDEFINE

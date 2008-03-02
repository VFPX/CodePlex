*==============================================================================
* Program:			MemberDataEngine.PRG
* Purpose:			MemberData engine classes
* Last revision:	11/12/2004
*==============================================================================

#include MemberDataEditor.H

* The MemberData Editor engine class.

define class MemberDataEngine as Session
	oObject = .NULL.
		* Reference to the object we're working on MemberData for
	cMemberData = ''
		* Existing MemberData for the object
	dimension aObjectMembers[1]
		* An array of members of the object
	lHadMemberData = .T.
		* .T. if the object already had MemberData
	oXMLDOM = .NULL.
		* A reference to an XML DOM object
	cSelectedMember = ''
		* The name of the member passed to the editor by Builder.APP
	lCreateGetMemberDataRecord = .F.
		* .T. to create an _GetMemberData record in FOXCODE on a "setup editor"
		* call
	cErrorMessage = ''
		* The text of any error that occurred
	oMemberDataCollection = .NULL.
		* A collection of objects containing information about the MemberData
		* for the object
	lPropertiesWindowOpen = .F.
		* .T. if the Properties window was open when we started
	dimension aDockWindow[1]
		* An array of window dock states
	lClassDesigner = .F.
		* .T. if the object is a class
	lNoObjectMemberData = .F.
		* .T. if we can't create MemberData for the object

* Clean up upon exit.

	function Destroy
		This.oObject               = .NULL.
		This.oMemberDataCollection = .NULL.
		This.oXMLDOM               = .NULL.
	endfunc

* Set up properties based on the object we're working with.

	function SetupEngine(tlAddToFavorites)
		local laObjects[1], ;
			lnObjects, ;
			loObject
		with This

* If we don't already have it, get a reference to the selected object.

			if vartype(.oObject) <> 'O'
				lnObjects = aselobj(laObjects)
				if lnObjects = 0
					lnObjects = aselobj(laObjects, 1)
				endif lnObjects = 0
				if lnObjects > 0
					.oObject = laObjects[1]
				endif lnObjects > 0
			endif vartype(.oObject) <> 'O'
			if vartype(.oObject) = 'O'

* See if the selected object has a _MemberData property. If not and it's a
* member object, tell the user we'll handle the class/form and then find it.

				.lHadMemberData = pemstatus(.oObject, '_MemberData', 5)
				loObject = FindTopMostParent(.oObject, .lClassDesigner)
				if not .lHadMemberData and not compobj(.oObject, loObject)
					if tlAddToFavorites
						messagebox(ccLOC_CANT_ADD_FAVORITES, ;
							MB_OK + MB_ICONINFORMATION, ;
							ccLOC_CAP_MEMBER_DATA_EDITOR)
					else
						messagebox(ccLOC_USE_PARENT, ;
							MB_OK + MB_ICONINFORMATION, ;
							ccLOC_CAP_MEMBER_DATA_EDITOR)
					endif tlAddToFavorites
					.lNoObjectMemberData = .T.
				endif not .lHadMemberData ...

* Get the object's existing MemberData (if any) and an array of its members.

				if .lHadMemberData
					.cMemberData = .oObject._MemberData
					if vartype(.cMemberData) <> 'C'
						.cMemberData = ''
					endif vartype(.cMemberData) <> 'C'
				else
					.cMemberData = ''
				endif .lHadMemberData
				amembers(.aObjectMembers, .oObject, 1, 'PHG#')

* Create an XML DOM object and load the MemberData XML. If we have a problem,
* bug out.

				.oXMLDOM = createobject(ccXML_DOM_CLASS)
				.oXMLDOM.async = .F.
				if not empty(.cMemberData)
					.oXMLDOM.loadXML(.cMemberData)
					if .oXMLDOM.parseError.errorCode <> 0
						.cErrorMessage = ccLOC_INVALID_XML
					endif .oXMLDOM.parseError.errorCode <> 0
				endif not empty(.cMemberData)
			endif vartype(.oObject) = 'O'
		endwith
	endfunc

* Set the MemberData for the object so the specified member appears on the
* Favorites tab of the Properties window.

	function AddMemberToFavorites
		local loNode, ;
			lnMember, ;
			lcType, ;
			loRoot, ;
			lcMemberData
		with This

* Get the node for the member (if it exists).

			loNode = .oXMLDOM.selectSingleNode('//' + ;
				ccMEMBER_DATA_XML_ELEMENT + '[@name = "' + .cSelectedMember + ;
				'"]')

* If it doesn't exist, we'll have to create it. First, determine what type of
* member we have (Property, Event, or Method).

			if vartype(loNode) <> 'O'
				lnMember = ascan(.aObjectMembers, .cSelectedMember, -1, -1, ;
					1, 15)
				lcType   = .aObjectMembers[lnMember, 2]

* Create a MemberData node for this member.

				loNode = .oXMLDOM.createElement(ccMEMBER_DATA_XML_ELEMENT)
				loNode.setAttribute('name', .cSelectedMember)
				loNode.setAttribute('type', lcType)

* Get the root node of the MemberData XML. If it doesn't exist, create it.

				loRoot = .oXMLDOM.selectSingleNode('/' + ccXML_ROOT_NODE)
				if vartype(loRoot) <> 'O'
					loRoot = .oXMLDOM.createElement(ccXML_ROOT_NODE)
					.oXMLDOM.appendChild(loRoot)
				endif vartype(loRoot) <> 'O'

* Add the new node to the root.

				loRoot.appendChild(loNode)
			endif vartype(loNode) <> 'O'

* Set the favorites attribute to True and update the _Memberdata property of
* the object.

			loNode.setAttribute('favorites', ccXML_TRUE)
			.cMemberData = .oXMLDOM.XML
			.WriteMemberData()
		endwith
	endfunc

* Update the _Memberdata property of the object (create it if necessary).

	function WriteMemberData
		with This
			if .lHadMemberData
				.oObject._MemberData = .cMemberData
			else
				.oObject.AddProperty('_MemberData', .cMemberData)
			endif .lHadMemberData
		endwith
	endfunc

* Fill oMemberDataCollection with a collection of the MemberData for the
* members of the object.

	function CreateMemberDataCollection
		local lnKeywordLen, ;
			lnLen, ;
			lnMember, ;
			llMemberDataInherited, ;
			llMemberDataChanged, ;
			llActiveX, ;
			laMembers[1], ;
			lnI, ;
			lcPEM, ;
			lcType, ;
			llNative, ;
			lnPos, ;
			loPEMMemberData, ;
			loGlobalMemberData, ;
			llMemberData, ;
			llInherited, ;
			lcName, ;
			lcClass, ;
			lcLibrary, ;
			lnLen, ;
			lcMemberData, ;
			loPEM, ;
			loDOM, ;
			loNodes, ;
			loNode, ;
			lcDisplay, ;
			loParent

* Open FDKEYWRD because it contains the correct case for all VFP PEMs. If we
* can't, we won't worry about it.

		try
			use home() + 'WIZARDS\FDKEYWRD' order TOKEN again shared in 0
			lnKeywordLen = len(FDKEYWRD.TOKEN)
		catch
		endtry

* Create a cursor of MemberData records from the FOXCODE table so we can look
* for global PEMs. Bug out if we can't open FOXCODE.

		try
			use (_foxcode) again shared in 0 alias FOXCODE
		catch
		endtry
		if not used('FOXCODE')
			This.cErrorMessage = ccLOC_CANT_OPEN_FOXCODE
			return
		endif not used('FOXCODE')
		select ABBREV from (_foxcode) ;
			where TYPE = 'P' and not deleted() ;
			into cursor _PROPERTIES
		index on upper(ABBREV) tag ABBREV
		select ABBREV, TIP from (_foxcode) ;
			where TYPE = ccGLOBAL_MEMBER_DATA_TYPE and not deleted() ;
			into cursor GLOBAL
		index on upper(ABBREV) tag ABBREV
		use in FOXCODE
		lnLen = len(ABBREV)

* Put all the object's PEMs into a collection. For ActiveX controls, we'll use
* AMEMBERS again to get the correct case for members.

		with This
			.oMemberDataCollection = createobject('Collection')
			lnMember = ascan(.aObjectMembers, '_MemberData', -1, -1, 1, 15)
			if lnMember > 0
				llMemberDataInherited = 'I' $ .aObjectMembers[lnMember, 3]
				llMemberDataChanged   = 'C' $ .aObjectMembers[lnMember, 3]
			endif lnMember > 0
			llActiveX = lower(.oObject.BaseClass) = 'olecontrol'
			if llActiveX
				amembers(laMembers, .oObject, 3)
			endif llActiveX
			for lnI = 1 to alen(.aObjectMembers, 1)
				lcPEM    = .aObjectMembers[lnI, 1]
				lcType   = lower(.aObjectMembers[lnI, 2])
				llNative = 'N' $ .aObjectMembers[lnI, 3]

* For each PEM that doesn't hold an object, get the information about its
* MemberData.

				if lcType <> 'object'
					llMemberData = .HasMemberData(lcPEM)

* This member has inherited member data if the member data was changed and this
* member doesn't appear in it or the member data wasn't changed and this member
* does appear (because we've just inherited the member data).

					llInherited = ((llMemberDataChanged and not llMemberData) or ;
						(not llMemberDataChanged and llMemberData)) and ;
						llMemberDataInherited and 'I' $ .aObjectMembers[lnI, 3]

* If we can find the member in FOXCODE, we'll use the abbreviation stored there
* since it may have the correct case.

					lcName = iif(seek(padr('.' + lcPEM, lnLen), '_PROPERTIES'), ;
						trim(substr(_PROPERTIES.ABBREV, 2)), lcPEM)

* If we can find it in FDKEYWRD, we'll use the name stored there since it'll be
* in the correct case.

					lcName = iif(used('FDKEYWRD') and ;
						seek(upper(padr(lcPEM, lnKeywordLen)), 'FDKEYWRD'), ;
						trim(FDKEYWRD.TOKEN), lcName)

* Get the correct case for members of ActiveX controls.

					if llActiveX
						lnPos = ascan(laMembers, lcPEM, -1, -1, 1, 15)
						if lnPos > 0
							lcName = laMembers[lnPos, 1]
						endif lnPos > 0
					endif llActiveX

* If the name is still upper-cased and it's a native or ActiveX control
* property, use PROPER() on it.

					if upper(lcName) == lcName and (llNative or llActiveX)
						lcName = proper(lcName)
					endif upper(lcName) == lcName ...

* Create an object to hold information about the MemberData.

					loPEMMemberData = createobject('MemberDataObject')
					with loPEMMemberData
						.HasMemberData = llMemberData
						.Inherited     = llInherited
						if llMemberData
							.Display   = This.FindAttributeForMember(lcPEM, ;
								'Display')
							.Favorites = This.FindAttributeForMember(lcPEM, ;
								'Favorites')
							.Override  = This.FindAttributeForMember(lcPEM, ;
								'Override')
							.Script    = This.FindAttributeForMember(lcPEM, ;
								'Script')
							.OriginalDisplay   = .Display
							.OriginalFavorites = .Favorites
							.OriginalOverride  = .Override
							.OriginalScript    = .Script
							lcName             = evl(.Display, lcName)
						endif llMemberData
						.CustomAttributes = This.GetCustomAttributesForMember(lcPEM, ;
							This.oXMLDOM)
					endwith

* Now get any global MemberData for the PEM.

					loGlobalMemberData = createobject('MemberDataObject')
					with loGlobalMemberData
						.HasMemberData = This.HasGlobalMemberData(lcPEM)
						if .HasMemberData
							loDOM = createobject(ccXML_DOM_CLASS)
							loDOM.async = .F.
							loDOM.loadXML(GLOBAL.TIP)
							if loDOM.parseError.errorCode = 0
								.Display           = This.FindAttributeForMember(lcPEM, ;
									'Display',   loDOM)
								.Favorites         = This.FindAttributeForMember(lcPEM, ;
									'Favorites', loDOM)
								.Override          = This.FindAttributeForMember(lcPEM, ;
									'Override',  loDOM)
								.Script            = This.FindAttributeForMember(lcPEM, ;
									'Script',    loDOM)
								.OriginalDisplay   = .Display
								.OriginalFavorites = .Favorites
								.OriginalOverride  = .Override
								.OriginalScript    = .Script
								lcName             = iif(upper(lcName) == lcName, ;
									evl(.Display, lcName), lcName)

* Get any custom attributes.

								.CustomAttributes = This.GetCustomAttributesForMember(lcPEM, ;
									loDOM)
							endif loDOM.parseError.errorCode = 0
						endif .HasMemberData
					endwith

* Add the PEM object to the collection. Due to a bug in AMEMBERS() that
* sometimes includes the same PEM more than once in the array, we'll trap for
* an duplicate item error when we add to the collection.

					loPEM = createobject('MemberObject')
					with loPEM
						.Name             = lcName
						.NativePEM        = llNative
						.Type             = lcType
						.ClassMemberData  = loPEMMemberData
						.GlobalMemberData = loGlobalMemberData
						.Display          = evl(loPEMMemberData.Display, ;
							loGlobalMemberData.Display)
					endwith
					try
						.oMemberDataCollection.Add(loPEM, lcPEM)
					catch
					endtry
				endif lcType <> 'object'
			next lnI

* Now get member data from all classes up the class hierarchy so it's displayed
* properly.
	
			lcClass   = iif(.lClassDesigner, lower(.oObject.ParentClass), ;
				lower(.oObject.Class))
			lcLibrary = .oObject.ClassLibrary
			do while not empty(lcLibrary)
				select 0
				use (lcLibrary) again shared
				locate for OBJNAME == lcClass and UNIQUEID <> 'RESERVED'
				lnPos = at('_memberdata = ', PROPERTIES)
				if lnPos > 0
					lnPos = lnPos + 14

* We have to handle properties with more than 255 characters in the value
* differently.

					if substr(PROPERTIES, lnPos, 1) = ccPROPERTIES_PADDING_CHAR
						lnLen        = val(alltrim(substr(PROPERTIES, ;
							lnPos + cnPROPERTIES_PADDING_SIZE, ;
							cnPROPERTIES_LEN_SIZE)))
						lcMemberData = substr(PROPERTIES, lnPos + ;
							cnPROPERTIES_PADDING_SIZE + cnPROPERTIES_LEN_SIZE, ;
							lnLen)
					else
						lcMemberData = strextract(substr(PROPERTIES, lnPos), ;
							'', ccCR)
					endif substr(PROPERTIES, lnPos, 1) = ccPROPERTIES_PADDING_CHAR
					if not empty(lcMemberData)
						loDOM = createobject(ccXML_DOM_CLASS)
						loDOM.async = .F.
						loDOM.loadXML(lcMemberData)
						if loDOM.parseError.errorCode = 0
							loNodes = loDOM.selectNodes('//' + ;
								ccMEMBER_DATA_XML_ELEMENT)
							for each loNode in loNodes
								lcPEM     = upper(loNode.getAttribute('name'))
								lcDisplay = nvl(loNode.getAttribute('display'), '')
								try
									loPEM           = .oMemberDataCollection.Item(lcPEM)
									loPEM.Display   = evl(loPEM.Display, ;
										lcDisplay)
									loPEM.Name      = evl(loPEM.Display, ;
										loPEM.Name)
									loPEMMemberData = createobject('MemberDataObject')
									with loPEMMemberData
										.HasMemberData = .T.
										.Location      = lcClass + ccLOC_OF + ;
											justfname(lcLibrary)
										.Display       = lcDisplay
										.Favorites     = nvl(loNode.getAttribute('favorites'), ;
											'')
										.Override      = nvl(loNode.getAttribute('override'), ;
											'')
										.Script        = nvl(loNode.getAttribute('script'), ;
											'')
										.OriginalDisplay   = .Display
										.OriginalFavorites = .Favorites
										.OriginalOverride  = .Override
										.OriginalScript    = .Script
										.CustomAttributes  = This.GetCustomAttributesForMember(lcPEM, ;
											loDOM)
									endwith

* Store the MemberData object in the ParentMemberData property of the
* appropriate object.

									do while vartype(loPEM.ParentMemberData) = 'O'
										loPEM = loPEM.ParentMemberData
									enddo while vartype(loPEM.ParentMemberData) = 'O'
									loPEM.ParentMemberData = loPEMMemberData
								catch
								endtry
							next loNode
						endif loDOM.parseError.errorCode = 0
					endif not empty(.cMemberData)
				endif lnPos > 0
				lcClass   = lower(CLASS)
				if not empty(CLASSLOC)
					lcLibrary = fullpath(CLASSLOC, addbs(justpath(lcLibrary)))
				else
					lcLibrary = ''
				endif not empty(CLASSLOC)
				use
			enddo while not empty(lcLibrary)

* Handle MemberData in the containership hierarchy.

			loParent = iif(type('.oObject.Parent.Name') = 'C', ;
				.oObject.Parent, .NULL.)
			do while vartype(loParent) = 'O'
				if pemstatus(loParent, '_MemberData', 5)
					loDOM.loadXML(loParent._MemberData)
					if loDOM.parseError.errorCode = 0
						loNodes = loDOM.selectNodes('//' + ;
							ccMEMBER_DATA_XML_ELEMENT)
						for each loNode in loNodes
							lcPEM     = upper(loNode.getAttribute('name'))
							lcDisplay = nvl(loNode.getAttribute('display'), '')
							try
								loPEM = .oMemberDataCollection.Item(lcPEM)
								.SetupContainershipHierarchy(loPEM)
								loPEM.Display   = evl(loPEM.Display, ;
									lcDisplay)
								loPEM.Name      = evl(loPEM.Display, ;
									loPEM.Name)
								loPEMMemberData = .FindMemberDataForContainer(loPEM, ;
									loParent.Name)
								with loPEMMemberData
									.HasMemberData = .T.
									.Location      = loParent.Name
									.Display       = lcDisplay
									.Favorites     = nvl(loNode.getAttribute('favorites'), ;
										'')
									.Override      = nvl(loNode.getAttribute('override'), ;
										'')
									.Script        = nvl(loNode.getAttribute('script'), ;
										'')
									.OriginalDisplay   = .Display
									.OriginalFavorites = .Favorites
									.OriginalOverride  = .Override
									.OriginalScript    = .Script
									.CustomAttributes  = This.GetCustomAttributesForMember(lcPEM, ;
										loDOM)
								endwith
							catch
							endtry
						next loNode
					endif loDOM.parseError.errorCode = 0
				endif pemstatus(loParent, '_MemberData', 5)
				try
					loParent = loParent.Parent
				catch
					loParent = .NULL.
				endtry
			enddo while vartype(loParent) = 'O'
		endwith

* Close the cursors.

		use in _PROPERTIES
		use in GLOBAL
		use in FDKEYWRD
	endfunc

* Determine if the specified MemberData entry has a setting for the specified
* member.

	function HasMemberData(tcMember)
		return not empty(strextract(This.cMemberData, 'memberdata name="' + ;
			tcMember + '"', '/>', 1, 1))
	endfunc

* Determine if the specified member has global member data.

	function HasGlobalMemberData(tcMember)
		return seek(padr(upper(tcMember), len(GLOBAL.ABBREV)), 'GLOBAL')
	endfunc

* Find the specified attribute for the specified member.

	function FindAttributeForMember(tcMember, tcAttribute, toDOM)
		local loDOM, ;
			lcValue, ;
			loNode
		if vartype(toDOM) = 'O'
			loDOM = toDOM
		else
			loDOM = This.oXMLDOM
		endif vartype(toDOM) = 'O'
		lcValue = ''
		loNode  = loDOM.selectSingleNode('//' + ccMEMBER_DATA_XML_ELEMENT + ;
			'[@name = "' + lower(tcMember) + '"]')
		if vartype(loNode) = 'O'
			lcValue = nvl(loNode.getAttribute(lower(tcAttribute)), '')
		endif vartype(loNode) = 'O'
		return lcValue
	endfunc

* Get any custom attribute for the specified member.

	function GetCustomAttributesForMember(tcMember, toDOM)
		local loAttributes, ;
			loNode, ;
			lcCurrExact, ;
			loAttribute
		loAttributes = createobject('Collection')
		loNode       = toDOM.selectSingleNode('//' + ;
			ccMEMBER_DATA_XML_ELEMENT + '[@name = "' + lower(tcMember) + '"]')
		if vartype(loNode) = 'O'
			lcCurrExact = set('EXACT')
			set exact on
			for each loAttribute in loNode.Attributes
				if not inlist(loAttribute.Name, 'name', 'type', 'display', ;
					'favorites', 'override', 'script')
					loAttributes.Add(loAttribute, loAttribute.Name)
				endif not inlist(loAttribute.Name ...
			next loAttribute
			if lcCurrExact = 'OFF'
				set exact off
			endif lcCurrExact = 'OFF'
		endif vartype(loNode) = 'O'
		return loAttributes
	endfunc

* Create a hierarchy of member data objects for the containers of the selected
* object. We'll grab any parent if it has a _MemberData property or if it's the
* topmost parent.

	function SetupContainershipHierarchy(toPEM)
		local loParent, ;
			loTopObject, ;
			llHaveFirstParent, ;
			loMemberData
		loParent          = iif(type('This.oObject.Parent.Name') = 'C', ;
			This.oObject.Parent, .NULL.)
		loTopObject       = FindTopMostParent(This.oObject, ;
			This.lClassDesigner)
		llHaveFirstParent = .F.
		loMemberData      = toPEM
		do while vartype(loParent) = 'O'
			if pemstatus(loParent, '_MemberData', 5) or ;
				compobj(loParent, loTopObject)
				if llHaveFirstParent
					loMemberData.ParentMemberData = createobject('MemberDataObject')
					loMemberData.ParentMemberData.Location  = loParent.Name
					loMemberData = loMemberData.ParentMemberData
				else
					loMemberData.ContainerMemberData = createobject('MemberDataObject')
					loMemberData.ContainerMemberData.Location  = loParent.Name
					loMemberData = loMemberData.ContainerMemberData
					llHaveFirstParent = .T.
				endif llHaveFirstParent
			endif pemstatus(loParent, '_MemberData', 5) ...
			try
				loParent = loParent.Parent
			catch
				loParent = .NULL.
			endtry
		enddo while vartype(loParent) = 'O'
		return
	endfunc

* Finds the appropriate member data object for the specified container.

	function FindMemberDataForContainer(toPEM, tcContainer)
		local loMemberData
		loMemberData = toPEM.ContainerMemberData
		do while vartype(loMemberData) = 'O' and ;
			loMemberData.Location <> tcContainer
			loMemberData = loMemberData.ParentMemberData
		enddo while vartype(loMemberData) = 'O' ...
		return loMemberData
	endfunc

* Create a MemberData node for the specified member and member data set.

	function CreateMemberDataForMember(toPEM, toMemberData, ;
		tlIgnoreInheritance)
		local loNode
		loNode = This.oXMLDOM.createElement(ccMEMBER_DATA_XML_ELEMENT)
		loNode.setAttribute('name', lower(toPEM.Name))
		loNode.setAttribute('type', toPEM.Type)
		This.UpdateMemberDataForMember(toPEM, toMemberData, loNode, ;
			tlIgnoreInheritance)
		return loNode
	endfunc
	
	function UpdateMemberDataForMember(toPEM, toMemberData, toNode, ;
		tlIgnoreInheritance)
		local llInherited, ;
			lnI, ;
			lcAttribute, ;
			loAttribute
		with toMemberData
			llInherited = .Inherited and not tlIgnoreInheritance

* If we have a display value and either this isn't a subclass or it is but the
* display value is different, create the display attribute. If we don't have a
* display value but we have a former display atrribute, remove it.

			do case
				case not empty(.Display) and (not llInherited or ;
					not .Display == .OriginalDisplay)
					toNode.setAttribute('display', .Display)
				case empty(.Display) and ;
					not empty(nvl(toNode.getAttribute('display'), ''))
					toNode.removeAttribute('display')
			endcase

* If this is supposed to be a favorite and this isn't a subclass, or it is a
* subclass but the member's favorite status is different in the subclass,
* create the favorite attribute. If we don't have a favorite value but we have
* a former favorite atrribute, remove it.

			do case
				case not empty(.Favorites) and (not llInherited or ;
					.Favorites <> .OriginalFavorites)
					toNode.setAttribute('favorites', .Favorites)
				case empty(.Favorites) and ;
					not empty(nvl(toNode.getAttribute('favorites'), ''))
					toNode.removeAttribute('favorites')
			endcase

* If this is supposed to be an override and this isn't a subclass, or it is a
* subclass but the member's override status is different in the subclass,
* create the override attribute. If we don't have a override value but we have
* a former override atrribute, remove it.

			do case
				case not empty(.Override) and (not llInherited or ;
					.Override <> .OriginalOverride)
					toNode.setAttribute('override', .Override)
				case empty(.Override) and ;
					not empty(nvl(toNode.getAttribute('override'), ''))
					toNode.removeAttribute('override')
			endcase

* If we have a script and either this isn't a subclass or it is but the script
* is different, create the script attribute. If we don't have a script but we
* have a former script atrribute, remove it.

			do case
				case not empty(.Script) and (not llInherited or ;
					not .Script == .OriginalScript)
					toNode.setAttribute('script', .Script)
				case empty(.Script) and ;
					not empty(nvl(toNode.getAttribute('script'), ''))
					toNode.removeAttribute('script')
			endcase

* Remove all custom sttributes (we'll add any we're supposed to save next).

			for lnI = toNode.attributes.length - 1 to 0 step -1
				lcAttribute = toNode.attributes(lnI).Name
				if not inlist(lower(lcAttribute), 'name', 'type', 'display', ;
					'favorites', 'override', 'script')
					toNode.removeAttribute(lcAttribute)
				endif not inlist(lower(lcAttribute) ...
			next lnI

* Handle custom attributes.

			if vartype(.CustomAttributes) = 'O'
				for each loAttribute in .CustomAttributes
					toNode.setAttribute(loAttribute.Name, loAttribute.Value)
				next loAttribute
			endif vartype(.CustomAttributes) = 'O'
		endwith
	endfunc

* Hide the Properties window if it's open.

	function HidePropertiesWindow
		if wvisible('Properties')
			adockstate(This.aDockWindow)
			hide window Properties
			This.lPropertiesWindowOpen = .T.
		endif wvisible('Properties')
	endfunc

* Redisplay the Properties window if necessary; if it was docked, we may need
* to redock it (it's "before" docking state may not match the docking state
* when we re-activate the window.

	function ShowPropertiesWindow
		local laDockWindow[1], ;
			lnCurrRow, ;
			lnRow, ;
			lnTabRow, ;
			lnPosition, ;
			lcWindow
		with This
			if .lPropertiesWindowOpen
				activate window Properties
				adockstate(laDockWindow)
				lnCurrRow = ascan(laDockWindow, 'PROPERTIES', -1, -1, 1, 15)
				lnRow     = ascan(.aDockWindow, 'PROPERTIES', -1, -1, 1, 15)
				if lnRow > 0 and .aDockWindow[lnRow, 2] = 1 and ;
					(.aDockWindow[lnRow, 3] <> laDockWindow[lnCurrRow, 3] or ;
					.aDockWindow[lnRow, 4] <> laDockWindow[lnCurrRow, 4] )
					lnTabRow = ascan(.aDockWindow, 'PROPERTIES', -1, -1, 4, 15)
					if lnTabRow > 0
						lnPosition = 4
						lcWindow   = .aDockWindow[lnTabRow, 1]
					else
						lnPosition = .aDockWindow[lnRow, 3]
						lcWindow   = .aDockWindow[lnRow, 4]
					endif lnTabRow > 0
					if not inlist(lcWindow, 'VIEW', 'TRACE', 'WATCH', ;
						'COMMAND', 'DOCUMENT', 'LOCALS', 'DEBUG OUTPUT', ;
						'CALL STACK')
						lcWindow = ''
					endif not inlist(lcWindow ...
					lcWindow = iif(empty(lcWindow), '', 'window "' + ;
						lcWindow + '"')
					dock window Properties position lnPosition &lcWindow
				endif lnRow > 0 ...
			endif .lPropertiesWindowOpen
		endwith
	endfunc

* Add _GetMemberData script to FOXCODE.

	function RegisterGetMemberDataScript(tlRegister)
		local lcCode

* Create the code for the _GetMemberData entry in FOXCODE.

		text to lcCode noshow
lparameters toFoxcode
local laObjects[1], ;
	loObject
if aselobj(laObjects) > 0 or aselobj(laObjects, 1) > 0
	loObject = __FindTopMostParent(laObjects[1])
	if vartype(loObject) = 'O' and not pemstatus(loObject, '_memberdata', 5)
		loObject.AddProperty('_memberdata', '')
	endif vartype(loObject) <> = 'O' ...
endif aselobj(laObjects) > 0 ...
return ''

* Find the top-most parent object for the specified object. The complication is
* that the top level container is a Formset in the Form and Class Designers,
* and even worse, one level down from the Formset is a Form for non-form
* classes in the Class Designer. So, we need to be careful about finding the
* top-most parent object.

function __FindTopMostParent(toObject)
local laObjects[1], ;
	llClass, ;
	loObject1, ;
	loObject2, ;
	llDone
if aselobj(laObjects, 3) <> 3
	return
endif aselobj(laObjects, 3) <> 3
if vartype(laObjects[2]) <> 'C'
	return
endif vartype(laObjects[2]) <> 'C'
llClass = upper(justext(laObjects[2])) = 'VCX'
store toObject to loObject1, loObject2
llDone = .F.
do while not llDone
	if not empty(loObject1.ClassLibrary) or (not llClass and ;
		not upper(loObject1.Class) == 'FORMSET')
		loObject2 = loObject1
	endif not empty(loObject1.ClassLibrary) ...
	if type('loObject1.Parent.Name') = 'C'
		loObject1 = loObject1.Parent
	else
		llDone = .T.
	endif type('loObject1.Parent.Name') = 'C'
enddo while not llDone
return loObject2
		endtext

* Add or remove the _GetMemberData record in FOXCODE.

		try
			use (_foxcode) again shared
			locate for TYPE = ccGLOBAL_MEMBER_DATA_TYPE and ;
				upper(ABBREV) = upper(ccGETMEMBERDATA_ABBREV) and not deleted()
			do case
				case not tlRegister and found()
					delete
				case not tlRegister
				case found()
					replace DATA with lcCode
				otherwise
					insert into (_foxcode) (TYPE, ABBREV, DATA) ;
						values (ccGLOBAL_MEMBER_DATA_TYPE, ;
						ccGETMEMBERDATA_ABBREV, lcCode)
			endcase
			use
		catch
		endtry
	endfunc

* Add information about MemberDataEditor to FOXCODE.

	function RegisterMemberDataEditor(tcPath)
		local lcXML

* Create the XML for the _MemberData entry in FOXCODE.

		text to lcXML noshow textmerge pretext 2
		<<ccXML_DECLARATION>>
		<VFPData><memberdata name="_memberdata" type="property" display="_MemberData"
		script="do [<<tcPath>>MemberDataEditor.app]"/></VFPData>
		endtext

* Add the _MemberData record to FOXCODE.

		try
			use (_foxcode) again shared
			locate for TYPE = ccGLOBAL_MEMBER_DATA_TYPE and ;
				upper(ABBREV) = '_MEMBERDATA' and not deleted()
			if found()
				replace TIP with lcXML
			else
				insert into (_foxcode) (TYPE, ABBREV, TIP) ;
					values (ccGLOBAL_MEMBER_DATA_TYPE, '_memberdata', lcXML)
			endif found()
			use
		catch
		endtry
	endfunc
enddefine

* A class to represent a member. Each *MemberData property contains a
* MemberDataObject object with the MemberData attributes from the specified
* location.

define class MemberObject as Custom
	ClassMemberData     = .NULL.
	ParentMemberData    = .NULL.
	ContainerMemberData = .NULL.
	GlobalMemberData    = .NULL.
	NativePEM           = .F.
	Type                = ''
	Display             = ''
enddefine

* A class to hold attribute values for a member.

define class MemberDataObject as Custom
	HasMemberData     = .F.
	Inherited         = .F.
	Display           = ''
	Location          = ''
	OriginalDisplay   = ''
	Favorites         = ''
	OriginalFavorites = ''
	Override          = ''
	OriginalOverride  = ''
	Script            = ''
	OriginalScript    = ''
	ParentMemberData  = .NULL.
	CustomAttributes  = .NULL.
enddefine

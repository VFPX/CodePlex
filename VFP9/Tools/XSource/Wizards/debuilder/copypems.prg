*==============================================================================
* Function:			CopyPEMs
* Purpose:			Copies PEMS from one object to another
* Author:			Doug Hennig
* Last revision:	07/21/2002
* Parameters:		toSource - the object to copy PEMs from
*					toTarget - the object to copy PEMs to
* Returns:			.T.
* Environment in:	toSource and toTarget must be objects
* Environment out:	all possible PEMs (those that exist in the target and
*						aren't read-only or protected) are copied from toSource
*						to toTarget
*==============================================================================

lparameters toSource, ;
	toTarget
local llAddProperty, ;
	lcFlags, ;
	laPEMs[1], ;
	lnPEMs, ;
	lnI, ;
	lcPEM, ;
	lcType, ;
	lcFlag, ;
	llExists, ;
	lcMethod, ;
	lcCode, ;
	lcOldCode, ;
	loSource, ;
	lcClass, ;
	lcLibrary, ;
	loTarget, ;
	luValue, ;
	luOldValue

* Get an array of public PEMs and process each one.

llAddProperty = pemstatus(toTarget, 'AddProperty', 5)
lcFlags       = 'G#'
lnPEMs        = amembers(laPEMs, toSource, 1, lcFlags)
for lnI = 1 to lnPEMs
	lcPEM    = laPEMs[lnI, 1]
	lcType   = laPEMs[lnI, 2]
	lcFlag   = laPEMs[lnI, 3]
	llExists = pemstatus(toTarget, lcPEM, 5)
	do case

* If this is a placeholder property for code (see below), copy it to the target
* object (this will only work if the target is in design mode!).

		case upper(lcPEM) = '__CODE_'
			lcMethod  = substr(lcPEM, 8)
			lcCode    = evaluate('toSource.' + lcPEM)
			lcOldCode = toTarget.ReadMethod(lcMethod)
			if not lcCode == lcOldCode
				toTarget.WriteMethod(lcMethod, luValue)
			endif not lcCode == lcOldCode

* If the PEM is a member, create such a member in the target object (if
* necessary) and call ourselves recursively to handle it.

		case lcType = 'Object'
			loSource = evaluate('toSource.' + lcPEM)
			if type('toTarget.' + lcPEM + '.Name') <> 'C'
				lcClass   = loSource.Class
				lcLibrary = loSource.ClassLibrary
				if empty(lcLibrary)
					toTarget.AddObject(lcPEM, lcClass)
				else
					toTarget.NewObject(lcPEM, lcClass, lcLibrary)
				endif empty(lcLibrary)
			endif type('toTarget.' + lcPEM + '.Name') <> 'C'
			loTarget = evaluate('toTarget.' + lcPEM)
			CopyPEMs(loSource, loTarget)

* Ensure the PEM isn't read-only and either exists in the target object or we
* can add it.

		case (llExists and pemstatus(toTarget, lcPEM, 1)) or ;
			(not llExists and not llAddProperty)

* If this is a method or event, copy any code from the source to a placeholder
* property in the target (since we almost certainly can't use WriteMethod) if
* we can.

		case inlist(lcType, 'Method', 'Event') and llAddProperty
			lcCode = toSource.ReadMethod(lcPEM)
			if not empty(lcCode)
				toTarget.AddProperty('__Code_' + lcPEM)
				store lcCode to ('toTarget.__Code_' + lcPEM)
			endif not empty(lcCode)
		case inlist(lcType, 'Method', 'Event')

* If this is an array property, use ACOPY (the check for element 0 is a
* workaround for a VFP bug that makes native properties look like arrays; that
* is, TYPE('OBJECT.NAME[1]') is not "U").

		case type('toSource.' + lcPEM + '[0]') = 'U' and ;
			type('toSource.' + lcPEM + '[1]') <> 'U'
			if not llExists
				toTarget.AddProperty(lcPEM + '[1]')
			endif not llExists
			acopy(toSource.&lcPEM, toTarget.&lcPEM)

* Copy the property value to the target object. We may have to use
* ReadExpression to get the desired value, since some properties (such as
* CursorAdapter.DataSource) fail otherwise.

		otherwise
			if not llExists
				toTarget.AddProperty(lcPEM)
			endif not llExists
			try
				luValue    = evaluate('toSource.' + lcPEM)
				luOldValue = evaluate('toTarget.' + lcPEM)
				if vartype(luValue) <> vartype(luOldValue) or ;
					not luValue == luOldValue
					store luValue to ('toTarget.' + lcPEM)
				endif vartype(luValue) <> vartype(luOldValue) ...
			catch
				luValue    = toSource.ReadExpression(lcPEM)
				luOldValue = toTarget.ReadExpression(lcPEM)
				if vartype(luValue) <> vartype(luOldValue) or ;
					not luValue == luOldValue
					toTarget.WriteExpression(lcPEM, luValue)
				endif vartype(luValue) <> vartype(luOldValue) ...
			endtry
	endcase
next lnI
return

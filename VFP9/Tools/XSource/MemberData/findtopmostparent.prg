* Find the top-most parent object for the specified object. The complication is
* that the top level container is a Formset in the Form and Class Designers,
* and even worse, one level down from the Formset is a Form for non-form
* classes in the Class Designer. ALso, of course, we could be editing a Formset
* or an object in a Formset. So, we need to be careful about finding the
* top-most parent object.

lparameters toObject, ;
	tlClass
local llClass, ;
	loObject1, ;
	loObject2, ;
	llDone
llClass = iif(pcount() = 1, upper(wontop()) = 'CLASS DESIGNER', tlClass)
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

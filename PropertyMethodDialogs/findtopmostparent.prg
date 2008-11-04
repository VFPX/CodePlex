* Find the top-most parent object for the specified object. The complication is
* that the top level container is a Formset in the Form and Class Designers,
* and even worse, one level down from the Formset is a Form for non-form
* classes in the Class Designer. So, we need to be careful about finding the
* top-most parent object.

lparameters toObject, ;
	tlClass
local llClass, ;
	loObject1, ;
	loObject2
llClass = iif(pcount() = 1, upper(wontop()) = 'CLASS DESIGNER', tlClass)
store toObject to loObject1, loObject2
do while type('loObject1.Parent.Name') = 'C' and ;
	upper(loObject1.Class) <> 'FORMSET' and ;
	(not llClass or not (upper(loObject1.Class) == 'FORM' and ;
	empty(loObject1.ClassLibrary)))
	loObject2 = loObject1
	loObject1 = loObject1.Parent
enddo while type('loObject1.Parent.Name') = 'C' ...
return loObject2

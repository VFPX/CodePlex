function CopyCode(cElement)
{
	var oElement = document.getElementById(cElement);
	window.clipboardData.setData("Text", oElement.innerText);
}

function ChangeClass(oElement, cClass)
{
	oElement.className = cClass;
}
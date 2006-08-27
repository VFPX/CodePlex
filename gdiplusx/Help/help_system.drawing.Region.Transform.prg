** Converted to GDIPlusX for VFP from .NET help:
** http://msdn.microsoft.com/library/default.asp?url=/library/en-us/cpref/html/frlrfsystemdrawingknowncolorclasstopic.asp
** The following code example demonstrates the use of Region.Transform Method
** Creates a rectangle and draws it to the screen in blue. 
** Creates a region from the rectangle. 
** Creates a transform matrix and sets it to 45 degrees. 
** Apply the transform to the region. 
** Fill the transformed region with red and draw the transformed region to the screen in red. 


_SCREEN.AddProperty("System", NEWOBJECT("xfcSystem", LOCFILE("system.vcx","vcx"))) 

WITH _SCREEN.System.Drawing

* Retrieve the graphics object.
* Initialize the graphics object to be able to draw in the _screen
LOCAL loScreenGfx AS xfcGraphics
loScreenGfx = .Graphics.FromHwnd(_Screen.HWnd)

* Create the first rectangle and draw it to the screen in blue.
LOCAL loRegionRect as xfcRectangle
loRegionRect = .Rectangle.New(100, 50, 100, 100)
loScreenGfx.DrawRectangle(.Pens.Blue, loRegionRect)

* Create a region using the first rectangle.
LOCAL loMyRegion as xfcRegion
loMyRegion = _screen.system.Drawing.Region.New(loRegionRect)

* Create a transform matrix and set it to have a 45 degree rotation.
LOCAL loTransformMatrix as xfcMatrix
loTransformMatrix = _screen.system.Drawing.Drawing2D.Matrix.New()
loTransformMatrix.RotateAt(45, .PointF.New(100, 50))

* Apply the transform to the region.
loMyRegion.Transform(loTransformMatrix)

* Fill the transformed region with red and draw it to the _screen in red.
LOCAL loMybrush as xfcBrush
loMyBrush = _screen.system.Drawing.SolidBrush.New( .Color.Red)
loScreenGfx.FillRegion(loMyBrush, loMyRegion)


ENDWITH 

RETURN
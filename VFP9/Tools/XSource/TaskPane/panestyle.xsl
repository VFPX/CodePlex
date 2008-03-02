<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:template match="VFPData">
<HTML>
<TITLE></TITLE>
<HEAD>
<STYLE>
  BODY {font-family:verdana;font-size:9pt}
  TD   {font-size:9pt}
  TD.CODE {color:#000080;font-family:Courier New}
  .TableTitle { font-family: Verdana; font-size: 9pt; font-weight: bold; background-color: #94b2d6; color: #000000}

  a:link {  color: #0000FF;text-decoration: none}
  a:visited {  color: #0000FF; text-decoration: none}
  a:hover {  color: #0066FF;text-decoration: underline}
  A {  text-decoration: underline; font-family: Verdana, Arial, Helvetica, sans-serif; color: #0066FF}
  A.button { background-color: #D2D2D2; 
 	border-right: thin outset;
	border-top: thin outset;
	border-left: thin outset;
	border-bottom: thin outset;
	padding-right: 2px;
	padding-left: 2px;
	padding-bottom: 1px;
	padding-top: 2px
  }
</STYLE>
</HEAD>
<BODY>
	<TABLE BORDER="0" width="100%" cellpadding="3" cellspacing="0">
	<xsl:for-each select="PaneContent">
		<TR><TD>
		<xsl:value-of select="HTMLText" disable-output-escaping="yes"/>
		</TD></TR>
	</xsl:for-each>
	</TABLE>
</BODY>
</HTML>
</xsl:template>

</xsl:stylesheet>

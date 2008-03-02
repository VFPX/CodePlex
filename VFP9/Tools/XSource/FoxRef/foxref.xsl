<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:template match="VFPData">
  <HTML>
  <STYLE>
  BODY {font-family:verdana;font-size:9pt}
  TD   {font-size:9pt}
  TD.CODE {color:#000080;font-family:Courier New}
  </STYLE>
    <BODY>
      <H2>Code References</H2>    
      <xsl:apply-templates select="exportcursor"/>
    </BODY>
  </HTML>
</xsl:template>

<xsl:template match="exportcursor">
  <TABLE BORDER="0" width="100%">
    <TR><TD valign="top" width="200"><B>Symbol:</B></TD><TD valign="top"><xsl:value-of select="symbol"/></TD></TR>
    <TR><TD valign="top" width="200"><B>Folder:</B></TD><TD valign="top"><xsl:value-of select="folder"/></TD></TR> 
    <TR><TD valign="top" width="200"><B>File Name:</B></TD><TD valign="top"><xsl:value-of select="filename"/></TD></TR>     
    <TR><TD valign="top" width="200"><B>Class.Method (Line, Col):</B></TD><TD valign="top"><xsl:value-of select="classname"/>.<xsl:value-of select="procname"/> (<xsl:value-of select="lineno"/>, <xsl:value-of select="colpos"/>)</TD></TR>
  </TABLE>    

  <TABLE BORDER="0" width="100%">
    <TR><TD valign="top"><B>Code:</B></TD></TR>
    <TR><TD valign="top" class="CODE"><xsl:value-of select="abstract"/></TD></TR>
  </TABLE>

  <HR/>
</xsl:template>
</xsl:stylesheet>


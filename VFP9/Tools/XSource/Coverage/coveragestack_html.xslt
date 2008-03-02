<?xml version="1.0" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"> 

<xsl:output omit-xml-declaration="yes" method="html" />

<xsl:variable name="level" select="0"/>

<xsl:template match="/">
<html>
<style type="text/css">
<xsl:comment>
.greenbar {background-color: #CCFFCC}
.whitebar {background-color: #FFFFFF}
</xsl:comment>
</style>
<body>
  <ul>
  <xsl:for-each select="./*">
     <xsl:call-template name ="stack">
        <xsl:with-param name="level" select="$level+1"/>
     </xsl:call-template>
  </xsl:for-each>
  </ul>
</body>
</html>
</xsl:template>

<xsl:template name="stack">
  <xsl:param name="level"/>

  <li>
  <xsl:value-of select="local-name()"/>
  </li>

  <xsl:if test="./*">
    <div>
    <xsl:attribute name="class">
   	<xsl:choose>
	<xsl:when test="$level mod 2 = 1">greenbar</xsl:when>
	<xsl:otherwise>whitebar</xsl:otherwise>
   	</xsl:choose> 
     </xsl:attribute>
     <ul>
     <xsl:for-each select="./*">
        <xsl:call-template name="stack">
           <xsl:with-param name="level" select="$level+1"/>
        </xsl:call-template>
     </xsl:for-each>
     </ul>
     </div>
  </xsl:if>

</xsl:template>

</xsl:stylesheet>

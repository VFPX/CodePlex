<?xml version = "1.0" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="xml" indent="yes" omit-xml-declaration="yes" encoding="Windows-1252" standalone="yes" cdata-section-elements="description title image runlink viewlink"/> 

<xsl:template match="VFPData">
	<VFPData>
	<xsl:call-template name="categorytemplate">
		<xsl:with-param name="parentid">0_</xsl:with-param>
	</xsl:call-template>
	</VFPData>
</xsl:template>


<xsl:template name="categorytemplate">
	<xsl:param name="parentid"/>
	<xsl:for-each select="//panesolution[parent=$parentid and type='N']">
		<category>
			<id>msft_<xsl:value-of select="key"/></id>
			<parent><xsl:value-of select="parent"/></parent>
			<provider>Microsoft</provider>
			<title><xsl:value-of select="text"/></title>
			<description><xsl:value-of select="descript"/></description>
			<showimage><xsl:value-of select="image"/></showimage>
			<isaddin><xsl:value-of select="isaddin"/></isaddin>

			<xsl:call-template name="categorytemplate">
				<xsl:with-param name="parentid" select="key"/>
			</xsl:call-template>
			<xsl:call-template name="solutiontemplate">
				<xsl:with-param name="parentid" select="key"/>
			</xsl:call-template>
		</category>
	</xsl:for-each>
</xsl:template>

<xsl:template name="solutiontemplate">
	<xsl:param name="parentid"/>
	<xsl:for-each select="//panesolution[parent=$parentid and type!='N']">
		<solution>
			<id>msft_<xsl:value-of select="key"/></id>
			<parent><xsl:value-of select="parent"/></parent>
			<provider>Microsoft</provider>
			<title><xsl:value-of select="text"/></title>
			<description><xsl:value-of select="descript"/></description>
			<showimage><xsl:value-of select="image"/></showimage>
			<isaddin><xsl:value-of select="isaddin"/></isaddin>			
			<xsl:choose>
				<xsl:when test="file and type !='A'  and type !='P' and type !='M' and type !='S' and type !='D'">
					<runlink>vfps:runsolution?filename=<xsl:value-of select="file"/>&amp;type=<xsl:value-of select="type"/>&amp;homedir=<xsl:value-of select="homedir"/></runlink>
					<viewlink>vfps:viewsolution?filename=<xsl:value-of select="file"/>&amp;type=<xsl:value-of select="type"/>&amp;homedir=<xsl:value-of select="homedir"/>&amp;method=<xsl:value-of select="method"/></viewlink>
				</xsl:when>
				<xsl:when test="file">
					<runlink>vfps:runsolution?filename=<xsl:value-of select="file"/>&amp;type=<xsl:value-of select="type"/>&amp;homedir=<xsl:value-of select="homedir"/></runlink>
					<viewlink></viewlink>
				</xsl:when>
				<xsl:otherwise>
					<runlink></runlink>
					<viewlink></viewlink>
				</xsl:otherwise>
			</xsl:choose>
		</solution>
	</xsl:for-each>
</xsl:template>
</xsl:stylesheet>


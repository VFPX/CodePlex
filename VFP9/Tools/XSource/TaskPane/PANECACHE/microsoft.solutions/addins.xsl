<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:template match="VFPData">
	<TABLE BORDER="0" width="100%" cellpadding="0" cellspacing="0" >
		<TR class="SolutionHeader" >
		<TD >
		Links to sites that have Add-Ins available:
	   </TD>
	   </TR>
   	   <xsl:apply-templates />
	</TABLE>
</xsl:template>

<xsl:template match="content" name="contents">
<xsl:variable name="linkvar" select="link"/>
<xsl:variable name="imagevar" select="image"/>
<xsl:variable name="idvar" select="id"/>
	<TR>
	<TD>	
		<xsl:if test="content">
			<A href="javascript:showAddinContent('{$idvar}')" class="toggle"><img border="0" src="p.gif" id="{$idvar}_link" align="absmiddle" /></A>
		</xsl:if>
				
		<xsl:if test="link and (not(string(link)=''))">
			<A href="{$linkvar}">
		
			<xsl:value-of select="name"/>
			<xsl:if test="image">	
				<xsl:text> </xsl:text>
				<img border="0" src="{$imagevar}" align="absmiddle" />
			</xsl:if>
			</A>
		</xsl:if>	
	
		<xsl:if test="not(link) or string(link)=''">
			<xsl:value-of select="name"/>
			<xsl:if test="image">	
				<xsl:text> </xsl:text>
				<img border="0" src="{$imagevar}" align="absmiddle" />
			</xsl:if>
		</xsl:if>	
	
	</TD>
	</TR>	
	<TR>
	<TD>
		<xsl:if test="content">
			<TABLE BORDER="0" width="100%" cellpadding="2" cellspacing="0" id="{$idvar}_content" style="display:none" class="cat">
			<xsl:for-each select="content">
				<xsl:call-template name="contents" />
			</xsl:for-each>
			</TABLE>
		</xsl:if>
	</TD>
	</TR>

</xsl:template>


</xsl:stylesheet>

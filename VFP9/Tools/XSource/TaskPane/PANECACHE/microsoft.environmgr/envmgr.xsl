<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >
<xsl:template match="VFPData">
	<HTML>
		<HEAD>
		</HEAD>
		<STYLE>
			BODY {
			font-family:verdana;
			font-size:9pt;
			margin-top:0px;
			margin-left:2px;
			margin-right:2px;	
			margin-bottom:2px;
			}  
			H3  {
			margin-bottom:0px;
			margin-top:0px;
			font-weight: bold
			}	  	
			TD   {font-size:9pt}
			a:link {  color: #0033CC;text-decoration: none}
			a:visited {   text-decoration: none}
			a:hover {  color: #CC0000;text-decoration: underline}
			A {  text-decoration: underline; font-family: Verdana, Arial, Helvetica, sans-serif; color: 

#0066FF			

}
			TD.TableTitle
			{ 
			padding:2px;
			background-color:#993333;
			color:#FFFFFF;
			}
			TR.TableSubTitle TD
			{
			border-bottom: #993333  1pt solid
			}
			TR.projaltrow TD
			{
			background-color:#ffffe6;
			}
			TABLE.EnvMgr 
			{
				border-right: #cccc99 1px solid;
				border-top: #cccc99 1px solid;
				border-left:#cccc99 1px solid;
				border-bottom: #cccc99 1px solid;
			}
			TR.EnvTitle TD
			{
			font-size: 10pt; 
			padding:2px;
			background-color:#f5f5dc;
				border-right: #cccc99 1px solid;
				border-top: #cccc99 1px solid;
				border-left:#cccc99 1px solid;
				border-bottom: #cccc99 1px solid;
				
			}
			INPUT
			{
			font-size: 9pt
			}
			SELECT 
			{
			font-size: 9pt
			}
			TABLE.project {
			margin-top:2px;
			
			}
			TABLE.project TD {
			font-size:8pt;
			
			}			

			
			A.toggle:link {  color: #000000;text-decoration: none}
			A.toggle:visited {   text-decoration: none}
			A.toggle:hover {  color: #000000;text-decoration: none}
			A.toggle {  text-decoration: none; color: #000000}

			
		</STYLE>	
		<SCRIPT><xsl:comment><![CDATA[
				
											
				]]></xsl:comment></SCRIPT>
		
		<SCRIPT for="window" event="onload"><xsl:comment><![CDATA[
				stylesheet = document.XSLDocument;
				source = document.XMLDocument;
				]]></xsl:comment>
		</SCRIPT>

		<BODY leftmargin="0" topmargin="0">
			<TABLE width="100%" cellspacing="0" cellpadding="0">
				<TR>
					<TD class="TableTitle" width="100%" nowrap="nowrap"><h3>Environment Manager</h3></TD>
					<TD  align="left" valign="center"><img src="envend.gif" alt="" /></TD>
				</TR>
				<TR>
					<TD colspan="2">
						<TABLE width="100%" cellspacing="2" cellpadding="2">
						<tr class="TableSubTitle">
						<td >The Environment Manager is where you can organize environment settings into groups and associate projects with them. When you select a project from here, the environment settings will execute before the project opens. </td>
						</tr>
						</TABLE>
					</TD>
				</TR>	
				<TR>
					<TD colspan="2" height="10"></TD>
				</TR>		          
				<TR class="EnvTitle" >
					<TD colspan="2" >
						<A href="vfps:doapplication?filename=(HOME() + [envmgr.app])&amp;refresh">Manage Environments</A>
					</TD>
				</TR>
				<TR>
					<TD valign="top" colspan="2">
						<DIV id="environments">
						<TABLE width="100%" class="EnvMgr">
							<xsl:apply-templates/>
						</TABLE>
						</DIV>
					</TD>
					
				</TR>
			</TABLE>    
		</BODY>		

	</HTML>
</xsl:template>

<xsl:template match="//environment">
	<xsl:variable name="idvar" select="id"/>
	<xsl:variable name="gotolinkvar" select="gotolink"/>
	<xsl:variable name="modifylinkvar" select="modifylink"/>

	<TR>
		<TD >
			<A href="{$gotolinkvar}">
			<img border="0" src="env.gif" align="absmiddle" alt="Execute these environment settings"/>
			<b><xsl:text> </xsl:text><xsl:value-of select="setname"/></b></A>
		</TD>
		<TD align="right">
			<A href="{$modifylinkvar}&amp;refresh"><img border="0" src="edit.gif" id="{$idvar}_link" align="absmiddle" alt="Modify this environment set"/></A>
		</TD>
		
	</TR>
	<TR>
		<TD colspan="2">
	<TABLE cellspacing="0" cellpadding="3" id="{$idvar}_content" class="project" width="100%">
		<xsl:call-template name="projects"/>

	</TABLE>
		</TD>
	</TR>
</xsl:template>


<xsl:template name="projects">
  <xsl:variable name="empty_string"/>
	<xsl:for-each select="project">
		<xsl:variable name="gotolinkvar" select="gotolink"/>
		

		<xsl:if test="position() mod 2 > 0">
	        	<TR class="projaltrow">
			<TD valign="top" width="100%">
				<A href="{$gotolinkvar}"><xsl:value-of select="setname"/></A>
			</TD>
			</TR>
		</xsl:if> 	
       	<xsl:if test="position() mod 2 = 0">
	        	<TR >
	        	<TD valign="top" width="100%">
				<A href="{$gotolinkvar}"><xsl:value-of select="setname"/></A>
			</TD>
			</TR>
		</xsl:if> 	



	</xsl:for-each>
</xsl:template>

	
</xsl:stylesheet>

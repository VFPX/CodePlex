<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >
<xsl:output encoding="Windows-1252"/>
<xsl:template match="VFPData">
			<XML ID="ResultsHeaderXML">
			</XML>
			<XML ID="ResultsXML">
			</XML>
			
			<TABLE width="100%" cellspacing="0" cellpadding="0">
				<TR>
				<TD >
					<TABLE width="100%" cellspacing="2" cellpadding="2">
						<TR class="TableSubTitle" >
							<TD colspan="2" >You can search or browse for solution samples you have installed.</TD>
						</TR>
					</TABLE>
				</TD>
				</TR>
				<TR >
					<TD height="10"></TD>
				</TR>
				<TR>
					<TD>
						<TABLE width="100%" cellspacing="0" cellpadding="0">
						<tr class="SolutionHeader">
						<td>Search for a sample by entering a search string below:</td>
						</tr>
						<tr>
						<td >
						<TABLE width="100%" cellspacing="2" cellpadding="2">
							<tr>
							<td>
								<form action="vfps:search" style="margin-bottom:0px">
								<input type="text" id="searchstring" style="vertical-align:middle;" /><xsl:text> </xsl:text>

								<A href="vfps:search" class="button">Search</A>
								<A href="vfps:reset" class="button">Reset</A>
								</form>
							</td>
							</tr>
							<tr id="ResultsHeader" class="ResultsHeader" style="display:none">
							<td >
								<span datasrc="#ResultsHeaderXML" datafld="results"></span>
							</td>
							</tr>
							<tr>
							<td>
							    <table datasrc="#ResultsXML" id="SearchResults" cellpadding="2" cellspacing="2" width="100%" style="display:none">
								<TR>
									<TD valign="top">
										<A datafld="runlink"><span datafld="title"></span></A>
									</TD>
									<TD valign="top" align="right">
										<A datafld="viewlink"><img border="0" src="showcode.gif" align="absmiddle" alt="Click here to view the code" /></A>
									</TD>
								</TR>
								<TR class="SolutionTitle">
									<TD colspan="2" valign="top">
										<span datafld="description" dataformatas="html"></span>
									</TD>
								</TR>
								<TR class="spacer">
									<TD valign="top" colspan="2" height="6">
									</TD>
								</TR>
							    </table>
							</td>
							</tr>
						</TABLE>
						</td>
						</tr>
						</TABLE>
					</TD>
					</TR>			          
					<TR >
					<TD height="10"></TD>
					
					</TR>
					<TR>
					<TD valign="top" >
					<TABLE width="100%" cellspacing="0" cellpadding="0">
						<TR class="SolutionHeader">
						<td>Browse for a sample by category:</td>
						</TR>
						<TR>
						<TD>
						<TABLE width="100%" cellspacing="0" cellpadding="1">
							<tr>
							<td width="100%">
							<DIV id="categories">
								<xsl:apply-templates/>
							</DIV>
							</td>
							</tr>
						</TABLE>
						</TD>
						</TR>
					</TABLE>	
					</TD>
				</TR>
			</TABLE>
<TABLE BORDER="0" width="100%" cellpadding="0" cellspacing="0" >
		<TR >
		<TD  height="10"></TD>
		</TR>
		<tr class="SolutionHeader">
		<td>Solution Sample Add-Ins:</td>
		</tr>
		<TR>
		<td >
		Install downloaded samples so that they are available from the Task Pane. Simply click the button below and navigate to the sample's manifest file.
		</td>
		</TR>
		<TR>
		<td>
		<A href="vfps:addin?refresh" class="button">Install Sample</A>
		</td>
		</TR>
		<TR>
		<td height="10">
		</td>
		</TR>
	</TABLE>
</xsl:template>

<xsl:template match="//category" name="categories">
	<xsl:variable name="idvar" select="id"/>
	<xsl:variable name="imagevar" select="showimage"/>
	<TR>
		<TD>
			<A href="javascript:showContent('{$idvar}')" class="toggle"><img border="0" src="p1.gif" id="{$idvar}_link" align="absmiddle" /><img border="0" src="{$imagevar}.gif" align="absmiddle" /><xsl:text> </xsl:text>
			<xsl:value-of select="title"/></A>
		</TD>
		</TR>
		<TR>
		<TD width="100%">
		<TABLE cellspacing="0" cellpadding="1" id="{$idvar}_content" style="display:none" class="cat" width="95%">
			<xsl:if test="category">
				<xsl:for-each select="category">
					<xsl:call-template name="categories"/>
				</xsl:for-each>
			</xsl:if>
			<xsl:call-template name="solution"/>
		</TABLE>
			
		</TD>
	</TR>
</xsl:template>		

<xsl:template name="solution">
	<xsl:for-each select="solution">
		<xsl:variable name="idvar" select="id"/>
		<xsl:variable name="parentvar" select="parent"/>
		<xsl:variable name="runlinkvar" select="runlink"/>
		<xsl:variable name="viewlinkvar" select="viewlink"/>

		<TR >
			<TD valign="top">
				<A href="{$runlinkvar}"><xsl:value-of select="title"/></A>
			</TD>
			<TD valign="top" align="right">
			<xsl:if test="not(string(isaddin)='N')">
				<A href="vfps:removeaddin?id={$idvar}&amp;parent={$parentvar}&amp;refresh" ><img border="0" src="removeaddin.gif" align="absmiddle" alt="Remove this Add-in from the Task Pane" /></A>
				<xsl:if test="string(viewlink)">
					<font color="#FFFFFF">.....</font>
				</xsl:if>
			</xsl:if>
			<xsl:if test="string(viewlink)">
				<A href="{$viewlinkvar}" ><img border="0" src="showcode.gif" align="absmiddle" alt="Click here to view the code" /></A>
			</xsl:if>
			</TD>
		</TR>
		<TR class="SolutionTitle">
			<TD colspan="2" valign="top">
				<xsl:value-of select="description" disable-output-escaping="yes" />
			</TD>
		</TR>
		<TR class="spacer">
			<TD valign="top" colspan="2" height="6">
			</TD>
		</TR>
	</xsl:for-each>
</xsl:template>

	
</xsl:stylesheet>

<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >

  <xsl:template match="/">
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
  TD.CODE {color:#000080;font-family:Courier New}
  a:link {  color: #0033CC;text-decoration: none}
  a:visited {   text-decoration: none}
  a:hover {  color: #CC0000;text-decoration: underline}
  A {  text-decoration: underline; font-family: Verdana, Arial, Helvetica, sans-serif; color: #0066FF}
  A.button
	{
	background:#E0DFE3;
	font-weight:bold;
	font-family:verdana;
	padding:2px;
	margin-left:0px;
	margin-right:2px;
	border-top:1px solid #E5E4E8;
	border-left:1px solid #E5E4E8;
	border-bottom:1px solid #6699CC;
	border-right:1px solid #6699CC;	
	color: #8080C0;
	font-size:1em;
	line-height:2em;
	text-align:center;
	}
  TD.TableTitle 
  	{ 
  	font-family: Verdana; 
  	font-size: 9pt; 
  	font-weight: bold; 
  	background-color: #8080C0; 
  	padding:2px;
  	color: #FFFFFF
  	}
  TR.TableSubTitle 
  	{ 
  	font-family: Verdana; 
  	font-size: 9pt; 
  	font-weight: bold; 
  	background-color: #f0f8ff; 
  	color: #C080C0  	
  	}
  TR.TableSubTitle TD
  {
  border-bottom: #C080C0  1pt solid
  }
  TABLE
  {
	margin-bottom:12px
  }
  TABLE.list
	{
	border-right: #6699CC 1pt solid;
	border-top: #E5E4E8 1pt solid;
	border-left: #E5E4E8 1pt solid;
	border-bottom: #6699CC 1pt solid;
	margin-bottom:2px
	}
  TABLE.list TD 
  	{
  	font-size: 8pt;
	border-right: #E0DFE3 1pt solid
  	}
  TABLE.list TR.altrow 
  	{
	background:#DFE5F4
  	}
  .itemdate
  	{
	color:#999999
  	}	
  H5.TableHeading {
  	margin-bottom:1px;
  	margin-top:10px;
  	font-size:9pt;
  	color:#FFFFFF;
  	padding:2px;
  	background-color:#C080C0 ;
  	font-weight:bold
  	}
TD.providerimage {
 	background-color:#E7E1ED;
}
TR.sortheader {
 	background-color:#E7E1ED;
}
TR.sortheader TD {
 	font-size: 8pt;
 	font-weight: bold;
 	border-bottom:1px solid #E7E1ED;
 }
INPUT
{
	font-size: 9pt
}
SELECT 
{
	font-size: 9pt
}
TABLE.links TD {
	font-size: 9pt;

}
TD.disclaimer {
	font-size: 8pt;
	color:#FF0000;
}
      </STYLE>	
      <SCRIPT><xsl:comment><![CDATA[
      
	function showContent( cID) {
	var content = cID+"_content"
	var link = cID+"_link"
	if (window.document.all(content).style.display == "none") {
		window.document.all(link).src = "m.gif";
		window.document.all(content).style.display = "";
		}
		else {
		window.document.all(link).src = "p.gif";
		window.document.all(content ).style.display = "none";
		}
	}

	function sort(field, order)
        {
          sortField.value = field;
	  sortOrder.value = order;
          listing.innerHTML = source.documentElement.transformNode(stylesheet);
        }

      ]]></xsl:comment></SCRIPT>

      <SCRIPT for="window" event="onload"><xsl:comment><![CDATA[
        stylesheet = document.XSLDocument;
        source = document.XMLDocument;
	sortField = document.XSLDocument.selectSingleNode("//xsl:sort/@select");
	sortOrder = document.XSLDocument.selectSingleNode("//xsl:sort/@order");
      ]]></xsl:comment></SCRIPT>
      
      <BODY leftmargin="0" topmargin="0">
	<TABLE cellpadding="0" cellspacing="0" style="margin-bottom:0px">
		
	<TR ><TD class="TableTitle" width="100%" nowrap="nowrap"><h3>Community</h3></TD>
		<TD  align="left" valign="center"><img src="commend.gif" alt="" /></TD>
	</TR>
	<TR ><TD colspan="2" >
		<table BORDER="0" width="100%" cellpadding="2" cellspacing="0" class="links">
  <tr>
    <td><a href="vfps:linkto?url=http://www.foxcentral.net">FoxCentral.net</a></td>
    <td><a href="vfps:linkto?url=http://leafe.com/mailman/listinfo/profox">ProFox Email List</a></td>
  </tr>
  <tr>
    <td><a href="vfps:linkto?url=http://www.FoxForum.com">FoxForum.com</a></td>
    <td><a href="vfps:linkto?url=http://www.universalthread.com">Universal 
    Thread</a></td>
  </tr>
  <tr>
    <td>
    <a href="vfps:linkto?url=http://msdn.microsoft.com/newsgroups/default.asp?url=/newsgroups/loadframes.asp?newsgroup=microsoft.public.fox.programmer.exchange">
    <xsl:text></xsl:text>
    FoxPro Newsgroups</a></td>
    <td><a href="vfps:linkto?url=http://www.vfug.org">Virtual FoxPro User Group</a></td>
  </tr>
  <tr>
    <td><a href="vfps:linkto?url=http://www.gotdotnet.com/team/vfp/">GotDotNet</a></td>
    <td>
    <a href="vfps:linkto?url=http://community.compuserve.com/n/pfx/forum.aspx?webtag=ws-MSDevApps">
    Visual FoxPro Forums on CompuServe</a></td>
  </tr>
  <tr>
    <td><a href="vfps:linkto?url=http://fox.wikis.com">Visual FoxPro Wiki</a></td>
    <td><a href="vfps:linkto?url=http://msdn.microsoft.com/vfoxpro/community/related/default.aspx">Related Communities</a></td>
  </tr>
</table>


		</TD>
		</TR>
	</TABLE>
        <TABLE width="100%" cellspacing="0" cellpadding="0">
        <TR >
        	<TD colspan="2" class="disclaimer">
All links to non-Microsoft sites are provided solely as a convenience.  Microsoft has no control of these sites, therefore, the responsibility for the contents on any non-Microsoft site, or any subsequent links that these sites might offer, resides soley with the site owner.  The results of search queries are displayed in random order, and offering these links in no way implies any endorsement by Microsoft.
        	</TD>
        </TR>
	<TR>	
	<TD class="TableTitle" ><h3>News</h3></TD>
	<TD class="TableTitle" align="right" nowrap="nowrap">
		Sort by 
 		 <SELECT name="lstSort" onChange="sort(this.options(this.selectedIndex).value, document.all.lstOrder.options(document.all.lstOrder.selectedIndex).value)">
 		 	<OPTION value="date">Date</OPTION>
 		 	<OPTION value="headline">Title</OPTION>
 		 	<OPTION value="provider">Provider</OPTION>
 		 </SELECT>
		Order 
 		 <SELECT name="lstOrder" onChange="sort(document.all.lstSort.options(document.all.lstSort.selectedIndex).value, this.options(this.selectedIndex).value)">
			<OPTION value="descending">Descending</OPTION>
 		 	<OPTION value="ascending">Ascending</OPTION>
 		 </SELECT>
	</TD>	
	</TR>		          
	<TR>
            <TD colspan="2" valign="top">
              <DIV id="listing"><xsl:apply-templates/></DIV>
            </TD>
          </TR>
        </TABLE>    
      </BODY>
    </HTML>
  </xsl:template>
  
  <xsl:template match="VFPData">
  
	
	<TABLE cellpadding="2" cellspacing="0">
	
	<xsl:for-each select="news">
	<xsl:sort select="date" data-type="text" order="descending"/> 
	<xsl:variable name="linkvar" select="link"/>
	<xsl:variable name="providervar" select="provider"/>
	<xsl:variable name="idvar" select="id"/>
	<xsl:variable name="imagefile" select="imagelink"/>
		<TR>
		<TD class="providerimage"><img border="0" src="{$imagefile}" alt="{$providervar}" /></TD>
		 <TD>
		<xsl:if test="content and (not(string(content)=''))">
		 <A href="javascript:showContent('{$idvar}')" class="toggle"><img border="0" src="p.gif" id="{$idvar}_link" align="absmiddle" /></A>
		</xsl:if>
		<xsl:if test="not(content) or (string(content)='')">
		 <font color="#FFFFFF">....</font>
		</xsl:if>
		 <xsl:text>  </xsl:text> 
		<xsl:if test="link and (not(string(link)=''))">
			<A href="vfps:linkto?url={$linkvar}"><xsl:value-of select="headline"/></A>
		</xsl:if>
		<xsl:if test="link and (string(link)='')">
			<xsl:value-of select="headline"/>
		</xsl:if>
		<xsl:for-each select="date">
			<span class="itemdate">
			(<xsl:value-of select="substring(text(),6,2)"/>/<xsl:value-of  select="substring(text(),9,2)"/>/<xsl:value-of select="substring(text(),1,4)"/>)
			</span>
		</xsl:for-each>
		</TD>
		</TR>
		<TR  id="{$idvar}_content" style="display:none">
		<TD class="providerimage"><xsl:text>  </xsl:text></TD>
		<TD>
			<xsl:value-of select="content"/>
		</TD>
		</TR>
	</xsl:for-each>
	</TABLE>
  
  </xsl:template>
  
  
</xsl:stylesheet>

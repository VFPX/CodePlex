
using System;
using System.ComponentModel;
using System.Text;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using Microsoft.VisualStudio;
using Microsoft.VisualStudio.Shell;
using Microsoft.VisualStudio.Shell.Interop;
using Microsoft.VisualStudio.Package;
using Microsoft.VisualStudio.Package.Automation;
using Microsoft.Win32;
using EnvDTE;
using IOleServiceProvider = Microsoft.VisualStudio.OLE.Interop.IServiceProvider;

namespace VFPX.FoxProIntegration.FoxProProject
{
	[ComVisible(true), CLSCompliant(false)]
	[Guid("BF389FD8-F382-41b1-B502-63CB11254137")]
	public class FoxProFileNodeProperties : SingleFileGeneratorNodeProperties
	{
		#region ctors
		public FoxProFileNodeProperties(HierarchyNode node)
			: base(node)
		{
		}
		#endregion

		#region properties

		[Browsable(false)]
		public string Url
		{
			get
			{
				return "file:///" + this.Node.Url;
			}
		}
		[Browsable(false)]
		public string SubType
		{
			get
			{
				return ((FoxProFileNode)this.Node).SubType;
			}
			set
			{
				((FoxProFileNode)this.Node).SubType = value;
			}
		}

		[Microsoft.VisualStudio.Package.SRCategoryAttribute(Microsoft.VisualStudio.Package.SR.Advanced)]
		[Microsoft.VisualStudio.Package.LocDisplayName(Microsoft.VisualStudio.Package.SR.BuildAction)]
		[Microsoft.VisualStudio.Package.SRDescriptionAttribute(Microsoft.VisualStudio.Package.SR.BuildActionDescription)]
		public virtual FoxProBuildAction FoxProBuildAction
		{
			get
			{
				string value = this.Node.ItemNode.ItemName;
				if (value == null || value.Length == 0)
				{
					return FoxProBuildAction.None;
				}
				return (FoxProBuildAction)Enum.Parse(typeof(FoxProBuildAction), value);
			}
			set
			{
				this.Node.ItemNode.ItemName = value.ToString();
			}
		}

		[Browsable(false)]
		public override BuildAction BuildAction
		{
			get
			{
				switch(this.FoxProBuildAction)
				{
					case FoxProBuildAction.ApplicationDefinition:
					case FoxProBuildAction.Page:
					case FoxProBuildAction.Resource:
						return BuildAction.Compile;
					default:
						return (BuildAction)Enum.Parse(typeof(BuildAction), this.FoxProBuildAction.ToString());
				}
			}
			set
			{
				this.FoxProBuildAction = (FoxProBuildAction)Enum.Parse(typeof(FoxProBuildAction), value.ToString());
			}
		}
		#endregion
	}

	public enum FoxProBuildAction { None, Compile, Content, EmbeddedResource, ApplicationDefinition, Page, Resource };
}

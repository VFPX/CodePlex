
using System;
using System.CodeDom.Compiler;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using System.Collections;
using System.Runtime.Serialization;
using System.Reflection;
using IServiceProvider = System.IServiceProvider;

using Microsoft.VisualStudio.Shell.Interop;
using Microsoft.VisualStudio.Shell;
using Microsoft.VisualStudio.OLE.Interop;
using Microsoft.VisualStudio.Package;
using Microsoft.VisualStudio.Package.Automation;
using Microsoft.VisualStudio.Designer.Interfaces;

using VFPX.FoxProIntegration.CodeDomCodeModel;

namespace VFPX.FoxProIntegration.FoxProProject
{
	/// <summary>
	/// Add support for automation on py files.
	/// </summary>
    [ComVisible(true)]
	[Guid("CCD70EB5-E3FE-454f-AD14-C945E9F04250")]
	public class OAFoxProFileItem : OAFileItem
    {
        #region variables
        private EnvDTE.FileCodeModel codeModel;
        #endregion

        #region ctors
        public OAFoxProFileItem(OAProject project, FileNode node)
			: base(project, node)
		{
		}
		#endregion

		#region overridden methods
        public override EnvDTE.FileCodeModel FileCodeModel
        {
            get
            {
                if (null != codeModel)
                {
                    return codeModel;
                }
                if ((null == this.Node) || (null == this.Node.OleServiceProvider))
                {
                    return null;
                }
                ServiceProvider sp = new ServiceProvider(this.Node.OleServiceProvider);
                IVSMDCodeDomProvider smdProvider = sp.GetService(typeof(SVSMDCodeDomProvider)) as IVSMDCodeDomProvider;
                if (null == smdProvider)
                {
                    return null;
                }
                CodeDomProvider provider = smdProvider.CodeDomProvider as CodeDomProvider;
                codeModel = FoxProCodeModelFactory.CreateFileCodeModel(this as EnvDTE.ProjectItem, provider, this.Node.Url);
                return codeModel;
            }
        }
        
        public override EnvDTE.Window Open(string viewKind)
		{
			if (string.Compare(viewKind, EnvDTE.Constants.vsViewKindPrimary) == 0)
			{
				// Get the subtype and decide the viewkind based on the result
				if (((FoxProFileNode)this.Node).IsFormSubType)
				{
					return base.Open(EnvDTE.Constants.vsViewKindDesigner);
				}
			}
			return base.Open(viewKind);
		}
		#endregion
	}

    [ComVisible(true)]
    public class OAFoxProProject : OAProject
    {
        public OAFoxProProject(FoxProProjectNode FoxProProject)
            : base(FoxProProject)
        {
        }

        public override EnvDTE.CodeModel CodeModel
        {
            get 
            {
                return FoxProCodeModelFactory.CreateProjectCodeModel(this);
            }
        }
    }

}

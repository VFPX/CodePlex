
using System;
using System.Text;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using Microsoft.VisualStudio.Shell.Interop;
using Microsoft.VisualStudio.Shell;
using Microsoft.VisualStudio.Package;
using Microsoft.Win32;
using EnvDTE;
using IOleServiceProvider = Microsoft.VisualStudio.OLE.Interop.IServiceProvider;

namespace VFPX.FoxProIntegration.FoxProProject
{
    [ComVisible(true), Guid("87EC20F2-2C4B-488c-91AE-76826E660CF0")]
    public class FoxProBuildPropertyPage : BuildPropertyPage
    {
    }
}

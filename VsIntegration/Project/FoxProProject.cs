
using System;
using System.Text;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using Microsoft.VisualStudio;
using Microsoft.VisualStudio.Shell.Interop;
using Microsoft.VisualStudio.Shell;
using Microsoft.VisualStudio.Package;
using Microsoft.Win32;
using EnvDTE;
using IOleServiceProvider = Microsoft.VisualStudio.OLE.Interop.IServiceProvider;
using VFPX.FoxProIntegration.FoxProLanguageService;
using System.Windows.Forms;
using System.Drawing;
using VSConstants = Microsoft.VisualStudio.VSConstants;
using Microsoft.Windows.Design.Host;
using VFPX.FoxProIntegration.FoxProProject.WPFProviders;

namespace VFPX.FoxProIntegration.FoxProProject
{
    [DefaultRegistryRoot("Software\\Microsoft\\VisualStudio\\9.0Exp")]
    //Set the projectsTemplatesDirectory to a non-existant path to prevent VS from including the working directory as a valid template path
    [ProvideProjectFactory(typeof(FoxProProjectFactory), "FoxPro", "FoxPro Project Files (*.foxproproj);*.foxproproj", "foxproproj", "foxproproj", ".\\NullPath", LanguageVsTemplate = "FoxPro")]
    [SingleFileGeneratorSupportRegistrationAttribute(typeof(FoxProProjectFactory))]
    [ProvideObject(typeof(GeneralPropertyPage))]
    [ProvideObject(typeof(FoxProBuildPropertyPage))]
    [ProvideMenuResource(1000, 1)]
    [ProvideEditorExtensionAttribute(typeof(EditorFactory), ".prg", 32)]
    [ProvideEditorLogicalView(typeof(EditorFactory), "{7651a702-06e5-11d1-8ebd-00a0c90f26ea}")]  //LOGVIEWID_Designer
    [ProvideEditorLogicalView(typeof(EditorFactory), "{7651a701-06e5-11d1-8ebd-00a0c90f26ea}")]  //LOGVIEWID_Code
    [Microsoft.VisualStudio.Shell.PackageRegistration(UseManagedResourcesOnly = true)]
    [ProvideLoadKey("standard", "1.0", "Visual Studio Integration of FoxPro Project System", "VFPX", 1)]
    [Guid("38F7EBA3-A5C6-4e32-B2C9-B6456F31B129")]
    [InstalledProductRegistration(true, null, null, null)]
    // Register the targets file used by the FoxPro project system.
    [ProvideMSBuildTargets("FoxPro_1.0", @"%ProgramFiles%\MSBuild\Microsoft\FoxPro\1.0\FoxPro.targets")]
    public class FoxProProjectPackage : ProjectPackage, IVsInstalledProduct
    {
        protected override void Initialize()
        {
            base.Initialize();
            this.RegisterProjectFactory(new FoxProProjectFactory(this));
            this.RegisterEditorFactory(new EditorFactory(this));
        }

        #region IVsInstalledProduct Members

        /// <summary>
        /// This method is called during Devenv /Setup to get the bitmap to
        /// display on the splash screen for this package.
        /// </summary>
        /// <param name="pIdBmp">The resource id corresponding to the bitmap to display on the splash screen</param>
        /// <returns>HRESULT, indicating success or failure</returns>
        public int IdBmpSplash(out uint pIdBmp)
        {
            pIdBmp = 300;

            return VSConstants.S_OK;
        }

        /// <summary>
        /// This method is called to get the icon that will be displayed in the
        /// Help About dialog when this package is selected.
        /// </summary>
        /// <param name="pIdIco">The resource id corresponding to the icon to display on the Help About dialog</param>
        /// <returns>HRESULT, indicating success or failure</returns>
        public int IdIcoLogoForAboutbox(out uint pIdIco)
        {
            pIdIco = 400;

            return VSConstants.S_OK;
        }

        /// <summary>
        /// This methods provides the product official name, it will be
        /// displayed in the help about dialog.
        /// </summary>
        /// <param name="pbstrName">Out parameter to which to assign the product name</param>
        /// <returns>HRESULT, indicating success or failure</returns>
        public int OfficialName(out string pbstrName)
        {
            pbstrName = GetResourceString("@ProductName");
            return VSConstants.S_OK;
        }

        /// <summary>
        /// This methods provides the product description, it will be
        /// displayed in the help about dialog.
        /// </summary>
        /// <param name="pbstrProductDetails">Out parameter to which to assign the description of the package</param>
        /// <returns>HRESULT, indicating success or failure</returns>
        public int ProductDetails(out string pbstrProductDetails)
        {
            pbstrProductDetails = GetResourceString("@ProductDetails");
            return VSConstants.S_OK;
        }

        /// <summary>
        /// This methods provides the product version, it will be
        /// displayed in the help about dialog.
        /// </summary>
        /// <param name="pbstrPID">Out parameter to which to assign the version number</param>
        /// <returns>HRESULT, indicating success or failure</returns>
        public int ProductID(out string pbstrPID)
        {
            pbstrPID = GetResourceString("@ProductID");
            return VSConstants.S_OK;
        }

        #endregion

        /// <summary>
        /// This method loads a localized string based on the specified resource.
        /// </summary>
        /// <param name="resourceName">Resource to load</param>
        /// <returns>String loaded for the specified resource</returns>
        public string GetResourceString(string resourceName)
        {
            string resourceValue;

            IVsResourceManager resourceManager = (IVsResourceManager)GetService(typeof(SVsResourceManager));
            
            if (resourceManager == null)
            {
                throw new InvalidOperationException("Could not get SVsResourceManager service. Make sure the package is Sited before calling this method");
            }
            
            Guid packageGuid = this.GetType().GUID;
            
            int hr = resourceManager.LoadResourceString(ref packageGuid, -1, resourceName, out resourceValue);
            
            Microsoft.VisualStudio.ErrorHandler.ThrowOnFailure(hr);
            
            return resourceValue;
        }
    }

    [GuidAttribute(FoxProProjectFactory.FoxProProjectFactoryGuid)]
    public class FoxProProjectFactory : Microsoft.VisualStudio.Package.ProjectFactory
    {
        public const string FoxProProjectFactoryGuid = "AF48B115-53DB-4e4f-A04C-CF2B83C29EE3";

        #region ctor
        public FoxProProjectFactory(FoxProProjectPackage package)
            : base(package)
        {

        }
        #endregion

        #region overridden methods
        protected override Microsoft.VisualStudio.Package.ProjectNode CreateProject()
        {
            FoxProProjectNode project = new FoxProProjectNode(this.Package as FoxProProjectPackage);
            project.SetSite((IOleServiceProvider)((IServiceProvider)this.Package).GetService(typeof(IOleServiceProvider)));
            return project;
        }
        #endregion
    }

    /// <summary>
    /// Type of outputfile extension supported by FoxPro Project
    /// </summary>
    internal enum OutputFileExtension
    {
        exe,
        dll
    }

    [Guid("5DADABD3-6A4C-455a-8450-C8ABD3CA9F9D")]
    public class FoxProProjectNode : Microsoft.VisualStudio.Package.ProjectNode, IVsProjectSpecificEditorMap2
    {
        #region fields
        private FoxProProjectPackage package;
        private Guid GUID_MruPage = new Guid("{19B97F03-9594-4c1c-BE28-25FF030113B3}");
        private VSLangProj.VSProject vsProject = null;
        private Microsoft.VisualStudio.Designer.Interfaces.IVSMDCodeDomProvider codeDomProvider;
        private static ImageList FoxProImageList;
        private ProjectDocumentsListenerForMainFileUpdates projectDocListenerForMainFileUpdates;
        internal static int ImageOffset;
        private DesignerContext designerContext;
        #endregion

        #region enums

        public enum FoxProImageName
        {
            FoxProFile = 0,
            FoxProProject = 1,
        }

        #endregion

        #region Properties
        /// <summary>
        /// Returns the outputfilename based on the output type
        /// </summary>
        public string OutputFileName
        {
            get
            {
                string assemblyName = this.ProjectMgr.GetProjectProperty(GeneralPropertyPageTag.AssemblyName.ToString(), true);

                string outputTypeAsString = this.ProjectMgr.GetProjectProperty(GeneralPropertyPageTag.OutputType.ToString(), false);
                OutputType outputType = (OutputType)Enum.Parse(typeof(OutputType), outputTypeAsString);

                return assemblyName + GetOuputExtension(outputType);
            }
        }
        /// <summary>
        /// Retreive the CodeDOM provider
        /// </summary>
        protected internal Microsoft.VisualStudio.Designer.Interfaces.IVSMDCodeDomProvider CodeDomProvider
        {
            get
            {
                if (codeDomProvider == null)
                    codeDomProvider = new VSMDFoxProProvider(this.VSProject);
                return codeDomProvider;
            }
        }
        protected internal Microsoft.Windows.Design.Host.DesignerContext DesignerContext
        {
            get
            {
                if (designerContext == null)
                {
                    designerContext = new DesignerContext();
                    //Set the EventBindingProvider and RuntimeNameProvider so the designer will call them
                    //when event handlers need to be generated
                    designerContext.EventBindingProvider = new FoxProEventBindingProvider(this as IVsProject3);
                    designerContext.RuntimeNameProvider = new FoxProRuntimeNameProvider();
                }
                return designerContext;
            }
        }
        /// <summary>
        /// Get the VSProject corresponding to this project
        /// </summary>
        protected internal VSLangProj.VSProject VSProject
        {
            get
            {
                if (vsProject == null)
                    vsProject = new Microsoft.VisualStudio.Package.Automation.OAVSProject(this);
                return vsProject;
            }
        }
        private IVsHierarchy InteropSafeHierarchy
        {
            get
            {
                IntPtr unknownPtr = Utilities.QueryInterfaceIUnknown(this);
                if (IntPtr.Zero == unknownPtr)
                {
                    return null;
                }
                IVsHierarchy hier = Marshal.GetObjectForIUnknown(unknownPtr) as IVsHierarchy;
                return hier;
            }
        }

        /// <summary>
        /// FoxPro specific project images
        /// </summary>
        public static ImageList FoxProImageList
        {
            get
            {
                return FoxProImageList;
            }
            set
            {
                FoxProImageList = value;
            }
        }
        #endregion

        #region ctor

        static FoxProProjectNode()
        {
            FoxProImageList = Utilities.GetImageList(typeof(FoxProProjectNode).Assembly.GetManifestResourceStream("Resources.FoxProImageList.bmp"));
        }

        public FoxProProjectNode(FoxProProjectPackage pkg)
        {
            this.package = pkg;
            this.CanFileNodesHaveChilds = true;
            this.OleServiceProvider.AddService(typeof(VSLangProj.VSProject), new OleServiceProvider.ServiceCreatorCallback(this.CreateServices), false);
			this.SupportsProjectDesigner = true;

            //Store the number of images in ProjectNode so we know the offset of the FoxPro icons.
            ImageOffset = this.ImageHandler.ImageList.Images.Count;
            foreach (Image img in FoxProImageList.Images)
            {
                this.ImageHandler.AddImage(img);
            }
            
            InitializeCATIDs();
        }

        /// <summary>
        /// Provide mapping from our browse objects and automation objects to our CATIDs
        /// </summary>
        private void InitializeCATIDs()
        {
            // The following properties classes are specific to FoxPro so we can use their GUIDs directly
            this.AddCATIDMapping(typeof(FoxProProjectNodeProperties), typeof(FoxProProjectNodeProperties).GUID);
            this.AddCATIDMapping(typeof(FoxProFileNodeProperties), typeof(FoxProFileNodeProperties).GUID);
            this.AddCATIDMapping(typeof(OAFoxProFileItem), typeof(OAFoxProFileItem).GUID);
            // The following are not specific to FoxPro and as such we need a separate GUID (we simply used guidgen.exe to create new guids)
            this.AddCATIDMapping(typeof(FolderNodeProperties), new Guid("A3273B8E-FDF8-4ea8-901B-0D66889F645F"));
            // This one we use the same as FoxPro file nodes since both refer to files
            this.AddCATIDMapping(typeof(FileNodeProperties), typeof(FoxProFileNodeProperties).GUID);
            // Because our property page pass itself as the object to display in its grid, we need to make it have the same CATID
            // as the browse object of the project node so that filtering is possible.
            this.AddCATIDMapping(typeof(GeneralPropertyPage), typeof(FoxProProjectNodeProperties).GUID);

            // We could also provide CATIDs for references and the references container node, if we wanted to.
        }

        #endregion

        #region overridden properties
        
        /// <summary>
        /// Since we appended the FoxPro images to the base image list in the constructor,
        /// this should be the offset in the ImageList of the FoxPro project icon.
        /// </summary>
        public override int ImageIndex
        {
            get
            {
                return ImageOffset + (int)FoxProImageName.foxproproject;
            }
        }

        public override Guid ProjectGuid
        {
            get
            {
                return typeof(FoxProProjectFactory).GUID;
            }
        }
        public override string ProjectType
        {
            get
            {
                return "FoxProProject";
            }
        }
        internal override object Object
        {
            get
            {
                return this.VSProject;
            }
        }
        #endregion

        #region overridden methods

        public override int GetGuidProperty(int propid, out Guid guid)
        {
            if ((__VSHPROPID)propid == __VSHPROPID.VSHPROPID_PreferredLanguageSID)
            {
                guid = typeof(FoxProLanguage).GUID;
            }
            else
            {
                return base.GetGuidProperty(propid, out guid);
            }
            return VSConstants.S_OK;
        }

        protected override bool IsItemTypeFileType(string type)
        {
            if (!base.IsItemTypeFileType(type))
            {
                if (String.Compare(type, "Page", StringComparison.OrdinalIgnoreCase) == 0
                || String.Compare(type, "ApplicationDefinition", StringComparison.OrdinalIgnoreCase) == 0
                || String.Compare(type, "Resource", StringComparison.OrdinalIgnoreCase) == 0)
                {
                    return true;
                }
                else
                {
                    return false;
                }
            }
            else
            {
                //This is a well known item node type, so return true.
                return true;
            }
        }

        protected override NodeProperties CreatePropertiesObject()
        {
            return new FoxProProjectNodeProperties(this);
        }

        public override int SetSite(Microsoft.VisualStudio.OLE.Interop.IServiceProvider site)
        {
            base.SetSite(site);

            //Initialize a new object to track project document changes so that we can update the MainFile Property accordingly
            this.projectDocListenerForMainFileUpdates = new ProjectDocumentsListenerForMainFileUpdates((ServiceProvider)this.Site, this);
            this.projectDocListenerForMainFileUpdates.Init();

            return VSConstants.S_OK;
        }

        public override int Close()
        {
            if (null != this.projectDocListenerForMainFileUpdates)
            {
                this.projectDocListenerForMainFileUpdates.Dispose();
                this.projectDocListenerForMainFileUpdates = null;
            }
            if (null != Site)
            {
                IFoxProLibraryManager libraryManager = Site.GetService(typeof(IFoxProLibraryManager)) as IFoxProLibraryManager;
                if (null != libraryManager)
                {
                    libraryManager.UnregisterHierarchy(this.InteropSafeHierarchy);
                }
            }

            return base.Close();
        }
        public override void Load(string filename, string location, string name, uint flags, ref Guid iidProject, out int canceled)
        {
            base.Load(filename, location, name, flags, ref iidProject, out canceled);
            // WAP ask the designer service for the CodeDomProvider corresponding to the project node.
            this.OleServiceProvider.AddService(typeof(SVSMDCodeDomProvider), new OleServiceProvider.ServiceCreatorCallback(this.CreateServices), false);
            this.OleServiceProvider.AddService(typeof(System.CodeDom.Compiler.CodeDomProvider), new OleServiceProvider.ServiceCreatorCallback(this.CreateServices), false);

            IFoxProLibraryManager libraryManager = Site.GetService(typeof(IFoxProLibraryManager)) as IFoxProLibraryManager;
            if (null != libraryManager)
            {
                libraryManager.RegisterHierarchy(this.InteropSafeHierarchy);
            }

            //If this is a WPFFlavor-ed project, then add a project-level DesignerContext service to provide
            //event handler generation (EventBindingProvider) for the XAML designer.
            this.OleServiceProvider.AddService(typeof(DesignerContext), new OleServiceProvider.ServiceCreatorCallback(this.CreateServices), false);

        }
        /// <summary>
        /// Overriding to provide project general property page
        /// </summary>
        /// <returns></returns>
        protected override Guid[] GetConfigurationIndependentPropertyPages()
        {
            Guid[] result = new Guid[1];
            result[0] = typeof(GeneralPropertyPage).GUID;
            return result;
        }

        /// <summary>
        /// Returns the configuration dependent property pages.
        /// Specify here a property page. By returning no property page the configuartion dependent properties will be neglected.
        /// Overriding, but current implementation does nothing
        /// To provide configuration specific page project property page, this should return an array bigger then 0
        /// (you can make it do the same as GetPropertyPageGuids() to see its impact)
        /// </summary>
        /// <param name="config"></param>
        /// <returns></returns>
        protected override Guid[] GetConfigurationDependentPropertyPages()
        {
            Guid[] result = new Guid[1];
            result[0] = typeof(FoxProBuildPropertyPage).GUID;
            return result;
        }

        public override object GetAutomationObject()
        {
            return new OAFoxProProject(this);
        }


        /// <summary>
        /// Overriding to provide customization of files on add files.
        /// This will replace tokens in the file with actual value (namespace, class name,...)
        /// </summary>
        /// <param name="source">Full path to template file</param>
        /// <param name="target">Full path to destination file</param>
        public override void AddFileFromTemplate(string source, string target)
        {
            if (!System.IO.File.Exists(source))
                throw new FileNotFoundException(String.Format("Template file not found: {0}", source));

            // We assume that there is no token inside the file because the only
            // way to add a new element should be through the template wizard that
            // take care of expanding and replacing the tokens.
            // The only task to perform is to copy the source file in the
            // target location.
            string targetFolder = Path.GetDirectoryName(target);
            if (!Directory.Exists(targetFolder))
            {
                Directory.CreateDirectory(targetFolder);
            }

            File.Copy(source, target);
        }
        /// <summary>
        /// Evaluates if a file is an FoxPro code file based on is extension
        /// </summary>
        /// <param name="strFileName">The filename to be evaluated</param>
        /// <returns>true if is a code file</returns>
        public override bool IsCodeFile(string strFileName)
        {
            // We do not want to assert here, just return silently.
            if (String.IsNullOrEmpty(strFileName))
            {
                return false;
            }
            return (String.Compare(Path.GetExtension(strFileName), ".py", StringComparison.OrdinalIgnoreCase) == 0);

        }

        /// <summary>
        /// Create a file node based on an msbuild item.
        /// </summary>
        /// <param name="item">The msbuild item to be analyzed</param>
        /// <returns>FoxProFileNode or FileNode</returns>
        public override FileNode CreateFileNode(ProjectElement item)
        {
            if (item == null)
            {
                throw new ArgumentNullException("item");
            }

            string include = item.GetMetadata(ProjectFileConstants.Include);
            FoxProFileNode newNode = new FoxProFileNode(this, item);
            newNode.OleServiceProvider.AddService(typeof(EnvDTE.Project), new OleServiceProvider.ServiceCreatorCallback(this.CreateServices), false);
            newNode.OleServiceProvider.AddService(typeof(EnvDTE.ProjectItem), newNode.ServiceCreator, false);
            newNode.OleServiceProvider.AddService(typeof(VSLangProj.VSProject), new OleServiceProvider.ServiceCreatorCallback(this.CreateServices), false);
            if (IsCodeFile(include))
            {
                newNode.OleServiceProvider.AddService(
                    typeof(SVSMDCodeDomProvider), new OleServiceProvider.ServiceCreatorCallback(this.CreateServices), false);
            }

            return newNode;
        }

        public override DependentFileNode CreateDependentFileNode(ProjectElement item)
        {
            DependentFileNode node = base.CreateDependentFileNode(item);
            if (null != node)
            {
                string include = item.GetMetadata(ProjectFileConstants.Include);
                if (IsCodeFile(include))
                {
                    node.OleServiceProvider.AddService(
                        typeof(SVSMDCodeDomProvider), new OleServiceProvider.ServiceCreatorCallback(this.CreateServices), false);
                }
            }

            return node;
        }

        /// <summary>
        /// Creates the format list for the open file dialog
        /// </summary>
        /// <param name="formatlist">The formatlist to return</param>
        /// <returns>Success</returns>
        public override int GetFormatList(out string formatlist)
        {
            formatlist = String.Format(CultureInfo.CurrentCulture, SR.GetString(SR.ProjectFileExtensionFilter), "\0", "\0");
            return VSConstants.S_OK;
        }

        /// <summary>
        /// This overrides the base class method to show the VS 2005 style Add reference dialog. The ProjectNode implementation
        /// shows the VS 2003 style Add Reference dialog.
        /// </summary>
        /// <returns>S_OK if succeeded. Failure other wise</returns>
        public override int AddProjectReference()
        {
            IVsComponentSelectorDlg2 componentDialog;
            Guid guidEmpty = Guid.Empty;
            VSCOMPONENTSELECTORTABINIT[] tabInit = new VSCOMPONENTSELECTORTABINIT[5];
            string strBrowseLocations = Path.GetDirectoryName(this.BaseURI.Uri.LocalPath);

            //Add the .NET page
            tabInit[0].dwSize = (uint)Marshal.SizeOf(typeof(VSCOMPONENTSELECTORTABINIT));
            tabInit[0].varTabInitInfo = 0;
            tabInit[0].guidTab = VSConstants.GUID_COMPlusPage;

            //Add the COM page
            tabInit[1].dwSize = (uint)Marshal.SizeOf(typeof(VSCOMPONENTSELECTORTABINIT));
            tabInit[1].varTabInitInfo = 0;
            tabInit[1].guidTab = VSConstants.GUID_COMClassicPage;

            //Add the Project page
            tabInit[2].dwSize = (uint)Marshal.SizeOf(typeof(VSCOMPONENTSELECTORTABINIT));
            // Tell the Add Reference dialog to call hierarchies GetProperty with the following
            // propID to enablefiltering out ourself from the Project to Project reference
            tabInit[2].varTabInitInfo = (int)__VSHPROPID.VSHPROPID_ShowProjInSolutionPage;
            tabInit[2].guidTab = VSConstants.GUID_SolutionPage;

            // Add the Browse page			
            tabInit[3].dwSize = (uint)Marshal.SizeOf(typeof(VSCOMPONENTSELECTORTABINIT));
            tabInit[3].guidTab = NativeMethods.GUID_BrowseFilePage;
            tabInit[3].varTabInitInfo = 0;

            //// Add the Recent page			
            tabInit[4].dwSize = (uint)Marshal.SizeOf(typeof(VSCOMPONENTSELECTORTABINIT));
            tabInit[4].guidTab = GUID_MruPage;
            tabInit[4].varTabInitInfo = 0;

            uint pX = 0, pY = 0;


            componentDialog = this.GetService(typeof(SVsComponentSelectorDlg)) as IVsComponentSelectorDlg2;
            try
            {
                // call the container to open the add reference dialog.
                if (componentDialog != null)
                {
                    // Let the project know not to show itself in the Add Project Reference Dialog page
                    this.ShowProjectInSolutionPage = false;

                    // call the container to open the add reference dialog.
                    ErrorHandler.ThrowOnFailure(componentDialog.ComponentSelectorDlg2(
                        (System.UInt32)(__VSCOMPSELFLAGS.VSCOMSEL_MultiSelectMode | __VSCOMPSELFLAGS.VSCOMSEL_IgnoreMachineName),
                        (IVsComponentUser)this,
                        0,
                        null,
                Microsoft.VisualStudio.Package.SR.GetString(Microsoft.VisualStudio.Package.SR.AddReferenceDialogTitle),   // Title
                        "VS.AddReference",						  // Help topic
                        ref pX,
                        ref pY,
                        (uint)tabInit.Length,
                        tabInit,
                        ref guidEmpty,
                        "*.dll",
                        ref strBrowseLocations));
                }
            }
            catch (COMException e)
            {
                Trace.WriteLine("Exception : " + e.Message);
                return e.ErrorCode;
            }
            finally
            {
                // Let the project know it can show itself in the Add Project Reference Dialog page
                this.ShowProjectInSolutionPage = true;
            }
            return VSConstants.S_OK;
        }

        protected override ConfigProvider CreateConfigProvider()
        {
            return new FoxProConfigProvider(this);
        }
        
        #endregion

        #region Methods
        /// <summary>
        /// Creates the services exposed by this project.
        /// </summary>
        private object CreateServices(Type serviceType)
        {
            object service = null;
            if (typeof(SVSMDCodeDomProvider) == serviceType)
            {
                service = this.CodeDomProvider;
            }
            else if (typeof(System.CodeDom.Compiler.CodeDomProvider) == serviceType)
            {
                service = this.CodeDomProvider.CodeDomProvider;
            }
            else if (typeof(DesignerContext) == serviceType)
            {
                service = this.DesignerContext;
            }
            else if (typeof(VSLangProj.VSProject) == serviceType)
            {
                service = this.VSProject;
            }
            else if (typeof(EnvDTE.Project) == serviceType)
            {
                service = this.GetAutomationObject();
            }
            return service;
        }
        #endregion
          
        #region IVsProjectSpecificEditorMap2 Members

        public int GetSpecificEditorProperty(string mkDocument, int propid, out object result)
        {
            // initialize output params
            result = null;

            //Validate input
            if (string.IsNullOrEmpty(mkDocument))
                throw new ArgumentException("Was null or empty", "mkDocument");

            // Make sure that the document moniker passed to us is part of this project
            // We also don't care if it is not a FoxPro file node
            uint itemid;
            ErrorHandler.ThrowOnFailure(ParseCanonicalName(mkDocument, out itemid));
            HierarchyNode hierNode = NodeFromItemId(itemid);
            if (hierNode == null || ((hierNode as FoxProFileNode) == null))
                return VSConstants.E_NOTIMPL;

            switch (propid)
            {
                case (int)__VSPSEPROPID.VSPSEPROPID_UseGlobalEditorByDefault:
                    // we do not want to use global editor for form files
                    result = true;
                    break;
                case (int)__VSPSEPROPID.VSPSEPROPID_ProjectDefaultEditorName:
                    result = "FoxPro Form Editor";
                    break;
            }

            return VSConstants.S_OK;
        }

        public int GetSpecificEditorType(string mkDocument, out Guid guidEditorType)
        {
            // Ideally we should at this point initalize a File extension to EditorFactory guid Map e.g.
            // in the registry hive so that more editors can be added without changing this part of the
            // code. FoxPro only makes usage of one Editor Factory and therefore we will return 
            // that guid
            guidEditorType = EditorFactory.guidEditorFactory;
            return VSConstants.S_OK;
        }

        public int GetSpecificLanguageService(string mkDocument, out Guid guidLanguageService)
        {
            guidLanguageService = Guid.Empty;
            return VSConstants.E_NOTIMPL;
        }

        public int SetSpecificEditorProperty(string mkDocument, int propid, object value)
        {
            return VSConstants.E_NOTIMPL;
        }

        #endregion

        #region static methods
        public static string GetOuputExtension(OutputType outputType)
        {
            if (outputType == OutputType.Library)
            {
                return "." + OutputFileExtension.dll.ToString();
            }
            else
            {
                return "." + OutputFileExtension.exe.ToString();
            }
        }
        #endregion
    }

    /// <summary>
    /// This class defines constants being used by the FoxPro Project File
    /// </summary>
    public static class FoxProProjectFileConstants
    {
        public const string MainFile = "MainFile";
    }
}
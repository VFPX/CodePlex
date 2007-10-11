﻿
using System;
using System.Diagnostics;
using System.Globalization;
using System.Runtime.InteropServices;
using System.ComponentModel.Design;
using Microsoft.Win32;
using Microsoft.VisualStudio.Shell.Interop;
using Microsoft.VisualStudio.OLE.Interop;
using Microsoft.VisualStudio.Shell;
using IOleServiceProvider = Microsoft.VisualStudio.OLE.Interop.IServiceProvider;
using VFPX.FoxProIntegration.FoxProInterfaces;
using FoxPro.Hosting;

namespace VFPX.FoxProIntegration.FoxProConsole
{
    /// <summary>
    /// This class implements the package responsible for the integration of the FoxPro
    /// console window in Visual Studio.
    /// There are two main aspects in this integration: the first one is to expose a service
    /// that will allow other packages to get a reference to the FoxPro engine used by
    /// the console or create a new one; the second part of the integration is the creation
    /// of the console as a Visual Studio tool window.
    /// </summary>
    // This attribute tells the registration utility (regpkg.exe) that this class needs
    // to be registered as package.
    [PackageRegistration(UseManagedResourcesOnly = true)]
    // A Visual Studio component can be registered under different registry roots; for instance
    // when you debug your package you want to register it in the experimental hive. This
    // attribute specifies the registry root to use if one was not provided to regpkg.exe with
    // the /root switch.
    [DefaultRegistryRoot("Software\\Microsoft\\VisualStudio\\9.0")]
    // This attribute is used to register the information needed to show this package
    // in the Help/About dialog of Visual Studio.
    [InstalledProductRegistration(false, "#100", "#102", "1.0", IconResourceID = 0)]
    // This attribute is used to register a Visual Studio service so that the shell will load
    // this package if another package is querying for this service.
    [ProvideService(typeof(IFoxProEngineProvider))]
    // Set the information needed for the shell to know about this tool window and to know
    // how to persist its data.
    [ProvideToolWindow(typeof(ConsoleWindow))]
    // With this attribute we notify the shell that we are defining some menu in the VSCT file.
    [ProvideMenuResource(1000, 1)]

    [ProvideLoadKey("standard", "1.0", "Visual Studio Integration of FoxPro Console Window", "Microsoft Corporation", 1)]
    // The GUID of the package.
    [Guid(GuidList.guidFoxProConsolePkgString)]
    public sealed class FoxProConsolePackage : Package
    {
        /// <summary>
        /// Default constructor of the package.
        /// Inside this method you can place any initialization code that does not require 
        /// any Visual Studio service, because at this point the package object is created but 
        /// not sited yet inside the Visual Studio environment. The place to do all the other 
        /// initialization is the Initialize method.
        /// </summary>
        public FoxProConsolePackage()
        {
            Trace.WriteLine(string.Format(CultureInfo.CurrentCulture, "Entering constructor for: {0}", this.ToString()));
            // This package has to proffer the FoxPro engine provider as a Visual Studio
            // service. Note that for performance reasons we don't actually create any object here,
            // but instead we register a callback function that will create the object the first
            // time this package will receive a request for the service.
            IServiceContainer container = this as IServiceContainer;
            ServiceCreatorCallback callback = new ServiceCreatorCallback(CreateService);
            container.AddService(typeof(IFoxProEngineProvider), callback, true);
        }

        /// <summary>
        /// Initialization function for the package.
        /// When this function is called, the package is sited, so it is possible to use the standard
        /// Visual Studio services.
        /// </summary>
        protected override void Initialize()
        {
            // Always call the base implementation of Initialize.
            base.Initialize();

            // Add our command handlers for menu (commands must exist in the .vsct file)
            OleMenuCommandService mcs = GetService(typeof(IMenuCommandService)) as OleMenuCommandService;
            if (null == mcs)
            {
                // If it is not possible to get the command service, then there is nothing to do.
                return;
            }

            // Create the command for the tool window
            CommandID toolwndCommandID = new CommandID(GuidList.guidFoxProConsoleCmdSet, (int)PkgCmdIDList.cmdidFoxProConsole);
            MenuCommand menuToolWin = new MenuCommand(new EventHandler(ShowConsole), toolwndCommandID);
            mcs.AddCommand(menuToolWin);
        }

        /// <summary>
        /// This function is called the first time the service container implemented by this package
        /// receives a request for one of the services added with AddService; the goal of this
        /// function is to create an instance of the requested service.
        /// </summary>
        private object CreateService(IServiceContainer container, Type serviceType)
        {
            if (serviceType == typeof(IFoxProEngineProvider))
            {
                // Get the service provider for this package.
                IOleServiceProvider serviceProvider = GetService(typeof(IOleServiceProvider)) as IOleServiceProvider;
                // Create the engine provider.
                return new FoxProEngineProvider(serviceProvider);
            }
            return null;
        }

        /// <summary>
        /// This function is called when the user clicks the menu item that shows the 
        /// console window. 
        /// </summary>
        private void ShowConsole(object sender, EventArgs e)
        {
            // FindToolWindow will search for this window and, because the 'create' flag
            // is set to true, will create a new instance if it can not find it.
            ToolWindowPane pane = this.FindToolWindow(typeof(ConsoleWindow), 0, true);
            if (null == pane)
            {
                throw new COMException(Resources.CanNotCreateConsole);
            }
            IVsWindowFrame frame = pane.Frame as IVsWindowFrame;
            if (null == frame)
            {
                throw new COMException(Resources.CanNotCreateConsole);
            }
            Microsoft.VisualStudio.ErrorHandler.ThrowOnFailure(frame.Show());
        }

    }
}
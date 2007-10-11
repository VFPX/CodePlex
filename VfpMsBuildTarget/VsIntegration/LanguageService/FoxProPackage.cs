
using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;

using System.ComponentModel.Design;
using Microsoft.VisualStudio.Package;
using Microsoft.VisualStudio.Shell;
using Microsoft.VisualStudio.Shell.Interop;
using Microsoft.VisualStudio.OLE.Interop;
using Microsoft.VisualStudio.TextManager.Interop;

namespace VFPX.FoxProIntegration.FoxProLanguageService {

    [PackageRegistration(UseManagedResourcesOnly = true)]
    [ProvideLoadKey(FoxProConstants.PLKMinEdition, FoxProConstants.PLKProductVersion, FoxProConstants.PLKProductName, FoxProConstants.PLKCompanyName, FoxProConstants.PLKResourceID)]
    [DefaultRegistryRoot("Software\\Microsoft\\VisualStudio\\9.0Exp")]
    [ProvideService(typeof(FoxProLanguage), ServiceName = "FoxPro")]
    [ProvideService(typeof(IFoxProLibraryManager))]
    [ProvideLanguageService(typeof(FoxProLanguage), "FoxPro", 100,
        CodeSense = true,
        DefaultToInsertSpaces = true,
        EnableCommenting = true,
        MatchBraces = true,
        ShowCompletion = true,
        ShowMatchingBrace = true)]
    [ProvideLanguageExtension(typeof(FoxProLanguage), FoxProConstants.FoxProFileExtension)]
    [ProvideIntellisenseProvider(typeof(FoxProIntellisenseProvider), "FoxProCodeProvider", "FoxPro", ".py", "FoxPro;FoxPro", "FoxPro")]
    [ProvideObject(typeof(FoxProIntellisenseProvider))]
    [Guid(FoxProConstants.packageGuidString)]
    [RegisterSnippetsAttribute(FoxProConstants.languageServiceGuidString, false, 131, "FoxPro", @"CodeSnippets\SnippetsIndex.xml", @"CodeSnippets\Snippets\", @"CodeSnippets\Snippets\")]
    public class FoxProPackage : Package, IOleComponent {
        private uint componentID;
        private FoxProLibraryManager libraryManager;

        public FoxProPackage() {
            IServiceContainer container = this as IServiceContainer;
            ServiceCreatorCallback callback = new ServiceCreatorCallback(CreateService);
            container.AddService(typeof(FoxProLanguage), callback, true);
            container.AddService(typeof(IFoxProLibraryManager), callback, true);
        }

        private void RegisterForIdleTime() {
            IOleComponentManager mgr = GetService(typeof(SOleComponentManager)) as IOleComponentManager;
            if (componentID == 0 && mgr != null) {
                OLECRINFO[] crinfo = new OLECRINFO[1];
                crinfo[0].cbSize = (uint)Marshal.SizeOf(typeof(OLECRINFO));
                crinfo[0].grfcrf = (uint)_OLECRF.olecrfNeedIdleTime |
                                              (uint)_OLECRF.olecrfNeedPeriodicIdleTime;
                crinfo[0].grfcadvf = (uint)_OLECADVF.olecadvfModal |
                                              (uint)_OLECADVF.olecadvfRedrawOff |
                                              (uint)_OLECADVF.olecadvfWarningsOff;
                crinfo[0].uIdleTimeInterval = 1000;
                int hr = mgr.FRegisterComponent(this, crinfo, out componentID);
            }
        }

        protected override void Dispose(bool disposing) {
            try {
                if (componentID != 0) {
                    IOleComponentManager mgr = GetService(typeof(SOleComponentManager)) as IOleComponentManager;
                    if (mgr != null) {
                        mgr.FRevokeComponent(componentID);
                    }
                    componentID = 0;
                }
                if (null != libraryManager) {
                    libraryManager.Dispose();
                    libraryManager = null;
                }
            } finally {
                base.Dispose(disposing);
            }
        }

        private object CreateService(IServiceContainer container, Type serviceType) {
            object service = null;
            if (typeof(FoxProLanguage) == serviceType) {
                FoxProLanguage language = new FoxProLanguage();
                language.SetSite(this);
                RegisterForIdleTime();
                service = language;
            } else if (typeof(IFoxProLibraryManager) == serviceType) {
                libraryManager = new FoxProLibraryManager(this);
                service = libraryManager as IFoxProLibraryManager;
            }
            return service;
        }

        #region IOleComponent Members

        public int FContinueMessageLoop(uint uReason, IntPtr pvLoopData, MSG[] pMsgPeeked) {
            return 1;
        }

        public int FDoIdle(uint grfidlef) {
            FoxProLanguage pl = GetService(typeof(FoxProLanguage)) as FoxProLanguage;
            if (pl != null) {
                pl.OnIdle((grfidlef & (uint)_OLEIDLEF.oleidlefPeriodic) != 0);
            }
            if (null != libraryManager) {
                libraryManager.OnIdle();
            }
            return 0;
        }

        public int FPreTranslateMessage(MSG[] pMsg) {
            return 0;
        }

        public int FQueryTerminate(int fPromptUser) {
            return 1;
        }

        public int FReserved1(uint dwReserved, uint message, IntPtr wParam, IntPtr lParam) {
            return 1;
        }

        public IntPtr HwndGetWindow(uint dwWhich, uint dwReserved) {
            return IntPtr.Zero;
        }

        public void OnActivationChange(IOleComponent pic, int fSameComponent, OLECRINFO[] pcrinfo, int fHostIsActivating, OLECHOSTINFO[] pchostinfo, uint dwReserved) {
        }

        public void OnAppActivate(int fActive, uint dwOtherThreadID) {
        }

        public void OnEnterState(uint uStateID, int fEnter) {
        }

        public void OnLoseActivation() {
        }

        public void Terminate() {
        }

        #endregion
    }
}

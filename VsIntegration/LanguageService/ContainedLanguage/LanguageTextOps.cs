using System;
using Microsoft.VisualStudio.TextManager.Interop;
using VSConstants = Microsoft.VisualStudio.VSConstants;

namespace VFPX.FoxProIntegration.FoxProLanguageService {
    /// <summary>
    /// The implementation of this interface is needed only to work around a bug in the
    /// HTML editor. If it is not implemented, then GetPairExtent does not work.
    /// Note that all the methods return E_NOTIMPL because the actual implementation
    /// of the interface is not important in this context.
    /// </summary>
    public partial class FoxProLanguage : IVsLanguageTextOps {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1033:InterfaceMethodsShouldBeCallableByChildTypes")]
        int IVsLanguageTextOps.Format(IVsTextLayer pTextLayer, TextSpan[] ptsSel) {
            return VSConstants.E_NOTIMPL;
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1033:InterfaceMethodsShouldBeCallableByChildTypes")]
        int IVsLanguageTextOps.GetDataTip(IVsTextLayer pTextLayer, TextSpan[] ptsSel, TextSpan[] ptsTip, out string pbstrText) {
            pbstrText = string.Empty;
            return VSConstants.E_NOTIMPL;
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1033:InterfaceMethodsShouldBeCallableByChildTypes")]
        int IVsLanguageTextOps.GetPairExtent(IVsTextLayer pTextLayer, TextAddress ta, TextSpan[] pts) {
            return VSConstants.E_NOTIMPL;
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1033:InterfaceMethodsShouldBeCallableByChildTypes")]
        int IVsLanguageTextOps.GetWordExtent(IVsTextLayer pTextLayer, TextAddress ta, WORDEXTFLAGS flags, TextSpan[] pts) {
            return VSConstants.E_NOTIMPL;
        }
    }
}

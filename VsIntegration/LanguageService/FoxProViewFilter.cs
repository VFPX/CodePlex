
using System;
using Microsoft.VisualStudio.Package;
using Microsoft.VisualStudio.TextManager.Interop;
using Microsoft.VisualStudio;
using Microsoft.VisualStudio.OLE.Interop;

namespace VFPX.FoxProIntegration.FoxProLanguageService {

    internal partial class FoxProViewFilter : ViewFilter {

        public FoxProViewFilter(CodeWindowManager mgr, IVsTextView view)
            : base(mgr, view) {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1031:DoNotCatchGeneralExceptionTypes")]
        public override void Dispose() {
            try {
                this.bufferCoordinator = null;
                base.Dispose();
            } catch(Exception) {
            }
        }

        protected override int QueryCommandStatus(ref Guid guidCmdGroup, uint nCmdId) {
            if (guidCmdGroup == VSConstants.VSStd2K) {
                if (nCmdId == (uint)VSConstants.VSStd2KCmdID.INSERTSNIPPET || 
                    nCmdId == (uint)VSConstants.VSStd2KCmdID.SURROUNDWITH) {
                    return (int)(OLECMDF.OLECMDF_SUPPORTED | OLECMDF.OLECMDF_ENABLED);
                }
            }

            return base.QueryCommandStatus(ref guidCmdGroup, nCmdId);
        }

        public override bool HandlePreExec(ref Guid guidCmdGroup, uint nCmdId, uint nCmdexecopt, IntPtr pvaIn, IntPtr pvaOut) {
            if (guidCmdGroup == VSConstants.VSStd2K) {
                if (nCmdId == (uint)VSConstants.VSStd2KCmdID.INSERTSNIPPET) {
                    ExpansionProvider ep = this.GetExpansionProvider();
                    if (this.TextView != null && ep != null) {
                        ep.DisplayExpansionBrowser(this.TextView, Resources.InsertSnippet, null, false, null, false);
                    }
                    return true;   // Handled the command.
                } else if (nCmdId == (uint)VSConstants.VSStd2KCmdID.SURROUNDWITH) {
                    ExpansionProvider ep = this.GetExpansionProvider();
                    if (this.TextView != null && ep != null) {
                        ep.DisplayExpansionBrowser(this.TextView, Resources.SurroundWith, null, false, null, false);
                    }
                    return true;   // Handled the command.
                }
            }

            // Base class handled the command.  Do nothing more here.
            return base.HandlePreExec(ref guidCmdGroup, nCmdId, nCmdexecopt, pvaIn, pvaOut);
        }

    }
}


using System;
using System.Windows.Forms;

using Microsoft.VisualStudio.Package;
using Microsoft.VisualStudio.TextManager.Interop;
using ErrorHandler = Microsoft.VisualStudio.ErrorHandler;

namespace VFPX.FoxProIntegration.FoxProLanguageService {
    internal sealed class FoxProCompletionSet : CompletionSet {
        internal TextViewWrapper view;

        internal FoxProCompletionSet(ImageList imageList, Source source) : base(imageList, source) {
        }

        public override void Init(IVsTextView textView, Declarations declarations, bool completeWord) {
            view = textView as TextViewWrapper;
            base.Init(textView, declarations, completeWord);
        }

        public override int GetInitialExtent(out int line, out int startIdx, out int endIdx) {
            int returnCode = base.GetInitialExtent(out line, out startIdx, out endIdx);
            if (ErrorHandler.Failed(returnCode) || (null == view)) {
                return returnCode;
            }

            TextSpan secondary = new TextSpan();
            secondary.iStartLine = secondary.iEndLine = line;
            secondary.iStartIndex = startIdx;
            secondary.iEndIndex = endIdx;

            TextSpan primary = view.GetPrimarySpan(secondary);
            line = primary.iStartLine;
            startIdx = primary.iStartIndex;
            endIdx = primary.iEndIndex;

            return returnCode;
        }
    }
}

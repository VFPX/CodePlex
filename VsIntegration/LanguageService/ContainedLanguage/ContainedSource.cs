
using System;
using Microsoft.VisualStudio.Package;
using Microsoft.VisualStudio.TextManager.Interop;

namespace VFPX.FoxProIntegration.FoxProLanguageService {
    public partial class FoxProSource {
        public override CompletionSet CreateCompletionSet() {
            return new FoxProCompletionSet(LanguageService.GetImageList(), this);
        }
    }
}

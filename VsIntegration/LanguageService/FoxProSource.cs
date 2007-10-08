
using System;

using Microsoft.VisualStudio.TextManager.Interop;
using Microsoft.VisualStudio.Package;

namespace VFPX.FoxProIntegration.FoxProLanguageService {
    public delegate AuthoringScope ScopeCreatorCallback(ParseRequest request);

    public partial class FoxProSource : Source {
        private ScopeCreatorCallback scopeCreator;

        public FoxProSource(LanguageService service, IVsTextLines textLines, Colorizer colorizer)
            : base(service, textLines, colorizer) {
        }

        public override CommentInfo GetCommentFormat() {
            CommentInfo ci = new CommentInfo();
            ci.UseLineComments = true;
            ci.LineStart = "#";
            return ci;
        }

        public ScopeCreatorCallback ScopeCreator {
            get { return scopeCreator; }
            set { scopeCreator = value; }
        }
    }
}

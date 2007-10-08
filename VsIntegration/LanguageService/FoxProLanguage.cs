
using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using System.Diagnostics;
using System.Security.Permissions;
using System.Runtime.InteropServices;

using Microsoft.VisualStudio.Package;
using Microsoft.VisualStudio.TextManager.Interop;
using Microsoft.VisualStudio.Shell;
using ErrorHandler = Microsoft.VisualStudio.ErrorHandler;
using VSConstants = Microsoft.VisualStudio.VSConstants;
using VFPX.FoxProIntegration.FoxProInference;
using FoxPro.Hosting;

namespace VFPX.FoxProIntegration.FoxProLanguageService {

    [Guid(FoxProConstants.languageServiceGuidString)]
    public partial class FoxProLanguage : LanguageService {
        LanguagePreferences preferences;
        FoxProScanner scanner;
        Modules modules = new Modules();
        private Dictionary<IVsTextView, FoxProSource> specialSources;

        // This array contains the definition of the colorable items provided by this
        // language service.
        // This specific language does not really need to provide colorable items because it
        // does not define any item different from the default ones, but the base class has
        // an empty implementation of IVsProvideColorableItems, so any language service that
        // derives from it must implement the methods of this interface, otherwise there are
        // errors when the shell loads an editor to show a file associated to this language.
        private static FoxProColorableItem[] colorableItems = {
            // The first 6 items in this list MUST be these default items.
            new FoxProColorableItem("Keyword", COLORINDEX.CI_BLUE, COLORINDEX.CI_USERTEXT_BK),
            new FoxProColorableItem("Comment", COLORINDEX.CI_DARKGREEN, COLORINDEX.CI_USERTEXT_BK),
            new FoxProColorableItem("Identifier", COLORINDEX.CI_SYSPLAINTEXT_FG, COLORINDEX.CI_USERTEXT_BK),
            new FoxProColorableItem("String", COLORINDEX.CI_MAROON, COLORINDEX.CI_USERTEXT_BK),
            new FoxProColorableItem("Number", COLORINDEX.CI_SYSPLAINTEXT_FG, COLORINDEX.CI_USERTEXT_BK),
            new FoxProColorableItem("Text", COLORINDEX.CI_SYSPLAINTEXT_FG, COLORINDEX.CI_USERTEXT_BK)
        };

        public FoxProLanguage() {
            specialSources = new Dictionary<IVsTextView, FoxProSource>();
        }

        public override void Dispose() {
            try {
                // Clear the special sources
                foreach(FoxProSource source in specialSources.Values) {
                    source.Dispose();
                }
                specialSources.Clear();

                // Dispose the preferences.
                if (null != preferences) {
                    preferences.Dispose();
                    preferences = null;
                }

                // Dispose the scanner.
                if (null != scanner) {
                    scanner.Dispose();
                    scanner = null;
                }
            }
            finally {
                base.Dispose();
            }
        }

        public void AddSpecialSource(FoxProSource source, IVsTextView view) {
            specialSources.Add(view, source);
        }

        public override string Name {
            get {
                return Resources.FoxPro;
            }
        }

        public override Source CreateSource(IVsTextLines buffer) {
            return new FoxProSource(this, buffer, new Colorizer(this, buffer, GetScanner(buffer)));
        }

        public override LanguagePreferences GetLanguagePreferences() {
            if (preferences == null) {
                preferences = new LanguagePreferences(
                    this.Site, typeof(FoxProLanguage).GUID, this.Name
                    );
                preferences.Init();
            }
            return preferences;
        }

        public override IScanner GetScanner(IVsTextLines buffer) {
            if (scanner == null) {
                scanner = new FoxProScanner();
            }
            return scanner;
        }

        public override AuthoringScope ParseSource(ParseRequest req) {
            if (null == req) {
                throw new ArgumentNullException("req");
            }
            Debug.Print("ParseSource at ({0}:{1}), reason {2}", req.Line, req.Col, req.Reason);
            FoxProSource source = null;
            if (specialSources.TryGetValue(req.View, out source) && (null != source.ScopeCreator)) {
                return source.ScopeCreator(req);
            }
            FoxProSink sink = new FoxProSink(req.Sink);
            return new FoxProScope(modules.AnalyzeModule(sink, req.FileName, req.Text), this);
        }

        public override string GetFormatFilterList() {
            return Resources.FoxProFormatFilter;
        }

        public override System.Windows.Forms.ImageList GetImageList() {
            System.Windows.Forms.ImageList il = base.GetImageList();
            return il;
        }

        public override int ValidateBreakpointLocation(IVsTextBuffer buffer, int line, int col, TextSpan[] pCodeSpan) {
            if (pCodeSpan != null) {
                pCodeSpan[0].iStartLine = line;
                pCodeSpan[0].iStartIndex = col;
                pCodeSpan[0].iEndLine = line;
                pCodeSpan[0].iEndIndex = col;
                if (buffer != null) {
                    int length;
                    buffer.GetLengthOfLine(line, out length);
                    pCodeSpan[0].iStartIndex = 0;
                    pCodeSpan[0].iEndIndex = length;
                }
                return Microsoft.VisualStudio.VSConstants.S_OK;
            } else {
                return Microsoft.VisualStudio.VSConstants.S_FALSE;
            }
        }

        public override void OnIdle(bool periodic) {
            Source src = GetSource(this.LastActiveTextView);
            if (src != null && src.LastParseTime == Int32.MaxValue) {
                src.LastParseTime = 0;
            }
            base.OnIdle(periodic);
        }

        // Implementation of IVsProvideColorableItems

        public override int GetItemCount(out int count) {
            count = colorableItems.Length;
            return Microsoft.VisualStudio.VSConstants.S_OK;
        }

        public override int GetColorableItem(int index, out IVsColorableItem item) {
            if (index < 1) {
                throw new ArgumentOutOfRangeException("index");
            }
            item = colorableItems[index - 1];
            return Microsoft.VisualStudio.VSConstants.S_OK;
        }

        private int classNameCounter = 0;

        public override ExpansionFunction CreateExpansionFunction(ExpansionProvider provider, string functionName) {
            ExpansionFunction function = null;
            if (functionName == "GetName") {
                ++classNameCounter;
                function = new FoxProGetNameExpansionFunction(provider, classNameCounter);
            }
            return function;
        }

        private List<VsExpansion> expansionsList;
        private List<VsExpansion> ExpansionsList {
            get {
                if (null != expansionsList) {
                    return expansionsList;
                }
                GetSnippets();
                return expansionsList;
            }
        }

        // Disable the "DoNotPassTypesByReference" warning.
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1045")]
        public void AddSnippets(ref FoxProDeclarations declarations) {
            if (null == this.ExpansionsList) {
                return;
            }
            foreach (VsExpansion expansionInfo in this.ExpansionsList) {
                declarations.AddDeclaration(new Declaration(expansionInfo));
            }
        }

        [System.Security.Permissions.SecurityPermission(SecurityAction.Demand, Flags = SecurityPermissionFlag.UnmanagedCode)]
        private void GetSnippets() {
            if (null == this.expansionsList) {
                this.expansionsList = new List<VsExpansion>();
            } else {
                this.expansionsList.Clear();
            }
            IVsTextManager2 textManager = Package.GetGlobalService(typeof(SVsTextManager)) as IVsTextManager2;
            if (textManager == null) {
                return;
            }
            SnippetsEnumerator enumerator = new SnippetsEnumerator(textManager, GetLanguageServiceGuid());
            foreach (VsExpansion expansion in enumerator) {
                if (!string.IsNullOrEmpty(expansion.shortcut)) {
                    this.expansionsList.Add(expansion);
                }
            }
        }

        public override ViewFilter CreateViewFilter(CodeWindowManager mgr, IVsTextView newView) {
            // This call makes sure debugging events can be received
            // by our view filter.
            base.GetIVsDebugger();
            return new FoxProViewFilter(mgr, newView);
        }

        internal class FoxProGetNameExpansionFunction : ExpansionFunction {
            private int nameCount;

            public FoxProGetNameExpansionFunction(ExpansionProvider provider, int counter)
                : base(provider) {
                nameCount = counter;
            }

            public override string GetCurrentValue() {
                string name = "MyClass";
                name += nameCount.ToString(System.Globalization.CultureInfo.InvariantCulture);
                return name;
            }
        }

    }
}

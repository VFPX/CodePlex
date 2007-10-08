
using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.VisualStudio.TextManager.Interop;

using Microsoft.VisualStudio.Package;
using VFPX.FoxProIntegration.FoxProInference;

namespace VFPX.FoxProIntegration.FoxProLanguageService {
    public class FoxProDeclarations : Declarations {
        List<Declaration> declarations;
        private LanguageService languageService;
        private TextSpan        commitSpan;

        public FoxProDeclarations(IList<Declaration> declarations, LanguageService langService)             
            : base() {
            this.declarations = new List<Declaration>(declarations);
            languageService = langService;
        }

        // Disable the "UsePropertiesWhereAppropriate" warning.
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1024")]
        public override int GetCount() {
            return declarations.Count;
        }

        public override string GetDisplayText(int index) {
            string title = "";
            if (index >= 0 && index < declarations.Count) {
                title = declarations[index].Title;
            }
            return title;
        }

        public override string GetName(int index) {
            string name = string.Empty;
            if (index >= 0 && index < declarations.Count) {
                Declaration item = declarations[index];
                if (item.Type == Declaration.DeclarationType.Snippet) {
                    name = declarations[index].Shortcut;
                } else {
                    name = item.Title;
                }
            }
            return name;
        }

        public override string GetDescription(int index) {
            string description = "";
            if (index >= 0 && index < declarations.Count) {
                description = declarations[index].Description;
            }
            return description;
        }

        public override int GetGlyph(int index) {
            int glyph = 0;
            //The following constants are the index of the various glyphs in the ressources of Microsoft.VisualStudio.Package.LanguageService.dll
            const int SnippetGlyph = 205;
            const int ClassGlyph = 0;
            const int FunctionGlyph = 72;
            if (index >= 0 && index < declarations.Count) {
                switch (declarations[index].Type) {
                    case Declaration.DeclarationType.Snippet:
                        glyph = SnippetGlyph;
                        break;
                    case Declaration.DeclarationType.Function:
                        glyph = FunctionGlyph;
                        break;
                    case Declaration.DeclarationType.Class:
                        glyph = ClassGlyph;
                        break;
                    default:
                        glyph = 0;
                        break;
                }
            }
            return glyph;
        }

        public void Sort() {
            declarations.Sort();
        }

        // This method is used to add declarations to the internal list.
        public void AddDeclaration(Declaration declaration) {
            declarations.Add(declaration);
        }

        // This method is called to get the string to commit to the source buffer.
        // Note that the initial extent is only what the user has typed so far.
        // Disable the "ParameterNamesShouldMatchBaseDeclaration" warning.
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1725")]
        public override string OnCommit(IVsTextView textView, string textSoFar, char commitCharacter, int index, ref TextSpan initialExtent) {
            // We intercept this call only to get the initial extent
            // of what was committed to the source buffer.
            commitSpan = initialExtent;

            return base.OnCommit(textView, textSoFar, commitCharacter, index, ref initialExtent);
        }

        // This method is called after the string has been committed to the source buffer.
        public override char OnAutoComplete(IVsTextView textView, string committedText, char commitCharacter, int index) {
            const char defaultReturnValue = '\0';
            Declaration item = declarations[index] as Declaration;
            if (item == null) {
                return defaultReturnValue;
            }
            // In this example, FoxProDeclaration identifies types with an enum.
            // You can choose a different approach.
            if (item.Type != Declaration.DeclarationType.Snippet) {
                return defaultReturnValue;
            }
            Source src = languageService.GetSource(textView);
            if (src == null) {
                return defaultReturnValue;
            }
            ExpansionProvider ep = src.GetExpansionProvider();
            if (ep == null) {
                return defaultReturnValue;
            }
            string title;
            string path;
            int commitLength = commitSpan.iEndIndex - commitSpan.iStartIndex;
            if (commitLength < committedText.Length) {
                // Replace everything that was inserted so calculate the span of the full
                // insertion, taking into account what was inserted when the commitSpan
                // was obtained in the first place.
                commitSpan.iEndIndex += (committedText.Length - commitLength);
            }

            if (ep.FindExpansionByShortcut(textView, committedText, commitSpan,
                                           true, out title, out path) >= 0) {
                ep.InsertNamedExpansion(textView, title, path, commitSpan, false);
            }
            return defaultReturnValue;
        }
    }
}

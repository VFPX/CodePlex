
using System;
using System.Collections.Generic;
using System.Text;

using Microsoft.VisualStudio;
using Microsoft.VisualStudio.Package;
using Microsoft.VisualStudio.TextManager.Interop;

using VFPX.FoxProIntegration.FoxProInference;

namespace VFPX.FoxProIntegration.FoxProLanguageService {
    class FoxProScope : AuthoringScope {
        Module module;
        LanguageService language;

        public FoxProScope(Module module, LanguageService language) {
            this.module = module;
            this.language = language;
        }

        public override string GetDataTipText(int line, int col, out TextSpan span) {
            span = new TextSpan();
            return null;
        }

        public override Declarations GetDeclarations(IVsTextView view, int line, int col, TokenInfo info, ParseReason reason) {
            System.Diagnostics.Debug.Print("GetDeclarations line({0}), col({1}), TokenInfo(type {2} at {3}-{4} triggers {5}), reason({6})",
                line, col, info.Type, info.StartIndex, info.EndIndex, info.Trigger, reason);

            IList<Declaration> declarations = module.GetAttributesAt(line + 1, info.StartIndex);
            FoxProDeclarations FoxProDeclarations = new FoxProDeclarations(declarations, language);
            
            //Show snippets according to current language context
            if (IsContextRightForSnippets(line, info)) {
                ((FoxProLanguage)language).AddSnippets(ref FoxProDeclarations);
            }

            //Sort statement completion items in alphabetical order
            FoxProDeclarations.Sort();
            return FoxProDeclarations;
        }

        private bool IsContextRightForSnippets(int line, TokenInfo info) {
            FoxPro.Compiler.Ast.Node node;
            Scope scope;
            module.Locate(line + 1, info.StartIndex, out node, out scope);
            bool contextOK = true;
            if (null != node) {
                if (node is FoxPro.Compiler.Ast.FieldExpression || node is FoxPro.Compiler.Ast.ConstantExpression) {
                    contextOK = false;
                }
            }
            return contextOK;
        }

        public override Methods GetMethods(int line, int col, string name) {
            System.Diagnostics.Debug.Print("GetMethods line({0}), col({1}), name({2})", line, col, name);

            IList<FunctionInfo> methods = module.GetMethodsAt(line + 1, col, name);
            return new FoxProMethods(methods);
        }

        public override string Goto(VSConstants.VSStd97CmdID cmd, IVsTextView textView, int line, int col, out TextSpan span) {
            span = new TextSpan();
            return null;
        }
    }
}

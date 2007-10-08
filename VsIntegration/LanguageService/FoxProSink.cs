using System;
using System.Collections.Generic;
using System.Diagnostics;

using FoxPro.Compiler;
using Hosting = FoxPro.Hosting;

using Microsoft.VisualStudio.Package;
using Microsoft.VisualStudio.TextManager.Interop;

namespace VFPX.FoxProIntegration.FoxProLanguageService {
    public class FoxProSink : FoxPro.Hosting.CompilerSink {
        AuthoringSink authoringSink;

        public FoxProSink(AuthoringSink authoringSink) {
            this.authoringSink = authoringSink;
        }

        private static TextSpan CodeToText(Hosting.CodeSpan code) {
            TextSpan span = new TextSpan();
            if (code.StartLine > 0) {
                span.iStartLine = code.StartLine - 1;
            }
            span.iStartIndex = code.StartColumn;
            if (code.EndLine > 0) {
                span.iEndLine = code.EndLine - 1;
            }
            span.iEndIndex = code.EndColumn;
            return span;
        }

        public override void AddError(string path, string message, string lineText, Hosting.CodeSpan location, int errorCode, Hosting.Severity severity) {
            TextSpan span = new TextSpan();
            if (location.StartLine > 0) {
                span.iStartLine = location.StartLine - 1;
            }
            span.iStartIndex = location.StartColumn;
            if (location.EndLine > 0) {
                span.iEndLine = location.EndLine - 1;
            }
            span.iEndIndex = location.EndColumn;
            authoringSink.AddError(path, message, span, Severity.Error);
        }

        public override void MatchPair(Hosting.CodeSpan span, Hosting.CodeSpan endContext, int priority) {
            authoringSink.MatchPair(CodeToText(span), CodeToText(endContext), priority);
        }

        public override void EndParameters(Hosting.CodeSpan span) {
            authoringSink.EndParameters(CodeToText(span));
        }

        public override void NextParameter(Hosting.CodeSpan span) {
            authoringSink.NextParameter(CodeToText(span));
        }

        public override void QualifyName(Hosting.CodeSpan selector, Hosting.CodeSpan span, string name) {
            authoringSink.QualifyName(CodeToText(selector), CodeToText(span), name);
        }

        public override void StartName(Hosting.CodeSpan span, string name) {
            authoringSink.StartName(CodeToText(span), name);
        }

        public override void StartParameters(Hosting.CodeSpan span) {
            authoringSink.StartParameters(CodeToText(span));
        }
    }
}

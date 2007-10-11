using System;
using System.Collections.Generic;
using System.Diagnostics;

using SystemState = FoxPro.Runtime.SystemState;
using FoxPro.Compiler;
using Microsoft.VisualStudio.Package;

namespace VFPX.FoxProIntegration.FoxProLanguageService {
    public class FoxProScanner : IScanner, IDisposable {
        private SystemState systemState = new SystemState();
        private Tokenizer tokenizer;

        [Flags]
        enum StringState {
            IncompleteString = 1,
            RawString = 2,
            LongString = 4,
            SingleQuote = 8,
            UnicodeString = 16,
            Max = IncompleteString | RawString | LongString | SingleQuote | UnicodeString
        }

        public void Dispose() {
            Dispose(true);
        }

        private void Dispose(bool disposing) {
            if (disposing) {
                if (null != systemState) {
                    systemState.Dispose();
                    systemState = null;
                }
            }
            GC.SuppressFinalize(this);
        }

        #region IScanner Members

        public bool ScanTokenAndProvideInfoAboutIt(TokenInfo tokenInfo, ref int state) {
            Token token = null;

            if (tokenizer.IsEndOfFile) return false;

            switch (state) {
                case 0:
                    token = tokenizer.Next();
                    break;

                default:
                    if (state <= (int)StringState.Max) {
                        StringState strState = (StringState)state;
                        token = tokenizer.ContinueString(
                            (strState & StringState.SingleQuote) != 0 ? '\'' : '"',
                            (strState & StringState.RawString) != 0,
                            (strState & StringState.UnicodeString) != 0,
                            (strState & StringState.LongString) != 0
                            );
                    }
                    break;
            }

            state = 0;

            tokenInfo.Trigger = TokenTriggers.None;

            switch (token.Kind) {
                case TokenKind.Error:
                case TokenKind.NewLine:
                    goto default;

                case TokenKind.Indent:
                case TokenKind.Dedent:
                    tokenInfo.Trigger = TokenTriggers.MatchBraces;
                    goto default;

                case TokenKind.Comment:
                    tokenInfo.Type = TokenType.LineComment;
                    tokenInfo.Color = TokenColor.Comment;
                    break;
                
                case TokenKind.Dot:
                    tokenInfo.Trigger = TokenTriggers.MemberSelect;
                    goto case TokenKind.Assign;

                case TokenKind.LeftParenthesis:
                    tokenInfo.Trigger = TokenTriggers.MatchBraces | TokenTriggers.ParameterStart;
                    goto case TokenKind.Assign;

                case TokenKind.RightParenthesis:
                    tokenInfo.Trigger = TokenTriggers.MatchBraces | TokenTriggers.ParameterEnd;
                    goto case TokenKind.Assign;

                case TokenKind.LeftBracket:
                    tokenInfo.Trigger = TokenTriggers.MatchBraces;
                    goto case TokenKind.Assign;

                case TokenKind.RightBracket:
                    tokenInfo.Trigger = TokenTriggers.MatchBraces;
                    goto case TokenKind.Assign;
                case TokenKind.LeftBrace:
                    tokenInfo.Trigger = TokenTriggers.MatchBraces;
                    goto case TokenKind.Assign;
                case TokenKind.RightBrace:
                    tokenInfo.Trigger = TokenTriggers.MatchBraces;
                    goto case TokenKind.Assign;
                case TokenKind.Comma:
                    tokenInfo.Trigger = TokenTriggers.ParameterNext;
                    goto case TokenKind.Assign;
                case TokenKind.Colon:
                case TokenKind.BackQuote:
                case TokenKind.Semicolon:
                case TokenKind.Assign:
                case TokenKind.Twiddle:
                case TokenKind.LessThanGreaterThan:
                    tokenInfo.Type = TokenType.Delimiter;
                    tokenInfo.Color = TokenColor.Text;
                    break;

                case TokenKind.Add:
                case TokenKind.AddEqual:
                case TokenKind.Subtract:
                case TokenKind.SubtractEqual:
                case TokenKind.Power:
                case TokenKind.PowerEqual:
                case TokenKind.Multiply:
                case TokenKind.MultiplyEqual:
                case TokenKind.FloorDivide:
                case TokenKind.FloorDivideEqual:
                case TokenKind.Divide:
                case TokenKind.DivEqual:
                case TokenKind.Mod:
                case TokenKind.ModEqual:
                case TokenKind.LeftShift:
                case TokenKind.LeftShiftEqual:
                case TokenKind.RightShift:
                case TokenKind.RightShiftEqual:
                case TokenKind.BitwiseAnd:
                case TokenKind.BitwiseAndEqual:
                case TokenKind.BitwiseOr:
                case TokenKind.BitwiseOrEqual:
                case TokenKind.Xor:
                case TokenKind.XorEqual:
                case TokenKind.LessThan:
                case TokenKind.GreaterThan:
                case TokenKind.LessThanOrEqual:
                case TokenKind.GreaterThanOrEqual:
                case TokenKind.Equal:
                case TokenKind.NotEqual:
                    tokenInfo.Type = TokenType.Operator;
                    tokenInfo.Color = TokenColor.Text;
                    break;

                case TokenKind.KeywordAnd:
                case TokenKind.KeywordAssert:
                case TokenKind.KeywordBreak:
                case TokenKind.KeywordClass:
                case TokenKind.KeywordContinue:
                case TokenKind.KeywordDef:
                case TokenKind.KeywordDel:
                case TokenKind.KeywordElseIf:
                case TokenKind.KeywordElse:
                case TokenKind.KeywordExcept:
                case TokenKind.KeywordExec:
                case TokenKind.KeywordFinally:
                case TokenKind.KeywordFor:
                case TokenKind.KeywordFrom:
                case TokenKind.KeywordGlobal:
                case TokenKind.KeywordIf:
                case TokenKind.KeywordImport:
                case TokenKind.KeywordIn:
                case TokenKind.KeywordIs:
                case TokenKind.KeywordLambda:
                case TokenKind.KeywordNot:
                case TokenKind.KeywordOr:
                case TokenKind.KeywordPass:
                case TokenKind.KeywordPrint:
                case TokenKind.KeywordRaise:
                case TokenKind.KeywordReturn:
                case TokenKind.KeywordTry:
                case TokenKind.KeywordWhile:
                case TokenKind.KeywordYield:
                    tokenInfo.Type = TokenType.Keyword;
                    tokenInfo.Color = TokenColor.Keyword;
                    break;

                case TokenKind.Name:
                    tokenInfo.Type = TokenType.Identifier;
                    tokenInfo.Color = TokenColor.Identifier;
                    // To show the statement completion for the current name we have to
                    // set the MemberSelect trigger on the token, but we don't want to do
                    // it too often to avoid to show the completion window also after the
                    // user dismiss it, so we set the trigger only if the name is 1 char long
                    // that is close enough to the condition that the user has just started
                    // to type the name.
                    if (tokenizer.EndLocation.Column <= tokenizer.StartLocation.Column + 1) {
                        tokenInfo.Trigger = TokenTriggers.MemberSelect;
                    }
                    break;

                case TokenKind.Constant:
                    ConstantValueToken ctoken = (ConstantValueToken)token;
                    if (ctoken.Constant is string) {
                        tokenInfo.Type = TokenType.String;
                        tokenInfo.Color = TokenColor.String;
                    } else {
                        tokenInfo.Type = TokenType.Literal;
                        tokenInfo.Color = TokenColor.Number;
                    }
                    IncompleteStringToken ist = ctoken as IncompleteStringToken;
                    if (ist != null) {
                        StringState strState = StringState.IncompleteString;
                        if (ist.IsRaw) strState |= StringState.RawString;
                        if (ist.IsUnicode) strState |= StringState.UnicodeString;
                        if (ist.IsTripleQuoted) strState |= StringState.LongString;
                        if (ist.IsSingleTickQuote) strState |= StringState.SingleQuote;
                        state = (int)strState;
                    }
                    break;

                default:
                    tokenInfo.Type = TokenType.Unknown;
                    tokenInfo.Color = TokenColor.Text;
                    return false;
            }

            tokenInfo.StartIndex = tokenizer.StartLocation.Column;
            tokenInfo.EndIndex = tokenizer.EndLocation.Column> tokenizer.StartLocation.Column ? tokenizer.EndLocation.Column - 1 : tokenizer.EndLocation.Column;

            return true;
        }

        public void SetSource(string source, int offset) {
            tokenizer = new Tokenizer(source.ToCharArray(offset, source.Length - offset), true, systemState,
                new CompilerContext("", new VFPX.FoxProIntegration.FoxProInference.QuietCompilerSink()));
        }

        #endregion
    }
}

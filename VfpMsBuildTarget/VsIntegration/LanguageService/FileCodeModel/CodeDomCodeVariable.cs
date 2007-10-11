using System;
using System.CodeDom;
using System.CodeDom.Compiler;
using System.Diagnostics.CodeAnalysis;
using System.Runtime.InteropServices;
using EnvDTE;

namespace VFPX.FoxProIntegration.CodeDomCodeModel {

    [ComVisible(true)]
    [SuppressMessage("Microsoft.Interoperability", "CA1409:ComVisibleTypesShouldBeCreatable")]
    [SuppressMessage("Microsoft.Interoperability", "CA1405:ComVisibleTypeBaseTypesShouldBeComVisible")]
    public class CodeDomCodeVariable : CodeDomCodeElement<CodeMemberField>, CodeVariable {
        private CodeElement parent;

        [SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "0#dte")]
        public CodeDomCodeVariable(DTE dte, CodeElement parent, string name, CodeTypeRef type, vsCMAccess access)
            : base(dte, name) {
            CodeObject = new CodeMemberField(CodeDomCodeTypeRef.ToCodeTypeReference(type), name);
            CodeObject.Attributes = VSAccessToMemberAccess(access);
            CodeObject.UserData[CodeKey] = this;
            this.parent = parent;
        }

        public CodeDomCodeVariable(CodeElement parent, CodeMemberField field)
            : base((null==parent) ? null : parent.DTE, (null==field) ? null : field.Name) {
            this.parent = parent;
            CodeObject = field;
        }

        #region CodeVariable Members

        public override CodeElements Children {
            get { throw new NotImplementedException(); }
        }

        public override CodeElements Collection {
            get { return parent.Children; }
        }

        public override ProjectItem ProjectItem {
            get { return parent.ProjectItem; }
        }

        public vsCMAccess Access {
            get { return MemberAccessToVSAccess(CodeObject.Attributes); }
            [SuppressMessage("Microsoft.Naming", "CA1725:ParameterNamesShouldMatchBaseDeclaration", MessageId = "0#")]
            set { 
                CodeObject.Attributes = VSAccessToMemberAccess(value);

                CommitChanges();
            }
        }

        public CodeAttribute AddAttribute(string Name, string Value, object Position) {
            CodeAttribute res =  AddCustomAttribute(CodeObject.CustomAttributes, Name, Value, Position);
            
            CommitChanges();
            
            return res;
        }

        public CodeElements Attributes {
            get { return GetCustomAttributes(CodeObject.CustomAttributes); }
        }

        public string Comment {
            get {
                return GetComment(CodeObject.Comments, false);
            }
            [SuppressMessage("Microsoft.Naming", "CA1725:ParameterNamesShouldMatchBaseDeclaration", MessageId = "0#")]
            set {
                ReplaceComment(CodeObject.Comments, value, false);

                CommitChanges();
            }
        }

        public string DocComment {
            get {
                return GetComment(CodeObject.Comments, true);
            }
            [SuppressMessage("Microsoft.Naming", "CA1725:ParameterNamesShouldMatchBaseDeclaration", MessageId = "0#")]
            set {
                ReplaceComment(CodeObject.Comments, value, true);

                CommitChanges();
            }
        }

        public object InitExpression {
            get {
                if (CodeObject.InitExpression != null) {
                    return ((CodeSnippetExpression)CodeObject.InitExpression).Value;
                }
                return null;
            }
            [SuppressMessage("Microsoft.Naming", "CA1725:ParameterNamesShouldMatchBaseDeclaration", MessageId = "0#")]
            set {
                string strVal = value as string;
                if (strVal != null) {
                    CodeObject.InitExpression = new CodeSnippetExpression(strVal);

                    CommitChanges();

                    return;
                }
                throw new ArgumentException(VFPX.FoxProIntegration.FoxProLanguageService.Resources.CodeModelVariableExpressionNotString);
            }
        }

        public bool IsConstant {
            get {
                return (CodeObject.Attributes & MemberAttributes.Const) != 0;
            }
            [SuppressMessage("Microsoft.Naming", "CA1725:ParameterNamesShouldMatchBaseDeclaration", MessageId = "0#")]
            set {
                if (value) CodeObject.Attributes |= MemberAttributes.Const;
                else CodeObject.Attributes &= ~MemberAttributes.Const;

                CommitChanges();
            }
        }

        public bool IsShared {
            get {
                return (CodeObject.Attributes & MemberAttributes.Static) != 0;
            }
            [SuppressMessage("Microsoft.Naming", "CA1725:ParameterNamesShouldMatchBaseDeclaration", MessageId = "0#")]
            set {
                if (value) CodeObject.Attributes |= MemberAttributes.Static;
                else CodeObject.Attributes &= ~MemberAttributes.Static;

                CommitChanges();
            }
        }

        public object Parent {
            get { return parent; }
        }

        public CodeTypeRef Type {
            get {
                return CodeDomCodeTypeRef.FromCodeTypeReference(CodeObject.Type);
            }
            [SuppressMessage("Microsoft.Naming", "CA1725:ParameterNamesShouldMatchBaseDeclaration", MessageId = "0#")]
            set {
                CodeObject.Type = CodeDomCodeTypeRef.ToCodeTypeReference(value);

                CommitChanges();
            }
        }

        public string get_Prototype(int Flags) {
            throw new NotImplementedException();
        }

        #endregion

        public override object ParentElement {
            get { return parent; }
        }

        public override string FullName {
            get { return CodeObject.Name; }
        }

        public override vsCMElement Kind {
            get {
                return vsCMElement.vsCMElementVariable;
            }
        }

    }

}

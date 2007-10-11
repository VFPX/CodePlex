
using System;
using System.Collections.Generic;
using System.Text;

using SystemState = FoxPro.Runtime.SystemState;
using FoxPro.Hosting;
using FoxPro.Compiler;
using FoxPro.Compiler.Ast;
using FoxPro.Runtime;

namespace VFPX.FoxProIntegration.FoxProInference {
    public class ScopeNode {
        private List<ScopeNode> nested;

		public IList<ScopeNode> NestedScopes {
			get { return nested; }
		}

        public virtual string Name {
            get { return ""; }
        }

        public virtual string Doc {
            get { return ""; }
        }

        public virtual Location Start {
            get {
                return Location.None;
            }
        }
        public virtual Location End {
            get {
                return Location.None;
            }
        }

        public void Add(ScopeNode node) {
            if (nested == null) nested = new List<ScopeNode>();
            nested.Add(node);
        }
    }

    public class ClassNode : ScopeNode {
        private FoxPro.Compiler.Ast.ClassDefinition cls;
        public ClassNode(FoxPro.Compiler.Ast.ClassDefinition cls) {
            this.cls = cls;
        }

        public override string Name {
            get {
                if (cls.Name == SymbolTable.Empty) {
                    return "";
                }
                return cls.Name.GetString();
            }
        }
        public override string Doc {
            get {
                return cls.Documentation;
            }
        }
        public override Location Start {
            get {
                return cls.Start;
            }
        }
        public override Location End {
            get {
                return cls.End;
            }
        }
    }

    public class FunctionNode : ScopeNode {
        private FoxPro.Compiler.Ast.FunctionDefinition func;
        public FunctionNode(FoxPro.Compiler.Ast.FunctionDefinition functionDefinition) {
			this.func = functionDefinition;
        }
        public override string Name {
            get {
                if (func.Name == SymbolTable.Empty) {
                    return "";
                }
                return func.Name.GetString();
            }
        }
        public override string Doc {
            get {
                return func.Documentation;
            }
        }
        public override Location Start {
            get {
                return func.Start;
            }
        }
        public override Location End {
            get {
                return func.End;
            }
        }
    }

    public class ScopeWalker : AstWalker {
        private static SystemState state = new SystemState();

        public static ScopeNode GetScopesFromFile(string file) {
            CompilerContext context = new CompilerContext(file, new QuietCompilerSink());
            Parser parser = Parser.FromFile(state, context);
            Statement Statement = parser.ParseFileInput();
            ScopeWalker walker = new ScopeWalker();
            return walker.WalkScopes(Statement);
        }
        public static ScopeNode GetScopesFromText(string text) {
            CompilerContext context = new CompilerContext("<input>", new QuietCompilerSink());
            Parser parser = Parser.FromString(state, context, text);
            Statement Statement = parser.ParseFileInput();
            ScopeWalker walker = new ScopeWalker();
            return walker.WalkScopes(Statement);
        }

        private ScopeNode root = new ScopeNode();
        private Stack<ScopeNode> scopes = new Stack<ScopeNode>();

        private ScopeNode WalkScopes(Statement Statement) {
            Statement.Walk(this);
            return root;
        }

        private void AddNode(ScopeNode node) {
            if (scopes.Count > 0) {
                ScopeNode current = scopes.Peek();
                current.Add(node);
            } else {
                root.Add(node);
            }

            scopes.Push(node);
        }

        #region IAstWalker Members
        public override void PostWalk(FoxPro.Compiler.Ast.FunctionDefinition node) {
            scopes.Pop();
        }

        public override void PostWalk(FoxPro.Compiler.Ast.ClassDefinition node) {
            scopes.Pop();
        }

        public override bool Walk(FoxPro.Compiler.Ast.FunctionDefinition node) {
            FunctionNode functionNode = new FunctionNode(node);
            AddNode(functionNode);
            return true;
        }

        public override bool Walk(FoxPro.Compiler.Ast.ClassDefinition node) {
            ClassNode classNode = new ClassNode(node);
            AddNode(classNode);
            return true;
        }
        #endregion
    }
}

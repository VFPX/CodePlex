
using System;
using System.Diagnostics.CodeAnalysis;
using EnvDTE;

namespace VFPX.FoxProIntegration.CodeDomCodeModel {
    [System.Runtime.InteropServices.ComVisible(true)]
    [SuppressMessage("Microsoft.Interoperability", "CA1409:ComVisibleTypesShouldBeCreatable")]
    public sealed class FoxProProjectCodeModel : CodeModel {
        private Project projectItem;
        internal FoxProProjectCodeModel(Project project) {
            this.projectItem = project;
        }

        #region CodeModel interface
        public CodeAttribute AddAttribute(string Name, object Location, string Value, object Position) {
            throw new NotImplementedException();
        }
        public CodeClass AddClass(string Name, object Location, object Position, object Bases, object ImplementedInterfaces, vsCMAccess Access) {
            throw new NotImplementedException();
        }
        public CodeDelegate AddDelegate(string Name, object Location, object Type, object Position, vsCMAccess Access) {
            throw new NotImplementedException();
        }
        public CodeEnum AddEnum(string Name, object Location, object Position, object Bases, vsCMAccess Access) {
            throw new NotImplementedException();
        }
        public CodeFunction AddFunction(string Name, object Location, vsCMFunction Kind, object Type, object Position, vsCMAccess Access) {
            throw new NotImplementedException();
        }
        public CodeInterface AddInterface(string Name, object Location, object Position, object Bases, vsCMAccess Access) {
            throw new NotImplementedException();
        }
        public CodeNamespace AddNamespace(string Name, object Location, object Position) {
            throw new NotImplementedException();
        }
        public CodeStruct AddStruct(string Name, object Location, object Position, object Bases, object ImplementedInterfaces, vsCMAccess Access) {
            throw new NotImplementedException();
        }
        public CodeVariable AddVariable(string Name, object Location, object Type, object Position, vsCMAccess Access) {
            throw new NotImplementedException();
        }
        public CodeType CodeTypeFromFullName(string Name) {
            throw new NotImplementedException();
        }
        public CodeTypeRef CreateCodeTypeRef(object Type) {
            throw new NotImplementedException();
        }
        public bool IsValidID(string Name) {
            throw new NotImplementedException();
        }
        public void Remove(object Element) {
            throw new NotImplementedException();
        }
        public CodeElements CodeElements {
            get { throw new NotImplementedException(); }
        }
        public DTE DTE {
            get {
                return projectItem.DTE;
            }
        }
        public bool IsCaseSensitive {
            get { return true; }
        }
        public string Language {
            get { return VFPX.FoxProIntegration.FoxProLanguageService.FoxProConstants.FoxProCodeDomProviderName; }
        }
        public Project Parent {
            get { return projectItem; }
        }
        #endregion
    }
}

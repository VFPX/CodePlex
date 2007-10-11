
using System;
using System.Collections.Generic;
using System.Text;
using VFPX.FoxProIntegration.FoxProInference;

using Microsoft.VisualStudio.Package;

namespace VFPX.FoxProIntegration.FoxProLanguageService {
    class FoxProMethods : Methods {
        private IList<FunctionInfo> methods;

        public FoxProMethods(IList<FunctionInfo> methods) {
            this.methods = methods;
        }

        public override int GetCount() {
            return methods != null ? methods.Count : 0;
        }

        public override string GetDescription(int index) {
            return methods != null && 0 <= index && index < methods.Count ? methods[index].Description : "";
        }

        public override string GetType(int index) {
            return methods != null && 0 <= index && index < methods.Count ? methods[index].Type : "";
        }

        public override int GetParameterCount(int index) {
            return methods != null && 0 <= index && index < methods.Count ? methods[index].ParameterCount : 0;
        }

        public override void GetParameterInfo(int index, int parameter, out string name, out string display, out string description) {
            if (methods != null && 0 <= index && index < methods.Count) {
                methods[index].GetParameterInfo(parameter, out name, out display, out description);
            } else {
                name = display = description = string.Empty;
            }
        }

        public override string GetName(int index) {
            return methods != null && 0 <= index && index < methods.Count ? methods[index].Name : "";
        }
    }
}

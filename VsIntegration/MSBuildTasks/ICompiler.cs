
using System;
using System.Collections.Generic;
using System.Reflection;
using System.Reflection.Emit;
using System.Text;

namespace VFPX.FoxProIntegration.FoxProTasks
{
	/// <summary>
	/// This exposes the same methods and properties
	/// as the actual engine, but gives us a good
	/// way to replace it with a mock object when
	/// unit testing.
	/// </summary>
	public interface ICompiler
	{
		IList<string> SourceFiles {get; set;}
		
        string OutputAssembly {get; set;}
		
        IList<string> ReferencedAssemblies {get; set;}
		
        IList<FoxPro.Hosting.ResourceFile> ResourceFiles { get; set; }
		
        string MainFile { get; set;}
		
        PEFileKinds TargetKind {get; set;}
		
        bool IncludeDebugInformation {get; set;}

		void Compile();
	}
}



using System;
using System.Collections.Generic;
using System.Text;

namespace VFPX.FoxProIntegration.FoxProTasks
{
	/// <summary>
	/// The main purpose of this class is to associate the FoxProCompiler
	/// class with the ICompiler interface.
	/// </summary>
	public class Compiler : FoxPro.Hosting.FoxProCompiler, ICompiler
	{
		public Compiler(IList<string> sourcesFiles, string OutputAssembly)
			: base(sourcesFiles, OutputAssembly)
		{
		}

		public Compiler(IList<string> sourcesFiles, string OutputAssembly, FoxPro.Hosting.CompilerSink compilerSink)
			: base(sourcesFiles, OutputAssembly, compilerSink)
		{
		}
	}
}

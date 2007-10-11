
using System;
using System.IO;
using System.Collections.Generic;
using System.Globalization;
using System.Reflection;
using Microsoft.Build.Utilities;
using Microsoft.Build.Framework;
using VFPX.FoxProIntegration.FoxProTasks.Properties;

namespace VFPX.FoxProIntegration.FoxProTasks
{
	public class FoxProCompilerTask : Task
	{
		private ICompiler compiler = null;

		#region Constructors

		/// <summary>
		/// Constructor. This is the constructor that will be used
		/// when the task runs.
		/// </summary>
		public FoxProCompilerTask()
		{
		}

		/// <summary>
		/// Constructor. The goal of this constructor is to make
		/// it easy to test the task.
		/// </summary>
		public FoxProCompilerTask(ICompiler compilerToUse)
		{
			compiler = compilerToUse;
		}

		#endregion

		#region Public Properties and related Fields

		private string[] sourceFiles;
		/// <summary>
		/// List of FoxPro source files that should be compiled into the assembly
		/// </summary>
		[Required()]
		public string[] SourceFiles
		{
			get { return sourceFiles; }
			set { sourceFiles = value; }
		}

		private string outputBinary;
		/// <summary>
		/// Output Assembly (including extension)
		/// </summary>
		[Required()]
		public string OutputBinary
		{
			get { return outputBinary; }
			set { outputBinary = value; }
		}

		private ITaskItem[] referencedBinaries = new ITaskItem[0];
		/// <summary>
		/// List of dependent binaries (fll, dll)
		/// </summary>
		public ITaskItem[] ReferencedBinaries
		{
			get { return referencedBinaries; }
			set
			{
				if (value != null)
				{
					referencedBinaries = value;
				}
				else
				{
					referencedBinaries = new ITaskItem[0];
				}

			}
		}

		private string mainFile;
		/// <summary>
		/// For applications, which file is the entry point
		/// </summary>
		[Required()]
		public string MainFile
		{
			get { return mainFile; }
			set { mainFile = value; }
		}

		private string targetKind;
		/// <summary>
		/// Target type (exe, dll)
		/// </summary>
		public string TargetKind
		{
			get { return targetKind; }
			set { targetKind = value.ToLower(CultureInfo.InvariantCulture); }
		}
		private bool debugSymbols = true;
		/// <summary>
		/// Generate debug information
		/// </summary>
		public bool DebugSymbols
		{
			get { return debugSymbols; }
			set { debugSymbols = value; }
		}
		private string projectPath = null;
		/// <summary>
		/// This should be set to $(MSBuildProjectDirectory)
		/// </summary>
		public string ProjectPath
		{
			get { return projectPath; }
			set { projectPath = value; }
		}

		private bool useExperimentalCompiler;
		/// <summary>
		/// This property is only needed because FoxPro does not officially support building real .Net assemblies.
		/// For WAP scenarios, we need to support real assemblies and as such we use an alternate approach to build those assemblies.
		/// </summary>
		public bool UseExperimentalCompiler
		{
			get { return useExperimentalCompiler; }
			set { useExperimentalCompiler = value; }
		}
	
		#endregion

		/// <summary>
		/// Main entry point for the task
		/// </summary>
		/// <returns></returns>
		public override bool Execute()
		{
			Log.LogMessage(MessageImportance.Normal, "FoxPro Compilation Task");

			// Create the compiler if it does not already exist
			CompilerErrorSink errorSink = new CompilerErrorSink(this.Log);

			errorSink.ProjectDirectory = ProjectPath;

			if (compiler == null)
			{
				if (UseExperimentalCompiler)
					compiler = new ExperimentalCompiler(new List<string>(this.SourceFiles), this.OutputBinary, errorSink);
				else
					compiler = new Compiler(new List<string>(this.SourceFiles), this.OutputBinary, errorSink);
			}

			if (!InitializeCompiler())
				return false;

			// Call the compiler and report errors and warnings
			compiler.Compile();

			return errorSink.BuildSucceeded;
		}

		/// <summary>
		/// Initialize compiler options based on task parameters
		/// </summary>
		/// <returns>false if failed</returns>
		private bool InitializeCompiler()
		{
			switch (TargetKind)
			{
				case "exe":
					{
            compiler.TargetKind = TargetKind;
						break;
					}
				case "dll":
					{
            compiler.TargetKind = TargetKind;
						break;
					}
				default:
					{
						this.Log.LogError(Resources.InvalidTargetType, TargetKind);
						return false;
					}
			}
			compiler.IncludeDebugInformation = this.DebugSymbols;

			compiler.MainFile = this.MainFile;

			compiler.SourceFiles = new List<string>(this.SourceFiles);

			// References require a bit more work since our compiler expects us to pass the Assemblies (and not just paths)
			compiler.ReferencedBinaries = new List<string>();

			foreach (ITaskItem assemblyReference in this.ReferencedBinaries)
			{
				compiler.ReferencedBinaries.Add(assemblyReference.ItemSpec);
			}
			return true;
		}
	}
}
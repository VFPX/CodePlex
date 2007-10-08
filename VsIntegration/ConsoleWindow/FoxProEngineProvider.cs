
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

using IOleServiceProvider = Microsoft.VisualStudio.OLE.Interop.IServiceProvider;
using ServiceProvider = Microsoft.VisualStudio.Shell.ServiceProvider;

using VFPX.FoxProIntegration.FoxProInterfaces;
using FoxPro.Hosting;
using FoxPro.Runtime;

namespace VFPX.FoxProIntegration.FoxProConsole
{
    /// <summary>
    /// Wrapper around the FoxPro engine to implement the IEngine interface.
    /// </summary>
    internal class EngineWrapper : IEngine
    {
        private FoxProEngine engine;
        private System.IO.Stream stdOut;
        private System.IO.Stream stdErr;
        private System.IO.Stream stdIn;

        public EngineWrapper()
        {
            engine = new FoxProEngine();
        }

        public string Copyright
        {
            get { return FoxProEngine.Copyright; }
        }

        public object Evaluate(string expression)
        {
            return engine.Evaluate(expression);
        }

        public void Execute(string text)
        {
            engine.Execute(text);
        }

        public void ExecuteFile(string fileName)
        {
            engine.ExecuteFile(fileName);
        }

        // This method have to catch general exception because the engine
        // can throw any kind of exception and we want to print the error
        // message on the standard error stream.
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1031:DoNotCatchGeneralExceptionTypes")]
        public void ExecuteToConsole(string text)
        {
            string errorMessage = null;
            try
            {
                engine.ExecuteToConsole(text);
            }
            catch (Exception e)
            {
                errorMessage = e.Message;
            }

            if (!string.IsNullOrEmpty(errorMessage))
            {
                System.IO.Stream stream = StdErr;
                if (null == stream)
                {
                    stream = StdOut;
                }
                if (null != stream)
                {
                    using (System.IO.StreamWriter writer = new System.IO.StreamWriter(stream))
                    {
                        writer.WriteLine(errorMessage);
                    }
                }
            }
        }

        public object GetVariable(string name)
        {
            return null;
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1031:DoNotCatchGeneralExceptionTypes")]
        public bool ParseInteractiveInput(string text, bool allowIncompleteStatement)
        {
            try
            {
                return engine.ParseInteractiveInput(text, allowIncompleteStatement);
            }
            catch (Exception)
            {
                // In case of exception we want to let the engine process the current statement so that
                // it can print an error message on the standard error stream.
                return true;
            }
        }

        public FoxProEngine FoxProEngine
        {
            get { return engine; }
        }

        public int RunInteractive()
        {
            return 0;
        }

        public void SetVariable(string name, object value)
        {
            IDictionary<string, object> globals = engine.DefaultModule.Globals;
            globals.Add(name, value);
        }

        public System.IO.Stream StdErr
        {
            get { return stdErr; }
            set 
            {
                stdErr = value;
                engine.SetStandardError(stdErr); 
            }
        }
        public System.IO.Stream StdIn
        {
            get { return stdIn; }
            set 
            {
                stdIn = value;
                engine.SetStandardInput(stdIn);
            }
        }
        public System.IO.Stream StdOut
        {
            get { return stdOut; }
            set 
            {
                stdOut = value;
                engine.SetStandardOutput(stdOut);
            }
        }

        public Version Version
        {
            get { return FoxProEngine.Version; }
        }
    }

    /// <summary>
    /// Implementation of the engine provider service.
    /// This object is responsible to handle the instances of the FoxPro engine.
    /// </summary>
    internal class FoxProEngineProvider : IFoxProEngineProvider
    {
        private EngineWrapper engine;
        private ServiceProvider serviceProvider;

        public FoxProEngineProvider(IOleServiceProvider serviceProvider)
        {
            if (null != serviceProvider)
            {
                this.serviceProvider = new ServiceProvider(serviceProvider);
            }
        }

        /// <summary>
        /// Returns a reference to a shared instance of the engine. This instance is the
        /// same that is used by the console window.
        /// </summary>
        public IEngine GetSharedEngine()
        {
            if (null == engine)
            {
                engine = CreateSharedEngine();
            }

            return engine;
        }

        /// <summary>
        /// Create a new instance of the FoxPro engine.
        /// </summary>
        public IEngine CreateNewEngine()
        {
            return new EngineWrapper();
        }

        private EngineWrapper CreateSharedEngine()
        {
            // Create the engine wrapper.
            EngineWrapper wrapper = new EngineWrapper();

            // Set the default variables for the shared engine.
            if (null != serviceProvider)
            {
                EnvDTE._DTE dte = (EnvDTE._DTE)serviceProvider.GetService(typeof(EnvDTE.DTE));
                wrapper.SetVariable("dte", dte);
            }
            wrapper.SetVariable("engine", wrapper.FoxProEngine);

            return wrapper;
        }
    }
}

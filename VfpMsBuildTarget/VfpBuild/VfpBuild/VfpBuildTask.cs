using System;
using Microsoft.Build.Utilities;

namespace VfpBuild
{
  public class VfpBuildTask : Task
  {
    private string _buildPath = "";
    private string _buildTime = "";
    private string _outputFileName = "";
    private string _vfpProjectName = "";
    private string _vsProject = "";
    private int _buildAction = 0;

    public int BuildAction
    {
      get { return _buildAction; }
      set { _buildAction = value; }
    }

    public string BuildPath
    {
      get { return this._buildPath; }
      set { this._buildPath = value; }
    }

    public string BuildTime
    {
      get { return this._buildTime; }
      set { this._buildTime = value; }
    }

    public string OutputFileName
    {
      get { return this._outputFileName; }
      set { this._outputFileName = value; }
    }

    public string VfpProjectName
    {
      get { return this._vfpProjectName; }
      set { this._vfpProjectName = value; }
    }

    public string VSProject
    {
      get { return this._vsProject; }
      set { this._vsProject = value; }
    }

    public override bool Execute()
    {
      projectbuilder.VfpProjectBuilderClass vfpBuilder = new projectbuilder.VfpProjectBuilderClass();

      this.Log.LogMessage("Setting Properties", new object[0]);
      
      this.Log.LogMessage("Building " + this._vfpProjectName + " as " + this._outputFileName, new object[0]);

      if (!vfpBuilder.BuildProject(_vfpProjectName, _outputFileName, _buildAction, _vsProject, _buildTime, _buildPath))
      {
        this.Log.LogError(vfpBuilder.cErrorMessage);
      }
      else if (vfpBuilder.cWarningMessage.Length > 0)
      {
        this.Log.LogWarning(vfpBuilder.cWarningMessage);
      }
     
      return true;
    }
  }
}



using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using Microsoft.VisualStudio;
using Microsoft.VisualStudio.Package;
using Microsoft.VisualStudio.Shell;
using Microsoft.VisualStudio.Shell.Interop;

namespace VFPX.FoxProIntegration.FoxProProject
{
    /// <summary>
    /// Updates the FoxPro project property called MainFile 
    /// </summary>
	class ProjectDocumentsListenerForMainFileUpdates : ProjectDocumentsListener
    {
        #region fields
        /// <summary>
        /// The FoxPro project who adviced for TrackProjectDocumentsEvents
        /// </summary>
        private FoxProProjectNode project;
        #endregion

        #region ctors
        public ProjectDocumentsListenerForMainFileUpdates(ServiceProvider serviceProvider, FoxProProjectNode project)
            : base(serviceProvider)
        {
            this.project = project;
        }
        #endregion

        #region overriden methods
        public override int OnAfterRenameFiles(int cProjects, int cFiles, IVsProject[] projects, int[] firstIndices, string[] oldFileNames, string[] newFileNames, VSRENAMEFILEFLAGS[] flags)
        {
            //Get the current value of the MainFile Property
            string currentMainFile = this.project.GetProjectProperty(FoxProProjectFileConstants.MainFile, true);
            string fullPathToMainFile = Path.Combine(Path.GetDirectoryName(this.project.BaseURI.Uri.LocalPath), currentMainFile);

            //Investigate all of the oldFileNames if they belong to the current project and if they are equal to the current MainFile
            int index = 0;
            foreach (string oldfile in oldFileNames)
            {
                //Compare this project with the project that the old file belongs to
                IVsProject belongsToProject = projects[firstIndices[index]];
                if (Utilities.IsSameComObject(belongsToProject,this.project))
                {
                    //Compare the files and update the MainFile Property if the currentMainFile is an old file
                    if (NativeMethods.IsSamePath(oldfile, fullPathToMainFile))
                    {
                        //Get the newfilename and update the MainFile property
                        string newfilename = newFileNames[index];
                        FoxProFileNode node = this.project.FindChild(newfilename) as FoxProFileNode;
                        if (node == null)
                            throw new InvalidOperationException("Could not find the FoxProFileNode object");
                        this.project.SetProjectProperty(FoxProProjectFileConstants.MainFile, node.GetRelativePath());
                        break;
                    }
                }

                index++;
            }

            return VSConstants.S_OK;
        }

        public override int OnAfterRemoveFiles(int cProjects, int cFiles, IVsProject[] projects, int[] firstIndices, string[] oldFileNames, VSREMOVEFILEFLAGS[] flags)
        {
            //Get the current value of the MainFile Property
            string currentMainFile = this.project.GetProjectProperty(FoxProProjectFileConstants.MainFile, true);
            string fullPathToMainFile = Path.Combine(Path.GetDirectoryName(this.project.BaseURI.Uri.LocalPath), currentMainFile);

            //Investigate all of the oldFileNames if they belong to the current project and if they are equal to the current MainFile
            int index = 0;
            foreach (string oldfile in oldFileNames)
            {
                //Compare this project with the project that the old file belongs to
                IVsProject belongsToProject = projects[firstIndices[index]];
                if (Utilities.IsSameComObject(belongsToProject, this.project))
                {
                    //Compare the files and update the MainFile Property if the currentMainFile is an old file
                    if (NativeMethods.IsSamePath(oldfile, fullPathToMainFile))
                    {
                        //Get the first available py file in the project and update the MainFile property
                        List<FoxProFileNode> FoxProFileNodes = new List<FoxProFileNode>();
                        this.project.FindNodesOfType<FoxProFileNode>(FoxProFileNodes);
                        string newMainFile = string.Empty;
                        if (FoxProFileNodes.Count > 0)
                        {
                            newMainFile = FoxProFileNodes[0].GetRelativePath();
                        }
                        this.project.SetProjectProperty(FoxProProjectFileConstants.MainFile, newMainFile);
                        break;
                    }
                }

                index++;
            }
            
            return VSConstants.S_OK;
        }

        public override int OnAfterAddFilesEx(int cProjects, int cFiles, IVsProject[] projects, int[] firstIndices, string[] newFileNames, VSADDFILEFLAGS[] flags)
        {
            //Get the current value of the MainFile Property
            string currentMainFile = this.project.GetProjectProperty(FoxProProjectFileConstants.MainFile, true);
            if (!string.IsNullOrEmpty(currentMainFile))
                //No need for further operation since MainFile is already set
                return VSConstants.S_OK;

            string fullPathToMainFile = Path.Combine(Path.GetDirectoryName(this.project.BaseURI.Uri.LocalPath), currentMainFile);

            //Investigate all of the newFileNames if they belong to the current project and set the first FoxProFileNode found equal to MainFile
            int index = 0;
            foreach (string newfile in newFileNames)
            {
                //Compare this project with the project that the new file belongs to
                IVsProject belongsToProject = projects[firstIndices[index]];
                if (Utilities.IsSameComObject(belongsToProject, this.project))
                {
                    //If the newfile is a FoxPro filenode we willl map this file to the MainFile property
                    FoxProFileNode filenode = project.FindChild(newfile) as FoxProFileNode;
                    if (filenode != null)
                    {
                        this.project.SetProjectProperty(FoxProProjectFileConstants.MainFile, filenode.GetRelativePath());
                        break;
                    }
                }

                index++;
            }

            return VSConstants.S_OK;
        }
        #endregion

    }
}

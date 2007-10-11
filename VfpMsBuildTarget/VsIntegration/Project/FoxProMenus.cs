
using System;
using System.ComponentModel.Design;

namespace VFPX.FoxProIntegration.FoxProProject
{
    /// <summary>
    /// CommandIDs matching the commands defined items from PkgCmdID.h and guids.h
    /// </summary>
    public sealed class FoxProMenus
    {
        internal static readonly Guid guidFoxProProjectCmdSet = new Guid("{22EBFCA0-A97A-4ad3-AC19-77BEC7E8C0EB}");
        internal static readonly CommandID SetAsMain = new CommandID(guidFoxProProjectCmdSet, 0x3001);
    }
}


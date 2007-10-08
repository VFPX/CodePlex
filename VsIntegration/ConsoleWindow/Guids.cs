
// Guids.cs
// MUST match guids.h
using System;

namespace VFPX.FoxProIntegration.FoxProConsole
{
    public static class GuidList
    {
        public const string guidFoxProConsolePkgString =    "068980a2-def8-4422-adc4-76af7a935e7e";
        public const string guidFoxProConsoleCmdSetString = "aba8cb4c-73e3-4a11-8cde-9501d0a2ab9e";

        public static readonly Guid guidFoxProConsolePkg = new Guid(guidFoxProConsolePkgString);
        public static readonly Guid guidFoxProConsoleCmdSet = new Guid(guidFoxProConsoleCmdSetString);
    };
}
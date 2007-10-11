/***************************************************************************

Copyright (c) Microsoft Corporation. All rights reserved.
This code is licensed under the Visual Studio SDK license terms.
THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF
ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY
IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR
PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.

***************************************************************************/

using System;

namespace Microsoft.VisualStudio.Package 
{

	public class VsMenus
	{
		// menu command guids.
		public static Guid guidStandardCommandSet97 = new Guid("5efc7975-14bc-11cf-9b2b-00aa00573819");
		public static Guid guidStandardCommandSet2K = new Guid("1496A755-94DE-11D0-8C3F-00C04FC2AAE2");
		public static Guid guidVsVbaPkg = new Guid(0xa659f1b3, 0xad34, 0x11d1, 0xab, 0xad, 0x0, 0x80, 0xc7, 0xb8, 0x9c, 0x95);
		public static Guid guidSHLMainMenu = new Guid(0xd309f791, 0x903f, 0x11d0, 0x9e, 0xfc, 0x00, 0xa0, 0xc9, 0x11, 0x00, 0x4f);
		public static Guid guidVSUISet = new Guid("60481700-078b-11d1-aaf8-00a0c9055a90");
		public static Guid guidCciSet = new Guid("2805D6BD-47A8-4944-8002-4e29b9ac2269");
		public static Guid guidVsUIHierarchyWindowCmds = new Guid("60481700-078B-11D1-AAF8-00A0C9055A90");
		// Special Menus.
		public const int IDM_VS_CTXT_CODEWIN = 0x040D;
		public const int IDM_VS_CTXT_ITEMNODE = 0x0430;
		public const int IDM_VS_CTXT_PROJNODE = 0x0402;
		public const int IDM_VS_CTXT_REFERENCEROOT = 0x0450;
		public const int IDM_VS_CTXT_REFERENCE = 0x0451;
		public const int IDM_VS_CTXT_FOLDERNODE = 0x0431;
		public const int IDM_VS_CTXT_NOCOMMANDS = 0x041A;
		public const int VSCmdOptQueryParameterList = 1;
		public const int IDM_VS_CTXT_XPROJ_MULTIITEM = 0x0419;
		public const int IDM_VS_CTXT_XPROJ_PROJITEM = 0x0417;
	}
}

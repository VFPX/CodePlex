Directory: 		..\XBASESLM\WIZAPP

Author: 		John Alden
emailname:		v-johnal
Creation Date:	11/4/94


Description:	This is the main project directory for WIZARD.APP and BUILDER.APP.

Files:			BUILDER.PJX/.PJT  - Builder project files
				WIZARD.PJX/.PJT   - Wizard project files
				
				WBPICK.VCX/.VCT	  - Class library for wizard/builder picklists and certain error dialogs
				
				WB.H			  - Common header file for both .apps

				WBMAIN.PRG		  - Main program library, common to both .apps. This is what locates/builds the 
									registration tables, updates FOXUSER for preferences, and does other housekeeping 
									chores for both wizard.app and builder.app. It reads the reg table, offers a
									picklist if necessary, calls the wizard or builder either as an app or by creating
									an object, responds to certain key parameters, passes along any other params to the
									individual wizard or builder, and can return a value to the calling program (e.g.,
									the Project Manager).
				WIZARD.PRG		  -	Main program in wizard.app
				BUILDER.PRG		  -	Main program in builder.app
				WBGRID.PRG		  - Used by builders, to dynamically create a grid with code for resize and
									double-click events at the column level. This is handled this way because certain 
									builders offer grids in which users may dynamically add additional columns. These
									new columns, created at runtime, need to inherit common code for resize/dblclick 
									events, so the grid and any columns are defined via this .prg.
				DUMMY.PRG		  - Dummy program to prevent certain errors when building projects
				
				WREGTBL.DBF/.FPT  - Wizard registration table template. The default reg table is built from this; it
									has an additional field (PLATFORM) in anticipation of future support for  other 
									platforms.
				BREGTBL.DBF/.FPT  - Same as above, but for builders.
				
									
									
				
				BLDLIST.H	}
				BLDCOMBO.H	} header files for individual builders
				BLDFORM.H	}
				
				CMBBDCMB.BMP }
				CMBBDLST.BMP } bitmap files for individual builders
				FRMBHZ1.BMP  }
				FRMBVT1.BMP  }
				
Dependencies:	..\WIZAPP\BUILDER.PJX/.PJT - builder project files; BUILDER.APP is built from these
				..\WZCOMMON\WIZCTRL.VCX    - common wizard/builder control class library
				..\WZFORM\WIZSTYLES.VCX    - form builder styles library
				
Distribution:	The files here are embedded into BUILDER.APP and will not be distributed to target machines.


Class listing:	WBPICK.VCX
--------------	-----------
		Class:	WBPick
  Description:	Picklist for wizards and builders.

		Class:  WBLocate
  Description:	Dialog handling case of missing reg table. The required custom prompts for
  				the commandbuttons (Locate/Create/Cancel), so we couldn't use MessageBox().


Directory: 		..\XBASESLM\BUILDERS

Author: 		John Alden
emailname:		v-johnal
Creation Date:	11/4/94


Description:	This is the primary source directory for the builders. 

Files:			BUILDER.VCX/.VCT - main source library for builders
				
				BLDLIST.H	}
				BLDCOMBO.H	} header files for individual builders
				BLDFORM.H	}
				BLDCMD.H	}
				
				CMBBDCMB.BMP }
				CMBBDLST.BMP } bitmap files for individual builders
				FRMBHZ1.BMP  }
				FRMBVT1.BMP  }
				
Dependencies:	..\WIZAPP\BUILDER.PJX/.PJT - builder project files; BUILDER.APP is built from these
				..\WZCOMMON\WIZCTRL.VCX    - common wizard/builder control class library
				..\WZFORM\WIZSTYLES.VCX    - form builder styles library
				
Distribution:	The files here are embedded into BUILDER.APP and will not be distributed to target machines.


Class listing:	BUILDER.VCX
--------------	-----------
		Class:	BuilderTemplate
  Description:	Underlying template for builder forms, analogous to WizardTemplate class for wizards.

		Class:  ListBoxBuilder
  Description:	List box builder class. Builder.app creates an instance of this to run the list box builder. 
  				This is a subclass of BuilderTemplate.

		Class:	ComboBoxBuilder
  Description:	Combo box builder class. This is a subclass of ListBoxBuilder.
		
		Class:	CommandBuilder
  Description:	Command Button Group builder class.
  				This is a subclass of BuilderTemplate.

		Class:	GridTextButton
  Description:	Container for custom control for column 2 of grid in Commandbuilder, page 1.
  				Contains a textbox and a commandbutton.

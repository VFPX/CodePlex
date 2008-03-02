* COV_DLGS.H
* Constants for components in use by Coverage app

*&* Messagebox:
#DEFINE COV_STOP_MESSAGEBOX                     16,COV_DIALOG_CAPTION_LOC+" "+COV_PROBLEM_LOC
#DEFINE COV_INFO_MESSAGEBOX                     64,COV_DIALOG_CAPTION_LOC+" "+COV_INFO_LOC
#DEFINE COV_YESNOCANCEL_MESSAGEBOX              32+3,COV_DIALOG_CAPTION_LOC
#DEFINE COV_WARNING_YESNO_MESSAGEBOX            48+4,COV_DIALOG_CAPTION_LOC
#DEFINE IDYES                                   6
#DEFINE IDNO                                    7
#DEFINE IDCANCEL                                2 


*&* common dialog classes in use:

#DEFINE COV_COMMON_FILE_DIALOG_CLASS            "scov_CommonFileDialog"
#DEFINE COV_COMMON_DIALOG_CLASS                 "scov_CommonDialog"

#DEFINE cdlScaleModePixels                      3

*&* common dialog flag constants and results for getfont:
#DEFINE cdlCFScreenFonts                        0x1
* Screen fonts supported by the system only
#DEFINE cdlCFANSIOnly                           0x400
* Specifies that the dialog box allows only a selection of the fonts that use the Windows character set. 
* If this flag is set, the user won't be able to select a font that contains only symbols.
#DEFINE cdlCFForceFontExist                     0x10000
* Specifies that an error message box is displayed if the user attempts to select a font or style that doesn't exist.
#DEFINE cdlCFNoStyleSel	                        0x100000
* No style
#DEFINE cdlCFFixedPitchOnly	                    0x4000	
* Specifies that the dialog box selects only fixed-pitch fonts

*&* common dialog constants for getfile/putfile:
#DEFINE cdlOFNPathMustExist                     0x800	
* User can enter only valid path names.
#DEFINE cdlOFNNoChangeDir                       0x8
* Sets the current directory to what it was when the dialog box was invoked.
#DEFINE cdlOFNHideReadOnly                      0x4
* Hide readonly checkbox
#DEFINE cdlOFNExplorer                          0x80000	
* Use Explorer dialog template

*&* addtl common dialog constant for getfile/reads:
#DEFINE cdlOFNFileMustExist                     0x1000	
* User can enter only names of existing files.

*&* addtl common dialog constants for putfile/writes:
#DEFINE cdlOFNOverwritePrompt                   0x2
* User must confirm whether to overwrite the file.
#DEFINE cdlOFNNoReadOnlyReturn                  0x8000
* File can't be Read Only and can't be in a write-protected dir.



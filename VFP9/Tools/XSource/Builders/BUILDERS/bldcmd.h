* Header file for Command Button Group builder

#DEFINE PG1LBL1_LOC			"You may specify a caption, a graphic, or both for your command group. To make a button blank, leave the cell empty."
#DEFINE PG2LBL1_LOC			"How do you want your command group to look?"
#DEFINE PG3LBL1_LOC			"Do you want to store the command group's value in a table or view?"

#DEFINE PG3LBL2_LOC			"Do you want sample code added to the Click event of this command group?"

#DEFINE PG2LBL3_LOC			"S\<pacing between buttons" + CHR(13) + CHR(10)
#DEFINE PG2LBL3A_LOC		"(in pixels):"
#DEFINE PG2LBL3B_LOC		"(in foxels):"

#DEFINE OPENTBLERR_LOC		"Error opening table: "

#DEFINE CLICKCOMMENT1_LOC	"** The following sample code will execute when the user clicks a button in this group."
#DEFINE CLICKCMD1_LOC		'= MESSAGEBOX("You clicked: " + THIS.Buttons[THIS.Value].Caption + ".")'

#DEFINE GETFILEBMP_LOC		"Select Picture:"
#DEFINE OK_LOC				"OK"

#DEFINE C_REMOVEBTN_LOC		"Removing buttons will also remove any code stored in the buttons's methods. " + ;
							"This cannot be undone. Continue?"
							
#DEFINE MB_YESNO                4       && Yes and No buttons
#DEFINE MB_DEFBUTTON2           256     && Second button is default

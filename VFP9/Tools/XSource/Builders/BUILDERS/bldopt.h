* Header file for Option Group builder

#DEFINE PG1LBL1_LOC			"You may specify a caption or graphic, or both (Graphical option). To make the button blank, leave the cell empty."
#DEFINE PG2LBL1_LOC			"How do you want your option group to look?"
#DEFINE PG3LBL1_LOC			"If you want to store the option group's value in a table or view, type the field or select"+CHR(13)+"it from the list."

#DEFINE PG3LBL2_LOC			"Do you want sample code added to the Click event of this option group?"

#DEFINE PG2LBL3_LOC			"Spacing Between Buttons" + CHR(13) + CHR(10)
#DEFINE PG2LBL3A_LOC		"(in pixels):"
#DEFINE PG2LBL3B_LOC		"(in foxels):"

#DEFINE OPENTBLERR_LOC		"Error opening table: "

#DEFINE CLICKCOMMENT1_LOC	"** The following sample code will execute when the user chooses an option in this group."
#DEFINE CLICKCMD1_LOC		'= MESSAGEBOX("You chose: " + THIS.Buttons[THIS.Value].Caption + ".")'

#DEFINE GETFILEBMP_LOC		"Select Picture:"
#DEFINE SELECTTABLE_LOC		"Select a table:"

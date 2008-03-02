***** Dropdown list selector
#define CRET		CHR(13)

#define STEP1_LOC	"Step 1 - Select Fields"
#define STEP2_LOC	"Step 2 - Define Layout"
#define STEP3_LOC	"Step 3 - Add Summary Information"
#define STEP4_LOC	"Step 4 - Finish"

* Help IDs
#define wizCrosstab_Wizard_Step4	95825000
#define wizCrosstab_Wizard_Step3	95825511
#define wizCrosstab_Wizard_Step2	95825510
#define wizCrosstab_Wizard_Step1	95825509
#define wizCrosstab_Wizard			95825508


***** Screen directions
#define DESC1a_LOC	"Which fields do you want in your cross-tab query?"
#define DESC1d_LOC	"Select a database or Free Tables item, select a table or view, and then select the fields you want."
#define DESC1		DESC1a_LOC+CRET+CRET+DESC1d_LOC

#define DESC2a_LOC	"How do you want to lay out your cross-tab query?"
#define DESC2b_LOC	"Drag available fields to the cross-tab locations."
#define DESC2		DESC2a_LOC+CRET+CRET+DESC2b_LOC

#define DESC3a_LOC	"Do you want to add a subtotal column to your data?"
#define DESC3b_LOC	"Select the type of total you want for each row."
#define DESC3		DESC3a_LOC+CRET+CRET+DESC3b_LOC

***** Screen hint button text
#define HINT1_LOC	""
#define HINT2_LOC	""
#define HINT3_LOC	""
#define HINT4_LOC	""

***** Screen BMP files
#define BMPFILE1	"opentabl.bmp"
#define BMPFILE2	"pivot2.bmp"
#define BMPFILE3	"crostab3.bmp"

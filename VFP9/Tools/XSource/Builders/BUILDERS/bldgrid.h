* Header file for Grid builder

#DEFINE PG1LBL1_LOC			"Which fields do you want in your grid?" + CHR(13) + CHR(10) + ;
							"Select a database or free table, and then select fields from one table."
#DEFINE PG2LBL1_LOC			"Select a style for your grid.  Each style is illustrated in the example grid shown."
#DEFINE PG3LBL1_LOC			"To specify a caption and control type for a column, first click the column, then specify"+ ;
							CHR(13)+CHR(10)+"your changes."
#DEFINE PG4LBL1_LOC			"To create a one-to-many form, specify the key field in the parent table and the related"+ ;
							CHR(13)+CHR(10)+"index for the child table in the grid."

#DEFINE COLUMN_LOC			"Column "
#DEFINE NODATA_LOC			"Data is not available for display. " + chr(13) + chr(10)
#DEFINE NODATA1A_LOC		NODATA_LOC + 'A table has not yet been selected on the "Grid Items" tab.'
#DEFINE NODATA1B_LOC		NODATA_LOC + 'Fields have not yet been selected on the "Grid Items" tab.'
#DEFINE NODATA1C_LOC		NODATA_LOC + 'There are no records in: '

#DEFINE GRIDHEAD1_LOC		"North"
#DEFINE GRIDHEAD2_LOC		"East"
#DEFINE GRIDHEAD3_LOC		"West"
#DEFINE GRIDHEAD4_LOC		"South"
#DEFINE GRIDHEAD5_LOC		"Total"

#DEFINE CTRLTYPE1_LOC		"Textbox"
#DEFINE CTRLNAME1			"Text"
#DEFINE CTRLCLASS1			"Textbox"
#DEFINE CTRLTYPE1			"CYNFDTBLMGI"

#DEFINE CTRLTYPE2_LOC		"Editbox"
#DEFINE CTRLNAME2			"Edit"
#DEFINE CTRLCLASS2			"Editbox"
#DEFINE CTRLTYPE2			"CM"

#DEFINE CTRLTYPE3_LOC		"Spinner"
#DEFINE CTRLNAME3			"Spinner"
#DEFINE CTRLCLASS3			"Spinner"
#DEFINE CTRLTYPE3			"YNFBI"

#DEFINE CTRLTYPE4_LOC		"Checkbox"
#DEFINE CTRLNAME4			"Check"
#DEFINE CTRLCLASS4			"Checkbox"
#DEFINE CTRLTYPE4			"L"

#DEFINE CTRLTYPE5_LOC		"OLEBoundControl"
#DEFINE CTRLNAME5			"OLEBoundControl"
#DEFINE CTRLCLASS5			"OLEBoundControl"
#DEFINE CTRLTYPE5			"G"

#DEFINE C_NONE_LOC			"<None>"

#DEFINE NOTBLCREATE_LOC		"The Grid Styles table GRIDSTYL.DBF was not found, and the default table was not successfully created."
#DEFINE NOSTYLECHG_LOC		"<Preserve current style>"
#DEFINE C_STYLETITLE_LOC	"Style Information"
#DEFINE C_TABLETASK_LOC		"Locating style table"
#DEFINE C_STYLETASK_LOC		"Gathering data from style table"
#DEFINE C_CURRSTYLE_LOC		"Examining current style of grid"

#DEFINE NOCURSORADAPTER_LOC	"The Grid Builder does not support grids bound to CursorAdapters."
*=======================================================
* frxCursor.vcx compile constants
*=======================================================

#include foxpro_reporting.h

*-------------------------------------------------------
* Magic numbers
*-------------------------------------------------------

*-- Report Layout object dimensions
*--
#define BAND_SEPARATOR_HEIGHT_FRUS	 	2083.333
#define BAND_SEPARATOR_HEIGHT_PIXELS	20

*-- Object Cursor filter modes:
*--
#define OBJCSR_ALL_OBJECTS_IGNORE_GROUPS	0
#define OBJCSR_FILTER_ON_SELECTED			1
#define OBJCSR_SHOW_ALL_OBJECTS				2
#define OBJCSR_FILTER_GROUP					3

#define OBJCSR_SORTORDER_TYPE		        1
#define OBJCSR_SORTORDER_BAND		        2

#define FRX_OBJTYPE_MULTISELECT             99

*-------------------------------------------------------
* Localization strings 
*-------------------------------------------------------

*-- FRX object targets:
*--
#define TARGET_MULTISELECT_LOC		"Multiple Selection"
#define TARGET_REPORT_COMMENT_LOC   "Comment"
#define TARGET_REPORT_GLOBAL_LOC	"Report/Global"
#define TARGET_WORKAREA_LOC			"Workarea"
#define TARGET_INDEX_LOC			"Index"
#define TARGET_RELATION_LOC			"Relation"	
#define TARGET_TEXT_LABEL_LOC		"Label"
#define TARGET_LINE_LOC				"Line"
#define TARGET_BOX_LOC				"Rectangle"
#define TARGET_FIELD_LOC			"Field"
#define TARGET_TITLE_LOC			"Title"
#define TARGET_PAGE_HEADER_LOC		"Page Header"
#define TARGET_COL_HEADER_LOC		"Column Header"
#define TARGET_GROUP_HEADER_LOC		"Group Header"
#define TARGET_DETAIL_LOC			"Detail"
#define TARGET_GROUP_FOOTER_LOC		"Group Footer"
#define TARGET_COL_FOOTER_LOC		"Column Footer"
#define TARGET_PAGE_FOOTER_LOC		"Page Footer"
#define TARGET_SUMMARY_LOC			"Summary"
#define TARGET_DETAIL_HEADER_LOC	"Detail Header"
#define TARGET_DETAIL_FOOTER_LOC	"Detail Footer"
#define TARGET_UNKNOWN_BAND_LOC		"Unknown band type"
#define TARGET_GROUPED_LOC			"Grouped Objects"
#define TARGET_PICTURE_LOC			"Picture/OLE Bound"
#define TARGET_VARIABLE_LOC			"Variable"
#define TARGET_PDRIVER_LOC			"Printer Driver Setup"
#define TARGET_FONTRESO_LOC			"Font Resource"
#define TARGET_DATAENV_LOC			"Data Environment"
#define TARGET_CURSOR_LOC			"Cursor"
#define TARGET_UNKNOWN_LOC			"Unknown Target type"

#define TARGET_FORCED_PAGEHEADER_LOC "Resolved as Page Header"
#define TARGET_UNPREDICTABLE_LOC     "Indeterminate behavior"

*-- Calculation "Reset On" combo list
*--
#define ENDOFREPORT_LOC		    "Report"
#define ENDOFPAGE_LOC		    "Page"
#define ENDOFCOLUMN_LOC		    "Column"
#define GROUP_BY_LOC		    "Group: "
#define DETAIL_LOC              "Detail "
#define NEW_LOC                 "new"


*-- Messagebox error messages:
*--
#define METADATA_DOM_ERROR_LOC   "Exception occurred in frxCursor::getMetadataDomDoc()"
#define CREATE_IC_FAILURE_LOC    "Unable to create device context. CreateIC() returned 0."
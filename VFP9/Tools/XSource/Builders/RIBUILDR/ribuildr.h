#define C_DEBUG .f.
#DEFINE D_DELVIOL_LOC   "Delete restrict rule violated."
#DEFINE D_INSVIOL_LOC   "Insert restrict rule violated."
#DEFINE D_UPDVIOL_LOC   "Update restrict rule violated."
#define d_cannotlockdbc_loc "Cannot lock the DBC. Referential integrity builder cannot run without locking the DBC."
#define d_cascadechar "C"
#define d_cascadeword_loc "Cascade"
#define d_exclusive_loc "EXCLUSIVE"
#define d_ignorechar "I"
#define d_ignoreword_loc "Ignore"
#define d_missingdbc_loc "No DBC open. Referential Integrity builder cannot run without an open DBC."
#define d_msgtitle_loc "Referential Integrity Builder"
#define d_norelations_loc "There are no relations in this DBC. Referential Integrity builder cannot run without at least one relationship."
#define d_notexclusive_loc "This DBC is not open for EXCLUSIVE use. You will not be allowed to generate RI code for this DBC"
#define d_overwrite2_loc "."+chr(13)+"The RI builder will "
#define d_overwrite3_loc "save a copy of all stored procedure code in risp.old before making changes."+chr(13)+"Do you want to generate your "
#define d_overwrite4_loc "new RI code now?"
*** DH
#define d_overwrite5_loc "."+chr(13)+chr(13) + "Choose:" + chr(13) + "   Yes to save a copy of all stored procedure code in risp.old then generate your new RI code."+chr(13)+"   No to generate your new RI code now without saving a copy." + chr(13) + "   Cancel to cancel this process."
*** END DH
#define d_overwrite_loc "Generating will attempt to merge RI code with your non-RI stored procedures in "
#define d_record_locked_loc "RECORD LOCKED"
#define d_restrictchar "R"
#define d_restrictword_loc "Restrict"
#define d_rusureA_loc "Are you sure you want to cancel RI info changes and exit?"
#define d_rusureD_loc "Do you want to save your changes, generate RI code, and exit?"
#define D_Tables_Are_Buffered_loc "Referential Integrity builder cannot run with tables open and buffering on"
#define D_DELTRIGCOMMENT_LOC "Referential integrity delete trigger for"
#define D_DELTRIGCOMMENTEND_LOC "End of Referential integrity Delete trigger for"
#define D_UPDTRIGCOMMENT_LOC "Referential integrity update trigger for"
#define D_UPDTRIGCOMMENTEND_LOC "End of Referential integrity Update trigger for"
#define D_INSTRIGCOMMENT_LOC "Referential integrity insert trigger for"
#define D_INSTRIGCOMMENTEND_LOC "End of Referential integrity insert trigger for"
#define D_NOSETMULTIOFF .T.
#DEFINE d_nokcancel 1
#define D_ncancel 2
#define d_ok 0
#define d_cr chr(13)
#define d_operators_loc "!@#$%^&*()-+=></.,"
#define d_expressionbasedcascade_loc "Cascade updates that are based on expression-based index keys, may not behave as expected. The system has identified expression-based keys in the following relationships:"+chr(13)+chr(13)
#define d_expressionbasedcascade2_loc chr(13)+"Select Ok to continue with RI code generation. (Note: You can override the generated __ri_update_* code by creating stored procedures of the same name, and including those stored procedures AFTER the end of the generated RI code.)"
#define C_VERSION  "6.0" &&Version use use by PSS -- hold mouse down for 1 second on Help button
#define D_CleanupFirst_loc "The Referential Integrity builder cannot run until your database is first cleaned up. With your database open in the Database Designer, select the Clean Up Database item from the Database menu."

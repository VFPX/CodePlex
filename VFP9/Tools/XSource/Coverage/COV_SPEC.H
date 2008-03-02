* COV_SPEC.H
* Constants required by current Coverage app specifications

#DEFINE COV_COMPILED_IN_VFP5       ( "PRO 05." $ UPPER(VERSION()) )

#DEFINE COV_MESSAGE_LIMIT           254
* used to trim WAIT WINDOW messages to the legal limit

* Legal path length:
#DEFINE N_VFP_PATH_LIMIT           1024

* FRX Object Types:
#DEFINE N_FRX_DATAENVIRONMENT_OBJTYPE    25
#DEFINE N_FRX_CURSOR_RELATION_OBJTYPE    26

* Mouse Pointers:
#DEFINE MOUSEPOINTER_ARROW_UP        10
#DEFINE MOUSEPOINTER_HOURGLASS       11
#DEFINE MOUSEPOINTER_ARROW_EW        9
#DEFINE MOUSEPOINTER_SIZE_NS         7
#DEFINE MOUSEPOINTER_DEFAULT         0

* set by format of internally-created log:
#DEFINE N_COVLOG_FIELDCOUNT_V5       5
#DEFINE N_COVLOG_FIELDCOUNT_V6       6
#DEFINE N_COVLOG_PRECISION           IIF("05." $ VERS() OR ;
                                         ("06.00" $ VERS() AND ;
                                           VAL(SUBS(VERS(4),7)) < ;
                                          8365),;
                                          3,6)
   

* original: "06.00" $ VERS(),3,6)

#DEFINE COV_LOG_DELIMITER            ,
* comma, at least so far!
* and you can't use CHR(44) or any other
* variant thereof, that I can find...

* currently required:
#DEFINE COV_IGNORE_COVERAGE_FILES     .T.
#DEFINE COV_KNOWN_ALIAS_PROPERTIES    "SOURCE","TARGET","SKIPPED","COVFILES","PROJECT"
#DEFINE COV_KNOWN_PJX_TYPES           "K","V","P","M","Q","R","B","F","d"
#DEFINE COV_BASE_CLASSLIB             "COVERAGE.VCX"

#DEFINE COV_FRX_LANGUAGEOPTIONS_ISSUE .T.


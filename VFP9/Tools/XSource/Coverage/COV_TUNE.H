* COV_TUNE.H
* Default/tunable option settings for Coverage app

* reference variable for the formset:
#DEFINE COV_PUBLIC_VARIABLE         _oCoverage

* class to instance:
#DEFINE COV_CLASS_TO_INSTANCE       "cov_standard"
#DEFINE COV_CLASS_CLASSLIB          "COVERAGE.VCX"

* forms in use by the cov_standard interface:
#DEFINE COV_MAINFORM                "cov_maindialog_standard"
#DEFINE COV_ZOOMFORM                "cov_zoomdialog"
#DEFINE COV_MAINFORM_CLASSLIB       "COVERAGE.VCX"
#DEFINE COV_ZOOMFORM_CLASSLIB       "COVERAGE.VCX"
* The two form classes must descend from 
* cov_maindialog_standard and
* cov_zoomdialog,
* or cov_standard will refuse to instantiate.

* dialogs in use by the cov_standard interface:
#DEFINE COV_STATISTICSDIALOG          "cov_statisticsdialog"
#DEFINE COV_STATISTICS_CLASSLIB       "COVERAGE.VCX"
#DEFINE COV_OPTIONSDIALOG             "cov_optionsdialog"
#DEFINE COV_OPTIONS_CLASSLIB          "COVERAGE.VCX"
#DEFINE COV_ADDINDIALOG               "cov_addindialog"
#DEFINE COV_ADDIN_CLASSLIB            "COVERAGE.VCX"
#DEFINE COV_FINDDIALOG                "cov_finddialog"
#DEFINE COV_FIND_CLASSLIB             "COVERAGE.VCX"

* default profile marking:
#DEFINE COV_PROFILE_EXECUTED_SPACING 10
#DEFINE COV_PROFILE_STATS_SPACING    15

* default coverage marking
#DEFINE COV_DEFAULT_MARKEXECUTED     ""
#DEFINE COV_DEFAULT_MARKNOTEXECUTED  "|"+SPACE(3)
#DEFINE COV_DEFAULT_MARKSPACING      5

* default fonts:
#DEFINE COV_DEFAULT_BASE_FONTNAME   "MS San Serif"
#DEFINE COV_DEFAULT_MONO_FONTNAME   "Courier New"
* these defaults will be overwritten by registry
* (trace window and standard Font properties) or
* if available resource file entries

* suffixs for default savenames for coverage result tables:
#DEFINE COV_SKIPFILEDBF_SUFFIX       "_SKIP"
#DEFINE COV_TARGETDBF_SUFFIX         "_COV"

#DEFINE COV_USE_OCXS                .T.
#DEFINE COV_TOPSPEED                .F.
* Make this one .T. if you want a fast, in-line call
* while Coverage parses your code.
* Using the method call, OTOH, gives you more
* scope for formatting the marks:
#IF COV_TOPSPEED
    #DEFINE COV_MARK_CODE_LINE      IIF(THIS.lInProfileMode, ;
                                        IIF(ISNULL(iExecuted), ;
                                            SPACE(40), ;
                                            STR(iExecuted,10,0)+ ;
                                            STR(nFirst,15,6)+STR(nAverage,15,6)), ;
                                        IIF(ISNULL(iExecuted), ;
                                            SPACE(LEN(THIS.cMarkExecuted)), ;
                                            IIF(iExecuted > 0, ;
                                                THIS.cMarkExecuted, ;
                                                THIS.cMarkNotExecuted)) ) + ;
                                     SPACE(4) + ;
                                     cRealLine
#ELSE
    #DEFINE COV_MARK_CODE_LINE      THIS.MarkCodeLine(cRealLine,iExecuted, nFirst, nAverage)
#ENDIF


* The following item is used for SET MEMOWIDTH in the Coverage 
* private data session.
* The Coverage engine uses MLINE(), MEMLINES(), and _MLINE to parse
* lines of source code.
* Note: this figure is the command line limit, and SET MEMOWIDTH
* limit, in VFP 6. In VFP 5, SETting MEMOWIDTH TO this value still 
* results in a setting of 1024 (the VFP 5 command and SET MEMOWIDTH
* limit).
* You can change this setting manually in the Coverage data session
* any time you like.... unless you write *lines without 
* continuation/concatenation* that are extremely long, 
* you do not need this high a limit --  and you may find that 
* leaving it at this setting uses slightly more memory than necessary.
* (Remember that we're not talking about macro-expanded SELECT statements,
* here, but rather the length of the actual code lines you *type*.)
* When figuring your longest lines of code, take a look at the length
* of your object and procedure names
* This figure is set at the outside limit for safety's sake.
#DEFINE COV_MEMOWIDTH                 8192

* The following items define the length of 
* character fields in the source and target cursors.
* Their default values (115 each) are defined by
* max length concatenated key,
* since two of these may be used together.
*
* To conserve disk space, especially in the source
* cursor and its CDX, you may reduce the size
* of these fields if you wish.  However,
* use care, or errors will occur
* when filenames or object/container
* information is truncated, as described below.

* As in the COV_MARK_CODE_LINE item above,
* these items are defined in two ways, depending
* on the setting of COV_TOPSPEED.  Setting 
* COV_TOPSPEED .T. will give you the fastest possible
* execution, since these #DEFINEs will resolve to a 
* literal.  By contrast, when COV_TOPSPEED is .F.,
* (the default value of this #DEFINE), 
* these #DEFINEs resolve to coverage engine properties,
* which means they take a little longer to execute but
* can be tweaked dynamically, for example when you know
* you are about to open a very large log.

* Whether you change these values in the #DEFINEs or
* in the property values, be mindful of the following
* conditions:

* If you choose to increase any of these values, 
* don't make the sum of any two of them over 240,
* to avoid potential max key length problems.

* If you choose to decrease any of these values, to
* conserve diskspace, avoid decreasing Hostfile unless
* you are sure the lengths of your fully-qualified 
* source files will not be exceeded. Otherwise,
* you may receive errors when the Profiler tries
* to find the uncompiled versions of these files.  

* Whether you decrease ObjClass, Executing, or both,
* be sensible. If you know you nest pageframes and
* grids several container-layers deep, or that
* you tend to use very long class names, try to
* stay above the maximum string these fields 
* are likely to contain, plus a margin for error.
* You may want to examine the source and target files
* first, to see how the engine uses these fields.
* Be on the lookout for suddenly-incorrect 
* Coverage and Profiling statistics,
* even though you may receive no obvious errors when
* when the Profiler analyzes the log.
* Statistical errors will occur if object and method names 
* are being truncated in the fields.


#IF COV_TOPSPEED

   #DEFINE COV_LEN_HOSTFILE            115
   #DEFINE COV_LEN_OBJCLASS            115
   #DEFINE COV_LEN_EXECUTING           115


#ELSE

   #DEFINE COV_LEN_HOSTFILE            THISFORMSET.iLenHostFile
   #DEFINE COV_LEN_OBJCLASS            THISFORMSET.iLenObjClass
   #DEFINE COV_LEN_EXECUTING           THISFORMSET.iLenExecuting

#ENDIF

* The Duration field in the source cursor is tuned with a constant
* and engine property similar to the character fields above.  
* However, this numeric field's length is also
* affected by the N_COVLOG_PRECISION specification.  Like all other
* constants set by the internal log and its version changes,
* you will find N_COVLOG_PRECISION in COV_SPEC.H.  You should
* not change N_COVLOG_PRECISION, but you can change the total length
* of the Duration field using COV_LEN_DURATION, after some experience,
*  if you find you don't need this many places in the field.  

#IF COV_TOPSPEED
   #DEFINE COV_LEN_DURATION            11
#ELSE
   #DEFINE COV_LEN_DURATION            THISFORMSET.iLenDuration
#ENDIF   

#DEFINE COV_LINES_TO_VALIDATE       100
#DEFINE COV_POINT_SETTING           "."

* The following item is the report form in use 
* by the cov_standard.DisplayProjectStatistics()
* method. 
* Note that this method is abstract in the cov_engine class.
* It is called by cov_engine.ShowProjectStatistics() after 
* cov_engine.GetProjectStatistics(), which serves to
* create a cursor containing the appropriate information.
* You can use a different FRX, and recompile COVERAGE.APP,
* to change cov_standard's display of this cursor,
* or you can subclass cov_engine with a different 
* .DisplayProjectStatistics() method that doesn't 
* use a REPORT FORM mechanism at all.
* Refer to cov_engine.GetProjectStatistics() to 
* the makeup of the project statistics cursor.
#DEFINE COV_PROJECT_FRX             "COV_PJX.FRX"

* debugging:
#DEFINE COV_DEBUG                    .F.
#DEFINE COV_TIMEOUT_SECS             2
#IF COV_DEBUG

    #DEFINE COV_DEBUG_MESSAGE        WAIT WINDOW LEFT(MESSAGE()+C_CR+;
                                                      SYS(2018)+C_CR+;
                                                      cMethod+C_CR+;
                                                      MESSAGE(1),COV_MESSAGE_LIMIT) ;
                                          TIMEOUT COV_TIMEOUT_SECS
    #DEFINE COV_DEBUG_ACTION         ERROR nError
    #DEFINE COV_ENGINE_ERROR_DEFAULT NOTE

#ELSE

    #DEFINE COV_DEBUG_MESSAGE        MESSAGEBOX(COV_PROBLEM_LOC+":"+C_CR+;
                                                MESSAGE()+C_CR+;
                                                cMethod,COV_STOP_MESSAGEBOX)
    #DEFINE COV_DEBUG_ACTION         NOTE
    #DEFINE COV_ENGINE_ERROR_DEFAULT THIS.Release()

#ENDIF

*&* comment out the line
*&* below if you don't want the
*&* on key label set up to
*&* invoke the Find dialog in the Coverage context...
*&* Or, if this keystroke conflicts with some other
*&* utility you use, change the label to suit
*&* your environment... 
#DEFINE COV_OKL_SHOW_FIND_DIALOG CTRL-F5

*&* the following five items are used by Coverage generation
*&* of StackLevel information to an XML version of the log:

* the first two represent element node prefixes
#DEFINE COV_STACKROOT        "VFPCallStackLog"     
#DEFINE COV_STACK_ONEVENT_TAG    "event"

* the next items are used to help identify the XML and HTM files written to
* disk as being generated from this particular process.
#DEFINE COV_STACKXML_SUFFIX          "_STACK"    
#DEFINE COV_STACKXMLEXT_SUFFIX       "_STACKX"
#DEFINE COV_TRANSFORM_SUFFIX         "_XSL"

* the next item indicates whether lines are loaded from the Coverage
* source workfile dbf or gathered directly by reading the original
* text log.  The former has a very slight speed advantage but will
* not include ON... events, since those lines are ignored by the
* Coverage source and target workfiles (there is no code to mark or profile
* for these lines).
#DEFINE COV_LOAD_STACK_FROM_DBF    .F.

* the vars in the next item have the same meaning as the columns of the
* same name in the Coverage source workfile DBF -- equivalents for these
* items are read in from the source text log when COV_LOAD_STACK_FROM_DBF is .F.,
* and this expression stays the same.  You can change it as long as you ensure that
* the result will never be empty except for ON... events.
* Load a log into COVERAGE.APP, SET DATASESSION TO _oCoverage.DataSessionID, 
* and refer to the source workfile (by default, its alias is FromLog) for 
* some indication on the possible contents of these columns.  
#DEFINE COV_STACKEXPR             ALLTR(IIF(INLIST(FileType,".fxp",".mpx",".qpx",".spx"), ;
                                  IIF(EMPTY(ObjClass), ;
                                      IIF(NOT EMPTY(Executing),ALLTR(Executing),""),;
                                      IIF(LEFT(Executing,1)="." OR AT(".",Executing) = 0,ALLTR(ObjClass)+;
                                      IIF(AT(".",Executing) = 0,".",""),"")+ALLTR(Executing)), ;
                                   ALLTR(Executing)))    

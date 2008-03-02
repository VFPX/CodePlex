* COV_LOCS.H
* String constants in use by Coverage app

* NB: some of these #DEFINEs are dependent on COV_CHAR.H
* definitions, so this file is #INCLUDEd after COV_CHAR.H
* in COVERAGE.H

#DEFINE COV_LOC                       "English-US"

#IF UPPER(COV_LOC) = "ENGLISH-US"

   #DEFINE COV_APPLICATION_NAME_LOC             "Coverage Profiler"
   #DEFINE COV_DIALOG_CAPTION_LOC               COV_APPLICATION_NAME_LOC

   *&* error messages and other feedback:
   #DEFINE COV_PROBLEM_LOC                      "Problem"
   #DEFINE COV_INFO_LOC                         "Information"    
   #DEFINE COV_DEBUG_ERROR_LOC                  "Error #"
   #DEFINE COV_DEBUG_LINENO_LOC                 "Line #"
   #DEFINE COV_LOG_NOT_SPECIFIED_LOC            "No log file specified."
   #DEFINE COV_LOCATE_CLASSLIB_LOC              "Where is "+COV_APPLICATION_NAME_LOC+"'s VCX?"
   #DEFINE COV_FILE_DOES_NOT_EXIST_LOC          "File specified does not exist."
   #DEFINE COV_OKAY_TO_OVERWRITE_LOC            "File specified already exists. "+C_CR+"Okay to overwrite?"
   #DEFINE COV_ADDIN_DOES_NOT_EXIST_LOC         "Add-In file specified does not exist."
   #DEFINE COV_ADDIN_NOT_SUPPORTED_TYPE_LOC     "Add-In file specified is not a supported type."
   #DEFINE COV_LOG_CANNOT_BE_OPENED_LOC         "Log file unavailable."
   #DEFINE COV_SOURCE_CANNOT_BE_OPENED_LOC      "Source file unavailable."
   #DEFINE COV_START_LOGGING_LOC                "The log file you chose does not exist yet."+C_DOUBLE_CR + ;
                                                "Test your application with COVERAGE SET TO "+C_CR + ;
                                                "<your chosen filename>, then run "+COV_APPLICATION_NAME_LOC+C_CR+;
                                                "against that log."+C_DOUBLE_CR+;
                                                COV_APPLICATION_NAME_LOC+" can SET COVERAGE TO your filename "+ C_CR+;
                                                "now and you can test your application.  When you re-run "+ C_CR+;
                                                COV_APPLICATION_NAME_LOC+", it will analyze the current "+ C_CR+;
                                                "contents of SET('COVERAGE') by default."+C_DOUBLE_CR+;
                                                "Would you like to: "+C_DOUBLE_CR+;
                                                "SET COVERAGE TO your log file now? (yes)"+C_DOUBLE_CR+;
                                                "Pick a filename from existing coverage logs? (no)"+C_DOUBLE_CR+;
                                                "Come back later? (cancel)"
                                                
   #DEFINE COV_NO_COVERABLE_CODE_LOC            "A source code entry has no coverable code"+C_CR+;
                                                "or is a member of a container object."+C_DOUBLE_CR+;
                                                "This record will be deleted."

   #DEFINE COV_PROJECT_UNAVAILABLE_LOC          "Project file currently unavailable."
   #DEFINE COV_CANNOT_RESUME_LOC                "Former coverage file is unavailable;"+C_CR+"COVERAGE will be off."
   #DEFINE COV_LOG_WRONG_FORMAT_LOC             "File specified is not correct Coverage Log format for this version of VFP."
   #DEFINE COV_LOG_HAS_NO_USABLE_RECORDS_LOC    "Log file has no usable records."
   #DEFINE COV_NO_USABLE_PROJECT_RECORDS_LOC    "Project has no source-code-type records."
   #DEFINE COV_NO_LOG_ENTRIES_SKIPPED_LOC       "No log entries were skipped."
   #DEFINE COV_SWITCHING_OFF_COMMON_DIALOG_LOC  "Common Dialog OCX not found; "+ C_CR + ;
                                                "switching to native VFP code version."

   #DEFINE COV_FEATURE_NEEDS_OCX_LOC            "This feature is currently unavailable, "+C_CR+ ;
                                                "because it requires an ActiveX control "+C_CR+ ;
                                                "not found on your system."

   #DEFINE COV_ALREADY_ACTIVE_LOC               COV_APPLICATION_NAME_LOC+" already active!"
   
   #DEFINE COV_REOPEN_SAME_LOG_FILE_LOC         "You haven't changed the specified Coverage filename."+ ;
                                                C_DOUBLE_CR+;
                                                "Do you want to re-examine this Coverage file?"
                                                
   #DEFINE COV_MARKS_CHANGED_LOC                "You have changed Coverage marks, but some records "+C_CR+;
                                                "in the current log are already marked. "+ ;
                                                C_DOUBLE_CR+ ;
                                                "Would you like to: "+ ;
                                                C_DOUBLE_CR+ ;
                                                "Preserve current marked records (yes) or "+ ;
                                                C_DOUBLE_CR+ ;
                                                "Empty and re-mark these records (no)?"

   #DEFINE COV_MARK_ALL_NOW_LOC                 "You have chosen to mark all records on load, but "+C_CR+;
                                                "some records in the current log may not be marked yet. "+ ;
                                                C_DOUBLE_CR+ ;
                                                "Would you like to mark all records now?"                                                
   
   #DEFINE COV_RESUME_LOC                       "Running Coverage Profiler temporarily suspended" + C_CR + ;
                                                "coverage logging to " + THIS.cSuspendedLog + "." + ;
                                                C_DOUBLE_CR + ;
                                                "How would you like to resume coverage logging to this file?" + ;
                                                C_DOUBLE_CR + ;
                                                "Click:"+ C_TAB + "To have this effect:" + ;
                                                C_DOUBLE_CR + ;  
                                                "Yes"+ SPACE(2) + C_TAB + "-- Append records to the log file" + C_CR + ;
                                                "No"+ SPACE(3) + C_TAB + "-- Overwrite the log file" + C_CR + ;
                                                "Cancel"+ C_TAB + "-- Leave coverage set off"

   #DEFINE COV_BAD_PARAMS_LOC                   "You have passed one or more parameters incorrectly." + ;
                                                C_DOUBLE_CR+ ;
                                                "This application takes the following "+ C_CR + ;
                                                "parameters, all optional:"+ ;
                                                C_DOUBLE_CR + ;
                                                "(1), type 'C'     the name of a coverage log to mark;"+ ;
                                                C_DOUBLE_CR + ;
                                                "(2), type 'L'     a switch to process the log unattended;" + ;
                                                C_DOUBLE_CR + ;
                                                "(3), type 'C'     the name of an Add-In program to run."
  #DEFINE COV_BADDIALOGS_LOC                    "Cov_Standard's .cMainDialogClass and/or .cZoomDialogClass"+C_CR+;
                                                "have been incorrectly assigned."+C_DOUBLE_CR+;
                                                "This Coverage User Interface class must contain dialogs"+C_CR+;
                                                "descended from "+ ;
                                                "cov_MainDialog_Standard and cov_ZoomDialog."
   
   *&*GETFILE/PUTFILE dialog titles, filters, etc:
   #DEFINE COV_GETMAINFILE_TITLE_LOC            "Please confirm main program for"
   #DEFINE COV_GETSOURCEFILE_TITLE_LOC          "Please locate"
   #DEFINE COV_SETTARGETDBF_TITLE_LOC           "Please specify location to save Coverage results for"
   #DEFINE COV_SETSTACKXML_TITLE_LOC            "Please specify location to save Coverage StackLevel XML for"
   #DEFINE COV_SETTRANSFORMEDXML_TITLE_LOC      "Please specify location to save transformed file for"
   #DEFINE COV_GETXSLTFILE_TITLE_LOC            "Please specify an XSL Transformation file"
   #DEFINE COV_SAVEDTARGET_AS_LOC               "Your coverage analysis is saved as"   
   #DEFINE COV_SAVEDSTACKXML_AS_LOC             "Your coverage stack analysis is saved as"      
   #DEFINE COV_SAVEDSKIPFILES_AS_LOC            "Some source files could not be located;"+C_CR+;
                                                "their names are saved in a second table"  
   #DEFINE COV_GETLOGFILE_TITLE_LOC             "Please specify coverage log file"
   #DEFINE COV_GETPROJECTFILE_TITLE_LOC         "Please specify a project file to check"
   #DEFINE COV_GETADDINFILE_TITLE_LOC           "Please specify an Add-In to run"
   #DEFINE COV_GETFILE_BUTTON_LOC               "Select"
   #DEFINE COV_LOGFILES_LOC                     "Coverage Logs"
   #DEFINE COV_ALLFILES_LOC                     "All Files"
   #DEFINE COV_XMLFILES_LOC                     "XML Files"
   #DEFINE COV_XSLFILES_LOC                     "XSL Transforms"
   #DEFINE COV_HTMFILES_LOC                     "HTML Files"
   #DEFINE COV_PROJECTSONLY_LOC                 "Projects Only"
   #DEFINE COV_PROGRAMSONLY_LOC                 "Programs Only"
   #DEFINE COV_DBFSONLY_LOC                     "Table/DBF"
   #DEFINE COV_SOURCEFILES_LOC                  "Source Files"   

   *&* wait window nowait /status bar messages during processing
   #DEFINE COV_FILLING_ALL_RECORDS_LOC          "Checking Coverage of all target source files..."
   #DEFINE COV_MARKING_ALL_RECORDS_LOC          "Marking all source code..."
   #DEFINE COV_EMPTYING_ALL_RECORDS_LOC         "Changing Coverage modes and emptying marked code..."
   #DEFINE COV_CREATING_FILES_FROM_LOC          "Creating work files from"
   #DEFINE COV_CHECKING_SOURCE_AVAIL_FROM_LOC   "Checking for source code for"
   #DEFINE COV_MARKING_SOURCE_FOR_LOC           "Marking source code for"
   #DEFINE COV_GETTING_SOURCECODE_FROM_LOC      "Getting source code from"
   #DEFINE COV_CHECKING_FOR_VALID_LOG_LOC       "Validating source file..."
   #DEFINE COV_INDEXING_SOURCE_RECORDS_LOC      "Indexing source records..."
   #DEFINE COV_CREATING_TARGET_ITEMS_LOC        "Creating target items..."
   #DEFINE COV_LOADING_STACKINFO_LOC            "Loading log for StackLevel analysis" 
   #DEFINE COV_GENERATING_STACKXML_LOC          "Generating StackLevel XML for"  
   #DEFINE COV_WRITING_STACKXML_LOC             "Writing StackLevel XML to disk"
   #DEFINE COV_WRITING_TRANSFORM_LOC            "Writing transformed file to disk"
   
                                                
   *&* main dialog buttons (tooltips and default captions if no pictures)
   #DEFINE COV_OPEN_LOC                         "Open"
   #DEFINE COV_SAVE_LOC                         "Save"   
   #DEFINE COV_COVERAGE_MODE_LOC                "Coverage Mode"
   #DEFINE COV_PROFILE_MODE_LOC                 "Profile Mode"
   #DEFINE COV_PREVIEW_MODE_LOC                 "Preview Mode"
   #DEFINE COV_ZOOM_MODE_LOC                    "Zoom Mode"
   #DEFINE COV_STATISTICS_LOC                   "Statistics"
   #DEFINE COV_OPTIONS_LOC                      "Options"
   #DEFINE COV_ADDINS_LOC                       "Add-Ins"   
   #DEFINE COV_HELP_LOC                         "Help"
   #DEFINE COV_OKCLOSE_LOC                      "OK"
   #DEFINE COV_CANCEL_LOC                       "Cancel"   
   #DEFINE COV_FIND_LOC                         "Find"
   
   *&* Main and Zoom dialog strings      
   #DEFINE COV_FULL_SOURCE_FILE_LOC             "All Classes, Objects, Procs"
   #DEFINE COV_ZOOM_MARKED_CODE_FOR_LOC         "Marked Code For"  
   #DEFINE COV_ZOOM_GET_CODE_LOC                "Fast Mode: DoubleClick/Enter on List for Code"
   #DEFINE COV_PROFILE_MARK_1ST_LOC             "1st"
   #DEFINE COV_PROFILE_MARK_AVG_LOC             "Avg"   
   #DEFINE COV_PROFILE_ONE_HIT_LOC              "Hit"
   #DEFINE COV_PROFILE_HITS_LOC                 "Hits"

   *&* Statistics dialog and reporting
   #DEFINE COV_STATS_VIEW_DETAILS_LOC           "View details"
   #DEFINE COV_STATS_VIEW_FILES_SKIPPED_LOC     "\<Source Files Skipped"
   #DEFINE COV_STATS_VIEW_SOURCE_LOG_LOC        "Source Text \<Log"
   #DEFINE COV_STATS_VIEW_PROJECT_LOC           "Statistics by \<Project..."
   
   #DEFINE COV_STATS_LINES_COVERABLE_LOC        "Total coverable lines"
   #DEFINE COV_STATS_LINES_HIT_LOC              "Line(s) hit"
   #DEFINE COV_STATS_LINES_MISSED_LOC           "Line(s) missed"
   #DEFINE COV_STATS_PCT_LINES_LOC              "% Covered Linecount"
   #DEFINE COV_STATS_OBJS_COVERABLE_LOC         "Classes with code"
   #DEFINE COV_STATS_OBJS_HIT_LOC               "Class(es) hit"
   #DEFINE COV_STATS_OBJS_MISSED_LOC            "Class(es) missed"
   #DEFINE COV_STATS_PCT_OBJS_LOC               "% Covered Classes"
   #DEFINE COV_STATS_FULL_FILE_LOC              "All Objects and Procs"

   #DEFINE COV_STATS_PJXFILES_HIT_LOC           "Project Source Files Hit"
   #DEFINE COV_STATS_PJXFILES_COVERABLE_LOC     "Total Source Code Files For Project"
   #DEFINE COV_STATS_PJXLINES_HIT_LOC           "Total Project Lines Hit"
   #DEFINE COV_STATS_PJXLINES_COVERABLE_LOC     "Total Lines Coverable Code in Files Hit"
   #IF ATC("FoxPro 05",VERSION()) > 0
      #DEFINE COV_STATS_PJXOBJS_HIT_LOC            "Total Classes Hit in Project VCXs and SCXs"
      #DEFINE COV_STATS_PJXOBJS_COVERABLE_LOC      "Total Classes in Project VCXs and SCXs contain code"
   #ELSE
      #DEFINE COV_STATS_PJXOBJS_HIT_LOC            "Total Classes Hit in Project VCXs, SCXs, FRXs, and LBXs"
      #DEFINE COV_STATS_PJXOBJS_COVERABLE_LOC      "Total Classes in Project VCXs, SCXs, FRXs, and LBXs contain code"
   #ENDIF
   #DEFINE COV_STATS_PCT_PJXFILES_LOC           "% Project Coverage by Files"
   #DEFINE COV_STATS_PCT_PJXLINES_LOC           "% Project Coverage by Lines (Files Hit Only)"
   #DEFINE COV_STATS_PCT_PJXOBJS_LOC            "% Class Code Coverage for Project Files Hit"
   #DEFINE COV_STATS_FILE_NOT_HIT_LOC           "File skipped or not logged"
   
   *&* Options dialog
   #DEFINE COV_OPT_SMARTPATH_LOC                "Use \<Smart Pathing"
   #DEFINE COV_OPT_REGISTER_ADDINS_LOC          "Register \<Add-Ins when run"   
   #DEFINE COV_OPT_MARKALL_LOC                  "\<Mark all code while log loads"
   #DEFINE COV_OPT_COVERAGE_MARKS_LOC           "Coverage marks"
   #DEFINE COV_OPT_MARKS_WILL_BE_MATCHED_LOC    "Mark lengths will be matched"
   #DEFINE COV_OPT_MARK_EXECUTED_LOC            "\<Executed:"
   #DEFINE COV_OPT_MARK_NOT_EXECUTED_LOC        "\<Not executed:"
   #DEFINE COV_OPT_FONTS_LOC                    "Fonts"
   #DEFINE COV_OPT_GETFONT_LOC                  "D\<isplay Font..."
   #DEFINE COV_OPT_GETFIXEDFONT_LOC             "C\<ode Font..."
   #DEFINE COV_OPT_SET_DEFAULTS_LOC             "Set as \<default"
   #DEFINE COV_OPT_START_IN_LOC                 "Start mode"
   #DEFINE COV_OPT_START_COVERAGE_LOC           "\<Coverage"   
   #DEFINE COV_OPT_START_PROFILE_LOC            "\<Profile"
   #DEFINE COV_OPT_ENVIRONMENT_LOC              "Environment"
   #DEFINE COV_OPT_COVFRAME_LOC                 "Co\<verage frame"
   #DEFINE COV_OPT_VFPFRAME_LOC                 "Fo\<xPro frame"
   #DEFINE COV_OPT_STACK_LOC                    "StackLevel XML analysis"
   #DEFINE COV_OPT_STACK_EXTENDED_LOC           "\<Generate extended StackLevel tree"
   #DEFINE COV_OPT_STACK_XSLT_LOC               "XSL \<Transform..."
   
   
   
   *&* shortcut prompts (different hotkeys)
   #DEFINE COV_SC_SMARTPATH_LOC                "\<Use Smart Pathing"
   #DEFINE COV_SC_GETFONT_LOC                  "\<Display Font..."
   #DEFINE COV_SC_GETFIXEDFONT_LOC             "\<Code Font..."
   #DEFINE COV_SC_STATISTICS_LOC               "\<Statistics..."
   #DEFINE COV_SC_ADDINS_LOC                   "\<Add-Ins..."
   #DEFINE COV_SC_SOURCELOG_LOC                "\<View Source Log"
   #DEFINE COV_SC_ARRANGE_LOC                  "Cascade \<Windows"
   #DEFINE COV_SC_FASTZOOM_LOC                 "Fast \<Zoom Mode"
   #DEFINE COV_SC_STACKLEVEL_LOC               "\<Generate StackLevel XML"      
   #DEFINE COV_SC_VIEW_STACKLEVEL_LOC          "View Stac\<kLevel XML"
   #DEFINE COV_SC_STACK_TRANSFORM_LOC          "\<Transform StackLevel XML"
   #DEFINE COV_SC_STACKLEVEL_EXTENDED_LOC      "E\<xtended StackLevel XML"
   
   
   *&* Add-Ins dialog
   #DEFINE COV_ADDIN_REGISTER_LOC               "Register this \<Add-In after running"
   #DEFINE COV_ADDIN_RUN_LOC                    "\<Run"
   
   *&* Find dialog
   #DEFINE COV_FIND_NOTFOUND_LOC               "Not found!"
   #DEFINE COV_FIND_FIND_LOC                   "\<Find"
   #DEFINE COV_FIND_FINDNEXT_LOC               "Find \<Next"
#ELSE

   * this case can contain empty #defs,
   * for pasting to new #ELIF cases above

#ENDIF

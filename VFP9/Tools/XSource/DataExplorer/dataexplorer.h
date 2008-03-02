#define APP_NAME	"VFP Data Explorer"
#define SQL_ODBC_DRIVER	"{SQL Server}"

#define CRLF	CHR(13) + CHR(10)

#define FONT_DEFAULT			"Tahoma,8,N"

#define tvwFirst	0
#define tvwLast		1
#define tvwNext		2
#define tvwPrevious	3
#define tvwChild	4


#define DEFTYPE_ROOT				'R'
#define DEFTYPE_DATASOURCE			'S'
#define DEFTYPE_CONNECTION			'C'
#define DEFTYPE_MENU				'M'
#define DEFTYPE_PICTURE				'P'
#define DEFTYPE_TEMPLATE			'T'
#define DEFTYPE_QUERYADDIN			'Q'
#define DEFTYPE_DATAADDIN			'Z'
#define DEFTYPE_EXPANDEDINFO		'E'
#define DEFTYPE_DROP_CODEWINDOW		'Y'
#define DEFTYPE_DROP_DESIGNSURFACE	'V'

#define CONNDB_SQLSERVER		'S'
#define CONNDB_SQLDATABASE		'D'
#define CONNDB_VFPDIRECTORY		'V'
#define CONNDB_VFPDATABASE		'F'
#define CONNDB_VFPTABLE			'T'


* define the Namespace and DMO CLSIDs
#define SQLDMO_CLASS		"SQLDMO.Application"
#define SQLDMO_SERVER		"SQLDMO.SQLServer"
#define SQLDMO_DATABASE		"SQLDMO.Database"
#define SQLDMO_FILE		"SQLDMO.DBFile"
#define SQLDMO_RESTORE		"SQLDMO.Restore"
#define SQLNS_CLASS	"SQLNS.SQLNamespace"

#define CONNECT_TIMEOUT_DEFAULT		15
#define QUERY_TIMEOUT_DEFAULT		600

#define ADOCONNECT_TIMEOUT_DEFAULT	15
#define ADOQUERY_TIMEOUT_DEFAULT	30


* Named Constants for SQL Namespace
#define SQLNSROOTTYPE_SERVER	2
#define SQLNSROOTTYPE_SERVERGROUP	1
#define SQLNSROOTTYPE_DATABASE	3
#define SQLNSROOTTYPE_DEFAULTROOT	0

#define SQLNSOBJECTTYPE_ROOT	0	&& Generic root node.
#define SQLNSOBJECTTYPE_EMPTY	1	&& Generic object type.
#define SQLNSOBJECTTYPE_SERVER_GROUP	2	&& Server group.
#define SQLNSOBJECTTYPE_SERVER	3	&& Server.
#define SQLNSOBJECTTYPE_DATABASES	4	&& Databases, SQLNSRootType_Server\Databases.
#define SQLNSOBJECTTYPE_DATABASE	5	&& Specific database, SQLNSRootType_Server\Databases\master.
#define SQLNSOBJECTTYPE_MANAGEMENT	6	&& SQLNSRootType_Server\Management.
#define SQLNSOBJECTTYPE_SECURITY	7	&& Security folder SQLNSRootType_Server\Security.
#define SQLNSOBJECTTYPE_SERVICES	8	&& Services folder, SQLNSRootType_Server\Support Services.
#define SQLNSOBJECTTYPE_LOGINS	9	&& Logins.
#define SQLNSOBJECTTYPE_LOGIN	10	&& Specific user login.
#define SQLNSOBJECTTYPE_BACKUPDEVICES	11	&& Backup Devices.
#define SQLNSOBJECTTYPE_BACKUPDEVICE	12	&& Specific backup device.
#define SQLNSOBJECTTYPE_DATABASE_PUBLICATIONS	13	&& Publications in a database tree.
#define SQLNSOBJECTTYPE_DATABASE_PUBLICATION	14	&& Specific publication in a database tree.
#define SQLNSOBJECTTYPE_DATABASE_PUB_SUBSCRIPTION	15	&& Specific subscription to a publication in a database tree.
#define SQLNSOBJECTTYPE_DATABASE_PULL_SUBSCRIPTIONS	16	&& Pull subscriptions.
#define SQLNSOBJECTTYPE_DATABASE_PULL_SUBSCRIPTION	17	&& Specific pull subscription.
#define SQLNSOBJECTTYPE_DATABASE_USERS	18	&& Database Users.
#define SQLNSOBJECTTYPE_DATABASE_USER	19	&& Specific database user.
#define SQLNSOBJECTTYPE_DATABASE_ROLES	20	&& Database Roles.
#define SQLNSOBJECTTYPE_DATABASE_ROLE	21	&& Specific database role.
#define SQLNSOBJECTTYPE_DATABASE_DIAGRAMS	22	&& Database Diagrams.
#define SQLNSOBJECTTYPE_DATABASE_DIAGRAM	23	&& Internal use only, not exposed.
#define SQLNSOBJECTTYPE_DATABASE_TABLES	24	&& Tables.
#define SQLNSOBJECTTYPE_DATABASE_TABLE	25	&& Specific table.
#define SQLNSOBJECTTYPE_DATABASE_VIEWS	26	&& SQL Server Views, SQLNSRootType_Server\Databases\pubs\Views.
#define SQLNSOBJECTTYPE_DATABASE_VIEW	27	&& Specific view, SQLNSRootType_Server\Databases\pubs\Views\titleview.
#define SQLNSOBJECTTYPE_DATABASE_SPS	28	&& Stored Procedures.
#define SQLNSOBJECTTYPE_DATABASE_SP	29	&& Specific stored procedure.
#define SQLNSOBJECTTYPE_DATABASE_EXTENDED_SPS	30	&& Extended stored procedure folder, SQLNSRootType_Server\Databases\master\Extended Stored Procedures.
#define SQLNSOBJECTTYPE_DATABASE_EXTENDED_SP	31	&& Specific extended stored procedure, SQLNSRootType_Server\Databases\master\Extended Stored Procedures
#define SQLNSOBJECTTYPE_DATABASE_RULES	32	&& Rules.
#define SQLNSOBJECTTYPE_DATABASE_RULE	33	&& Specific rule.
#define SQLNSOBJECTTYPE_DATABASE_DEFAULTS	34	&& Defaults.
#define SQLNSOBJECTTYPE_DATABASE_DEFAULT	35	&& Specific default.
#define SQLNSOBJECTTYPE_DATABASE_UDDTS	36	&& User Defined Data Types.
#define SQLNSOBJECTTYPE_DATABASE_UDDT	37	&& Specific user-defined data type.
#define SQLNSOBJECTTYPE_JOBSERVER	38	&& SQL Server Agent.
#define SQLNSOBJECTTYPE_SQLMAIL	39	&& SQL Mail.
#define SQLNSOBJECTTYPE_DTC	40	&& Distributed Transaction Coordinator.
#define SQLNSOBJECTTYPE_INDEXSERVER	41	&& Index server catalog.
#define SQLNSOBJECTTYPE_INDEXSERVER_CATALOGS	42	&& Index server catalog folder.
#define SQLNSOBJECTTYPE_INDEXSERVER_CATOLOG	43	&& Specific index server catalog.
#define SQLNSOBJECTTYPE_ERRORLOGS	44	&& Error log folder, SQLNSRootType_Server\Management\SQL Server Logs.
#define SQLNSOBJECTTYPE_ERRORLOG	45	&& Specific error log, SQLNSRootType_Server\Management\SQL Server Logs\Current ? Date.
#define SQLNSOBJECTTYPE_ERRORLOGENTRY	46	&& Error log entry, SQLNSRootType_Server\Management\SQL Server Logs\Current ? Date and time.
#define SQLNSOBJECTTYPE_ALERTS	47	&& SQLNSRootType_Server\Management\SQL Server Agent\Alerts.
#define SQLNSOBJECTTYPE_OPERATORS	48	&& Specific SQL Server log.
#define SQLNSOBJECTTYPE_MSX_JOBS	49	&& Reserved.
#define SQLNSOBJECTTYPE_LOCAL_JOBS	50	&& Local jobs, SQLNSRootType_Server\Management\SQL Server Agent\Jobs.
#define SQLNSOBJECTTYPE_MULTI_JOBS	51	&& Operators.
#define SQLNSOBJECTTYPE_LOCAL_JOB	52	&& Specific local job, SQLNSRootType_Server\Management\SQL Server Agent\Jobs\test.
#define SQLNSOBJECTTYPE_MULTI_JOB	53	&& Jobs.
#define SQLNSOBJECTTYPE_REMOTESERVERS	54	&& SQLNSRootType_Server\Security\Remote Servers.
#define SQLNSOBJECTTYPE_LINKEDSERVERS	55	&& Linked server folder, SQLNSRootType_Server\Security\Linked Servers.
#define SQLNSOBJECTTYPE_SERVERROLES	56	&& Remote server folder, SQLNSRootType_Server\Security\Server Roles.
#define SQLNSOBJECTTYPE_SERVERROLE	57	&& Specific remote server.
#define SQLNSOBJECTTYPE_ALERT	58	&& SQLNSRootType_Server\Management\SQL Server Agent\Alerts\Demo: Full msdb log.
#define SQLNSOBJECTTYPE_OPERATOR	59	&& Server Roles.
#define SQLNSOBJECTTYPE_REMOTESERVER	60	&& Specific server role.
#define SQLNSOBJECTTYPE_LINKEDSERVER	61	&& Specific linked server, SQLNSRootType_Server\Security\Linked Servers\NWIND.
#define SQLNSOBJECTTYPE_LINKEDSERVER_TABLE	62	&& Linked server table, SQLNSRootType_Server\Security\Linked Servers\NWIND\Tables\Categories.
#define SQLNSOBJECTTYPE_LINKEDSERVER_TABLES	63	&& Linked server table name, SQLNSRootType_Server\Security\Linked Servers\NWIND\Tables.
#define SQLNSOBJECTTYPE_REPLICATION	64	&& Replication folder.
#define SQLNSOBJECTTYPE_REPLICATION_PUBLISHERS	65	&& Replication Publishers folder.
#define SQLNSOBJECTTYPE_REPLICATION_PUBLISHER	66	&& Specific replication Publisher.
#define SQLNSOBJECTTYPE_REPLICATION_AGENTS	67	&& Replication agents folder.
#define SQLNSOBJECTTYPE_REPLICATION_REPORTS	68	&& Reserved.
#define SQLNSOBJECTTYPE_REPLICATION_ALERTS	69	&& Replication alerts folder.
#define SQLNSOBJECTTYPE_REPLICATION_SUBSCRIPTION	70	&& Specific replication subscription.
#define SQLNSOBJECTTYPE_REPLICATION_PUBLICATION	71	&& Specific replication publication.
#define SQLNSOBJECTTYPE_REPLICATION_SNAPSHOT_AGENTS	72	&& Replication Snapshot Agents folder.
#define SQLNSOBJECTTYPE_REPLICATION_LOGREADER_AGENTS	73	&& Replication Log Reader Agents folder.
#define SQLNSOBJECTTYPE_REPLICATION_DISTRIBUTION_AGENTS	74	&& Replication Distribution Agents folder.
#define SQLNSOBJECTTYPE_REPLICATION_MERGE_AGENTS	75	&& Replication Merge Agents folder.
#define SQLNSOBJECTTYPE_REPLICATION_SNAPSHOT_AGENT	76	&& Specific replication Snapshot Agent.
#define SQLNSOBJECTTYPE_REPLICATION_LOGREADER_AGENT	77	&& Specific replication Log Reader Agent.
#define SQLNSOBJECTTYPE_REPLICATION_DISTRIBUTION_AGENT	78	&& Specific replication Distribution Agent.
#define SQLNSOBJECTTYPE_REPLICATION_MERGE_AGENT	79	&& Specific replication Merge Agent.
#define SQLNSOBJECTTYPE_REPLICATION_REPORT	80	&& Reserved.
#define SQLNSOBJECTTYPE_DTS_LOCALPKGS	82	&& DTS packages saved to Microsoft? SQL Server? 2000.
#define SQLNSOBJECTTYPE_DTS_REPOSPKGS	83	&& DTS packages saved to repository.
#define SQLNSOBJECTTYPE_DTSPKGS	83	&& DTS Packages.
#define SQLNSOBJECTTYPE_DTSCATEGORIES	85	&& Reserved.
#define SQLNSOBJECTTYPE_DTSCATEGORY	85	&& Reserved.
#define SQLNSOBJECTTYPE_DTS_METADATA	86	&& DTS package meta data folder.
#define SQLNSOBJECTTYPE_DTSPKG	86	&& Specific DTS package.
#define SQLNSOBJECTTYPE_DTSSTEPS	87	&& Reserved.
#define SQLNSOBJECTTYPE_DTSCONNECTIONS	88	&& Reserved.
#define SQLNSOBJECTTYPE_DTSSTEP	89	&& Reserved.
#define SQLNSOBJECTTYPE_DTSCONNECTION	90	&& Reserved.
#define SQLNSOBJECTTYPE_DB_MAINT_PLANS	91	&& Database Maintenance Plans.
#define SQLNSOBJECTTYPE_DB_MAINT_PLAN	92	&& Specific database maintenance plan.
#define SQLNSOBJECTTYPE_WEBASSISTANTJOBS	93	&& Web Assistant Jobs.
#define SQLNSOBJECTTYPE_WEBASSISTANTJOB	94	&& Specific Web Assistant job.
#define SQLNSOBJECTTYPE_CURRENTACTIVITY	95	&& SQLNSRootType_Server\Management\Current Activity.
#define SQLNSOBJECTTYPE_CURRENTACTIVITY_ USERS	96	&& Reserved.
#define SQLNSOBJECTTYPE_CURRENTACTIVITY_LOGIN	97	&& Reserved.
#define SQLNSOBJECTTYPE_CURRENTACTIVITY_PROCESSINFO	98	&& SQLNSRootType_Server\Management\Current Activity\Process Info.
#define SQLNSOBJECTTYPE_CURRENTACTIVITY_PROCESSINFO_INFO	99	&& SQLNSRootType_Server\Management\Current Activity\Process Info\1.
#define SQLNSOBJECTTYPE_CURRENTACTIVITY_LOCKEDOBJECTS	100	&& SQLNSRootType_Server\Management\Current Activity\Locks\Object.
#define SQLNSOBJECTTYPE_CURRENTACTIVITY_LOCKEDOBJECT	101	&& SQLNSRootType_Server\Management\Current Activity\Locks\Object\master.
#define SQLNSOBJECTTYPE_DATABASE_UDFS	101	&& User-defined Functions folder.
#define SQLNSOBJECTTYPE_CURRENTACTIVITY_LOCKEDOBJECT_INFO	102	&& SQLNSRootType_Server\Management\Current Activity\Locks\Object\master\1.
#define SQLNSOBJECTTYPE_DATABASE_UDF	102	&& Specific user-defined function.
#define SQLNSOBJECTTYPE_PROFILER	103	&& SQL Server Performance Analysis Traces in the Management folder.
#define SQLNSOBJECTTYPE_PROFILER_TRACE	104	&& Reserved.
#define SQLNSOBJECTTYPE_REPLICATION_MONITOR_GROUP	105	&& Replication monitor group folder.
#define SQLNSOBJECTTYPE_REPLICATION_QUEUEREADER_AGENTS	106	&& Replication Queue Reader Agents Folder.
#define SQLNSOBJECTTYPE_REPLICATION_QUEUEREADER_AGENT	107	&& Specific replication Queue Reader Agent.
#define SQLNSOBJECTTYPE_LOGSHIPPING_MONITORS	108	&& Log Shipping monitor folder.
#define SQLNSOBJECTTYPE_LOGSHIPPING_MONITOR	109	&& Specific Log Shipping monitor.
#define SQLNSOBJECTTYPE_REPLICATION_FOLDER	110	&& Replication folder.
#define SQLNSOBJECTTYPE_PUBLICATIONS_FOLDER	111	&& Publications folder in the Replication folder.
#define SQLNSOBJECTTYPE_SUBSCRIPTIONS_FOLDER	112	&& Subscriptions folder in the Replication folder.
#define SQLNSOBJECTTYPE_REPLICATION_FOLDER_PUBLICATION	113	&& Specific publication in the Publications folder.
#define SQLNSOBJECTTYPE_REPLICATION_FOLDER_PUB_SUBSCRIPTION	114	&& Specific subscription to a publication in the Publications folder.
#define SQLNSOBJECTTYPE_REPLICATION_FOLDER_SUBSCRIPTION	115	&& Specific pull subscription in the Subscriptions folder.
#define SQLNSOBJECTTYPE_REPLICATION_FOLDER_PUSH_SUBSCRIPTION	116	&& Specific push subscription in the Subscriptions folder.
#define SQLNSOBJECTTYPE_HETEROGENEOUS_PUBLICATIONS_FOLDER	117	&& Heterogeneous Publications folder.
#define SQLNSOBJECTTYPE_HETEROGENEOUS_PUBLICATION	118	&& Specific heterogeneous publication.
#define SQLNSOBJECTTYPE_HETEROGENEOUS_PUB_SUBSCRIPTION	119	&& Subscription to a heterogeneous publication.
#define SQLNSOBJECTTYPE_HETEROGENEOUS_VENDOR_FOLDER	120	&& Heterogeneous Vendors folder.
#define SQLNSOBJECTTYPE_LINKEDSERVER_VIEWS	121	&& Linked server views folder.
#define SQLNSOBJECTTYPE_LINKEDSERVER_VIEW	122	&& Specific linked server view



* SQL Namespace commands
#define SQLNS_CMDID_AGENT_ERROR_DETAILS	76
#define SQLNS_CMDID_AGENT_HISTORY	77
#define SQLNS_CMDID_DATABASE_BACKUP	80
#define SQLNS_CMDID_DATABASE_RESTORE	81
#define SQLNS_CMDID_DATABASE_SHRINKDB	82
#define SQLNS_CMDID_DEFECT	56
#define SQLNS_CMDID_DELETE	17
#define SQLNS_CMDID_DTS_EXPORT	60
#define SQLNS_CMDID_DTS_IMPORT	59
#define SQLNS_CMDID_DTS_RUN	61
#define SQLNS_CMDID_EDIT_SERVER	43
#define SQLNS_CMDID_ENLIST	55
#define SQLNS_CMDID_ENLIST_REG_SERVERS	62
#define SQLNS_CMDID_EXPORT_JOB	57
#define SQLNS_CMDID_GENERATE_SCRIPTS	79
#define SQLNS_CMDID_JOB_HISTORY	40
#define SQLNS_CMDID_JOB_PROPERTIES (was #define SQLNS_CMDID_JOB_STEPS)	48
#define SQLNS_CMDID_JOB_START	39
#define SQLNS_CMDID_JOB_STOP	41
#define SQLNS_CMDID_JOBSERVER_ERRORLOG	38
#define SQLNS_CMDID_JOBSERVER_TARGET_SERVERS	42
#define SQLNS_CMDID_MULTI_SERVER_JOB_STATUS	58
#define SQLNS_CMDID_NEW_ALERT	20
#define SQLNS_CMDID_NEW_BACKUPDEVICE	36
#define SQLNS_CMDID_NEW_DATABASE	23
#define SQLNS_CMDID_NEW_DATABASE_ROLE	33
#define SQLNS_CMDID_NEW_DBUSER	35
#define SQLNS_CMDID_NEW_DEFAULT	29
#define SQLNS_CMDID_NEW_DIAGRAM	32
#define SQLNS_CMDID_NEW_EXTENDED_STORED_PROCEDURE	27
#define SQLNS_CMDID_NEW_JOB	19
#define SQLNS_CMDID_NEW_LOGIN	34
#define SQLNS_CMDID_NEW_OPERATOR	21
#define SQLNS_CMDID_NEW_PUBLICATION	69
#define SQLNS_CMDID_NEW_REMOTE_SERVER	22
#define SQLNS_CMDID_NEW_RULE	28
#define SQLNS_CMDID_NEW_SERVER	18
#define SQLNS_CMDID_NEW_SERVER_GROUP	31
#define SQLNS_CMDID_NEW_STORED_PROCEDURE	26
#define SQLNS_CMDID_NEW_SUBSCRIPTION	72
#define SQLNS_CMDID_NEW_TABLE	24
#define SQLNS_CMDID_NEW_TRACE	86
#define SQLNS_CMDID_NEW_UDDT	30
#define SQLNS_CMDID_NEW_UDF	85
#define SQLNS_CMDID_NEW_VIEW	25
#define SQLNS_CMDID_OBJECT_DEPENDENCIES	45
#define SQLNS_CMDID_OBJECT_PERMISSIONS	44
#define SQLNS_CMDID_OPEN	37
#define SQLNS_CMDID_PROPERTIES	16
#define SQLNS_CMDID_PUBLISHING_PROPERTIES	83
#define SQLNS_CMDID_PUSH_NEW_SUBSCRIPTION	70
#define SQLNS_CMDID_REINIT_SUBSCRIPTION	73
#define SQLNS_CMDID_REPLICATION_CONFIGURE	65
#define SQLNS_CMDID_REPLICATION_SUBSCRIBE	66
#define SQLNS_CMDID_REPLICATION_UNINSTALL	68
#define SQLNS_CMDID_REPLICATION_PUBLISH	64
#define SQLNS_CMDID_REPLICATION_RESOLVE_CONFLICTS	71
#define SQLNS_CMDID_REPLICATION_SCRIPT	67
#define SQLNS_CMDID_SECURITY_LIST	78
#define SQLNS_CMDID_SERVER_CONFIGURATION	54
#define SQLNS_CMDID_SERVER_CONNECT	53
#define SQLNS_CMDID_SERVER_SECURITY	52
#define SQLNS_CMDID_STOP_SYNCHRONIZING	75
#define SQLNS_CMDID_SVC_PAUSE	50
#define SQLNS_CMDID_SVC_START	51
#define SQLNS_CMDID_SVC_STOP	49
#define SQLNS_CMDID_SYNCHRONIZE_NOW	74
#define SQLNS_CMDID_TABLE_INDEXES	46
#define SQLNS_CMDID_TABLE_TRIGGERS	47
#define SQLNS_CMDID_TOOLS_MAINT_PLAN	63
#define SQLNS_CMDID_WIZARD_INDEXTUNING	9
#define SQLNS_CMDID_WIZARD_ALERT	10
#define SQLNS_CMDID_WIZARD_BACKUP	13
#define SQLNS_CMDID_WIZARD_CREATEDB	1
#define SQLNS_CMDID_WIZARD_CREATEINDEX	2
#define SQLNS_CMDID_WIZARD_CREATEJOB	5
#define SQLNS_CMDID_WIZARD_CREATETRACE	14
#define SQLNS_CMDID_WIZARD_DTSEXPORT	4
#define SQLNS_CMDID_WIZARD_DTSIMPORT	3
#define SQLNS_CMDID_WIZARD_MAINTPLAN	11
#define SQLNS_CMDID_WIZARD_SECURITY	6
#define SQLNS_CMDID_WIZARD_SP	7
#define SQLNS_CMDID_WIZARD_VIEW	8
#define SQLNS_CMDID_WIZARD_WEBASST	12
#define SQLNS_CMDID_WIZARDS	15

* for parameter input/output
#define PARAM_UNKNOWN 		0
#define PARAM_INPUT 		1
#define PARAM_OUTPUT		2
#define PARAM_INPUTOUTPUT	3
#define PARAM_RETURNVALUE	4


* -- Drag/drop support

#define VK_SHIFT  	0x10
#define VK_CONTROL  0x11

* The following are invalid in object name so we strip them out if we find them
#define INVALID_OBJNAME_CHARS	" -!@#$%^&*()+={}[]:;?/<>,\|~`'" + ["]


* -- Localizations
#define DATAEXPLORER_LOC	"Data Explorer"

#define NODETEXT_ROOT_LOC			"Data Explorer"
#define NODETEXT_SQLSERVERS_LOC		"SQL Servers"
#define NODETEXT_VFPDATABASES_LOC	"VFP Databases"
#define NODETEXT_TABLES_LOC			"Tables"
#define NODETEXT_VIEWS_LOC			"Views"
#define NODETEXT_STOREDPROCS_LOC	"Stored Procedures"
#define NODETEXT_FUNCTIONS_LOC		"Functions"

#define NODETEXT_CONNECTIONS_LOC	"Connections"


#define SELECTFOLDER_LOC			"Select the database folder:"

#define MENU_REFRESH_LOC			"\<Refresh"

#define NODE_LOADING_LOC			"(loading...)"

#define ERROR_OPENTABLE_LOC			"Unable to open the Data Explorer due to the following error:"
#define ERROR_RESTORE_LOC			"Do you want to restore to the default location?"
#define ERROR_CREATETABLES_LOC		"Error encountered creating table:"

#define ERROR_DROPSCRIPT_LOC		"Error executing drag/drop script:"


#define ERROR_SQLDMO_NOTINSTALLED_LOC  "Unable to create instance of SQL DMO object."

#define ERROR_NOBACKUP_LOC				"Unable to create a backup of the current Data Explorer table." + CHR(10) + CHR(10) + "Do you still want to proceed?"

#define ERROR_RESTORETODEFAULT_LOC		"Unable to restore to the original Data Explorer table due to the following error:"


#define DETAILS_SERVER_LOC			"Server:"
#define DETAILS_DATABASE_LOC		"Database:"
#define DETAILS_DATATYPE_LOC		"Data type:"
#define DETAILS_TABLE_LOC			"Table:"
#define DETAILS_COLUMN_LOC			"Column:"
#define DETAILS_DBF_LOC				"DBF:"
#define DETAILS_PHYSICALFILE_LOC	"Physical file:"
#define DETAILS_VIEW_LOC			"View:"
#define DETAILS_DEFAULT_LOC			"Default:"
#define DETAILS_PARAMETER_LOC		"Parameter:"
#define DETAILS_FUNCTION_LOC		"Function:"
#define DETAILS_DEFINITION_LOC		"Definition:"
#define DETAILS_STOREDPROC_LOC		"Stored Procedure:"
#define DETAILS_CONNECTIONSTRING_LOC "Connection String:"
#define DETAILS_OWNER_LOC			"Owner:"
#define UNKNOWN_LOC					"Unknown"

#define ADO_CONN_LOC	"ADO Connection"

#define NO_CHILDREN_LOC				"(none)"
#define NOT_SUPPORTED_LOC			"(not supported by provider)"


#define CUSTOMIZE_RESTORE_LOC	"Do you want to maintain connections and customizations that were done" + CHR(10) + "by you or a third-party vendor?"
#define CUSTOMIZE_RESTOREDONE_LOC		"The DataExplorer table has been restored to the original." + CHR(10) + "A backup of the original table was saved to:"

* displayed in place of backed up file if a backup could not be done
#define CUSTOMIZE_NONE_LOC				"<none>"

#define MENU_PROMPT_LOC			"Data Explore\<r"
#define MENU_MESSAGE_LOC 		"Displays Visual FoxPro Data Explorer"

#define ERROR_CREATECONNECTION_LOC "Unable to create connection node due to the following error:"
#define ERROR_CREATEDATAMGMT_LOC "Unable to create instance of data management object:"

#define FILTERED_LOC	" [filtered]"

#define NEW_ADDIN_LOC	"New Add-In"
#define DELETE_ADDIN_LOC	"Are you sure you want to delete this add-in?"

#define NEW_MENU_LOC	"New Menu Item"
#define DELETE_MENU_LOC	"Are you sure you want to delete this menu item?"

#define NEW_DRAGDROP_LOC	"New Drop Script"
#define DELETE_DRAGDROP_LOC	"Are you sure you want to delete this drag/drop add-in?"


#define SHOWERROR_ADDIN_LOC	"Error encountered displaying the add-ins:"
#define RUNERROR_ADDIN_LOC	"Error encountered running the add-in:"

* put the ## where you want the number to go
#define RETRIEVE_COUNT_LOC		"## row(s) retrieved"
#define QUERY_NORESULTS_LOC	"Query executed (no result set)"


#define ERROR_CREATECONNSCRIPT_LOC	"Error running script code associated with connection."

* what to return for function return value
#define RETURN_VALUE_LOC	"value"

#define PARAM_IN_LOC	"In"
#define PARAM_OUT_LOC	"Out"
#define PARAM_INOUT_LOC	"In/Out"

#define MENU_SCRIPTCODE_LOC	"Menu Script Code"
#define MENU_DISPLAYIF_LOC	"Menu Display Only If"
#define MENU_TEMPLATE_LOC	"Menu Template"

#define ADDIN_SCRIPTCODE_LOC	"Add-In Script Code"

#define DRAGDROP_SCRIPTCODE_LOC	"Drop Script Code"
#define DRAGDROP_TEMPLATE_LOC	"Drop Template"

#define ERROR_NONCONTAINER_LOC			"Cannot add objects to non-container classes."

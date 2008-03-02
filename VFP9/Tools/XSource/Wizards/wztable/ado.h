*- ADO.h
*- #DEFINEs for using ADO

*- the ADO constants
#INCLUDE "ADOVFP.h"

*- Use the ADO engine
#DEFINE ADOENGINE				"adodb.connection"
#DEFINE JET_PROVIDER_KEY		".jod"

*- Latest version
#DEFINE I_ADO_VERSION				   1.5

*- VFP error numbers
#DEFINE I_OLEERROR						1429

*- Access index attributes
#DEFINE dbDescending				   1

*- Access relation attributes
#DEFINE dbRelationUnique			   1
#DEFINE dbRelationDontEnforce		   2
#DEFINE dbRelationInherited			   4
#DEFINE dbRelationUpdateCascade		 256
#DEFINE dbRelationDeleteCascade		4096
#DEFINE dbRelationLeft			16777216
#DEFINE dbRelationRight			33554432

*- Access table attributes
#DEFINE dbSystemObject		 -2147483646

#DEFINE dbAutoIncrement		16

#DEFINE C_NOADO_LOC				"Unable to use ActiveX Data Objects. Access indexes, relations and field data cannot be imported."
#DEFINE C_NOJETPROVIDER_LOC		"Unable to locate a Jet OLE DB provider. The wizard will attempt to use ODBC, but Microsoft Access " + ;
								"indexes and relations will not be imported."
#DEFINE C_NOJETOPENMDB_LOC		"Unable to open the Access database with the Jet ADO provider. " + ;
								"Indexes and relations will not be imported."
#DEFINE C_OLDDAO_LOC			"The wizard requires ActiveX Data Objects version 3.0 or later.")
#DEFINE C_NOOPENMDB_LOC			"Unable to open Access database."
#DEFINE C_TABLECREATEFAIL_LOC	"Unable to create table "
#DEFINE C_NODATASET_LOC			"Unable to get data from "
#DEFINE C_ADDRELATION_LOC		"Adding relations..."
#DEFINE C_MOVEDATA_LOC			"Moving data..."
#DEFINE C_PROCESSING_LOC		"Processing "
#DEFINE C_BUILDINGINDEX_LOC		"Building index "
#DEFINE C_OLDJETPROVIDER_LOC	"The installed Jet OLE DB provider doesn't support functionality needed to retrieve database information necessary for index creation. You should upgrade to a newer version of the Microsoft Data Access Components to improve importing of Access databases."

*- DAO.h
*- #DEFINEs for using the DAO.DBEngine

*- Use the DAO.DBEngine
#DEFINE DAOENGINE				"DAO.DBEngine"

*- Latest version
#DEFINE I_DAO_VERSION				   3

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

#DEFINE C_NODAO_LOC			"Unable to use Data Access Objects. Access indexes, relations and field data cannot be imported."
#DEFINE C_OLDDAO_LOC		"The wizard requires Data Access Objects version 3.0 or later."
#DEFINE C_NOOPENMDB_LOC		"Unable to open Access database."
#DEFINE C_ADDRELATION_LOC	"Adding relations..."
#DEFINE C_PROCESSING_LOC	"Processing "
#DEFINE C_BUILDINGINDEX_LOC	"Building index "


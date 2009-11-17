*- SubFox.h --*

#include PushOK.h
#include FoxPro.h

#define SUBFOX_VERSION			1
#define CRLF					CHR(13) + CHR(10)
#define CR						CHR(13)
#define LF						CHR(10)

#define MAX_VFP_FLD_LEN			254
#define MAX_VFP_IDX_LEN			120

#DEFINE PJX_RECTYPE_HOME		"H"
#DEFINE FILETYPE_DBTABLE		"t"  && table within DBC (.DBF)
#DEFINE FILETYPE_PRJHOOK		"W"
#DEFINE FILETYPE_PROJECT		"H"
#DEFINE FILETYPE_ICON			"i"
#DEFINE FILETYPE_ONECLASS		"c"

#define SUBFOX_PRIVATE_EXT		"subfox"
#define SUBFOX_TEXT_EXTS		"prg,qpr,mpr,spr,h,ini,txt,fpw,xml,reg,csv,c,cpp"
#define SUBFOX_UNENCODEABLE_EXTS "bmp,msk,ico,png,gif,jpg,jpeg,tiff,xls,zip,pdf,app,dll,fll"
#define SUBFOX_ENCODEABLE_EXTS	"dbc,dbf,frx,lbx,mnx,pjx,scx,vcx"
#define SUBFOX_IMAGE_EXTS		"bmp,msk,ico,png,gif,jpg,jpeg,tiff"
#define SDT_META_TABLES			"sdtmeta,sdtuser,coremeta,dbcxreg"
#define SDT_UPD_PEND_FNAME		"sdt update pending.tmp"
#define SDT_META_SECTION		"SDT_META_FILES"
#define SDT_TABLE_SECTION		"SDT_STATIC_TABLES"

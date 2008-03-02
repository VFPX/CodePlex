#ifndef __XML_H
#define __XML_H

#include "foxpro.h"

#define TAB		Chr(9)
#define LF		Chr(10)
#define CR		Chr(13)
#define CR_LF	CR + LF

#define HTTP_HEADER "HTTP/1.0 200 OK" + CR_LF + "Content-type: text/xml" + CR_LF + CR_LF
#define XML_HEADER '<?xml version="1.0"?>' + CR_LF

#endif
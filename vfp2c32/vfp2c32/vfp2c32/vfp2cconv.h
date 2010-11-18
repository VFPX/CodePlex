#ifndef _VFP2CCONV_H__
#define _VFP2CCONV_H__

#define HEX_PREFIX 1
#define HEX_LEADINGNULLS 2

#pragma pack(push,1)	// set structure padding to 1
typedef struct _VALUEEX
{
	union
	{
		double ev_real;
		CCY ev_currency;
		int ev_long;
		unsigned int ev_length;
	};
	char ev_type;
	unsigned char ev_width;
	unsigned char ev_decimals;
	unsigned char ev_unused;
} VALUEEX, *LPVALUEEX;
#pragma pack(pop)

#ifdef __cplusplus
extern "C" {
#endif

void _fastcall PG_ByteA2Str(ParamBlk *parm);
void _fastcall PG_Str2ByteA(ParamBlk *parm);
void _fastcall RGB2Colors(ParamBlk *parm);
void _fastcall Colors2RGB(ParamBlk *parm);
void _fastcall GetCursorPosEx(ParamBlk *parm);

void _fastcall Int64_Add(ParamBlk *parm);
void _fastcall Int64_Sub(ParamBlk *parm);
void _fastcall Int64_Mul(ParamBlk *parm);
void _fastcall Int64_Div(ParamBlk *parm);
void _fastcall Int64_Mod(ParamBlk *parm);

void _fastcall Value2Variant(ParamBlk *parm);
void _fastcall Variant2Value(ParamBlk *parm);

void _fastcall Decimals(ParamBlk *parm);
void _fastcall Num2Binary(ParamBlk *parm);

void _fastcall CreatePublicShadowObjReference(ParamBlk *parm);
void _fastcall ReleasePublicShadowObjReference(ParamBlk *parm);

void _fastcall GetLocaleInfoExLib(ParamBlk *parm);

#ifdef __cplusplus
}
#endif

#endif // _VFP2CCONV_H__
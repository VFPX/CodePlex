#define _WINSOCKAPI_ // we're using winsock2 .. so this is neccessary to exclude winsock.h 

#include "windows.h"
#include "vfp2cassembly.h"

/* this code implements a runtime assembly code emitter */

/* pointer to codesection */
static LPCODE gpCS = 0;
static LPCODE gpCSEx = 0;

static CTYPEINFO gaParms[ASM_MAX_PARAMS] = {0};
static int gnParms = -1;

static CTYPEINFO gaVars[ASM_MAX_VARS] = {0};
static int gnVars = -1;

static LABEL gaLabels[ASM_MAX_LABELS] = {0};
static int gnLabels = -1;

static LABEL gaJumps[ASM_MAX_LABELS] = {0};
static int gnJumps = -1;

static CODE gaCodeBuffer[ASM_MAX_CODE_BUFFER];

static int Asm_Types[10][3] =  // size, alignment & sign of C types
{
	{ sizeof(char), __alignof(char), TRUE },
	{ sizeof(unsigned char), __alignof(unsigned char), FALSE },
	{ sizeof(short),__alignof(short), TRUE },
	{ sizeof(unsigned short), __alignof(unsigned short), FALSE },
	{ sizeof(int), __alignof(int), TRUE },
	{ sizeof(unsigned int), __alignof(unsigned int), FALSE },
	{ sizeof(__int64), __alignof(__int64), TRUE },
	{ sizeof(unsigned __int64), __alignof(unsigned __int64), FALSE },
	{ sizeof(float), __alignof(float), FALSE },
	{ sizeof(double), __alignof(double), FALSE }
};

void _stdcall Emit_Init()
{
	gpCS = (LPCODE)gaCodeBuffer;
	gnParms = -1;
	gnVars = -1;
	gnLabels = -1;
	gnJumps = -1;
}

void _stdcall Emit_Write(void *lpAddress)
{
	gpCSEx = (LPCODE)lpAddress;
	CopyMemory(lpAddress,gaCodeBuffer,Emit_CodeSize());
}

int _stdcall Emit_CodeSize()
{
	return gpCS - gaCodeBuffer;
}

void _stdcall Emit_Prolog()
{
	Push(EBP);
	Mov(EBP,ESP);
	if (gnVars >= 0)
		Sub(ESP,-gaVars[gnVars].nOffset);
}

void _stdcall Emit_Epilog(bool bCDecl)
{
 	Mov(ESP,EBP);
	Pop(EBP);
	Ret(bCDecl ? 0 : Emit_ParmSize());
}

void _stdcall Emit_Parameter(char *pParameter, TYPE nType)
{
	LPCTYPEINFO lpType = &gaParms[gnParms+1];
	strcpy(lpType->aName,pParameter);
	Emit_ParameterEx(lpType,nType);
}

void _stdcall Emit_Parameter(TYPE nType)
{
	LPCTYPEINFO lpType = &gaParms[gnParms+1];
	strcpy(lpType->aName,"");
	Emit_ParameterEx(lpType,nType);
}

void _stdcall Emit_ParameterEx(LPCTYPEINFO lpType, TYPE nType)
{
	lpType->nType = nType;
	lpType->nSize = Asm_Types[nType][CTYPE_SIZE];
	lpType->nAlign = Asm_Types[nType][CTYPE_ALIGN];
	lpType->bSign = Asm_Types[nType][CTYPE_SIGN];
	
	if (gnParms >= 0)
		lpType->nOffset = gaParms[gnParms].nOffset + max(gaParms[gnParms].nSize,sizeof(int));
	else
		lpType->nOffset = 8;

	gnParms++;
}

LPCTYPEINFO _stdcall Emit_ParameterRef(char *pParameter)
{
	LPCTYPEINFO lpType = gaParms;
	int nParms = gnParms;
	while (nParms-- >= 0)
	{
		if (!strcmp(pParameter,lpType->aName))
			return lpType;
		lpType++;
	}
	return 0;
}

LPCTYPEINFO _stdcall Emit_ParameterRef(PARAMNO nParmNo)
{
	if (gnParms >= (nParmNo-1))
		return &gaParms[nParmNo-1];
	else
		return 0;

}

int _stdcall Emit_ParmSize()
{
	if (gnParms >= 0)
		return gaParms[gnParms].nOffset + max(gaParms[gnParms].nSize,sizeof(int)) - 8;
	else
		return 0;
}

void _stdcall Emit_LocalVar(char *pVariable, TYPE nType)
{
	LPCTYPEINFO lpType = &gaVars[gnVars+1];

	strcpy(lpType->aName,pVariable);
	lpType->nType = nType;
	lpType->nSize = Asm_Types[nType][CTYPE_SIZE];
	lpType->nAlign = Asm_Types[nType][CTYPE_ALIGN];
	lpType->bSign = Asm_Types[nType][CTYPE_SIGN];
	
	if (gnVars >= 0)
	{
		lpType->nOffset = gaVars[gnVars].nOffset - lpType->nSize;
		lpType->nOffset -= lpType->nOffset % lpType->nAlign;
	}
	else
		lpType->nOffset = -lpType->nSize;

	gnVars++;
}

void _stdcall Emit_LocalVar(char *pVariable, int nSize, int nAlignment)
{
	LPCTYPEINFO lpType = &gaVars[gnVars+1];

	strcpy(lpType->aName,pVariable);
	lpType->nSize = nSize;
	lpType->nAlign = nAlignment;
	
	if (gnVars >= 0)
	{
		lpType->nOffset = gaVars[gnVars].nOffset - lpType->nSize;
		lpType->nOffset -= lpType->nOffset % lpType->nAlign;
	}
	else
		lpType->nOffset = -lpType->nSize;

	gnVars++;
}

LPCTYPEINFO _stdcall Emit_LocalVarRef(char *pVariable)
{
	LPCTYPEINFO lpType = gaVars;
	int nVars = gnVars;

	while (nVars-- >= 0)
	{
		if (!strcmp(pVariable,lpType->aName))
			return lpType;
		lpType++;
	}
	return 0;
}

LPCTYPEINFO _stdcall Emit_ParmOrVarRef(char *pVariable)
{
	LPCTYPEINFO lpType;
	lpType = Emit_ParameterRef(pVariable);
	if (lpType)
		return lpType;
	else
		return Emit_LocalVarRef(pVariable);
}

void _stdcall Emit_Label(char *pLabel)
{
	LPLABEL lpLabel = &gaLabels[++gnLabels];
	strcpy(lpLabel->aName,pLabel);
	lpLabel->pLocation = gpCS;
}

void _stdcall Emit_Jump(char *pLabel)
{
	LPLABEL lpJump = &gaJumps[++gnJumps];
	strcpy(lpJump->aName,pLabel);
	lpJump->pLocation = gpCS;
	gpCS += sizeof(int);
}

void _stdcall Emit_Patch()
{
	int nJumps, nDist;
	LPLABEL lpJump, lpLabel;

	for (nJumps = 0; nJumps <= gnJumps; nJumps++)
	{
		lpJump = &gaJumps[nJumps];
		lpLabel = Emit_LabelRef(lpJump->aName);
		if (lpLabel)
		{
			nDist = lpLabel->pLocation - lpJump->pLocation - sizeof(int);
			*(int*)lpJump->pLocation = nDist;
		}
	}
}

LPLABEL _stdcall Emit_LabelRef(char *pLabel)
{
	int nLabels;
	for (nLabels = 0; nLabels <= gnLabels; nLabels++)
	{
		if (!strcmp(gaLabels[nLabels].aName,pLabel))
			return &gaLabels[nLabels];
	}
	return 0;
}

void* _stdcall Emit_LabelAddress(char *pLabel)
{
	LPLABEL lpLabel = Emit_LabelRef(pLabel);
	if (lpLabel)
	{
		// pointer of realcode + offset of label in codebuffer
		return gpCSEx + (lpLabel->pLocation - gaCodeBuffer);
	}
	else
		return 0;
}

void _stdcall Emit_BreakPoint()
{
	*gpCS++ = 0xCC;
}

/* push a register onto the stack */
void _stdcall Push(REGISTER nReg)
{
	if (nReg > EDI)
		*gpCS++ = OP_ADRSIZE_16;
	*gpCS++ = MAKE_OP(OP_PUSH_R32,nReg);
}

void _stdcall Push(AVALUE nValue)
{
	int nValue2 = (int)nValue;
	if (InByteRange(nValue2))
	{
		*gpCS++ = OP_PUSH_IMM8;
		*gpCS++ = (CODE)nValue2;
	}
	else
	{
		*gpCS++ = OP_PUSH_IMM32;
		*(int*)gpCS = nValue2;
		gpCS += sizeof(int);
	}
}

void _stdcall Push(int nValue)
{
	*gpCS++ = OP_PUSH_IMM32;
	*(int*)gpCS = nValue;
	gpCS += sizeof(int);
}

void _stdcall Push_Ex(TYPE nType, int nOffset)
{
	if (nType <= T_UINT || nType == T_FLOAT)
	{
		if (InByteRange(nOffset))
		{
			*gpCS++ = OP_PUSH_RM32;
			*gpCS++ = MODRM_DISP8_OP_STACK(MODRM_OP_PUSH);
			*gpCS++ = (CODE)nOffset;
		}
		else
		{
			*gpCS++ = OP_PUSH_RM32;
			*gpCS++ = MODRM_DISP32_OP_STACK(MODRM_OP_PUSH);
			*(int*)gpCS = nOffset;
			gpCS += sizeof(int);
		}
	}
	else if (nType <= T_INT64 || nType == T_DOUBLE)
	{
		if (InByteRange(nOffset) && InByteRange((nOffset+4)))
		{
			// push upper 32 bit
			*gpCS++ = OP_PUSH_RM32;
			*gpCS++ = MODRM_DISP8_OP_STACK(MODRM_OP_PUSH);
			*gpCS++ = (CODE)nOffset+4;

			// push lower 32 bit
			*gpCS++ = OP_PUSH_RM32;
			*gpCS++ = MODRM_DISP8_OP_STACK(MODRM_OP_PUSH);
			*gpCS++ = (CODE)nOffset;
		}
		else
		{
			// push upper 32 bit
			*gpCS++ = OP_PUSH_RM32;
			*gpCS++ = MODRM_DISP32_OP_STACK(MODRM_OP_PUSH);
			*(int*)gpCS = nOffset+4;
			gpCS += sizeof(int);
			
			// push lower 32 bit
			*gpCS++ = OP_PUSH_RM32;
			*gpCS++ = MODRM_DISP32_OP_STACK(MODRM_OP_PUSH);
			*(int*)gpCS = nOffset;
			gpCS += sizeof(int);
		}
	}
}

void _stdcall Push(PARAMNO nParmNo)
{
	LPCTYPEINFO lpType = Emit_ParameterRef(nParmNo);
	if (lpType)
		Push_Ex(lpType->nType,lpType->nOffset);
}

void _stdcall Push(char *pParmOrVar)
{
	LPCTYPEINFO lpType = Emit_ParmOrVarRef(pParmOrVar);
	if (lpType)
		Push_Ex(lpType->nType,lpType->nOffset);
}

void _stdcall Push(PARAMNO nParmNo, TYPE nType, int nOffset)
{
	LPCTYPEINFO lpType = Emit_ParameterRef(nParmNo);
	if (lpType)
		Push_Ex(nType,lpType->nOffset + nOffset);
}

void _stdcall Push(char *pParmOrVar, TYPE nType, int nOffset)
{
	LPCTYPEINFO lpType = Emit_ParmOrVarRef(pParmOrVar);
	if (lpType)
		Push_Ex(nType,lpType->nOffset + nOffset);
}

/* pop a value from the stack into a register */
void _stdcall Pop(REGISTER nReg)
{
	if (nReg <= EDI)
		*gpCS++ = MAKE_OP(OP_POP_R32,nReg);
	else if (nReg <= DI)
	{
		*gpCS++ = OP_ADRSIZE_16;
		*gpCS++ = MAKE_OP(OP_POP_R32,nReg);
	}
}

/* Sub ?! :) */
void _stdcall Sub(REGISTER nReg, int nBytes)
{
	if (nReg <= EDI)
	{
		if (InByteRange(nBytes))
		{
			*gpCS++ = OP_SUB_R32_IMM8;
			*gpCS++ = MODRM_REG_OP_REG(MODRM_OP_SUB,nReg);
			*(char*)gpCS++ = nBytes;
		}
		else
		{
			if (nReg == EAX)
				*gpCS++ = OP_SUB_EAX_IMM32;
			else
			{
				*gpCS++ = OP_SUB_R32_IMM32;
				*gpCS++ = MODRM_REG_OP_REG(MODRM_OP_SUB,nReg);
			}
			*(int*)gpCS = nBytes;
			gpCS += sizeof(int);
		}
	}
	else if (nReg <= DI)
	{
		*gpCS++ = OP_ADRSIZE_16;
		if (nReg == AX)
			*gpCS++ = OP_SUB_AX_IMM16;
		else
		{
			*gpCS++ = OP_SUB_R32_IMM32;
			*gpCS++ = MODRM_REG_OP_REG(MODRM_OP_SUB,nReg);
		}
		*(short*)gpCS = nBytes;
		gpCS += sizeof(short);
	}
	else
	{
		if (nReg == AL)
			*gpCS++ = OP_SUB_AL_IMM8;
		else
		{
			*gpCS++ = OP_SUB_RM8_IMM8;
			*gpCS++ = MODRM_REG_OP_REG(MODRM_OP_SUB,nReg);
		}
		*(char*)gpCS++ = nBytes;
	}
}

void _stdcall Sub(REGISTER nReg, unsigned int nBytes)
{
	if(nReg <= EDI)
	{
		if (nReg == EAX)
			*gpCS++ = OP_SUB_EAX_IMM32;
		else
		{
			*gpCS++ = OP_SUB_R32_IMM32;
			*gpCS++ = MODRM_REG_OP_REG(MODRM_OP_SUB,nReg);
		}
		*(unsigned int*)gpCS = nBytes;
		gpCS += sizeof(unsigned int);
	}
	else if (nReg <= DI)
	{
		if (nReg == AX)
			*gpCS++ = OP_SUB_AX_IMM16;
		else
		{
			*gpCS++ = OP_ADRSIZE_16;
			*gpCS++ = OP_SUB_R32_IMM32;
			*gpCS++ = MODRM_REG_OP_REG(MODRM_OP_SUB,nReg);
		}
		*(unsigned int*)gpCS = nBytes;
		gpCS += sizeof(unsigned int);
	}
	else
	{
		if (nReg = AL)
			*gpCS++ = OP_SUB_AL_IMM8;
		else
		{
			*gpCS++ = OP_SUB_RM8_IMM8;
			*gpCS++ = MODRM_REG_OP_REG(MODRM_OP_SUB,nReg);
		}
		*(unsigned __int8*)gpCS++ = nBytes;
	}
}

void _stdcall Sub(REGISTER nReg, REGISTER nReg2)
{
	if (nReg <= EDI)
	{
		*gpCS++ = OP_SUB_R32_RM32;
		*gpCS++ = MODRM_REG_REG_REG(nReg,nReg2);
	}
	else if (nReg <= DI)
	{
		*gpCS++ = OP_ADRSIZE_16;
		*gpCS++ = OP_SUB_R32_RM32;
		*gpCS++ = MODRM_REG_REG_REG(nReg,nReg2);
	}
	else
	{
		*gpCS++ = OP_SUB_R8_RM8;
		*gpCS++ = MODRM_REG_REG_REG(nReg,nReg2);
	}
}

/* Add ?! :) */
void _stdcall Add(REGISTER nReg, int nBytes)
{
	if (nReg <= EDI)
	{
		if (InByteRange(nBytes))
		{
			*gpCS++ = OP_ADD_R32_IMM8;
			*gpCS++ = MODRM_REG_REG(nReg);
			*(char*)gpCS++ = nBytes;
		}
		else
		{
			if (nReg == EAX)
				*gpCS++ = OP_ADD_EAX_IMM32;
			else
			{
				*gpCS++ = OP_ADD_RM32_IMM32;
				*gpCS++ = MODRM_REG_REG(nReg);
			}
			*(int*)gpCS = nBytes;
			gpCS += sizeof(int);
		}
	}
	else if (nReg <= DI)
	{
		if (nReg == AX)
			*gpCS++ = OP_ADD_AX_IMM16;
		else
		{
			*gpCS++ = OP_ADRSIZE_16;
			*gpCS++ = OP_ADD_RM32_IMM32;
			*gpCS++ = MODRM_REG_REG(nReg);
		}
		*(short*)gpCS = (short)nBytes;
		gpCS += sizeof(short);
	}
	else 
	{
		if (nReg == AL)
			*gpCS++ = OP_ADD_AL_IMM8;
		else
		{
			*gpCS++ = OP_ADD_RM8_IMM8;
			*gpCS++ = MODRM_REG_REG(nReg);
		}
		*(char*)gpCS++ = nBytes;
	}
}

void _stdcall Add(REGISTER nReg, unsigned int nBytes)
{
	if (nReg <= EDI)
	{
		if (nReg == EAX)
			*gpCS++ = OP_ADD_EAX_IMM32;
		else
		{
			*gpCS++ = OP_ADD_RM32_IMM32;
			*gpCS++ = MODRM_REG_REG(nReg);
		}
		*(unsigned int*)gpCS = nBytes;
		gpCS += sizeof(unsigned int);
	}
	else if (nReg <= DI)
	{
		if (nReg == AX)
			*gpCS++ = OP_ADD_AX_IMM16;
		else
		{
			*gpCS++ = OP_ADRSIZE_16;
			*gpCS++ = OP_ADD_RM32_IMM32;
			*gpCS++ = MODRM_REG_REG(nReg);
		}
		*(unsigned short*)gpCS = (unsigned short)nBytes;
		gpCS += sizeof(unsigned short);
	}
	else 
	{
		if (nReg == AL)
			*gpCS++ = OP_ADD_AL_IMM8;
		else
		{
			*gpCS++ = OP_ADD_RM8_IMM8;
			*gpCS++ = MODRM_REG_REG(nReg);
		}
		*(char*)gpCS++ = nBytes;
	}
}

void _stdcall Add(REGISTER nReg, REGISTER nReg2)
{
	if (nReg <= EDI)
	{
		*gpCS++ = OP_ADD_R32_RM32;
		*gpCS++ = MODRM_REG_REG_REG(nReg,nReg2);
	}
	else if (nReg <= DI)
	{
		*gpCS++ = OP_ADRSIZE_16;
		*gpCS++ = OP_ADD_R32_RM32;
		*gpCS++ = MODRM_REG_REG_REG(nReg,nReg2);
	}
	else
	{
		*gpCS++ = OP_ADD_R8_RM8;
		*gpCS++ = MODRM_REG_REG_REG(nReg,nReg2);
	}
}

/* Dec ?! :) decrement; someRegister--; */
void _stdcall Dec(REGISTER nReg)
{
	if (nReg <= EDI)
		*gpCS++ = MAKE_OP(OP_DEC_R32,nReg);
	else if (nReg <= DI)
	{
		*gpCS++ = OP_ADRSIZE_16;
		*gpCS++ = MAKE_OP(OP_DEC_R32,nReg);
	}
	else 
	{
		*gpCS++ = OP_DEC_RM8;
		*gpCS++ = MODRM_REG_OP_REG(MODRM_OP_DEC,nReg);
	}
}

/* Inc ?! :) increment; someRegister++; */
void _stdcall Inc(REGISTER nReg)
{
	if (nReg <= EDI)
		*gpCS++ = MAKE_OP(OP_INC_R32,nReg);
	else if (nReg <= DI)
	{
		*gpCS++ = OP_ADRSIZE_16;
		*gpCS++ = MAKE_OP(OP_INC_R32,nReg);
	}
	else
	{
		*gpCS++ = OP_INC_RM8;
		*gpCS++ = MODRM_REG_REG(nReg);
	}
}

void _stdcall And(REGISTER nReg, int nValue)
{
	if (nReg <= ESI)
	{
		if (nReg == EAX)
		{
			*gpCS++ = OP_AND_EAX_IMM32;
			*(int*)gpCS = nValue;
			gpCS += sizeof(int);
		}
		else
		{
            if (InByteRange(nValue))
			{
				*gpCS++ = OP_AND_RM32_IMM8;
				*gpCS++ = MODRM_REG_OP_REG(MODRM_OP_AND,nReg);
				*(char*)gpCS++ = nValue;
			}
			else
			{
				*gpCS++ = OP_AND_RM32_IMM32;
				*gpCS++ = MODRM_REG_OP_REG(MODRM_OP_AND,nReg);
				*(int*)gpCS = nValue;
				gpCS += sizeof(int);
			}
		}
	}
	else if (nReg <= DI)
	{
		if (nReg == AX)
		{
			*gpCS++ = OP_ADRSIZE_16;
			*gpCS++ = OP_AND_EAX_IMM32;
			*(short*)gpCS = (short)nValue;
			gpCS += sizeof(short);
		}
		else
		{
			*gpCS++ = OP_ADRSIZE_16;
			*gpCS++ = OP_AND_RM32_IMM32;
			*gpCS++ = MODRM_REG_OP_REG(MODRM_OP_AND,nReg);
			*(short*)gpCS = (short)nValue;
			gpCS += sizeof(short);
		}
	}
	else
	{
		if (nReg == AL)
		{
			*gpCS++ = OP_AND_AL_IMM8;
			*(char*)gpCS++ = (char)nValue;
		}
		else
		{
			*gpCS++ = OP_AND_RM8_IMM8;
			*gpCS++ = MODRM_REG_OP_REG(MODRM_OP_AND,nReg);
			*(char*)gpCS++ = (char)nValue;
		}
	}
}

void _stdcall And(REGISTER nReg, REGISTER nReg2)
{
	if (nReg <= EDI)
	{
		*gpCS++ = OP_AND_R32_RM32;
		*gpCS++ = MODRM_REG_REG_REG(nReg,nReg2);
	}
	else if (nReg <= DI)
	{
		*gpCS++ = OP_ADRSIZE_16;
		*gpCS++ = OP_AND_R32_RM32;
		*gpCS++ = MODRM_REG_REG_REG(nReg,nReg2);
	}
	else
	{
		*gpCS++ = OP_AND_R8_RM8;
		*gpCS++ = MODRM_REG_REG_REG(nReg,nReg2);
	}
}

void _stdcall Or(REGISTER nReg, int nValue)
{
	if (nReg <= EDI)
	{
		if (nReg == EAX)
		{
			*gpCS++ = OP_OR_EAX_IMM32;
			*(int*)gpCS = nValue;
			gpCS += sizeof(int);
		}
		else
		{
			*gpCS++ = OP_OR_RM32_IMM32;
			*gpCS++ = MODRM_REG_OP_REG(MODRM_OP_OR,nReg);
			*(int*)gpCS = nValue;
			gpCS += sizeof(int);
		}
	}
	else if (nReg <= DI)
	{
		if (nReg == AX)
		{
			*gpCS++ = OP_ADRSIZE_16;
			*gpCS++ = OP_OR_EAX_IMM32;
			*(short*)gpCS = nValue;
			gpCS += sizeof(short);
		}
		else
		{
			*gpCS++ = OP_ADRSIZE_16;
			*gpCS++ = OP_OR_RM32_IMM32;
			*gpCS++ = MODRM_REG_OP_REG(MODRM_OP_OR,nReg);
			*(short*)gpCS = nValue;
			gpCS += sizeof(short);
		}
	}
	else
	{
		if (nReg == AL)
		{
			*gpCS++ = OP_OR_AL_IMM8;
			*(char*)gpCS++ = (char)nValue;
		}
		else
		{
			*gpCS++ = OP_OR_RM8_IMM8;
			*gpCS++ = MODRM_REG_OP_REG(MODRM_OP_OR,nReg);
		}
	}
}

void _stdcall Or(REGISTER nReg, REGISTER nReg2)
{
	if (nReg <= EDI)
	{
		*gpCS++ = OP_OR_R32_RM32;
		*gpCS++ = MODRM_REG_REG_REG(nReg,nReg2);
	}
	else if (nReg <= DI)
	{
		*gpCS++ = OP_ADRSIZE_16;
		*gpCS++ = OP_OR_R32_RM32;
		*gpCS++ = MODRM_REG_REG_REG(nReg,nReg2);
	}
	else
	{
		*gpCS++ = OP_OR_R8_RM8;
		*gpCS++ = MODRM_REG_REG_REG(nReg,nReg2);
	}
}

void _stdcall Xor(REGISTER nReg, int nValue)
{
	if (nReg <= EDI)
	{
		if (nReg == EAX)
		{
			*gpCS++ = OP_XOR_EAX_IMM32;
			*(int*)gpCS = nValue;
			gpCS += sizeof(int);
		}
		else
		{
			*gpCS++ = OP_XOR_RM32_IMM32;
			*gpCS++ = MODRM_REG_OP_REG(MODRM_OP_XOR,nReg);
			*(int*)gpCS = nValue;
			gpCS += sizeof(int);
		}
	}
	else if (nReg <= DI)
	{
		if (nReg == AX)
		{
			*gpCS++ = OP_ADRSIZE_16;
			*gpCS++ = OP_XOR_EAX_IMM32;
			*(short*)gpCS = nValue;
			gpCS += sizeof(short);
		}
		else
		{
			*gpCS++ = OP_ADRSIZE_16;
			*gpCS++ = OP_XOR_RM32_IMM32;
			*gpCS++ = MODRM_REG_OP_REG(MODRM_OP_XOR,nReg);
			*(short*)gpCS = nValue;
			gpCS += sizeof(short);
		}
	}
	else
	{
		if (nReg == AL)
		{
			*gpCS++ = OP_XOR_AL_IMM8;
			*(char*)gpCS++ = (char)nValue;
		}
		else
		{
			*gpCS++ = OP_XOR_RM8_IMM8;
			*gpCS++ = MODRM_REG_OP_REG(MODRM_OP_XOR,nReg);
		}
	}
}

void _stdcall Xor(REGISTER nReg, REGISTER nReg2)
{
	if (nReg <= EDI)
	{
		*gpCS++ = OP_XOR_R32_RM32;
		*gpCS++ = MODRM_REG_REG_REG(nReg,nReg2);
	}
	else if (nReg <= DI)
	{
		*gpCS++ = OP_ADRSIZE_16;
		*gpCS++ = OP_XOR_R32_RM32;
		*gpCS++ = MODRM_REG_REG_REG(nReg,nReg2);
	}
	else
	{
		*gpCS++ = OP_XOR_R8_RM8;
		*gpCS++ = MODRM_REG_REG_REG(nReg,nReg2);
	}
}


void _stdcall Cdq()
{
	*gpCS++ = OP_CDQ;
}

void _stdcall Shift_Ex(REGISTER nReg, int nBits, int nOpcode)
{
	if (nReg <= DI)
	{
		if (nReg > EDI)
			*gpCS++ = OP_ADRSIZE_16;

		if (nBits == 1)
		{
			*gpCS++ = OP_SHIFT_RM32;
			*gpCS++ = MODRM_REG_OP_REG(nOpcode,nReg);
		}
		else
		{
			*gpCS++ = OP_SHIFT_RM32_IMM8;
			*gpCS++ = MODRM_REG_OP_REG(nOpcode,nReg);
			*(char*)gpCS++ = (char)nBits;
		}
	}
	else
	{
		if (nBits == 1)
		{
			*gpCS++ = OP_SHIFT_RM8;
			*gpCS++ = MODRM_REG_OP_REG(nOpcode,nReg);
		}
		else
		{
			*gpCS++ = OP_SHIFT_RM8_IMM8;
			*gpCS++ = MODRM_REG_OP_REG(nOpcode,nReg);
			*(char*)gpCS++ = (char)nBits;
		}
	}
}

void _stdcall Sal(REGISTER nReg, int nBits)
{
	Shift_Ex(nReg,nBits,MODRM_OP_SAL);
}

void _stdcall Sar(REGISTER nReg, int nBits)
{
	Shift_Ex(nReg,nBits,MODRM_OP_SAR);
}

void _stdcall Shl(REGISTER nReg, int nBits)
{
	Shift_Ex(nReg,nBits,MODRM_OP_SHL);
}

void _stdcall Shr(REGISTER nReg, int nBits)
{
	Shift_Ex(nReg,nBits,MODRM_OP_SHR);
}

void _stdcall Lea_Ex(REGISTER nReg, int nOffset)
{
	*gpCS++ = OP_LEA_R32_M;
	if (InByteRange(nOffset))
	{
		*gpCS++ = MODRM_DISP8_REG_STACK(nReg);
		*(char*)gpCS++ = (char)nOffset;
	}
	else
	{
		*gpCS++ = MODRM_DISP32_REG_STACK(nReg);
		*(int*)gpCS = nOffset;
		gpCS += sizeof(int);
	}
}

void _stdcall Lea(REGISTER nReg, char *pParmOrVar, int nOffset)
{
	LPCTYPEINFO lpType = Emit_ParmOrVarRef(pParmOrVar);
	if (lpType)
		Lea_Ex(nReg,lpType->nOffset + nOffset);
}

void _stdcall Lea(REGISTER nReg, PARAMNO nParmNo, int nOffset)
{
	LPCTYPEINFO lpType = Emit_ParameterRef(nParmNo);
	if (lpType)
		Lea_Ex(nReg,lpType->nOffset + nOffset);
}

/* Move value from stack into a register */
void _stdcall Mov_Ex(REGISTER nReg, TYPE nType, int nOffset)
{
	if (nReg <= EDI)
	{
		if (nType < T_INT)
		{
			if (Asm_Types[nType][CTYPE_SIGN]) // signed?
				MovSX_Ex(nReg,nType,nOffset);
			else
				MovZX_Ex(nReg,nType,nOffset);
		}
		else
		{
			*gpCS++ = OP_MOV_R32_RM32;
			if (InByteRange(nOffset))
			{
				*gpCS++ = MODRM_DISP8_REG_STACK(nReg);
				*(char*)gpCS++ = nOffset;
			}
			else
			{
				*gpCS++ = MODRM_DISP32_REG_STACK(nReg);
				*(int*)gpCS = nOffset;
				gpCS += sizeof(int);
			}
		}
	}
	else if (nReg <= DI)
	{
		*gpCS++ = OP_ADRSIZE_16;
		*gpCS++ = OP_MOV_R32_RM32;

		if (InByteRange(nOffset))
		{
			*gpCS++ = MODRM_DISP8_REG_STACK(nReg);
			*(char*)gpCS++ = nOffset;
		}
		else
		{
			*gpCS++ = MODRM_DISP32_REG_STACK(nReg);
			*(int*)gpCS = nOffset;
			gpCS += sizeof(int);
		}
	}
	else
	{
		*gpCS++ = OP_MOV_R8_RM8;
		if (InByteRange(nOffset))
		{
			*gpCS++ = MODRM_DISP8_REG_STACK(nReg);
			*gpCS++ = (CODE)nOffset;
		}
		else
		{
			*gpCS++ = MODRM_DISP32_REG_STACK(nReg);
			*(int*)gpCS = nOffset;
			gpCS += sizeof(int);
		}
	}
}

void _stdcall Mov(REGISTER nReg, PARAMNO nParmNo)
{
	LPCTYPEINFO lpType = Emit_ParameterRef(nParmNo);
	if (lpType)
		Mov_Ex(nReg,lpType->nType,lpType->nOffset);
}

/* Move declared Parameter/Local variable from stack into a register */
void _stdcall Mov(REGISTER nReg, char *pParmOrVar)
{
    LPCTYPEINFO lpType = Emit_ParmOrVarRef(pParmOrVar);
	if (lpType)
		Mov_Ex(nReg,lpType->nType,lpType->nOffset);
}

void _stdcall Mov(REGISTER nReg, PARAMNO nParmNo, TYPE nType, int nOffset)
{
	LPCTYPEINFO lpType = Emit_ParameterRef(nParmNo);
	if (lpType)
		Mov_Ex(nReg,nType,lpType->nOffset + nOffset);
}

void _stdcall Mov(REGISTER nReg, char *pParmOrVar, TYPE nType, int nOffset)
{
	LPCTYPEINFO lpType = Emit_ParmOrVarRef(pParmOrVar);
	if (lpType)
		Mov_Ex(nReg,nType,lpType->nOffset + nOffset);
}

/* Move direct value into a register */
void _stdcall Mov(REGISTER nReg, AVALUE nValue)
{
	if (nReg <= EDI)
	{
		*gpCS++ = MAKE_OP(OP_MOV_R32_IMM32,nReg);
		*(AVALUE*)gpCS = nValue;
		gpCS += sizeof(AVALUE);
	}
	else if (nReg <= DI)
	{
		*gpCS++ = OP_ADRSIZE_16;
		*gpCS++ = MAKE_OP(OP_MOV_R32_IMM32,nReg);
		*(unsigned short*)gpCS = (unsigned short)nValue;
		gpCS += sizeof(short);
	}
	else
	{
		*gpCS++ = MAKE_OP(OP_MOV_R8_IMM8,nReg);
		*(unsigned char*)gpCS++ = (unsigned char)nValue;
	}
}

/* Move value into parameter/local variable */
void _stdcall Mov(char *pParmOrVar, int nValue)
{
	LPCTYPEINFO lpType = Emit_ParmOrVarRef(pParmOrVar);
	if (!lpType)
		return;

	if (lpType->nType <= T_UCHAR)
	{
		*gpCS++ = OP_MOV_RM8_IMM8;
		if (InByteRange(lpType->nOffset))
		{
            *gpCS++ = MODRM_DISP8_STACK();
			*(char*)gpCS++ = lpType->nOffset;
		}
		else
		{
			*gpCS++ = MODRM_DISP32_STACK();
			*(int*)gpCS = lpType->nOffset;
			gpCS += sizeof(int);
		}
		*(char*)gpCS++ = (char)nValue;
	}
	else if (lpType->nType <= T_USHORT)
	{
		*gpCS++ = OP_ADRSIZE_16;
		*gpCS++ = OP_MOV_RM32_IMM32;
		if (InByteRange(lpType->nOffset))
		{
            *gpCS++ = MODRM_DISP8_STACK();
			*(char*)gpCS++ = lpType->nOffset;
		}
		else
		{
			*gpCS++ = MODRM_DISP32_STACK();
			*(int*)gpCS = lpType->nOffset;
			gpCS += sizeof(int);
		}
		*(short*)gpCS = (short)nValue;
		gpCS += sizeof(short);
	}
	else if (lpType->nType <= T_UINT || lpType->nType == T_FLOAT)
	{
		*gpCS++ = OP_MOV_RM32_IMM32;
		if (InByteRange(lpType->nOffset))
		{
            *gpCS++ = MODRM_DISP8_STACK();
			*(char*)gpCS++ = lpType->nOffset;
		}
		else
		{
			*gpCS++ = MODRM_DISP32_STACK();
			*(int*)gpCS = lpType->nOffset;
			gpCS += sizeof(int);
		}
		*(int*)gpCS = nValue;
		gpCS += sizeof(int);
	}
}

/* move register into parameter/local variable */
void _stdcall Mov(char *pParmOrVar, REGISTER nReg)
{
	LPCTYPEINFO lpType = Emit_ParmOrVarRef(pParmOrVar);
	if (!lpType)
		return;

	if (lpType->nType <= T_UCHAR)
	{
		*gpCS++ = MAKE_OP(OP_MOV_RM8_R8,nReg);
		if (InByteRange(lpType->nOffset))
		{
            *gpCS++ = MODRM_DISP8_STACK();
			*(char*)gpCS++ = lpType->nOffset;
		}
		else
		{
			*gpCS++ = MODRM_DISP32_STACK();
			*(int*)gpCS = lpType->nOffset;
			gpCS += sizeof(int);
		}
	}
	else if (lpType->nType <= T_USHORT)
	{
		*gpCS++ = OP_ADRSIZE_16;
		*gpCS++ = MAKE_OP(OP_MOV_RM32_R32,nReg);
		if (InByteRange(lpType->nOffset))
		{
            *gpCS++ = MODRM_DISP8_STACK();
			*(char*)gpCS++ = lpType->nOffset;
		}
		else
		{
			*gpCS++ = MODRM_DISP32_STACK();
			*(int*)gpCS = lpType->nOffset;
			gpCS += sizeof(int);
		}
	}
	else if (lpType->nType <= T_UINT || lpType->nType == T_FLOAT)
	{
		*gpCS++ = MAKE_OP(OP_MOV_RM32_R32,nReg);
		if (InByteRange(lpType->nOffset))
		{
            *gpCS++ = MODRM_DISP8_STACK();
			*(char*)gpCS++ = lpType->nOffset;
		}
		else
		{
			*gpCS++ = MODRM_DISP32_STACK();
			*(int*)gpCS = lpType->nOffset;
			gpCS += sizeof(int);
		}
	}
}

void _stdcall Mov(RELREGISTER nRelReg, int nSize, int nValue)
{
	if (nSize == 1)
	{
		*gpCS++ = OP_MOV_RM8_IMM8;
		*gpCS++ = MODRM_REL_REG(nRelReg);
		*(char*)gpCS++ = (char)nValue;
	}
	else if (nSize == 2)
	{
		*gpCS++ = OP_ADRSIZE_16;
		*gpCS++ = OP_MOV_RM32_IMM32;
		*gpCS++ = MODRM_REL_REG(nRelReg);
		*(short*)gpCS = (short)nValue;
		gpCS += sizeof(short);
	}
	else if (nSize == 4)
	{
		*gpCS++ = OP_MOV_RM32_IMM32;
		*gpCS++ = MODRM_REL_REG(nRelReg);
		*(int*)gpCS = nValue;
		gpCS += sizeof(int);
	}
}

/* Move value from one register into another */
void _stdcall Mov(REGISTER nRegDest, REGISTER nRegSource)
{
 	if (nRegDest <= EDI)
	{
   		*gpCS++ = OP_MOV_R32_RM32;
		*gpCS++ = MODRM_REG_REG_REG(nRegDest,nRegSource);
	}
	else if (nRegDest <= DI)
	{
		*gpCS++ = OP_ADRSIZE_16;
		*gpCS++ = OP_MOV_R32_RM32;
		*gpCS++ = MODRM_REG_REG_REG(nRegDest,nRegSource);
	}
	else
	{
		*gpCS++ = OP_MOV_R8_RM8;
		*gpCS++ = MODRM_REG_REG_REG(nRegDest,nRegSource);
	}
}

void _stdcall MovZX_Ex(REGISTER nReg, TYPE nType, int nOffset)
{
	if (nReg > R_32BIT)
		*gpCS++ = OP_ADRSIZE_16;

	*gpCS++ = 0x0F;

	if (nType <= T_UCHAR)
		*gpCS++ = 0xB6;
	else
		*gpCS++ = 0xB7;

	if (InByteRange(nOffset))
	{
        //*gpCS++ = Asm_Mov_RS[nReg];
		*gpCS++ = (CODE)nOffset;
	}
	else
	{
		//*gpCS++ = Asm_Mov_RS[nReg] + 0x40;
		*(int*)gpCS = nOffset;
		gpCS += sizeof(int);
	}
}

void _stdcall MovZX(REGISTER nReg, PARAMNO nParmNo)
{
	LPCTYPEINFO lpType = Emit_ParameterRef(nParmNo);
	if (lpType)
		MovZX_Ex(nReg,lpType->nType,lpType->nOffset);
}

void _stdcall MovZX(REGISTER nReg, char *pParmOrVar)
{
	LPCTYPEINFO lpType = Emit_ParmOrVarRef(pParmOrVar);
	if (lpType)
		MovZX_Ex(nReg,lpType->nType,lpType->nOffset);
}

void _stdcall MovZX(char *pVariable, unsigned int nValue)
{

}

void _stdcall MovZX(REGISTER nRegDest, REGISTER nRegSource)
{
	if (nRegDest > R_32BIT)
		*gpCS++ = OP_ADRSIZE_16;

	*gpCS++ = 0x0F;

	if (nRegSource > R_16BIT)
		*gpCS++ = 0xB6;
	else
		*gpCS++ = 0xB7;

	//*gpCS++ = Asm_RegReg[nRegDest][nRegSource];
}

void _stdcall MovSX_Ex(REGISTER nReg, TYPE nType, int nOffset)
{
	
}

void _stdcall Cmp(REGISTER nReg, int nValue)
{
	if (nReg <= R_32BIT)
	{
		if (InByteRange(nValue))
		{
			*gpCS++ = 0x83;
			//*gpCS++ = Asm_Cmp[nReg];
			*gpCS++ = (CODE)nValue;
		}
		else
		{
			if (nReg != EAX)
			{
				*gpCS++ = 0x81;
				//*gpCS++ = Asm_Cmp[nReg];
			}
			else
				*gpCS++ = 0x3D;
			
			*(int*)gpCS = nValue;
			gpCS += sizeof(int);
		}
	}
	else if (nReg <= R_16BIT)
	{
		if (InByteRange(nValue))
		{
			*gpCS++ = OP_ADRSIZE_16;
			if (nReg != AX)
			{
				*gpCS++ = 0x83;
				//*gpCS++ = Asm_Cmp[nReg];
				*gpCS++ = (CODE)nValue;
			}
			else
			{
				*gpCS++ = 0x3D;
				*(short*)gpCS++ = (short)nValue;
				gpCS += sizeof(short);
			}
		}
		else
		{
			*gpCS++ = OP_ADRSIZE_16;
			if (nReg != AX)
			{
				*gpCS++ = 0x81;
				//*gpCS++ = Asm_Cmp[nReg];
				*(short*)gpCS = (short)nValue;
			}
			else
			{
				*gpCS++ = 0x3D;
				*(short*)gpCS = (short)nValue;
			}
			gpCS += sizeof(short);
		}
	}
	else
	{
		if (nReg != AL)
		{
			*gpCS++ = 0x80;
			//*gpCS++ = Asm_Cmp[nReg];
		}
		else
			*gpCS++ = 0x3C;

		*gpCS++ = (CODE)nValue;
	}
}

void _stdcall Cmp(REGISTER nReg, REGISTER nReg2)
{
	if (nReg <= R_32BIT)
	{
		*gpCS++ = 0x3B;
		//*gpCS++ = Asm_RegReg[nReg][nReg2];
	}
	else if (nReg <= R_16BIT)
	{
		*gpCS++ = OP_ADRSIZE_16;
		*gpCS++ = 0x3B;
		//*gpCS++ = Asm_RegReg[nReg][nReg2];
	}
	else
	{
		*gpCS++ = 0x3A;
		//*gpCS++ = Asm_RegReg[nReg][nReg2];
	}
}

void _stdcall Je(char *pLabel)
{
	*gpCS++ = 0x0F;
	*gpCS++ = 0x84;
	Emit_Jump(pLabel);
}

void _stdcall Jmp(char *pLabel)
{
	*gpCS++ = OP_JMP_REL32;
	Emit_Jump(pLabel);
}

/* jump to location in a register */
void _stdcall Jmp(REGISTER nReg)
{
	*gpCS++ = OP_JMP_RM32;
	*gpCS++ = MODRM_REG_OP_REG(MODRM_OP_JMP,nReg);
}

void _stdcall Jmp(REGISTER nReg, AVALUE pLocation)
{
	Mov(nReg,pLocation);
	Jmp(nReg);
}

/* call a function pointer in a register */
void _stdcall Call(REGISTER nReg)
{
	*gpCS++ = OP_CALL_R32;
	*gpCS++ = MODRM_REG_OP_REG(MODRM_OP_CALL,nReg);
}

void _stdcall Call(REGISTER nReg, FUNCPTR pFunction)
{
	Mov(nReg,(AVALUE)pFunction);
	Call(nReg);
}

void _stdcall Call(FUNCPTR pFunction)
{
	Mov(EAX,(AVALUE)pFunction);
	Call(EAX);
}

void _stdcall Ret()
{
	Ret(Emit_ParmSize());
}

void _stdcall Ret(int nBytes)
{
	if (nBytes)
	{
		*gpCS++ = 0xC2;
		*(short*)gpCS = (short)nBytes;
		gpCS += sizeof(short);
	}
	else
		*gpCS++ = 0xC3;
}

void _stdcall Fld_Ex(TYPE nType, int nOffset)
{
	if (nType == T_DOUBLE)
		*gpCS++ = 0xDD;
	else if (nType == T_FLOAT)
		*gpCS++ = 0xD9;
	else
		return;

	if (InByteRange(nOffset))
	{
		*gpCS++ = 0x45;
		*gpCS++ = (CODE)nOffset;
	}
	else
	{
		*gpCS++ = 0x45;
		*(int*)gpCS = nOffset;
		gpCS += sizeof(int);
	}
}

void _stdcall Fld(PARAMNO nParmNo)
{
	LPCTYPEINFO lpType = Emit_ParameterRef(nParmNo);
	if (lpType)
		Fld_Ex(lpType->nType,lpType->nOffset);
}

void _stdcall Fld(char *pParmOrVar)
{
	LPCTYPEINFO lpType = Emit_ParameterRef(pParmOrVar);
	if (lpType)
		Fld_Ex(lpType->nType,lpType->nOffset);
}

void _stdcall Fld(PARAMNO nParmNo, TYPE nType, int nOffset)
{
	LPCTYPEINFO lpType = Emit_ParameterRef(nParmNo);
	if (lpType)
		Fld_Ex(nType,lpType->nOffset + nOffset);
}

void _stdcall Fld(char *pParmOrVar, TYPE nType, int nOffset)
{
	LPCTYPEINFO lpType = Emit_ParameterRef(pParmOrVar);
	if (lpType)
		Fld_Ex(nType,lpType->nOffset + nOffset);
}
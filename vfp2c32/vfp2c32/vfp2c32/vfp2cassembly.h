#ifndef _VFP2CASSEMBLY_H__
#define _VFP2CASSEMBLY_H__

// count of registers
const int R_COUNT	= 24;
const int R_16COUNT	= 16;
const int R_32COUNT	= 8;
const int R_32BIT	= 7;
const int R_16BIT	= 15;

inline bool InByteRange(int nValue) { return (nValue > 0 && nValue < 127) || (nValue < 0 && nValue > -128); }
inline bool InUByteRange(unsigned  int nValue) { return nValue < 256; }

const int ASM_IDENTIFIER_LEN	= 64;
const int ASM_MAX_PARAMS		= 32;
const int ASM_MAX_VARS			= 64;
const int ASM_MAX_LABELS		= 32;
const int ASM_MAX_JUMPS			= 64;
const int ASM_MAX_CODE_BUFFER	= 8192;

const int CTYPE_SIZE	= 0;
const int CTYPE_ALIGN	= 1;
const int CTYPE_SIGN	= 2;

typedef void (_stdcall *FUNCPTR)();
typedef unsigned char *LPCODE;
typedef unsigned char CODE;
typedef void* AVALUE;

typedef enum _REGISTER {
// 32bit Registers
	EAX = 0,
	ECX,
	EDX,
	EBX,
	ESP,
	EBP,
	ESI,
	EDI,
// 16bit Registers
	AX,
	CX, 
	DX,
	BX,
	SP,
	BP,
	SI,
	DI,
// 8bit Registers
	AL,
	BL,
	CL,
	DL,
	DH,
	BH,
	CH,
	AH,
} REGISTER;

typedef enum _RELREGISTER {
	REAX = 0,
	RECX,
	REDX,
	REBX,
	RESP,
	REBP,
	RESI,
	REDI,
} RELREGISTER;

typedef enum _PARAMNO {
	parm1 = 1,
	parm2,
	parm3,
	parm4,
	parm5,
	parm6,
	parm7,
	parm8,
	parm9,
	parm10,
	parm11,
	parm12,
	parm13,
	parm14,
	parm15,
	parm16,
	parm17,
	parm18,
	parm19,
	parm20,
	parm21,
	parm22,
	parm23,
	parm24,
	parm25,
	parm26,
	parm27,
} PARAMNO;

typedef enum _TYPE {
	T_CHAR = 0,
	T_UCHAR,
	T_SHORT,
	T_USHORT,
	T_INT,
	T_UINT,
	T_INT64,
	T_UINT64,
	T_FLOAT,
	T_DOUBLE,
} TYPE;

typedef struct _CTYPEINFO {
	int nSize;
	int nAlign;
	int nOffset;
	BOOL bSign;
	TYPE nType;
	char aName[ASM_IDENTIFIER_LEN];
} CTYPEINFO, *LPCTYPEINFO;

typedef struct _LABEL {
	char aName[ASM_IDENTIFIER_LEN];
	LPCODE pLocation;
} LABEL, *LPLABEL;

// ModR/M byte encoding
// 7   6  5        3  2    0
// Mod    Reg/Opcode  R/M
const CODE MODRM_MOD_REL		= 0;		// 00000000
const CODE MODRM_MOD_DISP8		= 64;		// 01000000
const CODE MODRM_MOD_DISP32		= 128;		// 10000000
const CODE MODRM_MOD_REG		= 192;		// 11000000

// SIB byte (Scale Index Register) encoding
// 7   6  5    3  2   0
// Scale  Index   Base
const CODE SIB_SCALE0	= 0;	// 00000000
const CODE SIB_SCALE2	= 64;	// 01000000
const CODE SIB_SCALE4	= 128;	// 10000000
const CODE SIB_SCALE8	= 192;	// 11000000

// defines to make opcodes
const int MODRM_OP_OFFSET	= 3;

inline CODE MAKE_REG_CODE(REGISTER nReg) { return (CODE)(nReg <= EDI ? nReg : nReg <= DI ? nReg - AX : nReg - AL); }
inline CODE MODRM_REL_REG(REGISTER nReg) { return (MODRM_MOD_REL | MAKE_REG_CODE(nReg)); }
inline CODE MODRM_REL_REG(RELREGISTER nReg) { return (MODRM_MOD_REL | MAKE_REG_CODE((REGISTER)nReg)); }
inline CODE MODRM_REG_REG(REGISTER nReg) { return (MODRM_MOD_REG | MAKE_REG_CODE(nReg)); }
inline CODE MODRM_REG_OP_REG(CODE nOpcode, REGISTER nReg) { return (MODRM_MOD_REG | (nOpcode << MODRM_OP_OFFSET) | MAKE_REG_CODE(nReg)); }
inline CODE MODRM_REG_REG_REG(REGISTER nDest, REGISTER nSource)	{ return (MODRM_MOD_REG | MAKE_REG_CODE(nSource) | (MAKE_REG_CODE(nDest) << MODRM_OP_OFFSET)); }

inline CODE MODRM_DISP32_OP_REG(CODE nOpcode, REGISTER nReg) { return (MODRM_MOD_DISP32 | (nOpcode << MODRM_OP_OFFSET) | MAKE_REG_CODE(nReg)); }
inline CODE MODRM_DISP32_STACK() { return (MODRM_MOD_DISP32 | EBP); }
inline CODE MODRM_DISP32_OP_STACK(CODE nOpcode) { return (MODRM_MOD_DISP32 | (nOpcode << MODRM_OP_OFFSET) | EBP); }
inline CODE MODRM_DISP32_REG_STACK(REGISTER nReg) { return (MODRM_MOD_DISP32 | (MAKE_REG_CODE(nReg) << MODRM_OP_OFFSET) | EBP); }

inline CODE MODRM_DISP8_OP_REG(CODE nOpcode, REGISTER nReg) { return (MODRM_MOD_DISP8 | (nOpcode << MODRM_OP_OFFSET) | MAKE_REG_CODE(nReg)); }
inline CODE MODRM_DISP8_STACK() { return (MODRM_MOD_DISP8 | EBP); }
inline CODE MODRM_DISP8_OP_STACK(CODE nOpcode) { return (MODRM_MOD_DISP8 | (nOpcode << MODRM_OP_OFFSET) | EBP); }
inline CODE MODRM_DISP8_REG_STACK(REGISTER nReg) { return (MODRM_MOD_DISP8 | (MAKE_REG_CODE(nReg) << MODRM_OP_OFFSET) | EBP); }
inline CODE MAKE_OP(CODE nOpcode, REGISTER nReg) { return (nOpcode + MAKE_REG_CODE(nReg)); }

/* Opcodes
r					= any register
r/m					= register or memory operand
imm8,imm16,imm32	= immediate operand of size X
*/
const CODE OP_ADRSIZE_16		= 0x66;		// immediate/register 16 bit prefix

const CODE OP_PUSH_R32			= 0x50;		// PUSH r16 | r32
const CODE OP_PUSH_IMM8			= 0x6A;		// PUSH imm8 - Push sign-extended imm8. Stack pointer is incremented by the size of stack pointer.
const CODE OP_PUSH_IMM32		= 0x68;		// PUSH imm16 | imm32 - Push sign-extended imm16. Stack pointer is incremented by the size of stack pointer.
const CODE OP_PUSH_RM32			= 0xFF;		// PUSH r/m16 | r/m32 - Push r/m16 | r/m32.
const CODE MODRM_OP_PUSH		= 6;		// additional opcode for PUSH in ModRM byte

const CODE OP_POP_R32			= 0x58;		// pop to register

const CODE OP_DEC_RM8			= 0xFE;		// DEC r/m8 - Decrement r/m8 by 1.
const CODE OP_DEC_RM32			= 0xFF;		// DEC r/m16 | r/m32 - Decrement r/m16 by 1.
const CODE OP_DEC_R32			= 0x48;		// DEC r16 | r32 - Decrement r16 by 1.
const CODE MODRM_OP_DEC			= 1;		// additional opcode for DEC in ModRM byte

const CODE OP_INC_RM8			= 0xFE;		// INC r/m8 - Increment r/m byte by 1.
const CODE OP_INC_RM32			= 0xFF;		// INC r/m16 | r/m32 - Increment word/doubleword by 1.
const CODE OP_INC_R32			= 0x40;		// INC r16 | r32 - Increment word/doubleword register by 1.

const CODE OP_ADD_RM8_R8		= 0x00;		// ADD r/m8, r8
const CODE OP_ADD_RM32_R32		= 0x01;		// ADD r/m32, r32
const CODE OP_ADD_R8_RM8		= 0x02;		// ADD r8, r/m8
const CODE OP_ADD_R32_RM32		= 0x03;		// ADD r32, r/m32 | ADD r16, r/m16
const CODE OP_ADD_RM8_IMM8		= 0x80;		// ADD r/m8, imm8 
const CODE OP_ADD_RM32_IMM32	= 0x81;		// ADD r/m32, imm32 | ADD r/m16, imm16
const CODE OP_ADD_R32_IMM8		= 0x83;		// ADD r/m16, imm8 | ADD r/m32, imm8 - Add sign-extended imm8 to r/m16 | r/m32.
const CODE OP_ADD_AL_IMM8		= 0x04;		// ADD AL, imm8
const CODE OP_ADD_AX_IMM16		= 0x05;		// ADD AX, imm16
const CODE OP_ADD_EAX_IMM32		= 0x05;		// ADD EAX, imm32

const CODE OP_SUB_AL_IMM8		= 0x2C;		// SUB AL, imm8 - Subtract imm8 from AL.
const CODE OP_SUB_AX_IMM16		= 0x2D;		// SUB AX, imm16 - Subtract imm16 from AX.
const CODE OP_SUB_EAX_IMM32		= 0x2D;		// SUB EAX, imm32 - Subtract imm32 from EAX.
const CODE OP_SUB_RM8_IMM8		= 0x80;		// SUB r/m8, imm8 - Subtract imm8 from r/m8.
const CODE OP_SUB_R32_IMM32		= 0x81;		// SUB r/m16, imm16 | r/m32, imm32 - Subtract imm16 from r/m16 | imm32 from r/m32.
const CODE OP_SUB_R32_IMM8		= 0x83;		// SUB r/m16, imm8 | r/m32, imm8 - Subtract sign-extended imm8 from r/m16 | r/m32.
const CODE OP_SUB_RM8_R8		= 0x28;		// SUB r/m8, r8 - Subtract r8 from r/m8.
const CODE OP_SUB_RM32_R32		= 0x29;		// SUB r/m16, r16 | r/m32, r32 - Subtract r16 from r/m16 | r32 from r/m32.
const CODE OP_SUB_R8_RM8		= 0x2A;		// SUB r8, r/m8 - Subtract r/m8 from r8.
const CODE OP_SUB_R32_RM32		= 0x2B;		// SUB r16, r/m16 | r/m32 from r32 - Subtract r/m16 from r16 | r/m32 from r32.
const CODE MODRM_OP_SUB			= 5;		// additional opcode for SUB in ModRM byte

const CODE OP_AND_AL_IMM8		= 0x24;		// AND AL, imm8 - AL AND imm8.
const CODE OP_AND_EAX_IMM32		= 0x25;		// AND EAX, imm32 | AND AX, imm16 - EAX AND imm32.
const CODE OP_AND_RM8_IMM8		= 0x80;		// AND r/m8, imm8 - r/m8 AND imm8.
const CODE OP_AND_RM32_IMM32	= 0x81;		// AND r/m16, imm16 | AND r/m32, imm32 - r/m16 AND imm16.
const CODE OP_AND_RM32_IMM8		= 0x83;		// AND r/m16, imm8 | AND r/m32, imm8 - r/m16 AND imm8 (signextended).
const CODE OP_AND_RM8_R8		= 0x20;		// AND r/m8, r8 - r/m8 AND r8.
const CODE OP_AND_RM32_R32		= 0x21;		// AND r/m16, r16 | AND r/m32, r32 - r/m16 AND r16.
const CODE OP_AND_R8_RM8		= 0x22;		// AND r8, r/m8 - r8 AND r/m8.
const CODE OP_AND_R32_RM32		= 0x23;		// AND r16, r/m16 | AND r32, r/m32 - r16 AND r/m16.
const CODE MODRM_OP_AND			= 4;		// additional opcode for AND in ModRM byte

const CODE OP_OR_AL_IMM8		= 0x0C;		// OR AL, imm8 - AL OR imm8.
const CODE OP_OR_EAX_IMM32		= 0x0D;		// OR AX, imm16 | OR EAX, imm32 - EAX OR imm32.
const CODE OP_OR_RM8_IMM8		= 0x80;		// OR r/m8, imm8 - r/m8 OR imm8.
const CODE OP_OR_RM32_IMM32		= 0x81;		// OR r/m16, imm16 | OR r/m32, imm32 - r/m32 OR imm32.
const CODE OP_OR_RM32_IMM8		= 0x83;		// OR r/m16, imm8 | OR r/m32, imm8 - r/m16 OR imm8 (signextended).
const CODE OP_OR_RM8_R8			= 0x08;		// OR r/m8, r8 - r/m8 OR r8.
const CODE OP_OR_RM32_R32		= 0x09;		// OR r/m16, r16 | OR r/m32, r32 - r/m16 OR r16.
const CODE OP_OR_R8_RM8			= 0x0A;		// OR r8, r/m8 - r8 OR r/m8.
const CODE OP_OR_R32_RM32		= 0x0B;		// OR r16, r/m16 | OR r32, r/m32 - r16 OR r/m16.
const CODE MODRM_OP_OR			= 1;		// additional opcode for OR in ModRM byte

const CODE OP_XOR_AL_IMM8		= 0x34;		// XOR AL, imm8 - AL XOR imm8.
const CODE OP_XOR_EAX_IMM32		= 0x35;		// XOR EAX, imm32 | XOR AX, imm16 - EAX XOR imm32.
const CODE OP_XOR_RM8_IMM8		= 0x80;		// XOR r/m8, imm8 - r/m8 XOR imm8.
const CODE OP_XOR_RM32_IMM32	= 0x81;		// XOR r/m16, imm16 - r/m16 XOR imm16.
const CODE OP_XOR_RM32_IMM8		= 0x83;		// XOR r/m32, imm8 - r/m32 XOR imm8 (signextended).
const CODE OP_XOR_RM8_R8		= 0x30;		// XOR r/m8, r8 - r/m8 XOR r8.
const CODE OP_XOR_RM32_R32		= 0x31;		// XOR r/m16, r16 - r/m16 XOR r16.
const CODE OP_XOR_R8_RM8		= 0x32;		// XOR r8, r/m8 - r8 XOR r/m8.
const CODE OP_XOR_R32_RM32		= 0x33;		// XOR r32, r/m32 - r32 XOR r/m32.
const CODE MODRM_OP_XOR			= 6;		// additional opcode for XOR in ModRM byte

const CODE OP_CDQ				= 0x99;

const CODE OP_SHIFT_RM8			= 0xD0;		// SHIFT r/m8, 1 - Multiply r/m8 by 2, once.
const CODE OP_SHIFT_RM8_IMM8	= 0xC0;		// SHIFT r/m8, imm8 - Multiply r/m8 by 2, imm8 times.
const CODE OP_SHIFT_RM32		= 0xD1;		// SHIFT r/m32, 1 - Multiply r/m32 by 2, once.
const CODE OP_SHIFT_RM32_IMM8	= 0xC1;		// SHIFT r/m32, imm8 - Multiply r/m32 by 2, imm8 times.
const CODE MODRM_OP_SAL			= 4;		// additional opcode for SAL in ModRM byte
const CODE MODRM_OP_SAR			= 7;		// additional opcode for SAR in ModRM byte
const CODE MODRM_OP_SHL			= 4;		// additional opcode for SHL in ModRM byte
const CODE MODRM_OP_SHR			= 5;		// additional opcode for SHR in ModRM byte

const CODE OP_LEA_R32_M			= 0x8D;		// LEA r32,m  - Store effective address for m in register r32.

const CODE OP_MOV_RM8_R8		= 0x88;		// MOV r/m8,r8 - Move r8 to r/m8.
const CODE OP_MOV_RM32_R32		= 0x89;		// MOV r/m16,r16 | r/m32,r32 - Move r16 to r/m16 | r32 to r/m32.
const CODE OP_MOV_R8_RM8		= 0x8A;		// MOV r8,r/m8 - Move r/m8 to r8.
const CODE OP_MOV_R32_RM32		= 0x8B;		// MOV r16,r/m16 | r32,r/m32 - Move r/m16 to r16 | r/m32 to r32.
const CODE OP_MOV_R8_IMM8		= 0xB0;		// MOV r8, imm8 - Move imm8 to r8.
const CODE OP_MOV_R32_IMM32		= 0xB8;		// MOV r16, imm16 | r32, imm32 - Move imm16 to r16 | imm32 to r32.
const CODE OP_MOV_RM8_IMM8		= 0xC6;		// MOV r/m8, imm8 - Move imm8 to r/m8.
const CODE OP_MOV_RM32_IMM32	= 0xC7;		// MOV r/m16, imm16 | r/m32, imm32 - Move imm16 to r/m16 | imm32 to r/m32.

const CODE OP_TEST_AL_IMM8		= 0xA8;		// TEST AL, imm8 - AND imm8 with AL; set SF,ZF, PF according to result.
const CODE OP_TEST_EAX_IMM32	= 0xA9;		// TEST EAX, imm32 - AND imm32 with EAX; set SF,ZF, PF according to result.
const CODE OP_TEST_RM8_IMM8		= 0xF6;		// TEST r/m8, imm8 - AND imm8 with r/m8; set SF,ZF, PF according to result.
const CODE OP_TEST_RM32_IMM32	= 0xF7;		// TEST r/m32, imm32 - AND imm32 with r/m32; set SF, ZF, PF according to result.
const CODE OP_TEST_RM8_R8		= 0x84;		// TEST r/m8, r8 - AND r8 with r/m8; set SF, ZF, PF according to result.
const CODE OP_TEST_RM32_R32		= 0x85;		// TEST r/m32, r32 - AND r32 with r/m32; set SF, ZF, PF according to result.

const CODE OP_JMP_REL8			= 0xEB;		// JMP rel8 - Jump short, RIP = RIP + 8-bit displacement
const CODE OP_JMP_REL32			= 0xE9;		// JMP rel16 | rel32 - Jump near, relative, RIP = RIP + 16/32-bit
const CODE OP_JMP_RM32			= 0xFF;		// JMP r/m16 | r/m32 - Jump near, absolute indirect
const CODE MODRM_OP_JMP			= 4;		// additional opcode for JMP in ModRM byte

const CODE OP_CALL_R32			= 0xFF;		// CALL r/m16 | r/m32 Call near, absolute indirect, address given in r/m16 | r/m32.
const CODE MODRM_OP_CALL		= 2;		// additional opcode for CALL in ModRM byte

void _stdcall Emit_Init();
void _stdcall Emit_Write(void *lpAddress);
int _stdcall Emit_CodeSize();

void _stdcall Emit_Prolog();
void _stdcall Emit_Epilog(bool bCDecl = false);

void _stdcall Emit_Parameter(TYPE nType);
void _stdcall Emit_Parameter(char *pParameter, TYPE nType);
void _stdcall Emit_ParameterEx(LPCTYPEINFO lpType, TYPE nType);
LPCTYPEINFO _stdcall Emit_ParameterRef(char *pParameter);
LPCTYPEINFO _stdcall Emit_ParameterRef(PARAMNO nParmNo);

int _stdcall Emit_ParmSize();
void _stdcall Emit_LocalVar(char *pVariable, TYPE nType);
void _stdcall Emit_LocalVar(char *pVariable, int nSize, int nAlignment);
LPCTYPEINFO _stdcall Emit_LocalVarRef(char *pVariable);
LPCTYPEINFO _stdcall Emit_ParmOrVarRef(char *pVariable);
void _stdcall Emit_Label(char *pLabel);
LPLABEL _stdcall Emit_LabelRef(char *pLabel);
void* _stdcall Emit_LabelAddress(char *pLabel);
void _stdcall Emit_Jump(char *pLabel);
void _stdcall Emit_Patch();
void _stdcall Emit_BreakPoint();

void _stdcall Push_Ex(TYPE nType, int nOffset);
void _stdcall Push(REGISTER nReg);
void _stdcall Push(AVALUE nValue);
void _stdcall Push(int nValue);
void _stdcall Push(PARAMNO nParmNo);
void _stdcall Push(char *pParmOrVar);
void _stdcall Push(PARAMNO nParmNo, TYPE nType, int nOffset = 0);
void _stdcall Push(char *pParmOrVar, TYPE nType, int nOffset = 0);

void _stdcall Pop(REGISTER nReg);

void _stdcall Sub(REGISTER nReg, int nBytes);
void _stdcall Sub(REGISTER nReg, unsigned int nBytes);
void _stdcall Sub(REGISTER nReg, REGISTER nReg2);
void _stdcall Add(REGISTER nReg, int nBytes);
void _stdcall Add(REGISTER nReg, unsigned int nBytes);
void _stdcall Add(REGISTER nReg, REGISTER nReg2);
void _stdcall Dec(REGISTER nReg);
void _stdcall Inc(REGISTER nReg);
void _stdcall And(REGISTER nReg, int nValue);
void _stdcall And(REGISTER nReg, REGISTER nReg2);
void _stdcall Or(REGISTER nReg, int nValue);
void _stdcall Or(REGISTER nReg, REGISTER nReg2);
void _stdcall Xor(REGISTER nReg, int nValue);
void _stdcall Xor(REGISTER nReg, REGISTER nReg2);

void _stdcall Cdq();

void _stdcall Shift_Ex(REGISTER nReg, int nBits, int nOpcode);
void _stdcall Sar(REGISTER nReg, int nBits);
void _stdcall Sal(REGISTER nReg, int nBits);
void _stdcall Shl(REGISTER nReg, int nBits);
void _stdcall Shr(REGISTER nReg, int nBits);

void _stdcall Lea_Ex(REGISTER nReg, int nOffset);
void _stdcall Lea(REGISTER nReg, PARAMNO nParmNo, int nOffset = 0);
void _stdcall Lea(REGISTER nReg, char *pParmOrVar, int nOffset = 0);
void _stdcall Mov_Ex(REGISTER nReg, TYPE nType, int nOffset);
void _stdcall Mov(REGISTER nReg, PARAMNO nParmNo);
void _stdcall Mov(REGISTER nReg, char *pParmOrVar);
void _stdcall Mov(REGISTER nReg, PARAMNO nParmNo, TYPE nType, int nOffset = 0);
void _stdcall Mov(REGISTER nReg, char *pParmOrVar, TYPE nType, int nOffset = 0);
void _stdcall Mov(char *pParmOrVar, unsigned int nValue);
void _stdcall Mov(char *pParmOrVar, REGISTER nReg);
void _stdcall Mov(REGISTER nReg, AVALUE nValue);
void _stdcall Mov(REGISTER nRegDest, REGISTER nRegSource);
void _stdcall Mov(RELREGISTER nRelReg, int nSize, int nValue);
void _stdcall MovZX_Ex(REGISTER nReg, TYPE nType, int nOffset);
void _stdcall MovZX(REGISTER nReg, PARAMNO nParmNo);
void _stdcall MovZX(REGISTER nReg, char *pParmOrVar);
void _stdcall MovZX(REGISTER nReg, PARAMNO nParmNo, TYPE nType, int nOffset = 0);
void _stdcall MovZX(REGISTER nReg, char *pParmOrVar, TYPE nType, int nOffset = 0);
void _stdcall MovZX(char *pParmOrVar, REGISTER nReg);
void _stdcall MovZX(REGISTER nRegDest, REGISTER nRegSource);
void _stdcall MovSX_Ex(REGISTER nReg, TYPE nType, int nOffset);
void _stdcall MovSX(REGISTER nReg, PARAMNO nParmNo);
void _stdcall MovSX(REGISTER nReg, char *pParmOrVar);
void _stdcall MovSX(REGISTER nReg, PARAMNO nParmNo, TYPE nType, int nOffset = 0);
void _stdcall MovSX(REGISTER nReg, char *pParmOrVar, TYPE nType, int nOffset = 0);
void _stdcall MovSX(char *pParmOrVar, REGISTER nReg);
void _stdcall MovSX(PARAMNO nParmNo, REGISTER nReg);
void _stdcall MovSX(REGISTER nRegDest, REGISTER nRegSource);
void _stdcall Cmp(REGISTER nReg, int nValue);
void _stdcall Cmp(REGISTER nReg, REGISTER nReg2);

// conditional jumps
void _stdcall Je(char *pLabel);
void _stdcall Jmp(char *pLabel);
void _stdcall Jmp(REGISTER nReg, AVALUE pLocation);
void _stdcall Jmp(REGISTER nReg);

// function invocation
void _stdcall Call(REGISTER nReg, FUNCPTR pFunction);
void _stdcall Call(FUNCPTR pFunction);
void _stdcall Call(REGISTER nReg);
void _stdcall Ret();
void _stdcall Ret(int nBytes);

// FLOATING POINT functions

// Fld -  Pushes a Float Number from the source onto the top of the FPU Stack.
void _stdcall Fld_Ex(TYPE nType, int nOffset);
void _stdcall Fld(PARAMNO nParmNo);
void _stdcall Fld(char *pParmOrVar);
void _stdcall Fld(PARAMNO nParmNo, TYPE nType, int nOffset = 0);
void _stdcall Fld(char *pParmOrVar, TYPE nType, int nOffset = 0);

#endif	// _VFP2CASSEMBLY_H__
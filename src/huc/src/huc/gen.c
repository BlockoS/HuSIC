/*	File gen.c: 2.1 (83/03/20,16:02:06) */
/*% cc -O -c %
 *
 */

#include <stdio.h>
#include <string.h>
#include "defs.h"
#include "data.h"
#include "code.h"
#include "primary.h"
#include "sym.h"

static char *needargs[] = {
	"vreg",
	"vsync",
	"spr_hide", "spr_show",
	"satb_update",
	"map_load_tile",
	NULL
};

/*
 *	gen arg count
 *
 */
void gnargs (char *name, int nb)
{
	char *ptr;
	int   i;

	if (name == NULL)
		return;
	for (i = 0; ; i++) {
		ptr = needargs[i];

		if (ptr == NULL)
			break;
		if (strcmp(name, ptr) == 0) {
			out_ins(I_NARGS, T_VALUE, nb);
			break;
		}
	}
}

/*
 *	return next available internal label number
 *
 */
int getlabel (void )
{
	return (nxtlab++);
}

/*
 *	fetch a static memory cell into the primary register
 */
void getmem (char *sym)
{
	if ((sym[IDENT] != POINTER) & (sym[TYPE] == CCHAR)) {
		if ((sym[STORAGE] & ~WRITTEN) == LSTATIC)
			out_ins(I_LDB, T_LABEL, glint(sym));
		else
			out_ins(I_LDB, T_SYMBOL, (INTPTR_T)(sym + NAME));
	} else {
		if ((sym[STORAGE] & ~WRITTEN) == LSTATIC)
			out_ins(I_LDW, T_LABEL, glint(sym));
		else
			out_ins(I_LDW, T_SYMBOL, (INTPTR_T)(sym + NAME));
	}
}

/*
 *	fetch a hardware register into the primary register
 */
void getio (char *sym)
{
	out_ins(I_CALL, T_LIB, (INTPTR_T)"getvdc");
}
void getvram (char *sym)
{
	out_ins(I_CALL, T_LIB, (INTPTR_T)"readvram");
}

/*
 *	fetch the address of the specified symbol into the primary register
 *
 */
void getloc (char *sym)
{
	int value;

	if ((sym[STORAGE] & ~WRITTEN) == LSTATIC)
		out_ins(I_LDWI, T_LABEL, glint(sym));
	else {
		value = glint(sym) - stkp;
		out_ins_sym(X_LEA_S, T_STACK, value, sym);

//		out_ins(I_LDW, T_STACK, NULL);
//
//		if (value || optimize) {
//			out_ins(I_ADDWI, T_VALUE, value);
//		}
	}
}

/*
 *	store the primary register into the specified static memory cell
 *
 */
void putmem (char *sym)
{
	int code;

	if ((sym[IDENT] != POINTER) & (sym[TYPE] == CCHAR))
		code = I_STB;
	else
		code = I_STW;

	if ((sym[STORAGE] & ~WRITTEN) == LSTATIC)
		out_ins(code, T_LABEL, glint(sym));
	else
		out_ins(code, T_SYMBOL, (INTPTR_T)(sym + NAME));
}

/*
 *	store the specified object type in the primary register
 *	at the address on the top of the stack
 *
 */
void putstk (char typeobj)
{
	if (typeobj == CCHAR)
		out_ins(I_STBPS, (INTPTR_T)NULL, (INTPTR_T)NULL);
	else
		out_ins(I_STWPS, (INTPTR_T)NULL, (INTPTR_T)NULL);
	stkp = stkp + INTSIZE;
}

/*
 *	store the primary register
 *	at the address on the top of the stack
 *
 */
void putio (char *sym)
{
	out_ins(I_JSR, T_LIB, (INTPTR_T)"setvdc");
	stkp = stkp + INTSIZE;
}
void putvram (char *sym)
{
	out_ins(I_JSR, T_LIB, (INTPTR_T)"writevram");
	stkp = stkp + INTSIZE;
}

/*
 *	fetch the specified object type indirect through the primary
 *	register into the primary register
 *
 */
void indirect (char typeobj)
{
	out_ins(I_STW, T_PTR, (INTPTR_T)NULL);
	if (typeobj == CCHAR)
		out_ins(I_LDBP, T_PTR, (INTPTR_T)NULL);
	else {
		out_ins(I_LDWP, T_PTR, (INTPTR_T)NULL);
	}
}

void farpeek(char *ptr)
{
	if (ptr[TYPE] == CCHAR)
		out_ins(I_FGETB, T_SYMBOL, (INTPTR_T)ptr);
	else
		out_ins(I_FGETW, T_SYMBOL, (INTPTR_T)ptr);
}

/*
 *	print partial instruction to get an immediate value into
 *	the primary register
 *
 */
void immed (int type, INTPTR_T data)
{
	out_ins(I_LDWI, type, data);
}

/*
 *	push the primary register onto the stack
 *
 */
void gpush (void )
{
//	out_ins(I_PUSHWZ, T_VALUE, zpstkp);
//	zpstkp = zpstkp - INTSIZE;

	out_ins(I_PUSHW, T_VALUE, INTSIZE);
	stkp = stkp - INTSIZE;
}

/*
 *	push the primary register onto the stack
 *
 */
void gpusharg (int size)
{
	out_ins(I_PUSHW, T_SIZE, size);
	stkp = stkp - size;
}

/*
 *	pop the top of the stack into the secondary register
 *
 */
void gpop (void )
{
	out_ins(I_POPW, (INTPTR_T)NULL, (INTPTR_T)NULL);
	stkp = stkp + INTSIZE;
}

/*
 *	swap the primary register and the top of the stack
 *
 */
void swapstk (void )
{
	out_ins(I_SWAPW, (INTPTR_T)NULL, (INTPTR_T)NULL);
}

/*
 *	call the specified subroutine name
 *
 */
void gcall (char *sname, INTPTR_T nargs)
{
	out_ins_ex(I_CALL, T_SYMBOL, (INTPTR_T)sname, nargs);
}

/*
 *         generate a bank pseudo instruction
 *
 */
void gbank(unsigned char bank, unsigned short offset)
{
	out_ins(I_BANK, T_VALUE, bank);
	out_ins(I_OFFSET, T_VALUE, offset);
}

/*
 *	return from subroutine
 *
 */
void gret (void )
{
	out_ins(I_RTS, (INTPTR_T)NULL, (INTPTR_T)NULL);
}

/*
 *	perform subroutine call to value on top of stack
 *
 */
void callstk (int nargs)
{
	if (nargs <= INTSIZE)
		out_ins(I_CALLS, T_STACK, 0);
	else
		out_ins(I_CALLS, T_STACK, nargs - INTSIZE);

	stkp = stkp + INTSIZE;
}

/*
 *	jump to specified internal label number
 *
 */
void jump (INTPTR_T label)
{
	out_ins(I_LBRA, T_LABEL, label);
}

/*
 *	test the primary register and jump if false to label
 *
 */
void testjump (INTPTR_T label, int ft)
{
	out_ins(I_TSTW, (INTPTR_T)NULL, (INTPTR_T)NULL);
	if (ft)
		out_ins(I_LBNE, T_LABEL, label);
	else
		out_ins(I_LBEQ, T_LABEL, label);
}

/*
 *	modify the stack pointer to the new value indicated
 *      Is it there that we decrease the value of the stack to add local vars ?
 */
int modstk (INTPTR_T newstkp)
{
	INTPTR_T	k;

//	k = galign(newstkp - stkp);
	k = newstkp - stkp;
	if (k) {
		gtext();
		out_ins(I_ADDMI, T_STACK, k);
	}
	return (int)(newstkp);
}

/*
 *	multiply the primary register by INTSIZE
 */
void gaslint (void )
{
	out_ins(I_ASLW, (INTPTR_T)NULL, (INTPTR_T)NULL);
}

/*
 *	divide the primary register by INTSIZE
 */
void gasrint(void )
{
	out_ins(I_ASRW, (INTPTR_T)NULL, (INTPTR_T)NULL);
}

/*
 *	Case jump instruction
 */
void gjcase(void )
{
	out_ins(I_JMP, T_SYMBOL, (INTPTR_T)"__case");
}

/*
 *	add the primary and secondary registers
 *	if lval2 is int pointer and lval is int, scale lval
 */
void gadd (INTPTR_T *lval, INTPTR_T *lval2)
{
	if (dbltest (lval2, lval)) {
		out_ins(I_ASLWS, (INTPTR_T)NULL, (INTPTR_T)NULL);
	}
	out_ins(I_ADDWS, (INTPTR_T)NULL, (INTPTR_T)NULL);
	stkp = stkp + INTSIZE;
}

/*
 *	subtract the primary register from the secondary
 *
 */
void gsub (void )
{
	out_ins(I_SUBWS, (INTPTR_T)NULL, (INTPTR_T)NULL);
	stkp = stkp + INTSIZE;
}

/*
 *	multiply the primary and secondary registers
 *	(result in primary)
 *
 */
void gmult (void )
{
	out_ins(I_JSR, T_LIB, (INTPTR_T)"smul");
	stkp = stkp + INTSIZE;
}

/*
 *	divide the secondary register by the primary
 *	(quotient in primary, remainder in secondary)
 *
 */
void gdiv (void )
{
	out_ins(I_JSR, T_LIB, (INTPTR_T)"sdiv");
	stkp = stkp + INTSIZE;
}

/*
 *	compute the remainder (mod) of the secondary register
 *	divided by the primary register
 *	(remainder in primary, quotient in secondary)
 *
 */
void gmod (void )
{
	out_ins(I_JSR, T_LIB, (INTPTR_T)"smod");
	stkp = stkp + INTSIZE;
}

/*
 *	inclusive 'or' the primary and secondary registers
 *
 */
void gor (void )
{
	out_ins(I_ORWS, (INTPTR_T)NULL, (INTPTR_T)NULL);
	stkp = stkp + INTSIZE;
}

/*
 *	exclusive 'or' the primary and secondary registers
 *
 */
void gxor (void )
{
	out_ins(I_EORWS, (INTPTR_T)NULL, (INTPTR_T)NULL);
	stkp = stkp + INTSIZE;
}

/*
 *	'and' the primary and secondary registers
 *
 */
void gand (void )
{
	out_ins(I_ANDWS, (INTPTR_T)NULL, (INTPTR_T)NULL);
	stkp = stkp + INTSIZE;
}

/*
 *	arithmetic shift right the secondary register the number of
 *	times in the primary register
 *	(results in primary register)
 *
 */
void gasr (void )
{
	out_ins(I_JSR, T_LIB, (INTPTR_T)"asr");
	stkp = stkp + INTSIZE;
}

/*
 *	arithmetic shift left the secondary register the number of
 *	times in the primary register
 *	(results in primary register)
 *
 */
void gasl (void )
{
	out_ins(I_JSR, T_LIB, (INTPTR_T)"asl");
	stkp = stkp + INTSIZE;
}

/*
 *	two's complement of primary register
 *
 */
void gneg (void )
{
	out_ins(I_NEGW, (INTPTR_T)NULL, (INTPTR_T)NULL);
}

/*
 *	one's complement of primary register
 *
 */
void gcom (void )
{
	out_ins(I_COMW, (INTPTR_T)NULL, (INTPTR_T)NULL);
}

/*
 *	convert primary register into logical value
 *
 */
void gbool (void )
{
	out_ins(I_BOOLW, (INTPTR_T)NULL, (INTPTR_T)NULL);
}

/*
 *	logical complement of primary register
 *
 */
void glneg (void )
{
	out_ins(I_NOTW, (INTPTR_T)NULL, (INTPTR_T)NULL);
}

/*
 *	increment the primary register by 1 if char, INTSIZE if
 *      int
 */
void ginc (INTPTR_T * lval)
/* int lval[]; */
{
	if (lval[2] == CINT)
		out_ins(I_ADDWI, T_VALUE, 2);
	else
		out_ins(I_ADDWI, T_VALUE, 1);
}

/*
 *	decrement the primary register by one if char, INTSIZE if
 *	int
 */
void gdec (INTPTR_T *lval)
/* int lval[]; */
{
	if (lval[2] == CINT)
		out_ins(I_SUBWI, T_VALUE, 2);
	else
		out_ins(I_SUBWI, T_VALUE, 1);
}

/*
 *	following are the conditional operators.
 *	they compare the secondary register against the primary register
 *	and put a literl 1 in the primary if the condition is true,
 *	otherwise they clear the primary register
 *
 */

/*
 *	equal
 *
 */
void geq (void )
{
	out_ins(I_JSR, T_LIB, (INTPTR_T)"eq");
	stkp = stkp + INTSIZE;
}

/*
 *	not equal
 *
 */
void gne (void )
{
	out_ins(I_JSR, T_LIB, (INTPTR_T)"ne");
	stkp = stkp + INTSIZE;
}

/*
 *	less than (signed)
 *
 */
/*void glt (int lvl) */
void glt (void)
{
	out_ins(I_JSR,  T_LIB, (INTPTR_T)"lt");
	stkp = stkp + INTSIZE;
}

/*
 *	less than or equal (signed)
 *
 */
void gle (void )
{
	out_ins(I_JSR, T_LIB, (INTPTR_T)"le");
	stkp = stkp + INTSIZE;
}

/*
 *	greater than (signed)
 *
 */
void ggt (void )
{
	out_ins(I_JSR, T_LIB, (INTPTR_T)"gt");
	stkp = stkp + INTSIZE;
}

/*
 *	greater than or equal (signed)
 *
 */
void gge (void )
{
	out_ins(I_JSR, T_LIB, (INTPTR_T)"ge");
	stkp = stkp + INTSIZE;
}

/*
 *	less than (unsigned)
 *
 */
/*void gult (int lvl)*/
void gult (void)
{
	out_ins(I_JSR, T_LIB, (INTPTR_T)"ult");
	stkp = stkp + INTSIZE;
}

/*
 *	less than or equal (unsigned)
 *
 */
void gule (void )
{
	out_ins(I_JSR, T_LIB, (INTPTR_T)"ule");
	stkp = stkp + INTSIZE;
}

/*
 *	greater than (unsigned)
 *
 */
void gugt (void )
{
	out_ins(I_JSR, T_LIB, (INTPTR_T)"ugt");
	stkp = stkp + INTSIZE;
}

/*
 *	greater than or equal (unsigned)
 *
 */
void guge (void )
{
	out_ins(I_JSR, T_LIB, (INTPTR_T)"uge");
	stkp = stkp + INTSIZE;
}

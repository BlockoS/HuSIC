/*	File while.c: 2.1 (83/03/20,16:02:22) */
/*% cc -O -c %
 *
 */

#include <stdio.h>
#include "defs.h"
#include "data.h"
#include "error.h"
#include "gen.h"
#include "io.h"
#include "while.h"

void addwhile (INTPTR_T *ptr)
/*int	ptr[];*/
{
	int	k;

	if (wsptr == WSMAX) {
		error ("too many active whiles");
		return;
	}
	k = 0;
	while (k < WSSIZ)
		*wsptr++ = ptr[k++];
}

void delwhile (void )
{
	if (readwhile ())
		wsptr = wsptr - WSSIZ;
}

INTPTR_T* readwhile (void )
{
	if (wsptr == ws) {
		error ("no active do/for/while/switch");
		return (0);
	} else
		return (wsptr-WSSIZ);
}

INTPTR_T* findwhile (void )
{
	INTPTR_T	*ptr;

	for (ptr = wsptr; ptr != ws;) {
		ptr = ptr - WSSIZ;
		if (ptr[WSTYP] != WSSWITCH)
			return (ptr);
	}
	error ("no active do/for/while");
	return NULL;
}

INTPTR_T* readswitch (void )
{
	INTPTR_T	*ptr;

	ptr = readwhile ();
	if (ptr)
		if (ptr[WSTYP] == WSSWITCH)
			return (ptr);
	return (0);
}

void addcase (INTPTR_T val)
{
	int	lab;

	if (swstp == SWSTSZ)
		error ("too many case labels");
	else {
		swstcase[swstp] = val;
		swstlab[swstp++] = lab = getlabel ();
		gnlabel (lab);
	}
}

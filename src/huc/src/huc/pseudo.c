/*
 * pseudo.c
 */

#include <stdio.h>
#include <string.h>
#include "data.h"
#include "defs.h"
#include "code.h"
#include "error.h"
#include "io.h"
#include "lex.h"
#include "optimize.h"
#include "primary.h"
#include "pseudo.h"
#include "sym.h"


/* local array to store internal strings */
static char str_buf[0x10000];
static int  str_idx;

/* protos */
char *new_string(int und, char *a);
void  do_inc_ex(int type);

/* extern protos */
void add_buffer(char *p, char c);
void new_const(void);
void add_const(int typ);


/*
 * This source file includes all kind of stuff used to 'simulate' pseudo code
 * of the magic kit and so using itself pseudo C functions...
 */

void dopsdinc(void)
{
 INTPTR_T dummy; /* Used in the qstr function, I don't know its utility yet */
 int numericarg = 0; /* Number of numeric arg to test validity */

 if (amatch("pal",3))
   {
    if (!match("("))
      error("missing (");

    ol(".data");
    ol(".dw $0");

    readstr(); /* read the label name */
    prefix();
    outstr(litq2);
    outstr(":\n");
	addglb_far(litq2, CINT);

    if (!match(","))
      {
        error("missing ,");
        kill_line();
        return;
      }

    ot(".incpal \"");

    if (readqstr() == 0)  /* read the filename */
    {
       error("bad filename in incpal");
       kill_line();
       return;
    }

    outstr(litq2);
    outstr("\"");

    if (match(","))
      outstr(",");

    numericarg = 0;

    while (!match(")"))
      {
       numericarg++;

       number(&dummy);
       outdec(dummy);
       if (match(","))
         outstr(",");

       }

    newl();
    ol(".code");

    if (numericarg>2)
      error("Maximum 2 numeric arg for incpal(name,\"filename\" [,start_pal] [,nb_pal])");

    kill_line();

    }
 else
 if (amatch("bin",3))
   {
    if (!match("("))
      error("missing (");

    ol(".data");
    ol(".dw $0");

    readstr(); /* read the label name */
    prefix();
    outstr(litq2);
    outstr(":\n");
	addglb_far(litq2, CCHAR);

    if (!match(",")) {
        error("missing ,");
        kill_line();
        return;
    }

    ot(".incbin \"");
    if (readqstr() == 0)   /* read the filename */
    {
       error("bad filename in incbin");
       kill_line();
       return;
    }
    outstr(litq2);
    outstr("\"\n");

    if (!match(")"))
      error("missing )");

    newl();
    ol(".code");
    kill_line();
   }
 else
 if (amatch("bat",3))
   {

    if (!match("("))
      error("missing (");

    ol(".data");
    ol(".dw $0");

    readstr(); /* read the label name */
    prefix();
    outstr(litq2);
    outstr(":\n");
	addglb_far(litq2, CINT);

    if (!match(","))
      {
        error("missing ,");
        kill_line();
        return;
      }

    ot(".incbat \"");

    if (readqstr() == 0)
    {
       error("bad filename in incbat");
       kill_line();
       return;
    }

    outstr(litq2);
    outstr("\"");

    if (match(","))
      outstr(",");

    numericarg = 0;

    while (!match(")"))
      {
       numericarg++;

       number(&dummy);
       outdec(dummy);
       if (match(","))
         outstr(",");

       }

    newl();
    ol(".code");

    if ((numericarg!=1) &&
        (numericarg!=3) &&
        (numericarg!=5))
      error("Either 1,3 or 5 numeric arguments are needed for incbat statement");

    kill_line();

    }
 else
 if (amatch("spr",3))
   {

    if (!match("("))
      error("missing (");

    ol(".data");
    ol(".dw $0");

    readstr(); /* read the label name */
    prefix();
    outstr(litq2);
    outstr(":\n");
	addglb_far(litq2, CINT);

    if (!match(","))
      {
        error("missing ,");
        kill_line();
        return;
      }

    ot(".incspr \"");

    if (readqstr() == 0)
    {
       error("bad filename in incspr");
       kill_line();
       return;
    }

    outstr(litq2);
    outstr("\"");

    if (match(","))
      outstr(",");

    numericarg = 0;

    while (!match(")"))
      {
       numericarg++;

       number(&dummy);
       outdec(dummy);
       if (match(","))
         outstr(",");

       }

    newl();
    ol(".code");

    if ((numericarg!=0) &&
        (numericarg!=2) &&
        (numericarg!=4))
      error("Either 0,2 or 4 numeric arguments are needed for incspr statement");

    kill_line();

    }
 else
 if (amatch("chr",3))
   {

    if (!match("("))
      error("missing (");

    ol(".data");
    ol(".dw $0800");

    readstr(); /* read the label name */
    prefix();
    outstr(litq2);
    outstr(":\n");
	addglb_far(litq2, CINT);

    if (!match(","))
      {
        error("missing ,");
        kill_line();
        return;
      }

    ot(".incchr \"");

    if (readqstr() == 0)
    {
       error("bad filename in incchr");
       kill_line();
       return;
    }

    outstr(litq2);
    outstr("\"");

    if (match(","))
      outstr(",");

    numericarg = 0;

    while (!match(")"))
      {
       numericarg++;

       number(&dummy);
       outdec(dummy);
       if (match(","))
         outstr(",");

       }

    newl();
    ol(".code");

    if ((numericarg!=0) &&
        (numericarg!=2) &&
        (numericarg!=4))
      error("Either 0,2 or 4 numeric arguments are needed for incchr statement");

    kill_line();

   }
 else
 if (amatch("chr_ex",6))
   {
	do_inc_ex(8);
   }
 else
 if (amatch("tile",4))
   {

    if (!match("("))
      error("missing (");

    ol(".data");
    ol(".dw $1000");

    readstr(); /* read the label name */
    prefix();
    outstr(litq2);
    outstr(":\n");
	addglb_far(litq2, CINT);

    if (!match(","))
      {
        error("missing ,");
        kill_line();
        return;
      }

    ot(".inctile \"");

    if (readqstr() == 0)
    {
       error("bad filename in inctile");
       kill_line();
       return;
    }

    outstr(litq2);
    outstr("\"");

    if (match(","))
      outstr(",");

    numericarg = 0;

    while (!match(")"))
      {
       numericarg++;

       number(&dummy);
       outdec(dummy);
       if (match(","))
         outstr(",");

       }

    newl();
    ol(".code");

    if ((numericarg!=0) &&
        (numericarg!=2) &&
        (numericarg!=4))
      error("Either 0,2 or 4 numeric arguments are needed for inctile statement");

    kill_line();

    }
 else
 if (amatch("tile_ex",7))
   {
	do_inc_ex(16);
   }
 else
   {
    error("Unknown include directive");
    kill_line();
    }
 return;
}


void dopsddef(void)
{
  int numericarg = 0;
  INTPTR_T dummy;
  INTPTR_T dummy_array[16];
  int i;

  if (amatch("pal",3))
   {

    if (!match("("))
      error("missing (");

    readstr(); /* read the label name */
    addglb_far(litq2, CINT);

    if (!match(","))
      {
        error("missing ',' in #defpal");
        kill_line();
        return;
      }

    numericarg = 0;

    while (!match(")"))
    {
       number(&dummy_array[numericarg]);
       numericarg++;

       if (numericarg>16)
         error("No more than 16 colors can be defined at once");

       match(",");
    }

    ol(".data");
    prefix();
    outstr(litq2);
    outstr(":");
    ot(".defpal ");

    for (i = 0; i < numericarg; i++)
    {
       outhexfix(dummy_array[i],3);

       if (i < numericarg - 1)
       {
          outstr(",");
          if (i == 7)
          {
             outstr(" \\\n");
             ot("\t");
          }
       }
    }

    newl();
    ol(".code");

    kill_line();

    }
  else
 if (amatch("chr",3))
   {

    if (!match("("))
      error("missing (");

    ol(".data");

    readstr(); /* read the label name */
    prefix();
    outstr(litq2);
    outstr(":");
	addglb_far(litq2, CINT);

    if (!match(","))
      {
        error("missing ,");
        kill_line();
        return;
      }

    ot(".defchr ");

    numericarg = 0;

    while (!match(")"))
      {
       numericarg++;

       number(&dummy);

       switch (numericarg)
         {
          case 1:
               outhexfix(dummy,4);
               outstr(",");
               break;
          case 2:
               outdec(dummy);
               outstr(",\\");
               newl();
               break;
          case 10:
               outhexfix(dummy,8);
               break;
          default:
       	       outhexfix(dummy,8);
               outstr(",\\");
               newl();

          }

         match(",");

       }

    newl();
    ol(".code");

    if (numericarg!=10)
      error("You must enter the VRAM address, the default palette and 8 values for pattern");

    kill_line();

    }
  else
 if (amatch("spr",3))
   {

    if (!match("("))
      error("missing (");

    ol(".data");

    readstr(); /* read the label name */
    prefix();
    outstr(litq2);
    outstr(":");
	addglb_far(litq2, CINT);

    if (!match(","))
      {
        error("missing ,");
        kill_line();
        return;
      }

    ot(".defspr ");

    numericarg = 0;

    while (!match(")"))
      {
       numericarg++;

       number(&dummy);

       switch (numericarg)
         {
          case 1:
               outhexfix(dummy,4);
               outstr(",");
               break;
          case 2:
               outdec(dummy);
               outstr(",\\");
               newl();
               break;
          case 34:
               outhexfix(dummy,8);
               break;
          default:
       	       outhexfix(dummy,8);
               outstr(",");

               if (!(numericarg & 1))
                 {
                  outstr("\\");
                  newl();
                 }

          }

       match(",");

       }

    newl();
    ol(".code");

    if (numericarg!=34)
      error("You must enter the VRAM address, the default palette and 32 values for pattern");

    kill_line();

    }
  else
    {
      error("Unknown define directive");
      kill_line();
    }
 return;
 }


int outcomma(void)
{

   if (!match(","))
    {
      error("missing ,");
      kill_line();
      return 1;
    }

  outbyte(',');

  return 0;

 }

int outnameunderline(void)
{
  char	n[NAMESIZE];

  if (!symname(n))
    {
      error("invalid identifier");
      kill_line();
      return 1;
     }

  prefix();
  outstr(n);

  return 0;

 }

int outconst(void)
{

  INTPTR_T dummy;

  number(&dummy);
  outbyte('#');
  outdec(dummy);

  return 0;

 }

void doset_bgpalstatement(void)
{ /* syntax is
     number of the first palette to alter : integer
     name of the data for loading palettes : identifier
     [ number of palette to load : integer ]
     if last argument is missing, 1 is assumed
   */

  flush_ins();  /* David, optimize.c related */
  ot("_set_bgpal\t");

  outconst();
  if (outcomma())		return;
  if (outnameunderline())	return;
  if (!match(","))
    {
     outstr(",#");
     outdec(1);
    }
  else
    {
      outbyte(',');
      outconst();
    }

  newl();
  needbrack(")");
}

void doset_sprpalstatement(void)
{ /* syntax is
     number of the first palette to alter : integer
     name of the data for loading palettes : identifier
     [ number of palette to load : integer ]
     if last argument is missing, 1 is assumed
   */

  flush_ins();  /* David, optimize.c related */
  ot("_set_sprpal\t");

  outconst();
  if (outcomma())		return;
  if (outnameunderline())	return;
  if (!match(","))
    {
     outstr(",#");
     outdec(1);
    }
  else
    {
      outbyte(',');
      outconst();
    }

  newl();
  needbrack(")");
}


void doload_spritesstatement(void)
{ /* syntax is
     offset in vram to load data at : integer
     name of the data to transfert : identifier
     number of sprites (of size 32x64) to load : integer
   */
  flush_ins();  /* David, optimize.c related */
  ot("load_sprites\t");

  outconst();
  if (outcomma())		return;
  if (outnameunderline())	return;
  if (!match(","))
    {
     outstr(",#");
     outdec(1);
    }
  else
    {
      outbyte(',');
      outconst();
    }

  newl();
  needbrack(")");

 }

void doload_backgroundstatement(void)
{ /* syntax is
     name of the beginning of the data pattern : identifier
     name of the 16 palettes : identifier
     name of the bat : identifier
     width (in tiles [8x8] ) : integer
     height (in tiles [8x8] ) : integer
   */

  flush_ins();  /* David, optimize.c related */
  ot("_load_background\t");

  if (outnameunderline())	return;
  if (outcomma())		return;

  if (outnameunderline())	return;
  if (outcomma())		return;

  if (outnameunderline())	return;
  if (outcomma())		return;

  if (outconst())		return;
  if (outcomma())		return;

  if (outconst())		return;

  newl();
  needbrack(")");

 }

void
do_asm_func(int type)
{	/* syntax is
	   name of the data : identifier
	 */
	char  n[NAMESIZE];
	char *ptr;

	/* get identifier */ 
	if (!symname(n)) {
		error("invalid identifier");
		kill_line();
		return;
	}

	/* close function */
	needbrack(")");

	/* duplicate identifier */
	ptr = new_string(1, n);

	/* gen code */
	if (ptr)
		out_ins(I_LDWI, type, (INTPTR_T)ptr);
	else
		error("out of memory");
}

char *
new_string(int und, char *a)
{
	INTPTR_T len;
	int tmp;

	if (a == NULL)
		return (NULL);
	len = strlen(a);
	tmp = str_idx;
	if((len + str_idx) > 0xFFF0)
		return (NULL);
	if (und)
		str_buf[str_idx++] = '_';
	strcpy(&str_buf[str_idx], a);
	str_idx += len;
	str_buf[str_idx++] = '\0';
	return (&str_buf[tmp]);
}

void
do_inc_ex(int type)
{
	int end;
	int i;
	INTPTR_T j;
	int num;
	int nb_tile;
	char label[NAMESIZE];
	char label2[NAMESIZE];
	char str[NAMESIZE+32];
	struct {
		char fname[FILENAMESIZE];
		INTPTR_T  arg[5];
	} tiles[16];

	if(!match("(")) {
		error("missing '('");
		kill_line();
		return;
	}

	readstr(); /* read the label name */
	strcpy(label, litq2);
	strcpy(label2, litq2);
	strcpy(str, "__data__");
	for(i = (int)strlen(label2), j = 0; i < NAMEMAX; i++)
		label2[i] = str[j++];
	label2[i] = '\0';
	addglb(label2, ARRAY, CINT, 0, EXTERN);
	addglb(label, ARRAY, CINT, 0, EXTERN);

	if(!match(",")) {
		error("comma missing");
		kill_line();
		return;
	}

	end = 0;
	num = 0;
	nb_tile = 0;
	while (!end) {
		// if (match("\\"));
	    if(!readqstr()) {
			error("not a file name");
			kill_line();
			return;
		}
		if(!match(",")) {
			error("comma missing");
			kill_line();
			return;
		}
		strcpy(tiles[num].fname, litq2);

		for (i = 0; i < 5; i++) {
			// if (match("\\"));
			if(!number(&tiles[num].arg[i])) {
				error("not a number");
				kill_line();
				return;
			}
			if (match(")")) {
				if (i == 4) {
					kill_line();
					end = 1;
					break;
				}
				else {
					error("arg missing");
					kill_line();
					return;
				}
			}
			if(!match(",")) {
				error("comma missing");
				kill_line();
				return;
			}
			while((ch() == ' ') || (ch() == '\t'))
				gch();
			if (ch() == '\0') {
				error("arg missing");
				kill_line();
				return;
			}
		}
		nb_tile += tiles[num].arg[2] * tiles[num].arg[3];
		num++;
		if (num == 16) {
			if(!end) {
				error("too many args (max 16 files)");
				kill_line();
				return;
			}
		}
	}

	/* create const array to hold extra infos */
	new_const();
	const_val[const_val_idx++] = const_data_idx;	/* number of tile */
	sprintf(str, "%i", nb_tile);
	add_buffer(str, '(');
	const_data[const_data_idx++] = '\0';
	const_val[const_val_idx++] = const_data_idx;	/* tile size */
	sprintf(str, "%i", type);
	add_buffer(str, '(');
	const_data[const_data_idx++] = '\0';
	const_val[const_val_idx++] = const_data_idx;	/* tile bank */
	sprintf(str, "BANK(_%s)", label2);
	add_buffer(str, '(');
	const_data[const_data_idx++] = '\0';
	const_val[const_val_idx++] = const_data_idx;	/* tile addr */
	sprintf(str, "     _%s", label2);
	add_buffer(str, '(');
	const_data[const_data_idx++] = '\0';
	const_val[const_val_idx++] = -(litptr + 1024);	/* pal idx table addr */
	add_const(CINT);

	/* create pal idx table */
	for(i = 0; i < num; i++) {
		j = tiles[i].arg[2] * tiles[i].arg[3];
		while (j) {
			j--;
			if (litptr < LITMAX)
				litq[litptr++] = (tiles[i].arg[4] << 4);
		}
	}

	/* dump incchr/tile cmds */
	ol(".data");
	if (type == 8)
		ol(".dw $0800");
	else
		ol(".dw $1000");
	prefix();
	outstr(label2);
	outstr(":\n");
	for(i = 0; i < num; i++) {
		if (type == 8)
			ot(".incchr \"");
		else
			ot(".inctile \"");
		outstr(tiles[i].fname);
		outstr("\"");
		for (j = 0; j < 4; j++) {
			outstr(",");
			outdec(tiles[i].arg[j]);
		}
		newl();
	}
	ol(".code");
	kill_line();
}


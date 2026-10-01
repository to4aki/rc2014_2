>>> STDIO.H 296
/*
** STDIO.H -- Standard Small-C Definitions
*/
#define stdin    0
#define stdout   1
#define stderr   2
#define ERR   (-2)
#define EOF   (-1)
#define YES      1
#define NO       0
#define NULL     0
#define CR      13
#define LF      10
#define BELL     7
#define SPACE  ' '
#define NEWLINE LF
>>> NOTICE.H 99
#define VERSION "Version 2.1 (Rev. 67)\n"
#define CRIGHT1 "Copyright 1982, 1983 J. E. Hendrix\n\n"
>>> CC.DEF 2770
/*
** Small-C Compiler Symbol Definitions
*/

/*
** compile options
*/
#define NOCCARGC	/* no argument counts */
#define SEPARATE	/* compile separately */
#define OPTIMIZE	/* compile output optimizer */
#define DYNAMIC 	/* allocate memory dynamically */
#define COL		/* terminate labels with a colon */
/* #define UPPER	/* force symbols to upper case */
#define LINK		/* will use with linking loader */

/*
** machine dependent parameters
*/
#define BPW     2	/* bytes per word */
#define LBPW    1	/* log2(BPW) */
#define SBPC    1	/* stack bytes per character */
#define ERRCODE 7	/* op sys return code */
 
/*
** symbol table format
*/
#define IDENT    0
#define TYPE     1
#define CLASS    2
#define OFFSET   3
#define NAME     5
#define OFFSIZE (NAME-OFFSET)
#define SYMAVG  10
#define SYMMAX  14

/*
** symbol table parameters
*/
#define NUMLOCS   25
#define STARTLOC  symtab
#define ENDLOC   (symtab+(NUMLOCS*SYMAVG))
#define NUMGLBS   200
#define STARTGLB  ENDLOC
#define ENDGLB   (ENDLOC+((NUMGLBS-1)*SYMMAX))
#define SYMTBSZ   3050  /* NUMLOCS*SYMAVG + NUMGLBS*SYMMAX */
 
/*
** System wide name size (for symbols)
*/
#define NAMESIZE 9
#define NAMEMAX  8
 
/*
** possible entries for "IDENT"
*/
#define LABEL    0
#define VARIABLE 1
#define ARRAY    2
#define POINTER  3
#define FUNCTION 4
 
/*
** possible entries for "TYPE"
**    low order 2 bits make type unique within length
**    high order bits give length of object
*/
/*      LABEL   0 */
#define CCHAR   (1<<2)
#define CINT    (BPW<<2)
 
/*
** possible entries for "CLASS"
*/
/*      LABEL     0 */
#define STATIC    1
#define AUTOMATIC 2
#define EXTERNAL  3
#define AUTOEXT   4

/*
** "switch" table
*/
#define SWSIZ   (2*BPW)
#define SWTABSZ (60*SWSIZ)
 
/*
** "while" statement queue
*/
#define WQTABSZ  30
#define WQSIZ     3
#define WQMAX   (wq+WQTABSZ-WQSIZ)
 
/*
** entry offsets in while queue
*/
#define WQSP    0
#define WQLOOP  1
#define WQEXIT  2
 
/*
** literal pool
*/
#define LITABSZ 800
#define LITMAX  (LITABSZ-1)
 
/*
** input line
*/
#define LINEMAX  127
#define LINESIZE 128

/*
** output staging buffer size
*/
#define STAGESIZE   800
#define STAGELIMIT  (STAGESIZE-1)
 
/*
** macro (define) pool
*/
#define MACNBR   130
#define MACNSIZE (MACNBR*(NAMESIZE+2))
#define MACNEND  (macn+MACNSIZE)
#define MACQSIZE (MACNBR*7)
#define MACMAX   (MACQSIZE-1)
 
/*
** statement types
*/
#define STIF      1
#define STWHILE   2
#define STRETURN  3
#define STBREAK   4
#define STCONT    5
#define STASM     6
#define STEXPR    7
#define STDO      8	/* compile "do" logic */
#define STFOR     9	/* compile "for" logic */
#define STSWITCH 10	/* compile "switch/case/default" logic */
#define STCASE   11
#define STDEF    12
#define STGOTO   13	/* compile "goto" logic */
#define STLABEL  14
>>> CC1.C 3299
/*
** Small-C Compiler Part 1
*/
#include <stdio.h>
#include "notice.h"
#include "cc.def"

/*
** miscellaneous storage
*/
char
#ifdef OPTIMIZE
  optimize,	/* optimize output of staging buffer */
#endif
  alarm,	/* audible alarm on errors? */
  monitor,	/* monitor function headers? */
  pause,	/* pause for operator on errors? */
#ifdef DYNAMIC
 *stage,	/* output staging buffer */
 *symtab,	/* symbol table */
 *litq,		/* literal pool */
 *macn,		/* macro name buffer */
 *macq,		/* macro string buffer */
 *pline,	/* parsing buffer */
 *mline,	/* macro buffer */
#else
  stage[STAGESIZE],
  symtab[SYMTBSZ],
  litq[LITABSZ],
  macn[MACNSIZE],
  macq[MACQSIZE],
  pline[LINESIZE],
  mline[LINESIZE],
  swq[SWTABSZ],
#endif
 *line,		/* points to pline or mline */
 *lptr,		/* ptr to either */
 *glbptr,	/* ptrs to next entries */
 *locptr,	/* ptr to next local symbol */
 *stagenext,	/* next addr in stage */
 *stagelast,	/* last addr in stage */
  quote[2],	/* literal string for '"' */
 *cptr,		/* work ptrs to any char buffer */
 *cptr2,
 *cptr3,
  msname[NAMESIZE],	/* macro symbol name array */
  ssname[NAMESIZE];	/* static symbol name array */
int
#ifdef STGOTO
  nogo,		/* > 0 disables goto statements */
  noloc,	/* > 0 disables block locals */
#endif
  op[16],	/* function addresses of binary operators */
  op2[16],	/* same for unsigned operators */
  opindex,	/* index to matched operator */
  opsize,	/* size of operator in bytes */
  swactive,	/* true inside a switch */
  swdefault,	/* default label #, else 0 */
 *swnext,	/* address of next entry */
 *swend,	/* address of last table entry */
#ifdef DYNAMIC
 *wq,		/* while queue */
#else
  wq[WQTABSZ],
#endif
  argcs,	/* static argc */
 *argvs,	/* static argv */
 *wqptr,	/* ptr to next entry */
  litptr,	/* ptr to next entry */
  macptr,	/* macro buffer index */
  pptr,		/* ptr to parsing buffer */
  oper,		/* address of binary operator function */
  ch,		/* current character of line being scanned */
  nch,		/* next character of line being scanned */
  declared,	/* # of local bytes declared, else -1 when done */
  iflevel,	/* #if... nest level */
  skiplevel,	/* level at which #if... skipping started */
  func1,	/* true for first function */
  nxtlab,	/* next avail label # */
  litlab,	/* label # assigned to literal pool */
  beglab,	/* beginning label -- first function */
  csp,		/* compiler relative stk ptr */
  argstk,	/* function arg sp */
  argtop,
  ncmp,		/* # open compound statements */
  errflag,	/* non-zero after 1st error in statement */
  eof,		/* set non-zero on final input eof */
  input,	/* fd # for input file */
  input2,	/* fd # for "include" file */
  output,	/* fd # for output file */
  files,	/* non-zero if file list specified on cmd line */
  filearg,	/* cur file arg index */
  glbflag,	/* non-zero if internal globals */
  ctext,	/* non-zero to intermix c-source */
  ccode,	/* non-zero while parsing c-code */
		/* zero when passing assembly code */
  listfp,	/* file pointer to list device */
  lastst,	/* last executed statement type */
 *iptr;		/* work ptr to any int buffer */

#include "cc11.c"
#include "cc12.c"
#include "cc13.c"

#ifndef SEPARATE
#include "cc21.c"
#include "cc22.c"
#include "cc31.c"
#include "cc32.c"
#include "cc33.c"
#include "cc41.c"
#include "cc42.c"
#endif
>>> CC11.C 5409
/*
** execution begins here
*/
main(argc, argv) int argc, *argv; {
  argcs=argc;
  argvs=argv;
  fputs("Small-C Compiler, ", stderr); fputs(VERSION, stderr);
  fputs(CRIGHT1, stderr);
#ifdef DYNAMIC
  swnext=calloc(SWTABSZ, 1);
  swend=swnext+((SWTABSZ-SWSIZ)>>1);
  stage=calloc(STAGESIZE, 1);
  stagelast=stage+STAGELIMIT;
  wq=calloc(WQTABSZ, BPW);
  litq=calloc(LITABSZ, 1);
  macn=calloc(MACNSIZE, 1);
  macq=calloc(MACQSIZE, 1);
  pline=calloc(LINESIZE, 1);
  mline=calloc(LINESIZE, 1);
#else
  swend=(swnext=swq)+SWTABSZ-SWSIZ;
  stagelast=stage+STAGELIMIT;
#endif
  swactive=		/* not in switch */
  stagenext=		/* direct output mode */
  iflevel=		/* #if... nesting level = 0 */
  skiplevel=		/* #if... not encountered */
  macptr=		/* clear the macro pool */
  csp=			/* stack ptr (relative) */
  errflag=		/* not skipping errors till ";" */
  eof=			/* not eof yet */
  ncmp=			/* not in compound statement */
  files=
  filearg=
  quote[1]=0;
  func1=		/* first function */
  ccode=1;		/* enable preprocessing */
  wqptr=wq;		/* clear while queue */
  quote[0]='"';		/* fake a quote literal */
  input=input2=EOF;
  ask();		/* get user options */
  openfile();		/* and initial input file */
  preprocess();		/* fetch first line */
#ifdef DYNAMIC
  symtab=calloc((NUMLOCS*SYMAVG + NUMGLBS*SYMMAX), 1);
#endif
  locptr=STARTLOC;
  glbptr=STARTGLB;
  glbflag=1;
  ctext=0;
  header();		/* intro code */
  setops();		/* set values in op arrays */
  parse();		/* process ALL input */
  outside();		/* verify outside any function */
  trailer();		/* follow-up code */
  fclose(output);
  }

/*
** process all input text
**
** At this level, only static declarations,
**      defines, includes and function
**      definitions are legal...
*/
parse() {
  while (eof==0) {
    if(amatch("extern", 6))   dodeclare(EXTERNAL);
    else if(dodeclare(STATIC));
    else if(match("#asm"))    doasm();
    else if(match("#include"))doinclude();
    else if(match("#define")) addmac();
    else                      newfunc();
    blanks();		/* force eof if pending */
    }
  }

/*
** dump the literal pool
*/
dumplits(size) int size; {
  int j, k;
  k=0;
  while (k<litptr) {
    poll(1);		/* allow program interruption */
    defstorage(size);
    j=10;
    while(j--) {
      outdec(getint(litq+k, size));
      k=k+size;
      if ((j==0)|(k>=litptr)) {nl(); break;}
      outbyte(',');
      }
    }
  }

/*
** dump zeroes for default initial values
*/
dumpzero(size, count) int size, count; {
  int j;
  while (count > 0) {
    poll(1);		/* allow program interruption */
    defstorage(size);
    j=30;
    while(j--) {
      outdec(0);
      if ((--count <= 0)|(j==0)) {nl(); break;}
      outbyte(',');
      }
    }
  }

/*
** verify compile ends outside any function
*/
outside()  {
  if (ncmp) error("no closing bracket");
  }

/*
** get run options
*/
ask() {
  int i;
  i=listfp=nxtlab=0;
  output=stdout;
#ifdef OPTIMIZE
  optimize=
#endif
  alarm=monitor=pause=NO;
  line=mline;
  while(getarg(++i, line, LINESIZE, argcs, argvs)!=EOF) {
    if(line[0]!='-') continue;
    if((toupper(line[1])=='L')&(isdigit(line[2]))&(line[3]<=' ')) {
      listfp=line[2]-'0';
      continue;
      }
    if(line[2]<=' ') {
      if(toupper(line[1])=='A') {
        alarm=YES;
        continue;
        }
      if(toupper(line[1])=='M') {
        monitor=YES;
        continue;
        }
#ifdef OPTIMIZE
      if(toupper(line[1])=='O') {
        optimize=YES;
        continue;
        }
#endif
      if(toupper(line[1])=='P') {
        pause=YES;
        continue;
        }
      }
#ifndef LINK
    if(toupper(line[1])=='B') {
      bump(0); bump(2);
      if(number(&nxtlab)) continue;
      }
#endif
    sout("usage: cc [file]... [-m] [-a] [-p] [-l#]", stderr);
#ifdef OPTIMIZE
    sout(" [-o]", stderr);
#endif
#ifndef LINK
    sout(" [-b#]", stderr);
#endif
    sout(NEWLINE, stderr);
    abort(ERRCODE);
    }
  }

/*
** input and output file opens
*/
openfile() {		/* entire function revised */
  char outfn[15];
  int i, j, ext;
  input=EOF;
  while(getarg(++filearg, pline, LINESIZE, argcs, argvs)!=EOF) {
    if(pline[0]=='-') continue;
    ext = NO;
    i = -1;
    j = 0;
    while(pline[++i]) {
      if(pline[i] == '.') {ext = YES; break;}
      if(j < 10) outfn[j++] = pline[i];
      }
    if(!ext) {
      strcpy(pline + i, ".C");
      }
    input = mustopen(pline, "r");
    if(!files && isatty(stdout)) {
      strcpy(outfn + j, ".MAC");
      output = mustopen(outfn, "w");
      }
    files=YES;
    kill();
    return;
    }
  if(files++) eof=YES;
  else input=stdin;
  kill();
  }

/*
** open a file with error checking
*/
mustopen(fn, mode) char *fn, *mode; {
  int fd;
  if(fd = fopen(fn, mode)) return fd;
  sout("open error on ", stderr);
  lout(fn, stderr);
  abort(ERRCODE);
  }

setops() {
  op2[ 0]=     op[ 0]=  ffor;		/* heir5 */
  op2[ 1]=     op[ 1]= ffxor;		/* heir6 */
  op2[ 2]=     op[ 2]= ffand;		/* heir7 */
  op2[ 3]=     op[ 3]=  ffeq;		/* heir8 */
  op2[ 4]=     op[ 4]=  ffne;
  op2[ 5]=ule; op[ 5]=  ffle;		/* heir9 */
  op2[ 6]=uge; op[ 6]=  ffge;
  op2[ 7]=ult; op[ 7]=  fflt;
  op2[ 8]=ugt; op[ 8]=  ffgt;
  op2[ 9]=     op[ 9]= ffasr;		/* heir10 */
  op2[10]=     op[10]= ffasl;
  op2[11]=     op[11]= ffadd;		/* heir11 */
  op2[12]=     op[12]= ffsub;
  op2[13]=     op[13]=ffmult;		/* heir12 */
  op2[14]=     op[14]= ffdiv;
  op2[15]=     op[15]= ffmod;
  }

>>> CC12.C 6788
/*
** open an include file
*/
doinclude()  {
  char *cp;
  blanks();			/* skip over to name */
  switch (*lptr) {
    case '"': case '<': cp = ++lptr;
    while(*cp) {
      switch(*cp) {case '"': case '>': *cp=NULL;}
      ++cp;
      }
    }
  if((input2=fopen(lptr,"r"))==NULL) {
    input2=EOF;
    error("open failure on include file");
    }
  kill();			/* clear rest of line */
				/* so next read will come from */
				/* new file (if open) */
  }

/*
** test for global declarations
*/
dodeclare(class) int class; {
  if(amatch("char",4)) {
    declglb(CCHAR, class);
    ns();
    return 1;
    }
  else if((amatch("int",3))|(class==EXTERNAL)) {
    declglb(CINT, class);
    ns();
    return 1;
    }
  return 0;
  }

/*
** delcare a static variable
*/
declglb(type, class)  int type, class; {
  int k, j;
  while(1) {
    if(endst()) return;			/* do line */
    if(match("(*")|match("*")) {
      j=POINTER;
      k=0;
      }
    else {
      j=VARIABLE;
      k=1;
      }
    if (symname(ssname, YES)==0) illname();
    if(findglb(ssname)) multidef(ssname);
    if(match(")")) ;
    if(match("()")) j=FUNCTION;
    else if (match("[")) {
      paerror(j);
      k=needsub();			/* get size */
      j=ARRAY;				/* !0=array */
      }
    if(class==EXTERNAL) external(ssname);
    else if(j!=FUNCTION) j=initials(type>>2, j, k);
    addsym(ssname, j, type, k, &glbptr, class);
    if (match(",")==0) return;		/* more? */
    }
  }

/*
** declare local variables
*/
declloc(typ)  int typ;  {
  int k,j;
  if(swactive) error("not allowed in switch");
#ifdef STGOTO
  if(noloc) error("not allowed with goto");
#endif
  if(declared < 0) error("must declare first in block");
  while(1) {
    while(1) {
      if(endst()) return;
      if(match("*")) j=POINTER;
      else           j=VARIABLE;
      if (symname(ssname, YES)==0) illname();
      /* no multidef check, block-locals are together */
      k=BPW;
      if (match("[")) {
        paerror(j);
        if(k=needsub()) {
          j=ARRAY;
          if(typ==CINT)k=k<<LBPW;
          }
        else {j=POINTER; k=BPW;}
        }
      else if((typ==CCHAR)&(j==VARIABLE)) k=SBPC;
      declared = declared + k;
      addsym(ssname, j, typ, csp - declared, &locptr, AUTOMATIC);
      break;
      }
    if (match(",")==0) return;
    }
  }

/*
** test for pointer array (unsupported)
*/
paerror(j) int j; {
  if(j==POINTER) error("no pointer arrays");
  }

/*
** initialize global objects
*/
initials(size, ident, dim) int size, ident, dim; {
  int savedim;
  litptr=0;
  if(dim==0) dim = -1;
  savedim=dim;
  entry();
  if(match("=")) {
    if(match("{")) {
      while(dim) {
        init(size, ident, &dim);
        if(match(",")==0) break;
        }
      needtoken("}");
      }
    else init(size, ident, &dim);
    }
  if((dim == -1)&(dim==savedim)) {
     stowlit(0, size=BPW);
    ident=POINTER;
    }
  dumplits(size);
  dumpzero(size, dim);
  return ident;
  }

/*
** evaluate one initializer
*/
init(size, ident, dim) int size, ident, *dim; {
  int value;
  if(qstr(&value)) {
    if((ident==VARIABLE)|(size!=1))
      error("must assign to char pointer or array");
    *dim = *dim - (litptr - value);
    if(ident==POINTER) point();
    }
  else if(constexpr(&value)) {
    if(ident==POINTER) error("cannot assign to pointer");
    stowlit(value, size);
    *dim = *dim - 1;
    }
  }

/*
** get required array size
*/
needsub()  {
  int val;
  if(match("]")) return 0;	/* null size */
  if (constexpr(&val)==0) val=1;
  if (val<0) {
    error("negative size illegal");
    val = -val;
    }
  needtoken("]");		/* force single dimension */
  return val;			/* and return size */
  }

/*
** begin a function
**
** called from "parse" and tries to make a function
** out of the following text
**
*/
newfunc()  {
  char *ptr;
#ifdef STGOTO
  nogo  =			/* enable goto statements */
  noloc = 0;			/* enable block-local declarations */
#endif
  lastst=			/* no statement yet */
  litptr=0;			/* clear lit pool */
  litlab=getlabel();		/* label next lit pool */
  locptr=STARTLOC;		/* clear local variables */
  if(monitor) lout(line, stderr);
  if (symname(ssname, YES)==0) {
    error("illegal function or declaration");
    kill();			/* invalidate line */
    return;
    }
  if(func1) {
    postlabel(beglab);
    func1=0;
    }
  if(ptr=findglb(ssname)) {	/* already in symbol table ? */
    if(ptr[IDENT]!=FUNCTION)       multidef(ssname);
    else if(ptr[OFFSET]==FUNCTION) multidef(ssname);
    else {
      /* earlier assumed to be a function */
      ptr[OFFSET]=FUNCTION;
      ptr[CLASS]=STATIC;
      }
    }
  else
    addsym(ssname, FUNCTION, CINT, FUNCTION, &glbptr, STATIC);
  if(match("(")==0) error("no open paren");
  entry();
  locptr=STARTLOC;
  argstk=0;			/* init arg count */
  while(match(")")==0) {	/* then count args */
    /* any legal name bumps arg count */
    if(symname(ssname, YES)) {
      if(findloc(ssname)) multidef(ssname);
      else {
        addsym(ssname, 0, 0, argstk, &locptr, AUTOMATIC);
        argstk=argstk+BPW;
        }
      }
    else {error("illegal argument name");junk();}
    blanks();
    /* if not closing paren, should be comma */
    if(streq(lptr,")")==0) {
      if(match(",")==0) error("no comma");
      }
    if(endst()) break;
    }
  csp=0;			/* preset stack ptr */
  argtop=argstk;
  while(argstk) {
    /* now let user declare what types of things */
    /*      those arguments were */
    if(amatch("char",4))     {doargs(CCHAR);ns();}
    else if(amatch("int",3)) {doargs(CINT);ns();}
    else {error("wrong number of arguments");break;}
    }
  statement();
#ifdef STGOTO
  if(lastst != STRETURN && lastst != STGOTO) ffret();
#else
  if(lastst != STRETURN) ffret();
#endif
  if(litptr) {
    printlabel(litlab);
    col();
    dumplits(1);		/* dump literals */
    }
  }

/*
** declare argument types
**
** called from "newfunc" this routine adds an entry in the
** local symbol table for each named argument
*/
doargs(t) int t; {
  int j, legalname;
  char c, *argptr;
  while(1) {
    if(argstk==0) return;	/* no arguments */
    if(match("(*")|match("*")) j=POINTER;  else j=VARIABLE;
    if((legalname=symname(ssname, YES))==0) illname();
    if(match(")")) ;
    if(match("()")) ;
    if(match("[")) {
      paerror(j);
      while(inbyte()!=']') if(endst()) break;	/* skip "[...]" */
      j=POINTER;		/* add entry as pointer */
      }
    if(legalname) {
      if(argptr=findloc(ssname)) {
        /* add details of type and address */
        argptr[IDENT]=j;
        argptr[TYPE]=t;
        putint(argtop-getint(argptr+OFFSET, OFFSIZE), argptr+OFFSET, OFFSIZE);
        }
      else error("not an argument");
      }
    argstk=argstk-BPW;		/* cnt down */
    if(endst())return;
    if(match(",")==0) error("no comma");
    }
  }

>>> CC13.C 6825
/*
** statement parser
**
** called whenever syntax requires a statement
**  this routine performs that statement
**  and returns a number telling which one
*/
statement() {
  if ((ch==0) & (eof)) return;
  else if(amatch("char",4))  {declloc(CCHAR);ns();}
  else if(amatch("int",3))   {declloc(CINT);ns();}
  else {
    if(declared >= 0) {
#ifdef STGOTO
      if(ncmp > 1) nogo=declared;	/* disable goto if any */
#endif
      csp=modstk(csp - declared, NO);
      declared = -1;
      }
    if(match("{"))                compound();
    else if(amatch("if",2))       {doif();		lastst=STIF;}
    else if(amatch("while",5))    {dowhile();		lastst=STWHILE;}
#ifdef STDO
    else if(amatch("do",2))       {dodo();		lastst=STDO;}
#endif
#ifdef STFOR
    else if(amatch("for",3))	  {dofor();		lastst=STFOR;}
#endif
#ifdef STSWITCH
    else if(amatch("switch",6))	  {doswitch();		lastst=STSWITCH;}
    else if(amatch("case",4))	  {docase();		lastst=STCASE;}
    else if(amatch("default",7))  {dodefault();		lastst=STDEF;}
#endif
#ifdef STGOTO
    else if(amatch("goto", 4))	  {dogoto();		lastst=STGOTO;}
    else if(dolabel())					lastst=STLABEL;
#endif
    else if(amatch("return",6))	  {doreturn();ns();	lastst=STRETURN;}
    else if(amatch("break",5))	  {dobreak();ns();	lastst=STBREAK;}
    else if(amatch("continue",8)) {docont();ns();	lastst=STCONT;}
    else if(match(";"))		  errflag=0;
    else if(match("#asm"))	  {doasm();		lastst=STASM;}
    else			  {doexpr();ns();	lastst=STEXPR;}
    }
  return lastst;
  }

/*
** semicolon enforcer
**
** called whenever syntax requires a semicolon
*/
ns()  {
  if(match(";")==0) error("no semicolon");
  else errflag=0;
  }

compound()  {
  int savcsp;
  char *savloc;
  savcsp=csp;
  savloc=locptr;
  declared=0;			/* may now declare local variables */
  ++ncmp;			/* new level open */
  while (match("}")==0)
    if(eof) {
      error("no final }");
      break;
      }
    else statement();		/* do one */
  --ncmp;			/* close current level */
/*55*/
#ifdef STGOTO
  if(lastst != STRETURN && lastst != STGOTO)
#else
  if(lastst != STRETURN)
#endif
    modstk(savcsp, NO);		/* delete local variable space */
  csp=savcsp;
/*55*/
#ifdef STGOTO
  cptr=savloc;			/* retain labels */
  while(cptr < locptr) {
    cptr2=nextsym(cptr);
    if(cptr[IDENT] == LABEL) {
      while(cptr < cptr2) *savloc++ = *cptr++;
      }
    else cptr=cptr2;
    }
#endif
  locptr=savloc;		/* delete local symbols */
  declared = -1;		/* may not declare variables */
  }

doif()  {
  int flab1,flab2;
  flab1=getlabel();		/* get label for false branch */
  test(flab1, YES);		/* get expression, and branch false */
  statement();			/* if true, do a statement */
  if (amatch("else",4)==0) {	/* if...else ? */
    /* simple "if"...print false label */
    postlabel(flab1);
    return;			/* and exit */
    }
  flab2=getlabel();
#ifdef STGOTO
  if((lastst != STRETURN)&(lastst != STGOTO)) jump(flab2);
#else
  if(lastst != STRETURN) jump(flab2);
#endif
  postlabel(flab1);		/* print false label */
  statement();			/* and do "else" clause */
  postlabel(flab2);		/* print true label */
  }

doexpr() {
  int const, val;
  char *before, *start;
  while(1) {
    setstage(&before, &start);
    expression(&const, &val);
    clearstage(before, start);
    if(ch != ',') break;
    bump(1);
    }
  }

dowhile()  {
  int wq[4];			/* allocate local queue */
  addwhile(wq);			/* add entry to queue for "break" */
  postlabel(wq[WQLOOP]);	/* loop label */
  test(wq[WQEXIT], YES);	/* see if true */
  statement();			/* if so, do a statement */
  jump(wq[WQLOOP]);		/* loop to label */
  postlabel(wq[WQEXIT]);	/* exit label */
  delwhile();			/* delete queue entry */
  }

#ifdef STDO
dodo() {
  int wq[4], top;
  addwhile(wq);
  postlabel(top=getlabel());
  statement();
  needtoken("while");
  postlabel(wq[WQLOOP]);
  test(wq[WQEXIT], YES);
  jump(top);
  postlabel(wq[WQEXIT]);
  delwhile();
  ns();
  }
#endif

#ifdef STFOR
dofor() {
  int wq[4], lab1, lab2;
  addwhile(wq);
  lab1=getlabel();
  lab2=getlabel();
  needtoken("(");
  if(match(";")==0) {
    doexpr();			/* expr 1 */
    ns();
    }
  postlabel(lab1);
  if(match(";")==0) {
    test(wq[WQEXIT], NO);	/* expr 2 */
    ns();
    }
  jump(lab2);
  postlabel(wq[WQLOOP]);
  if(match(")")==0) {
    doexpr();			/* expr 3 */
    needtoken(")");
    }
  jump(lab1);
  postlabel(lab2);
  statement();
  jump(wq[WQLOOP]);
  postlabel(wq[WQEXIT]);
  delwhile();
  }
#endif

#ifdef STSWITCH
doswitch() {
  int wq[4], endlab, swact, swdef, *swnex, *swptr;
  swact=swactive;
  swdef=swdefault;
  swnex=swptr=swnext;
  addwhile(wq);
  *(wqptr + WQLOOP - WQSIZ) = 0;
  needtoken("(");
  doexpr();			/* evaluate switch expression */
  needtoken(")");
  swdefault=0;
  swactive=1;
  jump(endlab=getlabel());
  statement();			/* cases, etc. */
  jump(wq[WQEXIT]);
  postlabel(endlab);
  sw();				/* match cases */
  while(swptr < swnext) {
    defstorage(CINT>>2);
    printlabel(*swptr++);	/* case label */
    outbyte(',');
    outdec(*swptr++);		/* case value */
    nl();
    }
  defstorage(CINT>>2);
  outdec(0);
  nl();
  if(swdefault) jump(swdefault);
  postlabel(wq[WQEXIT]);
  delwhile();
  swnext=swnex;
  swdefault=swdef;
  swactive=swact;
  }

docase() {
  if(swactive==0) error("not in switch");
  if(swnext > swend) {
    error("too many cases");
    return;
    }
  postlabel(*swnext++ = getlabel());
  constexpr(swnext++);
  needtoken(":");
  }

dodefault() {
  if(swactive) {
    if(swdefault) error("multiple defaults");
    }
  else error("not in switch");
  needtoken(":");
  postlabel(swdefault=getlabel());
  }
#endif

#ifdef STGOTO
dogoto() {
  if(nogo > 0) error("not allowed with block-locals");
  else noloc = 1;
  if(symname(ssname, YES)) jump(addlabel());
  else error("bad label");
  ns();
  }

dolabel() {
  char *savelptr;
  blanks();
  savelptr=lptr;
  if(symname(ssname, YES)) {
    if(gch()==':') {
      postlabel(addlabel());
      return 1;
      }
    else bump(savelptr-lptr);
    }
  return 0;
  }

addlabel()  {
  if(cptr=findloc(ssname)) {
    if(cptr[IDENT]!=LABEL) error("not a label");
    }
  else cptr=addsym(ssname, LABEL, LABEL, getlabel(), &locptr, LABEL);
  return (getint(cptr+OFFSET, OFFSIZE));
  }
#endif

doreturn()  {
  if(endst()==0) {
    doexpr();
    modstk(0, YES);
    }
  else modstk(0, NO);
  ffret();
  }

dobreak()  {
  int *ptr;
  if ((ptr=readwhile(wqptr))==0) return;
  modstk((ptr[WQSP]), NO);
  jump(ptr[WQEXIT]);
  }

docont()  {
  int *ptr;
  ptr = wqptr;
  while (1) {
    if ((ptr=readwhile(ptr))==0) return;
    if (ptr[WQLOOP]) break;
    }
  modstk((ptr[WQSP]), NO);
  jump(ptr[WQLOOP]);
  }

doasm()  {
  ccode=0;			/* mark mode as "asm" */
  while (1) {
    inline();
    if (match("#endasm")) break;
    if(eof)break;
    sout(line, output);
    }
  kill();
  ccode=1;
  }

>>> CC2.C 703
/*
** Small-C Compiler Part 2
*/
#include <stdio.h>
#include "cc.def"

extern char
#ifdef DYNAMIC
 *symtab,
 *stage,
 *macn,
 *macq,
 *pline,
 *mline,
#else
  symtab[SYMTBSZ],
  stage[STAGESIZE],
  macn[MACNSIZE],
  macq[MACQSIZE],
  pline[LINESIZE],
  mline[LINESIZE],
#endif
#ifdef OPTIMIZE
  optimize,
#endif
  alarm, *glbptr, *line, *lptr, *cptr, *cptr2,  *cptr3,
 *locptr, msname[NAMESIZE],  pause,  quote[2],
 *stagelast, *stagenext;
extern int
#ifdef DYNAMIC
  *wq,
#else
  wq[WQTABSZ],
#endif
  ccode,  ch,  csp,  eof,  errflag,  iflevel,
  input,  input2,  listfp,  macptr,  nch,
  nxtlab,  op[16],  opindex,  opsize,  output,  pptr,
  skiplevel,  *wqptr;

#include "cc21.c"
#include "cc22.c"

>>> CC21.C 4371
junk() {
  if(an(inbyte())) while(an(ch)) gch();
  else while(an(ch)==0) {
    if(ch==0) break;
    gch();
    }
  blanks();
  }

endst() {
  blanks();
  return ((streq(lptr,";")|(ch==0)));
  }

illname() {
  error("illegal symbol");
  junk();
  }
  
multidef(sname)  char *sname; {
  error("already defined");
  }

needtoken(str)  char *str; {
  if (match(str)==0) error("missing token");
  }

needlval() {
  error("must be lvalue");
  }

findglb(sname)  char *sname; {
  if(search(sname, STARTGLB, SYMMAX, ENDGLB, NUMGLBS, NAME))
    return cptr;
  return 0;
  }

findloc(sname)  char *sname;  {
  cptr = locptr - 1;		/* search backward for block locals */
  while(cptr > STARTLOC) {
    cptr = cptr - *cptr;
    if(astreq(sname, cptr, NAMEMAX)) return (cptr - NAME);
    cptr = cptr - NAME - 1;
    }
  return 0;
  }

addsym(sname, id, typ, value, lgptrptr, class)
  char *sname, id, typ;  int value, *lgptrptr, class; {
  if(lgptrptr == &glbptr) {
    if(cptr2=findglb(sname)) return cptr2;
    if(cptr==0) {
      error("global symbol table overflow");
      return 0;
      }
    }
  else {
    if(locptr > (ENDLOC-SYMMAX)) {
      error("local symbol table overflow");
      abort(ERRCODE);
      }
    cptr = *lgptrptr;
    }
  cptr[IDENT]=id;
  cptr[TYPE]=typ;
  cptr[CLASS]=class;
  putint(value, cptr+OFFSET, OFFSIZE);
  cptr3 = cptr2 = cptr + NAME;
  while(an(*sname)) *cptr2++ = *sname++;
  if(lgptrptr == &locptr) {
    *cptr2 = cptr2 - cptr3;	/* set length */
    *lgptrptr = ++cptr2;
    }
  return cptr;
  }

nextsym(entry) char *entry; {
  entry = entry + NAME;
  while(*entry++ >= ' ');	/* find length byte */
  return entry;
  }

/*
** get integer of length len from address addr
** (byte sequence set by "putint")
*/
getint(addr, len) char *addr; int len; {
  int i;
  i = *(addr + --len);		/* high order byte sign extended */
  while(len--) i = (i << 8) | *(addr+len)&255;
  return i;
  }

/*
** put integer i of length len into address addr
** (low byte first)
*/
putint(i, addr, len) char *addr; int i, len; {
  while(len--) {
    *addr++ = i;
    i = i>>8;
    }
  }

/*
** test if next input string is legal symbol name
*/
symname(sname, ucase) char *sname; int ucase; {
  int k;char c;
  blanks();
  if(alpha(ch)==0) return (*sname=0);
  k=0;
  while(an(ch)) {
#ifdef UPPER
    if(ucase)
      sname[k]=toupper(gch());
    else
#endif
      sname[k]=gch();
    if(k<NAMEMAX) ++k;
    }
  sname[k]=0;
  return 1;
  }

/*
** return next avail internal label number
*/
getlabel() {
  return(++nxtlab);
  }

/*
** post a label in the program
*/
postlabel(label) int label; {
  printlabel(label);
  col();
  nl();
  }

/*
** print specified number as a label
*/
printlabel(label)  int label; {
  outstr("CC");
  outdec(label);
  }

/*
** test if c is alphabetic
*/
alpha(c)  char c; {
  return (isalpha(c) || c=='_');
  }

/*
** test if given character is alphanumeric
*/
an(c)  char c; {
  return (alpha(c) || isdigit(c));
  }

addwhile(ptr)  int ptr[]; {
  int k;
  ptr[WQSP]=csp;		/* and stk ptr */
  ptr[WQLOOP]=getlabel();	/* and looping label */
  ptr[WQEXIT]=getlabel();	/* and exit label */
  if (wqptr==WQMAX) {
    error("too many active loops");
    abort(ERRCODE);
    }
  k=0;
  while (k<WQSIZ) *wqptr++ = ptr[k++];
  }

delwhile() {
  if (wqptr > wq) wqptr=wqptr-WQSIZ;
  }

readwhile(ptr) int *ptr; {
  if (ptr <= wq) {
    error("out of context");
    return 0;
    }
  else return (ptr-WQSIZ);
 }

white() {
#ifdef DYNAMIC
  /* test for stack/prog overlap at deepest nesting */
  /* primary -> symname -> blanks -> white */
  avail(YES);		/* abort on stack overflow */
#endif
  return (*lptr<= ' ' && *lptr!=NULL);
  }

gch() {
  int c;
  if(c=ch) bump(1);
  return c;
  }

bump(n) int n; {
  if(n) lptr=lptr+n;
  else  lptr=line;
  if(ch=nch = *lptr) nch = *(lptr+1);
  }

kill() {
  *line=0;
  bump(0);
  }

inbyte()  {
  while(ch==0) {
    if (eof) return 0;
    preprocess();
    }
  return gch();
  }

inline() {			/* numerous revisions */
  int k,unit;
  poll(1);			/* allow operator interruption */
  if (input==EOF) openfile();
  if(eof) return;
  if((unit=input2)==EOF) unit=input;
  if(fgets(line, LINEMAX, unit)==NULL) {
    fclose(unit);
    if(input2!=EOF) input2=EOF;
    else input=EOF;
    *line=NULL;
    }
  else if(listfp) {
    if(listfp==output) cout(';', output);
    sout(line, listfp);
    }
  bump(0);
  }

>>> CC22.C 6866
ifline() {
  while(1) {
    inline();
    if(eof) return;
    if(match("#ifdef")) {
      ++iflevel;
      if(skiplevel) continue;
      symname(msname, NO);
      if(search(msname, macn, NAMESIZE+2, MACNEND, MACNBR, 0)==0)
        skiplevel=iflevel;
      continue;
      }
    if(match("#ifndef")) {
      ++iflevel;
      if(skiplevel) continue;
      symname(msname, NO);
      if(search(msname, macn, NAMESIZE+2, MACNEND, MACNBR, 0))
        skiplevel=iflevel;
      continue;
      }
    if(match("#else")) {
      if(iflevel) {
        if(skiplevel==iflevel) skiplevel=0;
        else if(skiplevel==0)  skiplevel=iflevel;
        }
      else noiferr();
      continue;
      }
    if(match("#endif")) {
      if(iflevel) {
        if(skiplevel==iflevel) skiplevel=0;
        --iflevel;
        }
      else noiferr();
      continue;
      }
    if(skiplevel) continue;
    if(ch==0) continue;
    break;
    }
  }

keepch(c)  char c; {
  if(pptr<LINEMAX) pline[++pptr]=c;
  }

preprocess() {
  int k;
  char c;
  if(ccode) {
    line=mline;
    ifline();
    if(eof) return;
    }
  else {
    line=pline;
    inline();
    return;
    }
  pptr = -1;
  while(ch != NEWLINE && ch) {
    if(white()) {
      keepch(' ');
      while(white()) gch();
      }
    else if(ch=='"') {
      keepch(ch);
      gch();
      while((ch!='"')|((*(lptr-1)==92)&(*(lptr-2)!=92))) {
        if(ch==0) {
          error("no quote");
          break;
          }
        keepch(gch());
        }
      gch();
      keepch('"');
      }
    else if(ch==39) {
      keepch(39);
      gch();
      while((ch!=39)|((*(lptr-1)==92)&(*(lptr-2)!=92))) {
        if(ch==0) {
          error("no apostrophe");
          break;
          }
        keepch(gch());
        }
      gch();
      keepch(39);
      }
    else if((ch=='/')&(nch=='*')) {
      bump(2);
      while(((ch=='*')&(nch=='/'))==0) {
        if(ch) bump(1);
        else {
          ifline();
          if(eof) break;
          }
        }
      bump(2);
      }
    else if(an(ch)) {
      k=0;
      while((an(ch)) & (k<NAMEMAX)) {
        msname[k++]=ch;
        gch();
        }
      msname[k]=0;
      if(search(msname, macn, NAMESIZE+2, MACNEND, MACNBR, 0)) {
        k=getint(cptr+NAMESIZE, 2);
        while(c=macq[k++]) keepch(c);
        while(an(ch)) gch();
        }
      else {
        k=0;
        while(c=msname[k++]) keepch(c);
        }
      }
    else keepch(gch());
    }
  if(pptr>=LINEMAX) error("line too long");
  keepch(0);
  line=pline;
  bump(0);
  }

noiferr() {
  error("no matching #if...");
  errflag=0;
  }

addmac() {
  int k;
  if(symname(msname, NO)==0) {
    illname();
    kill();
    return;
    }
  k=0;
  if(search(msname, macn, NAMESIZE+2, MACNEND, MACNBR, 0)==0) {
    if(cptr2=cptr) while(*cptr2++ = msname[k++]);
    else {
      error("macro name table full");
      return;
      }
    }
  putint(macptr, cptr+NAMESIZE, 2);
  while(white()) gch();
  while(putmac(gch()));
  if(macptr>=MACMAX) {
    error("macro string queue full"); abort(ERRCODE);
    }
  }

putmac(c)  char c; {
  macq[macptr]=c;
  if(macptr<MACMAX) ++macptr;
  return c;
  }

/*
** search for symbol match
** on return cptr points to slot found or empty slot
*/
search(sname, buf, len, end, max, off)
  char *sname, *buf, *end;  int len, max, off; {
  cptr=cptr2=buf+((hash(sname)%(max-1))*len);
  while(*cptr != 0) {
    if(astreq(sname, cptr+off, NAMEMAX)) return 1;
    if((cptr=cptr+len) >= end) cptr=buf;
    if(cptr == cptr2) return (cptr=0);
    }
  return 0;
  }

hash(sname) char *sname; {
  int i, c;
  i=0;
  while(c = *sname++) i=(i<<1)+c;
  return i;
  }

setstage(before, start) int *before, *start; {
  if((*before=stagenext)==0) stagenext=stage;
  *start=stagenext;
  }

clearstage(before, start) char *before, *start; {
  *stagenext=0;
  if(stagenext=before) return;
  if(start) {
#ifdef OPTIMIZE
    peephole(start);
#else
    sout(start, output);
#endif
    }
  }

outdec(number)  int number; {
  int k,zs;
  char c, *q, *r;
  zs = 0;
  k=10000;
  if (number<0) {
    number=(-number);
    outbyte('-');
    }
  while (k>=1) {
    q=0; r=number;
    while(r >= k) {++q; r -= k;}
    c = q + '0';
    if ((c!='0')|(k==1)|(zs)) {
      zs=1;
      outbyte(c);
      }
    number=r;
    k=k/10;
    }
  }

ol(ptr)  char ptr[];  {
  ot(ptr);
  nl();
  }

ot(ptr) char ptr[]; {
  outstr(ptr);
  }

outstr(ptr) char ptr[]; {
  poll(1); /* allow program interruption */
  /* must work with symbol table names terminated by length */
  while(*ptr >= ' ') outbyte(*ptr++);
  }

outbyte(c) char c; {
  if(stagenext) {
    if(stagenext==stagelast) {
      error("staging buffer overflow");
      return 0;
      }
    else *stagenext++ = c;
    }
  else cout(c,output);
  return c;
  }

cout(c, fd) char c; int fd; {
  if(fputc(c, fd)==EOF) xout();
  }

sout(string, fd) char *string; int fd; {
  if(fputs(string, fd)==EOF) xout();
  }

lout(line, fd) char *line; int fd; {
  sout(line, fd);
  cout(NEWLINE, fd);
  }

xout() {
  fputs("output error", stderr);
  abort(ERRCODE);
  }

nl() {
  outbyte(NEWLINE);
  }

col() {
#ifdef COL
  outbyte(':');
#endif
  }

error(msg) char msg[]; {
  if(errflag) return; else errflag=1;
  lout(line, stderr);
  errout(msg, stderr);
  if(alarm) fputc(7, stderr);
  if(pause) while(fgetc(stderr)!=NEWLINE);
  if(listfp>0) errout(msg, listfp);
  }

errout(msg, fp) char msg[]; int fp; {
  int k; k=line+2;
  while(k++ <= lptr) cout(' ', fp);
  lout("/\\", fp);
  sout("**** ", fp); lout(msg, fp);
  }

streq(str1,str2)  char str1[],str2[]; {
  int k;
  k=0;
  while (str2[k]) {
    if ((str1[k])!=(str2[k])) return 0;
    ++k;
    }
  return k;
 }

astreq(str1,str2,len)  char str1[],str2[];int len; {
  int k;
  k=0;
  while (k<len) {
    if ((str1[k])!=(str2[k]))break;
    /*
    ** must detect end of symbol table names terminated by
    ** symbol length in binary
    */
    if(str1[k] < ' ') break;
    if(str2[k] < ' ') break;
    ++k;
    }
  if (an(str1[k]))return 0;
  if (an(str2[k]))return 0;
  return k;
 }

match(lit)  char *lit; {
  int k;
  blanks();
  if (k=streq(lptr,lit)) {
    bump(k);
    return 1;
    }
  return 0;
  }

amatch(lit,len)  char *lit;int len; {
  int k;
  blanks();
  if (k=astreq(lptr,lit,len)) {
    bump(k);
    while(an(ch)) inbyte();
    return 1;
    }
  return 0;
 }

nextop(list) char *list; {
  char op[4];
  opindex=0;
  blanks();
  while(1) {
    opsize=0;
    while(*list > ' ') op[opsize++] = *list++;
    op[opsize]=0;
    if(opsize=streq(lptr, op))
      if((*(lptr+opsize) != '=')&
         (*(lptr+opsize) != *(lptr+opsize-1)))
         return 1;
    if(*list) {
      ++list;
      ++opindex;
      }
    else return 0;
    }
  }

blanks() {
  while(1) {
    while(ch) {
      if(white()) gch();
      else return;
      }
    if(line==mline) return;
    preprocess();
    if(eof)break;
    }
  }

>>> CC3.C 373
/*
** Small-C Compiler Part 3
*/
#include <stdio.h>
#include "cc.def"

extern char
#ifdef DYNAMIC
 *stage,
 *litq,
#else
  stage[STAGESIZE],
  litq[LITABSZ],
#endif
 *glbptr, *lptr,  ssname[NAMESIZE],  quote[2], *stagenext;
extern int
  ch,  csp,  litlab,  litptr,  nch,  op[16],  op2[16],
  oper,  opindex,  opsize;

#include "cc31.c"
#include "cc32.c"
#include "cc33.c"

>>> CC31.C 6680
/*
** lval[0] - symbol table address, else 0 for constant
** lval[1] - type of indirect obj to fetch, else 0 for static
** lval[2] - type of pointer or array, else 0 for all other
** lval[3] - true if constant expression
** lval[4] - value of constant expression (+ auxiliary uses)
** lval[5] - true if secondary register altered
** lval[6] - function address of highest/last binary operator
** lval[7] - stage address of "oper 0" code, else 0
*/

/*
** skim over terms adjoining || and && operators
*/
skim(opstr, testfunc, dropval, endval, hier, lval)
  char *opstr;
  int (*testfunc)(), dropval, endval, (*hier)(), lval[]; {
  int k, hits, droplab, endlab;
  hits=0;
  while(1) {
    k=plnge1(hier, lval);
    if(nextop(opstr)) {
      bump(opsize);
      if(hits==0) {
        hits=1;
        droplab=getlabel();
        }
      dropout(k, testfunc, droplab, lval);
      }
    else if(hits) {
      dropout(k, testfunc, droplab, lval);
      const(endval);
      jump(endlab=getlabel());
      postlabel(droplab);
      const(dropval);
      postlabel(endlab);
      lval[1]=lval[2]=lval[3]=lval[4]=lval[7]=0;
      return 0;
      }
    else return k;
    }
  }

/*
** test for early dropout from || or && evaluations
*/
dropout(k, testfunc, exit1, lval)
  int k, (*testfunc)(), exit1, lval[]; {
  if(k) rvalue(lval);
  else if(lval[3]) const(lval[4]);
  (*testfunc)(exit1);		/* jumps on false */
  }

/*
** plunge to a lower level
*/
plnge(opstr, opoff, hier, lval)
  char *opstr;
  int opoff, (*hier)(), lval[]; {
  int k, lval2[8];
  k=plnge1(hier, lval);
  if(nextop(opstr)==0) return k;
  if(k) rvalue(lval);
  while(1) {
    if(nextop(opstr)) {
      bump(opsize);
      opindex=opindex+opoff;
      plnge2(op[opindex], op2[opindex], hier, lval, lval2);
      }
    else return 0;
    }
  }

/*
** unary plunge to lower level
*/
plnge1(hier, lval) int (*hier)(), lval[]; {
  char *before, *start;
  int k;
  setstage(&before, &start);
  k=(*hier)(lval);
  if(lval[3]) clearstage(before,0);	/* load constant later */
  return k;
  }

/*
** binary plunge to lower level
*/
plnge2(oper, oper2, hier, lval, lval2)
  int (*oper)(),(*oper2)(),(*hier)(),lval[],lval2[]; {
  char *before, *start;
  setstage(&before, &start);
  lval[5]=1;		/* flag secondary register used */
  lval[7]=0;		/* flag as not "... oper 0" syntax */
  if(lval[3]) {		/* constant on left side not yet loaded */
    if(plnge1(hier, lval2)) rvalue(lval2);
    if(lval[4]==0) lval[7]=stagenext;
    const2(lval[4]<<dbltest(oper, lval2, lval));
    }
  else {		/* non-constant on left side */
    push();
    if(plnge1(hier, lval2)) rvalue(lval2);
    if(lval2[3]) {	/* constant on right side */
      if(lval2[4]==0) lval[7]=start;
      if(oper==ffadd) {	/* may test other commutative operators */
        csp=csp+2;
        clearstage(before, 0);
        const2(lval2[4]<<dbltest(oper, lval, lval2));
			/* load secondary */
        }
      else {
        const(lval2[4]<<dbltest(oper, lval, lval2));
			/* load primary */
        smartpop(lval2, start);
        }
      }
    else {		/* non-constants on both sides */
      smartpop(lval2, start);
      if(dbltest(oper, lval,lval2)) doublereg();
      if(dbltest(oper, lval2,lval)) {
        swap();
        doublereg();
        if(oper==ffsub) swap();
        }
      }
    }
  if(oper) {
    if(lval[3]=lval[3]&lval2[3]) {
      lval[4]=calc(lval[4], oper, lval2[4]);
      clearstage(before, 0);  
      lval[5]=0;
      }
    else {
      if((lval[2]==0)&(lval2[2]==0)) {
        (*oper)();
        lval[6]=oper;			/* identify the operator */
        }
      else {
        (*oper2)();
        lval[6]=oper2;			/* identify the operator */
        }
      }
    if(oper==ffsub) {
      if((lval[2]==CINT)&(lval2[2]==CINT)) {
        swap();
        const(1);
        ffasr();			/** div by 2 **/
        }
      }
    if((oper==ffsub)|(oper==ffadd)) result(lval, lval2);
    }
  }

calc(left, oper, right) int left, (*oper)(), right; {
       if(oper ==  ffor) return (left  |  right);
  else if(oper == ffxor) return (left  ^  right);
  else if(oper == ffand) return (left  &  right);
  else if(oper ==  ffeq) return (left  == right);
  else if(oper ==  ffne) return (left  != right);
  else if(oper ==  ffle) return (left  <= right);
  else if(oper ==  ffge) return (left  >= right);
  else if(oper ==  fflt) return (left  <  right);
  else if(oper ==  ffgt) return (left  >  right);
  else if(oper == ffasr) return (left  >> right);
  else if(oper == ffasl) return (left  << right);
  else if(oper == ffadd) return (left  +  right);
  else if(oper == ffsub) return (left  -  right);
  else if(oper ==ffmult) return (left  *  right);
  else if(oper == ffdiv) return (left  /  right);
  else if(oper == ffmod) return (left  %  right);
  else return 0;
  }

expression(const, val) int *const, *val;  {
  int lval[8];
  if(hier1(lval)) rvalue(lval);
  if(lval[3]) {
    *const=1;
    *val=lval[4];
    }
  else *const=0;
  }

hier1(lval)  int lval[];  {
  int k,lval2[8], lval3[2], oper;
  k=plnge1(hier3, lval);
  if(lval[3]) const(lval[4]);
       if(match("|="))  oper=ffor;
  else if(match("^="))  oper=ffxor;
  else if(match("&="))  oper=ffand;
  else if(match("+="))  oper=ffadd;
  else if(match("-="))  oper=ffsub;
  else if(match("*="))  oper=ffmult;
  else if(match("/="))  oper=ffdiv;
  else if(match("%="))  oper=ffmod;
  else if(match(">>=")) oper=ffasr;
  else if(match("<<=")) oper=ffasl;
  else if(match("="))   oper=0;
  else return k;
  if(k==0) {
    needlval();
    return 0;
    }
  lval3[0] = lval[0];
  lval3[1] = lval[1];
  if(lval[1]) {
    if(oper) {
      push();
      rvalue(lval);
      }
    plnge2(oper, oper, hier1, lval, lval2);
    if(oper) pop();
    }
  else {
    if(oper) {
      rvalue(lval);
      plnge2(oper, oper, hier1, lval, lval2);
      }
    else {
      if(hier1(lval2)) rvalue(lval2);
      lval[5]=lval2[5];
      }
    }
  store(lval3);
  return 0;
  }

hier3(lval)  int lval[]; {
  return skim("||", eq0, 1, 0, hier4, lval);
  }

hier4(lval)  int lval[]; {
  return skim("&&", ne0, 0, 1, hier5, lval);
  }

hier5(lval)  int lval[]; {
  return plnge("|", 0, hier6, lval);
  }

hier6(lval)  int lval[]; {
  return plnge("^", 1, hier7, lval);
  }

hier7(lval)  int lval[]; {
  return plnge("&", 2, hier8, lval);
  }

hier8(lval)  int lval[];  {
  return plnge("== !=", 3, hier9, lval);
  }

hier9(lval)  int lval[];  {
  return plnge("<= >= < >", 5, hier10, lval);
  }

hier10(lval)  int lval[];  {
  return plnge(">> <<", 9, hier11, lval);
  }

hier11(lval)  int lval[];  {
  return plnge("+ -", 11, hier12, lval);
  }

hier12(lval)  int lval[];  {
  return plnge("* / %", 13, hier13, lval);
  }

>>> CC32.C 5065
hier13(lval)  int lval[];  {
  int k;
  char *ptr;
  if(match("++")) {			/* ++lval */
    if(hier13(lval)==0) {
      needlval();
      return 0;
      }
    step(inc, lval);
    return 0;
    }
  else if(match("--")) {		/* --lval */
    if(hier13(lval)==0) {
      needlval();
      return 0;
      }
    step(dec, lval);
    return 0;
    }
  else if (match("~")) {		/* ~ */
    if(hier13(lval)) rvalue(lval);
    com();
    lval[4] = ~lval[4];
    return (lval[7]=0);
    }
  else if (match("!")) {		/* ! */
    if(hier13(lval)) rvalue(lval);
    lneg();
    lval[4] = !lval[4];
    return (lval[7]=0);
    }
  else if (match("-")) {		/* unary - */
    if(hier13(lval)) rvalue(lval);
    neg();
    lval[4] = -lval[4];
    return (lval[7]=0);
    }
  else if(match("*")) {			/* unary * */
    if(hier13(lval)) rvalue(lval);
    if(ptr=lval[0])lval[1]=ptr[TYPE];
    else lval[1]=CINT;
    lval[2]=0;		/* flag as not pointer or array */
    lval[3]=0;		/* flag as not constant */
    lval[4]=1;		/* omit rvalue() on func call */
    lval[7]=0;
    return 1;
    }
  else if(match("&")) {			/* unary & */
    if(hier13(lval)==0) {
      error("illegal address");
      return 0;
      }
    ptr=lval[0];
    lval[2]=ptr[TYPE];
    if(lval[1]) return 0;
					/* global & non-array */
    address(ptr);
    lval[1]=ptr[TYPE];
    return 0;
    }
  else {
    k=hier14(lval);
    if(match("++")) {			/* lval++ */
      if(k==0) {
        needlval();
        return 0;
        }
      step(inc, lval);
      dec(lval[2]>>2);
      return 0;
      }
    else if(match("--")) {		/* lval-- */
      if(k==0) {
        needlval();
        return 0;
        }
      step(dec, lval);
      inc(lval[2]>>2);
      return 0;
      }
    else return k;
    }
  }

hier14(lval)  int *lval; {
  int k, const, val, lval2[8];
  char *ptr, *before, *start;
  k=primary(lval);
  ptr=lval[0];
  blanks();
  if((ch=='[')|(ch=='(')) {
    lval[5]=1;			/* secondary register will be used */
    while(1) {
      if(match("[")) {			/* [subscript] */
        if(ptr==0) {
          error("can't subscript");
          junk();
          needtoken("]");
          return 0;
          }
        else if(ptr[IDENT]==POINTER)rvalue(lval);
        else if(ptr[IDENT]!=ARRAY) {
          error("can't subscript");
          k=0;
          }
        setstage(&before, &start);
        lval2[3]=0;
        plnge2(0, 0, hier1, lval2, lval2); /* lval2 deadend */
        needtoken("]");
        if(lval2[3]) {
          clearstage(before, 0);
          if(lval2[4]) {
            if(ptr[TYPE]==CINT) const2(lval2[4]<<LBPW);
            else                const2(lval2[4]);
            ffadd();
            }
          }
        else {
          if(ptr[TYPE]==CINT) doublereg();
          ffadd();
          }
        lval[2]=0;
        lval[1]=ptr[TYPE];
        k=1;
        }
      else if(match("(")) {		/* function(...) */
        if(ptr==0) callfunction(0);
        else if(ptr[IDENT]!=FUNCTION) {
          if(k && !lval[4]) rvalue(lval);
          callfunction(0);
          }
        else callfunction(ptr);
        k=lval[0]=lval[3]=lval[4]=0;
        }
      else return k;
      }
    }
  if(ptr==0) return k;
  if(ptr[IDENT]==FUNCTION) {
    address(ptr);
    lval[0]=0;
    return 0;
    }
  return k;
  }

primary(lval)  int *lval; {
  char *ptr, sname[NAMESIZE];
  int k;
  if(match("(")) {			/* (expression,...) */
    do k=hier1(lval); while(match(","));
    needtoken(")");
    return k;
    }
  putint(0, lval, 8<<LBPW);		/* clear lval array */
  if(symname(sname, YES)) {
    if(ptr=findloc(sname)) {
#ifdef STGOTO
      if(ptr[IDENT]==LABEL) {
        experr();
        return 0;
        }
#endif
      getloc(ptr);
      lval[0]=ptr;
      lval[1]=ptr[TYPE];
      if(ptr[IDENT]==POINTER) {
        lval[1]=CINT;
        lval[2]=ptr[TYPE];
        }
      if(ptr[IDENT]==ARRAY) {
        lval[2]=ptr[TYPE];
        return 0;
        }
      else return 1;
      }
    if(ptr=findglb(sname))
      if(ptr[IDENT]!=FUNCTION) {
        lval[0]=ptr;
        lval[1]=0;
        if(ptr[IDENT]!=ARRAY) {
          if(ptr[IDENT]==POINTER) lval[2]=ptr[TYPE];
          return 1;
          }
        address(ptr);
        lval[1]=lval[2]=ptr[TYPE];
        return 0;
        }
    ptr=addsym(sname,FUNCTION,CINT,0,&glbptr,AUTOEXT);
    lval[0]=ptr;
    lval[1]=0;
    return 0;
    }
  if(constant(lval)==0) experr();
  return 0;
  }

experr() {
  error("invalid expression");
  const(0);
  junk();
  }
 
callfunction(ptr)  char *ptr; {		/* symbol table entry or 0 */
  int nargs, const, val;
  nargs=0;
  blanks();				/* already saw open paren */
  while(streq(lptr,")")==0) {
    if(endst()) break;
    if(ptr) {
      expression(&const, &val);
      push();
      }
    else {
      push();
      expression(&const, &val);
      swapstk();
      }
    nargs=nargs+BPW;			/* count args*BPW */
    if (match(",")==0) break;
    }
  needtoken(")");
  if(streq(ptr+NAME, "CCARGC")==0) loadargc(nargs>>LBPW);
  if(ptr) ffcall(ptr+NAME);
  else callstk();
  csp=modstk(csp+nargs, YES);
  }

>>> CC33.C 4152
/*
** true if val1 -> int pointer or int array and val2 not ptr or array
*/
dbltest(oper, val1, val2) int (*oper)(), val1[], val2[]; {
  if((oper!=ffadd) && (oper!=ffsub)) return 0;
  if(val1[2]!=CINT) return 0;
  if(val2[2]) return 0;
  return 1;
  }

/*
** determine type of binary operation
*/
result(lval, lval2) int lval[], lval2[]; {
  if((lval[2]!=0)&(lval2[2]!=0)) {
    lval[2]=0;
    }
  else if(lval2[2]) {
    lval[0]=lval2[0];
    lval[1]=lval2[1];
    lval[2]=lval2[2];
    }
  }

step(oper, lval) int (*oper)(), lval[]; {
  if(lval[1]) {
    if(lval[5]) {
      push();
      rvalue(lval);
      (*oper)(lval[2]>>2);
      pop();
      store(lval);
      return;
      }
    else {
      move();
      lval[5]=1;
      }
    }
  rvalue(lval);
  (*oper)(lval[2]>>2);
  store(lval);
  }

store(lval)  int lval[]; {
  if(lval[1]) putstk(lval);
  else        putmem(lval);
  }

rvalue(lval) int lval[]; {
  if ((lval[0]!=0)&(lval[1]==0)) getmem(lval);
  else                         indirect(lval);
  }

test(label, parens)  int label, parens;  {
  int lval[8];
  char *before, *start;
  if(parens) needtoken("(");
  while(1) {
    setstage(&before, &start);
    if(hier1(lval)) rvalue(lval);
    if(match(",")) clearstage(before, start);
    else break;
    }
  if(parens) needtoken(")");
  if(lval[3]) {			/* constant expression */
    clearstage(before, 0);
    if(lval[4]) return;
    jump(label);
    return;
    }
  if(lval[7]) {			/* stage address of "oper 0" code */
    oper=lval[6];		/* operator function address */
         if((oper==ffeq)|
            (oper==ule)) zerojump(eq0, label, lval);
    else if((oper==ffne)|
            (oper==ugt)) zerojump(ne0, label, lval);
    else if (oper==ffgt) zerojump(gt0, label, lval);
    else if (oper==ffge) zerojump(ge0, label, lval);
    else if (oper==uge)  clearstage(lval[7],0);
    else if (oper==fflt) zerojump(lt0, label, lval);
    else if (oper==ult)  zerojump(ult0, label, lval);
    else if (oper==ffle) zerojump(le0, label, lval);
    else                 testjump(label);
    }
  else testjump(label);
  clearstage(before, start);
  }

constexpr(val) int *val; {
  int const;
  char *before, *start;
  setstage(&before, &start);
  expression(&const, val);
  clearstage(before, 0);	/* scratch generated code */
  if(const==0) error("must be constant expression");
  return const;
  }

const(val) int val; {
  immed();
  outdec(val);
  nl();
  }

const2(val) int val; {
  immed2();
  outdec(val);
  nl();
  }

constant(lval)  int lval[]; {
  lval=lval+3;
  *lval=1;			/* assume it will be a constant */
  if (number(++lval)) immed();
  else if (pstr(lval)) immed();
  else if (qstr(lval)) {
    *(lval-1)=0;		/* nope, it's a string address */
    immed();
    printlabel(litlab);
    outbyte('+');
    }
  else return 0;
  outdec(*lval);
  nl();
  return 1;
  }

number(val)  int val[]; {
  int k, minus;
  k=minus=0;
  while(1) {
    if(match("+")) ;
    else if(match("-")) minus=1;
    else break;
    }
  if(isdigit(ch)==0)return 0;
  while (isdigit(ch)) k=k*10+(inbyte()-'0');
  if (minus) k=(-k);
  val[0]=k;
  return 1;
  }

address(ptr) char *ptr; {
  immed();
  outstr(ptr+NAME);
  nl();
  }

pstr(val)  int val[]; {
  int k;
  k=0;
  if (match("'")==0) return 0;
  while(ch!=39)    k=(k&255)*256 + (litchar()&255);
  gch();
  val[0]=k;
  return 1;
  }

qstr(val)  int val[]; {
  char c;
  if (match(quote)==0) return 0;
  val[0]=litptr;
  while (ch!='"') {
    if(ch==0) break;
    stowlit(litchar(), 1);
    }
  gch();
  litq[litptr++]=0;
  return 1;
  }

stowlit(value, size) int value, size; {
  if((litptr+size) >= LITMAX) {
    error("literal queue overflow"); abort(ERRCODE);
    }
  putint(value, litq+litptr, size);
  litptr=litptr+size;
  }

/*
** return current literal char & bump lptr
*/
litchar() {
  int i, oct;
  if((ch!=92)|(nch==0)) return gch();
  gch();
  if(ch=='n') {gch(); return NEWLINE;}
  if(ch=='t') {gch(); return  9;} /* HT */
  if(ch=='b') {gch(); return  8;} /* BS */
  if(ch=='f') {gch(); return 12;} /* FF */
  i=3; oct=0;
  while(((i--)>0)&(ch>='0')&(ch<='7')) oct=(oct<<3)+gch()-'0';
  if(i==2) return gch(); else return oct;
  }

>>> CC4.C 244
/*
** Small-C Compiler Part 4
*/
#include <stdio.h>
#include "cc.def"

extern char
 *macn,
 *cptr, *symtab,
#ifdef OPTIMIZE
 optimize,
#endif
 *stagenext, ssname[NAMESIZE];
extern int
 beglab,  csp, output;

#include "cc41.c"
#include "cc42.c"
>>> CC41.C 5196
/*
** print all assembler info before any code is generated
*/
header()  {
  beglab=getlabel();
  }

/*
** print any assembler stuff needed at the end
*/
trailer()  {  
#ifndef LINK
  if((beglab == 1)|(beglab > 9000)) {
    /* implementation dependent trailer code goes here */
    }
#else
  char *ptr;
  cptr=STARTGLB;
  while(cptr<ENDGLB) {
    if(cptr[IDENT]==FUNCTION && cptr[CLASS]==AUTOEXT)
      external(cptr+NAME);
    cptr+=SYMMAX;
    }
#ifdef UPPER
  if((ptr=findglb("MAIN")) && (ptr[OFFSET]==FUNCTION))
#else
  if((ptr=findglb("main")) && (ptr[OFFSET]==FUNCTION))
#endif
    external("Ulink");	/* link to library functions */
#endif
  ol("END");
  }

/*
** load # args before function call
*/
loadargc(val) int val; {
  if(search("NOCCARGC", macn, NAMESIZE+2, MACNEND, MACNBR, 0)==0) {
    if(val) {
      ot("MVI A,");
      outdec(val);
      nl();
      }
    else ol("XRA A");
    }
  }

/*
** declare entry point
*/
entry() {
  outstr(ssname);
  col();
#ifdef LINK
  col();
#endif
  nl();
  }

/*
** declare external reference
*/
external(name) char *name; {
#ifdef LINK
  ot("EXT ");
  ol(name);
#endif
  }

/*
** fetch object indirect to primary register
*/
indirect(lval) int lval[]; {
  if(lval[1]==CCHAR) ffcall("CCGCHAR##");
  else               ffcall("CCGINT##");
  }

/*
** fetch a static memory cell into primary register
*/
getmem(lval)  int lval[]; {
  char *sym;
  sym=lval[0];
  if((sym[IDENT]!=POINTER)&(sym[TYPE]==CCHAR)) {
    ot("LDA ");
    outstr(sym+NAME);
    nl();
    ffcall("CCSXT##");
    }
  else {
    ot("LHLD ");
    outstr(sym+NAME);
    nl();
    }
  }

/*
** fetch addr of the specified symbol into primary register
*/
getloc(sym)  char *sym; {
  const(getint(sym+OFFSET, OFFSIZE)-csp);
  ol("DAD SP");
  }

/*
** store primary register into static cell
*/
putmem(lval)  int lval[]; {
  char *sym;
  sym=lval[0];
  if((sym[IDENT]!=POINTER)&(sym[TYPE]==CCHAR)) {
    ol("MOV A,L");
    ot("STA ");
    }
  else ot("SHLD ");
  outstr(sym+NAME);
  nl();
  }

/*
** put on the stack the type object in primary register
*/
putstk(lval) int lval[]; {
  if(lval[1]==CCHAR) {
    ol("MOV A,L");
    ol("STAX D");
    }
  else ffcall("CCPINT##");
  }

/*
** move primary register to secondary
*/
move() {
  ol("MOV D,H");
  ol("MOV E,L");
  }

/*
** swap primary and secondary registers
*/
swap() {
  ol("XCHG;;");		/* peephole() uses trailing ";;" */
  }

/*
** partial instruction to get immediate value
** into the primary register
*/
immed() {
  ot("LXI H,");
  }

/*
** partial instruction to get immediate operand
** into secondary register
*/
immed2() {
  ot("LXI D,");
  }

/*
** push primary register onto stack
*/
push() {
  ol("PUSH H");
  csp=csp-BPW;
  }

/*
** unpush or pop as required
*/
smartpop(lval, start) int lval[]; char *start; {
  if(lval[5])  pop();		/* secondary was used */
  else unpush(start);
  }

/*
** replace a push with a swap
*/
unpush(dest) char *dest; {
  int i;
  char *sour;
  sour="XCHG;;";		/* peephole() uses trailing ";;" */
  while(*sour) *dest++ = *sour++;
  sour=stagenext;
  while(--sour > dest) {	/* adjust stack references */
    if(streq(sour,"DAD SP")) {
      --sour;
      i=BPW;
      while(isdigit(*(--sour))) {
        if((*sour = *sour-i) < '0') {
          *sour = *sour+10;
          i=1;
          }
        else i=0;
        }
      }
    }
  csp=csp+BPW;
  }

/*
** pop stack to the secondary register
*/
pop() {
  ol("POP D");
  csp=csp+BPW;
  }

/*
** swap primary register and stack
*/
swapstk() {
  ol("XTHL");
  }

/*
** process switch statement
*/
sw() {
  ffcall("CCSWITCH##");
  }

/*
** call specified subroutine name
*/
ffcall(sname)  char *sname; {
  ot("CALL ");
  outstr(sname);
  nl();
  }

/*
** return from subroutine
*/
ffret() {
  ol("RET");
  }

/*
** perform subroutine call to value on stack
*/
callstk() {
  ffcall("CCDCAL##");
  }

/*
** jump to internal label number
*/
jump(label)  int label; {
  ot("JMP ");
  printlabel(label);
  nl();
  }

/*
** test primary register and jump if false
*/
testjump(label)  int label; {
  ol("MOV A,H");
  ol("ORA L");
  ot("JZ ");
  printlabel(label);
  nl();
  }

/*
** test primary register against zero and jump if false
*/
zerojump(oper, label, lval) int (*oper)(), label, lval[]; {
  clearstage(lval[7], 0);	/* purge conventional code */
  (*oper)(label);
  }

/*
** define storage according to size
*/
defstorage(size) int size; {
  if(size==1) ot("DB ");
  else        ot("DW ");
  }

/*
** point to following object(s)
*/
point() {
  ol("DW $+2");
  }

/*
** modify stack pointer to value given
*/
modstk(newsp, save)  int newsp, save; {
  int k;
  k=newsp-csp;
  if(k==0)return newsp;
  if(k>=0) {
    if(k<7) {
      if(k&1) {
        ol("INX SP");
        k--;
        }
      while(k) {
        ol("POP B");
        k=k-BPW;
        }
      return newsp;
      }
    }
  if(k<0) {
    if(k>-7) {
      if(k&1) {
        ol("DCX SP");
        k++;
        }
      while(k) {
        ol("PUSH B");
        k=k+BPW;
        }
      return newsp;
      }
    }
  if(save) swap();
  const(k);
  ol("DAD SP");
  ol("SPHL");
  if(save) swap();
  return newsp;
  }

/*
** double primary register
*/
doublereg() {ol("DAD H");}

>>> CC42.C 5615
/*
** add primary and secondary registers (result in primary)
*/
ffadd() {ol("DAD D");}

/*
** subtract primary from secondary register (result in primary)
*/
ffsub() {ffcall("CCSUB##");}

/*
** multiply primary and secondary registers (result in primary)
*/
ffmult() {ffcall("CCMULT##");}

/*
** divide secondary by primary register
** (quotient in primary, remainder in secondary)
*/
ffdiv() {ffcall("CCDIV##");}

/*
** remainder of secondary/primary
** (remainder in primary, quotient in secondary)
*/
ffmod() {ffdiv();swap();}

/*
** inclusive "or" primary and secondary registers
** (result in primary)
*/
ffor() {ffcall("CCOR##");}

/*
** exclusive "or" the primary and secondary registers
** (result in primary)
*/
ffxor() {ffcall("CCXOR##");}

/*
** "and" primary and secondary registers
** (result in primary)
*/
ffand() {ffcall("CCAND##");}

/*
** logical negation of primary register
*/
lneg() {ffcall("CCLNEG##");}

/*
** arithmetic shift right secondary register
** number of bits given in primary register
** (result in primary)
*/
ffasr() {ffcall("CCASR##");}

/*
** arithmetic shift left secondary register
** number of bits given in primary register
** (result in primary)
*/
ffasl() {ffcall("CCASL##");}

/*
** two's complement primary register
*/
neg() {ffcall("CCNEG##");}

/*
** one's complement primary register
*/
com() {ffcall("CCCOM##");}

/*
** increment primary register by one object of whatever size
*/
inc(n) int n; {
  while(1) {
    ol("INX H");
    if(--n < 1) break;
    }
  }

/*
** decrement primary register by one object of whatever size
*/
dec(n) int n; {
  while(1) {
    ol("DCX H");
    if(--n < 1) break;
    }
  }
 
/*
** test for equal to
*/
ffeq()  {ffcall("CCEQ##");}

/*
** test for equal to zero
*/
eq0(label) int label; {
  ol("MOV A,H");
  ol("ORA L");
  ot("JNZ ");
  printlabel(label);
  nl();
  }

/*
** test for not equal to
*/
ffne()  {ffcall("CCNE##");}

/*
** test for not equal to zero
*/
ne0(label) int label; {
  ol("MOV A,H");
  ol("ORA L");
  ot("JZ ");
  printlabel(label);
  nl();
  }

/*
** test for less than (signed)
*/
fflt()  {ffcall("CCLT##");}

/*
** test for less than to zero
*/
lt0(label) int label; {
  ol("XRA A");
  ol("ORA H");
  ot("JP ");
  printlabel(label);
  nl();
  }

/*
** test for less than or equal to (signed)
*/
ffle()  {ffcall("CCLE##");}

/*
** test for less than or equal to zero
*/
le0(label) int label; {
  ol("MOV A,H");
  ol("ORA L");
  ol("JZ $+8");
  ol("XRA A");
  ol("ORA H");
  ot("JP ");
  printlabel(label);
  nl();
  }

/*
** test for greater than (signed)
*/
ffgt()  {ffcall("CCGT##");}

/*
** test for greater than to zero
*/
gt0(label) int label; {
  ol("XRA A");
  ol("ORA H");
  ot("JM ");
  printlabel(label);
  nl();
  ol("ORA L");
  ot("JZ ");
  printlabel(label);
  nl();
  }

/*
** test for greater than or equal to (signed)
*/
ffge()  {ffcall("CCGE##");}

/*
** test for gteater than or equal to zero
*/
ge0(label) int label; {
  ol("XRA A");
  ol("ORA H");
  ot("JM ");
  printlabel(label);
  nl();
  }

/*
** test for less than (unsigned)
*/
ult()  {ffcall("CCULT##");}

/*
** test for less than to zero (unsigned)
*/
ult0(label) int label; {
  ot("JMP ");
  printlabel(label);
  nl();
  }

/*
** test for less than or equal to (unsigned)
*/
ule()  {ffcall("CCULE##");}

/*
** test for greater than (unsigned)
*/
ugt()  {ffcall("CCUGT##");}

/*
** test for greater than or equal to (unsigned)
*/
uge()  {ffcall("CCUGE##");}

#ifdef OPTIMIZE
peephole(ptr) char *ptr; {
  while(*ptr) {
    if(streq(ptr,"LXI H,0\nDAD SP\nCALL CCGINT##")) {
      if(streq(ptr+29, "XCHG;;")) {pp2();ptr=ptr+36;}
      else                        {pp1();ptr=ptr+29;}
      }
    else if(streq(ptr,"LXI H,2\nDAD SP\nCALL CCGINT##")) {
      if(streq(ptr+29, "XCHG;;")) {pp3(pp2);ptr=ptr+36;}
      else                        {pp3(pp1);ptr=ptr+29;}
      }
    else if(optimize) {
      if(streq(ptr, "DAD SP\nCALL CCGINT##")) {
        ol("CALL CCDSGI##");
        ptr=ptr+21;
        }
      else if(streq(ptr, "DAD D\nCALL CCGINT##")) {
        ol("CALL CCDDGI##");
        ptr=ptr+20;
        }
      else if(streq(ptr, "DAD SP\nCALL CCGCHAR##")) {
        ol("CALL CCDSGC##");
        ptr=ptr+22;
          }
      else if(streq(ptr, "DAD D\nCALL CCGCHAR##")) {
        ol("CALL CCDDGC##");
        ptr=ptr+21;
        }
      else if(streq(ptr,
        "DAD SP\nMOV D,H\nMOV E,L\nCALL CCGINT##\nINX H\nCALL CCPINT##")) {
        ol("CALL CCINCI##");
        ptr=ptr+57;
        }
      else if(streq(ptr,
        "DAD SP\nMOV D,H\nMOV E,L\nCALL CCGINT##\nDCX H\nCALL CCPINT##")) {
        ol("CALL CCDECI##");
        ptr=ptr+57;
        }
      else if(streq(ptr,
        "DAD SP\nMOV D,H\nMOV E,L\nCALL CCGCHAR##\nINX H\nMOV A,L\nSTAX D")) {
        ol("CALL CCINCC##");
        ptr=ptr+59;
        }
      else if(streq(ptr,
        "DAD SP\nMOV D,H\nMOV E,L\nCALL CCGCHAR##\nDCX H\nMOV A,L\nSTAX D")) {
        ol("CALL CCDECC##");
        ptr=ptr+59;
        }
      else if(streq(ptr, "DAD D\nPOP D\nCALL CCPINT##")) {
        ol("CALL CDPDPI##");
        ptr=ptr+26;
        }
      else if(streq(ptr, "DAD D\nPOP D\nMOV A,L\nSTAX D")) {
        ol("CALL CDPDPC##");
        ptr=ptr+27;
        }
      else if(streq(ptr, "POP D\nCALL CCPINT##")) {
        ol("CALL CCPDPI##");
        ptr=ptr+20;
        }
      /* additional optimizing logic goes here */
      else cout(*ptr++, output);
      }
    else cout(*ptr++, output);
    }
  }

pp1() {
  ol("POP H");
  ol("PUSH H");
  }

pp2() {
  ol("POP D");
  ol("PUSH D");
  }

pp3(pp) int (*pp)(); {
  ol("POP B");
  (*pp)();
  ol("PUSH B");
  }
#endif

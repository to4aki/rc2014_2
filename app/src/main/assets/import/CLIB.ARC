>>> ABS.C 116
/*
** abs -- returns absolute value of nbr
*/
abs(nbr)  int nbr; {
  if(nbr < 0) return (-nbr);
  return (nbr);
  }
>>> ATOI.C 308
#define NOCCARGC  /* no argument count passing */
/*
** atoi(s) - convert s to integer.
*/
atoi(s) char *s; {
  int sign, n;
  while(isspace(*s)) ++s;
  sign = 1;
  switch(*s) {
    case '-': sign = -1;
    case '+': ++s;
    }
  n = 0;
  while(isdigit(*s)) n = 10 * n + *s++ - '0';
  return (sign * n);
  }
>>> ATOIB.C 484
#define NOCCARGC  /* no argument count passing */
/*
** atoib(s,b) - Convert s to "unsigned" integer in base b.
**              NOTE: This is a non-standard function.
*/
atoib(s, b) char *s; int b; {
  int n, digit;
  n = 0;
  while(isspace(*s)) ++s;
  while((digit = (127 & *s++)) >= '0') {
    if(digit >= 'a')      digit -= 87;
    else if(digit >= 'A') digit -= 55;
    else                  digit -= '0';
    if(digit >= b) break;
    n = b * n + digit;
    }
  return (n);
  }

>>> AUXBUF.C 3204
#define NOCCARGC  /* no argument count passing */
#include stdio.h
#include clib.def
extern int *Uauxsz, Uauxin, Uauxrd, Uauxwt, Uauxfl, Ustatus[];
/*
** This module is loaded with a program only if auxbuf()
** is called.  It links to Uopen(), Uread(), Uwrite(), and
** fflush() through Uauxsz, Uauxin, Uauxrd, Uauxwt, and Uauxfl
** in CSYSLIB.  This technique reduces the overhead for
** programs which don't use auxiliary buffering.  Presumably,
** if there is enough memory for extra buffering, there is
** room to spare for this overhead too.  A bug in some
** versions of Small-C between 2.0 and 2.1 may cause the calls
** to Uauxrd, Uauxwt, and Uauxfl in Uread(), Uwrite(), and
** fflush(), respectively, to produce bad code.  The current
** compiler corrects the problem.
*/
int
  Uxsize[MAXFILES],  /* size of buffer */
  Uxaddr[MAXFILES],  /* aux buffer address */
  Uxnext[MAXFILES],  /* address of next byte in buffer */
  Uxend[MAXFILES],   /* address of end-of-data in buffer */
  Uxeof[MAXFILES];   /* true if current buffer ends file */
/*
** auxbuf -- allocate an auxiliary input buffer for fd
**   fd = file descriptor of an open file
** size = size of buffer to be allocated
** Returns NULL on success, else ERR.
** Note: Ungetc() still works.
**       A 2nd call returns ERR, but has no effect.
**       If fd is a device, buffer is allocated but ignored.
**       Buffer stays allocated when fd is closed.
**       Do not mix reads and writes or perform seeks on fd.
*/
auxbuf(fd, size) int fd; char *size; {   /* fake unsigned */
  if(!Umode(fd) || !size || avail(NO) < size   || Uxsize[fd])
    return (ERR);
  Uxaddr[fd] = malloc(size); Uxinit(fd);
  Uauxin = Uxinit;    /* tell Uopen() where Uxinit() is */
  Uauxrd = Uxread;    /* tell Uread() where Uxread() is */
  Uauxwt = Uxwrite;   /* tell Uwrite() where Uxwrite() is */
  Uauxsz = Uxsize;    /* tell both where Uxsize[] is */
  Uauxfl = Uxflush;   /* tell fflush() where Uxflush() is */
  Uxsize[fd] = size;  /* tell Uread() that fd has aux buf */
  return (NULL);
  }

/*
** Initialize aux buffer controls
*/
Uxinit(fd) int fd; {
  Uxnext[fd] = Uxend[fd] = Uxaddr[fd];
  Uxeof[fd] = NO;
  }

/*
** Fill buffer if necessary, and return next byte.
*/
Uxread(fd) int fd; {
  char *ptr;
  while(YES) {
    ptr = Uxnext[fd];
    if(ptr < Uxend[fd]) {++Uxnext[fd]; return (*ptr);}
    if(Uxeof[fd]) {Useteof(fd); return (EOF);}
    Uauxsz = NULL;          /* avoid recursive loop */
    Uxend[fd] = Uxaddr[fd]
              + read(fd, Uxnext[fd]=Uxaddr[fd], Uxsize[fd]);
    Uauxsz = Uxsize;        /* restore Uauxsz */
    if(feof(fd)) {Uxeof[fd] = YES; Uclreof(fd);}
    }
  }

/*
** Empty buffer if necessary, and store ch in buffer.
*/
Uxwrite(ch, fd) int ch, fd; {
  char *ptr;
  while(YES) {
    ptr = Uxnext[fd];
    if(ptr < (Uxaddr[fd] + Uxsize[fd]))
      {*ptr = ch; ++Uxnext[fd]; return (ch);}
    if(Uxflush(fd)) return (EOF);
    }
  }

/*
** Flush aux buffer to file.
*/
Uxflush(fd) int fd; {
  int i, j;
  i = Uxnext[fd] - Uxaddr[fd];
  Uauxsz = NULL;   /* avoid recursive loop */
  j = write(fd, Uxnext[fd]=Uxaddr[fd], i);
  Uauxsz = Uxsize; /* restore Uauxsz */
  if(i != j) return (EOF);
  return (NULL);
  }
>>> AVAIL.C 399
#define NOCCARGC  /* no argument count passing */
extern char *Umemptr;
/*
** Return the number of bytes of available memory.
** In case of a stack overflow condition, if 'abort'
** is non-zero the program aborts with an 'S' clue,
** otherwise zero is returned.
*/
avail(abort) int abort; {
  char x;
  if(&x < Umemptr) {
    if(abort) exit('M');
    return (0);
    }
  return (&x - Umemptr);
  }

>>> CALL.MAC 8487
;
;----- CALL: Small-C arithmetic and logical library
;
CCDCAL::
        PCHL
;
CCDDGC::
        DAD     D
        JMP     CCGCHAR
;
CCDSGC::
        INX     H
        INX     H
        DAD     SP
;
;FETCH A SINGLE BYTE FROM THE ADDRESS IN HL AND SIGN INTO HL
CCGCHAR::
        MOV     A,M
;
;PUT THE ACCUM INTO HL AND SIGN EXTEND THROUGH H.
CCARGC::
CCSXT::
        MOV     L,A
        RLC
        SBB     A
        MOV     H,A
        RET
;
CCDDGI::
        DAD     D
        JMP     CCGINT
;
CCDSGI::
        INX     H
        INX     H
        DAD     SP
;
;FETCH A FULL 16-BIT INTEGER FROM THE ADDRESS IN HL INTO HL
CCGINT::
        MOV     A,M
        INX     H
        MOV     H,M
        MOV     L,A
        RET
;
CCDECC::
        INX     H
        INX     H
        DAD     SP
        MOV     D,H
        MOV     E,L
        CALL    CCGCHAR
        DCX     H
        MOV     A,L
        STAX    D
        RET
;
CCINCC::
        INX     H
        INX     H
        DAD     SP
        MOV     D,H
        MOV     E,L
        CALL    CCGCHAR
        INX     H
        MOV     A,L
        STAX    D
        RET
;
CDPDPC::
        DAD     D
CCPDPC::
        POP     B       ;RET ADDR
        POP     D
        PUSH    B
;
;STORE A SINGLE BYTE FROM HL AT THE ADDRESS IN DE
CCPCHAR::
PCHAR:  MOV     A,L
        STAX    D
        RET
;
CCDECI::
        INX     H
        INX     H
        DAD     SP
        MOV     D,H
        MOV     E,L
        CALL    CCGINT
        DCX     H
        JMP     CCPINT
;
CCINCI::
        INX     H
        INX     H
        DAD     SP
        MOV     D,H
        MOV     E,L
        CALL    CCGINT
        INX     H
        JMP     CCPINT
;
CDPDPI::
        DAD     D
CCPDPI::
        POP     B       ;RET ADDR
        POP     D
        PUSH    B
;
;STORE A 16-BIT INTEGER IN HL AT THE ADDRESS IN DE
CCPINT::
PINT:   MOV     A,L
        STAX    D
        INX     D
        MOV     A,H
        STAX    D
        RET
;
;INCLUSIVE "OR" HL AND DE INTO HL
CCOR::
        MOV     A,L
        ORA     E
        MOV     L,A
        MOV     A,H
        ORA     D
        MOV     H,A
        RET
;
;EXCLUSIVE "OR" HL AND DE INTO HL
CCXOR::
        MOV     A,L
        XRA     E
        MOV     L,A
        MOV     A,H
        XRA     D
        MOV     H,A
        RET
;
;"AND" HL AND DE INTO HL
CCAND::
        MOV     A,L
        ANA     E
        MOV     L,A
        MOV     A,H
        ANA     D
        MOV     H,A
        RET
;
;IN ALL THE FOLLOWING COMPARE ROUTINES, HL IS SET TO 1 IF THE
;  CONDITION IS TRUE, OTHERWISE IT IS SET TO 0 (ZERO).
;
;TEST IF HL = DE
;
CCEQ::
        CALL    CCCMP
        RZ
        DCX     H
        RET
;
;TEST IF DE != HL
CCNE::
        CALL    CCCMP
        RNZ
        DCX     H
        RET
;
;TEST IF DE > HL (SIGNED)
CCGT::
        XCHG
        CALL    CCCMP
        RC
        DCX     H
        RET
;
;TEST IF DE <= HL (SIGNED)
CCLE::
        CALL    CCCMP
        RZ
        RC
        DCX     H
        RET
;
;TEST IF DE >= HL (SIGNED)
CCGE::
        CALL    CCCMP
        RNC
        DCX     H
        RET
;
;TEST IF DE < HL (SIGNED)
CCLT::
        CALL    CCCMP
        RC
        DCX     H
        RET
;
;COMMON ROUTINE TO PERFORM A SIGNED COMPARE OF DE AND HL
; THIS ROUTINE PERFORMS DE - HL AND SETS THE CONDITIONS:
; CARRY REFLECTS SIGN OF DIFFERENCE (SET MEANS DE < HL)
; ZERO/NON-ZERO SET ACCORDING TO EQUALITY.
CCCMP::
        MOV     A,H     ;INVERT SIGN OF HL
        XRI     80H
        MOV     H,A
        MOV     A,D     ;INVERT SIGN OF DE
        XRI     80H
        CMP     H       ;COMPARE MSBS
        JNZ     CCCMP1  ;DONE IF NEQ
        MOV     A,E     ;COMPARE LSBS
        CMP     L
CCCMP1: LXI H,1         ;PRESET TRUE COND
        RET
;
;TEST IF DE >= HL (UNSIGNED)
CCUGE::
        CALL    CCUCMP
        RNC
        DCX     H
        RET
;
;TEST IF DE < HL (UNSIGNED)
CCULT::
        CALL    CCUCMP
        RC
        DCX     H
        RET
;
;TEST IF DE > HL (UNSIGNED)
CCUGT::
        XCHG
        CALL    CCUCMP
        RC
        DCX     H
        RET
;
;TEST IF DE <= HL (UNSIGNED)
CCULE::
        CALL    CCUCMP
        RZ
        RC
        DCX     H
        RET
;
;COMMON ROUTINE TO PERFORM UNSIGNED COMPARE
; CARRY SET IF DE < HL
; ZERO/NONZERO SET ACCORDINGLY
CCUCMP::
        MOV     A,D
        CMP     H
        JNZ     UCMP1
        MOV     A,E
        CMP     L
UCMP1:  LXI     H,1
        RET
;
;SHIFT DE ARITHMETICALLY RIGHT BY HL AND RETURN IN HL
CCASR::
        XCHG
        DCR     E
        RM
        MOV     A,H
        RAL
        MOV     A,H
        RAR
        MOV     H,A
        MOV     A,L
        RAR
        MOV     L,A
        JMP     CCASR+1
;
;SHIFT DE ARITHMETICALLY LEFT BY HL AND RETURN IN HL
CCASL::
        XCHG
        DCR     E
        RM
        DAD     H
        JMP     CCASL+1
;
;SUBTRACT HL FROM DE AND RETURN IN HL
CCSUB::
        MOV     A,E
        SUB     L
        MOV     L,A
        MOV     A,D
        SBB     H
        MOV     H,A
        RET
;
;FORM THE TWO'S COMPLEMENT OF HL
CCNEG::
        CALL    CCCOM
        INX     H
        RET
;
;FORM THE ONE'S COMPLEMENT OF HL
CCCOM::
        MOV     A,H
        CMA
        MOV     H,A
        MOV     A,L
        CMA
        MOV     L,A
        RET
;
;MULTIPLY DE BY HL AND RETURN IN HL (SIGNED MULTIPLY)
CCMULT::
MULT:   MOV     B,H
        MOV     C,L
        LXI     H,0
MULT1:  MOV     A,C
        RRC
        JNC     MULT2
        DAD     D
MULT2:  XRA A
        MOV     A,B
        RAR
        MOV     B,A
        MOV     A,C
        RAR
        MOV     C,A
        ORA     B
        RZ
        XRA     A
        MOV     A,E
        RAL
        MOV     E,A
        MOV     A,D
        RAL
        MOV     D,A
        ORA     E
        RZ
        JMP     MULT1
;
;DIVIDE DE BY HL AND RETURN QUOTIENT IN HL, REMAINDER IN DE (SIGNED DIVIDE)
CCDIV::
DIV:    MOV     B,H
        MOV     C,L
        MOV     A,D
        XRA     B
        PUSH    PSW
        MOV     A,D
        ORA     A
        CM      CCDENEG
        MOV     A,B
        ORA     A
        CM      CCBCNEG
        MVI     A,16
        PUSH    PSW
        XCHG
        LXI     D,0
CCDIV1: DAD     H
        CALL    CCRDEL
        JZ      CCDIV2
        CALL    CCCMPBCDE
        JM      CCDIV2
        MOV     A,L
        ORI     1
        MOV     L,A
        MOV     A,E
        SUB     C
        MOV     E,A
        MOV     A,D
        SBB     B
        MOV     D,A
CCDIV2: POP     PSW
        DCR     A
        JZ      CCDIV3
        PUSH    PSW
        JMP     CCDIV1
CCDIV3: POP     PSW
        RP
        CALL    CCDENEG
        XCHG
        CALL    CCDENEG
        XCHG
        RET
;
;NEGATE THE INTEGER IN DE (INTERNAL ROUTINE)
CCDENEG: MOV    A,D
        CMA
        MOV     D,A
        MOV     A,E
        CMA
        MOV     E,A
        INX     D
        RET
;
;NEGATE THE INTEGER IN BC (INTERNAL ROUTINE)
CCBCNEG: MOV    A,B
        CMA
        MOV     B,A
        MOV     A,C
        CMA
        MOV     C,A
        INX     B
        RET
;
;ROTATE DE LEFT ONE BIT (INTERNAL ROUTINE)
CCRDEL: MOV     A,E
        RAL
        MOV     E,A
        MOV     A,D
        RAL
        MOV     D,A
        ORA     E
        RET
;
;COMPARE BC TO DE (INTERNAL ROUTINE)
CCCMPBCDE: MOV  A,E
        SUB     C
        MOV     A,D
        SBB     B
        RET
;
;LOGICAL NEGATION
CCLNEG::
        MOV     A,H
        ORA     L
        JNZ     $+6
        MVI     L,1
        RET
        LXI     H,0
        RET
;
; EXECUTE "SWITCH" STATEMENT
;
;  HL  =  SWITCH VALUE
; (SP) -> SWITCH TABLE
;         DW ADDR1, VALUE1
;         DW ADDR2, VALUE2
;         ...
;         DW 0
;        [JMP default]
;         continuation
;
CCSWITCH::
        XCHG            ;DE =  SWITCH VALUE
        POP     H       ;HL -> SWITCH TABLE
SWLOOP: MOV     C,M
        INX     H
        MOV     B,M     ;BC -> CASE ADDR, ELSE 0
        INX     H
        MOV     A,B
        ORA     C
        JZ      SWEND   ;DEFAULT OR CONTINUATION CODE
        MOV     A,M
        INX     H
        CMP     E
        MOV     A,M
        INX     H
        JNZ     SWLOOP
        CMP     D
        JNZ     SWLOOP
        MOV     H,B     ;CASE MATCHED
        MOV     L,C
SWEND:  PCHL
;
Uend: lhld  6           ;get bdos address
      sphl              ;use for base of stack
      lxi   h,Uend      ;get start of free memory
      shld  Umemptr##   ;use for memory allocation
      jmp   Umain##     ;parse command line, execute program
      end   Uend       
>>> CALLOC.C 360
#define NOCCARGC  /* no argument count passing */
#include stdio.h
/*
** Cleared-memory allocation of n items of size bytes.
** n     = Number of items to allocate space for.
** size  = Size of the items in bytes.
** Returns the address of the allocated block,
** else NULL for failure.
*/
calloc(n, size) char *n, *size; {
  return (Ualloc(n*size, YES));
  }
>>> CLEARERR.C 206
#define NOCCARGC  /* no arg count passing */
#include stdio.h
#include clib.def
extern int Ustatus[];
/*
** Clear error status for fd.
*/
clearerr(fd) int fd; {
  if(Umode(fd)) Ustatus[fd] &= ~ERRBIT;
  }

>>> CLIB.DEF 2056
/*
** CLIB.DEF -- Definitions for Small-C library functions.
**
** Copyright 1983  L. E. Payne and J. E. Hendrix
*/

/*
** Definition of CP/M FCB and additional parameters
*/
#define FCBSIZE   36  /* size of file control block */
#define DRIVE      0  /* CP/M drive designator offset */
#define NAMEOFF    1  /* CP/M file name offset */
#define NAMEOFF2  16  /* CP/M 2nd file name offset */
#define NAMESIZE   8  /* CP/M file name size */
#define TYPEOFF    9  /* CP/M file type offset */
#define TYPESIZE   3  /* CP/M file type size */
#define NTSIZE    11  /* CP/M file name & type size */
#define RRNOFF    33  /* CP/M random record number offset */
#define CPMEOF    26  /* CP/M end-of-file byte */
#define BUFSIZE  128  /* size of I/O buffer */
#define MAXFILES  10  /* maximum open files */
/*
** CP/M function calls
*/
#define GOCPM     0  /* go to CP/M */
#define RDRINP    3  /* reader input */
#define PUNOUT    4  /* punch output */
#define LSTOUT    5  /* list output */
#define DCONIO    6  /* direct console i/o */
#define OPNFIL   15  /* open file */
#define CLOFIL   16  /* close file */
#define FNDFIL   17  /* find first occurrence of a file */
#define FNDNXT   18  /* find next occurrence of a file */
#define DELFIL   19  /* delete file */
#define MAKFIL   22  /* make file */
#define RENAME   23  /* rename file */
#define SETDMA   26  /* set dma */
#define RDRND    33  /* read sector randomly */
#define POSEND   35  /* position file to end */
#define GETPOS   36  /* get number of current sector */
#define WRTRND   40  /* write sector randomly */
/*
** Device codes
*/
#define CPMCON DCONIO /* console */
#define CPMRDR RDRINP /* reader  */
#define CPMPUN PUNOUT /* punch   */
#define CPMLST LSTOUT /* list    */
/*
** File status bits
*/
#define RDBIT      1  /* open for read */
#define WRTBIT     2  /* open for write */
#define EOFBIT     4  /* eof condition */
#define ERRBIT     8  /* error condition */
/*
** ASCII characters
*/
#define ABORT    3
#define RUB      8
#define PAUSE   19
#define WIPE    24
#define DEL    127
>>> CSEEK.C 908
#define NOCCARGC  /* no argument count passing */
#include stdio.h
#include clib.def
extern int Ufcbptr[], Uchrpos[], Unextc[];
/*
** Position fd to the 128-byte record indicated by
** "offset" relative to the point indicated by "base."
** 
**     BASE     OFFSET-RELATIVE-TO
**       0      first record
**       1      current record
**       2      end of file (last record + 1)
**
** Returns NULL on success, else EOF.
*/
cseek(fd, offset, base) int fd, offset, base; {
  int oldrrn, *rrn;
  if(!Umode(fd) || isatty(fd) || fflush(fd)) return (EOF);
  rrn = Ufcbptr[fd] + RRNOFF;
  oldrrn = *rrn;
  switch (base) {
    case 2: Ubdos(POSEND, Ufcbptr[fd]);
    case 1: *rrn += offset; break;
    case 0: *rrn = offset;  break;
    default: return (EOF);
    }
  if(Usector(fd,  RDRND)) {
    *rrn = oldrrn;
    return (EOF);
    }
  Uchrpos[fd] = 0;
  Unextc[fd] = EOF;
  Uclreof(fd);
  return (NULL);
  }

>>> CSYSLIB.C 10216

/*
** CSYSLIB -- System-Level Library Functions
*/

#include stdio.h
#include clib.def
#define NOCCARGC    /* no argument count passing */
#define DIR         /* compile directory option */

/*
****************** System Variables ********************
*/

int
 *Uauxsz,            /* addr of Uxsize[] in AUXBUF */
  Uauxin,            /* addr of Uxinit() in AUXBUF */
  Uauxrd,            /* addr of Uxread() in AUXBUF */
  Uauxwt,            /* addr of Uxwrite() in AUXBUF */
  Uauxfl,            /* addr of Uxflush() in AUXBUF */

  Ucnt=1,            /* arg count for main */
  Uvec[20],          /* arg vectors for main */

  Ustatus[MAXFILES] = {RDBIT, WRTBIT, RDBIT|WRTBIT},
                     /* status of respective file */
  Udevice[MAXFILES] = {CPMCON, CPMCON, CPMCON},
                     /* non-disk device assignments */
  Unextc[MAXFILES]  = {EOF, EOF, EOF},
                     /* pigeonhole for ungetc bytes */
  Ufcbptr[MAXFILES], /* FCB pointers for open files */
  Ubufptr[MAXFILES], /* buffer pointers for files */
  Uchrpos[MAXFILES], /* character position in buffer */
  Udirty[MAXFILES];  /* "true" if changed buffer */

char
 *Umemptr,           /* pointer to free memory. */
  Uarg1[]="*";       /* first arg for main */

/*
*************** System-Level Functions *****************
*/

/*
** -- Process Command Line, Execute main(), and Exit to CP/M
*/
Umain() {
  Uparse();
  main(Ucnt,Uvec);
  exit(0);
  }

/*
** Parse command line and setup argc and argv.
*/
Uparse() {
  char *count, *ptr;
  count = 128;  /* CP/M command buffer address */
  ptr = Ualloc((count = *count&255)+1, YES);
  strncpy(ptr, 129, count);
  Uvec[0]=Uarg1;				/* first arg = "*" */
  while (*ptr) {
    if(isspace(*ptr)) {++ptr; continue;}
    switch(*ptr) {
      case '<': ptr = Uredirect(ptr, "r", stdin);
                continue;
      case '>': if(*(ptr+1) == '>')
                     ptr = Uredirect(ptr+1, "a", stdout);
                else ptr = Uredirect(ptr,   "w", stdout);
                continue;
      default:  if(Ucnt < 20) Uvec[Ucnt++] = ptr;
                ptr = Ufield(ptr);
      }
    }
  }

/*
** Isolate next command-line field.
*/
Ufield(ptr) char *ptr; {
  while(*ptr) {
    if(isspace(*ptr)) {
      *ptr = NULL;
      return (++ptr);
      }
    ++ptr;
    }
  return (ptr);
  }

/*
** Redirect stdin or stdout.
*/
Uredirect(ptr, mode, std)  char *ptr, *mode; int std; {
  char *fn;
  fn = ++ptr;
  ptr = Ufield(ptr);
  if(Uopen(fn, mode, std)==ERR) exit('R');
  return (ptr);
  }

/*
** ------------ File Open
*/

/*
** Open file on specified fd.
*/
Uopen(fn, mode, fd) char *fn, *mode; int fd; {
  char *fcb;
  if(!strchr("rwa", *mode)) return (ERR);
  Unextc[fd] = EOF;
  if(Uauxin) Uauxin(fd);
  if(strcmp(fn,"CON:")==0) {
    Udevice[fd]=CPMCON; Ustatus[fd]=RDBIT|WRTBIT; return (fd);
    }
  if(strcmp(fn,"RDR:")==0) {
    Udevice[fd]=CPMRDR; Ustatus[fd]=RDBIT;  return (fd);
    }
  if(strcmp(fn,"PUN:")==0) {
    Udevice[fd]=CPMPUN; Ustatus[fd]=WRTBIT; return (fd);
    }
  if(strcmp(fn,"LST:")==0) {
    Udevice[fd]=CPMLST; Ustatus[fd]=WRTBIT; return (fd);
    }
  if(fcb = Ufcbptr[fd]) pad(fcb, NULL, FCBSIZE);
  else {
    if((fcb = Ufcbptr[fd] = Ualloc(FCBSIZE, YES)) == NULL
          || (Ubufptr[fd] = Ualloc(BUFSIZE, YES)) == NULL)
        return (ERR);
    }
  pad(Ubufptr[fd], CPMEOF, BUFSIZE);
  Udirty[fd] = Udevice[fd] = Uchrpos[fd] = 0;
#ifdef DIR
  if(fn[1] == ':' && fn[2] == NULL) {  /* directory file */
    pad(fcb, NULL, FCBSIZE);
    pad(fcb+NAMEOFF, '?', NTSIZE);
    if(toupper(fn[0]) != 'X') *fcb = toupper(fn[0]) - 64;
    Uchrpos[fd] = BUFSIZE;
    Udevice[fd] = FNDFIL;
    Ustatus[fd] = RDBIT;
    return (fd);
    }
#endif
  if(!Unewfcb(fn,fcb)) return (ERR);
  switch(*mode) {
    case 'r': {
      if(Ubdos(OPNFIL,fcb)==255) return (ERR);
      Ustatus[fd] =  RDBIT;
      if(Usector(fd,  RDRND)) Useteof(fd);
      break;
      }
    case 'w': {
      if(Ubdos(FNDFIL,fcb)!=255) Ubdos(DELFIL,fcb);
    create:
      if(Ubdos(MAKFIL,fcb)==255) return (ERR);
      Ustatus[fd] = EOFBIT|WRTBIT;
      break;
      }
    default: {      /* append mode */
      if(Ubdos(OPNFIL,fcb)==255) goto create;
      Ustatus[fd] = RDBIT;
      cseek(fd, -1, 2);
      while(fgetc(fd)!=EOF) ;
      Ustatus[fd] = EOFBIT|WRTBIT;
      }
    }
  if(*(mode+1)=='+') Ustatus[fd] |= RDBIT|WRTBIT;
  return (fd);
  }

/*
** Create CP/M file control block from file name. 
** Entry: fn  = Legal CP/M file name (null terminated)
**              May be prefixed by letter of drive.
**        fcb = Pointer to memory space for CP/M fcb.
** Returns the pointer to the fcb.
*/
Unewfcb(fn, fcb) char *fn, *fcb; {
  char *fnptr;
  pad(fcb+1, SPACE, NTSIZE);
  if(*(fn + 1) == ':') {
    *fcb = toupper(*fn) - 64;
    fnptr = fn + 2;
    }
  else fnptr = fn;
  if(*fnptr == NULL) return (NO);
  fnptr = Uloadfn(fcb + NAMEOFF, fnptr, NAMESIZE);
  if(*fnptr == '.') ++fnptr;
  else if(*fnptr) return (NO);
  fnptr = Uloadfn(fcb + TYPEOFF, fnptr, TYPESIZE);
  if(*fnptr) return (NO);
  return (YES);
  }

/*
** Load into fcb and validate file name.
*/
Uloadfn(dest, sour, max) char *dest, *sour; int max; {
  while(*sour && !strchr("<>.,;:=?*[]", *sour)) {
    if(max--) *dest++ = toupper(*sour++);
    else break;
    }
  return (sour);
  }

/*
** ------------ File Input
*/

/*
** Binary-stream input of one byte from fd.
*/
Uread(fd) int fd; {
  char *bufloc;
  int ch;
  switch (Umode(fd)) {
    default: Useterr(fd); return (EOF);
    case RDBIT:
    case RDBIT|WRTBIT:
    }
  if((ch = Unextc[fd]) != EOF) {
    Unextc[fd] = EOF;
    return (ch);
    }
  switch(Udevice[fd]) {
    /* PUN & LST can't occur since they are write mode */
    case CPMCON: return (Uconin());
    case CPMRDR: return (Ubdos(RDRINP,NULL));
    default:
         if(Uauxsz && Uauxsz[fd]) return (Uauxrd(fd));
         if(Uchrpos[fd]>=BUFSIZE && !Ugetsec(fd))
           return (EOF);
         bufloc = Ubufptr[fd] + Uchrpos[fd]++;
         return (*bufloc);
    }
  }

/*
** Console character input.
*/
Uconin() {
  int ch;
  while(!(ch = Ubdos(DCONIO, 255))) ;
  switch(ch) {
    case ABORT: exit(0);
    case    LF:
    case    CR: Uconout(LF); return (Uconout(CR));
    case   DEL: ch = RUB;
       default: if(ch < 32) { Uconout('^'); Uconout(ch+64);}
                else Uconout(ch);
                return (ch);
    }
  }

/*
** Read one sector from fd.
*/
Ugetsec(fd) int fd; {
#ifdef DIR
  if(Udevice[fd]) {        /* directory file */
    char *bp, *name, *type, *end;
    Ubdos(SETDMA, 128);
    if((name = Ubdos(Udevice[fd], Ufcbptr[fd])) == 255) {
      Useteof(fd);
      return (NO);
      }
    Udevice[fd] = FNDNXT;
    name = (name << 5) + (128 + NAMEOFF);
    type = name + NAMESIZE;
    end = name + NTSIZE;
    bp = Ubufptr[fd] + BUFSIZE;
    *--bp = CR;
    while(--end >= name) { /* put filename at end of buffer */
      if(*end == SPACE) continue;
      *--bp = *end;
      if(end == type) *--bp = '.';
      }
    Uchrpos[fd] = bp - Ubufptr[fd];
    return (YES);
    }
#endif
  if(fflush(fd)) return (NO);
  Uadvance(fd);
  if(Usector(fd, RDRND)) {
    pad(Ubufptr[fd], CPMEOF, BUFSIZE);
    Useteof(fd);
    return (NO);
    }
  return (YES);
  }

/*
** ------------ File Output
*/

/*
** Binary-Stream output of one byte to fd.
*/
Uwrite(ch, fd) int ch, fd; {
  char *bufloc;
  switch (Umode(fd)) {
    default: Useterr(fd); return (EOF);
    case WRTBIT:
    case WRTBIT|RDBIT:
    case WRTBIT|EOFBIT:
    case WRTBIT|EOFBIT|RDBIT:
    }
  switch(Udevice[fd]) {
    /* RDR can't occur since it is read mode */
    case CPMCON: return (Uconout(ch));
    case CPMPUN:
    case CPMLST: Ubdos(Udevice[fd], ch);
                 break;
    default:
      if(Uauxsz && Uauxsz[fd]) return (Uauxwt(ch, fd));
      if(Uchrpos[fd]>=BUFSIZE && !Uputsec(fd)) return (EOF);
      bufloc = Ubufptr[fd] + Uchrpos[fd]++;
      *bufloc = ch;
      Udirty[fd] = YES;
    }
  return (ch);
  }

/*
** Console character output.
*/
Uconout(ch) int ch; {
  Ubdos(DCONIO, ch);
  return (ch);
  }

/*
** Write one sector to fd. 
*/
Uputsec(fd) int fd; {
  if(fflush(fd)) return (NO);
  Uadvance(fd);
  if(Ustatus[fd]&EOFBIT || Usector(fd, RDRND))
    pad(Ubufptr[fd], CPMEOF, BUFSIZE);
  return (YES);
  }

/*
** ------------ Buffer Service
*/

/*
** Advance to next sector.
*/
Uadvance(fd) int fd; {
  int *rrn;
  rrn = Ufcbptr[fd] + RRNOFF;
  ++(*rrn);
  Uchrpos[fd] = 0;
  }

/*
** Sector I/O.
*/
Usector(fd, func) int fd, func; {
  int error;
  Ubdos(SETDMA, Ubufptr[fd]);
  error = Ubdos(func, Ufcbptr[fd]);
  Ubdos(SETDMA, 128);
  Udirty[fd] = NO;
  return (error);
  }

/*
** ------------ File Status
*/

/*
** Return fd's open mode, else NULL.
*/
Umode(fd) char *fd; {
  if(fd < MAXFILES) return (Ustatus[fd]);
  return (NULL);
  }

/*
** Set eof status for fd and
** disable future i/o unless writing is allowed.
*/
Useteof(fd) int fd; {
  Ustatus[fd] |= EOFBIT;
  }

/*
** Clear eof status for fd.
*/
Uclreof(fd) int fd; {
  Ustatus[fd] &= ~EOFBIT;
  }

/*
** Set error status for fd.
*/
Useterr(fd) int fd; {
  Ustatus[fd] |= ERRBIT;
  }

/*
** ------------ Memory Allocation
*/

/*
** Allocate n bytes of (possibly zeroed) memory.
** Entry: n = Size of the items in bytes.
**    clear = "true" if clearing is desired.
** Returns the address of the allocated block of memory
** or NULL if the requested amount of space is not available.
*/
Ualloc(n, clear) char *n; int clear; {
  char *oldptr;
  if(n < avail(YES)) {
    if(clear) pad(Umemptr, NULL, n);
    oldptr = Umemptr;
    Umemptr += n;
    return (oldptr);
    }
  return (NULL);
  }

/*
** ------------ CP/M Interface
*/

/*
** Issue CP/M function and return result. 
** Entry: c  = CP/M function code (register C)
**        de = CP/M parameter (register DE or E)
** Returns the CP/M return code (register A)
*/
Ubdos(c,de) int c,de; {
#asm
        pop     h       ;hold return address
        pop     d       ;load CP/M function parameter
        pop     b       ;load CP/M function number
        push    b       ;restore
        push    d       ;  the
        push    h       ;     stack
        call    5       ;call bdos
        mvi     h,0     ;
        mov     l,a     ;return the CP/M response
#endasm
  }
>>> CTELL.C 397
#define NOCCARGC  /* no arg count passing */
#include stdio.h
#include clib.def
extern int Ufcbptr[], Uchrpos[];
/*
** Return offset to current 128-byte record.
*/
ctell(fd) int fd; {
  int *rrn;
  if(!Umode(fd) || isatty(fd)) return (-1);
  rrn=Ufcbptr[fd]+RRNOFF;
  return (*rrn);
  }
/*
** Return offset to next character in current buffer.
*/
ctellc(fd) int fd; {
  return (Uchrpos[fd]);
  }

>>> DTOI.C 417
#define NOCCARGC  /* no argument count passing */
#include stdio.h
/*
** dtoi -- convert signed decimal string to integer nbr
**         returns field length, else ERR on error
*/
dtoi(decstr, nbr)  char *decstr;  int *nbr;  {
  int len, s;
  if((*decstr)=='-') {s=1; ++decstr;} else s=0;
  if((len=utoi(decstr, nbr))<0) return ERR;
  if(*nbr<0) return ERR;
  if(s) {*nbr = -*nbr; return ++len;} else return len;
  }
>>> EXIT.C 420
#define NOCCARGC  /* no argument count passing */
#include stdio.h
#include clib.def
/*
** Close all open files and exit to CP/M. 
** Entry: errcode = Character to be sent to stderr.
** Returns to CP/M rather than the caller.
*/
exit(errcode) char errcode; {
  int fd;
  if(errcode) Uconout(errcode);
  for(fd=0; fd < MAXFILES; fclose(fd++));
  Ubdos(GOCPM,NULL);
  }
#asm
abort  equ    exit
       entry  abort
#endasm
>>> FCLOSE.C 442
#define NOCCARGC  /* no argument count passing */
#include stdio.h
#include clib.def
/*
** Close fd 
** Entry: fd = File descriptor for file to be closed.
** Returns NULL for success, otherwise ERR
*/
extern int Ufcbptr[], Ustatus[], Udevice[];
fclose(fd) int fd; {
  if(!Umode(fd)) return (ERR);
  if(!isatty(fd)) {
    if(fflush(fd) || Ubdos(CLOFIL,Ufcbptr[fd])==255)
      return (ERR);
    }
  return (Ustatus[fd]=Udevice[fd]=NULL);
  }

>>> FEOF.C 264
#define NOCCARGC  /* no argument count passing */
#include clib.def
extern int Ustatus[];
/*
** Test for end-of-file status.
** Entry: fd = file descriptor
** Returns non-zero if fd is at eof, else zero.
*/
feof(fd) int fd; {
  return (Ustatus[fd] & EOFBIT);
  }

>>> FERROR.C 194
#define NOCCARGC  /* no arg count passing */
#include stdio.h
#include clib.def
extern Ustatus[];
/*
** Test for error status on fd.
*/
ferror(fd) int fd; {
  return (Ustatus[fd] & ERRBIT);
  }
>>> FFLUSH.C 584
#define NOCCARGC  /* no argument count passing */
#include stdio.h
#include clib.def
extern int Udirty[], *Uauxsz, Uauxfl;
/*
** Write buffer for fd if it has changes.
** Entry: fd = File descriptor of pertinent file.
** Returns NULL on success, otherwise EOF.
** Returns NULL if file is opened for input only
**         or if it is not a disk file.
*/
fflush(fd) int fd; {
  if(Umode(fd) & WRTBIT) {
    if((Uauxsz && Uauxsz[fd] && Uauxfl(fd)) ||
       (!isatty(fd) && Udirty[fd] && Usector(fd, WRTRND))) {
      Useterr(fd);
      return (ERR);
      }
    }
  return (NULL);
  }

>>> FGETC.C 761
#define NOCCARGC  /* no argument count passing */
#include stdio.h
#include clib.def
extern int Uchrpos[];
/*
** Character-stream input of one character from fd.
** Entry: fd = File descriptor of pertinent file.
** Returns the next character on success, else EOF.
*/
fgetc(fd) int fd; {
  int ch;
  while(1) {
    switch(ch = Uread(fd)) {
      default:     return (ch);
      case CPMEOF: switch(Uchrpos[fd]) {
                     default: --Uchrpos[fd];
                     case 0:
                     case BUFSIZE:
                     }
                   Useteof(fd);
                   return (EOF);
      case CR:     return ('\n');
      case LF:    /* NOTE: Uconin() maps LF -> CR */
      }
    }
  }
#asm
getc equ   fgetc
     entry getc
#endasm

>>> FGETS.C 1813
#define NOCCARGC  /* no arg count passing */
#include stdio.h
#include clib.def
/*
** Gets an entire string (including its newline
** terminator) or size-1 characters, whichever comes
** first. The input is terminated by a null character.
** Entry: str  = Pointer to destination buffer.
**        size = Size of the destination buffer.
**        fd   = File descriptor of pertinent file.
** Returns str on success, else NULL.
*/
fgets(str, size, fd) char *str; int size, fd; {
  return (Ugets(str, size, fd, 1));
  }

/*
** Gets an entire string from stdin (excluding its newline
** terminator) or size-1 characters, whichever comes
** first. The input is terminated by a null character.
** The user buffer must be large enough to hold the data.
** Entry: str  = Pointer to destination buffer.
** Returns str on success, else NULL.
*/
gets(str) char *str; {
  return (Ugets(str, 32767, stdin, 0));
  }

Ugets(str, size, fd, nl) char *str; int size, fd, nl; {
  int backup;
  char *next;
  next = str;
  while(--size > 0) {
    switch (*next = fgetc(fd)) {
      case  EOF: *next = NULL;
                 if(next == str) return (NULL);
                 return (str);
      case '\n': *(next + nl) = NULL;
                 return (str);
      case  RUB: if(next > str) backup = 1; else backup = 0;
                 goto backout;
      case WIPE: backup = next - str;
        backout:
                 if(iscons(fd)) {
                   fputs("\b \b\b \b", stderr);
                   ++size;
                   while(backup--) {
                     fputs("\b \b", stderr);
                     if(*--next < 32) fputs("\b \b", stderr);
                     ++size;
                     }
                   continue;
                   }
        default: ++next;
      }
    }
  *next = NULL;
  return (str);
  }

>>> FOPEN.C 771
#define NOCCARGC  /* no arg count passing */
#include stdio.h
#include clib.def
/*
** Open file indicated by fn.
** Entry: fn   = Null-terminated CP/M file name.
**               May be prefixed by letter of dirve.
**               May be just CON:, RDR:, PUN:, or LST:.
**        mode = "a"  - append
**               "r"  - read
**               "w"  - write
**               "a+" - append update
**               "r+" - read   update
**               "w+" - write  update
** Returns a file descriptor on success, else NULL.
*/
fopen(fn, mode) char *fn, *mode; {
  int fd;
  fd = 0; /* skip stdin (= error return) */
  while(++fd < MAXFILES) {
    if(Umode(fd) == NULL) {
      if(Uopen(fn, mode, fd)!=ERR) return (fd);
      break;
      }
    }
  return (NULL);
  }

>>> FPRINTF.C 2275
#define NOCCARGC 
/*
** Yes, that is correct.  Although these functions use an
** argument count, they do not call functions which need one.
*/
#include stdio.h
/*
** fprintf(fd, ctlstring, arg, arg, ...) - Formatted print.
** Operates as described by Kernighan & Ritchie.
** b, c, d, o, s, u, and x specifications are supported.
** Note: b (binary) is a non-standard extension.
*/
fprintf(argc) int argc; {
  int *nxtarg;
  nxtarg = CCARGC() + &argc;
  return(Uprint(*(--nxtarg), --nxtarg));
  }

/*
** printf(ctlstring, arg, arg, ...) - Formatted print.
** Operates as described by Kernighan & Ritchie.
** b, c, d, o, s, u, and x specifications are supported.
** Note: b (binary) is a non-standard extension.
*/
printf(argc) int argc; {
  return(Uprint(stdout, CCARGC() + &argc - 1));
  }

/*
** Uprint(fd, ctlstring, arg, arg, ...)
** Called by fprintf() and printf().
*/
Uprint(fd, nxtarg) int fd, *nxtarg; {
  int  arg, left, pad, cc, len, maxchr, width;
  char *ctl, *sptr, str[17];
  cc = 0;                                         
  ctl = *nxtarg--;                          
  while(*ctl) {
    if(*ctl!='%') {fputc(*ctl++, fd); ++cc; continue;}
    else ++ctl;
    if(*ctl=='%') {fputc(*ctl++, fd); ++cc; continue;}
    if(*ctl=='-') {left = 1; ++ctl;} else left = 0;       
    if(*ctl=='0') pad = '0'; else pad = ' ';           
    if(isdigit(*ctl)) {
      width = atoi(ctl++);
      while(isdigit(*ctl)) ++ctl;
      }
    else width = 0;
    if(*ctl=='.') {            
      maxchr = atoi(++ctl);
      while(isdigit(*ctl)) ++ctl;
      }
    else maxchr = 0;
    arg = *nxtarg--;
    sptr = str;
    switch(*ctl++) {
      case 'c': str[0] = arg; str[1] = NULL; break;
      case 's': sptr = arg;        break;
      case 'd': itoa(arg,str);     break;
      case 'b': itoab(arg,str,2);  break;
      case 'o': itoab(arg,str,8);  break;
      case 'u': itoab(arg,str,10); break;
      case 'x': itoab(arg,str,16); break;
      default:  return (cc);
      }
    len = strlen(sptr);
    if(maxchr && maxchr<len) len = maxchr;
    if(width>len) width = width - len; else width = 0; 
    if(!left) while(width--) {fputc(pad,fd); ++cc;}
    while(len--) {fputc(*sptr++,fd); ++cc; }
    if(left) while(width--) {fputc(pad,fd); ++cc;}  
    }
  return(cc);
  }

>>> FPUTC.C 574
#define NOCCARGC  /* no arg count passing */
#include stdio.h
#include clib.def
extern int Ustatus[];
/*
** Character-stream output of a character to fd.
** Entry: ch = Character to write.
**        fd = File descriptor of perinent file.
** Returns character written on success, else EOF.
*/
fputc(ch, fd) int ch, fd; {
  switch(ch) {
    case EOF:  Uwrite(CPMEOF, fd); break;
    case '\n': Uwrite(CR, fd); Uwrite(LF, fd); break;
    default:   Uwrite(ch, fd);
    }
  if(Ustatus[fd] & ERRBIT) return (EOF);
  return (ch);
  }
#asm
putc equ   fputc
     entry putc
#endasm
>>> FPUTS.C 306
#define NOCCARGC  /* no arg count passing */
#include stdio.h
#include clib.def
/*
** Write a string to fd. 
** Entry: string = Pointer to null-terminated string.
**        fd     = File descriptor of pertinent file.
*/
fputs(string,fd) char *string; int fd; {
  while(*string) fputc(*string++, fd) ;
  }

>>> FREAD.C 926
#define NOCCARGC  /* no argument count passing */
#include clib.def
extern int Ustatus[];
/*
** Item-stream read from fd.
** Entry: buf = address of target buffer
**         sz = size of items in bytes
**          n = number of items to read
**         fd = file descriptor
** Returns a count of the items actually read.
** Use feof() and ferror() to determine file status.
*/
fread(buf, sz, n, fd) char *buf; int sz, n, fd; {
  return (read(fd, buf, n*sz)/sz);
  }

/*
** Binary-stream read from fd.
** Entry:  fd = file descriptor
**        buf = address of target buffer
**          n = number of bytes to read
** Returns a count of the bytes actually read.
** Use feof() and ferror() to determine file status.
*/
read(fd, buf, n) int fd, n; char *buf; {
  char *cnt;  /* fake unsigned */
  cnt = 0;
  while(n--) {
    *buf++ = Uread(fd);
    if(Ustatus[fd] & (ERRBIT | EOFBIT)) break;
    ++cnt;
    }
  return (cnt);
  }
>>> FREE.C 417
#define NOCCARGC  /* no argument count passing */
extern char *Umemptr;
/*
** free(ptr) - Free previously allocated memory block.
** Memory must be freed in the reverse order from which
** it was allocated.
** ptr    = Value returned by calloc() or malloc().
** Returns ptr if successful or NULL otherwise.
*/
free(ptr) char *ptr; {
   return (Umemptr = ptr);
   }
#asm
cfree  equ    free
       entry  cfree
#endasm
>>> FREOPEN.C 729
#define NOCCARGC  /* no argument count passing */
#include stdio.h
/*
** Close previously opened fd and reopen it. 
** Entry: fn   = Null-terminated CP/M file name.
**               May be prefixed by letter of drive.
**               May be just CON:, RDR:, PUN:, or LST:.
**        mode = "a"  - append
**               "r"  - read
**               "w"  - write
**               "a+" - append update
**               "r+" - read   update
**               "w+" - write  update
**        fd   = File descriptor of pertinent file.
** Returns the original fd on success, else NULL.
*/
freopen(fn, mode, fd) char *fn, *mode; int fd; {
  if(fclose(fd)) return (NULL);
  if(Uopen(fn, mode, fd)==ERR) return (NULL);
  return (fd);
  }
>>> FSCANF.C 2685
#define NOCCARGC  /* no argument count passing */
/*
** Yes, that is correct.  Although these functions use an
** argument count, they do not call functions which need one.
*/
#include stdio.h
/*
** fscanf(fd, ctlstring, arg, arg, ...) - Formatted read.
** Operates as described by Kernighan & Ritchie.
** b, c, d, o, s, u, and x specifications are supported.
** Note: b (binary) is a non-standard extension.
*/
fscanf(argc) int argc; {
  int *nxtarg;
  nxtarg = CCARGC() + &argc;
  return (Uscan(*(--nxtarg), --nxtarg));
  }

/*
** scanf(ctlstring, arg, arg, ...) - Formatted read.
** Operates as described by Kernighan & Ritchie.
** b, c, d, o, s, u, and x specifications are supported.
** Note: b (binary) is a non-standard extension.
*/
scanf(argc) int argc; {
  return (Uscan(stdin, CCARGC() + &argc - 1));
  }

/*
** Uscan(fd, ctlstring, arg, arg, ...) - Formatted read.
** Called by fscanf() and scanf().
*/
Uscan(fd,nxtarg) int fd, *nxtarg; {
  char *carg, *ctl, *unsigned;
  int  *narg, wast, ac, width, ch, cnv, base, ovfl, sign;
  ac = 0;
  ctl = *nxtarg--;
  while(*ctl) {
    if(isspace(*ctl)) {++ctl; continue;}
    if(*ctl++ != '%') continue;
    if(*ctl == '*') {narg = carg = &wast; ++ctl;}
    else             narg = carg = *nxtarg--;
    ctl += utoi(ctl, &width);
    if(!width) width = 32767;
    if(!(cnv = *ctl++)) break;
    while(isspace(ch = fgetc(fd))) ;
    if(ch == EOF) {if(ac) break; else return(EOF);}
    ungetc(ch,fd);
    switch(cnv) {
      case 'c':
        *carg = fgetc(fd);
        break;
      case 's':
        while(width--) {
          if((*carg = fgetc(fd)) == EOF) break;
          if(isspace(*carg)) break;
          if(carg != &wast) ++carg;
          }
        *carg = 0;
        break;
      default:
        switch(cnv) {
          case 'b': base =  2; sign = 1; ovfl = 32767; break;
          case 'd': base = 10; sign = 0; ovfl =  3276; break;
          case 'o': base =  8; sign = 1; ovfl =  8191; break;
          case 'u': base = 10; sign = 1; ovfl =  6553; break;
          case 'x': base = 16; sign = 1; ovfl =  4095; break;
          default:  return (ac);
          }
        *narg = unsigned = 0;
        while(width-- && !isspace(ch=fgetc(fd)) && ch!=EOF) {
          if(!sign)
            if(ch == '-') {sign = -1; continue;}
            else sign = 1;
          if(ch < '0') return (ac);
          if(ch >= 'a')      ch -= 87;
          else if(ch >= 'A') ch -= 55;
          else               ch -= '0';
          if(ch >= base || unsigned > ovfl) return (ac);
          unsigned = unsigned * base + ch;
          }
        *narg = sign * unsigned;
      }
    ++ac;                          
    }
  return (ac);
  }

>>> FWRITE.C 998
#define NOCCARGC  /* no argument count passing */
#include clib.def
extern int Ustatus[];
/*
** Item-stream write to fd.
** Entry: buf = address of source buffer
**         sz = size of items in bytes
**          n = number of items to write
**         fd = file descriptor
** Returns a count of the items actually written or
** zero if an error occurred.
** May use ferror(), as always, to detect errors.
*/
fwrite(buf, sz, n, fd) char *buf; int sz, n, fd; {
  if(write(fd, buf, n*sz) == -1) return (0);
  return (n);
  }

/*
** Binary-stream write to fd.
** Entry:  fd = file descriptor
**        buf = address of source buffer
**          n = number of bytes to write
** Returns a count of the bytes actually written or
** -1 if an error occurred.
** May use ferror(), as always, to detect errors.
*/
write(fd, buf, n) int fd, n; char *buf; {
  char *cnt;  /* fake unsigned */
  cnt = n;
  while(cnt--) {
    Uwrite(*buf++, fd);
    if(Ustatus[fd] & ERRBIT) return (-1);
    }
  return (n);
  }
>>> GETARG.C 669
#define NOCCARGC  /* no argument count passing */
#include stdio.h
/*
** Get command line argument. 
** Entry: n    = Number of the argument.
**        s    = Destination string pointer.
**        size = Size of destination string.
**        argc = Argument count from main().
**        argv = Argument vector(s) from main().
** Returns number of characters moved on success,
** else EOF.
*/
getarg(n,s,size,argc,argv)
  int n; char *s; int size, argc, argv[]; {
  char *str;
  int i;
  if(n < 0 | n >= argc) {
    *s = NULL;
    return EOF;
    }
  i = 0;
  str=argv[n];
  while(i<size) {
    if((s[i]=str[i])==NULL) break;
    ++i;
    }
  s[i]=NULL;
  return i;
  }
>>> GETCHAR.C 158
#define NOCCARGC  /* no argument count passing */
#include stdio.h
/*
** Get next character from standard input. 
*/
getchar() {
  return (fgetc(stdin));
  }
>>> ISALNUM.C 163
/*
** return 'true' if c is alphanumeric
*/
isalnum(c) int c; {
  return ((c<='z' && c>='a') ||
          (c<='Z' && c>='A') ||
          (c<='9' && c>='0'));
  }
>>> ISALPHA.C 119
/*
** return 'true' if c is alphabetic
*/
isalpha(c) int c; {
  return ((c<='z' && c>='a') || (c<='Z' && c>='A'));
  }
>>> ISASCII.C 147
/*
** return 'true' if c is an ASCII character (0-127)
*/
isascii(c) char *c; {
  /* c is a simulated unsigned integer */
  return (c <= 127);
  }
>>> ISATTY.C 126
extern int Udevice[];
/*
** Return "true" if fd is a device, else "false"
*/
isatty(fd) int fd; {
  return (Udevice[fd]);
  }
>>> ISCNTRL.C 172
/*
** return 'true' if c is a control character
** (0-31 or 127)
*/
iscntrl(c) char *c; {
  /* c is a simulated unsigned integer */
  return ((c <= 31) || (c == 127));
  }
>>> ISCONS.C 157
#include stdio.h
#include clib.def
extern int Udevice[];
/*
** Determine if fd is the console.
*/
iscons(fd) int fd; {
  return (Udevice[fd] == CPMCON);
  }
>>> ISDIGIT.C 100
/*
** return 'true' if c is a decimal digit
*/
isdigit(c) int c; {
  return (c<='9' && c>='0');
  }
>>> ISGRAPH.C 115
/*
** return 'true' if c is a graphic character
** (33-126)
*/
isgraph(c) int c; {
  return (c>=33 && c<=126);
  }
>>> ISLOWER.C 106
/*
** return 'true' if c is lower-case alphabetic
*/
islower(c) int c; {
  return (c<='z' && c>='a');
  }
>>> ISPRINT.C 117
/*
** return 'true' if c is a printable character
** (32-126)
*/
isprint(c) int c; {
  return (c>=32 && c<=126);
  }
>>> ISPUNCT.C 206
#define NOCCARGC  /* no argument count passing */
/*
** return 'true' if c is a punctuation character
** (all but control and alphanumeric)
*/
ispunct(c) int c; {
  return (!isalnum(c) && !iscntrl(c));
  }
>>> ISSPACE.C 180
/*
** return 'true' if c is a white-space character
*/
isspace(c) int c; {
  /* first check gives quick exit in most cases */
  return(c<=' ' && (c==' ' || (c<=13 && c>=9)));
  }

>>> ISUPPER.C 106
/*
** return 'true' if c is upper-case alphabetic
*/
isupper(c) int c; {
  return (c<='Z' && c>='A');
  }
>>> ISXDIGIT.C 193
/*
** return 'true' if c is a hexadecimal digit
** (0-9, A-F, or a-f)
*/
isxdigit(c) int c; {
  return ((c<='f' && c>='a') ||
          (c<='F' && c>='A') ||
          (c<='9' && c>='0'));
  }
>>> ITOA.C 469
#define NOCCARGC  /* no argument count passing */
/*
** itoa(n,s) - Convert n to characters in s 
*/
itoa(n, s) char *s; int n; {
  int sign;
  char *ptr;
  ptr = s;
  if ((sign = n) < 0) /* record sign */
    n = -n;     /* make n positive */
  do {          /* generate digits in reverse order */
    *ptr++ = n % 10 + '0';         /* get next digit */
    } while ((n = n / 10) > 0);    /* delete it */
  if (sign < 0) *ptr++ = '-';
  *ptr = '\0';
  reverse(s);
  }
>>> ITOAB.C 475
#define NOCCARGC  /* no argument count passing */
/*
** itoab(n,s,b) - Convert "unsigned" n to characters in s using base b.
**                NOTE: This is a non-standard function.
*/
itoab(n, s, b) int n; char *s; int b; {
  char *ptr;
  int lowbit;
  ptr = s;
  b >>= 1;
  do {
    lowbit = n & 1;
    n = (n >> 1) & 32767;
    *ptr = ((n % b) << 1) + lowbit;
    if(*ptr < 10) *ptr += '0'; else *ptr += 55;
    ++ptr;
    } while(n /= b);
  *ptr = 0;
  reverse (s);
  }

>>> ITOD.C 620
#include stdio.h
/*
** itod -- convert nbr to signed decimal string of width sz
**         right adjusted, blank filled; returns str
**
**        if sz > 0 terminate with null byte
**        if sz = 0 find end of string
**        if sz < 0 use last byte for data
*/
itod(nbr, str, sz)  int nbr;  char str[];  int sz;  {
  char sgn;
  if(nbr<0) {nbr = -nbr; sgn='-';}
  else sgn=' ';
  if(sz>0) str[--sz]=NULL;
  else if(sz<0) sz = -sz;
  else while(str[sz]!=NULL) ++sz;
  while(sz) {
    str[--sz]=(nbr%10+'0');
    if((nbr=nbr/10)==0) break;
    }
  if(sz) str[--sz]=sgn;
  while(sz>0) str[--sz]=' ';
  return str;
  }
>>> ITOO.C 540
/*
** itoo -- converts nbr to octal string of length sz
**         right adjusted and blank filled, returns str
**
**        if sz > 0 terminate with null byte
**        if sz = 0 find end of string
**        if sz < 0 use last byte for data
*/
itoo(nbr, str, sz)  int nbr;  char str[];  int sz;  {
  int digit;
  if(sz>0) str[--sz]=0;
  else if(sz<0) sz = -sz;
  else while(str[sz]!=0) ++sz;
  while(sz) {
    digit=nbr&7; nbr=(nbr>>3)&8191;
    str[--sz]=digit+48;
    if(nbr==0) break;
    }
  while(sz) str[--sz]=' ';
  return str;
  }
>>> ITOU.C 618
#include stdio.h
/*
** itou -- convert nbr to unsigned decimal string of width sz
**         right adjusted, blank filled; returns str
**
**        if sz > 0 terminate with null byte
**        if sz = 0 find end of string
**        if sz < 0 use last byte for data
*/
itou(nbr, str, sz)  int nbr;  char str[];  int sz;  {
  int lowbit;
  if(sz>0) str[--sz]=NULL;
  else if(sz<0) sz = -sz;
  else while(str[sz]!=NULL) ++sz;
  while(sz) {
    lowbit=nbr&1;
    nbr=(nbr>>1)&32767;  /* divide by 2 */
    str[--sz]=((nbr%5)<<1)+lowbit+'0';
    if((nbr=nbr/5)==0) break;
    }
  while(sz) str[--sz]=' ';
  return str;
  }
>>> ITOX.C 595
/*
** itox -- converts nbr to hex string of length sz
**         right adjusted and blank filled, returns str
**
**        if sz > 0 terminate with null byte
**        if sz = 0 find end of string
**        if sz < 0 use last byte for data
*/
itox(nbr, str, sz)  int nbr;  char str[];  int sz;  {
  int digit, offset;
  if(sz>0) str[--sz]=0;
  else if(sz<0) sz = -sz;
  else while(str[sz]!=0) ++sz;
  while(sz) {
    digit=nbr&15; nbr=(nbr>>4)&4095;
    if(digit<10) offset=48; else offset=55;
    str[--sz]=digit+offset;
    if(nbr==0) break;
    }
  while(sz) str[--sz]=' ';
  return str;
  }
>>> LEFT.C 165
/*
** left -- left adjust and null terminate a string
*/
left(str) char *str; {
  char *str2;
  str2=str;
  while(*str2==' ') ++str2;
  while(*str++ = *str2++);
  }
>>> LEXCMP.C 1362
#define NOCCARGC  /* no argument count passing */
/*
** lexcmp(s, t) - Return a number <0, 0, or>0 
**                as s is <, =, or > t.
*/
lexcmp(s, t) char *s, *t; {
  while(lexorder(*s, *t) == 0)
    if(*s++) ++t;
    else return (0);
  return (lexorder(*s, *t));
  }

/*
** lexorder(c1, c2)
**
** Return a negative, zero, or positive number if
** c1 is less than, equal to, or greater than c2,
** based on a lexicographical (dictionary order)
** colating sequence.
**
*/
char Ulex[128] = {
     /**** NUL - / ****/
       0,  1,  2,  3,  4,  5,  6,  7,  8,  9,
      10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
      20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
      30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
      40, 41, 42, 43, 44, 45, 46, 47,
     /**** 0-9 ****/
      65, 66, 67, 68, 69, 70, 71, 72, 73, 74,
     /**** : ; < = > ? @ ****/
      48, 49, 50, 51, 52, 53, 54,
     /**** A-Z ****/
      75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87,
      88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99,100,
     /**** [ \ ] ^ U ` ****/
      55, 56, 57, 58, 59, 60,
     /**** a-z ****/
      75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87,
      88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99,100,
     /**** { | } ~ ****/
      61, 62, 63, 64,
     /**** DEL ****/
     101
     };

lexorder(c1, c2) char c1, c2; {
  return(Ulex[c1] - Ulex[c2]);
  }
>>> LINK.MAC 30
Ulink:: ext Umain
        end
>>> MALLOC.C 281
#define NOCCARGC  /* no argument count passing */
#include stdio.h
/*
** Memory allocation of size bytes.
** size  = Size of the block in bytes.
** Returns the address of the allocated block,
** else NULL for failure.
*/
malloc(size) char *size; {
  return (Ualloc(size, NO));
  }
>>> OTOI.C 365
#include stdio.h
/*
** otoi -- convert unsigned octal string to integer nbr
**          returns field size, else ERR on error
*/
otoi(octstr, nbr)  char *octstr;  int *nbr;  {
  int d,t; d=0;
  *nbr=0;
  while((*octstr>='0')&(*octstr<='7')) {
    t=*nbr;
    t=(t<<3) + (*octstr++ - '0');
    if ((t>=0)&(*nbr<0)) return ERR;
    d++; *nbr=t;
    }
  return d;
  }
>>> PAD.C 205
#define NOCCARGC  /* no argument count passing */
/*
** Place n occurrences of ch at dest.
*/
pad(dest, ch, n) char *dest, *n; int ch; {
  /* n is a fake unsigned integer */
  while(n--) *dest++ = ch;
  }
>>> POLL.C 377
#define NOCCARGC  /* no argument count passing */
#include stdio.h
#include clib.def
/*
** Poll for console input or interruption
*/
poll(pause) int pause; {
  int i;
  i = Ubdos(DCONIO, 255);
  if(pause) {
    if(i == PAUSE) {
      while(!(i = Ubdos(DCONIO, 255))) ;
      if(i == ABORT) exit(0);
      return (0);
      }
    if(i == ABORT) exit(0);
    }
  return (i);
  }
>>> PUTCHAR.C 169
#define NOCCARGC  /* no argument count passing */
#include stdio.h
/*
** Write character to standard output. 
*/
putchar(ch) int ch; {
  return (fputc(ch, stdout));
  }
>>> PUTS.C 191
#define NOCCARGC  /* no argument count passing */
#include stdio.h
/*
** Write string to standard output. 
*/
puts(string) char *string; {
  fputs(string, stdout);
  fputc('\n', stdout);
  }
>>> RENAME.C 539
#define NOCCARGC  /* no argument count passing */
#include stdio.h
#include clib.def
/*
** Rename a file.
**  from = address of old filename.
**    to = address of new filename.
**  Returns NULL on success, else ERR.
*/
rename(from, to) char *from, *to; {
  char fcb[FCBSIZE];
  pad(fcb, NULL, FCBSIZE);
  if(!Unewfcb(to, fcb) || Ubdos(OPNFIL, fcb) != 255) {
    Ubdos(CLOFIL, fcb);
    return (ERR);
    }
  if(Unewfcb(from, fcb) &&
     Unewfcb(to, fcb+NAMEOFF2) &&
     Ubdos(RENAME, fcb) != 255)
    return (NULL);
  return (ERR);
  }
>>> REVERSE.C 220
#define NOCCARGC  /* no argument count passing */
/*
** reverse string in place 
*/
reverse(s) char *s; {
  char *j;
  int c;
  j = s + strlen(s) - 1;
  while(s < j) {
    c = *s;
    *s++ = *j;
    *j-- = c;
    }
  }

>>> REWIND.C 138
#define NOCCARGC  /* no argument count passing */
/*
** Rewind file to beginning. 
*/
rewind(fd) int fd; {
  return(cseek(fd, 0, 0));
  }
>>> SIGN.C 148
/*
** sign -- return -1, 0, +1 depending on the sign of nbr
*/
sign(nbr)  int nbr;  {
  if(nbr>0) return 1;
  if(nbr==0) return 0;
  return -1;
  }
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
>>> STRCAT.C 175
/*
** concatenate t to end of s 
** s must be large enough
*/
strcat(s, t) char *s, *t; {
  char *d;
  d = s;
  --s;
  while (*++s) ;
  while (*s++ = *t++) ;
  return(d);
  }
>>> STRCHR.C 176
/*
** return pointer to 1st occurrence of c in str, else 0
*/
strchr(str, c) char *str, c; {
  while(*str) {
    if(*str == c) return (str);
    ++str;
    }
  return (0);
  }
>>> STRCMP.C 185
/*
** return <0,   0,  >0 aUording to
**       s<t, s=t, s>t
*/
strcmp(s, t) char *s, *t; {
  while(*s == *t) {
    if(*s == 0) return (0);
    ++s; ++t;
    }
  return (*s - *t);
  }

>>> STRCPY.C 111
/*
** copy t to s 
*/
strcpy(s, t) char *s, *t; {
  char *d;
  d = s;
  while (*s++ = *t++) ;
  return(d);
  }
>>> STRLEN.C 113
/*
** return length of s 
*/
strlen(s) char *s; {
  char *t;
  t = s - 1;
  while (*++t) ;
  return (t - s);
  }
>>> STRNCAT.C 254
/*
** concatenate n bytes max from t to end of s 
** s must be large enough
*/
strncat(s, t, n) char *s, *t; int n; {
  char *d;
  d = s;
  --s;
  while(*++s) ;
  while(n--) {
    if(*s++ = *t++) continue;
    return(d);
    }
  *s = 0;
  return(d);
  }
>>> STRNCMP.C 332
/*
** strncmp(s,t,n) - Compares two strings for at most n
**                  characters and returns an integer
**                  >0, =0, or <0 as s is >t, =t, or <t.
*/
strncmp(s, t, n) char *s, *t; int n; {
  while(n && *s==*t) {
    if (*s == 0) return (0);
    ++s; ++t; --n;
    }
  if(n) return (*s - *t);
  return (0);
  }
>>> STRNCPY.C 252
/*
** copy n characters from sour to dest (null padding)
*/
strncpy(dest, sour, n) char *dest, *sour; int n; {
  char *d;
  d = dest;
  while(n-- > 0) {
    if(*d++ = *sour++) continue;
    while(n-- > 0) *d++ = 0;
    }
  *d = 0;
  return (dest);
  }
>>> STRRCHR.C 314
/*
** strrchr(s,c) - Search s for rightmost occurrance of c.
** s      = Pointer to string to be searched.
** c      = Character to search for.
** Returns pointer to rightmost c or NULL.
*/
strrchr(s, c) char *s, c; {
  char *ptr;
  ptr = 0;
  while(*s) {
    if(*s==c) ptr = s;
    ++s;
    }
  return (ptr);
  }
>>> TOASCII.C 76
/*
** return ASCII equivalent of c
*/
toascii(c) int c; {
  return (c);
  }
>>> TOLOWER.C 130
/*
** return lower-case of c if upper-case, else c
*/
tolower(c) int c; {
  if(c<='Z' && c>='A') return (c+32);
  return (c);
  }
>>> TOUPPER.C 136
/*
** return upper-case of c if it is lower-case, else c
*/
toupper(c) int c; {
  if(c<='z' && c>='a') return (c-32);
  return (c);
  }
>>> UNGETC.C 342
#define NOCCARGC  /* no argument count passing */
#include stdio.h
extern Unextc[];
/*
** Put c back into file fd.
** Entry:  c = character to put back
**        fd = file descriptor
** Returns c if successful, else EOF.
*/
ungetc(c, fd) int c, fd; {
  if(!Umode(fd) || Unextc[fd]!=EOF || c==EOF) return (EOF);
  return (Unextc[fd] = c);
  }
>>> UNLINK.C 477
#define NOCCARGC  /* no arg count passing */
#include stdio.h
#include clib.def
/*
** Unlink (delete) the named file. 
** Entry: fn = Null-terminated CP/M file name.
**             May be prefixed by letter of drive.
** Returns NULL on success, else ERR.
*/
unlink(fn) char *fn; {
  char fcb[FCBSIZE];
  pad(fcb, NULL, FCBSIZE);
  if(Unewfcb(fn, fcb) && Ubdos(DELFIL, fcb) != 255)
    return (NULL);
  return (ERR);
  }
#asm
delete  equ    unlink
        entry  delete
#endasm
>>> UTOI.C 362
#include stdio.h
/*
** utoi -- convert unsigned decimal string to integer nbr
**          returns field size, else ERR on error
*/
utoi(decstr, nbr)  char *decstr;  int *nbr;  {
  int d,t; d=0;
  *nbr=0;
  while((*decstr>='0')&(*decstr<='9')) {
    t=*nbr;t=(10*t) + (*decstr++ - '0');
    if ((t>=0)&(*nbr<0)) return ERR;
    d++; *nbr=t;
    }
  return d;
  }
>>> XTOI.C 729
#include stdio.h
/*
** xtoi -- convert hex string to integer nbr
**         returns field size, else ERR on error
*/
xtoi(hexstr, nbr) char *hexstr; int *nbr; {
  int d, b;  char *cp;
  d = *nbr = 0; cp = hexstr;
  while(*cp == '0') ++cp;
  while(1) {
    switch(*cp) {
      case '0': case '1': case '2':
      case '3': case '4': case '5':
      case '6': case '7': case '8':
      case '9':                     b=48; break;
      case 'A': case 'B': case 'C':
      case 'D': case 'E': case 'F': b=55; break;
      case 'a': case 'b': case 'c':
      case 'd': case 'e': case 'f': b=87; break;
       default: return (cp - hexstr);
      }
    if(d < 4) ++d; else return (ERR);
    *nbr = (*nbr << 4) + (*cp++ - b);
    }
  }

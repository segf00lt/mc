%{
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include "mc.h"

extern char* progname;
extern char domain;
extern union Num outreg;
extern union Num acc;
extern struct Flags flags;

struct Var {
	union Num v;
	char d;
};
struct Var regs[26];

int yylex(void);
void yyerror(char* s);

double factorial(double n);
%}

%union {
	double r;
	unsigned long n;
	unsigned int b;
	int reg;
}

%start start
%token UNDEFINED
%token R_DOMAIN
%token Z_DOMAIN
%token N_DOMAIN
%token END
%token <reg> R_VAR
%token <reg> N_VAR
%token <r> REAL
%token <n> NATURAL
%token <r> PI E
%token ASSIGN
%token OREQ ANDEQ XOREQ LSHIFTEQ RSHIFTEQ
%token ADDEQ SUBEQ MULEQ DIVEQ MODEQ
%token LAND LOR
%token LT GT LTEQ GTEQ EQ NEQ
%token AND OR NOT XOR LSHIFT RSHIFT
%token ADD SUB MUL DIV MOD POW FACT OPAREN CPAREN
%token SIN COS TAN ASIN ACOS ATAN ROOT LN ABS LOG2 LOG
%left ASSIGN OREQ ANDEQ XOREQ LSHIFTEQ RSHIFTEQ ADDEQ SUBEQ MULEQ DIVEQ MODEQ
%left LOR
%left LAND
%left OR
%left XOR
%left AND
%left EQ NEQ
%left LT GT LTEQ GTEQ
%left LSHIFT RSHIFT
%left ADD SUB
%left MUL DIV MOD
%left LNOT NOT
%left POW
%left SIN COS TAN ASIN ACOS ATAN ROOT LN ABS LOG
%right FACT
%left OPAREN CPAREN
%type <r> r_expr r_primary r_builtin r_paren
%type <n> n_expr n_primary n_builtin n_paren

%%
start: r_expr END { outreg.r = $1; acc.r += $1; flags.assigned = 0;}
     | r_assign END { flags.assigned = 1; }
     | n_expr END { outreg.n = $1; acc.n += $1; flags.assigned = 0;}
     | n_assign END { flags.assigned = 1; }
     ;
r_assign: R_VAR ASSIGN r_expr { regs[$1].v.r = $3; regs[$1].d = 'r'; }
     	| R_VAR ADDEQ r_expr { regs[$1].v.r += $3; regs[$1].d = 'r'; }
     	| R_VAR SUBEQ r_expr { regs[$1].v.r -= $3; regs[$1].d = 'r'; }
     	| R_VAR MULEQ r_expr { regs[$1].v.r *= $3; regs[$1].d = 'r'; }
     	| R_VAR DIVEQ r_expr { regs[$1].v.r /= $3; regs[$1].d = 'r'; }
     	| R_VAR MODEQ r_expr { regs[$1].v.r = fmod(regs[$1].v.r,$3); regs[$1].d = 'r'; }
	;
r_expr: r_primary { $$ = $1; }
      | r_expr LAND r_expr { $$ = $1 && $3; }
      | r_expr LOR r_expr { $$ = $1 || $3; }
      | r_expr LT r_expr { $$ = $1 < $3; }
      | r_expr GT r_expr { $$ = $1 > $3; }
      | r_expr LTEQ r_expr { $$ = $1 <= $3; }
      | r_expr GTEQ r_expr { $$ = $1 >= $3; }
      | r_expr EQ r_expr { $$ = $1 == $3; }
      | r_expr NEQ r_expr { $$ = $1 != $3; }
      | r_expr ADD r_expr { $$ = $1 + $3; }
      | r_expr SUB r_expr { $$ = $1 - $3; }
      | r_expr MUL r_expr { $$ = $1 * $3; }
      | r_expr DIV r_expr { $$ = $1 / $3; }
      | r_expr MOD r_expr { $$ = fmod($1, $3); }
      | r_expr POW r_expr { $$ = pow($1, $3); }
      | r_expr FACT {
	if((round($1) == $1) && $1 > 0) $$ = factorial($1);
     	else {
		yyerror("attempted factorial on non natural");
		return 1;
	}
      }
      ;
r_primary: REAL { $$ = $1; }
	 | ADD r_primary { $$ = $2; }
	 | SUB r_primary { $$ = -$2; }
	 | LNOT r_primary { $$ = !$2; }
	 | R_VAR { $$ = regs[$1].v.r; }
         | PI { $$ = $1; }
         | E { $$ = $1; }
	 | r_builtin { $$ = $1; }
	 | r_paren { $$ = $1; }
	 ;
r_builtin: SIN r_paren { $$ = sin($2); }
          | COS r_paren { $$ = cos($2); }
          | TAN r_paren { $$ = tan($2); }
          | ASIN r_paren { $$ = asin($2); }
          | ACOS r_paren { $$ = acos($2); }
          | ATAN r_paren { $$ = atan($2); }
          | ROOT r_paren { $$ = sqrt($2); }
	  | ROOT REAL r_paren { $$ = pow($3, 1 / $2); }
          | ROOT r_paren r_paren { $$ = pow($3, 1 / $2); }
          | LN r_paren { $$ = log($2); }
          | ABS r_paren { $$ = fabs($2); }
          | LOG2 r_paren { $$ = log2($2); }
          | LOG r_paren { $$ = log10($2); }
	  ;
r_paren: OPAREN r_expr CPAREN { $$ = $2; }
       ;
n_assign: N_VAR ASSIGN n_expr END { regs[$1].v.n = $3; regs[$1].d = 'n'; }
     	| N_VAR OREQ n_expr END { regs[$1].v.n |= $3; regs[$1].d = 'n'; }
     	| N_VAR ANDEQ n_expr END { regs[$1].v.n &= $3; regs[$1].d = 'n'; }
     	| N_VAR XOREQ n_expr END { regs[$1].v.n ^= $3; regs[$1].d = 'n'; }
     	| N_VAR LSHIFTEQ n_expr END { regs[$1].v.n <<= $3; regs[$1].d = 'n'; }
     	| N_VAR RSHIFTEQ n_expr END { regs[$1].v.n >>= $3; regs[$1].d = 'n'; }
     	| N_VAR ADDEQ n_expr END { regs[$1].v.n += $3; regs[$1].d = 'n'; }
     	| N_VAR SUBEQ n_expr END { regs[$1].v.n -= $3; regs[$1].d = 'n'; }
     	| N_VAR MULEQ n_expr END { regs[$1].v.n *= $3; regs[$1].d = 'n'; }
     	| N_VAR DIVEQ n_expr END { regs[$1].v.n /= $3; regs[$1].d = 'n'; }
     	| N_VAR MODEQ n_expr END { regs[$1].v.n %= $3; regs[$1].d = 'n'; }
	;
n_expr: n_primary { $$ = $1; }
      | n_expr LAND n_expr { $$ = $1 && $3; }
      | n_expr LOR n_expr { $$ = $1 || $3; }
      | n_expr LT n_expr { $$ = $1 < $3; }
      | n_expr GT n_expr { $$ = $1 > $3; }
      | n_expr LTEQ n_expr { $$ = $1 <= $3; }
      | n_expr GTEQ n_expr { $$ = $1 >= $3; }
      | n_expr EQ n_expr { $$ = $1 == $3; }
      | n_expr NEQ n_expr { $$ = $1 != $3; }
      | n_expr OR n_expr { $$ = $1 | $3; }
      | n_expr XOR n_expr { $$ = $1 ^ $3; }
      | n_expr AND n_expr { $$ = $1 & $3; }
      | n_expr LSHIFT n_expr { $$ = $1 << $3; }
      | n_expr RSHIFT n_expr { $$ = $1 >> $3; }
      | n_expr ADD n_expr { $$ = $1 + $3; }
      | n_expr SUB n_expr { $$ = ($1 - $3) ? ((long)($1 - $3) > 0) : 0; }
      | n_expr MUL n_expr { $$ = $1 * $3; }
      | n_expr DIV n_expr { $$ = $1 / $3; }
      | n_expr MOD n_expr { $$ = $1 % $3; }
      | n_expr POW n_expr { $$ = (unsigned long)powl($1, $3); }
      ;
n_primary: NATURAL { $$ = $1; }
	 | SUB n_primary { $$ = -$2; }
	 | NOT n_primary { $$ = ~$2; }
	 | LNOT n_primary { $$ = !$2; }
	 | N_VAR { $$ = regs[$1].v.n; }
	 | n_builtin { $$ = $1; }
	 | n_paren { $$ = $1; }
	 ;
n_builtin: ROOT n_paren { $$ = (unsigned long)sqrtl((long double)$2); }
          | ROOT NATURAL n_paren { $$ = (unsigned long)powl((long double)$3, 1.0 / (long double)$2); }
	  | ROOT n_paren n_paren { $$ = (unsigned long)powl((long double)$3, 1.0 / (long double)$2); }
          | LOG2 n_paren { $$ = (unsigned long)log2l((long double)$2); }
          | LOG n_paren { $$ = (unsigned long)log10l((long double)$2); }
	  ;
n_paren: OPAREN n_expr CPAREN { $$ = $2; }
       ;
%%

double factorial(double n) {
	double result = n;
	for(double k = 1; k < n; ++k)
		result *= k;
	return result;
}

void yyerror(char* s) {
	fprintf(stderr, "%s: %s\n", progname, s);
}

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

unsigned long factorial(unsigned long n);
%}

%union {
	double r;
	unsigned long n;
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
%token AND OR BNOT XOR LSHIFT RSHIFT
%token ADD SUB MUL DIV MOD POW FACT OPAREN CPAREN
%token SIN COS TAN ASIN ACOS ATAN ROOT LN ABS LOG2 LOG
%left ASSIGN
%left OR
%left XOR
%left AND
%left LSHIFT RSHIFT
%left BNOT
%left ADD SUB
%left MUL DIV MOD
%left POW
%right FACT
%left SIN COS TAN ASIN ACOS ATAN ROOT LN ABS LOG
%left OPAREN CPAREN
%type <r> r_expr r_primary r_function r_paren
%type <n> n_expr n_primary n_function n_paren

%%
start: r_expr END { outreg.r = $1; acc.r += $1; flags.assigned = 0;}
     | n_expr END { outreg.n = $1; acc.n += $1; flags.assigned = 0;}
     | R_VAR ASSIGN r_expr END { regs[$1].v.r = $3; regs[$1].d = 'r'; flags.assigned = 1; }
     | N_VAR ASSIGN n_expr END { regs[$1].v.n = $3; regs[$1].d = 'n'; flags.assigned = 1; }
     ;
r_expr: r_primary { $$ = $1; }
      | r_expr ADD r_expr { $$ = $1 + $3; }
      | r_expr SUB r_expr { $$ = $1 - $3; }
      | r_expr MUL r_expr { $$ = $1 * $3; }
      | r_expr DIV r_expr { $$ = $1 / $3; }
      | r_expr MOD r_expr { $$ = fmod($1, $3); }
      | r_expr POW r_expr { $$ = pow($1, $3); }
      | r_expr FACT {
	if((round($1) == $1) && $1 > 0) $$ = (double)factorial($1);
     	else {
		yyerror("attempted factorial on non natural");
		return 1;
	}
      }
      ;
r_primary: REAL { $$ = $1; }
	 | ADD r_primary { $$ = $2; }
	 | SUB r_primary { $$ = -$2; }
	 | R_VAR { if(regs[$1].d != 'r') { yyerror("non real var in real expression"); return 1; }
		$$ = regs[$1].v.r; }
         | PI { $$ = $1; }
         | E { $$ = $1; }
	 | r_function { $$ = $1; }
	 | r_paren { $$ = $1; }
	 ;
r_function: SIN r_paren { $$ = sin($2); }
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
n_expr: n_primary { $$ = $1; }
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
	 | N_VAR { if(regs[$1].d != 'n') { yyerror("non natural var in natural expression"); return 1; }
	 	$$ = regs[$1].v.n; }
	 | SUB n_primary { $$ = -$2; }
	 | BNOT n_primary { $$ = ~$2; }
	 | n_function { $$ = $1; }
	 | n_paren { $$ = $1; }
	 ;
n_function: ROOT n_paren { $$ = (unsigned long)sqrtl($2); }
          | ROOT NATURAL n_paren { $$ = (unsigned long)powl($3, 1 / $2); }
	  | ROOT n_paren n_paren { $$ = (unsigned long)powl($3, 1 / $2); }
          | LOG2 n_paren { $$ = (unsigned long)log2l($2); }
          | LOG n_paren { $$ = (unsigned long)log10l($2); }
	  ;
n_paren: OPAREN n_expr CPAREN { $$ = $2; }
       ;
%%

unsigned long factorial(unsigned long n) {
	unsigned long result = n;
	for(unsigned long k = 1; k < n; ++k)
		result *= k;
	return result;
}

void yyerror(char* s) {
	fprintf(stderr, "%s: %s\n", progname, s);
}

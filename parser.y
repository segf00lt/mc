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
//union Num regs[26];

int yylex(void);
void yyerror(char* s);

unsigned long factorial(unsigned long n);
%}

%union {
	double r;
	long z;
	unsigned long n;
	int reg;
}

%start start
%token UNDEFINED
%token <reg> VAR
%token R_DOMAIN
%token Z_DOMAIN
%token N_DOMAIN
%token END
%token <r> REAL
%token <z> WHOLE
%token <n> NATURAL
%token <r> PI E
%token ASSIGN
%token AND OR NOT XOR LSHIFT RSHIFT
%token ADD SUB MUL DIV MOD POW FACT OPAREN CPAREN
%token SIN COS TAN ASIN ACOS ATAN ROOT LN ABS LOG
%left ASSIGN
%left OR
%left XOR
%left AND
%left LSHIFT RSHIFT
%left NOT
%left ADD SUB
%left MUL DIV MOD
%left POW
%right FACT
%left SIN COS TAN ASIN ACOS ATAN ROOT LN ABS LOG
%left OPAREN CPAREN
%type <r> r_expr r_primary r_function r_paren
%type <z> z_expr z_primary z_function z_paren
%type <n> n_expr n_primary n_function n_paren

%%
start: R_DOMAIN r_expr END { outreg.r = $2; acc.r += $2; flags.assigned = 0; }
     | Z_DOMAIN z_expr END { outreg.z = $2; acc.z += $2; flags.assigned = 0;}
     | N_DOMAIN n_expr END { outreg.n = $2; acc.n += $2; flags.assigned = 0;}
     | R_DOMAIN VAR ASSIGN r_expr END { regs[$2].v.r = $4; regs[$2].d = 'r'; flags.assigned = 1; }
     | Z_DOMAIN VAR ASSIGN z_expr END { regs[$2].v.z = $4; regs[$2].d = 'z'; flags.assigned = 1; }
     | N_DOMAIN VAR ASSIGN n_expr END { regs[$2].v.n = $4; regs[$2].d = 'n'; flags.assigned = 1; }
     ;
r_expr: r_primary { $$ = $1; }
      | r_function { $$ = $1; }
      | r_expr ADD r_expr { $$ = $1 + $3; }
      | r_expr SUB r_expr { $$ = $1 - $3; }
      | r_expr MUL r_expr { $$ = $1 * $3; }
      | r_expr DIV r_expr { $$ = $1 / $3; }
      | r_expr MOD r_expr { $$ = fmod($1, $3); }
      | r_expr POW r_expr { $$ = pow($1, $3); }
      ;
r_primary: REAL { $$ = $1; }
	 | ADD REAL { $$ = $2; }
	 | SUB REAL { $$ = -$2; }
	 | VAR { if(regs[$1].d != 'r') { yyerror("non real var in real expression"); return 1; }
		$$ = regs[$1].v.r; }
	 | ADD VAR { if(regs[$2].d != 'r') { yyerror("non real var in real expression"); return 1; }
		$$ = regs[$2].v.r; }
	 | SUB VAR { if(regs[$2].d != 'r') { yyerror("non real var in real expression"); return 1; }
	 	$$ = -regs[$2].v.r; }
         | PI { $$ = $1; }
         | E { $$ = $1; }
	 | ADD PI { $$ = $2; }
	 | SUB PI { $$ = -$2; }
	 | ADD E { $$ = $2; }
	 | SUB E { $$ = -$2; }
	 | r_paren { $$ = $1; }
	 ;
r_function: SIN r_paren { $$ = sin($2); }
          | COS r_paren { $$ = cos($2); }
          | TAN r_paren { $$ = tan($2); }
          | ASIN r_paren { $$ = asin($2); }
          | ACOS r_paren { $$ = acos($2); }
          | ATAN r_paren { $$ = atan($2); }
          | ROOT r_paren { $$ = sqrt($2); }
          | ROOT r_primary r_paren { $$ = pow($3, 1 / $2); }
          | LN r_paren { $$ = log($2); }
          | ABS r_paren { $$ = fabs($2); }
          | LOG r_paren { $$ = log10($2); }
	  ;
r_paren: OPAREN r_expr CPAREN { $$ = $2; }
       ;
z_expr: z_primary { $$ = $1; }
      | z_function { $$ = $1; }
      | z_expr ADD z_expr { $$ = $1 + $3; }
      | z_expr SUB z_expr { $$ = $1 - $3; }
      | z_expr MUL z_expr { $$ = $1 * $3; }
      | z_expr DIV z_expr { $$ = $1 / $3; }
      | z_expr MOD z_expr { $$ = $1 % $3; }
      | z_expr POW z_expr { $$ = (long)powl($1, $3); }
      ;
z_primary: WHOLE { $$ = $1; }
	 | VAR { if(regs[$1].d != 'z') { yyerror("non whole var in whole expression"); return 1; }
	 	$$ = regs[$1].v.z; }
	 | ADD VAR { if(regs[$2].d != 'z') { yyerror("non whole var in whole expression"); return 1; }
	 	$$ = regs[$2].v.z; }
	 | SUB VAR { if(regs[$2].d != 'z') { yyerror("non whole var in whole expression"); return 1; }
	 	$$ = -regs[$2].v.z; }
	 | ADD WHOLE { $$ = $2; }
	 | SUB WHOLE { $$ = -$2; }
	 | z_paren { $$ = $1; }
	 ;
z_function: ROOT z_paren { $$ = (long)sqrtl($2); }
          | ROOT z_primary z_paren { $$ = (long)powl($3, 1 / $2); }
          | ABS z_paren { $$ = labs($2); }
          | LOG z_paren { $$ = (long)log10l($2); }
	  ;
z_paren: OPAREN z_expr CPAREN { $$ = $2; }
       ;
n_expr: n_primary { $$ = $1; }
      | n_function { $$ = $1; }
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
      | n_expr FACT { $$ = factorial($1); }
      ;
n_primary: NATURAL { $$ = $1; }
	 | VAR { if(regs[$1].d != 'n') { yyerror("non natural var in natural expression"); return 1; }
	 	$$ = regs[$1].v.z; }
	 | NOT n_primary { $$ = $2; }
	 | n_paren { $$ = $1; }
	 ;
n_function: ROOT n_paren { $$ = (unsigned long)sqrtl($2); }
          | ROOT n_primary n_paren { $$ = (unsigned long)powl($3, 1 / $2); }
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

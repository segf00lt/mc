%{
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include "mc.h"

extern char* progname;
extern union Num outreg;
extern union Num acc;
extern struct Flags flags;

int yylex(void);
void yyerror(char* s);

union Num v[256];
int i = 0;

int c[256];
int j = 0;

double factorial(double n);
union Num chaincompare(void);
%}

%union {
	double r;
	unsigned long n;
}

%start start
%token UNDEFINED
%token END
%token <r> REAL
%token <n> NATURAL
%token <r> PI E
%token IF ELSE
%token LAND LOR
%token LT GT LTEQ GTEQ EQ NEQ
%token AND OR NOT XOR LSHIFT RSHIFT
%token ADD SUB MUL DIV MOD POW FACT OPAREN CPAREN
%token SIN COS TAN ASIN ACOS ATAN ROOT LN ABS LOG LOG2 LOG10
%left IF ELSE
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
%left SIN COS TAN ASIN ACOS ATAN ROOT LN ABS LOG LOG2 LOG10
%right FACT
%left OPAREN CPAREN
%type <r> r_conditional r_logic r_compare r_expr r_primary r_builtin r_paren
%type <n> n_conditional n_logic n_compare n_expr n_primary n_builtin n_paren

%%
start: r_conditional END { outreg.r = $1; acc.r += $1; }
     | n_conditional END { outreg.n = $1; acc.n += $1; }
     ;
r_conditional: r_logic { $$ = $1; }
	     | r_logic IF r_logic ELSE r_logic { $$ = $3 ? $1 : $5; }
	     ;
r_logic: r_compare { $$ = chaincompare().r; }
       | r_logic LAND r_logic { $$ = $1 && $3; }
       | r_logic LOR r_logic { $$ = $1 || $3; }
       ;
r_compare: r_expr { v[i++].r = $1; }
	 | r_compare LT r_compare { c[j++] = LT; }
	 | r_compare GT r_compare { c[j++] = GT; }
	 | r_compare LTEQ r_compare { c[j++] = LTEQ; }
	 | r_compare GTEQ r_compare { c[j++] = GTEQ; }
	 | r_compare EQ r_compare { c[j++] = EQ; }
	 | r_compare NEQ r_compare { c[j++] = NEQ; }
	 ;
r_expr: r_primary { $$ = $1; }
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
	 | LOG REAL r_paren { $$ = log($3) / log($2); }
	 | LOG PI r_paren { $$ = log($3) / log($2); }
	 | LOG E r_paren { $$ = log($3) / log($2); }
	 | LOG r_paren r_paren { $$ = log($3) / log($2); }
	 ;
r_paren: OPAREN r_conditional CPAREN { $$ = $2; }
       ;
n_conditional: n_logic { $$ = $1; }
	     | n_logic IF n_logic ELSE n_logic { $$ = $3 ? $1 : $5; }
	     ;
n_logic: n_compare { $$ = chaincompare().n; }
       | n_logic LAND n_logic { $$ = $1 && $3; }
       | n_logic LOR n_logic { $$ = $1 || $3; }
       ;
n_compare: n_expr { v[i++].n = $1; }
	 | n_compare LT n_compare { c[j++] = LT; }
	 | n_compare GT n_compare { c[j++] = GT; }
	 | n_compare LTEQ n_compare { c[j++] = LTEQ; }
	 | n_compare GTEQ n_compare { c[j++] = GTEQ; }
	 | n_compare EQ n_compare { c[j++] = EQ; }
	 | n_compare NEQ n_compare { c[j++] = NEQ; }
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
	 | SUB n_primary { $$ = -$2; }
	 | NOT n_primary { $$ = ~$2; }
	 | LNOT n_primary { $$ = !$2; }
	 | n_builtin { $$ = $1; }
	 | n_paren { $$ = $1; }
	 ;
n_builtin: ROOT n_paren { $$ = (unsigned long)sqrtl((long double)$2); }
         | ROOT NATURAL n_paren { $$ = (unsigned long)powl((long double)$3, 1.0 / (long double)$2); }
	 | ROOT n_paren n_paren { $$ = (unsigned long)powl((long double)$3, 1.0 / (long double)$2); }
         | LOG n_paren { $$ = (unsigned long)log2l((long double)$2); }
         | LOG10 n_paren { $$ = (unsigned long)log10l((long double)$2); }
	 ;
n_paren: OPAREN n_conditional CPAREN { $$ = $2; }
       ;
%%

double factorial(double n) {
	double result = n;
	for(double k = 1; k < n; ++k)
		result *= k;
	return result;
}

union Num chaincompare(void) {
	if(i == 1) {
		i = j = 0;
		return v[0];
	}

	union Num ret;
	unsigned int out = 1;

	switch(flags.mode) {
		case SCIMODE:
			goto r_comp;
		case BINMODE:
			goto n_comp;
	}

r_comp:
	for(int n = 0; n < j; ++n) {
		unsigned int op = 0;
		switch(c[n]) {
			case LT:
				op = v[n].r < v[n + 1].r;
				break;
			case GT:
				op = v[n].r > v[n + 1].r;
				break;
			case LTEQ:
				op = v[n].r <= v[n + 1].r;
				break;
			case GTEQ:
				op = v[n].r >= v[n + 1].r;
				break;
			case EQ:
				op = v[n].r == v[n + 1].r;
				break;
			case NEQ:
				op = v[n].r != v[n + 1].r;
				break;
		}
		out &= op;
	}
	i = j = 0;
	ret.r = out;
	return ret;

n_comp:
	for(int n = 0; n < j; ++n) {
		unsigned int op = 0;
		switch(c[n]) {
			case LT:
				op = v[n].n < v[n + 1].n;
				break;
			case GT:
				op = v[n].n > v[n + 1].n;
				break;
			case LTEQ:
				op = v[n].n <= v[n + 1].n;
				break;
			case GTEQ:
				op = v[n].n >= v[n + 1].n;
				break;
			case EQ:
				op = v[n].n == v[n + 1].n;
				break;
			case NEQ:
				op = v[n].n != v[n + 1].n;
				break;
		}
		out &= op;
	}
	i = j = 0;
	ret.n = out;
	return ret;
}

void yyerror(char* s) {
	fprintf(stderr, "%s: %s\n", progname, s);
}

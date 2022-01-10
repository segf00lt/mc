%{
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include "mc.h"

extern char* progname;
extern long outreg;
extern long acc;
extern unsigned int logicout;
extern struct Flags flags;

int yylex(void);
void yyerror(char* s);

int v[256];
int i = 0;

int c[256];
int j = 0;

long chaincompare(void);
%}

%union {
	long n;
}

%start start
%token UNDEFINED
%token END
%token <n> NATURAL
%token LAND LOR
%token LT GT LTEQ GTEQ EQ NEQ
%token AND OR NOT XOR LSHIFT RSHIFT
%token ADD SUB MUL DIV MOD POW LNOT OPAREN CPAREN
%token SQRT ABS LOG LOG10
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
%left SQRT ABS LOG LOG10
%left OPAREN CPAREN
%type <n> n_logic n_compare n_expr n_primary n_builtin n_paren

%%
start: n_logic END { outreg = $1; acc += $1; }
     ;
n_logic: n_compare { $$ = chaincompare(); }
       | n_logic LAND n_logic { $$ = $1 && $3; logicout = $1 && $3; }
       | n_logic LOR n_logic { $$ = $1 || $3; logicout = $1 || $3; }
       ;
n_compare: n_expr { v[i++] = $1; }
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
      | n_expr SUB n_expr { $$ = ((int)($1 - $3) > 0) ? ($1 - $3) : 0; }
      | n_expr MUL n_expr { $$ = $1 * $3; }
      | n_expr DIV n_expr { $$ = $1 / $3; }
      | n_expr MOD n_expr { $$ = $1 % $3; }
      | n_expr POW n_expr { $$ = (int)pow($1, $3); }
      ;
n_primary: NATURAL { $$ = $1; }
	 | SUB n_primary { $$ = -$2; }
	 | NOT n_primary { $$ = ~$2; }
	 | LNOT n_primary { $$ = !$2; }
	 | n_builtin { $$ = $1; }
	 | n_paren { $$ = $1; }
	 ;
n_builtin: SQRT n_paren { $$ = (int)sqrt((double)$2); }
         | LOG n_paren { $$ = (int)log2((double)$2); }
         | LOG10 n_paren { $$ = (int)log10((double)$2); }
	 ;
n_paren: OPAREN n_logic CPAREN { $$ = $2; }
       ;
%%

long chaincompare(void) {
	if(i == 1) {
		i = j = 0;
		logicout = 2;
		return v[0];
	}

	long ret;
	unsigned int out = 1;

	for(int n = 0; n < j; ++n) {
		unsigned int op = 0;
		switch(c[n]) {
			case LT:
				op = v[n] < v[n + 1];
				break;
			case GT:
				op = v[n] > v[n + 1];
				break;
			case LTEQ:
				op = v[n] <= v[n + 1];
				break;
			case GTEQ:
				op = v[n] >= v[n + 1];
				break;
			case EQ:
				op = v[n] == v[n + 1];
				break;
			case NEQ:
				op = v[n] != v[n + 1];
				break;
		}
		out &= op;
	}
	i = j = 0;
	logicout = !out;
	ret = out;
	return ret;
}

void yyerror(char* s) {
	fprintf(stderr, "%s: %s\n", progname, s);
}

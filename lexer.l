%{
#include <stdlib.h>
#include <math.h>
#include "y.tab.h"
#include "mc.h"
#define YY_NO_INPUT
#define YY_NO_UNPUT

extern char* progname;
extern char defaultdomain;
extern char domain;
extern char errstr[64];
extern struct Flags flags;
%}

%%
[0-9]+\.[0-9]* {
		yylval.r = atof(yytext);
		return REAL;
}
[0-9]+ { 
	switch(flags.mode) {
		case SCIMODE:
			yylval.r = atof(yytext);
			return REAL;
		case BINMODE:
			yylval.n = atol(yytext);
			return NATURAL;
	}
}
pi { yylval.r = M_PI; return PI; }
euler { yylval.r = M_E; return E; }
[a-z] {
	yylval.reg = yytext[0] - 'a';
	switch(flags.mode) {
		case SCIMODE:
			return R_VAR;
		case BINMODE:
			return N_VAR;
	}
}
\& { return AND; }
\| { return OR; }
\^ { return XOR; }
\~ { return BNOT; }
\<\< { return LSHIFT; }
\>\> { return RSHIFT; }
\+ { return ADD; }
\- { return SUB; }
\* { return MUL; }
\/ { return DIV; }
\% { return MOD; }
\*\* { return POW; }
\! { return FACT; }
\( { return OPAREN; }
\) { return CPAREN; }
\= { return ASSIGN; }
sin { return SIN; }
cos { return COS; }
tan { return TAN; }
asin { return ASIN; }
acos { return ACOS; }
atan { return ATAN; }
root { return ROOT; }
ln { return LN; }
abs { return ABS; }
log { return LOG; }
log2 { return LOG2; }
[ \t] ;
\n { return END; }
. { return UNDEFINED; }
%%

int yywrap(void) { return 1; }

%{
#include <stdlib.h>
#include <math.h>
#include "y.tab.h"
#include "mc.h"
#define YY_NO_INPUT
#define YY_NO_UNPUT
extern char domain;
%}

%%
[0-9]+\.[0-9]+ { yylval.r = atof(yytext);
		return REAL;
}
[0-9]+ { 
	switch(domain) {
		case 'r':
			yylval.r = atof(yytext);
			return REAL;
			break;
		case 'z':
			yylval.z = atol(yytext);
			return WHOLE;
			break;
		case 'n':
			yylval.n = atol(yytext);
			return NATURAL;
			break;
	}
}
^[rzn]\: {
	domain = yytext[0];
	switch(domain) {
		case 'r':
			return R_DOMAIN;
		case 'z':
			return Z_DOMAIN;
		case 'n':
			return N_DOMAIN;
	}
}
pi { yylval.r = M_PI; return PI; }
euler { yylval.r = M_E; return E; }
[a-z] { yylval.reg = yytext[0] - 'a'; return VAR; }
\& { return AND; }
\| { return OR; }
\^ { return XOR; }
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
[ \t] ;
\n { return END; }
. { return UNDEFINED; }
%%

int yywrap(void) { return 1; }

%{
#include <stdlib.h>
#include <math.h>
#include "y.tab.h"
#include "mc.h"
#define YY_NO_INPUT
#define YY_NO_UNPUT

extern void yyerror(char* s);
extern char errstr[64];
extern struct Flags flags;
%}

%%
[0-9]+ { 
	yylval.n = strtol(yytext, NULL, 10);
	return NATURAL;
}
0[bB][01]+ {
	yylval.n = strtoul(yytext + 2, NULL, 2);
	return NATURAL;
}
0[oO][0-7]+ {
	yylval.n = strtoul(yytext + 2, NULL, 8);
	return NATURAL;
}
0[xX][0-9a-fA-F]+ {
	yylval.n = strtoul(yytext, NULL, 16);
	return NATURAL;
}
if { return IF; }
else { return ELSE; }
not { return LNOT; }
and { return LAND; }
or { return LOR; }
\< { return LT; }
\> { return GT; }
\<\= { return LTEQ; }
\>\= { return GTEQ; }
\=\= { return EQ; }
\!\= { return NEQ; }
\& { return AND; }
\| { return OR; }
\^ { return XOR; }
\~ { return NOT; }
\<\< { return LSHIFT; }
\>\> { return RSHIFT; }
\+ { return ADD; }
\\?\- { return SUB; }
\* { return MUL; }
\/ { return DIV; }
\% { return MOD; }
\*\* { return POW; }
\( { return OPAREN; }
\) { return CPAREN; }
sqrt { return SQRT; }
abs { return ABS; }
log { return LOG; }
log10 { return LOG10; }
[ \t] ;
\n { return END; }
. { return UNDEFINED; }
%%

int yywrap(void) { return 1; }

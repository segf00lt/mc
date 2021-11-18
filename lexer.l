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
[0-9]+\.[0-9]* {
	if(flags.mode)
		return UNDEFINED;
	yylval.r = atof(yytext);
	return REAL;
}
[0-9]\.[0-9]+e\+[0-9][0-9] {
	if(flags.mode)
		return UNDEFINED;
	yylval.r = atof(yytext);
	return REAL;
}
[0-9]+ { 
	switch(flags.mode) {
		case SCIMODE:
			yylval.r = atof(yytext);
			return REAL;
		case BINMODE:
			yylval.n = strtoul(yytext, NULL, 10);
			return NATURAL;
	}
}
0[bB][01]+ {
	if(!flags.mode)
		return UNDEFINED;
	yylval.n = strtoul(yytext + 2, NULL, 2);
	return NATURAL;
}
0[oO][0-7]+ {
	if(!flags.mode)
		return UNDEFINED;
	yylval.n = strtoul(yytext + 2, NULL, 8);
	return NATURAL;
}
0[xX][0-9a-fA-F]+ {
	if(!flags.mode)
		return UNDEFINED;
	yylval.n = strtoul(yytext, NULL, 16);
	return NATURAL;
}
pi { yylval.r = M_PI; if(flags.mode) return UNDEFINED; return PI; }
e { yylval.r = M_E; if(flags.mode) return UNDEFINED; return E; }
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
\! { return FACT; }
\( { return OPAREN; }
\) { return CPAREN; }
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
log10 { return LOG10; }
[ \t] ;
\n { return END; }
. { return UNDEFINED; }
%%

int yywrap(void) { return 1; }

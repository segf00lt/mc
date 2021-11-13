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
		domain = 'r';
		if(flags.accumulate && (domain != defaultdomain)) {
			sprintf(errstr, "%s: accumulate invalid for multi domain input", progname);
			errhandle(errstr);
		}
		yylval.r = atof(yytext);
		return REAL;
}
[0-9]+u {
	domain = 'n';
	if(flags.accumulate && (domain != defaultdomain)) {
		sprintf(errstr, "%s: accumulate invalid for multi domain input", progname);
		errhandle(errstr);
	}
	yytext[yyleng - 1] = 0;
	yylval.n = atol(yytext);
	return NATURAL;
}
[0-9]+ { 
	switch(domain) {
		case 'r':
			yylval.r = atof(yytext);
			return REAL;
		case 'z':
			yylval.z = atol(yytext);
			return WHOLE;
		case 'n':
			yylval.n = atol(yytext);
			return NATURAL;
		default:
			domain = 'z';
			if(flags.accumulate && (domain != defaultdomain)) {
				sprintf(errstr, "%s: accumulate invalid for multi domain input", progname);
				errhandle(errstr);
			}
			yylval.z = atol(yytext);
			return WHOLE;
	}
}
[rzn]\: {
	domain = yytext[0];
	if(flags.accumulate && (domain != defaultdomain)) {
		sprintf(errstr, "%s: accumulate invalid for multi domain input", progname);
		errhandle(errstr);
	}
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
[a-z] {
	yylval.reg = yytext[0] - 'a';
	switch(domain) {
		case 'r':
			return R_VAR;
		case 'z':
			return Z_VAR;
		case 'n':
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
[ \t] ;
\n { return END; }
. { return UNDEFINED; }
%%

int yywrap(void) { return 1; }

#include <stdio.h>
#include <stdlib.h>
#include "lex.yy.c"
#include "y.tab.h"

char buf[256];
int bufpos = 0;
int expr[32];
int exprpos = 0;
char domain = 'r';
char defaultdomain = 'r';

int main(int argc, char* argv[]) {
	int i = 1;
	if(argc == 1)
		exit(1);

	if(argc == 2) {
		i = 2;
		expr[exprpos++] = 1;
	}

	for(; i < argc; ++i) {
		if(!strcmp(argv[i], "-e")) {
			expr[exprpos++] = (++i);
		} else if(!strcmp(argv[i], "-d")) {
			defaultdomain = domain = argv[++i][0];
		}
	}

	for(int j = 0; j < exprpos; ++j) {
		if(
			(strstr(argv[expr[j]], "r:")) != argv[expr[j]] &&
			(strstr(argv[expr[j]], "z:")) != argv[expr[j]] &&
			(strstr(argv[expr[j]], "n:")) != argv[expr[j]]
		  )
		{
			buf[bufpos++] = domain;
			buf[bufpos++] = ':';
		}
		for(char* c = argv[expr[j]]; *c != 0; ++c)
			buf[bufpos++] = *c;
		buf[bufpos++] = '\n';
		buf[bufpos++] = 0;
		yy_scan_string(buf);
		yyparse();
		yylex_destroy();
		domain = defaultdomain;
		bufpos = 0;
	}
	return 0;
}

#include <stdio.h>
#include <stdlib.h>
#include "lex.yy.c"
#include "y.tab.h"

char buf[256];
char domain = 'r';

int main(int argc, char* argv[]) {
	if(argc == 1)
		exit(1);
	int i = 0;
	switch(argv[1][0]) {
		case 'r':
		case 'z':
		case 'n':
			break;
		default:
			buf[i++] = domain;
			buf[i++] = ':';
			break;
	}
	for(char* c = argv[1]; *c != 0; ++c)
		buf[i++] = *c;
	buf[i++] = '\n';
	yy_scan_string(buf);
	yyparse();
	yylex_destroy();
	return 0;
}

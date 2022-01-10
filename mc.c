#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <math.h>
#include "lex.yy.h"
#include "y.tab.h"
#include "mc.h"

char* progname = NULL;
char format = 'd';

struct Flags flags;

char* expr[32];
int expr_len = 0;

char buf[256];
int buf_len = 0;

long outreg = 0;
long acc = 0;
unsigned int logicout = 0;

/* line number */
int lnum = 1;

char errstr[64];
void errhandle(char* errstr) {
	fprintf(stderr, "%s\n", errstr);
	exit(1);
}

void binf(char str[64], unsigned int n) {
	int index = n > 0 ? (int)log2(n) : 0;
	int j = 0;
	for(int i = index; i >= 0; --i) {
		unsigned int k = 1 << i;
		str[j++] = (n & k ? 1 : 0) + '0';
	}
	while(j < 64)
		str[j++] = 0;
}

void print(void) {
	char binstr[64];

	if(flags.linenumber & !flags.readarg)
		printf("%d: ", lnum);
	if(flags.print) {
		buf[buf_len - 2] = 0;
		printf("%s -> ", buf);
	}
	switch(format) {
		case 'd':
			printf("%li\n", outreg);
			return;
		case 'b':
			binf(binstr, outreg);
			printf("0b%s\n", binstr);
			return;
		case 'B':
			binf(binstr, outreg);
			printf("0B%s\n", binstr);
			return;
		case 'o':
			printf("0o%lo\n", (unsigned long)outreg);
			return;
		case 'O':
			printf("0O%lo\n", (unsigned long)outreg);
			return;
		case 'x':
			printf("0x%lx\n", (unsigned long)outreg);
			return;
		case 'X':
			printf("0X%lX\n", (unsigned long)outreg);
			return;
	}
}

void readstdin(void) {
	char line[256];

	while((fgets(line, 256, stdin)) != NULL) {
		int len = strlen(line);

		if(len >= 250) {
			sprintf(errstr, "%s: expression at line %d too long", progname, lnum);
			errhandle(errstr);
		}

		if(len == 1 && line[0] == '\n') {
			++lnum;
			continue;
		}

		for(char* c = line; *c != 0; ++c)
			buf[buf_len++] = *c;
		buf[buf_len++] = 0;

		yy_scan_string(buf);
		if(yyparse()) {
			yylex_destroy();
			exit(1);
		}
		yylex_destroy();

		if(!flags.last)
			print();

		buf_len = 0;

		/* increment line number */
		++lnum;
	}
}

void readstr(void) {
	for(int j = 0; j < expr_len; ++j) {
		int exprlen = strlen(expr[j]);

		if(exprlen >= 250) {
			sprintf(errstr, "%s: expression %d too long", progname, j + 1);
			errhandle(errstr);
		}

		for(char* c = expr[j]; *c != 0; ++c)
			buf[buf_len++] = *c;
		buf[buf_len++] = '\n';
		buf[buf_len++] = 0;

		yy_scan_string(buf);
		if(yyparse()) {
			yylex_destroy();
			exit(1);
		}
		yylex_destroy();

		if(!flags.last)
			print();

		buf_len = 0;
	}
}

int main(int argc, char* argv[]) {
	progname = argv[0];

	int c;
	while((c = getopt(argc, argv, "e:f:o:nbsphal")) != -1) {
		switch(c) {
			case 'h':
				fprintf(stderr, "%s\n", USAGE);
				exit(0);
			case 'e':
				if(expr_len == 31) {
					sprintf(errstr, "%s: too many expressions", progname);
					errhandle(errstr);
				}
				flags.readarg = 1;
				expr[expr_len++] = optarg;
				break;
			case 'o':
				if(flags.format) {
					sprintf(errstr, "%s: output format set multiple times", progname);
					errhandle(errstr);
				}
				flags.format = 1;
				switch(optarg[0]) {
					case 'd':
					case 'b':
					case 'B':
					case 'o':
					case 'O':
					case 'x':
					case 'X':
						format = optarg[0];
						break;
					default:
						sprintf(errstr, "%s: unrecognized output format", progname);
						errhandle(errstr);
				}
				break;
			case 'a':
				flags.accumulate = 1;
				break;
			case 'l':
				/* only affects output when used with accumulate */
				flags.last = 1;
				break;
			case 'p':
				flags.print = 1;
				break;
			case 'n':
				flags.linenumber = 1;
				break;
			case '?':
				exit(1);
		}
	}

	while(optind < argc) {
		expr[expr_len++] = argv[optind++];
		flags.readarg = 1;
	}

	switch(format) {
		case 'd':
		case 'b':
		case 'B':
		case 'o':
		case 'O':
		case 'x':
		case 'X':
			break;
		default:
			sprintf(errstr, "%s: unrecognized output format for binary mode", progname);
			errhandle(errstr);
	}

	switch(flags.readarg) {
		case 1:
			readstr();
			break;
		case 0:
			readstdin();
			break;
		default:
			sprintf(errstr, "%s: flags.readarg is not 0 or 1", progname);
			errhandle(errstr);
	}

	if(flags.accumulate) {
		if(flags.print)
			printf("total -> ");
		printf("%li\n", acc);
	}
	return !logicout;
}

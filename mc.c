#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "lex.yy.h"
#include "y.tab.h"
#include "helper.h"

#define USAGE "Usage: mc [-nph] [-d[rzn]] [-e EXPRESSION] EXPRESSION ..."

char* progname = NULL;
struct Flags {
	unsigned int printexpr : 1;
	unsigned int linenumber : 1;
	unsigned int domainset : 1;
};
struct Flags flags;

char* handle[32];
int handle_pos = 0;

FILE* file[32];
int file_pos = 0;

char* expr[32];
int expr_pos = 0;

char buf[256];
int buf_pos = 0;

char domain = 'r';
char defaultdomain = 'r';

void cleanup(void) {
	for(int i = 0; i < file_pos; ++i)
		fclose(file[i]);
}

char errstr[64];
void errhandle(void) {
	fprintf(stderr, "%s\n", errstr);
	cleanup();
	exit(1);
}

void fileinput(void) {
	char linebuf[256];
	char tmp[256];

	for(int i = 0; i < file_pos; ++i) {
		FILE* fp = file[i];
		int lnum = 1;

		while((fgets(linebuf, 256, fp)) != NULL) {
			int linelen = strlen(linebuf);
			if(linelen >= 250) {
				sprintf(errstr, "%s: expression %d too long", progname, lnum);
				errhandle();
			}
			if(linelen == 1 && linebuf[0] == '\n') {
				++lnum;
				continue;
			}
			if(
					(strstr(linebuf, "r:")) != linebuf &&
					(strstr(linebuf, "z:")) != linebuf &&
					(strstr(linebuf, "n:")) != linebuf
			  )
			{
				buf[buf_pos++] = defaultdomain;
				buf[buf_pos++] = ':';
			}
			for(char* c = linebuf; *c != 0; ++c)
				buf[buf_pos++] = *c;
			buf[buf_pos++] = 0;
			yy_scan_string(buf);

			if(file_pos > 1)
				printf("%s: ", handle[i]);
			if(flags.linenumber)
				printf("%d: ", lnum);
			if(flags.printexpr) {
				strncpy(tmp, linebuf, linelen - 1);
				tmp[linelen - 1] = 0;
				printf("%s = ", tmp);
			}

			yyparse();
			yylex_destroy();
			domain = defaultdomain;
			buf_pos = 0;
			++lnum;
		}
	}
}

void strinput(void) {
	char tmp[256];

	for(int j = 0; j < expr_pos; ++j) {
		int exprlen = strlen(expr[j]);

		if(exprlen >= 250) {
			sprintf(errstr, "%s: expression %d too long", progname, j + 1);
			errhandle();
		}

		if(
				(strstr(expr[j], "r:")) != expr[j] &&
				(strstr(expr[j], "z:")) != expr[j] &&
				(strstr(expr[j], "n:")) != expr[j]
		)
		{
			buf[buf_pos++] = defaultdomain;
			buf[buf_pos++] = ':';
		}

		for(char* c = expr[j]; *c != 0; ++c)
			buf[buf_pos++] = *c;
		buf[buf_pos++] = '\n';
		buf[buf_pos++] = 0;
		yy_scan_string(buf);
		if(flags.printexpr) {
			strcpy(tmp, expr[j]);
			tmp[exprlen] = 0;
			printf("%s = ", tmp);
		}
		yyparse();
		yylex_destroy();
		domain = defaultdomain;
		buf_pos = 0;
	}
}

int main(int argc, char* argv[]) {
	progname = argv[0];

	int c;
	while((c = getopt(argc, argv, "e:d:f:nph")) != -1) {
		switch(c) {
			case 'h':
				fprintf(stderr, "%s\n", USAGE);
				cleanup();
				exit(0);
			case 'e':
				if(expr_pos == 31) {
					sprintf(errstr, "%s: too many expressions", progname);
					errhandle();
				}
				expr[expr_pos++] = optarg;
				break;
			case 'd':
				if(!flags.domainset) {
					defaultdomain = domain = optarg[0];
					flags.domainset = 1;
				}
				else {
					sprintf(errstr, "%s: domain already set", progname);
					errhandle();
				}
				break;
			case 'f':
				if(file_pos == 31) {
					sprintf(errstr, "%s: too many files", progname);
					errhandle();
				}
				if(isdir(optarg)) {
					sprintf(errstr, "%s: %s is a directory", progname, optarg);
					errhandle();
				}
				handle[handle_pos++] = optarg;
				file[file_pos++] = fopen(optarg, "r");
				break;
			case 'p':
				flags.printexpr = 1;
				break;
			case 'n':
				flags.linenumber = 1;
				break;
			case '?':
				cleanup();
				exit(1);
		}
	}

	while(optind < argc)
		expr[expr_pos++] = argv[optind++];

	int i = file_pos + expr_pos;
	if(i != file_pos && i != expr_pos) {
		sprintf(errstr, "%s: only one input source allowed at a time", progname);
		errhandle();
	}

	if(i == 0) {
		file[file_pos++] = stdin;
		fileinput();
		cleanup();
		return 0;
	}

	if(i == expr_pos) {
		strinput();
		cleanup();
		return 0;
	} else if(file_pos) {
		fileinput();
		cleanup();
		return 0;
	}

	cleanup();
	return 1;
}

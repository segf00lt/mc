#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "lex.yy.h"
#include "y.tab.h"
#include "mc.h"

#define USAGE "Usage: mc [-nph] [-d[rzn]] [-e EXPRESSION] EXPRESSION ..."

char* progname = NULL;

struct Flags flags;

char* handle[32];
int handle_len = 0;

FILE* file[32];
int file_len = 0;

char* expr[32];
int expr_len = 0;

char buf[256];
int buf_len = 0;

char domain = 'r';
char defaultdomain = 'r';

union Num outreg;

int isdir(char* handle) {
	struct stat s;
	memset(&s, 0, sizeof(struct stat));
	stat(handle, &s);
	return S_ISDIR(s.st_mode);
}

/* number of decimals in double, 6 is max */
unsigned int ndecimals(double d) {
	unsigned int n = 0;
	int i = d;
	while((d - (double)i) != 0) {
		if(n == 6)
			break;
		d *= 10;
		i = d;
		++n;
	}
	return n;
}

void cleanup(void) {
	for(int i = 0; i < file_len; ++i)
		fclose(file[i]);
}

char errstr[64];
void errhandle(char* errstr) {
	fprintf(stderr, "%s\n", errstr);
	cleanup();
	exit(1);
}

void fileinput(void) {
	char linebuf[256];
	char tmp[256];

	for(int i = 0; i < file_len; ++i) {
		FILE* fp = file[i];
		int lnum = 1;

		while((fgets(linebuf, 256, fp)) != NULL) {
			int linelen = strlen(linebuf);
			if(linelen >= 250) {
				sprintf(errstr, "%s: expression %d too long", progname, lnum);
				errhandle(errstr);
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
				buf[buf_len++] = defaultdomain;
				buf[buf_len++] = ':';
			}
			for(char* c = linebuf; *c != 0; ++c)
				buf[buf_len++] = *c;
			buf[buf_len++] = 0;
			yy_scan_string(buf);

			if(flags.readfile)
				printf("%s: ", handle[i]);
			if(flags.linenumber)
				printf("%d: ", lnum);
			if(flags.printexpr & !flags.accumulate) {
				strncpy(tmp, linebuf, linelen - 1);
				tmp[linelen - 1] = 0;
				printf("%s = ", tmp);
			}

			yyparse();
			yylex_destroy();
			domain = defaultdomain;
			buf_len = 0;
			++lnum;
		}

		if(flags.last) {
			switch(domain) {
				case 'r':
					printf("%.*f\n", ndecimals(outreg.r), outreg.r);
					return;
				case 'z':
					printf("%ld\n", outreg.z);
					return;
				case 'n':
					printf("%lu\n", outreg.n);
					return;
			}
		}
	}
}

void strinput(void) {
	char tmp[256];

	for(int j = 0; j < expr_len; ++j) {
		int exprlen = strlen(expr[j]);

		if(exprlen >= 250) {
			sprintf(errstr, "%s: expression %d too long", progname, j + 1);
			errhandle(errstr);
		}

		if(
				(strstr(expr[j], "r:")) != expr[j] &&
				(strstr(expr[j], "z:")) != expr[j] &&
				(strstr(expr[j], "n:")) != expr[j]
		)
		{
			buf[buf_len++] = defaultdomain;
			buf[buf_len++] = ':';
		}

		for(char* c = expr[j]; *c != 0; ++c)
			buf[buf_len++] = *c;
		buf[buf_len++] = '\n';
		buf[buf_len++] = 0;
		yy_scan_string(buf);
		if(flags.printexpr & !flags.accumulate) {
			strcpy(tmp, expr[j]);
			tmp[exprlen] = 0;
			printf("%s = ", tmp);
		}
		yyparse();
		yylex_destroy();
		domain = defaultdomain;
		buf_len = 0;
	}

	if(flags.last) {
		switch(domain) {
			case 'r':
				printf("%.*f\n", ndecimals(outreg.r), outreg.r);
				return;
			case 'z':
				printf("%ld\n", outreg.z);
				return;
			case 'n':
				printf("%lu\n", outreg.n);
				return;
		}
	}
}

int main(int argc, char* argv[]) {
	progname = argv[0];
	memset(&outreg, 0, sizeof(union Num));

	int c;
	while((c = getopt(argc, argv, "e:d:f:nphal")) != -1) {
		switch(c) {
			case 'h':
				fprintf(stderr, "%s\n", USAGE);
				cleanup();
				exit(0);
			case 'e':
				if(expr_len == 31) {
					sprintf(errstr, "%s: too many expressions", progname);
					errhandle(errstr);
				}
				flags.readarg = 1;
				expr[expr_len++] = optarg;
				break;
			case 'd':
				if(!flags.domainset) {
					defaultdomain = domain = optarg[0];
					flags.domainset = 1;
				}
				else {
					sprintf(errstr, "%s: domain already set", progname);
					errhandle(errstr);
				}
				break;
			case 'f':
				if(file_len == 31) {
					sprintf(errstr, "%s: too many files", progname);
					errhandle(errstr);
				}
				if(isdir(optarg)) {
					sprintf(errstr, "%s: %s is a directory", progname, optarg);
					errhandle(errstr);
				}
				flags.readfile = 1;
				handle[handle_len++] = optarg;
				file[file_len++] = fopen(optarg, "r");
				break;
			case 'a':
				flags.last = 1;
				flags.accumulate = 1;
				break;
			case 'l':
				flags.last = 1;
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

	while(optind < argc) {
		expr[expr_len++] = argv[optind++];
		flags.readarg = 1;
	}

	if(flags.readarg & flags.readfile) {
		sprintf(errstr, "%s: only one input source allowed at a time", progname);
		errhandle(errstr);
	}

	if(!(flags.readarg | flags.readfile)) {
		file[file_len++] = stdin;
		fileinput();
		cleanup();
		return 0;
	}

	if(flags.readarg) {
		strinput();
		cleanup();
		return 0;
	} else if(flags.readfile) {
		fileinput();
		cleanup();
		return 0;
	}

	cleanup();
	return 1;
}

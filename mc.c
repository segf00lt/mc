#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "lex.yy.h"
#include "y.tab.h"
#include "mc.h"

char* progname = NULL;

struct Flags flags;

char* handle[32];
int handle_len = 0;
char* curhandle = NULL;

FILE* file[32];
int file_len = 0;

char* expr[32];
int expr_len = 0;

char buf[256];
int buf_len = 0;

union Num outreg;
union Num acc;

/* line number */
int lnum = 1;

int isreg(char* handle) {
	struct stat s;
	memset(&s, 0, sizeof(struct stat));
	stat(handle, &s);
	return S_ISREG(s.st_mode);
}

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
		if(n == 12)
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

void print(void) {
	if(file_len > 1)
		printf("%s: ", curhandle);
	if(flags.linenumber & flags.readfile)
		printf("%d: ", lnum);
	if(flags.print) {
		buf[buf_len - 2] = 0;
		printf("%s%s", buf, flags.assigned ? "\n" : " -> ");
	}
	if(!flags.assigned) {
		switch(flags.mode) {
			case SCIMODE:
				printf("%.*f\n", ndecimals(outreg.r), outreg.r);
				break;
			case BINMODE:
				printf("%lu\n", outreg.n);
				break;
		}
	}
}

void readfile(void) {
	char line[256];
	FILE* fp = NULL;

	for(int i = 0; i < file_len; ++i) {
		fp = file[i];
		curhandle = handle[i];
		lnum = 1;

		while((fgets(line, 256, fp)) != NULL) {
			int len = strlen(line);

			if(len >= 250) {
				sprintf(errstr, "%s: expression %d too long", progname, lnum);
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
				cleanup();
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
			cleanup();
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
	memset(&outreg, 0, sizeof(union Num));

	int c;
	while((c = getopt(argc, argv, "e:f:nbsphal")) != -1) {
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
			case 'f':
				if(file_len == 31) {
					sprintf(errstr, "%s: too many files", progname);
					errhandle(errstr);
				}
				if(isdir(optarg)) {
					sprintf(errstr, "%s: %s is a directory", progname, optarg);
					errhandle(errstr);
				}
				if(!isreg(optarg)) {
					sprintf(errstr, "%s: no such file: %s", progname, optarg);
					errhandle(errstr);
				}
				flags.readfile = 1;
				handle[handle_len++] = optarg;
				file[file_len++] = fopen(optarg, "r");
				break;
			case 's':
				if(flags.setmode) {
					sprintf(errstr, "%s: mode flag set multiple times", progname);
					errhandle(errstr);
				}
				flags.mode = SCIMODE;
				flags.setmode = 1;
				break;
			case 'b':
				if(flags.setmode) {
					sprintf(errstr, "%s: mode flag set multiple times", progname);
					errhandle(errstr);
				}
				flags.mode = BINMODE;
				flags.setmode = 1;
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
		readfile();
		goto end;
	}

	if(flags.readarg) {
		readstr();
		goto end;
	} else if(flags.readfile) {
		readfile();
		goto end;
	}

end:
	if(flags.accumulate & !flags.assigned) {
		if(flags.print)
			printf("total -> ");
		switch(flags.mode) {
			case SCIMODE:
				printf("%.*f\n", ndecimals(acc.r), acc.r);
				break;
			case BINMODE:
				printf("%lu\n", acc.n);
				break;
		}
	}
	cleanup();
	return 0;
}

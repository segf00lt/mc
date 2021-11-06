#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "lex.yy.c"
#include "y.tab.h"
#include "helper.h"

#define USAGE "Usage: mc [-d r|z|n] [-e EXPRESSION]"

char* progname = NULL;

FILE* file[32];
int filepos = 0;

char* expr[32];
int exprpos = 0;

char buf[256];
int bufpos = 0;

char domain = 'r';
char defaultdomain = 'r';

void cleanup(void) {
	for(int i = 0; i < filepos; ++i)
		fclose(file[i]);
}

char errstr[64];
void errhandle(void) {
	fprintf(stderr, "%s\n", errstr);
	cleanup();
	exit(1);
}

void fileinput(void) {
	for(int i = 0; i < filepos; ++i) {
		FILE* fp = file[i];
		int lnum = 1;
		char linebuf[256];
		while((fgets(linebuf, 256, fp)) != NULL) {
			int linelen = strlen(linebuf);
			if(linelen >= 250) {
				sprintf(errstr, "%s: expression %d too long", progname, lnum);
				errhandle();
			}
			if(
					(strstr(linebuf, "r:")) != linebuf &&
					(strstr(linebuf, "z:")) != linebuf &&
					(strstr(linebuf, "n:")) != linebuf
			  )
			{
				buf[bufpos++] = defaultdomain;
				buf[bufpos++] = ':';
			}
			for(char* c = linebuf; *c != 0; ++c)
				buf[bufpos++] = *c;
			buf[bufpos++] = 0;
			yy_scan_string(buf);
			yyparse();
			yylex_destroy();
			domain = defaultdomain;
			bufpos = 0;
			++lnum;
		}
	}
}

void strinput(void) {
	for(int j = 0; j < exprpos; ++j) {
		if(strlen(expr[j]) >= 250) {
			sprintf(errstr, "%s: expression %d too long", progname, j + 1);
			errhandle();
		}
		if(
				(strstr(expr[j], "r:")) != expr[j] &&
				(strstr(expr[j], "z:")) != expr[j] &&
				(strstr(expr[j], "n:")) != expr[j]
		)
		{
			buf[bufpos++] = defaultdomain;
			buf[bufpos++] = ':';
		}
		for(char* c = expr[j]; *c != 0; ++c)
			buf[bufpos++] = *c;
		buf[bufpos++] = '\n';
		buf[bufpos++] = 0;
		yy_scan_string(buf);
		yyparse();
		yylex_destroy();
		domain = defaultdomain;
		bufpos = 0;
	}
}

int main(int argc, char* argv[]) {
	if(argc == 1) {
		fprintf(stderr, "%s\n", USAGE);
		exit(1);
	}

	progname = argv[0];

	int c;
	int domainset = 0;
	while((c = getopt(argc, argv, "e:d:f:")) != -1) {
		switch(c) {
			case 'e':
				if(exprpos == 31) {
					sprintf(errstr, "%s: too many expressions", progname);
					errhandle();
				}
				expr[exprpos++] = optarg;
				break;
			case 'd':
				if(!domainset) {
					defaultdomain = domain = optarg[0];
					domainset = 1;
				}
				else {
					sprintf(errstr, "%s: domain already set", progname);
					errhandle();
				}
				break;
			case 'f':
				if(filepos == 31) {
					sprintf(errstr, "%s: too many files", progname);
					errhandle();
				}
				if(isdir(optarg)) {
					sprintf(errstr, "%s: %s is a directory", progname, optarg);
					errhandle();
				}
				file[filepos++] = fopen(optarg, "r");
				break;
			case '?':
				cleanup();
				exit(1);
		}
	}

	if(optind == 1)
		expr[exprpos++] = argv[optind++];

	int i = filepos + exprpos;
	if(i != filepos && i != exprpos) {
		sprintf(errstr, "%s: only one input source allowed at a time", progname);
		errhandle();
	}

	if(i == exprpos)
		strinput();
	else if(filepos)
		fileinput();

	cleanup();
	return 0;
}

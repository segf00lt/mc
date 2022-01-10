#ifndef MC_H
#define MC_H

#define USAGE "Usage: mc [-nalph] [-o [dbBoOxX]] [-e EXPRESSION] EXPRESSION ..."

struct Flags {
	unsigned int readarg : 1;
	unsigned int print : 1;
	unsigned int linenumber : 1;
	unsigned int accumulate : 1;
	unsigned int last : 1;
	unsigned int format : 1;
};

void errhandle(char* errstr);
void print(void);
void readstdin(void);
void readstr(void);

#endif

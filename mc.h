#ifndef MC_H
#define MC_H

#define USAGE "Usage: mc [-nalpbh] [-e EXPRESSION] [-f FILE] EXPRESSION ..."
#define BINMODE 1
#define SCIMODE 0

struct Flags {
	unsigned int readfile : 1;
	unsigned int readarg : 1;
	unsigned int print : 1;
	unsigned int linenumber : 1;
	unsigned int accumulate : 1;
	unsigned int last : 1;
	unsigned int mode : 1;
	unsigned int setmode : 1;
};

union Num {
	double r;
	unsigned long n;
};

int isreg(char* handle);
int isdir(char* handle);
unsigned int ndecimals(double d);
void cleanup(void);
void errhandle(char* errstr);
void print(void);
void readfile(void);
void readstr(void);

#endif

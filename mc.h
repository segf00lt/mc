#ifndef MC_H
#define MC_H

struct Flags {
	unsigned int readfile : 1;
	unsigned int readarg : 1;
	unsigned int print : 1;
	unsigned int linenumber : 1;
	unsigned int domainset : 1;
	unsigned int accumulate : 1;
	unsigned int last : 1;
	unsigned int assigned : 1;
};

union Num {
	double r;
	long z;
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

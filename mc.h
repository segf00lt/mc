#ifndef MC_H
#define MC_H

struct Flags {
	unsigned int readfile : 1;
	unsigned int readarg : 1;
	unsigned int printexpr : 1;
	unsigned int linenumber : 1;
	unsigned int domainset : 1;
	unsigned int accumulate : 1;
	unsigned int last : 1;
};

union Num {
	double r;
	long z;
	unsigned long n;
};

int isdir(char* handle);
unsigned int ndecimals(double d);
void cleanup(void);
void errhandle(char* errstr);
void print(void);
void fileinput(void);
void strinput(void);

#endif

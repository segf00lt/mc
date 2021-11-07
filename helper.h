
#ifndef HELPER_H
#define HELPER_H

struct Flags {
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
unsigned long factorial(unsigned long n);

#endif

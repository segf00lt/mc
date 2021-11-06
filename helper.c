/* helper functions */
#include <math.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <string.h>

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

unsigned long factorial(unsigned long n) {
	unsigned long result = n;
	for(unsigned long k = 1; k < n; ++k)
		result *= k;
	return result;
}

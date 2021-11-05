/* helper functions */
#include <math.h>

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

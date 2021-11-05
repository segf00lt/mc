/* helper functions */

unsigned long factorial(unsigned long n) {
	unsigned long result = n;
	for(unsigned long k = 1; k < n; ++k)
		result *= k;
	return result;
}

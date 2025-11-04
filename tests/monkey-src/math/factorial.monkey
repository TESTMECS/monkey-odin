#!/usr/bin/env monkey -- 

puts("Iterative 5!")
let factorial = fn(n) {
	n = n + 1;
	let ans = 1;
	let i = 2; 
	for ( i < n ) {
		ans = ans * i;
		i = i + 1;
	};
	return ans;
};
puts(factorial(5));

puts("Recursive 5!")
let factorial = fn(n) {
	if ( n == 0 ) {
		return 1;
	}
	return n * factorial(n - 1);
}
puts(factorial(5));




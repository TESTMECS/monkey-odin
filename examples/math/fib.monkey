#!/usr/bin/env monkey-odin --

puts("Recursive fib(5)")
let fibonacci = fn(x) {
  if (x == 0) {
    0
  } else {
    if (x == 1) {
      return 1;
    } else {
      fibonacci(x - 1) + fibonacci(x - 2);
    }
  }
};
puts(fibonacci(5));

puts("Iterative fib(5)")
let fibonacci = fn(n) {
    if (n < 2) { 
			n 
		}
    let prev = 0;
    let curr = 1;
    let i = 2;

    for ( !(i > n) ) { # same as i <= n
        let next = prev + curr;
        prev = curr;
        curr = next;
        i = i + 1;
    }
    return curr;
};
puts(fibonacci(5));


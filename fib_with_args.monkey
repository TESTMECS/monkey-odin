#!/usr/bin/env monkey-odin -- 10

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

// Get the first argument (default to 10 if not provided)
let n = len(args()) > 0 ? int(args()[0]) : 10;
puts("Fibonacci(" + str(n) + ") = " + str(fibonacci(n)));
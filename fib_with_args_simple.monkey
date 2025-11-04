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

let args_list = args();
let n = 10;
if (len(args_list) > 0) {
  n = int(args_list[0]);
}
puts("Fibonacci(" + str(n) + ") = " + str(fibonacci(n)));
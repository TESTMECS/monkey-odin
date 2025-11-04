#!/usr/bin/env monkey-odin -- 5

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
puts("Args: " + str(args_list));
let n = 5;
if (len(args_list) > 0) {
  n = int(args_list[0]);
}
puts("Computing fibonacci(" + str(n) + ")");
let result = fibonacci(n);
puts("Result: " + str(result));
#!/usr/bin/env monkey -- 

# Simple ternary test
false ? 1 : 0;

# With variables
let x = 5;
x > 3 ? "big" : "small";

# Nested ternary
true ? false ? 1 : 2 : 3;

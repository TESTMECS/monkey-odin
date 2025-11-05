#!/usr/bin/env monkey -- "hello"

# Macro expansion is now working correctly!
# These tests demonstrate that unquote() properly expands macro parameters

let show_value = macro(x) {
	quote(puts(unquote(x)))
};

let check_positive = macro(x) {
	quote(if (unquote(x) > 0) { puts("positive") } else { puts("zero or negative") })
};

let count_down = macro(x) {
	quote(let i = unquote(x) while (i > 0) { puts(i) i = i - 1 })
};

# Test cases
show_value(42);                    # prints: 42
check_positive(5);                   # prints: positive  
check_positive(0);                   # prints: zero or negative
count_down(3);                      # prints: 3, 2, 1


#!/usr/bin/env monkey -- 42 5 0
let show_value = macro(x) {
	quote(puts(unquote(x)))
};

let check_positive = macro(x) {
	quote(if (unquote(x) > 0) { puts("positive") } else { puts("zero or negative") })
};
# Test cases, remember literals go in so args()[0] will not work.
show_value(42);                    # prints: 42
check_positive(5);                   # prints: positive  
check_positive(0);                   # prints: zero or negative


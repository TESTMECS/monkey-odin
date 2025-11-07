#!/usr/bin/env monkey -- 1,2,3

let my_macro = macro(x) {
	quote(print("macro called with: ", unquote(x)))
}
my_macro(1)

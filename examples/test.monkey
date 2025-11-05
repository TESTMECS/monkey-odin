#!/usr/bin/env monkey -- "hello"

let my_macro = macro() {
	quote(unquote(1+1) + unquote(2+2))
}

my_macro();


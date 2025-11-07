#!/usr/bin/env monkey -- 1,2,3

let forexpr = macro(x) {
	quote( puts(unquote(x) ) )
}

forexpr([1,2,3]);



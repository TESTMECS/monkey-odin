#!/usr/bin/env monkey -- 1,2,3

let ifexpr = macro(c) {
	quote(if ( unquote(c) ) { puts("then") } else { puts("else") })
};
ifexpr(1 == 2);

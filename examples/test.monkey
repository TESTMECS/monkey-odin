#!/usr/bin/env monkey -- 1,2,3

let equal = macro(a, b) { quote(unquote(b) == unquote(a)); };
equal(!1, !1);

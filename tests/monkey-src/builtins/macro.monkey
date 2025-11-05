#!usr/bin/env monkey-odin
let infixExpression = macro() { quote(unquote(quote(5+1))) }; # allows up to two levels of nesting
infixExpression();

let ifexpr = macro() {
	quote(if true { puts("is true")})
}

ifexpr();

let forexpr = macro() {
	quote(for ( i > 0 ) { puts(i); i = i - 1; })
}

let i = 10;
forexpr();


# quote(unquote(5))
# quote(unquote(5+8))

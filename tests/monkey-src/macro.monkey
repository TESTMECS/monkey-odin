#!usr/bin/env monkey-odin
let infixExpression = macro() { quote(1 + 2); };
infixExpression();

quote(unquote(5))
quote(unquote(5+8))

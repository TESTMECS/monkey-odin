;; queries/highlights.scm

;; 1. Highlight the 'let' keyword
(let_statement "let" @keyword)

;; 2. Highlight the assignment operator
(let_statement "=" @operator)

;; 3. Highlight the name being defined (fibonacci) as a variable definition
(let_statement
  name: (identifier) @variable.declaration)

;; 4. Highlight the 'fn' keyword
(function_definition "fn" @keyword)

;; 5. Highlight the function's parameters
(parameter_list
  (identifier) @variable.parameter)

;; 6. Highlight punctuation (parens and braces)
["(" ")" "{" "}" ";" "," ] @punctuation.bracket

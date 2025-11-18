;; ----------------------------------------------------------------------------
;; Keywords
;; ----------------------------------------------------------------------------

(let_statement "let" @keyword)
(function_definition "fn" @keyword)
(return_statement "return" @keyword)
(if_expression "if" @keyword)
(if_expression "else" @keyword)
(for_statement "for" @keyword)
(foreach_statement "foreach" @keyword)
(foreach_statement "in" @keyword)

;; ----------------------------------------------------------------------------
;; Literals
;; ----------------------------------------------------------------------------

(boolean) @boolean
(integer) @number
(float) @number.float
(string) @string
(comment) @comment

;; ----------------------------------------------------------------------------
;; Functions
;; ----------------------------------------------------------------------------

;; Highlight the function name in a call: myFunc()
(call_expression
  function: (identifier) @function.call)

;; Highlight the arrow operator specifically
(arrow_expression "->" @operator)

;; ----------------------------------------------------------------------------
;; Variables and Identifiers
;; ----------------------------------------------------------------------------

;; Definition of a variable in 'let'
(let_statement
  name: (identifier) @variable)

;; Loop variable in 'foreach'
(foreach_statement
  variable: (identifier) @variable)

;; Parameters in function definitions
(parameter_list
  (identifier) @variable.parameter)

;; Hash keys (map them to properties for distinct coloring)
(hash_pair
  key: (string) @property)

;; General fallback for all other identifiers
(identifier) @variable

;; ----------------------------------------------------------------------------
;; Punctuation & Operators
;; ----------------------------------------------------------------------------

;; Operators
[
  "="
  "+" "-" "*" "/" "%"
  "==" "!=" "<" ">"
  "&&" "||" "!"
  "&" "|" "^" "~" "<<" ">>"
] @operator

;; Delimiters
[
  "(" ")"
  "[" "]"
  "{" "}"
] @punctuation.bracket

[
  ";"
  ","
  ":"
] @punctuation.delimiter

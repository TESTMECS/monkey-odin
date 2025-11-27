" Vim syntax file
" Language: Monkey 
" Maintainer: TESTMEE 
" Version: 1.0

if exists("b:current_syntax")
  finish
endif

" ---------------------------------------------------------
" Comments
" ---------------------------------------------------------
syntax match monkeyComment "#.*$"

highlight link monkeyComment Comment

" ---------------------------------------------------------
" Strings
" ---------------------------------------------------------
syntax region monkeyString start=+"+ skip=+\\."+ end=+"+
highlight link monkeyString String

" ---------------------------------------------------------
" Numbers
" ---------------------------------------------------------
syntax match monkeyNumber "\v<\d+(\.\d+)?([eE][+-]?\d+)?"
highlight link monkeyNumber Number

" ---------------------------------------------------------
" Booleans & Nulls
" ---------------------------------------------------------
syntax keyword monkeyBoolean true false
highlight link monkeyBoolean Boolean

" ---------------------------------------------------------
" Keywords
" ---------------------------------------------------------
syntax keyword monkeyKeyword
      \ let fn class return if else for foreach in macro quote unquote
      \ break continue
highlight link monkeyKeyword Keyword

" ---------------------------------------------------------
" Builtins and stdlib functions
" ---------------------------------------------------------
syntax keyword monkeyBuiltin
      \ args printf puts readf writef len split upper lower int float bool
      \ sum min max hash rand sin cos tan
      \ indexOf slice map keys values has reverse contains replace match
      \ quote unquote
highlight link monkeyBuiltin Function

" ---------------------------------------------------------
" Operators and Symbols
" ---------------------------------------------------------
syntax match monkeyOperator "==\|!=\|<=\|>=\|<\|>\|=\|@\|+\|-\|*\|/\|%"
highlight link monkeyOperator Operator

" ---------------------------------------------------------
" Braces, brackets, parens
" ---------------------------------------------------------
syntax match monkeyBraces "[{}()\[\]]"
highlight link monkeyBraces Delimiter

" ---------------------------------------------------------
" Class and function names
" ---------------------------------------------------------
syntax match monkeyClassName "\v<class\s+\zs[A-Za-z_]\w*"
syntax match monkeyFunctionName "\v<fn\s+\zs[A-Za-z_]\w*"
highlight link monkeyClassName Type
highlight link monkeyFunctionName Function

" ---------------------------------------------------------
" Constants / identifiers
" ---------------------------------------------------------
syntax match monkeyIdentifier "\<[A-Za-z_][A-Za-z0-9_]*\>"
highlight link monkeyIdentifier Identifier

" ---------------------------------------------------------
" Special
" ---------------------------------------------------------
syntax match monkeyAnnotation "#!.*$"
highlight link monkeyAnnotation PreProc

" ---------------------------------------------------------
" Define the syntax
" ---------------------------------------------------------
let b:current_syntax = "monkey"

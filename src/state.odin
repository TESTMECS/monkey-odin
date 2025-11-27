package monkey
import "core:mem"
import "core:strings"
/*
* Copyright (C) 2025 TESTMEE
* ./state.odin
* One-stop-shop for all State
* Sections: << Lexer >> << Parser >> << Evaluator >> << Compiler >> << VM >>
*/
Lexer_VTable :: struct {
	next_token: proc(l: ^Lexer) -> Token,
	read_char:  proc(l: ^Lexer),
}
Lexer :: struct {
	input:        []u8, // input string
	pos:          int, // current position in input
	read_pos:     int, // l.pos + 1
	ch:           u8, // current character
	using vtable: Lexer_VTable,
}
Lexer_New :: proc(input: string) -> Lexer {
	l := Lexer {
		ch         = 0,
		input      = transmute([]u8)input,
		pos        = 0,
		read_pos   = 0,
		next_token = next_token,
		vtable     = LEXERVTABLE,
	}
	read_char(&l)
	return l
}
Precedence :: enum {
	Lowest       = 0,
	Assign       = 1,
	Equals       = 2,
	Less_Greater = 3,
	Sum          = 4,
	Product      = 5,
	Prefix       = 6,
	Call         = 7,
	Index        = 8,
}
GetPrecedence: [Token_Type]Precedence
init_precedences :: proc() {
	GetPrecedence = #partial {
		.Plus               = .Sum,
		.Minus              = .Sum,
		.Pipe               = .Sum,
		.Caret              = .Sum,
		.Ampersand          = .Sum,
		.Lor                = .Sum,
		.Land               = .Sum,
		.Asterisk           = .Product,
		.Slash              = .Product,
		.Percent            = .Product,
		.RShift             = .Product,
		.LShift             = .Product,
		.Less_Than          = .Less_Greater,
		.Greater_Than       = .Less_Greater,
		.Greater_Than_Equal = .Less_Greater,
		.Less_Than_Equal    = .Less_Greater,
		.Equal              = .Equals,
		.Not_Equal          = .Equals,
		.Question_Mark      = .Equals,
		.Assign             = .Assign,
		.Left_Paren         = .Call,
		.Arrow              = .Call,
		.Macro              = .Lowest,
		.Left_Bracket       = .Index,
	}
}

Parser_VTable :: struct {
	parse:       proc(p: ^Parser) -> Ast_Program,
	advance:     proc(p: ^Parser),
	parse_error: proc(p: ^Parser, str: string, args: ..any),
}
Parser :: struct {
	l:            Lexer,
	cur_token:    Token,
	peek_token:   Token,
	varena:       mem.Allocator,
	errors:       [dynamic]string,
	sb:           strings.Builder,
	using vtable: Parser_VTable,
}
Parser_New :: proc(input: string, varena: mem.Allocator) -> Parser {
	init_precedences()
	return Parser {
		varena = varena,
		errors = make([dynamic]string, 0, varena),
		l = Lexer_New(input),
		vtable = PARSERVTABLE,
	}
}


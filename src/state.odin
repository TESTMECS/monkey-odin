package monkey
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


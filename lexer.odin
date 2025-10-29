/*
%exports{
-- Lexer::struct
{[]u8 :: int :: int :: u8 :: proc(l:^Lexer, input:string) -> nil :: proc(l:^Lexer) -> Token}
-- LexerNew::proc
{proc()->Lexer}
}
%desc{
{"Implements the Lexer for Monkey."}
}
*/
package monkey

import "core:log"
import "core:testing"

Lexer :: struct {
	input:      []u8,
	pos:        int,
	read_pos:   int,
	ch:         u8,
	init:       proc(l: ^Lexer, input: string),
	next_token: proc(l: ^Lexer) -> Token,
}

// Lexer returns a new lexer
LexerNew :: proc() -> Lexer {
	return {next_token = next_token, init = init}
}

@(private = "file")
is_letter :: proc(ch: u8) -> bool {
	return 'a' <= ch && ch <= 'z' || 'A' <= ch && ch <= 'Z' || ch == '_'
}

@(private = "file")
is_digit :: proc(ch: u8) -> bool {
	return '0' <= ch && ch <= '9'
}

@(private = "file")
token_from_current_char :: proc(l: ^Lexer, type: Token_Type) -> Token {
	return GetToken(type, l.input, l.pos, 1)
}

// init sets the lexer struct and begins to `read_char`
@(private = "file")
init :: proc(l: ^Lexer, input: string) {
	l.ch = 0
	l.input = transmute([]u8)input
	l.pos = 0
	l.read_pos = 0

	read_char(l)
}

@(private = "file")
skip_whitespace :: proc(l: ^Lexer) {
	for l.ch == ' ' || l.ch == '\t' || l.ch == '\n' || l.ch == '\r' do read_char(l)
}

@(private = "file")
create_identifier :: proc(l: ^Lexer) -> Token {
	start := l.pos

	for is_letter(l.ch) do read_char(l)

	return GetToken(.Identifier, l.input, start, l.pos - start)
}

@(private = "file")
create_number :: proc(l: ^Lexer) -> Token {
	start := l.pos

	for is_digit(l.ch) do read_char(l)

	return GetToken(.Int, l.input, start, l.pos - start)
}

@(private = "file")
create_string :: proc(l: ^Lexer) -> Token {
	start := l.pos + 1

	for {
		read_char(l)
		if l.ch == '"' || l.ch == 0 do break
	}

	return GetToken(.String, l.input, start, l.pos - start)
}

// read_char increases `read_pos` by 1 and sets `ch, pos`
@(private = "file")
read_char :: proc(l: ^Lexer) {
	if l.read_pos >= len(l.input) {
		l.ch = 0
	} else {
		l.ch = l.input[l.read_pos]
	}
	l.pos = l.read_pos
	l.read_pos += 1
}

// `peek_char` returns 0 if `read_pos` is outside of input
@(private = "file")
peek_char :: proc(l: ^Lexer) -> u8 {
	return l.read_pos >= len(l.input) ? 0 : l.input[l.read_pos]
}

// next_token reads in the next token and then calls `read_char`
@(private = "file")
next_token :: proc(l: ^Lexer) -> Token {
	tok: Token

	skip_whitespace(l)

	switch l.ch {
	case '=':
		if peek_char(l) == '=' {
			start := l.pos
			read_char(l)
			tok = GetToken(.Equal, l.input, start, 2)
		} else do tok = token_from_current_char(l, .Assign)
	case '+':
		tok = token_from_current_char(l, .Plus)
	case '-':
		tok = token_from_current_char(l, .Minus)
	case '!':
		if peek_char(l) == '=' {
			start := l.pos
			read_char(l)
			tok = GetToken(.Not_Equal, l.input, start, 2)
		} else do tok = token_from_current_char(l, .Bang)
	case '/':
		tok = token_from_current_char(l, .Slash)
	case '*':
		tok = token_from_current_char(l, .Asterisk)
	case '<':
		tok = token_from_current_char(l, .Less_Than)
	case '>':
		tok = token_from_current_char(l, .Greater_Than)
	case ';':
		tok = token_from_current_char(l, .Semicolon)
	case ':':
		tok = token_from_current_char(l, .Colon)
	case ',':
		tok = token_from_current_char(l, .Comma)
	case '(':
		tok = token_from_current_char(l, .Left_Paren)
	case ')':
		tok = token_from_current_char(l, .Right_Paren)
	case '{':
		tok = token_from_current_char(l, .Left_Brace)
	case '}':
		tok = token_from_current_char(l, .Right_Brace)
	case '[':
		tok = token_from_current_char(l, .Left_Bracket)
	case ']':
		tok = token_from_current_char(l, .Right_Bracket)
	case '"':
		tok = create_string(l)
	case 0:
		tok.text_slice = {}
		tok.type = .EOF
	case:
		if is_letter(l.ch) {
			tok = create_identifier(l)
			UpdateKwType(&tok)
			return tok
		} else if is_digit(l.ch) do return create_number(l)
		tok = token_from_current_char(l, .Illegal)
	}
	read_char(l)
	return tok
}

@(test)
test_lexer :: proc(t: ^testing.T) {
	input := `let five = 5;
							let ten = 10;

							let add = fn(x, y) {
									x + y;
							};

							let result = add(five, ten);

							5 < 10 > 5;

							if 5 < 10 {
									return true;
							} else {
									return false;
							}

							10 == 10;
							10 != 9;
							"foobar"
							"foo bar"
							[]
							:
	`


	tests := [?]struct {
		expected_type:    Token_Type,
		expected_literal: string,
	} {
		{.Let, "let"},
		{.Identifier, "five"},
		{.Assign, "="},
		{.Int, "5"},
		{.Semicolon, ";"},

		//
		{.Let, "let"},
		{.Identifier, "ten"},
		{.Assign, "="},
		{.Int, "10"},
		{.Semicolon, ";"},

		//
		{.Let, "let"},
		{.Identifier, "add"},
		{.Assign, "="},
		{.Function, "fn"},
		{.Left_Paren, "("},
		{.Identifier, "x"},
		{.Comma, ","},
		{.Identifier, "y"},
		{.Right_Paren, ")"},
		{.Left_Brace, "{"},
		{.Identifier, "x"},
		{.Plus, "+"},
		{.Identifier, "y"},
		{.Semicolon, ";"},
		{.Right_Brace, "}"},
		{.Semicolon, ";"},

		//
		{.Let, "let"},
		{.Identifier, "result"},
		{.Assign, "="},
		{.Identifier, "add"},
		{.Left_Paren, "("},
		{.Identifier, "five"},
		{.Comma, ","},
		{.Identifier, "ten"},
		{.Right_Paren, ")"},
		{.Semicolon, ";"},

		//
		{.Int, "5"},
		{.Less_Than, "<"},
		{.Int, "10"},
		{.Greater_Than, ">"},
		{.Int, "5"},
		{.Semicolon, ";"},

		//
		{.If, "if"},
		{.Int, "5"},
		{.Less_Than, "<"},
		{.Int, "10"},
		{.Left_Brace, "{"},

		//
		{.Return, "return"},
		{.True, "true"},
		{.Semicolon, ";"},

		//
		{.Right_Brace, "}"},
		{.Else, "else"},
		{.Left_Brace, "{"},

		//
		{.Return, "return"},
		{.False, "false"},
		{.Semicolon, ";"},

		//
		{.Right_Brace, "}"},

		//
		{.Int, "10"},
		{.Equal, "=="},
		{.Int, "10"},
		{.Semicolon, ";"},

		//
		{.Int, "10"},
		{.Not_Equal, "!="},
		{.Int, "9"},
		{.Semicolon, ";"},

		//
		{.String, "foobar"},
		{.String, "foo bar"},

		//
		{.Left_Bracket, "["},
		{.Right_Bracket, "]"},

		//
		{.Colon, ":"},

		// end of file
		{.EOF, ""},

		// end of test cases
	}

	l := LexerNew()
	l->init(input)

	for test_case, i in tests {
		tok := l->next_token()

		if tok.type != test_case.expected_type {
			log.errorf(
				"tests[%d] - token wrong. expected='%v', got='%v'",
				i,
				test_case.expected_type,
				tok.type,
			)
			continue
		}

		if string(tok.text_slice) != test_case.expected_literal {
			log.errorf(
				"tests[%d] - literal wrong. expected='%s', got='%s'",
				i,
				test_case.expected_literal,
				string(tok.text_slice),
			)
		}
	}
}


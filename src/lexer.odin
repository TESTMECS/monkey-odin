package monkey
/*
* Copyright (C) 2025 TESTMEE
* ./lexer.odin
*/
// Main procedure for getting the next token from the input string.
next_token :: proc(l: ^Lexer) -> Token {
	tok: Token
	skip_whitespace(l)
	switch l.ch {
	case '=':
		if peek_char(l) == '=' {
			start := l.pos
			l->read_char()
			tok = GetToken(.Equal, l.input, start, 2)
		}
		 else do tok = token_from_current_char(l, .Assign)
	case '+':
		tok = token_from_current_char(l, .Plus)
	case '-':
		if peek_char(l) == '>' {
			start := l.pos
			l->read_char()
			tok = GetToken(.Arrow, l.input, start, 2)
		}
		 else do tok = token_from_current_char(l, .Minus)
	case '!':
		if peek_char(l) == '=' {
			start := l.pos
			l->read_char()
			tok = GetToken(.Not_Equal, l.input, start, 2)
		}
		 else do tok = token_from_current_char(l, .Bang)
	case '/':
		tok = token_from_current_char(l, .Slash)
	case '*':
		tok = token_from_current_char(l, .Asterisk)
	case '<':
		if peek_char(l) == '<' {
			start := l.pos
			l->read_char()
			tok = GetToken(.LShift, l.input, start, 2)
		}
		 else if peek_char(l) == '=' {
			start := l.pos
			l->read_char()
			tok = GetToken(.Less_Than_Equal, l.input, start, 2)
		}
		 else do tok = token_from_current_char(l, .Less_Than)
	case '>':
		if peek_char(l) == '>' {
			start := l.pos
			l->read_char()
			tok = GetToken(.RShift, l.input, start, 2)
		}
		 else if peek_char(l) == '=' {
			start := l.pos
			l->read_char()
			tok = GetToken(.Greater_Than_Equal, l.input, start, 2)
		}
		 else do tok = token_from_current_char(l, .Greater_Than)
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
	case '?':
		tok = token_from_current_char(l, .Question_Mark)
	case '%':
		tok = token_from_current_char(l, .Percent)
	case '|':
		if peek_char(l) == '|' {
			start := l.pos
			l->read_char()
			tok = GetToken(.Lor, l.input, start, 2)
		}
		 else do tok = token_from_current_char(l, .Pipe)
	case '&':
		if peek_char(l) == '&' {
			start := l.pos
			l->read_char()
			tok = GetToken(.Land, l.input, start, 2)
		}
		 else do tok = token_from_current_char(l, .Ampersand)
	case '^':
		tok = token_from_current_char(l, .Caret)
	case '~':
		tok = token_from_current_char(l, .Tilde)
	case '"':
		tok = create_string(l)
	case '#':
		for l.ch != '\n' && l.ch != 0 {l->read_char()}
		return l->next_token()
	case 0:
		tok.text_slice = {}
		tok.type = .EOF
	case:
		// Identifiers, numbers, and keywords
		if is_letter(l.ch) {
			tok = create_identifier(l)
			UpdateKwType(&tok)
			return tok
		}
		 else if is_digit(l.ch) do return create_number(l)
		tok = token_from_current_char(l, .Illegal)
	}
	l->read_char()
	return tok
}
// Reads the next character from the input string.
// Updates l.pos and l.read_pos.
read_char :: proc(l: ^Lexer) {
	if l.read_pos >= len(l.input) {
		l.ch = 0
	}
	 else {
		l.ch = l.input[l.read_pos]
	}
	l.pos = l.read_pos
	l.read_pos += 1
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
@(private = "file")
skip_whitespace :: proc(l: ^Lexer) {
	for l.ch == ' ' || l.ch == '\t' || l.ch == '\n' || l.ch == '\r' do read_char(l)
}
@(private = "file")
create_identifier :: proc(l: ^Lexer) -> Token {
	start := l.pos
	read_char(l)
	for is_letter(l.ch) || is_digit(l.ch) do read_char(l)
	return GetToken(.Identifier, l.input, start, l.pos - start)
}
@(private = "file")
create_number :: proc(l: ^Lexer) -> Token {
	start := l.pos
	for is_digit(l.ch) do read_char(l)
	if l.ch == '.' {
		read_char(l)
		for is_digit(l.ch) do read_char(l)
		return GetToken(.Int, l.input, start, l.pos - start)
	}
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

@(private = "file")
peek_char :: proc(l: ^Lexer) -> u8 {
	return l.read_pos >= len(l.input) ? 0 : l.input[l.read_pos]
}
@(rodata)
LEXERVTABLE := Lexer_VTable {
	next_token = next_token,
	read_char  = read_char,
}


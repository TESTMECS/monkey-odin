package monkey
Lexer :: struct {
	input:      []u8,
	pos:        int,
	read_pos:   int,
	ch:         u8,
	next_token: proc(l: ^Lexer) -> Token,
}
Lexer_New :: proc(input: string) -> Lexer {
	l := Lexer {
		ch         = 0,
		input      = transmute([]u8)input,
		pos        = 0,
		read_pos   = 0,
		next_token = next_token,
	}
	read_char(&l)
	return l
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
peek_char :: proc(l: ^Lexer) -> u8 {
	return l.read_pos >= len(l.input) ? 0 : l.input[l.read_pos]
}

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
		}
		 else do tok = token_from_current_char(l, .Assign)
	case '+':
		tok = token_from_current_char(l, .Plus)
	case '-':
		tok = token_from_current_char(l, .Minus)
	case '!':
		if peek_char(l) == '=' {
			start := l.pos
			read_char(l)
			tok = GetToken(.Not_Equal, l.input, start, 2)
		}
		 else do tok = token_from_current_char(l, .Bang)
	case '/':
		tok = token_from_current_char(l, .Slash)
	case '*':
		tok = token_from_current_char(l, .Asterisk)
	case '<':
		if peek_char(l) == '=' {
			start := l.pos
			read_char(l)
			tok = GetToken(.Less_Than_Equal, l.input, start, 2)
		}
		 else do tok = token_from_current_char(l, .Less_Than)
	case '>':
		if peek_char(l) == '=' {
			start := l.pos
			read_char(l)
			tok = GetToken(.Greater_Than_Equal, l.input, start, 2)
		}
		 else do tok = token_from_current_char(l, .Greater_Than)
	case ';':
		tok = token_from_current_char(l, .Semicolon)
	case ':':
		tok = token_from_current_char(l, .Colon)
	case ',':
		tok = token_from_current_char(l, .Comma)
	case '.':
		tok = token_from_current_char(l, .Dot)
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
	case '"':
		tok = create_string(l)
	case '#':
		for l.ch != '\n' && l.ch != 0 do read_char(l)
		return next_token(l)
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
	read_char(l)
	return tok
}


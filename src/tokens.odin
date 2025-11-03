package monkey

Token_Type :: enum {
	Illegal,
	EOF,
	Identifier,
	Int,
	String,
	Assign,
	Plus,
	Minus,
	Bang,
	Asterisk,
	Slash,
	Less_Than,
	Greater_Than,
	Equal,
	Not_Equal,
	Comma,
	Semicolon,
	Colon,
	Left_Paren,
	Right_Paren,
	Left_Brace,
	Right_Brace,
	Left_Bracket,
	Right_Bracket,
	Function,
	Let,
	True,
	False,
	If,
	Else,
	Return,
	Macro,
	For,
}

Token :: struct {
	type:       Token_Type,
	text_slice: []u8,
}

GetToken :: proc(type: Token_Type, input: []u8, start: int, length: int) -> Token {
	return {type, input[start:start + length]}
}

UpdateKwType :: proc(tok: ^Token) {
	switch (string(tok.text_slice)) {
	case "fn":
		tok.type = .Function
	case "let":
		tok.type = .Let
	case "true":
		tok.type = .True
	case "false":
		tok.type = .False
	case "if":
		tok.type = .If
	case "else":
		tok.type = .Else
	case "return":
		tok.type = .Return
	case "macro":
		tok.type = .Macro
	case "for":
		tok.type = .For
	}
}


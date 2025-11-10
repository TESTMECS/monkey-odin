package lexer_tests

import monkey "../../src"
import "core:log"
import "core:testing"

@(test)
test_lexer :: proc(t: ^testing.T) {
	using monkey
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
              # comment
							foreach 
							in
							?
							%
							|
							>>
							<<
							&
							^
							||
							&&
							~
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
		//
		{.Foreach, "foreach"},
		{.In, "in"},
		{.Question_Mark, "?"},
		{.Percent, "%"},
		{.Pipe, "|"},
		{.RShift, ">>"},
		{.LShift, "<<"},
		{.Ampersand, "&"},
		{.Caret, "^"},
		{.Lor, "||"},
		{.Land, "&&"},
		{.Tilde, "~"},

		// end of file
		{.EOF, ""},

		// end of test cases
	}

	l := Lexer_New(input)

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


package parser_tests

import monkey "../../src"
import "core:log"
import "core:testing"

@(test)
test_parse_string_literal :: proc(t: ^testing.T) {
	using monkey
	input := `"hello world";`

	p := Parser__New__(input)
	defer p->free()

	program := p->parse()
	if parser_has_error(p) do return

	if len(program) != 1 {
		log.errorf("program does not contain 1 statement, got='%v'", len(program))
		return
	}

	literal, str_ok := program[0].(string)
	if !str_ok {
		log.errorf("expression is not string, got='%v'", Ast__Type__(program[0]))
		return
	}

	if literal != "hello world" {
		log.errorf("string is not 'hello world', got='%s'", literal)
	}
}


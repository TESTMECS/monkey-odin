package parser_tests

import monkey "../../src"
import "core:log"
import "core:mem/virtual"
import "core:testing"

@(test)
test_parse_string_literal :: proc(t: ^testing.T) {
	using monkey
	using tc

	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	input := `"hello world";`

	p := Parser_New(input, a)

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


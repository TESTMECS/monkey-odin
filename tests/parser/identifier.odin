package parser_tests

import monkey "../../src"
import "core:log"
import "core:testing"

@(test)
test_parse_identifier :: proc(t: ^testing.T) {
	using monkey

	input := "foobar;"
	p := Parser__New__(input)
	defer p->free()

	program := p->parse()
	if parser_has_error(p) do return

	if len(program) != 1 {
		log.errorf("Program does not contain at least 1 statement, got'%v'", len(program))
		return
	}

	identifier_is_valid(&program[0], "foobar")
}


package tests

import m "../.."
import "core:testing"
import "core:log"

@(test)
test_integer_literal :: proc(t: ^testing.T) {
	input := "5;"
	p := m.Parser__New__(input)
	defer p->free()

	program := p->parse()
	if parser_has_error(p) do return

	if len(program) != 1 {
		log.errorf("program does not contain 1 statement, got='%v'", len(program))
		return
	}

	literal_value_is_valid(&program[0], 5)
}

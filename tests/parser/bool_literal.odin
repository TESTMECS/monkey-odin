package parser_tests

import m "../.."
import "core:testing"
import "core:log"

@(test)
test_boolean :: proc(t: ^testing.T) {
	input := "true;"
	p := m.Parser__New__(input)
	defer p->free()

	program := p->parse()
	if parser_has_error(p) do return

	if len(program) != 1 {
		log.errorf("program does not contain 1 statement, got='%v'", len(program))
		return
	}

	literal_value_is_valid(&program[0], true)
}

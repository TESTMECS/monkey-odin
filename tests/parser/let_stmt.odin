package parser_tests

import monkey "../../src"
import "core:log"
import "core:testing"
@(test)
test_let_statement :: proc(t: ^testing.T) {
	using monkey
	input := `
	let x = 5;
	let y = true;
	let foobar = y;
	`


	tests := [?]struct {
		expected_identifier: string,
		expected_value:      Literal,
	}{{"x", 5}, {"y", true}, {"foobar", "y"}}

	p := Parser__New__(input)
	defer p->free()

	program := p->parse()
	if parser_has_error(p) do return

	if len(program) != 3 {
		log.errorf("program does not contain 3 statements, got='%v'", len(program))
		return
	}

	for test_case, i in tests {
		if !stmt_is_let(program[i], test_case.expected_identifier, test_case.expected_value) {
			log.errorf("test [%d] has failed", i)
		}
	}
}


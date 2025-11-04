package parser_tests

import monkey "../../src"
import "core:log"
import "core:mem/virtual"
import "core:testing"

@(test)
test_let_statement :: proc(t: ^testing.T) {
	using monkey
	using tc

	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	input := `
	let x = 5;
	let y = true;
	let foobar = y;
	`


	tests := [?]struct {
		expected_identifier: string,
		expected_value:      Literal,
	}{{"x", 5}, {"y", true}, {"foobar", "y"}}

	p := Parser_New(input, a)

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


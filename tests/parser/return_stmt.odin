package parser_tests

import monkey "../../src"
import "core:log"
import "core:testing"

@(test)
test_parsing_return_statement :: proc(t: ^testing.T) {
	using monkey
	input := `
	return 5;
	return 10;
	return 100;
	`


	p := Parser__New__(input)
	defer p->free()

	program := p->parse()
	if parser_has_error(p) do return

	if len(program) != 3 {
		log.errorf("program does not contain 3 statements, got='%v'", len(program))
		return
	}

	tests := [?]struct {
		expected_identifier: string,
	}{{"x"}, {"y"}, {"foobar"}}

	for _, i in tests {
		stmt := program[i]
		_, ok := stmt.(Ast_Ret)
		if !ok {
			log.errorf("test [%d]: stmt is not a return statement. got='%v'", i, Ast__Type__(stmt))
		}
	}
}


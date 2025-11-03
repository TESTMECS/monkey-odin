package parser_tests

import monkey "../../src"
import "core:log"
import "core:testing"

@(test)
test_array :: proc(t: ^testing.T) {
	using monkey
	input := "[1,2*2,3+3]"
	p := Parser__New__(input)
	defer p->free()

	program := p->parse()
	if parser_has_error(p) do return

	if len(program) != 1 {
		log.errorf("program does not contain 1 statement, got='%v'", len(program))
		return
	}

	stmt, ok := program[0].(Ast_Array) // check array
	if !ok {
		log.errorf("program[0] is not Ast_Array, got='%v'", Ast__Type__(program[0]))
		return
	}

	if len(stmt) != 3 {
		log.errorf("length of the array is not 3, got='%d'", len(stmt))
		return
	}

	literal_value_is_valid(&stmt[0], 1)
	infix_expression_is_valid(&stmt[1], 2, "*", 2)
	infix_expression_is_valid(&stmt[2], 3, "+", 3)
}


package parser_tests

import monkey "../../src"
import "core:log"
import "core:mem/virtual"
import "core:testing"

@(test)
test_parse_if_expression :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	input := `
	if true { 10 } else { 20 }
	`


	p := Parser_New(input, a)

	program := p->parse()
	if parser_has_error(p) do return

	if len(program) != 1 {
		log.errorf("program does not contain 1 statement, got='%v'", len(program))
		return
	}

	stmt, ok := program[0].(Ast_If)
	if !ok {
		log.errorf("program[0] is not Ast_If, got='%v'", Ast__Type__(program[0]))
		return
	}
	// stmt.condition
	if !literal_value_is_valid(stmt.condition, true) {
		log.errorf("stmt.condition is not 'true', got='%v'", Ast__Type__(stmt.condition))
		return
	}

	// stmt.then
	if len(stmt.then) != 1 {
		log.errorf("stmt.then does not contain 1 statement, got='%v'", len(stmt.then))
		return
	}
	if !literal_value_is_valid(&stmt.then[0], 10) {
		log.errorf("stmt.then[0] is not '10', got='%v'", Ast__Type__(stmt.then[0]))
		return
	}

	// stmt.orelse
	if stmt.orelse == nil {
		log.errorf("stmt.orelse is nil, expected else block")
		return
	}
	if len(stmt.orelse) != 1 {
		log.errorf("stmt.orelse does not contain 1 statement, got='%v'", len(stmt.orelse))
		return
	}

	if !literal_value_is_valid(&stmt.orelse[0], 20) {
		log.errorf("stmt.orelse[0] is not '20', got='%v'", Ast__Type__(stmt.orelse[0]))
		return
	}
}


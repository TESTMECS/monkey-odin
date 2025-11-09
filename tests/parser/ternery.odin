package parser_tests

import monkey "../../src"
import "core:log"
import "core:mem/virtual"
import "core:testing"
@(test)
test_ternery :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	input := `true ? "hello world" : "hello world";`

	p := Parser_New(input, a)

	program := p->parse()
	if parser_has_error(p) do return

	if len(program) != 1 {
		log.errorf("program does not contain 1 statement, got='%v'", len(program))
		return
	}
	ternery, tern_ok := program[0].(Ast_Ternery)
	if !tern_ok {
		log.errorf("expression is not ternery, got='%v'", Ast__Type__(program[0]))
		return
	}

	condition, cond_ok := ternery.condition.(bool)
	then, then_ok := ternery.then.(string)
	orelse, orelse_ok := ternery.orelse.(string)

	if !cond_ok || !then_ok || !orelse_ok {
		log.errorf("ternery parts are not correct types, condition=%v, then=%v, orelse=%v", 
			Ast__Type__(ternery.condition^), Ast__Type__(ternery.then^), Ast__Type__(ternery.orelse^))
		return
	}

	if !condition {
		log.errorf("condition is not true, got='%v'", condition)
		return
	}

	if then != "hello world" {
		log.errorf("then is not 'hello world', got='%s'", then)
		return
	}

	if orelse != "hello world" {
		log.errorf("orelse is not 'hello world', got='%s'", orelse)
		return
	}
}


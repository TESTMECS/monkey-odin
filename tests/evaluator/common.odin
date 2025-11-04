package evaluator_tests

import monkey "../../src"
import test_commons "../../tests_commons"
import "core:log"
import "core:mem/virtual"

tc :: test_commons

eval_test_get :: proc(
	input: string,
	print_errors := true,
) -> (
	monkey.ObjectBase,
	monkey.Evaluator,
	bool,
	tc.Vmem,
) {
	using monkey
	using tc

	v := new_vmem()
	a := virtual.arena_allocator(v.a)

	p := Parser_New(input, a)

	program := p->parse()
	if parser_has_error(p) do return nil, Evaluator{}, false, v

	e := Evaluator_New(a) // Create the evaluator
	evaluated, ok := e.eval(&e, program, a) // Evaluate the program

	if !ok {
		if print_errors do log.errorf("eval failed: %s", evaluated)
		return nil, Evaluator{}, false, v
	}

	return evaluated, e, true, v
}

eval_test_is_valid :: proc(
	input: string,
	print_errors := true,
) -> (
	monkey.ObjectBase,
	monkey.Evaluator,
	bool,
	tc.Vmem,
) {
	using monkey
	evaluated, e, ok, v := eval_test_get(input, print_errors)
	if !ok do return nil, Evaluator{}, false, v
	return evaluated, e, ok, v
}


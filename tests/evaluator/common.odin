package evaluator_tests

import monkey "../../src"
import "core:log"

eval_test_get :: proc(
	input: string,
	print_errors := true,
) -> (
	monkey.ObjectBase,
	monkey.Evaluator,
	bool,
) {
	using monkey
	p := Parser__New__(input)
	defer p->free()
	program := p->parse()
	if parser_has_error(p) do return nil, Evaluator{}, false

	e := Evaluator_New() // Create the evaluator
	evaluated, ok := e.eval(&e, program, context.allocator) // Evaluate the program

	if !ok {
		if print_errors do log.errorf("eval failed: %s", evaluated)
		e->free()
		return nil, Evaluator{}, false
	}

	return evaluated, e, true
}

eval_test_is_valid :: proc(
	input: string,
	print_errors := true,
) -> (
	monkey.ObjectBase,
	monkey.Evaluator,
	bool,
) {
	using monkey
	evaluated, e, ok := eval_test_get(input, print_errors)
	if !ok do return nil, Evaluator{}, false
	return evaluated, e, ok
}


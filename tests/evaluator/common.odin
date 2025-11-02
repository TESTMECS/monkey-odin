package evaluator_tests
import m "../.."
import "core:log"

eval_test_get :: proc(input: string, print_errors := true) -> (m.ObjectBase, m.Evaluator, bool) {
	p := m.Parser__New__(input)
	defer p->free()
	program := p->parse()
	if m.parser_has_error(p) do return nil, m.Evaluator{}, false

	e := m.Evaluator_New() // Create the evaluator
	evaluated, ok := e.eval(&e, program, e.vmem.allocator) // Evaluate the program
	if !ok {
		if print_errors do log.errorf("eval failed: %s", evaluated)
		e->free()
		return nil, m.Evaluator{}, false
	}
	return evaluated, e, true
}

eval_test_is_valid :: proc(input: string, print_errors := true) -> (m.ObjectBase, bool) {
	evaluated, _, ok := eval_test_get(input, print_errors)
	if !ok do return nil, false
	return evaluated, ok
}


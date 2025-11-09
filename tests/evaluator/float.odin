package evaluator_tests

import monkey "../../src"
import "core:log"
import "core:testing"

@(test)
test_eval_float_expression :: proc(t: ^testing.T) {
	using monkey
	using tc
	tests := [?]struct {
		input:    string,
		expected: f64,
	}{{"1.0", 1.0}, {"1.0+1.0", 2.0}}

	for test_case, i in tests {
		evaluated, e, ok, v := eval_test_is_valid(test_case.input)
		defer v->free()
		if !ok {
			log.errorf("test [%d] has failed", i)
			continue
		}
		log.info(evaluated)
	}
}


#+feature dynamic-literals
package evaluator_tests

import monkey "../../src"
import "core:log"
import "core:testing"

@(test)
test_eval_let_statements :: proc(t: ^testing.T) {
	using monkey
	tests := [?]struct {
		input:    string,
		expected: int,
	} {
		{"let a = 5; a;", 5},
		{"let a = 5 * 5; a;", 25},
		{"let a = 5; let b = a; b;", 5},
		{"let a = 5; let b = a; let c = a + b + 5; c;", 15},
	}

	for test_case, i in tests {
		evaluated, e, ok := eval_test_is_valid(test_case.input)
		defer e->free()
		if !ok {
			log.errorf("test[%d] has failed", i)
			continue
		}

		if !integer_object_is_valid(evaluated, test_case.expected) {
			log.errorf("test[%d] has failed", i)
		}
	}
}


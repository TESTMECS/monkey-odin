package evaluator_tests

import monkey "../../src"
import "core:log"
import "core:testing"

@(test)
test_eval_bang_operator :: proc(t: ^testing.T) {
	using monkey
	using tc
	tests := [?]struct {
		input:    string,
		expected: bool,
	} {
		{"!true", false},
		{"!false", true},
		{"!1", false},
		{"!!true", true},
		{"!!false", false},
		{"!!1", true},
	}

	for test_case, i in tests {
		evaluated, e, ok, v := eval_test_is_valid(test_case.input)
		defer v->free()
		if !ok {
			log.errorf("test [%d] has failed", i)
			continue
		}
		if !boolean_object_is_valid(evaluated, test_case.expected) {
			log.errorf("test [%d] has failed", i)
		}
	}
}


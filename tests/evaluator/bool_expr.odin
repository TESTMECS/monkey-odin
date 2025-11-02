package evaluator_tests

import m "../.."
import "core:log"
import "core:testing"

@(test)
test_eval_boolean_expression :: proc(t: ^testing.T) {
	tests := [?]struct {
		input:    string,
		expected: bool,
	} {
		{"true", true},
		{"false", false},
		{"1<2", true},
		{"1>2", false},
		{"1==1", true},
		{"1!=1", false},
		{"true == true", true},
		{"false == false", true},
		{"(1 < 2) == true", true},
		{"(1 < 2) == false", false},
	}

	for test_case, i in tests {
		evaluated, ok := eval_test_is_valid(test_case.input)
		if !ok {
			log.errorf("test [%d] has failed", i)
			continue
		}
		if !m.boolean_object_is_valid(evaluated, test_case.expected) {
			log.errorf("test [%d] has failed", i)
		}
	}
}


package evaluator_tests

import m "../.."
import "core:log"
import "core:testing"

@(test)
test_eval_integer_expression :: proc(t: ^testing.T) {
	tests := [?]struct {
		input:    string,
		expected: int,
	} {
		{"5", 5},
		{"10", 10},
		{"-5", -5},
		{"-10", -10},
		{"5 + 5 + 5 + 5 - 10", 10},
		{"2 * 2 * 2 * 2 * 2", 32},
		{"-50 + 100 + -50", 0},
		{"5 * 2 + 10", 20},
		{"5 + 2 * 10", 25},
		{"20 + 2 * -10", 0},
		{"50 / 2 * 2 + 10", 60},
		{"2 * (5 + 10)", 30},
		{"3 * 3 * 3 + 10", 37},
		{"3 * (3 * 3) + 10", 37},
		{"(5 + 10 * 2 + 15 / 3) * 2 + -10", 50},
		{"(5 + 10 * 2 + 15 / 3) * 2 + -10", 50},
	}
	for test, i in tests {
		evaluated, e, ok := eval_test_is_valid(test.input)
		defer e->free()
		if !ok do return

		if !m.integer_object_is_valid(evaluated, test.expected) {
			log.errorf("test [%d] has failed", i)
		}
	}

}


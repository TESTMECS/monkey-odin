package evaluator_tests

import m "../.."
import "core:log"
import "core:testing"

@(test)
test_eval_return_statement :: proc(t: ^testing.T) {
	tests := [?]struct {
		input:    string,
		expected: int,
	} {
		{"return 10;", 10},
		{"return 10; 9;", 10},
		{"return 2 * 5; 9;", 10},
		{"9; return 2 * 5; 9;", 10},
		{
			`
    if 10 > 1 {
        if 10 > 1 {
            return 10;
        }

        return 1;
    }`,
			10,
		},
	}

	for test_case, i in tests {
		evaluated, ok := eval_test_is_valid(test_case.input)
		if !ok {
			log.errorf("test[%d] has failed", i)
			continue
		}

		if !m.integer_object_is_valid(evaluated, test_case.expected) {
			log.errorf("test[%d] has failed", i)
		}
	}
}


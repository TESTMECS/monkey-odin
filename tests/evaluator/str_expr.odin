package evaluator_tests
import m "../.."
import "core:log"
import "core:testing"

@(test)
test_eval_string_expression :: proc(t: ^testing.T) {
	tests := [?]struct {
		input:    string,
		expected: string,
	}{{`"Hello World"`, "Hello World"}, {`"Hello" + " " + "World"`, "Hello World"}}

	for test_case, i in tests {
		evaluated, ok := eval_test_is_valid(test_case.input)
		if !ok {
			log.errorf("test [%d] has failed", i)
			continue
		}
		if !m.string_object_is_valid(evaluated, test_case.expected) {
			log.errorf("test [%d] has failed", i)
		}
	}
}


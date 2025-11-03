package evaluator_tests

import monkey "../../src"
import "core:log"
import "core:testing"

@(test)
test_eval_string_expression :: proc(t: ^testing.T) {
	using monkey
	tests := [?]struct {
		input:    string,
		expected: string,
	}{{`"Hello World"`, "Hello World"}, {`"Hello" + " " + "World"`, "Hello World"}}
	defer free_all(context.allocator)

	for test_case, i in tests {
		evaluated, e, ok := eval_test_is_valid(test_case.input)
		defer e->free()
		if !ok {
			log.errorf("test [%d] has failed", i)
			continue
		}
		if !string_object_is_valid(evaluated, test_case.expected) {
			log.errorf("test [%d] has failed", i)
		}
	}
}


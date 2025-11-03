package evaluator_tests

import monkey "../../src"
import "core:log"
import "core:testing"

@(test)
test_eval_array_literals :: proc(t: ^testing.T) {
	using monkey
	input := "[1, 2 * 2, 3 + 3]"

	evaluated, e, ok := eval_test_is_valid(input)
	defer e->free()
	if !ok do return

	arr, is_arr := evaluated.(ObjectArray)
	if !is_arr {
		log.errorf("expected array object but got '%v'", ObjectType(evaluated))
		return
	}

	if len(arr) != 3 {
		log.errorf("expected array length to be 3 but got='%d'", len(arr))
		return
	}

	if !integer_object_is_valid(arr[0], 1) {
		log.errorf("arr[0] does not match")
	}

	if !integer_object_is_valid(arr[1], 4) {
		log.errorf("arr[1] does not match")
	}

	if !integer_object_is_valid(arr[2], 6) {
		log.errorf("arr[2] does not match")
	}
}

@(test)
test_eval_array_index_expression :: proc(t: ^testing.T) {
	using monkey
	tests := [?]struct {
		input:    string,
		expected: int,
	} {
		{"[1, 2, 3][0]", 1},
		{"[1, 2, 3][1]", 2},
		{"[1, 2, 3][2]", 3},
		{"let i = 0; [1][i]", 1},
		{"[1, 2, 3][1 + 1];", 3},
		{"let my_arr = [1, 2, 3]; my_arr[2]", 3},
		{"let my_arr = [1, 2, 3]; my_arr[0] + my_arr[1] + my_arr[2];", 6},
		{"let my_arr = [1, 2, 3]; let i = my_arr[0]; my_arr[i]", 2},
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


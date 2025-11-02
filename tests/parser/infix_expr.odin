package parser_tests

import m "../.."
import "core:testing"
import "core:log"


@(test)
test_parsing_infix :: proc(t: ^testing.T) {
	tests := []struct {
		input:       string,
		left_value:  Literal,
		operator:    string,
		right_value: Literal,
	} {
		{"5 + 5;", 5, "+", 5},
		{"5 - 5;", 5, "-", 5},
		{"5 * 5;", 5, "*", 5},
		{"5 / 5;", 5, "/", 5},
		{"5 > 5;", 5, ">", 5},
		{"5 < 5;", 5, "<", 5},
		{"5 == 5;", 5, "==", 5},
		{"5 != 5;", 5, "!=", 5},
		{"true == true", true, "==", true},
		{"true != false", true, "!=", false},
		{"false == false", false, "==", false},
	}

	defer free_all(context.temp_allocator)

	for test_case, i in tests {
		if !infix_test_case_is_valid(
			test_case.input,
			test_case.left_value,
			test_case.operator,
			test_case.right_value,
		) {
			log.errorf("Test [%d] has failed", i)
		}
	}

}

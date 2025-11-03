package parser_tests

import monkey "../../src"
import "core:log"
import "core:testing"


@(test)
test_prefix_expression :: proc(t: ^testing.T) {
	using monkey
	prefix_tests := [?]struct {
		input:         string,
		operator:      string,
		operand_value: Literal,
	}{{"!5;", "!", 5}, {"-15;", "-", 15}, {"!true;", "!", true}, {"!false;", "!", false}}

	defer free_all(context.temp_allocator)

	for test_case, i in prefix_tests {
		if !prefix_test_case_is_ok(
			i,
			test_case.input,
			test_case.operator,
			test_case.operand_value,
		) {
			log.errorf("Test [%d] has failed", i)
		}
	}

}


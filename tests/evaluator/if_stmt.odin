#+feature dynamic-literals
package evaluator_tests
import m "../.."
import "core:log"
import "core:testing"

@(test)
test_eval_if_expression :: proc(t: ^testing.T) {
	tests := [?]struct {
		input:    string,
		expected: m.ObjectBase,
	} {
		{"if (true) { 10 }", 10},
		{"if (false) { 10 }", m.NULL},
		{"if (1) { 10 }", 10},
		{"if (1 < 2) { 10 }", 10},
		{"if (1 > 2) { 10 }", m.NULL},
		{"if (1 < 2) { 10 } else { 20 }", 10},
		{"if (1 > 2) { 10 } else { 20 }", 20},
	}
	for test_case, i in tests {
		evaluated, e, ok := eval_test_is_valid(test_case.input)
		defer e->free()
		if !ok {
			log.errorf("test [%d] has failed", i)
			continue
		}
		#partial switch expected in test_case.expected {
		case int:
			if !m.integer_object_is_valid(evaluated, expected) {
				log.errorf("test [%d] has failed", i)
			}
		case m.ObjectNil:
			if m.ObjectType(evaluated) != m.ObjectNil {
				log.errorf(
					"test [%d] has failed, Object is not nil, got='%v' instead.",
					i,
					m.ObjectType(evaluated),
				)
			}
		}
	}
}


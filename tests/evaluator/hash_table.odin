#+feature dynamic-literals
package evaluator_tests

import monkey "../../src"
import "core:log"
import "core:testing"

@(test)
test_eval_hash_literals :: proc(t: ^testing.T) {
	using monkey
	using tc
	input := `
    {
        "one": 10 - 9,
        "two": 1 + 1,
        "three": 6 / 2,
    }`


	evaluated, e, ok, v := eval_test_is_valid(input)
	defer v->free()
	if !ok do return

	ht, is_hash_table := evaluated.(ObjectHashTable)
	if !is_hash_table {
		log.errorf("expected hash table object but got '%v'", ObjectType(evaluated))
		return
	}

	expected := make(map[string]int, 3, context.temp_allocator)
	expected["one"] = 1
	expected["two"] = 2
	expected["three"] = 3
	defer delete(expected)

	if len(ht) != len(expected) {
		log.errorf(
			"Hash table has wrong number of pairs, expected='%d', got='%d'",
			len(expected),
			len(ht),
		)
		return
	}

	for expected_key, expected_value in expected {
		value, key_exists := ht[expected_key]
		if !key_exists {
			log.errorf("key '%v' expected but does not exist", expected_key)
			continue
		}

		if !integer_object_is_valid(value, expected_value) {
			log.errorf("key '%s' has wrong value", expected_key)
		}
	}
}

@(test)
test_eval_hash_table_index_expression :: proc(t: ^testing.T) {
	using monkey
	using tc
	tests := [?]struct {
		input:    string,
		expected: int,
	}{{`{"foo": 5}["foo"]`, 5}, {`let key = "foo"; {"foo": 5}[key]`, 5}}

	for test_case, i in tests {
		evaluated, e, ok, v := eval_test_is_valid(test_case.input)
		defer v->free()
		if !ok {
			log.errorf("test[%d] has failed", i)
			continue
		}

		if !integer_object_is_valid(evaluated, test_case.expected) {
			log.errorf("test[%d] has failed", i)
		}
	}
}


package test_commons

import monkey "../src"
import "core:fmt"
import "core:reflect"
import "core:testing"

Test_Data :: union {
	int,
	bool,
	string,
	[]int,
	map[string]int,
}

test_expected_object :: proc(
	t: ^testing.T,
	expected: Test_Data,
	actual: monkey.ObjectBase,
) -> string {
	using monkey
	err := ""
	t := reflect.union_variant_typeid(expected)
	#partial switch expected_value in expected {
	case int:
		err = test_integer_object(expected_value, actual)
	case bool:
		err = test_boolean_object(expected_value, actual)
	case string:
		err = test_string_object(expected_value, actual)
	case []int:
		arr, ok := actual.(ObjectArray)
		if !ok {
			err = fmt.tprintf("expected array object but got '%v'", ObjectType(actual))
			break
		}
		if len(arr) != len(expected_value) {
			err = fmt.tprintf(
				"wrong num of elements, want='%v', got='%v'",
				len(expected_value),
				len(arr),
			)
			break
		}
		for e_elem, i in expected_value {
			if err = test_integer_object(e_elem, arr[i]); err != "" do break
		}
	case map[string]int:
		ht, ok := actual.(ObjectHashTable)
		if !ok {
			err = fmt.tprintf("expected hash table object but got '%v'", ObjectType(actual))
			break
		}
		if len(ht) != len(expected_value) {
			err = fmt.tprintf(
				"wrong num of elements, want='%v', got='%v'",
				len(expected_value),
				len(ht),
			)
			break
		}
		for key, value in expected_value {
			actual_value, key_exists := ht[key]
			if !key_exists {
				err = fmt.tprintf("key '%s' does not exist in the hash table", key)
				break
			}
			if err = test_integer_object(value, actual_value); err != "" do break
		}
	case nil:
		if ObjectType(actual) != ObjectNil {
			err = fmt.tprintf("expected nil but got '%v'", ObjectType(actual))
			break
		}
	}
	return ""
}


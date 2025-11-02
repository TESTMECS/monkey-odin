package monkey

import "core:fmt"
import "core:log"
import "core:reflect"
import "core:testing"

parser_has_error :: proc(p: Parser) -> bool {
	if len(p.errors) == 0 do return false

	log.errorf("parser has %d errors", len(p.errors))
	for msg, _ in p.errors {
		log.errorf("parser error: %q", msg)
	}

	return true
}

concat_instructions :: proc(s: []Instructions) -> Instructions {
	out := make(Instructions, 0, context.temp_allocator)
	for ins_slice in s {
		append(&out, ..ins_slice[:])
	}
	return out
}

test_integer_object :: proc(expected: int, actual: ObjectBase) -> (err: string) {
	result, ok := actual.(int)
	if !ok {
		return fmt.tprintf("object is not integer. got='%v'", ObjectType(actual))
	}

	if result != expected {
		return fmt.tprintf("object has wrong value. wants='%d', got='%d'", expected, result)
	}

	return ""
}

test_boolean_object :: proc(expected: bool, actual: ObjectBase) -> (err: string) {
	result, ok := actual.(bool)
	if !ok {
		return fmt.tprintf("object is not boolean. got='%v'", ObjectType(actual))
	}

	if result != expected {
		return fmt.tprintf("object has wrong value. wants='%v', got='%v'", expected, result)
	}

	return ""
}

test_string_object :: proc(expected: string, actual: ObjectBase) -> (err: string) {
	result, ok := actual.(string)
	if !ok {
		return fmt.tprintf("object is not string. got='%v'", ObjectType(actual))
	}

	if result != expected {
		return fmt.tprintf("object has wrong value. wants='%s', got='%s'", expected, result)
	}

	return ""
}

test_expected_object :: proc(t: ^testing.T, expected: Test_Data, actual: ObjectBase) -> string {
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

integer_object_is_valid :: proc(obj: ObjectBase, expected: int) -> bool {
	result, ok := obj.(int)
	if !ok {
		log.errorf("object is not integer, got='%v'", ObjectType(obj))
		return false
	}

	if result != expected {
		log.errorf("object has wrong value. got='%d', expected='%d'", result, expected)
		return false
	}

	return true
}
boolean_object_is_valid :: proc(obj: ObjectBase, expected: bool) -> bool {
	result, ok := obj.(bool)
	if !ok {
		log.errorf("object is not boolean, got='%v'", ObjectType(obj))
		return false
	}

	if result != expected {
		log.errorf("object has wrong value. got='%d', expected='%d'", result, expected)
		return false
	}

	return true
}

string_object_is_valid :: proc(obj: ObjectBase, expected: string) -> bool {
	result, ok := obj.(string)
	if !ok {
		log.errorf("object is not string, got='%v'", ObjectType(obj))
		return false
	}

	if result != expected {
		log.errorf("object has wrong value. got='%s', expected='%s'", result, expected)
		return false
	}

	return true
}


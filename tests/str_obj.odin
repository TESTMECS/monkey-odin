package test_commons
import monkey "../src"
import "core:fmt"
import "core:log"

test_string_object :: proc(expected: string, actual: monkey.ObjectBase) -> (err: string) {
	using monkey
	result, ok := actual.(string)
	if !ok do return fmt.tprintf("object is not string. got='%v'", monkey.ObjectType(actual))
	if result != expected do return fmt.tprintf("object has wrong value. wants='%s', got='%s'", expected, result)
	return ""
}

string_object_is_valid :: proc(obj: monkey.ObjectBase, expected: string) -> bool {
	using monkey
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


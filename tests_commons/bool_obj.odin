package test_commons
import monkey "../src"
import "core:fmt"
import "core:log"

test_boolean_object :: proc(expected: bool, actual: monkey.ObjectBase) -> (err: string) {
	using monkey
	result, ok := actual.(bool)
	if !ok do return fmt.tprintf("object is not boolean. got='%v'", ObjectType(actual))
	if result != expected do return fmt.tprintf("object has wrong value. wants='%v', got='%v'", expected, result)
	return ""
}

boolean_object_is_valid :: proc(obj: monkey.ObjectBase, expected: bool) -> bool {
	using monkey
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


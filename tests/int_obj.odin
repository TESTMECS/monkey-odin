package test_commons
import monkey "../src"
import "core:fmt"
import "core:log"

test_integer_object :: proc(expected: int, actual: monkey.ObjectBase) -> (err: string) {
	using monkey
	result, ok := actual.(int)
	if !ok do return fmt.tprintf("object is not integer. got='%v'", ObjectType(actual))
	if result != expected do return fmt.tprintf("object has wrong value. wants='%d', got='%d'", expected, result)
	return ""
}

integer_object_is_valid :: proc(obj: monkey.ObjectBase, expected: int) -> bool {
	using monkey
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


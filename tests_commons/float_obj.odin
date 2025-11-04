package test_commons
import monkey "../src"
import "core:fmt"
import "core:log"

test_float_object :: proc(expected: f64, actual: monkey.ObjectBase) -> (err: string) {
	using monkey
	result, ok := actual.(f64)
	if !ok do return fmt.tprintf("object is not float. got='%v'", ObjectType(actual))
	if result != expected do return fmt.tprintf("object has wrong value. wants='%f', got='%f'", expected, result)
	return ""
}

float_object_is_valid :: proc(obj: monkey.ObjectBase, expected: f64) -> bool {
	using monkey
	result, ok := obj.(f64)
	if !ok {
		log.errorf("object is not float, got='%v'", ObjectType(obj))
		return false
	}

	if result != expected {
		log.errorf("object has wrong value. got='%f', expected='%f'", result, expected)
		return false
	}

	return true
}
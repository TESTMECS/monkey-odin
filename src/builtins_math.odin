package monkey
import "core:math"
import "core:math/rand"
/*
* Copyright (C) 2025 TESTMEE
* ./builtins_math.odin
* This file defines the builtin math functions for monkey-odin.
* << b_abs, b_rand, b_choose, b_sin, b_cos, b_tan >>
*/
b_abs :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Get absolute value of int">>
				abs(value)
				$ value :: int
				Usage: abs(-1)=>>1<<`


	if len(args) != 1 {
		return e->eval_new_error(
				"'abs' function error: wrong number of arguments, wants='1', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	value, ok := args[0].(int)
	if !ok {
		return e->eval_new_error(
				"'abs' function error: not supported for argument of type '%v'.%s",
				ObjectType(args[0]),
				usage,
			),
			false
	}
	if value < 0 do return -value, true
	return value, true
}
b_rand :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Get random int">>
				rand()
				$ none
				Usage: rand()=>>1<<
				`


	if len(args) != 0 {
		return e->eval_new_error(
				"'rand' function error: wrong number of arguments, wants='0', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	return int(rand.int31()), true
}
b_choose :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Choose rand element from array">>
				choose(arr)
				$ arr :: int, int
				Usage: choose([1,2,3])=>>1<<
				`


	if len(args) != 1 {
		return e->eval_new_error(
				"'choose' function error: wrong number of arguments, wants='1', got='%d'",
				len(args),
			),
			false
	}
	arr, ok := args[0].(ObjectArray)
	if !ok {
		return e->eval_new_error(
				"'choose' function error: not supported for argument of type '%v'",
				ObjectType(args[0]),
			),
			false
	}
	if len(arr) == 0 {
		return e->eval_new_error("'choose' function error: cannot choose from empty array"), false
	}
	return arr[int(rand.int31()) % len(arr)], true
}
b_sin :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				Sine of angle in degrees
				sin(angle)
				$ angle :: float
				Usage: sin(90)=>>1<<`


	if len(args) != 1 {
		return e->eval_new_error(
				"'sin' function error: wrong number of arguments, wants='1', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	angle, ok := args[0].(f64)
	if !ok {
		return e->eval_new_error(
				"'sin' function error: not supported for argument of type '%v'.%s",
				ObjectType(args[0]),
				usage,
			),
			false
	}
	return math.sin(angle), true
}
b_cos :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				Cosine of angle in degrees
				cos(angle)
				$ angle :: float
				Usage: cos(90)=>>0<<`


	if len(args) != 1 {
		return e->eval_new_error(
				"'cos' function error: wrong number of arguments, wants='1', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	angle, ok := args[0].(f64)
	if !ok {
		return e->eval_new_error(
				"'cos' function error: not supported for argument of type '%v'.%s",
				ObjectType(args[0]),
				usage,
			),
			false
	}
	return math.cos(angle), true
}
b_tan :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				Tangent of angle in degrees
				tan(angle)
				$ angle :: float
				Usage: tan(90)=>>1<<`


	if len(args) != 1 {
		return e->eval_new_error(
				"'tan' function error: wrong number of arguments, wants='1', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	angle, ok := args[0].(f64)
	if !ok {
		return e->eval_new_error(
				"'tan' function error: not supported for argument of type '%v'.%s",
				ObjectType(args[0]),
				usage,
			),
			false
	}
	return math.tan(angle), true
}


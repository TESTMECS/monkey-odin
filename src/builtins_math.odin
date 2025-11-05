package monkey

import "core:math/rand"

b_abs :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Get absolute value of int">>
				abs(value)
				$ value :: int
				Usage: abs(-1)=>>1<<`


	if len(args) != 1 {
		return eval_new_error(
				e,
				"'abs' function error: wrong number of arguments, wants='1', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}

	value, ok := args[0].(int)
	if !ok {
		return eval_new_error(
				e,
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
		return eval_new_error(
				e,
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
		return eval_new_error(
				e,
				"'choose' function error: wrong number of arguments, wants='1', got='%d'",
				len(args),
			),
			false
	}

	arr, ok := args[0].(ObjectArray)
	if !ok {
		return eval_new_error(
				e,
				"'choose' function error: not supported for argument of type '%v'",
				ObjectType(args[0]),
			),
			false
	}

	if len(arr) == 0 {
		return eval_new_error(e, "'choose' function error: cannot choose from empty array"), false
	}

	return arr[int(rand.int31()) % len(arr)], true
}


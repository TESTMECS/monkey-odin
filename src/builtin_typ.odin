package monkey
import "core:fmt"
import "core:strconv"
import "core:strings"
b_str :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Convert obj to str">>
				str(value)
				$ str | int
				Usage: str(1)=>>"1"<<`


	if len(args) != 1 {
		return eval_new_error(
				e,
				"'str' function error: wrong number of arguments, wants='1', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	strings.builder_reset(&e.sb)
	ObjectInspect(args[0], &e.sb)
	return strings.to_string(e.sb), true
}

b_arr :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Convert str to arr">>
				arr(value)
				$ arr | str
				Usage: arr(1)=>>[1]<<`


	if len(args) != 1 {
		return eval_new_error(
				e,
				"'arr' function error: wrong number of arguments, wants='1', got='%d'",
				len(args),
			),
			false
	}
	str_arg, ok := args[0].(string)
	if !ok {
		return eval_new_error(
				e,
				"'arr' function error: not supported for argument of type '%v'",
				ObjectType(args[0]),
			),
			false
	}
	arr_arg := strings.split(str_arg, ",")
	make_arr := make([dynamic]ObjectBase, len(arr_arg), e.varena)
	for value, idx in arr_arg {
		make_arr[idx] = value
	}
	return ObjectArray(make_arr), true
}

b_int :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Convert value to int">>
				int(value)
				$ str | int
				Usage: int(1)=>>1<<`


	if len(args) != 1 {
		return eval_new_error(
				e,
				"'int' function error: wrong number of arguments, wants='1', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	#partial switch arg in args[0] {
	case string:
		value, ok := strconv.parse_int(arg)
		if !ok {
			return eval_new_error(
					e,
					"'int' function error: cannot convert '%s' to int.%s",
					arg,
					usage,
				),
				false
		}
		return value, true
	case int:
		return arg, true
	}
	return eval_new_error(
			e,
			"'int' function error: not supported for argument of type '%v'.%s",
			ObjectType(args[0]),
			usage,
		),
		false
}

b_bool :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Convert value to bool">>
				bool(value)
				$ str | int
				Usage: bool(1)=>>true
				true: "1", "True", "true", "t", "T"
				false: "0", "False", "false", "f", "F"<<
				`


	if len(args) != 1 {
		return eval_new_error(
				e,
				"'bool' function error: wrong number of arguments, wants='1', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	#partial switch arg in args[0] {
	case string:
		value, ok := strconv.parse_bool(arg)
		if !ok {
			return eval_new_error(
					e,
					"'bool' function error: cannot convert '%s' to bool.%s",
					arg,
					usage,
				),
				false
		}
		return value, true
	case int:
		return arg != 0, true
	}
	return eval_new_error(
			e,
			"'bool' function error: not supported for argument of type '%v'.%s",
			ObjectType(args[0]),
			usage,
		),
		false
}
b_float :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
						"Convert value to float">>
						float(value)
						$ str | int
						Usage: float(1)=>>1.0`


	if len(args) != 1 {
		return eval_new_error(
				e,
				"'float' function error: wrong number of arguments, wants='1', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	#partial switch arg in args[0] {
	case string:
		value, ok := strconv.parse_f64(arg)
		if !ok {
			return eval_new_error(
					e,
					"'float' function error: cannot convert '%s' to float.%s",
					arg,
					usage,
				),
				false
		}
		return value, true
	case int:
		return f64(arg), true
	case f64:
		return arg, true
	}
	return eval_new_error(
			e,
			"'float' function error: not supported for argument of type '%v'.%s",
			ObjectType(args[0]),
			usage,
		),
		false
}
b_typeof :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Get type of obj">>
				typeof(obj)
				$ obj :: obj of int, str, float, any
				Usage: typeof(1)=>>int<<`


	if len(args) != 1 {
		return eval_new_error(
				e,
				"'typeof' function error: wrong number of arguments, wants='1', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	type_str := strings.clone(fmt.tprintf("%v", ObjectType(args[0])), e.varena)
	return type_str, true
}


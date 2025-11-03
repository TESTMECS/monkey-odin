package monkey

import "core:fmt"
import "core:mem/virtual"
import "core:strconv"
import "core:strings"

find_builtin_fn :: proc(name: string) -> ObjectBuilinFunction {
	switch name {
	case "len":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 1 {
					return eval_new_error(
							e,
							"'len' function error: wrong number of arguments, wants='1', got='%d'",
							len(args),
						),
						false
				}

				#partial switch arg in args[0] {
				case string:
					return len(arg), true

				case ObjectArray:
					return len(arg), true
				}

				return eval_new_error(
						e,
						"'len' function error: not supported for argument of type '%v'",
						ObjectType(args[0]),
					),
					false
			}

	case "first":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 1 {
					return eval_new_error(
							e,
							"'first' function error: wrong number of arguments, wants='1', got='%d'",
							len(args),
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return eval_new_error(
							e,
							"'first' function error: not supported for argument of type '%v'",
							ObjectType(args[0]),
						),
						false
				}

				if len(arr) > 0 do return arr[0], true

				return NULL, true
			}

	case "last":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 1 {
					return eval_new_error(
							e,
							"'last' function error: wrong number of arguments, wants='1', got='%d'",
							len(args),
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return eval_new_error(
							e,
							"'last' function error: not supported for argument of type '%v'",
							ObjectType(args[0]),
						),
						false
				}

				if len(arr) > 0 do return arr[len(arr) - 1], true

				return NULL, true
			}

	case "rest":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 1 {
					return eval_new_error(
							e,
							"'rest' function error: wrong number of arguments, wants='1', got='%d'",
							len(args),
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return eval_new_error(
							e,
							"'rest' function error: not supported for argument of type '%v'",
							ObjectType(args[0]),
						),
						false
				}

				if len(arr) > 0 {
					varena := virtual.arena_allocator(e.vmem)
					new_arr := make([dynamic]ObjectBase, 0, varena)
					append(&new_arr, ..arr[1:])
					arr_obj := ObjectArray(new_arr)

					return arr_obj, true
				}

				return NULL, true
			}

	case "push":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 2 {
					return eval_new_error(
							e,
							"'push' function error: wrong number of arguments, wants='2', got='%d'",
							len(args),
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return eval_new_error(
							e,
							"'push' function error: not supported for argument of type '%v'",
							ObjectType(args[0]),
						),
						false
				}

				append(&arr, args[1])

				return NULL, true
			}

	case "puts":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				strings.builder_reset(&e.sb)

				for arg in args {
					ObjectInspect(arg, &e.sb)
					fmt.sbprintln(&e.sb)
				}

				fmt.print(strings.to_string(e.sb))

				return NULL, true
			}

	case "int":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 1 {
					return eval_new_error(
							e,
							"'int' function error: wrong number of arguments, wants='1', got='%d'",
							len(args),
						),
						false
				}

				#partial switch arg in args[0] {
				case string:
					value, ok := strconv.parse_int(arg)
					if !ok {
						return eval_new_error(
								e,
								"'int' function error: cannot convert '%s' to int",
								arg,
							),
							false
					}
					return value, true
				case int:
					return arg, true
				}

				return eval_new_error(
						e,
						"'int' function error: not supported for argument of type '%v'",
						ObjectType(args[0]),
					),
					false
			}

	case "str":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 1 {
					return eval_new_error(
							e,
							"'str' function error: wrong number of arguments, wants='1', got='%d'",
							len(args),
						),
						false
				}

				strings.builder_reset(&e.sb)
				ObjectInspect(args[0], &e.sb)
				varena := virtual.arena_allocator(e.vmem)
				return strings.to_string(e.sb), true
			}

	case "typeof":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 1 {
					return eval_new_error(
							e,
							"'typeof' function error: wrong number of arguments, wants='1', got='%d'",
							len(args),
						),
						false
				}

				varena := virtual.arena_allocator(e.vmem)
				type_str := strings.clone(fmt.tprintf("%v", ObjectType(args[0])), varena)
				return type_str, true
			}

	case "abs":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 1 {
					return eval_new_error(
							e,
							"'abs' function error: wrong number of arguments, wants='1', got='%d'",
							len(args),
						),
						false
				}

				value, ok := args[0].(int)
				if !ok {
					return eval_new_error(
							e,
							"'abs' function error: not supported for argument of type '%v'",
							ObjectType(args[0]),
						),
						false
				}

				if value < 0 do return -value, true
				return value, true
			}

	case "range":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) < 1 || len(args) > 3 {
					return eval_new_error(
							e,
							"'range' function error: wrong number of arguments, wants='1-3', got='%d'",
							len(args),
						),
						false
				}

				start, end, step := 0, 0, 1

				if len(args) == 1 {
					// range(end)
					end_val, ok := args[0].(int)
					if !ok {
						return eval_new_error(
								e,
								"'range' function error: end must be int, got '%v'",
								ObjectType(args[0]),
							),
							false
					}
					end = end_val
				} else if len(args) == 2 {
					// range(start, end)
					start_val, start_ok := args[0].(int)
					if !start_ok {
						return eval_new_error(
								e,
								"'range' function error: start must be int, got '%v'",
								ObjectType(args[0]),
							),
							false
					}
					end_val, end_ok := args[1].(int)
					if !end_ok {
						return eval_new_error(
								e,
								"'range' function error: end must be int, got '%v'",
								ObjectType(args[1]),
							),
							false
					}
					start, end = start_val, end_val
				} else {
					// range(start, end, step)
					start_val, start_ok := args[0].(int)
					if !start_ok {
						return eval_new_error(
								e,
								"'range' function error: start must be int, got '%v'",
								ObjectType(args[0]),
							),
							false
					}
					end_val, end_ok := args[1].(int)
					if !end_ok {
						return eval_new_error(
								e,
								"'range' function error: end must be int, got '%v'",
								ObjectType(args[1]),
							),
							false
					}
					step_val, step_ok := args[2].(int)
					if !step_ok {
						return eval_new_error(
								e,
								"'range' function error: step must be int, got '%v'",
								ObjectType(args[2]),
							),
							false
					}
					if step_val == 0 {
						return eval_new_error(e, "'range' function error: step cannot be zero"),
							false
					}
					start, end, step = start_val, end_val, step_val
				}

				varena := virtual.arena_allocator(e.vmem)
				result := make([dynamic]ObjectBase, 0, varena)

				if step > 0 {
					for i := start; i < end; i += step {
						append(&result, i)
					}
				} else {
					for i := start; i > end; i += step {
						append(&result, i)
					}
				}

				return ObjectArray(result), true
			}
	}

	return nil
}


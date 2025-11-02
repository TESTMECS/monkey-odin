package monkey

import "core:fmt"
import "core:strings"

find_builtin_fn :: proc(name: string) -> ObjectBuilinFunction {
	switch name {
	case "len":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 1 {
					return new_error(
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

				return new_error(
						e,
						"'len' function error: not supported for argument of type '%v'",
						ObjectType(args[0]),
					),
					false
			}

	case "first":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 1 {
					return new_error(
							e,
							"'first' function error: wrong number of arguments, wants='1', got='%d'",
							len(args),
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return new_error(
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
					return new_error(
							e,
							"'last' function error: wrong number of arguments, wants='1', got='%d'",
							len(args),
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return new_error(
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
					return new_error(
							e,
							"'rest' function error: wrong number of arguments, wants='1', got='%d'",
							len(args),
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return new_error(
							e,
							"'rest' function error: not supported for argument of type '%v'",
							ObjectType(args[0]),
						),
						false
				}

				if len(arr) > 0 {
					new_arr := VArena_Alloc(&e.vmem, ObjectArray)
					inject_at(new_arr, 0, ..arr[1:])

					return new_arr^, true
				}

				return NULL, true
			}

	case "push":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 2 {
					return new_error(
							e,
							"'push' function error: wrong number of arguments, wants='2', got='%d'",
							len(args),
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return new_error(
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
				strings.builder_reset(&e.vmem.string_builder)

				for arg in args {
					ObjectInspect(arg, &e.vmem.string_builder)
					fmt.sbprintln(&e.vmem.string_builder)
				}

				fmt.print(strings.to_string(e.vmem.string_builder))

				return NULL, true
			}
	}

	return nil
}


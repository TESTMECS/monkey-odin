package monkey

import "core:crypto/hash"
import "core:fmt"
import "core:mem/virtual"
import "core:strconv"
import "core:strings"

find_builtin_fn :: proc(name: string) -> ObjectBuilinFunction {
	switch name {
	case "hash":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				varena := virtual.arena_allocator(e.vmem)
				if len(args) != 1 {
					return eval_new_error(
							e,
							"'hash' function error: wrong number of arguments, wants='1', got='%d'",
							len(args),
						),
						false
				}

				#partial switch arg in args[0] {
				case string:
					s_copy := strings.clone(arg, varena)
					digest := hash.hash_string(hash.Algorithm.SHA256, s_copy)
					sb := strings.builder_make(varena)
					for b in digest {
						fmt.sbprintf(&sb, "%02x", b)
					}
					hex_str := strings.to_string(sb)
					return fmt.tprintfln("SHA-256(\"%s\") = %x", s_copy, hex_str), true
				}

				return eval_new_error(
						e,
						"'hash' function error: not supported for argument of type '%v'",
						ObjectType(args[0]),
					),
					false
			}

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

				return strings.to_string(e.sb), true
			}

	case "printf":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) < 2 {
					return eval_new_error(
							e,
							"'printf' function error: wrong number of arguments, wants=<<Greater than or equal to 2>>, got='%d'",
							len(args),
						),
						false
				}
				is_valid_format_string := proc(s: string) -> bool {
					for i := 0; i < len(s); i += 1 {
						if s[i] == '%' {
							if i + 1 >= len(s) {return false} 	// dangling '%'
							valid_specifiers := "sdxfv" // TODO: add more
							if !strings.contains(valid_specifiers, s[i + 1:]) {
								return false
							}
						}
					}
					return true
				}
				format_str, ok := args[0].(string)
				is_valid := is_valid_format_string(format_str)
				if !ok || !is_valid {
					return eval_new_error(
							e,
							"'printf' function error: first argument must be a valid format string, got '%v'",
							ObjectType(args[0]),
						),
						false
				}

				strings.builder_reset(&e.sb)
				fmt.sbprintf(&e.sb, format_str, args[1:])
				return strings.to_string(e.sb), true
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

	case "quote":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 1 {
					return eval_new_error(
							e,
							"'quote' function error: wrong number of arguments, wants='1', got='%d'",
							len(args),
						),
						false
				}

				// For quote, we need to convert the argument back to an AST node
				// This is a simplified implementation - in a real system, you'd need
				// to track the original AST nodes
				varena := virtual.arena_allocator(e.vmem)

				#partial switch arg in args[0] {
				case int:
					return arg, true
				case bool:
					return arg, true
				case string:
					return arg, true
				case ObjectCompiledFunction:
					return arg, true
				case ObjectHashTable:
					return arg, true
				case ObjectArray:
					return arg, true
				case ObjectQuote:
					return arg, true
				}

				return eval_new_error(
						e,
						"'quote' function error: cannot quote type '%v'",
						ObjectType(args[0]),
					),
					false
			}

	case "unquote":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 1 {
					return eval_new_error(
							e,
							"'unquote' function error: wrong number of arguments, wants='1', got='%d'",
							len(args),
						),
						false
				}

				// For unquote, we just return the argument as-is
				// In a real implementation, this would be handled during macro expansion
				return args[0], true
			}

	case "keys":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 1 {
					return eval_new_error(
							e,
							"'keys' function error: wrong number of arguments, wants='1', got='%d'",
							len(args),
						),
						false
				}

				hash_table, ok := args[0].(ObjectHashTable)
				if !ok {
					return eval_new_error(
							e,
							"'keys' function error: not supported for argument of type '%v'",
							ObjectType(args[0]),
						),
						false
				}

				varena := virtual.arena_allocator(e.vmem)
				keys_arr := make([dynamic]ObjectBase, 0, varena)

				for key, _ in hash_table {
					append(&keys_arr, key)
				}

				return ObjectArray(keys_arr), true
			}

	case "values":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 1 {
					return eval_new_error(
							e,
							"'values' function error: wrong number of arguments, wants='1', got='%d'",
							len(args),
						),
						false
				}

				hash_table, ok := args[0].(ObjectHashTable)
				if !ok {
					return eval_new_error(
							e,
							"'values' function error: not supported for argument of type '%v'",
							ObjectType(args[0]),
						),
						false
				}

				varena := virtual.arena_allocator(e.vmem)
				values_arr := make([dynamic]ObjectBase, 0, varena)

				for _, value in hash_table {
					append(&values_arr, value)
				}

				return ObjectArray(values_arr), true
			}

	case "has":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 2 {
					return eval_new_error(
							e,
							"'has' function error: wrong number of arguments, wants='2', got='%d'",
							len(args),
						),
						false
				}

				hash_table, ok := args[0].(ObjectHashTable)
				if !ok {
					return eval_new_error(
							e,
							"'has' function error: first argument must be hash table, got '%v'",
							ObjectType(args[0]),
						),
						false
				}

				key_str, key_ok := args[1].(string)
				if !key_ok {
					return eval_new_error(
							e,
							"'has' function error: hash table keys must be strings, got '%v'",
							ObjectType(args[1]),
						),
						false
				}

				_, exists := hash_table[key_str]
				return exists, true
			}
	}

	return nil
}


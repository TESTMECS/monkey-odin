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

	case "sort":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 1 {
					return eval_new_error(
							e,
							"'sort' function error: wrong number of arguments, wants='1', got='%d'",
							len(args),
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return eval_new_error(
							e,
							"'sort' function error: not supported for argument of type '%v'",
							ObjectType(args[0]),
						),
						false
				}

				// Check if all elements are integers
				for elem in arr {
					_, ok := elem.(int)
					if !ok {
						return eval_new_error(
								e,
								"'sort' function error: all elements must be integers, got '%v'",
								ObjectType(elem),
							),
							false
					}
				}

				varena := virtual.arena_allocator(e.vmem)
				sorted_arr := make([dynamic]ObjectBase, len(arr), varena)
				copy(sorted_arr[:], arr[:])

				// Simple bubble sort for integers
				for i := 0; i < len(sorted_arr); i += 1 {
					for j := 0; j < len(sorted_arr) - i - 1; j += 1 {
						a, _ := sorted_arr[j].(int)
						b, _ := sorted_arr[j + 1].(int)
						if a > b {
							sorted_arr[j], sorted_arr[j + 1] = sorted_arr[j + 1], sorted_arr[j]
						}
					}
				}

				return ObjectArray(sorted_arr), true
			}

	case "reverse":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 1 {
					return eval_new_error(
							e,
							"'reverse' function error: wrong number of arguments, wants='1', got='%d'",
							len(args),
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return eval_new_error(
							e,
							"'reverse' function error: not supported for argument of type '%v'",
							ObjectType(args[0]),
						),
						false
				}

				varena := virtual.arena_allocator(e.vmem)
				reversed_arr := make([dynamic]ObjectBase, len(arr), varena)
				
				arr_len := len(arr)
				for i in 0..<arr_len {
					reversed_arr[arr_len - 1 - i] = arr[i]
				}

				return ObjectArray(reversed_arr), true
			}

	case "slice":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 3 {
					return eval_new_error(
							e,
							"'slice' function error: wrong number of arguments, wants='3', got='%d'",
							len(args),
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return eval_new_error(
							e,
							"'slice' function error: first argument must be array, got '%v'",
							ObjectType(args[0]),
						),
						false
				}

				start, start_ok := args[1].(int)
				if !start_ok {
					return eval_new_error(
							e,
							"'slice' function error: start index must be integer, got '%v'",
							ObjectType(args[1]),
						),
						false
				}

				end, end_ok := args[2].(int)
				if !end_ok {
					return eval_new_error(
							e,
							"'slice' function error: end index must be integer, got '%v'",
							ObjectType(args[2]),
						),
						false
				}

				if start < 0 || end > len(arr) || start > end {
					return eval_new_error(
							e,
							"'slice' function error: invalid slice range [%d, %d] for array of length %d",
							start, end, len(arr),
						),
						false
				}

				varena := virtual.arena_allocator(e.vmem)
				sliced_arr := make([dynamic]ObjectBase, 0, varena)
				append(&sliced_arr, ..arr[start:end])

				return ObjectArray(sliced_arr), true
			}

	case "indexOf":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 2 {
					return eval_new_error(
							e,
							"'indexOf' function error: wrong number of arguments, wants='2', got='%d'",
							len(args),
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return eval_new_error(
							e,
							"'indexOf' function error: first argument must be array, got '%v'",
							ObjectType(args[0]),
						),
						false
				}

				target := args[1]
				for i in 0..<len(arr) {
					elem := arr[i]
					
					// Check if types match first
					if ObjectType(elem) != ObjectType(target) {
						continue
					}
					
					// Now compare based on the common type
					#partial switch elem_val in elem {
					case int:
						#partial switch target_val in target {
						case int:
							if elem_val == target_val {
								return i, true
							}
						}
					case string:
						#partial switch target_val in target {
						case string:
							if elem_val == target_val {
								return i, true
							}
						}
					case bool:
						#partial switch target_val in target {
						case bool:
							if elem_val == target_val {
								return i, true
							}
						}
					}
				}

				return -1, true
			}

	case "sum":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 1 {
					return eval_new_error(
							e,
							"'sum' function error: wrong number of arguments, wants='1', got='%d'",
							len(args),
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return eval_new_error(
							e,
							"'sum' function error: not supported for argument of type '%v'",
							ObjectType(args[0]),
						),
						false
				}

				sum := 0
				for elem in arr {
					value, ok := elem.(int)
					if !ok {
						return eval_new_error(
								e,
								"'sum' function error: all elements must be integers, got '%v'",
								ObjectType(elem),
							),
							false
					}
					sum += value
				}

				return sum, true
			}

	case "min":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 1 {
					return eval_new_error(
							e,
							"'min' function error: wrong number of arguments, wants='1', got='%d'",
							len(args),
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return eval_new_error(
							e,
							"'min' function error: not supported for argument of type '%v'",
							ObjectType(args[0]),
						),
						false
				}

				if len(arr) == 0 {
					return eval_new_error(
							e,
							"'min' function error: cannot find minimum of empty array",
						),
						false
				}

				// Check if all elements are integers
				for elem in arr {
					_, ok := elem.(int)
					if !ok {
						return eval_new_error(
								e,
								"'min' function error: all elements must be integers, got '%v'",
								ObjectType(elem),
							),
							false
					}
				}

				min_val, _ := arr[0].(int)
				for i := 1; i < len(arr); i += 1 {
					value, _ := arr[i].(int)
					if value < min_val {
						min_val = value
					}
				}

				return min_val, true
			}

	case "max":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 1 {
					return eval_new_error(
							e,
							"'max' function error: wrong number of arguments, wants='1', got='%d'",
							len(args),
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return eval_new_error(
							e,
							"'max' function error: not supported for argument of type '%v'",
							ObjectType(args[0]),
						),
						false
				}

				if len(arr) == 0 {
					return eval_new_error(
							e,
							"'max' function error: cannot find maximum of empty array",
						),
						false
				}

				// Check if all elements are integers
				for elem in arr {
					_, ok := elem.(int)
					if !ok {
						return eval_new_error(
								e,
								"'max' function error: all elements must be integers, got '%v'",
								ObjectType(elem),
							),
							false
					}
				}

				max_val, _ := arr[0].(int)
				for i := 1; i < len(arr); i += 1 {
					value, _ := arr[i].(int)
					if value > max_val {
						max_val = value
					}
				}

				return max_val, true
			}
	}

	return nil
}


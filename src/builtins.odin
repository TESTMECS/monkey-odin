package monkey

import "base:runtime"
import "core:crypto/hash"
import "core:fmt"
import "core:math/rand"
import "core:strconv"
import "core:strings"

find_builtin_fn :: proc(name: string) -> ObjectBuilinFunction {
	switch name {
	case "bool":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
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
	case "float":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
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
				}

				return eval_new_error(
						e,
						"'float' function error: not supported for argument of type '%v'.%s",
						ObjectType(args[0]),
						usage,
					),
					false
			}
	case "choose":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
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
					return eval_new_error(
							e,
							"'choose' function error: cannot choose from empty array",
						),
						false
				}

				return arr[int(rand.int31()) % len(arr)], true
			}
	case "rand":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
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

	case "hash":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				usage := `
				"Hash a string">>
				hash(str)
				$ str
				Usage: hash("monkey")=>>123456789<<
				`


				if len(args) != 1 {
					return eval_new_error(
							e,
							"'hash' function error: wrong number of arguments, wants='1', got='%d'.%s",
							len(args),
							usage,
						),
						false
				}

				#partial switch arg in args[0] {
				case string:
					s_copy := strings.clone(arg, e.varena)
					digest := hash.hash_string(hash.Algorithm.SHA256, s_copy)
					sb := strings.builder_make(e.varena)
					for b in digest {
						fmt.sbprintf(&sb, "%02x", b)
					}
					hex_str := strings.to_string(sb)
					return fmt.tprintfln("SHA-256(\"%s\") = %x", s_copy, hex_str), true
				}

				return eval_new_error(
						e,
						"'hash' function error: not supported for argument of type '%v'.%s",
						ObjectType(args[0]),
						usage,
					),
					false
			}

	case "len":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				usage := `
				"Get length of array">>
				len(arr)
				$ arr :: int, int
				Usage: len([1,2,3])=>>3<<`


				if len(args) != 1 {
					return eval_new_error(
							e,
							"'len' function error: wrong number of arguments, wants='1', got='%d'.%s",
							len(args),
							usage,
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
						"'len' function error: not supported for argument of type '%v'.%s",
						ObjectType(args[0]),
						usage,
					),
					false
			}

	case "first":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				usage := `
				"Get first element of array">>
				first(arr)
				$ arr :: int, int
				Usage: first([1,2,3])=>>1<<`


				if len(args) != 1 {
					return eval_new_error(
							e,
							"'first' function error: wrong number of arguments, wants='1', got='%d'.%s",
							len(args),
							usage,
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return eval_new_error(
							e,
							"'first' function error: not supported for argument of type '%v'.%s",
							ObjectType(args[0]),
							usage,
						),
						false
				}

				if len(arr) > 0 do return arr[0], true

				return NULL, true
			}

	case "last":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				usage := `
				"Get last element of array">>
				last(arr)
				$ arr :: int, int
				Usage: last([1,2,3])=>>3<<`


				if len(args) != 1 {
					return eval_new_error(
							e,
							"'last' function error: wrong number of arguments, wants='1', got='%d'.%s",
							len(args),
							usage,
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return eval_new_error(
							e,
							"'last' function error: not supported for argument of type '%v'.%s",
							ObjectType(args[0]),
							usage,
						),
						false
				}

				if len(arr) > 0 do return arr[len(arr) - 1], true

				return NULL, true
			}

	case "rest":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				usage := `
				"Get all but first element of array">>
				rest(arr)
				$ arr :: int, int
				Usage: rest([1,2,3])=>>[2,3]<<`


				if len(args) != 1 {
					return eval_new_error(
							e,
							"'rest' function error: wrong number of arguments, wants='1', got='%d'.%s",
							len(args),
							usage,
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return eval_new_error(
							e,
							"'rest' function error: not supported for argument of type '%v'.%s",
							ObjectType(args[0]),
							usage,
						),
						false
				}

				if len(arr) > 0 {
					new_arr := make([dynamic]ObjectBase, 0, e.varena)
					append(&new_arr, ..arr[1:])
					arr_obj := ObjectArray(new_arr)

					return arr_obj, true
				}

				return NULL, true
			}

	case "push":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				usage := `
				"Push element to array">>
				push(arr, elem)
				$ arr :: int, int
				Usage: push([1,2,3], 4)=>>[1,2,3,4]<<`


				if len(args) != 2 {
					return eval_new_error(
							e,
							"'push' function error: wrong number of arguments, wants='2', got='%d'.%s",
							len(args),
							usage,
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return eval_new_error(
							e,
							"'push' function error: not supported for argument of type '%v'.%s",
							ObjectType(args[0]),
							usage,
						),
						false
				}

				append(&arr, args[1])

				return NULL, true
			}

	case "puts":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				usage := `
				"Print obj">>
				puts(arr)
				$ arr :: obj   
				Usage: puts([1,2,3])=>>[1,2,3]<<`


				strings.builder_reset(&e.sb)

				for arg in args {
					ObjectInspect(arg, &e.sb)
					fmt.sbprintln(&e.sb)
				}
				dbg(strings.to_string(e.sb)) // also print for multiple statements.

				return strings.to_string(e.sb), true
			}

	case "printf":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				usage := `
				"Print obj">>
				printf(format, obj)
				$ format :: str of "%d", "%s", "%f", "%v"
				$ obj :: obj of int, str, float, any
				Usage: printf("%d", 1)=>>1<<`


				if len(args) < 1 {
					return eval_new_error(
							e,
							"'printf' function error: wrong number of arguments, wants=<<Greater than or equal to 1>>, got='%d'.%s",
							len(args),
							usage,
						),
						false
				}
				format_str, ok := args[0].(string)
				if !ok {
					return eval_new_error(
							e,
							"'printf' function error: first argument must be a valid format string, got '%v'.%s",
							ObjectType(args[0]),
							usage,
						),
						false
				}
				strings.builder_reset(&e.sb)

				// Count format specifiers to validate argument count
				specifier_count := 0
				for i := 0; i < len(format_str); i += 1 {
					if format_str[i] == '%' {
						if i + 1 >= len(format_str) {break} 	// dangling '%'
						if format_str[i + 1] != '%' {
							specifier_count += 1
						} else {
							i += 1 // skip escaped %%
						}
					}
				}

				if specifier_count != len(args) - 1 {
					return eval_new_error(
							e,
							"'printf' function error: format string expects %d arguments, got %d.%s",
							specifier_count,
							len(args) - 1,
							usage,
						),
						false
				}

				// Convert arguments to any type for fmt.sbprintf
				fmt_args := make([]any, len(args) - 1, e.varena)
				for i in 1 ..< len(args) {
					fmt_args[i - 1] = args[i]
				}

				fmt.sbprintf(&e.sb, format_str, ..fmt_args)
				// print and return
				fmt.println(strings.to_string(e.sb))
				return strings.to_string(e.sb), true
			}
	case "int":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
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

	case "str":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
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

	case "typeof":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
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

	case "abs":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
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

	case "quote":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				usage := `
				"Quote obj">>
				quote(obj)
				$ obj :: obj of int, str, float, any
				Usage: quote(1)=>>1<<`


				if len(args) != 1 {
					return eval_new_error(
							e,
							"'quote' function error: wrong number of arguments, wants='1', got='%d'.%s",
							len(args),
							usage,
						),
						false
				}

				// For quote, we need to convert the argument back to an AST node
				// This is a simplified implementation - in a real system, you'd need
				// to track the original AST nodes
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
						"'quote' function error: cannot quote type '%v'.%s",
						ObjectType(args[0]),
						usage,
					),
					false
			}

	case "unquote":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				usage := `
				"Unquote obj">>
				unquote(obj)
				$ obj :: obj of int, str, float, any
				Usage: unquote(1)=>>1<<`


				if len(args) != 1 do return eval_new_error(e, "'unquote' function error: wrong number of arguments, wants='1', got='%d'.%s", len(args), usage), false

				return args[0], true
			}

	case "keys":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				usage := `
				"Get keys of hash table">>
				keys(hash_table)
				$ hash_table :: hash_table of str, int
				Usage: keys({"a": 1, "b": 2})=>>["a", "b"]<<`


				if len(args) != 1 {
					return eval_new_error(
							e,
							"'keys' function error: wrong number of arguments, wants='1', got='%d'.%s",
							len(args),
							usage,
						),
						false
				}

				hash_table, ok := args[0].(ObjectHashTable)
				if !ok {
					return eval_new_error(
							e,
							"'keys' function error: not supported for argument of type '%v'.%s",
							ObjectType(args[0]),
							usage,
						),
						false
				}

				keys_arr := make([dynamic]ObjectBase, 0, e.varena)

				for key, _ in hash_table {
					append(&keys_arr, key)
				}

				return ObjectArray(keys_arr), true
			}

	case "values":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				usage := `
				"Get values of hash table">>
				values(hash_table)
				$ hash_table :: hash_table of str, int
				Usage: values({"a": 1, "b": 2})=>>[1, 2]<<`


				if len(args) != 1 {
					return eval_new_error(
							e,
							"'values' function error: wrong number of arguments, wants='1', got='%d'.%s",
							len(args),
							usage,
						),
						false
				}

				hash_table, ok := args[0].(ObjectHashTable)
				if !ok {
					return eval_new_error(
							e,
							"'values' function error: not supported for argument of type '%v'.%s",
							ObjectType(args[0]),
							usage,
						),
						false
				}

				values_arr := make([dynamic]ObjectBase, 0, e.varena)

				for _, value in hash_table {
					append(&values_arr, value)
				}

				return ObjectArray(values_arr), true
			}

	case "has":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				usage := `
				"Check if hash table has key">>
				has(hash_table, key)
				$ hash_table :: hash_table of str, int
				$ key :: str
				Usage: has({"a": 1, "b": 2}, "a")=>>true<<`


				if len(args) != 2 {
					return eval_new_error(
							e,
							"'has' function error: wrong number of arguments, wants='2', got='%d'.%s",
							len(args),
							usage,
						),
						false
				}

				hash_table, ok := args[0].(ObjectHashTable)
				if !ok {
					return eval_new_error(
							e,
							"'has' function error: first argument must be hash table, got '%v'.%s",
							ObjectType(args[0]),
							usage,
						),
						false
				}

				key_str, key_ok := args[1].(string)
				if !key_ok {
					return eval_new_error(
							e,
							"'has' function error: hash table keys must be strings, got '%v'.%s",
							ObjectType(args[1]),
							usage,
						),
						false
				}

				_, exists := hash_table[key_str]
				return exists, true
			}

	case "sort":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				usage := `
				"Sort arr">>
				sort(arr)
				$ arr :: int, int
				Usage: sort([3,2,1])=>>[1,2,3]<<`


				if len(args) != 1 {
					return eval_new_error(
							e,
							"'sort' function error: wrong number of arguments, wants='1', got='%d'.%s",
							len(args),
							usage,
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return eval_new_error(
							e,
							"'sort' function error: not supported for argument of type '%v'.%s",
							ObjectType(args[0]),
							usage,
						),
						false
				}

				// Check if all elements are integers
				for elem in arr {
					_, ok := elem.(int)
					if !ok {
						return eval_new_error(
								e,
								"'sort' function error: all elements must be integers, got '%v'.%s",
								ObjectType(elem),
								usage,
							),
							false
					}
				}

				sorted_arr := make([dynamic]ObjectBase, len(arr), e.varena)
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
				usage := `
				"Reverse arr">>
				reverse(arr)
				$ arr :: int, int
				Usage: reverse([1,2,3])=>>[3,2,1]<<`


				if len(args) != 1 {
					return eval_new_error(
							e,
							"'reverse' function error: wrong number of arguments, wants='1', got='%d'.%s",
							len(args),
							usage,
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return eval_new_error(
							e,
							"'reverse' function error: not supported for argument of type '%v'.%s",
							ObjectType(args[0]),
							usage,
						),
						false
				}

				reversed_arr := make([dynamic]ObjectBase, len(arr), e.varena)

				arr_len := len(arr)
				for i in 0 ..< arr_len {
					reversed_arr[arr_len - 1 - i] = arr[i]
				}

				return ObjectArray(reversed_arr), true
			}
	case "arr":
		// str to arr
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
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
	case "slice":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				usage := `
				Get a arr slice from array>>
				slice(arr, start, end)
				$ arr :: int, int
				Usage: arr([1,2,3],0,1)=>>[1]<<
				`


				if len(args) != 3 {
					return eval_new_error(
							e,
							"function error: wrong number of arguments, wants='3', got='%d'.%s",
							len(args),
							usage,
						),
						false
				}

				arr, ok := args[0].(ObjectArray)
				if !ok {
					return eval_new_error(
							e,
							"'slice' function error: first argument must be array, got '%v'.%s",
							ObjectType(args[0]),
							usage,
						),
						false
				}

				start, start_ok := args[1].(int)
				if !start_ok {
					return eval_new_error(
							e,
							"'slice' function error: start index must be integer, got '%v'.%s",
							ObjectType(args[1]),
							usage,
						),
						false
				}

				end, end_ok := args[2].(int)
				if !end_ok {
					return eval_new_error(
							e,
							"'slice' function error: end index must be integer, got '%v'.%s",
							ObjectType(args[2]),
							usage,
						),
						false
				}

				if start < 0 || end > len(arr) || start > end {
					return eval_new_error(
							e,
							"'slice' function error: invalid slice range [%d, %d] for array of length %d.%s",
							start,
							end,
							len(arr),
							usage,
						),
						false
				}

				sliced_arr := make([dynamic]ObjectBase, 0, e.varena)
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
				for i in 0 ..< len(arr) {
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

	case "args":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
				if len(args) != 0 {
					return eval_new_error(
							e,
							"'args' function error: wrong number of arguments, wants='0', got='%d'",
							len(args),
						),
						false
				}

				args_array := make([dynamic]ObjectBase, 0, e.varena)
				for arg in e.args {
					arg_clone := strings.clone(arg, e.varena)
					append(&args_array, arg_clone)
				}

				return ObjectArray(args_array), true
			}
	}

	return nil
}


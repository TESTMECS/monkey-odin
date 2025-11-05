package monkey
import "core:crypto/hash"
import "core:fmt"
import "core:strings"

b_hash :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
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

b_upper :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Convert string to uppercase">>
				upper(str)
				$ str
				Usage: upper("hello")=>>"HELLO"<<`

	if len(args) != 1 {
		return eval_new_error(
				e,
				"'upper' function error: wrong number of arguments, wants='1', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}

	#partial switch arg in args[0] {
	case string:
		return strings.upper(arg), true
	}

	return eval_new_error(
			e,
			"'upper' function error: not supported for argument of type '%v'.%s",
			ObjectType(args[0]),
			usage,
		),
		false
}

b_lower :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Convert string to lowercase">>
				lower(str)
				$ str
				Usage: lower("HELLO")=>>"hello"<<`

	if len(args) != 1 {
		return eval_new_error(
				e,
				"'lower' function error: wrong number of arguments, wants='1', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}

	#partial switch arg in args[0] {
	case string:
		return strings.lower(arg), true
	}

	return eval_new_error(
			e,
			"'lower' function error: not supported for argument of type '%v'.%s",
			ObjectType(args[0]),
			usage,
		),
		false
}

b_split :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Split string by delimiter">>
				split(str, delimiter)
				$ str
				$ delimiter :: str
				Usage: split("a,b,c", ",")=>>["a", "b", "c"]<<`

	if len(args) != 2 {
		return eval_new_error(
				e,
				"'split' function error: wrong number of arguments, wants='2', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}

	str, str_ok := args[0].(string)
	if !str_ok {
		return eval_new_error(
				e,
				"'split' function error: first argument must be string, got '%v'.%s",
				ObjectType(args[0]),
				usage,
			),
			false
	}

	delimiter, delim_ok := args[1].(string)
	if !delim_ok {
		return eval_new_error(
				e,
				"'split' function error: second argument must be string, got '%v'.%s",
				ObjectType(args[1]),
				usage,
			),
			false
	}

	parts := strings.split(str, delimiter)
	result := make([dynamic]ObjectBase, len(parts), e.varena)
	for part in parts {
		append(&result, part)
	}

	return ObjectArray(result), true
}

b_join :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Join array of strings with delimiter">>
				join(arr, delimiter)
				$ arr :: array of str
				$ delimiter :: str
				Usage: join(["a", "b", "c"], ",")=>>"a,b,c"<<`

	if len(args) != 2 {
		return eval_new_error(
				e,
				"'join' function error: wrong number of arguments, wants='2', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}

	arr, arr_ok := args[0].(ObjectArray)
	if !arr_ok {
		return eval_new_error(
				e,
				"'join' function error: first argument must be array, got '%v'.%s",
				ObjectType(args[0]),
				usage,
			),
			false
	}

	delimiter, delim_ok := args[1].(string)
	if !delim_ok {
		return eval_new_error(
				e,
				"'join' function error: second argument must be string, got '%v'.%s",
				ObjectType(args[1]),
				usage,
			),
			false
	}

	str_parts := make([]string, len(arr), e.varena)
	for i, item in arr {
		str, ok := item.(string)
		if !ok {
			return eval_new_error(
					e,
					"'join' function error: array elements must be strings, got '%v' at index %d.%s",
					ObjectType(item),
					i,
					usage,
				),
				false
		}
		str_parts[i] = str
	}

	return strings.join(str_parts, delimiter), true
}


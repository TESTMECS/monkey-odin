package monkey
import "core:crypto/hash"
import "core:fmt"
import "core:strings"
import r "core:text/regex"
/*
* Copyright (C) 2025 TESTMEE
* ./builtins_str.odin
* This file defines the builtin string functions for monkey-odin::
* |b_hash|b_join|b_split|b_lower|b_upper|b_match|b_replace|b_contains|
*/
b_hash :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Hash a string">>
				hash(str)
				$ str
				Usage: hash("monkey")=>>123456789<<
				`


	if len(args) != 1 {
		return e->eval_new_error(
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
	return e->eval_new_error(
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
		return e->eval_new_error(
				"'upper' function error: wrong number of arguments, wants='1', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	#partial switch arg in args[0] {
	case string:
		return strings.to_upper(arg), true
	}
	return e->eval_new_error(
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
		return e->eval_new_error(
				"'lower' function error: wrong number of arguments, wants='1', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	#partial switch arg in args[0] {
	case string:
		return strings.to_lower(arg), true
	}
	return e->eval_new_error(
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
		return e->eval_new_error(
				"'split' function error: wrong number of arguments, wants='2', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	str, str_ok := args[0].(string)
	if !str_ok {
		return e->eval_new_error(
				"'split' function error: first argument must be string, got '%v'.%s",
				ObjectType(args[0]),
				usage,
			),
			false
	}
	delimiter, delim_ok := args[1].(string)
	if !delim_ok {
		return e->eval_new_error(
				"'split' function error: second argument must be string, got '%v'.%s",
				ObjectType(args[1]),
				usage,
			),
			false
	}
	parts := strings.split(str, delimiter)
	result := make([dynamic]ObjectBase, 0, e.varena)
	for part in parts {
		append(&result, ObjectBase(part))
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
		return e->eval_new_error(
				"'join' function error: wrong number of arguments, wants='2', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	arr, arr_ok := args[0].(ObjectArray)
	if !arr_ok {
		return e->eval_new_error(
				"'join' function error: first argument must be array, got '%v'.%s",
				ObjectType(args[0]),
				usage,
			),
			false
	}
	delimiter, delim_ok := args[1].(string)
	if !delim_ok {
		return e->eval_new_error(
				"'join' function error: second argument must be string, got '%v'.%s",
				ObjectType(args[1]),
				usage,
			),
			false
	}
	str_parts := make([]string, len(arr), e.varena)
	for i, item in arr {
		str, ok := i.(string)
		if !ok {
			return e->eval_new_error(
					"'join' function error: array elements must be strings, got '%v' at index %d.%s",
					ObjectType(i),
					i,
					usage,
				),
				false
		}
		str_parts[item] = str
	}
	return strings.join(str_parts, delimiter), true
}
b_match :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				Match string against regex, return array of groups captured >>
				match(str, regex)
				$ str 
				$ regex 
				Usage: match("hello monkey", "hello (.*)")=>>"monkey"<<`


	if len(args) != 2 {
		return e->eval_new_error(
				"'match' function error: wrong number of arguments, wants='2', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	str, str_ok := args[0].(string)
	if !str_ok {
		return e->eval_new_error(
				"'match' function error: first argument must be string, got '%v'.%s",
				ObjectType(args[0]),
				usage,
			),
			false
	}
	regex, regex_ok := args[1].(string)
	if !regex_ok {
		return e->eval_new_error(
				"'match' function error: second argument must be string, got '%v'.%s",
				ObjectType(args[1]),
				usage,
			),
			false
	}
	regex_c, err := r.create(regex)
	if err != nil do return e->eval_new_error("'match' function error: bad regex '%s'.%s", regex, usage), false
	c, ok := r.match_and_allocate_capture(regex_c, str)
	if !ok do return e->eval_new_error("'match' function error: cannot match string '%s' against regex '%s'.%s", str, regex, usage), false
	new_arr := make([dynamic]ObjectBase, 0, e.varena)
	for i in c.groups[1:] {
		append(&new_arr, ObjectBase(i))
	}
	return ObjectArray(new_arr), true
}
b_replace :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				Replace string with regex, return string >>
				replace(str, regex, replacement)
				$ str 
				$ regex 
				$ replacement 
				Usage: replace("hello monkey", "hello (.*)", "BANANAS")=>>"hello BANANAS"<<`


	if len(args) != 3 {
		return e->eval_new_error(
				"'replace' function error: wrong number of arguments, wants='3', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	str, str_ok := args[0].(string)
	if !str_ok {
		return e->eval_new_error(
				"'replace' function error: first argument must be string, got '%v'.%s",
				ObjectType(args[0]),
				usage,
			),
			false
	}
	regex, regex_ok := args[1].(string)
	if !regex_ok {
		return e->eval_new_error(
				"'replace' function error: second argument must be string, got '%v'.%s",
				ObjectType(args[1]),
				usage,
			),
			false
	}
	replacement, replacement_ok := args[2].(string)
	if !replacement_ok {
		return e->eval_new_error(
				"'replace' function error: third argument must be string, got '%v'.%s",
				ObjectType(args[2]),
				usage,
			),
			false
	}
	regex_c, err := r.create(regex)
	if err != nil do return e->eval_new_error("'replace' function error: bad regex '%s'.%s", regex, usage), false
	c, ok := r.match_and_allocate_capture(regex_c, str)
	if !ok do return e->eval_new_error("'replace' function error: cannot match string '%s' against regex '%s'.%s", str, regex, usage), false
	out, _ := strings.replace(str, c.groups[1], replacement, 1)
	if !ok do return e->eval_new_error("'replace' function error: cannot match string '%s' against regex '%s'.%s", str, regex, usage), false
	return out, true
}
b_contains :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Check if string contains substring">>
				contains(str, substring)
				$ str
				$ substring
				Usage: contains("hello monkey", "monkey")=>>true<<`


	if len(args) != 2 {
		return e->eval_new_error(
				"'contains' function error: wrong number of arguments, wants='2', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	str, str_ok := args[0].(string)
	if !str_ok {
		return e->eval_new_error(
				"'contains' function error: first argument must be string, got '%v'.%s",
				ObjectType(args[0]),
				usage,
			),
			false
	}
	substring, substring_ok := args[1].(string)
	if !substring_ok {
		return e->eval_new_error(
				"'contains' function error: second argument must be string, got '%v'.%s",
				ObjectType(args[1]),
				usage,
			),
			false
	}
	return strings.contains(str, substring), true
}


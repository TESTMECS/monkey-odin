package monkey
/*
* Copyright (C) 2025 TESTMEE
* ./builtins_map.odin
* This file defines the builtin map functions for monkey-odin.
* << b_keys, b_values, b_has, b_map >>
*/
b_keys :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
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
b_values :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
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
b_has :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
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
b_map :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Create hash table from two arrays">>
				map(keys, values)
				$ keys :: array of str
				$ values :: array of any
				Usage: map(["a", "b"], [1, 2])=>>{"a": 1, "b": 2}<<`


	if len(args) != 2 {
		return eval_new_error(
				e,
				"'map' function error: wrong number of arguments, wants='2', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	keys_arr, keys_ok := args[0].(ObjectArray)
	if !keys_ok {
		return eval_new_error(
				e,
				"'map' function error: first argument must be array, got '%v'.%s",
				ObjectType(args[0]),
				usage,
			),
			false
	}
	values_arr, values_ok := args[1].(ObjectArray)
	if !values_ok {
		return eval_new_error(
				e,
				"'map' function error: second argument must be array, got '%v'.%s",
				ObjectType(args[1]),
				usage,
			),
			false
	}
	if len(keys_arr) != len(values_arr) {
		return eval_new_error(
				e,
				"'map' function error: arrays must have same length, keys='%d', values='%d'.%s",
				len(keys_arr),
				len(values_arr),
				usage,
			),
			false
	}
	result := make(map[string]ObjectBase, e.varena)
	for i in 0 ..< len(keys_arr) {
		key_str, key_ok := keys_arr[i].(string)
		if !key_ok {
			return eval_new_error(
					e,
					"'map' function error: all keys must be strings, got '%v' at index %d.%s",
					ObjectType(keys_arr[i]),
					i,
					usage,
				),
				false
		}
		result[key_str] = values_arr[i]
	}
	return result, true
}


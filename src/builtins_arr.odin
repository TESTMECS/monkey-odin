package monkey
/*
* Copyright (C) 2025 TESTMEE
* ./builtins_arr.odin
* This file defines the builtin array functions for monkey-odin.
* << b_sort, b_reverse, b_slice, b_indexOf, b_sum, b_min, b_max, 
* b_len, b_range, b_first, b_last, b_rest, b_push, b_pop >>
*/
b_sort :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
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
b_reverse :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
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
b_slice :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
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
b_indexOf :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Get index of element in array">>
				indexOf(arr, elem)
				$ arr :: int, int
				$ elem :: int
				Usage: indexOf([1,2,3], 2)=>>1<<`


	if len(args) != 2 {
		return eval_new_error(
				e,
				"'indexOf' function error: wrong number of arguments, wants='2', got='%d'.%s",
				len(args),
			),
			false
	}
	arr, ok := args[0].(ObjectArray)
	if !ok {
		return eval_new_error(
				e,
				"'indexOf' function error: first argument must be array, got '%v'.%s",
				ObjectType(args[0]),
			),
			false
	}
	target := args[1]
	for i in 0 ..< len(arr) {
		elem := arr[i]
		if ObjectType(elem) != ObjectType(target) {
			continue
		}
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
b_sum :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Get sum of array">>
				sum(arr)
				$ arr :: int, int
				Usage: sum([1,2,3])=>>6<<`


	if len(args) != 1 {
		return eval_new_error(
				e,
				"'sum' function error: wrong number of arguments, wants='1', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	arr, ok := args[0].(ObjectArray)
	if !ok {
		return eval_new_error(
				e,
				"'sum' function error: not supported for argument of type '%v'.%s",
				ObjectType(args[0]),
				usage,
			),
			false
	}
	sum := 0
	for elem in arr {
		value, ok := elem.(int)
		if !ok {
			return eval_new_error(
					e,
					"'sum' function error: all elements must be integers, got '%v'.%s",
					ObjectType(elem),
					usage,
				),
				false
		}
		sum += value
	}
	return sum, true
}
b_min :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Get min value of array">>
				min(arr)
				$ arr :: int, int
				Usage: min([1,2,3])=>>1<<`


	if len(args) != 1 {
		return eval_new_error(
				e,
				"'min' function error: wrong number of arguments, wants='1', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	arr, ok := args[0].(ObjectArray)
	if !ok {
		return eval_new_error(
				e,
				"'min' function error: not supported for argument of type '%v'.%s",
				ObjectType(args[0]),
				usage,
			),
			false
	}
	if len(arr) == 0 {
		return eval_new_error(
				e,
				"'min' function error: cannot find minimum of empty array.%s",
				usage,
			),
			false
	}
	for elem in arr {
		_, ok := elem.(int)
		if !ok {
			return eval_new_error(
					e,
					"'min' function error: all elements must be integers, got '%v'.%s",
					ObjectType(elem),
					usage,
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
b_max :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Get max value of array">>
				max(arr)
				$ arr :: int, int
				Usage: max([1,2,3])=>>3<<`


	if len(args) != 1 {
		return eval_new_error(
				e,
				"'max' function error: wrong number of arguments, wants='1', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	arr, ok := args[0].(ObjectArray)
	if !ok {
		return eval_new_error(
				e,
				"'max' function error: not supported for argument of type '%v'.%s",
				ObjectType(args[0]),
				usage,
			),
			false
	}
	if len(arr) == 0 {
		return eval_new_error(
				e,
				"'max' function error: cannot find maximum of empty array.%s",
				usage,
			),
			false
	}
	for elem in arr {
		_, ok := elem.(int)
		if !ok {
			return eval_new_error(
					e,
					"'max' function error: all elements must be integers, got '%v'.%s",
					ObjectType(elem),
					usage,
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
b_push :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
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
	new_arr := make([dynamic]ObjectBase, len(arr), e.varena)
	copy(new_arr[:], arr[:])
	append(&new_arr, args[1])
	return ObjectArray(new_arr), true
}
b_rest :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
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
b_last :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
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
b_first :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
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
b_len :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
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
b_range :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				Create an arr of integers
				range(start, end, step)
				$ start :: int
				$ end :: int
				$ step :: int
				Usage: range(1, 10, 2)=>>[1,3,5,7,9]<< `


	if len(args) != 3 {
		return eval_new_error(
				e,
				"'range' function error: wrong number of arguments, wants='3', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	start, start_ok := args[0].(int)
	if !start_ok {
		return eval_new_error(
				e,
				"'range' function error: start index must be integer, got '%v'.%s",
				ObjectType(args[0]),
				usage,
			),
			false
	}
	end, end_ok := args[1].(int)
	if !end_ok {
		return eval_new_error(
				e,
				"'range' function error: end index must be integer, got '%v'.%s",
				ObjectType(args[1]),
				usage,
			),
			false
	}
	step, step_ok := args[2].(int)
	if !step_ok {
		return eval_new_error(
				e,
				"'range' function error: step must be integer, got '%v'.%s",
				ObjectType(args[2]),
				usage,
			),
			false
	}
	if step == 0 {
		return eval_new_error(
				e,
				"'range' function error: step cannot be 0, got '%v'.%s",
				ObjectType(args[2]),
				usage,
			),
			false
	}
	arr := make([dynamic]ObjectBase, 0, e.varena)
	for i := start; i < end; i += step {
		append(&arr, i)
	}
	return ObjectArray(arr), true
}
b_pop :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Pop element from array">>
				pop(arr)
				$ arr :: int, int
				Usage: pop([1,2,3])=>>3<<`


	if len(args) != 1 {
		return eval_new_error(
				e,
				"'pop' function error: wrong number of arguments, wants='1', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}
	arr, ok := args[0].(ObjectArray)
	if !ok {
		return eval_new_error(
				e,
				"'pop' function error: not supported for argument of type '%v'.%s",
				ObjectType(args[0]),
				usage,
			),
			false
	}
	if len(arr) == 0 {
		return eval_new_error(e, "'pop' function error: cannot pop from empty array.%s", usage),
			false
	}
	new_arr := make([dynamic]ObjectBase, len(arr), e.varena)
	copy(new_arr[:], arr[:])
	pop(&new_arr)
	return ObjectArray(new_arr), true
}


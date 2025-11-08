package monkey
find_builtin_fn :: proc(name: string) -> ObjectBuilinFunction
{
	switch name
	{
	// str
	case "hash":
		return b_hash
	case "join":
		return b_join
	case "split":
		return b_split
	case "lower":
		return b_lower
	case "upper":
		return b_upper
	case "match":
		return b_match
	case "replace":
		return b_replace
	case "contains":
		return b_contains
	// Arr
	case "len":
		return b_len
	case "first":
		return b_first
	case "last":
		return b_last
	case "rest":
		return b_rest
	case "push":
		return b_push
	case "sort":
		return b_sort
	case "reverse":
		return b_reverse
	case "slice":
		return b_slice
	case "indexOf":
		return b_indexOf
	case "range":
		return b_range
	// typ
	case "bool":
		return b_bool
	case "float":
		return b_float
	case "int":
		return b_int
	case "str":
		return b_str
	case "typeof":
		return b_typeof
	case "arr":
		return b_arr
	// hashmap
	case "keys":
		return b_keys
	case "values":
		return b_values
	case "has":
		return b_has
	case "map":
		return b_map
	//math
	case "abs":
		return b_abs
	case "sum":
		return b_sum
	case "min":
		return b_min
	case "max":
		return b_max
	case "choose":
		return b_choose
	case "rand":
		return b_rand
	case "sin":
		return b_sin
	case "cos":
		return b_cos
	case "tan":
		return b_tan
	// io
	case "args":
		return b_args
	case "puts":
		return b_puts
	case "printf":
		return b_printf
	case "readf":
		return b_readf
	// quotes
	case "quote":
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool)
			{
				usage := `
				"Quote obj">>
				quote(obj)
				$ obj :: obj of int, str, float, any
				Usage: quote(1)=>>1<<`


				if len(args) != 1
				{
					return eval_new_error(
							e,
							"'quote' function error: wrong number of arguments, wants='1', got='%d'.%s",
							len(args),
							usage,
						),
						false
				}
				#partial switch arg in args[0]


				
				{
				case int,
				     bool,
				     string,
				     ObjectCompiledFunction,
				     ObjectHashTable,
				     ObjectArray,
				     ObjectQuote:
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
		return proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool)
			{
				usage := `
				"Unquote obj">>
				unquote(obj)
				$ obj :: obj of int, str, float, any
				Usage: unquote(1)=>>1<<`


				if len(args) != 1 do return eval_new_error(e, "'unquote' function error: wrong number of arguments, wants='1', got='%d'.%s", len(args), usage), false
				#partial switch arg in args[0]


				
				{
				case ObjectQuote:
					return arg, true // for quote, we need to convert the argument back to an AST node
				}
				return eval_new_error(
						e,
						"'unquote' function error: not supported for argument of type '%v'.%s",
						ObjectType(args[0]),
						usage,
					),
					false
			}
	}
	return nil
}


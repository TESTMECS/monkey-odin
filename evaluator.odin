#+feature dynamic-literals
package monkey
import "base:runtime"
import "core:fmt"
import "core:log"
import "core:strings"
import "core:testing"

// Evaluator=>>begin
Evaluator :: struct {
	_env: Environment,
	eval: proc(
		e: ^Evaluator,
		node: Ast_Program,
		allocator: runtime.Allocator,
	) -> (
		ObjectBase,
		bool,
	),
	free: proc(e: ^Evaluator),
	vmem: VArena,
}

Evaluator_New :: proc() -> Evaluator {
	v := VArena__New__()
	err := v->init()
	if err != nil {
		panic("Arena Allocation Failed: Evaluator_new")
	}

	new_env := Env_New(nil, v.allocator)

	e := Evaluator {
		_env = new_env,
		eval = eval_statements,
		free = eval_free,
		vmem = v,
	}

	return e
}

eval_free :: proc(e: ^Evaluator) {
	e.vmem->reset()
	e._env->free()
}

@(private = "file")
new_error :: proc(e: ^Evaluator, str: string, args: ..any) -> string {
	sb := &e.vmem.string_builder
	strings.builder_reset(sb)
	fmt.sbprintf(sb, str, ..args)
	err := strings.to_string(sb^)
	return strings.clone(err, e.vmem.allocator)
} // end <<Evaluator

@(private = "file")
eval :: proc(e: ^Evaluator, node: Node, current_env: ^Environment) -> (Object, bool) {
	#partial switch &data in node {
	// statements=>>begin
	case Ast_Ret:
		val, ok := eval(e, data.return_value^, current_env)
		if !ok do return val, false
		return ObjectReturn(ToObjectBase(val)), true
	case Ast_Let:
		val, ok := eval(e, data.value^, current_env)
		if !ok do return val, false
		_, ok = current_env->get(data.name)
		if ok do return ObjectBase(new_error(e, "identifier '%s' is already declared", data.name)), false
		current_env->set(data.name, ToObjectBase(val))
		return ObjectBase(NULL), true
	// end <<statements
	// expressions=>>begin
	case Ast_Identifier:
		return eval_identifier(e, data, current_env)
	case Ast_Prefix:
		operand, ok := eval(e, data.operand^, current_env)
		if !ok do return operand, false
		return eval_prefix_expression(e, data.op, ToObjectBase(operand))
	case Ast_Infix:
		left, ok := eval(e, data.left^, current_env)
		if !ok do return left, false
		right, ok2 := eval(e, data.right^, current_env)
		if !ok2 do return right, ok2
		return eval_infix_expression(e, data.op, ToObjectBase(left), ToObjectBase(right))
	case Ast_Block:
		return eval_block_statements(e, data, current_env)
	case Ast_If:
		return eval_if_expression(e, data, current_env)
	case Ast_Function:
		fn := Vmem__Alloc__(&e.vmem, ObjectFunction)

		fn.parameters = make([dynamic]Ast_Identifier, 0, len(data.parameters), e.vmem.allocator)
		Ast__Copy__(&data.parameters, &fn.parameters, e.vmem.allocator) // Copies the parameters

		fn.body = make(Ast_Block, 0, len(data.body), e.vmem.allocator)
		Ast__Copy__(&data.body, &fn.body, e.vmem.allocator) // copies the body

		fn.env = current_env
		return ObjectBase(fn), true
	case Ast_Call:
		function, ok := eval(e, data.function^, current_env)
		if !ok do return function, false

		args, args_success := eval_array_of_expressions_fixed(e, data.arguments, current_env)
		if !args_success do return args[0], false

		return apply_function(e, ToObjectBase(function), args)
	case Ast_Index:
		operand, ok := eval(e, data.operand^, current_env)
		if !ok do return operand, false

		index, index_ok := eval(e, data.index^, current_env)
		if !index_ok do return index, false

		return eval_index_expression(e, ToObjectBase(operand), ToObjectBase(index))
	// end <<expressions
	// literals=>>begin
	case int:
		return ObjectBase(data), true

	case bool:
		return ObjectBase(data), true

	case string:
		return ObjectBase(strings.clone(data, e.vmem.allocator)), true

	case Ast_Array:
		elements, ok := eval_array_of_expressions_registered(e, data, current_env)
		if !ok do return ObjectBase(elements), false

		return ObjectBase(elements), true

	case Ast_Hash_Table:
		return eval_hash_table_literal(e, data, current_env)
	}
	// end <<literals

	return ObjectBase(new_error(e, "unrecognized Node of type '%v'", Ast__Type__(node))), false
}

eval_statements :: proc(
	e: ^Evaluator,
	node: Ast_Program,
	allocator: runtime.Allocator,
) -> (
	ObjectBase,
	bool,
) {
	result: Object
	ok: bool

	for stmt in node {
		result, ok = eval(e, stmt, &e._env)
		if !ok do return result.(ObjectBase), false
		if _, ok_type := result.(ObjectReturn); ok_type do break
	}

	if str_obj, is_str := ToObjectBase(result).(string); is_str {
		result = ObjectBase(str_obj)
	}
	return ToObjectBase(result), true
}
@(private = "file")
eval_block_statements :: proc(
	e: ^Evaluator,
	program: Ast_Block,
	current_env: ^Environment,
) -> (
	Object,
	bool,
) {
	result: Object
	ok: bool

	for stmt in program {
		result, ok = eval(e, stmt, current_env)
		if !ok do return result, false

		if ObjectIsReturn(result) do break
	}

	if str_obj, is_str := ToObjectBase(result).(string); is_str {
		result = ObjectBase(strings.clone(str_obj, e.vmem.allocator))
	}
	return result, true
}
//%endsection

//%section eval expressions
@(private = "file")
eval_bang_operator_expression :: proc(e: ^Evaluator, operand: ObjectBase) -> ObjectBase {
	#partial switch data in operand {
	case bool:
		return !data

	case ObjectNil:
		return true
	}

	return false
}

@(private = "file")
eval_minus_operator_expression :: proc(e: ^Evaluator, operand: ObjectBase) -> (ObjectBase, bool) {
	value, ok := operand.(int)
	if !ok do return new_error(e, "unknown operator: '-' on type '%v'", ObjectType(operand)), false

	return -value, true
}

@(private = "file")
eval_prefix_expression :: proc(
	e: ^Evaluator,
	op: string,
	operand: ObjectBase,
) -> (
	ObjectBase,
	bool,
) {
	switch op {
	case "!":
		return eval_bang_operator_expression(e, operand), true

	case "-":
		return eval_minus_operator_expression(e, operand)
	}

	return new_error(e, "unknown operator: '%s' for type '%v'", op, ObjectType(operand)), false
}


@(private = "file")
eval_integer_infix_expression :: proc(
	e: ^Evaluator,
	op: string,
	left: int,
	right: int,
) -> (
	ObjectBase,
	bool,
) {
	switch op {
	case "+":
		return left + right, true

	case "-":
		return left - right, true

	case "*":
		return left * right, true

	case "/":
		return left / right, true

	case "<":
		return left < right, true

	case ">":
		return left > right, true

	case "==":
		return left == right, true

	case "!=":
		return left != right, true
	}

	return new_error(e, "unknown integer infix operator '%s'", op), false
}

@(private = "file")
eval_string_infix_expression :: proc(
	e: ^Evaluator,
	op: string,
	left: string,
	right: string,
) -> (
	ObjectBase,
	bool,
) {
	if op != "+" do return new_error(e, "unknown string infix operator '%s'", op), false

	strings.builder_reset(&e.vmem.string_builder)
	fmt.sbprintf(&e.vmem.string_builder, "%s%s", left, right)

	return strings.to_string(e.vmem.string_builder), true
}


@(private = "file")
eval_infix_expression :: proc(
	e: ^Evaluator,
	op: string,
	left: ObjectBase,
	right: ObjectBase,
) -> (
	ObjectBase,
	bool,
) {
	if Ast__Type__(left) == int && Ast__Type__(right) == int {
		return eval_integer_infix_expression(e, op, left.(int), right.(int))
	} else if Ast__Type__(left) == string && Ast__Type__(right) == string {
		return eval_string_infix_expression(e, op, left.(string), right.(string))
	}

	switch op {
	case "==":
		switch ObjectType(left) {
		case ObjectArray,
		     ObjectHashTable,
		     ObjectBuilinFunction,
		     ObjectCompiledFunction,
		     ObjectFunction:
			if ObjectType(right) == ObjectArray do return new_error(e, "cannot compare arrays with '=='"), false
		case ObjectNil:
			// always false
			return false, true
		case int, string, bool:
			// make sure to compare bools by value
			if ObjectType(left) == bool && ObjectType(right) == bool {
				return left.(bool) == right.(bool), true
			}
			if ObjectType(left) == int && ObjectType(right) == int {
				return left.(int) == right.(int), true
			}
			if ObjectType(left) == string && ObjectType(right) == string {
				return left.(string) == right.(string), true
			}
			return false, true
		}
	case "!=":
		switch ObjectType(left) {
		case ObjectArray,
		     ObjectHashTable,
		     ObjectBuilinFunction,
		     ObjectCompiledFunction,
		     ObjectFunction:
			return new_error(e, "cannot compare arrays with '=='"), false
		case ObjectNil:
			return true, true
		case int, string, bool:
			if ObjectType(left) == bool && ObjectType(right) == bool {
				return left.(bool) == right.(bool), true
			}
			if ObjectType(left) == int && ObjectType(right) == int {
				return left.(int) == right.(int), true
			}
			if ObjectType(left) == string && ObjectType(right) == string {
				return left.(string) == right.(string), true
			}
			return false, true
		}
	}

	return new_error(
			e,
			"unknown operator '%s' for types '%v' and '%v'",
			op,
			ObjectType(left),
			ObjectType(right),
		),
		false
}

@(private = "file")
is_truthy :: proc(obj: Object) -> bool {
	#partial switch data in ToObjectBase(obj) {
	case ObjectNil:
		return false
	case bool:
		return data
	}
	return true
}


@(private = "file")
eval_if_expression :: proc(
	e: ^Evaluator,
	node: Ast_If,
	current_env: ^Environment,
) -> (
	Object,
	bool,
) {
	condition, ok := eval(e, node.condition^, current_env)
	if !ok do return condition, false
	if is_truthy(condition) {
		return eval(e, node.then, current_env)
	} else if node.orelse != nil {
		return eval(e, node.orelse, current_env)
	}
	return ObjectBase(NULL), true
}

@(private = "file")
eval_identifier :: proc(
	e: ^Evaluator,
	node: Ast_Identifier,
	current_env: ^Environment,
) -> (
	ObjectBase,
	bool,
) {
	if val, ok := current_env->get(node.value); ok do return val, true

	if builtin := find_builtin_fn(node.value); builtin != nil do return builtin, true

	return new_error(e, "identifier '%s' is not declared", node.value), false
}

@(private = "file")
eval_array_of_expressions_fixed :: proc(
	e: ^Evaluator,
	expressions: [dynamic]Node,
	current_env: ^Environment,
) -> (
	[dynamic]ObjectBase,
	bool,
) {
	args := make([dynamic]ObjectBase, 0, len(expressions), e.vmem.allocator)

	for expr in expressions {
		evaluated, ok := eval(e, expr, current_env)
		append(&args, ToObjectBase(evaluated))
		if !ok do return args, false
	}

	return args, true
}


@(private = "file")
eval_array_of_expressions_registered :: proc(
	e: ^Evaluator,
	expressions: Ast_Array,
	current_env: ^Environment,
) -> (
	ObjectArray,
	bool,
) {
	// Intestingly, this make call crashes my entire OS LMAO
	// TODO: Might be interesting to find out why
	// args := make([dynamic]ObjectBase, 0, len(expressions), e.vmem.allocator)
	args := make(ObjectArray, 0, len(expressions), e.vmem.allocator)

	for expr in expressions {
		evaluated, ok := eval(e, expr, current_env)
		append(&args, ToObjectBase(evaluated))
		if !ok do return args, false
	}

	return args, true
}

@(private = "file")
extend_function_env :: proc(
	e: ^Evaluator,
	fn: ^ObjectFunction,
	args: [dynamic]ObjectBase,
) -> ^Environment {
	env := Env_Enclosed(fn.env, len(fn.parameters), e.vmem.allocator)

	for param, idx in fn.parameters {
		env->set(param.value, args[idx])
	}

	return env
}

@(private = "file")
apply_function :: proc(
	e: ^Evaluator,
	fn: ObjectBase,
	args: [dynamic]ObjectBase,
) -> (
	ObjectBase,
	bool,
) {
	#partial switch function in fn {
	case ^ObjectFunction:
		if len(function.parameters) != len(args) {
			return new_error(
					e,
					"number of passed arguments does not match the number of needed parameters, need='%d', got='%d'",
					len(function.parameters),
					len(args),
				),
				false
		}
		extended_env := extend_function_env(e, function, args)
		evaluated, success := eval(e, function.body, extended_env)
		extended_env->free()
		return ToObjectBase(evaluated), success

	case ObjectBuilinFunction:
		return function(e, args)
	}

	return new_error(e, "not a function: '%v'", ObjectType(fn)), false
}


@(private = "file")
eval_hash_table_literal :: proc(
	e: ^Evaluator,
	node: Ast_Hash_Table,
	current_env: ^Environment,
) -> (
	Object,
	bool,
) {
	ht := make(ObjectHashTable, len(node.pairs), e.vmem.allocator)

	for pair in node.pairs {
		// Evaluate key
		key_obj, key_ok := eval(e, pair.key, current_env)
		if !key_ok do return key_obj, false

		// Evaluate value
		val_obj, val_ok := eval(e, pair.value, current_env)
		if !val_ok do return val_obj, false

		// Convert evaluated key to something hashable (string, int, etc.)
		key_base := ToObjectBase(key_obj)
		val_base := ToObjectBase(val_obj)

		// For simplicity, enforce that keys are strings
		key_str, key_is_string := key_base.(string)
		if !key_is_string {
			log.errorf(
				"hash literal key must evaluate to a string, got: %v",
				typeid_of(type_of(key_base)),
			)
			return key_base, false
		}

		ht[key_str] = val_base
	}

	return ObjectBase(ht), true
}

@(private = "file")
eval_array_index_expression :: proc(
	e: ^Evaluator,
	array: ObjectArray,
	index: int,
) -> (
	ObjectBase,
	bool,
) {
	max := len(array) - 1

	if index < 0 || index > max {
		return new_error(e, "index out of boundary expect '0..%d', got='%d'", max, index), false
	}

	return array[index], true
}

@(private = "file")
eval_hash_table_index_expression :: proc(
	e: ^Evaluator,
	ht: ObjectHashTable,
	key: string,
) -> (
	ObjectBase,
	bool,
) {
	value, ok := ht[key]

	if !ok {
		return new_error(e, "key '%s' does not exists", key), false
	}

	return value, true
}

@(private = "file")
eval_index_expression :: proc(
	e: ^Evaluator,
	operand: ObjectBase,
	index: ObjectBase,
) -> (
	ObjectBase,
	bool,
) {
	if ObjectType(operand) == ObjectArray && ObjectType(index) == int {
		return eval_array_index_expression(e, operand.(ObjectArray), index.(int))
	}
	if ObjectType(operand) == ObjectHashTable && ObjectType(index) == string {
		return eval_hash_table_index_expression(e, operand.(ObjectHashTable), index.(string))
	}
	return new_error(e, "index operator does not support: '%v'", ObjectType(operand)), false
}
//%endsection

//%section eval builtin functions
@(private = "file")
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
					new_arr := Vmem__Alloc__(&e.vmem, ObjectArray)
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


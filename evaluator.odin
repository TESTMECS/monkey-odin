#+feature dynamic-literals
package monkey
import "base:runtime"
import "core:fmt"
import "core:log"
import "core:strings"
import "core:testing"
//%note:"fixme: Allocator"
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
//%section Evaluator
Evaluator__New__ :: proc() -> Evaluator {
	v := VArena__New__()
	err := v->init()

	if err != nil {
		panic("Arena Allocation Failed: Evaluator_new")
	}

	new_env := Env__New__(nil, v.allocator)

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
}
//%endsection
//%section main eval function
@(private = "file")
eval :: proc(e: ^Evaluator, node: Node, current_env: ^Environment) -> (Object, bool) {
	#partial switch &data in node {

	// statements
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

	// expressions
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

	// literals
	case int:
		return ObjectBase(data), true

	case bool:
		return ObjectBase(data), true

	case string:
		return ObjectBase(strings.clone(data, e.vmem.allocator)), true

	case Ast_Array:
		elements, ok := eval_array_of_expressions_registered(e, data, current_env)
		if !ok do return ObjectBase(&elements), false

		return ObjectBase(&elements), true

	case Ast_Hash_Table:
		return eval_hash_table_literal(e, data, current_env)
	}

	return ObjectBase(new_error(e, "unrecognized Node of type '%v'", ast_type(node))), false
}
//%endsection
//%section eval statements
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
	if ast_type(left) == int && ast_type(right) == int {
		return eval_integer_infix_expression(e, op, left.(int), right.(int))
	} else if ast_type(left) == string && ast_type(right) == string {
		return eval_string_infix_expression(e, op, left.(string), right.(string))
	}

	switch op {
	case "==":
		return left == right, true

	case "!=":
		return left != right, true
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
	env := Env__Enclosed__(fn.env, len(fn.parameters), e.vmem.allocator)

	// Leak here fs
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
	ht := make(ObjectHashTable, len(node), e.vmem.allocator)
	// ht := Vmem__Alloc__(&e.vmem, ObjectHashTable)

	for key_node, value_node in node {
		key, key_is_valid := eval(e, key_node, current_env)
		if !key_is_valid do return key, false

		value, value_is_valid := eval(e, value_node, current_env)
		if !value_is_valid do return value, false

		key_conv, key_is_string := ToObjectBase(key).(string)
		ht[key_conv] = ToObjectBase(value)
	}
	return ObjectBase(&ht), true
}

@(private = "file")
eval_array_index_expression :: proc(
	e: ^Evaluator,
	array: ^ObjectArray,
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
	ht: ^ObjectHashTable,
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
	if ObjectType(operand) == ^ObjectArray && ObjectType(index) == int {
		return eval_array_index_expression(e, operand.(^ObjectArray), index.(int))
	}

	if ObjectType(operand) == ^ObjectHashTable && ObjectType(index) == string {
		return eval_hash_table_index_expression(e, operand.(^ObjectHashTable), index.(string))
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

				case ^ObjectArray:
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

				arr, ok := args[0].(^ObjectArray)
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

				arr, ok := args[0].(^ObjectArray)
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

				arr, ok := args[0].(^ObjectArray)
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

					return new_arr, true
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

				arr, ok := args[0].(^ObjectArray)
				if !ok {
					return new_error(
							e,
							"'push' function error: not supported for argument of type '%v'",
							ObjectType(args[0]),
						),
						false
				}

				append(arr, args[1])

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
//%endsection
//%section test helpers.
eval_test_get :: proc(input: string, print_errors := true) -> (ObjectBase, Evaluator, bool) {
	p := Parser__New__(input)
	defer p->free()
	program := p->parse()
	if parser_has_error(p) do return nil, Evaluator{}, false

	e := Evaluator__New__() // Create the evaluator
	evaluated, ok := e.eval(&e, program, e.vmem.allocator) // Evaluate the program
	if !ok {
		if print_errors do log.errorf("eval failed: %s", evaluated)
		e->free()
		return nil, Evaluator{}, false
	}
	return evaluated, e, true
}
eval_test_is_valid :: proc(input: string, print_errors := true) -> (ObjectBase, bool) {
	evaluated, _, ok := eval_test_get(input, print_errors)
	if !ok do return nil, false
	return evaluated, ok
}
integer_object_is_valid :: proc(obj: ObjectBase, expected: int) -> bool {
	result, ok := obj.(int)
	if !ok {
		log.errorf("object is not integer, got='%v'", ObjectType(obj))
		return false
	}

	if result != expected {
		log.errorf("object has wrong value. got='%d', expected='%d'", result, expected)
		return false
	}

	return true
}
boolean_object_is_valid :: proc(obj: ObjectBase, expected: bool) -> bool {
	result, ok := obj.(bool)
	if !ok {
		log.errorf("object is not boolean, got='%v'", ObjectType(obj))
		return false
	}

	if result != expected {
		log.errorf("object has wrong value. got='%d', expected='%d'", result, expected)
		return false
	}

	return true
}

string_object_is_valid :: proc(obj: ObjectBase, expected: string) -> bool {
	result, ok := obj.(string)
	if !ok {
		log.errorf("object is not string, got='%v'", ObjectType(obj))
		return false
	}

	if result != expected {
		log.errorf("object has wrong value. got='%s', expected='%s'", result, expected)
		return false
	}

	return true
}
//%endsection
//%section Main Evaluator Tests
@(test)
test_eval_integer_expression :: proc(t: ^testing.T) {
	tests := [?]struct {
		input:    string,
		expected: int,
	} {
		{"5", 5},
		{"10", 10},
		{"-5", -5},
		{"-10", -10},
		{"5 + 5 + 5 + 5 - 10", 10},
		{"2 * 2 * 2 * 2 * 2", 32},
		{"-50 + 100 + -50", 0},
		{"5 * 2 + 10", 20},
		{"5 + 2 * 10", 25},
		{"20 + 2 * -10", 0},
		{"50 / 2 * 2 + 10", 60},
		{"2 * (5 + 10)", 30},
		{"3 * 3 * 3 + 10", 37},
		{"3 * (3 * 3) + 10", 37},
		{"(5 + 10 * 2 + 15 / 3) * 2 + -10", 50},
		{"(5 + 10 * 2 + 15 / 3) * 2 + -10", 50},
	}
	for test, i in tests {
		evaluated, ok := eval_test_is_valid(test.input)
		if !ok do return

		if !integer_object_is_valid(evaluated, test.expected) {
			log.errorf("test [%d] has failed", i)
		}
	}

}
@(test)
test_eval_boolean_expression :: proc(t: ^testing.T) {
	tests := [?]struct {
		input:    string,
		expected: bool,
	} {
		{"true", true},
		{"false", false},
		{"1<2", true},
		{"1>2", false},
		{"1==1", true},
		{"1!=1", false},
		{"true == true", true},
		{"false == false", true},
		{"(1<2) == true", true},
		{"(1<2) == false", false},
	}

	for test_case, i in tests {
		evaluated, ok := eval_test_is_valid(test_case.input)
		if !ok {
			log.errorf("test [%d] has failed", i)
			continue
		}
		if !boolean_object_is_valid(evaluated, test_case.expected) {
			log.errorf("test [%d] has failed", i)
		}
	}
}
@(test)
test_eval_string_expression :: proc(t: ^testing.T) {
	tests := [?]struct {
		input:    string,
		expected: string,
	}{{`"Hello World"`, "Hello World"}, {`"Hello" + " " + "World"`, "Hello World"}}

	for test_case, i in tests {
		evaluated, ok := eval_test_is_valid(test_case.input)
		if !ok {
			log.errorf("test [%d] has failed", i)
			continue
		}
		if !string_object_is_valid(evaluated, test_case.expected) {
			log.errorf("test [%d] has failed", i)
		}
	}
}
@(test)
test_eval_bang_operator :: proc(t: ^testing.T) {
	tests := [?]struct {
		input:    string,
		expected: bool,
	} {
		{"!true", false},
		{"!false", true},
		{"!1", false},
		{"!!true", true},
		{"!!false", false},
		{"!!1", true},
	}

	for test_case, i in tests {
		evaluated, ok := eval_test_is_valid(test_case.input)
		if !ok {
			log.errorf("test [%d] has failed", i)
			continue
		}
		if !boolean_object_is_valid(evaluated, test_case.expected) {
			log.errorf("test [%d] has failed", i)
		}
	}
}
@(test)
test_eval_if_expression :: proc(t: ^testing.T) {
	tests := [?]struct {
		input:    string,
		expected: ObjectBase,
	} {
		{"if (true) { 10 }", 10},
		{"if (false) { 10 }", NULL},
		{"if (1) { 10 }", 10},
		{"if (1 < 2) { 10 }", 10},
		{"if (1 > 2) { 10 }", NULL},
		{"if (1 < 2) { 10 } else { 20 }", 10},
		{"if (1 > 2) { 10 } else { 20 }", 20},
	}
	for test_case, i in tests {
		evaluated, ok := eval_test_is_valid(test_case.input)
		if !ok {
			log.errorf("test [%d] has failed", i)
			continue
		}
		#partial switch expected in test_case.expected {
		case int:
			if !integer_object_is_valid(evaluated, expected) {
				log.errorf("test [%d] has failed", i)
			}
		case ObjectNil:
			if ObjectType(evaluated) != ObjectNil {
				log.errorf(
					"test [%d] has failed, Object is not nil, got='%v' instead.",
					i,
					ObjectType(evaluated),
				)
			}
		}
	}
}

@(test)
test_eval_return_statement :: proc(t: ^testing.T) {
	tests := [?]struct {
		input:    string,
		expected: int,
	} {
		{"return 10;", 10},
		{"return 10; 9;", 10},
		{"return 2 * 5; 9;", 10},
		{"9; return 2 * 5; 9;", 10},
		{
			`
    if 10 > 1 {
        if 10 > 1 {
            return 10;
        }

        return 1;
    }`,
			10,
		},
	}

	for test_case, i in tests {
		evaluated, ok := eval_test_is_valid(test_case.input)
		if !ok {
			log.errorf("test[%d] has failed", i)
			continue
		}

		if !integer_object_is_valid(evaluated, test_case.expected) {
			log.errorf("test[%d] has failed", i)
		}
	}
}

@(test)
test_eval_let_statements :: proc(t: ^testing.T) {
	tests := [?]struct {
		input:    string,
		expected: int,
	} {
		{"let a = 5; a;", 5},
		{"let a = 5 * 5; a;", 25},
		{"let a = 5; let b = a; b;", 5},
		{"let a = 5; let b = a; let c = a + b + 5; c;", 15},
	}

	for test_case, i in tests {
		evaluated, ok := eval_test_is_valid(test_case.input)
		if !ok {
			log.errorf("test[%d] has failed", i)
			continue
		}

		if !integer_object_is_valid(evaluated, test_case.expected) {
			log.errorf("test[%d] has failed", i)
		}
	}
}

@(test)
test_eval_function_object :: proc(t: ^testing.T) {
	input := "fn(x) { x + 2 };"

	evaluated, e, ok := eval_test_get(input)
	if !ok do return
	defer e.free(&e)

	fn, is_fn := evaluated.(^ObjectFunction)
	if !is_fn {
		log.errorf("object is not function. got='%v'", ObjectType(evaluated))
		return
	}

	if len(fn.parameters) != 1 {
		log.errorf(
			"function has wrong number of parameters, got='%d', '%v'",
			len(fn.parameters),
			fn.parameters,
		)
		return
	}


	if fn.parameters[0].value != "x" {
		log.errorf("function's parameter is not 'x', got='%s'", fn.parameters[0])
		return
	}

	expected_body := "{ (x+2) }"

	sb := strings.builder_make(context.temp_allocator)
	defer free_all(context.temp_allocator)

	ast_to_string(fn.body, &sb)

	if strings.to_string(sb) != expected_body {
		log.errorf(
			"ast_to_string ris not valid, expected='%s', got='%s'",
			expected_body,
			strings.to_string(sb),
		)
	}
}

@(test)
test_eval_function_application :: proc(t: ^testing.T) {
	tests := [?]struct {
		input:    string,
		expected: int,
	} {
		{"let identity = fn(x) { x; }; identity(5);", 5},
		{"let identity = fn(x) { return x; }; identity(5);", 5},
		{"let double = fn(x) { x * 2; }; double(5);", 10},
		{"let add = fn(x, y) { x * y; }; add(5, 5);", 25},
		{"let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));", 20},
		{"fn (x) { x; }(5)", 5},
		{`
let new_adder = fn(x) {
	fn(y) {x + y};
};

let add_two = new_adder(2);
add_two(2)`, 4},
	}

	for test_case, i in tests {
		evaluated, ok := eval_test_is_valid(test_case.input)
		if !ok {
			log.errorf("test[%d] has failed", i)
			continue
		}

		if !integer_object_is_valid(evaluated, test_case.expected) {
			log.errorf("test[%d] has failed", i)
		}

	}
}

@(test)
test_eval_builtin_functions :: proc(t: ^testing.T) {
	tests := [?]struct {
		input:    string,
		expected: union {
			int,
			string,
		},
	}{{`len("")`, 0}, {`len("four")`, 4}, {`len("hello world")`, 11}}

	for test_case, i in tests {
		evaluated, ok := eval_test_is_valid(test_case.input)
		if !ok {
			log.errorf("test[%d] has failed", i)
			continue
		}

		switch expected in test_case.expected {
		case int:
			if !integer_object_is_valid(evaluated, expected) {
				log.errorf("test[%d] has failed", i)
			}

		case string:
			if !string_object_is_valid(evaluated, expected) {
				log.errorf("test[%d] has failed", i)
			}
		}

	}
}

@(test)
test_eval_array_literals :: proc(t: ^testing.T) {
	input := "[1, 2 * 2, 3 + 3]"

	evaluated, ok := eval_test_is_valid(input)
	if !ok do return

	arr, is_arr := evaluated.(^ObjectArray)
	if !is_arr {
		log.errorf("expected array object but got '%v'", ObjectType(evaluated))
		return
	}

	if len(arr) != 3 {
		log.errorf("expected array length to be 3 but got='%d'", len(arr))
		return
	}

	if !integer_object_is_valid(arr[0], 1) {
		log.errorf("arr[0] does not match")
	}

	if !integer_object_is_valid(arr[1], 4) {
		log.errorf("arr[1] does not match")
	}

	if !integer_object_is_valid(arr[2], 6) {
		log.errorf("arr[2] does not match")
	}
}

@(test)
test_eval_hash_literals :: proc(t: ^testing.T) {
	input := `
    {
        "one": 10 - 9,
        "two": 1 + 1,
        "three": 6 / 2,
    }`


	evaluated, ok := eval_test_is_valid(input)
	if !ok do return

	ht, is_hash_table := evaluated.(^ObjectHashTable)
	if !is_hash_table {
		log.errorf("expected hash table object but got '%v'", ObjectType(evaluated))
		return
	}

	expected := map[string]int {
		"one"   = 1,
		"two"   = 2,
		"three" = 3,
	}
	defer delete(expected)

	if len(ht) != len(expected) {
		log.errorf(
			"Hash table has wrong number of pairs, expected='%d', got='%d'",
			len(expected),
			len(ht),
		)
		return
	}

	for expected_key, expected_value in expected {
		value, key_exists := ht[expected_key]
		if !key_exists {
			log.errorf("key '%v' expected but does not exist", expected_key)
			continue
		}

		if !integer_object_is_valid(value, expected_value) {
			log.errorf("key '%s' has wrong value", expected_key)
		}
	}
}


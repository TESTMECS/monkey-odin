package evaluator_tests

import monkey "../../src"
import "core:log"
import "core:strings"
import "core:testing"

@(test)
test_eval_function_object :: proc(t: ^testing.T)
{
	using monkey
	using tc
	input := "fn(x) { x + 2 };"

	evaluated, e, ok, v := eval_test_get(input)
	defer v->free()
	if !ok do return

	fn, is_fn := evaluated.(^ObjectFunction)
	if !is_fn
	{
		log.errorf("object is not function. got='%v'", ObjectType(evaluated))
		return
	}

	if len(fn.parameters) != 1
	{
		log.errorf(
			"function has wrong number of parameters, got='%d', '%v'",
			len(fn.parameters),
			fn.parameters,
		)
		return
	}


	if fn.parameters[0].value != "x"
	{
		log.errorf("function's parameter is not 'x', got='%s'", fn.parameters[0])
		return
	}

	expected_body := "{ ( x + 2 ) }"

	sb := strings.builder_make(context.temp_allocator)
	defer free_all(context.temp_allocator)

	ast_to_string(fn.body, &sb)

	if strings.to_string(sb) != expected_body
	{
		log.errorf(
			"ast_to_string ris not valid, expected='%s', got='%s'",
			expected_body,
			strings.to_string(sb),
		)
	}
}

@(test)
test_eval_function_application :: proc(t: ^testing.T)
{
	using monkey
	using tc
	tests := [?]struct
	{
		input:    string,
		expected: int,
	} {
		{"let identity = fn(x) { x; }; identity(5);", 5},
		{"let identity = fn(x) { return x; }; identity(5);", 5},
		{"let double = fn(x) { x * 2; }; double(5);", 10},
		{"let add = fn(x, y) { x * y; }; add(5, 5);", 25},
		{"let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));", 20},
		{"fn (x) { x; }(5)", 5},
		{
			`
			let new_adder = fn(x) {
				fn(y) {x + y};
			};

			let add_two = new_adder(2);
			add_two(2)`,
			4,
		},
	}

	for test_case, i in tests
	{
		evaluated, e, ok, v := eval_test_is_valid(test_case.input)
		defer v->free()
		if !ok
		{
			log.errorf("test[%d] has failed", i)
			continue
		}

		if !integer_object_is_valid(evaluated, test_case.expected)
		{
			log.errorf("test[%d] has failed", i)
		}

	}
}

@(test)
test_eval_builtin_functions :: proc(t: ^testing.T)
{
	using monkey
	using tc
	tests := [?]struct
	{
		input:    string,
		expected: union
		{
			int,
			string,
		},
	}{{`len("")`, 0}, {`len("four")`, 4}, {`len("hello world")`, 11}}

	for test_case, i in tests
	{
		evaluated, e, ok, v := eval_test_is_valid(test_case.input)
		defer v->free()
		if !ok
		{
			log.errorf("test[%d] has failed", i)
			continue
		}

		switch expected in test_case.expected
		
		{
		case int:
			if !integer_object_is_valid(evaluated, expected)
			{
				log.errorf("test[%d] has failed", i)
			}

		case string:
			if !string_object_is_valid(evaluated, expected)
			{
				log.errorf("test[%d] has failed", i)
			}
		}
	}
}


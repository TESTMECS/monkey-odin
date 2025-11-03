package compiler_tests

import monkey "../../src"
import "core:testing"

@(test)
test_compile_functions :: proc(t: ^testing.T) {
	using monkey
	tests := [?]Compiler_Test_Case {
		{
			"fn () { return 5 + 10 }",
			{
				5,
				10,
				[]Instructions {
					make_instructions(context.temp_allocator, .Cnst, 0),
					make_instructions(context.temp_allocator, .Cnst, 1),
					make_instructions(context.temp_allocator, .Add),
					make_instructions(context.temp_allocator, .Ret_V),
				},
			},
			{
				make_instructions(context.temp_allocator, .Cnst, 2),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"fn () { 5 + 10 }",
			{
				5,
				10,
				[]Instructions {
					make_instructions(context.temp_allocator, .Cnst, 0),
					make_instructions(context.temp_allocator, .Cnst, 1),
					make_instructions(context.temp_allocator, .Add),
					make_instructions(context.temp_allocator, .Ret_V),
				},
			},
			{
				make_instructions(context.temp_allocator, .Cnst, 2),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"fn () { 1; 2 }",
			{
				1,
				2,
				[]Instructions {
					make_instructions(context.temp_allocator, .Cnst, 0),
					make_instructions(context.temp_allocator, .Pop),
					make_instructions(context.temp_allocator, .Cnst, 1),
					make_instructions(context.temp_allocator, .Ret_V),
				},
			},
			{
				make_instructions(context.temp_allocator, .Cnst, 2),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"fn () { }",
			{[]Instructions{make_instructions(context.temp_allocator, .Ret)}},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}

@(test)
test_compile_function_calls :: proc(t: ^testing.T) {
	using monkey
	tests := [?]Compiler_Test_Case {
		{
			"fn () { 24 }();",
			{
				24,
				[]Instructions {
					make_instructions(context.temp_allocator, .Cnst, 0), // the literal "24"
					make_instructions(context.temp_allocator, .Ret_V),
				},
			},
			{
				make_instructions(context.temp_allocator, .Cnst, 1), // the compiled function
				make_instructions(context.temp_allocator, .Call, 0),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"let no_arg = fn () { 24 }; no_arg();",
			{
				24,
				[]Instructions {
					make_instructions(context.temp_allocator, .Cnst, 0), // the literal "24"
					make_instructions(context.temp_allocator, .Ret_V),
				},
			},
			{
				make_instructions(context.temp_allocator, .Cnst, 1), // the compiled function
				make_instructions(context.temp_allocator, .Set_G, 0),
				make_instructions(context.temp_allocator, .Get_G, 0),
				make_instructions(context.temp_allocator, .Call, 0),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"let one_arg = fn (a) { a }; one_arg(24);",
			{
				[]Instructions {
					make_instructions(context.temp_allocator, .Get_L, 0),
					make_instructions(context.temp_allocator, .Ret_V),
				},
				24,
			},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Set_G, 0),
				make_instructions(context.temp_allocator, .Get_G, 0),
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Call, 1),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"let many_args = fn (a, b, c) { a; b; c }; many_args(24, 25, 26);",
			{
				[]Instructions {
					make_instructions(context.temp_allocator, .Get_L, 0),
					make_instructions(context.temp_allocator, .Pop),
					make_instructions(context.temp_allocator, .Get_L, 1),
					make_instructions(context.temp_allocator, .Pop),
					make_instructions(context.temp_allocator, .Get_L, 2),
					make_instructions(context.temp_allocator, .Ret_V),
				},
				24,
				25,
				26,
			},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Set_G, 0),
				make_instructions(context.temp_allocator, .Get_G, 0),
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Cnst, 2),
				make_instructions(context.temp_allocator, .Cnst, 3),
				make_instructions(context.temp_allocator, .Call, 3),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}


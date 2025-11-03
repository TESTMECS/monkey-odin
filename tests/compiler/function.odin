package compiler_tests

import m "../.."
import "core:testing"

@(test)
test_compile_function_calls :: proc(t: ^testing.T) {
	tests := [?]Compiler_Test_Case {
		{
			"fn () { 24 }();",
			{
				24,
				[]m.Instructions {
					m.make_instructions(context.temp_allocator, .Cnst, 0), // the literal "24"
					m.make_instructions(context.temp_allocator, .Ret_V),
				},
			},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 1), // the compiled function
				m.make_instructions(context.temp_allocator, .Call, 0),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"let no_arg = fn () { 24 }; no_arg();",
			{
				24,
				[]m.Instructions {
					m.make_instructions(context.temp_allocator, .Cnst, 0), // the literal "24"
					m.make_instructions(context.temp_allocator, .Ret_V),
				},
			},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 1), // the compiled function
				m.make_instructions(context.temp_allocator, .Set_G, 0),
				m.make_instructions(context.temp_allocator, .Get_G, 0),
				m.make_instructions(context.temp_allocator, .Call, 0),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"let one_arg = fn (a) { a }; one_arg(24);",
			{
				[]m.Instructions {
					m.make_instructions(context.temp_allocator, .Get_L, 0),
					m.make_instructions(context.temp_allocator, .Ret_V),
				},
				24,
			},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 0),
				m.make_instructions(context.temp_allocator, .Set_G, 0),
				m.make_instructions(context.temp_allocator, .Get_G, 0),
				m.make_instructions(context.temp_allocator, .Cnst, 1),
				m.make_instructions(context.temp_allocator, .Call, 1),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"let many_args = fn (a, b, c) { a; b; c }; many_args(24, 25, 26);",
			{
				[]m.Instructions {
					m.make_instructions(context.temp_allocator, .Get_L, 0),
					m.make_instructions(context.temp_allocator, .Pop),
					m.make_instructions(context.temp_allocator, .Get_L, 1),
					m.make_instructions(context.temp_allocator, .Pop),
					m.make_instructions(context.temp_allocator, .Get_L, 2),
					m.make_instructions(context.temp_allocator, .Ret_V),
				},
				24,
				25,
				26,
			},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 0),
				m.make_instructions(context.temp_allocator, .Set_G, 0),
				m.make_instructions(context.temp_allocator, .Get_G, 0),
				m.make_instructions(context.temp_allocator, .Cnst, 1),
				m.make_instructions(context.temp_allocator, .Cnst, 2),
				m.make_instructions(context.temp_allocator, .Cnst, 3),
				m.make_instructions(context.temp_allocator, .Call, 3),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}


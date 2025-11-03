package compiler_tests

import monkey "../../src"
import "core:testing"

@(test)
test_compile_global_let_statements :: proc(t: ^testing.T) {
	using monkey
	tests := [?]Compiler_Test_Case {
		{
			"let one = 1; let two = 2;",
			{1, 2},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Set_G, 0),
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Set_G, 1),
			},
		},
		{
			"let one = 1; one;",
			{1},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Set_G, 0),
				make_instructions(context.temp_allocator, .Get_G, 0),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"let one = 1; let two = one; two;",
			{1},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Set_G, 0),
				make_instructions(context.temp_allocator, .Get_G, 0),
				make_instructions(context.temp_allocator, .Set_G, 1),
				make_instructions(context.temp_allocator, .Get_G, 1),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}


package compiler_tests

import m "../.."
import "core:testing"

@(test)
test_compile_global_let_statements :: proc(t: ^testing.T) {
	tests := [?]Compiler_Test_Case {
		{
			"let one = 1; let two = 2;",
			{1, 2},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 0),
				m.make_instructions(context.temp_allocator, .Set_G, 0),
				m.make_instructions(context.temp_allocator, .Cnst, 1),
				m.make_instructions(context.temp_allocator, .Set_G, 1),
			},
		},
		{
			"let one = 1; one;",
			{1},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 0),
				m.make_instructions(context.temp_allocator, .Set_G, 0),
				m.make_instructions(context.temp_allocator, .Get_G, 0),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"let one = 1; let two = one; two;",
			{1},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 0),
				m.make_instructions(context.temp_allocator, .Set_G, 0),
				m.make_instructions(context.temp_allocator, .Get_G, 0),
				m.make_instructions(context.temp_allocator, .Set_G, 1),
				m.make_instructions(context.temp_allocator, .Get_G, 1),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}

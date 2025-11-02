package compiler_tests

import m "../.."
import "core:fmt"
import "core:testing"

@(test)
test_compile_array_literals :: proc(t: ^testing.T) {
	tests := [?]Compiler_Test_Case {
		{
			"[]",
			{},
			{
				m.make_instructions(context.temp_allocator, .Arr, 0),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"[1, 2, 3]",
			{1, 2, 3},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 0),
				m.make_instructions(context.temp_allocator, .Cnst, 1),
				m.make_instructions(context.temp_allocator, .Cnst, 2),
				m.make_instructions(context.temp_allocator, .Arr, 3),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"[1 + 2, 3 - 4, 5 * 6]",
			{1, 2, 3, 4, 5, 6},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 0),
				m.make_instructions(context.temp_allocator, .Cnst, 1),
				m.make_instructions(context.temp_allocator, .Add),
				m.make_instructions(context.temp_allocator, .Cnst, 2),
				m.make_instructions(context.temp_allocator, .Cnst, 3),
				m.make_instructions(context.temp_allocator, .Sub),
				m.make_instructions(context.temp_allocator, .Cnst, 4),
				m.make_instructions(context.temp_allocator, .Cnst, 5),
				m.make_instructions(context.temp_allocator, .Mul),
				m.make_instructions(context.temp_allocator, .Arr, 3),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}


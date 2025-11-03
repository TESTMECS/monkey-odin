package compiler_tests

import monkey "../../src"
import "core:testing"

@(test)
test_compile_index_expressions :: proc(t: ^testing.T) {
	using monkey
	tests := [?]Compiler_Test_Case {
		{
			"[1, 2, 3][1 + 1]",
			{1, 2, 3, 1, 1},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Cnst, 2),
				make_instructions(context.temp_allocator, .Arr, 3),
				make_instructions(context.temp_allocator, .Cnst, 3),
				make_instructions(context.temp_allocator, .Cnst, 4),
				make_instructions(context.temp_allocator, .Add),
				make_instructions(context.temp_allocator, .Idx),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			`{"name": "Navid"}["name"]`,
			{"name", "Navid", "name"},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Ht, 2),
				make_instructions(context.temp_allocator, .Cnst, 2),
				make_instructions(context.temp_allocator, .Idx),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}


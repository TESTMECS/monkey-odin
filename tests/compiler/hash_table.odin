package compiler_tests

import m "../.."
import "core:testing"
import "core:fmt"

@(test)
test_compile_hash_table_literals :: proc(t: ^testing.T) {
	tests := [?]Compiler_Test_Case {
		{
			"{}",
			{},
			{
				m.make_instructions(context.temp_allocator, .Ht, 0),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			`{"name": "drew", "index": 1}`,
			{"name", "drew", "index", 1},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 0),
				m.make_instructions(context.temp_allocator, .Cnst, 1),
				m.make_instructions(context.temp_allocator, .Cnst, 2),
				m.make_instructions(context.temp_allocator, .Cnst, 3),
				m.make_instructions(context.temp_allocator, .Ht, 4),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			`{"drew": 1 + 2, "xavier": 3 * 4}`,
			{"drew", 1, 2, "xavier", 3, 4},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 0),
				m.make_instructions(context.temp_allocator, .Cnst, 1),
				m.make_instructions(context.temp_allocator, .Cnst, 2),
				m.make_instructions(context.temp_allocator, .Add),
				m.make_instructions(context.temp_allocator, .Cnst, 3),
				m.make_instructions(context.temp_allocator, .Cnst, 4),
				m.make_instructions(context.temp_allocator, .Cnst, 5),
				m.make_instructions(context.temp_allocator, .Mul),
				m.make_instructions(context.temp_allocator, .Ht, 4),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}


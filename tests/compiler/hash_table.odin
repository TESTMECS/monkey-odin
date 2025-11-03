package compiler_tests

import monkey "../../src"
import "core:mem/virtual"
import "core:testing"

@(test)
test_compile_hash_table_literals :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	tests := [?]Compiler_Test_Case {
		{"{}", {}, {make_instructions(a, .Ht, 0), make_instructions(a, .Pop)}},
		{
			`{"name": "drew", "index": 1}`,
			{"name", "drew", "index", 1},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Cnst, 1),
				make_instructions(a, .Cnst, 2),
				make_instructions(a, .Cnst, 3),
				make_instructions(a, .Ht, 4),
				make_instructions(a, .Pop),
			},
		},
		{
			`{"drew": 1 + 2, "xavier": 3 * 4}`,
			{"drew", 1, 2, "xavier", 3, 4},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Cnst, 1),
				make_instructions(a, .Cnst, 2),
				make_instructions(a, .Add),
				make_instructions(a, .Cnst, 3),
				make_instructions(a, .Cnst, 4),
				make_instructions(a, .Cnst, 5),
				make_instructions(a, .Mul),
				make_instructions(a, .Ht, 4),
				make_instructions(a, .Pop),
			},
		},
	}

	run_compiler_tests(t, tests[:])
}


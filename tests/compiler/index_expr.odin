package compiler_tests

import monkey "../../src"
import "core:mem/virtual"
import "core:testing"

@(test)
test_compile_index_expressions :: proc(t: ^testing.T) {
	using tc
	using monkey
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	tests := [?]Compiler_Test_Case {
		{
			"[1, 2, 3][1 + 1]",
			{1, 2, 3, 1, 1},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Cnst, 1),
				make_instructions(a, .Cnst, 2),
				make_instructions(a, .Arr, 3),
				make_instructions(a, .Cnst, 3),
				make_instructions(a, .Cnst, 4),
				make_instructions(a, .Add),
				make_instructions(a, .Idx),
				make_instructions(a, .Pop),
			},
		},
		{
			`{"name": "drew"}["name"]`,
			{"name", "drew", "name"},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Cnst, 1),
				make_instructions(a, .Ht, 2),
				make_instructions(a, .Cnst, 2),
				make_instructions(a, .Idx),
				make_instructions(a, .Pop),
			},
		},
	}

	run_compiler_tests(t, tests[:])
}


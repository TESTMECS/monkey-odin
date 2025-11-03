package compiler_tests

import monkey "../../src"
import "core:mem/virtual"
import "core:testing"

@(test)
test_compile_global_let_statements :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	tests := [?]Compiler_Test_Case {
		{
			"let one = 1; let two = 2;",
			{1, 2},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Set_G, 0),
				make_instructions(a, .Cnst, 1),
				make_instructions(a, .Set_G, 1),
			},
		},
		{
			"let one = 1; one;",
			{1},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Set_G, 0),
				make_instructions(a, .Get_G, 0),
				make_instructions(a, .Pop),
			},
		},
		{
			"let one = 1; let two = one; two;",
			{1},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Set_G, 0),
				make_instructions(a, .Get_G, 0),
				make_instructions(a, .Set_G, 1),
				make_instructions(a, .Get_G, 1),
				make_instructions(a, .Pop),
			},
		},
	}

	run_compiler_tests(t, tests[:])
}


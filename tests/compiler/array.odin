package compiler_tests
import monkey "../../src"
import "core:mem/virtual"
import "core:testing"

@(test)
test_compile_array_literals :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	tests := [?]Compiler_Test_Case {
		{"[]", {}, {make_instructions(a, .Arr, 0), make_instructions(a, .Pop)}},
		{
			"[1, 2, 3]",
			{1, 2, 3},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Cnst, 1),
				make_instructions(a, .Cnst, 2),
				make_instructions(a, .Arr, 3),
				make_instructions(a, .Pop),
			},
		},
		{
			"[1 + 2, 3 - 4, 5 * 6]",
			{1, 2, 3, 4, 5, 6},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Cnst, 1),
				make_instructions(a, .Add),
				make_instructions(a, .Cnst, 2),
				make_instructions(a, .Cnst, 3),
				make_instructions(a, .Sub),
				make_instructions(a, .Cnst, 4),
				make_instructions(a, .Cnst, 5),
				make_instructions(a, .Mul),
				make_instructions(a, .Arr, 3),
				make_instructions(a, .Pop),
			},
		},
	}

	run_compiler_tests(t, tests[:])
}


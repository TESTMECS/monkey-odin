package compiler_tests

import monkey "../../src"
import "core:mem/virtual"
import "core:testing"

@(test)
test_compile_integer_arithmetic :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	tests := [?]Compiler_Test_Case {
		{
			"1; 2",
			{1, 2},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Pop),
				make_instructions(a, .Cnst, 1),
				make_instructions(a, .Pop),
			},
		},
		{
			"-1",
			{1},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Neg),
				make_instructions(a, .Pop),
			},
		},
		{
			"1 + 2",
			{1, 2},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Cnst, 1),
				make_instructions(a, .Add),
				make_instructions(a, .Pop),
			},
		},
		{
			"1 - 2",
			{1, 2},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Cnst, 1),
				make_instructions(a, .Sub),
				make_instructions(a, .Pop),
			},
		},
		{
			"1 * 2",
			{1, 2},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Cnst, 1),
				make_instructions(a, .Mul),
				make_instructions(a, .Pop),
			},
		},
		{
			"1 / 2",
			{1, 2},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Cnst, 1),
				make_instructions(a, .Div),
				make_instructions(a, .Pop),
			},
		},
	}

	run_compiler_tests(t, tests[:])
}


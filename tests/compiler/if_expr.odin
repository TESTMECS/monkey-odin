package compiler_tests

import monkey "../../src"
import "core:mem/virtual"
import "core:testing"

@(test)
test_compile_if_expression :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	tests := [?]Compiler_Test_Case {
		{
			"if true { 10 }; 3333;",
			{10, 3333},
			{
				make_instructions(a, .True), // 0000
				make_instructions(a, .Jmp_If_Not, 10), // 0001
				make_instructions(a, .Cnst, 0), // 0004
				make_instructions(a, .Jmp, 11), // 0007
				make_instructions(a, .Nil), // 0010
				make_instructions(a, .Pop), // 0011
				make_instructions(a, .Cnst, 1), // 0012
				make_instructions(a, .Pop), // 0015
			},
		},
		{
			"if true { 10 } else { 20 }; 3333;",
			{10, 20, 3333},
			{
				make_instructions(a, .True), // 0000
				make_instructions(a, .Jmp_If_Not, 10), // 0001
				make_instructions(a, .Cnst, 0), // 0004
				make_instructions(a, .Jmp, 13), // 0007
				make_instructions(a, .Cnst, 1), // 0010
				make_instructions(a, .Pop), // 0013
				make_instructions(a, .Cnst, 2), // 0014
				make_instructions(a, .Pop), // 0017
			},
		},
	}

	run_compiler_tests(t, tests[:])
}


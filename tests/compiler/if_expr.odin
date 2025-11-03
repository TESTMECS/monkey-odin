package compiler_tests

import monkey "../../src"
import "core:testing"

@(test)
test_compile_if_expression :: proc(t: ^testing.T) {
	using monkey
	tests := [?]Compiler_Test_Case {
		{
			"if true { 10 }; 3333;",
			{10, 3333},
			{
				make_instructions(context.temp_allocator, .True), // 0000
				make_instructions(context.temp_allocator, .Jmp_If_Not, 10), // 0001
				make_instructions(context.temp_allocator, .Cnst, 0), // 0004
				make_instructions(context.temp_allocator, .Jmp, 11), // 0007
				make_instructions(context.temp_allocator, .Nil), // 0010
				make_instructions(context.temp_allocator, .Pop), // 0011
				make_instructions(context.temp_allocator, .Cnst, 1), // 0012
				make_instructions(context.temp_allocator, .Pop), // 0015
			},
		},
		{
			"if true { 10 } else { 20 }; 3333;",
			{10, 20, 3333},
			{
				make_instructions(context.temp_allocator, .True), // 0000
				make_instructions(context.temp_allocator, .Jmp_If_Not, 10), // 0001
				make_instructions(context.temp_allocator, .Cnst, 0), // 0004
				make_instructions(context.temp_allocator, .Jmp, 13), // 0007
				make_instructions(context.temp_allocator, .Cnst, 1), // 0010
				make_instructions(context.temp_allocator, .Pop), // 0013
				make_instructions(context.temp_allocator, .Cnst, 2), // 0014
				make_instructions(context.temp_allocator, .Pop), // 0017
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}


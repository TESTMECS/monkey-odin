package compiler_tests

import monkey "../../src"
import "core:testing"

@(test)
test_compile_integer_arithmetic :: proc(t: ^testing.T) {
	using monkey
	tests := [?]Compiler_Test_Case {
		{
			"1; 2",
			{1, 2},
			{
				make_instructions(context.allocator, .Cnst, 0),
				make_instructions(context.allocator, .Pop),
				make_instructions(context.allocator, .Cnst, 1),
				make_instructions(context.allocator, .Pop),
			},
		},
		{
			"-1",
			{1},
			{
				make_instructions(context.allocator, .Cnst, 0),
				make_instructions(context.allocator, .Neg),
				make_instructions(context.allocator, .Pop),
			},
		},
		{
			"1 + 2",
			{1, 2},
			{
				make_instructions(context.allocator, .Cnst, 0),
				make_instructions(context.allocator, .Cnst, 1),
				make_instructions(context.allocator, .Add),
				make_instructions(context.allocator, .Pop),
			},
		},
		{
			"1 - 2",
			{1, 2},
			{
				make_instructions(context.allocator, .Cnst, 0),
				make_instructions(context.allocator, .Cnst, 1),
				make_instructions(context.allocator, .Sub),
				make_instructions(context.allocator, .Pop),
			},
		},
		{
			"1 * 2",
			{1, 2},
			{
				make_instructions(context.allocator, .Cnst, 0),
				make_instructions(context.allocator, .Cnst, 1),
				make_instructions(context.allocator, .Mul),
				make_instructions(context.allocator, .Pop),
			},
		},
		{
			"1 / 2",
			{1, 2},
			{
				make_instructions(context.allocator, .Cnst, 0),
				make_instructions(context.allocator, .Cnst, 1),
				make_instructions(context.allocator, .Div),
				make_instructions(context.allocator, .Pop),
			},
		},
	}

	defer free_all(context.allocator)

	run_compiler_tests(t, tests[:])
}


package compiler_tests

import m "../.."
import "core:testing"

@(test)
test_compile_integer_arithmetic :: proc(t: ^testing.T) {
	tests := [?]Compiler_Test_Case {
		{
			"1; 2",
			{1, 2},
			{
				m.make_instructions(context.allocator, .Cnst, 0),
				m.make_instructions(context.allocator, .Pop),
				m.make_instructions(context.allocator, .Cnst, 1),
				m.make_instructions(context.allocator, .Pop),
			},
		},
		{
			"-1",
			{1},
			{
				m.make_instructions(context.allocator, .Cnst, 0),
				m.make_instructions(context.allocator, .Neg),
				m.make_instructions(context.allocator, .Pop),
			},
		},
		{
			"1 + 2",
			{1, 2},
			{
				m.make_instructions(context.allocator, .Cnst, 0),
				m.make_instructions(context.allocator, .Cnst, 1),
				m.make_instructions(context.allocator, .Add),
				m.make_instructions(context.allocator, .Pop),
			},
		},
		{
			"1 - 2",
			{1, 2},
			{
				m.make_instructions(context.allocator, .Cnst, 0),
				m.make_instructions(context.allocator, .Cnst, 1),
				m.make_instructions(context.allocator, .Sub),
				m.make_instructions(context.allocator, .Pop),
			},
		},
		{
			"1 * 2",
			{1, 2},
			{
				m.make_instructions(context.allocator, .Cnst, 0),
				m.make_instructions(context.allocator, .Cnst, 1),
				m.make_instructions(context.allocator, .Mul),
				m.make_instructions(context.allocator, .Pop),
			},
		},
		{
			"1 / 2",
			{1, 2},
			{
				m.make_instructions(context.allocator, .Cnst, 0),
				m.make_instructions(context.allocator, .Cnst, 1),
				m.make_instructions(context.allocator, .Div),
				m.make_instructions(context.allocator, .Pop),
			},
		},
	}

	defer free_all(context.allocator)

	run_compiler_tests(t, tests[:])
}

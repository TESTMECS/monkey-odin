package compiler_tests

import monkey "../../src"
import "core:testing"

@(test)
test_compile_string_expressions :: proc(t: ^testing.T) {
	using monkey
	tests := [?]Compiler_Test_Case {
		{
			`"monkey"`,
			{"monkey"},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			`"mon" + "key"`,
			{"mon", "key"},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Add),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}


package compiler_tests

import m "../.."
import "core:testing"
import "core:fmt"

@(test)
test_compile_string_expressions :: proc(t: ^testing.T) {
	tests := [?]Compiler_Test_Case {
		{
			`"monkey"`,
			{"monkey"},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 0),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			`"mon" + "key"`,
			{"mon", "key"},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 0),
				m.make_instructions(context.temp_allocator, .Cnst, 1),
				m.make_instructions(context.temp_allocator, .Add),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}

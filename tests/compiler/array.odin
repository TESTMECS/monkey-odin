package compiler_tests
import monkey "../../src"
import "core:testing"

@(test)
test_compile_array_literals :: proc(t: ^testing.T) {
	using monkey
	tests := [?]Compiler_Test_Case {
		{
			"[]",
			{},
			{
				make_instructions(context.temp_allocator, .Arr, 0),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"[1, 2, 3]",
			{1, 2, 3},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Cnst, 2),
				make_instructions(context.temp_allocator, .Arr, 3),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"[1 + 2, 3 - 4, 5 * 6]",
			{1, 2, 3, 4, 5, 6},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Add),
				make_instructions(context.temp_allocator, .Cnst, 2),
				make_instructions(context.temp_allocator, .Cnst, 3),
				make_instructions(context.temp_allocator, .Sub),
				make_instructions(context.temp_allocator, .Cnst, 4),
				make_instructions(context.temp_allocator, .Cnst, 5),
				make_instructions(context.temp_allocator, .Mul),
				make_instructions(context.temp_allocator, .Arr, 3),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}


package compiler_tests
import m "../.."
import "core:testing"
@(test)
test_compile_index_expressions :: proc(t: ^testing.T) {
	tests := [?]Compiler_Test_Case {
		{
			"[1, 2, 3][1 + 1]",
			{1, 2, 3, 1, 1},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 0),
				m.make_instructions(context.temp_allocator, .Cnst, 1),
				m.make_instructions(context.temp_allocator, .Cnst, 2),
				m.make_instructions(context.temp_allocator, .Arr, 3),
				m.make_instructions(context.temp_allocator, .Cnst, 3),
				m.make_instructions(context.temp_allocator, .Cnst, 4),
				m.make_instructions(context.temp_allocator, .Add),
				m.make_instructions(context.temp_allocator, .Idx),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			`{"name": "Navid"}["name"]`,
			{"name", "Navid", "name"},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 0),
				m.make_instructions(context.temp_allocator, .Cnst, 1),
				m.make_instructions(context.temp_allocator, .Ht, 2),
				m.make_instructions(context.temp_allocator, .Cnst, 2),
				m.make_instructions(context.temp_allocator, .Idx),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}


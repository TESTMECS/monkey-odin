package compiler_tests
import m "../.."
import "core:testing"
@(test)
test_compile_let_statements_scopes :: proc(t: ^testing.T) {
	tests := [?]Compiler_Test_Case {
		{
			"let num = 55; fn() { num };",
			{
				55,
				[]m.Instructions {
					m.make_instructions(context.temp_allocator, .Get_G, 0),
					m.make_instructions(context.temp_allocator, .Ret_V),
				},
			},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 0),
				m.make_instructions(context.temp_allocator, .Set_G, 0),
				m.make_instructions(context.temp_allocator, .Cnst, 1),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"fn() { let num = 55; num }",
			{
				55,
				[]m.Instructions {
					m.make_instructions(context.temp_allocator, .Cnst, 0),
					m.make_instructions(context.temp_allocator, .Set_L, 0),
					m.make_instructions(context.temp_allocator, .Get_L, 0),
					m.make_instructions(context.temp_allocator, .Ret_V),
				},
			},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 1),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"fn() { let a = 55; let b = 77; a + b }",
			{
				55,
				77,
				[]m.Instructions {
					m.make_instructions(context.temp_allocator, .Cnst, 0),
					m.make_instructions(context.temp_allocator, .Set_L, 0),
					m.make_instructions(context.temp_allocator, .Cnst, 1),
					m.make_instructions(context.temp_allocator, .Set_L, 1),
					m.make_instructions(context.temp_allocator, .Get_L, 0),
					m.make_instructions(context.temp_allocator, .Get_L, 1),
					m.make_instructions(context.temp_allocator, .Add),
					m.make_instructions(context.temp_allocator, .Ret_V),
				},
			},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 2),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}
// test_compile_compilation_scopes :: proc(t: ^testing.T) { todo() }


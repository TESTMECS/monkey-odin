package compiler_tests
import monkey "../../src"
import "core:testing"
@(test)
test_compile_let_statements_scopes :: proc(t: ^testing.T) {
	using monkey
	tests := [?]Compiler_Test_Case {
		{
			"let num = 55; fn() { num };",
			{
				55,
				[]Instructions {
					make_instructions(context.temp_allocator, .Get_G, 0),
					make_instructions(context.temp_allocator, .Ret_V),
				},
			},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Set_G, 0),
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"fn() { let num = 55; num }",
			{
				55,
				[]Instructions {
					make_instructions(context.temp_allocator, .Cnst, 0),
					make_instructions(context.temp_allocator, .Set_L, 0),
					make_instructions(context.temp_allocator, .Get_L, 0),
					make_instructions(context.temp_allocator, .Ret_V),
				},
			},
			{
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"fn() { let a = 55; let b = 77; a + b }",
			{
				55,
				77,
				[]Instructions {
					make_instructions(context.temp_allocator, .Cnst, 0),
					make_instructions(context.temp_allocator, .Set_L, 0),
					make_instructions(context.temp_allocator, .Cnst, 1),
					make_instructions(context.temp_allocator, .Set_L, 1),
					make_instructions(context.temp_allocator, .Get_L, 0),
					make_instructions(context.temp_allocator, .Get_L, 1),
					make_instructions(context.temp_allocator, .Add),
					make_instructions(context.temp_allocator, .Ret_V),
				},
			},
			{
				make_instructions(context.temp_allocator, .Cnst, 2),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}
// test_compile_compilation_scopes :: proc(t: ^testing.T) { todo() }


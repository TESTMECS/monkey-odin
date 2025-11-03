package compiler_tests
import monkey "../../src"
import "core:mem/virtual"
import "core:testing"

@(test)
test_compile_let_statements_scopes :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	tests := [?]Compiler_Test_Case {
		{
			"let num = 55; fn() { num };",
			{55, []Instructions{make_instructions(a, .Get_G, 0), make_instructions(a, .Ret_V)}},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Set_G, 0),
				make_instructions(a, .Cnst, 1),
				make_instructions(a, .Pop),
			},
		},
		{
			"fn() { let num = 55; num }",
			{
				55,
				[]Instructions {
					make_instructions(a, .Cnst, 0),
					make_instructions(a, .Set_L, 0),
					make_instructions(a, .Get_L, 0),
					make_instructions(a, .Ret_V),
				},
			},
			{make_instructions(a, .Cnst, 1), make_instructions(a, .Pop)},
		},
		{
			"fn() { let a = 55; let b = 77; a + b }",
			{
				55,
				77,
				[]Instructions {
					make_instructions(a, .Cnst, 0),
					make_instructions(a, .Set_L, 0),
					make_instructions(a, .Cnst, 1),
					make_instructions(a, .Set_L, 1),
					make_instructions(a, .Get_L, 0),
					make_instructions(a, .Get_L, 1),
					make_instructions(a, .Add),
					make_instructions(a, .Ret_V),
				},
			},
			{make_instructions(a, .Cnst, 2), make_instructions(a, .Pop)},
		},
	}

	run_compiler_tests(t, tests[:])
}


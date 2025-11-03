package compiler_tests

import monkey "../../src"
import "core:mem/virtual"
import "core:testing"

@(test)
test_compile_functions :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	tests := [?]Compiler_Test_Case {
		{
			"fn () { return 5 + 10 }",
			{
				5,
				10,
				[]Instructions {
					make_instructions(a, .Cnst, 0),
					make_instructions(a, .Cnst, 1),
					make_instructions(a, .Add),
					make_instructions(a, .Ret_V),
				},
			},
			{make_instructions(a, .Cnst, 2), make_instructions(a, .Pop)},
		},
		{
			"fn () { 5 + 10 }",
			{
				5,
				10,
				[]Instructions {
					make_instructions(a, .Cnst, 0),
					make_instructions(a, .Cnst, 1),
					make_instructions(a, .Add),
					make_instructions(a, .Ret_V),
				},
			},
			{make_instructions(a, .Cnst, 2), make_instructions(a, .Pop)},
		},
		{
			"fn () { 1; 2 }",
			{
				1,
				2,
				[]Instructions {
					make_instructions(a, .Cnst, 0),
					make_instructions(a, .Pop),
					make_instructions(a, .Cnst, 1),
					make_instructions(a, .Ret_V),
				},
			},
			{make_instructions(a, .Cnst, 2), make_instructions(a, .Pop)},
		},
		{
			"fn () { }",
			{[]Instructions{make_instructions(a, .Ret)}},
			{make_instructions(a, .Cnst, 0), make_instructions(a, .Pop)},
		},
	}

	run_compiler_tests(t, tests[:])
}

@(test)
test_compile_function_calls :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	tests := [?]Compiler_Test_Case {
		{
			"fn () { 24 }();",
			{
				24,
				[]Instructions {
					make_instructions(a, .Cnst, 0), // the literal "24"
					make_instructions(a, .Ret_V),
				},
			},
			{
				make_instructions(a, .Cnst, 1), // the compiled function
				make_instructions(a, .Call, 0),
				make_instructions(a, .Pop),
			},
		},
		{
			"let no_arg = fn () { 24 }; no_arg();",
			{
				24,
				[]Instructions {
					make_instructions(a, .Cnst, 0), // the literal "24"
					make_instructions(a, .Ret_V),
				},
			},
			{
				make_instructions(a, .Cnst, 1), // the compiled function
				make_instructions(a, .Set_G, 0),
				make_instructions(a, .Get_G, 0),
				make_instructions(a, .Call, 0),
				make_instructions(a, .Pop),
			},
		},
		{
			"let one_arg = fn (a) { a }; one_arg(24);",
			{[]Instructions{make_instructions(a, .Get_L, 0), make_instructions(a, .Ret_V)}, 24},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Set_G, 0),
				make_instructions(a, .Get_G, 0),
				make_instructions(a, .Cnst, 1),
				make_instructions(a, .Call, 1),
				make_instructions(a, .Pop),
			},
		},
		{
			"let many_args = fn (a, b, c) { a; b; c }; many_args(24, 25, 26);",
			{
				[]Instructions {
					make_instructions(a, .Get_L, 0),
					make_instructions(a, .Pop),
					make_instructions(a, .Get_L, 1),
					make_instructions(a, .Pop),
					make_instructions(a, .Get_L, 2),
					make_instructions(a, .Ret_V),
				},
				24,
				25,
				26,
			},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Set_G, 0),
				make_instructions(a, .Get_G, 0),
				make_instructions(a, .Cnst, 1),
				make_instructions(a, .Cnst, 2),
				make_instructions(a, .Cnst, 3),
				make_instructions(a, .Call, 3),
				make_instructions(a, .Pop),
			},
		},
	}

	run_compiler_tests(t, tests[:])
}


package compiler_tests

import monkey "../../src"
import "core:mem/virtual"
import "core:testing"

@(test)
test_compile_string_expressions :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	tests := [?]Compiler_Test_Case {
		{`"monkey"`, {"monkey"}, {make_instructions(a, .Cnst, 0), make_instructions(a, .Pop)}},
		{
			`"mon" + "key"`,
			{"mon", "key"},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Cnst, 1),
				make_instructions(a, .Add),
				make_instructions(a, .Pop),
			},
		},
	}

	run_compiler_tests(t, tests[:])
}


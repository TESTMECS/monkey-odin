package compiler_tests

import monkey "../../src"
import "core:mem/virtual"
import "core:testing"

@(test)
test_compile_boolean_expressions :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	tests := [?]Compiler_Test_Case {
		{"true", {}, {make_instructions(a, .True), make_instructions(a, .Pop)}},
		{"false", {}, {make_instructions(a, .False), make_instructions(a, .Pop)}},
		{
			"!true",
			{},
			{make_instructions(a, .True), make_instructions(a, .Not), make_instructions(a, .Pop)},
		},
		{
			"1 > 2",
			{1, 2},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Cnst, 1),
				make_instructions(a, .Gt),
				make_instructions(a, .Pop),
			},
		},
		{
			"1 < 2",
			{1, 2},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Cnst, 1),
				make_instructions(a, .Lt),
				make_instructions(a, .Pop),
			},
		},
		{
			"1 == 2",
			{1, 2},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Cnst, 1),
				make_instructions(a, .Eq),
				make_instructions(a, .Pop),
			},
		},
		{
			"1 != 2",
			{1, 2},
			{
				make_instructions(a, .Cnst, 0),
				make_instructions(a, .Cnst, 1),
				make_instructions(a, .Neq),
				make_instructions(a, .Pop),
			},
		},
		{
			"true == false",
			{},
			{
				make_instructions(a, .True),
				make_instructions(a, .False),
				make_instructions(a, .Eq),
				make_instructions(a, .Pop),
			},
		},
		{
			"true != false",
			{},
			{
				make_instructions(a, .True),
				make_instructions(a, .False),
				make_instructions(a, .Neq),
				make_instructions(a, .Pop),
			},
		},
	}

	run_compiler_tests(t, tests[:])
}


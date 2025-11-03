package compiler_tests

import monkey "../../src"
import "core:testing"

@(test)
test_compile_boolean_expressions :: proc(t: ^testing.T) {
	using monkey
	tests := [?]Compiler_Test_Case {
		{
			"true",
			{},
			{
				make_instructions(context.temp_allocator, .True),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"false",
			{},
			{
				make_instructions(context.temp_allocator, .False),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"!true",
			{},
			{
				make_instructions(context.temp_allocator, .True),
				make_instructions(context.temp_allocator, .Not),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"1 > 2",
			{1, 2},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Gt),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"1 < 2",
			{2, 1},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Gt),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"1 == 2",
			{1, 2},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Eq),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"1 != 2",
			{1, 2},
			{
				make_instructions(context.temp_allocator, .Cnst, 0),
				make_instructions(context.temp_allocator, .Cnst, 1),
				make_instructions(context.temp_allocator, .Neq),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"true == false",
			{},
			{
				make_instructions(context.temp_allocator, .True),
				make_instructions(context.temp_allocator, .False),
				make_instructions(context.temp_allocator, .Eq),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"true != false",
			{},
			{
				make_instructions(context.temp_allocator, .True),
				make_instructions(context.temp_allocator, .False),
				make_instructions(context.temp_allocator, .Neq),
				make_instructions(context.temp_allocator, .Pop),
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}


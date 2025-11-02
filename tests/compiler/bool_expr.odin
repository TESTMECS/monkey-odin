package compiler_tests

import m "../.."
import "core:testing"

@(test)
test_compile_boolean_expressions :: proc(t: ^testing.T) {
	tests := [?]Compiler_Test_Case {
		{
			"true",
			{},
			{
				m.make_instructions(context.temp_allocator, .True),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"false",
			{},
			{
				m.make_instructions(context.temp_allocator, .False),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"!true",
			{},
			{
				m.make_instructions(context.temp_allocator, .True),
				m.make_instructions(context.temp_allocator, .Not),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"1 > 2",
			{1, 2},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 0),
				m.make_instructions(context.temp_allocator, .Cnst, 1),
				m.make_instructions(context.temp_allocator, .Gt),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"1 < 2",
			{2, 1},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 0),
				m.make_instructions(context.temp_allocator, .Cnst, 1),
				m.make_instructions(context.temp_allocator, .Gt),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"1 == 2",
			{1, 2},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 0),
				m.make_instructions(context.temp_allocator, .Cnst, 1),
				m.make_instructions(context.temp_allocator, .Eq),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"1 != 2",
			{1, 2},
			{
				m.make_instructions(context.temp_allocator, .Cnst, 0),
				m.make_instructions(context.temp_allocator, .Cnst, 1),
				m.make_instructions(context.temp_allocator, .Neq),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"true == false",
			{},
			{
				m.make_instructions(context.temp_allocator, .True),
				m.make_instructions(context.temp_allocator, .False),
				m.make_instructions(context.temp_allocator, .Eq),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
		{
			"true != false",
			{},
			{
				m.make_instructions(context.temp_allocator, .True),
				m.make_instructions(context.temp_allocator, .False),
				m.make_instructions(context.temp_allocator, .Neq),
				m.make_instructions(context.temp_allocator, .Pop),
			},
		},
	}

	defer free_all(context.temp_allocator)

	run_compiler_tests(t, tests[:])
}

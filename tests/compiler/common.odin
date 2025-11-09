package compiler_tests

import monkey "../../src"
import test_commons "../../tests_commons"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:mem/virtual"
import "core:reflect"
import "core:strings"
import "core:testing"


@(private = "file")
Compiler_Test_Data :: union {
	int,
	f64,
	string,
	[]monkey.Instructions,
}

Compiler_Test_Case :: struct {
	input:                 string,
	expected_constants:    []Compiler_Test_Data,
	expected_instructions: []monkey.Instructions,
}

tc :: test_commons

run_compiler_tests :: proc(t: ^testing.T, tests: []Compiler_Test_Case) {
	using monkey
	using tc

	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()
	cli_args := []string{""}

	for test_case, i in tests {
		p := Parser_New(test_case.input, a)
		program := p->parse()
		if len(program) == 0 || len(p.errors) != 0 {
			log.errorf("Parsing encountered errors on test_case[%d]", i)
			for e in p.errors {
				log.error(e)
			}
			continue
		}
		c := Compiler_New(a, cli_args)
		err := c->compile_program(program)
		if err != "" {
			log.errorf("Compiling encountered errors on test_case[%d]", i)
			log.error(err)
			continue
		}
		bytecode := c->bytecode()
		err = test_instructions(
			test_case.expected_instructions[:],
			bytecode.instructions,
			context.allocator,
		)
		if err != "" {
			log.errorf("Instructions for test_case[%d] failed with: %v", i, err)
			continue
		}
		err = test_constants(test_case.expected_constants, bytecode.constants, context.allocator)
		if err != "" {
			log.errorf("Constants for test_case[%d] failed with: %v", i, err)
			continue
		}
	}
}

test_constants :: proc(
	expected: []Compiler_Test_Data,
	actual: []monkey.ObjectBase,
	alloc: mem.Allocator,
) -> (
	err: string,
) {
	using monkey
	using tc
	if len(expected) != len(actual) {
		return fmt.tprintf(
			"wrong number of constants. wants='%d', got='%d'",
			len(expected),
			len(actual),
		)
	}

	err = ""

	for constant, i in expected {
		t := reflect.union_variant_typeid(constant)

		switch constant_value in constant {
		case int:
			err = test_integer_object(constant_value, actual[i])
		case f64:
			err = test_float_object(constant_value, actual[i])
		case string:
			err = test_string_object(constant_value, actual[i])
		case []Instructions:
			fn, ok := actual[i].(ObjectCompiledFunction)
			if !ok {
				err = fmt.tprintf("not a function: '%v'", ObjectType(actual[i]))
			}
			 else {
				err = test_instructions(constant_value, fn.instructions[:], alloc)
			}
		}

		if err != "" {
			err = fmt.tprintf("constant '%v' - testing '%v' object failed with: %v", i, t, err)
			break
		}

	}

	return
}

test_instructions :: proc(
	expected: []monkey.Instructions,
	actual: []byte,
	alloc: mem.Allocator,
) -> (
	err: string,
) {
	using monkey
	using tc

	concatenated := concat_instructions(expected)
	expected_ins := byte_to_instruction(concatenated[:])
	actual_ins := byte_to_instruction(actual)

	if len(expected_ins) == len(actual_ins) {
		return ""
	}
	n := len(concatenated)
	for ins, i in concatenated {
		if ins == actual[i] {
			n -= 1
		}
	}
	if n == 0 {
		return "" // all instructions matched
	}

	max_len := max(len(expected_ins), len(actual_ins))
	builder := strings.builder_make(alloc)
	defer strings.builder_destroy(&builder)

	fmt.sbprintf(
		&builder,
		"Instruction mismatch:\n\n%-5s | %-15s | %-15s | %s\n",
		"Idx",
		"Expected",
		"Actual",
		"Match?",
	)
	fmt.sbprintf(&builder, "-------------------------------------------------------------\n")

	exp: string
	act: string
	match: string
	i: int
	for i in 0 ..< max_len {
		if i < len(expected_ins) {
			exp = expected_ins[i]
		}
		 else {
			exp = "<none>"
		}
		if i < len(actual_ins) {
			act = actual_ins[i]
		}
		 else {
			act = "<none>"
		}
		if exp == act {
			match = "✓"
		}
		 else {
			match = "✗"
		}
		fmt.sbprintf(&builder, "%-5d | %-15s | %-15s | %s\n", i, exp, act, match)
	}

	return strings.to_string(builder)
}

byte_to_instruction :: proc(bs: []byte) -> []string {
	using monkey
	ins := make([dynamic]string, 0, len(bs))
	for opcode_val, idx in bs {
		val := fmt.tprintf("%v", Opcode(opcode_val)) // Convert to Opcode string instead of enum int.
		append(&ins, val)
	}
	return ins[:]
}


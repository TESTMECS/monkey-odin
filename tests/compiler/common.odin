package compiler_tests

import monkey "../../src"
import test_commons "../../tests_commons"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:mem/virtual"
import "core:reflect"
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
		c := Compiler_New(a)
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
			} else {
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
	if (len(actual) != len(concatenated)) {
		return fmt.tprintf(
			"wrong number of instructions. wants='%v', got='%v'",
			concatenated,
			actual,
		)
	}
	for ins, i in concatenated {
		if actual[i] != ins {
			return fmt.tprintf(
				"wrong instruction at '%d'. wants='%v', got='%v'",
				i,
				concatenated,
				actual,
			)
		}
	}
	return ""
}


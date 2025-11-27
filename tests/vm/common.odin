package vm_tests
import monkey "../../src"
import test_commons "../../tests_commons"
import "core:log"
import "core:mem/virtual"
import "core:testing"
/*
* Copyright (C) 2025 TESTMEE
* ./tests/vm/common.odin
*/
tc :: test_commons
VM_Test_Cases :: struct {
	input:    string,
	expected: tc.Test_Data,
}
run_vm_tests :: proc(t: ^testing.T, tests: []VM_Test_Cases) {
	using monkey
	using tc

	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	for test_case, i in tests {
		p := Parser_New(test_case.input, a)
		program := p->parse()
		if parser_has_error(p) do return

		compiler := Compiler_New(a, []string{""})
		err := compiler->compile_program(program)
		if err != "" {
			log.errorf("test [%d] has failed, compiler has error: %s", i, err)
			continue
		}

		vm := Vm_New(compiler->bytecode(), &compiler, a)
		err = vm->run_vm()
		if err != "" {
			log.errorf("test [%d] has failed, vm has error: %s", i, err)
			continue
		}

		last_popped := vm->last_popped()
		err = test_expected_object(t, test_case.expected, last_popped)

		if err != "" {
			log.errorf(
				"test [%d] has failed, expected: '%v', got: '%v'",
				i,
				test_case.expected,
				last_popped,
			)
			continue
		}
	}
}


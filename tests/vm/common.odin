package vm_tests

import monkey "../../src"
import "core:log"
import "core:testing"

VM_Test_Cases :: struct {
	input:    string,
	expected: monkey.Test_Data,
}

run_vm_tests :: proc(t: ^testing.T, tests: []VM_Test_Cases) {
	using monkey
	for test_case, i in tests {
		p := Parser__New__(test_case.input)
		defer p->free()

		program := p->parse()
		if parser_has_error(p) do return

		compiler := Compiler__New__()
		defer compiler->free()

		err := compiler->compile_program(program)
		if err != "" {
			log.errorf("test [%d] has failed, compiler has error: %s", i, err)
			continue
		}

		vm := Vm_New(compiler->bytecode(), &compiler.compiler_state)
		defer vm->free_vm()

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


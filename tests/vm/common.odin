package vm_tests

import m "../.."
import "core:log"
import "core:testing"

VM_Test_Cases :: struct {
	input:    string,
	expected: m.Test_Data,
}

run_vm_tests :: proc(t: ^testing.T, tests: []VM_Test_Cases) {
	for test_case, i in tests {
		p := m.Parser__New__(test_case.input)
		defer p->free()

		program := p->parse()
		if m.parser_has_error(p) do return

		compiler := m.Compiler__New__()
		defer compiler->free()

		err := compiler->compile_program(program)
		if err != "" {
			log.errorf("test [%d] has failed, compiler has error: %s", i, err)
			continue
		}

		vm := m.Vm_New(compiler->bytecode(), &compiler.compiler_state)
		defer vm->free_vm()

		err = vm->run_vm()
		if err != "" {
			log.errorf("test [%d] has failed, vm has error: %s", i, err)
			continue
		}

		last_popped := vm->last_popped()
		err = m.test_expected_object(t, test_case.expected, last_popped)

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


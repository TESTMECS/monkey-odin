package vm_tests

import "core:testing"

@(test)
test_vm_integer_arithmetic :: proc(t: ^testing.T) {
	tests := []VM_Test_Cases {
		{"1", 1},
		{"2", 2},
		{"-5", -5},
		{"1 + 2", 3},
		{"3 - 1", 2},
		{"2 * 2", 4},
		{"4 / 2", 2},
		{"5 + 5 + 5 + 5 - 10", 10},
		{"2 * 2 * 2 * 2 * 2", 32},
		{"5 * 2 + 10", 20},
		{"5 + 2 * 10", 25},
		{"5 * (2 + 10)", 60},
		{"-50 + 100 + -50", 0},
	}

	defer free_all(context.temp_allocator)

	run_vm_tests(t, tests)
}


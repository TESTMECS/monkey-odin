package vm_tests

import "core:testing"

@(test)
test_vm_array_literals :: proc(t: ^testing.T) {
	tests := []VM_Test_Cases {
		{"[]", []int{}},
		{"[1, 2, 3]", []int{1, 2, 3}},
		{"[1 + 2, 3 * 4, 5 + 6]", []int{3, 12, 11}},
	}

	defer free_all(context.temp_allocator)

	run_vm_tests(t, tests)
}


#+feature dynamic-literals
package vm_tests

import "core:testing"

@(test)
test_vm_hash_table_literals :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	tests := []VM_Test_Cases {
		{"{}", map[string]int{}},
		{`{"drew": 1, "xavier": 2}`, map[string]int{"drew" = 1, "xavier" = 2}},
		{`{"drew": 2 * 2, "xavier":  4 + 4}`, map[string]int{"drew" = 4, "xavier" = 8}},
	}

	defer free_all(context.temp_allocator)

	run_vm_tests(t, tests)
}


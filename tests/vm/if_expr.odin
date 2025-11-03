package vm_tests
import "core:testing"
@(test)
test_vm_if_expressions :: proc(t: ^testing.T) {
	tests := []VM_Test_Cases {
		{"if true { 10 }", 10},
		{"if false { 10 }", nil},
		{"if 1 > 2 { 10 }", nil},
		{"if true { 10 } else { 20 }", 10},
		{"if false { 10 } else { 20 }", 20},
		{"if 1 { 10 }", 10},
		{"if 1 < 2 { 10 }", 10},
		{"if 1 < 2 { 10 } else { 20 }", 10},
		{"if 1 > 2 { 10 } else { 20 }", 20},
		{"if (if false { 10 }) { 10 } else { 20 }", 20},
	}

	defer free_all(context.temp_allocator)

	run_vm_tests(t, tests)
}


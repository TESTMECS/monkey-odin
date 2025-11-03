package vm_tests
import "core:testing"
@(test)
test_vm_global_let_statement :: proc(t: ^testing.T) {
	tests := []VM_Test_Cases {
		{"let one = 1; one", 1},
		{"let one = 1; let two = 2; one + two", 3},
		{"let one = 1; let two = one + one; one + two", 3},
	}

	defer free_all(context.temp_allocator)

	run_vm_tests(t, tests)
}


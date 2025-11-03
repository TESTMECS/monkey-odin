package vm_tests
import "core:testing"

@(test)
test_vm_string_expressions :: proc(t: ^testing.T) {
	tests := []VM_Test_Cases {
		{`"monkey`, "monkey"},
		{`"mon" + "key"`, "monkey"},
		{`"mon" + "key" + "banana"`, "monkeybanana"},
	}

	defer free_all(context.temp_allocator)

	run_vm_tests(t, tests)
}


package vm_tests
import "core:testing"

@(test)
test_vm_index_expressions :: proc(t: ^testing.T) {
	tests := []VM_Test_Cases {
		{"[1, 2, 3][1]", 2},
		{"[1, 2, 3][0 + 2]", 3},
		{"[[1, 1, 1]][0][0]", 1},
		{"[][0]", nil},
		{"[1, 2, 3][99]", nil},
		{"[1][-1]", nil},
		{`{"name": "Navid"}["name"]`, "Navid"},
		{`{"name": "Navid"}["age"]`, nil},
		{`{}["name"]`, nil},
	}

	defer free_all(context.temp_allocator)

	run_vm_tests(t, tests)
}


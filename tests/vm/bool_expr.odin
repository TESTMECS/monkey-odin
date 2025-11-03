package vm_tests

import "core:testing"

@(test)
test_vm_boolean_expressions :: proc(t: ^testing.T) {
	tests := []VM_Test_Cases {
		{"true", true},
		{"false", false},
		{"!true", false},
		{"!false", true},
		{"1 < 2", true},
		{"1 > 2", false},
		{"1 < 1", false},
		{"1 > 1", false},
		{"1 == 1", true},
		{"1 != 1", false},
		{"1 == 2", false},
		{"1 != 2", true},
		{"true == true", true},
		{"false == false", true},
		{"true == false", false},
		{"true != false", true},
		{"false != true", true},
		{"(1 < 2) == true", true},
		{"(1 < 2) == false", false},
		{"(1 > 2) == true", false},
		{"(1 > 2) == false", true},
		{"!5", false},
		{"!!true", true},
		{"!!5", true},
		{"!(if false { 5; })", true},
	}

	defer free_all(context.temp_allocator)

	run_vm_tests(t, tests)
}


package vm_tests

import "core:testing"

@(test)
test_vm_calling_functions_without_arguments :: proc(t: ^testing.T) {
	tests := []VM_Test_Cases {
		{`
	let five_plus_ten = fn() { 5 + 10; };
	five_plus_ten();
		`, 15},
		{`
		let one = fn() { 1; };
		let two = fn() { 2; };
		one() + two()
			`, 3},
		{`	let a = fn() { 1; };
	let b = fn() { a() + 1 };
	let c = fn() { b() + 1 };
	c()
		`, 3},
		{`
	let no_return = fn() {};
	no_return();
			`, nil},
		{
			`
	let no_return = fn() {};
	let no_return_two = fn() { no_return(); };
	no_return();
	no_return_two();
			`,
			nil,
		},
	}

	defer free_all(context.temp_allocator)

	run_vm_tests(t, tests)
}


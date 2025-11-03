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


@(test)
test_vm_calling_functions_with_return_statements :: proc(t: ^testing.T) {
	tests := []VM_Test_Cases {
		{`
	let early_exit = fn() { return 99; 100; };
	early_exit();
		`, 99},
		{`
	let early_exit = fn() { return 99; return 100; };
	early_exit();
		`, 99},
	}

	defer free_all(context.temp_allocator)

	run_vm_tests(t, tests)
}

@(test)
test_vm_first_class_functions :: proc(t: ^testing.T) {
	tests := []VM_Test_Cases {
		{
			`
	let return_one_returner = fn() { 
		let return_one = fn() { 1; };
		return_one 
	};
	return_one_returner()();
		`,
			1,
		},
	}

	defer free_all(context.temp_allocator)

	run_vm_tests(t, tests)
}

@(test)
test_vm_calling_functions_with_bindings :: proc(t: ^testing.T) {
	tests := []VM_Test_Cases {
		{`
	let one = fn() { let one = 1; one };
	one()
		`, 1},
		{`let one_and_two = fn() { let one = 1; let two = 2; one + two };
			one_and_two()`, 3},
		{
			`let one_and_two = fn() { let one = 1; let two = 2; one + two; };
		  let three_and_four = fn() { let three = 3; let four = 4; three + four; };
		  one_and_two() + three_and_four()`,
			10,
		},
		{
			`let first_foobar = fn() { let foobar = 50; foobar; };
			 let second_foobar = fn() { let foobar = 100; foobar; };
			 first_foobar() + second_foobar()`,
			150,
		},
		{
			`
			let global_seed = 50;
			let minus_one = fn() {
				let num = 1;
				global_seed - num;
			};
			let minus_two = fn() {
				let num = 2;
				global_seed - num;
			};
			minus_one() + minus_two()
			`,
			97,
		},
	}

	defer free_all(context.temp_allocator)

	run_vm_tests(t, tests)
}

@(test)
test_vm_calling_functions_with_arguments_and_bindings :: proc(t: ^testing.T) {
	tests := []VM_Test_Cases {
		{`
	let identity = fn(a) { a };
	identity(4)
		`, 4},
		{`let sum = fn(a, b) { a + b };
		  sum(1, 2)`, 3},
		{`let sum = fn(a, b) {
 			 let c = a + b;
			 c
		  };
		  sum(1, 2)`, 3},
		{`let sum = fn(a, b) {
		 	 let c = a + b;
			 c
		  };
		  sum(1, 2) + sum(3, 4)`, 10},
		{
			`let sum = fn(a, b) {
				let c = a + b;
				c
		  	 };
		  	 let outer = fn() {
		  		sum(1, 2) + sum(3, 4)
		  	 };
		  	 outer()`,
			10,
		},
		{
			`
			let global_num = 10;

			let sum = fn(a, b) {
				let c = a + b;
				c + global_num
			};

			let outer = fn() {
				sum(1, 2) + sum(3, 4) + global_num
			};

			outer() + global_num
		  	 `,
			50,
		},
	}

	defer free_all(context.temp_allocator)

	run_vm_tests(t, tests)
}


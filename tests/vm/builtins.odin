package vm_tests

import "core:testing"

@(test)
test_typeof :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases {
		{`typeof(1);`, "int"},
		{`typeof("1");`, "string"},
		{`typeof(typeof);`, "function"},
		{`typeof(typeof(typeof));`, "function"},
		{`typeof(typeof(typeof(typeof)));`, "function"},
	}
	run_vm_tests(t, tests)
}

@(test)
test_puts :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases{{`puts("Hello, World!")`, "Hello, World!"}}
	run_vm_tests(t, tests)
}

@(test)
test_printf :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases{{`printf("%s", "printf is alive")`, "printf is alive"}}
	run_vm_tests(t, tests)
}

@(test)
test_int :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases{{`int(1);`, 1}, {`int("1");`, 1}}
	run_vm_tests(t, tests)
}

@(test)
test_str :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases{{`str(1);`, "1"}, {`str("1");`, "1"}}
	run_vm_tests(t, tests)
}

@(test)
test_abs :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases{{`abs(-1);`, 1}, {`abs(1);`, 1}}
	run_vm_tests(t, tests)
}

@(test)
test_quote :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases {
		{`quote(1);`, 1},
		{`quote(puts("1")); `, "puts(\"1\")"},
		{`quote(quote("1"));`, `quote("1")`},
		{`quote([1,2,3]);`, `[1, 2, 3]`},
		{`quote({"name": 1});`, `{"name": 1}`},
		{`quote(fn(a, b) { a + b });`, `fn(a, b) { a + b }`},
	}
	run_vm_tests(t, tests)
}

@(test)
test_unquote :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases{{`unquote(1);`, 1}}
	run_vm_tests(t, tests)
}


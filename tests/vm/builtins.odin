package vm_tests

import "core:testing"

@(test)
test_hash :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases{{`hash("hello");`, "5d41402abc4b2a76b9719d911017c592"}}
	run_vm_tests(t, tests)
}

@(test)
test_rest :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases{{`rest([1,2,3]);`, `[2, 3]`}}
	run_vm_tests(t, tests)
}

@(test)
test_first :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases{{`first([1,2,3]);`, 1}}
	run_vm_tests(t, tests)
}

@(test)
test_last :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases{{`last([1,2,3]);`, 3}}
	run_vm_tests(t, tests)
}

@(test)
test_push :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases {
		{`push([1,2,3], 4);`, `[1, 2, 3, 4]`},
		{`push([1,2,3], 5);`, `[1, 2, 3, 5]`},
		{`push([1,2,3], "str");`, `[1, 2, 3, "str"]`},
		{`push([1,2,3], true);`, `[1, 2, 3, true]`},
		{`push([1,2,3], [1,2]);`, `[1, 2, 3, [1, 2]]`},
	}
	run_vm_tests(t, tests)
}

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

@(test)
test_len :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases {
		{`len([]);`, 0},
		{`len([1]);`, 1},
		{`len([1,2,3]);`, 3},
		{`len("hello");`, 5},
	}
	run_vm_tests(t, tests)
}

@(test)
test_keys :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases {
		{`keys({});`, []string{}},
		{`keys({"a": 1});`, []string{"a"}},
		{`keys({"a": 1, "b": 2});`, []string{"a", "b"}},
	}
	run_vm_tests(t, tests)
}

@(test)
test_values :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases {
		{`values({});`, []int{}},
		{`values({"a": 1});`, []int{1}},
		{`values({"a": 1, "b": 2});`, []int{1, 2}},
		{`values({"one": "hello", "two": "world"});`, []string{"hello", "world"}},
	}
	run_vm_tests(t, tests)
}

@(test)
test_has :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases {
		{`has({}, "a");`, false},
		{`has({"a": 1}, "a");`, true},
		{`has({"a": 1}, "b");`, false},
		{`has({"a": 1, "b": 2}, "b");`, true},
		{`has({"one": "hello", "two": "world"}, "one");`, true},
		{`has({"one": "hello", "two": "world"}, "three");`, false},
	}
	run_vm_tests(t, tests)
}


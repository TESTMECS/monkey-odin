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

@(test)
test_sort :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases {
		{`sort([]);`, []int{}},
		{`sort([1]);`, []int{1}},
		{`sort([3, 1, 2]);`, []int{1, 2, 3}},
		{`sort([5, 4, 3, 2, 1]);`, []int{1, 2, 3, 4, 5}},
		{`sort([1, 2, 3, 4, 5]);`, []int{1, 2, 3, 4, 5}},
	}
	run_vm_tests(t, tests)
}

@(test)
test_reverse :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases {
		{`reverse([]);`, []int{}},
		{`reverse([1]);`, []int{1}},
		{`reverse([1, 2, 3]);`, []int{3, 2, 1}},
		{`reverse(["a", "b", "c"]);`, []string{"c", "b", "a"}},
	}
	run_vm_tests(t, tests)
}

@(test)
test_slice :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases {
		{`slice([1, 2, 3, 4, 5], 0, 3);`, []int{1, 2, 3}},
		{`slice([1, 2, 3, 4, 5], 1, 4);`, []int{2, 3, 4}},
		{`slice([1, 2, 3, 4, 5], 2, 5);`, []int{3, 4, 5}},
		{`slice([1, 2, 3, 4, 5], 0, 0);`, []int{}},
		{`slice(["a", "b", "c", "d"], 1, 3);`, []string{"b", "c"}},
	}
	run_vm_tests(t, tests)
}

@(test)
test_indexOf :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases {
		{`indexOf([1, 2, 3, 4, 5], 3);`, 2},
		{`indexOf([1, 2, 3, 4, 5], 1);`, 0},
		{`indexOf([1, 2, 3, 4, 5], 5);`, 4},
		{`indexOf([1, 2, 3, 4, 5], 6);`, -1},
		{`indexOf(["a", "b", "c"], "b");`, 1},
		{`indexOf(["a", "b", "c"], "d");`, -1},
	}
	run_vm_tests(t, tests)
}

@(test)
test_sum :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases {
		{`sum([]);`, 0},
		{`sum([1]);`, 1},
		{`sum([1, 2, 3]);`, 6},
		{`sum([5, 10, 15]);`, 30},
		{`sum([-1, 1, -2, 2]);`, 0},
	}
	run_vm_tests(t, tests)
}

@(test)
test_min :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases {
		{`min([1]);`, 1},
		{`min([3, 1, 2]);`, 1},
		{`min([5, 4, 3, 2, 1]);`, 1},
		{`min([1, 2, 3, 4, 5]);`, 1},
		{`min([-5, -1, -3]);`, -5},
	}
	run_vm_tests(t, tests)
}

@(test)
test_max :: proc(t: ^testing.T) {
	using tc
	tests := []VM_Test_Cases {
		{`max([1]);`, 1},
		{`max([3, 1, 2]);`, 3},
		{`max([5, 4, 3, 2, 1]);`, 5},
		{`max([1, 2, 3, 4, 5]);`, 5},
		{`max([-5, -1, -3]);`, -1},
	}
	run_vm_tests(t, tests)
}


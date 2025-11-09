package compiler_tests

import monkey "../../src"
import "core:mem/virtual"
import "core:testing"

@(test)
test_method_calling :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	//TODO
	tests := [?]Compiler_Test_Case {
		"let point = class() { let new = fn(self, x, y) { self.x = x; self.y = y; }; }; let p = point(); p->new(1, 2);",
		{1, 2, []Instructions{}},
		{},
	}

	run_compiler_tests(t, tests[:])
}


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

	tests := [?]Compiler_Test_Case {
		{
			"let point = class() { let new = fn(self, x, y) { self.x = x; self.y = y; }; }; let p = point(); p->new(1, 2);",
			{
				1,
				2,
				[]Instructions {
					make_instructions(a, .Get_L, 0), // self
					make_instructions(a, .Get_L, 1), // x
					make_instructions(a, .Set_L, 0), // self.x = x
					make_instructions(a, .Get_L, 0), // self
					make_instructions(a, .Get_L, 2), // y
					make_instructions(a, .Set_L, 1), // self.y = y
					make_instructions(a, .Get_L, 0), // return self
					make_instructions(a, .Ret_V),
				},
				"new", // method name
			},
			{
				make_instructions(a, .Cnst, 0), // compiled class
				make_instructions(a, .Set_G, 0), // let point = class
				make_instructions(a, .Get_G, 0), // point
				make_instructions(a, .Call, 0), // point()
				make_instructions(a, .Set_G, 1), // let p = point()
				make_instructions(a, .Get_G, 1), // p
				make_instructions(a, .Cnst, 1), // "new" method name
				make_instructions(a, .Get_Method), // get method
				make_instructions(a, .Cnst, 2), // 1
				make_instructions(a, .Cnst, 3), // 2
				make_instructions(a, .Call, 2), // p->new(1, 2)
				make_instructions(a, .Pop), // pop result
			},
		},
		{
			"let counter = class() { let increment = fn(self, amount) { self.value = self.value + amount; return self.value; }; }; let c = counter(); c->increment(5);",
			{
				5,
				[]Instructions {
					make_instructions(a, .Get_L, 0), // self
					make_instructions(a, .Get_Field, 0), // self.value
					make_instructions(a, .Get_L, 1), // amount
					make_instructions(a, .Add), // self.value + amount
					make_instructions(a, .Set_L, 0), // self.value = result
					make_instructions(a, .Get_L, 0), // self
					make_instructions(a, .Get_Field, 0), // self.value
					make_instructions(a, .Ret_V), // return self.value
				},
				"increment", // method name
				"value", // field name
			},
			{
				make_instructions(a, .Cnst, 0), // compiled class
				make_instructions(a, .Set_G, 0), // let counter = class
				make_instructions(a, .Get_G, 0), // counter
				make_instructions(a, .Call, 0), // counter()
				make_instructions(a, .Set_G, 1), // let c = counter()
				make_instructions(a, .Get_G, 1), // c
				make_instructions(a, .Cnst, 1), // "increment" method name
				make_instructions(a, .Get_Method), // get method
				make_instructions(a, .Cnst, 2), // 5
				make_instructions(a, .Call, 1), // c->increment(5)
				make_instructions(a, .Pop), // pop result
			},
		},
	}

	run_compiler_tests(t, tests[:])
}


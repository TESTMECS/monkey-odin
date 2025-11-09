package parser_tests

import monkey "../../src"
import "core:log"
import "core:mem/virtual"
import "core:testing"


@(test)
test_method_parsing :: proc(t: ^testing.T) {
	using monkey
	using tc

	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	// Test basic class without inheritance
	input := "let point = class() { let new = fn(self, x, y) { self.x = x; self.y = y; }; } let p = point(); p.new(1, 2);"
	parser := monkey.Parser_New(input, a)
	program := parser.parse(&parser)

	if len(parser.errors) > 0 {
		log.errorf("parser has errors: %v", parser.errors)
		return
	}

	for stmt in program {
		if stmt, ok := stmt.(monkey.Ast_Let); ok {
			if class_node, ok := stmt.value.(monkey.Ast_Class); ok {
				log.info(class_node)
			}
		}
	}

	//TODO

}


package parser_tests

import monkey "../../src"
import "core:log"
import "core:mem/virtual"
import "core:testing"


@(test)
test_class_with_inheritance :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	// Test class with inheritance
	input := "let Point3d = class(Point) { let z = 0; }"
	parser := monkey.Parser_New(input, a)
	program := parser.parse(&parser)

	if len(parser.errors) > 0 {
		log.errorf("parser has errors: %v", parser.errors)
		return
	}

	if len(program) != 1 {
		log.errorf("expected 1 statement, got %d", len(program))
		return
	}

	class_decl, ok := program[0].(monkey.Ast_Let)
	if !ok {
		log.errorf("expected Ast_Class, got %v", monkey.Ast__Type__(program[0]))
		return
	}
	if class_decl.name != "Point3d" {
		log.errorf("expected class name 'Point3d', got '%s'", class_decl.name)
		return
	}
	// log.info(class_decl)
	class_node, okk := class_decl.value.(monkey.Ast_Class)
	if !okk {
		log.errorf("expected Ast_Class, got %v", monkey.Ast__Type__(class_decl.value))
		return
	}
	if len(class_node.super) == 0 {
		log.errorf("expected 1 superclass, got %d", len(class_node.super))
		return
	}
	if class_node.super[0].value != "Point" {
		log.errorf("expected superclass 'Point', got '%s'", class_node.super[0].value)
		return
	}
}

@(test)
test_class_with_methods :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	// Test class with methods
	input := `
	let point = class() {
		let new = fn(self, x, y) {
			self.x = x;
			self.y = y;
		};
		let inspect = fn(self) {
			puts(self.x);
			puts(self.y);
		};
	}
	`


	parser := monkey.Parser_New(input, a)
	program := parser.parse(&parser)

	if len(parser.errors) > 0 {
		log.errorf("parser has errors: %v", parser.errors)
		return
	}

	if len(program) != 1 {
		log.errorf("expected 1 statement, got %d", len(program))
		return
	}

	class_decl, ok := program[0].(monkey.Ast_Let)
	if !ok {
		log.errorf("expected Ast_Class, got %v", monkey.Ast__Type__(program[0]))
		return
	}
	if class_decl.name != "point" {
		log.errorf("expected class name 'point', got '%s'", class_decl.name)
		return
	}
	// log.info(class_decl)
	class_node, okk := class_decl.value.(monkey.Ast_Class)
	if !okk {
		log.errorf("expected Ast_Class, got %v", monkey.Ast__Type__(class_decl.value))
		return
	}
	if len(class_node.super) != 0 {
		log.errorf("expected no superclass, got %d", len(class_node.super))
		return
	}
	if len(class_node.body) != 2 {
		log.errorf("expected 2 methods in class body, got %d", len(class_node.body))
		return
	}
}


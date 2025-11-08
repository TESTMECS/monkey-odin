package parser_tests

import monkey "../../src"
import "core:log"
import "core:mem/virtual"
import "core:testing"

@(test)
test_class_parsing :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	// Test basic class without inheritance
	input := "class Point { let x = 0; let y = 0; }"
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

	class_node, ok := program[0].(monkey.Ast_Class)
	if !ok {
		log.errorf("expected Ast_Class, got %v", monkey.Ast__Type__(program[0]))
		return
	}

	if class_node.name != "Point" {
		log.errorf("expected class name 'Point', got '%s'", class_node.name)
		return
	}

	if len(class_node.super) != 0 {
		log.errorf("expected no superclass, got %d", len(class_node.super))
		return
	}

	if len(class_node.body) != 2 {
		log.errorf("expected 2 statements in class body, got %d", len(class_node.body))
		return
	}
}

@(test)
test_class_with_inheritance :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	// Test class with inheritance
	input := "class Point3D(Point) { let z = 0; }"
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

	class_node, ok := program[0].(monkey.Ast_Class)
	if !ok {
		log.errorf("expected Ast_Class, got %v", monkey.Ast__Type__(program[0]))
		return
	}

	if class_node.name != "Point3D" {
		log.errorf("expected class name 'Point3D', got '%s'", class_node.name)
		return
	}

	if len(class_node.super) != 1 {
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
	class Point {
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

	class_node, ok := program[0].(monkey.Ast_Class)
	if !ok {
		log.errorf("expected Ast_Class, got %v", monkey.Ast__Type__(program[0]))
		return
	}

	if class_node.name != "Point" {
		log.errorf("expected class name 'Point', got '%s'", class_node.name)
		return
	}

	if len(class_node.body) != 2 {
		log.errorf("expected 2 methods in class body, got %d", len(class_node.body))
		return
	}

	// Check that both methods are let statements with function values
	for method, i in class_node.body {
		let_stmt, ok := method.(monkey.Ast_Let)
		if !ok {
			log.errorf("expected method %d to be Ast_Let, got %v", i, monkey.Ast__Type__(method))
			return
		}

		if let_stmt.name != "new" && let_stmt.name != "inspect" {
			log.errorf("unexpected method name: %s", let_stmt.name)
			return
		}
	}
}


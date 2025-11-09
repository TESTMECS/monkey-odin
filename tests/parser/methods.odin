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
	input := "let point = class() { let new = fn(self, x, y) { self.x = x; self.y = y; }; }; let p = point(); p->new(1, 2);"
	parser := monkey.Parser_New(input, a)
	program := parser.parse(&parser)
	for stmt in program {
		log.infof("%v", stmt)
	}

	if len(parser.errors) > 0 {
		log.errorf("parser has errors: %v", parser.errors)
		return
	}

	if stmt, ok := program[0].(monkey.Ast_Let); !ok {
		log.errorf("expected Ast_Let, got %v", monkey.Ast__Type__(stmt))
		return
	}
	 else if class_node, ok := stmt.value.(monkey.Ast_Class); !ok {
		log.errorf("expected Ast_Class, got %v", monkey.Ast__Type__(stmt.value))
		return
	}
	 else if len(class_node.body) != 1 {
		log.errorf("expected 1 method in class body, got %d", len(class_node.body))
		return
	}

	if inst, ok := program[1].(monkey.Ast_Let); !ok {
		log.errorf("expected Ast_Let, got %v", monkey.Ast__Type__(program[1]))
		return
	}
	 else if call, ok := inst.value.(monkey.Ast_Call); !ok {
		log.errorf("expected Ast_Call, got %v", monkey.Ast__Type__(inst.value))
		return
	}
	 else if len(call.arguments) != 0 {
		log.errorf("expected 0 arguments in instantiation, got %d", len(call.arguments))
		return
	}

	if method_call, ok := program[2].(monkey.Ast_Method_Call); !ok {
		log.errorf("expected Ast_Method_Call, got %v", monkey.Ast__Type__(program[2]))
		return
	}
	 else if ident, ok := method_call.object.(monkey.Ast_Identifier); !ok {
		log.errorf("expected Ast_Identifier, got %v", monkey.Ast__Type__(method_call.object))
		return
	}
	 else if ident.value != "p" {
		log.errorf("expected identifier 'p', got '%s'", ident.value)
		return
	}
	 else if method_call.method.(monkey.Ast_Identifier).value != "new" {
		log.errorf(
			"expected method name 'new', got '%s'",
			method_call.method.(monkey.Ast_Identifier).value,
		)
		return
	}
	 else if len(method_call.arguments) != 2 {
		log.errorf("expected 2 arguments in method call, got %d", len(method_call.arguments))
		return
	}
}


package parser_tests

import monkey "../../src"
import "core:log"
import "core:mem/virtual"
import "core:testing"

@(test)
test_foreach_array :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	// Test foreach with array
	input := "foreach x in [1, 2, 3] { puts(x); }"
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

	foreach_node, ok := program[0].(monkey.Ast_Foreach)
	if !ok {
		log.errorf("expected Ast_Foreach, got %v", monkey.Ast__Type__(program[0]))
		return
	}

	if foreach_node.itervar != "x" {
		log.errorf("expected iterator variable 'x', got '%s'", foreach_node.itervar)
		return
	}

	// Check that the expression is an array
	array_node, okk := foreach_node.expr^.(monkey.Ast_Array)
	if !okk {
		log.errorf("expected array expression, got %v", monkey.Ast__Type__(foreach_node.expr^))
		return
	}

	if len(array_node) != 3 {
		log.errorf("expected array with 3 elements, got %d", len(array_node))
		return
	}

	// Check that body has one statement
	if len(foreach_node.body) != 1 {
		log.errorf("expected 1 statement in body, got %d", len(foreach_node.body))
		return
	}
}

@(test)
test_foreach_hash_table :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	// Test foreach with hash table
	input := "foreach key in {\"a\": 1, \"b\": 2} { puts(key); }"
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

	foreach_node, ok := program[0].(monkey.Ast_Foreach)
	if !ok {
		log.errorf("expected Ast_Foreach, got %v", monkey.Ast__Type__(program[0]))
		return
	}

	if foreach_node.itervar != "key" {
		log.errorf("expected iterator variable 'key', got '%s'", foreach_node.itervar)
		return
	}

	// Check that the expression is a hash table
	hash_node, okk := foreach_node.expr^.(monkey.Ast_Hash_Table)
	if !okk {
		log.errorf(
			"expected hash table expression, got %v",
			monkey.Ast__Type__(foreach_node.expr^),
		)
		return
	}

	if len(hash_node.pairs) != 2 {
		log.errorf("expected hash table with 2 pairs, got %d", len(hash_node.pairs))
		return
	}
}

@(test)
test_foreach_with_identifier :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	// Test foreach with identifier expression
	input := "foreach item in myArray { puts(item); }"
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

	foreach_node, ok := program[0].(monkey.Ast_Foreach)
	if !ok {
		log.errorf("expected Ast_Foreach, got %v", monkey.Ast__Type__(program[0]))
		return
	}

	if foreach_node.itervar != "item" {
		log.errorf("expected iterator variable 'item', got '%s'", foreach_node.itervar)
		return
	}

	// Check that the expression is an identifier
	ident_node, okk := foreach_node.expr^.(monkey.Ast_Identifier)
	if !okk {
		log.errorf(
			"expected identifier expression, got %v",
			monkey.Ast__Type__(foreach_node.expr^),
		)
		return
	}

	if ident_node.value != "myArray" {
		log.errorf("expected identifier 'myArray', got '%s'", ident_node.value)
		return
	}
}

@(test)
test_foreach_empty_body :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	// Test foreach with empty body
	input := "foreach x in [] { }"
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

	foreach_node, ok := program[0].(monkey.Ast_Foreach)
	if !ok {
		log.errorf("expected Ast_Foreach, got %v", monkey.Ast__Type__(program[0]))
		return
	}

	if foreach_node.itervar != "x" {
		log.errorf("expected iterator variable 'x', got '%s'", foreach_node.itervar)
		return
	}

	// Check that body is empty
	if len(foreach_node.body) != 0 {
		log.errorf("expected empty body, got %d statements", len(foreach_node.body))
		return
	}
}


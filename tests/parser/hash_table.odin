#+feature dynamic-literals
package parser_tests

import monkey "../../src"
import "core:log"
import "core:mem/virtual"
import "core:testing"

@(test)
test_hash_table :: proc(t: ^testing.T) {
	using monkey
	using tc
	v := new_vmem()
	a := virtual.arena_allocator(v.a)
	defer v->free()

	input := `{"one": 1, "two": 2, "three": 3};`

	p := Parser_New(input, a)

	program := p->parse()
	if parser_has_error(p) do return

	if len(program) != 1 {
		log.errorf("program does not contain 1 statement, got='%v'", len(program))
		return
	}

	stmt, ok := program[0].(Ast_Hash_Table)
	if !ok {
		log.errorf("program[0] is not Ast_Hash_Table, got='%v'", Ast__Type__(program[0]))
		return
	} else if len(stmt.table) != 3 {
		log.errorf("length of the hash table is not 3, got'%d'", len(stmt.table))
		return
	}

	expected := map[string]int {
		"one"   = 1,
		"two"   = 2,
		"three" = 3,
	}
	defer delete(expected)

	for key, ev in expected {
		value, key_exists := stmt.table[key]
		if !key_exists {
			log.errorf("key '%s' does not exist in the hash table", key)
			continue
		}
		literal_value_is_valid(&value, ev)
	}

}

